import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('22 on its own line, 18 dense', (tester) async {
    await pumpMx(tester, const MxTagChip(label: 'verbs'));
    expect(tester.getSize(find.byType(MxTagChip)).height, AppSize.tagChip);
    await pumpMx(tester, const MxTagChip(label: 'verbs', isDense: true));
    expect(tester.getSize(find.byType(MxTagChip)).height, AppSize.tagChipDense);
  });

  testWidgets('a long name stops at half its row and is read whole', (
    tester,
  ) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    const String name = 'irregular verbs of the past tense, chapter twelve';
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: MxTagChip(label: name),
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(DecoratedBox).last).width,
      lessThanOrEqualTo(150),
    );
    expect(
      tester.getSemantics(find.byType(MxTagChip)),
      isSemantics(label: name),
    );
    semantics.dispose();
  });
}
