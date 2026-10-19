import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

import '../../support/widget_harness.dart';

// FE-A9 D6: kit 22's seven stacked day bars, drawn with fl_chart (critique
// 2026-10-19).

const _learning = MxBarSeries(label: 'Learning', color: Colors.orange);
const _reviewing = MxBarSeries(label: 'Reviewing', color: Colors.indigo);

/// The theme's hairline and `sizeTrack`, which the chart reads.
const double _hairline = 1;
const double _sizeTrack = 4;

MxDayBar _day(String label, int reviewing, int learning, {bool now = false}) =>
    MxDayBar(
      label: label,
      base: reviewing,
      top: learning,
      semanticLabel: '$label: ${reviewing + learning} cards',
      isCurrent: now,
    );

Widget _chart(List<MxDayBar> days) => SizedBox(
  width: 300,
  child: MxStackedDayBars(days: days, base: _reviewing, top: _learning),
);

BarChartData _data(WidgetTester tester) =>
    tester.widget<BarChart>(find.byType(BarChart)).data;

BarChartRodData _rod(WidgetTester tester, int day) =>
    _data(tester).barGroups[day].barRods.single;

/// The [from, to] of each stacked part of [day]'s rod, base first.
List<(double, double)> _parts(WidgetTester tester, int day) => [
  for (final item in _rod(tester, day).rodStackItems) (item.fromY, item.toY),
];

/// Taps the middle of [day]'s column, high above its bar.
Future<void> _tapColumn(WidgetTester tester, int day, int of) async {
  final chart = tester.getRect(find.byType(BarChart));
  final column = chart.width / of;
  await tester.tapAt(Offset(chart.left + column * (day + 0.5), chart.top + 4));
  await tester.pump();
}

void main() {
  testWidgets('the fullest day fills the chart; the rest scale to it; the '
      'parts stack with a card hairline between them', (tester) async {
    await pumpMx(
      tester,
      _chart([_day('M', 10, 0), _day('Today', 12, 8, now: true)]),
    );

    // Today: 8 learning over 12 reviewing, and the hairline, fill the 78.
    const unit = (MxStackedDayBars.barsHeight - _hairline) / 20;
    expect(_parts(tester, 1), [
      (0, 12 * unit),
      (12 * unit + _hairline, MxStackedDayBars.barsHeight),
    ]);
    expect(_rod(tester, 1).rodStackItems.map((item) => item.color), [
      _reviewing.color,
      _learning.color,
    ]);
    // The rod itself shows only in the gap: the card.
    expect(_rod(tester, 1).color, appLightColors.card);
    // Monday is drawn as strongly as Today, half its 20 (critique
    // 2026-10-02, F5), with no gap over a single part.
    expect(_parts(tester, 0), [(0, 10 * unit)]);
    expect(_rod(tester, 0).toY, 10 * unit);
  });

  testWidgets('a part with any cards stays visible beside a far fuller day', (
    tester,
  ) async {
    await pumpMx(tester, _chart([_day('M', 80, 0), _day('T', 0, 1)]));

    // One card in a week of 80 would be under 1 dp; it keeps `sizeTrack`.
    expect(_parts(tester, 1), [(0, _sizeTrack)]);
  });

  testWidgets('a day with nothing is one 2-high baseline: the progress track, '
      'visible on the card it sits in, light and dark', (tester) async {
    for (final (brightness, colors) in [
      (Brightness.light, appLightColors),
      (Brightness.dark, appDarkColors),
    ]) {
      await pumpMx(
        tester,
        MxCard(child: _chart([_day('F', 0, 0), _day('S', 3, 0)])),
        brightness: brightness,
      );
      // The host theme eases from the previous brightness.
      await tester.pump(const Duration(milliseconds: 400));
      final baseline = _rod(tester, 0);
      // The chart starts over in the new brightness, so it paints the new
      // colours at once rather than easing from the old ones.
      expect(
        tester.widget<BarChart>(find.byType(BarChart)).key,
        ValueKey(brightness),
        reason: '$brightness',
      );

      expect(baseline.toY, 2, reason: '$brightness');
      expect(baseline.rodStackItems, isEmpty, reason: '$brightness');
      expect(baseline.color, MasteryRamp.track(colors), reason: '$brightness');
      expect(baseline.color, isNot(colors.card), reason: '$brightness');
    }
  });

  testWidgets('a dashed guide at the fullest day carries its count; a week of '
      'empty days has none', (tester) async {
    await pumpMx(tester, _chart([_day('M', 10, 0), _day('T', 12, 8)]));

    final guide = _data(tester).extraLinesData.horizontalLines.single;
    expect(guide.y, MxStackedDayBars.barsHeight + _hairline);
    expect(guide.dashArray, isNotEmpty);
    expect(guide.label.show, isTrue);
    expect(guide.label.labelResolver(guide), '20');

    await pumpMx(tester, _chart([_day('M', 0, 0), _day('T', 0, 0)]));

    expect(_data(tester).extraLinesData.horizontalLines, isEmpty);
  });

  testWidgets('a tap on a day shows its words; a tap on another day, a '
      'second tap or a tap outside the chart moves or hides them', (
    tester,
  ) async {
    final days = [_day('M', 3, 1), _day('T', 0, 0), _day('Today', 2, 0)];
    await pumpMx(tester, _chart(days));
    List<int> shown() => [
      for (final group in _data(tester).barGroups)
        if (group.showingTooltipIndicators.isNotEmpty) group.x,
    ];

    expect(shown(), isEmpty);

    // Well above the short bar: the whole column is the day's.
    await _tapColumn(tester, 0, days.length);
    expect(shown(), [0]);
    final tooltip = _data(tester).barTouchData.touchTooltipData;
    final group = _data(tester).barGroups[0];
    expect(
      tooltip.getTooltipItem(group, 0, group.barRods.single, 0)!.text,
      'M: 4 cards',
    );

    // An empty day is a day too.
    await _tapColumn(tester, 1, days.length);
    expect(shown(), [1]);

    await _tapColumn(tester, 1, days.length);
    expect(shown(), isEmpty);

    // Off the chart: the legend.
    await _tapColumn(tester, 2, days.length);
    expect(shown(), [2]);
    await tester.tap(find.text('Learning'));
    await tester.pump();
    expect(shown(), isEmpty);
  });

  testWidgets('a change of data eases in, and is instant when the platform '
      'removes animations', (tester) async {
    for (final (disabled, duration) in [
      (false, Durations.medium2),
      (true, Duration.zero),
    ]) {
      await pumpMx(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: disabled),
            child: _chart([_day('M', 1, 0)]),
          ),
        ),
      );

      expect(
        tester.widget<BarChart>(find.byType(BarChart)).duration,
        duration,
        reason: 'disableAnimations: $disabled',
      );
    }
  });

  testWidgets('each bar is one TalkBack node; labels, guide and legend say '
      'nothing more', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _chart([_day('S', 3, 1), _day('Today', 0, 2, now: true)]),
    );

    expect(find.bySemanticsLabel('S: 4 cards'), findsOneWidget);
    expect(find.bySemanticsLabel('Today: 2 cards'), findsOneWidget);
    expect(find.bySemanticsLabel('Learning'), findsNothing);
    expect(find.bySemanticsLabel('Reviewing'), findsNothing);
    expect(find.bySemanticsLabel('4'), findsNothing);
    handle.dispose();
  });

  testWidgets('the current day is labelled at full strength', (tester) async {
    await pumpMx(
      tester,
      _chart([_day('S', 1, 0), _day('Today', 1, 0, now: true)]),
    );

    final colors = appLightColors;
    expect(
      tester.widget<Text>(find.text('Today')).style!.color,
      colors.foreground,
    );
    expect(
      tester.widget<Text>(find.text('S')).style!.color,
      colors.mutedForeground,
    );
  });
}
