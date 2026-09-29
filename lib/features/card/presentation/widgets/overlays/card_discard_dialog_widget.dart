import 'package:flutter/material.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a changed form is left (ruling P4a-L5). Completes true to
/// discard, false to keep editing. [edited] names what changed on a saved
/// card (kit 09).
Future<bool> showCardDiscardDialog(
  BuildContext context, {
  required bool isNew,
  List<String> edited = const [],
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => CardDiscardDialogWidget(isNew: isNew, edited: edited),
    ) ??
    false;

class CardDiscardDialogWidget extends StatelessWidget {
  const CardDiscardDialogWidget({
    super.key,
    required this.isNew,
    this.edited = const [],
  });

  /// A card not saved yet, rather than changes to a saved one.
  final bool isNew;

  /// The parts of a saved card that changed, in the person's words.
  final List<String> edited;

  /// "a", "a and b", "a, b and c".
  static String _joined(AppLocalizations l10n, List<String> parts) {
    if (parts.length == 1) return parts.single;
    final head = parts.sublist(0, parts.length - 1);
    return l10n.cardEditedPair(head.join(l10n.cardEditedSeparator), parts.last);
  }

  String _body(AppLocalizations l10n) {
    if (isNew) return l10n.cardDiscardNewBody;
    if (edited.isEmpty) return l10n.cardDiscardBody;
    return l10n.cardDiscardEditedBody(_joined(l10n, edited));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: isNew ? l10n.cardDiscardNewTitle : l10n.cardDiscardTitle,
      body: _body(l10n),
      actions: MxSheetActions(
        cancelLabel: l10n.cardKeepEditing,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.cardDiscard,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
