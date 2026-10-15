/// The two TOPIK exams: TOPIK I (grades 1–2) and TOPIK II (grades 3–6)
/// (spec 2026-10-15 §4.1).
enum TopikLevel {
  topik1('topik1'),
  topik2('topik2');

  const TopikLevel(this.code);

  /// The value stored in content files and in the database.
  final String code;

  static TopikLevel? ofCode(Object? code) {
    for (final level in values) {
      if (level.code == code) return level;
    }
    return null;
  }
}
