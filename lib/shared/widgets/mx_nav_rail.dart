import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The top-level destinations in an 80-wide rail on the leading edge, for
/// windows of [AppSize.navRailBreakpoint] and wider (FE-C5): the page
/// surface, edged on its trailing side by the hairline divider, with
/// MxBottomNav's items, so the two read as one control ("Flashcard Color
/// Tokens" §6). It takes the insets on its own side and scrolls when the
/// window is short.
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
    // SafeArea's sides are physical: the rail takes only the one it sits on.
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: BorderDirectional(
          end: BorderSide(
            color: context.semanticColors.divider,
            width: AppStroke.hairline,
          ),
        ),
      ),
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
                    SizedBox(
                      width: AppSize.navRail,
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
      ),
    );
  }
}
