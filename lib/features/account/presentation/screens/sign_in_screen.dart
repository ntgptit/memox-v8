import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/providers/can_sign_in_again_provider.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Screen 30 (account UI spec §5.2): attach Google or an email to this
/// device's anonymous user (`link`), or sign in again after the session was
/// refused (`reauth`), which may also continue without an account.
class SignInScreen extends ConsumerWidget {
  const SignInScreen({
    super.key,
    required this.onCodeSent,
    required this.onSignedIn,
    this.purpose = SignInPurpose.link,
    this.onLeftAccount,
  });

  final ValueChanged<String> onCodeSent;

  /// Signed in: the flow closes (spec §9 B9).
  final VoidCallback onSignedIn;

  /// `link` attaches this user's first account; `reauth` signs in again
  /// (spec §5.2).
  final SignInPurpose purpose;

  /// Continued without an account: the flow closes (spec §9 B8).
  final VoidCallback? onLeftAccount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isReauth = purpose == SignInPurpose.reauth;
    final canAct = isReauth
        ? ref.watch(canSignInAgainProvider)
        : ref.watch(canLinkProvider);
    // Watched, so the command's controller lives while it runs.
    final isLeaving = ref.watch(accountManageControllerProvider);
    // A send or the Google pick holds Back: the spinner says what runs (2.46).
    final isRunning = ref.watch(
      signInControllerProvider(purpose).select((state) => state.isRunning),
    );
    return PopScope(
      canPop: !isRunning,
      child: MxAppShell(
        appBar: MxAppBar(
          title: l10n.accountSignIn,
          density: MxAppBarDensity.content,
          leading: MxIconButton(
            icon: AppIcons.back,
            semanticLabel: l10n.commonBack,
            onPressed: () => unawaited(Navigator.of(context).maybePop()),
          ),
        ),
        body: MxScreenScroll(
          children: [
            if (!isReauth && !canAct) ...[
              MxNote(text: l10n.accountOfflineNote),
              const SizedBox(height: AppSpacing.gutter),
            ],
            SignInFormWidget(
              purpose: purpose,
              isEnabled: canAct,
              initialEmail: isReauth
                  ? ref.watch(deviceAccountProvider)?.email
                  : null,
              onCodeSent: onCodeSent,
              onSignedIn: () {
                saySignedIn(context, stateAfterCommand(ref));
                onSignedIn();
              },
            ),
            // P3b plan ruling 10: the way out sits under the form.
            if (isReauth) ...[
              const SizedBox(height: AppSpacing.section),
              MxButton(
                label: l10n.accountContinueWithout,
                tone: MxButtonTone.text,
                isBlock: true,
                onPressed: canAct && !isLeaving
                    ? () => unawaited(_leave(context, ref))
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Gives up the refused account (auth spec #38) once the loss is
  /// confirmed; the layer shows the clearing (spec §9 B8).
  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final email = ref.read(deviceAccountProvider)?.email ?? '';
    final unsent = await controller.unsentChanges();
    if (!context.mounted) return;
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountWithoutTitle,
      body: l10n.accountWithoutBody(email),
      // The refused account cannot send them: they go with it (final
      // review I2), named as the merge sheet names a discard.
      note: unsent == 0
          ? null
          : MxInlineBanner(
              tone: MxBannerTone.danger,
              message: l10n.accountUnsentBody(unsent),
            ),
      confirmLabel: l10n.accountContinueWithout,
      isDestructive: true,
    );
    if (!isSure || !context.mounted) return;
    final result = await controller.continueWithoutAccount();
    if (!context.mounted) return;
    if (result == AccountCommandResult.done) return onLeftAccount?.call();
    sayAccountResult(context, result);
  }
}
