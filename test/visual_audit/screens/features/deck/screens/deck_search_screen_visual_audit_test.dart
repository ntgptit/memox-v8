import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/presentation/screens/deck_search_screen.dart';

import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  libraryTest('screen 04, a blank search', (tester, env) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await auditProductionScreen(
      tester,
      screen: DeckSearchScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        DeckSearchScreen(onOpenDeck: (_) {}),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 04, a search with hits', (tester, env) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await auditProductionScreen(
      tester,
      screen: DeckSearchScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          DeckSearchScreen(onOpenDeck: (_) {}),
          brightness: brightness,
          textScale: scale,
        );
        await tester.enterText(find.byType(EditableText), 'or');
      },
    );
  });
}
