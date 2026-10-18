import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

import '../../support/widget_harness.dart';

EdgeInsets _padding(WidgetTester tester) => tester
    .widget<ListView>(find.byType(ListView))
    .padding!
    .resolve(TextDirection.ltr);

void main() {
  final rows = [
    for (var i = 0; i < 3; i++) SizedBox(height: 40, key: Key('$i')),
  ];

  // A null clearance is the widget's default (the base tail).
  for (final (name, clearance, tail) in <(String, MxScrollClearance?, double)>[
    ('16 gutter; base tail 24 + inset', null, 24),
    ('FAB tail: 24 + 56 + 24 + inset', MxScrollClearance.fab, 24 + 56 + 24),
    (
      'FAB above nav tail: 4 + 56 + 24 + inset',
      MxScrollClearance.fabAboveNav,
      4 + 56 + 24,
    ),
  ]) {
    testWidgets(name, (tester) async {
      await pumpMxPage(
        tester,
        Scaffold(
          body: clearance == null
              ? MxScreenScroll(children: rows)
              : MxScreenScroll(clearance: clearance, children: rows),
        ),
        padding: const EdgeInsets.only(bottom: 20),
      );
      final padding = _padding(tester);

      expect(padding.left, 16);
      expect(padding.right, 16);
      expect(padding.bottom, tail + 20);
    });
  }
}
