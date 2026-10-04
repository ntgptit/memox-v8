import 'package:flutter/material.dart';
import 'package:memox/core/theme/components/mark_style.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/theme_context.dart';

export 'package:memox/core/theme/components/mark_style.dart'
    show MxIconTileTone;

/// An icon tile's geometry: box, radius and glyph.
enum MxIconTileSize {
  small(AppSize.iconTileSmall, AppRadius.sm, AppIconSize.small),
  medium(AppSize.iconTileMedium, AppRadius.md, AppIconSize.medium),
  large(AppSize.iconTileLarge, AppRadius.md, AppIconSize.large);

  const MxIconTileSize(this.box, this.radius, this.glyph);

  final double box;
  final double radius;
  final double glyph;
}

/// A glyph on a toned square beside a row or a heading (DESIGN.md,
/// MxIconTile). Decorative: the row or heading beside it names it.
class MxIconTile extends StatelessWidget {
  const MxIconTile({
    required this.icon,
    this.size = MxIconTileSize.medium,
    this.tone = MxIconTileTone.tinted,
    super.key,
  });

  final IconData icon;
  final MxIconTileSize size;
  final MxIconTileTone tone;

  @override
  Widget build(BuildContext context) {
    final ToneColors pair = mxIconTileColors(
      context.colors,
      context.semanticColors,
      tone,
    );
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size.box,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: pair.ground,
            borderRadius: BorderRadius.circular(size.radius),
          ),
          child: Icon(icon, size: size.glyph, color: pair.content),
        ),
      ),
    );
  }
}
