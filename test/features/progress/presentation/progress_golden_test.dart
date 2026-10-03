@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/presentation/providers/progress_provider.dart';
import 'package:memox/features/progress/presentation/providers/watch_progress_use_case_provider.dart';
import 'package:memox/features/progress/presentation/screens/progress_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 (FE-A9) against the kit's frames, at the library level: its
// decks with Latin and Vietnamese names (goldens render no Hangul).

final _en = lookupAppLocalizations(const Locale('en'));

ProgressScreen _screen() =>
    ProgressScreen(onOpenDeck: (_) {}, onStartStudying: () {});

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name, {
      List<Override> overrides = const [],
      Future<void> Function()? before,
    }) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: overrides,
        );
        await before?.call();
        await expectBoundaryGolden(
          tester,
          'goldens/progress_${name}_$theme.png',
        );
      });
    }

    libraryTest('progress, last 7 days, $theme', (tester, env) async {
      await progressLibrary(env);
      await shoot(tester, env, 'week');
    });

    libraryTest('progress, last 30 days, the list, $theme', (
      tester,
      env,
    ) async {
      await progressLibrary(env);
      await shoot(
        tester,
        env,
        'month',
        before: () async {
          await tester.tap(find.text(_en.progressRangeMonth));
          await tester.pump();
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -900),
          );
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    });

    libraryTest('progress, streak held, $theme', (tester, env) async {
      await progressLibrary(env, today: false);
      await shoot(tester, env, 'held');
    });

    libraryTest('progress, streak lost, $theme', (tester, env) async {
      await progressLibrary(env, lastDaysAgo: 2);
      await shoot(tester, env, 'lost');
    });

    libraryTest('progress, never studied, $theme', (tester, env) async {
      await studiedDeck(env, 'Tiếng Hàn TOPIK I · Từ vựng');
      await studiedDeck(env, 'IELTS Academic Word List');
      await studiedDeck(env, 'Tiếng Anh giao tiếp hằng ngày');
      await shoot(tester, env, 'never');
    });

    libraryTest('progress, a quiet week, $theme', (tester, env) async {
      await studiedDeck(
        env,
        'Korean Basics',
        days: [(daysAgo: 20, learning: 0, reviewing: 10)],
      );
      await studiedDeck(env, 'IT');
      await shoot(
        tester,
        env,
        'quiet',
        before: () async {
          await tester.drag(
            find.byType(Scrollable).first,
            const Offset(0, -900),
          );
          await tester.pump(const Duration(milliseconds: 300));
        },
      );
    });

    libraryTest('progress, no decks, $theme', (tester, env) async {
      await shoot(tester, env, 'no_decks');
    });

    libraryTest('progress, loading, $theme', (tester, env) async {
      final never = StreamController<Progress>();
      addTearDown(never.close);
      await shoot(
        tester,
        env,
        'loading',
        overrides: [progressProvider.overrideWith((ref) => never.stream)],
      );
    });

    libraryTest('progress, error, $theme', (tester, env) async {
      await shoot(
        tester,
        env,
        'error',
        overrides: [
          progressProvider.overrideWith(
            (ref) => Stream<Progress>.error(StateError('read failed')),
          ),
        ],
      );
    });

    libraryTest('progress, stale after a failed refresh, $theme', (
      tester,
      env,
    ) async {
      await progressLibrary(env);
      await shoot(
        tester,
        env,
        'stale',
        overrides: [
          progressProvider.overrideWith(
            (ref) => snapshotThenError(
              ref,
              ref.watch(watchProgressUseCaseProvider)(),
            ),
          ),
        ],
      );
    });
  }
}
