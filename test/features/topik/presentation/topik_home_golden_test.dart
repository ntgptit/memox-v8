@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/presentation/providers/topik_catalog_provider.dart';
import 'package:memox/features/topik/presentation/screens/topik_home_screen.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

// Screen 34's states (detail file 34).
void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String state,
      List<Override> overrides,
    ) => withRealShadows(() async {
      await pumpLibraryGolden(
        tester,
        env,
        TopikHomeScreen(onOpenLevel: (_) {}),
        brightness,
        overrides: overrides,
      );
      await tester.pump(const Duration(seconds: 1));
      await expectBoundaryGolden(
        tester,
        'goldens/topik_home_${state}_$theme.png',
      );
    });

    libraryTest('loaded, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'loaded',
        topikContentOverrides(topikScreenTests()),
      );
    });

    libraryTest('noTests, $theme', (tester, env) async {
      await shoot(tester, env, 'no_tests', topikContentOverrides(const []));
    });

    libraryTest('loading, $theme', (tester, env) async {
      final pending = StreamController<List<TopikCatalogEntry>>();
      addTearDown(pending.close);
      await shoot(tester, env, 'loading', [
        topikCatalogProvider.overrideWith((ref) => pending.stream),
      ]);
    });

    libraryTest('error, $theme', (tester, env) async {
      await shoot(tester, env, 'error', [
        topikCatalogProvider.overrideWith(
          (ref) => Stream<List<TopikCatalogEntry>>.error(StateError('read')),
        ),
      ]);
    });
  }
}
