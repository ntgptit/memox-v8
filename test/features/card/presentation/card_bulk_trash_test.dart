import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/library_harness.dart';
import 'card_bulk_actions_harness.dart';

void main() {
  libraryTest('Trash asks with the count on its button; Cancel keeps the '
      'selection; Undo of several puts them all back (SP2a 2.20)', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardDelete);

    expect(find.text(enL10n.cardDeleteTitle(2)), findsOneWidget);
    expect(find.text(enL10n.cardDeleteNote(2)), findsOneWidget);
    expect(inDialog(enL10n.cardMoveToTrashCount(2)), findsOneWidget);
    await tester.tap(inDialog(enL10n.commonCancel));
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MxSelectionCheckbox && widget.isChecked,
      ),
      findsNWidgets(2),
    );

    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();
    expect(await countActiveCards(env), 2);
    expect(find.text(enL10n.cardsTrashedToast(2)), findsOneWidget);
    expect(find.text(enL10n.commonUndo), findsOneWidget);

    await tester.tap(find.text(enL10n.commonUndo));
    await tester.pumpAndSettle();
    expect(await countActiveCards(env), 4);
    expect(find.text('annyeong'), findsOneWidget);
    expect(find.text('gamsa'), findsOneWidget);
  });

  libraryTest('a refused Undo of several leaves them all in the Trash '
      '(UC-TRASH-001 E3, SP2a 2.20)', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();
    await env.decks.deleteDeck(deckId: ids.words);

    await tester.tap(find.text(enL10n.commonUndo));
    await tester.pumpAndSettle();

    expect(
      find.text(enL10n.cardUndoRefused(enL10n.cardRejectionTargetInTrash)),
      findsOneWidget,
    );
    expect(
      await countRows(
        env,
        "SELECT COUNT(*) AS n FROM card WHERE id IN ('new1', 'due1') "
        'AND delete_batch_id IS NULL',
      ),
      0,
    );
  });

  libraryTest('one card shows its text; Undo puts it back (UC-TRASH-001 '
      'A1)', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong']);
    await tapBulk(tester, enL10n.cardDelete);

    expect(find.text(enL10n.cardDeleteTitle(1)), findsOneWidget);
    expect(inDialog('annyeong'), findsOneWidget);
    expect(inDialog('back'), findsOneWidget);
    expect(find.text(enL10n.cardDeleteNote(1)), findsOneWidget);
    await tester.tap(inDialog(enL10n.cardMoveToTrash));
    await tester.pumpAndSettle();
    expect(await countActiveCards(env), 3);
    expect(find.text(enL10n.cardTrashedToast('annyeong')), findsOneWidget);

    await tester.tap(find.text(enL10n.commonUndo));
    await tester.pumpAndSettle();
    expect(await countActiveCards(env), 4);
    expect(find.text('annyeong'), findsOneWidget);
  });

  libraryTest('a refused Undo says why; the card stays in the Trash '
      '(UC-TRASH-001 E3)', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong']);
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrash));
    await tester.pumpAndSettle();
    // Meanwhile its deck goes to the Trash as well.
    await env.decks.deleteDeck(deckId: ids.words);

    await tester.tap(find.text(enL10n.commonUndo));
    await tester.pumpAndSettle();
    expect(
      find.text(enL10n.cardUndoRefused(enL10n.cardRejectionTargetInTrash)),
      findsOneWidget,
    );
    expect(
      await countRows(
        env,
        "SELECT COUNT(*) AS n FROM card WHERE id = 'new1' "
        'AND delete_batch_id IS NULL',
      ),
      0,
    );
  });

  libraryTest('Move to Trash spins while the cards move (FE-B1 D15)', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong']);
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrash));
    await tester.pump();

    expect(find.byType(MxSpinner), findsOneWidget);
    await tester.pumpAndSettle();
  });
}
