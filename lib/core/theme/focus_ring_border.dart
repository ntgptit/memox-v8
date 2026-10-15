import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Wraps any [OutlinedBorder] [base] (a stadium for buttons, a rounded
/// rectangle for the FAB and the chips) and also draws the focus ring: [ring]
/// painted [gap] outside the container, so it shows on any fill, a `primary`
/// one included. A [ring] of [BorderSide.none] draws nothing.
///
/// `ButtonStyle` has no focus-indicator slot, and a `side` is drawn on the
/// container's own edge, so the ring rides on the shape: the Material paints
/// it unclipped, outside the container, and the ink still clips to
/// [getOuterPath], which is the plain [base].
class MxFocusRingBorder extends OutlinedBorder {
  // The side is the base's, so a ButtonStyle's `copyWith(side:)` and the
  // default [dimensions] read it.
  MxFocusRingBorder({
    required this.base,
    this.ring = BorderSide.none,
    this.gap = 0,
  }) : super(side: base.side);

  final OutlinedBorder base;
  final BorderSide ring;

  /// Distance between the container's edge and the ring's inner edge.
  final double gap;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      base.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      base.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    base.paint(canvas, rect, textDirection: textDirection);
    if (ring.style == BorderStyle.none) return;
    final grow = gap + ring.width / 2;
    // A rounded corner grows with the ring, so the ring stays concentric.
    if (base case RoundedRectangleBorder(:final borderRadius)) {
      canvas.drawRRect(
        borderRadius.resolve(textDirection).toRRect(rect).inflate(grow),
        ring.toPaint(),
      );
      return;
    }
    canvas.drawPath(
      base.getOuterPath(rect.inflate(grow), textDirection: textDirection),
      ring.toPaint(),
    );
  }

  @override
  MxFocusRingBorder copyWith({BorderSide? side}) => MxFocusRingBorder(
    base: base.copyWith(side: side),
    ring: ring,
    gap: gap,
  );

  @override
  ShapeBorder scale(double t) => MxFocusRingBorder(
    base: base.scale(t) as OutlinedBorder,
    ring: ring.scale(t),
    gap: gap * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is MxFocusRingBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is MxFocusRingBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  static MxFocusRingBorder _lerp(
    MxFocusRingBorder a,
    MxFocusRingBorder b,
    double t,
  ) => MxFocusRingBorder(
    base: OutlinedBorder.lerp(a.base, b.base, t)!,
    ring: BorderSide.lerp(a.ring, b.ring, t),
    gap: lerpDouble(a.gap, b.gap, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is MxFocusRingBorder &&
      other.base == base &&
      other.ring == ring &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(base, ring, gap);

  @override
  String toString() => 'MxFocusRingBorder($base, ring: $ring, gap: $gap)';
}
