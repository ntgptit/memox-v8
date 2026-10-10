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

  /// The small step's side, for a caller that sizes the row around it.
  static const double smallBox = 28;

  /// The medium step's side, for a caller that indents past it.
  static const double mediumBox = 36;
  static const double _largeBox = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final semantic = context.semanticColors;
    final (box, radius, glyph) = switch (size) {
      MxIconTileSize.small => (smallBox, AppRadius.sm, AppIconSize.inline),
      MxIconTileSize.medium => (mediumBox, AppRadius.md, AppIconSize.compact),
      MxIconTileSize.large => (_largeBox, AppRadius.md, AppIconSize.compact),
    };
    // The soft tones sit on their soft ground with the on-soft glyph; a seed
    // keeps its own glyph on the primary soft ground.
    final (fill, foreground) = switch (tone) {
      MxIconTileTone.tinted => (
        semantic.primarySoft,
        seed ?? semantic.onPrimarySoft,
      ),
      MxIconTileTone.primary => (colors.primary, colors.onPrimary),
      MxIconTileTone.warning => (semantic.warning, semantic.onWarning),
      MxIconTileTone.success => (semantic.successSoft, semantic.onSuccessSoft),
      MxIconTileTone.caution => (semantic.warningSoft, semantic.onWarningSoft),
      MxIconTileTone.danger => (semantic.dangerSoft, semantic.onDangerSoft),
    };
    return SizedBox.square(
      dimension: box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Center(
          child: child ?? Icon(icon, size: glyph, color: foreground),
        ),
      ),
    );
  }
}
