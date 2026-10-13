import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

/// The one way UI code reads the theme.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;

  TextTheme get texts => Theme.of(this).textTheme;

  MxColorsExtension get mxColors => _extension<MxColorsExtension>();

  AppDimens get dimens => _extension<AppDimens>();

  /// [T] from the ThemeData in scope; a theme built elsewhere lacks it.
  T _extension<T extends ThemeExtension<T>>() {
    final found = Theme.of(this).extension<T>();
    if (found != null) return found;
    throw StateError(
      '$T is missing from the ThemeData in scope. Build it with '
      'buildLightTheme() or buildDarkTheme() from core/theme/app_theme.dart.',
    );
  }
}
