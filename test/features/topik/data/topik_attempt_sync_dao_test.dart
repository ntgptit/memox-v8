import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/features/topik/data/datasources/topik_attempt_sync_dao.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_attempt_store.dart';

// TOPIK spec §13.2: the adapter reads a submitted attempt with its answers,
// writes a pulled one once, deletes a tombstoned one and records versions.

Future<String> _submitted(TopikAttemptRepositoryImpl repository) async {
  final attempt = topikOk(
    await repository.start(topikListeningTest, now: topikT0),
  );
  topikOk(
    await repository.answer(
      attemptId: attempt.id,
      questionNo: 1,
      selectedIdx: 1,
      elapsedMs: 1500,
      now: topikT0.add(const Duration(seconds: 2)),
    ),
  );
  topikOk(
    await repository.submit(
      attemptId: attempt.id,
      test: topikListeningTest,
      elapsedMs: 0,
      now: topikT0.add(const Duration(seconds: 9)),
    ),
  );
  return attempt.id;
}

void main() {
  late AppDatabase db;
  late TopikAttemptSyncDao dao;
  late TopikAttemptRepositoryImpl repository;
  setUp(() {
    (:db, :repository) = openTopikAttemptStore();
    dao = TopikAttemptSyncDao(db);
  });
  tearDown(() => db.close());

  test('reads a submitted attempt with its answers in wire shape', () async {
    final id = await _submitted(repository);

    final row = (await dao.readRow(id))!;

    expect(row['id'], id);
    expect(row['testId'], topikListeningTest.testId);
    expect(row['status'], 'completed');
    expect(row['score'], 4);
    expect(row['startedAt'], '2026-10-15T09:00:00Z');
    expect(row['completedAt'], '2026-10-15T09:00:09Z');
    final answers = (row['answers']! as List).cast<Map<String, Object?>>();
    expect(answers, hasLength(30));
    expect(answers.first, {
      'questionNo': 1,
      'selectedIdx': 1,
      'timeSpentMs': 1500,
      'answeredAt': '2026-10-15T09:00:02Z',
      'correctIdx': 1,
      'points': 4,
      'pointsEarned': 4,
      'questionType': 'L1_answer_question',
    });
  });

  test('an attempt in progress or gone reads as null', () async {
    final open = topikOk(await repository.start(topikListeningTest));
    expect(await dao.readRow(open.id), isNull);
    expect(await dao.readRow('gone'), isNull);
  });

  test('a pulled attempt lands once, with its answers and version, and '
      'queues nothing', () async {
    final id = await _submitted(repository);
    final row = (await dao.readRow(id))!;
    final other = openTestDatabase();
    addTearDown(other.close);
    final pulled = TopikAttemptSyncDao(other);

    await SyncStore(other).applyingRemote(() async {
      await pulled.upsertFromServer(row, 7);
      await pulled.upsertFromServer(row, 9);
    });

    final stored = (await topikAttemptRow(other, id))!;
    expect(stored.status, 'completed');
    expect(stored.serverVersion, 9);
    expect(await topikAnswerRows(other, id), hasLength(30));
    expect(await other.select(other.syncOutbox).get(), isEmpty);
    expect(await pulled.readRow(id), row);
  });

  test('a pulled copy of its own attempt only records the version', () async {
    final id = await _submitted(repository);
    final row = (await dao.readRow(id))!;

    await SyncStore(db).applyingRemote(() => dao.upsertFromServer(row, 11));

    expect((await topikAttemptRow(db, id))!.serverVersion, 11);
    expect(await topikAnswerRows(db, id), hasLength(30));
  });

  test('a pulled attempt with a code this build does not know is skipped '
      '(plan 2 R4)', () async {
    final id = await _submitted(repository);
    final row = {...(await dao.readRow(id))!, 'mode': 'exam'};
    final other = openTestDatabase();
    addTearDown(other.close);

    await SyncStore(
      other,
    ).applyingRemote(() => TopikAttemptSyncDao(other).upsertFromServer(row, 7));

    expect(await topikAttemptRow(other, id), isNull);
  });

  test('a tombstone deletes the attempt and its answers; an unknown id is a '
      'no-op', () async {
    final id = await _submitted(repository);
    await db.customStatement('DELETE FROM sync_outbox');

    await SyncStore(db).applyingRemote(() async {
      await dao.deleteFromServer(id);
      await dao.deleteFromServer('gone');
    });

    expect(await topikAttemptRow(db, id), isNull);
    expect(await topikAnswerRows(db, id), isEmpty);
    expect(await db.select(db.syncOutbox).get(), isEmpty);
  });

  test('an acknowledgement records the version only', () async {
    final id = await _submitted(repository);

    await dao.markAcknowledged(id, 5);

    final stored = (await topikAttemptRow(db, id))!;
    expect(stored.serverVersion, 5);
    expect(stored.score, 4);
  });
}
