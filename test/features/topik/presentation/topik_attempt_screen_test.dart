import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/usecases/answer_topik_question_use_case.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/answer_topik_question_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/submit_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_choice_tile.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

/// The attempt store with an answer that fails, as a locked database does.
final class _FailingAnswer implements TopikAttemptRepository {
  @override
  Future<Outcome<void, TopikRejection>> answer({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
    DateTime? now,
  }) async => throw const DatabaseLockedFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The attempt store with a submit that waits for [release]; the use case is
/// final, so the wait sits under it.
final class _HeldSubmit implements TopikAttemptRepository {
  _HeldSubmit(this._real);

  final TopikAttemptRepository _real;
  final release = Completer<void>();
  var calls = 0;

  @override
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  }) async {
    calls++;
    await release.future;
    return _real.submit(
      attemptId: attemptId,
      test: test,
      elapsedMs: elapsedMs,
      now: now,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Screen 37 (UC-TOPIK-003; BR-TOPIK-010…016): answering, moving, the clock,
// leaving and submitting; each test is a row of detail file 37's
// Transitions table. The gone, listening and language rows are in
// topik_attempt_screen_states_test.dart.
void main() {
  final reading = topikTestFixture();

  libraryTest('opens at the attempt\'s current question, with the real '
      'numbers (BR-TOPIK-010, -011, -001)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading, currentNo: 3);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [reading]);

    expect(find.text('3. ${reading.questions[2].stemKo}'), findsOneWidget);
    expect(find.text('3 / 50'), findsOneWidget);
    // The study bar paints its mode upper-case.
    expect(find.text('PRACTICE'), findsOneWidget);
  });

  libraryTest('TOPIK I reading: the counter reads 31 / 70 and the grid runs '
      '31 to 70 (BR-TOPIK-001, UC-TOPIK-003)', (tester, env) async {
    final topik1 = topikTestFixture(level: TopikLevel.topik1);
    final attempt = await topikSeedAttempt(env, topik1);
    final handle = tester.ensureSemantics();
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [topik1]);

    expect(find.text('31 / 70'), findsOneWidget);
    expect(find.textContaining('31. '), findsOneWidget);
    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Question 31, not answered'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 70, not answered'), findsOneWidget);
    expect(find.bySemanticsLabel('Question 1, not answered'), findsNothing);
    handle.dispose();
  });

  libraryTest('a pick is saved at once and shows only as chosen '
      '(BR-TOPIK-012, -016)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [reading]);

    await tester.tap(find.text('② 보기 2'));
    await tester.pumpAndSettle();
    expect(topikOptionTile(tester, '② 보기 2').tone, MxChoiceTone.selected);
    await tester.tap(find.text('④ 보기 4'));
    await tester.pumpAndSettle();
    expect(topikOptionTile(tester, '② 보기 2').tone, MxChoiceTone.idle);
    expect(topikOptionTile(tester, '④ 보기 4').tone, MxChoiceTone.selected);
    final answer = (await topikStoredAttempt(
      tester,
      env,
      attempt.id,
    )).answers.first;
    expect(answer.selectedIdx, 4);
  });

  libraryTest('Next, Previous and a grid cell move; the time of the question '
      'left is written (BR-TOPIK-015)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [reading]);

    topikWait(env, 7);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 50'), findsOneWidget);
    topikWait(env, 4);
    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 50'), findsOneWidget);
    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.text('10 / 50'), findsOneWidget);

    final times = {
      for (final answer in (await topikStoredAttempt(
        tester,
        env,
        attempt.id,
      )).answers)
        if (answer.timeSpentMs > 0) answer.questionNo: answer.timeSpentMs,
    };
    expect(times, {1: 7000, 2: 4000});
  });

  libraryTest('in the background no time runs (BR-TOPIK-015)', (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(tester, env, attempt.id, catalog: [reading]);

    topikWait(env, 3);
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    topikWait(env, 600);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    topikWait(env, 2);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final first = (await topikStoredAttempt(
      tester,
      env,
      attempt.id,
    )).answers.first;
    expect(first.timeSpentMs, 5000);
  });

  libraryTest('Close leaves with nothing lost: the attempt stays in progress '
      'with its answer and its time (BR-TOPIK-010)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
    );

    await tester.tap(find.text('① 보기 1'));
    await tester.pumpAndSettle();
    topikWait(env, 5);
    await tester.tap(find.byTooltip('Close'));
    expect(exits.closes, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final detail = await topikStoredAttempt(tester, env, attempt.id);
    expect(detail.attempt.isCompleted, isFalse);
    expect(detail.answers.first.selectedIdx, 1);
    expect(detail.answers.first.timeSpentMs, 5000);
  });

  libraryTest('Submit with blanks asks; Keep answering stays; Submit '
      'submits and opens the summary (BR-TOPIK-013, -014)', (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(
      env,
      reading,
      currentNo: 50,
      answers: {1: 1},
    );
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text('49 questions unanswered'), findsOneWidget);
    await tester.tap(find.text('Keep answering'));
    await tester.pumpAndSettle();
    expect(exits.submitted, isEmpty);

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit').last);
    // Held, Submit spinning, until app/ replaces the screen with 38.
    await tester.pump(const Duration(seconds: 1));
    expect(exits.submitted, [attempt.id]);
    expect(
      (await topikStoredAttempt(tester, env, attempt.id)).attempt.isCompleted,
      isTrue,
    );
  });

  libraryTest('with every question answered, Submit does not ask', (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(
      env,
      reading,
      currentNo: 50,
      answers: {for (final question in reading.questions) question.no: 1},
    );
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
    );

    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(seconds: 1));
    expect(exits.submitted, [attempt.id]);
    expect(find.text('1 question unanswered'), findsNothing);
  });

  libraryTest('while submitting, a second tap and Back do nothing '
      '(BR-TOPIK-014)', (tester, env) async {
    final attempt = await topikSeedAttempt(
      env,
      reading,
      currentNo: 50,
      answers: {for (final question in reading.questions) question.no: 2},
    );
    late _HeldSubmit held;
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      overrides: [
        submitTopikAttemptUseCaseProvider.overrideWith(
          (ref) => SubmitTopikAttemptUseCase(
            FakeTopikContentRepository([reading]),
            held = _HeldSubmit(TopikAttemptRepositoryImpl(env.db)),
          ),
        ),
      ],
      catalog: [reading],
    );

    await tester.tap(find.text('Submit'));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(
      tester.widget<MxIconButton>(find.byType(MxIconButton).last).onPressed,
      isNull,
    );
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, 'Questions'))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(MxSpinner), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(held.calls, 1);
    expect(find.byType(TopikAttemptScreen), findsOneWidget);

    held.release.complete();
    await tester.pump(const Duration(seconds: 1));
    expect(exits.submitted, [attempt.id]);
  });

  libraryTest('a choice that is not saved says so and is not shown as '
      'chosen (UC-TOPIK-003 E4)', (tester, env) async {
    final attempt = await topikSeedAttempt(env, reading);
    await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      overrides: [
        answerTopikQuestionUseCaseProvider.overrideWith(
          (ref) => AnswerTopikQuestionUseCase(_FailingAnswer()),
        ),
      ],
      catalog: [reading],
    );

    await tester.tap(find.text('③ 보기 3'));
    await tester.pumpAndSettle();
    expect(find.text("Your choice wasn't saved. Try again."), findsOneWidget);
    expect(topikOptionTile(tester, '③ 보기 3').tone, MxChoiceTone.idle);
  });

  libraryTest('a submit refused because the test left says so and lets the '
      'person go on (BR-TOPIK-019)', (tester, env) async {
    final attempt = await topikSeedAttempt(
      env,
      reading,
      currentNo: 50,
      answers: {for (final question in reading.questions) question.no: 2},
    );
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
      overrides: [
        // The content changed after the screen read it: nothing to score.
        submitTopikAttemptUseCaseProvider.overrideWith(
          (ref) => SubmitTopikAttemptUseCase(
            FakeTopikContentRepository([]),
            TopikAttemptRepositoryImpl(env.db),
          ),
        ),
      ],
    );

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();
    expect(find.text("This test isn't available"), findsOneWidget);
    expect(exits.submitted, isEmpty);
    expect(
      (await topikStoredAttempt(tester, env, attempt.id)).attempt.isCompleted,
      isFalse,
    );

    await tester.tap(find.text('③ 보기 3'));
    await tester.pumpAndSettle();
    expect(topikOptionTile(tester, '③ 보기 3').tone, MxChoiceTone.selected);
  });

  libraryTest("the grid's Submit submits like the footer's", (
    tester,
    env,
  ) async {
    final attempt = await topikSeedAttempt(
      env,
      reading,
      answers: {for (final question in reading.questions) question.no: 4},
    );
    final exits = await pumpTopikAttempt(
      tester,
      env,
      attempt.id,
      catalog: [reading],
    );

    await tester.tap(find.text('Questions'));
    await tester.pumpAndSettle();
    // The sheet's Submit, over the footer's (the last pick made 50 current).
    await tester.tap(find.text('Submit').last);
    // The sheet closes, then the submit holds the screen (it never settles).
    for (var frame = 0; frame < 3; frame++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(exits.submitted, [attempt.id]);
  });
}
