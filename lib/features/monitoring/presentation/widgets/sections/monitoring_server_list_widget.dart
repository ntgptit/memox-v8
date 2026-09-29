import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/monitoring/presentation/controllers/monitoring_list_controller.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_list_state.dart';
import 'package:memox/features/monitoring/presentation/states/monitoring_load_failure_state.dart';
import 'package:memox/features/monitoring/presentation/widgets/items/log_row_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The Server tab's body: one widget per state of monitoring spec §3.4.
class MonitoringServerListWidget extends ConsumerWidget {
  const MonitoringServerListWidget({
    super.key,
    required this.onOpenLog,
    required this.onOpenNotSent,
    required this.onClearFilters,
  });

  final ValueChanged<String> onOpenLog;
  final VoidCallback onOpenNotSent;
  final VoidCallback onClearFilters;

  static const int _skeletonRows = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(monitoringListControllerProvider);
    final controller = ref.watch(monitoringListControllerProvider.notifier);
    return switch (state.content) {
      MonitoringListLoading() => MxScreenScroll(
        children: [
          MxSkeletonList(
            semanticLabel: l10n.commonLoading,
            rows: _skeletonRows,
          ),
        ],
      ),
      MonitoringListFailed(:final failure) => MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          _failure(context, failure, controller),
        ],
      ),
      MonitoringListLoaded(:final items) when items.isEmpty => _Refreshable(
        onRefresh: controller.refresh,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            if (state.filter.isDefault)
              MxEmptyState(
                icon: AppIcons.learned,
                title: l10n.monitoringEmptyTitle,
                body: l10n.monitoringEmptyBody,
                tone: MxEmptyStateTone.success,
                isCompact: true,
              )
            else
              MxEmptyState(
                icon: AppIcons.searchOff,
                title: l10n.monitoringNoMatchTitle,
                tone: MxEmptyStateTone.neutral,
                isCompact: true,
                actionLabel: l10n.monitoringClearFilters,
                onAction: onClearFilters,
              ),
          ],
        ),
      ),
      final MonitoringListLoaded loaded => _Rows(
        loaded: loaded,
        isDefaultFilter: state.filter.isDefault,
        onOpenLog: onOpenLog,
      ),
    };
  }

  Widget _failure(
    BuildContext context,
    MonitoringLoadFailure failure,
    MonitoringListController controller,
  ) {
    final l10n = context.l10n;
    return switch (failure) {
      MonitoringLoadFailure.notAdmin => MxEmptyState(
        icon: AppIcons.lock,
        title: l10n.monitoringNotAdminTitle,
        tone: MxEmptyStateTone.neutral,
        isCompact: true,
      ),
      MonitoringLoadFailure.offline => Column(
        spacing: AppSpacing.grouped,
        children: [
          MxErrorState(
            title: l10n.monitoringOfflineTitle,
            body: l10n.monitoringOfflineBody,
            retryLabel: l10n.commonRetry,
            onRetry: controller.retry,
          ),
          MxButton(
            label: l10n.monitoringOpenNotSent,
            tone: MxButtonTone.outline,
            icon: AppIcons.inbox,
            isBlock: true,
            onPressed: onOpenNotSent,
          ),
        ],
      ),
      MonitoringLoadFailure.other => MxErrorState(
        title: l10n.monitoringErrorTitle,
        body: l10n.libraryLoadErrorBody,
        retryLabel: l10n.commonRetry,
        onRetry: controller.retry,
      ),
    };
  }
}

/// The rows read so far, the count above them and the state of the end
/// below. The next page is asked for when the last ten rows come into view;
/// a failed page waits for its Retry instead of asking again on every
/// scroll.
class _Rows extends ConsumerWidget {
  const _Rows({
    required this.loaded,
    required this.isDefaultFilter,
    required this.onOpenLog,
  });

  final MonitoringListLoaded loaded;
  final bool isDefaultFilter;
  final ValueChanged<String> onOpenLog;

  static const double _prefetchExtent = 10 * AppSize.listRowMin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.watch(monitoringListControllerProvider.notifier);
    final now = ref.watch(dayClockProvider).now();
    final count = loaded.items.length;
    final hasMore = loaded.next != null;
    final header = switch ((isDefaultFilter, hasMore)) {
      (true, false) => l10n.monitoringCountOpen(count),
      (true, true) => l10n.monitoringCountOpenMore(count),
      (false, false) => l10n.monitoringCountLogs(count),
      (false, true) => l10n.monitoringCountLogsMore(count),
    };
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (loaded.more == MonitoringMore.idle &&
            hasMore &&
            notification.metrics.extentAfter < _prefetchExtent) {
          unawaited(controller.loadMore());
        }
        return false;
      },
      child: _Refreshable(
        onRefresh: controller.refresh,
        child: MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            MxListSectionHeader(label: header),
            for (final (index, log) in loaded.items.indexed)
              LogRowWidget(
                log: log,
                now: now,
                onTap: () => onOpenLog(log.id),
                hasDivider: index < count - 1,
              ),
            const SizedBox(height: AppSpacing.grouped),
            _End(loaded: loaded, onRetry: controller.loadMore),
          ],
        ),
      ),
    );
  }
}

/// The spinner under the last row while a page loads, the retry when it
/// failed, "No more logs" at the end.
class _End extends StatelessWidget {
  const _End({required this.loaded, required this.onRetry});

  final MonitoringListLoaded loaded;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch ((loaded.more, loaded.next)) {
      (MonitoringMore.loading, _) => Center(
        child: MxSpinner(semanticLabel: l10n.commonLoading),
      ),
      (MonitoringMore.failed, _) => MxInlineBanner(
        tone: MxBannerTone.danger,
        message: l10n.monitoringLoadMoreFailed,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            size: MxButtonSize.compact,
            onPressed: () => unawaited(onRetry()),
          ),
        ],
      ),
      (_, null) => Text(
        l10n.monitoringNoMore,
        textAlign: TextAlign.center,
        style: context.textStyles.footerCaption,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Pull to refresh over a list that may be shorter than the screen: the
/// scroll accepts a drag whatever its length, on top of the platform's own
/// physics.
class _Refreshable extends StatelessWidget {
  const _Refreshable({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final behavior = ScrollConfiguration.of(context);
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ScrollConfiguration(
        behavior: behavior.copyWith(
          physics: AlwaysScrollableScrollPhysics(
            parent: behavior.getScrollPhysics(context),
          ),
        ),
        child: child,
      ),
    );
  }
}
