import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/core/theme/theme_rules.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_code_card_widget.dart';

import '../../../support/widget_harness.dart';

// Code reads in the mono face at the body role's size; only the family
// changes (token spec §3.3), and a frame number takes the accent.

void main() {
  testWidgets('code is the body role in the mono face', (tester) async {
    await pumpMx(
      tester,
      const MonitoringCodeCardWidget(title: 'Payload', text: '{"a": 1}'),
    );
    final context = tester.element(find.byType(MonitoringCodeCardWidget));
    final style = tester
        .widget<SelectableText>(find.byType(SelectableText))
        .style!;

    expect(style.fontFamily, AppTypography.monoFamily);
    expect(style.fontSize, context.texts.bodyMedium!.fontSize);
    expect(style.height, context.texts.bodyMedium!.height);
  });

  testWidgets('a stack trace frame number is mono in the accent', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MonitoringCodeCardWidget.stackTrace(
        title: 'Stack trace',
        text: '#0      main (file:///a.dart:1:1)',
      ),
    );
    final context = tester.element(find.byType(MonitoringCodeCardWidget));
    final frame = tester.widget<Text>(find.text('#0'));

    expect(frame.style!.fontFamily, AppTypography.monoFamily);
    expect(frame.style!.color, context.accentColor);
  });
}
