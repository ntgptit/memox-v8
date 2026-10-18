import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// Owner ruling 2026-10-17: an accent icon is the brand indigo in light and
// as bright as text in dark, where the indigo is too dark to read on the
// navy page; text and fills keep primary.
void main() {
  final modes = <(String, FThemeData, FColors, Color, Color, String)>[
    (
      'light',
      buildLightTheme(),
      appLightColors,
      const Color(0xFF564BCB),
      appLightColors.primary,
      'the brand indigo',
    ),
    (
      'dark',
      buildDarkTheme(),
      appDarkColors,
      const Color(0xFFE6E6EA),
      appDarkColors.foreground,
      'the text colour',
    ),
  ];

  for (final (mode, theme, colors, literal, role, what) in modes) {
    test('$mode: an accent icon is $what', () {
      expect(colors.extension<MxStatusColors>().accentMark, literal);
      expect(colors.extension<MxStatusColors>().accentMark, role);
    });

    test(
      '$mode: the selected tab icon is the accent icon, its label primary',
      () {
        final item = theme.bottomNavigationBarStyle.itemStyle;
        final selected = {FTappableVariant.selected};
        expect(
          item.iconStyle.resolve(selected).color,
          theme.colors.extension<MxStatusColors>().accentMark,
        );
        expect(item.textStyle.resolve(selected).color, theme.colors.primary);
      },
    );

    test('$mode: the selected radio dot is the accent mark, its ring '
        'unchanged', () {
      final radio = theme.radioStyle;
      final mark = theme.colors.extension<MxStatusColors>().accentMark;
      expect(radio.indicatorColor.resolve({}), mark);
      expect(
        radio.indicatorColor.resolve({FRadioVariant.disabled}),
        theme.colors.disable(mark),
      );
      expect(
        radio.indicatorColor.resolve({FRadioVariant.error}),
        theme.colors.error,
      );
      expect(radio.borderColor.resolve({}), theme.colors.mutedForeground);
    });
  }
}
