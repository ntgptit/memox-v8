import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// What the person picked when an attempt is in progress (BR-TOPIK-011).
enum TopikContinueChoice { continueAttempt, startNew }

/// "You have an attempt in progress": Continue (primary) or Start new; null
/// when dismissed.
Future<TopikContinueChoice?> showTopikContinueDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxDialog<TopikContinueChoice>(
    context,
    builder: (dialogContext) => MxDialog(
      title: l10n.topikContinueTitle,
      body: l10n.topikContinueBody,
      actions: MxSheetActions(
        cancelLabel: l10n.topikStartNew,
        onCancel: () =>
            Navigator.of(dialogContext).pop(TopikContinueChoice.startNew),
        confirmLabel: l10n.topikContinue,
        onConfirm: () =>
            Navigator.of(dialogContext)
                .pop(TopikContinueChoice.continueAttempt),
      ),
    ),
  );
}

/// The second question before the attempt in progress is deleted.
Future<bool> showTopikStartNewDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.topikStartNewTitle,
    body: l10n.topikStartNewBody,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.topikStartNew,
    isDestructive: true,
  );
}

Future<bool> showTopikDeleteDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.topikDeleteTitle,
    body: l10n.topikDeleteBody,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.topikDelete,
    isDestructive: true,
  );
}
