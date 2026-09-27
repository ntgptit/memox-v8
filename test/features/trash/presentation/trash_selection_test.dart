import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/presentation/providers/purge_expired_trash_use_case_provider.dart';
import 'package:memox/features/trash/presentation/screens/trash_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';
import 'package:memox/features/trash/presentation/widgets/items/trash_entry_row_widget.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_card.dart';

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
    expect(find.text(_en.trashKindLock), findsOneWidget);

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
    expect(find.text(_en.trashKindLock), findsOneWidget);
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
    await _tap(tester, _button(_en.trashPurgeSelected(2)));

    expect(find.text(_en.trashPurgeCardsTitle(2)), findsOneWidget);
    expect(find.text(_en.trashPurgeBody(2)), findsOneWidget);
    final focused = FocusManager.instance.primaryFocus!.context!;
    expect(
      focused.findAncestorWidgetOfExactType<MxButton>()?.label,
      _en.trashPurgeKeep,
    );

    await _tap(tester, _inDialog(_en.trashPurgeKeep));
    expect(find.text('meokda · eat'), findsOneWidget);

    await _tap(tester, _button(_en.trashPurgeSelected(2)));
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

  libraryTest('a picked entry that leaves the Trash leaves every count', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    expect(find.text(_en.trashCardsSelected(2)), findsOneWidget);

    // "homework" expires while it is picked; the resume purge takes it.
    env.clock.current = libraryToday.add(const Duration(hours: 2));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(TrashScreen)),
    );
    await container.read(purgeExpiredTrashUseCaseProvider)();
    await tester.pumpAndSettle();

    expect(find.text('homework · bai tap'), findsNothing);
    expect(find.text(_en.trashCardsSelected(1)), findsOneWidget);
    expect(
      find.text(_en.trashSelectedOfCards(1, 1).toUpperCase()),
      findsOneWidget,
    );
    expect(_button(_en.trashRestoreSelected(1)), findsOneWidget);
  });

  libraryTest('while the purge runs, Keep in Trash and Back wait for it; '
      'nothing is deleted behind a closed dialog', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected(2)));
    await tester.tap(_inDialog(_en.trashPurgeConfirm(2)));
    await tester.pump();

    final keep = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.trashPurgeKeep),
    );
    expect(keep.onPressed, isNull);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(MxDialog), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text(_en.trashPurgedCards(2)), findsOneWidget);
  });

  libraryTest('the selection bar is one MxActionPair, Restore 13 : Delete 10', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);

    final pair = tester.widget<MxActionPair>(find.byType(MxActionPair));
    expect(pair.leadingFlex, 13);
    expect(pair.trailingFlex, 10);
    expect(pair.leading!.isSingleLine, isTrue);
    expect(pair.trailing.isSingleLine, isTrue);
  });

  libraryTest('the purge dialog footer is one MxActionPair, Keep autofocused', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);
    await _tap(tester, _button(_en.trashPurgeSelected(2)));

    final pair = tester.widget<MxActionPair>(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.byType(MxActionPair),
      ),
    );
    expect(pair.leading!.label, _en.trashPurgeKeep);
    expect(pair.leading!.isAutofocused, isTrue);
  });

  libraryTest('while selecting, each checkbox is centred on its row', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _tap(tester, _button(_en.trashSelect));

    final rows = find.byType(TrashEntryRowWidget);
    expect(rows, findsWidgets);
    for (var i = 0; i < tester.widgetList(rows).length; i++) {
      final row = rows.at(i);
      final box = tester.getRect(
        find.descendant(of: row, matching: find.byType(MxSelectionCheckbox)),
      );
      final card = tester.getRect(
        find.descendant(of: row, matching: find.byType(MxCard)),
      );
      expect(box.center.dy, closeTo(card.center.dy, 0.5));
    }
  });

  libraryTest('the bar reads Restore (2) and Delete (2), side by side', (
    tester,
    env,
  ) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);

    final restore = tester.getRect(_button(_en.trashRestoreSelected(2)));
    final purge = tester.getRect(_button(_en.trashPurgeSelected(2)));
    expect(restore.top, purge.top);
  });

  libraryTest('while selecting, the retention note hides and one line says '
      'why the other kind waits', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);

    expect(find.text(_en.trashNote), findsNothing);
    expect(find.text(_en.trashKindLock), findsOneWidget);
  });

  libraryTest('while cards are selected, a deck row is dimmed and a card row '
      'is not', (tester, env) async {
    await seedTrash(env);
    await pumpLibraryScreen(tester, env, const TrashScreen());
    await _selectCards(tester);

    double opacityOf(String name) {
      final row = find.ancestor(
        of: find.text(name),
        matching: find.byType(TrashEntryRowWidget),
      );
      final dims = tester.widgetList<Opacity>(
        find.descendant(of: row, matching: find.byType(Opacity)),
      );
      return dims.fold(1, (value, dim) => value * dim.opacity);
    }

    expect(opacityOf('Basics'), closeTo(0.38, 0.001));
    expect(opacityOf('meokda · eat'), 1);
  });
}
