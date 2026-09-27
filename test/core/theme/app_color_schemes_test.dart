import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';

// Every V3_DEFINED role from 02-theme-binding.md, light then dark. The dark
// primary pair follows spec 2026-09-27 D1, not the kit.
const _v3Roles = <String, (int, int)>{
  'primary': (0xFF5265F5, 0xFF5265F5),
  'onPrimary': (0xFFFFFFFF, 0xFFFFFFFF),
  'primaryContainer': (0xFFE0E5FE, 0xFF2D346A),
  'onPrimaryContainer': (0xFF1A2580, 0xFFD9DFFF),
  'secondary': (0xFF6E7CD9, 0xFF9DA8E8),
  'onSecondary': (0xFFFFFFFF, 0xFF1A2150),
  'secondaryContainer': (0xFFE3E6F7, 0xFF343C78),
  'onSecondaryContainer': (0xFF262E6E, 0xFFDDE2FB),
  'tertiary': (0xFF8B6FF5, 0xFFB5A0FF),
  'onTertiary': (0xFFFFFFFF, 0xFF240B63),
  'tertiaryContainer': (0xFFEBE3FE, 0xFF443078),
  'onTertiaryContainer': (0xFF33177E, 0xFFE6DCFF),
  'error': (0xFFDC2D4E, 0xFFFF8FA3),
  'onError': (0xFFFFFFFF, 0xFF52061B),
  'errorContainer': (0xFFFBDDE3, 0xFF7A2036),
  'onErrorContainer': (0xFF7A0A23, 0xFFFFD9DF),
  'surfaceDim': (0xFFDAE0EF, 0xFF060925),
  'surface': (0xFFF7F9FE, 0xFF0A0E27),
  'surfaceBright': (0xFFFFFFFF, 0xFF232B5A),
  'surfaceContainerLowest': (0xFFFFFFFF, 0xFF131A3A),
  'surfaceContainerLow': (0xFFF1F4FB, 0xFF1B2249),
  'surfaceContainer': (0xFFE9EDF7, 0xFF232B5A),
  'surfaceContainerHigh': (0xFFE2E7F3, 0xFF2C356E),
  'surfaceContainerHighest': (0xFFDAE0EF, 0xFF353D7E),
  'onSurface': (0xFF0F1638, 0xFFE4E8FA),
  'onSurfaceVariant': (0xFF4A5278, 0xFFA4ACD0),
  'outline': (0xFF7C85AB, 0xFF5A6BAE),
  'outlineVariant': (0xFFC5CBE3, 0xFF2A3267),
  'inverseSurface': (0xFF34395D, 0xFF34395D),
  'onInverseSurface': (0xFFE8EAFC, 0xFFE8EAFC),
  'inversePrimary': (0xFF8B9AFF, 0xFF5265F5),
  'scrim': (0xFF0A0E27, 0xFF000000),
  'shadow': (0xFF0F1638, 0xFF000000),
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
    test('$role is the V3 value in both themes', () {
      expect(_read[role]!(AppColorSchemes.light).toARGB32(), light);
      expect(_read[role]!(AppColorSchemes.dark).toARGB32(), dark);
    });
  }

  test('inverseSurface pair is invariant across themes', () {
    expect(
      AppColorSchemes.light.inverseSurface,
      AppColorSchemes.dark.inverseSurface,
    );
    expect(
      AppColorSchemes.light.onInverseSurface,
      AppColorSchemes.dark.onInverseSurface,
    );
  });

  test(
    'roles V3 leaves open keep the seed-generated value (REPO_PRESERVED)',
    () {
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
    },
  );
}
