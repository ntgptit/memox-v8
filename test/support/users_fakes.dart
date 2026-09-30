import 'dart:async';

import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// A user of screen 33, joined 2026-09-01; its id is the email's name.
ManagedUser managedUser(String email, {AccountRole role = AccountRole.user}) =>
    ManagedUser(
      id: email.split('@').first,
      email: email,
      role: role,
      createdAt: DateTime.utc(2026, 9, 1, 8),
    );

/// `role_list` and `role_set` in memory, driven by the test: pages by email,
/// a list can be held or failed once, and a set can fail once.
final class FakeUserRoleRepository implements UserRoleRepository {
  FakeUserRoleRepository(List<ManagedUser> users) : users = [...users];

  final List<ManagedUser> users;
  var pageSize = 50;

  /// Every list asked, as (query, after).
  final lists = <(String, String?)>[];

  /// The next list waits on it.
  Completer<void>? holdList;

  /// The next list throws it.
  Object? failNextList;

  /// The next set throws it.
  Object? failNextSet;

  @override
  Future<UserPage> list(String query, {String? after}) async {
    lists.add((query, after));
    final hold = holdList;
    if (hold != null) {
      holdList = null;
      await hold.future;
    }
    final failure = failNextList;
    if (failure != null) {
      failNextList = null;
      throw failure;
    }
    final matching =
        users
            .where((user) => user.email.contains(query.toLowerCase()))
            .where((user) => after == null || user.email.compareTo(after) > 0)
            .toList()
          ..sort((a, b) => a.email.compareTo(b.email));
    final page = matching.take(pageSize).toList();
    return UserPage(
      users: page,
      next: matching.length > pageSize ? page.last.email : null,
    );
  }

  @override
  Future<AccountRole?> set(String userId, AccountRole role) async {
    final failure = failNextSet;
    if (failure != null) {
      failNextSet = null;
      throw failure;
    }
    final index = users.indexWhere((user) => user.id == userId);
    if (index < 0) return null;
    users[index] = users[index].withRole(role);
    return role;
  }
}
