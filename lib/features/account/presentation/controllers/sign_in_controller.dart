import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
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

  Future<SignInOutcome> continueWithGoogle() =>
      _run(SignInTask.google, (accounts) => accounts.continueWithGoogle());

  /// A text that is not an address is refused here, before anything is
  /// sent.
  Future<SignInOutcome> sendCode(String email) async {
    final address = email.trim();
    if (!isEmailAddress(address)) {
      state = const SignInState(
        problem: SignInProblem.invalidEmail,
        problemTask: SignInTask.email,
      );
      return SignInOutcome.failed;
    }
    return _run(
      SignInTask.email,
      (accounts) => accounts.requestCode(address),
      done: SignInOutcome.codeSent,
    );
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
    var outcome = done;
    try {
      await command(accounts);
    } on IdentityTakenFailure {
      outcome = SignInOutcome.identityTaken;
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
      );
    }
    return outcome;
  }
}
