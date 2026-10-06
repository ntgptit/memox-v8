import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/datasources/account_settings_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/card_schedule_sync_dao.dart';
import 'package:memox/features/card/data/datasources/card_sync_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_sync_dao.dart';
import 'package:memox/features/trash/data/datasources/delete_batch_sync_dao.dart';
import 'package:memox/features/srs/data/datasources/review_log_sync_dao.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/tags/data/datasources/tag_sync_dao.dart';

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
      final cards = CardSyncDao(db);
      return SyncCoordinator(
        api: server,
        store: SyncStore(db),
        adapters: [
          DeleteBatchSyncDao(db),
          DeckSyncDao(db),
          TagSyncDao(db, SyncStore(db)),
          cards,
          CardScheduleSyncDao(db, SyncStore(db)),
          ReviewLogSyncDao(db),
          AccountSettingsSyncDao(db),
        ],
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

  // DEV-206: the first pull of an account with years of data (50 000 cards,
  // their schedules and 200 000 review logs seeded on the server). The pull
  // applies one page at a time inside one transaction; the time and the
  // process RSS are printed for the ledger. Minutes long, so opt in with
  // MEMOX_BULK=1.
  const bulkCards = 50000;
  const bulkLogs = 200000;
  final bulkOptIn = Platform.environment['MEMOX_BULK'] == '1';

  test(
    '$bulkCards cards with schedules and $bulkLogs review logs pull from '
    'since 0 one page at a time (DEV-206)',
    () async {
      final server = FakeSyncServer();
      final b = openTestDatabase();
      addTearDown(b.close);
      server.seed('deck', 'R', {
        'id': 'R',
        'name': 'r',
        'parentId': null,
        'rootId': 'R',
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
      });
      for (var i = 0; i < bulkCards; i++) {
        server.seed('card', 'K$i', {
          'id': 'K$i',
          'deckId': 'R',
          'front': 'front $i',
          'back': 'b',
          'isFlagged': false,
          'example': null,
          'hint': null,
          'pronunciation': null,
          'deleteBatchId': null,
          'createdAt': '2026-09-28T00:00:00Z',
          'updatedAt': '2026-09-28T00:00:00Z',
        });
      }
      for (var i = 0; i < bulkCards; i++) {
        server.seed('card_schedule', 'K$i', {
          'cardId': 'K$i',
          'schedulerType': 'sm2',
          'schedulerVersion': 1,
          'generation': 1,
          'learnedAt': '2026-09-28T00:00:00Z',
          'dueAt': '2026-10-01T00:00:00Z',
          'lastAnsweredAt': '2026-09-28T00:00:00Z',
          'answerCount': 4,
          'lapseCount': 0,
          'currentBox': null,
          'easeFactor': 2.5,
          'intervalDays': 3,
          'repetitions': 2,
        });
      }
      for (var j = 0; j < bulkLogs; j++) {
        server.seed('review_log', 'L$j', {
          'id': 'L$j',
          'cardId': 'K${j % bulkCards}',
          'sessionId': 'S${j ~/ 200}',
          'schedulerType': 'sm2',
          'generation': 1,
          'kind': 'scheduled',
          'mode': 'self_assess',
          'outcomeReason': null,
          'comparisonVersion': null,
          'usedHint': null,
          'direction': null,
          'action': 'good',
          'answeredAt': '2026-09-28T00:00:00Z',
          'nextDueAt': '2026-10-01T00:00:00Z',
          'previousBox': null,
          'nextBox': null,
          'previousEaseFactor': 2.5,
          'nextEaseFactor': 2.6,
          'previousIntervalDays': 1,
          'nextIntervalDays': 3,
        });
      }
      final coordinator = SyncCoordinator(
        api: server,
        store: SyncStore(b),
        adapters: [
          DeleteBatchSyncDao(b),
          DeckSyncDao(b),
          TagSyncDao(b, SyncStore(b)),
          CardSyncDao(b),
          CardScheduleSyncDao(b, SyncStore(b)),
          ReviewLogSyncDao(b),
          AccountSettingsSyncDao(b),
        ],
      );
      final rssBefore = ProcessInfo.currentRss;

      final pull = Stopwatch()..start();
      await coordinator.runOnce();
      pull.stop();

      expect(await b.select(b.card).get(), hasLength(bulkCards));
      expect(await b.select(b.cardSchedule).get(), hasLength(bulkCards));
      expect(
        (await b
                .customSelect('SELECT COUNT(*) AS n FROM review_log')
                .getSingle())
            .read<int>('n'),
        bulkLogs,
      );
      expect(await SyncStore(b).since(), 1 + 2 * bulkCards + bulkLogs);
      // ignore: avoid_print
      print(
        'DEV-206 bulk: pull ${pull.elapsedMilliseconds} ms for '
        '${1 + 2 * bulkCards + bulkLogs} changes; RSS before pull '
        '${rssBefore ~/ (1024 * 1024)} MB, after '
        '${ProcessInfo.currentRss ~/ (1024 * 1024)} MB, peak '
        '${ProcessInfo.maxRss ~/ (1024 * 1024)} MB (the fake server holds '
        'the data set)',
      );
    },
    skip: bulkOptIn ? false : 'minutes long: opt in with MEMOX_BULK=1',
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
