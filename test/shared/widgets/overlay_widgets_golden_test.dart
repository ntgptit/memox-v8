@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/theme/app_icons.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

import '../../support/golden_harness.dart';

void main() {
  testWidgets('MxSheetActions and MxInlineBanner', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_sheet_actions_banner',
      Column(
        spacing: 16,
        children: [
          MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () {},
            confirmLabel: 'Move',
            onConfirm: () {},
            isDestructive: true,
          ),
          MxSheetActions(
            cancelLabel: 'Cancel',
            onCancel: () {},
            confirmLabel: 'Move',
            onConfirm: null,
            isInSheet: true,
          ),
          const MxInlineBanner(
            tone: MxBannerTone.warning,
            title: 'Ten tags at most',
            message: 'Remove a tag before adding another one.',
          ),
          MxInlineBanner(
            tone: MxBannerTone.danger,
            message:
                'The export could not be written. Nothing on this device '
                'changed.',
            actions: [
              MxButton(
                label: 'Retry',
                icon: AppIcons.retry,
                size: MxButtonSize.small,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  });

  testWidgets('MxDialog with a destructive footer', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_dialog',
      MxDialog(
        title: 'Delete this deck?',
        body: 'Its 42 cards move to Trash, where they stay for 30 days.',
        actions: MxSheetActions(
          cancelLabel: 'Cancel',
          onCancel: () {},
          confirmLabel: 'Move',
          onConfirm: () {},
          isDestructive: true,
        ),
      ),
    );
  });

  testWidgets('MxBottomSheet with command rows', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_bottom_sheet',
      Align(
        alignment: Alignment.bottomCenter,
        child: MxBottomSheet(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                MxActionSheetCommandRow(
                  icon: AppIcons.edit,
                  label: 'Rename',
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: 'Move',
                  hasChevron: true,
                  onTap: () {},
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  subtitle: 'Recoverable for 30 days',
                  isDestructive: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('MxSnackbar: a toast with an action, from showMxSnackbar', (
    tester,
  ) async {
    await expectThemedOverlayGoldens(
      tester,
      'mx_snackbar',
      open: (context) => showMxSnackbar(
        context,
        message:
            'The export was saved to Downloads and is ready to share with '
            'another device.',
        actionLabel: 'Open',
        onAction: () {},
      ),
    );
  });

  // One sheet per board: two content-sized sheets stacked do not fit the 768
  // of the 360 x 800 board once a list row is 56 / 72 tall (Material 3).
  testWidgets('MxDeckPickerSheet with targets', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_deck_picker',
      MxDeckPickerSheet(
        title: 'Move to deck',
        rule:
            'Cards keep their progress. Decks that hold other decks '
            'are not offered.',
        candidates: [
          MxPickerCandidate(label: 'Kana', onTap: () {}),
          MxPickerCandidate(label: 'Kanji N5', onTap: () {}),
          MxPickerCandidate(
            label: 'Grammar',
            reason: 'Holds other decks',
            isEnabled: false,
            onTap: () {},
          ),
        ],
        dismissLabel: 'Cancel',
        onDismiss: () {},
        emptyTitle: 'Nowhere to move',
      ),
    );
  });

  testWidgets('MxDeckPickerSheet with none', (tester) async {
    await expectThemedGoldens(
      tester,
      'mx_deck_picker_empty',
      MxDeckPickerSheet(
        title: 'Move to deck',
        rule: 'Cards keep their progress.',
        candidates: const [],
        dismissLabel: 'OK',
        onDismiss: () {},
        emptyTitle: 'Nowhere to move',
        emptyBody: 'Create another deck first.',
      ),
    );
  });
}
