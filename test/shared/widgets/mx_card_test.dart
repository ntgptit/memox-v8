import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_decorations.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_shadows.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../support/widget_harness.dart';

const _bodyKey = ValueKey('card-body');

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(MxCard), matching: find.byType(Material))
      .first,
);

RoundedRectangleBorder _shape(WidgetTester tester) =>
    _surface(tester).shape! as RoundedRectangleBorder;

List<BoxShadow>? _shadow(WidgetTester tester) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(MxCard),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .boxShadow;

void main() {
  testWidgets('light: raised fill, radius 12, 20 padding, whisper, no edge', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    await pumpMx(
      tester,
      const MxCard(child: SizedBox(key: _bodyKey, height: 40)),
    );

    expect(_surface(tester).color, scheme.surfaceContainerLowest);
    expect(_shape(tester).borderRadius, BorderRadius.circular(12));
    expect(_shape(tester).side, BorderSide.none);
    expect(_shadow(tester), AppShadows.whisper(scheme));
    expect(
      tester.getTopLeft(find.byKey(_bodyKey)) -
          tester.getTopLeft(find.byType(MxCard)),
      const Offset(20, 20),
    );
    expect(tester.getSize(find.byType(MxCard)).width, 360);
  });

  testWidgets('dark: a 1px ghost edge and no shadow', (tester) async {
    final scheme = AppColorSchemes.dark;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.dark);
    await pumpMx(
      tester,
      const MxCard(child: SizedBox(height: 40)),
      brightness: Brightness.dark,
    );

    expect(_shape(tester).side, BorderSide(color: derived.ghostBorder));
    expect(_shadow(tester), isEmpty);
  });

  testWidgets('hero: surface-hero fill keeps the ghost edge in light', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);
    await pumpMx(
      tester,
      const MxCard(isHero: true, child: SizedBox(height: 40)),
    );

    expect(_surface(tester).color, derived.surfaceHero);
    expect(_shape(tester).side, BorderSide(color: derived.ghostBorder));
  });

  testWidgets('full bleed: no padding, clipped, the row ripple on the card', (
    tester,
  ) async {
    await pumpMx(
      tester,
      MxCard(
        isFullBleed: true,
        child: InkWell(
          key: _bodyKey,
          onTap: () {},
          child: const SizedBox(height: 48),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_bodyKey)),
      tester.getTopLeft(find.byType(MxCard)),
    );
    expect(_surface(tester).clipBehavior, Clip.antiAlias);
    // Review Focus 1: the nearest Material above the row is the card's, so
    // the ripple paints on the card instead of under its fill.
    expect(
      tester.widget<Material>(
        find
            .ancestor(of: find.byKey(_bodyKey), matching: find.byType(Material))
            .first,
      ),
      same(_surface(tester)),
    );
  });

  testWidgets(
    'a warning card fills with warning-soft and edges with the warning border',
    (tester) async {
      await pumpMx(
        tester,
        const MxCard(isWarning: true, child: SizedBox(height: 40)),
      );
      final derived = MxDerivedColors.resolve(
        AppColorSchemes.light,
        MxSemanticColors.light,
      );
      final raised = AppDecorations.raisedCard(
        AppColorSchemes.light,
        derived,
      ).color!;

      expect(
        _surface(tester).color,
        Color.alphaBlend(derived.warningSoft, raised),
      );
      expect(_shape(tester).side.color, derived.warningBorder);
    },
  );

  test('a card is hero or warning, not both', () {
    expect(
      () => MxCard(isHero: true, isWarning: true, child: const SizedBox()),
      throwsAssertionError,
    );
  });

  testWidgets('selected: a primary control-weight edge (screen 07 rows)', (
    tester,
  ) async {
    final scheme = AppColorSchemes.light;
    await pumpMx(
      tester,
      const MxCard(isSelected: true, child: SizedBox(height: 40)),
    );

    expect(_shape(tester).side, BorderSide(color: scheme.primary, width: 2));
    expect(_surface(tester).color, scheme.surfaceContainerLowest);
  });

  testWidgets('a success card and a danger card take their decoration '
      '(FE-A6 D14)', (tester) async {
    await pumpMx(
      tester,
      const Column(
        children: [
          MxCard(isSuccess: true, child: Text('ok')),
          MxCard(isDanger: true, child: Text('error')),
        ],
      ),
    );
    final colors = tester
        .widgetList<Material>(
          find.descendant(
            of: find.byType(MxCard),
            matching: find.byType(Material),
          ),
        )
        .map((material) => material.color)
        .toList();
    final scheme = AppColorSchemes.light;
    final derived = MxDerivedColors.resolve(scheme, MxSemanticColors.light);

    expect(colors, [
      AppDecorations.successCard(scheme, derived).color,
      AppDecorations.dangerCard(scheme, derived).color,
    ]);
  });

  testWidgets('recessed: the answer face of a study card, container-low, '
      'the ghost edge in both themes, flat (FE-A6 P2)', (tester) async {
    for (final brightness in Brightness.values) {
      final scheme = brightness == Brightness.light
          ? AppColorSchemes.light
          : AppColorSchemes.dark;
      final derived = MxDerivedColors.resolve(
        scheme,
        brightness == Brightness.light
            ? MxSemanticColors.light
            : MxSemanticColors.dark,
      );
      await pumpMx(
        tester,
        const MxCard(isRecessed: true, child: SizedBox(height: 40)),
        brightness: brightness,
      );
      // The theme animates from the previous brightness.
      await tester.pumpAndSettle();

      expect(_surface(tester).color, scheme.surfaceContainerLow);
      expect(_shape(tester).side, BorderSide(color: derived.ghostBorder));
      expect(_shadow(tester), isEmpty);
    }
  });

  test('a card takes one tone at most', () {
    expect(
      () => MxCard(isHero: true, isSuccess: true, child: const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => MxCard(isWarning: true, isDanger: true, child: const SizedBox()),
      throwsAssertionError,
    );
    expect(
      () => MxCard(isHero: true, isRecessed: true, child: const SizedBox()),
      throwsAssertionError,
    );
  });
}
