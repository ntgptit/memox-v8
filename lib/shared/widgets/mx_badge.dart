import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The tone a count carries. There is no streak tone (ruling S1).
enum MxBadgeTone { primary, mastery, warning, danger, neutral }

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
  static const double _tint = 0.12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final toneColor = switch (tone) {
      MxBadgeTone.primary => colors.primary,
      MxBadgeTone.mastery => context.semanticColors.mastery,
      MxBadgeTone.warning => context.semanticColors.warning,
      MxBadgeTone.danger => colors.error,
      // Ruling S2: the contract names no neutral colour.
      MxBadgeTone.neutral => colors.onSurfaceVariant,
    };
    // Ruling S3: tonal warning text reads in warning-ink, because the amber
    // fails as 12px text on a light surface.
    final ink = switch ((isSolid, tone)) {
      (true, _) => colors.onPrimary,
      (false, MxBadgeTone.warning) => context.derivedColors.warningInk,
      (false, _) => toneColor,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSolid ? toneColor : toneColor.withValues(alpha: _tint),
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
