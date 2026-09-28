import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

class _Device {
  _Device(FakeSyncServer server, {int pullLimit = SyncCoordinator.pullPageSize})
    : db = openTestDatabase() {
    final cards = CardSyncAdapter(db);
    coordinator = SyncCoordinator(
      api: server,
      store: SyncStore(db),
      adapters: [
        DeleteBatchSyncAdapter(db),
        DeckSyncAdapter(db),
        TagSyncAdapter(db, SyncStore(db)),
        cards,
        AccountSettingsSyncAdapter(db),
      ],
      pullLimit: pullLimit,
      afterPull: cards.ensureSchedules,
    );
  }
  final AppDatabase db;
  late final SyncCoordinator coordinator;
}

Future<void> _root(AppDatabase db, String id) => db.customStatement(
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
  "scheduler_version, generation, sibling_position, created_at, updated_at) "
  "VALUES (?, 'r', NULL, ?, 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
  [id, id],
);

Future<void> _child(AppDatabase db, String id, String parent) =>
    db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "sibling_position, created_at, updated_at) VALUES (?, 'c', ?, ?, 2, 'card', 0, 0, 0)",
      [id, parent, parent],
    );

Future<void> _card(
  AppDatabase db,
  String id,
  String deck, {
  String front = 'f',
}) => db.customStatement(
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
  "VALUES (?, ?, ?, 'b', 0, 0)",
  [id, deck, front],
);

Future<String?> _front(AppDatabase db, String id) async => (await (db.select(
  db.card,
)..where((c) => c.id.equals(id))).getSingleOrNull())?.front;

void main() {
  late FakeSyncServer server;
  late _Device a;
  late _Device b;
  setUp(() {
    server = FakeSyncServer();
    a = _Device(server);
    b = _Device(server, pullLimit: 2);
  });
  tearDown(() async {
    await a.db.close();
    await b.db.close();
  });

  test('a card and its edit reach the other device', () async {
    await _root(a.db, 'R');
    await _child(a.db, 'D', 'R');
    await _card(a.db, 'K', 'D', front: 'one');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    expect(await _front(b.db, 'K'), 'one');

    await b.db.customStatement("UPDATE card SET front = 'two' WHERE id = 'K'");
    await b.coordinator.runOnce();
    await a.coordinator.runOnce();
    expect(await _front(a.db, 'K'), 'two');
  });

  test(
    'a deck edited after its cards lands pages later and the pull commits',
    () async {
      await _root(a.db, 'R');
      await _child(a.db, 'D', 'R');
      for (var i = 0; i < 5; i++) {
        await _card(a.db, 'K$i', 'D');
      }
      await a.coordinator.runOnce();
      await a.db.customStatement(
        "UPDATE deck SET name = 'renamed' WHERE id = 'D'",
      );
      await a.coordinator.runOnce();

      await b.coordinator.runOnce(); // pages of 2: the cards come before D

      expect(await b.db.select(b.db.card).get(), hasLength(5));
      expect(await b.db.select(b.db.cardSchedule).get(), hasLength(5));
    },
  );

  test('deleting a deck removes its cards on the other device', () async {
    await _root(a.db, 'R');
    await _child(a.db, 'D', 'R');
    await _card(a.db, 'K', 'D');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    await a.db.customStatement("DELETE FROM deck WHERE id = 'D'");
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();

    expect(await _front(b.db, 'K'), isNull);
    expect(await b.db.select(b.db.syncOutbox).get(), isEmpty);
  });

  test('an offline edit refused with a tombstone deletes the card', () async {
    await _root(a.db, 'R');
    await _card(a.db, 'K', 'R');
    await a.coordinator.runOnce();
    await b.coordinator.runOnce();
    server.seed('card', 'K', null); // the server tombstoned it meanwhile
    await b.db.customStatement(
      "UPDATE card SET front = 'offline' WHERE id = 'K'",
    );
    server.rejectNext['card/K'] = 'CARD_DECK_MISSING';

    await b.coordinator.runOnce();

    expect(await _front(b.db, 'K'), isNull);
    expect(await b.db.select(b.db.syncRejection).get(), isEmpty);
  });

  test(
    'trash, restore and purge of a card travel as upserts and a delete',
    () async {
      await _root(a.db, 'R');
      await _card(a.db, 'K', 'R');
      await a.coordinator.runOnce();
      await b.coordinator.runOnce();

      await a.db.customStatement(
        "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('B', 'card', 'K', 0)",
      );
      await a.db.customStatement(
        "UPDATE card SET delete_batch_id = 'B' WHERE id = 'K'",
      );
      await a.coordinator.runOnce();
      await b.coordinator.runOnce();
      final trashed = await (b.db.select(
        b.db.card,
      )..where((c) => c.id.equals('K'))).getSingle();
      expect(trashed.deleteBatchId, 'B');

      await a.db.customStatement(
        "UPDATE card SET delete_batch_id = NULL WHERE id = 'K'",
      );
      await a.coordinator.runOnce();
      await b.coordinator.runOnce();
      final restored = await (b.db.select(
        b.db.card,
      )..where((c) => c.id.equals('K'))).getSingle();
      expect(restored.deleteBatchId, isNull);

      await a.db.customStatement(
        "UPDATE card SET delete_batch_id = 'B' WHERE id = 'K'",
      );
      await a.db.customStatement("DELETE FROM delete_batches WHERE id = 'B'");
      await a.coordinator.runOnce();
      await b.coordinator.runOnce();
      expect(
        await _front(b.db, 'K'),
        isNull,
        reason: 'purge cascades to the card',
      );
    },
  );

  test(
    'a card moved into a deck made after its pending edit follows that deck',
    () async {
      await _root(a.db, 'R');
      await _card(a.db, 'K', 'R');
      await a.coordinator.runOnce();
      await a.db.customStatement(
        "UPDATE card SET front = 'edited' WHERE id = 'K'",
      );
      await _root(a.db, 'R2');
      await a.db.customStatement(
        "UPDATE card SET deck_id = 'R2' WHERE id = 'K'",
      );
      server.pushed.clear();

      await a.coordinator.runOnce();

      expect(server.pushed, ['deck/R2', 'card/K']);
    },
  );
}
