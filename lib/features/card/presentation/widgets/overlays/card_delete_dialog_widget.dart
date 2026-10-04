import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_trashed_snackbar_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// The one card a Move to Trash names: its front over its back (kit 07, 09).
typedef CardTrashPreview = ({String front, String back});

/// Asks before the cards of [cardIds] move to the Trash with their history
/// (IT-ORG-014, FE-B1). A single card shows [preview] when the caller has
/// it. Completes true once they have, and the toast is up.
Future<bool> showDeleteCardsDialog(
  BuildContext context, {
  required Set<String> cardIds,
  CardTrashPreview? preview,
  VoidCallback? onOpenTrash,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardDeleteDialogWidget(
        cardIds: cardIds,
        preview: cardIds.length == 1 ? preview : null,
        onOpenTrash: onOpenTrash,
      ),
    ) ??
    false;

/// The confirm is not destructive, since the Trash keeps the cards for 30
/// days, and it spins while they move (FE-B1 D15).
class CardDeleteDialogWidget extends ConsumerStatefulWidget {
  const CardDeleteDialogWidget({
    super.key,
    required this.cardIds,
    this.preview,
    this.onOpenTrash,
  });

  final Set<String> cardIds;
  final CardTrashPreview? preview;

  /// Rides on the toast of several cards and on a refused Undo (FE-B1).
  final VoidCallback? onOpenTrash;

  @override
  ConsumerState<CardDeleteDialogWidget> createState() =>
      _CardDeleteDialogWidgetState();
}

class _CardDeleteDialogWidgetState
    extends ConsumerState<CardDeleteDialogWidget> {
  var _isDeleting = false;

  Future<void> _delete() async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isDeleting) return;
    setState(() => _isDeleting = true);
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .deleteCards(cardIds: widget.cardIds);
      if (!mounted) return;
      switch (outcome) {
        case Ok(value: final batchIds):
          showCardsTrashedSnackbar(
            context,
            batchIds: batchIds,
            front: widget.preview?.front,
            onOpenTrash: widget.onOpenTrash,
          );
        case Rejected(:final reason):
          showMxSnackbar(context, message: context.l10n.cardRejection(reason));
      }
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
    final count = widget.cardIds.length;
    return MxDialog(
      title: l10n.cardDeleteTitle(count),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          if (widget.preview case final preview?) _Preview(preview: preview),
          MxNote(icon: AppIcons.history, text: l10n.cardDeleteNote(count)),
        ],
      ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardMoveToTrash,
        confirmIcon: AppIcons.delete,
        isConfirmLoading: _isDeleting,
        onConfirm: _isDeleting ? null : _delete,
      ),
    );
  }
}

/// The card's front over its back, as the list row shows them.
class _Preview extends StatelessWidget {
  const _Preview({required this.preview});

  final CardTrashPreview preview;

  static const int _maxLines = 2;

  @override
  Widget build(BuildContext context) {
    final styles = context.textStyles;
    return MxCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.micro,
        children: [
          Text(
            preview.front,
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
            style: styles.contentTitle,
          ),
          Text(
            preview.back,
            maxLines: _maxLines,
            overflow: TextOverflow.ellipsis,
            style: styles.rowDescription,
          ),
        ],
      ),
    );
  }
}
