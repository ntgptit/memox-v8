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

  testWidgets('56 box; the arc in the ramp fill, the label in its foreground', (
    tester,
  ) async {
    for (final (fraction, text, color, ink) in [
      (0.2, '20%', semantic.warning, semantic.warning),
      (0.42, '42%', scheme.primary, semantic.primaryForeground),
      (0.9, '90%', semantic.mastery, semantic.mastery),
    ]) {
      await pumpMx(tester, MxMasteryDonut(fraction: fraction));

      expect(
        tester.getSize(find.byType(MxMasteryDonut)),
        const Size.square(56),
      );
      // The arc is the fill; the label is text, so it takes the foreground.
      expect(tester.widget<Text>(find.text(text)).style!.color, ink);
      expect(
        _ring(tester),
        paints
          ..circle(color: scheme.outlineVariant, style: PaintingStyle.stroke)
          ..arc(color: color, strokeCap: StrokeCap.round),
      );
    }
  });

  testWidgets('0%: the track only; the label in the lowest band (RF5)', (
    tester,
  ) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 0));

    expect(tester.widget<Text>(find.text('0%')).style!.color, semantic.warning);
    expect(_ring(tester), paints..circle(color: scheme.outlineVariant));
    expect(_ring(tester), isNot(paints..arc()));
  });

  testWidgets('100%: the full ring at the top colour', (tester) async {
    await pumpMx(tester, const MxMasteryDonut(fraction: 1));

    expect(
      tester.widget<Text>(find.text('100%')).style!.color,
      semantic.mastery,
    );
    expect(_ring(tester), paints..arc(color: semantic.mastery));
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

  testWidgets('the track is outlineVariant in both themes; at 0 there is no '
      'arc and the label is warning; at 0.5 it is primaryForeground', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      final isLight = brightness == Brightness.light;
      final colors = isLight ? AppColorSchemes.light : AppColorSchemes.dark;
      final roles = isLight ? MxSemanticColors.light : MxSemanticColors.dark;
      await pumpMx(
        tester,
        const MxMasteryDonut(fraction: 0),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(_ring(tester), paints..circle(color: colors.outlineVariant));
      expect(_ring(tester), isNot(paints..arc()));
      expect(tester.widget<Text>(find.text('0%')).style!.color, roles.warning);

      await pumpMx(
        tester,
        const MxMasteryDonut(fraction: 0.5),
        brightness: brightness,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('50%')).style!.color,
        roles.primaryForeground,
      );
    }
  });
}
