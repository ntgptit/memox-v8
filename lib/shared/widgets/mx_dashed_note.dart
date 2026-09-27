import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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
      foregroundPainter: _DashedBorder(color: colors.outlineVariant),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.gutter,
            vertical: AppSpacing.section,
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: context.textStyles.noteText,
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle's outline in dashes, drawn over the box.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color});

  final Color color;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = AppStroke.hairline / 2;
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset,
            size.width - AppStroke.hairline,
            size.height - AppStroke.hairline,
          ),
          const Radius.circular(AppRadius.md),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.hairline;
    for (final metric in outline.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += _dash + _gap) {
        canvas.drawPath(metric.extractPath(start, start + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder oldDelegate) => oldDelegate.color != color;
}
