import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_size.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';
import 'package:memox/shared/widgets/mx_spinner.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// The code step of screen 31 and of the transition layer (account UI spec
/// §5.2): the title, the lead and the address, six slots, a wait line that is
/// a caption while the wait runs, a spinner while six digits are checked, and
/// Resend once it may (sign-in redesign 2026-10-05 §4). Six digits check at
/// once; a wrong code clears the field (plan ruling 11).
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

  Future<void> _resend({bool confirmedLoss = false}) async {
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
    final styles = context.textStyles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          namesRoute: true,
          child: Text(l10n.accountCodeTitle, style: styles.screenTitle),
        ),
        const SizedBox(height: AppSpacing.control),
        // TalkBack reads the lead and its address as one sentence (DEV-168).
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.accountCodeSentTo, style: styles.emptyBody),
              Text(widget.email, style: styles.emptyBodyStrong),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.section),
        MxTextField(
          controller: _code,
          variant: MxTextFieldVariant.code,
          label: l10n.accountCodeLabel,
          isAutofocused: true,
          isReadOnly: state.isVerifying,
          onChanged: (text) => unawaited(_changed(text)),
          errorText: problem == null ? null : signInProblemText(l10n, problem),
        ),
        const SizedBox(height: AppSpacing.grouped),
        _WaitLine(
          isVerifying: state.isVerifying,
          // A resend in flight has no wait left: the button shows and spins.
          wait: state.resendIn == Duration.zero ? null : _clock(state.resendIn),
          isResending: state.isResending,
          onResend: () => unawaited(_resend()),
        ),
        MxNote.hint(text: l10n.accountCodeSpamHint),
        MxButton(
          label: l10n.accountUseAnotherEmail,
          tone: MxButtonTone.text,
          onPressed: state.isVerifying ? null : widget.onUseAnotherEmail,
        ),
      ],
    );
  }
}

/// The line under the code, 48 tall at least so its three forms never move
/// what is below: a spinner while the code is checked, the wait as a
/// caption, then "Resend code" once a new code may go (critique 2026-10-05
/// P1: a disabled button read at 1.83:1).
class _WaitLine extends StatelessWidget {
  const _WaitLine({
    required this.isVerifying,
    required this.wait,
    required this.isResending,
    required this.onResend,
  });

  final bool isVerifying;

  /// The time left as m:ss, or null once a new code may be sent.
  final String? wait;
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final wait = this.wait;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: AppSize.touchTarget),
      child: Center(
        child: switch ((isVerifying, wait)) {
          (true, _) => MxSpinner(semanticLabel: l10n.commonLoading),
          (false, final String time) => Text(
            l10n.accountResendIn(time),
            style: context.textStyles.footerCaption,
          ),
          // A polite live region on the button's own node, so TalkBack
          // speaks its label when the wait ends (DEV-168, final review I1).
          (false, null) => MergeSemantics(
            child: Semantics(
              liveRegion: true,
              child: MxButton(
                label: l10n.accountResend,
                tone: MxButtonTone.text,
                isLoading: isResending,
                onPressed: onResend,
              ),
            ),
          ),
        },
      ),
    );
  }
}
