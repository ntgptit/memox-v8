import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A ring that fills clockwise from twelve o'clock: [fraction] of it in
/// [arc] with round caps over a full [track]. The one donut painter of the
/// app (audit 2026-10-19, G4): `MxMasteryDonut` and the TOPIK score donut
/// both draw with it. It fills the box its parent gives it; [child] sits in
/// the middle.
class MxDonut extends StatelessWidget {
  const MxDonut({
    super.key,
    required this.fraction,
    required this.arc,
    required this.track,
    required this.strokeWidth,
    this.radius,
    this.child,
  }) : assert(fraction >= 0 && fraction <= 1, 'fraction is within [0, 1]');

  final double fraction;
  final Color arc;
  final Color track;
  final double strokeWidth;

  /// The radius of the stroke's centre line; null fills the box.
  final double? radius;
  final Widget? child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DonutPainter(
      fraction: fraction,
      arc: arc,
      track: track,
      strokeWidth: strokeWidth,
      radius: radius,
    ),
    child: Center(child: child),
  );
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fraction,
    required this.arc,
    required this.track,
    required this.strokeWidth,
    required this.radius,
  });

  final double fraction;
  final Color arc;
  final Color track;
  final double strokeWidth;
  final double? radius;

  static const double _fullTurn = 2 * math.pi;
  static const double _twelveOClock = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final ring = radius ?? (size.shortestSide - strokeWidth) / 2;
    canvas.drawCircle(center, ring, _stroke(track));
    if (fraction == 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ring),
      _twelveOClock,
      _fullTurn * fraction,
      false,
      _stroke(arc),
    );
  }

  Paint _stroke(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.arc != arc ||
      oldDelegate.track != track ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
