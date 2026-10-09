import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

/// Asks before a session is stopped (spec D8, owner ruling 2026-09-27).
/// Completes true to stop; false (Keep studying, or dismissed) keeps it.
Future<bool> showStudyExitDialog(BuildContext context) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.studyExitTitle,
    body: l10n.studyExitBody,
    cancelLabel: l10n.studyExitKeep,
    confirmLabel: l10n.studyExitStop,
  );
}
