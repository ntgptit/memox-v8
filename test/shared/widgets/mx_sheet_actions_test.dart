import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_color_schemes.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/widget_harness.dart';

Finder _button(String label) => find.widgetWithText(MxButton, label);

Widget _width(Widget child) => SizedBox(width: 340, child: child);

void main() {
  testWidgets('cancel outline at 1 share, confirm primary at 1.3; 16 inset', (
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
    // 340 − 16 − 16 − 8 = 300, split 1 : 1 (DEV-179).
    expect(tester.getSize(_button('Cancel')).width, closeTo(150, 0.01));
    expect(tester.getSize(_button('Move')).width, closeTo(150, 0.01));
    expect(
      tester.widget<MxButton>(_button('Cancel')).tone,
      MxButtonTone.outline,
    );
    expect(tester.widget<MxButton>(_button('Move')).tone, MxButtonTone.primary);
    expect(
      tester.getTopLeft(_button('Cancel')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(16, 16),
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

  testWidgets('a destructive confirm, without a glyph (DEV-179)', (
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
          isDestructive: true,
        ),
      ),
    );
    final confirm = tester.widget<MxButton>(_button('Delete'));

    // A popup's buttons carry no icon; the tone tells the weight (DEV-179).
    expect((confirm.tone, confirm.icon), (MxButtonTone.destructive, null));
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
    // The outline tone never sits on a container; the text tone reads
    // primaryForeground on the warning container.
    expect(tester.widget<MxButton>(_button('Cancel')).tone, MxButtonTone.text);
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

  testWidgets('in a sheet: an outlineVariant rule on top, then 8 16 16', (
    tester,
  ) async {
    final ghost = AppColorSchemes.light.outlineVariant;
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

  testWidgets('at a larger text scale labels too long for their shares '
      'stack the pair', (tester) async {
    await pumpMx(
      tester,
      _width(
        MxSheetActions(
          cancelLabel: 'Giữ lại tất cả',
          onCancel: () {},
          confirmLabel: 'Xoá vĩnh viễn 12 thẻ',
          isDestructive: true,
          onConfirm: () {},
        ),
      ),
      textScale: 1.3,
    );
    final cancel = tester.getRect(_button('Giữ lại tất cả'));
    final confirm = tester.getRect(_button('Xoá vĩnh viễn 12 thẻ'));

    expect(confirm.top, greaterThan(cancel.bottom));
    expect(cancel.width, confirm.width);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cancel and the confirm share one width and one height '
      '(DEV-179)', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Continue',
          onConfirm: () {},
        ),
      ),
    );
    final cancel = tester.getSize(_button('Cancel'));
    final confirm = tester.getSize(_button('Continue'));
    expect(cancel.width, confirm.width);
    expect(cancel.height, confirm.height);
  });

  testWidgets('at a larger text scale the pair stacks a label too long '
      'for its half, both full width (The Short Label Rule)', (tester) async {
    const long = 'Discard and continue with everything';
    await pumpMx(
      tester,
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: SizedBox(
          width: 328,
          child: MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () {},
            confirmLabel: long,
            onConfirm: () {},
          ),
        ),
      ),
    );
    final cancel = tester.getRect(_button('Cancel'));
    final confirm = tester.getRect(_button(long));
    expect(cancel.width, confirm.width);
    expect(cancel.top, lessThan(confirm.top));
  });

  // SW-REV-008: one action (a lone Close, Done, OK) spans the row in the
  // footer's own padding, without each caller rebuilding the row.
  testWidgets('single: one block button in its tone, the sheet form kept', (
    tester,
  ) async {
    var taps = 0;
    await pumpMx(
      tester,
      _width(
        MxSheetActions.single(
          label: 'Done',
          onPressed: () => taps++,
          isInSheet: true,
        ),
      ),
    );
    final button = tester.widget<MxButton>(_button('Done'));
    expect(button.tone, MxButtonTone.primary);
    expect(button.isBlock, isTrue);
    expect(tester.getSize(_button('Done')).width, 340 - 2 * 16);
    expect(
      tester.getTopLeft(_button('Done')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(16, 8),
    );
    await tester.tap(_button('Done'));
    expect(taps, 1);

    await pumpMx(
      tester,
      _width(
        const MxSheetActions.single(
          label: 'Cancel',
          onPressed: null,
          tone: MxButtonTone.outline,
        ),
      ),
    );
    expect(tester.widget<MxButton>(_button('Cancel')).onPressed, isNull);
    expect(
      tester.widget<MxButton>(_button('Cancel')).tone,
      MxButtonTone.outline,
    );
  });
}
