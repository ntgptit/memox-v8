import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A thin progress track (FE-A8 H2): the fill eases to [value] in primary
/// over the progress track, at once under Remove animations. Decorative:
/// the text beside it states the fraction, so it says nothing to TalkBack.
/// Screens 13 and 14 draw it for a session's progress.
class MxLinearProgress extends StatelessWidget {
  const MxLinearProgress({super.key, required this.value})
    : assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;

  static const double _height = 4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          height: _height,
          child: ColoredBox(
            color: MasteryRamp.track(colors),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: value),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : AppDurations.standard,
                curve: Easing.standard,
                builder: (context, fraction, _) => FractionallySizedBox(
                  widthFactor: fraction,
                  heightFactor: 1,
                  child: ColoredBox(color: colors.primary),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
