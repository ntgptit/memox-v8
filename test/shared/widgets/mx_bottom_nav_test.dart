import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/core/theme/foundations/app_icon_size.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_radius.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_bottom_nav.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';

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

  testWidgets('a 64 block with no inset, 64 + inset with one', (tester) async {
    await pumpMx(tester, _nav());
    expect(
      tester.getSize(find.byType(MxBottomNav)).height,
      AppSize.bottomNavBar,
    );

    await pumpMx(tester, _nav(), padding: const EdgeInsets.only(bottom: 24));
    expect(
      tester.getSize(find.byType(MxBottomNav)).height,
      AppSize.bottomNavBar + 24,
    );
  });

  testWidgets('the bar runs the full width, unrounded and unpadded', (
    tester,
  ) async {
    await pumpMx(tester, _nav());

    expect(tester.getSize(find.byType(MxBottomNav)).width, phoneSize.width);
    final bar = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxBottomNav),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((bar.decoration as BoxDecoration).borderRadius, isNull);
    expect((bar.decoration as BoxDecoration).boxShadow, isNull);
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

  testWidgets('the selected destination reads on-secondary-container with its '
      'filled glyph, the label on-surface', (tester) async {
    await pumpMx(tester, _nav(selected: 1));

    expect(find.byIcon(AppIcons.studySelected), findsOneWidget);
    expect(find.byIcon(AppIcons.study), findsNothing);
    final selected = tester.widget<Icon>(find.byIcon(AppIcons.studySelected));
    expect(selected.color, scheme.onSecondaryContainer);
    expect(selected.size, AppIconSize.standard);
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

  testWidgets('the pill is the 56x32 secondary container, fully rounded; the '
      'resting ones are transparent', (tester) async {
    await pumpMx(tester, _nav());
    BoxDecoration pillOf(IconData icon) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.byIcon(icon),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    final selected = pillOf(AppIcons.librarySelected);
    expect(selected.color, scheme.secondaryContainer);
    expect(selected.borderRadius, BorderRadius.circular(AppRadius.full));
    expect(pillOf(AppIcons.study).color!.a, 0);
    expect(
      tester.getSize(
        find
            .ancestor(
              of: find.byIcon(AppIcons.librarySelected),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      ),
      const Size(AppSize.navIndicatorWidth, AppSize.navIndicatorHeight),
    );
  });

  testWidgets('the pill animates between destinations over the sheet '
      'duration', (tester) async {
    var selected = 0;
    await pumpMx(
      tester,
      StatefulBuilder(
        builder: (context, setState) => _nav(
          selected: selected,
          onSelected: (i) => setState(() => selected = i),
        ),
      ),
    );
    await tester.tap(find.text('Study'));
    await tester.pump();
    await tester.pump(AppDurations.sheet ~/ 2);
    final pill =
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.byIcon(AppIcons.studySelected),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(pill.color, isNot(scheme.secondaryContainer));
    expect(pill.color!.a, greaterThan(0));

    await tester.pump(AppDurations.sheet);
    final settled =
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(
                        of: find.byIcon(AppIcons.studySelected),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(settled.color, scheme.secondaryContainer);
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

  testWidgets('the bar is the page surface with a hairline divider on top, no '
      'backdrop blur: nothing scrolls under it (DEV-302)', (tester) async {
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
    final decoration = bar.decoration as BoxDecoration;
    expect(decoration.color, scheme.surface);
    expect(
      decoration.border,
      Border(
        top: BorderSide(
          color: MxSemanticColors.light.divider,
          width: AppStroke.hairline,
        ),
      ),
    );
  });

  test('selectedIndex outside the destinations is rejected', () {
    expect(() => _nav(selected: 4), throwsAssertionError);
  });
}
