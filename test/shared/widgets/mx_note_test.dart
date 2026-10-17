import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_palette.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import '../../support/widget_harness.dart';

const _rule = 'Changes apply to future sessions.';

void main() {
  final colors = appLightColors;

  testWidgets('muted fill, hairline border, medium radius, padding 10 12', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxNote(text: _rule)),
    );
    final box =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: find.byType(MxNote),
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;
    final note = tester.getTopLeft(find.byType(MxNote));

    expect(box.color, colors.muted);
    final element = tester.element(find.byType(MxNote));
    expect(
      box.border,
      Border.all(color: colors.border, width: element.hairline),
    );
    expect(box.borderRadius, element.radii.md);
    expect(tester.getTopLeft(find.byType(Icon)).dx - note.dx, 13);
    expect(tester.getTopLeft(find.text(_rule)) - note, const Offset(37, 11));
    expect(tester.widget<Icon>(find.byType(Icon)).size, 16);
    expect(
      tester.widget<Text>(find.text(_rule)).style!.color,
      colors.mutedForeground,
    );
  });

  testWidgets('the glyph centres on the first line', (tester) async {
    final long = List.filled(12, _rule).join(' ');
    await pumpMx(tester, SizedBox(width: 328, child: MxNote(text: long)));
    final role = tester.element(find.text(long)).texts.body;
    final firstLine = role.fontSize! * role.height!;

    expect(
      tester.getCenter(find.byType(Icon)).dy,
      tester.getTopLeft(find.text(long)).dy + firstLine / 2,
    );
  });

  testWidgets('the hint form is a footnote: no fill, no border, the glyph and '
      'text in the secondary text (critique 2026-09-30)', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxNote.hint(text: _rule)),
    );

    final boxes = tester.widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(MxNote),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(boxes, isEmpty);
    expect(
      tester.widget<Text>(find.text(_rule)).style!.color,
      colors.mutedForeground,
    );
    expect(tester.widget<MxNote>(find.byType(MxNote)).isHint, isTrue);
  });

  testWidgets('a dismissible note ends in a close button named by its label, '
      'and a tap dismisses it (critique 2026-09-30)', (tester) async {
    final handle = tester.ensureSemantics();
    var dismissed = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 328,
        child: MxNote(
          text: _rule,
          dismissLabel: 'Hide this note',
          onDismiss: () => dismissed++,
        ),
      ),
    );

    expect(find.bySemanticsLabel('Hide this note'), findsOneWidget);
    await tester.tap(find.byType(MxIconButton));
    await tester.pumpAndSettle();
    expect(dismissed, 1);
    handle.dispose();
  });

  testWidgets('a note without onDismiss has no close button', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 328, child: MxNote(text: _rule)),
    );

    expect(find.byType(MxIconButton), findsNothing);
  });
}
