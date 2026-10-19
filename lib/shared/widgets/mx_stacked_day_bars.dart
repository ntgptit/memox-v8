import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart' show Durations, Easing;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';

/// One day of an MxStackedDayBars: the [top] series stacked over the [base]
/// series, a short label under the bar, and the whole day in words for
/// TalkBack and the tap tooltip.
@immutable
final class MxDayBar {
  const MxDayBar({
    required this.label,
    required this.base,
    required this.top,
    required this.semanticLabel,
    this.isCurrent = false,
  }) : assert(base >= 0 && top >= 0, 'a bar counts from zero');

  /// A narrow weekday, or the current day's word ("Today").
  final String label;
  final int base;
  final int top;

  /// The day and its numbers: "Sunday: 17 cards, 5 learning, 12 reviewing".
  /// TalkBack reads it, and a tap on the bar shows it.
  final String semanticLabel;

  /// Labelled in the full ink; every day's bars draw at full strength
  /// (critique 2026-10-02, F5).
  final bool isCurrent;

  int get total => base + top;
}

/// A week of days as stacked bars (kit 22, FE-A9 D6), drawn with fl_chart:
/// the [MxBarSeries.color] of the top series over the base series, scaled to
/// the fullest day, with the labels under the bars and the legend under the
/// labels (critique 2026-10-19):
/// - a dashed guide at the fullest day carries its number, so the heights
///   read as counts;
/// - a tap anywhere in a day's column shows its [MxDayBar.semanticLabel] in
///   a tooltip above it (it floats over what sits above the chart); a tap on
///   another day moves it, a second tap on the same day or a tap outside the
///   chart hides it;
/// - the two series are parted by a hairline of the card, and a day with any
///   cards keeps each of its parts visible however full the fullest day is;
/// - a day with nothing is a thin baseline;
/// - a change of data eases in, unless the platform removes animations.
///
/// Every day draws at full strength; the current day is told by its label in
/// the full ink (critique 2026-10-02, F5). Each bar is one TalkBack node; the
/// drawing, the guide and the legend say nothing more.
class MxStackedDayBars extends StatefulWidget {
  const MxStackedDayBars({
    super.key,
    required this.days,
    required this.base,
    required this.top,
  }) : assert(days.length > 0, 'a chart has at least one day');

  final List<MxDayBar> days;
  final MxBarSeries base;
  final MxBarSeries top;

  /// The height the fullest day fills.
  static const double barsHeight = 78;

  @override
  State<MxStackedDayBars> createState() => _MxStackedDayBarsState();
}

class _MxStackedDayBarsState extends State<MxStackedDayBars> {
  /// The day whose tooltip shows, or null.
  int? _selected;

  /// True from a tap until the next data: fl_chart eases its whole data,
  /// the shown tooltip too, and a tip must answer the tap at once.
  bool _isTapAnswer = false;

  static const double _emptyHeight = 2;

  @override
  void didUpdateWidget(MxStackedDayBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    _isTapAnswer = false;
    final selected = _selected;
    if (selected == null || selected < widget.days.length) return;
    _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final bars = _layout(context);
    final guideRoom = _guideRoom(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TapRegion(
          // A tap anywhere else on the screen hides the tooltip.
          onTapOutside: (_) => _hideTip(),
          child: SizedBox(
            height: MxStackedDayBars.barsHeight + guideRoom,
            child: Stack(
              // The tooltip floats above the chart's top.
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (context, constraints) => BarChart(
                        // A new chart per brightness: fl_chart eases every
                        // value it is given over its own duration, colours
                        // too, so it would trail ForUI's theme motion.
                        key: ValueKey(context.colors.brightness),
                        _chartData(
                          context,
                          bars,
                          chartWidth: constraints.maxWidth,
                          maxY:
                              math.max(
                                MxStackedDayBars.barsHeight,
                                bars.tallest,
                              ) +
                              guideRoom,
                          columnHeight: constraints.maxHeight,
                        ),
                        duration:
                            _isTapAnswer ||
                                MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : Durations.medium2,
                        curve: Easing.standardDecelerate,
                      ),
                    ),
                  ),
                ),
                // One TalkBack node per day over its column; it holds no
                // pointer, so a tap reaches the chart under it.
                Positioned.fill(
                  child: Row(
                    children: [
                      for (final day in widget.days)
                        Expanded(
                          child: Semantics(
                            label: day.semanticLabel,
                            excludeSemantics: true,
                            child: const SizedBox.expand(),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: dimens.space4),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final day in widget.days)
                // Each label is centred in its day's column, as fl_chart
                // centres the bar (`spaceAround`). A label wider than its
                // column, such as "Today", shrinks to fit rather than lose
                // letters.
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: dimens.space4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        day.label,
                        maxLines: 1,
                        // The current day reads in the full ink; the weight
                        // is the role's, so colour carries the distinction.
                        style: context.texts.meta.copyWith(
                          color: day.isCurrent
                              ? context.colors.foreground
                              : context.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: dimens.space12),
        MxChartLegend(series: [widget.top, widget.base]),
      ],
    );
  }

  void _hideTip() {
    if (_selected == null) return;
    setState(() {
      _selected = null;
      _isTapAnswer = true;
    });
  }

  /// The room above the fullest day for the guide's number: one line of the
  /// `meta` role at the platform's text scale.
  double _guideRoom(BuildContext context) {
    final meta = context.texts.meta;
    final fontSize = MediaQuery.textScalerOf(context).scale(meta.fontSize!);
    return fontSize * (meta.height ?? 1);
  }

  /// Each day's parts in logical pixels: the fullest day fills
  /// [MxStackedDayBars.barsHeight], a part with any cards is at least
  /// `sizeTrack` tall, and the hairline between two parts is extra.
  _Bars _layout(BuildContext context) {
    final most = widget.days.map((day) => day.total).fold(0, math.max);
    final gap = context.hairline;
    final minPart = context.dimens.sizeTrack;
    final unit = (MxStackedDayBars.barsHeight - gap) / math.max(most, 1);
    double part(int count) => count == 0 ? 0 : math.max(count * unit, minPart);
    final days = [
      for (final day in widget.days)
        (
          base: part(day.base),
          gap: day.base > 0 && day.top > 0 ? gap : 0.0,
          top: part(day.top),
        ),
    ];
    final tallest = days
        .map((day) => day.base + day.gap + day.top)
        .fold(0.0, math.max);
    return _Bars(days: days, most: most, tallest: tallest);
  }

  BarChartData _chartData(
    BuildContext context,
    _Bars bars, {
    required double chartWidth,
    required double maxY,
    required double columnHeight,
  }) {
    final colors = context.colors;
    final round = context.radii.xs2.topLeft;
    final rodWidth = chartWidth / widget.days.length - context.dimens.space8;
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: maxY,
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      extraLinesData: ExtraLinesData(
        // Behind the bars, so the fullest day's top is never dashed.
        extraLinesOnTop: false,
        horizontalLines: [
          // Nothing to measure in a week of empty days.
          if (bars.most > 0) _guide(context, bars),
        ],
      ),
      barTouchData: _touchData(context, chartWidth, columnHeight),
      barGroups: [
        for (final (index, day) in bars.days.indexed)
          BarChartGroupData(
            x: index,
            showingTooltipIndicators: [if (index == _selected) 0],
            barRods: [
              if (day.base + day.top == 0)
                BarChartRodData(
                  toY: _emptyHeight,
                  width: rodWidth,
                  color: MasteryRamp.track(colors),
                  borderRadius: BorderRadius.circular(_emptyHeight / 2),
                )
              else
                BarChartRodData(
                  toY: day.base + day.gap + day.top,
                  width: rodWidth,
                  // The rod shows only between the parts: the card's
                  // hairline. Its corners round the stack as a whole.
                  color: colors.card,
                  borderRadius: BorderRadius.all(round),
                  rodStackItems: [
                    if (day.base > 0)
                      BarChartRodStackItem(0, day.base, widget.base.color),
                    if (day.top > 0)
                      BarChartRodStackItem(
                        day.base + day.gap,
                        day.base + day.gap + day.top,
                        widget.top.color,
                      ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  HorizontalLine _guide(BuildContext context, _Bars bars) {
    final count = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    ).format(bars.most);
    return HorizontalLine(
      // A hairline above the fullest day's top, so no dash lies on it.
      y: bars.tallest + context.hairline,
      color: context.colors.border,
      strokeWidth: context.hairline,
      dashArray: [context.dimens.space4.toInt(), context.dimens.space4.toInt()],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        padding: EdgeInsets.zero,
        style: context.texts.meta.copyWith(
          color: context.colors.mutedForeground,
        ),
        labelResolver: (_) => count,
      ),
    );
  }

  BarTouchData _touchData(
    BuildContext context,
    double chartWidth,
    double columnHeight,
  ) {
    final tooltip = FTheme.of(context).tooltipStyle;
    return BarTouchData(
      handleBuiltInTouches: false,
      // The rods leave `space8` between them; half of it on each side, and
      // the whole height above each bar, make the columns tile the chart, so
      // every tap lands on a day.
      touchExtraThreshold: EdgeInsets.only(
        left: context.dimens.space4,
        right: context.dimens.space4,
        top: columnHeight,
      ),
      touchCallback: (event, response) {
        if (event is! FlTapUpEvent) return;
        final touched = response?.spot?.touchedBarGroupIndex;
        setState(() {
          _selected = touched == _selected ? null : touched;
          _isTapAnswer = true;
        });
      },
      touchTooltipData: BarTouchTooltipData(
        // ForUI's tooltip: the foreground as ground, the page as ink.
        getTooltipColor: (_) => context.colors.foreground,
        tooltipBorderRadius: context.radii.md,
        tooltipPadding: tooltip.padding,
        tooltipMargin: context.dimens.space4,
        // Above the day it names, never over it, and as wide as the chart:
        // the tip floats past the chart's top onto what sits above it (the
        // Today card's figure and line).
        direction: TooltipDirection.top,
        maxContentWidth: chartWidth - tooltip.padding.horizontal,
        fitInsideHorizontally: true,
        getTooltipItem: (_, groupIndex, _, _) => BarTooltipItem(
          widget.days[groupIndex].semanticLabel,
          tooltip.textStyle,
        ),
      ),
    );
  }
}

/// The parts of every day, in logical pixels, and the count of the fullest.
final class _Bars {
  const _Bars({required this.days, required this.most, required this.tallest});

  final List<({double base, double gap, double top})> days;
  final int most;

  /// The drawn height of the tallest day, where the guide sits.
  final double tallest;
}
