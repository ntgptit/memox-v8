import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';

/// Screen 27's floating notice (sync status spec §5.2; owner ruling
/// 2026-09-28): the refused rows with Keep on this device and Try again, or
/// else the last failed run. Shown only when [shows] is true.
class SyncNoticeWidget extends StatelessWidget {
  const SyncNoticeWidget({
    super.key,
    required this.status,
    required this.task,
    required this.onRun,
  });

  final SyncStatus status;
  final SyncTask? task;
  final ValueChanged<SyncTask> onRun;

  static bool shows(SyncStatus status) =>
      status.rejectedCount > 0 || status.lastFailure != null;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failure = status.lastFailure;
    if (status.rejectedCount == 0 && failure != null) {
      return MxFloatingNotice(message: syncFailureSentence(l10n, failure.kind));
    }
    final isIdle = task == null;
    return MxFloatingNotice(
      message: l10n.syncRejectedTitle(status.rejectedCount),
      actions: [
        MxButton(
          label: l10n.syncKeepOnDevice,
          size: MxButtonSize.compact,
          tone: MxButtonTone.outline,
          isLoading: task == SyncTask.keep,
          onPressed: isIdle ? () => onRun(SyncTask.keep) : null,
        ),
        MxButton(
          label: l10n.syncTryAgain,
          size: MxButtonSize.compact,
          isLoading: task == SyncTask.retry,
          onPressed: isIdle ? () => onRun(SyncTask.retry) : null,
        ),
      ],
    );
  }
}
