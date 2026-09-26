# MemoX V8 Trash Backend Implementation Plan (package 7)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-B1 of [`docs/wbs_BE.md`](../../wbs_BE.md), the store side of the
Trash (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) with the schema migration v2 → v3
it needs, as domain, data and di code, so FE-B1 can build screen 06 and the Undo of
the delete flows on use cases alone.

**Architecture:** Schema v3 adds `delete_batches` and turns `deck.delete_batch_id`
and `card.delete_batch_id` into keys to it, `ON DELETE CASCADE`, by rebuilding both
tables through drift's `TableMigration`. The owner of an item deletes, restores and
undoes it: a delete in `deck` or `card` writes one batch per item root and marks
rows with it, a restore and an Undo run the rules of a move (`DeckEntity.checkMove`,
`CardEntity.checkTarget`), and the move-target queries gain a restore mode. A new
`trash` feature lists the batches with where each item was and purges them in
passes by `deleted_at`, skipping whole a batch whose decks still hold rows of
another. A text check over `lib/` fails on a statement that reads `card` or `deck`
without the tombstone filter, unless its allowlist names it with a reason.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35 and `drift_dev` (`schema dump`, `schema steps`,
`schema generate`). No dependency is added.

**Spec:**
[`docs/superpowers/specs/2026-09-25-trash-backend-design.md`](../specs/2026-09-25-trash-backend-design.md),
approved 2026-09-25 and amended on this branch, in the commit after the one that
adds this plan, with Clarifications 1, 3, 5, 9, 10 and 11. Business rules:
`docs/features/trash/rules/` (BR-TRASH-001…BR-TRASH-012); use case:
`docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md`; data
model: [`features/trash/data.md`](../../features/trash/data.md) and
[`shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-trash` holds the spec (`3b3473f`), its approval
(`3f5a358`), this plan and the spec's amendment, on `master` at `5f9c309` (#64). The
plan runs on that branch, from the amendment; the gate passes there with 1450 tests.
Generated code is not committed: in a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`
first (root `README.md`, "Commands").

**How this plan was checked:** the migration was written and run first, in a scratch
copy of the repository; then every code block below, task by task, test first. Each
task's tests failed as its "Expected" line says, then passed, and after every task
the gate passed. Each rule the tests pin was also broken on purpose in the scratch
copy, one at a time: the v2 → v3 step without its two rebuilds; a deck delete that
walks into an older tombstone's subtree; a parent sub-deck left as it was; the root
clause and the guess-option clause of the sessions a delete closes, and a card
delete that closes none; the guess options without their filter; one batch for every
card of a delete; a deck emptied by a card delete left as it was; a restore that
unmarks only the batch's decks; a deck restore without the rules of a move; an Undo
that puts a deck last; a restore that moves the row it read before its writes; a
card restore that keeps `updated_at` and a card Undo that stamps it; a card restore
into another root; a reset that skips the tree's tombstones (D11); the old parent
left out of the restore targets; targets for cards of two roots; a purge of one
pass; a purge that takes a blocked batch; expiry without its boundary; and the
entries without their batch-id tie-break. That is 23 breaks: Task 1 makes the first
one itself, in its Step 7, and Task 4 makes one more there, on the shape check.
Every break failed a test. This document was then applied, step by step as written,
onto a clean checkout of the spec's amendment: each task's files matched the scratch
commit's, no other file moved, and the outputs and counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only, but for what the contract forces: the return types of
  `DeckActionsController.deleteDeck` and `CardActionsController.deleteCards`, and
  the five new refusals' cases in the rejection message widgets with their strings
  in `app_en.arb` and `app_vi.arb` (spec §4, D16). No screen, no provider for a new
  use case, no other copy: the delete dialogs keep their "permanent" wording,
  nothing calls the auto-purge and nothing restores until FE-B1 (D15).
- The import map gains `'trash': {'deck', 'card'}`; `deck` and `card` gain no
  dependency (D3; ADR-011 D2).
- Schema v3 is exactly `features/trash/data.md`: `delete_batches` with
  `idx_delete_batches_deleted (deleted_at, id)`; `delete_batch_id` on `deck` and
  `card` becomes `REFERENCES delete_batches (id) ON DELETE CASCADE`, with
  `idx_deck_delete_batch` and `idx_card_delete_batch`. The step v2 → v3 rebuilds
  `deck` and `card` through `TableMigration` and rewrites no value (D5, §5.2).
  `drift_schemas/drift_schema_v3.json`, `lib/core/database/schema_versions.dart` and
  `test/drift/generated/` are written by `drift_dev` and committed; `*.g.dart` are
  not.
- One batch per item root: deleting n cards writes n batches with one
  `deleted_at`. `deleted_at` lives on the batch only; marking a row changes no
  content, no `updated_at` and no place (D6, §6.4).
- Every write is one transaction and runs every check before its first write: a
  refusal writes nothing, and a restore of several batches is all or none (§6, §7).
- A deck restore and a deck Undo call `DeckEntity.checkMove`; a card restore and a
  card Undo call `CardEntity.checkTarget`. `sameParent` and `sameDeck` stay a
  move's (D8). An Undo keeps a deck's `sibling_position` and a card's `updated_at`
  (D9); a tombstone inside a subtree moves with it (D10).
- A purge is one transaction a call, in passes by ascending `deleted_at`, then `id`,
  until a pass purges nothing; a batch whose decks still hold a row of another batch
  or an active row is skipped whole and reported (D12). Retention is
  `Duration(hours: 720)`; a batch is expired when `deleted_at <= now − 720 h`. The
  trash repository takes `now` as a required argument, the use cases read it from
  `DayClock`, and no read purges (D13).
- Every statement of `lib/` that reads `card` or `deck` names `delete_batch_id`, or
  the allowlist of `test/architecture/tombstone_filter_test.dart` names it with its
  reason (BR-TRASH-002; D14).
- Nothing on these paths logs, and `data/` has no logger: content in the Trash is
  never logged (BR-TRASH-012).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing `call`
  (AD-12).
- The tests of the delete, restore, Undo and purge paths run
  `expectStudyInvariants` after every scenario, which runs every invariant query of
  `schema.md` in scope, 33–37 included from Task 1 on.
- After every task the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It runs the host
  suite with `TZ=UTC` and `--exclude-tags golden`: the goldens are compared in CI and
  regenerated only in the Linux container. Its generated-code check asks every
  source under `lib/` to be in git, so each task stages its files, runs the gate,
  then commits.
- The guard fails a hand-written file at 400 logical lines
  (`common.no_large_source_file`; the memox-v8 profile fails on warnings). The
  largest files of the package end near it: `card_batch_writes_test.dart`,
  `card_repository_impl.dart` and `deck_repository_impl.dart` (Clarification 7).
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a rule or use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- The contract documents change only as D4 says: BR-DECK-022 (renamed with its new
  title), BR-DECK-023, UC-DECK-002 (the delete flow and its postcondition),
  UC-CARD-001 A2, the trash README and UC-TRASH-001's `code:`. The shared UI rule
  "Delete is permanent in V8.0" of the screen handoff stays for FE-B1.
- Code, identifiers, test names and commit messages are in English; `docs/` keeps
  its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan and showed
where its text needed a ruling. Each is decided here and implemented as described;
say so if one is wrong.

1. **The batch row class is `DeleteBatch`** (Task 1; spec §5.1). The approved spec
   wrote `AS DeleteBatchRow`. Every table's row class is its singular noun (`Deck`,
   `CardSchedule`, `ReviewLog`, `StudyGuessOption`, `Tag`); only `card`'s is
   `CardRow`, because `Card` is a Flutter widget. `delete_batches` follows the rule.
2. **Task 1's order** (spec §5.2). `schema steps` makes `from2To3` a required
   argument of the generated `stepByStep`, so the bumped database no longer compiles
   until the step exists: the analyzer names the missing step (Step 5), the step is
   written (Step 6), and a scratch edit that drops the two rebuilds shows the
   migration tests catching a step that skips them (Step 7). The version bump and
   the step cannot be separated by a failing migration run, as package 2b's first
   migration was.
3. **The sessions a delete closes** (Tasks 2 and 3; spec §6.3, D7). The statement
   closes every `in_progress` session whose deck took the batch, whose queue holds a
   card that took it, or whose stored guess options use such a card, and also one
   whose `root_id` took it: a session keeps its root when its deck moves to another
   tree (IT-CONT-006), and once that root is in the Trash nothing could reach the
   session again.
4. **A session in the Trash, on the screen and on Continue** (Tasks 2 and 3;
   UC-STUDY-001 A5, E5; IT-CONT-007). The session screen's read leaves out a session
   whose deck or root is in the Trash, so it reads `notFound`, as for a session that
   is gone; Continue and leave meet a session the delete closed, and return
   `sessionClosed`. The settle path for a queue that lost cards (study session spec
   D12) stays, for a v2 database upgraded with such a session: its tests now delete
   the card for good through `hardDeleteCards` of `test/support/study_fixtures.dart`,
   since the app itself no longer does.
5. **The shape check** (Task 4; spec §11, D14). It lives in three files, as the
   import map's does: `tombstone_rules.dart` (the scanner), `tombstone_rules_test.dart`
   (the scanner's own tests on planted sources) and `tombstone_filter_test.dart` (the
   run over `lib/` with the allowlist). It is stricter than §11's statement-level
   rule: each alias needs its own filter, so `FROM card c JOIN deck d` needs
   `c.delete_batch_id` and `d.delete_batch_id`; a bare table name needs any
   `delete_batch_id`. Two references that share an alias share its filter:
   `deckMoveTargets` names both the moving deck's root and the targets' roots `r`,
   and filters the second only, since in its restore mode the moving deck's root
   may be in the Trash on purpose (Task 7). A query-builder write addressed by
   `.id.equals(` or `.id.isIn(` touches the rows it names and is not a read.
6. **Filters, not entries** (Task 4; spec §11). The run over `lib/` found statements
   that read active content without the filter; each gets it: the ancestors of a
   deck (`DeckDao.ancestorIds`, `deckAndAncestors`), the roots of the children and
   the targets of a move (`deckLevelOfChildren`, `deckMoveTargets`), the root of a
   card and a tree's schedules (`SrsDao.rootOfCard`, `_ofTree`), and the study reads
   of a queue, a round and a session (`pendingMeanings`, `builtRows`, `boardPairs`,
   `cardRow` of the view and of the session, `hasHint`). Their inputs are active by
   construction today; the filter keeps them so. The allowlist ends with eleven
   entries, each with its reason, all reading tombstones on purpose: the Trash's
   own reads and the purge's blockers, `review_log_no_delete`, D9's
   `nextSiblingPosition`, D10's `subtreeHeight` and `moveSubtree`, D11's
   `replaceTreeSchedules`, a restore's reads of an item's root (`rowInAnyState`,
   `rootIdsOf`) and the search's two statements, filtered by its one predicate
   `_live` (Search spec D8).
7. **The deck repository splits** (Task 5). With restore and Undo,
   `deck_repository_impl.dart` would reach 433 logical lines. The row mapping moves
   to `data/mappers/deck_mapper.dart`, and the tree writes a move and a restore share
   (the move rules against a target, the subtree's move, the content type that
   follows) to `data/datasources/deck_tree_data_source.dart`. The move keeps its
   behaviour; its tests pass unchanged.
8. **What a restore of a root, and an Undo of a sub-deck, write** (Task 5; spec
   §7.1, D9). A root deck comes back last among the roots. An Undo of a sub-deck
   goes back through `moveSubtree`, the write of a move, so its subtree's
   `updated_at` is stamped; D9 keeps its `sibling_position`, which is what it
   promises. An Undo of a root deck only unmarks its batch.
9. **An Undo never exceeds the depth** (Task 5; spec §7.3, §12). A tombstone keeps
   its place and a subtree's height counts it (D10), so no later move can leave the
   old parent too deep for the deleted subtree: `depthExceeded` is unreachable for an
   Undo, and Task 5 tests it for a restore under another deck.
10. **A restore reads each item again before it moves it** (Task 5; spec §7.1,
    D10). Reading the prototype's code before writing this plan found this one: when
    a restore takes a batch and an older batch inside it, the outer first, the
    outer's move carries the inner item with its subtree (D10), and moving the inner
    item by the row read before the writes left it one level too deep. Each item is
    read again right before its move; Task 5 pins it (Review Focus 2).
11. **An Undo after a reorder** (Task 5; spec D9, §2). D9 keeps a deck's
    `sibling_position` because a new sibling, a move and a restore all take the next
    position over every child, tombstones included. A reorder renumbers the active
    siblings from 0 (spec §2), so an Undo after the old siblings were reordered can
    share a position with one of them: the tie falls to `id`
    (`ORDER BY sibling_position, id`), no invariant asks for distinct positions, and
    the next reorder renumbers them apart. The plan keeps D9's write: the snackbar
    offers the Undo for seconds, and keeping the tombstones' positions free would
    change `reorderDeck`, a write outside this package.
12. **`cardMoveTargets` takes a root or a source** (Task 7; spec §7.4). A move passes
    its source deck and no root, and the query takes the source's root; a restore
    passes the cards' root and no source. drift orders the generated arguments by
    their first use: `cardMoveTargets(String? sourceDeckId, String? rootId)`, and
    `deckMoveTargets(String deckId, bool restoring, int maxDepth)`.
13. **Generated names and orders** (Tasks 2, 5, 6). drift writes
    `closeSessionsTouchingBatch(DateTime? now, String batchId)`, in the order the
    statement uses them. `flutter analyze` does not regenerate
    `lib/l10n/generated/`: after an ARB edit, `flutter gen-l10n` runs first.
14. **Who owns `trash_queries.drift`** (Tasks 2 and 8). The statements `deck` and
    `card` share, and the Trash's own, live in one query file; the impact map's
    `database_query_features` names its owners, `["card", "deck"]` from Task 2 and
    `["card", "deck", "trash"]` from Task 8, since the CI tooling tests ask every
    query file for one.
15. **Out of scope, unchanged.** `verify_invariants.py`, which the gate does not
    run, reports invariants 38–40 without a violation case before and after this
    package; 33–37 pass it. It belongs with package 2b's invariants, not here.
16. **The plan's date.** The plan is written on 2026-09-26, the day after the spec;
    its file name and the WBS log line carry that date.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person,
each pinned by a test in the task that owns the code:

1. **A sub-deck whose root went to the Trash after it**: it is offered, and comes
   back, under a deck of another active root of its scheduler and generation — Task
   5, "a sub-deck whose root went to the Trash after it comes back under a deck of
   another root of its scheduler and generation", and Task 7, "a sub-deck whose root
   went to the Trash after it may go back into the decks of another root of its
   scheduler and generation".
2. **A batch restored together with an older batch inside it, the outer first**:
   each comes back under the chosen deck at its own depth, its subtree with it — Task
   5, "a batch and an older one inside it come back together, the outer first, each
   under the chosen deck at its own depth" (Clarification 10).
3. **A reset or a scheduler change while cards sit in the Trash**: a card that
   comes back runs its root's generation and scheduler, from the start — Task 6, "a
   card in the Trash through a reset that changed the scheduler comes back at its
   root's generation, under the new scheduler (trash spec D11)".
4. **An Undo pressed twice, or after the item came back from the Trash**: it is
   `notFound` and writes nothing — Task 5 and Task 6, "a second Undo, or one after
   the deck (the card) came back from the Trash, is notFound and writes nothing".
5. **A select-all delete of a large deck**: 1,000 cards go in one call, as 1,000
   batches at one time, the deck left `unset`; 720 hours later one auto-purge takes
   them all — Task 3, "a selection of 1,000 cards goes in one call", and Task 8,
   "1,000 cards deleted in one call expire together, and one auto-purge takes every
   batch".

## File Structure

```
lib/core/database/
├── tables/trash.drift                    delete_batches and its index (1)
├── tables/deck.drift, tables/card.drift  delete_batch_id → delete_batches, an index each (1)
├── app_database.dart                     schemaVersion 3, from2To3 (1); trash_queries (2)
├── schema_versions.dart                  generated (schema steps), committed (1)
└── queries/
    ├── trash_queries.drift               insertDeleteBatch, closeSessionsTouchingBatch (2);
    │                                     deckIsInTrash (6); the entries, the forest and
    │                                     a purge's blockers (8)
    ├── deck_queries.drift                filters (4); deckMoveTargets' restore mode (7)
    └── card_queries.drift                cardMoveTargets by root or source (7)
drift_schemas/drift_schema_v3.json        generated (schema dump), committed (1)
test/drift/generated/                     schema.dart, schema_v3.dart: generated (schema
                                          generate), committed (1)

lib/features/deck/
├── domain/failures/deck_failure.dart     four refusals (5)
├── domain/models/deck_restore_targets_model.dart
│                                         DeckRestoreTargets, TopLevel, Under (7)
├── domain/repositories/deck_repository.dart
│                                         deleteDeck (2); restoreDecks, undoDeckDeletion (5);
│                                         watchRestoreTargets (7)
├── domain/usecases/                      delete_deck (2); undo_deck_deletion (5)
├── data/datasources/deck_dao.dart        the delete (2); filters (4); the restore's reads
│                                         and writes (5, 6); the targets (7)
├── data/datasources/deck_tree_data_source.dart
│                                         what a move and a restore share (5)
├── data/mappers/deck_mapper.dart         rows → entities and views (5)
├── data/repositories/deck_repository_impl.dart   (2, 5, 7)
└── presentation/                         deleteDeck's type (2); four messages (5)

lib/features/card/
├── domain/entities/card_entity.dart      checkTarget (6)
├── domain/failures/card_failure.dart     targetInTrash (6)
├── domain/repositories/card_repository.dart
│                                         deleteCards (3); restoreCards, undoCardDeletion (6);
│                                         watchRestoreTargets (7)
├── domain/usecases/                      delete_cards (3); undo_card_deletion (6)
├── data/datasources/card_dao.dart        (3, 6, 7); card_detail_dao.dart (7)
├── data/repositories/card_repository_impl.dart   (3, 6, 7)
└── presentation/                         deleteCards' type (3); one message (6)

lib/features/study/                       the Trash left out of the options and the session
                                          screen (2), and of the queue, round and session
                                          reads (4)
lib/features/srs/data/datasources/srs_dao.dart   filters (4)
lib/l10n/app_en.arb, app_vi.arb           five refusals (5, 6)

lib/features/trash/                       new (8)
├── domain/entities/trash_entry_entity.dart   trashRetention, trashCutoff, TrashEntry,
│                                             TrashDeckEntry, TrashCardEntry
├── domain/models/purge_report_model.dart     PurgeReport
├── domain/repositories/trash_repository.dart watchEntries, purge, purgeExpired
├── domain/usecases/                          the seven of spec §10
├── data/datasources/trash_dao.dart
├── data/mappers/trash_mapper.dart            trashEntriesOf
├── data/repositories/trash_repository_impl.dart
└── di/trash_repository_provider.dart         trashRepositoryProvider

test/support/trash_fixtures.dart          insertDeleteBatch, trashDeckRows, trashCardRow (1)
test/support/study_fixtures.dart          hardDeleteCards (3)
test/architecture/tombstone_rules.dart, tombstone_rules_test.dart,
  tombstone_filter_test.dart              the shape check (4); its allowlist grows (5, 6, 8)
test/architecture/boundary_rules.dart     'trash': {'deck', 'card'} (8)
```

Other changed files: `schema.md` and `features/trash/data.md` (Task 1), BR-DECK-022,
BR-DECK-023, UC-DECK-002, `deck/ui.md` (Task 2), UC-CARD-001 (Task 3), the impact
map `verification_impact_map.json` (Tasks 2 and 8), the trash README, UC-TRASH-001,
`wbs_BE.md` and `wbs_FE.md` (Task 9), and `docs/_generated/` where a task's tests
name a new id.

---


### Task 1: Schema v3, the v2 → v3 step, and tombstones through a batch

**Files:**
- Create: `lib/core/database/tables/trash.drift`
- Modify: `docs/features/trash/data.md`, `docs/shared/data/schema.md`, `lib/core/database/app_database.dart`, `lib/core/database/tables/card.drift`, `lib/core/database/tables/deck.drift`
- Test (create): `test/support/trash_fixtures.dart`
- Test (modify): `test/database/invariants_test.dart`, `test/drift/migration_test.dart`, `test/features/card/data/card_batch_writes_test.dart`, `test/features/card/data/card_detail_read_test.dart`, `test/features/deck/data/deck_level_read_test.dart`, `test/features/deck/data/deck_navigation_read_test.dart`, `test/features/deck/data/deck_repository_impl_edit_test.dart`, `test/features/progress/data/watch_deck_progress_test.dart`, `test/features/progress/data/watch_progress_test.dart`, `test/features/search/data/search_cards_test.dart`, `test/features/search/data/search_decks_test.dart`, `test/features/search/data/search_pages_test.dart`, `test/features/settings/data/root_study_options_repository_test.dart`, `test/features/srs/data/record_turn_test.dart`, `test/features/srs/data/reset_learning_test.dart`, `test/features/srs/data/schedule_repository_impl_test.dart`, `test/features/study/data/open_learning_session_test.dart`, `test/features/study/data/watch_study_home_test.dart`, `test/support/card_fixtures.dart`, `test/support/invariant_queries.dart`
- Generate with `drift_dev`, and commit: `drift_schemas/drift_schema_v3.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema.dart`, `test/drift/generated/schema_v3.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed)

**Interfaces:**
- Consumes: `AppDatabase` and its `stepByStep` migration (package 2b);
  `drift_schemas/drift_schema_v1.json` and `drift_schema_v2.json`; the invariant
  parser of `test/support/invariant_queries.dart`; `drift_dev`.
- Produces:
  - The table `delete_batches` (row class `DeleteBatch`, `db.deleteBatches`) with
    `idx_delete_batches_deleted`; `deck.delete_batch_id` and `card.delete_batch_id`
    as keys to it, `ON DELETE CASCADE`, with `idx_deck_delete_batch` and
    `idx_card_delete_batch`.
  - `AppDatabase.schemaVersion == 3`, upgrading through
    `stepByStep(from1To2: …, from2To3: …)`.
  - `test/drift/generated/schema.dart` and `schema_v3.dart`, for `SchemaVerifier`.
  - In `test/support/trash_fixtures.dart`:
    `Future<void> insertDeleteBatch(AppDatabase db, String id, {required String itemType, required String rootItemId, int deletedAt = 0})`,
    `Future<void> trashDeckRows(AppDatabase db, String deckId, {String? batchId, int deletedAt = 0})`
    and
    `Future<void> trashCardRow(AppDatabase db, String cardId, {String? batchId, int deletedAt = 0})`;
    `insertCard(deleteBatchId: …)` inserts its batch first.
  - Invariants 33–37 in force, run by `invariants_test.dart` and
    `expectStudyInvariants`.

Spec §5, D5; Clarifications 1 and 2. The tests come first: the migration test
upgrades real rows from v1 and v2, and the 16 test files that marked rows by hand
insert their batch first, which v2 cannot hold. Then the schema, the generated
files, the step the generated code asks for, and a scratch edit proving the tests
catch a step that skips the rebuild.

- [ ] **Step 1: Write the failing tests**

In `test/support/card_fixtures.dart`:

Replace

```dart
import 'package:memox/features/card/domain/repositories/card_repository.dart';

```

with

```dart
import 'package:memox/features/card/domain/repositories/card_repository.dart';

import 'trash_fixtures.dart';

```

Replace

```dart
  final created = createdAt ?? DateTime(2026, 9, 1);
  await db.customUpdate(
```

with

```dart
  final created = createdAt ?? DateTime(2026, 9, 1);
  if (deleteBatchId != null) {
    await insertDeleteBatch(
      db,
      deleteBatchId,
      itemType: 'card',
      rootItemId: id,
    );
  }
  await db.customUpdate(
```

In `test/support/invariant_queries.dart`:

Replace

```dart
);

/// Invariants 33-37 need `delete_batches`, which does not exist yet
/// (foundation plan, Clarification 2; the Trash, BE-B1).
const _waitingForDeleteBatches = {33, 34, 35, 36, 37};

```

with

```dart
);

```

Replace

```dart
    final number = int.parse(headers[i].group(1)!);
    if (_waitingForDeleteBatches.contains(number)) continue;
    final end = i + 1 < headers.length ? headers[i + 1].start : sql.length;
```

with

```dart
    final number = int.parse(headers[i].group(1)!);
    final end = i + 1 < headers.length ? headers[i + 1].start : sql.length;
```

Replace

```dart
  32: "a turn carries the direction of its queue row (BR-MODE-016)",
  38: "hint_shown appears only on fill (BR-STUDY-028)",
```

with

```dart
  32: "a turn carries the direction of its queue row (BR-MODE-016)",
  33: "an active card never sits in a deck in the Trash (BR-TRASH-001, BR-TRASH-003)",
  34: "an active deck never sits under a deck in the Trash (BR-TRASH-001, BR-TRASH-003)",
  35: "a batch keeps at least one row (BR-TRASH-010)",
  36: "a tombstone is never deleted after its deleted ancestor (BR-TRASH-003)",
  37: "a batch's item root carries that batch (BR-TRASH-001)",
  38: "hint_shown appears only on fill (BR-STUDY-028)",
```

Create `test/support/trash_fixtures.dart`:

```dart
import 'package:memox/core/database/app_database.dart';

/// A row of `delete_batches` alone, for a test that marks rows by hand: the
/// key on `delete_batch_id` refuses an unknown batch (trash spec §5.4). A
/// second call with the same id changes nothing.
Future<void> insertDeleteBatch(
  AppDatabase db,
  String id, {
  required String itemType,
  required String rootItemId,
  int deletedAt = 0,
}) => db.customStatement(
  'INSERT OR IGNORE INTO delete_batches '
  '(id, item_type, root_item_id, deleted_at) VALUES (?, ?, ?, ?)',
  [id, itemType, rootItemId, deletedAt],
);

/// [deckId] in the Trash with every active deck and card under it, as one
/// batch, the way a delete leaves them (BR-TRASH-001, BR-TRASH-003), for a
/// test that needs tombstones without the delete path.
Future<void> trashDeckRows(
  AppDatabase db,
  String deckId, {
  String? batchId,
  int deletedAt = 0,
}) async {
  final batch = batchId ?? 'trash-$deckId';
  await insertDeleteBatch(
    db,
    batch,
    itemType: 'deck',
    rootItemId: deckId,
    deletedAt: deletedAt,
  );
  await db.customStatement(
    'WITH RECURSIVE subtree(id) AS (SELECT ? UNION '
    'SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id) '
    'UPDATE deck SET delete_batch_id = ? '
    'WHERE id IN (SELECT id FROM subtree) AND delete_batch_id IS NULL',
    [deckId, batch],
  );
  await db.customStatement(
    'UPDATE card SET delete_batch_id = ? WHERE delete_batch_id IS NULL '
    'AND deck_id IN (SELECT id FROM deck WHERE delete_batch_id = ?)',
    [batch, batch],
  );
}

/// [cardId] in the Trash as a batch of its own (BR-TRASH-001).
Future<void> trashCardRow(
  AppDatabase db,
  String cardId, {
  String? batchId,
  int deletedAt = 0,
}) async {
  final batch = batchId ?? 'trash-$cardId';
  await insertDeleteBatch(
    db,
    batch,
    itemType: 'card',
    rootItemId: cardId,
    deletedAt: deletedAt,
  );
  await db.customStatement('UPDATE card SET delete_batch_id = ? WHERE id = ?', [
    batch,
    cardId,
  ]);
}
```

In `test/database/invariants_test.dart`:

Replace

```dart

/// Rows that satisfy every invariant in scope: three trees (eight_box, sm2,
/// empty), learned and new cards, three sessions (completed, open,
/// invalidated) with queue rows in five modes, a guess question with its five
/// options, and review turns of all three kinds.
const _seed = <String>[
```

with

```dart

/// Rows that satisfy every invariant: three trees (eight_box, sm2, empty),
/// learned and new cards, three sessions (completed, open, invalidated) with
/// queue rows in five modes, a guess question with its five options, review
/// turns of all three kinds, and the Trash: a sub-deck in it with a card, an
/// older card batch inside that sub-deck, and a card batch of its own.
const _seed = <String>[
```

Replace

```dart
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
  // The settings row exists from the first open (BR-SETTINGS-001).
```

with

```dart
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't1')",
  // The Trash (BR-TRASH-001, BR-TRASH-003): c8 went first, then the deck A4
  // with c7, then c9 on its own.
  "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b0', 'card', 'c8', 50), ('b1', 'deck', 'A4', 60), ('b2', 'card', 'c9', 70)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, delete_batch_id, sibling_position, created_at, updated_at) VALUES ('A4', 'A4', 'A', 'A', 2, 'card', 'b1', 3, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, delete_batch_id, created_at, updated_at) VALUES ('c7', 'A4', 'f', 'b', 'b1', 0, 0), ('c8', 'A4', 'f', 'b', 'b0', 0, 0), ('c9', 'A1', 'f', 'b', 'b2', 0, 0)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) VALUES ('c7', 'eight_box', 1, 1, 1), ('c8', 'eight_box', 1, 1, 1), ('c9', 'eight_box', 1, 1, 1)",
  // The settings row exists from the first open (BR-SETTINGS-001).
```

Replace

```dart
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'meaning_to_korean', 'remembered', 130, 3, 4)",
  ],
};

```

with

```dart
    "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('bad', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'meaning_to_korean', 'remembered', 130, 3, 4)",
  ],
  33: ["UPDATE card SET delete_batch_id = NULL WHERE id = 'c7'"],
  34: [
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A4', 'A', 3, 'unset', 0, 0, 0)",
  ],
  35: [
    "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('bad', 'card', 'c1', 80)",
  ],
  36: [
    "INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) VALUES ('b3', 'deck', 'bad', 90)",
    "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, delete_batch_id, sibling_position, created_at, updated_at) VALUES ('bad', 'x', 'A4', 'A', 3, 'unset', 'b3', 0, 0, 0)",
  ],
  37: ["UPDATE delete_batches SET root_item_id = 'c1' WHERE id = 'b2'"],
};

```

Replace

```dart

  test('schema.md states invariants 1 to 32 and 38 to 40', () {
    expect(
      invariantQueries.keys,
      unorderedEquals([for (var n = 1; n <= 32; n++) n, 38, 39, 40]),
    );
```

with

```dart

  test('schema.md states invariants 1 to 40', () {
    expect(
      invariantQueries.keys,
      unorderedEquals([for (var n = 1; n <= 40; n++) n]),
    );
```

In `test/drift/migration_test.dart`:

Replace

```dart
// their values intact (spec §5.3; .claude/skills/flutter-drift/references/
// migrations.md).

```

with

```dart
// their values intact (spec §5.3; .claude/skills/flutter-drift/references/
// migrations.md). v3 is the Trash's (trash spec §5.3).

```

Replace

```dart

/// The tables of v1, whose rows the upgrade must keep as they are.
```

with

```dart

/// What a v2 database adds to those rows: a fill hint shown, the meaning
/// slots of a match board, and the five options of the guess question in
/// progress.
const _v2Rows = <String>[
  "UPDATE study_queue_items SET hint_shown = 1 WHERE session_id = 'open' AND mode = 'fill'",
  "UPDATE study_queue_items SET meaning_slot = position WHERE session_id = 'learned' AND mode = 'match'",
  "INSERT INTO study_guess_options (session_id, round, card_id, slot, option_card_id) VALUES ('open', 1, 'k4', 0, 'k6'), ('open', 1, 'k4', 1, 'k4'), ('open', 1, 'k4', 2, 'k3'), ('open', 1, 'k4', 3, 'k5'), ('open', 1, 'k4', 4, 'k1')",
];

/// The tables of v1, whose rows the upgrade must keep as they are.
```

Replace

```dart

/// [rows] as text without v2's columns, in a stable order.
```

with

```dart

/// The tables of v2: v1's and the options of a guess question.
const _v2Tables = [..._v1Tables, 'study_guess_options'];

/// [rows] as text, in a stable order.
List<String> _values(Iterable<Map<String, Object?>> rows) =>
    [for (final row in rows) _canonical(row)]..sort();

/// [rows] as text without v2's columns, in a stable order.
```

Replace

```dart

  test('v1 upgrades to the schema of v2', () async {
    final db = AppDatabase(await verifier.startAt(1));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });
```

with

```dart

  test('v1 upgrades to the schema of v3', () async {
    final db = AppDatabase(await verifier.startAt(1));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });

  test('v2 upgrades to the schema of v3', () async {
    final db = AppDatabase(await verifier.startAt(2));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 3);
  });
```

Replace

```dart
  test(
    'a new database has the schema of v2, the one an upgrade ends at',
    () async {
```

with

```dart
  test(
    'a new database has the schema of v3, the one an upgrade ends at',
    () async {
```

Replace

```dart
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
    },
```

with

```dart
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 3);
    },
```

Replace

```dart
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
    });
```

with

```dart
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);
    });
```

Replace

```dart
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });
}
```

with

```dart
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });

  group('a v2 database with rows', () {
    late AppDatabase db;
    late Map<String, List<String>> before;

    setUp(() async {
      final schema = await verifier.schemaAt(2);
      for (final statement in [..._v1Rows, ..._v2Rows]) {
        schema.rawDatabase.execute(statement);
      }
      before = {
        for (final table in _v2Tables)
          table: _values(schema.rawDatabase.select('SELECT * FROM $table')),
      };
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);
    });
    tearDown(() => db.close());

    Future<List<String>> ids(String sql) async => [
      for (final row in await db.customSelect(sql).get())
        '${row.data.values.single}',
    ]..sort();

    test('keeps every row of v2 with its values', () async {
      for (final table in _v2Tables) {
        final after = await db.customSelect('SELECT * FROM $table').get();
        expect(
          _values([for (final row in after) row.data]),
          before[table],
          reason: table,
        );
      }
      expect(before['study_guess_options'], hasLength(5));
      expect(await ids('SELECT id FROM delete_batches'), isEmpty);
    });

    test('still holds every invariant of schema.md', () async {
      for (final MapEntry(key: number, value: query)
          in invariantQueries.entries) {
        expect(
          await db.customSelect(query).get(),
          isEmpty,
          reason: 'invariant $number: ${invariantSummaries[number]}',
        );
      }
    });

    test('passes the integrity and foreign key checks', () async {
      final integrity = await db.customSelect('PRAGMA integrity_check').get();
      expect([for (final row in integrity) row.data.values.single], ['ok']);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });

    test('deleting a batch deletes its rows and what hangs off them, and no '
        'other row (BR-TRASH-010)', () async {
      await db.customStatement(
        'INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at) '
        "VALUES ('b1', 'card', 'k1', 0), ('b2', 'deck', 'S1', 0)",
      );
      await db.customStatement(
        "UPDATE card SET delete_batch_id = 'b1' WHERE id = 'k1'",
      );
      await db.customStatement(
        "UPDATE deck SET delete_batch_id = 'b2' WHERE id = 'S1'",
      );
      await db.customStatement(
        "UPDATE card SET delete_batch_id = 'b2' WHERE id = 'm1'",
      );

      await db.customStatement('DELETE FROM delete_batches');

      expect(await ids('SELECT id FROM deck'), ['R', 'R1', 'S']);
      expect(await ids('SELECT id FROM card'), ['k2', 'k3', 'k4', 'k5', 'k6']);
      expect(await ids('SELECT card_id FROM card_schedule'), [
        'k2',
        'k3',
        'k4',
        'k5',
        'k6',
      ]);
      expect(await ids('SELECT id FROM review_log'), [
        'l1',
        'l10',
        'l11',
        'l12',
        'l13',
        'l4',
        'l5',
        'l7',
      ]);
      expect(await ids('SELECT card_id FROM card_tags'), isEmpty);
      expect(await ids('SELECT id FROM tags'), ['t1']);
      expect(await ids('SELECT id FROM study_session'), [
        'learned',
        'open',
        'review',
        'sm2',
      ]);
      expect(
        await ids(
          "SELECT COUNT(*) FROM study_queue_items WHERE card_id IN ('k1', 'm1')",
        ),
        ['0'],
      );
      expect(await ids('SELECT option_card_id FROM study_guess_options'), [
        'k3',
        'k4',
        'k5',
        'k6',
      ]);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });
}
```

In `test/features/card/data/card_batch_writes_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    final trashedDeck = await decks.sub(root.id, 'Trashed');
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
      [trashedCard.id],
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [trashedDeck.id],
    );
    final before = await totalChanges(db);
```

with

```dart
    final trashedDeck = await decks.sub(root.id, 'Trashed');
    await trashCardRow(db, trashedCard.id);
    await trashDeckRows(db, trashedDeck.id);
    final before = await totalChanges(db);
```

Replace

```dart
      cardId = (await cards.card(trashed.id)).id;
      await db.customStatement(
```

with

```dart
      cardId = (await cards.card(trashed.id)).id;
      await insertDeleteBatch(
        db,
        'b',
        itemType: 'deck',
        rootItemId: trashed.id,
      );
      await db.customStatement(
```

In `test/features/card/data/card_detail_read_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
      final trashed = await cards.card(leaf.id);
      await db.customStatement(
        "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
        [trashed.id],
      );
      final details = <CardDetail?>[];
```

with

```dart
      final trashed = await cards.card(leaf.id);
      await trashCardRow(db, trashed.id);
      final details = <CardDetail?>[];
```

Replace

```dart
    final trashed = await decks.sub(root.id, 'Trashed');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [trashed.id],
    );
    final other = await decks.root('Twin');
```

with

```dart
    final trashed = await decks.sub(root.id, 'Trashed');
    await trashDeckRows(db, trashed.id);
    final other = await decks.root('Twin');
```

In `test/features/deck/data/deck_level_read_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [noDueGroup.id],
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'future'",
    );

```

with

```dart
    );
    await trashDeckRows(db, noDueGroup.id);
    await trashCardRow(db, 'future');

```

In `test/features/deck/data/deck_navigation_read_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart

  Future<void> trash(String deckId) => db.customStatement(
    "UPDATE deck SET delete_batch_id = 'batch' WHERE id = ?",
    [deckId],
  );

```

with

```dart

  Future<void> trash(String deckId) => trashDeckRows(db, deckId);

```

In `test/features/deck/data/deck_repository_impl_edit_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
  Future<void> insertCard(String id, String deckId, {String? batch}) async {
    await db.customStatement(
```

with

```dart
  Future<void> insertCard(String id, String deckId, {String? batch}) async {
    if (batch != null) {
      await insertDeleteBatch(db, batch, itemType: 'card', rootItemId: id);
    }
    await db.customStatement(
```

Replace

```dart
      await insertCard('gone', kept.id, batch: 'batch');
      await db.customStatement(
        "UPDATE deck SET delete_batch_id = 'batch' WHERE id = ?",
        [trashed.id],
      );

```

with

```dart
      await insertCard('gone', kept.id, batch: 'batch');
      await trashDeckRows(db, trashed.id);

```

In `test/features/progress/data/watch_deck_progress_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
      isA<Ok<void, DeckRejection>>(),
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );

    expect(await read(deleted.id), isA<ProgressDeckMissing>());
```

with

```dart
      isA<Ok<void, DeckRejection>>(),
    );
    await trashDeckRows(db, trashed.id);

    expect(await read(deleted.id), isA<ProgressDeckMissing>());
```

Replace

```dart
      box: 2,
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    await lockScheduler(db, korean.id);
```

with

```dart
      box: 2,
    );
    await trashDeckRows(db, trashed.id);
    await lockScheduler(db, korean.id);
```

In `test/features/progress/data/watch_progress_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
      box: 2,
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    await lockScheduler(db, korean.id);
```

with

```dart
      box: 2,
    );
    await trashDeckRows(db, trashed.id);
    await lockScheduler(db, korean.id);
```

In `test/features/search/data/search_cards_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    final gone = await decks.sub(koreanId, 'Gone');
    await insertCard(
      db,
      id: 'inGoneDeck',
      deckId: gone.id,
      front: 'học',
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', gone.id],
    );

```

with

```dart
    final gone = await decks.sub(koreanId, 'Gone');
    await insertCard(db, id: 'inGoneDeck', deckId: gone.id, front: 'học');
    await trashDeckRows(db, gone.id);

```

In `test/features/search/data/search_decks_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    final deleted = await decks.sub(root.id, 'Học deleted');
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    expect(
```

with

```dart
    final deleted = await decks.sub(root.id, 'Học deleted');
    await trashDeckRows(db, trashed.id);
    expect(
```

In `test/features/search/data/search_pages_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
      }
      await db.customStatement(
        'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
        ['batch', gone.id],
      );
      await insertCard(db, id: 'kept', deckId: lessonId, front: 'học b');
```

with

```dart
      }
      await trashDeckRows(db, gone.id);
      await insertCard(db, id: 'kept', deckId: lessonId, front: 'học b');
```

In `test/features/settings/data/root_study_options_repository_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart

Future<void> _moveTreeToTrash(AppDatabase db) => db.customStatement(
  "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
);

```

with

```dart

Future<void> _moveTreeToTrash(AppDatabase db) => trashDeckRows(db, 'r');

```

In `test/features/srs/data/record_turn_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
      [cardId],
    );
    final before = await totalChanges(db);
```

with

```dart
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await trashCardRow(db, cardId);
    final before = await totalChanges(db);
```

Replace

```dart
  test('a card whose deck is in the Trash is notFound (BE-C3)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = 'r-leaf'",
```

with

```dart
  test('a card whose deck is in the Trash is notFound (BE-C3)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    // The card is left active on purpose, a state invariant 33 forbids: the
    // deck alone keeps it out of the study flow.
    await insertDeleteBatch(db, 'b', itemType: 'deck', rootItemId: 'r-leaf');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = 'r-leaf'",
```

In `test/features/srs/data/reset_learning_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'r-trashed'",
    );
    for (final id in [cardId, deepCardId]) {
```

with

```dart
    );
    await trashCardRow(db, 'r-trashed');
    for (final id in [cardId, deepCardId]) {
```

Replace

```dart
    );
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
    );
    expect(
```

with

```dart
    );
    await trashDeckRows(db, 'r');
    expect(
```

In `test/features/srs/data/schedule_repository_impl_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE root_id = 'r'",
    );
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = 'r-card'",
    );
    final before = await totalChanges(db);
```

with

```dart
    await insertStudyTree(db, 'r');
    await trashDeckRows(db, 'r');
    final before = await totalChanges(db);
```

In `test/features/study/data/open_learning_session_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    await newCards(leaf.id, 'c', 1);
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [leaf.id],
    );
    await db.customStatement("UPDATE card SET delete_batch_id = 'b'");

```

with

```dart
    await newCards(leaf.id, 'c', 1);
    await trashDeckRows(db, leaf.id);

```

In `test/features/study/data/watch_study_home_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart
    await entries.openLearningSession(deckId: trashed.id);
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );

```

with

```dart
    await entries.openLearningSession(deckId: trashed.id);
    await trashDeckRows(db, trashed.id);

```

Replace

```dart
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'gone',
      deckId: lesson.id,
      back: 'gone',
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', lesson.id],
    );

```

with

```dart
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'gone', deckId: lesson.id, back: 'gone');
    await trashDeckRows(db, lesson.id);

```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/database/invariants_test.dart \
  test/drift/migration_test.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_detail_read_test.dart \
  test/features/deck/data/deck_level_read_test.dart \
  test/features/deck/data/deck_navigation_read_test.dart \
  test/features/deck/data/deck_repository_impl_edit_test.dart \
  test/features/progress/data/watch_deck_progress_test.dart \
  test/features/progress/data/watch_progress_test.dart \
  test/features/search/data/search_cards_test.dart \
  test/features/search/data/search_decks_test.dart \
  test/features/search/data/search_pages_test.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/srs/data/record_turn_test.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/study/data/open_learning_session_test.dart \
  test/features/study/data/watch_study_home_test.dart
```

Expected: `+95 -178: Some tests failed.` The 11 tests of `migration_test.dart` fail on
`Unknown schema version 3. Known are 1, 2.`: the generated helpers know v1 and v2
only. Every other failure is
`SqliteException(1): while executing, no such table: delete_batches`: the fixtures
insert the batch a tombstone now needs, and invariants 33–37 run.

- [ ] **Step 3: Add the v3 schema**

The version goes to 3 with the schema. The step
comes in Step 6, once the generated code asks for it (Clarification 2).

Create `lib/core/database/tables/trash.drift`:

```sql
-- One row per deletion a person makes (BR-TRASH-001): the rows of deck and
-- card are never copied anywhere, they take delete_batch_id. Purging is
-- deleting the batch; the keys on delete_batch_id cascade (BR-TRASH-010).
CREATE TABLE delete_batches (
  id TEXT NOT NULL PRIMARY KEY,
  -- The kind of the item root, the thing the person touched (BR-TRASH-011).
  item_type TEXT NOT NULL CHECK (item_type IN ('card', 'deck')),
  -- No FK: two target tables, and the cascade runs the other way.
  root_item_id TEXT NOT NULL,
  -- The only home of the deletion time: the 30-day retention counts from it
  -- (BR-TRASH-009).
  deleted_at DATETIME NOT NULL,
  owner_id TEXT -- NULL = local profile. Scope: sub-project sau (auth).
) AS DeleteBatch;

CREATE INDEX idx_delete_batches_deleted ON delete_batches (deleted_at, id);
```

In `lib/core/database/tables/deck.drift`:

Replace

```sql
CREATE TABLE deck (
```

with

```sql
import 'trash.drift';

CREATE TABLE deck (
```

Replace

```sql
  source_template_version INTEGER,
  -- Scope: sub-project sau (Trash). No FK yet: delete_batches does not exist.
  delete_batch_id TEXT,
  sibling_position INTEGER NOT NULL,
```

with

```sql
  source_template_version INTEGER,
  -- NULL = active; otherwise a tombstone of that batch (BR-TRASH-001,
  -- BR-TRASH-003). Purging the batch deletes the row.
  delete_batch_id TEXT REFERENCES delete_batches (id) ON DELETE CASCADE,
  sibling_position INTEGER NOT NULL,
```

Replace

```sql
CREATE INDEX idx_deck_root_position ON deck (root_id, sibling_position, id);
```

with

```sql
CREATE INDEX idx_deck_root_position ON deck (root_id, sibling_position, id);
CREATE INDEX idx_deck_delete_batch ON deck (delete_batch_id);
```

Replace the whole of `lib/core/database/tables/card.drift` with:

```sql
import 'deck.drift';
import 'trash.drift';

CREATE TABLE card (
  id TEXT NOT NULL PRIMARY KEY,
  deck_id TEXT NOT NULL REFERENCES deck (id) ON DELETE CASCADE,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  front_folded TEXT NOT NULL DEFAULT '',
  back_folded TEXT NOT NULL DEFAULT '',
  is_flagged INTEGER NOT NULL DEFAULT 0 CHECK (is_flagged IN (0, 1)),
  example TEXT,
  hint TEXT,
  pronunciation TEXT,
  -- NULL = active; otherwise a tombstone of that batch (BR-TRASH-001,
  -- BR-TRASH-003). Purging the batch deletes the row.
  delete_batch_id TEXT REFERENCES delete_batches (id) ON DELETE CASCADE,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) AS CardRow;

CREATE INDEX idx_card_deck_created ON card (deck_id, created_at, id);
CREATE INDEX idx_card_delete_batch ON card (delete_batch_id);
```

In `lib/core/database/app_database.dart`:

Replace

```dart
    'package:memox/core/database/tables/settings.drift',
    'package:memox/core/database/queries/card_queries.drift',
```

with

```dart
    'package:memox/core/database/tables/settings.drift',
    'package:memox/core/database/tables/trash.drift',
    'package:memox/core/database/queries/card_queries.drift',
```

Replace

```dart
  @override
  int get schemaVersion => 2;

```

with

```dart
  @override
  int get schemaVersion => 3;

```

- [ ] **Step 4: Generate the database code, the v3 snapshot and the migration helpers**

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

Expected: `build_runner` ends with `Built with build_runner` (it warns that
`--delete-conflicting-outputs` is ignored); `schema dump` prints
`Wrote to drift_schemas/drift_schema_v3.json`; `schema steps` prints nothing and
rewrites `lib/core/database/schema_versions.dart`; `schema generate` prints
`Wrote 4 files into test/drift/generated`, of which only `schema.dart` and the new
`schema_v3.dart` differ from before.

- [ ] **Step 5: See the generated steps ask for the v2 → v3 step**

```bash
flutter analyze lib/core/database/app_database.dart
```

Expected: `1 issue found.`, the one Step 6 answers:
`error • The named parameter 'from2To3' is required, but there's no corresponding argument. Try adding the required argument • lib/core/database/app_database.dart:34:16 • missing_required_argument`
(Clarification 2).

- [ ] **Step 6: Write the v2 → v3 step**

In `lib/core/database/app_database.dart`:

Replace

```dart
        await m.createIndex(schema.idxStudyGuessOptionsOption);
      },
    ),
    beforeOpen: (details) async {
```

with

```dart
        await m.createIndex(schema.idxStudyGuessOptionsOption);
      },
      from2To3: (m, schema) async {
        // Package 7: the Trash. delete_batch_id becomes a key to the batch,
        // which SQLite adds only by rebuilding deck and card; no row changes,
        // since no build before v3 writes the column (trash spec §5.2).
        await m.createTable(schema.deleteBatches);
        await m.createIndex(schema.idxDeleteBatchesDeleted);
        await m.alterTable(TableMigration(schema.deck));
        await m.alterTable(TableMigration(schema.card));
        await m.createIndex(schema.idxDeckDeleteBatch);
        await m.createIndex(schema.idxCardDeleteBatch);
      },
    ),
    beforeOpen: (details) async {
```

- [ ] **Step 7: Watch the migration test catch a step that skips the rebuild**

```bash
F=lib/core/database/app_database.dart
KEEP=$(mktemp) && cp "$F" "$KEEP"
sed -i '/alterTable(TableMigration(schema\.\(deck\|card\)))/d' "$F"
flutter test test/drift/migration_test.dart 2>&1 | grep -E '^[0-9:]+ \+[0-9]+' | tail -1
cp "$KEEP" "$F" && echo "app_database.dart restored"
```

Expected: `00:00 +1 -10: Some tests failed.`, then
`app_database.dart restored`. Without the rebuilds an upgrade does not end at the
schema of v3, so the two upgrade tests and the eight tests of the two groups of
rows fail; a new database, built from the schema, passes.

- [ ] **Step 8: Describe schema v3 and its invariants**

In `docs/features/trash/data.md`:

Replace

```markdown

**Phạm vi:** sub-project sau — Trash.

```

with

```markdown

**Phạm vi:** Trash (BE-B1), từ schema v3.

```

In `docs/shared/data/schema.md`:

Replace

```markdown
| `source_template_version` | INTEGER NULL | version tại thời điểm sao chép. **Phạm vi:** sub-project sau — Starter decks |
| `delete_batch_id` | TEXT NULL | NULL = deck đang active. Khác NULL = tombstone thuộc batch đó (BR-TRASH-001, BR-TRASH-003). → `delete_batches(id)` ON DELETE CASCADE. **Phạm vi:** sub-project sau — Trash |
| `sibling_position` | INTEGER NOT NULL | Thứ tự manual trong nhóm cùng `parent_id`; tie-break bằng `id` (BR-SRS-007) |
```

with

```markdown
| `source_template_version` | INTEGER NULL | version tại thời điểm sao chép. **Phạm vi:** sub-project sau — Starter decks |
| `delete_batch_id` | TEXT NULL | NULL = deck đang active. Khác NULL = tombstone thuộc batch đó (BR-TRASH-001, BR-TRASH-003). → `delete_batches(id)` ON DELETE CASCADE, từ v3, với index `idx_deck_delete_batch`: purge batch là xoá hàng (BR-TRASH-010) |
| `sibling_position` | INTEGER NOT NULL | Thứ tự manual trong nhóm cùng `parent_id`; tie-break bằng `id` (BR-SRS-007) |
```

Replace

```markdown
| `pronunciation` | TEXT NULL | Tuỳ chọn (BR-CARD-003) |
| `delete_batch_id` | TEXT NULL | NULL = card đang active. Khác NULL = tombstone thuộc batch đó (BR-TRASH-001, BR-TRASH-003). → `delete_batches(id)` ON DELETE CASCADE. **Phạm vi:** sub-project sau — Trash |
| `created_at` | DATETIME NOT NULL | UTC |
```

with

```markdown
| `pronunciation` | TEXT NULL | Tuỳ chọn (BR-CARD-003) |
| `delete_batch_id` | TEXT NULL | NULL = card đang active. Khác NULL = tombstone thuộc batch đó (BR-TRASH-001, BR-TRASH-003). → `delete_batches(id)` ON DELETE CASCADE, từ v3, với index `idx_card_delete_batch`: purge batch là xoá hàng (BR-TRASH-010) |
| `created_at` | DATETIME NOT NULL | UTC |
```

Replace

```markdown

-- Bất biến 33-37: Phạm vi sub-project sau — Trash. Giữ số và nghĩa, có hiệu
-- lực từ khi delete_batches triển khai.

```

with

```markdown

-- Bất biến 33-37: Trash, có hiệu lực từ schema v3 (BE-B1).

```

Replace

```markdown

## Chưa mô hình hoá
```

with

```markdown

Từ v3, `deck.delete_batch_id` và `card.delete_batch_id` trỏ tới
`delete_batches(id)`, `ON DELETE CASCADE`: xoá một batch xoá hàng của nó, và các
cascade sẵn có dọn study state, lịch sử, hàng đợi và quan hệ tag (BR-TRASH-010).
Cần test: xoá một batch không làm mất hàng nào của batch khác, kể cả sau khi
nâng cấp từ v1 hay v2.

## Chưa mô hình hoá
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 57 warning(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/database/invariants_test.dart \
  test/drift/migration_test.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_detail_read_test.dart \
  test/features/deck/data/deck_level_read_test.dart \
  test/features/deck/data/deck_navigation_read_test.dart \
  test/features/deck/data/deck_repository_impl_edit_test.dart \
  test/features/progress/data/watch_deck_progress_test.dart \
  test/features/progress/data/watch_progress_test.dart \
  test/features/search/data/search_cards_test.dart \
  test/features/search/data/search_decks_test.dart \
  test/features/search/data/search_pages_test.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/srs/data/record_turn_test.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/study/data/open_learning_session_test.dart \
  test/features/study/data/watch_study_home_test.dart
```

Expected: `+273: All tests passed!`

- [ ] **Step 10: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/trash/data.md \
  docs/shared/data/schema.md \
  drift_schemas/drift_schema_v3.json \
  lib/core/database/app_database.dart \
  lib/core/database/schema_versions.dart \
  lib/core/database/tables/card.drift \
  lib/core/database/tables/deck.drift \
  lib/core/database/tables/trash.drift \
  test/database/invariants_test.dart \
  test/drift/generated/schema.dart \
  test/drift/generated/schema_v3.dart \
  test/drift/migration_test.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_detail_read_test.dart \
  test/features/deck/data/deck_level_read_test.dart \
  test/features/deck/data/deck_navigation_read_test.dart \
  test/features/deck/data/deck_repository_impl_edit_test.dart \
  test/features/progress/data/watch_deck_progress_test.dart \
  test/features/progress/data/watch_progress_test.dart \
  test/features/search/data/search_cards_test.dart \
  test/features/search/data/search_decks_test.dart \
  test/features/search/data/search_pages_test.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/srs/data/record_turn_test.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/study/data/open_learning_session_test.dart \
  test/features/study/data/watch_study_home_test.dart \
  test/support/card_fixtures.dart \
  test/support/invariant_queries.dart \
  test/support/trash_fixtures.dart
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 11: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 57 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1465: All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git commit -F - <<'EOF'
feat(db): schema v3, the Trash batches, and the v2 -> v3 step

delete_batches holds one row per deletion, and deck.delete_batch_id and
card.delete_batch_id become keys to it, ON DELETE CASCADE, each with its
index. SQLite adds a key only by rebuilding the table: the v2 -> v3 step
rebuilds deck and card through drift's TableMigration and rewrites no
value, since no build before v3 writes the column. The migration tests
upgrade real rows from v1 and v2, then run every invariant, the integrity
check and the foreign key check, and delete a batch to watch its rows
and what hangs off them go. Invariants 33-37 are in force, and the tests
that marked rows by hand insert their batch first (trash spec §5).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: A deck delete moves its active subtree to the Trash as one batch

**Files:**
- Create: `lib/core/database/queries/trash_queries.drift`
- Rename, then rewrite: `docs/features/deck/rules/BR-DECK-022-xoa-deck-cascade-toan-bo-cay.md` → `docs/features/deck/rules/BR-DECK-022-xoa-deck-dua-ca-cay-vao-trash.md`
- Modify: `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`, `docs/features/deck/rules/BR-DECK-023-xoa-deck-can-xac-nhan-kem-so-luong.md`, `docs/features/deck/ui.md`, `docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md`, `docs/shared/data/schema.md`, `lib/core/database/app_database.dart`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`, `lib/features/deck/domain/usecases/delete_deck_use_case.dart`, `lib/features/deck/presentation/controllers/deck_actions_controller.dart`, `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/domain/usecases/watch_study_session_use_case.dart`
- Test (create): `test/features/deck/data/deck_trash_test.dart`
- Test (modify): `test/features/deck/data/deck_repository_impl_test.dart`, `test/features/deck/presentation/deck_action_sheet_test.dart`, `test/features/deck/presentation/deck_actions_controller_test.dart`, `test/features/study/data/round_preparation_test.dart`, `test/features/study/data/session_endings_test.dart`, `test/features/study/data/watch_session_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's schema and `trash_fixtures.dart`; `DeckDao.findRow`,
  `contentTypeFromChildren` and `setContentType`; `newId()`; `mapDatabaseError`.
- Produces:
  - `lib/core/database/queries/trash_queries.drift`, generated as
    `AppDatabase.insertDeleteBatch(String id, String itemType, String rootItemId, DateTime deletedAt)`
    and `AppDatabase.closeSessionsTouchingBatch(DateTime? now, String batchId)`.
  - In `DeckDao`: `Future<void> insertBatch(String batchId, String id, DateTime now)`,
    `Future<void> markSubtree(String id, String batchId)` and
    `Future<void> closeSessionsTouching(String batchId, DateTime now)`; the hard
    delete goes.
  - `DeckRepository.deleteDeck({required String deckId, DateTime? now})` returns
    `Future<Outcome<String, DeckRejection>>`, the batch id;
    `DeleteDeckUseCase.call({required String deckId})` and
    `DeckActionsController.deleteDeck({required String deckId})` return the same.
  - The session screen's reads leave the Trash out: the options of a guess question
    and the session row (`StudyViewDao.guessOptions`, `watchSessionRow`).
  - The impact map names the query file's owners: `"trash_queries": ["card", "deck"]`.

Spec §6.1, §6.3, §6.4, D6, D7; Clarifications 3, 4, 13 and 14. A deck delete
marks its active subtree with one batch in one transaction and closes the sessions
the batch touches. Four older tests change with it: two count active decks, since a
deleted deck's row stays, and IT-CONT-007's Continue now meets a closed session.

- [ ] **Step 1: Write the failing tests**

In `test/features/deck/data/deck_repository_impl_test.dart`:

Replace

```dart
        deckId: 'missing',
      )) as Rejected<void, DeckRejection>).reason,
      DeckRejection.notFound,
```

with

```dart
        deckId: 'missing',
      )) as Rejected<String, DeckRejection>).reason,
      DeckRejection.notFound,
```

Create `test/features/deck/data/deck_trash_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-DECK-002 and BR-DECK-022: a deck delete moves the deck and its active
// subtree to the Trash as one batch (BR-TRASH-001, BR-TRASH-003 to
// BR-TRASH-005; trash spec §6.1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    entries = studyEntryRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> delete(String deckId) async => ((await decks.deleteDeck(
    deckId: deckId,
  )) as Ok<String, DeckRejection>).value;

  /// Each row of [table] by id: its batch, null while it is active.
  Future<Map<String, String?>> marksOf(String table) async => {
    for (final row
        in await db
            .customSelect('SELECT id, delete_batch_id FROM $table')
            .get())
      row.read<String>('id'): row.read<String?>('delete_batch_id'),
  };

  /// Each row of [table], every column but `delete_batch_id`.
  Future<List<Map<String, Object?>>> contentOf(String table) async => [
    for (final row
        in await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
      {...row.data}..remove('delete_batch_id'),
  ];

  test('a deck goes to the Trash with every active deck and card under it, '
      'as one batch of the deck at one time, and the batch comes back '
      '(BR-TRASH-001, BR-DECK-022)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final food = await decks.sub(words.id, 'Food');
    final grammar = await decks.sub(root.id, 'Grammar');
    await insertCard(db, id: 'f1', deckId: food.id);
    await insertCard(db, id: 'f2', deckId: food.id);
    await insertCard(db, id: 'g1', deckId: grammar.id);

    final batchId = await delete(words.id);

    expect(await marksOf('deck'), {
      root.id: null,
      words.id: batchId,
      food.id: batchId,
      grammar.id: null,
    });
    expect(await marksOf('card'), {'f1': batchId, 'f2': batchId, 'g1': null});
    final batch = await db
        .customSelect(
          'SELECT item_type, root_item_id, deleted_at FROM delete_batches'
          ' WHERE id = ?',
          variables: [Variable(batchId)],
        )
        .getSingle();
    expect(batch.read<String>('item_type'), 'deck');
    expect(batch.read<String>('root_item_id'), words.id);
    expect(batch.read<DateTime>('deleted_at'), clock);
  });

  test(
    'marking changes no content, no updated_at and no place: parents, '
    'decks, positions and schedules stay as they were (trash spec §6.4)',
    () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      await insertCard(
        db,
        id: 'f1',
        deckId: food.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
      await lockScheduler(db, root.id);
      final decksBefore = await contentOf('deck');
      final cardsBefore = await contentOf('card');
      final schedulesBefore = await contentOf('card_schedule');
      clock = DateTime(2026, 9, 26, 10);

      await delete(words.id);

      expect(await contentOf('deck'), decksBefore);
      expect(await contentOf('card'), cardsBefore);
      expect(await contentOf('card_schedule'), schedulesBefore);
    },
  );

  test('a tombstone inside keeps its own, older batch: the new batch takes '
      'only the rows still active (BR-TRASH-003)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final food = await decks.sub(words.id, 'Food');
    final drinks = await decks.sub(words.id, 'Drinks');
    await insertCard(db, id: 'f1', deckId: food.id);
    await insertCard(db, id: 'd1', deckId: drinks.id);
    final older = await delete(drinks.id);
    clock = clock.add(const Duration(minutes: 5));

    final newer = await delete(words.id);

    expect(await marksOf('deck'), {
      root.id: null,
      words.id: newer,
      food.id: newer,
      drinks.id: older,
    });
    expect(await marksOf('card'), {'f1': newer, 'd1': older});
  });

  test('a sub-deck left with no active child becomes unset; a root stays a '
      'deck of decks (BR-TRASH-005)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final food = await decks.sub(words.id, 'Food');

    await delete(food.id);
    expect(
      (await decks.findById(words.id))!.contentType,
      DeckContentType.unset,
    );

    await delete(words.id);
    expect((await decks.findById(root.id))!.contentType, DeckContentType.deck);
  });

  test('a deck that is gone or already in the Trash is notFound, and nothing '
      'is written (UC-DECK-002)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    await delete(words.id);
    final before = await totalChanges(db);

    for (final deckId in ['missing', words.id]) {
      expect(
        await decks.deleteDeck(deckId: deckId),
        isA<Rejected<String, DeckRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          DeckRejection.notFound,
        ),
      );
    }
    expect(await totalChanges(db), before);
  });

  group('the sessions a delete touches close as content_deleted '
      '(BR-TRASH-004)', () {
    Future<String> learning(String deckId) async =>
        ((await entries.openLearningSession(
          deckId: deckId,
        )) as Ok<String, StudyRejection>).value;

    Future<void> expectClosed(String sessionId) async {
      final session = await sessionOf(db, sessionId);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'content_deleted');
      expect(session.read<DateTime>('ended_at'), clock);
    }

    test('the session of the deck itself', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final id = await learning(lesson.id);
      clock = clock.add(const Duration(minutes: 1));

      await delete(lesson.id);

      await expectClosed(id);
    });

    test(
      'a session of a parent whose queue holds a card of the batch',
      () async {
        final root = await decks.root('Korean');
        final lesson = await decks.sub(root.id, 'Lesson');
        final other = await decks.sub(root.id, 'Other');
        await insertCard(db, id: 'c1', deckId: lesson.id);
        await insertCard(db, id: 'c2', deckId: other.id);
        final id = await learning(root.id);

        await delete(lesson.id);

        await expectClosed(id);
      },
    );

    test('a session whose stored guess question uses a card of the batch as '
        'an option (trash spec D7)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(
        db,
        id: 'asked',
        deckId: lesson.id,
        back: 'library',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
      );
      for (final (index, meaning) in [
        'kitchen',
        'school',
        'office',
        'garden',
      ].indexed) {
        await insertCard(
          db,
          id: 'd$index',
          deckId: other.id,
          back: meaning,
          learnedAt: DateTime(2026, 9, 1),
          dueAt: DateTime(2026, 10, 20),
        );
      }
      await lockScheduler(db, root.id);
      final opened = await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.guess,
      );
      final id = (opened as Ok<String, StudyRejection>).value;
      expect(
        await optionsOf(db, id, 'asked'),
        containsAll(['d0', 'd1', 'd2', 'd3']),
      );

      await delete(other.id);

      await expectClosed(id);
    });

    test('a session opened in the tree of a deck in the batch, though its own '
        'deck has moved to another tree since (IT-CONT-006)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.root('Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final id = await learning(lesson.id);
      expect(
        await decks.moveDeck(deckId: lesson.id, newParentId: other.id),
        isA<Ok<void, DeckRejection>>(),
      );

      await delete(root.id);

      await expectClosed(id);
    });

    test('a session that touches nothing of the batch stays open', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: other.id);
      final id = await learning(lesson.id);

      await delete(other.id);

      expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
    });
  });
}
```

In `test/features/deck/presentation/deck_action_sheet_test.dart`:

Replace

```dart

Future<int> _deckCount(LibraryEnv env) async =>
    (await env.db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
        .read<int>('n');
```

with

```dart

Future<int> _activeDeckCount(LibraryEnv env) async =>
    (await env.db
            .customSelect(
              'SELECT COUNT(*) AS n FROM deck WHERE delete_batch_id IS NULL',
            )
            .getSingle())
        .read<int>('n');
```

Replace

```dart

  libraryTest('Delete says what goes with the deck, then deletes it', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
```

with

```dart

  libraryTest('Delete says what goes with the deck, then sends it to the '
      'Trash', (tester, env) async {
    final korean = await env.decks.root('Korean');
```

Replace

```dart

    expect(await _deckCount(env), 1);
    expect(find.text(_en.deckDeletedToast), findsOneWidget);
```

with

```dart

    expect(await _activeDeckCount(env), 1);
    expect(find.text(_en.deckDeletedToast), findsOneWidget);
```

In `test/features/deck/presentation/deck_actions_controller_test.dart`:

Replace

```dart
      (await db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
          .read<int>('n');
```

with

```dart
      (await db.customSelect('SELECT COUNT(*) AS n FROM deck').getSingle())
          .read<int>('n');

  Future<int> activeDeckCount() async =>
      (await db
              .customSelect(
                'SELECT COUNT(*) AS n FROM deck WHERE delete_batch_id IS NULL',
              )
              .getSingle())
          .read<int>('n');
```

Replace

```dart

  test('deleteDeck takes the subtree with it', () async {
    final korean = await decks().root('Korean');
    await decks().sub(korean.id, 'Words');
    await actions().deleteDeck(deckId: korean.id);

    expect(await deckCount(), 0);
  });

```

with

```dart

  test(
    'deleteDeck moves the subtree to the Trash and hands back its batch',
    () async {
      final korean = await decks().root('Korean');
      await decks().sub(korean.id, 'Words');
      final outcome = await actions().deleteDeck(deckId: korean.id);

      expect(outcome, isA<Ok<String, DeckRejection>>());
      expect(await activeDeckCount(), 0);
      expect(await deckCount(), 2, reason: 'the rows stay, marked');
    },
  );

```

In `test/features/study/data/round_preparation_test.dart`:

Replace

```dart
import '../../../support/test_database.dart';

```

with

```dart
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

```

Replace

```dart

  test('a question its meaning source cannot fill stores no option, and the '
```

with

```dart

  test('an option that went to the Trash is never shown: the question is '
      'blocked, as for a deleted card (BR-TRASH-002, BR-STUDY-040)', () async {
    final (root, leaf) = await tree();
    await learned(root, leaf.id, 'asked', back: 'library', due: true);
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'river',
    ].indexed) {
      await learned(root, leaf.id, 'd$index', back: meaning);
    }
    final id = await review(leaf.id, StudyMode.guess);
    final trashed = (await optionsOf(
      db,
      id,
      'asked',
    )).firstWhere((card) => card != 'asked');
    await trashCardRow(db, trashed);

    final question = (await viewOf(id)).currentItem!.guess!;
    expect(question.isBlocked, isTrue);
    expect(question.options, isEmpty);
  });

  test('a question its meaning source cannot fill stores no option, and the '
```

In `test/features/study/data/session_endings_test.dart`:

Replace

```dart

  test('Continue or leaving a session whose deck was deleted is notFound: '
      'the session went with the deck (IT-CONT-007)', () async {
    final (leaf, id) = await learning(['c1']);
```

with

```dart

  test('Continue or leaving a session whose deck went to the Trash is '
      'sessionClosed: the delete ended it as content_deleted (IT-CONT-007, '
      'BR-TRASH-004)', () async {
    final (leaf, id) = await learning(['c1']);
```

Replace

```dart
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<void, DeckRejection>>(),
    );
```

with

```dart
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<String, DeckRejection>>(),
    );
```

Replace

```dart
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.notFound),
    );
```

with

```dart
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
```

Replace

```dart
      await sessions.abandonSession(sessionId: id),
      _refusedWith(StudyRejection.notFound),
    );
```

with

```dart
      await sessions.abandonSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
```

In `test/features/study/data/watch_session_test.dart`:

Replace

```dart

  test('once its deck is deleted the session is notFound, and the watch '
      'says so (UC-STUDY-001 A5, E5; IT-CONT-007)', () async {
    final (_, leaf) = await tree();
```

with

```dart

  test('once its deck goes to the Trash the session is notFound, and the '
      'watch says so (UC-STUDY-001 A5; IT-CONT-007; BR-TRASH-002)', () async {
    final (_, leaf) = await tree();
```

Replace

```dart
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<void, DeckRejection>>(),
    );
```

with

```dart
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<String, DeckRejection>>(),
    );
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/deck/data/deck_repository_impl_test.dart \
  test/features/deck/data/deck_trash_test.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/deck_actions_controller_test.dart \
  test/features/study/data/round_preparation_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_session_test.dart
```

Expected: `+64 -15: Some tests failed.` `deleteDeck` still deletes for good and returns no batch id: ten
tests fail on
`type 'Ok<void, DeckRejection>' is not a subtype of type 'Ok<String, DeckRejection>' in type cast`,
three on `Expected: <Instance of 'Ok<String, DeckRejection>'>`, one on the
`Rejected<String, DeckRejection>` cast of a missing deck, and the guess question
still shows its option in the Trash (`Expected: true`, `Actual: <false>`). The
tests that now count active decks pass already: a deck deleted for good counts as
none.

- [ ] **Step 3: Write the statements deck and card share**

The CI tooling tests ask every
query file for an owner (Clarification 14).

Create `lib/core/database/queries/trash_queries.drift`:

```sql
import '../tables/trash.drift';
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/study.drift';

-- BR-TRASH-001: the batch of one deletion, with its item root and the one
-- time the retention counts from (BR-TRASH-009).
insertDeleteBatch(:id AS TEXT, :item_type AS TEXT, :root_item_id AS TEXT,
  :deleted_at AS DATETIME):
INSERT INTO delete_batches (id, item_type, root_item_id, deleted_at)
VALUES (:id, :item_type, :root_item_id, :deleted_at);

-- BR-TRASH-004: every open session the batch touches closes, in the
-- transaction of the delete: opened on one of its decks or in the tree of
-- one (a deck may leave its tree mid-session, IT-CONT-006), holding one of
-- its cards in the queue, or using one of its cards as a stored guess
-- option (trash spec D7). The reason is stored, never inferred.
closeSessionsTouchingBatch(:batch_id AS TEXT, :now AS DATETIME):
UPDATE study_session
SET status = 'invalidated', end_reason = 'content_deleted', ended_at = :now
WHERE status = 'in_progress' AND (
  deck_id IN (SELECT id FROM deck WHERE delete_batch_id = :batch_id)
  OR root_id IN (SELECT id FROM deck WHERE delete_batch_id = :batch_id)
  OR id IN (SELECT q.session_id FROM study_queue_items q
    JOIN card c ON c.id = q.card_id WHERE c.delete_batch_id = :batch_id)
  OR id IN (SELECT o.session_id FROM study_guess_options o
    JOIN card c ON c.id = o.option_card_id WHERE c.delete_batch_id = :batch_id)
);
```

In `lib/core/database/app_database.dart`:

Replace

```dart
    'package:memox/core/database/queries/deck_queries.drift',
  },
```

with

```dart
    'package:memox/core/database/queries/deck_queries.drift',
    'package:memox/core/database/queries/trash_queries.drift',
  },
```

In `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`:

Replace

```json
    "card_queries": ["card"],
    "deck_queries": ["deck"]
  },
```

with

```json
    "card_queries": ["card"],
    "deck_queries": ["deck"],
    "trash_queries": ["card", "deck"]
  },
```

- [ ] **Step 4: Generate the database code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner` (it warns that `--delete-conflicting-outputs` is ignored).

- [ ] **Step 5: Move a deck and its active subtree to the Trash**

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart

  Future<void> delete(String id) =>
      (_db.delete(_db.deck)..where((deck) => deck.id.equals(id))).go();

```

with

```dart

  /// The batch of one deletion, with [id] as its item root (BR-TRASH-001).
  Future<void> insertBatch(String batchId, String id, DateTime now) =>
      _db.insertDeleteBatch(batchId, 'deck', id, now);

  /// Puts [id] and every active deck under it in the batch [batchId], then
  /// every active card of those decks (BR-TRASH-001). A tombstone inside
  /// keeps its older batch (BR-TRASH-003). The walk is cycle-safe and never
  /// capped.
  Future<void> markSubtree(String id, String batchId) async {
    await _db.customUpdate(
      'WITH RECURSIVE subtree(id) AS ('
      ' SELECT ? UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
      ' WHERE d.delete_batch_id IS NULL'
      ') UPDATE deck SET delete_batch_id = ? WHERE id IN (SELECT id FROM subtree)',
      variables: [Variable<String>(id), Variable<String>(batchId)],
      updates: {_db.deck},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE card SET delete_batch_id = ? WHERE delete_batch_id IS NULL'
      ' AND deck_id IN (SELECT id FROM deck WHERE delete_batch_id = ?)',
      variables: [Variable<String>(batchId), Variable<String>(batchId)],
      updates: {_db.card},
      updateKind: UpdateKind.update,
    );
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004;
  /// `trash_queries.drift`).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      _db.closeSessionsTouchingBatch(now, batchId);

```

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId});

```

with

```dart

  /// UC-DECK-002: [deckId] and every active deck and card under it go to the
  /// Trash as one batch, whose id comes back for an Undo (BR-DECK-022,
  /// BR-TRASH-001). The sessions it touches end (BR-TRASH-004).
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  });

```

In `lib/features/deck/data/repositories/deck_repository_impl.dart`:

Replace

```dart
  @override
  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) {
    final at = _now();
    return _write(() async {
```

with

```dart
  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
```

Replace

```dart
      if (deck == null) return const Rejected(DeckRejection.notFound);
      // Sub-decks, cards, schedule rows, review logs and sessions go with it
      // by cascade (BR-DECK-022).
      await _dao.delete(deckId);
      if (deck.parentId case final parentId?) {
        await _refreshContentType(parentId, at);
      }
      return const Ok(null);
    });
  }
```

with

```dart
      if (deck == null) return const Rejected(DeckRejection.notFound);
      // The rows stay where they are, marked: only a purge deletes them, by
      // cascade (BR-DECK-022, BR-TRASH-010).
      final batchId = newId();
      await _dao.insertBatch(batchId, deckId, at);
      await _dao.markSubtree(deckId, batchId);
      if (deck.parentId case final parentId?) {
        await _refreshContentType(parentId, at);
      }
      await _dao.closeSessionsTouching(batchId, at);
      return Ok(batchId);
    });
  }
```

Replace the whole of `lib/features/deck/domain/usecases/delete_deck_use_case.dart` with:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-DECK-002: the deck and its active subtree go to the Trash as one batch
/// (BR-DECK-022, BR-TRASH-001); the batch id is what an Undo takes.
final class DeleteDeckUseCase {
  const DeleteDeckUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<String, DeckRejection>> call({required String deckId}) =>
      _decks.deleteDeck(deckId: deckId);
}
```

In `lib/features/deck/presentation/controllers/deck_actions_controller.dart`:

Replace

```dart

  Future<Outcome<void, DeckRejection>> deleteDeck({required String deckId}) =>
      ref.read(deleteDeckUseCaseProvider)(deckId: deckId);
```

with

```dart

  Future<Outcome<String, DeckRejection>> deleteDeck({required String deckId}) =>
      ref.read(deleteDeckUseCaseProvider)(deckId: deckId);
```

- [ ] **Step 6: Leave the Trash out of a guess question and of the session screen**

In `lib/features/study/data/datasources/study_view_dao.dart`:

Replace

```dart
  /// [sessionId]'s row, with its deck's name and its root's scheduler; null
  /// once the session is gone. Emits again on every write the session
  /// screen can see: the session, its queue, its decks, cards, schedules and
  /// logs.
  Stream<SessionViewRow?> watchSessionRow(String sessionId) => _db
```

with

```dart
  /// [sessionId]'s row, with its deck's name and its root's scheduler; null
  /// once the session is gone or its deck or root is in the Trash
  /// (BR-TRASH-002). Emits again on every write the session screen can see:
  /// the session, its queue, its decks, cards, schedules and logs.
  Stream<SessionViewRow?> watchSessionRow(String sessionId) => _db
```

Replace

```dart
        ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
        ' JOIN deck r ON r.id = s.root_id WHERE s.id = ?',
        variables: [Variable<String>(sessionId)],
```

with

```dart
        ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
        ' JOIN deck r ON r.id = s.root_id WHERE s.id = ?'
        ' AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL',
        variables: [Variable<String>(sessionId)],
```

Replace

```dart
  /// The options of [cardId]'s question in [round] of `guess`, in the order
  /// shown (graded modes spec §9).
  Future<List<OptionRecord>> guessOptions(
```

with

```dart
  /// The options of [cardId]'s question in [round] of `guess`, in the order
  /// shown (graded modes spec §9). A card in the Trash is left out
  /// (BR-TRASH-002), which blocks the question as a deleted card does; a
  /// delete closes such a session anyway (trash spec D7).
  Future<List<OptionRecord>> guessOptions(
```

Replace

```dart
          ' WHERE o.session_id = ? AND o.round = ? AND o.card_id = ?'
          ' ORDER BY o.slot',
          variables: [
```

with

```dart
          ' WHERE o.session_id = ? AND o.round = ? AND o.card_id = ?'
          ' AND c.delete_batch_id IS NULL ORDER BY o.slot',
          variables: [
```

In `lib/features/study/domain/usecases/watch_study_session_use_case.dart`:

Replace

```dart
/// UC-STUDY-001 steps 6–13: the session screen, again after every turn, and
/// notFound once the session is gone with its deck (A5, E5). It writes
/// nothing (BR-STUDY-075).
final class WatchStudySessionUseCase {
```

with

```dart
/// UC-STUDY-001 steps 6–13: the session screen, again after every turn, and
/// notFound once its deck is in the Trash or the session is gone (A5, E5;
/// BR-TRASH-002). It writes nothing (BR-STUDY-075).
final class WatchStudySessionUseCase {
```

- [ ] **Step 7: Say what a deck delete does now**

Run:

```bash
git mv docs/features/deck/rules/BR-DECK-022-xoa-deck-cascade-toan-bo-cay.md docs/features/deck/rules/BR-DECK-022-xoa-deck-dua-ca-cay-vao-trash.md
```

Replace the whole of `docs/features/deck/rules/BR-DECK-022-xoa-deck-dua-ca-cay-vao-trash.md` with:

```markdown
---
id: BR-DECK-022
title: Xoá deck đưa cả cây vào Trash
status: active
summary: Xoá deck chuyển deck cùng mọi deck con và card còn active bên dưới vào Trash thành một batch; chỉ purge mới xoá hẳn, theo cascade.
superseded_by:
---
## Rule

Xoá deck MUST chuyển deck đó cùng mọi deck con và card còn active bên dưới vào Trash, thành **một** batch mà item root là chính deck đó (BR-TRASH-001, BR-TRASH-003), và MUST NOT xoá cứng hàng nào. Chỉ purge một batch (BR-TRASH-010) mới xoá hẳn: deck, card, study state, study answers và study session của batch đi theo cascade.

**Enforced by:** store + db
**Liên quan:** BR-TRASH-001, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-010

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
```

Replace the whole of `docs/features/deck/rules/BR-DECK-023-xoa-deck-can-xac-nhan-kem-so-luong.md` with:

```markdown
---
id: BR-DECK-023
title: Xoá deck cần xác nhận kèm số lượng
status: active
summary: Xoá deck cần xác nhận, kèm số deck con và số card sẽ vào Trash cùng nó.
superseded_by:
---
## Rule

Xoá deck MUST cần xác nhận, kèm số deck con và số card còn active sẽ vào Trash cùng nó (BR-DECK-022).

**Enforced by:** UI
**Liên quan:** BR-DECK-022, BR-TRASH-001

## Lý do

Nguồn không ghi lý do.

## Ví dụ

Không áp dụng

## Edge case

Không áp dụng
```

In `docs/features/deck/ui.md`:

Replace

```markdown

    B -->|"Xoá"| F["Xác nhận, nêu rõ số deck con và số card sẽ bị xoá vĩnh viễn · UC-DECK-002, BR-DECK-023"]
    F -->|"Đồng ý"| F1["Xoá cứng cả cây theo cascade, trong một transaction · BR-DECK-022 · Trash là sub-project sau, xem UC-TRASH-001"]
    F -->|"Huỷ"| F2["Không xảy ra gì · UC-DECK-002 A3"]
```

with

```markdown

    B -->|"Xoá"| F["Xác nhận, nêu rõ số deck con và số card sẽ vào Trash cùng deck · UC-DECK-002, BR-DECK-023"]
    F -->|"Đồng ý"| F1["Chuyển cả cây active vào Trash thành một batch, trong một transaction · BR-DECK-022, BR-TRASH-001 · Undo hoặc khôi phục: UC-TRASH-001"]
    F -->|"Huỷ"| F2["Không xảy ra gì · UC-DECK-002 A3"]
```

In `docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md`:

Replace

```markdown
status: ready
rules: [BR-DECK-015, BR-DECK-020, BR-DECK-022, BR-DECK-023, BR-DECK-025, BR-SRS-002, BR-SRS-003, BR-SRS-004, BR-STUDY-016]
code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart, lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart, lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart]
```

with

```markdown
status: ready
rules: [BR-DECK-015, BR-DECK-020, BR-DECK-022, BR-DECK-023, BR-DECK-025, BR-SRS-002, BR-SRS-003, BR-SRS-004, BR-STUDY-016, BR-TRASH-001, BR-TRASH-002, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-008]
code: [lib/features/deck/domain/usecases/rename_deck_use_case.dart, lib/features/deck/domain/usecases/change_deck_scheduler_use_case.dart, lib/features/deck/domain/usecases/get_deck_deletion_summary_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart]
```

Replace

```markdown
**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ bị xoá vĩnh viễn
   (BR-DECK-023).
2. Người dùng xác nhận.
3. Hệ thống xoá cứng deck cùng toàn bộ descendant, card, study state, study
   answers và study session của nó, trong một transaction (BR-DECK-022). Khi
   sub-project Trash triển khai, bước này đổi thành soft-delete có Undo và
   khôi phục — xem UC-TRASH-001.

```

with

```markdown
**Main flow (xoá):**
1. Hệ thống hỏi xác nhận, nêu rõ số deck con và số card sẽ vào Trash cùng deck
   (BR-DECK-023).
2. Người dùng xác nhận.
3. Hệ thống chuyển deck cùng mọi deck con và card còn active bên dưới vào Trash,
   thành **một** batch, trong một transaction (BR-DECK-022, BR-TRASH-001,
   BR-TRASH-003). Tombstone đã có sẵn bên trong giữ batch cũ của nó. Phiên
   `in_progress` chạm tới batch kết thúc trong cùng transaction với
   `content_deleted` (BR-TRASH-004).
4. Người dùng có thể Undo ngay tại chỗ (BR-TRASH-008) hoặc khôi phục về sau từ
   Trash (UC-TRASH-001).

```

Replace

```markdown
  vẫn NULL, và không còn phiên `in_progress` nào của cây (BR-STUDY-016).
- Sau xoá: deck và mọi descendant của nó không còn tồn tại — cascade đã xoá
  cứng card, study state, study answers và study session của chúng (BR-DECK-022);
  không bề mặt active nào còn hiện chúng.
- Sau xoá một deck con: nếu deck cha là **sub-deck** và vừa mất phần tử con cuối
  cùng, `content_type` của nó tự về `unset` trong cùng transaction (BR-DECK-015).
  Deck cha là root thì giữ `deck` (BR-DECK-004).

```

with

```markdown
  vẫn NULL, và không còn phiên `in_progress` nào của cây (BR-STUDY-016).
- Sau xoá: deck và mọi descendant active của nó nằm trong Trash, cùng một batch
  và một `deleted_at` (BR-DECK-022, BR-TRASH-001); không bề mặt active nào còn
  hiện chúng (BR-TRASH-002). Nội dung, study state, study answers, id và chỗ cũ
  của từng hàng giữ nguyên tới khi purge (BR-TRASH-004); chỉ purge mới xoá hẳn,
  theo cascade (BR-TRASH-010).
- Sau xoá một deck con: nếu deck cha là **sub-deck** và vừa mất phần tử con
  active cuối cùng, `content_type` của nó tự về `unset` trong cùng transaction
  (BR-DECK-015, BR-TRASH-005). Deck cha là root thì giữ `deck` (BR-DECK-004).

```

In `docs/shared/data/schema.md`:

Replace

```markdown
| `status` | TEXT NOT NULL | `in_progress` \| `completed` \| `abandoned` \| `invalidated` \| `failed` (BR-STUDY-010) |
| `end_reason` | TEXT NULL | `user_exit` \| `scheduler_reset` \| `scheduler_changed` \| `stale_generation` \| `persistence_error` \| `interrupted` \| `content_deleted` (BR-STUDY-012, BR-TRASH-004, BR-STUDY-016). NULL khi `in_progress` hoặc `completed`. **Phạm vi:** `content_deleted` là sub-project sau — Trash |
| `cursor` | INTEGER NOT NULL DEFAULT 0 | số lượt đã phục vụ trong phiên; nền của BR-STUDY-005 |
```

with

```markdown
| `status` | TEXT NOT NULL | `in_progress` \| `completed` \| `abandoned` \| `invalidated` \| `failed` (BR-STUDY-010) |
| `end_reason` | TEXT NULL | `user_exit` \| `scheduler_reset` \| `scheduler_changed` \| `stale_generation` \| `persistence_error` \| `interrupted` \| `content_deleted` (BR-STUDY-012, BR-TRASH-004, BR-STUDY-016). NULL khi `in_progress` hoặc `completed`. **Phạm vi:** `content_deleted` có từ schema v3 (Trash, BE-B1) |
| `cursor` | INTEGER NOT NULL DEFAULT 0 | số lượt đã phục vụ trong phiên; nền của BR-STUDY-005 |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 57 warning(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/deck/data/deck_repository_impl_test.dart \
  test/features/deck/data/deck_trash_test.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/deck_actions_controller_test.dart \
  test/features/study/data/round_preparation_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_session_test.dart
```

Expected: `+79: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The rename is staged already, by `git mv`.

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add .claude/skills/flutter-workflow/scripts/verification_impact_map.json \
  docs/features/deck/rules/BR-DECK-022-xoa-deck-dua-ca-cay-vao-trash.md \
  docs/features/deck/rules/BR-DECK-023-xoa-deck-can-xac-nhan-kem-so-luong.md \
  docs/features/deck/ui.md \
  docs/features/deck/usecases/UC-DECK-002-sua-va-xoa-deck.md \
  docs/shared/data/schema.md \
  lib/core/database/app_database.dart \
  lib/core/database/queries/trash_queries.drift \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  lib/features/deck/domain/usecases/delete_deck_use_case.dart \
  lib/features/deck/presentation/controllers/deck_actions_controller.dart \
  lib/features/study/data/datasources/study_view_dao.dart \
  lib/features/study/domain/usecases/watch_study_session_use_case.dart \
  test/features/deck/data/deck_repository_impl_test.dart \
  test/features/deck/data/deck_trash_test.dart \
  test/features/deck/presentation/deck_action_sheet_test.dart \
  test/features/deck/presentation/deck_actions_controller_test.dart \
  test/features/study/data/round_preparation_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_session_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 57 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1476: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
feat(deck): a deck delete moves its active subtree to the Trash

deleteDeck no longer deletes: in one transaction it writes a batch, marks
the deck, every active deck under it and their active cards, unsets a
parent sub-deck left with no active child, and returns the batch id for
an Undo (BR-DECK-022, BR-TRASH-001, BR-TRASH-003, BR-TRASH-005). A
tombstone inside keeps its older batch. Every open session the batch
touches ends as content_deleted: one on a deck of the batch or in its
tree, one whose queue holds a card of it, and one whose stored guess
options use such a card, whose options read now leaves the Trash out
(BR-TRASH-004, BR-TRASH-002; trash spec D7). BR-DECK-022, BR-DECK-023 and
UC-DECK-002 say what a delete does now.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: A card delete moves each card to the Trash as a batch of its own

**Files:**
- Modify: `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md`, `lib/features/card/data/datasources/card_dao.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/card/domain/usecases/delete_cards_use_case.dart`, `lib/features/card/presentation/controllers/card_actions_controller.dart`
- Test (create): `test/features/card/data/card_trash_test.dart`
- Test (modify): `test/features/card/data/card_batch_writes_test.dart`, `test/features/card/domain/card_write_use_cases_test.dart`, `test/features/card/presentation/card_actions_controller_test.dart`, `test/features/card/presentation/card_bulk_actions_test.dart`, `test/features/card/presentation/card_editor_screen_test.dart`, `test/features/study/data/session_endings_test.dart`, `test/features/study/data/watch_session_test.dart`, `test/features/study/data/watch_study_home_test.dart`, `test/support/study_fixtures.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `insertDeleteBatch` and `closeSessionsTouchingBatch`;
  `CardDao.liveRows`; the repository's `_unsetEmptied`.
- Produces:
  - In `CardDao`: `Future<void> moveToTrash(String id, String batchId, DateTime now)`
    and `Future<void> closeSessionsTouching(String batchId, DateTime now)`; the hard
    delete goes.
  - `CardRepository.deleteCards({required Set<String> cardIds, DateTime? now})`
    returns `Future<Outcome<List<String>, CardRejection>>`, the batch ids in the order
    of `cardIds`; `DeleteCardsUseCase.call({required Set<String> cardIds})` and
    `CardActionsController.deleteCards({required Set<String> cardIds})` return the
    same.
  - `Future<void> hardDeleteCards(AppDatabase db, Set<String> cardIds)` in
    `test/support/study_fixtures.dart` (Clarification 4).

Spec §6.2, §6.3, D6; Clarifications 3 and 4; Review Focus 5. Each card takes a
batch of its own, all at one `deleted_at`. The older tests that count rows count
active ones; the study tests that settle a session over a card deleted for good
delete it through `hardDeleteCards`.

- [ ] **Step 1: Write the failing tests**

In `test/support/study_fixtures.dart`:

Replace

```dart

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
```

with

```dart

import 'package:drift/drift.dart' show QueryRow, UpdateKind, Variable;
import 'package:flutter_test/flutter_test.dart';
```

Replace

```dart
        .read<String>('card_id');
```

with

```dart
        .read<String>('card_id');

/// Deletes [cardIds] for good, the way a build before the Trash (schema v2)
/// did: their open sessions stayed open without them, and spec D12's settle
/// is for those sessions. A sub-deck left with no active card goes back to
/// unset, as that delete did. A delete today closes such a session instead
/// (BR-TRASH-004).
Future<void> hardDeleteCards(AppDatabase db, Set<String> cardIds) async {
  final marks = List.filled(cardIds.length, '?').join(', ');
  await db.customUpdate(
    'DELETE FROM card WHERE id IN ($marks)',
    variables: [for (final id in cardIds) Variable<String>(id)],
    updates: {db.card},
    updateKind: UpdateKind.delete,
  );
  await db.customUpdate(
    "UPDATE deck SET content_type = 'unset' WHERE parent_id IS NOT NULL"
    " AND content_type = 'card' AND NOT EXISTS (SELECT 1 FROM card c"
    ' WHERE c.deck_id = deck.id AND c.delete_batch_id IS NULL)',
    updates: {db.deck},
    updateKind: UpdateKind.update,
  );
}
```

In `test/features/card/data/card_batch_writes_test.dart`:

Replace

```dart
  group('deleteCards (BR-CARD-011)', () {
    test('deletes the batch with its schedule rows and tag links; an emptied deck is unset', () async {
      final a = await cards.card(
```

with

```dart
  group('deleteCards (BR-CARD-011)', () {
    test('moves the cards to the Trash with their schedule rows and tag links; an emptied deck is unset', () async {
      final a = await cards.card(
```

Replace

```dart

      expect(result, isA<Ok<void, CardRejection>>());
      expect(
```

with

```dart

      expect(result, isA<Ok<List<String>, CardRejection>>());
      expect(
```

Replace

```dart
          await count('card_tags'),
        ),
        (1, 1, 0),
      );
      expect(await contentTypeOf(nouns.id), DeckContentType.unset);
```

with

```dart
          await count('card_tags'),
        ),
        (3, 3, 1),
      );
      expect(await contentTypeOf(nouns.id), DeckContentType.unset);
```

Replace

```dart
        await cards.deleteCards(cardIds: {}),
        isA<Ok<void, CardRejection>>(),
      );
```

with

```dart
        await cards.deleteCards(cardIds: {}),
        isA<Ok<List<String>, CardRejection>>(),
      );
```

Replace

```dart
        await cards.deleteCards(cardIds: {cardId}),
        isA<Ok<void, CardRejection>>(),
      );
```

with

```dart
        await cards.deleteCards(cardIds: {cardId}),
        isA<Ok<List<String>, CardRejection>>(),
      );
```

Create `test/features/card/data/card_trash_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-CARD-001 A2: a card delete moves each card to the Trash as a batch of
// its own (BR-TRASH-001, BR-TRASH-004, BR-TRASH-005; trash spec §6.2).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late StudyEntryRepositoryImpl entries;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    entries = studyEntryRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<List<String>> delete(Set<String> cardIds) async =>
      ((await cards.deleteCards(
        cardIds: cardIds,
      )) as Ok<List<String>, CardRejection>).value;

  Future<String?> batchOf(String cardId) async =>
      (await db
              .customSelect(
                'SELECT delete_batch_id FROM card WHERE id = ?',
                variables: [Variable(cardId)],
              )
              .getSingle())
          .read<String?>('delete_batch_id');

  /// Each row of [table], every column but `delete_batch_id`.
  Future<List<Map<String, Object?>>> contentOf(String table) async => [
    for (final row
        in await db.customSelect('SELECT * FROM $table ORDER BY rowid').get())
      {...row.data}..remove('delete_batch_id'),
  ];

  test('deleting three cards writes three batches at one time, each card the '
      'item root of its own, in the order asked (BR-TRASH-001)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    for (final id in ['c1', 'c2', 'c3', 'kept']) {
      await insertCard(db, id: id, deckId: lesson.id);
    }

    final batchIds = await delete({'c3', 'c1', 'c2'});

    expect(batchIds.toSet(), hasLength(3));
    expect([
      for (final id in ['c3', 'c1', 'c2']) await batchOf(id),
    ], batchIds);
    expect(await batchOf('kept'), isNull);
    final batches = await db
        .customSelect(
          'SELECT item_type, root_item_id, deleted_at FROM delete_batches'
          ' ORDER BY root_item_id',
        )
        .get();
    expect(
      [
        for (final batch in batches)
          (
            batch.read<String>('item_type'),
            batch.read<String>('root_item_id'),
            batch.read<DateTime>('deleted_at'),
          ),
      ],
      [('card', 'c1', clock), ('card', 'c2', clock), ('card', 'c3', clock)],
    );
  });

  test('marking changes no content, no updated_at, no deck and no schedule '
      '(trash spec §6.4)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: lesson.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
    );
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await lockScheduler(db, root.id);
    final cardsBefore = await contentOf('card');
    final schedulesBefore = await contentOf('card_schedule');
    clock = DateTime(2026, 9, 26, 10);

    await delete({'c1'});

    expect(await contentOf('card'), cardsBefore);
    expect(await contentOf('card_schedule'), schedulesBefore);
  });

  test('a card that is gone or already in the Trash refuses the whole set as '
      'notFound, and nothing is written; an empty set writes nothing '
      '(UC-CARD-001 A2)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await delete({'c2'});
    final before = await totalChanges(db);

    for (final cardIds in [
      {'c1', 'missing'},
      {'c1', 'c2'},
    ]) {
      expect(
        await cards.deleteCards(cardIds: cardIds),
        isA<Rejected<List<String>, CardRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          CardRejection.notFound,
        ),
      );
    }
    expect(await delete({}), isEmpty);
    expect(await totalChanges(db), before);
  });

  test(
    'a selection of 1,000 cards goes in one call: 1,000 batches at one '
    'time, and the deck left empty is unset (BR-TRASH-001, BR-TRASH-005)',
    () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final ids = {for (var i = 0; i < 1000; i++) 'c$i'};
      for (final id in ids) {
        await insertCard(db, id: id, deckId: lesson.id);
      }

      final batchIds = await delete(ids);

      expect(batchIds.toSet(), hasLength(1000));
      final batches = await db
          .customSelect(
            'SELECT COUNT(*) AS n, COUNT(DISTINCT deleted_at) AS times'
            ' FROM delete_batches',
          )
          .getSingle();
      expect((batches.read<int>('n'), batches.read<int>('times')), (1000, 1));
      final deck = await db
          .customSelect(
            'SELECT content_type FROM deck WHERE id = ?',
            variables: [Variable(lesson.id)],
          )
          .getSingle();
      expect(deck.read<String>('content_type'), 'unset');
    },
  );

  group('the sessions a delete touches close as content_deleted '
      '(BR-TRASH-004)', () {
    Future<void> expectClosed(String sessionId) async {
      final session = await sessionOf(db, sessionId);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'content_deleted');
      expect(session.read<DateTime>('ended_at'), clock);
    }

    test('a session whose queue holds the card', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: lesson.id);
      final opened = await entries.openLearningSession(deckId: lesson.id);
      final id = (opened as Ok<String, StudyRejection>).value;
      clock = clock.add(const Duration(minutes: 1));

      await delete({'c2'});

      await expectClosed(id);
    });

    test('a session whose stored guess question uses the card as an option '
        '(trash spec D7)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(
        db,
        id: 'asked',
        deckId: lesson.id,
        back: 'library',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
      );
      for (final (index, meaning) in [
        'kitchen',
        'school',
        'office',
        'garden',
      ].indexed) {
        await insertCard(
          db,
          id: 'd$index',
          deckId: other.id,
          back: meaning,
          learnedAt: DateTime(2026, 9, 1),
          dueAt: DateTime(2026, 10, 20),
        );
      }
      await lockScheduler(db, root.id);
      final opened = await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.guess,
      );
      final id = (opened as Ok<String, StudyRejection>).value;
      expect(await optionsOf(db, id, 'asked'), contains('d0'));

      await delete({'d0'});

      await expectClosed(id);
    });

    test('a session that touches none of the cards stays open', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: other.id);
      final opened = await entries.openLearningSession(deckId: lesson.id);
      final id = (opened as Ok<String, StudyRejection>).value;

      await delete({'c2'});

      expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
    });
  });
}
```

In `test/features/card/domain/card_write_use_cases_test.dart`:

Replace

```dart
      final rows = await db
          .customSelect('SELECT id, deck_id, back, is_flagged FROM card')
          .get();
```

with

```dart
      final rows = await db
          .customSelect(
            'SELECT id, deck_id, back, is_flagged FROM card'
            ' WHERE delete_batch_id IS NULL',
          )
          .get();
```

In `test/features/card/presentation/card_actions_controller_test.dart`:

Replace

```dart

  test('deleteCards deletes every card given', () async {
    await seed();
    await actions().deleteCards(cardIds: {'a', 'c'});

    expect(await count('SELECT COUNT(*) AS n FROM card'), 2);
  });

```

with

```dart

  test(
    'deleteCards moves every card given to the Trash, a batch each',
    () async {
      await seed();
      final outcome = await actions().deleteCards(cardIds: {'a', 'c'});

      expect((outcome as Ok<List<String>, CardRejection>).value, hasLength(2));
      expect(
        await count(
          'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
        ),
        2,
      );
    },
  );

```

In `test/features/card/presentation/card_bulk_actions_test.dart`:

Replace

```dart
    await tester.pumpAndSettle();
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 2);
    expect(find.text(_en.cardDeletedToast(2)), findsOneWidget);
```

with

```dart
    await tester.pumpAndSettle();
    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
      ),
      2,
    );
    expect(find.text(_en.cardDeletedToast(2)), findsOneWidget);
```

In `test/features/card/presentation/card_editor_screen_test.dart`:

Replace

```dart
    expect(find.text(_en.cardBackToDeck), findsOneWidget);
    expect(await _count(env, 'SELECT COUNT(*) AS n FROM card'), 0);
  });
```

with

```dart
    expect(find.text(_en.cardBackToDeck), findsOneWidget);
    expect(
      await _count(
        env,
        'SELECT COUNT(*) AS n FROM card WHERE delete_batch_id IS NULL',
      ),
      0,
    );
  });
```

In `test/features/study/data/session_endings_test.dart`:

Replace

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
```

with

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
```

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

Replace

```dart

  Future<void> deleteCards(Set<String> cardIds) async {
    final schedules = ScheduleRepositoryImpl(db, now: () => clock);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    expect(
      await cards.deleteCards(cardIds: cardIds),
      isA<Ok<void, CardRejection>>(),
    );
  }

```

with

```dart

  /// Spec D12 settles the sessions a build before the Trash left open.
  Future<void> deleteCards(Set<String> cardIds) => hardDeleteCards(db, cardIds);

```

In `test/features/study/data/watch_session_test.dart`:

Replace

```dart

  Future<void> deleteCards(Set<String> cardIds) async {
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );
    expect(
      await cards.deleteCards(cardIds: cardIds),
      isA<Ok<void, CardRejection>>(),
    );
  }

```

with

```dart

  /// Spec D12 settles the sessions a build before the Trash left open.
  Future<void> deleteCards(Set<String> cardIds) => hardDeleteCards(db, cardIds);

```

In `test/features/study/data/watch_study_home_test.dart`:

Replace

```dart

  test('a session whose cards left in its round were deleted is still '
      'offered, with no progress until Continue settles it (BR-STUDY-075, '
      'spec D3)', () async {
    final root = await decks.root('Korean');
```

with

```dart

  test('a session whose cards left in its round were deleted by a build '
      'before the Trash is still offered, with no progress until Continue '
      'settles it (BR-STUDY-075, spec D3)', () async {
    final root = await decks.root('Korean');
```

Replace

```dart
    await answerServed(db, sessions, id, right: true);
    expect(
      await cardRepository().deleteCards(
        cardIds: {first == 'c1' ? 'c2' : 'c1'},
      ),
      isA<Ok<void, CardRejection>>(),
    );

```

with

```dart
    await answerServed(db, sessions, id, right: true);
    await hardDeleteCards(db, {first == 'c1' ? 'c2' : 'c1'});

```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_trash_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/features/card/presentation/card_actions_controller_test.dart \
  test/features/card/presentation/card_bulk_actions_test.dart \
  test/features/card/presentation/card_editor_screen_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_session_test.dart \
  test/features/study/data/watch_study_home_test.dart
```

Expected: `+75 -11: Some tests failed.` `deleteCards` still deletes for good and returns nothing: eight
tests fail on
`type 'Ok<void, CardRejection>' is not a subtype of type 'Ok<List<String>, CardRejection>' in type cast`
and three on `Expected: <Instance of 'Ok<List<String>, CardRejection>'>`.

- [ ] **Step 3: Move each card to the Trash as a batch of its own**

In `lib/features/card/data/datasources/card_dao.dart`:

Replace

```dart

  /// Their schedule rows, review logs and tag links go with them by cascade.
  Future<void> deleteCards(Set<String> ids) =>
      (_db.delete(_db.card)..where((card) => card.id.isIn(ids))).go();

```

with

```dart

  /// [id] goes to the Trash as the item root of the batch [batchId]
  /// (BR-TRASH-001). The row stays as it is otherwise; only a purge deletes
  /// it, and its schedule, logs and tag links with it.
  Future<void> moveToTrash(String id, String batchId, DateTime now) async {
    await _db.insertDeleteBatch(batchId, 'card', id, now);
    await (_db.update(_db.card)..where((card) => card.id.equals(id))).write(
      CardCompanion(deleteBatchId: Value(batchId)),
    );
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004;
  /// `trash_queries.drift`).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      _db.closeSessionsTouchingBatch(now, batchId);

```

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart

  /// Their schedule rows, logs and tag links go with them; a deck left with
  /// no card is unset again (BR-DECK-015).
  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  });
```

with

```dart

  /// UC-CARD-001 A2: each card goes to the Trash as a batch of its own, all
  /// at one time, and the batch ids come back in the order of [cardIds]
  /// (BR-TRASH-001). A deck left with no active card is unset again
  /// (BR-TRASH-005); the sessions they touch end (BR-TRASH-004).
  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  });
```

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
  @override
  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
  }) {
    final at = _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok(null);
      final rows = await _dao.liveRows(cardIds);
```

with

```dart
  @override
  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (cardIds.isEmpty) return const Ok([]);
      final rows = await _dao.liveRows(cardIds);
```

Replace

```dart
      }
      await _dao.deleteCards(cardIds);
      await _unsetEmptied({for (final row in rows) row.deckId}, at);
      return const Ok(null);
    });
```

with

```dart
      }
      // One batch per card, all at one time: each card is an item the person
      // can restore on its own (BR-TRASH-001).
      final batchIds = <String>[];
      for (final cardId in cardIds) {
        final batchId = newId();
        await _dao.moveToTrash(cardId, batchId, at);
        batchIds.add(batchId);
      }
      await _unsetEmptied({for (final row in rows) row.deckId}, at);
      for (final batchId in batchIds) {
        await _dao.closeSessionsTouching(batchId, at);
      }
      return Ok(batchIds);
    });
```

Replace the whole of `lib/features/card/domain/usecases/delete_cards_use_case.dart` with:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-CARD-001 A2, A6: the cards go to the Trash, all or none (BR-CARD-011),
/// each as a batch of its own whose id an Undo takes (BR-TRASH-001).
final class DeleteCardsUseCase {
  const DeleteCardsUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<List<String>, CardRejection>> call({
    required Set<String> cardIds,
  }) => _cards.deleteCards(cardIds: cardIds);
}
```

In `lib/features/card/presentation/controllers/card_actions_controller.dart`:

Replace

```dart

  Future<Outcome<void, CardRejection>> deleteCards({
    required Set<String> cardIds,
```

with

```dart

  Future<Outcome<List<String>, CardRejection>> deleteCards({
    required Set<String> cardIds,
```

- [ ] **Step 4: Say what a card delete does now**

In `docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md`:

Replace

```markdown
status: ready
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-CARD-005, BR-CARD-006, BR-CARD-009, BR-CARD-010, BR-CARD-011, BR-CARD-012, BR-CARD-020, BR-DECK-009, BR-DECK-015, BR-DECK-022, BR-DECK-023, BR-TAG-001, BR-TAG-002, BR-TAG-004]
code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart, lib/features/card/domain/usecases/edit_card_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/move_cards_use_case.dart, lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart, lib/features/card/domain/usecases/set_cards_flagged_use_case.dart, lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart, lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart]
```

with

```markdown
status: ready
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-CARD-005, BR-CARD-006, BR-CARD-009, BR-CARD-010, BR-CARD-011, BR-CARD-012, BR-CARD-020, BR-DECK-009, BR-DECK-015, BR-DECK-022, BR-DECK-023, BR-TAG-001, BR-TAG-002, BR-TAG-004, BR-TRASH-001, BR-TRASH-004, BR-TRASH-005, BR-TRASH-008]
code: [lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart, lib/features/card/domain/usecases/create_card_use_case.dart, lib/features/card/domain/usecases/edit_card_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/move_cards_use_case.dart, lib/features/card/domain/usecases/watch_card_move_targets_use_case.dart, lib/features/card/domain/usecases/set_cards_flagged_use_case.dart, lib/features/card/domain/usecases/add_tag_to_cards_use_case.dart, lib/features/card/domain/usecases/remove_tag_from_cards_use_case.dart]
```

Replace

```markdown
- **A1 — Sửa card:** nội dung đổi; study state và history **không** đổi (BR-CARD-005).
- **A2 — Xoá card:** hỏi xác nhận, nêu rõ nội dung sẽ mất (BR-DECK-023); xác nhận thì
  xoá cứng card cùng study state và history của nó, trong một transaction
  (BR-DECK-022). Khi sub-project Trash triển khai, thao tác này đổi thành soft-delete
  có Undo và khôi phục — xem UC-TRASH-001. Nếu đó là card **cuối cùng** đang active,
  deck atomically trở về `content_type = unset` trong cùng transaction
  (BR-DECK-015); sau đó người dùng quay về màn hình deck và
  lại chọn được tạo card hay tạo sub-deck. "Deck `card` rỗng" không còn là một
```

with

```markdown
- **A1 — Sửa card:** nội dung đổi; study state và history **không** đổi (BR-CARD-005).
- **A2 — Xoá card:** hỏi xác nhận; xác nhận thì card vào Trash trong một
  transaction, mỗi card là **một** batch của riêng nó, cùng một `deleted_at`
  (BR-TRASH-001). Nội dung, study state và history giữ nguyên tới khi purge
  (BR-TRASH-004); phiên `in_progress` có card trong hàng đợi hoặc dùng card làm
  lựa chọn của câu `guess` kết thúc với `content_deleted`. Xoá **một** card thì có
  Undo ngay tại chỗ (BR-TRASH-008); khôi phục về sau qua Trash (UC-TRASH-001).
  Nếu đó là card **cuối cùng** đang active,
  deck atomically trở về `content_type = unset` trong cùng transaction
  (BR-DECK-015, BR-TRASH-005); sau đó người dùng quay về màn hình deck và
  lại chọn được tạo card hay tạo sub-deck. "Deck `card` rỗng" không còn là một
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 57 warning(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_trash_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/features/card/presentation/card_actions_controller_test.dart \
  test/features/card/presentation/card_bulk_actions_test.dart \
  test/features/card/presentation/card_editor_screen_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_session_test.dart \
  test/features/study/data/watch_study_home_test.dart
```

Expected: `+86: All tests passed!`

- [ ] **Step 6: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/card/usecases/UC-CARD-001-quan-ly-card-trong-deck.md \
  lib/features/card/data/datasources/card_dao.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/card/domain/usecases/delete_cards_use_case.dart \
  lib/features/card/presentation/controllers/card_actions_controller.dart \
  test/features/card/data/card_batch_writes_test.dart \
  test/features/card/data/card_trash_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  test/features/card/presentation/card_actions_controller_test.dart \
  test/features/card/presentation/card_bulk_actions_test.dart \
  test/features/card/presentation/card_editor_screen_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_session_test.dart \
  test/features/study/data/watch_study_home_test.dart \
  test/support/study_fixtures.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 7: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 57 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1483: All tests passed!`.

- [ ] **Step 8: Commit**

```bash
git commit -F - <<'EOF'
feat(card): a card delete moves each card to the Trash as its own batch

deleteCards no longer deletes: each card takes a batch of its own, all at
one deleted_at, and the batch ids come back in the order of the ids given
(BR-TRASH-001). The card keeps its schedule, logs and tag links until a
purge; a deck left with no active card is unset; the sessions each batch
touches end as content_deleted (BR-TRASH-004, BR-TRASH-005). The study
tests that settle a session over a card deleted before v3 delete it for
good through a fixture, the only way such a card could go. UC-CARD-001
A2 says what a delete does now.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: The BR-TRASH-002 shape check, and the filters it asks for

**Files:**
- Modify: `lib/core/database/queries/deck_queries.drift`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/srs/data/datasources/srs_dao.dart`, `lib/features/study/data/datasources/study_queue_dao.dart`, `lib/features/study/data/datasources/study_round_dao.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/datasources/study_view_dao.dart`
- Test (create): `test/architecture/tombstone_filter_test.dart`, `test/architecture/tombstone_rules.dart`, `test/architecture/tombstone_rules_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed)

**Interfaces:**
- Consumes: the sources of `lib/`, as text.
- Produces, in `test/architecture/tombstone_rules.dart`:
  - `class TableStatement(String file, String member, List<String> leaks)` with
    `String get key` (`file#member`).
  - `Map<String, String> readQuerySources(Directory projectRoot)`, which leaves out
    files that say `DO NOT MODIFY`.
  - `List<TableStatement> tableStatements(Map<String, String> sources)`,
    `List<String> tombstoneViolations(Map<String, String> sources, Map<String, String> allowlist)`
    and
    `List<String> staleAllowlistEntries(Map<String, String> sources, Map<String, String> allowlist)`.
  - The allowlist `_readsTombstones` of `tombstone_filter_test.dart`, which Tasks 5,
    6 and 8 extend.
- The filters of Clarification 6; no signature changes.

Spec §11, D14; Clarifications 5 and 6. The check reads `lib/` as text: every
statement of the drift files, the SQL of `customSelect`, `customUpdate`,
`customInsert` and `customStatement`, and drift's query builder on `_db.card` and
`_db.deck`. Its own tests plant each case; the run over `lib/` lists the statements
Steps 3–5 filter. Step 7 removes one real filter and watches the check fail.

- [ ] **Step 1: Write the shape check and its own tests**

Create `test/architecture/tombstone_rules.dart`:

```dart
/// BR-TRASH-002 as a text check (trash spec §11): every statement of `lib/`
/// that reads `card` or `deck` leaves the tombstones out, unless an
/// allowlist names it with its reason. `tombstone_rules_test.dart` proves
/// each rule on planted sources; `tombstone_filter_test.dart` applies them
/// to the real `lib/`.
library;

import 'dart:io';

/// A statement of `lib/` that reads `card` or `deck`.
class TableStatement {
  const TableStatement(this.file, this.member, this.leaks);

  /// The repo-relative path, `lib/...`.
  final String file;

  /// The Dart member, or the drift query or trigger, it belongs to.
  final String member;

  /// What reads the tombstones: `card c`, `deck`, or `query builder`.
  /// Empty when every read is filtered.
  final List<String> leaks;

  /// How the allowlist names it.
  String get key => '$file#$member';
}

/// Every `.dart` and `.drift` file under `lib/` of [projectRoot], by
/// repo-relative path. Generated Dart is left out: it repeats what the
/// drift files say.
Map<String, String> readQuerySources(Directory projectRoot) {
  final root = projectRoot.path.replaceAll(r'\', '/');
  return {
    for (final entity in Directory('$root/lib').listSync(recursive: true))
      if (entity is File &&
          (entity.path.endsWith('.dart') || entity.path.endsWith('.drift')))
        if (entity.readAsStringSync() case final text
            when !text.contains(_generated))
          entity.path.replaceAll(r'\', '/').substring(root.length + 1): text,
  };
}

/// What build_runner's and drift_dev's headers both say.
const _generated = 'DO NOT MODIFY';

/// The statements of [sources] that read `card` or `deck`.
List<TableStatement> tableStatements(Map<String, String> sources) => [
  for (final MapEntry(key: path, value: text) in sources.entries)
    ...(path.endsWith('.drift')
        ? driftStatements(path, text)
        : dartStatements(path, text)),
];

/// The statements of [sources] that read tombstones and that [allowlist]
/// does not name, each with what leaks.
List<String> tombstoneViolations(
  Map<String, String> sources,
  Map<String, String> allowlist,
) => [
  for (final statement in tableStatements(sources))
    if (statement.leaks.isNotEmpty && !allowlist.containsKey(statement.key))
      '${statement.key}: ${statement.leaks.join(', ')}',
];

/// The entries of [allowlist] that excuse nothing: the statement is gone,
/// renamed, or filtered now.
List<String> staleAllowlistEntries(
  Map<String, String> sources,
  Map<String, String> allowlist,
) {
  final excused = {
    for (final statement in tableStatements(sources))
      if (statement.leaks.isNotEmpty) statement.key,
  };
  return [
    for (final key in allowlist.keys)
      if (!excused.contains(key)) key,
  ];
}

/// `FROM`, `JOIN` or `UPDATE` with the bare table name, so `card_schedule`
/// and `card_tags` do not count, and its alias when it has one.
final _reference = RegExp(
  r'\b(?:FROM|JOIN|UPDATE)\s+(card|deck)\b'
  r'(?:\s+(?:AS\s+)?(?!(?:WHERE|ON|JOIN|SET|LEFT|INNER|CROSS|NATURAL|GROUP|'
  r'ORDER|LIMIT|UNION|EXCEPT|INTERSECT|AND|OR|USING|WINDOW|HAVING|'
  r'RETURNING)\b)([A-Za-z_]\w*))?',
  caseSensitive: false,
);

/// The reads of [sql] that leave the tombstones in: an aliased table with
/// no `alias.delete_batch_id`, a bare one in a statement that never names
/// `delete_batch_id`.
List<String> unfilteredTables(String sql) => [
  for (final match in _reference.allMatches(sql))
    ?_leak(sql, match.group(1)!, match.group(2)),
];

String? _leak(String sql, String table, String? alias) {
  if (alias == null) return sql.contains('delete_batch_id') ? null : table;
  final filtered = RegExp('\\b$alias\\.delete_batch_id\\b').hasMatch(sql);
  return filtered ? null : '$table $alias';
}

/// A query-builder call on `card` or `deck`: a read, or a join.
final _builder = RegExp(
  r'\b(select|selectOnly|update|delete|innerJoin|leftOuterJoin)\(\s*'
  r'_?db\.(card|deck)\b',
);

/// A builder write addressed by its key, which the write's own reads have
/// checked: BR-TRASH-002 governs reads.
final _byKey = RegExp(r'\.id\.(?:equals|isIn)\(');

/// The SQL of [source], a Dart file, and its query-builder calls, each
/// with the member it is written in.
List<TableStatement> dartStatements(String path, String source) {
  final lines = source.split('\n');
  String memberAt(int offset) =>
      _memberAt(lines, '\n'.allMatches(source.substring(0, offset)).length);
  return [
    for (final (:offset, :text) in stringGroups(source))
      if (_reference.hasMatch(text))
        TableStatement(path, memberAt(offset), unfilteredTables(text)),
    for (final match in _builder.allMatches(source))
      TableStatement(path, memberAt(match.start), _builderLeaks(match, source)),
  ];
}

List<String> _builderLeaks(Match match, String source) {
  final end = source.indexOf(';', match.start);
  final call = source.substring(match.start, end < 0 ? source.length : end);
  final isWrite = match.group(1) == 'update' || match.group(1) == 'delete';
  if (call.contains('deleteBatchId')) return const [];
  if (isWrite && _byKey.hasMatch(call)) return const [];
  return const ['query builder'];
}

/// A declaration at the top level or in a class body: the name before its
/// parameters, its `=>` or its `=`.
final _declaration = RegExp(
  r'^(?:  )?(?![ })\]/@])'
  r'(?!(?:return|await|if|for|while|switch|case|else|throw|yield|assert|var)\b)'
  r'.*?\b(_?[A-Za-z]\w*)\s*(?:<[^()]*?>)?\s*(?:\(|=>|=(?!=))',
);

/// The member line [line] of [lines] is written in: the nearest declaration
/// above it.
String _memberAt(List<String> lines, int line) {
  for (var index = line; index >= 0; index--) {
    if (_declaration.firstMatch(lines[index]) case final match?) {
      return match.group(1)!;
    }
  }
  return '?';
}

/// The string literals of [source] that stand next to each other, joined,
/// with the offset of the first: one group is the text a `customSelect` or
/// a constant holds. An interpolation stays as written, so a fragment it
/// calls in is checked where it is declared.
List<({int offset, String text})> stringGroups(String source) {
  final groups = <({int offset, String text})>[];
  final text = StringBuffer();
  int? start;
  var index = 0;
  while (index < source.length) {
    if (source.startsWith('//', index)) {
      final end = source.indexOf('\n', index);
      index = end < 0 ? source.length : end;
      continue;
    }
    final char = source[index];
    final isRaw =
        char == 'r' &&
        index + 1 < source.length &&
        _isQuote(source[index + 1]) &&
        (index == 0 || !RegExp(r'\w').hasMatch(source[index - 1]));
    if (_isQuote(char) || isRaw) {
      final (end, literal) = _literalAt(source, index);
      start ??= index;
      text.write(literal);
      index = end;
      continue;
    }
    if (char.trim().isNotEmpty && start != null) {
      groups.add((offset: start, text: text.toString()));
      text.clear();
      start = null;
    }
    index++;
  }
  if (start != null) groups.add((offset: start, text: text.toString()));
  return groups;
}

bool _isQuote(String char) => char == "'" || char == '"';

/// The index just past the literal at [start], and what it holds.
(int, String) _literalAt(String source, int start) {
  var index = start;
  final isRaw = source[index] == 'r';
  if (isRaw) index++;
  final quote = source[index];
  final delimiter = source.startsWith(quote * 3, index) ? quote * 3 : quote;
  index += delimiter.length;
  final text = StringBuffer();
  while (index < source.length && !source.startsWith(delimiter, index)) {
    if (!isRaw && source[index] == r'\') {
      text.write(source.substring(index, index + 2));
      index += 2;
    } else if (!isRaw && source.startsWith(r'${', index)) {
      final end = _interpolationEnd(source, index + 2);
      text.write(source.substring(index, end));
      index = end;
    } else {
      text.write(source[index]);
      index++;
    }
  }
  return (index + delimiter.length, text.toString());
}

/// The index just past the `}` that closes an interpolation whose body
/// starts at [start], with the strings and braces inside it.
int _interpolationEnd(String source, int start) {
  var depth = 1;
  var index = start;
  while (index < source.length) {
    final char = source[index];
    if (_isQuote(char)) {
      index = _literalAt(source, index).$1;
      continue;
    }
    if (char == '{') depth++;
    if (char == '}' && --depth == 0) return index + 1;
    index++;
  }
  return index;
}

/// A named query's name, before its parameters, its result class or `:`.
final _queryName = RegExp(
  r'^([A-Za-z_]\w*)\s*(?:\([^)]*\))?\s*(?:AS\s+\w+\s*)?:',
);
final _triggerName = RegExp(r'^CREATE\s+TRIGGER\s+(\w+)', caseSensitive: false);

/// The statements of [source], a drift file, that read `card` or `deck`: a
/// named query by its name, a trigger by its own. Tables and indexes read
/// nothing.
List<TableStatement> driftStatements(String path, String source) {
  final code = [
    for (final line in source.split('\n'))
      line.contains('--') ? line.substring(0, line.indexOf('--')) : line,
  ].join('\n');
  return [
    for (final statement in _driftSplit(code))
      if (_reference.hasMatch(statement))
        TableStatement(
          path,
          (_triggerName.firstMatch(statement) ??
                      _queryName.firstMatch(statement))
                  ?.group(1) ??
              '?',
          unfilteredTables(statement),
        ),
  ];
}

/// [code] cut at each `;` that ends a statement: a trigger's `BEGIN … END`
/// holds its own.
List<String> _driftSplit(String code) {
  final statements = <String>[];
  var current = '';
  for (final part in code.split(';')) {
    current = current.isEmpty ? part : '$current;$part';
    final opened = RegExp(
      r'\bBEGIN\b',
      caseSensitive: false,
    ).allMatches(current).length;
    final closed = RegExp(
      r'\bEND\b',
      caseSensitive: false,
    ).allMatches(current).length;
    if (opened > closed) continue;
    statements.add(current.trim());
    current = '';
  }
  return statements;
}
```

Create `test/architecture/tombstone_filter_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'tombstone_rules.dart';

/// The statements that read tombstones on purpose, by `file#member`, each
/// with its reason (trash spec §11). A statement that reads active content
/// gets the filter, not an entry.
const _readsTombstones = <String, String>{
  'lib/core/database/tables/srs.drift#review_log_no_delete':
      'asks whether the card row is still there, tombstone or not: only a '
      "purge's cascade may delete a review log",
  'lib/features/deck/data/datasources/deck_dao.dart#nextSiblingPosition':
      "D9: a new sibling's position counts the tombstones, so an Undo finds "
      'its place free',
  'lib/features/deck/data/datasources/deck_dao.dart#subtreeHeight':
      "D10: a subtree's height counts the tombstones that move with it",
  'lib/features/deck/data/datasources/deck_dao.dart#moveSubtree':
      'D10: the tombstones of a subtree move with it (BR-TRASH-007)',
  'lib/features/search/data/datasources/search_dao.dart#_cardHits':
      "filtered by `_live`, the search's one predicate (Search spec D8), "
      'which the scan cannot read through',
  'lib/features/search/data/datasources/search_dao.dart#deckForest':
      "filtered by `_live`, the search's one predicate (Search spec D8), "
      'which the scan cannot read through',
  'lib/features/srs/data/datasources/srs_dao.dart#replaceTreeSchedules':
      'D11: a reset or a scheduler change rewrites the schedules of the '
      "tree's tombstones too",
};

/// BR-TRASH-002 over the real `lib/`. Each rule is proven on planted sources
/// in `tombstone_rules_test.dart`.
void main() {
  final sources = readQuerySources(Directory.current);

  test('every read of card or deck leaves the tombstones out, or says why '
      'it reads them (BR-TRASH-002)', () {
    expect(tombstoneViolations(sources, _readsTombstones), isEmpty);
  });

  test('every entry of the allowlist still excuses a statement', () {
    expect(staleAllowlistEntries(sources, _readsTombstones), isEmpty);
  });
}
```

Create `test/architecture/tombstone_rules_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';

import 'tombstone_rules.dart';

/// [sql] as a DAO holds it, in [member] of `lib/x_dao.dart`.
Map<String, String> _dao(String sql, {String member = 'read'}) => {
  'lib/x_dao.dart':
      'final class XDao {\n'
      '  Future<void> $member() => _db.customSelect(\n'
      "    '$sql',\n"
      '  );\n'
      '}\n',
};

void main() {
  group('SQL in Dart', () {
    test('a read of card without the filter is a violation', () {
      final sources = _dao('SELECT id FROM card WHERE id = ?');

      expect(tombstoneViolations(sources, {}), ['lib/x_dao.dart#read: card']);
    });

    test('a read that names delete_batch_id passes', () {
      final sources = _dao(
        'SELECT id FROM card WHERE id = ? AND delete_batch_id IS NULL',
      );

      expect(tombstoneViolations(sources, {}), isEmpty);
    });

    test('each aliased table needs its own filter', () {
      final sources = _dao(
        'SELECT c.id FROM card c JOIN deck d ON d.id = c.deck_id'
        ' WHERE c.delete_batch_id IS NULL',
      );

      expect(tombstoneViolations(sources, {}), ['lib/x_dao.dart#read: deck d']);
    });

    test('card_schedule and card_tags are other tables', () {
      final sources = _dao(
        'SELECT s.card_id FROM card_schedule s JOIN card_tags t'
        ' ON t.card_id = s.card_id',
      );

      expect(tableStatements(sources), isEmpty);
    });

    test('adjacent literals make one statement, an interpolation with its '
        'own quotes included', () {
      const source = r'''
final _hits =
    'SELECT c.id FROM card c'
    ' WHERE ${_live('c')} AND c.front = ?';
''';

      expect(stringGroups(source).map((group) => group.text), [
        r"SELECT c.id FROM card c WHERE ${_live('c')} AND c.front = ?",
      ]);
    });

    test('a statement belongs to the member it is written in', () {
      const source = r'''
final _top = 'SELECT id FROM deck';

final class XDao {
  Future<List<String>> first(String id) async {
    final rows = await _db.customSelect('SELECT id FROM card');
    return rows;
  }

  Stream<int> second() => _db.customSelect('SELECT id FROM deck d');
}
''';

      expect(
        [for (final s in dartStatements('lib/x_dao.dart', source)) s.member],
        ['_top', 'first', 'second'],
      );
    });
  });

  group('the query builder', () {
    Map<String, String> builder(String call) => {
      'lib/x_dao.dart':
          'final class XDao {\n'
          '  Future<void> read(String id) => $call;\n'
          '}\n',
    };

    test('a read without deleteBatchId is a violation', () {
      final sources = builder(
        '(_db.select(_db.card)..where((card) => card.id.equals(id))).get()',
      );

      expect(tombstoneViolations(sources, {}), [
        'lib/x_dao.dart#read: query builder',
      ]);
    });

    test('a read with deleteBatchId passes', () {
      final sources = builder(
        '(_db.select(_db.card)..where((card) => '
        'card.id.equals(id) & card.deleteBatchId.isNull())).get()',
      );

      expect(tombstoneViolations(sources, {}), isEmpty);
    });

    test('a write addressed by its id passes: its reads checked the row', () {
      final sources = builder(
        '(_db.update(_db.deck)..where((deck) => deck.id.equals(id)))'
        '.write(row)',
      );

      expect(tombstoneViolations(sources, {}), isEmpty);
    });
  });

  group('drift files', () {
    test('a named query is named by its name; comments do not count', () {
      const source = '''
import '../tables/deck.drift';

-- The names, FROM deck.
deckNames(:id AS TEXT) AS DeckNameRow:
SELECT d.name FROM deck d WHERE d.id = :id;
''';

      expect(tombstoneViolations({'lib/q.drift': source}, {}), [
        'lib/q.drift#deckNames: deck d',
      ]);
    });

    test("a trigger is named by its own name, with its BEGIN … END", () {
      const source = '''
CREATE TRIGGER t_no_delete BEFORE DELETE ON review_log
BEGIN
  SELECT RAISE(ABORT, 'no') WHERE EXISTS (SELECT 1 FROM card WHERE id = 1);
END;
''';

      expect(tombstoneViolations({'lib/t.drift': source}, {}), [
        'lib/t.drift#t_no_delete: card',
      ]);
    });

    test('tables and indexes read nothing', () {
      const source = '''
CREATE TABLE x (deck_id TEXT REFERENCES deck (id));
CREATE INDEX idx_x ON x (deck_id);
''';

      expect(tableStatements({'lib/t.drift': source}), isEmpty);
    });
  });

  group('the allowlist', () {
    final sources = _dao('SELECT id FROM card', member: 'everything');
    const entry = 'lib/x_dao.dart#everything';

    test('an allowlisted statement passes, and its entry excuses it', () {
      final allowlist = {entry: 'reads the tombstones on purpose'};

      expect(tombstoneViolations(sources, allowlist), isEmpty);
      expect(staleAllowlistEntries(sources, allowlist), isEmpty);
    });

    test('an entry that names no statement is stale', () {
      expect(
        staleAllowlistEntries(sources, {entry: 'x', 'lib/y.dart#z': 'x'}),
        ['lib/y.dart#z'],
      );
    });

    test('an entry whose statement is filtered now is stale', () {
      final filtered = _dao(
        'SELECT id FROM card WHERE delete_batch_id IS NULL',
        member: 'everything',
      );

      expect(staleAllowlistEntries(filtered, {entry: 'x'}), [entry]);
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/architecture/tombstone_rules_test.dart
```

Expected: `+16 -1: Some tests failed.` The scanner's own tests pass: they plant their sources. The run
over `lib/` fails on the twelve statements that read `card` or `deck` without the
filter, `Expected: empty` with:

```text
'lib/features/deck/data/datasources/deck_dao.dart#ancestorIds: deck, deck d',
'lib/features/srs/data/datasources/srs_dao.dart#_ofTree: card c, deck k',
'lib/features/srs/data/datasources/srs_dao.dart#rootOfCard: deck root',
'lib/features/study/data/datasources/study_queue_dao.dart#pendingMeanings: card c',
'lib/features/study/data/datasources/study_round_dao.dart#builtRows: card c',
'lib/features/study/data/datasources/study_session_dao.dart#hasHint: card',
'lib/features/study/data/datasources/study_session_dao.dart#cardRow: query builder',
'lib/features/study/data/datasources/study_view_dao.dart#boardPairs: card c',
'lib/features/study/data/datasources/study_view_dao.dart#cardRow: query builder',
'lib/core/database/queries/deck_queries.drift#deckLevelOfChildren: deck r',
'lib/core/database/queries/deck_queries.drift#deckAndAncestors: deck d',
'lib/core/database/queries/deck_queries.drift#deckMoveTargets: deck r, deck r'
```

Steps 3–5 filter them (Clarification 6). The allowlist's own test passes: each of
its entries already excuses a statement.

- [ ] **Step 3: Filter the deck reads**

In `lib/core/database/queries/deck_queries.drift`:

Replace

```sql
FROM deck d
JOIN deck r ON r.id = d.root_id
LEFT JOIN counts ON counts.tile_id = d.id
```

with

```sql
FROM deck d
JOIN deck r ON r.id = d.root_id AND r.delete_batch_id IS NULL
LEFT JOIN counts ON counts.tile_id = d.id
```

Replace

```sql
  SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id
)
```

with

```sql
  SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id
  WHERE d.delete_batch_id IS NULL
)
```

Replace

```sql
FROM deck d
JOIN deck r ON r.id = d.root_id
JOIN moving m
```

with

```sql
FROM deck d
JOIN deck r ON r.id = d.root_id AND r.delete_batch_id IS NULL
JOIN moving m
```

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart

  /// [id] and every deck above it. Cycle-safe (`UNION`) and never capped, as
  /// schema.md asks of a tree walk.
  Future<List<String>> ancestorIds(String id) async {
```

with

```dart

  /// [id] and every deck above it, while they are active. Cycle-safe
  /// (`UNION`) and never capped, as schema.md asks of a tree walk.
  Future<List<String>> ancestorIds(String id) async {
```

Replace

```dart
          'WITH RECURSIVE up(id, parent_id) AS ('
          ' SELECT id, parent_id FROM deck WHERE id = ?'
          ' UNION SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id'
          ') SELECT id FROM up',
```

with

```dart
          'WITH RECURSIVE up(id, parent_id) AS ('
          ' SELECT id, parent_id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
          ' UNION SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id'
          ' WHERE d.delete_batch_id IS NULL'
          ') SELECT id FROM up',
```

- [ ] **Step 4: Filter the schedule reads**

In `lib/features/srs/data/datasources/srs_dao.dart`:

Replace

```dart
    ' JOIN card c ON c.id = q.card_id JOIN deck k ON k.id = c.deck_id'
    ' WHERE q.session_id = $session.id AND k.root_id = $root))';

```

with

```dart
    ' JOIN card c ON c.id = q.card_id JOIN deck k ON k.id = c.deck_id'
    ' WHERE q.session_id = $session.id AND k.root_id = $root'
    ' AND c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL))';

```

Replace

```dart
          ' WHERE c.id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL',
          variables: [Variable<String>(cardId)],
```

with

```dart
          ' WHERE c.id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL AND root.delete_batch_id IS NULL',
          variables: [Variable<String>(cardId)],
```

- [ ] **Step 5: Filter the study reads**

In `lib/features/study/data/datasources/study_queue_dao.dart`:

Replace

```dart
          'SELECT q.card_id, c.back_folded FROM study_queue_items q'
          ' JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
```

with

```dart
          'SELECT q.card_id, c.back_folded FROM study_queue_items q'
          ' JOIN card c ON c.id = q.card_id AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
```

In `lib/features/study/data/datasources/study_round_dao.dart`:

Replace

```dart
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
```

with

```dart
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
```

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart
  Future<CardRow> cardRow(String id) =>
      (_db.select(_db.card)..where((card) => card.id.equals(id))).getSingle();

```

with

```dart
  Future<CardRow> cardRow(String id) =>
      (_db.select(_db.card)
            ..where((card) => card.id.equals(id) & card.deleteBatchId.isNull()))
          .getSingle();

```

Replace

```dart
        .customSelect(
          'SELECT hint IS NOT NULL AS has_hint FROM card WHERE id = ?',
          variables: [Variable<String>(cardId)],
```

with

```dart
        .customSelect(
          'SELECT hint IS NOT NULL AS has_hint FROM card WHERE id = ?'
          ' AND delete_batch_id IS NULL',
          variables: [Variable<String>(cardId)],
```

In `lib/features/study/data/datasources/study_view_dao.dart`:

Replace

```dart

  Future<CardRow?> cardRow(String cardId) => (_db.select(
    _db.card,
  )..where((card) => card.id.equals(cardId))).getSingleOrNull();

```

with

```dart

  Future<CardRow?> cardRow(String cardId) =>
      (_db.select(_db.card)..where(
            (card) => card.id.equals(cardId) & card.deleteBatchId.isNull(),
          ))
          .getSingleOrNull();

```

Replace

```dart
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
```

with

```dart
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' AND c.delete_batch_id IS NULL'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
```

- [ ] **Step 6: Generate the database code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner` (it warns that `--delete-conflicting-outputs` is ignored).

- [ ] **Step 7: Watch the check catch a filter that goes**

```bash
F=lib/core/database/queries/card_queries.drift
KEEP=$(mktemp) && cp "$F" "$KEEP"
sed -i 's/ AND c\.delete_batch_id IS NULL;/;/' "$F"
git diff --stat -- "$F"
flutter test test/architecture/tombstone_filter_test.dart 2>&1 | grep -E 'card_queries|^[0-9:]+ \+[0-9]+' | tail -3
cp "$KEEP" "$F" && git diff --quiet -- "$F" && echo "card_queries.drift restored"
```

Expected: `git diff --stat` shows one line changed in
`card_queries.drift`; the check then fails, naming
`'lib/core/database/queries/card_queries.drift#cardDetail: card c'`, and the run ends
`+1 -1: Some tests failed.`; then `card_queries.drift restored`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/architecture/tombstone_rules_test.dart
```

Expected: `+17: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/core/database/queries/deck_queries.drift \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/srs/data/datasources/srs_dao.dart \
  lib/features/study/data/datasources/study_queue_dao.dart \
  lib/features/study/data/datasources/study_round_dao.dart \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/datasources/study_view_dao.dart \
  test/architecture/tombstone_filter_test.dart \
  test/architecture/tombstone_rules.dart \
  test/architecture/tombstone_rules_test.dart
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 57 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1500: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
test(arch): every read of card or deck leaves the Trash out, or says why

tombstone_filter_test reads every statement of lib/ as text: the drift
files, the SQL of customSelect, customUpdate, customInsert and
customStatement, and the query builder on card and deck. A statement
that reads card or deck without delete_batch_id fails it, unless the
allowlist names it with its reason (BR-TRASH-002; trash spec §11). The
statements it found that read active content get the filter: the
ancestors and move targets of a deck, the root of a card and a tree's
schedules, and the study reads of a queue, a round and a session.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: A deck comes back from the Trash under the rules of a move, and an Undo takes it back

**Files:**
- Create: `lib/features/deck/data/datasources/deck_tree_data_source.dart`, `lib/features/deck/data/mappers/deck_mapper.dart`, `lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart`
- Modify: `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`, `lib/features/deck/domain/failures/deck_failure.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`, `lib/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test (create): `test/features/deck/data/deck_restore_test.dart`
- Test (modify): `test/architecture/tombstone_filter_test.dart`, `test/features/deck/domain/deck_write_use_cases_test.dart`
- Regenerate: `lib/l10n/generated/` (`flutter gen-l10n`, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's batches and `DeckDao`; `DeckEntity.checkMove`;
  `DeckDao.moveSubtree`, `subtreeHeight`, `ancestorIds`, `nextSiblingPosition`,
  `setSiblingPosition`, `findRow`.
- Produces:
  - `DeckRejection.targetNotFound`, `.targetInTrash`, `.rootRestoresToTopLevel` and
    `.subDeckNeedsParent`, with their cases in `deck_rejection_message_widget.dart` and
    the ARB keys `deckRejectionTargetNotFound`, `deckRejectionTargetInTrash`,
    `deckRejectionRootRestoresToTopLevel` and `deckRejectionSubDeckNeedsParent`.
  - `lib/features/deck/data/mappers/deck_mapper.dart`: `schedulerTypeOf(Deck)`,
    `deckEntityOf(Deck)`, `deckTileOf(DeckTileRow, DateTime)`,
    `deckViewOf(List<Deck>)` and `deckTreeNodeOf(DeckForestRow)`.
  - `DeckTreeDataSource(AppDatabase db)` with
    `Future<DeckRejection?> refusalUnder(Deck target, Deck moving)`,
    `Future<void> moveUnder(Deck target, Deck moving, {required int siblingPosition, required DateTime at})`,
    `Future<DeckRejection> missingTarget(String deckId)` and
    `Future<void> refreshContentType(String deckId, DateTime at)`.
  - In `DeckDao`: `Future<Deck?> itemRootOf(String batchId)`,
    `Future<Deck?> rowInAnyState(String id)`, `Future<bool> isInTrash(String id)` and
    `Future<void> restoreBatch(String batchId)`.
  - `DeckRepository.restoreDecks({required Set<String> batchIds, required String? parentId, DateTime? now})`
    and `DeckRepository.undoDeckDeletion({required String batchId, DateTime? now})`,
    both `Future<Outcome<void, DeckRejection>>`.
  - `UndoDeckDeletionUseCase(DeckRepository)` with
    `Future<Outcome<void, DeckRejection>> call({required String batchId})`.

Spec §7.1, §7.3, D8–D10, D16; Clarifications 7–11 and 13; Review Focus 1,
2 and 4.
Every check runs before any write; one refusal refuses the whole restore. The
allowlist gains `rowInAnyState`: a restore checks an item against its own root,
which may be in the Trash too.

- [ ] **Step 1: Write the failing tests**

In `test/architecture/tombstone_filter_test.dart`:

Replace

```dart
      'D10: the tombstones of a subtree move with it (BR-TRASH-007)',
  'lib/features/search/data/datasources/search_dao.dart#_cardHits':
```

with

```dart
      'D10: the tombstones of a subtree move with it (BR-TRASH-007)',
  'lib/features/deck/data/datasources/deck_dao.dart#rowInAnyState':
      "a restore checks its item against the item's own root, which may be "
      'in the Trash too (BR-TRASH-006)',
  'lib/features/search/data/datasources/search_dao.dart#_cardHits':
```

Create `test/features/deck/data/deck_restore_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRASH-001 steps 5-7 and BR-TRASH-006 to BR-TRASH-008: a deck comes back
// from the Trash under the rules of a move, and an Undo takes it back where
// it was (trash spec §7.1, §7.3).

Matcher _refused(DeckRejection reason) => isA<Rejected<void, DeckRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> delete(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  /// Where [deckId] sits: parent, root, depth, position and batch.
  Future<(String?, String, int, int, String?)> placeOf(String deckId) async {
    final row = await db
        .customSelect(
          'SELECT parent_id, root_id, depth, sibling_position, delete_batch_id'
          ' FROM deck WHERE id = ?',
          variables: [Variable(deckId)],
        )
        .getSingle();
    return (
      row.read<String?>('parent_id'),
      row.read<String>('root_id'),
      row.read<int>('depth'),
      row.read<int>('sibling_position'),
      row.read<String?>('delete_batch_id'),
    );
  }

  Future<int> batchCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
              .getSingle())
          .read<int>('n');

  group('restoreDecks (BR-TRASH-006, BR-TRASH-007)', () {
    test('a sub-deck goes under the chosen deck, last among its children, '
        'with its subtree and cards, and its batch goes', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final grammar = await decks.sub(root.id, 'Grammar');
      await decks.sub(grammar.id, 'Verbs');
      await insertCard(db, id: 'f1', deckId: food.id);
      final batch = await delete(words.id);

      expect(
        await decks.restoreDecks(batchIds: {batch}, parentId: grammar.id),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(words.id), (grammar.id, root.id, 3, 1, null));
      expect(await placeOf(food.id), (words.id, root.id, 4, 0, null));
      expect(await decks.findById(food.id), isNotNull);
      expect(
        (await db
                .customSelect(
                  "SELECT delete_batch_id FROM card WHERE id = 'f1'",
                )
                .getSingle())
            .read<String?>('delete_batch_id'),
        isNull,
      );
      expect(await batchCount(), 0);
    });

    test('an unset target becomes a deck of decks (BR-DECK-015)', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final empty = await decks.sub(root.id, 'Empty');
      final batch = await delete(words.id);

      await decks.restoreDecks(batchIds: {batch}, parentId: empty.id);

      expect((await decks.findById(empty.id))!.contentType.name, 'deck');
    });

    test('a tombstone inside stays in the Trash with its own batch and moves '
        'with its subtree, across roots of one scheduler and generation '
        '(BR-TRASH-003, UC-TRASH-001 A5)', () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final english = await decks.root('English');
      final older = await delete(food.id);
      final newer = await delete(words.id);

      await decks.restoreDecks(batchIds: {newer}, parentId: english.id);

      expect(await placeOf(words.id), (english.id, english.id, 2, 0, null));
      expect(await placeOf(food.id), (words.id, english.id, 3, 0, older));
    });

    test('a sub-deck whose root went to the Trash after it comes back under '
        'a deck of another root of its scheduler and generation', () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final english = await decks.root('English');
      final target = await decks.sub(english.id, 'Target');
      final foodBatch = await delete(food.id);
      final koreanBatch = await delete(korean.id);

      expect(
        await decks.restoreDecks(batchIds: {foodBatch}, parentId: target.id),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(food.id), (target.id, english.id, 3, 0, null));
      expect((await placeOf(words.id)).$5, koreanBatch);
    });

    test('a batch and an older one inside it come back together, the outer '
        'first, each under the chosen deck at its own depth', () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final fruit = await decks.sub(food.id, 'Fruit');
      final english = await decks.root('English');
      final target = await decks.sub(english.id, 'Target');
      final inner = await delete(food.id);
      final outer = await delete(words.id);

      expect(
        await decks.restoreDecks(batchIds: {outer, inner}, parentId: target.id),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(words.id), (target.id, english.id, 3, 0, null));
      expect(await placeOf(food.id), (target.id, english.id, 3, 1, null));
      expect(await placeOf(fruit.id), (food.id, english.id, 4, 0, null));
    });

    test(
      'a root deck goes back to the top level, last among the roots',
      () async {
        final korean = await decks.root('Korean');
        final batch = await delete(korean.id);
        final english = await decks.root('English');

        await decks.restoreDecks(batchIds: {batch}, parentId: null);

        expect(await placeOf(korean.id), (null, korean.id, 1, 2, null));
        expect((await placeOf(english.id)).$4, 1);
      },
    );

    test('several batches come back in the order given', () async {
      final root = await decks.root('Korean');
      final a = await decks.sub(root.id, 'A');
      final b = await decks.sub(root.id, 'B');
      final target = await decks.sub(root.id, 'Target');
      final first = await delete(b.id);
      final second = await delete(a.id);

      await decks.restoreDecks(batchIds: {first, second}, parentId: target.id);

      expect((await placeOf(b.id)).$4, 0);
      expect((await placeOf(a.id)).$4, 1);
    });

    test(
      'each refusal writes nothing, and one refusal refuses them all',
      () async {
        final korean = await decks.root('Korean');
        final words = await decks.sub(korean.id, 'Words');
        final cards = await decks.sub(korean.id, 'Cards');
        await insertCard(db, id: 'c1', deckId: cards.id);
        final gone = await decks.sub(korean.id, 'Gone');
        final sm2 = await decks.root('Other', SchedulerType.sm2);
        var parent = korean.id;
        for (var level = 2; level <= DeckEntity.maxDepth; level++) {
          parent = (await decks.sub(parent, 'L$level')).id;
        }
        final deepest = parent;
        final wordsBatch = await delete(words.id);
        final goneBatch = await delete(gone.id);
        final rootBatch = await delete((await decks.root('Root')).id);
        await insertCard(db, id: 'c2', deckId: cards.id);
        await trashCardRow(db, 'c2', batchId: 'card-batch');
        final before = await totalChanges(db);

        final cases = <(Set<String>, String?, DeckRejection)>[
          ({'missing'}, korean.id, DeckRejection.notFound),
          ({'card-batch'}, korean.id, DeckRejection.notFound),
          ({wordsBatch}, null, DeckRejection.subDeckNeedsParent),
          ({rootBatch}, korean.id, DeckRejection.rootRestoresToTopLevel),
          ({wordsBatch}, gone.id, DeckRejection.targetInTrash),
          ({wordsBatch}, 'missing', DeckRejection.targetNotFound),
          ({wordsBatch}, cards.id, DeckRejection.notADeckContainer),
          ({wordsBatch}, deepest, DeckRejection.depthExceeded),
          ({wordsBatch}, sm2.id, DeckRejection.subtreeSchedulerMismatch),
          (
            {wordsBatch, goneBatch, 'missing'},
            korean.id,
            DeckRejection.notFound,
          ),
        ];
        for (final (batchIds, parentId, reason) in cases) {
          expect(
            await decks.restoreDecks(batchIds: batchIds, parentId: parentId),
            _refused(reason),
            reason: '$reason',
          );
        }
        expect(await totalChanges(db), before);
      },
    );
  });

  group('undoDeckDeletion (BR-TRASH-008)', () {
    test('a sub-deck goes back under its parent at its old position, though '
        'a sibling came after it', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      await decks.sub(words.id, 'Food');
      await decks.sub(root.id, 'Grammar');
      final batch = await delete(words.id);
      await decks.sub(root.id, 'Later');

      expect(
        await decks.undoDeckDeletion(batchId: batch),
        isA<Ok<void, DeckRejection>>(),
      );

      expect(await placeOf(words.id), (root.id, root.id, 2, 0, null));
      expect(await batchCount(), 0);
    });

    test(
      'a root deck goes back to the top level at its old position',
      () async {
        final korean = await decks.root('Korean');
        final batch = await delete(korean.id);
        await decks.root('English');

        await decks.undoDeckDeletion(batchId: batch);

        expect(await placeOf(korean.id), (null, korean.id, 1, 0, null));
      },
    );

    test('refused, typed, when the old place no longer takes it, and nothing '
        'is written', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final lesson = await decks.sub(root.id, 'Lesson');
      final verbs = await decks.sub(lesson.id, 'Verbs');
      final foodBatch = await delete(food.id);
      await delete(words.id);
      final verbsBatch = await delete(verbs.id);
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final before = await totalChanges(db);

      expect(
        await decks.undoDeckDeletion(batchId: foodBatch),
        _refused(DeckRejection.targetInTrash),
      );
      expect(
        await decks.undoDeckDeletion(batchId: verbsBatch),
        _refused(DeckRejection.notADeckContainer),
      );
      expect(
        await decks.undoDeckDeletion(batchId: 'missing'),
        _refused(DeckRejection.notFound),
      );
      expect(await totalChanges(db), before);
    });

    test('a second Undo, or one after the deck came back from the Trash, is '
        'notFound and writes nothing', () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final grammar = await decks.sub(root.id, 'Grammar');
      final undone = await delete(words.id);
      final restored = await delete(grammar.id);
      await decks.undoDeckDeletion(batchId: undone);
      await decks.restoreDecks(batchIds: {restored}, parentId: root.id);
      final before = await totalChanges(db);

      for (final batchId in [undone, restored]) {
        expect(
          await decks.undoDeckDeletion(batchId: batchId),
          _refused(DeckRejection.notFound),
        );
      }
      expect(await totalChanges(db), before);
    });
  });
}
```

In `test/features/deck/domain/deck_write_use_cases_test.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
```

with

```dart
import 'package:memox/features/deck/domain/usecases/reorder_deck_use_case.dart';
import 'package:memox/features/deck/domain/usecases/undo_deck_deletion_use_case.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
```

Replace

```dart
      expect((await decks.findById(root.id))!.schedulerType, SchedulerType.sm2);
    },
  );
}
```

with

```dart
      expect((await decks.findById(root.id))!.schedulerType, SchedulerType.sm2);
    },
  );

  test(
    'Undo right after a delete brings the deck back (BR-TRASH-008)',
    () async {
      final root = _value<DeckEntity>(
        await CreateRootDeckUseCase(decks)(
          name: 'Korean',
          schedulerType: SchedulerType.eightBox,
        ),
      );
      final batchId = _value(await DeleteDeckUseCase(decks)(deckId: root.id));

      expect(
        await UndoDeckDeletionUseCase(decks)(batchId: batchId),
        isA<Ok<void, DeckRejection>>(),
      );
      expect(await decks.findById(root.id), isNotNull);
    },
  );
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/features/deck/data/deck_restore_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart
```

Expected: `+1 -4: Some tests failed.` Neither test file compiles: `Error: The method 'restoreDecks' isn't defined for the type 'DeckRepositoryImpl'.`,
`Error: The method 'undoDeckDeletion' isn't defined for the type 'DeckRepositoryImpl'.`,
`Error: Member not found: 'targetInTrash'.` and
`Error: Method not found: 'UndoDeckDeletionUseCase'.` The allowlist's test fails on
the entry it gains, `Actual: ['lib/features/deck/data/datasources/deck_dao.dart#rowInAnyState']`:
the method does not exist yet. A failed compile can take the next file's load down
with it (`Error: The Dart compiler exited unexpectedly.`); that file's tests then
run on their own.

- [ ] **Step 3: Name the new refusals**

In `lib/features/deck/domain/failures/deck_failure.dart`:

Replace

```dart
  /// A move to the parent the deck already has.
  sameParent,
}
```

with

```dart
  /// A move to the parent the deck already has.
  sameParent,

  /// BR-TRASH-006: the deck a restore is aimed at no longer exists.
  targetNotFound,

  /// BR-TRASH-006, BR-TRASH-008: the deck a restore or an Undo is aimed at
  /// is in the Trash itself.
  targetInTrash,

  /// BR-TRASH-006: a root deck goes back to the top level only.
  rootRestoresToTopLevel,

  /// BR-TRASH-006: a sub-deck goes back under a deck only.
  subDeckNeedsParent,
}
```

In `lib/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart`:

Replace

```dart
    DeckRejection.sameParent => deckRejectionSameParent,
  };
```

with

```dart
    DeckRejection.sameParent => deckRejectionSameParent,
    DeckRejection.targetNotFound => deckRejectionTargetNotFound,
    DeckRejection.targetInTrash => deckRejectionTargetInTrash,
    DeckRejection.rootRestoresToTopLevel => deckRejectionRootRestoresToTopLevel,
    DeckRejection.subDeckNeedsParent => deckRejectionSubDeckNeedsParent,
  };
```

In `lib/l10n/app_en.arb`:

Replace

```json
    "description": "Why a deck write was refused: same parent."
  },
```

with

```json
    "description": "Why a deck write was refused: same parent."
  },
  "deckRejectionTargetNotFound": "That deck no longer exists.",
  "@deckRejectionTargetNotFound": {
    "description": "Why a deck restore was refused: the chosen deck is gone."
  },
  "deckRejectionTargetInTrash": "That deck is in the Trash too.",
  "@deckRejectionTargetInTrash": {
    "description": "Why a deck restore or Undo was refused: the deck it goes to is in the Trash."
  },
  "deckRejectionRootRestoresToTopLevel": "A top-level deck goes back to the top level.",
  "@deckRejectionRootRestoresToTopLevel": {
    "description": "Why a deck restore was refused: a root deck was aimed under a deck."
  },
  "deckRejectionSubDeckNeedsParent": "Choose a deck to put it in.",
  "@deckRejectionSubDeckNeedsParent": {
    "description": "Why a deck restore was refused: a sub-deck was aimed at the top level."
  },
```

In `lib/l10n/app_vi.arb`:

Replace

```json
  "deckRejectionSameParent": "Bộ thẻ đã ở đó rồi.",
  "failureConstraint": "Chưa lưu gì: thay đổi này vi phạm một quy tắc dữ liệu.",
```

with

```json
  "deckRejectionSameParent": "Bộ thẻ đã ở đó rồi.",
  "deckRejectionTargetNotFound": "Bộ thẻ đó không còn nữa.",
  "deckRejectionTargetInTrash": "Bộ thẻ đó cũng đang ở Thùng rác.",
  "deckRejectionRootRestoresToTopLevel": "Bộ thẻ cấp cao nhất chỉ trở về cấp cao nhất.",
  "deckRejectionSubDeckNeedsParent": "Hãy chọn một bộ thẻ để đặt nó vào.",
  "failureConstraint": "Chưa lưu gì: thay đổi này vi phạm một quy tắc dữ liệu.",
```

- [ ] **Step 4: Generate the localizations**

```bash
flutter gen-l10n
```

Expected: nothing is printed, and `lib/l10n/generated/` knows the four new strings.

- [ ] **Step 5: Share the row mapping and the tree writes of a move**

The repository's
private mapping functions move to `deck_mapper.dart` under public names, and what a
move writes to a tree moves to `DeckTreeDataSource`, so a restore and an Undo run
the move's own code (Clarification 7). The repository switches to both in the next
step.

Create `lib/features/deck/data/mappers/deck_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

/// A root's scheduler; null on a sub-deck (BR-DECK-025).
SchedulerType? schedulerTypeOf(Deck row) => switch (row.schedulerType) {
  final String code => SchedulerType.fromCode(code),
  null => null,
};

DeckEntity deckEntityOf(Deck row) => DeckEntity(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  rootId: row.rootId,
  depth: row.depth,
  contentType: DeckContentType.values.byName(row.contentType),
  schedulerType: schedulerTypeOf(row),
  generation: row.generation,
  firstAnsweredAt: row.firstAnsweredAt,
  siblingPosition: row.siblingPosition,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

DeckTile deckTileOf(DeckTileRow row, DateTime startOfToday) => DeckTile(
  id: row.id,
  name: row.name,
  siblingPosition: row.siblingPosition,
  createdAt: row.createdAt,
  schedulerType: SchedulerType.fromCode(row.schedulerType!),
  subDeckCount: row.subDeckCount,
  cardCount: row.cardCount,
  newCount: row.newCount,
  overdueCount: row.overdueCount,
  dueTodayCount: row.dueTodayCount,
  oldestDueAt: row.oldestDueAt,
  startOfToday: startOfToday,
);

/// [rows] run from the root down to the open deck.
DeckView? deckViewOf(List<Deck> rows) {
  if (rows.isEmpty) return null;
  final root = rows.first;
  return DeckView(
    deck: deckEntityOf(rows.last),
    schedulerType: schedulerTypeOf(root)!,
    isSchedulerLocked: root.firstAnsweredAt != null,
    breadcrumb: [
      for (final row in rows.take(rows.length - 1))
        DeckPathEntry(id: row.id, name: row.name),
    ],
  );
}

DeckTreeNode deckTreeNodeOf(DeckForestRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: row.isCandidate,
  contentType: DeckContentType.values.byName(row.contentType),
);
```

Create `lib/features/deck/data/datasources/deck_tree_data_source.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/mappers/deck_mapper.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';

/// The tree writes that several deck writes share, inside the caller's
/// transaction: whether a deck may go under another, putting it there with
/// its subtree, and the content type that follows what a deck holds. A move
/// and a restore ask the same rules (BR-TRASH-006).
final class DeckTreeDataSource {
  DeckTreeDataSource(AppDatabase db) : _dao = DeckDao(db);

  final DeckDao _dao;

  /// Why [moving] may not go under [target], by the rules of a move
  /// (BR-DECK-001, BR-DECK-009, BR-DECK-017, BR-DECK-024): null when it may.
  /// [moving] may be in the Trash, and so may its root: a restore asks this
  /// too (BR-TRASH-006).
  Future<DeckRejection?> refusalUnder(Deck target, Deck moving) async {
    final movingRoot = await _dao.rowInAnyState(moving.rootId);
    final targetRoot = await _dao.findRow(target.rootId);
    if (movingRoot == null || targetRoot == null) {
      return DeckRejection.notFound;
    }
    final rule = DeckEntity.checkMove(
      movingId: moving.id,
      targetParentId: target.id,
      targetAncestorIds: await _dao.ancestorIds(target.id),
      targetDepth: target.depth,
      subtreeHeight: await _dao.subtreeHeight(
        moving.id,
        cap: DeckEntity.maxDepth,
      ),
      targetContentType: DeckContentType.values.byName(target.contentType),
      movingRootScheduler: schedulerTypeOf(movingRoot),
      movingRootGeneration: movingRoot.generation,
      targetRootScheduler: schedulerTypeOf(targetRoot),
      targetRootGeneration: targetRoot.generation,
    );
    return switch (rule) {
      Ok() => null,
      Rejected(:final reason) => reason,
    };
  }

  /// [moving] and its whole subtree under [target] at [siblingPosition]:
  /// the root and depths follow, tombstones inside included (BR-DECK-018,
  /// trash spec D10).
  Future<void> moveUnder(
    Deck target,
    Deck moving, {
    required int siblingPosition,
    required DateTime at,
  }) => _dao.moveSubtree(
    moving.id,
    parentId: target.id,
    rootId: target.rootId,
    depthShift: target.depth + 1 - moving.depth,
    siblingPosition: siblingPosition,
    now: at,
  );

  /// Why [deckId] cannot take a restore: it is in the Trash, or it is gone
  /// (BR-TRASH-006).
  Future<DeckRejection> missingTarget(String deckId) async =>
      await _dao.isInTrash(deckId)
      ? DeckRejection.targetInTrash
      : DeckRejection.targetNotFound;

  /// A sub-deck's content type follows what it holds (BR-DECK-006..008,
  /// BR-DECK-015); a root is always a deck of decks (BR-DECK-004).
  Future<void> refreshContentType(String deckId, DateTime at) async {
    final deck = await _dao.findRow(deckId);
    if (deck == null || deck.parentId == null) return;
    final contentType = await _dao.contentTypeFromChildren(deckId);
    if (contentType == deck.contentType) return;
    await _dao.setContentType(deckId, contentType, at);
  }
}
```

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart
      updates: {_db.card},
      updateKind: UpdateKind.update,
    );
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004;
```

with

```dart
      updates: {_db.card},
      updateKind: UpdateKind.update,
    );
  }

  /// The item root of [batchId] when the batch holds a deck: the deck the
  /// person deleted, still marked with that batch (BR-TRASH-001). Null when
  /// the batch is gone or holds a card.
  Future<Deck?> itemRootOf(String batchId) async {
    final row = await _db
        .customSelect(
          'SELECT d.* FROM delete_batches b JOIN deck d ON d.id = b.root_item_id'
          " AND d.delete_batch_id = b.id WHERE b.id = ? AND b.item_type = 'deck'",
          variables: [Variable<String>(batchId)],
          readsFrom: {_db.deleteBatches, _db.deck},
        )
        .getSingleOrNull();
    return row == null ? null : _db.deck.map(row.data);
  }

  /// [id]'s row, active or in the Trash: a restore checks its item against
  /// the item's own root, which may be in the Trash too (BR-TRASH-006).
  Future<Deck?> rowInAnyState(String id) => (_db.select(
    _db.deck,
  )..where((deck) => deck.id.equals(id))).getSingleOrNull();

  /// Whether [id] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006).
  Future<bool> isInTrash(String id) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM deck WHERE id = ?'
          ' AND delete_batch_id IS NOT NULL) AS in_trash',
          variables: [Variable<String>(id)],
          readsFrom: {_db.deck},
        )
        .getSingle();
    return row.read<bool>('in_trash');
  }

  /// The rows of [batchId], decks and cards, lose their mark; then the batch
  /// row goes, which the key would otherwise cascade (BR-TRASH-007).
  Future<void> restoreBatch(String batchId) async {
    await _db.customUpdate(
      'UPDATE deck SET delete_batch_id = NULL WHERE delete_batch_id = ?',
      variables: [Variable<String>(batchId)],
      updates: {_db.deck},
      updateKind: UpdateKind.update,
    );
    await _db.customUpdate(
      'UPDATE card SET delete_batch_id = NULL WHERE delete_batch_id = ?',
      variables: [Variable<String>(batchId)],
      updates: {_db.card},
      updateKind: UpdateKind.update,
    );
    await (_db.delete(
      _db.deleteBatches,
    )..where((batch) => batch.id.equals(batchId))).go();
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004;
```

- [ ] **Step 6: Restore and undo a deck deletion**

`deck_repository_impl.dart` changes
throughout: the move calls `DeckTreeDataSource`, the mapping functions leave its
end, and the restore and the Undo join it; the whole file follows.

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart

  Future<DeckEntity?> findById(String id);
```

with

```dart

  /// UC-TRASH-001 steps 5-7: the decks of [batchIds] come back under
  /// [parentId], or to the top level when it is null, each last among its
  /// new siblings, in the order given, all or none. A root deck goes back to
  /// the top level only, a sub-deck under a deck only, and each passes the
  /// rules of a move (BR-TRASH-006, BR-TRASH-007).
  Future<Outcome<void, DeckRejection>> restoreDecks({
    required Set<String> batchIds,
    required String? parentId,
    DateTime? now,
  });

  /// BR-TRASH-008: the deck of [batchId] goes back where it was, at its old
  /// position; refused, typed, when that place no longer takes it.
  Future<Outcome<void, DeckRejection>> undoDeckDeletion({
    required String batchId,
    DateTime? now,
  });

  Future<DeckEntity?> findById(String id);
```

Replace the whole of `lib/features/deck/data/repositories/deck_repository_impl.dart` with:

```dart
import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/data/datasources/deck_dao.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/mappers/deck_mapper.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_deletion_summary_model.dart';
import 'package:memox/features/deck/domain/models/deck_level_model.dart';
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/deck/domain/models/deck_view_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';

/// Every write reads the rows its rules need and writes inside one
/// transaction, so a rule never judges data another write has changed.
final class DeckRepositoryImpl implements DeckRepository {
  DeckRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = DeckDao(_db),
      _tree = DeckTreeDataSource(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final DeckDao _dao;
  final DeckTreeDataSource _tree;
  final DateTime Function() _now;

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createRootDeck({
    required String name,
    required SchedulerType schedulerType,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      final id = newId();
      await _dao.insert(
        DeckCompanion.insert(
          id: id,
          name: name.trim(),
          rootId: id,
          depth: 1,
          contentType: Value(DeckContentType.deck.name),
          schedulerType: Value(schedulerType.code),
          schedulerVersion: Value(schedulerFor(schedulerType).version),
          generation: const Value(1),
          siblingPosition: await _dao.nextSiblingPosition(null),
          createdAt: at,
          updatedAt: at,
        ),
      );
      return Ok(deckEntityOf((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<DeckEntity, DeckRejection>> createSubDeck({
    required String parentId,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      final parent = await _dao.findRow(parentId);
      if (parent == null) return const Rejected(DeckRejection.notFound);
      final rule = DeckEntity.checkCreateSubDeck(
        parentDepth: parent.depth,
        parentContentType: DeckContentType.values.byName(parent.contentType),
      );
      if (_refusal(rule) case final reason?) return Rejected(reason);

      final id = newId();
      await _dao.insert(
        DeckCompanion.insert(
          id: id,
          name: name.trim(),
          parentId: Value(parentId),
          rootId: parent.rootId,
          depth: parent.depth + 1,
          contentType: Value(DeckContentType.unset.name),
          siblingPosition: await _dao.nextSiblingPosition(parentId),
          createdAt: at,
          updatedAt: at,
        ),
      );
      await _tree.refreshContentType(parentId, at);
      return Ok(deckEntityOf((await _dao.findRow(id))!));
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> moveDeck({
    required String deckId,
    required String newParentId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final moving = await _dao.findRow(deckId);
      final target = await _dao.findRow(newParentId);
      if (moving == null || target == null) {
        return const Rejected(DeckRejection.notFound);
      }
      final oldParentId = moving.parentId;
      if (oldParentId == null) {
        return const Rejected(DeckRejection.rootCannotMove);
      }
      if (oldParentId == newParentId) {
        return const Rejected(DeckRejection.sameParent);
      }
      if (await _tree.refusalUnder(target, moving) case final reason?) {
        return Rejected(reason);
      }

      await _tree.moveUnder(
        target,
        moving,
        siblingPosition: await _dao.nextSiblingPosition(newParentId),
        at: at,
      );
      await _tree.refreshContentType(oldParentId, at);
      await _tree.refreshContentType(newParentId, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> renameDeck({
    required String deckId,
    required String name,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (_refusal(DeckEntity.checkName(name)) case final reason?) {
        return Rejected(reason);
      }
      if (await _dao.findRow(deckId) == null) {
        return const Rejected(DeckRejection.notFound);
      }
      await _dao.rename(deckId, name.trim(), at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> reorderDeck({
    required String deckId,
    required String anchorId,
    required DeckPlacement placement,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final deck = await _dao.findRow(deckId);
      final anchor = await _dao.findRow(anchorId);
      if (deck == null || anchor == null) {
        return const Rejected(DeckRejection.notFound);
      }
      if (deck.parentId != anchor.parentId) {
        return const Rejected(DeckRejection.notSiblings);
      }
      final siblings = await _dao.siblingRows(deck.parentId);
      final order = DeckEntity.reorder(
        [for (final row in siblings) row.id],
        movingId: deckId,
        anchorId: anchorId,
        placement: placement,
      );
      final positionOf = {
        for (final row in siblings) row.id: row.siblingPosition,
      };
      for (final (position, id) in order.indexed) {
        if (positionOf[id] == position) continue;
        await _dao.setSiblingPosition(id, position, at);
      }
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<DeckDeletionSummary, DeckRejection>> deletionSummary(
    String deckId,
  ) => _mapped(() async {
    final row = await _dao.deletionSummary(deckId);
    if (row == null) return const Rejected(DeckRejection.notFound);
    return Ok(
      DeckDeletionSummary(
        subDeckCount: row.subDeckCount,
        cardCount: row.cardCount,
      ),
    );
  });

  @override
  Future<Outcome<String, DeckRejection>> deleteDeck({
    required String deckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final deck = await _dao.findRow(deckId);
      if (deck == null) return const Rejected(DeckRejection.notFound);
      // The rows stay where they are, marked: only a purge deletes them, by
      // cascade (BR-DECK-022, BR-TRASH-010).
      final batchId = newId();
      await _dao.insertBatch(batchId, deckId, at);
      await _dao.markSubtree(deckId, batchId);
      if (deck.parentId case final parentId?) {
        await _tree.refreshContentType(parentId, at);
      }
      await _dao.closeSessionsTouching(batchId, at);
      return Ok(batchId);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> restoreDecks({
    required Set<String> batchIds,
    required String? parentId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final items = <String, Deck>{};
      for (final batchId in batchIds) {
        final item = await _dao.itemRootOf(batchId);
        if (item == null) return const Rejected(DeckRejection.notFound);
        items[batchId] = item;
      }
      if (parentId == null) {
        if (items.values.any((item) => item.parentId != null)) {
          return const Rejected(DeckRejection.subDeckNeedsParent);
        }
        for (final MapEntry(key: batchId, value: item) in items.entries) {
          await _dao.restoreBatch(batchId);
          final position = await _dao.nextSiblingPosition(null);
          await _dao.setSiblingPosition(item.id, position, at);
        }
        return const Ok(null);
      }
      if (items.values.any((item) => item.parentId == null)) {
        return const Rejected(DeckRejection.rootRestoresToTopLevel);
      }
      final target = await _dao.findRow(parentId);
      if (target == null) return Rejected(await _tree.missingTarget(parentId));
      for (final item in items.values) {
        if (await _tree.refusalUnder(target, item) case final reason?) {
          return Rejected(reason);
        }
      }
      for (final MapEntry(key: batchId, value: item) in items.entries) {
        await _dao.restoreBatch(batchId);
        // Read again: an item restored before it may have carried it along,
        // when this batch lies inside that one (D10).
        await _tree.moveUnder(
          target,
          (await _dao.findRow(item.id))!,
          siblingPosition: await _dao.nextSiblingPosition(target.id),
          at: at,
        );
      }
      await _tree.refreshContentType(target.id, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, DeckRejection>> undoDeckDeletion({
    required String batchId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final item = await _dao.itemRootOf(batchId);
      if (item == null) return const Rejected(DeckRejection.notFound);
      final parentId = item.parentId;
      if (parentId == null) {
        await _dao.restoreBatch(batchId);
        return const Ok(null);
      }
      final target = await _dao.findRow(parentId);
      if (target == null) return Rejected(await _tree.missingTarget(parentId));
      if (await _tree.refusalUnder(target, item) case final reason?) {
        return Rejected(reason);
      }
      await _dao.restoreBatch(batchId);
      // Its old place: nothing took that position, since a new sibling's
      // position counts the tombstones (trash spec D9).
      await _tree.moveUnder(
        target,
        item,
        siblingPosition: item.siblingPosition,
        at: at,
      );
      await _tree.refreshContentType(target.id, at);
      return const Ok(null);
    });
  }

  @override
  Future<DeckEntity?> findById(String id) => _mapped(() async {
    final row = await _dao.findRow(id);
    return row == null ? null : deckEntityOf(row);
  });

  @override
  Stream<List<DeckTile>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) => _dao
      .watchLevel(parentId: parentId, now: now, startOfToday: startOfToday)
      .map((rows) => [for (final row in rows) deckTileOf(row, startOfToday)])
      .mapDatabaseErrors();

  @override
  Stream<DeckView?> watchDeck(String deckId) =>
      _dao.watchDeckAndAncestors(deckId).map(deckViewOf).mapDatabaseErrors();

  @override
  Stream<List<DeckMoveTarget>> watchMoveTargets(String deckId) => _dao
      .watchMoveTargetRows(deckId, maxDepth: DeckEntity.maxDepth)
      .map(
        (rows) => candidatesInTreeOrder(
          [for (final row in rows) deckTreeNodeOf(row)],
          (node, path) =>
              DeckMoveTarget(id: node.id, name: node.name, path: path),
        ),
      )
      .mapDatabaseErrors();

  @override
  Stream<List<DeckSearchHit>> watchSearch({
    required String? scopeDeckId,
    required String foldedTerm,
  }) => _dao
      .watchSearchRows(scopeDeckId)
      .map(
        (rows) => [
          for (final hit in candidatesInTreeOrder(
            [for (final row in rows) deckTreeNodeOf(row)],
            (node, path) => DeckSearchHit(
              id: node.id,
              name: node.name,
              path: path,
              contentType: node.contentType,
            ),
          ))
            if (foldText(hit.name).contains(foldedTerm)) hit,
        ],
      )
      .mapDatabaseErrors();

  /// One transaction; see [_mapped] for what leaves it on an error.
  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  /// An unexpected database error leaves as the [Failure] `mapDatabaseError`
  /// makes of it, with its stack trace. A transaction has rolled back by then.
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

DeckRejection? _refusal(Outcome<void, DeckRejection> check) => switch (check) {
  Ok() => null,
  Rejected(:final reason) => reason,
};
```

Create `lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// BR-TRASH-008: the deck deleted a moment ago goes back where it was, or
/// the reason it cannot.
final class UndoDeckDeletionUseCase {
  const UndoDeckDeletionUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({required String batchId}) =>
      _decks.undoDeckDeletion(batchId: batchId);
}
```

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 56 warning(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/features/deck/data/deck_restore_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart
```

Expected: `+17: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/deck/data/datasources/deck_tree_data_source.dart \
  lib/features/deck/data/mappers/deck_mapper.dart \
  lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/failures/deck_failure.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart \
  lib/features/deck/presentation/widgets/support/deck_rejection_message_widget.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/architecture/tombstone_filter_test.dart \
  test/features/deck/data/deck_restore_test.dart \
  test/features/deck/domain/deck_write_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 56 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1513: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
feat(deck): restore a deck from the Trash, and undo its deletion

restoreDecks brings the decks of the chosen batches back, all or none: a
root to the top level only, a sub-deck under an active deck only, each
through DeckEntity.checkMove against its own root's scheduler and
generation, last among its new siblings, its subtree's root and depth
rewritten, tombstones inside included (BR-TRASH-006, BR-TRASH-007;
trash spec D8, D10). undoDeckDeletion puts one batch back where it was,
at its old position, or refuses with a typed reason (BR-TRASH-008; D9).
DeckRejection gains targetNotFound, targetInTrash,
rootRestoresToTopLevel and subDeckNeedsParent, with their messages (D16).
The row mapping and the tree writes a move and a restore share leave the
repository for a mapper and a data source.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: A card comes back from the Trash into a deck of its root, and an Undo takes it back

**Files:**
- Create: `lib/features/card/domain/usecases/undo_card_deletion_use_case.dart`
- Modify: `lib/core/database/queries/trash_queries.drift`, `lib/features/card/data/datasources/card_dao.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `lib/features/card/domain/entities/card_entity.dart`, `lib/features/card/domain/failures/card_failure.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/card/presentation/widgets/support/card_rejection_message_widget.dart`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test (create): `test/features/card/data/card_restore_test.dart`
- Test (modify): `test/architecture/tombstone_filter_test.dart`, `test/features/card/domain/card_entity_test.dart`, `test/features/card/domain/card_write_use_cases_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `lib/l10n/generated/` (`flutter gen-l10n`, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 3's batches and `CardDao`; `CardEntity.checkMove`; Task 5's
  pattern and `DeckDao.isInTrash`.
- Produces:
  - `static Outcome<void, CardRejection> CardEntity.checkTarget({required String targetRootId, required bool targetIsRoot, required DeckContentType targetContentType, required Set<String> sourceRootIds})`;
    `checkMove` refuses `sameDeck`, then asks it.
  - `CardRejection.targetInTrash`, with its case in
    `card_rejection_message_widget.dart` and the ARB key `cardRejectionTargetInTrash`.
  - `deckIsInTrash(:deck_id)` in `trash_queries.drift`, generated as
    `Selectable<bool> AppDatabase.deckIsInTrash(String deckId)`; `DeckDao.isInTrash`
    reads it.
  - In `CardDao`: `Future<CardRow?> itemOf(String batchId)`,
    `Future<Set<String>> rootIdsOf(Set<String> deckIds)`,
    `Future<bool> isDeckInTrash(String deckId)` and
    `Future<void> restoreFromBatch(String batchId, String cardId, {required String deckId, DateTime? updatedAt})`.
  - `CardRepository.restoreCards({required Set<String> batchIds, required String deckId, DateTime? now})`
    and `CardRepository.undoCardDeletion({required String batchId, DateTime? now})`,
    both `Future<Outcome<void, CardRejection>>`.
  - `UndoCardDeletionUseCase(CardRepository)` with
    `Future<Outcome<void, CardRejection>> call({required String batchId})`.

Spec §7.2, §7.3, D8, D9, D16; Clarification 13; Review Focus 3 and 4. A card's
root is its deck's `root_id`, tombstone or not; the allowlist gains `rootIdsOf`,
which reads it.

- [ ] **Step 1: Write the failing tests**

In `test/architecture/tombstone_filter_test.dart`:

Replace

```dart
      "purge's cascade may delete a review log",
  'lib/features/deck/data/datasources/deck_dao.dart#nextSiblingPosition':
```

with

```dart
      "purge's cascade may delete a review log",
  'lib/features/card/data/datasources/card_dao.dart#rootIdsOf':
      'a restore checks a card against the root of its deck, which may be in '
      'the Trash (BR-TRASH-006)',
  'lib/features/deck/data/datasources/deck_dao.dart#nextSiblingPosition':
```

Create `test/features/card/data/card_restore_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TRASH-001 steps 5-7 and BR-TRASH-006 to BR-TRASH-008: a card comes back
// from the Trash into a deck of its root, and an Undo takes it back where it
// was (trash spec §7.2, §7.3).

Matcher _refused(CardRejection reason) => isA<Rejected<void, CardRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<List<String>> delete(Set<String> cardIds) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await cards.deleteCards(
      cardIds: cardIds,
    )) as Ok<List<String>, CardRejection>).value;
  }

  Future<String> deleteDeck(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  /// Where [cardId] sits: its deck, its batch and its updated_at.
  Future<(String, String?, DateTime)> placeOf(String cardId) async {
    final row = await db
        .customSelect(
          'SELECT deck_id, delete_batch_id, updated_at FROM card WHERE id = ?',
          variables: [Variable(cardId)],
        )
        .getSingle();
    return (
      row.read<String>('deck_id'),
      row.read<String?>('delete_batch_id'),
      row.read<DateTime>('updated_at'),
    );
  }

  Future<DeckContentType> contentTypeOf(String deckId) async =>
      (await decks.findById(deckId))!.contentType;

  group('restoreCards (BR-TRASH-006, BR-TRASH-007)', () {
    test(
      'the cards go into the chosen deck of their root, stamped as a move '
      'stamps them, and their batches go; an unset target takes cards',
      () async {
        final root = await decks.root('Korean');
        final lesson = await decks.sub(root.id, 'Lesson');
        final empty = await decks.sub(root.id, 'Empty');
        await insertCard(db, id: 'c1', deckId: lesson.id);
        await insertCard(db, id: 'c2', deckId: lesson.id);
        final batchIds = await delete({'c1', 'c2'});
        clock = clock.add(const Duration(minutes: 1));

        expect(
          await cards.restoreCards(
            batchIds: batchIds.toSet(),
            deckId: empty.id,
          ),
          isA<Ok<void, CardRejection>>(),
        );

        expect(await placeOf('c1'), (empty.id, null, clock));
        expect(await placeOf('c2'), (empty.id, null, clock));
        expect(await contentTypeOf(empty.id), DeckContentType.card);
        expect(await contentTypeOf(lesson.id), DeckContentType.unset);
        expect(
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM delete_batches')
                  .getSingle())
              .read<int>('n'),
          0,
        );
      },
    );

    test('a card whose deck is in the Trash too comes back into another deck '
        'of the same root', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      final other = await decks.sub(root.id, 'Other');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final [batchId] = await delete({'c1'});
      await deleteDeck(lesson.id);

      expect(
        await cards.restoreCards(batchIds: {batchId}, deckId: other.id),
        isA<Ok<void, CardRejection>>(),
      );
      expect((await placeOf('c1')).$1, other.id);
    });

    test('a card in the Trash through a reset that changed the scheduler '
        "comes back at its root's generation, under the new scheduler "
        '(trash spec D11)', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(
        db,
        id: 'c1',
        deckId: lesson.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
      await insertCard(db, id: 'c2', deckId: lesson.id);
      await lockScheduler(db, root.id);
      final [batchId] = await delete({'c1'});
      await ScheduleRepositoryImpl(
        db,
        now: () => clock,
      ).resetLearning(rootDeckId: root.id, schedulerType: SchedulerType.sm2);

      expect(
        await cards.restoreCards(batchIds: {batchId}, deckId: lesson.id),
        isA<Ok<void, CardRejection>>(),
      );

      final schedule = await db
          .customSelect(
            'SELECT scheduler_type, generation, learned_at FROM card_schedule'
            " WHERE card_id = 'c1'",
          )
          .getSingle();
      expect(
        (
          schedule.read<String>('scheduler_type'),
          schedule.read<int>('generation'),
          schedule.read<DateTime?>('learned_at'),
        ),
        ('sm2', 2, null),
      );
    });

    test(
      'each refusal writes nothing, and one refusal refuses them all',
      () async {
        final root = await decks.root('Korean');
        final lesson = await decks.sub(root.id, 'Lesson');
        final parent = await decks.sub(root.id, 'Parent');
        await decks.sub(parent.id, 'Child');
        final trashed = await decks.sub(root.id, 'Trashed');
        final english = await decks.root('English');
        final words = await decks.sub(english.id, 'Words');
        await insertCard(db, id: 'c1', deckId: lesson.id);
        await insertCard(db, id: 'c2', deckId: lesson.id);
        final [batchId] = await delete({'c1'});
        final deckBatch = await deleteDeck(trashed.id);
        final before = await totalChanges(db);

        final cases = <(Set<String>, String, CardRejection)>[
          ({'missing'}, lesson.id, CardRejection.notFound),
          ({deckBatch}, lesson.id, CardRejection.notFound),
          ({batchId}, trashed.id, CardRejection.targetInTrash),
          ({batchId}, 'missing', CardRejection.targetNotFound),
          ({batchId}, root.id, CardRejection.targetIsRoot),
          ({batchId}, parent.id, CardRejection.targetHoldsDecks),
          ({batchId}, words.id, CardRejection.crossRootMove),
          ({batchId, 'missing'}, lesson.id, CardRejection.notFound),
        ];
        for (final (batchIds, deckId, reason) in cases) {
          expect(
            await cards.restoreCards(batchIds: batchIds, deckId: deckId),
            _refused(reason),
            reason: '$reason',
          );
        }
        expect(await totalChanges(db), before);
      },
    );
  });

  group('undoCardDeletion (BR-TRASH-008)', () {
    test('a card goes back into its deck with its updated_at kept, and the '
        'deck takes cards again', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final updatedAt = (await placeOf('c1')).$3;
      final [batchId] = await delete({'c1'});
      expect(await contentTypeOf(lesson.id), DeckContentType.unset);

      expect(
        await cards.undoCardDeletion(batchId: batchId),
        isA<Ok<void, CardRejection>>(),
      );

      expect(await placeOf('c1'), (lesson.id, null, updatedAt));
      expect(await contentTypeOf(lesson.id), DeckContentType.card);
    });

    test('refused, typed, when its deck is in the Trash or holds decks now, '
        'and nothing is written', () async {
      final root = await decks.root('Korean');
      final gone = await decks.sub(root.id, 'Gone');
      final grown = await decks.sub(root.id, 'Grown');
      await insertCard(db, id: 'c1', deckId: gone.id);
      await insertCard(db, id: 'c2', deckId: grown.id);
      final [first] = await delete({'c1'});
      await deleteDeck(gone.id);
      final [second] = await delete({'c2'});
      await decks.sub(grown.id, 'Child');
      final before = await totalChanges(db);

      expect(
        await cards.undoCardDeletion(batchId: first),
        _refused(CardRejection.targetInTrash),
      );
      expect(
        await cards.undoCardDeletion(batchId: second),
        _refused(CardRejection.targetHoldsDecks),
      );
      expect(
        await cards.undoCardDeletion(batchId: 'missing'),
        _refused(CardRejection.notFound),
      );
      expect(await totalChanges(db), before);
    });

    test('a second Undo, or one after the card came back from the Trash, is '
        'notFound and writes nothing', () async {
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      await insertCard(db, id: 'c2', deckId: lesson.id);
      final [undone] = await delete({'c1'});
      final [restored] = await delete({'c2'});
      await cards.undoCardDeletion(batchId: undone);
      await cards.restoreCards(batchIds: {restored}, deckId: lesson.id);
      final before = await totalChanges(db);

      for (final batchId in [undone, restored]) {
        expect(
          await cards.undoCardDeletion(batchId: batchId),
          _refused(CardRejection.notFound),
        );
      }
      expect(await totalChanges(db), before);
    });
  });
}
```

In `test/features/card/domain/card_entity_test.dart`:

Replace

```dart
        CardRejection.crossRootMove,
      );
    });
  });
}
```

with

```dart
        CardRejection.crossRootMove,
      );
    });
  });

  group('checkTarget (BR-CARD-010, BR-TRASH-006)', () {
    Outcome<void, CardRejection> check({
      bool targetIsRoot = false,
      DeckContentType targetContentType = DeckContentType.unset,
      Set<String> sourceRootIds = const {'root'},
    }) => CardEntity.checkTarget(
      targetRootId: 'root',
      targetIsRoot: targetIsRoot,
      targetContentType: targetContentType,
      sourceRootIds: sourceRootIds,
    );

    CardRejection reasonOf(Outcome<void, CardRejection> result) =>
        (result as Rejected<void, CardRejection>).reason;

    test(
      'a sub-deck of the cards\' root holding cards or nothing takes them',
      () {
        expect(check(), isA<Ok<void, CardRejection>>());
        expect(
          check(targetContentType: DeckContentType.card),
          isA<Ok<void, CardRejection>>(),
        );
      },
    );

    test('a root, a deck of decks and a deck of another root are refused', () {
      expect(reasonOf(check(targetIsRoot: true)), CardRejection.targetIsRoot);
      expect(
        reasonOf(check(targetContentType: DeckContentType.deck)),
        CardRejection.targetHoldsDecks,
      );
      expect(
        reasonOf(check(sourceRootIds: {'root', 'twin'})),
        CardRejection.crossRootMove,
      );
    });
  });
}
```

In `test/features/card/domain/card_write_use_cases_test.dart`:

Replace

```dart
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
```

with

```dart
import 'package:memox/features/card/domain/usecases/set_cards_flagged_use_case.dart';
import 'package:memox/features/card/domain/usecases/undo_card_deletion_use_case.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
```

Replace

```dart

import '../../../support/deck_fixtures.dart';
```

with

```dart

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
```

Replace

```dart
        DeckContentType.card,
      );
    },
  );
}
```

with

```dart
        DeckContentType.card,
      );
    },
  );

  test(
    'Undo right after a delete brings the card back (BR-TRASH-008)',
    () async {
      DateTime now() => DateTime(2026, 9, 23);
      final decks = DeckRepositoryImpl(db, now: now);
      final cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: now),
        TagRepositoryImpl(db, now: now),
        now: now,
      );
      final lesson = await decks.sub((await decks.root('Korean')).id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id);
      final deleted = await DeleteCardsUseCase(cards)(cardIds: {'c1'});
      final [batchId] = (deleted as Ok<List<String>, CardRejection>).value;

      expect(
        await UndoCardDeletionUseCase(cards)(batchId: batchId),
        isA<Ok<void, CardRejection>>(),
      );
      expect(await cards.watchDetail('c1').first, isNotNull);
    },
  );
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/features/card/data/card_restore_test.dart \
  test/features/card/domain/card_entity_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart
```

Expected: `+1 -5: Some tests failed.` The test files do not compile:
`Error: The method 'restoreCards' isn't defined for the type 'CardRepositoryImpl'.`,
`Error: The method 'undoCardDeletion' isn't defined for the type 'CardRepositoryImpl'.`,
`Error: Member not found: 'targetInTrash'.`,
`Error: Member not found: 'CardEntity.checkTarget'.` and
`Error: Error when reading 'lib/features/card/domain/usecases/undo_card_deletion_use_case.dart': No such file or directory`.
The allowlist's test fails on the entry it gains,
`Actual: ['lib/features/card/data/datasources/card_dao.dart#rootIdsOf']`. As in Task
5, a failed compile can take the next file's load down with it.

- [ ] **Step 3: Split the target rules out of a card move**

In `lib/features/card/domain/entities/card_entity.dart`:

Replace

```dart
  }) {
    if (targetIsRoot) return const Rejected(CardRejection.targetIsRoot);
```

with

```dart
  }) {
    if (sourceDeckIds.contains(targetDeckId)) {
      return const Rejected(CardRejection.sameDeck);
    }
    return checkTarget(
      targetRootId: targetRootId,
      targetIsRoot: targetIsRoot,
      targetContentType: targetContentType,
      sourceRootIds: sourceRootIds,
    );
  }

  /// BR-CARD-010, BR-TRASH-006: whether a deck can hold cards of
  /// [sourceRootIds]: a sub-deck of their root that holds cards or nothing.
  /// A move and a restore both ask it; only a move refuses the deck a card is
  /// in, since a restore may put a card back where it was.
  static Outcome<void, CardRejection> checkTarget({
    required String targetRootId,
    required bool targetIsRoot,
    required DeckContentType targetContentType,
    required Set<String> sourceRootIds,
  }) {
    if (targetIsRoot) return const Rejected(CardRejection.targetIsRoot);
```

Replace

```dart
      return const Rejected(CardRejection.targetHoldsDecks);
    }
    if (sourceDeckIds.contains(targetDeckId)) {
      return const Rejected(CardRejection.sameDeck);
    }
```

with

```dart
      return const Rejected(CardRejection.targetHoldsDecks);
    }
```

- [ ] **Step 4: Name the new refusal**

In `lib/features/card/domain/failures/card_failure.dart`:

Replace

```dart
  crossRootMove,
}
```

with

```dart
  crossRootMove,

  /// BR-TRASH-006, BR-TRASH-008: the deck a restore or an Undo is aimed at
  /// is in the Trash itself.
  targetInTrash,
}
```

In `lib/features/card/presentation/widgets/support/card_rejection_message_widget.dart`:

Replace

```dart
    CardRejection.crossRootMove => cardRejectionCrossRootMove,
  };
```

with

```dart
    CardRejection.crossRootMove => cardRejectionCrossRootMove,
    CardRejection.targetInTrash => cardRejectionTargetInTrash,
  };
```

In `lib/l10n/app_en.arb`:

Replace

```json
    "description": "Card move refusal: another root."
  },
```

with

```json
    "description": "Card move refusal: another root."
  },
  "cardRejectionTargetInTrash": "That deck is in the Trash.",
  "@cardRejectionTargetInTrash": {
    "description": "Card restore or Undo refusal: the deck it goes to is in the Trash."
  },
```

In `lib/l10n/app_vi.arb`:

Replace

```json
  "cardRejectionCrossRootMove": "Thẻ chỉ di chuyển được trong cùng một bộ thẻ cấp cao nhất.",
  "tagRejectionBlankName": "Hãy nhập tên nhãn.",
```

with

```json
  "cardRejectionCrossRootMove": "Thẻ chỉ di chuyển được trong cùng một bộ thẻ cấp cao nhất.",
  "cardRejectionTargetInTrash": "Bộ thẻ đó đang ở Thùng rác.",
  "tagRejectionBlankName": "Hãy nhập tên nhãn.",
```

- [ ] **Step 5: Ask whether a deck is in the Trash**

In `lib/core/database/queries/trash_queries.drift`:

Replace

```sql
VALUES (:id, :item_type, :root_item_id, :deleted_at);

```

with

```sql
VALUES (:id, :item_type, :root_item_id, :deleted_at);

-- BR-TRASH-006: whether :deck_id is a deck in the Trash, which a restore
-- refuses as its target (targetInTrash) rather than as gone.
deckIsInTrash(:deck_id AS TEXT):
SELECT EXISTS (
  SELECT 1 FROM deck WHERE id = :deck_id AND delete_batch_id IS NOT NULL
);

```

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart
  /// Whether [id] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006).
  Future<bool> isInTrash(String id) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM deck WHERE id = ?'
          ' AND delete_batch_id IS NOT NULL) AS in_trash',
          variables: [Variable<String>(id)],
          readsFrom: {_db.deck},
        )
        .getSingle();
    return row.read<bool>('in_trash');
  }

```

with

```dart
  /// Whether [id] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006; `trash_queries.drift`).
  Future<bool> isInTrash(String id) => _db.deckIsInTrash(id).getSingle();

```

- [ ] **Step 6: Generate the database code and the localizations**

```bash
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

Expected: `flutter gen-l10n` prints nothing; the run ends with `Built with build_runner` (it warns that `--delete-conflicting-outputs` is ignored).

- [ ] **Step 7: Restore and undo a card deletion**

In `lib/features/card/data/datasources/card_dao.dart`:

Replace

```dart
      CardCompanion(deleteBatchId: Value(batchId)),
    );
  }

```

with

```dart
      CardCompanion(deleteBatchId: Value(batchId)),
    );
  }

  /// The card of [batchId] when the batch holds one: the card the person
  /// deleted, still marked with that batch (BR-TRASH-001). Null when the
  /// batch is gone or holds a deck.
  Future<CardRow?> itemOf(String batchId) async {
    final row = await _db
        .customSelect(
          'SELECT c.* FROM delete_batches b JOIN card c ON c.id = b.root_item_id'
          " AND c.delete_batch_id = b.id WHERE b.id = ? AND b.item_type = 'card'",
          variables: [Variable<String>(batchId)],
          readsFrom: {_db.deleteBatches, _db.card},
        )
        .getSingleOrNull();
    return row == null ? null : _db.card.map(row.data);
  }

  /// The roots of [deckIds], active or in the Trash: a restore checks a card
  /// against the root of its deck, which may be in the Trash (BR-TRASH-006).
  Future<Set<String>> rootIdsOf(Set<String> deckIds) async => {
    for (final deck in await (_db.select(
      _db.deck,
    )..where((deck) => deck.id.isIn(deckIds))).get())
      deck.rootId,
  };

  /// Whether [deckId] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006; `trash_queries.drift`).
  Future<bool> isDeckInTrash(String deckId) =>
      _db.deckIsInTrash(deckId).getSingle();

  /// [cardId] comes back from the batch [batchId] into [deckId], then the
  /// batch row goes, which the key would otherwise cascade (BR-TRASH-007).
  /// A restore stamps [updatedAt], as a move does; an Undo passes none and
  /// the card keeps its own (trash spec D9).
  Future<void> restoreFromBatch(
    String batchId,
    String cardId, {
    required String deckId,
    DateTime? updatedAt,
  }) async {
    await (_db.update(_db.card)..where((card) => card.id.equals(cardId))).write(
      CardCompanion(
        deleteBatchId: const Value(null),
        deckId: Value(deckId),
        updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
      ),
    );
    await (_db.delete(
      _db.deleteBatches,
    )..where((batch) => batch.id.equals(batchId))).go();
  }

```

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart
    required Set<String> cardIds,
    DateTime? now,
```

with

```dart
    required Set<String> cardIds,
    DateTime? now,
  });

  /// UC-TRASH-001 steps 5-7: the cards of [batchIds] come back into
  /// [deckId], a sub-deck of their root that holds cards or nothing, all or
  /// none; `deck_id` and `updated_at` change as in a move (BR-TRASH-006,
  /// BR-TRASH-007).
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
    DateTime? now,
  });

  /// BR-TRASH-008: the card of [batchId] goes back into its deck with its
  /// `updated_at` kept; refused, typed, when that deck no longer takes it.
  Future<Outcome<void, CardRejection>> undoCardDeletion({
    required String batchId,
    DateTime? now,
```

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
      return Ok(batchIds);
    });
```

with

```dart
      return Ok(batchIds);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> restoreCards({
    required Set<String> batchIds,
    required String deckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (batchIds.isEmpty) return const Ok(null);
      final cards = <String, CardRow>{};
      for (final batchId in batchIds) {
        final card = await _dao.itemOf(batchId);
        if (card == null) return const Rejected(CardRejection.notFound);
        cards[batchId] = card;
      }
      return _restoreInto(deckId, cards, updatedAt: at, at: at);
    });
  }

  @override
  Future<Outcome<void, CardRejection>> undoCardDeletion({
    required String batchId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final card = await _dao.itemOf(batchId);
      if (card == null) return const Rejected(CardRejection.notFound);
      // Back into its own deck with its own updated_at: an Undo is not a
      // move (trash spec D9).
      return _restoreInto(card.deckId, {batchId: card}, at: at);
    });
```

Replace

```dart

  /// A card deck left with no card is unset again (BR-DECK-015, invariant 29).
```

with

```dart

  /// [cards], by batch, come back into [deckId] when it takes them
  /// (BR-TRASH-006, BR-TRASH-007); [updatedAt] stamps them as a move does.
  /// An unset deck becomes a deck of cards (BR-DECK-008).
  Future<Outcome<void, CardRejection>> _restoreInto(
    String deckId,
    Map<String, CardRow> cards, {
    DateTime? updatedAt,
    required DateTime at,
  }) async {
    final target = await _dao.deckRow(deckId);
    if (target == null) {
      return Rejected(
        await _dao.isDeckInTrash(deckId)
            ? CardRejection.targetInTrash
            : CardRejection.targetNotFound,
      );
    }
    final targetContentType = DeckContentType.values.byName(target.contentType);
    final rule = CardEntity.checkTarget(
      targetRootId: target.rootId,
      targetIsRoot: target.parentId == null,
      targetContentType: targetContentType,
      sourceRootIds: await _dao.rootIdsOf({
        for (final card in cards.values) card.deckId,
      }),
    );
    if (rule case Rejected(:final reason)) return Rejected(reason);
    for (final MapEntry(key: batchId, value: card) in cards.entries) {
      await _dao.restoreFromBatch(
        batchId,
        card.id,
        deckId: deckId,
        updatedAt: updatedAt,
      );
    }
    if (targetContentType == DeckContentType.unset) {
      await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
    }
    return const Ok(null);
  }

  /// A card deck left with no card is unset again (BR-DECK-015, invariant 29).
```

Create `lib/features/card/domain/usecases/undo_card_deletion_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// BR-TRASH-008: the card deleted a moment ago goes back into its deck, or
/// the reason it cannot.
final class UndoCardDeletionUseCase {
  const UndoCardDeletionUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({required String batchId}) =>
      _cards.undoCardDeletion(batchId: batchId);
}
```

- [ ] **Step 8: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 56 warning(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/features/card/data/card_restore_test.dart \
  test/features/card/domain/card_entity_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart
```

Expected: `+17: All tests passed!`

- [ ] **Step 10: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/core/database/queries/trash_queries.drift \
  lib/features/card/data/datasources/card_dao.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/entities/card_entity.dart \
  lib/features/card/domain/failures/card_failure.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/card/domain/usecases/undo_card_deletion_use_case.dart \
  lib/features/card/presentation/widgets/support/card_rejection_message_widget.dart \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/architecture/tombstone_filter_test.dart \
  test/features/card/data/card_restore_test.dart \
  test/features/card/domain/card_entity_test.dart \
  test/features/card/domain/card_write_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 11: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 56 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1523: All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git commit -F - <<'EOF'
feat(card): restore cards from the Trash, and undo a deletion

CardEntity.checkTarget holds what a deck must be to take cards: a
sub-deck of their root that holds cards or nothing; checkMove keeps
sameDeck, a move's alone (trash spec D8). restoreCards brings the cards
of the chosen batches into one such deck, all or none, their deck_id and
updated_at changed as a move changes them; undoCardDeletion puts a card
back into its deck with its updated_at kept, or refuses with a typed
reason (BR-TRASH-006 to BR-TRASH-008; D9). CardRejection gains
targetInTrash, with its message (D16).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 7: Where a Trash selection may go back

**Files:**
- Create: `lib/features/deck/domain/models/deck_restore_targets_model.dart`
- Modify: `lib/core/database/queries/card_queries.drift`, `lib/core/database/queries/deck_queries.drift`, `lib/features/card/data/datasources/card_dao.dart`, `lib/features/card/data/datasources/card_detail_dao.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/deck/data/datasources/deck_dao.dart`, `lib/features/deck/data/repositories/deck_repository_impl.dart`, `lib/features/deck/domain/repositories/deck_repository.dart`
- Test (create): `test/features/card/data/card_restore_targets_test.dart`, `test/features/deck/data/deck_restore_targets_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Tasks 5 and 6's restore; `DeckForestRow`, `DeckMoveTarget`,
  `CardMoveTarget`; `tableChanges` (`lib/core/database/table_changes.dart`).
- Produces:
  - `deckMoveTargets(:deck_id, :max_depth, :restoring)`, generated as
    `deckMoveTargets(String deckId, bool restoring, int maxDepth)`, and
    `cardMoveTargets(:root_id, :source_deck_id)`, generated as
    `cardMoveTargets(String? sourceDeckId, String? rootId)` (Clarification 12).
  - `sealed class DeckRestoreTargets` with `DeckRestoreTopLevel()` and
    `DeckRestoreUnder(List<DeckMoveTarget> decks)`
    (`deck/domain/models/deck_restore_targets_model.dart`).
  - `DeckDao.restoreTargetRows(String itemId, {required int maxDepth})`,
    `DeckDao.restoreTargetChanges()`, `CardDetailDao.restoreTargetRows(String rootId)`
    and `CardDao.restoreTargetChanges()`.
  - `DeckRepository.watchRestoreTargets(Set<String> batchIds)` returning
    `Stream<DeckRestoreTargets>`, and `CardRepository.watchRestoreTargets(Set<String> batchIds)`
    returning `Stream<List<CardMoveTarget>>`.

Spec §7.4, D8; Clarification 12; Review Focus 1. A picker's list follows every
write to the decks, the cards and the batches (E2); a write refuses a target that
left anyway.

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/data/card_restore_targets_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BR-TRASH-006 and UC-TRASH-001 step 5: where the cards of a Trash selection
// may go back (trash spec §7.4).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  setUp(() {
    db = openTestDatabase();
    DateTime now() => DateTime(2026, 9, 25, 9);
    decks = DeckRepositoryImpl(db, now: now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: now),
      TagRepositoryImpl(db, now: now),
      now: now,
    );
  });
  tearDown(() => db.close());

  Future<List<String>> delete(Set<String> cardIds) async =>
      ((await cards.deleteCards(
        cardIds: cardIds,
      )) as Ok<List<String>, CardRejection>).value;

  Future<List<String>> namesFor(Set<String> batchIds) async => [
    for (final target in await cards.watchRestoreTargets(batchIds).first)
      target.name,
  ];

  test('cards may go back into any deck of their root that holds cards or '
      'nothing, their old deck included', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final parent = await decks.sub(korean.id, 'Parent');
    await decks.sub(parent.id, 'Child');
    final english = await decks.root('English');
    await decks.sub(english.id, 'Words');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: lesson.id);
    final batchIds = await delete({'c1', 'c2'});

    final targets = await cards.watchRestoreTargets(batchIds.toSet()).first;

    expect([for (final target in targets) target.name], ['Lesson', 'Child']);
    expect(
      [for (final entry in targets[1].path) entry.name],
      ['Korean', 'Parent'],
    );
  });

  test('cards of two roots have no common deck, and a batch that is gone has '
      'none (E1)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    await insertCard(db, id: 'c2', deckId: words.id);
    final [first, second] = await delete({'c1', 'c2'});

    expect(await namesFor({first}), ['Lesson']);
    expect(await namesFor({first, second}), isEmpty);
    expect(await namesFor({first, 'missing'}), isEmpty);
  });

  test('the list follows a write (E2)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    final batchIds = await delete({'c1'});
    final names = cards
        .watchRestoreTargets(batchIds.toSet())
        .map((targets) => [for (final target in targets) target.name]);

    final followed = expectLater(
      names,
      emitsInOrder([
        ['Lesson'],
        emitsThrough(['Lesson', 'Other']),
      ]),
    );
    await pumpEventQueue();
    await decks.sub(korean.id, 'Other');
    await followed;
  });
}
```

Create `test/features/deck/data/deck_restore_targets_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// BR-TRASH-006 and UC-TRASH-001 step 5: where the decks of a Trash selection
// may go back (trash spec §7.4).

/// The names [targets] offers, the top level as `/`.
List<String> _namesOf(DeckRestoreTargets targets) => switch (targets) {
  DeckRestoreTopLevel() => ['/'],
  DeckRestoreUnder(:final decks) => [for (final deck in decks) deck.name],
};

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
  });
  tearDown(() => db.close());

  Future<String> delete(String deckId) async => ((await decks.deleteDeck(
    deckId: deckId,
  )) as Ok<String, DeckRejection>).value;

  Future<List<String>> namesFor(Set<String> batchIds) async =>
      _namesOf(await decks.watchRestoreTargets(batchIds).first);

  test('a sub-deck may go back under its old parent, or where a move of it '
      'may go: not into a deck of cards, its own subtree or another '
      'scheduler', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final food = await decks.sub(words.id, 'Food');
    await decks.sub(food.id, 'Fruit');
    final cards = await decks.sub(korean.id, 'Cards');
    await insertCard(db, id: 'c1', deckId: cards.id);
    await decks.root('Other', SchedulerType.sm2);
    await decks.root('English');
    final batch = await delete(food.id);

    final targets = await decks.watchRestoreTargets({batch}).first;

    expect(_namesOf(targets), ['Korean', 'Words', 'English']);
    final under = (targets as DeckRestoreUnder).decks;
    expect([for (final entry in under[1].path) entry.name], ['Korean']);
  });

  test('root decks go back to the top level; roots and sub-decks together, '
      'or a batch that is gone, have no common place (E1)', () async {
    final korean = await decks.root('Korean');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    final root = await delete(korean.id);
    final sub = await delete(words.id);

    expect(await namesFor({root}), ['/']);
    expect(await namesFor({root, sub}), isEmpty);
    expect(await namesFor({sub, 'missing'}), isEmpty);
  });

  test('a sub-deck whose root went to the Trash after it may go back into '
      'the decks of another root of its scheduler and generation', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    await decks.root('Other', SchedulerType.sm2);
    final english = await decks.root('English');
    await decks.sub(english.id, 'Grammar');
    final batch = await delete(words.id);
    await delete(korean.id);

    expect(await namesFor({batch}), ['English', 'Grammar']);
  });

  test('several batches keep the decks that take all of them: the tallest '
      'subtree sets the depth (BR-DECK-001)', () async {
    final korean = await decks.root('Korean');
    var deepest = korean.id;
    for (var level = 2; level <= 9; level++) {
      deepest = (await decks.sub(deepest, 'L$level')).id;
    }
    final tall = await decks.sub(korean.id, 'Tall');
    await decks.sub(tall.id, 'Inside');
    final flat = await decks.sub(korean.id, 'Flat');
    final tallBatch = await delete(tall.id);
    final flatBatch = await delete(flat.id);

    expect(await namesFor({flatBatch}), contains('L9'));
    expect(await namesFor({tallBatch}), isNot(contains('L9')));
    expect(await namesFor({tallBatch, flatBatch}), [
      for (final name in await namesFor({tallBatch})) name,
    ]);
  });

  test('the list follows a write: a new deck joins it, a deck sent to the '
      'Trash leaves it (E2)', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final batch = await delete(words.id);
    final targets = decks.watchRestoreTargets({batch}).map(_namesOf);

    final followed = expectLater(
      targets,
      emitsInOrder([
        ['Korean'],
        emitsThrough(['Korean', 'Grammar']),
        emitsThrough(['Korean']),
      ]),
    );
    await pumpEventQueue();
    final grammar = await decks.sub(korean.id, 'Grammar');
    await pumpEventQueue();
    await delete(grammar.id);
    await followed;
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/data/card_restore_targets_test.dart \
  test/features/deck/data/deck_restore_targets_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/deck/domain/models/deck_restore_targets_model.dart': No such file or directory`,
`Error: The method 'watchRestoreTargets' isn't defined for the type 'DeckRepositoryImpl'.`
and `Error: The method 'watchRestoreTargets' isn't defined for the type 'CardRepositoryImpl'.`

- [ ] **Step 3: Give the move-target queries a restore mode**

In `lib/core/database/queries/deck_queries.drift`:

Replace

```sql
-- root, a missing deck or a deck in the Trash.
deckMoveTargets(:deck_id AS TEXT, :max_depth AS INTEGER) AS DeckForestRow:
WITH RECURSIVE
```

with

```sql
-- root, a missing deck or a deck in the Trash.
-- With :restoring, :deck_id is the item root of a batch in the Trash and its
-- current parent is a candidate like any other (BR-TRASH-006); its own root
-- may be in the Trash too, and the subtree's height counts its tombstones.
deckMoveTargets(:deck_id AS TEXT, :max_depth AS INTEGER,
  :restoring AS BOOLEAN) AS DeckForestRow:
WITH RECURSIVE
```

Replace

```sql
    WHERE d.id = :deck_id AND d.parent_id IS NOT NULL
      AND d.delete_batch_id IS NULL
  ),
```

with

```sql
    WHERE d.id = :deck_id AND d.parent_id IS NOT NULL
      AND (d.delete_batch_id IS NOT NULL) = :restoring
  ),
```

Replace

```sql
SELECT d.id, d.name, d.parent_id, d.sibling_position, d.content_type,
  d.id <> m.parent_id AS is_candidate
FROM deck d
```

with

```sql
SELECT d.id, d.name, d.parent_id, d.sibling_position, d.content_type,
  (:restoring OR d.id <> m.parent_id) AS is_candidate
FROM deck d
```

In `lib/core/database/queries/card_queries.drift`:

Replace

```sql

-- BR-CARD-010: the decks the cards of :source_deck_id may move to, and the
-- decks on their paths: every active deck of the source's tree.
-- is_candidate marks a sub-deck that holds cards or nothing, other than the
-- source. No row when the source is not an active deck.
cardMoveTargets(:source_deck_id AS TEXT) AS DeckForestRow:
SELECT d.id, d.name, d.parent_id, d.sibling_position, d.content_type,
  (d.parent_id IS NOT NULL AND d.content_type IN ('unset', 'card')
    AND d.id <> :source_deck_id) AS is_candidate
FROM deck d
JOIN deck source ON source.root_id = d.root_id
WHERE source.id = :source_deck_id AND source.delete_batch_id IS NULL
  AND d.delete_batch_id IS NULL;
```

with

```sql

-- BR-CARD-010, BR-TRASH-006: the decks cards may go to, and the decks on
-- their paths: every active deck of one tree. A move names its source deck,
-- whose tree it is and which is no candidate; no row when the source is not
-- an active deck. A restore names the root of its cards and excludes
-- nothing. is_candidate marks a sub-deck that holds cards or nothing.
cardMoveTargets(:root_id AS TEXT OR NULL, :source_deck_id AS TEXT OR NULL)
  AS DeckForestRow:
SELECT d.id, d.name, d.parent_id, d.sibling_position, d.content_type,
  (d.parent_id IS NOT NULL AND d.content_type IN ('unset', 'card')
    AND d.id IS NOT :source_deck_id) AS is_candidate
FROM deck d
WHERE d.delete_batch_id IS NULL AND d.root_id = COALESCE(:root_id, (
  SELECT s.root_id FROM deck s
  WHERE s.id = :source_deck_id AND s.delete_batch_id IS NULL
));
```

- [ ] **Step 4: Generate the database code**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner` (it warns that `--delete-conflicting-outputs` is ignored).

- [ ] **Step 5: Where decks may go back**

Create `lib/features/deck/domain/models/deck_restore_targets_model.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_move_target_model.dart';

/// Where the decks of a Trash selection may go back (BR-TRASH-006).
sealed class DeckRestoreTargets {
  const DeckRestoreTargets();
}

/// Every deck of the selection is a root: the top level is its one place,
/// which the person still confirms.
final class DeckRestoreTopLevel extends DeckRestoreTargets {
  const DeckRestoreTopLevel();
}

/// Every deck of the selection is a sub-deck: the decks that take all of
/// them, in tree order with their paths, the old parent among them. Empty
/// when none does, or when the selection mixes roots and sub-decks (E1).
final class DeckRestoreUnder extends DeckRestoreTargets {
  const DeckRestoreUnder(this.decks);

  final List<DeckMoveTarget> decks;
}
```

In `lib/features/deck/data/datasources/deck_dao.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';

```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

```

Replace

```dart
    required int maxDepth,
  }) => _db.deckMoveTargets(id, maxDepth).watch();

```

with

```dart
    required int maxDepth,
  }) => _db.deckMoveTargets(id, false, maxDepth).watch();

  /// The decks a restore of [itemId], the item root of a batch, may pick,
  /// and the decks on their paths (BR-TRASH-006).
  Future<List<DeckForestRow>> restoreTargetRows(
    String itemId, {
    required int maxDepth,
  }) => _db.deckMoveTargets(itemId, true, maxDepth).get();

  /// Fires once, then after every write to the decks or the batches: where
  /// the decks of a Trash selection may go follows both (E2).
  Stream<void> restoreTargetChanges() =>
      tableChanges(_db, [_db.deck, _db.deleteBatches]);

```

In `lib/features/deck/domain/repositories/deck_repository.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
```

Replace

```dart

  Future<DeckEntity?> findById(String id);
```

with

```dart

  /// UC-TRASH-001 step 5: where the decks of [batchIds] may go back, again
  /// on every change of the decks or the batches (BR-TRASH-006, E1, E2).
  Stream<DeckRestoreTargets> watchRestoreTargets(Set<String> batchIds);

  Future<DeckEntity?> findById(String id);
```

In `lib/features/deck/data/repositories/deck_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_placement_model.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/models/deck_search_hit_model.dart';
```

Replace

```dart
      .watchMoveTargetRows(deckId, maxDepth: DeckEntity.maxDepth)
      .map(
        (rows) => candidatesInTreeOrder(
          [for (final row in rows) deckTreeNodeOf(row)],
          (node, path) =>
              DeckMoveTarget(id: node.id, name: node.name, path: path),
        ),
      )
      .mapDatabaseErrors();
```

with

```dart
      .watchMoveTargetRows(deckId, maxDepth: DeckEntity.maxDepth)
      .map(_moveTargetsOf)
      .mapDatabaseErrors();

  @override
  Stream<DeckRestoreTargets> watchRestoreTargets(Set<String> batchIds) => _dao
      .restoreTargetChanges()
      .asyncMap((_) => _db.transaction(() => _restoreTargets(batchIds)))
      .mapDatabaseErrors();
```

Replace

```dart

  /// One transaction; see [_mapped] for what leaves it on an error.
```

with

```dart

  /// Where the decks of [batchIds] may go back: the top level for roots,
  /// the decks that take every sub-deck otherwise (BR-TRASH-006).
  Future<DeckRestoreTargets> _restoreTargets(Set<String> batchIds) async {
    final items = <Deck>[];
    for (final batchId in batchIds) {
      final item = await _dao.itemRootOf(batchId);
      if (item == null) return const DeckRestoreUnder([]);
      items.add(item);
    }
    if (items.isEmpty) return const DeckRestoreUnder([]);
    final roots = items.where((item) => item.parentId == null).length;
    if (roots == items.length) return const DeckRestoreTopLevel();
    if (roots > 0) return const DeckRestoreUnder([]);
    var common = await _restoreTargetsOf(items.first);
    for (final item in items.skip(1)) {
      final ids = {
        for (final target in await _restoreTargetsOf(item)) target.id,
      };
      common = [
        for (final target in common)
          if (ids.contains(target.id)) target,
      ];
    }
    return DeckRestoreUnder(common);
  }

  Future<List<DeckMoveTarget>> _restoreTargetsOf(Deck item) async =>
      _moveTargetsOf(
        await _dao.restoreTargetRows(item.id, maxDepth: DeckEntity.maxDepth),
      );

  /// One transaction; see [_mapped] for what leaves it on an error.
```

Replace

```dart

DeckRejection? _refusal(Outcome<void, DeckRejection> check) => switch (check) {
```

with

```dart

List<DeckMoveTarget> _moveTargetsOf(List<DeckForestRow> rows) =>
    candidatesInTreeOrder(
      [for (final row in rows) deckTreeNodeOf(row)],
      (node, path) => DeckMoveTarget(id: node.id, name: node.name, path: path),
    );

DeckRejection? _refusal(Outcome<void, DeckRejection> check) => switch (check) {
```

- [ ] **Step 6: Where cards may go back**

In `lib/features/card/data/datasources/card_detail_dao.dart`:

Replace

```dart
  Stream<List<DeckForestRow>> watchMoveTargetRows(String sourceDeckId) =>
      _db.cardMoveTargets(sourceDeckId).watch();
}
```

with

```dart
  Stream<List<DeckForestRow>> watchMoveTargetRows(String sourceDeckId) =>
      _db.cardMoveTargets(sourceDeckId, null).watch();

  /// The decks of [rootId]'s tree, candidates marked: where cards of that
  /// root may go back (BR-TRASH-006).
  Future<List<DeckForestRow>> restoreTargetRows(String rootId) =>
      _db.cardMoveTargets(null, rootId).get();
}
```

In `lib/features/card/data/datasources/card_dao.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/text/folded_text.dart';
```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/core/text/folded_text.dart';
```

Replace

```dart
      deck.rootId,
  };

  /// Whether [deckId] is a deck in the Trash, which a restore refuses as its
```

with

```dart
      deck.rootId,
  };

  /// Fires once, then after every write to the decks, the cards or the
  /// batches: where the cards of a Trash selection may go follows all three
  /// (E2).
  Stream<void> restoreTargetChanges() =>
      tableChanges(_db, [_db.deck, _db.card, _db.deleteBatches]);

  /// Whether [deckId] is a deck in the Trash, which a restore refuses as its
```

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId);
}
```

with

```dart
  Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId);

  /// UC-TRASH-001 step 5: where the cards of [batchIds] may go back, again
  /// on every change of the decks, the cards or the batches: the decks of
  /// their one root that hold cards or nothing (BR-TRASH-006, E1, E2).
  Stream<List<CardMoveTarget>> watchRestoreTargets(Set<String> batchIds);
}
```

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
          .watchMoveTargetRows(sourceDeckId)
          .map(
            (rows) => candidatesInTreeOrder(
              [for (final row in rows) deckTreeNodeOf(row)],
              (node, path) =>
                  CardMoveTarget(id: node.id, name: node.name, path: path),
            ),
          )
          .mapDatabaseErrors();

```

with

```dart
          .watchMoveTargetRows(sourceDeckId)
          .map(_moveTargetsOf)
          .mapDatabaseErrors();

  @override
  Stream<List<CardMoveTarget>> watchRestoreTargets(Set<String> batchIds) => _dao
      .restoreTargetChanges()
      .asyncMap((_) => _db.transaction(() => _restoreTargets(batchIds)))
      .mapDatabaseErrors();

  /// Where the cards of [batchIds] may go back: the decks of their one root
  /// that hold cards or nothing; none when they come from two roots, or a
  /// batch is gone (BR-TRASH-006).
  Future<List<CardMoveTarget>> _restoreTargets(Set<String> batchIds) async {
    final deckIds = <String>{};
    for (final batchId in batchIds) {
      final card = await _dao.itemOf(batchId);
      if (card == null) return const [];
      deckIds.add(card.deckId);
    }
    final roots = await _dao.rootIdsOf(deckIds);
    if (roots.length != 1) return const [];
    return _moveTargetsOf(await _detailDao.restoreTargetRows(roots.single));
  }

```

Replace

```dart
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

with

```dart
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

List<CardMoveTarget> _moveTargetsOf(List<DeckForestRow> rows) =>
    candidatesInTreeOrder(
      [for (final row in rows) deckTreeNodeOf(row)],
      (node, path) => CardMoveTarget(id: node.id, name: node.name, path: path),
    );
```

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 56 warning(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/card/data/card_restore_targets_test.dart \
  test/features/deck/data/deck_restore_targets_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/core/database/queries/card_queries.drift \
  lib/core/database/queries/deck_queries.drift \
  lib/features/card/data/datasources/card_dao.dart \
  lib/features/card/data/datasources/card_detail_dao.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/deck/data/datasources/deck_dao.dart \
  lib/features/deck/data/repositories/deck_repository_impl.dart \
  lib/features/deck/domain/models/deck_restore_targets_model.dart \
  lib/features/deck/domain/repositories/deck_repository.dart \
  test/features/card/data/card_restore_targets_test.dart \
  test/features/deck/data/deck_restore_targets_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 56 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1531: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
feat(deck, card): where a Trash selection may go back

deckMoveTargets gains a restore mode: the moving deck is a batch's item
root, in the Trash, and its old parent is a candidate like any other.
watchRestoreTargets gives the top level for roots, the decks that take
every batch of the selection for sub-decks, and nothing for a mix
(BR-TRASH-006, E1). cardMoveTargets takes a root and an excluded deck: a
move passes its source's root and the source, a restore the cards' one
root and no exclusion. Both lists follow every write to the decks, the
cards or the batches (E2; trash spec §7.4).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 8: The trash feature: its entries, the purge, seven use cases and the provider

**Files:**
- Create: `lib/features/trash/data/datasources/trash_dao.dart`, `lib/features/trash/data/mappers/trash_mapper.dart`, `lib/features/trash/data/repositories/trash_repository_impl.dart`, `lib/features/trash/di/trash_repository_provider.dart`, `lib/features/trash/domain/entities/trash_entry_entity.dart`, `lib/features/trash/domain/models/purge_report_model.dart`, `lib/features/trash/domain/repositories/trash_repository.dart`, `lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart`, `lib/features/trash/domain/usecases/purge_trash_use_case.dart`, `lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart`, `lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart`, `lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart`, `lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart`, `lib/features/trash/domain/usecases/watch_trash_use_case.dart`
- Modify: `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`, `lib/core/database/queries/trash_queries.drift`
- Test (create): `test/features/trash/data/trash_entries_test.dart`, `test/features/trash/data/trash_purge_test.dart`, `test/features/trash/domain/trash_entry_entity_test.dart`, `test/features/trash/domain/trash_use_cases_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`, `test/architecture/tombstone_filter_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: the deck and card repositories of Tasks 2–7; `DayClock`
  (`lib/core/clock/`); `databaseProvider`; `tableChanges`; `mapDatabaseError`;
  `DeckPathEntry`.
- Produces:
  - `const trashRetention = Duration(hours: 720)`, `DateTime trashCutoff(DateTime now)`,
    `sealed class TrashEntry` (`batchId`, `deletedAt`, `origin`, `expiresAt`),
    `TrashDeckEntry` (`deckId`, `name`, `isRoot`, `subDeckCount`, `cardCount`) and
    `TrashCardEntry` (`cardId`, `front`, `back`)
    (`trash/domain/entities/trash_entry_entity.dart`).
  - `PurgeReport({required Set<String> purged, required Map<String, Set<String>> blocked, required Set<String> missing})`.
  - `abstract interface class TrashRepository` with
    `Stream<List<TrashEntry>> watchEntries()`,
    `Future<PurgeReport> purge({required Set<String> batchIds, required DateTime now})`
    and `Future<PurgeReport> purgeExpired({required DateTime now})`;
    `TrashRepositoryImpl(AppDatabase db)` and `trashRepositoryProvider`.
  - `TrashDao(AppDatabase db)` and
    `List<TrashEntry> trashEntriesOf({required List<TrashDeckEntryRow> decks, required List<TrashCardEntryRow> cards, required List<TrashForestRow> forest})`.
  - The use cases of spec §10: `WatchTrashUseCase(TrashRepository)`,
    `WatchDeckRestoreTargetsUseCase(DeckRepository)`,
    `WatchCardRestoreTargetsUseCase(CardRepository)`,
    `RestoreDecksFromTrashUseCase(DeckRepository)`,
    `RestoreCardsFromTrashUseCase(CardRepository)`,
    `PurgeTrashUseCase(TrashRepository, DayClock)` and
    `PurgeExpiredTrashUseCase(TrashRepository, DayClock)`.
  - `allowedFeatureImports` gains `'trash': {'deck', 'card'}`; the impact map names
    `"trash_queries": ["card", "deck", "trash"]`.

Spec §8, §9, §10, D2, D3, D12, D13; Clarification 14; Review Focus 5. Each
emission of the Trash reads in one transaction; a purge runs its passes in one
transaction and reports what it purged, what it skipped and why, and what was
missing. The purge test of a second pass sets the outer batch's `deleted_at` to 0,
so the outer batch sorts first and waits for the pass after the inner one.
Several items deleted at one time share a `deleted_at`: the list orders them by
batch id, the same on every emission.

- [ ] **Step 1: Write the failing tests, and add the feature to the import map**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'search': {'deck'},
};
```

with

```dart
  'search': {'deck'},
  'trash': {'deck', 'card'},
};
```

In `test/architecture/tombstone_filter_test.dart`:

Replace

```dart
const _readsTombstones = <String, String>{
  'lib/core/database/tables/srs.drift#review_log_no_delete':
```

with

```dart
const _readsTombstones = <String, String>{
  'lib/core/database/queries/trash_queries.drift#trashDeckForest':
      'the origin of an entry walks decks in the Trash too (BR-TRASH-012)',
  'lib/core/database/queries/trash_queries.drift#trashBlockersOf':
      "a purge looks for anything left in a batch's decks, in the Trash or "
      'not (BR-TRASH-010)',
  'lib/core/database/tables/srs.drift#review_log_no_delete':
```

Create `test/features/trash/data/trash_entries_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRASH-001 steps 3-4: the Trash lists every batch by the item the person
// deleted, newest first, with where it was and what went with it
// (BR-TRASH-012; trash spec §9).

/// [entry] as a line a test can read: the item, its origin and its counts.
String _line(TrashEntry entry) {
  final origin = [for (final deck in entry.origin) deck.name].join(' › ');
  return switch (entry) {
    TrashDeckEntry(:final name, :final subDeckCount, :final cardCount) =>
      'deck $name in [$origin] with $subDeckCount decks, $cardCount cards',
    TrashCardEntry(:final front) => 'card $front in [$origin]',
  };
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TrashRepositoryImpl trash;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    trash = TrashRepositoryImpl(db);
  });
  tearDown(() => db.close());

  Future<String> deleteDeck(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  Future<List<String>> deleteCards(Set<String> cardIds) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await cards.deleteCards(
      cardIds: cardIds,
    )) as Ok<List<String>, CardRejection>).value;
  }

  Future<List<String>> lines() async => [
    for (final entry in await trash.watchEntries().first) _line(entry),
  ];

  test(
    'every batch, newest first, with the counts of its own rows and the '
    'path of decks it was in, decks in the Trash included (BR-TRASH-003)',
    () async {
      final korean = await decks.root('Korean');
      final words = await decks.sub(korean.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      final drinks = await decks.sub(words.id, 'Drinks');
      await decks.sub(drinks.id, 'Tea');
      await insertCard(db, id: 'f1', front: 'apple', deckId: food.id);
      await insertCard(db, id: 'f2', front: 'bread', deckId: food.id);
      await insertCard(db, id: 'd1', front: 'water', deckId: drinks.id);
      await deleteCards({'f1'});
      await deleteDeck(food.id);
      await deleteDeck(words.id);

      expect(await lines(), [
        'deck Words in [Korean] with 2 decks, 1 cards',
        'deck Food in [Korean › Words] with 0 decks, 1 cards',
        'card apple in [Korean › Words › Food]',
      ]);
    },
  );

  test('cards deleted in one call share a time and list in batch id order, '
      'the same on every emission', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final ids = {for (var i = 1; i <= 6; i++) 'c$i'};
    for (final id in ids) {
      await insertCard(db, id: id, deckId: lesson.id);
    }
    final batchIds = await deleteCards(ids);
    final order = [...batchIds]..sort();
    final emissions = trash.watchEntries().map(
      (entries) => [
        for (final entry in entries) (entry.batchId, entry.deletedAt),
      ],
    );

    final followed = expectLater(
      emissions,
      emitsInOrder([
        [for (final id in order) (id, clock)],
        [for (final id in order) (id, clock)],
      ]),
    );
    await pumpEventQueue();
    await decks.sub(korean.id, 'Later');
    await followed;
  });

  test('a root deck has no origin and says it is a root', () async {
    final korean = await decks.root('Korean');
    final batchId = await deleteDeck(korean.id);

    final [entry] = await trash.watchEntries().first;

    expect(entry.batchId, batchId);
    expect((entry as TrashDeckEntry).isRoot, isTrue);
    expect(entry.origin, isEmpty);
    expect(entry.deletedAt, clock);
    expect(entry.expiresAt, clock.add(trashRetention));
  });

  test(
    'a batch whose item root is missing is not listed (invariant 37)',
    () async {
      await insertDeleteBatch(
        db,
        'orphan',
        itemType: 'deck',
        rootItemId: 'gone',
      );

      expect(await lines(), isEmpty);
    },
  );

  test('the list follows a delete, a restore and a purge', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final entries = trash.watchEntries().map(
      (entries) => [for (final entry in entries) _line(entry)],
    );

    final followed = expectLater(
      entries,
      emitsInOrder([
        isEmpty,
        emitsThrough(['deck Words in [Korean] with 0 decks, 0 cards']),
        emitsThrough(isEmpty),
        emitsThrough(['deck Words in [Korean] with 0 decks, 0 cards']),
        emitsThrough(isEmpty),
      ]),
    );
    await pumpEventQueue();
    final first = await deleteDeck(words.id);
    await pumpEventQueue();
    await decks.restoreDecks(batchIds: {first}, parentId: korean.id);
    await pumpEventQueue();
    final second = await deleteDeck(words.id);
    await pumpEventQueue();
    await trash.purge(batchIds: {second}, now: clock);
    await followed;
  });
}
```

Create `test/features/trash/data/trash_purge_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// BR-TRASH-009 and BR-TRASH-010: a purge deletes chosen and expired batches
// for good, by cascade, oldest first, and skips whole a batch that still
// holds rows of another (trash spec §8).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TrashRepositoryImpl trash;
  var clock = DateTime(2026, 9, 25, 9);

  setUp(() {
    clock = DateTime(2026, 9, 25, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => clock),
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    trash = TrashRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<String> deleteDeck(String deckId) async {
    clock = clock.add(const Duration(minutes: 1));
    return ((await decks.deleteDeck(
      deckId: deckId,
    )) as Ok<String, DeckRejection>).value;
  }

  Future<String> deleteCard(String cardId) async {
    clock = clock.add(const Duration(minutes: 1));
    final [batchId] = ((await cards.deleteCards(
      cardIds: {cardId},
    )) as Ok<List<String>, CardRejection>).value;
    return batchId;
  }

  Future<int> countOf(String sql) async =>
      (await db.customSelect('SELECT COUNT(*) AS n FROM $sql').getSingle())
          .read<int>('n');

  void expectReport(
    PurgeReport report, {
    Set<String> purged = const {},
    Map<String, Set<String>> blocked = const {},
    Set<String> missing = const {},
  }) {
    expect(report.purged, purged);
    expect(report.blocked, blocked);
    expect(report.missing, missing);
  }

  test('a purge deletes exactly the batch and what hangs on its rows: '
      'schedules, logs, tag links, sessions and queues (BR-TRASH-010)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    final kept = await decks.sub(root.id, 'Kept');
    for (final (id, deckId) in [('c1', lesson.id), ('k1', kept.id)]) {
      await insertCard(
        db,
        id: id,
        deckId: deckId,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 30),
      );
    }
    await insertCard(db, id: 'c2', deckId: lesson.id);
    await lockScheduler(db, root.id);
    await logReview(db, id: 'l1', cardId: 'c1', at: DateTime(2026, 9, 2));
    await logReview(db, id: 'l2', cardId: 'k1', at: DateTime(2026, 9, 2));
    await db.customStatement(
      "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t', 't', 't', 0)",
    );
    await db.customStatement(
      "INSERT INTO card_tags (card_id, tag_id) VALUES ('c1', 't'), ('k1', 't')",
    );
    final opened = await studyEntryRepository(
      db,
      () => clock,
    ).openLearningSession(deckId: lesson.id);
    expect(opened, isA<Ok<String, StudyRejection>>());
    final batchId = await deleteDeck(lesson.id);

    final report = await trash.purge(batchIds: {batchId}, now: clock);

    expectReport(report, purged: {batchId});
    expect(await countOf('delete_batches'), 0);
    expect(await countOf("deck WHERE id = '${lesson.id}'"), 0);
    expect(await countOf("card WHERE id = 'c1'"), 0);
    expect(await countOf("card_schedule WHERE card_id = 'c1'"), 0);
    expect(await countOf("review_log WHERE card_id = 'c1'"), 0);
    expect(await countOf("card_tags WHERE card_id = 'c1'"), 0);
    expect(await countOf('study_session'), 0);
    expect(await countOf('study_queue_items'), 0);
    expect(await countOf("card WHERE id = 'k1'"), 1);
    expect(await countOf('review_log'), 1);
    expect(await countOf('card_tags'), 1);
  });

  test(
    'a deck holding a batch that is not chosen is skipped whole and '
    'reported with it; a missing id is reported (BR-TRASH-010, E4, E6)',
    () async {
      final root = await decks.root('Korean');
      final words = await decks.sub(root.id, 'Words');
      final food = await decks.sub(words.id, 'Food');
      await insertCard(db, id: 'c1', deckId: food.id);
      final inner = await deleteCard('c1');
      final outer = await deleteDeck(words.id);

      final report = await trash.purge(batchIds: {outer, 'gone'}, now: clock);

      expectReport(
        report,
        blocked: {
          outer: {inner},
        },
        missing: {'gone'},
      );
      expect(await countOf('delete_batches'), 2);
      expect(await countOf("deck WHERE id = '${food.id}'"), 1);
    },
  );

  test('choosing the inner batch too purges both in one call; when the '
      'outer one sorts first, a second pass takes it', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    await insertCard(db, id: 'c1', deckId: words.id);
    final inner = await deleteCard('c1');
    final outer = await deleteDeck(words.id);
    await db.customStatement(
      "UPDATE delete_batches SET deleted_at = 0 WHERE id = '$outer'",
    );

    final report = await trash.purge(batchIds: {outer, inner}, now: clock);

    expect(report.purged, {outer, inner});
    expect(report.blocked, isEmpty);
    expect(await countOf('delete_batches'), 0);
  });

  test('expiry: 720 hours after a delete the batch goes, a millisecond '
      'earlier it stays; a second run purges nothing (BR-TRASH-009)', () async {
    final root = await decks.root('Korean');
    final words = await decks.sub(root.id, 'Words');
    final deletedAt = clock.add(const Duration(minutes: 1));
    final batchId = await deleteDeck(words.id);
    expect(clock, deletedAt);

    final early = await trash.purgeExpired(
      now: deletedAt.add(trashRetention - const Duration(milliseconds: 1)),
    );
    expect(early.purged, isEmpty);

    final due = await trash.purgeExpired(now: deletedAt.add(trashRetention));
    expect(due.purged, {batchId});

    final again = await trash.purgeExpired(now: deletedAt.add(trashRetention));
    expectReport(again);
  });

  test('1,000 cards deleted in one call expire together, and one auto-purge '
      'takes every batch (BR-TRASH-009)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    final ids = {for (var i = 0; i < 1000; i++) 'c$i'};
    for (final id in ids) {
      await insertCard(db, id: id, deckId: lesson.id);
    }
    clock = clock.add(const Duration(minutes: 1));
    final batchIds = ((await cards.deleteCards(
      cardIds: ids,
    )) as Ok<List<String>, CardRejection>).value;

    final report = await trash.purgeExpired(now: clock.add(trashRetention));

    expectReport(report, purged: batchIds.toSet());
    expect(await countOf('card'), 0);
    expect(await countOf('card_schedule'), 0);
  });

  test('a manual purge takes the expired batches too', () async {
    final root = await decks.root('Korean');
    final old = await deleteDeck((await decks.sub(root.id, 'Old')).id);
    final oldAt = clock;
    final fresh = await deleteDeck((await decks.sub(root.id, 'Fresh')).id);
    final chosen = await deleteDeck((await decks.sub(root.id, 'Chosen')).id);

    final report = await trash.purge(
      batchIds: {chosen},
      now: oldAt.add(trashRetention),
    );

    expectReport(report, purged: {old, chosen});
    expect(await countOf("delete_batches WHERE id = '$fresh'"), 1);
  });

  test('an error half-way rolls the whole purge back (E5)', () async {
    final root = await decks.root('Korean');
    final first = await deleteDeck((await decks.sub(root.id, 'First')).id);
    final second = await decks.sub(root.id, 'Second');
    final secondBatch = await deleteDeck(second.id);
    await db.customStatement(
      'CREATE TEMP TRIGGER fail_purge BEFORE DELETE ON deck '
      "WHEN OLD.id = '${second.id}' BEGIN SELECT RAISE(ABORT, 'boom'); END",
    );

    await expectLater(
      trash.purge(batchIds: {first, secondBatch}, now: clock),
      throwsA(isA<Failure>()),
    );

    expect(await countOf('delete_batches'), 2);
    await db.customStatement('DROP TRIGGER fail_purge');
  });
}
```

Create `test/features/trash/domain/trash_entry_entity_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

// BR-TRASH-009: a batch stays in the Trash for 720 hours, the boundary
// included (trash spec D13).

void main() {
  final deletedAt = DateTime(2026, 9, 1, 8);

  test('the retention is 720 hours', () {
    expect(trashRetention, const Duration(hours: 720));
  });

  test('an entry expires 720 hours after it was deleted', () {
    final entry = TrashCardEntry(
      batchId: 'b',
      deletedAt: deletedAt,
      origin: const [],
      cardId: 'c',
      front: 'f',
      back: 'b',
    );

    expect(entry.expiresAt, deletedAt.add(const Duration(hours: 720)));
  });

  test('a batch deleted at the cutoff has expired; one a millisecond later '
      'has not', () {
    final now = deletedAt.add(trashRetention);

    expect(trashCutoff(now), deletedAt);
    expect(
      trashCutoff(now.subtract(const Duration(milliseconds: 1))),
      isNot(deletedAt),
    );
    expect(
      trashCutoff(now.subtract(const Duration(milliseconds: 1)))
          .isBefore(deletedAt),
      isTrue,
    );
  });
}
```

Create `test/features/trash/domain/trash_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/usecases/purge_expired_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/purge_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart';
import 'package:memox/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart';
import 'package:memox/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart';
import 'package:memox/features/trash/domain/usecases/watch_trash_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';

// The Trash use cases forward to one repository call each (AD-12), over the
// real repositories, so the test asserts what a person sees in the Trash.

void main() {
  late AppDatabase db;
  late FakeDayClock clock;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TrashRepositoryImpl trash;

  setUp(() {
    db = openTestDatabase();
    clock = FakeDayClock(DateTime(2026, 9, 25, 9));
    decks = DeckRepositoryImpl(db, now: clock.now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock.now),
      TagRepositoryImpl(db, now: clock.now),
      now: clock.now,
    );
    trash = TrashRepositoryImpl(db);
  });
  tearDown(() => db.close());

  test('a deck and a card go to the Trash, come back where the person '
      'chooses, and go for good when purged (UC-TRASH-001)', () async {
    final korean = await decks.root('Korean');
    final words = await decks.sub(korean.id, 'Words');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final other = await decks.sub(korean.id, 'Other');
    await insertCard(db, id: 'c1', deckId: lesson.id);
    final deckBatch = ((await decks.deleteDeck(
      deckId: words.id,
    )) as Ok<String, DeckRejection>).value;
    final [cardBatch] = ((await cards.deleteCards(
      cardIds: {'c1'},
    )) as Ok<List<String>, CardRejection>).value;

    final entries = await WatchTrashUseCase(trash)().first;
    expect(entries, hasLength(2));

    final deckTargets = await WatchDeckRestoreTargetsUseCase(decks)(
      batchIds: {deckBatch},
    ).first;
    expect(
      [for (final deck in (deckTargets as DeckRestoreUnder).decks) deck.name],
      ['Korean', 'Lesson', 'Other'],
    );
    final cardTargets = await WatchCardRestoreTargetsUseCase(cards)(
      batchIds: {cardBatch},
    ).first;
    expect([for (final deck in cardTargets) deck.name], ['Lesson', 'Other']);

    expect(
      await RestoreDecksFromTrashUseCase(decks)(
        batchIds: {deckBatch},
        parentId: other.id,
      ),
      isA<Ok<void, DeckRejection>>(),
    );
    expect(
      await RestoreCardsFromTrashUseCase(cards)(
        batchIds: {cardBatch},
        deckId: lesson.id,
      ),
      isA<Ok<void, CardRejection>>(),
    );
    expect(await WatchTrashUseCase(trash)().first, isEmpty);

    final again = ((await decks.deleteDeck(
      deckId: words.id,
    )) as Ok<String, DeckRejection>).value;
    expect((await PurgeTrashUseCase(trash, clock)(batchIds: {again})).purged, {
      again,
    });

    final last = ((await decks.deleteDeck(
      deckId: other.id,
    )) as Ok<String, DeckRejection>).value;
    clock.current = clock.current.add(trashRetention);
    expect((await PurgeExpiredTrashUseCase(trash, clock)()).purged, {last});
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/features/trash/data/trash_entries_test.dart \
  test/features/trash/data/trash_purge_test.dart \
  test/features/trash/domain/trash_entry_entity_test.dart \
  test/features/trash/domain/trash_use_cases_test.dart
```

Expected: `+1 -6: Some tests failed.` The four test files of `trash` do not compile:
`Error: Error when reading 'lib/features/trash/domain/entities/trash_entry_entity.dart': No such file or directory`,
`Error: Error when reading 'lib/features/trash/data/repositories/trash_repository_impl.dart': No such file or directory`,
`Error: Undefined name 'trashRetention'.` and
`Error: Method not found: 'TrashRepositoryImpl'.` The allowlist's test fails on the
two entries it gains,
`'lib/core/database/queries/trash_queries.drift#trashDeckForest'` and
`'lib/core/database/queries/trash_queries.drift#trashBlockersOf'`. As in Task 5, a
failed compile can take the next file's load down with it.

- [ ] **Step 3: Write the Trash vocabulary and its contract**

Create `lib/features/trash/domain/entities/trash_entry_entity.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_path_model.dart';

/// BR-TRASH-009: how long a batch stays in the Trash.
const trashRetention = Duration(hours: 720);

/// The latest time a batch may have been deleted at and be expired at
/// [now]: a batch deleted at the cutoff has expired (BR-TRASH-009).
DateTime trashCutoff(DateTime now) => now.subtract(trashRetention);

/// One row of the Trash: a batch, by the item the person deleted
/// (UC-TRASH-001 steps 3-4).
sealed class TrashEntry {
  const TrashEntry({
    required this.batchId,
    required this.deletedAt,
    required this.origin,
  });

  final String batchId;
  final DateTime deletedAt;

  /// The decks the item was in, root first; empty for a root deck. It is
  /// information only: a restore asks for its target (BR-TRASH-012).
  final List<DeckPathEntry> origin;

  /// When the auto-purge takes the batch (BR-TRASH-009).
  DateTime get expiresAt => deletedAt.add(trashRetention);
}

/// A deck the person deleted, with the decks and cards of its batch.
final class TrashDeckEntry extends TrashEntry {
  const TrashDeckEntry({
    required super.batchId,
    required super.deletedAt,
    required super.origin,
    required this.deckId,
    required this.name,
    required this.isRoot,
    required this.subDeckCount,
    required this.cardCount,
  });

  final String deckId;
  final String name;

  /// A root goes back to the top level only (BR-TRASH-006).
  final bool isRoot;

  /// The decks of the batch other than [deckId], and its cards: an older
  /// tombstone inside is an entry of its own (BR-TRASH-003).
  final int subDeckCount;
  final int cardCount;
}

/// A card the person deleted.
final class TrashCardEntry extends TrashEntry {
  const TrashCardEntry({
    required super.batchId,
    required super.deletedAt,
    required super.origin,
    required this.cardId,
    required this.front,
    required this.back,
  });

  final String cardId;
  final String front;
  final String back;
}
```

Create `lib/features/trash/domain/models/purge_report_model.dart`:

```dart
/// What a purge did (BR-TRASH-010, UC-TRASH-001 E4 and E6).
final class PurgeReport {
  const PurgeReport({
    required this.purged,
    required this.blocked,
    required this.missing,
  });

  /// The batches deleted for good, and every row of theirs with them.
  final Set<String> purged;

  /// Each batch skipped whole, with the batches that still have rows inside
  /// its decks; an empty set means an active row, which invariants 33 and 34
  /// forbid.
  final Map<String, Set<String>> blocked;

  /// The chosen batches that no longer exist.
  final Set<String> missing;
}
```

Create `lib/features/trash/domain/repositories/trash_repository.dart`:

```dart
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';

/// The Trash as its own screen reads and purges it (UC-TRASH-001). Deleting,
/// restoring and undoing belong to the owner of each item: `deck` and
/// `card` (trash spec D2).
abstract interface class TrashRepository {
  /// UC-TRASH-001 steps 3-4: every batch as an entry, newest first, again
  /// after every write to the batches, the decks or the cards. Reading purges
  /// nothing (trash spec D13).
  Stream<List<TrashEntry>> watchEntries();

  /// UC-TRASH-001 A3: [batchIds] and every expired batch go for good, oldest
  /// first, in one transaction; a batch that still holds rows of another is
  /// skipped whole (BR-TRASH-010).
  Future<PurgeReport> purge({
    required Set<String> batchIds,
    required DateTime now,
  });

  /// UC-TRASH-001 step 3 and A4: every batch deleted at or before
  /// `trashCutoff(now)` goes for good (BR-TRASH-009).
  Future<PurgeReport> purgeExpired({required DateTime now});
}
```

- [ ] **Step 4: Write the statements the Trash reads and purges with**

In `lib/core/database/queries/trash_queries.drift`:

Replace

```sql
    JOIN card c ON c.id = o.option_card_id WHERE c.delete_batch_id = :batch_id)
);
```

with

```sql
    JOIN card c ON c.id = o.option_card_id WHERE c.delete_batch_id = :batch_id)
);

-- UC-TRASH-001 steps 3-4: each deck batch with its item root, and the decks
-- and cards of the batch other than the root. An older tombstone inside is
-- an entry of its own (BR-TRASH-003, BR-TRASH-012).
trashDeckEntries AS TrashDeckEntryRow:
SELECT b.id AS batch_id, b.deleted_at, d.id AS deck_id, d.name, d.parent_id,
  (SELECT COUNT(*) FROM deck s WHERE s.delete_batch_id = b.id) - 1
    AS sub_deck_count,
  (SELECT COUNT(*) FROM card c WHERE c.delete_batch_id = b.id) AS card_count
FROM delete_batches b
JOIN deck d ON d.id = b.root_item_id AND d.delete_batch_id = b.id
WHERE b.item_type = 'deck';

-- UC-TRASH-001 steps 3-4: each card batch with its card.
trashCardEntries AS TrashCardEntryRow:
SELECT b.id AS batch_id, b.deleted_at, c.id AS card_id, c.front, c.back,
  c.deck_id
FROM delete_batches b
JOIN card c ON c.id = b.root_item_id AND c.delete_batch_id = b.id
WHERE b.item_type = 'card';

-- UC-TRASH-001 step 4: every deck, the Trash included, from which the origin
-- of an entry is walked (BR-TRASH-012).
trashDeckForest AS TrashForestRow:
SELECT id, parent_id, name FROM deck;

-- BR-TRASH-010: what still sits in the decks of :batch_id and is not of that
-- batch: another batch's id, or NULL for an active row. A purge skips a deck
-- batch with any of them whole.
trashBlockersOf(:batch_id AS TEXT):
WITH RECURSIVE subtree(id) AS (
  SELECT id FROM deck WHERE delete_batch_id = :batch_id
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
)
SELECT delete_batch_id FROM deck
WHERE id IN (SELECT id FROM subtree) AND delete_batch_id IS NOT :batch_id
UNION
SELECT delete_batch_id FROM card
WHERE deck_id IN (SELECT id FROM subtree) AND delete_batch_id IS NOT :batch_id;
```

In `.claude/skills/flutter-workflow/scripts/verification_impact_map.json`:

Replace

```json
    "deck_queries": ["deck"],
    "trash_queries": ["card", "deck"]
  },
```

with

```json
    "deck_queries": ["deck"],
    "trash_queries": ["card", "deck", "trash"]
  },
```

- [ ] **Step 5: Read and purge the batches**

Create `lib/features/trash/data/datasources/trash_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// Row access for the Trash (`trash_queries.drift`). It returns Drift rows,
/// never domain values, and runs inside the caller's transaction.
final class TrashDao {
  TrashDao(this._db);

  final AppDatabase _db;

  /// Fires once, then after every write to the batches, the decks or the
  /// cards: the Trash follows a delete, a restore and a purge.
  Stream<void> entryChanges() =>
      tableChanges(_db, [_db.deleteBatches, _db.deck, _db.card]);

  Future<List<TrashDeckEntryRow>> deckEntryRows() =>
      _db.trashDeckEntries().get();

  Future<List<TrashCardEntryRow>> cardEntryRows() =>
      _db.trashCardEntries().get();

  Future<List<TrashForestRow>> forestRows() => _db.trashDeckForest().get();

  /// The batches a purge takes: [chosen] ones that still exist, and every
  /// one deleted at or before [cutoff], oldest first (BR-TRASH-009,
  /// BR-TRASH-010).
  Future<List<DeleteBatch>> purgeCandidates({
    required Set<String> chosen,
    required DateTime cutoff,
  }) =>
      (_db.select(_db.deleteBatches)
            ..where(
              (batch) =>
                  batch.id.isIn(chosen) |
                  batch.deletedAt.isSmallerOrEqualValue(cutoff),
            )
            ..orderBy([
              (batch) => OrderingTerm(expression: batch.deletedAt),
              (batch) => OrderingTerm(expression: batch.id),
            ]))
          .get();

  /// What still sits in the decks of [batchId] and is not of it: another
  /// batch's id, or null for an active row (BR-TRASH-010).
  Future<List<String?>> blockersOf(String batchId) =>
      _db.trashBlockersOf(batchId).get();

  /// [batchId] goes for good: the keys delete its decks and cards, and
  /// theirs everything that hangs on them (BR-TRASH-010).
  Future<void> purge(String batchId) => (_db.delete(
    _db.deleteBatches,
  )..where((batch) => batch.id.equals(batchId))).go();
}
```

Create `lib/features/trash/data/mappers/trash_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';

/// The entries of the Trash, newest first, from its rows (UC-TRASH-001
/// steps 3-4). Each origin is walked through [forest], the whole deck tree
/// with the Trash in it, so a deck in the Trash is on the path of what was in
/// it (BR-TRASH-012).
List<TrashEntry> trashEntriesOf({
  required List<TrashDeckEntryRow> decks,
  required List<TrashCardEntryRow> cards,
  required List<TrashForestRow> forest,
}) {
  final byId = {for (final row in forest) row.id: row};

  /// [deckId] and every deck above it, root first. Cycle-safe.
  List<DeckPathEntry> pathThrough(String? deckId) {
    final path = <DeckPathEntry>[];
    final seen = <String>{};
    for (var row = byId[deckId]; row != null; row = byId[row.parentId]) {
      if (!seen.add(row.id)) break;
      path.insert(0, DeckPathEntry(id: row.id, name: row.name));
    }
    return path;
  }

  return [
    for (final row in decks)
      TrashDeckEntry(
        batchId: row.batchId,
        deletedAt: row.deletedAt,
        origin: pathThrough(row.parentId),
        deckId: row.deckId,
        name: row.name,
        isRoot: row.parentId == null,
        subDeckCount: row.subDeckCount,
        cardCount: row.cardCount,
      ),
    for (final row in cards)
      TrashCardEntry(
        batchId: row.batchId,
        deletedAt: row.deletedAt,
        origin: pathThrough(row.deckId),
        cardId: row.cardId,
        front: row.front,
        back: row.back,
      ),
  ]..sort(_newestFirst);
}

/// `deleted_at` descending, then the batch id (trash spec §9).
int _newestFirst(TrashEntry a, TrashEntry b) {
  final byTime = b.deletedAt.compareTo(a.deletedAt);
  return byTime != 0 ? byTime : a.batchId.compareTo(b.batchId);
}
```

Create `lib/features/trash/data/repositories/trash_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/trash/data/datasources/trash_dao.dart';
import 'package:memox/features/trash/data/mappers/trash_mapper.dart';
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// The Trash in one transaction a call: each emission of the list is one
/// snapshot, and each purge is all or nothing (trash spec D12).
final class TrashRepositoryImpl implements TrashRepository {
  TrashRepositoryImpl(this._db) : _dao = TrashDao(_db);

  final AppDatabase _db;
  final TrashDao _dao;

  @override
  Stream<List<TrashEntry>> watchEntries() => _dao
      .entryChanges()
      .asyncMap(
        (_) => _db.transaction(
          () async => trashEntriesOf(
            decks: await _dao.deckEntryRows(),
            cards: await _dao.cardEntryRows(),
            forest: await _dao.forestRows(),
          ),
        ),
      )
      .mapDatabaseErrors();

  @override
  Future<PurgeReport> purge({
    required Set<String> batchIds,
    required DateTime now,
  }) => _purge(batchIds, now);

  @override
  Future<PurgeReport> purgeExpired({required DateTime now}) =>
      _purge(const {}, now);

  /// Passes in ascending `deleted_at` until one purges nothing: an inner
  /// batch is older than its deck's (invariant 36), and a pass after it takes
  /// the deck. What is left is skipped whole (BR-TRASH-010).
  Future<PurgeReport> _purge(Set<String> chosen, DateTime now) async {
    try {
      return await _db.transaction(() async {
        var pending = await _dao.purgeCandidates(
          chosen: chosen,
          cutoff: trashCutoff(now),
        );
        final found = {for (final batch in pending) batch.id};
        final purged = <String>{};
        while (true) {
          final left = <DeleteBatch>[];
          for (final batch in pending) {
            if (batch.itemType == 'deck' &&
                (await _dao.blockersOf(batch.id)).isNotEmpty) {
              left.add(batch);
              continue;
            }
            await _dao.purge(batch.id);
            purged.add(batch.id);
          }
          if (left.length == pending.length) break;
          pending = left;
        }
        return PurgeReport(
          purged: purged,
          blocked: {
            for (final batch in pending)
              batch.id: {...(await _dao.blockersOf(batch.id)).nonNulls},
          },
          missing: chosen.difference(found),
        );
      });
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

Create `lib/features/trash/di/trash_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/trash/data/repositories/trash_repository_impl.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'trash_repository_provider.g.dart';

@riverpod
TrashRepository trashRepository(Ref ref) =>
    TrashRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 6: Generate the database code and the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner` (it warns that
`--delete-conflicting-outputs` is ignored), and
`lib/features/trash/di/trash_repository_provider.g.dart` exists next to its
provider.

- [ ] **Step 7: Write the seven use cases**

Create `lib/features/trash/domain/usecases/watch_trash_use_case.dart`:

```dart
import 'package:memox/features/trash/domain/entities/trash_entry_entity.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// UC-TRASH-001 steps 3-4: the Trash, newest first, again after every
/// change. It purges nothing: the screen calls `PurgeExpiredTrashUseCase`
/// first (trash spec D13).
final class WatchTrashUseCase {
  const WatchTrashUseCase(this._trash);

  final TrashRepository _trash;

  Stream<List<TrashEntry>> call() => _trash.watchEntries();
}
```

Create `lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_restore_targets_model.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-TRASH-001 step 5: where the decks of [batchIds] may go back, again on
/// every change (BR-TRASH-006, E1, E2).
final class WatchDeckRestoreTargetsUseCase {
  const WatchDeckRestoreTargetsUseCase(this._decks);

  final DeckRepository _decks;

  Stream<DeckRestoreTargets> call({required Set<String> batchIds}) =>
      _decks.watchRestoreTargets(batchIds);
}
```

Create `lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart`:

```dart
import 'package:memox/features/card/domain/models/card_move_target_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRASH-001 step 5: where the cards of [batchIds] may go back, again on
/// every change (BR-TRASH-006, E1, E2).
final class WatchCardRestoreTargetsUseCase {
  const WatchCardRestoreTargetsUseCase(this._cards);

  final CardRepository _cards;

  Stream<List<CardMoveTarget>> call({required Set<String> batchIds}) =>
      _cards.watchRestoreTargets(batchIds);
}
```

Create `lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';

/// UC-TRASH-001 steps 6-7: the decks of [batchIds] come back under
/// [parentId], or to the top level when it is null, all or none
/// (BR-TRASH-006, BR-TRASH-007).
final class RestoreDecksFromTrashUseCase {
  const RestoreDecksFromTrashUseCase(this._decks);

  final DeckRepository _decks;

  Future<Outcome<void, DeckRejection>> call({
    required Set<String> batchIds,
    required String? parentId,
  }) => _decks.restoreDecks(batchIds: batchIds, parentId: parentId);
}
```

Create `lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';

/// UC-TRASH-001 steps 6-7: the cards of [batchIds] come back into [deckId],
/// all or none (BR-TRASH-006, BR-TRASH-007).
final class RestoreCardsFromTrashUseCase {
  const RestoreCardsFromTrashUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<void, CardRejection>> call({
    required Set<String> batchIds,
    required String deckId,
  }) => _cards.restoreCards(batchIds: batchIds, deckId: deckId);
}
```

Create `lib/features/trash/domain/usecases/purge_trash_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// UC-TRASH-001 A3: the batches the person chose, and every expired one, go
/// for good; a batch that still holds another is skipped and reported
/// (BR-TRASH-010, E4, E6).
final class PurgeTrashUseCase {
  const PurgeTrashUseCase(this._trash, this._clock);

  final TrashRepository _trash;
  final DayClock _clock;

  Future<PurgeReport> call({required Set<String> batchIds}) =>
      _trash.purge(batchIds: batchIds, now: _clock.now());
}
```

Create `lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/trash/domain/models/purge_report_model.dart';
import 'package:memox/features/trash/domain/repositories/trash_repository.dart';

/// UC-TRASH-001 step 3 and A4: every batch 720 hours old or more goes for
/// good. The UI calls it at start, on resume, when the Trash opens and when
/// it regains focus (BR-TRASH-009; trash spec D13).
final class PurgeExpiredTrashUseCase {
  const PurgeExpiredTrashUseCase(this._trash, this._clock);

  final TrashRepository _trash;
  final DayClock _clock;

  Future<PurgeReport> call() => _trash.purgeExpired(now: _clock.now());
}
```

- [ ] **Step 8: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 56 warning(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/architecture/tombstone_filter_test.dart \
  test/features/trash/data/trash_entries_test.dart \
  test/features/trash/data/trash_purge_test.dart \
  test/features/trash/domain/trash_entry_entity_test.dart \
  test/features/trash/domain/trash_use_cases_test.dart
```

Expected: `+18: All tests passed!`

- [ ] **Step 10: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add .claude/skills/flutter-workflow/scripts/verification_impact_map.json \
  lib/core/database/queries/trash_queries.drift \
  lib/features/trash/data/datasources/trash_dao.dart \
  lib/features/trash/data/mappers/trash_mapper.dart \
  lib/features/trash/data/repositories/trash_repository_impl.dart \
  lib/features/trash/di/trash_repository_provider.dart \
  lib/features/trash/domain/entities/trash_entry_entity.dart \
  lib/features/trash/domain/models/purge_report_model.dart \
  lib/features/trash/domain/repositories/trash_repository.dart \
  lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart \
  lib/features/trash/domain/usecases/purge_trash_use_case.dart \
  lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart \
  lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart \
  lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart \
  lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart \
  lib/features/trash/domain/usecases/watch_trash_use_case.dart \
  test/architecture/boundary_rules.dart \
  test/architecture/tombstone_filter_test.dart \
  test/features/trash/data/trash_entries_test.dart \
  test/features/trash/data/trash_purge_test.dart \
  test/features/trash/domain/trash_entry_entity_test.dart \
  test/features/trash/domain/trash_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 11: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 56 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1547: All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git commit -F - <<'EOF'
feat(trash): the Trash entries, the purge, and the use cases

watchEntries lists every batch newest first, a deck with the decks and
cards of its batch, a card with its faces, each with where it was, root
first, read in one transaction and again after every write to the
batches, the decks or the cards (UC-TRASH-001 steps 3-4). purge takes the
chosen batches and every expired one, purgeExpired the expired ones: in
one transaction, in passes by deleted_at, a batch whose decks still hold
another batch's rows skipped whole and reported with them, a missing id
reported (BR-TRASH-009, BR-TRASH-010; trash spec D12, D13). Seven use
cases give FE-B1 the screen; the feature enters the import map with deck
and card (D3).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 9: The package's documents

**Files:**
- Modify: `docs/features/trash/README.md`, `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md`, `docs/shared/data/schema.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: the code of Tasks 1–8.
- Produces: the documents only.

Spec §13, D4; Clarification 16.

- [ ] **Step 1: Record the package in the trash documents, the schema and the WBS**

Replace the whole of `docs/features/trash/README.md` with:

```markdown
---
feature: trash
code: [lib/features/trash/domain, lib/features/trash/data, lib/features/trash/di]
depends_on: [card, deck, srs]
---
## Phạm vi

**Phạm vi:** Trash, từ schema v3 (BE-B1,
[spec](../../superpowers/specs/2026-09-25-trash-backend-design.md)).

Soft-delete thay thế delete cứng cho **card và deck**: xoá đưa item vào Trash thành
một batch (BR-DECK-022, BR-DECK-023, UC-CARD-001 A2), và chỉ purge mới xoá hẳn, theo
cascade. Các rule dưới đây **không** phát biểu lại BR-DECK-022/BR-DECK-023 hay
BR-DECK-015 (`content_type` tự về `unset`) — chúng nói phần mà tombstone thêm vào.

Chủ của một item xoá, khôi phục và Undo nó: `deck` cho deck, `card` cho card. Feature
`trash` giữ phần của màn Trash: danh sách batch, đích khôi phục, việc chuyển lệnh
khôi phục về đúng chủ, và purge (spec D2).

Từ vựng: **batch** là một lần xoá của người dùng, mang một id riêng; **item root**
là chính card/deck người dùng đã chạm; **tombstone** là hàng còn nguyên trong
`card`/`deck` nhưng mang `delete_batch_id`; **purge** là xoá cứng vĩnh viễn.

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| `Trash` từ app bar (và thao tác xoá card/deck vào Trash) | UC-TRASH-001 |

Nguồn: trigger của UC-TRASH-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Màn Trash, câu chữ của hộp thoại xoá, snackbar Undo và thời gian của nó, lúc gọi auto-purge, xác nhận purge | FE-B1 ([`wbs_FE.md`](../../wbs_FE.md)); tới lúc đó hộp thoại xoá giữ câu chữ "xoá vĩnh viễn" và chưa gì gọi auto-purge (spec D15) |
| Đồng bộ batch giữa các thiết bị | `owner_id` luôn NULL; thuộc sub-project auth/sync sau |
```

In `docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md`:

Replace

```markdown
rules: [BR-CARD-010, BR-CARD-012, BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK-015, BR-DECK-017, BR-DECK-018, BR-SRS-006, BR-TRASH-001, BR-TRASH-002, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-006, BR-TRASH-007, BR-TRASH-008, BR-TRASH-009, BR-TRASH-010, BR-TRASH-011, BR-TRASH-012]
code: []
---
```

with

```markdown
rules: [BR-CARD-010, BR-CARD-012, BR-DECK-001, BR-DECK-009, BR-DECK-010, BR-DECK-015, BR-DECK-017, BR-DECK-018, BR-SRS-006, BR-TRASH-001, BR-TRASH-002, BR-TRASH-003, BR-TRASH-004, BR-TRASH-005, BR-TRASH-006, BR-TRASH-007, BR-TRASH-008, BR-TRASH-009, BR-TRASH-010, BR-TRASH-011, BR-TRASH-012]
code: [lib/features/trash/domain/usecases/watch_trash_use_case.dart, lib/features/trash/domain/usecases/watch_deck_restore_targets_use_case.dart, lib/features/trash/domain/usecases/watch_card_restore_targets_use_case.dart, lib/features/trash/domain/usecases/restore_decks_from_trash_use_case.dart, lib/features/trash/domain/usecases/restore_cards_from_trash_use_case.dart, lib/features/trash/domain/usecases/purge_trash_use_case.dart, lib/features/trash/domain/usecases/purge_expired_trash_use_case.dart, lib/features/deck/domain/usecases/delete_deck_use_case.dart, lib/features/deck/domain/usecases/undo_deck_deletion_use_case.dart, lib/features/card/domain/usecases/delete_cards_use_case.dart, lib/features/card/domain/usecases/undo_card_deletion_use_case.dart]
---
```

Replace

```markdown

**Phạm vi:** sub-project sau — Trash (spec §2).

```

with

```markdown

**Phạm vi:** Trash, từ schema v3 (BE-B1). Màn Trash và snackbar Undo thuộc FE-B1.

```

In `docs/shared/data/schema.md`:

Replace

```markdown
ra descendant trỏ sai root hoặc sai độ sâu — dữ liệu hỏng im lặng, vì query vẫn
chạy và chỉ trả về kết quả thiếu.

```

with

```markdown
ra descendant trỏ sai root hoặc sai độ sâu — dữ liệu hỏng im lặng, vì query vẫn
chạy và chỉ trả về kết quả thiếu. Tombstone bên trong subtree đi cùng nó: phép di
chuyển viết lại `root_id` và `depth` của tombstone, và chiều cao của subtree tính cả
tombstone, nên một phép di chuyển không bao giờ đẩy tombstone quá cấp 10 (BR-TRASH-007,
spec Trash D10).

```

Replace

```markdown
`PRAGMA foreign_keys = ON` trong `beforeOpen`. Không có nó, `ON DELETE CASCADE`
chỉ là chú thích. Cần test: xoá root deck → toàn bộ cây deck con, card, study
state, study answers và study session đều biến mất (BR-DECK-022).

```

with

```markdown
`PRAGMA foreign_keys = ON` trong `beforeOpen`. Không có nó, `ON DELETE CASCADE`
chỉ là chú thích. Cần test: xoá cứng root deck → toàn bộ cây deck con, card, study
state, study answers và study session đều biến mất. Từ v3 chỉ purge xoá cứng
(BR-DECK-022, BR-TRASH-010).

```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-D2 | CI chạy gate trên Linux cho mỗi pull request: job `gate` dựng lại code sinh từ đầu rồi chạy `dod_check.sh` đầy đủ; job `goldens` so ảnh golden và đếm số test đã chạy (sàn 60); job `CI gate` chỉ xanh khi mọi job khác thành công, là check duy nhất cần bắt buộc. Gỡ công cụ CI của V7 không còn gì dùng | xong | — | M | [spec](superpowers/specs/2026-09-25-ci-gate-design.md) và [plan](superpowers/plans/2026-09-25-ci-gate.md) gói 6; `.github/workflows/ci.yml`; test hợp đồng workflow và test đếm golden trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | Chủ dự án đặt `CI gate` làm check bắt buộc trong ruleset ([`README.md` gốc](../README.md)); BE-D5 |

```

with

```markdown
| BE-D2 | CI chạy gate trên Linux cho mỗi pull request: job `gate` dựng lại code sinh từ đầu rồi chạy `dod_check.sh` đầy đủ; job `goldens` so ảnh golden và đếm số test đã chạy (sàn 60); job `CI gate` chỉ xanh khi mọi job khác thành công, là check duy nhất cần bắt buộc. Gỡ công cụ CI của V7 không còn gì dùng | xong | — | M | [spec](superpowers/specs/2026-09-25-ci-gate-design.md) và [plan](superpowers/plans/2026-09-25-ci-gate.md) gói 6; `.github/workflows/ci.yml`; test hợp đồng workflow và test đếm golden trong `.claude/skills/flutter-workflow/scripts/tests/test_ci_tooling.py` | Chủ dự án đặt `CI gate` làm check bắt buộc trong ruleset ([`README.md` gốc](../README.md)); BE-D5 |
| BE-B1 | Trash, phần store (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012): schema v3 với `delete_batches` và khoá `delete_batch_id` → `delete_batches(id)` (migration v2 → v3 bằng dựng lại bảng, test nâng cấp từ v1 và v2); xoá deck và card là soft-delete theo batch, đóng phiên chạm tới batch (kể cả qua lựa chọn `guess`); khôi phục và Undo theo đúng luật di chuyển; đích khôi phục; danh sách Trash và purge theo lượt, bỏ qua trọn batch còn chứa batch khác; 11 use case; test hình dạng câu lệnh của BR-TRASH-002 với allowlist có lý do | xong | BE-02, BE-D1 | L | [spec](superpowers/specs/2026-09-25-trash-backend-design.md) và [plan](superpowers/plans/2026-09-26-trash-backend.md) gói 7; test trong `test/features/trash/`, `test/features/deck/data/deck_trash_test.dart`, `test/features/card/data/card_trash_test.dart`, `test/drift/migration_test.dart`, `test/architecture/tombstone_filter_test.dart` | FE-B1 dựng màn 06, snackbar Undo và lời gọi auto-purge trên các use case này |

```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-B1 | Trash: xoá mềm theo batch, khôi phục, purge (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) | chưa bắt đầu | BE-02, BE-D1 | L | Cột `delete_batch_id` đã có trên `deck` và `card` nhưng chưa có FK; chưa có bảng `delete_batches`; mọi query và lệnh ghi đã lọc `delete_batch_id IS NULL` | Mang migration v2 → v3 (v1 → v2 thuộc gói 2b). Đổi xoá cứng của BR-DECK-022 và BR-DECK-023 thành tombstone; bất biến 33–37 của `schema.md` bắt đầu có hiệu lực |
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
```

Replace

```markdown
  sau mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

with

```markdown
  sau mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-B1** (gói 7, [spec](superpowers/specs/2026-09-25-trash-backend-design.md),
  [plan](superpowers/plans/2026-09-26-trash-backend.md)): gate xanh sau mỗi task, final
  review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

Replace

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 16/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  6 UC còn lại chưa có code.

```

with

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 17/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003, UC-TRASH-001).
  5 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 6 (BE-D2).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 7 (BE-B1).

```

Replace

```markdown

1. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.
```

with

```markdown

1. BE-B2…BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của chúng đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.
```

Replace

```markdown
  pull request. Thêm BE-D5 cho phần của planner chỉ CI của V7 dùng.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  pull request. Thêm BE-D5 cho phần của planner chỉ CI của V7 dùng.
- **Cập nhật ngày 2026-09-26:** BE-B1 xong trong gói 7, hạng mục đầu của nhóm sau V8.0:
  schema v3, xoá vào Trash, khôi phục, Undo, purge.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
|---|---|---|---|---|---|---|
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | [README trash](features/trash/README.md) | Sau BE-B1 |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Sau BE-B2 |
```

with

```markdown
|---|---|---|---|---|---|---|
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | BE-B1 xong: hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Sau BE-B2 |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 55 warning(s)`.

- [ ] **Step 2: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/trash/README.md \
  docs/features/trash/usecases/UC-TRASH-001-trash-va-khoi-phuc-item-da-xoa.md \
  docs/shared/data/schema.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 3: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 55 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1547: All tests passed!`.

- [ ] **Step 4: Commit**

```bash
git commit -F - <<'EOF'
docs: the Trash is built; BE-B1 done

The trash README and UC-TRASH-001 name the code, schema.md says that
tombstones travel with their subtree and what a batch's key deletes, and
the WBS has BE-B1 done, with FE-B1's notes: the Undo snackbars, where to
call the auto-purge, the kit's youngerInside wording and the copy of the
new refusals (trash spec §13).
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-trash` and open its pull request against `master`, then subscribe
to its activity.

Expected: the checks `gate`, `goldens` and `CI gate` go green. This package changes
no widget and no golden.

- [ ] **Step 2: Merge**

Squash-merge only while `CI gate` is green on the pull request's head, then
unsubscribe from its activity.


## Plan self-review

- **Spec coverage.** §5 schema v3, the step and its tests: Task 1. §6.1 and §6.3 a
  deck delete and the sessions it closes: Task 2; §6.2 cards: Task 3; §6.4 what a
  delete leaves alone: Tasks 2 and 3. §7.1 and §7.3 a deck's restore and Undo:
  Task 5; §7.2 and §7.3 a card's: Task 6; §7.4 the targets: Task 7. §8 the purge, §9
  the read model and §10 the use cases: Task 8. §11 the shape check: Task 4, its
  allowlist grown in Tasks 5, 6 and 8. §12 tests: every line has its test in Tasks
  1–8. §13 documents: Tasks 1, 2, 3 and 9. D16's refusals: Tasks 5 and 6.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run
  compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the task that owns the
  code.
