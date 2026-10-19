import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../../support/library_harness.dart';
import '../../../support/topik_summary_parts.dart';

// Screen 38's time chart (detail file 38; critique S4, owner 2026-10-17).
void main() {
  final answers = topikSummaryAnswers();

  libraryTest('the chart: a bar per question with its real number and a '
      'status glyph, and a tap opens it (critique S4)', (tester, env) async {
    final opened = <int>[];
    await pumpSummaryPart(
      tester,
      env,
      TopikQuestionBarChartWidget(answers: answers, onOpen: opened.add),
    );

    for (final no in [31, 32, 33, 34]) {
      expect(find.text('$no'), findsOneWidget);
    }
    // A second channel besides colour, in the text role of the bar's status.
    final context = tester.element(find.byType(MxChartLegend));
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
    expect(themeOf(1).color, context.colors.error);
    expect(themeOf(2).color, context.colors.mutedForeground);
    expect(themeOf(1).size, context.dimens.sizeIconCompact);
    await tester.tap(find.text('32'));
    expect(opened, [32]);
    await tester.pump(const Duration(milliseconds: 200));
  });

  libraryTest('the chart is one TalkBack node; its bars are hidden from the '
      'tree (owner 2026-10-17, ruling S4)', (tester, env) async {
    final handle = tester.ensureSemantics();
    await pumpSummaryPart(
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
    await pumpSummaryPart(
      tester,
      env,
      TopikQuestionBarChartWidget(
        answers: [topikSummaryAnswer(31, ms: 0), topikSummaryAnswer(32, ms: 0)],
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
    await pumpSummaryPart(
      tester,
      env,
      TopikQuestionBarChartWidget(
        answers: [
          for (var no = 1; no <= 40; no++) topikSummaryAnswer(no, selected: 1),
        ],
        onOpen: (_) {},
      ),
    );

    expect(find.byKey(MxScrollFade.trailingKey), findsOneWidget);
    expect(find.byKey(MxScrollFade.leadingKey), findsNothing);
  });

  libraryTest('at the compact column a seventh bar peeks under the fade '
      '(audit 2026-10-17, P2-1)', (tester, env) async {
    await pumpSummaryPart(
      tester,
      env,
      // The chart column at 360 dp: 360 less two screen margins.
      SizedBox(
        width: 328,
        child: TopikQuestionBarChartWidget(
          answers: [
            for (var no = 1; no <= 40; no++)
              topikSummaryAnswer(no, selected: 1),
          ],
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
