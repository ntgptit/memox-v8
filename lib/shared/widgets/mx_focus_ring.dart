import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// Where the ring sits against its control.
enum MxFocusRingPlacement {
  /// `AppStroke.focusOffset` outside the control: buttons, chips, the
  /// toggle, the stepper, anything with room around it.
  outside,

  /// Inset by the same offset: a full-bleed row under a clipping card, where
  /// an outside ring would be cut off (spec 2026-10-08 §4.13 round 2, P1).
  inside,
}

/// The one focus ring (spec 2026-10-08 §4.13 P1): `AppStroke.focus` in
/// `primaryForeground`, drawn around [child] while focus is inside it. The
/// ring always borders the ground, never the control's fill, so it is one
/// measured pair on every ground (`token_contrast_test.dart`).
class MxFocusRing extends StatefulWidget {
  const MxFocusRing({
    super.key,
    required this.radius,
    this.placement = MxFocusRingPlacement.outside,
    required this.child,
  });

  /// The control's corner radius; the ring follows it.
  final BorderRadius radius;
  final MxFocusRingPlacement placement;
  final Widget child;

  @override
  State<MxFocusRing> createState() => _MxFocusRingState();
}

class _MxFocusRingState extends State<MxFocusRing> {
  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    // Not a focus target itself: it only hears its descendants' focus.
    final child = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      child: widget.child,
    );
    if (!_hasFocus) return child;
    return CustomPaint(
      foregroundPainter: MxFocusRingPainter(
        color: context.semanticColors.primaryForeground,
        radius: widget.radius,
        placement: widget.placement,
      ),
      child: child,
    );
  }
}

/// Paints the ring; public so a test can read its geometry.
class MxFocusRingPainter extends CustomPainter {
  const MxFocusRingPainter({
    required this.color,
    required this.radius,
    required this.placement,
  });

  final Color color;
  final BorderRadius radius;
  final MxFocusRingPlacement placement;

  /// The ring's centreline rect for a control of [size].
  Rect ringRect(Size size) {
    final delta = AppStroke.focusOffset + AppStroke.focus / 2;
    final rect = Offset.zero & size;
    return switch (placement) {
      MxFocusRingPlacement.outside => rect.inflate(delta),
      MxFocusRingPlacement.inside => rect.deflate(delta),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = ringRect(size);
    final rrect = switch (placement) {
      MxFocusRingPlacement.outside =>
        radius.toRRect(Offset.zero & size).inflate(rect.left.abs()),
      MxFocusRingPlacement.inside =>
        radius.toRRect(Offset.zero & size).deflate(rect.left),
    };
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.focus
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(MxFocusRingPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.placement != placement;
}
