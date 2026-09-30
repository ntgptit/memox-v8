import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// Auth spec §4: v11 adds the validated account, a pending account transition
// and the welcome flag. Existing settings keep their values; the flag starts
// unset, so an upgraded install sees the welcome once.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'v10 upgrades to v11 with its settings intact and the welcome unseen',
    () async {
      final schema = await verifier.schemaAt(10);
      schema.rawDatabase.execute(
        "INSERT INTO app_settings (id, card_limit, theme_mode, reminder_enabled, updated_at) "
        "VALUES (1, 35, 'dark', 1, 0)",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 11);

      final row = await db.select(db.appSettings).getSingle();
      expect(row.cardLimit, 35);
      expect(row.themeMode, 'dark');
      expect(row.reminderEnabled, 1);
      expect(row.welcomeSeen, 0);
      expect(await db.select(db.accountState).get(), isEmpty);
      expect(await db.select(db.accountTransition).get(), isEmpty);
    },
  );

  test('a transition row is one row at most', () async {
    final db = AppDatabase(await verifier.startAt(11));
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO account_transition (id, op_id, kind, stage, created_at, updated_at) "
      "VALUES (1, 'op', 'signOut', 'started', 0, 0)",
    );
    expect(
      () => db.customStatement(
        "INSERT INTO account_transition (id, op_id, kind, stage, created_at, updated_at) "
        "VALUES (2, 'op2', 'signOut', 'started', 0, 0)",
      ),
      throwsA(anything),
    );
  });
}
