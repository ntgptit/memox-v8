import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 21: a review that reached its card_limit (handoff 21).

final _en = lookupAppLocalizations(const Locale('en'));

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StudySessionView view,
  SummaryOutcome outcome, {
  VoidCallback? onDone,
  VoidCallback? onStudyDeck,
  double textScale = 1,
}) => pumpLibraryScreen(
  tester,
  env,
  textScale: textScale,
  SessionSummaryWidget(
    view: view,
    outcome: outcome,
    onDone: onDone ?? () {},
    onStudyDeck: onStudyDeck ?? () {},
  ),
);

void main() {
  libraryTest('a review that reached its card_limit says so (handoff 21 '
      'large, BR-STUDY-024)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        summary: const SessionSummary(
          cardCount: 200,
          learnedCardCount: null,
          wrongTurnCount: 41,
          answeredCardCount: 200,
          turnCount: 241,
          cardLimit: 200,
        ),
      ),
      SummaryOutcome.reviewFinished,
    );

    expect(
      find.text(
        _en.summaryReviewAtLimitBody(_en.summaryCards(200)),
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        _en.summaryReviewFinishedBody(_en.summaryCards(200)),
        findRichText: true,
      ),
      findsNothing,
    );
  });

  libraryTest('a review at its card_limit says how many cards are still '
      'due (UC-STUDY-001 A4)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        summary: const SessionSummary(
          cardCount: 20,
          learnedCardCount: null,
          wrongTurnCount: 2,
          answeredCardCount: 20,
          turnCount: 22,
          cardLimit: 20,
          remainingDueCount: 34,
        ),
      ),
      SummaryOutcome.reviewFinished,
    );

    expect(
      find.text(
        _en.summaryReviewAtLimitMoreBody(
          _en.summaryCards(20),
          _en.summaryMoreDue(34),
        ),
        findRichText: true,
      ),
      findsOneWidget,
    );
  });

  libraryTest('a review under its card_limit keeps the plain body', (
    tester,
    env,
  ) async {
    await _pump(tester, env, summaryView(), SummaryOutcome.reviewFinished);

    expect(
      find.text(
        _en.summaryReviewAtLimitBody(_en.summaryCards(20)),
        findRichText: true,
      ),
      findsNothing,
    );
  });
}
