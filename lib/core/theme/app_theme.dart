import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

/// Tokyo Pure Light.
ThemeData buildLightTheme() =>
    _build(AppColorSchemes.light, MxSemanticColors.light);

/// Tokyo Nebula. Authored, not a filter over light.
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
    filledButtonTheme: AppComponentThemes.filledButtons(scheme, texts),
    outlinedButtonTheme: AppComponentThemes.outlinedButtons(scheme, texts),
    textButtonTheme: AppComponentThemes.textButtons(scheme, texts),
    iconButtonTheme: AppComponentThemes.iconButtons(scheme),
    dialogTheme: AppComponentThemes.dialogs(scheme, texts),
    bottomSheetTheme: AppComponentThemes.sheets(scheme),
    snackBarTheme: AppComponentThemes.snackbars(scheme, texts),
    tooltipTheme: AppComponentThemes.tooltips(scheme, texts),
    // InkWell rows (MxRowInk, MxOptionRow, the tray, the nav) press in the
    // theme's ink at the buttons' 12% overlay, not Material's grey
    // (SW-REV-007).
    splashColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
    highlightColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
  );
}
