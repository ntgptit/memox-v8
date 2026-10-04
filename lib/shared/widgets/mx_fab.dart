import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

/// The screen's floating creation action: a 52dp `primary` square, r16, icon
/// only, with the FAB shadow (DESIGN.md, Actions; Elevation & Depth).
class MxFab extends StatelessWidget {
  const MxFab({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final IconData icon;

  /// Read aloud and shown as the tooltip: the FAB has no visible label.
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final AppShadow shadow = isDark ? AppShadows.fabDark : AppShadows.fabLight;
    return MxFocusRing(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [shadow.on(context.colors.shadow)],
        ),
        child: FloatingActionButton(
          heroTag: null,
          tooltip: semanticLabel,
          onPressed: onPressed,
          child: Icon(icon),
        ),
      ),
    );
  }
}
