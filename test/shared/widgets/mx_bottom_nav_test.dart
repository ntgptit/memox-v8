import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/forui_expect.dart';
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

/// The tappable cell of the destination labelled [label].
Finder _cell(String label) => find.ancestor(
  of: find.text(label),
  matching: find.byType(FBottomNavigationBarItem),
);

MxBottomNav _nav({int selected = 0, ValueChanged<int>? onSelected}) =>
    MxBottomNav(
      destinations: _destinations,
      selectedIndex: selected,
      onSelected: onSelected ?? (_) {},
    );

FBottomNavigationBarStyle _style(WidgetTester tester) =>
    forUiTheme(tester, find.byType(MxBottomNav)).bottomNavigationBarStyle;

void main() {
  final colors = appLightColors;

  testWidgets('the bar is its cells and ForUI padding tall, plus the inset '
      'with one', (tester) async {
    await pumpMx(tester, _nav());
    final padding = _style(tester).padding.vertical;
    final cell = tester.getSize(_cell('Library')).height;
    expect(cell, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.byType(MxBottomNav)).height, cell + padding);

    await pumpMx(tester, _nav(), padding: const EdgeInsets.only(bottom: 24));
    expect(
      tester.getSize(find.byType(MxBottomNav)).height,
      cell + padding + 24,
    );
  });

  testWidgets('a flat bar: the background, a divider on top, no glass', (
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

    expect(decoration, _style(tester).decoration);
    expect(decoration.color, colors.background);
    expect((decoration.border! as Border).top.color, colors.border);
    expect(find.byType(BackdropFilter), findsNothing);
  });

  testWidgets('four equal columns', (tester) async {
    await pumpMx(tester, _nav());
    final widths = [
      for (final d in _destinations) tester.getSize(_cell(d.label)).width,
    ];

    expect(widths.toSet(), hasLength(1));
  });

  testWidgets('the selected destination: glyph and label in primary, '
      'the others muted', (tester) async {
    await pumpMx(tester, _nav(selected: 1));

    // The selected glyph is the resting one: selection shows in colour and
    // weight, not in a second glyph.
    expect(AppIcons.studySelected, AppIcons.study);
    expect(find.byIcon(AppIcons.study), findsOneWidget);
    expect(iconColor(tester, find.byIcon(AppIcons.study)), colors.primary);
    expect(
      IconTheme.of(tester.element(find.byIcon(AppIcons.study))).weight,
      700,
    );
    expect(
      iconColor(tester, find.byIcon(AppIcons.library)),
      colors.mutedForeground,
    );
    expect(textColor(tester, find.text('Study')), colors.primary);
    expect(textColor(tester, find.text('Library')), colors.mutedForeground);
    expect(
      DefaultTextStyle.of(tester.element(find.text('Study'))).style.fontWeight,
      FontWeight.bold,
    );
  });

  testWidgets('moving the selection moves the primary colour', (tester) async {
    final host = ValueNotifier(0);
    addTearDown(host.dispose);
    await pumpMx(
      tester,
      ValueListenableBuilder(
        valueListenable: host,
        builder: (_, selected, _) => _nav(selected: selected),
      ),
    );
    expect(textColor(tester, find.text('Library')), colors.primary);
    expect(textColor(tester, find.text('Study')), colors.mutedForeground);

    host.value = 1;
    await tester.pumpAndSettle();

    expect(iconColor(tester, find.byIcon(AppIcons.study)), colors.primary);
    expect(
      iconColor(tester, find.byIcon(AppIcons.library)),
      colors.mutedForeground,
    );
    expect(textColor(tester, find.text('Study')), colors.primary);
    expect(textColor(tester, find.text('Library')), colors.mutedForeground);
  });

  testWidgets('the tap target is the whole cell, as tall as the bar content', (
    tester,
  ) async {
    int? picked;
    await pumpMx(tester, _nav(onSelected: (i) => picked = i));
    final cell = tester.getRect(_cell('Progress'));

    expect(cell.height, greaterThanOrEqualTo(48));
    await tester.tapAt(cell.topLeft + const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(picked, 2);
    await tester.tapAt(cell.bottomRight - const Offset(1, 1));
    await tester.pumpAndSettle();
    expect(picked, 2);
  });

  testWidgets('a tap reports the index; the selected item is marked', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    int? picked;
    await pumpMx(tester, _nav(onSelected: (i) => picked = i));
    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(picked, 2);
    expect(
      tester.getSemantics(find.text('Library')),
      // The label ends with the destination's position, as ForUI reads it.
      isSemantics(
        label: 'Library\nTab 1 of 4',
        isSelected: true,
        hasSelectedState: true,
        isButton: true,
      ),
    );
    handle.dispose();
  });

  // The tab shell resets a branch to its root on a re-tap of the current
  // tab; ForUI's bar reports that tap, with no equality guard.
  testWidgets('a re-tap of the selected destination still reports it', (
    tester,
  ) async {
    final picked = <int>[];
    await pumpMx(tester, _nav(selected: 1, onSelected: picked.add));
    await tester.tap(find.text('Study'));
    await tester.pumpAndSettle();

    expect(picked, [1]);
  });

  testWidgets('each destination is named with its position', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _nav(selected: 1));

    expect(
      tester.getSemantics(find.text('Study')),
      isSemantics(
        label: 'Study\nTab 2 of 4',
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
        isButton: true,
        isSelected: false,
        hasSelectedState: true,
        hasTapAction: true,
      ),
    );
    handle.dispose();
  });

  testWidgets('the cells are accessible targets', (tester) async {
    await pumpMx(tester, _nav());
    await expectAccessibleTargets(tester);
  });

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });

  for (final brightness in Brightness.values) {
    final focusColors = brightness == Brightness.light
        ? appLightColors
        : appDarkColors;
    // Library is the selected destination, Study is not.
    for (final label in ['Library', 'Study']) {
      testWidgets('the focused $label cell draws ForUI\'s focus outline '
          '(${brightness.name})', (tester) async {
        int? picked;
        await pumpMx(
          tester,
          _nav(onSelected: (i) => picked = i),
          brightness: brightness,
        );
        useKeyboardFocusHighlight();
        final outline = forUiTheme(
          tester,
          find.byType(MxBottomNav),
        ).style.focusedOutlineStyle;
        expect(outline.color, focusColors.primary);
        final ring = find.descendant(
          of: _cell(label),
          matching: find.byType(FFocusedOutline),
        );
        expect(
          tester.renderObject(ring),
          isNot(paintsFocusRing(outline.color, width: outline.width)),
        );

        await tabTo(tester, find.text(label));

        expect(
          tester.renderObject(ring),
          paintsFocusRing(outline.color, width: outline.width),
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(picked, label == 'Library' ? 0 : 1);
      });
    }
  }
}
