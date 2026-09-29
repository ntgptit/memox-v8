import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';

/// The head of a log's page (Impeccable 2026-09-29 F1): how bad it is and
/// whether it is dealt with, before anything else. The level's glyph tile
/// and the status pill match the list's row, with the full time under the
/// level.
class MonitoringDetailHeaderWidget extends StatelessWidget {
  const MonitoringDetailHeaderWidget({super.key, required this.record});

  final LogRecordEntity record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final status = record.status;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: Row(
        spacing: AppSpacing.gutter,
        children: [
          MxIconTile(
            icon: monitoringLevelIcon(record.level),
            tone: monitoringLevelTone(record.level),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.micro,
              children: [
                Text(
                  monitoringLevelLabel(l10n, record.level),
                  style: styles.settingsLabel,
                ),
                Text(
                  monitoringFullTime(l10n, record.occurredAt),
                  style: styles.rowDescription,
                ),
              ],
            ),
          ),
          if (status != null)
            MxBadge(
              label: monitoringStatusLabel(l10n, status),
              tone: monitoringStatusTone(status),
            ),
        ],
      ),
    );
  }
}
