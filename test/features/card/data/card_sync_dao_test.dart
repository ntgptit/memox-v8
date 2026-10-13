import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';

import '../../../support/test_database.dart';

Future<void> _root(
  AppDatabase db,
  String id,
  String scheduler,
) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', ?, 1, 3, 0, 0, 0)",
  [id, id, scheduler],
);

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES (?, 'c', ?, ?, 2, 'card', 0, 0, 0)",
      [id, parent, parent],
    );

Map<String, Object?> _wire(String id, String deckId) => {
  'id': id,
  'deckId': deckId,
  'front': ' Äpfel ',
  'back': 'APPLE',
  'isFlagged': true,
  'example': 'ex',
  'hint': null,
  'pronunciation': 'ap',
  'deleteBatchId': null,
  'createdAt': '2026-09-28T01:02:03Z',
  'updatedAt': '2026-09-28T01:02:04Z',
  'tagIds': <String>[],
};

void main() {
  late AppDatabase db;
  late CardSyncDao adapter;
  setUp(() {
    db = openTestDatabase();
    adapter = CardSyncDao(db);
  });
  tearDown(() => db.close());

  test('a pulled card reads back as the same wire row', () async {
    await _root(db, 'R', 'sm2');
    await _child(db, 'D', 'R');

    await adapter.upsertFromServer(_wire('K', 'D'), 9);

    expect(await adapter.readRow('K'), _wire('K', 'D'));
    final row = await (db.select(
      db.card,
    )..where((c) => c.id.equals('K'))).getSingle();
    expect(row.serverVersion, 9);
    expect(row.frontFolded, 'äpfel', reason: 'folded as the repository folds');
    expect(row.backFolded, 'apple');
    expect(row.isFlagged, 1);
  });

  test(
    'a row without isFlagged, from a build before the key, takes the default '
    '(server sync spec §4.4)',
    () async {
      await db.customStatement(
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
        "scheduler_version, generation, sibling_position, created_at, updated_at) "
        "VALUES ('D', 'd', NULL, 'D', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
      );
      await adapter.upsertFromServer(_wire('K', 'D')..remove('isFlagged'), 9);

      final card = await (db.select(
        db.card,
      )..where((c) => c.id.equals('K'))).getSingle();
      expect(card.isFlagged, 0);
    },
  );

  test('a deleted card and a missing card read as null', () async {
    await _root(db, 'R', 'sm2');
    await adapter.upsertFromServer(_wire('K', 'R'), 1);
    await adapter.deleteFromServer('K');
    expect(await adapter.readRow('K'), isNull);
    expect(await adapter.readRow('nope'), isNull);
  });

  test('markAcknowledged records the version', () async {
    await _root(db, 'R', 'sm2');
    await adapter.upsertFromServer(_wire('K', 'R'), 1);
    await adapter.markAcknowledged('K', 42);
    final row = await (db.select(
      db.card,
    )..where((c) => c.id.equals('K'))).getSingle();
    expect(row.serverVersion, 42);
  });

  test('tagIds read and write the card links', () async {
    await _root(db, 'R', 'sm2');
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('b', 'b', 'b', 0), ('a', 'a', 'a', 0)",
    );
    await adapter.upsertFromServer({
      ..._wire('K', 'R'),
      'tagIds': ['b', 'a'],
    }, 1);
    expect((await adapter.readRow('K'))!['tagIds'], ['a', 'b']);

    await adapter.upsertFromServer({
      ..._wire('K', 'R'),
      'tagIds': ['a'],
    }, 2);
    expect((await adapter.readRow('K'))!['tagIds'], ['a']);

    final withoutKey = _wire('K', 'R')..remove('tagIds');
    await adapter.upsertFromServer(withoutKey, 3);
    expect((await adapter.readRow('K'))!['tagIds'], ['a'], reason: 'R10');
  });
}
