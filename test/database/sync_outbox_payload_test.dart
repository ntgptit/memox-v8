import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/test_database.dart';

// DEV-181: a purge's delete carries the batch it purged, so the server can
// tell a row still in that batch from one another device restored. The
// delete triggers of deck and card keep `old.delete_batch_id` in the outbox
// entry's payload with the row's acknowledged version; a delete outside the
// Trash carries none.

Future<Map<String, Object?>> _entry(
  AppDatabase db,
  String type,
  String id,
) async =>
    (await db
            .customSelect(
              'SELECT op, payload FROM sync_outbox WHERE entity_type = ? AND entity_id = ?',
              variables: [Variable(type), Variable(id)],
            )
            .getSingle())
        .data;

void main() {
  late AppDatabase db;
  setUp(() async {
    db = openTestDatabase();
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES ('D', 'd', 'R', 'R', 2, 'card', 0, 0, 0), "
      "('E', 'e', 'R', 'R', 2, 'card', 1, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('K', 'D', 'f', 'b', 0, 0), ('M', 'E', 'f', 'b', 0, 0)",
    );
    await db.customStatement(
      "UPDATE card SET server_version = 7 WHERE id = 'K'",
    );
  });
  tearDown(() => db.close());

  test('a purge queues each deleted deck and card with its batch', () async {
    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
      "VALUES ('B', 'deck', 'D', 100)",
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'B' WHERE id = 'D'",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'B' WHERE id = 'K'",
    );
    await db.customStatement('DELETE FROM sync_outbox');

    await db.customStatement("DELETE FROM delete_batches WHERE id = 'B'");

    expect(await _entry(db, 'deck', 'D'), {
      'op': 'delete',
      'payload': '{"deleteBatchId":"B","serverVersion":null}',
    });
    expect(await _entry(db, 'card', 'K'), {
      'op': 'delete',
      'payload': '{"deleteBatchId":"B","serverVersion":7}',
    });
    expect(await _entry(db, 'delete_batch', 'B'), {
      'op': 'delete',
      'payload': null,
    });
  });

  test('a delete outside the Trash carries no batch', () async {
    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement("DELETE FROM deck WHERE id = 'E'");

    expect(await _entry(db, 'deck', 'E'), {'op': 'delete', 'payload': null});
    expect(await _entry(db, 'card', 'M'), {'op': 'delete', 'payload': null});
  });

  test('a row written again after a delete drops the batch', () async {
    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
      "VALUES ('B', 'card', 'K', 100)",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'B' WHERE id = 'K'",
    );
    await db.customStatement("DELETE FROM delete_batches WHERE id = 'B'");
    expect((await _entry(db, 'card', 'K'))['payload'], isNotNull);

    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('K', 'D', 'f', 'b', 0, 0)",
    );

    expect(await _entry(db, 'card', 'K'), {'op': 'upsert', 'payload': null});
  });
}
