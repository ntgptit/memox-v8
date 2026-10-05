import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_footer_bar.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The sign-in page of screen 30 and of the transition layer (sign-in
/// redesign 2026-10-05 §3): the title, the lead and the address in the body;
/// Send code, the one fill, and Google in the footer, above the keyboard.
/// The address is checked on send; its problem shows under the field, and a
/// Google problem shows as a toast.
class SignInFormWidget extends ConsumerStatefulWidget {
  const SignInFormWidget({
    super.key,
    required this.purpose,
    required this.onCodeSent,
    this.appBar,
    this.onSignedIn,
    this.initialEmail,
    this.isEnabled = true,
    this.below = const [],
  });

  final SignInPurpose purpose;

  /// The top bar: Back on screen 30, Cancel in the layer.
  final Widget? appBar;

  /// A code went to this address: the code step is next.
  final ValueChanged<String> onCodeSent;

  /// Google signed in (the link; the layer follows the state instead).
  final VoidCallback? onSignedIn;

  /// The address typed before, such as the switch's target.
  final String? initialEmail;

  /// False while this device cannot sign in yet (plan ruling 6).
  final bool isEnabled;

  /// What sits under the field, such as re-auth's way out (S9).
  final List<Widget> below;

  @override
  ConsumerState<SignInFormWidget> createState() => _SignInFormWidgetState();
}

class _SignInFormWidgetState extends ConsumerState<SignInFormWidget> {
  late final _email = TextEditingController(text: widget.initialEmail);

  SignInController get _controller =>
      ref.read(signInControllerProvider(widget.purpose).notifier);

  /// A re-auth's address arrives with the account state, which may come a
  /// frame after the form: it fills the field while nothing is typed.
  @override
  void didUpdateWidget(SignInFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final email = widget.initialEmail;
    if (email != null &&
        oldWidget.initialEmail == null &&
        _email.text.isEmpty) {
      _email.text = email;
    }
  }

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _google({bool confirmedLoss = false}) async {
    final outcome = await _controller.continueWithGoogle(
      confirmedLoss: confirmedLoss,
    );
    if (!mounted) return;
    final problem = ref.read(signInControllerProvider(widget.purpose)).problem;
    if (outcome == SignInOutcome.failed && problem != null) {
      showMxSnackbar(
        context,
        message: signInProblemText(context.l10n, problem),
      );
      return;
    }
    await _follow(outcome, email: null);
  }

  Future<void> _send({bool confirmedLoss = false}) async {
    final email = _email.text.trim();
    final outcome = await _controller.sendCode(
      email,
      confirmedLoss: confirmedLoss,
    );
    if (!mounted) return;
    await _follow(outcome, email: email);
  }

  Future<void> _follow(SignInOutcome outcome, {required String? email}) async {
    switch (outcome) {
      case SignInOutcome.signedIn:
        widget.onSignedIn?.call();
      case SignInOutcome.codeSent:
        widget.onCodeSent(email!);
      case SignInOutcome.identityTaken:
        await startLinkSwitch(context, ref, email: email);
      case SignInOutcome.unsentChanges:
        await _confirmLoss(isGoogle: email == null);
      case SignInOutcome.none || SignInOutcome.failed:
        return;
    }
  }

  /// Auth spec ruling 6: another account replaces this phone's data, so the
  /// unsent changes are named before the command runs again.
  Future<void> _confirmLoss({required bool isGoogle}) async {
    final count = ref
        .read(signInControllerProvider(widget.purpose))
        .unsentCount;
    final isSure = await confirmUnsentLoss(context, count);
    if (!isSure) {
      if (isGoogle) _controller.forgetPickedGoogle();
      return;
    }
    if (!mounted) return;
    if (isGoogle) return _google(confirmedLoss: true);
    return _send(confirmedLoss: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final state = ref.watch(signInControllerProvider(widget.purpose));
    final canAct = widget.isEnabled && !state.isRunning;
    final fieldProblem = state.problemTask == SignInTask.email
        ? state.problem
        : null;
    final isReauth = widget.purpose == SignInPurpose.reauth;
    // S9: re-auth names the account it signs in again to.
    final eyebrow = isReauth ? widget.initialEmail : null;
    // Plan ruling 6: only a link waits for the account to be ready.
    // A Google sign-in in flight turns the account away from linking for a
    // moment: that is not waiting (final review F2).
    final isWaiting =
        !widget.isEnabled &&
        !state.isRunning &&
        widget.purpose == SignInPurpose.link;
    // A re-auth and a prefilled target already hold their address: only an
    // empty one takes the keyboard.
    final isAutofocused =
        widget.isEnabled && !isReauth && (widget.initialEmail ?? '').isEmpty;
    return MxAppShell(
      appBar: widget.appBar,
      body: MxScreenScroll(
        children: [
          if (eyebrow != null) ...[
            Text(eyebrow, style: styles.eyebrow),
            const SizedBox(height: AppSpacing.micro),
          ],
          Semantics(
            header: true,
            namesRoute: true,
            child: Text(
              isReauth ? l10n.accountReauthTitle : l10n.accountSignIn,
              style: styles.screenTitle,
            ),
          ),
          const SizedBox(height: AppSpacing.control),
          Text(switch (widget.purpose) {
            SignInPurpose.link => l10n.accountLinkLine,
            SignInPurpose.target => l10n.accountTargetLine,
            SignInPurpose.reauth => l10n.accountReauthLine,
          }, style: styles.emptyBody),
          const SizedBox(height: AppSpacing.section),
          // The field announces the same label; TalkBack reads it once.
          ExcludeSemantics(
            child: Text(l10n.accountEmail, style: styles.fieldLabel),
          ),
          const SizedBox(height: AppSpacing.control),
          MxTextField(
            controller: _email,
            label: l10n.accountEmail,
            hintText: l10n.accountEmailHint,
            isEnabled: widget.isEnabled,
            isAutofocused: isAutofocused,
            textInputAction: TextInputAction.send,
            onSubmitted: canAct ? (_) => unawaited(_send()) : null,
            errorText: fieldProblem == null
                ? null
                : signInProblemText(l10n, fieldProblem),
          ),
          ...widget.below,
        ],
      ),
      footer: MxFooterBar(
        caption: isWaiting ? l10n.accountOfflineNote : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.grouped,
          children: [
            MxButton(
              label: l10n.accountSendCode,
              isBlock: true,
              isLoading: state.task == SignInTask.email,
              onPressed: canAct ? () => unawaited(_send()) : null,
            ),
            MxButton(
              label: l10n.accountContinueGoogle,
              tone: MxButtonTone.outline,
              mark: googleMark,
              isBlock: true,
              isLoading: state.task == SignInTask.google,
              onPressed: canAct ? () => unawaited(_google()) : null,
            ),
          ],
        ),
      ),
    );
  }
}
