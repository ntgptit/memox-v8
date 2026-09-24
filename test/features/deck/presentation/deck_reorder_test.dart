import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/deck/presentation/providers/reorder_deck_use_case_provider.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_reorder_row_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// Decks whose every reorder is refused, as when the anchor moved away.
final class _RefusingDecks implements DeckRepository {
  @override
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  }) async => const Rejected(DeckRejection.notSiblings);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<List<String>> _rootOrder(LibraryEnv env) async => [
  for (final row
      in await env.db
          .customSelect(
            'SELECT name FROM deck WHERE parent_id IS NULL '
            'ORDER BY sibling_position',
          )
          .get())
    row.read<String>('name'),
];

/// The deck names in reorder mode, top to bottom.
List<String> _shownOrder(WidgetTester tester) => [
  for (final row in tester.widgetList<DeckReorderRowWidget>(
    find.byType(DeckReorderRowWidget),
  ))
    row.tile.name,
];

/// Drags [name]'s handle down one row, past the next deck.
Future<void> _dragPastNext(WidgetTester tester, String name) async {
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

Future<void> _startReorder(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.libraryReorder));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('Reorder is offered for a manual level of two decks or more', (
    tester,
    env,
  ) async {
    await env.decks.root('A');
    await pumpLibraryScreen(tester, env, deckScreen());
    expect(find.byTooltip(_en.libraryReorder), findsNothing);

    await env.decks.root('B');
    await tester.pump();
    await tester.pump();
    expect(find.byTooltip(_en.libraryReorder), findsOneWidget);

    await tester.tap(find.text(_en.deckSortTrigger(_en.deckSortManual)));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckSortName));
    await tester.pumpAndSettle();
    expect(find.byTooltip(_en.libraryReorder), findsNothing);
  });

  libraryTest('dragging a deck past the next one saves the new order', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B', 'C']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    await _startReorder(tester);

    expect(find.byType(MxFab), findsNothing);
    await _dragPastNext(tester, 'A');

    expect(await _rootOrder(env), ['B', 'A', 'C']);
    expect(_shownOrder(tester), ['B', 'A', 'C']);
  });

  libraryTest('each row offers TalkBack move actions (D7)', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    await _startReorder(tester);
    final handle = tester.ensureSemantics();
    final widgets = WidgetsLocalizations.of(
      tester.element(find.byType(DeckReorderRowWidget).first),
    );

    final labels = <String>{};
    for (
      SemanticsNode? node = tester.getSemantics(find.text('A'));
      node != null;
      node = node.parent
    ) {
      for (final id
          in node.getSemanticsData().customSemanticsActionIds ??
              const <int>[]) {
        labels.add(CustomSemanticsAction.getAction(id)!.label!);
      }
    }
    expect(labels, contains(widgets.reorderItemDown));
    handle.dispose();
  });

  libraryTest('Done ends the mode and brings back the FAB', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen());
    await _startReorder(tester);
    await tester.tap(find.text(_en.libraryReorderDone));
    await tester.pumpAndSettle();

    expect(find.byType(DeckReorderRowWidget), findsNothing);
    expect(find.byType(MxFab), findsOneWidget);
  });

  libraryTest('a refused drop snaps back and says why (RF3)', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B', 'C']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(),
      overrides: [
        reorderDeckUseCaseProvider.overrideWithValue(
          ReorderDeckUseCase(_RefusingDecks()),
        ),
      ],
    );
    await _startReorder(tester);
    await _dragPastNext(tester, 'A');

    expect(_shownOrder(tester), ['A', 'B', 'C']);
    expect(find.text(_en.deckRejectionNotSiblings), findsOneWidget);
  });

  libraryTest('reorder mode meets the target guidelines at 2x', (
    tester,
    env,
  ) async {
    for (final name in ['A', 'B']) {
      await env.decks.root(name);
    }
    await pumpLibraryScreen(tester, env, deckScreen(), textScale: 2);
    await _startReorder(tester);

    expect(tester.takeException(), isNull);
    await expectAccessibleTargets(tester);
  });
}
