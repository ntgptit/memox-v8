import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';

import '../../support/widget_harness.dart';

RenderObject _ring(WidgetTester tester) => tester.renderObject(
  find
      .descendant(
        of: find.byType(MxMasteryDonut),
        matching: find.byType(CustomPaint),
      )
      .first,
);

void main() {
  final scheme = AppColorSchemes.light;
  final semantic = MxSemanticColors.light;

  testWidgets('56 box; the label is the percentage in the ramp colour', (
    tester,
  ) async {
    for (final (fraction, text, color) in [
      (0.2, '20%', semantic.statusLearning),
      (0.42, '42%', semantic.statusReviewing),
      (0.9, '90%', semantic.statusMastered),
    ]) {
      await pumpMx(tester, MxMasteryDonut(fraction: fraction));

      expect(
        tester.getSize(find.byType(MxMasteryDonut)),
        const Size.square(56),
      );
      expect(tester.widget<Text>(find.text(text)).style!.color, color);
      expect(
        _ring(tester),
        paints
          ..circle(color: scheme.surfaceContainer, style: PaintingStyle.stroke)
          ..arc(color: color, strokeCap: StrokeCap.round),
      );
    }
  });

  testWidgets('0%: the track only; the label in the lowest band (RF5)', (
    tester,
  ) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 0));

    expect(
      tester.widget<Text>(find.text('0%')).style!.color,
      semantic.statusLearning,
    );
    expect(_ring(tester), paints..circle(color: scheme.surfaceContainer));
    expect(_ring(tester), isNot(paints..arc()));
  });

  testWidgets('100%: the full ring at the top colour', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 1));

    expect(
      tester.widget<Text>(find.text('100%')).style!.color,
      semantic.statusMastered,
    );
    expect(_ring(tester), paints..arc(color: semantic.statusMastered));
  });

  testWidgets('at 2x the label stays inside the ring', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 1), textScale: 2);

    expect(tester.takeException(), isNull);
    expect(tester.getRect(find.text('100%')).width, lessThanOrEqualTo(44));
  });

  test('out of range or NaN asserts (RF5)', () {
    expect(() => MxMasteryDonut(fraction: 1.2), throwsAssertionError);
    expect(() => MxMasteryDonut(fraction: -0.1), throwsAssertionError);
    expect(() => MxMasteryDonut(fraction: double.nan), throwsAssertionError);
  });
}
