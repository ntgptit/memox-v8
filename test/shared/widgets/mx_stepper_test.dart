import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/shared/widgets/mx_stepper.dart';

import 'support/mx_harness.dart';

class _Host extends StatefulWidget {
  const _Host({required this.start, this.minDigits = 1});

  final int start;
  final int minDigits;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.start;

  @override
  Widget build(BuildContext context) => MxStepper(
    value: value,
    min: 0,
    max: 23,
    minDigits: widget.minDigits,
    valueLabel: 'Hour',
    decreaseLabel: 'Earlier hour',
    increaseLabel: 'Later hour',
    onChanged: (v) => setState(() => value = v),
  );
}

void main() {
  testWidgets('+ and − step by one and stop at the bounds', (tester) async {
    await pumpMx(tester, const _Host(start: 22));
    await tester.tap(find.byTooltip('Later hour'));
    await tester.pump();
    expect(find.text('23'), findsOneWidget);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Earlier hour'));
    await tester.pump();
    expect(find.text('22'), findsOneWidget);
  });

  testWidgets('minDigits zero-pads the value', (tester) async {
    await pumpMx(tester, const _Host(start: 7, minDigits: 2));
    expect(find.text('07'), findsOneWidget);
  });

  testWidgets('holding + repeats until release', (tester) async {
    await pumpMx(tester, const _Host(start: 0));
    final TestGesture press = await tester.startGesture(
      tester.getCenter(find.byTooltip('Later hour')),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    await tester.pump(AppDurations.repeat * 3);
    await press.up();
    await tester.pump();
    final int reached = int.parse(
      tester.widget<Text>(find.textContaining(RegExp(r'^\d+$'))).data!,
    );
    expect(reached, greaterThanOrEqualTo(2));
    await tester.pump(AppDurations.repeat * 3);
    expect(find.text('$reached'), findsOneWidget);
  });

  testWidgets('it reads its value and offers increase and decrease', (
    tester,
  ) async {
    await pumpMx(tester, const _Host(start: 7, minDigits: 2));
    expect(
      tester.getSemantics(find.byType(MxStepper)),
      matchesSemantics(
        label: 'Hour',
        value: '07',
        increasedValue: '08',
        decreasedValue: '06',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
  });

  testWidgets('the buttons stay put as the digits change', (tester) async {
    await pumpMx(tester, const _Host(start: 9));
    final double plus = tester.getCenter(find.byTooltip('Later hour')).dx;
    await tester.tap(find.byTooltip('Later hour'));
    await tester.pump();
    expect(find.text('10'), findsOneWidget);
    expect(tester.getCenter(find.byTooltip('Later hour')).dx, plus);
  });
}
