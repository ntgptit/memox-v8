import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/providers/unsent_count_provider.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/sections/code_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/sign_in_form_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/failure_message.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';

/// The transition layer (account UI spec U4, §5.4, §6): over the whole app
/// while a switch, sign-out, deletion or clear runs. Its own navigator
/// holds the target sign-in's code step; the host sends Back here.
class AccountTransitionLayerWidget extends StatelessWidget {
  const AccountTransitionLayerWidget({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  Widget build(BuildContext context) => Navigator(
    key: navigatorKey,
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const _LayerPage(),
      transitionDuration: Duration.zero,
    ),
  );
}

class _LayerPage extends ConsumerWidget {
  const _LayerPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = blockingViewOf(ref.watch(authStateProvider).value);
    if (view == null) return const SizedBox.shrink();
    final canCancel = canCancelSwitch(view.transition) && !view.isStuck;
    final isSigningIn = view.isAwaitingTargetSignIn && !view.isStuck;
    return MxAppShell(
      appBar: canCancel
          ? MxAppBar(
              titleWidget: const SizedBox.shrink(),
              density: MxAppBarDensity.content,
              actions: [
                MxButton(
                  label: context.l10n.commonCancel,
                  tone: MxButtonTone.text,
                  size: MxButtonSize.small,
                  onPressed: () => unawaited(_cancel(context, ref)),
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: isSigningIn
            ? _TargetSignIn(targetHint: view.transition.targetHint)
            : _Progress(view: view),
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(accountCoordinatorProvider)?.cancelSwitch();
    } on Failure catch (error) {
      if (context.mounted) {
        showMxSnackbar(context, message: context.l10n.failure(error));
      }
    } on StateError {
      // The switch passed the target sign-in meanwhile; the layer follows.
      return;
    }
  }
}

/// The target sign-in, first the address, then the code on the layer's
/// navigator.
class _TargetSignIn extends StatelessWidget {
  const _TargetSignIn({required this.targetHint});

  final String? targetHint;

  @override
  Widget build(BuildContext context) => MxScreenScroll(
    children: [
      const SizedBox(height: AppSpacing.gutter),
      SignInFormWidget(
        purpose: SignInPurpose.target,
        initialEmail: targetHint,
        onCodeSent: (email) => unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => _LayerCodePage(email)),
          ),
        ),
      ),
    ],
  );
}

/// The code step inside the layer. It closes itself once the target has
/// signed in: the switch then runs on under the progress.
class _LayerCodePage extends ConsumerWidget {
  const _LayerCodePage(this.email);

  final String email;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authStateProvider, (_, next) {
      final view = blockingViewOf(next.value);
      if (view == null || !view.isAwaitingTargetSignIn) {
        unawaited(Navigator.of(context).maybePop());
      }
    });
    final l10n = context.l10n;
    void back() => unawaited(Navigator.of(context).maybePop());
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountCodeTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: back,
        ),
      ),
      body: MxScreenScroll(
        children: [
          CodeFormWidget(
            email: email,
            purpose: SignInPurpose.target,
            onUseAnotherEmail: back,
          ),
        ],
      ),
    );
  }
}

/// The step, or what stopped it and how to go on (spec §5.4).
class _Progress extends ConsumerWidget {
  const _Progress({required this.view});

  final BlockingView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final error = view.error;
    final isStopped = error != null || view.isStuck;
    final step = accountStepText(l10n, accountStepOf(view.transition));
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.pageEnd),
        if (isStopped) ...[
          Semantics(
            liveRegion: true,
            child: MxInlineBanner(
              tone: MxBannerTone.warning,
              message: view.isStuck
                  ? l10n.accountLayerStuck
                  : error is OfflineFailure
                  ? l10n.accountLayerOffline
                  : l10n.accountLayerFailed,
            ),
          ),
          const SizedBox(height: AppSpacing.gutter),
          MxButton(
            label: l10n.commonRetry,
            isBlock: true,
            onPressed: () => unawaited(_retry(ref)),
          ),
          if (_isSignOutStoppedOffline(error)) ...[
            const SizedBox(height: AppSpacing.grouped),
            const _SignOutNow(),
          ],
        ] else ...[
          Center(
            child: MxSpinner(size: MxSpinnerSize.large, semanticLabel: step),
          ),
          const SizedBox(height: AppSpacing.section),
          Semantics(
            liveRegion: true,
            child: Text(
              step,
              textAlign: TextAlign.center,
              style: context.textStyles.screenTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Text(
            l10n.accountSafeToClose,
            textAlign: TextAlign.center,
            style: context.textStyles.emptyBody,
          ),
        ],
      ],
    );
  }

  /// Auth spec #39: offline, a sign-out waits to send unless its loss is
  /// accepted (plan ruling 10 of P2).
  bool _isSignOutStoppedOffline(Failure? error) =>
      view.transition.kind == TransitionKind.signOut &&
      view.transition.choice != TransitionChoice.discard &&
      (error is OfflineFailure || error is UnsentChangesFailure);

  Future<void> _retry(WidgetRef ref) async {
    try {
      await ref.read(accountCoordinatorProvider)?.retry();
    } on Failure catch (error, stackTrace) {
      // The state carries what stopped; the log keeps why.
      appLogger.warning(
        'account.retry_failed',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

/// "Sign out now and lose n changes": the offline way on (spec §5.4).
class _SignOutNow extends ConsumerWidget {
  const _SignOutNow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unsentCountProvider).value;
    if (count == null) return const SizedBox.shrink();
    return MxButton(
      label: context.l10n.accountSignOutLosing(count),
      tone: MxButtonTone.dangerSoft,
      isBlock: true,
      onPressed: () => unawaited(_signOutNow(ref)),
    );
  }

  /// Auth spec #39: the loss is accepted, so the sign-out goes on offline.
  Future<void> _signOutNow(WidgetRef ref) async =>
      ref.read(accountCoordinatorProvider)?.signOut(discardUnsent: true);
}
