import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_answer_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_figures_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';
import 'package:memox/shared/widgets/mx_stat_tile.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_screen_fixtures.dart';

/// Question [no] answered [selected] (null: blank) where [correct] is right,
/// taking [ms]; of [type].
TopikAttemptAnswer _answer(
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

TopikAttemptSummary _summary(List<TopikAttemptAnswer> answers) {
  final correct = answers.where((a) => a.status == TopikAnswerStatus.correct);
  final answered = answers.where((a) => a.selectedIdx != null).length;
  return TopikAttemptSummary(
    score: correct.length * 2,
    maxScore: answers.length * 2,
    correctCount: correct.length,
    questionCount: answers.length,
    answeredCount: answered,
    accuracyPercent: answered == 0 ? 0 : correct.length * 100 ~/ answered,
    longest: answers.reduce((a, b) => b.timeSpentMs > a.timeSpentMs ? b : a),
    typeStats: const [
      TopikTypeStat(type: TopikQuestionType.r1Topic, correct: 2, total: 2),
      TopikTypeStat(type: TopikQuestionType.r1FillBlank, correct: 0, total: 2),
    ],
    weakestType: TopikQuestionType.r1FillBlank,
    answers: answers,
  );
}

// Screen 38's parts (detail file 38; critique S1, S3–S7).
void main() {
  final answers = [
    _answer(31, selected: 1, ms: 65000),
    _answer(32, selected: 3, ms: 125000, type: TopikQuestionType.r1FillBlank),
    _answer(33, ms: 0, type: TopikQuestionType.r1FillBlank),
    _answer(34, selected: 1, ms: 30000),
  ];
  final summary = _summary(answers);

  Future<void> host(WidgetTester tester, LibraryEnv env, Widget child) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: SingleChildScrollView(child: child)),
    );
    await tester.pumpAndSettle();
  }

  libraryTest('the donut writes correct of total', (tester, env) async {
    await host(
      tester,
      env,
      const TopikScoreDonutWidget(correct: 48, total: 50),
    );
    expect(find.text('48 / 50'), findsOneWidget);
    // Beside "96 / 100" the ring's figure says what it counts (wireframe).
    expect(
      find.descendant(
        of: find.byType(TopikScoreDonutWidget),
        matching: find.text('Correct'),
      ),
      findsOneWidget,
    );
  });

  libraryTest('the time chart names what each colour means', (
    tester,
    env,
  ) async {
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(answers: answers, onOpen: (_) {}),
    );

    final legend = find.byType(MxChartLegend);
    expect(legend, findsOneWidget);
    // In the filter chips' order (audit 2026-10-16).
    final labels = tester
        .widgetList<Text>(
          find.descendant(of: legend, matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .toList();
    expect(labels, ['Wrong', 'Unanswered', 'Correct']);
  });

  libraryTest('the figures: accuracy, answered, unanswered, and the longest '
      'with its real number (critique S1)', (tester, env) async {
    await host(tester, env, TopikSummaryFiguresWidget(summary: summary));

    expect(find.text('66%'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2m 05s'), findsOneWidget);
    expect(find.text('LONGEST · Q32'), findsOneWidget);
  });

  libraryTest('no time on any question: Longest shows a dash and reads '
      '"None" (Q-P6-5)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final blank = _summary([_answer(31, ms: 0), _answer(32, ms: 0)]);
    await host(tester, env, TopikSummaryFiguresWidget(summary: blank));

    expect(find.text('–'), findsOneWidget);
    expect(
      tester.getSemantics(
        find.byWidgetPredicate((w) => w is MxStatTile && w.label == 'Longest'),
      ),
      matchesSemantics(label: 'Longest', value: 'None'),
    );
    handle.dispose();
  });

  libraryTest('the chips carry their counts; an empty one can be off', (
    tester,
    env,
  ) async {
    final picks = <TopikAnswerFilter>[];
    await host(
      tester,
      env,
      TopikAnswerFilterChipsWidget(
        summary: _summary([_answer(31, selected: 1)]),
        selected: TopikAnswerFilter.all,
        onSelected: picks.add,
        isEmptyDisabled: true,
      ),
    );

    final chips = tester.widgetList<MxFilterChip>(find.byType(MxFilterChip));
    expect([for (final c in chips) c.count], [1, 0, 0, 1]);
    expect(
      [for (final c in chips) c.onSelected == null],
      [false, true, true, false],
    );
    // The chip row scrolls sideways at 360 dp.
    await tester.ensureVisible(find.text('Correct'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct'));
    expect(picks, [TopikAnswerFilter.correct]);
  });

  libraryTest('the chart: a bar per question with its real number, one node '
      'each, and a tap opens it (critique S4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final opened = <int>[];
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(answers: answers, onOpen: opened.add),
    );

    for (final no in [31, 32, 33, 34]) {
      expect(find.text('$no'), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Question 32, Wrong, 2m 05s'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Question 33, Unanswered, 0s'),
      findsOneWidget,
    );
    await tester.tap(find.text('32'));
    expect(opened, [32]);
    handle.dispose();
  });

  libraryTest('an answer row: yours, the right one and the time; the eye '
      'hides the right one; the status badge (critique S5)', (
    tester,
    env,
  ) async {
    var opens = 0;
    await host(
      tester,
      env,
      Column(
        children: [
          TopikAnswerRowWidget(
            answer: answers[1],
            isRightHidden: false,
            onOpen: () => opens++,
          ),
          TopikAnswerRowWidget(
            answer: answers[2],
            isRightHidden: true,
            onOpen: () {},
          ),
        ],
      ),
    );

    expect(
      findPlainText('Your answer ③ · Right answer ① · 2m 05s'),
      findsOneWidget,
    );
    expect(findPlainText('Not answered · 0s'), findsOneWidget);
    final badges = tester.widgetList<MxBadge>(find.byType(MxBadge)).toList();
    expect(
      [for (final b in badges) b.tone],
      [MxBadgeTone.danger, MxBadgeTone.neutral],
    );
    await tester.tap(find.text('Question 32'));
    expect(opens, 1);
  });

  libraryTest('by type: each with its share; the weakest marked '
      '(BR-TOPIK-024)', (tester, env) async {
    await host(tester, env, TopikTypeStatsWidget(summary: summary));

    expect(find.text("What it's about"), findsOneWidget);
    expect(find.text('Fill the blank'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('0 / 2'), findsOneWidget);
    expect(find.text('Weakest'), findsOneWidget);
  });

  libraryTest('by type: no weakest when every type is perfect', (
    tester,
    env,
  ) async {
    final perfect = TopikAttemptSummary(
      score: 4,
      maxScore: 4,
      correctCount: 2,
      questionCount: 2,
      answeredCount: 2,
      accuracyPercent: 100,
      longest: answers.first,
      typeStats: const [
        TopikTypeStat(type: TopikQuestionType.r1Topic, correct: 2, total: 2),
      ],
      weakestType: null,
      answers: [answers.first, answers.last],
    );
    await host(tester, env, TopikTypeStatsWidget(summary: perfect));
    expect(find.text('Weakest'), findsNothing);
  });

  libraryTest('a chip says selected to TalkBack', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikAnswerFilterChipsWidget(
        summary: summary,
        selected: TopikAnswerFilter.wrong,
        onSelected: (_) {},
      ),
    );
    final node = tester.getSemantics(find.text('Wrong'));
    expect(node.getSemanticsData().flagsCollection.isSelected, Tristate.isTrue);
    handle.dispose();
  });
}
