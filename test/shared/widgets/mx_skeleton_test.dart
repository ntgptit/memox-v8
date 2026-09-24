import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import '../../support/widget_harness.dart';

BoxDecoration _block(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(MxSkeleton),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

double _opacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
        of: find.byType(MxSkeleton),
        matching: find.byType(FadeTransition),
      ),
    )
    .opacity
    .value;

Widget _still(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('12 tall, radius 6, full width, surfaceContainerHigh', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxSkeleton()));

    expect(tester.getSize(find.byType(MxSkeleton)), const Size(300, 12));
    expect(_block(tester).color, scheme.surfaceContainerHigh);
    expect(_block(tester).borderRadius, BorderRadius.circular(6));
  });

  testWidgets('a circle is its height wide with a full radius', (tester) async {
    await pumpMx(tester, const MxSkeleton(height: 28, isCircle: true));

    expect(tester.getSize(find.byType(MxSkeleton)), const Size.square(28));
    expect(_block(tester).borderRadius, BorderRadius.circular(999));
  });

  testWidgets('pulses 0.45 → 0.75 → 0.45 over 1.4s', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxSkeleton()));
    expect(_opacity(tester), closeTo(0.45, 0.001));

    await tester.pump(const Duration(milliseconds: 700));
    expect(_opacity(tester), closeTo(0.75, 0.001));

    await tester.pump(const Duration(milliseconds: 700));
    expect(_opacity(tester), closeTo(0.45, 0.001));
  });

  testWidgets('reduced motion: rests at 0.5 and nothing runs (RF4)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _still(const SizedBox(width: 300, child: MxSkeleton())),
    );

    expect(
      find.descendant(
        of: find.byType(MxSkeleton),
        matching: find.byType(FadeTransition),
      ),
      findsNothing,
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: find.byType(MxSkeleton),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.5,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('skeleton row: a 28 tile and bars at 70% and 45%', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 360, child: MxSkeletonRow()));
    final sizes = tester
        .widgetList<MxSkeleton>(find.byType(MxSkeleton))
        .map((skeleton) => tester.getSize(find.byWidget(skeleton)))
        .toList();

    // The text column is 360 − 16 − 16 − 28 − 12 = 288 wide.
    expect(sizes, [
      const Size.square(28),
      const Size(288 * 0.7, 12),
      const Size(288 * 0.45, 12),
    ]);
  });
}
