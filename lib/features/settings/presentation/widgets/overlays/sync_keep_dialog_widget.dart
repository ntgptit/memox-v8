import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before refused changes are kept on this device only: they then never
/// sync (sync status spec R7; critique 2026-09-30 part 1, R4). Completes true
/// to keep; false (Cancel, Back or the scrim) writes nothing.
Future<bool> showSyncKeepDialog(BuildContext context, int count) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => SyncKeepDialogWidget(count: count),
    ) ??
    false;

class SyncKeepDialogWidget extends StatelessWidget {
  const SyncKeepDialogWidget({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxDialog(
      title: l10n.syncKeepTitle(count),
      body: l10n.syncKeepBody,
      actions: MxSheetActions(
        cancelLabel: l10n.commonCancel,
        onCancel: () => Navigator.of(context).pop(false),
        confirmLabel: l10n.syncKeepConfirm,
        // The changes then never sync: warned, not destroyed (critique
        // 2026-10-02, F8).
        isWarning: true,
        onConfirm: () => Navigator.of(context).pop(true),
      ),
    );
  }
}
