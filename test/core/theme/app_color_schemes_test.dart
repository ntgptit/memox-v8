import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';

// Every role's value is pinned by flashcard_tokens_spec_test.dart (spec §1).
// This file pins the relations the components rely on.
void main() {
  test('brightness matches each theme', () {
    expect(AppColorSchemes.light.brightness, Brightness.light);
    expect(AppColorSchemes.dark.brightness, Brightness.dark);
  });

  test(
    'the inverse surface inverts each theme: dark in light, light in dark',
    () {
      final light = AppColorSchemes.light;
      final dark = AppColorSchemes.dark;

      expect(
        light.inverseSurface.computeLuminance(),
        lessThan(light.surface.computeLuminance()),
      );
      expect(
        dark.inverseSurface.computeLuminance(),
        greaterThan(dark.surface.computeLuminance()),
      );
    },
  );

  test('the accent is one indigo in both themes', () {
    expect(AppColorSchemes.light.primary, AppColorSchemes.dark.primary);
    expect(AppColorSchemes.light.surfaceTint, AppColorSchemes.light.primary);
    expect(AppColorSchemes.dark.surfaceTint, AppColorSchemes.dark.primary);
  });
}
