import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/presentation/states/card_selection_state.dart';
import 'package:memox/features/card/presentation/widgets/items/card_row_widget.dart';
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
    expect(_checked, findsNWidgets(2));

    await tester.tap(find.text('gamsa'));
    await tester.pump();
    expect(_checked, findsNWidgets(1));
    await tester.tap(find.text('annyeong'));
    await tester.pump();
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

  libraryTest('selection meets the target guidelines', (tester, env) async {
    final deckId = await _deck(env, ['annyeong', 'gamsa']);
    await pumpLibraryScreen(tester, env, _section(deckId));
    await tester.longPress(find.text('annyeong'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });

  test('prune drops the ids a bulk action found already gone (SP2a 2.19)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final selection = container.read(cardSelectionProvider('deck').notifier)
      ..selectAll({'a', 'b', 'c'});

    selection.prune({'b', 'unknown'});

    expect(container.read(cardSelectionProvider('deck')), {'a', 'c'});
  });
}
