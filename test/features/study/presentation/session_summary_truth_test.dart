import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 21 says only what the session did (critique 2026-10-02, F1): no
// "came back in later rounds" for a session that had none, and no
// "Schedules updated" success under an ended or failed hero.

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StudySessionView view,
  SummaryOutcome outcome,
) => pumpLibraryScreen(
  tester,
  env,
  SessionSummaryWidget(
    view: view,
    outcome: outcome,
    onDone: () {},
    onStudyDeck: () {},
  ),
);

void main() {
  for (final (outcome, reason) in [
    (SummaryOutcome.leftEarly, SessionEndReason.userExit),
    (SummaryOutcome.interrupted, SessionEndReason.interrupted),
  ]) {
    libraryTest('${outcome.name} with wrong turns: no came-back note', (
      tester,
      env,
    ) async {
      await _pump(
        tester,
        env,
        summaryView(status: SessionStatus.abandoned, reason: reason),
        outcome,
      );

      expect(find.text(_en.summaryWrongExplained), findsNothing);
    });
  }

  libraryTest('a failed save: the facts say the answers are kept, on a '
      'neutral tile, and the turns line says nothing came back', (
    tester,
    env,
  ) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.failed,
        reason: SessionEndReason.persistenceError,
      ),
      SummaryOutcome.saveError,
    );

    final finished = find.widgetWithText(MxListRow, _en.summaryFactReviewed);
    expect(
      find.descendant(
        of: finished,
        matching: find.text(_en.summaryFactKeptSub),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<MxIconTile>(
            find.descendant(of: finished, matching: find.byType(MxIconTile)),
          )
          .tone,
      MxIconTileTone.tinted,
    );
    expect(find.text(_en.summaryFactWrongSub(23)), findsOneWidget);
    expect(find.text(_en.summaryWrongExplained), findsNothing);
  });

  libraryTest('a reset learning session says the same', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        kind: SessionKind.learning,
        status: SessionStatus.invalidated,
        reason: SessionEndReason.schedulerReset,
        summary: const SessionSummary(
          cardCount: 12,
          learnedCardCount: 4,
          wrongTurnCount: 2,
          answeredCardCount: 9,
          turnCount: 14,
          cardLimit: 20,
        ),
      ),
      SummaryOutcome.reset,
    );

    expect(
      find.descendant(
        of: find.widgetWithText(MxListRow, _en.summaryFactLearned),
        matching: find.text(_en.summaryFactKeptSub),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.summaryFactWrongSub(14)), findsOneWidget);
  });
}
