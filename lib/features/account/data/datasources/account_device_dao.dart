import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Row access for the account screens' device-only reads. It returns plain
/// values and runs inside the caller's guard.
final class AccountDeviceDao {
  AccountDeviceDao(this._db);

  final AppDatabase _db;

  Future<bool> welcomeSeen() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((row) => row.id.equals(appSettingsRowId))).getSingle();
    return row.welcomeSeen == 1;
  }

  /// Only `welcome_seen` changes, so the settings sync trigger, which
  /// watches the four synced columns, stays silent.
  Future<void> setWelcomeSeen() =>
      (_db.update(_db.appSettings)
            ..where((row) => row.id.equals(appSettingsRowId)))
          .write(const AppSettingsCompanion(welcomeSeen: Value(1)));

  /// Live decks, and live cards whose deck is live too.
  Future<(int, int)> liveCounts() async {
    final row = await _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM deck WHERE delete_batch_id IS NULL) AS decks, '
          '(SELECT COUNT(*) FROM card c JOIN deck d ON d.id = c.deck_id '
          'WHERE c.delete_batch_id IS NULL AND d.delete_batch_id IS NULL) '
          'AS cards',
          readsFrom: {_db.deck, _db.card},
        )
        .getSingle();
    return (row.read<int>('decks'), row.read<int>('cards'));
  }
}
