@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

/// Korean › Words holding a reviewed, flagged card with a two-cycle history.
/// Romanized text: the golden font has no Hangul.
Future<void> _seed(LibraryEnv env) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(
    env.db,
    id: 'c',
    deckId: words.id,
    front: 'gamsahamnida',
    back: 'thank you',
    isFlagged: true,
    learnedAt: DateTime(2026, 8, 20),
    dueAt: DateTime(2026, 9, 26),
    box: 5,
  );
  final answers = [
    (DateTime(2026, 9, 4, 19), 'recall', 4, 5, DateTime(2026, 9, 20)),
    (DateTime(2026, 8, 27, 20), 'fill', 3, 4, DateTime(2026, 9, 4)),
    (DateTime(2026, 8, 23, 18), 'guess', 2, 3, DateTime(2026, 8, 27)),
  ];
  for (final (index, (at, mode, from, to, due)) in answers.indexed) {
    await logReview(
      env.db,
      id: 'g2-$index',
      cardId: 'c',
      at: at,
      generation: 2,
      mode: mode,
      previousBox: from,
      nextBox: to,
      nextDueAt: due,
      usedHint: mode == 'fill' ? true : null,
    );
  }
  await logReview(
    env.db,
    id: 'g1',
    cardId: 'c',
    at: DateTime(2026, 4, 6, 20),
    schedulerType: 'sm2',
    mode: 'self_assess',
    action: 'again',
    previousEase: 2.5,
    nextEase: 2.3,
    previousInterval: 6,
    nextInterval: 1,
  );
}

CardDetailScreen _screen() => CardDetailScreen(
  cardId: 'c',
  deckContext: (deckId, label) =>
      DeckContextHeaderWidget(deckId: deckId, currentLabel: label),
  onEdit: (_) {},
);

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('card detail, top, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_detail_top_$theme.png',
        );
      });
    });

    libraryTest('card detail, history, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
        await tester.pumpAndSettle();
        await expectBoundaryGolden(
          tester,
          'goldens/card_detail_history_$theme.png',
        );
      });
    });
  }
}
