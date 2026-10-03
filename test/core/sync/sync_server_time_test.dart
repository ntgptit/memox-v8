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
}
