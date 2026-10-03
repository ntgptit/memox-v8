import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The code step of screen 31 and of the transition layer (account UI spec
/// §5.2): six digits check at once; a wrong code clears the field (plan
/// ruling 11); a code that could not be checked keeps its digits and offers
/// Retry (SP2b 2.45); "Resend code" counts down its wait in its label.
class CodeFormWidget extends ConsumerStatefulWidget {
  const CodeFormWidget({
    super.key,
    required this.email,
    required this.purpose,
    required this.onUseAnotherEmail,
    this.onSignedIn,
  });

  final String email;
  final SignInPurpose purpose;
  final VoidCallback onUseAnotherEmail;

  /// The code signed in (the link; the layer follows the state instead).
  final VoidCallback? onSignedIn;

  @override
  ConsumerState<CodeFormWidget> createState() => _CodeFormWidgetState();
}

class _CodeFormWidgetState extends ConsumerState<CodeFormWidget> {
  static const int _clockDigits = 2;

  final _code = TextEditingController();
  final _focus = FocusNode();

  /// True while the digits stand unchecked because the check could not run
  /// (offline, failed, rate limited). The digits stay and Retry checks them
  /// again (2.45).
  var _hasKeptCode = false;

  CodeController get _controller =>
      ref.read(codeControllerProvider(widget.email, widget.purpose).notifier);

  @override
  void initState() {
    super.initState();
    // The keyboard opens with the step.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _changed(String text) async {
    if (text.length < MxTextField.codeLength) return;
    await _check(text);
  }

  /// Checks [text]. A refused code is cleared; a code that could not be
  /// checked is kept, with its problem and a Retry (2.45).
  Future<void> _check(String text) async {
    final isSignedIn = await _controller.verify(text);
    if (!mounted) return;
    if (isSignedIn) {
      widget.onSignedIn?.call();
      return;
    }
    final problem = ref
        .read(codeControllerProvider(widget.email, widget.purpose))
        .problem;
    final isRefused = problem == SignInProblem.wrongCode;
    setState(() => _hasKeptCode = problem != null && !isRefused);
    if (!isRefused) return;
    _code.clear();
    _focus.requestFocus();
  }

  /// Retry: the digits typed are checked again; with one missing, the field
  /// takes the focus so it can be completed.
  void _retry() {
    if (_code.text.length < MxTextField.codeLength) {
      _focus.requestFocus();
      return;
    }
    unawaited(_check(_code.text));
  }

  Future<void> _resend({bool confirmedLoss = false}) async {
    setState(() => _hasKeptCode = false);
    final outcome = await _controller.resend(confirmedLoss: confirmedLoss);
    if (!mounted) return;
    switch (outcome) {
      case ResendOutcome.sent:
        showMxSnackbar(context, message: context.l10n.accountCodeResent);
      case ResendOutcome.unsentChanges:
        final count = ref
            .read(codeControllerProvider(widget.email, widget.purpose))
            .unsentCount;
        final isSure = await confirmUnsentLoss(context, count);
        if (!isSure || !mounted) return;
        await _resend(confirmedLoss: true);
      case ResendOutcome.refused:
        return;
    }
  }

  /// The wait as m:ss.
  String _clock(Duration wait) {
    final seconds = wait.inSeconds % Duration.secondsPerMinute;
    return '${wait.inMinutes}:${seconds.toString().padLeft(_clockDigits, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(
      codeControllerProvider(widget.email, widget.purpose),
    );
    final problem = state.problem;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.accountCodeSentTo(widget.email),
          style: context.textStyles.emptyBody,
        ),
        const SizedBox(height: AppSpacing.section),
        MxTextField(
          controller: _code,
          focusNode: _focus,
          variant: MxTextFieldVariant.code,
          label: l10n.accountCodeLabel,
          onChanged: (text) => unawaited(_changed(text)),
          errorText: problem == null || _hasKeptCode
              ? null
              : signInProblemText(l10n, problem),
        ),
        if (state.isVerifying)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.grouped),
            child: Center(child: MxSpinner(semanticLabel: l10n.commonLoading)),
          ),
        if (problem != null && _hasKeptCode)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.grouped),
            child: MxInlineBanner(
              tone: MxBannerTone.warning,
              message: signInProblemText(l10n, problem),
              actions: [
                MxButton(
                  label: l10n.commonRetry,
                  size: MxButtonSize.compact,
                  onPressed: _retry,
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.grouped),
        MxButton(
          label: state.canResend
              ? l10n.accountResend
              : l10n.accountResendIn(_clock(state.resendIn)),
          tone: MxButtonTone.text,
          isLoading: state.isResending,
          onPressed: state.canResend ? () => unawaited(_resend()) : null,
        ),
        MxButton(
          label: l10n.accountUseAnotherEmail,
          tone: MxButtonTone.text,
          onPressed: state.isVerifying ? null : widget.onUseAnotherEmail,
        ),
      ],
    );
  }
}
