@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean (1 of 6 mastered, learning band), Kanji N5 (1 of 2, reviewing)
/// and Hanja (1 of 1, mastered): one deck per MasteryRamp band.
Future<void> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final kanji = await env.decks.root('Kanji N5');
  final hanja = await env.decks.root('Hanja');
  final words = await env.decks.sub(korean.id, 'Words');
  final radicals = await env.decks.sub(kanji.id, 'Radicals');
  final basics = await env.decks.sub(hanja.id, 'Basics');
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
  await insertCard(env.db, id: 'fresh', deckId: radicals.id);
  for (final (id, deckId) in [
    ('known', words.id),
    ('radical', radicals.id),
    ('hanja', basics.id),
  ]) {
    await insertCard(
      env.db,
      id: id,
      deckId: deckId,
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 30),
      box: 8,
    );
  }
}

void main() {
  for (final brightness in Brightness.values) {
    libraryTest('Library with decks, ${brightness.name}', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
        await expectBoundaryGolden(
          tester,
          'goldens/library_decks_${brightness.name}.png',
        );
      });
    });

    libraryTest('Library sort sheet, ${brightness.name}', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, deckScreen(), brightness);
        await tester.tap(find.text(_en.deckSortManual));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(
          tester,
          'goldens/library_sort_${brightness.name}.png',
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
