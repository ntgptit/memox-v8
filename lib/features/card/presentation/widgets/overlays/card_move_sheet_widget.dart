import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_move_targets_provider.dart';
import 'package:memox/features/card/presentation/widgets/support/card_deck_path_label_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Picks the deck the cards of [cardIds] move to (UC-CARD-001 A5).
/// Completes true once the move landed.
Future<bool> showCardMoveSheet(
  BuildContext context, {
  required String sourceDeckId,
  required Set<String> cardIds,
}) async =>
    await showMxBottomSheet<bool>(
      context,
      builder: (_) =>
          CardMoveSheetWidget(sourceDeckId: sourceDeckId, cardIds: cardIds),
    ) ??
    false;

/// The backend offers only eligible decks, each named by its path (ruling
/// P3-L8).
class CardMoveSheetWidget extends ConsumerStatefulWidget {
  const CardMoveSheetWidget({
    super.key,
    required this.sourceDeckId,
    required this.cardIds,
  });

  final String sourceDeckId;
  final Set<String> cardIds;

  @override
  ConsumerState<CardMoveSheetWidget> createState() =>
      _CardMoveSheetWidgetState();
}

class _CardMoveSheetWidgetState extends ConsumerState<CardMoveSheetWidget> {
  static const int _skeletonRows = 3;

  /// One move at a time: a second tap before the first lands does nothing.
  var _isMoving = false;

  Future<void> _move(CardMoveTarget target) async {
    if (_isMoving) return;
    setState(() => _isMoving = true);
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .moveCards(cardIds: widget.cardIds, targetDeckId: target.id);
      if (!mounted) return;
      final l10n = context.l10n;
      final hasMoved = outcome is Ok;
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok() => l10n.cardMovedToast(widget.cardIds.length, target.name),
          Rejected(:final reason) => l10n.cardRejection(reason),
        },
      );
      Navigator.of(context).pop(hasMoved);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() => _isMoving = false);
      showMxSnackbar(context, message: context.l10n.failure(failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = cardMoveTargetsProvider(widget.sourceDeckId);
    return switch (ref.watch(provider)) {
      AsyncData(:final value) => MxDeckPickerSheet(
        title: l10n.cardMoveTitle,
        rule: l10n.cardMoveRule,
        candidates: [
          for (final target in value)
            MxPickerCandidate(
              label: cardDeckPathLabel([
                for (final entry in target.path) entry.name,
                target.name,
              ]),
              isEnabled: !_isMoving,
              onTap: () => unawaited(_move(target)),
            ),
        ],
        dismissLabel: value.isEmpty ? l10n.commonOk : l10n.commonCancel,
        onDismiss: () => Navigator.of(context).pop(false),
        emptyTitle: l10n.cardMoveEmptyTitle,
        emptyBody: l10n.cardMoveEmptyBody,
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
            MxSkeletonList(
              semanticLabel: context.l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
      ),
    };
  }
}
