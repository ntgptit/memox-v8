import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
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
