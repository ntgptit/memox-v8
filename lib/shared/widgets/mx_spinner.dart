import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// One spinner revolution.
const Duration _cycle = Duration(milliseconds: 800);

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
    this.color,
    this.semanticLabel,
  });

  final MxSpinnerSize size;

  /// The ring colour. Null is the accent, for a spinner on a surface; a
  /// spinner on a fill passes the foreground that fill is read with, so it
  /// keeps its contrast (M3F-02).
  final Color? color;

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
    duration: _cycle,
  )..repeat();

  @override
  void dispose() {
    _turns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = switch (widget.size) {
      MxSpinnerSize.inline => context.dimens.sizeIconInline,
      MxSpinnerSize.compact => context.dimens.sizeIconCompact,
      MxSpinnerSize.standard => context.dimens.sizeIcon,
      MxSpinnerSize.large => context.dimens.sizeIconTile,
    };
    final ring = SizedBox.square(
      dimension: dimension,
      child: RotationTransition(
        turns: _turns,
        child: CustomPaint(
          painter: _RingPainter(
            color: widget.color ?? context.accentColor,
            stroke: context.dimens.strokeIndicator,
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
  const _RingPainter({required this.color, required this.stroke});

  final Color color;
  final double stroke;

  /// Three quarters drawn, one open.
  static const double _sweep = 1.5 * math.pi;
  static const double _start = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final ring = (Offset.zero & size).deflate(stroke / 2);
    canvas.drawArc(
      ring,
      _start,
      _sweep,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}
