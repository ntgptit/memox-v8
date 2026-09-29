import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_device_user_sheet_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_filter_sheets_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';

/// The Server tab's filters (monitoring spec §3.2): five chips in a row that
/// scrolls, each opening its sheet. A chip that holds a choice shows it.
class MonitoringFilterBarWidget extends StatelessWidget {
  const MonitoringFilterBarWidget({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final LogFilter filter;
  final ValueChanged<LogFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levels = [
      for (final level in LogLevel.values)
        if (filter.levels.contains(level)) monitoringLevelLabel(l10n, level),
    ];
    final statuses = [
      for (final status in LogStatus.values)
        if (filter.statuses.contains(status))
          monitoringStatusLabel(l10n, status),
    ];
    final ids = [?filter.deviceId, ?filter.userId];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Row(
        spacing: AppSpacing.control,
        children: [
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipLevel, levels),
            onPressed: () => unawaited(_pickLevels(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(
              l10n,
              l10n.monitoringChipStatus,
              statuses,
            ),
            onPressed: () => unawaited(_pickStatuses(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipCategory, [
              for (final category in filter.categories) category.name,
            ]),
            onPressed: () => unawaited(_pickCategories(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipTime, [
              if (filter.window != LogWindow.all)
                monitoringWindowLabel(l10n, filter.window),
            ]),
            onPressed: () => unawaited(_pickWindow(context)),
          ),
          MxChipTrigger(
            label: monitoringChipLabel(l10n, l10n.monitoringChipDevice, ids),
            onPressed: () => unawaited(_pickDeviceUser(context)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickLevels(BuildContext context) async {
    final picked = await showMonitoringLevelSheet(
      context,
      selected: filter.levels,
    );
    if (picked != null) onChanged(filter.withLevels(picked));
  }

  Future<void> _pickStatuses(BuildContext context) async {
    final picked = await showMonitoringStatusFilterSheet(
      context,
      selected: filter.statuses,
    );
    if (picked != null) onChanged(filter.withStatuses(picked));
  }

  Future<void> _pickCategories(BuildContext context) async {
    final picked = await showMonitoringCategorySheet(
      context,
      selected: filter.categories,
    );
    if (picked != null) onChanged(filter.withCategories(picked));
  }

  Future<void> _pickWindow(BuildContext context) async {
    final picked = await showMonitoringWindowSheet(
      context,
      selected: filter.window,
    );
    if (picked != null && picked.isNotEmpty) {
      onChanged(filter.withWindow(picked.single));
    }
  }

  Future<void> _pickDeviceUser(BuildContext context) async {
    final picked = await showMonitoringDeviceUserSheet(
      context,
      initial: (device: filter.deviceId ?? '', user: filter.userId ?? ''),
    );
    if (picked != null) {
      onChanged(filter.withDevice(picked.device).withUser(picked.user));
    }
  }
}
