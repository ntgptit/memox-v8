import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_focus_ring.dart';
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
  int minDigits = 1,
}) => MxStepper(
  value: value,
  minDigits: minDigits,
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

  testWidgets('minDigits pads the value and what it reads as (critique '
      '2026-09-30 part 3d-2, E14)', (tester) async {
    await pumpMx(tester, _stepper(value: 5, minDigits: 2));
    expect(find.text('05'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.value == '05',
      ),
      findsOneWidget,
    );
  });

  testWidgets('by default a value keeps its digits', (tester) async {
    await pumpMx(tester, _stepper(value: 5));
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('an invalid value reads as invalid each time TalkBack visits '
      'it (audit 2026-10-07)', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _stepper(value: 250, isInvalid: true));
    expect(
      tester.getSemantics(find.byKey(_valueKey)),
      isSemantics(
        value: '250',
        validationResult: SemanticsValidationResult.invalid,
      ),
    );

    await pumpMx(tester, _stepper());
    expect(
      tester.getSemantics(find.byKey(_valueKey)),
      isSemantics(
        value: '20',
        validationResult: SemanticsValidationResult.none,
      ),
    );
    handle.dispose();
  });

  testWidgets('each step button wears the shared ring in primaryForeground '
      'when focused, not a Material side', (tester) async {
    await pumpMx(tester, _stepper(onDecrement: () {}, onIncrement: () {}));
    expect(find.byType(MxFocusRing), findsNWidgets(2));
    expect(
      tester
          .widgetList<TextButton>(find.byType(TextButton))
          .map((b) => b.style!.side!.resolve({WidgetState.focused})),
      everyElement(BorderSide.none),
    );

    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final painter =
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (w) =>
                        w is CustomPaint &&
                        w.foregroundPainter is MxFocusRingPainter,
                  ),
                )
                .foregroundPainter!
            as MxFocusRingPainter;
    expect(painter.color, MxSemanticColors.light.primaryForeground);
  });
}
