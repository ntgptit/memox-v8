import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/primitives/mx_focus_ring.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('MxFocusRing paints only when it is told to', (tester) async {
    Finder ring() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.foregroundPainter != null,
    );
    await pumpMx(
      tester,
      const MxFocusRing(
        borderRadius: BorderRadius.zero,
        isShown: true,
        child: SizedBox.square(dimension: 20),
      ),
    );
    expect(ring(), findsOneWidget);
    await pumpMx(
      tester,
      const MxFocusRing(
        borderRadius: BorderRadius.zero,
        isShown: false,
        child: SizedBox.square(dimension: 20),
      ),
    );
    expect(ring(), findsNothing);
  });

  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    testWidgets('$name: the ring is the Indigo Accent, never primary', (
      tester,
    ) async {
      await pumpMx(
        tester,
        const MxFocusRing(
          borderRadius: BorderRadius.zero,
          isShown: true,
          child: SizedBox.square(dimension: 20),
        ),
        theme: theme,
      );
      expect(
        find.byType(MxFocusRing),
        paints..rrect(color: theme.colorScheme.onPrimaryContainer),
      );
    });
  }
}
