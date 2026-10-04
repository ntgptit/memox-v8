import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_study_top_bar.dart';

import '../../support/widget_harness.dart';

MxStudyTopBar _bar({int current = 3, int total = 10}) => MxStudyTopBar(
  modeLabel: 'Review',
  current: current,
  total: total,
  counterLabel: '$current / $total',
  closeLabel: 'Close session',
  onClose: () {},
);

double _fill(WidgetTester tester) => tester
    .widget<FractionallySizedBox>(find.byType(FractionallySizedBox))
    .widthFactor!;

void main() {
  testWidgets('fill is current/total; the counter shows the caller label', (
    tester,
  ) async {
    await pumpMx(tester, _bar());
    await tester.pumpAndSettle();

    expect(_fill(tester), 0.3);
    expect(find.text('3 / 10'), findsOneWidget);
  });

  testWidgets('the badge is the mode label upper-cased', (tester) async {
    await pumpMx(tester, _bar());

    expect(find.text('REVIEW'), findsOneWidget);
  });

  testWidgets(
    'the fill is primary, in every mode (critique 2026-09-30 part 3c-2, R8)',
    (tester) async {
      Color fillColor() => tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byType(FractionallySizedBox),
              matching: find.byType(ColoredBox),
            ),
          )
          .color;

      await pumpMx(tester, _bar());
      expect(fillColor(), AppColorSchemes.light.primary);
    },
  );

  testWidgets('the track is progress-track (R6)', (tester) async {
    await pumpMx(tester, _bar());
    final track = tester.widget<ColoredBox>(
      find
          .ancestor(
            of: find.byType(FractionallySizedBox),
            matching: find.byType(ColoredBox),
          )
          .first,
    );

    expect(track.color, AppColorSchemes.light.surfaceContainerLow);
  });

  testWidgets('the fill animates over 200ms unless motion is reduced', (
    tester,
  ) async {
    await pumpMx(tester, _bar(current: 1));
    await pumpMx(tester, _bar(current: 5));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_fill(tester), inExclusiveRange(0.1, 0.5));
    await tester.pumpAndSettle();

    Widget reduced(int current) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: _bar(current: current)),
      ),
    );
    await tester.pumpWidget(reduced(1));
    await tester.pumpWidget(reduced(9));
    await tester.pump();
    expect(_fill(tester), 0.9);
  });

  testWidgets('close is a labelled 48 target that fires onClose', (
    tester,
  ) async {
    var closed = 0;
    await pumpMx(
      tester,
      MxStudyTopBar(
        modeLabel: 'Review',
        current: 1,
        total: 2,
        counterLabel: '1 / 2',
        closeLabel: 'Close session',
        onClose: () => closed++,
      ),
    );
    await tester.tap(find.byTooltip('Close session'));

    expect(closed, 1);
    await expectAccessibleTargets(tester);
  });

  test('current outside [1, total] or an empty session is rejected', () {
    expect(() => _bar(current: 0), throwsAssertionError);
    expect(() => _bar(current: 11), throwsAssertionError);
    expect(() => _bar(current: 1, total: 0), throwsAssertionError);
  });
}
