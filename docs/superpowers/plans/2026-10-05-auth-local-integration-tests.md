# Auth integration tests on a local Supabase — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the email-based device-check rows D1, D3–D8, D10–D12 of auth spec §9.1 run as host tests against a local Supabase stack, from one script.

**Architecture:** each test builds one or two "devices" from production classes (`AccountCoordinator`, `SupabaseAuthGateway`, `SupabaseAccountApi`, `SupabaseSyncApi`, `SyncCoordinator`, `AppSyncControl`, Drift in memory) on their own `SupabaseClient`, fakes only the secret store and the network, reads OTP codes from the stack's Mailpit and checks the server with a service-role client. The suite lives outside `test/`, so the default suite, its bundler and `dod_check.sh` never see it.

**Tech Stack:** Flutter `flutter_test` (plain `test()`), `supabase_flutter`'s `SupabaseClient`, `http`, Drift `NativeDatabase.memory`, Supabase CLI local stack (Docker), Mailpit HTTP API.

**Spec:** `docs/superpowers/specs/2026-10-05-auth-local-integration-tests-design.md`

## Global Constraints

- No production code changes; no new entry in `pubspec.yaml` (`http` and `supabase_flutter` are already dependencies).
- Plain `test()` only, never `testWidgets` or `TestWidgetsFlutterBinding`: the binding blocks real HTTP.
- **Location (amends spec §7):** `test_supabase/auth/`, not `test/integration/auth/` with a tag. `bundle_tests.py` refuses a library-level `@Tags` in a host file and discovers every `_test.dart` under `test/`; a top-level directory keeps the suite out of `run_tests.sh` and `dod_check.sh` without touching them. Task 6 records the amendment in the spec.
- Environment variables, set by the script: `MEMOX_IT_API_URL`, `MEMOX_IT_PUBLISHABLE_KEY`, `MEMOX_IT_SERVICE_ROLE_KEY`, `MEMOX_IT_MAILPIT_URL`.
- Every test uses fresh addresses `it-<12 random hex>@example.com`; no test relies on an empty database or cleans up.
- Templates: subject `{{ .Token }} is your MemoX code`; body exactly the three lines of `supabase/README.md` "Sign-in setup" step 3.
- `[auth.rate_limit] email_sent = 100` locally.
- A missing variable or an unreachable stack fails with a message naming it; never a skip.
- Waits come from polling the server or the state stream with a timeout (default 20 s), never from a fixed sleep.

## Review Focus

1. **The stack is down or a variable is unset** → the run fails at once with the name of what is missing (Task 1, `LocalEnv` test).
2. **A re-sent code for the same address** → the reader returns the newest message received after the request, not an older code (Task 1, Mailpit test).
3. **Running the script twice** → the second run passes on a database the first one filled (fresh addresses; Task 1 runs the smoke test twice).
4. **The default suite picks the files up** → `run_tests.sh` and `dod_check.sh` stay green and do not run `test_supabase/` (Task 1 verification).
5. **A local-only pass** → each row checks the server through the probe, not only the device's database (every row task asserts a `ServerProbe` value).

---

### Task 1: Local stack, script, environment and Mailpit reader

**Files:**
- Create: `supabase/templates/magic_link.html`, `supabase/templates/confirmation.html`, `supabase/templates/email_change.html`
- Modify: `supabase/config.toml` (`[auth.rate_limit] email_sent`, `[auth.email.template.magic_link|confirmation|email_change]` with `subject` and `content_path`)
- Create: `tools/supabase/run_auth_it.sh`
- Create: `test_supabase/auth/support/local_env.dart`, `test_supabase/auth/support/mailpit.dart`
- Test: `test_supabase/auth/mailpit_test.dart`

**Interfaces:**
- Produces: `class LocalEnv { final Uri apiUrl; final String publishableKey; final String serviceRoleKey; final Uri mailpitUrl; static LocalEnv fromMap(Map<String, String> vars); static LocalEnv read(); }` — `read()` is `fromMap(Platform.environment)`; `fromMap` throws `StateError('MEMOX_IT_… is not set: run tools/supabase/run_auth_it.sh')` naming the first missing variable.
- Produces: `String freshEmail()` in `local_env.dart`.
- Produces: `class Mailpit { Mailpit(Uri base); Future<String> codeFor(String to, {required DateTime after, Duration timeout}); }` — searches `GET {base}/api/v1/search?query=to:"<to>"`, keeps messages whose `Created` is after `after`, takes the newest, parses its `Subject` with `^(\d{6}) is your MemoX code$`; on timeout throws `TimeoutException` naming the address.

- [ ] **Step 1: Write the failing test** — `mailpit_test.dart`, group `local stack`:
  - `test('LocalEnv names a missing variable')`: `expect(() => LocalEnv.fromMap({}), throwsA(isA<StateError>().having((e) => e.message, 'message', contains('MEMOX_IT_API_URL'))))` (so `read()` delegates to `LocalEnv.fromMap(Platform.environment)`).
  - `test('a code requested by email arrives through Mailpit')`: a bare `SupabaseClient(env.apiUrl, env.publishableKey)` calls `auth.signInWithOtp(email: a)`; `expect(await mailpit.codeFor(a, after: t0), matches(RegExp(r'^\d{6}$')))`.
  - `test('a second request reads the newer code')`: request twice for the same address 1.1 s apart (`max_frequency` is `1s`), with `t1` taken before the second; `codeFor(a, after: t1)` returns the second message's code and it verifies with `auth.verifyOTP(type: OtpType.email, email: a, token: code)`.
- [ ] **Step 2: Run to see it fail** — `bash tools/supabase/run_auth_it.sh` does not exist yet; run `flutter test test_supabase/auth/mailpit_test.dart`. Expected: compile failure (`LocalEnv` undefined).
- [ ] **Step 3: Templates and config** — three templates with the constraint's subject and body; in `config.toml` set `email_sent = 100` and, for each of `magic_link`, `confirmation`, `email_change`, `subject = "{{ .Token }} is your MemoX code"` and `content_path = "./supabase/templates/<name>.html"`.
- [ ] **Step 4: Script** — `tools/supabase/run_auth_it.sh [flutter test args…]`: `set -euo pipefail`; `npx supabase start`; parse `npx supabase status -o env` (`API_URL`; `PUBLISHABLE_KEY` else `ANON_KEY`; `SERVICE_ROLE_KEY`; `MAILPIT_URL` else `INBUCKET_URL`), export the four `MEMOX_IT_*`, fail naming any that is empty; run `TZ=UTC flutter test -r failures-only "${@:-test_supabase/auth}"`. Header comment: why it exists and when it is required (spec §7).
- [ ] **Step 5: Implement `LocalEnv`, `freshEmail`, `Mailpit`** as in Interfaces.
- [ ] **Step 6: Run** — `bash tools/supabase/run_auth_it.sh test_supabase/auth/mailpit_test.dart` twice. Expected: both PASS.
- [ ] **Step 7: The default suite ignores it** — `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`, and `test_supabase` appears in no test report line.
- [ ] **Step 8: Commit** — `test(auth): local Supabase stack, script and Mailpit reader for auth ITs`.

### Task 2: A device, the server probe, and D1

**Files:**
- Create: `test_supabase/auth/support/local_device.dart`, `test_supabase/auth/support/server_probe.dart`
- Test: `test_supabase/auth/link_test.dart`

**Interfaces:**
- Consumes: `LocalEnv`, `Mailpit`, `freshEmail` (Task 1); `openTestDatabase()` (`test/support/test_database.dart`), `FakeSecretStore` (`test/support/fake_secret_store.dart`) by relative import.
- Produces:
  - `class SwitchableNetwork implements NetworkStatus { bool online = true; void setOnline(bool value); }` — `reconnects` emits on every switch back on.
  - `class SwitchableHttpClient extends http.BaseClient` — throws `SocketException('offline')` from `send` while its `SwitchableNetwork` is off.
  - `class LocalDevice` with `static Future<LocalDevice> launch(LocalEnv env, {AccountStore Function(AppDatabase db)? store})`, `Future<void> reboot({AccountStore Function(AppDatabase db)? store})` (disposes the coordinator, builds a new one on the same client, database and secrets, and `start()`s it), fields `db`, `secrets`, `network`, `client`, `coordinator`, getters `String? userId`, `AuthState state`, and `Future<T> waitFor<T extends AuthState>({Duration timeout})`, `Future<String> createDeck(String name)`, `Future<List<String>> deckNames()`, `Future<void> syncNow()`, `Future<void> signInByEmail(Mailpit mail, String email)` (request, read, verify through the coordinator), `Future<void> close()`.
  - `class ServerProbe { ServerProbe(LocalEnv env); Future<bool> userExists(String id); Future<String?> emailOf(String id); Future<Set<String>> deckNames(String userId); Future<void> makeAdmin(String userId); Future<void> signOutEverywhere(String accessToken); }` over a service-role client: `auth.admin.getUserById`, `from('deck').select('name').eq('user_id', id).isFilter('deleted_at', null)`, `from('profiles').update({'role': 'admin'})`, `auth.admin.signOut(token, scope: SignOutScope.global)`.
- Wiring of `LocalDevice.launch` mirrors `accountCoordinatorProvider` and `sync_providers.dart`: `SupabaseClient(apiUrl, publishableKey, httpClient: SwitchableHttpClient(network), authOptions: const AuthClientOptions(autoRefreshToken: false))`; `SupabaseSyncApi(ensureSession: throws SyncSessionMissing without a session, rpc: client.rpc)`; `SyncCoordinator` with the same seven adapters in the same order; `AppSyncControl(scheduler: null, …)` — sync runs only through `syncNow()` (`SyncCoordinator.runOnce`), so every test syncs where it means to; `AccountCoordinator(gateway: SupabaseAuthGateway(client.auth, pickGoogle: () => throw UnsupportedError('no Google here')), api: SupabaseAccountApi(rpc: client.rpc, refreshSession: client.auth.refreshSession), store: (store ?? AccountStore.new)(db), secrets, sync, localReset: LocalDataReset(db), gate: db.mutationGate, network, retryDelay: (_) => Duration.zero, logger: AppLogger(sinks: const []))`; then `start()` and `waitFor<Ready>()`. `createDeck` goes through `DeckRepositoryImpl(db).createRootDeck(name:, schedulerType: SchedulerType.eightBoxes)` so it writes the outbox like the app.

- [ ] **Step 1: Write the failing test** — `link_test.dart`, `test('D1 linking an email keeps the user id and the decks')`: launch A, `createDeck('A1')`, `createDeck('A2')`, `syncNow()`; `id = A.userId`; `signInByEmail(mail, e)`; expect `A.state` is `Ready` with `user.email == e` and `!user.isAnonymous`, `A.userId == id`, `A.deckNames()` equals `{'A1','A2'}`, `probe.emailOf(id) == e`, `probe.deckNames(id)` equals `{'A1','A2'}`.
- [ ] **Step 2: Run to see it fail** — `bash tools/supabase/run_auth_it.sh test_supabase/auth/link_test.dart`. Expected: compile failure (`LocalDevice` undefined).
- [ ] **Step 3: Implement `SwitchableNetwork`, `SwitchableHttpClient`, `LocalDevice`, `ServerProbe`** as in Interfaces. If the probe's deck read fails with `42501`, the service role lacks a grant: stop and report it; do not add a migration.
- [ ] **Step 4: Run** — same command. Expected: PASS.
- [ ] **Step 5: Commit** — `test(auth): a local device and server probe; D1 on a real stack`.

### Task 3: Switching a device to an account — D3, D4, D5

**Files:**
- Test: `test_supabase/auth/switch_test.dart`

**Interfaces:**
- Consumes: `LocalDevice`, `ServerProbe`, `Mailpit`, `freshEmail` (Tasks 1–2); `Killed` (`test/support/auth_fakes.dart`); `TransitionChoice`, `TransitionStage`, `IdentityTakenFailure` (production).
- Produces: in this file, `Future<String> accountWithDecks(LocalEnv env, Mailpit mail, Set<String> names)` (a device that creates, syncs and links, then closes; returns the email) and `Future<void> moveTo(LocalDevice b, Mailpit mail, String email, TransitionChoice choice)`: `requestCode(email)` must throw `IdentityTakenFailure`; `beginSwitch(choice: choice, targetHint: email)`; `waitFor<Transitioning>` with `isAwaitingTargetSignIn`; `signInByEmail(mail, email)`; `waitFor<Ready>()`; `syncNow()`.
- A store that stops after the merge: `class _StopAfterMerged extends AccountStore` overriding `saveTransition` to call `super` and then `throw const Killed()` when `t.stage == TransitionStage.merged`.

- [ ] **Step 1: Write the failing tests**
  - `test('D3 merge: B's decks join the account and B's anonymous user is gone')`: account with `{'A1'}`; B launched with `{'B1','B2'}` synced, `anon = B.userId`; `moveTo(B, …, merge)`; expect `B.deckNames()` equals `{'A1','B1','B2'}`, `probe.deckNames(B.userId)` the same, `probe.userExists(anon)` false.
  - `test('D4 discard: B shows only the account's decks')`: same with `TransitionChoice.discard`; expect `{'A1'}` on B and on the server, and none of `B1`, `B2` under any of the two users.
  - `test('D5 a merge stopped after its commit resumes once')`: B launched with `store: _StopAfterMerged.new`; `moveTo` throws `Killed`; `B.reboot()` with the plain store; `waitFor<Ready>()`, `syncNow()`; expect the D3 sets, and `probe.deckNames` has each name once (compare a list's length with its set's).
- [ ] **Step 2: Run to see them fail** — `bash tools/supabase/run_auth_it.sh test_supabase/auth/switch_test.dart`. Expected: failures only if the behaviour is wrong; with Tasks 1–2 in place these exercise existing code, so a first run that passes is acceptable here — record "passed on first run" in the commit body. A failure is a finding: stop, report it with the probe's values, and add a WBS row before any fix (spec §9.1 rule).
- [ ] **Step 3: Commit** — `test(auth): D3, D4, D5 on a real stack`.

### Task 4: Leaving — D6, D7, D11, D12

**Files:**
- Test: `test_supabase/auth/leave_test.dart`

**Interfaces:**
- Consumes: Tasks 1–3 (`accountWithDecks`, `moveTo` move to `support/flows.dart` when a second file needs them; Task 4 is that file); `UnsentChangesFailure`, `OfflineFailure`.

- [ ] **Step 1: Write the tests**
  - `test('D6 signing out online sends first, then leaves a new anonymous user')`: A linked with `{'A1'}`; `createDeck('A2')` without syncing; `signOut()`; expect `probe.deckNames(accountId)` equals `{'A1','A2'}`, `A.state` `Ready` anonymous with a new id, `A.deckNames()` empty; then `moveTo(A, …, discard)` and `deckNames()` equals `{'A1','A2'}`.
  - `test('D7 signing out offline names the unsent changes and clears nothing')`: A linked, synced; `network.setOnline(false)`; `createDeck('A2')`; `signOut()` throws `UnsentChangesFailure` with `count == 1`; `A.state` still `Ready` with the email; `A.deckNames()` contains `A2`.
  - `test('D11 deleting the account removes it and its rows')`: A linked with `{'A1'}`; `deleteAccount()`; `probe.userExists(id)` false, `probe.deckNames(id)` empty; `A.state` `Ready` anonymous with a new id and no decks.
  - `test('D12 asking for a code offline changes nothing; online it completes')`: A anonymous; network off; `requestCode(e)` throws `OfflineFailure`; `A.state` unchanged (same anonymous id); network on; `signInByEmail(mail, e)`; `Ready` with `e`.
- [ ] **Step 2: Run** — `bash tools/supabase/run_auth_it.sh test_supabase/auth/leave_test.dart`. Expected: PASS; a failure is a finding as in Task 3 Step 2.
- [ ] **Step 3: Commit** — `test(auth): D6, D7, D11, D12 on a real stack`.

### Task 5: Sessions and roles — D8, D10

**Files:**
- Test: `test_supabase/auth/session_role_test.dart`

**Interfaces:**
- Consumes: Tasks 1–4; `UserRoleRemoteDataSource` (`lib/features/account/data/datasources/user_role_remote_data_source.dart`) built on the device's `client.rpc`; `ReauthRequired`.

- [ ] **Step 1: Write the tests**
  - `test('D8 a revoked session asks to sign in again and loses nothing')`: A linked with `{'A1'}` and an unsynced `A2`; `probe.signOutEverywhere(A.client.auth.currentSession!.accessToken)`; force the refresh the app makes when the token runs out (`A.client.auth.refreshSession()`, its error ignored); `waitFor<ReauthRequired>()`; `A.deckNames()` still `{'A1','A2'}`; `signInByEmail(mail, e)`; `waitFor<Ready>()`, `syncNow()`; `probe.deckNames(id)` equals `{'A1','A2'}`.
  - `test('D10 an admin changes roles and cannot demote the last admin')`: A and B linked; `probe.makeAdmin(A.userId!)`; on A, `role_list` lists both emails; `role_set(B, 'admin')` then `role_set(B, 'user')` change B's role (read back through `role_list`); `role_set(A, 'user')` while A is the only admin fails with the code `LAST_ADMIN`.
- [ ] **Step 2: Run** — `bash tools/supabase/run_auth_it.sh test_supabase/auth/session_role_test.dart`. Expected: PASS; a failure is a finding as in Task 3 Step 2. If the forced refresh does not lead to `ReauthRequired`, report the state reached; it is the D8 finding, not a test to bend.
- [ ] **Step 3: Commit** — `test(auth): D8, D10 on a real stack`.

### Task 6: Gate rule and records

**Files:**
- Modify: `supabase/README.md` ("Run and test locally": the script and when it is required), `CLAUDE.md` (The gate: one bullet beside `supabase test db`), `docs/superpowers/specs/2026-09-30-auth-design.md` (§9.1: rows D1, D3–D8, D10–D12 point at `test_supabase/auth/`; D2 and D9 stay as they are), `docs/superpowers/specs/2026-10-05-auth-local-integration-tests-design.md` (§7 location amendment, status), `docs/wbs_supabase.md` (a row SB-T1 `xong` for this suite; the 2026-10-05 update entry).

- [ ] **Step 1: Write the records** as listed; the rule text: "A PR that changes `lib/core/auth/`, `lib/features/account/` or `supabase/migrations/` runs `bash tools/supabase/run_auth_it.sh` (Docker)."
- [ ] **Step 2: Run the whole suite and the gate** — `bash tools/supabase/run_auth_it.sh` then `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: all ITs PASS; `✓ mechanical gates passed`.
- [ ] **Step 3: Commit** — `docs(auth): the local IT suite is the gate for auth changes`.
