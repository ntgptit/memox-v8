import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The place a chart or a figure takes once there is something to show
/// (kit 22's per-chart empty, FE-A9 D6): one centred line in a muted box
/// with a dashed hairline. A fact, never an error and never an action.
class MxDashedNote extends StatelessWidget {
  const MxDashedNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return CustomPaint(
      foregroundPainter: _DashedBorder(
        color: colors.border,
        stroke: context.hairline,
        radius: context.radii.md.topLeft.x,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.muted,
          borderRadius: context.radii.md,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.dimens.space16,
            vertical: context.dimens.space24,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.texts.body.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle's outline in dashes, drawn over the box.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({
    required this.color,
    required this.stroke,
    required this.radius,
  });

  final Color color;
  final double stroke;
  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final inset = stroke / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - stroke,
            size.height - stroke,
          ),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.stroke != stroke ||
      oldDelegate.radius != radius;
}
