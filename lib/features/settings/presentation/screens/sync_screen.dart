import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/settings/presentation/controllers/sync_controller.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:memox/features/settings/presentation/widgets/sections/sync_problem_banners_widget.dart';
import 'package:memox/features/settings/presentation/widgets/sections/sync_status_section_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Screen 27, Sync (SB-U1, sync status spec §5.2): what sync did, what
/// waits, the last problem, and Sync now. Not in the kit (v3 predates the
/// server); shaped with Impeccable 2026-09-28.
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  static const int _skeletonRows = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    ref.listen(
      syncControllerProvider.select((state) => state.notice),
      (_, notice) => _say(context, ref, notice),
    );
    final task = ref.watch(syncControllerProvider.select((s) => s.task));
    void run(SyncTask next) =>
        unawaited(ref.read(syncControllerProvider.notifier).run(next));
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.syncTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: switch (ref.watch(syncStatusProvider)) {
        AsyncData(:final value?) => MxScreenScroll(
          children: [
            const SizedBox(height: AppSpacing.control),
            SyncProblemBannersWidget(status: value, task: task, onRun: run),
            SyncStatusSectionWidget(
              status: value,
              now: ref.watch(dayClockProvider).now(),
            ),
            const SizedBox(height: AppSpacing.gutter),
            MxButton(
              label: l10n.syncNow,
              icon: AppIcons.sync,
              isBlock: true,
              isLoading: task == SyncTask.syncNow,
              onPressed: task == null ? () => run(SyncTask.syncNow) : null,
            ),
          ],
        ),
        AsyncData() || AsyncError() => MxScreenScroll(
          children: [
            MxErrorState(
              title: l10n.syncLoadErrorTitle,
              body: l10n.libraryLoadErrorBody,
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(syncStatusProvider),
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
    );
  }

  void _say(BuildContext context, WidgetRef ref, SyncNotice? notice) {
    final l10n = context.l10n;
    switch (notice) {
      case null:
        return;
      case SyncSucceeded():
        showMxSnackbar(context, message: l10n.syncDone);
      case SyncNotSucceeded():
        showMxSnackbar(context, message: l10n.syncNotDone);
      case SyncKeptOnDevice():
        showMxSnackbar(context, message: l10n.syncKept);
      case SyncChangeFailed(:final task):
        showMxSnackbar(
          context,
          message: l10n.syncChangeFailed,
          actionLabel: l10n.commonRetry,
          onAction: () =>
              unawaited(ref.read(syncControllerProvider.notifier).run(task)),
        );
    }
  }
}
