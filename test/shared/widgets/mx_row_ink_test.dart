import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/primitives/mx_row_ink.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('MxRowInk taps, and does nothing without onTap', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxRowInk(onTap: () => taps++, child: const Text('Row')),
    );
    await tester.tap(find.text('Row'));
    expect(taps, 1);
    await pumpMx(tester, const MxRowInk(onTap: null, child: Text('Row')));
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
