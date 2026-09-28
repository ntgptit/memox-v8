import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/sync/card_schedule_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

Map<String, Object?> _review(String id, String cardId) => {
  'id': id,
  'cardId': cardId,
  'sessionId': 's1',
  'schedulerType': 'sm2',
  'generation': 1,
  'kind': 'scheduled',
  'mode': 'fill',
  'outcomeReason': null,
  'comparisonVersion': 2,
  'usedHint': 1,
  'direction': 'korean_to_meaning',
  'action': 'good',
  'answeredAt': '2026-09-28T10:00:00Z',
  'nextDueAt': '2026-10-04T00:00:00Z',
  'previousBox': null,
  'nextBox': null,
  'previousEaseFactor': 2.5,
  'nextEaseFactor': 2.6,
  'previousIntervalDays': 1,
  'nextIntervalDays': 6,
};

Map<String, Object?> _eightBox({
  int generation = 1,
  String? answered = '2026-09-28T10:00:00Z',
  int answers = 3,
}) => {
  'cardId': 'K',
  'schedulerType': 'eight_box',
  'schedulerVersion': 1,
  'generation': generation,
  'learnedAt': '2026-09-27T00:00:00Z',
  'dueAt': '2026-09-30T00:00:00Z',
  'lastAnsweredAt': answered,
  'answerCount': answers,
  'lapseCount': 0,
  'currentBox': 2,
  'easeFactor': null,
  'intervalDays': null,
  'repetitions': null,
};

final Map<String, Object?> _sm2 = {
  'cardId': 'K',
  'schedulerType': 'sm2',
  'schedulerVersion': 1,
  'generation': 1,
  'learnedAt': '2026-09-27T00:00:00Z',
  'dueAt': '2026-10-04T00:00:00Z',
  'lastAnsweredAt': '2026-09-28T10:00:00Z',
  'answerCount': 2,
  'lapseCount': 1,
  'currentBox': null,
  'easeFactor': 2.36,
  'intervalDays': 6,
  'repetitions': 2,
};

void main() {
  late AppDatabase db;
  late SyncStore store;
  late ReviewLogSyncAdapter reviews;
  late CardScheduleSyncAdapter schedules;
  setUp(() async {
    db = openTestDatabase();
    store = SyncStore(db);
    reviews = ReviewLogSyncAdapter(db);
    schedules = CardScheduleSyncAdapter(
      db,
      store,
      now: () => DateTime.utc(2026, 9, 28, 12),
    );
    await db.customStatement(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, "
      "scheduler_version, generation, sibling_position, created_at, updated_at) "
      "VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    );
    await db.customStatement(
      "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) "
      "VALUES ('K', 'R', 'f', 'b', 0, 0)",
    );
    await db.customStatement('DELETE FROM sync_outbox');
  });
  tearDown(() => db.close());

  Future<void> remote(Future<void> Function() body) =>
      store.applyingRemote(deferForeignKeys: true, body);

  Future<List<String>> queued() async => [
    for (final e in await db.select(db.syncOutbox).get())
      '${e.entityType}/${e.entityId}',
  ];

  test('a review round-trips, and a second copy changes nothing', () async {
    await remote(() => reviews.upsertFromServer(_review('V', 'K'), 3));
    await remote(() => reviews.upsertFromServer(_review('V', 'K'), 4));

    expect(await reviews.readRow('V'), _review('V', 'K'));
    expect(await db.select(db.reviewLog).get(), hasLength(1));
    expect(await queued(), isEmpty);
  });

  test('a schedule round-trips, for either scheduler', () async {
    for (final row in [_eightBox(), _sm2]) {
      await db.customStatement('DELETE FROM card_schedule');
      await remote(() => schedules.upsertFromServer({...row}, 5));
      expect(await schedules.readRow('K'), row);
    }
  });

  test('an older pulled schedule leaves the local one and queues it', () async {
    await remote(
      () => schedules.upsertFromServer(
        _eightBox(answered: '2026-09-28T11:00:00Z'),
        1,
      ),
    );
    await remote(() => schedules.upsertFromServer(_eightBox(), 2));

    expect(
      (await schedules.readRow('K'))!['lastAnsweredAt'],
      '2026-09-28T11:00:00Z',
    );
    expect(await queued(), ['card_schedule/K']);
  });

  test('a later pulled schedule replaces the local one', () async {
    await remote(() => schedules.upsertFromServer(_eightBox(), 1));
    await remote(
      () => schedules.upsertFromServer(
        _eightBox(answered: '2026-09-28T11:00:00Z'),
        2,
      ),
    );

    expect(
      (await schedules.readRow('K'))!['lastAnsweredAt'],
      '2026-09-28T11:00:00Z',
    );
    expect(await queued(), isEmpty);
  });

  test('a higher generation replaces a schedule with more answers', () async {
    await remote(() => schedules.upsertFromServer(_eightBox(answers: 9), 1));
    await remote(
      () => schedules.upsertFromServer(
        _eightBox(generation: 2, answered: null, answers: 0),
        2,
      ),
    );

    expect((await schedules.readRow('K'))!['generation'], 2);
    expect(await queued(), isEmpty);
  });
}
