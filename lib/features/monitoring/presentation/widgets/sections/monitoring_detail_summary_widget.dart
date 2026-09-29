import 'package:flutter/widgets.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/monitoring_detail_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';

/// The detail's Details, last on the page (monitoring spec §3.3; Impeccable
/// 2026-09-29 F1): who fixed it and when, the note, then where the log came
/// from. The level, status and time head the page, and the event is the app
/// bar's title, so none repeats here. A row whose value the log does not have
/// is left out: a buffered log may have no user, an open one no fixer (a
/// reopened log keeps who reopened it, which is not a fix).
class MonitoringDetailSummaryWidget extends StatelessWidget {
  const MonitoringDetailSummaryWidget({super.key, required this.record});

  final LogRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFixed = record.status == LogStatus.fixed;
    final fixedBy = isFixed ? record.statusChangedBy : null;
    final changedAt = isFixed ? record.statusChangedAt : null;
    final rows = [
      if (fixedBy != null)
        MonitoringDetailRowWidget(
          label: l10n.monitoringFieldFixedBy,
          value: fixedBy,
          copyLabel: l10n.monitoringCopyUser,
        ),
      if (changedAt != null)
        MonitoringDetailRowWidget(
          label: l10n.monitoringFieldFixedAt,
          value: monitoringFullTime(l10n, changedAt),
        ),
      if (_nonBlank(record.statusNote) case final note?)
        MonitoringDetailRowWidget(
          label: l10n.monitoringFieldNote,
          value: note,
          isStacked: true,
        ),
      MonitoringDetailRowWidget(
        label: l10n.monitoringFieldCategory,
        value: record.category,
      ),
      MonitoringDetailRowWidget(
        label: l10n.monitoringFieldSource,
        value: record.source,
      ),
      if (_nonBlank(record.deviceId) case final device?)
        MonitoringDetailRowWidget(
          label: l10n.monitoringFieldDevice,
          value: device,
          copyLabel: l10n.monitoringCopyDevice,
        ),
      if (_app case final app?)
        MonitoringDetailRowWidget(label: l10n.monitoringFieldApp, value: app),
      if (_platform case final platform?)
        MonitoringDetailRowWidget(
          label: l10n.monitoringFieldPlatform,
          value: platform,
        ),
      if (_nonBlank(record.userId) case final user?)
        MonitoringDetailRowWidget(
          label: l10n.monitoringFieldUser,
          value: user,
          copyLabel: l10n.monitoringCopyUser,
        ),
    ];
    return MxSection(title: l10n.monitoringSummary, children: rows);
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
