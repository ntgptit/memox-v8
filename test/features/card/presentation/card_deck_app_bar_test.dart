import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Korean › Words with three cards.
Future<String> _cardDeck(LibraryEnv env) async {
  final korean = await env.decks.root('Korean');
  final words = await env.decks.sub(korean.id, 'Words');
  for (final (id, front) in [('a', 'mul'), ('b', 'sarang'), ('c', 'gamsa')]) {
    await insertCard(env.db, id: id, deckId: words.id, front: front);
  }
  return words.id;
}

Finder _inBar(Finder finder) =>
    find.descendant(of: find.byType(MxAppBar), matching: finder);

void main() {
  libraryTest('the deck bar offers search; the field opens on demand (E-O3)', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();

    expect(find.byType(MxSearchField), findsNothing);
    expect(_inBar(find.byTooltip(_en.deckActions)), findsOneWidget);
    await tester.tap(_inBar(find.byTooltip(_en.cardOpenSearch)));
    await tester.pumpAndSettle();

    expect(find.byType(MxSearchField), findsOneWidget);
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });

  libraryTest('closing the search clears the term', (tester, env) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();
    await tester.tap(_inBar(find.byTooltip(_en.cardOpenSearch)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(find.byType(CardRowWidget), findsNothing);

    await tester.tap(_inBar(find.byTooltip(_en.cardCloseSearch)));
    await tester.pumpAndSettle();

    expect(find.byType(MxSearchField), findsNothing);
    expect(find.byType(CardRowWidget), findsNWidgets(3));
  });

  libraryTest('selecting swaps the bar: close, count, Select all; the '
      'breadcrumb steps aside (E-O1)', (tester, env) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();

    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    expect(_inBar(find.text(_en.cardSelectedCount(1))), findsOneWidget);
    expect(_inBar(find.byTooltip(_en.cardSelectionClose)), findsOneWidget);
    expect(find.byType(MxBreadcrumb), findsNothing);
    await tester.tap(_inBar(find.text(_en.cardSelectAllCount(3))));
    await tester.pumpAndSettle();
    expect(_inBar(find.text(_en.cardSelectedCount(3))), findsOneWidget);

    await tester.tap(_inBar(find.byTooltip(_en.cardSelectionClose)));
    await tester.pumpAndSettle();
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });

  libraryTest('Back leaves selection, then the deck', (tester, env) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(tester, env, cardDeckScreen(deckId: deckId));
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text(_en.cardSelectedCount(1)), findsNothing);
    expect(find.byType(MxBreadcrumb), findsOneWidget);
  });

  libraryTest('the selection bar at 2x on a 360 phone does not overflow', (
    tester,
    env,
  ) async {
    final deckId = await _cardDeck(env);
    await pumpLibraryScreen(
      tester,
      env,
      cardDeckScreen(deckId: deckId),
      textScale: 2,
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.byType(CardRowWidget).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
