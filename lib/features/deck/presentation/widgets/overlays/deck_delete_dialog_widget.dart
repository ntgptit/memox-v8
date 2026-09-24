import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/deck_deletion_summary_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Asks before [deck] and everything below it are deleted for good.
Future<void> showDeleteDeckDialog(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxDialog<void>(
  context,
  builder: (_) => DeckDeleteDialogWidget(deck: deck),
);

/// The body states how many sub-decks and cards go with the deck
/// (BR-DECK-023). The confirm waits for that count and is destructive.
class DeckDeleteDialogWidget extends ConsumerStatefulWidget {
  const DeckDeleteDialogWidget({super.key, required this.deck});

  final DeckEntity deck;

  @override
  ConsumerState<DeckDeleteDialogWidget> createState() =>
      _DeckDeleteDialogWidgetState();
}

class _DeckDeleteDialogWidgetState
    extends ConsumerState<DeckDeleteDialogWidget> {
  var _isDeleting = false;

  Future<void> _delete() async {
    setState(() => _isDeleting = true);
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .deleteDeck(deckId: widget.deck.id);
      if (!mounted) return;
      if (outcome case Rejected(:final reason)) {
        showMxSnackbar(context, message: context.l10n.deckRejection(reason));
      }
      // On Ok the open deck's screen says "Deck deleted" and steps back
      // (ruling P2-L7).
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(deckDeletionSummaryProvider(widget.deck.id));
    final body = switch (summary) {
      AsyncData(value: Ok(:final value)) => l10n.deckDeleteSummary(
        value.subDeckCount,
        value.cardCount,
      ),
      AsyncData(value: Rejected(:final reason)) => l10n.deckRejection(reason),
      AsyncError(:final error) =>
        error is Failure ? l10n.failure(error) : l10n.failureUnknown,
      _ => null,
    };
    final canDelete = summary.value is Ok && !_isDeleting;
    return MxDialog(
      title: l10n.deckDeleteTitle(widget.deck.name),
      body: body,
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(),
        confirmLabel: l10n.deckDelete,
        isDestructive: true,
        onConfirm: canDelete ? _delete : null,
      ),
    );
  }
}
