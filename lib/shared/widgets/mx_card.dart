import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The base surface. Light lifts it with the whisper shadow; dark draws the
/// hairline ghost edge instead. It is a Material, so the ripple of a row
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
  }) : assert(
         (isHero ? 1 : 0) +
                 (isWarning ? 1 : 0) +
                 (isSuccess ? 1 : 0) +
                 (isDanger ? 1 : 0) <=
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

  @override
  Widget build(BuildContext context) {
    final surface = switch ((isHero, isWarning, isSuccess, isDanger)) {
      (true, _, _, _) => AppDecorations.heroCard(
        context.colors,
        context.derivedColors,
      ),
      (_, true, _, _) => AppDecorations.warningCard(
        context.colors,
        context.derivedColors,
      ),
      (_, _, true, _) => AppDecorations.successCard(
        context.colors,
        context.derivedColors,
      ),
      (_, _, _, true) => AppDecorations.dangerCard(
        context.colors,
        context.derivedColors,
      ),
      _ => AppDecorations.raisedCard(context.colors, context.derivedColors),
    };
    final radius = surface.borderRadius!;
    final edge = isSelected
        ? Border.all(color: context.colors.primary, width: AppStroke.control)
        : surface.border as Border?;
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
          child: Padding(
            padding: isFullBleed
                ? EdgeInsets.zero
                : const EdgeInsets.all(AppSpacing.card),
            child: child,
          ),
        ),
      ),
    );
  }
}
