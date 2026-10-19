import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/presentation/providers/reset_learning_summary_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';
import 'package:memox/shared/widgets/mx_outcome_tile.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/deck_screen_harness.dart';
import '../../../support/library_harness.dart';

// The States rows of screen 02 (Review algorithm & reset) whose detail file
// cites no executed test: resetSummaryLoading, resetSummaryRejected and
// resetSummaryError, the reset dialog while its summary is read, refused or
// failed.

final _en = lookupAppLocalizations(const Locale('en'));

typedef _Summary = Outcome<ResetLearningSummary, SrsRejection>;

MxSheetActions _actions(WidgetTester tester) =>
    tester.widget<MxSheetActions>(find.byType(MxSheetActions));

/// Opens the reset dialog from screen 02. The dialog may hold a skeleton,
/// which pulses for ever, so this never waits for the animations to end.
Future<void> _tapReset(WidgetTester tester) async {
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
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Finder _inDialog(Finder finder) =>
    find.descendant(of: find.byType(MxDialog), matching: finder);

/// Opens the reset dialog of a locked root whose summary read is [summary].
Future<void> _openDialog(
  WidgetTester tester,
  LibraryEnv env,
  Future<_Summary> Function() summary,
) async {
  final korean = await env.decks.root('Korean');
  await lockScheduler(env.db, korean.id);
  await pumpLibraryScreen(
    tester,
    env,
    deckAlgorithmScreen(deckId: korean.id),
    overrides: [
      resetLearningSummaryProvider(korean.id).overrideWith((ref) => summary()),
    ],
  );
  await _tapReset(tester);
}

void main() {
  libraryTest('resetSummaryLoading: the dialog shows its title, one skeleton '
      'row and the algorithm choice; no intro; the confirm is off', (
    tester,
    env,
  ) async {
    await _openDialog(tester, env, () => Completer<_Summary>().future);

    final dialog = tester.widget<MxDialog>(find.byType(MxDialog));
    expect(dialog.title, _en.resetDialogTitle);
    expect(dialog.body, isNull);
    expect(
      find.descendant(
        of: find.byType(MxDialog),
        matching: find.byType(MxSkeletonList),
      ),
      findsOneWidget,
    );
    expect(tester.widget<MxSkeletonList>(find.byType(MxSkeletonList)).rows, 1);
    expect(find.byType(MxOutcomeTile), findsNothing);
    expect(
      _inDialog(find.text(_en.resetAlgorithmHeader.toUpperCase())),
      findsOneWidget,
    );
    expect(_inDialog(find.byType(MxOptionRow)), findsNWidgets(2));
    expect(_actions(tester).confirmLabel, _en.resetConfirm);
    expect(_actions(tester).onConfirm, isNull);
    expect(_actions(tester).onCancel, isNotNull);
  });

  libraryTest('resetSummaryRejected: a refused summary says why in the body; '
      'the confirm stays off and Cancel closes', (tester, env) async {
    await _openDialog(
      tester,
      env,
      () async => const Rejected(SrsRejection.notFound),
    );

    expect(
      tester.widget<MxDialog>(find.byType(MxDialog)).body,
      _en.srsRejection(SrsRejection.notFound),
    );
    expect(find.byType(MxSkeletonList), findsNothing);
    expect(_actions(tester).onConfirm, isNull);

    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(find.byType(MxDialog), findsNothing);
  });

  for (final (name, error, message) in <(String, Object, String)>[
    (
      'a Failure',
      const DatabaseLockedFailure(cause: 'busy'),
      _en.failure(const DatabaseLockedFailure(cause: 'busy')),
    ),
    ('anything else', StateError('summary'), _en.failureUnknown),
  ]) {
    libraryTest('resetSummaryError: $name is the body; the confirm stays '
        'off', (tester, env) async {
      await _openDialog(tester, env, () => Future<_Summary>.error(error));

      expect(tester.widget<MxDialog>(find.byType(MxDialog)).body, message);
      expect(find.byType(MxSkeletonList), findsNothing);
      expect(_actions(tester).onConfirm, isNull);
      expect(_inDialog(find.byType(MxOptionRow)), findsNWidgets(2));
    });
  }
}
