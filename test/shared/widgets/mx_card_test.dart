import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/core/theme/generated/mx_colors_extension.g.dart';
import 'package:memox/shared/widgets/mx_card.dart';

import '../../support/theme_expect.dart';
import '../../support/widget_harness.dart';

const _bodyKey = ValueKey('card-body');
const _dimens = AppDimens();

Material _surface(WidgetTester tester) => tester.widget<Material>(
  find
      .descendant(of: find.byType(MxCard), matching: find.byType(Material))
      .first,
);

RoundedRectangleBorder _shape(WidgetTester tester) =>
    _surface(tester).shape! as RoundedRectangleBorder;

void main() {
  for (final brightness in Brightness.values) {
    final isLight = brightness == Brightness.light;
    final scheme = isLight ? lightColorScheme : darkColorScheme;
    final mx = isLight ? MxColorsExtension.light : MxColorsExtension.dark;

    group(brightness.name, () {
      testWidgets(
        'the card surface, medium radius, padding, no edge, no shadow',
        (tester) async {
          await pumpMx(
            tester,
            const MxCard(child: SizedBox(key: _bodyKey, height: 40)),
            brightness: brightness,
          );

          expect(_surface(tester).color, mx.cardSurface);
          expect(_surface(tester).elevation, 0);
          expect(
            _shape(tester).borderRadius,
            BorderRadius.circular(_dimens.radiusMd),
          );
          expect(_shape(tester).side, BorderSide.none);
          expect(
            tester.getTopLeft(find.byKey(_bodyKey)) -
                tester.getTopLeft(find.byType(MxCard)),
            Offset(_dimens.space24, _dimens.space24),
          );
        },
      );

      testWidgets('hero: the accent tint over the page surface', (
        tester,
      ) async {
        await pumpMx(
          tester,
          const MxCard(isHero: true, child: SizedBox(height: 40)),
          brightness: brightness,
        );

        expect(
          _surface(tester).color,
          accentOf(scheme).tintOver(scheme.surface),
        );
        expect(_shape(tester).side, BorderSide.none);
      });

      testWidgets('warning, success and danger cards tint their colour over '
          'the page surface (FE-A6 D14)', (tester) async {
        await pumpMx(
          tester,
          const Column(
            children: [
              MxCard(isWarning: true, child: Text('warn')),
              MxCard(isSuccess: true, child: Text('ok')),
              MxCard(isDanger: true, child: Text('error')),
            ],
          ),
          brightness: brightness,
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

        expect(colors, [
          mx.warning.tintOver(scheme.surface),
          mx.success.tintOver(scheme.surface),
          scheme.error.tintOver(scheme.surface),
        ]);
      });

      testWidgets('recessed: the container-low ground, flat, no edge', (
        tester,
      ) async {
        await pumpMx(
          tester,
          const MxCard(isRecessed: true, child: SizedBox(height: 40)),
          brightness: brightness,
        );

        expect(_surface(tester).color, scheme.surfaceContainerLow);
        expect(_shape(tester).side, BorderSide.none);
        expect(_surface(tester).elevation, 0);
      });

      testWidgets('selected: a primary control-weight edge (screen 07 rows)', (
        tester,
      ) async {
        await pumpMx(
          tester,
          const MxCard(isSelected: true, child: SizedBox(height: 40)),
          brightness: brightness,
        );

        expect(
          _shape(tester).side,
          BorderSide(color: scheme.primary, width: _dimens.strokeControl),
        );
        expect(_surface(tester).color, mx.cardSurface);
      });
    });
  }

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

  test('a card takes one tone at most', () {
    expect(
      () => MxCard(isHero: true, isWarning: true, child: const SizedBox()),
      throwsAssertionError,
    );
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
