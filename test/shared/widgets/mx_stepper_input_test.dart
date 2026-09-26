import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

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
    await tester.pump(AppDurations.stepperRepeatDelay - _tick);
    expect(_value(tester), 21);
    await tester.pump(_tick);
    expect(_value(tester), 22);
    await tester.pump(AppDurations.stepperRepeatInterval);
    await tester.pump(AppDurations.stepperRepeatInterval);
    expect(_value(tester), 24);

    await hold.up();
    await tester.pump(AppDurations.stepperRepeatDelay * 2);
    // Releasing a hold is not one more tap.
    expect(_value(tester), 24);
  });

  testWidgets('a hold stops at the bound the caller sets', (tester) async {
    await pumpMx(tester, const _Bounded(max: 22));
    final hold = await tester.startGesture(
      tester.getCenter(find.byTooltip('More cards')),
    );
    await tester.pump(AppDurations.stepperRepeatDelay);
    for (var i = 0; i < 5; i++) {
      await tester.pump(AppDurations.stepperRepeatInterval);
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
}
