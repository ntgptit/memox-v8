import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/primitives/mx_chip_shell.dart';

import 'support/mx_harness.dart';

BoxDecoration _ground(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxChipShell),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  final ColorScheme s = mxThemes['light']!.colorScheme;

  testWidgets('a filled chip rests raised and fills primary when selected', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxChipShell(
        label: 'All',
        isSelected: false,
        isGhost: false,
        onTap: () {},
      ),
    );
    expect(_ground(tester).color, s.surfaceContainerLowest);
    await pumpMx(
      tester,
      MxChipShell(label: 'All', isSelected: true, isGhost: false, onTap: () {}),
    );
    expect(_ground(tester).color, s.primary);
  });

  testWidgets('a ghost chip has no fill until it is active', (tester) async {
    await pumpMx(
      tester,
      MxChipShell(
        label: 'Manual',
        isSelected: false,
        isGhost: true,
        onTap: () {},
      ),
    );
    expect(_ground(tester).color, isNull);
    await pumpMx(
      tester,
      MxChipShell(
        label: 'Manual',
        isSelected: true,
        isGhost: true,
        onTap: () {},
      ),
    );
    expect(_ground(tester).color, s.primaryContainer);
  });

  testWidgets('it paints 28 inside a 48 hit area', (tester) async {
    await pumpMx(
      tester,
      MxChipShell(
        label: 'All',
        isSelected: false,
        isGhost: false,
        onTap: () {},
      ),
    );
    expect(tester.getSize(find.byType(MxChipShell)).height, AppSize.tapTarget);
    expect(tester.getSize(find.byType(DecoratedBox).last).height, AppSize.chip);
  });
}
