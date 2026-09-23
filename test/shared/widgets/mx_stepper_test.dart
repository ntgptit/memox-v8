import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import '../../support/widget_harness.dart';

const _valueKey = ValueKey('mx-stepper-value');

MxStepper _stepper({
  int value = 20,
  VoidCallback? onDecrement,
  VoidCallback? onIncrement,
  bool isInvalid = false,
  bool isBusy = false,
  bool isEnabled = true,
}) => MxStepper(
  value: value,
  decrementLabel: 'Fewer cards',
  incrementLabel: 'More cards',
  onDecrement: onDecrement ?? () {},
  onIncrement: onIncrement ?? () {},
  isInvalid: isInvalid,
  isBusy: isBusy,
  isEnabled: isEnabled,
);

void main() {
  final scheme = AppColorSchemes.light;

  testWidgets('minus and plus fire; the value reads in onSurface', (
    tester,
  ) async {
    final calls = <String>[];
    await pumpMx(
      tester,
      _stepper(
        onDecrement: () => calls.add('-'),
        onIncrement: () => calls.add('+'),
      ),
    );
    await tester.tap(find.byTooltip('Fewer cards'));
    await tester.tap(find.byTooltip('More cards'));

    expect(calls, ['-', '+']);
    expect(tester.widget<Text>(find.text('20')).style!.color, scheme.onSurface);
  });

  testWidgets('36 buttons with 48 targets; the value column is at least 48', (
    tester,
  ) async {
    await pumpMx(tester, _stepper(value: 1));
    final painted = find.descendant(
      of: find.byType(TextButton),
      matching: find.byType(Material),
    );

    expect(tester.getSize(painted.first), const Size.square(36));
    expect(
      tester.getSize(find.byKey(_valueKey)).width,
      greaterThanOrEqualTo(48),
    );
    await expectAccessibleTargets(tester);
  });

  testWidgets('invalid: error number inside a 1px error ring', (tester) async {
    await pumpMx(tester, _stepper(value: 250, isInvalid: true));
    final ring =
        (tester.widget<DecoratedBox>(find.byKey(_valueKey)).decoration
                as BoxDecoration)
            .border!;

    expect(tester.widget<Text>(find.text('250')).style!.color, scheme.error);
    expect(ring, Border.all(color: scheme.error));
  });

  testWidgets('valid carries no ring, so turning invalid moves nothing', (
    tester,
  ) async {
    await pumpMx(tester, _stepper());
    final validSize = tester.getSize(find.byKey(_valueKey));
    expect(
      (tester.widget<DecoratedBox>(find.byKey(_valueKey)).decoration
              as BoxDecoration)
          .border,
      isNull,
    );

    await pumpMx(tester, _stepper(isInvalid: true));
    expect(tester.getSize(find.byKey(_valueKey)), validSize);
  });

  testWidgets('busy: a spinner replaces the number, widths hold', (
    tester,
  ) async {
    await pumpMx(tester, _stepper());
    final width = tester.getSize(find.byType(MxStepper)).width;

    await pumpMx(tester, _stepper(isBusy: true));
    expect(find.byType(MxSpinner), findsOneWidget);
    expect(find.text('20'), findsNothing);
    expect(tester.getSize(find.byType(MxStepper)).width, width);
  });

  testWidgets('at a bound the button stops without dimming', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxStepper(
        value: 200,
        decrementLabel: 'Fewer cards',
        incrementLabel: 'More cards',
        onDecrement: () {},
        onIncrement: null,
      ),
    );
    await tester.tap(find.byTooltip('More cards'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      find.ancestor(of: find.byKey(_valueKey), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('disabled dims the whole control and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(tester, _stepper(isEnabled: false, onIncrement: () => taps++));
    await tester.tap(find.byTooltip('More cards'), warnIfMissed: false);

    expect(taps, 0);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(
              of: find.byKey(_valueKey),
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      0.38,
    );
  });
}
