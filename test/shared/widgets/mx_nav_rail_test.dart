import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';

import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';

import '../../support/focus_ring_expect.dart';
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

Finder _item(String label) =>
    find.ancestor(of: find.text(label), matching: find.bySubtype<InkWell>());

Finder _pill(String label) =>
    find.descendant(of: _item(label), matching: find.byType(Ink));

void main() {
  final scheme = lightColorScheme;

  testWidgets('sizeRail wide on the surface with a divider edge; every item '
      'at least control wide and 56 tall', (tester) async {
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
    expect(decoration.color, scheme.surface);
    expect(
      (decoration.border! as BorderDirectional).end.color,
      MxColorsExtension.light.divider,
    );
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

  testWidgets('the selected item: filled glyph on the secondary-container '
      'pill; the rest outlined in onSurfaceVariant', (tester) async {
    await pumpMx(tester, _rail(selected: 1));

    expect(find.byIcon(AppIcons.study), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color,
      scheme.onSecondaryContainer,
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.library)).color,
      scheme.onSurfaceVariant,
    );
    expect(
      (tester.widget<Ink>(_pill('Study')).decoration! as ShapeDecoration).color,
      scheme.secondaryContainer,
    );
    expect(
      tester.getSize(_pill('Study')),
      Size(
        const AppDimens().sizeNavIndicatorWidth,
        const AppDimens().sizeNavIndicatorHeight,
      ),
    );
  });

  testWidgets('a tap reports its index, a re-tap of the current one too', (
    tester,
  ) async {
    final taps = <int>[];
    await pumpMx(tester, _rail(onSelected: taps.add));

    await tester.tap(find.text('Progress'));
    await tester.tap(find.text('Library'));

    expect(taps, [2, 0]);
  });

  testWidgets('announced as selected buttons named by their labels, with '
      '48 targets', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _rail());

    expect(
      tester.getSemantics(_item('Library')),
      isSemantics(
        label: 'Library',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
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

  // M3F-05: the rail shares MxNavItem with the bar, so it draws the same
  // pill ring; the rail's scroll view and edge must not cut it.
  for (final brightness in Brightness.values) {
    final focusScheme = brightness == Brightness.light
        ? lightColorScheme
        : darkColorScheme;
    testWidgets('M3F-05: a focused destination draws the 2px primary ring '
        'and nothing clips it (${brightness.name})', (tester) async {
      const dimens = AppDimens();
      int? picked;
      await pumpMx(
        tester,
        _rail(onSelected: (i) => picked = i),
        brightness: brightness,
      );
      useKeyboardFocusHighlight();
      expect(
        tester.renderObject(find.byType(MxNavRail)),
        isNot(paintsFocusRing(focusScheme.primary)),
      );

      await tabTo(tester, find.text('Library'));

      expect(focusedRender(tester), paintsFocusRing(focusScheme.primary));
      final cell = find.ancestor(
        of: find.text('Library'),
        matching: find.bySubtype<InkWell>(),
      );
      final pill = tester.getRect(
        find.descendant(of: cell, matching: find.byType(Ink)),
      );
      expect(
        clipsAway(
          tester,
          cell,
          pill.inflate(dimens.strokeFocusGap + dimens.strokeFocus),
        ),
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(picked, 0);
    });
  }
}
