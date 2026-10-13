import 'package:flutter/material.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// The base surface: a [Card], so it takes the theme's card colour, radius, and
/// the absence of border and shadow. The tones below change only the ground. It
/// is a Material, so the ripple of a row inside paints on the card instead of
/// under its fill (ruling S14).
class MxCard extends StatelessWidget {
  const MxCard({
    super.key,
    required this.child,
    this.isFullBleed = false,
    this.isHero = false,
    this.isWarning = false,
    this.isSelected = false,
    this.isSuccess = false,
    this.isDanger = false,
    this.isRecessed = false,
  }) : assert(
         (isHero ? 1 : 0) +
                 (isWarning ? 1 : 0) +
                 (isSuccess ? 1 : 0) +
                 (isDanger ? 1 : 0) +
                 (isRecessed ? 1 : 0) <=
             1,
         'one tone at most',
       );

  final Widget child;

  /// No padding, for rows that run edge to edge. The card clips them to its
  /// radius, so their dividers meet the corners.
  final bool isFullBleed;

  /// The accent tint over the page surface.
  final bool isHero;

  /// The warning tint over the page surface (screen 02's locked strip, owner
  /// decision D-O1).
  final bool isWarning;

  /// A primary edge at the control weight over the card's own ground: a
  /// picked row of a selection (screen 07).
  final bool isSelected;

  /// The success tint over the page surface: a finished session (FE-A6 D14).
  final bool isSuccess;

  /// The error tint over the page surface: a session stopped by an error
  /// (FE-A6 D14).
  final bool isDanger;

  /// The container-low ground: the answer face of a study card (kit
  /// StudyFaceCard, screen 16a).
  final bool isRecessed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final ground = switch ((
      isHero,
      isWarning,
      isSuccess,
      isDanger,
      isRecessed,
    )) {
      (true, _, _, _, _) => context.accentColor.tintOver(colors.surface),
      (_, true, _, _, _) => context.mxColors.warning.tintOver(colors.surface),
      (_, _, true, _, _) => context.mxColors.success.tintOver(colors.surface),
      (_, _, _, true, _) => colors.error.tintOver(colors.surface),
      (_, _, _, _, true) => colors.surfaceContainerLow,
      _ => null,
    };
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: ground,
        shape: isSelected
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(dimens.radiusMd),
                side: BorderSide(
                  color: colors.primary,
                  width: dimens.strokeControl,
                ),
              )
            : null,
        child: Padding(
          padding: isFullBleed
              ? EdgeInsets.zero
              : EdgeInsets.all(dimens.space24),
          child: child,
        ),
      ),
    );
  }
}
