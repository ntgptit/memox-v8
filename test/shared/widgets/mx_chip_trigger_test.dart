import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import '../../support/widget_harness.dart';

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  testWidgets('ghost: no fill, onSurfaceVariant label, a trailing chevron', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final material = tester.widget<Material>(_painted.first);

    expect(tester.getSize(_painted.first).height, 28);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, AppColorSchemes.light.onSurfaceVariant);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
    expect(tester.getSize(find.byIcon(AppIcons.chevronDown)).width, 16);
  });

  testWidgets('opens its menu on tap and meets the 48 target', (tester) async {
    var taps = 0;
    await pumpMx(tester, MxChipTrigger(label: 'Sort', onPressed: () => taps++));
    await tester.tap(find.byType(MxChipTrigger));

    expect(taps, 1);
    await expectAccessibleTargets(tester);
  });

  // SW-REV-010: Import's sheet chip carries a workbook sheet name, user
  // data; a label wider than the column ends in an ellipsis, never an
  // overflow.
  testWidgets('a label wider than its column ends in an ellipsis', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 200,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxChipTrigger(label: 'Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)', onPressed: () {}),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Text>(find.text('Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)')).overflow,
      TextOverflow.ellipsis,
    );
  });
}
