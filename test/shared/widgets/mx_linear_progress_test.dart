import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/mastery_ramp.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
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
    expect(
      tester.getSize(find.byType(MxLinearProgress)).height,
      AppSize.progressTrack,
    );
    // Both variants fill in the mastery colour over the track (spec §6).
    final fillColor = tester.widget<ColoredBox>(
      find.descendant(
        of: find.byType(FractionallySizedBox),
        matching: find.byType(ColoredBox),
      ),
    );
    expect(fillColor.color, MxSemanticColors.light.mastery);
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

    testWidgets('as tall as the plain track, on the ramp track, filled in the '
        'mastery colour', (tester) async {
      await pumpMx(
        tester,
        const SizedBox(width: 200, child: MxLinearProgress.mastery(value: 0.5)),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(MxLinearProgress)).height,
        AppSize.progressTrack,
      );
      final fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(FractionallySizedBox),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color, MxSemanticColors.light.mastery);
      final track = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(MxLinearProgress),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(track.color, MasteryRamp.track(AppColorSchemes.light));
    });

    testWidgets('any mastery shows, and a deck short of 100% never looks '
        'full: the fill keeps its height in from either end', (tester) async {
      expect(await drawn(tester, 0.0001), AppSize.progressTrack / 200);
      expect(await drawn(tester, 0.9999), 1 - AppSize.progressTrack / 200);
      expect(await drawn(tester, 0.5), 0.5);
      expect(await drawn(tester, 1), 1);
    });

    testWidgets('0 paints the track alone: the fill has no width', (
      tester,
    ) async {
      expect(await drawn(tester, 0), 0);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(FractionallySizedBox),
                matching: find.byType(ColoredBox),
              ),
            )
            .width,
        0,
      );
    });
  });

  testWidgets('the plain bar keeps its height as the least fill, and may end '
      'full', (tester) async {
    Future<double> drawn(double value) async {
      await pumpMx(
        tester,
        SizedBox(width: 200, child: MxLinearProgress(value: value)),
      );
      await tester.pumpAndSettle();
      return tester
          .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
          .widthFactor!;
    }

    expect(await drawn(0.0001), AppSize.progressTrack / 200);
    expect(await drawn(0.9999), 0.9999);
    expect(await drawn(1), 1);
  });

  test('a value outside 0 to 1 is a programming error', () {
    expect(() => MxLinearProgress(value: 1.2), throwsAssertionError);
  });
}
