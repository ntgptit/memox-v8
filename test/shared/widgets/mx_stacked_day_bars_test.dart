import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_stacked_day_bars.dart';

import '../../support/widget_harness.dart';

// FE-A9 D6: kit 22's seven stacked day bars.

const _learning = MxBarSeries(label: 'Learning', color: Colors.orange);
const _reviewing = MxBarSeries(label: 'Reviewing', color: Colors.indigo);

MxDayBar _day(String label, int reviewing, int learning, {bool now = false}) =>
    MxDayBar(
      label: label,
      base: reviewing,
      top: learning,
      semanticLabel: '$label: ${reviewing + learning} cards',
      isCurrent: now,
    );

Widget _chart(List<MxDayBar> days) => SizedBox(
  width: 300,
  child: MxStackedDayBars(days: days, base: _reviewing, top: _learning),
);

double _height(WidgetTester tester, Color color) => tester
    .getSize(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).shape == BoxShape.rectangle &&
            (widget.decoration! as BoxDecoration).color?.toARGB32() ==
                color.toARGB32(),
      ),
    )
    .height;

void main() {
  testWidgets('the fullest day fills the chart; the rest scale to it', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _chart([_day('M', 10, 0), _day('Today', 12, 8, now: true)]),
    );

    // Today: 8 learning over 12 reviewing fill the 78 of the chart.
    expect(_height(tester, _learning.color), closeTo(8 * 78 / 20, 0.01));
    expect(_height(tester, _reviewing.color), closeTo(12 * 78 / 20, 0.01));
    // Monday's reviewing is faded, and half of Today's 20.
    expect(
      _height(tester, _reviewing.color.withValues(alpha: 0.55)),
      closeTo(10 * 78 / 20, 0.01),
    );
  });

  testWidgets('a day with nothing is a 2-high baseline', (tester) async {
    await pumpMx(tester, _chart([_day('F', 0, 0), _day('S', 3, 0)]));
    final baseline = find.byWidgetPredicate(
      (widget) => widget is Container && widget.constraints?.maxHeight == 2,
    );

    expect(baseline, findsOneWidget);
  });

  testWidgets('each bar is one TalkBack node; labels and legend say nothing '
      'more', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      _chart([_day('S', 3, 1), _day('Today', 0, 2, now: true)]),
    );

    expect(find.bySemanticsLabel('S: 4 cards'), findsOneWidget);
    expect(find.bySemanticsLabel('Today: 2 cards'), findsOneWidget);
    expect(find.bySemanticsLabel('Learning'), findsNothing);
    expect(find.bySemanticsLabel('Reviewing'), findsNothing);
    handle.dispose();
  });

  testWidgets('the current day is labelled in bold', (tester) async {
    await pumpMx(
      tester,
      _chart([_day('S', 1, 0), _day('Today', 1, 0, now: true)]),
    );

    expect(
      tester.widget<Text>(find.text('Today')).style!.fontWeight,
      FontWeight.w700,
    );
    expect(
      tester.widget<Text>(find.text('S')).style!.fontWeight,
      FontWeight.w400,
    );
  });
}
