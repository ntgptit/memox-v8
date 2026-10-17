import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
import '../../support/paint_clip.dart';
import '../../support/widget_harness.dart';

// FE-C5: the rail the tab shell shows from 600 dp (spec
// 2026-09-28-tablet-rail-design.md §3).

const _destinations = [
  MxNavDestination(
    icon: AppIcons.library,
    selectedIcon: AppIcons.librarySelected,
    label: 'Library',
  ),
  MxNavDestination(
    icon: AppIcons.study,
    selectedIcon: AppIcons.studySelected,
    label: 'Study',
  ),
  MxNavDestination(
    icon: AppIcons.progress,
    selectedIcon: AppIcons.progressSelected,
    label: 'Progress',
  ),
  MxNavDestination(
    icon: AppIcons.settings,
    selectedIcon: AppIcons.settingsSelected,
    label: 'Settings',
  ),
];

Widget _rail({
  int selected = 0,
  ValueChanged<int>? onSelected,
  double height = 600,
}) => SizedBox(
  height: height,
  child: MxNavRail(
    destinations: _destinations,
    selectedIndex: selected,
    onSelected: onSelected ?? (_) {},
  ),
);

Finder _item(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(FBottomNavigationBarItem),
);

void main() {
  final colors = appLightColors;

  testWidgets('sizeRail wide on the background with a divider edge; every '
      'item at least control wide and 56 tall', (tester) async {
    await pumpMx(tester, _rail());

    expect(
      tester.getSize(find.byType(MxNavRail)).width,
      const AppDimens().sizeRail,
    );
    final rail = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxNavRail),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = rail.decoration as BoxDecoration;
    expect(decoration.color, colors.background);
    expect((decoration.border! as BorderDirectional).end.color, colors.border);
    for (final d in _destinations) {
      final size = tester.getSize(_item(d.label));
      expect(
        size.width,
        greaterThanOrEqualTo(const AppDimens().sizeControl),
        reason: d.label,
      );
      expect(size.height, greaterThanOrEqualTo(56), reason: d.label);
    }
  });

  // The frame is ForUI's sidebar: its background and end edge come from the
  // theme's sidebar style, not from a box drawn here.
  testWidgets('the frame is ForUI\'s sidebar in the theme\'s style', (
    tester,
  ) async {
    await pumpMx(tester, _rail());

    final sidebar = find.descendant(
      of: find.byType(MxNavRail),
      matching: find.byType(FSidebar),
    );
    expect(sidebar, findsOneWidget);
    final frame = tester.widget<DecoratedBox>(
      find.descendant(of: sidebar, matching: find.byType(DecoratedBox)).first,
    );
    expect(
      frame.decoration,
      FTheme.of(tester.element(sidebar)).sidebarStyle.decoration,
    );
  });

  testWidgets('the selected item: glyph and label in primary; the rest in '
      'muted foreground', (tester) async {
    await pumpMx(tester, _rail(selected: 1));

    // The selected glyph is the resting one: selection shows in colour.
    expect(AppIcons.studySelected, AppIcons.study);
    expect(iconColor(tester, find.byIcon(AppIcons.study)), colors.primary);
    expect(textColor(tester, find.text('Study')), colors.primary);
    expect(
      iconColor(tester, find.byIcon(AppIcons.library)),
      colors.mutedForeground,
    );
    expect(textColor(tester, find.text('Library')), colors.mutedForeground);
  });

  testWidgets('a tap reports its index, a re-tap of the current one too', (
    tester,
  ) async {
    final taps = <int>[];
    await pumpMx(tester, _rail(onSelected: taps.add));

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(taps, [2, 0]);
  });

  testWidgets('announced as selected buttons named by their labels and '
      'position, with 48 targets', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _rail(selected: 2));

    expect(
      tester.getSemantics(_item('Progress')),
      isSemantics(
        label: 'Progress\nTab 3 of 4',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(_item('Library')),
      isSemantics(
        label: 'Library\nTab 1 of 4',
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(tester.takeException(), isNull);
    handle.dispose();
    await expectAccessibleTargets(tester);
  });

  testWidgets('it takes the start inset only: left in LTR, right in RTL', (
    tester,
  ) async {
    const inset = EdgeInsets.only(left: 32, right: 24);
    await pumpMx(tester, _rail(), padding: inset);
    expect(tester.getSize(find.byType(MxNavRail)).width, 80 + 32);

    await pumpMx(
      tester,
      Directionality(textDirection: TextDirection.rtl, child: _rail()),
      padding: inset,
    );
    expect(tester.getSize(find.byType(MxNavRail)).width, 80 + 24);
  });

  testWidgets('a short window scrolls the rail instead of overflowing', (
    tester,
  ) async {
    await pumpMx(tester, _rail(height: 150));

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  // The rail shares MxNavItem with the bar, so it draws the same ForUI focus
  // outline; the rail's scroll view and edge must not cut it.
  for (final brightness in Brightness.values) {
    testWidgets('a focused destination draws ForUI\'s focus outline and '
        'nothing clips it (${brightness.name})', (tester) async {
      int? picked;
      await pumpMx(
        tester,
        _rail(onSelected: (i) => picked = i),
        brightness: brightness,
      );
      useKeyboardFocusHighlight();
      final outline = forUiTheme(
        tester,
        find.byType(MxNavRail),
      ).style.focusedOutlineStyle;
      final ring = find.descendant(
        of: _item('Library'),
        matching: find.byType(FFocusedOutline),
      );
      expect(
        tester.renderObject(ring),
        isNot(paintsFocusRing(outline.color, width: outline.width)),
      );

      await tabTo(tester, find.text('Library'));

      expect(
        tester.renderObject(ring),
        paintsFocusRing(outline.color, width: outline.width),
      );
      final cell = tester.getRect(_item('Library'));
      expect(
        clipsAway(
          tester,
          _item('Library'),
          cell.inflate(outline.spacing + outline.width),
        ),
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(picked, 0);
    });
  }
}
