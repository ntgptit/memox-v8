import 'package:flutter/widgets.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// The detail's key/value rows (monitoring spec §3.3). A row whose value the
/// log does not have is left out: a buffered log has no user, an info has no
/// status.
class MonitoringDetailSummaryWidget extends StatelessWidget {
  const MonitoringDetailSummaryWidget({super.key, required this.record});

  final LogRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <(String, String?)>[
      (l10n.monitoringFieldEvent, record.event),
      (l10n.monitoringFieldLevel, monitoringLevelLabel(l10n, record.level)),
      (l10n.monitoringFieldStatus, _status(l10n)),
      (l10n.monitoringFieldNote, _nonBlank(record.statusNote)),
      (l10n.monitoringFieldTime, monitoringFullTime(l10n, record.occurredAt)),
      (l10n.monitoringFieldCategory, record.category),
      (l10n.monitoringFieldSource, record.source),
      (l10n.monitoringFieldDevice, record.deviceId),
      (l10n.monitoringFieldApp, _app),
      (l10n.monitoringFieldPlatform, _platform),
      (l10n.monitoringFieldUser, record.userId),
    ];
    return MxSection(
      title: l10n.monitoringSummary,
      children: [
        for (final (label, value) in rows)
          if (value != null) MxSettingsRow(label: label, subtitle: value),
      ],
    );
  }

  /// "Open", or "Fixed by {user} · {date}" once someone marked it.
  String? _status(AppLocalizations l10n) {
    final status = record.status;
    if (status == null) return null;
    final by = record.statusChangedBy;
    final at = record.statusChangedAt;
    if (status == LogStatus.fixed && by != null && at != null) {
      return l10n.monitoringFixedBy(by, monitoringFullTime(l10n, at));
    }
    return monitoringStatusLabel(l10n, status);
  }

  String? get _app {
    final version = _nonBlank(record.appVersion);
    if (version == null) return null;
    final build = _nonBlank(record.buildNumber);
    return build == null ? version : '$version ($build)';
  }

  String? get _platform {
    final parts = [?_nonBlank(record.platform), ?_nonBlank(record.osVersion)];
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String? _nonBlank(String? text) =>
      text == null || text.trim().isEmpty ? null : text;
}
