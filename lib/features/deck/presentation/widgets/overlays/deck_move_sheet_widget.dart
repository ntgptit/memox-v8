import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/providers/deck_move_targets_provider.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_path_label_widget.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Picks the deck [deck] moves under (UC-DECK-005).
Future<void> showMoveDeckSheet(
  BuildContext context, {
  required DeckEntity deck,
}) => showMxBottomSheet<void>(
  context,
  builder: (_) => DeckMoveSheetWidget(deck: deck),
);

/// The backend already leaves out every deck that cannot take this one
/// (spec §6.2), so each candidate is enabled and named by its path (ruling
/// P2-L8).
class DeckMoveSheetWidget extends ConsumerStatefulWidget {
  const DeckMoveSheetWidget({super.key, required this.deck});

  final DeckEntity deck;

  @override
  ConsumerState<DeckMoveSheetWidget> createState() =>
      _DeckMoveSheetWidgetState();
}

class _DeckMoveSheetWidgetState extends ConsumerState<DeckMoveSheetWidget> {
  static const int _skeletonRows = 3;

  /// One move at a time: a second tap before the first lands does nothing.
  var _isMoving = false;

  Future<void> _move(DeckMoveTarget target) async {
    if (_isMoving) return;
    setState(() => _isMoving = true);
    try {
      final outcome = await ref
          .read(deckActionsControllerProvider.notifier)
          .moveDeck(deckId: widget.deck.id, newParentId: target.id);
      if (!mounted) return;
      final l10n = context.l10n;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.deckMovedToast(target.name),
          Rejected(:final reason) => l10n.deckRejection(reason),
        },
      );
      Navigator.of(context).pop();
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isMoving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = deckMoveTargetsProvider(widget.deck.id);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => MxDeckPickerSheet(
        title: l10n.deckMoveTitle,
        rule: l10n.deckMoveRule,
        candidates: [
          for (final target in value)
            MxPickerCandidate(
              label: deckPathLabel([
                for (final entry in target.path) entry.name,
                target.name,
              ]),
              isEnabled: !_isMoving,
              onTap: () => unawaited(_move(target)),
            ),
        ],
        // Ruling O11: OK, not Cancel, when there is nowhere to go.
        dismissLabel: value.isEmpty ? l10n.commonOk : l10n.commonCancel,
        onDismiss: () => Navigator.of(context).pop(),
        emptyTitle: l10n.deckMoveEmptyTitle,
        emptyBody: l10n.deckMoveEmptyBody,
      ),
      AsyncError() => MxBottomSheet(
        child: MxErrorState(
          title: l10n.libraryLoadErrorTitle,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
        ),
      ),
      _ => MxBottomSheet(
        child: Column(
          children: [
            for (var i = 0; i < _skeletonRows; i++) const MxSkeletonRow(),
          ],
        ),
      ),
    };
  }
}
