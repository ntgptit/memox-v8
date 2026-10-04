import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/foundations/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_semantic_colors.dart';
import 'package:memox/core/theme/foundations/app_text_styles.dart';

void main() {
  final Map<String, (ThemeData, ColorScheme, AppSemanticColors)> themes = {
    'light': (AppTheme.light(), AppColorSchemes.light, AppSemanticColors.light),
    'dark': (AppTheme.dark(), AppColorSchemes.dark, AppSemanticColors.dark),
  };

  test(
    'primary is #4151C6 in both themes (DESIGN.md, The One Indigo Rule)',
    () {
      const Color canonical = Color(0xFF4151C6);
      expect(AppTheme.light().colorScheme.primary, canonical);
      expect(AppTheme.dark().colorScheme.primary, canonical);
      expect(
        AppTheme.light().colorScheme.primary,
        AppTheme.dark().colorScheme.primary,
      );
    },
  );

  for (final MapEntry(key: name, value: (theme, scheme, semantic))
      in themes.entries) {
    group('$name theme', () {
      test('carries the generated colour scheme, role for role', () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, scheme);
        expect(theme.colorScheme.brightness, scheme.brightness);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
      });

      test('carries the generated semantic colours', () {
        expect(theme.extension<AppSemanticColors>(), semantic);
      });

      test('fills every TextTheme slot from the generated styles', () {
        final TextTheme generated = AppTextStyles.textTheme;
        final List<(TextStyle?, TextStyle?)> slots = [
          (theme.textTheme.displayLarge, generated.displayLarge),
          (theme.textTheme.displayMedium, generated.displayMedium),
          (theme.textTheme.displaySmall, generated.displaySmall),
          (theme.textTheme.headlineLarge, generated.headlineLarge),
          (theme.textTheme.headlineMedium, generated.headlineMedium),
          (theme.textTheme.headlineSmall, generated.headlineSmall),
          (theme.textTheme.titleLarge, generated.titleLarge),
          (theme.textTheme.titleMedium, generated.titleMedium),
          (theme.textTheme.titleSmall, generated.titleSmall),
          (theme.textTheme.bodyLarge, generated.bodyLarge),
          (theme.textTheme.bodyMedium, generated.bodyMedium),
          (theme.textTheme.bodySmall, generated.bodySmall),
          (theme.textTheme.labelLarge, generated.labelLarge),
          (theme.textTheme.labelMedium, generated.labelMedium),
          (theme.textTheme.labelSmall, generated.labelSmall),
        ];
        for (final (built, source) in slots) {
          expect(source, isNotNull);
          expect(built!.fontFamily, AppTextStyles.family);
          expect(built.fontSize, source!.fontSize);
          expect(built.fontWeight, source.fontWeight);
          expect(built.fontVariations, source.fontVariations);
          expect(built.height, source.height);
          expect(built.letterSpacing, source.letterSpacing);
          expect(built.color, scheme.onSurface);
        }
      });

      test('focus falls back to the primary role, not a Flutter default', () {
        expect(
          theme.focusColor,
          scheme.primary.withValues(alpha: AppOpacity.focus),
        );
      });

      test('the component slots read the same roles as the Mx widgets', () {
        expect(theme.inputDecorationTheme.filled, isTrue);
        expect(theme.inputDecorationTheme.fillColor, isA<WidgetStateColor>());
        expect(
          theme.iconButtonTheme.style!.foregroundColor!.resolve({}),
          scheme.onSurfaceVariant,
        );
        expect(theme.floatingActionButtonTheme.backgroundColor, scheme.primary);
        expect(
          theme.floatingActionButtonTheme.foregroundColor,
          scheme.onPrimary,
        );
        expect(theme.textSelectionTheme.cursorColor, scheme.onPrimaryContainer);
        expect(
          theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
          scheme.primary,
        );
      });

      test('the FAB slot has no elevation in any state', () {
        final FloatingActionButtonThemeData fab =
            theme.floatingActionButtonTheme;
        expect([
          fab.elevation,
          fab.focusElevation,
          fab.hoverElevation,
          fab.highlightElevation,
          fab.disabledElevation,
        ], everyElement(0));
      });

      test('pads every tap target to 48', () {
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      });
    });
  }
}
