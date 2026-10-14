import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/app_dimens.g.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
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
  final scheme = lightColorScheme;

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

  testWidgets(
    'small buttons with 48 targets; the value column is at least 48',
    (tester) async {
      await pumpMx(tester, _stepper(value: 1));
      final painted = find.descendant(
        of: find.byType(TextButton),
        matching: find.byType(Material),
      );

      expect(
        tester.getSize(painted.first),
        Size.square(const AppDimens().sizeButtonSmall),
      );
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

  testWidgets('disabled ignores taps and dims the value once', (tester) async {
    var taps = 0;
    await pumpMx(tester, _stepper(isEnabled: false, onIncrement: () => taps++));
    await tester.tap(find.byTooltip('More cards'), warnIfMissed: false);

    expect(taps, 0);
    expect(_opacityAbove(tester, find.byKey(_valueKey)), 0.38);
  });

  // DEV-372: the step buttons resolve their own disabled colours, so no
  // wrapper may dim them a second time.
  testWidgets('a disabled step button paints the theme disabled colours only', (
    tester,
  ) async {
    await pumpMx(tester, _stepper(isEnabled: false));

    final buttons = find.byType(TextButton);
    expect(buttons, findsNWidgets(2));
    for (final button in buttons.evaluate()) {
      final target = find.byElementPredicate((element) => element == button);
      expect(_opacityAbove(tester, target), 1);
      final material = tester.widget<Material>(
        find.descendant(of: target, matching: find.byType(Material)).first,
      );
      expect(material.color, scheme.onSurface.withValues(alpha: 0.12));
      final icon = find.descendant(of: target, matching: find.byType(Icon));
      expect(
        IconTheme.of(tester.element(icon)).color,
        scheme.onSurface.withValues(alpha: 0.38),
      );
    }
  });

  testWidgets('an enabled stepper is not dimmed anywhere', (tester) async {
    await pumpMx(tester, _stepper());

    expect(_opacityAbove(tester, find.byType(MxStepper)), 1);
    expect(_opacityAbove(tester, find.byKey(_valueKey)), 1);
    expect(_opacityAbove(tester, find.byType(TextButton).first), 1);
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
}
