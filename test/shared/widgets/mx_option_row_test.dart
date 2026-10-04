import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a tap picks it; it is a checked member of a group', (
    tester,
  ) async {
    var picked = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: MxOptionRow(
          title: 'Name',
          isSelected: true,
          onSelected: () => picked++,
        ),
      ),
    );
    await tester.tap(find.text('Name'));
    expect(picked, 1);
    expect(
      tester.getSemantics(find.byType(MxOptionRow)),
      isSemantics(isInMutuallyExclusiveGroup: true, isChecked: true),
    );
    expect(
      tester.getSize(find.byType(MxOptionRow)).height,
      greaterThanOrEqualTo(AppSize.tapTarget),
    );
  });

  testWidgets('a locked row dims its radio and title, never the reason', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 320,
        child: MxOptionRow(
          title: 'SM-2',
          description: 'Locked after the first review',
          isSelected: false,
          onSelected: null,
        ),
      ),
    );
    final Iterable<Opacity> dims = tester.widgetList<Opacity>(
      find.byType(Opacity),
    );
    expect(dims.map((o) => o.opacity), everyElement(AppOpacity.disabled));
    expect(dims, hasLength(2));
    expect(
      find.ancestor(
        of: find.text('Locked after the first review'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testWidgets('the selected row is never dimmed, even when locked', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 320,
        child: MxOptionRow(
          title: 'Eight boxes',
          isSelected: true,
          onSelected: null,
        ),
      ),
    );
    final Iterable<Opacity> dims = tester.widgetList<Opacity>(
      find.byType(Opacity),
    );
    expect(dims.map((o) => o.opacity), everyElement(1));
  });
}
