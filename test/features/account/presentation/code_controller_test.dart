import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/providers/last_code_sent_provider.dart';
import 'package:memox/features/account/presentation/states/code_state.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';
import '../../../support/fake_day_clock.dart';

void main() {
  late AuthWorld world;
  final provider = codeControllerProvider('a@example.com', SignInPurpose.link);

  late FakeDayClock clock;

  setUp(() async {
    clock = FakeDayClock(DateTime(2026, 10, 3, 9));
    world = AuthWorld();
    await readyAnonymous(world);
    await world.coordinator.requestCode('a@example.com');
  });
  tearDown(() => world.close());

  /// A container whose controller is not built yet, so a test can record a
  /// send first.
  ProviderContainer bareContainer() {
    final container = ProviderContainer(
      overrides: [
        ...accountOverrides(world),
        dayClockProvider.overrideWithValue(clock),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ProviderContainer containerOf() {
    final container = bareContainer();
    container.listen(provider, (_, _) {});
    return container;
  }

  test('Resend waits a minute, counting down each second', () {
    fakeAsync((async) {
      final container = ProviderContainer(overrides: accountOverrides(world));
      container.listen(provider, (_, _) {});

      expect(container.read(provider).resendIn, CodeController.resendWait);
      async.elapse(const Duration(seconds: 59));
      expect(container.read(provider).resendIn, const Duration(seconds: 1));
      expect(container.read(provider).canResend, isFalse);
      async.elapse(const Duration(seconds: 1));
      expect(container.read(provider).canResend, isTrue);

      container.dispose();
    });
  });

  test('the right code signs in', () async {
    final container = containerOf();

    expect(
      await container.read(provider.notifier).verify(FakeAuthGateway.code),
      isTrue,
    );
    expect(
      world.state,
      isA<Ready>().having((s) => s.user.email, 'email', 'a@example.com'),
    );
  });

  test('a wrong code says so, and the wait goes on', () async {
    final container = containerOf();

    expect(await container.read(provider.notifier).verify('000000'), isFalse);
    expect(container.read(provider).problem, SignInProblem.wrongCode);
    expect(container.read(provider).isVerifying, isFalse);
    expect(container.read(provider).canResend, isFalse);
  });

  group('a code sent a moment ago (2.41, 2.44)', () {
    void sentAgo(
      ProviderContainer container,
      Duration ago, {
      String email = 'A@Example.com',
      SignInPurpose purpose = SignInPurpose.link,
    }) => container
        .read(lastCodeSentProvider.notifier)
        .record(purpose, email, clock.current.subtract(ago));

    test('the wait picks up where the last send left it, in whole seconds', () {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 20, milliseconds: 400));
      container.listen(provider, (_, _) {});

      expect(container.read(provider).resendIn, const Duration(seconds: 40));
      expect(container.read(provider).canResend, isFalse);
    });

    test('a send older than the wait leaves Resend open at once', () {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});

      expect(container.read(provider).canResend, isTrue);
    });

    for (final (email, purpose) in [
      ('b@example.com', SignInPurpose.link),
      ('a@example.com', SignInPurpose.reauth),
    ]) {
      test('a send to $email for ${purpose.name} is another step', () {
        final container = bareContainer();
        sentAgo(
          container,
          const Duration(seconds: 30),
          email: email,
          purpose: purpose,
        );
        container.listen(provider, (_, _) {});

        expect(container.read(provider).resendIn, CodeController.resendWait);
      });
    }

    test('a successful resend records the send and waits a minute', () async {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});

      expect(
        await container.read(provider.notifier).resend(),
        ResendOutcome.sent,
      );

      expect(container.read(provider).resendIn, CodeController.resendWait);
      expect(container.read(lastCodeSentProvider)?.sentAt, clock.current);
    });

    test('a rate-limited resend waits a minute too, and leaving the step '
        'keeps what is left of it (2.44)', () async {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});
      world.gateway.failNextRequest = const RateLimitedFailure();

      expect(
        await container.read(provider.notifier).resend(),
        ResendOutcome.refused,
      );

      expect(container.read(provider).problem, SignInProblem.rateLimited);
      expect(container.read(provider).resendIn, CodeController.resendWait);
      // Leave and come back ten seconds later: the controller is built again.
      clock.current = clock.current.add(const Duration(seconds: 10));
      container.invalidate(provider);
      expect(container.read(provider).resendIn, const Duration(seconds: 50));
    });

    test('any other refusal leaves Resend open and records nothing', () async {
      final container = bareContainer();
      sentAgo(container, const Duration(seconds: 61));
      container.listen(provider, (_, _) {});
      world.network.goOffline();

      expect(
        await container.read(provider.notifier).resend(),
        ResendOutcome.refused,
      );

      expect(container.read(provider).problem, SignInProblem.offline);
      expect(container.read(provider).canResend, isTrue);
      expect(
        container.read(lastCodeSentProvider)?.sentAt,
        clock.current.subtract(const Duration(seconds: 61)),
      );
    });
  });
}
