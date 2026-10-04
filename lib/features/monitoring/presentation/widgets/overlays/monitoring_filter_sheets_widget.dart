import 'package:flutter/widgets.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/features/monitoring/domain/models/log_filter_model.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/domain/models/log_window_model.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_choice_sheet_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';

/// The Level sheet: any of the four levels. Reset is the default, warning
/// and error.
Future<Set<LogLevel>?> showMonitoringLevelSheet(
  BuildContext context, {
  required Set<LogLevel> selected,
}) {
  final l10n = context.l10n;
  return showMonitoringChoiceSheet<LogLevel>(
    context,
    title: l10n.monitoringChipLevel,
    choices: [
      for (final level in LogLevel.values)
        MonitoringChoice(level, monitoringLevelLabel(l10n, level)),
    ],
    selected: selected,
    resetTo: LogFilter.defaultLevels,
    isMulti: true,
  );
}

/// The Status sheet: open, fixed or both. Reset is the default, open.
Future<Set<LogStatus>?> showMonitoringStatusFilterSheet(
  BuildContext context, {
  required Set<LogStatus> selected,
}) {
  final l10n = context.l10n;
  return showMonitoringChoiceSheet<LogStatus>(
    context,
    title: l10n.monitoringChipStatus,
    choices: [
      for (final status in LogStatus.values)
        MonitoringChoice(status, monitoringStatusLabel(l10n, status)),
    ],
    selected: selected,
    resetTo: LogFilter.defaultStatuses,
    isMulti: true,
  );
}

/// The Category sheet: every value of [LogCategory], by the code the logs
/// carry, so a category another branch adds shows without a change here.
/// Reset is every category.
Future<Set<LogCategory>?> showMonitoringCategorySheet(
  BuildContext context, {
  required Set<LogCategory> selected,
}) => showMonitoringChoiceSheet<LogCategory>(
  context,
  title: context.l10n.monitoringChipCategory,
  choices: [
    for (final category in LogCategory.values)
      MonitoringChoice(category, category.name),
  ],
  selected: selected,
  resetTo: const {},
  isMulti: true,
);

/// The Time sheet: one window, from the last hour to all time.
Future<Set<LogWindow>?> showMonitoringWindowSheet(
  BuildContext context, {
  required LogWindow selected,
}) {
  final l10n = context.l10n;
  return showMonitoringChoiceSheet<LogWindow>(
    context,
    title: l10n.monitoringChipTime,
    choices: [
      for (final window in LogWindow.values)
        MonitoringChoice(window, monitoringWindowLabel(l10n, window)),
    ],
    selected: {selected},
    resetTo: const {LogWindow.all},
    isMulti: false,
  );
}
