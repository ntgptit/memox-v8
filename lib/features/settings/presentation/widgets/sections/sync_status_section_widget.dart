import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 27's Status section (sync status spec §5.2): the last success and
/// what waits.
class SyncStatusSectionWidget extends StatelessWidget {
  const SyncStatusSectionWidget({
    super.key,
    required this.status,
    required this.now,
  });

  final SyncStatus status;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final success = status.lastSuccessAt;
    return MxSection(
      title: l10n.syncStatusSection,
      note: l10n.syncNote,
      children: [
        MxSettingsRow(
          label: l10n.syncLastSynced,
          subtitle: success == null
              ? l10n.syncLastSyncedNever
              : syncTimeLabel(l10n, success, now),
        ),
        MxSettingsRow(
          label: l10n.syncWaiting,
          subtitle: status.pendingCount == 0
              ? l10n.syncWaitingNone
              : l10n.syncWaitingCount(status.pendingCount),
        ),
      ],
    );
  }
}
