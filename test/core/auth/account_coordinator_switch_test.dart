import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/secret_store.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 rows #16–#35, plan rulings 4, 7–9 and Review Focus 2–3.
void main() {
  const bEmail = 'b@example.com';
  const code = FakeAuthGateway.code;
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  Future<String> existingB() async => world.server.addUser(email: bEmail).id;

  /// The device on anonymous A, B's account taken: the merge sheet's answer.
  Future<(String, String)> switchStarted(TransitionChoice choice) async {
    final a = await readyAnonymous(world);
    final b = await existingB();
    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );
    await world.coordinator.beginSwitch(choice: choice, targetHint: bEmail);
    return (a, b);
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

  test(
    '#16 a code attaches the email to the same user; nothing is cleared',
    () async {
      final a = await readyAnonymous(world);

      await world.coordinator.requestCode('a@example.com');
      await world.coordinator.verifyCode('a@example.com', code);

      expect(
        world.state,
        isA<Ready>()
            .having((s) => s.user.id, 'id', a)
            .having((s) => s.user.isAnonymous, 'anonymous', isFalse),
      );
      expect(world.device.resets, 0);
    },
  );

  test('#16 a Google identity attaches to the same user', () async {
    final a = await readyAnonymous(world);

    await world.coordinator.continueWithGoogle();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', a));
    expect((world.state as Ready).user.email, 'g@example.com');
  });

  test('#17 a taken email changes nothing and says so', () async {
    final a = await readyAnonymous(world);
    await existingB();

    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );

    expectSettledOn(a);
    expect(await world.store.transition(), isNull);
  });

  test(
    '#18 #19 #20 a merge shuts the gate, sends A, claims, then asks for B',
    () async {
      final (a, _) = await switchStarted(TransitionChoice.merge);

      final t = (await world.store.transition())!;
      expect(t.kind, TransitionKind.switchAccount);
      expect(t.stage, TransitionStage.claimed);
      expect(world.gate.isClosed, isTrue);
      expect(world.sync.paused, isTrue);
      expect(world.device.pushes.single, (signedIn: a, owner: a));
      expect(world.secrets.values.keys, [claimSecretKey(t.opId)]);
      expect(
        world.state,
        isA<Transitioning>().having((s) => s.needsTargetSignIn, 'asks', isTrue),
      );
    },
  );

  test(
    '#21 #23 #24 #27–#30 the merge into B clears A from the device and pulls B',
    () async {
      final (a, b) = await switchStarted(TransitionChoice.merge);

      await signInB();

      expectSettledOn(b);
      expect(world.server.users.containsKey(a), isFalse);
      expect(world.server.receipts.values.single.acknowledged, isTrue);
      expect(world.device.resets, 1);
      expect(world.device.pulls, [b]);
      expect(world.device.owner, b);
      expect(world.server.anonymousCreated, 1);
      final afterMerge = world.gateway.history.skipWhile((id) => id != b);
      expect(afterMerge, isNot(contains(a)));
    },
  );

  test('#22 cancel before the target sign-in returns to A as it was', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);

    await world.coordinator.cancelSwitch();

    expectSettledOn(a);
    expect(world.device.resets, 0);
    expect(await world.store.transition(), isNull);
  });

  test(
    '#25 a refused claim goes back to A with its data and a notice',
    () async {
      final (a, _) = await switchStarted(TransitionChoice.merge);
      world.server.claims.clear();

      await signInB();

      expectSettledOn(a);
      expect(world.device.resets, 0);
      expect(world.device.owner, a);
      expect(world.notices, [isA<MergeNotDone>()]);
    },
  );

  test("ruling 8: a refused claim with A's backup unusable keeps the data "
      'under a new anonymous user', () async {
    final (a, b) = await switchStarted(TransitionChoice.merge);
    world.server.claims.clear();
    world.gateway.afterSignIn = () => world.server.revokeTokensOf(a);

    await signInB();

    final user = (world.state as Ready).user;
    expect(user.id, isNot(anyOf(a, b)));
    expect(user.isAnonymous, isTrue);
    expect(world.device.resets, 0);
    expect(world.device.markAllPendingCalls, 1);
    expect(world.notices, [isA<MergeNotDone>()]);
  });

  test('#26 a network error during the merge keeps everything; the reconnect finishes', () async {
    final (_, b) = await switchStarted(TransitionChoice.merge);
    world.gateway.afterSignIn = world.network.goOffline;

    await signInB();
    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.error,
        'error',
        isA<OfflineFailure>(),
      ),
    );
    expect(
      (await world.store.transition())!.stage,
      TransitionStage.targetSignedIn,
    );
    expect(world.device.resets, 0);
    expect(world.gate.isClosed, isTrue);

    world.gateway.afterSignIn = null;
    world.network.goOnline();
    await pumpEventQueue();

    expectSettledOn(b);
  });

  test('#31 a launch that finds the SDK still on A before the target sign-in '
      'cancels the switch', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);

    world.boot();
    await world.coordinator.start();

    expectSettledOn(a);
    expect(world.device.resets, 0);
    expect(await world.store.transition(), isNull);
  });

  test('#32 killed after the target sign-in, before its stage was saved: the '
      'launch finishes the merge with the same op', () async {
    final (a, b) = await switchStarted(TransitionChoice.merge);
    world.gateway.afterSignIn = () => throw const Killed();
    await world.coordinator.requestCode(bEmail);
    await expectLater(
      world.coordinator.verifyCode(bEmail, code),
      throwsA(isA<Killed>()),
    );
    world.gateway.afterSignIn = null;

    world.boot();
    await world.coordinator.start();

    expectSettledOn(b);
    expect(world.server.users.containsKey(a), isFalse);
    expect(world.server.receipts, hasLength(1));
  });

  test(
    '#33 no session and a merge not yet done: back to A through the backup',
    () async {
      final (a, _) = await switchStarted(TransitionChoice.merge);
      final t = (await world.store.transition())!;
      await world.secrets.write(
        backupSecretKey(t.opId),
        world.gateway.refreshToken!,
      );
      world.gateway.forgetSession();

      world.boot();
      await world.coordinator.start();

      expectSettledOn(a);
      expect(world.device.resets, 0);
    },
  );

  test('#33 no session after the merge: the gate stays shut until B signs in again', () async {
    final (_, b) = await switchStarted(TransitionChoice.merge);
    // Killed right after the merge committed, with the SDK's session lost.
    world.server.afterMergeCommit = () {
      world.gateway.forgetSession();
      throw const Killed();
    };
    await world.coordinator.requestCode(bEmail);
    await expectLater(
      world.coordinator.verifyCode(bEmail, code),
      throwsA(isA<Killed>()),
    );
    world.server.afterMergeCommit = null;

    world.boot();
    await world.coordinator.start();
    expect(
      world.state,
      isA<Recovering>().having((s) => s.needsTargetSignIn, 'asks', isTrue),
    );
    expect(world.gate.isClosed, isTrue);

    await signInB();

    expectSettledOn(b);
  });

  test('#34 #35 an account switches to another: X is sent, Y is pulled, no anonymous user in between', () async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 4
      ..pending = 1;
    final y = world.server.addUser(email: 'y@example.com').id;

    await world.coordinator.beginSwitch(choice: TransitionChoice.discard);
    expect(world.device.pushes.single, (signedIn: x, owner: x));
    await world.coordinator.requestCode('y@example.com');
    await world.coordinator.verifyCode('y@example.com', code);

    expectSettledOn(y);
    expect(world.server.anonymousCreated, 0);
    expect(world.server.users.containsKey(x), isTrue);
    expect(world.device.resets, 1);
    expect(world.device.pulls, [y]);
  });

  test(
    '#17 discard: B is pulled, A stays on the server, nothing merges',
    () async {
      final (a, b) = await switchStarted(TransitionChoice.discard);

      await signInB();

      expectSettledOn(b);
      expect(world.server.receipts, isEmpty);
      expect(world.server.users.containsKey(a), isTrue);
      expect(world.device.resets, 1);
    },
  );

  test(
    'Google taken on the link: the switch signs in with the same pick',
    () async {
      final a = await readyAnonymous(world);
      world.server.addUser(email: 'g@example.com');
      await expectLater(
        world.coordinator.continueWithGoogle(),
        throwsA(
          isA<IdentityTakenFailure>().having(
            (f) => f.method,
            'method',
            IdentityMethod.google,
          ),
        ),
      );
      world.gateway.googleCancels = true; // a second pick would now fail

      await world.coordinator.beginSwitch(choice: TransitionChoice.merge);
      await world.coordinator.continueWithGoogle();

      expect((world.state as Ready).user.email, 'g@example.com');
      expect(world.server.users.containsKey(a), isFalse);
    },
  );

  test('Review Focus 2: a reconnect while the target sign-in is asked keeps the switch', () async {
    await switchStarted(TransitionChoice.merge);

    world.network.goOnline();
    await pumpEventQueue();

    expect(
      world.state,
      isA<Transitioning>().having((s) => s.needsTargetSignIn, 'asks', isTrue),
    );
    expect((await world.store.transition())!.stage, TransitionStage.claimed);
  });

  test(
    'Review Focus 3: commands run one at a time; a second switch is refused',
    () async {
      await readyAnonymous(world);
      await existingB();

      final first = world.coordinator.beginSwitch(
        choice: TransitionChoice.discard,
      );
      final second = world.coordinator.beginSwitch(
        choice: TransitionChoice.discard,
      );

      await first;
      await expectLater(second, throwsA(isA<StateError>()));
      expect(world.device.pushes, hasLength(1));
    },
  );

  test('ruling 7: the SDK on another account than the last known one, with no '
      'record, adopts the SDK account and its data', () async {
    final a = await readyAnonymous(world);
    final u = world.server.addUser(email: 'u@example.com').id;
    world.gateway.adopt(u);

    world.boot();
    await world.coordinator.start();

    expectSettledOn(u);
    expect(world.device.resets, 1);
    expect(world.device.pulls, [u]);
    expect(world.device.pushes.where((p) => p.signedIn != p.owner), isEmpty);
    expect(a, isNot(u));
  });

  test('a wrong code keeps the switch waiting for B', () async {
    await switchStarted(TransitionChoice.merge);
    await world.coordinator.requestCode(bEmail);

    await expectLater(
      world.coordinator.verifyCode(bEmail, '000000'),
      throwsA(isA<InvalidCodeFailure>()),
    );

    expect((await world.store.transition())!.stage, TransitionStage.claimed);
    expect(world.gate.isClosed, isTrue);
  });

  test('only an anonymous user merges', () async {
    world.gateway.adopt(world.server.addUser(email: 'x@example.com').id);
    world.boot();
    await world.coordinator.start();

    await expectLater(
      world.coordinator.beginSwitch(choice: TransitionChoice.merge),
      throwsA(isA<ArgumentError>()),
    );
    expect(await world.store.transition(), isNull);
  });
}
