# Real accounts: sign-in, account switch, sign-out and deletion (SB-A1)

Status: approved 2026-09-30; P1 (server) implemented by
`docs/superpowers/plans/2026-09-30-accounts-server.md`; P2 (core auth) implemented by
`docs/superpowers/plans/2026-09-30-accounts-core-auth.md`. Every section was
approved in the brainstorm of 2026-09-29/30, the UI brief in the Impeccable
`shape` of 2026-09-30. Covers SB-A1 (this spec), SB-A2, SB-A3, SB-A5
and the owner's setup SB-A4 of `docs/wbs_supabase.md`. Decisions extend
[ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md) and
[ADR-018](../../shared/decisions/ADR-018-log-tap-trung-va-monitoring.md) §7.
§7 and §8 are settled for P3 by
[the account UI addendum](2026-09-30-account-ui-design.md), which wins where
they differ.

## 1. Intent and owner rulings

Today every install signs in anonymously (`signInAnonymously`); a reinstall
or a second device starts a new anonymous user and the old data is out of
reach. This spec lets a person attach a real account to the **same** user, so
their data follows them, and adds sign-out, account deletion (required by
Google Play once an app creates accounts) and cleanup of abandoned anonymous
users.

| # | Ruling (owner, 2026-09-29/30) |
|---|---|
| O1 | Sign in with **email OTP** (6-digit code) and **Google** |
| O2 | Signing in is **optional**; the first launch shows a welcome that invites it ("Sign in" / "Continue without an account") |
| O3 | An account is attached to the current anonymous user (same `uid`): no data moves on the server |
| O4 | A second device whose anonymous data meets an existing account: **ask, default merge** (the other choice discards the device's data) |
| O5 | Merge mechanism: **claim token + `account_merge` RPC**, idempotent by `operation_id` with a receipt |
| O6 | Sign-out: push what is pending, **clear business data on the device**, return to a new anonymous user |
| O7 | Account deletion in the app; anonymous users inactive for **90 days** are deleted by a daily job |
| O8 | Roles live in data: **`public.profiles.role`** (`user` default, `admin`), read by the app through `me()`; no role in the JWT, no Auth Hook |
| O9 | Only an admin grants roles, from a **Users** screen under Settings › Admin |
| O10 | Schema rule: **our tables in `public`**, internal functions in `private`, `auth` belongs to Supabase |
| O11 | Google is **native** (`google_sign_in` → `idToken` + `accessToken` → `signInWithIdToken` / `linkIdentityWithIdToken`) |
| O12 | Drift stays one profile per device (`owner_id` stays `NULL`); no per-user namespacing |
| O13 | The A-session backup and the claim token are kept in **Secure Storage** (`flutter_secure_storage`) |
| O14 | Architecture reference adopted: Supabase owns identity and session, Riverpod holds app state, the router reacts to it, Postgres decides access; mapped onto ADR-010 layers |

## 2. Server

One new migration (after `20261009000000`), pgTAP in
`supabase/tests/database/12_account.sql`.

### 2.1 Rules

- `auth.*` is Supabase's; nothing of ours is created there.
- `public.*`: business tables and the public RPC entry points. Every table: RLS
  on, no policy, `revoke all … from anon, authenticated`.
- `private.*`: implementation (`is_admin`, `require_current_profile`,
  `delete_user_data`, `merge_user_data`, `touch_user_activity`), never
  exposed.
- `alter default privileges in schema public revoke execute on functions from
  public, anon, authenticated` drops Supabase's per-schema grant to `anon` and
  `authenticated`. It cannot drop the global EXECUTE-to-PUBLIC default, so
  every function still revokes from `public, anon, authenticated` and grants
  explicitly; a pgTAP allowlist (`04_function_privileges.sql`) fails on any
  public function a client can run that is not on the list.
- Every RPC: `security definer`, `set search_path = ''`, schema-qualified
  names, its own authorization check first.

### 2.2 Tables

- **`public.profiles`**: `id uuid primary key references auth.users(id) on
  delete cascade`, `role text not null default 'user' check (role in
  ('user','admin'))`, `role_changed_by uuid references auth.users(id) on
  delete set null`, `role_changed_at timestamptz`, `last_active_at
  timestamptz not null default now()`, `created_at`, `updated_at`.
  - Trigger `on_auth_user_created` (after insert on `auth.users`): `insert …
    on conflict (id) do nothing` — idempotent, no `exception when others`
    (a broken trigger must surface, not hide).
  - The migration backfills a profile for every existing user and copies
    `raw_app_meta_data.role = 'admin'` into `role`.
- **`public.account_claim`**: `token_hash`, `source_user_id` (FK cascade),
  `expires_at` (15 minutes); one live token per anonymous user.
- **`public.account_merge_receipt`**: `operation_id` (PK), `source_user_id`,
  `target_user_id` (no cascade on the source), `merged_at`,
  `acknowledged_at`, `expires_at` (7 days; no longer read since DEV-188: a
  receipt stays until acknowledged, so a device that merged and comes back
  months later still gets MERGED).
- **Foreign keys added**: `user_id → auth.users(id) on delete cascade` on
  every table with a `user_id` (`deck`, `card`, `tags`, `delete_batch`,
  `review_log`, `card_schedule`, `account_settings`, `user_sync_version`,
  `sync_applied_op`, `app_log`). Existing rows all have live users (none has
  been deleted), so the constraints validate. Effect: a deleted user's
  still-valid access JWT cannot recreate rows through `sync_push` (FK
  violation), without editing the sync functions.
- **`card_tags`** has no `user_id`: its two keys (`card_id → card`,
  `tag_id → tags`) become `on delete cascade`, or deleting a user would fail
  on the links. The other existing keys (`deck.parent_id`,
  `deck/card.delete_batch_id`, `card.deck_id`, `review_log.card_id`,
  `card_schedule.card_id`) stay `NO ACTION`: they point between rows of the
  same user, all removed by the same cascade in one statement, and NO ACTION
  is checked at the end of the statement.

### 2.3 Functions

| Function | Who | Does |
|---|---|---|
| `private.is_admin()` | internal | now reads `profiles.role` (immediate effect; Monitoring's RPCs keep calling it) |
| `private.require_current_profile()` | internal | raises `UNAUTHORIZED` when the caller has no profile (a deleted user with an old JWT) |
| `private.touch_user_activity()` | internal | sets `last_active_at = now()` when it is older than 1 day |
| `public.me()` | authenticated | touches activity; returns `{id, email, isAnonymous, role}` |
| `public.role_list(query, cursor)` | admin | searches non-anonymous users by email: id, email, role, created, last sign-in |
| `public.role_set(user, role)` | admin | `pg_advisory_xact_lock` then checks; refuses `NOT_FOUND`, `ANONYMOUS_USER` (no admin for anonymous), `LAST_ADMIN` (never demote the last admin) |
| `public.account_claim_begin()` | anonymous only (`NOT_ANONYMOUS` otherwise) | stores a token hash (15 min), returns the token |
| `public.account_merge(token, operation_id)` | non-anonymous | if a receipt for `operation_id` with `target = auth.uid()` exists → `MERGED`. Else consumes the token atomically (`delete … where token_hash = … and expires_at > now() returning`); none → `CLAIM_INVALID`. In one transaction: moves every source row to the caller with **new `server_version`s** from the caller's counter, merges tags with the same `name_folded` (re-pointing `card_tags`), keeps the caller's `account_settings`, writes the receipt, deletes the source user (its profile and role go with it) |
| `public.account_merge_ack(operation_id)` | non-anonymous | sets `acknowledged_at` on the caller's receipt; idempotent |
| `public.account_delete()` | authenticated | refuses the last admin (`LAST_ADMIN`); `private.delete_user_data(uid)` = delete from `auth.users` (cascades). Later, Storage objects would have to go first |
| cron `account-cleanup` (daily) | — | deletes users with `is_anonymous` and `last_active_at < now() - 90 days`; deletes acknowledged receipts (an unacknowledged one stays whatever its age, DEV-188) and expired claims; forgets `sync_applied_op` rows older than 90 days (DEV-200: every operation is idempotent by content, so a forgotten op id resent is applied again as the same upsert or delete) |

### 2.4 Owner setup (SB-A4)

Google provider on, "Allow manual linking" on, Google Cloud OAuth clients (Web
client first in Supabase's list; Android clients with the debug and release
SHA-1), custom SMTP, email templates that send `{{ .Token }}`. No hook.

## 3. App: auth state machine

### 3.1 Rules

- **R1 — the SDK says who is signed in.** Recovery and start always read
  `currentSession.user.id` (no network) first; the transition record holds
  intent (kind, op, source, choice), never session truth.
- **R2 — validate before sync.** A cached session only reaches `VALIDATING`;
  sync runs once `me()` succeeds.
- **R3 — mutation gate.** During Switch, SignOut, Delete and ClearToAnon
  every business write is refused and a blocking layer is shown; A's outbox
  is never pushed under B.

Offline is a condition, never a state: it never signs out and never clears
data.

### 3.2 States

| State | Meaning | Sync | Business writes |
|---|---|---|---|
| `BOOTING` | reading the record and the session | paused | allowed |
| `RECOVERING(t)` | a pending transition is reconciled (R1) | paused | blocked (except AnonRecovery) |
| `LOCAL_ONLY` | no session, offline | paused (outbox fills) | allowed |
| `BOOTSTRAPPING` | reconcile, then create an anonymous user only if none exists | paused | allowed |
| `VALIDATING(last)` | session present, `me()` not yet OK; stays here offline | **paused** | allowed |
| `READY(snapshot)` | validated | on when online | allowed |
| `REAUTH_REQUIRED(last)` | permanent account whose session was refused; local kept | paused | allowed (X's outbox) |
| `TRANSITIONING(t)` | Switch, SignOut, Delete, ClearToAnon, AnonRecovery | paused | blocked (except AnonRecovery) |

Error classes (data layer only): `NETWORK`, `SESSION_INVALID`
(`refresh_token_not_found`, `session_not_found`, `user_not_found`),
`PROFILE_GONE` (`me()` → `UNAUTHORIZED` with a live JWT), `IDENTITY_TAKEN`
(`email_exists`, `identity_already_exists`), `CLAIM_INVALID`, `MERGED`.

### 3.3 Transitions

| # | State | Event / guard | Action | Next |
|---|---|---|---|---|
| 1 | BOOTING | record exists | — | RECOVERING(t) |
| 2 | BOOTING | no record, SDK has a session | snapshot = `lastKnownAccount` | VALIDATING |
| 3 | BOOTING | no record, no session | — | BOOTSTRAPPING (online) / LOCAL_ONLY |
| 4 | LOCAL_ONLY | online | — | BOOTSTRAPPING |
| 5 | BOOTSTRAPPING | SDK already has a session | no second anonymous user | VALIDATING |
| 6 | BOOTSTRAPPING | no session | `signInAnonymously()` | VALIDATING |
| 7 | BOOTSTRAPPING | NETWORK | — | LOCAL_ONLY |
| 8 | VALIDATING | offline / NETWORK | wait, retry online | VALIDATING |
| 9 | VALIDATING | `me()` OK | save `lastKnownAccount`; start sync | READY |
| 10 | VALIDATING / READY | anonymous + SESSION_INVALID or PROFILE_GONE | record AnonRecovery{started}; `signOut(local)` | TRANSITIONING(AnonRecovery) |
| 11 | AnonRecovery | R1: no session → `signInAnonymously()`; session → reuse | stage = newAnon(uid) | — |
| 12 | AnonRecovery | newAnon | `markAllPending` + cursor 0 (idempotent); clear record | VALIDATING |
| 13 | VALIDATING / READY | account + PROFILE_GONE | record ClearToAnon | TRANSITIONING |
| 14 | VALIDATING / READY | account + SESSION_INVALID | keep local, pause sync | REAUTH_REQUIRED(X) |
| 15 | READY | NETWORK | keep | READY |
| 16 | READY(anon) | email or Google link OK (same uid) | `me()` | READY(account) |
| 17 | READY(anon) | IDENTITY_TAKEN | local has data → ask Merge (default) / Discard; empty → skip | (choice) |
| 18 | READY(anon A) | chosen | record Switch{op, choice, source A}; **gate closed** | TRANSITIONING(Switch) |
| 19 | Switch | started, online | push outbox under A until empty, then ship the logs under A (DEV-190); stage = sourcePushed. Rows the server refused (`sync_rejection`, no copy of its own) stop a merge here with `UnsentChangesFailure`: Retry repeats it, the layer's "Continue and lose n changes" keeps them on the device first; a discard goes on, those rows go with the device at #27 (DEV-191) | — |
| 20 | Switch | sourcePushed, merge | A's refresh token and the claim token → Secure Storage; stage = claimed | — |
| 21 | Switch | sign-in to B OK | R1 reads B; stage = targetSignedIn(B) | — |
| 22 | Switch | cancelled before the target sign-in | drop secrets and record; open gate | READY(A) |
| 23 | Switch | targetSignedIn, merge | `account_merge(token, op)` | — |
| 24 | Switch | MERGED | stage = merged; **drop A's backup** | — |
| 25 | Switch | CLAIM_INVALID without receipt | `setSession(A backup)`; drop secrets and record; open gate; "Couldn't merge" | VALIDATING(A) |
| 26 | Switch | NETWORK during merge | keep stage; same op on reconnect | RECOVERING |
| 27 | Switch | merged, or targetSignedIn + discard | `LocalDataReset` (outbox empty by the gate); cursor 0; stage = localCleared | — |
| 28 | Switch | localCleared, online | full pull; stage = targetPulled | — |
| 29 | Switch | targetPulled, merge | `account_merge_ack(op)`; stage = acknowledged | — |
| 30 | Switch | acknowledged, or targetPulled + discard | drop the op's secrets and the record; open gate; `me()` | READY(B) |
| 31 | RECOVERING(Switch) | R1: SDK uid = A | stage ≤ claimed → drop secrets and record, open gate; stage ≥ merged cannot happen → error, gate stays shut | VALIDATING |
| 32 | RECOVERING(Switch) | R1: SDK uid = U ≠ A (even if killed before saving targetSignedIn) | target = U; stage = max(stage, targetSignedIn); continue #23 or #27 with the same op | TRANSITIONING |
| 33 | RECOVERING(Switch) | R1: no session | stage < merged + A backup → `setSession(A)` → #31; stage ≥ merged → ask to sign in to the target again, gate shut | RECOVERING |
| 34 | READY(account X) | "Switch account" | record Switch{source X, permanent, discard}; gate; push under X and ship the logs (#19); rows the server refused do not stop it (discard, DEV-191) | TRANSITIONING(Switch) |
| 35 | Switch (permanent source) | sign-in to Y OK (R1) | #27 → #28 → #30; **no anonymous in between** | READY(Y) |
| 36 | REAUTH_REQUIRED(X) | sign-in, SDK uid = X | `me()` | VALIDATING → READY(X) |
| 37 | REAUTH_REQUIRED(X) | sign-in, uid Y ≠ X; user confirmed losing N unsent changes | record Switch{source X, discard, targetSignedIn(Y)} → #27 | READY(Y) |
| 38 | REAUTH_REQUIRED(X) | "Continue without an account"; confirmed | record ClearToAnon | TRANSITIONING |
| 39 | READY | sign out (outbox empty, or loss accepted offline) | record SignOut; gate; push; ship logs | — |
| 39a | SignOut, stage started (nothing local removed) | "Cancel" (critique 2026-10-02) | drop record; open gate; `me()` (#8/#9) | VALIDATING → READY(X) |
| 40 | SignOut / ClearToAnon | pushed | `signOut(local)`; stage = signedOut | — |
| 41 | SignOut / ClearToAnon | signedOut (R1: no session) | `LocalDataReset`; clear `lastKnownAccount` and record; open gate | BOOTSTRAPPING |
| 42 | READY(account) | delete (online) | record Delete; gate; `account_delete()` | — |
| 43 | Delete | OK, or PROFILE_GONE on a retry (the record proves the request) | stage = serverDeleted → #40 → #41 | BOOTSTRAPPING |
| 44 | Delete | LAST_ADMIN, or NETWORK before the server took it | clear record; open gate | READY |
| 45 | RECOVERING(SignOut / Delete / ClearToAnon / AnonRecovery) | launch | reconcile by R1, continue the stage (every step idempotent) | as above |

### 3.4 Invariants

| Invariant | Held by |
|---|---|
| An uncommitted merge never clears A's local data | `LocalDataReset` only at #27 after MERGED; #25, #31 return to A intact; #26, #33 keep everything |
| A committed merge never returns to A | A's backup dropped at #24; `setSession(A)` only at #25 (no receipt) and #33 (stage < merged); a kill after commit re-merges at #32 and gets MERGED from the receipt |
| Offline never signs out | #7, #8, #15, #26 |
| A refused permanent session never clears local at once | #14 → REAUTH_REQUIRED; cleared only on confirmation (#37, #38) or PROFILE_GONE (#13) |
| A cleaned-up anonymous user keeps local data, gets a new anonymous user, pushes everything | #10 → #11 → #12 |
| A successful sign-out clears business data | #40 → #41 with a record |
| A pending transition is recovered before any bootstrap | #1 precedes #2/#3 |
| No cross-account data | R3 gate and paused sync in every transition; sync only in READY (R2); no push after the SDK uid differs from the source |
| No second anonymous user | #5, #11 |

## 4. Persisted state

| Data | Where | Content | Lives until |
|---|---|---|---|
| SDK session | SharedPreferences (managed by `supabase_flutter`) | unchanged | the SDK clears it |
| `account_state` | Drift, new table, one row | `user_id`, `email`, `is_anonymous`, `role`, `validated_at` (= `lastKnownAccount`) | overwritten on each `me()`; cleared at #41 |
| `account_transition` | Drift, new table, 0–1 row | `op_id`, `kind`, `choice`, `source_user_id`, `source_is_anonymous`, `target_user_id`, `target_hint`, `stage`, `created_at`, `updated_at` | end of the flow |
| `sync_state` | Drift, existing | cursors, `last_success_at`, `last_failure_*`; no new key (`fullPush` is the AnonRecovery record) | cleared by `LocalDataReset` |
| A's refresh-token backup | Secure Storage `account.backup.<op>` | refresh token | #22, #24, #25, #31 |
| Claim token | Secure Storage `account.claim.<op>` | one-time token | #22, #25, #30, #31 |
| Auth state, validated snapshot | memory | — | app lifetime |
| Google tokens, typed OTP | memory, during the call only | — | never written |
| `welcome_seen` | Drift, `app_settings` local-only column | — | never cleared by `LocalDataReset` |

`LocalDataReset` clears deck, card, tags, card_tags, review_log,
card_schedule, delete_batch, trash, the outbox, cursors and `sync_state` keys,
`sync_rejection`, and resets the account-synced settings (`card_limit`,
`new_card_order`, `theme_mode`, `language`); it keeps `account_transition`,
`welcome_seen`, the device-only reminder columns and `LogDatabase` (logs are
shipped before sign-out). At start, Secure Storage keys `account.*` whose op
is not the current record's are deleted. Drift: schema bump, two tables, one
column, migration test.

## 5. Boundary

One owner for the whole machine: **`AccountCoordinator` in `lib/core/auth/`**
(the start-up, sync and every screen depend on it), like `SyncCoordinator`.
Features send it commands; there is no use case per flow.

- App types (no `User`, `Session`, `AuthResponse` beyond the gateway files):
  `AccountUser {id, email?, isAnonymous, role}`, sealed `AuthState`, sealed
  `AuthFailure` (extends ADR-016 `Failure`: `Network`, `SessionInvalid`,
  `ProfileGone`, `IdentityTaken(email|google)`, `InvalidCode`, `CodeExpired`,
  `RateLimited`, `ClaimInvalid`, `LastAdmin`, `AnonymousUser`, `Forbidden`,
  `GoogleCancelled`, `MutationBlocked`).
- `AuthGateway` (Supabase GoTrue + `google_sign_in`): `currentUserId`,
  `events`, `signInAnonymously`, `requestEmailLink`/`verifyEmailLink`
  (`updateUser` + `emailChange` OTP), `requestEmailSignIn`/`verifyEmailSignIn`,
  `pickGoogle` → `GoogleCredential`, `linkGoogle`, `signInGoogle`,
  `refreshToken`, `restoreSession`, `signOutLocal`.
- `AccountApi` (RPC): `me`, `claimBegin`, `merge(token, opId)`, `mergeAck`,
  `deleteAccount`.
- `AccountStore` (Drift) and `SecretStore` (Secure Storage), as in §4.
- `SyncControl` (`core/sync`): `pause`, `resume`, `pendingCount`,
  `pushPending`, `pullAll`, `markAllPending`.
- `LocalDataReset` and `MutationGate` (`core/database`); the gate sits in the
  shared write helper of sub-project A, so every feature's write is covered;
  sync pull and the reset use their own path.
- Providers (`core/auth/di`, keepAlive): the four infrastructure providers,
  `accountCoordinatorProvider`, `authStateProvider` (the single source of
  truth), `currentAccountProvider`, `isAdminProvider` (`Ready` and admin;
  replaces `features/monitoring/di/{auth_session,is_admin}_provider.dart`);
  `syncSchedulerProvider` runs only in `Ready`.
- `features/account` (ADR-010 layers): controllers `EmailSignInController`,
  `GoogleSignInController`, `MergeChoiceController`,
  `AccountActionsController`, `ReauthController` send commands and hold only
  their screen's submit/error state; none navigates after sign-in. The Users
  screen has `domain/UserRoleRepository` (`list`, `set`),
  `data/UserRoleRemoteDataSource` (`role_list`, `role_set`) and
  `UsersController`.
- Architecture guard: only `lib/core/auth/supabase_*.dart`,
  `lib/core/auth/google_*.dart`, `lib/core/sync/supabase_sync_api.dart` and
  `lib/core/network/` import `supabase_flutter` or `google_sign_in`.
- New packages: `google_sign_in`, `flutter_secure_storage` (owner-approved).

## 6. Algorithms

Reference pseudo-code, approved with the state table (`#n` = row of §3.3).

```dart
Future<void> start() async {
  emit(Booting()); sync.pause();
  final t = await store.transition();
  await secrets.purgeExcept(t?.opId);
  if (t != null) return _recover(t);                        // #1
  return _settle();
}

Future<void> _settle() async {                              // R1
  if (gateway.currentUserId != null) return _validate();    // #2, #5
  if (!await net.isOnline) return emit(LocalOnly());        // #3
  emit(Bootstrapping());
  try {
    if (gateway.currentUserId == null) await gateway.signInAnonymously(); // #6
    return _validate();
  } on Network { return emit(LocalOnly()); }                // #7
}

Future<void> _validate() async {
  emit(Validating(await store.lastKnown()));                // R2
  try {
    final me = await api.me();
    await store.saveLastKnown(me); emit(Ready(me)); sync.resume(); // #9
  } on Network { /* #8: retried on reconnect */ }
    on SessionInvalid { return _lost(sessionInvalid: true); }
    on ProfileGone { return _lost(sessionInvalid: false); }
}

Future<void> _lost({required bool sessionInvalid}) async {
  final last = await store.lastKnown(); sync.pause();
  if (last == null || last.isAnonymous) return _anonRecovery();   // #10
  if (sessionInvalid) return emit(ReauthRequired(last));          // #14
  return _run(AccountTransition.clearToAnon(opId: uuid()));       // #13
}

Future<void> _recoverSwitch(AccountTransition t) async {
  gate.close(); sync.pause(); emit(Recovering(t));
  final uid = gateway.currentUserId;                              // R1
  if (uid == t.sourceUserId) {                                    // #31
    if (t.stage <= Stage.claimed) { await _drop(t); gate.open(); return _validate(); }
    return emit(Recovering(t, error: const Unexpected()));
  }
  if (uid == null) {                                              // #33
    final backup = await secrets.get('account.backup.${t.opId}');
    if (t.stage < Stage.merged && backup != null) {
      await gateway.restoreSession(backup); return _recoverSwitch(t);
    }
    return emit(Recovering(t, needsTargetSignIn: true));
  }
  var s = await _save(t.copyWith(targetUserId: uid,
      stage: max(t.stage, Stage.targetSignedIn)));                // #32
  if (s.choice == Choice.merge && s.stage == Stage.targetSignedIn) {
    final token = await secrets.get('account.claim.${s.opId}');
    try {
      await api.merge(token ?? '', s.opId);                       // #23
      await secrets.delete('account.backup.${s.opId}');           // #24
      s = await _save(s.copyWith(stage: Stage.merged));
    } on ClaimInvalid {                                           // #25
      await gateway.restoreSession((await secrets.get('account.backup.${s.opId}'))!);
      await _drop(s); gate.open(); return _validate(notice: Notice.mergeNotDone);
    } on Network { return; }                                      // #26
  }
  if (s.stage < Stage.localCleared) { await localReset.run(); s = await _save(s.copyWith(stage: Stage.localCleared)); } // #27
  if (s.stage < Stage.targetPulled) {
    try { await sync.pullAll(); } on Network { return; }
    s = await _save(s.copyWith(stage: Stage.targetPulled));       // #28
  }
  if (s.choice == Choice.merge && s.stage == Stage.targetPulled) {
    try { await api.mergeAck(s.opId); } on Network { return; }
    s = await _save(s.copyWith(stage: Stage.acknowledged));       // #29
  }
  await _drop(s); gate.open(); return _validate();                // #30
}

Future<void> _recoverAnon(AccountTransition t) async {            // #10–#12
  var s = t;
  if (s.stage == Stage.started) {
    if (gateway.currentUserId == null) {
      try { await gateway.signInAnonymously(); } on Network { return emit(LocalOnly()); }
    }
    s = await _save(s.copyWith(stage: Stage.newAnon, targetUserId: gateway.currentUserId));
  }
  await sync.markAllPending(); await store.clearTransition(); return _validate();
}

Future<void> reauthSignedIn() async {                             // #36–#37
  final last = (await store.lastKnown())!;
  final uid = gateway.currentUserId;
  if (uid == last.id) return _validate();
  final t = AccountTransition.switch_(opId: uuid(), choice: Choice.discard,
      sourceUserId: last.id, sourceIsAnonymous: false,
      targetUserId: uid, stage: Stage.targetSignedIn);
  await store.saveTransition(t); return _recoverSwitch(t);
}

Future<void> _recoverSignOut(AccountTransition t) async {         // #39–#45
  gate.close(); sync.pause(); emit(Recovering(t));
  var s = t;
  if (s.kind == Kind.delete && s.stage == Stage.started) {
    try { await api.deleteAccount(); }
    on ProfileGone { /* retry after the server already deleted */ }
    on LastAdmin catch (f) { await store.clearTransition(); gate.open(); return _validate(error: f); }
    on Network { await store.clearTransition(); gate.open(); return _validate(); }
    s = await _save(s.copyWith(stage: Stage.serverDeleted));
  }
  if (gateway.currentUserId != null) await gateway.signOutLocal();
  s = await _save(s.copyWith(stage: Stage.signedOut));
  await localReset.run(); await store.clearLastKnown(); await store.clearTransition();
  gate.open(); return _settle();
}
```

`beginSwitch` records Switch{started}, closes the gate, pushes under A and
ships A's logs (#19; `app_log.user_id` is the shipping session's, so they
go before the SDK moves to B, as a sign-out ships them at #39) and, for a
merge, stores the backup and the claim token (#20); the
target sign-in then calls `_recover`, which R1 routes. Every
`on Network { return; }` keeps the record; the connectivity listener calls
`_recover` again. Each stage is saved before the next step, so a rerun is a
no-op up to where it stopped.

## 7. Router

Signing in is optional: no guard forces `/login`. `GoRouter` refreshes on
`authStateProvider` for these rules only:

- **Welcome:** `welcome_seen == false` redirects to
  `/welcome?from=<target>`; "Continue without an account" or a finished
  sign-in sets the flag and goes to `from ?? '/'`. The flag is loaded in
  `bootstrap` before the first frame, so nothing flashes.
- **Transition in progress** (`Transitioning`/`Recovering` of Switch,
  SignOut, Delete, ClearToAnon): a blocking layer at the app root (not a
  route) with progress, a network error with Retry, and the sign-in when
  `needsTargetSignIn`.
- **`REAUTH_REQUIRED`:** no redirect; a banner on Settings and Study home
  (like SB-U1's) opens `/account/sign-in?mode=reauth`.
- **Admin routes** (`/settings/monitoring…`, `/settings/users`): the existing
  gate widget reads the core `isAdminProvider`; `Validating` shows loading.
- **Account routes:** `/settings/account`, `/account/sign-in?mode=link|switch|reauth`,
  `/account/code`; `mode=link` while `Ready(account)` redirects to
  `/settings/account`.

## 8. UI (Impeccable shape, 2026-09-30)

**Job and mode.** Operate: the person finishes one account task and returns
to studying. The kit has none of these screens; they are built only from the
kit's widgets (no new shared widget), each deviation recorded in its screen
file and the UI-base register (§9). Copy is local-first: say what is kept
before what is asked.

| # | Screen | Widgets | Design |
|---|---|---|---|
| 29 | Welcome (first launch) | `MxScreenScroll`, launcher icon, `MxIconTile` rows, `MxButton` × 2, text `MxButton` | Icon and "MemoX"; three benefit rows with a glyph each (owner: a benefit list): keep your decks when you reinstall · study on several phones · still works offline. "Continue with Google" (primary), "Continue with email" (outline), "Continue without an account" (text). No back; Back leaves the app as on any root |
| 30 | Sign-in (`mode = link \| switch \| reauth`) | `MxAppBar` + back, `MxButton`, divider "or", `MxTextField` (email), `MxButton` | One screen (owner). A line per mode: link "Your decks stay on this phone and join the account."; switch "Signing in to another account replaces this phone's data after it is sent."; reauth "Sign in again to keep syncing. Your decks are still here." Google on top, then email + "Send code". Field errors under the field (`MxFieldMessage`) |
| 31 | Code | `MxAppBar` + back, `MxTextField` (numeric, 6, one field), text `MxButton` | "Enter the 6-digit code sent to {email}". Six digits submit at once; "Resend code" after 60 s (countdown in the label); "Use another email" returns to 30. States: sending, wrong code, expired, too many requests (with the wait), offline |
| — | Merge choice | `MxBottomSheet`, `MxNote`, `MxSheetActions` | Shown on IDENTITY_TAKEN when this phone has data: "{email} already has an account". "Merge into the account" (primary, default) with "Your {n} decks and {m} cards join it."; "Discard this phone's data" (destructive outline) with the warning note; Cancel. Local empty → no sheet |
| — | Transition layer | full-screen, `MxSpinner`, `MxNote`, `MxButton` | Over the whole app while Switch / SignOut / Delete / ClearToAnon run: the current step ("Sending your changes…", "Merging…", "Downloading your decks…", "Signing out…"), "Nothing is lost if you close the app." Network error → "No connection. Your data is safe on this phone." + Retry. `needsTargetSignIn` → the sign-in of 30 inline. Back does nothing |
| 23 | Settings › Account (first section) | `MxSection` + `MxSettingsRow` | Anonymous: "Sign in" / "Keep your decks if you reinstall or change phones" → 30 (link). Account: the email and "Google" or "Email" → 32 |
| 32 | Account | `MxAppBar`, `MxSection` + `MxSettingsRow`, `MxDialog` | Email, sign-in method, "Switch account" → 30 (switch). "Sign out" → dialog: "Your changes are sent first, then this phone's data is removed. Sign in again to get it back." (offline: "{n} changes aren't sent yet and will be lost."). "Delete account" (destructive) → dialog naming what is deleted, online only; LAST_ADMIN explains an admin must remain |
| — | Re-auth banner | `MxInlineBanner` on 23 and 13 | "Your sign-in expired. Your decks are still on this phone." · "Sign in" → 30 (reauth). Same slot and rules as the SB-U1 sync banner |
| 33 | Users (admin) | `MxAppBar`, `MxSearchField`, `MxListRow` + `MxBadge`, `MxBottomSheet` with `MxOptionRow` × 2 | Settings › Admin gets a "Users" row under Monitoring. Search by email (400 ms), rows show email, joined date and a role badge (Admin tinted, User neutral). Tap → sheet "User · Admin" with Save; `LAST_ADMIN` and `ANONYMOUS_USER` as toasts; paging like 28 |

States every screen carries: loading, offline, error (local-first copy), text
scale 2.0 in en and vi, dark theme, TalkBack labels (the code field reads
"Code, 6 digits"; the transition layer is a live region).

## 9. Testing

| Layer | Where | What |
|---|---|---|
| Server | `supabase/tests/database/12_account.sql` | profile trigger (permanent, anonymous, duplicate, default role), backfill; `me()`; role FORBIDDEN / ANONYMOUS_USER / LAST_ADMIN / concurrent demotion; claim success, expired, replay, concurrent replay, duplicate tag names, `server_version` increase, role not transferred; `account_merge` retry with the same op → MERGED, another user's op reveals nothing; `account_merge_ack` idempotent; delete own data only, LAST_ADMIN; "deleted user cannot recreate persisted data through sync_push"; cleanup removes old anonymous, keeps permanent and active anonymous; receipts purged |
| Coordinator | `test/core/auth/account_coordinator_test.dart` | at least one test per row #1–#45, on fakes |
| Crash injection | `…/account_coordinator_crash_test.dart` | a `Kill` at the k-th await of Switch, SignOut, Delete, AnonRecovery; a new coordinator on the same stores, secrets and fake SDK; after each k the eight invariants of §3.4 hold. Named cases: killed between the target sign-in and saving `targetSignedIn`; killed after the merge commit and before saving `merged` |
| Network | same | `Network` at every step keeps state and resumes; offline never signs out or clears |
| Drift | `test/drift/` | migration; `LocalDataReset` scope; `MutationGate` blocks business writes, lets pull and reset write |
| Data | `test/core/auth/` | error classification (auth codes, RPC codes); gateway and API over an HTTP `MockClient` |
| Architecture | `test/architecture`, `check_architecture.py` | import rule of §5; no Supabase types in `features/` |
| Router and widgets | `test/app/`, `test/features/account/` | welcome once, deep link kept; blocking layer; re-auth banner; admin gate in `Validating`/`Ready`; sign-in and code states; text scale 2.0 in en and vi |
| Goldens | after the shape | every new screen, light and dark, with a golden-compare page |
| Device | recorded in this spec | after SB-A4: real Google, real OTP mail, merge across two emulators, killed mid-merge, delete, offline then online |

### 9.1 Device check (after SB-A4)

Two Android devices or emulators, A and B, on a build with the three defines
and signed by a key registered in SB-A4 (`supabase/README.md`, "Sign-in
setup"). Each starts fresh (clear the app's data) with a deck or two of its
own. The dashboard's **Authentication → Users** and **Table Editor →
`profiles`** show the server side. Record each row's date, result and any
note; a failure becomes a WBS row before it is fixed. This check closes P3
and P4.

**Since 2026-10-05** the rows that need only email run as tests on a local
stack: `test_supabase/auth/` through `bash tools/supabase/run_auth_it.sh`
([spec](2026-10-05-auth-local-integration-tests-design.md)). D2 (real Google)
stays a device check, and D9 (Back) belongs to the widget tests.

| # | Steps | Expected | Result |
|---|---|---|---|
| D1 | A: Welcome → Sign in → an email with no account → the code from the mail | The mail arrives through the custom SMTP within a minute and shows the code; A is signed in; Authentication → Users shows the **same user id** as before, now with the email; A's decks stay | 2026-10-05: emulator ✓; IT `link_test` ✓ |
| D2 | A: Settings → Account → Switch account → Google → a Google account with no MemoX account | The account picker opens; A is signed in as that Google account; no nonce or client ID error | 2026-10-05: emulator ✓ (`ntgptit@gmail.com`) |
| D3 | B (anonymous, own decks): Sign in with A's email → the code | The merge sheet opens; "Merge into the account" keeps B's decks and adds the account's; after a sync A shows B's decks too; B's anonymous user is gone from Users | 2026-10-05: IT `switch_test` ✓ |
| D4 | Repeat D3 on B with "Discard this phone's data" (clear B first) | B's own decks are removed; B shows only the account's decks | 2026-10-05: IT `switch_test` ✓ |
| D5 | Repeat D3, and force-stop B while the transition layer shows | On reopen the layer resumes and ends in the same state as D3; no duplicated decks | 2026-10-05: IT `switch_test` ✓ (coordinator dropped after the merge commit) |
| D6 | B, online: Account → Sign out | The changes are sent first; B returns to a new anonymous user with no decks; signing in again brings them back | 2026-10-05: emulator ✓ for data, F1 and F2 found (SB-A7, fixed); IT `leave_test` ✓ |
| D7 | B, flight mode, edit a card, then Sign out | The dialog names the unsent changes that will be lost; cancelling keeps everything | 2026-10-05: IT `leave_test` ✓ (stops before removing anything; Cancel restores) |
| D8 | A signed in: in the SQL Editor, `delete from auth.sessions where user_id = '<A's id>';`, then reopen A after its access token expires (at most an hour) | Settings shows the re-auth banner and Study home the notice; "Sign in" with the same email returns to where it started; nothing is lost | 2026-10-05: IT `session_role_test` ✓ (sessions revoked by the service role) |
| D9 | Android Back on 30, 31, 32, the merge sheet and the transition layer | Back leaves 30–32; on the sheet it cancels, merging and discarding nothing; the layer ignores Back while it runs | widget tests in `test/app/`, `test/features/account/` |
| D10 | An admin on A: Settings → Admin → Users; make B's account an admin, then a user; try to demote yourself as the only admin from B | The list shows both accounts; the badge changes and B's Settings shows or hides Admin after a restart; the last admin is refused with the in-sheet banner | 2026-10-05: IT `session_role_test` ✓ |
| D11 | A second account, online: Account → Delete account | The account and its rows are gone from the dashboard; the device returns to a fresh anonymous user. Offline, the confirm is disabled and says why | 2026-10-05: emulator ✓ (on `+a`, unplanned); IT `leave_test` ✓ |
| D12 | A, flight mode: Welcome → Sign in → Send code; then back online | Offline says so and nothing changes; online, sign-in and sync resume | 2026-10-05: IT `leave_test` ✓ |

## 10. Risks

- **Supabase's built-in mailer** sends only a few emails an hour; OTP needs
  the custom SMTP of SB-A4 before real users.
- **The FK migration** fails if any owned row points at a missing user; none
  has been deleted so far, and the migration checks first. pgTAP deletes a
  user owning decks, cards, tags with links, reviews and schedules, and
  expects every row gone and no error.
- **A 1-hour access JWT survives deletion**; the FKs stop it from writing
  data, and `require_current_profile` stops the new RPCs.
- **Rollback:** the client work is behind the account UI; the server
  migration only adds tables, functions and constraints; reverting the app
  leaves anonymous sign-in working as today.

## 11. Phasing

Four plans, each its own PR, in this order; each leaves the app working as
today for anonymous users.

| Phase | Scope | Depends on | WBS |
|---|---|---|---|
| P1 Server | The migration of §2 (profiles and trigger, backfill, FKs, default privileges, `is_admin` on profiles, `me`, roles, claim, merge + receipt + ack, delete, cleanup cron) and `12_account.sql`. The app keeps working: nothing calls the new RPCs yet, Monitoring's admin check moves to `profiles` with the backfilled role | — | SB-A5 (server), part of SB-A2/SB-A3 |
| P2 Core auth | `lib/core/auth` (types, gateway, API, stores, secret store, `AccountCoordinator` with all 45 rows), `SyncControl`, `LocalDataReset`, `MutationGate`, the Drift tables, providers; `start()` in `bootstrap`; sync gated on `Ready`; `isAdmin` from `me()`; the two packages. Anonymous start, validation and AnonRecovery are live; Switch, SignOut, Delete are proven by the coordinator and crash-injection tests only | P1 deployed | SB-A2, SB-A3 (logic) |
| P3 Account UI | Screens 29–32, the merge sheet, the transition layer, the re-auth banner, Settings › Account; router rules of §7; goldens and the golden-compare page; handoff files | P2 | SB-A2 (UI, the former SB-U2), SB-A5 (in-app deletion); new FE rows in `wbs_FE.md` |
| P4 Users | Screen 33 and the role RPC client | P1, P2 | new FE row (admin) |

The owner's SB-A4 setup (Google Cloud, providers, manual linking, SMTP,
templates) must be done before the device check that closes P3; the check's
results are recorded in this spec like the reminders' device check.
