@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// A deck of cards in every status and every due kind, two flagged, tags on
/// two, shown as its open deck (screen 07). Romanized fronts: the golden
/// test font has no Hangul glyphs.
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final rows = [
    ('annyeonghaseyo', 'hello', null, 1, false),
    ('gamsahamnida', 'thank you', DateTime(2026, 9, 20), 2, true),
    ('sarang', 'love', DateTime(2026, 9, 24), 5, false),
    ('gada', 'to go', DateTime(2026, 9, 27), 3, false),
    ('mul', 'water', DateTime(2026, 12, 1), 8, true),
  ];
  for (final (index, (front, back, due, box, isFlagged)) in rows.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: words.id,
      front: front,
      back: back,
      learnedAt: due == null ? null : DateTime(2026, 9, 1),
      dueAt: due,
      box: box,
      isFlagged: isFlagged,
      createdAt: DateTime(2026, 9, 10 - index),
    );
  }
  final tags = TagRepositoryImpl(env.db);
  for (final name in ['greeting', 'TOPIK I', 'basics']) {
    await tags.attachByName(cardIds: {'c0'}, name: name);
  }
  await tags.attachByName(cardIds: {'c2'}, name: 'noun');
  return words.id;
}

/// A deck of cards whose only card was deleted: the deck keeps its content
/// type and shows the empty state.
Future<String> _seedEmpty(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(env.db, id: 'gone', deckId: words.id, deleteBatchId: 'b');
  return words.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> pump(WidgetTester tester, LibraryEnv env, String deckId) =>
        pumpLibraryGolden(
          tester,
          env,
          cardDeckScreen(deckId: deckId),
          brightness,
        );

    libraryTest('card list, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await expectBoundaryGolden(tester, 'goldens/card_list_$theme.png');
      });
    });

    libraryTest('card selection, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await tester.longPress(find.text('sarang'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('gada'));
        await tester.pump();
        // Past the ink's fade, so the selected card shows its own fill.
        await tester.pump(const Duration(seconds: 1));
        await expectBoundaryGolden(tester, 'goldens/card_selection_$theme.png');
      });
    });

    libraryTest('card list search with no hit, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await tester.tap(find.byTooltip(_en.cardOpenSearch));
        await tester.pump();
        await tester.enterText(find.byType(EditableText), 'bap');
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump();
        await expectBoundaryGolden(
          tester,
          'goldens/card_list_search_$theme.png',
        );
      });
    });

    libraryTest('card list empty, $theme', (tester, env) async {
      final deckId = await _seedEmpty(env);
      await withRealShadows(() async {
        await pump(tester, env, deckId);
        await expectBoundaryGolden(
          tester,
          'goldens/card_list_empty_$theme.png',
        );
      });
    });
  }
}
