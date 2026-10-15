/// A section of the paper exam. Writing (쓰기) is Phase C and has no value
/// yet, so a writing file reads as unknown (spec 2026-10-15 §4.2).
enum TopikSection {
  listening('listening'),
  reading('reading');

  const TopikSection(this.code);

  /// The value stored in content files and in the database.
  final String code;

  static TopikSection? ofCode(Object? code) {
    for (final section in values) {
      if (section.code == code) return section;
    }
    return null;
  }
}
