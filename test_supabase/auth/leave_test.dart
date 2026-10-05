import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_store.dart';

import 'support/flows.dart';
import 'support/local_device.dart';
import 'support/local_env.dart';
import 'support/mailpit.dart';
import 'support/server_probe.dart';

// Device checks D6, D7, D11, D12 (auth spec §9.1) on a real stack.
void main() {
  late LocalEnv env;
  late Mailpit mail;
  late ServerProbe probe;
  final devices = <LocalDevice>[];

  setUp(() {
    env = LocalEnv.read();
    mail = Mailpit(env.mailpitUrl);
    probe = ServerProbe(env);
  });

  tearDown(() async {
    for (final device in devices) {
      await device.close();
    }
    devices.clear();
    probe.close();
  });

  /// A device on an account of its own that holds [names], synced.
  Future<({LocalDevice device, String email, String id})> linked(
    Set<String> names,
  ) async {
    final device = await anonymousWithDecks(env, names);
    devices.add(device);
    final email = freshEmail();
    await device.signInByEmail(mail, email);
    await device.syncNow();
    return (device: device, email: email, id: device.userId!);
  }

  test('D6 signing out online sends first, then leaves a new anonymous '
      'user', () async {
    final a = await linked({'A1'});
    await a.device.createDeck('A2');

    await a.device.coordinator.signOut();

    expect(await probe.deckNames(a.id), {'A1', 'A2'});
    final anon = await a.device.waitFor<Ready>(
      where: (s) => s.user.isAnonymous,
    );
    expect(anon.user.id, isNot(a.id));
    expect(await a.device.deckNames(), isEmpty);

    await moveTo(a.device, mail, a.email, TransitionChoice.discard);
    expect(await a.device.deckNames(), {'A1', 'A2'});
  });

  test('D7 signing out offline stops before anything is removed, and '
      'cancelling keeps everything', () async {
    final a = await linked({'A1'});
    a.device.network.setOnline(false);
    await a.device.createDeck('A2');

    // The coordinator stops on the push it cannot make; the dialog that
    // names the loss reads the unsent count (account UI spec, B2).
    await a.device.coordinator.signOut();

    final stopped = a.device.state;
    expect(stopped, isA<Transitioning>());
    expect((stopped as Transitioning).error, isA<OfflineFailure>());
    expect(await SyncStore(a.device.db).pendingCount(), 1);
    expect(a.device.userId, a.id);
    expect(await a.device.deckNames(), {'A1', 'A2'});
    expect(await probe.userExists(a.id), isTrue);
    expect(await probe.deckNames(a.id), {'A1'}, reason: 'A2 was never sent');

    await a.device.coordinator.cancelSignOut();
    a.device.network.setOnline(true);
    final back = await a.device.waitFor<Ready>();
    expect(back.user.email, a.email);
    expect(await a.device.deckNames(), {'A1', 'A2'});
  });

  test('D11 deleting the account removes it and its rows', () async {
    final a = await linked({'A1'});

    await a.device.coordinator.deleteAccount();

    expect(await probe.userExists(a.id), isFalse);
    expect(await probe.deckNames(a.id), isEmpty);
    final anon = await a.device.waitFor<Ready>(
      where: (s) => s.user.isAnonymous,
    );
    expect(anon.user.id, isNot(a.id));
    expect(await a.device.deckNames(), isEmpty);
  });

  test('D12 asking for a code offline changes nothing; online it '
      'completes', () async {
    final a = await LocalDevice.launch(env);
    devices.add(a);
    final anon = a.userId;
    final email = freshEmail();

    a.network.setOnline(false);
    await expectLater(
      a.coordinator.requestCode(email),
      throwsA(isA<OfflineFailure>()),
    );
    expect(a.userId, anon);
    expect(a.state, isA<Ready>());
    expect(await probe.emailOf(anon!), anyOf(isNull, isEmpty));

    a.network.setOnline(true);
    await a.signInByEmail(mail, email);
    expect((a.state as Ready).user.email, email);
    expect(a.userId, anon);
  });
}
