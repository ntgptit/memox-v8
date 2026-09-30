import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// The final review of the core-auth branch: each case reproduces a finding.
void main() {
  const xEmail = 'x@example.com';
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  Future<String> readyAccount({int pending = 2}) async {
    final x = world.server.addUser(email: xEmail).id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 4
      ..pending = pending;
    return x;
  }

  group('C1: no session at launch but a last known account', () {
    test(
      'a refused account stays waiting for its sign-in across a relaunch',
      () async {
        final x = await readyAccount();
        world.gateway.dropSession();
        await pumpEventQueue();
        expect(world.state, isA<ReauthRequired>());

        world.boot();
        await world.coordinator.start();

        expect(
          world.state,
          isA<ReauthRequired>().having((s) => s.last.id, 'last', x),
        );
        expect(world.server.anonymousCreated, 0);
        expect(world.device.owner, x);
        expect(world.device.pushes, isEmpty);
        expect(world.sync.paused, isTrue);
      },
    );

    test(
      'an anonymous session gone before launch recovers with a full push',
      () async {
        final a = await readyAnonymous(world);
        world.gateway.dropSession();

        world.boot();
        await world.coordinator.start();

        final user = (world.state as Ready).user;
        expect(user.id, isNot(a));
        expect(world.device.markAllPendingCalls, greaterThan(0));
        expect(world.device.owner, user.id);
        expect(world.device.resets, 0);
      },
    );
  });

  test('I1: a deletion retried with no session clears nothing, reopens the '
      'gate and waits for a sign-in', () async {
    final x = await readyAccount();
    world.server.users.remove(x);
    world.gateway.forgetSession();
    await world.store.saveTransition(
      AccountTransition(
        opId: 'op-x',
        kind: TransitionKind.delete,
        sourceUserId: x,
        sourceIsAnonymous: false,
        stage: TransitionStage.started,
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    world.boot();
    await world.coordinator.start();

    expect(
      world.state,
      isA<ReauthRequired>().having((s) => s.last.id, 'last', x),
    );
    expect(world.gate.isClosed, isFalse);
    expect(await world.store.transition(), isNull);
    expect(world.device.resets, 0);
    expect(world.notices, [isA<DeleteRefused>()]);
  });

  group('I2: rows the server refused are not lost silently', () {
    test(
      'a sign-out stops while refused rows exist on the device only',
      () async {
        final x = await readyAccount(pending: 0);
        world.device.refused = 1;

        await world.coordinator.signOut();

        expect(
          world.state,
          isA<Transitioning>().having(
            (s) => s.error,
            'error',
            isA<UnsentChangesFailure>(),
          ),
        );
        expect(world.device.resets, 0);
        expect(world.gateway.currentUserId, x);
      },
    );

    test('accepting the loss on the same sign-out goes on', () async {
      final x = await readyAccount(pending: 0);
      world.device.refused = 1;
      await world.coordinator.signOut();

      await world.coordinator.signOut(discardUnsent: true);

      expect(
        world.state,
        isA<Ready>().having((s) => s.user.id, 'id', isNot(x)),
      );
      expect(world.device.resets, 1);
    });
  });

  test('I3: an error on the SDK auth stream is handled, not thrown', () async {
    await readyAnonymous(world);

    world.gateway.emitError();
    await pumpEventQueue();

    expect(world.state, isA<Ready>());
  });

  test(
    'I5: a server error while validating is retried, and sync starts',
    () async {
      world.api.serverFailuresOnMe = 1;
      world.boot();

      await world.coordinator.start();
      expect(world.state, isA<Validating>());
      await pumpEventQueue(times: 50);

      expect(world.state, isA<Ready>());
      expect(world.sync.paused, isFalse);
    },
  );

  test('I6: the target sign-in waits until the source is sent', () async {
    final x = await readyAccount();
    world.server.addUser(email: 'y@example.com');
    world.network.goOffline();
    await world.coordinator.beginSwitch(choice: TransitionChoice.discard);
    expect((await world.store.transition())!.stage, TransitionStage.started);
    world.server.offline = false;

    await world.coordinator.requestCode('y@example.com');
    await expectLater(
      world.coordinator.verifyCode('y@example.com', FakeAuthGateway.code),
      throwsA(isA<StateError>()),
    );

    expect(world.device.resets, 0);
    expect(world.gateway.currentUserId, x);
  });
}
