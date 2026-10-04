import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/surface_style.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

export 'package:memox/core/theme/components/surface_style.dart' show MxCardTone;

/// A surface that groups content (DESIGN.md, Containers › MxCard): r12, a
/// 20 interior, one tone at a time. Its content reads in the tone's colour.
class MxCard extends StatelessWidget {
  const MxCard({
    required this.child,
    this.tone = MxCardTone.raised,
    this.isSelected = false,
    this.isFullBleed = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final MxCardTone tone;

  /// Chosen: a 2dp Indigo Accent edge (The Selection Ladder Rule).
  final bool isSelected;

  /// Rows that run edge to edge: no interior padding, clipped to the corners.
  final bool isFullBleed;

  /// Makes the whole card one tappable surface.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final surface = mxCardSurface(
      context.colors,
      context.semanticColors,
      tone: tone,
      isSelected: isSelected,
    );
    final BorderRadius radius = BorderRadius.circular(AppRadius.md);
    Widget body = isFullBleed
        ? child
        : Padding(padding: const EdgeInsets.all(AppSpacing.card), child: child);
    body = IconTheme.merge(
      data: IconThemeData(color: surface.content),
      child: DefaultTextStyle.merge(
        style: context.texts.bodyMedium?.apply(color: surface.content),
        child: body,
      ),
    );
    final VoidCallback? tap = onTap;
    if (tap != null) {
      body = MxRowInk(onTap: tap, borderRadius: radius, child: body);
    }
    final Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: surface.ground,
        borderRadius: radius,
        border: Border.fromBorderSide(surface.edge),
        boxShadow: surface.shadows,
      ),
      child: ClipRRect(borderRadius: radius, child: body),
    );
    if (tap == null) {
      return card;
    }
    return MxFocusRing(borderRadius: radius, child: card);
  }
}
