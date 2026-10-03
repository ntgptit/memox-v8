import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// R3: starting here ends the open session of another deck. Completes true to
/// end it and start; false (Keep it, or dismissed) starts nothing. The
/// confirm is the warning tone: nothing is lost, a round is dropped.
Future<bool> showStudyEndOtherSessionDialog(
  BuildContext context, {
  required String deckName,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => StudyEndOtherSessionDialogWidget(deckName: deckName),
    ) ??
    false;

class StudyEndOtherSessionDialogWidget extends StatelessWidget {
  const StudyEndOtherSessionDialogWidget({super.key, required this.deckName});

  /// The deck whose session the start would end.
  final String deckName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.studyEndOtherTitle(deckName),
      body: l10n.studyEndOtherBody,
      actions: MxSheetActions(
        cancelLabel: l10n.studyEndOtherKeep,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.studyEndOtherConfirm,
        onConfirm: () => Navigator.of(context).pop(true),
        isWarning: true,
      ),
    );
  }
}
