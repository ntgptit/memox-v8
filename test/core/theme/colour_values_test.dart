import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_elevation.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

import '../../support/theme_colours.dart';

/// DESIGN.md ↔ code parity for colour (spec 2026-10-04-sp3a §8.1). Every
/// colour of each theme is the generated value of the same DESIGN.md name,
/// so a hand edit in lib/core/theme fails here; a DESIGN.md edit that skips
/// the generator fails `generate.py --check` in the gate.
void main() {
  final themes = {
    'light': (
      lightColorScheme,
      MxSemanticColors.light,
      MxDerivedColors.light,
      MxElevation.light,
      DesignPalette.light,
      Brightness.light,
    ),
    'dark': (
      darkColorScheme,
      MxSemanticColors.dark,
      MxDerivedColors.dark,
      MxElevation.dark,
      DesignPalette.dark,
      Brightness.dark,
    ),
  };

  for (final MapEntry(key: name, value: theme) in themes.entries) {
    final (scheme, semantic, derived, elevation, palette, brightness) = theme;

    test('the $name scheme sets all 45 Material 3 roles from DESIGN.md', () {
      final roles = schemeRoles(scheme);

      expect(scheme.brightness, brightness);
      expect(roles, hasLength(45));
      for (final MapEntry(key: role, value: colour) in roles.entries) {
        expect(colour, palette.byName[role], reason: role);
      }
    });

    test('every $name colour is the generated value of its name', () {
      final colours = coloursOf(
        scheme: scheme,
        semantic: semantic,
        derived: derived,
      );

      expect(colours.keys.toSet(), palette.byName.keys.toSet());
      for (final MapEntry(key: key, value: colour) in colours.entries) {
        expect(colour, palette.byName[key], reason: key);
      }
    });

    test('the $name shadows are DESIGN.md\'s', () {
      expect(elevation.whisper, palette.shadowWhisper);
      expect(elevation.chrome, palette.shadowChrome);
      expect(elevation.overlay, palette.shadowOverlay);
      expect(elevation.fab, palette.shadowFab);
    });

    test('every $name contrast pair of DESIGN.md holds', () {
      final colours = coloursOf(
        scheme: scheme,
        semantic: semantic,
        derived: derived,
      );

      for (final pair in designContrastPairs) {
        final ratio = contrastRatio(
          colours[pair.foreground]!,
          colours[pair.ground]!,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(pair.floor),
          reason: '${pair.foreground} on ${pair.ground}: $ratio',
        );
      }
    });
  }

  test('dark draws no whisper shadow: a card takes the ghost border', () {
    expect(MxElevation.dark.whisper, isEmpty);
    expect(MxElevation.light.whisper, isNotEmpty);
  });
}
