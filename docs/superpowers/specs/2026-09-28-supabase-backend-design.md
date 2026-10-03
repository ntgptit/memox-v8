# MemoX — Supabase backend for deck sync

Status: draft 2026-09-28 · Path: architectural · Decision record:
[ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md) · Parents:
[server-sync design](2026-09-27-server-sync-design.md),
[app deck-sync design](2026-09-27-app-deck-sync-design.md)

## 1. Intent

The app already syncs `deck` and `delete_batch` through an outbox, a
coordinator and a `SyncApi` (PR #114). This slice gives that sync a real,
free backend: a Supabase project. The Postgres functions in the Supabase project
take over what `memox-api-services` did in PR #110, with the same wire
format. The app gets an anonymous Supabase identity and a `SupabaseSyncApi`.

Success means:

- a build with `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` signs in
  anonymously and syncs decks and trash batches both ways, with no change to
  the coordinator, the outbox, the triggers or the adapters;
- a build without them behaves exactly as today, and every existing test
  still passes;
- a client holding the publishable key can reach user data only through the
  two sync functions, and only its own rows;
- `supabase test db` proves the protocol rules of the server-sync spec §4–5
  for `deck` and `delete_batch`.

Out of scope: card, tag, `review_log` and schedule sync (rollout step 4, on
Supabase, own spec); email login and linking (step 5); web client.

## 2. Decisions

| Topic | Decision | Why |
|---|---|---|
| Business rules | App only (ADR-015 #2). The server checks integrity: owner, deck-tree invariants, CHECKs, FKs, tombstones | Owner's ruling 2026-09-28; one implementation of BR and SRS |
| Server code | Plain SQL and PL/pgSQL in `supabase/migrations/`, one migration file for this slice | Versioned with the app, applied by `supabase db push` |
| API surface | Two RPCs, `sync_push(request jsonb) → jsonb` and `sync_changes(since bigint, max_rows int) → jsonb`, plus `ping() → text` | The client sends and receives the existing wire models as JSON |
| Table access | RLS on every table, no policies; `REVOKE ALL` on the tables from `anon`, `authenticated` and `public` | The only path to data is the functions, which filter on `auth.uid()` |
| Functions | `SECURITY DEFINER`, `SET search_path = ''` with every name schema-qualified; `EXECUTE` revoked from `public` and `anon`, granted to `authenticated` (and `ping` to `anon`) | Supabase's advice for definer functions; anonymous-auth users hold the `authenticated` role |
| Identity | `auth.uid()`; the app calls `signInAnonymously()` when it has no session | Login later links an email to the same user id, so no data moves |
| Retrofit | `SyncApi` stays the interface and Retrofit client; nothing constructs the Retrofit client while sync goes to Supabase. `ApiConfig` and the Dio provider stay | Owner's choice: keep Dio/Retrofit for a REST API later (ADR-012) |
| Spring Boot | `memox-api-services/` frozen, its CI job removed | ADR-015 #8 |

## 3. Schema (`supabase/migrations/<timestamp>_deck_sync.sql`)

Ported from Flyway V1–V3 of PR #110, with the V4 FK, in the `public` schema:

- `user_sync_version(user_id uuid PK, version bigint NOT NULL)`.
- `sync_applied_op(user_id, op_id, server_version, applied_at, PK (user_id, op_id))`.
- `delete_batch` as Flyway V3: `tombstoned_at` is the sync tombstone,
  `deleted_at` the batch's own time; unique `(user_id, server_version)`.
- `deck` as Flyway V1 with the V3 CHECKs (`deck_root_shape`,
  `deck_root_generation`, `deck_root_scheduler_version`,
  `deck_child_configs`), unique `(user_id, server_version)`, index on
  `parent_id`, and `delete_batch_id REFERENCES delete_batch (id)`.
- `user_id` has no default and no FK to `auth.users`: the functions always
  set it, and deleting an auth user is out of scope.
- Every table: `ENABLE ROW LEVEL SECURITY`, no policy, privileges revoked as
  in §2.

No `card` table: step 4 adds it.

## 4. Functions

Private helpers live in a schema `private` that is not exposed through the
Data API (not listed in `[api].schemas` of `supabase/config.toml`). Only
`public.sync_push`, `public.sync_changes` and `public.ping` are callable.

### 4.1 `sync_push(request jsonb) → jsonb`

Input is `PushRequestModel.toJson()`: `{"deviceId", "operations": [{"opId",
"entityType", "entityId", "op", "row"}]}`. Output is
`PushResponseModel`: `{"results": [{"opId", "status", "serverVersion",
"code", "current"}]}`.

- `auth.uid()` null → `RAISE` (the call fails, the client backs off).
- More than 100 operations, or `deviceId` not a UUID → `RAISE` with
  `VALIDATION_FAILED`; the whole batch is refused, as a 4xx was.
- Takes `pg_advisory_xact_lock(hashtextextended(uid::text, 0))` once, before
  the first operation. The whole call is one transaction, so one user's
  pushes are serialized and no subtree read can interleave with another
  device's write.
- Each operation, in order:
  1. `opId` already in `sync_applied_op` → `applied` with the stored
     version.
  2. Unknown `entityType` → `rejected`, `SYNC_ENTITY_UNSUPPORTED`,
     `current: null`.
  3. Otherwise run the entity's apply inside a `BEGIN … EXCEPTION` block (a
     subtransaction), so a failure rolls back only that operation. On
     success insert into `sync_applied_op` and answer `applied`.
  4. On a raised business code (`SQLSTATE` `P0001`, the code in the
     message) answer `rejected` with that code. On
     `check_violation`, `not_null_violation`, `foreign_key_violation`,
     `invalid_text_representation` or `invalid_datetime_format` answer
     `VALIDATION_FAILED`; on `unique_violation` answer `CONFLICT`. Any other
     error propagates and fails the call. `current` is the entity's
     server copy for this user (`null` if the server has never seen it),
     read after the rollback.
- An `upsert` without `row`, or a `row.id` different from `entityId` →
  `VALIDATION_FAILED`.
- Versions: `private.allocate_versions(uid, n) → bigint` does
  `INSERT … ON CONFLICT DO UPDATE SET version = version + n RETURNING
  version` and returns the last version of the block.

**Deck upsert** (server-sync spec §5, PR #110 `DeckSyncHandler`):

- An existing row with another `user_id` → `SYNC_ENTITY_CONFLICT`.
- Row shape: a root (`parentId` null) has `contentType = 'deck'` and
  non-null `schedulerType`, `schedulerVersion` and `generation`; a child
  has all five scheduler/config/generation fields null. Otherwise
  `VALIDATION_FAILED`. `schedulerConfig` and `studyConfig`, when present,
  must cast to `jsonb`.
- A parent that is missing, another user's or tombstoned →
  `DECK_PARENT_MISSING`.
- `parentId` equal to the deck or inside its live subtree →
  `DECK_TREE_CYCLE`.
- `root_id` and `depth` are derived from the parent, never read from the
  row. `depth + height of the live subtree > 10` → `DECK_TREE_TOO_DEEP`.
- One version for the row; when `root_id` or `depth` changes on an existing
  deck, one more version per live descendant, and the descendants are
  rewritten (`root_id`, `depth` relative to the new placement, their own
  version) in the same operation.
- The upsert clears `deleted_at`: an upsert of a tombstoned id resurrects it
  (with no live subtree, so no descendants move).

**Deck delete:** an unknown id is `applied` with the user's current version
(0 if none); an already tombstoned id is `applied` with its version;
otherwise the live subtree is tombstoned, one version per row, and the
first version is returned.

**Delete-batch upsert:** owner check as for deck; `itemType` in
`card|deck`; whole-row upsert with one version; clears `tombstoned_at`.
**Delete:** as deck delete, but a single row and `tombstoned_at`.

### 4.2 `sync_changes(since bigint, max_rows int) → jsonb`

- `max_rows` is clamped to 1..500. Returns `ChangesResponseModel`:
  `{"changes": [...], "nextSince", "hasMore", "serverTime"}`.
- `serverTime` is the server's `now()` as UTC epoch milliseconds (SP2b 2.30,
  R10). The app stores it at each pull; the Trash purge clock is the earlier
  of the device clock and that time, and without one nothing is swept as
  expired (BR-TRASH-009).
- `UNION ALL` of the user's `deck` and `delete_batch` rows with
  `server_version > since`, ordered by `server_version`, `LIMIT max_rows + 1`
  to compute `hasMore`. `nextSince` is the last returned version, or
  `since` when the page is empty.
- A change is `{"entityType", "entityId", "serverVersion", "deleted",
  "row"}`; `row` is `null` for a tombstone.

### 4.3 Wire rows

`row` uses the camelCase keys the adapters read (`DeckSyncAdapter`,
`DeleteBatchSyncAdapter`). Times are UTC ISO-8601 with a `Z` and
microseconds (`to_char(t AT TIME ZONE 'UTC',
'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')`). The input side casts with
`::timestamptz`, which accepts what the app sends.

### 4.4 `ping() → text`

Returns `'ok'`; granted to `anon`. The keep-alive workflow calls it.

## 5. App

- **Dependency:** `supabase_flutter` (latest stable, verified at plan time).
- **`lib/core/network/supabase_config.dart`:** `SupabaseConfig(url,
  publishableKey)` from `String.fromEnvironment('SUPABASE_URL')` and
  `('SUPABASE_PUBLISHABLE_KEY')`; `isEnabled` when both are non-empty.
- **`main.dart`:** when enabled, `await Supabase.initialize(...)` before the
  provider container reads `syncSchedulerProvider`. `API_BASE_URL` no longer
  enables sync.
- **`lib/core/sync/supabase_sync_api.dart`:** `SupabaseSyncApi implements
  SyncApi`. It takes two injected functions, so tests need no Supabase
  client:
  - `Future<void> Function() ensureSession`: in the app, signs in
    anonymously when `auth.currentSession` is null;
  - `Future<Object?> Function(String fn, Map<String, Object?> params) rpc`:
    in the app, `client.rpc(fn, params: params)`.
  `push` calls `ensureSession`, then `rpc('sync_push', {'request':
  request.toJson()})`, and parses `PushResponseModel.fromJson`. `changes`
  does the same with `sync_changes`. Any exception propagates: the
  scheduler already backs off on every error.
- **`sync_providers.dart`:** the scheduler is built when
  `SupabaseConfig.isEnabled`; the `SyncApi` it gets is the
  `SupabaseSyncApi`.
- The session persists through `supabase_flutter`'s default storage. A lost
  session (reinstall, cleared data) signs in as a new anonymous user; the
  outbox then uploads the local library to that user. Recovering the old
  user belongs to the login spec.

## 6. Repo and operations

- `supabase/` from `npx supabase init`: `config.toml`, `migrations/`,
  `tests/`. `auth.enable_anonymous_sign_ins = true` in `config.toml`.
- CI (`ci.yml`): the `api` job is removed from the jobs and from `ci-gate`;
  a `supabase` job runs `supabase/setup-cli`, `supabase db start` and
  `supabase test db`, and joins `ci-gate`.
- `.github/workflows/supabase-keepalive.yml`: daily cron and
  `workflow_dispatch`; `curl` POSTs to `$SUPABASE_URL/rest/v1/rpc/ping`
  with the publishable key from repository secrets. It skips with a notice
  when the secrets are absent.
- `supabase/README.md`: local run, tests, and the owner's steps — create the
  project, enable Anonymous sign-ins (and CAPTCHA or rate limits as
  advised), `supabase link` and `supabase db push`, add the two secrets,
  build with the two `--dart-define`s.

## 7. Documents

- ADR-014 → `status: deprecated`, `superseded_by: ADR-015`.
- ADR-013: the ADR-014 note under the table is replaced by a note that
  ADR-015 restores rows #1, #2, #4, #5 and #8, with Supabase as the server.
- Specs superseded, each with a header note pointing to this spec: API
  authority / command sync, command protocol deck–card (and its plan); the
  server-sync spec's header note is rewritten.
- `wbs_API.md`: a header note that it is frozen with `memox-api-services`;
  sync items move to `wbs_BE.md`, which gains a row for this slice.
- `CLAUDE.md` "Backend API" section → "Backend: Supabase" (`supabase/`,
  `supabase test db`), with `memox-api-services` described as frozen.
- Skills that cite ADR-014 (`flutter-architecture`, `flutter-data-layer`
  and its `persistence.md`, `flutter-feature-slice`, `flutter-drift`
  references) cite ADR-015 and say the app owns BR and SRS.
- `docs/shared/data/schema.md` sync section: the server is Supabase.
- `docs/_generated/index.md` regenerated.

## 8. Testing

- **pgTAP (`supabase/tests/`),** as two simulated users via
  `set local role authenticated` and `request.jwt.claims`:
  - privileges: `anon` and `authenticated` cannot select from or insert
    into any table; `anon` cannot execute `sync_push`;
  - idempotency: the same `opId` twice → one row, the same version;
  - versions: strictly increasing per user; one per row on a subtree move
    and a subtree delete;
  - tree: cycle, depth 11, missing / tombstoned / foreign parent, derived
    `root_id` and `depth` whatever the client sent, subtree rewrite on move;
  - validation: bad root shape, non-JSON config, `row.id` ≠ `entityId`,
    an unknown entity type; a failed operation does not undo the one before
    it in the batch;
  - isolation: user B's upsert of user A's id is `SYNC_ENTITY_CONFLICT`
    with `current: null`, and B's `sync_changes` never shows A's rows;
  - tombstones in `sync_changes`, `hasMore`/`nextSince` paging across both
    entity types, and resurrection;
  - wire: a pushed deck read back through `sync_changes` has the same keys
    and time format the adapters parse.
- **Concurrency** relies on the per-user advisory lock taken for the whole
  call; pgTAP runs one session, so no automated two-connection test (the
  PR #110 Java race test is not ported).
- **Dart:** `SupabaseSyncApi` with fake `rpc`/`ensureSession`: request JSON
  shape and function names, response parsing, session ensured before every
  call, errors propagate. The existing two-device convergence test keeps
  running against its in-memory fake.
- **Gates:** `supabase test db` (CI, and locally with Docker); app
  `flutter test --exclude-tags golden` and `dod_check.sh`.
