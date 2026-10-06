import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// DEV-192: two short-lived gaps between the session and the account.
// 1. The server's account is gone while the app is Ready (deleted from
//    another device, or by an admin): a sync run refused for want of an
//    account makes the coordinator validate again, which finds #13.
// 2. The network is lost after `account_delete` was sent: the record is
//    kept and Retry finds the account gone (#43), instead of a refusal
//    notice that the next me() then contradicts.
void main() {
  const xEmail = 'x@example.com';
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  Future<String> readyAccount() async {
    final x = world.server.addUser(email: xEmail).id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 4;
    return x;
  }

  void expectNewAnonymous({required String not}) {
    final user = (world.state as Ready).user;
    expect(user.id, isNot(not));
    expect(user.isAnonymous, isTrue);
    expect(world.gate.isClosed, isFalse);
  }

  test('a sync run refused for want of an account validates again: the '
      'profile gone clears the device to a new anonymous user (#13)', () async {
    final x = await readyAccount();
    world.server.users.remove(x);

    await world.coordinator.recheckSession();

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
    expect(await world.store.transition(), isNull);
  });

  test('a sync run refused while the account is still there only validates '
      'again', () async {
    final x = await readyAccount();

    await world.coordinator.recheckSession();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.device.resets, 0);
    expect(world.sync.paused, isFalse);
  });

  test('#42 the network lost after the request was sent keeps the record; '
      'the retry finds the account gone (#43) and finishes', () async {
    final x = await readyAccount();
    world.server.afterDeleteCommit = () =>
        throw const OfflineFailure(cause: 'the response was lost');

    await world.coordinator.deleteAccount();

    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.error,
        'error',
        isA<OfflineFailure>(),
      ),
    );
    expect((await world.store.transition())!.stage, TransitionStage.started);
    expect(world.notices, isEmpty);
    expect(world.device.resets, 0);
    expect(world.gate.isClosed, isTrue);

    world.server.afterDeleteCommit = null;
    await world.coordinator.retry();

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
    expect(world.notices, isEmpty);
    expect(world.server.users.containsKey(x), isFalse);
  });

  test('#42 the network lost before the server took it keeps the record too; '
      'the reconnect deletes', () async {
    final x = await readyAccount();
    world.network.claimsOnline = true;
    world.server.offline = true;

    await world.coordinator.deleteAccount();

    expect(
      world.state,
      isA<Transitioning>().having(
        (s) => s.error,
        'error',
        isA<OfflineFailure>(),
      ),
    );
    expect(world.server.users.containsKey(x), isTrue);
    expect(world.notices, isEmpty);

    world.network.claimsOnline = null;
    world.network.goOnline();
    await pumpEventQueue();

    expectNewAnonymous(not: x);
    expect(world.server.users.containsKey(x), isFalse);
    expect(world.device.resets, 1);
  });
}
