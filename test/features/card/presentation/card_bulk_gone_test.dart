import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../../support/library_harness.dart';
import '../../../support/widget_harness.dart';
import 'card_bulk_actions_harness.dart';

void main() {
  libraryTest('Move skips a card that went meanwhile and says so (SP2a 2.19)', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await tapBulk(tester, enL10n.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(
      find.text(enL10n.bulkToast(enL10n.cardMovedToast(1, 'Verbs'), 1)),
      findsOneWidget,
    );
    expect(
      await countRows(env, 'SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [
        ids.verbs,
      ]),
      2,
    );
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Flag skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await tapBulk(tester, enL10n.cardFlag);
    await tapBulk(tester, enL10n.cardFlagSet);

    expect(
      find.text(enL10n.bulkToast(enL10n.cardFlaggedToast(1), 1)),
      findsOneWidget,
    );
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Tag skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await tapBulk(tester, enL10n.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(
      find.text(enL10n.bulkToast(enL10n.cardTaggedToast(1, 'greetings'), 1)),
      findsOneWidget,
    );
  });

  libraryTest('Trash skips a card that went meanwhile and says so', (
    tester,
    env,
  ) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();

    expect(
      find.text(enL10n.bulkToast(enL10n.cardsTrashedToast(1), 1)),
      findsOneWidget,
    );
    expect(await countActiveCards(env), 2);
  });

  libraryTest('Undo after a Trash that skipped a gone card restores exactly '
      'the cards it wrote (SP2a 2.20)', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'due1'});
    await tester.pumpAndSettle();
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(enL10n.commonUndo));
    await tester.pumpAndSettle();

    expect(await countActiveCards(env), 3);
    expect(find.text('annyeong'), findsOneWidget);
    expect(find.text('gamsa'), findsNothing);
  });

  /// Both selected cards go behind the screen's back; the action then
  /// refuses as a whole (SP2a 2.19), says how many, and prunes them.
  Future<void> selectThenLoseBoth(WidgetTester tester, LibraryEnv env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong', 'gamsa']);
    await env.cards.deleteCards(cardIds: {'new1', 'due1'});
    await tester.pumpAndSettle();
  }

  libraryTest('Move when every selected card went meanwhile says so and '
      'prunes the selection (SP2a 2.19)', (tester, env) async {
    await selectThenLoseBoth(tester, env);
    await tapBulk(tester, enL10n.cardMove);
    await tester.tap(find.text('Korean › Verbs'));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Tag when every selected card went meanwhile says so and '
      'prunes the selection (SP2a 2.19)', (tester, env) async {
    await selectThenLoseBoth(tester, env);
    await tapBulk(tester, enL10n.cardTag);
    await tester.enterText(find.byType(EditableText).last, 'greetings');
    await tester.tap(inDialog(enL10n.cardTagConfirm));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('Trash when every selected card went meanwhile says so and '
      'prunes the selection (SP2a 2.19)', (tester, env) async {
    await selectThenLoseBoth(tester, env);
    await tapBulk(tester, enL10n.cardDelete);
    await tester.tap(inDialog(enL10n.cardMoveToTrashCount(2)));
    await tester.pumpAndSettle();

    expect(find.text(enL10n.cardBulkAllGone(2)), findsOneWidget);
    expect(find.byType(MxSelectionCheckbox), findsNothing);
  });

  libraryTest('the bulk bar meets the target guidelines', (tester, env) async {
    final ids = await seedBulkCards(env);
    await pumpLibraryScreen(tester, env, bulkSection(ids.words));
    await selectCards(tester, ['annyeong']);

    await expectAccessibleTargets(tester);
  });
}
