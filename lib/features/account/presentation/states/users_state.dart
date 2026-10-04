import 'package:flutter/foundation.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';

/// Where the next page stands (users spec §3).
enum UsersMore { idle, loading, failed }

/// Why screen 33's read failed, as it tells them apart.
enum UsersLoadFailure {
  notAdmin,
  offline,
  other;

  /// The kind of [error], a `Failure` from the repository.
  static UsersLoadFailure of(Object error) => switch (error) {
    NotAdminFailure() => notAdmin,
    OfflineFailure() => offline,
    _ => other,
  };
}

/// What the list shows.
sealed class UsersContent {
  const UsersContent();
}

/// The first page is on its way.
final class UsersLoading extends UsersContent {
  const UsersLoading();
}

/// The pages read so far; [next] is null at the last page.
final class UsersLoaded extends UsersContent {
  const UsersLoaded({
    required this.users,
    required this.next,
    this.more = UsersMore.idle,
  });

  final List<ManagedUser> users;
  final String? next;
  final UsersMore more;

  UsersLoaded withMore(UsersMore value) =>
      UsersLoaded(users: users, next: next, more: value);

  UsersLoaded withUsers(List<ManagedUser> value) =>
      UsersLoaded(users: value, next: next, more: more);
}

/// The first page failed; no stale row is shown.
final class UsersFailed extends UsersContent {
  const UsersFailed(this.failure);

  final UsersLoadFailure failure;
}

/// Screen 33: the query asked and what it returned.
@immutable
final class UsersState {
  const UsersState({this.query = '', this.content = const UsersLoading()});

  final String query;
  final UsersContent content;
}

/// What a role change came to, for the sheet to say (users spec §3).
enum RoleChange { saved, lastAdmin, anonymous, gone, notAdmin, offline, failed }
