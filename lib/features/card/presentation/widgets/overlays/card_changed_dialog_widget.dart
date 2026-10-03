import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Which version wins when Save finds the card changed on another device
/// (SP2a 2.18).
enum CardConflictChoice { useTheirs, keepMine }

/// Asks which version to keep. Completes null when it is dismissed without a
/// choice: the form then stays as it is, unsaved.
Future<CardConflictChoice?> showCardChangedDialog(BuildContext context) =>
    showMxDialog<CardConflictChoice>(
      context,
      builder: (_) => const CardChangedDialogWidget(),
    );

class CardChangedDialogWidget extends StatelessWidget {
  const CardChangedDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.cardChangedTitle,
      body: l10n.cardChangedBody,
      actions: MxSheetActions(
        cancelLabel: l10n.cardUseTheirs,
        onCancel: () => Navigator.of(context).pop(CardConflictChoice.useTheirs),
        confirmLabel: l10n.cardKeepMine,
        onConfirm: () => Navigator.of(context).pop(CardConflictChoice.keepMine),
      ),
    );
  }
}
