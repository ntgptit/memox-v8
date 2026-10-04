import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a trigger opens what it names and shows a chevron', (
    tester,
  ) async {
    var opened = 0;
    await pumpMx(
      tester,
      MxChipTrigger(label: 'Manual', onOpen: () => opened++),
    );
    await tester.tap(find.text('Manual'));
    expect(opened, 1);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}
