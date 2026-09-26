import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/theme/foundations/app_durations.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/presentation/controllers/deck_actions_controller.dart';
import 'package:memox/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Says a deck went to the Trash, with what went with it, and offers Undo
/// for 8 seconds (FE-B1 D3, BR-TRASH-008).
///
/// The toast outlives the dialog and often the screen that showed it, so it
/// lives on the root navigator and Undo reads the app's container, not a
/// widget's.
void showDeckTrashedSnackbar(
  BuildContext context, {
  required String deckName,
  required DeckDeletionSummary summary,
  required String batchId,
}) {
  final host = Navigator.of(context, rootNavigator: true).context;
  final container = ProviderScope.containerOf(context, listen: false);
  final l10n = context.l10n;
  showMxSnackbar(
    host,
    message: l10n.deckTrashedToast(
      deckName,
      summary.subDeckCount,
      summary.cardCount,
    ),
    actionLabel: l10n.commonUndo,
    duration: AppDurations.undoWindow,
    onAction: () => unawaited(_undo(host, container, batchId)),
  );
}

/// The deck goes back where it was; a refusal says why and leaves it in
/// the Trash (UC-TRASH-001 A1, E3).
Future<void> _undo(
  BuildContext host,
  ProviderContainer container,
  String batchId,
) async {
  try {
    final outcome = await container
        .read(deckActionsControllerProvider.notifier)
        .undoDeckDeletion(batchId: batchId);
    if (outcome case Rejected(:final reason) when host.mounted) {
      final l10n = host.l10n;
      showMxSnackbar(
        host,
        message: l10n.deckUndoRefused(l10n.deckRejection(reason)),
      );
    }
  } on Failure catch (failure) {
    if (host.mounted) showMxSnackbar(host, message: host.l10n.failure(failure));
  }
}
