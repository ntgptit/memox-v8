import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/button_style.dart';
import 'package:memox/core/theme/components/chrome_style.dart';
import 'package:memox/core/theme/components/field_style.dart';
import 'package:memox/core/theme/components/icon_button_style.dart';
import 'package:memox/core/theme/components/overlay_style.dart';
import 'package:memox/core/theme/foundations/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
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
      focusColor: scheme.onPrimaryContainer.withValues(alpha: AppOpacity.focus),
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
      extensions: <AppSemanticColors>[semantic],
      filledButtonTheme: FilledButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.primary,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.outline,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: mxButtonStyle(
          colors: scheme,
          semantic: semantic,
          texts: textTheme,
          tone: MxButtonTone.text,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: mxIconButtonStyle(colors: scheme),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        splashColor: scheme.onPrimary.withValues(alpha: AppOpacity.pressed),
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        disabledElevation: 0,
        iconSize: AppIconSize.large,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
        sizeConstraints: const BoxConstraints.tightFor(
          width: AppSize.fab,
          height: AppSize.fab,
        ),
      ),
      inputDecorationTheme: mxInputDecorationTheme(
        colors: scheme,
        texts: textTheme,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: scheme.onPrimaryContainer,
        selectionColor: scheme.primaryContainer,
        selectionHandleColor: scheme.onPrimaryContainer,
      ),
      appBarTheme: mxAppBarTheme(scheme, textTheme),
      dialogTheme: mxDialogTheme(scheme, textTheme),
      bottomSheetTheme: mxBottomSheetTheme(scheme),
      snackBarTheme: mxSnackBarTheme(scheme, textTheme),
      cardTheme: mxCardTheme(scheme),
    );
  }
}
