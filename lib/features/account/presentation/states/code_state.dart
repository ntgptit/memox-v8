import 'package:memox/features/account/presentation/states/sign_in_state.dart';

/// What "Resend code" did (P3b minor M7): a code went out, the resend
/// waits on the loss of [CodeState.unsentCount] changes being accepted, or
/// it was refused ([CodeState.problem] says why).
enum ResendOutcome { sent, unsentChanges, refused }

/// Screen 31's state (account UI spec §5.2): a check or a resend running,
/// the last problem, and the wait before "Resend code" works again.
final class CodeState {
  const CodeState({
    this.isVerifying = false,
    this.isResending = false,
    this.problem,
    this.resendIn = Duration.zero,
    this.unsentCount = 0,
  });

  final bool isVerifying;
  final bool isResending;
  final SignInProblem? problem;

  /// Zero once a new code may be asked for.
  final Duration resendIn;

  /// What a resend to another account would lose, until it is accepted.
  final int unsentCount;

  bool get isBusy => isVerifying || isResending;

  bool get canResend => resendIn == Duration.zero && !isBusy;

  CodeState copyWith({Duration? resendIn}) => CodeState(
    isVerifying: isVerifying,
    isResending: isResending,
    problem: problem,
    resendIn: resendIn ?? this.resendIn,
    unsentCount: unsentCount,
  );
}
