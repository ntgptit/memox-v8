import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/features/study/presentation/screens/study_home_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_attempt_screen.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/di/topik_audio_repository_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_review_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../support/library_harness.dart';
import '../support/topik_attempt_screen_fixtures.dart';
import '../support/topik_fakes.dart';
import '../support/topik_screen_fixtures.dart';

// Detail files 34–36: the TOPIK screens under Study (the tab bar stays).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _go(WidgetTester tester, String location) async {
  GoRouter.of(tester.element(find.byType(Scaffold).first)).go(location);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  test('the paths', () {
    expect(AppRoutes.topik, '/study/topik');
    expect(AppRoutes.topikLevel('topik1'), '/study/topik/topik1');
    expect(
      AppRoutes.topikTest('topik2-96-reading'),
      '/study/topik/test/topik2-96-reading',
    );
    expect(AppRoutes.topikAttempt('a1'), '/study/topik/attempt/a1');
    expect(AppRoutes.topikSummary('a1'), '/study/topik/attempt/a1/summary');
    expect(AppRoutes.topikReview('a1'), '/study/topik/attempt/a1/review');
    expect(
      AppRoutes.topikReview('a1', questionNo: 31),
      '/study/topik/attempt/a1/review?q=31',
    );
  });

  libraryTest('Study home → TOPIK → a level → a test under the tab bar; Back '
      'climbs one level each time', (tester, env) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: topikContentOverrides(topikScreenTests()),
    );
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navStudy),
      ),
    );

    await _tap(tester, find.text(_en.topikEntryTitle));
    expect(find.byType(TopikHomeScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);

    await _tap(tester, find.text(_en.topikLevel2));
    expect(find.byType(TopikTestListScreen), findsOneWidget);

    await _tap(tester, find.textContaining('제96회').first);
    expect(find.byType(TopikTestDetailScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(TopikTestListScreen), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(TopikHomeScreen), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(StudyHomeScreen), findsOneWidget);
  });

  libraryTest('deep links: an unknown level is not found; an unknown test is '
      'missing, and Back to tests opens TOPIK', (tester, env) async {
    await pumpMemoxApp(
      tester,
      env,
      overrides: topikContentOverrides(topikScreenTests()),
    );

    await _go(tester, '/study/topik/xyz');
    expect(find.text(_en.routeNotFoundTitle), findsOneWidget);

    await _go(tester, AppRoutes.topikTest('topik2-1-reading'));
    expect(find.text(_en.topikTestMissingTitle), findsOneWidget);
    await _tap(tester, find.text(_en.topikBackToTests));
    expect(find.byType(TopikHomeScreen), findsOneWidget);
  });

  libraryTest('an attempt opens full screen above the tab bar, and Close '
      'returns to the test (spec §8)', (tester, env) async {
    final tests = topikScreenTests();
    final test96 = tests.firstWhere(
      (t) =>
          t.level == TopikLevel.topik2 &&
          t.round == 96 &&
          t.section == TopikSection.reading,
    );
    await topikSeedInProgress(env, test96, startedAt: libraryToday);
    await pumpMemoxApp(tester, env, overrides: topikContentOverrides(tests));
    await _go(tester, AppRoutes.topikTest(test96.testId));

    await _tap(tester, find.text('#1'));
    expect(find.byType(TopikAttemptScreen), findsOneWidget);
    expect(find.byType(MxBottomNav), findsNothing);
    await _tap(tester, find.byTooltip(_en.topikClose));
    expect(find.byType(TopikTestDetailScreen), findsOneWidget);
  });

  libraryTest('a deep link to an attempt opens it; Close lands on TOPIK', (
    tester,
    env,
  ) async {
    final tests = topikScreenTests();
    final attempt = await topikSeedInProgress(
      env,
      tests.last,
      startedAt: libraryToday,
    );
    await pumpMemoxApp(
      tester,
      env,
      overrides: [
        ...topikContentOverrides(tests),
        topikAudioRepositoryProvider.overrideWithValue(
          FakeTopikAudioRepository(),
        ),
      ],
    );
    await _go(tester, AppRoutes.topikAttempt(attempt.id));

    expect(find.byType(TopikAttemptScreen), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.topikClose));
    expect(find.byType(TopikHomeScreen), findsOneWidget);
  });

  libraryTest('Submit on 37 replaces it with the summary; Done lands on the '
      'test (UC-TOPIK-003 step 6)', (tester, env) async {
    final tests = topikScreenTests();
    final test96 = tests.firstWhere(
      (t) =>
          t.level == TopikLevel.topik2 &&
          t.round == 96 &&
          t.section == TopikSection.reading,
    );
    await topikSeedAttempt(
      env,
      test96,
      answers: {for (final q in test96.questions) q.no: 1},
    );
    await pumpMemoxApp(tester, env, overrides: topikContentOverrides(tests));
    await _go(tester, AppRoutes.topikTest(test96.testId));
    await _tap(tester, find.text('#1'));
    expect(find.byType(TopikAttemptScreen), findsOneWidget);

    await _tap(tester, find.text(_en.topikSubmit));
    expect(find.byType(TopikSummaryScreen), findsOneWidget);
    expect(find.byType(TopikAttemptScreen), findsNothing);
    await _tap(tester, find.text(_en.topikDone));
    expect(find.byType(TopikTestDetailScreen), findsOneWidget);
  });

  libraryTest('from the summary a row opens Review at its question; Back '
      'returns to the summary (UC-TOPIK-004 step 7)', (tester, env) async {
    final tests = topikScreenTests();
    final done = await topikSeedSubmitted(env, tests.first);
    await pumpMemoxApp(tester, env, overrides: topikContentOverrides(tests));
    await _go(tester, AppRoutes.topikSummary(done.id));
    expect(find.byType(TopikSummaryScreen), findsOneWidget);

    // The rows sit below the hero, the figures and the chart.
    await tester.scrollUntilVisible(
      find.text(_en.topikQuestionTitle(33)),
      300,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await _tap(tester, find.text(_en.topikQuestionTitle(33)));
    expect(find.byType(TopikReviewScreen), findsOneWidget);
    expect(find.text(_en.topikReviewTitle(33, 70)), findsOneWidget);
    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(find.byType(TopikSummaryScreen), findsOneWidget);
  });
}
