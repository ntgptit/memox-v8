import 'package:memox/core/error/failure.dart';

/// Who the sign-in form signs in (account UI spec §5.2): this anonymous
/// user's link, or the switch's target inside the transition layer. Each
/// has its own controller, since the layer's form can stand over screen
/// 30's. P3b adds signing in again after the session was refused.
enum SignInPurpose { link, target, reauth }

/// The command the form is running.
enum SignInTask { google, email }

/// What went wrong; `signInProblemText` gives the local-first copy.
enum SignInProblem { invalidEmail, wrongCode, rateLimited, offline, failed }

/// What a command came to, for the screen to act on.
enum SignInOutcome {
  /// The account is attached, or the switch's target signed in.
  signedIn,

  /// A code is on its way to the address.
  codeSent,

  /// The identity belongs to another account (auth spec #17).
  identityTaken,

  /// Signing in to another account would lose [SignInState.unsentCount]
  /// changes; asked again with the loss confirmed (auth spec ruling 6).
  unsentChanges,

  /// Nothing to show: a cancelled Google pick, or a press while one runs.
  none,

  /// [SignInState.problem] says why.
  failed,
}

/// The form's state: what runs, and what went wrong with which command.
final class SignInState {
  const SignInState({
    this.task,
    this.problem,
    this.problemTask,
    this.unsentCount = 0,
  });

  final SignInTask? task;
  final SignInProblem? problem;

  /// Which command [problem] belongs to: an email problem shows under the
  /// field, a Google one as a toast.
  final SignInTask? problemTask;

  /// The changes a re-auth to another account would lose.
  final int unsentCount;

  bool get isRunning => task != null;
}

/// The problem a refused command shows (spec R3: a wrong and an expired
/// code read alike; a rate limit carries no wait).
SignInProblem signInProblemOf(Object error) => switch (error) {
  InvalidCodeFailure() => SignInProblem.wrongCode,
  InvalidEmailFailure() => SignInProblem.invalidEmail,
  RateLimitedFailure() => SignInProblem.rateLimited,
  OfflineFailure() => SignInProblem.offline,
  _ => SignInProblem.failed,
};

final _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// A plausible address: one `@`, a dotted domain, no spaces. The server
/// decides the rest.
bool isEmailAddress(String text) => _emailShape.hasMatch(text);
