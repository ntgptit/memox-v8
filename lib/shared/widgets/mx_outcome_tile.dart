import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/color_tint.dart';

/// What an outcome keeps or loses (the reset dialog of screen 02, D-O2).
enum MxOutcomeTone { kept, lost }

/// A labelled consequence: the label in its tone's ink over its tint, and
/// the body under it. "Kept" uses the mastered ink (spec A10), "Lost" the
/// warning ink; both reach 4.5:1 on their ground.
class MxOutcomeTile extends StatelessWidget {
  const MxOutcomeTile({
    super.key,
    required this.label,
    required this.body,
    required this.tone,
  });

  final String label;
  final String body;
  final MxOutcomeTone tone;

  /// Lighter than the 12% status tint: on the dialog's surface the success
  /// ink reaches 4.53:1 over 8% (light). Kept is a fine state, so success,
  /// not mastery (critique 2026-09-30 tone pass, final review).
  static const double _keptTint = 0.08;

  @override
  Widget build(BuildContext context) {
    final (ground, edge, ink) = switch (tone) {
      MxOutcomeTone.kept => (
        context.mxColors.success.withValues(alpha: _keptTint),
        context.colors.outlineVariant,
        context.mxColors.success,
      ),
      MxOutcomeTone.lost => (
        context.mxColors.warning.tintOver(context.colors.surface),
        context.mxColors.warning,
        context.mxColors.warning,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(context.dimens.radiusMd),
        border: Border.all(color: edge, width: context.dimens.strokeHairline),
      ),
      child: Padding(
        padding: EdgeInsets.all(context.dimens.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: context.dimens.space4,
          children: [
            Text(label, style: context.texts.labelSmall?.copyWith(color: ink)),
            Text(
              body,
              style: context.texts.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
