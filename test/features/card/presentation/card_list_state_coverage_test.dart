import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/deck_screen_harness.dart';
import '../../../support/forui_expect.dart';
import '../../../support/library_harness.dart';

// The States rows of screen 07 (Card list) whose detail file cites no
// executed test: deckActions and delDeck, the open deck's ⋮ sheet and its
// Move to Trash dialog over a deck of cards.

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words holding two cards.
Future<String> _words(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
  await insertCard(env.db, id: 'c2', deckId: words.id, front: 'bul');
  return words.id;
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(byControlLabel(_en.deckActions));
  await tester.pumpAndSettle();
}

Future<int> _activeDeckCount(LibraryEnv env) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM deck WHERE delete_batch_id IS NULL',
            )
            .getSingle())
        .read<int>('n');

/// [label] inside the open sheet, not the screen behind it.
Finder _inSheet(String label) =>
    find.descendant(of: find.byType(MxBottomSheet), matching: find.text(label));

double _top(WidgetTester tester, String label) =>
    tester.getTopLeft(_inSheet(label)).dy;

void main() {
  libraryTest('deckActions: the ⋮ of a deck of cards lists Study, Rename, '
      'Select cards, Move, Import, Export and Move to Trash in that order', (
    tester,
    env,
  ) async {
    final words = await _words(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(words));
    await _openSheet(tester);

    final labels = [
      _en.studyThisDeck,
      _en.deckRename,
      _en.deckActionSelectCards,
      _en.deckMove,
      _en.deckActionImport,
      _en.deckActionExport,
      _en.deckDelete,
    ];
    for (final label in labels) {
      expect(_inSheet(label), findsOneWidget, reason: label);
    }
    final tops = [for (final label in labels) _top(tester, label)];
    expect(tops, orderedEquals([...tops]..sort()));
    // The deck is open, a sub-deck and holds no deck.
    expect(_inSheet(_en.deckOpen), findsNothing);
    expect(_inSheet(_en.deckReviewAlgorithm), findsNothing);
    expect(_inSheet(_en.deckReorder), findsNothing);
  });

  libraryTest('delDeck: Move to Trash from a deck of cards names the deck and '
      'its cards, moves it once and offers Undo', (tester, env) async {
    final words = await _words(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(words));
    await _openSheet(tester);
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckDeleteTitle), findsOneWidget);
    expect(find.text(_en.deckDeleteSummary('Words', 0, 2)), findsOneWidget);
    expect(find.text(_en.deckDeleteNote), findsOneWidget);

    await tester.tap(find.text(_en.trashMoveConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckTrashedToast('Words', 0, 2)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);
    expect(await _activeDeckCount(env), 1);
  });
}
