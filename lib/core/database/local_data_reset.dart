import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';

/// Removes the signed-out or replaced account's data from the device (auth
/// spec §4, #27, #41). One transaction, and not gated (R3 lets it write).
///
/// The capture triggers are silenced with `applying_remote`, so the deletes
/// queue nothing. Cards go first: their schedules, tag links, reviews and
/// study rows go with them by cascade, and reviews cannot be deleted while
/// their card exists. The synced settings go back to `settings.drift`'s
/// defaults while the triggers are still silent. Then sync's keys (all but
/// the device id), the outbox and the refusals.
///
/// Kept: the transition record, the welcome flag, the reminder columns, the
/// device id and the log database.
class LocalDataReset {
  LocalDataReset(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> run() => _db.transaction(() async {
    await _db.customStatement(
      'INSERT OR REPLACE INTO sync_state (name, value) VALUES (?, ?)',
      [syncApplyingRemoteKey, '1'],
    );
    for (final table in ['card', 'deck', 'delete_batches', 'tags']) {
      await _db.customStatement('DELETE FROM $table');
    }
    await _db.customStatement(
      "UPDATE app_settings SET card_limit = 20, new_card_order = 'created', "
      "theme_mode = 'system', language = 'system', updated_at = ? "
      'WHERE id = $appSettingsRowId',
      [_now().millisecondsSinceEpoch ~/ 1000],
    );
    await _db.customStatement('DELETE FROM sync_state WHERE name <> ?', [
      syncDeviceIdKey,
    ]);
    await _db.customStatement('DELETE FROM sync_outbox');
    await _db.customStatement('DELETE FROM sync_rejection');
  });
}
