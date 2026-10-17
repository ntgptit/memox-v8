import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/color_tint.dart';

void main() {
  test('a tint is the colour at 16% over the base, rounded per channel', () {
    // 0x56 * 0.16 + 0xFF * 0.84 = 228.0, 0x4B → 226.2, 0xCB → 246.7.
    expect(
      const Color(0xFF564BCB).tintOver(const Color(0xFFFFFFFF)).toARGB32(),
      0xFFE4E2F7,
    );
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
