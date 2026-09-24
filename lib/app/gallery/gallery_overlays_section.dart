import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/app/gallery/gallery_section.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/shared/widgets/mx_action_sheet_command_row.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Group F: SheetActions and InlineBanner in place; the dialog, the sheets
/// and the snackbar open live.
class GalleryOverlaysSection extends StatelessWidget {
  const GalleryOverlaysSection({super.key});

  static const int _candidateCount = 8;

  @override
  Widget build(BuildContext context) => GallerySection(
    title: 'F · Overlays & feedback',
    children: [
      MxSheetActions(
        cancelLabel: 'Cancel',
        onCancel: () {},
        confirmLabel: 'Move to Trash',
        onConfirm: () {},
        isDestructive: true,
      ),
      const MxInlineBanner(
        tone: MxBannerTone.warning,
        title: 'Ten tags at most',
        message: 'Remove a tag before adding another one.',
      ),
      MxInlineBanner(
        tone: MxBannerTone.danger,
        message: 'The export could not be written.',
        actions: [
          MxButton(
            label: 'Retry',
            icon: AppIcons.retry,
            size: MxButtonSize.compact,
            onPressed: () {},
          ),
        ],
      ),
      Wrap(
        spacing: AppSpacing.control,
        runSpacing: AppSpacing.control,
        children: [
          MxButton(
            label: 'Dialog',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openDialog(context)),
          ),
          MxButton(
            label: 'Sheet',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openSheet(context)),
          ),
          MxButton(
            label: 'Deck picker',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openPicker(context)),
          ),
          MxButton(
            label: 'Snackbar',
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => showMxSnackbar(
              context,
              message: 'Moved to Trash',
              actionLabel: 'Undo',
              onAction: () {},
            ),
          ),
        ],
      ),
    ],
  );

  static Future<void> _openDialog(BuildContext context) => showMxDialog<void>(
    context,
    builder: (dialogContext) => MxDialog(
      title: 'Delete this deck?',
      body: 'Its 42 cards move to Trash, where they stay for 30 days.',
      actions: MxSheetActions(
        cancelLabel: 'Cancel',
        onCancel: () => Navigator.pop(dialogContext),
        confirmLabel: 'Move to Trash',
        onConfirm: () => Navigator.pop(dialogContext),
        isDestructive: true,
      ),
    ),
  );

  static Future<void> _openSheet(BuildContext context) =>
      showMxBottomSheet<void>(
        context,
        builder: (sheetContext) => MxBottomSheet(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.control),
            child: Column(
              children: [
                MxActionSheetCommandRow(
                  icon: AppIcons.edit,
                  label: 'Rename',
                  onTap: () => Navigator.pop(sheetContext),
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: 'Move',
                  hasChevron: true,
                  onTap: () => Navigator.pop(sheetContext),
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: 'Delete',
                  subtitle: 'Recoverable for 30 days',
                  isDestructive: true,
                  onTap: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        ),
      );

  static Future<void> _openPicker(BuildContext context) =>
      showMxBottomSheet<void>(
        context,
        builder: (sheetContext) => MxDeckPickerSheet(
          title: 'Move to deck',
          rule:
              'Cards keep their progress. Decks that hold other decks are '
              'not offered.',
          candidates: [
            for (var i = 1; i <= _candidateCount; i++)
              MxPickerCandidate(
                label: 'Deck ${i.toString()}',
                onTap: () => Navigator.pop(sheetContext),
              ),
            MxPickerCandidate(
              label: 'Grammar',
              reason: 'Holds other decks',
              isEnabled: false,
              onTap: () {},
            ),
          ],
          dismissLabel: 'Cancel',
          onDismiss: () => Navigator.pop(sheetContext),
          emptyTitle: 'Nowhere to move',
        ),
      );
}
