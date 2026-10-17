import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_tint_base.dart';
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
  final colors = appLightColors;

  testWidgets('12 tall, the small radius, full width, the muted ground on the '
      'page', (tester) async {
    await pumpMx(tester, const SizedBox(width: 300, child: MxSkeleton()));

    expect(tester.getSize(find.byType(MxSkeleton)), const Size(300, 12));
    expect(_block(tester).color, colors.muted);
    expect(
      _block(tester).borderRadius,
      tester.element(find.byType(MxSkeleton)).radii.sm,
    );
  });

  testWidgets('the bar is one step off the ground it sits on, on every '
      'ground, light and dark', (tester) async {
    for (final (brightness, colors) in [
      (Brightness.light, appLightColors),
      (Brightness.dark, appDarkColors),
    ]) {
      // The grounds MxTintBase carries: the page, a card, a sheet (the page's
      // colour), a dialog (the card's) and a recessed card. On those of the
      // page's or the card's colour the bar is `muted`; on a ground that is
      // `muted` itself, the stronger `border`.
      for (final (name, ground, bar) in [
        ('page', colors.background, colors.muted),
        ('card', colors.card, colors.muted),
        ('sheet', colors.background, colors.muted),
        ('dialog', colors.card, colors.muted),
        ('recessed', colors.muted, colors.border),
      ]) {
        await pumpMx(
          tester,
          MxTintBase(
            color: ground,
            child: const SizedBox(width: 300, child: MxSkeleton()),
          ),
          brightness: brightness,
        );
        // The theme change animates; the pulse never settles.
        await tester.pump(const Duration(milliseconds: 400));

        expect(_block(tester).color, bar, reason: '$brightness $name');
        expect(
          _block(tester).color,
          isNot(ground),
          reason: '$brightness $name',
        );
      }
    }
  });

  testWidgets('inside an MxCard the bar reads the card ground', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxCard(child: MxSkeleton())),
    );

    expect(_block(tester).color, colors.muted);
  });

  testWidgets('a circle is its height wide with a full radius', (tester) async {
    await pumpMx(tester, const MxSkeleton(height: 28, isCircle: true));

    expect(tester.getSize(find.byType(MxSkeleton)), const Size.square(28));
    expect(_block(tester).borderRadius, BorderRadius.circular(14));
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

  testWidgets('a skeleton row is as tall as a two-line list row', (
    tester,
  ) async {
    await pumpMx(tester, const SizedBox(width: 360, child: MxSkeletonRow()));

    expect(tester.getSize(find.byType(MxSkeletonRow)).height, 72);
  });

  testWidgets('a list says Loading once and runs one ticker', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonList(semanticLabel: 'Loading', rows: 4),
      ),
    );

    expect(find.byType(MxSkeletonRow), findsNWidgets(4));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    expect(tester.binding.transientCallbackCount, 1);
    handle.dispose();
  });

  testWidgets('a list under reduced motion runs no ticker', (tester) async {
    await pumpMx(
      tester,
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: SizedBox(
          width: 360,
          child: MxSkeletonList(semanticLabel: 'Loading'),
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('loose skeletons under one MxSkeletonPulse share a ticker', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxSkeletonPulse(
        child: Column(
          children: [MxSkeleton(width: 80), MxSkeleton(width: 120)],
        ),
      ),
    );

    expect(tester.binding.transientCallbackCount, 1);
  });
}
