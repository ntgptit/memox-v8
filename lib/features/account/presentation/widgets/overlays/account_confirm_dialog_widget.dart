import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before an account step (account UI spec §9.1, plan ruling 6), in
/// the Reset dialog's form: a title, the body, an optional note, Cancel and
/// the confirm. True only on the confirm; Cancel, Back and the scrim are a
/// no.
Future<bool> confirmAccountStep(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  Widget? note,
  bool isDestructive = false,
  bool isWarning = false,
  bool canConfirm = true,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => AccountConfirmDialogWidget(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        note: note,
        isDestructive: isDestructive,
        isWarning: isWarning,
        canConfirm: canConfirm,
      ),
    ) ??
    false;

/// Auth spec ruling 6: signing in as another account replaces this
/// phone's data, so its [count] unsent changes are named first (screens 30
/// and 31).
Future<bool> confirmUnsentLoss(BuildContext context, int count) {
  final l10n = context.l10n;
  return confirmAccountStep(
    context,
    title: l10n.accountUnsentTitle(count),
    body: l10n.accountUnsentBody(count),
    // The title names what it loses; the confirm is the verb (DEV-179).
    confirmLabel: l10n.accountUnsentConfirm,
    isDestructive: true,
  );
}

/// A refused deletion of the last admin (spec §5.4, §9 B7): what to do
/// first, and one OK.
Future<void> showLastAdminDialog(BuildContext context) => showMxDialog<void>(
  context,
  builder: (dialogContext) {
    final l10n = dialogContext.l10n;
    return MxDialog(
      title: l10n.accountLastAdminTitle,
      body: l10n.accountLastAdmin,
      actions: MxSheetActions.custom(
        children: [
          Expanded(
            child: MxButton(
              label: l10n.commonOk,
              isBlock: true,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ),
        ],
      ),
    );
  },
);

class AccountConfirmDialogWidget extends StatelessWidget {
  const AccountConfirmDialogWidget({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.note,
    this.isDestructive = false,
    this.isWarning = false,
    this.canConfirm = true,
  });

  final String title;
  final String body;
  final String confirmLabel;

  /// An `MxNote`: the reassurance, or why the confirm cannot go.
  final Widget? note;
  final bool isDestructive;

  /// A confirm that changes a lot but loses nothing (critique 2026-10-02).
  final bool isWarning;

  /// False disables the confirm, as a deletion offline (spec §9 B6).
  final bool canConfirm;

  @override
  Widget build(BuildContext context) => MxDialog(
    title: title,
    body: body,
    content: note,
    actions: MxSheetActions(
      cancelLabel: context.l10n.commonCancel,
      onCancel: () => Navigator.of(context).pop(false),
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
      isWarning: isWarning,
      onConfirm: canConfirm ? () => Navigator.of(context).pop(true) : null,
    ),
  );
}
