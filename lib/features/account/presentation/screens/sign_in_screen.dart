import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';
import 'package:memox/features/account/presentation/providers/can_link_provider.dart';
import 'package:memox/features/account/presentation/providers/can_sign_in_again_provider.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

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
    return SignInFormWidget(
      appBar: MxAppBar(
        titleWidget: const SizedBox.shrink(),
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      purpose: purpose,
      isEnabled: canAct,
      initialEmail: isReauth ? ref.watch(deviceAccountProvider)?.email : null,
      onCodeSent: onCodeSent,
      onSignedIn: () {
        saySignedIn(context, stateAfterCommand(ref));
        onSignedIn();
      },
      below: [
        // S9: the way out sits in the body, 32 under the form, out of the
        // footer's thumb path.
        if (isReauth) ...[
          const SizedBox(height: AppSpacing.major),
          MxButton(
            label: l10n.accountContinueWithoutThis,
            tone: MxButtonTone.text,
            isBlock: true,
            onPressed: canAct && !isLeaving
                ? () => unawaited(_leave(context, ref))
                : null,
          ),
        ],
      ],
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
              hasBottomMargin: false,
            ),
      confirmLabel: l10n.accountWithoutConfirm,
      isDestructive: true,
      isEvenSplit: true,
    );
    if (!isSure || !context.mounted) return;
    final result = await controller.continueWithoutAccount();
    if (!context.mounted) return;
    if (result == AccountCommandResult.done) return onLeftAccount?.call();
    sayAccountResult(context, result);
  }
}
