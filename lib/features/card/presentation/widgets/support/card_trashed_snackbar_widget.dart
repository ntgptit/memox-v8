import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/card/presentation/controllers/card_actions_controller.dart';
import 'package:memox/features/card/presentation/widgets/support/card_rejection_message_widget.dart';
import 'package:memox/l10n/bulk_message.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Says cards went to the Trash (FE-B1 D3, D4). One card, named by its
/// [front] when the caller has it, or several: Undo for 8 seconds puts them
/// all back (BR-TRASH-008, SP2a 2.20). [skipped] is how many of the selected
/// cards were already gone (SP2a 2.19). [onOpenTrash] rides on a refused
/// Undo's toast.
///
/// The toast outlives the dialog and often the screen that showed it, so it
/// lives on the root navigator and Undo reads the app's container, not a
/// widget's.
void showCardsTrashedSnackbar(
  BuildContext context, {
  required List<String> batchIds,
  String? front,
  VoidCallback? onOpenTrash,
  int skipped = 0,
}) {
  final host = Navigator.of(context, rootNavigator: true).context;
  final l10n = context.l10n;
  final container = ProviderScope.containerOf(context, listen: false);
  final message = switch (batchIds) {
    [_] when front != null => l10n.cardTrashedToast(front),
    _ => l10n.bulkToast(l10n.cardsTrashedToast(batchIds.length), skipped),
  };
  showMxSnackbar(
    host,
    message: message,
    actionLabel: l10n.commonUndo,
    duration: AppDurations.undoWindow,
    onAction: () =>
        unawaited(_undo(host, container, batchIds.toSet(), onOpenTrash)),
  );
}

/// The cards go back into their decks; a refusal says why and leaves them in
/// the Trash (UC-TRASH-001 A1, E3).
Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  Set<String> batchIds,
  VoidCallback? onOpenTrash,
) async {
  try {
    final outcome = await container
        .read(cardActionsControllerProvider.notifier)
        .undoCardDeletion(batchIds: batchIds);
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
