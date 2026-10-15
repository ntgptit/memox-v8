import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_content_fixtures.dart';

// TOPIK spec §5.1–§5.4, §13.5. Fixture: TOPIK I listening, questions 1–30,
// 1–10 worth 4 and 11–30 worth 3; the answer of question n is (n - 1) % 4 + 1.
final _test = topikTestFixture(
  level: TopikLevel.topik1,
  section: TopikSection.listening,
);
final _t0 = DateTime.utc(2026, 10, 15, 9);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

T _ok<T>(Outcome<T, TopikRejection> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('rejected: $reason'),
};

TopikRejection _reason(Outcome<Object?, TopikRejection> outcome) =>
    switch (outcome) {
      Ok() => fail('expected a rejection'),
      Rejected(:final reason) => reason,
    };

Future<List<TopikAttemptAnswerRow>> _answers(AppDatabase db, String id) =>
    (db.select(db.topikAttemptAnswer)
          ..where((a) => a.attemptId.equals(id))
          ..orderBy([(a) => OrderingTerm(expression: a.questionNo)]))
        .get();

Future<TopikAttemptRow?> _row(AppDatabase db, String id) => (db.select(
  db.topikAttempt,
)..where((a) => a.id.equals(id))).getSingleOrNull();

void main() {
  late AppDatabase db;
  late TopikAttemptRepositoryImpl repository;
  setUp(() {
    db = openTestDatabase();
    repository = TopikAttemptRepositoryImpl(db, now: () => _t0);
  });
  tearDown(() => db.close());

  group('start', () {
    test('creates an attempt in progress with one blank answer per question '
        '(BR-TOPIK-010)', () async {
      final attempt = _ok(await repository.start(_test, now: _t0));

      expect(attempt.status, TopikAttemptStatus.inProgress);
      expect(attempt.testId, _test.testId);
      expect(attempt.level, TopikLevel.topik1);
      expect(attempt.section, TopikSection.listening);
      expect(attempt.round, 96);
      expect(attempt.mode, TopikAttemptMode.practice);
      expect(attempt.currentQuestionNo, 1);
      expect(attempt.questionCount, 30);
      expect(attempt.maxScore, 100);
      expect(attempt.totalTimeMs, 0);
      expect(attempt.score, isNull);
      expect(attempt.contentVersion, 1);
      expect(attempt.startedAt.isAtSameMomentAs(_t0), isTrue);
      final answers = await _answers(db, attempt.id);
      expect(answers.map((a) => a.questionNo), [
        for (var n = 1; n <= 30; n++) n,
      ]);
      expect(answers.every((a) => a.selectedIdx == null), isTrue);
      expect(answers.every((a) => a.timeSpentMs == 0), isTrue);
    });

    test('refuses a second attempt in progress of the same test '
        '(BR-TOPIK-011)', () async {
      _ok(await repository.start(_test));
      expect(
        _reason(await repository.start(_test)),
        TopikRejection.inProgressExists,
      );
      expect(await db.select(db.topikAttempt).get(), hasLength(1));
    });

    test('Start new replaces the attempt in progress in one transaction '
        '(BR-TOPIK-011)', () async {
      final old = _ok(await repository.start(_test));
      _ok(
        await repository.answer(
          attemptId: old.id,
          questionNo: 1,
          selectedIdx: 2,
          elapsedMs: 0,
        ),
      );

      final fresh = await repository.replaceInProgressAndStart(_test);

      expect(fresh.id, isNot(old.id));
      expect(await _row(db, old.id), isNull);
      expect(await _answers(db, old.id), isEmpty);
      expect(await _answers(db, fresh.id), hasLength(30));
    });

    test('Start new keeps the completed attempts', () async {
      final done = _ok(await repository.start(_test));
      _ok(
        await repository.submit(attemptId: done.id, test: _test, elapsedMs: 0),
      );

      await repository.replaceInProgressAndStart(_test);

      expect(await db.select(db.topikAttempt).get(), hasLength(2));
    });
  });

  group('answer', () {
    test('saves the choice, replacing the old one, and its time '
        '(BR-TOPIK-012)', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 2,
          elapsedMs: 4000,
          now: _at(4),
        ),
      );
      _ok(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 4,
          elapsedMs: 1000,
          now: _at(5),
        ),
      );

      final first = (await _answers(db, attempt.id)).first;
      expect(first.selectedIdx, 4);
      expect(first.answeredAt!.isAtSameMomentAs(_at(5)), isTrue);
      expect(first.timeSpentMs, 5000);
      final row = (await _row(db, attempt.id))!;
      expect(row.totalTimeMs, 5000);
      expect(row.updatedAt.isAtSameMomentAs(_at(5)), isTrue);
    });

    test('refuses an option outside 1–4, an unknown question, a submitted '
        'or a deleted attempt, and writes nothing', () async {
      final attempt = _ok(await repository.start(_test));
      expect(
        _reason(
          await repository.answer(
            attemptId: attempt.id,
            questionNo: 1,
            selectedIdx: 5,
            elapsedMs: 10,
          ),
        ),
        TopikRejection.invalidOption,
      );
      expect(
        _reason(
          await repository.answer(
            attemptId: attempt.id,
            questionNo: 31,
            selectedIdx: 1,
            elapsedMs: 10,
          ),
        ),
        TopikRejection.unknownQuestion,
      );
      expect((await _row(db, attempt.id))!.totalTimeMs, 0);

      _ok(
        await repository.submit(
          attemptId: attempt.id,
          test: _test,
          elapsedMs: 0,
        ),
      );
      expect(
        _reason(
          await repository.answer(
            attemptId: attempt.id,
            questionNo: 1,
            selectedIdx: 1,
            elapsedMs: 0,
          ),
        ),
        TopikRejection.attemptCompleted,
      );

      expect(
        _reason(
          await repository.answer(
            attemptId: 'gone',
            questionNo: 1,
            selectedIdx: 1,
            elapsedMs: 0,
          ),
        ),
        TopikRejection.notFound,
      );
    });

    test('negative elapsed time is a programming error', () async {
      final attempt = _ok(await repository.start(_test));
      await expectLater(
        repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 1,
          elapsedMs: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  group('time (BR-TOPIK-015)', () {
    test('accrues to the question that was current, and adds up on return', () async {
      final attempt = _ok(await repository.start(_test));
      // 40 s on question 5 (reached by a move), 20 s on 6, back to 5 for 10 s.
      _ok(
        await repository.move(
          attemptId: attempt.id,
          toQuestionNo: 5,
          elapsedMs: 0,
        ),
      );
      _ok(
        await repository.move(
          attemptId: attempt.id,
          toQuestionNo: 6,
          elapsedMs: 40000,
        ),
      );
      _ok(
        await repository.move(
          attemptId: attempt.id,
          toQuestionNo: 5,
          elapsedMs: 20000,
        ),
      );
      _ok(await repository.recordTime(attemptId: attempt.id, elapsedMs: 10000));

      final answers = {
        for (final a in await _answers(db, attempt.id)) a.questionNo: a,
      };
      expect(answers[5]!.timeSpentMs, 50000);
      expect(answers[6]!.timeSpentMs, 20000);
      final row = (await _row(db, attempt.id))!;
      expect(row.totalTimeMs, 70000);
      expect(row.currentQuestionNo, 5);
    });

    test('move refuses an unknown question and writes nothing', () async {
      final attempt = _ok(await repository.start(_test));
      expect(
        _reason(
          await repository.move(
            attemptId: attempt.id,
            toQuestionNo: 99,
            elapsedMs: 500,
          ),
        ),
        TopikRejection.unknownQuestion,
      );
      expect((await _row(db, attempt.id))!.totalTimeMs, 0);
    });
  });

  group('submit (BR-TOPIK-013)', () {
    test('scores against the content and snapshots every answer', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 1,
          elapsedMs: 1000,
        ),
      );
      _ok(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 2,
          selectedIdx: 1,
          elapsedMs: 1000,
        ),
      );
      _ok(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 11,
          selectedIdx: 3,
          elapsedMs: 1000,
        ),
      );

      final done = _ok(
        await repository.submit(
          attemptId: attempt.id,
          test: _test,
          elapsedMs: 2000,
          now: _at(60),
        ),
      );

      expect(done.status, TopikAttemptStatus.completed);
      expect(done.score, 7);
      expect(done.maxScore, 100);
      expect(done.correctCount, 2);
      expect(done.answeredCount, 3);
      expect(done.questionCount, 30);
      expect(done.totalTimeMs, 5000);
      expect(done.completedAt!.isAtSameMomentAs(_at(60)), isTrue);
      final answers = {
        for (final a in await _answers(db, attempt.id)) a.questionNo: a,
      };
      expect(answers[1]!.pointsEarned, 4);
      expect(answers[2]!.pointsEarned, 0);
      expect(answers[2]!.correctIdx, 2);
      expect(answers[3]!.pointsEarned, 0);
      expect(answers[3]!.points, 4);
      expect(answers[11]!.questionType, 'L1_topic');
      // 1 s each on questions 1, 1 and 2 before each choice moved on, then
      // the 2 s before submit on question 11.
      expect(answers[1]!.timeSpentMs, 2000);
      expect(answers[2]!.timeSpentMs, 1000);
      expect(answers[11]!.timeSpentMs, 2000);
    });

    test('queues the attempt for sync in the same transaction '
        '(BR-TOPIK-026)', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(
        await repository.submit(
          attemptId: attempt.id,
          test: _test,
          elapsedMs: 0,
        ),
      );
      final queued = await db
          .customSelect(
            "SELECT entity_id, op FROM sync_outbox WHERE entity_type = 'topik_attempt'",
          )
          .get();
      expect(queued.single.read<String>('entity_id'), attempt.id);
      expect(queued.single.read<String>('op'), 'upsert');
    });

    test(
      'a second submit is refused and changes nothing (BR-TOPIK-014)',
      () async {
        final attempt = _ok(await repository.start(_test));
        _ok(
          await repository.submit(
            attemptId: attempt.id,
            test: _test,
            elapsedMs: 0,
            now: _at(10),
          ),
        );
        expect(
          _reason(
            await repository.submit(
              attemptId: attempt.id,
              test: _test,
              elapsedMs: 900,
              now: _at(20),
            ),
          ),
          TopikRejection.attemptCompleted,
        );
        final row = (await _row(db, attempt.id))!;
        expect(row.completedAt!.isAtSameMomentAs(_at(10)), isTrue);
        expect(row.totalTimeMs, 0);
      },
    );

    test('refuses content that is not the attempt\'s test and writes nothing '
        '(BR-TOPIK-019)', () async {
      final attempt = _ok(await repository.start(_test));
      final other = topikTestFixture(level: TopikLevel.topik1);
      expect(
        _reason(
          await repository.submit(
            attemptId: attempt.id,
            test: other,
            elapsedMs: 100,
          ),
        ),
        TopikRejection.contentMismatch,
      );
      final row = (await _row(db, attempt.id))!;
      expect(row.status, 'in_progress');
      expect(row.totalTimeMs, 0);
    });

    test(
      'a content correction made before submit is the one that scores',
      () async {
        final attempt = _ok(await repository.start(_test));
        _ok(
          await repository.answer(
            attemptId: attempt.id,
            questionNo: 1,
            selectedIdx: 2,
            elapsedMs: 0,
          ),
        );
        final json = topikTestJson(
          level: TopikLevel.topik1,
          section: TopikSection.listening,
        );
        questionJson(json, 1)['answerIdx'] = 2;
        json['contentVersion'] = 2;
        final corrected = topikTestOfFixtureJson(json);

        final done = _ok(
          await repository.submit(
            attemptId: attempt.id,
            test: corrected,
            elapsedMs: 0,
          ),
        );

        expect(done.score, 4);
        expect(done.contentVersion, 2);
      },
    );
  });

  group('delete (BR-TOPIK-018)', () {
    test('removes the attempt and its answers', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.delete(attempt.id));
      expect(await _row(db, attempt.id), isNull);
      expect(await _answers(db, attempt.id), isEmpty);
      expect(
        _reason(await repository.delete(attempt.id)),
        TopikRejection.notFound,
      );
    });

    test('every write to an attempt that is gone is notFound and writes '
        'nothing (BR-TOPIK-018, BR-TOPIK-027)', () async {
      expect(
        _reason(
          await repository.move(
            attemptId: 'gone',
            toQuestionNo: 1,
            elapsedMs: 0,
          ),
        ),
        TopikRejection.notFound,
      );
      expect(
        _reason(await repository.recordTime(attemptId: 'gone', elapsedMs: 0)),
        TopikRejection.notFound,
      );
      expect(
        _reason(
          await repository.submit(attemptId: 'gone', test: _test, elapsedMs: 0),
        ),
        TopikRejection.notFound,
      );
      expect(await db.select(db.topikAttempt).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });
  });
}
