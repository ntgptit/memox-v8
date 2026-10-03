import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/bulk_outcome.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/transfer/presentation/controllers/card_import_controller.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before the [count] imported cards move to the Trash (SP2a 2.25).
/// Completes with what moved once they have, and the toast is up; null when
/// the person kept them.
Future<BulkOutcome?> showImportUndoDialog(
  BuildContext context, {
  required String deckId,
  required int count,
}) => showMxDialog<BulkOutcome>(
  context,
  builder: (_) => ImportUndoDialogWidget(deckId: deckId, count: count),
);

/// The confirm is not destructive, since the Trash keeps the cards for 30
/// days, and it spins while they move.
class ImportUndoDialogWidget extends ConsumerStatefulWidget {
  const ImportUndoDialogWidget({
    super.key,
    required this.deckId,
    required this.count,
  });

  final String deckId;
  final int count;

  @override
  ConsumerState<ImportUndoDialogWidget> createState() =>
      _ImportUndoDialogWidgetState();
}

class _ImportUndoDialogWidgetState
    extends ConsumerState<ImportUndoDialogWidget> {
  var _isUndoing = false;

  Future<void> _undo() async {
    if (_isUndoing) return;
    setState(() => _isUndoing = true);
    try {
      final outcome = await ref
          .read(cardImportControllerProvider(widget.deckId).notifier)
          .undoImport();
      if (!mounted) return;
      final l10n = context.l10n;
      switch (outcome) {
        case Ok(:final value):
          showMxSnackbar(
            context,
            message: l10n.bulkToast(
              l10n.importUndoneToast(value.done.length),
              value.skipped.length,
            ),
          );
          Navigator.of(context).pop(value);
        // Every imported card is already gone: nothing is left to move, so
        // the result has nothing left to undo either.
        case Rejected():
          showMxSnackbar(context, message: l10n.importUndoGone);
          Navigator.of(context).pop(const BulkOutcome(done: {}));
      }
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isUndoing = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.importUndoTitle(widget.count),
      content: MxNote(
        icon: AppIcons.history,
        text: l10n.cardDeleteNote(widget.count),
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.cardMoveToTrash,
        confirmIcon: AppIcons.delete,
        isConfirmLoading: _isUndoing,
        onConfirm: _isUndoing ? null : _undo,
      ),
    );
  }
}
