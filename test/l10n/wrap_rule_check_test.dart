import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/wrap_rule.dart';

// The Wrap Rule's test check: it must fail on every break inside a glued
// term, wherever the engine puts it, or a glued line wider than its column
// passes (final review I-1).
Future<void> _pump(WidgetTester tester, String text, double width) =>
    tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(width: width, child: Text(text)),
        ),
      ),
    );

void main() {
  testWidgets('a glued term wider than its line fails, at every width', (
    tester,
  ) async {
    for (var width = 60.0; width <= 76; width += 2) {
      await _pump(tester, 'ab\u00A0cd\u00A0ef\u00A0gh\u00A0ij\u00A0kl', width);
      expect(
        () => expectBreaksOnlyBetweenWords(tester, find.byType(Text)),
        throwsA(isA<TestFailure>()),
        reason: 'width $width',
      );
    }
  });

  testWidgets('a line of whole terms that breaks between them passes', (
    tester,
  ) async {
    await _pump(tester, 'ab\u00A0cd\u00A0· ef\u00A0gh\u00A0· ij\u00A0kl', 400);
    expectBreaksOnlyBetweenWords(tester, find.byType(Text));
  });
}
