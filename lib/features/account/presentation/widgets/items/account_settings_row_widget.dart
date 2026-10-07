import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// The hub's account row (account UI spec §5.5; settings hub spec D7):
/// attach an account, or the account attached, which opens screen 32.
/// Settings draws the "Account & sync" section; `app/` puts this row in
/// it. A build that cannot sign in shows nothing.
class AccountSettingsRowWidget extends ConsumerWidget {
  const AccountSettingsRowWidget({
    super.key,
    required this.onSignIn,
    required this.onOpenAccount,
  });

  /// Opens screen 30 in its link mode.
  final VoidCallback onSignIn;

  /// Opens screen 32 (spec §5.5).
  final VoidCallback onOpenAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountCoordinatorProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final account = ref.watch(deviceAccountProvider);
    final canLink = ref.watch(canLinkProvider);
    if (account == null) {
      return MxSettingsRow(
        label: l10n.accountSignIn,
        subtitle: canLink ? l10n.accountSignInHint : l10n.accountSignInLater,
        icon: AppIcons.account,
        isEnabled: canLink,
        onTap: canLink ? onSignIn : null,
      );
    }
    return MxSettingsRow(
      label: account.email ?? l10n.accountSignedIn,
      subtitle: l10n.accountSignedInHint,
      icon: AppIcons.account,
      onTap: onOpenAccount,
    );
  }
}
