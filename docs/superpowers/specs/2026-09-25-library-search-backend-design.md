# MemoX V8 — Library search backend design (package 5)

Status: approved 2026-09-25 · amended while writing the plan (its Clarifications: D5, D11, §4, §5.1, §5.3, §6.1, §9, §12) · Path: architectural

## 1. Intent

Build BE-A8 of [`docs/wbs_BE.md`](../../wbs_BE.md): the read model of the library-wide
search, UC-SEARCH-001, with BR-SEARCH-001…BR-SEARCH-009 and the rules it leans on
(BR-DECK-001…BR-DECK-003 for paths, BR-DECK-009 for opening a deck of cards, BR-TAG-001
for a tag's identity).

The package writes `domain/`, `data/` and `di/` of a new `lib/features/search/`. The
screen (04 Library search of the kit, `/decks/search`) belongs to FE-A10 in
[`docs/wbs_FE.md`](../../wbs_FE.md).

Success means:

- FE-A10 builds every state of screen 04 from one use case: decks by name, cards by
  either face or by a tag's name, decks first, three match tiers, one result per card,
  "Load more";
- a blank query runs no statement, and a test counts the statements (BR-SEARCH-003);
- the results follow every write they depend on without a manual refresh, and reading
  writes nothing (BR-SEARCH-008);
- every rule above that the backend owns has a test that fails when it breaks;
- the phased gate of the root `README.md` passes after every task;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-25)

- `master` is at `fb5f979`: package 4 (#60) merged.
- **UC-SEARCH-001** is `ready` with `code: []`, and no test names it.
- **The rules.**
  - Exactly four fields are searched: a deck's name, a card's front and back, and a
    tag's name. Never `example`, `hint`, `pronunciation`, scheduler data, study state or
    review history. Deleted decks and cards never appear, and content in the Trash is
    excluded by one predicate in one place (BR-SEARCH-001).
  - The query and the data pass through one fold: trim, then Dart's Unicode lowercase.
    SQL never uses `lower()` or `COLLATE NOCASE`, which fold ASCII only, and the fold
    never strips accents (BR-SEARCH-002).
  - A query that folds to empty returns the initial state and sends no statement to
    the database. The 250 ms debounce, the identity of each read and the cancellation
    on leaving are the UI's (BR-SEARCH-003, "Enforced by: UI").
  - Each group is ordered exact match, then prefix, then contains; a card's tier is the
    best of the fields it matches. No score: the order is explainable and stable
    between two reads (BR-SEARCH-004).
  - Two groups, decks first. A page fills with decks first; no card appears while
    decks remain; the groups never interleave (BR-SEARCH-005).
  - A card matching several fields or tags yields one result, merged by a correlated
    aggregate in the query, never by `DISTINCT` over a multiplying join
    (BR-SEARCH-006).
  - Pagination is keyset over exactly four parts in the sort order: tier, the folded
    text sorted on, `created_at`, `id`. No `OFFSET`. A write between two pages never
    repeats or skips a row (BR-SEARCH-007).
  - Results are read-only and open no session. Renaming an ancestor deck, moving a
    card or deck, renaming a tag and deleting update the results and their paths
    without a manual action. A deck result opens its deck; a card result opens the
    card's detail in reading mode, never its editor (BR-SEARCH-008).
  - No FTS table or new index without `EXPLAIN QUERY PLAN` and numbers at a real
    scale. No N+1: the paths of a page come from one read of the deck tree, and the
    tags of a page's cards come from the statement that reads the cards
    (BR-SEARCH-009).
- **What exists.**
  - `foldText` (`lib/core/text/folded_text.dart`): trim, then `toLowerCase()`.
    `card.front_folded`, `card.back_folded` and `tags.name_folded` are written with it.
    `deck` has no folded column: the WBS left "fold in Dart as stage 2 did, or add a
    column" to this package.
  - The deck feature's `SearchDecksUseCase` (`deckSearchScope`, names folded in Dart)
    serves screen 04 today over the whole library (ruling P2-L9): "decks only until
    BE-A8".
  - `candidatesInTreeOrder`, `DeckTreeNode`, `DeckPathEntry` and `DeckContentType` in
    `deck/domain/models/`.
  - `tableChanges` in `lib/core/database/` (package 4): a listen-first change stream
    over a list of tables.
  - The card detail route exists (`AppRoutes.card`, `/decks/card/:cardId`), so the
    clause of BR-SEARCH-008 for a route that does not exist yet does not apply.
  - Indexes: `card_tags` has its primary key `(card_id, tag_id)` and
    `idx_card_tags_tag (tag_id, card_id)`; `card` has `idx_card_deck_created`. No
    folded column is indexed.
- **The kit** (screen 04; states emptyQuery, loading, results, noResults, error).
  - A deck row: a tile by content type, the name with the match emphasised, then
    "{path} · holds cards" or "· holds sub-decks", the path being the deck's ancestors.
  - A card row: "front · back", both emphasised; below, a tag chip when the card
    matched through a tag, then the path of the card's deck.
  - Each group header counts the rows loaded, with "+" when more follow ("20+").
  - "Load more results" at the end, then the footer "Decks first, then cards ·
    case-insensitive, accents matter".

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | UC-SEARCH-001 only. `SearchDecksUseCase` stays until FE-A10 moves screen 04 to the new use case and removes it: removing it touches `presentation/` | Owner, 2026-09-25 |
| D2 | Approach | Deck names are folded in Dart from the snapshot's one read of the deck tree; cards are matched by one SQL statement; the extent a watch shows is bounded by a keyset cursor | Owner, 2026-09-25 (approach A of three) |
| D3 | Deck names | No `deck.name_folded` and no migration. The snapshot reads every active deck anyway, for the paths (BR-SEARCH-009); matching folds each name there with `foldText`. The WBS's blocked row on the folded deck name closes on this | Owner, 2026-09-25 |
| D4 | Tiers | Exact, prefix, contains. SQL tests `folded = :term`, `instr(folded, :term) = 1` and `instr(folded, :term) > 0`: never `LIKE`, so `%` and `_` are plain characters, and never `lower()` or `NOCASE`. A card's tier is the best of its front, its back and its tags | BR-SEARCH-002, BR-SEARCH-004 |
| D5 | Sort text | A deck sorts on its folded name, a card on `front_folded`, its face that names it. Each group's order is computed on one side only, decks in Dart and cards in SQL, so a cursor is never compared across the two collations. Dart compares the texts by code point, the order SQLite's BINARY collation gives UTF-8, where `String.compareTo` would compare UTF-16 code units, so both groups order texts alike (plan Clarification 2) | BR-SEARCH-007; Owner, 2026-09-25 |
| D6 | Pages | Keyset, 50 rows a page. A watch shows every row whose key is at or before `through`, the first page when `through` is null. Each emission looks at the next page and carries its last key as `nextThrough`, null when nothing follows. "Load more" watches again with `through = nextThrough` | BR-SEARCH-005, BR-SEARCH-007; Owner, 2026-09-25 |
| D7 | One result per card | Correlated subqueries over the card's own `card_tags ⋈ tags` give its best tag tier and the name of its best matching tag. A hit names that tag only when neither face matches | BR-SEARCH-006, BR-SEARCH-009; UC-SEARCH-001 step 5 |
| D8 | What counts | A deck out of the Trash; a card out of the Trash in a deck out of the Trash. The search DAO holds the predicate once and both reads use it | BR-SEARCH-001 |
| D9 | When it reads | Once when watched, then after every write to `deck`, `card`, `card_tags` or `tags` (`tableChanges`); each emission in one transaction | BR-SEARCH-008 |
| D10 | A blank query | The use case folds the term; a blank one is `LibrarySearchIdle`, with no statement | BR-SEARCH-003 |
| D11 | Schema | No change. Measured by the plan on a synthetic library of 300 decks and 200 tags, two tags on each card, in a 4-core desktop container: the card statement reads in 23–41 ms at 10,000 cards and 124–207 ms at 50,000, the deck tree in 1–2 ms, and one emission in 25–98 ms and 131–506 ms. `EXPLAIN QUERY PLAN`: one pass over the cards through `idx_card_deck_created`, each card's tags by the primary keys of `card_tags` and `tags`, and a temporary B-tree for the order. The tags' subquery is about two-thirds of the statement at 50,000 cards, where the faces alone read in 42 ms (plan Clarification 1). An index or FTS would be its own package, with a migration | BR-SEARCH-009 |
| D12 | Import map | `'search': {'deck'}`: only `deck/domain/models/` (`DeckTreeNode`, `DeckPathEntry`, `DeckContentType`, `candidatesInTreeOrder`) | ADR-011 D2 |
| D13 | Documents | Of the BR and UC files, only the `code:` of UC-SEARCH-001 changes. With it: the search README (`code:`, and its stale note that the repository has no `lib/`), a new `features/search/data.md`, `wbs_BE.md`, the lines of `wbs_FE.md`, `04-library-search.md` and `01-deck-list.md` that wait for BE-A8, and `docs/_generated/` | Owner, 2026-09-25 |
| D14 | Branch and PR | Branch `claude/be-search` from `master`. When the gate is green and the final review is clean, the package is opened as a PR and squash-merged | Owner's standing choice |

## 4. Structure

```
lib/features/search/
├── domain/
│   ├── models/search_cursor_model.dart        SearchTier, searchTierOf, SearchGroup,
│   │                                          SearchCursor
│   ├── models/search_hit_model.dart           SearchableDeck, SearchDeckHit,
│   │                                          SearchCardHit, deckHitsOf
│   ├── models/library_search_model.dart       LibrarySearch, LibrarySearchIdle,
│   │                                          LibrarySearchResults, searchPageSize
│   ├── repositories/search_repository.dart    watchSearch
│   └── usecases/search_library_use_case.dart  SearchLibraryUseCase
├── data/
│   ├── datasources/search_dao.dart            deckForest, cardHits, changes
│   ├── mappers/search_mapper.dart             rows → hits, paths
│   └── repositories/search_repository_impl.dart
└── di/search_repository_provider.dart         searchRepositoryProvider
```

`allowedFeatureImports` gains `'search': {'deck'}` (D12). The use case's provider
belongs to FE-A10's `presentation/providers/`, as for every use case so far. The
models are split in three files, as above (plan Clarification 3).

## 5. The read model

### 5.1 Types

```dart
enum SearchTier { exact, prefix, contains }   // in this order (BR-SEARCH-004)
enum SearchGroup { deck, card }                // decks first (BR-SEARCH-005)

/// A row's place in the total order; opaque to the UI, which only hands it back.
final class SearchCursor {
  final SearchGroup group;
  final SearchTier tier;
  final String sortText;     // the folded name of a deck, a card's front_folded
  final DateTime createdAt;
  final String id;
}

final class SearchDeckHit {
  final String deckId;
  final String name;
  final List<DeckPathEntry> path;   // the ancestors, root first, not the deck
  final DeckContentType contentType;
  final SearchCursor cursor;        // its place in the order (§5.3)
  SearchTier get tier => cursor.tier;
}

final class SearchCardHit {
  final String cardId;
  final String deckId;
  final String front;
  final String back;
  final List<DeckPathEntry> deckPath;  // root first, the card's deck last
  final String? matchedTag;            // only when neither face matches (D7)
  final SearchCursor cursor;
  SearchTier get tier => cursor.tier;
}

sealed class LibrarySearch {}
final class LibrarySearchIdle extends LibrarySearch {}   // blank query, nothing read
final class LibrarySearchResults extends LibrarySearch {
  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;
  final SearchCursor? nextThrough;     // null: nothing follows, no "Load more"
  bool get hasResults;
}

const searchPageSize = 50;
```

Each hit carries its cursor as a field, and `tier` reads it (plan Clarification 3).
`searchTierOf(folded, term)` gives a field's tier, and `deckHitsOf(decks, term)`
matches and orders the decks in Dart.

### 5.2 Matching

A field matches when its folded text holds the folded term. Its tier is `exact` when
the two are equal, `prefix` when the text starts with the term, `contains` otherwise
(BR-SEARCH-004). A deck is matched on its name, in Dart. A card is matched on
`front_folded`, `back_folded` and the `name_folded` of each of its tags, in SQL, and
its tier is the best of the three (D4, D7).

### 5.3 The order

Decks, then cards (BR-SEARCH-005). Within a group, by the key `(tier, sort text,
created_at, id)`: tier in the order of `SearchTier`, then the sort text ascending by
code point (D5), then `created_at`, then `id`. The key is unique, so the order is
total, and two reads of the same data give the same order (BR-SEARCH-004,
BR-SEARCH-007).

### 5.4 Pages

- A watch shows every row whose cursor is at or before `through`; with `through` null,
  the first `searchPageSize` rows (D6).
- Each emission also reads up to `searchPageSize` rows after the last one it shows.
  `nextThrough` is the cursor of the last of those, null when there are none.
- If no row at or before `through` is left while rows follow it, the emission shows
  the first page instead: a list is never empty while "Load more" is offered.
- Because every bound is a cursor and never a count, a write between two pages
  cannot repeat or skip a row (BR-SEARCH-007). A row that a write moves past
  `through` leaves the list and comes back with the next page.

## 6. The reads

### 6.1 The deck tree

`deckForest()` is one statement: every active deck with `id`, `name`, `parent_id`,
`sibling_position`, `content_type` and `created_at`. From it, in Dart:

- every deck's path, root first, through `candidatesInTreeOrder` with every deck a
  candidate. Every hit of the snapshot takes its path from this one read
  (BR-SEARCH-009);
- the deck hits: each name folded with `foldText`, matched and tiered (§5.2), in the
  order of §5.3.

A deck that the walk from the roots does not reach, one under a deck in the Trash, has
no path, so neither it nor its cards are hits. BE-B1 puts whole subtrees in the Trash;
this only guards against a partial one (plan Clarification 4).

### 6.2 The card statement

`cardHits` is one statement, sketched here; the plan pins it:

```sql
WITH hits AS (
  SELECT c.id, c.deck_id, c.front, c.back, c.front_folded, c.created_at,
    <tier of c.front_folded> AS front_tier,
    <tier of c.back_folded>  AS back_tier,
    COALESCE((SELECT MIN(<tier of t.name_folded>)
              FROM card_tags ct JOIN tags t ON t.id = ct.tag_id
              WHERE ct.card_id = c.id), <none>) AS tag_tier,
    (SELECT t.name FROM card_tags ct JOIN tags t ON t.id = ct.tag_id
     WHERE ct.card_id = c.id AND instr(t.name_folded, :term) > 0
     ORDER BY <tier of t.name_folded>, t.name_folded, t.id
     LIMIT 1) AS tag_name
  FROM card c JOIN deck k ON k.id = c.deck_id
  WHERE <live: D8>
)
SELECT ... , MIN(front_tier, back_tier, tag_tier) AS tier
FROM hits
WHERE <a tier>
  AND (tier, front_folded, created_at, id) >  (:after)    -- when it pages on
  AND (tier, front_folded, created_at, id) <= (:through)  -- when it is bounded
ORDER BY tier, front_folded, created_at, id
LIMIT :limit
```

`<tier of x>` is `CASE WHEN x = :term THEN 0 WHEN instr(x, :term) = 1 THEN 1 WHEN
instr(x, :term) > 0 THEN 2 ELSE <none> END`. The tags come from this statement, one
row per card, with no `DISTINCT` (BR-SEARCH-006, BR-SEARCH-009).

### 6.3 One emission

In one transaction:

1. `deckForest()`: the paths and the deck hits.
2. The extent: the deck hits and the card hits at or before `through`, or the first
   page (§5.4). A page fills with decks first; cards start only after the last deck
   (BR-SEARCH-005).
3. The next page after the extent's last row: the remaining deck hits, then a card
   statement after that cursor. Its last cursor is `nextThrough`.

That is one read of the deck tree and at most two card statements, three only in the
empty-extent case of §5.4.

### 6.4 When it reads

`tableChanges(db, [deck, card, cardTags, tags])` fires once when listened to, then
after every write to one of those tables: a renamed ancestor, a moved card or deck, a
deletion, a renamed tag or a tag put on or taken off a card (BR-SEARCH-008). Each
firing becomes one emission through `asyncMap`, one at a time and in order.

### 6.5 Mapping

`search_mapper.dart` turns a forest row into a `DeckTreeNode` (content type through
`DeckContentType.values.byName`), a deck hit and its path into a `SearchDeckHit`, and
a card row with the path of its deck into a `SearchCardHit`, whose `matchedTag` is set
only when both face tiers are none.

### 6.6 Errors

The stream ends in `.mapDatabaseErrors()`: a failed read reaches the UI as a database
`Failure` (UC-SEARCH-001 E1). Keeping the rows already shown when a later page fails
(E2) is the UI's: its last emission stays on screen.

## 7. The use case

`SearchLibraryUseCase(SearchRepository)`:

```dart
Stream<LibrarySearch> call({required String term, SearchCursor? through}) {
  final folded = foldText(term);
  if (folded.isEmpty) return Stream.value(const LibrarySearchIdle());
  return _search.watchSearch(foldedTerm: folded, through: through);
}
```

The repository's `watchSearch` takes the folded term; nothing below the use case
folds it again.

## 8. The contract for the UI (FE-A10)

| Use case | Input | Output | Errors |
|---|---|---|---|
| `SearchLibraryUseCase` | `term`, `through` | `Stream<LibrarySearch>`: `LibrarySearchIdle` for a blank term; else `LibrarySearchResults`, again after every write it can see | a database `Failure` on the stream (E1) |

For FE-A10:

- The controller debounces the typed term by 250 ms, drops what arrives for a query
  that changed, clears at once on an empty field and cancels on leaving
  (BR-SEARCH-003).
- `LibrarySearchIdle` is the emptyQuery state; results with no deck and no card are
  noResults; otherwise mixed, decks-only or cards-only. A group with no row draws no
  header (A2).
- A group header counts the rows loaded, with "+" when `nextThrough` is not null.
  "Load more results" shows when `nextThrough` is not null and watches again with
  `through = nextThrough` (A1). A failure after "Load more" keeps the shown rows and
  turns the end of the list into a retry (E2).
- A deck row opens `AppRoutes.deck(deckId)`, `/decks/deck/:deckId` (a deck of cards
  opens its cards, BR-DECK-009); a card row opens `AppRoutes.card(cardId)`,
  `/decks/card/:cardId`, in reading mode (BR-SEARCH-008).
- The match emphasis is the UI's, from the folded term.

## 9. Tests

Every test names the rule or the use case it pins.

Domain (pure):

- the tiers of a deck name: exact, prefix, contains, none (BR-SEARCH-004);
- the order of deck hits: tier, then the folded name, `created_at` and `id`, and the
  same order from two reads (BR-SEARCH-004, BR-SEARCH-007);
- the cursor's order: decks before cards, then the four parts;
- a blank or all-space term is `LibrarySearchIdle` (BR-SEARCH-003).

Data (a test database):

- the four fields and no other: a deck's name, a card's front and back, a tag's name;
  never `example`, `hint` or `pronunciation` (BR-SEARCH-001);
- a deck or a card in the Trash, or a card in a deck in the Trash, never appears
  (BR-SEARCH-001, D8);
- `công nghệ` finds `CÔNG NGHỆ`; `cong` does not find `công`; spaces around the term
  do not matter (BR-SEARCH-002);
- a blank term sends no statement to the database, counted by a query interceptor
  that counts SELECTs: the path only reads, and every emission starts with one
  (BR-SEARCH-003; plan Clarification 5);
- exact, then prefix, then contains, in both groups; a card's tier is the best of its
  fields (BR-SEARCH-004);
- decks first; the first page fills with decks first and turns to cards only after the
  last deck (BR-SEARCH-005);
- a card matching its front, its back and two tags is one result; it names a tag only
  when it matched through a tag alone (BR-SEARCH-006);
- a card written before and after the page boundary between two pages repeats no row
  and skips none; two rows equal in tier, text and `created_at` fall to `id`
  (BR-SEARCH-007);
- the stream emits again on a renamed ancestor (its path changes), a moved card, a
  moved deck, a deleted card or deck and a renamed tag; reading writes nothing and
  opens no session (BR-SEARCH-008);
- one emission reads the deck tree once and runs at most two card statements, however
  many hits, three only in the empty-extent case of §5.4 (BR-SEARCH-009);
- a list whose rows at or before `through` are all gone while rows follow shows the
  first page, never an empty list with "Load more" (§5.4);
- a failed read emits a database `Failure` (UC-SEARCH-001 E1);
- the plan's Review Focus.

## 10. Documents

- **UC-SEARCH-001:** `code:` names `search_library_use_case.dart`. No other line of a
  BR or UC file changes (D13).
- **`docs/features/search/README.md`:** `code:` names the feature's `domain`, `data`
  and `di`; the stale note that the repository has no `lib/` goes.
- **`docs/features/search/data.md`** (new): what is matched and how it folds, the deck
  tree read, the card statement, the pages, when it reads, and that nothing writes.
- **`docs/wbs_BE.md`:** BE-A8 done; the blocked row on the folded deck name closes on
  D3; the order moves on; the update log; the traceability line.
- **`docs/wbs_FE.md`:** FE-A10's next step no longer waits for BE-A8.
- **`docs/shared/ui/screen-handoff/04-library-search.md`** and
  **`01-deck-list.md`:** the lines that wait for BE-A8 wait for FE-A10.
- **`docs/_generated/`:** regenerated.

## 11. Out of scope

- FE-A10: screen 04 on the new use case, the debounce and the identity of a read, the
  "Load more" row, the retry at the end of the list, and the removal of
  `SearchDecksUseCase` (D1).
- A search without accents (S1), and any field outside the four of BR-SEARCH-001.
- An FTS table or an index (BR-SEARCH-009, D11).
- The Trash (BE-B1): the filters are in place; restore and purge come with it.

## 12. Risks and rollback

- **Load.** Each write to `deck`, `card`, `card_tags` or `tags` re-reads the snapshot
  while the search screen listens, and the card statement scans every active card with
  `instr`. Measured (D11): one emission takes 25–98 ms at 10,000 cards and 131–506 ms
  at 50,000 in a desktop container, more on a phone. An index or FTS would be its own
  package, with a migration.
- **Two collations.** Dart orders the decks and SQLite the cards; D5 keeps each
  group's order and its cursor on one side.
- **The old deck search** keeps serving screen 04 until FE-A10 moves it (D1).
- **Rollback.** No schema change and no write: reverting the package's commits
  removes it.
