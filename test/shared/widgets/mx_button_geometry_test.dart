import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/core/theme/app_dimens.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../support/widget_harness.dart';

// What MxButton measures and paints around its label: the side padding per
// tone, the leading glyph and its gap, and the focus ring (Material 3).

final _painted = find.descendant(
  of: find.byType(TextButton),
  matching: find.byType(Material),
);

void main() {
  final scheme = lightColorScheme;

  testWidgets('a leading glyph is painted at 18, 8 before the label', (
    tester,
  ) async {
    const dimens = AppDimens();
    await pumpMx(
      tester,
      MxButton(label: 'Add', icon: AppIcons.add, onPressed: () {}),
    );

    expect(
      tester.getSize(find.byIcon(AppIcons.add)),
      Size.square(dimens.sizeIconButton),
    );
    expect(dimens.sizeIconButton, 18);
    expect(
      tester.getRect(find.text('Add')).left -
          tester.getRect(find.byIcon(AppIcons.add)).right,
      dimens.space8,
    );
  });

  testWidgets('horizontal padding: 12 for the text tone, 24 for the rest', (
    tester,
  ) async {
    const dimens = AppDimens();
    for (final tone in MxButtonTone.values) {
      await pumpMx(tester, MxButton(label: 'Go', tone: tone, onPressed: () {}));
      final box = tester.getRect(_painted.first);
      final label = tester.getRect(find.text('Go'));
      final side = tone == MxButtonTone.text ? dimens.space12 : dimens.space24;

      expect(label.left - box.left, side, reason: '$tone start');
      expect(box.right - label.right, side, reason: '$tone end');
    }
  });

  // Material 3: a leading glyph takes the start side from 24 to 16 (text:
  // 12 start, 16 end).
  testWidgets('with a leading glyph the start side is closer: 16, text 12', (
    tester,
  ) async {
    const dimens = AppDimens();
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(label: 'Go', tone: tone, icon: AppIcons.add, onPressed: () {}),
      );
      final box = tester.getRect(_painted.first);
      final glyph = tester.getRect(find.byIcon(AppIcons.add));
      final label = tester.getRect(find.text('Go'));
      final isText = tone == MxButtonTone.text;

      expect(
        glyph.left - box.left,
        isText ? dimens.space12 : dimens.space16,
        reason: '$tone start',
      );
      expect(
        box.right - label.right,
        isText ? dimens.space16 : dimens.space24,
        reason: '$tone end',
      );
    }
  });

  testWidgets('a focused button draws a 2dp primary ring 2dp outside its '
      'container, on a primary fill too', (tester) async {
    const dimens = AppDimens();
    for (final tone in MxButtonTone.values) {
      await pumpMx(
        tester,
        MxButton(
          label: 'Go',
          tone: tone,
          isAutofocused: true,
          onPressed: () {},
        ),
      );
      await tester.pumpAndSettle();
      final painter = tester.renderObject<RenderBox>(
        find
            .descendant(of: _painted.first, matching: find.byType(CustomPaint))
            .first,
      );
      // The painter shares the container's box, in its own coordinates.
      final container = Offset.zero & painter.size;
      final ringCentre = container.inflate(
        dimens.strokeFocusGap + dimens.strokeFocus / 2,
      );
      expect(painter.size, tester.getSize(_painted.first), reason: '$tone');

      expect(
        painter,
        paints..something((name, arguments) {
          if (name != #drawPath) return false;
          final paint = arguments[1] as Paint;
          final bounds = (arguments[0] as Path).getBounds();
          return paint.color.toARGB32() == scheme.primary.toARGB32() &&
              paint.style == PaintingStyle.stroke &&
              paint.strokeWidth == dimens.strokeFocus &&
              (bounds.left - ringCentre.left).abs() < 0.01 &&
              (bounds.top - ringCentre.top).abs() < 0.01 &&
              (bounds.right - ringCentre.right).abs() < 0.01 &&
              (bounds.bottom - ringCentre.bottom).abs() < 0.01;
        }),
        reason: '$tone',
      );
    }
  });

  testWidgets('an unfocused button paints no ring', (tester) async {
    await pumpMx(tester, MxButton(label: 'Go', onPressed: () {}));
    final painter = tester.renderObject(
      find
          .descendant(of: _painted.first, matching: find.byType(CustomPaint))
          .first,
    );

    expect(
      painter,
      isNot(
        paints..something(
          (name, arguments) =>
              name == #drawPath &&
              (arguments[1] as Paint).color.toARGB32() ==
                  scheme.primary.toARGB32(),
        ),
      ),
    );
  });
}
