import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's first section (account UI spec §5.5): attach an account, or
/// the account attached. Settings takes it as a slot, so the two features
/// stay apart; `app/` composes them. A build that cannot sign in shows
/// nothing.
class AccountSettingsSectionWidget extends ConsumerWidget {
  const AccountSettingsSectionWidget({super.key, required this.onSignIn});

  /// Opens screen 30 in its link mode.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountCoordinatorProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final account = switch (ref.watch(authStateProvider).value) {
      Ready(:final user) when !user.isAnonymous => user,
      Validating(:final last?) when !last.isAnonymous => last,
      ReauthRequired(:final last) => last,
      _ => null,
    };
    final canLink = ref.watch(canLinkProvider);
    return MxSection(
      title: l10n.accountSection,
      children: [
        if (account == null)
          MxSettingsRow(
            label: l10n.accountSignIn,
            subtitle: canLink
                ? l10n.accountSignInHint
                : l10n.accountSignInLater,
            icon: AppIcons.account,
            isEnabled: canLink,
            onTap: canLink ? onSignIn : null,
          )
        else
          // P3b adds the chevron to screen 32 (plan ruling 5).
          MxSettingsRow(
            label: account.email ?? l10n.accountSignedIn,
            subtitle: l10n.accountSignedInHint,
            icon: AppIcons.account,
          ),
      ],
    );
  }
}
