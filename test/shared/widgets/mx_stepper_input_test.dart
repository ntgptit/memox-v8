import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/color_schemes.g.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import '../../support/focus_ring_expect.dart';
import '../../support/theme_expect.dart';
import '../../support/widget_harness.dart';

const _valueKey = ValueKey('mx-stepper-value');
const _tick = Duration(milliseconds: 1);

/// A stepper bounded to 1…[max] that records what it receives.
class _Bounded extends StatefulWidget {
  const _Bounded({this.max = 200, this.onSubmitted});

  final int max;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_Bounded> createState() => _BoundedState();
}

class _BoundedState extends State<_Bounded> {
  var value = 20;

  @override
  Widget build(BuildContext context) => MxStepper(
    value: value,
    decrementLabel: 'Fewer cards',
    incrementLabel: 'More cards',
    valueLabel: 'Cards per session',
    editHint: 'Edit',
    onDecrement: value > 1 ? () => setState(() => value--) : null,
    onIncrement: value < widget.max ? () => setState(() => value++) : null,
    onValueSubmitted: widget.onSubmitted,
  );
}

int _value(WidgetTester tester) =>
    tester.state<_BoundedState>(find.byType(_Bounded)).value;

void main() {
  testWidgets('a tap steps once; a hold repeats after its delay, then at '
      'its interval, and stops on release', (tester) async {
    await pumpMx(tester, const _Bounded());
    await tester.tap(find.byTooltip('More cards'));
    expect(_value(tester), 21);

    final hold = await tester.startGesture(
      tester.getCenter(find.byTooltip('More cards')),
    );
    await tester.pump(mxStepperRepeatDelay - _tick);
    expect(_value(tester), 21);
    await tester.pump(_tick);
    expect(_value(tester), 22);
    await tester.pump(mxStepperRepeatInterval);
    await tester.pump(mxStepperRepeatInterval);
    expect(_value(tester), 24);

    await hold.up();
    await tester.pump(mxStepperRepeatDelay * 2);
    // Releasing a hold is not one more tap.
    expect(_value(tester), 24);
  });

  testWidgets('a hold that turns into a scroll never repeats', (tester) async {
    await pumpMx(tester, const _Bounded());
    final drag = await tester.startGesture(
      tester.getCenter(find.byTooltip('More cards')),
    );
    // Past touch slop: the finger is scrolling the page, not holding +.
    await drag.moveBy(const Offset(0, kTouchSlop * 2));
    await tester.pump(mxStepperRepeatDelay * 2);
    await drag.up();
    await tester.pump();

    expect(_value(tester), 20);
  });

  testWidgets('a hold stops at the bound the caller sets', (tester) async {
    await pumpMx(tester, const _Bounded(max: 22));
    final hold = await tester.startGesture(
      tester.getCenter(find.byTooltip('More cards')),
    );
    await tester.pump(mxStepperRepeatDelay);
    for (var i = 0; i < 5; i++) {
      await tester.pump(mxStepperRepeatInterval);
    }
    await hold.up();
    await tester.pump();

    expect(_value(tester), 22);
  });

  testWidgets('tapping the number types a value; Done submits it', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpMx(tester, _Bounded(onSubmitted: submitted.add));
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();

    await tester.enterText(find.byType(TextField), '150');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(submitted, ['150']);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the number being typed has no edge of its own: the box draws '
      'the one edge, and the theme\'s field edges do not reach it (M3F-16)', (
    tester,
  ) async {
    await pumpMx(tester, _Bounded(onSubmitted: (_) {}));
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();

    final decoration = tester
        .widget<InputDecorator>(find.byType(InputDecorator))
        .decoration;
    // The box's own accent hairline is the typing indicator, and the only
    // edge while typing.
    final box = tester.widget<DecoratedBox>(find.byKey(_valueKey));
    final edge = (box.decoration as BoxDecoration).border! as Border;
    expect(edge.top.color, accentOf(lightColorScheme));
    expect(edge.top.width, 1);
    expect(decoration.border, InputBorder.none);
    for (final border in [
      decoration.enabledBorder,
      decoration.focusedBorder,
      decoration.disabledBorder,
      decoration.errorBorder,
      decoration.focusedErrorBorder,
    ]) {
      expect(border, isNull);
    }
  });

  testWidgets('leaving the field submits what was typed; only digits go in', (
    tester,
  ) async {
    final submitted = <String>[];
    await pumpMx(tester, _Bounded(onSubmitted: submitted.add));
    await tester.tap(find.byKey(_valueKey));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '2a50');
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pump();

    expect(submitted, ['250']);
  });

  testWidgets('without onValueSubmitted the number cannot be typed', (
    tester,
  ) async {
    await pumpMx(tester, const _Bounded());
    await tester.tap(find.byKey(_valueKey), warnIfMissed: false);
    await tester.pump();

    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('the number is one TalkBack node: its name, its value and Edit', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(tester, _Bounded(onSubmitted: (_) {}));

    expect(
      tester.getSemantics(find.byKey(_valueKey)),
      matchesSemantics(
        label: 'Cards per session',
        value: '20',
        isButton: true,
        hasTapAction: true,
        onTapHint: 'Edit',
      ),
    );
    handle.dispose();
  });

  testWidgets('the editable number is a full touch target in a row', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    // As in a settings row: no height to fill, so the number sizes itself.
    await pumpMx(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [_Bounded(onSubmitted: (_) {})],
      ),
    );

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    handle.dispose();
  });

  // M3F-06: the number was a GestureDetector in a Semantics, so Tab skipped
  // it. It now takes keyboard focus with the shared 2px primary ring.
  for (final brightness in Brightness.values) {
    final focusScheme = brightness == Brightness.light
        ? lightColorScheme
        : darkColorScheme;
    testWidgets('M3F-06: Tab reaches the number, which draws the 2px primary '
        'ring and opens on Enter (${brightness.name})', (tester) async {
      await pumpMx(
        tester,
        _Bounded(onSubmitted: (_) {}),
        brightness: brightness,
      );
      useKeyboardFocusHighlight();
      expect(
        tester.renderObject(find.byKey(_valueKey)),
        isNot(paintsFocusRing(focusScheme.primary)),
      );

      await tabTo(tester, find.byKey(_valueKey));

      expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
      expect(focusedRender(tester), paintsFocusRing(focusScheme.primary));
      expect(find.byType(TextField), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);
    });
  }

  testWidgets('M3F-06: a number that cannot be edited takes no focus', (
    tester,
  ) async {
    await pumpMx(tester, const _Bounded());
    useKeyboardFocusHighlight();
    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        find.descendant(
          of: find.byElementPredicate(
            (e) => e == FocusManager.instance.primaryFocus?.context,
          ),
          matching: find.byKey(_valueKey),
        ),
        findsNothing,
      );
    }
  });
}
