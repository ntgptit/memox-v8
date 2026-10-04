import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before a session is stopped (spec D8, owner ruling 2026-09-27).
/// Completes true to stop; false (Keep studying, or dismissed) keeps it.
Future<bool> showStudyExitDialog(BuildContext context) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => const StudyExitDialogWidget(),
    ) ??
    false;

class StudyExitDialogWidget extends StatelessWidget {
  const StudyExitDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.studyExitTitle,
      body: l10n.studyExitBody,
      actions: MxSheetActions(
        cancelLabel: l10n.studyExitKeep,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.studyExitStop,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
