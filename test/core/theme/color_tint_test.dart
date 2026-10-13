import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

// The expected hex values are the ones the Design System spec precomputed
// (SPEC section 2): the accent / state colour at 16% over the page surface.
void expectTint(Color tinted, int argb) =>
    expect(tinted.toARGB32(), argb, reason: tinted.toString());

void main() {
  group('tintOver matches the spec hex, per 8-bit channel', () {
    test('light', () {
      final surface = lightColorScheme.surface;
      const mx = MxColorsExtension.light;
      expectTint(lightColorScheme.primary.tintOver(surface), 0xFFE4E2F7);
      expectTint(mx.success.tintOver(surface), 0xFFD6E7E2);
      expectTint(mx.warning.tintOver(surface), 0xFFEBE3D6);
      expectTint(lightColorScheme.error.tintOver(surface), 0xFFF4DADA);
    });

    test('dark', () {
      final surface = darkColorScheme.surface;
      const mx = MxColorsExtension.dark;
      expectTint(darkColorScheme.primaryFixedDim.tintOver(surface), 0xFF28254F);
      expectTint(mx.success.tintOver(surface), 0xFF172A40);
      expectTint(mx.warning.tintOver(surface), 0xFF312638);
      expectTint(darkColorScheme.error.tintOver(surface), 0xFF312441);
    });
  });

  test('the result is opaque', () {
    final tinted = const Color(0x80FF0000).tintOver(const Color(0xFFFFFFFF));
    expect(tinted.a, 1);
  });

  test('a tint over its own colour is that colour', () {
    const grey = Color(0xFF808080);
    expect(grey.tintOver(grey), grey);
  });
}
