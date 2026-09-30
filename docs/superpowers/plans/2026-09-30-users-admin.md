# Users (admin) — screen 33 and the role client (P4) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An admin finds any signed-in account by email on screen 33 and makes it an admin or a user, from a Users row under Settings › Admin.

**Architecture:**
- **`features/account` gains a small admin slice** (users spec U3): `domain/` (`ManagedUser`, `UserPage`, `UserRoleRepository`, two use cases), `data/` (`UserRoleRemoteDataSource` over `role_list`/`role_set`, a mapper, the repository), `di/`, and `presentation/` (`UsersController`, screen 33, its row, list and role sheet).
- **The data source follows Monitoring's** (U4): the shared `RpcCall` on the session sync holds; errors map through core's `classifyAuthError`, which already knows `FORBIDDEN`, `LAST_ADMIN` and `ANONYMOUS_USER`.
- **Settings owns the Admin section** (U2): an `adminRows` slot replaces `adminSection`; Monitoring's entry becomes a row; `app/` composes the two rows and the `/settings/users` route behind the admin gate.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3.4 codegen, go_router 18, intl, supabase_flutter (through core only).

**Spec:** `docs/superpowers/specs/2026-09-30-users-admin-design.md` (U1–U5, §2 data, §3 screen, §4 Settings, §6 shape). Background: auth spec §2 (the RPCs), §5, §11 P4.

## Rulings made while planning

1. **Errors reuse `classifyAuthError`** (core/auth), with a missing session read as `NotAdminFailure` first: one mapping of the account RPCs' codes, not a second. Cost if wrong: a feature mapper.
2. **The admin gate takes a title.** `MonitoringAdminGateWidget` shows "Monitoring" in its app bar; it gains `title` (default Monitoring's) so 33's gate says "Users". Cost if wrong: one parameter.
3. **Dates show with `DateFormat.yMMMd`** of the screen's locale, as a `String` placeholder ("Joined {date}"): the ARB has no `DateTime` placeholder precedent. Times are the server's UTC shown in local time.
4. **The role sheet runs the command itself** (its Save spins, it stays on a refusal, it closes on success, gone or not-admin), through `UsersController.setRole`; the list updates in place from the controller.
5. **`isAdminProvider` gates the Admin section in Settings** (settings may import core), replacing the check inside Monitoring's widget; with no Supabase `isAdmin` is false, as today.
6. **One icon joins `AppIcons`**: `users` (`Icons.group_outlined`, lucide users) for the Settings row.

## Global Constraints

- **UI authority:** `DESIGN.md`, the reviewed goldens (ADR-019) and spec §6: screen 28 is the pattern; one fill per decision (the sheet's Save); a row has a badge or a chevron, never both. Copy only from `context.l10n`.
- **Layers:** presentation never imports `data/`; no feature imports another (`test/architecture/boundary_rules.dart` keeps `'account': {}` and `'monitoring': {}`, `'settings': {}`); file suffixes per `check_architecture.py`.
- **Strings:** every key has a description and a Vietnamese value; `flutter gen-l10n` after changes.
- **Guard:** `no_text_restyle`, `no_ref_read_in_build` (reads in methods), `max_file_lines` 500, `no_large_source_file` 400; `lib/app/router/app_router.dart` is at 478 lines, so the new route goes in `account_routes.dart` and costs app_router one line.
- **Tests:** default text scale; goldens English, light and dark, TZ=UTC in this container; pump 1 s before a capture after a tap; no real clock.
- **Task gate** (the scratchpad `gate.sh`, never piped through `tail`): format, `flutter analyze`, the architecture check, the guard, then the task's tests with `--exclude-tags golden`.
- **Codegen:** `dart run build_runner build --delete-conflicting-outputs` after any `@riverpod` change.
- **Commits** end with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2`.
- `S=/tmp/claude-0/-home-user-memox-v8/145740b4-0fc1-50a5-8b05-262c0c57b91d/scratchpad`.

## Review Focus

1. **A search typed while a page is loading** must not let the older answer overwrite the newer one (generation counter, as 28): Task 3 pins it.
2. **The admin's own row** never opens the sheet, even after a reload changes its position: Task 4 pins it.
3. **Setting the role the user already has** is impossible (Save disabled until the choice differs): Task 4 pins it.
4. **The last admin demoted by another admin's screen at the same time**: `LAST_ADMIN` keeps the sheet and says why; the row keeps its badge: Task 3 and 4 pin it.
5. **An admin demoted elsewhere while on 33**: the next call is `FORBIDDEN`, the screen shows the not-admin state, never a stack trace or a stale list: Task 3 pins it.

---

### Task 1: Domain and data — the role client

**Files:**
- Create: `lib/features/account/domain/models/managed_user_model.dart`, `lib/features/account/domain/models/user_page_model.dart`
- Create: `lib/features/account/domain/repositories/user_role_repository.dart`
- Create: `lib/features/account/domain/usecases/search_users_use_case.dart`, `lib/features/account/domain/usecases/set_user_role_use_case.dart`
- Create: `lib/features/account/data/datasources/user_role_remote_data_source.dart`
- Create: `lib/features/account/data/mappers/user_role_mapper.dart`
- Create: `lib/features/account/data/repositories/user_role_repository_impl.dart`
- Create: `lib/features/account/di/user_role_repository_provider.dart`
- Create: `lib/features/account/presentation/providers/search_users_use_case_provider.dart`, `set_user_role_use_case_provider.dart`
- Test: `test/features/account/data/user_role_repository_impl_test.dart`

**Interfaces:**
- Produces:
  - `ManagedUser({required String id, required String email, required AccountRole role, required DateTime createdAt, DateTime? lastSignInAt})` with `withRole(AccountRole)`, value equality;
  - `UserPage({required List<ManagedUser> users, required String? next})`;
  - `UserRoleRepository`: `Future<UserPage> list(String query, {String? after})`, `Future<AccountRole?> set(String userId, AccountRole role)` (null when the user is gone);
  - `SearchUsersUseCase(repo)(String query, {String? after})` (trims), `SetUserRoleUseCase(repo)(String userId, AccountRole role)` (empty id → `ArgumentError`);
  - `UserRoleRemoteDataSource({required RpcCall rpc, required bool Function() hasSession})` with `list(String query, String? after)` → `Map<String, Object?>` and `set(String userId, String role)` → `String?`; `UserRoleSessionMissing`;
  - `userRoleRepositoryProvider`, `searchUsersUseCaseProvider`, `setUserRoleUseCaseProvider`.

- [ ] **Step 1: Write the failing test** `user_role_repository_impl_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/repositories/user_role_repository_impl.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

void main() {
  late List<(String, Map<String, Object?>)> calls;
  late Object? Function(String, Map<String, Object?>) answer;
  var hasSession = true;

  UserRoleRepositoryImpl repository() => UserRoleRepositoryImpl(
    UserRoleRemoteDataSource(
      rpc: (function, params) async {
        calls.add((function, params));
        return answer(function, params);
      },
      hasSession: () => hasSession,
    ),
  );

  setUp(() {
    calls = [];
    hasSession = true;
  });

  test('a page of users, read from role_list', () async {
    answer = (_, _) => {
      'items': [
        {
          'id': 'u1',
          'email': 'a@example.com',
          'role': 'admin',
          'createdAt': '2026-09-01T08:00:00.000Z',
          'lastSignInAt': null,
        },
      ],
      'next': 'a@example.com',
    };

    final page = await repository().list('a', after: 'x@example.com');

    expect(calls.single, (
      'role_list',
      {'p_query': 'a', 'p_after': 'x@example.com'},
    ));
    expect(page.next, 'a@example.com');
    expect(
      page.users.single,
      ManagedUser(
        id: 'u1',
        email: 'a@example.com',
        role: AccountRole.admin,
        createdAt: DateTime.utc(2026, 9, 1, 8),
      ),
    );
  });

  test('a role set is the role the server now holds; a gone user is null',
      () async {
    answer = (_, params) => {'id': params['p_user'], 'role': 'admin'};
    expect(await repository().set('u1', AccountRole.admin), AccountRole.admin);
    expect(calls.single, ('role_set', {'p_user': 'u1', 'p_role': 'admin'}));

    answer = (_, _) => throw const PostgrestException(message: 'NOT_FOUND');
    expect(await repository().set('u2', AccountRole.user), isNull);
  });

  test('the server\'s refusals become the app\'s failures', () async {
    for (final (code, matcher) in [
      ('FORBIDDEN', isA<NotAdminFailure>()),
      ('LAST_ADMIN', isA<LastAdminFailure>()),
      ('ANONYMOUS_USER', isA<AnonymousUserFailure>()),
    ]) {
      answer = (_, _) => throw PostgrestException(message: code);
      await expectLater(
        repository().set('u1', AccountRole.user),
        throwsA(matcher),
      );
    }
  });

  test('no session is not an admin, and the server is not asked', () async {
    hasSession = false;

    await expectLater(repository().list(''), throwsA(isA<NotAdminFailure>()));
    expect(calls, isEmpty);
  });
}
```

- [ ] **Step 2: Run it to see it fail.** `flutter test test/features/account/data/user_role_repository_impl_test.dart` → compile errors (files missing).

- [ ] **Step 3: Implement.**

`managed_user_model.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';

/// A signed-in account as screen 33 lists it (users spec §2).
final class ManagedUser {
  const ManagedUser({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    this.lastSignInAt,
  });

  final String id;
  final String email;
  final AccountRole role;
  final DateTime createdAt;
  final DateTime? lastSignInAt;

  ManagedUser withRole(AccountRole value) => ManagedUser(
    id: id,
    email: email,
    role: value,
    createdAt: createdAt,
    lastSignInAt: lastSignInAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ManagedUser &&
      other.id == id &&
      other.email == email &&
      other.role == role &&
      other.createdAt == createdAt &&
      other.lastSignInAt == lastSignInAt;

  @override
  int get hashCode => Object.hash(id, email, role, createdAt, lastSignInAt);
}
```

`user_page_model.dart`:

```dart
import 'package:memox/features/account/domain/models/managed_user_model.dart';

/// One page of `role_list`: 50 users by email, and the email to ask after
/// for the next page, null at the last (users spec §2).
final class UserPage {
  const UserPage({required this.users, required this.next});

  final List<ManagedUser> users;
  final String? next;
}
```

`user_role_repository.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';

/// An admin's reads and changes of roles (users spec §2). Throws
/// `NotAdminFailure`, `LastAdminFailure`, `AnonymousUserFailure`,
/// `OfflineFailure` or `ServerFailure`.
abstract interface class UserRoleRepository {
  /// The users whose email contains [query] (everyone when blank), after
  /// the email [after].
  Future<UserPage> list(String query, {String? after});

  /// The role [userId] now holds, or null when the user is gone.
  Future<AccountRole?> set(String userId, AccountRole role);
}
```

`search_users_use_case.dart`:

```dart
import 'package:memox/features/account/domain/models/user_page_model.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// Screen 33's search (users spec §3): the typed text, trimmed.
final class SearchUsersUseCase {
  const SearchUsersUseCase(this._roles);

  final UserRoleRepository _roles;

  Future<UserPage> call(String query, {String? after}) =>
      _roles.list(query.trim(), after: after);
}
```

`set_user_role_use_case.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// Makes a user an admin or a user (auth spec O9); null when the user is
/// gone.
final class SetUserRoleUseCase {
  const SetUserRoleUseCase(this._roles);

  final UserRoleRepository _roles;

  Future<AccountRole?> call(String userId, AccountRole role) {
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
    return _roles.set(userId, role);
  }
}
```

`user_role_remote_data_source.dart`:

```dart
import 'package:memox/core/network/remote_error.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';

/// The admin RPCs of roles (auth spec §2): `role_list` and `role_set`, on
/// the session sync already holds. It never signs in: a caller with no
/// session is not an admin (users spec U4).
final class UserRoleRemoteDataSource {
  UserRoleRemoteDataSource({required this._rpc, required this._hasSession});

  final RpcCall _rpc;
  final bool Function() _hasSession;

  static const _notFound = 'NOT_FOUND';

  /// One page: `{items: [...], next}`.
  Future<Map<String, Object?>> list(String query, String? after) async =>
      (await _call('role_list', {'p_query': query, 'p_after': after}))!
          as Map<String, Object?>;

  /// The role the server now holds, or null when the user is gone.
  Future<String?> set(String userId, String role) async {
    try {
      final json =
          (await _call('role_set', {'p_user': userId, 'p_role': role}))!
              as Map<String, Object?>;
      return json['role']! as String;
    } on Object catch (error) {
      if (rpcErrorCode(error) == _notFound) return null;
      rethrow;
    }
  }

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    if (!_hasSession()) throw const UserRoleSessionMissing();
    return _rpc(function, params);
  }
}

/// A role call with no session behind it: the caller cannot be an admin, so
/// the server is not asked.
final class UserRoleSessionMissing implements Exception {
  const UserRoleSessionMissing();

  @override
  String toString() => 'UserRoleSessionMissing: no session';
}
```

`user_role_mapper.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/domain/models/managed_user_model.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';

/// One user of `role_list`'s JSON.
ManagedUser managedUserOfJson(Map<String, Object?> json) => ManagedUser(
  id: json['id']! as String,
  email: json['email']! as String,
  role: AccountRole.parse(json['role'] as String?),
  createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
  lastSignInAt: switch (json['lastSignInAt']) {
    final String at => DateTime.parse(at).toUtc(),
    _ => null,
  },
);

/// `role_list`'s answer.
UserPage userPageOfJson(Map<String, Object?> json) => UserPage(
  users: [
    for (final item in json['items']! as List)
      managedUserOfJson(item! as Map<String, Object?>),
  ],
  next: json['next'] as String?,
);

/// The [Failure] a role call's error becomes (plan ruling 1): no session is
/// "not an admin"; the codes are core's one mapping.
Failure mapUserRoleError(Object error) => error is UserRoleSessionMissing
    ? NotAdminFailure(cause: error)
    : classifyAuthError(error);
```

`user_role_repository_impl.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/mappers/user_role_mapper.dart';
import 'package:memox/features/account/domain/models/user_page_model.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';

/// Roles through the admin RPCs (users spec §2).
final class UserRoleRepositoryImpl implements UserRoleRepository {
  UserRoleRepositoryImpl(this._remote);

  final UserRoleRemoteDataSource _remote;

  @override
  Future<UserPage> list(String query, {String? after}) =>
      _guard(() async => userPageOfJson(await _remote.list(query, after)));

  @override
  Future<AccountRole?> set(String userId, AccountRole role) => _guard(() async {
    final held = await _remote.set(userId, role.name);
    return held == null ? null : AccountRole.parse(held);
  });

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapUserRoleError(error), stackTrace);
    }
  }
}
```

`user_role_repository_provider.dart` (di):

```dart
import 'package:memox/core/network/supabase_client.dart';
import 'package:memox/features/account/data/datasources/user_role_remote_data_source.dart';
import 'package:memox/features/account/data/repositories/user_role_repository_impl.dart';
import 'package:memox/features/account/domain/repositories/user_role_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_role_repository_provider.g.dart';

/// The role RPCs through the Supabase project main.dart initialized; read
/// only from screen 33, which only an admin reaches.
@riverpod
UserRoleRepository userRoleRepository(Ref ref) => UserRoleRepositoryImpl(
  UserRoleRemoteDataSource(rpc: supabaseRpc, hasSession: hasSupabaseSession),
);
```

The two use-case providers, in the form of `set_log_status_use_case_provider.dart`:

```dart
@riverpod
SearchUsersUseCase searchUsersUseCase(Ref ref) =>
    SearchUsersUseCase(ref.watch(userRoleRepositoryProvider));
```

```dart
@riverpod
SetUserRoleUseCase setUserRoleUseCase(Ref ref) =>
    SetUserRoleUseCase(ref.watch(userRoleRepositoryProvider));
```

Run build_runner. If the architecture check refuses `data/` importing `core/auth/supabase_auth_errors.dart` (a file that imports `supabase_flutter`), record a ruling and copy the three codes into `mapUserRoleError` with `classifyRemoteError` for the network case instead.

- [ ] **Step 4: Run the test** → 4 pass. **Step 5: gate, commit** `feat(account): the role client for screen 33 (P4 U3, U4)`.

---

### Task 2: Strings, icon, route

**Files:** `lib/l10n/app_en.arb`, `app_vi.arb`, `lib/core/theme/foundations/app_icons.dart`, `lib/app/router/app_routes.dart`; test `test/app/account_redirect_test.dart` (the path).

**Produces:** the keys below; `AppIcons.users`; `AppRoutes.settingsUsersChild` (`users`) and `AppRoutes.settingsUsers` (`/settings/users`).

- [ ] **Step 1: Add the strings** with a `$S/add_users_strings.py` in the form of P3b's (assert new keys, descriptions, vi), then `flutter gen-l10n`:

| Key | English | Vietnamese | Description |
|---|---|---|---|
| `usersTitle` | Users | Người dùng | Screen 33's title and 23's Admin row (users spec §3, §4). |
| `usersRowHint` | Who can manage the app | Ai được quản lý app | Screen 23: under the Users row. |
| `usersSearchHint` | Search by email | Tìm theo email | Screen 33: the search field. |
| `usersSearchClear` | Clear search | Xoá tìm kiếm | Screen 33: the search field's clear button. |
| `usersSection` | Accounts | Tài khoản | Screen 33: the overline over the list (§6). |
| `usersJoined` | Joined {date} | Tham gia {date} | Screen 33: a row's subtitle; `date` is a medium date. placeholder date String |
| `usersJoinedYou` | Joined {date} · You | Tham gia {date} · Bạn | Screen 33: the signed-in admin's own row (U1). placeholder date String |
| `usersRoleAdmin` | Admin | Admin | Screen 33: the badge and the sheet's option. |
| `usersRoleUser` | User | Người dùng | Screen 33: the badge and the sheet's option. |
| `usersRoleAdminHint` | Sees logs and manages roles | Xem log và quản lý vai trò | Role sheet: under Admin. |
| `usersRoleUserHint` | Studies and syncs their own decks | Học và đồng bộ bộ thẻ của mình | Role sheet: under User. |
| `usersSave` | Save | Lưu | Role sheet: confirm. |
| `usersNoMore` | No more users | Hết người dùng | Screen 33: the end of the list. |
| `usersLoadMoreFailed` | Couldn't load more users. | Không tải thêm được. | Screen 33: a failed next page. |
| `usersNoMatch` | No users match “{query}” | Không ai khớp “{query}” | Screen 33: empty search. placeholder query String |
| `usersNone` | No accounts yet | Chưa có tài khoản nào | Screen 33: empty with no query. |
| `usersErrorTitle` | Couldn't load users | Không tải được danh sách | Screen 33: a failed first page. |
| `usersOfflineTitle` | No connection | Không có mạng | Screen 33: offline. |
| `usersOfflineBody` | Users load when you're online. | Danh sách sẽ tải khi có mạng. | Screen 33: offline body. |
| `usersNowAdmin` | {email} is now an admin | {email} giờ là admin | Toast after a save. placeholder email String |
| `usersNowUser` | {email} is now a user | {email} giờ là người dùng | Toast after a save. placeholder email String |
| `usersLastAdmin` | An admin must remain. Make someone else an admin first. | Phải còn một admin. Hãy cấp quyền admin cho người khác trước. | Toast: LAST_ADMIN. |
| `usersAnonymous` | This account isn't signed in with an email or Google. | Tài khoản này chưa đăng nhập bằng email hay Google. | Toast: ANONYMOUS_USER. |
| `usersGone` | That account no longer exists. | Tài khoản đó không còn. | Toast: NOT_FOUND. |
| `usersOffline` | No connection. Nothing changed. | Không có mạng. Chưa có gì thay đổi. | Toast: offline save. |
| `usersSaveFailed` | Couldn't change the role. Nothing changed. | Không đổi được vai trò. Chưa có gì thay đổi. | Toast: any other failed save. |

- [ ] **Step 2:** `AppIcons.users = Icons.group_outlined; // users` next to `account`; `AppRoutes.settingsUsersChild = 'users'` and `settingsUsers = '$settings/$settingsUsersChild'` after `settingsAccount`; the redirect test's path check gains `expect(AppRoutes.settingsUsers, '/settings/users');` — watch it fail first, then pass.
- [ ] **Step 3:** gate, commit `feat(account): P4 strings, icon and route`.

---

### Task 3: `UsersController`

**Files:** Create `lib/features/account/presentation/states/users_state.dart`, `lib/features/account/presentation/controllers/users_controller.dart`; test `test/features/account/presentation/users_controller_test.dart`; support `test/support/users_fakes.dart`.

**Interfaces:**
- Produces:
  - `enum UsersMore { idle, loading, failed }`; `enum UsersLoadFailure { notAdmin, offline, other; static of(Object) }`;
  - `sealed class UsersContent` with `UsersLoading`, `UsersLoaded({users, next, more})` (`withMore`, `withUsers`), `UsersFailed(failure)`;
  - `UsersState({String query = '', UsersContent content = const UsersLoading()})`;
  - `enum RoleChange { saved, lastAdmin, anonymous, gone, notAdmin, offline, failed }`;
  - `usersControllerProvider` with `search(String)` (400 ms, `usersSearchDebounce`), `retry()`, `refresh()`, `loadMore()`, `Future<RoleChange> setRole(ManagedUser user, AccountRole role)`;
  - `FakeUserRoleRepository` (test support): `users` list, `pageSize`, `holdList` (Completer), `failNextList`/`failNextSet` (Object), `lists` (recorded calls), filters by query, pages by email.

- [ ] **Step 1: Write the failing tests** (`ProviderContainer` with `userRoleRepositoryProvider.overrideWithValue(fake)`, `fake_async` for the debounce):
  - the first page loads at build;
  - a search waits 400 ms, then asks with the text; two quick keystrokes ask once;
  - **Review Focus 1:** hold the first answer, search again, release the first after the second: the state shows the second's users;
  - `loadMore` appends the next page; a failed page is `UsersMore.failed`, and `loadMore` again retries it;
  - `setRole` saved: returns `saved`, the user's role changes in place;
  - `setRole` with `LastAdminFailure` → `lastAdmin`, the list unchanged (**Review Focus 4**); `AnonymousUserFailure` → `anonymous`; `OfflineFailure` → `offline`; other → `failed`;
  - `setRole` gone (null) → `gone`, and the first page reloads;
  - **Review Focus 5:** `setRole` with `NotAdminFailure` → `notAdmin`, and the content is `UsersFailed(UsersLoadFailure.notAdmin)`; a list that fails `NotAdminFailure` is the same state.

  Write each as its own `test(...)` with exact expectations on `container.read(usersControllerProvider)`.

- [ ] **Step 2:** run → compile errors.
- [ ] **Step 3: Implement** in the form of `MonitoringListController` (generation counter, pending search carried into retry/refresh, `ref.mounted` checks), minus filters:

```dart
const Duration usersSearchDebounce = Duration(milliseconds: 400);

@riverpod
class UsersController extends _$UsersController {
  Timer? _debounce;
  var _generation = 0;
  String? _pendingSearch;

  @override
  UsersState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(_loadFirst);
    return const UsersState();
  }

  String get _intended => _pendingSearch ?? state.query;

  void search(String text) {
    _debounce?.cancel();
    _pendingSearch = text;
    _debounce = Timer(usersSearchDebounce, () => _ask(_intended));
  }

  void retry() => _ask(_intended);

  Future<void> refresh() {
    final query = _intended;
    _debounce?.cancel();
    _pendingSearch = null;
    if (query != state.query) state = UsersState(query: query);
    return _loadFirst();
  }

  Future<void> loadMore() async { /* as MonitoringListController.loadMore,
     with searchUsersUseCaseProvider(query, after: next) */ }

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

  // _replace, _show, _isCurrent, _loadFirst as MonitoringListController.
}
```

Write `loadMore`, `_replace` (maps the loaded users, swapping the one with the same id), `_show` and `_loadFirst` in full, copying the Monitoring controller's bodies with the names above. Run build_runner.

- [ ] **Step 4:** run → all pass. **Step 5:** gate, commit `feat(account): screen 33's controller (P4)`.

---

### Task 4: Screen 33, its row and the role sheet

**Files:** Create `lib/features/account/presentation/screens/users_screen.dart`, `lib/features/account/presentation/widgets/items/user_row_widget.dart`, `lib/features/account/presentation/widgets/sections/users_list_widget.dart`, `lib/features/account/presentation/widgets/overlays/user_role_sheet_widget.dart`; test `test/features/account/presentation/users_screen_test.dart`, visual audit `test/visual_audit/screens/features/account/screens/users_screen_visual_audit_test.dart`.

**Interfaces:** `UsersScreen()`; `UserRowWidget({required ManagedUser user, required bool isSelf, required VoidCallback onTap, bool hasDivider = true})`; `Future<void> showUserRoleSheet(BuildContext context, ManagedUser user)`.

- [ ] **Step 1: Write the failing widget tests** (overrides: `userRoleRepositoryProvider` with the fake, `currentAccountProvider.overrideWithValue(AccountUser(id: 'me', email: 'me@example.com', isAnonymous: false, role: AccountRole.admin))`):
  - loaded: the overline "ACCOUNTS", each email, "Joined Sep 1, 2026", the badges "Admin"/"User", no chevron;
  - **Review Focus 2:** the row of `me` reads "Joined … · You" and a tap opens nothing;
  - a tap on another row opens the sheet with the email as title and the current role selected; **Review Focus 3:** Save is disabled until the other option is chosen;
  - Save → the sheet closes, the badge changes, toast `usersNowAdmin(email)`;
  - `LastAdminFailure` → the sheet stays, toast `usersLastAdmin`;
  - gone → the sheet closes, toast `usersGone`;
  - empty with a query → `usersNoMatch(query)`; empty without → `usersNone`;
  - offline first page → `usersOfflineTitle` + Retry; not admin → `monitoringNotAdminTitle`-style empty state with `failureNotAdmin`'s title key `monitoringNotAdminTitle` (reuse);
  - end of the list → `usersNoMore`.
- [ ] **Step 2:** run → compile errors.
- [ ] **Step 3: Implement**, following `MonitoringServerTabWidget` + `MonitoringServerListWidget`:
  - `UsersScreen` (ConsumerStatefulWidget owning the search `TextEditingController`): `MxAppShell` with `MxAppBar(title: usersTitle, density: content, leading: back)`; body: a `Column` of the padded `MxSearchField` (hint `usersSearchHint`, clear `usersSearchClear`, `onChanged: controller.search`) and `Expanded(UsersListWidget(...))`; on a not-admin failure the search is hidden, as 28.
  - `UsersListWidget`: the four contents; loaded = `NotificationListener` prefetch at 10 rows × `AppSize.listRowMin` from the end, `RefreshIndicator` wrapper (copy 28's `_Refreshable` into this file as a private widget), `MxListSectionHeader(label: usersSection)`, the rows, then `_End` (spinner / danger banner with Retry / `usersNoMore` in `footerCaption`).
  - `UserRowWidget`: `MxListRow(leading: MxIconTile(icon: AppIcons.account, tone: MxIconTileTone.tinted), title: email, subtitle: joined, trailing: MxBadge(label, tone: admin ? primary : neutral), onTap: isSelf ? null : onTap, hasDivider: …)`; the date is `DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(user.createdAt.toLocal())` (plan ruling 3).
  - `UserRoleSheetWidget` (ConsumerStatefulWidget): `MxBottomSheet` in the merge sheet's form — header text in `compactTitle`, two `MxOptionRow`s (`usersRoleUser` + hint, `usersRoleAdmin` + hint; the second `hasDivider: false`), `MxSheetActions(isInSheet: true, cancelLabel: commonCancel, confirmLabel: usersSave, isConfirmLoading: _isSaving, onConfirm: _choice != widget.user.role && !_isSaving ? _save : null)`; `PopScope(canPop: !_isSaving)`. `_save` calls `ref.read(usersControllerProvider.notifier).setRole(...)` and acts per spec §3's table (plan ruling 4): pop on `saved`/`gone`/`notAdmin`, toast per outcome with `showMxSnackbar`.
  - The visual-audit companion in the form of P3b's `account_screen_visual_audit_test.dart`, with the fake repository overridden.
- [ ] **Step 4:** run the tests and the audit → pass. **Step 5:** gate, commit `feat(account): screen 33 Users with the role sheet (P4)`.

---

### Task 5: Settings' Admin section with two rows

**Files:** Modify `lib/features/settings/presentation/screens/settings_screen.dart` (`adminSection` → `adminRows`); rename `lib/features/monitoring/presentation/widgets/sections/monitoring_entry_section_widget.dart` to `lib/features/monitoring/presentation/widgets/items/monitoring_entry_row_widget.dart` (`MonitoringEntryRowWidget`, the row only); create `lib/features/account/presentation/widgets/items/users_entry_row_widget.dart`; modify `MonitoringAdminGateWidget` (`title`, plan ruling 2); tests `test/features/monitoring/presentation/monitoring_entry_section_test.dart` (moves to the new API).

**Interfaces:** `SettingsScreen(..., List<Widget> adminRows = const [])`; `MonitoringEntryRowWidget({required VoidCallback onOpen})`; `UsersEntryRowWidget({required VoidCallback onOpen})`; `MonitoringAdminGateWidget({required Widget child, String? title})`.

- [ ] **Step 1: Tests first.** The entry test's `_screen` passes `adminRows: [MonitoringEntryRowWidget(onOpen: …), UsersEntryRowWidget(onOpen: …)]`; the existing four tests keep their expectations; add: "an admin sees Monitoring then Users, and Users opens its screen" (both labels, order by `tester.getTopLeft`, tap count); the settings' no-admin and no-Supabase tests also expect `usersTitle` absent. Run → compile errors.
- [ ] **Step 2: Implement.**
  - `SettingsScreen`: replace `?adminSection,` with
    ```dart
    if (adminRows.isNotEmpty && ref.watch(isAdminProvider))
      MxSection(title: l10n.settingsAdmin, children: adminRows),
    ```
    (`SettingsScreen` is a `ConsumerWidget` already; import `core/auth/di/auth_providers.dart`), and document `adminRows` ("Rows features supply for the Admin section, which shows only to an admin (users spec U2).").
  - `MonitoringEntryRowWidget`: the `MxSettingsRow` alone (no `isAdmin` check, no section).
  - `UsersEntryRowWidget`: `MxSettingsRow(label: usersTitle, subtitle: usersRowHint, icon: AppIcons.users, onTap: onOpen)`.
  - The gate's app bar title is `title ?? l10n.monitoringTitle`.
- [ ] **Step 3:** run → pass. **Step 4:** gate, commit `feat(settings): the Admin section owns its rows; Users joins Monitoring (P4 U2)`.

---

### Task 6: `app/` wiring

**Files:** `lib/app/router/account_routes.dart` (`usersRoute(rootNavigator)`), `lib/app/router/app_router.dart` (one route line; `adminRows:` in place of `adminSection:`), test `test/app/account_routes_test.dart`.

- [ ] **Step 1: Test first:** "an admin opens Users from Settings and Back returns" — `pumpMemoxApp` with `isAdminProvider.overrideWithValue(true)` and the fake repository, go to Settings, scroll to "Users", tap, expect `UsersScreen`, `pageBack`, expect `SettingsScreen`; and "a non-admin's deep link to /settings/users shows the gate" (expect `monitoringNotAdminTitle` and the app bar "Users"). Run → fail.
- [ ] **Step 2: Implement**:

```dart
/// Screen 33 (users spec U5) under Settings, behind the admin gate.
GoRoute usersRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsUsersChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => MonitoringAdminGateWidget(
    title: context.l10n.usersTitle,
    child: const UsersScreen(),
  ),
);
```

In `app_router.dart`: `usersRoute(rootNavigator),` after `accountRoute(rootNavigator),`, and
```dart
adminRows: [
  MonitoringEntryRowWidget(onOpen: () => context.push(AppRoutes.settingsMonitoring)),
  UsersEntryRowWidget(onOpen: () => context.push(AppRoutes.settingsUsers)),
],
```
(check `app_router.dart` stays ≤ 500 lines).
- [ ] **Step 3:** run `test/app` → pass. **Step 4:** gate, commit `feat(app): screen 33 route and the Admin rows (P4 U5)`.

---

### Task 7: Goldens

**Files:** `test/features/account/presentation/users_golden_test.dart`, `test/features/account/presentation/goldens/*.png`.

- [ ] **Step 1:** parity: `TZ=UTC flutter test --tags golden test/features/settings test/features/monitoring test/features/account` passes untouched, except `settings_*` goldens that show the Admin section (none today: the section needs an admin) — expect no change.
- [ ] **Step 2:** write the golden test (light and dark) in `account_manage_golden_test.dart`'s form: `users_loaded` (5 users, one admin, "me" among them), `users_empty_search` (query "zz"), `users_offline`, `users_role_sheet` (tap a user row), `users_role_sheet_changed` (tap the other option: Save enabled), `settings_admin_rows` (SettingsScreen with both rows, `isAdminProvider` true, scrolled to the section).
- [ ] **Step 3:** render with `--update-goldens`, look at every PNG (Read): one fill (the sheet's Save), badges' tones, the "You" row not dimmed, nothing clipped. Fix in one batch if needed.
- [ ] **Step 4:** all goldens pass. **Step 5:** commit `test(account): P4 goldens — screen 33, the role sheet, the Admin section`.

---

### Task 8: Docs

- [ ] `docs/shared/ui/screen-handoff/33-users.md` in `32-account.md`'s shape (entry points, layout, the sheet's outcome table, states with Task 7's goldens, rulings U1–U5 and plan rulings 1–6, copy).
- [ ] The screen index gets row 33 (Users, FE-B11, built); `23-settings.md`'s Admin row (two rows, `adminRows`) and its golden; `docs/wbs_FE.md` gains **FE-B11** "UI quản lý vai trò (P4 của auth): màn 33 Users" done, with the spec and plan links.
- [ ] The spec's status line: "implemented by `docs/superpowers/plans/2026-09-30-users-admin.md`". `DESIGN.md` unchanged (no shared change). Commit `docs(account): screen 33 Users in the handoff files, index and WBS (FE-B11)`.

### Task 9: The whole suite

- [ ] Gate; `flutter test --exclude-tags golden` and `TZ=UTC flutter test --tags golden` in the background; both green.
