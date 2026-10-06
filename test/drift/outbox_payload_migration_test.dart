import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// DEV-181: v13 adds sync_outbox.payload and recreates the deck and card
// triggers so a purge's delete carries its batch. A v12 database keeps its
// pending entries (payload NULL), and a purge after the upgrade writes the
// batch through the recreated triggers.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v12 keeps its pending entries, and a purge after the upgrade carries '
      'its batch', () async {
    final schema = await verifier.schemaAt(12);
    schema.rawDatabase
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, created_at, updated_at) "
        "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, "
        "created_at, updated_at) VALUES ('D', 'd', 'R', 'R', 2, 'card', 0, 0, 0)",
      )
      ..execute(
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
        "VALUES ('K', 'D', 'f', 'b', 0, 0)",
      )
      ..execute(
        "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
        "VALUES ('B', 'deck', 'D', 100)",
      )
      ..execute("UPDATE deck SET delete_batch_id = 'B' WHERE id = 'D'")
      ..execute("UPDATE card SET delete_batch_id = 'B' WHERE id = 'K'")
      ..execute('DELETE FROM sync_outbox')
      ..execute(
        "INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at, attempts) "
        "VALUES ('op-r', 'deck', 'R', 'upsert', 9, 1)",
      );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 14);

    final kept = await db
        .customSelect(
          "SELECT op_id, op, attempts, payload FROM sync_outbox WHERE entity_id = 'R'",
        )
        .getSingle();
    expect(kept.data, {
      'op_id': 'op-r',
      'op': 'upsert',
      'attempts': 1,
      'payload': null,
    });

    await db.customStatement("DELETE FROM delete_batches WHERE id = 'B'");
    final purged = await db
        .customSelect(
          "SELECT entity_type, op, payload FROM sync_outbox "
          "WHERE entity_id IN ('D', 'K') ORDER BY entity_type",
        )
        .get();
    expect(
      [for (final row in purged) row.data],
      [
        {
          'entity_type': 'card',
          'op': 'delete',
          'payload': '{"deleteBatchId":"B","serverVersion":null}',
        },
        {
          'entity_type': 'deck',
          'op': 'delete',
          'payload': '{"deleteBatchId":"B","serverVersion":null}',
        },
      ],
    );
  });
}
