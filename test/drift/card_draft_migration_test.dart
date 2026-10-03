import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// SP2a R9: v13 adds card_draft, the card being written, kept on this device
// only. Nothing else changes: existing settings keep their values and the
// table starts empty.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v12 upgrades to v13 with its rows intact and no draft', () async {
    final schema = await verifier.schemaAt(12);
    schema.rawDatabase.execute(
      "INSERT INTO app_settings (id, card_limit, theme_mode, updated_at) "
      "VALUES (1, 35, 'dark', 0)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 13);

    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.cardLimit, 35);
    expect(settings.themeMode, 'dark');
    expect(await db.select(db.cardDraft).get(), isEmpty);
  });

  test('a draft is one row per key and queues nothing for sync', () async {
    final db = AppDatabase(await verifier.startAt(13));
    addTearDown(db.close);
    const insert =
        "INSERT INTO card_draft (draft_key, front, back, extras, tags, updated_at) "
        "VALUES ('create:d', 'f', 'b', '{}', '[]', 0)";
    await db.customStatement(insert);

    expect(() => db.customStatement(insert), throwsA(anything));
    final outbox = await db
        .customSelect('SELECT COUNT(*) AS n FROM sync_outbox')
        .getSingle();
    expect(outbox.read<int>('n'), 0);
  });
}
