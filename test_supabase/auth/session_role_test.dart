import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/network/remote_error.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';

import 'support/flows.dart';
import 'support/local_device.dart';
import 'support/local_env.dart';
import 'support/mailpit.dart';
import 'support/server_probe.dart';

// Device checks D8 and D10 (auth spec §9.1) on a real stack.
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

  UserRoleRemoteDataSource rolesOn(LocalDevice device) =>
      UserRoleRemoteDataSource(
        rpc: (function, params) =>
            device.client.rpc<Object?>(function, params: params),
        hasSession: () => device.client.auth.currentSession != null,
      );

  test(
    'D8 a revoked session asks to sign in again and loses nothing',
    () async {
      final a = await linked({'A1'});
      await a.device.createDeck('A2');

      await probe.signOutEverywhere(
        a.device.client.auth.currentSession!.accessToken,
      );
      // The refresh the app makes when the access token runs out.
      try {
        await a.device.client.auth.refreshSession();
      } on Object {
        // GoTrue refuses the revoked refresh token; the state shows it.
      }
      await a.device.waitFor<ReauthRequired>();
      expect(await a.device.deckNames(), {'A1', 'A2'});

      await a.device.signInByEmail(mail, a.email);
      await a.device.waitFor<Ready>(where: (s) => s.user.email == a.email);
      await a.device.syncNow();
      expect(await probe.deckNames(a.id), {'A1', 'A2'});
    },
  );

  test('D10 an admin changes roles and cannot demote the last admin', () async {
    final a = await linked(const {});
    final b = await linked(const {});
    await probe.onlyAdmin(a.id);
    final roles = rolesOn(a.device);

    Future<String?> roleOf(String email) async {
      final page = await roles.list(email, null);
      final items = (page['items']! as List<Object?>)
          .cast<Map<String, Object?>>();
      return items.firstWhere((i) => i['email'] == email)['role'] as String?;
    }

    expect(await roleOf(a.email), 'admin');
    expect(await roleOf(b.email), 'user');

    expect(await roles.set(b.id, 'admin'), 'admin');
    expect(await roleOf(b.email), 'admin');
    expect(await roles.set(b.id, 'user'), 'user');
    expect(await roleOf(b.email), 'user');

    await expectLater(
      roles.set(a.id, 'user'),
      throwsA(predicate((Object e) => rpcErrorCode(e) == 'LAST_ADMIN')),
    );
  });
}
