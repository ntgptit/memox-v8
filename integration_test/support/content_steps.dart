import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memox/features/card/presentation/screens/card_editor_screen.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import 'device_app.dart';

// Library steps through the UI, as a person takes them (FE-D3 spec D9). The
// finders mirror the widget tests: create_root_deck_dialog_widget_test.dart,
// open_deck_screen_test.dart, card_editor_screen_test.dart and
// card_bulk_actions_test.dart.

/// The route the app shows, e.g. `/decks/deck/<id>`, pushed routes too.
String currentPath(WidgetTester tester) {
  final configuration = GoRouter.of(tester.element(find.byType(Scaffold).first))
      .routerDelegate
      .currentConfiguration;
  final top = configuration.isEmpty ? null : configuration.last;
  return (top is ImperativeRouteMatch ? top.matches.uri : configuration.uri)
      .path;
}

Finder _editorFinder(int index) => find
    .descendant(
      of: find.byType(CardEditorScreen),
      matching: find.byType(EditableText),
    )
    .at(index);

EditableText _editorField(WidgetTester tester, int index) =>
    tester.widget<EditableText>(_editorFinder(index));

/// Focuses the card editor's [index]th field (0 front, 1 back), types
/// [text], and checks it took.
Future<void> typeInto(WidgetTester tester, int index, String text) async {
  final field = _editorFinder(index);
  await tester.tap(field);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 300));
  expect(_editorField(tester, index).controller.text, text);
}

Future<void> _typeName(WidgetTester tester, String name) async {
  await waitFor(tester, find.byType(EditableText));
  await tester.enterText(find.byType(EditableText).last, name);
  await tester.pump();
}

/// From the Library root: Create deck, a name, Eight boxes or SM-2, Create.
Future<void> createRootDeck(
  WidgetTester tester,
  String name, {
  bool isSm2 = false,
}) async {
  final l10n = l10nOf(tester);
  // The empty Library's button, or the FAB once decks exist.
  final create = await waitForAny(tester, [
    find.text(l10n.libraryCreateDeck),
    find.byType(MxFab),
  ]);
  await tester.tap(create.last);
  await tester.pump(const Duration(milliseconds: 300));
  await _typeName(tester, name);
  await tapText(
    tester,
    isSm2 ? l10n.deckSchedulerSm2 : l10n.deckSchedulerEightBox,
  );
  await tapText(tester, l10n.deckCreateConfirm);
  // A tap while the dialog closes lands on its barrier.
  await waitGone(tester, find.byType(MxDialog));
  await waitFor(tester, find.text(name));
}

/// Opens the deck named [name] from the level on screen.
Future<void> openDeck(WidgetTester tester, String name) async {
  final from = currentPath(tester);
  await tapText(tester, name);
  await waitUntil(
    tester,
    () => currentPath(tester) != from,
    '$name opens (from $from)',
  );
}

/// In the open deck: a new sub-deck named [name], from the empty deck's
/// "New sub-deck" or a deck of decks' "Create sub-deck" FAB.
Future<void> createSubDeck(WidgetTester tester, String name) async {
  final l10n = l10nOf(tester);
  final action = await waitForAny(tester, [
    find.text(l10n.deckNewSubDeck),
    find.byType(MxFab),
  ]);
  await tester.tap(action.last);
  await tester.pump(const Duration(milliseconds: 300));
  await _typeName(tester, name);
  await tapText(tester, l10n.deckCreateConfirm);
  // A tap while the dialog closes lands on its barrier.
  await waitGone(tester, find.byType(MxDialog));
  await waitFor(tester, find.text(name));
}

/// In the open deck: a new card with [front] and [back].
Future<void> createCard(WidgetTester tester, String front, String back) async {
  final l10n = l10nOf(tester);
  await tapText(tester, l10n.deckNewCard);
  await waitFor(tester, find.byType(CardEditorScreen));
  await typeInto(tester, 0, front);
  await typeInto(tester, 1, back);
  await tapText(tester, l10n.cardSaveCard);
  // The new-card editor stays open for the next card: a saved card empties
  // the form, then Close returns to the list.
  await waitUntil(
    tester,
    () => _editorField(tester, 0).controller.text.isEmpty,
    'the saved card empties the form',
  );
  await tester.tap(find.byTooltip(l10n.cardClose));
  await waitGone(tester, find.byType(CardEditorScreen));
  await waitFor(tester, find.text(front));
}

/// Opens the card [front] from its list, then its editor.
Future<void> _editCard(WidgetTester tester, String front) async {
  final l10n = l10nOf(tester);
  await tapText(tester, front);
  await tapText(tester, l10n.cardEditAction);
  await waitFor(tester, find.byType(CardEditorScreen));
}

/// Saves the open editor, then returns from the card's detail to its list.
Future<void> _saveAndReturn(WidgetTester tester) async {
  final l10n = l10nOf(tester);
  await tapText(tester, l10n.cardSaveChanges);
  await waitGone(tester, find.text(l10n.cardSaveChanges));
  await tester.tap(find.byTooltip(l10n.commonBack).first);
  await tester.pump(const Duration(milliseconds: 500));
}

/// Changes the meaning of the card [front] to [back].
Future<void> editCardBack(
  WidgetTester tester,
  String front,
  String back,
) async {
  await _editCard(tester, front);
  await typeInto(tester, 1, back);
  await _saveAndReturn(tester);
  await waitFor(tester, find.text(back));
}

/// Flags the card [front] in its editor.
Future<void> flagCard(WidgetTester tester, String front) async {
  final l10n = l10nOf(tester);
  await _editCard(tester, front);
  await tester.tap(find.byTooltip(l10n.cardFlagLabel));
  await tester.pump();
  await _saveAndReturn(tester);
}

/// Selects the card [front] by a long press and moves it to the Trash.
Future<void> deleteCard(WidgetTester tester, String front) async {
  final l10n = l10nOf(tester);
  await waitFor(tester, find.text(front));
  await tester.longPress(find.text(front));
  await tester.pump(const Duration(milliseconds: 500));
  await tapText(tester, l10n.cardDelete);
  await tapText(tester, l10n.cardMoveToTrash);
  await waitGone(tester, find.text(front));
}

/// Back to the Library root from any deck level: the Library tab, again.
Future<void> goToLibraryRoot(WidgetTester tester) async {
  final l10n = l10nOf(tester);
  await tester.tap(find.text(l10n.navLibrary).last);
  await tester.pump(const Duration(milliseconds: 500));
}
