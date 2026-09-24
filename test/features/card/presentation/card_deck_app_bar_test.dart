import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_app_bar_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_deck_breadcrumb_widget.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

/// Screen 07's app bar and breadcrumb, composed as `app/` composes them (A14).
final _en = lookupAppLocalizations(const Locale('en'));

Widget _screen(String deckId) => deckScreen(
  deckId: deckId,
  cardContent: (view) => CardListSectionWidget(
    deckId: view.deck.id,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
  ),
  cardAppBar: (view, actions) =>
      CardDeckAppBarWidget(view: view, deckActions: actions),
  cardBreadcrumb: (id, child) =>
      CardDeckBreadcrumbWidget(deckId: id, child: child),
);

/// Korean › Words with [fronts] as new cards.
Future<String> _deck(LibraryEnv env, List<String> fronts) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  for (final (i, front) in fronts.indexed) {
    await insertCard(
      env.db,
      id: 'c${i.toString().padLeft(2, '0')}',
      deckId: words.id,
      front: front,
    );
  }
  return words.id;
}

Finder _barText(String text) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(text));

void main() {
  libraryTest('the deck bar: Back, the name, search, the deck actions', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _screen(deckId));

    expect(find.byTooltip(_en.commonBack), findsOneWidget);
    expect(_barText('Words'), findsOneWidget);
    expect(find.byTooltip(_en.deckActions), findsOneWidget);
    expect(find.byType(MxSearchField), findsNothing);

    await tester.tap(find.byTooltip(_en.cardSearchOpen));
    await tester.pumpAndSettle();
    expect(find.byType(MxSearchField), findsOneWidget);
    expect(find.byTooltip(_en.cardSearchClose), findsOneWidget);
  });

  libraryTest('selecting turns the bar into the selection header (A14)', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa', 'sarang', 'mul']);
    await pumpLibraryScreen(tester, env, _screen(deckId));
    expect(find.byType(MxBreadcrumb), findsOneWidget);

    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(find.byTooltip(_en.cardSelectionClose), findsOneWidget);
    expect(_barText(_en.cardSelectedCount(1)), findsOneWidget);
    expect(
      find.widgetWithText(MxButton, _en.cardSelectAllCount(4)),
      findsOneWidget,
    );
    expect(find.byTooltip(_en.deckActions), findsNothing);
    expect(find.byType(MxBreadcrumb), findsNothing);
  });

  libraryTest('Select all takes every card the term lets through', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, [
      for (var i = 0; i < 60; i++) 'card $i',
      'bap',
    ]);
    await pumpLibraryScreen(tester, env, _screen(deckId));
    await tester.tap(find.byTooltip(_en.cardSearchOpen));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'card');
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, _en.cardSelectAllCount(60)));
    await tester.pumpAndSettle();

    expect(_barText(_en.cardSelectedCount(60)), findsOneWidget);
  });

  libraryTest('Select all honours the filter under the search too', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    for (var i = 0; i < 60; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: words.id,
        front: 'card $i',
        isFlagged: i < 55,
      );
    }
    await insertCard(env.db, id: 'x', deckId: words.id, front: 'bap');
    await pumpLibraryScreen(tester, env, _screen(words.id));
    await tester.tap(find.byTooltip(_en.cardSearchOpen));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'card');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxFilterChip, _en.cardFilterFlagged));
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, _en.cardSelectAllCount(55)));
    await tester.pumpAndSettle();

    expect(_barText(_en.cardSelectedCount(55)), findsOneWidget);
  });

  libraryTest('Close clears the selection; the deck bar returns', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _screen(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(_en.cardSelectionClose));
    await tester.pumpAndSettle();

    expect(_barText('Words'), findsOneWidget);
    expect(find.byTooltip(_en.cardSelectionClose), findsNothing);
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });

  libraryTest('the selecting bar holds at 2x', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _screen(deckId), textScale: 2);
    await tester.scrollUntilVisible(
      find.text('annyeong'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CardListSectionWidget),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
