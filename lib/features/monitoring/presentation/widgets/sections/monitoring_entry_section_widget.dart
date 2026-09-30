import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's Admin section (monitoring spec §3.1): one row opening
/// Monitoring, shown only while the session's account is an admin, and gone
/// again if it stops being one. Settings takes it as a slot, so the two
/// features stay apart; `app/` composes them.
class MonitoringEntrySectionWidget extends ConsumerWidget {
  const MonitoringEntrySectionWidget({super.key, required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) return const SizedBox.shrink();
    final l10n = context.l10n;
    return MxSection(
      title: l10n.settingsAdmin,
      children: [
        MxSettingsRow(
          label: l10n.settingsMonitoring,
          subtitle: l10n.settingsMonitoringHint,
          icon: AppIcons.monitoring,
          onTap: onOpen,
        ),
      ],
    );
  }
}
