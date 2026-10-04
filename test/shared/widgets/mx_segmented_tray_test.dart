import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';

import 'support/mx_harness.dart';

void main() {
  const segments = [
    MxSegmentedTrayItem(value: 7, label: 'Last 7 days'),
    MxSegmentedTrayItem(value: 30, label: 'Last 30 days'),
  ];

  testWidgets('a tap picks a segment; the chosen one reads as selected', (
    tester,
  ) async {
    int? picked;
    await pumpMx(
      tester,
      MxSegmentedTray<int>(
        segments: segments,
        selected: 7,
        onChanged: (v) => picked = v,
      ),
    );
    await tester.tap(find.text('Last 30 days'));
    expect(picked, 30);
    expect(
      tester.getSemantics(find.text('Last 7 days')),
      isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
    );
  });

  testWidgets('each segment is 48 to the touch', (tester) async {
    await pumpMx(
      tester,
      MxSegmentedTray<int>(segments: segments, selected: 7, onChanged: (_) {}),
    );
    expect(
      tester.getSize(find.byType(MxSegmentedTray<int>)).height,
      AppSize.tapTarget,
    );
  });

  testWidgets('expanded, the segments share the width equally', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 360,
        child: MxSegmentedTray<int>(
          segments: segments,
          selected: 7,
          isExpanded: true,
          onChanged: (_) {},
        ),
      ),
    );
    final double a = tester
        .getSize(
          find.ancestor(
            of: find.text('Last 7 days'),
            matching: find.byType(Expanded),
          ),
        )
        .width;
    final double b = tester
        .getSize(
          find.ancestor(
            of: find.text('Last 30 days'),
            matching: find.byType(Expanded),
          ),
        )
        .width;
    expect(a, b);
  });

  testWidgets('the chosen segment is lighter than its tray in both themes', (
    tester,
  ) async {
    for (final theme in mxThemes.values) {
      await pumpMx(
        tester,
        MxSegmentedTray<int>(
          segments: segments,
          selected: 7,
          onChanged: (_) {},
        ),
        theme: theme,
      );
      final BoxDecoration chosen =
          tester
                  .widget<AnimatedContainer>(
                    find.byType(AnimatedContainer).first,
                  )
                  .decoration!
              as BoxDecoration;
      final BoxDecoration tray =
          tester
                  .widget<DecoratedBox>(find.byType(DecoratedBox).first)
                  .decoration
              as BoxDecoration;
      expect(
        chosen.color!.computeLuminance(),
        greaterThan(tray.color!.computeLuminance()),
        reason: theme.brightness.name,
      );
    }
  });

  testWidgets('the chosen segment is told by weight, not only by its ground', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxSegmentedTray<int>(
        segments: const [
          MxSegmentedTrayItem(value: 1, label: 'Day'),
          MxSegmentedTrayItem(value: 2, label: 'Week'),
        ],
        selected: 1,
        onChanged: (_) {},
      ),
    );
    FontWeight? weight(String label) =>
        tester.widget<Text>(find.text(label)).style!.fontWeight;
    expect(weight('Day'), FontWeight.w700);
    expect(weight('Week'), FontWeight.w500);
  });
}
