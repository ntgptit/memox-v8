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
}
