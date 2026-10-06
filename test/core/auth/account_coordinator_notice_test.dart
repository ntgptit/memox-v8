import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../../support/auth_fakes.dart';

// DEV-202: a notice is a one-time result for the person (plan rulings 3 and
// 8), so one raised before the layer host listens (start() runs before the
// first frame) waits for the first listener instead of being dropped.
void main() {
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// A deletion killed after its record was saved, retried offline at the
  /// next start: #44 refuses it and says so before any frame.
  Future<void> deletionRefusedAtStart() async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
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
    world.network.goOffline();
    world.boot(subscribeNotices: false);
    await world.coordinator.start();
  }

  test(
    'a notice raised before anyone listens reaches the first listener, once',
    () async {
      await deletionRefusedAtStart();
      expect(world.notices, isEmpty);

      final first = <AccountNotice>[];
      world.coordinator.notices.listen(first.add);
      await pumpEventQueue();

      expect(first, [isA<DeleteRefused>()]);

      final second = <AccountNotice>[];
      world.coordinator.notices.listen(second.add);
      await pumpEventQueue();

      expect(second, isEmpty);
      expect(first, hasLength(1));
    },
  );
}
