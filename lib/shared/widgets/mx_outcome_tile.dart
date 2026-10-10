import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_soft_ground.dart';

/// What an outcome keeps or loses (the reset dialog of screen 02, D-O2).
enum MxOutcomeTone { kept, lost }

/// A labelled consequence on a soft ground (spec 2026-10-10 D4): the label in
/// its tone's on-soft token, the body under it. "Kept" is the success soft
/// ground, "Lost" the warning soft ground.
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

  /// Kept is a fine state, so success, not mastery (critique 2026-09-30 tone
  /// pass, final review).
  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final styles = context.textStyles;
    // A soft ground, light in both themes (spec 2026-10-10 D4).
    final (ground, edge, foreground) = switch (tone) {
      MxOutcomeTone.kept => (
        semantic.successSoft,
        semantic.successBorder,
        semantic.onSuccessSoft,
      ),
      MxOutcomeTone.lost => (
        semantic.warningSoft,
        semantic.warningBorder,
        semantic.onWarningSoft,
      ),
    };
    return MxSoftGround(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: edge, width: AppStroke.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.grouped),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(label, style: styles.badgeLabel(foreground)),
            // Day's description style, read from inside the ground.
            Builder(
              builder: (day) =>
                  Text(body, style: day.textStyles.rowDescription),
            ),
          ],
        ),
      ),
    );
  }
}
