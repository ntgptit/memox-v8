import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';

import '../../support/widget_harness.dart';

// A chart's legend: a dot of each series' colour beside its label. The
// chart's own nodes say what each mark is, so the legend says nothing to
// TalkBack.
void main() {
  const series = [
    MxBarSeries(label: 'Correct', color: Colors.green),
    MxBarSeries(label: 'Wrong', color: Colors.red),
  ];

  testWidgets('each series shows its label beside a dot of its colour', (
    tester,
  ) async {
    await pumpMx(tester, const MxChartLegend(series: series));

    for (final entry in series) {
      expect(find.text(entry.label), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.decoration is BoxDecoration &&
              (widget.decoration! as BoxDecoration).shape == BoxShape.circle &&
              (widget.decoration! as BoxDecoration).color == entry.color,
        ),
        findsOneWidget,
        reason: entry.label,
      );
    }
  });

  testWidgets('the legend says nothing to TalkBack', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, const MxChartLegend(series: series));

    expect(find.bySemanticsLabel('Correct'), findsNothing);
    expect(find.bySemanticsLabel('Wrong'), findsNothing);
    handle.dispose();
  });
}
