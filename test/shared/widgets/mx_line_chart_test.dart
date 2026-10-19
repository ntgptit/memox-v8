import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/shared/widgets/mx_line_chart.dart';

import '../../support/widget_harness.dart';

// A line of values on fl_chart (follow-ups spec G8): one point per value
// from 0 to the maximum, a label under each, one TalkBack node.
void main() {
  const dimens = AppDimens();

  List<MxLinePoint> points(List<double> values) => [
    for (final (index, value) in values.indexed)
      MxLinePoint(value: value, label: '#${index + 1}'),
  ];

  Widget chart(List<MxLinePoint> points, {double width = 320}) => SizedBox(
    width: width,
    child: MxLineChart(
      points: points,
      maxValue: 100,
      maxLabel: '100',
      semanticLabel: 'Scores: 44, 62, 76 of 100',
    ),
  );

  LineChartData data(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data;

  testWidgets('one point per value, from 0 to the maximum, in the accent '
      'fill, each point centred over its label', (tester) async {
    await pumpMx(tester, chart(points([44, 62, 76])));

    final line = data(tester).lineBarsData.single;
    expect([for (final spot in line.spots) spot.y], [44, 62, 76]);
    expect(data(tester).minY, 0);
    expect(data(tester).maxY, 100);
    expect(line.color, MxStatusColors.light.accentFill);
    // The scale: a guide at the maximum carries it.
    final guide = data(tester).extraLinesData.horizontalLines.single;
    expect(guide.y, 100);
    expect(guide.label.labelResolver(guide), '100');
    // A label's centre is its point's x: the plot spans the cells.
    final plot = tester.getRect(find.byType(LineChart));
    for (final (index, label) in ['#1', '#2', '#3'].indexed) {
      final x = plot.left + plot.width * (index + 0.5) / 3;
      expect(tester.getCenter(find.text(label)).dx, closeTo(x, 0.5));
    }
  });

  testWidgets('one TalkBack node carries the summary; the chart and its '
      'labels are not read', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, chart(points([44, 62, 76])));

    expect(find.bySemanticsLabel('Scores: 44, 62, 76 of 100'), findsOneWidget);
    expect(find.bySemanticsLabel('#1'), findsNothing);
    handle.dispose();
  });

  testWidgets('a few points stretch to the width; many keep a control per '
      'point and scroll, opening at the newest', (tester) async {
    await pumpMx(tester, chart(points([44, 62])));
    expect(tester.getSize(find.byType(LineChart)).width, 320);

    await pumpMx(tester, chart(points([for (var i = 0; i < 30; i++) 50.0])));
    expect(
      tester.getSize(find.byType(LineChart)).width,
      dimens.sizeControl * 30,
    );
    // The newest point is in view, the oldest past the start.
    final view = tester.getRect(find.byType(MxLineChart));
    expect(
      tester.getRect(find.text('#30')).right,
      lessThanOrEqualTo(view.right),
    );
    expect(tester.getRect(find.text('#1')).right, lessThan(view.left));
  });
}
