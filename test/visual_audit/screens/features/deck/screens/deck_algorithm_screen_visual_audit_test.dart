import 'package:memox/features/deck/presentation/screens/deck_algorithm_screen.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 02, a deck\'s review algorithm', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await auditProductionScreen(
      tester,
      screen: DeckAlgorithmScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        deckAlgorithmScreen(deckId: korean.id),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });
}
