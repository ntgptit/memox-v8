# Every query in `.drift`, P3 (deck) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `DeckDao` to a `@DriftAccessor` whose own queries live in `.drift`, take `deck_dao.dart` off the guard's temporary exclude, and take `delete_batch_queries.drift` off `@DriftDatabase`.

**Architecture:** P0–P2 set the pattern (ADR-020).
- **New query file.** `DeckDao` includes a new `deck_row_queries.drift`, plus the shared `live_row_queries.drift` and `delete_batch_queries.drift`.
- **`setLiveDeckContentType` becomes shared.** It moves from `card_row_queries.drift` to `live_row_queries.drift` (D3), because both the card and the deck feature write a deck's content type.
- **`deck_queries.drift` stays on `AppDatabase` for now.** Its result classes (`DeckTileRow`, `DeckForestRow`, `DeckDeletionSummaryResult`) are shared by deck, study (P5), reminders and progress (P6). Including one file with result classes in several accessors generates a duplicate class per accessor, so `DeckDao` keeps calling those queries through `attachedDatabase` until that is decided (ruling in Task 1). `reminder_workload_dao` calls only one of them, so it moves with that decision too.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P3; D1–D7, D11). ADR-020.

## Global Constraints

These are the same as P2:
- behaviour-preserving;
- generated `*.g.dart` stays uncommitted;
- guard commands use `python3.13`;
- generated parameters follow first appearance in the SQL, so match the calls to them;
- deck and card writes in `.drift` name `delete_batch_id`, or carry a tombstone allowlist entry keyed `<file>#<queryName>`;
- every new query file gets an impact-map owner row;
- query names never collide with DAO method names.

## Review Focus

1. **Restore order.** Every restore unmarks the batch (`restoreBatch`) before it re-places the deck (`setSiblingPosition`, `moveUnder`), so the new `delete_batch_id IS NULL` filters on those writes never refuse a restoring deck. Pinned by `deck_restore_test` and `deck_restore_targets_test`.
2. **Delete marks a whole subtree, keeping older tombstones (BR-TRASH-003).** Pinned by `deck_trash_test`.
3. **A move re-roots the whole subtree, tombstones included (D10).** Pinned by `deck_repository_impl_edit_test` and the tree tests.
4. **The sibling end counts tombstones (D9), and the subtree height counts them (D10).** These two queries read tombstones on purpose and keep their allowlist entries, under new keys.
5. **`delete_batch_queries.drift` leaves `@DriftDatabase`.** No `AppDatabase` caller of `insertDeleteBatch`, `deckIsInTrash` or `closeSessionsTouchingBatch` may remain.

---

### Task 1: `DeckDao`

**Files:**
- Create: `lib/core/database/queries/deck_row_queries.drift`
- Modify: `lib/core/database/queries/live_row_queries.drift` (gains `setLiveDeckContentType`)
- Modify: `lib/core/database/queries/card_row_queries.drift` (loses it)
- Modify: `lib/core/database/app_database.dart` (drop the `delete_batch_queries.drift` include)
- Modify: `lib/features/deck/data/datasources/deck_dao.dart` (whole class)
- Modify: `test/architecture/tombstone_filter_test.dart` (four `deck_dao.dart#…` keys move)
- Modify: guard `scopes.yaml`, `MIGRATED_TO_DRIFT`, impact map
- Tests (existing): `test/features/deck/`, `test/features/card/`, `test/features/trash/`, `test/features/study/`, `test/architecture/`

**Interfaces:**
- Produces: `DeckDao(AppDatabase)` with unchanged method names and types.

- [ ] **Step 1: Red.** Delete `      - lib/features/deck/data/datasources/deck_dao.dart` from `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `deck_dao.dart`.

- [ ] **Step 2: Move the shared write.** Cut `setLiveDeckContentType` and its comment from `card_row_queries.drift` and append them to `live_row_queries.drift`.

- [ ] **Step 3: Deck queries.** Create `lib/core/database/queries/deck_row_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';
import '../tables/trash.drift';

-- Spec §8: a deck in the Trash is out of reach of every write here, except
-- where a query says why.

-- BR-SRS-007: the active decks under :parent_id in manual order; a null
-- parent selects the roots.
liveSiblingDecks(:parent_id AS TEXT OR NULL):
SELECT * FROM deck WHERE parent_id IS :parent_id AND delete_batch_id IS NULL
ORDER BY sibling_position, id;

renameLiveDeck(:deck_id AS TEXT, :name AS TEXT, :now AS DATETIME):
UPDATE deck SET name = :name, updated_at = :now
WHERE id = :deck_id AND delete_batch_id IS NULL;

setLiveDeckSiblingPosition(:deck_id AS TEXT, :position AS INTEGER,
  :now AS DATETIME):
UPDATE deck SET sibling_position = :position, updated_at = :now
WHERE id = :deck_id AND delete_batch_id IS NULL;

createDeck: INSERT INTO deck $row;

-- BR-TRASH-001, BR-TRASH-003: :deck_id and every active deck under it join
-- :batch_id; a tombstone inside keeps its older batch. Cycle-safe (UNION)
-- and never capped.
markDeckSubtreeDeleted(:deck_id AS TEXT, :batch_id AS TEXT):
WITH RECURSIVE subtree(id) AS (
  SELECT :deck_id
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
  WHERE d.delete_batch_id IS NULL
)
UPDATE deck SET delete_batch_id = :batch_id
WHERE id IN (SELECT id FROM subtree);

-- BR-TRASH-001: every active card of the decks of :batch_id joins it.
markCardsOfBatchDecksDeleted(:batch_id AS TEXT):
UPDATE card SET delete_batch_id = :batch_id
WHERE delete_batch_id IS NULL
  AND deck_id IN (SELECT id FROM deck WHERE delete_batch_id = :batch_id);

-- BR-TRASH-001: the item root of :batch_id when the batch holds a deck,
-- still marked with that batch.
deckOfBatch(:batch_id AS TEXT):
SELECT d.* FROM delete_batches b
JOIN deck d ON d.id = b.root_item_id AND d.delete_batch_id = b.id
WHERE b.id = :batch_id AND b.item_type = 'deck';

-- BR-TRASH-006: :deck_id's row, active or in the Trash: a restore checks
-- its item against the item's own root, which may be in the Trash too.
deckInAnyState(:deck_id AS TEXT):
SELECT * FROM deck WHERE id = :deck_id;

-- BR-TRASH-007: the decks and the cards of :batch_id lose their mark.
unmarkDecksOfBatch(:batch_id AS TEXT):
UPDATE deck SET delete_batch_id = NULL WHERE delete_batch_id = :batch_id;

unmarkCardsOfBatch(:batch_id AS TEXT):
UPDATE card SET delete_batch_id = NULL WHERE delete_batch_id = :batch_id;

-- BR-SRS-007, D9: the end of the sibling group under :parent_id, counting
-- the tombstones, so an Undo finds its place free; IS makes a null parent
-- select the roots.
nextSiblingPositionUnder(:parent_id AS TEXT OR NULL):
SELECT COALESCE(MAX(sibling_position) + 1, 0) FROM deck
WHERE parent_id IS :parent_id;

-- :deck_id and every deck above it, while they are active. Cycle-safe
-- (UNION) and never capped, as schema.md asks of a tree walk.
liveAncestorIds(:deck_id AS TEXT):
WITH RECURSIVE up(id, parent_id) AS (
  SELECT id, parent_id FROM deck
  WHERE id = :deck_id AND delete_batch_id IS NULL
  UNION
  SELECT d.id, d.parent_id FROM deck d JOIN up ON d.id = up.parent_id
  WHERE d.delete_batch_id IS NULL
)
SELECT id FROM up;

-- D10, schema.md depth probe: how many levels the subtree of :deck_id
-- spans, tombstones included, walking at most :cap levels.
deckSubtreeHeight(:deck_id AS TEXT, :cap AS INTEGER):
WITH RECURSIVE down(id, height) AS (
  SELECT id, 1 FROM deck WHERE id = :deck_id
  UNION ALL
  SELECT d.id, down.height + 1 FROM deck d
  JOIN down ON d.parent_id = down.id WHERE down.height < :cap
)
SELECT MAX(height) FROM down;

-- BR-DECK-006, BR-DECK-015: what :deck_id holds now; tombstones do not
-- count, as in invariants 2 and 29.
deckContentFromChildren(:deck_id AS TEXT):
SELECT CASE
  WHEN EXISTS (SELECT 1 FROM deck
               WHERE parent_id = :deck_id AND delete_batch_id IS NULL)
    THEN 'deck'
  WHEN EXISTS (SELECT 1 FROM card
               WHERE deck_id = :deck_id AND delete_batch_id IS NULL)
    THEN 'card'
  ELSE 'unset' END;

-- BR-DECK-018: :deck_id goes under :parent_id at :position.
placeLiveDeck(:deck_id AS TEXT, :parent_id AS TEXT, :position AS INTEGER,
  :now AS DATETIME):
UPDATE deck SET parent_id = :parent_id, sibling_position = :position,
  updated_at = :now
WHERE id = :deck_id AND delete_batch_id IS NULL;

-- BR-DECK-018, D10: the whole subtree of :deck_id, tombstones included,
-- takes :root_id and a depth shifted by :depth_shift. Cycle-safe, never
-- capped.
reRootDeckSubtree(:deck_id AS TEXT, :root_id AS TEXT,
  :depth_shift AS INTEGER, :now AS DATETIME):
WITH RECURSIVE subtree(id) AS (
  SELECT :deck_id
  UNION
  SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id
)
UPDATE deck SET root_id = :root_id, depth = depth + :depth_shift,
  updated_at = :now
WHERE id IN (SELECT id FROM subtree);
```

- [ ] **Step 4: DAO.** Replace the class in `deck_dao.dart` with the code below. The three `deck_queries.drift` reads stay on `attachedDatabase`.

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

part 'deck_dao.g.dart';

/// Row access for `deck` (`deck_row_queries.drift`). It returns Drift rows,
/// never domain entities, and runs inside the caller's transaction:
/// `DeckRepositoryImpl` owns that. The level, path, move-target and
/// deletion-summary reads are `deck_queries.drift`'s, still on
/// [AppDatabase] while other features share their result classes.
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/deck_row_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
    'package:memox/core/database/queries/delete_batch_queries.drift',
  },
)
final class DeckDao extends DatabaseAccessor<AppDatabase>
    with _$DeckDaoMixin {
  DeckDao(super.attachedDatabase);

  /// An active deck: a deck in the Trash is out of reach of every write
  /// (spec §8).
  Future<Deck?> findRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The active decks under [parentId] in manual order, `(sibling_position,
  /// id)` (BR-SRS-007); a null parent selects the roots.
  Future<List<Deck>> siblingRows(String? parentId) =>
      liveSiblingDecks(parentId).get();

  Future<void> rename(String id, String name, DateTime now) =>
      renameLiveDeck(name, now, id);

  Future<void> setSiblingPosition(String id, int position, DateTime now) =>
      setLiveDeckSiblingPosition(position, now, id);

  /// The decks under [parentId], the roots when it is null, with the counts
  /// of their subtrees: one statement per emission (`deck_queries.drift`).
  Stream<List<DeckTileRow>> watchLevel({
    required String? parentId,
    required DateTime now,
    required DateTime startOfToday,
  }) {
    if (parentId == null) {
      return attachedDatabase.deckLevelOfRoots(startOfToday, now).watch();
    }
    return attachedDatabase
        .deckLevelOfChildren(parentId, startOfToday, now)
        .watch();
  }

  /// [id] and every deck above it, root first; empty when [id] is not an
  /// active deck.
  Stream<List<Deck>> watchDeckAndAncestors(String id) =>
      attachedDatabase.deckAndAncestors(id).watch();

  /// The decks a move of [id] may pick, and the decks on their paths.
  Stream<List<DeckForestRow>> watchMoveTargetRows(
    String id, {
    required int maxDepth,
  }) => attachedDatabase.deckMoveTargets(id, false, maxDepth).watch();

  /// The decks a restore of [itemId], the item root of a batch, may pick,
  /// and the decks on their paths (BR-TRASH-006).
  Future<List<DeckForestRow>> restoreTargetRows(
    String itemId, {
    required int maxDepth,
  }) => attachedDatabase.deckMoveTargets(itemId, true, maxDepth).get();

  /// Fires once, then after every write to the decks or the batches: where
  /// the decks of a Trash selection may go follows both (E2).
  Stream<void> restoreTargetChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.deleteBatches,
  ]);

  /// One statement (`deck_queries.drift`); null when [id] is not an active
  /// deck.
  Future<DeckDeletionSummaryResult?> deletionSummary(String id) =>
      attachedDatabase.deckDeletionSummary(id).getSingleOrNull();

  Future<void> insert(DeckCompanion row) => createDeck(row);

  /// The batch of one deletion, with [id] as its item root (BR-TRASH-001).
  Future<void> insertBatch(String batchId, String id, DateTime now) =>
      insertDeleteBatch(batchId, 'deck', id, now);

  /// Puts [id] and every active deck under it in the batch [batchId], then
  /// every active card of those decks (BR-TRASH-001). A tombstone inside
  /// keeps its older batch (BR-TRASH-003). The walk is cycle-safe and never
  /// capped.
  Future<void> markSubtree(String id, String batchId) async {
    await markDeckSubtreeDeleted(id, batchId);
    await markCardsOfBatchDecksDeleted(batchId);
  }

  /// The item root of [batchId] when the batch holds a deck: the deck the
  /// person deleted, still marked with that batch (BR-TRASH-001). Null when
  /// the batch is gone or holds a card.
  Future<Deck?> itemRootOf(String batchId) =>
      deckOfBatch(batchId).getSingleOrNull();

  /// [id]'s row, active or in the Trash: a restore checks its item against
  /// the item's own root, which may be in the Trash too (BR-TRASH-006).
  Future<Deck?> rowInAnyState(String id) =>
      deckInAnyState(id).getSingleOrNull();

  /// Whether [id] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006).
  Future<bool> isInTrash(String id) => deckIsInTrash(id).getSingle();

  /// The rows of [batchId], decks and cards, lose their mark; then the batch
  /// row goes, which the key would otherwise cascade (BR-TRASH-007).
  Future<void> restoreBatch(String batchId) async {
    await unmarkDecksOfBatch(batchId);
    await unmarkCardsOfBatch(batchId);
    await dropDeleteBatch(batchId);
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      closeSessionsTouchingBatch(now, batchId);

  Future<void> setContentType(String id, String contentType, DateTime now) =>
      setLiveDeckContentType(contentType, now, id);

  /// The end of the sibling group under [parentId]: the largest position
  /// plus one, `0` for a first child. `IS` makes a null parent select the
  /// roots (BR-SRS-007).
  Future<int> nextSiblingPosition(String? parentId) =>
      nextSiblingPositionUnder(parentId).getSingle();

  /// [id] and every deck above it, while they are active. Cycle-safe
  /// (`UNION`) and never capped, as schema.md asks of a tree walk.
  Future<List<String>> ancestorIds(String id) => liveAncestorIds(id).get();

  /// How many levels the subtree of [id] spans, itself included (a leaf is
  /// 1). A depth probe (schema.md): it walks at most [cap] levels, so an
  /// answer of [cap] means "at least [cap]". With the deepest level as [cap],
  /// that answer is already too deep under any parent.
  Future<int> subtreeHeight(String id, {required int cap}) async =>
      (await deckSubtreeHeight(id, cap).getSingle())!;

  /// What [id] holds now: `deck` with a live sub-deck, `card` with a live
  /// card, `unset` with neither (BR-DECK-006, BR-DECK-015). Tombstones do not
  /// count, as in invariants 2 and 29.
  Future<String> contentTypeFromChildren(String id) =>
      deckContentFromChildren(id).getSingle();

  /// Puts [id] under [parentId] at [siblingPosition], and gives its whole
  /// subtree [rootId] and a depth shifted by [depthShift] (BR-DECK-018). The
  /// subtree walk is cycle-safe and never capped.
  Future<void> moveSubtree(
    String id, {
    required String parentId,
    required String rootId,
    required int depthShift,
    required int siblingPosition,
    required DateTime now,
  }) async {
    await placeLiveDeck(parentId, siblingPosition, now, id);
    await reRootDeckSubtree(id, rootId, depthShift, now);
  }
}
```

- [ ] **Step 5: Drop the include and move the allowlist keys.**
  - Delete `    'package:memox/core/database/queries/delete_batch_queries.drift',` from `@DriftDatabase`.
  - In `tombstone_filter_test.dart`, rename these keys and keep their reasons:
    - `deck_dao.dart#nextSiblingPosition` → `lib/core/database/queries/deck_row_queries.drift#nextSiblingPositionUnder`
    - `#subtreeHeight` → `#deckSubtreeHeight`
    - `#moveSubtree` → `#reRootDeckSubtree`
    - `#rowInAnyState` → `#deckInAnyState`

- [ ] **Step 6: Build and match the signatures.** Run build_runner, then read the generated signatures in `deck_dao.g.dart`. The orders below follow first appearance in the SQL; fix the calls to whatever was actually generated.
  - `renameLiveDeck(name, now, deckId)`
  - `setLiveDeckSiblingPosition(position, now, deckId)`
  - `markDeckSubtreeDeleted(deckId, batchId)`
  - `placeLiveDeck(parentId, position, now, deckId)`
  - `reRootDeckSubtree(deckId, rootId, depthShift, now)`
  - `setLiveDeckContentType(contentType, now, deckId)`

  If `deckSubtreeHeight` returns `int` (non-null), drop the `!`. Check that `deckOfBatch` and `deckInAnyState` return `Selectable<Deck>`.

- [ ] **Step 7: Verify.** Add `"deck_row_queries": ["deck", "trash"]` to the impact map, and add `"deck"` to `live_row_queries`. Then run:
  - analyze on `lib/features/deck` and `lib/features/card`;
  - the guard and its tests;
  - the CI tooling tests;
  - `TZ=UTC flutter test test/features/deck/ test/features/card/ test/features/trash/ test/features/study/ test/architecture/`.

  Expected: all green.

- [ ] **Step 8: Commit** `refactor(deck): DeckDao reads and writes through .drift (ADR-020 P3)`.

### Task 2: WBS and gate

- [ ] Run `dod_check.sh`. Expected: green.
- [ ] Set FE-D21 to `xong` in `docs/wbs_FE.md`, regenerate the docs and check them, then commit `docs(wbs): FE-D21 done`.
