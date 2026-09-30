import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// An expired sign-in, where the screen owns it (account UI spec §5.5,
/// R2): 23 and 32. What is safe first, then Sign in.
class AccountReauthBannerWidget extends StatelessWidget {
  const AccountReauthBannerWidget({super.key, required this.onSignIn});

  /// Opens screen 30 in its reauth mode.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      message: l10n.accountReauthBanner,
      actions: [
        MxButton(
          label: l10n.accountSignIn,
          size: MxButtonSize.compact,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}
