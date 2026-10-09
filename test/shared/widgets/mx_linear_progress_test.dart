import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import '../../support/widget_harness.dart';

// FE-A8 H2: the themed track that 13's Resume card and 14's resume banner
// draw; decorative (S7).

void main() {
  testWidgets('the fill is the value, and the track says nothing of its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(width: 200, child: MxLinearProgress(value: 0.6)),
    );
    await tester.pumpAndSettle();

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.6);
    expect(tester.getSize(find.byType(MxLinearProgress)).height, 4);
    // No node of its own: the whole track sits under ExcludeSemantics.
    expect(
      find.descendant(
        of: find.byType(MxLinearProgress),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  group('mastery (deck mastery spec D8, D13)', () {
    Future<double> drawn(WidgetTester tester, double value) async {
      await pumpMx(
        tester,
        SizedBox(width: 200, child: MxLinearProgress.mastery(value: value)),
      );
      await tester.pumpAndSettle();
      return tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
    }

    testWidgets('5 tall, filled in the ramp colour', (tester) async {
      await pumpMx(
        tester,
        const SizedBox(width: 200, child: MxLinearProgress.mastery(value: 0.5)),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(MxLinearProgress)).height, 5);
      final fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color, AppColorSchemes.light.primary);
    });

    testWidgets('any mastery shows, and a deck short of 100% never looks '
        'full: the fill keeps its height in from either end', (tester) async {
      expect(await drawn(tester, 0.0001), 5 / 200);
      expect(await drawn(tester, 0.9999), 1 - 5 / 200);
      expect(await drawn(tester, 0.5), 0.5);
      expect(await drawn(tester, 1), 1);
    });

    testWidgets('0 paints the track alone', (tester) async {
      expect(await drawn(tester, 0), 0);
      expect(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(ColoredBox),
        ),
        findsNothing,
      );
    });
  });

  test('a value outside 0 to 1 is a programming error', () {
    expect(() => MxLinearProgress(value: 1.2), throwsAssertionError);
  });
}
