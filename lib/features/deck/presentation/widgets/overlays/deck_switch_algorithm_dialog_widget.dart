import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// UC-DECK-002 steps 3–4 (spec A9): a switch asks first, without the
/// destructive tone, because nothing is deleted. True once confirmed.
Future<bool> showSwitchAlgorithmDialog(
  BuildContext context, {
  required String algorithm,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (dialogContext) {
        final l10n = dialogContext.l10n;
        return MxDialog(
          title: l10n.algorithmSwitchTitle(algorithm),
          body: l10n.algorithmSwitchBody,
          actions: MxSheetActions(
            cancelLabel: l10n.commonCancel,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            confirmLabel: l10n.algorithmSwitchConfirm,
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        );
      },
    ) ??
    false;
