import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// The Monitoring row (monitoring spec §3.1), in screen 23b's Logs section,
/// which only an admin reaches (users spec U2, settings hub spec D4);
/// `app/` hands it in.
class MonitoringEntryRowWidget extends StatelessWidget {
  const MonitoringEntryRowWidget({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSettingsRow(
      label: l10n.settingsMonitoring,
      subtitle: l10n.settingsMonitoringHint,
      icon: AppIcons.monitoring,
      onTap: onOpen,
    );
  }
}
