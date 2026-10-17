import 'package:flutter/widgets.dart';
import 'package:forui/forui.dart';

/// A top-level destination: its resting glyph, the glyph it shows while
/// selected, and its label.
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

/// The top-level destinations on ForUI's [FBottomNavigationBar]: in-flow,
/// never over the scroll, and above the gesture inset. Each destination is
/// a tab named with its place, "Tab 2 of 4", as ForUI reads it.
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
  Widget build(BuildContext context) => FBottomNavigationBar(
    index: selectedIndex,
    onChange: onSelected,
    safeAreaBottom: true,
    children: [
      for (final (index, destination) in destinations.indexed)
        _item(destination, isSelected: index == selectedIndex),
    ],
  );
}

/// One destination of [MxBottomNav] and `MxNavRail`, outside a bar: ForUI's
/// [FBottomNavigationBarItem] with the place the bar would give it, so the
/// rail and the bar read as one control. [index] is zero-based.
class MxNavItem extends StatelessWidget {
  const MxNavItem({
    super.key,
    required this.destination,
    required this.index,
    required this.count,
    required this.isSelected,
    required this.onTap,
  }) : assert(index >= 0 && index < count, 'index must be within count');

  final MxNavDestination destination;
  final int index;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => FBottomNavigationBarData(
    itemStyle: FTheme.of(context).bottomNavigationBarStyle.itemStyle,
    selected: isSelected,
    index: index,
    length: count,
    onChange: (_) => onTap(),
    child: _item(destination, isSelected: isSelected),
  );
}

FBottomNavigationBarItem _item(
  MxNavDestination destination, {
  required bool isSelected,
}) => FBottomNavigationBarItem(
  icon: Icon(isSelected ? destination.selectedIcon : destination.icon),
  label: Text(destination.label, maxLines: 1),
);
