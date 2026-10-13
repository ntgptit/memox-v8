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

// DEV-181: a device that purges an expired Trash batch long after another
// device restored its rows must not tombstone them: the server refuses the
// purge with the live copy, and the stale device gets its rows back. A batch
// the server never saw (trashed and purged offline) still purges. DEV-184
// (policy A): a tombstone is final; an offline edit of a purged deck is
// refused with the tombstone and the deck goes.

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

  Future<bool> hasDeck(String id) async => (await (db.select(
    db.deck,
  )..where((d) => d.id.equals(id))).get()).isNotEmpty;

  Future<bool> hasCard(String id) async => (await (db.select(
    db.card,
  )..where((c) => c.id.equals(id))).get()).isNotEmpty;

  /// The library: root R, child D, card K in D.
  Future<void> library() async {
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES ('D', 'd', 'R', 'R', 2, 'card', 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('K', 'D', 'f', 'b', 0, 0)",
    );
  }

  /// D and K go to the Trash in batch B, as the Trash repository writes it.
  Future<void> trashD() async {
    await db.customStatement(
      "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) "
      "VALUES ('B', 'deck', 'D', 100)",
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'B' WHERE id = 'D'",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'B' WHERE id = 'K'",
    );
  }

  /// Batch B is restored: its rows leave it, then it goes.
  Future<void> restoreB() async {
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = NULL WHERE delete_batch_id = 'B'",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = NULL WHERE delete_batch_id = 'B'",
    );
    await db.customStatement("DELETE FROM delete_batches WHERE id = 'B'");
  }

  /// Batch B is purged: the keys delete its rows (BR-TRASH-010).
  Future<void> purgeB() =>
      db.customStatement("DELETE FROM delete_batches WHERE id = 'B'");
}

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  late _Device c;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server);
    c = _Device(server);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
    await c.db.close();
  });

  test('a stale purge of a batch another device restored brings the rows back '
      'and tombstones nothing', () async {
    await a.library();
    await a.trashD();
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    await b.restoreB();
    await b.coordinator.runOnce();

    // Device A, not opened for 30 days, purges before it syncs.
    await a.purgeB();
    expect(await a.hasDeck('D'), isFalse);
    await a.coordinator.runOnce();

    expect(server.row('deck', 'D')!.isDeleted, isFalse);
    expect(server.row('card', 'K')!.isDeleted, isFalse);
    expect(await a.hasDeck('D'), isTrue, reason: 'A gets D back');
    expect(await a.hasCard('K'), isTrue, reason: 'A gets K back');
    expect(await a.db.select(a.db.syncOutbox).get(), isEmpty);
    expect(await a.db.select(a.db.syncRejection).get(), isEmpty);

    await b.coordinator.runOnce();
    await c.coordinator.runOnce();
    expect(await b.hasDeck('D'), isTrue);
    expect(await b.hasCard('K'), isTrue);
    expect(await c.hasDeck('D'), isTrue);
    expect(await c.hasCard('K'), isTrue);
  });

  test('a batch the server never saw still purges its rows', () async {
    await a.library();
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    // Trashed and purged offline: the server never sees batch B.
    await a.trashD();
    await a.purgeB();
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    expect(server.row('deck', 'D')!.isDeleted, isTrue);
    expect(server.row('card', 'K')!.isDeleted, isTrue);
    expect(await a.hasDeck('D'), isFalse);
    expect(await b.hasDeck('D'), isFalse);
    expect(await b.hasCard('K'), isFalse);
  });

  test('a tombstone is final: an offline edit of a purged deck is refused and '
      'the deck goes (policy A)', () async {
    await a.library();
    await a.trashD();
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    // B restores D and edits it, offline.
    await b.restoreB();
    await b.db.customStatement("UPDATE deck SET name = 'kept' WHERE id = 'D'");
    // A purges B meanwhile and syncs.
    await a.purgeB();
    await a.coordinator.runOnce();
    expect(server.row('deck', 'D')!.isDeleted, isTrue);

    await b.coordinator.runOnce();

    expect(server.row('deck', 'D')!.isDeleted, isTrue);
    expect(await b.hasDeck('D'), isFalse);
    expect(await b.hasCard('K'), isFalse);
    expect(await b.db.select(b.db.syncOutbox).get(), isEmpty);
    expect(await b.db.select(b.db.syncRejection).get(), isEmpty);
  });
}
