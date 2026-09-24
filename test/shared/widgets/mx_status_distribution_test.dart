import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_status_badge.dart';
import 'package:memox/shared/widgets/mx_status_distribution.dart';

import '../../support/widget_harness.dart';

const _counts = MxStatusCounts(
  newCards: 100,
  learning: 140,
  reviewing: 100,
  mastered: 80,
);

String _label(MxCardStatus status) => status.name;

Finder _segment(MxCardStatus status) =>
    find.byKey(ValueKey(('segment', status)));

void main() {
  testWidgets('segments share the width by count; the legend names each', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 420,
        child: MxStatusDistribution(counts: _counts, label: _label),
      ),
    );
    final widths = [
      for (final status in MxCardStatus.values)
        tester.getSize(_segment(status)).width,
    ];

    expect(widths[0], closeTo(widths[2], 0.5));
    expect(widths[1], greaterThan(widths[0]));
    for (final status in MxCardStatus.values) {
      expect(find.text(status.name), findsOneWidget);
    }
    expect(find.text('140'), findsOneWidget);
  });

  testWidgets('an empty deck draws the track alone, no division by zero', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxStatusDistribution(
          counts: MxStatusCounts(
            newCards: 0,
            learning: 0,
            reviewing: 0,
            mastered: 0,
          ),
          label: _label,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(_segment(MxCardStatus.newCard), findsNothing);
  });

  testWidgets('a status with no card draws no segment', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: MxStatusDistribution(
          counts: MxStatusCounts(
            newCards: 3,
            learning: 0,
            reviewing: 0,
            mastered: 0,
          ),
          label: _label,
        ),
      ),
    );

    expect(_segment(MxCardStatus.learning), findsNothing);
    expect(_segment(MxCardStatus.newCard), findsOneWidget);
  });
}
