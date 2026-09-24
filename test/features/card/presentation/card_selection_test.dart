import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Widget _section(String deckId) =>
    Scaffold(body: CardListSectionWidget(deckId: deckId));

/// A deck of cards whose fronts are [fronts]; the first [flagged] are
/// flagged.
Future<String> _deck(
  LibraryEnv env,
  List<String> fronts, {
  int flagged = 0,
}) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  for (final (index, front) in fronts.indexed) {
    await insertCard(
      env.db,
      id: 'c${index.toString().padLeft(2, '0')}',
      deckId: words.id,
      front: front,
      isFlagged: index < flagged,
    );
  }
  return words.id;
}

Finder _header(int count) => find.text(_en.cardSelectedCount(count));

void main() {
  libraryTest('a long-press selects that card', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(_header(1), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNWidgets(2));
    expect(
      tester.getSemantics(find.byType(CardRowWidget).last),
      isSemantics(isChecked: true),
    );
  });

  libraryTest('a tap toggles; the last one off leaves selection', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_header(2), findsOneWidget);

    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_header(1), findsOneWidget);
    await tester.tap(find.text('annyeong'));
    await tester.pump();
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('outside selection a tap does nothing yet (ruling P3-L3)', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.tap(find.text('annyeong'));
    await tester.pump();

    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Select all takes the whole filtered, searched set (RF1)', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, [
      for (var i = 0; i < 60; i++) 'card $i',
    ], flagged: 55);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.enterText(find.byType(EditableText), 'card');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterFlagged));
    await tester.pumpAndSettle();
    expect(find.byType(CardRowWidget), findsNWidgets(cardListWindowStep));

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.cardSelectAll));
    await tester.pumpAndSettle();

    expect(_header(55), findsOneWidget);
  });

  libraryTest('changing the filter clears the selection', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa'], flagged: 1);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterFlagged));
    await tester.pumpAndSettle();

    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('system Back leaves selection first (RF5)', (tester, env) async {
    final deckId = await _deck(env, ['annyeong']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(MxSelectionCheckbox), findsNothing);
    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('selection meets the target guidelines at 2x', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId), textScale: 2);
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
