import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';

/// One face of the card under study (kit StudyFaceCard): the label at the
/// top, the content centred below it, and a recessed ground when it is the answer.
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
      // The label runs in flow above the face (kit labelPlacement flow), so
      // a face that grows with large text never slides under it.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.card,
              AppSpacing.gutter,
              AppSpacing.card,
              0,
            ),
            child: Text(
              label.toUpperCase(),
              semanticsLabel: label,
              style: context.textStyles.overline,
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.gutter),
                child: child,
              ),
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
