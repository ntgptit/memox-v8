import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_component_themes.dart';

/// The one pinned action: the Material 3 regular FAB, a square icon-only box
/// styled by the theme's `FloatingActionButtonThemeData`. V3 has no extended
/// FAB. [semanticLabel] is the accessible name and is never painted.
/// Placement belongs to MxAppShell.
class MxFab extends StatefulWidget {
  const MxFab({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onPressed;

  @override
  State<MxFab> createState() => _MxFabState();
}

class _MxFabState extends State<MxFab> {
  bool _focused = false;

  MxFocusRingRoundedBorder _shape(ThemeTokens t) => MxFocusRingRoundedBorder(
    borderRadius: t.radius(t.dimens.radiusLg),
    ring: _focused
        ? BorderSide(color: t.scheme.primary, width: t.dimens.strokeFocus)
        : BorderSide.none,
    gap: t.dimens.strokeFocusGap,
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      excludeSemantics: true,
      onTap: widget.onPressed,
      // The theme's shape is not state-aware, so the focus ring is set here.
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: FloatingActionButton(
          onPressed: widget.onPressed,
          // The default tag is shared, so two FABs in one route would clash.
          heroTag: null,
          shape: _shape(ThemeTokens.of(context)),
          child: Icon(widget.icon),
        ),
      ),
    );
  }
}

/// [MxFocusRingBorder] for a rounded rectangle: the same offset ring on a
/// container with a fixed corner radius, such as the FAB.
class MxFocusRingRoundedBorder extends RoundedRectangleBorder {
  const MxFocusRingRoundedBorder({
    super.side,
    super.borderRadius,
    this.ring = BorderSide.none,
    this.gap = 0,
  });

  final BorderSide ring;

  /// Distance between the container's edge and the ring's inner edge.
  final double gap;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    super.paint(canvas, rect, textDirection: textDirection);
    if (ring.style == BorderStyle.none) return;
    final grow = gap + ring.width / 2;
    final outer = borderRadius
        .resolve(textDirection)
        .toRRect(rect)
        .inflate(grow);
    canvas.drawRRect(outer, ring.toPaint());
  }

  @override
  MxFocusRingRoundedBorder copyWith({
    BorderSide? side,
    BorderRadiusGeometry? borderRadius,
  }) => MxFocusRingRoundedBorder(
    side: side ?? this.side,
    borderRadius: borderRadius ?? this.borderRadius,
    ring: ring,
    gap: gap,
  );

  @override
  ShapeBorder scale(double t) => MxFocusRingRoundedBorder(
    side: side.scale(t),
    borderRadius: borderRadius * t,
    ring: ring.scale(t),
    gap: gap * t,
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) =>
      a is MxFocusRingRoundedBorder ? _lerp(a, this, t) : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) =>
      b is MxFocusRingRoundedBorder ? _lerp(this, b, t) : super.lerpTo(b, t);

  static MxFocusRingRoundedBorder _lerp(
    MxFocusRingRoundedBorder a,
    MxFocusRingRoundedBorder b,
    double t,
  ) => MxFocusRingRoundedBorder(
    side: BorderSide.lerp(a.side, b.side, t),
    borderRadius: BorderRadiusGeometry.lerp(a.borderRadius, b.borderRadius, t)!,
    ring: BorderSide.lerp(a.ring, b.ring, t),
    gap: lerpDouble(a.gap, b.gap, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is MxFocusRingRoundedBorder &&
      other.side == side &&
      other.borderRadius == borderRadius &&
      other.ring == ring &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(side, borderRadius, ring, gap);

  @override
  String toString() =>
      'MxFocusRingRoundedBorder($side, $borderRadius, ring: $ring, gap: $gap)';
}
