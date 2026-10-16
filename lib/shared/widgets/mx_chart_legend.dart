import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One series of a chart: its legend label and its fill.
@immutable
final class MxBarSeries {
  const MxBarSeries({required this.label, required this.color});

  final String label;
  final Color color;
}

/// A chart's legend: a dot of each series' colour beside its label, wrapping
/// at the column's edge. The chart's own nodes tell TalkBack what each mark
/// is, so the legend says nothing to it.
class MxChartLegend extends StatelessWidget {
  const MxChartLegend({super.key, required this.series});

  final List<MxBarSeries> series;

  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return ExcludeSemantics(
      child: Wrap(
        spacing: dimens.space12,
        runSpacing: dimens.space4,
        children: [for (final entry in series) _entry(context, entry)],
      ),
    );
  }

  Widget _entry(BuildContext context, MxBarSeries entry) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: context.dimens.space4,
    children: [
      Container(
        width: _dot,
        height: _dot,
        decoration: BoxDecoration(color: entry.color, shape: BoxShape.circle),
      ),
      Text(
        entry.label,
        style: context.texts.labelSmall?.copyWith(
          color: context.colors.onSurfaceVariant,
        ),
      ),
    ],
  );
}
