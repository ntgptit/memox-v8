import 'package:flutter/widgets.dart';
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
    final status = record.status;
    return Padding(
      padding: EdgeInsets.only(bottom: context.dimens.space16),
      child: Row(
        spacing: context.dimens.space12,
        children: [
          MxIconTile(
            icon: monitoringLevelIcon(record.level),
            tone: monitoringLevelTone(record.level),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: context.dimens.space4,
              children: [
                Text(
                  monitoringLevelLabel(l10n, record.level),
                  style: context.texts.itemTitle,
                ),
                Text(
                  monitoringFullTime(l10n, record.occurredAt),
                  style: context.texts.body.copyWith(
                    color: context.colors.mutedForeground,
                  ),
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
