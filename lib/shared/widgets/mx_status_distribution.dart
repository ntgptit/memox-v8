import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';

/// How many cards sit in each display state.
final class MxStatusCounts {
  const MxStatusCounts({
    required this.newCards,
    required this.learning,
    required this.reviewing,
    required this.mastered,
  });

  final int newCards;
  final int learning;
  final int reviewing;
  final int mastered;

  int of(MxCardStatus status) => switch (status) {
    MxCardStatus.newCard => newCards,
    MxCardStatus.learning => learning,
    MxCardStatus.reviewing => reviewing,
    MxCardStatus.mastered => mastered,
  };

  int get total => newCards + learning + reviewing + mastered;
}

/// A deck's cards by display state (screen 07, spec A13): one stacked bar,
/// each state a segment in its colour sized by its count, then a legend of
/// dots, names and counts. A state with no card draws no segment; an empty
/// deck draws the track alone.
class MxStatusDistribution extends StatelessWidget {
  const MxStatusDistribution({
    super.key,
    required this.counts,
    required this.label,
  });

  final MxStatusCounts counts;

  /// The state's name, from the caller's copy.
  final String Function(MxCardStatus status) label;

  static const double _barHeight = 6;
  static const double _dot = 6;

  @override
  Widget build(BuildContext context) {
    final present = [
      for (final status in MxCardStatus.values)
        if (counts.of(status) > 0) status,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.control,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: _barHeight,
            child: ColoredBox(
              color: context.colors.surfaceContainer,
              child: Row(
                children: [
                  for (final status in present)
                    Expanded(
                      key: ValueKey(('segment', status)),
                      flex: counts.of(status),
                      child: ColoredBox(color: mxStatusColor(context, status)),
                    ),
                ],
              ),
            ),
          ),
        ),
        Wrap(
          spacing: AppSpacing.grouped,
          runSpacing: AppSpacing.micro,
          children: [
            for (final status in MxCardStatus.values)
              _LegendItem(
                color: mxStatusColor(context, status),
                label: label(status),
                count: counts.of(status),
              ),
          ],
        ),
      ],
    );
  }
}

/// A dot, the state's name and its count, as one TalkBack node.
class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    final locale = Localizations.localeOf(context).toLanguageTag();
    return MergeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.micro,
        children: [
          SizedBox.square(
            dimension: MxStatusDistribution._dot,
            child: DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Text(label, style: styles.workloadText),
          Text(
            NumberFormat.decimalPattern(locale).format(count),
            style: styles.workloadTerm(context.colors.onSurface),
          ),
        ],
      ),
    );
  }
}
