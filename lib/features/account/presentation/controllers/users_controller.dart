import 'dart:async';

import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/presentation/providers/search_users_use_case_provider.dart';
import 'package:memox/features/account/presentation/providers/set_user_role_use_case_provider.dart';
import 'package:memox/features/account/presentation/states/users_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'users_controller.g.dart';

/// How long the search field stays still before it asks (users spec §3).
const Duration usersSearchDebounce = Duration(milliseconds: 400);

/// Screen 33 (users spec §3): the query, the pages read so far, the one in
/// flight, and role changes. A search and a pull to refresh start again
/// from the first page; an answer to an earlier ask than the latest is
/// dropped, so a slow response never overwrites a newer one (as screen 28).
@riverpod
class UsersController extends _$UsersController {
  Timer? _debounce;

  /// Bumped by every ask from the first page.
  var _generation = 0;

  /// The search typed but not yet asked, carried into a retry or refresh.
  String? _pendingSearch;

  @override
  UsersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadFirst);
    return const UsersState();
  }

  String get _intended => _pendingSearch ?? state.query;

  /// The search field changed: asked [usersSearchDebounce] after the last
  /// change.
  void search(String text) {
    _debounce?.cancel();
    _pendingSearch = text;
    _debounce = Timer(usersSearchDebounce, () => _ask(_intended));
  }

  /// After a failure: the first page again, the failure gone at once.
  void retry() => _ask(_intended);

  /// Pull to refresh: the first page again, the rows kept until it lands.
  Future<void> refresh() {
    final query = _intended;
    _debounce?.cancel();
    _pendingSearch = null;
    if (query != state.query) state = UsersState(query: query);
    return _loadFirst();
  }

  /// One more page, keeping the rows until it arrives; after a failure it is
  /// the retry.
  Future<void> loadMore() async {
    final current = _loaded;
    if (current == null) return;
    final after = current.next;
    if (after == null || current.more == UsersMore.loading) return;
    final generation = _generation;
    final query = state.query;
    _show(current.withMore(UsersMore.loading));
    try {
      final page = await ref.read(searchUsersUseCaseProvider)(
        query,
        after: after,
      );
      if (!_isCurrent(generation)) return;
      final latest = _loaded;
      if (latest == null) return;
      _show(
        UsersLoaded(users: [...latest.users, ...page.users], next: page.next),
      );
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      // No longer an admin: the whole screen says so, not one page (final
      // review I1).
      if (error is NotAdminFailure) {
        return _show(const UsersFailed(UsersLoadFailure.notAdmin));
      }
      final latest = _loaded;
      if (latest == null) return;
      _show(latest.withMore(UsersMore.failed));
    }
  }

  /// Screen 33's role sheet (users spec §3): the change, and what the sheet
  /// says about it.
  Future<RoleChange> setRole(ManagedUser user, AccountRole role) async {
    try {
      final held = await ref.read(setUserRoleUseCaseProvider)(user.id, role);
      if (!ref.mounted) return RoleChange.saved;
      if (held == null) {
        unawaited(_loadFirst());
        return RoleChange.gone;
      }
      _replace(user.withRole(held));
      return RoleChange.saved;
    } on NotAdminFailure {
      if (ref.mounted) _show(const UsersFailed(UsersLoadFailure.notAdmin));
      return RoleChange.notAdmin;
    } on LastAdminFailure {
      return RoleChange.lastAdmin;
    } on AnonymousUserFailure {
      return RoleChange.anonymous;
    } on OfflineFailure {
      return RoleChange.offline;
    } on Failure {
      return RoleChange.failed;
    }
  }

  void _ask(String query) {
    _debounce?.cancel();
    _pendingSearch = null;
    state = UsersState(query: query);
    unawaited(_loadFirst());
  }

  UsersLoaded? get _loaded => switch (state.content) {
    final UsersLoaded loaded => loaded,
    _ => null,
  };

  void _replace(ManagedUser changed) {
    final current = _loaded;
    if (current == null) return;
    _show(
      current.withUsers([
        for (final user in current.users)
          user.id == changed.id ? changed : user,
      ]),
    );
  }

  void _show(UsersContent content) =>
      state = UsersState(query: state.query, content: content);

  bool _isCurrent(int generation) => ref.mounted && generation == _generation;

  Future<void> _loadFirst() async {
    if (!ref.mounted) return;
    final generation = ++_generation;
    final query = state.query;
    try {
      final page = await ref.read(searchUsersUseCaseProvider)(query);
      if (!_isCurrent(generation)) return;
      _show(UsersLoaded(users: page.users, next: page.next));
    } on Object catch (error) {
      if (!_isCurrent(generation)) return;
      _show(UsersFailed(UsersLoadFailure.of(error)));
    }
  }
}
