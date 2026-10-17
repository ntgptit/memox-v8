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

final FThemeData _light = _build(appLightColors, 'MemoX Light');
final FThemeData _dark = _build(appDarkColors, 'MemoX Dark');

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
/// way from [theme] (ADR-026): `MaterialApp.router` (go_router's page
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
  final type = _hostTextTheme(theme.typography);
  return sdk.ThemeData(
    colorScheme: scheme,
    // Every slot is a ForUI step, so the default text style a host Material
    // (the Scaffold) sets under ForUI's is ForUI's, with no Material letter
    // spacing merged in from the typography geometry.
    typography: sdk.Typography(
      black: type,
      white: type,
      englishLike: type,
      dense: type,
      tall: type,
    ),
    textTheme: type,
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

/// The SDK text theme of [typography]: each Material slot on the ForUI step
/// ForUI's own Material bridge picks for it (`toApproximateMaterialTheme`),
/// inked in the step's foreground. `bodyMedium`, the host's default text,
/// is ForUI's default text (body `sm`).
sdk.TextTheme _hostTextTheme(FTypography typography) {
  final display = typography.display;
  final body = typography.body;
  return sdk.TextTheme(
    displayLarge: display.xl4,
    displayMedium: display.xl3,
    displaySmall: display.xl2,
    headlineLarge: display.xl3,
    headlineMedium: display.xl2,
    headlineSmall: display.xl,
    titleLarge: body.lg,
    titleMedium: body.md,
    titleSmall: body.sm,
    labelLarge: body.md,
    labelMedium: body.sm,
    labelSmall: body.xs,
    bodyLarge: body.md,
    bodyMedium: body.sm,
    bodySmall: body.xs,
  );
}
