# MemoX V8 — Trash backend design (package 7)

Status: approved 2026-09-25 (design section by section in conversation, then this
written spec); amended 2026-09-26 with the clarifications of its plan
([`2026-09-26-trash-backend.md`](../plans/2026-09-26-trash-backend.md)) · Path:
architectural

## 1. Intent

Build BE-B1 of [`docs/wbs_BE.md`](../../wbs_BE.md): the store side of the Trash,
UC-TRASH-001, with BR-TRASH-001…BR-TRASH-012 where the store enforces them, and the
schema migration v2 → v3 that the Trash needs.

The package writes `domain/`, `data/` and `di/` of a new `lib/features/trash/`, changes
the delete paths of `deck` and `card` and gives both a restore and an Undo. Screen 06
(Trash) of the kit, the delete dialogs' copy and the Undo snackbars belong to FE-B1 in
[`docs/wbs_FE.md`](../../wbs_FE.md).

Success means:

- deleting a deck or cards moves them to the Trash in one transaction: one batch per
  item root, nothing deleted for good, every active surface without them at once;
- a restore asks for a target, decided by the rules of a move, and writes nothing on a
  refusal; an Undo puts the item back where it was or refuses with a typed reason;
- a purge, by hand or after 30 × 24 hours, deletes exactly the rows of a batch and
  what cascades from them, or skips that batch whole;
- FE-B1 builds every state of screen 06 and the Undo of the delete flows from use
  cases alone;
- a v1 or v2 database upgrades to v3 with every value intact, and all 40 invariants,
  the integrity check and the foreign key check hold after it;
- a test fails when a statement that reads `card` or `deck` loses its tombstone
  filter (BR-TRASH-002);
- every store rule above has a test that fails when it breaks; the phased gate of the
  root `README.md` passes after every task, and `CI gate` is green before the merge;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-25)

- `master` is at `5f9c309`: package 6 (#64) merged; CI runs the gate on every pull
  request.
- **UC-TRASH-001** is `ready` with `code: []`. BR-TRASH-001…BR-TRASH-012 are
  `active`. The table `delete_batches` is specified in
  [`features/trash/data.md`](../../features/trash/data.md); invariants 33–37 of
  [`schema.md`](../../shared/data/schema.md) wait for it, and
  `test/support/invariant_queries.dart` skips them (`_waitingForDeleteBatches`).
- **Deleting today.** `DeckRepositoryImpl.deleteDeck` and
  `CardRepositoryImpl.deleteCards` delete for good, by cascade (BR-DECK-022). The
  columns `deck.delete_batch_id` and `card.delete_batch_id` exist without a foreign
  key, and every active read already filters `delete_batch_id IS NULL`. No code
  writes the column; 16 test files fake a tombstone by writing it directly.
- **The rules** the store owns:
  - a delete is a soft delete in one transaction, one batch per item root, a batch
    per card when several are deleted at once (BR-TRASH-001);
  - a deck takes its **active** descendants with it in the same batch; an older
    tombstone inside keeps its own batch; the batch lives on the row, never inferred
    from the parent (BR-TRASH-003);
  - content, `card_schedule`, `review_log`, tag links and ids stay until the purge;
    every `in_progress` session touching the item closes in the same transaction as
    `invalidated`/`content_deleted` (BR-TRASH-004);
  - a sub-deck that loses its last active direct child becomes `unset`; a root stays
    `deck` (BR-TRASH-005);
  - a restore asks for a target and follows exactly the rules of a move; a root deck
    goes back to the top level only; a refusal is typed and writes nothing
    (BR-TRASH-006);
  - a restore revives exactly the rows of its batch and rewrites `root_id` for the
    whole subtree, tombstones inside included (BR-TRASH-007);
  - an Undo reverses one batch to where it was, under the same conditions, or
    refuses with a typed reason (BR-TRASH-008);
  - retention is 30 × 24 hours from `deleted_at`, the boundary included; the
    auto-purge runs at start, on resume and when the Trash opens, is idempotent,
    and takes its time from an injected clock (BR-TRASH-009);
  - a purge deletes exactly the rows of a batch and their cascade; a batch with a
    descendant of a batch not purged with it, or still active, is skipped whole;
    any error rolls everything back (BR-TRASH-010);
  - every statement that reads `card` or `deck` carries the tombstone filter, or is
    on an allowlist with a reason that can be checked (BR-TRASH-002);
  - content in the Trash is never logged (BR-TRASH-012).
- **The code this builds on.**
  - `DeckEntity.checkMove` (deck domain) holds the rules of a deck move: own subtree,
    content type, depth, scheduler and generation. The repository adds
    `rootCannotMove` and `sameParent`.
  - `CardEntity.checkMove` (card domain) holds the rules of a card move, with
    `sameDeck` inside it.
  - `DeckDao.moveSubtree` rewrites `root_id`, `depth` and `updated_at` for the whole
    subtree, tombstones included; `subtreeHeight` counts them;
    `nextSiblingPosition` is `MAX + 1` over every child, tombstones included;
    `reorderDeck` renumbers the active siblings only.
  - A reset or a scheduler change (`SrsDao.replaceTreeSchedules`) rewrites the
    schedule of every card of the tree, tombstones included; invariant 9 checks every
    row.
  - A guess question's options come from the session's queue and from the learned,
    active cards of the root's tree (package 2b spec, §8.2); the session view reads
    them joined to `card` without a tombstone filter.
  - drift 2.35's `Migrator.alterTable` turns foreign keys off when they are on, sets
    `legacy_alter_table` around its rename, and re-creates the table's indexes and
    triggers. The app turns foreign keys on in `beforeOpen`, after the migration.
  - The rejection messages of `deck` and `card` switch exhaustively over their enums
    in `presentation/widgets/support/`.
- **Screen 06** of the kit has 15 states (all, cards, decks, selection,
  restoreTarget, noTarget, restored, undoRefused, purgeConfirm, purged,
  youngerInside, empty, loading, error, actions). An entry shows its name, its kind,
  when it was deleted, the time left, where it was ("Was in …", information only),
  and for a deck how many decks and cards it holds; entries are newest first.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | BE-B1: the store side of UC-TRASH-001, the migration v2 → v3, and the deck and card delete paths. No screen and no copy beyond D16 | Owner's standing order; WBS |
| D2 | Approach | The owner of an item deletes, restores and undoes it: `deck` for decks, `card` for cards. `trash` lists the batches, purges them, and dispatches the Trash screen's restore to `deck` or `card` by kind | Owner, 2026-09-25 (approach A of three) |
| D3 | Import map | `'trash': {'deck', 'card'}`. `deck` and `card` gain no dependency | ADR-011 D2 |
| D4 | Contract documents | BR-DECK-022, BR-DECK-023, UC-DECK-002 (the delete flow and its postcondition) and UC-CARD-001 A2 change to say what a delete now does. The shared UI rule "Delete is permanent in V8.0" of the screen handoff stays for FE-B1 | Owner, 2026-09-25 |
| D5 | Schema | v3 as `trash/data.md` states: `delete_batches` and its index; `delete_batch_id` becomes a foreign key to it, `ON DELETE CASCADE`, on `deck` and `card`, each with its index. The key needs a table rebuild, done by drift's `TableMigration` | `trash/data.md`; flutter-drift `references/migrations.md` |
| D6 | Batches | One batch per item root. Deleting n cards writes n batches with one `deleted_at`. `deleted_at` lives on the batch only: marking a row changes no content and no `updated_at` | BR-TRASH-001, BR-TRASH-004; `trash/data.md` |
| D7 | Sessions closed | An `in_progress` session closes as `invalidated`/`content_deleted` when its deck is marked, when its queue holds a marked card, **or when a stored guess question uses a marked card as an option**. The options read gains the tombstone filter too | BR-TRASH-004, BR-TRASH-002; Owner, 2026-09-25 |
| D8 | One set of rules | A deck restore and a deck Undo call `DeckEntity.checkMove`. `CardEntity.checkMove` splits into `checkTarget` and the move-only `sameDeck`; a card restore and a card Undo call `checkTarget`. `sameParent` and `sameDeck` stay a move's: the place an item was is a valid target. The target queries of a move gain a restore mode rather than a second query | BR-TRASH-006; Owner, 2026-09-25 |
| D9 | Positions | A restore puts a deck last among its new siblings, as a move does, and sets a card's `deck_id` and `updated_at`, as a move does. An Undo keeps a deck's `sibling_position` and a card's `updated_at`: no new sibling, move or restore takes that place, since the next position counts tombstones. A reorder renumbers the active siblings from 0 (§2), so an Undo after one can share a position with a sibling; the tie falls to `id`, and the next reorder renumbers them apart | BR-TRASH-007, BR-TRASH-008 |
| D10 | Tombstones travel | A tombstone inside a subtree moves with it: `moveSubtree` rewrites its `root_id` and `depth`, and a subtree's height counts it, as they do today. A move can never push a tombstone past depth 10 | BR-TRASH-007, BR-DECK-001, BR-DECK-018 |
| D11 | Reset and the Trash | Unchanged: a reset or a scheduler change rewrites the schedules of the tree's tombstones too, so a restored card is at its root's generation and invariant 9 holds for every row | BR-SRS-023, invariant 9 |
| D12 | Purge | One transaction a call. A manual purge takes the chosen batches and every expired one; the auto-purge takes the expired ones. Batches go in ascending `deleted_at`, in passes, until a pass purges nothing; a batch whose subtree still holds a row of another batch or an active row is skipped whole and reported with the batches that block it | BR-TRASH-009, BR-TRASH-010; Owner, 2026-09-25 |
| D13 | Time | Retention is `Duration(hours: 720)`; a batch is expired when `deleted_at <= now − retention`. The trash repository takes `now` as a required argument; the use cases read it from `DayClock`. No read purges: the UI calls `PurgeExpiredTrash` at start, on resume, when the Trash opens and when it regains focus | BR-TRASH-009; study session spec §7.5 (`abandonStaleSessions`) |
| D14 | The shape check | `test/architecture/tombstone_filter_test.dart` reads the sources as text and fails on a statement that reads `card` or `deck` without `delete_batch_id`, unless an allowlist in the test names it with a reason | BR-TRASH-002; Owner, 2026-09-25 |
| D15 | Until FE-B1 | On the development branch, the delete dialogs keep their "permanent" copy, nothing calls the auto-purge, and nothing restores. No flag guards this: FE-B1 follows BE-B1 in the WBS | Owner, 2026-09-25 |
| D16 | New rejection values | `DeckRejection` gains `targetNotFound`, `targetInTrash`, `rootRestoresToTopLevel` and `subDeckNeedsParent`; `CardRejection` gains `targetInTrash`. Each gets its case in the rejection message widget and its string in `app_en.arb` and `app_vi.arb`, the minimum that keeps the exhaustive switches compiling; FE-B1 aligns the copy with the kit | ADR-011 D6; `CLAUDE.md` (no `default` clause) |
| D17 | Branch and PR | Branch `claude/be-trash` from `master` at `5f9c309`. When the gate is green and the final review is clean, the package is opened as a PR and squash-merged once `CI gate` is green | Owner's standing choice |

## 4. Structure

```
lib/core/database/
├── tables/trash.drift                  new: delete_batches, its index
├── tables/deck.drift, tables/card.drift
│                                       delete_batch_id → delete_batches, one index each
├── queries/trash_queries.drift         new: statements deck and card share (§6.3)
├── queries/deck_queries.drift          deckMoveTargets gains its restore mode (§7.4)
├── queries/card_queries.drift          cardMoveTargets takes a root and an excluded deck
└── app_database.dart                   schemaVersion 3, the step from2To3 (§5.2)

lib/features/deck/
├── domain/failures/                    four new values (D16)
├── domain/models/deck_restore_targets_model.dart
│                                       new: DeckRestoreTargets (sealed)
├── domain/repositories/deck_repository.dart
│                                       deleteDeck returns the batch id; restoreDecks,
│                                       undoDeckDeletion, watchRestoreTargets
├── domain/usecases/                    DeleteDeck returns the batch id;
│                                       new UndoDeckDeletionUseCase
└── data/                               the soft delete, restore and Undo (§6, §7)

lib/features/card/
├── domain/entities/card_entity.dart    checkTarget split out of checkMove (D8)
├── domain/failures/                    targetInTrash (D16)
├── domain/repositories/card_repository.dart
│                                       deleteCards returns the batch ids; restoreCards,
│                                       undoCardDeletion, watchRestoreTargets
├── domain/usecases/                    DeleteCards returns the batch ids;
│                                       new UndoCardDeletionUseCase
└── data/                               the soft delete, restore and Undo (§6, §7)

lib/features/trash/                     new
├── domain/
│   ├── entities/trash_entry_entity.dart     TrashEntry, TrashDeckEntry,
│   │                                        TrashCardEntry, trashRetention
│   ├── models/purge_report_model.dart       PurgeReport
│   ├── repositories/trash_repository.dart   watchEntries, purge, purgeExpired
│   └── usecases/                            the seven of §10
├── data/
│   ├── datasources/trash_dao.dart           entries, the deck forest, purge
│   ├── mappers/trash_mapper.dart            rows → entries, origin paths
│   └── repositories/trash_repository_impl.dart
└── di/trash_repository_provider.dart        trashRepositoryProvider
```

Presentation changes only where the contract forces them: the return types of
`DeckActionsController.deleteDeck` and `CardActionsController.deleteCards`, and the new
rejection cases with their ARB strings (D16). The use case providers belong to FE-B1's
`presentation/providers/`, as for every use case so far.

## 5. Schema v3 and the migration

### 5.1 Tables

```sql
-- lib/core/database/tables/trash.drift
CREATE TABLE delete_batches (
  id TEXT NOT NULL PRIMARY KEY,
  item_type TEXT NOT NULL CHECK (item_type IN ('card', 'deck')),
  root_item_id TEXT NOT NULL,   -- no FK: two target tables (trash/data.md)
  deleted_at DATETIME NOT NULL,
  owner_id TEXT                 -- NULL = local profile
) AS DeleteBatch;              -- every row class is its singular noun

CREATE INDEX idx_delete_batches_deleted ON delete_batches (deleted_at, id);
```

`deck.delete_batch_id` and `card.delete_batch_id` become
`TEXT REFERENCES delete_batches (id) ON DELETE CASCADE`, with
`idx_deck_delete_batch ON deck (delete_batch_id)` and
`idx_card_delete_batch ON card (delete_batch_id)`.

### 5.2 The step v2 → v3

```dart
from2To3: (m, schema) async {
  // Package 7: the Trash (trash spec §5).
  await m.createTable(schema.deleteBatches);
  await m.createIndex(schema.idxDeleteBatchesDeleted);
  await m.alterTable(TableMigration(schema.deck));
  await m.alterTable(TableMigration(schema.card));
  await m.createIndex(schema.idxDeckDeleteBatch);
  await m.createIndex(schema.idxCardDeleteBatch);
},
```

- The step rewrites no value. No v1 or v2 build writes `delete_batch_id`, so every
  row reaches v3 with it null, and no row can orphan the new key.
- `alterTable` copies every column by name, drops the old table and renames the new
  one. Foreign keys are off while the migration runs: the app turns them on in
  `beforeOpen`, after it, so dropping the old `deck` or `card` cascades nothing. Its
  `legacy_alter_table` keeps the rename from re-parsing `review_log_no_delete`, whose
  body names `card`. It re-creates the table's own indexes
  (`idx_deck_parent_position`, `idx_deck_root_position`, `idx_card_deck_created`).
- The workflow of `flutter-drift/references/migrations.md` applies: snapshot
  `drift_schema_v3.json`, regenerate `schema_versions.dart` and
  `test/drift/generated/`, commit all three.
- The plan runs this step in the prototype before it writes a line of the plan.

### 5.3 What the migration tests prove

- v1 → v3 and v2 → v3 end at the schema of v3; a new database has the same schema.
- A v2 database with rows keeps every row of every table with its values: the v1
  rows of today's test, which v2 keeps, plus the v2 columns and a guess question.
- After either upgrade: every invariant of `schema.md`, 33–37 included,
  `PRAGMA integrity_check` is `ok`, and `PRAGMA foreign_key_check` returns no row.
- After the upgrade, the cascades still hold: deleting a card through a batch
  removes its `card_schedule`, `review_log` and `card_tags` rows, and nothing else.

### 5.4 The tests that fake tombstones

The 16 test files that write `delete_batch_id` directly use a helper of
`test/support/` that inserts the batch first, since the key refuses an unknown id.
`_waitingForDeleteBatches` goes, so every test that checks the invariants checks
33–37 too.

## 6. Moving to the Trash

### 6.1 A deck: `deleteDeck({deckId, now})`

In one transaction:

1. The deck must be active; otherwise `notFound`, and nothing is written.
2. A batch: a new id, `item_type = 'deck'`, `root_item_id = deckId`,
   `deleted_at = now`.
3. The deck and every **active** deck under it (cycle-safe recursive `UNION` over
   `parent_id`, never capped) take the batch; then every active card of those decks.
   A tombstone inside keeps its older batch (BR-TRASH-003).
4. A parent that is a sub-deck recomputes its `content_type` from its active children:
   no child left, `unset` (BR-TRASH-005). A root stays `deck`.
5. The sessions of §6.3 close.
6. The batch id is returned.

### 6.2 Cards: `deleteCards({cardIds, now})`

In one transaction: every card must be active, otherwise `notFound` and nothing is
written, as today. Each card gets its own batch, all with one `deleted_at`, and takes
it. A deck left with no active card becomes `unset` (the helper of today). The
sessions of §6.3 close. The batch ids are returned in the order of `cardIds`; an empty
set writes nothing and returns none.

### 6.3 The sessions it closes

`trash_queries.drift` holds one statement for both features: every `in_progress`
session whose deck took the batch, whose root took it (a session keeps its root when
its deck moves to another tree, IT-CONT-006), whose queue holds a card that took it,
or whose stored guess options use such a card, becomes `invalidated` with
`end_reason = 'content_deleted'` and `ended_at = now` (D7). The reason is stored, never
inferred (BR-TRASH-004).

### 6.4 What it leaves alone

Content, `card_schedule`, `review_log`, `card_tags`, every id, `updated_at` of a marked
row, `deck.parent_id`, `card.deck_id` and `sibling_position`. The old place of an item
is its row as it stands: an Undo reads it there (§7.3).

## 7. Restore and Undo

### 7.1 Decks: `restoreDecks({batchIds, parentId, now})`

One transaction. Every check runs before any write; one refusal refuses all.

- Each batch must exist and hold a deck; otherwise `notFound` (E6).
- `parentId` null (the top level): every item root must be a root deck, otherwise
  `subDeckNeedsParent`. Each goes back last among the roots.
- `parentId` set: every item root must be a sub-deck, otherwise
  `rootRestoresToTopLevel`. The target must be an active deck: `targetInTrash` when it
  is a tombstone, `targetNotFound` when it is gone. Each item passes
  `DeckEntity.checkMove` against the target, with its own root's scheduler and
  generation, its subtree's height (tombstones inside count, D10) and the target's
  ancestors (BR-TRASH-006).
- Writes, for each item in the order of `batchIds`:
  1. the rows of its batch, decks and cards, lose their mark;
  2. a sub-deck moves under the target by `moveSubtree`, last among its siblings,
     `root_id` and `depth` rewritten for the whole subtree, tombstones inside
     included (BR-TRASH-007), from its row read again: an item restored before it
     may have carried it along (D10); a root deck takes the next position among the
     roots;
  3. an `unset` target becomes `deck`;
  4. the batch row is deleted, after the marks are gone: the key would otherwise
     cascade.

### 7.2 Cards: `restoreCards({batchIds, deckId, now})`

One transaction, every check first. Each batch must exist and hold a card
(`notFound`). The target must be an active deck (`targetInTrash`,
`targetNotFound`). Each card passes `CardEntity.checkTarget`: not a root
(`targetIsRoot`), holding no deck (`targetHoldsDecks`), in the card's root
(`crossRootMove`), the card's root being its deck's `root_id`, tombstone or not.
Writes: the mark goes, `deck_id` and `updated_at` change as in a move, an `unset`
target becomes `card`, the batch row goes.

### 7.3 Undo: `undoDeckDeletion({batchId, now})`, `undoCardDeletion({batchId, now})`

The target is where the item was, read from its row: a root deck's top level, a
sub-deck's `parent_id`, a card's `deck_id`. The checks are §7.1's and §7.2's, against
that place, so a refusal is typed: `targetInTrash` when the old parent is in the Trash
too (the kit's `undoRefused`), `notADeckContainer` or `targetHoldsDecks` when it holds
the other kind now (`depthExceeded` cannot happen: the subtree's height counts its
tombstones, D10). The writes are §7.1's and §7.2's but keep a deck's
`sibling_position` and a card's `updated_at` (D9). The store sets no time limit: the
snackbar decides how long an Undo is offered, and offers it for a single item only
(BR-TRASH-008, "Enforced by: store + UI").

### 7.4 Targets: `watchRestoreTargets(batchIds)`

- **Decks.** `deckMoveTargets` gains a restore mode: the moving deck is the item root
  of a batch, a tombstone, and its current parent is a candidate like any other. For
  several batches the lists intersect. The result is `DeckRestoreTargets`:
  `DeckRestoreTopLevel` when every item is a root deck (the one target, which the user
  still confirms), otherwise `DeckRestoreUnder(decks)`, empty when no deck fits all of
  them (E1) or when roots and sub-decks are mixed.
- **Cards.** `cardMoveTargets` takes a root and an excluded deck: a move passes its
  source's root and the source, a restore the cards' root and no exclusion. Cards of
  several roots have no common target: an empty list.

Both are `watch()` streams, so a target that goes away while the picker is open leaves
it (E2), and the write refuses it anyway.

## 8. Purge

`purge({batchIds, now})` and `purgeExpired({now})`, one transaction a call (D12):

1. The set: for `purgeExpired`, every batch with `deleted_at <= now − 720 h`, the
   boundary included; for `purge`, the chosen batches plus every expired one.
   A chosen id that no longer exists is reported as missing (E6).
2. Passes in ascending `deleted_at`, then `id`, until a pass purges nothing. A
   tombstone inside is always older than its ancestor (invariant 36), so an inner
   batch goes first.
3. A deck batch is blocked while its subtree (every deck under its decks, and their
   cards) still holds a row that is active or belongs to another batch. It is skipped
   whole (BR-TRASH-010). A card batch is never blocked.
4. Purging a batch is `DELETE FROM delete_batches WHERE id = ?`: the key deletes its
   decks and cards, and their cascades delete `card_schedule`, `review_log`,
   `study_queue_items`, `study_guess_options`, `card_tags` and the sessions of its
   decks.
5. The result is a `PurgeReport`: `purged`, `blocked` (each skipped batch with the
   batches that still have rows in it, an empty set meaning an active row, which
   invariants 33–34 forbid) and `missing`.

Any error rolls the call back whole. By invariant 36 the auto-purge is never blocked;
a manual purge is, when a deck holds an older entry the user did not choose. The kit's
`youngerInside` names that entry "deleted later", the reverse of what invariant 36
allows; FE-B1 records the deviation.

## 9. The Trash read model

`watchEntries()` emits a `List<TrashEntry>`, newest first (`deleted_at` descending,
then `id`), once when watched and again after every write to `delete_batches`, `deck`
or `card` (`tableChanges`). Each emission reads in one transaction:

- the deck batches joined to their item root, with the number of the batch's decks
  other than the root and of its cards;
- the card batches joined to their card;
- the whole deck forest (`id`, `parent_id`, `name`), tombstones included, from which
  Dart builds each entry's `origin`: the decks the item was in, root first (a card's
  deck included; a root deck's origin is empty).

```dart
sealed class TrashEntry {
  String get batchId;
  DateTime get deletedAt;
  DateTime get expiresAt;          // deletedAt + trashRetention
  List<DeckPathEntry> get origin;  // information only (BR-TRASH-012)
}
final class TrashDeckEntry extends TrashEntry { deckId, name, isRoot,
                                                subDeckCount, cardCount }
final class TrashCardEntry extends TrashEntry { cardId, front, back }
```

A batch whose item root is missing (invariant 37) is not listed. Reading writes
nothing and purges nothing (D13).

## 10. The contract for the UI (FE-B1)

| Use case | Returns | Where | Rules |
|---|---|---|---|
| `DeleteDeckUseCase(deckId)` | `Outcome<String, DeckRejection>`, the batch id | deck | BR-TRASH-001, 003–005 |
| `DeleteCardsUseCase(cardIds)` | `Outcome<List<String>, CardRejection>`, the batch ids | card | BR-TRASH-001, 004, 005 |
| `UndoDeckDeletionUseCase(batchId)` | `Outcome<void, DeckRejection>` | deck | BR-TRASH-008 |
| `UndoCardDeletionUseCase(batchId)` | `Outcome<void, CardRejection>` | card | BR-TRASH-008 |
| `WatchTrashUseCase()` | `Stream<List<TrashEntry>>` | trash | UC-TRASH-001 steps 3–4 |
| `WatchDeckRestoreTargetsUseCase(batchIds)` | `Stream<DeckRestoreTargets>` | trash | BR-TRASH-006 |
| `WatchCardRestoreTargetsUseCase(batchIds)` | `Stream<List<CardMoveTarget>>` | trash | BR-TRASH-006 |
| `RestoreDecksFromTrashUseCase(batchIds, parentId)` | `Outcome<void, DeckRejection>` | trash | BR-TRASH-006, 007 |
| `RestoreCardsFromTrashUseCase(batchIds, deckId)` | `Outcome<void, CardRejection>` | trash | BR-TRASH-006, 007 |
| `PurgeTrashUseCase(batchIds)` | `PurgeReport` | trash | BR-TRASH-010 |
| `PurgeExpiredTrashUseCase()` | `PurgeReport` | trash | BR-TRASH-009 |

- The screen splits entries by kind; a selection never mixes them (BR-TRASH-011, UI).
- The UI offers Undo after deleting one item, not several (BR-TRASH-008).
- The UI calls `PurgeExpiredTrashUseCase` at start, on resume, when the Trash opens
  and when it regains focus (A4); the list then drops the purged rows in place.
- A database error leaves as the `Failure` of `mapDatabaseError` after the rollback
  (E5).

## 11. The shape check (BR-TRASH-002)

`test/architecture/tombstone_filter_test.dart`, text-based like
`test/architecture/boundary_rules.dart`:

- **What it reads.** Every statement of `lib/**/*.drift`; in `lib/**/*.dart`,
  generated files aside, the SQL passed to `customSelect`, `customUpdate`,
  `customInsert` and `customStatement`, and drift's query builder on `_db.card` or
  `_db.deck`.
- **The rule.** A statement that reads `card` or `deck` (`FROM`, `JOIN`, `UPDATE`
  or `DELETE FROM` followed by the bare table name, so `card_schedule` and
  `card_tags` do not count) names `delete_batch_id` for each of its aliases
  (`c.delete_batch_id` for `card c`; any `delete_batch_id` for a bare name), or
  `deleteBatchId` in the query builder. Otherwise the allowlist of the test names it,
  as `file#member` or `file#query`, with its reason.
- **The allowlist** holds the statements that read tombstones on purpose: a reset's
  rewrite of the whole tree (D11), `moveSubtree` and `subtreeHeight` (D10),
  `nextSiblingPosition` (D9), the trash reads and the purge. The plan fixes the list
  from the prototype's run over the real code; an unfiltered statement it finds that
  reads active content gets the filter, not an entry.
- **Its own tests.** A statement without the filter fails, one with it passes, an
  allowlisted one passes, and an allowlist entry that names no statement fails. The
  plan removes the filter from a real query once and watches the test fail.

## 12. Tests

Every test names the rule or the use case it pins.

Domain (pure):

- `CardEntity.checkTarget`: root, deck holder, cross root; `checkMove` keeps
  `sameDeck` (D8);
- `trashRetention` is 720 hours; `expiresAt`; a batch at exactly 720 hours is expired
  (BR-TRASH-009).

Data (a test database):

- a deck delete marks the deck and its active subtree with one batch and one
  `deleted_at`, keeps an older tombstone's batch, changes no content and no
  `updated_at` (BR-TRASH-001, 003, 004);
- deleting three cards writes three batches; each card is its own item root
  (BR-TRASH-001);
- a sub-deck left with no active child becomes `unset`; a root stays `deck`
  (BR-TRASH-005);
- sessions: the deck's own, a parent's whose queue holds a marked card, and one
  whose stored guess options use a marked card close as `content_deleted`; a session
  that touches nothing marked stays open (BR-TRASH-004, D7);
- every active read the package touches leaves the tombstones out; the options of a
  guess question leave out a card in the Trash (BR-TRASH-002);
- restore: each refusal of `checkMove` and `checkTarget` against a real tree; a root
  only to the top level and a sub-deck never there; a refusal writes nothing; a
  restore revives exactly its batch's rows, leaves an older tombstone inside in the
  Trash with its `root_id` rewritten, and moves a deck across roots of the same
  scheduler and generation (BR-TRASH-006, 007, UC-TRASH-001 A5);
- Undo: back to the old parent and position; refused, typed, when the parent is in
  the Trash, holds the other kind now or would exceed the depth (BR-TRASH-008);
- targets: the old parent is a candidate; the lists follow a write; several batches
  intersect; roots give `DeckRestoreTopLevel` (BR-TRASH-006);
- purge: the cascade removes exactly the batch's rows and their dependants; a deck
  holding a batch that is not chosen is skipped whole and reported with it; a missing
  id is reported; an error half-way rolls everything back (BR-TRASH-010);
- expiry: 720 hours is expired, 720 hours minus a millisecond is not; a second run
  purges nothing (BR-TRASH-009);
- the Trash list: newest first, counts of the batch only, origins through decks in
  the Trash too, and it follows a delete, a restore and a purge;
- the migration (§5.3) and the shape check (§11);
- the plan's Review Focus.

BR-TRASH-012's store half has no test of its own: the new paths log nothing, `data/`
has no logger, and the final review checks that none comes in.

## 13. Documents

- **BR-DECK-022:** a deck delete moves the deck with its active descendants to the
  Trash in one batch; only a purge deletes for good, by cascade (D4). **BR-DECK-023:**
  the confirmation counts what goes to the Trash.
- **UC-DECK-002:** the delete flow and its postcondition say "to the Trash", with
  Undo; **UC-CARD-001 A2:** a card goes to the Trash, one batch per card, with Undo for
  a single card. Their `rules:` gain the BR-TRASH rules they now follow.
- **`docs/features/trash/README.md`:** the scope (the Trash is built), `code:`, the
  stale note that the repository has no `lib/`, and "Không thuộc phạm vi".
  **UC-TRASH-001:** `code:`.
- **`docs/features/deck/ui.md`:** the node that says "Xoá cứng cả cây".
- **`docs/shared/data/schema.md`:** invariants 33–37 in force; the notes of the two
  `delete_batch_id` columns; the foreign key section (the purge's cascade); tombstones
  travel with a subtree (D10).
- **`docs/wbs_BE.md`:** BE-B1 done; the order moves on; the update log.
  **`docs/wbs_FE.md`:** FE-B1 no longer waits; notes for FE-B1: the Undo snackbars,
  where to call the auto-purge, the kit's `youngerInside` wording, the copy of D16.
- **`docs/_generated/`:** regenerated.
- The shared UI rule "Delete is permanent in V8.0" stays for FE-B1 (D4).

## 14. Out of scope

- FE-B1: screen 06, the delete dialogs' copy, the Undo snackbars and their time,
  calling the auto-purge, and the strong confirmation of a purge (BR-TRASH-011).
- Import and export (BE-B3) do not exist yet; their duplicate check and export must
  leave tombstones out, and the shape check will see their statements.
- Tag Management (BE-B2), whose counts of a tag's cards the shape check will see too.
- A sync of batches between devices (`owner_id` stays null).

## 15. Risks and rollback

- **The rebuild.** A shipped migration never changes, and this one rebuilds the two
  tables every other table points at. The prototype runs it first; the tests upgrade
  real rows from v1 and v2 and run the integrity and foreign key checks. drift's
  `alterTable` was read, not assumed (§2).
- **The heuristic.** A text scan can miss a statement built at run time or flag a
  harmless one. Its own tests and the mutation of §11 bound the first; the allowlist,
  with reasons, handles the second.
- **More sessions close.** D7 closes a session whose stored guess options use a card
  that goes to the Trash; the session is resumable from nothing, as for any other
  `content_deleted` (BR-STUDY-012).
- **Until FE-B1** (D15), a deleted item sits in the Trash with no way back and no
  auto-purge. Development builds only.
- **Rollback.** Before a release, reverting the package's commits removes it and
  schema v3 with it. After a release, v3 is permanent and a fix moves forward in v4.
