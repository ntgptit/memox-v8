import 'package:flutter/material.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The 2 dp keyboard-focus ring, in `primary`, drawn 2 dp outside
/// [shape] (DESIGN.md, Shapes). It paints over nothing and takes no space.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.isVisible,
    required this.shape,
    required this.child,
  });

  final bool isVisible;
  final ShapeBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: isVisible
        ? _RingPainter(shape, context.colors.primary)
        : null,
    child: child,
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.shape, this.color);

  final ShapeBorder shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppStroke.focusOffset + AppStroke.focus / 2;
    final rect = (Offset.zero & size).inflate(inset);
    canvas.drawPath(
      shape.getOuterPath(rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.focus
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.shape != shape || old.color != color;
}
