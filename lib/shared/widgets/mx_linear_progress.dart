import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A thin progress track (FE-A8 H2): the fill eases to [value] over the
/// progress track, at once under Remove animations. Decorative: the text
/// beside it, or its row's semantics, states the fraction, so it says
/// nothing to TalkBack. Screens 13 and 14 draw it in primary for a
/// session's progress; screen 01 draws [MxLinearProgress.mastery] for a
/// deck's mastery.
class MxLinearProgress extends StatelessWidget {
  const MxLinearProgress({super.key, required this.value})
    : isMastery = false,
      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  /// The deck mastery bar (deck mastery spec D8, D13): 5 tall, filled in
  /// the MasteryRamp colour. Some mastery always shows, and a deck not
  /// wholly mastered never looks full: the fill keeps at least its height
  /// in from either end.
  const MxLinearProgress.mastery({super.key, required this.value})
    : isMastery = true,
      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;
  final bool isMastery;

  static const double _height = 4;
  static const double _masteryHeight = 5;

  double get _barHeight => isMastery ? _masteryHeight : _height;

  /// The width factor drawn for [fraction] on a bar [width] wide.
  double _factor(double fraction, double width) {
    if (!isMastery || fraction <= 0 || fraction >= 1) return fraction;
    final inset = _barHeight / width;
    if (inset >= 0.5) return 0.5;
    return fraction.clamp(inset, 1 - inset);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fill = isMastery
        ? MasteryRamp.fill(context.semanticColors, value)
        : colors.primary;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          height: _barHeight,
          child: ColoredBox(
            color: MasteryRamp.track(colors),
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppDurations.standard,
                  curve: Easing.standard,
                  builder: (context, fraction, _) => FractionallySizedBox(
                    widthFactor: _factor(fraction, constraints.maxWidth),
                    heightFactor: 1,
                    child: fill == null ? null : ColoredBox(color: fill),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
