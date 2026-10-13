import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';

import '../../../support/test_database.dart';

// Sync spec §3.5 and the SQL log switch spec §3.2: the fifth synced column
// travels under `logSqlStatements`; a row without the key leaves it.
void main() {
  late AppDatabase db;
  late AccountSettingsSyncDao dao;

  setUp(() {
    db = openTestDatabase();
    dao = AccountSettingsSyncDao(db);
  });
  tearDown(() => db.close());

  Future<int> flag() async =>
      (await db.select(db.appSettings).getSingle()).logSqlStatements;

  test('the pushed row carries the switch as a boolean', () async {
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    final row = await dao.readRow('00000000-0000-0000-0000-000000000000');
    expect(row!['logSqlStatements'], false);
  });

  test('a pulled row applies the switch', () async {
    await dao.upsertFromServer({
      'logSqlStatements': false,
      'updatedAt': '2026-10-07T00:00:00Z',
    }, 1);
    expect(await flag(), 0);
  });

  test('a pulled row without the key leaves the switch', () async {
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    await dao.upsertFromServer({
      'themeMode': 'dark',
      'updatedAt': '2026-10-07T00:00:00Z',
    }, 1);
    expect(await flag(), 0);
  });
}
