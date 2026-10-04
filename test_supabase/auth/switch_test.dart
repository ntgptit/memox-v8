import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../../test/support/auth_fakes.dart' show Killed;
import 'support/flows.dart';
import 'support/local_device.dart';
import 'support/local_env.dart';
import 'support/mailpit.dart';
import 'support/server_probe.dart';

/// Stops the app right after the merge committed and its stage was saved,
/// before the ack (device check D5).
class _StopAfterMerged extends AccountStore {
  _StopAfterMerged(super.db);

  @override
  Future<AccountTransition> saveTransition(AccountTransition t) async {
    final saved = await super.saveTransition(t);
    if (t.stage == TransitionStage.merged) throw const Killed();
    return saved;
  }
}

// Device checks D3, D4, D5 (auth spec §9.1) on a real stack.
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

  test("D3 merge: B's decks join the account and B's anonymous user is "
      'gone', () async {
    final account = await accountWithDecks(env, mail, {'A1'});
    final b = await anonymousWithDecks(env, {'B1', 'B2'});
    devices.add(b);
    final anon = b.userId!;

    await moveTo(b, mail, account.email, TransitionChoice.merge);

    expect(b.userId, account.id);
    expect(await b.deckNames(), {'A1', 'B1', 'B2'});
    expect(await probe.deckNames(account.id), {'A1', 'B1', 'B2'});
    expect(await probe.userExists(anon), isFalse);
  });

  test("D4 discard: B shows only the account's decks", () async {
    final account = await accountWithDecks(env, mail, {'A1'});
    final b = await anonymousWithDecks(env, {'B1', 'B2'});
    devices.add(b);
    final anon = b.userId!;

    await moveTo(b, mail, account.email, TransitionChoice.discard);

    expect(await b.deckNames(), {'A1'});
    expect(await probe.deckNames(account.id), {'A1'});
    expect(await probe.deckNames(anon), isNot(contains('A1')));
  });

  test('D5 a merge stopped after its commit resumes once', () async {
    final account = await accountWithDecks(env, mail, {'A1'});
    final b = await anonymousWithDecks(env, {
      'B1',
      'B2',
    }, store: _StopAfterMerged.new);
    devices.add(b);

    await expectLater(
      moveTo(b, mail, account.email, TransitionChoice.merge),
      throwsA(isA<Killed>()),
    );
    await b.reboot();
    await b.waitFor<Ready>(where: (s) => s.user.email == account.email);
    await b.syncNow();

    expect(await b.deckNames(), {'A1', 'B1', 'B2'});
    final names = await probe.deckNameList(account.id);
    expect(names.toSet(), {'A1', 'B1', 'B2'});
    expect(names, hasLength(3), reason: 'no deck duplicated');
  });
}
