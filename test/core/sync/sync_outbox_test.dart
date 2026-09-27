import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_outbox.dart';

import '../../support/test_database.dart';

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

List<SyncEntityRef> _affected(SyncOutboxEntry entry) => [
  for (final item in jsonDecode(entry.affected) as List)
    SyncEntityRef.fromJson(item as Map<String, Object?>),
];

void main() {
  late AppDatabase db;
  late SyncOutboxWriter outbox;
  setUp(() {
    db = openTestDatabase();
    outbox = SyncOutboxWriter(db);
  });
  tearDown(() => db.close());

  test(
    'a command carries every id its write changed, then the collector is empty',
    () async {
      await db.transaction(() async {
        await _root(db, 'R');
        await _root(db, 'S');
        await outbox.command(SyncCommandType.createRootDeck, {
          'id': 'R',
          'name': 'r',
          'schedulerType': 'sm2',
        }, subject: const SyncEntityRef.deck('R'));
      });

      final entry = (await db.select(db.syncOutbox).get()).single;
      expect(entry.kind, 'command');
      expect(entry.commandType, 'CREATE_ROOT_DECK');
      expect(jsonDecode(entry.payload!), {
        'id': 'R',
        'name': 'r',
        'schedulerType': 'sm2',
      });
      expect(_affected(entry).toSet(), {
        const SyncEntityRef.deck('R'),
        const SyncEntityRef.deck('S'),
      });
      expect(
        await db.customSelect('SELECT * FROM sync_changed').get(),
        isEmpty,
      );
    },
  );

  test(
    'two patches of one field group keep the first seq and a new op id',
    () async {
      await _root(db, 'R');
      await outbox.patch(SyncEntityType.deck, 'R', SyncPatchGroup.studyOptions);
      final first = (await db.select(db.syncOutbox).get()).single;

      await outbox.patch(SyncEntityType.deck, 'R', SyncPatchGroup.studyOptions);

      final second = (await db.select(db.syncOutbox).get()).single;
      expect(second.seq, first.seq);
      expect(second.opId, isNot(first.opId));
    },
  );

  test('commands are never coalesced', () async {
    await outbox.command(SyncCommandType.renameDeck, {
      'deckId': 'R',
      'name': 'a',
    });
    await outbox.command(SyncCommandType.renameDeck, {
      'deckId': 'R',
      'name': 'b',
    });
    expect(await db.select(db.syncOutbox).get(), hasLength(2));
  });
}
