import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';
import 'package:material_ui/material_ui.dart' as forui_material;
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The brightness [mode] resolves to: `system` follows the platform's as it
/// changes.
Brightness resolveBrightness(BuildContext context, ThemeMode mode) =>
    switch (mode) {
      ThemeMode.light => Brightness.light,
      ThemeMode.dark => Brightness.dark,
      ThemeMode.system => MediaQuery.platformBrightnessOf(context),
    };

/// Puts the app's ForUI theme of [brightness] over [child] (ADR-025). It sits
/// in `MaterialApp.builder`, above the Navigator, so every route, dialog,
/// sheet and overlay below inherits the one theme; a theme placed in a screen
/// would not reach the routes the root navigator shows.
///
/// - [FTheme] is the theme every widget reads (`context.colors`, …).
/// - The `material_ui` Theme is ForUI's own bridge (`toApproximateMaterialTheme`)
///   for the few `material_ui` pieces ForUI builds on, such as a text field's
///   selection toolbar; derived one way, nothing reads it back.
/// - [MxToastHost] holds the toasts `showMxSnackbar` shows, above every route.
/// - A glyph with no colour of its own reads `mutedForeground` (DESIGN.md),
///   not the accent the `material_ui` Theme gives icons.
class AppThemeHost extends StatelessWidget {
  const AppThemeHost({
    super.key,
    required this.brightness,
    required this.child,
  });

  final Brightness brightness;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = themeFor(brightness);
    return FTheme(
      data: theme,
      child: forui_material.Theme(
        data: theme.toApproximateMaterialTheme(),
        child: IconTheme.merge(
          data: IconThemeData(color: theme.colors.mutedForeground),
          child: MxToastHost(child: child),
        ),
      ),
    );
  }
}
