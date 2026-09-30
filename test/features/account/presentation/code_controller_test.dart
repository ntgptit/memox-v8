import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/controllers/code_controller.dart';
import 'package:memox/features/account/presentation/states/sign_in_state.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';

void main() {
  late AuthWorld world;
  final provider = codeControllerProvider('a@example.com', SignInPurpose.link);

  setUp(() async {
    world = AuthWorld();
    await readyAnonymous(world);
    await world.coordinator.requestCode('a@example.com');
  });
  tearDown(() => world.close());

  ProviderContainer containerOf() {
    final container = ProviderContainer(overrides: accountOverrides(world));
    addTearDown(container.dispose);
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
}
