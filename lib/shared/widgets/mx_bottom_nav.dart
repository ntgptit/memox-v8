import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';

/// A top-level destination: an outlined resting glyph, a filled selected one.
@immutable
final class MxNavDestination {
  const MxNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Backdrop blur sigma behind the nav's glass surface.
const double _glassBlur = 18;

/// The top-level destinations on a translucent glass bar, with a tinted pill
/// behind the current glyph. It is in-flow, never over the scroll, and adds
/// the gesture inset below itself.
class MxBottomNav extends StatelessWidget {
  const MxBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  }) : assert(
         selectedIndex >= 0 && selectedIndex < destinations.length,
         'selectedIndex must name a destination',
       );

  final List<MxNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const double _pillTintLight = 0.14;
  static const double _pillTintDark = 0.20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final inset = MediaQuery.paddingOf(context).bottom;
    final pillTint = colors.primary.withValues(
      alpha: colors.brightness == Brightness.dark
          ? _pillTintDark
          : _pillTintLight,
    );
    final radius = BorderRadius.circular(context.dimens.radiusLg);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.dimens.space8,
        context.dimens.space4,
        context.dimens.space8,
        context.dimens.space12 + inset,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _glassBlur, sigmaY: _glassBlur),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: radius,
              border: Border.all(
                color: context.colors.outlineVariant,
                width: context.dimens.strokeHairline,
              ),
            ),
            // Ruling R3: 64 at minimum, grows with text scaling.
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.dimens.sizeNav),
              child: Material(
                type: MaterialType.transparency,
                child: Row(
                  children: [
                    for (final (index, destination) in destinations.indexed)
                      Expanded(
                        child: _Item(
                          destination: destination,
                          isSelected: index == selectedIndex,
                          pillTint: pillTint,
                          onTap: () => onSelected(index),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.isSelected,
    required this.pillTint,
    required this.onTap,
  });

  final MxNavDestination destination;
  final bool isSelected;
  final Color pillTint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: context.dimens.space4,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                color: isSelected ? pillTint : null,
                shape: const StadiumBorder(),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.screenMargin,
                  vertical: context.dimens.space4,
                ),
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: context.dimens.sizeIconCompact,
                  color: isSelected
                      ? context.accentColor
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                color: isSelected
                    ? context.colors.onSurface
                    : context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
