# Every query in `.drift`, P2 (card) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `CardDetailDao`, `CardDao` and `CardListDao` to `@DriftAccessor`s whose every query lives in `.drift`. Take `card_dao.dart` and `card_list_dao.dart` off the guard's temporary exclude, and take `card_queries.drift` off `@DriftDatabase`.

**Architecture:** P0 and P1 set the pattern (ADR-020).
- **Card list.** `CardListDao` keeps `_predicate` as the one Dart source of "which cards a query lets through". It feeds `$predicate`, `$isDue`, `$isNew` and `$isFlagged` placeholders, built on the aliases the generated callbacks pass in.
  - The tag clause is the one piece written in SQL, identical in the three filtering queries: `(:tag_count = 0 OR EXISTS (… ct.tag_id IN :tag_ids))`. An `EXISTS` subquery cannot be built as an `Expression` without the builder.
  - The spike (Drift 2.35) confirmed that several Dart placeholders per query, `COUNT(*) FILTER (WHERE $x)` and `$order` on a join all generate correctly.
- **Shared by-id reads.** The live deck and card lookups go to a shared `live_row_queries.drift`, per D3. `SettingsDao` (P1) switches to it, and `DeckDao` (P3) will include it.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, Python 3.13 guard.

**Spec:** `docs/superpowers/specs/2026-10-01-drift-queries-only-design.md` (§4 P2; D1–D7, D11, D12). ADR-020.

## Global Constraints

- Behaviour-preserving: no schema, `schemaVersion` or index change.
- Generated `*.g.dart` is not committed; run `dart run build_runner build --delete-conflicting-outputs` after each `.drift` / accessor change.
- Guard commands use `python3.13`.
- **Generated parameter order.** Parameters follow the first appearance of each variable or placeholder in the SQL body, not the order in the header. After each build, read the generated signatures and match the calls to them. Never reorder the SQL to fit a call.
- **Writes to `deck` and `card` in `.drift` must name `delete_batch_id`.** `test/architecture/tombstone_filter_test.dart` treats them as reads. Unlike the builder rule, the `.drift` rule has no write-by-id exemption. A statement that reads tombstones on purpose needs an allowlist entry keyed `<file>#<queryName>`. A renamed or moved statement must move its entry.
- Every new `queries/*.drift` file gets an owner row in `verification_impact_map.json`.
- A query name must not collide with a DAO method name.
- Commit messages: `type(scope): summary` plus the session attribution lines.

## Review Focus

1. **The list, its counts and Select all agree under every filter, search and tag combination (BR-CARD-012).** Pinned by `card_list_read_test` (17 tests) and `card_list_tag_filter_test` (8 tests).
2. **One emission is still exactly four statements, and a change emits once.** Pinned by `card_list_read_test` ("an emission is four statements…").
3. **A card or deck in the Trash is out of reach of every write.** The new `AND delete_batch_id IS NULL` filters must not refuse a live row. A restore matches the card by its own batch. Pinned by `card_trash_test`, `card_restore_test` and `card_batch_writes_test`.
4. **The tag clause does not change the window's query plan when no tag is selected.** Task 3 Step 6 runs `EXPLAIN QUERY PLAN` before and after (D12).
5. **Chunked reads and writes past the bind limit.** Pinned by `card_batch_limit_test`.

---

### Task 1: `CardDetailDao` and `card_queries.drift` off `@DriftDatabase`

**Files:**
- Modify: `lib/core/database/queries/card_queries.drift:43` (`AS DeckForestRow` → `AS CardMoveTargetRow`)
- Modify: `lib/core/database/app_database.dart` (drop the `card_queries.drift` include line)
- Modify: `lib/features/card/data/datasources/card_detail_dao.dart` (whole file)
- Modify: `lib/features/card/data/mappers/card_mapper.dart` (import; `deckTreeNodeOf(CardMoveTargetRow row)`)
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart`, wherever it names `DeckForestRow` for card rows
- Tests (existing): `test/features/card/data/card_detail_read_test.dart`, `card_restore_targets_test.dart`, `test/features/card/`

**Interfaces:**
- Produces:
  - `CardDetailDao(AppDatabase)` with unchanged method names. `watchMoveTargetRows` and `restoreTargetRows` now yield `CardMoveTargetRow`.
  - `CardDetailResult`, `CardHistoryRow` and `CardMoveTargetRow` are generated into `card_detail_dao.g.dart`. Import `card_detail_dao.dart` to reach them.

- [ ] **Step 1: Rename the result.** In `card_queries.drift` change `  AS DeckForestRow:` (the `cardMoveTargets` header) to `  AS CardMoveTargetRow:`.
- [ ] **Step 2: Drop the include.** Delete `    'package:memox/core/database/queries/card_queries.drift',` from `@DriftDatabase` in `app_database.dart`.
- [ ] **Step 3: DAO.** Replace `card_detail_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

part 'card_detail_dao.g.dart';

/// The reads of one card (`card_queries.drift`). They write nothing
/// (BR-CARD-013).
@DriftAccessor(
  include: {'package:memox/core/database/queries/card_queries.drift'},
)
final class CardDetailDao extends DatabaseAccessor<AppDatabase>
    with _$CardDetailDaoMixin {
  CardDetailDao(super.attachedDatabase);

  /// The card, its schedule row and its tags; empty once the card is gone or
  /// in the Trash. Emits again when any of them changes.
  Stream<List<CardDetailResult>> watchDetail(String cardId) =>
      cardDetail(cardId).watch();

  /// Up to [limit] log rows after [afterAnsweredAt], [afterId], newest first,
  /// in one statement. Empty when the card is not active; one row with a
  /// null log when it has no answer there.
  Future<List<CardHistoryRow>> historyRows(
    String cardId, {
    required DateTime? afterAnsweredAt,
    required String? afterId,
    required int limit,
  }) => cardHistoryPage(afterAnsweredAt, afterId, cardId, limit).get();

  /// The decks of the source's tree, candidates marked (BR-CARD-010).
  Stream<List<CardMoveTargetRow>> watchMoveTargetRows(String sourceDeckId) =>
      cardMoveTargets(sourceDeckId, null).watch();

  /// The decks of [rootId]'s tree, candidates marked: where cards of that
  /// root may go back (BR-TRASH-006).
  Future<List<CardMoveTargetRow>> restoreTargetRows(String rootId) =>
      cardMoveTargets(null, rootId).get();
}
```

- [ ] **Step 4: Build, then fix the types.** Run build_runner and `flutter analyze --no-fatal-infos lib/features/card`. For every error that names `DeckForestRow` in a card file, or an undefined `CardDetailResult` / `CardHistoryRow`:
  - add `import 'package:memox/features/card/data/datasources/card_detail_dao.dart';`;
  - change `DeckForestRow` to `CardMoveTargetRow` in that card file.

  Deck files keep `DeckForestRow` from `app_database.dart` until P3. Expected: no issues.
- [ ] **Step 5: Verify.** Run `TZ=UTC flutter test test/features/card/ test/features/trash/`, then the guard. Expected: all passed.
- [ ] **Step 6: Commit** `refactor(card): CardDetailDao owns card_queries.drift (ADR-020 P2)`.

---

### Task 2: `CardDao`, plus the shared live-row reads

**Files:**
- Create: `lib/core/database/queries/live_row_queries.drift`, `lib/core/database/queries/card_row_queries.drift`
- Modify: `lib/core/database/queries/delete_batch_queries.drift` (add `dropDeleteBatch`)
- Modify: `lib/core/database/queries/settings_queries.drift` (remove `liveDeckRow`); `lib/features/settings/data/datasources/settings_dao.dart` (also include `live_row_queries.drift`)
- Modify: `lib/features/card/data/datasources/card_dao.dart` (whole file)
- Modify: `test/architecture/tombstone_filter_test.dart` (the `card_dao.dart#rootIdsOf` entry moves to `card_row_queries.drift#deckRootsInAnyState`)
- Modify: guard `scopes.yaml`, `MIGRATED_TO_DRIFT`, impact map
- Tests (existing): `test/features/card/`, `test/features/transfer/`, `test/features/trash/`, `test/features/settings/`, `test/architecture/`

**Interfaces:**
- Consumes: `delete_batch_queries.drift` (`insertDeleteBatch`, `deckIsInTrash`, `closeSessionsTouchingBatch`), still also included on `AppDatabase` for `deck_dao` until P3.
- Produces:
  - `CardDao(AppDatabase)` with unchanged method names and types.
  - `live_row_queries.drift` with `liveDeckRow(:deck_id)` and `liveCardRow(:card_id)`.

- [ ] **Step 1: Red.** Delete `      - lib/features/card/data/datasources/card_dao.dart` from `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `card_dao.dart`.

- [ ] **Step 2: Shared queries.** Create `lib/core/database/queries/live_row_queries.drift`:

```sql
import '../tables/deck.drift';
import '../tables/card.drift';

-- The deck :deck_id names, unless it is in the Trash.
liveDeckRow(:deck_id AS TEXT):
SELECT * FROM deck WHERE id = :deck_id AND delete_batch_id IS NULL;

-- The card :card_id names, unless it is in the Trash.
liveCardRow(:card_id AS TEXT):
SELECT * FROM card WHERE id = :card_id AND delete_batch_id IS NULL;
```

Delete `liveDeckRow` and its comment from `settings_queries.drift`. Add `'package:memox/core/database/queries/live_row_queries.drift'` to `SettingsDao`'s `include`.

Append to `delete_batch_queries.drift`:

```sql
-- BR-TRASH-007: a restored item's batch goes, which the key would
-- otherwise cascade.
dropDeleteBatch(:batch_id AS TEXT):
DELETE FROM delete_batches WHERE id = :batch_id;
```

- [ ] **Step 3: Card queries.** Create `lib/core/database/queries/card_row_queries.drift`:

```sql
import '../tables/card.drift';
import '../tables/deck.drift';
import '../tables/trash.drift';

-- Spec §8: a card or deck in the Trash is out of reach of every read and
-- write here, except where a query says why.

-- BE-C2: the active cards among :card_ids, one chunk at a time.
liveCardsIn:
SELECT * FROM card WHERE id IN :card_ids AND delete_batch_id IS NULL
ORDER BY id;

-- BE-C2: the active decks among :deck_ids, one chunk at a time.
liveDecksIn:
SELECT * FROM deck WHERE id IN :deck_ids AND delete_batch_id IS NULL
ORDER BY id;

-- BR-TRANSFER-003: the folded faces of the live cards of :deck_id.
liveCardFacesOfDeck(:deck_id AS TEXT) AS CardFacesRow:
SELECT front_folded, back_folded FROM card
WHERE deck_id = :deck_id AND delete_batch_id IS NULL;

liveCardCountOfDeck(:deck_id AS TEXT):
SELECT COUNT(*) FROM card WHERE deck_id = :deck_id AND delete_batch_id IS NULL;

-- BR-TRANSFER-010: the live cards of :deck_id by created_at, then id.
exportCardsOfDeck(:deck_id AS TEXT):
SELECT * FROM card WHERE deck_id = :deck_id AND delete_batch_id IS NULL
ORDER BY created_at, id;

-- BR-TRANSFER-010, BE-C2: those among :card_ids, one chunk at a time.
exportCardsIn(:deck_id AS TEXT):
SELECT * FROM card
WHERE deck_id = :deck_id AND delete_batch_id IS NULL AND id IN :card_ids
ORDER BY created_at, id;

createCard: INSERT INTO card $row;

updateLiveCard(:card_id AS TEXT):
UPDATE card SET $values WHERE id = :card_id AND delete_batch_id IS NULL;

-- BR-TRASH-001: the card goes to the Trash as the item root of :batch_id.
markCardDeleted(:card_id AS TEXT, :batch_id AS TEXT):
UPDATE card SET delete_batch_id = :batch_id
WHERE id = :card_id AND delete_batch_id IS NULL;

-- BR-TRASH-001: the card of :batch_id when the batch holds one, still
-- marked with that batch.
cardOfBatch(:batch_id AS TEXT):
SELECT c.* FROM delete_batches b
JOIN card c ON c.id = b.root_item_id AND c.delete_batch_id = b.id
WHERE b.id = :batch_id AND b.item_type = 'card';

-- BR-TRASH-006: the roots of :deck_ids, active or in the Trash: a restore
-- checks a card against the root of its deck, which may be in the Trash.
deckRootsInAnyState:
SELECT root_id FROM deck WHERE id IN :deck_ids ORDER BY root_id;

-- BR-TRASH-007: the card comes back from the batch it is marked with.
restoreCard(:card_id AS TEXT, :batch_id AS TEXT):
UPDATE card SET $values WHERE id = :card_id AND delete_batch_id = :batch_id;

-- BE-C2: moves the live cards among :card_ids into :deck_id.
moveLiveCardsIn(:deck_id AS TEXT, :now AS DATETIME):
UPDATE card SET deck_id = :deck_id, updated_at = :now
WHERE id IN :card_ids AND delete_batch_id IS NULL;

-- BE-C2: writes only the live cards whose flag differs from :flag.
flagLiveCardsIn(:flag AS INTEGER, :now AS DATETIME):
UPDATE card SET is_flagged = :flag, updated_at = :now
WHERE id IN :card_ids AND is_flagged <> :flag AND delete_batch_id IS NULL;

-- Invariant 29: whether :deck_id still holds a live card.
deckHoldsLiveCards(:deck_id AS TEXT):
SELECT EXISTS (
  SELECT 1 FROM card WHERE deck_id = :deck_id AND delete_batch_id IS NULL
);

-- A deck in the Trash keeps its row as it is.
setLiveDeckContentType(:deck_id AS TEXT, :content_type AS TEXT,
  :now AS DATETIME):
UPDATE deck SET content_type = :content_type, updated_at = :now
WHERE id = :deck_id AND delete_batch_id IS NULL;
```

- [ ] **Step 4: DAO.** Replace the class in `card_dao.dart`, keeping `_contentOf` and its imports, with:

```dart
part 'card_dao.g.dart';

/// Row access for `card`, plus the reads and writes of the owning `deck` row
/// that card writes need (`card_row_queries.drift`). It returns Drift rows,
/// never domain entities, and runs inside the caller's transaction. A card
/// or deck in the Trash is out of reach of every write (spec §8).
@DriftAccessor(
  include: {
    'package:memox/core/database/queries/card_row_queries.drift',
    'package:memox/core/database/queries/live_row_queries.drift',
    'package:memox/core/database/queries/delete_batch_queries.drift',
  },
)
final class CardDao extends DatabaseAccessor<AppDatabase>
    with _$CardDaoMixin {
  CardDao(super.attachedDatabase);

  Future<CardRow?> findRow(String id) => liveCardRow(id).getSingleOrNull();

  /// The active cards among [ids], read in chunks (BE-C2).
  Future<List<CardRow>> liveRows(Set<String> ids) async => [
    for (final chunk in idChunks(ids)) ...await liveCardsIn(chunk).get(),
  ];

  Future<Deck?> deckRow(String id) => liveDeckRow(id).getSingleOrNull();

  /// The active decks among [ids], read in chunks (BE-C2).
  Future<List<Deck>> deckRows(Set<String> ids) async => [
    for (final chunk in idChunks(ids)) ...await liveDecksIn(chunk).get(),
  ];

  /// The folded faces of the live cards of [deckId] (BR-TRANSFER-003).
  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async => {
    for (final row in await liveCardFacesOfDeck(deckId).get())
      (front: row.frontFolded, back: row.backFolded),
  };

  /// How many live cards [deckId] holds.
  Future<int> liveCount(String deckId) =>
      liveCardCountOfDeck(deckId).getSingle();

  /// The live cards of [deckId], or those among [ids], by `created_at`, then
  /// `id` (BR-TRANSFER-010). [ids] are read in chunks, and the whole set is
  /// ordered once they are all in (BE-C2).
  Future<List<CardRow>> exportRows(String deckId, Set<String>? ids) async {
    if (ids == null) return exportCardsOfDeck(deckId).get();
    final rows = [
      for (final chunk in idChunks(ids))
        ...await exportCardsIn(deckId, chunk).get(),
    ];
    // Each chunk is ordered on its own; the export's order is the whole
    // set's.
    return rows..sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
  }

  Future<void> insertCard({
    required String id,
    required String deckId,
    required CardDraft draft,
    required DateTime now,
  }) => createCard(
    _contentOf(draft).copyWith(
      id: Value(id),
      deckId: Value(deckId),
      createdAt: Value(now),
      updatedAt: Value(now),
    ),
  );

  Future<void> updateContent(String id, CardDraft draft, DateTime now) =>
      updateLiveCard(_contentOf(draft).copyWith(updatedAt: Value(now)), id);

  /// [id] goes to the Trash as the item root of the batch [batchId]
  /// (BR-TRASH-001). The row stays as it is otherwise; only a purge deletes
  /// it, and its schedule, logs and tag links with it.
  Future<void> moveToTrash(String id, String batchId, DateTime now) async {
    await insertDeleteBatch(batchId, 'card', id, now);
    await markCardDeleted(batchId, id);
  }

  /// The card of [batchId] when the batch holds one: the card the person
  /// deleted, still marked with that batch (BR-TRASH-001). Null when the
  /// batch is gone or holds a deck.
  Future<CardRow?> itemOf(String batchId) =>
      cardOfBatch(batchId).getSingleOrNull();

  /// The roots of [deckIds], active or in the Trash: a restore checks a card
  /// against the root of its deck, which may be in the Trash (BR-TRASH-006).
  /// Read in chunks (BE-C2).
  Future<Set<String>> rootIdsOf(Set<String> deckIds) async => {
    for (final chunk in idChunks(deckIds))
      ...await deckRootsInAnyState(chunk).get(),
  };

  /// Fires once, then after every write to the decks, the cards or the
  /// batches: where the cards of a Trash selection may go follows all three
  /// (E2).
  Stream<void> restoreTargetChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.deck,
    attachedDatabase.card,
    attachedDatabase.deleteBatches,
  ]);

  /// Whether [deckId] is a deck in the Trash, which a restore refuses as its
  /// target (BR-TRASH-006).
  Future<bool> isDeckInTrash(String deckId) =>
      deckIsInTrash(deckId).getSingle();

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
    await restoreCard(
      CardCompanion(
        deleteBatchId: const Value(null),
        deckId: Value(deckId),
        updatedAt: updatedAt == null ? const Value.absent() : Value(updatedAt),
      ),
      cardId,
      batchId,
    );
    await dropDeleteBatch(batchId);
  }

  /// The open sessions [batchId] touches end (BR-TRASH-004).
  Future<void> closeSessionsTouching(String batchId, DateTime now) =>
      closeSessionsTouchingBatch(now, batchId);

  /// Moves [ids] into [deckId], in chunks (BE-C2).
  Future<void> moveCards(Set<String> ids, String deckId, DateTime now) async {
    for (final chunk in idChunks(ids)) {
      await moveLiveCardsIn(deckId, now, chunk);
    }
  }

  /// Writes only the cards whose flag differs from [isFlagged], in chunks
  /// (BE-C2).
  Future<void> setFlagged(Set<String> ids, bool isFlagged, DateTime now) async {
    final flag = isFlagged ? 1 : 0;
    for (final chunk in idChunks(ids)) {
      await flagLiveCardsIn(flag, now, chunk);
    }
  }

  /// Whether [deckId] still holds a live card; tombstones do not count, as in
  /// invariant 29.
  Future<bool> holdsCards(String deckId) =>
      deckHoldsLiveCards(deckId).getSingle();

  /// A deck in the Trash keeps its row as it is.
  Future<void> setDeckContentType(
    String deckId,
    String contentType,
    DateTime now,
  ) => setLiveDeckContentType(contentType, now, deckId);
}
```

- [ ] **Step 5: Allowlist.** In `test/architecture/tombstone_filter_test.dart`, replace the key `'lib/features/card/data/datasources/card_dao.dart#rootIdsOf'` with `'lib/core/database/queries/card_row_queries.drift#deckRootsInAnyState'` and keep its reason.

- [ ] **Step 6: Build and match the signatures.**
  - Run build_runner, then `grep -nE "^  (Selectable|Future)<[^>]+> [a-zA-Z]+\(" -A4 lib/features/card/data/datasources/card_dao.g.dart`.
  - Make every call in Step 4 match the generated order. The expected orders, by first appearance in the SQL, are:
    - `updateLiveCard(values, cardId)`
    - `markCardDeleted(batchId, cardId)`
    - `restoreCard(values, cardId, batchId)`
    - `moveLiveCardsIn(deckId, now, cardIds)`
    - `flagLiveCardsIn(flag, now, cardIds)`
    - `setLiveDeckContentType(contentType, now, deckId)`
    - `exportCardsIn(deckId, cardIds)`
  - Also check that `cardOfBatch` returns `Selectable<CardRow>`. If it returns a generated result class instead, change the query to `SELECT c.**` and map with `.map((row) => row.c)`.
  - Do the same signature check for `settings_dao.g.dart` (`liveDeckRow(deckId)`).

- [ ] **Step 7: Verify.** Add to the impact map `"card_row_queries": ["card", "transfer", "trash"]` and `"live_row_queries": ["card", "settings"]`. Then run:
  - analyze on `lib/features/card` and `lib/features/settings`;
  - the guard and its tests;
  - the CI tooling tests;
  - `TZ=UTC flutter test test/features/card/ test/features/transfer/ test/features/trash/ test/features/settings/ test/architecture/`.

  Expected: all green.

- [ ] **Step 8: Commit** `refactor(card): CardDao reads and writes through .drift (ADR-020 P2)`.

---

### Task 3: `CardListDao`

**Files:**
- Create: `lib/core/database/queries/card_list_queries.drift`
- Modify: `lib/features/card/data/datasources/card_list_dao.dart` (whole file)
- Modify: guard `scopes.yaml`, `MIGRATED_TO_DRIFT`, impact map
- Tests (existing): `test/features/card/data/card_list_read_test.dart`, `card_list_tag_filter_test.dart`, `test/features/card/`

**Interfaces:**
- Produces: `CardListDao(AppDatabase)` with unchanged `window`, `counts`, `ids`, `activeSchedules`, `tagsOf` and `changes` signatures.

- [ ] **Step 1: Baseline plan.** Before any change, run this in a scratch test (`/tmp`, not committed) or a `dart` REPL against a test database:

```
EXPLAIN QUERY PLAN SELECT ... (the window SQL the builder emits for deck 'd', no search, filter all, no tag, newest, limit 51)
```

To capture that SQL, wrap the test database with `test/support/test_database.dart`'s `SelectCounter`-style interceptor and print the statement. Record the plan lines in the ledger.

- [ ] **Step 2: Red.** Delete `      - lib/features/card/data/datasources/card_list_dao.dart` from `scopes.yaml` and add it to `MIGRATED_TO_DRIFT`. Run the guard. Expected: exit 1 on `card_list_dao.dart`.

- [ ] **Step 3: Queries.** Create `lib/core/database/queries/card_list_queries.drift`:

```sql
import '../tables/card.drift';
import '../tables/srs.drift';
import '../tables/tags.drift';

-- UC-CARD-001. CardListDao._predicate is the one place that says which
-- cards a query lets through (BR-CARD-012). The tag clause is the one part
-- written here, the same in the three queries that filter (BR-TAG-004): an
-- EXISTS on card_tags, one boolean per card, never a join that repeats a
-- card; :tag_count 0 means no tag is selected.

-- Up to :row_limit cards with their schedule rows, in $order.
cardListWindow AS CardListEntryRow:
SELECT c.**, s.**
FROM card c INNER JOIN card_schedule s ON s.card_id = c.id
WHERE $predicate AND (:tag_count = 0 OR EXISTS (
  SELECT 1 FROM card_tags ct
  WHERE ct.card_id = c.id AND ct.tag_id IN :tag_ids))
ORDER BY $order
LIMIT :row_limit;

-- IT-ORG-005: All, Due, New and Flagged under the search and the tags,
-- whatever the filter, in one statement.
cardListCounts AS CardListCountsRow:
SELECT COUNT(*) AS all_count,
  COUNT(*) FILTER (WHERE $isDue) AS due_count,
  COUNT(*) FILTER (WHERE $isNew) AS new_count,
  COUNT(*) FILTER (WHERE $isFlagged) AS flagged_count
FROM card c INNER JOIN card_schedule s ON s.card_id = c.id
WHERE $inDeck AND (:tag_count = 0 OR EXISTS (
  SELECT 1 FROM card_tags ct
  WHERE ct.card_id = c.id AND ct.tag_id IN :tag_ids));

-- BR-CARD-012: every card the query lets through, not only a window.
cardListIds:
SELECT c.id
FROM card c INNER JOIN card_schedule s ON s.card_id = c.id
WHERE $predicate AND (:tag_count = 0 OR EXISTS (
  SELECT 1 FROM card_tags ct
  WHERE ct.card_id = c.id AND ct.tag_id IN :tag_ids));

-- BR-CARD-008: the schedule rows of every active card of :deck_id, outside
-- any search or filter.
activeSchedulesOfDeck(:deck_id AS TEXT):
SELECT s.* FROM card_schedule s INNER JOIN card c ON c.id = s.card_id
WHERE c.deck_id = :deck_id AND c.delete_batch_id IS NULL;

-- BR-TAG-001, BE-C2: the tags of :card_ids, each card's by folded name then
-- id, one chunk of cards at a time.
cardTagsIn AS CardTagRow:
SELECT ct.card_id AS card_id, t.**
FROM card_tags ct INNER JOIN tags t ON t.id = ct.tag_id
WHERE ct.card_id IN :card_ids
ORDER BY t.name_folded, t.id;
```

- [ ] **Step 4: DAO.** Replace `card_list_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/id_chunks.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';

part 'card_list_dao.g.dart';

/// The card list read model (UC-CARD-001): a window, the filter counts, the
/// deck's display states and the window's tags (`card_list_queries.drift`).
/// Every filtered read takes [_predicate] and the tag clause of its query,
/// so the list, its counts and Select all never disagree about which cards a
/// query lets through (BR-CARD-012).
@DriftAccessor(
  include: {'package:memox/core/database/queries/card_list_queries.drift'},
)
final class CardListDao extends DatabaseAccessor<AppDatabase>
    with _$CardListDaoMixin {
  CardListDao(super.attachedDatabase);

  /// Up to [limit] cards with their schedule rows, in [query]'s order.
  Future<List<(CardRow, CardSchedule)>> window({
    required String deckId,
    required CardListQuery query,
    required int limit,
    required DateTime now,
  }) async {
    final tagIds = query.tagIds.toList();
    final rows = await cardListWindow(
      (c, s) => _predicate(c, s, deckId: deckId, query: query, now: now),
      tagIds.length,
      tagIds,
      (c, s) => OrderBy(_order(c, s, query.sort)),
      limit,
    ).get();
    return [for (final row in rows) (row.c, row.s)];
  }

  /// All, Due, New and Flagged under [searchTerm] and [tagIds], whatever the
  /// filter, in one statement (IT-ORG-005, BR-TAG-004).
  Future<({int all, int due, int newCards, int flagged})> counts({
    required String deckId,
    required String searchTerm,
    required Set<String> tagIds,
    required DateTime now,
  }) async {
    final tags = tagIds.toList();
    final row = await cardListCounts(
      (c, s) => _passes(c, s, CardListFilter.due, now),
      (c, s) => _passes(c, s, CardListFilter.newCards, now),
      (c, s) => _passes(c, s, CardListFilter.flagged, now),
      (c, s) => _inDeck(c, deckId, searchTerm),
      tags.length,
      tags,
    ).getSingle();
    return (
      all: row.allCount,
      due: row.dueCount,
      newCards: row.newCount,
      flagged: row.flaggedCount,
    );
  }

  /// BR-CARD-012: every card [query] lets through, not only a window.
  Future<Set<String>> ids({
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) async {
    final tagIds = query.tagIds.toList();
    return (await cardListIds(
      (c, s) => _predicate(c, s, deckId: deckId, query: query, now: now),
      tagIds.length,
      tagIds,
    ).get()).toSet();
  }

  /// The schedule rows of every active card of [deckId], outside any search
  /// or filter, for the display-state counts (BR-CARD-008).
  Future<List<CardSchedule>> activeSchedules(String deckId) =>
      activeSchedulesOfDeck(deckId).get();

  /// The tags of [cardIds], each card's by folded name then id (BR-TAG-001).
  /// One statement per chunk of cards (BE-C2): a card's tags all come from
  /// its own chunk, so each list keeps its order. No statement for no card.
  Future<Map<String, List<Tag>>> tagsOf(List<String> cardIds) async {
    if (cardIds.isEmpty) return const {};
    final byCard = <String, List<Tag>>{};
    for (final chunk in idChunks(cardIds)) {
      for (final row in await cardTagsIn(chunk).get()) {
        byCard.putIfAbsent(row.cardId, () => []).add(row.t);
      }
    }
    return byCard;
  }

  /// Fires after every write to a table the list reads: cards, schedules,
  /// and the tags on cards. A transaction fires once.
  Stream<void> changes() => attachedDatabase.tableUpdates(
    TableUpdateQuery.onAllTables([
      attachedDatabase.card,
      attachedDatabase.cardSchedule,
      attachedDatabase.cardTags,
      attachedDatabase.tags,
    ]),
  );

  /// The one Dart place that says which cards a query lets through: the
  /// active cards of [deckId], under the search, through the filter. The
  /// tag clause is its query's (BR-TAG-004).
  Expression<bool> _predicate(
    Card c,
    CardScheduleTable s, {
    required String deckId,
    required CardListQuery query,
    required DateTime now,
  }) =>
      _inDeck(c, deckId, query.searchTerm) & _passes(c, s, query.filter, now);

  /// The search matches the folded term inside a folded side with `instr`,
  /// so `%` and `_` are plain characters and nothing needs escaping.
  Expression<bool> _inDeck(Card c, String deckId, String searchTerm) {
    final inDeck = c.deckId.equals(deckId) & c.deleteBatchId.isNull();
    final term = foldText(searchTerm);
    if (term.isEmpty) return inDeck;
    return inDeck & (_holds(c.frontFolded, term) | _holds(c.backFolded, term));
  }

  Expression<bool> _passes(
    Card c,
    CardScheduleTable s,
    CardListFilter filter,
    DateTime now,
  ) => switch (filter) {
    CardListFilter.all => const Constant(true),
    CardListFilter.due =>
      s.learnedAt.isNotNull() & s.dueAt.isSmallerOrEqualValue(now),
    CardListFilter.newCards => s.learnedAt.isNull(),
    CardListFilter.flagged => c.isFlagged.equals(1),
  };

  List<OrderingTerm> _order(Card c, CardScheduleTable s, CardListSort sort) =>
      switch (sort) {
        CardListSort.newest => [
          OrderingTerm.desc(c.createdAt),
          OrderingTerm.desc(c.id),
        ],
        CardListSort.dueFirst => [
          OrderingTerm.asc(s.learnedAt.isNull()),
          OrderingTerm.asc(s.dueAt),
          OrderingTerm.desc(c.createdAt),
          OrderingTerm.desc(c.id),
        ],
      };
}

Expression<bool> _holds(Expression<String> folded, String term) =>
    FunctionCallExpression<int>('instr', [
      folded,
      Variable<String>(term),
    ]).isBiggerThanValue(0);
```

- [ ] **Step 5: Build and match.** Run build_runner, then read the generated signatures of `cardListWindow`, `cardListCounts`, `cardListIds`, `activeSchedulesOfDeck` and `cardTagsIn` in `card_list_dao.g.dart`. Make the calls in Step 4 match the generated order, which follows first appearance:
  - `cardListWindow`: predicate, tagCount, tagIds, order, rowLimit;
  - `cardListCounts`: isDue, isNew, isFlagged, inDeck, tagCount, tagIds.

  Also check:
  - that `activeSchedulesOfDeck` returns `Selectable<CardSchedule>`;
  - the nested field names of `CardListEntryRow` (`c`, `s`) and `CardTagRow` (`cardId`, `t`);
  - that `readsFrom` covers `card`, `cardSchedule` and `cardTags`, plus `tags` for `cardTagsIn`.

- [ ] **Step 6: Plan after (D12).** Repeat Step 1's `EXPLAIN QUERY PLAN` on the generated window SQL, once with no tag and once with one tag. Expected: the same index on `card(deck_id, …)` as the baseline. A `SCAN card` where the baseline used an index is a stop: record it, and split the tag clause into a tagged and an untagged query.

- [ ] **Step 7: Verify.** Add `"card_list_queries": ["card"]` to the impact map. Then run:
  - analyze on `lib/features/card`;
  - the guard and its tests;
  - the CI tooling tests;
  - `TZ=UTC flutter test test/features/card/ test/architecture/`, including "an emission is four statements".

  Expected: all green.

- [ ] **Step 8: Commit** `refactor(card): CardListDao composes $predicate/$order over .drift (ADR-020 P2)`.

---

### Task 4: WBS and gate

- [ ] Run `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. Expected: `✓ mechanical gates passed`.
- [ ] Run `git diff --stat <P2 base>...HEAD -- 'test/**/goldens/*.png' 'lib/features/*/presentation/**'`. Expected: empty.
- [ ] Set FE-D19 in `docs/wbs_FE.md` to `xong`, with the plan link and "`dod_check.sh` xanh" as evidence. Run `python3 tools/docs/generate.py && python3 tools/docs/check.py` and expect PASS. Commit `docs(wbs): FE-D19 done`.
