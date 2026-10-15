import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/presentation/controllers/topik_attempt_controller.dart';

import '../../../support/fake_day_clock.dart';
import '../../../support/library_harness.dart';
import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 37's clock and submit guard (spec §5.4, §13.6; BR-TOPIK-014, -015).
void main() {
  final test0 = topikTestFixture();
  late LibraryEnv env;
  late TopikAttemptRepositoryImpl store;

  setUp(() {
    env = LibraryEnv(openTestDatabase(), FakeDayClock(libraryToday));
    store = TopikAttemptRepositoryImpl(env.db, now: env.clock.now);
  });
  tearDown(() => env.db.close());

  Future<TopikAttempt> open() async =>
      topikOk(await store.start(test0, now: libraryToday));

  ({ProviderContainer container, TopikAttemptController controller}) control(
    String attemptId, {
    bool hasContent = true,
  }) {
    final container = libraryContainer(
      env,
      overrides: topikContentOverrides(hasContent ? [test0] : []),
    );
    final provider = topikAttemptControllerProvider(attemptId);
    container.listen(provider, (_, _) {});
    return (
      container: container,
      controller: container.read(provider.notifier),
    );
  }

  Future<Map<int, int>> times(String attemptId) async {
    final detail = (await store.watchAttempt(attemptId).first)!;
    return {
      for (final answer in detail.answers)
        if (answer.timeSpentMs > 0) answer.questionNo: answer.timeSpentMs,
    };
  }

  void wait(int seconds) =>
      env.clock.current = env.clock.current.add(Duration(seconds: seconds));

  test('time goes to the question that was current, adds up when the person '
      'returns, and stops in the background (BR-TOPIK-015)', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    wait(5);
    await controller.answer(questionNo: 1, selectedIdx: 2);
    wait(3);
    await controller.move(2);
    wait(4);
    await controller.pause();
    wait(600);
    controller.resume();
    wait(2);
    await controller.move(1);
    wait(1);
    await controller.leave();

    expect(await times(attempt.id), {1: 9000, 2: 6000});
    expect(
      (await store.watchAttempt(attempt.id).first)!.attempt.totalTimeMs,
      15000,
    );
  });

  test('a pause while paused writes nothing more', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    wait(2);
    await controller.pause();
    wait(30);
    await controller.pause();
    await controller.leave();

    expect(await times(attempt.id), {1: 2000});
  });

  test('a second submit, and every answer after one, is ignored '
      '(BR-TOPIK-014)', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    final first = controller.submit(test0.testId);
    expect(await controller.submit(test0.testId), isNull);
    expect(topikOk((await first)!).isCompleted, isTrue);
    expect(await controller.answer(questionNo: 1, selectedIdx: 1), isNull);
    expect(await controller.move(2), isNull);
  });

  test('a refused submit lets the person go on', () async {
    final attempt = await open();
    final controlled = control(attempt.id, hasContent: false);

    final outcome = await controlled.controller.submit(test0.testId);
    expect(topikReason(outcome!), TopikRejection.testUnavailable);
    expect(
      controlled.container.read(topikAttemptControllerProvider(attempt.id)),
      isFalse,
    );
    topikOk(
      (await controlled.controller.answer(questionNo: 1, selectedIdx: 3))!,
    );
  });

  test('delete removes the attempt', () async {
    final attempt = await open();
    final controller = control(attempt.id).controller;

    topikOk((await controller.delete())!);
    expect(await store.watchAttempt(attempt.id).first, isNull);
  });
}
