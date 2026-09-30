import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';

/// Where the account stands (auth spec §3.2). The single source of truth
/// for sync, the router and every screen (`authStateProvider`).
sealed class AuthState {
  const AuthState();
}

/// Reading the record and the session.
final class Booting extends AuthState {
  const Booting();
}

/// No session and no network. Local writes go on; the outbox fills.
final class LocalOnly extends AuthState {
  const LocalOnly();
}

/// Creating the anonymous user, only if the SDK has none (#5, #6).
final class Bootstrapping extends AuthState {
  const Bootstrapping();
}

/// A session, not yet confirmed by `me()`. Sync stays paused (R2).
final class Validating extends AuthState {
  const Validating(this.last);

  final AccountUser? last;
}

/// Confirmed. Sync runs when online.
final class Ready extends AuthState {
  const Ready(this.user);

  final AccountUser user;
}

/// A permanent account whose session was refused. Local data is kept and
/// sync paused until the user signs in again (#14).
final class ReauthRequired extends AuthState {
  const ReauthRequired(this.last);

  final AccountUser last;
}

/// A transition this run of the app started.
final class Transitioning extends AuthState {
  const Transitioning(
    this.transition, {
    this.needsTargetSignIn = false,
    this.error,
  });

  final AccountTransition transition;

  /// The switch waits for the user to sign in to the target account.
  final bool needsTargetSignIn;

  /// Why the flow stopped, when it did (a network error until Retry).
  final Failure? error;
}

/// A transition found at start, being reconciled with the SDK (R1, #45).
final class Recovering extends AuthState {
  const Recovering(
    this.transition, {
    this.needsTargetSignIn = false,
    this.error,
    this.stuck = false,
  });

  final AccountTransition transition;
  final bool needsTargetSignIn;
  final Failure? error;

  /// A state the table says cannot happen (#31 after a merge). The gate
  /// stays shut, and the log has the details.
  final bool stuck;
}

/// A one-off outcome for the user, beside the state (plan ruling 3).
sealed class AccountNotice {
  const AccountNotice();
}

/// The merge was refused and the device is back on its own data (#25).
final class MergeNotDone extends AccountNotice {
  const MergeNotDone();
}

/// The deletion did not happen (#44).
final class DeleteRefused extends AccountNotice {
  const DeleteRefused(this.failure);

  final Failure failure;
}
