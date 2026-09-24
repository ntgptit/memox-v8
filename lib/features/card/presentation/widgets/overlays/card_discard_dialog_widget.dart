import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a changed form is left (ruling P4a-L5). Completes true to
/// discard, false to keep editing.
Future<bool> showCardDiscardDialog(
  BuildContext context, {
  required bool isNew,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardDiscardDialogWidget(isNew: isNew),
    ) ??
    false;

class CardDiscardDialogWidget extends StatelessWidget {
  const CardDiscardDialogWidget({super.key, required this.isNew});

  /// A card not saved yet, rather than changes to a saved one.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      width: MxDialogWidth.medium,
      title: isNew ? l10n.cardDiscardNewTitle : l10n.cardDiscardTitle,
      body: isNew ? l10n.cardDiscardNewBody : l10n.cardDiscardBody,
      actions: MxSheetActions(
        cancelLabel: l10n.cardKeepEditing,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardDiscard,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
