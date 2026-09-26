/// BR-TRASH-002 as a text check (trash spec §11): every statement of `lib/`
/// that reads `card` or `deck` leaves the tombstones out, unless an
/// allowlist names it with its reason. `tombstone_rules_test.dart` proves
/// each rule on planted sources; `tombstone_filter_test.dart` applies them
/// to the real `lib/`.
library;

import 'dart:io';

/// A statement of `lib/` that reads `card` or `deck`.
class TableStatement {
  const TableStatement(this.file, this.member, this.leaks);

  /// The repo-relative path, `lib/...`.
  final String file;

  /// The Dart member, or the drift query or trigger, it belongs to.
  final String member;

  /// What reads the tombstones: `card c`, `deck`, or `query builder`.
  /// Empty when every read is filtered.
  final List<String> leaks;

  /// How the allowlist names it.
  String get key => '$file#$member';
}

/// Every `.dart` and `.drift` file under `lib/` of [projectRoot], by
/// repo-relative path. Generated Dart is left out: it repeats what the
/// drift files say.
Map<String, String> readQuerySources(Directory projectRoot) {
  final root = projectRoot.path.replaceAll(r'\', '/');
  return {
    for (final entity in Directory('$root/lib').listSync(recursive: true))
      if (entity is File &&
          (entity.path.endsWith('.dart') || entity.path.endsWith('.drift')))
        if (entity.readAsStringSync() case final text
            when !text.contains(_generated))
          entity.path.replaceAll(r'\', '/').substring(root.length + 1): text,
  };
}

/// What build_runner's and drift_dev's headers both say.
const _generated = 'DO NOT MODIFY';

/// The statements of [sources] that read `card` or `deck`.
List<TableStatement> tableStatements(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    ...(path.endsWith('.drift')
        ? driftStatements(path, text)
        : dartStatements(path, text)),
];

/// The statements of [sources] that read tombstones and that [allowlist]
/// does not name, each with what leaks.
List<String> tombstoneViolations(
  Map<String, String> sources,
  Map<String, String> allowlist,
) => [
  for (final statement in tableStatements(sources))
    if (statement.leaks.isNotEmpty && !allowlist.containsKey(statement.key))
      '${statement.key}: ${statement.leaks.join(', ')}',
];

/// The entries of [allowlist] that excuse nothing: the statement is gone,
/// renamed, or filtered now.
List<String> staleAllowlistEntries(
  Map<String, String> sources,
  Map<String, String> allowlist,
) {
  final excused = {
    for (final statement in tableStatements(sources))
      if (statement.leaks.isNotEmpty) statement.key,
  };
  return [
    for (final key in allowlist.keys)
      if (!excused.contains(key)) key,
  ];
}

/// `FROM`, `JOIN` or `UPDATE` with the bare table name, so `card_schedule`
/// and `card_tags` do not count, and its alias when it has one.
final _reference = RegExp(
  r'\b(?:FROM|JOIN|UPDATE)\s+(card|deck)\b'
  r'(?:\s+(?:AS\s+)?(?!(?:WHERE|ON|JOIN|SET|LEFT|INNER|CROSS|NATURAL|GROUP|'
  r'ORDER|LIMIT|UNION|EXCEPT|INTERSECT|AND|OR|USING|WINDOW|HAVING|'
  r'RETURNING)\b)([A-Za-z_]\w*))?',
  caseSensitive: false,
);

/// The reads of [sql] that leave the tombstones in: an aliased table with
/// no `alias.delete_batch_id`, a bare one in a statement that never names
/// `delete_batch_id`.
List<String> unfilteredTables(String sql) => [
  for (final match in _reference.allMatches(sql))
    ?_leak(sql, match.group(1)!, match.group(2)),
];

String? _leak(String sql, String table, String? alias) {
  if (alias == null) return sql.contains('delete_batch_id') ? null : table;
  final filtered = RegExp('\\b$alias\\.delete_batch_id\\b').hasMatch(sql);
  return filtered ? null : '$table $alias';
}

/// A query-builder call on `card` or `deck`: a read, or a join.
final _builder = RegExp(
  r'\b(select|selectOnly|update|delete|innerJoin|leftOuterJoin)\(\s*'
  r'_?db\.(card|deck)\b',
);

/// A builder write addressed by its key, which the write's own reads have
/// checked: BR-TRASH-002 governs reads.
final _byKey = RegExp(r'\.id\.(?:equals|isIn)\(');

/// The SQL of [source], a Dart file, and its query-builder calls, each
/// with the member it is written in.
List<TableStatement> dartStatements(String path, String source) {
  final lines = source.split('\n');
  String memberAt(int offset) =>
      _memberAt(lines, '\n'.allMatches(source.substring(0, offset)).length);
  return [
    for (final (:offset, :text) in stringGroups(source))
      if (_reference.hasMatch(text))
        TableStatement(path, memberAt(offset), unfilteredTables(text)),
    for (final match in _builder.allMatches(source))
      TableStatement(path, memberAt(match.start), _builderLeaks(match, source)),
  ];
}

List<String> _builderLeaks(Match match, String source) {
  final end = source.indexOf(';', match.start);
  final call = source.substring(match.start, end < 0 ? source.length : end);
  final isWrite = match.group(1) == 'update' || match.group(1) == 'delete';
  if (call.contains('deleteBatchId')) return const [];
  if (isWrite && _byKey.hasMatch(call)) return const [];
  return const ['query builder'];
}

/// A declaration at the top level or in a class body: the name before its
/// parameters, its `=>` or its `=`.
final _declaration = RegExp(
  r'^(?:  )?(?![ })\]/@])'
  r'(?!(?:return|await|if|for|while|switch|case|else|throw|yield|assert|var)\b)'
  r'.*?\b(_?[A-Za-z]\w*)\s*(?:<[^()]*?>)?\s*(?:\(|=>|=(?!=))',
);

/// The member line [line] of [lines] is written in: the nearest declaration
/// above it.
String _memberAt(List<String> lines, int line) {
  for (var index = line; index >= 0; index--) {
    if (_declaration.firstMatch(lines[index]) case final match?) {
      return match.group(1)!;
    }
  }
  return '?';
}

/// The string literals of [source] that stand next to each other, joined,
/// with the offset of the first: one group is the text a `customSelect` or
/// a constant holds. An interpolation stays as written, so a fragment it
/// calls in is checked where it is declared.
List<({int offset, String text})> stringGroups(String source) {
  final groups = <({int offset, String text})>[];
  final text = StringBuffer();
  int? start;
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      index = end < 0 ? source.length : end;
      continue;
    }
    final char = source[index];
    final isRaw =
        char == 'r' &&
        index + 1 < source.length &&
        _isQuote(source[index + 1]) &&
        (index == 0 || !RegExp(r'\w').hasMatch(source[index - 1]));
    if (_isQuote(char) || isRaw) {
      final (end, literal) = _literalAt(source, index);
      start ??= index;
      text.write(literal);
      index = end;
      continue;
    }
    if (char.trim().isNotEmpty && start != null) {
      groups.add((offset: start, text: text.toString()));
      text.clear();
      start = null;
    }
    index++;
  }
  if (start != null) groups.add((offset: start, text: text.toString()));
  return groups;
}

bool _isQuote(String char) => char == "'" || char == '"';

/// The index just past the literal at [start], and what it holds.
(int, String) _literalAt(String source, int start) {
  var index = start;
  final isRaw = source[index] == 'r';
  if (isRaw) index++;
  final quote = source[index];
  final delimiter = source.startsWith(quote * 3, index) ? quote * 3 : quote;
  index += delimiter.length;
  final text = StringBuffer();
  while (index < source.length && !source.startsWith(delimiter, index)) {
    if (!isRaw && source[index] == r'\') {
      text.write(source.substring(index, index + 2));
      index += 2;
    } else if (!isRaw && source.startsWith(r'${', index)) {
      final end = _interpolationEnd(source, index + 2);
      text.write(source.substring(index, end));
      index = end;
    } else {
      text.write(source[index]);
      index++;
    }
  }
  return (index + delimiter.length, text.toString());
}

/// The index just past the `}` that closes an interpolation whose body
/// starts at [start], with the strings and braces inside it.
int _interpolationEnd(String source, int start) {
  var depth = 1;
  var index = start;
  while (index < source.length) {
    final char = source[index];
    if (_isQuote(char)) {
      index = _literalAt(source, index).$1;
      continue;
    }
    if (char == '{') depth++;
    if (char == '}' && --depth == 0) return index + 1;
    index++;
  }
  return index;
}

/// A named query's name, before its parameters, its result class or `:`.
final _queryName = RegExp(
  r'^([A-Za-z_]\w*)\s*(?:\([^)]*\))?\s*(?:AS\s+\w+\s*)?:',
);
final _triggerName = RegExp(r'^CREATE\s+TRIGGER\s+(\w+)', caseSensitive: false);

/// The statements of [source], a drift file, that read `card` or `deck`: a
/// named query by its name, a trigger by its own. Tables and indexes read
/// nothing.
List<TableStatement> driftStatements(String path, String source) {
  final code = [
    for (final line in source.split('\n'))
      line.contains('--') ? line.substring(0, line.indexOf('--')) : line,
  ].join('\n');
  return [
    for (final statement in _driftSplit(code))
      if (_reference.hasMatch(statement))
        TableStatement(
          path,
          (_triggerName.firstMatch(statement) ??
                      _queryName.firstMatch(statement))
                  ?.group(1) ??
              '?',
          unfilteredTables(statement),
        ),
  ];
}

/// [code] cut at each `;` that ends a statement: a trigger's `BEGIN … END`
/// holds its own.
List<String> _driftSplit(String code) {
  final statements = <String>[];
  var current = '';
  for (final part in code.split(';')) {
    current = current.isEmpty ? part : '$current;$part';
    final opened = RegExp(
      r'\bBEGIN\b',
      caseSensitive: false,
    ).allMatches(current).length;
    final closed = RegExp(
      r'\bEND\b',
      caseSensitive: false,
    ).allMatches(current).length;
    if (opened > closed) continue;
    statements.add(current.trim());
    current = '';
  }
  return statements;
}
