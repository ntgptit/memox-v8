import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:memox/core/theme/focus_ring_border.dart';
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
        child: Material(
          type: MaterialType.transparency,
          // The tab bar of the SDK's NavigationBar: a group whose children
          // are the tabs.
          child: Semantics(
            role: SemanticsRole.tabBar,
            explicitChildNodes: true,
            container: true,
            child: Row(
              children: [
                for (final (index, destination) in destinations.indexed)
                  Expanded(
                    // The bar is `sizeNav` at minimum and grows with the text
                    // scale; each cell is as tall as the bar, so its tap
                    // target spans the whole cell.
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: dimens.sizeNav),
                      child: MxNavItem(
                        destination: destination,
                        index: index,
                        count: destinations.length,
                        isSelected: index == selectedIndex,
                        onTap: () => onSelected(index),
                      ),
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
///
/// The pill grows in and fades in over `Durations.medium2` (at once when the
/// platform asks for reduced motion). The whole cell is the tap target, and
/// the ink is clipped to the pill, as the Material 3 navigation bar does.
/// Keyboard focus draws the shared 2px `primary` ring around the pill,
/// `strokeFocusGap` outside it ([MxFocusRingBorder]).
///
/// It is a tab named with its place, "Tab [index] of [count]", as the SDK
/// NavigationBar destination is; [index] is zero-based.
class MxNavItem extends StatefulWidget {
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
  State<MxNavItem> createState() => _MxNavItemState();
}

/// The share of its width the pill has when it starts to grow in: the
/// Material 3 indicator scales in from 40%.
const double _pillRestWidthShare = 0.4;

class _MxNavItemState extends State<MxNavItem> {
  /// Locates the pill for the ink's rectangle.
  final _pillKey = GlobalKey();

  var _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dimens = context.dimens;
    final destination = widget.destination;
    final isSelected = widget.isSelected;
    final pillColor = colors.secondaryContainer;
    return Semantics(
      container: true,
      role: SemanticsRole.tab,
      selected: isSelected,
      button: true,
      child: _PillInkWell(
        pillKey: _pillKey,
        onTap: widget.onTap,
        onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: dimens.space4,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(end: isSelected ? 1 : 0),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : Durations.medium2,
              curve: Easing.standard,
              builder: (_, progress, icon) => SizedBox(
                key: _pillKey,
                width: dimens.sizeNavIndicatorWidth,
                height: dimens.sizeNavIndicatorHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ink, so the splash paints over the pill, not under it.
                    Ink(
                      width: lerpDouble(
                        dimens.sizeNavIndicatorWidth * _pillRestWidthShare,
                        dimens.sizeNavIndicatorWidth,
                        progress,
                      ),
                      height: dimens.sizeNavIndicatorHeight,
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: Color.lerp(
                          pillColor.withValues(alpha: 0),
                          pillColor,
                          progress,
                        ),
                      ),
                    ),
                    ?icon,
                    if (_hasFocus)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            key: const ValueKey('mx-nav-focus-ring'),
                            decoration: ShapeDecoration(
                              shape: MxFocusRingBorder(
                                base: const StadiumBorder(),
                                ring: BorderSide(
                                  color: colors.primary,
                                  width: dimens.strokeFocus,
                                ),
                                gap: dimens.strokeFocusGap,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              child: Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                size: dimens.sizeIcon,
                color: isSelected
                    ? colors.onSecondaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
            _NavLabel(
              label: destination.label,
              index: widget.index,
              count: widget.count,
              isSelected: isSelected,
            ),
          ],
        ),
      ),
    );
  }
}

/// The destination's label and, after it, its place for a screen reader, as
/// the SDK bar does: "Study, Tab 2 of 4".
class _NavLabel extends StatelessWidget {
  const _NavLabel({
    required this.label,
    required this.index,
    required this.count,
    required this.isSelected,
  });

  final String label;
  final int index;
  final int count;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.texts.labelSmall?.copyWith(
            color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
          ),
        ),
        Semantics(
          label: MaterialLocalizations.of(context)
              .tabLabel(tabIndex: index + 1, tabCount: count),
        ),
      ],
    );
  }
}

/// An ink well over the whole cell whose ripple and state layers are drawn on
/// the pill only (`_IndicatorInkWell` of the SDK's NavigationBar).
class _PillInkWell extends InkWell {
  const _PillInkWell({
    required this.pillKey,
    required super.onTap,
    required super.onFocusChange,
    required super.child,
  }) : super(customBorder: const StadiumBorder());

  final GlobalKey pillKey;

  @override
  RectCallback? getRectCallback(RenderBox referenceBox) => () {
    final pill = pillKey.currentContext!.findRenderObject()! as RenderBox;
    final rect = pill.localToGlobal(Offset.zero) & pill.size;
    return referenceBox.globalToLocal(rect.topLeft) & pill.size;
  };
}
