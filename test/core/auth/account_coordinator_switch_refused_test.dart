import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 #19 and #34 after DEV-190 (the source's logs are shipped
// before the target sign-in) and DEV-191 (rows the server refused stop a
// merge with a way on, and never a discard).
void main() {
  const bEmail = 'b@example.com';
  const code = FakeAuthGateway.code;
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// The device on anonymous A, B's account taken: the merge sheet's answer.
  Future<void> switchStarted(TransitionChoice choice) async {
    await readyAnonymous(world);
    world.server.addUser(email: bEmail);
    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );
    await world.coordinator.beginSwitch(choice: choice, targetHint: bEmail);
  }

  Future<void> signInB() async {
    await world.coordinator.requestCode(bEmail);
    await world.coordinator.verifyCode(bEmail, code);
  }

  void expectSettledOn(String userId) {
    expect(world.state, isA<Ready>().having((s) => s.user.id, 'user', userId));
    expect(world.gate.isClosed, isFalse);
    expect(world.secrets.values, isEmpty);
    expect(world.sync.paused, isFalse);
  }

  test("#19 A's logs are shipped once after its push, before B signs in "
      '(DEV-190)', () async {
    await switchStarted(TransitionChoice.merge);
    expect(world.logFlushes, 1);

    await signInB();

    expect(world.logFlushes, 1);
  });

  test('#19 a merge with rows the server refused stops on them, and goes on '
      'once they are kept on the device (DEV-191)', () async {
    await readyAnonymous(world);
    world.server.addUser(email: bEmail);
    world.device.refused = 2;
    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );

    await world.coordinator.beginSwitch(
      choice: TransitionChoice.merge,
      targetHint: bEmail,
    );

    expect(
      world.state,
      isA<Transitioning>()
          .having((s) => s.isAwaitingTargetSignIn, 'asks', isFalse)
          .having(
            (s) => s.error,
            'error',
            isA<UnsentChangesFailure>().having((f) => f.count, 'count', 2),
          ),
    );
    expect((await world.store.transition())!.stage, TransitionStage.started);
    expect(world.logFlushes, 0);

    world.device.refused = 0; // Keep on this device
    await world.coordinator.retry();

    expect(
      world.state,
      isA<Transitioning>()
          .having((s) => s.isAwaitingTargetSignIn, 'asks', isTrue)
          .having((s) => s.error, 'error', isNull),
    );
    expect(world.logFlushes, 1);
  });

  test('#34 a discard switch with rows the server refused goes on: they are '
      'lost with the rest of the device (DEV-191)', () async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 4
      ..pending = 1
      ..refused = 2;
    final y = world.server.addUser(email: 'y@example.com').id;

    await world.coordinator.beginSwitch(choice: TransitionChoice.discard);

    expect(
      world.state,
      isA<Transitioning>()
          .having((s) => s.isAwaitingTargetSignIn, 'asks', isTrue)
          .having((s) => s.error, 'error', isNull),
    );
    expect(
      (await world.store.transition())!.stage,
      TransitionStage.sourcePushed,
    );
    expect(world.device.pushes.single, (signedIn: x, owner: x));
    expect(world.logFlushes, 1);

    await world.coordinator.requestCode('y@example.com');
    await world.coordinator.verifyCode('y@example.com', code);

    expectSettledOn(y);
    expect(world.device.refused, 0);
    expect(world.device.resets, 1);
  });
}
