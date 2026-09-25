import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The icon step a spinner is drawn at, so it drops into a button, a row or a
/// card without a new number.
enum MxSpinnerSize { inline, compact, standard, large }

/// The indeterminate ring: 2px, one quarter open, one turn every 0.8s. It
/// keeps turning under reduced motion (ruling O1), because it is the only
/// sign that work is in flight.
class MxSpinner extends StatefulWidget {
  const MxSpinner({
    super.key,
    this.size = MxSpinnerSize.inline,
    this.isOnFill = false,
    this.semanticLabel,
  });

  final MxSpinnerSize size;

  /// Inside a filled (primary or destructive) button: onPrimary, not primary
  /// (ruling O2).
  final bool isOnFill;

  /// What is in flight, for a screen reader (§9 row 61). Null keeps the
  /// spinner silent, as inside a button that already names its work.
  final String? semanticLabel;

  @override
  State<MxSpinner> createState() => _MxSpinnerState();
}

class _MxSpinnerState extends State<MxSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turns = AnimationController(
    vsync: this,
    duration: AppDurations.spinnerCycle,
  )..repeat();

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimension = switch (widget.size) {
      MxSpinnerSize.inline => AppIconSize.inline,
      MxSpinnerSize.compact => AppIconSize.compact,
      MxSpinnerSize.standard => AppIconSize.standard,
      MxSpinnerSize.large => AppIconSize.large,
    };
    final ring = SizedBox.square(
      dimension: dimension,
      child: RotationTransition(
        turns: _turns,
        child: CustomPaint(
          painter: _RingPainter(
            color: widget.isOnFill ? colors.onPrimary : colors.primary,
          ),
        ),
      ),
    );
    final label = widget.semanticLabel;
    if (label == null) return ExcludeSemantics(child: ring);
    return Semantics(label: label, child: ring);
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color});

  final Color color;

  /// Three quarters drawn, one open.
  static const double _sweep = 1.5 * math.pi;
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = (Offset.zero & size).deflate(AppStroke.indicator / 2);
    canvas.drawArc(
      ring,
      _start,
      _sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.indicator,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}
