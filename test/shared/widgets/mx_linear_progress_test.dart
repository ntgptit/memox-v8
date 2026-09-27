import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_linear_progress.dart';

import '../../support/widget_harness.dart';

// FE-A8 H2: the themed track that 13's Resume card and 14's resume banner
// draw; decorative (S7).

void main() {
  testWidgets('the fill is the value, and the track says nothing of its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpMx(
      tester,
      const SizedBox(width: 200, child: MxLinearProgress(value: 0.6)),
    );
    await tester.pumpAndSettle();

    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.6);
    expect(tester.getSize(find.byType(MxLinearProgress)).height, 4);
    // No node of its own: the whole track sits under ExcludeSemantics.
    expect(
      find.descendant(
        of: find.byType(MxLinearProgress),
        matching: find.byType(ExcludeSemantics),
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  test('a value outside 0 to 1 is a programming error', () {
    expect(() => MxLinearProgress(value: 1.2), throwsAssertionError);
  });
}
