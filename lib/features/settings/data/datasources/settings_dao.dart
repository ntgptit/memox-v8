import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for the one `app_settings` row and for the study options a
/// root deck keeps in `deck.study_config`. It returns Drift rows, never
/// domain values, and runs inside the caller's transaction.
final class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Stream<AppSetting> watchRow() => (_db.select(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).watchSingle();

  /// [watchRow] read once.
  Future<AppSetting> row() => (_db.select(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).getSingle();

  Future<void> updateRow(AppSettingsCompanion values) => (_db.update(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).write(values);

  /// The root of [deckId] and the settings row, in one statement, again when
  /// either changes; null when [deckId] or its root does not exist or is in
  /// the Trash. The root is reached through `root_id` (BR-DECK-003).
  Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId) {
    final (query, read) = _rootAndSettings(deckId);
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : read(row),
    );
  }

  /// [watchRootAndSettings] read once.
  Future<(Deck, AppSetting)?> rootAndSettings(String deckId) async {
    final (query, read) = _rootAndSettings(deckId);
    final row = await query.getSingleOrNull();
    return row == null ? null : read(row);
  }

  (Selectable<TypedResult>, (Deck, AppSetting) Function(TypedResult))
  _rootAndSettings(String deckId) {
    final deck = _db.deck;
    final root = _db.alias(_db.deck, 'root');
    final settings = _db.appSettings;
    final query = _db.select(deck).join([
      innerJoin(
        root,
        root.id.equalsExp(deck.rootId) & root.deleteBatchId.isNull(),
      ),
      innerJoin(settings, settings.id.equals(appSettingsRowId)),
    ])..where(deck.id.equals(deckId) & deck.deleteBatchId.isNull());
    return (query, (row) => (row.readTable(root), row.readTable(settings)));
  }

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// Writes the override of the root [rootId]; null removes it.
  Future<void> setStudyConfig(
    String rootId,
    String? studyConfig,
    DateTime now,
  ) => (_db.update(_db.deck)..where((deck) => deck.id.equals(rootId))).write(
    DeckCompanion(studyConfig: Value(studyConfig), updatedAt: Value(now)),
  );
}
