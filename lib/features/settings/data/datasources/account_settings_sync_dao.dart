import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';

part 'account_settings_sync_dao.g.dart';

/// Syncs the study and display settings of `app_settings` row 1 as the one
/// account row the server keeps per user (library and study sync spec §3.5).
/// Reminders never leave the device. The row has no server version and is
/// never deleted, so acknowledgements and deletes do nothing.
@DriftAccessor(
  include: {'package:memox/core/database/queries/settings_queries.drift'},
)
class AccountSettingsSyncDao extends DatabaseAccessor<AppDatabase>
    with _$AccountSettingsSyncDaoMixin, EntitySyncAdapter {
  AccountSettingsSyncDao(super.attachedDatabase);

  static const type = 'account_settings';

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final row = await appSettingsRow(appSettingsRowId).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return {
      'cardLimit': row.cardLimit,
      'newCardOrder': row.newCardOrder,
      'themeMode': row.themeMode,
      'language': row.language,
      'updatedAt': toWireTime(row.updatedAt)!
          .replaceFirst(RegExp(r'\.\d+Z$'), 'Z'),
    };
  }

  @override
  Future<void> upsertFromServer(Map<String, Object?> row, int serverVersion) =>
      updateAppSettings(
        // Every setting is an optional wire key (server sync spec §4.4): one
        // the row leaves out stays as it is on this device.
        // A card limit outside 1..200 is left out too: this device keeps a
        // limit a session can open with (DEV-214, BR-STUDY-003).
        AppSettingsCompanion(
          cardLimit: Value.absentIfNull(_cardLimitOf(row['cardLimit'] as int?)),
          newCardOrder: Value.absentIfNull(row['newCardOrder'] as String?),
          themeMode: Value.absentIfNull(row['themeMode'] as String?),
          language: Value.absentIfNull(row['language'] as String?),
          updatedAt: Value(fromWireTime(row['updatedAt'])!),
        ),
        appSettingsRowId,
      );

  /// [cardLimit] when a session can open with it, null otherwise.
  static int? _cardLimitOf(int? cardLimit) {
    if (cardLimit == null) return null;
    if (cardLimit < StudyOptions.minCardLimit) return null;
    if (cardLimit > StudyOptions.maxCardLimit) return null;
    return cardLimit;
  }

  @override
  Future<void> deleteFromServer(String id) async {}

  @override
  Future<void> markAcknowledged(String id, int serverVersion) async {}
}
