import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec R3 / §3.4 (DEV-227): a transition waits for the sync run in
// progress before it sends the source's changes, signs the device out or
// records itself. FakeSyncControl.pauseGate holds pause() open as a run
// would; a push during it is the run's own ground and throws.
void main() {
  const bEmail = 'b@example.com';
  const xEmail = 'x@example.com';
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// The device on account X, with unsent changes.
  Future<String> readyAccount() async {
    final x = world.server.addUser(email: xEmail).id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 5
      ..pending = 2;
    return x;
  }

  test('a merge records and sends nothing until the run in progress ended; '
      'then A is sent under A (#18, #19)', () async {
    final a = await readyAnonymous(world);
    world.server.addUser(email: bEmail);
    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );
    final run = world.sync.pauseGate = Completer<void>();

    final switching = world.coordinator.beginSwitch(
      choice: TransitionChoice.merge,
      targetHint: bEmail,
    );
    await pumpEventQueue();

    expect(world.sync.paused, isTrue);
    expect(world.gate.isClosed, isTrue);
    expect(await world.store.transition(), isNull);
    expect(world.device.pushes, isEmpty);
    expect(world.gateway.currentUserId, a);

    run.complete();
    await switching;

    expect((await world.store.transition())!.stage, TransitionStage.claimed);
    expect(world.device.pushes, [(signedIn: a, owner: a)]);
    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.isAwaitingTargetSignIn,
        'awaiting target',
        isTrue,
      ),
    );
  });

  test('a sign-out sends, signs out and clears nothing until the run in '
      'progress ended (#39, #40)', () async {
    final x = await readyAccount();
    final run = world.sync.pauseGate = Completer<void>();

    final signingOut = world.coordinator.signOut();
    await pumpEventQueue();

    expect(world.gate.isClosed, isTrue);
    expect(await world.store.transition(), isNull);
    expect(world.device.pushes, isEmpty);
    expect(world.gateway.currentUserId, x);
    expect(world.device.resets, 0);

    run.complete();
    await signingOut;

    expect(world.device.pushes, [(signedIn: x, owner: x)]);
    expect(world.device.resets, 1);
    final user = (world.state as Ready).user;
    expect(user.id, isNot(x));
    expect(user.isAnonymous, isTrue);
    expect(await world.store.transition(), isNull);
  });

  test('a launch with a pending sign-out shuts the gate at once and drives '
      'it only once the run in progress ended (R3 #1)', () async {
    final x = await readyAccount();
    await world.store.saveTransition(
      AccountTransition(
        opId: 'op-x',
        kind: TransitionKind.signOut,
        sourceUserId: x,
        sourceIsAnonymous: false,
        stage: TransitionStage.started,
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    world.boot();
    final run = world.sync.pauseGate = Completer<void>();
    final starting = world.coordinator.start();
    await pumpEventQueue();

    expect(world.gate.isClosed, isTrue);
    expect(world.sync.paused, isTrue);
    expect(world.device.pushes, isEmpty);
    expect(world.gateway.currentUserId, x);
    expect(world.device.resets, 0);
    expect((await world.store.transition())!.stage, TransitionStage.started);

    run.complete();
    await starting;

    expect(world.device.pushes, [(signedIn: x, owner: x)]);
    expect(world.device.resets, 1);
    final user = (world.state as Ready).user;
    expect(user.id, isNot(x));
    expect(user.isAnonymous, isTrue);
    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
  });

  test('the target sign-in advances nothing until the run in progress '
      'ended; A is never pushed under B (#21, #23, #28)', () async {
    final a = await readyAnonymous(world);
    final b = world.server.addUser(email: bEmail).id;
    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );
    await world.coordinator.beginSwitch(
      choice: TransitionChoice.merge,
      targetHint: bEmail,
    );
    await world.coordinator.requestCode(bEmail);
    final run = world.sync.pauseGate = Completer<void>();

    final signingIn = world.coordinator.verifyCode(
      bEmail,
      FakeAuthGateway.code,
    );
    await pumpEventQueue();

    expect(world.gateway.currentUserId, b);
    expect((await world.store.transition())!.stage, TransitionStage.claimed);
    expect(world.device.pulls, isEmpty);
    expect(world.device.resets, 0);

    run.complete();
    await signingIn;

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'user', b));
    expect(world.device.pushes, [(signedIn: a, owner: a)]);
    expect(world.device.pulls, [b]);
    expect(world.device.resets, 1);
  });

  test('a sign-out asked again after it stopped waits for the run in '
      'progress before it sends (#39, final review I2)', () async {
    final x = await readyAccount();
    world.network.goOffline();
    await world.coordinator.signOut();
    expect(
      world.state,
      isA<Transitioning>().having((s) => s.error, 'error', isNotNull),
    );
    expect((await world.store.transition())!.stage, TransitionStage.started);
    world.server.offline = false;
    final run = world.sync.pauseGate = Completer<void>();

    final signingOut = world.coordinator.signOut(discardUnsent: true);
    await pumpEventQueue();

    expect(world.device.pushes, isEmpty);
    expect(world.gateway.currentUserId, x);
    expect(world.device.resets, 0);

    run.complete();
    await signingOut;

    expect(world.device.pushes, [(signedIn: x, owner: x)]);
    expect(world.device.resets, 1);
    expect((world.state as Ready).user.id, isNot(x));
    expect(await world.store.transition(), isNull);
  });
}
