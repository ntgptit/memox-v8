import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../../support/library_harness.dart';

/// Question [no] answered [selected] (null: blank) where 1 is right, taking
/// [ms].
TopikAttemptAnswer _answer(
  int no, {
  int? selected,
  int ms = 60000,
  TopikQuestionType type = TopikQuestionType.r1Topic,
}) => TopikAttemptAnswer(
  questionNo: no,
  selectedIdx: selected,
  timeSpentMs: ms,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: 1,
  points: 2,
  pointsEarned: selected == 1 ? 2 : 0,
  questionType: type,
);

// Screen 38's time chart (detail file 38; critique S4, owner 2026-10-17).
void main() {
  final answers = [
    _answer(31, selected: 1, ms: 65000),
    _answer(32, selected: 3, ms: 125000, type: TopikQuestionType.r1FillBlank),
    _answer(33, ms: 0, type: TopikQuestionType.r1FillBlank),
    _answer(34, selected: 1, ms: 30000),
  ];

  Future<void> host(WidgetTester tester, LibraryEnv env, Widget child) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(body: SingleChildScrollView(child: child)),
    );
    await tester.pumpAndSettle();
  }

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
    // The ink and size come from the glyph's own IconTheme.
    IconThemeData themeOf(int i) =>
        IconTheme.of(tester.element(find.byWidget(glyphs[i])));
    expect(themeOf(1).color, theme.colorScheme.error);
    expect(themeOf(2).color, theme.colorScheme.onSurfaceVariant);
    expect(themeOf(1).size, 18);
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
        'Time per question, 4 questions, longest question 32: 2m 05s',
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

  libraryTest('at the compact column a seventh bar peeks under the fade '
      '(audit 2026-10-17, P2-1)', (tester, env) async {
    await host(
      tester,
      env,
      // The chart column at 360 dp: 360 less two screen margins.
      SizedBox(
        width: 328,
        child: TopikQuestionBarChartWidget(
          answers: [for (var no = 1; no <= 40; no++) _answer(no, selected: 1)],
          onOpen: (_) {},
        ),
      ),
    );

    final chart = find.byType(TopikQuestionBarChartWidget);
    final right = tester.getTopRight(chart).dx;
    final seventh = find.byKey(const ValueKey('topik-chart-fill-7'));
    // 328 / 48 = 6.83 cells: 40 dp of the seventh cell show, its painted
    // bar inside them and under the fade.
    expect(tester.getTopLeft(seventh).dx, lessThan(right));
    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);
    expect(
      tester.getTopLeft(seventh).dx,
      greaterThan(tester.getTopLeft(find.byKey(MxScrollFade.trailingKey)).dx),
      reason: 'the bar sits under the fade, not beside it',
    );
  });
}
