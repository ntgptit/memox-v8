import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import '../../support/theme_expect.dart';
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
  final scheme = lightColorScheme;

  // Material 3 checkbox: an 18 box, a 2 corner, a 2px onSurfaceVariant edge.
  testWidgets('unchecked: an 18 box, 2 corner, 2px onSurfaceVariant edge', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));

    expect(
      tester.getSize(find.byType(MxSelectionCheckbox)),
      const Size.square(18),
    );
    expect(_box(tester).color, isNull);
    expect(
      _box(tester).border,
      Border.all(color: scheme.onSurfaceVariant, width: 2),
    );
    expect(_box(tester).borderRadius, BorderRadius.circular(2));
    expect(find.byIcon(AppIcons.check), findsNothing);
  });

  testWidgets('checked: accent fill, 14 onAccent check, no border (I2)', (
    tester,
  ) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: true));

    expect(_box(tester).color, accentOf(scheme));
    expect(_box(tester).color, scheme.primary);
    expect(_box(tester).border, isNull);
    expect(_box(tester).borderRadius, BorderRadius.circular(2));
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.check)).color,
      scheme.onPrimary,
    );
    expect(tester.getSize(find.byIcon(AppIcons.check)).width, 14);
  });

  // Dark `primary` on a sheet is 2.46:1; the fill is the lighter accent step
  // and its check the matching on-colour.
  testWidgets('dark checked: primaryFixedDim fill, onPrimaryFixed check', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxSelectionCheckbox(isChecked: true),
      brightness: Brightness.dark,
    );

    expect(_box(tester).color, appDarkColors.primary);
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.check)).color,
      appDarkColors.primaryForeground,
    );
  });
}
