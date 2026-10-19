import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/core/theme/mx_status_colors.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_row_ink.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

const _bodyKey = ValueKey('card-body');
const _dimens = AppDimens();

ShapeDecoration _surface(WidgetTester tester) =>
    paintedDecoration(tester, find.byType(MxCard));

RoundedSuperellipseBorder _shape(WidgetTester tester) =>
    _surface(tester).shape as RoundedSuperellipseBorder;

FThemeData _theme(WidgetTester tester) =>
    forUiTheme(tester, find.byType(MxCard));

void main() {
  for (final brightness in Brightness.values) {
    final isLight = brightness == Brightness.light;
    final colors = isLight ? appLightColors : appDarkColors;
    final mx = isLight ? MxStatusColors.light : MxStatusColors.dark;

    group(brightness.name, () {
      testWidgets(
        "ForUI's card ground, large radius and hairline edge, padding, no "
        'shadow',
        (tester) async {
          await pumpMx(
            tester,
            const MxCard(child: SizedBox(key: _bodyKey, height: 40)),
            brightness: brightness,
          );

          expect(_surface(tester).color, colors.card);
          expect(_surface(tester).shadows, isNull);
          expect(
            _shape(tester).borderRadius,
            _theme(tester).style.borderRadius.lg,
          );
          expect(
            _shape(tester).side,
            BorderSide(
              color: colors.border,
              width: _theme(tester).style.borderWidth,
            ),
          );
          expect(
            tester.getTopLeft(find.byKey(_bodyKey)) -
                tester.getTopLeft(find.byType(MxCard)),
            Offset(_dimens.space24, _dimens.space24),
          );
        },
      );

      // One flag per case: the ground, and the edge's colour and weight (in
      // hairlines). Every card here is flat.
      final variants = [
        (
          name: 'hero: the accent tint over the page surface',
          card: const MxCard(isHero: true, child: SizedBox(height: 40)),
          ground: colors.primary.tintOver(colors.background),
          edge: colors.border,
          hairlines: 1,
        ),
        (
          name: 'recessed: the muted ground, flat, the hairline edge',
          card: const MxCard(isRecessed: true, child: SizedBox(height: 40)),
          ground: colors.muted,
          edge: colors.border,
          hairlines: 1,
        ),
        (
          name: 'selected: a primary control-weight edge (screen 07 rows)',
          card: const MxCard(isSelected: true, child: SizedBox(height: 40)),
          ground: colors.card,
          edge: colors.primary,
          hairlines: 2,
        ),
      ];
      for (final c in variants) {
        testWidgets(c.name, (tester) async {
          await pumpMx(tester, c.card, brightness: brightness);

          expect(_surface(tester).color, c.ground);
          expect(
            _shape(tester).side,
            BorderSide(
              color: c.edge,
              width: _theme(tester).style.borderWidth * c.hairlines,
            ),
          );
          expect(_surface(tester).shadows, isNull);
        });
      }

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
        final grounds = [
          for (final card in find.byType(MxCard).evaluate())
            paintedDecoration(tester, find.byWidget(card.widget)).color,
        ];

        expect(grounds, [
          mx.warning.tintOver(colors.background),
          mx.success.tintOver(colors.background),
          colors.error.tintOver(colors.background),
        ]);
      });
    });
  }

  testWidgets('full bleed: no padding, clipped, a tappable row works on the '
      'card', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxCard(
        isFullBleed: true,
        child: MxRowInk(
          key: _bodyKey,
          onTap: () => taps++,
          child: const SizedBox(height: 48),
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.byKey(_bodyKey)),
      tester.getTopLeft(find.byType(MxCard)),
    );
    expect(
      tester
          .widget<ClipPath>(
            find.descendant(
              of: find.byType(MxCard),
              matching: find.byType(ClipPath),
            ),
          )
          .clipBehavior,
      Clip.antiAlias,
    );
    // The row sits inside the card's width and answers a tap.
    expect(
      tester.getSize(find.byKey(_bodyKey)).width,
      tester.getSize(find.byType(MxCard)).width,
    );
    await tester.tap(find.byKey(_bodyKey));
    await tester.pumpAndSettle();
    expect(taps, 1);
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
