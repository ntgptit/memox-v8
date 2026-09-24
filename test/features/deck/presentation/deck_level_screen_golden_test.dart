@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

void main() {
  for (final brightness in Brightness.values) {
    libraryTest('Library with decks, ${brightness.name}', (tester, env) async {
      final korean = await env.decks.root('Korean');
      await env.decks.root('Kanji N5');
      await env.decks.root('Hanja');
      final words = await env.decks.sub(korean.id, 'Words');
      for (var i = 0; i < 3; i++) {
        await insertCard(
          env.db,
          id: 'late$i',
          deckId: words.id,
          learnedAt: DateTime(2026, 9, 1),
          dueAt: DateTime(2026, 9, 20),
        );
      }
      await insertCard(
        env.db,
        id: 'today',
        deckId: words.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 24),
      );
      await insertCard(env.db, id: 'new', deckId: words.id);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/library_decks_${brightness.name}.png',
        );
      });
    });

    libraryTest('Library first run, ${brightness.name}', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/library_empty_${brightness.name}.png',
        );
      });
    });
  }
}
