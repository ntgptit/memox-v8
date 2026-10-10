import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_soft_ground.dart';

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
