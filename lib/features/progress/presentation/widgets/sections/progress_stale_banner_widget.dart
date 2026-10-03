import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// A refresh of Progress failed after figures were read: the figures stay and
/// this says so, local-first (2.50). Warning: nothing was lost.
class ProgressStaleBannerWidget extends StatelessWidget {
  const ProgressStaleBannerWidget({
    super.key,
    required this.onRetry,
    required this.isRetrying,
  });

  final VoidCallback onRetry;

  /// The reload runs: Retry spins.
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      title: l10n.progressStaleTitle,
      message: l10n.progressStaleBody,
      actions: [
        MxButton(
          label: l10n.commonRetry,
          size: MxButtonSize.compact,
          isLoading: isRetrying,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
