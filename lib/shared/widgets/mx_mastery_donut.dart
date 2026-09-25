import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The circular mastery indicator. The ring fills clockwise from twelve
/// o'clock in the MasteryRamp colour, and the percentage uses the same
/// colour, so the number and the ring never disagree.
class MxMasteryDonut extends StatelessWidget {
  const MxMasteryDonut({super.key, required this.fraction, this.semanticLabel})
    : assert(fraction >= 0 && fraction <= 1, 'fraction is within [0, 1]');

  final double fraction;

  /// What the percentage measures ("Mastered"), read before it (§9 row 61).
  /// Null reads the percentage alone.
  final String? semanticLabel;

  static const double _box = 56;

  /// The kit's geometry: r 17 and stroke 3 on a 40 viewBox, scaled to the
  /// box.
  static const double _viewBox = 40;
  static const double _viewRadius = 17;
  static const double _viewStroke = 3;
  static const double _scale = _box / _viewBox;

  /// The clear space inside the stroke, where the label scales down to fit
  /// (ruling S10).
  static const double _innerDiameter = (_viewRadius * 2 - _viewStroke) * _scale;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    // Ruling S10: 0% falls in the lowest band, so its label takes that colour.
    final ink = MasteryRamp.fill(semantic, fraction) ?? semantic.statusLearning;
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    ).format(fraction);
    final donut = SizedBox.square(
      dimension: _box,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: fraction,
          arc: ink,
          // Ruling S10: the contract's track, not the ramp's progress-track.
          track: context.colors.surfaceContainer,
        ),
        child: Center(
          child: SizedBox.square(
            dimension: _innerDiameter,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(percent, style: context.textStyles.donutLabel(ink)),
            ),
          ),
        ),
      ),
    );
    final label = semanticLabel;
    if (label == null) return donut;
    return Semantics(
      label: label,
      value: percent,
      excludeSemantics: true,
      child: donut,
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fraction,
    required this.arc,
    required this.track,
  });

  final double fraction;
  final Color arc;
  final Color track;

  static const double _fullTurn = 2 * math.pi;
  static const double _twelveOClock = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = MxMasteryDonut._viewRadius * MxMasteryDonut._scale;
    canvas.drawCircle(center, radius, _stroke(track));
    if (fraction == 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _twelveOClock,
      _fullTurn * fraction,
      false,
      _stroke(arc),
    );
  }

  Paint _stroke(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = MxMasteryDonut._viewStroke * MxMasteryDonut._scale
    ..strokeCap = StrokeCap.round;

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.fraction != fraction ||
      oldDelegate.arc != arc ||
      oldDelegate.track != track;
}
