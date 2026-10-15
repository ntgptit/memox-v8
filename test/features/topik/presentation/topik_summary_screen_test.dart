import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_summary_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

final class _Exits {
  final reviews = <int?>[];
  var dones = 0;
}

// Screen 38 (UC-TOPIK-004; BR-TOPIK-013, -019, -023…025): each test is a
// row of detail file 38's Transitions table.
void main() {
  final reading = topikTestFixture();

  /// Questions 1–3 right, 4 wrong, 5 blank, the rest blank.
  Map<int, int> mixed(TopikTest test) {
    final q = test.questions;
    return {
      for (final question in q.take(3)) question.no: question.answerIdx,
      q[3].no: q[3].answerIdx % 4 + 1,
    };
  }

  Future<_Exits> pump(
    WidgetTester tester,
    LibraryEnv env,
    String attemptId, {
    List<TopikTest>? catalog,
    List<Override> overrides = const [],
  }) async {
    final exits = _Exits();
    await pumpLibraryScreen(
      tester,
      env,
      TopikSummaryScreen(
        attemptId: attemptId,
        onReview: exits.reviews.add,
        onDone: () => exits.dones++,
      ),
      overrides: [
        ...topikContentOverrides(catalog ?? [reading]),
        ...overrides,
      ],
    );
    await tester.pumpAndSettle();
    return exits;
  }

  /// Scrolls the screen's body (the vertical scroll) until [finder] shows:
  /// the rows sit below the hero, the figures and the chart.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable && widget.axisDirection == AxisDirection.down,
      ),
    );
    await tester.pumpAndSettle();
  }

  libraryTest('the result from the snapshot: score, rows per question; a row, '
      'Review answers and Done lead out (UC-TOPIK-004)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    final exits = await pump(tester, env, done.id);

    expect(find.text('${done.score} / 100'), findsOneWidget);
    expect(find.text('3 / 50'), findsOneWidget);
    await reveal(tester, find.text('Question 1'));
    await tester.tap(find.text('Question 1'));
    await tester.tap(find.text('Review answers'));
    await tester.tap(find.text('Done'));
    expect(exits.reviews, [1, null]);
    expect(exits.dones, 1);
  });

  libraryTest('a filter narrows the chart and the rows; an empty one says so '
      '(UC-TOPIK-004 step 5, A1)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id);

    await reveal(tester, find.widgetWithText(MxFilterChip, 'Wrong'));
    await tester.tap(find.widgetWithText(MxFilterChip, 'Wrong'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('Question 4'));
    expect(find.text('Question 1'), findsNothing);
  });

  libraryTest('a perfect result: Wrong is empty and says so; no weakest '
      'type (BR-TOPIK-024)', (tester, env) async {
    final perfect = await topikSeedSubmitted(
      env,
      reading,
      answers: {for (final q in reading.questions) q.no: q.answerIdx},
    );
    await pump(tester, env, perfect.id);

    await reveal(tester, find.widgetWithText(MxFilterChip, 'Wrong'));
    await tester.tap(find.widgetWithText(MxFilterChip, 'Wrong'));
    await tester.pumpAndSettle();
    await reveal(tester, find.text('No wrong answers'));
    // MxSection paints its title upper-case.
    await reveal(tester, find.text('BY QUESTION TYPE'));
    expect(find.text('Weakest'), findsNothing);
  });

  libraryTest('the eye hides the right answers, and shows them again '
      '(UC-TOPIK-004 step 6)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id);
    await reveal(tester, find.text('Question 1'));

    expect(findPlainTextContaining('Right answer'), findsWidgets);
    await tester.tap(find.byTooltip('Hide answers'));
    await tester.pumpAndSettle();
    expect(findPlainTextContaining('Right answer'), findsNothing);
    await tester.tap(find.byTooltip('Show answers'));
    await tester.pumpAndSettle();
    expect(findPlainTextContaining('Right answer'), findsWidgets);
  });

  libraryTest('TOPIK I reading numbers 31–70 (BR-TOPIK-001)', (
    tester,
    env,
  ) async {
    final t1 = topikTestFixture(level: TopikLevel.topik1);
    final done = await topikSeedSubmitted(env, t1, answers: mixed(t1));
    await pump(tester, env, done.id, catalog: [t1]);

    await reveal(tester, find.text('Question 31'));
    expect(find.text('Question 1'), findsNothing);
  });

  libraryTest('the test removed afterwards changes nothing: the snapshot '
      'stays (BR-TOPIK-019)', (tester, env) async {
    final done = await topikSeedSubmitted(
      env,
      reading,
      answers: mixed(reading),
    );
    await pump(tester, env, done.id, catalog: const []);

    expect(find.text('${done.score} / 100'), findsOneWidget);
    await reveal(tester, find.text('Question 4'));
  });

  libraryTest('the attempt deleted elsewhere: missing, Back to the test '
      '(UC-TOPIK-004 E1)', (tester, env) async {
    final done = await topikSeedSubmitted(env, reading);
    final exits = await pump(tester, env, done.id);

    await TopikAttemptRepositoryImpl(env.db).delete(done.id);
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
    await tester.tap(find.text('Back to the test'));
    expect(exits.dones, 1);
  });

  libraryTest('an attempt in progress has no summary', (tester, env) async {
    final open = await topikSeedAttempt(env, reading);
    await pump(tester, env, open.id);
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });

  libraryTest('a read that fails: Retry reads again', (tester, env) async {
    var reads = 0;
    final done = await topikSeedSubmitted(env, reading);
    await pump(
      tester,
      env,
      done.id,
      overrides: [
        topikSummaryProvider(done.id).overrideWith((ref) {
          reads++;
          if (reads == 1) {
            return Stream<TopikSummaryView?>.error(StateError('read'));
          }
          return Stream.value(null);
        }),
      ],
    );

    expect(find.byType(MxErrorState), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text("This attempt isn't here any more"), findsOneWidget);
  });
}
