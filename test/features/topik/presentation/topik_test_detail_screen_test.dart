import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/start_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/delete_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/start_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_detail_provider.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_test_detail_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/library_harness.dart';
import '../../../support/route_naming.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
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
/// The value of Overall Progress' figure [label] (BR-TOPIK-020).
String _figure(WidgetTester tester, String label) => tester
    .widget<MxStatTile>(
      find.byWidgetPredicate((w) => w is MxStatTile && w.label == label),
    )
    .value;

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
    expect(_figure(tester, 'Sessions'), '2');
    expect(_figure(tester, 'Completed'), '2');
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
    final taps = _Taps();
    await pump(tester, env, taps);
    expect(_figure(tester, 'Sessions'), '3');
    expect(_figure(tester, 'Completed'), '3');
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('#3'), findsOneWidget);

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
    expect(_figure(tester, 'Sessions'), '2');
    expect(_figure(tester, 'Completed'), '2');
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
    final taps = _Taps();
    await pump(tester, env, taps);
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

  libraryTest('a recent row opens Summary when completed and the attempt '
      'when in progress (BR-TOPIK-021)', (tester, env) async {
    final done = await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.add(const Duration(hours: 1)),
    );
    final taps = _Taps();
    await pump(tester, env, taps);

    await tester.tap(find.text('#1'));
    await tester.tap(find.text('#2'));
    expect(taps.summaries, [done.id]);
    expect(taps.attempts, [open.id]);
  });

  libraryTest('an error after the test loaded drops the FAB and the title '
      '(States: error, The Content Gate Rule)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pumpLibraryScreen(
      tester,
      env,
      screen(taps),
      overrides: [
        ...topikContentOverrides([test]),
        topikTestDetailProvider(test.testId).overrideWith((ref) {
          // The store's stream reads the test, then fails, as a locked
          // database does.
          final out = StreamController<TopikTestDetail>();
          final read = ref.watch(watchTopikTestDetailUseCaseProvider);
          final sub = read(test.testId).listen((detail) {
            out
              ..add(detail)
              ..addError(const DatabaseLockedFailure(cause: 'locked'));
          });
          ref.onDispose(() {
            unawaited(sub.cancel());
            unawaited(out.close());
          });
          return out.stream;
        }),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byType(MxFab), findsNothing);
    expect(find.text(test.titleKo), findsNothing);
  });

  libraryTest('error: Retry reads the test again (States: error to loaded)', (
    tester,
    env,
  ) async {
    var reads = 0;
    final taps = _Taps();
    await pumpLibraryScreen(
      tester,
      env,
      screen(taps),
      overrides: [
        ...topikContentOverrides([test]),
        topikTestDetailProvider(test.testId).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikTestDetail>.error(StateError('read'));
          }
          return ref.watch(watchTopikTestDetailUseCaseProvider)(test.testId);
        }),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text("Couldn't load this test"), findsOneWidget);
    expect(find.text('Nothing was lost. Try again.'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(MxErrorState), findsNothing);
    expect(find.text('No attempts yet'), findsOneWidget);
  });

  libraryTest('a start refused because the test left says so '
      '(BR-TOPIK-019)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = _Taps();
    await pumpLibraryScreen(
      tester,
      env,
      screen(taps),
      overrides: [
        ...topikContentOverrides([test]),
        // The content changed after the screen read it: no test to start.
        startTopikAttemptUseCaseProvider.overrideWith(
          (ref) => StartTopikAttemptUseCase(
            FakeTopikContentRepository([]),
            TopikAttemptRepositoryImpl(env.db),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    expect(taps.attempts, isEmpty);
    expect(find.text("This test isn't available"), findsOneWidget);
  });

  libraryTest('the test title names the route once, as a heading', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, env, _Taps());

    final node = tester.getSemantics(find.text(test.titleKo));
    expect(node.hasFlag(SemanticsFlag.namesRoute), isTrue);
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(routeNamingNodes(tester), 1);
    handle.dispose();
  });
}
