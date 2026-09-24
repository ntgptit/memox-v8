import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_flag_mark.dart';

import '../../support/widget_harness.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the flag draws in streakInk and says it is flagged, '
        '${brightness.name}', (tester) async {
      await pumpMx(
        tester,
        const MxFlagMark(semanticLabel: 'Flagged'),
        brightness: brightness,
      );
      final icon = tester.widget<Icon>(find.byType(Icon));
      final context = tester.element(find.byType(MxFlagMark));

      expect(icon.icon, AppIcons.flagged);
      expect(icon.color, context.derivedColors.streakInk);
      expect(find.bySemanticsLabel('Flagged'), findsOneWidget);
    });
  }
}
