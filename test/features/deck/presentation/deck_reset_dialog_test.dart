import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';
import '../../../support/srs_fixtures.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The real schedules; a reset first waits for [gate], and the first one
/// fails in the database when [isFirstFailing] (UC-SRS-001 E1).
final class _GatedReset implements ScheduleRepository {
  _GatedReset(this._real, {this.isFirstFailing = false});

  final ScheduleRepository _real;
  final bool isFirstFailing;
  final gate = Completer<void>();
  var _resets = 0;

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) async {
    await gate.future;
    _resets++;
    if (isFirstFailing && _resets == 1) {
      throw const DatabaseLockedFailure(cause: 'locked');
    }
    return _real.resetLearning(
      rootDeckId: rootDeckId,
      schedulerType: schedulerType,
    );
  }

  @override
  Future<Outcome<void, SrsRejection>> changeScheduler({
    required String rootDeckId,
    required SchedulerType newType,
  }) => _real.changeScheduler(rootDeckId: rootDeckId, newType: newType);

  @override
  Future<void> initializeCard({required String cardId}) =>
      _real.initializeCard(cardId: cardId);

  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) =>
      _real.recordTurn(turn);

  @override
  Future<(SchedulerType, CardScheduleState)?> scheduleOf({
    required String cardId,
  }) => _real.scheduleOf(cardId: cardId);

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  }) =>
      _real.completeLearning(cardId: cardId, generation: generation, now: now);

  @override
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  }) => _real.resetSummary(rootDeckId: rootDeckId);
}

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

    await tester.tap(find.text(_en.resetConfirm));
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
    await tester.tap(find.text(_en.resetConfirm));
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
    await tester.tap(find.text(_en.resetConfirm));
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

  libraryTest('a reset made elsewhere while the dialog is open moves its '
      'cycle on', (tester, env) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
    );
    await _openReset(tester);

    await ScheduleRepositoryImpl(env.db).resetLearning(rootDeckId: korean.id);
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.resetConfirm));
    await tester.pumpAndSettle();

    // The dialog follows the live deck: its reset opens cycle 3, not 2.
    expect(find.text(_en.resetDoneToast(3, 0)), findsOneWidget);
  });

  libraryTest('while the reset runs the confirm spins and Cancel is off', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    final schedules = _GatedReset(ScheduleRepositoryImpl(env.db));
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [scheduleRepositoryProvider.overrideWithValue(schedules)],
    );
    await _openReset(tester);

    await tester.tap(find.text(_en.resetConfirm));
    await tester.pump();
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNull,
    );
    expect(
      _option(tester, _en.resetSwitchTo(_en.deckSchedulerEightBox)).onSelected,
      isNull,
    );
    await tester.tap(find.text(_en.commonCancel));
    await tester.pump();
    expect(find.text(_en.resetDialogTitle), findsOneWidget);

    schedules.gate.complete();
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDialogTitle), findsNothing);
    expect(find.text(_en.resetDoneToast(2, 0)), findsOneWidget);
  });

  libraryTest('a reset that fails keeps the dialog for another try (E1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean', SchedulerType.sm2);
    await lockScheduler(env.db, korean.id);
    final schedules = _GatedReset(
      ScheduleRepositoryImpl(env.db),
      isFirstFailing: true,
    )..gate.complete();
    await pumpLibraryScreen(
      tester,
      env,
      deckAlgorithmScreen(deckId: korean.id),
      overrides: [scheduleRepositoryProvider.overrideWithValue(schedules)],
    );
    await _openReset(tester);

    await tester.tap(find.text(_en.resetConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDialogTitle), findsOneWidget);
    expect(
      find.text(_en.failure(const DatabaseLockedFailure(cause: 'locked'))),
      findsOneWidget,
    );
    expect(find.text(_en.algorithmLockedTitle(1)), findsOneWidget);

    await tester.tap(find.text(_en.resetConfirm));
    await tester.pumpAndSettle();

    expect(find.text(_en.resetDialogTitle), findsNothing);
    expect(find.text(_en.algorithmUnlockedTitle), findsOneWidget);
  });

  libraryTest('the reset confirm is warning, not the action Indigo '
      '(critique 2026-09-30 part 3d-2, E4)', (tester, env) async {
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
    );
    await _openReset(tester);

    final actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.isWarning, isTrue);
    expect(actions.isDestructive, isFalse);
  });
}
