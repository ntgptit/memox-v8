import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/trash_screen_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Finder _button(String label) => find.widgetWithText(MxButton, label);

Finder _inDialog(String text) =>
    find.descendant(of: find.byType(MxDialog), matching: find.text(text));

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Selects the two cards of [seedTrash].
Future<void> _selectCards(WidgetTester tester) async {
  await _tap(tester, _button(_en.trashSelect));
  await _tap(tester, find.text('meokda · eat'));
  await _tap(tester, find.text('homework · bai tap'));
}

void main() {
  libraryTest('Select starts with nothing chosen; the first pick locks the '
      'kind (BR-TRASH-011)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _tap(tester, _button(_en.trashSelect));

    expect(find.text(_en.trashSelectTitle), findsOneWidget);
    expect(find.byType(MxFilterChip), findsNothing);
    final restore = tester.widget<MxButton>(
      _button(_en.trashRestoreSelected(0)),
    );
    expect(restore.onPressed, isNull);

    await _tap(tester, find.text('meokda · eat'));
    expect(find.text(_en.trashCardsSelected(1)), findsOneWidget);
    expect(
      find.text(_en.trashSelectedOfCards(1, 2).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(_en.trashCardsOnly), findsOneWidget);

    // A deck cannot join a selection of cards.
    await _tap(tester, find.text('Basics'));
    expect(find.text(_en.trashCardsSelected(1)), findsOneWidget);

    await _tap(tester, find.byTooltip(_en.trashSelectionClose));
    expect(find.text(_en.libraryTrash), findsOneWidget);
    expect(find.byType(MxFilterChip), findsNWidgets(3));
  });

  libraryTest('a long-press starts the selection with its entry (spec D8)', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await tester.longPress(find.text('Places'));
    await tester.pumpAndSettle();
    expect(find.text(_en.trashDecksSelected(1)), findsOneWidget);
    expect(find.text(_en.trashDecksOnly), findsOneWidget);
  });

  libraryTest('Restore 2… asks one target for both, then ends the selection '
      '(UC-TRASH-001 A2)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);

    await _tap(tester, _button(_en.trashRestoreSelected(2)));
    expect(find.text(_en.trashRestoreCardsTitle(2)), findsOneWidget);
    await _tap(tester, find.text('Korean › Words'));

    expect(find.text(_en.trashRestoredMany(2, 'Words')), findsOneWidget);
    expect(find.text('meokda · eat'), findsNothing);
    expect(find.text(_en.libraryTrash), findsOneWidget);
  });

  libraryTest('Delete for good names the count, focuses Keep in Trash, and '
      'deletes only on its own button (BR-TRASH-011)', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected));

    expect(find.text(_en.trashPurgeCardsTitle(2)), findsOneWidget);
    expect(find.text(_en.trashPurgeBody(2)), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      focused.findAncestorWidgetOfExactType<MxButton>()?.label,
      _en.trashPurgeKeep,
    );

    await _tap(tester, _inDialog(_en.trashPurgeKeep));
    expect(find.text('meokda · eat'), findsOneWidget);

    await _tap(tester, _button(_en.trashPurgeSelected));
    await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(_en.trashPurgedCards(2)), findsOneWidget);
    expect(find.text('meokda · eat'), findsNothing);
    expect(find.text('homework · bai tap'), findsNothing);
  });

  libraryTest('a purge the store skips names what it still holds (spec D6)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final food = await env.decks.sub(korean.id, 'Food');
    await insertCard(
      env.db,
      id: 'rice',
      deckId: food.id,
      front: 'bap',
      back: 'rice',
    );
    // The card goes first, then its deck: the deck holds an older entry.
    await env.cards.deleteCards(
      cardIds: {'rice'},
      now: libraryToday.subtract(const Duration(days: 2)),
    );
    await env.decks.deleteDeck(
      deckId: food.id,
      now: libraryToday.subtract(const Duration(days: 1)),
    );
    await pumpLibraryScreen(tester, env, const TrashScreen());

    await _tap(tester, find.byTooltip(_en.trashEntryActions('Food')));
    await _tap(tester, find.text(_en.trashDeletePermanently));
    expect(find.text(_en.trashPurgeDecksTitle(1)), findsOneWidget);
    await _tap(tester, _inDialog(_en.trashPurgeConfirm(1)));

    expect(find.text('Food'), findsOneWidget);
    expect(find.text(_en.trashPurgedDecks(1)), findsNothing);
    expect(
      find.text(_en.trashPurgeBlocked('Food', 'bap · rice')),
      findsOneWidget,
    );
  });
}
