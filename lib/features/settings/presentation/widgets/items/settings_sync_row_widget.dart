import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// The hub's Sync row (SB-U1, sync status spec §5.1): names the state, the
/// tone on its tile, opens screen 27. Settings draws it in "Account & sync"
/// (settings hub spec D2).
class SettingsSyncRowWidget extends StatelessWidget {
  const SettingsSyncRowWidget({
    super.key,
    required this.status,
    required this.now,
    required this.onOpenSync,
  });

  final SyncStatus status;
  final DateTime now;
  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSettingsRow(
      label: l10n.settingsSync,
      subtitle: syncStatusLine(l10n, status, now),
      icon: AppIcons.sync,
      iconTone: switch (status) {
        _ when syncNeedsAttention(status) => MxIconTileTone.warning,
        _ when syncIsSettled(status) => MxIconTileTone.success,
        _ => MxIconTileTone.tinted,
      },
      onTap: onOpenSync,
    );
  }
}
