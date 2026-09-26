import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The size steps, each with one role: small leads content rows, medium
/// leads settings rows, large leads deck rows.
enum MxIconTileSize { small, medium, large }

/// The fill: the primary or seed tint (default), or a solid primary or
/// warning square whose glyph takes the matching on-colour (screen 02's lock
/// strip, owner decision D-O1). [success], [caution] and [danger] are soft
/// tints with a legible glyph: the session summary's outcomes (FE-A6 D14).
enum MxIconTileTone { tinted, primary, warning, success, caution, danger }

/// The tinted square that leads a row. It never shrinks; the text beside it
/// gives up space first.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    super.key,
    this.icon,
    this.child,
    this.size = MxIconTileSize.small,
    this.seed,
    this.tone = MxIconTileTone.tinted,
  }) : assert((icon == null) != (child == null), 'an icon or a child'),
       assert(
         seed == null || tone == MxIconTileTone.tinted,
         'a seed only tints',
       );

  final IconData? icon;

  /// Replaces the glyph: a letter, a count, a donut.
  final Widget? child;
  final MxIconTileSize size;

  /// A per-deck colour from the caller's data (ruling S16). Null tints with
  /// primary.
  final Color? seed;
  final MxIconTileTone tone;

  static const double _smallBox = 28;
  static const double _mediumBox = 36;
  static const double _largeBox = 44;
  static const double _primaryTintLight = 0.10;
  static const double _primaryTintDark = 0.16;
  static const double _seedTint = 0.12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tinted = seed ?? colors.primary;
    final tint = switch ((seed, colors.brightness)) {
      (_?, _) => _seedTint,
      (null, Brightness.light) => _primaryTintLight,
      (null, Brightness.dark) => _primaryTintDark,
    };
    final (box, radius, glyph) = switch (size) {
      MxIconTileSize.small => (_smallBox, AppRadius.sm, AppIconSize.inline),
      MxIconTileSize.medium => (_mediumBox, AppRadius.md, AppIconSize.compact),
      MxIconTileSize.large => (_largeBox, AppRadius.md, AppIconSize.compact),
    };
    final (fill, ink) = switch (tone) {
      MxIconTileTone.tinted => (
        tinted.withValues(alpha: tint),
        seed ?? context.derivedColors.primaryInk,
      ),
      MxIconTileTone.primary => (colors.primary, colors.onPrimary),
      MxIconTileTone.warning => (
        context.semanticColors.warning,
        context.semanticColors.onWarning,
      ),
      MxIconTileTone.success => (
        context.derivedColors.successSoft,
        context.derivedColors.successInk,
      ),
      MxIconTileTone.caution => (
        context.derivedColors.warningSoft,
        context.derivedColors.warningInk,
      ),
      MxIconTileTone.danger => (
        context.derivedColors.dangerSoft,
        context.colors.error,
      ),
    };
    return SizedBox.square(
      dimension: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: child ?? Icon(icon, size: glyph, color: ink),
        ),
      ),
    );
  }
}
