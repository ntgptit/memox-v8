import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
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

/// The top-level destinations on a translucent bar (surface at 84%) with a
/// tinted pill behind the current glyph. It is in-flow, never over the scroll,
/// so it carries no blur (SP1 §5.2). Custom by owner ruling R4: Material's
/// NavigationBar would change the bar's look; this one reads its tab positions
/// the same way, and carries its tab roles. It adds the insets below and on
/// both sides itself (a landscape cutout).
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
    final colors = context.colors;
    final derived = context.derivedColors;
    final insets = MediaQuery.paddingOf(context);
    final pillTint = colors.primary.withValues(
      alpha: colors.brightness == Brightness.dark
          ? AppOpacity.navPillDark
          : AppOpacity.navPillLight,
    );
    final radius = BorderRadius.circular(AppRadius.lg);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.control + insets.left,
        AppSpacing.micro,
        AppSpacing.control + insets.right,
        AppSpacing.grouped + insets.bottom,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: derived.chromeGlass,
            borderRadius: radius,
            border: Border.all(
              color: derived.ghostBorder,
              width: AppStroke.hairline,
            ),
          ),
          // Ruling R3: 64 at minimum, grows with text scaling.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSize.bottomNavBar),
            child: Material(
              type: MaterialType.transparency,
              // The roles Material's NavigationBar gives its row and items.
              child: Semantics(
                role: SemanticsRole.tabBar,
                explicitChildNodes: true,
                container: true,
                child: Row(
                  children: [
                    for (final (index, destination) in destinations.indexed)
                      Expanded(
                        child: _Item(
                          destination: destination,
                          isSelected: index == selectedIndex,
                          pillTint: pillTint,
                          tabIndex: index + 1,
                          tabCount: destinations.length,
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
    required this.tabIndex,
    required this.tabCount,
    required this.onTap,
  });

  final MxNavDestination destination;
  final bool isSelected;
  final Color pillTint;
  final int tabIndex;
  final int tabCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      role: SemanticsRole.tab,
      container: true,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: AppSpacing.micro,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: isSelected ? pillTint : null,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.gutter,
                  vertical: AppSpacing.micro,
                ),
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: AppIconSize.compact,
                  color: isSelected
                      ? context.derivedColors.primaryInk
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              destination.label,
              // The position, as Material's NavigationBar reads it (R4).
              semanticsLabel:
                  '${destination.label}\n${MaterialLocalizations.of(context).tabLabel(tabIndex: tabIndex, tabCount: tabCount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.navLabel(isSelected: isSelected),
            ),
          ],
        ),
      ),
    );
  }
}
