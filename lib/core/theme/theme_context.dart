import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// The one way UI code reads the theme.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  MxSemanticColors get semanticColors {
    final semantic = Theme.of(this).extension<MxSemanticColors>();
    if (semantic == null) {
      throw StateError(
        'MxSemanticColors is missing from the ThemeData in scope. Build it '
        'with buildLightTheme() or buildDarkTheme() from '
        'core/theme/app_theme.dart.',
      );
    }
    return semantic;
  }

  MxDerivedColors get derivedColors =>
      MxDerivedColors.resolve(colors, semanticColors);

  MxTextStyles get textStyles => MxTextStyles(texts, colors);
}
