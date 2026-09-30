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
  IconData? confirmIcon,
  bool isDestructive = false,
  bool canConfirm = true,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => AccountConfirmDialogWidget(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        note: note,
        confirmIcon: confirmIcon,
        isDestructive: isDestructive,
        canConfirm: canConfirm,
      ),
    ) ??
    false;

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
    this.confirmIcon,
    this.isDestructive = false,
    this.canConfirm = true,
  });

  final String title;
  final String body;
  final String confirmLabel;

  /// An `MxNote`: the reassurance, or why the confirm cannot go.
  final Widget? note;
  final IconData? confirmIcon;
  final bool isDestructive;

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
      confirmIcon: confirmIcon,
      isDestructive: isDestructive,
      onConfirm: canConfirm ? () => Navigator.of(context).pop(true) : null,
    ),
  );
}
