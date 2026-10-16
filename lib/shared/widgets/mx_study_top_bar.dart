import 'package:flutter/material.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_route_name.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// Session chrome for the study modes: close, mode badge, a thin progress
/// track and a counter. Primary in every mode (critique 2026-09-30 part 3c-2,
/// R8): the badge, its tint and the fill.
class MxStudyTopBar extends StatelessWidget {
  const MxStudyTopBar({
    super.key,
    required this.modeLabel,
    required this.current,
    required this.total,
    required this.counterLabel,
    required this.closeLabel,
    required this.onClose,
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

  /// The share of the bar's width the mode chip may take (FE-A6 P3 T1).
  static const double _badgeShare = 0.4;

  /// The share the counter may take before it shrinks (P3 final review).
  static const double _counterShare = 0.25;

  /// The close glyph and the counter sit on the screen margin; the touch area
  /// reaches past the margin by the glyph's inset.
  EdgeInsetsDirectional _sidePadding(BuildContext context) {
    final glyphInset =
        (context.dimens.sizeControl - context.dimens.sizeIcon) / 2;
    return EdgeInsetsDirectional.only(
      start: context.screenMargin - glyphInset,
      end: context.screenMargin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final accentColor = colors.primary;
    final trackHeight = context.dimens.sizeTrack;
    // The badge text is ink: primaryInk on the primary tint.
    final accentInk = context.accentColor;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Durations.short4;
    return ColoredBox(
      color: colors.surface,
      child: SafeArea(
        bottom: false,
        // Ruling R1: 56 at minimum, grows with text scaling.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.dimens.sizeAppBar),
          child: Padding(
            padding: _sidePadding(context),
            // The chip is capped so a long mode name at large text ellipsizes
            // instead of squeezing the track away (FE-A6 P3 ruling T1).
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                spacing: context.dimens.space8,
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
                      decoration: ShapeDecoration(
                        color: accentColor.tintOver(MxTintBase.of(context)),
                        shape: const StadiumBorder(),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.dimens.space8,
                          vertical: context.dimens.space4,
                        ),
                        // The session route is pushed full screen under this
                        // bar: its mode names the route (DEV-393).
                        child: MxRouteName(
                          child: Text(
                            modeLabel.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.texts.labelSmall?.copyWith(
                              color: accentInk,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                      child: SizedBox(
                        height: trackHeight,
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
                      child: Text(
                        counterLabel,
                        style: context.texts.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
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
