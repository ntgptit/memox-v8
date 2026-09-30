import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';

void main() {
  late AuthWorld world;
  late ProviderContainer container;
  final provider = signInControllerProvider(SignInPurpose.link);

  setUp(() async {
    world = AuthWorld();
    await readyAnonymous(world);
    container = ProviderContainer(overrides: accountOverrides(world));
    container.listen(provider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await world.close();
  });

  SignInController controller() => container.read(provider.notifier);
  SignInState state() => container.read(provider);

  test('a mistyped address is refused before anything is sent', () async {
    expect(await controller().sendCode('a@'), SignInOutcome.failed);

    expect(state().problem, SignInProblem.invalidEmail);
    expect(state().problemTask, SignInTask.email);
    expect(world.server.sentCodes, isEmpty);
  });

  test('a free address gets a code', () async {
    expect(
      await controller().sendCode(' a@example.com '),
      SignInOutcome.codeSent,
    );

    expect(world.server.sentCodes['a@example.com'], FakeAuthGateway.code);
    expect(state().problem, isNull);
    expect(state().isRunning, isFalse);
  });

  test(
    "another account's address is identity taken, with nothing to say",
    () async {
      world.server.addUser(email: 'b@example.com');

      expect(
        await controller().sendCode('b@example.com'),
        SignInOutcome.identityTaken,
      );
      expect(state().problem, isNull);
    },
  );

  test('offline says offline', () async {
    world.network.goOffline();

    expect(await controller().sendCode('a@example.com'), SignInOutcome.failed);
    expect(state().problem, SignInProblem.offline);
  });

  test('a rate limit says so', () async {
    world.gateway.failNextRequest = const RateLimitedFailure();

    expect(await controller().sendCode('a@example.com'), SignInOutcome.failed);
    expect(state().problem, SignInProblem.rateLimited);
  });

  test(
    'a second press while one runs sends nothing (Review Focus 3)',
    () async {
      final first = controller().sendCode('a@example.com');
      final second = await controller().sendCode('a@example.com');

      expect(second, SignInOutcome.none);
      expect(await first, SignInOutcome.codeSent);
    },
  );

  test('Google attaches the account to this user', () async {
    expect(await controller().continueWithGoogle(), SignInOutcome.signedIn);

    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'g@example.com'),
    );
    expect(state().isRunning, isFalse);
  });

  test('a cancelled Google pick says nothing', () async {
    world.gateway.googleCancels = true;

    expect(await controller().continueWithGoogle(), SignInOutcome.none);
    expect(state().problem, isNull);
  });

  test('a Google failure is marked as Google\'s', () async {
    world.network.goOffline();

    expect(await controller().continueWithGoogle(), SignInOutcome.failed);
    expect(state().problemTask, SignInTask.google);
  });
}
