import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_easing.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';

/// A thin progress track ("Flashcard Color Tokens" §6): 4 tall, a pill, the
/// mastery fill easing to [value] over the surfaceContainerHighest track, at
/// once under Remove animations. Any progress shows at least as wide as the
/// track is tall. Decorative: the text beside it, or its row's semantics,
/// states the fraction, so it says nothing to TalkBack. Screens 13 and 14
/// draw it for a session's progress; screen 01 draws
/// [MxLinearProgress.mastery] for a deck's mastery.
class MxLinearProgress extends StatelessWidget {
  const MxLinearProgress({super.key, required this.value})
    : isMastery = false,
      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  /// The deck mastery bar (deck mastery spec D8, D13): a deck not wholly
  /// mastered never looks full, the fill stopping its height short of the
  /// end.
  const MxLinearProgress.mastery({super.key, required this.value})
    : isMastery = true,
      assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;
  final bool isMastery;

  /// The width factor drawn for [fraction] on a bar [width] wide.
  double _factor(double fraction, double width) {
    if (fraction <= 0 || fraction >= 1) return fraction;
    final inset = AppSize.progressTrack / width;
    if (inset >= 0.5) return 0.5;
    final ceiling = isMastery ? 1 - inset : 1.0;
    return fraction.clamp(inset, ceiling);
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: SizedBox(
          height: AppSize.progressTrack,
          child: ColoredBox(
            color: MasteryRamp.track(context.colors),
            child: LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: value),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : AppDurations.standard,
                  curve: AppEasing.standard,
                  builder: (context, fraction, _) => FractionallySizedBox(
                    widthFactor: _factor(fraction, constraints.maxWidth),
                    heightFactor: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: ColoredBox(color: context.semanticColors.mastery),
                    ),
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
