import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_schedule_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/entity_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

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

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES (?, 'c', ?, ?, 2, 'unset', 0, 0, 0)",
      [id, parent, parent],
    );

Future<String?> _name(AppDatabase db, String id) async => (await (db.select(
  db.deck,
)..where((d) => d.id.equals(id))).getSingleOrNull())?.name;

class _Device {
  _Device(
    FakeSyncServer server, {
    int pullLimit = SyncCoordinator.pullPageSize,
    List<EntitySyncAdapter> Function(AppDatabase db)? adapters,
  }) : db = openTestDatabase() {
    final cards = CardSyncAdapter(db);
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters:
          adapters?.call(db) ??
          [
            DeleteBatchSyncAdapter(db),
            DeckSyncAdapter(db),
            TagSyncAdapter(db, SyncStore(db)),
            cards,
            CardScheduleSyncAdapter(db, SyncStore(db)),
            ReviewLogSyncAdapter(db),
            AccountSettingsSyncAdapter(db),
          ],
      pullLimit: pullLimit,
      afterPull: cards.ensureSchedules,
    );
  }

  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

Map<String, Object?> _rootRow(String id) => {
  'id': id,
  'name': id,
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
  'createdAt': '2026-09-28T00:00:00Z',
  'updatedAt': '2026-09-28T00:00:00Z',
};

Map<String, Object?> _cardRow(String id, String deckId) => {
  'id': id,
  'deckId': deckId,
  'front': 'f',
  'back': 'b',
  'isFlagged': false,
  'example': null,
  'hint': null,
  'pronunciation': null,
  'deleteBatchId': null,
  'createdAt': '2026-09-28T00:00:00Z',
  'updatedAt': '2026-09-28T00:00:00Z',
};

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a deck created on one device reaches the other', () async {
    await _root(a.db, 'R', name: 'Korean');
    await _child(a.db, 'C', 'R');

    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    expect(await _name(b.db, 'R'), 'Korean');
    expect(await _name(b.db, 'C'), 'c');
    expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
    expect(
      await b.db.select(b.db.syncOutbox).get(),
      isEmpty,
      reason: 'pulled rows must not echo',
    );
  });

  test('an edit made while its push is in flight survives the ack', () async {
    await _root(a.db, 'R', name: 'first');
    server.duringPush = () async {
      server.duringPush = null;
      await a.db.customStatement(
        "UPDATE deck SET name = 'second' WHERE id = 'R'",
      );
    };

    await a.coordinator.runOnce();
    expect(await a.db.select(a.db.syncOutbox).get(), hasLength(1));

    await a.coordinator.runOnce();
    expect(server.row('deck', 'R')!.row!['name'], 'second');
  });

  test('a rejection applies the server copy', () async {
    await _root(a.db, 'R', name: 'server name');
    await a.coordinator.runOnce();
    await a.db.customStatement(
      "UPDATE deck SET name = 'refused' WHERE id = 'R'",
    );
    server.rejectNext['deck/R'] = 'DECK_TREE_CYCLE';

    await a.coordinator.runOnce();

    expect(await _name(a.db, 'R'), 'server name');
    expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
  });

  test('a rejection never overwrites a newer local edit', () async {
    await _root(a.db, 'R', name: 'server name');
    await a.coordinator.runOnce();
    await a.db.customStatement(
      "UPDATE deck SET name = 'refused' WHERE id = 'R'",
    );
    server.rejectNext['deck/R'] = 'DECK_TREE_CYCLE';
    server.duringPush = () async {
      server.duringPush = null;
      await a.db.customStatement(
        "UPDATE deck SET name = 'newest' WHERE id = 'R'",
      );
    };

    await a.coordinator.runOnce();

    expect(await _name(a.db, 'R'), 'newest');
  });

  test('pull skips a row with a pending local edit', () async {
    await _root(a.db, 'R', name: 'shared');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    await b.db.customStatement(
      "UPDATE deck SET name = 'b edit' WHERE id = 'R'",
    );
    await a.db.customStatement(
      "UPDATE deck SET name = 'a edit' WHERE id = 'R'",
    );
    await a.coordinator.runOnce();

    await b.coordinator.runOnce();

    expect(await _name(b.db, 'R'), 'b edit');
    expect(server.row('deck', 'R')!.row!['name'], 'b edit');
  });

  test('a rejection of a row the server never saw keeps the local row and its cards', () async {
    await _root(a.db, 'R', name: 'offline only');
    await a.db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) "
      "VALUES ('C', 'c', 'R', 'R', 2, 'card', 0, 0, 0)",
    );
    await a.db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, created_at, updated_at) "
      "VALUES ('k', 'C', 'f', 'b', 'f', 'b', 0, 0)",
    );
    server.rejectNext['deck/R'] = 'VALIDATION_FAILED';
    server.rejectNext['deck/C'] = 'DECK_PARENT_MISSING';

    await a.coordinator.runOnce();

    expect(await _name(a.db, 'R'), 'offline only');
    final cards = await a.db
        .customSelect("SELECT id FROM card WHERE id = 'k'")
        .get();
    expect(cards, hasLength(1));
  });

  test('a child that arrives before its parent applies', () async {
    server.seed('deck', 'C', {...await _wireChild('C', 'R')});
    server.seed('deck', 'R', await _wireRoot('R'));

    await b.coordinator.runOnce();

    expect(await _name(b.db, 'C'), 'c');
  });

  test('a tombstone deletes the deck and its local subtree', () async {
    await _root(a.db, 'R');
    await _child(a.db, 'C', 'R');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    await a.db.customStatement("DELETE FROM deck WHERE id = 'R'");
    await a.coordinator.runOnce();

    await b.coordinator.runOnce();

    expect(await _name(b.db, 'R'), isNull);
    expect(await _name(b.db, 'C'), isNull);
  });

  test(
    'a refusal without a server copy is recorded; a later apply clears it',
    () async {
      await _root(a.db, 'R', name: 'offline only');
      server.rejectNext['deck/R'] = 'VALIDATION_FAILED';

      await a.coordinator.runOnce();
      final store = SyncStore(a.db);
      expect((await store.rejections()).map((r) => '${r.entityId}:${r.code}'), [
        'R:VALIDATION_FAILED',
      ]);

      await a.coordinator.requeueRejected();
      await a.coordinator.runOnce();
      expect(await store.rejections(), isEmpty);
    },
  );

  test('a refusal with a server copy is not recorded', () async {
    await _root(a.db, 'R');
    await a.coordinator.runOnce();
    await a.db.customStatement("UPDATE deck SET name = 'x' WHERE id = 'R'");
    server.rejectNext['deck/R'] = 'SYNC_ENTITY_CONFLICT';

    await a.coordinator.runOnce();

    expect(await SyncStore(a.db).rejections(), isEmpty);
  });

  test('requeue turns a vanished entity into a delete', () async {
    await _root(a.db, 'R');
    server.rejectNext['deck/R'] = 'VALIDATION_FAILED';
    await a.coordinator.runOnce();
    await SyncStore(a.db).applyingRemote(
      () => a.db.customStatement("DELETE FROM deck WHERE id = 'R'"),
    );

    await a.coordinator.requeueRejected();

    final queued = await SyncStore(a.db).pendingBatch(['deck'], 10);
    expect(queued.single.op, 'delete');
  });
  test(
    'a failed page keeps nothing of the pull and does not move since',
    () async {
      server
        ..seed('deck', 'R1', _rootRow('R1'))
        ..seed('deck', 'R2', _rootRow('R2'))
        ..seed('deck', 'R3', _rootRow('R3'))
        ..failChangesAfter = 2;
      final device = _Device(server, pullLimit: 2);
      addTearDown(device.db.close);

      await expectLater(device.coordinator.runOnce(), throwsStateError);

      expect(await _name(device.db, 'R1'), isNull);
      expect(await SyncStore(device.db).since(), 0);
    },
  );

  test('a new adapter pulls its type from since 0', () async {
    server
      ..seed('deck', 'R', _rootRow('R'))
      ..seed('card', 'K', _cardRow('K', 'R'));
    final old = _Device(
      server,
      adapters: (db) => [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
    );
    addTearDown(old.db.close);
    await old.coordinator.runOnce();
    expect(await SyncStore(old.db).since(), 2, reason: 'the card was skipped');

    final upgraded = SyncCoordinator(
      api: server,
      store: SyncStore(old.db),
      adapters: [
        DeckSyncAdapter(old.db),
        DeleteBatchSyncAdapter(old.db),
        CardSyncAdapter(old.db),
      ],
    );
    await upgraded.runOnce();

    expect(
      await (old.db.select(
        old.db.card,
      )..where((c) => c.id.equals('K'))).getSingleOrNull(),
      isNotNull,
    );
    expect(await SyncStore(old.db).pullEntityTypes(), 'card,deck,delete_batch');
  });

  test('a pulled card gets its initial schedule in the same pull', () async {
    server
      ..seed('card', 'K', _cardRow('K', 'R'))
      ..seed('deck', 'R', _rootRow('R'));
    await b.coordinator.runOnce();
    final schedule = await (b.db.select(
      b.db.cardSchedule,
    )..where((s) => s.cardId.equals('K'))).getSingle();
    expect(schedule.schedulerType, 'sm2');
  });
}

Future<Map<String, Object?>> _wireRoot(String id) async => {
  'id': id,
  'name': 'r',
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
  'createdAt': '2026-09-27T01:00:00Z',
  'updatedAt': '2026-09-27T01:00:00Z',
};

Future<Map<String, Object?>> _wireChild(String id, String parent) async => {
  ...await _wireRoot(id),
  'name': 'c',
  'parentId': parent,
  'rootId': parent,
  'depth': 2,
  'contentType': 'unset',
  'schedulerType': null,
  'schedulerVersion': null,
  'generation': null,
};
