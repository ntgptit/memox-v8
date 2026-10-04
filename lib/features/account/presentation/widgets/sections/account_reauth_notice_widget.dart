import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';

/// An expired sign-in over a screen that does not own it (account UI spec
/// §5.7, R2): Study home, in the sync notice's form.
class AccountReauthNoticeWidget extends StatelessWidget {
  const AccountReauthNoticeWidget({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxFloatingNotice(
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
