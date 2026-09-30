import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The code step of screen 31 and of the transition layer (account UI spec
/// §5.2): six digits check at once; a wrong code clears the field (plan
/// ruling 11); "Resend code" counts down its wait in its label.
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

  CodeController get _controller =>
      ref.read(codeControllerProvider(widget.email, widget.purpose).notifier);

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _changed(String text) async {
    if (text.length < MxTextField.codeLength) return;
    final isSignedIn = await _controller.verify(text);
    if (!mounted) return;
    if (!isSignedIn) {
      _code.clear();
      return;
    }
    widget.onSignedIn?.call();
  }

  Future<void> _resend() async {
    final isSent = await _controller.resend();
    if (!mounted || !isSent) return;
    showMxSnackbar(context, message: context.l10n.accountCodeResent);
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
          variant: MxTextFieldVariant.code,
          label: l10n.accountCodeLabel,
          isEnabled: !state.isVerifying,
          onChanged: (text) => unawaited(_changed(text)),
          errorText: problem == null ? null : signInProblemText(l10n, problem),
        ),
        if (state.isVerifying)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.grouped),
            child: Center(child: MxSpinner(semanticLabel: l10n.commonLoading)),
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
