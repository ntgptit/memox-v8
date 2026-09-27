@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/presentation/screens/study_session_screen.dart';
import 'package:memox/features/study/presentation/states/session_ending_state.dart';
import 'package:memox/features/study/presentation/widgets/sections/session_summary_widget.dart';
import 'package:memox/features/study/presentation/widgets/sections/study_browse_widget.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';
import '../../../support/study_fixtures.dart';

// Screens 16 and 21 against the kit's frames (handoff 16 default, handoff
// 21's states with the kit's numbers). No Hangul: the test fonts have none.

StudySessionScreen _screen(String id) => StudySessionScreen(
  sessionId: id,
  onDone: (_) {},
  onStudyDeck: (_) {},
  onLeave: (_) {},
);

Future<String> _browse(LibraryEnv env, {bool isTwoCards = false}) async {
  final root = await env.decks.root('TOPIK I');
  final leaf = await env.decks.sub(root.id, 'Động từ');
  await insertCard(
    env.db,
    id: 'a',
    deckId: leaf.id,
    front: 'ăn uống',
    back: 'to eat and drink',
    pronunciation: 'an uong',
    example: 'Tôi ăn sáng lúc 7 giờ.',
  );
  if (isTwoCards) {
    await insertCard(
      env.db,
      id: 'b',
      deckId: leaf.id,
      front: 'đi học',
      back: 'to go to school',
      createdAt: DateTime(2026, 9, 2),
    );
  }
  final opened = await studyEntryRepository(
    env.db,
    env.clock.now,
  ).openLearningSession(deckId: leaf.id);
  return (opened as Ok<String, StudyRejection>).value;
}

SessionSummary _counts(
  int cards,
  int? learned,
  int answered,
  int wrong,
  int turns,
) => SessionSummary(
  cardCount: cards,
  learnedCardCount: learned,
  wrongTurnCount: wrong,
  answeredCardCount: answered,
  turnCount: turns,
);

/// Handoff 21's states with the kit's numbers.
final _summaries = <(String, StudySessionView, SummaryOutcome)>[
  (
    'review',
    summaryView(summary: _counts(20, null, 20, 3, 23)),
    SummaryOutcome.reviewFinished,
  ),
  (
    'learning',
    summaryView(
      kind: SessionKind.learning,
      summary: _counts(12, 12, 12, 5, 53),
    ),
    SummaryOutcome.learningFinished,
  ),
  (
    'left_early',
    summaryView(
      kind: SessionKind.learning,
      status: SessionStatus.abandoned,
      reason: SessionEndReason.userExit,
      summary: _counts(12, 4, 9, 2, 14),
    ),
    SummaryOutcome.leftEarly,
  ),
  (
    'interrupted',
    summaryView(
      status: SessionStatus.abandoned,
      reason: SessionEndReason.interrupted,
      summary: _counts(7, null, 7, 1, 8),
    ),
    SummaryOutcome.interrupted,
  ),
  (
    'reset',
    summaryView(
      status: SessionStatus.invalidated,
      reason: SessionEndReason.schedulerReset,
      summary: _counts(5, null, 5, 0, 5),
    ),
    SummaryOutcome.reset,
  ),
  (
    'scheduler_changed',
    summaryView(
      kind: SessionKind.learning,
      status: SessionStatus.invalidated,
      reason: SessionEndReason.schedulerChanged,
      summary: _counts(12, 0, 0, 0, 0),
    ),
    SummaryOutcome.schedulerChanged,
  ),
  (
    'content_deleted',
    summaryView(
      status: SessionStatus.invalidated,
      reason: SessionEndReason.contentDeleted,
      summary: _counts(3, null, 3, 0, 3),
    ),
    SummaryOutcome.contentDeleted,
  ),
  (
    'save_error',
    summaryView(
      status: SessionStatus.failed,
      reason: SessionEndReason.persistenceError,
      summary: _counts(11, null, 11, 2, 13),
    ),
    SummaryOutcome.saveError,
  ),
];

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('study browse, $theme', (tester, env) async {
      final id = await _browse(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(id), brightness);
        await tester.pumpAndSettle();
        await expectBoundaryGolden(tester, 'goldens/study_browse_$theme.png');
      });
    });

    libraryTest('study browse, looking back, $theme', (tester, env) async {
      final id = await _browse(env, isTwoCards: true);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(id), brightness);
        await tester.pumpAndSettle();
        for (final dx in [-300.0, 300.0]) {
          await tester.drag(find.byType(StudyBrowseWidget), Offset(dx, 0));
          await tester.pumpAndSettle();
        }
        await expectBoundaryGolden(
          tester,
          'goldens/study_browse_looking_back_$theme.png',
        );
      });
    });

    for (final (name, view, outcome) in _summaries) {
      libraryTest('summary, $name, $theme', (tester, env) async {
        await withRealShadows(() async {
          await pumpLibraryGolden(
            tester,
            env,
            SessionSummaryWidget(
              view: view,
              outcome: outcome,
              onDone: () {},
              onStudyDeck: () {},
            ),
            brightness,
          );
          await expectBoundaryGolden(
            tester,
            'goldens/summary_${name}_$theme.png',
          );
        });
      });
    }
  }
}
