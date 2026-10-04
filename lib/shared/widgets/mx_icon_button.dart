import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/icon_button_style.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

export 'package:memox/core/theme/components/icon_button_style.dart'
    show MxIconButtonTone;

/// An icon-only action. It always has a name: [semanticLabel] is read aloud
/// and shown as the long-press tooltip.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tone = MxIconButtonTone.standard,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;

  /// `null` disables the button, drawn at `AppOpacity.disabled`.
  final VoidCallback? onPressed;
  final MxIconButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final Widget button = MxFocusRing(
      borderRadius: BorderRadius.circular(AppSize.iconButton / 2),
      paintedHeight: AppSize.iconButton,
      child: IconButton(
        style: mxIconButtonStyle(colors: context.colors, tone: tone),
        tooltip: semanticLabel,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
    if (onPressed != null) {
      return button;
    }
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}
