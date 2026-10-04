import 'package:flutter/material.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/entities/log_summary_entity.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// One log of a list (monitoring spec §3.2): the level as a glyph on a tile,
/// the event, the message's first line, the time and, for a warning or an
/// error of the server, its status. A screen reader hears one sentence.
/// The time column keeps the pill's room on every row, so the times line up.
class LogRowWidget extends StatelessWidget {
  const LogRowWidget({
    super.key,
    required this.log,
    required this.now,
    required this.onTap,
    this.hasDivider = true,
    this.statusShownByFilter,
  });

  final LogSummaryEntity log;
  final DateTime now;
  final VoidCallback onTap;
  final bool hasDivider;

  /// The one status the Status filter holds, if it holds one: a row with it
  /// leaves it to the chip and the header (critique 2026-09-30 part 3b).
  /// TalkBack still hears the status.
  final LogStatus? statusShownByFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final time = monitoringRowTime(l10n, log.occurredAt, now);
    final level = monitoringLevelLabel(l10n, log.level);
    final status = log.status;
    final statusLabel = status == null
        ? null
        : monitoringStatusLabel(l10n, status);
    return Semantics(
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      label: statusLabel == null
          ? l10n.monitoringRowLabelNoStatus(level, log.event, time)
          : l10n.monitoringRowLabel(level, log.event, time, statusLabel),
      child: MxListRow(
        leading: MxIconTile(
          icon: monitoringLevelIcon(log.level),
          tone: monitoringLevelTone(log.level),
        ),
        title: log.event,
        subtitle: log.subtitle,
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: AppSpacing.micro,
          children: [
            Text(time, style: context.textStyles.counter),
            if (status != statusShownByFilter &&
                status != null &&
                statusLabel != null)
              MxBadge(label: statusLabel, tone: monitoringStatusTone(status))
            else
              // Holds the pill's height, so every row's time sits at one
              // height (Impeccable 2026-09-29 F5).
              Visibility.maintain(
                visible: false,
                child: MxBadge(label: l10n.monitoringStatusOpen),
              ),
          ],
        ),
        onTap: onTap,
        hasDivider: hasDivider,
      ),
    );
  }
}
