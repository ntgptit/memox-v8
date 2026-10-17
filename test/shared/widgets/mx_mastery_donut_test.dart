import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/shared/widgets/mx_mastery_donut.dart';

import '../../support/palette_status.dart';
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
  final colors = appLightColors;
  final mx = lightStatus;

  testWidgets('56 box; the arc in the ramp fill, the label in its band\'s '
      'text colour (SW-REV-001)', (tester) async {
    for (final (fraction, text, color, label) in [
      (0.2, '20%', mx.warningFill, mx.warning),
      (0.42, '42%', colors.primary, colors.primary),
      (0.9, '90%', mx.successFill, mx.success),
    ]) {
      await pumpMx(tester, MxMasteryDonut(fraction: fraction));

      expect(
        tester.getSize(find.byType(MxMasteryDonut)),
        const Size.square(56),
      );
      expect(tester.widget<Text>(find.text(text)).style!.color, label);
      expect(
        _ring(tester),
        paints
          ..circle(
            color: MasteryRamp.track(colors),
            style: PaintingStyle.stroke,
          )
          ..arc(color: color, strokeCap: StrokeCap.round),
      );
    }
  });

  testWidgets('the track is the ramp\'s progress track in both themes (token: '
      'progress and countdown ring track)', (tester) async {
    for (final (brightness, colors) in [
      (Brightness.light, appLightColors),
      (Brightness.dark, appDarkColors),
    ]) {
      await pumpMx(
        tester,
        const MxMasteryDonut(fraction: 0.5),
        brightness: brightness,
      );
      await tester.pumpAndSettle();

      expect(
        _ring(tester),
        paints..circle(color: MasteryRamp.track(colors)),
        reason: '$brightness',
      );
    }
  });

  testWidgets('0%: the track only; the label in the lowest band (RF5)', (
    tester,
  ) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 0));

    expect(tester.widget<Text>(find.text('0%')).style!.color, mx.warning);
    expect(_ring(tester), paints..circle(color: MasteryRamp.track(colors)));
    expect(_ring(tester), isNot(paints..arc()));
  });

  testWidgets('100%: the full ring at the top colour, the label in its '
      'text colour', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 1));

    expect(tester.widget<Text>(find.text('100%')).style!.color, mx.success);
    expect(_ring(tester), paints..arc(color: mx.successFill));
  });

  testWidgets('the label never rounds to a lie: 99.6% reads 99%, 0.4% reads '
      '1% (deck mastery spec D13)', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 0.996));
    expect(find.text('99%'), findsOneWidget);

    await pumpMx(tester, const MxMasteryDonut(fraction: 0.004));
    expect(find.text('1%'), findsOneWidget);
  });

  test('out of range or NaN asserts (RF5)', () {
    expect(() => MxMasteryDonut(fraction: 1.2), throwsAssertionError);
    expect(() => MxMasteryDonut(fraction: -0.1), throwsAssertionError);
    expect(() => MxMasteryDonut(fraction: double.nan), throwsAssertionError);
  });

  testWidgets('a named donut reads its subject with the percentage', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const MxMasteryDonut(fraction: 0.25, semanticLabel: 'Mastered'),
    );

    final node = tester.getSemantics(find.byType(MxMasteryDonut));
    expect(node.label, 'Mastered');
    expect(node.value, '25%');
    expect(find.bySemanticsLabel('25%'), findsNothing);
    handle.dispose();
  });
}
