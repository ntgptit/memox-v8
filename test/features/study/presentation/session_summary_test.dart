import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_hero_widget.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';
import 'package:memox/shared/widgets/mx_action_pair.dart';

import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screen 21: handoff states; UC-STUDY-001 steps 13, A3, E3; FE-A6 D18.

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
  libraryTest('a finished review: the body states the count; the one tile is '
      'wrong turns, explained (critique 2026-09-30 part 3c-1, R3)', (
    tester,
    env,
  ) async {
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
      [(_en.summaryStatWrong, _en.summaryWrongOf(3, 23))],
    );
    expect(find.text(_en.summaryWrongExplained), findsOneWidget);
    expect(find.byType(MxListRow), findsNothing);
    expect(find.text(_en.summaryFactsHeader.toUpperCase()), findsNothing);

    await tester.tap(find.widgetWithText(MxButton, _en.summaryDone));
    await tester.tap(find.widgetWithText(MxButton, _en.summaryStudyAgain));
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
          cardLimit: 20,
        ),
      ),
      SummaryOutcome.leftEarly,
    );

    expect(find.text(_en.summaryLeftEarly), findsOneWidget);
    expect(find.text(_en.summaryLeftEarlyLearningBody(4, 8)), findsOneWidget);
    expect(find.text(_en.summaryFactLearned), findsNothing);
    expect(
      find.widgetWithText(MxButton, _en.summaryStudyAgain),
      findsOneWidget,
    );
    // Answered (9) differs from the 4 learned, so it has a tile.
    expect(
      [
        for (final tile in tester.widgetList<MxStatTile>(
          find.byType(MxStatTile),
        ))
          tile.label,
      ],
      [_en.summaryStatAnswered, _en.summaryStatWrong],
    );
  });

  libraryTest('a clean learning session: answered equals learned, so only '
      'wrong turns show, with no explanation at zero (critique 2026-09-30 '
      'part 3c-1, R3)', (tester, env) async {
    await _pump(
      tester,
      env,
      summaryView(
        kind: SessionKind.learning,
        summary: const SessionSummary(
          cardCount: 12,
          learnedCardCount: 12,
          wrongTurnCount: 0,
          answeredCardCount: 12,
          turnCount: 12,
          cardLimit: 20,
        ),
      ),
      SummaryOutcome.learningFinished,
    );
    expect(
      [
        for (final tile in tester.widgetList<MxStatTile>(
          find.byType(MxStatTile),
        ))
          (tile.label, tile.value),
      ],
      [(_en.summaryStatWrong, _en.summaryWrongOf(0, 12))],
    );
    expect(find.text(_en.summaryWrongExplained), findsNothing);
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
    expect(find.widgetWithText(MxButton, _en.summaryStudyAgain), findsNothing);
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
    // The footer hides Study this deck here, so the copy points to Done
    // (critique 2026-09-30 part 3c-1).
    expect(find.text(_en.summarySchedulerChangedBody), findsOneWidget);
    expect(
      _en.summarySchedulerChangedBody,
      contains('Done takes you back to the deck'),
    );
  });

  libraryTest('the facts card names the wrong count in the warning role, '
      'the card being a surface and not the hero\'s container; a clean run '
      'reads in onSurface (task 14.3)', (tester, env) async {
    Color? wrongCountColor() {
      final text = find.byWidgetPredicate(
        (w) =>
            w is Text &&
            (w.data == _en.summaryWrongOf(3, 23) ||
                w.data == _en.summaryWrongOf(0, 23)),
      );
      return tester.widget<Text>(text).style?.color;
    }

    await _pump(
      tester,
      env,
      summaryView(status: SessionStatus.abandoned),
      SummaryOutcome.reset,
    );
    final context = tester.element(find.byType(SessionSummaryWidget));
    expect(find.byType(MxStatTile), findsNothing);
    expect(wrongCountColor(), context.semanticColors.warning);

    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.abandoned,
        summary: const SessionSummary(
          cardCount: 20,
          learnedCardCount: null,
          wrongTurnCount: 0,
          answeredCardCount: 20,
          turnCount: 23,
          cardLimit: 50,
        ),
      ),
      SummaryOutcome.reset,
    );
    expect(wrongCountColor(), context.colors.onSurface);
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
          cardLimit: 20,
        ),
      ),
      SummaryOutcome.leftEarly,
    );

    expect(find.byType(MxStatTile), findsNothing);
    expect(find.byType(MxListRow), findsNothing);
  });

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

  libraryTest('the footer is one MxActionPair: Study this deck 5, Done 6', (
    tester,
    env,
  ) async {
    await _pump(tester, env, summaryView(), SummaryOutcome.reviewFinished);

    final pair = tester.widget<MxActionPair>(find.byType(MxActionPair));
    expect(pair.leadingFlex, 5);
    expect(pair.trailingFlex, 6);
    expect(pair.leading!.label, _en.summaryStudyAgain);
    expect(pair.leading!.isSingleLine, isTrue);
  });

  libraryTest('a short summary sits centred above the footer (critique '
      '2026-09-30 part 3c-1, R4)', (tester, env) async {
    await _pump(tester, env, summaryView(), SummaryOutcome.reviewFinished);
    final hero = tester.getRect(find.byType(SessionSummaryHeroWidget));
    final bar = tester.getRect(find.byType(MxAppBar));
    final footer = tester.getRect(find.byType(MxFooterBar));
    final spaceCentre = (bar.bottom + footer.top) / 2;
    expect((hero.center.dy - spaceCentre).abs(), lessThan(AppSpacing.gutter));
  });

  libraryTest('a long summary still scrolls from the top, clipping nothing', (
    tester,
    env,
  ) async {
    await _pump(
      tester,
      env,
      summaryView(),
      SummaryOutcome.reviewFinished,
      textScale: 2,
    );
    final hero = tester.getRect(find.byType(SessionSummaryHeroWidget));
    final bar = tester.getRect(find.byType(MxAppBar));
    expect(hero.top - bar.bottom, lessThan(AppSpacing.section));
    expect(tester.takeException(), isNull);
  });

  libraryTest("an interrupted session's body states no count, so the finished "
      'tile stays (critique 2026-09-30 part 3c-1 review, R3)', (
    tester,
    env,
  ) async {
    await _pump(
      tester,
      env,
      summaryView(
        status: SessionStatus.abandoned,
        reason: SessionEndReason.interrupted,
      ),
      SummaryOutcome.interrupted,
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
        (_en.summaryStatWrong, _en.summaryWrongOf(3, 23)),
      ],
    );
  });

  libraryTest('the overline keeps the deck name as typed and reads the plain '
      'sentence (critique 2026-09-30 part 2, P4)', (tester, env) async {
    await _pump(tester, env, summaryView(), SummaryOutcome.reviewFinished);

    final overline = find.text('REVIEW SESSION · Nhà hàng');
    expect(overline, findsOneWidget);
    expect(find.text('REVIEW SESSION · NHÀ HÀNG'), findsNothing);
    final text = tester.widget<Text>(overline);
    expect(text.style, tester.element(overline).textStyles.eyebrow);
    expect(
      text.semanticsLabel,
      _en.summaryOverline(_en.summaryKindReview, 'Nhà hàng'),
    );
  });
}
