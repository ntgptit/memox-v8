import 'package:flutter/material.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

/// The attempt store with a delete that fails, as a locked database does.
final class _FailingDelete implements TopikAttemptRepository {
  @override
  Future<Outcome<void, TopikRejection>> delete(String attemptId) async =>
      throw const DatabaseLockedFailure(cause: 'locked');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Taps {
  final attempts = <String>[];
  final summaries = <String>[];
  final reviews = <String>[];
  var backToTests = 0;
}

// Screen 36 (UC-TOPIK-002, BR-TOPIK-011, -018, -020, -021).
void main() {
  final test = topikTestFixture();

  Widget screen(_Taps taps, {String? testId}) => TopikTestDetailScreen(
    testId: testId ?? test.testId,
    onOpenAttempt: taps.attempts.add,
    onOpenSummary: taps.summaries.add,
    onOpenReview: taps.reviews.add,
    onBackToTests: () => taps.backToTests++,
  );

  Future<void> pump(
    WidgetTester tester,
    LibraryEnv env,
    _Taps taps, {
    String? testId,
  }) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(taps, testId: testId),
      overrides: topikContentOverrides([test]),
    );
    await tester.pumpAndSettle();
  }

  libraryTest('no attempt: the empty card starts one, and there is no FAB '
      '(BR-TOPIK-020, critique F2)', (tester, env) async {
    final taps = _Taps();
    await pump(tester, env, taps);

    expect(find.text('No attempts yet'), findsOneWidget);
    expect(find.byType(MxFab), findsNothing);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(taps.attempts, hasLength(1));
  });

  libraryTest('Overview: the figures, then recent attempts numbered', (
    tester,
    env,
  ) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday, correct: 25);
    await topikSeedCompleted(
      env,
      test,
      startedAt: libraryToday.add(const Duration(days: 1)),
      correct: 40,
    );
    final taps = _Taps();
    await pump(tester, env, taps);

    expect(find.text('ACCURACY'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('#2'), findsOneWidget);
    expect(find.text('#1'), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('the FAB with an attempt in progress asks; Continue opens it '
      '(BR-TOPIK-011)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.add(const Duration(hours: 2)),
    );
    final taps = _Taps();
    await pump(tester, env, taps);

    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    expect(find.text('You have an attempt in progress'), findsOneWidget);
    await tester.tap(find.text('Continue').last);
    await tester.pumpAndSettle();
    expect(taps.attempts, [open.id]);
  });

  libraryTest('Start new asks again, then replaces the attempt in progress', (
    tester,
    env,
  ) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.add(const Duration(hours: 2)),
    );
    final taps = _Taps();
    await pump(tester, env, taps);

    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new attempt?'), findsOneWidget);
    await tester.tap(find.text('Start new').last);
    await tester.pumpAndSettle();

    expect(taps.attempts, hasLength(1));
    expect(taps.attempts.single, isNot(open.id));
    final store = TopikAttemptRepositoryImpl(env.db);
    final ids = await tester.runAsync(
      () async => [
        for (final a in await store.watchAttemptsOfTest(test.testId).first)
          a.id,
      ],
    );
    expect(ids, isNot(contains(open.id)));
  });

  libraryTest('the dialog dismissed changes nothing', (tester, env) async {
    await topikSeedInProgress(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(taps.attempts, isEmpty);
  });

  libraryTest('a second tap while starting opens one attempt', (
    tester,
    env,
  ) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.byType(MxFab));
    await tester.tap(find.byType(MxFab), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps.attempts, hasLength(1));
    // The second tap is ignored, not refused: no message either.
    expect(find.byType(SnackBar), findsNothing);
  });

  libraryTest('History: delete asks, then removes the row and renumbers '
      '(BR-TOPIK-018, -021)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    await topikSeedCompleted(
      env,
      test,
      startedAt: libraryToday.add(const Duration(days: 1)),
    );
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('#2'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete attempt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('#2'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete attempt').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('#2'), findsNothing);
    expect(find.text('#1'), findsOneWidget);
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
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Summary'));
    await tester.tap(find.text('Review'));
    await tester.tap(find.text('Continue'));
    expect(taps.summaries, [done.id]);
    expect(taps.reviews, [done.id]);
    expect(taps.attempts, [open.id]);
  });

  libraryTest('an unknown test: missing, with Back to tests and no FAB '
      '(UC-TOPIK-002 E1)', (tester, env) async {
    final taps = _Taps();
    await pump(tester, env, taps, testId: 'topik2-1-reading');

    expect(find.text("This test isn't available"), findsOneWidget);
    expect(find.byType(MxFab), findsNothing);
    await tester.tap(find.text('Back to tests'));
    expect(taps.backToTests, 1);
  });

  libraryTest('History with no attempt keeps the FAB', (tester, env) async {
    final taps = _Taps();
    await pump(tester, env, taps);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('a delete that fails keeps the row and says nothing was lost '
      '(UC-TOPIK-002 E3)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pumpLibraryScreen(
      tester,
      env,
      screen(taps),
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
}
