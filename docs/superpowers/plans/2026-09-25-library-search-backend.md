# MemoX V8 Library Search Backend Implementation Plan (package 5)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-A8 of [`docs/wbs_BE.md`](../../wbs_BE.md), the read model of
the library-wide search (UC-SEARCH-001), as domain, data and di code with one use
case, so the UI session can build screen 04 of the kit on it. No UI.

**Architecture:** In `search/domain`, `SearchCursor` gives every hit its place in
one total order (decks before cards, then the tier, the folded text by code
point, `created_at` and `id`), and `deckHitsOf` matches and orders the decks in
Dart. In `search/data`, `SearchDao` reads the live deck tree in one statement and
the cards in another: each field ranked with `=` and `instr`, a card's tags
through correlated subqueries, one row per card, keyset bounds and a limit.
`SearchRepositoryImpl` reads each emission in one transaction: the hits through
`through` (the first page when it is null), then a peek at the next page for
`nextThrough`, again after every write to `deck`, `card`, `card_tags` or `tags`.
`SearchLibraryUseCase` folds the term; a blank one reads nothing.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35. No dependency is added.

**Spec:** [`docs/superpowers/specs/2026-09-25-library-search-backend-design.md`](../specs/2026-09-25-library-search-backend-design.md),
approved 2026-09-25 and amended on this branch with the Clarifications below.
Business rules: `docs/features/search/rules/` (BR-SEARCH-001…BR-SEARCH-009);
use case: `docs/features/search/usecases/`; data model:
[`docs/shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-search` holds the spec (`c8c2db3`), its approval
(`7cd1943`) and its amendment from the Clarifications below (`e3b9fff`), on
`master` at `fb5f979` (#60). This plan runs on that branch, from the commit that
adds it; the gate passes there with 1401 tests. Generated code is not
committed: in a fresh working tree, run `flutter pub get`, `flutter gen-l10n`
and `dart run build_runner build --delete-conflicting-outputs` first (root
`README.md`, "Commands").

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed, and after every task the gate
passed. Each rule the data tests pin was also broken on purpose in the scratch
copy (the prefix tier made to swallow contains, a card's back never matched,
tags never matched, a tag always named, the Trash filter dropped from the deck
tree, from a card and from a card's deck, the keyset's lower bound made
inclusive, the first-page fallback of §5.4 dropped, the decks on a page ignored,
a deck's cursor handed to the card statement, UTF-16 order, the `id` tie-break
dropped, `deck` or `tags` no longer listened to): every break failed a test.
This document was then applied, step by step as written, onto a clean checkout
of `7cd1943`, whose tree differs from this plan's commit only in the spec's
amendment and in this document: each task's files matched the scratch commit's,
no other file moved, and the suite counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme. Screen 04, its controller (the 250 ms
  debounce, the identity of a read, "Load more", the retry), the routes and the
  use case's provider are FE-A10 (spec §1, §8, §11). `SearchDecksUseCase` stays
  until FE-A10 removes it (spec D1).
- The import map gains `'search': {'deck'}`: the feature imports only
  `deck/domain/models/` (spec D12; ADR-011 D2).
- Read only: nothing on these paths writes, and no session is opened
  (BR-SEARCH-008). No schema change, no index and no FTS table (spec D11,
  BR-SEARCH-009).
- Exactly four fields are searched: a deck's name, a card's front and back, a
  tag's name (BR-SEARCH-001). The Trash predicate `delete_batch_id IS NULL` is
  written once, in `SearchDao`, and applies to the deck tree, to a card and to
  its deck (spec D8).
- One fold, `foldText`. SQL never uses `lower()`, `COLLATE NOCASE` or `LIKE`: a
  tier is `=` or `instr` (BR-SEARCH-002; spec D4).
- Decks first; keyset pages of 50 on `(tier, sort text, created_at, id)`, never
  `OFFSET`; one row per card, never `DISTINCT` (BR-SEARCH-005…BR-SEARCH-007;
  spec D6, D7).
- One emission is one transaction: one read of the deck tree and at most two
  card statements, three only in the empty-extent case of §5.4
  (BR-SEARCH-009; spec §6.3).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing
  `call` (AD-12).
- The data tests run `expectStudyInvariants` after every scenario, which runs
  every invariant query of `schema.md` in scope.
- After every task the phased gate of the root `README.md` passes, plus
  `tools/docs/check.py`. On Linux, `flutter test` runs with
  `--exclude-tags golden`: the goldens were made on Windows (FE-D1 in
  [`docs/wbs_FE.md`](../../wbs_FE.md)).
- The guard warns at 400 logical lines of a file and fails at 500: the largest
  file of the package, `search_dao.dart`, ends at 119 (the guard's own count
  decides).
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a rule or use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- Of the contract files, only the `code:` field of UC-SEARCH-001 changes (spec
  D13).
- Code, identifiers, test names and commit messages are in English; `docs/`
  keeps its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan and showed
where it needed a change. Each is decided here, implemented as described, and
written into the spec on this branch (`e3b9fff`); say so if one is wrong.

1. **D11's measurement** (Tasks 2 and 3; spec D11, §12). A synthetic library of
   10 roots and 290 sub-decks, 200 tags, two tags on each card and one front in
   ten holding the term was read in this container (4 cores, Xeon 2.8 GHz; a
   phone is slower), in memory and from a file, each time the median of seven
   reads:

   | Cards | Deck tree | Card statement, one page | One emission | Through page 11 (550 rows) |
   |---|---|---|---|---|
   | 10,000 | 1–2 ms | 23–41 ms | 25–98 ms | 66–67 ms |
   | 50,000 | 1 ms | 124–207 ms | 131–506 ms | 312–320 ms |

   The low ends are a term no card holds (one card statement, no peek); the high
   ends a term that 77% of the cards hold through a tag. `EXPLAIN QUERY PLAN` of
   the card statement: `SCAN k`, then `SEARCH c USING INDEX
   idx_card_deck_created (deck_id=?)`, the tags' correlated subqueries through
   `sqlite_autoindex_card_tags_1 (card_id=?)` and `sqlite_autoindex_tags_1
   (id=?)`, and `USE TEMP B-TREE FOR ORDER BY`; the deck tree is `SCAN d`.
   SQLite flattens the `hits` CTE, so a matching card evaluates its tags'
   subquery again for the order and the output. At 50,000 cards the faces
   alone read in 42 ms: the tags' subquery is about two-thirds of the
   statement. Variants that change no schema returned the same rows:
   materialising `hits` was slower (220–245 ms); evaluating each card once, in a
   subquery SQLite cannot flatten, took the many-hit term to 140 ms; matching
   the tags first took a term no tag holds to 51 ms. Each changes the statement
   the spec approved (§6.2, D7) for a gain only at a library this large, so the
   statement stays as the spec sketches it, and the numbers are recorded for the
   package that would add an index or FTS (BR-SEARCH-009).
2. **One order for texts, by code point** (Tasks 1 and 3; spec D5, §5.3).
   Dart's `String.compareTo` compares UTF-16 code units; SQLite's BINARY
   collation compares UTF-8 bytes, which is code-point order. The two disagree
   when a character above U+FFFF meets one in U+E000–U+FFFF: Dart puts 𝒜
   (U+1D49C) before ｱ (U+FF71), SQLite after. `SearchCursor.compareTo` compares
   texts by code point, so the decks (ordered in Dart) and the cards (ordered
   in SQLite) follow one rule. D5 still holds: no cursor is compared across the
   two sides.
3. **The models' files, and the hits' cursor** (Task 1; spec §4, §5.1).
   `search_cursor_model.dart` holds the tier, `searchTierOf`, the group and the
   cursor; `search_hit_model.dart` holds `SearchableDeck` (a deck as the tree
   gives it), the two hits and `deckHitsOf`; `library_search_model.dart` holds
   `searchPageSize` and the sealed state. A hit carries its cursor as a field
   and reads its tier from it, so the repository compares hits without
   rebuilding their cursors.
4. **What the walk from the roots does not reach** (Tasks 2 and 3; spec §6.1,
   D8). The paths come from walking the live deck tree from its roots with
   `candidatesInTreeOrder`. A live deck under a deck in the Trash is not
   reached: it has no path, so neither it nor its cards are hits. BE-B1 puts
   whole subtrees in the Trash, so this only guards against a partial one. The
   card statement filters a card and its own deck in SQL, before the limit, so
   the cards of a deck in the Trash never take a place on a page (Review
   Focus 2).
5. **What the statement counts count** (Tasks 3 and 4; spec §9).
   `SelectCounter` (`test/support/test_database.dart`) counts SELECTs. The
   search only reads, and every emission starts with the deck tree's SELECT, so
   a blank term that sends no SELECT has sent no statement. One emission of the
   first page, or through a card's cursor, is three SELECTs: the deck tree and
   two card statements.
6. **A renamed tag in the tests** (Task 3; spec §9, D9). V8.0 has no write that
   renames a tag (Tag Management is BE-B2), so the test renames one with
   `customUpdate(..., updates: {db.tags}, updateKind: UpdateKind.update)`, the
   update a rename will report. Without the kind, drift would also notify
   `card_tags`, whose `ON DELETE CASCADE` rule on `tags` matches a write of any
   kind, and the test would pass without the search listening to `tags`.
7. **Where the deck side's tests sit** (Task 2; spec §9). "Reading writes
   nothing and opens no session" and "the results come again on a renamed
   ancestor, a moved deck and a deleted deck" are in Task 2's test file: the
   stream and its transaction exist from Task 2. Task 3's tests add the card
   writes: a moved or deleted card, a tag put on a card, a renamed tag.
8. **The documents** (Task 4; spec §10, D13). With BE-A8 done, the "V8.0 — còn
   lại" table of `wbs_BE.md` has no row left: BE-A8 moves to "Đã xong", the
   table gives way to one line, and the next step becomes BE-D2, then BE-B1.
   The blocked row on the folded deck name closes on D3. In
   `04-library-search.md`, "a search hint must not promise a match the backend
   cannot make" now says "the screen": the backend makes those matches, and the
   screen will from FE-A10. The counts: tests name 16 of the 22 use cases; the
   IT ids stay 63, since no IT scenario traces to UC-SEARCH-001.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **More than a page of decks for one term**: the first page holds decks alone,
   and "Load more" goes on from the last deck to the first card, skipping none —
   Task 3, "more than a page of decks".
2. **Cards of a deck in the Trash sorting before the live ones**: they take no
   place on a page, which still fills with live cards — Task 3, "cards of a deck
   in the Trash take no place on a page".
3. **A term holding `%` or `_`**: found as written, never as a wildcard — Task
   3, "% and _ in a term are plain characters".
4. **Texts that UTF-16 and UTF-8 order differently** (a character above U+FFFF
   against one in U+E000–U+FFFF): both groups order them alike — Task 1, "texts
   compare by code point", and Task 3, "decks and cards order their texts by one
   rule".
5. **A tag renamed while the search is open**: the hits that name it follow,
   though no `card_tags` row changes — Task 3, "the results come again on a
   moved card, a deleted card, a tag put on a card and a renamed tag".

## File Structure

```
lib/features/search/
├── domain/
│   ├── models/search_cursor_model.dart          SearchTier, searchTierOf, SearchGroup,
│   │                                            SearchCursor (1)
│   ├── models/search_hit_model.dart             SearchableDeck, SearchDeckHit,
│   │                                            SearchCardHit, deckHitsOf (1)
│   ├── models/library_search_model.dart         searchPageSize, LibrarySearch,
│   │                                            LibrarySearchIdle, LibrarySearchResults (1)
│   ├── repositories/search_repository.dart      watchSearch (2)
│   └── usecases/search_library_use_case.dart    SearchLibraryUseCase (4)
├── data/
│   ├── datasources/search_dao.dart              deckForest, changes (2); cardHits (3)
│   ├── mappers/search_mapper.dart               trailsOf, searchableDecksOf (2);
│   │                                            cardHitsOf (3)
│   └── repositories/search_repository_impl.dart (2, 3)
└── di/search_repository_provider.dart           searchRepositoryProvider (2)

test/architecture/boundary_rules.dart                          'search': {'deck'} (1)
test/features/search/domain/search_cursor_test.dart            (1)
test/features/search/domain/search_deck_hits_test.dart         (1)
test/features/search/data/search_decks_test.dart               (2)
test/features/search/data/search_cards_test.dart               (3)
test/features/search/data/search_pages_test.dart               (3)
test/features/search/domain/search_library_use_case_test.dart  (4)
```

Other changed files: UC-SEARCH-001's `code:`, the search README, a new
`features/search/data.md`, `wbs_BE.md`, `wbs_FE.md`,
`shared/ui/screen-handoff/04-library-search.md` and `01-deck-list.md` (Task 4),
and `docs/_generated/` (every task).

---


### Task 1: The search vocabulary: tiers, cursors, hits and pages

**Files:**
- Create: `lib/features/search/domain/models/library_search_model.dart`, `lib/features/search/domain/models/search_cursor_model.dart`, `lib/features/search/domain/models/search_hit_model.dart`
- Test (create): `test/features/search/domain/search_cursor_test.dart`, `test/features/search/domain/search_deck_hits_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `foldText` (`lib/core/text/folded_text.dart`); `DeckPathEntry`
  (`deck/domain/models/deck_path_model.dart`) and `DeckContentType`
  (`deck/domain/models/deck_content_type_model.dart`).
- Produces, in `lib/features/search/domain/models/search_cursor_model.dart`:
  - `enum SearchTier { exact, prefix, contains }` and
    `SearchTier? searchTierOf(String folded, String term)`.
  - `enum SearchGroup { deck, card }`.
  - `SearchCursor({required SearchGroup group, required SearchTier tier, required String sortText, required DateTime createdAt, required String id})`,
    which `implements Comparable<SearchCursor>`.
- Produces, in `lib/features/search/domain/models/search_hit_model.dart`:
  - `SearchableDeck({required String deckId, required String name, required DateTime createdAt, required List<DeckPathEntry> path, required DeckContentType contentType})`.
  - `SearchDeckHit({required String deckId, required String name, required List<DeckPathEntry> path, required DeckContentType contentType, required SearchCursor cursor})`,
    with `SearchTier get tier`.
  - `SearchCardHit({required String cardId, required String deckId, required String front, required String back, required List<DeckPathEntry> deckPath, required String? matchedTag, required SearchCursor cursor})`,
    with `SearchTier get tier`.
  - `List<SearchDeckHit> deckHitsOf(Iterable<SearchableDeck> decks, String term)`.
- Produces, in `lib/features/search/domain/models/library_search_model.dart`:
  `const searchPageSize = 50`; `sealed class LibrarySearch`;
  `LibrarySearchIdle()`;
  `LibrarySearchResults({required List<SearchDeckHit> decks, required List<SearchCardHit> cards, required SearchCursor? nextThrough})`,
  with `hasResults`.
- `allowedFeatureImports` gains `'search': {'deck'}`.

Spec §5.1–§5.3, D3–D5, D12; Clarifications 2 and 3. Pure Dart: the tier
of a folded text, the one order every hit takes its place in, and the deck
hits, matched and ordered in Dart from the decks the tree read gives.

- [ ] **Step 1: Write the failing tests, and add the feature to the import map**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'progress': {},
};
```

with

```dart
  'progress': {},
  'search': {'deck'},
};
```

Create `test/features/search/domain/search_cursor_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

// BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-007: the tier of a match and the
// total order of the results (Search spec §5.2, §5.3).

SearchCursor _cursor({
  SearchGroup group = SearchGroup.deck,
  SearchTier tier = SearchTier.exact,
  String sortText = 'a',
  DateTime? createdAt,
  String id = 'id',
}) => SearchCursor(
  group: group,
  tier: tier,
  sortText: sortText,
  createdAt: createdAt ?? DateTime.utc(2026, 9),
  id: id,
);

void main() {
  test('a folded text holds a folded term exactly, as a prefix, inside it, '
      'or not at all; accents count (BR-SEARCH-002, BR-SEARCH-004)', () {
    expect(searchTierOf('học', 'học'), SearchTier.exact);
    expect(searchTierOf('học qua phim', 'học'), SearchTier.prefix);
    expect(searchTierOf('từ vựng học thuật', 'học'), SearchTier.contains);
    expect(searchTierOf('hoc qua phim', 'học'), isNull);
  });

  test('every deck comes before every card, whatever its tier and text '
      '(BR-SEARCH-005)', () {
    final deck = _cursor(tier: SearchTier.contains, sortText: 'z');
    final card = _cursor(group: SearchGroup.card, sortText: 'a');

    expect(deck.compareTo(card), lessThan(0));
    expect(card.compareTo(deck), greaterThan(0));
  });

  test('within a group the tier comes first, then the text, then created_at, '
      'then the id: no two rows are equal (BR-SEARCH-004, BR-SEARCH-007)', () {
    final later = DateTime.utc(2026, 9, 2);
    final ordered = [
      _cursor(sortText: 'z'),
      _cursor(tier: SearchTier.prefix),
      _cursor(tier: SearchTier.prefix, sortText: 'b'),
      _cursor(tier: SearchTier.prefix, sortText: 'b', createdAt: later),
      _cursor(
        tier: SearchTier.prefix,
        sortText: 'b',
        createdAt: later,
        id: 'id2',
      ),
    ];

    final sorted = [...ordered.reversed]..sort();

    expect(sorted, ordered);
    expect(ordered.last.compareTo(ordered.last), 0);
  });

  test('texts compare by code point, the order SQLite gives UTF-8: a '
      'halfwidth ｱ comes before 𝒜, where Dart strings put it after '
      '(Search spec D5)', () {
    expect(
      _cursor(sortText: 'ｱ').compareTo(_cursor(sortText: '𝒜')),
      lessThan(0),
    );
    expect('ｱ'.compareTo('𝒜'), greaterThan(0));
    expect(_cursor(sortText: 'ab').compareTo(_cursor(sortText: 'a')), 1);
  });
}
```

Create `test/features/search/domain/search_deck_hits_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';

// BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-004: the decks a term finds, in
// the deck group's order (Search spec §5.2, §5.3, §6.1).

SearchableDeck _deck(String id, String name, {DateTime? createdAt}) =>
    SearchableDeck(
      deckId: id,
      name: name,
      createdAt: createdAt ?? DateTime.utc(2026, 9),
      path: const [DeckPathEntry(id: 'root', name: 'Root')],
      contentType: DeckContentType.card,
    );

List<String> _ids(List<SearchDeckHit> hits) => [
  for (final hit in hits) hit.deckId,
];

void main() {
  test('a name is folded in Dart: công nghệ finds CÔNG NGHỆ, and cong nghe '
      'is not found, accents counting (BR-SEARCH-002)', () {
    final decks = [_deck('upper', 'CÔNG NGHỆ'), _deck('plain', 'Cong nghe')];

    expect(_ids(deckHitsOf(decks, 'công nghệ')), ['upper']);
  });

  test('the exact name first, then the names it begins, then the names that '
      'hold it; the others are not hits (BR-SEARCH-001, BR-SEARCH-004)', () {
    final hits = deckHitsOf([
      _deck('contains', 'Từ vựng học thuật'),
      _deck('prefix', 'Học qua phim'),
      _deck('exact', 'Học'),
      _deck('none', 'Ngữ pháp'),
    ], 'học');

    expect(_ids(hits), ['exact', 'prefix', 'contains']);
    expect(
      [for (final hit in hits) hit.tier],
      [SearchTier.exact, SearchTier.prefix, SearchTier.contains],
    );
  });

  test('a tie falls to the folded name, then created_at, then the id, in the '
      'same order whatever order the decks come in (BR-SEARCH-004, '
      'BR-SEARCH-007)', () {
    final decks = [
      _deck('b', 'Học B'),
      _deck('late', 'Học A', createdAt: DateTime.utc(2026, 9, 3)),
      _deck('a2', 'học a', createdAt: DateTime.utc(2026, 9, 2)),
      _deck('a1', 'HỌC A', createdAt: DateTime.utc(2026, 9, 2)),
    ];

    final once = _ids(deckHitsOf(decks, 'học'));

    expect(once, ['a1', 'a2', 'late', 'b']);
    expect(_ids(deckHitsOf(decks.reversed, 'học')), once);
  });

  test('a hit shows the deck as written, with its path and content type; it '
      'sorts in the deck group on its folded name (Search spec §5.1)', () {
    final hit = deckHitsOf([_deck('d', 'Học qua phim')], 'học').single;

    expect(hit.name, 'Học qua phim');
    expect([for (final step in hit.path) step.name], ['Root']);
    expect(hit.contentType, DeckContentType.card);
    expect(
      (hit.cursor.group, hit.cursor.sortText),
      (SearchGroup.deck, 'học qua phim'),
    );
  });

  test('results with neither a deck nor a card have nothing to show '
      '(UC-SEARCH-001, no results)', () {
    const none = LibrarySearchResults(decks: [], cards: [], nextThrough: null);
    final one = LibrarySearchResults(
      decks: deckHitsOf([_deck('d', 'Học')], 'học'),
      cards: const [],
      nextThrough: null,
    );

    expect(none.hasResults, isFalse);
    expect(one.hasResults, isTrue);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/search/domain/search_cursor_test.dart \
  test/features/search/domain/search_deck_hits_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles: the models do not exist yet. The first errors: `Error: Undefined name 'SearchTier'.`, `Error: Method not found: 'deckHitsOf'.`, `Error: Method not found: 'searchTierOf'.`

- [ ] **Step 3: Write the tiers and the cursor**

Create `lib/features/search/domain/models/search_cursor_model.dart`:

```dart
/// How a folded field holds the folded term, the best first
/// (BR-SEARCH-004).
enum SearchTier { exact, prefix, contains }

/// The tier of [folded] for [term], null when it does not hold it. Both are
/// folded with `foldText` (BR-SEARCH-002); the card statement makes the same
/// test in SQL (Search spec D4).
SearchTier? searchTierOf(String folded, String term) {
  if (folded == term) return SearchTier.exact;
  if (folded.startsWith(term)) return SearchTier.prefix;
  if (folded.contains(term)) return SearchTier.contains;
  return null;
}

/// The two groups of results, decks first (BR-SEARCH-005).
enum SearchGroup { deck, card }

/// A result's place in the total order of a search: its group, its tier,
/// the folded text it sorts on, when it was made and its id (BR-SEARCH-007).
/// The UI only hands it back.
final class SearchCursor implements Comparable<SearchCursor> {
  const SearchCursor({
    required this.group,
    required this.tier,
    required this.sortText,
    required this.createdAt,
    required this.id,
  });

  final SearchGroup group;
  final SearchTier tier;

  /// A deck's folded name, a card's `front_folded` (Search spec D5).
  final String sortText;
  final DateTime createdAt;
  final String id;

  /// Texts compare by code point, the order SQLite's BINARY collation gives
  /// UTF-8, so Dart orders the decks by the rule SQLite orders the cards by
  /// (Search spec D5).
  @override
  int compareTo(SearchCursor other) {
    final byGroup = group.index.compareTo(other.group.index);
    if (byGroup != 0) return byGroup;
    final byTier = tier.index.compareTo(other.tier.index);
    if (byTier != 0) return byTier;
    final byText = _compareCodePoints(sortText, other.sortText);
    if (byText != 0) return byText;
    final byTime = createdAt.compareTo(other.createdAt);
    if (byTime != 0) return byTime;
    return _compareCodePoints(id, other.id);
  }
}

int _compareCodePoints(String a, String b) {
  final left = a.runes.iterator;
  final right = b.runes.iterator;
  while (true) {
    final hasLeft = left.moveNext();
    final hasRight = right.moveNext();
    if (!hasLeft || !hasRight) return (hasLeft ? 1 : 0) - (hasRight ? 1 : 0);
    final byRune = left.current.compareTo(right.current);
    if (byRune != 0) return byRune;
  }
}
```

- [ ] **Step 4: Write the hits, and match the decks**

Create `lib/features/search/domain/models/search_hit_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

/// A deck the search can find, as the snapshot's one read of the deck tree
/// gives it (Search spec §6.1).
final class SearchableDeck {
  const SearchableDeck({
    required this.deckId,
    required this.name,
    required this.createdAt,
    required this.path,
    required this.contentType,
  });

  final String deckId;
  final String name;
  final DateTime createdAt;

  /// The deck's ancestors, root first.
  final List<DeckPathEntry> path;
  final DeckContentType contentType;
}

/// A deck whose name holds the term (UC-SEARCH-001 step 5).
final class SearchDeckHit {
  const SearchDeckHit({
    required this.deckId,
    required this.name,
    required this.path,
    required this.contentType,
    required this.cursor,
  });

  final String deckId;

  /// The name as written; the UI emphasises the match.
  final String name;

  /// The deck's ancestors, root first, not the deck itself.
  final List<DeckPathEntry> path;
  final DeckContentType contentType;
  final SearchCursor cursor;

  SearchTier get tier => cursor.tier;
}

/// A card whose front, back or one of whose tags holds the term, once
/// however many of them do (BR-SEARCH-006; UC-SEARCH-001 step 5).
final class SearchCardHit {
  const SearchCardHit({
    required this.cardId,
    required this.deckId,
    required this.front,
    required this.back,
    required this.deckPath,
    required this.matchedTag,
    required this.cursor,
  });

  final String cardId;
  final String deckId;
  final String front;
  final String back;

  /// The card's deck with its ancestors, root first, the deck last.
  final List<DeckPathEntry> deckPath;

  /// The tag that made the card a hit, named only when neither face holds
  /// the term (Search spec D7).
  final String? matchedTag;
  final SearchCursor cursor;

  SearchTier get tier => cursor.tier;
}

/// Every deck of [decks] whose name, folded in Dart, holds [term], a folded
/// term, in the deck group's order (BR-SEARCH-001, BR-SEARCH-002,
/// BR-SEARCH-004; Search spec D3).
List<SearchDeckHit> deckHitsOf(Iterable<SearchableDeck> decks, String term) {
  final hits = [for (final deck in decks) ?_hitOf(deck, term)];
  return hits..sort((a, b) => a.cursor.compareTo(b.cursor));
}

SearchDeckHit? _hitOf(SearchableDeck deck, String term) {
  final folded = foldText(deck.name);
  final tier = searchTierOf(folded, term);
  if (tier == null) return null;
  return SearchDeckHit(
    deckId: deck.deckId,
    name: deck.name,
    path: deck.path,
    contentType: deck.contentType,
    cursor: SearchCursor(
      group: SearchGroup.deck,
      tier: tier,
      sortText: folded,
      createdAt: deck.createdAt,
      id: deck.deckId,
    ),
  );
}
```

- [ ] **Step 5: Write what the search shows**

Create `lib/features/search/domain/models/library_search_model.dart`:

```dart
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';

/// The rows of one page (Search spec D6).
const searchPageSize = 50;

/// What the library search shows (UC-SEARCH-001).
sealed class LibrarySearch {
  const LibrarySearch();
}

/// A query that folds to empty: the initial state, and nothing was read
/// (BR-SEARCH-003).
final class LibrarySearchIdle extends LibrarySearch {
  const LibrarySearchIdle();
}

/// The hits from the first through the watched cursor, decks first
/// (BR-SEARCH-005).
final class LibrarySearchResults extends LibrarySearch {
  const LibrarySearchResults({
    required this.decks,
    required this.cards,
    required this.nextThrough,
  });

  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;

  /// The cursor to watch through for one more page; null when nothing
  /// follows, and no "Load more" (BR-SEARCH-007; Search spec §5.4).
  final SearchCursor? nextThrough;

  bool get hasResults => decks.isNotEmpty || cards.isNotEmpty;
}
```

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/search/domain/search_cursor_test.dart \
  test/features/search/domain/search_deck_hits_test.dart
```

Expected: `+9: All tests passed!`

- [ ] **Step 8: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1410: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 9: Commit**

```bash
git add docs/_generated \
  lib/features/search/domain/models/library_search_model.dart \
  lib/features/search/domain/models/search_cursor_model.dart \
  lib/features/search/domain/models/search_hit_model.dart \
  test/architecture/boundary_rules.dart \
  test/features/search/domain/search_cursor_test.dart \
  test/features/search/domain/search_deck_hits_test.dart
git commit -F - <<'EOF'
feat(search): the search vocabulary: tiers, cursors, hits and pages

Every hit of the library search takes its place in one total order:
decks before cards, then the tier (exact, prefix, contains), the folded text
it sorts on, compared by code point as SQLite's BINARY collation compares
UTF-8, then created_at and id (BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-007).
deckHitsOf matches deck names folded in Dart and orders them (BR-SEARCH-002;
Search spec D3). The feature enters the import map with the deck models it
reads.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The deck side: one read of the deck tree, in one transaction

**Files:**
- Create: `lib/features/search/data/datasources/search_dao.dart`, `lib/features/search/data/mappers/search_mapper.dart`, `lib/features/search/data/repositories/search_repository_impl.dart`, `lib/features/search/di/search_repository_provider.dart`, `lib/features/search/domain/repositories/search_repository.dart`
- Test (create): `test/features/search/data/search_decks_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's models and `deckHitsOf`; `candidatesInTreeOrder` and
  `DeckTreeNode` (`deck/domain/models/deck_tree_model.dart`); `tableChanges`
  (`lib/core/database/table_changes.dart`); `mapDatabaseErrors`
  (`lib/core/error/failure.dart`); `databaseProvider`.
- Produces:
  - `abstract interface class SearchRepository`
    (`search/domain/repositories/search_repository.dart`) with
    `Stream<LibrarySearchResults> watchSearch({required String foldedTerm, SearchCursor? through})`.
  - `SearchDao(AppDatabase db)` (`search/data/datasources/search_dao.dart`), with
    `typedef SearchDeckRow = ({String id, String name, String? parentId, int siblingPosition, String contentType, DateTime createdAt})`,
    `Future<List<SearchDeckRow>> deckForest()` and `Stream<void> changes()`.
  - `Map<String, List<DeckPathEntry>> trailsOf(List<SearchDeckRow> rows)` and
    `List<SearchableDeck> searchableDecksOf(List<SearchDeckRow> rows, Map<String, List<DeckPathEntry>> trails)`
    (`search/data/mappers/search_mapper.dart`).
  - `SearchRepositoryImpl(AppDatabase db)`, and `searchRepositoryProvider`
    (`search/di/search_repository_provider.dart`).

Spec §5.4, §6.1, §6.3, §6.4, §6.6, D8, D9; Clarifications 4 and 7. Each
emission reads the live deck tree once and takes both the paths and the deck
hits from it. Until Task 3 an emission shows decks only: those through
`through`, or the first page when it is null or when nothing through it is
left, and a peek at the next page for `nextThrough`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/search/data/search_decks_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001: the deck group of the library search, its pages and its
// updates (Search spec §5, §6).

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (UC-SEARCH-001 E1).
final class _FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late SearchRepositoryImpl search;

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
    search = SearchRepositoryImpl(db);
  }

  setUp(open);
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<LibrarySearchResults> read(String term, {SearchCursor? through}) =>
      search.watchSearch(foldedTerm: term, through: through).first;

  List<String> names(LibrarySearchResults results) => [
    for (final hit in results.decks) hit.name,
  ];

  /// Decks `Deck 01` to `Deck [count]` under [rootId].
  Future<void> manyDecks(String rootId, int count) async {
    for (var n = 1; n <= count; n++) {
      await decks.sub(rootId, 'Deck ${n.toString().padLeft(2, '0')}');
    }
  }

  test('a deck is found by its name at any level, with its ancestors as its '
      'path and what it holds (BR-SEARCH-001; UC-SEARCH-001 step 5)', () async {
    final english = await decks.root('Tiếng Anh giao tiếp hằng ngày');
    final films = await decks.sub(english.id, 'Học qua phim');
    await insertCard(db, id: 'c1', deckId: films.id);
    await decks.root('Từ vựng học thuật');

    final results = await read('học');

    expect(
      [
        for (final hit in results.decks)
          (
            hit.name,
            [for (final step in hit.path) step.name].join(' › '),
            hit.contentType,
          ),
      ],
      [
        ('Học qua phim', 'Tiếng Anh giao tiếp hằng ngày', DeckContentType.card),
        ('Từ vựng học thuật', '', DeckContentType.deck),
      ],
    );
    expect(results.cards, isEmpty);
  });

  test('a deck in the Trash and a deleted deck are never found '
      '(BR-SEARCH-001)', () async {
    final root = await decks.root('Root');
    final kept = await decks.sub(root.id, 'Học kept');
    final trashed = await decks.sub(root.id, 'Học trashed');
    final deleted = await decks.sub(root.id, 'Học deleted');
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    expect(
      await decks.deleteDeck(deckId: deleted.id),
      isA<Ok<void, DeckRejection>>(),
    );

    final results = await read('học');

    expect([for (final hit in results.decks) hit.deckId], [kept.id]);
  });

  test(
    'the first page holds 50 decks, and nextThrough ends the next page: '
    'watching through it shows every deck (BR-SEARCH-005, BR-SEARCH-007)',
    () async {
      final root = await decks.root('Root');
      await manyDecks(root.id, 60);

      final first = await read('deck');
      final both = await read('deck', through: first.nextThrough);

      expect((first.decks.length, names(first).last), (50, 'Deck 50'));
      expect(names(both), [
        for (var n = 1; n <= 60; n++) 'Deck ${n.toString().padLeft(2, '0')}',
      ]);
      expect(both.nextThrough, isNull);
    },
  );

  test('a deck made between two pages repeats no deck and skips none: one '
      'before the cursor shows now, one after it with the next page '
      '(BR-SEARCH-007)', () async {
    final root = await decks.root('Root');
    await manyDecks(root.id, 60);
    final first = await read('deck');

    await decks.sub(root.id, 'Deck 00');
    await decks.sub(root.id, 'Deck 99');
    final shown = await read('deck', through: first.nextThrough);
    final rest = await read('deck', through: shown.nextThrough);

    expect(names(shown).length, 61);
    expect(names(shown).toSet().length, 61);
    expect(names(shown).first, 'Deck 00');
    expect(names(rest).last, 'Deck 99');
    expect(rest.nextThrough, isNull);
  });

  test('when every deck through the cursor is gone while decks follow, the '
      'first page shows, never an empty list with more to load '
      '(Search spec §5.4)', () async {
    final root = await decks.root('Root');
    final one = await decks.sub(root.id, 'Deck 1');
    await decks.sub(root.id, 'Deck 2');
    await decks.sub(root.id, 'Deck 3');
    final throughOne = (await read('deck')).decks.first.cursor;

    expect(
      await decks.deleteDeck(deckId: one.id),
      isA<Ok<void, DeckRejection>>(),
    );
    final shown = await read('deck', through: throughOne);

    expect(names(shown), ['Deck 2', 'Deck 3']);
    expect(shown.nextThrough, isNull);
  });

  test('reading writes nothing and opens no session (BR-SEARCH-008)', () async {
    final root = await decks.root('Học');
    await insertCard(
      db,
      id: 'c1',
      deckId: (await decks.sub(root.id, 'Lesson')).id,
    );
    final before = await totalChanges(db);

    await read('học');

    expect(await totalChanges(db), before);
    final sessions = await db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  test('renaming an ancestor or moving a deck gives the hits shown their '
      'new path, and a deleted deck leaves them (BR-SEARCH-008)', () async {
    final english = await decks.root('Tiếng Anh');
    final other = await decks.root('Khác');
    final film = await decks.sub(english.id, 'Học qua phim');
    final talk = await decks.sub(other.id, 'Học nói');
    final shown = <LibrarySearchResults>[];
    final subscription = search
        .watchSearch(foldedTerm: 'học')
        .listen(shown.add);
    await pumpEventQueue();
    List<String> paths() => [
      for (final hit in shown.last.decks)
        [for (final step in hit.path) step.name, hit.name].join(' › '),
    ];

    expect(
      await decks.renameDeck(deckId: english.id, name: 'English'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(paths(), ['Khác › Học nói', 'English › Học qua phim']);

    expect(
      await decks.moveDeck(deckId: film.id, newParentId: other.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(paths(), ['Khác › Học nói', 'Khác › Học qua phim']);

    expect(
      await decks.deleteDeck(deckId: talk.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(paths(), ['Khác › Học qua phim']);
    await subscription.cancel();
  });

  test(
    'a read that fails comes as a database Failure (UC-SEARCH-001 E1)',
    () async {
      await db.close();
      final failing = _FailingSelects();
      open(failing);
      await decks.root('Học');
      failing.isArmed = true;

      await expectLater(
        search.watchSearch(foldedTerm: 'học'),
        emitsError(isA<Failure>()),
      );
      failing.isArmed = false;
    },
  );
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/search/data/search_decks_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the repository does not exist yet. The first errors: `Error: Error when reading 'lib/features/search/data/repositories/search_repository_impl.dart': No such file or directory`, `Error: 'SearchRepositoryImpl' isn't a type.`, `Error: Method not found: 'SearchRepositoryImpl'.`

- [ ] **Step 3: Declare the repository**

Create `lib/features/search/domain/repositories/search_repository.dart`:

```dart
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

/// The library search's read (UC-SEARCH-001). The one implementation is
/// `SearchRepositoryImpl` (data layer); the contract exists for ADR-010's
/// reason: domain stays framework-free and tests substitute a fake.
abstract interface class SearchRepository {
  /// The hits of [foldedTerm], a term folded with `foldText`, from the first
  /// through [through], or the first page when it is null (Search spec
  /// §5.4), decks first, with the cursor that ends the next page; again
  /// after every write it can see. It writes nothing (BR-SEARCH-008).
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  });
}
```

- [ ] **Step 4: Read the deck tree**

Create `lib/features/search/data/datasources/search_dao.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

/// A deck as the search reads the tree (Search spec §6.1).
typedef SearchDeckRow = ({
  String id,
  String name,
  String? parentId,
  int siblingPosition,
  String contentType,
  DateTime createdAt,
});

/// Out of the Trash, on the table aliased [alias]: the one predicate every
/// read of the search uses (BR-SEARCH-001; Search spec D8).
String _live(String alias) => '$alias.delete_batch_id IS NULL';

/// The reads of the library search (Search spec §6). They write nothing
/// (BR-SEARCH-008).
final class SearchDao {
  const SearchDao(this._db);

  final AppDatabase _db;

  /// Every active deck in one statement: the decks to match, and the paths
  /// of every hit of the snapshot (BR-SEARCH-009).
  Future<List<SearchDeckRow>> deckForest() async {
    final rows = await _db
        .customSelect(
          'SELECT d.id, d.name, d.parent_id, d.sibling_position,'
          ' d.content_type, d.created_at'
          ' FROM deck d WHERE ${_live('d')}',
          readsFrom: {_db.deck},
        )
        .get();
    return [
      for (final row in rows)
        (
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          parentId: row.readNullable<String>('parent_id'),
          siblingPosition: row.read<int>('sibling_position'),
          contentType: row.read<String>('content_type'),
          createdAt: row.read<DateTime>('created_at'),
        ),
    ];
  }

  /// Fires once when listened to, then after every write to the decks
  /// (BR-SEARCH-008).
  Stream<void> changes() => tableChanges(_db, [_db.deck]);
}
```

- [ ] **Step 5: Map the tree to paths and searchable decks**

Create `lib/features/search/data/mappers/search_mapper.dart`:

```dart
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';

/// Every deck reached from a root, with its trail: the root first and the
/// deck last, walked once over one read of the tree (BR-SEARCH-009).
Map<String, List<DeckPathEntry>> trailsOf(List<SearchDeckRow> rows) => {
  for (final (id, trail) in candidatesInTreeOrder(
    [for (final row in rows) _nodeOf(row)],
    (node, path) =>
        (node.id, [...path, DeckPathEntry(id: node.id, name: node.name)]),
  ))
    id: trail,
};

/// The decks of [rows] that the walk reached, each with its ancestors
/// (Search spec §6.1).
List<SearchableDeck> searchableDecksOf(
  List<SearchDeckRow> rows,
  Map<String, List<DeckPathEntry>> trails,
) => [
  for (final row in rows)
    if (trails[row.id] case final trail?)
      SearchableDeck(
        deckId: row.id,
        name: row.name,
        createdAt: row.createdAt,
        path: trail.sublist(0, trail.length - 1),
        contentType: DeckContentType.values.byName(row.contentType),
      ),
];

DeckTreeNode _nodeOf(SearchDeckRow row) => DeckTreeNode(
  id: row.id,
  name: row.name,
  parentId: row.parentId,
  siblingPosition: row.siblingPosition,
  isCandidate: true,
  contentType: DeckContentType.values.byName(row.contentType),
);
```

- [ ] **Step 6: Read the decks through the cursor in one transaction**

Create `lib/features/search/data/repositories/search_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/data/mappers/search_mapper.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';

/// Reads the library search (UC-SEARCH-001; Search spec §6): one snapshot in
/// one transaction, once when listened to and again after every write it
/// can see.
final class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._db) : _search = SearchDao(_db);

  final AppDatabase _db;
  final SearchDao _search;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => _search
      .changes()
      .asyncMap((_) => _db.transaction(() => _read(foldedTerm, through)))
      .mapDatabaseErrors();

  /// The hits through [through], or the first page when it is null or when
  /// nothing through it is left, and the cursor that ends the next page
  /// (Search spec §5.4).
  Future<LibrarySearchResults> _read(String term, SearchCursor? through) async {
    final rows = await _search.deckForest();
    final decks = deckHitsOf(searchableDecksOf(rows, trailsOf(rows)), term);
    final bounded = through == null
        ? const <SearchDeckHit>[]
        : [
            for (final hit in decks)
              if (hit.cursor.compareTo(through) <= 0) hit,
          ];
    final shown = bounded.isEmpty
        ? decks.take(searchPageSize).toList()
        : bounded;
    final next = shown.isEmpty
        ? const <SearchDeckHit>[]
        : [
            for (final hit in decks)
              if (hit.cursor.compareTo(shown.last.cursor) > 0) hit,
          ].take(searchPageSize).toList();
    return LibrarySearchResults(
      decks: shown,
      cards: const [],
      nextThrough: next.isEmpty ? null : next.last.cursor,
    );
  }
}
```

- [ ] **Step 7: Give the repository a provider**

Create `lib/features/search/di/search_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_repository_provider.g.dart';

@riverpod
SearchRepository searchRepository(Ref ref) =>
    SearchRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 8: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run prints `Built with build_runner`, and `search_repository_provider.g.dart` exists next to its provider.

- [ ] **Step 9: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 10: Run the task's tests**

```bash
flutter test test/features/search/data/search_decks_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 11: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1418: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 12: Commit**

```bash
git add docs/_generated \
  lib/features/search/data/datasources/search_dao.dart \
  lib/features/search/data/mappers/search_mapper.dart \
  lib/features/search/data/repositories/search_repository_impl.dart \
  lib/features/search/di/search_repository_provider.dart \
  lib/features/search/domain/repositories/search_repository.dart \
  test/features/search/data/search_decks_test.dart
git commit -F - <<'EOF'
feat(search): the deck side of the library search, read in one transaction

SearchRepository watches the library search. Each emission reads the
live deck tree in one statement, in one transaction, and takes both the
paths and the deck hits from it, the names folded in Dart (UC-SEARCH-001;
Search spec §6.1, D3). It shows the hits through the watched cursor, or the
first page, and carries the cursor that ends the next page (BR-SEARCH-005,
BR-SEARCH-007). Decks in the Trash are never found, reading writes nothing,
and a failed read reaches the stream as a database Failure (BR-SEARCH-001,
BR-SEARCH-008; UC-SEARCH-001 E1).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: The card side: one statement, and pages across the two groups

**Files:**
- Modify: `lib/features/search/data/datasources/search_dao.dart`, `lib/features/search/data/mappers/search_mapper.dart`, `lib/features/search/data/repositories/search_repository_impl.dart`
- Test (create): `test/features/search/data/search_cards_test.dart`, `test/features/search/data/search_pages_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `SearchDao`, mapper and repository; `insertCard`
  (`test/support/card_fixtures.dart`); `SelectCounter`
  (`test/support/test_database.dart`); `CardRepositoryImpl` and
  `TagRepositoryImpl` for the writes the tests make.
- Produces:
  - In `SearchDao`:
    `typedef SearchCardRow = ({String id, String deckId, String front, String back, String frontFolded, DateTime createdAt, SearchTier? frontTier, SearchTier? backTier, SearchTier tier, String? tagName})`
    and
    `Future<List<SearchCardRow>> cardHits({required String term, SearchCursor? after, SearchCursor? through, int? limit})`;
    `changes()` now also fires after a write to `card`, `card_tags` or `tags`.
  - `List<SearchCardHit> cardHitsOf(List<SearchCardRow> rows, Map<String, List<DeckPathEntry>> trails)`
    in the mapper.
  - `watchSearch` returns the cards too; its signature does not change.

Spec §5.2–§5.4, §6.2, §6.3, §6.5, D4, D6, D7; Clarifications 1, 4, 5 and
6; Review Focus 1–5. The card statement ranks each field with `=` and `instr`
and a card's tags through correlated subqueries, one row per card, and pages
with a keyset and a limit. An emission reads the hits through `through` and
peeks at the next page, decks first, cards after the last deck.

- [ ] **Step 1: Write the failing tests**

Create `test/features/search/data/search_cards_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001: what the card group finds and how it ranks it (Search spec
// §5.2, §5.3, §6.2).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late TagRepositoryImpl tags;
  late SearchRepositoryImpl search;
  late String koreanId;
  late String lessonId;
  final now = DateTime(2026, 9, 25, 9);

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    tags = TagRepositoryImpl(db, now: () => now);
    search = SearchRepositoryImpl(db);
    koreanId = (await decks.root('Korean')).id;
    lessonId = (await decks.sub(koreanId, 'Lesson')).id;
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<LibrarySearchResults> read(String term) =>
      search.watchSearch(foldedTerm: term).first;

  List<String> ids(LibrarySearchResults results) => [
    for (final hit in results.cards) hit.cardId,
  ];

  Future<void> tag(String cardId, String name) async => expect(
    await tags.attachByName(cardIds: {cardId}, name: name),
    isA<Ok<void, TagRejection>>(),
  );

  test('a card is found by its front, its back or the name of one of its '
      'tags; never by its example, hint or pronunciation '
      '(BR-SEARCH-001)', () async {
    await insertCard(db, id: 'front', deckId: lessonId, front: 'học sinh');
    await insertCard(db, id: 'back', deckId: lessonId, back: 'học tập');
    await insertCard(db, id: 'tagged', deckId: lessonId, front: 'homework');
    await tag('tagged', 'Học');
    await insertCard(db, id: 'example', deckId: lessonId, example: 'học');
    await insertCard(db, id: 'hint', deckId: lessonId, hint: 'học');
    await CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => now),
      tags,
      now: () => now,
    ).card(
      lessonId,
      const CardDraft(front: 'e', back: 'f', pronunciation: 'học'),
    );

    expect(ids(await read('học')).toSet(), {'front', 'back', 'tagged'});
  });

  test('công nghệ finds a face written CÔNG NGHỆ, and cong does not find '
      'công: the faces are folded in Dart, accents counting '
      '(BR-SEARCH-002)', () async {
    await insertCard(db, id: 'upper', deckId: lessonId, front: 'CÔNG NGHỆ');
    await insertCard(db, id: 'accent', deckId: lessonId, front: 'công');

    expect(ids(await read('công nghệ')), ['upper']);
    expect(ids(await read('cong')), isEmpty);
  });

  test('exact first, then prefix, then contains: a card takes the best tier '
      'of its front, its back and its tags (BR-SEARCH-004)', () async {
    await insertCard(
      db,
      id: 'contains',
      deckId: lessonId,
      front: 'từ vựng học',
    );
    await insertCard(db, id: 'prefix', deckId: lessonId, back: 'học tập');
    await insertCard(db, id: 'exact', deckId: lessonId, front: 'từ vựng học');
    await tag('exact', 'Học');

    expect(
      [for (final hit in (await read('học')).cards) (hit.cardId, hit.tier)],
      [
        ('exact', SearchTier.exact),
        ('prefix', SearchTier.prefix),
        ('contains', SearchTier.contains),
      ],
    );
  });

  test('a card holding the term in its front, its back and two tags is one '
      'hit and names no tag; one found only through tags names its best '
      'one (BR-SEARCH-006; UC-SEARCH-001 step 5)', () async {
    await insertCard(
      db,
      id: 'everywhere',
      deckId: lessonId,
      front: 'học',
      back: 'học',
    );
    await tag('everywhere', 'Học');
    await tag('everywhere', 'Học tập');
    await insertCard(db, id: 'tags', deckId: lessonId, front: 'homework');
    await tag('tags', 'Học tập');
    await tag('tags', 'Học');

    expect(
      [
        for (final hit in (await read('học')).cards)
          (hit.cardId, hit.matchedTag),
      ],
      [('tags', 'Học'), ('everywhere', null)],
    );
  });

  test("a card's hit shows its faces as written and the path from the root "
      'to its deck (UC-SEARCH-001 step 5)', () async {
    await insertCard(
      db,
      id: 'c1',
      deckId: lessonId,
      front: 'Học sinh',
      back: 'student',
    );

    final hit = (await read('học')).cards.single;

    expect(
      (hit.front, hit.back, hit.deckId),
      ('Học sinh', 'student', lessonId),
    );
    expect([for (final step in hit.deckPath) step.name], ['Korean', 'Lesson']);
    expect(hit.cursor.group, SearchGroup.card);
  });

  test('a card in the Trash, and a deck in the Trash with its cards, are '
      'never found (BR-SEARCH-001; Search spec D8)', () async {
    await insertCard(db, id: 'kept', deckId: lessonId, front: 'học');
    await insertCard(
      db,
      id: 'trashed',
      deckId: lessonId,
      front: 'học',
      deleteBatchId: 'batch',
    );
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

    expect(ids(await read('học')), ['kept']);
  });

  test('% and _ in a term are plain characters, not wildcards '
      '(Search spec D4)', () async {
    await insertCard(db, id: 'percent', deckId: lessonId, front: '100% done');
    await insertCard(db, id: 'digits', deckId: lessonId, front: '1000 done');
    await insertCard(
      db,
      id: 'underscore',
      deckId: lessonId,
      front: 'snake_case',
    );
    await insertCard(db, id: 'space', deckId: lessonId, front: 'snake case');

    expect(ids(await read('100%')), ['percent']);
    expect(ids(await read('e_c')), ['underscore']);
  });

  test('decks and cards order their texts by one rule, code point: ｱ before '
      '𝒜 in both groups (Search spec D5)', () async {
    await decks.sub(koreanId, 'x𝒜');
    await decks.sub(koreanId, 'xｱ');
    await insertCard(db, id: 'script', deckId: lessonId, front: 'x𝒜');
    await insertCard(db, id: 'kana', deckId: lessonId, front: 'xｱ');

    final results = await read('x');

    expect([for (final hit in results.decks) hit.name], ['xｱ', 'x𝒜']);
    expect(ids(results), ['kana', 'script']);
  });
}
```

Create `test/features/search/data/search_pages_test.dart`:

```dart
import 'package:drift/drift.dart' show UpdateKind;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001 A1, A3: pages across the two groups, what a write changes,
// and what one emission reads (Search spec §5.4, §6.3, §6.4).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late TagRepositoryImpl tags;
  late CardRepositoryImpl cards;
  late SearchRepositoryImpl search;
  late String koreanId;
  late String lessonId;
  final now = DateTime(2026, 9, 25, 9);

  Future<void> open([SelectCounter? counter]) async {
    db = openTestDatabase(interceptor: counter);
    decks = DeckRepositoryImpl(db, now: () => now);
    tags = TagRepositoryImpl(db, now: () => now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => now),
      tags,
      now: () => now,
    );
    search = SearchRepositoryImpl(db);
    koreanId = (await decks.root('Korean')).id;
    lessonId = (await decks.sub(koreanId, 'Lesson')).id;
  }

  setUp(open);
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<LibrarySearchResults> read(String term, {SearchCursor? through}) =>
      search.watchSearch(foldedTerm: term, through: through).first;

  List<String> ids(LibrarySearchResults results) => [
    for (final hit in results.cards) hit.cardId,
  ];

  /// Cards `c01` to `c[count]`, their fronts `học 01` to `học [count]`.
  Future<void> manyCards(int count) async {
    for (var n = 1; n <= count; n++) {
      final number = n.toString().padLeft(2, '0');
      await insertCard(
        db,
        id: 'c$number',
        deckId: lessonId,
        front: 'học $number',
      );
    }
  }

  test('decks first: the first page takes every deck, then fills with '
      'cards; nextThrough ends exactly one more page, and watching through '
      'it goes on with cards (BR-SEARCH-005, BR-SEARCH-007)', () async {
    for (var n = 1; n <= 3; n++) {
      await decks.sub(koreanId, 'Học $n');
    }
    await manyCards(99);

    final first = await read('học');
    final two = await read('học', through: first.nextThrough);

    expect((first.decks.length, first.cards.length), (3, 47));
    expect(first.nextThrough?.id, 'c97');
    expect((two.decks.length, two.cards.length), (3, 97));
    expect(two.nextThrough?.id, 'c99');
  });

  test('more than a page of decks: the first page is decks alone, and '
      'watching through nextThrough goes on from the last deck to the first '
      'card, skipping none (BR-SEARCH-005, BR-SEARCH-007)', () async {
    for (var n = 10; n < 65; n++) {
      await decks.sub(koreanId, 'Học $n');
    }
    await manyCards(3);

    final first = await read('học');
    final two = await read('học', through: first.nextThrough);

    expect((first.decks.length, first.cards.length), (50, 0));
    expect(two.decks.length, 55);
    expect(ids(two), ['c01', 'c02', 'c03']);
    expect(two.nextThrough, isNull);
  });

  test('a card written between two pages repeats no card and skips none; '
      'a card equal to another in tier, front and created_at falls to its '
      'id (BR-SEARCH-007)', () async {
    await manyCards(60);
    final first = await read('học');

    await insertCard(db, id: 'c00', deckId: lessonId, front: 'học 00');
    await insertCard(db, id: 'c99', deckId: lessonId, front: 'học 99');
    await insertCard(db, id: 'b30', deckId: lessonId, front: 'học 30');
    final shown = ids(await read('học', through: first.nextThrough));
    final rest = await read(
      'học',
      through: (await read('học', through: first.nextThrough)).nextThrough,
    );

    expect((shown.length, shown.toSet().length), (62, 62));
    expect(shown.first, 'c00');
    expect(shown.sublist(shown.indexOf('b30'), shown.indexOf('b30') + 2), [
      'b30',
      'c30',
    ]);
    expect(ids(rest).last, 'c99');
    expect(rest.nextThrough, isNull);
  });

  test('when every card through the cursor is gone while cards follow, the '
      'first page shows (Search spec §5.4)', () async {
    await manyCards(3);
    final throughFirst = (await read('học')).cards.first.cursor;

    expect(
      await cards.deleteCards(cardIds: {'c01'}),
      isA<Ok<void, CardRejection>>(),
    );
    final shown = await read('học', through: throughFirst);

    expect(ids(shown), ['c02', 'c03']);
    expect(shown.nextThrough, isNull);
  });

  test(
    'cards of a deck in the Trash take no place on a page: the live '
    'cards after them still fill it (BR-SEARCH-001, BR-SEARCH-007)',
    () async {
      final gone = await decks.sub(koreanId, 'Gone');
      for (var n = 1; n <= searchPageSize; n++) {
        await insertCard(db, id: 'g$n', deckId: gone.id, front: 'học a$n');
      }
      await db.customStatement(
        'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
        ['batch', gone.id],
      );
      await insertCard(db, id: 'kept', deckId: lessonId, front: 'học b');

      expect(ids(await read('học')), ['kept']);
    },
  );

  test(
    'the results come again on a moved card, a deleted card, a tag put '
    'on a card and a renamed tag (BR-SEARCH-008; UC-SEARCH-001 A3)',
    () async {
      await insertCard(db, id: 'c1', deckId: lessonId, front: 'học 1');
      await insertCard(db, id: 'c2', deckId: lessonId, front: 'học 2');
      await insertCard(db, id: 'c3', deckId: lessonId, front: 'three');
      final other = await decks.sub(koreanId, 'Other');
      final shown = <LibrarySearchResults>[];
      final subscription = search
          .watchSearch(foldedTerm: 'học')
          .listen(shown.add);
      await pumpEventQueue();

      expect(
        await cards.moveCards(cardIds: {'c1'}, targetDeckId: other.id),
        isA<Ok<void, CardRejection>>(),
      );
      await pumpEventQueue();
      expect(
        [for (final step in shown.last.cards.first.deckPath) step.name],
        ['Korean', 'Other'],
      );

      expect(
        await cards.deleteCards(cardIds: {'c2'}),
        isA<Ok<void, CardRejection>>(),
      );
      await pumpEventQueue();
      expect(ids(shown.last), ['c1']);

      expect(
        await tags.attachByName(cardIds: {'c3'}, name: 'Học'),
        isA<Ok<void, TagRejection>>(),
      );
      await pumpEventQueue();
      expect(ids(shown.last), ['c3', 'c1']);

      await db.customUpdate(
        "UPDATE tags SET name = 'Học phần', name_folded = 'học phần'",
        updates: {db.tags},
        updateKind: UpdateKind.update,
      );
      await pumpEventQueue();
      expect(
        [for (final hit in shown.last.cards) (hit.cardId, hit.matchedTag)],
        [('c1', null), ('c3', 'Học phần')],
      );
      await subscription.cancel();
    },
  );

  test('one emission reads the deck tree once and runs at most two card '
      'statements, however many hits (BR-SEARCH-009)', () async {
    await db.close();
    final counter = SelectCounter();
    await open(counter);
    for (var n = 1; n <= 3; n++) {
      await decks.sub(koreanId, 'Học $n');
    }
    await manyCards(99);

    counter.selects = 0;
    final first = await read('học');
    final firstReads = counter.selects;
    counter.selects = 0;
    await read('học', through: first.nextThrough);

    expect((firstReads, counter.selects), (3, 3));
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/search/data/search_cards_test.dart \
  test/features/search/data/search_pages_test.dart
```

Expected: `+0 -15: Some tests failed.` Every test fails on its expectations, none on compiling: the repository reads no card yet, so the card lists are empty (`Actual: []`), a read of the first card finds none (`Bad state: No element`), the first page of three decks and 99 cards is `(3, 0)` where `(3, 47)` is expected, and one emission runs `(1, 1)` SELECTs where `(3, 3)` is.

- [ ] **Step 3: Match the cards in one statement, and listen to their tables**

Replace the whole of `lib/features/search/data/datasources/search_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';

/// A deck as the search reads the tree (Search spec §6.1).
typedef SearchDeckRow = ({
  String id,
  String name,
  String? parentId,
  int siblingPosition,
  String contentType,
  DateTime createdAt,
});

/// A card that holds the term, once (Search spec §6.2): the tier of each
/// face, null when the face does not hold the term, its own tier, the best
/// of its faces and tags, and the name of its best matching tag.
typedef SearchCardRow = ({
  String id,
  String deckId,
  String front,
  String back,
  String frontFolded,
  DateTime createdAt,
  SearchTier? frontTier,
  SearchTier? backTier,
  SearchTier tier,
  String? tagName,
});

/// Out of the Trash, on the table aliased [alias]: the one predicate every
/// read of the search uses (BR-SEARCH-001; Search spec D8).
String _live(String alias) => '$alias.delete_batch_id IS NULL';

/// Past the last tier: the field does not hold the term.
final _noTier = SearchTier.values.length;

/// [folded]'s tier for the term `?1`, the index of the `SearchTier` that
/// `searchTierOf` gives, by `=` and `instr`: never `LIKE`, so `%` and `_`
/// are plain characters, and never `lower()` (Search spec D4).
String _tierOf(String folded) =>
    'CASE WHEN $folded = ?1 THEN ${SearchTier.exact.index}'
    ' WHEN instr($folded, ?1) = 1 THEN ${SearchTier.prefix.index}'
    ' WHEN instr($folded, ?1) > 0 THEN ${SearchTier.contains.index}'
    ' ELSE $_noTier END';

/// The tags of the card `c`, for a correlated subquery (Search spec D7).
const _tagsOfCard =
    'FROM card_tags ct JOIN tags t ON t.id = ct.tag_id'
    ' WHERE ct.card_id = c.id';

/// Every live card with the tier of its front, its back and its best tag,
/// and the name of its best matching tag: one row per card, from correlated
/// subqueries, never `DISTINCT` over a join (BR-SEARCH-006); then its tier,
/// the best of the three, and only the cards that have one (BR-SEARCH-004).
final _cardHits =
    'WITH hits AS (SELECT c.id, c.deck_id, c.front, c.back, c.front_folded,'
    ' c.created_at,'
    ' ${_tierOf('c.front_folded')} AS front_tier,'
    ' ${_tierOf('c.back_folded')} AS back_tier,'
    ' COALESCE((SELECT MIN(${_tierOf('t.name_folded')}) $_tagsOfCard),'
    ' $_noTier) AS tag_tier,'
    ' (SELECT t.name $_tagsOfCard AND instr(t.name_folded, ?1) > 0'
    ' ORDER BY ${_tierOf('t.name_folded')}, t.name_folded, t.id'
    ' LIMIT 1) AS tag_name'
    ' FROM card c JOIN deck k ON k.id = c.deck_id'
    ' WHERE ${_live('c')} AND ${_live('k')}),'
    ' tiered AS (SELECT hits.*, MIN(front_tier, back_tier, tag_tier) AS tier'
    ' FROM hits)'
    ' SELECT * FROM tiered WHERE tier < $_noTier';

/// A card's key, in the order of `SearchCursor` (BR-SEARCH-007).
const _key = '(tier, front_folded, created_at, id)';

/// The reads of the library search (Search spec §6). They write nothing
/// (BR-SEARCH-008).
final class SearchDao {
  const SearchDao(this._db);

  final AppDatabase _db;

  /// Every active deck in one statement: the decks to match, and the paths
  /// of every hit of the snapshot (BR-SEARCH-009).
  Future<List<SearchDeckRow>> deckForest() async {
    final rows = await _db
        .customSelect(
          'SELECT d.id, d.name, d.parent_id, d.sibling_position,'
          ' d.content_type, d.created_at'
          ' FROM deck d WHERE ${_live('d')}',
          readsFrom: {_db.deck},
        )
        .get();
    return [
      for (final row in rows)
        (
          id: row.read<String>('id'),
          name: row.read<String>('name'),
          parentId: row.readNullable<String>('parent_id'),
          siblingPosition: row.read<int>('sibling_position'),
          contentType: row.read<String>('content_type'),
          createdAt: row.read<DateTime>('created_at'),
        ),
    ];
  }

  /// The live cards whose front, back or tag name holds [term], one row
  /// each, in the card group's order: after [after], through [through], at
  /// most [limit] rows, never an `OFFSET` (BR-SEARCH-001, BR-SEARCH-004,
  /// BR-SEARCH-006, BR-SEARCH-007).
  Future<List<SearchCardRow>> cardHits({
    required String term,
    SearchCursor? after,
    SearchCursor? through,
    int? limit,
  }) async {
    final rows = await _db
        .customSelect(
          '$_cardHits'
          '${after == null ? '' : ' AND $_key > (?, ?, ?, ?)'}'
          '${through == null ? '' : ' AND $_key <= (?, ?, ?, ?)'}'
          ' ORDER BY tier, front_folded, created_at, id'
          '${limit == null ? '' : ' LIMIT ?'}',
          variables: [
            Variable<String>(term),
            ...?_keyOf(after),
            ...?_keyOf(through),
            if (limit != null) Variable<int>(limit),
          ],
          readsFrom: {_db.card, _db.deck, _db.cardTags, _db.tags},
        )
        .get();
    return [for (final row in rows) _cardRowOf(row)];
  }

  /// Fires once when listened to, then after every write to the decks, the
  /// cards, the tags or the tags on cards (BR-SEARCH-008).
  Stream<void> changes() =>
      tableChanges(_db, [_db.deck, _db.card, _db.cardTags, _db.tags]);
}

List<Variable<Object>>? _keyOf(SearchCursor? cursor) => cursor == null
    ? null
    : [
        Variable<int>(cursor.tier.index),
        Variable<String>(cursor.sortText),
        Variable<DateTime>(cursor.createdAt),
        Variable<String>(cursor.id),
      ];

SearchCardRow _cardRowOf(QueryRow row) => (
  id: row.read<String>('id'),
  deckId: row.read<String>('deck_id'),
  front: row.read<String>('front'),
  back: row.read<String>('back'),
  frontFolded: row.read<String>('front_folded'),
  createdAt: row.read<DateTime>('created_at'),
  frontTier: _tierAt(row.read<int>('front_tier')),
  backTier: _tierAt(row.read<int>('back_tier')),
  tier: SearchTier.values[row.read<int>('tier')],
  tagName: row.readNullable<String>('tag_name'),
);

SearchTier? _tierAt(int index) =>
    index < _noTier ? SearchTier.values[index] : null;
```

- [ ] **Step 4: Map a card row to a hit**

In `lib/features/search/data/mappers/search_mapper.dart`:

Replace

```dart
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
```

with

```dart
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
```

Replace

```dart

DeckTreeNode _nodeOf(SearchDeckRow row) => DeckTreeNode(
```

with

```dart

/// The card rows whose deck the walk reached, each with its deck's trail.
/// A hit names its tag only when neither face holds the term (Search spec
/// §6.5, D7).
List<SearchCardHit> cardHitsOf(
  List<SearchCardRow> rows,
  Map<String, List<DeckPathEntry>> trails,
) => [
  for (final row in rows)
    if (trails[row.deckId] case final trail?)
      SearchCardHit(
        cardId: row.id,
        deckId: row.deckId,
        front: row.front,
        back: row.back,
        deckPath: trail,
        matchedTag: row.frontTier == null && row.backTier == null
            ? row.tagName
            : null,
        cursor: SearchCursor(
          group: SearchGroup.card,
          tier: row.tier,
          sortText: row.frontFolded,
          createdAt: row.createdAt,
          id: row.id,
        ),
      ),
];

DeckTreeNode _nodeOf(SearchDeckRow row) => DeckTreeNode(
```

- [ ] **Step 5: Page across decks and cards**

Replace the whole of `lib/features/search/data/repositories/search_repository_impl.dart` with:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_path_model.dart';
import 'package:memox/features/search/data/datasources/search_dao.dart';
import 'package:memox/features/search/data/mappers/search_mapper.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';

/// Reads the library search (UC-SEARCH-001; Search spec §6): one snapshot in
/// one transaction, once when listened to and again after every write it
/// can see.
final class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._db) : _search = SearchDao(_db);

  final AppDatabase _db;
  final SearchDao _search;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => _search
      .changes()
      .asyncMap((_) => _db.transaction(() => _read(foldedTerm, through)))
      .mapDatabaseErrors();

  /// The hits through [through], or the first page when it is null or when
  /// nothing through it is left, and the cursor that ends the next page
  /// (Search spec §5.4, §6.3).
  Future<LibrarySearchResults> _read(String term, SearchCursor? through) async {
    final rows = await _search.deckForest();
    final trails = trailsOf(rows);
    final decks = deckHitsOf(searchableDecksOf(rows, trails), term);
    Future<_Page> pageAfter(SearchCursor? cursor) =>
        _pageAfter(term, decks, trails, cursor);
    final bounded = through == null
        ? _Page.none
        : await _through(term, decks, trails, through);
    final shown = bounded.isEmpty ? await pageAfter(null) : bounded;
    final next = shown.isEmpty ? _Page.none : await pageAfter(shown.last);
    return LibrarySearchResults(
      decks: shown.decks,
      cards: shown.cards,
      nextThrough: next.isEmpty ? null : next.last,
    );
  }

  /// The hits at or before [through]: the decks, and the cards when it is a
  /// card's cursor.
  Future<_Page> _through(
    String term,
    List<SearchDeckHit> decks,
    Map<String, List<DeckPathEntry>> trails,
    SearchCursor through,
  ) async => _Page(
    [
      for (final hit in decks)
        if (hit.cursor.compareTo(through) <= 0) hit,
    ],
    through.group == SearchGroup.deck
        ? const []
        : cardHitsOf(
            await _search.cardHits(term: term, through: through),
            trails,
          ),
  );

  /// One page after [after], the first when it is null: decks first, then
  /// cards to fill it (BR-SEARCH-005).
  Future<_Page> _pageAfter(
    String term,
    List<SearchDeckHit> decks,
    Map<String, List<DeckPathEntry>> trails,
    SearchCursor? after,
  ) async {
    final pageDecks = [
      for (final hit in decks)
        if (after == null || hit.cursor.compareTo(after) > 0) hit,
    ].take(searchPageSize).toList();
    final room = searchPageSize - pageDecks.length;
    if (room == 0) return _Page(pageDecks, const []);
    final cards = await _search.cardHits(
      term: term,
      after: after?.group == SearchGroup.card ? after : null,
      limit: room,
    );
    return _Page(pageDecks, cardHitsOf(cards, trails));
  }
}

/// Hits in order, decks first (BR-SEARCH-005).
final class _Page {
  const _Page(this.decks, this.cards);

  static const none = _Page([], []);

  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;

  bool get isEmpty => decks.isEmpty && cards.isEmpty;

  /// The cursor of the last hit, of a page that is not empty.
  SearchCursor get last =>
      cards.isEmpty ? decks.last.cursor : cards.last.cursor;
}
```

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/search/data/search_cards_test.dart \
  test/features/search/data/search_pages_test.dart
```

Expected: `+15: All tests passed!`

- [ ] **Step 8: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1433: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 9: Commit**

```bash
git add docs/_generated \
  lib/features/search/data/datasources/search_dao.dart \
  lib/features/search/data/mappers/search_mapper.dart \
  lib/features/search/data/repositories/search_repository_impl.dart \
  test/features/search/data/search_cards_test.dart \
  test/features/search/data/search_pages_test.dart
git commit -F - <<'EOF'
feat(search): the card side of the library search, and its pages

The card statement matches a card's front, back and tag names with = and
instr, never LIKE or lower(), gives each card its best tier, and names the
tag it matched through only when neither face did: one row per card, from
correlated subqueries (BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-004,
BR-SEARCH-006). Pages are keyset on the tier, front_folded, created_at and
id, never OFFSET: an emission shows the decks first, then the cards through
the watched cursor, and peeks at the next page for nextThrough
(BR-SEARCH-005, BR-SEARCH-007). The results come again after every write to
deck, card, card_tags or tags, with one read of the deck tree and at most
two card statements (BR-SEARCH-008, BR-SEARCH-009).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: The use case, and the package's documents

**Files:**
- Create: `lib/features/search/domain/usecases/search_library_use_case.dart`
- Modify: `docs/features/search/README.md`, `docs/features/search/data.md`, `docs/features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md`, `docs/shared/ui/screen-handoff/01-deck-list.md`, `docs/shared/ui/screen-handoff/04-library-search.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`
- Test (create): `test/features/search/domain/search_library_use_case_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `SearchRepository` (Tasks 2 and 3); `foldText`; `SelectCounter`.
- Produces: `SearchLibraryUseCase(SearchRepository)` with
  `Stream<LibrarySearch> call({required String term, SearchCursor? through})`
  (`search/domain/usecases/search_library_use_case.dart`); UC-SEARCH-001's
  `code:` names it; the search README and a new `features/search/data.md`
  describe the reads; `wbs_BE.md` has BE-A8 done; `wbs_FE.md`,
  `04-library-search.md` and `01-deck-list.md` wait for FE-A10.

Spec §7, §8, §10, D1, D10, D13; Clarifications 5 and 8. The use case folds
the term once; nothing below it folds again.

- [ ] **Step 1: Write the failing tests**

Create `test/features/search/domain/search_library_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/usecases/search_library_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// UC-SEARCH-001: the use case folds the term, and a blank one reads nothing
// (BR-SEARCH-002, BR-SEARCH-003; Search spec §7).

void main() {
  late AppDatabase db;
  late SelectCounter counter;
  late SearchLibraryUseCase searchLibrary;

  setUp(() async {
    counter = SelectCounter();
    db = openTestDatabase(interceptor: counter);
    final decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Học');
    await insertCard(db, id: 'c1', deckId: lesson.id, front: 'học 1');
    await insertCard(db, id: 'c2', deckId: lesson.id, front: 'học 2');
    searchLibrary = SearchLibraryUseCase(SearchRepositoryImpl(db));
  });
  tearDown(() => db.close());

  Future<LibrarySearchResults> results(
    String term, {
    SearchCursor? through,
  }) async =>
      await searchLibrary(term: term, through: through).first
          as LibrarySearchResults;

  test('a blank or all-space term is LibrarySearchIdle and reads nothing '
      'from the database (BR-SEARCH-003)', () async {
    counter.selects = 0;

    for (final term in ['', '   ', ' \t\n ']) {
      expect(await searchLibrary(term: term).first, isA<LibrarySearchIdle>());
    }
    expect(counter.selects, 0);
  });

  test('the term is folded before it is matched: its case and the spaces '
      'around it do not matter (BR-SEARCH-002)', () async {
    final shown = await results('  HỌC  ');

    expect([for (final hit in shown.decks) hit.name], ['Học']);
    expect([for (final hit in shown.cards) hit.cardId], ['c1', 'c2']);
  });

  test('watching through a cursor shows the hits through it '
      '(UC-SEARCH-001 A1)', () async {
    final first = await results('học');

    final shown = await results('học', through: first.cards.first.cursor);

    expect([for (final hit in shown.cards) hit.cardId], ['c1']);
    expect(shown.nextThrough?.id, 'c2');
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/search/domain/search_library_use_case_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the use case does not exist yet. The first errors: `Error: Error when reading 'lib/features/search/domain/usecases/search_library_use_case.dart': No such file or directory`, `Error: 'SearchLibraryUseCase' isn't a type.`, `Error: Method not found: 'SearchLibraryUseCase'.`

- [ ] **Step 3: Write the use case**

Create `lib/features/search/domain/usecases/search_library_use_case.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';

/// UC-SEARCH-001: the decks and cards whose searched fields hold [term],
/// case and the spaces around it aside, through [through] (the first page
/// when it is null), again after every write they can see. A blank term is
/// [LibrarySearchIdle] and reads nothing (BR-SEARCH-002, BR-SEARCH-003).
final class SearchLibraryUseCase {
  const SearchLibraryUseCase(this._search);

  final SearchRepository _search;

  Stream<LibrarySearch> call({required String term, SearchCursor? through}) {
    final foldedTerm = foldText(term);
    if (foldedTerm.isEmpty) return Stream.value(const LibrarySearchIdle());
    return _search.watchSearch(foldedTerm: foldedTerm, through: through);
  }
}
```

- [ ] **Step 4: Record the package in the use case, the documents and the WBS**

In `docs/features/search/README.md`:

Replace

```markdown
feature: search
code: []
depends_on: [card, deck, tags]
```

with

```markdown
feature: search
code: [lib/features/search/domain, lib/features/search/data, lib/features/search/di]
depends_on: [card, deck, tags]
```

Replace

```markdown
Tìm kiếm toàn thư viện (Global Library Search): tên deck, hai mặt card và tên tag. Thuộc V8.0 (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)).

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

```

with

```markdown
Tìm kiếm toàn thư viện (Global Library Search): tên deck, hai mặt card và tên tag. Thuộc V8.0 (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)).

```

Create `docs/features/search/data.md`:

```markdown
# Search — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Những gì được tìm

Tìm kiếm chỉ đọc bốn trường: tên deck, mặt trước và mặt sau của card, tên tag. Nó không
đọc `example`, `hint` hay `pronunciation` (BR-SEARCH-001). Deck và card nằm trong Trash,
và card của một deck nằm trong Trash, không bao giờ hiện: mọi câu lệnh lọc
`delete_batch_id IS NULL`, trên card lẫn trên deck của nó.

- **Chuẩn hoá:** câu truy vấn đi qua đúng hàm fold mà các cột `*_folded` dùng khi ghi:
  bỏ khoảng trắng hai đầu, hạ chữ theo Unicode của Dart, giữ dấu (BR-SEARCH-002). SQL
  không dùng `lower()` hay `COLLATE NOCASE`. Câu truy vấn fold thành rỗng không chạy câu
  lệnh nào (BR-SEARCH-003).
- **Tên deck** không có cột folded: tên được fold trong Dart, từ một lần đọc cây deck.
- **Card và tag** được so trên `card.front_folded`, `card.back_folded` và
  `tags.name_folded`, bằng `=` và `instr`. Không dùng `LIKE`, nên `%` và `_` trong câu
  truy vấn là ký tự thường.

## Thứ tự

- Khớp đúng, rồi khớp tiền tố, rồi khớp chứa (BR-SEARCH-004). Bậc của một card là bậc
  tốt nhất trong mặt trước, mặt sau và các tag của nó. Card khớp ở nhiều trường vẫn là
  một kết quả, và chỉ mang tên tag khi không mặt nào khớp (BR-SEARCH-006).
- Deck trước, card sau (BR-SEARCH-005). Trong mỗi nhóm: bậc khớp, rồi văn bản đã fold
  (tên deck; `front_folded` của card), `created_at`, `id` (BR-SEARCH-007). Văn bản được
  so theo code point. Đó là thứ tự BINARY của SQLite trên UTF-8, nên Dart (nhóm deck) và
  SQLite (nhóm card) sắp theo cùng một cách.

## Các câu lệnh

Mỗi lần đọc chạy trong một transaction:

1. một câu lệnh đọc mọi deck không nằm trong Trash: các deck để khớp tên, và đường dẫn
   của mọi kết quả, cả deck lẫn card (BR-SEARCH-009);
2. câu lệnh card: mỗi card một hàng, bậc của từng trường tính bằng subquery tương quan,
   không `DISTINCT` trên phép join. Câu lệnh phân trang theo keyset
   `(bậc, front_folded, created_at, id)` với `LIMIT`, không `OFFSET` (BR-SEARCH-007).

Một trang có 50 kết quả, deck trước. Màn hình xem mọi kết quả tới con trỏ `through`
(trang đầu khi chưa có con trỏ). Mỗi lần đọc trả về `nextThrough`, con trỏ kết thúc trang
kế tiếp, hoặc không trả về con trỏ nào khi đã hết kết quả. Khi mọi kết quả tới `through`
đã biến mất trong khi vẫn còn kết quả phía sau, trang đầu hiện ra. Một lần đọc chạy tối
đa hai câu lệnh card; ba chỉ trong trường hợp vừa nói.

## Khi nào đọc lại

Sau mỗi lần ghi vào `deck`, `card`, `card_tags` hay `tags` (một transaction, một lần
đọc), nên đường dẫn, tên và tag đang hiển thị luôn đúng. Tìm kiếm không ghi hàng nào và
không mở phiên nào (BR-SEARCH-008).

## Hiệu năng

Không có index hay bảng FTS nào cho tìm kiếm (BR-SEARCH-009): câu lệnh card quét mọi card
còn sống bằng `instr`. `EXPLAIN QUERY PLAN` và thời gian đo trên khoảng 10.000 và 50.000
card nằm ở D11 của
[spec gói 5](../../superpowers/specs/2026-09-25-library-search-backend-design.md).
```

In `docs/features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md`:

Replace

```markdown
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-009, BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-003, BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-006, BR-SEARCH-007, BR-SEARCH-008, BR-SEARCH-009, BR-TAG-001]
code: []
---
```

with

```markdown
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-DECK-009, BR-SEARCH-001, BR-SEARCH-002, BR-SEARCH-003, BR-SEARCH-004, BR-SEARCH-005, BR-SEARCH-006, BR-SEARCH-007, BR-SEARCH-008, BR-SEARCH-009, BR-TAG-001]
code: [lib/features/search/domain/usecases/search_library_use_case.dart]
---
```

In `docs/shared/ui/screen-handoff/01-deck-list.md`:

Replace

```markdown
| Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
| Root search hint "Search decks, cards, tags" | "Search decks" | Spec A11 (waits for BE-A8) |
| No reorder entry at the root | Reorder in the root deck's action sheet | Library spec D7 |
```

with

```markdown
| Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
| Root search hint "Search decks, cards, tags" | "Search decks" | Spec A11 (waits for FE-A10) |
| No reorder entry at the root | Reorder in the root deck's action sheet | Library spec D7 |
```

In `docs/shared/ui/screen-handoff/04-library-search.md`:

Replace

```markdown

`/decks/search`. UC-SEARCH-001, decks only until BE-A8.

```

with

```markdown

`/decks/search`. UC-SEARCH-001, decks only until FE-A10 moves the screen to
`SearchLibraryUseCase` (the backend, BE-A8, is done).

```

Replace

```markdown
|---|---|---|
| Cards group, tag names on card rows | absent | BE-A8 |
| "Load more results" | absent | BE-A8 (BR-SEARCH-007) |
| Hint rows "a card term or meaning", "a tag name" | absent | BE-A8 |
| Footer "Decks first, then cards · case-insensitive, accents matter" | absent | BE-A8 |

A search hint must not promise a match the backend cannot make, so these are absent
rather than disabled.
```

with

```markdown
|---|---|---|
| Cards group, tag names on card rows | absent | FE-A10 |
| "Load more results" | absent | FE-A10 (BR-SEARCH-007) |
| Hint rows "a card term or meaning", "a tag name" | absent | FE-A10 |
| Footer "Decks first, then cards · case-insensitive, accents matter" | absent | FE-A10 |

A search hint must not promise a match the screen cannot make, so these are absent
rather than disabled.
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-A7 | Progress, 2 use case (UC-PROGRESS-001, UC-PROGRESS-002): tổng quan (Today tách Learning/Reviewing, bảy ngày, streak) và tiến độ theo deck ở cấp thư viện và cấp deck (bốn số cho 7 và 30 ngày từ một lần đọc, tổng đọc thẳng từ câu lệnh); ngày chia theo UTC offset của lần đọc; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | L | [spec](superpowers/specs/2026-09-25-progress-backend-design.md) và [plan](superpowers/plans/2026-09-25-progress-backend.md) gói 4; test trong `test/features/progress/` | FE-A9 dựng màn 22 trên hai use case này |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

with

```markdown
| BE-A7 | Progress, 2 use case (UC-PROGRESS-001, UC-PROGRESS-002): tổng quan (Today tách Learning/Reviewing, bảy ngày, streak) và tiến độ theo deck ở cấp thư viện và cấp deck (bốn số cho 7 và 30 ngày từ một lần đọc, tổng đọc thẳng từ câu lệnh); ngày chia theo UTC offset của lần đọc; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | L | [spec](superpowers/specs/2026-09-25-progress-backend-design.md) và [plan](superpowers/plans/2026-09-25-progress-backend.md) gói 4; test trong `test/features/progress/` | FE-A9 dựng màn 22 trên hai use case này |
| BE-A8 | Tìm kiếm toàn thư viện, 1 use case (UC-SEARCH-001): tên deck, hai mặt card, tên tag; tên deck fold trong Dart từ một lần đọc cây deck, card khớp trong một câu lệnh (bậc khớp bằng `=` và `instr`, tag qua subquery tương quan, một kết quả mỗi card); deck trước card sau, trang 50 kết quả theo keyset với `through` và `nextThrough`; truy vấn rỗng không chạy câu lệnh nào; đọc lại sau mỗi lần ghi, không ghi gì | xong | BE-03, BE-04, BE-05 | M | [spec](superpowers/specs/2026-09-25-library-search-backend-design.md) và [plan](superpowers/plans/2026-09-25-library-search-backend.md) gói 5; test trong `test/features/search/` | FE-A10 dựng màn 04 trên use case này, rồi bỏ `SearchDecksUseCase` |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

Replace

```markdown

| ID | Kết quả | Trạng thái | Phụ thuộc | Cỡ | Bằng chứng | Việc tiếp theo |
|---|---|---|---|---|---|---|
| BE-A8 | Tìm kiếm toàn thư viện: tên deck, hai mặt card, tên tag (UC-SEARCH-001; BR-SEARCH-001…BR-SEARCH-009) | chưa bắt đầu | BE-03, BE-04, BE-05 | M | ADR-009, quyết định 2; UC chưa có code | Làm được ngay, song song với nhóm study |

```

with

```markdown

Không còn hạng mục nào: BE-A8, hạng mục cuối, xong trong gói 5 và chuyển lên mục
"Đã xong".

```

Replace

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 15/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  7 UC còn lại chưa có code.

```

with

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A8** (gói 5, [spec](superpowers/specs/2026-09-25-library-search-backend-design.md),
  [plan](superpowers/plans/2026-09-25-library-search-backend.md)): gate năm lệnh xanh
  sau mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 16/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  6 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 4 (BE-A7).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 5 (BE-A8).

```

Replace

```markdown
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
| BE-A8 | Tên deck chưa có cột folded: fold trong Dart như giai đoạn 2, hay thêm cột (kéo theo migration và cần BE-D1) | Cách truy vấn và hiệu năng tìm kiếm | Quyết trong spec của BE-A8 |
| BE-B5 | Cần một dependency thông báo cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5, kèm lý do và cách rollback |
```

with

```markdown
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
| BE-B5 | Cần một dependency thông báo cục bộ | Thêm package vào dự án | Quyết trong spec của BE-B5, kèm lý do và cách rollback |
```

Replace

```markdown

1. Gói 5: BE-A8. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
```

with

```markdown

1. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
```

Replace

```markdown
  về mastery chuyển từ BE-A7 sang danh sách deck, nơi nó thuộc về.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  về mastery chuyển từ BE-A7 sang danh sách deck, nơi nó thuộc về.
- **Cập nhật ngày 2026-09-25:** BE-A8 xong trong gói 5, hạng mục cuối của nhóm V8.0.
  Điểm chặn về cột folded của tên deck đóng theo D3 của spec gói 5: tên deck fold
  trong Dart, không thêm cột, không migration.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | chưa bắt đầu | BE-A7 | L | Tab Tiến độ đang là placeholder; nội dung theo `navigation.md`; [kịch bản IT](features/progress/it-scenarios.md) | Cần thiết kế màn hình |
| FE-A10 | Tìm kiếm toàn thư viện từ header của Thư viện, ở mọi cấp (UC-SEARCH-001) | chưa bắt đầu | BE-A8, FE-A1 | M | [README search](features/search/README.md) | Sau BE-A8 |
| FE-A11 | Căn Thư viện theo screen handoff V3 (artifact "MemoX — Mobile UI Kit v3"): màn 01, 02, 04, 07; 5 phase A–E | xong | FE-A1, FE-A2, BE-A2 | L | [spec](superpowers/specs/2026-09-24-library-artifact-alignment-design.md); phase A (#32), B (#34), C (#38), D (#42), E (#46, #49) | — |
```

with

```markdown
| FE-A9 | Tab Tiến độ và drill-down theo deck (UC-PROGRESS-001, UC-PROGRESS-002) | chưa bắt đầu | BE-A7 | L | Tab Tiến độ đang là placeholder; nội dung theo `navigation.md`; [kịch bản IT](features/progress/it-scenarios.md) | Cần thiết kế màn hình |
| FE-A10 | Tìm kiếm toàn thư viện từ header của Thư viện, ở mọi cấp (UC-SEARCH-001) | chưa bắt đầu | BE-A8, FE-A1 | M | BE-A8 xong; [README search](features/search/README.md), hợp đồng cho UI ở §8 của [spec gói 5](superpowers/specs/2026-09-25-library-search-backend-design.md) | Dựng màn 04 trên `SearchLibraryUseCase`, rồi bỏ `SearchDecksUseCase` (spec gói 5, D1) |
| FE-A11 | Căn Thư viện theo screen handoff V3 (artifact "MemoX — Mobile UI Kit v3"): màn 01, 02, 04, 07; 5 phase A–E | xong | FE-A1, FE-A2, BE-A2 | L | [spec](superpowers/specs/2026-09-24-library-artifact-alignment-design.md); phase A (#32), B (#34), C (#38), D (#42), E (#46, #49) | — |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/search/domain/search_library_use_case_test.dart
```

Expected: `+3: All tests passed!`

- [ ] **Step 6: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1436: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 7: Commit**

```bash
git add docs/_generated \
  docs/features/search/README.md \
  docs/features/search/data.md \
  docs/features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/shared/ui/screen-handoff/04-library-search.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  lib/features/search/domain/usecases/search_library_use_case.dart \
  test/features/search/domain/search_library_use_case_test.dart
git commit -F - <<'EOF'
feat(search): the library search use case; a blank term reads nothing

SearchLibraryUseCase folds the term and watches the search through the
given cursor; a term that folds to empty is LibrarySearchIdle and sends no
statement (BR-SEARCH-002, BR-SEARCH-003). UC-SEARCH-001's code field names
it, a data document describes the reads, and the WBS has BE-A8 done:
FE-A10 builds screen 04 on it, then removes SearchDecksUseCase.
EOF
```

Append the session's attribution trailers to the message when you commit.


## Plan self-review

- **Spec coverage.** §5.1–§5.3 the types, the tiers and the order: Task 1.
  §5.4 the pages: Task 2 for the decks, Task 3 across both groups. §6.1 the deck
  tree, §6.4 when it reads and §6.6 the errors: Task 2. §6.2 the card
  statement, §6.3 one emission and §6.5 the mapping: Task 3, on Task 2's deck
  half. §7 the use case: Task 4. §8 the contract for the UI: Tasks 2–4 (the
  repository's provider, the use case). §9 tests: every line has its test in
  Tasks 1–4. §10 documents: Task 4, and `docs/_generated/` in every task.
  D12's import map: Task 1.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the
  replay compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test: four in Task 3, and the
  fourth also in Task 1.
