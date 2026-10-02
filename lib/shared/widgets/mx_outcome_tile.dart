import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

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
    final derived = context.derivedColors;
    final styles = context.textStyles;
    final (ground, edge, ink) = switch (tone) {
      MxOutcomeTone.kept => (
        // Lighter than the 12% status tint: on the dialog's surface the
        // success ink reaches 4.53:1 over 8% (light). Kept is a fine state,
        // so success, not mastery (critique 2026-09-30 tone pass).
        context.semanticColors.success.withValues(alpha: AppOpacity.tintFaint),
        derived.ghostBorder,
        derived.successInk,
      ),
      MxOutcomeTone.lost => (
        derived.warningSoft,
        derived.warningBorder,
        derived.warningInk,
      ),
    };
    return DecoratedBox(
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
            Text(label, style: styles.badgeLabel(ink)),
            Text(body, style: styles.rowDescription),
          ],
        ),
      ),
    );
  }
}
