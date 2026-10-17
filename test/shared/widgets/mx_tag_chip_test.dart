import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../support/forui_expect.dart';
import '../../support/widget_harness.dart';

void main() {
  final colors = appLightColors;

  testWidgets('22 default, 18 dense; secondary ground, muted label', (
    tester,
  ) async {
    await pumpMx(tester, const MxTagChip(label: 'verbs'));
    final box = paintedDecoration(tester, find.byType(MxTagChip));

    expect(tester.getSize(find.byType(MxTagChip)).height, 22);
    expect(box.color, colors.secondary);
    expect(
      box.shape,
      RoundedSuperellipseBorder(
        borderRadius: forUiTheme(
          tester,
          find.byType(MxTagChip),
        ).style.borderRadius.pill,
      ),
    );
    expect(textColor(tester, find.text('verbs')), colors.mutedForeground);
    expect(
      tester.getTopLeft(find.text('verbs')).dx -
          tester.getTopLeft(find.byType(MxTagChip)).dx,
      8,
    );

    await pumpMx(tester, const MxTagChip(label: 'verbs', isDense: true));
    expect(tester.getSize(find.byType(MxTagChip)).height, 18);
  });

  testWidgets('a long tag stops at 140 with an ellipsis', (tester) async {
    const long = 'a tag long enough to push the row past its width';
    await pumpMx(tester, const MxTagChip(label: long));

    expect(tester.getSize(find.byType(MxTagChip)).width, 140);
    expect(
      tester.widget<Text>(find.text(long)).overflow,
      TextOverflow.ellipsis,
    );
    // An ellipsized paragraph clips to its box: at line-height 1 the box is
    // the 12px em and the descenders of g, p, y are cut.
    expect(tester.getSize(find.text(long)).height, greaterThan(12));

    await pumpMx(tester, const MxTagChip(label: 'N5'));
    expect(tester.getSize(find.byType(MxTagChip)).width, lessThan(140));
  });
}
