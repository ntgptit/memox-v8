import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_breadcrumb.dart';

import '../../support/widget_harness.dart';

List<MxBreadcrumbSegment> _path(int depth, {void Function(int)? onTap}) => [
  for (var i = 1; i <= depth; i++)
    MxBreadcrumbSegment(label: 'Level $i', onTap: () => onTap?.call(i)),
];

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('ancestors are tappable, the current level is not', (
    tester,
  ) async {
    final tapped = <int>[];
    await pumpMx(tester, MxBreadcrumb(segments: _path(3, onTap: tapped.add)));
    await tester.tap(find.text('Level 1'));
    await tester.tap(find.text('Level 3'), warnIfMissed: false);

    expect(tapped, [1]);
  });

  testWidgets('ancestor 500 onSurfaceVariant, current 700 onSurface', (
    tester,
  ) async {
    await pumpMx(tester, MxBreadcrumb(segments: _path(2)));

    final ancestor = tester.widget<Text>(find.text('Level 1')).style!;
    final current = tester.widget<Text>(find.text('Level 2')).style!;
    expect(ancestor.fontWeight, FontWeight.w500);
    expect(ancestor.color, scheme.onSurfaceVariant);
    expect(current.fontWeight, FontWeight.w700);
    expect(current.color, scheme.onSurface);
  });

  testWidgets('one outline chevron at 16 between each pair', (tester) async {
    await pumpMx(tester, MxBreadcrumb(segments: _path(4)));
    final chevrons = find.byIcon(AppIcons.chevronRight);

    expect(chevrons, findsNWidgets(3));
    expect(tester.widget<Icon>(chevrons.first).color, scheme.outline);
    expect(tester.getSize(chevrons.first).width, 16);
  });

  testWidgets('a short path starts at the 16 gutter', (tester) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(2))),
    );
    final offset =
        tester.getTopLeft(find.text('Level 1')).dx -
        tester.getTopLeft(find.byType(MxBreadcrumb)).dx;

    expect(offset, greaterThanOrEqualTo(16));
    expect(offset, lessThan(40));
  });

  testWidgets('a 10-level path shows the current level without scrolling', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(width: 360, child: MxBreadcrumb(segments: _path(10))),
    );

    expect(tester.getRect(find.text('Level 10')).right, lessThanOrEqualTo(360));
    expect(tester.takeException(), isNull);
  });

  testWidgets('ancestor segments are 48×48 labelled targets (R4)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxBreadcrumb(
        segments: [
          MxBreadcrumbSegment(label: 'A', onTap: () {}),
          const MxBreadcrumbSegment(label: 'B'),
        ],
      ),
    );

    await expectAccessibleTargets(tester);
  });
}
