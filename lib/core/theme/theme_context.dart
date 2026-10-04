import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

/// The one way a widget reads the design system: the scheme's 45 roles, the
/// type slots and the MemoX extensions of the current theme.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  MxTextStyles get textStyles => Theme.of(this).extension<MxTextStyles>()!;

  MxSemanticColors get semanticColors =>
      Theme.of(this).extension<MxSemanticColors>()!;

  MxElevation get elevation => Theme.of(this).extension<MxElevation>()!;
}
