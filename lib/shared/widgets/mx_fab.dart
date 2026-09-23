import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The one pinned action: a square, icon-only 52 box. V3 has no extended FAB.
/// [semanticLabel] is the accessible name and is never painted. Placement
/// belongs to MxAppShell.
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
    final colors = context.colors;
    final radius = BorderRadius.circular(AppRadius.lg);
    final shape = RoundedRectangleBorder(borderRadius: radius);
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.fab(colors),
        ),
        child: Material(
          color: colors.primary,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            customBorder: shape,
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.pressed)
                  ? colors.onPrimary.withValues(alpha: AppOpacity.pressed)
                  : null,
            ),
            child: SizedBox.square(
              dimension: AppSize.fab,
              child: Center(
                child: Icon(
                  icon,
                  size: AppIconSize.compact,
                  color: colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
