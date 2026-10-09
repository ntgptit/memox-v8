import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The card lifecycle, in order.
enum MxCardStatus { newCard, learning, reviewing, mastered }

/// The one place a card status becomes colour (spec 2026-10-08 §4.7): the
/// fill of a dot or a bar, the foreground of text on a neutral ground, the
/// tonal ground of a pill and the text on it. The status badge, the card
/// row, the workload line and the Progress rows all read these.
extension MxCardStatusColors on MxCardStatus {
  Color fill(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.outline,
    MxCardStatus.learning => context.semanticColors.warning,
    MxCardStatus.reviewing => context.colors.primary,
    MxCardStatus.mastered => context.semanticColors.mastery,
  };

  Color foreground(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.onSurfaceVariant,
    MxCardStatus.learning => context.semanticColors.warning,
    MxCardStatus.reviewing => context.semanticColors.primaryForeground,
    MxCardStatus.mastered => context.semanticColors.mastery,
  };

  Color container(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.surfaceContainerHigh,
    MxCardStatus.learning => context.semanticColors.warningContainer,
    MxCardStatus.reviewing => context.colors.primaryContainer,
    MxCardStatus.mastered => context.semanticColors.masteryContainer,
  };

  Color onContainer(BuildContext context) => switch (this) {
    MxCardStatus.newCard => context.colors.onSurfaceVariant,
    MxCardStatus.learning => context.semanticColors.onWarningContainer,
    MxCardStatus.reviewing => context.colors.onPrimaryContainer,
    MxCardStatus.mastered => context.semanticColors.onMasteryContainer,
  };
}

/// Names a card's lifecycle state; a Badge counts things. The status fixes
/// the colour. The caller passes the localized name (ruling S6), which the
/// bare dot uses as its semantics label.
class MxStatusBadge extends StatelessWidget {
  const MxStatusBadge({
    super.key,
    required this.status,
    required this.label,
    this.isDot = false,
  });

  final MxCardStatus status;
  final String label;

  /// The bare 8 indicator for dense card rows.
  final bool isDot;

  /// A minimum: text scaling grows the pill (ruling S11).
  static const double _height = 22;
  static const double _pillDot = 6;
  static const double _bareDot = 8;

  /// The dot sits closer to the start edge than the label to the end edge.
  static const double _startPadding = 6;

  @override
  Widget build(BuildContext context) {
    if (isDot) {
      return Semantics(
        container: true,
        label: label,
        child: _Dot(color: status.fill(context), size: _bareDot),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status.container(context),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _height),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: _startPadding,
            end: AppSpacing.control,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              _Dot(color: status.fill(context), size: _pillDot),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: context.textStyles.badgeLabel(
                  status.onContainer(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: DecoratedBox(
      key: const ValueKey('mx-status-dot'),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
