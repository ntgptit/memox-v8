import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_line_chart.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

import '../../support/widget_harness.dart';

// A line of values on fl_chart (follow-ups spec G8): one point per value
// from 0 to the maximum, a label under each, one TalkBack node.
void main() {
  const dimens = AppDimens();

  List<MxLinePoint> points(List<double> values) => [
    for (final (index, value) in values.indexed)
      MxLinePoint(value: value, label: '#${index + 1}'),
  ];

  Widget chart(
    List<MxLinePoint> points, {
    MxScrollFadeGround ground = MxScrollFadeGround.page,
  }) => SizedBox(
    width: 320,
    child: MxLineChart(
      points: points,
      maxValue: 100,
      maxLabel: '100',
      semanticLabel: 'Scores: 44, 62, 76 of 100',
      ground: ground,
    ),
  );

  LineChartData data(WidgetTester tester) =>
      tester.widget<LineChart>(find.byType(LineChart)).data;

  testWidgets('one point per value, from 0 to the maximum, in the primary, '
      'each point centred over its label', (tester) async {
    await pumpMx(tester, chart(points([44, 62, 76])));

    final line = data(tester).lineBarsData.single;
    expect([for (final spot in line.spots) spot.y], [44, 62, 76]);
    expect(data(tester).minY, 0);
    expect(line.color, appLightColors.primary);
    // The scale: a guide at the maximum carries it, with a room above it
    // that keeps a dot at the maximum and the label inside the scroll's
    // clip (final review F3).
    final guide = data(tester).extraLinesData.horizontalLines.single;
    expect(guide.y, 100);
    expect(guide.label.labelResolver(guide), '100');
    expect(guide.label.alignment, Alignment.topRight);
    final height = tester.getSize(find.byType(LineChart)).height;
    final room = height - dimens.sizeControl * 2;
    expect(room, greaterThan(dimens.space4 + dimens.strokeEmphasis / 2));
    expect(data(tester).maxY, closeTo(100 * height / (height - room), 0.001));
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
    // Inside a card the fade dissolves into the card (final review F2).
    await pumpMx(
      tester,
      chart(points([44, 62]), ground: MxScrollFadeGround.raised),
    );
    expect(
      tester.widget<MxScrollFade>(find.byType(MxScrollFade)).ground,
      MxScrollFadeGround.raised,
    );

    await pumpMx(tester, chart(points([for (var i = 0; i < 30; i++) 50.0])));
    // The newest point is in view, the oldest past the start.
    final view = tester.getRect(find.byType(MxLineChart));
    expect(
      tester.getRect(find.text('#30')).right,
      lessThanOrEqualTo(view.right),
    );
    expect(tester.getRect(find.text('#1')).right, lessThan(view.left));
  });
}
