import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

// How the push half of a run treats what comes back, or does not (ADR-013,
// app deck-sync spec §5):
// - DEV-225: a change the server has not confirmed never leaves the outbox,
//   and a retry with the same op id after a lost response converges on one
//   server version;
// - DEV-183: a refused row whose server copy this device cannot hold yet
//   fails only that entity, so the run goes on and the pull resolves it.

class _Device {
  _Device(FakeSyncServer server) : db = openTestDatabase() {
    final store = SyncStore(db);
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
  late final SyncCoordinator coordinator;

  Future<List<SyncOutboxEntry>> outbox() => db.select(db.syncOutbox).get();

  Future<List<SyncRejectionEntry>> rejections() =>
      db.select(db.syncRejection).get();

  Future<int> since() => SyncStore(db).since();

  Future<({String? name, String? parentId, int? serverVersion})?> deck(
    String id,
  ) async {
    final row = await db
        .customSelect(
          'SELECT name, parent_id, server_version FROM deck WHERE id = ?',
          variables: [Variable(id)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      name: row.read<String>('name'),
      parentId: row.readNullable<String>('parent_id'),
      serverVersion: row.readNullable<int>('server_version'),
    );
  }
}

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

Future<void> _child(
  AppDatabase db,
  String id,
  String parent, {
  int depth = 2,
}) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
  "sibling_position, created_at, updated_at) VALUES (?, 'c', ?, 'R', ?, 'unset', 0, 0, 0)",
  [id, parent, depth],
);

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

  group('a push that fails keeps the outbox (DEV-225, ADR-013)', () {
    test('thrown before the server: the entry stays with the same op id, one '
        'more attempt, and the next run converges', () async {
      await _root(a.db, 'R');
      final before = (await a.outbox()).single;
      server.duringPush = () async => throw const SocketException('offline');

      await expectLater(
        a.coordinator.runOnce(),
        throwsA(isA<SocketException>()),
      );

      final after = (await a.outbox()).single;
      expect(after.opId, before.opId);
      expect(after.attempts, before.attempts + 1);
      expect(await a.since(), 0);
      expect(server.row('deck', 'R'), isNull);

      server.duringPush = null;
      await a.coordinator.runOnce();

      expect(await a.outbox(), isEmpty);
      expect(server.row('deck', 'R')?.serverVersion, 1);
      expect((await a.deck('R'))?.serverVersion, 1);
      expect(server.pushCalls, 2);
    });

    test('committed on the server, response lost: the retry resends the op id, '
        'the server does not apply it again, and the ack lands', () async {
      await _root(a.db, 'R');
      final before = (await a.outbox()).single;
      server.afterPushCommit = () async {
        server.afterPushCommit = null;
        throw const SocketException('response lost');
      };

      await expectLater(
        a.coordinator.runOnce(),
        throwsA(isA<SocketException>()),
      );

      expect((await a.outbox()).single.opId, before.opId);
      expect((await a.deck('R'))?.serverVersion, isNull);
      expect(server.row('deck', 'R')?.serverVersion, 1);

      // The push alone: the ack must carry the version the server row
      // holds, before any pull could paper over a wrong one.
      await a.coordinator.pushAll();

      expect(await a.outbox(), isEmpty);
      expect(server.row('deck', 'R')?.serverVersion, 1, reason: 'applied once');
      expect((await a.deck('R'))?.serverVersion, 1);
      expect(server.pushCalls, 2);
    });

    test('a delete whose response was lost is resent as the same delete and '
        'tombstones once', () async {
      await _root(a.db, 'R');
      await a.coordinator.runOnce();
      await a.db.customStatement("DELETE FROM deck WHERE id = 'R'");
      final before = (await a.outbox()).single;
      expect(before.op, 'delete');
      server.afterPushCommit = () async {
        server.afterPushCommit = null;
        throw const SocketException('response lost');
      };

      await expectLater(
        a.coordinator.runOnce(),
        throwsA(isA<SocketException>()),
      );

      expect((await a.outbox()).single.opId, before.opId);
      final tombstone = server.row('deck', 'R');
      expect(tombstone?.isDeleted, isTrue);

      await a.coordinator.pushAll();

      expect(await a.outbox(), isEmpty);
      expect(server.row('deck', 'R')?.serverVersion, tombstone?.serverVersion);
      expect(server.pushed.where((k) => k == 'deck/R').length, 3);
      expect(await a.deck('R'), isNull);
    });
  });

  group(
    'a refused row whose server copy this device cannot hold yet (DEV-183)',
    () {
      /// A and B share R and C; B moves C under its new deck X, which A has
      /// not pulled; A edits C offline and the server refuses the edit with
      /// C's copy under X.
      Future<void> moveAwayOnB() async {
        await _root(a.db, 'R');
        await _child(a.db, 'C', 'R');
        await a.coordinator.runOnce();
        await b.coordinator.runOnce();
        await _child(b.db, 'X', 'R');
        await b.db.customStatement(
          "UPDATE deck SET parent_id = 'X', depth = 3, name = 'server copy' WHERE id = 'C'",
        );
        await b.coordinator.runOnce();
        await a.db.customStatement(
          "UPDATE deck SET name = 'edited' WHERE id = 'C'",
        );
        server.rejectNext['deck/C'] = 'DECK_TREE_TOO_DEEP';
      }

      test('the run no longer stalls: the pull brings the parent and the copy, '
          'and nothing is left pending or refused', () async {
        await moveAwayOnB();

        await a.coordinator.runOnce();

        expect(await a.deck('X'), isNotNull);
        final c = await a.deck('C');
        expect(c?.parentId, 'X');
        expect(c?.name, 'server copy');
        expect(await a.outbox(), isEmpty);
        expect(await a.rejections(), isEmpty);
        expect(await a.since(), greaterThan(0));
      });

      test(
        'the copy that cannot be applied fails only its own entity: the other '
        'results of the batch land, and it is listed until a pull resolves it',
        () async {
          await moveAwayOnB();
          await a.db.customStatement(
            "UPDATE deck SET name = 'renamed' WHERE id = 'R'",
          );
          server.failChangesAfter = 0;

          await expectLater(a.coordinator.runOnce(), throwsStateError);

          expect(
            (await a.deck('R'))?.serverVersion,
            isNotNull,
            reason: 'R acked',
          );
          expect(await a.outbox(), isEmpty);
          expect(
            (await a.deck('C'))?.name,
            'edited',
            reason: 'C kept as it is',
          );
          final rejection = (await a.rejections()).single;
          expect((rejection.entityType, rejection.entityId), ('deck', 'C'));
          expect(rejection.code, SyncCoordinator.localApplyFailed);

          server.failChangesAfter = null;
          await a.coordinator.runOnce();

          expect((await a.deck('C'))?.parentId, 'X');
          expect(await a.rejections(), isEmpty);
        },
      );
    },
  );
}
