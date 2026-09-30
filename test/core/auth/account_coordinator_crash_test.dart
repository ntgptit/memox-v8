import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §9 "Crash injection" and "Network": a kill, or a lost network,
// at each step of Switch, SignOut, Delete and AnonRecovery. After a launch
// and the user's own next steps, the invariants of §3.4 hold.
const _bEmail = 'b@example.com';
const _xEmail = 'x@example.com';

typedef _Step = Future<void> Function(AuthWorld world);

/// One flow: [setup] builds the world before the flow and returns what
/// [check] needs; [steps] are what the user does, in order; [target] is the
/// account a pending switch signs in to.
class _Flow {
  const _Flow(this.name, this.setup, this.steps, this.check, {this.target});

  final String name;
  final Future<Map<String, String>> Function(AuthWorld) setup;
  final List<_Step> steps;
  final void Function(AuthWorld, Map<String, String>, String reason) check;
  final String? target;
}

/// The user's steps in order. The app dies at the first kill: nothing after
/// it runs. A failure is what the user sees, and they go on.
Future<void> _run(AuthWorld world, List<_Step> steps) async {
  for (final step in steps) {
    try {
      await step(world);
    } on Killed {
      return;
    } on Failure {
      // Shown on screen; the next step is the user's next tap.
    } on StateError {
      // A command the state does not take: the screen would not offer it.
    }
  }
}

/// A launch after a kill.
Future<void> _launch(AuthWorld world) async {
  world.boot();
  await world.coordinator.start();
}

/// The user's next steps: a target sign-in when asked, Retry otherwise.
Future<void> _settle(AuthWorld world, String? target) async {
  for (var round = 0; round < 6; round++) {
    final state = world.state;
    if (state is Ready) return;
    final asks =
        (state is Transitioning && state.isAwaitingTargetSignIn) ||
        (state is Recovering && state.isAwaitingTargetSignIn);
    if (asks && target != null) {
      await world.coordinator.requestCode(target);
      await world.coordinator.verifyCode(target, FakeAuthGateway.code);
    } else {
      await world.coordinator.retry();
    }
  }
}

/// §3.4, checked on every outcome.
Future<void> _expectSettled(AuthWorld world, String reason) async {
  expect(world.state, isA<Ready>(), reason: reason);
  expect(world.gate.isClosed, isFalse, reason: reason);
  expect(await world.store.transition(), isNull, reason: reason);
  expect(world.secrets.values, isEmpty, reason: reason);
  expect(world.sync.paused, isFalse, reason: reason);
  for (final push in world.device.pushes) {
    expect(push.signedIn, push.owner, reason: '$reason: pushed $push');
  }
}

String _userId(AuthWorld world) => (world.state as Ready).user.id;

final _flows = [
  _Flow(
    'merge switch',
    (world) async {
      final a = await readyAnonymous(world);
      final b = world.server.addUser(email: _bEmail).id;
      return {'a': a, 'b': b};
    },
    [
      (world) => world.coordinator.requestCode(_bEmail),
      (world) => world.coordinator.beginSwitch(
        choice: TransitionChoice.merge,
        targetHint: _bEmail,
      ),
      (world) => world.coordinator.requestCode(_bEmail),
      (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
    ],
    (world, ids, reason) {
      final merged = world.server.receipts.isNotEmpty;
      if (merged) {
        // A committed merge never returns to A.
        expect(_userId(world), ids['b'], reason: reason);
        expect(world.device.owner, ids['b'], reason: reason);
        expect(
          world.server.users.containsKey(ids['a']),
          isFalse,
          reason: reason,
        );
        final afterB = world.gateway.history.skipWhile((id) => id != ids['b']);
        expect(afterB, isNot(contains(ids['a'])), reason: reason);
      } else {
        // An uncommitted merge never clears A.
        expect(_userId(world), ids['a'], reason: reason);
        expect(world.device.resets, 0, reason: reason);
        expect(world.device.owner, ids['a'], reason: reason);
      }
      expect(
        world.server.anonymousCreated,
        1,
        reason: '$reason: no second anonymous user',
      );
    },
    target: _bEmail,
  ),
  _Flow(
    'discard switch',
    (world) async {
      final a = await readyAnonymous(world);
      final b = world.server.addUser(email: _bEmail).id;
      return {'a': a, 'b': b};
    },
    [
      (world) =>
          world.coordinator.beginSwitch(choice: TransitionChoice.discard),
      (world) => world.coordinator.requestCode(_bEmail),
      (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
    ],
    (world, ids, reason) {
      final user = _userId(world);
      expect(user, anyOf(ids['a'], ids['b']), reason: reason);
      if (user == ids['a']) {
        expect(world.device.resets, 0, reason: reason);
      } else {
        expect(world.device.owner, ids['b'], reason: reason);
      }
      expect(world.server.users.containsKey(ids['a']), isTrue, reason: reason);
      expect(world.server.receipts, isEmpty, reason: reason);
    },
    target: _bEmail,
  ),
  _Flow(
    'sign-out',
    (world) async {
      final x = world.server.addUser(email: _xEmail).id;
      world.gateway.adopt(x);
      world.boot();
      await world.coordinator.start();
      world.device
        ..owner = x
        ..rows = 4
        ..pending = 2;
      return {'x': x};
    },
    [(world) => world.coordinator.signOut()],
    (world, ids, reason) {
      final user = _userId(world);
      if (user == ids['x']) {
        expect(world.device.resets, 0, reason: reason);
      } else {
        expect((world.state as Ready).user.isAnonymous, isTrue, reason: reason);
        expect(world.device.resets, greaterThan(0), reason: reason);
      }
    },
  ),
  _Flow(
    'deletion',
    (world) async {
      final x = world.server.addUser(email: _xEmail).id;
      world.gateway.adopt(x);
      world.boot();
      await world.coordinator.start();
      world.device
        ..owner = x
        ..rows = 4;
      return {'x': x};
    },
    [(world) => world.coordinator.deleteAccount()],
    (world, ids, reason) {
      final deleted = !world.server.users.containsKey(ids['x']);
      if (deleted) {
        expect(_userId(world), isNot(ids['x']), reason: reason);
        expect(world.device.resets, greaterThan(0), reason: reason);
      } else {
        expect(_userId(world), ids['x'], reason: reason);
        expect(world.device.resets, 0, reason: reason);
      }
    },
  ),
  _Flow(
    'anonymous recovery',
    (world) async {
      final a = await readyAnonymous(world);
      world.server.deleteUser(a);
      return {'a': a};
    },
    [_launch],
    (world, ids, reason) {
      expect(_userId(world), isNot(ids['a']), reason: reason);
      expect(
        world.server.anonymousCreated,
        2,
        reason: '$reason: exactly one new anonymous user',
      );
      expect(world.device.resets, 0, reason: reason);
      expect(world.device.owner, _userId(world), reason: reason);
      expect(
        world.device.pending,
        greaterThanOrEqualTo(world.device.rows),
        reason: reason,
      );
    },
  ),
];

/// The steps an undisturbed run of [flow] takes.
Future<int> _stepsOf(_Flow flow) async {
  final world = AuthWorld();
  try {
    await flow.setup(world);
    world.kill.steps = 0;
    await _run(world, flow.steps);
    return world.kill.steps;
  } finally {
    await world.close();
  }
}

void main() {
  for (final flow in _flows) {
    test('${flow.name}: a kill at any step keeps the invariants', () async {
      final total = await _stepsOf(flow);
      expect(total, greaterThan(3));
      for (var k = 1; k <= total; k++) {
        final reason = '${flow.name}, killed at step $k of $total';
        final world = AuthWorld();
        try {
          final ids = await flow.setup(world);
          world.kill
            ..steps = 0
            ..at = k;
          await _run(world, flow.steps);
          world.kill.at = null;
          await _launch(world);
          await _settle(world, flow.target);
          await _expectSettled(world, reason);
          flow.check(world, ids, reason);
        } finally {
          await world.close();
        }
      }
    });

    test('${flow.name}: the network lost at any step never signs out or '
        'clears, and the flow finishes once it is back', () async {
      final total = await _stepsOf(flow);
      for (var k = 1; k <= total; k++) {
        final reason = '${flow.name}, offline from step $k of $total';
        final world = AuthWorld();
        try {
          final ids = await flow.setup(world);
          final resetsBefore = world.device.resets;
          world.kill
            ..steps = 0
            ..offlineAt = k;
          await _run(world, flow.steps);
          world.kill.offlineAt = null;
          if (flow.name.contains('switch')) {
            expect(
              world.device.resets == resetsBefore ||
                  world.server.receipts.isNotEmpty ||
                  world.device.pulls.isNotEmpty ||
                  (await world.store.transition())?.stage ==
                      TransitionStage.localCleared,
              isTrue,
              reason:
                  '$reason: nothing cleared while offline before the target took over',
            );
          }
          world.network.goOnline();
          await pumpEventQueue();
          await _settle(world, flow.target);
          await _expectSettled(world, reason);
          flow.check(world, ids, reason);
        } finally {
          await world.close();
        }
      }
    });
  }

  test(
    'named case: killed after the merge committed, before merged was saved',
    () async {
      final world = AuthWorld();
      addTearDown(world.close);
      final a = await readyAnonymous(world);
      final b = world.server.addUser(email: _bEmail).id;
      await _run(world, [(world) => world.coordinator.requestCode(_bEmail)]);
      await world.coordinator.beginSwitch(choice: TransitionChoice.merge);
      world.server.afterMergeCommit = () => throw const Killed();
      await world.coordinator.requestCode(_bEmail);
      await _run(world, [
        (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
      ]);
      world.server.afterMergeCommit = null;
      expect(
        (await world.store.transition())!.stage,
        TransitionStage.targetSignedIn,
      );

      world.boot();
      await world.coordinator.start();

      await _expectSettled(world, 'after-commit kill');
      expect(_userId(world), b);
      expect(world.server.receipts, hasLength(1));
      expect(world.server.users.containsKey(a), isFalse);
    },
  );

  test(
    'named case: killed between the target sign-in and saving targetSignedIn',
    () async {
      final world = AuthWorld();
      addTearDown(world.close);
      await readyAnonymous(world);
      final b = world.server.addUser(email: _bEmail).id;
      await _run(world, [(world) => world.coordinator.requestCode(_bEmail)]);
      await world.coordinator.beginSwitch(choice: TransitionChoice.merge);
      world.gateway.afterSignIn = () => throw const Killed();
      await world.coordinator.requestCode(_bEmail);
      await _run(world, [
        (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
      ]);
      world.gateway.afterSignIn = null;
      expect((await world.store.transition())!.stage, TransitionStage.claimed);

      world.boot();
      await world.coordinator.start();

      await _expectSettled(world, 'sign-in kill');
      expect(_userId(world), b);
    },
  );
}
