import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 rows #1–#12, #14, #15 and plan Review Focus 1, on fakes.
void main() {
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  test(
    '#3 #6 #9 a first launch online makes one anonymous user and syncs',
    () async {
      world.boot();
      await world.coordinator.start();

      expect(
        world.state,
        isA<Ready>().having((s) => s.user.isAnonymous, 'anonymous', isTrue),
      );
      expect(world.server.anonymousCreated, 1);
      expect(world.sync.paused, isFalse);
      expect((await world.store.lastKnown())!.id, world.gateway.currentUserId);
    },
  );

  test(
    '#3 offline with no session is local only; #4 it bootstraps on reconnect',
    () async {
      world.network.goOffline();
      world.boot();
      await world.coordinator.start();
      expect(world.state, isA<LocalOnly>());
      expect(world.sync.paused, isTrue);

      world.network.goOnline();
      await pumpEventQueue();

      expect(world.state, isA<Ready>());
      expect(world.server.anonymousCreated, 1);
    },
  );

  test(
    '#7 a network error during the anonymous sign-in is local only',
    () async {
      world.network
        ..goOffline()
        ..claimsOnline = true;
      world.boot();
      await world.coordinator.start();

      expect(world.state, isA<LocalOnly>());
      expect(world.server.anonymousCreated, 0);
    },
  );

  test(
    '#2 #5 a session the SDK holds is validated; no second anonymous user',
    () async {
      world.gateway.adopt(world.server.addUser(anonymous: true).id);
      world.boot();
      await world.coordinator.start();

      expect(world.state, isA<Ready>());
      expect(world.server.anonymousCreated, 1);
    },
  );

  test('#8 R2 offline with a session stays validating with sync paused; #9 on reconnect', () async {
    world.gateway.adopt(world.server.addUser(anonymous: true).id);
    world.network.goOffline();
    world.boot();
    await world.coordinator.start();
    expect(world.state, isA<Validating>());
    expect(world.sync.paused, isTrue);

    world.network.goOnline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>());
    expect(world.sync.paused, isFalse);
  });

  test('#10 #11 #12 an anonymous user the server cleaned up keeps its data, '
      'gets a new anonymous user and pushes everything', () async {
    final a = await readyAnonymous(world);
    world.server.deleteUser(a);

    world.boot();
    await world.coordinator.start();

    final state = world.state as Ready;
    expect(state.user.id, isNot(a));
    expect(state.user.isAnonymous, isTrue);
    expect(world.server.anonymousCreated, 2);
    expect(world.device.markAllPendingCalls, 1);
    expect(world.device.owner, state.user.id);
    expect(world.device.resets, 0);
    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
  });

  test('Review Focus 1: a session the SDK drops while ready, anonymous, '
      'recovers into a new anonymous user', () async {
    final a = await readyAnonymous(world);

    world.gateway.dropSession();
    await pumpEventQueue();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', isNot(a)));
    expect(world.device.markAllPendingCalls, 1);
    expect(world.device.resets, 0);
  });

  test(
    '#14 an account whose session is refused keeps its data and waits',
    () async {
      final b = world.server.addUser(email: 'b@example.com');
      world.gateway.adopt(b.id);
      world.boot();
      await world.coordinator.start();
      world.device
        ..owner = b.id
        ..pending = 2;

      world.gateway.dropSession();
      await pumpEventQueue();

      expect(
        world.state,
        isA<ReauthRequired>().having((s) => s.last.id, 'last', b.id),
      );
      expect(world.device.resets, 0);
      expect(world.device.pending, 2);
      expect(world.sync.paused, isTrue);
    },
  );

  test('#15 offline while ready stays ready and signs nobody out', () async {
    final a = await readyAnonymous(world);

    world.network.goOffline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>());
    expect(world.gateway.currentUserId, a);
  });

  test(
    '#1 a pending anonymous recovery is finished before anything else',
    () async {
      final a = await readyAnonymous(world);
      world.server.deleteUser(a);
      await world.store.saveTransition(
        AccountTransition(
          opId: 'op-x',
          kind: TransitionKind.anonRecovery,
          sourceUserId: a,
          sourceIsAnonymous: true,
          stage: TransitionStage.started,
          createdAt: t0,
          updatedAt: t0,
        ),
      );

      world.boot();
      await world.coordinator.start();

      expect(world.state, isA<Ready>());
      expect(world.gateway.currentUserId, isNot(a));
      expect(world.server.anonymousCreated, 2);
      expect(await world.store.transition(), isNull);
    },
  );

  test('R3 prepare shuts the gate for a pending blocking transition', () async {
    await world.store.saveTransition(
      AccountTransition(
        opId: 'op-x',
        kind: TransitionKind.signOut,
        stage: TransitionStage.started,
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    world.boot();
    await world.coordinator.prepare();

    expect(world.gate.isClosed, isTrue);
    expect(world.state, isA<Booting>());
  });

  test(
    'prepare purges the secrets of an operation that is no longer pending',
    () async {
      world.secrets.values.addAll({
        'account.backup.old': 'r',
        'account.claim.old': 'c',
      });

      world.boot();
      await world.coordinator.prepare();

      expect(world.secrets.values, isEmpty);
    },
  );
}
