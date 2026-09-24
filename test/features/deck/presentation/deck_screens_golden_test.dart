@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › {Words (3 overdue, 1 today, 1 new), Grammar}; Words › Verbs.
Future<({String korean, String words})> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await env.decks.sub(korean.id, 'Grammar');
  final verbs = await env.decks.sub(words.id, 'Verbs');
  for (var i = 0; i < 3; i++) {
    await insertCard(
      env.db,
      id: 'late$i',
      deckId: verbs.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
  }
  await insertCard(
    env.db,
    id: 'today',
    deckId: verbs.id,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: DateTime(2026, 9, 24),
  );
  await insertCard(env.db, id: 'new', deckId: verbs.id);
  return (korean: korean.id, words: words.id);
}

Future<void> _settleOverlay(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('open deck, $theme', (tester, env) async {
      final ids = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.korean),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_open_$theme.png',
        );
      });
    });

    libraryTest('empty deck, $theme', (tester, env) async {
      final korean = await env.decks.root('Korean');
      final words = await env.decks.sub(korean.id, 'Words');
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: words.id),
          brightness,
        );
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_unset_$theme.png',
        );
      });
    });

    libraryTest('reorder mode, $theme', (tester, env) async {
      for (final name in ['Korean', 'Kanji N5', 'Hanja']) {
        await env.decks.root(name);
      }
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
        // Reorder starts from a row's sheet (ruling C-L4).
        await tester.tap(
          find
              .byTooltip(RegExp('^${RegExp.escape(_en.deckMoreActions(''))}'))
              .first,
        );
        await _settleOverlay(tester);
        await tester.tap(find.text(_en.deckReorder));
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_reorder_$theme.png',
        );
      });
    });

    libraryTest('deck actions, $theme', (tester, env) async {
      final ids = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.words),
          brightness,
        );
        await tester.tap(find.byTooltip(_en.deckActions));
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_actions_$theme.png',
        );
      });
    });

    libraryTest('delete dialog, $theme', (tester, env) async {
      final ids = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(deckId: ids.words),
          brightness,
        );
        await tester.tap(find.byTooltip(_en.deckActions));
        await _settleOverlay(tester);
        await tester.tap(find.text(_en.deckDelete));
        await _settleOverlay(tester);
        await expectBoundaryGolden(
          tester,
          'goldens/library_deck_delete_$theme.png',
        );
      });
    });

    libraryTest('search results, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          DeckSearchScreen(onOpenDeck: (_) {}),
          brightness,
        );
        await tester.enterText(find.byType(EditableText), 'or');
        await _settleOverlay(tester);
        await expectBoundaryGolden(tester, 'goldens/library_search_$theme.png');
      });
    });
  }
}
