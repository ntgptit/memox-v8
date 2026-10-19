import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_chart_legend.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

/// One bar of an [MxBarChart]: its value, its fill, the mark under it (a
/// second channel besides colour) and its short label.
@immutable
final class MxBar {
  const MxBar({
    required this.value,
    required this.color,
    required this.marker,
    required this.label,
    this.cellKey,
  }) : assert(value >= 0, 'a bar counts from zero');

  final double value;
  final Color color;
  final Widget marker;
  final String label;

  /// A key on the bar's cell, for finding it.
  final Key? cellKey;
}

/// A row of bars that scrolls sideways (audit 2026-10-19, G4), drawn with
/// fl_chart:
/// - one `sizeControl` cell per bar, the bar a `space12` rod centred in it,
///   scaled to the largest value, a value of 0 a `space4` stub;
/// - the marker and the label under each bar;
/// - a dashed guide at the largest value carrying [guideLabel];
/// - the whole cell a control-wide [MxRowInk] that calls [onOpen] with the
///   bar's index;
/// - the edge fades while more lies past it;
/// - the [legend] under it.
///
/// TalkBack gets one node, [semanticLabel], for the whole chart; the bars are
/// hidden from it, so the caller gives each bar another way in (screen 38's
/// answer rows, ruling S4). The bars do not animate: the chart is a result,
/// and fl_chart would ease the colours behind a theme change.
class MxBarChart extends StatelessWidget {
  const MxBarChart({
    super.key,
    required this.bars,
    required this.legend,
    required this.semanticLabel,
    required this.onOpen,
    this.guideLabel,
  });

  final List<MxBar> bars;
  final List<MxBarSeries> legend;
  final String semanticLabel;
  final ValueChanged<int> onOpen;

  /// The largest value in words, beside the guide; null draws no guide.
  final String? guideLabel;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final cell = dimens.sizeControl;
    final plot = dimens.sizeControl * 2;
    final largest = bars.map((bar) => bar.value).fold(0.0, math.max);
    final guide = largest > 0 ? guideLabel : null;
    final meta = context.texts.meta;
    final guideRoom = meta.fontSize! * (meta.height ?? 1);
    final chartHeight = plot + guideRoom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: dimens.space12,
      children: [
        Semantics(
          container: true,
          label: semanticLabel,
          excludeSemantics: true,
          child: MxScrollFade(
            axis: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: cell * bars.length,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: chartHeight,
                      child: BarChart(
                        _data(
                          context,
                          largest: largest,
                          plot: plot,
                          maxY: chartHeight,
                          guide: guide,
                        ),
                        duration: Duration.zero,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final (index, bar) in bars.indexed)
                          MxRowInk(
                            onTap: () => onOpen(index),
                            borderRadius: context.radii.sm,
                            child: SizedBox(
                              key: bar.cellKey,
                              width: cell,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                spacing: dimens.space4,
                                children: [
                                  SizedBox(height: chartHeight),
                                  bar.marker,
                                  Text(
                                    bar.label,
                                    style: meta.copyWith(
                                      color: context.colors.mutedForeground,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        MxChartLegend(series: legend),
      ],
    );
  }

  /// The bars in logical pixels: the largest fills [plot], a 0 is a stub.
  BarChartData _data(
    BuildContext context, {
    required double largest,
    required double plot,
    required double maxY,
    required String? guide,
  }) {
    final dimens = context.dimens;
    final unit = largest > 0 ? plot / largest : 0.0;
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      minY: 0,
      maxY: maxY,
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      // The cells over the chart take the taps.
      barTouchData: const BarTouchData(enabled: false),
      extraLinesData: ExtraLinesData(
        // Behind the bars, a hairline above the largest one's top.
        extraLinesOnTop: false,
        horizontalLines: [
          if (guide != null)
            HorizontalLine(
              y: plot + context.hairline,
              color: context.colors.border,
              strokeWidth: context.hairline,
              dashArray: [dimens.space4.toInt(), dimens.space4.toInt()],
              label: HorizontalLineLabel(
                show: true,
                // At the start, where the scroll opens.
                alignment: Alignment.topLeft,
                padding: EdgeInsets.zero,
                style: context.texts.meta.copyWith(
                  color: context.colors.mutedForeground,
                ),
                labelResolver: (_) => guide,
              ),
            ),
        ],
      ),
      barGroups: [
        for (final (index, bar) in bars.indexed)
          BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: math.max(dimens.space4, bar.value * unit),
                width: dimens.space12,
                color: bar.color,
                borderRadius: context.radii.xs2,
              ),
            ],
          ),
      ],
    );
  }
}
