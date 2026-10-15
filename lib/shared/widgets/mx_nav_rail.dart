import 'package:flutter/material.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

/// The top-level destinations in a rail on the leading edge, for windows of
/// `breakpointMedium` and wider (FE-C5): the page surface, a hairline `divider`
/// on its inner edge, and the same glyph, pill and label as [MxBottomNav], so
/// the two read as one control. It takes the insets on its own side and scrolls
/// when the window is short.
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

  /// A destination keeps this height so the pill and label have room.
  static const double _itemMinHeight = 56;

  @override
  Widget build(BuildContext context) {
    final dimens = context.dimens;
    // SafeArea's sides are physical: the rail takes only the one it sits on.
    final isLtr = Directionality.of(context) == TextDirection.ltr;
    final edge = BorderSide(
      color: context.mxColors.divider,
      width: dimens.strokeHairline,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: BorderDirectional(end: edge),
      ),
      child: SafeArea(
        left: isLtr,
        right: !isLtr,
        child: SizedBox(
          width: dimens.sizeRail,
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(vertical: dimens.space8),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                spacing: dimens.space4,
                children: [
                  for (final (index, destination) in destinations.indexed)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: _itemMinHeight,
                        minWidth: dimens.sizeRail,
                      ),
                      child: MxNavItem(
                        destination: destination,
                        index: index,
                        count: destinations.length,
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
