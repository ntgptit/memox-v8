import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mx_status_colors.dart';

// The dark palette keeps the MemoX page and brand colours from before the
// ForUI migration, and every other dark role is computed from those two
// seeds (owner ruling 2026-10-17).
void main() {
  const page = Color(0xFF0A082D);
  const brand = Color(0xFF564BCB);

  group('the dark palette keeps its two seeds', () {
    test('the page is the navy and primary the brand, as in light', () {
      expect(appDarkColors.background, page);
      expect(appDarkColors.primary, brand);
      expect(appDarkColors.primary, appLightColors.primary);
      expect(appDarkColors.primaryForeground, appLightColors.primaryForeground);
    });

    test('it is the palette the two seeds compute', () {
      final computed = darkColorsFrom(background: page, primary: brand);
      for (final (role, actual, expected) in _roles(appDarkColors, computed)) {
        expect(actual, expected, reason: role);
      }
    });
  });

  group('every other role follows the seeds', () {
    // Other seeds give another palette: no role is written on its own.
    final other = darkColorsFrom(
      background: const Color(0xFF102010),
      primary: const Color(0xFF2E7D32),
    );

    test('a role computed from other seeds differs', () {
      for (final (role, actual, expected) in _roles(appDarkColors, other)) {
        if (role == 'primaryForeground' || role.startsWith('error')) continue;
        if (role.startsWith('destructive')) continue;
        expect(actual, isNot(expected), reason: role);
      }
    });

    test('the neutrals step from the page toward the foreground', () {
      double lum(Color c) => c.computeLuminance();
      final colors = appDarkColors;
      expect(lum(colors.background), lessThan(lum(colors.card)));
      expect(lum(colors.card), lessThan(lum(colors.muted)));
      expect(lum(colors.muted), lessThan(lum(colors.mutedForeground)));
      expect(lum(colors.mutedForeground), lessThan(lum(colors.foreground)));
    });

    test('the brand ink lies between primary and the foreground', () {
      final ink = appDarkColors.extension<MxStatusColors>().primaryInk;
      final p = appDarkColors.primary.computeLuminance();
      final f = appDarkColors.foreground.computeLuminance();
      expect(ink.computeLuminance(), inExclusiveRange(p, f));
    });
  });

  test('light ink is the brand itself', () {
    expect(
      appLightColors.extension<MxStatusColors>().primaryInk,
      appLightColors.primary,
    );
  });
}

List<(String, Color, Color)> _roles(FColors a, FColors b) => [
  ('barrier', a.barrier, b.barrier),
  ('foreground', a.foreground, b.foreground),
  ('primaryForeground', a.primaryForeground, b.primaryForeground),
  ('secondary', a.secondary, b.secondary),
  ('secondaryForeground', a.secondaryForeground, b.secondaryForeground),
  ('muted', a.muted, b.muted),
  ('mutedForeground', a.mutedForeground, b.mutedForeground),
  ('destructive', a.destructive, b.destructive),
  ('destructiveForeground', a.destructiveForeground, b.destructiveForeground),
  ('error', a.error, b.error),
  ('errorForeground', a.errorForeground, b.errorForeground),
  ('card', a.card, b.card),
  ('border', a.border, b.border),
  (
    'primaryInk',
    a.extension<MxStatusColors>().primaryInk,
    b.extension<MxStatusColors>().primaryInk,
  ),
];
