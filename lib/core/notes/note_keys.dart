/// The one-time notes a person can dismiss (critique 2026-09-30). Each key
/// names one note, wherever it shows.
abstract final class NoteKeys {
  /// Screen 06: kept for 30 days, then removed.
  static const String trashRetention = 'trash_retention';

  /// Screen 03: the starter decks are development fixtures.
  static const String starterFixtures = 'starter_fixtures';

  /// Screen 11: which files and text an import reads.
  static const String importHelper = 'import_helper';
}
