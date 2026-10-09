import 'package:flutter/material.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';

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

MxBottomNav _nav({int selected = 0, ValueChanged<int>? onSelected}) =>
    MxBottomNav(
      destinations: _destinations,
      selectedIndex: selected,
      onSelected: onSelected ?? (_) {},
    );

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

Finder _itemOf(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InkWell));

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('an 80 block with no inset, 80 + inset with one', (tester) async {
    await pumpMx(tester, _nav());
    expect(tester.getSize(find.byType(MxBottomNav)).height, 80);

    await pumpMx(tester, _nav(), padding: const EdgeInsets.only(bottom: 24));
    expect(tester.getSize(find.byType(MxBottomNav)).height, 80 + 24);
  });

  testWidgets('four equal columns', (tester) async {
    await pumpMx(tester, _nav());
    final widths = [
      for (final d in _destinations)
        tester
            .getSize(
              find.ancestor(
                of: find.text(d.label),
                matching: find.byType(InkWell),
              ),
            )
            .width,
    ];

    expect(widths.toSet(), hasLength(1));
  });

  testWidgets(
    'the selected destination is a filled onPrimaryContainer glyph with its label in primaryForeground on the bar',
    (tester) async {
      await pumpMx(tester, _nav(selected: 1));

      expect(find.byIcon(AppIcons.studySelected), findsOneWidget);
      expect(find.byIcon(AppIcons.study), findsNothing);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color,
        scheme.onPrimaryContainer,
      );
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.library)).color,
        scheme.onSurfaceVariant,
      );
      // The label sits on the bar's ground, not on the pill: the brand as text.
      expect(
        tester.widget<Text>(find.text('Study')).style!.color,
        MxSemanticColors.light.primaryForeground,
      );
    },
  );

  testWidgets('the pill is primaryContainer, in both themes', (tester) async {
    await pumpMx(tester, _nav());
    final pill = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byIcon(AppIcons.librarySelected),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    expect((pill.decoration as BoxDecoration).color, scheme.primaryContainer);
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
      isSemantics(label: 'Library', isSelected: true, isButton: true),
    );
    handle.dispose();
  });

  testWidgets(
    'the bar is the page surface with the outlineVariant edge, no backdrop '
    'blur: nothing scrolls under it (DEV-302)',
    (tester) async {
      await pumpMx(tester, _nav());

      expect(find.byType(BackdropFilter), findsNothing);
      final bar = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(MxBottomNav),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((bar.decoration as BoxDecoration).color, scheme.surface);
      expect(
        (bar.decoration as BoxDecoration).border,
        Border.all(color: scheme.outlineVariant),
      );
    },
  );

  testWidgets(
    'dark: the pill is primaryContainer, the glyph onPrimaryContainer, the label primaryForeground',
    (tester) async {
      final dark = AppColorSchemes.dark;
      await pumpMx(tester, _nav(selected: 1), brightness: Brightness.dark);
      await tester.pumpAndSettle();
      final pill = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byIcon(AppIcons.studySelected),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );

      expect((pill.decoration as BoxDecoration).color, dark.primaryContainer);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color,
        dark.onPrimaryContainer,
      );
      expect(
        tester.widget<Text>(find.text('Study')).style!.color,
        MxSemanticColors.dark.primaryForeground,
      );
    },
  );

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });

  testWidgets('focus: Tab lands on the first destination; one ring, '
      'primaryForeground, and it moves', (tester) async {
    _showFocusRings();
    await pumpMx(tester, _nav());
    expect(_ringFinder(), findsNothing);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ringFinder(), findsOneWidget);
    expect(_painter(tester).color, MxSemanticColors.light.primaryForeground);
    expect(_painter(tester).placement, MxFocusRingPlacement.inside);
    final first = tester.getRect(_ringFinder());
    expect(first.center, tester.getCenter(_itemOf('Library')));

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ringFinder(), findsOneWidget);
    expect(tester.getRect(_ringFinder()), isNot(first));
  });
}
