import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
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
  return base.copyWith(
    textTheme: AppTypography.bind(base.textTheme),
    // Read directly by CircleAvatar, FlexibleSpaceBar and others.
    primaryTextTheme: AppTypography.bind(base.primaryTextTheme),
    scaffoldBackgroundColor: scheme.surface,
    extensions: [semantic],
  );
}
