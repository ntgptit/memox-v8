@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_option_row.dart';

import 'support/mx_harness.dart';

void main() {
  final Map<(String, String), Widget Function()> sheets = {
    ('dialog', 'decision'): () => SizedBox(
      width: 380,
      child: MxDialog(
        title: 'Move "Spanish" to Trash?',
        message: 'Its 120 cards go with it. Trash keeps them for 30 days.',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move to Trash',
          onConfirm: () {},
          tone: MxSheetActionsTone.destructive,
        ),
      ),
    ),
    ('bottom_sheet', 'picker'): () => SizedBox(
      width: 380,
      child: MxBottomSheet(
        title: 'Sort & filter',
        actions: MxSheetActions(
          cancelLabel: 'Reset',
          onCancel: () {},
          confirmLabel: 'Apply',
          onConfirm: () {},
          isInSheet: true,
        ),
        child: Column(
          children: [
            MxOptionRow(
              title: 'Manual order',
              isSelected: true,
              onSelected: () {},
            ),
            MxOptionRow(
              title: 'Date added',
              isSelected: false,
              onSelected: () {},
            ),
          ],
        ),
      ),
    ),
  };
  for (final MapEntry(key: (component, state), value: sheet)
      in sheets.entries) {
    for (final variant in mxThemes.keys) {
      testWidgets('mx_$component $state $variant', (tester) async {
        await expectMxGolden(
          tester,
          component: component,
          state: state,
          variant: variant,
          sheet: sheet(),
        );
      });
    }
  }
}
