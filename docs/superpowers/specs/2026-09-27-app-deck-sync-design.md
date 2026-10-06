# MemoX — app deck sync (rollout step 3)

Status: approved 2026-09-27 · Path: architectural · Parent:
[server-sync design](2026-09-27-server-sync-design.md),
[ADR-013](../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md),
[ADR-012](../../shared/decisions/ADR-012-goi-api-bang-retrofit.md)

> Since 2026-09-28 the server is Supabase and sync is enabled by `SUPABASE_URL` and
> `SUPABASE_PUBLISHABLE_KEY` ([Supabase backend design](2026-09-28-supabase-backend-design.md) §5).

## 1. Intent

The server side of deck sync is live (PR #110). This slice makes the Flutter
app use it. Decks, and the trash batches that decks reference, flow between
Drift and the server with no change to use cases, presentation or
`DeckRepositoryImpl`.

Success means:

- every write to `deck` or `delete_batches` reaches the server once the app is
  online, whichever code path made it: repository, recursive CTE, cascade,
  trash purge or another feature;
- changes made on another device appear in this device's Drift, and so in
  its UI through `watch()`;
- with no `API_BASE_URL`, the app behaves exactly as today and every existing
  test still passes;
- nothing written locally is ever lost to a race between an edit and a push
  acknowledgement.

## 2. Decisions

| Topic | Decision | Why |
|---|---|---|
| Capturing changes | **SQLite triggers** on `deck` and `delete_batches` write `sync_outbox` in the writer's own transaction | Rows change from many places (deck, card, srs and starter repositories, subtree CTEs, cascades, purge). A trigger cannot be forgotten |
| Remote writes | Pull application and push acknowledgements run with `sync_state.applying_remote = '1'` inside their transaction, which the triggers skip | Pulled data must not echo back to the server |
| Enabling | Sync runs only when the build defines `API_BASE_URL` (`--dart-define`). Without it the outbox still fills, so turning sync on later loses nothing | Tests, goldens and web E2E stay offline |
| Connectivity | `connectivity_plus` triggers a run when the network returns; plus runs at start, after local writes and on backoff | Owner's choice |
| Trash | `delete_batches` is synced as the entity `delete_batch`, with a server table and handler added in this slice | A trashed deck references its batch, which holds the only deletion time (30-day retention) |
| Dependencies | `dio`, `retrofit`, `retrofit_generator`, `json_annotation`, `json_serializable`, `connectivity_plus` | ADR-012 #6: added with the first real API call |

## 3. Local schema (Drift v3 → v4)

New file `lib/core/database/tables/sync.drift`:

```sql
CREATE TABLE sync_outbox (
  op_id TEXT NOT NULL PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  op TEXT NOT NULL CHECK (op IN ('upsert', 'delete')),
  created_at DATETIME NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  payload TEXT,  -- schema 13 (DEV-181): what a delete sends beyond the op
  UNIQUE (entity_type, entity_id)
) AS SyncOutboxEntry;

CREATE TABLE sync_state (
  name TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
) AS SyncStateEntry;
```

`deck` and `delete_batches` gain `server_version INTEGER` (nullable; null
means the server has never acknowledged the row).

Triggers, one set per synced table. They run only when
`(SELECT value FROM sync_state WHERE key = 'applying_remote') IS NULL`:

- `AFTER INSERT` and `AFTER UPDATE` → upsert `(entity_type, entity_id)` into
  `sync_outbox` with `op = 'upsert'`. The upsert sets a **new `op_id`** and
  keeps the existing `created_at`.
- `AFTER DELETE` → the same with `op = 'delete'`. This covers purge and
  foreign-key cascades. From schema 13 (DEV-181) the deck and card triggers
  keep the row's `delete_batch_id` and `server_version` in `payload` as JSON
  (`{"deleteBatchId", "serverVersion"}`) when the row was in the Trash, so
  the server can tell a purge of a row still in that batch from one another
  device restored; a delete outside the Trash carries none.
- `op_id` is a random UUID built in SQL from `randomblob(16)`.
- `created_at` is the time of the first pending write, and push order is
  `created_at`, so a parent is pushed before its child.

The migration seeds the outbox with every existing `delete_batches` and `deck`
row, in that order, so the first sync uploads the existing library. It also
stores a new `device_id`. `drift_schema_v4.json` is generated, and
`test/drift/migration_test.dart` covers v1/v2/v3 → v4.

## 4. Network (`lib/core/network/`)

- `ApiConfig`: `baseUrl` from `String.fromEnvironment('API_BASE_URL')`;
  `isEnabled` is true when it is non-empty.
- One `Dio` (a `keepAlive` provider) with timeouts: connect 10 s, receive
  20 s, send 20 s. A `RequestIdInterceptor` sets `X-Request-ID` to a new UUID.
- `SyncApi` (Retrofit, `@RestApi()`): `push(PushRequestModel)` →
  `PushResponseModel`; `changes(since, limit)` → `ChangesResponseModel`.
- DTOs are `json_serializable` classes mirroring the server wire format of
  the server spec §4. `row` stays a `Map<String, dynamic>`, and the entity
  adapters convert it.

## 5. `SyncCoordinator` (`lib/core/sync/`)

A `keepAlive` provider, started from `main` when `ApiConfig.isEnabled` is
true. It owns one run loop, and at most one run is in flight.

**Triggers:** app start; connectivity back (`connectivity_plus`); outbox
changes (a `watch()` on `sync_outbox`, debounced 2 s); and retry after a
failure, with backoff of 5 s, 10 s, 20 s and so on, capped at 5 minutes.

**Run = push, then pull.**

- **Push:**
  - Read up to 100 outbox entries ordered by `created_at`.
  - For each entry, the adapter reads the entity's current row. An `upsert`
    whose row is gone is sent as a `delete`. A `delete` sends the entry's
    `payload` as its `row` (server sync spec §4.1).
  - `POST /sync/push`.
  - For each result, in one transaction with `applying_remote`:
    - `applied` sets the row's `server_version`, and deletes the outbox
      entry **only if its `op_id` still equals the one sent**. An edit made
      during the push has replaced the `op_id`, so that entry stays pending.
    - `rejected` applies `current`: it upserts the row, or deletes it when
      `current` is a tombstone. So a purge the server refuses
      (`ENTITY_NOT_IN_TRASH`: another device restored the row) brings the
      row back, and an edit of a row purged elsewhere
      (`ENTITY_TOMBSTONED`) removes it. When `current` is `null` the server has
      never seen the row, so the row and its cards are **kept** and the
      rejection is logged. The entry is deleted on the same `op_id`
      condition.
    - `current` is applied in a savepoint of its own (DEV-183): a copy this
      device cannot hold yet (its parent not pulled, a constraint the local
      rows break) fails only that entity. The row stays as it is, recorded
      in `sync_rejection` as `LOCAL_APPLY_FAILED`, and the run goes on to
      the pull, which brings the parent; a pull that applies the server's
      copy of a listed row clears its record.
  - Repeat while entries remain.
- **Pull:**
  - `GET /sync/changes?since=` from `sync_state.since`, paging while
    `hasMore`.
  - Each page is applied in one transaction with `applying_remote` and
    `PRAGMA defer_foreign_keys = ON`, because a child may arrive before its
    parent.
  - Changes for entities that still have an outbox entry are skipped.
  - Upserts write the row, including `server_version`. Tombstones delete it,
    and Drift's cascades remove its local descendants, matching the server's
    subtree tombstone.
  - `since` is stored in the same transaction.
- **Known limit until card sync (rollout step 4):** pulling a deck
  tombstone deletes the deck locally, and Drift's cascades remove its cards.
  A tombstone comes only from a purge on another device, so this matches what
  the person asked for. It also removes cards created on this device in that
  deck and never uploaded.
- **Backoff:** during a backoff, local writes wait for the retry; a
  reconnection retries at once and resets the backoff.
- **Errors:**
  - A network error or 5xx increments `attempts` and schedules a backoff.
  - Each RPC (`sync_push` of one batch, `sync_changes` of one page) is
    bounded at 30 s (`SupabaseSyncApi.rpcTimeout`, DEV-186): a request the
    network never answers fails as `TimeoutException`, a network failure,
    so the run ends, backs off, and a `pause()` waiting on it (an account
    transition) returns instead of hanging until the app is killed.
  - A 4xx on push, meaning a batch the server refuses as a whole, is logged
    and backs off.
  - Nothing reaches the UI.

**`EntitySyncAdapter`** is one per entity type, and the coordinator never
names a table. Its interface: `entityType`, `readRow(id)`,
`upsertFromServer(row, serverVersion)`, `deleteFromServer(id)` and
`markAcknowledged(id, serverVersion)`. It has two implementations,
`DeckSyncAdapter` and `DeleteBatchSyncAdapter`. The wire rows use
camelCase column names, UUID strings and ISO-8601 UTC times (ADR-008).

## 6. Server additions (same slice)

- Flyway `V3__delete_batch.sql` creates `delete_batch`: `id uuid PK`,
  `user_id`, `item_type` (`card|deck`), `root_item_id uuid`,
  `deleted_at timestamptz`, `server_version bigint`, `last_device_id`,
  `tombstoned_at timestamptz NULL`, and a unique
  `(user_id, server_version)`. The tombstone column is not named
  `deleted_at`, because that is the batch's own deletion time.
- `DeleteBatchSyncHandler` (package `trash`): a whole-row upsert, owner
  checked, one version per write; a delete sets `tombstoned_at`. It has no
  tree rules.

## 7. Unchanged

Use cases, presentation, `DeckRepositoryImpl` and every other repository. The
triggers do the capturing.

## 8. Testing

- **Triggers:** create, rename, subtree move (the CTE rewrite of every
  descendant), soft delete, restore and purge all leave exactly one outbox
  entry per touched row, with the right `op`, a fresh `op_id` on every write
  and the original `created_at`. Writes under `applying_remote` leave none.
- **Migration:** v1/v2/v3 → v4, with the outbox seeded.
- **Coordinator,** against a fake `SyncApi`:
  - coalescing;
  - an edit during the push survives the ack;
  - a rejection applies `current`;
  - pull skips pending entities;
  - a child applied before its parent in one page;
  - a tombstone cascades;
  - backoff;
  - disabled without `API_BASE_URL`;
  - two simulated devices sharing one in-memory fake server converge.
- **Server:** `DeleteBatchSyncHandler` IT, plus a push/changes round trip
  with a deck in a batch.
- **Gates:**
  - app: `flutter test --exclude-tags golden` and `dod_check.sh`; goldens
    are unaffected because sync is off;
  - server: `./mvnw verify`.
