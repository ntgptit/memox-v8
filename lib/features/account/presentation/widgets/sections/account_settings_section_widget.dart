import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 23's first section (account UI spec §5.5): attach an account, or
/// the account attached, which opens screen 32; an expired sign-in's
/// banner first (P3b). Settings takes it as a slot, so the two features
/// stay apart; `app/` composes them. A build that cannot sign in shows
/// nothing.
class AccountSettingsSectionWidget extends ConsumerWidget {
  const AccountSettingsSectionWidget({
    super.key,
    required this.onSignIn,
    required this.onOpenAccount,
    required this.onSignInAgain,
  });

  /// Opens screen 30 in its link mode.
  final VoidCallback onSignIn;

  /// Opens screen 32 (spec §5.5).
  final VoidCallback onOpenAccount;

  /// Opens screen 30 in its reauth mode.
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(accountCoordinatorProvider) == null) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final account = ref.watch(deviceAccountProvider);
    final canLink = ref.watch(canLinkProvider);
    final row = account == null
        ? MxSettingsRow(
            label: l10n.accountSignIn,
            subtitle: canLink
                ? l10n.accountSignInHint
                : l10n.accountSignInLater,
            icon: AppIcons.account,
            isEnabled: canLink,
            onTap: canLink ? onSignIn : null,
          )
        : MxSettingsRow(
            label: account.email ?? l10n.accountSignedIn,
            subtitle: l10n.accountSignedInHint,
            icon: AppIcons.account,
            onTap: onOpenAccount,
          );
    final section = MxSection(title: l10n.accountSection, children: [row]);
    if (ref.watch(authStateProvider).value is! ReauthRequired) return section;
    // P3b plan ruling 1: the banner leads the section, above its overline.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountReauthBannerWidget(onSignIn: onSignInAgain),
        const SizedBox(height: AppSpacing.gutter),
        section,
      ],
    );
  }
}
