# G2 — BE-C2: chunked batches; BE-C1 closed — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** a batch operation on more ids than SQLite binds in one statement
(32 766) works, giving the same result as it does on a small set, inside
the operation's one transaction.

**Architecture:**

- One helper in `lib/core/database/id_chunks.dart` splits an id set into
  chunks of at most 30 000.
- Each DAO method that takes a user-sized id set runs its statement once per
  chunk, then combines the results as the statement's meaning requires:
  - concatenate the rows;
  - re-sort them where the statement orders its rows;
  - de-duplicate where a disjunct matches outside the id set;
  - sum counts.
- Everything stays in the caller's transaction, so atomicity does not change.

**Tech Stack:** Flutter 3.47.5, Drift 2.35, SQLite (`SQLITE_MAX_VARIABLE_NUMBER` 32 766).

**Spec:** [2026-09-27-local-backend-completion-design.md](../specs/2026-09-27-local-backend-completion-design.md) §5. Approved by the owner; this plan needs no further approval.

## Global Constraints

- Default chunk: 30 000 ids.
- Chunk only id sets whose size a person controls. These are the Select all
  of the card list and the Trash, and a tag attached to many cards.
- Id sets bounded by construction stay as they are:
  - a page of cards;
  - a tag filter;
  - the cards of one study session;
  - the lapse actions.
- A chunked read returns what the unchunked read returned: the same rows,
  in the same order, with no duplicates.
- No new transaction: the chunks run in the caller's transaction.
- Commits end with this session's two trailers.

## Review Focus

1. **An ordered read across chunks.** `exportRows` must keep
   `created_at, id` order over the whole set, not within each chunk.
   Pinned in Task 2.
2. **A disjunct outside the id set.** `purgeCandidates` (`chosen OR
   deleted_at <= cutoff`) must not return an expired batch once per chunk.
   Pinned in Task 3.
3. **Aggregates.** `tagCounts` and `liveCardCount` must sum per tag and in
   total across chunks. Pinned in Task 3.
4. **An empty set.** It runs no statement and returns an empty result, as
   `isIn({})` did. Pinned in Task 1.
5. **Exactly the limit.** 30 000 ids is one chunk and 30 001 is two. Pinned
   in Task 1.

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/database/id_chunks.dart` | create | `idChunks`, `sqliteIdChunk` |
| `lib/features/card/data/datasources/card_dao.dart` | modify | `liveRows`, `deckRows`, `rootIdsOf`, `exportRows`, `moveCards`, `setFlagged` |
| `lib/features/tags/data/datasources/tag_dao.dart` | modify | `liveCardCount`, `cardsCarrying`, `tagCounts`, `unlink` |
| `lib/features/trash/data/datasources/trash_dao.dart` | modify | `purgeCandidates` |
| `test/core/database/id_chunks_test.dart` | create | the helper |
| `test/features/card/data/card_batch_limit_test.dart` | create | card batches past the limit |
| `test/features/tags/data/tag_batch_limit_test.dart` | create | tag batches past the limit |
| `test/features/trash/data/trash_batch_limit_test.dart` | create | a purge of many chosen batches |
| `docs/wbs_BE.md` | modify | BE-C2 `xong`, BE-C1 closed |

---

### Task 1: The chunk helper

**Files:**
- Create: `lib/core/database/id_chunks.dart`,
  `test/core/database/id_chunks_test.dart`.

**Interfaces — Produces:**
- `const int sqliteIdChunk = 30000;`
- `List<List<T>> idChunks<T>(Iterable<T> ids, {int size = sqliteIdChunk})`:
  - chunks in iteration order, each at most `size`;
  - an empty input gives `[]`.

- [ ] **Step 1: Write the failing test.**

  ```dart
  import 'package:flutter_test/flutter_test.dart';
  import 'package:memox/core/database/id_chunks.dart';

  // BE-C2: an id set larger than SQLite binds goes in chunks (local backend
  // spec 2026-09-27 §5).
  void main() {
    test('ids go in chunks of at most the size, in their order', () {
      expect(idChunks(['a', 'b', 'c', 'd', 'e'], size: 2), [
        ['a', 'b'],
        ['c', 'd'],
        ['e'],
      ]);
    });

    test('an empty set is no chunk, so no statement runs', () {
      expect(idChunks(<String>[]), isEmpty);
    });

    test('exactly the default size is one chunk; one more is two', () {
      final ids = [for (var i = 0; i < sqliteIdChunk + 1; i++) '$i'];
      expect(idChunks(ids.take(sqliteIdChunk)), hasLength(1));
      expect(idChunks(ids).map((chunk) => chunk.length), [sqliteIdChunk, 1]);
    });

    test('the default stays under SQLite bind limit with room to spare', () {
      expect(sqliteIdChunk, lessThan(32766));
    });
  }
  ```

- [ ] **Step 2: Run it.**

  Run: `flutter test test/core/database/id_chunks_test.dart`

  Expected: FAIL, because `id_chunks.dart` does not exist yet.

- [ ] **Step 3: Implement.**

  ```dart
  /// How many ids one statement binds. SQLite binds at most 32 766 variables
  /// (`SQLITE_MAX_VARIABLE_NUMBER`); the rest of a statement's variables fit
  /// in what is left (BE-C2).
  const int sqliteIdChunk = 30000;

  /// [ids] in chunks of at most [size], in their order. A DAO runs its
  /// statement once per chunk, in the caller's transaction, and combines the
  /// results as the statement means them. An empty set is no chunk.
  List<List<T>> idChunks<T>(Iterable<T> ids, {int size = sqliteIdChunk}) {
    final all = ids.toList();
    return [
      for (var start = 0; start < all.length; start += size)
        all.sublist(start, start + size > all.length ? all.length : start + size),
    ];
  }
  ```

- [ ] **Step 4: Run.** Run the command of Step 2. Expected: PASS.

- [ ] **Step 5: Commit.**

  `feat(core): idChunks — ids in chunks under SQLite's bind limit (BE-C2 G2)`

---

### Task 2: Card batches past the limit

**Files:**
- Modify: `lib/features/card/data/datasources/card_dao.dart`.
- Create: `test/features/card/data/card_batch_limit_test.dart`.

**Interfaces — Consumes:** `idChunks`, `sqliteIdChunk` (Task 1).

- [ ] **Step 1: Write the failing test.**

  The seed inserts 33 000 cards in one statement, through a recursive CTE, so
  the test stays fast.

  ```dart
  import 'package:drift/drift.dart' show Variable;
  import 'package:flutter_test/flutter_test.dart';
  import 'package:memox/core/database/app_database.dart';
  import 'package:memox/core/error/outcome.dart';
  import 'package:memox/features/card/data/datasources/card_dao.dart';
  import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
  import 'package:memox/features/card/domain/failures/card_failure.dart';
  import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
  import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
  import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

  import '../../../support/deck_fixtures.dart';
  import '../../../support/test_database.dart';

  // BE-C2: a batch over more ids than SQLite binds in one statement works,
  // with the result of a small batch (local backend spec 2026-09-27 §5).

  const _many = 33000;

  DateTime _now() => DateTime(2026, 9, 27);

  /// [_many] live cards in [deckId], ids `c00000`…, created in id order.
  Future<Set<String>> _seed(AppDatabase db, String deckId) async {
    await db.customStatement(
      'WITH RECURSIVE n(i) AS (SELECT 0 UNION ALL SELECT i + 1 FROM n '
      'WHERE i + 1 < ?) '
      "INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, "
      'created_at, updated_at) '
      "SELECT printf('c%05d', i), ?, 'f', 'b', 'f', 'b', i, i FROM n",
      [_many, deckId],
    );
    return {for (var i = 0; i < _many; i++) 'c${'$i'.padLeft(5, '0')}'};
  }

  void main() {
    late AppDatabase db;
    late CardRepositoryImpl cards;
    late CardDao dao;
    late String from;
    late String to;
    late Set<String> ids;

    setUp(() async {
      db = openTestDatabase();
      final decks = DeckRepositoryImpl(db, now: _now);
      cards = CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        now: _now,
      );
      dao = CardDao(db);
      final root = await decks.root('r');
      from = (await decks.sub(root.id, 'from')).id;
      to = (await decks.sub(root.id, 'to')).id;
      ids = await _seed(db, from);
    });
    tearDown(() => db.close());

    Future<int> count(String sql, [List<Object> args = const []]) async =>
        (await db
                .customSelect(sql, variables: [for (final a in args) Variable(a)])
                .getSingle())
            .read<int>('n');

    test('flagging more cards than SQLite binds flags them all', () async {
      final result = await cards.setFlagged(cardIds: ids, isFlagged: true);

      expect(result, isA<Ok<void, CardRejection>>());
      expect(await count('SELECT COUNT(*) AS n FROM card WHERE is_flagged = 1'), _many);
    });

    test('moving more cards than SQLite binds moves them all', () async {
      final result = await cards.moveCards(cardIds: ids, targetDeckId: to);

      expect(result, isA<Ok<void, CardRejection>>());
      expect(await count('SELECT COUNT(*) AS n FROM card WHERE deck_id = ?', [to]), _many);
    });

    test('an export of more cards than SQLite binds keeps created_at order '
        'across the chunks', () async {
      final rows = await dao.exportRows(from, ids);

      expect(rows, hasLength(_many));
      expect([for (final row in rows) row.id], [...ids.toList()..sort()]);
    });

    test('the live rows and root ids of a large set are read whole', () async {
      expect(await dao.liveRows(ids), hasLength(_many));
      expect(await dao.rootIdsOf({from, to}), hasLength(1));
    });
  }
  ```

  Match the names the file really uses: the `CardDao` constructor (read it in
  `card_dao.dart`), the repository parameters (`cardIds:`,
  `targetDeckId:`, `isFlagged:`), the id field of the export row type, and
  the card columns in the seed (every `NOT NULL` column without a default
  gets a value).

- [ ] **Step 2: Run it.**

  Run: `flutter test test/features/card/data/card_batch_limit_test.dart`

  Expected: FAIL with `too many SQL variables` in the flag, move, export and
  live-rows tests.

- [ ] **Step 3: Implement** in `card_dao.dart`. Add
  `import 'package:memox/core/database/id_chunks.dart';` and rewrite each
  method as below.

  ```dart
  /// The active cards among [ids], read in chunks (BE-C2).
  Future<List<CardRow>> liveRows(Set<String> ids) async => [
    for (final chunk in idChunks(ids))
      ...await (_db.select(_db.card)..where(
            (card) => card.id.isIn(chunk) & card.deleteBatchId.isNull(),
          ))
          .get(),
  ];

  /// The active decks among [ids], read in chunks (BE-C2).
  Future<List<Deck>> deckRows(Set<String> ids) async => [
    for (final chunk in idChunks(ids))
      ...await (_db.select(_db.deck)..where(
            (deck) => deck.id.isIn(chunk) & deck.deleteBatchId.isNull(),
          ))
          .get(),
  ];
  ```

  `exportRows`: a null `ids` keeps the one statement. Otherwise, read per
  chunk, then sort the whole result with the same key:

  ```dart
  Future<List<CardRow>> exportRows(String deckId, Set<String>? ids) async {
    SimpleSelectStatement<$CardTable, CardRow> of(List<String>? chunk) =>
        _db.select(_db.card)
          ..where(
            (card) =>
                card.deckId.equals(deckId) &
                card.deleteBatchId.isNull() &
                (chunk == null ? const Constant(true) : card.id.isIn(chunk)),
          )
          ..orderBy([
            (card) => OrderingTerm.asc(card.createdAt),
            (card) => OrderingTerm.asc(card.id),
          ]);
    if (ids == null) return of(null).get();
    final rows = [
      for (final chunk in idChunks(ids)) ...await of(chunk).get(),
    ];
    // Each chunk is ordered on its own; the export's order is the whole
    // set's (BR-TRANSFER-010).
    rows.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return rows;
  }
  ```

  Take the table type name (`$CardTable`) and the row type from the
  generated code. If the select type does not infer, write the statement
  inline twice rather than guess.

  `rootIdsOf`:

  ```dart
  Future<Set<String>> rootIdsOf(Set<String> deckIds) async => {
    for (final chunk in idChunks(deckIds))
      for (final deck in await (_db.select(
        _db.deck,
      )..where((deck) => deck.id.isIn(chunk))).get())
        deck.rootId,
  };
  ```

  `moveCards` and `setFlagged` write per chunk:

  ```dart
  Future<void> moveCards(Set<String> ids, String deckId, DateTime now) async {
    for (final chunk in idChunks(ids)) {
      await (_db.update(_db.card)..where((card) => card.id.isIn(chunk))).write(
        CardCompanion(deckId: Value(deckId), updatedAt: Value(now)),
      );
    }
  }

  /// Writes only the cards whose flag differs from [isFlagged], in chunks.
  Future<void> setFlagged(Set<String> ids, bool isFlagged, DateTime now) async {
    final flag = isFlagged ? 1 : 0;
    for (final chunk in idChunks(ids)) {
      await (_db.update(_db.card)..where(
            (card) => card.id.isIn(chunk) & card.isFlagged.equals(flag).not(),
          ))
          .write(CardCompanion(isFlagged: Value(flag), updatedAt: Value(now)));
    }
  }
  ```

  Keep the existing doc comments. Add "in chunks (BE-C2)" to each one.

- [ ] **Step 4: Run.**

  Run:
  `flutter test test/features/card/data/card_batch_limit_test.dart test/features/card test/features/transfer`

  Expected: PASS. Note the limit test's run time in the ledger. If it takes
  more than 20 s, rule on a `slow` tag in the ledger (register it in
  `dart_test.yaml`) instead of shrinking `_many`.

- [ ] **Step 5: Commit.**

  `fix(card): batches past SQLite's bind limit run in chunks (BE-C2 G2)`

---

### Task 3: Tag and Trash batches past the limit

**Files:**
- Modify: `lib/features/tags/data/datasources/tag_dao.dart`,
  `lib/features/trash/data/datasources/trash_dao.dart`.
- Create: `test/features/tags/data/tag_batch_limit_test.dart`,
  `test/features/trash/data/trash_batch_limit_test.dart`.

**Interfaces — Consumes:** `idChunks` (Task 1).

- [ ] **Step 1: Write the failing tests.**

  `tag_batch_limit_test.dart`:
  - Seed a card sub-deck with 33 000 cards. Use raw inserts as
    `tag_repository_impl_test.dart` does, with the recursive CTE of Task 2.
  - Test "attaching a tag to more cards than SQLite binds links them all,
    and a detach unlinks them all":

    ```dart
    final ids = {for (var i = 0; i < 33000; i++) 'c${'$i'.padLeft(5, '0')}'};
    expect(await tags.attachByName(cardIds: ids, name: 'Noun'), isA<Ok<void, TagRejection>>());
    expect(await _count(db, 'card_tags'), 33000);
    final tagId = (await db.customSelect('SELECT id FROM tags').getSingle()).read<String>('id');
    expect(await tags.detach(cardIds: ids, tagId: tagId), isA<Ok<void, TagRejection>>());
    expect(await _count(db, 'card_tags'), 0);
    ```

    Use the repository's real detach method and parameter names. Read them
    in `tag_repository_impl.dart`.
  - Test "the per-tag counts of a large selection sum across the chunks".
    Build a `TagDao(db)`, attach 'Noun' to all 33 000 cards and 'Verb' to the
    first 10, then:

    ```dart
    final counts = await dao.tagCounts(ids);
    expect(counts.values.toSet(), {33000, 10});
    expect(await dao.liveCardCount(ids), 33000);
    ```

  `trash_batch_limit_test.dart`:
  - Seed 33 000 `delete_batches` rows (recursive CTE; ids `b00000`…,
    `deleted_at` = i, of item type `card`). Read the table's columns in
    `trash.drift`. The rows need no cards.
  - Seed one more batch `old` deleted at time 0 − 1 day.
  - Test "purge candidates of a large choice are each batch once, oldest
    first":

    ```dart
    final chosen = {for (var i = 0; i < 33000; i++) 'b${'$i'.padLeft(5, '0')}'};
    final rows = await TrashDao(db).purgeCandidates(chosen: chosen, cutoff: <the old batch's time>);
    expect(rows, hasLength(33001));
    expect(rows.first.id, 'old');
    expect(rows.map((r) => r.id).toSet(), hasLength(33001));
    ```

- [ ] **Step 2: Run.**

  Run:
  `flutter test test/features/tags/data/tag_batch_limit_test.dart test/features/trash/data/trash_batch_limit_test.dart`

  Expected: FAIL with `too many SQL variables`.

- [ ] **Step 3: Implement.** Add
  `import 'package:memox/core/database/id_chunks.dart';` to both files.

  `tag_dao.dart`:
  - `liveCardCount`: sum the chunk counts.
  - `cardsCarrying`: union the chunk sets.
  - `unlink`: delete per chunk.
  - `tagCounts`: add each chunk's per-tag count into one map:

    ```dart
    Future<Map<String, int>> tagCounts(Set<String> cardIds) async {
      final total = <String, int>{};
      for (final chunk in idChunks(cardIds)) {
        // … the existing statement with `isIn(chunk)` …
        for (final MapEntry(key: tagId, value: n) in chunkCounts.entries) {
          total[tagId] = (total[tagId] ?? 0) + n;
        }
      }
      return total;
    }
    ```

    Here `chunkCounts` is the map the existing body builds, taken from one
    chunk.

  `trash_dao.dart`, `purgeCandidates`:
  - With an empty `chosen`, keep the one statement on `cutoff`.
  - Otherwise read the `cutoff` statement once and each chunk's
    `batch.id.isIn(chunk)` statement, keep the rows by id in a map (one row
    per batch), and sort the values by `deletedAt`, then `id`.
  - Doc comment: "in chunks, each batch once (BE-C2)".

- [ ] **Step 4: Run.**

  Run:
  `flutter test test/features/tags test/features/trash test/features/card`

  Expected: PASS.

- [ ] **Step 5: Commit.**

  `fix(tags,trash): batches past SQLite's bind limit run in chunks (BE-C2 G2)`

---

### Task 4: Records and the gate

**Files:** `docs/wbs_BE.md`.

- [ ] **Step 1: Edit the WBS.**
  - Move BE-C2 to "Đã xong" with status `xong`, this plan and its tests as
    evidence, and next step "—".
  - BE-C1: status "đóng". Evidence: "chủ dự án giữ thứ tự theo code unit
    (2026-09-27, [spec](../specs/2026-09-27-local-backend-completion-design.md)
    D3)". Next step "—". Drop its row from "Điểm chặn".
  - Add an update-log line for 2026-09-27 (G2).
- [ ] **Step 2: Run the docs check.**

  Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`

  Expected: 0 errors.
- [ ] **Step 3: Run the gate.**

  Run: `GUARD_PY=python3.13 bash .claude/skills/flutter-workflow/scripts/dod_check.sh`,
  then `TZ=UTC flutter test --tags golden`.

  Expected: green. The guard's 400-line limit holds for every touched file.
- [ ] **Step 4: Commit.**

  `docs(be): BE-C2 done, BE-C1 closed by the owner (G2)`
