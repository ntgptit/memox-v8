import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

LibrarySearchScreen _screen() =>
    LibrarySearchScreen(onOpenDeck: (_) {}, onOpenCard: (_) {});

void main() {
  libraryTest('screen 04, a blank search', (tester, env) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await auditProductionScreen(
      tester,
      screen: LibrarySearchScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        _screen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 04, decks and cards', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'c', deckId: words.id, front: 'word');
    await auditProductionScreen(
      tester,
      screen: LibrarySearchScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          _screen(),
          brightness: brightness,
          textScale: scale,
        );
        await tester.enterText(find.byType(EditableText), 'or');
        await tester.pump(searchDebounce);
        await tester.pump();
      },
    );
  });
}
