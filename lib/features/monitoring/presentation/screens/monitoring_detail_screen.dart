import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/monitoring/domain/entities/log_record_entity.dart';
import 'package:memox/features/monitoring/domain/models/log_status_model.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_detail_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_detail_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:memox/features/monitoring/presentation/widgets/overlays/monitoring_status_sheet_widget.dart';
import 'package:memox/features/monitoring/presentation/widgets/sections/monitoring_detail_body_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 28's detail (monitoring spec §3.3): one log whole, and, for a
/// warning or an error of the server, Mark fixed or Reopen. [isLocal] reads
/// the device buffer instead of the server. Not in the kit; shaped with
/// Impeccable 2026-09-29.
class MonitoringDetailScreen extends ConsumerWidget {
  const MonitoringDetailScreen({
    super.key,
    required this.logId,
    required this.isLocal,
  });

  final String logId;
  final bool isLocal;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final provider = monitoringDetailControllerProvider(logId, isLocal);
    ref.listen(
      provider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final state = ref.watch(provider);
    final content = state.content;
    final record = content is MonitoringDetailLoaded ? content.record : null;
    return MxAppShell(
      appBar: MxAppBar(
        title: record?.event ?? l10n.monitoringDetailTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        actions: [
          if (record != null)
            MxIconButton(
              icon: AppIcons.copy,
              semanticLabel: l10n.monitoringCopy,
              onPressed: () => unawaited(_copy(context, record)),
            ),
        ],
      ),
      body: switch (content) {
        MonitoringDetailLoading() => MxScreenScroll(
          children: [
            MxSkeletonList(
              semanticLabel: l10n.commonLoading,
              rows: _skeletonRows,
            ),
          ],
        ),
        MonitoringDetailLoaded(:final record) => MonitoringDetailBodyWidget(
          record: record,
        ),
        MonitoringDetailGone() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.monitoringGoneTitle,
              body: l10n.monitoringGoneBody,
              icon: AppIcons.searchOff,
            ),
          ],
        ),
        MonitoringDetailFailed(:final failure) => MxScreenScroll(
          children: [_failure(context, ref, failure)],
        ),
      },
      footer: record != null && record.canTriage
          ? _triage(context, ref, record, state)
          : null,
    );
  }

  Widget _failure(
    BuildContext context,
    WidgetRef ref,
    MonitoringLoadFailure failure,
  ) {
    final l10n = context.l10n;
    void retry() => unawaited(
      ref
          .read(monitoringDetailControllerProvider(logId, isLocal).notifier)
          .retry(),
    );
    return switch (failure) {
      MonitoringLoadFailure.notAdmin => MxEmptyState(
        icon: AppIcons.lock,
        title: l10n.monitoringNotAdminTitle,
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      ),
      MonitoringLoadFailure.offline => MxErrorState(
        title: l10n.monitoringOfflineTitle,
        body: l10n.monitoringDetailOfflineBody,
        retryLabel: l10n.commonRetry,
        onRetry: retry,
      ),
      MonitoringLoadFailure.other => MxErrorState(
        title: l10n.monitoringDetailErrorTitle,
        body: l10n.libraryLoadErrorBody,
        retryLabel: l10n.commonRetry,
        onRetry: retry,
      ),
    };
  }

  Widget _triage(
    BuildContext context,
    WidgetRef ref,
    LogRecordEntity record,
    MonitoringDetailState state,
  ) {
    final l10n = context.l10n;
    final target = record.status == LogStatus.fixed
        ? LogStatus.open
        : LogStatus.fixed;
    return MxFooterBar(
      child: MxButton(
        label: target == LogStatus.fixed
            ? l10n.monitoringMarkFixed
            : l10n.monitoringReopen,
        isBlock: true,
        isLoading: state.changing != null,
        onPressed: state.changing == null
            ? () => unawaited(_change(context, ref, target))
            : null,
      ),
    );
  }

  Future<void> _change(
    BuildContext context,
    WidgetRef ref,
    LogStatus target,
  ) async {
    final controller = ref.read(
      monitoringDetailControllerProvider(logId, isLocal).notifier,
    );
    final note = await showMonitoringStatusSheet(context, target: target);
    if (note == null) return;
    await controller.setStatus(target, note: note);
  }

  Future<void> _copy(BuildContext context, LogRecordEntity record) async {
    final l10n = context.l10n;
    final text = const JsonEncoder.withIndent('  ').convert(record.toJson());
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showMxSnackbar(context, message: l10n.monitoringCopied);
  }

  void _say(
    BuildContext context,
    WidgetRef ref,
    MonitoringDetailNotice? notice,
  ) {
    final l10n = context.l10n;
    switch (notice) {
      case null:
        return;
      case StatusChanged(:final status):
        showMxSnackbar(
          context,
          message: status == LogStatus.fixed
              ? l10n.monitoringMarkedFixed
              : l10n.monitoringReopened,
        );
      case StatusChangeFailed(:final status, :final note):
        showMxSnackbar(
          context,
          message: l10n.monitoringStatusChangeFailed,
          actionLabel: l10n.commonRetry,
          onAction: () => unawaited(
            ref
                .read(
                  monitoringDetailControllerProvider(logId, isLocal).notifier,
                )
                .setStatus(status, note: note),
          ),
        );
    }
  }
}
