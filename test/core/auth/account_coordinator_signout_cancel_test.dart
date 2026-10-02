import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../../support/auth_fakes.dart';

// Critique 2026-10-02 (F2): a sign-out stopped before anything on the
// device was removed goes back to the account as it was (auth spec #39a).
void main() {
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// Account X with two unsent changes, its sign-out stopped offline.
  Future<String> stoppedOffline() async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 5
      ..pending = 2;
    world.network.goOffline();
    await world.coordinator.signOut();
    expect(world.state, isA<Transitioning>());
    return x;
  }

  test('offline: X keeps everything, waits for the network, then is ready '
      'and syncing', () async {
    final x = await stoppedOffline();

    await world.coordinator.cancelSignOut();

    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
    expect(world.gateway.currentUserId, x);
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
    expect(world.state, isA<Validating>());

    world.network.goOnline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.sync.paused, isFalse);
    expect(world.device.resets, 0);
  });

  test('back online before the cancel: X is ready at once', () async {
    final x = await stoppedOffline();
    // The server answers again; no reconnect event has resumed the sign-out.
    world.server.offline = false;

    await world.coordinator.cancelSignOut();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.sync.paused, isFalse);
  });

  test("with the SDK's session gone meanwhile, X waits for a sign-in with "
      'its data kept', () async {
    await stoppedOffline();
    world.gateway.dropSession();

    await world.coordinator.cancelSignOut();

    expect(world.state, isA<ReauthRequired>());
    expect(world.device.resets, 0);
  });

  test('nothing to cancel is refused', () async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();

    await expectLater(world.coordinator.cancelSignOut(), throwsStateError);
  });

  test('a Cancel that arrives after the reconnect finished the sign-out is '
      'refused, and the sign-out stands (final review)', () async {
    await stoppedOffline();
    world.network.goOnline();
    await pumpEventQueue();

    await expectLater(world.coordinator.cancelSignOut(), throwsStateError);
    expect(world.device.resets, 1);
    expect(await world.store.transition(), isNull);
  });
}
