import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/usecases/start_topik_attempt_use_case.dart';
import 'package:memox/features/topik/presentation/providers/start_topik_attempt_use_case_provider.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_detail_provider.dart';
import 'package:memox/features/topik/presentation/providers/watch_topik_test_detail_use_case_provider.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_line_chart.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_recent_attempt_row_widget.dart';

import '../../../support/library_harness.dart';
import '../../../support/route_naming.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';
import '../../../support/topik_screen_fixtures.dart';
import '../../../support/topik_test_detail_fixtures.dart';

import 'package:forui/forui.dart';

// Screen 36 (UC-TOPIK-002, BR-TOPIK-011, -020): Overview, starting an
// attempt, and the screen's states. History is in
// topik_test_detail_history_test.dart.
void main() {
  final test = topikTestFixture();

  libraryTest('no attempt: the empty card starts one, and there is no FAB '
      '(BR-TOPIK-020, critique F2)', (tester, env) async {
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);

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
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);

    expect(find.text('ACCURACY'), findsOneWidget);
    expect(topikDetailFigure(tester, 'Sessions'), '2');
    expect(topikDetailFigure(tester, 'Completed'), '2');
    for (final number in ['#2', '#1']) {
      expect(
        find.descendant(
          of: find.byType(TopikRecentAttemptRowWidget),
          matching: find.text(number),
        ),
        findsOneWidget,
      );
    }
    expect(find.byType(MxFab), findsOneWidget);
  });

  // Follow-ups spec G8: submitted attempts only, from two; scores 44, 62
  // and 76 are 22, 31 and 38 right of 50 at two points each.
  for (final (name, corrects, summary) in [
    ('one submitted attempt: no trend', [22], null),
    (
      'three submitted attempts: the trend, read as one summary',
      [22, 31, 38],
      'Scores of 3 submitted attempts, oldest first: 44, 62, 76, out of 100',
    ),
  ]) {
    libraryTest('Score trend, $name; an attempt in progress is no point', (
      tester,
      env,
    ) async {
      final handle = tester.ensureSemantics();
      for (final (day, correct) in corrects.indexed) {
        await topikSeedCompleted(
          env,
          test,
          startedAt: libraryToday.add(Duration(days: day)),
          correct: correct,
        );
      }
      await topikSeedInProgress(
        env,
        test,
        startedAt: libraryToday.add(const Duration(days: 9)),
      );
      await pumpTopikTestDetail(tester, env, test, TopikDetailTaps());

      if (summary == null) {
        expect(find.byType(MxLineChart), findsNothing);
        expect(find.text('SCORE TREND'), findsNothing);
        handle.dispose();
        return;
      }
      await tester.scrollUntilVisible(
        find.byType(MxLineChart),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SCORE TREND'), findsOneWidget);
      expect(
        tester.widget<MxLineChart>(find.byType(MxLineChart)).points.length,
        3,
      );
      expect(find.bySemanticsLabel(summary), findsOneWidget);
      handle.dispose();
    });
  }

  libraryTest('the FAB with an attempt in progress asks; Continue opens it '
      '(BR-TOPIK-011)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.add(const Duration(hours: 2)),
    );
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);

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
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);

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
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);
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
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);
    await tester.tap(find.byType(MxFab));
    await tester.tap(find.byType(MxFab), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(taps.attempts, hasLength(1));
    // The second tap is ignored, not refused: no message either.
    expect(find.byType(FToast), findsNothing);
  });

  libraryTest('an unknown test: missing, with Back to tests and no FAB '
      '(UC-TOPIK-002 E1)', (tester, env) async {
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(
      tester,
      env,
      test,
      taps,
      testId: 'topik2-1-reading',
    );

    expect(find.text("This test isn't available"), findsOneWidget);
    expect(find.byType(MxFab), findsNothing);
    await tester.tap(find.text('Back to tests'));
    expect(taps.backToTests, 1);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('a recent row opens Summary when completed and the attempt '
      'when in progress (BR-TOPIK-021)', (tester, env) async {
    final done = await topikSeedCompleted(env, test, startedAt: libraryToday);
    final open = await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.add(const Duration(hours: 1)),
    );
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);

    await tester.tap(find.text('#1'));
    await tester.tap(find.text('#2'));
    expect(taps.summaries, [done.id]);
    expect(taps.attempts, [open.id]);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('an error after the test loaded drops the FAB and the title '
      '(States: error, The Content Gate Rule)', (tester, env) async {
    await topikSeedCompleted(env, test, startedAt: libraryToday);
    final taps = TopikDetailTaps();
    await pumpLibraryScreen(
      tester,
      env,
      topikTestDetailScreen(test, taps),
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
    final taps = TopikDetailTaps();
    await pumpLibraryScreen(
      tester,
      env,
      topikTestDetailScreen(test, taps),
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
    final taps = TopikDetailTaps();
    await pumpLibraryScreen(
      tester,
      env,
      topikTestDetailScreen(test, taps),
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

  libraryTest('Recent attempts are the five newest, #7 to #3 '
      '(BR-TOPIK-021, UC-TOPIK-002)', (tester, env) async {
    for (var day = 0; day < 7; day++) {
      await topikSeedCompleted(
        env,
        test,
        startedAt: libraryToday.add(Duration(days: day)),
      );
    }
    await pumpTopikTestDetail(tester, env, test, TopikDetailTaps());

    expect(topikDetailFigure(tester, 'Sessions'), '7');
    // The score trend above names every submitted attempt; the rows are
    // the five newest.
    Finder row(String number) => find.descendant(
      of: find.byType(TopikRecentAttemptRowWidget),
      matching: find.text(number),
    );
    for (final number in ['#7', '#6', '#5', '#4', '#3']) {
      expect(row(number), findsOneWidget);
    }
    expect(row('#2'), findsNothing);
    expect(row('#1'), findsNothing);
  });

  libraryTest('Total time sums every attempt and reads to the second: '
      '1h 02m 11s (BR-TOPIK-020, -025)', (tester, env) async {
    await topikSeedCompleted(
      env,
      test,
      startedAt: libraryToday,
      elapsedMs: 3731000,
    );
    await pumpTopikTestDetail(tester, env, test, TopikDetailTaps());

    // Overall Progress' last-activity line and the attempt's own row.
    expect(findPlainTextContaining('1h 02m 11s'), findsNWidgets(2));
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Text) return false;
        final plain = (widget.data ?? '').replaceAll('\u00A0', ' ');
        return plain.startsWith('Last activity') &&
            plain.endsWith('1h 02m 11s');
      }),
      findsOneWidget,
    );
  });

  libraryTest('Start new asks again; Cancel keeps the attempt in progress '
      '(BR-TOPIK-011)', (tester, env) async {
    final open = await topikSeedInProgress(env, test, startedAt: libraryToday);
    final taps = TopikDetailTaps();
    await pumpTopikTestDetail(tester, env, test, taps);

    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start new'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new attempt?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Start a new attempt?'), findsNothing);
    expect(taps.attempts, isEmpty);
    final stored = await tester.runAsync(
      () => TopikAttemptRepositoryImpl(env.db).watchAttempt(open.id).first,
    );
    expect(stored!.attempt.isCompleted, isFalse);
  });

  libraryTest('a start refused because an attempt in progress appeared says '
      'so (BR-TOPIK-011)', (tester, env) async {
    final taps = TopikDetailTaps();
    await pumpLibraryScreen(
      tester,
      env,
      topikTestDetailScreen(test, taps),
      overrides: [
        ...topikContentOverrides([test]),
        // Another screen started an attempt between the read and the tap.
        startTopikAttemptUseCaseProvider.overrideWith(
          (ref) => StartTopikAttemptUseCase(
            FakeTopikContentRepository([test]),
            _InProgressAppeared(),
          ),
        ),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(taps.attempts, isEmpty);
    expect(find.text('You have an attempt in progress'), findsOneWidget);
  });

  libraryTest('the test title names the route once, as a heading', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpTopikTestDetail(tester, env, test, TopikDetailTaps());

    final node = tester.getSemantics(find.text(test.titleKo));
    expect(node.hasFlag(SemanticsFlag.namesRoute), isTrue);
    expect(node.hasFlag(SemanticsFlag.isHeader), isTrue);
    expect(routeNamingNodes(tester), 1);
    handle.dispose();
  });
}

/// The store once another screen has started an attempt of the test.
final class _InProgressAppeared implements TopikAttemptRepository {
  @override
  Future<Outcome<TopikAttempt, TopikRejection>> start(
    TopikTest test, {
    DateTime? now,
  }) async => const Rejected(TopikRejection.inProgressExists);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
