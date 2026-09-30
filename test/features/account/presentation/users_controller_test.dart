import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/di/user_role_repository_provider.dart';
import 'package:memox/features/account/presentation/controllers/users_controller.dart';
import 'package:memox/features/account/presentation/states/users_state.dart';

import '../../../support/users_fakes.dart';

void main() {
  late FakeUserRoleRepository roles;
  late ProviderContainer container;

  setUp(() {
    roles = FakeUserRoleRepository([
      managedUser('ann@example.com', role: AccountRole.admin),
      managedUser('bob@example.com'),
      managedUser('cat@example.com'),
    ]);
    container = ProviderContainer(
      overrides: [userRoleRepositoryProvider.overrideWithValue(roles)],
    );
    container.listen(usersControllerProvider, (_, _) {});
  });
  tearDown(() => container.dispose());

  UsersController controller() =>
      container.read(usersControllerProvider.notifier);
  UsersState state() => container.read(usersControllerProvider);
  List<String> emails() => switch (state().content) {
    UsersLoaded(:final users) => [for (final user in users) user.email],
    _ => const [],
  };

  test('the first page loads at once', () async {
    await pumpEventQueue();

    expect(roles.lists, [('', null)]);
    expect(emails(), ['ann@example.com', 'bob@example.com', 'cat@example.com']);
  });

  test('a search waits 400 ms after the last keystroke, then asks once', () {
    fakeAsync((async) {
      // Its own fake: the setUp container already listed into [roles].
      final fresh = FakeUserRoleRepository(roles.users);
      final local = ProviderContainer(
        overrides: [userRoleRepositoryProvider.overrideWithValue(fresh)],
      );
      local.listen(usersControllerProvider, (_, _) {});
      async.flushMicrotasks();
      final users = local.read(usersControllerProvider.notifier);

      users.search('b');
      async.elapse(const Duration(milliseconds: 200));
      users.search('bo');
      async.elapse(const Duration(milliseconds: 399));
      expect(fresh.lists, [('', null)]);
      async.elapse(const Duration(milliseconds: 1));
      async.flushMicrotasks();

      expect(fresh.lists, [('', null), ('bo', null)]);
      expect(local.read(usersControllerProvider).query, 'bo');
      local.dispose();
    });
  });

  test(
    'an older answer never overwrites a newer one (Review Focus 1)',
    () async {
      await pumpEventQueue();
      final held = roles.holdList = Completer<void>();
      controller().retry(); // asks '' and waits
      await pumpEventQueue();
      controller().search('cat');
      await Future<void>.delayed(usersSearchDebounce);
      await pumpEventQueue();
      expect(emails(), ['cat@example.com']);

      held.complete();
      await pumpEventQueue();

      expect(emails(), ['cat@example.com']);
    },
  );

  test(
    'the next page joins the list; a failed page waits for its retry',
    () async {
      roles.pageSize = 2;
      controller().retry();
      await pumpEventQueue();
      expect(emails(), ['ann@example.com', 'bob@example.com']);

      roles.failNextList = const ServerFailure(cause: 'x');
      await controller().loadMore();
      expect((state().content as UsersLoaded).more, UsersMore.failed);

      await controller().loadMore();
      expect(emails(), [
        'ann@example.com',
        'bob@example.com',
        'cat@example.com',
      ]);
      expect((state().content as UsersLoaded).next, isNull);
    },
  );

  test('a saved role changes the row in place', () async {
    await pumpEventQueue();
    final bob = managedUser('bob@example.com');

    expect(
      await controller().setRole(bob, AccountRole.admin),
      RoleChange.saved,
    );

    final loaded = state().content as UsersLoaded;
    expect(loaded.users[1].role, AccountRole.admin);
  });

  test(
    'the server\'s refusals leave the list as it was (Review Focus 4)',
    () async {
      await pumpEventQueue();
      final ann = managedUser('ann@example.com', role: AccountRole.admin);
      for (final (failure, change) in [
        (const LastAdminFailure(), RoleChange.lastAdmin),
        (const AnonymousUserFailure(), RoleChange.anonymous),
        (const OfflineFailure(cause: 'x'), RoleChange.offline),
        (const ServerFailure(cause: 'x'), RoleChange.failed),
      ]) {
        roles.failNextSet = failure;
        expect(await controller().setRole(ann, AccountRole.user), change);
      }

      expect(
        (state().content as UsersLoaded).users.first.role,
        AccountRole.admin,
      );
    },
  );

  test('a user gone is said, and the list reloads', () async {
    await pumpEventQueue();
    final gone = managedUser('zed@example.com');

    expect(
      await controller().setRole(gone, AccountRole.admin),
      RoleChange.gone,
    );
    await pumpEventQueue();

    expect(roles.lists, [('', null), ('', null)]);
  });

  test('no longer an admin: the screen says so, from a save or a list '
      '(Review Focus 5)', () async {
    await pumpEventQueue();
    roles.failNextSet = const NotAdminFailure(cause: 'x');

    expect(
      await controller().setRole(
        managedUser('bob@example.com'),
        AccountRole.admin,
      ),
      RoleChange.notAdmin,
    );
    expect(
      state().content,
      isA<UsersFailed>().having(
        (c) => c.failure,
        'failure',
        UsersLoadFailure.notAdmin,
      ),
    );

    roles.failNextList = const NotAdminFailure(cause: 'x');
    controller().retry();
    await pumpEventQueue();
    expect(
      state().content,
      isA<UsersFailed>().having(
        (c) => c.failure,
        'failure',
        UsersLoadFailure.notAdmin,
      ),
    );
  });
}
