import 'package:memox/core/database/app_database.dart';

/// Row access for the one `app_settings` row. It returns Drift rows, never
/// domain values, and runs inside the caller's transaction.
final class SettingsDao {
  SettingsDao(this._db);

  final AppDatabase _db;

  Stream<AppSetting> watchRow() => (_db.select(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).watchSingle();

  Future<void> updateRow(AppSettingsCompanion values) => (_db.update(
    _db.appSettings,
  )..where((row) => row.id.equals(appSettingsRowId))).write(values);
}
