import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import '../../support/forui_expect.dart';
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

/// The step button named [label]: ForUI's icon button, found by its name.
Finder _button(String label) => find.byWidgetPredicate(
  (widget) => widget is FButton && widget.semanticsLabel == label,
  description: 'FButton named $label',
);

FButtonStyle _style(WidgetTester tester) =>
    forUiTheme(tester, find.byType(MxStepper)).buttonStyles.secondary.xs;

/// The product of every [Opacity] above [finder], the dim a widget paints
/// under.
double _opacityAbove(WidgetTester tester, Finder finder) {
  var opacity = 1.0;
  for (final wrapper
      in find.ancestor(of: finder, matching: find.byType(Opacity)).evaluate()) {
    opacity *= (wrapper.widget as Opacity).opacity;
  }
  return opacity;
}

void main() {
  final colors = appLightColors;

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
    await tester.tap(_button('Fewer cards'));
    await tester.pumpAndSettle();
    await tester.tap(_button('More cards'));
    await tester.pumpAndSettle();

    expect(calls, ['-', '+']);
    expect(
      tester.widget<Text>(find.text('20')).style!.color,
      colors.foreground,
    );
  });

  testWidgets(
    'small buttons painted in a 48 target; the value column is at least 48',
    (tester) async {
      await pumpMx(tester, _stepper(value: 1));
      final painted = _style(tester).iconContentStyle.constraints;

      for (final label in ['Fewer cards', 'More cards']) {
        expect(
          paintedRect(tester, _button(label)).size,
          Size.square(painted.minHeight),
          reason: label,
        );
        expect(
          tester.getSize(_button(label)),
          const Size.square(48),
          reason: label,
        );
      }
      expect(
        tester.getSize(find.byKey(_valueKey)).width,
        greaterThanOrEqualTo(48),
      );
      await expectAccessibleTargets(tester);
    },
  );

  testWidgets('invalid: error number inside a 1px error ring', (tester) async {
    await pumpMx(tester, _stepper(value: 250, isInvalid: true));
    final ring =
        (tester.widget<DecoratedBox>(find.byKey(_valueKey)).decoration
                as BoxDecoration)
            .border!;

    final hairline = tester.element(find.byKey(_valueKey)).hairline;

    expect(tester.widget<Text>(find.text('250')).style!.color, colors.error);
    expect(ring, Border.all(color: colors.error, width: hairline));
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
    await tester.tap(_button('More cards'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      find.ancestor(of: find.byKey(_valueKey), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testWidgets('disabled ignores taps and dims the value once', (tester) async {
    var taps = 0;
    await pumpMx(tester, _stepper(isEnabled: false, onIncrement: () => taps++));
    await tester.tap(_button('More cards'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(taps, 0);
    expect(
      _opacityAbove(tester, find.byKey(_valueKey)),
      colors.disabledOpacity,
    );
  });

  // DEV-372: the step buttons resolve their own disabled colours, so no
  // wrapper may dim them a second time.
  testWidgets('a disabled step button paints the theme disabled colours only', (
    tester,
  ) async {
    await pumpMx(tester, _stepper(isEnabled: false));

    final style = _style(tester);
    final buttons = find.byType(FButton);
    expect(buttons, findsNWidgets(2));
    for (var i = 0; i < 2; i++) {
      final button = buttons.at(i);
      expect(_opacityAbove(tester, button), 1);
      expect(
        paintedDecoration(tester, button).color,
        (style.decoration.resolve({
          FTappableVariant.disabled,
        }) as ShapeDecoration).color,
      );
      expect(
        iconColor(
          tester,
          find.descendant(of: button, matching: find.byType(Icon)),
        ),
        style.iconContentStyle.iconStyle.resolve({
          FTappableVariant.disabled,
        }).color,
      );
    }
  });

  testWidgets('an enabled stepper is not dimmed anywhere', (tester) async {
    await pumpMx(tester, _stepper());

    expect(_opacityAbove(tester, find.byType(MxStepper)), 1);
    expect(_opacityAbove(tester, find.byKey(_valueKey)), 1);
    expect(_opacityAbove(tester, find.byType(FButton).first), 1);
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

  testWidgets('each step button is one labelled node that keeps its tap and '
      'its long press', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _stepper());

    for (final label in ['Fewer cards', 'More cards']) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        matchesSemantics(
          label: label,
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasSelectedState: true,
          hasTapAction: true,
          hasLongPressAction: true,
        ),
        reason: label,
      );
    }
    handle.dispose();
  });
}
