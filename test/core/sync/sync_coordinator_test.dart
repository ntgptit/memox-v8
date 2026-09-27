import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_entity_ref.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:memox/core/sync/sync_outbox.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

const _t = '2026-09-28T00:00:00Z';

Map<String, Object?> _rootRow(String id, String name) => {
  'id': id,
  'name': name,
  'parentId': null,
  'rootId': id,
  'depth': 1,
  'contentType': 'deck',
  'schedulerType': 'sm2',
  'schedulerVersion': 1,
  'schedulerConfig': null,
  'studyConfig': null,
  'generation': 1,
  'firstAnsweredAt': null,
  'sourceTemplateId': null,
  'sourceTemplateVersion': null,
  'deleteBatchId': null,
  'siblingPosition': 0,
  'createdAt': _t,
  'updatedAt': _t,
};

Future<void> _root(
  AppDatabase db,
  String id, {
  String name = 'r',
}) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, ?, NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, name, id],
);

Future<String?> _name(AppDatabase db, String id) async => (await (db.select(
  db.deck,
)..where((d) => d.id.equals(id))).getSingleOrNull())?.name;

void main() {
  late FakeSyncServer server;
  late AppDatabase db;
  late SyncOutboxWriter outbox;
  late SyncCoordinator coordinator;
  setUp(() {
    server = FakeSyncServer();
    db = openTestDatabase();
    outbox = SyncOutboxWriter(db);
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters: [
        DeckSyncAdapter(db),
        DeleteBatchSyncAdapter(db),
        CardSyncAdapter(db),
      ],
      pullPageSize: 2,
    );
  });
  tearDown(() => db.close());

  test(
    'a command is pushed as recorded and leaves the outbox when applied',
    () async {
      await db.transaction(() async {
        await _root(db, 'R');
        await outbox.command(SyncCommandType.createRootDeck, {
          'id': 'R',
          'name': 'r',
          'schedulerType': 'sm2',
        }, subject: const SyncEntityRef.deck('R'));
      });

      await coordinator.runOnce();

      final op = server.pushed.single;
      expect(op.kind, 'command');
      expect(op.type, 'CREATE_ROOT_DECK');
      expect(op.affected, [
        {'entityType': 'deck', 'entityId': 'R'},
      ]);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  test(
    'a patch recorded twice is pushed once with the latest fields',
    () async {
      await _root(db, 'R');
      await outbox.patch('deck', 'R', SyncPatchGroup.studyOptions);
      await db.customStatement(
        "UPDATE deck SET study_config = '{\"cardLimit\":9}' WHERE id = 'R'",
      );
      await outbox.patch('deck', 'R', SyncPatchGroup.studyOptions);

      await coordinator.runOnce();

      expect(server.pushed, hasLength(1));
      expect(server.pushed.single.fields, {'studyConfig': '{"cardLimit":9}'});
    },
  );

  test(
    'a rejection overwrites every affected row the server returns',
    () async {
      await _root(db, 'R', name: 'mine');
      await outbox.command(SyncCommandType.renameDeck, {
        'deckId': 'R',
        'name': 'mine',
      });
      server.rejectNext['RENAME_DECK'] = (
        'SYNC_ENTITY_CONFLICT',
        [
          SyncChangeModel(
            entityType: 'deck',
            entityId: 'R',
            serverVersion: 4,
            isDeleted: false,
            row: _rootRow('R', 'server'),
          ),
        ],
      );

      await coordinator.runOnce();

      expect(await _name(db, 'R'), 'server');
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    },
  );

  test('an absent entity is deleted only when its parent was purged', () async {
    await _root(db, 'P');
    await _root(db, 'V');
    await outbox.command(SyncCommandType.createSubDeck, {'id': 'P'});
    await outbox.command(SyncCommandType.renameDeck, {'deckId': 'V'});
    server.rejectNext['CREATE_SUB_DECK'] = (
      'DECK_PARENT_MISSING',
      [
        const SyncChangeModel(
          entityType: 'deck',
          entityId: 'P',
          serverVersion: 0,
          isDeleted: true,
          row: null,
        ),
      ],
    );
    server.rejectNext['RENAME_DECK'] = (
      'VALIDATION_FAILED',
      [
        const SyncChangeModel(
          entityType: 'deck',
          entityId: 'V',
          serverVersion: 0,
          isDeleted: true,
          row: null,
        ),
      ],
    );

    await coordinator.runOnce();

    expect(await _name(db, 'P'), isNull);
    expect(
      await _name(db, 'V'),
      'r',
      reason: 'a bug or a legacy row never deletes local data',
    );
  });

  test(
    'a pull applies every page in one transaction; a failure keeps the cursor',
    () async {
      server
        ..publish('deck', 'A', _rootRow('A', 'a'))
        ..publish('deck', 'B', _rootRow('B', 'b'))
        ..publish('deck', 'C', _rootRow('C', 'c'))
        ..failChangesCall = 1;

      await expectLater(coordinator.runOnce(), throwsStateError);

      expect(await _name(db, 'A'), isNull);
      expect(await SyncStore(db).since(), 0);

      server.failChangesCall = null;
      await coordinator.runOnce();
      expect(await _name(db, 'C'), 'c');
      expect(await SyncStore(db).since(), 3);
    },
  );

  test('a pulled change skips an entity that is still pending', () async {
    await _root(db, 'R', name: 'local');
    await outbox.command(SyncCommandType.renameDeck, {
      'deckId': 'R',
      'name': 'local',
    }, subject: const SyncEntityRef.deck('R'));
    server.publish('deck', 'R', _rootRow('R', 'server'));

    await coordinator.pull();

    expect(await _name(db, 'R'), 'local');
  });

  test('a card change is pulled with its folded columns', () async {
    await _root(db, 'R');
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) "
      "VALUES ('D', 'd', 'R', 'R', 2, 'card', 0, 0, 0)",
    );
    server.publish('card', 'k1', {
      'id': 'k1',
      'deckId': 'D',
      'front': 'Ả',
      'back': 'b',
      'isFlagged': false,
      'createdAt': _t,
      'updatedAt': _t,
    });

    await coordinator.runOnce();

    final card = await (db.select(
      db.card,
    )..where((c) => c.id.equals('k1'))).getSingle();
    expect(card.frontFolded, 'ả');
  });
}
