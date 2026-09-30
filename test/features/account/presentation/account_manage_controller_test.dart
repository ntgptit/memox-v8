import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';

import '../../../support/account_harness.dart';
import '../../../support/auth_fakes.dart';

void main() {
  late AuthWorld world;
  late ProviderContainer container;

  setUp(() async {
    world = AuthWorld();
    await readyAnonymous(world); // 2 changes pending
    await linkEmail(world);
    container = ProviderContainer(overrides: accountOverrides(world));
    container.listen(accountManageControllerProvider, (_, _) {});
  });
  tearDown(() async {
    container.dispose();
    await world.close();
  });

  AccountManageController controller() =>
      container.read(accountManageControllerProvider.notifier);

  test(
    'online, a sign-out loses nothing; offline, the unsent changes',
    () async {
      expect(await controller().changesLostBySignOut(), 0);

      world.network.goOffline();
      expect(await controller().changesLostBySignOut(), 2);
    },
  );

  test('a deletion needs the network', () async {
    expect(await controller().canDelete(), isTrue);
    world.network.goOffline();
    expect(await controller().canDelete(), isFalse);
  });

  test('a deletion refused offline says so, and nothing changed', () async {
    world.network.goOffline();

    expect(await controller().deleteAccount(), AccountCommandResult.offline);
    expect(world.state, isA<Ready>());
  });

  test(
    'the network gone after the online dialog: the sign-out stops on '
    'the unsent changes and the layer offers the loss (Review Focus 2)',
    () async {
      world.network.goOffline();

      expect(
        await controller().signOut(discardUnsent: false),
        AccountCommandResult.done,
      );
      expect(
        world.state,
        isA<Transitioning>().having((s) => s.error, 'error', isNotNull),
      );
    },
  );

  test(
    'a second command while one runs sends nothing (Review Focus 4)',
    () async {
      // _run sets its flag before its first await, so the switch is still
      // running when the sign-out arrives.
      final first = controller().switchAccount();
      expect(
        await controller().signOut(discardUnsent: false),
        AccountCommandResult.none,
      );
      expect(await first, AccountCommandResult.done);
      expect(world.state, isA<Transitioning>());
    },
  );

  test('a command in the wrong state is a failure, not a crash', () async {
    world.gateway.dropSession();
    await pumpEventQueue();
    expect(world.state, isA<ReauthRequired>());

    expect(await controller().switchAccount(), AccountCommandResult.failed);
  });
}
