import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import 'support/mx_harness.dart';

Widget _twice(Widget child) => MediaQuery(
  data: const MediaQueryData(textScaler: TextScaler.linear(2)),
  child: child,
);

void main() {
  testWidgets('a filter chip toggles and reads selected', (tester) async {
    bool? next;
    await pumpMx(
      tester,
      MxFilterChip(
        label: 'Flagged',
        isSelected: true,
        onSelected: (v) => next = v,
      ),
    );
    await tester.tap(find.text('Flagged'));
    expect(next, isFalse);
    expect(
      tester.getSemantics(find.byType(MxFilterChip)),
      matchesSemantics(
        label: 'Flagged',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('both chips paint 28 inside a 48 hit area', (tester) async {
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MxFilterChip(label: 'All', isSelected: false, onSelected: (_) {}),
          MxChipTrigger(label: 'Manual', onOpen: () {}),
        ],
      ),
    );
    for (final Type type in [MxFilterChip, MxChipTrigger]) {
      final Finder chip = find.byType(type);
      expect(tester.getSize(chip).height, AppSize.tapTarget);
      expect(
        tester
            .getSize(
              find
                  .descendant(of: chip, matching: find.byType(DecoratedBox))
                  .first,
            )
            .height,
        AppSize.chip,
      );
    }
  });

  testWidgets('at twice the text the pill grows around its label', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _twice(
        MxFilterChip(label: 'Flagged', isSelected: true, onSelected: (_) {}),
      ),
    );
    expect(tester.takeException(), isNull);
    final Rect label = tester.getRect(find.text('Flagged'));
    final Rect pill = tester.getRect(
      find
          .descendant(
            of: find.byType(MxFilterChip),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(pill.height, greaterThan(AppSize.chip));
    expect(label.top, greaterThanOrEqualTo(pill.top));
    expect(label.bottom, lessThanOrEqualTo(pill.bottom));
  });
}
