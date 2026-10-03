import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before Study options is left with changes that Save has not written
/// (2.06), as the card editor asks before a changed form is left. Completes
/// true to discard, false to keep editing.
Future<bool> showStudyOptionsDiscardDialog(BuildContext context) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => const StudyOptionsDiscardDialogWidget(),
    ) ??
    false;

class StudyOptionsDiscardDialogWidget extends StatelessWidget {
  const StudyOptionsDiscardDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.studyOptionsDiscardTitle,
      body: l10n.studyOptionsDiscardBody,
      actions: MxSheetActions(
        cancelLabel: l10n.studyOptionsKeepEditing,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.studyOptionsDiscard,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
