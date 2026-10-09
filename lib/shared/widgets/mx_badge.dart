import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The tone a count carries. There is no streak tone (ruling S1). Mastery is
/// learning progress; success is a right answer or a finished, fine state
/// (critique 2026-09-30 tone pass, T6).
enum MxBadgeTone { primary, mastery, success, warning, danger, neutral }

/// A count pill. The unit belongs inside the label ("23 due"), so the digits
/// stay tabular and the space is part of the text. Omitting a zero count is
/// the caller's call.
class MxBadge extends StatelessWidget {
  const MxBadge({
    super.key,
    required this.label,
    this.tone = MxBadgeTone.primary,
    this.isSolid = false,
    this.isOutlined = false,
    this.icon,
  }) : assert(!(isSolid && isOutlined), 'A badge is solid or outlined.');

  final String label;
  final MxBadgeTone tone;

  /// Emphasis inside a tinted or hero surface.
  final bool isSolid;

  /// Outlined: a label on a ground the tonal pill cannot separate from (a
  /// sheet or a neutral tile; spec 2026-10-08 §4.6 sets no floor for a
  /// container on its ground); the edge is `outline`, the label the tone's
  /// foreground.
  final bool isOutlined;

  /// A 12 glyph before the label, for a counted status (ruling S18).
  final IconData? icon;

  /// A minimum: text scaling grows the pill (ruling S11).
  static const double _height = 22;
  static const double _glyphSize = 12;

  @override
  Widget build(BuildContext context) {
    final (fill, edge, ink) = _roles(context.colors, context.semanticColors);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        border: edge == null
            ? null
            : Border.all(color: edge, width: AppStroke.hairline),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _height),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.micro,
            children: [
              if (icon case final glyph?)
                Icon(glyph, size: _glyphSize, color: ink),
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

  /// The (fill, edge, label) of the variant and tone: outlined has an edge
  /// and no fill.
  (Color?, Color?, Color) _roles(
    ColorScheme colors,
    MxSemanticColors semantic,
  ) {
    return switch ((isOutlined, isSolid, tone)) {
      (false, true, MxBadgeTone.primary) => (
        colors.primary,
        null,
        colors.onPrimary,
      ),
      (false, true, MxBadgeTone.mastery) => (
        semantic.mastery,
        null,
        semantic.onMastery,
      ),
      (false, true, MxBadgeTone.success) => (
        semantic.success,
        null,
        semantic.onSuccess,
      ),
      (false, true, MxBadgeTone.warning) => (
        semantic.warning,
        null,
        semantic.onWarning,
      ),
      (false, true, MxBadgeTone.danger) => (colors.error, null, colors.onError),
      (false, true, MxBadgeTone.neutral) => (
        colors.onSurfaceVariant,
        null,
        colors.surface,
      ),
      (false, false, MxBadgeTone.primary) => (
        colors.primaryContainer,
        null,
        colors.onPrimaryContainer,
      ),
      (false, false, MxBadgeTone.mastery) => (
        semantic.masteryContainer,
        null,
        semantic.onMasteryContainer,
      ),
      (false, false, MxBadgeTone.success) => (
        semantic.successContainer,
        null,
        semantic.onSuccessContainer,
      ),
      (false, false, MxBadgeTone.warning) => (
        semantic.warningContainer,
        null,
        semantic.onWarningContainer,
      ),
      (false, false, MxBadgeTone.danger) => (
        colors.errorContainer,
        null,
        colors.onErrorContainer,
      ),
      (false, false, MxBadgeTone.neutral) => (
        colors.surfaceContainerHigh,
        null,
        colors.onSurfaceVariant,
      ),
      (true, _, MxBadgeTone.primary) => (
        null,
        colors.outline,
        semantic.primaryForeground,
      ),
      (true, _, MxBadgeTone.mastery) => (
        null,
        colors.outline,
        semantic.mastery,
      ),
      (true, _, MxBadgeTone.success) => (
        null,
        colors.outline,
        semantic.success,
      ),
      (true, _, MxBadgeTone.warning) => (
        null,
        colors.outline,
        semantic.warning,
      ),
      (true, _, MxBadgeTone.danger) => (null, colors.outline, colors.error),
      (true, _, MxBadgeTone.neutral) => (
        null,
        colors.outline,
        colors.onSurfaceVariant,
      ),
    };
  }
}
