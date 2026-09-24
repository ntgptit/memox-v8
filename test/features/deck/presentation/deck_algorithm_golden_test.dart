@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('algorithm unlocked, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckAlgorithmScreen(deckId: korean.id),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/library_algorithm_unlocked_$theme.png',
        );
      });
    });

    libraryTest('algorithm locked, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      await lockScheduler(env.db, korean.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckAlgorithmScreen(deckId: korean.id),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/library_algorithm_locked_$theme.png',
        );
      });
    });

    libraryTest('reset dialog, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean', SchedulerType.sm2);
      final words = await env.decks.sub(korean.id, 'Words');
      await insertCard(
        env.db,
        id: 'a',
        deckId: words.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
      await lockScheduler(env.db, korean.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckAlgorithmScreen(deckId: korean.id),
          brightness,
        );
        await tester.tap(find.text(_en.algorithmResetAction));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(
          tester,
          'goldens/library_algorithm_reset_$theme.png',
        );
      });
    });
  }
}
