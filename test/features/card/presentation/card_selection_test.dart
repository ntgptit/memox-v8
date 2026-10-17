import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/card/presentation/providers/card_list_provider.dart';
import 'package:memox/features/card/presentation/states/card_list_request_state.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/sections/card_list_section_widget.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

Widget _section(String deckId) => Scaffold(
  body: CardListSectionWidget(
    deckId: deckId,
    algorithm: 'Eight boxes',
    onAddCard: () {},
    onOpenCard: (_) {},
    // As the router wires it: the bulk bar holds its five commands.
    onExport: (_) {},
  ),
);

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

/// The checked rows: the selected count lives in the app bar title, which
/// this section-only harness does not build (critique 2026-09-30 part 3b).
final _checked = find.byWidgetPredicate(
  (widget) => widget is MxSelectionCheckbox && widget.isChecked,
);

void main() {
  libraryTest('a long-press selects that card', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(_checked, findsNWidgets(1));
    expect(find.byType(MxSelectionCheckbox), findsNWidgets(2));
    // The front's node is the row's merged node (DEV-304).
    expect(
      tester.getSemantics(find.text('annyeong')),
      isSemantics(isChecked: true),
    );
  });

  libraryTest('a tap toggles; unticking the last one keeps selection', (
    tester,
    env,
  ) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_checked, findsNWidgets(2));

    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_checked, findsNWidgets(1));
    await tester.tap(find.text('annyeong'));
    await tester.pump();
    // DEV-307: selection ends with Close, as in the Trash.
    expect(_checked, findsNothing);
    expect(find.byType(MxSelectionCheckbox), findsNWidgets(2));
    await tester.pump(const Duration(milliseconds: 200));
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

  libraryTest('cards that left the deck leave the selection too, so a bulk '
      'action is not refused for them (audit CARD-14)', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa', 'sarang']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('gamsa'));
    await tester.pump();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(CardListSectionWidget)),
    );
    expect(container.read(cardSelectionProvider(deckId)).ids, hasLength(2));

    // "gamsa" goes to the Trash from elsewhere while it is picked.
    await env.cards.deleteCards(cardIds: {'c01'});
    await tester.pumpAndSettle();

    expect(container.read(cardSelectionProvider(deckId)).ids, {'c00'});
    expect(_checked, findsNWidgets(1));
  });

  for (final isFailed in [false, true]) {
    libraryTest('system Back leaves selection first while the list is '
        '${isFailed ? 'in error' : 'loading'} (audit CARD-14)', (
      tester,
      env,
    ) async {
      final deckId = await _deck(env, ['annyeong']);
      final stream = StreamController<CardListView>();
      addTearDown(stream.close);
      await pumpLibraryScreen(
        tester,
        env,
        _section(deckId),
        overrides: [
          cardListProvider(
            deckId: deckId,
            filter: CardListFilter.all,
            sort: CardListSort.newest,
            searchTerm: '',
            tags: const CardTagFilter(),
            windowSize: cardListWindowStep,
          ).overrideWith((ref) => stream.stream),
        ],
      );
      if (isFailed) stream.addError(StateError('disk I/O error'));
      await tester.pump();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CardListSectionWidget)),
      );
      container.read(cardSelectionProvider(deckId).notifier).start();
      await tester.pump();

      // True: the pop was taken by the selection, not by the screen.
      final handled = await tester
          .state<NavigatorState>(find.byType(Navigator))
          .maybePop();
      await tester.pump();

      expect(handled, isTrue);
      expect(
        container.read(cardSelectionProvider(deckId)).isSelecting,
        isFalse,
      );
    });
  }

  libraryTest('selection meets the target guidelines', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
