# Core auth (P2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The app owns its account in one place, `AccountCoordinator` in `lib/core/auth/`. It starts, validates and recovers the anonymous user, and it runs the account switch, sign-out, deletion and clear-to-anonymous flows of spec §3.3 rows #1–#45 with crash-safe persisted state. Sync runs only in `Ready`, and the admin check reads `me()`.

**Architecture:**
- **Coordinator.** `AccountCoordinator` is a serial state machine over six ports:
  - `AuthGateway` (GoTrue + `google_sign_in`);
  - `AccountApi` (the P1 RPCs);
  - `AccountStore` (Drift);
  - `SecretStore` (Secure Storage);
  - `SyncControl` (pause, resume, push, pull, full push);
  - `LocalDataReset`.
- **Gate and state.** It closes a `MutationGate` that every business write passes through (`mappedTransaction`), and it publishes a sealed `AuthState`. Providers expose `authStateProvider`, `currentAccountProvider` and `isAdminProvider`, and `main()` prepares and starts it.
- **Supabase boundary.** Only `lib/core/auth/supabase_*.dart`, `lib/core/auth/google_*.dart`, `lib/core/auth/secure_*.dart`, `lib/core/sync/supabase_sync_api.dart` and `lib/core/network/` import `supabase_flutter`, `google_sign_in` or `flutter_secure_storage` (Task 14 enforces it).
- **Scope of P2.** No screen. P3 builds the UI on the coordinator's commands.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3 (codegen), Drift 2.35, supabase_flutter 2.17.2 (gotrue 2.27.2), google_sign_in 7.x, flutter_secure_storage 11.x, connectivity_plus 7, fake_async.

**Spec:** `docs/superpowers/specs/2026-09-30-auth-design.md`. It is the binding authority: §3 (state machine, 45 rows, invariants), §4 (persisted state), §5 (boundary), §6 (algorithms), §9 (tests) and §11 row P2. P1 (server) is merged and deployed as `supabase/migrations/20261010000000_accounts.sql` (PR #164).

## Global Constraints

- The app's account types are `AccountUser`, `AuthState`, `AccountTransition` and the `AuthFailure` family. No `User`, `Session`, `AuthResponse`, `PostgrestException` or `AuthException` appears outside `lib/core/auth/supabase_*.dart`, `lib/core/network/` and `lib/core/sync/supabase_sync_api.dart` (spec §5).
- **R1:** start and recovery read `currentUserId` from the SDK first. The transition record holds intent, never session truth.
- **R2:** sync resumes only on `Ready`, after `me()` succeeds.
- **R3:** during Switch, SignOut, Delete and ClearToAnon, every business write fails with `MutationBlockedFailure`. Nothing is pushed after the SDK's user differs from the record's source (spec §3.1).
- **Offline is a condition, never a state:** it never signs out and never clears data (spec §3.1).
- **Where state is kept (spec §4):**
  - Drift holds `account_state` (one row) and `account_transition` (0–1 row), and gains the `app_settings.welcome_seen` column.
  - The A-session backup and the claim token live in Secure Storage under `account.backup.<op>` and `account.claim.<op>`.
  - Google tokens and typed codes live in memory only.
- **Logs:** no token, refresh token, claim token or OTP code is ever written to Drift or passed to `appLogger`. ADR-018 redacts nothing, so these values must never reach it.
- **Failures:** ADR-016. A `Failure` is thrown and carries no display text. Copy comes from `l10n.failure(failure)`, and every new `Failure` gets an arm in `lib/l10n/failure_message.dart`, in both `en` and `vi`.
- **Drift:** a shipped migration step never changes. The new step is `from10To11`. `drift_schemas/drift_schema_v11.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema_v11.dart` and `schema.dart` are regenerated with the commands in `.claude/skills/flutter-drift/references/migrations.md` and committed.
- **Code generation:** providers use `@Riverpod(keepAlive: true)` codegen, and `.g.dart` files are committed (`dart run build_runner build --delete-conflicting-outputs`).
- **Task gate:** `dart format --output=none --set-exit-if-changed lib test`, `flutter analyze`, and `flutter test --exclude-tags golden` for the task's files. The whole suite runs at the last task. No golden changes in P2.
- **Commits:** end each message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2`. No model id appears anywhere else.
- **Language:** code, comments and commit messages are in English. Messages in `tools/` stay in English.

## Rulings made while planning

1. **Reuse of existing failures.** Spec §5's `AuthFailure.Network` is the existing `OfflineFailure`, and `Forbidden` is the existing `NotAdminFailure`. Both are thrown by the new code, and there are no duplicate types.
2. **`CodeExpired` is not a type.** GoTrue answers both a wrong and an expired OTP with `otp_expired`, so the classifier maps it to `InvalidCodeFailure`. P3 decides whether its copy says "wrong or expired" (no speculative type).
3. **Notices.** One-off outcomes that are not states go out on `AccountCoordinator.notices`, a stream of `AccountNotice`: "Couldn't merge" (#25) and a refused deletion (#44, carrying the failure). The states stay pure.
4. **The A backup is written just before the target sign-in, not at #20.** The SDK rotates refresh tokens on every refresh. A backup taken at claim time can be revoked by the time #25 or #33 restores it, because GoTrue's reuse detection revokes the whole family. The claim token is still written at #20. The cost of this order is none, because before the target sign-in the SDK still holds A (R1 → #31).
5. **The source is never signed out during a switch.** `signOut` revokes the session on the server, while `setSession` needs A's refresh token alive. Signing in to B replaces the SDK session without revoking A.
6. **Reauth with another account.**
   - The loss confirmation of #37 happens before the sign-in: `requestCode` and `continueWithGoogle` in the reauth context throw `UnsentChangesFailure(count)` when the email differs from the last account's and the outbox is not empty, unless the call carries `confirmedLoss: true`.
   - The record is written right after the sign-in. The same guard, and the start-up guard of ruling 7, cover the kill window.
7. **Start-up guard.** With no record, if the SDK's user differs from `lastKnownAccount`, the local data belongs to another account. The coordinator records Switch{discard, source = last, target = SDK user, stage `targetSignedIn`} and continues at #27 (reset and pull). The ways this could lose unsent writes are closed by saving a provisional `lastKnown` before each record is dropped (#12, #30, #41). DEV-189 hardens it: with the outbox not empty, nothing is reset; the state is REAUTH_REQUIRED(last) with the log `auth.account_mismatch_unsent`, so the loss is confirmed at #37 or taken at #38, never silently.
8. **An unusable A backup at #25.** When restoring A fails with `SessionInvalidFailure`, the coordinator signs B out locally, drops the switch and starts AnonRecovery: a new anonymous user, and the full local library is pushed. No data is lost. A's server rows are left for the 90-day cleanup.
9. **`cancelSwitch()`** is allowed while the stage is below `targetSignedIn`. With the SDK on A it returns to A (#22). With no session it treats the source as lost (`_lost(sessionInvalid: true)`: AnonRecovery for an anonymous source, ReauthRequired for an account).
10. **Sign-out without waiting for sync.** The spec's "loss accepted offline" is `choice = discard` on the SignOut record. Push is always tried, and a network failure then continues.
11. **Scheduler pause and resume.**
    - `SyncScheduler` gains `pause()`, `resume()` and `start({bool paused})`. `pause()` waits for a run in progress, and while paused, triggers, reconnects and `syncNow()` (which answers false) do nothing.
    - The sync scheduler starts paused, and the coordinator resumes it on `Ready`.
    - `SupabaseSyncApi` stops signing in: it becomes existing-session-only, like the log.
12. **`markAllPending`.** It queues every local row of every synced type in the migration's parents-first order, plus the settings row, with `ON CONFLICT DO NOTHING`, and sets `since = 0`. `app_database.dart`'s `_seedOutbox` becomes the public `seedOutboxSql`. The shipped steps' SQL is unchanged.
13. **`LocalDataReset` order.**
    - The reset sets `applying_remote` so the capture triggers stay silent.
    - It deletes `card`, then `deck`, `delete_batches` and `tags`; schedules, links, reviews and study rows go by cascade.
    - It resets the four synced settings columns while the flag is still set, then deletes the `sync_state` keys (all but `device_id`), `sync_outbox` and `sync_rejection`.
    - `device_id` identifies the device, not the account, so it stays.
14. **The mutation gate.** It lives on `AppDatabase` (`mutationGate`), and `mappedTransaction` checks it. The starter library's one write that opened its own `guardDatabase(() => _db.transaction(...))` moves to `mappedTransaction`. `recordReminderDelivered` stays ungated: it writes a device-only column that the reset keeps.
15. **Logging.** Account events log as `auth.<event>` under `LogCategory.state`. No new category, since that would also need a server migration of `app_log`'s category check.
16. **Test style.** Gateway and API tests call the ports' real classes over closures and a GoTrue `MockClient`, following the existing `supabase_sync_api_test.dart`, instead of wrapping the whole Supabase client.
17. **`GoogleCredentialSource`.** It wraps a platform plugin, so it has no unit test here. The device check that closes P3 covers it (spec §9, "Device").
18. **One-door rule for secure storage.** `flutter_secure_storage` gets the same one-door rule as `supabase_flutter`, confined to `lib/core/auth/secure_*.dart`.
19. **Where the rule lives.**
    - The import rule is a pure architecture test (`test/architecture/sdk_door_test.dart`) and a guard rule, following `memox_v8.architecture.unicode_normalisation_has_one_door`.
    - It is not added to `check_architecture.py` as well: the guard is the repo's home for one-door rules, and a third copy would drift.
20. **No Supabase project.** A build with no Supabase project builds no coordinator. `authStateProvider` is then `LocalOnly`, `isAdmin` is false, the gate stays open, and nothing else changes.

## Review Focus

1. **The SDK drops the session on its own.**
   - Situation: a refresh token is refused while the app is open, so GoTrue removes the session and emits `signedOut`.
   - Expected: `Ready` or `Validating` must go to AnonRecovery for an anonymous user and to `REAUTH_REQUIRED` for an account. It must not remain `Ready` with sync resumed on no session.
   - Test in Task 10: `Review Focus 1: a session the SDK drops while ready …`.
2. **A reconnect while the switch waits for the target sign-in.**
   - Situation: the network returns while the blocking layer asks for the target account.
   - Expected: the flow must not cancel the switch, which is what the #31 rule would do on a cold start.
   - Test in Task 11: `Review Focus 2: a reconnect while the target sign-in is asked keeps the switch`.
3. **A second tap.**
   - Situation: the user taps twice, or a command arrives while a flow is running (the connectivity listener firing mid-merge).
   - Expected: commands are serialized, and a second `beginSwitch` while a record exists is refused (`StateError`), not doubled.
   - Test in Task 11: `Review Focus 3: commands run one at a time; a second switch is refused`.
4. **Everything already pushed, then a kill.**
   - Situation: the outbox is empty, and the app is killed between `markAllPending` and clearing the AnonRecovery record.
   - Expected: the rerun must not queue twice (`ON CONFLICT DO NOTHING`) and must not create a second anonymous user.
   - Test: Task 7's `markAllPending` test and Task 13's anonymous-recovery sweep.
5. **A write the gate stops mid-transition.**
   - Situation: a feature write started by a timer, such as `_closeStaleSessions` on resume, runs during Switch.
   - Expected: it fails with `MutationBlockedFailure` and writes nothing. Pull and reset still write.
   - Test in Task 5.

---

## File map

| File | Responsibility | Task |
|---|---|---|
| `lib/core/network/supabase_client.dart` | the one door to `Supabase.instance`: initialize, RPC call, has-session | 1 |
| `lib/core/network/remote_error.dart` | network / sign-in / server classification of a transport error; the RPC error code | 1 |
| `lib/core/database/tables/account.drift` | `account_state`, `account_transition` | 2 |
| `lib/core/database/tables/settings.drift` | + `welcome_seen` | 2 |
| `lib/core/auth/account_user.dart` | `AccountUser`, `AccountRole` | 3 |
| `lib/core/auth/account_transition.dart` | `AccountTransition`, `TransitionKind`, `TransitionChoice`, `TransitionStage` | 3 |
| `lib/core/auth/auth_state.dart` | sealed `AuthState`, `AccountNotice` | 3 |
| `lib/core/error/failure.dart` | + sealed `AuthFailure` and its variants, `MutationBlockedFailure`, `IdentityMethod` | 3 |
| `lib/core/auth/account_store.dart` | Drift store of `lastKnownAccount` and the record | 4 |
| `lib/core/auth/secret_store.dart`, `secure_secret_store.dart` | the secrets port and its Secure Storage implementation | 4 |
| `lib/core/database/mutation_gate.dart` | the gate | 5 |
| `lib/core/database/local_data_reset.dart` | clears the account's data from the device | 6 |
| `lib/core/sync/sync_control.dart` | what accounts need from sync | 7 |
| `lib/core/auth/supabase_auth_errors.dart` | GoTrue and RPC errors → `Failure` | 8 |
| `lib/core/auth/account_api.dart`, `supabase_account_api.dart` | the account RPCs | 8 |
| `lib/core/auth/auth_gateway.dart`, `supabase_auth_gateway.dart`, `google_credential_source.dart` | identity | 9 |
| `lib/core/network/network_status.dart` | online now, and reconnects | 10 |
| `lib/core/auth/account_coordinator.dart` | the state machine | 10–12 |
| `lib/core/auth/di/auth_providers.dart` | providers | 14 |
| `test/support/auth_fakes.dart` | fakes and the coordinator harness | 10 |
| `test/architecture/sdk_door_test.dart` | the import rule | 14 |
| `test/core/auth/account_coordinator_crash_test.dart` | crash and network sweeps | 13 |

### Task 1: One door to the Supabase client

Today `lib/main.dart`, `lib/core/sync/di/sync_providers.dart`, `lib/core/sync/sync_failure.dart`, `lib/core/logging/di/logging_providers.dart` and three Monitoring files import `supabase_flutter`. This task moves every such use behind `lib/core/network/`, so Task 14's import rule can hold. Behaviour does not change; the existing tests stay green.

**Files:**
- Create: `lib/core/network/remote_error.dart`, `lib/core/network/supabase_client.dart`
- Modify: `lib/core/sync/sync_failure.dart`, `lib/core/sync/di/sync_providers.dart`, `lib/core/logging/di/logging_providers.dart`, `lib/main.dart`, `lib/features/monitoring/di/monitoring_repository_provider.dart`, `lib/features/monitoring/data/datasources/monitoring_remote_data_source.dart`, `lib/features/monitoring/data/mappers/monitoring_error_mapper.dart`
- Test: `test/core/network/remote_error_test.dart`

**Interfaces:**
- Produces:
  - `enum RemoteErrorKind { network, signIn, server, unknown }`
  - `RemoteErrorKind classifyRemoteError(Object error)`
  - `String? rpcErrorCode(Object error)`
  - `Future<void> initializeSupabase(SupabaseConfig config)`
  - `Future<Object?> supabaseRpc(String function, Map<String, Object?> params)`
  - `bool hasSupabaseSession()`

- [ ] **Step 1: Write the failing test**

`test/core/network/remote_error_test.dart`:

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:memox/core/network/remote_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('a call that never reached the server is network', () {
    for (final error in <Object>[
      const SocketException('down'),
      TimeoutException('slow'),
      http.ClientException('reset'),
      AuthRetryableFetchException(message: 'offline'),
    ]) {
      expect(classifyRemoteError(error), RemoteErrorKind.network, reason: '$error');
    }
  });

  test('a refused sign-in is signIn, a server answer is server', () {
    expect(classifyRemoteError(const AuthException('refused')), RemoteErrorKind.signIn);
    expect(
      classifyRemoteError(const PostgrestException(message: 'FORBIDDEN')),
      RemoteErrorKind.server,
    );
    expect(classifyRemoteError(const FormatException('json')), RemoteErrorKind.server);
    expect(classifyRemoteError(StateError('x')), RemoteErrorKind.unknown);
  });

  test("an RPC's business code is its exception message", () {
    expect(
      rpcErrorCode(const PostgrestException(message: 'LAST_ADMIN', code: 'P0001')),
      'LAST_ADMIN',
    );
    expect(rpcErrorCode(const SocketException('down')), isNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/network/remote_error_test.dart`
Expected: FAIL, with a compile error: `remote_error.dart` does not exist.

- [ ] **Step 3: Write `remote_error.dart`**

```dart
import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// How a call to the server failed, whatever the call was.
enum RemoteErrorKind { network, signIn, server, unknown }

/// The kind of [error] a server call threw. The transport's errors are
/// checked before the sign-in's, since a retryable fetch is also an
/// AuthException.
RemoteErrorKind classifyRemoteError(Object error) => switch (error) {
  SocketException() ||
  TimeoutException() ||
  http.ClientException() ||
  AuthRetryableFetchException() => RemoteErrorKind.network,
  AuthException() => RemoteErrorKind.signIn,
  PostgrestException() ||
  FormatException() ||
  TypeError() => RemoteErrorKind.server,
  _ => RemoteErrorKind.unknown,
};

/// The business code a Postgres function raised: its exception message
/// (SQLSTATE P0001, Supabase backend spec §4). Null for any other error.
String? rpcErrorCode(Object error) =>
    error is PostgrestException ? error.message : null;
```

- [ ] **Step 4: Write `supabase_client.dart`**

```dart
import 'package:http/http.dart' as http;
import 'package:memox/core/network/logging_http_client.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one place that reaches `Supabase.instance` outside `core/auth`'s
/// gateway files (auth spec §5).

/// Before the first frame, when [config] names a project. Every request,
/// auth and RPC, is logged (ADR-018; network logging spec).
Future<void> initializeSupabase(SupabaseConfig config) => Supabase.initialize(
  url: config.url,
  publishableKey: config.publishableKey,
  httpClient: LoggingHttpClient(inner: http.Client()),
);

/// Calls the Postgres function [function] and returns its decoded JSON.
Future<Object?> supabaseRpc(String function, Map<String, Object?> params) =>
    Supabase.instance.client.rpc<Object?>(function, params: params);

/// Whether the SDK holds a session now. It never signs in.
bool hasSupabaseSession() =>
    Supabase.instance.client.auth.currentSession != null;
```

- [ ] **Step 5: Rewire the callers**

1. **`lib/core/sync/sync_failure.dart`:** drop the `dart:async`, `dart:io`, `http` and `supabase_flutter` imports, import `package:memox/core/network/remote_error.dart`, and make the classifier delegate:

   ```dart
   /// The kind of [error] a run threw (the transport's classification).
   SyncFailureKind classifySyncFailure(Object error) =>
       switch (classifyRemoteError(error)) {
         RemoteErrorKind.network => SyncFailureKind.network,
         RemoteErrorKind.signIn => SyncFailureKind.signIn,
         RemoteErrorKind.server => SyncFailureKind.server,
         RemoteErrorKind.unknown => SyncFailureKind.unknown,
       };
   ```

2. **`lib/core/sync/di/sync_providers.dart`:** remove the `supabase_flutter` import, import `package:memox/core/network/supabase_client.dart`, and write `syncApi` as below. It is still signing in lazily; Task 7 changes that.

   ```dart
   @Riverpod(keepAlive: true)
   SyncApi syncApi(Ref ref) => SupabaseSyncApi(
     ensureSession: () async {
       if (hasSupabaseSession()) return;
       await signInAnonymouslyForSync();
     },
     rpc: supabaseRpc,
   );
   ```

   Add to `supabase_client.dart`. Task 7 deletes it again once `AccountCoordinator` owns sign-in.

   ```dart
   /// Sync's lazy anonymous sign-in, until the account coordinator owns
   /// sign-in (auth spec §3; removed by core-auth plan Task 7).
   Future<void> signInAnonymouslyForSync() async {
     await Supabase.instance.client.auth.signInAnonymously();
   }
   ```

3. **`lib/core/logging/di/logging_providers.dart`:** remove the `supabase_flutter` import, import `supabase_client.dart`, and write `logApi` as:

   ```dart
   @Riverpod(keepAlive: true)
   LogApi logApi(Ref ref) => LogApi(
     ensureSession: existingSessionOnly(hasSupabaseSession),
     rpc: supabaseRpc,
   );
   ```

4. **`lib/main.dart`:**
   - Remove the `http`, `logging_http_client` and `supabase_flutter` imports, and import `package:memox/core/network/supabase_client.dart`.
   - Replace the `Supabase.initialize(...)` block with `await initializeSupabase(supabase);` and keep the comment above it.

5. **`lib/features/monitoring/di/monitoring_repository_provider.dart`:** remove the `supabase_flutter` import, import `supabase_client.dart`, and use `rpc: supabaseRpc, hasSession: hasSupabaseSession`.

6. **`lib/features/monitoring/data/datasources/monitoring_remote_data_source.dart`:** remove the `PostgrestException` import, import `package:memox/core/network/remote_error.dart`, and replace the catch:

   ```dart
       } on Object catch (error) {
         if (rpcErrorCode(error) == _notFound) return null;
         rethrow;
       }
   ```

7. **`lib/features/monitoring/data/mappers/monitoring_error_mapper.dart`:** remove the `PostgrestException` import, import `remote_error.dart`, and replace the `FORBIDDEN` test with `if (rpcErrorCode(error) == _forbidden) return NotAdminFailure(cause: error);`.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/core/network test/core/sync test/core/logging test/features/monitoring`
Expected: PASS. The existing `sync_failure_test.dart`, the log and Monitoring tests are unchanged and green.

Run: `grep -rln "package:supabase_flutter" lib`
Expected: exactly the following, and nothing under `core/sync` except `supabase_sync_api.dart`, which imports none of them. Task 14 removes the two Monitoring files.

```
lib/core/network/remote_error.dart
lib/core/network/supabase_client.dart
lib/features/monitoring/di/auth_session_provider.dart
lib/features/monitoring/di/is_admin_provider.dart
```

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "refactor(network): one door to the Supabase client

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 2: Drift v11 — the account tables and `welcome_seen`

**Files:**
- Create: `lib/core/database/tables/account.drift`
- Modify:
  - `lib/core/database/tables/settings.drift`
  - `lib/core/database/app_database.dart`: the include, `schemaVersion`, the `from10To11` step, and `seedOutboxSql`
  - `test/drift/migration_test.dart`, `test/drift/sync_seed_migration_test.dart`
- Generate: `drift_schemas/drift_schema_v11.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema_v11.dart`, `test/drift/generated/schema.dart`, `lib/core/database/app_database.g.dart`
- Test: `test/drift/account_migration_test.dart`

**Interfaces:**
- Produces:
  - Drift tables `accountState` (data class `AccountStateRow`) and `accountTransition` (data class `AccountTransitionRow`), with companions `AccountStateCompanion` and `AccountTransitionCompanion`.
  - Column `AppSettings.welcomeSeen` (`int`, 0 or 1).
  - `const accountRowId = 1`.
  - The public `String seedOutboxSql(String entityType, String table, String order)`, which is the renamed `_seedOutbox`.

- [ ] **Step 1: Write the failing test**

`test/drift/account_migration_test.dart`:

```dart
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import 'generated/schema.dart';

// Auth spec §4: v11 adds the validated account, a pending account transition
// and the welcome flag. Existing settings keep their values; the flag starts
// unset, so an upgraded install sees the welcome once.
void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v10 upgrades to v11 with its settings intact and the welcome unseen',
      () async {
    final schema = await verifier.schemaAt(10);
    schema.rawDatabase.execute(
      "INSERT INTO app_settings (id, card_limit, theme_mode, reminder_enabled, updated_at) "
      "VALUES (1, 35, 'dark', 1, 0)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 11);

    final row = await db.select(db.appSettings).getSingle();
    expect(row.cardLimit, 35);
    expect(row.themeMode, 'dark');
    expect(row.reminderEnabled, 1);
    expect(row.welcomeSeen, 0);
    expect(await db.select(db.accountState).get(), isEmpty);
    expect(await db.select(db.accountTransition).get(), isEmpty);
  });

  test('a transition row is one row at most', () async {
    final db = AppDatabase(await verifier.startAt(11));
    addTearDown(db.close);
    await db.customStatement(
      "INSERT INTO account_transition (id, op_id, kind, stage, created_at, updated_at) "
      "VALUES (1, 'op', 'signOut', 'started', 0, 0)",
    );
    expect(
      () => db.customStatement(
        "INSERT INTO account_transition (id, op_id, kind, stage, created_at, updated_at) "
        "VALUES (2, 'op2', 'signOut', 'started', 0, 0)",
      ),
      throwsA(anything),
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/drift/account_migration_test.dart`
Expected: FAIL, with a compile error: `welcomeSeen`, `accountState` and `accountTransition` are not defined.

- [ ] **Step 3: Add the tables and the column**

`lib/core/database/tables/account.drift`:

```sql
-- Auth spec §4. The account the server last confirmed through me(), read at
-- start before any network (R1, R2). One row; overwritten on each me(),
-- removed when the device's data is cleared (#41).
CREATE TABLE account_state (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  user_id TEXT NOT NULL,
  email TEXT,
  is_anonymous INTEGER NOT NULL CHECK (is_anonymous IN (0, 1)),
  role TEXT NOT NULL CHECK (role IN ('user', 'admin')),
  validated_at DATETIME NOT NULL
) AS AccountStateRow;

-- Auth spec §3.3, §4. The account transition in progress: its intent and how
-- far it got, never who is signed in (R1). Zero or one row, until the flow
-- ends.
CREATE TABLE account_transition (
  id INTEGER NOT NULL PRIMARY KEY CHECK (id = 1),
  op_id TEXT NOT NULL,
  kind TEXT NOT NULL CHECK (kind IN ('switchAccount', 'signOut', 'delete', 'clearToAnon', 'anonRecovery')),
  choice TEXT CHECK (choice IN ('merge', 'discard')),
  source_user_id TEXT,
  source_is_anonymous INTEGER CHECK (source_is_anonymous IN (0, 1)),
  target_user_id TEXT,
  target_hint TEXT,
  stage TEXT NOT NULL CHECK (stage IN ('started', 'sourcePushed', 'claimed', 'targetSignedIn', 'merged', 'localCleared', 'targetPulled', 'acknowledged', 'serverDeleted', 'signedOut', 'newAnon')),
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) AS AccountTransitionRow;
```

In `lib/core/database/tables/settings.drift`, add after `reminder_last_delivered_at DATETIME,`:

```sql
  -- Auth spec §7: the first-launch welcome was answered. Device-only: not in
  -- the account settings that sync, kept by LocalDataReset.
  welcome_seen INTEGER NOT NULL DEFAULT 0 CHECK (welcome_seen IN (0, 1)),
```

The `app_settings_sync_update` trigger names its four columns, so it stays silent for this column. Do not add `welcome_seen` to it or to `AccountSettingsSyncAdapter`.

In `lib/core/database/app_database.dart`:
- Add `'package:memox/core/database/tables/account.drift',` to `include`.
- Set `int get schemaVersion => 11;`.
- Add the step after `from9To10`:

```dart
      from10To11: (m, schema) async {
        // SB-A2/SB-A3 (auth spec §4): the validated account, a pending
        // account transition and the welcome flag. Two empty tables and one
        // column with its default; no row changes.
        await m.createTable(schema.accountState);
        await m.createTable(schema.accountTransition);
        await m.addColumn(schema.appSettings, schema.appSettings.welcomeSeen);
      },
```

- Rename `_seedOutbox` to the public `seedOutboxSql`, including its five call sites in the shipped steps; the SQL each step runs is unchanged (ruling 12). Update its doc comment: `/// Queues every existing row of [table] for upload, in [order] (migrations and SyncStore.markAllPending).`
- Add `const accountRowId = 1;` under `appSettingsRowId`, with the comment `/// The id of the one account_state row and of the one account_transition row.`

- [ ] **Step 4: Regenerate**

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
dart run build_runner build --delete-conflicting-outputs
```

Expected:
- `drift_schemas/drift_schema_v11.json` and `test/drift/generated/schema_v11.dart` exist.
- `schema_versions.dart` has `Schema11` and a `from10To11` parameter.

- [ ] **Step 5: Bump the upgrade-to-latest tests**

Run:

```bash
sed -i 's/migrateAndValidate(db, 10)/migrateAndValidate(db, 11)/; s/upgrades to the schema of v10/upgrades to the schema of v11/' test/drift/migration_test.dart
```

Then add this test after the v9 one in `migration_test.dart`, and extend its header comment with `v11 adds the account state, the account transition and the welcome flag (auth spec §4).`:

```dart
  test('v10 upgrades to the schema of v11', () async {
    final db = AppDatabase(await verifier.startAt(10));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 11);
  });
```

In `test/drift/sync_seed_migration_test.dart`, replace every `migrateAndValidate(db, 10)` with `migrateAndValidate(db, 11)`: the verifier checks the migrated database against the current schema.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/drift`
Expected: PASS for every upgrade test, the seed tests and `account_migration_test.dart`.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test drift_schemas
git commit -m "feat(database): v11 — account state, account transition, welcome flag

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 3: Account types and the `AuthFailure` family

**Files:**
- Create: `lib/core/auth/account_user.dart`, `lib/core/auth/account_transition.dart`, `lib/core/auth/auth_state.dart`
- Modify: `lib/core/error/failure.dart`, `lib/l10n/failure_message.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/core/auth/account_transition_test.dart`, `test/l10n/failure_message_test.dart`

**Interfaces:**
- Produces:
  - `enum AccountRole { user, admin; static AccountRole parse(String?) }`
  - `AccountUser({required String id, String? email, required bool isAnonymous, required AccountRole role})`, with `isAdmin` and value equality.
  - `enum TransitionKind { switchAccount, signOut, delete, clearToAnon, anonRecovery }`
  - `enum TransitionChoice { merge, discard }`
  - `enum TransitionStage { started, sourcePushed, claimed, targetSignedIn, merged, localCleared, targetPulled, acknowledged, serverDeleted, signedOut, newAnon }`, with `isBefore(other)` and `atLeast(other)`.
  - `AccountTransition({required opId, required kind, required stage, required createdAt, required updatedAt, choice, sourceUserId, sourceIsAnonymous, targetUserId, targetHint})`, with `copyWith({stage, targetUserId, updatedAt})`, `merges` and `blocksWrites`.
  - The sealed `AuthState` and its subclasses:
    - `Booting`, `LocalOnly`, `Bootstrapping`
    - `Validating(AccountUser? last)`, `Ready(AccountUser user)`, `ReauthRequired(AccountUser last)`
    - `Transitioning(AccountTransition, {bool needsTargetSignIn, Failure? error})`
    - `Recovering(AccountTransition, {bool needsTargetSignIn, Failure? error, bool stuck})`
  - The sealed `AccountNotice`: `MergeNotDone`, `DeleteRefused(Failure failure)`.
  - In `failure.dart`:
    - `enum IdentityMethod { email, google }`
    - the sealed `AuthFailure extends Failure`, with `SessionInvalidFailure`, `ProfileGoneFailure`, `IdentityTakenFailure(method)`, `InvalidCodeFailure`, `RateLimitedFailure`, `ClaimInvalidFailure`, `LastAdminFailure`, `AnonymousUserFailure`, `GoogleCancelledFailure` and `UnsentChangesFailure(count)`, all with an optional `cause`;
    - `MutationBlockedFailure extends Failure` (const, no cause).
  - ARB keys `failureAccount` and `failureAccountBusy`.

- [ ] **Step 1: Write the failing tests**

`test/core/auth/account_transition_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';

void main() {
  final at = DateTime.utc(2026, 9, 30);

  test('a switch passes its stages in order', () {
    const order = [
      TransitionStage.started,
      TransitionStage.sourcePushed,
      TransitionStage.claimed,
      TransitionStage.targetSignedIn,
      TransitionStage.merged,
      TransitionStage.localCleared,
      TransitionStage.targetPulled,
      TransitionStage.acknowledged,
    ];
    for (var i = 1; i < order.length; i++) {
      expect(order[i - 1].isBefore(order[i]), isTrue, reason: '${order[i]}');
    }
    expect(
      TransitionStage.claimed.atLeast(TransitionStage.targetSignedIn),
      TransitionStage.targetSignedIn,
    );
    expect(
      TransitionStage.merged.atLeast(TransitionStage.targetSignedIn),
      TransitionStage.merged,
    );
  });

  test('sign-out and recovery stages come after the switch ones', () {
    expect(TransitionStage.started.isBefore(TransitionStage.serverDeleted), isTrue);
    expect(TransitionStage.serverDeleted.isBefore(TransitionStage.signedOut), isTrue);
    expect(TransitionStage.started.isBefore(TransitionStage.newAnon), isTrue);
  });

  test('copyWith moves the stage and keeps the intent', () {
    final t = AccountTransition(
      opId: 'op',
      kind: TransitionKind.switchAccount,
      choice: TransitionChoice.merge,
      sourceUserId: 'A',
      sourceIsAnonymous: true,
      stage: TransitionStage.claimed,
      createdAt: at,
      updatedAt: at,
    );
    final next = t.copyWith(stage: TransitionStage.targetSignedIn, targetUserId: 'B');

    expect(next.stage, TransitionStage.targetSignedIn);
    expect(next.targetUserId, 'B');
    expect(next.opId, 'op');
    expect(next.sourceUserId, 'A');
    expect(next.merges, isTrue);
    expect(next.blocksWrites, isTrue);
  });

  test('only anonymous recovery lets business writes through', () {
    for (final kind in TransitionKind.values) {
      final t = AccountTransition(
        opId: 'op',
        kind: kind,
        stage: TransitionStage.started,
        createdAt: at,
        updatedAt: at,
      );
      expect(t.blocksWrites, kind != TransitionKind.anonRecovery, reason: '$kind');
    }
  });

  test('a role other than admin is a user', () {
    expect(AccountRole.parse('admin'), AccountRole.admin);
    expect(AccountRole.parse('user'), AccountRole.user);
    expect(AccountRole.parse(null), AccountRole.user);
    expect(
      const AccountUser(id: 'u', isAnonymous: false, role: AccountRole.admin),
      const AccountUser(id: 'u', isAnonymous: false, role: AccountRole.admin),
    );
  });
}
```

In `test/l10n/failure_message_test.dart`, add to the `failures` list. Also add `import 'package:memox/core/error/failure.dart';` if it is missing.

```dart
        const SessionInvalidFailure(cause: 'refresh_token_not_found'),
        const IdentityTakenFailure(method: IdentityMethod.google),
        const InvalidCodeFailure(cause: 'otp_expired'),
        const LastAdminFailure(cause: 'LAST_ADMIN'),
        const UnsentChangesFailure(count: 3),
        const MutationBlockedFailure(),
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/auth/account_transition_test.dart test/l10n/failure_message_test.dart`
Expected: FAIL, with compile errors: the auth types and failures are not defined.

- [ ] **Step 3: Write the types**

`lib/core/auth/account_user.dart`:

```dart
/// The account's role (auth spec O8): `public.profiles.role`.
enum AccountRole {
  user,
  admin;

  /// Anything but `admin` is a user.
  static AccountRole parse(String? name) => name == 'admin' ? admin : user;
}

/// Who the server says the signed-in user is: the answer of `me()` (auth
/// spec §2.3, §5). The app's own type; no SDK `User` leaves the gateway.
final class AccountUser {
  const AccountUser({
    required this.id,
    required this.isAnonymous,
    required this.role,
    this.email,
  });

  final String id;
  final String? email;
  final bool isAnonymous;
  final AccountRole role;

  bool get isAdmin => role == AccountRole.admin;

  @override
  bool operator ==(Object other) =>
      other is AccountUser &&
      other.id == id &&
      other.email == email &&
      other.isAnonymous == isAnonymous &&
      other.role == role;

  @override
  int get hashCode => Object.hash(id, email, isAnonymous, role);

  @override
  String toString() =>
      'AccountUser($id, anonymous: $isAnonymous, role: ${role.name})';
}
```

`lib/core/auth/account_transition.dart`:

```dart
/// What an account transition does (auth spec §3.3).
enum TransitionKind { switchAccount, signOut, delete, clearToAnon, anonRecovery }

/// Whether a switch brings this device's data into the target account.
/// On a sign-out, `discard` means the user accepted losing unsent changes
/// (plan ruling 10).
enum TransitionChoice { merge, discard }

/// How far a transition got, in the order flows pass them. Each kind uses
/// its own subsequence:
/// - Switch: started … acknowledged.
/// - SignOut, Delete and ClearToAnon: started, serverDeleted, signedOut.
/// - AnonRecovery: started, newAnon.
///
/// Every stage is saved before the next step, so a rerun resumes where the
/// last run stopped (spec §6).
enum TransitionStage {
  started,
  sourcePushed,
  claimed,
  targetSignedIn,
  merged,
  localCleared,
  targetPulled,
  acknowledged,
  serverDeleted,
  signedOut,
  newAnon;

  bool isBefore(TransitionStage other) => index < other.index;

  /// The later of this stage and [other].
  TransitionStage atLeast(TransitionStage other) =>
      index >= other.index ? this : other;
}

/// The account transition in progress (auth spec §4): its intent and how far
/// it got. Never who is signed in: the SDK says that (R1).
final class AccountTransition {
  const AccountTransition({
    required this.opId,
    required this.kind,
    required this.stage,
    required this.createdAt,
    required this.updatedAt,
    this.choice,
    this.sourceUserId,
    this.sourceIsAnonymous,
    this.targetUserId,
    this.targetHint,
  });

  /// The merge's `operation_id`; also the key of this flow's secrets.
  final String opId;
  final TransitionKind kind;
  final TransitionChoice? choice;
  final String? sourceUserId;
  final bool? sourceIsAnonymous;
  final String? targetUserId;

  /// The target's email as typed, shown while the target sign-in is asked.
  final String? targetHint;
  final TransitionStage stage;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get merges => choice == TransitionChoice.merge;

  /// Business writes wait during every transition but an anonymous
  /// recovery (R3, spec §3.2).
  bool get blocksWrites => kind != TransitionKind.anonRecovery;

  AccountTransition copyWith({
    TransitionStage? stage,
    String? targetUserId,
    DateTime? updatedAt,
  }) => AccountTransition(
    opId: opId,
    kind: kind,
    choice: choice,
    sourceUserId: sourceUserId,
    sourceIsAnonymous: sourceIsAnonymous,
    targetUserId: targetUserId ?? this.targetUserId,
    targetHint: targetHint,
    stage: stage ?? this.stage,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  String toString() =>
      'AccountTransition(${kind.name}, ${stage.name}, op: $opId)';
}
```

`lib/core/auth/auth_state.dart`:

```dart
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/error/failure.dart';

/// Where the account stands (auth spec §3.2). The single source of truth
/// for sync, the router and every screen (`authStateProvider`).
sealed class AuthState {
  const AuthState();
}

/// Reading the record and the session.
final class Booting extends AuthState {
  const Booting();
}

/// No session and no network. Local writes go on; the outbox fills.
final class LocalOnly extends AuthState {
  const LocalOnly();
}

/// Creating the anonymous user, only if the SDK has none (#5, #6).
final class Bootstrapping extends AuthState {
  const Bootstrapping();
}

/// A session, not yet confirmed by `me()`. Sync stays paused (R2).
final class Validating extends AuthState {
  const Validating(this.last);

  final AccountUser? last;
}

/// Confirmed. Sync runs when online.
final class Ready extends AuthState {
  const Ready(this.user);

  final AccountUser user;
}

/// A permanent account whose session was refused. Local data is kept and
/// sync paused until the user signs in again (#14).
final class ReauthRequired extends AuthState {
  const ReauthRequired(this.last);

  final AccountUser last;
}

/// A transition this run of the app started.
final class Transitioning extends AuthState {
  const Transitioning(
    this.transition, {
    this.needsTargetSignIn = false,
    this.error,
  });

  final AccountTransition transition;

  /// The switch waits for the user to sign in to the target account.
  final bool needsTargetSignIn;

  /// Why the flow stopped, when it did (a network error until Retry).
  final Failure? error;
}

/// A transition found at start, being reconciled with the SDK (R1, #45).
final class Recovering extends AuthState {
  const Recovering(
    this.transition, {
    this.needsTargetSignIn = false,
    this.error,
    this.stuck = false,
  });

  final AccountTransition transition;
  final bool needsTargetSignIn;
  final Failure? error;

  /// A state the table says cannot happen (#31 after a merge). The gate
  /// stays shut, and the log has the details.
  final bool stuck;
}

/// A one-off outcome for the user, beside the state (plan ruling 3).
sealed class AccountNotice {
  const AccountNotice();
}

/// The merge was refused and the device is back on its own data (#25).
final class MergeNotDone extends AccountNotice {
  const MergeNotDone();
}

/// The deletion did not happen (#44).
final class DeleteRefused extends AccountNotice {
  const DeleteRefused(this.failure);

  final Failure failure;
}
```

- [ ] **Step 4: Add the failures**

In `lib/core/error/failure.dart`, after `ServerFailure`:

```dart
/// How an identity was being attached when it turned out to belong to
/// another account (auth spec §3.2 `IDENTITY_TAKEN`).
enum IdentityMethod { email, google }

/// An account step that the server or the identity provider refused (auth
/// spec §3.2, §5). A call that never arrived stays [OfflineFailure], and an
/// admin-only refusal stays [NotAdminFailure] (plan ruling 1).
sealed class AuthFailure extends Failure {
  const AuthFailure({required super.message, super.cause});
}

/// The SDK's session was refused: its refresh token, session or user is gone.
final class SessionInvalidFailure extends AuthFailure {
  const SessionInvalidFailure({super.cause})
    : super(message: 'The sign-in is no longer valid.');
}

/// A live token whose user no longer has a profile: the account was
/// deleted (`me()` → `UNAUTHORIZED`).
final class ProfileGoneFailure extends AuthFailure {
  const ProfileGoneFailure({super.cause})
    : super(message: 'This account no longer exists.');
}

final class IdentityTakenFailure extends AuthFailure {
  const IdentityTakenFailure({required this.method, super.cause})
    : super(message: 'That sign-in belongs to another account.');

  final IdentityMethod method;
}

/// A code the server refused. GoTrue answers a wrong and an expired code
/// alike (plan ruling 2).
final class InvalidCodeFailure extends AuthFailure {
  const InvalidCodeFailure({super.cause})
    : super(message: 'The code is wrong or has expired.');
}

final class RateLimitedFailure extends AuthFailure {
  const RateLimitedFailure({super.cause})
    : super(message: 'Too many attempts. Wait, then try again.');
}

/// The claim token was used, expired or never existed (`CLAIM_INVALID`).
final class ClaimInvalidFailure extends AuthFailure {
  const ClaimInvalidFailure({super.cause})
    : super(message: 'The merge could not be completed.');
}

final class LastAdminFailure extends AuthFailure {
  const LastAdminFailure({super.cause})
    : super(message: 'An admin must remain.');
}

final class AnonymousUserFailure extends AuthFailure {
  const AnonymousUserFailure({super.cause})
    : super(message: 'An anonymous user cannot be an admin.');
}

final class GoogleCancelledFailure extends AuthFailure {
  const GoogleCancelledFailure({super.cause})
    : super(message: 'Google sign-in was cancelled.');
}

/// Signing in again as another account would clear [count] changes not yet
/// sent; the caller asks first (plan ruling 6).
final class UnsentChangesFailure extends AuthFailure {
  const UnsentChangesFailure({required this.count})
    : super(message: 'Changes on this phone are not sent yet.');

  final int count;
}

/// A business write while the account is changing (R3). Nothing was
/// written.
final class MutationBlockedFailure extends Failure {
  const MutationBlockedFailure()
    : super(message: 'The account is changing. Try again in a moment.');
}
```

In `lib/l10n/failure_message.dart`, add two arms to the switch, before the closing `};`:

```dart
    MutationBlockedFailure() => failureAccountBusy,
    AuthFailure() => failureAccount,
```

In `lib/l10n/app_en.arb`, after the `failureUnknown` entry:

```json
  "failureAccount": "Nothing was lost. The account step didn't finish. Try again.",
  "@failureAccount": {
    "description": "Any refused account step (auth spec §3.2); screens of P3 may say more for their own cases."
  },
  "failureAccountBusy": "Nothing was saved yet: your account is changing. Try again in a moment.",
  "@failureAccountBusy": {
    "description": "A change refused while the account switches, signs out or is deleted (R3)."
  },
```

In `lib/l10n/app_vi.arb`, at the same place:

```json
  "failureAccount": "Không mất dữ liệu nào. Bước tài khoản chưa xong, hãy thử lại.",
  "failureAccountBusy": "Chưa lưu gì: tài khoản đang được chuyển. Hãy thử lại sau giây lát.",
```

Then run `flutter gen-l10n`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/core/auth/account_transition_test.dart test/l10n`
Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(auth): account types and the AuthFailure family

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 4: `AccountStore` and `SecretStore`

**Files:**
- Create: `lib/core/auth/account_store.dart`, `lib/core/auth/secret_store.dart`, `lib/core/auth/secure_secret_store.dart`
- Modify: `pubspec.yaml`, `pubspec.lock` (`flutter_secure_storage`)
- Test: `test/core/auth/account_store_test.dart`, `test/core/auth/secret_store_test.dart`, `test/support/fake_secret_store.dart`

**Interfaces:**
- Consumes (Tasks 2 and 3): `AppDatabase.accountState`, `AppDatabase.accountTransition`, `accountRowId`, `AccountUser`, `AccountTransition`.
- Produces:
  - `AccountStore(AppDatabase db)`, with:
    - `Future<AccountUser?> lastKnown()`
    - `Future<void> saveLastKnown(AccountUser, DateTime at)`
    - `Future<void> clearLastKnown()`
    - `Future<AccountTransition?> transition()`
    - `Future<AccountTransition> saveTransition(AccountTransition)`
    - `Future<void> clearTransition()`
  - The interface `SecretStore { read, write, delete, keys }`.
  - `String backupSecretKey(String opId)` and `String claimSecretKey(String opId)`.
  - `Future<void> purgeAccountSecrets(SecretStore, {String? keepOpId})`.
  - `SecureSecretStore implements SecretStore`.
  - Test side: `FakeSecretStore implements SecretStore`, with a public `values` map and an `onCall` hook that Task 10's `KillSwitch` uses.

- [ ] **Step 1: Add the package**

Run: `flutter pub add flutter_secure_storage:^11.2.0`
Expected: `pubspec.yaml` lists it and `flutter pub get` succeeds.

If the Android build later needs a higher `minSdk`, raise it in `android/app/build.gradle.kts` to what the package's README states, and ledger the ruling.

- [ ] **Step 2: Write the failing tests**

`test/support/fake_secret_store.dart`:

```dart
import 'package:memox/core/auth/secret_store.dart';

/// Secure Storage in memory. [onCall] runs before every call, so a crash test
/// can stop the flow at any step.
class FakeSecretStore implements SecretStore {
  final values = <String, String>{};
  void Function()? onCall;

  @override
  Future<String?> read(String key) async {
    onCall?.call();
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    onCall?.call();
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    onCall?.call();
    values.remove(key);
  }

  @override
  Future<Set<String>> keys() async => values.keys.toSet();
}
```

`test/core/auth/secret_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/secret_store.dart';

import '../../support/fake_secret_store.dart';

void main() {
  test("the purge keeps the current op's secrets and other apps' keys", () async {
    final secrets = FakeSecretStore()
      ..values.addAll({
        backupSecretKey('old'): 'r1',
        claimSecretKey('old'): 'c1',
        backupSecretKey('now'): 'r2',
        claimSecretKey('now'): 'c2',
        'other.key': 'x',
      });

    await purgeAccountSecrets(secrets, keepOpId: 'now');

    expect(secrets.values.keys.toSet(), {
      backupSecretKey('now'),
      claimSecretKey('now'),
      'other.key',
    });
  });

  test('with no current op every account secret goes', () async {
    final secrets = FakeSecretStore()
      ..values.addAll({backupSecretKey('a'): 'r', 'other.key': 'x'});

    await purgeAccountSecrets(secrets);

    expect(secrets.values.keys, ['other.key']);
  });
}
```

`test/core/auth/account_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';

import '../../support/test_database.dart';

void main() {
  final at = DateTime.utc(2026, 9, 30, 8);

  test('the last known account round-trips and is cleared', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = AccountStore(db);
    const user = AccountUser(
      id: 'u1',
      email: 'a@example.com',
      isAnonymous: false,
      role: AccountRole.admin,
    );

    expect(await store.lastKnown(), isNull);
    await store.saveLastKnown(user, at);
    await store.saveLastKnown(user, at.add(const Duration(minutes: 1)));
    expect(await store.lastKnown(), user);

    await store.clearLastKnown();
    expect(await store.lastKnown(), isNull);
  });

  test('the transition round-trips every field and is one row', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = AccountStore(db);
    final t = AccountTransition(
      opId: 'op',
      kind: TransitionKind.switchAccount,
      choice: TransitionChoice.merge,
      sourceUserId: 'A',
      sourceIsAnonymous: true,
      targetHint: 'b@example.com',
      stage: TransitionStage.claimed,
      createdAt: at,
      updatedAt: at,
    );

    await store.saveTransition(t);
    await store.saveTransition(
      t.copyWith(stage: TransitionStage.targetSignedIn, targetUserId: 'B'),
    );
    final read = (await store.transition())!;

    expect(read.opId, 'op');
    expect(read.kind, TransitionKind.switchAccount);
    expect(read.choice, TransitionChoice.merge);
    expect(read.sourceUserId, 'A');
    expect(read.sourceIsAnonymous, isTrue);
    expect(read.targetUserId, 'B');
    expect(read.targetHint, 'b@example.com');
    expect(read.stage, TransitionStage.targetSignedIn);
    expect(read.createdAt, at);

    await store.clearTransition();
    expect(await store.transition(), isNull);
  });

}
```

- [ ] **Step 3: Run them to verify they fail**

Run: `flutter test test/core/auth/account_store_test.dart test/core/auth/secret_store_test.dart`
Expected: FAIL, with compile errors: `AccountStore` and `secret_store.dart` do not exist.

- [ ] **Step 4: Write the stores**

`lib/core/auth/secret_store.dart`:

```dart
/// Where the account keeps its short-lived secrets (auth spec §4, O13): A's
/// refresh-token backup and the claim token, one pair per operation. Never
/// Drift, never a log.
abstract interface class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<Set<String>> keys();
}

const _prefix = 'account.';

/// A's refresh token, kept while switching to B (#20, ruling 4).
String backupSecretKey(String opId) => '${_prefix}backup.$opId';

/// The one-time token that lets B claim A's data (#20).
String claimSecretKey(String opId) => '${_prefix}claim.$opId';

/// At start: every account secret that is not [keepOpId]'s goes (auth spec
/// §4). Keys of anything else are left alone.
Future<void> purgeAccountSecrets(
  SecretStore secrets, {
  String? keepOpId,
}) async {
  for (final key in await secrets.keys()) {
    if (!key.startsWith(_prefix)) continue;
    if (keepOpId != null && key.endsWith('.$keepOpId')) continue;
    await secrets.delete(key);
  }
}
```

`lib/core/auth/secure_secret_store.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:memox/core/auth/secret_store.dart';

/// [SecretStore] on the platform's secure storage (auth spec O13). The one
/// file that imports `flutter_secure_storage` (plan ruling 18).
class SecureSecretStore implements SecretStore {
  SecureSecretStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<Set<String>> keys() async => (await _storage.readAll()).keys.toSet();
}
```

`lib/core/auth/account_store.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/database/app_database.dart';

/// The account's persisted state (auth spec §4): the last account `me()`
/// confirmed and the transition in progress. Device-only; never synced. It
/// writes past the mutation gate (R3 stops business writes, not these).
class AccountStore {
  AccountStore(this._db);

  final AppDatabase _db;

  Future<AccountUser?> lastKnown() async {
    final row = await _db.select(_db.accountState).getSingleOrNull();
    if (row == null) return null;
    return AccountUser(
      id: row.userId,
      email: row.email,
      isAnonymous: row.isAnonymous == 1,
      role: AccountRole.parse(row.role),
    );
  }

  Future<void> saveLastKnown(AccountUser user, DateTime at) => _db
      .into(_db.accountState)
      .insertOnConflictUpdate(
        AccountStateCompanion.insert(
          id: const Value(accountRowId),
          userId: user.id,
          email: Value(user.email),
          isAnonymous: user.isAnonymous ? 1 : 0,
          role: user.role.name,
          validatedAt: at,
        ),
      );

  Future<void> clearLastKnown() => _db.delete(_db.accountState).go();

  Future<AccountTransition?> transition() async {
    final row = await _db.select(_db.accountTransition).getSingleOrNull();
    if (row == null) return null;
    final sourceIsAnonymous = row.sourceIsAnonymous;
    final choice = row.choice;
    return AccountTransition(
      opId: row.opId,
      kind: TransitionKind.values.byName(row.kind),
      choice: choice == null ? null : TransitionChoice.values.byName(choice),
      sourceUserId: row.sourceUserId,
      sourceIsAnonymous: sourceIsAnonymous == null
          ? null
          : sourceIsAnonymous == 1,
      targetUserId: row.targetUserId,
      targetHint: row.targetHint,
      stage: TransitionStage.values.byName(row.stage),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Saves [t] as the one record and returns it.
  Future<AccountTransition> saveTransition(AccountTransition t) async {
    final sourceIsAnonymous = t.sourceIsAnonymous;
    await _db
        .into(_db.accountTransition)
        .insertOnConflictUpdate(
          AccountTransitionCompanion.insert(
            id: const Value(accountRowId),
            opId: t.opId,
            kind: t.kind.name,
            choice: Value(t.choice?.name),
            sourceUserId: Value(t.sourceUserId),
            sourceIsAnonymous: Value(
              sourceIsAnonymous == null ? null : (sourceIsAnonymous ? 1 : 0),
            ),
            targetUserId: Value(t.targetUserId),
            targetHint: Value(t.targetHint),
            stage: t.stage.name,
            createdAt: t.createdAt,
            updatedAt: t.updatedAt,
          ),
        );
    return t;
  }

  Future<void> clearTransition() => _db.delete(_db.accountTransition).go();
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/core/auth/account_store_test.dart test/core/auth/secret_store_test.dart`
Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add pubspec.yaml pubspec.lock lib test
git commit -m "feat(auth): account store in Drift, secrets in secure storage

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 5: `MutationGate` in the shared write path

**Files:**
- Create: `lib/core/database/mutation_gate.dart`
- Modify:
  - `lib/core/database/app_database.dart`: the constructor and the field
  - `lib/core/database/mapped_transaction.dart`
  - `lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart`: its one write moves to `mappedTransaction`
- Test: `test/core/database/mutation_gate_test.dart`

**Interfaces:**
- Consumes: `MutationBlockedFailure` (Task 3) and `AccountStore` (Task 4).
- Produces:
  - `MutationGate` with `isClosed`, `close()`, `open()` and `check()`. `check()` throws `MutationBlockedFailure` while the gate is closed.
  - `AppDatabase(executor, {DateTime Function()? now, MutationGate? mutationGate})`, and its `final MutationGate mutationGate`.

- [ ] **Step 1: Write the failing test**

`test/core/database/mutation_gate_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_store.dart';

import '../../support/test_database.dart';

// Auth spec R3 and plan Review Focus 5: while the account changes, a
// business write fails and writes nothing; sync's own path, the account's
// store and the reset still write.
void main() {
  Future<int> tagCount(db) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM tags').getSingle())
          .read<int>('n');

  test('a closed gate refuses a business write and writes nothing', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    db.mutationGate.close();

    await expectLater(
      db.mappedTransaction(
        () => db.customStatement(
          "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
        ),
      ),
      throwsA(isA<MutationBlockedFailure>()),
    );
    expect(await tagCount(db), 0);
    expect(
      (await db.customSelect('SELECT COUNT(*) AS n FROM sync_outbox').getSingle())
          .read<int>('n'),
      0,
    );
  });

  test('an open gate lets the write through', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    db.mutationGate
      ..close()
      ..open();

    await db.mappedTransaction(
      () => db.customStatement(
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
      ),
    );

    expect(await tagCount(db), 1);
  });

  test("sync's own path and the account store write past a closed gate",
      () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    db.mutationGate.close();

    await SyncStore(db).applyingRemote(
      () => db.customStatement(
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
      ),
    );
    await AccountStore(db).saveLastKnown(
      const AccountUser(id: 'u', isAnonymous: true, role: AccountRole.user),
      DateTime.utc(2026, 9, 30),
    );

    expect(await tagCount(db), 1);
    expect(await AccountStore(db).lastKnown(), isNotNull);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/database/mutation_gate_test.dart`
Expected: FAIL, with a compile error: `mutationGate` is not defined.

- [ ] **Step 3: Write the gate and put it in the write path**

`lib/core/database/mutation_gate.dart`:

```dart
import 'package:memox/core/error/failure.dart';

/// Shut while the account switches, signs out, is deleted or is cleared
/// (auth spec R3). Every business write passes [check] in
/// `mappedTransaction`. Sync's pull, the reset and the account store write
/// on their own paths, so they are not stopped by it.
class MutationGate {
  var _closed = false;

  bool get isClosed => _closed;

  void close() => _closed = true;

  void open() => _closed = false;

  /// Throws [MutationBlockedFailure] while shut.
  void check() {
    if (_closed) throw const MutationBlockedFailure();
  }
}
```

In `lib/core/database/app_database.dart`, import `mutation_gate.dart` and change the constructor:

```dart
  AppDatabase(
    super.executor, {
    DateTime Function()? now,
    MutationGate? mutationGate,
  }) : _now = now ?? DateTime.now,
       mutationGate = mutationGate ?? MutationGate();

  final DateTime Function() _now;

  /// The account's write gate (auth spec R3); open unless a transition runs.
  final MutationGate mutationGate;
```

`lib/core/database/mapped_transaction.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';

/// A transaction whose unexpected error leaves as its [Failure], after the
/// rollback: the one place repositories open a write (spec
/// 2026-09-29-database-error-guard-design.md D2). It refuses to start while
/// the account's gate is shut (auth spec R3).
extension MappedTransaction on AppDatabase {
  Future<T> mappedTransaction<T>(Future<T> Function() body) =>
      guardDatabase(() {
        mutationGate.check();
        return transaction(body);
      });
}
```

In `starter_library_repository_impl.dart`:
- replace `return guardDatabase(\n      () => _db.transaction(() async {` with `return _db.mappedTransaction(() async {`;
- close it with `});` in place of `}),\n    );`;
- import `package:memox/core/database/mapped_transaction.dart`, and drop the `failure.dart` import if nothing else uses `guardDatabase` there.

Run `grep -n "guardDatabase\|failure.dart" lib/features/starter_decks/data/repositories/starter_library_repository_impl.dart` before deleting that import.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/database test/features/starter_decks`
Expected: PASS: the three gate tests and the unchanged starter tests.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(database): the account's mutation gate in the shared write path

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 6: `LocalDataReset`

**Files:**
- Create: `lib/core/database/local_data_reset.dart`
- Test: `test/core/database/local_data_reset_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `accountRowId`, `appSettingsRowId`, and `syncApplyingRemoteKey` and `syncDeviceIdKey` from `tables/sync_keys.dart`.
- Produces: `LocalDataReset(AppDatabase db, {DateTime Function()? now})`, with `Future<void> run()`. The class is non-final, so the fakes can `implements` it.

- [ ] **Step 1: Write the failing test**

`test/core/database/local_data_reset_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/local_data_reset.dart';

import '../../support/test_database.dart';

// Auth spec §4: the reset removes the account's data from the device and
// keeps the device's own: the transition record, the welcome flag, the
// reminder, the device id. It queues nothing and is gated by nothing.
Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

Future<void> _seed(AppDatabase db) async {
  for (final sql in [
    "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b', 'deck', 'D2', 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('C', 'c', 'R', 'R', 2, 'card', 0, 0, 0)",
    "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'C', 'f', 'b', 0, 0)",
    "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
    "INSERT INTO card_tags (card_id, tag_id) VALUES ('K', 't')",
    "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 1, 0, 1)",
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", answered_at) VALUES ('V', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
    "UPDATE app_settings SET card_limit = 35, theme_mode = 'dark', language = 'vi', new_card_order = 'random', reminder_enabled = 1, reminder_minute_of_day = 480, welcome_seen = 1",
    "INSERT INTO sync_rejection (entity_type, entity_id, code, rejected_at) VALUES ('deck', 'R', 'CONFLICT', 0)",
    "INSERT OR REPLACE INTO sync_state (name, value) VALUES ('since', '42'), ('device_id', 'dev-1'), ('last_success_at', '9')",
    "INSERT INTO account_transition (id, op_id, kind, stage, created_at, updated_at) VALUES (1, 'op', 'signOut', 'signedOut', 0, 0)",
  ]) {
    await db.customStatement(sql);
  }
}

void main() {
  test("clears the account's data and keeps the device's", () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _seed(db);
    db.mutationGate.close();

    await LocalDataReset(db).run();

    for (final table in [
      'deck',
      'card',
      'tags',
      'card_tags',
      'card_schedule',
      'review_log',
      'delete_batches',
      'sync_outbox',
      'sync_rejection',
    ]) {
      expect(await _count(db, table), 0, reason: table);
    }
    final settings = await db.select(db.appSettings).getSingle();
    expect(settings.cardLimit, 20);
    expect(settings.newCardOrder, 'created');
    expect(settings.themeMode, 'system');
    expect(settings.language, 'system');
    expect(settings.reminderEnabled, 1);
    expect(settings.reminderMinuteOfDay, 480);
    expect(settings.welcomeSeen, 1);
    final state = await db.customSelect('SELECT name, value FROM sync_state').get();
    expect(
      {for (final row in state) row.read<String>('name'): row.read<String>('value')},
      {'device_id': 'dev-1'},
    );
    expect(await _count(db, 'account_transition'), 1);
  });

  test('a second run is a no-op', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _seed(db);
    final reset = LocalDataReset(db);

    await reset.run();
    await reset.run();

    expect(await _count(db, 'deck'), 0);
    expect(await _count(db, 'sync_outbox'), 0);
  });
}
```

The seed's columns follow `lib/core/database/tables/*.drift` as of v11. If a column is added later, only the seed text may change, never what the test asserts.

- [ ] **Step 2: Run it to verify it fails**

Run: `flutter test test/core/database/local_data_reset_test.dart`
Expected: FAIL, with a compile error: `local_data_reset.dart` does not exist.

- [ ] **Step 3: Write the reset**

`lib/core/database/local_data_reset.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';

/// Removes the signed-out or replaced account's data from the device (auth
/// spec §4, #27, #41). One transaction, and not gated (R3 lets it write).
///
/// The capture triggers are silenced with `applying_remote`, so the deletes
/// queue nothing. Cards go first: their schedules, tag links, reviews and
/// study rows go with them by cascade, and reviews cannot be deleted while
/// their card exists. The synced settings go back to `settings.drift`'s
/// defaults while the triggers are still silent. Then sync's keys (all but
/// the device id), the outbox and the refusals.
///
/// Kept: the transition record, the welcome flag, the reminder columns, the
/// device id and the log database.
class LocalDataReset {
  LocalDataReset(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<void> run() => _db.transaction(() async {
    await _db.customStatement(
      'INSERT OR REPLACE INTO sync_state (name, value) VALUES (?, ?)',
      [syncApplyingRemoteKey, '1'],
    );
    for (final table in ['card', 'deck', 'delete_batches', 'tags']) {
      await _db.customStatement('DELETE FROM $table');
    }
    await _db.customStatement(
      "UPDATE app_settings SET card_limit = 20, new_card_order = 'created', "
      "theme_mode = 'system', language = 'system', updated_at = ? "
      'WHERE id = $appSettingsRowId',
      [_now().millisecondsSinceEpoch ~/ 1000],
    );
    await _db.customStatement('DELETE FROM sync_state WHERE name <> ?', [
      syncDeviceIdKey,
    ]);
    await _db.customStatement('DELETE FROM sync_outbox');
    await _db.customStatement('DELETE FROM sync_rejection');
  });
}
```

The `updated_at` value follows Drift's default `DATETIME` storage (unix seconds). Check `app_database.g.dart`'s `AppSettings.updatedAt` mapping. If the project stores datetimes as text, write `_now().toIso8601String()` instead, and ledger the ruling.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/database/local_data_reset_test.dart`
Expected: PASS. If the `review_log_no_delete` trigger aborts the card delete, the cascade order is wrong. Use systematic-debugging. The trash purge already deletes cards with reviews, so read how `trash_repository_impl.dart`'s `_purge` does it and follow that order.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(database): LocalDataReset clears the account's data from the device

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 7: `SyncControl` — pause, resume, push all, pull all, full push

**Files:**
- Create: `lib/core/sync/sync_control.dart`
- Modify:
  - `lib/core/sync/sync_scheduler.dart`
  - `lib/core/sync/sync_store.dart`
  - `lib/core/sync/sync_coordinator.dart`
  - `lib/core/sync/supabase_sync_api.dart`: `SyncSessionMissing`
  - `lib/core/sync/di/sync_providers.dart`: `syncApi` becomes existing-session-only, the scheduler starts paused, and `syncControl` is added
  - `lib/core/network/supabase_client.dart`: drop `signInAnonymouslyForSync`
- Test: `test/core/sync/sync_scheduler_test.dart`, `test/core/sync/sync_store_test.dart`, `test/core/sync/sync_control_test.dart`

**Interfaces:**
- Consumes: `seedOutboxSql` (Task 2), `OfflineFailure` and `ServerFailure`.
- Produces:
  - `SyncScheduler`: `start({bool paused = false})`, `Future<void> pause()`, `void resume()`, `bool get isPaused`.
  - `SyncStore`: `Future<int> pendingCount()`, `Future<void> markAllPending()`.
  - `SyncCoordinator`: `Future<void> pushAll()`, `Future<void> pullAll()`.
  - The interface `SyncControl { Future<void> pause(); void resume(); Future<int> pendingCount(); Future<void> pushPending(); Future<void> pullAll(); Future<void> markAllPending(); }`.
  - `AppSyncControl({required SyncScheduler? scheduler, required SyncCoordinator coordinator, required SyncStore store})`. It maps transport errors to `OfflineFailure` or `ServerFailure`.
  - The provider `syncControlProvider` (keepAlive).
  - `final class SyncSessionMissing implements Exception`.

- [ ] **Step 1: Write the failing tests**

Append to `test/core/sync/sync_scheduler_test.dart`:

```dart
  test('started paused, nothing runs until resume', () {
    fakeAsync((clock) {
      var runs = 0;
      final triggers = StreamController<void>();
      final reconnects = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async => runs++,
        triggers: triggers.stream,
        reconnects: reconnects.stream,
      )..start(paused: true);

      triggers.add(null);
      reconnects.add(null);
      clock.elapse(const Duration(minutes: 1));
      expect(runs, 0);
      expect(scheduler.isPaused, isTrue);

      var answered = false;
      scheduler.syncNow().then((ok) {
        expect(ok, isFalse);
        answered = true;
      });
      clock.flushMicrotasks();
      expect(answered, isTrue);
      expect(runs, 0);

      scheduler.resume();
      clock.elapse(Duration.zero);
      expect(runs, 1);

      scheduler.dispose();
      triggers.close();
      reconnects.close();
    });
  });

  test('pause waits for the run in progress and schedules nothing after', () {
    fakeAsync((clock) {
      var runs = 0;
      final release = Completer<void>();
      final triggers = StreamController<void>();
      final scheduler = SyncScheduler(
        run: () async {
          runs++;
          await release.future;
        },
        triggers: triggers.stream,
      )..start();
      clock.elapse(Duration.zero);
      expect(runs, 1);

      var paused = false;
      scheduler.pause().then((_) => paused = true);
      clock.flushMicrotasks();
      expect(paused, isFalse);

      triggers.add(null);
      release.complete();
      clock.elapse(const Duration(minutes: 10));
      expect(paused, isTrue);
      expect(runs, 1);

      scheduler.dispose();
      triggers.close();
    });
  });
```

Append to `test/core/sync/sync_store_test.dart`. Add `import 'package:memox/core/sync/sync_coordinator.dart';` only if it is needed, and keep the file's existing imports.

```dart
  test('markAllPending queues every row parents first, once, and rewinds the cursor',
      () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    await store.applyingRemote(() async {
      for (final sql in [
        "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b', 'deck', 'x', 0)",
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('R', 'r', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
        "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('C', 'c', 'R', 'R', 2, 'card', 0, 0, 0)",
        "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('K', 'C', 'f', 'b', 0, 0)",
        "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
        "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, answer_count, lapse_count, current_box) VALUES ('K', 'eight_box', 1, 1, 1, 0, 1)",
        "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", answered_at) VALUES ('V', 'K', 's', 'eight_box', 1, 'learning', 'self_assess', 'remembered', 1)",
      ]) {
        await db.customStatement(sql);
      }
    });
    await store.setSince(42);
    await store.enqueue('deck', 'R', 'delete', DateTime.utc(2026));

    await store.markAllPending();
    await store.markAllPending();

    final queued = await db
        .customSelect('SELECT entity_type, entity_id, op FROM sync_outbox ORDER BY rowid')
        .get();
    expect(
      [
        for (final row in queued)
          '${row.read<String>('entity_type')}:${row.read<String>('entity_id')}:${row.read<String>('op')}',
      ],
      [
        'deck:R:delete',
        'delete_batch:b:upsert',
        'deck:C:upsert',
        'tag:t:upsert',
        'card:K:upsert',
        'card_schedule:K:upsert',
        'review_log:V:upsert',
        'account_settings:00000000-0000-0000-0000-000000000000:upsert',
      ],
    );
    expect(await store.since(), 0);
    expect(await store.pendingCount(), 8);
  });
```

The deck `R` was already queued as a delete, and it keeps that operation: `ON CONFLICT DO NOTHING` (Review Focus 4).

`test/core/sync/sync_control_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/account_settings_sync_adapter.dart';
import 'package:memox/core/sync/card_schedule_sync_adapter.dart';
import 'package:memox/core/sync/card_sync_adapter.dart';
import 'package:memox/core/sync/deck_sync_adapter.dart';
import 'package:memox/core/sync/delete_batch_sync_adapter.dart';
import 'package:memox/core/sync/review_log_sync_adapter.dart';
import 'package:memox/core/sync/sync_control.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_models.dart';
import 'package:memox/core/sync/sync_store.dart';
import 'package:memox/core/sync/tag_sync_adapter.dart';

import '../../support/test_database.dart';
import 'fake_sync_server.dart';

void main() {
  test('push all empties the outbox; pull all reads from version 0', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    final server = FakeSyncServer();
    final coordinator = SyncCoordinator(
      api: server,
      store: store,
      adapters: [
        DeleteBatchSyncAdapter(db),
        DeckSyncAdapter(db),
        TagSyncAdapter(db, store),
        CardSyncAdapter(db),
        CardScheduleSyncAdapter(db, store),
        ReviewLogSyncAdapter(db),
        AccountSettingsSyncAdapter(db),
      ],
    );
    final control = AppSyncControl(
      scheduler: null,
      coordinator: coordinator,
      store: store,
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
    );
    expect(await control.pendingCount(), 1);

    await control.pushPending();
    expect(await control.pendingCount(), 0);
    expect(server.row('tag', 't'), isNotNull);

    await store.setSince(99);
    await control.pullAll();
    expect(await store.since(), greaterThan(0));
  });

  test('a push that never reached the server is an OfflineFailure', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final store = SyncStore(db);
    final control = AppSyncControl(
      scheduler: null,
      coordinator: SyncCoordinator(
        api: _OfflineApi(),
        store: store,
        adapters: [TagSyncAdapter(db, store)],
      ),
      store: store,
    );
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 'T', 't', 0)",
    );

    await expectLater(control.pushPending(), throwsA(isA<OfflineFailure>()));
  });
}

class _OfflineApi extends FakeSyncServer {
  @override
  Future<PushResponseModel> push(PushRequestModel request) async =>
      throw const SocketException('down');
}
```

`TagSyncAdapter` and `CardScheduleSyncAdapter` default `now` to `DateTime.now`.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/sync/sync_scheduler_test.dart test/core/sync/sync_store_test.dart test/core/sync/sync_control_test.dart`
Expected: FAIL, with compile errors: `start(paused:)`, `isPaused`, `markAllPending`, `pendingCount` and `sync_control.dart` are not defined.

- [ ] **Step 3: Pause and resume in `SyncScheduler`**

Add the fields next to `_failures`:

```dart
  var _paused = false;

  /// Completed when the run in progress ends, for a [pause] waiting on it.
  Completer<void>? _idle;

  bool get isPaused => _paused;
```

Replace `start()`:

```dart
  /// Listens for triggers and reconnects. [paused] waits for [resume] before
  /// the first run: sync starts only once the account is confirmed (auth
  /// spec R2).
  void start({bool paused = false}) {
    _paused = paused;
    _subscriptions
      ..add(
        _triggers.listen((_) {
          if (_paused) return;
          // During a backoff a local write waits for the retry: offline, a
          // burst of edits must not hammer the server every 2 s.
          if (_failures == 0) {
            _schedule(debounce);
          }
        }),
      )
      ..add(
        _reconnects.listen((_) {
          if (_paused) return;
          _failures = 0;
          _schedule(Duration.zero);
        }),
      );
    if (!paused) _schedule(Duration.zero);
  }

  /// No run starts until [resume]. Completes once a run in progress has
  /// ended, so nothing is pushed after it returns (auth spec R3).
  Future<void> pause() {
    _paused = true;
    _timer?.cancel();
    if (!_running) return Future<void>.value();
    return (_idle ??= Completer<void>()).future;
  }

  /// Runs at once, then schedules as before; the backoff is forgotten.
  void resume() {
    if (!_paused) return;
    _paused = false;
    _failures = 0;
    _schedule(Duration.zero);
  }
```

At the top of `syncNow()`, add `if (_paused) return Future<bool>.value(false);`. At the top of `_schedule`, add `if (_paused) return;`. At the top of `_tick`, add `if (_paused) return;`.

Replace the `finally` block of `_tick`:

```dart
    } finally {
      _running = false;
      for (final waiter in waiting) {
        waiter.complete(succeeded);
      }
      final idle = _idle;
      _idle = null;
      idle?.complete();
      if (_paused) {
        for (final waiter in _waiters) {
          waiter.complete(false);
        }
        _waiters.clear();
      } else if (_waiters.isNotEmpty || (succeeded && _rerun)) {
        _schedule(Duration.zero);
      } else if (!succeeded) {
        _schedule(backoffFor(_failures));
      }
      _rerun = false;
    }
```

- [ ] **Step 4: Pending count and full push in `SyncStore`; push all and pull all in `SyncCoordinator`**

In `sync_store.dart`, import `package:memox/core/database/app_database.dart` (it may already be imported) and add:

```dart
  /// How many changes wait in the outbox (auth spec §5).
  Future<int> pendingCount() async => (await _db
          .customSelect(
            'SELECT COUNT(*) AS n FROM sync_outbox',
            readsFrom: {_db.syncOutbox},
          )
          .getSingle())
      .read<int>('n');

  /// Every local row queued for upload in the migrations' parents-first
  /// order, the settings row included, and the pull cursor back to 0: a new
  /// anonymous user gets the whole library (auth spec #12). A row already
  /// queued keeps its operation, so a rerun queues nothing twice (plan
  /// ruling 12).
  Future<void> markAllPending() => _db.transaction(() async {
    for (final (entityType, table, order) in _everyRow) {
      await _db.customStatement(
        '${seedOutboxSql(entityType, table, order)} '
        'ON CONFLICT (entity_type, entity_id) DO NOTHING',
      );
    }
    await setSince(0);
  });
```

At the bottom of the file:

```dart
/// Each synced type in the coordinator's adapter order, with the rows it
/// uploads and their order (the migrations' seeds, app_database.dart).
const _everyRow = [
  ('delete_batch', 'delete_batches', 'id'),
  ('deck', 'deck', 'depth, id'),
  ('tag', 'tags', 'created_at, id'),
  ('card', 'card', 'created_at, id'),
  ('card_schedule', '(SELECT card_id AS id FROM card_schedule)', 'id'),
  ('review_log', '(SELECT id, answered_at FROM review_log)', 'answered_at, id'),
  (
    'account_settings',
    "(SELECT '$accountSettingsEntityId' AS id FROM app_settings "
        'WHERE id = $appSettingsRowId)',
    'id',
  ),
];
```

In `sync_coordinator.dart`, add after `runOnce`:

```dart
  /// Pushes until the outbox is empty (auth spec #19, #39).
  Future<void> pushAll() async {
    await _push(await _store.deviceId());
  }

  /// The account's whole library, from version 0 (auth spec #28).
  Future<void> pullAll() async {
    await _store.setSince(0);
    await _pull();
  }
```

- [ ] **Step 5: `SyncControl`, and the providers**

`lib/core/sync/sync_control.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/sync/sync_coordinator.dart';
import 'package:memox/core/sync/sync_failure.dart';
import 'package:memox/core/sync/sync_scheduler.dart';
import 'package:memox/core/sync/sync_store.dart';

/// What the account coordinator needs from sync (auth spec §5).
abstract interface class SyncControl {
  /// No scheduled run starts; completes once a run in progress ended.
  Future<void> pause();

  void resume();

  Future<int> pendingCount();

  /// Pushes the outbox until it is empty.
  Future<void> pushPending();

  /// Pulls the whole library from version 0.
  Future<void> pullAll();

  /// Queues every local row, and the cursor back to 0 (#12).
  Future<void> markAllPending();
}

/// [SyncControl] over the app's scheduler, coordinator and store. A call
/// that never reached the server throws [OfflineFailure]; any other
/// transport error, [ServerFailure].
class AppSyncControl implements SyncControl {
  AppSyncControl({
    required SyncScheduler? scheduler,
    required SyncCoordinator coordinator,
    required SyncStore store,
  }) : _scheduler = scheduler,
       _coordinator = coordinator,
       _store = store;

  final SyncScheduler? _scheduler;
  final SyncCoordinator _coordinator;
  final SyncStore _store;

  @override
  Future<void> pause() => _scheduler?.pause() ?? Future<void>.value();

  @override
  void resume() => _scheduler?.resume();

  @override
  Future<int> pendingCount() => _store.pendingCount();

  @override
  Future<void> pushPending() => _mapped(_coordinator.pushAll);

  @override
  Future<void> pullAll() => _mapped(_coordinator.pullAll);

  @override
  Future<void> markAllPending() => _store.markAllPending();

  static Future<void> _mapped(Future<void> Function() call) async {
    try {
      await call();
    } on Failure {
      rethrow;
    } on Object catch (error, stackTrace) {
      final failure = classifySyncFailure(error) == SyncFailureKind.network
          ? OfflineFailure(cause: error)
          : ServerFailure(cause: error);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }
}
```

In `supabase_sync_api.dart`, add at the bottom:

```dart
/// A sync call with no session: the account has not signed in yet (auth
/// spec R2). Sync runs only once the account is confirmed, so this is a
/// bug, not a state.
final class SyncSessionMissing implements Exception {
  const SyncSessionMissing();

  @override
  String toString() => 'SyncSessionMissing: no session to sync with';
}
```

In `sync_providers.dart`:
- `syncApi` stops signing in (ruling 11):

```dart
/// Sync through the Supabase project main.dart initialized. It never signs
/// in: the account coordinator does, and resumes sync once `me()` confirms
/// the account (auth spec R2).
@Riverpod(keepAlive: true)
SyncApi syncApi(Ref ref) => SupabaseSyncApi(
  ensureSession: () async {
    if (!hasSupabaseSession()) throw const SyncSessionMissing();
  },
  rpc: supabaseRpc,
);
```

- In `syncScheduler`, replace `)..start();` with `)..start(paused: true);` and add the comment `// Paused until the account coordinator reaches Ready (auth spec R2).`
- Add:

```dart
/// What the account coordinator drives (auth spec §5).
@Riverpod(keepAlive: true)
SyncControl syncControl(Ref ref) => AppSyncControl(
  scheduler: ref.watch(syncSchedulerProvider),
  coordinator: ref.watch(syncCoordinatorProvider),
  store: ref.watch(syncStoreProvider),
);
```

In `supabase_client.dart`, delete `signInAnonymouslyForSync`.

- [ ] **Step 6: Run the tests to verify they pass**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/core/sync test/core/logging`
Expected: PASS. The existing scheduler, provider and log tests still pass: the log scheduler calls `start()` unpaused.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(sync): pause, resume, push all, pull all and full push for accounts

Sync no longer signs in and starts paused; the account coordinator resumes it.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

Until Task 14 wires the coordinator, a build with Supabase does not sync: the scheduler starts paused and nothing resumes it. Tasks 8–14 land in the same PR, so no release has this state. Leave a ledger note: `Task 7: Note: sync paused until Task 14 wires the coordinator (same PR)`.

### Task 8: Error classification and `AccountApi`

**Files:**
- Create: `lib/core/auth/supabase_auth_errors.dart`, `lib/core/auth/account_api.dart`, `lib/core/auth/supabase_account_api.dart`
- Test: `test/core/auth/supabase_auth_errors_test.dart`, `test/core/auth/supabase_account_api_test.dart`

**Interfaces:**
- Consumes: the Task 3 failures, `classifyRemoteError` and `rpcErrorCode` (Task 1), `supabaseRpc` (Task 1), and `RpcCall` (`core/sync/supabase_sync_api.dart`).
- Produces:
  - `Failure classifyAuthError(Object error, {IdentityMethod method = IdentityMethod.email})`
  - `bool isExpiredJwt(Object error)`
  - The interface `AccountApi { Future<AccountUser> me(); Future<String> claimBegin(); Future<void> merge(String token, String operationId); Future<void> mergeAck(String operationId); Future<void> deleteAccount(); }`. Every method throws a `Failure`.
  - `SupabaseAccountApi({required RpcCall rpc, required Future<void> Function() refreshSession})` and `SupabaseAccountApi.instance()`.

- [ ] **Step 1: Write the failing tests**

`test/core/auth/supabase_auth_errors_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Auth spec §3.2: the error classes, from GoTrue's codes and the RPCs'.
void main() {
  test('a call that never arrived is offline', () {
    expect(classifyAuthError(const SocketException('down')), isA<OfflineFailure>());
    expect(
      classifyAuthError(AuthRetryableFetchException(message: 'offline')),
      isA<OfflineFailure>(),
    );
  });

  test("GoTrue's codes", () {
    Failure of(String code, {IdentityMethod method = IdentityMethod.email}) =>
        classifyAuthError(AuthApiException('x', code: code), method: method);

    for (final code in [
      'refresh_token_not_found',
      'refresh_token_already_used',
      'session_not_found',
      'user_not_found',
    ]) {
      expect(of(code), isA<SessionInvalidFailure>(), reason: code);
    }
    expect(
      of('email_exists'),
      isA<IdentityTakenFailure>().having((f) => f.method, 'method', IdentityMethod.email),
    );
    expect(
      of('identity_already_exists', method: IdentityMethod.google),
      isA<IdentityTakenFailure>().having((f) => f.method, 'method', IdentityMethod.google),
    );
    expect(of('otp_expired'), isA<InvalidCodeFailure>());
    expect(of('over_email_send_rate_limit'), isA<RateLimitedFailure>());
    expect(
      classifyAuthError(const AuthApiException('x', statusCode: '429')),
      isA<RateLimitedFailure>(),
    );
    expect(classifyAuthError(AuthSessionMissingException()), isA<SessionInvalidFailure>());
    expect(of('unexpected_failure'), isA<ServerFailure>());
  });

  test("the RPCs' codes", () {
    Failure of(String code) =>
        classifyAuthError(PostgrestException(message: code, code: 'P0001'));

    expect(of('NOT_AUTHENTICATED'), isA<SessionInvalidFailure>());
    expect(of('UNAUTHORIZED'), isA<ProfileGoneFailure>());
    expect(of('CLAIM_INVALID'), isA<ClaimInvalidFailure>());
    expect(of('LAST_ADMIN'), isA<LastAdminFailure>());
    expect(of('ANONYMOUS_USER'), isA<AnonymousUserFailure>());
    expect(of('FORBIDDEN'), isA<NotAdminFailure>());
    expect(of('NOT_ANONYMOUS'), isA<ServerFailure>());
  });

  test('a failure passes through; an expired JWT is recognised', () {
    const failure = LastAdminFailure();
    expect(classifyAuthError(failure), same(failure));
    expect(isExpiredJwt(const PostgrestException(message: 'JWT expired', code: 'PGRST301')), isTrue);
    expect(isExpiredJwt(const PostgrestException(message: 'LAST_ADMIN', code: 'P0001')), isFalse);
  });
}
```

`test/core/auth/supabase_account_api_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/supabase_account_api.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  final calls = <(String, Map<String, Object?>)>[];
  late Object? Function(String function) answer;
  var refreshes = 0;
  late Future<void> Function() refresh;

  SupabaseAccountApi api() => SupabaseAccountApi(
    rpc: (function, params) async {
      calls.add((function, params));
      final result = answer(function);
      if (result is Exception) throw result;
      return result;
    },
    refreshSession: () {
      refreshes++;
      return refresh();
    },
  );

  setUp(() {
    calls.clear();
    refreshes = 0;
    refresh = () async {};
  });

  test('me reads the account', () async {
    answer = (_) => {
      'id': 'u1',
      'email': 'a@example.com',
      'isAnonymous': false,
      'role': 'admin',
    };

    expect(
      await api().me(),
      const AccountUser(
        id: 'u1',
        email: 'a@example.com',
        isAnonymous: false,
        role: AccountRole.admin,
      ),
    );
    expect(calls.single.$1, 'me');
  });

  test('the claim, the merge, the ack and the deletion call their RPCs', () async {
    answer = (function) => switch (function) {
      'account_claim_begin' => 'token-1',
      'account_merge' => {'status': 'MERGED'},
      _ => null,
    };
    final a = api();

    expect(await a.claimBegin(), 'token-1');
    await a.merge('token-1', 'op-1');
    await a.mergeAck('op-1');
    await a.deleteAccount();

    expect(calls.map((c) => c.$1), [
      'account_claim_begin',
      'account_merge',
      'account_merge_ack',
      'account_delete',
    ]);
    expect(calls[1].$2, {'p_token': 'token-1', 'p_operation_id': 'op-1'});
    expect(calls[2].$2, {'p_operation_id': 'op-1'});
  });

  test('errors leave as failures', () async {
    answer = (_) => const PostgrestException(message: 'LAST_ADMIN', code: 'P0001');
    await expectLater(api().deleteAccount(), throwsA(isA<LastAdminFailure>()));
    answer = (_) => const SocketException('down');
    await expectLater(api().me(), throwsA(isA<OfflineFailure>()));
  });

  test('an expired JWT is refreshed once and the call retried', () async {
    var first = true;
    answer = (_) {
      if (first) {
        first = false;
        return const PostgrestException(message: 'JWT expired', code: 'PGRST301');
      }
      return {'id': 'u1', 'email': null, 'isAnonymous': true, 'role': 'user'};
    };

    final me = await api().me();

    expect(me.id, 'u1');
    expect(refreshes, 1);
    expect(calls, hasLength(2));
  });

  test('a refresh the server refuses is a lost session', () async {
    answer = (_) => const PostgrestException(message: 'JWT expired', code: 'PGRST301');
    refresh = () async =>
        throw const AuthApiException('gone', code: 'refresh_token_not_found');

    await expectLater(api().me(), throwsA(isA<SessionInvalidFailure>()));
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/auth/supabase_auth_errors_test.dart test/core/auth/supabase_account_api_test.dart`
Expected: FAIL, with compile errors: the files do not exist.

- [ ] **Step 3: Write the classifier**

`lib/core/auth/supabase_auth_errors.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/network/remote_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The one mapping from GoTrue's and the account RPCs' errors to the app's
/// [Failure]s (auth spec §3.2). [method] says which identity a "taken"
/// answer is about.
Failure classifyAuthError(
  Object error, {
  IdentityMethod method = IdentityMethod.email,
}) {
  if (error is Failure) return error;
  if (classifyRemoteError(error) == RemoteErrorKind.network) {
    return OfflineFailure(cause: error);
  }
  if (error is AuthException) return _fromAuth(error, method);
  return switch (rpcErrorCode(error)) {
    'NOT_AUTHENTICATED' => SessionInvalidFailure(cause: error),
    'UNAUTHORIZED' => ProfileGoneFailure(cause: error),
    'CLAIM_INVALID' => ClaimInvalidFailure(cause: error),
    'LAST_ADMIN' => LastAdminFailure(cause: error),
    'ANONYMOUS_USER' => AnonymousUserFailure(cause: error),
    'FORBIDDEN' => NotAdminFailure(cause: error),
    _ => ServerFailure(cause: error),
  };
}

Failure _fromAuth(AuthException error, IdentityMethod method) {
  if (error is AuthSessionMissingException) {
    return SessionInvalidFailure(cause: error);
  }
  return switch (error.code) {
    'refresh_token_not_found' ||
    'refresh_token_already_used' ||
    'session_not_found' ||
    'user_not_found' => SessionInvalidFailure(cause: error),
    'email_exists' ||
    'identity_already_exists' => IdentityTakenFailure(method: method, cause: error),
    // GoTrue answers a wrong and an expired code alike (plan ruling 2).
    'otp_expired' => InvalidCodeFailure(cause: error),
    'over_email_send_rate_limit' ||
    'over_request_rate_limit' => RateLimitedFailure(cause: error),
    _ when error.statusCode == '429' => RateLimitedFailure(cause: error),
    _ => ServerFailure(cause: error),
  };
}

/// PostgREST refused the access token as expired or invalid. The SDK
/// refreshes on a timer; a call that lands in between refreshes once.
bool isExpiredJwt(Object error) =>
    error is PostgrestException &&
    (error.code == 'PGRST301' || error.code == 'PGRST303');
```

- [ ] **Step 4: Write the API**

`lib/core/auth/account_api.dart`:

```dart
import 'package:memox/core/auth/account_user.dart';

/// The account RPCs of migration 20261010 (auth spec §2.3). Every method
/// throws a `Failure`.
abstract interface class AccountApi {
  /// The caller's account; also marks it active.
  Future<AccountUser> me();

  /// A one-time token for this anonymous user's data (15 minutes).
  Future<String> claimBegin();

  /// Moves the claimed user's data into the caller's account; idempotent by
  /// [operationId] (a retry after a lost answer succeeds).
  Future<void> merge(String token, String operationId);

  /// The device has pulled the merged library; the receipt can go.
  Future<void> mergeAck(String operationId);

  Future<void> deleteAccount();
}
```

`lib/core/auth/supabase_account_api.dart`:

```dart
import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/network/supabase_client.dart';
import 'package:memox/core/sync/supabase_sync_api.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AccountApi] over Supabase RPC. Its errors leave through
/// [classifyAuthError].
class SupabaseAccountApi implements AccountApi {
  SupabaseAccountApi({
    required RpcCall rpc,
    required Future<void> Function() refreshSession,
  }) : _rpc = rpc,
       _refreshSession = refreshSession;

  /// On the client main.dart initialized.
  factory SupabaseAccountApi.instance() => SupabaseAccountApi(
    rpc: supabaseRpc,
    refreshSession: () async {
      await Supabase.instance.client.auth.refreshSession();
    },
  );

  final RpcCall _rpc;
  final Future<void> Function() _refreshSession;

  @override
  Future<AccountUser> me() async {
    final json = (await _call('me', const {}))! as Map<String, Object?>;
    return AccountUser(
      id: json['id']! as String,
      email: json['email'] as String?,
      isAnonymous: json['isAnonymous'] == true,
      role: AccountRole.parse(json['role'] as String?),
    );
  }

  @override
  Future<String> claimBegin() async =>
      (await _call('account_claim_begin', const {}))! as String;

  @override
  Future<void> merge(String token, String operationId) =>
      _call('account_merge', {'p_token': token, 'p_operation_id': operationId});

  @override
  Future<void> mergeAck(String operationId) =>
      _call('account_merge_ack', {'p_operation_id': operationId});

  @override
  Future<void> deleteAccount() => _call('account_delete', const {});

  Future<Object?> _call(String function, Map<String, Object?> params) async {
    try {
      return await _callRefreshingOnce(function, params);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(classifyAuthError(error), stackTrace);
    }
  }

  Future<Object?> _callRefreshingOnce(
    String function,
    Map<String, Object?> params,
  ) async {
    try {
      return await _rpc(function, params);
    } on Object catch (error) {
      if (!isExpiredJwt(error)) rethrow;
      await _refreshSession();
      return _rpc(function, params);
    }
  }
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `flutter test test/core/auth`
Expected: PASS.

- [ ] **Step 6: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(auth): the account RPC client and one error classification

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 9: `AuthGateway` over GoTrue, and the Google picker

**Files:**
- Create: `lib/core/auth/auth_gateway.dart`, `lib/core/auth/supabase_auth_gateway.dart`, `lib/core/auth/google_credential_source.dart`
- Modify: `pubspec.yaml`, `pubspec.lock` (`google_sign_in`)
- Test: `test/core/auth/supabase_auth_gateway_test.dart`

**Interfaces:**
- Consumes: `classifyAuthError` (Task 8).
- Produces:
  - `GoogleCredential({required String idToken, String? accessToken, String? email})`.
  - The interface `AuthGateway`, with:
    - `String? get currentUserId`, `Stream<String?> get userIds`, `String? get refreshToken`
    - `Future<void> signInAnonymously()`
    - `requestEmailLink(String email)` and `verifyEmailLink(String email, String code)`
    - `requestEmailSignIn(String email)` and `verifyEmailSignIn(String email, String code)`
    - `Future<GoogleCredential> pickGoogle()`, `linkGoogle(GoogleCredential)`, `signInGoogle(GoogleCredential)`
    - `restoreSession(String refreshToken)`, `signOutLocal()`

    Every method throws a `Failure`.
  - `SupabaseAuthGateway(GoTrueClient auth, {required Future<GoogleCredential> Function() pickGoogle})` and `SupabaseAuthGateway.instance({required pickGoogle})`.
  - `GoogleCredentialSource({String serverClientId})`, with `Future<GoogleCredential> pick()`.

- [ ] **Step 1: Add the package**

Run: `flutter pub add google_sign_in:^7.2.0`
Expected: `flutter pub get` succeeds.

Read the resolved package's `README.md` and `lib/google_sign_in.dart` (`~/.pub-cache/hosted/pub.dev/google_sign_in-<version>/`). Confirm these names before Step 5:
- `GoogleSignIn.instance`
- `initialize(serverClientId:)`
- `authenticate()`
- `account.authentication.idToken`
- `account.authorizationClient.authorizationForScopes(List<String>)`, returning an object with `accessToken`
- `GoogleSignInException.code == GoogleSignInExceptionCode.canceled`

If a name differs, use the package's name and ledger the ruling.

- [ ] **Step 2: Write the failing test**

`test/core/auth/supabase_auth_gateway_test.dart`:

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// The gateway over a real GoTrueClient and a fake HTTP server: its answers
// become the app's types and failures (auth spec §5, plan ruling 16).
Map<String, Object?> _session(String id, {bool anonymous = true}) => {
  'access_token': 'access-$id',
  'token_type': 'bearer',
  'expires_in': 3600,
  'expires_at': DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
  'refresh_token': 'refresh-$id',
  'user': {
    'id': id,
    'aud': 'authenticated',
    'role': 'authenticated',
    'is_anonymous': anonymous,
    'created_at': '2026-09-30T00:00:00Z',
    'app_metadata': <String, Object?>{},
    'user_metadata': <String, Object?>{},
  },
};

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late Future<http.Response> Function(http.Request request) server;

  SupabaseAuthGateway gateway() => SupabaseAuthGateway(
    GoTrueClient(
      url: 'http://auth.test/auth/v1',
      httpClient: MockClient((request) => server(request)),
      flowType: AuthFlowType.implicit,
      autoRefreshToken: false,
    ),
    pickGoogle: () async => const GoogleCredential(idToken: 'id', email: 'g@example.com'),
  );

  test('an anonymous sign-in gives a user id, a refresh token and an event', () async {
    server = (request) async => _json(_session('u1'));
    final g = gateway();
    final ids = <String?>[];
    final subscription = g.userIds.listen(ids.add);
    addTearDown(subscription.cancel);

    await g.signInAnonymously();
    await pumpEventQueue();

    expect(g.currentUserId, 'u1');
    expect(g.refreshToken, 'refresh-u1');
    expect(ids, contains('u1'));
  });

  test('a Google identity of another account is IdentityTaken(google)', () async {
    server = (request) async =>
        _json({'error_code': 'identity_already_exists', 'msg': 'taken'}, 422);

    await expectLater(
      gateway().linkGoogle(const GoogleCredential(idToken: 'id')),
      throwsA(
        isA<IdentityTakenFailure>().having((f) => f.method, 'method', IdentityMethod.google),
      ),
    );
  });

  test('a refused code is InvalidCode; a flood is RateLimited', () async {
    server = (request) async =>
        _json({'error_code': 'otp_expired', 'msg': 'Token has expired or is invalid'}, 403);
    await expectLater(
      gateway().verifyEmailSignIn('a@example.com', '000000'),
      throwsA(isA<InvalidCodeFailure>()),
    );

    server = (request) async =>
        _json({'error_code': 'over_email_send_rate_limit', 'msg': 'slow down'}, 429);
    await expectLater(
      gateway().requestEmailSignIn('a@example.com'),
      throwsA(isA<RateLimitedFailure>()),
    );
  });

  test('sign-out offline still leaves no session', () async {
    var signedIn = false;
    server = (request) async {
      if (!signedIn) {
        signedIn = true;
        return _json(_session('u1'));
      }
      throw const SocketException('down');
    };
    final g = gateway();
    await g.signInAnonymously();

    await g.signOutLocal();

    expect(g.currentUserId, isNull);
    expect(g.refreshToken, isNull);
  });

  test('a network error is offline', () async {
    server = (request) async => throw const SocketException('down');

    await expectLater(gateway().signInAnonymously(), throwsA(isA<OfflineFailure>()));
  });
}
```

`http/testing.dart` ships with the `http` package the app already depends on.

- [ ] **Step 3: Run it to verify it fails**

Run: `flutter test test/core/auth/supabase_auth_gateway_test.dart`
Expected: FAIL, with a compile error: `auth_gateway.dart` does not exist.

- [ ] **Step 4: Write the port and its GoTrue implementation**

`lib/core/auth/auth_gateway.dart`:

```dart
/// A Google account picked on the device (auth spec O11). Held in memory
/// only, and never logged: [toString] names no token.
final class GoogleCredential {
  const GoogleCredential({required this.idToken, this.accessToken, this.email});

  final String idToken;
  final String? accessToken;
  final String? email;

  @override
  String toString() => 'GoogleCredential(${email ?? 'unknown'})';
}

/// Who is signed in, and every way to change that (auth spec §5). The SDK
/// is the truth about the session (R1). Every method throws a `Failure`.
abstract interface class AuthGateway {
  String? get currentUserId;

  /// The SDK's user id on every auth event, null once it holds no session.
  Stream<String?> get userIds;

  String? get refreshToken;

  Future<void> signInAnonymously();

  /// Attaches [email] to the current anonymous user: a code goes to it.
  Future<void> requestEmailLink(String email);

  Future<void> verifyEmailLink(String email, String code);

  /// Signs in to [email]'s account, creating it if needed: a code goes to
  /// it.
  Future<void> requestEmailSignIn(String email);

  Future<void> verifyEmailSignIn(String email, String code);

  Future<GoogleCredential> pickGoogle();

  /// Attaches the Google identity to the current anonymous user.
  Future<void> linkGoogle(GoogleCredential credential);

  Future<void> signInGoogle(GoogleCredential credential);

  /// Back to the account of [refreshToken] (#25, #33).
  Future<void> restoreSession(String refreshToken);

  /// Drops the session on this device, even offline.
  Future<void> signOutLocal();
}
```

`lib/core/auth/supabase_auth_gateway.dart`:

```dart
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/supabase_auth_errors.dart';
import 'package:memox/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [AuthGateway] over GoTrue (auth spec §5, O11). The one place that touches
/// Supabase's `User` and `Session`; only ids and tokens leave it.
class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(
    this._auth, {
    required Future<GoogleCredential> Function() pickGoogle,
  }) : _pickGoogle = pickGoogle;

  /// On the client main.dart initialized.
  factory SupabaseAuthGateway.instance({
    required Future<GoogleCredential> Function() pickGoogle,
  }) => SupabaseAuthGateway(
    Supabase.instance.client.auth,
    pickGoogle: pickGoogle,
  );

  final GoTrueClient _auth;
  final Future<GoogleCredential> Function() _pickGoogle;

  @override
  String? get currentUserId => _auth.currentSession?.user.id;

  @override
  Stream<String?> get userIds =>
      _auth.onAuthStateChange.map((state) => state.session?.user.id);

  @override
  String? get refreshToken => _auth.currentSession?.refreshToken;

  @override
  Future<void> signInAnonymously() => _guard(_auth.signInAnonymously);

  @override
  Future<void> requestEmailLink(String email) =>
      _guard(() => _auth.updateUser(UserAttributes(email: email)));

  @override
  Future<void> verifyEmailLink(String email, String code) => _guard(
    () => _auth.verifyOTP(type: OtpType.emailChange, email: email, token: code),
  );

  @override
  Future<void> requestEmailSignIn(String email) =>
      _guard(() => _auth.signInWithOtp(email: email, shouldCreateUser: true));

  @override
  Future<void> verifyEmailSignIn(String email, String code) => _guard(
    () => _auth.verifyOTP(type: OtpType.email, email: email, token: code),
  );

  @override
  Future<GoogleCredential> pickGoogle() => _pickGoogle();

  @override
  Future<void> linkGoogle(GoogleCredential credential) => _guard(
    () => _auth.linkIdentityWithIdToken(
      provider: OAuthProvider.google,
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    ),
    method: IdentityMethod.google,
  );

  @override
  Future<void> signInGoogle(GoogleCredential credential) => _guard(
    () => _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: credential.idToken,
      accessToken: credential.accessToken,
    ),
    method: IdentityMethod.google,
  );

  @override
  Future<void> restoreSession(String refreshToken) =>
      _guard(() => _auth.setSession(refreshToken));

  /// GoTrue drops the session before it tells the server. When the server
  /// cannot be reached, the device is signed out all the same, which is
  /// what matters here.
  @override
  Future<void> signOutLocal() async {
    try {
      await _auth.signOut();
    } on Object catch (error, stackTrace) {
      if (_auth.currentSession == null) return;
      Error.throwWithStackTrace(classifyAuthError(error), stackTrace);
    }
  }

  static Future<void> _guard(
    Future<Object?> Function() call, {
    IdentityMethod method = IdentityMethod.email,
  }) async {
    try {
      await call();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(
        classifyAuthError(error, method: method),
        stackTrace,
      );
    }
  }
}
```

- [ ] **Step 5: Write the Google picker**

`lib/core/auth/google_credential_source.dart`:

```dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/error/failure.dart';

/// Picks a Google account natively and returns its tokens for GoTrue (auth
/// spec O11). [serverClientId] is the Web OAuth client of SB-A4, from
/// `--dart-define=GOOGLE_WEB_CLIENT_ID=…`. The device check covers it, not a
/// unit test (plan ruling 17).
class GoogleCredentialSource {
  GoogleCredentialSource({
    this.serverClientId = const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
  });

  final String serverClientId;
  Future<void>? _initialized;

  Future<GoogleCredential> pick() async {
    final google = GoogleSignIn.instance;
    try {
      await (_initialized ??= google.initialize(
        serverClientId: serverClientId.isEmpty ? null : serverClientId,
      ));
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const ServerFailure(cause: 'Google returned no id token');
      }
      final authorization = await account.authorizationClient
          .authorizationForScopes(const ['email']);
      return GoogleCredential(
        idToken: idToken,
        accessToken: authorization?.accessToken,
        email: account.email,
      );
    } on GoogleSignInException catch (error, stackTrace) {
      final failure = error.code == GoogleSignInExceptionCode.canceled
          ? GoogleCancelledFailure(cause: error)
          : ServerFailure(cause: error);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/core/auth`
Expected: PASS. If GoTrue's session parsing needs another field in `_session`, add it to the fixture. The fixture is test data; the assertions stay as written.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add pubspec.yaml pubspec.lock lib test
git commit -m "feat(auth): the identity gateway over GoTrue and the native Google picker

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 10: `AccountCoordinator` core — start, validation, anonymous recovery (#1–#12, #14, #15)

**Files:**
- Create:
  - `lib/core/network/network_status.dart`
  - `lib/core/auth/account_coordinator.dart`
  - `test/support/auth_fakes.dart`
- Test: `test/core/auth/account_coordinator_start_test.dart`

**Interfaces:**
- Consumes: everything in Tasks 3–9 (`AccountStore`, `SecretStore`, `purgeAccountSecrets`, `backupSecretKey`, `claimSecretKey`, `MutationGate`, `LocalDataReset`, `SyncControl`, `AccountApi`, `AuthGateway`, the failures and the states).
- Produces:
  - The interface `NetworkStatus { Future<bool> get isOnline; Stream<void> get reconnects; }`.
  - `ConnectivityNetworkStatus([Connectivity? connectivity])`.
  - `AccountCoordinator({required gateway, api, store, secrets, sync, localReset, gate, network, Future<void> Function()? flushLogs, String Function() newOpId, DateTime Function() now, AppLogger? logger})`, with:
    - `AuthState get state`, `Stream<AuthState> watch()`, `Stream<AccountNotice> get notices`
    - `Future<void> prepare()`, `Future<void> start()`, `Future<void> retry()`, `Future<void> dispose()`
  - Tasks 11 and 12 add the commands.
  - Test side, in `test/support/auth_fakes.dart`:
    - `Killed` and `KillSwitch`
    - `FakeUser`, `FakeAuthServer`, `FakeAuthGateway`, `FakeAccountApi`
    - `FakeDevice`, `FakeSyncControl`, `FakeLocalDataReset`, `KillableAccountStore`, `FakeNetworkStatus`
    - `AuthWorld` and `readyAnonymous(AuthWorld)`

- [ ] **Step 1: Write the network port**

`lib/core/network/network_status.dart`:

```dart
import 'package:connectivity_plus/connectivity_plus.dart';

/// Whether the device has a network, and when it comes back (auth spec
/// §6). A hint only: a call can still fail offline, and that is handled
/// where it fails.
abstract interface class NetworkStatus {
  Future<bool> get isOnline;

  Stream<void> get reconnects;
}

class ConnectivityNetworkStatus implements NetworkStatus {
  ConnectivityNetworkStatus([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async => (await _connectivity.checkConnectivity())
      .any((result) => result != ConnectivityResult.none);

  @override
  Stream<void> get reconnects => _connectivity.onConnectivityChanged
      .where((results) => !results.contains(ConnectivityResult.none))
      .map((_) {});
}
```

- [ ] **Step 2: Write the fakes**

`test/support/auth_fakes.dart`. Tasks 10–13 use the whole file.

```dart
import 'dart:async';
import 'dart:math' as math;

import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_gateway.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/database/mutation_gate.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/sync_control.dart';

import 'fake_secret_store.dart';
import 'test_database.dart';

/// The app killed at a step (auth spec §9, crash injection).
final class Killed implements Exception {
  const Killed();

  @override
  String toString() => 'Killed';
}

/// Every fake call is one step. [at] kills the flow at that step;
/// [offlineAt] cuts the network from that step on (spec §9, "Network").
class KillSwitch {
  int? at;
  int? offlineAt;
  FakeAuthServer? server;
  var steps = 0;

  void step() {
    steps++;
    if (offlineAt != null && steps == offlineAt) server!.offline = true;
    if (at != null && steps == at) throw const Killed();
  }
}

class FakeUser {
  FakeUser(
    this.id, {
    this.email,
    this.isAnonymous = false,
    this.role = AccountRole.user,
  });

  final String id;
  String? email;
  bool isAnonymous;
  AccountRole role;
}

/// GoTrue and the account RPCs, in memory.
class FakeAuthServer {
  final users = <String, FakeUser>{};

  /// Refresh token → user id.
  final refreshTokens = <String, String>{};

  /// Claim token → source user id.
  final claims = <String, String>{};
  final receipts =
      <String, ({String source, String target, bool acknowledged})>{};
  final sentCodes = <String, String>{};
  var offline = false;
  var anonymousCreated = 0;
  var _next = 0;

  /// Runs right after a merge commits and before it answers.
  void Function()? afterMergeCommit;

  String nextId(String prefix) => '$prefix${_next++}';

  FakeUser addUser({
    String? email,
    bool anonymous = false,
    AccountRole role = AccountRole.user,
  }) {
    final user = FakeUser(
      nextId(anonymous ? 'anon-' : 'user-'),
      email: email,
      isAnonymous: anonymous,
      role: role,
    );
    users[user.id] = user;
    if (anonymous) anonymousCreated++;
    return user;
  }

  String issueToken(String userId) {
    final token = nextId('rt-');
    refreshTokens[token] = userId;
    return token;
  }

  void revokeTokensOf(String userId) =>
      refreshTokens.removeWhere((_, id) => id == userId);

  void deleteUser(String userId) {
    users.remove(userId);
    revokeTokensOf(userId);
    claims.removeWhere((_, id) => id == userId);
  }

  FakeUser? userByEmail(String email) =>
      users.values.where((user) => user.email == email).firstOrNull;

  void checkOnline() {
    if (offline) throw const OfflineFailure(cause: 'fake offline');
  }
}

/// The SDK. Its session survives a restart, as SharedPreferences does.
class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway(this.server);

  static const code = '123456';

  final FakeAuthServer server;
  KillSwitch? kill;
  String? _userId;
  String? _refreshToken;
  final _ids = StreamController<String?>.broadcast();

  /// Every user id the SDK held, in order.
  final history = <String?>[];
  GoogleCredential google = const GoogleCredential(
    idToken: 'google-id-token',
    email: 'g@example.com',
  );
  var googleCancels = false;

  /// Runs right after a target sign-in succeeds, before it returns.
  void Function()? afterSignIn;

  void _set(String? userId) {
    _userId = userId;
    _refreshToken = userId == null ? null : server.issueToken(userId);
    history.add(userId);
    _ids.add(userId);
  }

  /// Test setup: the SDK already holds [userId]'s session.
  void adopt(String userId) => _set(userId);

  /// The server refused the refresh token and the SDK dropped the session on
  /// its own (Review Focus 1).
  void dropSession() {
    server.revokeTokensOf(_userId!);
    _set(null);
  }

  /// The SDK lost its session without telling the server (a cleared app
  /// store, a kill mid-write): the refresh tokens stay valid.
  void forgetSession() => _set(null);

  @override
  String? get currentUserId => _userId;

  @override
  Stream<String?> get userIds => _ids.stream;

  @override
  String? get refreshToken => _refreshToken;

  @override
  Future<void> signInAnonymously() async {
    kill?.step();
    server.checkOnline();
    _set(server.addUser(anonymous: true).id);
  }

  @override
  Future<void> requestEmailLink(String email) async {
    kill?.step();
    server.checkOnline();
    final owner = server.userByEmail(email);
    if (owner != null && owner.id != _userId) {
      throw const IdentityTakenFailure(method: IdentityMethod.email);
    }
    server.sentCodes[email] = code;
  }

  @override
  Future<void> verifyEmailLink(String email, String code) async {
    kill?.step();
    server.checkOnline();
    _checkCode(email, code);
    server.users[_userId]!
      ..email = email
      ..isAnonymous = false;
    _ids.add(_userId);
  }

  @override
  Future<void> requestEmailSignIn(String email) async {
    kill?.step();
    server.checkOnline();
    server.sentCodes[email] = code;
  }

  @override
  Future<void> verifyEmailSignIn(String email, String code) async {
    kill?.step();
    server.checkOnline();
    _checkCode(email, code);
    _set((server.userByEmail(email) ?? server.addUser(email: email)).id);
    afterSignIn?.call();
  }

  @override
  Future<GoogleCredential> pickGoogle() async {
    kill?.step();
    if (googleCancels) throw const GoogleCancelledFailure();
    return google;
  }

  @override
  Future<void> linkGoogle(GoogleCredential credential) async {
    kill?.step();
    server.checkOnline();
    final owner = server.userByEmail(credential.email!);
    if (owner != null && owner.id != _userId) {
      throw const IdentityTakenFailure(method: IdentityMethod.google);
    }
    server.users[_userId]!
      ..email = credential.email
      ..isAnonymous = false;
    _ids.add(_userId);
  }

  @override
  Future<void> signInGoogle(GoogleCredential credential) async {
    kill?.step();
    server.checkOnline();
    final email = credential.email!;
    _set((server.userByEmail(email) ?? server.addUser(email: email)).id);
    afterSignIn?.call();
  }

  @override
  Future<void> restoreSession(String refreshToken) async {
    kill?.step();
    server.checkOnline();
    final userId = server.refreshTokens.remove(refreshToken);
    if (userId == null || !server.users.containsKey(userId)) {
      throw const SessionInvalidFailure();
    }
    _set(userId);
  }

  @override
  Future<void> signOutLocal() async {
    kill?.step();
    final userId = _userId;
    _set(null);
    if (userId != null && !server.offline) server.revokeTokensOf(userId);
  }

  void _checkCode(String email, String code) {
    if (server.sentCodes[email] != code) throw const InvalidCodeFailure();
  }
}

class FakeAccountApi implements AccountApi {
  FakeAccountApi(this.server, this.gateway);

  final FakeAuthServer server;
  final FakeAuthGateway gateway;
  KillSwitch? kill;
  var meCalls = 0;

  FakeUser _caller() {
    final id = gateway.currentUserId;
    if (id == null) throw const SessionInvalidFailure();
    return server.users[id] ?? (throw const ProfileGoneFailure());
  }

  @override
  Future<AccountUser> me() async {
    kill?.step();
    server.checkOnline();
    meCalls++;
    final user = _caller();
    return AccountUser(
      id: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
      role: user.role,
    );
  }

  @override
  Future<String> claimBegin() async {
    kill?.step();
    server.checkOnline();
    final user = _caller();
    if (!user.isAnonymous) throw const ServerFailure(cause: 'NOT_ANONYMOUS');
    server.claims.removeWhere((_, id) => id == user.id);
    final token = server.nextId('claim-');
    server.claims[token] = user.id;
    return token;
  }

  @override
  Future<void> merge(String token, String operationId) async {
    kill?.step();
    server.checkOnline();
    final target = _caller();
    final receipt = server.receipts[operationId];
    if (receipt != null && receipt.target == target.id) return;
    final source = server.claims.remove(token);
    if (source == null ||
        source == target.id ||
        !(server.users[source]?.isAnonymous ?? false)) {
      throw const ClaimInvalidFailure();
    }
    server.receipts[operationId] = (
      source: source,
      target: target.id,
      acknowledged: false,
    );
    server.deleteUser(source);
    server.afterMergeCommit?.call();
  }

  @override
  Future<void> mergeAck(String operationId) async {
    kill?.step();
    server.checkOnline();
    final target = _caller();
    final receipt = server.receipts[operationId];
    if (receipt == null || receipt.target != target.id) return;
    server.receipts[operationId] = (
      source: receipt.source,
      target: receipt.target,
      acknowledged: true,
    );
  }

  @override
  Future<void> deleteAccount() async {
    kill?.step();
    server.checkOnline();
    final user = _caller();
    final admins = server.users.values
        .where((u) => u.role == AccountRole.admin)
        .length;
    if (user.role == AccountRole.admin && admins <= 1) {
      throw const LastAdminFailure();
    }
    server.deleteUser(user.id);
  }
}

/// What the device holds; it survives a restart, as Drift does.
class FakeDevice {
  /// Whose library is on the device; null when it holds none.
  String? owner;
  var rows = 0;
  var pending = 0;
  final pushes = <({String? signedIn, String? owner})>[];
  final pulls = <String?>[];
  var resets = 0;
  var markAllPendingCalls = 0;
}

class FakeSyncControl implements SyncControl {
  FakeSyncControl(this.device, this.gateway, this.server);

  final FakeDevice device;
  final FakeAuthGateway gateway;
  final FakeAuthServer server;
  KillSwitch? kill;
  var paused = true;
  var resumes = 0;

  @override
  Future<void> pause() async => paused = true;

  @override
  void resume() {
    paused = false;
    resumes++;
  }

  @override
  Future<int> pendingCount() async => device.pending;

  @override
  Future<void> pushPending() async {
    kill?.step();
    server.checkOnline();
    device.pushes.add((signedIn: gateway.currentUserId, owner: device.owner));
    device.pending = 0;
  }

  @override
  Future<void> pullAll() async {
    kill?.step();
    server.checkOnline();
    device.pulls.add(gateway.currentUserId);
    device.owner = gateway.currentUserId;
  }

  @override
  Future<void> markAllPending() async {
    kill?.step();
    device
      ..markAllPendingCalls += 1
      ..owner = gateway.currentUserId
      ..pending = math.max(device.pending, device.rows);
  }
}

class FakeLocalDataReset implements LocalDataReset {
  FakeLocalDataReset(this.device);

  final FakeDevice device;
  KillSwitch? kill;

  @override
  Future<void> run() async {
    kill?.step();
    device
      ..resets += 1
      ..owner = null
      ..rows = 0
      ..pending = 0;
  }
}

/// The real Drift store, each write one step of the kill switch.
class KillableAccountStore extends AccountStore {
  KillableAccountStore(super.db, this.kill);

  final KillSwitch kill;

  @override
  Future<AccountTransition> saveTransition(AccountTransition t) {
    kill.step();
    return super.saveTransition(t);
  }

  @override
  Future<void> clearTransition() {
    kill.step();
    return super.clearTransition();
  }

  @override
  Future<void> saveLastKnown(AccountUser user, DateTime at) {
    kill.step();
    return super.saveLastKnown(user, at);
  }

  @override
  Future<void> clearLastKnown() {
    kill.step();
    return super.clearLastKnown();
  }
}

class FakeNetworkStatus implements NetworkStatus {
  FakeNetworkStatus(this.server);

  final FakeAuthServer server;

  /// What the OS says, when it differs from what the server answers.
  bool? claimsOnline;
  final _reconnects = StreamController<void>.broadcast();

  @override
  Future<bool> get isOnline async => claimsOnline ?? !server.offline;

  @override
  Stream<void> get reconnects => _reconnects.stream;

  void goOffline() => server.offline = true;

  void goOnline() {
    server.offline = false;
    _reconnects.add(null);
  }
}

/// One device and one server. [boot] launches the app: the server, the
/// SDK's session, Drift, the secrets and the device's library survive it;
/// the coordinator, the gate and sync's run state do not.
class AuthWorld {
  AuthWorld() {
    kill.server = server;
    gateway = FakeAuthGateway(server)..kill = kill;
    api = FakeAccountApi(server, gateway)..kill = kill;
    secrets.onCall = kill.step;
    network = FakeNetworkStatus(server);
  }

  final server = FakeAuthServer();
  final kill = KillSwitch();
  final device = FakeDevice();
  final AppDatabase db = openTestDatabase();
  final secrets = FakeSecretStore();
  final notices = <AccountNotice>[];
  late final FakeAuthGateway gateway;
  late final FakeAccountApi api;
  late final FakeNetworkStatus network;
  late FakeSyncControl sync;
  late MutationGate gate;
  AccountCoordinator? _coordinator;
  var _opIds = 0;

  /// How often a sign-out shipped the logs (#39).
  var logFlushes = 0;

  AccountCoordinator get coordinator => _coordinator!;

  AuthState get state => coordinator.state;

  /// A store that is not killable, for the test's own reads and setup.
  AccountStore get store => AccountStore(db);

  AccountCoordinator boot() {
    final previous = _coordinator;
    if (previous != null) unawaited(previous.dispose());
    gate = MutationGate();
    sync = FakeSyncControl(device, gateway, server)..kill = kill;
    final coordinator = AccountCoordinator(
      gateway: gateway,
      api: api,
      store: KillableAccountStore(db, kill),
      secrets: secrets,
      sync: sync,
      localReset: FakeLocalDataReset(device)..kill = kill,
      gate: gate,
      network: network,
      flushLogs: () async => logFlushes++,
      newOpId: () => 'op-${_opIds++}',
      logger: AppLogger(sinks: const []),
    );
    coordinator.notices.listen(notices.add);
    return _coordinator = coordinator;
  }

  Future<void> close() async {
    await _coordinator?.dispose();
    await db.close();
  }
}

/// A launched device on its first anonymous user, with [rows] local rows of
/// which [pending] are not sent.
Future<String> readyAnonymous(
  AuthWorld world, {
  int rows = 3,
  int pending = 2,
}) async {
  world.boot();
  await world.coordinator.start();
  final id = world.gateway.currentUserId!;
  world.device
    ..owner = id
    ..rows = rows
    ..pending = pending;
  return id;
}
```

- [ ] **Step 3: Write the failing tests**

`test/core/auth/account_coordinator_start_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 rows #1–#12, #14, #15 and plan Review Focus 1, on fakes.
void main() {
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  test('#3 #6 #9 a first launch online makes one anonymous user and syncs', () async {
    world.boot();
    await world.coordinator.start();

    expect(world.state, isA<Ready>().having((s) => s.user.isAnonymous, 'anonymous', isTrue));
    expect(world.server.anonymousCreated, 1);
    expect(world.sync.paused, isFalse);
    expect((await world.store.lastKnown())!.id, world.gateway.currentUserId);
  });

  test('#3 offline with no session is local only; #4 it bootstraps on reconnect', () async {
    world.network.goOffline();
    world.boot();
    await world.coordinator.start();
    expect(world.state, isA<LocalOnly>());
    expect(world.sync.paused, isTrue);

    world.network.goOnline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>());
    expect(world.server.anonymousCreated, 1);
  });

  test('#7 a network error during the anonymous sign-in is local only', () async {
    world.network
      ..goOffline()
      ..claimsOnline = true;
    world.boot();
    await world.coordinator.start();

    expect(world.state, isA<LocalOnly>());
    expect(world.server.anonymousCreated, 0);
  });

  test('#2 #5 a session the SDK holds is validated; no second anonymous user', () async {
    world.gateway.adopt(world.server.addUser(anonymous: true).id);
    world.boot();
    await world.coordinator.start();

    expect(world.state, isA<Ready>());
    expect(world.server.anonymousCreated, 1);
  });

  test('#8 R2 offline with a session stays validating with sync paused; #9 on reconnect', () async {
    world.gateway.adopt(world.server.addUser(anonymous: true).id);
    world.network.goOffline();
    world.boot();
    await world.coordinator.start();
    expect(world.state, isA<Validating>());
    expect(world.sync.paused, isTrue);

    world.network.goOnline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>());
    expect(world.sync.paused, isFalse);
  });

  test('#10 #11 #12 an anonymous user the server cleaned up keeps its data, '
      'gets a new anonymous user and pushes everything', () async {
    final a = await readyAnonymous(world);
    world.server.deleteUser(a);

    world.boot();
    await world.coordinator.start();

    final state = world.state as Ready;
    expect(state.user.id, isNot(a));
    expect(state.user.isAnonymous, isTrue);
    expect(world.server.anonymousCreated, 2);
    expect(world.device.markAllPendingCalls, 1);
    expect(world.device.owner, state.user.id);
    expect(world.device.resets, 0);
    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
  });

  test('Review Focus 1: a session the SDK drops while ready, anonymous, '
      'recovers into a new anonymous user', () async {
    final a = await readyAnonymous(world);

    world.gateway.dropSession();
    await pumpEventQueue();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', isNot(a)));
    expect(world.device.markAllPendingCalls, 1);
    expect(world.device.resets, 0);
  });

  test('#14 an account whose session is refused keeps its data and waits', () async {
    final b = world.server.addUser(email: 'b@example.com');
    world.gateway.adopt(b.id);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = b.id
      ..pending = 2;

    world.gateway.dropSession();
    await pumpEventQueue();

    expect(world.state, isA<ReauthRequired>().having((s) => s.last.id, 'last', b.id));
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
    expect(world.sync.paused, isTrue);
  });

  test('#15 offline while ready stays ready and signs nobody out', () async {
    final a = await readyAnonymous(world);

    world.network.goOffline();
    await pumpEventQueue();

    expect(world.state, isA<Ready>());
    expect(world.gateway.currentUserId, a);
  });

  test('#1 a pending anonymous recovery is finished before anything else', () async {
    final a = await readyAnonymous(world);
    world.server.deleteUser(a);
    await world.store.saveTransition(
      AccountTransition(
        opId: 'op-x',
        kind: TransitionKind.anonRecovery,
        sourceUserId: a,
        sourceIsAnonymous: true,
        stage: TransitionStage.started,
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    world.boot();
    await world.coordinator.start();

    expect(world.state, isA<Ready>());
    expect(world.gateway.currentUserId, isNot(a));
    expect(world.server.anonymousCreated, 2);
    expect(await world.store.transition(), isNull);
  });

  test('R3 prepare shuts the gate for a pending blocking transition', () async {
    await world.store.saveTransition(
      AccountTransition(
        opId: 'op-x',
        kind: TransitionKind.signOut,
        stage: TransitionStage.started,
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    world.boot();
    await world.coordinator.prepare();

    expect(world.gate.isClosed, isTrue);
    expect(world.state, isA<Booting>());
  });

  test('prepare purges the secrets of an operation that is no longer pending', () async {
    world.secrets.values.addAll({'account.backup.old': 'r', 'account.claim.old': 'c'});

    world.boot();
    await world.coordinator.prepare();

    expect(world.secrets.values, isEmpty);
  });
}
```

- [ ] **Step 4: Run them to verify they fail**

Run: `flutter test test/core/auth/account_coordinator_start_test.dart`
Expected: FAIL, with a compile error: `account_coordinator.dart` does not exist.

- [ ] **Step 5: Write the coordinator core**

`lib/core/auth/account_coordinator.dart`:

```dart
import 'dart:async';

import 'package:memox/core/auth/account_api.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/secret_store.dart';
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/database/mutation_gate.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/core/logging/app_logger.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/sync_control.dart';

/// The one owner of the account (auth spec §3, §5, §6): start, validation,
/// recovery and every transition, one step at a time. Features send it
/// commands; it publishes [AuthState].
///
/// Each stage is saved before the next step, so a rerun after a kill is a
/// no-op up to where it stopped. Each `OfflineFailure` keeps the record, and
/// the reconnect listener runs it again.
class AccountCoordinator {
  AccountCoordinator({
    required AuthGateway gateway,
    required AccountApi api,
    required AccountStore store,
    required SecretStore secrets,
    required SyncControl sync,
    required LocalDataReset localReset,
    required MutationGate gate,
    required NetworkStatus network,
    Future<void> Function()? flushLogs,
    String Function() newOpId = newId,
    DateTime Function() now = DateTime.now,
    AppLogger? logger,
  }) : _gateway = gateway,
       _api = api,
       _store = store,
       _secrets = secrets,
       _sync = sync,
       _reset = localReset,
       _gate = gate,
       _network = network,
       _flushLogs = flushLogs,
       _newOpId = newOpId,
       _now = now,
       _logger = logger;

  final AuthGateway _gateway;
  final AccountApi _api;
  final AccountStore _store;
  final SecretStore _secrets;
  final SyncControl _sync;
  final LocalDataReset _reset;
  final MutationGate _gate;
  final NetworkStatus _network;
  final Future<void> Function()? _flushLogs;
  final String Function() _newOpId;
  final DateTime Function() _now;
  final AppLogger? _logger;

  AppLogger get _log => _logger ?? appLogger;

  AuthState _state = const Booting();
  final _states = StreamController<AuthState>.broadcast();
  final _notices = StreamController<AccountNotice>.broadcast();
  final _subscriptions = <StreamSubscription<Object?>>[];
  Future<void> _tail = Future<void>.value();
  var _prepared = false;

  /// The transition this run of the app started. A reconnect or a retry
  /// must not treat it as found at start (Review Focus 2).
  String? _liveOpId;

  AuthState get state => _state;

  /// The state now, then every change.
  Stream<AuthState> watch() {
    final controller = StreamController<AuthState>();
    controller.onListen = () {
      controller.add(_state);
      final subscription = _states.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    };
    return controller.stream;
  }

  Stream<AccountNotice> get notices => _notices.stream;

  /// Before the first frame, local only: shuts the gate if a blocking
  /// transition is pending, so no write slips in before recovery (#1, R3),
  /// and drops the secrets of any other operation (spec §4).
  Future<void> prepare() async {
    if (_prepared) return;
    _prepared = true;
    _emit(const Booting());
    await _sync.pause();
    final pending = await _store.transition();
    await purgeAccountSecrets(_secrets, keepOpId: pending?.opId);
    if (pending != null && pending.blocksWrites) _gate.close();
  }

  /// Recovers a pending transition or settles the session (#1–#3), then
  /// follows the network and the SDK.
  Future<void> start() => _serial(() async {
    await prepare();
    _subscriptions
      ..add(
        _network.reconnects.listen(
          (_) => _background('reconnect_failed', _resume),
        ),
      )
      ..add(
        _gateway.userIds.listen(
          (userId) =>
              _background('session_event_failed', () => _onUserId(userId)),
        ),
      );
    final pending = await _store.transition();
    if (pending != null) return _drive(pending); // #1
    return _settle();
  });

  /// Runs again whatever stopped on an error (a network error's Retry).
  Future<void> retry() => _serial(_resume);

  Future<void> dispose() async {
    await Future.wait([
      for (final subscription in _subscriptions) subscription.cancel(),
    ]);
    await _states.close();
    await _notices.close();
  }

  // --- Start and validation -------------------------------------------------

  Future<void> _settle() async {
    if (_gateway.currentUserId != null) return _validate(); // #2, #5 (R1)
    if (!await _network.isOnline) return _emit(const LocalOnly()); // #3
    _emit(const Bootstrapping());
    try {
      await _gateway.signInAnonymously(); // #6
    } on OfflineFailure {
      return _emit(const LocalOnly()); // #7
    }
    return _validate();
  }

  Future<void> _validate() async {
    await _sync.pause();
    _emit(Validating(await _store.lastKnown())); // R2
    try {
      final me = await _api.me();
      await _store.saveLastKnown(me, _now());
      _emit(Ready(me));
      _sync.resume(); // #9
      _log.info(
        'auth.ready',
        category: LogCategory.state,
        context: {'anonymous': me.isAnonymous, 'role': me.role.name},
      );
    } on OfflineFailure {
      // #8: stays Validating; the reconnect listener tries again.
    } on SessionInvalidFailure {
      return _lost(sessionInvalid: true);
    } on ProfileGoneFailure {
      return _lost(sessionInvalid: false);
    }
  }

  /// The session is refused (#10, #13, #14).
  Future<void> _lost({required bool sessionInvalid}) async {
    await _sync.pause();
    final last = await _store.lastKnown();
    if (last == null || last.isAnonymous) {
      return _begin(
        _newTransition(
          TransitionKind.anonRecovery,
          sourceUserId: _gateway.currentUserId ?? last?.id,
          sourceIsAnonymous: true,
        ),
      ); // #10
    }
    if (sessionInvalid) return _emit(ReauthRequired(last)); // #14
    return _begin(
      _newTransition(
        TransitionKind.clearToAnon,
        sourceUserId: last.id,
        sourceIsAnonymous: false,
      ),
    ); // #13
  }

  // --- Events ---------------------------------------------------------------

  /// A reconnect or a retry: the pending transition, else what waited.
  Future<void> _resume() async {
    final pending = await _store.transition();
    if (pending != null) return _drive(pending);
    return switch (_state) {
      LocalOnly() => _settle(), // #4
      Validating() => _validate(), // #8
      _ => Future<void>.value(),
    };
  }

  /// The SDK dropped the session on its own, as when its refresh token is
  /// refused (Review Focus 1). A transition's own sign-out is ignored.
  Future<void> _onUserId(String? userId) async {
    if (userId != null || _gateway.currentUserId != null) return;
    if (await _store.transition() != null) return;
    if (_state is Ready || _state is Validating) {
      return _lost(sessionInvalid: true);
    }
  }

  // --- Transitions ----------------------------------------------------------

  /// Records [t], then runs it.
  Future<void> _begin(AccountTransition t) async {
    if (t.blocksWrites) _gate.close();
    await _sync.pause();
    await _store.saveTransition(t);
    _liveOpId = t.opId;
    _log.info(
      'auth.transition_started',
      category: LogCategory.state,
      context: {'kind': t.kind.name, 'op': t.opId},
    );
    return _drive(t);
  }

  Future<void> _drive(AccountTransition t) async {
    switch (t.kind) {
      case TransitionKind.anonRecovery:
        return _driveAnonRecovery(t);
      case TransitionKind.switchAccount:
      case TransitionKind.signOut:
      case TransitionKind.delete:
      case TransitionKind.clearToAnon:
        // Tasks 11 and 12 of the core-auth plan drive these. Until then a
        // pending one keeps the gate shut.
        _log.error(
          'auth.transition_unsupported',
          category: LogCategory.state,
          context: {'kind': t.kind.name},
        );
        return _emit(Recovering(t, stuck: true));
    }
  }

  /// #10–#12: sign out the refused session, sign in a new anonymous user
  /// (never a second one: R1), queue the whole library under it.
  Future<void> _driveAnonRecovery(AccountTransition t) async {
    _emit(_inTransition(t));
    var s = t;
    if (s.stage == TransitionStage.started) {
      final source = s.sourceUserId;
      if (source != null && _gateway.currentUserId == source) {
        await _gateway.signOutLocal(); // #10
      }
      if (_gateway.currentUserId == null) {
        try {
          await _gateway.signInAnonymously(); // #11
        } on OfflineFailure {
          return _emit(const LocalOnly()); // the record waits for a reconnect
        }
      }
      s = await _save(
        s.copyWith(
          stage: TransitionStage.newAnon,
          targetUserId: _gateway.currentUserId,
        ),
      );
    }
    await _sync.markAllPending(); // #12, idempotent
    await _store.saveLastKnown(
      AccountUser(
        id: s.targetUserId ?? _gateway.currentUserId!,
        isAnonymous: true,
        role: AccountRole.user,
      ),
      _now(),
    ); // plan ruling 7: the device's data now belongs to the new user
    await _drop(s);
    return _validate();
  }

  /// The end of a transition: its secrets and record go, the gate opens.
  Future<void> _drop(AccountTransition s) async {
    await _secrets.delete(backupSecretKey(s.opId));
    await _secrets.delete(claimSecretKey(s.opId));
    await _store.clearTransition();
    if (_liveOpId == s.opId) _liveOpId = null;
    _gate.open();
    _log.info(
      'auth.transition_done',
      category: LogCategory.state,
      context: {'kind': s.kind.name, 'stage': s.stage.name, 'op': s.opId},
    );
  }

  Future<AccountTransition> _save(AccountTransition t) =>
      _store.saveTransition(t.copyWith(updatedAt: _now()));

  AccountTransition _newTransition(
    TransitionKind kind, {
    TransitionChoice? choice,
    String? sourceUserId,
    bool? sourceIsAnonymous,
    String? targetHint,
  }) {
    final at = _now();
    return AccountTransition(
      opId: _newOpId(),
      kind: kind,
      choice: choice,
      sourceUserId: sourceUserId,
      sourceIsAnonymous: sourceIsAnonymous,
      targetHint: targetHint,
      stage: TransitionStage.started,
      createdAt: at,
      updatedAt: at,
    );
  }

  /// [Transitioning] for a flow this run started, [Recovering] for one found
  /// at start.
  AuthState _inTransition(
    AccountTransition t, {
    bool needsTargetSignIn = false,
    Failure? error,
  }) => _liveOpId == t.opId
      ? Transitioning(t, needsTargetSignIn: needsTargetSignIn, error: error)
      : Recovering(t, needsTargetSignIn: needsTargetSignIn, error: error);

  // --- Plumbing -------------------------------------------------------------

  /// Runs [step] after every earlier one. Its result or error goes to its
  /// caller only.
  Future<T> _serial<T>(Future<T> Function() step) {
    final result = _tail.then((_) => step());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// A step no caller waits on: a failure is logged, and the state stays
  /// where the step stopped.
  void _background(String event, Future<void> Function() step) {
    unawaited(
      _serial(step).catchError((Object error, StackTrace stackTrace) {
        _log.error(
          'auth.$event',
          category: LogCategory.state,
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  void _emit(AuthState state) {
    _state = state;
    if (!_states.isClosed) _states.add(state);
  }
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `flutter test test/core/auth/account_coordinator_start_test.dart`
Expected: PASS for all 12 tests. If a test fails, use systematic-debugging on the coordinator. Do not edit the assertions: each one is a row of spec §3.3.

- [ ] **Step 7: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(auth): AccountCoordinator — start, validation, anonymous recovery

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 11: Link and switch (#16–#35) and the start-up guard

**Files:**
- Modify: `lib/core/auth/account_coordinator.dart`
- Test: `test/core/auth/account_coordinator_switch_test.dart`

**Interfaces:**
- Consumes: Task 10's coordinator and fakes.
- Produces the coordinator commands:
  - `Future<void> requestCode(String email)`
  - `Future<void> verifyCode(String email, String code)`
  - `Future<void> continueWithGoogle()`
  - `Future<void> beginSwitch({required TransitionChoice choice, String? targetHint})`
  - `Future<void> cancelSwitch()`

  Each throws a `Failure` for the user, or a `StateError` when the command does not fit the state.

- [ ] **Step 1: Write the failing tests**

`test/core/auth/account_coordinator_switch_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/secret_store.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 rows #16–#35, plan rulings 4, 7–9 and Review Focus 2–3.
void main() {
  const bEmail = 'b@example.com';
  const code = FakeAuthGateway.code;
  late AuthWorld world;

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  Future<String> existingB() async => world.server.addUser(email: bEmail).id;

  /// The device on anonymous A, B's account taken: the merge sheet's answer.
  Future<(String, String)> switchStarted(TransitionChoice choice) async {
    final a = await readyAnonymous(world);
    final b = await existingB();
    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );
    await world.coordinator.beginSwitch(choice: choice, targetHint: bEmail);
    return (a, b);
  }

  Future<void> signInB() async {
    await world.coordinator.requestCode(bEmail);
    await world.coordinator.verifyCode(bEmail, code);
  }

  void expectSettledOn(String userId) {
    expect(world.state, isA<Ready>().having((s) => s.user.id, 'user', userId));
    expect(world.gate.isClosed, isFalse);
    expect(world.secrets.values, isEmpty);
    expect(world.sync.paused, isFalse);
  }

  test('#16 a code attaches the email to the same user; nothing is cleared', () async {
    final a = await readyAnonymous(world);

    await world.coordinator.requestCode('a@example.com');
    await world.coordinator.verifyCode('a@example.com', code);

    expect(
      world.state,
      isA<Ready>()
          .having((s) => s.user.id, 'id', a)
          .having((s) => s.user.isAnonymous, 'anonymous', isFalse),
    );
    expect(world.device.resets, 0);
  });

  test('#16 a Google identity attaches to the same user', () async {
    final a = await readyAnonymous(world);

    await world.coordinator.continueWithGoogle();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', a));
    expect((world.state as Ready).user.email, 'g@example.com');
  });

  test('#17 a taken email changes nothing and says so', () async {
    final a = await readyAnonymous(world);
    await existingB();

    await expectLater(
      world.coordinator.requestCode(bEmail),
      throwsA(isA<IdentityTakenFailure>()),
    );

    expectSettledOn(a);
    expect(await world.store.transition(), isNull);
  });

  test('#18 #19 #20 a merge shuts the gate, sends A, claims, then asks for B', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);

    final t = (await world.store.transition())!;
    expect(t.kind, TransitionKind.switchAccount);
    expect(t.stage, TransitionStage.claimed);
    expect(world.gate.isClosed, isTrue);
    expect(world.sync.paused, isTrue);
    expect(world.device.pushes.single, (signedIn: a, owner: a));
    expect(world.secrets.values.keys, [claimSecretKey(t.opId)]);
    expect(world.state, isA<Transitioning>().having((s) => s.needsTargetSignIn, 'asks', isTrue));
  });

  test('#21 #23 #24 #27–#30 the merge into B clears A from the device and pulls B', () async {
    final (a, b) = await switchStarted(TransitionChoice.merge);

    await signInB();

    expectSettledOn(b);
    expect(world.server.users.containsKey(a), isFalse);
    expect(world.server.receipts.values.single.acknowledged, isTrue);
    expect(world.device.resets, 1);
    expect(world.device.pulls, [b]);
    expect(world.device.owner, b);
    expect(world.server.anonymousCreated, 1);
    final afterMerge = world.gateway.history.skipWhile((id) => id != b);
    expect(afterMerge, isNot(contains(a)));
  });

  test('#22 cancel before the target sign-in returns to A as it was', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);

    await world.coordinator.cancelSwitch();

    expectSettledOn(a);
    expect(world.device.resets, 0);
    expect(await world.store.transition(), isNull);
  });

  test('#25 a refused claim goes back to A with its data and a notice', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);
    world.server.claims.clear();

    await signInB();

    expectSettledOn(a);
    expect(world.device.resets, 0);
    expect(world.device.owner, a);
    expect(world.notices, [isA<MergeNotDone>()]);
  });

  test("ruling 8: a refused claim with A's backup unusable keeps the data "
      'under a new anonymous user', () async {
    final (a, b) = await switchStarted(TransitionChoice.merge);
    world.server.claims.clear();
    world.gateway.afterSignIn = () => world.server.revokeTokensOf(a);

    await signInB();

    final user = (world.state as Ready).user;
    expect(user.id, isNot(anyOf(a, b)));
    expect(user.isAnonymous, isTrue);
    expect(world.device.resets, 0);
    expect(world.device.markAllPendingCalls, 1);
    expect(world.notices, [isA<MergeNotDone>()]);
  });

  test('#26 a network error during the merge keeps everything; the reconnect finishes', () async {
    final (_, b) = await switchStarted(TransitionChoice.merge);
    world.gateway.afterSignIn = world.network.goOffline;

    await signInB();
    expect(world.state, isA<Transitioning>().having((s) => s.error, 'error', isA<OfflineFailure>()));
    expect((await world.store.transition())!.stage, TransitionStage.targetSignedIn);
    expect(world.device.resets, 0);
    expect(world.gate.isClosed, isTrue);

    world.gateway.afterSignIn = null;
    world.network.goOnline();
    await pumpEventQueue();

    expectSettledOn(b);
  });

  test('#31 a launch that finds the SDK still on A before the target sign-in '
      'cancels the switch', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);

    world.boot();
    await world.coordinator.start();

    expectSettledOn(a);
    expect(world.device.resets, 0);
    expect(await world.store.transition(), isNull);
  });

  test('#32 killed after the target sign-in, before its stage was saved: the '
      'launch finishes the merge with the same op', () async {
    final (a, b) = await switchStarted(TransitionChoice.merge);
    world.gateway.afterSignIn = () => throw const Killed();
    await world.coordinator.requestCode(bEmail);
    await expectLater(
      world.coordinator.verifyCode(bEmail, code),
      throwsA(isA<Killed>()),
    );
    world.gateway.afterSignIn = null;

    world.boot();
    await world.coordinator.start();

    expectSettledOn(b);
    expect(world.server.users.containsKey(a), isFalse);
    expect(world.server.receipts, hasLength(1));
  });

  test('#33 no session and a merge not yet done: back to A through the backup', () async {
    final (a, _) = await switchStarted(TransitionChoice.merge);
    final t = (await world.store.transition())!;
    await world.secrets.write(backupSecretKey(t.opId), world.gateway.refreshToken!);
    world.gateway.forgetSession();

    world.boot();
    await world.coordinator.start();

    expectSettledOn(a);
    expect(world.device.resets, 0);
  });

  test('#33 no session after the merge: the gate stays shut until B signs in again', () async {
    final (_, b) = await switchStarted(TransitionChoice.merge);
    // Killed right after the merge committed, with the SDK's session lost.
    world.server.afterMergeCommit = () {
      world.gateway.forgetSession();
      throw const Killed();
    };
    await world.coordinator.requestCode(bEmail);
    await expectLater(
      world.coordinator.verifyCode(bEmail, code),
      throwsA(isA<Killed>()),
    );
    world.server.afterMergeCommit = null;

    world.boot();
    await world.coordinator.start();
    expect(world.state, isA<Recovering>().having((s) => s.needsTargetSignIn, 'asks', isTrue));
    expect(world.gate.isClosed, isTrue);

    await signInB();

    expectSettledOn(b);
  });

  test('#34 #35 an account switches to another: X is sent, Y is pulled, no anonymous user in between', () async {
    final x = world.server.addUser(email: 'x@example.com').id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 4
      ..pending = 1;
    final y = world.server.addUser(email: 'y@example.com').id;

    await world.coordinator.beginSwitch(choice: TransitionChoice.discard);
    expect(world.device.pushes.single, (signedIn: x, owner: x));
    await world.coordinator.requestCode('y@example.com');
    await world.coordinator.verifyCode('y@example.com', code);

    expectSettledOn(y);
    expect(world.server.anonymousCreated, 0);
    expect(world.server.users.containsKey(x), isTrue);
    expect(world.device.resets, 1);
    expect(world.device.pulls, [y]);
  });

  test('#17 discard: B is pulled, A stays on the server, nothing merges', () async {
    final (a, b) = await switchStarted(TransitionChoice.discard);

    await signInB();

    expectSettledOn(b);
    expect(world.server.receipts, isEmpty);
    expect(world.server.users.containsKey(a), isTrue);
    expect(world.device.resets, 1);
  });

  test('Google taken on the link: the switch signs in with the same pick', () async {
    final a = await readyAnonymous(world);
    world.server.addUser(email: 'g@example.com');
    await expectLater(
      world.coordinator.continueWithGoogle(),
      throwsA(
        isA<IdentityTakenFailure>()
            .having((f) => f.method, 'method', IdentityMethod.google),
      ),
    );
    world.gateway.googleCancels = true; // a second pick would now fail

    await world.coordinator.beginSwitch(choice: TransitionChoice.merge);
    await world.coordinator.continueWithGoogle();

    expect((world.state as Ready).user.email, 'g@example.com');
    expect(world.server.users.containsKey(a), isFalse);
  });

  test('Review Focus 2: a reconnect while the target sign-in is asked keeps the switch', () async {
    await switchStarted(TransitionChoice.merge);

    world.network.goOnline();
    await pumpEventQueue();

    expect(world.state, isA<Transitioning>().having((s) => s.needsTargetSignIn, 'asks', isTrue));
    expect((await world.store.transition())!.stage, TransitionStage.claimed);
  });

  test('Review Focus 3: commands run one at a time; a second switch is refused', () async {
    await readyAnonymous(world);
    await existingB();

    final first = world.coordinator.beginSwitch(choice: TransitionChoice.discard);
    final second = world.coordinator.beginSwitch(choice: TransitionChoice.discard);

    await first;
    await expectLater(second, throwsA(isA<StateError>()));
    expect(world.device.pushes, hasLength(1));
  });

  test('ruling 7: the SDK on another account than the last known one, with no '
      'record, adopts the SDK account and its data', () async {
    final a = await readyAnonymous(world);
    final u = world.server.addUser(email: 'u@example.com').id;
    world.gateway.adopt(u);

    world.boot();
    await world.coordinator.start();

    expectSettledOn(u);
    expect(world.device.resets, 1);
    expect(world.device.pulls, [u]);
    expect(world.device.pushes.where((p) => p.signedIn != p.owner), isEmpty);
    expect(a, isNot(u));
  });

  test('a wrong code keeps the switch waiting for B', () async {
    await switchStarted(TransitionChoice.merge);
    await world.coordinator.requestCode(bEmail);

    await expectLater(
      world.coordinator.verifyCode(bEmail, '000000'),
      throwsA(isA<InvalidCodeFailure>()),
    );

    expect((await world.store.transition())!.stage, TransitionStage.claimed);
    expect(world.gate.isClosed, isTrue);
  });

  test('only an anonymous user merges', () async {
    world.gateway.adopt(world.server.addUser(email: 'x@example.com').id);
    world.boot();
    await world.coordinator.start();

    await expectLater(
      world.coordinator.beginSwitch(choice: TransitionChoice.merge),
      throwsA(isA<ArgumentError>()),
    );
    expect(await world.store.transition(), isNull);
  });

}
```

`googleCancels` makes a second `pickGoogle` throw, so the Google test proves the switch reused the first pick.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/auth/account_coordinator_switch_test.dart`
Expected: FAIL, with compile errors: `requestCode`, `verifyCode`, `continueWithGoogle`, `beginSwitch` and `cancelSwitch` are not defined.

- [ ] **Step 3: Add link, switch and the start-up guard to the coordinator**

In `lib/core/auth/account_coordinator.dart`:

1. **The field.** Add under `_liveOpId`:

   ```dart
     /// A Google account picked for a link that turned out to be another
     /// account's (#17). Kept in memory for the switch's target sign-in, so
     /// nobody picks twice; never persisted (spec §4).
     GoogleCredential? _pendingGoogle;
   ```

2. **The start-up guard in `_settle`** (ruling 7). Replace its first line, `if (_gateway.currentUserId != null) return _validate(); // #2, #5 (R1)`, with:

   ```dart
       final userId = _gateway.currentUserId; // R1
       if (userId != null) {
         final last = await _store.lastKnown();
         if (last != null && last.id != userId) return _adopt(last, userId);
         return _validate(); // #2, #5
       }
   ```

3. **Driving a switch.** In `_drive`, replace `case TransitionKind.switchAccount:` (in the fall-through group) with its own arm, placed before the group:

   ```dart
         case TransitionKind.switchAccount:
           return _driveSwitch(t);
   ```

   Leave the group with `signOut`, `delete` and `clearToAnon`; Task 12 replaces it.

4. **The commands and helpers.** Add them after `retry()`:

```dart
  // --- Sign-in and switch commands -----------------------------------------

  /// Sends a 6-digit code to [email]: to attach it to this anonymous user
  /// (#16), or to sign in to the switch's target (#21). Throws
  /// [IdentityTakenFailure] when [email] already has an account; the caller
  /// then asks merge or discard (#17).
  Future<void> requestCode(String email) => _serial(() async {
    return switch (await _signInContext()) {
      _SignIn.link => _gateway.requestEmailLink(email),
      _SignIn.target => _gateway.requestEmailSignIn(email),
    };
  });

  Future<void> verifyCode(String email, String code) => _serial(() async {
    switch (await _signInContext()) {
      case _SignIn.link:
        await _gateway.verifyEmailLink(email, code);
        return _validate(); // #16
      case _SignIn.target:
        return _signInTarget(
          () => _gateway.verifyEmailSignIn(email, code),
        ); // #21
    }
  });

  Future<void> continueWithGoogle() => _serial(() async {
    final context = await _signInContext();
    final credential = _pendingGoogle ?? await _gateway.pickGoogle();
    try {
      switch (context) {
        case _SignIn.link:
          await _gateway.linkGoogle(credential);
          _pendingGoogle = null;
          return _validate(); // #16
        case _SignIn.target:
          await _signInTarget(() => _gateway.signInGoogle(credential)); // #21
          _pendingGoogle = null;
      }
    } on IdentityTakenFailure {
      _pendingGoogle = credential; // #17
      rethrow;
    }
  });

  /// Starts moving this device to another account: #18 from an anonymous
  /// user whose identity is taken, #34 "Switch account" from an account.
  /// The gate shuts, the source's changes are sent and, for a merge, a claim
  /// is taken. Then the state asks for the target sign-in.
  Future<void> beginSwitch({
    required TransitionChoice choice,
    String? targetHint,
  }) => _serial(() async {
    await _ensureNoTransition();
    final user = _readyUser();
    if (choice == TransitionChoice.merge && !user.isAnonymous) {
      throw ArgumentError.value(choice, 'choice', 'only an anonymous user merges');
    }
    return _begin(
      _newTransition(
        TransitionKind.switchAccount,
        choice: choice,
        sourceUserId: user.id,
        sourceIsAnonymous: user.isAnonymous,
        targetHint: targetHint,
      ),
    );
  });

  /// Before the target sign-in: back to the source as it was (#22). With the
  /// source's session gone, the source is treated as lost (plan ruling 9).
  Future<void> cancelSwitch() => _serial(() async {
    final t = await _store.transition();
    final userId = _gateway.currentUserId;
    if (t == null ||
        t.kind != TransitionKind.switchAccount ||
        !t.stage.isBefore(TransitionStage.targetSignedIn) ||
        (userId != null && userId != t.sourceUserId)) {
      throw StateError('No switch to cancel before the target sign-in');
    }
    _pendingGoogle = null;
    await _drop(t);
    if (userId == t.sourceUserId) return _validate(); // #22
    return _lost(sessionInvalid: true);
  });

  Future<_SignIn> _signInContext() async {
    final pending = await _store.transition();
    if (pending != null) {
      if (pending.kind == TransitionKind.switchAccount) return _SignIn.target;
      throw StateError('No sign-in during ${pending.kind.name}');
    }
    return switch (_state) {
      Ready(:final user) when user.isAnonymous => _SignIn.link,
      _ => throw StateError('No account step takes a sign-in in $_state'),
    };
  }

  /// #21, and ruling 4: A's refresh token is kept just before the SDK
  /// replaces it with B's. A refused sign-in changes nothing.
  Future<void> _signInTarget(Future<void> Function() signIn) async {
    final t = (await _store.transition())!;
    _liveOpId = t.opId;
    final source = t.sourceUserId;
    if (t.merges &&
        t.stage.isBefore(TransitionStage.merged) &&
        source != null &&
        _gateway.currentUserId == source) {
      final token = _gateway.refreshToken;
      if (token != null) {
        await _secrets.write(backupSecretKey(t.opId), token);
      }
    }
    await signIn();
    return _driveSwitch(t);
  }

  // --- The switch -------------------------------------------------------------

  Future<void> _driveSwitch(AccountTransition t) async {
    _gate.close();
    await _sync.pause();
    _emit(_inTransition(t));
    final userId = _gateway.currentUserId; // R1
    if (userId != null && userId == t.sourceUserId) {
      if (_liveOpId == t.opId) return _advanceSource(t); // #19, #20
      if (t.stage.isBefore(TransitionStage.merged)) {
        await _drop(t); // #31
        return _validate();
      }
      _log.error(
        'auth.switch_source_after_merge',
        category: LogCategory.state,
        context: {'op': t.opId, 'stage': t.stage.name},
      );
      return _emit(Recovering(t, stuck: true));
    }
    if (userId == null) return _switchWithoutSession(t); // #33
    return _advanceTarget(t, userId); // #32
  }

  Future<void> _advanceSource(AccountTransition t) async {
    var s = t;
    if (s.stage == TransitionStage.started) {
      try {
        await _sync.pushPending(); // #19
      } on Failure catch (error) {
        return _emit(Transitioning(s, error: error));
      }
      s = await _save(s.copyWith(stage: TransitionStage.sourcePushed));
    }
    if (s.merges && s.stage == TransitionStage.sourcePushed) {
      final String token;
      try {
        token = await _api.claimBegin(); // #20
      } on Failure catch (error) {
        return _emit(Transitioning(s, error: error));
      }
      await _secrets.write(claimSecretKey(s.opId), token);
      s = await _save(s.copyWith(stage: TransitionStage.claimed));
    }
    _emit(Transitioning(s, needsTargetSignIn: true));
  }

  /// #33: no session. Before the merge, back to A through its backup; after
  /// it, the gate stays shut until the target signs in again.
  Future<void> _switchWithoutSession(AccountTransition t) async {
    final backup = await _secrets.read(backupSecretKey(t.opId));
    if (t.stage.isBefore(TransitionStage.merged) && backup != null) {
      try {
        await _gateway.restoreSession(backup);
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(t, error: error));
      } on SessionInvalidFailure {
        await _secrets.delete(backupSecretKey(t.opId));
        return _emit(_inTransition(t, needsTargetSignIn: true));
      }
      return _driveSwitch(t); // the SDK is on A again: #31
    }
    _emit(_inTransition(t, needsTargetSignIn: true));
  }

  /// #32 and #23–#30, on the target [userId] the SDK holds.
  Future<void> _advanceTarget(AccountTransition t, String userId) async {
    var s = t;
    if (s.targetUserId != userId ||
        s.stage.isBefore(TransitionStage.targetSignedIn)) {
      s = await _save(
        s.copyWith(
          targetUserId: userId,
          stage: s.stage.atLeast(TransitionStage.targetSignedIn),
        ),
      );
    }
    if (s.merges && s.stage == TransitionStage.targetSignedIn) {
      final token = await _secrets.read(claimSecretKey(s.opId));
      try {
        if (token == null) throw const ClaimInvalidFailure();
        await _api.merge(token, s.opId); // #23, MERGED on a retry
      } on ClaimInvalidFailure {
        return _mergeRefused(s); // #25
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error)); // #26
      }
      await _secrets.delete(backupSecretKey(s.opId)); // #24
      s = await _save(s.copyWith(stage: TransitionStage.merged));
    }
    if (s.stage.isBefore(TransitionStage.localCleared)) {
      await _reset.run(); // #27
      s = await _save(s.copyWith(stage: TransitionStage.localCleared));
    }
    if (s.stage.isBefore(TransitionStage.targetPulled)) {
      try {
        await _sync.pullAll(); // #28
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error));
      }
      s = await _save(s.copyWith(stage: TransitionStage.targetPulled));
    }
    if (s.merges && s.stage == TransitionStage.targetPulled) {
      try {
        await _api.mergeAck(s.opId); // #29
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error));
      }
      s = await _save(s.copyWith(stage: TransitionStage.acknowledged));
    }
    await _store.saveLastKnown(
      AccountUser(
        id: userId,
        email: s.targetHint,
        isAnonymous: false,
        role: AccountRole.user,
      ),
      _now(),
    ); // plan ruling 7; me() replaces it at once
    await _drop(s); // #30
    return _validate();
  }

  /// #25: the claim was refused, so nothing moved. Back to A with its data.
  /// When A cannot come back, a new anonymous user takes the data (ruling
  /// 8).
  Future<void> _mergeRefused(AccountTransition s) async {
    final backup = await _secrets.read(backupSecretKey(s.opId));
    if (backup != null) {
      try {
        await _gateway.restoreSession(backup);
        await _drop(s);
        _notice(const MergeNotDone());
        return _validate();
      } on OfflineFailure catch (error) {
        return _emit(_inTransition(s, error: error)); // the same op on reconnect
      } on SessionInvalidFailure {
        // Ruling 8, below.
      }
    }
    await _gateway.signOutLocal(); // B never sees A's data
    await _drop(s);
    _notice(const MergeNotDone());
    return _begin(
      _newTransition(TransitionKind.anonRecovery, sourceIsAnonymous: true),
    );
  }

  /// Ruling 7: the SDK holds another account than the one whose data the
  /// device has, and no transition says why. The device takes the SDK's
  /// account, as a discard switch that is past the sign-in.
  Future<void> _adopt(AccountUser last, String userId) {
    _log.warning(
      'auth.account_mismatch',
      category: LogCategory.state,
      context: {'last': last.id, 'signed_in': userId},
    );
    return _begin(
      _newTransition(
        TransitionKind.switchAccount,
        choice: TransitionChoice.discard,
        sourceUserId: last.id,
        sourceIsAnonymous: last.isAnonymous,
      ).copyWith(targetUserId: userId, stage: TransitionStage.targetSignedIn),
    );
  }

  AccountUser _readyUser() => switch (_state) {
    Ready(:final user) => user,
    _ => throw StateError('This needs a confirmed account, not $_state'),
  };

  Future<void> _ensureNoTransition() async {
    if (await _store.transition() != null) {
      throw StateError('An account transition is already running');
    }
  }

  void _notice(AccountNotice notice) {
    if (!_notices.isClosed) _notices.add(notice);
  }
```

5. **The sign-in context type.** Add at the bottom of the file:

   ```dart
   /// What a sign-in command does in the current state.
   enum _SignIn { link, target }
   ```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/auth`
Expected: PASS: Task 11's tests, and Task 10's are still green. A failing row is a coordinator bug; use systematic-debugging.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(auth): link, merge and discard switches, crash-safe by stage

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 12: Re-auth, sign-out, deletion, clear to anonymous (#13, #36–#45)

**Files:**
- Modify: `lib/core/auth/account_coordinator.dart`
- Test: `test/core/auth/account_coordinator_signout_test.dart`

**Interfaces:**
- Consumes: Tasks 10 and 11.
- Produces:
  - `requestCode(String email, {bool confirmedLoss = false})` and `continueWithGoogle({bool confirmedLoss = false})`. In the re-auth context, both throw `UnsentChangesFailure(count)` before anything is sent when the identity differs from the last account's and changes are unsent (ruling 6).
  - `Future<void> signOut({bool discardUnsent = false})`
  - `Future<void> deleteAccount()`
  - `Future<void> continueWithoutAccount()`

- [ ] **Step 1: Write the failing tests**

`test/core/auth/account_coordinator_signout_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §3.3 rows #13, #36–#45 and plan ruling 6.
void main() {
  const xEmail = 'x@example.com';
  const code = FakeAuthGateway.code;
  late AuthWorld world;
  final t0 = DateTime.utc(2026, 9, 30);

  setUp(() => world = AuthWorld());
  tearDown(() => world.close());

  /// The device on account X, with [pending] unsent changes.
  Future<String> readyAccount({AccountRole role = AccountRole.user, int pending = 2}) async {
    final x = world.server.addUser(email: xEmail, role: role).id;
    world.gateway.adopt(x);
    world.boot();
    await world.coordinator.start();
    world.device
      ..owner = x
      ..rows = 5
      ..pending = pending;
    return x;
  }

  /// X's session refused: REAUTH_REQUIRED.
  Future<String> reauthRequired({int pending = 2}) async {
    final x = await readyAccount(pending: pending);
    world.gateway.dropSession();
    await pumpEventQueue();
    expect(world.state, isA<ReauthRequired>());
    return x;
  }

  void expectNewAnonymous({required String not}) {
    final user = (world.state as Ready).user;
    expect(user.id, isNot(not));
    expect(user.isAnonymous, isTrue);
    expect(world.gate.isClosed, isFalse);
    expect(world.secrets.values, isEmpty);
  }

  test('#36 signing in again as X keeps the data and syncs', () async {
    final x = await reauthRequired();

    await world.coordinator.requestCode(xEmail);
    await world.coordinator.verifyCode(xEmail, code);

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.device.resets, 0);
    expect(world.device.pending, 2);
    expect(world.sync.paused, isFalse);
  });

  test('ruling 6: another email with unsent changes asks first, before any code is sent', () async {
    await reauthRequired();

    await expectLater(
      world.coordinator.requestCode('y@example.com'),
      throwsA(isA<UnsentChangesFailure>().having((f) => f.count, 'count', 2)),
    );

    expect(world.server.sentCodes, isEmpty);
    expect(world.state, isA<ReauthRequired>());
  });

  test('#37 another account, loss confirmed: X is cleared, Y is pulled', () async {
    await reauthRequired();
    final y = world.server.addUser(email: 'y@example.com').id;

    await world.coordinator.requestCode('y@example.com', confirmedLoss: true);
    await world.coordinator.verifyCode('y@example.com', code);

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', y));
    expect(world.device.resets, 1);
    expect(world.device.pulls, [y]);
    expect(world.device.pushes, isEmpty);
  });

  test('#37 with nothing unsent no confirmation is needed', () async {
    await reauthRequired(pending: 0);

    await world.coordinator.requestCode('y@example.com');
    await world.coordinator.verifyCode('y@example.com', code);

    expect((world.state as Ready).user.email, 'y@example.com');
  });

  test('#38 continue without an account clears X and starts a new anonymous user', () async {
    final x = await reauthRequired();

    await world.coordinator.continueWithoutAccount();

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
    expect((await world.store.lastKnown())!.isAnonymous, isTrue);
  });

  test('#13 an account the server deleted clears the device (no re-auth)', () async {
    final x = await readyAccount();
    world.server.users.remove(x);

    world.boot();
    await world.coordinator.start();

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
    expect(world.device.pushes, isEmpty);
  });

  test('#39 #40 #41 sign-out sends X first, ships the logs, clears, starts anonymous', () async {
    final x = await readyAccount();

    await world.coordinator.signOut();

    expectNewAnonymous(not: x);
    expect(world.device.pushes.single, (signedIn: x, owner: x));
    expect(world.logFlushes, 1);
    expect(world.device.resets, 1);
    expect(world.server.refreshTokens.values, isNot(contains(x)));
    expect(await world.store.transition(), isNull);
  });

  test('#39 offline, loss not accepted: nothing changes and it waits', () async {
    final x = await readyAccount();
    world.network.goOffline();

    await world.coordinator.signOut();

    expect(world.state, isA<Transitioning>().having((s) => s.error, 'error', isA<OfflineFailure>()));
    expect(world.gateway.currentUserId, x);
    expect(world.device.resets, 0);
    expect(world.gate.isClosed, isTrue);

    world.network.goOnline();
    await pumpEventQueue();

    expectNewAnonymous(not: x);
    expect(world.device.pushes.single.signedIn, x);
  });

  test('#39 offline with the loss accepted signs out; the new user waits for the network', () async {
    final x = await readyAccount();
    world.network.goOffline();

    await world.coordinator.signOut(discardUnsent: true);

    expect(world.state, isA<LocalOnly>());
    expect(world.gateway.currentUserId, isNull);
    expect(world.device.resets, 1);
    expect(await world.store.lastKnown(), isNull);
    expect(world.gate.isClosed, isFalse);

    world.network.goOnline();
    await pumpEventQueue();

    expectNewAnonymous(not: x);
  });

  test('#42 #43 deletion removes the account, then clears like a sign-out', () async {
    final x = await readyAccount();

    await world.coordinator.deleteAccount();

    expectNewAnonymous(not: x);
    expect(world.server.users.containsKey(x), isFalse);
    expect(world.device.resets, 1);
  });

  test('#43 a retried deletion the server already did goes on', () async {
    final x = await readyAccount();
    world.server.users.remove(x);
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

    world.boot();
    await world.coordinator.start();

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
  });

  test('#44 the last admin is not deleted; nothing changes; the user is told', () async {
    final x = await readyAccount(role: AccountRole.admin);

    await world.coordinator.deleteAccount();

    expect(world.state, isA<Ready>().having((s) => s.user.id, 'id', x));
    expect(world.notices, [isA<DeleteRefused>().having((n) => n.failure, 'failure', isA<LastAdminFailure>())]);
    expect(world.device.resets, 0);
    expect(world.gate.isClosed, isFalse);
    expect(await world.store.transition(), isNull);
  });

  test('#44 deletion offline is refused before anything changes', () async {
    await readyAccount();
    world.network.goOffline();

    await expectLater(world.coordinator.deleteAccount(), throwsA(isA<OfflineFailure>()));

    expect(await world.store.transition(), isNull);
    expect(world.gate.isClosed, isFalse);
  });

  test('#45 a sign-out found signed out at launch finishes the clearing', () async {
    final x = await readyAccount();
    world.gateway.forgetSession();
    await world.store.saveTransition(
      AccountTransition(
        opId: 'op-x',
        kind: TransitionKind.signOut,
        sourceUserId: x,
        sourceIsAnonymous: false,
        stage: TransitionStage.signedOut,
        createdAt: t0,
        updatedAt: t0,
      ),
    );

    world.boot();
    await world.coordinator.start();

    expectNewAnonymous(not: x);
    expect(world.device.resets, 1);
    expect(world.device.pushes, isEmpty);
  });

  test('sign-out and deletion need a confirmed account', () async {
    world.network.goOffline();
    world.boot();
    await world.coordinator.start();

    await expectLater(world.coordinator.signOut(), throwsA(isA<StateError>()));
    await expectLater(world.coordinator.continueWithoutAccount(), throwsA(isA<StateError>()));
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/auth/account_coordinator_signout_test.dart`
Expected: FAIL, with compile errors: `signOut`, `deleteAccount`, `continueWithoutAccount` and `confirmedLoss` are not defined.

- [ ] **Step 3: Add the re-auth context, the three commands and the sign-out flow**

In `lib/core/auth/account_coordinator.dart`:

1. **The enum.** Replace the enum at the bottom with:

   ```dart
   /// What a sign-in command does in the current state.
   enum _SignIn { link, target, reauth }
   ```

2. **`_signInContext`.** Replace its `return switch (_state) {…};` with:

   ```dart
       return switch (_state) {
         Ready(:final user) when user.isAnonymous => _SignIn.link,
         ReauthRequired() => _SignIn.reauth,
         _ => throw StateError('No account step takes a sign-in in $_state'),
       };
   ```

3. **The sign-in commands.** Replace `requestCode`, `verifyCode` and `continueWithGoogle` with:

```dart
  /// Sends a 6-digit code to [email]: to attach it to this anonymous user
  /// (#16), to sign in to the switch's target (#21), or to sign in again
  /// (#36). Throws [IdentityTakenFailure] when a link's email has an account
  /// (#17). Throws [UnsentChangesFailure] when a re-auth names another
  /// account while changes are unsent, unless [confirmedLoss] (ruling 6).
  Future<void> requestCode(String email, {bool confirmedLoss = false}) =>
      _serial(() async {
        switch (await _signInContext()) {
          case _SignIn.link:
            return _gateway.requestEmailLink(email);
          case _SignIn.target:
            return _gateway.requestEmailSignIn(email);
          case _SignIn.reauth:
            await _checkReplace(email, confirmedLoss: confirmedLoss);
            return _gateway.requestEmailSignIn(email);
        }
      });

  Future<void> verifyCode(String email, String code) => _serial(() async {
    switch (await _signInContext()) {
      case _SignIn.link:
        await _gateway.verifyEmailLink(email, code);
        return _validate(); // #16
      case _SignIn.target:
        return _signInTarget(
          () => _gateway.verifyEmailSignIn(email, code),
        ); // #21
      case _SignIn.reauth:
        await _gateway.verifyEmailSignIn(email, code);
        return _afterReauth(); // #36, #37
    }
  });

  Future<void> continueWithGoogle({bool confirmedLoss = false}) =>
      _serial(() async {
        final context = await _signInContext();
        final credential = _pendingGoogle ?? await _gateway.pickGoogle();
        try {
          switch (context) {
            case _SignIn.link:
              await _gateway.linkGoogle(credential);
              _pendingGoogle = null;
              return _validate(); // #16
            case _SignIn.target:
              await _signInTarget(() => _gateway.signInGoogle(credential));
              _pendingGoogle = null; // #21
            case _SignIn.reauth:
              await _checkReplace(
                credential.email,
                confirmedLoss: confirmedLoss,
              );
              await _gateway.signInGoogle(credential);
              _pendingGoogle = null;
              return _afterReauth(); // #36, #37
          }
        } on IdentityTakenFailure {
          _pendingGoogle = credential; // #17
          rethrow;
        } on UnsentChangesFailure {
          _pendingGoogle = credential; // asked again with confirmedLoss
          rethrow;
        }
      });
```

4. **The three commands.** Add after `cancelSwitch`:

```dart
  /// Signs this device out (#39–#41). X's changes are sent first; offline,
  /// that waits unless [discardUnsent]. Then the logs are shipped, the
  /// session goes, the device's account data is cleared, and a new
  /// anonymous user starts.
  Future<void> signOut({bool discardUnsent = false}) => _serial(() async {
    await _ensureNoTransition();
    final user = _readyUser();
    return _begin(
      _newTransition(
        TransitionKind.signOut,
        choice: discardUnsent ? TransitionChoice.discard : null,
        sourceUserId: user.id,
        sourceIsAnonymous: user.isAnonymous,
      ),
    );
  });

  /// Deletes the account on the server, then clears the device like a
  /// sign-out (#42–#44). Online only: offline, it refuses before anything
  /// changes.
  Future<void> deleteAccount() => _serial(() async {
    await _ensureNoTransition();
    final user = _readyUser();
    if (!await _network.isOnline) {
      throw const OfflineFailure(cause: 'deleting an account needs the network');
    }
    return _begin(
      _newTransition(
        TransitionKind.delete,
        sourceUserId: user.id,
        sourceIsAnonymous: user.isAnonymous,
      ),
    );
  });

  /// From REAUTH_REQUIRED: gives up the refused account. Its data on this
  /// device goes, and a new anonymous user starts (#38).
  Future<void> continueWithoutAccount() => _serial(() async {
    final last = switch (_state) {
      ReauthRequired(:final last) => last,
      _ => throw StateError('Only a refused sign-in continues without it'),
    };
    return _begin(
      _newTransition(
        TransitionKind.clearToAnon,
        sourceUserId: last.id,
        sourceIsAnonymous: false,
      ),
    );
  });

  /// Ruling 6: a re-auth as another account clears this device, so unsent
  /// changes are confirmed first.
  Future<void> _checkReplace(
    String? email, {
    required bool confirmedLoss,
  }) async {
    final last = (_state as ReauthRequired).last;
    if (confirmedLoss || _sameEmail(email, last.email)) return;
    final count = await _sync.pendingCount();
    if (count > 0) throw UnsentChangesFailure(count: count);
  }

  static bool _sameEmail(String? a, String? b) =>
      a != null && b != null && a.trim().toLowerCase() == b.trim().toLowerCase();

  /// #36: the same account, validated. #37: another one, a discard switch
  /// that is past the sign-in.
  Future<void> _afterReauth() async {
    final last = (_state as ReauthRequired).last;
    final userId = _gateway.currentUserId!;
    if (userId == last.id) return _validate();
    return _begin(
      _newTransition(
        TransitionKind.switchAccount,
        choice: TransitionChoice.discard,
        sourceUserId: last.id,
        sourceIsAnonymous: false,
      ).copyWith(targetUserId: userId, stage: TransitionStage.targetSignedIn),
    );
  }
```

5. **Driving sign-out, deletion and clear-to-anonymous.** In `_drive`, replace the fall-through group (`signOut`, `delete`, `clearToAnon`, with its error log and `stuck`) by:

   ```dart
         case TransitionKind.signOut:
         case TransitionKind.delete:
         case TransitionKind.clearToAnon:
           return _driveSignOut(t);
   ```

   Then add:

```dart
  /// #39–#45: send (sign-out), delete on the server (deletion), sign out,
  /// clear the device, start anonymous. Every step is idempotent, so a
  /// launch continues from the saved stage.
  Future<void> _driveSignOut(AccountTransition t) async {
    _gate.close();
    await _sync.pause();
    _emit(_inTransition(t));
    var s = t;
    if (s.stage == TransitionStage.started &&
        s.kind == TransitionKind.signOut) {
      try {
        await _sync.pushPending(); // #39
      } on Failure catch (error) {
        final accepted =
            error is OfflineFailure && s.choice == TransitionChoice.discard;
        if (!accepted) return _emit(_inTransition(s, error: error));
      }
      await _flushLogsQuietly();
    }
    if (s.stage == TransitionStage.started &&
        s.kind == TransitionKind.delete) {
      try {
        await _api.deleteAccount(); // #42
      } on ProfileGoneFailure {
        // #43: an earlier try already deleted it.
      } on LastAdminFailure catch (error) {
        return _refuseDelete(s, error); // #44
      } on OfflineFailure catch (error) {
        return _refuseDelete(s, error); // #44
      }
      s = await _save(s.copyWith(stage: TransitionStage.serverDeleted));
    }
    if (s.stage != TransitionStage.signedOut) {
      if (_gateway.currentUserId != null) await _gateway.signOutLocal(); // #40
      s = await _save(s.copyWith(stage: TransitionStage.signedOut));
    }
    await _reset.run(); // #41
    await _store.clearLastKnown();
    await _drop(s);
    return _settle();
  }

  Future<void> _refuseDelete(AccountTransition s, Failure failure) async {
    await _drop(s);
    _notice(DeleteRefused(failure));
    return _validate();
  }

  /// The logs go before the session does (spec §4: LogDatabase is kept, and
  /// shipped before sign-out). A failure costs only logs.
  Future<void> _flushLogsQuietly() async {
    try {
      await _flushLogs?.call();
    } on Object catch (error, stackTrace) {
      _log.warning(
        'auth.logs_not_shipped',
        category: LogCategory.state,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/core/auth`
Expected: PASS for every coordinator row in Tasks 10–12.

- [ ] **Step 5: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add lib test
git commit -m "feat(auth): re-auth, sign-out, deletion and clear-to-anonymous

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 13: Crash injection and network at every step

**Files:**
- Test: `test/core/auth/account_coordinator_crash_test.dart`

**Interfaces:**
- Consumes: the fakes' `KillSwitch.at`, `KillSwitch.offlineAt`, `FakeAuthServer.afterMergeCommit` and `FakeAuthGateway.afterSignIn`.

This task is tests only: they pin spec §9's crash and network rows. A failing case is a coordinator bug. Fix it in `account_coordinator.dart` with systematic-debugging, and ledger the fix under this task.

- [ ] **Step 1: Write the tests**

`test/core/auth/account_coordinator_crash_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_transition.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/error/failure.dart';

import '../../support/auth_fakes.dart';

// Auth spec §9 "Crash injection" and "Network": a kill, or a lost network,
// at each step of Switch, SignOut, Delete and AnonRecovery. After a launch
// and the user's own next steps, the invariants of §3.4 hold.
const _bEmail = 'b@example.com';
const _xEmail = 'x@example.com';

typedef _Step = Future<void> Function(AuthWorld world);

/// One flow: [setup] builds the world before the flow and returns what
/// [check] needs; [steps] are what the user does, in order; [target] is the
/// account a pending switch signs in to.
class _Flow {
  const _Flow(this.name, this.setup, this.steps, this.check, {this.target});

  final String name;
  final Future<Map<String, String>> Function(AuthWorld) setup;
  final List<_Step> steps;
  final void Function(AuthWorld, Map<String, String>, String reason) check;
  final String? target;
}

/// The user's steps in order. The app dies at the first kill: nothing after
/// it runs. A failure is what the user sees, and they go on.
Future<void> _run(AuthWorld world, List<_Step> steps) async {
  for (final step in steps) {
    try {
      await step(world);
    } on Killed {
      return;
    } on Failure {
      // Shown on screen; the next step is the user's next tap.
    }
  }
}

/// A launch after a kill.
Future<void> _launch(AuthWorld world) async {
  world.boot();
  await world.coordinator.start();
}

/// The user's next steps: a target sign-in when asked, Retry otherwise.
Future<void> _settle(AuthWorld world, String? target) async {
  for (var round = 0; round < 6; round++) {
    final state = world.state;
    if (state is Ready) return;
    final asks =
        (state is Transitioning && state.needsTargetSignIn) ||
        (state is Recovering && state.needsTargetSignIn);
    if (asks && target != null) {
      await world.coordinator.requestCode(target);
      await world.coordinator.verifyCode(target, FakeAuthGateway.code);
    } else {
      await world.coordinator.retry();
    }
  }
}

/// §3.4, checked on every outcome.
Future<void> _expectSettled(AuthWorld world, String reason) async {
  expect(world.state, isA<Ready>(), reason: reason);
  expect(world.gate.isClosed, isFalse, reason: reason);
  expect(await world.store.transition(), isNull, reason: reason);
  expect(world.secrets.values, isEmpty, reason: reason);
  expect(world.sync.paused, isFalse, reason: reason);
  for (final push in world.device.pushes) {
    expect(push.signedIn, push.owner, reason: '$reason: pushed $push');
  }
}

String _userId(AuthWorld world) => (world.state as Ready).user.id;

final _flows = [
  _Flow(
    'merge switch',
    (world) async {
      final a = await readyAnonymous(world);
      final b = world.server.addUser(email: _bEmail).id;
      return {'a': a, 'b': b};
    },
    [
      (world) => world.coordinator.requestCode(_bEmail),
      (world) => world.coordinator.beginSwitch(
        choice: TransitionChoice.merge,
        targetHint: _bEmail,
      ),
      (world) => world.coordinator.requestCode(_bEmail),
      (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
    ],
    (world, ids, reason) {
      final merged = world.server.receipts.isNotEmpty;
      if (merged) {
        // A committed merge never returns to A.
        expect(_userId(world), ids['b'], reason: reason);
        expect(world.device.owner, ids['b'], reason: reason);
        expect(world.server.users.containsKey(ids['a']), isFalse, reason: reason);
        final afterB = world.gateway.history.skipWhile((id) => id != ids['b']);
        expect(afterB, isNot(contains(ids['a'])), reason: reason);
      } else {
        // An uncommitted merge never clears A.
        expect(_userId(world), ids['a'], reason: reason);
        expect(world.device.resets, 0, reason: reason);
        expect(world.device.owner, ids['a'], reason: reason);
      }
      expect(world.server.anonymousCreated, 1, reason: '$reason: no second anonymous user');
    },
    target: _bEmail,
  ),
  _Flow(
    'discard switch',
    (world) async {
      final a = await readyAnonymous(world);
      final b = world.server.addUser(email: _bEmail).id;
      return {'a': a, 'b': b};
    },
    [
      (world) => world.coordinator.beginSwitch(choice: TransitionChoice.discard),
      (world) => world.coordinator.requestCode(_bEmail),
      (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
    ],
    (world, ids, reason) {
      final user = _userId(world);
      expect(user, anyOf(ids['a'], ids['b']), reason: reason);
      if (user == ids['a']) {
        expect(world.device.resets, 0, reason: reason);
      } else {
        expect(world.device.owner, ids['b'], reason: reason);
      }
      expect(world.server.users.containsKey(ids['a']), isTrue, reason: reason);
      expect(world.server.receipts, isEmpty, reason: reason);
    },
    target: _bEmail,
  ),
  _Flow(
    'sign-out',
    (world) async {
      final x = world.server.addUser(email: _xEmail).id;
      world.gateway.adopt(x);
      world.boot();
      await world.coordinator.start();
      world.device
        ..owner = x
        ..rows = 4
        ..pending = 2;
      return {'x': x};
    },
    [(world) => world.coordinator.signOut()],
    (world, ids, reason) {
      final user = _userId(world);
      if (user == ids['x']) {
        expect(world.device.resets, 0, reason: reason);
      } else {
        expect((world.state as Ready).user.isAnonymous, isTrue, reason: reason);
        expect(world.device.resets, greaterThan(0), reason: reason);
      }
    },
  ),
  _Flow(
    'deletion',
    (world) async {
      final x = world.server.addUser(email: _xEmail).id;
      world.gateway.adopt(x);
      world.boot();
      await world.coordinator.start();
      world.device
        ..owner = x
        ..rows = 4;
      return {'x': x};
    },
    [(world) => world.coordinator.deleteAccount()],
    (world, ids, reason) {
      final deleted = !world.server.users.containsKey(ids['x']);
      if (deleted) {
        expect(_userId(world), isNot(ids['x']), reason: reason);
        expect(world.device.resets, greaterThan(0), reason: reason);
      } else {
        expect(_userId(world), ids['x'], reason: reason);
        expect(world.device.resets, 0, reason: reason);
      }
    },
  ),
  _Flow(
    'anonymous recovery',
    (world) async {
      final a = await readyAnonymous(world);
      world.server.deleteUser(a);
      return {'a': a};
    },
    [_launch],
    (world, ids, reason) {
      expect(_userId(world), isNot(ids['a']), reason: reason);
      expect(world.server.anonymousCreated, 2, reason: '$reason: exactly one new anonymous user');
      expect(world.device.resets, 0, reason: reason);
      expect(world.device.owner, _userId(world), reason: reason);
      expect(world.device.pending, greaterThanOrEqualTo(world.device.rows), reason: reason);
    },
  ),
];

/// The steps an undisturbed run of [flow] takes.
Future<int> _stepsOf(_Flow flow) async {
  final world = AuthWorld();
  try {
    await flow.setup(world);
    world.kill.steps = 0;
    await _run(world, flow.steps);
    return world.kill.steps;
  } finally {
    await world.close();
  }
}

void main() {
  for (final flow in _flows) {
    test('${flow.name}: a kill at any step keeps the invariants', () async {
      final total = await _stepsOf(flow);
      expect(total, greaterThan(3));
      for (var k = 1; k <= total; k++) {
        final reason = '${flow.name}, killed at step $k of $total';
        final world = AuthWorld();
        try {
          final ids = await flow.setup(world);
          world.kill
            ..steps = 0
            ..at = k;
          await _run(world, flow.steps);
          world.kill.at = null;
          await _launch(world);
          await _settle(world, flow.target);
          await _expectSettled(world, reason);
          flow.check(world, ids, reason);
        } finally {
          await world.close();
        }
      }
    });

    test('${flow.name}: the network lost at any step never signs out or '
        'clears, and the flow finishes once it is back', () async {
      final total = await _stepsOf(flow);
      for (var k = 1; k <= total; k++) {
        final reason = '${flow.name}, offline from step $k of $total';
        final world = AuthWorld();
        try {
          final ids = await flow.setup(world);
          final resetsBefore = world.device.resets;
          world.kill
            ..steps = 0
            ..offlineAt = k;
          await _run(world, flow.steps);
          world.kill.offlineAt = null;
          if (flow.name.contains('switch')) {
            expect(
              world.device.resets == resetsBefore ||
                  world.server.receipts.isNotEmpty ||
                  world.device.pulls.isNotEmpty ||
                  (await world.store.transition())?.stage ==
                      TransitionStage.localCleared,
              isTrue,
              reason: '$reason: nothing cleared while offline before the target took over',
            );
          }
          world.network.goOnline();
          await pumpEventQueue();
          await _settle(world, flow.target);
          await _expectSettled(world, reason);
          flow.check(world, ids, reason);
        } finally {
          await world.close();
        }
      }
    });
  }

  test('named case: killed after the merge committed, before merged was saved', () async {
    final world = AuthWorld();
    addTearDown(world.close);
    final a = await readyAnonymous(world);
    final b = world.server.addUser(email: _bEmail).id;
    await _run(world, [(world) => world.coordinator.requestCode(_bEmail)]);
    await world.coordinator.beginSwitch(choice: TransitionChoice.merge);
    world.server.afterMergeCommit = () => throw const Killed();
    await world.coordinator.requestCode(_bEmail);
    await _run(world, [
      (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
    ]);
    world.server.afterMergeCommit = null;
    expect((await world.store.transition())!.stage, TransitionStage.targetSignedIn);

    world.boot();
    await world.coordinator.start();

    await _expectSettled(world, 'after-commit kill');
    expect(_userId(world), b);
    expect(world.server.receipts, hasLength(1));
    expect(world.server.users.containsKey(a), isFalse);
  });

  test('named case: killed between the target sign-in and saving targetSignedIn', () async {
    final world = AuthWorld();
    addTearDown(world.close);
    await readyAnonymous(world);
    final b = world.server.addUser(email: _bEmail).id;
    await _run(world, [(world) => world.coordinator.requestCode(_bEmail)]);
    await world.coordinator.beginSwitch(choice: TransitionChoice.merge);
    world.gateway.afterSignIn = () => throw const Killed();
    await world.coordinator.requestCode(_bEmail);
    await _run(world, [
      (world) => world.coordinator.verifyCode(_bEmail, FakeAuthGateway.code),
    ]);
    world.gateway.afterSignIn = null;
    expect((await world.store.transition())!.stage, TransitionStage.claimed);

    world.boot();
    await world.coordinator.start();

    await _expectSettled(world, 'sign-in kill');
    expect(_userId(world), b);
  });
}
```

- [ ] **Step 2: Run the tests**

Run: `flutter test test/core/auth/account_coordinator_crash_test.dart`
Expected: PASS.

A failure's `reason` names the flow and the step. Reproduce that case alone and use systematic-debugging on the coordinator. Never loosen an invariant: each line of `_expectSettled` and of the `check` functions is a row of §3.4.

The switch clause in the network test says the device is cleared only once the flow is past the target sign-in. That is Review Focus 2 in its offline form.

- [ ] **Step 3: Commit**

```bash
dart format test && flutter analyze
git add test
git commit -m "test(auth): the account invariants after a kill or a lost network at every step

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 14: Providers, start-up wiring, `isAdmin` from `me()`, and the one-door rule

**Files:**
- Create:
  - `lib/core/auth/di/auth_providers.dart`, and its generated `auth_providers.g.dart`
  - `test/core/auth/di/auth_providers_test.dart`
  - `test/architecture/sdk_door_test.dart`
- Modify:
  - `lib/main.dart`
  - `lib/features/monitoring/presentation/widgets/sections/monitoring_entry_section_widget.dart`
  - `lib/features/monitoring/presentation/widgets/sections/monitoring_admin_gate_widget.dart`
  - `test/support/monitoring_fakes.dart`
  - `test/features/monitoring/presentation/monitoring_entry_section_test.dart`
  - `test/app/monitoring_routes_test.dart`
  - `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`
- Delete:
  - `lib/features/monitoring/di/auth_session_provider.dart` and `.g.dart`
  - `lib/features/monitoring/di/is_admin_provider.dart` and `.g.dart`
  - `test/features/monitoring/di/is_admin_provider_test.dart`

**Interfaces:**
- Consumes: `AccountCoordinator` (Tasks 10–12), `syncControlProvider` (Task 7), `logSchedulerProvider`, `databaseProvider` and `dayClockProvider`.
- Produces:
  - `accountCoordinatorProvider`: `AccountCoordinator?`, keepAlive, null without Supabase.
  - `authStateProvider`: `Stream<AuthState>`.
  - `currentAccountProvider`: `AccountUser?`.
  - `isAdminProvider`: `bool`, now in `core/auth/di`.

- [ ] **Step 1: Write the failing tests**

`test/core/auth/di/auth_providers_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/di/auth_providers.dart';
import 'package:memox/core/network/supabase_config.dart';
import 'package:memox/core/sync/di/sync_providers.dart';

// Auth spec §5 and O8: the admin entry shows for a confirmed admin only, and
// follows the account; a build with no Supabase project stays local.
const _admin = AccountUser(id: 'a', isAnonymous: false, role: AccountRole.admin);
const _user = AccountUser(id: 'u', isAnonymous: false, role: AccountRole.user);

void main() {
  test('a build with no Supabase project is local only and has no admin', () async {
    final container = ProviderContainer(
      overrides: [
        supabaseConfigProvider.overrideWithValue(
          const SupabaseConfig(url: '', publishableKey: ''),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(isAdminProvider, (_, _) {});
    await container.read(authStateProvider.future);

    expect(container.read(accountCoordinatorProvider), isNull);
    expect(container.read(authStateProvider).value, isA<LocalOnly>());
    expect(container.read(isAdminProvider), isFalse);
  });

  test('admin follows the confirmed account; validating is not admin yet', () async {
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith((ref) => states.stream)],
    );
    addTearDown(container.dispose);
    final seen = <bool>[];
    container.listen(isAdminProvider, (_, next) => seen.add(next));

    states.add(const Validating(_admin));
    await pumpEventQueue();
    expect(container.read(isAdminProvider), isFalse);
    states.add(const Ready(_admin));
    await pumpEventQueue();
    expect(container.read(isAdminProvider), isTrue);
    expect(container.read(currentAccountProvider), _admin);
    states.add(const Ready(_user));
    await pumpEventQueue();

    expect(container.read(isAdminProvider), isFalse);
    expect(seen, [true, false]);
  });
}
```

`test/architecture/sdk_door_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The SDKs that only their door files may import (auth spec §5, plan
/// rulings 18–19). Paths are prefixes.
const _doors = <String, List<String>>{
  'package:supabase_flutter/': [
    'lib/core/auth/supabase_',
    'lib/core/network/',
    'lib/core/sync/supabase_sync_api.dart',
  ],
  'package:gotrue/': ['lib/core/auth/supabase_'],
  'package:google_sign_in/': ['lib/core/auth/google_'],
  'package:flutter_secure_storage/': ['lib/core/auth/secure_'],
};

final _import = RegExp(r"^\s*import\s+'([^']+)'", multiLine: true);

/// Each file of [sources] (path → text) that imports an SDK outside its
/// doors.
List<String> doorViolations(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    for (final match in _import.allMatches(text))
      for (final MapEntry(key: package, value: doors) in _doors.entries)
        if (match.group(1)!.startsWith(package) && !doors.any(path.startsWith))
          '$path imports ${match.group(1)}',
];

void main() {
  test('an SDK imported outside its door is found', () {
    final found = doorViolations({
      'lib/features/x/data/x.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';",
      'lib/core/auth/account_coordinator.dart':
          "import 'package:google_sign_in/google_sign_in.dart';",
      'lib/core/auth/supabase_auth_gateway.dart':
          "import 'package:supabase_flutter/supabase_flutter.dart';",
      'lib/core/auth/secure_secret_store.dart':
          "import 'package:flutter_secure_storage/flutter_secure_storage.dart';",
    });

    expect(found, hasLength(2));
  });

  test('lib/ reaches the SDKs only through their doors', () {
    final sources = {
      for (final file in Directory('lib').listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
          file.path.replaceAll(r'\', '/'): file.readAsStringSync(),
    };

    expect(doorViolations(sources), isEmpty);
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/core/auth/di/auth_providers_test.dart test/architecture/sdk_door_test.dart`
Expected: FAIL:
- the providers test fails to compile, because `auth_providers.dart` does not exist;
- the door test's second case lists `lib/features/monitoring/di/auth_session_provider.dart` and `is_admin_provider.dart`.

- [ ] **Step 3: Write the providers**

`lib/core/auth/di/auth_providers.dart`:

```dart
import 'dart:async';

import 'package:memox/core/auth/account_coordinator.dart';
import 'package:memox/core/auth/account_store.dart';
import 'package:memox/core/auth/account_user.dart';
import 'package:memox/core/auth/auth_state.dart';
import 'package:memox/core/auth/google_credential_source.dart';
import 'package:memox/core/auth/secure_secret_store.dart';
import 'package:memox/core/auth/supabase_account_api.dart';
import 'package:memox/core/auth/supabase_auth_gateway.dart';
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/core/database/local_data_reset.dart';
import 'package:memox/core/logging/di/logging_providers.dart';
import 'package:memox/core/network/network_status.dart';
import 'package:memox/core/sync/di/sync_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_providers.g.dart';

/// The account's one owner (auth spec §5). Null when this build names no
/// Supabase project (plan ruling 20). main.dart prepares and starts it.
@Riverpod(keepAlive: true)
AccountCoordinator? accountCoordinator(Ref ref) {
  if (!ref.watch(supabaseConfigProvider).isEnabled) return null;
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(dayClockProvider);
  final google = GoogleCredentialSource();
  final coordinator = AccountCoordinator(
    gateway: SupabaseAuthGateway.instance(pickGoogle: google.pick),
    api: SupabaseAccountApi.instance(),
    store: AccountStore(db),
    secrets: SecureSecretStore(),
    sync: ref.watch(syncControlProvider),
    localReset: LocalDataReset(db, now: clock.now),
    gate: db.mutationGate,
    network: ConnectivityNetworkStatus(),
    flushLogs: () async {
      await ref.read(logSchedulerProvider)?.syncNow();
    },
    now: clock.now,
  );
  ref.onDispose(() => unawaited(coordinator.dispose()));
  return coordinator;
}

/// Where the account stands: the single source of truth for sync, the
/// router and every screen (auth spec §5).
@Riverpod(keepAlive: true)
Stream<AuthState> authState(Ref ref) {
  final coordinator = ref.watch(accountCoordinatorProvider);
  if (coordinator == null) return Stream.value(const LocalOnly());
  return coordinator.watch();
}

/// The account `me()` confirmed, or null until one is.
@Riverpod(keepAlive: true)
AccountUser? currentAccount(Ref ref) =>
    switch (ref.watch(authStateProvider).value) {
      Ready(:final user) => user,
      _ => null,
    };

/// Whether to show admin entries (ADR-018 §7, auth spec O8): a confirmed
/// account whose `profiles.role` is admin. Visibility only: the RPCs check
/// again (`FORBIDDEN`).
@Riverpod(keepAlive: true)
bool isAdmin(Ref ref) => ref.watch(currentAccountProvider)?.isAdmin ?? false;
```

Check that `dayClockProvider`'s value exposes `now` as a method that can be torn off, as `sync_providers.dart` already uses `clock.now`.

- [ ] **Step 4: Start the coordinator in `main()`**

In `lib/main.dart`:
- Add `import 'dart:async';` and `import 'package:memox/core/auth/di/auth_providers.dart';`.
- Replace

  ```dart
  container
    ..read(syncSchedulerProvider)
    ..read(logSchedulerProvider);
  ```

  with:

  ```dart
  // Auth spec R3: a pending account transition shuts the write gate before
  // the first frame. The rest of the start runs in the background: the
  // first frame never waits for the network (R1, R2).
  final accounts = container.read(accountCoordinatorProvider);
  await accounts?.prepare();
  container
    ..read(syncSchedulerProvider)
    ..read(logSchedulerProvider);
  if (accounts != null) unawaited(accounts.start());
  ```

- [ ] **Step 5: Move Monitoring to the core admin check**

1. **The two widgets.** In `monitoring_entry_section_widget.dart` and `monitoring_admin_gate_widget.dart`, replace `import 'package:memox/features/monitoring/di/is_admin_provider.dart';` with `import 'package:memox/core/auth/di/auth_providers.dart';`.

2. **The old providers.** Delete them and their generated files, and the test that tested them (`is_admin_provider_test.dart`). Its cases now live in `auth_providers_test.dart`.

   ```bash
   git rm lib/features/monitoring/di/auth_session_provider.dart lib/features/monitoring/di/auth_session_provider.g.dart \
     lib/features/monitoring/di/is_admin_provider.dart lib/features/monitoring/di/is_admin_provider.g.dart \
     test/features/monitoring/di/is_admin_provider_test.dart
   ```

3. **`test/support/monitoring_fakes.dart`.** Remove `sessionWithRole` and the `supabase_flutter` import, and add:

   ```dart
   import 'package:memox/core/auth/account_user.dart';

   /// A confirmed admin, and a confirmed user (auth spec O8).
   const adminAccount = AccountUser(
     id: '00000000-0000-0000-0000-0000000000ad',
     email: 'admin@example.com',
     isAnonymous: false,
     role: AccountRole.admin,
   );
   const userAccount = AccountUser(
     id: '00000000-0000-0000-0000-0000000000a5',
     email: 'user@example.com',
     isAnonymous: false,
     role: AccountRole.user,
   );
   ```

4. **`monitoring_entry_section_test.dart`.**
   - Replace the imports of `auth_session_provider.dart`, `is_admin_provider.dart` and `supabase_flutter` with `package:memox/core/auth/di/auth_providers.dart` and `package:memox/core/auth/auth_state.dart`.
   - Replace `authSessionProvider.overrideWith((ref) => Stream.value(sessionWithRole('admin')))` with `authStateProvider.overrideWith((ref) => Stream.value(const Ready(adminAccount)))`.
   - In the test that drives a stream, make the controller a `StreamController<AuthState>` over `authStateProvider`, and map:
     - `sessions.add(sessionWithRole(null))` → `const Ready(userAccount)`;
     - `sessionWithRole('admin')` → `const Ready(adminAccount)`;
     - `null` → `const Validating(null)`.
   - Keep every expectation as it is. The test names that say "session" may say "account".

5. **`test/app/monitoring_routes_test.dart`.** Only its import changes, to `package:memox/core/auth/di/auth_providers.dart`, because `isAdminProvider.overrideWithValue` keeps its name.

Run `grep -rn "auth_session_provider\|is_admin_provider\|sessionWithRole\|isAdminSession" lib test`.
Expected: no output.

- [ ] **Step 6: Add the guard's one-door rule**

Append to `code-verification-guard-v2/registries/projects/memox-v8/rules/memox-architecture-rules.yaml`, after `reminder_plugins_have_one_door`:

```yaml
  # Auth spec §5: the SDKs of identity, sync and secrets are reached through
  # their door files only, so no Supabase or Google type leaks into a
  # feature (core-auth plan rulings 18-19; test/architecture/sdk_door_test.dart).
  - id: memox_v8.architecture.auth_sdks_have_one_door
    type: regex
    severity: error
    enabled: true
    message: >-
      Import `supabase_flutter`, `gotrue`, `google_sign_in` and
      `flutter_secure_storage` only in their door files
      (`lib/core/auth/supabase_*`, `lib/core/auth/google_*`,
      `lib/core/auth/secure_*`, `lib/core/network/`,
      `lib/core/sync/supabase_sync_api.dart`); use the account coordinator,
      the gateway ports or `supabase_client.dart` instead.
    scopes:
      - dart_lib
    exclude:
      - lib/core/auth/supabase_*.dart
      - lib/core/auth/google_*.dart
      - lib/core/auth/secure_*.dart
      - lib/core/network/**
      - lib/core/sync/supabase_sync_api.dart
    patterns:
      - "^\\s*import\\s+'package:(supabase_flutter|gotrue|google_sign_in|flutter_secure_storage)/"
    tags:
      - memox-v8
      - architecture
```

Find the guard command in `.claude/skills/flutter-workflow/scripts/dod_check.sh`. Run it once with a planted `import 'package:supabase_flutter/supabase_flutter.dart';` in a scratch copy of a feature file to confirm that the exclude globs match, then remove the plant. If the guard's `exclude` does not take globs, list the door files by name, and ledger the ruling.

- [ ] **Step 7: Run the tests to verify they pass**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/core test/architecture test/features/monitoring test/app/monitoring_routes_test.dart`
Expected: PASS.

- [ ] **Step 8: Format, analyze, commit**

```bash
dart format lib test && flutter analyze
git add -A lib test code-verification-guard-v2
git commit -m "feat(auth): the coordinator starts with the app; admin comes from me()

Sync resumes only once the account is confirmed. The identity, sync and
secret SDKs are imported only through their door files.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

### Task 15: Documents, and the whole gate

**Files:**
- Modify:
  - `docs/wbs_supabase.md`: SB-A2 and SB-A3 rows, and the update log
  - `docs/superpowers/specs/2026-09-30-auth-design.md`: the status line
  - `supabase/README.md`: the Google Web client define
  - `.claude/skills/flutter-data-layer/SKILL.md`: the sync-gating sentence
  - `docs/shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md`: login is no longer deferred, with a pointer to the auth spec

- [ ] **Step 1: Update the documents**

1. **`docs/wbs_supabase.md`.**
   - SB-A2 and SB-A3 get status `đang làm`, with the note: `P2 (core auth, logic, plan 2026-09-30-accounts-core-auth.md) xong; UI ở P3`.
   - The update log gains a 2026-09-30 line in the file's style: `P2 core auth: AccountCoordinator (45 hàng của spec §3.3), sync chỉ chạy khi Ready, isAdmin từ me(); chưa có màn hình (P3)`.
2. **The spec's status line** (line 3) adds: `P2 (core auth) implemented by docs/superpowers/plans/2026-09-30-accounts-core-auth.md.`
3. **`supabase/README.md`.** Beside the `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` defines, document `--dart-define=GOOGLE_WEB_CLIENT_ID=<Web OAuth client id of SB-A4>`: native Google sign-in needs it (auth spec O11).
4. **`.claude/skills/flutter-data-layer/SKILL.md`.** Where it says sync signs in anonymously, write instead: sync never signs in; `AccountCoordinator` (`lib/core/auth/`) owns sign-in and resumes the paused sync scheduler once `me()` confirms the account (auth spec R2).

   Find the sentence first with `grep -n "anonym" .claude/skills/flutter-data-layer/SKILL.md`. If none says that, add the sentence to its sync section.
5. **ADR-013.** In its decision table, the "login làm sau" row gets a dated note: `2026-09-30: login đã thiết kế ở docs/superpowers/specs/2026-09-30-auth-design.md (SB-A1); P1 server và P2 core auth xong.` The decision itself stays; this is the record of what followed.

Run: `python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`.

- [ ] **Step 2: The whole gate**

```bash
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- '*.g.dart' || echo "generated files changed: commit them"
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --exclude-tags golden
bash .claude/skills/flutter-architecture/scripts/check_architecture.sh
```

Also run the guard and the docs check as `.claude/skills/flutter-workflow/scripts/dod_check.sh` does. Its codegen, format, analyze and test steps repeat the ones above, so it can replace them.

Expected:
- every command succeeds;
- `flutter test` reports no failure;
- no golden changed (`git status test/**/goldens` is clean).

Write the counts into the ledger.

- [ ] **Step 3: Commit**

```bash
git add docs supabase/README.md .claude/skills/flutter-data-layer/SKILL.md
git commit -m "docs: core auth (P2) — WBS, spec status, Google define, sync gating

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01RGMkn5cK1mr4YTxedznqo2"
```

## Self-review (done while writing)

- **Spec coverage.**

  | Spec section | Tasks |
  |---|---|
  | §3.1 R1–R3 | 10–12; the gate in 5 |
  | §3.2 states | 3 |
  | §3.3 rows #1–#12, #14, #15 | 10 |
  | §3.3 rows #16–#35 | 11 |
  | §3.3 rows #13, #36–#45 | 12 |
  | §3.4 invariants | 13 |
  | §4 persisted state | 2, 4 |
  | §4 `LocalDataReset` | 6 |
  | §4 secrets purge | 4, 10 |
  | §5 types | 3 |
  | §5 gateway | 9 |
  | §5 API | 8 |
  | §5 stores | 4 |
  | §5 `SyncControl` | 7 |
  | §5 gate | 5 |
  | §5 providers | 14 |
  | §5 import rule | 1, 14 |
  | §5 packages | 4, 9 |
  | §9 coordinator, crash, network, Drift, data and architecture rows | 10–13, 2, 5, 6, 8, 9, 14 |
  | §11 P2 "`start()` in bootstrap" | 14 |
  | §11 P2 "sync gated on Ready" | 7, 10, 14 |
  | §11 P2 "isAdmin from me()" | 14 |

  Not in P2, by §11: screens, router rules, goldens and the device check (P3); the Users screen (P4).

- **Placeholders.** None. Task 10's interim `_drive` arm for kinds that Tasks 11 and 12 add is real behaviour (it keeps the gate shut, logs, and marks the transition stuck), and later tasks replace it with exact code.

- **Types.** The names are used consistently across tasks:
  - `AccountTransition.copyWith({stage, targetUserId, updatedAt})`
  - `TransitionStage.isBefore` and `atLeast`
  - `SyncControl.pushPending`, `pullAll` and `markAllPending`
  - `AccountStore.saveTransition`, which returns the transition
  - `backupSecretKey` and `claimSecretKey`
  - the fakes' `afterSignIn` and `afterMergeCommit`

- **Review Focus.** Each item has its test:

  | Item | Test |
  |---|---|
  | 1 | Task 10, `Review Focus 1: …` |
  | 2 | Task 11, `Review Focus 2: …`, and Task 13's network sweep |
  | 3 | Task 11, `Review Focus 3: …` |
  | 4 | Task 7's `markAllPending` test and Task 13's anonymous-recovery flow |
  | 5 | Task 5's gate tests |
