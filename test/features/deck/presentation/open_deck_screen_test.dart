import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/widgets/items/deck_row_widget.dart';
import 'package:memox/features/deck/presentation/widgets/sections/deck_summary_card_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_fab.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';
import 'package:memox/shared/widgets/mx_toggle.dart';
import 'package:memox/shared/widgets/mx_workload_breakdown_line.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../shared/expect_one_primary.dart';
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
    // M3-D5: the actions are the empty state's own block buttons.
    expect(find.byType(OverflowBar), findsNothing);
    final buttons = tester
        .widgetList<MxButton>(
          find.descendant(
            of: find.byType(MxEmptyState),
            matching: find.byType(MxButton),
          ),
        )
        .toList();
    expect(buttons, isNotEmpty);
    expect(buttons.every((b) => b.isBlock), isTrue);
    expect(buttons.first.label, _en.deckNewCard);
    // Its empty state offers both; no FAB beside it (ruling R9, critique
    // 2026-09-30 part 1).
    expect(find.byType(MxFab), findsNothing);
    expectOnePrimaryPerDecision(tester);
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

  libraryTest('an empty sub-deck imports cards from a file (UC-TRANSFER-001)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final imported = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: words.id, onImportCards: imported.add),
    );

    await tester.ensureVisible(_unsetButton(_en.deckUnsetImport));
    await tester.tap(_unsetButton(_en.deckUnsetImport));
    expect(imported, [words.id]);
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
    // A deck of sub-decks keeps the FAB; an unset one has none (R9).
    await env.decks.sub(korean.id, 'Words');
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

  libraryTest('deleting the last card turns the deck into its unset state', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'only', deckId: words.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    expect(find.text(_en.deckUnsetTitle), findsNothing);

    // Ruling E-L1 (BR-DECK-015): no empty card list, the unset state.
    await env.cards.deleteCards(cardIds: {'only'});
    await tester.pumpAndSettle();

    expect(find.text(_en.deckUnsetTitle), findsOneWidget);
  });

  libraryTest('a deck deleted while open says it is no longer here and leads '
      'back or to the Trash (A8, FE-B1 D11)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    String? ancestor = 'unset';
    var trashOpened = 0;
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(
        deckId: words.id,
        onOpenAncestor: (id) => ancestor = id,
        onOpenTrash: () => trashOpened++,
      ),
    );

    await env.decks.deleteDeck(deckId: words.id);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckGoneTitle), findsOneWidget);
    // A gone item reads in the neutral tone (owner 2026-10-08).
    expect(
      tester.widget<MxEmptyState>(find.byType(MxEmptyState)).tone,
      MxEmptyStateTone.neutral,
    );
    expect(find.byType(SnackBar), findsNothing);
    expect(find.byType(MxButton), findsNWidgets(2));
    await tester.tap(find.text(_en.commonOpenTrash));
    expect(trashOpened, 1);
    await tester.tap(find.text(_en.deckBackToLibrary));
    expect(ancestor, isNull);
  });

  libraryTest('a deck of decks leads with its summary and its Study (FE-A6 '
      'D10)', (tester, env) async {
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
    final studied = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onOpenStudy: studied.add),
    );

    expect(find.byType(DeckSummaryCardWidget), findsOneWidget);
    expect(
      find.text(_en.deckRowMeta(_en.deckSubDeckCount(2), _en.deckCardCount(1))),
      findsOneWidget,
    );
    // The summary card states the count; the header names the list
    // (critique 2026-09-30 part 3b).
    expect(find.text(_en.deckSubDecksHeader.toUpperCase()), findsOneWidget);
    expect(find.text(_en.deckSubDeckCount(2).toUpperCase()), findsNothing);
    // The breakdown wraps between whole terms, never "…" (Wrap Rule).
    final breakdown = tester.widget<Text>(
      find
          .descendant(
            of: find.descendant(
              of: find.byType(DeckSummaryCardWidget),
              matching: find.byType(MxWorkloadBreakdownLine),
            ),
            matching: find.byType(Text),
          )
          .first,
    );
    expect(breakdown.maxLines, isNull);
    expect(breakdown.overflow, isNot(TextOverflow.ellipsis));
    await tester.tap(find.widgetWithText(MxButton, _en.studyThisDeckDue(1)));
    expect(studied, [korean.id]);
  });

  libraryTest('the scheduled count is a whole term of the breakdown: it '
      'wraps before "1 scheduled", never inside it (Wrap Rule; critique '
      '2026-09-30 part 3b)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'late',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 22),
    );
    await insertCard(
      env.db,
      id: 'later',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 12, 1),
    );
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    final line = tester.widget<Text>(
      find
          .descendant(
            of: find.descendant(
              of: find.byType(DeckSummaryCardWidget),
              matching: find.byType(MxWorkloadBreakdownLine),
            ),
            matching: find.byType(Text),
          )
          .first,
    );
    expect(line.textSpan!.toPlainText(), contains('1\u00A0scheduled'));
  });

  libraryTest('the summary shows the level mastery donut beside "Mastered · '
      '{algorithm}" (BR-DECK-026)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(korean.id, 'Grammar');
    await insertCard(
      env.db,
      id: 'known',
      deckId: words.id,
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 30),
      box: 8,
    );
    await insertCard(env.db, id: 'fresh', deckId: words.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));

    final donut = tester.widget<MxMasteryDonut>(find.byType(MxMasteryDonut));
    expect(donut.fraction, 0.5);
    final overline = _en.deckSummaryMastered(_en.deckSchedulerEightBox);
    expect(find.text(overline.toUpperCase()), findsOneWidget);
    // An eyebrow (critique 2026-09-30 part 2, P2).
    expect(
      tester.widget<Text>(find.text(overline.toUpperCase())).style,
      tester.element(find.text(overline.toUpperCase())).textStyles.eyebrow,
    );
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

  libraryTest('a 10-level path keeps the current level in view (RF4)', (
    tester,
    env,
  ) async {
    final chain = await _chain(
      env,
      DeckEntity.maxDepth,
      (level) => 'Từ vựng tiếng Hàn cấp $level',
    );
    await pumpLibraryScreen(tester, env, deckScreen(deckId: chain.last.id));
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
