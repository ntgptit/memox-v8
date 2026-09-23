import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../support/widget_harness.dart';

BoxDecoration _box(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find.descendant(
                of: find.byType(MxSelectionCheckbox),
                matching: find.byType(DecoratedBox),
              ),
            )
            .decoration
        as BoxDecoration;

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('unchecked: a 20 box with a 2px outline, no fill', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));

    expect(
      tester.getSize(find.byType(MxSelectionCheckbox)),
      const Size.square(20),
    );
    expect(_box(tester).color, isNull);
    expect(_box(tester).border, Border.all(color: scheme.outline, width: 2));
    expect(find.byIcon(AppIcons.check), findsNothing);
  });

  testWidgets('checked: primary fill, 14 onPrimary check, no border (I2)', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: true));

    expect(_box(tester).color, scheme.primary);
    expect(_box(tester).border, isNull);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.check)).color,
      scheme.onPrimary,
    );
    expect(tester.getSize(find.byIcon(AppIcons.check)).width, 14);
  });
}
