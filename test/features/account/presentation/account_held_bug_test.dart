import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/held_bug_capture.dart';

/// A code step whose minute's wait is over, so Resend may be asked at once.
class _WaitOver extends CodeController {
  @override
  CodeState build(String email, SignInPurpose purpose) => const CodeState();
}

// LIB-6: an account command that meets a bug, not a Failure, releases its
// flow and reports it (ADR-016). The coordinator's own StateError (the
// account moved on) is an answer, not a bug: it ends as `failed`, unreported.
void main() {
  late AuthWorld world;
  late ProviderContainer container;

  setUp(() async {
    world = AuthWorld();
    await readyAnonymous(world);
    container = ProviderContainer(overrides: accountOverrides(world));
  });
  tearDown(() async {
    container.dispose();
    await world.close();
  });

  /// The next call the app makes to the server dies on a bug.
  void killNextCall() => world.kill.at = world.kill.steps + 1;

  final signIn = signInControllerProvider(SignInPurpose.link);
  final code = codeControllerProvider('a@example.com', SignInPurpose.link);
  final manage = accountManageControllerProvider;

  group('screen 30 sign-in', () {
    setUp(() => container.listen(signIn, (_, _) {}));

    test('a send that dies on a bug is no longer running and fails with the '
        'failed problem (_run)', () async {
      final reported = captureReportedBugs();
      killNextCall();

      final outcome = await container
          .read(signIn.notifier)
          .sendCode('a@example.com');

      expect(outcome, SignInOutcome.failed);
      expectOneBugReported(reported, bug: isA<Killed>());
      final state = container.read(signIn);
      expect(state.isRunning, isFalse);
      expect(state.problem, SignInProblem.failed);
      expect(state.problemTask, SignInTask.email);
    });

    test('the account moving on is a failed send, not a bug', () async {
      await linkEmail(world);
      final reported = captureReportedBugs();

      final outcome = await container
          .read(signIn.notifier)
          .sendCode('b@example.com');

      expect(outcome, SignInOutcome.failed);
      expect(reported, isEmpty);
      expect(container.read(signIn).isRunning, isFalse);
      expect(container.read(signIn).problem, SignInProblem.failed);
    });
  });

  group('screen 31 code', () {
    setUp(() => container.listen(code, (_, _) {}));

    test('a check that dies on a bug is no longer verifying and fails with '
        'the failed problem (verify)', () async {
      await world.coordinator.requestCode('a@example.com');
      final reported = captureReportedBugs();
      killNextCall();

      final isSignedIn = await container
          .read(code.notifier)
          .verify(FakeAuthGateway.code);

      expect(isSignedIn, isFalse);
      expectOneBugReported(reported, bug: isA<Killed>());
      final state = container.read(code);
      expect(state.isVerifying, isFalse);
      expect(state.problem, SignInProblem.failed);
    });

    test('the account moving on is a failed check, not a bug', () async {
      await linkEmail(world);
      final reported = captureReportedBugs();

      final isSignedIn = await container
          .read(code.notifier)
          .verify(FakeAuthGateway.code);

      expect(isSignedIn, isFalse);
      expect(reported, isEmpty);
      expect(container.read(code).isVerifying, isFalse);
      expect(container.read(code).problem, SignInProblem.failed);
    });
  });

  test('a resend that dies on a bug is no longer resending and is refused '
      'with the failed problem (resend)', () async {
    final resending = ProviderContainer(
      overrides: [...accountOverrides(world), code.overrideWith(_WaitOver.new)],
    );
    addTearDown(resending.dispose);
    resending.listen(code, (_, _) {});
    final reported = captureReportedBugs();
    killNextCall();

    final outcome = await resending.read(code.notifier).resend();

    expect(outcome, ResendOutcome.refused);
    expectOneBugReported(reported, bug: isA<Killed>());
    final state = resending.read(code);
    expect(state.isResending, isFalse);
    expect(state.problem, SignInProblem.failed);
    expect(state.canResend, isTrue);
  });

  group('screens 30 and 32 account commands', () {
    setUp(() => container.listen(manage, (_, _) {}));

    test('a command that dies on a bug is no longer running and says it '
        'failed (_run)', () async {
      final reported = captureReportedBugs();
      killNextCall();

      final result = await container
          .read(manage.notifier)
          .signOut(discardUnsent: true);

      expect(result, AccountCommandResult.failed);
      expectOneBugReported(reported, bug: isA<Killed>());
      expect(container.read(manage), isFalse);
    });

    test('the account moving on is a failed command, not a bug', () async {
      final reported = captureReportedBugs();

      final result = await container
          .read(manage.notifier)
          .continueWithoutAccount();

      expect(result, AccountCommandResult.failed);
      expect(reported, isEmpty);
      expect(container.read(manage), isFalse);
    });
  });
}
