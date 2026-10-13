import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The size steps, each with one role: small leads content rows, medium
/// leads settings rows, large leads a status hero, and deck is the 64 deck
/// tile of a deck list ("Flashcard Color Tokens" §4.3).
enum MxIconTileSize { small, medium, large, deck }

/// The fill: the primary soft ground (default), or a solid primary or
/// warning square whose glyph takes the matching on-colour (screen 02's lock
/// strip, owner decision D-O1). [success], [caution] and [danger] are soft
/// grounds with a legible glyph: the session summary's outcomes (FE-A6 D14).
/// [neutral] is the neutral soft ground for an idle glyph, such as a lost
/// streak. [deck] is a deck's tile: the tile surface with the information
/// glyph, info in light and the info container in dark (§2.2).
enum MxIconTileTone {
  tinted,
  primary,
  warning,
  success,
  caution,
  danger,
  neutral,
  deck,
}

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

  /// The glyph's colour over the primary soft ground. It must hold 3:1 on
  /// that ground in the theme in scope. Null takes the on-primary-soft
  /// glyph.
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
      MxIconTileSize.deck => (
        AppSize.deckTile,
        AppRadius.sm,
        AppIconSize.large,
      ),
    };
    // Each soft tone sits on its soft ground with the on-soft glyph; a seed
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
      MxIconTileTone.neutral => (semantic.neutralSoft, semantic.onNeutralSoft),
      MxIconTileTone.deck => (
        semantic.tileSurface,
        colors.brightness == Brightness.dark
            ? semantic.infoContainer
            : semantic.info,
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
          child: child ?? Icon(icon, size: glyph, color: foreground),
        ),
      ),
    );
  }
}
