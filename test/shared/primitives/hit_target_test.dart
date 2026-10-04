import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/generated/design_values.dart';
import 'package:memox/shared/primitives/hit_target.dart';

import '../../support/design_system_harness.dart';

void main() {
  testWidgets('a 28 dp control takes 48×48 and a tap at its edge lands', (
    tester,
  ) async {
    var taps = 0;
    await pumpDesignSystem(
      tester,
      HitTarget(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox(width: 28, height: 28),
        ),
      ),
    );

    final box = tester.getRect(find.byType(HitTarget));
    expect(box.size, const Size(AppSize.touchTarget, AppSize.touchTarget));

    await tester.tapAt(box.topLeft + const Offset(2, 2));
    expect(taps, 1);

    await tester.tapAt(box.topLeft - const Offset(4, 4));
    expect(taps, 1, reason: 'a tap outside the 48 dp area is not the control');
  });

  testWidgets('a control already 48 or larger keeps its size', (tester) async {
    await pumpDesignSystem(
      tester,
      const HitTarget(child: SizedBox(width: 120, height: 56)),
    );

    expect(tester.getSize(find.byType(HitTarget)), const Size(120, 56));
  });
}
