import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';

/// The design-system layer's one read of the theme (flutter-design-system,
/// tokens.md): the 45 roles, MemoX's semantic roles and the type scale.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>()!;

  TextTheme get texts => Theme.of(this).textTheme;
}
