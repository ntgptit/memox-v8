@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_add_fab_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

/// A deck of cards in every status, one flagged, shown as its open deck.
/// Romanized fronts: the golden test font has no Hangul glyphs.
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final rows = [
    ('annyeonghaseyo', 'hello', null, 1),
    ('gamsahamnida', 'thank you', DateTime(2026, 9, 24), 2),
    ('sarang', 'love', DateTime(2026, 9, 30), 5),
    ('mul', 'water', DateTime(2026, 12, 1), 8),
  ];
  for (final (index, (front, back, due, box)) in rows.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: words.id,
      front: front,
      back: back,
      learnedAt: due == null ? null : DateTime(2026, 9, 1),
      dueAt: due,
      box: box,
      isFlagged: index == 1,
      createdAt: DateTime(2026, 9, 1 + index),
    );
  }
  return words.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card list, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(
            deckId: deckId,
            cardContent: (view) => CardListSectionWidget(
              deckId: view.deck.id,
              algorithm: 'Eight boxes',
              onAddCard: () {},
              onOpenCard: (_) {},
            ),
            cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {}),
          ),
          brightness,
        );
        await expectBoundaryGolden(tester, 'goldens/card_list_$theme.png');
      });
    });

    libraryTest('card selection, $theme', (tester, env) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          deckScreen(
            deckId: deckId,
            cardContent: (view) => CardListSectionWidget(
              deckId: view.deck.id,
              algorithm: 'Eight boxes',
              onAddCard: () {},
              onOpenCard: (_) {},
            ),
            cardFab: (id) => CardAddFabWidget(deckId: id, onAddCard: () {}),
          ),
          brightness,
        );
        await tester.longPress(find.text('sarang'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(tester, 'goldens/card_selection_$theme.png');
      });
    });
  }
}
