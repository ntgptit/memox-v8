import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';

import 'support/mx_harness.dart';

void main() {
  testWidgets('a note sits on the muted fill with a hairline edge', (
    tester,
  ) async {
    final ColorScheme s = mxThemes['light']!.colorScheme;
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxNote(text: 'Synced just now')),
    );
    final BoxDecoration box =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(MxNote),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(box.color, s.surfaceContainerLow);
    expect(box.border!.top.color, s.outlineVariant);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('the hint form has no fill and no edge', (tester) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxNote.hint(text: 'Kept for 30 days')),
    );
    expect(
      find.descendant(
        of: find.byType(MxNote),
        matching: find.byType(DecoratedBox),
      ),
      findsNothing,
    );
  });

  testWidgets('a one-time note has a named close button', (tester) async {
    var dismissed = 0;
    await pumpMx(
      tester,
      SizedBox(
        width: 300,
        child: MxNote(
          text: 'Swipe a card to grade it',
          onDismiss: () => dismissed++,
          dismissLabel: 'Dismiss tip',
        ),
      ),
    );
    expect(find.byType(MxIconButton), findsOneWidget);
    await tester.tap(find.byTooltip('Dismiss tip'));
    expect(dismissed, 1);
  });

  testWidgets('the hint is calm Body, not the semibold caption', (
    tester,
  ) async {
    await pumpMx(
      tester,
      const SizedBox(width: 300, child: MxNote.hint(text: 'Kept for 30 days')),
    );
    final TextStyle style = tester
        .widget<Text>(find.text('Kept for 30 days'))
        .style!;
    final TextTheme texts = mxThemes['light']!.textTheme;
    expect(style.fontSize, texts.bodyMedium!.fontSize);
    expect(style.fontWeight, texts.bodyMedium!.fontWeight);
  });
}
