@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/presentation/screens/deck_progress_screen.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/progress_screen_fixtures.dart';

// Screen 22 inside a deck (FE-A9) against the kit's "Inside a deck", with
// the Korean names in Vietnamese; and the two states the kit lacks: a deck
// with no children (A1) and a deck that is gone (E2).

DeckProgressScreen _screen(String deckId) => DeckProgressScreen(
  deckId: deckId,
  onOpenDeck: (_) {},
  onOpenAncestor: (_) {},
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String deckId,
      String name,
    ) => withRealShadows(() async {
      await pumpLibraryGolden(tester, env, _screen(deckId), brightness);
      await expectBoundaryGolden(
        tester,
        'goldens/deck_progress_${name}_$theme.png',
      );
    });

    libraryTest('deck progress, inside a deck, $theme', (tester, env) async {
      final root = await env.decks.root('Tiếng Hàn TOPIK I · Từ vựng');
      Future<void> child(String name, List<StudyDay> days) =>
          studiedSubDeck(env, root.id, root.id, name, days: days);
      await child('Động từ', [
        (daysAgo: 4, learning: 3, reviewing: 5),
        (daysAgo: 1, learning: 2, reviewing: 6),
        (daysAgo: 0, learning: 1, reviewing: 9),
      ]);
      await child('Danh từ', [
        (daysAgo: 3, learning: 2, reviewing: 6),
        (daysAgo: 0, learning: 2, reviewing: 7),
      ]);
      await child('Trạng từ', [(daysAgo: 2, learning: 0, reviewing: 4)]);
      await child('Tính từ', []);
      await shoot(tester, env, root.id, 'deck');
    });

    libraryTest('deck progress, no sub-decks, $theme', (tester, env) async {
      final root = await env.decks.root('Tiếng Hàn TOPIK I · Từ vựng');
      final verbs = await studiedSubDeck(
        env,
        root.id,
        root.id,
        'Động từ',
        days: [(daysAgo: 1, learning: 2, reviewing: 6)],
      );
      await shoot(tester, env, verbs, 'leaf');
    });

    libraryTest('deck progress, gone, $theme', (tester, env) async {
      final root = await env.decks.root('Korean');
      await env.decks.deleteDeck(deckId: root.id);
      await shoot(tester, env, root.id, 'gone');
    });
  }
}
