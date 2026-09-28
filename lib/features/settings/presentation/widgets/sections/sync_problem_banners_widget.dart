import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 27's problems (sync status spec §5.2): the refused rows first,
/// then the last failed run. Nothing when all is well.
class SyncProblemBannersWidget extends StatelessWidget {
  const SyncProblemBannersWidget({
    super.key,
    required this.status,
    required this.task,
    required this.onRun,
  });

  final SyncStatus status;
  final SyncTask? task;
  final ValueChanged<SyncTask> onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isIdle = task == null;
    final failure = status.lastFailure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status.rejectedCount > 0)
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: l10n.syncRejectedTitle(status.rejectedCount),
            message: l10n.syncRejectedBody,
            actions: [
              MxButton(
                label: l10n.syncTryAgain,
                size: MxButtonSize.compact,
                isLoading: task == SyncTask.retry,
                onPressed: isIdle ? () => onRun(SyncTask.retry) : null,
              ),
              MxButton(
                label: l10n.syncKeepOnDevice,
                size: MxButtonSize.compact,
                tone: MxButtonTone.outline,
                isLoading: task == SyncTask.keep,
                onPressed: isIdle ? () => onRun(SyncTask.keep) : null,
              ),
            ],
          ),
        if (failure != null)
          MxInlineBanner(
            tone: MxBannerTone.warning,
            message: syncFailureSentence(l10n, failure.kind),
          ),
      ],
    );
  }
}
