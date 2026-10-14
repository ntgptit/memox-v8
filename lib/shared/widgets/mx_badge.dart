import 'package:flutter/material.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

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
    final toneColor = switch (tone) {
      MxBadgeTone.primary => colors.primary,
      MxBadgeTone.mastery => context.mxColors.successContainer,
      MxBadgeTone.success => context.mxColors.success,
      MxBadgeTone.warning => context.mxColors.warningContainer,
      MxBadgeTone.danger => colors.error,
      // Ruling S2: the contract names no neutral colour.
      MxBadgeTone.neutral => colors.onSurfaceVariant,
    };
    // Ruling S3: tonal warning text reads in warning-ink, because the amber
    // fails as 12px text on a light surface; the mastery green likewise
    // reads in its ink (3.56:1 on its tint in light, FE-C1).
    final ink = switch ((isSolid, tone)) {
      (true, _) => colors.onPrimary,
      (false, MxBadgeTone.warning) => context.mxColors.warning,
      (false, MxBadgeTone.primary) => context.accentColor,
      (false, MxBadgeTone.mastery) => context.mxColors.success,
      (false, MxBadgeTone.success) => context.mxColors.success,
      (false, _) => toneColor,
    };
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: isSolid ? toneColor : toneColor.tintOver(MxTintBase.of(context)),
        shape: const StadiumBorder(),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _height),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: context.dimens.space8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: context.dimens.space4,
            children: [
              if (icon case final glyph?)
                Icon(glyph, size: _glyphSize, color: ink),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: context.texts.labelSmall?.copyWith(color: ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
