import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_soft_ground.dart';

/// The base surface: the card ground with the border hairline in both themes
/// and the whisper shadow where the theme casts one. It is a Material, so the ripple of a row
/// inside paints on the card instead of under its fill (ruling S14).
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

  /// The surface-hero tint, with the ghost edge in both themes.
  final bool isHero;

  /// The warning-soft ground with the warning border (screen 02's locked
  /// strip, owner decision D-O1).
  final bool isWarning;

  /// A primary edge at the control weight over the card's own ground: a
  /// picked row of a selection (screen 07).
  final bool isSelected;

  /// The success-soft ground with the success border: a finished session
  /// (FE-A6 D14).
  final bool isSuccess;

  /// The danger-soft ground with the destructive border: a session stopped
  /// by an error (FE-A6 D14).
  final bool isDanger;

  /// The container-low ground, flat, with the ghost edge: the answer face of
  /// a study card (kit StudyFaceCard, screen 16a).
  final bool isRecessed;

  @override
  Widget build(BuildContext context) {
    final surface = switch ((
      isHero,
      isWarning,
      isSuccess,
      isDanger,
      isRecessed,
    )) {
      (true, _, _, _, _) => AppDecorations.heroCard(
        context.colors,
        context.semanticColors,
      ),
      (_, true, _, _, _) => AppDecorations.warningCard(
        context.colors,
        context.semanticColors,
      ),
      (_, _, true, _, _) => AppDecorations.successCard(
        context.colors,
        context.semanticColors,
      ),
      (_, _, _, true, _) => AppDecorations.dangerCard(
        context.colors,
        context.semanticColors,
      ),
      (_, _, _, _, true) => AppDecorations.recessedCard(
        context.colors,
        context.semanticColors,
      ),
      _ => AppDecorations.raisedCard(context.colors, context.semanticColors),
    };
    final radius = surface.borderRadius!;
    final edge = isSelected
        ? Border.all(color: context.colors.primary, width: AppStroke.control)
        : surface.border as Border?;
    final padded = Padding(
      padding: isFullBleed
          ? EdgeInsets.zero
          : const EdgeInsets.all(AppSpacing.card),
      child: child,
    );
    // A toned card is a soft ground, light in both themes: its content
    // renders in Day (spec 2026-10-10 D4).
    final isSoft = isWarning || isSuccess || isDanger;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: surface.boxShadow,
        ),
        child: Material(
          color: surface.color,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: edge?.top ?? BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: isSoft ? MxSoftGround(child: padded) : padded,
        ),
      ),
    );
  }
}
