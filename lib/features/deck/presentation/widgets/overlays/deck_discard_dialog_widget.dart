import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

/// Asks before a new root deck the person started is left (UC-DECK-001 A1).
/// Completes true to discard, false to keep editing.
Future<bool> showDeckDiscardDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.deckDiscardTitle,
    body: l10n.deckDiscardBody,
    cancelLabel: l10n.deckKeepEditing,
    confirmLabel: l10n.deckDiscard,
  );
}
