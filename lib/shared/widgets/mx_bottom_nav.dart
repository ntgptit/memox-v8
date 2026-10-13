import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';

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

/// The top-level destinations on a flat bar: the page surface, a hairline
/// `divider` on top, no shadow, and a pill behind the current glyph. It is
/// in-flow, never over the scroll, and adds the gesture inset below itself.
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

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(
            color: context.mxColors.divider,
            width: dimens.strokeHairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        // The bar is `sizeNav` at minimum and grows with the text scale.
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: dimens.sizeNav),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                for (final (index, destination) in destinations.indexed)
                  Expanded(
                    child: MxNavItem(
                      destination: destination,
                      isSelected: index == selectedIndex,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One destination of [MxBottomNav] and `MxNavRail`: the glyph on its
/// `sizeNavIndicatorWidth` x `sizeNavIndicatorHeight` pill, and the label
/// under it. The selected one sits on `secondaryContainer`.
class MxNavItem extends StatelessWidget {
  const MxNavItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final MxNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    return Semantics(
      container: true,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: dimens.space4,
          children: [
            DecoratedBox(
              decoration: ShapeDecoration(
                color: isSelected ? colors.secondaryContainer : null,
                shape: const StadiumBorder(),
              ),
              child: SizedBox(
                width: dimens.sizeNavIndicatorWidth,
                height: dimens.sizeNavIndicatorHeight,
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: dimens.sizeIcon,
                  color: isSelected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.texts.labelSmall?.copyWith(
                color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
