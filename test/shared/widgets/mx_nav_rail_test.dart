import 'package:flutter/material.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/shared/widgets/mx_nav_rail.dart';

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
    find.ancestor(of: find.text(label), matching: find.byType(InkWell));

// The painted focus ring: the one CustomPaint whose painter is the shared one.
Finder _ringFinder() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.foregroundPainter is MxFocusRingPainter,
);

MxFocusRingPainter _painter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_ringFinder()).foregroundPainter!
        as MxFocusRingPainter;

void _showFocusRings() {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
}

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('80 wide on surfaceContainerLow; every item at least 48×56', (
    tester,
  ) async {
    await pumpMx(tester, _rail());

    expect(tester.getSize(find.byType(MxNavRail)).width, 80);
    expect(
      tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(MxNavRail),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color,
      scheme.surfaceContainerLow,
    );
    for (final d in _destinations) {
      final size = tester.getSize(_item(d.label));
      expect(size.width, greaterThanOrEqualTo(48), reason: d.label);
      expect(size.height, greaterThanOrEqualTo(56), reason: d.label);
    }
  });

  testWidgets(
    'the selected item: filled glyph in onPrimaryContainer on the pill; '
    'the rest outlined in onSurfaceVariant',
    (tester) async {
      await pumpMx(tester, _rail(selected: 1));

      expect(find.byIcon(AppIcons.study), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color,
        scheme.onPrimaryContainer,
      );
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.library)).color,
        scheme.onSurfaceVariant,
      );
      final pill = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byIcon(AppIcons.studySelected),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((pill.decoration as BoxDecoration).color, scheme.primaryContainer);
    },
  );

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

  testWidgets('focus: Tab lands on the first destination; one ring, '
      'primaryForeground, and it moves', (tester) async {
    _showFocusRings();
    await pumpMx(tester, _rail());
    expect(_ringFinder(), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ringFinder(), findsOneWidget);
    expect(_painter(tester).color, MxSemanticColors.light.primaryForeground);
    expect(_painter(tester).placement, MxFocusRingPlacement.inside);
    final first = tester.getRect(_ringFinder());
    expect(first.center, tester.getCenter(_item('Library')));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ringFinder(), findsOneWidget);
    expect(tester.getRect(_ringFinder()), isNot(first));
  });
}
