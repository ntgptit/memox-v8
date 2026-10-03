import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

// SP2b 2.30 (R10): the server's clock as of the last pull, kept for the Trash
// purge clock to be bounded by.
void main() {
  late AppDatabase db;
  late SyncStore store;
  late FakeSyncServer server;
  late SyncCoordinator coordinator;
  final seen = DateTime.utc(2026, 10, 3, 8);

  setUp(() {
    db = openTestDatabase();
    store = SyncStore(db);
    server = FakeSyncServer();
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [DeckSyncAdapter(db)],
    );
  });
  tearDown(() => db.close());

  test('no server time is known before the first sync', () async {
    expect(await store.serverTime(), isNull);
  });

  test('the store keeps the time as UTC milliseconds', () async {
    await store.recordServerTime(seen);

    expect(await store.serverTime(), seen);
  });

  test('a pull stores the server time of its page', () async {
    server.serverTimeMillis = seen.millisecondsSinceEpoch;

    await coordinator.runOnce();

    expect(await store.serverTime(), seen);
  });

  test('a page without it keeps the last one (an old server)', () async {
    server.serverTimeMillis = seen.millisecondsSinceEpoch;
    await coordinator.runOnce();
    server.serverTimeMillis = null;

    await coordinator.runOnce();

    expect(await store.serverTime(), seen);
  });

  test('the store never moves the time backwards', () async {
    await store.recordServerTime(seen);

    await store.recordServerTime(seen.subtract(const Duration(days: 1)));
    expect(await store.serverTime(), seen);

    await store.recordServerTime(seen.add(const Duration(days: 1)));
    expect(await store.serverTime(), seen.add(const Duration(days: 1)));
  });

  test(
    'a server whose clock reads earlier does not pull the time back',
    () async {
      server.serverTimeMillis = seen.millisecondsSinceEpoch;
      await coordinator.runOnce();
      server.serverTimeMillis = seen
          .subtract(const Duration(hours: 5))
          .millisecondsSinceEpoch;

      await coordinator.runOnce();

      expect(await store.serverTime(), seen);
    },
  );

  test('a pull that fails on a later page keeps the old time', () async {
    server.serverTimeMillis = seen.millisecondsSinceEpoch;
    await coordinator.runOnce();
    final later = seen.add(const Duration(days: 2));
    server
      ..seed('deck', 'R1', _root('R1'))
      ..seed('deck', 'R2', _root('R2'))
      ..seed('deck', 'R3', _root('R3'))
      ..serverTimeMillis = later.millisecondsSinceEpoch
      ..failChangesAfter = 2;
    final paged = SyncCoordinator(
      api: server,
      store: store,
      adapters: [DeckSyncAdapter(db)],
      pullLimit: 2,
    );

    await expectLater(paged.runOnce(), throwsStateError);

    expect(await store.serverTime(), seen);
  });

  test('a pull rolled back after its pages keeps the old time', () async {
    server.serverTimeMillis = seen.millisecondsSinceEpoch;
    await coordinator.runOnce();
    server
      ..seed('deck', 'R1', _root('R1'))
      ..serverTimeMillis = seen
          .add(const Duration(days: 2))
          .millisecondsSinceEpoch;
    final failing = SyncCoordinator(
      api: server,
      store: store,
      adapters: [DeckSyncAdapter(db)],
      afterPull: () async => throw StateError('after pull'),
    );

    await expectLater(failing.runOnce(), throwsStateError);

    expect(await store.serverTime(), seen);
    expect(await store.since(), 0);
  });

  test('a pull of several pages stores the time of the last page', () async {
    final second = seen.add(const Duration(minutes: 1));
    server
      ..seed('deck', 'R1', _root('R1'))
      ..seed('deck', 'R2', _root('R2'))
      ..seed('deck', 'R3', _root('R3'))
      ..pageTimes.addAll([
        seen.millisecondsSinceEpoch,
        second.millisecondsSinceEpoch,
      ]);
    final paged = SyncCoordinator(
      api: server,
      store: store,
      adapters: [DeckSyncAdapter(db)],
      pullLimit: 2,
    );

    await paged.runOnce();

    expect(await store.serverTime(), second);
  });
}

Map<String, Object?> _root(String id) => {
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
