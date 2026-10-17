@Tags(['golden'])
library;

import '../../../support/forui_expect.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_summary_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_summary_screen.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_attempt_screen_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

/// Every third question wrong, every fifth blank, the rest right.
Map<int, int> _mixed(TopikTest test) => {
  for (final (i, q) in test.questions.indexed)
    if (i % 5 != 4) q.no: i % 3 == 2 ? q.answerIdx % 4 + 1 : q.answerIdx,
};

// Screen 38's states (detail file 38).
void main() {
  final reading = topikTestFixture();
  final t1 = topikTestFixture(level: TopikLevel.topik1);

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      String attemptId, {
      List<TopikTest>? catalog,
      List<Override> overrides = const [],
      Future<void> Function()? before,
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikSummaryScreen(
          attemptId: attemptId,
          onReview: (_) {},
          onDone: () {},
        ),
        brightness,
        overrides: [
          ...topikContentOverrides(catalog ?? [reading, t1]),
          ...overrides,
        ],
      );
      await tester.pump(const Duration(seconds: 1));
      if (before != null) {
        await before();
        await tester.pumpAndSettle();
      }
      await expectBoundaryGolden(
        tester,
        'goldens/topik_summary_${state}_$theme.png',
      );
    });

    libraryTest('loaded, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: _mixed(reading),
      );
      await shoot(tester, env, 'loaded', done.id);
    });

    // Scrolled to the time chart, so its legend is pinned (wireframe pass).
    libraryTest('chart, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: _mixed(reading),
      );
      await shoot(
        tester,
        env,
        'chart',
        done.id,
        // The chart's header near the top: the bars and the legend in full.
        before: () => Scrollable.ensureVisible(
          tester.element(find.byType(MxChartLegend)),
          alignment: 0.5,
        ),
      );
    });

    libraryTest('perfect, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: {for (final q in reading.questions) q.no: q.answerIdx},
      );
      await shoot(tester, env, 'perfect', done.id);
    });

    libraryTest('zero, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(env, reading);
      await shoot(tester, env, 'zero', done.id);
    });

    libraryTest('topik1Reading, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(env, t1, answers: _mixed(t1));
      await shoot(tester, env, 't1_reading', done.id);
    });

    libraryTest('correctHidden, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: _mixed(reading),
      );
      await shoot(
        tester,
        env,
        'hidden',
        done.id,
        before: () async {
          await tester.tap(byControlLabel('Hide answers'));
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.text('Question 1'),
            300,
            scrollable: find.byType(Scrollable).first,
          );
        },
      );
    });

    libraryTest('filterEmpty, $theme', (tester, env) async {
      final done = await topikSeedSubmitted(
        env,
        reading,
        answers: {for (final q in reading.questions) q.no: q.answerIdx},
      );
      await shoot(
        tester,
        env,
        'filter_empty',
        done.id,
        // The chip, not the chart legend's "Wrong".
        before: () => tester.tap(find.widgetWithText(MxFilterChip, 'Wrong')),
      );
    });

    libraryTest('attemptMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', 'gone');
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikSummaryView?>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        'a1',
        overrides: [
          topikSummaryProvider('a1').overrideWith((ref) => pending.stream),
        ],
      );
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        'a1',
        overrides: [
          topikSummaryProvider('a1').overrideWith(
            (ref) => Stream<TopikSummaryView?>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
