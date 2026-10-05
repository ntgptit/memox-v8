import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';

import 'support/local_device.dart';
import 'support/local_env.dart';
import 'support/mailpit.dart';
import 'support/server_probe.dart';

// Device check D1 (auth spec §9.1) on a real stack.
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

  test('D1 linking an email keeps the user id and the decks', () async {
    final a = await LocalDevice.launch(env);
    devices.add(a);
    await a.createDeck('A1');
    await a.createDeck('A2');
    await a.syncNow();
    final id = a.userId!;
    final email = freshEmail();

    await a.signInByEmail(mail, email);

    final user = (a.state as Ready).user;
    expect(user.email, email);
    expect(user.isAnonymous, isFalse);
    expect(a.userId, id);
    expect(await a.deckNames(), {'A1', 'A2'});
    expect(await probe.emailOf(id), email);
    expect(await probe.deckNames(id), {'A1', 'A2'});
  });
}
