import 'package:flutter/widgets.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

/// Asks before a changed form is left (ruling P4a-L5). Completes true to
/// discard, false to keep editing. [edited] names what changed on a saved
/// card (kit 09).
Future<bool> showCardDiscardDialog(
  BuildContext context, {
  required bool isNew,
  List<String> edited = const [],
}) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: isNew ? l10n.cardDiscardNewTitle : l10n.cardDiscardTitle,
    body: _body(l10n, isNew: isNew, edited: edited),
    cancelLabel: l10n.cardKeepEditing,
    confirmLabel: l10n.cardDiscard,
  );
}

/// What would be lost: a new card, or the parts of a saved one that
/// changed, in the person's words.
String _body(
  AppLocalizations l10n, {
  required bool isNew,
  required List<String> edited,
}) {
  if (isNew) return l10n.cardDiscardNewBody;
  if (edited.isEmpty) return l10n.cardDiscardBody;
  return l10n.cardDiscardEditedBody(_joined(l10n, edited));
}

/// "a", "a and b", "a, b and c".
String _joined(AppLocalizations l10n, List<String> parts) {
  if (parts.length == 1) return parts.single;
  final head = parts.sublist(0, parts.length - 1);
  return l10n.cardEditedPair(head.join(l10n.cardEditedSeparator), parts.last);
}
