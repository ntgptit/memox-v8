import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_attempt_store.dart';

// TOPIK spec §5.1, §5.2, §5.4, §13.5: start, answer and time. Fixture: TOPIK I listening, questions 1–30,
// 1–10 worth 4 and 11–30 worth 3; the answer of question n is (n - 1) % 4 + 1.

void main() {
  late AppDatabase db;
  late TopikAttemptRepositoryImpl repository;
  setUp(() {
    (:db, :repository) = openTopikAttemptStore();
  });
  tearDown(() => db.close());

  group('start', () {
    test('creates an attempt in progress with one blank answer per question '
        '(BR-TOPIK-010)', () async {
      final attempt = topikOk(
        await repository.start(topikListeningTest, now: topikT0),
      );

      expect(attempt.status, TopikAttemptStatus.inProgress);
      expect(attempt.testId, topikListeningTest.testId);
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
      expect(attempt.startedAt.isAtSameMomentAs(topikT0), isTrue);
      final answers = await topikAnswerRows(db, attempt.id);
      expect(answers.map((a) => a.questionNo), [
        for (var n = 1; n <= 30; n++) n,
      ]);
      expect(answers.every((a) => a.selectedIdx == null), isTrue);
      expect(answers.every((a) => a.timeSpentMs == 0), isTrue);
    });

    test('refuses a second attempt in progress of the same test '
        '(BR-TOPIK-011)', () async {
      topikOk(await repository.start(topikListeningTest));
      expect(
        topikReason(await repository.start(topikListeningTest)),
        TopikRejection.inProgressExists,
      );
      expect(await db.select(db.topikAttempt).get(), hasLength(1));
    });

    test('two Starts at once leave one attempt in progress; the other is '
        'refused (BR-TOPIK-011)', () async {
      final outcomes = await Future.wait([
        repository.start(topikListeningTest),
        repository.start(topikListeningTest),
      ]);
      final started = outcomes.whereType<Ok<TopikAttempt, TopikRejection>>();
      expect(started, hasLength(1));
      expect(
        outcomes.whereType<Rejected<TopikAttempt, TopikRejection>>().map(
          (outcome) => outcome.reason,
        ),
        [TopikRejection.inProgressExists],
      );
      final open = await db
          .customSelect(
            "SELECT id FROM topik_attempt WHERE status = 'in_progress'",
          )
          .get();
      expect(open.map((row) => row.read<String>('id')), [
        started.single.value.id,
      ]);
    });

    test('Start new replaces the attempt in progress in one transaction '
        '(BR-TOPIK-011)', () async {
      final old = topikOk(await repository.start(topikListeningTest));
      topikOk(
        await repository.answer(
          attemptId: old.id,
          questionNo: 1,
          selectedIdx: 2,
          elapsedMs: 0,
        ),
      );

      final fresh = await repository.replaceInProgressAndStart(
        topikListeningTest,
      );

      expect(fresh.id, isNot(old.id));
      expect(await topikAttemptRow(db, old.id), isNull);
      expect(await topikAnswerRows(db, old.id), isEmpty);
      expect(await topikAnswerRows(db, fresh.id), hasLength(30));
    });

    test('Start new keeps the completed attempts', () async {
      final done = topikOk(await repository.start(topikListeningTest));
      topikOk(
        await repository.submit(
          attemptId: done.id,
          test: topikListeningTest,
          elapsedMs: 0,
        ),
      );

      await repository.replaceInProgressAndStart(topikListeningTest);

      expect(await db.select(db.topikAttempt).get(), hasLength(2));
    });
  });

  group('answer', () {
    test('saves the choice, replacing the old one, and its time '
        '(BR-TOPIK-012)', () async {
      final attempt = topikOk(await repository.start(topikListeningTest));
      topikOk(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 2,
          elapsedMs: 4000,
          now: topikAt(4),
        ),
      );
      topikOk(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 4,
          elapsedMs: 1000,
          now: topikAt(5),
        ),
      );

      final first = (await topikAnswerRows(db, attempt.id)).first;
      expect(first.selectedIdx, 4);
      expect(first.answeredAt!.isAtSameMomentAs(topikAt(5)), isTrue);
      expect(first.timeSpentMs, 5000);
      final row = (await topikAttemptRow(db, attempt.id))!;
      expect(row.totalTimeMs, 5000);
      expect(row.updatedAt.isAtSameMomentAs(topikAt(5)), isTrue);
    });

    test('refuses an option outside 1–4, an unknown question, a submitted '
        'or a deleted attempt, and writes nothing', () async {
      final attempt = topikOk(await repository.start(topikListeningTest));
      expect(
        topikReason(
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
        topikReason(
          await repository.answer(
            attemptId: attempt.id,
            questionNo: 31,
            selectedIdx: 1,
            elapsedMs: 10,
          ),
        ),
        TopikRejection.unknownQuestion,
      );
      expect((await topikAttemptRow(db, attempt.id))!.totalTimeMs, 0);

      topikOk(
        await repository.submit(
          attemptId: attempt.id,
          test: topikListeningTest,
          elapsedMs: 0,
        ),
      );
      expect(
        topikReason(
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
        topikReason(
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
  });

  group('elapsed time', () {
    test('negative elapsed time is a programming error on every timed '
        'write, which then writes nothing', () async {
      final attempt = topikOk(await repository.start(topikListeningTest));
      final before = await totalChanges(db);
      final writes = <String, Future<Object?> Function()>{
        'answer': () => repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 1,
          elapsedMs: -1,
        ),
        'move': () => repository.move(
          attemptId: attempt.id,
          toQuestionNo: 2,
          elapsedMs: -1,
        ),
        'recordTime': () =>
            repository.recordTime(attemptId: attempt.id, elapsedMs: -1),
        'submit': () => repository.submit(
          attemptId: attempt.id,
          test: topikListeningTest,
          elapsedMs: -1,
        ),
      };
      for (final MapEntry(key: name, value: write) in writes.entries) {
        await expectLater(write(), throwsArgumentError, reason: name);
      }
      expect(await totalChanges(db), before);
    });
  });

  group('time (BR-TOPIK-015)', () {
    test('accrues to the question that was current, and adds up on return', () async {
      final attempt = topikOk(await repository.start(topikListeningTest));
      // 40 s on question 5 (reached by a move), 20 s on 6, back to 5 for 10 s.
      topikOk(
        await repository.move(
          attemptId: attempt.id,
          toQuestionNo: 5,
          elapsedMs: 0,
        ),
      );
      topikOk(
        await repository.move(
          attemptId: attempt.id,
          toQuestionNo: 6,
          elapsedMs: 40000,
        ),
      );
      topikOk(
        await repository.move(
          attemptId: attempt.id,
          toQuestionNo: 5,
          elapsedMs: 20000,
        ),
      );
      topikOk(
        await repository.recordTime(attemptId: attempt.id, elapsedMs: 10000),
      );

      final answers = {
        for (final a in await topikAnswerRows(db, attempt.id)) a.questionNo: a,
      };
      expect(answers[5]!.timeSpentMs, 50000);
      expect(answers[6]!.timeSpentMs, 20000);
      final row = (await topikAttemptRow(db, attempt.id))!;
      expect(row.totalTimeMs, 70000);
      expect(row.currentQuestionNo, 5);
    });

    test('move refuses an unknown question and writes nothing', () async {
      final attempt = topikOk(await repository.start(topikListeningTest));
      expect(
        topikReason(
          await repository.move(
            attemptId: attempt.id,
            toQuestionNo: 99,
            elapsedMs: 500,
          ),
        ),
        TopikRejection.unknownQuestion,
      );
      expect((await topikAttemptRow(db, attempt.id))!.totalTimeMs, 0);
    });
  });
}
