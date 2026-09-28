import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

/// SB-S2 (3), SB-S3: a large tagged import drains through push batches of 100 and pull
/// pages of 500. Timings are printed for the plan ledger; only correctness is
/// asserted, so the test cannot flake on a slow machine.
void main() {
  const cardCount = 5000;

  test('$cardCount imported cards drain up and down', () async {
    final server = FakeSyncServer();
    final a = openTestDatabase();
    final b = openTestDatabase();
    addTearDown(a.close);
    addTearDown(b.close);
    SyncCoordinator coordinatorOf(AppDatabase db) {
      final cards = CardSyncAdapter(db);
      return SyncCoordinator(
        api: server,
        store: SyncStore(db),
        adapters: [
          DeleteBatchSyncAdapter(db),
          DeckSyncAdapter(db),
          TagSyncAdapter(db, SyncStore(db)),
          cards,
        ],
        afterPull: cards.ensureSchedules,
      );
    }

    await a.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'sm2', 1, 1, 0, 0, 0)",
    );
    await a.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('T', 'tag', 'tag', 0)",
    );
    await a.transaction(() async {
      for (var i = 0; i < cardCount; i++) {
        await a.customStatement(
          "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
          "VALUES (?, 'R', ?, 'b', 0, 0)",
          ['K$i', 'front $i'],
        );
        await a.customStatement(
          "INSERT INTO card_tags (card_id, tag_id) VALUES (?, 'T')",
          ['K$i'],
        );
      }
    });

    final push = Stopwatch()..start();
    await coordinatorOf(a).runOnce();
    push.stop();
    final pull = Stopwatch()..start();
    await coordinatorOf(b).runOnce();
    pull.stop();

    expect(await a.select(a.syncOutbox).get(), isEmpty);
    expect(
      server.pushCalls,
      (cardCount + 2) ~/ SyncCoordinator.pushBatchSize + 1,
    );
    expect(await b.select(b.card).get(), hasLength(cardCount));
    expect(await b.select(b.cardSchedule).get(), hasLength(cardCount));
    expect(await b.select(b.tags).get(), hasLength(1));
    expect(await b.select(b.cardTags).get(), hasLength(cardCount));
    // ignore: avoid_print
    print(
      'SB-S3 bulk (tagged): push ${push.elapsedMilliseconds} ms, '
      'pull ${pull.elapsedMilliseconds} ms for $cardCount tagged cards',
    );
  });
}
