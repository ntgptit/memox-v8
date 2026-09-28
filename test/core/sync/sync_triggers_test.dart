import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';

import '../../support/test_database.dart';

Future<List<Map<String, Object?>>> _outbox(AppDatabase db) async => [
  for (final row
      in await db
          .customSelect('SELECT * FROM sync_outbox ORDER BY created_at, rowid')
          .get())
    row.data,
];

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) "
      "VALUES (?, 'c', ?, ?, 2, 'unset', 0, 0, 0)",
      [id, parent, parent],
    );

Future<void> _card(AppDatabase db, String id, String deck) =>
    db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES (?, ?, 'f', 'b', 0, 0)",
      [id, deck],
    );

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('an insert queues one upsert with a UUID op id', () async {
    await _root(db, 'R');

    final outbox = await _outbox(db);
    expect(outbox, hasLength(1));
    expect(outbox.single['entity_type'], 'deck');
    expect(outbox.single['entity_id'], 'R');
    expect(outbox.single['op'], 'upsert');
    expect(
      outbox.single['op_id'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
  });

  test(
    'a later write replaces the op id but keeps created_at and order',
    () async {
      await _root(db, 'R');
      await _child(db, 'C', 'R');
      final before = await _outbox(db);

      await db.customStatement(
        "UPDATE deck SET name = 'renamed' WHERE id = 'R'",
      );

      final after = await _outbox(db);
      expect(after.map((e) => e['entity_id']), ['R', 'C']);
      expect(after.first['op_id'], isNot(before.first['op_id']));
      expect(after.first['created_at'], before.first['created_at']);
    },
  );

  test('a delete, cascades included, queues deletes', () async {
    await _root(db, 'R');
    await _child(db, 'C', 'R');

    await db.customStatement("DELETE FROM deck WHERE id = 'R'");

    final outbox = await _outbox(db);
    expect(
      {for (final e in outbox) e['entity_id']: e['op']},
      {'R': 'delete', 'C': 'delete'},
    );
  });

  test('delete_batches are captured too', () async {
    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
      "VALUES ('B', 'deck', 'R', 0)",
    );

    expect((await _outbox(db)).single['entity_type'], 'delete_batch');
  });

  test('writes under applying_remote are not captured', () async {
    await db.transaction(() async {
      await db.customStatement(
        'INSERT INTO sync_state (name, value) VALUES (?, ?)',
        [syncApplyingRemoteKey, '1'],
      );
      await _root(db, 'R');
      await db.customStatement('DELETE FROM sync_state WHERE name = ?', [
        syncApplyingRemoteKey,
      ]);
    });

    expect(await _outbox(db), isEmpty);
  });

  test('a card insert, update and delete queue one card entry', () async {
    await _root(db, 'R');
    await _card(db, 'K', 'R');
    await db.customStatement("UPDATE card SET front = 'g' WHERE id = 'K'");
    var cards = (await _outbox(db)).where((e) => e['entity_type'] == 'card');
    expect(cards.single['op'], 'upsert');

    await db.customStatement("DELETE FROM card WHERE id = 'K'");
    cards = (await _outbox(db)).where((e) => e['entity_type'] == 'card');
    expect(cards.single['op'], 'delete');
  });

  test('a card written under applying_remote queues nothing', () async {
    await _root(db, 'R');
    await db.customStatement(
      "INSERT INTO sync_state (name, value) VALUES ('$syncApplyingRemoteKey', '1')",
    );
    await _card(db, 'K', 'R');
    expect(
      (await _outbox(db)).where((e) => e['entity_type'] == 'card'),
      isEmpty,
    );
  });

  test('deleting a deck queues a delete for each of its cards', () async {
    await _root(db, 'R');
    await _card(db, 'K1', 'R');
    await _card(db, 'K2', 'R');
    await db.customStatement("DELETE FROM deck WHERE id = 'R'");
    final cards = (await _outbox(db)).where((e) => e['entity_type'] == 'card');
    expect(
      {for (final e in cards) e['entity_id']: e['op']},
      {'K1': 'delete', 'K2': 'delete'},
    );
  });
}
