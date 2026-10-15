import 'package:flutter/material.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// A thin progress track (FE-A8 H2): the fill eases to [value] over the
/// progress track, at once under Remove animations. Decorative: the text
/// beside it, or its row's semantics, states the fraction, so it says
/// nothing to TalkBack. Screens 13 and 14 draw it in the success container for
/// a session's progress; screen 01 draws [MxLinearProgress.mastery] for a
/// deck's mastery. Both are `sizeTrack` tall.
class MxLinearProgress extends StatelessWidget {
  const MxLinearProgress({super.key, required this.value})
    : isMastery = false,
      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  /// The deck mastery bar (deck mastery spec D8, D13): filled in
  /// the MasteryRamp colour. Some mastery always shows, and a deck not
  /// wholly mastered never looks full: the fill keeps at least its height
  /// in from either end.
  const MxLinearProgress.mastery({super.key, required this.value})
    : isMastery = true,
      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;
  final bool isMastery;

  /// The width factor drawn for [fraction] on a bar [width] wide.
  double _factor(double fraction, double width, double height) {
    if (!isMastery || fraction <= 0 || fraction >= 1) return fraction;
    final inset = height / width;
    if (inset >= 0.5) return 0.5;
    return fraction.clamp(inset, 1 - inset);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final height = context.dimens.sizeTrack;
    final fill = isMastery
        ? MasteryRamp.fill(context.mxColors, context.accentColor, value)
        : context.mxColors.successContainer;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: MasteryRamp.track(colors),
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : Durations.short4,
                  curve: Easing.standard,
                  builder: (context, fraction, _) => FractionallySizedBox(
                    widthFactor: _factor(
                      fraction,
                      constraints.maxWidth,
                      height,
                    ),
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
