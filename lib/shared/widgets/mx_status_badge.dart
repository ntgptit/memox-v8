import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The card lifecycle, in order.
enum MxCardStatus { newCard, learning, reviewing, mastered }

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
  static const double _tint = 0.12;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final color = switch (status) {
      MxCardStatus.newCard => semantic.statusNew,
      MxCardStatus.learning => semantic.statusLearning,
      MxCardStatus.reviewing => semantic.statusReviewing,
      MxCardStatus.mastered => semantic.statusMastered,
    };
    final derived = context.derivedColors;
    // The label reads in the status ink (AA); dot and fill keep the colour.
    final ink = switch (status) {
      MxCardStatus.newCard => derived.statusNewInk,
      MxCardStatus.learning => derived.statusLearningInk,
      MxCardStatus.reviewing => derived.statusReviewingInk,
      MxCardStatus.mastered => derived.statusMasteredInk,
    };
    if (isDot) {
      return Semantics(
        container: true,
        label: label,
        child: _Dot(color: color, size: _bareDot),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: _tint),
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
              _Dot(color: color, size: _pillDot),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: context.textStyles.badgeLabel(ink),
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
