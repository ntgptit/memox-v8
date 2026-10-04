import 'package:flutter/material.dart';
import 'package:memox/features/card/presentation/screens/card_detail_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

void main() {
  libraryTest('screen 10, a learned card', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(
      env.db,
      id: 'c',
      deckId: korean.id,
      front: 'mul',
      back: 'water',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 26),
      box: 3,
    );
    await auditProductionScreen(
      tester,
      screen: CardDetailScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        CardDetailScreen(cardId: 'c', deckContext: _context, onEdit: (_) {}),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
