import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_models.dart';
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

// The order the coordinator pushes the outbox in (app deck-sync spec §3, §5):
// one entity type per batch in adapter order, decks shallower first
// (DEV-182), and a push that goes on until nothing is pending (DEV-205).

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
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
      adapters: [
        DeleteBatchSyncDao(db),
        DeckSyncDao(db),
        TagSyncDao(db, SyncStore(db)),
        CardSyncDao(db),
        CardScheduleSyncDao(db, SyncStore(db)),
        ReviewLogSyncDao(db),
        AccountSettingsSyncDao(db),
      ],
    );
  }

  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

/// A server whose push response names none of the operations sent.
class _SilentServer extends FakeSyncServer {
  @override
  Future<PushResponseModel> push(PushRequestModel request) async =>
      const PushResponseModel(results: []);
}

void main() {
  late FakeSyncServer server;
  late _Device a;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
  });
  tearDown(() => a.db.close());

  test(
    'a pending deck moved into a deck made after its edit follows that deck, '
    'and the move survives the ack (DEV-182)',
    () async {
      await _root(a.db, 'R');
      await _child(a.db, 'C', 'R');
      await a.coordinator.runOnce();
      await a.db.customStatement(
        "UPDATE deck SET name = 'edited' WHERE id = 'C'",
      );
      await _root(a.db, 'N');
      await a.db.customStatement(
        "UPDATE deck SET parent_id = 'N', root_id = 'N' WHERE id = 'C'",
      );
      server.pushed.clear();

      await a.coordinator.runOnce();

      expect(server.pushed, ['deck/N', 'deck/C']);
      expect(server.row('deck', 'C')?.row?['parentId'], 'N');
      expect(await _name(a.db, 'C'), 'edited');
      expect(await SyncStore(a.db).pendingBatch(['deck'], 10), isEmpty);
    },
  );

  test('Try again pushes a refused parent before its refused child in the '
      'same run (DEV-182)', () async {
    await _root(a.db, 'N');
    await _child(a.db, 'C', 'N');
    server.rejectNext['deck/N'] = 'VALIDATION_FAILED';
    server.rejectNext['deck/C'] = 'VALIDATION_FAILED';
    await a.coordinator.runOnce();
    // C was refused first: its record, and so its requeue, come first.
    await SyncStore(a.db).recordRejection('deck', 'C', 'X', DateTime.utc(2026));
    server.pushed.clear();

    await a.coordinator.requeueRejected();
    await a.coordinator.runOnce();

    expect(server.pushed, ['deck/N', 'deck/C']);
    expect(await SyncStore(a.db).rejections(), isEmpty);
  });

  test('a push goes on past a type with fewer entries than a batch '
      '(DEV-205)', () async {
    await _root(a.db, 'R');
    await a.db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('K', 'R', 'f', 'b', 0, 0)",
    );

    await a.coordinator.runOnce();

    expect(server.pushed, ['deck/R', 'card/K']);
    expect(server.pushCalls, 2);
    expect(await SyncStore(a.db).pendingCount(), 0);
  });

  test('a batch the server answers nothing for ends the push', () async {
    final device = _Device(_SilentServer());
    addTearDown(device.db.close);
    await _root(device.db, 'R');

    await device.coordinator.pushAll();

    expect(await SyncStore(device.db).pendingCount(), 1);
  });
}
