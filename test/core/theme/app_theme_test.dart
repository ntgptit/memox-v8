import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/core/theme/mx_text_styles.dart';

import '../../support/theme_colours.dart';

void main() {
  final themes = {
    'light': (buildLightTheme(), lightColorScheme, DesignPalette.light),
    'dark': (buildDarkTheme(), darkColorScheme, DesignPalette.dark),
  };

  for (final MapEntry(key: name, value: (theme, scheme, palette))
      in themes.entries) {
    test(
      'the $name theme is Material 3 with its scheme and every extension',
      () {
        expect(theme.useMaterial3, isTrue);
        expect(theme.colorScheme, same(scheme));
        expect(theme.extension<MxSemanticColors>(), isNotNull);
        expect(theme.extension<MxElevation>(), isNotNull);
        expect(theme.extension<MxTextStyles>(), isNotNull);
        expect(theme.scaffoldBackgroundColor, scheme.surface);
        expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
      },
    );

    test('every $name colour the theme holds is DESIGN.md\'s', () {
      final colours = themeColours(theme);

      for (final MapEntry(key: key, value: colour) in colours.entries) {
        expect(colour, palette.byName[key], reason: key);
      }
    });

    test('the $name system surfaces follow DESIGN.md', () {
      final floating = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      );

      expect(theme.dialogTheme.backgroundColor, scheme.surfaceContainerHigh);
      expect(theme.dialogTheme.shape, floating);
      expect(theme.datePickerTheme.shape, floating);
      expect(theme.timePickerTheme.shape, floating);
    });

    test('the $name text button is the quiet primary action', () {
      final style = theme.textButtonTheme.style!;
      const none = <WidgetState>{};
      final ink = scheme.primary;

      expect(style.foregroundColor!.resolve(none), ink);
      expect(
        style.overlayColor!.resolve({WidgetState.pressed}),
        ink.withValues(alpha: AppOpacity.pressed),
      );
      expect(
        style.foregroundColor!.resolve({WidgetState.disabled})!.a,
        closeTo(ink.a * AppOpacity.disabled, 0.001),
      );
      expect(style.minimumSize!.resolve(none)!.height, AppSize.buttonRegular);
      expect(
        style.side!.resolve({WidgetState.focused})!.width,
        AppStroke.focus,
      );
    });
  }

  test('a theme change animates through every extension', () {
    final halfway = ThemeData.lerp(buildLightTheme(), buildDarkTheme(), 0.5);

    expect(halfway.extension<MxSemanticColors>(), isNotNull);
    expect(halfway.extension<MxElevation>(), isNotNull);
    expect(halfway.extension<MxTextStyles>(), isNotNull);
  });
}
