import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

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

  @override
  Widget build(BuildContext context) {
    final (ground, edge, ink) = switch (tone) {
      MxOutcomeTone.kept => (
        context.mxColors.success.tintOver(MxTintBase.of(context)),
        context.colors.outlineVariant,
        context.mxColors.success,
      ),
      MxOutcomeTone.lost => (
        context.mxColors.warning.tintOver(MxTintBase.of(context)),
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
