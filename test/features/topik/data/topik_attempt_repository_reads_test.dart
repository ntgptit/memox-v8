import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';

import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_attempt_store.dart';
import '../../../support/topik_content_fixtures.dart';

void main() {
  late AppDatabase db;
  late TopikAttemptRepositoryImpl repository;
  final test2 = topikTestFixture();
  final test1 = topikTestFixture(level: TopikLevel.topik1);
  setUp(() {
    (:db, :repository) = openTopikAttemptStore();
  });
  tearDown(() => db.close());

  Future<TopikAttempt> completed(int startedSecond) async {
    final attempt = topikOk(
      await repository.start(test2, now: topikAt(startedSecond)),
    );
    return topikOk(
      await repository.submit(
        attemptId: attempt.id,
        test: test2,
        elapsedMs: 0,
        now: topikAt(startedSecond + 1),
      ),
    );
  }

  test('attempts of a test, newest first, and only that test\'s '
      '(BR-TOPIK-021)', () async {
    final first = await completed(0);
    final second = await completed(10);
    final open = topikOk(await repository.start(test2, now: topikAt(20)));
    topikOk(await repository.start(test1, now: topikAt(30)));

    final attempts = await repository.watchAttemptsOfTest(test2.testId).first;

    expect(attempts.map((a) => a.id), [open.id, second.id, first.id]);
  });

  test('a tie inside one second keeps creation order, newest first', () async {
    final a = await completed(0);
    final b = topikOk(await repository.start(test2, now: topikAt(0)));
    final attempts = await repository.watchAttemptsOfTest(test2.testId).first;
    expect(attempts.map((x) => x.id), [b.id, a.id]);
  });

  test('an attempt with its answers re-emits on a write and emits null once '
      'deleted (BR-TOPIK-018)', () async {
    final attempt = topikOk(await repository.start(test2));
    final seen = <TopikAttemptDetail?>[];
    final sub = repository.watchAttempt(attempt.id).listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(seen.single!.answers, hasLength(50));
    expect(seen.single!.answers.first.selectedIdx, isNull);

    topikOk(
      await repository.answer(
        attemptId: attempt.id,
        questionNo: 1,
        selectedIdx: 3,
        elapsedMs: 0,
      ),
    );
    await pumpEventQueue();
    expect(seen.last!.answers.first.selectedIdx, 3);

    topikOk(await repository.delete(attempt.id));
    await pumpEventQueue();
    expect(seen.last, isNull);
  });

  test('test statuses fold every attempt (BR-TOPIK-022)', () async {
    await completed(0);
    topikOk(await repository.start(test2, now: topikAt(20)));

    final statuses = await repository.watchTestStatuses().first;

    expect(statuses.keys, [test2.testId]);
    final status = statuses[test2.testId]!;
    expect(status.hasInProgress, isTrue);
    expect(status.completedCount, 1);
    expect(status.bestScore, 0);
    expect(status.lastActivityAt.isAtSameMomentAs(topikAt(20)), isTrue);
  });
}
