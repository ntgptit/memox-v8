import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/deck_deletion_summary_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_trashed_snackbar_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before [deck] and everything below it move to the Trash. True once
/// they have, and the toast offering Undo is up (FE-B1, kit 01).
Future<bool> showDeleteDeckDialog(
  BuildContext context, {
  required DeckEntity deck,
  VoidCallback? onOpenTrash,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) =>
          DeckDeleteDialogWidget(deck: deck, onOpenTrash: onOpenTrash),
    ) ??
    false;

/// The body states how many sub-decks and cards go with the deck
/// (BR-DECK-023). The confirm waits for that count; it is not destructive,
/// since the Trash keeps them for 30 days, and it spins while the deck
/// moves (FE-B1 D15).
class DeckDeleteDialogWidget extends ConsumerStatefulWidget {
  const DeckDeleteDialogWidget({
    super.key,
    required this.deck,
    this.onOpenTrash,
  });

  final DeckEntity deck;

  /// Rides on a refused Undo's toast (FE-B1).
  final VoidCallback? onOpenTrash;

  @override
  ConsumerState<DeckDeleteDialogWidget> createState() =>
      _DeckDeleteDialogWidgetState();
}

class _DeckDeleteDialogWidgetState
    extends ConsumerState<DeckDeleteDialogWidget> {
  var _isDeleting = false;

  /// The last move's failure, shown in the dialog until the next try
  /// (SP2b 2.27).
  Failure? _failure;

  Future<void> _delete(DeckDeletionSummary summary) async {
    // A second tap in the same frame reaches here before the busy confirm
    // is drawn.
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _failure = null;
    });
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .deleteDeck(deckId: widget.deck.id);
      if (!mounted) return;
      switch (outcome) {
        case Ok(value: final batchId):
          showDeckTrashedSnackbar(
            context,
            deckName: widget.deck.name,
            summary: summary,
            batchId: batchId,
            onOpenTrash: widget.onOpenTrash,
          );
        case Rejected(:final reason):
          showMxSnackbar(context, message: context.l10n.deckRejection(reason));
      }
      Navigator.of(context).pop(outcome is Ok);
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'deck delete');
      if (!mounted) return;
      setState(() {
        _isDeleting = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(deckDeletionSummaryProvider(widget.deck.id));
    final counted = switch (summary) {
      AsyncData(value: Ok(:final value)) => value,
      _ => null,
    };
    final body = switch (summary) {
      AsyncData(value: Ok(:final value)) => l10n.deckDeleteSummary(
        widget.deck.name,
        value.subDeckCount,
        value.cardCount,
      ),
      AsyncData(value: Rejected(:final reason)) => l10n.deckRejection(reason),
      _ => null,
    };
    // A failed count read: Retry reads it again; Cancel stays live, so the
    // dialog is never a dead end (as the reset dialog, SP2b 2.28).
    final summaryFailure = switch (summary) {
      AsyncError(:final error) =>
        error is Failure ? l10n.failure(error) : l10n.failureUnknown,
      _ => null,
    };
    final failure = _failure;
    return MxDialog(
      // The toast with Undo must reach the screen: Back and a scrim tap wait
      // for the move (SP2b 2.26).
      isHeld: _isDeleting,
      title: l10n.deckDeleteTitle,
      body: body,
      content: counted == null && failure == null && summaryFailure == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.grouped,
              children: [
                if (failure != null)
                  MxInlineBanner(
                    tone: MxBannerTone.warning,
                    message: l10n.failure(failure),
                  ),
                if (summaryFailure != null)
                  MxInlineBanner(
                    tone: MxBannerTone.warning,
                    message: summaryFailure,
                    actions: [
                      MxButton(
                        label: l10n.commonRetry,
                        size: MxButtonSize.compact,
                        isLoading: summary.isLoading,
                        onPressed: () => ref.invalidate(
                          deckDeletionSummaryProvider(widget.deck.id),
                        ),
                      ),
                    ],
                  ),
                if (counted != null)
                  MxNote(icon: AppIcons.history, text: l10n.deckDeleteNote),
              ],
            ),
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: _isDeleting ? null : () => Navigator.of(context).pop(),
        confirmLabel: l10n.deckDelete,
        confirmIcon: AppIcons.delete,
        isConfirmLoading: _isDeleting,
        onConfirm: switch (counted) {
          final summary? when !_isDeleting => () => _delete(summary),
          _ => null,
        },
      ),
    );
  }
}
