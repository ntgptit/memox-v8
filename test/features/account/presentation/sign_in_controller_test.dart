import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/controllers/sign_in_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/fake_day_clock.dart';

void main() {
  late AuthWorld world;
  late ProviderContainer container;
  final provider = signInControllerProvider(SignInPurpose.link);

  late FakeDayClock clock;

  setUp(() async {
    clock = FakeDayClock(DateTime(2026, 10, 3, 9));
    world = AuthWorld();
    await readyAnonymous(world);
    container = ProviderContainer(
      overrides: [
        ...accountOverrides(world),
        dayClockProvider.overrideWithValue(clock),
      ],
    );
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

  group('a code already on its way (2.41)', () {
    test('the same address inside the wait reopens the code step without '
        'sending, whatever its case or spaces', () async {
      expect(
        await controller().sendCode('a@example.com'),
        SignInOutcome.codeSent,
      );
      world.server.sentCodes.clear();
      clock.current = clock.current.add(const Duration(seconds: 30));

      expect(
        await controller().sendCode('  A@Example.com '),
        SignInOutcome.codeSent,
      );

      expect(world.server.sentCodes, isEmpty);
      expect(state().isRunning, isFalse);
    });

    test('another address sends, and so does the same one once the wait is '
        'over', () async {
      await controller().sendCode('a@example.com');
      world.server.sentCodes.clear();

      expect(
        await controller().sendCode('a@example.org'),
        SignInOutcome.codeSent,
      );
      expect(world.server.sentCodes.keys, ['a@example.org']);

      world.server.sentCodes.clear();
      clock.current = clock.current.add(CodeController.resendWait);
      expect(
        await controller().sendCode('a@example.org'),
        SignInOutcome.codeSent,
      );
      expect(world.server.sentCodes.keys, ['a@example.org']);
    });

    test('a refused send is not recorded: the next press asks the server '
        'again', () async {
      world.gateway.failNextRequest = const RateLimitedFailure();
      expect(
        await controller().sendCode('a@example.com'),
        SignInOutcome.failed,
      );

      expect(
        await controller().sendCode('a@example.com'),
        SignInOutcome.codeSent,
      );
      expect(world.server.sentCodes.keys, ['a@example.com']);
    });
  });

  test('a Google failure is marked as Google\'s', () async {
    world.network.goOffline();

    expect(await controller().continueWithGoogle(), SignInOutcome.failed);
    expect(state().problemTask, SignInTask.google);
  });

  group('reauth', () {
    final reauth = signInControllerProvider(SignInPurpose.reauth);

    setUp(() async {
      await refuseSession(world);
      container.listen(reauth, (_, _) {});
    });

    test('the same address gets its code without a word about loss '
        '(Review Focus 1)', () async {
      expect(
        await container.read(reauth.notifier).sendCode('A@example.com'),
        SignInOutcome.codeSent,
      );
    });

    test('another address with changes unsent asks first', () async {
      expect(
        await container.read(reauth.notifier).sendCode('b@example.com'),
        SignInOutcome.unsentChanges,
      );
      expect(container.read(reauth).unsentCount, 2);
      expect(world.server.sentCodes['b@example.com'], isNull);

      expect(
        await container
            .read(reauth.notifier)
            .sendCode('b@example.com', confirmedLoss: true),
        SignInOutcome.codeSent,
      );
    });

    test('Google as another account asks first too', () async {
      world.gateway.google = const GoogleCredential(
        idToken: 't',
        email: 'g@example.com',
      );
      expect(
        await container.read(reauth.notifier).continueWithGoogle(),
        SignInOutcome.unsentChanges,
      );
      expect(
        await container
            .read(reauth.notifier)
            .continueWithGoogle(confirmedLoss: true),
        SignInOutcome.signedIn,
      );
    });
  });
}
