# Every query in `.drift`, P7 (sync and account store) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `AccountStore`, the seven sync adapters and `SyncStore` to `@DriftAccessor`s whose queries live in `.drift`, take them off the guard's temporary exclude, and measure the pull (D9).

**Architecture:** P0–P6 set the pattern (ADR-020).
- **Accessors keep their names and constructors.**
  - `AccountStore`, `SyncStore` and the `*SyncAdapter` classes become `extends DatabaseAccessor<AppDatabase> with _$…Mixin`, built with `(super.attachedDatabase, …)`, and the adapters keep `implements EntitySyncAdapter`.
  - `AccountStore` stays non-final, because `KillableAccountStore` extends it.
  - `TagSyncAdapter` and `CardScheduleSyncAdapter` keep calling `SyncStore.enqueue`/`clearRejection` as they do today. This is existing structure that the phase leaves as it is.
- **One query file per synced entity (D3).**
  - The files are `sync_deck_queries`, `sync_card_queries` (card, its links and `ensureSchedules`), `sync_tag_queries`, `sync_card_schedule_queries`, `sync_review_log_queries` and `sync_delete_batch_queries`.
  - `sync_outbox_queries` (outbox, state, rejections, seeds) belongs to `SyncStore`, and `account_state_queries` to `AccountStore`.
  - `AccountSettingsSyncAdapter` reuses `settings_queries.drift` (`appSettingsRow`, `updateAppSettings`).
- **Upserts are explicit.** Drift's `insertOnConflictUpdate(companion)` becomes `INSERT INTO t $row ON CONFLICT (<pk>) DO UPDATE SET <col> = excluded.<col>, …`.
  - The `SET` list is exactly the non-key columns each companion supplies, so a column the builder left alone (`owner_id`) stays alone.
  - The companions themselves do not change.
  - `insert(..., insertOrIgnore)` becomes `INSERT OR IGNORE`.
  - The syntax was checked on a probe: `$row` in an upsert generates `Insertable<…>`.
- **`batch` (D9).** There is no `batch` left in sync. The pull already writes row by row inside `applyingRemote`'s transaction. D9's check is therefore the pull's time before and after, measured with `sync_bulk_test.dart` (5,000 tagged cards, more than D9's 1,000).
  - Baseline on `ac28f2e`, 3 runs: pull 1329–1523 ms, push 4767–5235 ms.
  - If the pull regresses by more than 20%, the ADR records the exception before this merges (spec §7).
- **The outbox order.** `pendingBatch` ranks entity types by their position in the adapter list.
  - The `CASE` SQL string becomes `$rank`, an `OrderingTerm` built with `entityType.caseMatch(...)`, which is the builder use ADR-020 allows.
  - `rowid` stays in the `.drift` `ORDER BY`. Checked on a probe.
- **`markAllPending`** becomes seven fixed `INSERT … SELECT … ON CONFLICT DO NOTHING` statements in `sync_outbox_queries.drift`, in the coordinator's order. Each has the same op-id expression as the migrations' `seedOutboxSql`. Migrations keep `seedOutboxSql`, because migrations are an exception (D7).
- **Tombstone allowlist.** `tombstone_filter_test` treats a `.drift` write as a read. Sync reads and writes card and deck rows in any state on purpose, so each such statement gets an entry with its reason. The existing `file#member` entries for sync become `file.drift#query`.
- **`PRAGMA defer_foreign_keys`** stays a `customStatement` (D7).
- **`outboxChanges`** becomes `tableChanges([syncOutbox])`. Like the old `select().watch()` it fires on listen and on every write.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P7; D3, D7, D9; §7). ADR-020.

## Global Constraints

These are the same as P2–P6:
- Behaviour-preserving.
- Generated `*.g.dart` stays uncommitted.
- Guard commands use `python3.13`.
- Generated parameters follow first appearance in the SQL.
- Card and deck statements in `.drift` name `delete_batch_id`, or carry an allowlist entry.
- Every new query file gets an impact-map owner row.
- Query names never collide with accessor members or with other files an accessor includes.
- Wire shapes and the `EntitySyncAdapter` contract do not change.

## Review Focus

1. **The upserts write the same columns as before.** Each `SET` list is the companion's non-key columns, and nothing more. `owner_id` is untouched. Pinned by the adapter round-trip and convergence tests.
2. **The outbox order is the same** (parents first by adapter order, then `created_at`, then `rowid`). Pinned by the coordinator and bulk tests.
3. **`markAllPending` queues the same rows in the same order**, keeps an already queued op, and sets the cursor back to 0. Pinned by the sync store and auth tests.
4. **The status stream re-emits** on writes to the state, outbox and rejection tables. Pinned by the sync status tests.
5. **The pull time** stays within 20% of the baseline.

---

### Task 1: `AccountStore`

- [ ] **Red.** Take `lib/core/auth/account_store.dart` off the guard scope and add it to `MIGRATED_TO_DRIFT`. Run the guard: exit 1.
- [ ] **`account_state_queries.drift`.**
  - `accountStateRow`, `upsertAccountState`, `clearAccountState`;
  - `accountTransitionRow`, `upsertAccountTransition`, `clearAccountTransition`.
- [ ] **Accessor.** Call the generated methods; the companions stay.
- [ ] **Verify.** Build, run the guard, and run `flutter test test/core/auth test/features/account test/architecture`.
- [ ] **Commit:** `refactor(auth): AccountStore reads and writes through .drift (ADR-020 P7)`.

### Task 2: the four plain adapters

- [ ] **Red.** Take the delete batch, deck, review log and account settings adapters off the guard scope and add them to `MIGRATED_TO_DRIFT`. Run the guard: exit 1.
- [ ] **Queries:**
  - `sync_delete_batch_queries`: row, upsert, delete, acknowledge.
  - `sync_deck_queries`: the same four.
  - `sync_review_log_queries`: row, insert-or-ignore.
  - The account settings adapter includes `settings_queries.drift`.
- [ ] **Allowlist.** Add entries for the deck statements that read or write any state:
  - `syncDeckRow`, which replaces `deck_sync_adapter.dart#readRow`;
  - `deleteSyncedDeck`;
  - `acknowledgeDeck`.
- [ ] **Verify.** Build, run the guard, and run `flutter test test/core/sync test/architecture`.
- [ ] **Commit:** `refactor(sync): the plain adapters read and write through .drift (ADR-020 P7)`.

### Task 3: the card, tag and schedule adapters

- [ ] **Red.** Run the guard as in Task 2.
- [ ] **`sync_card_queries`:**
  - row and tag ids;
  - upsert;
  - delete links, link-or-ignore;
  - delete, acknowledge;
  - `ensureSchedules`.
- [ ] **`sync_tag_queries`:**
  - row;
  - `tagClashOf(:name_folded, :id)`;
  - upsert;
  - the cards of a tag, link-or-ignore;
  - delete, acknowledge.
- [ ] **`sync_card_schedule_queries`:** row, upsert, and the root scheduler of a card.
- [ ] **Allowlist.** Move these entries: card `readRow`, `ensureSchedules` and `_rootSchedulerType`. Add entries for the card delete and acknowledge.
- [ ] **Verify** as in Task 2.
- [ ] **Commit:** `refactor(sync): card, tag and schedule adapters through .drift (ADR-020 P7)`.

### Task 4: `SyncStore`

- [ ] **Red.** Run the guard as above.
- [ ] **`sync_outbox_queries`:**
  - **State:** `syncStateValue`, `putSyncState`, `deleteSyncState`.
  - **Outbox:** `pendingOutbox(:types, $rank, :limit)`, `outboxEntryOf`, `outboxOp`, `deleteOutboxOp`, `countFailedAttempt(:op_ids)`, `enqueueOutbox`.
  - **Rejections:** `upsertRejection`, `deleteRejection`, `allRejections`, `deleteAllRejections`.
  - **Status:** `syncStatusRow`, with the keys written as literals that a test pins to `sync_keys.dart`. `outboxCount`.
  - **Seeds:** the seven `seed…Outbox` statements.
- [ ] **Accessor.**
  - `pendingBatch` builds `$rank` with `caseMatch`.
  - `watchStatus` maps the generated row.
  - `outboxChanges` is `tableChanges`.
  - `applyingRemote` keeps its `PRAGMA`.
- [ ] **Allowlist.** Add entries for the deck and card seeds, which queue rows in any state as `seedOutboxSql` did.
- [ ] **Verify.** Build, run the guard, and run `flutter test test/core test/features/account test/architecture`.
- [ ] **Commit:** `refactor(sync): SyncStore reads and writes through .drift (ADR-020 P7)`.

### Task 5: measure, WBS, gate

- [ ] **Measure.** Run `sync_bulk_test.dart` 3 times and compare with the baseline. The numbers go in the PR.
- [ ] **WBS.** Mark FE-D24 done and run `tools/docs/generate.py`.
- [ ] **Gate.** Run `dod_check.sh`.
- [ ] **Review.** Run the final review, then open the PR stacked on P6 (#186).
