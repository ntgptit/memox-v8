import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/library_harness.dart';

// Screen 21: handoff states; UC-STUDY-001 steps 13, A3, E3; FE-A6 D18.

final _en = lookupAppLocalizations(const Locale('en'));

StudySessionView summaryView({
  SessionKind kind = SessionKind.reviewing,
  SessionStatus status = SessionStatus.completed,
  SessionEndReason? reason,
  SessionSummary summary = const SessionSummary(
    cardCount: 20,
    learnedCardCount: null,
    wrongTurnCount: 3,
    answeredCardCount: 20,
    turnCount: 23,
  ),
}) => StudySessionView(
  sessionId: 's',
  deckId: 'd',
  deckName: 'Nhà hàng',
  kind: kind,
  status: status,
  endReason: reason,
  currentMode: StudyMode.recall,
  direction: null,
  stages: const [StudyMode.recall],
  currentItem: null,
  progress: null,
  summary: summary,
);

Future<void> _pump(
  WidgetTester tester,
  LibraryEnv env,
  StudySessionView view,
  SummaryOutcome outcome, {
  VoidCallback? onDone,
  VoidCallback? onStudyDeck,
}) => pumpLibraryScreen(
  tester,
  env,
  SessionSummaryWidget(
    view: view,
    outcome: outcome,
    onDone: onDone ?? () {},
    onStudyDeck: onStudyDeck ?? () {},
  ),
);

void main() {
  libraryTest('a finished review: title, body, three stats and three facts '
      '(handoff 21 loaded)', (tester, env) async {
    var done = 0;
    var again = 0;
    await _pump(
      tester,
      env,
      summaryView(),
      SummaryOutcome.reviewFinished,
      onDone: () => done++,
      onStudyDeck: () => again++,
    );

    expect(find.text(_en.summaryReviewFinished), findsOneWidget);
    expect(
      find.text(
        _en.summaryReviewFinishedBody(_en.summaryCards(20)),
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      [
        for (final tile in tester.widgetList<MxStatTile>(
          find.byType(MxStatTile),
        ))
          (tile.label, tile.value),
      ],
      [
        (_en.summaryStatReviewed, '20'),
        (_en.summaryStatAnswered, '20'),
        (_en.summaryStatWrong, _en.summaryWrongOf(3, 23)),
      ],
    );
    expect(find.byType(MxListRow), findsNWidgets(3));
    expect(find.text(_en.summaryFactWrongCameBack(23)), findsOneWidget);

    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    await tester.tap(find.widgetWithText(MxButton, _en.studyThisDeck));
    expect((done, again), (1, 1));
  });

  libraryTest('left early in learning: the finished cards are kept, the rest '
      'stay new (handoff 21 leftEarly)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        kind: SessionKind.learning,
        status: SessionStatus.abandoned,
        reason: SessionEndReason.userExit,
        summary: const SessionSummary(
          cardCount: 12,
          learnedCardCount: 4,
          wrongTurnCount: 2,
          answeredCardCount: 9,
          turnCount: 14,
        ),
      ),
      SummaryOutcome.leftEarly,
    );

    expect(find.text(_en.summaryLeftEarly), findsOneWidget);
    expect(find.text(_en.summaryLeftEarlyLearningBody(4, 8)), findsOneWidget);
    expect(find.text(_en.summaryFactLearned), findsOneWidget);
    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsOneWidget);
  });

  libraryTest('an ended or failed session draws no stats and offers no '
      'Study this deck (handoff 21 reset, saveError)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.failed,
        reason: SessionEndReason.persistenceError,
      ),
      SummaryOutcome.saveError,
    );

    expect(find.text(_en.summarySaveErrorBody), findsOneWidget);
    expect(find.byType(MxStatTile), findsNothing);
    expect(find.byType(MxListRow), findsNWidgets(3));
    expect(find.widgetWithText(MxButton, _en.studyThisDeck), findsNothing);
  });

  libraryTest('an algorithm change draws no facts and says nothing was lost '
      '(handoff 21 schedulerChanged)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.invalidated,
        reason: SessionEndReason.schedulerChanged,
      ),
      SummaryOutcome.schedulerChanged,
    );

    expect(find.byType(MxListRow), findsNothing);
    expect(find.text(_en.summaryNoteHistory), findsOneWidget);
  });

  libraryTest('a session that ended before its first turn draws neither '
      'stats nor facts (FE-A6 D18)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.abandoned,
        reason: SessionEndReason.userExit,
        summary: const SessionSummary(
          cardCount: 5,
          learnedCardCount: null,
          wrongTurnCount: 0,
          answeredCardCount: 0,
          turnCount: 0,
        ),
      ),
      SummaryOutcome.leftEarly,
    );

    expect(find.byType(MxStatTile), findsNothing);
    expect(find.byType(MxListRow), findsNothing);
  });

  libraryTest('the summary holds at text scale 2 (FE-A6 D19)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      SessionSummaryWidget(
        view: summaryView(),
        outcome: SummaryOutcome.reviewFinished,
        onDone: () {},
        onStudyDeck: () {},
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
