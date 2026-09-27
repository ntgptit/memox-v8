import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';

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
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters: [DeckSyncAdapter(db), DeleteBatchSyncAdapter(db)],
    );
  }

  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

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
