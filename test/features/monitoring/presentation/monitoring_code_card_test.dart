import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_typography.dart';
import 'package:memox/core/theme/theme_context.dart';
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
    expect(style.fontSize, context.texts.body.fontSize);
    expect(style.height, context.texts.body.height);
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
    expect(frame.style!.color, context.colors.primary);
  });

  // Owner 2026-10-21: the frame cell is as wide as "#99 " is drawn. It was
  // measured in the bare style: a mono face keeps its advance in bold, but
  // under the system's letter-spacing override the drawn number and its
  // space ran past the cell.
  Widget spaced(Widget child) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).applyTextStyleOverrides(
        lineHeightScaleFactorOverride: null,
        letterSpacingOverride: 2,
        wordSpacingOverride: null,
        paragraphSpacingOverride: null,
      ),
      child: child,
    ),
  );
  for (final textScale in [1.0, 1.3, 2.0]) {
    testWidgets('in bold text and spaced letters the frame cell holds the '
        'drawn number and its space (scale $textScale)', (tester) async {
      const rest = 'main (file:///a.dart:1:1)';
      await pumpMx(
        tester,
        spaced(
          const SizedBox(
            width: 320,
            child: MonitoringCodeCardWidget.stackTrace(
              title: 'Stack trace',
              text: '#0      $rest',
            ),
          ),
        ),
        textScale: textScale,
        isBoldText: true,
      );
      final cell =
          tester.getTopLeft(find.textContaining(rest)).dx -
          tester.getTopLeft(find.text('#0')).dx;
      final style = tester.widget<Text>(find.textContaining(rest)).style;

      await pumpMx(
        tester,
        spaced(
          Align(
            alignment: Alignment.topLeft,
            child: Text('#99 ', style: style),
          ),
        ),
        textScale: textScale,
        isBoldText: true,
      );
      final drawn = tester
          .renderObject<RenderParagraph>(find.byType(RichText))
          .size
          .width;
      expect(cell, closeTo(drawn, 0.01));
    });
  }
}
