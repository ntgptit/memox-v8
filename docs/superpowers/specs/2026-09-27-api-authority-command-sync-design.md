# MemoX — the API as the business authority, with command-based sync

Status: approved 2026-09-27 · Path: architectural · Decision record:
[ADR-014](../../shared/decisions/ADR-014-api-la-backend-nghiep-vu-chinh-thuc.md) ·
Amends: [server sync design](2026-09-27-server-sync-design.md)

## 1. Intent

`memox-api-services` becomes the official backend of the product, not a sync
server for Android. Every client that may come later (web, iOS, desktop) must
be able to perform every business operation Android can, through the API.
Android keeps its local implementation of the same business rules, so that it
still works fully offline; a web client does not need one.

Success means:

- a business operation behaves the same whether it runs through REST (a web
  client) or through a sync command replayed from an Android outbox, because
  both enter the same server service;
- when Android's offline result and the server's result differ, the server's
  result is what every device ends with;
- the SRS schedule computed by Dart and by Java agrees on a shared
  conformance dataset, and CI fails when they diverge;
- the infrastructure of the deck sync slice
  ([PR #110](https://github.com/ntgptit/memox-v8/pull/110)) is kept and
  extended, not rewritten.

Out of scope: designing a web client, login (its own spec), and the detailed
contract of each capability. Each capability gets its own spec and plan
(section 9).

## 2. Scope rule

> If a client other than Android needs to perform a business operation, and
> the result of that operation must persist or be shared across devices, the
> API supports that operation.

- **Server-owned:** deck and card CRUD, the deck tree invariants, tags, Trash,
  the SRS schedule, reviews, progress resets, scheduler changes, account-level
  settings, and read capabilities a client cannot compute without the local
  database (search, progress, card history).
- **Client-owned:** UI state, display sort and transient filters, animation,
  navigation, timers shown on screen, date formatting, local drafts, and the
  in-progress study session (ADR-013 #10 stands).
- The API is a business contract, not a remote UI controller: a client may run
  parts of a flow locally (for example a study session's queue) and send only
  the business results (reviews).
- The server does not mirror Drift's structure. It must enforce the same
  business rules (BR) through its own services, queries and transactions.

## 3. Server architecture

```
Web / iOS ──REST──► XxxController ──┐
                                    ├──► XxxService ──► Mapper ──► PostgreSQL
Android ──sync/push──► SyncService ──► SyncCommandHandler ──┘
                                    (every write bumps server_version → change feed)
```

- **One service per business operation.** `DeckService.move` is the only code
  that moves a deck. The REST controller and the sync handler are two entry
  points into it and hold no business rule.
- **`SyncEntityHandler` (PR #110) evolves into `SyncCommandHandler`:** one
  handler per command type, plus one handler per patchable field group. A
  handler maps the payload to a service call and returns the entities the
  service changed.
- **Every service write bumps `server_version`** of each row it changes,
  through the per-user version counter of PR #110. The change feed therefore
  carries a change whatever its entry point was.
- **The deck-tree logic of PR #110** (server-derived `root_id` and `depth`,
  cycle, depth and parent checks, whole-subtree rewrite) moves into
  `DeckService` and serves both entry points.
- **REST mutations are idempotent on request:** they accept an optional
  `Idempotency-Key` header, recorded in the same `sync_applied_op` table as
  sync operations, so a web client can retry safely.
- **Identity:** unchanged from the server sync design §3 (`CurrentUserProvider`,
  a dev user until login).

## 4. Protocol

### 4.1 Push: intents

`POST /api/v1/sync/push` keeps its envelope (`deviceId`, `operations`, at most
100 per batch, per-user serialization, `opId` idempotency). An operation is one
of two kinds:

```json
{"opId": "…", "kind": "command", "type": "MOVE_DECK",
 "payload": {"deckId": "…", "targetParentId": "…"},
 "affected": [{"entityType": "deck", "entityId": "…"}]}

{"opId": "…", "kind": "patch", "entityType": "card", "entityId": "…",
 "group": "content", "fields": {"front": "…", "back": "…"}}
```

- **`command`** carries an intent. The server executes it through the
  business service, which validates every rule.
- **`affected`** lists every entity the command changed in the client's local
  store. The client knows this because it just ran the same operation
  locally.
- **`patch`** carries plain mutable data for one field group of one entity.
  The field group's service validates it, and the patch the server applies
  later wins. A patch never touches a field that a command owns (for example
  `deck.parent_id`), which is why patches are per field group and not per row.
- The row upsert of PR #110 is retired once the deck commands replace it
  (section 9, step 1).

Results:

- `{"opId": "…", "status": "applied", "serverVersion": 42}`: the highest
  version the operation produced.
- `{"opId": "…", "status": "rejected", "code": "DECK_PARENT_MISSING", "current": [{"entityType": "deck", "entityId": "…", "serverVersion": 40, "deleted": false, "row": {…}}, …]}`.
  `current` holds the server's copy of every entity in `affected`, and only
  of entities the user owns. An entity the server has never seen is returned
  with `row: null`.
- **Each operation stands alone.** A rejection does not stop the batch. Later
  operations are validated on their own merits against the server's state.
  The client overwrites or deletes its local copy of each entity in `current`,
  and logs the code. The user is not asked to act.

### 4.2 Outbox

- **One FIFO queue**, ordered by a local monotonic `seq`.
- **Commands are never coalesced.** Two `MOVE_DECK` of the same deck are two
  intents, and the server validates both, in order.
- **Patches are coalesced per (entity, field group).** A replaced patch keeps
  its original `seq` and reads the current field values at push time, which
  is the server sync design's `created_at` rule applied to patches.
- **Pending entities:** an entity is pending while any outbox entry names it,
  either as a patch target or in a command's `affected`. A pulled change for a
  pending entity is skipped. The next push settles it, and a rejection carries
  its `current`.
- Network errors, 5xx responses and backoff are unchanged (server sync design
  §4.3).

### 4.3 Pull: canonical state

`GET /api/v1/sync/changes` is unchanged: a per-user change feed of whole rows
ordered by `serverVersion`, including tombstones.

- **One transaction per pull run.** The client fetches every page until
  `hasMore` is false, and applies them in one Drift transaction with
  `PRAGMA defer_foreign_keys = ON`. It stores `nextSince` only on commit.
- **Why:** a row carries the version of its latest change only, so a child
  can arrive before a parent that was edited later. The server keeps its
  foreign keys consistent and deletes are tombstones, so every reference
  resolves once all pages are in. A failure rolls the whole run back, and the
  cursor does not move.
- **Deferred:** a `GET /api/v1/sync/snapshot` bootstrap in parent-first order
  for a new device, triggered by a first sync measured as too slow.

## 5. Operation catalog

**Commands**

| Capability | Commands |
|---|---|
| Deck | `CREATE_ROOT_DECK`, `CREATE_SUB_DECK`, `RENAME_DECK`, `MOVE_DECK`, `REORDER_DECK`, `DELETE_DECK` (into Trash as a batch), `UNDO_DECK_DELETION`, `CHANGE_DECK_SCHEDULER` |
| Card | `CREATE_CARD`, `MOVE_CARDS`, `DELETE_CARDS`, `UNDO_CARD_DELETION`, `ADD_TAG_TO_CARDS`, `REMOVE_TAG_FROM_CARDS` |
| Tags | `RENAME_TAG` (including a merge), `DELETE_TAG` |
| Trash | `RESTORE_DECKS`, `RESTORE_CARDS`, `PURGE_TRASH` |
| SRS and study | `RESET_LEARNING_PROGRESS`, `RECORD_REVIEW`, `COMPLETE_LEARNING` |

**Patches (entity · field group)**

- card · `content` (`EditCard`) and card · `flag` (`SetCardsFlagged`, one
  patch per card);
- account settings · `appearance` (theme, language), · `study_defaults`, and
  the reset to defaults;
- root deck · `study_options` (`SaveRootStudyOptions`, `UseAppDefaults`).

**Not synced:** the study session operations (open, resume, abandon, reveal,
hint, recall time) and reminders.

**Read-only REST, not synced:** the `watch_*` reads, search, progress, card
history, the tag catalog, move and restore targets, deletion and reset
summaries, and building an export.

**Composite client operations:**

- **Import:** Android expands a committed import into `CREATE_CARD` and
  `ADD_TAG_TO_CARDS` commands. A web client will need a batch REST endpoint,
  decided in the card capability spec.
- **Starter decks:** Android expands a template into create commands. Serving
  the template library to other clients is decided in the starter decks spec.
- **Expired Trash purge (BR-TRASH-009):** the server runs it as a scheduled
  job with the same retention rule. Android purges locally and does **not**
  push that purge. User-triggered `PURGE_TRASH` is still a command.

**Duplicate tag names:** the server keeps `(user_id, name_folded)` unique among
live tags. A command that would create a second live tag with the same name is
rejected with `TAG_NAME_TAKEN`, and `current` carries the existing tag. The
client then runs its existing rename-merge flow (BR-TAG-003…BR-TAG-011): it
moves its `card_tags` to the existing id, deletes its own tag, and rewrites
the tag id in its pending outbox entries.

## 6. SRS

- **The server is the authority.** Java implements `eight_box` and `sm2`,
  keyed by `scheduler_type` and `scheduler_version`, which the schema already
  carries (`schema.md`, `deck` and `card_schedule`). Android's Dart
  implementation stays, for offline use.
- **`card_schedule` is derived canonical state, never a sync input.** No
  command or patch carries schedule fields. Clients receive it through pull
  and overwrite their provisional local copy.
- **`RECORD_REVIEW`** carries every field of Dart's `ReviewTurn`: `id` (the
  review id), `cardId`, `generation`, `kind` (`learning` | `scheduled` |
  `relearning`), `mode`, `action`, `direction`, `answeredAt`,
  `outcomeReason`, `comparisonVersion` and `usedHint`. A review id already
  stored is `applied` without change.
- **`COMPLETE_LEARNING`** (`cardId`, `at`) is the event that starts a card's
  schedule (`learned()`, BR-STUDY-053). If the card is already learned, the
  earliest event wins and a later one is `applied` without change.
- **`RESET_LEARNING_PROGRESS`**: the server increments the root's `generation`
  (BR-SRS-020) and resets the schedules of its cards.
- **Generation:** a review or completion whose `generation` is older than the
  root's current generation is **rejected** (`SRS_GENERATION_STALE`,
  BR-SRS-026). `current` returns `null` for the review, so the client deletes
  its local row, and returns the card's schedule.
- **Rebuild:** after any change to a card's SRS events, the server rebuilds
  its schedule. It starts from the initial state and applies the events of the
  current generation in `(answered_at, id)` order:
  - a completion calls `learned()`;
  - a `scheduled` review calls `next()`;
  - `learning` and `relearning` reviews are stored and leave the schedule as
    it is (BR-SRS-017).

  A `scheduled` review that falls before the card's completion is stored,
  skipped by the rebuild, and logged. Card histories are small, so a full
  per-card rebuild is always affordable.
- **`kind` is trusted from the client** (BR-SRS-015: the session decides it,
  and sessions are not synced). The server checks only the consistency rules
  above.
- **Conformance dataset:** one directory of JSON cases, at a path shared by
  the monorepo. Each case holds the scheduler, its version, the initial state,
  the ordered events and the expected schedule. Dart tests and Java tests both
  load every case, and a divergence fails CI. The dataset is written first,
  extracted from the existing Dart scheduler tests. It includes out-of-order
  arrival, a stale generation, a review before completion, and a scheduler
  change.

## 7. Conflict rules (replaces server sync design §5 for the covered data)

| Data | Rule |
|---|---|
| Command-owned state (tree position, deletion, Trash batches, tag identity, card–tag links) | The service validates each command against current server state; a violation is rejected with `current` (4.1) |
| Patch-owned field groups | The patch the server applies later wins; the client's `updated_at` is stored, never compared |
| `review_log` | Append-only by review id; old generation rejected (6) |
| `card_schedule` | Derived by the server (6) |
| Not synced | Unchanged: study session tables, device settings |

## 8. Error handling

- A rejected operation is not an error of the push request: the response is
  `200` with per-operation results, as in PR #110.
- Every rejection code is an `ErrorCode` constant with its message
  (`memox-api-services` README, "Errors"). The ones this spec adds are
  `TAG_NAME_TAKEN` and `SRS_GENERATION_STALE`; each capability spec adds its
  own.
- An unknown command `type` or patch `group` is rejected with
  `VALIDATION_FAILED`, never a `500`, so an older server does not break a
  newer client's batch.

## 9. Rollout and tracking

Progress lives in [`wbs_API.md`](../../wbs_API.md) (server) and
[`wbs_BE.md`](../../wbs_BE.md) (app). Each step below is one or more WBS items
with its own spec and plan:

1. Command protocol and Deck: `command` and `patch` in push, handler
   registry, deck commands through `DeckService`, deck REST, `Idempotency-Key`;
   retire the deck row upsert.
2. App: the deck sync slice on the command protocol (the Drift migration of
   the server sync design §8, with `sync_outbox` holding `seq`, `kind`, `type`,
   `payload`, `affected`).
3. Card and Tags, including duplicate tag names.
4. Auth, before any deployment and before a second client.
5. Trash, including the expired-purge job.
6. SRS: conformance dataset first, then the Java schedulers, the SRS commands
   and the rebuild.
7. Account settings.
8. Read capabilities for other clients: search, progress, card history.
9. Deferred: the snapshot bootstrap.

## 10. Testing

- **Server, per capability:** the service is tested once, and both entry
  points are tested for wiring only. REST and a replayed command must produce
  the same rows and versions for the same input.
- **Protocol:** a rejection carries `current` for every affected entity, and
  never another user's; a rejection does not stop the batch; an unknown type
  is rejected, not a `500`; `Idempotency-Key` replays return the first result.
- **Outbox (app):** commands keep order and are never coalesced; patches
  coalesce per field group and keep their first `seq`; pending entities skip
  pulled changes.
- **Pull (app):** a child page before its parent's page commits; a failure
  mid-run rolls back and keeps the cursor.
- **SRS:** the shared conformance dataset in Dart and Java; rebuild after
  out-of-order arrival equals rebuild in order.
