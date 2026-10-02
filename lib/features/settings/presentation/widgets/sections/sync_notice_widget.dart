import 'dart:async';

import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/settings/presentation/states/sync_screen_state.dart';
import 'package:memox/features/settings/presentation/widgets/overlays/sync_keep_dialog_widget.dart';
import 'package:memox/features/settings/presentation/widgets/support/sync_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';

/// Screen 27's problem banner, under the status card and above Sync now
/// (critique 2026-09-30; was a floating notice, sync status spec §5.2): the
/// refused rows with Keep on this device and Try again, or else the last
/// failed run. Shown only when [shows] is true. The refused banner says why
/// and what Keep costs, and Keep asks first (critique 2026-09-30 part 1). A
/// failed run for want of a network is a neutral note: there is nothing to
/// fix, only to wait (critique 2026-10-02, F8).
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
      final sentence = syncFailureSentence(l10n, failure.kind);
      if (failure.kind == SyncFailureKind.network) {
        return MxNote(icon: AppIcons.offline, text: sentence);
      }
      return MxInlineBanner(tone: MxBannerTone.warning, message: sentence);
    }
    final isIdle = task == null;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      title: l10n.syncRejectedTitle(status.rejectedCount),
      message: l10n.syncRejectedBody,
      actions: [
        MxButton(
          label: l10n.syncKeepOnDevice,
          size: MxButtonSize.compact,
          tone: MxButtonTone.outline,
          isLoading: task == SyncTask.keep,
          onPressed: isIdle ? () => unawaited(_keep(context)) : null,
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

  Future<void> _keep(BuildContext context) async {
    if (!await showSyncKeepDialog(context, status.rejectedCount)) return;
    onRun(SyncTask.keep);
  }
}
