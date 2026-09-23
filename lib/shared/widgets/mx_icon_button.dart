import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A 20 glyph in a 36 round ink box with a 48 touch area: the kit's only
/// bare-icon control. [semanticLabel] names it for screen readers and shows as
/// its tooltip.
class MxIconButton extends StatelessWidget {
  const MxIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;

  /// Null disables the control under the global 0.38 rule.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final button = IconButton(
      icon: Icon(icon),
      tooltip: semanticLabel,
      onPressed: onPressed,
      style: ButtonStyle(
        iconSize: const WidgetStatePropertyAll(AppIconSize.compact),
        foregroundColor: WidgetStatePropertyAll(colors.onSurface),
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? colors.onSurface.withValues(alpha: AppOpacity.pressed)
              : null,
        ),
        // Ruling R5: the focus ring sits on the circle's edge.
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? BorderSide(color: colors.primary, width: AppStroke.focus)
              : null,
        ),
        shape: const WidgetStatePropertyAll(CircleBorder()),
        fixedSize: const WidgetStatePropertyAll(
          Size.square(AppSize.iconButtonInk),
        ),
        minimumSize: const WidgetStatePropertyAll(
          Size.square(AppSize.iconButtonInk),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
    if (onPressed != null) return button;
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}
