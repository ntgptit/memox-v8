import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

void main() {
  for (final (name, theme, colors, status) in [
    ('light', buildLightTheme(), appLightColors, MxStatusColors.light),
    ('dark', buildDarkTheme(), appDarkColors, MxStatusColors.dark),
  ]) {
    group(name, () {
      test('is the app palette on the ForUI touch theme', () {
        expect(theme.colors, colors);
        // Touch: ForUI's 44 field and 48 tile, not the desktop 36 and 48.
        expect(theme.style.sizes.field.md, 44);
      });

      test('carries the app extensions: geometry on the theme, status '
          'colours on the palette', () {
        expect(theme.extension<AppDimens>(), isA<AppDimens>());
        expect(theme.colors.extension<MxStatusColors>(), status);
      });

      test('sets the type in Be Vietnam Pro, Noto Sans KR behind it', () {
        expect(theme.typography.body.fontFamily, 'BeVietnamPro');
        expect(theme.typography.display.fontFamily, 'BeVietnamPro');
        expect(theme.typography.body.fontFamilyFallback, ['NotoSansKR']);
      });

      test('the SDK host theme is derived from the ForUI theme, one way', () {
        final host = materialHostTheme(theme);
        expect(host.colorScheme.brightness, colors.brightness);
        expect(host.colorScheme.primary, colors.primary);
        expect(host.colorScheme.surface, colors.background);
        expect(host.colorScheme.onSurface, colors.foreground);
        expect(host.scaffoldBackgroundColor, colors.background);
        // ForUI draws every press state; the host draws no ripple.
        expect(host.splashFactory, NoSplash.splashFactory);
        expect(host.textTheme.bodyMedium?.fontFamily, 'BeVietnamPro');
      });
    });
  }

  test('the builders return one shared theme per mode', () {
    expect(identical(buildLightTheme(), buildLightTheme()), isTrue);
    expect(themeFor(Brightness.light), buildLightTheme());
    expect(themeFor(Brightness.dark), buildDarkTheme());
  });

  test('light to dark lerp keeps the extensions (the theme animation)', () {
    final halfway = FThemeData.lerp(buildLightTheme(), buildDarkTheme(), 0.5);
    expect(halfway.extension<AppDimens>(), isA<AppDimens>());
    expect(halfway.colors.extension<MxStatusColors>(), isA<MxStatusColors>());
  });
}
