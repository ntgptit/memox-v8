import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/foundations/app_breakpoints.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

import 'support/mx_harness.dart';

const Key _actions = ValueKey<String>('actions');

MxFooterBar _footer() => MxFooterBar(
  caption: 'Saved on this phone',
  actions: MxSheetActions(
    key: _actions,
    cancelLabel: 'Cancel',
    onCancel: () {},
    confirmLabel: 'Save card',
    onConfirm: () {},
  ),
);

void main() {
  for (final MapEntry(key: name, value: theme) in mxThemes.entries) {
    final ColorScheme s = theme.colorScheme;
    testWidgets('$name: the page ground under an outline-variant hairline', (
      tester,
    ) async {
      await pumpMx(
        tester,
        SizedBox(width: 400, child: _footer()),
        theme: theme,
      );
      final BoxDecoration box =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(MxFooterBar),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(box.color, s.surface);
      expect(box.boxShadow, isNull);
      expect(
        (box.border! as Border).top,
        BorderSide(color: s.outlineVariant, width: AppStroke.hairline),
      );
      expect(
        tester.widget<Text>(find.text('Saved on this phone')).style?.color,
        s.onSurfaceVariant,
      );
    });
  }

  testWidgets('16 across, 12 down, the caption 8 above the actions', (
    tester,
  ) async {
    await pumpMx(tester, SizedBox(width: 400, child: _footer()));
    final Rect bar = tester.getRect(find.byType(MxFooterBar));
    final Rect caption = tester.getRect(find.text('Saved on this phone'));
    final Rect actions = tester.getRect(find.byKey(_actions));
    expect(caption.left - bar.left, 16);
    expect(caption.top - bar.top, 12);
    expect(actions.top - caption.bottom, 8);
    expect(bar.bottom - actions.bottom, 12);
  });

  testWidgets('on a wide window its content keeps to the column', (
    tester,
  ) async {
    await pumpMx(tester, SizedBox(width: 1000, child: _footer()));
    expect(
      tester.getSize(find.byKey(_actions)).width,
      AppBreakpoints.contentMax - 32,
    );
  });

  testWidgets('its content keeps clear of a display cutout', (tester) async {
    await pumpMx(
      tester,
      SizedBox(
        width: 400,
        child: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(left: 40)),
          child: _footer(),
        ),
      ),
    );
    expect(
      tester.getRect(find.text('Saved on this phone')).left -
          tester.getRect(find.byType(MxFooterBar)).left,
      40 + 16,
    );
  });
}
