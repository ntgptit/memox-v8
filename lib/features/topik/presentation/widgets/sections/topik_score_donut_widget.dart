import 'dart:math';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/l10n/l10n_context.dart';

/// Screen 38's donut (detail file 38, critique S3): the correct answers of
/// the questions, a `success` arc on the `surfaceContainerHighest` track,
/// "{correct} / {total}" inside. A topik widget, not MxMasteryDonut, which
/// draws the mastery ramp. Its row says the figures to TalkBack.
class TopikScoreDonutWidget extends StatelessWidget {
  const TopikScoreDonutWidget({
    super.key,
    required this.correct,
    required this.total,
  });

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return SizedBox.square(
      dimension: dimens.sizeControl * 2,
      child: CustomPaint(
        painter: _DonutPainter(
          fraction: total == 0 ? 0 : correct / total,
          track: context.colors.surfaceContainerHighest,
          arc: context.mxColors.success,
          width: dimens.space8,
        ),
        child: Center(
          child: Text(
            context.l10n.topikOfTotal(correct, total),
            style: context.texts.titleMedium,
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.fraction,
    required this.track,
    required this.arc,
    required this.width,
  });

  final double fraction;
  final Color track;
  final Color arc;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, 0, 2 * pi, false, stroke..color = track);
    if (fraction <= 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * fraction,
      false,
      stroke..color = arc,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.fraction != fraction ||
      old.track != track ||
      old.arc != arc ||
      old.width != width;
}
