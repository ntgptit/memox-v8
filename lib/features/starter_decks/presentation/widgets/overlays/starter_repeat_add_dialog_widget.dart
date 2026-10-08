import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

/// Asks before a second copy of [title] (BR-STARTER-008; kit 03
/// `secondCopy`). Completes true to go on to the algorithm sheet.
Future<bool> showStarterRepeatAddDialog(
  BuildContext context, {
  required String title,
}) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.starterSecondCopyTitle,
    body: l10n.starterSecondCopyBody(title),
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.starterSecondCopyConfirm,
  );
}
