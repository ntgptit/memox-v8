import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _path = ['Korean', 'Words', 'Verbs'];

Finder _crumb(String label) =>
    find.descendant(of: find.byType(MxBreadcrumb), matching: find.text(label));

Finder _unsetButton(String label) => find.widgetWithText(MxButton, label);

Finder _barTitle(String title) =>
    find.descendant(of: find.byType(MxAppBar), matching: find.text(title));

/// A root and one deck per level below it, down to [depth].
Future<List<DeckEntity>> _chain(
  LibraryEnv env,
  int depth,
  String Function(int level) name,
) async {
  final decks = [await env.decks.root(name(1))];
  for (var level = 2; level <= depth; level++) {
    decks.add(await env.decks.sub(decks.last.id, name(level)));
  }
  return decks;
}

void main() {
  libraryTest('an open deck names itself and shows its path', (
    tester,
    env,
  ) async {
    final chain = await _chain(env, 3, (level) => _path[level - 1]);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: chain.last.id));

    expect(_barTitle('Verbs'), findsOneWidget);
    for (final label in [_en.navLibrary, ..._path]) {
      expect(_crumb(label), findsOneWidget);
    }
  });

  libraryTest('a breadcrumb tap reports that level, the root as null', (
    tester,
    env,
  ) async {
    final chain = await _chain(env, 3, (level) => _path[level - 1]);
    final levels = <String?>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain.last.id, onOpenAncestor: levels.add),
    );
    await tester.tap(_crumb('Korean'));
    await tester.tap(_crumb(_en.navLibrary));

    expect(levels, [chain.first.id, null]);
  });

  libraryTest('a deck of decks lists its sub-decks; a row opens its deck', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new', deckId: words.id);
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onOpenDeck: opened.add),
    );

    // Rows carry no workload line on screen 01; Task 7's summary card
    // brings the level's counts back.
    expect(find.byType(DeckRowWidget), findsOneWidget);
    expect(find.byType(MxListSectionHeader), findsOneWidget);
    await tester.tap(find.text('Words'));
    expect(opened, [words.id]);
  });

  libraryTest('an empty sub-deck offers a card or a sub-deck (P4a-L9)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final added = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: words.id, onAddCard: added.add),
    );

    expect(find.text(_en.deckUnsetTitle), findsOneWidget);
    expect(find.text(_en.deckUnsetNote), findsOneWidget);
    await tester.tap(_unsetButton(_en.deckNewCard));
    expect(added, [words.id]);

    await tester.tap(_unsetButton(_en.deckNewSubDeck));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Verbs');
    await tester.tap(find.text(_en.deckCreateConfirm));
    await tester.pumpAndSettle();

    expect(find.byType(MxDialog), findsNothing);
    expect(find.text('Verbs'), findsOneWidget);
  });

  libraryTest('a top-level deck offers sub-decks only (BR-DECK-005)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    expect(find.text(_en.deckRootEmptyTitle), findsOneWidget);
    expect(_unsetButton(_en.deckNewCard), findsNothing);
    expect(_unsetButton(_en.deckNewSubDeck), findsOneWidget);
    expect(find.text(_en.deckUnsetNote), findsNothing);
  });

  libraryTest('the FAB opens the new sub-deck dialog', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await tester.tap(find.byType(MxFab));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.text(_en.deckCreateSubTitle),
      ),
      findsOneWidget,
    );
  });

  libraryTest('the deepest deck offers a card only', (tester, env) async {
    final chain = await _chain(
      env,
      DeckEntity.maxDepth,
      (level) => 'Level $level',
    );
    final added = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain.last.id, onAddCard: added.add),
    );

    expect(find.byType(MxFab), findsNothing);
    expect(find.text(_en.deckUnsetDeepestBody), findsOneWidget);
    expect(_unsetButton(_en.deckNewSubDeck), findsNothing);
    await tester.tap(_unsetButton(_en.deckNewCard));
    expect(added, [chain.last.id]);
  });

  libraryTest('a deck of cards takes its FAB from the card feature', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'new', deckId: words.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: words.id, cardFab: (deckId) => Text('fab of $deckId')),
    );

    expect(_barTitle('Words'), findsOneWidget);
    expect(find.byType(MxListSectionHeader), findsNothing);
    expect(find.text('fab of ${words.id}'), findsOneWidget);
  });

  libraryTest('a deck deleted while open says it is no longer here (A8)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    String? ancestor = 'unset';
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: words.id, onOpenAncestor: (id) => ancestor = id),
    );

    await env.decks.deleteDeck(deckId: words.id);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    expect(find.text(_en.deckDeletedToast), findsNothing);
    final trash = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.deckOpenTrash),
    );
    expect(trash.onPressed, isNull);
    await tester.tap(find.text(_en.deckBackToLibrary));
    expect(ancestor, isNull);
  });

  libraryTest('a deck of decks leads with its summary; Study is disabled', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(korean.id, 'Grammar');
    await insertCard(
      env.db,
      id: 'late',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 22),
    );
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    expect(find.byType(DeckSummaryCardWidget), findsOneWidget);
    expect(
      find.text(_en.deckRowMeta(_en.deckSubDeckCount(2), _en.deckCardCount(1))),
      findsOneWidget,
    );
    final study = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.deckStudyThisDue(1)),
    );
    expect(study.onPressed, isNull);
    expect(find.text(_en.deckSubDeckCount(2).toUpperCase()), findsOneWidget);
  });

  libraryTest('the summary counts every sub-deck under the due filter', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(korean.id, 'Grammar');
    await insertCard(
      env.db,
      id: 'late',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 22),
    );
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    await tester.tap(find.text(_en.deckSortManual));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MxToggle));
    await tester.tap(find.text(_en.commonDone));
    await tester.pumpAndSettle();

    expect(
      find.text(_en.deckRowMeta(_en.deckSubDeckCount(2), _en.deckCardCount(1))),
      findsOneWidget,
    );
    expect(find.text(_en.libraryDueDecksHeader.toUpperCase()), findsOneWidget);
    expect(find.text('Grammar'), findsNothing);
  });

  libraryTest('sub-decks at the deepest level name it in the header (C-O6)', (
    tester,
    env,
  ) async {
    final chain = await _chain(env, DeckEntity.maxDepth, (level) => 'L$level');
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain[DeckEntity.maxDepth - 2].id),
    );

    expect(find.text(_en.deckDepthHeader(1).toUpperCase()), findsOneWidget);
  });

  libraryTest('a 10-level path at 2x keeps the current level in view (RF4)', (
    tester,
    env,
  ) async {
    final chain = await _chain(
      env,
      DeckEntity.maxDepth,
      (level) => 'Từ vựng tiếng Hàn cấp $level',
    );
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: chain.last.id),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final current = _crumb('Từ vựng tiếng Hàn cấp ${DeckEntity.maxDepth}');
    expect(tester.getRect(current).right, lessThanOrEqualTo(360));
  });

  libraryTest('an open deck meets the target guidelines', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    await expectAccessibleTargets(tester);
  });
}
