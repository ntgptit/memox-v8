import 'package:flutter/material.dart' as sdk;
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_typography.dart';

/// The light theme: ForUI's touch theme on the app palette and type scale.
/// Built once; every caller shares it.
FThemeData buildLightTheme() => _light;

/// The dark theme, authored on its own palette rather than as a filter over
/// light. Built once; every caller shares it.
FThemeData buildDarkTheme() => _dark;

final FThemeData _light = _build(AppPalette.light, 'MemoX Light');
final FThemeData _dark = _build(AppPalette.dark, 'MemoX Dark');

/// The ForUI theme of [brightness]: what the composition root and the test
/// harnesses select by the resolved theme mode.
FThemeData themeFor(sdk.Brightness brightness) => switch (brightness) {
  sdk.Brightness.light => buildLightTheme(),
  sdk.Brightness.dark => buildDarkTheme(),
};

FThemeData _build(FColors colors, String label) => FThemeData(
  debugLabel: label,
  colors: colors,
  touch: true,
  typography: AppTypography.build(colors),
  extensions: const [AppDimens()],
);

/// The SDK Material theme the app's infrastructure host reads, derived one
/// way from [theme] (ADR-025): `MaterialApp.router` (go_router's page
/// transitions), the `Scaffold` that `MxAppShell` lays out with, and the
/// `RefreshIndicator` of the two pull-to-refresh lists. ForUI owns every
/// visible component; this only gives those hosts the same ground, ink and
/// type so nothing flashes Material's defaults. It has no component themes
/// and nothing reads it back.
sdk.ThemeData materialHostTheme(FThemeData theme) {
  final colors = theme.colors;
  final scheme = sdk.ColorScheme(
    brightness: colors.brightness,
    primary: colors.primary,
    onPrimary: colors.primaryForeground,
    secondary: colors.secondary,
    onSecondary: colors.secondaryForeground,
    error: colors.error,
    onError: colors.errorForeground,
    surface: colors.background,
    onSurface: colors.foreground,
    onSurfaceVariant: colors.mutedForeground,
    outline: colors.border,
    outlineVariant: colors.border,
  );
  return sdk.ThemeData(
    colorScheme: scheme,
    fontFamily: theme.typography.body.fontFamily,
    fontFamilyFallback: theme.typography.body.fontFamilyFallback,
    scaffoldBackgroundColor: colors.background,
    canvasColor: colors.background,
    // ForUI draws every press and focus state; the host draws no ripple.
    splashFactory: sdk.NoSplash.splashFactory,
    textSelectionTheme: sdk.TextSelectionThemeData(
      cursorColor: colors.primary,
      selectionColor: colors.primary.withValues(alpha: 0.4),
      selectionHandleColor: colors.primary,
    ),
    visualDensity: sdk.VisualDensity.standard,
    materialTapTargetSize: sdk.MaterialTapTargetSize.padded,
  );
}
