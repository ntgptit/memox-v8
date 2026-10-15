import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_surface_themes.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

/// The light theme: its scheme, its extension and its accent.
ThemeData buildLightTheme() => _build(
  scheme: lightColorScheme,
  mx: MxColorsExtension.light,
  accent: lightColorScheme.primary,
);

/// The dark theme, authored on its own rather than as a filter over light.
/// Its accent is the lighter fixed step, as `primary` on the dark page is
/// only 3.01:1.
ThemeData buildDarkTheme() => _build(
  scheme: darkColorScheme,
  mx: MxColorsExtension.dark,
  accent: darkColorScheme.primaryFixedDim,
);

ThemeData _build({
  required ColorScheme scheme,
  required MxColorsExtension mx,
  required Color accent,
}) {
  // The base supplies Material's default slots, already inked onSurface.
  final base = ThemeData(colorScheme: scheme);
  final texts = AppTypography.bind(base.textTheme);
  final tokens = ThemeTokens(
    scheme: scheme,
    mx: mx,
    texts: texts,
    accent: accent,
  );
  return base.copyWith(
    textTheme: texts,
    // Read directly by CircleAvatar, FlexibleSpaceBar and others.
    primaryTextTheme: AppTypography.bind(base.primaryTextTheme),
    scaffoldBackgroundColor: scheme.surface,
    // InkWell rows (MxRowInk and the rows built on it) press in the theme's
    // foreground at the pressed overlay, not Material's grey (SW-REV-007).
    splashColor: tokens.onSurfaceAt(tokens.dimens.opacityPressed),
    highlightColor: tokens.onSurfaceAt(tokens.dimens.opacityPressed),
    // The hover and focus layers of the same rows: the tokens' state layers,
    // not the SDK's black or white at 4% and 12% (M3F-13).
    hoverColor: tokens.onSurfaceAt(tokens.dimens.opacityHover),
    focusColor: tokens.onSurfaceAt(tokens.dimens.opacityFocus),
    // A glyph with no IconTheme ancestor is a supporting icon (M3F-12).
    iconTheme: IconThemeData(
      color: scheme.onSurfaceVariant,
      size: tokens.dimens.sizeIcon,
    ),
    // Set, never left to the platform, which makes linux, windows and macOS
    // compact; `platform:` would change far more (M3F-14).
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [mx, tokens.dimens],
    cardTheme: cardTheme(tokens),
    searchBarTheme: searchBarTheme(tokens),
    dividerTheme: dividerTheme(tokens),
    filledButtonTheme: filledButtonTheme(tokens),
    outlinedButtonTheme: outlinedButtonTheme(tokens),
    textButtonTheme: textButtonTheme(tokens),
    iconButtonTheme: iconButtonTheme(tokens),
    floatingActionButtonTheme: floatingActionButtonTheme(tokens),
    navigationBarTheme: navigationBarTheme(tokens),
    navigationRailTheme: navigationRailTheme(tokens),
    progressIndicatorTheme: progressIndicatorTheme(tokens),
    chipTheme: chipTheme(tokens),
    switchTheme: switchTheme(tokens),
    sliderTheme: sliderTheme(tokens),
    segmentedButtonTheme: segmentedButtonTheme(tokens),
    inputDecorationTheme: inputDecorationTheme(tokens),
    dialogTheme: dialogTheme(tokens),
    bottomSheetTheme: bottomSheetTheme(tokens),
    snackBarTheme: snackBarTheme(tokens),
    tooltipTheme: tooltipTheme(tokens),
  );
}
