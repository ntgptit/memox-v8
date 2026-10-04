import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// Tokyo Pure Light: DESIGN.md's light theme.
ThemeData buildLightTheme() => _theme(
  scheme: lightColorScheme,
  semantic: MxSemanticColors.light,
  elevation: MxElevation.light,
);

/// Tokyo Nebula: DESIGN.md's dark theme, authored on its own.
ThemeData buildDarkTheme() => _theme(
  scheme: darkColorScheme,
  semantic: MxSemanticColors.dark,
  elevation: MxElevation.dark,
);

ThemeData _theme({
  required ColorScheme scheme,
  required MxSemanticColors semantic,
  required MxElevation elevation,
}) {
  final styles = MxTextStyles.from(scheme);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: DesignType.fontFamily,
    textTheme: AppTypography.textTheme(scheme),
    scaffoldBackgroundColor: scheme.surface,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    extensions: [semantic, elevation, styles],
    dialogTheme: AppComponentThemes.dialog(scheme),
    datePickerTheme: AppComponentThemes.datePicker(scheme),
    timePickerTheme: AppComponentThemes.timePicker(scheme),
    textButtonTheme: AppComponentThemes.textButton(scheme, styles),
  );
}
