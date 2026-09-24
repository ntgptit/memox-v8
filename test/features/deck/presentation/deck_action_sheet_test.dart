import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';

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

Future<int> _deckCount(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
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
    expect(find.text(_en.deckStudyOptions), findsOneWidget);
    expect(
      tester
          .widget<MxActionSheetCommandRow>(
            find.widgetWithText(MxActionSheetCommandRow, _en.deckStudyThis),
          )
          .isEnabled,
      isFalse,
    );
    // Spec A4: what waits for its feature says so to TalkBack.
    for (final label in [_en.deckStudyThis, _en.deckStudyOptions]) {
      expect(
        tester.getSemantics(find.text(label)),
        isSemantics(hint: _en.commonNotAvailableYet),
        reason: label,
      );
    }
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

  libraryTest('Delete says what goes with the deck, then deletes it', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    final verbs = await env.decks.sub(words.id, 'Verbs');
    await insertCard(env.db, id: 'one', deckId: verbs.id);
    await insertCard(env.db, id: 'two', deckId: verbs.id);
    await pumpLibraryScreen(tester, env, deckScreen(deckId: words.id));
    await _choose(tester, _en.deckDelete);

    expect(find.text(_en.deckDeleteTitle('Words')), findsOneWidget);
    expect(find.text(_en.deckDeleteSummary(1, 2)), findsOneWidget);
    await tester.tap(find.text(_en.deckDelete));
    // The screen is the test's only route: nothing to pop back to.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(await _deckCount(env), 1);
    expect(find.text(_en.deckDeletedToast), findsOneWidget);
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
    expect(find.text(_en.deckDeletedToast), findsOneWidget);
  });
}
