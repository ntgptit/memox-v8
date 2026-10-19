import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import 'forui_expect.dart';

final _en = lookupAppLocalizations(const Locale('en'));

// Reorder mode of the Library root, driven the way a person does: the row's
// action sheet, then the drag handle.

/// The deck names in reorder mode, top to bottom.
List<String> shownOrder(WidgetTester tester) => [
  for (final row in tester.widgetList<DeckReorderRowWidget>(
    find.byType(DeckReorderRowWidget),
  ))
    row.tile.name,
];

/// Drags [name]'s handle down one row, past the next deck.
Future<void> dragPastNext(WidgetTester tester, String name) async {
  final row = find.widgetWithText(DeckReorderRowWidget, name);
  final handle = find.descendant(
    of: row,
    matching: find.byIcon(AppIcons.dragHandle),
  );
  final step = tester.getSize(row).height * 0.5;
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await tester.pump();
  await gesture.moveBy(Offset(0, step));
  await tester.pump();
  await gesture.moveBy(Offset(0, step));
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Reorder starts from a row's action sheet (ruling C-L4).
Finder get anyRowMore =>
    byControlLabel(RegExp('^${RegExp.escape(_en.deckMoreActions(''))}')).first;

Future<void> openRowSheet(WidgetTester tester) async {
  await tester.tap(anyRowMore);
  await tester.pumpAndSettle();
}

Future<void> startReorder(WidgetTester tester) async {
  await openRowSheet(tester);
  await tester.tap(find.text(_en.deckReorder));
  await tester.pumpAndSettle();
}
