import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/color_tint.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';

import '../../support/palette_status.dart';
import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

const _message = '2 changes are kept only on this device';

Widget _width(Widget child) => SizedBox(width: 328, child: child);

MxButton _action(String label) =>
    MxButton(label: label, size: MxButtonSize.small, onPressed: () {});

Decoration _decoration(WidgetTester tester) => tester
    .widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(MxFloatingNotice),
            matching: find.byType(DecoratedBox),
          )
          .first,
    )
    .decoration;

/// The fill and the shadow of the card, whichever surface paints it.
({Color? color, List<BoxShadow>? shadows}) _ground(WidgetTester tester) =>
    switch (_decoration(tester)) {
      final BoxDecoration box => (color: box.color, shadows: box.boxShadow),
      final ShapeDecoration shape => (
        color: shape.color,
        shadows: shape.shadows,
      ),
      _ => (color: null, shadows: null),
    };

/// The corner radius of the card, whichever surface paints it.
BorderRadiusGeometry? _radius(WidgetTester tester) =>
    switch (_decoration(tester)) {
      final BoxDecoration box => box.borderRadius,
      final ShapeDecoration shape =>
        (shape.shape as RoundedSuperellipseBorder).borderRadius,
      _ => null,
    };

void main() {
  final colors = appLightColors;
  final mx = lightStatus;

  testWidgets('the warning card, lifted by the overlay shadow', (tester) async {
    await pumpMx(tester, _width(const MxFloatingNotice(message: _message)));
    final glyph = tester.widget<Icon>(find.byIcon(AppIcons.alert));

    final ground = _ground(tester);
    expect(ground.color, mx.warning.tintOver(colors.background));
    expect(
      ground.shadows,
      forUiTheme(tester, find.byType(MxFloatingNotice)).style.shadow,
    );
    expect(ground.shadows, isNotEmpty);
    // A glyph takes the text colour, never the amber fill (SW-REV-001).
    expect(
      (glyph.size, glyph.color),
      (const AppDimens().sizeIconInline, mx.warning),
    );
  });

  testWidgets(
    'the card keeps its md radius (10), 16 side inset and 48 height',
    (tester) async {
      await pumpMx(tester, _width(const MxFloatingNotice(message: 'Waiting')));
      final card = tester.getRect(find.byType(MxFloatingNotice));

      expect(_radius(tester), BorderRadius.circular(10));
      expect(card.height, const AppDimens().sizeControl);
      expect(tester.getTopLeft(find.byIcon(AppIcons.alert)).dx - card.left, 16);
    },
  );

  testWidgets('dark: the dark warning tint, its glyph and the dark text', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(const MxFloatingNotice(message: _message)),
      brightness: Brightness.dark,
    );
    await tester.pumpAndSettle();
    final night = darkStatus;
    final ground = _ground(tester);

    expect(ground.color, night.warning.tintOver(appDarkColors.background));
    expect(
      tester.widget<Icon>(find.byIcon(AppIcons.alert)).color,
      night.warning,
    );
    expect(
      tester.widget<Text>(find.text(_message)).style!.color,
      appDarkColors.foreground,
    );
    expect(
      forUiTheme(tester, find.byType(MxFloatingNotice)).style.shadow,
      ground.shadows,
    );
  });

  testWidgets('one action sits on the message line, at the end', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxFloatingNotice(message: 'Waiting', actions: [_action('Details')]),
      ),
    );
    final text = tester.getRect(find.text('Waiting'));
    final action = tester.getRect(find.text('Details'));

    expect(action.left, greaterThan(text.right));
    expect((action.center.dy - text.center.dy).abs(), lessThan(1));
  });

  testWidgets('two actions go under the message, at the end', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxFloatingNotice(
          message: _message,
          actions: [_action('Try again'), _action('Keep on this device')],
        ),
      ),
    );
    final text = tester.getRect(find.text(_message));
    final keep = tester.getRect(find.byType(MxButton).last);
    final card = tester.getRect(find.byType(MxFloatingNotice));

    expect(
      tester.getRect(find.byType(MxButton).first).top,
      greaterThan(text.bottom),
    );
    expect(card.right - keep.right, lessThan(20));
  });

  testWidgets('a live region that reads the message', (tester) async {
    await pumpMx(tester, _width(const MxFloatingNotice(message: _message)));

    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.liveRegion ?? false),
      ),
      findsOneWidget,
    );
  });
}
