import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/held_writes.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

/// The real schedules, except that the first [summaryFailures] summary reads
/// throw, a [summaryRejection] refuses the summary, and a reset waits on
/// [hold] (UC-SRS-001 E1; SP2b 2.26, 2.28).
final class _FlakySchedules implements ScheduleRepository {
  _FlakySchedules(this._real, this.hold);

  final ScheduleRepository _real;
  final WriteHold hold;
  int summaryFailures = 0;

  /// When set, a summary read that does not fail waits for it.
  Completer<void>? summaryGate;
  SrsRejection? summaryRejection;

  @override
  Future<Outcome<ResetLearningSummary, SrsRejection>> resetSummary({
    required String rootDeckId,
  }) async {
    if (summaryFailures > 0) {
      summaryFailures--;
      throw WriteHold.failure;
    }
    await summaryGate?.future;
    if (summaryRejection case final reason?) return Rejected(reason);
    return _real.resetSummary(rootDeckId: rootDeckId);
  }

  @override
  Future<Outcome<void, SrsRejection>> resetLearning({
    required String rootDeckId,
    SchedulerType? schedulerType,
  }) async {
    await hold.pass();
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
}

Future<void> _openReset(WidgetTester tester) async {
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

Finder _banner(String message) => find.descendant(
  of: find.byType(MxInlineBanner),
  matching: find.text(message),
);

/// A locked sm2 root over [schedules], its reset dialog open.
Future<void> _pumpOpen(
  WidgetTester tester,
  LibraryEnv env,
  _FlakySchedules Function(ScheduleRepository real) make,
) async {
  final korean = await env.decks.root('Korean', SchedulerType.sm2);
  await lockScheduler(env.db, korean.id);
  await pumpLibraryScreen(
    tester,
    env,
    deckAlgorithmScreen(deckId: korean.id),
    overrides: [
      scheduleRepositoryProvider.overrideWithValue(
        make(ScheduleRepositoryImpl(env.db)),
      ),
    ],
  );
  await _openReset(tester);
}

void main() {
  libraryTest('a failed summary read says so with Retry; Cancel stays live; '
      'Retry reads again (SP2b 2.28)', (tester, env) async {
    await _pumpOpen(
      tester,
      env,
      (real) => _FlakySchedules(real, WriteHold()..open())..summaryFailures = 1,
    );

    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    var actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.onConfirm, isNull);
    expect(actions.onCancel, isNotNull);

    await tester.tap(find.text(_en.commonRetry));
    await tester.pumpAndSettle();
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.resetNothingToLose), findsOneWidget);
    actions = tester.widget<MxSheetActions>(find.byType(MxSheetActions));
    expect(actions.onConfirm, isNotNull);
  });

  libraryTest('the frame after Retry is never blank: the banner stays, its '
      'Retry spinning, until the read answers (final fix 6)', (
    tester,
    env,
  ) async {
    final gate = Completer<void>();
    await _pumpOpen(
      tester,
      env,
      (real) => _FlakySchedules(real, WriteHold()..open())
        ..summaryFailures = 1
        ..summaryGate = gate,
    );

    await tester.tap(find.text(_en.commonRetry));
    await tester.pump();

    expect(
      find.byType(MxInlineBanner).evaluate().length +
          find.byType(MxSkeletonList).evaluate().length,
      greaterThan(0),
    );
    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    // Riverpod 3.4 reports the retry as an AsyncError that is loading, not an
    // AsyncLoading: the dialog's AsyncError match still holds, so no change.
    expect(
      tester
          .widget<MxButton>(find.widgetWithText(MxButton, _en.commonRetry))
          .isLoading,
      isTrue,
    );
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onCancel,
      isNotNull,
    );

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(MxInlineBanner), findsNothing);
    expect(find.text(_en.resetNothingToLose), findsOneWidget);
  });

  libraryTest('a deck gone meanwhile keeps its message, has no Retry and '
      'leaves the confirm off (SP2b 2.28)', (tester, env) async {
    await _pumpOpen(
      tester,
      env,
      (real) =>
          _FlakySchedules(real, WriteHold()..open())
            ..summaryRejection = SrsRejection.notFound,
    );

    expect(find.text(_en.srsRejection(SrsRejection.notFound)), findsOneWidget);
    expect(find.text(_en.commonRetry), findsNothing);
    expect(
      tester.widget<MxSheetActions>(find.byType(MxSheetActions)).onConfirm,
      isNull,
    );
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(_en.resetDialogTitle), findsNothing);
  });

  libraryTest('Back and a scrim tap wait for the reset; a failure keeps the '
      'dialog with a banner and the confirm retries (SP2b 2.26, 2.27)', (
    tester,
    env,
  ) async {
    final hold = WriteHold();
    await _pumpOpen(tester, env, (real) => _FlakySchedules(real, hold));
    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pump();

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tapAt(const Offset(2, 2));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MxDialog), findsOneWidget);

    hold
      ..failNext()
      ..open();
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsOneWidget);
    expect(_banner(_en.failure(WriteHold.failure)), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    await tester.tap(find.text(_en.resetConfirm(2)));
    await tester.pumpAndSettle();
    expect(find.text(_en.resetDialogTitle), findsNothing);
    expect(find.text(_en.resetDoneToast(2, 0)), findsOneWidget);
  });
}
