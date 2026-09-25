import 'package:flutter/material.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_context_header_widget.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

Widget _context(String deckId, String label) =>
    DeckContextHeaderWidget(deckId: deckId, currentLabel: label);

void main() {
  libraryTest('screen 08, a new card', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await auditProductionScreen(
      tester,
      screen: CardEditorScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        CardEditorScreen.create(deckId: korean.id, deckContext: _context),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 09, an existing card', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(
      env.db,
      id: 'c',
      deckId: korean.id,
      front: 'mul',
      back: 'water',
    );
    await auditProductionScreen(
      tester,
      screen: CardEditorScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        const CardEditorScreen.edit(cardId: 'c', deckContext: _context),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
