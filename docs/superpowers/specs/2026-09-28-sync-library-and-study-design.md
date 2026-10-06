# MemoX — sync of cards, tags, study history and account settings

Status: approved 2026-09-28 · Path: architectural · WBS: SB-S1 (spec for SB-S2…SB-S5,
SB-S8) · Decision record:
[ADR-017](../../shared/decisions/ADR-017-lich-srs-dong-bo-nhu-mot-dong.md) · Parents:
[server-sync design](2026-09-27-server-sync-design.md),
[Supabase backend design](2026-09-28-supabase-backend-design.md),
[app deck-sync design](2026-09-27-app-deck-sync-design.md)

## 1. Intent

Decks and trash batches sync today (PR #114, #120). This spec extends the same row
model to the rest of a user's library and study state: `card`, `tags` with the
card–tag links, `review_log`, `card_schedule`, and the account-wide settings. It is
rollout step 4 of the server-sync spec, on Supabase.

Success means:

- every entity above goes up from the device that wrote it and down to any other
  device of the same user, with the rules of section 3;
- a device that pulls from `since = 0` rebuilds its Drift database whatever the
  order of the rows across pages;
- an app update that adds a synced type pulls the rows of that type the server
  already holds;
- nothing changes for a build without Supabase, and the local-first rules hold:
  study, CRUD and search never wait for sync.

Out of scope: login and account linking (group C), sharing, the in-progress study
session, reminders (device settings).

## 2. Decisions (owner, 2026-09-28)

| # | Question (WBS "Quyết định còn mở") | Decision |
|---|---|---|
| D1 | How a card–tag link travels, given `card_tags` has a composite key | As a field of the card: the card row carries `tagIds`. The server derives its `card_tags` from it. A change of a card's links queues that card |
| D2 | Server key of the account settings; local `app_settings.id = 1` | One server row per user. On the wire the entity id is a constant, the nil UUID. Locally `app_settings` keeps `id = 1` |
| D3 | Reviews of an older `generation` | Kept as append-only history on every device; they never move a schedule |
| D4 | Pull pages and foreign keys | The whole pull, every page, is one Drift transaction with foreign keys checked at commit |
| D5 | How `card_schedule` syncs (supersedes the replay of server-sync spec §6) | As a whole row; on pull the schedule that has progressed further wins (section 3.4). No replay |

D5 is needed because replay cannot rebuild a schedule from the log: finishing
learning (`completeLearning`) writes `learned_at` and `due_at` with no `review_log`
row, and due dates are local midnights (BR-STUDY-074), so two devices in different
time zones would replay one log into two schedules. ADR-017 records it.

## 3. Rules by entity

The protocol (server-sync spec §4, Supabase spec §4) is unchanged: push by row with
`opId` idempotency, pull by `server_version`, whole-row upsert where the operation the
server applies later wins, tombstones for deletes, pending local rows skipped on pull.

### 3.1 `card`

- Wire row: `id`, `deckId`, `front`, `back`, `isFlagged`, `example`, `hint`,
  `pronunciation`, `deleteBatchId`, `createdAt`, `updatedAt`, and from SB-S3
  `tagIds` (section 3.2). `front_folded` and `back_folded` are not sent: the adapter
  computes them on pull with the same fold the repository uses.
- Server: `public.card` mirrors Drift's columns and CHECKs, with `user_id`,
  `server_version` and `deleted_at`; `deck_id → deck`, `delete_batch_id →
  delete_batch`.
- Upsert: another user's id → `SYNC_ENTITY_CONFLICT`; a deck that is missing,
  another user's or tombstoned → `CARD_DECK_MISSING`; a tombstoned card →
  `ENTITY_TOMBSTONED` with the tombstone (DEV-184, policy A: a tombstone is
  final, for decks too).
- Delete: tombstones the card and **hard-deletes** its `card_schedule`,
  `review_log` and `card_tags` rows on the server, when the card is still at
  the version the device last acknowledged (the delete's `row`, server sync
  spec §4.1); a card changed since is refused with `ENTITY_NOT_IN_TRASH` and
  its live copy (DEV-181). A device that already holds them
  loses them through the local cascade when it applies the card tombstone; a device
  that never pulled them never sees them.
- A deck delete (subtree tombstone) also tombstones every live card of those decks,
  one version per card, with the same hard delete of their children. Without it a
  new device would pull live cards of a deleted deck and fail the foreign key.
- Trash: moving to and restoring from the Trash are ordinary card and batch
  upserts (`delete_batch_id`); a purge deletes the rows locally and the triggers
  queue the deletes. Expiry of Trash batches stays local.
- A pulled card gets its schedule from the pull (section 3.4). Until SB-S4 ships,
  and whenever a pulled card has none, the pull's last step (section 4.2) gives it
  the initial schedule of its root's scheduler (BR-CARD-004).

### 3.2 `tags` and card–tag links

- Wire row of a tag: `id`, `name`, `nameFolded`, `createdAt`. `owner_id` stays
  `NULL` locally until login. `nameFolded` comes from the app (Dart folding); the
  server trusts it for uniqueness only.
- Server: `public.tags` with a unique index on `(user_id, name_folded)` over live
  rows. A second live tag with a taken name → `TAG_NAME_TAKEN`.
- Same name on two devices: the tag that reached the server first wins. When a
  pulled tag has the name of a different local tag, the tag adapter merges the local
  tag into the pulled one with the existing merge (`TagDao.merge`, the rename-merge of
  UC-TAG-001): the links move to the pulled tag, the local tag is deleted. Because pulls run under
  `applying_remote`, the adapter queues the affected cards and the deleted local tag
  itself, and clears any rejection recorded for that tag.
- Delete: tombstones the tag and removes its server `card_tags`. Locally the
  cascade removes the links, whose triggers queue the cards (below), so their
  `tagIds` follow.
- Links (D1): the card row carries `tagIds`, sorted. The server replaces the card's
  `card_tags` with the ids that are live tags of the user and ignores the rest: a
  tag not yet on the server (refused, or not pushed yet) must not refuse the card
  and so lose its edit; the card is queued again when its links change (merge,
  re-push). Locally, triggers on `card_tags` insert and delete queue an upsert of
  the card, skipped when the card itself is being deleted, so a delete stays a
  delete. On pull the card adapter makes the card's local links equal `tagIds`.
- The SB-S3 migration queues every card that has a link, so cards pushed by SB-S2
  get their links.

### 3.3 `review_log`

- Wire row: every column, camelCase (`action` included). Entity id is the log id.
- Server: `public.review_log` mirrors Drift's CHECKs; `card_id → card`. Upsert is
  insert-if-absent by id; an existing id is `applied` unchanged. There is no delete
  operation: rows go only with their card (section 3.1).
- Local: an insert trigger only (the table is append-only). The adapter inserts
  pulled rows if absent; it does not write `server_version` (the table forbids
  updates), so its acknowledgement is a no-op.
- Reviews of any generation are kept (D3). Progress and history read them as they
  do today.

### 3.4 `card_schedule`

- Wire row: every column but `card_id`; entity id is the card id.
- Server: `public.card_schedule` keyed by `card_id → card`, mirrors Drift's CHECKs,
  whole-row upsert, and never computes a schedule.
- Local: insert and update triggers queue the schedule; a delete comes only with the
  card and is not queued.
- On pull, the adapter keeps the local schedule, and queues it again, when the local
  one has progressed further by this order, compared left to right:
  1. higher `generation`;
  2. `scheduler_type` equal to the local root deck's;
  3. later `last_answered_at` (`NULL` first);
  4. `learned_at` set over `NULL`;
  5. higher `answer_count`.
  Otherwise, ties included, the pulled row is written. Every device applies the same
  order, so the devices converge on the most advanced schedule and the server ends
  with it after at most one more push.
- Cost (D5): when two devices review the same card offline, the later answer decides
  the schedule; the other answer stays in the history.
- A pull skips a schedule pending on this device, so a reset or a scheduler change
  pulled from another device can move the root past it. At the end of the pull the
  adapter reseeds every schedule not at its root's scheduler and generation (invariant
  9) with the initial state at the root's generation, as the change reseeded it on
  the device it was made, and queues it (DEV-224).

### 3.5 Account settings

- Synced: `card_limit`, `new_card_order`, `theme_mode`, `language`, and
  `updated_at`. Not synced: `reminder_*` (device settings, server-sync spec §5).
- Wire: entity type `account_settings`, entity id the nil UUID
  `00000000-0000-0000-0000-000000000000` (D2); row `cardLimit`, `newCardOrder`,
  `themeMode`, `language`, `updatedAt`.
- Server: `public.account_settings(user_id PK, …, server_version, deleted_at)`; the
  functions map the nil id to the caller's row. There is no delete.
- Local: an update trigger on `app_settings` queues the row only when one of the four
  synced columns changes, so a fresh install's defaults never overwrite the account.
  The adapter's pull writes those columns into `id = 1`; its acknowledgement is a
  no-op.

## 4. Coordinator changes

### 4.1 New types reach old cursors

The coordinator skips a type it has no adapter for and still advances `since`, so an
update that adds an adapter would never see the rows of that type already on the
server. `sync_state` keeps `pull_entity_types`, the sorted adapter types of the last
completed pull. When the current set differs, the next pull starts from `since = 0`
and stores the new set when it commits. Re-applying rows is idempotent; pending rows
are skipped as usual.

### 4.2 One transaction per pull (D4)

`_pull` runs every page inside one `applyingRemote(deferForeignKeys: true)`
transaction and stores `since` once, at the end. The transaction is open before the
first page and each page is applied as it arrives (DEV-206), so the pull holds one
page in memory whatever the size of the account. A failure rolls the whole pull back
and the next run starts from the stored cursor. Each change applies in a savepoint of
its own: one this device cannot hold is recorded as `PULL_APPLY_FAILED` and skipped
(DEV-185). The last step inside the transaction, run only when the pull applied
something (DEV-210), gives every card without a `card_schedule` row its initial
schedule (section 3.1) and reseeds every schedule the pull left behind its root
(section 3.4, DEV-224).

Cost: local writes wait while a pull runs. The SB-S2 measurement (section 6) records
the time of a large first pull; if it blocks study noticeably, the fix is a smaller
unit of commit that still orders parents first, decided then with numbers.

**Checkpoint for `since = 0` (DEV-206, decided 2026-10-06 with the numbers in the
card-sync plan's ledger):** kept as one transaction. 300 001 changes (50 000 cards
with schedules, 200 000 review logs) pull in about 101 s in this container, about
0.34 ms per change, with the pull adding about 100 MB to the process; memory no
longer grows with the account, and the first pull happens on a device before study
starts (auth spec #28). A per-type cursor (`sync_changes(since, max_rows,
entity_types)`, commit per page) is the next step, taken when a real account's first
pull is reported to exceed about two minutes or to be killed mid-way and repeat.

### 4.3 Adapters

`EntitySyncAdapter` stays as is. Adapters that must queue rows during a pull (tag
merge, schedule order) get the `SyncStore` in their constructor and call
`enqueue`.

### 4.4 Existing rows

Each slice's Drift migration queues the rows of its types that already exist
locally, as the deck migration did, so a library created before the update is
uploaded.

## 5. Server

- One migration per slice in `supabase/migrations/`, each extending `sync_push`'s
  dispatch, `private.current_change` and `sync_changes`'s `UNION ALL` with its
  types. Every new table: RLS on, no policy, privileges revoked, `(user_id,
  server_version)` unique.
- `sync_changes` stays ordered by `server_version` across types (D4 makes the order
  harmless).
- pgTAP per slice: owner isolation, idempotency, the rejection codes of section 3,
  tombstone cascades (deck → card → children), `tagIds` derivation, review
  insert-if-absent, settings keyed by user.

## 6. Slices and tests

| Slice | Content | Tests beyond pgTAP |
|---|---|---|
| SB-S2 | `card` (3.1), deck-delete cascade, Trash across types, §4.1, §4.2, §4.4 for cards, bulk measurement | Adapter round trip; two simulated devices converge on cards; a from-zero pull where a deck lands on a later page than its card; a new adapter resets the cursor; import of a large card set drains push and pull, with timings recorded in the plan ledger |
| SB-S3 | `tags` and links (3.2); the bulk measurement again with tags | Same-name tags on two devices merge and converge; a card delete with links stays a delete |
| SB-S4 | `review_log` (3.3) and `card_schedule` (3.4) | The order of 3.4 on every rule; two devices reviewing offline converge; reviews of an old generation are kept and move nothing |
| SB-S5 | Account settings (3.5) | Defaults on a new device do not push; a change on one device reaches the other; reminders stay put |
| SB-S8 | Needs login (group C): a second device of one user. D4 and §4.1 already make a from-zero pull correct | — |

Each slice has its own plan, PR and merge. SB-S5 depends only on this spec.
