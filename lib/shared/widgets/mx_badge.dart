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
  }) : assert(
         !isSolid || tone == MxBadgeTone.primary,
         'a solid badge is primary: only onPrimary is guaranteed on its fill',
       );

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
    // A tonal badge sits on its tone's soft ground and reads its on-soft
    // token (spec 2026-10-10 §5.3); a solid badge is primary.
    final (ground, foreground) = switch ((isSolid, tone)) {
      (true, _) => (colors.primary, colors.onPrimary),
      (false, MxBadgeTone.primary) => (
        semantic.primarySoft,
        semantic.onPrimarySoft,
      ),
      (false, MxBadgeTone.mastery) => (
        semantic.successSoft,
        semantic.onSuccessSoft,
      ),
      (false, MxBadgeTone.success) => (
        semantic.successSoft,
        semantic.onSuccessSoft,
      ),
      (false, MxBadgeTone.warning) => (
        semantic.warningSoft,
        semantic.onWarningSoft,
      ),
      (false, MxBadgeTone.danger) => (
        semantic.dangerSoft,
        semantic.onDangerSoft,
      ),
      (false, MxBadgeTone.neutral) => (
        semantic.neutralSoft,
        semantic.onNeutralSoft,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
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
                Icon(glyph, size: _glyphSize, color: foreground),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: context.textStyles.badgeLabel(foreground),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
