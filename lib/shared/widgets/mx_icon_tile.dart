import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/theme_context.dart';

/// The size steps, each with one role: small leads content rows, medium
/// leads settings rows, large leads deck rows.
enum MxIconTileSize { small, medium, large }

/// The fill: the primary container (default), or a solid primary or warning
/// square whose glyph takes the matching on-colour (screen 02's lock strip,
/// owner decision D-O1). [mastery], [success], [caution] and [danger] are
/// container grounds with their role as the glyph: the session summary's
/// outcomes (FE-A6 D14). [streak] and [neutral] sit on the sheet's ground.
enum MxIconTileTone {
  tinted,
  primary,
  mastery,
  warning,
  success,
  caution,
  danger,
  streak,
  neutral,
}

/// The tinted square that leads a row. It never shrinks; the text beside it
/// gives up space first.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    super.key,
    this.icon,
    this.child,
    this.size = MxIconTileSize.small,
    this.tone = MxIconTileTone.tinted,
  }) : assert((icon == null) != (child == null), 'an icon or a child');

  final IconData? icon;

  /// Replaces the glyph: a letter, a count, a donut.
  final Widget? child;
  final MxIconTileSize size;
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
    final (fill, ink) = switch (tone) {
      MxIconTileTone.tinted => (
        colors.primaryContainer,
        semantic.primaryForeground,
      ),
      MxIconTileTone.primary => (colors.primary, colors.onPrimary),
      MxIconTileTone.mastery => (semantic.masteryContainer, semantic.mastery),
      MxIconTileTone.warning => (semantic.warning, semantic.onWarning),
      MxIconTileTone.success => (semantic.successContainer, semantic.success),
      MxIconTileTone.caution => (semantic.warningContainer, semantic.warning),
      MxIconTileTone.danger => (colors.errorContainer, colors.error),
      MxIconTileTone.streak => (colors.surfaceContainerHigh, semantic.streak),
      MxIconTileTone.neutral => (
        colors.surfaceContainerHigh,
        colors.onSurfaceVariant,
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
