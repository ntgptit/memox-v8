import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// An icon in a round 48 box: ForUI's ghost icon button at the large touch
/// size. [semanticLabel] names it for screen readers and shows as its
/// tooltip on a long press.
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
  Widget build(BuildContext context) => FTooltip(
    tipBuilder: (_, _) => Text(semanticLabel),
    child: FButton.icon(
      onPress: onPressed,
      variant: FButtonVariant.ghost,
      size: FButtonSizeVariant.lg,
      semanticsLabel: semanticLabel,
      child: Icon(icon),
    ),
  );
}
