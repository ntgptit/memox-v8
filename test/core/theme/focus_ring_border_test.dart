import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_component_themes.dart';

// The border behind the button focus ring: the plain stadium for clipping,
// the ring only on top of it, and a ring that animates in and out.
void main() {
  const ring = BorderSide(color: Colors.indigo, width: 2);
  const rect = Rect.fromLTWH(0, 0, 100, 40);

  test('its outline is the plain stadium, so ink and clip ignore the ring', () {
    const border = MxFocusRingBorder(ring: ring, gap: 2);

    expect(
      border.getOuterPath(rect).getBounds(),
      const StadiumBorder().getOuterPath(rect).getBounds(),
    );
    expect(border.getInnerPath(rect).getBounds(), rect);
  });

  test('copyWith(side) keeps the ring: a ButtonStyle merges its side in', () {
    const side = BorderSide(color: Colors.red);
    final merged = const MxFocusRingBorder(
      ring: ring,
      gap: 2,
    ).copyWith(side: side);

    expect(merged, const MxFocusRingBorder(side: side, ring: ring, gap: 2));
  });

  test('a resting border and a focused one differ and lerp in between', () {
    const resting = MxFocusRingBorder(gap: 2);
    const focused = MxFocusRingBorder(ring: ring, gap: 2);

    expect(resting, isNot(focused));
    final half = ShapeBorder.lerp(resting, focused, 0.5)! as MxFocusRingBorder;
    expect(half.ring.width, 1);
    expect(ShapeBorder.lerp(resting, focused, 1), focused);
    expect(ShapeBorder.lerp(focused, resting, 1), resting);
  });
}
