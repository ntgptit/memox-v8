import 'package:flutter/material.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
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
  });

  final Widget child;

  /// No padding, for rows that run edge to edge. The card clips them to its
  /// radius, so their dividers meet the corners.
  final bool isFullBleed;

  /// The surface-hero tint, with the ghost edge in both themes.
  final bool isHero;

  @override
  Widget build(BuildContext context) {
    final surface = isHero
        ? AppDecorations.heroCard(context.colors, context.derivedColors)
        : AppDecorations.raisedCard(context.colors, context.derivedColors);
    final radius = surface.borderRadius!;
    final edge = surface.border as Border?;
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
