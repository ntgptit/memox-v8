import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('24 on its own line, 20 dense', (tester) async {
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

  testWidgets('it lays out inside an intrinsic-height row', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: Text('Spanish')),
              MxTagChip(label: 'verbs'),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(MxTagChip)).height, AppSize.tagChip);
  });

  testWidgets('in a row it stops at half the width it is given', (
    tester,
  ) async {
    const String name = 'irregular verbs of the past tense, chapter twelve';
    await pumpMx(
      tester,
      const SizedBox(
        width: 300,
        child: Row(
          children: [Flexible(child: MxTagChip(label: name))],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(MxTagChip)).width,
      lessThanOrEqualTo(150),
    );
  });

  testWidgets('with no width bound it stops at half the window', (
    tester,
  ) async {
    const String name =
        'irregular verbs of the past tense, chapter twelve, part two, '
        'with the exceptions that every learner trips over at least once';
    await pumpMx(tester, const UnconstrainedBox(child: MxTagChip(label: name)));
    final double window =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(
      tester.getSize(find.byType(MxTagChip)).width,
      lessThanOrEqualTo(window / 2),
    );
  });
}
