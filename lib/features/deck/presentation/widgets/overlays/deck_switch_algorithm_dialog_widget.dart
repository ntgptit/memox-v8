import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

/// UC-DECK-002 steps 3–4 (spec A9): a switch asks first, without the
/// destructive tone, because nothing is deleted. True once confirmed.
Future<bool> showSwitchAlgorithmDialog(
  BuildContext context, {
  required String algorithm,
}) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.algorithmSwitchTitle(algorithm),
    body: l10n.algorithmSwitchBody,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.algorithmSwitchConfirm,
  );
}
