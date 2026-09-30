# Account UI, account management (P3b) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A person with an account manages it in the app: screen 32 shows the account and switches, signs out or deletes it; an expired sign-in is announced on 23, 13 and 32 and fixed through screen 30 in its `reauth` mode, which also offers to lose unsent changes knowingly or to continue without an account.

**Architecture:**
- **Core, two small additions (owner, B1, B2).** `AuthGateway.signInMethods` reads the SDK session's identities, the coordinator exposes it, and `signInMethodsProvider` serves it. `networkStatusProvider` makes the one `NetworkStatus` shared by the coordinator and the UI.
- **Account feature, presentation only.** Screen 32, a confirm dialog shared by every account step, a controller for 32's commands, the re-auth banner (23, 32) and notice (13), and screen 30/31's `reauth` purpose. Commands go straight to P2's coordinator; nothing new in `domain/` or `data/`.
- **`app/` wiring.** A `/settings/account` route, sign-in routes that carry their mode and where the flow began, a redirect that reads the account state, Study home's `reauthNotice` slot and the host's last-admin dialog.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3.4 (codegen, `.g.dart` gitignored, `dart run build_runner build --delete-conflicting-outputs`), go_router 18, Drift 2.35, supabase_flutter (gotrue 2.27).

**Spec:**
- Binding: `docs/superpowers/specs/2026-09-30-account-ui-design.md`: §5.2 (the `reauth` lines), §5.4 (notices), §5.5–§5.7, §7 row P3b, **§9 (B1–B11) and §9.1 (shape, B12)**.
- Background: `docs/superpowers/specs/2026-09-30-auth-design.md` §3.3 #13–#14, #34–#45 (what P2's commands do) and P3a's plan `docs/superpowers/plans/2026-09-30-account-ui-attach.md` (its rulings 2, 5 and 8 are revisited here).

## Rulings made while planning

1. **The re-auth banner sits above the Account section, not inside it** (§9.1 says "inside the section, above its card"). `MxSection` has no slot between its overline and its card, and adding one is a shared change nobody asked for. On 23 the section is first, so the banner is the page's first line either way; on 32 it is too. Cost if wrong: a header slot on `MxSection` and two call sites.
2. **The email wraps; it is not cut with an ellipsis** (§6, §9.1). `MxSettingsRow` has no line limit, and `DESIGN.md`'s Wrap Rule says text containers grow and nothing is clamped; P3a's 23 row already wraps. Cost if wrong: a `maxLines` on `MxSettingsRow`.
3. **A re-auth opened from Study home goes through Settings**, as 13's sync notice does (`context.go(settingsSync)`): Back from screen 30 lands on Settings. A re-auth that succeeds returns to where it began through a `from` query parameter, so 13's ends on 13 (B9). Cost if wrong: a push across branches.
4. **The redirect reads the coordinator's own state**, not `authStateProvider`, because the provider hears of a change a frame late (P3a's toast finding): the link flow's `go('/settings/account')` must not be bounced to Settings. It sends `/settings/account` to Settings only while the device is plainly anonymous (`Ready(anonymous)`, `LocalOnly`, `Bootstrapping`, `Validating` of an anonymous or unknown user). During a transition it does nothing, so a refused deletion stays on 32. Cost if wrong: a flash of Settings after a switch.
5. **A finished switch or sign-out lands on Settings.** The redirect moves 32 to Settings once the device is anonymous (sign-out, delete, continue without); after a switch the account row shows the new account. Cost if wrong: one `go`.
6. **One confirm dialog for every account step** (`confirmAccountStep`), the Reset dialog's form (§9.1): title, body, optional note, Cancel · confirm. It returns true only on the confirm. The last-admin dialog is its own function with one OK.
7. **The last-admin dialog opens on the router's navigator** (`GoRouter.routerDelegate.navigatorKey`): the host sits above the router and has no navigator of its own outside the layer. It opens under the layer and shows once the layer leaves. Cost if wrong: the dialog moves to screen 32.
8. **A resend in `reauth` passes `confirmedLoss: true`.** Screen 31 opens only after the first code went out, which for another account needed the loss confirmed on 30 (P2 ruling 6); asking again would refuse the resend. Cost if wrong: a second dialog on 31.
9. **Two icons join `AppIcons`** (`switchAccount`, `signOut`), as P3a added `account`: screen 32's rows carry a glyph tile like every Settings row.
10. **"Continue without an account" sits under the form on 30**, a text button, block wide, after a section gap: screen 30 scrolls, so "the thumb zone" of §9.1 is the end of its column. Its confirm names the last account's email.

## Global Constraints

- **UI authority:** `DESIGN.md` and the reviewed goldens (ADR-019); the §9.1 shape. One primary fill per decision. Copy comes only from `context.l10n`; components hold no copy. Failure copy says what is safe first.
- **Layers (ADR-011, `flutter-architecture`):** presentation imports its own `domain/`/`di/`, `core/` and `shared/`, never `data/`. Study never imports account: `app/` composes the notice into a slot. File suffixes follow `check_architecture.py` (`_screen`, `_widget`, `_controller`, `_provider`, `_state`).
- **Strings:** every key in `app_en.arb` has a `description` and a Vietnamese value in `app_vi.arb`; run `flutter gen-l10n` after changing them (`lib/l10n/generated` is untracked).
- **Guard rules that bit P3a:** `no_text_restyle` (named `MxTextStyles` only, no `copyWith`); `no_ref_read_in_build` (the heuristic flags `ref.read` even inside a lambda in `build`: move it to a method); `no_temp_file_name`; `max_file_lines` 500 (error), `no_large_source_file` 400 (warning, avoid). `lib/app/router/app_router.dart` is at 476 lines: add at most the two lines Task 9 names.
- **Tests:** default text scale (Wrap Rule, R4); goldens English, light and dark, 1080×2400 (3x), tagged `golden`, rendered in this Linux container with `TZ=UTC`; pump 1 s before a capture so tap ink settles; `no_real_clock_in_test`.
- **Task gate, per task** (a scratchpad script that stops at the first failure, never piped through `tail`):
  - `dart format --output=none --set-exit-if-changed lib test`
  - `flutter analyze`
  - `bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
  - `python3.13 code-verification-guard-v2/guard/run.py check --project $PWD --ruleset memox-v8`
  - `flutter test <the task's test files> --exclude-tags golden`
- **Codegen:** after adding or changing a `@riverpod` declaration, `dart run build_runner build --delete-conflicting-outputs`.
- **Commits:** end each message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2`. No model id anywhere else.
- `S=/tmp/claude-0/-home-user-memox-v8/145740b4-0fc1-50a5-8b05-262c0c57b91d/scratchpad` for scripts.

## Review Focus

1. **Signing in again to the same address with changes unsent** must not ask about losing them (P2 compares the emails): Task 7 pins it.
2. **The network drops between the sign-out dialog and its confirm:** the online copy was shown, so `signOut()` runs without discarding, stops on the unsent changes and the layer offers the loss (P3a). Task 4 pins the command's result.
3. **A deep link to `/settings/account` on an anonymous device** lands on Settings, and one during a transition stays put: Task 9 pins both.
4. **A second tap on a 32 command while one runs** sends nothing: Task 4 pins it.
5. **Screen 32 while the account is checked again offline** (`Validating`): the rows are disabled and say why, and they come back on `Ready`: Task 5 pins it.

---

### Task 1: Core — sign-in methods and one network status

**Files:**
- Modify: `lib/core/auth/auth_gateway.dart`
- Modify: `lib/core/auth/supabase_auth_gateway.dart`
- Modify: `lib/core/auth/account_coordinator.dart`
- Modify: `lib/core/auth/di/auth_providers.dart`
- Modify: `lib/core/network/di/network_providers.dart`
- Modify: `test/support/fake_auth_server.dart`, `test/support/account_harness.dart`
- Test: `test/core/auth/sign_in_methods_test.dart`

**Interfaces:**
- Produces:
  - `enum SignInMethod { google, email }` in `auth_gateway.dart`;
  - `Set<SignInMethod> get signInMethods` on `AuthGateway`, `SupabaseAuthGateway`, `FakeAuthGateway` and `AccountCoordinator`;
  - top-level `Set<SignInMethod> signInMethodsOf(User? user)` in `supabase_auth_gateway.dart`;
  - `signInMethodsProvider` (`Set<SignInMethod>`, recomputed on every auth state) in `auth_providers.dart`;
  - `networkStatusProvider` (`NetworkStatus`, keepAlive) in `network_providers.dart`;
  - `accountOverrides(world)` now also overrides `networkStatusProvider` with `world.network`.

- [ ] **Step 1: Write the failing test** `test/core/auth/sign_in_methods_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../support/account_harness.dart';
import '../../support/auth_fakes.dart';

User _user({List<String> providers = const [], String? email}) => User.fromJson({
  'id': 'u1',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-09-30T00:00:00Z',
  'email': ?email,
  'identities': [
    for (final (index, provider) in providers.indexed)
      {
        'id': 'i$index',
        'user_id': 'u1',
        'identity_data': <String, dynamic>{},
        'provider': provider,
      },
  ],
})!;

void main() {
  group('signInMethodsOf', () {
    test('reads the identities GoTrue lists', () {
      expect(signInMethodsOf(_user(providers: ['google'])), {
        SignInMethod.google,
      });
      expect(signInMethodsOf(_user(providers: ['email', 'google'])), {
        SignInMethod.email,
        SignInMethod.google,
      });
    });

    test('an unknown provider and no session name nothing', () {
      expect(signInMethodsOf(_user(providers: ['anonymous'])), isEmpty);
      expect(signInMethodsOf(null), isEmpty);
    });
  });

  group('the coordinator and its provider', () {
    late AuthWorld world;
    late ProviderContainer container;

    setUp(() async {
      world = AuthWorld();
      await readyAnonymous(world);
      container = ProviderContainer(overrides: accountOverrides(world));
      container.listen(signInMethodsProvider, (_, _) {});
    });
    tearDown(() async {
      container.dispose();
      await world.close();
    });

    test('an anonymous user has no method; a linked email has one', () async {
      expect(world.coordinator.signInMethods, isEmpty);

      await linkEmail(world);
      await pumpEventQueue();

      expect(world.coordinator.signInMethods, {SignInMethod.email});
      expect(container.read(signInMethodsProvider), {SignInMethod.email});
    });

    test('the UI and the coordinator share one network status', () {
      expect(container.read(networkStatusProvider), same(world.network));
    });
  });
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/core/auth/sign_in_methods_test.dart`
Expected: compile errors: `SignInMethod`, `signInMethodsOf`, `signInMethods`, `signInMethodsProvider`, `networkStatusProvider` are not defined.

- [ ] **Step 3: Implement.**

In `lib/core/auth/auth_gateway.dart`, above `AuthGateway`:

```dart
/// How an account signs in (account UI spec §9 B1): its identities.
enum SignInMethod { google, email }
```

and inside `AuthGateway`, after `refreshToken`:

```dart
  /// The current user's identities, from the session the SDK keeps on the
  /// device: works offline (spec §9 B1). Empty without a session.
  Set<SignInMethod> get signInMethods;
```

In `lib/core/auth/supabase_auth_gateway.dart`, inside the class after `refreshToken`:

```dart
  @override
  Set<SignInMethod> get signInMethods =>
      signInMethodsOf(_auth.currentSession?.user);
```

and at the end of the file:

```dart
/// The methods [user]'s identities name; any other provider (anonymous)
/// names none.
Set<SignInMethod> signInMethodsOf(User? user) => {
  for (final identity in user?.identities ?? const <UserIdentity>[])
    ?switch (identity.provider) {
      'google' => SignInMethod.google,
      'email' => SignInMethod.email,
      _ => null,
    },
};
```

In `lib/core/auth/account_coordinator.dart`, next to the `state` getter:

```dart
  /// How the signed-in account signs in (account UI spec §9 B1).
  Set<SignInMethod> get signInMethods => _gateway.signInMethods;
```

In `lib/core/network/di/network_providers.dart` (import `package:memox/core/network/network_status.dart`):

```dart
/// The device's network hint (auth spec §6), one for the coordinator and
/// the screens that ask before an online-only step (account UI spec §9 B2).
@Riverpod(keepAlive: true)
NetworkStatus networkStatus(Ref ref) => ConnectivityNetworkStatus();
```

In `lib/core/auth/di/auth_providers.dart`: the coordinator takes `network: ref.watch(networkStatusProvider),` in place of `network: ConnectivityNetworkStatus(),` (drop the now unused import if `analyze` says so), and add:

```dart
/// How the signed-in account signs in, again on every account change
/// (account UI spec §9 B1).
@riverpod
Set<SignInMethod> signInMethods(Ref ref) {
  ref.watch(authStateProvider);
  return ref.watch(accountCoordinatorProvider)?.signInMethods ?? const {};
}
```

In `test/support/fake_auth_server.dart`:
- `FakeUser` gains `final methods = <SignInMethod>{};` (import `package:memox/core/auth/auth_gateway.dart` is already there through `FakeAuthGateway`; add it if not).
- `verifyEmailLink` adds `..methods.add(SignInMethod.email)` to the cascade on `server.users[_userId]!`.
- `linkGoogle` adds `..methods.add(SignInMethod.google)` the same way.
- `verifyEmailSignIn` becomes:

```dart
    final user = server.userByEmail(email) ?? server.addUser(email: email);
    user.methods.add(SignInMethod.email);
    _set(user.id);
    afterSignIn?.call();
```

- `signInGoogle` does the same with `SignInMethod.google`.
- `FakeAuthGateway` gains:

```dart
  @override
  Set<SignInMethod> get signInMethods =>
      Set.of(server.users[_userId]?.methods ?? const <SignInMethod>{});
```

In `test/support/account_harness.dart`, `accountOverrides` gains `networkStatusProvider.overrideWithValue(world.network),` (import `package:memox/core/network/di/network_providers.dart`).

Run `dart run build_runner build --delete-conflicting-outputs`.

- [ ] **Step 4: Run the test**

Run: `flutter test test/core/auth/sign_in_methods_test.dart test/core/auth test/features/account`
Expected: all pass.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/core test/support test/core/auth/sign_in_methods_test.dart
git commit -m "feat(auth): sign-in methods from the session and one network status (P3b B1, B2)"
```

---

### Task 2: The vocabulary — strings, icons, routes and the device's account

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Modify: `lib/core/theme/foundations/app_icons.dart`
- Modify: `lib/app/router/app_routes.dart`
- Create: `lib/features/account/presentation/providers/device_account_provider.dart`
- Test: `test/features/account/presentation/device_account_provider_test.dart`, `test/app/account_redirect_test.dart` (paths only)

**Interfaces:**
- Produces:
  - every `l10n.account*` key of Step 1, and `accountLastAdmin` re-described as a dialog body;
  - `AppIcons.switchAccount`, `AppIcons.signOut`;
  - `AppRoutes.settingsAccountChild`, `AppRoutes.settingsAccount` (`/settings/account`), `AppRoutes.accountReauthMode` (`reauth`), `AppRoutes.accountFromParam` (`from`), `AppRoutes.settingsSignInReauth({required String from})`, `AppRoutes.settingsSignInCodeReauth(String email, {required String from})`;
  - `AccountUser? deviceAccountOf(AuthState? state)` and `deviceAccountProvider` (`AccountUser?`).

- [ ] **Step 1: Add the strings.** Save as `$S/add_manage_strings.py`, run `python3.13 $S/add_manage_strings.py && flutter gen-l10n`:

```python
import json
from pathlib import Path

S = "Account UI spec"
STRINGS = [
    ("accountTitle", "Account", "Tài khoản", f"Screen 32's title ({S} §5.6).", None),
    ("accountMethodGoogle", "Signed in with Google", "Đăng nhập bằng Google", f"Screen 32: under the email ({S} §9 B1).", None),
    ("accountMethodEmail", "Signed in with email", "Đăng nhập bằng email", f"Screen 32: under the email ({S} §9 B1).", None),
    ("accountMethodBoth", "Signed in with Google and email", "Đăng nhập bằng Google và email", f"Screen 32: under the email, both identities ({S} §9 B1).", None),
    ("accountThisPhone", "This phone", "Điện thoại này", f"Screen 32: the commands' overline ({S} §9.1).", None),
    ("accountSwitch", "Switch account", "Đổi tài khoản", f"Screen 32's row and its dialog's confirm ({S} §5.6).", None),
    ("accountSwitchHint", "Move this phone to another account", "Chuyển điện thoại này sang tài khoản khác", f"Screen 32: under Switch account ({S} §9.1).", None),
    ("accountSignOut", "Sign out", "Đăng xuất", f"Screen 32's row and its dialog's confirm ({S} §5.6).", None),
    ("accountSignOutHint", "Your changes are sent first", "Các thay đổi được gửi trước", f"Screen 32: under Sign out ({S} §9.1).", None),
    ("accountDeleteSection", "Delete", "Xoá", f"Screen 32: the last section's overline ({S} §9.1 B12).", None),
    ("accountDelete", "Delete account", "Xoá tài khoản", f"Screen 32's row and its dialog's confirm ({S} §5.6).", None),
    ("accountDeleteHint", "Your account and its data, for good", "Tài khoản và dữ liệu của nó, vĩnh viễn", f"Screen 32: under Delete account ({S} §9.1).", None),
    ("accountNeedsConnection", "Managing your account needs a connection. Your decks are safe on this phone.", "Cần kết nối mạng để quản lý tài khoản. Bộ thẻ vẫn an toàn trên điện thoại này.", f"Screen 32: while the account is checked again ({S} §9 B3).", None),
    ("accountReauthBanner", "Your sign-in expired. Your decks are still on this phone.", "Phiên đăng nhập đã hết hạn. Bộ thẻ vẫn còn trên điện thoại này.", f"Screens 23, 32 and 13: the re-auth banner and notice ({S} §5.5, §5.7).", None),
    ("accountSwitchTitle", "Switch account?", "Đổi tài khoản?", f"Switch dialog: title ({S} §9.1).", None),
    ("accountSwitchBody", "This phone's data is replaced by the other account's after your changes are sent.", "Sau khi các thay đổi được gửi, dữ liệu trên điện thoại này sẽ được thay bằng dữ liệu của tài khoản kia.", f"Switch dialog: body ({S} §5.6).", None),
    ("accountChangesSentFirst", "Your changes are sent first.", "Các thay đổi của bạn được gửi trước.", f"Switch dialog: the reassurance note ({S} §9.1).", None),
    ("accountSignOutTitle", "Sign out?", "Đăng xuất?", f"Sign-out dialog: title ({S} §9.1).", None),
    ("accountSignOutBody", "Your changes are sent first, then this phone's data is removed. Sign in again to get it back.", "Các thay đổi được gửi trước, sau đó dữ liệu trên điện thoại này bị xoá. Đăng nhập lại để lấy lại.", f"Sign-out dialog: body ({S} §5.6).", None),
    ("accountSignOutLossTitle", "Sign out and lose changes?", "Đăng xuất và mất thay đổi?", f"Sign-out dialog offline with unsent changes: title ({S} §9 B4).", None),
    ("accountSignOutLossBody", "{count, plural, =1{1 change isn't sent yet and will be lost.} other{{count} changes aren't sent yet and will be lost.}}", "{count} thay đổi chưa được gửi và sẽ bị mất.", f"Sign-out dialog offline with unsent changes: body ({S} §9 B4).", {"count": {"type": "int"}}),
    ("accountDeleteTitle", "Delete your account?", "Xoá tài khoản?", f"Delete dialog: title ({S} §9.1).", None),
    ("accountDeleteBody", "Your account and its decks, cards and progress are deleted from the server, and this phone's data is removed. This can't be undone.", "Tài khoản cùng bộ thẻ, thẻ và tiến độ trên máy chủ sẽ bị xoá, dữ liệu trên điện thoại này cũng bị xoá. Không thể hoàn tác.", f"Delete dialog: what goes ({S} §9 B6).", None),
    ("accountDeleteOffline", "Deleting your account needs a connection.", "Cần kết nối mạng để xoá tài khoản.", f"Delete dialog offline: why the confirm is disabled ({S} §9 B6).", None),
    ("accountLastAdminTitle", "An admin must remain", "Phải còn một admin", f"Last-admin dialog: title ({S} §9 B7).", None),
    ("accountCommandFailed", "Couldn't finish that. Nothing changed; try again.", "Chưa làm được. Chưa có gì thay đổi; hãy thử lại.", f"Screen 32: toast when a command was refused ({S} §9).", None),
    ("accountReauthLine", "Sign in again to keep syncing. Your decks are still here.", "Đăng nhập lại để tiếp tục đồng bộ. Bộ thẻ vẫn còn ở đây.", f"Screen 30 in reauth mode: the mode line ({S} §5.2).", None),
    ("accountUnsentTitle", "Lose {count, plural, =1{1 change} other{{count} changes}}?", "Mất {count} thay đổi?", f"Screen 30 reauth, another account: title ({S} §9 B8).", {"count": {"type": "int"}}),
    ("accountUnsentBody", "{count, plural, =1{1 change on this phone isn't sent and will be lost.} other{{count} changes on this phone aren't sent and will be lost.}}", "{count} thay đổi trên điện thoại này chưa được gửi và sẽ bị mất.", f"Screen 30 reauth, another account: body ({S} §5.2).", {"count": {"type": "int"}}),
    ("accountWithoutTitle", "Continue without an account?", "Tiếp tục không cần tài khoản?", f"Screen 30 reauth: the confirm's title ({S} §9.1).", None),
    ("accountWithoutBody", "This phone's decks from {email} are removed. Sign in to {email} later to get them back.", "Bộ thẻ của {email} trên điện thoại này sẽ bị xoá. Đăng nhập lại {email} sau để lấy lại.", f"Screen 30 reauth: what continuing without does ({S} §9.1).", {"email": {"type": "String"}}),
]


def update(path, value_of, with_meta):
    file = Path(path)
    data = json.loads(file.read_text(encoding="utf-8"))
    for key, en, vi, description, placeholders in STRINGS:
        assert key not in data, key
        data[key] = value_of(en, vi)
        if with_meta:
            meta = {"description": description}
            if placeholders:
                meta = {"placeholders": placeholders, "description": description}
            data["@" + key] = meta
    if with_meta:
        data["@accountLastAdmin"]["description"] = (
            f"Last-admin dialog: body; the last admin cannot delete the account ({S} §9 B7)."
        )
    file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


update("lib/l10n/app_en.arb", lambda en, vi: en, True)
update("lib/l10n/app_vi.arb", lambda en, vi: vi, False)
```

Check: `git diff --stat lib/l10n` shows only additions plus the one description line in `app_en.arb`.

- [ ] **Step 2: Write the failing tests.**

`test/features/account/presentation/device_account_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';

import '../../../support/account_harness.dart';

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);
const _anonymous = AccountUser(
  id: 'n',
  isAnonymous: true,
  role: AccountRole.user,
);

void main() {
  test('the confirmed, checked or refused account is the device\'s', () {
    expect(deviceAccountOf(const Ready(_account)), _account);
    expect(deviceAccountOf(const Validating(_account)), _account);
    expect(deviceAccountOf(const ReauthRequired(_account)), _account);
  });

  test('an anonymous device, a start and a transition have none', () {
    expect(deviceAccountOf(const Ready(_anonymous)), isNull);
    expect(deviceAccountOf(const Validating(null)), isNull);
    expect(deviceAccountOf(const LocalOnly()), isNull);
    expect(deviceAccountOf(null), isNull);
    expect(
      deviceAccountOf(
        Transitioning(
          transitionOf(TransitionKind.signOut, TransitionStage.started),
        ),
      ),
      isNull,
    );
  });
}
```

In `test/app/account_redirect_test.dart`, add to the test `'the paths are what the routes register'`:

```dart
    expect(AppRoutes.settingsAccount, '/settings/account');
    expect(
      AppRoutes.settingsSignInReauth(from: '/study'),
      '/settings/sign-in?mode=reauth&from=%2Fstudy',
    );
    expect(
      AppRoutes.settingsSignInCodeReauth('a@example.com', from: '/settings'),
      '/settings/sign-in/code?mode=reauth&email=a%40example.com'
      '&from=%2Fsettings',
    );
```

Check the `Transitioning` constructor's other parameters in `lib/core/auth/auth_state.dart` before running: if any is required, pass it as `account_golden_test.dart` does.

- [ ] **Step 3: Run them to see them fail**

Run: `flutter test test/features/account/presentation/device_account_provider_test.dart test/app/account_redirect_test.dart`
Expected: compile errors for `deviceAccountOf`, `settingsAccount`, `settingsSignInReauth`, `settingsSignInCodeReauth`.

- [ ] **Step 4: Implement.**

`lib/features/account/presentation/providers/device_account_provider.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_account_provider.g.dart';

/// The account this device's data belongs to (account UI spec §9 B3): the
/// confirmed one, or the last known while it is checked again or refused.
/// None on an anonymous device, while starting, and during a transition.
AccountUser? deviceAccountOf(AuthState? state) => switch (state) {
  Ready(:final user) when !user.isAnonymous => user,
  Validating(:final last?) when !last.isAnonymous => last,
  ReauthRequired(:final last) => last,
  _ => null,
};

/// [deviceAccountOf] the current state, for 23, 30 and 32.
@riverpod
AccountUser? deviceAccount(Ref ref) =>
    deviceAccountOf(ref.watch(authStateProvider).value);
```

`lib/core/theme/foundations/app_icons.dart`, next to `account`:

```dart
  static const IconData switchAccount = Icons.swap_horiz; // arrow-left-right
  static const IconData signOut = Icons.logout; // log-out
```

`lib/app/router/app_routes.dart`, after `settingsSignInCodeLink`:

```dart
  /// Screen 32 (account UI spec §5.6), under [settings] like Sync.
  static const String settingsAccountChild = 'account';
  static const String settingsAccount = '$settings/$settingsAccountChild';

  /// Signing in again (spec §5.2) and where the flow began, to return to
  /// once it succeeds (spec §9 B9).
  static const String accountReauthMode = 'reauth';
  static const String accountFromParam = 'from';

  static String settingsSignInReauth({required String from}) => Uri(
    path: settingsSignIn,
    queryParameters: {
      accountModeParam: accountReauthMode,
      accountFromParam: from,
    },
  ).toString();

  static String settingsSignInCodeReauth(
    String email, {
    required String from,
  }) => Uri(
    path: settingsSignInCode,
    queryParameters: {
      accountModeParam: accountReauthMode,
      accountEmailParam: email,
      accountFromParam: from,
    },
  ).toString();
```

Also change the doc comment above `settingsSignInChild` from "P3a has the link; P3b adds re-auth." to "`link` attaches an account, `reauth` signs in again." Run build_runner.

- [ ] **Step 5: Run the tests**

Run: `flutter test test/features/account/presentation/device_account_provider_test.dart test/app/account_redirect_test.dart`
Expected: all pass.

- [ ] **Step 6: Gate and commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_vi.arb lib/core/theme/foundations/app_icons.dart lib/app/router/app_routes.dart lib/features/account/presentation/providers/device_account_provider.dart test/features/account/presentation/device_account_provider_test.dart test/app/account_redirect_test.dart
git commit -m "feat(account): P3b strings, icons, routes and the device's account"
```

---

### Task 3: The account confirm dialog and the last-admin dialog

**Files:**
- Create: `lib/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart`
- Modify: `lib/features/account/presentation/widgets/sections/account_layer_host_widget.dart`
- Modify: `lib/app/app.dart` (the host's new parameter)
- Test: `test/features/account/presentation/account_confirm_dialog_test.dart`, `test/features/account/presentation/account_transition_layer_test.dart` (wherever it builds `AccountLayerHostWidget`)

**Interfaces:**
- Produces:
  - `Future<bool> confirmAccountStep(BuildContext context, {required String title, required String body, required String confirmLabel, Widget? note, IconData? confirmIcon, bool isDestructive = false, bool canConfirm = true})`;
  - `Future<void> showLastAdminDialog(BuildContext context)`;
  - `AccountLayerHostWidget({required BackButtonDispatcher backButtons, required GlobalKey<NavigatorState> dialogNavigator, required Widget child})`.

- [ ] **Step 1: Write the failing test** `test/features/account/presentation/account_confirm_dialog_test.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';

import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

void main() {
  late bool? answer;

  Widget host({bool canConfirm = true}) => Scaffold(
    body: Builder(
      builder: (context) => TextButton(
        onPressed: () => unawaited(
          confirmAccountStep(
            context,
            title: 'Sure?',
            body: 'Body',
            confirmLabel: 'Do it',
            isDestructive: true,
            canConfirm: canConfirm,
          ).then((value) => answer = value),
        ),
        child: const Text('ask'),
      ),
    ),
  );

  setUp(() => answer = null);

  libraryTest('the confirm answers yes, Cancel no', (tester, env) async {
    await pumpLibraryScreen(tester, env, host());
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    expect(find.text('Sure?'), findsOneWidget);
    await tester.tap(find.text('Do it'));
    await tester.pumpAndSettle();
    expect(answer, isTrue);

    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_en.commonCancel));
    await tester.pumpAndSettle();
    expect(answer, isFalse);
  });

  libraryTest('a confirm that cannot go is disabled', (tester, env) async {
    await pumpLibraryScreen(tester, env, host(canConfirm: false));
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();

    final confirm = tester.widget<MxButton>(
      find.widgetWithText(MxButton, 'Do it'),
    );
    expect(confirm.onPressed, isNull);
    expect(confirm.tone, MxButtonTone.destructive);
  });

  libraryTest('the last-admin dialog explains and closes on OK', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => unawaited(showLastAdminDialog(context)),
            child: const Text('refuse'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('refuse'));
    await tester.pumpAndSettle();
    expect(find.text(_en.accountLastAdminTitle), findsOneWidget);
    expect(find.text(_en.accountLastAdmin), findsOneWidget);

    await tester.tap(find.text(_en.commonOk));
    await tester.pumpAndSettle();
    expect(find.text(_en.accountLastAdminTitle), findsNothing);
  });
}
```

(If `libraryTest`/`pumpLibraryScreen` are not the harness names for a plain widget, use the ones `settings_reset_dialog` tests use; check `test/support/library_harness.dart`. If `MxButton` exposes its tone under another name, assert through the `MxSheetActions.isDestructive` of the dialog instead.)

In the test that pumps `AccountLayerHostWidget` (search `test/` for `AccountLayerHostWidget(`), add a test:

```dart
  accountTest('a refused last-admin deletion is a dialog, not a toast', (
    tester,
    env,
    world,
  ) async {
    // The host as app.dart builds it, over a navigator of its own.
    final navigator = GlobalKey<NavigatorState>();
    await pumpLibraryScreen(
      tester,
      env,
      Navigator(
        key: navigator,
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('page')),
        ),
      ),
      overrides: accountOverrides(world),
      wrap: (child) => AccountLayerHostWidget(
        backButtons: RootBackButtonDispatcher(),
        dialogNavigator: navigator,
        child: child,
      ),
    );
    await linkEmail(world);
    world.server.users[world.gateway.currentUserId]!.role = AccountRole.admin;
    await world.coordinator.deleteAccount();
    await tester.pumpAndSettle();

    expect(find.text(_en.accountLastAdminTitle), findsOneWidget);
  });
```

Match the existing host test's own way of pumping the host (it already solves "the host above a navigator"); reuse it rather than the `wrap:` sketch above if it differs.

- [ ] **Step 2: Run to see it fail**

Run: `flutter test test/features/account/presentation/account_confirm_dialog_test.dart test/features/account/presentation/account_transition_layer_test.dart`
Expected: compile errors for `confirmAccountStep`, `showLastAdminDialog` and `dialogNavigator`.

- [ ] **Step 3: Implement** `account_confirm_dialog_widget.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_dialog.dart';
import 'package:memox/shared/widgets/mx_sheet_actions.dart';

/// Asks before an account step (account UI spec §9.1, plan ruling 6), in
/// the Reset dialog's form: a title, the body, an optional note, Cancel and
/// the confirm. True only on the confirm; Cancel, Back and the scrim are a
/// no.
Future<bool> confirmAccountStep(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  Widget? note,
  IconData? confirmIcon,
  bool isDestructive = false,
  bool canConfirm = true,
}) async =>
    await showMxDialog<bool>(
      context,
      builder: (_) => AccountConfirmDialogWidget(
        title: title,
        body: body,
        confirmLabel: confirmLabel,
        note: note,
        confirmIcon: confirmIcon,
        isDestructive: isDestructive,
        canConfirm: canConfirm,
      ),
    ) ??
    false;

/// A refused deletion of the last admin (spec §5.4, §9 B7): what to do
/// first, and one OK.
Future<void> showLastAdminDialog(BuildContext context) => showMxDialog<void>(
  context,
  builder: (dialogContext) {
    final l10n = dialogContext.l10n;
    return MxDialog(
      title: l10n.accountLastAdminTitle,
      body: l10n.accountLastAdmin,
      actions: MxSheetActions.custom(
        children: [
          MxButton(
            label: l10n.commonOk,
            isBlock: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  },
);

class AccountConfirmDialogWidget extends StatelessWidget {
  const AccountConfirmDialogWidget({
    super.key,
    required this.title,
    required this.body,
    required this.confirmLabel,
    this.note,
    this.confirmIcon,
    this.isDestructive = false,
    this.canConfirm = true,
  });

  final String title;
  final String body;
  final String confirmLabel;

  /// An `MxNote`: the reassurance, or why the confirm cannot go.
  final Widget? note;
  final IconData? confirmIcon;
  final bool isDestructive;

  /// False disables the confirm, as a deletion offline (spec §9 B6).
  final bool canConfirm;

  @override
  Widget build(BuildContext context) => MxDialog(
    title: title,
    body: body,
    content: note,
    actions: MxSheetActions(
      cancelLabel: context.l10n.commonCancel,
      onCancel: () => Navigator.of(context).pop(false),
      confirmLabel: confirmLabel,
      confirmIcon: confirmIcon,
      isDestructive: isDestructive,
      onConfirm: canConfirm ? () => Navigator.of(context).pop(true) : null,
    ),
  );
}
```

In `account_layer_host_widget.dart`:
- add the field, documented:

```dart
  /// The router's navigator, where the last-admin dialog opens (plan
  /// ruling 7).
  final GlobalKey<NavigatorState> dialogNavigator;
```

- in `_say`, before the snackbar:

```dart
    if (notice case DeleteRefused(failure: LastAdminFailure())) {
      final dialogContext = widget.dialogNavigator.currentContext;
      if (dialogContext != null) unawaited(showLastAdminDialog(dialogContext));
      return;
    }
```

- drop the `LastAdminFailure` arm from the snackbar's switch, and update the class comment's "notices (plan ruling 8)" to "notices (plan ruling 8; the last admin is a dialog, P3b B7)".

In `lib/app/app.dart`, the host gets `dialogNavigator: _router.routerDelegate.navigatorKey,`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/presentation/account_confirm_dialog_test.dart test/features/account/presentation/account_transition_layer_test.dart test/app`
Expected: all pass.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/features/account/presentation/widgets lib/app/app.dart test/features/account/presentation
git commit -m "feat(account): the account confirm dialog and the last-admin dialog (P3b B7)"
```

---

### Task 4: Screen 32's commands

**Files:**
- Create: `lib/features/account/presentation/controllers/account_manage_controller.dart`
- Test: `test/features/account/presentation/account_manage_controller_test.dart`

**Interfaces:**
- Consumes: `networkStatusProvider`, `syncControlProvider`, `accountCoordinatorProvider`.
- Produces:
  - `enum AccountCommandResult { done, none, offline, failed }`;
  - `accountManageControllerProvider` (state `bool`, true while a command runs) with `Future<int> changesLostBySignOut()`, `Future<bool> canDelete()`, `Future<AccountCommandResult> switchAccount()`, `signOut({required bool discardUnsent})`, `deleteAccount()` and `continueWithoutAccount()`.

- [ ] **Step 1: Write the failing test** `account_manage_controller_test.dart`:

```dart
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

  test('online, a sign-out loses nothing; offline, the unsent changes', () async {
    expect(await controller().changesLostBySignOut(), 0);

    world.network.goOffline();
    expect(await controller().changesLostBySignOut(), 2);
  });

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

  test('the network gone after the online dialog: the sign-out stops on '
      'the unsent changes and the layer offers the loss (Review Focus 2)', () async {
    world.network.goOffline();

    expect(
      await controller().signOut(discardUnsent: false),
      AccountCommandResult.done,
    );
    expect(
      world.state,
      isA<Transitioning>().having((s) => s.error, 'error', isNotNull),
    );
  });

  test('a second command while one runs sends nothing (Review Focus 4)', () async {
    // _run sets its flag before its first await, so the switch is still
    // running when the sign-out arrives.
    final first = controller().switchAccount();
    expect(await controller().signOut(discardUnsent: false),
        AccountCommandResult.none);
    expect(await first, AccountCommandResult.done);
    expect(world.state, isA<Transitioning>());
  });

  test('a command in the wrong state is a failure, not a crash', () async {
    world.gateway.dropSession();
    await pumpEventQueue();
    expect(world.state, isA<ReauthRequired>());

    expect(await controller().switchAccount(), AccountCommandResult.failed);
  });
}
```

- [ ] **Step 2: Run to see it fail**

Run: `flutter test test/features/account/presentation/account_manage_controller_test.dart`
Expected: compile error, `account_manage_controller.dart` does not exist.

- [ ] **Step 3: Implement** `account_manage_controller.dart`:

```dart
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/network/di/network_providers.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_manage_controller.g.dart';

/// What an account command came to, for the screen to say.
enum AccountCommandResult {
  /// It ran; the transition layer shows the rest.
  done,

  /// Nothing ran: another command is running.
  none,

  /// Refused before anything changed: no network.
  offline,

  /// Refused before anything changed.
  failed,
}

/// Screen 32's and screen 30's account commands (account UI spec §5.6, §9):
/// what a sign-out would lose and whether a deletion can go, read once as
/// their dialog opens (B2), then the command. The state is true while one
/// runs.
@riverpod
class AccountManageController extends _$AccountManageController {
  @override
  bool build() => false;

  /// None online; offline, the changes not sent yet (spec §9 B4).
  Future<int> changesLostBySignOut() async {
    if (await ref.read(networkStatusProvider).isOnline) return 0;
    return ref.read(syncControlProvider).pendingCount();
  }

  /// A deletion needs the network (spec §9 B6).
  Future<bool> canDelete() => ref.read(networkStatusProvider).isOnline;

  /// R1: the target sign-in happens inside the transition layer.
  Future<AccountCommandResult> switchAccount() => _run(
    (accounts) => accounts.beginSwitch(choice: TransitionChoice.discard),
  );

  Future<AccountCommandResult> signOut({required bool discardUnsent}) =>
      _run((accounts) => accounts.signOut(discardUnsent: discardUnsent));

  Future<AccountCommandResult> deleteAccount() =>
      _run((accounts) => accounts.deleteAccount());

  /// From an expired sign-in (screen 30, spec §9 B8).
  Future<AccountCommandResult> continueWithoutAccount() =>
      _run((accounts) => accounts.continueWithoutAccount());

  Future<AccountCommandResult> _run(
    Future<void> Function(AccountCoordinator accounts) command,
  ) async {
    final accounts = ref.read(accountCoordinatorProvider);
    if (accounts == null || state) return AccountCommandResult.none;
    state = true;
    var result = AccountCommandResult.done;
    try {
      await command(accounts);
    } on OfflineFailure {
      result = AccountCommandResult.offline;
    } on Failure {
      result = AccountCommandResult.failed;
    } on StateError {
      // The account moved on meanwhile: P2 runs these only in Ready.
      result = AccountCommandResult.failed;
    }
    if (ref.mounted) state = false;
    return result;
  }
}
```

Run build_runner.

- [ ] **Step 4: Run the test**

Run: `flutter test test/features/account/presentation/account_manage_controller_test.dart`
Expected: 6 pass. If the "second command" test sees the switch finish before the second call, the flag is set too late: keep `state = true` before the first `await`, as written.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/features/account/presentation/controllers/account_manage_controller.dart test/features/account/presentation/account_manage_controller_test.dart
git commit -m "feat(account): screen 32's commands (P3b B2, B4, B6)"
```

---

### Task 5: Screen 32 and the re-auth banner

**Files:**
- Create: `lib/features/account/presentation/screens/account_screen.dart`
- Create: `lib/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart`
- Modify: `lib/features/account/presentation/widgets/support/account_labels_widget.dart`
- Test: `test/features/account/presentation/account_screen_test.dart`
- Test: `test/visual_audit/screens/features/account/screens/account_screen_visual_audit_test.dart`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces:
  - `AccountScreen({required VoidCallback onSignInAgain})`;
  - `AccountReauthBannerWidget({required VoidCallback onSignIn})`;
  - `String? signInMethodText(AppLocalizations l10n, Set<SignInMethod> methods)` in `account_labels_widget.dart`;
  - `void sayAccountResult(BuildContext context, AccountCommandResult result)` in `account_labels_widget.dart`.

- [ ] **Step 1: Write the failing test** `account_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/screens/account_screen.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

import '../../../support/account_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

const _account = AccountUser(
  id: 'x',
  email: 'a@example.com',
  isAnonymous: false,
  role: AccountRole.user,
);

MxSettingsRow _row(WidgetTester tester, String label) =>
    tester.widget<MxSettingsRow>(find.widgetWithText(MxSettingsRow, label));

void main() {
  late int signIns;

  setUp(() => signIns = 0);

  Widget screen() => AccountScreen(onSignInAgain: () => signIns++);

  accountTest('the account, how it signs in, and three commands', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text(_en.accountMethodEmail), findsOneWidget);
    for (final label in [
      _en.accountSwitch,
      _en.accountSignOut,
      _en.accountDelete,
    ]) {
      expect(_row(tester, label).isEnabled, isTrue);
    }
  });

  accountTest('checked again offline: the commands wait and say why '
      '(Review Focus 5)', (tester, env, world) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const Validating(_account)),
      ],
    );

    expect(find.text('a@example.com'), findsOneWidget);
    expect(find.text(_en.accountNeedsConnection), findsOneWidget);
    expect(_row(tester, _en.accountSignOut).isEnabled, isFalse);
  });

  accountTest('an expired sign-in shows the banner, whose Sign in opens 30', (
    tester,
    env,
    world,
  ) async {
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const ReauthRequired(_account)),
      ],
    );

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(_row(tester, _en.accountDelete).isEnabled, isFalse);
    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    expect(signIns, 1);
  });

  accountTest('Switch account asks, then starts the switch', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountSwitch));
    await tester.pumpAndSettle();
    expect(find.text(_en.accountSwitchTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.accountSwitch));
    await tester.pumpAndSettle();

    expect(world.state, isA<Transitioning>());
  });

  accountTest('Sign out offline with unsent changes names the loss', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();

    expect(find.text(_en.accountSignOutLossTitle), findsOneWidget);
    expect(find.text(_en.accountSignOutLossBody(2)), findsOneWidget);
  });

  accountTest('Delete offline cannot be confirmed', (tester, env, world) async {
    await linkEmail(world);
    world.network.goOffline();
    await pumpLibraryScreen(
      tester,
      env,
      screen(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text(_en.accountDelete));
    await tester.pumpAndSettle();

    expect(find.text(_en.accountDeleteOffline), findsOneWidget);
    final confirm = tester.widget<MxButton>(
      find.widgetWithText(MxButton, _en.accountDelete),
    );
    expect(confirm.onPressed, isNull);
  });
}
```

The visual-audit companion (every production screen needs one), `account_screen_visual_audit_test.dart`:

```dart
import 'package:memox/features/account/presentation/screens/account_screen.dart';

import '../../../../../support/account_harness.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

void main() {
  accountTest('screen 32', (tester, env, world) async {
    await linkEmail(world);
    await auditProductionScreen(
      tester,
      screen: AccountScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        AccountScreen(onSignInAgain: () {}),
        brightness: brightness,
        textScale: scale,
        overrides: accountOverrides(world),
      ),
    );
  });
}
```

- [ ] **Step 2: Run to see it fail**

Run: `flutter test test/features/account/presentation/account_screen_test.dart`
Expected: compile error, `account_screen.dart` does not exist.

- [ ] **Step 3: Implement.**

`account_reauth_banner_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// An expired sign-in, where the screen owns it (account UI spec §5.5,
/// R2): 23 and 32. What is safe first, then Sign in.
class AccountReauthBannerWidget extends StatelessWidget {
  const AccountReauthBannerWidget({super.key, required this.onSignIn});

  /// Opens screen 30 in its reauth mode.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxInlineBanner(
      tone: MxBannerTone.warning,
      message: l10n.accountReauthBanner,
      actions: [
        MxButton(
          label: l10n.accountSignIn,
          size: MxButtonSize.compact,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}
```

In `account_labels_widget.dart` (imports: `package:memox/core/auth/auth_gateway.dart`, the controller file):

```dart
/// Screen 32's line under the email (spec §9 B1); none when the session
/// names no method.
String? signInMethodText(
  AppLocalizations l10n,
  Set<SignInMethod> methods,
) => switch ((
  methods.contains(SignInMethod.google),
  methods.contains(SignInMethod.email),
)) {
  (true, true) => l10n.accountMethodBoth,
  (true, false) => l10n.accountMethodGoogle,
  (false, true) => l10n.accountMethodEmail,
  (false, false) => null,
};

/// The toast for a refused account command; a command that ran says
/// nothing, since the transition layer shows it.
void sayAccountResult(BuildContext context, AccountCommandResult result) {
  if (!context.mounted) return;
  final l10n = context.l10n;
  final message = switch (result) {
    AccountCommandResult.offline => l10n.accountOffline,
    AccountCommandResult.failed => l10n.accountCommandFailed,
    AccountCommandResult.done || AccountCommandResult.none => null,
  };
  if (message != null) showMxSnackbar(context, message: message);
}
```

`account_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/account/presentation/controllers/account_manage_controller.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';
import 'package:memox/features/account/presentation/widgets/overlays/account_confirm_dialog_widget.dart';
import 'package:memox/features/account/presentation/widgets/sections/account_reauth_banner_widget.dart';
import 'package:memox/features/account/presentation/widgets/support/account_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_section.dart';
import 'package:memox/shared/widgets/mx_settings_row.dart';

/// Screen 32 (account UI spec §5.6, §9, §9.1): the account this phone's
/// data belongs to, then switch, sign out and delete. The commands need a
/// confirmed account (auth spec #39): before `Ready` they wait and say why
/// (B3). Each asks first; the transition layer shows what follows.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key, required this.onSignInAgain});

  /// Opens screen 30 in its reauth mode (spec §5.5).
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(authStateProvider).value;
    final account = ref.watch(deviceAccountProvider);
    final canManage =
        state is Ready && !ref.watch(accountManageControllerProvider);
    MxSettingsRow command(
      String label,
      String hint,
      IconData icon,
      Future<void> Function(BuildContext, WidgetRef) run,
    ) => MxSettingsRow(
      label: label,
      subtitle: hint,
      icon: icon,
      isEnabled: canManage,
      onTap: canManage ? () => unawaited(run(context, ref)) : null,
    );
    return MxAppShell(
      appBar: MxAppBar(
        title: l10n.accountTitle,
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
      ),
      body: MxScreenScroll(
        children: [
          if (state is ReauthRequired) ...[
            AccountReauthBannerWidget(onSignIn: onSignInAgain),
            const SizedBox(height: AppSpacing.gutter),
          ] else if (state is Validating) ...[
            MxNote(text: l10n.accountNeedsConnection),
            const SizedBox(height: AppSpacing.gutter),
          ],
          MxSection(
            title: l10n.accountSection,
            children: [
              MxSettingsRow(
                label: account?.email ?? l10n.accountSignedIn,
                subtitle: signInMethodText(
                  l10n,
                  ref.watch(signInMethodsProvider),
                ),
                icon: AppIcons.account,
              ),
            ],
          ),
          MxSection(
            title: l10n.accountThisPhone,
            children: [
              command(
                l10n.accountSwitch,
                l10n.accountSwitchHint,
                AppIcons.switchAccount,
                _switch,
              ),
              command(
                l10n.accountSignOut,
                l10n.accountSignOutHint,
                AppIcons.signOut,
                _signOut,
              ),
            ],
          ),
          MxSection(
            title: l10n.accountDeleteSection,
            children: [
              command(
                l10n.accountDelete,
                l10n.accountDeleteHint,
                AppIcons.delete,
                _delete,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _switch(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountSwitchTitle,
      body: l10n.accountSwitchBody,
      note: MxNote(icon: AppIcons.safe, text: l10n.accountChangesSentFirst),
      confirmLabel: l10n.accountSwitch,
    );
    if (!isSure || !context.mounted) return;
    sayAccountResult(context, await controller.switchAccount());
  }

  /// Online, or with nothing unsent, the changes go first; offline with
  /// changes unsent, their loss is named and accepted (spec §9 B4).
  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final lost = await controller.changesLostBySignOut();
    if (!context.mounted) return;
    final l10n = context.l10n;
    final isLosing = lost > 0;
    final isSure = await confirmAccountStep(
      context,
      title: isLosing ? l10n.accountSignOutLossTitle : l10n.accountSignOutTitle,
      body: isLosing
          ? l10n.accountSignOutLossBody(lost)
          : l10n.accountSignOutBody,
      confirmLabel: l10n.accountSignOut,
      isDestructive: isLosing,
    );
    if (!isSure || !context.mounted) return;
    sayAccountResult(
      context,
      await controller.signOut(discardUnsent: isLosing),
    );
  }

  /// Online only: offline the confirm is disabled and says why (spec §9
  /// B6).
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final canDelete = await controller.canDelete();
    if (!context.mounted) return;
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountDeleteTitle,
      body: l10n.accountDeleteBody,
      note: canDelete
          ? null
          : MxNote(icon: AppIcons.offline, text: l10n.accountDeleteOffline),
      confirmLabel: l10n.accountDelete,
      confirmIcon: AppIcons.delete,
      isDestructive: true,
      canConfirm: canDelete,
    );
    if (!isSure || !context.mounted) return;
    sayAccountResult(context, await controller.deleteAccount());
  }
}
```

If the guard's `no_ref_read_in_build` flags the local `command` helper (it passes `ref`, it does not read), leave it; if it flags anything inside `build`, move that call into a method as P3a did.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account/presentation/account_screen_test.dart test/visual_audit/screens/features/account`
Expected: all pass.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/features/account test/features/account/presentation/account_screen_test.dart test/visual_audit/screens/features/account/screens/account_screen_visual_audit_test.dart
git commit -m "feat(account): screen 32 Account with switch, sign-out and delete (FE-B10)"
```

---

### Task 6: Re-auth on 23 and 13

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/account_settings_section_widget.dart`
- Create: `lib/features/account/presentation/widgets/sections/account_reauth_notice_widget.dart`
- Modify: `lib/features/study/presentation/screens/study_home_screen.dart`
- Modify: every `AccountSettingsSectionWidget(` call site: `lib/app/router/account_routes.dart`, `test/features/account/presentation/account_settings_section_test.dart`, `test/features/account/presentation/account_golden_test.dart`
- Test: `test/features/account/presentation/account_settings_section_test.dart`, `test/features/study/presentation/study_home_screen_test.dart`

**Interfaces:**
- Produces:
  - `AccountSettingsSectionWidget({required VoidCallback onSignIn, required VoidCallback onOpenAccount, required VoidCallback onSignInAgain})`;
  - `AccountReauthNoticeWidget({required VoidCallback onSignIn})`;
  - `StudyHomeScreen(..., Widget? reauthNotice)`.

- [ ] **Step 1: Write the failing tests.**

In `account_settings_section_test.dart`: `section()` becomes

```dart
  Widget section() => Scaffold(
    body: AccountSettingsSectionWidget(
      onSignIn: () => opens++,
      onOpenAccount: () => accounts++,
      onSignInAgain: () => reauths++,
    ),
  );
```

with `late int accounts; late int reauths;` reset to 0 in `setUp`, and two tests added:

```dart
  accountTest('the attached account opens screen 32', (tester, env, world) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: accountOverrides(world),
    );

    await tester.tap(find.text('a@example.com'));
    expect(accounts, 1);
  });

  accountTest('an expired sign-in puts the banner first; Sign in re-auths', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpLibraryScreen(
      tester,
      env,
      section(),
      overrides: [
        ...accountOverrides(world),
        authStateOf(const ReauthRequired(_account)),
      ],
    );

    expect(find.text(_en.accountReauthBanner), findsOneWidget);
    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    expect(reauths, 1);
  });
```

with the `_account` literal of Task 5's test (`AccountUser(id: 'x', email: 'a@example.com', isAnonymous: false, role: AccountRole.user)`) declared at the top of the file.

In `test/features/study/presentation/study_home_screen_test.dart`, add (reuse the file's own pump helper and fixtures for a loaded home):

```dart
  libraryTest('an expired sign-in takes the notice slot over sync', (
    tester,
    env,
  ) async {
    await pumpStudyHome(
      tester,
      env,
      reauthNotice: const Text('reauth'),
      overrides: [authStateOf(const ReauthRequired(_account))],
    );

    expect(find.text('reauth'), findsOneWidget);
  });

  libraryTest('without an expired sign-in, the slot stays empty', (
    tester,
    env,
  ) async {
    await pumpStudyHome(tester, env, reauthNotice: const Text('reauth'));

    expect(find.text('reauth'), findsNothing);
  });
```

where `pumpStudyHome` is whatever that file uses to pump `StudyHomeScreen` (add a `reauthNotice` pass-through to it), and `_account` is the `AccountUser` literal from Task 5.

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/features/account/presentation/account_settings_section_test.dart test/features/study/presentation/study_home_screen_test.dart`
Expected: compile errors for `onOpenAccount`, `onSignInAgain` and `reauthNotice`.

- [ ] **Step 3: Implement.**

`account_reauth_notice_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_floating_notice.dart';

/// An expired sign-in over a screen that does not own it (account UI spec
/// §5.7, R2): Study home, in the sync notice's form.
class AccountReauthNoticeWidget extends StatelessWidget {
  const AccountReauthNoticeWidget({super.key, required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxFloatingNotice(
      message: l10n.accountReauthBanner,
      actions: [
        MxButton(
          label: l10n.accountSignIn,
          size: MxButtonSize.compact,
          onPressed: onSignIn,
        ),
      ],
    );
  }
}
```

`account_settings_section_widget.dart`: the fields `onOpenAccount` ("Opens screen 32 (spec §5.5).") and `onSignInAgain` ("Opens screen 30 in its reauth mode."); the account comes from `ref.watch(deviceAccountProvider)` in place of the local switch; the account row gets `onTap: onOpenAccount` (the chevron follows from `MxSettingsRow`) and loses the "P3b adds the chevron" comment; and the build returns:

```dart
    final section = MxSection(title: l10n.accountSection, children: [row]);
    if (ref.watch(authStateProvider).value is! ReauthRequired) return section;
    // Plan ruling 1: the banner leads the section, above its overline.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccountReauthBannerWidget(onSignIn: onSignInAgain),
        const SizedBox(height: AppSpacing.gutter),
        section,
      ],
    );
```

where `row` is the existing `if (account == null) … else …` choice, moved into a local. Update the class comment: "the account attached, which opens screen 32; an expired sign-in's banner first (P3b)".

`study_home_screen.dart`: add the field

```dart
  /// The account feature's notice for an expired sign-in (account UI spec
  /// §5.7), which `app/` composes; it takes the slot over the sync notice.
  final Widget? reauthNotice;
```

(`this.reauthNotice,` in the constructor, optional), import `package:memox/core/auth/auth_state.dart` and `package:memox/core/auth/di/auth_providers.dart`, and in `build`:

```dart
    final isSignInRefused =
        ref.watch(authStateProvider).value is ReauthRequired;
    ...
      notice: isSignInRefused && reauthNotice != null
          ? reauthNotice
          : showsSync
          ? StudyHomeSyncBannerWidget(status: sync, onOpenSync: onOpenSync)
          : null,
```

Update the call sites: `account_routes.dart`'s `accountSettingsSection` passes `onOpenAccount: () => unawaited(context.push(AppRoutes.settingsAccount))` and `onSignInAgain: () => unawaited(context.push(AppRoutes.settingsSignInReauth(from: AppRoutes.settings)))`; the golden test passes `() {}` for both.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account test/features/study/presentation/study_home_screen_test.dart test/features/settings --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/features lib/app/router/account_routes.dart test/features
git commit -m "feat(account): re-auth banner on Settings and notice on Study home (P3b R2, B5)"
```

---

### Task 7: The sign-in commands learn `reauth`

**Files:**
- Modify: `lib/features/account/presentation/states/sign_in_state.dart`
- Modify: `lib/features/account/presentation/controllers/sign_in_controller.dart`
- Modify: `lib/features/account/presentation/controllers/code_controller.dart`
- Create: `lib/features/account/presentation/providers/can_sign_in_again_provider.dart`
- Modify: `test/support/account_harness.dart`
- Test: `test/features/account/presentation/sign_in_controller_test.dart`, `test/features/account/presentation/code_controller_test.dart`

**Interfaces:**
- Produces:
  - `SignInPurpose.reauth`;
  - `SignInOutcome.unsentChanges` and `SignInState.unsentCount` (`int`, default 0);
  - `SignInController.continueWithGoogle({bool confirmedLoss = false})`, `sendCode(String email, {bool confirmedLoss = false})`;
  - `canSignInAgainProvider` (`bool`: the state is `ReauthRequired`);
  - `Future<void> refuseSession(AuthWorld world)` in the harness: the linked `a@example.com` account's session refused, then `ReauthRequired`.

- [ ] **Step 1: Write the failing tests.**

Harness addition (`account_harness.dart`; import `auth_state.dart` is already there):

```dart
/// [world]'s linked account refused its session: REAUTH_REQUIRED (auth
/// spec #14). Waits on microtasks only, so it runs under a widget test's
/// fake clock too.
Future<void> refuseSession(AuthWorld world) async {
  await linkEmail(world);
  world.gateway.dropSession();
  for (var turn = 0; turn < 1000 && world.state is! ReauthRequired; turn++) {
    await Future<void>.value();
  }
  expect(world.state, isA<ReauthRequired>());
}
```

In `sign_in_controller_test.dart`, a group with its own container on `signInControllerProvider(SignInPurpose.reauth)` after `await refuseSession(world)`:

```dart
  group('reauth', () {
    final reauth = signInControllerProvider(SignInPurpose.reauth);

    setUp(() async {
      await refuseSession(world);
      container.listen(reauth, (_, _) {});
    });

    test('the same address gets its code without a word about loss '
        '(Review Focus 1)', () async {
      expect(
        await container.read(reauth.notifier).sendCode('A@example.com'),
        SignInOutcome.codeSent,
      );
    });

    test('another address with changes unsent asks first', () async {
      expect(
        await container.read(reauth.notifier).sendCode('b@example.com'),
        SignInOutcome.unsentChanges,
      );
      expect(container.read(reauth).unsentCount, 2);
      expect(world.server.sentCodes['b@example.com'], isNull);

      expect(
        await container
            .read(reauth.notifier)
            .sendCode('b@example.com', confirmedLoss: true),
        SignInOutcome.codeSent,
      );
    });

    test('Google as another account asks first too', () async {
      world.gateway.google = const GoogleCredential(
        idToken: 't',
        email: 'g@example.com',
      );
      expect(
        await container.read(reauth.notifier).continueWithGoogle(),
        SignInOutcome.unsentChanges,
      );
      expect(
        await container
            .read(reauth.notifier)
            .continueWithGoogle(confirmedLoss: true),
        SignInOutcome.signedIn,
      );
    });
  });
```

(`readyAnonymous` leaves 2 changes pending; check `world.device.pending` after `linkEmail` if the count differs, and assert on that value.)

In `code_controller_test.dart` (the setup runs on the real clock; only the wait runs under `fakeAsync`, as the file's countdown test does):

```dart
  test('a re-auth resend to another address does not ask again '
      '(plan ruling 8)', () async {
    await refuseSession(world);
    await world.coordinator.requestCode('b@example.com', confirmedLoss: true);
    final reauth = codeControllerProvider(
      'b@example.com',
      SignInPurpose.reauth,
    );

    fakeAsync((async) {
      final container = ProviderContainer(overrides: accountOverrides(world));
      container.listen(reauth, (_, _) {});
      async.elapse(CodeController.resendWait);

      bool? isSent;
      unawaited(
        container.read(reauth.notifier).resend().then((sent) => isSent = sent),
      );
      async.elapse(const Duration(seconds: 1));

      expect(isSent, isTrue);
      container.dispose();
    });
  });
```

(`import 'dart:async';` for `unawaited`.) Without Task 7's change the resend throws `UnsentChangesFailure` and `isSent` is false: that is the red.

A provider test in the same file as Task 2's `device_account_provider_test.dart` is not needed: `canSignInAgainProvider` is covered by Task 8's screen test.

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/features/account/presentation/sign_in_controller_test.dart test/features/account/presentation/code_controller_test.dart`
Expected: compile errors for `SignInPurpose.reauth`, `unsentChanges`, `unsentCount`, `confirmedLoss` and `refuseSession`.

- [ ] **Step 3: Implement.**

`sign_in_state.dart`:
- `enum SignInPurpose { link, target, reauth }`, and the enum's comment gains "or signing in again after the session was refused (P3b)";
- in `SignInOutcome`, after `identityTaken`:

```dart
  /// Signing in to another account would lose [SignInState.unsentCount]
  /// changes; asked again with the loss confirmed (auth spec ruling 6).
  unsentChanges,
```

- `SignInState` gains `this.unsentCount = 0` and

```dart
  /// The changes a re-auth to another account would lose.
  final int unsentCount;
```

`sign_in_controller.dart`:

```dart
  Future<SignInOutcome> continueWithGoogle({bool confirmedLoss = false}) => _run(
    SignInTask.google,
    (accounts) => accounts.continueWithGoogle(confirmedLoss: confirmedLoss),
  );

  Future<SignInOutcome> sendCode(
    String email, {
    bool confirmedLoss = false,
  }) async {
    ...
    return _run(
      SignInTask.email,
      (accounts) => accounts.requestCode(address, confirmedLoss: confirmedLoss),
      done: SignInOutcome.codeSent,
    );
  }
```

and in `_run`, a local `var unsent = 0;`, a new arm before `on Failure`:

```dart
    } on UnsentChangesFailure catch (error) {
      unsent = error.count;
      outcome = SignInOutcome.unsentChanges;
```

and the final state `SignInState(problem: problem, problemTask: problem == null ? null : task, unsentCount: unsent)`.

`code_controller.dart`, `resend`:

```dart
      // Plan ruling 8: a re-auth's first code went out only once any loss
      // was accepted on screen 30; a resend does not ask again.
      await accounts.requestCode(
        email,
        confirmedLoss: purpose == SignInPurpose.reauth,
      );
```

`can_sign_in_again_provider.dart`:

```dart
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'can_sign_in_again_provider.g.dart';

/// Whether screen 30's reauth form can act: P2 takes a re-auth only while
/// the session is refused (auth spec #36, #37).
@riverpod
bool canSignInAgain(Ref ref) =>
    ref.watch(authStateProvider).value is ReauthRequired;
```

Run build_runner. The form's `switch` on `SignInOutcome` (Task 8 extends it) must stay exhaustive: add `case SignInOutcome.unsentChanges: return;` to `sign_in_form_widget.dart`'s `_follow` now, so this task compiles; Task 8 replaces it.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/features/account test/support/account_harness.dart test/features/account/presentation
git commit -m "feat(account): sign-in and code commands for re-auth with the unsent loss (P3b B8)"
```

---

### Task 8: Screens 30 and 31 in `reauth`

**Files:**
- Modify: `lib/features/account/presentation/widgets/sections/sign_in_form_widget.dart`
- Modify: `lib/features/account/presentation/screens/sign_in_screen.dart`
- Modify: `lib/features/account/presentation/screens/code_screen.dart`
- Test: `test/features/account/presentation/sign_in_screen_test.dart`, `test/features/account/presentation/code_screen_test.dart`

**Interfaces:**
- Consumes: Tasks 3, 4, 7.
- Produces:
  - `SignInScreen({required ValueChanged<String> onCodeSent, required VoidCallback onSignedIn, SignInPurpose purpose = SignInPurpose.link, VoidCallback? onLeftAccount})`;
  - `CodeScreen({required String email, required VoidCallback onSignedIn, SignInPurpose purpose = SignInPurpose.link})`.

- [ ] **Step 1: Write the failing tests** in `sign_in_screen_test.dart` (a `reauth` group; `left` counts `onLeftAccount`):

```dart
  group('reauth', () {
    late int left;

    setUp(() => left = 0);

    SignInScreen reauth() => SignInScreen(
      purpose: SignInPurpose.reauth,
      onCodeSent: codesSent.add,
      onSignedIn: () => signIns++,
      onLeftAccount: () => left++,
    );

    accountTest('the reauth line, and the last address filled in', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      expect(find.text(_en.accountReauthLine), findsOneWidget);
      expect(find.text('a@example.com'), findsOneWidget);
      expect(_button(tester, _en.accountSendCode).onPressed, isNotNull);
    });

    accountTest('another address with changes unsent asks, then sends', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      await tester.enterText(find.byType(TextField), 'b@example.com');
      await tester.tap(find.text(_en.accountSendCode));
      await _settle(tester);
      expect(find.text(_en.accountUnsentTitle(2)), findsOneWidget);

      await tester.tap(find.widgetWithText(MxButton, _en.accountContinue));
      await _settle(tester);
      expect(codesSent, ['b@example.com']);
    });

    accountTest('Continue without an account asks, then leaves the account', (
      tester,
      env,
      world,
    ) async {
      await refuseSession(world);
      await pumpLibraryScreen(
        tester,
        env,
        reauth(),
        overrides: accountOverrides(world),
      );

      await tester.tap(find.text(_en.accountContinueWithout));
      await _settle(tester);
      expect(find.text(_en.accountWithoutBody('a@example.com')), findsOneWidget);
      await tester.tap(
        find.widgetWithText(MxButton, _en.accountContinueWithout),
      );
      await _settle(tester);

      expect(left, 1);
      expect(world.state, isNot(isA<ReauthRequired>()));
    });
  });
```

In `code_screen_test.dart`:

```dart
  accountTest('a re-auth code signs in again', (tester, env, world) async {
    await refuseSession(world);
    await world.coordinator.requestCode('a@example.com');
    var signedIn = 0;
    await pumpLibraryScreen(
      tester,
      env,
      CodeScreen(
        email: 'a@example.com',
        purpose: SignInPurpose.reauth,
        onSignedIn: () => signedIn++,
      ),
      overrides: accountOverrides(world),
    );

    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(signedIn, 1);
    expect(world.state, isA<Ready>());
  });
```

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/features/account/presentation/sign_in_screen_test.dart test/features/account/presentation/code_screen_test.dart`
Expected: compile errors for `purpose` and `onLeftAccount`.

- [ ] **Step 3: Implement.**

`sign_in_form_widget.dart`:
- the mode line:

```dart
        Text(
          switch (widget.purpose) {
            SignInPurpose.link => l10n.accountLinkLine,
            SignInPurpose.target => l10n.accountTargetLine,
            SignInPurpose.reauth => l10n.accountReauthLine,
          },
          style: context.textStyles.emptyBody,
        ),
```

- `_google` and `_send` take `{bool confirmedLoss = false}` and pass it to the controller;
- `_follow`'s new arm replaces Task 7's placeholder:

```dart
      case SignInOutcome.unsentChanges:
        await _confirmLoss(isGoogle: email == null);
```

- and the method:

```dart
  /// Auth spec ruling 6: another account replaces this phone's data, so the
  /// unsent changes are named before the command runs again.
  Future<void> _confirmLoss({required bool isGoogle}) async {
    final count = ref.read(signInControllerProvider(widget.purpose)).unsentCount;
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountUnsentTitle(count),
      body: l10n.accountUnsentBody(count),
      confirmLabel: l10n.accountContinue,
      isDestructive: true,
    );
    if (!isSure || !mounted) return;
    if (isGoogle) return _google(confirmedLoss: true);
    return _send(confirmedLoss: true);
  }
```

`sign_in_screen.dart`:
- fields `purpose` ("link attaches this user's first account; reauth signs in again (spec §5.2)") and `onLeftAccount` ("Continued without an account: the flow closes (spec §9 B8).");
- in `build`: `final isReauth = purpose == SignInPurpose.reauth;` and `final canAct = isReauth ? ref.watch(canSignInAgainProvider) : ref.watch(canLinkProvider);`; the offline note stays for the link only (`if (!isReauth && !canAct)`);
- the form gets `purpose: purpose`, `isEnabled: canAct` and `initialEmail: isReauth ? ref.watch(deviceAccountProvider)?.email : null`;
- after the form, for `reauth` only:

```dart
          if (isReauth) ...[
            const SizedBox(height: AppSpacing.section),
            MxButton(
              label: l10n.accountContinueWithout,
              tone: MxButtonTone.text,
              isBlock: true,
              onPressed: canAct ? () => unawaited(_leave(context, ref)) : null,
            ),
          ],
```

- and the method:

```dart
  /// Gives up the refused account (auth spec #38) once the loss is
  /// confirmed; the layer shows the clearing (spec §9 B8).
  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(accountManageControllerProvider.notifier);
    final email = ref.read(deviceAccountProvider)?.email ?? '';
    final l10n = context.l10n;
    final isSure = await confirmAccountStep(
      context,
      title: l10n.accountWithoutTitle,
      body: l10n.accountWithoutBody(email),
      confirmLabel: l10n.accountContinueWithout,
      isDestructive: true,
    );
    if (!isSure || !context.mounted) return;
    final result = await controller.continueWithoutAccount();
    if (!context.mounted) return;
    if (result == AccountCommandResult.done) return onLeftAccount?.call();
    sayAccountResult(context, result);
  }
```

The class comment becomes "Screen 30 (account UI spec §5.2): attach Google or an email to this device's anonymous user (`link`), or sign in again after the session was refused (`reauth`), which may also continue without an account."

`code_screen.dart`: the field `purpose` (default `link`) goes to `CodeFormWidget(purpose: purpose, …)`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/features/account --exclude-tags golden`
Expected: all pass.

- [ ] **Step 5: Gate and commit**

```bash
git add lib/features/account test/features/account/presentation
git commit -m "feat(account): screen 30 and 31 in reauth mode, continue without an account (P3b B8)"
```

---

### Task 9: `app/` wiring — routes, redirect and slots

**Files:**
- Modify: `lib/app/router/account_routes.dart`
- Modify: `lib/app/router/account_redirect.dart`
- Modify: `lib/app/router/app_router.dart` (two lines)
- Modify: `lib/app/app.dart`
- Test: `test/app/account_redirect_test.dart`, `test/app/account_routes_test.dart`

**Interfaces:**
- Consumes: every earlier task.
- Produces:
  - `String? accountRedirect(Uri location, {required bool isWelcomeDue, required AuthState? account})`;
  - `GoRoute accountRoute(GlobalKey<NavigatorState> rootNavigator)`;
  - `Widget accountReauthNotice(BuildContext context)`.

- [ ] **Step 1: Write the failing tests.**

`account_redirect_test.dart`: the helper takes `AuthState? account` in place of `hasAccount` (`const _anon = Ready(AccountUser(id: 'n', isAnonymous: true, role: AccountRole.user))`, `const _signedIn = Ready(AccountUser(id: 'x', email: 'a@example.com', isAnonymous: false, role: AccountRole.user))`); the existing tests use `_anon` for "no account" and `_signedIn` for "an account", and the attach test now expects `AppRoutes.settingsAccount`. Add:

```dart
  test('screen 32 needs an account; a transition keeps it (Review Focus 3)',
      () {
    expect(redirect(AppRoutes.settingsAccount, account: _anon),
        AppRoutes.settings);
    expect(redirect(AppRoutes.settingsAccount, account: const LocalOnly()),
        AppRoutes.settings);
    expect(redirect(AppRoutes.settingsAccount, account: _signedIn), isNull);
    expect(
      redirect(
        AppRoutes.settingsAccount,
        account: Transitioning(
          transitionOf(TransitionKind.delete, TransitionStage.started),
        ),
      ),
      isNull,
    );
    expect(redirect(AppRoutes.settingsAccount, account: const Booting()),
        isNull);
  });
```

`account_routes_test.dart`: the existing "flow ends on Settings showing the account" test now expects `AccountScreen` (rename it "… ends on screen 32"). Add:

```dart
  accountTest('Settings › the account row opens screen 32; Back returns', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settings);
    await tester.pumpAndSettle();

    await tester.tap(find.text('a@example.com'));
    await tester.pumpAndSettle();
    expect(find.byType(AccountScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  accountTest('a re-auth from Study home returns to Study home', (
    tester,
    env,
    world,
  ) async {
    await refuseSession(world);
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.study);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(MxButton, _en.accountSignIn));
    await tester.pumpAndSettle();
    expect(find.byType(SignInScreen), findsOneWidget);
    await tester.tap(find.text(_en.accountSendCode)); // the address is filled in
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), FakeAuthGateway.code);
    await tester.pumpAndSettle();

    expect(
      _router(tester).routeInformationProvider.value.uri.path,
      AppRoutes.study,
    );
    expect(world.state, isA<Ready>());
  });

  accountTest('signing out from screen 32 lands on Settings', (
    tester,
    env,
    world,
  ) async {
    await linkEmail(world);
    world.device.pending = 0;
    await pumpMemoxApp(tester, env, overrides: accountOverrides(world));
    _router(tester).go(AppRoutes.settingsAccount);
    await tester.pumpAndSettle();

    await tester.tap(find.text(_en.accountSignOut));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MxButton, _en.accountSignOut));
    await tester.pumpAndSettle();

    expect(find.byType(AccountScreen), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
```

(If `pumpMemoxApp` does not route to Study for a refused session because Study home needs data, seed a deck with `env.decks.root('Korean')` first.)

- [ ] **Step 2: Run to see them fail**

Run: `flutter test test/app/account_redirect_test.dart test/app/account_routes_test.dart`
Expected: compile errors for `account:`; route tests fail (no `AccountScreen` route).

- [ ] **Step 3: Implement.**

`account_redirect.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:memox/app/router/app_routes.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/features/account/presentation/providers/device_account_provider.dart';

/// The router's account rules (account UI spec §4, §9 B9). Signing in
/// stays optional, so nothing else redirects:
/// - Welcome until it is answered, keeping the location asked for;
/// - no attach flow once the device holds an account: screen 32 instead;
/// - no screen 32 on a plainly anonymous device (plan ruling 4). During a
///   start or a transition nothing moves.
String? accountRedirect(
  Uri location, {
  required bool isWelcomeDue,
  required AuthState? account,
}) {
  if (isWelcomeDue && location.path != AppRoutes.welcome) {
    return AppRoutes.welcomeFrom(location.toString());
  }
  final mode =
      location.queryParameters[AppRoutes.accountModeParam] ??
      AppRoutes.accountLinkMode;
  final isAttach =
      location.path.startsWith(AppRoutes.settingsSignIn) &&
      mode == AppRoutes.accountLinkMode;
  if (isAttach && deviceAccountOf(account) != null) {
    return AppRoutes.settingsAccount;
  }
  if (location.path == AppRoutes.settingsAccount && _isAnonymous(account)) {
    return AppRoutes.settings;
  }
  return null;
}

bool _isAnonymous(AuthState? account) => switch (account) {
  Ready(:final user) => user.isAnonymous,
  Validating(:final last) => last == null || last.isAnonymous,
  LocalOnly() || Bootstrapping() => true,
  _ => false,
};
```

(If the architecture check forbids `app/router` importing a feature's `presentation/providers`, keep `deviceAccountOf` where it is and import it the way `account_routes.dart` already imports account screens: `app/` may import features.)

`account_routes.dart`:
- `signInRoute` builds both screens from a `_SignInFlow`:

```dart
/// Where a sign-in flow began and ends (spec §9 B9): the link ends on
/// screen 32; a re-auth returns to where it was opened.
final class _SignInFlow {
  const _SignInFlow(this.purpose, this.from);

  factory _SignInFlow.of(Uri uri) {
    final query = uri.queryParameters;
    final isReauth =
        query[AppRoutes.accountModeParam] == AppRoutes.accountReauthMode;
    return _SignInFlow(
      isReauth ? SignInPurpose.reauth : SignInPurpose.link,
      query[AppRoutes.accountFromParam] ?? AppRoutes.settings,
    );
  }

  final SignInPurpose purpose;
  final String from;

  String get end =>
      purpose == SignInPurpose.reauth ? from : AppRoutes.settingsAccount;

  String codeLocation(String email) => purpose == SignInPurpose.reauth
      ? AppRoutes.settingsSignInCodeReauth(email, from: from)
      : AppRoutes.settingsSignInCodeLink(email);
}
```

```dart
GoRoute signInRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsSignInChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) {
    final flow = _SignInFlow.of(state.uri);
    return SignInScreen(
      purpose: flow.purpose,
      onCodeSent: (email) =>
          unawaited(context.push(flow.codeLocation(email))),
      onSignedIn: () => context.go(flow.end),
      onLeftAccount: () => context.go(flow.end),
    );
  },
  routes: [
    GoRoute(
      path: AppRoutes.settingsSignInCodeChild,
      parentNavigatorKey: rootNavigator,
      builder: (context, state) {
        final flow = _SignInFlow.of(state.uri);
        return CodeScreen(
          email: state.uri.queryParameters[AppRoutes.accountEmailParam] ?? '',
          purpose: flow.purpose,
          onSignedIn: () => context.go(flow.end),
        );
      },
    ),
  ],
);

/// Screen 32 (spec §5.6) under Settings, on the root navigator.
GoRoute accountRoute(GlobalKey<NavigatorState> rootNavigator) => GoRoute(
  path: AppRoutes.settingsAccountChild,
  parentNavigatorKey: rootNavigator,
  builder: (context, state) => AccountScreen(
    onSignInAgain: () => unawaited(
      context.push(
        AppRoutes.settingsSignInReauth(from: AppRoutes.settingsAccount),
      ),
    ),
  ),
);

/// Study home's notice for an expired sign-in (spec §5.7). Screen 30 opens
/// under Settings, as the sync notice's Details does (plan ruling 3).
Widget accountReauthNotice(BuildContext context) => AccountReauthNoticeWidget(
  onSignIn: () =>
      context.go(AppRoutes.settingsSignInReauth(from: AppRoutes.study)),
);
```

Update the file's comment on `signInRoute` ("The flow ends on Settings (plan ruling 2)" → "The link ends on screen 32, a re-auth where it began (P3b B9)").

`app_router.dart`: `accountRoute(rootNavigator),` after `signInRoute(rootNavigator),`, and `reauthNotice: accountReauthNotice(context),` in `StudyHomeScreen(`.

`app.dart`:
- the redirect passes `account: ref.read(accountCoordinatorProvider)?.state ?? const LocalOnly(),` (plan ruling 4) in place of `hasAccount:`;
- the second `listenManual` listens to `authStateProvider` (every account change may change a rule) in place of `currentAccountProvider`.

- [ ] **Step 4: Run the tests**

Run: `flutter test test/app --exclude-tags golden`
Expected: all pass. If the Study home re-auth test lands on Settings, check that the code route's `from` survived: `state.uri` on the code page must carry it (`settingsSignInCodeReauth`).

- [ ] **Step 5: Gate and commit**

```bash
git add lib/app test/app
git commit -m "feat(app): screen 32 route, re-auth flows that return where they began (P3b B9)"
```

---

### Task 10: Goldens

**Files:**
- Create: `test/features/account/presentation/account_manage_golden_test.dart`
- Create: `test/features/account/presentation/goldens/*.png` (30 files)

- [ ] **Step 1: Prove parity first.** Run: `TZ=UTC flutter test --tags golden test/features/account test/features/settings test/features/study`. Expected: all pass untouched (nothing in Tasks 1–9 changes an existing golden; if `settings_account_*` changed, it is the chevron-less anonymous row and must not have).

- [ ] **Step 2: Write** `account_manage_golden_test.dart`, in `account_golden_test.dart`'s form (copy its `capture`, `_settle`, `_rest`; `withRealShadows`, `pumpLibraryGolden`, `expectBoundaryGolden`, `precacheGoogleMark` for 30). For each brightness:

| Golden | What | Setup |
|---|---|---|
| `account_ready` | `AccountScreen` | `await linkEmail(world)` |
| `account_validating` | `AccountScreen` | `authStateOf(const Validating(_account))` |
| `account_reauth` | `AccountScreen` | `authStateOf(const ReauthRequired(_account))` |
| `account_switch_confirm` | the switch dialog | linked; tap `accountSwitch`, settle, rest |
| `account_sign_out_confirm` | the online sign-out dialog | linked; tap `accountSignOut` |
| `account_sign_out_loss` | the loss dialog | linked, `world.network.goOffline()`; tap `accountSignOut` |
| `account_delete_confirm` | the delete dialog | linked; tap `accountDelete` |
| `account_delete_offline` | delete, offline | linked, offline; tap `accountDelete` |
| `account_last_admin` | the last-admin dialog | a host button calling `showLastAdminDialog` |
| `settings_account_signed_in` | 23 with the account row's chevron | `SettingsScreen` with the section (as `settings_account`), linked |
| `settings_account_reauth` | 23 with the banner | the same, `authStateOf(const ReauthRequired(_account))` |
| `study_home_reauth` | 13 with the notice | `StudyHomeScreen` with `reauthNotice: AccountReauthNoticeWidget(onSignIn: () {})`, a root deck with due cards (the study golden's fixture), `authStateOf(const ReauthRequired(_account))` |
| `sign_in_reauth` | 30 in `reauth` | `await refuseSession(world)`; `hasMark: true` |
| `sign_in_unsent_loss` | its loss dialog | refused; enter `b@example.com`, tap Send code, settle, rest; `hasMark: true` |
| `sign_in_continue_without` | its confirm | refused; tap `accountContinueWithout`; `hasMark: true` |

- [ ] **Step 3: Render.** Run: `TZ=UTC flutter test --tags golden test/features/account/presentation/account_manage_golden_test.dart --update-goldens`, then look at every PNG (Read tool): the One Indigo Rule (one primary fill per dialog), the destructive confirms red, the disabled delete confirm at 0.38, the banner above the ACCOUNT overline (plan ruling 1), the notice floating over 13's content, nothing clipped.

- [ ] **Step 4: Run all goldens.** Run: `TZ=UTC flutter test --tags golden`. Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add test/features/account/presentation/account_manage_golden_test.dart test/features/account/presentation/goldens
git commit -m "test(account): P3b goldens — screen 32, dialogs, re-auth on 23, 13 and 30"
```

---

### Task 11: Docs

**Files:**
- Create: `docs/shared/ui/screen-handoff/32-account.md`
- Modify: `docs/shared/ui/screen-handoff/30-sign-in.md`, `23-settings.md`, `13-study-home.md`, `00-index.md`
- Modify: `docs/wbs_FE.md` (FE-B10), `docs/wbs_supabase.md` (SB-A5's app side)
- Modify: `docs/superpowers/specs/2026-09-30-account-ui-design.md` (status, §9.1 per plan rulings 1–2)
- Modify: the UI-base register (§9 of `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md`)

- [ ] **Step 1: `32-account.md`** in `31-code.md`'s shape (the `<!-- Hand-written screen record. -->` line, title and lead, Entry points, Layout, States with the golden table of Task 10's `account_*` rows, Rulings, Copy): entry from 23's account row; the three sections; `Ready`, `Validating`, `ReauthRequired`; the five dialogs and the last-admin dialog; rulings B1–B7, B12 and plan rulings 1, 2, 5–7, 9.
- [ ] **Step 2: Update 30** (`reauth` mode: line, filled address, the loss dialog, Continue without; goldens `sign_in_reauth`, `sign_in_unsent_loss`, `sign_in_continue_without`; B8, B9, plan rulings 3, 8, 10; remove the "reauth renders the link form" note if it is there), **23** (the chevron to 32, the banner above the section; goldens `settings_account_signed_in`, `settings_account_reauth`; plan ruling 1), **13** (the re-auth notice takes the slot over sync; golden `study_home_reauth`; B5).
- [ ] **Step 3: The index** gets row 32 (Account, FE-B10, built) and the status of 30, 23 and 13 follow; `wbs_FE.md` marks FE-B10 done with this plan's path; `wbs_supabase.md` SB-A5 notes the in-app deletion is built (P3b) and what stays (the device check after SB-A4).
- [ ] **Step 4: The spec**: the status line adds "P3b implemented by `docs/superpowers/plans/2026-09-30-account-ui-manage.md`"; §9.1 says the banner leads the section above its overline and the email wraps (plan rulings 1, 2).
- [ ] **Step 5: The UI-base register** gains one row: "`MxSection` has no slot between overline and card; the re-auth banner sits above the section (P3b plan ruling 1)". `DESIGN.md` does not change: P3b adds no shared widget, token or tone (check `git diff --stat` shows no `lib/shared` change).
- [ ] **Step 6: Commit**

```bash
git add docs
git commit -m "docs(account): screen 32 and re-auth in the handoff files, index and WBS (FE-B10)"
```

---

### Task 12: The whole suite

- [ ] **Step 1:** Run the full gate (format, analyze, architecture, guard) and `flutter test --exclude-tags golden` in the background to a file in the workspace; read its tail.
- [ ] **Step 2:** Run `TZ=UTC flutter test --tags golden` the same way.
- [ ] **Step 3:** Expected: both green. A failure is fixed in the task that owns the code (systematic-debugging), with its own commit; the ledger names it.
