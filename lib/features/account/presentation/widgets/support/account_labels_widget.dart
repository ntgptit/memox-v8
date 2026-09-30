import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';
import 'package:memox/features/account/presentation/states/account_step_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_snackbar.dart';

/// Google's G on "Continue with Google" (account UI spec U6).
const AssetImage googleMark = AssetImage('assets/brand/google_g.png');

/// The local-first line for a refused sign-in step.
String signInProblemText(AppLocalizations l10n, SignInProblem problem) =>
    switch (problem) {
      SignInProblem.invalidEmail => l10n.accountEmailInvalid,
      SignInProblem.wrongCode => l10n.accountCodeWrong,
      SignInProblem.rateLimited => l10n.accountRateLimited,
      SignInProblem.offline => l10n.accountOffline,
      SignInProblem.failed => l10n.accountFailed,
    };

/// The toast after an account is attached (spec §5.2): its email once
/// `me()` confirmed it.
void saySignedIn(BuildContext context, AccountUser? account) {
  final l10n = context.l10n;
  final email = account?.email;
  showMxSnackbar(
    context,
    message: email == null
        ? l10n.accountSignedIn
        : l10n.accountSignedInAs(email),
  );
}

/// The account right after a command attached it. The coordinator's own
/// state, since the provider hears of the change a frame later.
AccountUser? attachedAccount(WidgetRef ref) =>
    switch (ref.read(accountCoordinatorProvider)?.state) {
      Ready(:final user) => user,
      _ => null,
    };

/// The layer's line for [step] (spec §5.4).
String accountStepText(AppLocalizations l10n, AccountStep step) =>
    switch (step) {
      AccountStep.sending => l10n.accountStepSending,
      AccountStep.preparing => l10n.accountStepPreparing,
      AccountStep.merging => l10n.accountStepMerging,
      AccountStep.downloading => l10n.accountStepDownloading,
      AccountStep.signingOut => l10n.accountStepSigningOut,
      AccountStep.deleting => l10n.accountStepDeleting,
    };

/// Screen 32's line under the email (spec §9 B1); none when the session
/// names no method.
String? signInMethodText(AppLocalizations l10n, Set<SignInMethod> methods) =>
    switch ((
      methods.contains(SignInMethod.google),
      methods.contains(SignInMethod.email),
    )) {
      (true, true) => l10n.accountMethodBoth,
      (true, false) => l10n.accountMethodGoogle,
      (false, true) => l10n.accountMethodEmail,
      (false, false) => null,
    };

/// The toast for a refused account command; a command that ran says
/// nothing, since the transition layer shows it.
void sayAccountResult(BuildContext context, AccountCommandResult result) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  final message = switch (result) {
    AccountCommandResult.offline => l10n.accountOffline,
    AccountCommandResult.failed => l10n.accountCommandFailed,
    AccountCommandResult.done || AccountCommandResult.none => null,
  };
  if (message != null) showMxSnackbar(context, message: message);
}
