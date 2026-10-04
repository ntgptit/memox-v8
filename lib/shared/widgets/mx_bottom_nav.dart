import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_effects.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
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
    final derived = context.derivedColors;
    final inset = MediaQuery.paddingOf(context).bottom;
    final pillTint = colors.primary.withValues(
      alpha: colors.brightness == Brightness.dark
          ? _pillTintDark
          : _pillTintLight,
    );
    final radius = BorderRadius.circular(AppRadius.lg);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.control,
        AppSpacing.micro,
        AppSpacing.control,
        AppSpacing.grouped + inset,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppEffects.glassBlur,
            sigmaY: AppEffects.glassBlur,
          ),
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
              constraints: const BoxConstraints(
                minHeight: AppSize.bottomNavBar,
              ),
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
