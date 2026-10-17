import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_tooltip.dart';

/// An icon at `sizeIcon` in a round 48 box: ForUI's ghost icon button at the
/// large touch size. The glyph size is the app's, not ForUI's default, so a
/// bar can put the glyph itself on the screen margin (MxAppBar).
/// [semanticLabel] names it for screen readers and shows as its tooltip on a
/// long press.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;

  /// Null disables the control; ForUI dims it.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return MxTooltip(
      label: semanticLabel,
      child: FButton.icon(
        onPress: onPressed,
        variant: FButtonVariant.ghost,
        size: FButtonSizeVariant.lg,
        semanticsLabel: semanticLabel,
        // The padding keeps the larger glyph in the 48 box.
        style: FButtonStyleDelta.delta(
          iconContentStyle: FButtonIconContentStyleDelta.delta(
            padding: EdgeInsetsGeometryDelta.value(
              EdgeInsets.all((dimens.sizeControl - dimens.sizeIcon) / 2),
            ),
          ),
        ),
        child: Icon(icon, size: dimens.sizeIcon),
      ),
    );
  }
}
