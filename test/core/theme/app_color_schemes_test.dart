import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';

// Every role of the Indigo palette (spec 2026-10-10 §4), Day then Night.
const _v3Roles = <String, (int, int)>{
  'primary': (0xFF4255FF, 0xFF4255FF),
  'onPrimary': (0xFFFFFFFF, 0xFFFFFFFF),
  'primaryContainer': (0xFFEDEFFF, 0xFF14125C),
  'onPrimaryContainer': (0xFF4255FF, 0xFFEDEFFF),
  'secondary': (0xFF586380, 0xFF586380),
  'onSecondary': (0xFFFFFFFF, 0xFFF6F7FB),
  'secondaryContainer': (0xFFEDEFF4, 0xFF2E3856),
  'onSecondaryContainer': (0xFF2E3856, 0xFFD9DDE8),
  'tertiary': (0xFF9C63FF, 0xFF9C63FF),
  'onTertiary': (0xFFFFFFFF, 0xFFFFFFFF),
  'tertiaryContainer': (0xFFFAA6FF, 0xFFFAA6FF),
  'onTertiaryContainer': (0xFF282E3E, 0xFF282E3E),
  'error': (0xFFB00020, 0xFFFC3C60),
  'onError': (0xFFFFFFFF, 0xFFFFFFFF),
  'errorContainer': (0xFFFFE8D8, 0xFFFFE8D8),
  'onErrorContainer': (0xFFB00020, 0xFFB00020),
  'surfaceDim': (0xFFEDEFF4, 0xFF0A092D),
  'surface': (0xFFFFFFFF, 0xFF0A092D),
  'surfaceBright': (0xFFFFFFFF, 0xFF2E3856),
  'surfaceContainerLowest': (0xFFFFFFFF, 0xFF202040),
  'surfaceContainerLow': (0xFFF6F7FB, 0xFF2E3856),
  'surfaceContainer': (0xFFF6F7FB, 0xFF2E3856),
  'surfaceContainerHigh': (0xFFEDEFF4, 0xFF282E3E),
  'surfaceContainerHighest': (0xFFD9DDE8, 0xFF586380),
  'onSurface': (0xFF282E3E, 0xFFF6F7FB),
  'onSurfaceVariant': (0xFF586380, 0xFFD9DDE8),
  'outline': (0xFF939BB4, 0xFF586380),
  'outlineVariant': (0xFFD9DDE8, 0xFF586380),
  'inverseSurface': (0xFF1A1D28, 0xFFEDEFF4),
  'onInverseSurface': (0xFFF6F7FB, 0xFF282E3E),
  'inversePrimary': (0xFFF6F7FB, 0xFF586380),
  'scrim': (0xFF010110, 0xFF010110),
  'shadow': (0xFF282E3E, 0xFF282E3E),
};

final _read = <String, Color Function(ColorScheme)>{
  'primary': (s) => s.primary,
  'onPrimary': (s) => s.onPrimary,
  'primaryContainer': (s) => s.primaryContainer,
  'onPrimaryContainer': (s) => s.onPrimaryContainer,
  'secondary': (s) => s.secondary,
  'onSecondary': (s) => s.onSecondary,
  'secondaryContainer': (s) => s.secondaryContainer,
  'onSecondaryContainer': (s) => s.onSecondaryContainer,
  'tertiary': (s) => s.tertiary,
  'onTertiary': (s) => s.onTertiary,
  'tertiaryContainer': (s) => s.tertiaryContainer,
  'onTertiaryContainer': (s) => s.onTertiaryContainer,
  'error': (s) => s.error,
  'onError': (s) => s.onError,
  'errorContainer': (s) => s.errorContainer,
  'onErrorContainer': (s) => s.onErrorContainer,
  'surfaceDim': (s) => s.surfaceDim,
  'surface': (s) => s.surface,
  'surfaceBright': (s) => s.surfaceBright,
  'surfaceContainerLowest': (s) => s.surfaceContainerLowest,
  'surfaceContainerLow': (s) => s.surfaceContainerLow,
  'surfaceContainer': (s) => s.surfaceContainer,
  'surfaceContainerHigh': (s) => s.surfaceContainerHigh,
  'surfaceContainerHighest': (s) => s.surfaceContainerHighest,
  'onSurface': (s) => s.onSurface,
  'onSurfaceVariant': (s) => s.onSurfaceVariant,
  'outline': (s) => s.outline,
  'outlineVariant': (s) => s.outlineVariant,
  'inverseSurface': (s) => s.inverseSurface,
  'onInverseSurface': (s) => s.onInverseSurface,
  'inversePrimary': (s) => s.inversePrimary,
  'scrim': (s) => s.scrim,
  'shadow': (s) => s.shadow,
};

void main() {
  test('brightness matches each theme', () {
    expect(AppColorSchemes.light.brightness, Brightness.light);
    expect(AppColorSchemes.dark.brightness, Brightness.dark);
  });

  for (final MapEntry(key: role, value: (light, dark)) in _v3Roles.entries) {
    test('$role is the Indigo value in both themes', () {
      expect(_read[role]!(AppColorSchemes.light).toARGB32(), light);
      expect(_read[role]!(AppColorSchemes.dark).toARGB32(), dark);
    });
  }

  test(
    'the inverse surface inverts each theme: dark in Day, light in Night',
    () {
      final day = AppColorSchemes.light;
      final night = AppColorSchemes.dark;

      expect(
        day.inverseSurface.computeLuminance(),
        lessThan(day.surface.computeLuminance()),
      );
      expect(
        night.inverseSurface.computeLuminance(),
        greaterThan(night.surface.computeLuminance()),
      );
    },
  );

  test('the *Fixed family keeps the seed-generated value', () {
    for (final brightness in Brightness.values) {
      final seeded = ColorScheme.fromSeed(
        seedColor: AppColorSchemes.seed,
        brightness: brightness,
      );
      final actual = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      expect(actual.primaryFixed, seeded.primaryFixed);
      expect(actual.primaryFixedDim, seeded.primaryFixedDim);
      expect(actual.onPrimaryFixed, seeded.onPrimaryFixed);
      expect(actual.onPrimaryFixedVariant, seeded.onPrimaryFixedVariant);
      expect(actual.secondaryFixed, seeded.secondaryFixed);
      expect(actual.secondaryFixedDim, seeded.secondaryFixedDim);
      expect(actual.onSecondaryFixed, seeded.onSecondaryFixed);
      expect(actual.onSecondaryFixedVariant, seeded.onSecondaryFixedVariant);
      expect(actual.tertiaryFixed, seeded.tertiaryFixed);
      expect(actual.tertiaryFixedDim, seeded.tertiaryFixedDim);
      expect(actual.onTertiaryFixed, seeded.onTertiaryFixed);
      expect(actual.onTertiaryFixedVariant, seeded.onTertiaryFixedVariant);
    }
  });
}
