@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_test_list_screen.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_screen_fixtures.dart';

TopikTest _topik2Reading(List<TopikTest> tests, int round) => tests.firstWhere(
  (t) =>
      t.level == TopikLevel.topik2 &&
      t.section == TopikSection.reading &&
      t.round == round,
);

// Screen 35's states (detail file 35).
void main() {
  final tests = topikScreenTests();

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state, {
      TopikLevel level = TopikLevel.topik2,
      List<Override>? overrides,
      Future<void> Function()? before,
    }) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikTestListScreen(level: level, onOpenTest: (_) {}),
        brightness,
        overrides: overrides ?? topikContentOverrides(tests),
      );
      await tester.pump(const Duration(seconds: 1));
      if (before != null) {
        await before();
        await tester.pumpAndSettle();
      }
      await expectBoundaryGolden(
        tester,
        'goldens/topik_list_${state}_$theme.png',
      );
    });

    libraryTest('reading, $theme', (tester, env) async {
      await shoot(tester, env, 'reading');
    });

    libraryTest('listening, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'listening',
        before: () => tester.tap(find.text('Listening')),
      );
    });

    libraryTest('withStatus, $theme', (tester, env) async {
      final round96 = _topik2Reading(tests, 96);
      final round91 = _topik2Reading(tests, 91);
      await topikSeedCompleted(
        env,
        round96,
        startedAt: libraryToday,
        correct: 41,
      );
      await topikSeedInProgress(
        env,
        round96,
        startedAt: libraryToday.add(const Duration(hours: 1)),
      );
      await topikSeedCompleted(
        env,
        round91,
        startedAt: libraryToday,
        correct: 30,
      );
      await topikSeedCompleted(
        env,
        round91,
        startedAt: libraryToday.add(const Duration(hours: 2)),
        correct: 35,
      );
      await shoot(tester, env, 'status');
    });

    libraryTest('sortSheet, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'sort',
        before: () => tester.tap(find.byType(MxChipTrigger)),
      );
    });

    libraryTest('empty, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'empty',
        level: TopikLevel.topik1,
        overrides: topikContentOverrides([topikTestFixture()]),
      );
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<List<TopikCatalogEntry>>();
      addTearDown(pending.close);
      await shoot(
        tester,
        env,
        'loading',
        overrides: [topikCatalogProvider.overrideWith((ref) => pending.stream)],
      );
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        overrides: [
          topikCatalogProvider.overrideWith(
            (ref) => Stream<List<TopikCatalogEntry>>.error(StateError('read')),
          ),
        ],
      );
    });
  }
}
