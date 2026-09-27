import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a second copy of [title] (BR-STARTER-008; kit 03
/// `secondCopy`). Completes true to go on to the algorithm sheet.
Future<bool> showStarterRepeatAddDialog(
  BuildContext context, {
  required String title,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return MxDialog(
          title: l10n.starterSecondCopyTitle,
          body: l10n.starterSecondCopyBody(title),
          actions: MxSheetActions(
            cancelLabel: l10n.commonCancel,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            confirmLabel: l10n.starterSecondCopyConfirm,
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    ) ??
    false;
