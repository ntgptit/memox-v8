import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
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

  testWidgets('the selected destination is primary with its filled glyph', (
    tester,
  ) async {
    await pumpMx(tester, _nav(selected: 1));

    expect(find.byIcon(AppIcons.studySelected), findsOneWidget);
    expect(find.byIcon(AppIcons.study), findsNothing);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.studySelected)).color,
      scheme.primary,
    );
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.library)).color,
      scheme.onSurfaceVariant,
    );
    expect(
      tester.widget<Text>(find.text('Study')).style!.color,
      scheme.primary,
    );
  });

  testWidgets('the pill tints primary at 14% in light', (tester) async {
    await pumpMx(tester, _nav());
    final pill = tester.widget<DecoratedBox>(
      find
          .ancestor(
            of: find.byIcon(AppIcons.librarySelected),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );

    expect(
      (pill.decoration as BoxDecoration).color,
      scheme.primary.withValues(alpha: 0.14),
    );
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

  testWidgets('glass: a backdrop blur behind the chrome surface', (
    tester,
  ) async {
    await pumpMx(tester, _nav());

    expect(find.byType(BackdropFilter), findsOneWidget);
  });

  testWidgets('2x text grows the bar instead of overflowing (R3)', (
    tester,
  ) async {
    await pumpMx(tester, _nav(), textScale: 2);

    expect(tester.takeException(), isNull);
  });

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });
}
