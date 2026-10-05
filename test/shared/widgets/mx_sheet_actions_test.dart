import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/mx_derived_colors.dart';
import 'package:memox/core/theme/mx_semantic_colors.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/widget_harness.dart';

Finder _button(String label) => find.widgetWithText(MxButton, label);

Widget _width(Widget child) => SizedBox(width: 340, child: child);

void main() {
  testWidgets('cancel outline at 1 share, confirm primary at 1.3; 20 at the '
      'sides, 16 on top (DEV-166)', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
        ),
      ),
    );
    // 340 − 20 − 20 − 8 = 292, split 10 : 13.
    expect(
      tester.getSize(_button('Cancel')).width,
      closeTo(292 * 10 / 23, 0.01),
    );
    expect(tester.getSize(_button('Move')).width, closeTo(292 * 13 / 23, 0.01));
    expect(
      tester.widget<MxButton>(_button('Cancel')).tone,
      MxButtonTone.outline,
    );
    expect(tester.widget<MxButton>(_button('Move')).tone, MxButtonTone.primary);
    expect(
      tester.getTopLeft(_button('Cancel')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(20, 16),
    );
  });

  testWidgets(
    'a loading confirm spins and cannot be pressed; Cancel stays live',
    (tester) async {
      var cancelled = 0;
      await pumpMx(
        tester,
        _width(
          MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () => cancelled++,
            confirmLabel: 'Preparing',
            onConfirm: () {},
            isConfirmLoading: true,
          ),
        ),
      );

      expect(tester.widget<MxButton>(_button('Preparing')).isLoading, isTrue);
      await tester.tap(_button('Cancel'));
      expect(cancelled, 1);
    },
  );

  testWidgets('a destructive confirm, with its glyph passed through', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Delete',
          onConfirm: () {},
          confirmIcon: AppIcons.delete,
          isDestructive: true,
        ),
      ),
    );
    final confirm = tester.widget<MxButton>(_button('Delete'));

    expect(
      (confirm.tone, confirm.icon),
      (MxButtonTone.destructive, AppIcons.delete),
    );
  });

  testWidgets('a warning confirm, for a merge (spec D15)', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Merge tags',
          onConfirm: () {},
          isWarning: true,
        ),
      ),
    );

    expect(
      tester.widget<MxButton>(_button('Merge tags')).tone,
      MxButtonTone.warning,
    );
  });

  testWidgets('a null Cancel is disabled while the confirm runs', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: null,
          confirmLabel: 'Add deck',
          onConfirm: () {},
          isConfirmLoading: true,
        ),
      ),
    );

    expect(tester.widget<MxButton>(_button('Cancel')).onPressed, isNull);
  });

  testWidgets('a disabled confirm leaves Cancel live (RF3)', (tester) async {
    var cancels = 0;
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () => cancels++,
          confirmLabel: 'Move',
          onConfirm: null,
        ),
      ),
    );

    expect(tester.widget<MxButton>(_button('Move')).onPressed, isNull);
    await tester.tap(_button('Cancel'));
    expect(cancels, 1);
  });

  testWidgets('in a sheet: a ghost rule on top, then 8 16 16', (tester) async {
    final ghost = MxDerivedColors.resolve(
      AppColorSchemes.light,
      MxSemanticColors.light,
    ).ghostBorder;
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
          isInSheet: true,
        ),
      ),
    );
    final edge =
        (tester
                        .widget<DecoratedBox>(
                          find
                              .descendant(
                                of: find.byType(MxSheetActions),
                                matching: find.byType(DecoratedBox),
                              )
                              .first,
                        )
                        .decoration
                    as BoxDecoration)
                .border!
            as Border;

    expect(edge.top, BorderSide(color: ghost));
    expect(
      tester.getTopLeft(_button('Cancel')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(16, 8),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSheetActions)).dy -
          tester.getBottomLeft(_button('Cancel')).dy,
      16,
    );
  });

  testWidgets('custom children replace the pair', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions.custom(
          children: [
            Expanded(
              child: MxButton(label: 'OK', onPressed: () {}),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(MxButton), findsOneWidget);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('labels too long for their shares stack the pair', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Giữ lại tất cả',
          onCancel: () {},
          confirmLabel: 'Xoá vĩnh viễn 12 thẻ',
          confirmIcon: Icons.delete,
          isDestructive: true,
          onConfirm: () {},
        ),
      ),
    );
    final cancel = tester.getRect(_button('Giữ lại tất cả'));
    final confirm = tester.getRect(_button('Xoá vĩnh viễn 12 thẻ'));

    expect(confirm.top, greaterThan(cancel.bottom));
    expect(cancel.width, confirm.width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an even split gives Cancel and the confirm one width and one '
      'height (2026-10-05 L2)', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Continue',
          onConfirm: () {},
          isEvenSplit: true,
        ),
      ),
    );
    final cancel = tester.getSize(_button('Cancel'));
    final confirm = tester.getSize(_button('Continue'));
    expect(cancel.width, confirm.width);
    expect(cancel.height, confirm.height);
  });

  testWidgets('an even split stacks a label too long for its half, both '
      'full width', (tester) async {
    const long = 'Discard and continue with everything';
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: long,
          onConfirm: () {},
          isEvenSplit: true,
        ),
      ),
    );
    final cancel = tester.getRect(_button('Cancel'));
    final confirm = tester.getRect(_button(long));
    expect(cancel.width, confirm.width);
    expect(cancel.top, lessThan(confirm.top));
  });

  testWidgets('a dialog pair ends 20 above the dialog edge (DEV-166)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
        ),
      ),
    );
    expect(
      tester.getBottomLeft(find.byType(MxSheetActions)).dy -
          tester.getBottomLeft(_button('Cancel')).dy,
      20,
    );
  });

  testWidgets('a custom footer in a dialog takes the same insets (DEV-166)', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions.custom(
          children: [
            Expanded(
              child: MxButton(label: 'OK', isBlock: true, onPressed: () {}),
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(_button('OK')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(20, 16),
    );
  });

  testWidgets('a stacked dialog pair keeps the 20 side insets (DEV-166)', (
    tester,
  ) async {
    const long = 'Discard everything on this phone and continue';
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: long,
          onConfirm: () {},
        ),
      ),
    );
    final box = tester.getRect(find.byType(MxSheetActions));
    final cancel = tester.getRect(_button('Cancel'));
    final confirm = tester.getRect(_button(long));
    expect(confirm.top, greaterThan(cancel.bottom), reason: 'stacked');
    for (final button in [cancel, confirm]) {
      expect(button.left - box.left, 20);
      expect(box.right - button.right, 20);
    }
  });
}
