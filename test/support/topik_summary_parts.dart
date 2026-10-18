import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';

import 'library_harness.dart';

// What the tests of screen 38's parts (the time chart, the summary widgets)
// share.

/// Question [no] answered [selected] (null: blank) where [correct] is right,
/// taking [ms]; of [type].
TopikAttemptAnswer topikSummaryAnswer(
  int no, {
  int? selected,
  int correct = 1,
  int ms = 60000,
  TopikQuestionType type = TopikQuestionType.r1Topic,
}) => TopikAttemptAnswer(
  questionNo: no,
  selectedIdx: selected,
  timeSpentMs: ms,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: correct,
  points: 2,
  pointsEarned: selected == correct ? 2 : 0,
  questionType: type,
);

/// Four answers: two right, one wrong, one blank.
List<TopikAttemptAnswer> topikSummaryAnswers() => [
  topikSummaryAnswer(31, selected: 1, ms: 65000),
  topikSummaryAnswer(
    32,
    selected: 3,
    ms: 125000,
    type: TopikQuestionType.r1FillBlank,
  ),
  topikSummaryAnswer(33, ms: 0, type: TopikQuestionType.r1FillBlank),
  topikSummaryAnswer(34, selected: 1, ms: 30000),
];

/// [child] alone on a scrolling page.
Future<void> pumpSummaryPart(
  WidgetTester tester,
  LibraryEnv env,
  Widget child,
) async {
  await pumpLibraryScreen(
    tester,
    env,
    Scaffold(body: SingleChildScrollView(child: child)),
  );
  await tester.pumpAndSettle();
}
