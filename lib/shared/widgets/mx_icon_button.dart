import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

/// An icon in a round `sizeControl` box: the Design System's icon button.
/// [semanticLabel] names it for screen readers and shows as its tooltip.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;

  /// Null disables the control; the theme dims it.
  final VoidCallback? onPressed;

  /// The theme's IconButton is this contract: the glyph size, the control
  /// size, the state layers, the disabled opacity and the focus ring.
  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: semanticLabel,
    onPressed: onPressed,
  );
}
