import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/shared/widgets/mx_chip_row.dart';
import 'package:memox/shared/widgets/mx_filter_chip.dart';

import '../../support/paint_clip.dart';
import '../../support/widget_harness.dart';

const _dimens = AppDimens();
final _reach = _dimens.strokeFocusGap + _dimens.strokeFocus;

Widget _row() => Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16),
  child: MxChipRow(
    children: [
      for (var i = 0; i < 8; i++)
        MxFilterChip(label: 'Filter $i', isSelected: false, onSelected: (_) {}),
    ],
  ),
);

Finder _painted(String label) => find
    .descendant(
      of: find.widgetWithText(MxFilterChip, label),
      matching: find.byType(Material),
    )
    .first;

void main() {
  testWidgets('a focused first chip keeps its whole ring', (tester) async {
    await pumpMx(tester, _row());
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final chip = _painted('Filter 0');

    expect(
      clipsAway(tester, chip, tester.getRect(chip).inflate(_reach)),
      isFalse,
    );
  });

  testWidgets('a focused last chip keeps its whole ring', (tester) async {
    await pumpMx(tester, _row());
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-2000, 0),
    );
    await tester.pumpAndSettle();
    for (var i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    }
    await tester.pumpAndSettle();
    final chip = _painted('Filter 7');

    expect(
      clipsAway(tester, chip, tester.getRect(chip).inflate(_reach)),
      isFalse,
    );
  });

  testWidgets('the row lays out as a plain scroll row: chips start at its '
      'edge', (tester) async {
    await pumpMx(tester, _row());

    expect(tester.getTopLeft(find.byType(MxFilterChip).first).dx, 16);
  });

  testWidgets('a chip scrolled past the edge is still cut a ring away', (
    tester,
  ) async {
    await pumpMx(tester, _row());
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    final first = _painted('Filter 0');

    expect(
      clipsAway(tester, first, tester.getRect(first).inflate(_reach)),
      isTrue,
    );
  });
}
