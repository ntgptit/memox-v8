import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

import '../../support/widget_harness.dart';

MxDeckPickerSheet _picker(
  List<MxPickerCandidate> candidates, {
  VoidCallback? onDismiss,
}) => MxDeckPickerSheet(
  title: 'Move to deck',
  rule: 'Cards keep their progress.',
  candidates: candidates,
  dismissLabel: 'Cancel',
  onDismiss: onDismiss ?? () {},
  emptyTitle: 'Nowhere to move',
);

void main() {
  testWidgets('head: a 16/700 title and a 12 rule, 20 in and 4 down', (
    tester,
  ) async {
    await pumpMx(
      tester,
      _picker([MxPickerCandidate(label: 'Kana', onTap: () {})]),
    );
    final sheet = tester.getTopLeft(find.byType(MxBottomSheet));

    expect(tester.widget<Text>(find.text('Move to deck')).style!.fontSize, 16);
    expect(
      tester
          .widget<Text>(find.text('Cards keep their progress.'))
          .style!
          .fontSize,
      12,
    );
    // The grabber block is 8 + 4 + 4 = 16, then the head's 4.
    expect(
      tester.getTopLeft(find.text('Move to deck')) - sheet,
      const Offset(20, 20),
    );
  });

  testWidgets(
    'candidates are chevron rows; an ineligible one keeps its reason',
    (tester) async {
      var picked = '';
      await pumpMx(
        tester,
        _picker([
          MxPickerCandidate(label: 'Kana', onTap: () => picked = 'Kana'),
          MxPickerCandidate(
            label: 'Grammar',
            reason: 'Holds other decks',
            isEnabled: false,
            onTap: () => picked = 'Grammar',
          ),
        ]),
      );
      final rows = tester
          .widgetList<MxListRow>(find.byType(MxListRow))
          .toList();

      expect(rows.map((row) => row.hasChevron), [true, true]);
      expect(rows.last.isEnabled, isFalse);
      expect(rows.last.subtitle, 'Holds other decks');
      expect(rows.map((row) => row.hasDivider), [true, false]);
      await tester.tap(find.text('Kana'));
      expect(picked, 'Kana');
      expect(
        tester.widget<MxButton>(find.byType(MxButton)).tone,
        MxButtonTone.outline,
      );
    },
  );

  testWidgets('nowhere to go: a neutral compact EmptyState and one primary', (
    tester,
  ) async {
    await pumpMx(tester, _picker(const []));
    final empty = tester.widget<MxEmptyState>(find.byType(MxEmptyState));

    expect((empty.tone, empty.isCompact), (MxEmptyStateTone.neutral, true));
    expect(find.byType(MxListRow), findsNothing);
    expect(
      tester.widget<MxButton>(find.byType(MxButton)).tone,
      MxButtonTone.primary,
    );
  });

  testWidgets('many candidates scroll; the footer stays tappable (RF1)', (
    tester,
  ) async {
    var dismissed = 0;
    await pumpMx(
      tester,
      _picker([
        for (var i = 0; i < 30; i++)
          MxPickerCandidate(label: 'Deck $i', onTap: () {}),
      ], onDismiss: () => dismissed++),
    );

    expect(
      tester.getSize(find.byType(MxBottomSheet)).height,
      lessThanOrEqualTo(800 * 0.85),
    );
    await tester.tap(find.text('Cancel'));
    expect(dismissed, 1);
  });
}
