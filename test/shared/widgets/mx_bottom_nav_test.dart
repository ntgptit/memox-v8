import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';

import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/paint_clip.dart';
import '../../support/widget_harness.dart';

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

Finder _pill(String label) => find.descendant(
  of: find.ancestor(of: find.text(label), matching: find.bySubtype<InkWell>()),
  matching: find.byType(Ink),
);

MxBottomNav _nav({int selected = 0, ValueChanged<int>? onSelected}) =>
    MxBottomNav(
      destinations: _destinations,
      selectedIndex: selected,
      onSelected: onSelected ?? (_) {},
    );

void main() {
  final scheme = lightColorScheme;

  testWidgets('sizeNav tall with no inset, plus the inset with one', (
    tester,
  ) async {
    final height = const AppDimens().sizeNav;
    await pumpMx(tester, _nav());
    expect(tester.getSize(find.byType(MxBottomNav)).height, height);

    await pumpMx(tester, _nav(), padding: const EdgeInsets.only(bottom: 24));
    expect(tester.getSize(find.byType(MxBottomNav)).height, height + 24);
  });

  testWidgets('a flat bar: the surface, a divider on top, no glass', (
    tester,
  ) async {
    await pumpMx(tester, _nav());
    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxBottomNav),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final decoration = bar.decoration as BoxDecoration;

    expect(decoration.color, scheme.surface);
    expect(
      (decoration.border! as Border).top.color,
      appLightColors.border,
    );
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('four equal columns', (tester) async {
    await pumpMx(tester, _nav());
    final widths = [
      for (final d in _destinations)
        tester
            .getSize(
              find.ancestor(
                of: find.text(d.label),
                matching: find.bySubtype<InkWell>(),
              ),
            )
            .width,
    ];

    expect(widths.toSet(), hasLength(1));
  });

  testWidgets('the selected destination: filled glyph on the pill, label in '
      'onSurface', (tester) async {
    await pumpMx(tester, _nav(selected: 1));

    expect(find.byIcon(AppIcons.studySelected), findsOneWidget);
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
      tester.widget<Text>(find.text('Study')).style!.color,
      scheme.onSurface,
    );
    expect(
      tester.widget<Text>(find.text('Library')).style!.color,
      scheme.onSurfaceVariant,
    );
  });

  testWidgets('the pill is the indicator size on secondaryContainer', (
    tester,
  ) async {
    await pumpMx(tester, _nav());

    expect(
      (tester.widget<Ink>(_pill('Library')).decoration! as ShapeDecoration)
          .color,
      scheme.secondaryContainer,
    );
    expect(
      tester.getSize(_pill('Library')),
      Size(
        const AppDimens().sizeNavIndicatorWidth,
        const AppDimens().sizeNavIndicatorHeight,
      ),
    );
  });

  group('selection animates the pill', () {
    final host = ValueNotifier(0);
    Widget animated() => ValueListenableBuilder(
      valueListenable: host,
      builder: (_, selected, _) => _nav(selected: selected),
    );

    setUp(() => host.value = 0);

    testWidgets('colour and width ease over medium2', (tester) async {
      await pumpMx(tester, animated());
      final restColor =
          (tester.widget<Ink>(_pill('Study')).decoration! as ShapeDecoration)
              .color!;
      expect(restColor.a, 0);

      host.value = 1;
      await tester.pump();
      await tester.pump(Durations.medium2 ~/ 2);
      final width = tester.getSize(_pill('Study')).width;
      final midColor =
          (tester.widget<Ink>(_pill('Study')).decoration! as ShapeDecoration)
              .color!;
      expect(width, greaterThan(const AppDimens().sizeNavIndicatorWidth * 0.4));
      expect(width, lessThan(const AppDimens().sizeNavIndicatorWidth));
      expect(midColor.a, inExclusiveRange(0, 1));

      await tester.pump(Durations.medium2);
      expect(
        tester.getSize(_pill('Study')).width,
        const AppDimens().sizeNavIndicatorWidth,
      );
      expect(
        (tester.widget<Ink>(_pill('Study')).decoration! as ShapeDecoration)
            .color,
        scheme.secondaryContainer,
      );
      // The pill it left is gone.
      expect(
        (tester.widget<Ink>(_pill('Library')).decoration! as ShapeDecoration)
            .color!
            .a,
        0,
      );
    });

    testWidgets('reduced motion: the pill is final after one frame', (
      tester,
    ) async {
      await pumpMx(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: animated(),
          ),
        ),
      );
      host.value = 1;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        (tester.widget<Ink>(_pill('Study')).decoration! as ShapeDecoration)
            .color,
        scheme.secondaryContainer,
      );
      expect(
        tester.getSize(_pill('Study')).width,
        const AppDimens().sizeNavIndicatorWidth,
      );
    });
  });

  testWidgets('the tap target is the whole cell, as tall as the bar', (
    tester,
  ) async {
    int? picked;
    await pumpMx(tester, _nav(onSelected: (i) => picked = i));
    final cell = tester.getRect(
      find.ancestor(
        of: find.text('Progress'),
        matching: find.bySubtype<InkWell>(),
      ),
    );

    expect(cell.height, const AppDimens().sizeNav);
    await tester.tapAt(cell.topLeft + const Offset(1, 1));
    expect(picked, 2);
  });

  testWidgets('the ripple is clipped to the pill, not the cell', (
    tester,
  ) async {
    await pumpMx(tester, _nav());
    final cell = tester.getRect(
      find.ancestor(
        of: find.text('Progress'),
        matching: find.bySubtype<InkWell>(),
      ),
    );
    final pill = tester.getRect(_pill('Progress'));
    // The ink paints in the cell's own coordinates.
    final inks = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == '_InkFeatures',
    );

    final gesture = await tester.startGesture(pill.center);
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      tester.renderObject(inks.first),
      paints..clipPath(
        pathMatcher: isPathThat(
          includes: [pill.center - cell.topLeft],
          excludes: [
            const Offset(1, 1),
            (cell.bottomRight - cell.topLeft) - const Offset(1, 1),
          ],
        ),
      ),
    );
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a tap reports the index; the selected item is marked', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? picked;
    await pumpMx(tester, _nav(onSelected: (i) => picked = i));
    await tester.tap(find.text('Progress'));

    expect(picked, 2);
    expect(
      tester.getSemantics(find.text('Library')),
      // M3F-09: the label now ends with the destination's position.
      isSemantics(
        label: 'Library\nTab 1 of 4',
        isSelected: true,
        isButton: true,
      ),
    );
    handle.dispose();
  });

  // M3F-09: the SDK NavigationBar gives each destination the tab role and
  // "Tab i of n", and the bar the tab bar role. Selected and button stay.
  testWidgets('M3F-09: each destination is a tab named with its position', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _nav(selected: 1));

    expect(
      tester.getSemantics(find.text('Study')),
      isSemantics(
        label: 'Study\nTab 2 of 4',
        role: SemanticsRole.tab,
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSemantics(find.text('Settings')),
      isSemantics(
        label: 'Settings\nTab 4 of 4',
        role: SemanticsRole.tab,
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('M3F-09: the bar is a tab bar whose children are the tabs', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _nav());

    final bar = tester.getSemantics(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.role == SemanticsRole.tabBar,
      ),
    );
    expect(bar.getSemanticsData().role, SemanticsRole.tabBar);
    var tabs = 0;
    bar.visitChildren((child) {
      expect(child.getSemanticsData().role, SemanticsRole.tab);
      tabs++;
      return true;
    });
    expect(tabs, _destinations.length);
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });

  // M3F-05: the cell's InkWell drew only the theme's focus layer on the pill,
  // 1.3:1 against the bar. The ring is `MxFocusRingBorder` on the pill's
  // stadium, `strokeFocusGap` outside it, as the toggle's is on its track.
  for (final brightness in Brightness.values) {
    final focusScheme = brightness == Brightness.light
        ? lightColorScheme
        : darkColorScheme;
    // Library is the selected destination, Study is not.
    for (final label in ['Library', 'Study']) {
      testWidgets('M3F-05: the focused $label pill draws the 2px primary '
          'ring (${brightness.name})', (tester) async {
        int? picked;
        await pumpMx(
          tester,
          _nav(onSelected: (i) => picked = i),
          brightness: brightness,
        );
        useKeyboardFocusHighlight();
        expect(
          tester.renderObject(find.byType(MxBottomNav)),
          isNot(paintsFocusRing(focusScheme.primary)),
        );

        await tabTo(tester, find.text(label));

        expect(focusedRender(tester), paintsFocusRing(focusScheme.primary));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        expect(picked, label == 'Library' ? 0 : 1);
      });
    }
  }

  testWidgets('M3F-05: the ring hugs the pill, offset by strokeFocusGap, and '
      'no clip cuts it', (tester) async {
    const dimens = AppDimens();
    await pumpMx(tester, _nav());
    useKeyboardFocusHighlight();
    await tabTo(tester, find.text('Study'));

    final cell = tester.getRect(
      find.ancestor(
        of: find.text('Study'),
        matching: find.bySubtype<InkWell>(),
      ),
    );
    final pill = tester.getRect(_pill('Study'));
    final pillWidth = dimens.sizeNavIndicatorWidth;
    final pillHeight = dimens.sizeNavIndicatorHeight;
    // The ring's centre line: the gap and half the stroke outside the pill.
    final reach = dimens.strokeFocusGap + dimens.strokeFocus / 2;
    final ringCentre = Rect.fromCenter(
      center: pill.center - cell.topLeft,
      width: pillWidth + 2 * reach,
      height: pillHeight + 2 * reach,
    );
    expect(
      focusedRender(tester),
      paints..something((name, arguments) {
        final paint = arguments.whereType<Paint>().firstOrNull;
        if (name != #drawPath || paint == null) return false;
        if (paint.color.toARGB32() != lightColorScheme.primary.toARGB32()) {
          return false;
        }
        final bounds = (arguments[0] as Path).getBounds();
        return (bounds.left - ringCentre.left).abs() < 0.01 &&
            (bounds.top - ringCentre.top).abs() < 0.01 &&
            (bounds.right - ringCentre.right).abs() < 0.01 &&
            (bounds.bottom - ringCentre.bottom).abs() < 0.01;
      }),
    );
    expect(
      clipsAway(
        tester,
        find.ancestor(
          of: find.text('Study'),
          matching: find.bySubtype<InkWell>(),
        ),
        pill.inflate(dimens.strokeFocusGap + dimens.strokeFocus),
      ),
      isFalse,
    );
  });
}
