import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The status and navigation bars follow the app's theme, not the phone's.
/// The bars are transparent over the edge-to-edge surface, and their icons
/// contrast with that surface. MxAppBar is not Material's AppBar, which
/// would otherwise set this (audit 2026-10-03 Platform, SP1 §5.2).
class AppSystemBars extends StatelessWidget {
  const AppSystemBars({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final icons = isDark ? Brightness.light : Brightness.dark;
    final clear = context.colors.surface.withValues(alpha: 0);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: clear,
        statusBarIconBrightness: icons,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: clear,
        systemNavigationBarIconBrightness: icons,
        systemNavigationBarContrastEnforced: false,
      ),
      child: child,
    );
  }
}
