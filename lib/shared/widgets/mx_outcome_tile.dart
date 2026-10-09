import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';

/// What an outcome keeps or loses (the reset dialog of screen 02, D-O2).
enum MxOutcomeTone { kept, lost }

/// A labelled consequence: the label and the body in the on-colour of the
/// tone's container. "Kept" is the success container, "Lost" the warning
/// container; both read 4.5:1 on their ground.
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
    final semantic = context.semanticColors;
    final styles = context.textStyles;
    // A container, no edge; every line reads in its on-container.
    final (ground, ink) = switch (tone) {
      MxOutcomeTone.kept => (
        semantic.successContainer,
        semantic.onSuccessContainer,
      ),
      MxOutcomeTone.lost => (
        semantic.warningContainer,
        semantic.onWarningContainer,
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ground,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.grouped),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.micro,
          children: [
            Text(label, style: styles.badgeLabel(ink)),
            Text(body, style: styles.rowDescription.copyWith(color: ink)),
          ],
        ),
      ),
    );
  }
}
