import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_opacity.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a list of rows is read once as what is loading', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonList(semanticLabel: 'Loading decks', rowCount: 4),
      ),
    );
    expect(find.byType(MxSkeletonRow), findsNWidgets(4));
    expect(find.bySemanticsLabel('Loading decks'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a row is the medium icon tile and two text-high lines', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonGroup(
          semanticLabel: 'Loading',
          child: MxSkeletonRow(),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(MxSkeleton).first),
      const Size.square(AppSize.iconTileMedium),
    );
    final TextTheme texts = mxThemes['light']!.textTheme;
    expect(
      tester.getSize(find.byType(MxSkeleton).at(1)).height,
      texts.bodyLarge!.fontSize,
    );
    expect(
      tester.getSize(find.byType(MxSkeleton).at(2)).height,
      texts.bodySmall!.fontSize,
    );
  });

  testWidgets('it pulses, and rests under reduced motion', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 360,
        child: MxSkeletonList(semanticLabel: 'Loading', rowCount: 1),
      ),
    );
    final FadeTransition fade = tester.widget(
      find
          .descendant(
            of: find.byType(MxSkeleton),
            matching: find.byType(FadeTransition),
          )
          .first,
    );
    final double start = fade.opacity.value;
    await tester.pump(const Duration(milliseconds: 700));
    expect(fade.opacity.value, isNot(start));
    await tester.pumpWidget(
      MaterialApp(
        theme: mxThemes['light'],
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Center(
            child: SizedBox(
              width: 360,
              child: MxSkeletonList(semanticLabel: 'Loading', rowCount: 1),
            ),
          ),
        ),
      ),
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
            find
                .descendant(
                  of: find.byType(MxSkeleton),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity,
      AppOpacity.skeletonLow,
    );
  });
}
