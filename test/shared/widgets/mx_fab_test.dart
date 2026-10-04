import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_fab.dart';

import 'support/mx_harness.dart';

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: a 52 primary square read by its label', (tester) async {
      var taps = 0;
      await pumpMx(
        tester,
        MxFab(
          icon: Icons.add,
          semanticLabel: 'New deck',
          onPressed: () => taps++,
        ),
        theme: theme,
      );
      expect(
        tester.getSize(find.byType(FloatingActionButton)),
        const Size.square(AppSize.fab),
      );
      final Material fill = tester.widget(
        find.descendant(
          of: find.byType(FloatingActionButton),
          matching: find.byType(Material),
        ),
      );
      expect(fill.color, theme.colorScheme.primary);
      expect(find.byTooltip('New deck'), findsOneWidget);
      await tester.tap(find.byType(FloatingActionButton));
      expect(taps, 1);
    });
  }
}
