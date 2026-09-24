import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/srs_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

MxOptionRow _option(WidgetTester tester, String title) =>
    tester.widget<MxOptionRow>(find.widgetWithText(MxOptionRow, title));

Future<void> _openReset(WidgetTester tester) async {
  // At large text the button sits below the fold.
  await tester.scrollUntilVisible(
    find.text(_en.algorithmResetAction),
    200,
    scrollable: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text(_en.algorithmResetAction));
  await tester.pumpAndSettle();
}

void main() {
  libraryTest('with progress: cycle, Kept and Lost; keeping the algorithm '
      'resets it (UC-SRS-001)', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'a',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await insertCard(env.db, id: 'b', deckId: words.id);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    await _openReset(tester);

    expect(find.text(_en.resetDialogIntro(2, 'Korean', 2)), findsOneWidget);
    expect(find.text(_en.resetKeptBody(1)), findsOneWidget);
    expect(find.text(_en.resetLostBody(2)), findsOneWidget);
    expect(
      _option(tester, _en.resetKeep(_en.deckSchedulerSm2)).isSelected,
      isTrue,
    );

    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDoneToast(2, 2)), findsOneWidget);
    expect(find.text(_en.algorithmUnlockedTitle), findsOneWidget);
    expect(_option(tester, _en.deckSchedulerSm2).isSelected, isTrue);
  });

  libraryTest('switching in the reset starts the new cycle on the other '
      'algorithm', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    await _openReset(tester);

    await tester.tap(find.text(_en.resetSwitchTo(_en.deckSchedulerEightBox)));
    await tester.pump();
    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();

    expect(_option(tester, _en.deckSchedulerEightBox).isSelected, isTrue);
    expect(find.text(_en.algorithmUnlockedTitle), findsOneWidget);
  });

  libraryTest('nothing to lose says so and still resets (UC-SRS-001 A2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    await _openReset(tester);

    expect(find.text(_en.resetNothingToLose), findsOneWidget);
    expect(find.byType(MxOutcomeTile), findsNothing);
    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDoneToast(2, 0)), findsOneWidget);
  });

  libraryTest('an open session is named among what is lost', (
    tester,
    env,
  ) async {
    final (rootId, _, _) = await insertStudyTree(env.db, 'r');
    await pumpLibraryScreen(tester, env, deckAlgorithmScreen(deckId: rootId));
    await _openReset(tester);

    expect(find.text(_en.resetLostBodyWithSession(1)), findsOneWidget);
    expect(find.text(_en.resetLostBody(1)), findsNothing);
  });

  libraryTest('cancelling the reset changes nothing (UC-SRS-001 A3)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    await _openReset(tester);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDialogTitle), findsNothing);
    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);
  });

  libraryTest('the reset dialog at 2x on a 360 phone does not overflow', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(
      env.db,
      id: 'a',
      deckId: words.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      textScale: 2,
    );
    await _openReset(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(_en.resetDialogTitle), findsOneWidget);
  });
}
