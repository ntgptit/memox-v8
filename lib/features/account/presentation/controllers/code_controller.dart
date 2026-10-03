import 'dart:async';

import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/providers/last_code_sent_provider.dart';
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
    // Read, not watched: a send recorded while this step is open must not
    // rebuild it. A code sent a moment ago keeps its wait across leaving and
    // coming back (2.41); one this run did not record starts a fresh minute.
    final wait =
        ref
            .read(lastCodeSentProvider.notifier)
            .waitLeft(
              purpose,
              email,
              ref.read(dayClockProvider).now(),
              resendWait,
            ) ??
        resendWait;
    if (wait > Duration.zero) _startWait();
    return CodeState(resendIn: wait);
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
    // Captured before the await: the step may be left once the code signs in.
    final sent = ref.read(lastCodeSentProvider.notifier);
    SignInProblem? problem;
    try {
      await accounts.verifyCode(email, code);
      sent.clear();
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

  /// A new code, once the wait is over; the wait starts again when it
  /// went out. A re-auth to another account names its unsent changes again,
  /// as screen 30 did (P3b minor M7): the link to this screen may not have
  /// passed there.
  Future<ResendOutcome> resend({bool confirmedLoss = false}) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || !state.canResend) return ResendOutcome.refused;
    // Captured before the await: the step may be left while the code is on
    // its way, and the send still has to be remembered.
    final sent = ref.read(lastCodeSentProvider.notifier);
    final clock = ref.read(dayClockProvider);
    state = const CodeState(isResending: true);
    SignInProblem? problem;
    try {
      await accounts.requestCode(email, confirmedLoss: confirmedLoss);
    } on UnsentChangesFailure catch (error) {
      if (ref.mounted) {
        state = CodeState(
          isVerifying: state.isVerifying,
          unsentCount: error.count,
        );
      }
      return ResendOutcome.unsentChanges;
    } on Failure catch (error) {
      problem = signInProblemOf(error);
    } on StateError {
      problem = SignInProblem.failed; // The account moved on meanwhile.
    }
    final isSent = problem == null;
    // A rate limit means the server saw a send within the minute: wait that
    // long again instead of offering a Resend that is sure to be refused
    // (2.44).
    final isWaiting = isSent || problem == SignInProblem.rateLimited;
    if (isWaiting) sent.record(purpose, email, clock.now());
    final outcome = isSent ? ResendOutcome.sent : ResendOutcome.refused;
    if (!ref.mounted) return outcome;
    state = CodeState(
      isVerifying: state.isVerifying,
      problem: problem,
      resendIn: isWaiting ? resendWait : Duration.zero,
    );
    if (isWaiting) _startWait();
    return outcome;
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
