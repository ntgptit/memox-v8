import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

Widget _footer(String confirm, {double width = 328}) => SizedBox(
  width: width,
  child: MxSheetActions(
    cancelLabel: 'Cancel',
    onCancel: () {},
    confirmLabel: confirm,
    onConfirm: () {},
  ),
);

void main() {
  testWidgets('short labels share the row equally, the confirm trailing', (
    tester,
  ) async {
    await pumpMx(tester, _footer('Save'));
    final Rect cancel = tester.getRect(find.byType(MxButton).first);
    final Rect confirm = tester.getRect(find.byType(MxButton).last);
    expect(cancel.width, confirm.width);
    expect(cancel.top, confirm.top);
    expect(confirm.left, greaterThan(cancel.left));
    expect(
      tester.widget<MxButton>(find.byType(MxButton).first).tone,
      MxButtonTone.outline,
    );
  });

  testWidgets('a label that would wrap stacks them, the confirm on top', (
    tester,
  ) async {
    await pumpMx(tester, _footer('Move everything to Trash for good'));
    final Rect top = tester.getRect(
      find.text('Move everything to Trash for good'),
    );
    final Rect bottom = tester.getRect(find.text('Cancel'));
    expect(top.top, lessThan(bottom.top));
    expect(tester.getSize(find.byType(MxButton).first).width, 328);
  });

  testWidgets('a lone confirm spans the row', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(confirmLabel: 'Done', onConfirm: () {}),
      ),
    );
    expect(tester.getSize(find.byType(MxButton)).width, 328);
  });

  testWidgets('the tone sets the confirm; loading blocks it', (tester) async {
    var confirmed = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: MxSheetActions(
          confirmLabel: 'Delete',
          onConfirm: () => confirmed++,
          tone: MxSheetActionsTone.destructive,
          isConfirmLoading: true,
        ),
      ),
    );
    final MxButton button = tester.widget(find.byType(MxButton));
    expect(button.tone, MxButtonTone.destructive);
    expect(button.isLoading, isTrue);
    await tester.tap(find.byType(MxButton));
    expect(confirmed, 0);
  });

  testWidgets('in a sheet it sits under a hairline on the gutter', (
    tester,
  ) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 320,
        child: MxSheetActions(
          confirmLabel: 'Done',
          onConfirm: () {},
          isInSheet: true,
        ),
      ),
    );
    final BoxDecoration box =
        tester.widget<DecoratedBox>(find.byType(DecoratedBox).first).decoration
            as BoxDecoration;
    expect(
      box.border!.top.color,
      mxThemes['light']!.colorScheme.outlineVariant,
    );
    expect(
      tester.getTopLeft(find.byType(MxButton)).dx -
          tester.getTopLeft(find.byType(MxSheetActions)).dx,
      AppSpacing.gutter,
    );
  });
}
