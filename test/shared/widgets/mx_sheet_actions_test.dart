import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import '../../support/widget_harness.dart';

Finder _button(String label) => find.widgetWithText(MxButton, label);

Widget _width(Widget child) => SizedBox(width: 340, child: child);

void main() {
  testWidgets('cancel outline at 1 share, confirm primary at 1.3; 24 inset', (
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
    // 340 − 24 − 24 − 8 = 284, split 1 : 1 (DEV-179).
    expect(tester.getSize(_button('Cancel')).width, closeTo(142, 0.01));
    expect(tester.getSize(_button('Move')).width, closeTo(142, 0.01));
    // Both share one height too.
    expect(
      tester.getSize(_button('Cancel')).height,
      tester.getSize(_button('Move')).height,
    );
    expect(
      tester.widget<MxButton>(_button('Cancel')).tone,
      MxButtonTone.outline,
    );
    expect(tester.widget<MxButton>(_button('Move')).tone, MxButtonTone.primary);
    expect(
      tester.getTopLeft(_button('Cancel')) -
          tester.getTopLeft(find.byType(MxSheetActions)),
      const Offset(24, 0),
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
      await tester.pump(const Duration(milliseconds: 200));
      expect(cancelled, 1);
      // The spinner keeps turning; take it off before the test ends.
      await tester.pumpWidget(const SizedBox());
    },
  );

  // A popup's buttons carry no icon; the tone tells the weight (DEV-179).
  for (final (name, label, isDestructive, isWarning, tone) in [
    (
      'a destructive confirm, without a glyph (DEV-179)',
      'Delete',
      true,
      false,
      MxButtonTone.destructive,
    ),
    (
      'a warning confirm, for a merge, without a glyph (spec D15)',
      'Merge tags',
      false,
      true,
      MxButtonTone.warning,
    ),
  ]) {
    testWidgets(name, (tester) async {
      await pumpMx(
        tester,
        _width(
          MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () {},
            confirmLabel: label,
            onConfirm: () {},
            isDestructive: isDestructive,
            isWarning: isWarning,
          ),
        ),
      );
      final confirm = tester.widget<MxButton>(_button(label));

      expect((confirm.tone, confirm.icon), (tone, null));
    });
  }

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
    await tester.pumpAndSettle();
    expect(cancels, 1);
  });

  testWidgets('in a sheet: a divider rule on top, then 8 16 16', (
    tester,
  ) async {
    final rule = appLightColors.border;
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
    final divider = find.descendant(
      of: find.byType(MxSheetActions),
      matching: find.byType(FDivider),
    );
    final context = tester.element(find.byType(MxSheetActions));
    final origin = tester.getTopLeft(find.byType(MxSheetActions));

    expect(
      tester
          .widget<ColoredBox>(
            find.descendant(of: divider, matching: find.byType(ColoredBox)),
          )
          .color,
      rule,
    );
    expect(
      tester.getRect(divider),
      Rect.fromLTWH(
        origin.dx,
        origin.dy,
        tester.getSize(find.byType(MxSheetActions)).width,
        context.hairline,
      ),
    );
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

  // The Short Label Rule: a label too long for its share stacks the pair,
  // both full width, whichever of the two is long.
  for (final (cancelLabel, confirmLabel, isDestructive, width) in [
    ('Giữ lại tất cả', 'Xoá vĩnh viễn 12 thẻ', true, 340.0),
    ('Cancel', 'Discard and continue with everything', false, 328.0),
  ]) {
    testWidgets('at a larger text scale labels too long for their shares '
        'stack the pair ($cancelLabel / $confirmLabel)', (tester) async {
      await pumpMx(
        tester,
        SizedBox(
          width: width,
          child: MxSheetActions(
            cancelLabel: cancelLabel,
            onCancel: () {},
            confirmLabel: confirmLabel,
            isDestructive: isDestructive,
            onConfirm: () {},
          ),
        ),
        textScale: 1.3,
      );
      final cancel = tester.getRect(_button(cancelLabel));
      final confirm = tester.getRect(_button(confirmLabel));

      expect(confirm.top, greaterThan(cancel.bottom));
      expect(cancel.width, confirm.width);
      expect(tester.takeException(), isNull);
    });
  }

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
    await tester.pumpAndSettle();
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
