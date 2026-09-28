import 'package:flutter/material.dart';
import 'package:memox/core/sync/sync_status.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// Screen 13's sync banner (SB-U1, sync status spec §5.3): refused rows, or
/// a change that waited over a day. No close button (R7); Details opens
/// screen 27.
class StudyHomeSyncBannerWidget extends StatelessWidget {
  const StudyHomeSyncBannerWidget({
    super.key,
    required this.status,
    required this.onOpenSync,
  });

  final SyncStatus status;
  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      message: status.rejectedCount > 0
          ? l10n.studyHomeSyncRejected(status.rejectedCount)
          : l10n.studyHomeSyncStale,
      actions: [
        MxButton(
          label: l10n.studyHomeSyncDetails,
          size: MxButtonSize.compact,
          onPressed: onOpenSync,
        ),
      ],
    );
  }
}
