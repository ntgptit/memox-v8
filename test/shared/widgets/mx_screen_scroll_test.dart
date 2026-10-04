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

  testWidgets('16 gutter; base tail 24 + inset', (tester) async {
    await pumpMxPage(
      tester,
      Scaffold(body: MxScreenScroll(children: rows)),
      padding: const EdgeInsets.only(bottom: 20),
    );
    final padding = _padding(tester);

    expect(padding.left, 16);
    expect(padding.right, 16);
    expect(padding.bottom, 24 + 20);
  });

  testWidgets('FAB tail: 24 + 52 + 24 + inset', (tester) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: MxScreenScroll(clearance: MxScrollClearance.fab, children: rows),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );

    expect(_padding(tester).bottom, 24 + 52 + 24 + 20);
  });

  testWidgets('FAB above nav tail: 4 + 52 + 24 + inset', (tester) async {
    await pumpMxPage(
      tester,
      Scaffold(
        body: MxScreenScroll(
          clearance: MxScrollClearance.fabAboveNav,
          children: rows,
        ),
      ),
      padding: const EdgeInsets.only(bottom: 20),
    );

    expect(_padding(tester).bottom, 4 + 52 + 24 + 20);
  });
}
