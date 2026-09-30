import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/foundations/app_stroke.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/merge_choice_sheet_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The sign-in of screen 30 and of the transition layer (account UI spec
/// §5.2, §6): Google as the outline, "or", then the address and "Send
/// code", the form's one fill. The address is checked on send; its problem
/// shows under the field, and a Google problem shows as a toast.
class SignInFormWidget extends ConsumerStatefulWidget {
  const SignInFormWidget({
    super.key,
    required this.purpose,
    required this.onCodeSent,
    this.onSignedIn,
    this.initialEmail,
    this.isEnabled = true,
  });

  final SignInPurpose purpose;

  /// A code went to this address: the code step is next.
  final ValueChanged<String> onCodeSent;

  /// Google signed in (the link; the layer follows the state instead).
  final VoidCallback? onSignedIn;

  /// The address typed before, such as the switch's target.
  final String? initialEmail;

  /// False while this device cannot sign in yet (plan ruling 6).
  final bool isEnabled;

  @override
  ConsumerState<SignInFormWidget> createState() => _SignInFormWidgetState();
}

class _SignInFormWidgetState extends ConsumerState<SignInFormWidget> {
  late final _email = TextEditingController(text: widget.initialEmail);

  SignInController get _controller =>
      ref.read(signInControllerProvider(widget.purpose).notifier);

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _google() async {
    final outcome = await _controller.continueWithGoogle();
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

  Future<void> _send() async {
    final email = _email.text.trim();
    final outcome = await _controller.sendCode(email);
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
      case SignInOutcome.none || SignInOutcome.failed:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(signInControllerProvider(widget.purpose));
    final canAct = widget.isEnabled && !state.isRunning;
    final fieldProblem = state.problemTask == SignInTask.email
        ? state.problem
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.purpose == SignInPurpose.link
              ? l10n.accountLinkLine
              : l10n.accountTargetLine,
          style: context.texts.bodyMedium!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        MxButton(
          label: l10n.accountContinueGoogle,
          tone: MxButtonTone.outline,
          mark: googleMark,
          isBlock: true,
          isLoading: state.task == SignInTask.google,
          onPressed: canAct ? () => unawaited(_google()) : null,
        ),
        const SizedBox(height: AppSpacing.section),
        _OrDivider(label: l10n.accountOr),
        const SizedBox(height: AppSpacing.section),
        MxTextField(
          controller: _email,
          label: l10n.accountEmail,
          hintText: l10n.accountEmail,
          isEnabled: widget.isEnabled,
          textInputAction: TextInputAction.send,
          onSubmitted: canAct ? (_) => unawaited(_send()) : null,
          errorText: fieldProblem == null
              ? null
              : signInProblemText(l10n, fieldProblem),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxButton(
          label: l10n.accountSendCode,
          isBlock: true,
          isLoading: state.task == SignInTask.email,
          onPressed: canAct ? () => unawaited(_send()) : null,
        ),
      ],
    );
  }
}

/// "or" between two hairlines.
class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(
      child: SizedBox(
        height: AppStroke.hairline,
        child: ColoredBox(color: context.derivedColors.ghostBorder),
      ),
    );
    return Row(
      spacing: AppSpacing.grouped,
      children: [
        line,
        Text(
          label,
          style: context.texts.labelSmall!.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        line,
      ],
    );
  }
}
