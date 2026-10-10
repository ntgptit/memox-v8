import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The top-level destinations in a rail on the leading edge, for windows of
/// [AppSize.navRailBreakpoint] and wider (FE-C5). The kit draws no rail: it
/// takes MxBottomNav's glyphs, pill and label so the two read as one
/// control. It takes the insets on its own side and scrolls when the window
/// is short.
class MxNavRail extends StatelessWidget {
  const MxNavRail({
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
    // The selected ground (spec 2026-10-10 §4).
    final pillGround = colors.primaryContainer;
    // SafeArea's sides are physical: the rail takes only the one it sits on.
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    return ColoredBox(
      color: colors.surfaceContainerLow,
      child: SafeArea(
        left: isLtr,
        right: !isLtr,
        child: SizedBox(
          width: AppSize.navRail,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.control),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                spacing: AppSpacing.micro,
                children: [
                  for (final (index, destination) in destinations.indexed)
                    _RailItem(
                      destination: destination,
                      isSelected: index == selectedIndex,
                      pillGround: pillGround,
                      onTap: () => onSelected(index),
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

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.isSelected,
    required this.pillGround,
    required this.onTap,
  });

  final MxNavDestination destination;
  final bool isSelected;
  final Color pillGround;
  final VoidCallback onTap;

  static const double _minHeight = 56;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: _minHeight,
            minWidth: AppSize.navRail,
          ),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.micro,
                ),
                child: Text(
                  destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.navLabel(isSelected: isSelected),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
