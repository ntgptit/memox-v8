import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';

/// The light and dark themes, built only from the generated foundations
/// (spec 2026-10-04-sp3a §3.3). Component themes join in the phase that
/// builds their `Mx*`.
abstract final class AppTheme {
  static ThemeData light() =>
      _build(AppColorSchemes.light, AppSemanticColors.light);

  static ThemeData dark() =>
      _build(AppColorSchemes.dark, AppSemanticColors.dark);

  static ThemeData _build(ColorScheme scheme, AppSemanticColors semantic) {
    final TextTheme textTheme = AppTextStyles.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      fontFamily: AppTextStyles.family,
      scaffoldBackgroundColor: scheme.surface,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      visualDensity: VisualDensity.standard,
      splashFactory: InkRipple.splashFactory,
      splashColor: scheme.onSurface.withValues(alpha: AppOpacity.pressed),
      focusColor: scheme.primary.withValues(alpha: AppOpacity.focus),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      extensions: <AppSemanticColors>[semantic],
    );
  }
}
