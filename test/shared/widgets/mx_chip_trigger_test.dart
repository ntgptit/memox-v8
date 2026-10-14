import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_component_themes.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/app_icons.dart';
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

    expect(tester.getSize(_painted.first).height, 32);
    expect(material.color?.a ?? 0, 0);
    expect(material.textStyle!.color, lightColorScheme.onSurfaceVariant);
    expect(find.byIcon(AppIcons.chevronDown), findsOneWidget);
    expect(tester.getSize(find.byIcon(AppIcons.chevronDown)).width, 18);
  });

  testWidgets('chip geometry: 8 corners, the label inset 16, no edge', (
    tester,
  ) async {
    await pumpMx(tester, MxChipTrigger(label: 'Sort: Due', onPressed: () {}));
    final shape =
        tester.widget<Material>(_painted.first).shape! as MxFocusRingBorder;

    expect(
      shape.base,
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
    expect(
      tester.getTopLeft(find.text('Sort: Due')).dx -
          tester.getTopLeft(_painted.first).dx,
      16,
    );
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
          child: MxChipTrigger(
            label: 'Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<Text>(
            find.text('Sheet: Vocabulary_Korean_Lesson_12_Final (3 of 5)'),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
  });
}
