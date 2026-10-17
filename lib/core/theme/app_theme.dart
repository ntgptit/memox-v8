import 'package:flutter/material.dart' as sdk;
import 'package:flutter/painting.dart' show Color;
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

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

/// The theme of [colors]. Where ForUI draws the brand as a mark, an edge or
/// a selected label (the focus outline, a ticked box, a switch that is on, a
/// slider's fill, the selected tab, a focused field), it draws it in the
/// brand's ink: ForUI's own styles, computed on the palette with the ink as
/// `primary`. A primary fill under text (a button, a badge) keeps `primary`.
/// Light's ink is its primary, so light is ForUI's default.
FThemeData _build(FColors colors, String label) {
  final typography = AppTypography.build(colors);
  final ink = colors.extension<MxStatusColors>().primaryInk;
  final inked = colors.copyWith(
    primary: ink,
    primaryForeground: _onInk(colors, ink),
  );
  final style = FStyle.inherit(
    colors: inked,
    typography: typography,
    touch: true,
  );
  return FThemeData(
    debugLabel: label,
    colors: colors,
    touch: true,
    typography: typography,
    style: style,
    checkboxStyle: FCheckboxStyle.inherit(
      colors: inked,
      icons: const FIcons.lucide(),
      style: style,
      touch: true,
    ),
    radioStyle: FRadioStyle.inherit(colors: inked, style: style, touch: true),
    switchStyle: FSwitchStyle.inherit(colors: inked, style: style),
    sliderStyles: FSliderStyles.inherit(
      colors: inked,
      typography: typography,
      style: style,
      hapticFeedback: const FHapticFeedback(),
    ),
    bottomNavigationBarStyle: FBottomNavigationBarStyle.inherit(
      colors: inked,
      typography: typography,
      style: style,
    ),
    textFieldStyles: FTextFieldSizeStyles.inherit(
      colors: inked,
      typography: typography,
      style: style,
      touch: true,
    ),
    extensions: const [AppDimens()],
  );
}

/// The colour a mark on [ink] reads in: the palette's `primaryForeground` or
/// its page, whichever stands out more (white on light's indigo, the navy
/// page on dark's pale ink).
Color _onInk(FColors colors, Color ink) {
  final onPrimary = colors.primaryForeground;
  final page = colors.background;
  return _contrast(onPrimary, ink) >= _contrast(page, ink) ? onPrimary : page;
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
}

/// The SDK Material theme the app's infrastructure host reads, derived one
/// way from [theme] (ADR-026): `MaterialApp.router` (go_router's page
/// transitions), the `Scaffold` that `MxAppShell` lays out with, and the
/// `RefreshIndicator` of the two pull-to-refresh lists. ForUI owns every
/// visible component; this only gives those hosts the same ground, ink and
/// type so nothing flashes Material's defaults. It has no component themes
/// and nothing reads it back.
sdk.ThemeData materialHostTheme(FThemeData theme) {
  final colors = theme.colors;
  final ink = colors.extension<MxStatusColors>().primaryInk;
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
    // The caret and the handles are marks, in the brand's ink.
    textSelectionTheme: sdk.TextSelectionThemeData(
      cursorColor: ink,
      selectionColor: ink.withValues(alpha: 0.4),
      selectionHandleColor: ink,
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
