import 'dart:async';

import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'code_controller.g.dart';

/// Screen 31's commands (account UI spec §5.2): check six digits, and ask
/// for a new code once the wait is over. One per address and purpose, so
/// the layer's code step never shares a countdown with screen 31's.
@riverpod
class CodeController extends _$CodeController {
  /// Between two codes to one address (spec §5.2).
  static const Duration resendWait = Duration(seconds: 60);
  static const Duration _tick = Duration(seconds: 1);

  Timer? _timer;

  @override
  CodeState build(String email, SignInPurpose purpose) {
    ref.onDispose(() => _timer?.cancel());
    _startWait();
    return const CodeState(resendIn: resendWait);
  }

  /// True when the code signed in.
  Future<bool> verify(String code) async {
    final accounts = ref.read(accountCoordinatorProvider);
    // A check may start while a new code is on its way: the coordinator
    // runs one step at a time, so it waits for the request (review M1).
    if (accounts == null || state.isVerifying) return false;
    state = CodeState(
      isVerifying: true,
      isResending: state.isResending,
      resendIn: state.resendIn,
    );
    SignInProblem? problem;
    try {
      await accounts.verifyCode(email, code);
    } on Failure catch (error) {
      problem = signInProblemOf(error);
    } on StateError {
      problem = SignInProblem.failed; // The account moved on meanwhile.
    }
    if (ref.mounted) {
      state = CodeState(
        isResending: state.isResending,
        problem: problem,
        resendIn: state.resendIn,
      );
    }
    return problem == null;
  }

  /// True when a new code is on its way; the wait starts again.
  Future<bool> resend() async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || !state.canResend) return false;
    state = const CodeState(isResending: true);
    SignInProblem? problem;
    try {
      await accounts.requestCode(email);
    } on Failure catch (error) {
      problem = signInProblemOf(error);
    } on StateError {
      problem = SignInProblem.failed; // The account moved on meanwhile.
    }
    if (!ref.mounted) return problem == null;
    final isSent = problem == null;
    state = CodeState(
      isVerifying: state.isVerifying,
      problem: problem,
      resendIn: isSent ? resendWait : Duration.zero,
    );
    if (isSent) _startWait();
    return isSent;
  }

  void _startWait() {
    _timer?.cancel();
    _timer = Timer.periodic(_tick, (timer) {
      final left = state.resendIn - _tick;
      if (left > Duration.zero) {
        state = state.copyWith(resendIn: left);
        return;
      }
      timer.cancel();
      state = state.copyWith(resendIn: Duration.zero);
    });
  }
}
