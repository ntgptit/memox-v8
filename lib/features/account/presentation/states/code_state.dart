import 'package:memox/features/account/presentation/states/sign_in_state.dart';

/// Screen 31's state (account UI spec §5.2): a check or a resend running,
/// the last problem, and the wait before "Resend code" works again.
final class CodeState {
  const CodeState({
    this.isVerifying = false,
    this.isResending = false,
    this.problem,
    this.resendIn = Duration.zero,
  });

  final bool isVerifying;
  final bool isResending;
  final SignInProblem? problem;

  /// Zero once a new code may be asked for.
  final Duration resendIn;

  bool get isBusy => isVerifying || isResending;

  bool get canResend => resendIn == Duration.zero && !isBusy;

  CodeState copyWith({Duration? resendIn}) => CodeState(
    isVerifying: isVerifying,
    isResending: isResending,
    problem: problem,
    resendIn: resendIn ?? this.resendIn,
  );
}
