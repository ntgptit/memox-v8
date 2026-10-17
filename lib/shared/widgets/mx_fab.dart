import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_tooltip.dart';

/// The one pinned action: ForUI's primary icon button as a square
/// `sizeFab` box with ForUI's shadow, icon only. [semanticLabel] is the
/// accessible name and the long-press tooltip, and is never painted.
/// Placement belongs to MxAppShell.
class MxFab extends StatelessWidget {
  const MxFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final size = context.dimens.sizeFab;
    return MxTooltip(
      label: semanticLabel,
      child: FButton.icon(
        variant: FButtonVariant.primary,
        size: FButtonSizeVariant.lg,
        onPress: onPressed,
        semanticsLabel: semanticLabel,
        style: FButtonStyleDelta.delta(
          // ForUI's shadow on every state, which lifts it over the scroll.
          decoration: FVariantsDelta.delta([
            FVariantOperation.all(
              DecorationDelta.shapeDelta(shadows: context.theme.style.shadow),
            ),
          ]),
          iconContentStyle: FButtonIconContentStyleDelta.delta(
            constraints: BoxConstraints.tightFor(width: size, height: size),
          ),
        ),
        child: Icon(icon),
      ),
    );
  }
}
