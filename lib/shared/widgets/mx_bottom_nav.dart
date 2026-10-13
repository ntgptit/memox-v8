import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_easing.dart';
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

/// The top-level destinations on a 64 bar of the page surface, edged on top
/// by the hairline divider, with no shadow ("Flashcard Color Tokens" §6). It
/// is in-flow, never over the scroll, and adds the gesture inset below
/// itself.
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
    final inset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(
          top: BorderSide(
            color: context.semanticColors.divider,
            width: AppStroke.hairline,
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        // Ruling R3: 64 at minimum, grows with text scaling.
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSize.bottomNavBar),
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

/// One destination of [MxBottomNav] and MxNavRail: the glyph on its pill
/// above the label. The current one sits on a 56 × 32 pill of the secondary
/// container, its glyph in on-secondary-container and its label in
/// on-surface; the rest read on-surface-variant. The pill fades in over
/// [AppDurations.sheet] on the standard easing.
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
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : AppDurations.sheet;
    return Semantics(
      container: true,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.micro,
            vertical: AppSpacing.micro,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.micro,
            children: [
              AnimatedContainer(
                duration: duration,
                curve: AppEasing.standard,
                width: AppSize.navIndicatorWidth,
                height: AppSize.navIndicatorHeight,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.secondaryContainer
                      : colors.secondaryContainer.withValues(alpha: 0),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Icon(
                  isSelected ? destination.selectedIcon : destination.icon,
                  size: AppIconSize.standard,
                  color: isSelected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.ellipsized(
                  context.textStyles.navLabel(isSelected: isSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
