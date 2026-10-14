import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_component_themes.dart';

// The border behind the focus ring: the plain base shape for clipping, the
// ring only on top of it, and a ring that animates in and out. One class
// wraps a stadium (buttons) and a rounded rectangle (FAB, chips).
void main() {
  const ring = BorderSide(color: Colors.indigo, width: 2);
  const rect = Rect.fromLTWH(0, 0, 100, 40);
  final radius = BorderRadius.circular(16);
  final bases = <String, OutlinedBorder>{
    'stadium': const StadiumBorder(),
    'rounded rectangle': RoundedRectangleBorder(borderRadius: radius),
  };

  for (final MapEntry(key: name, value: base) in bases.entries) {
    group(name, () {
      test('its outline is the plain base shape, so ink ignores the ring', () {
        final border = MxFocusRingBorder(base: base, ring: ring, gap: 2);

        expect(
          border.getOuterPath(rect).getBounds(),
          base.getOuterPath(rect).getBounds(),
        );
        expect(
          border.getInnerPath(rect).getBounds(),
          base.getInnerPath(rect).getBounds(),
        );
        expect(border.dimensions, base.dimensions);
      });

      test('copyWith(side) keeps the ring and the base shape', () {
        const side = BorderSide(color: Colors.red);
        final merged = MxFocusRingBorder(
          base: base,
          ring: ring,
          gap: 2,
        ).copyWith(side: side);

        expect(
          merged,
          MxFocusRingBorder(
            base: base.copyWith(side: side),
            ring: ring,
            gap: 2,
          ),
        );
        expect(merged.side, side);
      });

      test('a resting border and a focused one differ and lerp in between', () {
        final resting = MxFocusRingBorder(base: base, gap: 2);
        final focused = MxFocusRingBorder(base: base, ring: ring, gap: 2);

        expect(resting, isNot(focused));
        final half =
            ShapeBorder.lerp(resting, focused, 0.5)! as MxFocusRingBorder;
        expect(half.ring.width, 1);
        expect(half.base, base);
        expect(ShapeBorder.lerp(resting, focused, 1), focused);
        expect(ShapeBorder.lerp(focused, resting, 1), resting);
      });

      test('scale keeps the base shape', () {
        final scaled = MxFocusRingBorder(
          base: base,
          ring: ring,
          gap: 2,
        ).scale(0.5) as MxFocusRingBorder;

        expect(scaled.ring.width, 1);
        expect(scaled.gap, 1);
      });
    });
  }

  testWidgets('a rounded ring is concentric: gap and half stroke out', (
    tester,
  ) async {
    final border = MxFocusRingBorder(
      base: RoundedRectangleBorder(borderRadius: radius),
      ring: ring,
      gap: 2,
    );
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: CustomPaint(size: rect.size, painter: _ShapePainter(border)),
      ),
    );

    expect(
      find.byType(CustomPaint).last,
      paints..rrect(
        rrect: radius.toRRect(rect).inflate(3),
        color: ring.color,
        strokeWidth: ring.width,
      ),
    );
  });

  testWidgets('no ring draws nothing beyond the base shape', (tester) async {
    final border = MxFocusRingBorder(
      base: RoundedRectangleBorder(borderRadius: radius),
      gap: 2,
    );
    await tester.pumpWidget(
      Align(
        alignment: Alignment.topLeft,
        child: CustomPaint(size: rect.size, painter: _ShapePainter(border)),
      ),
    );

    expect(find.byType(CustomPaint).last, isNot(paints..rrect()));
  });
}

class _ShapePainter extends CustomPainter {
  const _ShapePainter(this.border);

  final ShapeBorder border;

  @override
  void paint(Canvas canvas, Size size) =>
      border.paint(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(_ShapePainter oldDelegate) => false;
}
