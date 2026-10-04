import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_selection_checkbox.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('an 18 box that carries its checked state to the row', (
    tester,
  ) async {
    await pumpMx(
      tester,
      Semantics(
        label: 'Card 1',
        container: true,
        child: const MxSelectionCheckbox(isChecked: true),
      ),
    );
    expect(
      tester.getSize(find.byType(MxSelectionCheckbox)),
      const Size.square(AppSize.checkbox),
    );
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(MxSelectionCheckbox)),
      matchesSemantics(hasCheckedState: true, isChecked: true),
    );
  });

  testWidgets('empty, it draws only its outline', (tester) async {
    await pumpMx(tester, const MxSelectionCheckbox(isChecked: false));
    expect(find.byIcon(Icons.check), findsNothing);
  });
}
