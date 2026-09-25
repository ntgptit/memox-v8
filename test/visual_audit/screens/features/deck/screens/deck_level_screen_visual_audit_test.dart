import 'package:memox/features/deck/presentation/screens/deck_level_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 01, the Library root with decks', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 01, an empty Library', (tester, env) async {
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckScreen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 01, an open deck of decks', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckScreen(deckId: korean.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 07, an open deck of cards', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(
      env.db,
      id: 'c1',
      deckId: korean.id,
      front: 'mul',
      back: 'water',
    );
    await insertCard(
      env.db,
      id: 'c2',
      deckId: korean.id,
      front: 'sarang',
      back: 'love',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24),
      isFlagged: true,
    );
    await auditProductionScreen(
      tester,
      screen: DeckLevelScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        cardDeckScreen(korean.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
