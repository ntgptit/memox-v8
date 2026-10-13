import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';

import '../../support/deck_fixtures.dart';
import '../../support/test_database.dart';
import 'fake_sync_server.dart';

/// The offline-first invariant end to end (app deck-sync spec §5, DEV-226):
/// a business write through a repository reaches the server by the trigger,
/// the outbox stream and the scheduler alone, with nobody calling `syncNow`.
/// Real Drift, the real coordinator and scheduler, a fake server and real
/// zero-length timers.
class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    store = SyncStore(db);
    decks = DeckRepositoryImpl(db);
    coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncDao(db),
        DeckSyncDao(db),
        TagSyncDao(db, store),
        CardSyncDao(db),
        CardScheduleSyncDao(db, store),
        ReviewLogSyncDao(db),
        AccountSettingsSyncDao(db),
      ],
    );
  }

  final AppDatabase db;
  late final SyncStore store;
  late final DeckRepositoryImpl decks;
  late final SyncCoordinator coordinator;
  var runs = 0;

  /// The scheduler as `syncSchedulerProvider` wires it, debounce aside.
  SyncScheduler scheduler() => SyncScheduler(
    run: () {
      runs++;
      return coordinator.runOnce();
    },
    triggers: store.outboxChanges().skip(1),
    debounce: Duration.zero,
  );
}

/// Pumps the event queue until [done], or gives up after a bound.
Future<bool> _until(Future<bool> Function() done) async {
  for (var i = 0; i < 100; i++) {
    await pumpEventQueue();
    if (await done()) return true;
  }
  return false;
}

/// Pumps a while and reports whether more runs happened meanwhile.
Future<bool> _runsSettled(_Device device) async {
  final before = device.runs;
  for (var i = 0; i < 20; i++) {
    await pumpEventQueue();
  }
  return device.runs == before;
}

void main() {
  late FakeSyncServer server;
  late _Device a;
  late SyncScheduler scheduler;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
  });
  tearDown(() async {
    scheduler.dispose();
    await a.db.close();
  });

  test(
    'a deck made through the repository reaches the server on its own',
    () async {
      scheduler = a.scheduler()..start();
      expect(await _until(() async => a.runs == 1), isTrue, reason: 'at start');

      final deck = await a.decks.root('Korean');

      expect(
        await _until(() async => server.row('deck', deck.id) != null),
        isTrue,
        reason: 'the trigger, the stream and the scheduler carried it',
      );
      expect(await a.store.pendingCount(), 0);
      expect(server.pushCalls, 1);
    },
  );

  test(
    'a pull echoes nothing back and does not keep the scheduler running',
    () async {
      final b = _Device(server);
      addTearDown(b.db.close);
      final deck = await b.decks.root('Korean');
      await b.coordinator.runOnce();
      final pushesBefore = server.pushCalls;

      scheduler = a.scheduler()..start();
      expect(
        await _until(
          () async => (await a.db.select(a.db.deck).get()).isNotEmpty,
        ),
        isTrue,
        reason: 'the first run pulled the deck',
      );
      expect(await _runsSettled(a), isTrue, reason: 'no pull → run loop');

      expect(server.pushCalls, pushesBefore, reason: 'nothing echoed back');
      expect(await a.store.pendingCount(), 0);
      expect(server.row('deck', deck.id)!.row?['name'], 'Korean');
    },
  );
}
