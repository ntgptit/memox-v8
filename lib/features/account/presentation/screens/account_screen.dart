import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 32 (account UI spec §5.6, §9, §9.1): the account this phone's
/// data belongs to, then switch, sign out and delete. The commands need a
/// confirmed account (auth spec #39): before `Ready` they wait and say why
/// (B3). Each asks first; the transition layer shows what follows.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, required this.onSignInAgain});

  /// Opens screen 30 in its reauth mode (spec §5.5).
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(authStateProvider).value;
    final account = ref.watch(deviceAccountProvider);
    final canManage =
        state is Ready && !ref.watch(accountManageControllerProvider);
    MxSettingsRow command(
      String label,
      String hint,
      IconData icon,
      Future<void> Function(BuildContext, WidgetRef) run,
    ) => MxSettingsRow(
      label: label,
      subtitle: hint,
      icon: icon,
      isEnabled: canManage,
      onTap: canManage ? () => unawaited(run(context, ref)) : null,
    );
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          if (state is ReauthRequired) ...[
            AccountReauthBannerWidget(onSignIn: onSignInAgain),
            const SizedBox(height: AppSpacing.gutter),
          ] else if (state is Validating) ...[
            MxNote(text: l10n.accountNeedsConnection),
            const SizedBox(height: AppSpacing.gutter),
          ],
          MxSection(
            title: l10n.accountSection,
            children: [
              MxSettingsRow(
                label: account?.email ?? l10n.accountSignedIn,
                subtitle: signInMethodText(
                  l10n,
                  ref.watch(signInMethodsProvider),
                ),
                icon: AppIcons.account,
              ),
            ],
          ),
          MxSection(
            title: l10n.accountThisPhone,
            children: [
              command(
                l10n.accountSwitch,
                l10n.accountSwitchHint,
                AppIcons.switchAccount,
                _switch,
              ),
              command(
                l10n.accountSignOut,
                l10n.accountSignOutHint,
                AppIcons.signOut,
                _signOut,
              ),
            ],
          ),
          MxSection(
            title: l10n.accountDeleteSection,
            children: [
              command(
                l10n.accountDelete,
                l10n.accountDeleteHint,
                AppIcons.delete,
                _delete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _switch(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountSwitchTitle,
      body: l10n.accountSwitchBody,
      note: MxNote(icon: AppIcons.safe, text: l10n.accountChangesSentFirst),
      confirmLabel: l10n.accountSwitch,
    );
    if (!isSure || !context.mounted) return;
    final result = await controller.switchAccount();
    if (context.mounted) sayAccountResult(context, result);
  }

  /// Online, or with nothing unsent, the changes go first; offline with
  /// changes unsent, their loss is named and accepted (spec §9 B4).
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final lost = await controller.changesLostBySignOut();
    if (!context.mounted) return;
    final l10n = context.l10n;
    final isLosing = lost > 0;
    final isSure = await confirmAccountStep(
      context,
      title: isLosing ? l10n.accountSignOutLossTitle : l10n.accountSignOutTitle,
      body: isLosing
          ? l10n.accountSignOutLossBody(lost)
          : l10n.accountSignOutBody,
      confirmLabel: l10n.accountSignOut,
      isDestructive: isLosing,
    );
    if (!isSure || !context.mounted) return;
    final result = await controller.signOut(discardUnsent: isLosing);
    if (context.mounted) sayAccountResult(context, result);
  }

  /// Online only: offline the confirm is disabled and says why (spec §9
  /// B6).
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final canDelete = await controller.canDelete();
    if (!context.mounted) return;
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountDeleteTitle,
      body: l10n.accountDeleteBody,
      note: canDelete
          ? null
          : MxNote(icon: AppIcons.offline, text: l10n.accountDeleteOffline),
      confirmLabel: l10n.accountDelete,
      confirmIcon: AppIcons.delete,
      isDestructive: true,
      canConfirm: canDelete,
    );
    if (!isSure || !context.mounted) return;
    final result = await controller.deleteAccount();
    if (context.mounted) sayAccountResult(context, result);
  }
}
