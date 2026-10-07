import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/test_database.dart';
import 'generated/schema.dart';

// Spec 2026-10-07-sql-log-switch-design.md §3.1–3.2: the fifth synced
// settings column, on for every existing row, queued like the other four.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  Future<List<String>> queued(AppDatabase db) async {
    final rows = await db
        .customSelect('SELECT entity_type, op FROM sync_outbox ORDER BY rowid')
        .get();
    return [
      for (final row in rows)
        '${row.read<String>('entity_type')}:${row.read<String>('op')}',
    ];
  }

  test('changing the switch queues the account settings; a reminder change '
      'queues nothing', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await db.customStatement('DELETE FROM sync_outbox');

    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    expect(await queued(db), ['account_settings:upsert']);

    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      'UPDATE app_settings SET reminder_enabled = 1 WHERE id = 1',
    );
    expect(await queued(db), isEmpty);
  });

  test('v14 gets log_sql_statements = 1, keeps its settings, and its '
      'recreated trigger queues the switch', () async {
    final schema = await verifier.schemaAt(14);
    schema.rawDatabase
      ..execute(
        'INSERT OR IGNORE INTO app_settings (id, updated_at) VALUES (1, 0)',
      )
      ..execute(
        "UPDATE app_settings SET card_limit = 35, theme_mode = 'dark', "
        'welcome_seen = 1 WHERE id = 1',
      );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 15);

    final row = await db.select(db.appSettings).getSingle();
    expect(row.logSqlStatements, 1);
    expect(row.cardLimit, 35);
    expect(row.themeMode, 'dark');
    expect(row.welcomeSeen, 1);

    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      'UPDATE app_settings SET log_sql_statements = 0 WHERE id = 1',
    );
    expect(await queued(db), ['account_settings:upsert']);

    final integrity = await db.customSelect('PRAGMA integrity_check').get();
    expect(integrity.single.data.values.single, 'ok');
    expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
  });
}
