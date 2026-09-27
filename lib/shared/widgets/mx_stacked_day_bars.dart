import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// One series of an MxStackedDayBars: its legend label and its fill.
@immutable
final class MxBarSeries {
  const MxBarSeries({required this.label, required this.color});

  final String label;
  final Color color;
}

/// One day of an MxStackedDayBars: the [top] series stacked over the [base]
/// series, a short label under the bar, and the whole day in words for
/// TalkBack.
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
  final String semanticLabel;

  /// Drawn at full strength, with a bold label.
  final bool isCurrent;

  int get total => base + top;
}

/// A week of days as stacked bars (kit 22, FE-A9 D6): the [MxBarSeries.color]
/// of the top series over the base series, scaled to the fullest day, with
/// the labels under the bars and the legend under the labels. A day with
/// nothing is a thin baseline. Each bar is one TalkBack node; the drawing
/// and the legend say nothing more.
class MxStackedDayBars extends StatelessWidget {
  const MxStackedDayBars({
    super.key,
    required this.days,
    required this.base,
    required this.top,
  }) : assert(days.length > 0, 'a chart has at least one day');

  final List<MxDayBar> days;
  final MxBarSeries base;
  final MxBarSeries top;

  static const double _chartHeight = 78;
  static const double _emptyHeight = 2;
  static const double _legendDot = 6;

  /// The kit's fades of the days before the current one.
  static const double _pastBaseOpacity = 0.55;
  static const double _pastTopOpacity = 0.7;

  @override
  Widget build(BuildContext context) {
    final most = days.map((day) => day.total).fold(1, math.max);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _chartHeight,
          child: Row(
            spacing: AppSpacing.control,
            children: [
              for (final day in days) Expanded(child: _bar(context, day, most)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.micro),
        ExcludeSemantics(
          child: Row(
            spacing: AppSpacing.control,
            children: [
              for (final day in days)
                // A label wider than its bar, such as "Today", shrinks to
                // fit rather than lose letters.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day.label,
                      maxLines: 1,
                      style: context.textStyles.dayLabel(
                        isCurrent: day.isCurrent,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        ExcludeSemantics(
          child: Wrap(
            spacing: AppSpacing.grouped,
            runSpacing: AppSpacing.micro,
            children: [_legend(context, top), _legend(context, base)],
          ),
        ),
      ],
    );
  }

  Widget _bar(BuildContext context, MxDayBar day, int most) => Semantics(
    label: day.semanticLabel,
    excludeSemantics: true,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final unit = constraints.maxHeight / most;
        const round = Radius.circular(AppRadius.xs);
        final topFade = day.isCurrent ? 1.0 : _pastTopOpacity;
        final baseFade = day.isCurrent ? 1.0 : _pastBaseOpacity;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (day.total == 0)
              Container(
                height: _emptyHeight,
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHigh,
                  borderRadius: const BorderRadius.all(round),
                ),
              ),
            if (day.top > 0)
              Container(
                height: day.top * unit,
                decoration: BoxDecoration(
                  color: top.color.withValues(alpha: topFade),
                  borderRadius: const BorderRadius.vertical(top: round),
                ),
              ),
            if (day.base > 0)
              Container(
                height: day.base * unit,
                decoration: BoxDecoration(
                  color: base.color.withValues(alpha: baseFade),
                  borderRadius: day.top > 0
                      ? const BorderRadius.vertical(bottom: round)
                      : const BorderRadius.all(round),
                ),
              ),
          ],
        );
      },
    ),
  );

  Widget _legend(BuildContext context, MxBarSeries series) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.micro,
    children: [
      Container(
        width: _legendDot,
        height: _legendDot,
        decoration: BoxDecoration(color: series.color, shape: BoxShape.circle),
      ),
      Text(series.label, style: context.textStyles.dayLabel(isCurrent: false)),
    ],
  );
}
