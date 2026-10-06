# MemoX — server-backed offline synchronization

Status: approved 2026-09-27 · Path: architectural · Decision record:
[ADR-013](../../shared/decisions/ADR-013-dong-bo-voi-server-offline-first.md)

> **Amended 2026-09-28** by [ADR-015](../../shared/decisions/ADR-015-supabase-lam-backend.md):
> the 2026-09-27 command-sync amendment (ADR-014) is withdrawn, so this spec holds as
> written; the server side is implemented in Supabase
> ([Supabase backend design](2026-09-28-supabase-backend-design.md)), with `auth.uid()`
> in place of `CurrentUserProvider`.

> **Amended 2026-09-28** by [ADR-017](../../shared/decisions/ADR-017-lich-srs-dong-bo-nhu-mot-dong.md):
> section 6 (replay) no longer holds; `card_schedule` syncs as a row and the schedule that
> has progressed further wins ([library and study sync design](2026-09-28-sync-library-and-study-design.md) §3.4).

## 1. Intent

MemoX becomes an online app with an official backend that stays fully usable
offline: a user can do everything with no network, and when connectivity
returns the app synchronizes by itself. The owner decided this on 2026-09-27,
replacing the local-only posture of ADR-001.

Success means:

- with no network, CRUD, study, review, search and progress all work from
  Drift, with no error and no waiting;
- a change made on one device reaches the server, and from there a second
  device, without user action once both are online;
- two devices editing offline converge to the same data after syncing, with
  the loss rules in section 5 and never a silent duplicate;
- adding login later changes neither the sync protocol nor the server schema.

Out of scope here: login and account UI (section 3), sharing, deck
publishing, and syncing an in-progress study session.

## 2. Roles and layering

```
Presentation → UseCase → Repository (domain contract)
                              │
                     RepositoryImpl (data/)
                      │                 │
            LocalDataSource (Drift)   SyncCoordinator ──► Retrofit API (ADR-012)
                      │                                        │
          data rows + sync_outbox                     memox-api-services
                                                            │
                                                       PostgreSQL (canonical)
```

- **PostgreSQL** holds the canonical copy of every user's data, shared by all
  of that user's devices.
- **Drift** is each device's durable operational store. The app always reads
  and writes it, online or offline; it is never cleared as a cache.
- **Write path:** SQLite triggers on each synced table write the
  `sync_outbox` entry in the writer's own transaction, whichever code path
  wrote the row (see the [app deck-sync design](2026-09-27-app-deck-sync-design.md)).
  The UI updates from Drift's `watch()` at once.
- **`SyncCoordinator`** (in `data/`, one per app, with a `keepAlive`
  provider) runs push and then pull. It runs at app start, when connectivity
  returns, and after local writes, debounced by 2 seconds. Only one run is in
  flight at a time.
- Use cases and presentation never see HTTP, and the layering of ADR-010 is
  unchanged.

## 3. Identity (login later)

- The server resolves the owner through `CurrentUserProvider` (`common` in
  `memox-api-services`). Until the auth spec, it returns one fixed dev user
  whose UUID is set by the property `memox.dev-user-id`. The auth spec swaps
  in a JWT-backed implementation.
- An id that already belongs to another user is rejected with `SYNC_ENTITY_CONFLICT`, and that user's copy is never returned.
- Every server table has `user_id uuid NOT NULL`, and every query filters on
  it. A `user_id` sent by the client is ignored.
- Each installation generates a `device_id` (a UUID) once, stores it in
  `sync_state` and sends it with every sync request. The server records it on
  each change, for diagnostics.
- The local `owner_id` columns stay `NULL` until login. Claiming local data
  into an account belongs to the auth spec.

## 4. Protocol

### 4.1 Push

`POST /api/v1/sync/push`

```json
{
  "deviceId": "…",
  "operations": [
    {"opId": "…", "entityType": "deck", "entityId": "…", "op": "upsert", "row": {"…": "…"}},
    {"opId": "…", "entityType": "deck", "entityId": "…", "op": "delete",
     "row": {"deleteBatchId": "…", "serverVersion": 40}}
  ]
}
```

- A `delete` of a deck or card comes only from a Trash purge, and its `row`
  says what the device purged: the batch and the row's acknowledged
  `serverVersion` (DEV-181). The server tombstones the row only while it is
  still at that version; a row changed since (another device restored or
  re-trashed it) is refused with `ENTITY_NOT_IN_TRASH` and the live copy,
  which the device takes back. A delete without `serverVersion` (an older
  build, or a row never acknowledged) tombstones as before.
- A tombstone is final (DEV-184, policy A): an `upsert` on a tombstoned deck
  or card is refused with `ENTITY_TOMBSTONED` and the tombstone, and the
  device deletes its copy. An offline edit of a row purged elsewhere is lost,
  the price rule 5 already accepts.

- `opId` is the outbox row's id and the **idempotency key**. The server keeps
  the applied `opId`s per user (table `sync_applied_op`), so a resent
  operation is acknowledged again without being applied again.
- The server applies operations in order, each in its own transaction, and
  answers one result per operation: `{"opId": "…", "status": "applied",
  "serverVersion": 42}` or `{"opId": "…", "status": "rejected", "code":
  "DECK_TREE_CYCLE", "current": {"serverVersion": 40, "deleted": false, "row":
  {"…": "…"}}}`. `current` is the server's copy of the entity, or `null` when
  the server has never seen it. A rejected operation does not stop the batch.
- Batch limit: 100 operations; the coordinator loops until the outbox is
  empty.
- **One user's operations are serialized.** Each operation takes a
  transaction-scoped advisory lock on its user before reading, so a subtree read
  and the write that follows cannot interleave with another device's operation;
  two cross moves can never form a cycle. `(user_id, server_version)` is unique
  on every synced table.

### 4.2 Pull

`GET /api/v1/sync/changes?since=<serverVersion>&limit=500`

```json
{
  "changes": [
    {"entityType": "deck", "entityId": "…", "serverVersion": 43, "deleted": false, "row": {"…": "…"}},
    {"entityType": "deck", "entityId": "…", "serverVersion": 44, "deleted": true}
  ],
  "nextSince": 44,
  "hasMore": false
}
```

- `serverVersion` is a per-user sequence (`user_sync_version`, a counter
  incremented in the same transaction as the write). Every write, tombstones
  included, gets the next value.
- **One version per changed row.** A move or delete that touches a subtree allocates a block of versions, one per row, so a page boundary never splits the rows of one version and no change is skipped.
- Changes are ordered by `serverVersion`. The client applies each page in one
  Drift transaction and then stores `nextSince` in `sync_state`.
- Pulled changes do not create outbox entries.
- **Local pending edits win the display until pushed.** A pulled change for
  an entity that still has an outbox entry is skipped, and the next push
  settles it with rule 5.1.

### 4.3 Outbox

`sync_outbox(id TEXT PK, entity_type TEXT, entity_id TEXT, op TEXT,
created_at DATETIME, attempts INTEGER)`

- The outbox keeps at most one entry per `(entity_type, entity_id)`: a new
  write replaces the old entry's `op`, and `delete` overrides `upsert`.
- A replaced entry keeps its original `created_at`, and push order is `created_at`. A parent created before its child is therefore always pushed first, even if the parent was edited later; otherwise the child would be rejected with `DECK_PARENT_MISSING`.
- At push time the coordinator reads the entity's **current** row, so many
  edits are sent once.
- An entry is removed on `applied` or `rejected`. On `applied` the entity's
  `server_version` is set from the result. On `rejected` the client applies
  `current` directly: it overwrites the row, or deletes it when `current` is
  `null` or deleted. A pull cannot do this, because the server's copy may be
  older than the cursor. The failure is logged with its `code`.
- Network errors and 5xx responses keep the entry, increase `attempts`, and
  retry with exponential backoff from 5 seconds up to 5 minutes.

### 4.4 Wire evolution

A build that is behind the server, and a server that is behind a build, talk
to each other across every release (DEV-197). The `row` of an operation and
of a change is a JSON object; these rules keep it readable by both sides:

- **Keys are only added.** A new key is nullable or has a default; a row
  without it means the old behaviour: the column's default, or for a key that
  carries a collection, unchanged (R10 `tagIds`: a card row without the key
  leaves the card's links as they are). The server reads a missing key as
  `null` and never fails a push on a key a build could not know.
- **A key is never renamed or dropped** without the old key being written
  and read for at least one release.
- **An adapter reads a new key null-safe:** `row['x'] as T?` with the
  default, never `row['x'] as T`. Only the contract keys below are read
  `as T`.
- **A new entity type** is ignored by an older build (it has no adapter), and
  `pull_entity_types` in `sync_state` brings its rows down once the build
  that knows it runs.
- **Every slice that changes the wire** adds one pgTAP test: a push in the
  wire of the previous slice is still `applied`.
- **An old build's `delete`** carries no `row`; a slice that adds keys to
  the operation (DEV-181's `deleteBatchId` and `serverVersion`) treats their
  absence as the behaviour before the slice: the delete is unconditional.
- **A server `CHECK` on a released column is tightened only to a rule every
  released build already enforces before writing** (DEV-214:
  `account_settings.card_limit` 1..200, BR-STUDY-003), so no stored row and
  no push of a released build breaks it. A push that does is
  `VALIDATION_FAILED` with `current`, as for any `CHECK`; an adapter reads
  such a value as it reads a missing key, leaving the device's own value.

**Contract keys.** `NOT NULL` without a default on both sides, written by
every build and never dropped; an adapter reads them `as T`:

| Entity | Contract keys |
|---|---|
| `deck` | `id`, `name`, `rootId`, `depth`, `siblingPosition`, `createdAt`, `updatedAt` |
| `card` | `id`, `deckId`, `front`, `back`, `createdAt`, `updatedAt` |
| `tag` | `id`, `name`, `nameFolded`, `createdAt` |
| `delete_batch` | `id`, `itemType`, `rootItemId`, `deletedAt` |
| `card_schedule` | `cardId`, `schedulerType`, `schedulerVersion`, `generation` |
| `review_log` | `id`, `cardId`, `sessionId`, `schedulerType`, `generation`, `kind`, `mode`, `action`, `answeredAt` |
| `account_settings` | `updatedAt` |

Every other key is optional: nullable columns read `as T?`, defaulted ones
read `as T?` with the default (`deck.contentType`, `card.isFlagged`,
`card_schedule.answerCount` and `lapseCount`), and the four settings of
`account_settings` are left as they are when the row leaves them out.

## 5. Conflict rules by data class

| Data | Rule |
|---|---|
| `deck`, `card`, `tags`, `card_tags`, account settings | Whole-row upsert; the operation the server applies **later** wins. The client's `updated_at` is stored but never compared |
| deck tree | `root_id` and `depth` are **server-derived**: the server ignores the client's values, computes them from `parent_id`, and on a move rewrites the whole live subtree in the same transaction, so a client's per-row operations may arrive in any order. It rejects a cycle (`DECK_TREE_CYCLE`), a subtree that would pass 10 levels (`DECK_TREE_TOO_DEEP`), and a missing, deleted or foreign parent (`DECK_PARENT_MISSING`). The root shape (a root holds decks and owns the scheduler) is validated as `VALIDATION_FAILED` |
| `review_log` | Append-only. Insert-if-absent by `id`; an existing id is `applied` without change |
| `card_schedule` | Derived (section 6) |
| deletes and trash purge | `op: delete` sets `deleted_at` (a tombstone) and bumps `server_version`; children follow their foreign-key semantics on the server. Devices delete the row on pull. Trash `delete_batch_id` states sync as ordinary deck/card upserts. A purge tombstones only a row still at the version the device last acknowledged (4.1); a row changed since is refused with its live copy. A tombstone is final: a later upsert is refused with the tombstone (DEV-181, DEV-184) |
| `study_session`, `study_queue_items`, `study_guess_options`, device settings (reminders, notifications) | Not synced |

## 6. SRS schedule

- Only the app computes schedules; the server never runs `eight_box` or
  `sm2`.
- After a pull that brought `review_log` rows, the app recomputes
  `card_schedule` for each affected card. It replays the card's reviews in
  `(reviewed_at, id)` order through that card's scheduler. The replay is
  deterministic: UTC timestamps (ADR-008), no wall-clock reads (the `Clock`
  is injected), and a total order.
- The recomputed schedule is written locally and pushed as a derived upsert.
  The server stores it only so that a newly installed device starts without
  replaying the full history.
- Two devices holding the same review log compute the same schedule.

## 7. Server schema conventions (Flyway)

- Table and column names are `snake_case` and match Drift's names.
- `id uuid PRIMARY KEY` has no default, because ids are client-generated
  (ADR-007).
- `user_id uuid NOT NULL`, indexed as the first column of every lookup.
- `created_at` and `updated_at` are `timestamptz`, taken from the client and
  used for display and ordering only.
- `server_version bigint NOT NULL`, indexed `(user_id, server_version)`.
- `deleted_at timestamptz NULL` is the tombstone; reads for the API filter
  `deleted_at IS NULL` except in `sync/changes`.
- Foreign keys and `CHECK` constraints mirror Drift's.
- Support tables: `user_sync_version(user_id PK, version bigint)` and
  `sync_applied_op(user_id, op_id, PRIMARY KEY (user_id, op_id))`. The daily
  `cleanup_accounts` forgets applied op ids older than 90 days (DEV-200):
  every operation is idempotent by content, so a forgotten op id resent is
  applied again as the same upsert or delete, never doubled.

## 8. Local changes (one Drift migration, at the first integration slice)

- New tables `sync_outbox` (4.3) and `sync_state(key TEXT PK, value TEXT)`,
  holding `device_id` and the `since` cursor.
- New column `server_version INTEGER NULL` on each synced table. `NULL` means
  never acknowledged by the server.
- Triggers on synced tables write the outbox entry in the same transaction
  as the row, purge and cascades included. Every write sets a fresh `op_id`,
  and an acknowledgement deletes the entry only if its `op_id` is unchanged.
  Writes that apply server data run under `sync_state.applying_remote`, which
  the triggers skip.
- Text pushed is already NFC: migration v4 → v5 and every write normalise it
  (BE-C5), so the server compares strings as stored. The v4 → v5 step
  rewrites deck names under the capture triggers, so a renamed deck is queued
  and its NFC name reaches the server.

## 9. Rollout

1. This spec and ADR-013; `PRODUCT.md` and ADR-001 updated.
2. Server slice: `deck` table (Flyway `V1`), `CurrentUserProvider`, the sync
   support tables, and `POST /sync/push` plus `GET /sync/changes` for `deck`,
   with the tree-invariant checks. Integration tests against PostgreSQL.
3. App slice: the Drift migration of section 8, `SyncCoordinator`, the
   Retrofit `SyncApi`, and deck repositories writing the outbox.
4. Extend to `card`, `tags`, `card_tags`, account settings, `review_log` and
   the schedule replay.
5. Login, as its own spec.

Each step gets its own plan; steps 2 and 3 can run in parallel once this spec
fixes the wire format.

## 10. Testing

- Server: push idempotency (same `opId` twice), ordering and `serverVersion`
  monotonicity, tombstones in `changes`, tree-cycle rejection, isolation
  between two users, and pagination of `changes`.
- App: outbox coalescing, push-then-pull convergence of two simulated
  devices against a fake server, skipping pulled changes for pending
  entities, backoff, and schedule replay determinism (the same log in two
  orders of arrival gives the same schedule).
