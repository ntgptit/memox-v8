import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';

/// The size steps, each with one role: small leads content rows, medium
/// leads settings rows, large leads deck rows.
enum MxIconTileSize { small, medium, large }

/// The fill: the primary or seed tint (default), or a solid primary or
/// warning square whose glyph takes the matching on-colour (screen 02's lock
/// strip, owner decision D-O1). [success], [caution] and [danger] are soft
/// tints with a legible glyph: the session summary's outcomes (FE-A6 D14).
/// [neutral] is the neutral container for an idle glyph, such as a lost
/// streak.
enum MxIconTileTone {
  tinted,
  primary,
  warning,
  success,
  caution,
  danger,
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
    final tinted = seed ?? context.colors.primary;
    final (box, radius, glyph) = switch (size) {
      MxIconTileSize.small => (
        smallBox,
        context.radii.sm,
        context.dimens.sizeIconInline,
      ),
      MxIconTileSize.medium => (
        mediumBox,
        context.radii.md,
        context.dimens.sizeIconCompact,
      ),
      MxIconTileSize.large => (
        _largeBox,
        context.radii.md,
        context.dimens.sizeIconCompact,
      ),
    };
    final (fill, ink) = switch (tone) {
      MxIconTileTone.tinted => (
        tinted.tintOver(MxTintBase.of(context)),
        seed ?? context.colors.primary,
      ),
      MxIconTileTone.primary => (colors.primary, colors.primaryForeground),
      MxIconTileTone.warning => (
        context.status.warningFill,
        context.status.onWarningFill,
      ),
      MxIconTileTone.success => (
        context.status.success.tintOver(MxTintBase.of(context)),
        context.status.success,
      ),
      MxIconTileTone.caution => (
        context.status.warning.tintOver(MxTintBase.of(context)),
        context.status.warning,
      ),
      MxIconTileTone.danger => (
        context.colors.error.tintOver(MxTintBase.of(context)),
        context.colors.error,
      ),
      // An idle glyph, such as a lost streak's (DEV-370).
      MxIconTileTone.neutral => (colors.secondary, colors.secondaryForeground),
    };
    return SizedBox.square(
      dimension: box,
      child: DecoratedBox(
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: Center(
          child: child ?? Icon(icon, size: glyph, color: ink),
        ),
      ),
    );
  }
}
