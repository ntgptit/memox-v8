/// The one codec of the tags cell, for import and export alike
/// (BR-TRANSFER-009, BR-TAG-011).
abstract final class TagCell {
  /// The names joined by `;`; inside a name, `\` becomes `\\` and `;`
  /// becomes `\;`.
  static String encode(Iterable<String> names) => names
      .map((name) => name.replaceAll(r'\', r'\\').replaceAll(';', r'\;'))
      .join(';');

  /// The names of [cell], split on each `;` no `\` escapes. `\;` and `\\`
  /// unescape; a `\` before anything else, or at the end, stays as it is,
  /// since legacy sources never escaped. A name empty after trim is dropped;
  /// the tag rules trim the others where they always do.
  static List<String> decode(String cell) {
    final names = <String>[];
    final name = StringBuffer();
    void endName() {
      if (name.toString().trim().isNotEmpty) names.add(name.toString());
      name.clear();
    }

    var index = 0;
    while (index < cell.length) {
      final char = cell[index];
      final next = index + 1 < cell.length ? cell[index + 1] : null;
      index++;
      if (char == r'\' && (next == ';' || next == r'\')) {
        name.write(next);
        index++;
        continue;
      }
      if (char == ';') {
        endName();
        continue;
      }
      name.write(char);
    }
    endName();
    return names;
  }
}
