import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
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
    this.icon,
  });

  final String label;
  final MxBadgeTone tone;

  /// Emphasis inside a tinted or hero surface.
  final bool isSolid;

  /// A 12 glyph before the label, for a counted status (ruling S18).
  final IconData? icon;

  /// A minimum: text scaling grows the pill (ruling S11).
  static const double _height = 22;
  static const double _glyphSize = 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    final (fill, ink) = switch ((isSolid, tone)) {
      (true, MxBadgeTone.primary) => (colors.primary, colors.onPrimary),
      (true, MxBadgeTone.mastery) => (semantic.mastery, semantic.onMastery),
      (true, MxBadgeTone.success) => (semantic.success, semantic.onSuccess),
      (true, MxBadgeTone.warning) => (semantic.warning, semantic.onWarning),
      (true, MxBadgeTone.danger) => (colors.error, colors.onError),
      (true, MxBadgeTone.neutral) => (colors.onSurfaceVariant, colors.surface),
      (false, MxBadgeTone.primary) => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      (false, MxBadgeTone.mastery) => (
        semantic.masteryContainer,
        semantic.onMasteryContainer,
      ),
      (false, MxBadgeTone.success) => (
        semantic.successContainer,
        semantic.onSuccessContainer,
      ),
      (false, MxBadgeTone.warning) => (
        semantic.warningContainer,
        semantic.onWarningContainer,
      ),
      (false, MxBadgeTone.danger) => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      (false, MxBadgeTone.neutral) => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
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
}
