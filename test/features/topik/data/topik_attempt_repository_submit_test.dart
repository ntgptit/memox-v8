import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';

// TOPIK spec §5.1, §5.3, §13.5: submit and delete. Fixture: TOPIK I listening, questions 1–30,
// 1–10 worth 4 and 11–30 worth 3; the answer of question n is (n - 1) % 4 + 1.
final _test = topikTestFixture(
  level: TopikLevel.topik1,
  section: TopikSection.listening,
);
final _t0 = DateTime.utc(2026, 10, 15, 9);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

void main() {
  late AppDatabase db;
  late TopikAttemptRepositoryImpl repository;
  setUp(() {
    db = openTestDatabase();
    repository = TopikAttemptRepositoryImpl(db, now: () => _t0);
  });
  tearDown(() => db.close());
  group('submit (BR-TOPIK-013)', () {
    test('scores against the content and snapshots every answer', () async {
      final attempt = topikOk(await repository.start(_test));
      topikOk(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 1,
          selectedIdx: 1,
          elapsedMs: 1000,
        ),
      );
      topikOk(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 2,
          selectedIdx: 1,
          elapsedMs: 1000,
        ),
      );
      topikOk(
        await repository.answer(
          attemptId: attempt.id,
          questionNo: 11,
          selectedIdx: 3,
          elapsedMs: 1000,
        ),
      );

      final done = topikOk(
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
        for (final a in await topikAnswerRows(db, attempt.id)) a.questionNo: a,
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
      final attempt = topikOk(await repository.start(_test));
      topikOk(
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
        final attempt = topikOk(await repository.start(_test));
        topikOk(
          await repository.submit(
            attemptId: attempt.id,
            test: _test,
            elapsedMs: 0,
            now: _at(10),
          ),
        );
        expect(
          topikReason(
            await repository.submit(
              attemptId: attempt.id,
              test: _test,
              elapsedMs: 900,
              now: _at(20),
            ),
          ),
          TopikRejection.attemptCompleted,
        );
        final row = (await topikAttemptRow(db, attempt.id))!;
        expect(row.completedAt!.isAtSameMomentAs(_at(10)), isTrue);
        expect(row.totalTimeMs, 0);
      },
    );

    test('refuses content that is not the attempt\'s test and writes nothing '
        '(BR-TOPIK-019)', () async {
      final attempt = topikOk(await repository.start(_test));
      final other = topikTestFixture(level: TopikLevel.topik1);
      expect(
        topikReason(
          await repository.submit(
            attemptId: attempt.id,
            test: other,
            elapsedMs: 100,
          ),
        ),
        TopikRejection.contentMismatch,
      );
      final row = (await topikAttemptRow(db, attempt.id))!;
      expect(row.status, 'in_progress');
      expect(row.totalTimeMs, 0);
    });

    test(
      'a content correction made before submit is the one that scores',
      () async {
        final attempt = topikOk(await repository.start(_test));
        topikOk(
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

        final done = topikOk(
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
      final attempt = topikOk(await repository.start(_test));
      topikOk(await repository.delete(attempt.id));
      expect(await topikAttemptRow(db, attempt.id), isNull);
      expect(await topikAnswerRows(db, attempt.id), isEmpty);
      expect(
        topikReason(await repository.delete(attempt.id)),
        TopikRejection.notFound,
      );
    });

    test('every write to an attempt that is gone is notFound and writes '
        'nothing (BR-TOPIK-018, BR-TOPIK-027)', () async {
      expect(
        topikReason(
          await repository.move(
            attemptId: 'gone',
            toQuestionNo: 1,
            elapsedMs: 0,
          ),
        ),
        TopikRejection.notFound,
      );
      expect(
        topikReason(
          await repository.recordTime(attemptId: 'gone', elapsedMs: 0),
        ),
        TopikRejection.notFound,
      );
      expect(
        topikReason(
          await repository.submit(attemptId: 'gone', test: _test, elapsedMs: 0),
        ),
        TopikRejection.notFound,
      );
      expect(await db.select(db.topikAttempt).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });
  });
}
