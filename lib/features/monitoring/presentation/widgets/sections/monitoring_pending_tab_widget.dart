import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/logging/log_entry.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/monitoring/domain/models/pending_logs_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/pending_logs_controller.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/log_row_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_filter_sheets_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/support/monitoring_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_chip_trigger.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// The Not sent tab (monitoring spec §3.2): the device buffer, read-only, so
/// it works offline. Only the level can be filtered.
class MonitoringPendingTabWidget extends ConsumerWidget {
  const MonitoringPendingTabWidget({super.key, required this.onOpenLog});

  final ValueChanged<String> onOpenLog;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(pendingLogsControllerProvider);
    final levels = [
      for (final level in LogLevel.values)
        if (state.levels.contains(level)) monitoringLevelLabel(l10n, level),
    ];
    return Column(
      children: [
        // Only while logs wait: an empty buffer says so below.
        if (state.logs.value case final logs? when logs.total > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.gutter,
              AppSpacing.grouped,
              AppSpacing.gutter,
              0,
            ),
            child: MxNote(text: l10n.monitoringPendingNote),
          ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            child: MxChipTrigger(
              label: monitoringChipLabel(
                l10n,
                l10n.monitoringChipLevel,
                levels,
              ),
              onPressed: () => unawaited(_pickLevels(context, ref)),
            ),
          ),
        ),
        Expanded(
          child: switch (state.logs) {
            AsyncData(:final value) => _rows(context, ref, value),
            AsyncError() => MxScreenScroll(
              children: [
                MxErrorState(
                  title: l10n.monitoringErrorTitle,
                  body: l10n.libraryLoadErrorBody,
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(pendingLogsControllerProvider),
                ),
              ],
            ),
            _ => MxScreenScroll(
              children: [
                MxSkeletonList(
                  semanticLabel: l10n.commonLoading,
                  rows: _skeletonRows,
                ),
              ],
            ),
          },
        ),
      ],
    );
  }

  Widget _rows(BuildContext context, WidgetRef ref, PendingLogs logs) {
    final l10n = context.l10n;
    if (logs.items.isEmpty) {
      final isBufferEmpty = logs.total == 0;
      return MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxEmptyState(
            icon: isBufferEmpty ? AppIcons.learned : AppIcons.searchOff,
            title: isBufferEmpty
                ? l10n.monitoringPendingNoneTitle
                : l10n.monitoringPendingFilteredTitle,
            body: isBufferEmpty
                ? l10n.monitoringPendingNoneBody
                : l10n.monitoringPendingFilteredBody,
            tone: isBufferEmpty
                ? MxEmptyStateTone.success
                : MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      );
    }
    final now = ref.watch(dayClockProvider).now();
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        // The tab states the buffer's count; the list counts what it shows
        // at the chosen levels (critique 2026-09-30 part 3b).
        MxListSectionHeader(
          label: l10n.monitoringPendingCount(logs.items.length),
        ),
        for (final (index, log) in logs.items.indexed)
          LogRowWidget(
            log: log,
            now: now,
            onTap: () => onOpenLog(log.id),
            hasDivider: index < logs.items.length - 1,
          ),
      ],
    );
  }

  Future<void> _pickLevels(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(pendingLogsControllerProvider.notifier);
    final picked = await showMonitoringLevelSheet(
      context,
      selected: ref.read(pendingLogsControllerProvider).levels,
    );
    if (picked != null) controller.setLevels(picked);
  }
}
