import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart'
    show MxLinearProgressTone;

/// A bar's thickness.
enum MxLinearProgressSize {
  regular(AppSize.progress),
  thick(AppSize.progressThick);

  const MxLinearProgressSize(this.height);

  final double height;
}

/// A determinate bar (DESIGN.md, MxLinearProgress): a flat fill on a
/// `surface-container-low` pill track, never a gradient. It knows a value, a
/// tone, a size and what TalkBack reads; it knows nothing of mastery, which
/// is composed on top of it. Any value above 0 shows at least a dot as long
/// as the bar is thick, so a small share never reads as none.
class MxLinearProgress extends StatelessWidget {
  const MxLinearProgress({
    required this.value,
    required this.semanticLabel,
    this.semanticValue,
    this.tone = MxLinearProgressTone.secondary,
    this.size = MxLinearProgressSize.regular,
    super.key,
  }) : assert(value >= 0 && value <= 1, 'value is a fraction in [0, 1]');

  final double value;

  /// What the bar measures, read aloud.
  final String semanticLabel;

  /// The localized value read aloud ("62%", "12 of 20").
  final String? semanticValue;
  final MxLinearProgressTone tone;
  final MxLinearProgressSize size;

  @override
  Widget build(BuildContext context) {
    final paint = mxProgressColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    final bool isStill = MediaQuery.disableAnimationsOf(context);
    final BorderRadius pill = BorderRadius.circular(AppRadius.full);
    return Semantics(
      label: semanticLabel,
      value: semanticValue,
      child: SizedBox(
        height: size.height,
        child: DecoratedBox(
          decoration: BoxDecoration(color: paint.track, borderRadius: pill),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: value),
            duration: isStill ? Duration.zero : AppDurations.standard,
            builder: (context, fraction, _) => LayoutBuilder(
              builder: (context, track) {
                if (fraction <= 0) {
                  return const SizedBox.shrink();
                }
                final double share = track.maxWidth * fraction;
                return Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: SizedBox(
                    width: share < size.height ? size.height : share,
                    height: size.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: paint.fill,
                        borderRadius: pill,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
