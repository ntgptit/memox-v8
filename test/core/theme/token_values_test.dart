import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_theme.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

import 'token_source.dart';

// The generated theme code equals design/tokens.json. Names live here, values
// only in the JSON.

final _roles = <String, Color Function(ColorScheme)>{
  'primary': (s) => s.primary,
  'onPrimary': (s) => s.onPrimary,
  'primaryContainer': (s) => s.primaryContainer,
  'onPrimaryContainer': (s) => s.onPrimaryContainer,
  'primaryFixed': (s) => s.primaryFixed,
  'primaryFixedDim': (s) => s.primaryFixedDim,
  'onPrimaryFixed': (s) => s.onPrimaryFixed,
  'onPrimaryFixedVariant': (s) => s.onPrimaryFixedVariant,
  'secondary': (s) => s.secondary,
  'onSecondary': (s) => s.onSecondary,
  'secondaryContainer': (s) => s.secondaryContainer,
  'onSecondaryContainer': (s) => s.onSecondaryContainer,
  'secondaryFixed': (s) => s.secondaryFixed,
  'secondaryFixedDim': (s) => s.secondaryFixedDim,
  'onSecondaryFixed': (s) => s.onSecondaryFixed,
  'onSecondaryFixedVariant': (s) => s.onSecondaryFixedVariant,
  'tertiary': (s) => s.tertiary,
  'onTertiary': (s) => s.onTertiary,
  'tertiaryContainer': (s) => s.tertiaryContainer,
  'onTertiaryContainer': (s) => s.onTertiaryContainer,
  'tertiaryFixed': (s) => s.tertiaryFixed,
  'tertiaryFixedDim': (s) => s.tertiaryFixedDim,
  'onTertiaryFixed': (s) => s.onTertiaryFixed,
  'onTertiaryFixedVariant': (s) => s.onTertiaryFixedVariant,
  'error': (s) => s.error,
  'onError': (s) => s.onError,
  'errorContainer': (s) => s.errorContainer,
  'onErrorContainer': (s) => s.onErrorContainer,
  'surface': (s) => s.surface,
  'onSurface': (s) => s.onSurface,
  'surfaceDim': (s) => s.surfaceDim,
  'surfaceBright': (s) => s.surfaceBright,
  'surfaceContainerLowest': (s) => s.surfaceContainerLowest,
  'surfaceContainerLow': (s) => s.surfaceContainerLow,
  'surfaceContainer': (s) => s.surfaceContainer,
  'surfaceContainerHigh': (s) => s.surfaceContainerHigh,
  'surfaceContainerHighest': (s) => s.surfaceContainerHighest,
  'onSurfaceVariant': (s) => s.onSurfaceVariant,
  'outline': (s) => s.outline,
  'outlineVariant': (s) => s.outlineVariant,
  'shadow': (s) => s.shadow,
  'scrim': (s) => s.scrim,
  'inverseSurface': (s) => s.inverseSurface,
  'onInverseSurface': (s) => s.onInverseSurface,
  'inversePrimary': (s) => s.inversePrimary,
  'surfaceTint': (s) => s.surfaceTint,
};

// field -> the Design System token that feeds it.
final _extension = <String, (String, Color Function(MxColorsExtension))>{
  'success': ('success-color', (m) => m.success),
  'onSuccess': ('success-onColor', (m) => m.onSuccess),
  'successContainer': ('success-container', (m) => m.successContainer),
  'onSuccessContainer': ('success-onContainer', (m) => m.onSuccessContainer),
  'warning': ('warning-color', (m) => m.warning),
  'onWarning': ('warning-onColor', (m) => m.onWarning),
  'warningContainer': ('warning-container', (m) => m.warningContainer),
  'onWarningContainer': ('warning-onContainer', (m) => m.onWarningContainer),
  'info': ('info-color', (m) => m.info),
  'onInfo': ('info-onColor', (m) => m.onInfo),
  'infoContainer': ('info-container', (m) => m.infoContainer),
  'onInfoContainer': ('info-onContainer', (m) => m.onInfoContainer),
  'cardSurface': ('cardSurface', (m) => m.cardSurface),
  'searchSurface': ('searchSurface', (m) => m.searchSurface),
  'tileSurface': ('tileSurface', (m) => m.tileSurface),
  'divider': ('divider', (m) => m.divider),
};

final _dimens = <String, double Function(AppDimens)>{
  'space4': (d) => d.space4,
  'space8': (d) => d.space8,
  'space12': (d) => d.space12,
  'space16': (d) => d.space16,
  'space24': (d) => d.space24,
  'space32': (d) => d.space32,
  'space48': (d) => d.space48,
  'marginScreen': (d) => d.marginScreen,
  'marginScreenMedium': (d) => d.marginScreenMedium,
  'radiusXs': (d) => d.radiusXs,
  'radiusSm': (d) => d.radiusSm,
  'radiusMd': (d) => d.radiusMd,
  'radiusLg': (d) => d.radiusLg,
  'radiusXl': (d) => d.radiusXl,
  'sizeControl': (d) => d.sizeControl,
  'sizeButton': (d) => d.sizeButton,
  'sizeButtonSmall': (d) => d.sizeButtonSmall,
  'sizeSearch': (d) => d.sizeSearch,
  'sizeAvatar': (d) => d.sizeAvatar,
  'sizeTile': (d) => d.sizeTile,
  'sizeNav': (d) => d.sizeNav,
  'sizeRail': (d) => d.sizeRail,
  'sizeNavIndicatorWidth': (d) => d.sizeNavIndicatorWidth,
  'sizeNavIndicatorHeight': (d) => d.sizeNavIndicatorHeight,
  'sizeIcon': (d) => d.sizeIcon,
  'sizeIconTile': (d) => d.sizeIconTile,
  'sizeTrack': (d) => d.sizeTrack,
  'sizeBadge': (d) => d.sizeBadge,
  'sizeDot': (d) => d.sizeDot,
  'sizeDotSmall': (d) => d.sizeDotSmall,
  'sizeContentMax': (d) => d.sizeContentMax,
  'sizeContentMaxWide': (d) => d.sizeContentMaxWide,
  'breakpointMedium': (d) => d.breakpointMedium,
  'breakpointExpanded': (d) => d.breakpointExpanded,
  'strokeHairline': (d) => d.strokeHairline,
  'strokeFocus': (d) => d.strokeFocus,
  'opacityHover': (d) => d.opacityHover,
  'opacityPressed': (d) => d.opacityPressed,
  'opacityFocus': (d) => d.opacityFocus,
  'opacityDragged': (d) => d.opacityDragged,
  'opacityDisabledContent': (d) => d.opacityDisabledContent,
  'opacityDisabledContainer': (d) => d.opacityDisabledContainer,
};

final _appOnly = <String, double Function(AppDimens)>{
  'sizeChip': (d) => d.sizeChip,
  'sizeInput': (d) => d.sizeInput,
  'sizeFab': (d) => d.sizeFab,
  'sizeAppBar': (d) => d.sizeAppBar,
  'sizeIconInline': (d) => d.sizeIconInline,
  'sizeIconCompact': (d) => d.sizeIconCompact,
  'sizeIconButton': (d) => d.sizeIconButton,
  'sizeSelectionControl': (d) => d.sizeSelectionControl,
  'sizeRadioDot': (d) => d.sizeRadioDot,
  'radiusCheckbox': (d) => d.radiusCheckbox,
  'strokeFocusGap': (d) => d.strokeFocusGap,
  'strokeControl': (d) => d.strokeControl,
  'strokeIndicator': (d) => d.strokeIndicator,
  'opacityMuted': (d) => d.opacityMuted,
  'opacityScrim': (d) => d.opacityScrim,
};

void main() {
  for (final (mode, scheme) in [
    ('light', lightColorScheme),
    ('dark', darkColorScheme),
  ]) {
    group(mode, () {
      test('the ColorScheme declares the 46 roles of the JSON', () {
        final tokens = colorTokens.take(46).map((t) => t['name']).toList();
        expect(_roles.keys.toList(), tokens);
        for (final MapEntry(:key, :value) in _roles.entries) {
          expect(value(scheme), tokenColor(key, mode), reason: key);
        }
        expect(
          scheme.brightness,
          mode == 'light' ? Brightness.light : Brightness.dark,
        );
      });

      test(
        'MxColorsExtension holds the 16 tokens the scheme has no role for',
        () {
          final extension = mode == 'light'
              ? MxColorsExtension.light
              : MxColorsExtension.dark;
          for (final MapEntry(:key, value: (token, read))
              in _extension.entries) {
            expect(read(extension), tokenColor(token, mode), reason: key);
          }
        },
      );
    });
  }

  test(
    'AppDimens holds every dimension token of the JSON and nothing else',
    () {
      const dimens = AppDimens();
      final expected = dimensionTokens;
      expect(_dimens.keys.toSet(), expected.keys.toSet());
      for (final MapEntry(:key, :value) in _dimens.entries) {
        expect(value(dimens), expected[key], reason: key);
      }
    },
  );

  test('AppDimens app-only fields equal design/app_tokens.json', () {
    const dimens = AppDimens();
    final expected = appOnlyTokens;
    expect(_appOnly.keys.toSet(), expected.keys.toSet());
    for (final MapEntry(:key, :value) in _appOnly.entries) {
      expect(value(dimens), expected[key], reason: key);
    }
  });

  test('every app-only token is absent from the Design System', () {
    expect(
      appOnlyTokens.keys.toSet().intersection(dimensionTokens.keys.toSet()),
      isEmpty,
    );
  });

  test(
    'both built themes carry the scheme, the extensions and the page ground',
    () {
      final light = buildLightTheme();
      final dark = buildDarkTheme();
      expect(light.colorScheme, lightColorScheme);
      expect(dark.colorScheme, darkColorScheme);
      expect(light.extension<MxColorsExtension>(), MxColorsExtension.light);
      expect(dark.extension<MxColorsExtension>(), MxColorsExtension.dark);
      expect(light.extension<AppDimens>(), isNotNull);
      expect(dark.scaffoldBackgroundColor, darkColorScheme.surface);
    },
  );
}
