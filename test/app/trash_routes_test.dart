import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_editor_form_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Korean › Words with the cards bap and gim.
Future<String> _seed(LibraryEnv env) async {
  final words = await env.decks.sub(
    (await env.decks.root('Korean')).id,
    'Words',
  );
  await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap');
  await insertCard(env.db, id: 'c1', deckId: words.id, front: 'gim');
  return words.id;
}

Future<void> _openWords(WidgetTester tester) async {
  await _tap(tester, find.text('Korean'));
  await _tap(tester, find.text('Words'));
}

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

/// The Trash is on screen, above the shell (FE-B1 D2).
void _expectTrash() {
  expect(_barTitle(_en.libraryTrash), findsOneWidget);
  expect(find.byType(MxBottomNav), findsNothing);
}

/// The routes around the Trash (FE-B1).
void main() {
  libraryTest('the Library’s Trash opens screen 06 above the shell; Back '
      'returns (FE-B1 D1, D2)', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);

    await _tap(tester, find.byTooltip(_en.libraryTrash));
    _expectTrash();
    expect(find.text(_en.trashEmptyTitle), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.commonBack));
    expect(_barTitle(_en.navLibrary), findsOneWidget);
    expect(find.byType(MxBottomNav), findsOneWidget);
  });

  libraryTest('the toast of several cards opens the Trash (FE-B1 D4)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await tester.longPress(find.text('bap'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text('gim'));
    await _tap(tester, find.text(_en.cardDelete));
    await _tap(tester, _inDialog(_en.cardMoveToTrash));

    expect(find.text(_en.cardsTrashedToast(2)), findsOneWidget);
    await _tap(tester, find.text(_en.commonOpenTrash));
    _expectTrash();
    expect(find.text(_en.trashEntriesHeader(2).toUpperCase()), findsOneWidget);
  });

  libraryTest('a refused Undo opens the Trash (UC-TRASH-001 E3)', (
    tester,
    env,
  ) async {
    final words = await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await tester.longPress(find.text('bap'));
    await tester.pumpAndSettle();
    await _tap(tester, find.text(_en.cardDelete));
    await _tap(tester, _inDialog(_en.cardMoveToTrash));
    // Meanwhile its deck goes to the Trash as well.
    await env.decks.deleteDeck(deckId: words);
    await tester.pumpAndSettle();

    await _tap(tester, find.text(_en.commonUndo));
    expect(
      find.text(_en.cardUndoRefused(_en.cardRejectionTargetInTrash)),
      findsOneWidget,
    );
    // The toast's, not the gone deck's behind it.
    await _tap(
      tester,
      find.descendant(
        of: find.byType(SnackBar),
        matching: find.text(_en.commonOpenTrash),
      ),
    );
    _expectTrash();
  });

  libraryTest('a card detail whose card went to the Trash leads there (FE-B1 '
      'D11)', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await _tap(tester, find.text('bap'));
    await env.cards.deleteCards(cardIds: {'c0'});
    await tester.pumpAndSettle();

    expect(find.text(_en.cardDetailGoneBody), findsOneWidget);
    await _tap(tester, find.text(_en.commonOpenTrash));
    _expectTrash();
  });

  libraryTest('an open deck gone to the Trash leads there (FE-B1 D11)', (
    tester,
    env,
  ) async {
    final words = await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await env.decks.deleteDeck(deckId: words);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckGoneBody), findsOneWidget);
    await _tap(tester, find.text(_en.commonOpenTrash));
    _expectTrash();
  });

  libraryTest('Move to Trash from the editor returns to the card list with '
      'Undo (FE-B1 D13)', (tester, env) async {
    final words = await env.decks.sub(
      (await env.decks.root('Korean')).id,
      'Words',
    );
    await insertCard(
      env.db,
      id: 'c0',
      deckId: words.id,
      front: 'bap',
      back: 'rice',
    );
    await pumpMemoxApp(tester, env);
    await _tap(tester, find.text('Korean'));
    await _tap(tester, find.text('Words'));
    await _tap(tester, find.text('bap'));
    await _tap(tester, find.widgetWithText(MxButton, _en.cardEditAction));
    // An unsaved edit goes with the card: no discard prompt (P6).
    await tester.enterText(find.byType(EditableText).at(1), 'cooked rice');
    await tester.pump();
    // The More card is the editor's last block (kit 09).
    await tester.drag(
      find.byType(CardEditorFormWidget),
      const Offset(0, -2000),
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.widgetWithText(MxButton, _en.cardMoveToTrash));
    expect(find.text(_en.cardDeleteTitle(1)), findsOneWidget);
    await _tap(
      tester,
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.cardMoveToTrash),
      ),
    );

    expect(find.text(_en.cardDiscardTitle), findsNothing);
    expect(_barTitle('Words'), findsOneWidget);
    expect(find.text(_en.cardTrashedToast('bap')), findsOneWidget);
    await _tap(tester, find.text(_en.commonUndo));
    expect(find.text('bap'), findsOneWidget);
  });
}
