import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/presentation/widgets/items/topik_answer_row_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_answer_filter_chips_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_figures_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_summary_hero_widget.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_type_stats_widget.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';
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

TopikAttempt _attempt(TopikAttemptSummary summary) => TopikAttempt(
  id: 'A',
  testId: 'topik2-96-reading',
  level: TopikLevel.topik2,
  section: TopikSection.reading,
  round: 96,
  mode: TopikAttemptMode.practice,
  status: TopikAttemptStatus.completed,
  startedAt: DateTime.utc(2026, 10, 15, 2),
  completedAt: DateTime.utc(2026, 10, 15, 3),
  updatedAt: DateTime.utc(2026, 10, 15, 3),
  totalTimeMs: 3731000,
  currentQuestionNo: 31,
  questionCount: summary.questionCount,
  maxScore: summary.maxScore,
  score: summary.score,
  correctCount: summary.correctCount,
  answeredCount: summary.answeredCount,
  contentVersion: 1,
);

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

  libraryTest('the figures: average per Q, answered, unanswered, and '
      'the longest with its real number (owner 2026-10-17)', (
    tester,
    env,
  ) async {
    await host(tester, env, TopikSummaryFiguresWidget(summary: summary));

    // (65 + 125 + 0 + 30) s over 4 questions.
    expect(find.text('55s'), findsOneWidget);
    expect(find.text('AVERAGE PER Q'), findsOneWidget);
    expect(find.text('ACCURACY'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2m 05s'), findsOneWidget);
    expect(find.text('LONGEST · Q32'), findsOneWidget);
  });

  for (final (locale, labels) in [
    (const Locale('en'), ['AVERAGE PER Q', 'LONGEST · Q32']),
    (const Locale('vi'), ['TRUNG BÌNH/CÂU', 'LÂU NHẤT · CÂU 32']),
  ]) {
    libraryTest('every figure label keeps one line at 360 dp in '
        '${locale.languageCode}', (tester, env) async {
      await pumpLibraryScreen(
        tester,
        env,
        Scaffold(
          body: SingleChildScrollView(
            child: TopikSummaryFiguresWidget(summary: summary),
          ),
        ),
        locale: locale,
      );
      await tester.pumpAndSettle();

      for (final label in labels) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        final lines = (paragraph.size.height / paragraph.preferredLineHeight)
            .round();
        expect(
          lines,
          1,
          reason: '$label wraps: ${paragraph.size.width} dp wide',
        );
      }
    });
  }

  libraryTest('no time on any question: Longest shows a dash and reads '
      '"None" (Q-P6-5)', (tester, env) async {
    final handle = tester.ensureSemantics();
    final blank = _summary([_answer(31, ms: 0), _answer(32, ms: 0)]);
    await host(tester, env, TopikSummaryFiguresWidget(summary: blank));

    // Both time figures have no value: a dash that reads "None".
    expect(find.text('–'), findsNWidgets(2));
    for (final label in ['Longest', 'Average per Q']) {
      expect(
        tester.getSemantics(
          find.byWidgetPredicate((w) => w is MxStatTile && w.label == label),
        ),
        matchesSemantics(label: label, value: 'None'),
      );
    }
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

  libraryTest('the chart: a bar per question with its real number and a '
      'status glyph, and a tap opens it (critique S4)', (tester, env) async {
    final opened = <int>[];
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(answers: answers, onOpen: opened.add),
    );

    for (final no in [31, 32, 33, 34]) {
      expect(find.text('$no'), findsOneWidget);
    }
    // A second channel besides colour, in the text role of the bar's status.
    final theme = Theme.of(tester.element(find.byType(MxChartLegend)));
    final glyphs = tester
        .widgetList<Icon>(
          find.descendant(
            of: find.byType(TopikQuestionBarChartWidget),
            matching: find.byType(Icon),
          ),
        )
        .toList();
    expect(
      [for (final g in glyphs) g.icon],
      [AppIcons.check, AppIcons.close, AppIcons.remove, AppIcons.check],
    );
    expect(glyphs[1].color, theme.colorScheme.error);
    expect(glyphs[2].color, theme.colorScheme.onSurfaceVariant);
    await tester.tap(find.text('32'));
    expect(opened, [32]);
  });

  libraryTest('the chart is one TalkBack node; its bars are hidden from the '
      'tree (owner 2026-10-17, ruling S4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(answers: answers, onOpen: (_) {}),
    );

    expect(
      find.bySemanticsLabel(
        'Time per question, 4 questions, longest question 32 2m 05s',
      ),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('^Question 3')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('^31|^32')), findsNothing);
    handle.dispose();
  });

  libraryTest('the chart with no time recorded names no longest question', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(
        answers: [_answer(31, ms: 0), _answer(32, ms: 0)],
        onOpen: (_) {},
      ),
    );

    expect(
      find.bySemanticsLabel('Time per question, 2 questions, no time recorded'),
      findsOneWidget,
    );
    handle.dispose();
  });

  libraryTest('a long chart fades its right edge while more lies past it '
      '(owner 2026-10-17)', (tester, env) async {
    await host(
      tester,
      env,
      TopikQuestionBarChartWidget(
        answers: [for (var no = 1; no <= 40; no++) _answer(no, selected: 1)],
        onOpen: (_) {},
      ),
    );

    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
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
    // TalkBack gets plain digits, not "circled digit three" (owner
    // 2026-10-17); the glyphs stay on screen.
    final spoken = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.semanticsLabel)
        .whereType<String>()
        .toList();
    expect(spoken, [
      'Your answer 3, Right answer 1, 2m 05s',
      'Not answered, 0s',
    ]);
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

  libraryTest('the hero: which test, when and how long, from the attempt, '
      'and one TalkBack node for the score (critique S2, S3)', (
    tester,
    env,
  ) async {
    final handle = tester.ensureSemantics();
    await host(
      tester,
      env,
      TopikSummaryHeroWidget(attempt: _attempt(summary), summary: summary),
    );

    expect(findPlainText('#96 · TOPIK II · Reading'), findsOneWidget);
    expect(findPlainTextContaining('1h 02m 11s'), findsOneWidget);
    expect(find.text('4 / 8'), findsOneWidget);
    // One node: the card merges the hero's lines into it.
    expect(
      find.bySemanticsLabel(RegExp(r'Score 4 of 8, 2 of 4 correct')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
