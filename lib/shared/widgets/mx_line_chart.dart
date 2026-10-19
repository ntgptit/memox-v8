import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_scroll_fade.dart';

/// One point of an [MxLineChart]: its value and the short label under it.
@immutable
final class MxLinePoint {
  const MxLinePoint({required this.value, required this.label})
    : assert(value >= 0, 'a point counts from zero');

  final double value;
  final String label;
}

/// A line of values from 0 to [maxValue], oldest first (follow-ups spec G8),
/// drawn with fl_chart:
/// - one column per point, at least `sizeControl` wide: a few points stretch
///   to the width, more scroll sideways and open at the newest, the edge
///   fading while more lies past it;
/// - the line and its dots in the accent fill, over a `border` baseline,
///   under a dashed guide at [maxValue] carrying [maxLabel] at the newest
///   end, where the scroll opens; a room above the guide keeps a dot at the
///   maximum and the label inside the scroll's clip;
/// - the label under each point; no number on a point, which the caller
///   says elsewhere (screen 36's one number per element).
///
/// TalkBack gets one node, [semanticLabel]; the chart is hidden from it. It
/// does not animate: the chart is a result, and fl_chart would ease the
/// colours behind a theme change.
class MxLineChart extends StatelessWidget {
  const MxLineChart({
    super.key,
    required this.points,
    required this.maxValue,
    required this.maxLabel,
    required this.semanticLabel,
    this.ground = MxScrollFadeGround.page,
  }) : assert(maxValue > 0, 'a line needs a range');

  final List<MxLinePoint> points;
  final double maxValue;

  /// [maxValue] in words, beside its guide: the scale, so a point's height
  /// reads against it.
  final String maxLabel;
  final String semanticLabel;

  /// What the chart sits on, for the edge fade: `raised` inside a card.
  final MxScrollFadeGround ground;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    final plot = dimens.sizeControl * 2;
    final meta = context.texts.meta.copyWith(
      color: context.colors.mutedForeground,
    );
    // Above the guide: the label's line, which also holds a dot at the
    // maximum (its radius is less than a line).
    final room = meta.fontSize! * (meta.height ?? 1);
    return Semantics(
      container: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cell = (constraints.maxWidth / points.length).clamp(
            dimens.sizeControl,
            double.infinity,
          );
          return MxScrollFade(
            axis: Axis.horizontal,
            ground: ground,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // The newest point is the one to see first.
              reverse: true,
              child: SizedBox(
                width: cell * points.length,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: dimens.space4,
                  children: [
                    SizedBox(
                      height: plot + room,
                      // fl_chart's x axis does not follow the text direction;
                      // the labels' row must not either.
                      child: LineChart(
                        _data(context, top: maxValue * (plot + room) / plot),
                        duration: Duration.zero,
                      ),
                    ),
                    Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        for (final point in points)
                          SizedBox(
                            width: cell,
                            child: Text(
                              point.label,
                              style: meta,
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// The points centred in their columns: x runs half a column past each
  /// end.
  LineChartData _data(BuildContext context, {required double top}) {
    final dimens = context.dimens;
    final ink = context.status.accentFill;
    return LineChartData(
      minX: -0.5,
      maxX: points.length - 0.5,
      minY: 0,
      // The guide at [maxValue] sits the label's room below the top.
      maxY: top,
      titlesData: const FlTitlesData(show: false),
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(
            color: context.colors.border,
            width: context.hairline,
          ),
        ),
      ),
      lineTouchData: const LineTouchData(enabled: false),
      extraLinesData: ExtraLinesData(
        extraLinesOnTop: false,
        horizontalLines: [
          HorizontalLine(
            y: maxValue,
            color: context.colors.border,
            strokeWidth: context.hairline,
            dashArray: [dimens.space4.toInt(), dimens.space4.toInt()],
            label: HorizontalLineLabel(
              show: true,
              // Above the line at the newest end, where the scroll opens.
              alignment: Alignment.topRight,
              padding: EdgeInsets.zero,
              style: context.texts.meta.copyWith(
                color: context.colors.mutedForeground,
              ),
              labelResolver: (_) => maxLabel,
            ),
          ),
        ],
      ),
      // The dots sit on the plot's edges at 0 and at the maximum.
      clipData: const FlClipData.none(),
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (final (index, point) in points.indexed)
              FlSpot(index.toDouble(), point.value),
          ],
          color: ink,
          barWidth: dimens.strokeEmphasis,
          dotData: FlDotData(
            getDotPainter: (_, _, _, _) =>
                FlDotCirclePainter(radius: dimens.space4, color: ink),
          ),
        ),
      ],
    );
  }
}
