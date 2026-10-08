import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';

/// Asks before refused changes are kept on this device only: they then never
/// sync (sync status spec R7; critique 2026-09-30 part 1, R4). Completes true
/// to keep; false (Cancel, Back or the scrim) writes nothing.
Future<bool> showSyncKeepDialog(BuildContext context, int count) {
  final l10n = context.l10n;
  return showMxConfirm(
    context,
    title: l10n.syncKeepTitle(count),
    body: l10n.syncKeepBody,
    cancelLabel: l10n.commonCancel,
    confirmLabel: l10n.syncKeepConfirm,
    // The changes then never sync: warned, not destroyed (critique
    // 2026-10-02, F8).
    isWarning: true,
  );
}
