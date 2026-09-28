import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';

/// Syncs the study and display settings of `app_settings` row 1 as the one
/// account row the server keeps per user (library and study sync spec §3.5).
/// Reminders never leave the device. The row has no server version and is
/// never deleted, so acknowledgements and deletes do nothing.
class AccountSettingsSyncAdapter implements EntitySyncAdapter {
  AccountSettingsSyncAdapter(this._db);

  static const type = 'account_settings';

  final AppDatabase _db;

  @override
  String get entityType => type;

  @override
  Future<Map<String, Object?>?> readRow(String id) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(appSettingsRowId))).getSingleOrNull();
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
      (_db.update(
        _db.appSettings,
      )..where((s) => s.id.equals(appSettingsRowId))).write(
        AppSettingsCompanion(
          cardLimit: Value(row['cardLimit'] as int),
          newCardOrder: Value(row['newCardOrder'] as String),
          themeMode: Value(row['themeMode'] as String),
          language: Value(row['language'] as String),
          updatedAt: Value(fromWireTime(row['updatedAt'])!),
        ),
      );

  @override
  Future<void> deleteFromServer(String id) async {}

  @override
  Future<void> markAcknowledged(String id, int serverVersion) async {}
}
