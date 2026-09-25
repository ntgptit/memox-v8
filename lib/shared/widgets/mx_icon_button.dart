import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
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

  /// The theme's IconButton is this contract (spec §4.6): the glyph size,
  /// the 36 ink and 48 target, the overlay and the focus ring. The glyph
  /// keeps one ink and a disabled control dims whole under the global 0.38
  /// rule, as every Mx control does: the theme's per-ink dim, meant for
  /// framework buttons, draws different pixels (component-themes ruling).
  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon),
      tooltip: semanticLabel,
      onPressed: onPressed,
      style: Theme.of(context).iconButtonTheme.style?.copyWith(
        foregroundColor: WidgetStatePropertyAll(context.colors.onSurface),
      ),
    );
    if (onPressed != null) return button;
    return Opacity(opacity: AppOpacity.disabled, child: button);
  }
}
