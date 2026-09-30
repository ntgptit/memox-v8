import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's Sync section (SB-U1, sync status spec §5.1): one row naming
/// the state, opening screen 27.
class SettingsSyncSectionWidget extends StatelessWidget {
  const SettingsSyncSectionWidget({
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
    return MxSection(
      title: l10n.settingsSync,
      children: [
        MxSettingsRow(
          label: l10n.settingsSync,
          subtitle: syncStatusLine(l10n, status, now),
          icon: AppIcons.sync,
          iconTone: syncIsSettled(status)
              ? MxIconTileTone.success
              : MxIconTileTone.tinted,
          onTap: onOpenSync,
        ),
      ],
    );
  }
}
