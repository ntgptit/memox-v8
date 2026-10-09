import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart';

/// An expired sign-in, above the hub's "Account & sync" overline (P3b plan
/// ruling 1; settings hub spec D7): the banner with the section's gap
/// below it, or nothing.
class AccountSettingsBannerWidget extends ConsumerWidget {
  const AccountSettingsBannerWidget({super.key, required this.onSignIn});

  /// Opens screen 30 in its reauth mode.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authStateProvider).value is! ReauthRequired) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.gutter),
      child: AccountReauthBannerWidget(onSignIn: onSignIn),
    );
  }
}
