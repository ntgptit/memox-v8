import 'package:flutter/material.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';
import '../../../support/topik_test_detail_fixtures.dart';

/// The attempt store with a delete that fails, as a locked database does.
final class _FailingDelete implements TopikAttemptRepository {
  @override
  Future<Outcome<void, TopikRejection>> delete(String attemptId) async =>
      throw const DatabaseLockedFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// Screen 36's History (UC-TOPIK-002, BR-TOPIK-018, -021): its rows, their
// actions, and deleting an attempt.
void main() {
  final test = topikTestFixture();

  libraryTest('History: delete asks, then removes the row, renumbers the '
      'later ones and recomputes the progress (BR-TOPIK-018, -021)', (
    tester,
    env,
  ) async {
    for (final day in [0, 1, 2]) {
      await topikSeedCompleted(
        env,
        test,
        startedAt: libraryToday.add(Duration(days: day)),
        correct: 20 + day,
      );
    }
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);
    expect(topikDetailFigure(tester, 'Sessions'), '3');
    expect(topikDetailFigure(tester, 'Completed'), '3');
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('#3'), findsOneWidget);
    expect(find.text('3 ATTEMPTS'), findsOneWidget);

    // Newest first: #3, #2, #1. Cancel leaves #2 in place.
    await tester.tap(find.byTooltip('Delete attempt').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('#3'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete attempt').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    // The attempt with 22 right was #3; it is #2 now, and #3 is gone.
    expect(find.text('#3'), findsNothing);
    expect(find.text('#2'), findsOneWidget);
    // The header counts what is left.
    expect(find.text('2 ATTEMPTS'), findsOneWidget);
    expect(
      findPlainTextContaining('22 / ${test.questions.length} correct'),
      findsOneWidget,
    );
    expect(
      findPlainTextContaining('21 / ${test.questions.length} correct'),
      findsNothing,
    );

    await tester.tap(find.text('Overview'));
    await tester.pumpAndSettle();
    expect(topikDetailFigure(tester, 'Sessions'), '2');
    expect(topikDetailFigure(tester, 'Completed'), '2');
  });

  libraryTest('History: Summary, Review and Continue open their screens', (
    tester,
    env,
  ) async {
    final done = await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.add(const Duration(hours: 1)),
    );
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summary'));
    await tester.tap(find.text('Review'));
    await tester.tap(find.text('Continue'));
    expect(taps.summaries, [done.id]);
    expect(taps.reviews, [done.id]);
    expect(taps.attempts, [open.id]);
  });

  libraryTest('History with no attempt keeps the FAB', (tester, env) async {
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('a delete that fails keeps the row and says nothing was lost '
      '(UC-TOPIK-002 E3)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = TopikDetailTaps();
    await pumpLibraryScreen(
      tester,
      env,
      topikTestDetailScreen(test, taps),
      overrides: [
        ...topikContentOverrides([test]),
        deleteTopikAttemptUseCaseProvider.overrideWith(
          (ref) => DeleteTopikAttemptUseCase(_FailingDelete()),
        ),
      ],
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete attempt'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.text('#1'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });

  libraryTest('a completed row shows the score and the correct answers, '
      'on Overview and in History (BR-TOPIK-021, spec §6.2)', (
    tester,
    env,
  ) async {
    final done = await topikSeedCompleted(
      env,
      test,
      startedAt: libraryToday,
      correct: 25,
    );
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);
    final score = '${done.score} / ${done.maxScore}';
    final correct = '25 / ${test.questions.length} correct';

    expect(findPlainTextContaining(score), findsOneWidget);
    expect(findPlainTextContaining(correct), findsOneWidget);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(findPlainTextContaining(score), findsOneWidget);
    expect(findPlainTextContaining(correct), findsOneWidget);
    // The list is headed by its count, as Overview's lists are.
    expect(find.text('1 ATTEMPT'), findsOneWidget);
  });
}
