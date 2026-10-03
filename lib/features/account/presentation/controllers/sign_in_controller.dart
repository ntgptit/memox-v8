import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/providers/last_code_sent_provider.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sign_in_controller.g.dart';

/// Screen 30's and the layer's commands (account UI spec §5.2): Google, or
/// a code to an address. The coordinator decides whether a sign-in links
/// this user or signs in the switch's target; [purpose] only keeps the two
/// forms' states apart.
@riverpod
class SignInController extends _$SignInController {
  @override
  SignInState build(SignInPurpose purpose) => const SignInState();

  Future<SignInOutcome> continueWithGoogle({bool confirmedLoss = false}) =>
      _run(
        SignInTask.google,
        (accounts) => accounts.continueWithGoogle(confirmedLoss: confirmedLoss),
      );

  /// The loss was declined: the Google account picked for it is dropped
  /// (P3b final review I1).
  void forgetPickedGoogle() =>
      ref.read(accountCoordinatorProvider)?.forgetPickedGoogle();

  /// A text that is not an address is refused here, before anything is
  /// sent.
  Future<SignInOutcome> sendCode(
    String email, {
    bool confirmedLoss = false,
  }) async {
    final address = email.trim();
    if (!isEmailAddress(address)) {
      state = const SignInState(
        problem: SignInProblem.invalidEmail,
        problemTask: SignInTask.email,
      );
      return SignInOutcome.failed;
    }
    final sent = ref.read(lastCodeSentProvider.notifier);
    final clock = ref.read(dayClockProvider);
    // The same address inside the resend wait: the code on its way is still
    // the one to enter, so the code step reopens and nothing is sent (2.41).
    final left = sent.waitLeft(
      purpose,
      address,
      clock.now(),
      CodeController.resendWait,
    );
    if (left != null && left > Duration.zero) {
      if (purpose != SignInPurpose.reauth) return SignInOutcome.codeSent;
      // A re-auth as another address replaces this device: changes added
      // since the send are still confirmed before the code is entered.
      return _run(
        SignInTask.email,
        (accounts) =>
            accounts.checkReplace(address, confirmedLoss: confirmedLoss),
        done: SignInOutcome.codeSent,
      );
    }
    final outcome = await _run(
      SignInTask.email,
      (accounts) => accounts.requestCode(address, confirmedLoss: confirmedLoss),
      done: SignInOutcome.codeSent,
    );
    if (outcome == SignInOutcome.codeSent) {
      sent.record(purpose, address, clock.now());
    }
    return outcome;
  }

  Future<SignInOutcome> _run(
    SignInTask task,
    Future<void> Function(AccountCoordinator accounts) command, {
    SignInOutcome done = SignInOutcome.signedIn,
  }) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || state.isRunning) return SignInOutcome.none;
    state = SignInState(task: task);
    SignInProblem? problem;
    var unsent = 0;
    var outcome = done;
    try {
      await command(accounts);
    } on IdentityTakenFailure {
      outcome = SignInOutcome.identityTaken;
    } on UnsentChangesFailure catch (error) {
      unsent = error.count;
      outcome = SignInOutcome.unsentChanges;
    } on GoogleCancelledFailure {
      outcome = SignInOutcome.none;
    } on Failure catch (error) {
      problem = signInProblemOf(error);
      outcome = SignInOutcome.failed;
    } on StateError {
      // The account moved on meanwhile: P2 takes a sign-in only in Ready
      // (plan ruling 6).
      problem = SignInProblem.failed;
      outcome = SignInOutcome.failed;
    }
    if (ref.mounted) {
      state = SignInState(
        problem: problem,
        problemTask: problem == null ? null : task,
        unsentCount: unsent,
      );
    }
    return outcome;
  }
}
