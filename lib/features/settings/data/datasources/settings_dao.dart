import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'settings_dao.g.dart';

/// Row access for the one `app_settings` row and for the study options a
/// root deck keeps in `deck.study_config` (`settings_queries.drift`). It
/// returns Drift rows, never domain values, and runs inside the caller's
/// transaction.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/settings_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
  },
)
final class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.attachedDatabase);

  Stream<AppSetting> watchRow() =>
      appSettingsRow(appSettingsRowId).watchSingle();

  /// [watchRow] read once.
  Future<AppSetting> row() => appSettingsRow(appSettingsRowId).getSingle();

  /// Writes the columns [values] holds; one with none writes nothing, as
  /// an `UPDATE … SET` with no column is not SQL.
  Future<void> updateRow(AppSettingsCompanion values) async {
    if (values.toColumns(false).isEmpty) return;
    await updateAppSettings(values, appSettingsRowId);
  }

  /// The root of [deckId] and the settings row, in one statement, again when
  /// either changes; null when [deckId] or its root does not exist or is in
  /// the Trash. The root is reached through `root_id` (BR-DECK-003).
  Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId) =>
      rootAndSettingsOf(appSettingsRowId, deckId).watchSingleOrNull().map(
        (row) => row == null ? null : (row.root, row.settings),
      );

  /// [watchRootAndSettings] read once.
  Future<(Deck, AppSetting)?> rootAndSettings(String deckId) async {
    final row = await rootAndSettingsOf(
      appSettingsRowId,
      deckId,
    ).getSingleOrNull();
    return row == null ? null : (row.root, row.settings);
  }

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// Writes the override of the root [rootId]; null removes it.
  Future<void> setStudyConfig(
    String rootId,
    String? studyConfig,
    DateTime now,
  ) => setDeckStudyConfig(studyConfig, now, rootId);
}
