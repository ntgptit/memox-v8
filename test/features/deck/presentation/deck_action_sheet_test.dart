import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip(_en.deckActions));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, String command) async {
  await _openSheet(tester);
  await tester.tap(find.text(command));
  await tester.pumpAndSettle();
}

Future<int> _activeDeckCount(LibraryEnv env) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM deck WHERE delete_batch_id IS NULL',
            )
            .getSingle())
        .read<int>('n');

Future<String?> _parentOf(LibraryEnv env, String id) async =>
    (await env.db
            .customSelect(
              'SELECT parent_id FROM deck WHERE id = ?',
              variables: [Variable<String>(id)],
            )
            .getSingle())
        .read<String?>('parent_id');

void main() {
  libraryTest('a root offers rename, its scheduler and delete, not move', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _openSheet(tester);

    expect(find.text(_en.deckRename), findsOneWidget);
    expect(find.text(_en.deckReviewAlgorithm), findsOneWidget);
    expect(find.text(_en.deckSchedulerEightBox), findsOneWidget);
    expect(find.text(_en.deckDelete), findsOneWidget);
    expect(find.text(_en.deckMove), findsNothing);
    expect(find.text(_en.deckReorder), findsNothing);
    // Study opens the entry (FE-A6 D10); Study options waits under Coming
    // soon (spec A4, amended).
    expect(find.text(_en.studyThisDeck), findsOneWidget);
    expect(find.text(_en.deckStudyOptions), findsNothing);
  });

  libraryTest('a sub-deck offers move, not the scheduler; two decks reorder', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(words.id, 'A');
    await env.decks.sub(words.id, 'B');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _openSheet(tester);

    expect(find.text(_en.deckMove), findsOneWidget);
    expect(find.text(_en.deckReorder), findsOneWidget);
    expect(find.text(_en.deckReviewAlgorithm), findsNothing);
  });

  libraryTest(
    'a deck that takes cards offers Import; a root and a deck of decks do not (BR-TRANSFER-008)',
    (tester, env) async {
      final korean = await env.decks.root('Korean');
      final words = await env.decks.sub(korean.id, 'Words');
      final grammar = await env.decks.sub(korean.id, 'Grammar');
      await env.decks.sub(grammar.id, 'Particles');
      await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
      final imported = <String>[];

      for (final (deckId, isOffered) in [
        (korean.id, false),
        (grammar.id, false),
        (words.id, true),
      ]) {
        await pumpLibraryScreen(
          tester,
          env,
          deckScreen(deckId: deckId, onImportCards: imported.add),
        );
        await _openSheet(tester);
        expect(
          find.text(_en.deckActionImport),
          isOffered ? findsOneWidget : findsNothing,
        );
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();
      }

      await _choose(tester, _en.deckActionImport);
      expect(imported, [words.id]);
    },
  );

  libraryTest(
    'only a deck of cards offers Export (UC-TRANSFER-002 E5, ruling E5)',
    (tester, env) async {
      final korean = await env.decks.root('Korean');
      final words = await env.decks.sub(korean.id, 'Words');
      final empty = await env.decks.sub(korean.id, 'Empty');
      await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
      final exported = <String>[];

      for (final (deckId, isOffered) in [
        (korean.id, false),
        (empty.id, false),
        (words.id, true),
      ]) {
        await pumpLibraryScreen(
          tester,
          env,
          deckScreen(
            deckId: deckId,
            onExportCards: (deck) => exported.add(deck.name),
          ),
        );
        await _openSheet(tester);
        expect(
          find.text(_en.deckActionExport),
          isOffered ? findsOneWidget : findsNothing,
        );
        await tester.tapAt(Offset.zero);
        await tester.pumpAndSettle();
      }

      await _choose(tester, _en.deckActionExport);
      expect(exported, ['Words']);
    },
  );

  libraryTest('Rename renames the open deck', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _choose(tester, _en.deckRename);
    await tester.enterText(find.byType(EditableText), 'Hàn Quốc');
    await tester.tap(find.text(_en.deckRenameConfirm));
    await tester.pumpAndSettle();

    // The app bar title and the current crumb.
    expect(find.text('Hàn Quốc'), findsNWidgets(2));
  });

  libraryTest('Move to Trash says what goes with the deck, then offers '
      'Undo (FE-B1)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final verbs = await env.decks.sub(words.id, 'Verbs');
    await insertCard(env.db, id: 'one', deckId: verbs.id);
    await insertCard(env.db, id: 'two', deckId: verbs.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _openSheet(tester);
    expect(find.text(_en.deckDeleteHint), findsOneWidget);
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckDeleteTitle), findsOneWidget);
    expect(find.text(_en.deckDeleteSummary('Words', 1, 2)), findsOneWidget);
    expect(find.text(_en.deckDeleteNote), findsOneWidget);
    await tester.tap(find.text(_en.deckDelete));
    // The screen is the test's only route: nothing to pop back to.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(await _activeDeckCount(env), 1);
    expect(find.text(_en.deckTrashedToast('Words', 1, 2)), findsOneWidget);
    expect(find.text(_en.commonUndo), findsOneWidget);
  });

  libraryTest('Undo puts the deck back where it was (UC-TRASH-001 A1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await env.decks.sub(words.id, 'Verbs');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await tester.tap(find.byTooltip(_en.deckMoreActions('Words')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    expect(await _activeDeckCount(env), 1);

    await tester.tap(find.text(_en.commonUndo));
    await tester.pumpAndSettle();
    expect(await _activeDeckCount(env), 3);
    expect(await _parentOf(env, words.id), korean.id);
    expect(find.text('Words'), findsOneWidget);
  });

  libraryTest('a refused Undo says why; the deck stays in the Trash '
      '(UC-TRASH-001 E3)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final verbs = await env.decks.sub(words.id, 'Verbs');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await tester.tap(find.byTooltip(_en.deckMoreActions('Verbs')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    // Meanwhile the deck it was in goes to the Trash as well.
    await env.decks.deleteDeck(deckId: words.id);

    await tester.tap(find.text(_en.commonUndo));
    await tester.pumpAndSettle();
    expect(
      find.text(_en.deckUndoRefused(_en.deckRejectionTargetInTrash)),
      findsOneWidget,
    );
    expect(await _activeDeckCount(env), 1);
    expect(await _parentOf(env, verbs.id), words.id);
  });

  libraryTest('Move to Trash spins while the deck moves, and moves once '
      '(FE-B1 D15)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await tester.tap(find.byTooltip(_en.deckMoreActions('Words')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.deckDelete));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    await tester.pumpAndSettle();

    final batches = await env.db
        .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
        .getSingle();
    expect(batches.read<int>('n'), 1);
    expect(find.text(_en.deckRejectionNotFound), findsNothing);
  });

  libraryTest('Move lists targets by path and moves there', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final grammar = await env.decks.sub(korean.id, 'Grammar');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: grammar.id));
    await _choose(tester, _en.deckMove);
    await tester.tap(find.text('Korean › Words'));
    await tester.pumpAndSettle();

    expect(await _parentOf(env, grammar.id), words.id);
    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
  });

  libraryTest('a double tap on a move target moves once (RF2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Words');
    final grammar = await env.decks.sub(korean.id, 'Grammar');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: grammar.id));
    await _choose(tester, _en.deckMove);
    await tester.tap(find.text('Korean › Words'));
    await tester.tap(find.text('Korean › Words'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text(_en.deckMovedToast('Words')), findsOneWidget);
    expect(find.text(_en.deckRejectionSameParent), findsNothing);
  });

  libraryTest('with nowhere to go, the picker says so and offers OK', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _choose(tester, _en.deckMove);

    expect(find.text(_en.deckMoveEmptyTitle), findsOneWidget);
    expect(find.text(_en.commonOk), findsOneWidget);
  });

  libraryTest('Review algorithm opens screen 02 for a root (ruling D-L5)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onOpenAlgorithm: opened.add),
    );
    await _choose(tester, _en.deckReviewAlgorithm);

    expect(opened, [korean.id]);
  });

  libraryTest('Study opens the Study Entry, for a root and for a sub-deck '
      '(FE-A6 D10)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final opened = <String>[];
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: korean.id, onOpenStudy: opened.add),
    );
    await _choose(tester, _en.studyThisDeck);
    await pumpLibraryScreen(
      tester,
      env,
      deckScreen(deckId: words.id, onOpenStudy: opened.add),
    );
    await _choose(tester, _en.studyThisDeck);

    expect(opened, [korean.id, words.id]);
  });

  libraryTest('Reorder from the sheet shows the drag handles', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'A');
    await env.decks.sub(korean.id, 'B');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _choose(tester, _en.deckReorder);

    expect(find.byIcon(AppIcons.dragHandle), findsNWidgets(2));
    expect(find.text(_en.libraryReorderDone), findsOneWidget);
  });

  libraryTest('the action sheet meets the target guidelines', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen(deckId: korean.id));
    await _openSheet(tester);

    await expectAccessibleTargets(tester);
  });

  libraryTest('a row’s ⋮ opens that deck’s sheet, with Open first', (
    tester,
    env,
  ) async {
    await env.decks.root('Korean');
    await env.decks.root('Kanji');
    await pumpLibraryScreen(tester, env, deckScreen());

    await tester.tap(find.byTooltip(_en.deckMoreActions('Kanji')));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckOpen), findsOneWidget);
    expect(find.text(_en.deckReorder), findsOneWidget);
  });

  libraryTest('a row’s actions on a vanished deck say so', (tester, env) async {
    final kanji = await env.decks.root('Kanji');
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, deckScreen());

    // Deleted elsewhere; the row is still on screen until the next frame.
    await env.decks.deleteDeck(deckId: kanji.id);
    await tester.tap(find.byTooltip(_en.deckMoreActions('Kanji')));
    await tester.pumpAndSettle();

    expect(find.text(_en.deckOpen), findsNothing);
    expect(find.text(_en.deckGoneTitle), findsOneWidget);
  });
}
