import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// One face of the card under study (kit StudyFaceCard): the label in the
/// corner, the content centred, and a recessed ground when it is the answer.
/// It shows the whole face: it scrolls, never ellipsizes (FE-A6 D19). A tap
/// on it is a shortcut only; the screen's button is the accessible path.
class StudyFaceCardWidget extends StatelessWidget {
  const StudyFaceCardWidget({
    super.key,
    required this.label,
    required this.child,
    this.isAnswer = false,
    this.onTap,
  });

  final String label;
  final Widget child;
  final bool isAnswer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = MxCard(
      isFullBleed: true,
      isRecessed: isAnswer,
      child: Stack(
        children: [
          Positioned(
            top: AppSpacing.gutter,
            left: AppSpacing.card,
            child: Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: context.textStyles.overline,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                AppSpacing.major,
                AppSpacing.gutter,
                AppSpacing.gutter,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      excludeFromSemantics: true,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}
