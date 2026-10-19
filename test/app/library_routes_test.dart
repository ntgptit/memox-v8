import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';

import '../support/card_fixtures.dart';
import '../support/deck_fixtures.dart';
import '../support/library_harness.dart';
import '../support/app_harness.dart';
import '../support/widget_harness.dart';
import '../support/forui_expect.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _crumb(String label) =>
    find.descendant(of: find.byType(MxBreadcrumb), matching: find.text(label));

Future<void> _back(WidgetTester tester) =>
    tapAndSettle(tester, byControlLabel(_en.commonBack));

/// Korean › Words › Verbs, with Grammar beside Words.
Future<void> _seed(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  await env.decks.sub(korean.id, 'Grammar');
  await env.decks.sub(words.id, 'Verbs');
}

Future<void> _openWords(WidgetTester tester) async {
  await tapAndSettle(tester, find.text('Korean'));
  await tapAndSettle(tester, find.text('Words'));
}

Future<void> _openVerbs(WidgetTester tester) async {
  await _openWords(tester);
  await tapAndSettle(tester, find.text('Verbs'));
}

void main() {
  libraryTest('each level is one page; Back climbs one level', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    expect(barTitle('Verbs'), findsOneWidget);

    for (final level in ['Words', 'Korean', _en.navLibrary]) {
      await _back(tester);
      expect(barTitle(level), findsOneWidget);
    }
  });

  libraryTest('a crumb pops back to its level (ruling P2-L5)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await tapAndSettle(tester, _crumb('Korean'));

    expect(barTitle('Korean'), findsOneWidget);
    await _back(tester);
    expect(barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('the Library crumb returns to the root', (tester, env) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await tapAndSettle(tester, _crumb(_en.navLibrary));

    expect(barTitle(_en.navLibrary), findsOneWidget);
    expect(byControlLabel(_en.commonBack), findsNothing);
  });

  libraryTest('from search, a crumb off the stack opens over the root', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, find.byType(MxSearchField));
    await tester.enterText(find.byType(EditableText), 'verb');
    await tester.pump(searchDebounce);
    await tester.pumpAndSettle();
    await tapAndSettle(tester, find.text('Verbs'));
    expect(barTitle('Verbs'), findsOneWidget);

    await tapAndSettle(tester, _crumb('Korean'));
    expect(barTitle('Korean'), findsOneWidget);
    await _back(tester);
    expect(barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('deleting the open deck returns to its parent once (RF1)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await tapAndSettle(tester, byControlLabel(_en.deckActions));
    await tapAndSettle(tester, find.text(_en.deckDelete));
    await tapAndSettle(tester, find.text(_en.trashMoveConfirm));

    expect(barTitle('Words'), findsOneWidget);
    // The toast with Undo survives the step back (FE-B1 D3).
    expect(find.text(_en.deckTrashedToast('Verbs', 0, 0)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);
  });

  libraryTest('Review algorithm pushes screen 02; Back returns to the deck', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, find.text('Korean'));
    await tapAndSettle(tester, byControlLabel(_en.deckActions));
    await tapAndSettle(tester, find.text(_en.deckReviewAlgorithm));

    expect(find.text(_en.algorithmHeader.toUpperCase()), findsOneWidget);
    await _back(tester);
    expect(barTitle('Korean'), findsOneWidget);
  });

  libraryTest('moving the open deck updates its path at once (RF5)', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await tapAndSettle(tester, find.text('Korean'));
    await tapAndSettle(tester, find.text('Grammar'));
    await tapAndSettle(tester, byControlLabel(_en.deckActions));
    await tapAndSettle(tester, find.text(_en.deckMove));
    await tapAndSettle(tester, find.text('Korean › Words'));

    expect(_crumb('Words'), findsOneWidget);
    await _back(tester);
    expect(barTitle('Korean'), findsOneWidget);
    expect(find.text('Grammar'), findsNothing);
  });

  libraryTest('re-tapping the Library tab returns to the root', (
    tester,
    env,
  ) async {
    await _seed(env);
    await pumpMemoxApp(tester, env);
    await _openVerbs(tester);
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(MxBottomNav),
        matching: find.text(_en.navLibrary),
      ),
    );

    expect(barTitle(_en.navLibrary), findsOneWidget);
  });

  libraryTest('a deck of cards lists its cards', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpMemoxApp(tester, env);
    await _openWords(tester);

    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('Back leaves selection first, then the deck (RF5)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new1', deckId: words.id, front: 'annyeong');
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(barTitle('Words'), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(barTitle('Korean'), findsOneWidget);
  });

  libraryTest('New card opens the editor; cards are added one after another', (
    tester,
    env,
  ) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await tapAndSettle(tester, find.widgetWithText(MxButton, _en.deckNewCard));
    expect(barTitle(_en.cardAddTitle), findsOneWidget);

    for (final (front, back) in [('bap', 'rice'), ('mul', 'water')]) {
      await tester.enterText(find.byType(EditableText).at(0), front);
      await tester.enterText(find.byType(EditableText).at(1), back);
      await tester.pump();
      await tapAndSettle(
        tester,
        find.widgetWithText(MxButton, _en.cardSaveCard),
      );
      // The toast floats over the footer's Save until it times out.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    }
    await tapAndSettle(tester, byControlLabel(_en.cardClose));

    expect(barTitle('Words'), findsOneWidget);
    expect(find.text('bap'), findsOneWidget);
    expect(find.text('mul'), findsOneWidget);
  });

  libraryTest(
    'Import covers the shell; Close returns to the deck (IT-NAV-012)',
    (tester, env) async {
      await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
      await pumpMemoxApp(tester, env);
      await _openWords(tester);
      await tapVisible(
        tester,
        find.widgetWithText(MxButton, _en.deckUnsetImport),
      );
      await tester.pumpAndSettle();

      expect(barTitle(_en.importTitle), findsOneWidget);
      expect(find.byType(MxBottomNav), findsNothing);

      await tapAndSettle(tester, byControlLabel(_en.importClose));
      expect(barTitle('Words'), findsOneWidget);
      expect(find.byType(MxBottomNav), findsOneWidget);
    },
  );

  libraryTest(
    'Export opens its sheet from the deck and from a selection (UC-TRANSFER-002)',
    (tester, env) async {
      final words = await env.decks.sub(
        (await env.decks.root('Korean')).id,
        'Words',
      );
      await insertCard(env.db, id: 'a', deckId: words.id, front: 'bap');
      await insertCard(env.db, id: 'b', deckId: words.id, front: 'mul');
      await pumpMemoxApp(tester, env);
      await _openWords(tester);

      await tapAndSettle(tester, byControlLabel(_en.deckActions));
      await tapAndSettle(tester, find.text(_en.deckActionExport));
      expect(find.text(_en.exportTitleDeck(2)), findsOneWidget);
      await tapAndSettle(
        tester,
        find.widgetWithText(MxButton, _en.commonCancel),
      );

      await tester.longPress(find.text('bap'));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, find.text(_en.cardExport));
      expect(find.text(_en.exportTitleSelection(1)), findsOneWidget);
      await tapAndSettle(
        tester,
        find.widgetWithText(MxButton, _en.commonCancel),
      );
      expect(barTitle(_en.cardSelectedCount(1)), findsOneWidget);
    },
  );

  libraryTest('Close on a typed card asks; Discard leaves (RF2)', (
    tester,
    env,
  ) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await tapAndSettle(tester, find.widgetWithText(MxButton, _en.deckNewCard));
    await tester.enterText(find.byType(EditableText).at(0), 'bap');
    await tester.pump();
    await tapAndSettle(tester, byControlLabel(_en.cardClose));
    expect(find.text(_en.cardDiscardNewTitle), findsOneWidget);

    await tapAndSettle(tester, find.text(_en.cardDiscard));
    expect(barTitle('Words'), findsOneWidget);
    expect(find.text(_en.deckUnsetTitle), findsOneWidget);
  });

  libraryTest('a card deck searches from its bar; closing shows every card', (
    tester,
    env,
  ) async {
    final words = await env.decks.sub(
      (await env.decks.root('Korean')).id,
      'Words',
    );
    await insertCard(env.db, id: 'c0', deckId: words.id, front: 'bap');
    await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
    await pumpMemoxApp(tester, env);
    await _openWords(tester);

    await tapAndSettle(tester, byControlLabel(_en.cardSearchOpen));
    await tester.enterText(find.byType(EditableText), 'bap');
    await tester.pumpAndSettle();
    expect(find.byType(CardRowWidget), findsOneWidget);

    await tapAndSettle(tester, byControlLabel(_en.cardSearchClose));
    expect(find.byType(EditableText), findsNothing);
    expect(find.byType(CardRowWidget), findsNWidgets(2));
  });

  libraryTest('a row opens its card; Back returns to the list as it was', (
    tester,
    env,
  ) async {
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
    await insertCard(
      env.db,
      id: 'c1',
      deckId: words.id,
      front: 'mul',
      back: 'water',
    );
    await pumpMemoxApp(tester, env);
    await _openWords(tester);
    await tapAndSettle(tester, byControlLabel(_en.cardSearchOpen));
    await tester.enterText(find.byType(EditableText), 'bap');
    await tester.pumpAndSettle();
    await tapAndSettle(
      tester,
      find.descendant(
        of: find.byType(CardRowWidget),
        matching: find.text('bap'),
      ),
    );
    expect(barTitle(_en.cardDetailTitle), findsOneWidget);

    await _back(tester);
    expect(barTitle('Words'), findsOneWidget);
    expect(find.byType(CardRowWidget), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'bap',
    );
  });

  libraryTest('Edit from the detail saves and returns to it (UC-CARD-002 A1)', (
    tester,
    env,
  ) async {
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
    await _openWords(tester);
    await tapAndSettle(tester, find.text('bap'));
    await tapAndSettle(
      tester,
      find.widgetWithText(MxButton, _en.cardEditAction),
    );
    expect(barTitle(_en.cardEditTitle), findsOneWidget);

    await tester.enterText(find.byType(EditableText).at(1), 'cooked rice');
    await tester.pump();
    await tapAndSettle(
      tester,
      find.widgetWithText(MxButton, _en.cardSaveChanges),
    );

    expect(barTitle(_en.cardDetailTitle), findsOneWidget);
    expect(find.text('cooked rice'), findsOneWidget);
  });

  libraryTest('a card trashed elsewhere while it is edited: Back to deck '
      'returns to the deck, past its detail (audit 2026-10-17)', (
    tester,
    env,
  ) async {
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
    await _openWords(tester);
    await tapAndSettle(tester, find.text('bap'));
    await tapAndSettle(
      tester,
      find.widgetWithText(MxButton, _en.cardEditAction),
    );
    expect(barTitle(_en.cardEditTitle), findsOneWidget);

    await env.cards.deleteCards(cardIds: {'c0'});
    await tester.pumpAndSettle();
    expect(find.text(_en.cardGoneTitle), findsOneWidget);
    await tapAndSettle(
      tester,
      find.widgetWithText(MxButton, _en.cardBackToDeck),
    );

    expect(find.text(_en.cardGoneTitle), findsNothing);
    expect(barTitle(_en.cardDetailTitle), findsNothing);
    expect(barTitle('Words'), findsOneWidget);
  });
}
