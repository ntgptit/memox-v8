import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Says cards went to the Trash (FE-B1 D3, D4). One card, named by its
/// [front] when the caller has it, gets Undo for 8 seconds; several get
/// [onOpenTrash] instead (BR-TRASH-008), as a refused Undo does.
///
/// The toast outlives the dialog and often the screen that showed it, so it
/// lives on the root navigator and Undo reads the app's container, not a
/// widget's.
void showCardsTrashedSnackbar(
  BuildContext context, {
  required List<String> batchIds,
  String? front,
  VoidCallback? onOpenTrash,
}) {
  final host = Navigator.of(context, rootNavigator: true).context;
  final l10n = context.l10n;
  if (batchIds case [final batchId]) {
    final container = ProviderScope.containerOf(context, listen: false);
    showMxSnackbar(
      host,
      message: front == null
          ? l10n.cardsTrashedToast(1)
          : l10n.cardTrashedToast(front),
      actionLabel: l10n.commonUndo,
      duration: AppDurations.undoWindow,
      onAction: () => unawaited(_undo(host, container, batchId, onOpenTrash)),
    );
    return;
  }
  showMxSnackbar(
    host,
    message: l10n.cardsTrashedToast(batchIds.length),
    actionLabel: onOpenTrash == null ? null : l10n.commonOpenTrash,
    onAction: onOpenTrash,
  );
}

/// The card goes back into its deck; a refusal says why and leaves it in
/// the Trash (UC-TRASH-001 A1, E3).
Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  String batchId,
  VoidCallback? onOpenTrash,
) async {
  try {
    final outcome = await container
        .read(cardActionsControllerProvider.notifier)
        .undoCardDeletion(batchId: batchId);
    if (outcome case Rejected(:final reason) when host.mounted) {
      final l10n = host.l10n;
      showMxSnackbar(
        host,
        message: l10n.cardUndoRefused(l10n.cardRejection(reason)),
        actionLabel: onOpenTrash == null ? null : l10n.commonOpenTrash,
        onAction: onOpenTrash,
      );
    }
  } on Failure catch (failure) {
    if (host.mounted) showMxSnackbar(host, message: host.l10n.failure(failure));
  }
}
