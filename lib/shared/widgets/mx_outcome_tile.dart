import 'package:flutter/material.dart';
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

  /// Lighter than the 12% status tint: on the dialog's surface the
  /// mastered ink reaches 4.6:1 over 8%, but only 4.4:1 over 12% (light).
  static const double _keptTint = 0.08;

  @override
  Widget build(BuildContext context) {
    final derived = context.derivedColors;
    final styles = context.textStyles;
    final (ground, edge, ink) = switch (tone) {
      MxOutcomeTone.kept => (
        context.semanticColors.statusMastered.withValues(alpha: _keptTint),
        derived.ghostBorder,
        derived.statusMasteredInk,
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
