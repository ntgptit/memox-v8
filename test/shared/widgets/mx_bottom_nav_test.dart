import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';

import 'package:memox/core/theme/app_icons.dart';
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
      MxColorsExtension.light.divider,
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
                matching: find.byType(InkWell),
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
    final pill = find
        .ancestor(
          of: find.byIcon(AppIcons.librarySelected),
          matching: find.byType(DecoratedBox),
        )
        .first;

    expect(
      (tester.widget<DecoratedBox>(pill).decoration as ShapeDecoration).color,
      scheme.secondaryContainer,
    );
    expect(
      tester.getSize(pill),
      Size(
        const AppDimens().sizeNavIndicatorWidth,
        const AppDimens().sizeNavIndicatorHeight,
      ),
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

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });
}
