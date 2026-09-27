@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';
import 'package:memox/features/study/presentation/screens/study_entry_screen.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

StudyEntryScreen _entry(String deckId) => StudyEntryScreen(
  deckId: deckId,
  deckContext: (id, label) =>
      DeckContextHeaderWidget(deckId: id, currentLabel: label),
  onBackToLibrary: () {},
  onSessionReady: (_) {},
);

/// Korean › Words: two new cards and three due.
Future<String> _words(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final words = await env.decks.sub(root.id, 'Words');
  await insertCard(env.db, id: 'n1', deckId: words.id);
  await insertCard(env.db, id: 'n2', deckId: words.id);
  for (final (id, day) in [('d1', 20), ('d2', 22), ('d3', 24)]) {
    await insertCard(
      env.db,
      id: id,
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, day),
    );
  }
  return words.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('study entry, sessions coming soon, $theme', (
      tester,
      env,
    ) async {
      final deckId = await _words(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _entry(deckId), brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_entry_gated_$theme.png',
        );
      });
    });

    libraryTest('study entry, nothing to do, $theme', (tester, env) async {
      final root = await env.decks.root('Korean');
      final words = await env.decks.sub(root.id, 'Words');
      await insertCard(
        env.db,
        id: 'c1',
        deckId: words.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _entry(words.id), brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_entry_nothing_$theme.png',
        );
      });
    });

    libraryTest('study entry, session to continue, $theme', (
      tester,
      env,
    ) async {
      final ids = await seedBrowseSession(
        env.db,
        env.decks,
        startedAt: libraryToday,
      );
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _entry(ids.deckId), brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/study_entry_resume_$theme.png',
        );
      });
    });
  }
}
