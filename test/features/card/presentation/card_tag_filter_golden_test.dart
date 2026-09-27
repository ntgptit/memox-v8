@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

// Screen 07's tag filter (FE-B2 spec D3, D14), which the kit does not draw:
// the sheet with none, one and several tags chosen, the list it filters,
// and a filter with no card (A7). Romanized fronts: the golden test font
// has no Hangul glyphs.

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words with four cards, tagged verb, noun and greeting; travel
/// is on no card of the deck.
Future<String> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  final other = await env.decks.sub(korean.id, 'Other');
  final rows = [
    ('annyeonghaseyo', 'hello'),
    ('gamsahamnida', 'thank you'),
    ('mul', 'water'),
    ('sarang', 'love'),
  ];
  for (final (index, (front, back)) in rows.indexed) {
    await insertCard(
      env.db,
      id: 'c$index',
      deckId: words.id,
      front: front,
      back: back,
      createdAt: DateTime(2026, 9, 1 + index),
    );
  }
  await insertCard(env.db, id: 'o', deckId: other.id, front: 'yeohaeng');
  final tags = TagRepositoryImpl(env.db);
  await tags.attachByName(cardIds: {'c0', 'c1'}, name: 'greeting');
  await tags.attachByName(cardIds: {'c1', 'c3'}, name: 'verb');
  await tags.attachByName(cardIds: {'c2'}, name: 'noun');
  await tags.attachByName(cardIds: {'o'}, name: 'travel');
  return words.id;
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    Future<void> shoot(
      WidgetTester tester,
      LibraryEnv env,
      String name,
      Future<void> Function() before,
    ) async {
      final deckId = await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          cardDeckScreen(deckId),
          brightness,
        );
        await before();
        await expectBoundaryGolden(
          tester,
          'goldens/card_tag_filter_${name}_$theme.png',
        );
      });
    }

    Future<void> openSheet(WidgetTester tester) async {
      await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterTags));
      await tester.pumpAndSettle();
    }

    Future<void> choose(WidgetTester tester, List<String> names) async {
      for (final name in names) {
        await tester.tap(find.text(name).last);
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    libraryTest('tag filter, none chosen, $theme', (tester, env) async {
      await shoot(tester, env, 'none', () => openSheet(tester));
    });

    libraryTest('tag filter, one chosen, $theme', (tester, env) async {
      await shoot(tester, env, 'one', () async {
        await openSheet(tester);
        await choose(tester, ['verb']);
      });
    });

    libraryTest('tag filter, several chosen, $theme', (tester, env) async {
      await shoot(tester, env, 'several', () async {
        await openSheet(tester);
        await choose(tester, ['verb', 'noun']);
      });
    });

    libraryTest('tag filter, applied, $theme', (tester, env) async {
      await shoot(tester, env, 'applied', () async {
        await openSheet(tester);
        await choose(tester, ['verb', 'noun']);
        await tester.tap(find.text(_en.cardTagFilterApply));
        await tester.pumpAndSettle();
      });
    });

    libraryTest('tag filter, no card (A7), $theme', (tester, env) async {
      await shoot(tester, env, 'no_card', () async {
        await openSheet(tester);
        await choose(tester, ['travel']);
        await tester.tap(find.text(_en.cardTagFilterApply));
        await tester.pumpAndSettle();
      });
    });
  }
}
