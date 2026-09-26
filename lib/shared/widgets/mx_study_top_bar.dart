import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';

/// Session chrome for the study modes: close, mode badge, a thin progress
/// track and a counter. [accent] (primary by default) drives the
/// badge, its tint and the fill, so one bar carries every mode's colour.
class MxStudyTopBar extends StatelessWidget {
  const MxStudyTopBar({
    super.key,
    required this.modeLabel,
    required this.current,
    required this.total,
    required this.counterLabel,
    required this.closeLabel,
    required this.onClose,
    this.accent,
  }) : assert(total >= 1, 'a session has at least one card'),
       assert(
         current >= 1 && current <= total,
         'current is 1-based and within total',
       );

  final String modeLabel;

  /// 1-based position of the card on screen; the track is never empty once a
  /// session starts.
  final int current;
  final int total;

  /// The localized "n / total" text; the bar draws the fill from [current]
  /// and [total] but holds no copy of its own.
  final String counterLabel;
  final String closeLabel;

  /// Leaving mid-session is the screen's decision; this bar only reports it.
  final VoidCallback onClose;
  final Color? accent;

  static const double _badgeTint = 0.10;
  static const double _trackHeight = 4;

  /// The share of the bar's width the mode chip may take (FE-A6 P3 T1).
  static const double _badgeShare = 0.4;

  /// The share the counter may take before it shrinks (P3 final review).
  static const double _counterShare = 0.25;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = accent ?? colors.primary;
    final styles = context.textStyles;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.standard;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        // Ruling R1: 56 at minimum, grows with text scaling.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.appBar),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
            // The chip is capped so a long mode name at large text ellipsizes
            // instead of squeezing the track away (FE-A6 P3 ruling T1).
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                spacing: AppSpacing.control,
                children: [
                  MxIconButton(
                    icon: AppIcons.close,
                    semanticLabel: closeLabel,
                    onPressed: onClose,
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _badgeShare,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: _badgeTint),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.control,
                          vertical: AppSpacing.micro,
                        ),
                        child: Text(
                          modeLabel.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: styles.studyBadge(accentColor),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: SizedBox(
                        height: _trackHeight,
                        child: ColoredBox(
                          color: MasteryRamp.track(colors),
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(end: current / total),
                              duration: duration,
                              curve: Easing.standard,
                              builder: (context, fraction, _) =>
                                  FractionallySizedBox(
                                    widthFactor: fraction,
                                    heightFactor: 1,
                                    child: ColoredBox(color: accentColor),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // A wide counter shrinks rather than squeeze the track.
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * _counterShare,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(counterLabel, style: styles.counter),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
