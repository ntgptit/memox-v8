@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_test_detail_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_detail_screen.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 36's states (detail file 36).
void main() {
  final test = topikTestFixture();

  /// Three completed attempts four, three and two days ago, then one in
  /// progress started two hours ago.
  Future<void> seedHistory(LibraryEnv env) async {
    for (final (day, correct) in [(0, 22), (1, 31), (2, 38)]) {
      await topikSeedCompleted(
        env,
        test,
        startedAt: libraryToday.subtract(Duration(days: 4 - day)),
        correct: correct,
        elapsedMs: 2400000 + day * 300000,
      );
    }
    await topikSeedInProgress(
      env,
      test,
      startedAt: libraryToday.subtract(const Duration(hours: 2)),
    );
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state, {
      String? testId,
      List<Override>? overrides,
      Future<void> Function()? before,
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikTestDetailScreen(
          testId: testId ?? test.testId,
          onOpenAttempt: (_) {},
          onOpenSummary: (_) {},
          onOpenReview: (_) {},
          onBackToTests: () {},
        ),
        brightness,
        overrides: overrides ?? topikContentOverrides([test]),
      );
      await tester.pump(const Duration(seconds: 1));
      if (before != null) {
        await before();
        await tester.pumpAndSettle();
      }
      await expectBoundaryGolden(
        tester,
        'goldens/topik_detail_${state}_$theme.png',
      );
    });

    Future<void> openHistory(WidgetTester tester) =>
        tester.tap(find.text('History'));

    libraryTest('overview, $theme', (tester, env) async {
      await seedHistory(env);
      await shoot(tester, env, 'overview');
    });

    libraryTest('overviewEmpty, $theme', (tester, env) async {
      await shoot(tester, env, 'overview_empty');
    });

    libraryTest('history, $theme', (tester, env) async {
      await seedHistory(env);
      await shoot(tester, env, 'history', before: () => openHistory(tester));
    });

    libraryTest('historyEmpty, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'history_empty',
        before: () => openHistory(tester),
      );
    });

    libraryTest('deleteConfirm, $theme', (tester, env) async {
      await seedHistory(env);
      await shoot(
        tester,
        env,
        'delete',
        before: () async {
          await openHistory(tester);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byTooltip(RegExp(r'^Delete attempt \d+$')).first,
          );
        },
      );
    });

    libraryTest('continueOrNew, $theme', (tester, env) async {
      await seedHistory(env);
      await shoot(
        tester,
        env,
        'continue',
        before: () => tester.tap(find.byType(MxFab)),
      );
    });

    libraryTest('testMissing, $theme', (tester, env) async {
      await shoot(tester, env, 'missing', testId: 'topik2-1-reading');
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<TopikTestDetail>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        overrides: [
          topikTestDetailProvider(test.testId)
              .overrideWith((ref) => pending.stream),
        ],
      );
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        overrides: [
          topikTestDetailProvider(test.testId).overrideWith(
            (ref) => Stream<TopikTestDetail>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
