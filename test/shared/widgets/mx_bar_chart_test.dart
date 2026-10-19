import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/shared/widgets/mx_bar_chart.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

import '../../support/widget_harness.dart';

// A row of bars on fl_chart (audit 2026-10-19, G4): a 48 dp cell per bar,
// scaled to the largest, a guide, one TalkBack node.
void main() {
  const dimens = AppDimens();
  final plot = dimens.sizeControl * 2;

  MxBar bar(double value, String label) => MxBar(
    value: value,
    color: Colors.teal.shade500,
    marker: const Icon(Icons.check),
    label: label,
    cellKey: ValueKey('cell-$label'),
  );

  Widget chart(List<MxBar> bars, {ValueChanged<int>? onOpen}) => SizedBox(
    width: 320,
    child: MxBarChart(
      bars: bars,
      legend: [MxBarSeries(label: 'Correct', color: Colors.teal.shade500)],
      semanticLabel: 'Time per question',
      guideLabel: '2m 05s',
      onOpen: onOpen ?? (_) {},
    ),
  );

  BarChartData data(WidgetTester tester) =>
      tester.widget<BarChart>(find.byType(BarChart)).data;

  testWidgets('the largest bar fills the plot, the rest scale to it, a 0 is '
      'a stub; each bar centred in its control-wide cell', (tester) async {
    await pumpMx(tester, chart([bar(120, '1'), bar(60, '2'), bar(0, '3')]));

    expect(
      [for (final group in data(tester).barGroups) group.barRods.single.toY],
      [plot, plot / 2, dimens.space4],
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('cell-1'))).width,
      dimens.sizeControl,
    );
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('a tap anywhere in a cell opens its bar', (tester) async {
    final opened = <int>[];
    await pumpMx(
      tester,
      chart([bar(120, '1'), bar(60, '2')], onOpen: opened.add),
    );

    await tester.tap(find.text('2'));
    // The cell's ink takes the tap; its content ignores the pointer.
    await tester.tap(
      find
          .ancestor(
            of: find.byKey(const ValueKey('cell-1')),
            matching: find.byType(MxRowInk),
          )
          .first,
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(opened, [1, 0]);
  });

  testWidgets('a guide at the largest value carries its words; none when '
      'every value is 0', (tester) async {
    await pumpMx(tester, chart([bar(120, '1'), bar(60, '2')]));

    final guide = data(tester).extraLinesData.horizontalLines.single;
    expect(guide.label.labelResolver(guide), '2m 05s');
    expect(guide.y, greaterThan(plot));

    await pumpMx(tester, chart([bar(0, '1'), bar(0, '2')]));
    expect(data(tester).extraLinesData.horizontalLines, isEmpty);
  });

  testWidgets('one TalkBack node for the chart; bars, labels and legend say '
      'nothing more', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, chart([bar(120, '1'), bar(60, '2')]));

    expect(find.bySemanticsLabel('Time per question'), findsOneWidget);
    expect(find.bySemanticsLabel('1'), findsNothing);
    expect(find.bySemanticsLabel('Correct'), findsNothing);
    handle.dispose();
  });
}
