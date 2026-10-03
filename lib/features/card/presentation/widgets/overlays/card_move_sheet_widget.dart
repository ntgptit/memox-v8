import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/providers/card_move_targets_provider.dart';
import 'package:memox/features/card/presentation/widgets/support/card_deck_path_label_widget.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_bottom_sheet.dart';
import 'package:memox/shared/widgets/mx_deck_picker_sheet.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Picks the deck the cards of [cardIds] move to (UC-CARD-001 A5).
/// Completes true once the move landed. [onAllGone] runs when every card was
/// already gone (SP2a 2.19).
Future<bool> showCardMoveSheet(
  BuildContext context, {
  required String sourceDeckId,
  required Set<String> cardIds,
  VoidCallback? onAllGone,
}) async =>
    await showMxBottomSheet<bool>(
      context,
      builder: (_) => CardMoveSheetWidget(
        sourceDeckId: sourceDeckId,
        cardIds: cardIds,
        onAllGone: onAllGone,
      ),
    ) ??
    false;

/// The backend offers only eligible decks, each named by its path (ruling
/// P3-L8).
class CardMoveSheetWidget extends ConsumerStatefulWidget {
  const CardMoveSheetWidget({
    super.key,
    required this.sourceDeckId,
    required this.cardIds,
    this.onAllGone,
  });

  final String sourceDeckId;
  final Set<String> cardIds;
  final VoidCallback? onAllGone;

  @override
  ConsumerState<CardMoveSheetWidget> createState() =>
      _CardMoveSheetWidgetState();
}

class _CardMoveSheetWidgetState extends ConsumerState<CardMoveSheetWidget> {
  static const int _skeletonRows = 3;

  /// One move at a time: a second tap before the first lands does nothing.
  var _isMoving = false;

  /// The last move's failure, shown in the sheet until the next try
  /// (SP2b 2.27).
  Failure? _failure;

  Future<void> _move(CardMoveTarget target) async {
    if (_isMoving) return;
    setState(() {
      _isMoving = true;
      _failure = null;
    });
    try {
      final outcome = await ref
          .read(cardActionsControllerProvider.notifier)
          .moveCards(cardIds: widget.cardIds, targetDeckId: target.id);
      if (!mounted) return;
      final l10n = context.l10n;
      final hasMoved = outcome is Ok;
      if (outcome case Rejected(reason: CardRejection.notFound)) {
        widget.onAllGone?.call();
      }
      showMxSnackbar(
        context,
        message: switch (outcome) {
          Ok(:final value) => l10n.bulkToast(
            l10n.cardMovedToast(value.done.length, target.name),
            value.skipped.length,
          ),
          Rejected(:final reason) => l10n.cardBulkRejection(
            reason,
            widget.cardIds.length,
          ),
        },
        duration: bulkToastDuration(
          hasNews: switch (outcome) {
            Ok(:final value) => value.skipped.isNotEmpty,
            Rejected(:final reason) => isBulkAllGone(
              reason,
              widget.cardIds.length,
            ),
          },
        ),
      );
      Navigator.of(context).pop(hasMoved);
    } on Object catch (error, stack) {
      final failure = failureOfThrown(error, stack, library: 'card move');
      if (!mounted) return;
      setState(() {
        _isMoving = false;
        _failure = failure;
      });
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
        isHeld: _isMoving,
        banner: switch (_failure) {
          final failure? => MxInlineBanner(
            tone: MxBannerTone.warning,
            message: l10n.failure(failure),
          ),
          null => null,
        },
      ),
      AsyncError(:final isLoading) => MxBottomSheet(
        child: MxErrorState(
          title: l10n.libraryLoadErrorTitle,
          body: l10n.libraryLoadErrorBody,
          retryLabel: l10n.commonRetry,
          onRetry: () => ref.invalidate(provider),
          isRetrying: isLoading,
        ),
      ),
      _ => MxDeckPickerLoadingSheet(
        title: l10n.cardMoveTitle,
        rule: l10n.cardMoveRule,
        semanticLabel: l10n.commonLoading,
        rows: _skeletonRows,
      ),
    };
  }
}
