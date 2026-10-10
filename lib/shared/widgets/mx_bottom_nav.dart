import 'package:flutter/material.dart';
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

/// The top-level destinations on a bar of the page surface with the ghost
/// edge, a tinted pill behind the current glyph. It is in-flow, never over
/// the scroll (so a backdrop blur had nothing to blur, DEV-302), and adds
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final derived = context.derivedColors;
    final inset = MediaQuery.paddingOf(context).bottom;
    // The selected ground (spec 2026-10-10 §4).
    final pillGround = colors.primaryContainer;
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
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
              child: Row(
                children: [
                  for (final (index, destination) in destinations.indexed)
                    Expanded(
                      child: _Item(
                        destination: destination,
                        isSelected: index == selectedIndex,
                        pillGround: pillGround,
                        onTap: () => onSelected(index),
                      ),
                    ),
                ],
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
    required this.pillGround,
    required this.onTap,
  });

  final MxNavDestination destination;
  final bool isSelected;
  final Color pillGround;
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
                color: isSelected ? pillGround : null,
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
                      ? context.semanticColors.primaryText
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
