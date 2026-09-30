import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 rows #13, #36–#45 and plan ruling 6.
void main() {
  const xEmail = 'x@example.com';
  const code = FakeAuthGateway.code;
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// The device on account X, with [pending] unsent changes.
  Future<String> readyAccount({
    AccountRole role = AccountRole.user,
    int pending = 2,
  }) async {
    final x = world.server.addUser(email: xEmail, role: role).id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 5
      ..pending = pending;
    return x;
  }

  /// X's session refused: REAUTH_REQUIRED.
  Future<String> reauthRequired({int pending = 2}) async {
    final x = await readyAccount(pending: pending);
    world.gateway.dropSession();
    await pumpEventQueue();
    expect(world.state, isA<ReauthRequired>());
    return x;
  }

  void expectNewAnonymous({required String not}) {
    final user = (world.state as Ready).user;
    expect(user.id, isNot(not));
    expect(user.isAnonymous, isTrue);
    expect(world.gate.isClosed, isFalse);
    expect(world.secrets.values, isEmpty);
  }

  test('#36 signing in again as X keeps the data and syncs', () async {
    final x = await reauthRequired();

    await world.coordinator.requestCode(xEmail);
    await world.coordinator.verifyCode(xEmail, code);

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
    expect(world.sync.paused, isFalse);
  });

  test('ruling 6: another email with unsent changes asks first, before any code is sent', () async {
    await reauthRequired();

    await expectLater(
      world.coordinator.requestCode('y@example.com'),
      throwsA(isA<UnsentChangesFailure>().having((f) => f.count, 'count', 2)),
    );

    expect(world.server.sentCodes, isEmpty);
    expect(world.state, isA<ReauthRequired>());
  });

  test(
    '#37 another account, loss confirmed: X is cleared, Y is pulled',
    () async {
      await reauthRequired();
      final y = world.server.addUser(email: 'y@example.com').id;

      await world.coordinator.requestCode('y@example.com', confirmedLoss: true);
      await world.coordinator.verifyCode('y@example.com', code);

      expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', y));
      expect(world.device.resets, 1);
      expect(world.device.pulls, [y]);
      expect(world.device.pushes, isEmpty);
    },
  );

  test('#37 with nothing unsent no confirmation is needed', () async {
    await reauthRequired(pending: 0);

    await world.coordinator.requestCode('y@example.com');
    await world.coordinator.verifyCode('y@example.com', code);

    expect((world.state as Ready).user.email, 'y@example.com');
  });

  test('a Google account refused for its loss is not kept past continuing '
      'without an account (final review I1)', () async {
    await reauthRequired();
    world.gateway.google = const GoogleCredential(
      idToken: 'other',
      email: 'other@example.com',
    );
    await expectLater(
      world.coordinator.continueWithGoogle(),
      throwsA(isA<UnsentChangesFailure>()),
    );

    await world.coordinator.continueWithoutAccount();
    world.gateway.google = const GoogleCredential(
      idToken: 'fresh',
      email: 'fresh@example.com',
    );
    await world.coordinator.continueWithGoogle();

    expect((world.state as Ready).user.email, 'fresh@example.com');
  });

  test('a Google account refused for its loss can be forgotten, so the '
      'picker shows again (final review I1)', () async {
    await reauthRequired();
    world.gateway.google = const GoogleCredential(
      idToken: 'other',
      email: 'other@example.com',
    );
    await expectLater(
      world.coordinator.continueWithGoogle(),
      throwsA(isA<UnsentChangesFailure>()),
    );

    world.coordinator.forgetPickedGoogle();
    world.gateway.google = const GoogleCredential(
      idToken: 'same',
      email: xEmail,
    );
    await world.coordinator.continueWithGoogle();

    expect((world.state as Ready).user.email, xEmail);
  });

  test(
    '#38 continue without an account clears X and starts a new anonymous user',
    () async {
      final x = await reauthRequired();

      await world.coordinator.continueWithoutAccount();

      expectNewAnonymous(not: x);
      expect(world.device.resets, 1);
      expect((await world.store.lastKnown())!.isAnonymous, isTrue);
    },
  );

  test(
    '#13 an account the server deleted clears the device (no re-auth)',
    () async {
      final x = await readyAccount();
      world.server.users.remove(x);

      world.boot();
      await world.coordinator.start();

      expectNewAnonymous(not: x);
      expect(world.device.resets, 1);
      expect(world.device.pushes, isEmpty);
    },
  );

  test('#39 #40 #41 sign-out sends X first, ships the logs, clears, starts anonymous', () async {
    final x = await readyAccount();

    await world.coordinator.signOut();

    expectNewAnonymous(not: x);
    expect(world.device.pushes.single, (signedIn: x, owner: x));
    expect(world.logFlushes, 1);
    expect(world.device.resets, 1);
    expect(world.server.refreshTokens.values, isNot(contains(x)));
    expect(await world.store.transition(), isNull);
  });

  test(
    '#39 offline, loss not accepted: nothing changes and it waits',
    () async {
      final x = await readyAccount();
      world.network.goOffline();

      await world.coordinator.signOut();

      expect(
        world.state,
        isA<Transitioning>().having(
          (s) => s.error,
          'error',
          isA<OfflineFailure>(),
        ),
      );
      expect(world.gateway.currentUserId, x);
      expect(world.device.resets, 0);
      expect(world.gate.isClosed, isTrue);

      world.network.goOnline();
      await pumpEventQueue();

      expectNewAnonymous(not: x);
      expect(world.device.pushes.single.signedIn, x);
    },
  );

  test('#39 offline with the loss accepted signs out; the new user waits for the network', () async {
    final x = await readyAccount();
    world.network.goOffline();

    await world.coordinator.signOut(discardUnsent: true);

    expect(world.state, isA<LocalOnly>());
    expect(world.gateway.currentUserId, isNull);
    expect(world.device.resets, 1);
    expect(await world.store.lastKnown(), isNull);
    expect(world.gate.isClosed, isFalse);

    world.network.goOnline();
    await pumpEventQueue();

    expectNewAnonymous(not: x);
  });

  test(
    '#42 #43 deletion removes the account, then clears like a sign-out',
    () async {
      final x = await readyAccount();

      await world.coordinator.deleteAccount();

      expectNewAnonymous(not: x);
      expect(world.server.users.containsKey(x), isFalse);
      expect(world.device.resets, 1);
    },
  );

  test('#43 a retried deletion the server already did goes on', () async {
    final x = await readyAccount();
    world.server.users.remove(x);
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

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
  });

  test(
    '#44 the last admin is not deleted; nothing changes; the user is told',
    () async {
      final x = await readyAccount(role: AccountRole.admin);

      await world.coordinator.deleteAccount();

      expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
      expect(world.notices, [
        isA<DeleteRefused>().having(
          (n) => n.failure,
          'failure',
          isA<LastAdminFailure>(),
        ),
      ]);
      expect(world.device.resets, 0);
      expect(world.gate.isClosed, isFalse);
      expect(await world.store.transition(), isNull);
    },
  );

  test('#44 deletion offline is refused before anything changes', () async {
    await readyAccount();
    world.network.goOffline();

    await expectLater(
      world.coordinator.deleteAccount(),
      throwsA(isA<OfflineFailure>()),
    );

    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
  });

  test(
    '#45 a sign-out found signed out at launch finishes the clearing',
    () async {
      final x = await readyAccount();
      world.gateway.forgetSession();
      await world.store.saveTransition(
        AccountTransition(
          opId: 'op-x',
          kind: TransitionKind.signOut,
          sourceUserId: x,
          sourceIsAnonymous: false,
          stage: TransitionStage.signedOut,
          createdAt: t0,
          updatedAt: t0,
        ),
      );

      world.boot();
      await world.coordinator.start();

      expectNewAnonymous(not: x);
      expect(world.device.resets, 1);
      expect(world.device.pushes, isEmpty);
    },
  );

  test('sign-out and deletion need a confirmed account', () async {
    world.network.goOffline();
    world.boot();
    await world.coordinator.start();

    await expectLater(world.coordinator.signOut(), throwsA(isA<StateError>()));
    await expectLater(
      world.coordinator.continueWithoutAccount(),
      throwsA(isA<StateError>()),
    );
  });
}
