import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
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
    title: context.l10n.galleryFOverlaysFeedback,
    children: [
      MxSheetActions(
        cancelLabel: context.l10n.commonCancel,
        onCancel: () {},
        confirmLabel: context.l10n.galleryMoveToTrash,
        onConfirm: () {},
        isDestructive: true,
      ),
      MxInlineBanner(
        tone: MxBannerTone.warning,
        title: context.l10n.galleryTenTagsAtMost,
        message: context.l10n.galleryRemoveATagBeforeAdding,
      ),
      MxInlineBanner(
        tone: MxBannerTone.danger,
        message: context.l10n.galleryTheExportCouldNotBe,
        actions: [
          MxButton(
            label: context.l10n.commonRetry,
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
            label: context.l10n.galleryDialog,
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openDialog(context)),
          ),
          MxButton(
            label: context.l10n.gallerySheet,
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openSheet(context)),
          ),
          MxButton(
            label: context.l10n.galleryDeckPicker,
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => unawaited(_openPicker(context)),
          ),
          MxButton(
            label: context.l10n.gallerySnackbar,
            size: MxButtonSize.small,
            tone: MxButtonTone.secondary,
            onPressed: () => showMxSnackbar(
              context,
              message: context.l10n.galleryMovedToTrash,
              actionLabel: context.l10n.galleryUndo,
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
      title: context.l10n.galleryDeleteThisDeck,
      body: context.l10n.galleryIts42CardsMoveTo,
      actions: MxSheetActions(
        cancelLabel: context.l10n.commonCancel,
        onCancel: () => Navigator.pop(dialogContext),
        confirmLabel: context.l10n.galleryMoveToTrash,
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
                  label: context.l10n.galleryRename,
                  onTap: () => Navigator.pop(sheetContext),
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.folder,
                  label: context.l10n.galleryMove,
                  hasChevron: true,
                  onTap: () => Navigator.pop(sheetContext),
                ),
                MxActionSheetCommandRow(
                  icon: AppIcons.delete,
                  label: context.l10n.galleryDelete,
                  subtitle: context.l10n.galleryRecoverableFor30Days,
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
          title: context.l10n.galleryMoveToDeck,
          rule: context.l10n.galleryCardsKeepTheirProgressDecks,
          candidates: [
            for (var i = 1; i <= _candidateCount; i++)
              MxPickerCandidate(
                label: context.l10n.galleryDeckNumber(i),
                onTap: () => Navigator.pop(sheetContext),
              ),
            MxPickerCandidate(
              label: context.l10n.galleryGrammar,
              reason: context.l10n.galleryHoldsOtherDecks,
              isEnabled: false,
              onTap: () {},
            ),
          ],
          dismissLabel: context.l10n.commonCancel,
          onDismiss: () => Navigator.pop(sheetContext),
          emptyTitle: context.l10n.galleryNowhereToMove,
        ),
      );
}
