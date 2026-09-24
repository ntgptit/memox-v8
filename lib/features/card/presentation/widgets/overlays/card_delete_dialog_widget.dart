import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before the cards of [cardIds] and their history are deleted for
/// good (IT-ORG-014). Completes true once they are gone.
Future<bool> showDeleteCardsDialog(
  BuildContext context, {
  required Set<String> cardIds,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardDeleteDialogWidget(cardIds: cardIds),
    ) ??
    false;

class CardDeleteDialogWidget extends ConsumerStatefulWidget {
  const CardDeleteDialogWidget({super.key, required this.cardIds});

  final Set<String> cardIds;

  @override
  ConsumerState<CardDeleteDialogWidget> createState() =>
      _CardDeleteDialogWidgetState();
}

class _CardDeleteDialogWidgetState
    extends ConsumerState<CardDeleteDialogWidget> {
  var _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .deleteCards(cardIds: widget.cardIds);
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.cardDeletedToast(widget.cardIds.length),
          Rejected(:final reason) => l10n.cardRejection(reason),
        },
      );
      Navigator.of(context).pop(outcome is Ok);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.cardDeleteTitle(widget.cardIds.length),
      body: l10n.cardDeleteBody,
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardDelete,
        isDestructive: true,
        onConfirm: _isDeleting ? null : _delete,
      ),
    );
  }
}
