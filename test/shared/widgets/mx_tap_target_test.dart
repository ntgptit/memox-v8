import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/primitives/mx_tap_target.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('MxTapTarget grows a small child to 48 and centres it', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const MxTapTarget(child: SizedBox.square(dimension: 20)),
    );
    expect(
      tester.getSize(find.byType(MxTapTarget)),
      const Size.square(AppSize.tapTarget),
    );
  });

  testWidgets('a touch in the padding reaches the small child', (tester) async {
    var taps = 0;
    await pumpMx(
      tester,
      MxTapTarget(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => taps++,
          child: const SizedBox.square(dimension: 20),
        ),
      ),
    );
    final Rect box = tester.getRect(find.byType(MxTapTarget));
    await tester.tapAt(box.topLeft + const Offset(1, 1));
    await tester.tapAt(box.bottomRight - const Offset(1, 1));
    expect(taps, 2);
    await tester.tapAt(box.topLeft - const Offset(4, 4));
    expect(taps, 2);
  });
}
