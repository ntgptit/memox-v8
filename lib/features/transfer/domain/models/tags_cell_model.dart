/// The one codec for the `tags` cell, shared by import and export
/// (BR-TRANSFER-009): tags joined by `;`, a `;` inside a tag written `\;`
/// and a `\` written `\\`.
abstract final class TagsCell {
  static const separator = ';';
  static const _escape = r'\';

  static String encode(List<String> tags) => tags
      .map(
        (tag) => tag
            .replaceAll(_escape, '$_escape$_escape')
            .replaceAll(separator, '$_escape$separator'),
      )
      .join(separator);

  /// A backslash escapes only a `;` or a `\` right after it; before any
  /// other character, or at the end of the cell, it is kept as written,
  /// since legacy sources never escaped. Each tag is trimmed; blank ones
  /// are dropped.
  static List<String> decode(String cell) {
    final tags = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < cell.length; i++) {
      final char = cell[i];
      final next = i + 1 < cell.length ? cell[i + 1] : null;
      if (char == _escape && (next == separator || next == _escape)) {
        current.write(next);
        i++;
        continue;
      }
      if (char == separator) {
        tags.add(current.toString());
        current.clear();
        continue;
      }
      current.write(char);
    }
    tags.add(current.toString());
    return [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
  }
}
