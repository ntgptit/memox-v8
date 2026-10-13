/// Auth spec R3 and spec 2026-09-29-database-error-guard-design.md D2 as a
/// text check (DEV-178): under `lib/features/*/data/`, a repository opens a
/// write only through `mappedTransaction`, where the account's gate is
/// checked; a raw `transaction(` is a read model, and its body calls no
/// write. `write_gate_rules_test.dart` proves the rule on planted sources;
/// `write_gate_test.dart` applies it to the real `lib/`.
library;

import 'dart:io';

/// A raw `transaction(` call of a data layer: where it is and the writes
/// its body calls.
class RawTransaction {
  const RawTransaction(this.file, this.member, this.writes);

  /// The repo-relative path, `lib/...`.
  final String file;

  /// The Dart member the call is written in.
  final String member;

  /// The write calls the body makes; empty for a read model.
  final List<String> writes;

  /// How the allowlist names it.
  String get key => '$file#$member';
}

/// Every hand-written `.dart` file under `lib/features/*/data/` of
/// [projectRoot], by repo-relative path.
Map<String, String> readDataSources(Directory projectRoot) {
  final root = projectRoot.path.replaceAll(r'\', '/');
  return {
    for (final entity in Directory(
      '$root/lib/features',
    ).listSync(recursive: true))
      if (entity is File &&
          entity.path.endsWith('.dart') &&
          !entity.path.endsWith('.g.dart'))
        if (entity.path.replaceAll(r'\', '/').substring(root.length + 1)
            case final path when _isDataLayer(path))
          path: entity.readAsStringSync(),
  };
}

bool _isDataLayer(String path) =>
    RegExp(r'^lib/features/[^/]+/data/').hasMatch(path);

/// `transaction(`, not `mappedTransaction(` nor `inTransaction(`: their
/// capital T keeps them apart.
final _rawTransaction = RegExp(r'\btransaction\s*(?:<[^>]*>)?\s*\(');

/// A call that writes: a Drift statement, a `.drift` query named for its
/// write, or a raw statement.
final _write = RegExp(
  r'\b(?:insert|update|delete|upsert|create|link|unlink|merge|'
  r'customStatement|customInsert|customUpdate)\w*\s*\(',
);

/// The raw transactions of [sources], each with the writes of its body.
List<RawTransaction> rawTransactions(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    for (final match in _rawTransaction.allMatches(text))
      RawTransaction(
        path,
        memberAt(text, match.start),
        writesIn(bodyOf(text, match.end - 1)),
      ),
];

/// The raw transactions of [sources] whose body writes and that
/// [allowlist] does not name, each with its writes.
List<String> writeGateViolations(
  Map<String, String> sources,
  Map<String, String> allowlist,
) => [
  for (final call in rawTransactions(sources))
    if (call.writes.isNotEmpty && !allowlist.containsKey(call.key))
      '${call.key}: ${call.writes.join(', ')}',
];

/// The entries of [allowlist] that excuse nothing: the call is gone, moved
/// to `mappedTransaction`, or reads only now.
List<String> staleAllowlistEntries(
  Map<String, String> sources,
  Map<String, String> allowlist,
) {
  final excused = {
    for (final call in rawTransactions(sources))
      if (call.writes.isNotEmpty) call.key,
  };
  return [
    for (final key in allowlist.keys)
      if (!excused.contains(key)) key,
  ];
}

/// The write calls in [body], by name, in order and once each.
List<String> writesIn(String body) => {
  for (final match in _write.allMatches(body))
    match.group(0)!.replaceAll(RegExp(r'\s*\($'), ''),
}.toList();

/// The text between the parenthesis at [open] and its match, string
/// literals skipped so a parenthesis inside one does not count.
String bodyOf(String text, int open) {
  var depth = 0;
  String? quote;
  for (var i = open; i < text.length; i++) {
    final char = text[i];
    if (quote != null) {
      if (char == r'\') {
        i++;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }
    if (char == "'" || char == '"') {
      quote = char;
    } else if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
      if (depth == 0) return text.substring(open + 1, i);
    }
  }
  return text.substring(open + 1);
}

/// A member declaration in a class body: two spaces in, a type or a
/// constructor name, then the name before its parameters, `=>` or `=`.
final _member = RegExp(
  r'^  (?!(?:return|await|if|for|final|var|const|late|static|'
  r'switch|case|else|throw|yield|assert)\b)'
  r'[A-Za-z_][\w<>?, ]*?\b(_?[A-Za-z]\w*)\s*(?:\(|=>|=(?!=))',
  multiLine: true,
);

/// The last member declared before [offset] in [text], or `<top level>`.
String memberAt(String text, int offset) {
  String? member;
  for (final match in _member.allMatches(text)) {
    if (match.start > offset) break;
    member = match.group(1);
  }
  return member ?? '<top level>';
}
