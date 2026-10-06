import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Plan ruling 7, hardened by DEV-189: at start, with no record, the SDK on
// another account than the one whose data the device holds adopts that
// account only when nothing is unsent. With changes unsent, the device asks
// for a sign-in instead (#14), so the loss goes through #37 or #38.
void main() {
  const xEmail = 'x@example.com';
  const uEmail = 'u@example.com';
  const code = FakeAuthGateway.code;
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// The device on account X with [pending] unsent changes; then the SDK is
  /// found on another account U, with no transition saying why.
  Future<(String, String)> sdkOnAnother({required int pending}) async {
    final x = world.server.addUser(email: xEmail).id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 4
      ..pending = pending;
    final u = world.server.addUser(email: uEmail).id;
    world.gateway.adopt(u);
    world.boot();
    await world.coordinator.start();
    return (x, u);
  }

  test('with changes unsent, the start asks for a sign-in and removes nothing '
      '(DEV-189)', () async {
    final (x, _) = await sdkOnAnother(pending: 2);

    expect(
      world.state,
      isA<ReauthRequired>().having((s) => s.last.id, 'last', x),
    );
    expect(world.device.resets, 0);
    expect(world.device.pulls, isEmpty);
    expect(world.device.pushes, isEmpty);
    expect(world.device.pending, 2);
    expect(world.sync.paused, isTrue);
    expect(await world.store.transition(), isNull);
  });

  test('with changes unsent, signing in to the other account goes through #37: '
      'the loss is confirmed first (DEV-189)', () async {
    final (_, u) = await sdkOnAnother(pending: 2);

    await expectLater(
      world.coordinator.requestCode(uEmail),
      throwsA(isA<UnsentChangesFailure>().having((f) => f.count, 'count', 2)),
    );
    expect(world.device.resets, 0);

    await world.coordinator.requestCode(uEmail, confirmedLoss: true);
    await world.coordinator.verifyCode(uEmail, code);

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', u));
    expect(world.device.resets, 1);
    expect(world.device.pulls, [u]);
    expect(world.device.pushes, isEmpty);
  });

  test('with nothing unsent, the SDK account is adopted as before', () async {
    final (_, u) = await sdkOnAnother(pending: 0);

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', u));
    expect(world.device.resets, 1);
    expect(world.device.pulls, [u]);
    expect(world.device.pushes, isEmpty);
  });
}
