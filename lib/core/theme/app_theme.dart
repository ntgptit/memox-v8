import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// The light theme ("Flashcard Color Tokens", ADR-022).
ThemeData buildLightTheme() =>
    _build(AppColorSchemes.light, MxSemanticColors.light);

/// The dark theme. Authored, not a filter over the light one.
ThemeData buildDarkTheme() =>
    _build(AppColorSchemes.dark, MxSemanticColors.dark);

ThemeData _build(ColorScheme scheme, MxSemanticColors semantic) {
  // The base supplies Material's default slots, already inked onSurface.
  final base = ThemeData(colorScheme: scheme);
  final texts = AppTypography.bind(base.textTheme);
  return base.copyWith(
    textTheme: texts,
    // Read directly by CircleAvatar, FlexibleSpaceBar and others.
    primaryTextTheme: AppTypography.bind(base.primaryTextTheme),
    scaffoldBackgroundColor: scheme.surface,
    extensions: [semantic],
    // Spec §4.6: the V3 defaults of the Material components.
    inputDecorationTheme: AppComponentThemes.fields(scheme, semantic, texts),
    filledButtonTheme: AppComponentThemes.filledButtons(
      scheme,
      semantic,
      texts,
    ),
    outlinedButtonTheme: AppComponentThemes.outlinedButtons(
      scheme,
      semantic,
      texts,
    ),
    textButtonTheme: AppComponentThemes.textButtons(scheme, semantic, texts),
    iconButtonTheme: AppComponentThemes.iconButtons(scheme, semantic),
    dialogTheme: AppComponentThemes.dialogs(scheme, semantic, texts),
    bottomSheetTheme: AppComponentThemes.sheets(scheme),
    snackBarTheme: AppComponentThemes.snackbars(scheme, semantic, texts),
    tooltipTheme: AppComponentThemes.tooltips(scheme, texts),
    // InkWell rows (MxRowInk, MxOptionRow, the tray, the nav) take the
    // Material 3 state layers in the theme's foreground, not Material's grey
    // ("Flashcard Color Tokens" §4.6; SW-REV-007).
    splashColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
    highlightColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
    focusColor: scheme.onSurface.withValues(alpha: AppOpacity.focus),
    hoverColor: scheme.onSurface.withValues(alpha: AppOpacity.hover),
  );
}
