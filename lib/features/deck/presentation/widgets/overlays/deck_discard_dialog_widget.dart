import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a new root deck the person started is left (UC-DECK-001 A1).
/// Completes true to discard, false to keep editing.
Future<bool> showDeckDiscardDialog(BuildContext context) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => const DeckDiscardDialogWidget(),
    ) ??
    false;

class DeckDiscardDialogWidget extends StatelessWidget {
  const DeckDiscardDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      width: MxDialogWidth.medium,
      title: l10n.deckDiscardTitle,
      body: l10n.deckDiscardBody,
      actions: MxSheetActions(
        cancelLabel: l10n.deckKeepEditing,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.deckDiscard,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
