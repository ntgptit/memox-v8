import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// The sync steps (SB-S2 v7, SB-S3 v8, SB-S5 v9, SB-S4 v10) queue the rows a
// device already holds, so its first sync after the update uploads them.
// Split from migration_test.dart, which keeps the upgrade-to-latest checks.

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('a v9 database queues its schedules and its reviews', () async {
    final schema = await verifier.schemaAt(9);
    schema.rawDatabase
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, created_at, updated_at) "
        "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'R', 'f', 'b', 0, 0)",
      )
      ..execute(
        "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, "
        "answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 0, 0, 1)",
      )
      ..execute(
        "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, "
        "\"action\", answered_at) VALUES ('V2', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 2), "
        "('V1', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
      )
      ..execute('DELETE FROM sync_outbox');
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);
    final queued = await db
        .customSelect(
          'SELECT entity_type, entity_id FROM sync_outbox ORDER BY rowid',
        )
        .get();
    expect(
      queued.map(
        (r) =>
            '${r.read<String>('entity_type')}/${r.read<String>('entity_id')}',
      ),
      ['card_schedule/K', 'review_log/V1', 'review_log/V2'],
    );
  });

  test('a v8 database queues its settings only when they are not the defaults', () async {
    for (final (theme, queued) in [('system', 0), ('dark', 1)]) {
      final schema = await verifier.schemaAt(8);
      schema.rawDatabase
        ..execute(
          'INSERT OR IGNORE INTO app_settings (id, updated_at) VALUES (1, 0)',
        )
        ..execute("UPDATE app_settings SET theme_mode = '$theme' WHERE id = 1")
        ..execute('DELETE FROM sync_outbox');
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 11);
      final rows = await db
          .customSelect(
            "SELECT 1 FROM sync_outbox WHERE entity_type = 'account_settings'",
          )
          .get();
      expect(rows, hasLength(queued), reason: theme);
      await db.close();
    }
  });

  test('a v7 database queues its tags and its tagged cards', () async {
    final schema = await verifier.schemaAt(7);
    schema.rawDatabase
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, created_at, updated_at) "
        "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES "
        "('K1', 'R', 'f', 'b', 1, 1), ('K2', 'R', 'f', 'b', 2, 2)",
      )
      ..execute(
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('T', 'v', 'v', 0)",
      )
      ..execute("INSERT INTO card_tags (card_id, tag_id) VALUES ('K1', 'T')")
      ..execute('DELETE FROM sync_outbox');
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);

    final queued = await db
        .customSelect(
          'SELECT entity_type, entity_id FROM sync_outbox ORDER BY rowid',
        )
        .get();
    expect(
      queued.map(
        (r) =>
            '${r.read<String>('entity_type')}/${r.read<String>('entity_id')}',
      ),
      ['tag/T', 'card/K1'],
    );
  });

  test('a v6 database queues its cards for the first card sync', () async {
    final schema = await verifier.schemaAt(6);
    schema.rawDatabase
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, created_at, updated_at) "
        "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
      )
      ..execute('DELETE FROM sync_outbox')
      ..execute(
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES "
        "('K2', 'R', 'f', 'b', 2, 2), ('K1', 'R', 'f', 'b', 1, 1)",
      );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);

    final queued = await db
        .customSelect(
          "SELECT entity_id FROM sync_outbox WHERE entity_type = 'card' ORDER BY created_at, rowid",
        )
        .get();
    expect(queued.map((r) => r.read<String>('entity_id')), ['K1', 'K2']);
  });
}
