# Library search UI (FE-A10) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Screen 04 (`/decks/search`) searches deck names, card faces and tag names on `SearchLibraryUseCase`, with a 250 ms debounce and keyset "Load more", then the deck-side search (`SearchDecksUseCase` and below) is removed.

**Architecture:** The screen moves to `lib/features/search/presentation/` (the import map lets `search` read `deck`, never the reverse). One `@riverpod` Notifier, `SearchScreenController`, owns the debounce, the cursor and the subscription and exposes a sealed `SearchScreenState`; widgets only draw it. Two pure text helpers move to `lib/core/text/` so both features can use them.

**Tech Stack:** Flutter 3.47.5, Riverpod 3 codegen (`@riverpod`), Drift (in-memory in tests), go_router, `flutter gen-l10n`, `fake_async`.

**Spec:** [docs/superpowers/specs/2026-09-26-library-search-ui-design.md](../specs/2026-09-26-library-search-ui-design.md) (D1–D26). Contract: §8 of [the search backend spec](../specs/2026-09-25-library-search-backend-design.md). UC-SEARCH-001.

## Global Constraints

- Debounce 250 ms (BR-SEARCH-003); a term that folds to empty is idle at once and reads nothing.
- Page size is the backend's (`searchPageSize`, 50); the UI never counts rows itself for paging, it only hands `nextThrough` back.
- Presentation file names end in `_screen`, `_widget`, `_controller`, `_state`, `_page`, `_view` or `_provider` (guard `presentation_file_role_suffix`).
- No literal user-facing string in Dart: every string is an ARB key in `lib/l10n/app_en.arb` **and** `lib/l10n/app_vi.arb`.
- No `Icon(color:)`, no `TextStyle(...)`/`copyWith` in feature code: text uses `context.textStyles.<role>`, tiles use `MxIconTile` default tone (spec D19).
- No magic numbers in `lib/`: durations and counts are named constants.
- `presentation/` never imports `data/`; `search` may import `deck/domain/models/` only (`test/architecture/boundary_rules.dart`).
- Goldens are written on Linux only; validate the committed goldens on this checkout before updating any (Task 7).
- Code generation after any `@riverpod` change: `dart run build_runner build --delete-conflicting-outputs`; after any ARB change: `flutter gen-l10n`.
- Every commit ends with the repo's attribution lines.

## Review Focus

1. A term typed, cleared and retyped within 250 ms must read once, for the last term only, and never flash the old term's rows as the new term's results — pinned in Task 3 ("a changed term drops the old query's rows").
2. A card that matched only by a tag must emphasise nothing in its title and still show why it matched (chip + spoken reason) — pinned in Task 1 (`searchPairMatch` null) and Task 5 (tag-only row test).
3. A back-face match must emphasise inside the back, never across " · " — pinned in Task 1 (shift test and separator test).
4. A write elsewhere (rename a deck) while results show must update the path in place without a spinner — pinned in Task 3 (later emission) and Task 5 (rename test).
5. "Load more" tapped twice quickly must read once — pinned in Task 3 (loadMore while loading is ignored).

---

## File map

| File | Action | Responsibility |
|---|---|---|
| `lib/core/text/search_match.dart` | create | `searchFaceSeparator`, `searchMatchRange`, `searchPairMatch` |
| `lib/core/text/path_label.dart` | create | `pathSeparator`, `pathLabel` |
| `lib/features/deck/presentation/widgets/support/deck_search_match_widget.dart` | delete | moved to core |
| `lib/features/deck/presentation/widgets/support/deck_path_label_widget.dart` | delete | moved to core |
| `lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart` | modify | import `pathLabel` |
| `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` | modify | new `search*` keys, `deckSearch*` removed |
| `lib/features/search/presentation/providers/search_library_use_case_provider.dart` | create | wires the use case |
| `lib/features/search/presentation/states/search_screen_state.dart` | create | sealed screen state |
| `lib/features/search/presentation/controllers/search_screen_controller.dart` | create | debounce, cursor, subscription |
| `lib/features/search/presentation/widgets/items/search_deck_hit_row_widget.dart` | create | deck row (from `DeckSearchHitRowWidget`) |
| `lib/features/search/presentation/widgets/items/search_card_hit_row_widget.dart` | create | card row |
| `lib/features/search/presentation/widgets/items/search_load_more_widget.dart` | create | Load more strip |
| `lib/features/search/presentation/widgets/sections/search_hints_widget.dart` | create | empty-query body |
| `lib/features/search/presentation/widgets/sections/search_results_widget.dart` | create | results body |
| `lib/features/search/presentation/widgets/sections/search_body_widget.dart` | create | switch over the state |
| `lib/features/search/presentation/screens/library_search_screen.dart` | create | the screen |
| `lib/app/router/app_router.dart` | modify | route builder |
| `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart` | modify | trigger hint key |
| deck search code (Task 6 list) | delete | D16 |
| tests, goldens, companion | create/move | Tasks 1, 3, 5, 7 |
| docs (Task 8 list) | modify | D18 |

---

### Task 1: Text helpers move to core, with the pair match

**Files:**
- Create: `lib/core/text/search_match.dart`, `lib/core/text/path_label.dart`
- Create: `test/core/text/search_match_test.dart`, `test/core/text/path_label_test.dart`
- Delete: `lib/features/deck/presentation/widgets/support/deck_search_match_widget.dart`, `lib/features/deck/presentation/widgets/support/deck_path_label_widget.dart`, `test/features/deck/presentation/deck_search_match_test.dart`
- Modify: `lib/features/deck/presentation/widgets/overlays/deck_move_sheet_widget.dart`, `lib/features/deck/presentation/widgets/items/deck_search_hit_row_widget.dart`, `test/features/deck/presentation/deck_reorder_anchor_test.dart` (the `deckPathLabel` expectation at line 36)

**Interfaces:**
- Produces: `const String searchFaceSeparator = ' · ';` · `(int, int)? searchMatchRange(String text, String term)` · `(int, int)? searchPairMatch(String first, String second, String term)` · `const String pathSeparator = ' › ';` · `String pathLabel(Iterable<String> names)`.

- [ ] **Step 1: Write the failing tests**

`test/core/text/search_match_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/search_match.dart';

void main() {
  group('searchMatchRange', () {
    test('finds the term case-insensitively, as a range in the text', () {
      expect(searchMatchRange('Ăn uống', 'ĂN'), (0, 2));
      expect(searchMatchRange('Academic words', 'words'), (9, 14));
    });

    test('accents matter (BR-SEARCH-002)', () {
      expect(searchMatchRange('Học qua phim', 'hoc'), isNull);
    });

    test('a blank term marks nothing', () {
      expect(searchMatchRange('Korean', '  '), isNull);
    });

    test('the term is trimmed, the text is not', () {
      expect(searchMatchRange('  Korean', ' korean '), (2, 8));
    });
  });

  group('searchPairMatch (spec D20)', () {
    test('a front match keeps its own range', () {
      expect(searchPairMatch('học sinh', 'student', 'sinh'), (4, 8));
    });

    test('a back match is shifted past the front and the separator', () {
      const front = '학생';
      final offset = front.length + searchFaceSeparator.length;
      expect(
        searchPairMatch(front, 'học sinh', 'học'),
        (offset, offset + 3),
      );
    });

    test('the front wins when both faces hold the term', () {
      expect(searchPairMatch('học', 'học tập', 'học'), (0, 3));
    });

    test('neither face: a tag-only hit emphasises nothing', () {
      expect(searchPairMatch('homework', 'bài tập', 'học'), isNull);
    });

    test('the separator itself is never matched', () {
      expect(searchPairMatch('a', 'b', '·'), isNull);
      expect(searchPairMatch('a', 'b', 'a · b'), isNull);
    });
  });
}
```

`test/core/text/path_label_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/path_label.dart';

void main() {
  test('a path reads root first, joined by the separator', () {
    expect(pathLabel(['Korean', 'Words']), 'Korean › Words');
    expect(pathLabel(const []), '');
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/core/text/`
Expected: FAIL, `search_match.dart` and `path_label.dart` do not exist.

- [ ] **Step 3: Write the helpers**

`lib/core/text/search_match.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';

/// Between a card's two faces when one line shows both (screen 04). Display
/// only: the search never matches it (spec D20).
const String searchFaceSeparator = ' · ';

/// Where [term] sits in [text] under the search's own folding
/// (BR-SEARCH-002), as a half-open range in [text]; null when it does not.
/// The text is lower-cased but not trimmed, so a range in it is the same
/// range in [text]. Where lower-casing changes a text's length (on the web
/// 'İ' becomes two code units), the text is left unmarked rather than
/// marked in the wrong place.
(int, int)? searchMatchRange(String text, String term) {
  final folded = foldText(term);
  if (folded.isEmpty) return null;
  final lowered = text.toLowerCase();
  if (lowered.length != text.length) return null;
  final start = lowered.indexOf(folded);
  if (start < 0) return null;
  return (start, start + folded.length);
}

/// The match in "[first][searchFaceSeparator][second]": [first]'s own
/// range, else [second]'s shifted past [first] and the separator; null when
/// neither face holds [term], as for a card found by a tag only. Each face
/// is searched alone, as the backend matches `front_folded` and
/// `back_folded` (spec D20).
(int, int)? searchPairMatch(String first, String second, String term) {
  final inFirst = searchMatchRange(first, term);
  if (inFirst != null) return inFirst;
  final inSecond = searchMatchRange(second, term);
  if (inSecond == null) return null;
  final offset = first.length + searchFaceSeparator.length;
  final (start, end) = inSecond;
  return (start + offset, end + offset);
}
```

`lib/core/text/path_label.dart`:

```dart
/// Between two decks of a path, as in "Korean › Words".
const String pathSeparator = ' › ';

/// A deck path read root first.
String pathLabel(Iterable<String> names) => names.join(pathSeparator);
```

- [ ] **Step 4: Move the deck callers and delete the old files**

In `deck_move_sheet_widget.dart` replace the import of `widgets/support/deck_path_label_widget.dart` with `package:memox/core/text/path_label.dart` and `deckPathLabel(` with `pathLabel(`. In `deck_search_hit_row_widget.dart` (deleted in Task 6, kept compiling until then) replace both support imports with `package:memox/core/text/path_label.dart` and `package:memox/core/text/search_match.dart`, `deckPathLabel(` with `pathLabel(` and `deckSearchMatch(` with `searchMatchRange(`. In `test/features/deck/presentation/deck_reorder_anchor_test.dart` replace the import and `deckPathLabel(` likewise.

```bash
git rm lib/features/deck/presentation/widgets/support/deck_search_match_widget.dart \
  lib/features/deck/presentation/widgets/support/deck_path_label_widget.dart \
  test/features/deck/presentation/deck_search_match_test.dart
grep -rn "deckPathLabel\|deckSearchMatch\|deckPathSeparator" lib test
```
Expected: the grep prints nothing.

- [ ] **Step 5: Run the tests and the analyzer**

Run: `flutter test test/core/text/ test/features/deck/ && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add -A lib/core/text test/core/text lib/features/deck test/features/deck
git commit -m "refactor(text): search match and path label move to core, with the pair match (FE-A10)"
```

---

### Task 2: Strings

**Files:**
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`

**Interfaces:**
- Produces (generated on `context.l10n`): `searchFieldHint`, `searchClear`, `searchHintCardTerm`, `searchHintCardExample`, `searchHintTagName`, `searchHintTagExample`, `searchCardsGroup`, `searchGroupCountMore(int count)`, `searchLoadMore`, `searchLoadMoreFailed`, `searchFooter`, `searchNoMatchesTitle(String term)`, `searchNoMatchesBody`, `searchCardRowLabel(String front, String back, String path)`, `searchCardRowTagLabel(String front, String back, String tag, String path)`; `searchAccentNote` changes text. `deckSearch*` keys stay until Task 6.

- [ ] **Step 1: Add the English keys** — next to the existing `search*` block in `app_en.arb` (after `"searchErrorBody"` and its `@` entry):

```json
  "searchFieldHint": "Search decks, cards, tags",
  "@searchFieldHint": {
    "description": "Screen handoff 04: hint of the library search field and of the Library root's search trigger (FE-A10, spec D15)."
  },
  "searchClear": "Clear search",
  "@searchClear": {
    "description": "Screen handoff 04: the search field's clear button, for screen readers."
  },
  "searchHintCardTerm": "a card term or meaning",
  "@searchHintCardTerm": {
    "description": "Screen handoff 04: hint row, what search finds on cards."
  },
  "searchHintCardExample": "학생, học sinh, homework",
  "@searchHintCardExample": {
    "description": "Screen handoff 04: examples under the card hint row. Sample vocabulary; keep as is in every language."
  },
  "searchHintTagName": "a tag name",
  "@searchHintTagName": {
    "description": "Screen handoff 04: hint row, what search finds on tags."
  },
  "searchHintTagExample": "verb, Học",
  "@searchHintTagExample": {
    "description": "Screen handoff 04: examples under the tag hint row. Sample tags; keep as is in every language."
  },
  "searchCardsGroup": "Cards",
  "@searchCardsGroup": {
    "description": "Screen handoff 04: the card group's header."
  },
  "searchGroupCountMore": "{count}+",
  "@searchGroupCountMore": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    },
    "description": "Screen handoff 04: a group's count while more results follow (spec D10)."
  },
  "searchLoadMore": "Load more results",
  "@searchLoadMore": {
    "description": "Screen handoff 04: reads the next page (BR-SEARCH-007)."
  },
  "searchLoadMoreFailed": "Couldn't load more results. What is shown is still correct.",
  "@searchLoadMoreFailed": {
    "description": "Screen handoff 04: the end of the list when the next page failed (UC-SEARCH-001 E2, spec D13)."
  },
  "searchFooter": "Decks first, then cards · case-insensitive, accents matter",
  "@searchFooter": {
    "description": "Screen handoff 04: the line under the results."
  },
  "searchNoMatchesTitle": "No matches for “{term}”",
  "@searchNoMatchesTitle": {
    "placeholders": {
      "term": {
        "type": "String"
      }
    },
    "description": "Screen handoff 04: no deck and no card holds the term."
  },
  "searchNoMatchesBody": "Accents matter — “hoc” does not find “học”. Search covers deck names, card terms and meanings, and tag names.",
  "@searchNoMatchesBody": {
    "description": "Screen handoff 04: under the no-results title (spec D14)."
  },
  "searchCardRowLabel": "{front}, {back}, in {path}",
  "@searchCardRowLabel": {
    "placeholders": {
      "front": {"type": "String"},
      "back": {"type": "String"},
      "path": {"type": "String"}
    },
    "description": "Screen handoff 04: what a screen reader says for a card result (spec D22)."
  },
  "searchCardRowTagLabel": "{front}, {back}, tag {tag}, in {path}",
  "@searchCardRowTagLabel": {
    "placeholders": {
      "front": {"type": "String"},
      "back": {"type": "String"},
      "tag": {"type": "String"},
      "path": {"type": "String"}
    },
    "description": "Screen handoff 04: a card result found by its tag only, for screen readers (spec D22)."
  },
```

Change `"searchAccentNote"` to `"Case does not matter, accents do: “hoc” will not find “học”. Examples, hints and pronunciation are not searched."`.

- [ ] **Step 2: Add the Vietnamese keys** — next to the `search*` block of `app_vi.arb`:

```json
  "searchFieldHint": "Tìm bộ thẻ, thẻ, nhãn",
  "searchClear": "Xoá nội dung tìm",
  "searchHintCardTerm": "một từ hoặc nghĩa của thẻ",
  "searchHintCardExample": "학생, học sinh, homework",
  "searchHintTagName": "tên một nhãn",
  "searchHintTagExample": "verb, Học",
  "searchCardsGroup": "Thẻ",
  "searchGroupCountMore": "{count}+",
  "searchLoadMore": "Xem thêm kết quả",
  "searchLoadMoreFailed": "Chưa tải thêm được kết quả. Những gì đang hiện vẫn đúng.",
  "searchFooter": "Bộ thẻ trước, thẻ sau · không phân biệt hoa thường, có phân biệt dấu",
  "searchNoMatchesTitle": "Không có kết quả cho “{term}”",
  "searchNoMatchesBody": "Dấu có ý nghĩa — “hoc” không tìm ra “học”. Tìm kiếm xét tên bộ thẻ, từ và nghĩa của thẻ, và tên nhãn.",
  "searchCardRowLabel": "{front}, {back}, trong {path}",
  "searchCardRowTagLabel": "{front}, {back}, nhãn {tag}, trong {path}",
```

Change `"searchAccentNote"` to `"Chữ hoa hay thường không quan trọng, dấu thì có: “hoc” không tìm ra “học”. Ví dụ, gợi ý và phát âm không được tìm."`.

- [ ] **Step 3: Generate and check**

Run: `flutter gen-l10n && flutter analyze && flutter test --exclude-tags golden test/l10n test/app`
Expected: generation succeeds, `No issues found!`, tests pass (`test/l10n` holds the locale checks).

- [ ] **Step 4: Commit**

```bash
git add lib/l10n
git commit -m "feat(l10n): library search strings for decks, cards and tags (FE-A10)"
```

---

### Task 3: Screen state and controller

**Files:**
- Create: `lib/features/search/presentation/providers/search_library_use_case_provider.dart`
- Create: `lib/features/search/presentation/states/search_screen_state.dart`
- Create: `lib/features/search/presentation/controllers/search_screen_controller.dart`
- Test: `test/features/search/presentation/search_screen_controller_test.dart`

**Interfaces:**
- Consumes: `SearchLibraryUseCase` (`call({required String term, SearchCursor? through}) → Stream<LibrarySearch>`), `searchRepositoryProvider` (`lib/features/search/di/search_repository_provider.dart`), `LibrarySearchIdle`, `LibrarySearchResults{decks, cards, nextThrough, hasResults}`, `SearchDeckHit`, `SearchCardHit`, `SearchCursor`.
- Produces: `searchLibraryUseCaseProvider`; `enum SearchMoreStatus { idle, loading, failed }`; `sealed class SearchScreenState` with `SearchScreenIdle()`, `SearchScreenLoading({required String term})`, `SearchScreenResults({required String term, required List<SearchDeckHit> decks, required List<SearchCardHit> cards, required bool hasMore, SearchMoreStatus more})` + `withMore(SearchMoreStatus)`, `SearchScreenNoResults({required String term})`, `SearchScreenFailed({required String term})`; `const Duration searchDebounce`; `searchScreenControllerProvider` with notifier methods `search(String term)`, `loadMore()`, `retry()`.

- [ ] **Step 1: Write the failing controller tests**

`test/features/search/presentation/search_screen_controller_test.dart`:

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';

// UC-SEARCH-001: debounce, pages, failures (spec D5–D8).

final class _Watch {
  _Watch(this.term, this.through) {
    controller = StreamController<LibrarySearchResults>(
      onCancel: () => isCancelled = true,
    );
  }

  final String term;
  final SearchCursor? through;
  late final StreamController<LibrarySearchResults> controller;
  var isCancelled = false;
}

/// Hands every watch a stream the test drives.
final class _FakeSearch implements SearchRepository {
  final watches = <_Watch>[];

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) {
    final watch = _Watch(foldedTerm, through);
    watches.add(watch);
    return watch.controller.stream;
  }
}

SearchCursor _cursor(SearchGroup group, String id) => SearchCursor(
  group: group,
  tier: SearchTier.exact,
  sortText: id,
  createdAt: DateTime.utc(2026, 9, 26),
  id: id,
);

SearchDeckHit _deck(String id) => SearchDeckHit(
  deckId: id,
  name: id,
  path: const [],
  contentType: DeckContentType.card,
  cursor: _cursor(SearchGroup.deck, id),
);

SearchCardHit _card(String id) => SearchCardHit(
  cardId: id,
  deckId: 'deck',
  front: id,
  back: 'back',
  deckPath: const [],
  matchedTag: null,
  cursor: _cursor(SearchGroup.card, id),
);

LibrarySearchResults _page({
  List<SearchDeckHit> decks = const [],
  List<SearchCardHit> cards = const [],
  SearchCursor? next,
}) => LibrarySearchResults(decks: decks, cards: cards, nextThrough: next);

const _failure = UnknownDatabaseFailure(cause: '/data/memox.sqlite');

/// Runs [body] in fake time over a container whose search is [_FakeSearch].
void _run(
  void Function(
    FakeAsync async,
    SearchScreenController controller,
    SearchScreenState Function() state,
    _FakeSearch search,
  )
  body,
) {
  fakeAsync((async) {
    final search = _FakeSearch();
    final container = ProviderContainer(
      overrides: [searchRepositoryProvider.overrideWithValue(search)],
    );
    final keepAlive = container.listen(
      searchScreenControllerProvider,
      (_, _) {},
    );
    body(
      async,
      container.read(searchScreenControllerProvider.notifier),
      () => container.read(searchScreenControllerProvider),
      search,
    );
    keepAlive.close();
    container.dispose();
    async.flushMicrotasks();
  });
}

void main() {
  test('it starts idle', () {
    _run((async, controller, state, search) {
      expect(state(), isA<SearchScreenIdle>());
    });
  });

  test('a term is read once, 250 ms after the last keystroke', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce - const Duration(milliseconds: 1));
      controller.search('kor');
      async.elapse(searchDebounce - const Duration(milliseconds: 1));
      expect(search.watches, isEmpty);

      async.elapse(const Duration(milliseconds: 1));

      expect(search.watches.map((watch) => watch.term), ['kor']);
      expect(search.watches.single.through, isNull);
      expect(state(), isA<SearchScreenLoading>());
      expect((state() as SearchScreenLoading).term, 'kor');
    });
  });

  test('a blank term is idle at once and cancels the pending read', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      controller.search('   ');

      expect(state(), isA<SearchScreenIdle>());
      expect(search.watches.single.isCancelled, isTrue);

      controller.search('kx');
      controller.search('');
      async.elapse(searchDebounce * 2);
      expect(search.watches, hasLength(1));
    });
  });

  test('rows are results; no rows is no results', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.single.controller.add(_page(decks: [_deck('a')]));
      async.flushMicrotasks();

      final results = state() as SearchScreenResults;
      expect(results.term, 'ko');
      expect(results.decks.map((hit) => hit.deckId), ['a']);
      expect(results.hasMore, isFalse);
      expect(results.more, SearchMoreStatus.idle);

      search.watches.single.controller.add(_page());
      async.flushMicrotasks();
      expect(state(), isA<SearchScreenNoResults>());
    });
  });

  test("a changed term drops the old query's rows", () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      controller.search('kx');
      async.elapse(searchDebounce);

      expect(search.watches.first.isCancelled, isTrue);
      search.watches.first.controller.add(_page(decks: [_deck('old')]));
      async.flushMicrotasks();
      expect(state(), isA<SearchScreenLoading>());
      expect((state() as SearchScreenLoading).term, 'kx');
    });
  });

  test('a later emission updates the rows in place (A3)', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      final watch = search.watches.single;
      watch.controller.add(_page(decks: [_deck('a')]));
      async.flushMicrotasks();
      watch.controller.add(_page(decks: [_deck('a'), _deck('b')]));
      async.flushMicrotasks();

      expect(
        (state() as SearchScreenResults).decks.map((hit) => hit.deckId),
        ['a', 'b'],
      );
      expect(search.watches, hasLength(1));
    });
  });

  test('load more keeps the rows while it reads, then shows the longer '
      'extent (A1)', () {
    _run((async, controller, state, search) {
      final next = _cursor(SearchGroup.card, 'c1');
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.first.controller.add(
        _page(cards: [_card('c1')], next: next),
      );
      async.flushMicrotasks();
      expect((state() as SearchScreenResults).hasMore, isTrue);

      controller.loadMore();
      controller.loadMore();

      final loading = state() as SearchScreenResults;
      expect(loading.more, SearchMoreStatus.loading);
      expect(loading.cards.map((hit) => hit.cardId), ['c1']);
      expect(search.watches, hasLength(2));
      expect(search.watches.last.through, same(next));
      expect(search.watches.first.isCancelled, isTrue);

      search.watches.last.controller.add(
        _page(cards: [_card('c1'), _card('c2')]),
      );
      async.flushMicrotasks();
      final longer = state() as SearchScreenResults;
      expect(longer.cards.map((hit) => hit.cardId), ['c1', 'c2']);
      expect(longer.more, SearchMoreStatus.idle);
      expect(longer.hasMore, isFalse);
    });
  });

  test('a load-more failure keeps the rows; retry reads the same cursor '
      '(E2)', () {
    _run((async, controller, state, search) {
      final next = _cursor(SearchGroup.card, 'c1');
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.first.controller.add(
        _page(cards: [_card('c1')], next: next),
      );
      async.flushMicrotasks();
      controller.loadMore();
      search.watches.last.controller.addError(_failure);
      async.flushMicrotasks();

      final failed = state() as SearchScreenResults;
      expect(failed.more, SearchMoreStatus.failed);
      expect(failed.cards.map((hit) => hit.cardId), ['c1']);

      controller.retry();

      expect((state() as SearchScreenResults).more, SearchMoreStatus.loading);
      expect(search.watches, hasLength(3));
      expect(search.watches.last.through, same(next));
    });
  });

  test('a first-page failure shows no rows; retry reads from the first page '
      '(E1)', () {
    _run((async, controller, state, search) {
      controller.search('ko');
      async.elapse(searchDebounce);
      search.watches.single.controller.addError(_failure);
      async.flushMicrotasks();

      expect(state(), isA<SearchScreenFailed>());
      expect((state() as SearchScreenFailed).term, 'ko');

      controller.retry();

      expect(state(), isA<SearchScreenLoading>());
      expect(search.watches, hasLength(2));
      expect(search.watches.last.through, isNull);
    });
  });

  test('leaving cancels the pending read and the watch', () {
    fakeAsync((async) {
      final search = _FakeSearch();
      final container = ProviderContainer(
        overrides: [searchRepositoryProvider.overrideWithValue(search)],
      );
      final keepAlive = container.listen(
        searchScreenControllerProvider,
        (_, _) {},
      );
      final controller = container.read(
        searchScreenControllerProvider.notifier,
      );
      controller.search('ko');
      async.elapse(searchDebounce);
      controller.search('kx');
      keepAlive.close();
      container.dispose();
      async.elapse(searchDebounce * 2);

      expect(search.watches, hasLength(1));
      expect(search.watches.single.isCancelled, isTrue);
    });
  });
}
```

- [ ] **Step 2: Run it to see it fail**

Run: `flutter test test/features/search/presentation/search_screen_controller_test.dart`
Expected: FAIL, the controller and state files do not exist.

- [ ] **Step 3: Write the provider, the state and the controller**

`lib/features/search/presentation/providers/search_library_use_case_provider.dart`:

```dart
import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/usecases/search_library_use_case.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_library_use_case_provider.g.dart';

@riverpod
SearchLibraryUseCase searchLibraryUseCase(Ref ref) =>
    SearchLibraryUseCase(ref.watch(searchRepositoryProvider));
```

`lib/features/search/presentation/states/search_screen_state.dart`:

```dart
import 'package:memox/features/search/domain/models/search_hit_model.dart';

/// Where "Load more" stands (UC-SEARCH-001 A1, E2).
enum SearchMoreStatus { idle, loading, failed }

/// What screen 04 draws (UC-SEARCH-001 "UI states", spec D4). Each [term]
/// is the typed term trimmed, as the headers quote it.
sealed class SearchScreenState {
  const SearchScreenState();
}

/// No term: the hints, and nothing read (BR-SEARCH-003).
final class SearchScreenIdle extends SearchScreenState {
  const SearchScreenIdle();
}

/// The first page of [term] is being read.
final class SearchScreenLoading extends SearchScreenState {
  const SearchScreenLoading({required this.term});

  final String term;
}

/// At least one deck or card holds [term], decks first (BR-SEARCH-005).
final class SearchScreenResults extends SearchScreenState {
  const SearchScreenResults({
    required this.term,
    required this.decks,
    required this.cards,
    required this.hasMore,
    this.more = SearchMoreStatus.idle,
  });

  final String term;
  final List<SearchDeckHit> decks;
  final List<SearchCardHit> cards;

  /// Another page follows the rows shown (BR-SEARCH-007).
  final bool hasMore;
  final SearchMoreStatus more;

  SearchScreenResults withMore(SearchMoreStatus more) => SearchScreenResults(
    term: term,
    decks: decks,
    cards: cards,
    hasMore: hasMore,
    more: more,
  );
}

/// Nothing holds [term].
final class SearchScreenNoResults extends SearchScreenState {
  const SearchScreenNoResults({required this.term});

  final String term;
}

/// The first page of [term] failed; no stale row is shown (E1).
final class SearchScreenFailed extends SearchScreenState {
  const SearchScreenFailed({required this.term});

  final String term;
}
```

`lib/features/search/presentation/controllers/search_screen_controller.dart`:

```dart
import 'dart:async';

import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/presentation/providers/search_library_use_case_provider.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_screen_controller.g.dart';

/// How long the field stays still before a term is read (BR-SEARCH-003).
const Duration searchDebounce = Duration(milliseconds: 250);

/// Screen 04's search (UC-SEARCH-001): the debounced term, the extent it
/// watches and the one subscription to it (spec D3–D8). Widgets only draw
/// its state.
@riverpod
class SearchScreenController extends _$SearchScreenController {
  Timer? _debounce;
  StreamSubscription<LibrarySearch>? _watch;
  var _term = '';

  /// The extent the current watch shows; null is the first page.
  SearchCursor? _through;

  /// Where one more page would end; null when nothing follows.
  SearchCursor? _nextThrough;

  @override
  SearchScreenState build() {
    ref.onDispose(_stop);
    return const SearchScreenIdle();
  }

  /// The field changed. A blank term is idle at once (A4); any other is
  /// read [searchDebounce] after the last change, from the first page.
  void search(String term) {
    _stop();
    _term = term;
    if (foldText(term).isEmpty) {
      state = const SearchScreenIdle();
      return;
    }
    _debounce = Timer(searchDebounce, () => _watchThrough(null));
  }

  /// One more page, keeping the rows until it arrives (A1).
  void loadMore() {
    final current = state;
    final next = _nextThrough;
    if (current is! SearchScreenResults || next == null) return;
    if (current.more == SearchMoreStatus.loading) return;
    state = current.withMore(SearchMoreStatus.loading);
    _watchThrough(next);
  }

  /// After a failure: the first page again (E1), or the same extent (E2).
  void retry() {
    switch (state) {
      case SearchScreenFailed():
        _watchThrough(null);
      case final SearchScreenResults current
          when current.more == SearchMoreStatus.failed:
        state = current.withMore(SearchMoreStatus.loading);
        _watchThrough(_through);
      case _:
        return;
    }
  }

  String get _shownTerm => _term.trim();

  void _watchThrough(SearchCursor? through) {
    unawaited(_watch?.cancel());
    _through = through;
    if (through == null) state = SearchScreenLoading(term: _shownTerm);
    _watch = ref
        .read(searchLibraryUseCaseProvider)(term: _term, through: through)
        .listen(_show, onError: _fail);
  }

  void _show(LibrarySearch search) {
    switch (search) {
      case LibrarySearchIdle():
        state = const SearchScreenIdle();
      case LibrarySearchResults(:final decks, :final cards, :final nextThrough):
        _nextThrough = nextThrough;
        state = search.hasResults
            ? SearchScreenResults(
                term: _shownTerm,
                decks: decks,
                cards: cards,
                hasMore: nextThrough != null,
              )
            : SearchScreenNoResults(term: _shownTerm);
    }
  }

  /// A failed first page shows no rows (E1); a failed later page keeps them
  /// and turns the end of the list into a retry (E2).
  void _fail(Object error, StackTrace stackTrace) {
    final current = state;
    if (_through != null && current is SearchScreenResults) {
      state = current.withMore(SearchMoreStatus.failed);
      return;
    }
    state = SearchScreenFailed(term: _shownTerm);
  }

  void _stop() {
    _debounce?.cancel();
    _debounce = null;
    unawaited(_watch?.cancel());
    _watch = null;
  }
}
```

- [ ] **Step 4: Generate and run**

Run: `dart run build_runner build --delete-conflicting-outputs && flutter test test/features/search/presentation/search_screen_controller_test.dart`
Expected: 10 tests PASS.

If the guard flags `_fail`'s unused parameters or the error-handling ruleset asks for the failure to be logged, follow the rule it names (the other controllers' `on Failure` handling in `card_history_controller.dart` is the pattern) and re-run.

- [ ] **Step 5: Analyze, check the boundaries, commit**

Run: `flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh && flutter test test/architecture`
Expected: clean.

```bash
git add lib/features/search/presentation test/features/search/presentation
git commit -m "feat(search): screen 04's controller — debounce, pages, failures (FE-A10)"
```

---

### Task 4: Result rows and the load-more strip

**Files:**
- Create: `lib/features/search/presentation/widgets/items/search_deck_hit_row_widget.dart`
- Create: `lib/features/search/presentation/widgets/items/search_card_hit_row_widget.dart`
- Create: `lib/features/search/presentation/widgets/items/search_load_more_widget.dart`

(Tested through the screen in Task 5, over the real database; the pure logic is in Task 1.)

**Interfaces:**
- Consumes: `SearchDeckHit`, `SearchCardHit`, `SearchMoreStatus`, `searchMatchRange`, `searchPairMatch`, `searchFaceSeparator`, `pathLabel`, Task 2 keys.
- Produces: `SearchDeckHitRowWidget({required SearchDeckHit hit, required String term, required VoidCallback onTap, required bool hasDivider})`; `SearchCardHitRowWidget({required SearchCardHit hit, required String term, required VoidCallback onTap, required bool hasDivider})`; `SearchLoadMoreWidget({required SearchMoreStatus status, required VoidCallback onLoadMore, required VoidCallback onRetry})`.

- [ ] **Step 1: The deck row** (the old `DeckSearchHitRowWidget`, on `SearchDeckHit`)

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/text/path_label.dart';
import 'package:memox/core/text/search_match.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';

/// A deck found by the search (screen 04): its tile, its name with the match
/// marked, where it sits and what it holds (spec D11).
class SearchDeckHitRowWidget extends StatelessWidget {
  const SearchDeckHitRowWidget({
    super.key,
    required this.hit,
    required this.term,
    required this.onTap,
    required this.hasDivider,
  });

  final SearchDeckHit hit;
  final String term;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = hit.path.isEmpty
        ? l10n.navLibrary
        : pathLabel([for (final entry in hit.path) entry.name]);
    return MxListRow(
      title: hit.name,
      titleMatch: searchMatchRange(hit.name, term),
      subtitle: switch (hit.contentType) {
        DeckContentType.card => l10n.searchHoldsCards(path),
        DeckContentType.deck => l10n.searchHoldsDecks(path),
        DeckContentType.unset => l10n.searchHoldsNothing(path),
      },
      leading: MxIconTile(
        icon: switch (hit.contentType) {
          DeckContentType.card => AppIcons.cardDeck,
          DeckContentType.deck => AppIcons.library,
          DeckContentType.unset => AppIcons.folder,
        },
      ),
      hasChevron: true,
      onTap: onTap,
      hasDivider: hasDivider,
    );
  }
}
```

- [ ] **Step 2: The card row** (spec D12, D19–D22)

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/text/path_label.dart';
import 'package:memox/core/text/search_match.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/search/domain/models/search_hit_model.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

/// A card found by the search (screen 04): "front · back" with the match
/// marked in the face that holds it, the tag that found it when neither
/// face does, and its deck path (UC-SEARCH-001 step 5; spec D12, D20–D22).
class SearchCardHitRowWidget extends StatelessWidget {
  const SearchCardHitRowWidget({
    super.key,
    required this.hit,
    required this.term,
    required this.onTap,
    required this.hasDivider,
  });

  final SearchCardHit hit;
  final String term;
  final VoidCallback onTap;
  final bool hasDivider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = pathLabel([for (final entry in hit.deckPath) entry.name]);
    final tag = hit.matchedTag;
    // The title can clip a back-face match on a long front (spec D22), so
    // one node says the whole card and why it was found.
    return Semantics(
      label: tag == null
          ? l10n.searchCardRowLabel(hit.front, hit.back, path)
          : l10n.searchCardRowTagLabel(hit.front, hit.back, tag, path),
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: MxListRow(
        title: '${hit.front}$searchFaceSeparator${hit.back}',
        titleMatch: searchPairMatch(hit.front, hit.back, term),
        // Always the meta slot, so tag rows and plain rows are one style
        // and one height (spec D21).
        meta: Row(
          spacing: AppSpacing.micro,
          children: [
            if (tag != null) MxTagChip(label: tag, isDense: true),
            Flexible(
              child: Text(
                path,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.rowSubtitle,
              ),
            ),
          ],
        ),
        leading: const MxIconTile(icon: AppIcons.cardDeck),
        hasChevron: true,
        onTap: onTap,
        hasDivider: hasDivider,
      ),
    );
  }
}
```

Check `lib/core/theme/theme_context.dart` is where `context.textStyles` comes from (`grep -rn "get textStyles" lib/core/theme`); use that import.

- [ ] **Step 3: The load-more strip** (spec D13, D24)

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_button.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';

/// The end of the results while another page follows: "Load more results",
/// busy while it reads; after a failure, a retry in its place and the rows
/// above kept (UC-SEARCH-001 A1, E2).
class SearchLoadMoreWidget extends StatelessWidget {
  const SearchLoadMoreWidget({
    super.key,
    required this.status,
    required this.onLoadMore,
    required this.onRetry,
  });

  final SearchMoreStatus status;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (status == SearchMoreStatus.failed) {
      return MxInlineBanner(
        tone: MxBannerTone.danger,
        message: l10n.searchLoadMoreFailed,
        actions: [
          MxButton(
            label: l10n.commonRetry,
            onPressed: onRetry,
            tone: MxButtonTone.outline,
            size: MxButtonSize.small,
          ),
        ],
      );
    }
    return MxButton(
      label: l10n.searchLoadMore,
      onPressed: onLoadMore,
      tone: MxButtonTone.secondary,
      isBlock: true,
      isLoading: status == SearchMoreStatus.loading,
    );
  }
}
```

Check how other banners pass actions (`grep -rn "MxInlineBanner(" lib/features`); if the codebase uses another tone/size for a banner action, use that.

- [ ] **Step 4: Analyze and commit**

Run: `flutter analyze`
Expected: `No issues found!`

```bash
git add lib/features/search/presentation/widgets/items
git commit -m "feat(search): deck and card result rows, the load-more strip (FE-A10)"
```

---

### Task 5: The screen, its sections and its route

**Files:**
- Create: `lib/features/search/presentation/widgets/sections/search_hints_widget.dart`
- Create: `lib/features/search/presentation/widgets/sections/search_results_widget.dart`
- Create: `lib/features/search/presentation/widgets/sections/search_body_widget.dart`
- Create: `lib/features/search/presentation/screens/library_search_screen.dart`
- Modify: `lib/app/router/app_router.dart` (search route builder; imports)
- Modify: `lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart:88` (`l10n.deckSearchHint` → `l10n.searchFieldHint`)
- Test: `test/features/search/presentation/library_search_screen_test.dart`

**Interfaces:**
- Consumes: Task 3 (`searchScreenControllerProvider`, states), Task 4 widgets.
- Produces: `LibrarySearchScreen({required ValueChanged<String> onOpenDeck, required ValueChanged<String> onOpenCard})`.

- [ ] **Step 1: Write the failing screen tests**

`test/features/search/presentation/library_search_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/search/presentation/widgets/items/search_card_hit_row_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/search_deck_hit_row_widget.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_inline_banner.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';
import 'package:memox/shared/widgets/mx_tag_chip.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/library_harness.dart';

// UC-SEARCH-001 on screen 04; IT-DISC-006, IT-DISC-007 in the whole-library
// sense (spec D17).

final _en = lookupAppLocalizations(const Locale('en'));

LibrarySearchScreen _screen({
  ValueChanged<String>? onOpenDeck,
  ValueChanged<String>? onOpenCard,
}) => LibrarySearchScreen(
  onOpenDeck: onOpenDeck ?? (_) {},
  onOpenCard: onOpenCard ?? (_) {},
);

/// Types [text] and lets the debounce pass and the read emit.
Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(searchDebounce);
  await tester.pump();
  await tester.pump();
}

/// Fails every read from [failFrom] on (0 = the first page), else answers
/// as [_inner] does.
final class _FailingSearch implements SearchRepository {
  _FailingSearch(this._inner, {this.failLaterPagesOnly = false});

  final SearchRepository _inner;
  final bool failLaterPagesOnly;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) {
    if (!failLaterPagesOnly || through != null) {
      return Stream.error(
        const UnknownDatabaseFailure(cause: '/data/memox.sqlite'),
      );
    }
    return _inner.watchSearch(foldedTerm: foldedTerm, through: through);
  }
}

void main() {
  libraryTest('the field sits in the app bar and takes focus', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen());
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(MxAppBar),
        matching: find.byType(MxSearchField),
      ),
      findsOneWidget,
    );
    expect(find.text(_en.searchFieldHint), findsOneWidget);
    expect(tester.testTextInput.hasAnyClients, isTrue);
  });

  libraryTest('before a term it says what search finds (step 2)', (
    tester,
    env,
  ) async {
    await pumpLibraryScreen(tester, env, _screen());

    expect(find.text(_en.searchFinds.toUpperCase()), findsOneWidget);
    expect(find.text(_en.searchHintDeckName), findsOneWidget);
    expect(find.text(_en.searchHintCardTerm), findsOneWidget);
    expect(find.text(_en.searchHintTagName), findsOneWidget);
    expect(find.text(_en.searchAccentNote), findsOneWidget);
  });

  libraryTest('decks first, then cards, each group counted (step 4)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean học');
    final lesson = await env.decks.sub(korean.id, 'Lesson');
    await insertCard(env.db, id: 'c', deckId: lesson.id, front: 'học sinh');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    expect(
      find.text(_en.searchResultsFor('học').toUpperCase()),
      findsOneWidget,
    );
    final decks = find.text(_en.searchDecksGroup.toUpperCase());
    final cards = find.text(_en.searchCardsGroup.toUpperCase());
    expect(decks, findsOneWidget);
    expect(cards, findsOneWidget);
    expect(
      tester.getTopLeft(decks).dy,
      lessThan(tester.getTopLeft(cards).dy),
    );
    expect(find.widgetWithText(MxBadge, '1'), findsNWidgets(2));
    expect(find.byType(SearchDeckHitRowWidget), findsOneWidget);
    expect(find.byType(SearchCardHitRowWidget), findsOneWidget);
    expect(find.text(_en.searchFooter), findsOneWidget);
    expect(find.text(_en.searchLoadMore), findsNothing);
  });

  libraryTest('a group with no row draws no header (A2)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c', deckId: korean.id, front: 'học sinh');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    expect(find.text(_en.searchDecksGroup.toUpperCase()), findsNothing);
    expect(find.text(_en.searchCardsGroup.toUpperCase()), findsOneWidget);
  });

  libraryTest('a back-face match marks the back; a tag-only match marks '
      'nothing and shows the tag (step 5, spec D20)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(
      env.db,
      id: 'back',
      deckId: korean.id,
      front: '학생',
      back: 'học sinh',
    );
    await insertCard(
      env.db,
      id: 'tagged',
      deckId: korean.id,
      front: 'homework',
      back: 'bài tập',
    );
    await TagRepositoryImpl(
      env.db,
    ).attachByName(cardIds: {'tagged'}, name: 'Học');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    final rows = tester
        .widgetList<MxListRow>(
          find.descendant(
            of: find.byType(SearchCardHitRowWidget),
            matching: find.byType(MxListRow),
          ),
        )
        .toList();
    final back = rows.singleWhere((row) => row.title.startsWith('학생'));
    final tagged = rows.singleWhere((row) => row.title.startsWith('homework'));
    final offset = '학생 · '.length;
    expect(back.titleMatch, (offset, offset + 3));
    expect(tagged.titleMatch, isNull);
    expect(find.widgetWithText(MxTagChip, 'Học'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        _en.searchCardRowTagLabel('homework', 'bài tập', 'Học', 'Korean'),
      ),
      findsOneWidget,
    );
  });

  libraryTest('two decks of one name tell apart by path, and a tap opens the '
      'one chosen (IT-DISC-006)', (tester, env) async {
    final english = await env.decks.root('English');
    final vocab = await env.decks.sub(english.id, 'Vocabulary');
    final academic = await env.decks.sub(vocab.id, 'Academic words');
    final korean = await env.decks.root('Korean');
    await env.decks.sub(korean.id, 'Academic words');
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenDeck: (id) => opened = id),
    );
    await _search(tester, 'academic');

    expect(
      find.text(_en.searchHoldsNothing('English › Vocabulary')),
      findsOneWidget,
    );
    expect(find.text(_en.searchHoldsNothing('Korean')), findsOneWidget);
    await tester.tap(find.text(_en.searchHoldsNothing('English › Vocabulary')));
    expect(opened, academic.id);
  });

  libraryTest('no match names what is searched; clearing returns to the '
      'hints (IT-DISC-007, A4)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'zzz');

    expect(find.byType(MxEmptyState), findsOneWidget);
    expect(find.text(_en.searchNoMatchesTitle('zzz')), findsOneWidget);
    expect(find.text(_en.searchNoMatchesBody), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(_en.searchClear));
    await tester.pump();

    expect(find.byType(MxEmptyState), findsNothing);
    expect(find.text(_en.searchFinds.toUpperCase()), findsOneWidget);
  });

  libraryTest('a card row opens the card (step 6)', (tester, env) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c', deckId: korean.id, front: 'học sinh');
    String? opened;
    await pumpLibraryScreen(
      tester,
      env,
      _screen(onOpenCard: (id) => opened = id),
    );
    await _search(tester, 'học');
    await tester.tap(find.byType(SearchCardHitRowWidget));

    expect(opened, 'c');
  });

  libraryTest('a rename elsewhere updates the path in place (A3)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    await insertCard(env.db, id: 'c', deckId: korean.id, front: 'học sinh');
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');
    expect(find.text('Korean'), findsWidgets);

    await env.decks.renameDeck(deckId: korean.id, name: 'Tiếng Hàn');
    await tester.pump();
    await tester.pump();

    expect(find.text('Tiếng Hàn'), findsOneWidget);
  });

  libraryTest('51 hits: the count says more, Load more reads the rest (A1)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    for (var i = 0; i < 51; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: korean.id,
        front: 'học ${i.toString().padLeft(2, '0')}',
      );
    }
    await pumpLibraryScreen(tester, env, _screen());
    await _search(tester, 'học');

    expect(find.widgetWithText(MxBadge, '50+'), findsOneWidget);
    await tester.scrollUntilVisible(find.text(_en.searchLoadMore), 400);
    await tester.tap(find.text(_en.searchLoadMore));
    await tester.pump();
    await tester.pump();

    expect(find.widgetWithText(MxBadge, '51'), findsOneWidget);
    expect(find.text(_en.searchLoadMore), findsNothing);
  });

  libraryTest('a failed first page is the error state; retry reads again '
      '(E1)', (tester, env) async {
    await env.decks.root('Korean');
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        searchRepositoryProvider.overrideWithValue(
          _FailingSearch(_inner(env)),
        ),
      ],
    );
    await _search(tester, 'kor');

    expect(find.byType(MxErrorState), findsOneWidget);
    expect(find.byType(SearchDeckHitRowWidget), findsNothing);
  });

  libraryTest('a failed later page keeps the rows and offers a retry (E2)', (
    tester,
    env,
  ) async {
    final korean = await env.decks.root('Korean');
    for (var i = 0; i < 51; i++) {
      await insertCard(
        env.db,
        id: 'c${i.toString().padLeft(2, '0')}',
        deckId: korean.id,
        front: 'học ${i.toString().padLeft(2, '0')}',
      );
    }
    await pumpLibraryScreen(
      tester,
      env,
      _screen(),
      overrides: [
        searchRepositoryProvider.overrideWithValue(
          _FailingSearch(_inner(env), failLaterPagesOnly: true),
        ),
      ],
    );
    await _search(tester, 'học');
    await tester.scrollUntilVisible(find.text(_en.searchLoadMore), 400);
    await tester.tap(find.text(_en.searchLoadMore));
    await tester.pump();
    await tester.pump();

    expect(find.byType(MxInlineBanner), findsOneWidget);
    expect(find.text(_en.searchLoadMoreFailed), findsOneWidget);
    expect(find.byType(SearchCardHitRowWidget), findsWidgets);
  });
}
```

Add at the bottom of the file the helper the failure tests use, the real repository over the test database:

```dart
SearchRepository _inner(LibraryEnv env) => SearchRepositoryImpl(env.db);
```

with the import `package:memox/features/search/data/repositories/search_repository_impl.dart` (a test may import `data/`). Before running, check `DeckRepository.renameDeck`'s parameters (`lib/features/deck/domain/repositories/deck_repository.dart:29`) and match the call. `TagRepositoryImpl.attachByName` is used the same way in `test/features/search/data/search_cards_test.dart:52`.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/features/search/presentation/library_search_screen_test.dart`
Expected: FAIL, `library_search_screen.dart` does not exist.

- [ ] **Step 3: The hints section** (spec D9, D19, D26)

`lib/features/search/presentation/widgets/sections/search_hints_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_icon_tile.dart';
import 'package:memox/shared/widgets/mx_list_row.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// Before a term: what search finds, read-only (UC-SEARCH-001 step 2; spec
/// D9). No statement runs (BR-SEARCH-003).
class SearchHintsWidget extends StatelessWidget {
  const SearchHintsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MxListSectionHeader(label: l10n.searchFinds),
        MxCard(
          isFullBleed: true,
          child: Column(
            children: [
              MxListRow(
                title: l10n.searchHintDeckName,
                subtitle: l10n.searchHintDeckExample,
                leading: const MxIconTile(icon: AppIcons.library),
              ),
              MxListRow(
                title: l10n.searchHintCardTerm,
                subtitle: l10n.searchHintCardExample,
                leading: const MxIconTile(icon: AppIcons.cardDeck),
              ),
              MxListRow(
                title: l10n.searchHintTagName,
                subtitle: l10n.searchHintTagExample,
                leading: const MxIconTile(icon: AppIcons.tag),
                hasDivider: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.grouped),
        MxNote(text: l10n.searchAccentNote),
      ],
    );
  }
}
```

- [ ] **Step 4: The results section** (spec D10–D13)

`lib/features/search/presentation/widgets/sections/search_results_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:memox/features/search/presentation/widgets/items/search_card_hit_row_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/search_deck_hit_row_widget.dart';
import 'package:memox/features/search/presentation/widgets/items/search_load_more_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';

/// The hits of a term, decks first (BR-SEARCH-005). A group with no row has
/// no header (A2); only the last group drawn counts with "+" while a page
/// follows, since that page continues it (spec D10).
class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.onOpenDeck,
    required this.onOpenCard,
    required this.onLoadMore,
    required this.onRetry,
  });

  final SearchScreenResults results;
  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;
  final VoidCallback onLoadMore;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final decks = results.decks;
    final cards = results.cards;
    final isMoreOnCards = results.hasMore && cards.isNotEmpty;
    final isMoreOnDecks = results.hasMore && cards.isEmpty;
    String count(int rows, {required bool isMore}) =>
        isMore ? l10n.searchGroupCountMore(rows) : l10n.searchGroupCount(rows);
    return MxScreenScroll(
      children: [
        const SizedBox(height: AppSpacing.control),
        MxListSectionHeader(label: l10n.searchResultsFor(results.term)),
        if (decks.isNotEmpty) ...[
          MxListSectionHeader(
            label: l10n.searchDecksGroup,
            trailing: MxBadge(
              label: count(decks.length, isMore: isMoreOnDecks),
              tone: MxBadgeTone.neutral,
            ),
          ),
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in decks.indexed)
                  SearchDeckHitRowWidget(
                    hit: hit,
                    term: results.term,
                    onTap: () => onOpenDeck(hit.deckId),
                    hasDivider: index < decks.length - 1,
                  ),
              ],
            ),
          ),
        ],
        if (cards.isNotEmpty) ...[
          if (decks.isNotEmpty) const SizedBox(height: AppSpacing.grouped),
          MxListSectionHeader(
            label: l10n.searchCardsGroup,
            trailing: MxBadge(
              label: count(cards.length, isMore: isMoreOnCards),
              tone: MxBadgeTone.neutral,
            ),
          ),
          MxCard(
            isFullBleed: true,
            child: Column(
              children: [
                for (final (index, hit) in cards.indexed)
                  SearchCardHitRowWidget(
                    hit: hit,
                    term: results.term,
                    onTap: () => onOpenCard(hit.cardId),
                    hasDivider: index < cards.length - 1,
                  ),
              ],
            ),
          ),
        ],
        if (results.hasMore || results.more == SearchMoreStatus.failed) ...[
          const SizedBox(height: AppSpacing.grouped),
          SearchLoadMoreWidget(
            status: results.more,
            onLoadMore: onLoadMore,
            onRetry: onRetry,
          ),
        ],
        const SizedBox(height: AppSpacing.grouped),
        Text(
          l10n.searchFooter,
          textAlign: TextAlign.center,
          style: context.textStyles.footerCaption,
        ),
      ],
    );
  }
}
```

A long list is at most a few hundred rows (50 per page); `MxScreenScroll` is what the other Library bodies use. If the guard's performance rules ask for a lazy list above a row count, switch the two `Column`s to the pattern the card list uses and note it in the commit.

- [ ] **Step 5: The body switch and the screen** (spec D3, D14)

`lib/features/search/presentation/widgets/sections/search_body_widget.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/states/search_screen_state.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_hints_widget.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_results_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_card.dart';
import 'package:memox/shared/widgets/mx_empty_state.dart';
import 'package:memox/shared/widgets/mx_error_state.dart';
import 'package:memox/shared/widgets/mx_list_section_header.dart';
import 'package:memox/shared/widgets/mx_screen_scroll.dart';
import 'package:memox/shared/widgets/mx_skeleton.dart';

/// Screen 04's body: one widget per [SearchScreenState] (spec D4, D14).
class SearchBodyWidget extends ConsumerWidget {
  const SearchBodyWidget({
    super.key,
    required this.onOpenDeck,
    required this.onOpenCard,
  });

  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;

  /// Two groups of three, as the kit draws the first read (spec D14).
  static const int _skeletonGroups = 2;
  static const int _skeletonRows = 3;
  static const double _skeletonHeaderWidth = 72;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(searchScreenControllerProvider.notifier);
    return switch (ref.watch(searchScreenControllerProvider)) {
      SearchScreenIdle() => const SearchHintsWidget(),
      SearchScreenLoading(:final term) => MxScreenScroll(
        children: [
          const SizedBox(height: AppSpacing.control),
          MxListSectionHeader(label: l10n.searchSearching(term)),
          for (var group = 0; group < _skeletonGroups; group++) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.control),
              child: MxSkeleton(width: _skeletonHeaderWidth),
            ),
            const MxCard(
              isFullBleed: true,
              child: MxSkeletonList(rows: _skeletonRows),
            ),
          ],
        ],
      ),
      final SearchScreenResults results => SearchResultsWidget(
        results: results,
        onOpenDeck: onOpenDeck,
        onOpenCard: onOpenCard,
        onLoadMore: controller.loadMore,
        onRetry: controller.retry,
      ),
      SearchScreenNoResults(:final term) => MxScreenScroll(
        children: [
          MxEmptyState(
            icon: AppIcons.searchOff,
            title: l10n.searchNoMatchesTitle(term),
            body: l10n.searchNoMatchesBody,
            tone: MxEmptyStateTone.neutral,
            isCompact: true,
          ),
        ],
      ),
      SearchScreenFailed() => MxScreenScroll(
        children: [
          MxErrorState(
            title: l10n.searchErrorTitle,
            body: l10n.searchErrorBody,
            retryLabel: l10n.commonRetry,
            onRetry: controller.retry,
          ),
        ],
      ),
    };
  }
}
```

The guard rule `no_ref_read_in_build` may flag `ref.read(...notifier)` in `build`; if it does, read the notifier inside the callbacks instead (`onLoadMore: () => ref.read(searchScreenControllerProvider.notifier).loadMore()`), as `deck_search_results_widget.dart` did with `ref.invalidate` in its retry closure. `MxSkeletonList` inside the two cards gives each group its own pulse; if `MxSkeletonList` already draws a surface, drop the `MxCard` wrapper and compare with the kit's `loading-light.png` in Task 7.

`lib/features/search/presentation/screens/library_search_screen.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memox/core/theme/foundations/app_icons.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/widgets/sections/search_body_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_app_bar.dart';
import 'package:memox/shared/widgets/mx_app_shell.dart';
import 'package:memox/shared/widgets/mx_icon_button.dart';
import 'package:memox/shared/widgets/mx_search_field.dart';

/// Screen 04: the whole library — deck names, card faces, tag names — from
/// the Library header, at any level (UC-SEARCH-001). Navigation arrives as
/// callbacks.
class LibrarySearchScreen extends ConsumerStatefulWidget {
  const LibrarySearchScreen({
    super.key,
    required this.onOpenDeck,
    required this.onOpenCard,
  });

  final ValueChanged<String> onOpenDeck;
  final ValueChanged<String> onOpenCard;

  @override
  ConsumerState<LibrarySearchScreen> createState() =>
      _LibrarySearchScreenState();
}

class _LibrarySearchScreenState extends ConsumerState<LibrarySearchScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // The person came here to type (step 1).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxAppShell(
      appBar: MxAppBar(
        density: MxAppBarDensity.content,
        leading: MxIconButton(
          icon: AppIcons.back,
          semanticLabel: l10n.commonBack,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
        ),
        titleWidget: MxSearchField(
          controller: _query,
          focusNode: _focus,
          hintText: l10n.searchFieldHint,
          clearLabel: l10n.searchClear,
          onChanged: (term) =>
              ref.read(searchScreenControllerProvider.notifier).search(term),
        ),
      ),
      body: SearchBodyWidget(
        onOpenDeck: widget.onOpenDeck,
        onOpenCard: widget.onOpenCard,
      ),
    );
  }
}
```

- [ ] **Step 6: The route and the root trigger**

In `lib/app/router/app_router.dart` replace the `DeckSearchScreen` import with `package:memox/features/search/presentation/screens/library_search_screen.dart` and the search route builder with:

```dart
                GoRoute(
                  path: AppRoutes.searchChild,
                  builder: (context, state) => LibrarySearchScreen(
                    onOpenDeck: (id) => context.push(AppRoutes.deck(id)),
                    onOpenCard: (id) => context.push(AppRoutes.card(id)),
                  ),
                ),
```

In `deck_library_root_widget.dart:88` replace `l10n.deckSearchHint` with `l10n.searchFieldHint`.

- [ ] **Step 7: Run the screen tests and the router tests**

Run: `flutter test test/features/search/presentation/ test/app --exclude-tags golden`
Expected: PASS. If a router test asserts `DeckSearchScreen` on `/decks/search`, change it to `LibrarySearchScreen` (`grep -rn "DeckSearchScreen" test/app`).

- [ ] **Step 8: Analyze, guard, commit**

Run: `flutter analyze && bash .claude/skills/flutter-architecture/scripts/check_architecture.sh`
Expected: clean.

```bash
git add lib/features/search lib/app/router lib/features/deck/presentation/widgets/sections/deck_library_root_widget.dart test/features/search test/app
git commit -m "feat(search): screen 04 searches decks, cards and tags (FE-A10)"
```

---

### Task 6: The deck-side search goes

**Files:**
- Delete: `lib/features/deck/domain/usecases/search_decks_use_case.dart`, `lib/features/deck/presentation/providers/search_decks_use_case_provider.dart` (+ `.g.dart`), `lib/features/deck/presentation/providers/deck_search_provider.dart` (+ `.g.dart`), `lib/features/deck/presentation/screens/deck_search_screen.dart`, `lib/features/deck/presentation/widgets/sections/deck_search_results_widget.dart`, `lib/features/deck/presentation/widgets/items/deck_search_hit_row_widget.dart`, `lib/features/deck/domain/models/deck_search_hit_model.dart`, `test/features/deck/presentation/deck_search_screen_test.dart`, `test/visual_audit/screens/features/deck/screens/deck_search_screen_visual_audit_test.dart`
- Modify: `lib/features/deck/domain/repositories/deck_repository.dart` (drop `watchSearch` and its import), `lib/features/deck/data/repositories/deck_repository_impl.dart` (drop `watchSearch` and its import), `lib/features/deck/data/datasources/deck_dao.dart` (drop `watchSearchRows` if nothing else calls it), `test/features/deck/data/deck_navigation_read_test.dart` (drop the `watchSearch (IT-DISC-006)` group), `test/features/deck/domain/deck_navigation_use_cases_test.dart` (drop the `SearchDecksUseCase` tests), `test/features/deck/presentation/deck_screens_golden_test.dart` (drop the five `search…` golden tests and their imports), `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb` (drop `deckSearchHint`, `deckSearchClear`, `deckSearchEmptyTitle`, `deckSearchEmptyBody` and their `@` entries)
- Delete: `test/features/deck/presentation/goldens/library_search_*.png` (ten files)

- [ ] **Step 1: Delete and trim**

```bash
git rm lib/features/deck/domain/usecases/search_decks_use_case.dart \
  lib/features/deck/presentation/providers/search_decks_use_case_provider.dart \
  lib/features/deck/presentation/providers/deck_search_provider.dart \
  lib/features/deck/presentation/screens/deck_search_screen.dart \
  lib/features/deck/presentation/widgets/sections/deck_search_results_widget.dart \
  lib/features/deck/presentation/widgets/items/deck_search_hit_row_widget.dart \
  lib/features/deck/domain/models/deck_search_hit_model.dart \
  test/features/deck/presentation/deck_search_screen_test.dart \
  test/visual_audit/screens/features/deck/screens/deck_search_screen_visual_audit_test.dart \
  test/features/deck/presentation/goldens/library_search_*.png
git rm --ignore-unmatch lib/features/deck/presentation/providers/search_decks_use_case_provider.g.dart \
  lib/features/deck/presentation/providers/deck_search_provider.g.dart
```

Then remove, by hand, the members and tests listed under **Modify**. For `DeckDao.watchSearchRows`: `grep -rn "watchSearchRows" lib test` — delete it only when the repository's `watchSearch` was its one caller.

- [ ] **Step 2: Prove nothing refers to it**

```bash
grep -rn "SearchDecksUseCase\|searchDecksUseCase\|deckSearchProvider\|DeckSearchHit\|DeckSearchScreen\|DeckSearchResults\|watchSearchRows\|deckSearchHint\|deckSearchClear\|deckSearchEmpty" lib test
```
Expected: no output (generated files are regenerated next).

- [ ] **Step 3: Regenerate, analyze, test**

Run: `flutter gen-l10n && dart run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test --exclude-tags golden test/features/deck test/features/search test/app test/architecture test/visual_audit`
Expected: all pass; `screen_audit_coverage_test.dart` now fails only because `library_search_screen.dart` has no companion yet — that companion is Task 7's first step, so run Task 7 Step 1 before committing if you want a green tree at this commit, or commit both together.

- [ ] **Step 4: Commit** (together with Task 7 Step 1)

```bash
git add -A lib test
git commit -m "refactor(deck): the deck-only search goes; screen 04 is the search feature's (FE-A10)"
```

---

### Task 7: Visual audit companion and goldens

**Files:**
- Create: `test/visual_audit/screens/features/search/screens/library_search_screen_visual_audit_test.dart`
- Create: `test/features/search/presentation/library_search_golden_test.dart`
- Create: `test/features/search/presentation/goldens/*.png` (generated)
- Modify: goldens of the Library root whose trigger hint changed (regenerated)

- [ ] **Step 1: The companion**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';

import '../../../../../support/card_fixtures.dart';
import '../../../../../support/deck_fixtures.dart';
import '../../../../../support/library_harness.dart';
import '../../../../screen_audit.dart';

LibrarySearchScreen _screen() =>
    LibrarySearchScreen(onOpenDeck: (_) {}, onOpenCard: (_) {});

void main() {
  libraryTest('screen 04, a blank search', (tester, env) async {
    await env.decks.sub((await env.decks.root('Korean')).id, 'Words');
    await auditProductionScreen(
      tester,
      screen: LibrarySearchScreen,
      pump: (brightness, scale) => pumpLibraryScreen(
        tester,
        env,
        _screen(),
        brightness: brightness,
        textScale: scale,
      ),
    );
  });

  libraryTest('screen 04, decks and cards', (tester, env) async {
    final korean = await env.decks.root('Korean');
    final words = await env.decks.sub(korean.id, 'Words');
    await insertCard(env.db, id: 'c', deckId: words.id, front: 'word');
    await auditProductionScreen(
      tester,
      screen: LibrarySearchScreen,
      pump: (brightness, scale) async {
        await pumpLibraryScreen(
          tester,
          env,
          _screen(),
          brightness: brightness,
          textScale: scale,
        );
        await tester.enterText(find.byType(EditableText), 'or');
        await tester.pump(searchDebounce);
        await tester.pump();
      },
    );
  });
}
```

Run: `flutter test test/visual_audit`
Expected: PASS (the coverage test finds the companion at the mirrored path).

- [ ] **Step 2: Validate the golden renderer on this checkout**

Goldens are written on Linux only. Before writing any, the committed ones must pass here unchanged:

Run: `git stash -u && TZ=UTC flutter test --tags golden; git stash pop`
Expected: `All tests passed!` If anything fails on untouched content, stop: this machine does not render like CI. Use the container in `.claude/skills/flutter-testing/scripts/golden.Dockerfile` (its header has the build and validate commands) for Steps 3–4.

- [ ] **Step 3: The golden tests** (spec §3)

`test/features/search/presentation/library_search_golden_test.dart`:

```dart
@Tags(['golden'])
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/search/data/repositories/search_repository_impl.dart';
import 'package:memox/features/search/di/search_repository_provider.dart';
import 'package:memox/features/search/domain/models/library_search_model.dart';
import 'package:memox/features/search/domain/models/search_cursor_model.dart';
import 'package:memox/features/search/domain/repositories/search_repository.dart';
import 'package:memox/features/search/presentation/controllers/search_screen_controller.dart';
import 'package:memox/features/search/presentation/screens/library_search_screen.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/golden_harness.dart';
import '../../../support/library_harness.dart';

final _en = lookupAppLocalizations(const Locale('en'));

LibrarySearchScreen _screen() =>
    LibrarySearchScreen(onOpenDeck: (_) {}, onOpenCard: (_) {});

/// The kit's library, shortened: two decks and five cards on "học", one of
/// them found by a tag, and enough cards for a second page.
Future<void> _seed(LibraryEnv env, {int extraCards = 0}) async {
  final english = await env.decks.root('Tiếng Anh giao tiếp hằng ngày');
  await env.decks.sub(english.id, 'Học qua phim');
  final korean = await env.decks.root('한국어 TOPIK I');
  final nouns = await env.decks.sub(korean.id, 'Danh từ');
  await insertCard(env.db, id: 'hw', deckId: nouns.id, front: 'homework', back: 'bài tập về nhà');
  await TagRepositoryImpl(env.db).attachByName(cardIds: {'hw'}, name: 'Học');
  await insertCard(env.db, id: 'hs', deckId: nouns.id, front: '학생', back: 'học sinh');
  await insertCard(env.db, id: 'ht', deckId: nouns.id, front: '공부하다', back: 'học, học tập');
  await insertCard(env.db, id: 'dh', deckId: nouns.id, front: '대학교', back: 'trường đại học');
  for (var i = 0; i < extraCards; i++) {
    await insertCard(env.db, id: 'x$i', deckId: nouns.id, front: 'học $i');
  }
}

Future<void> _search(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(EditableText), text);
  await tester.pump(searchDebounce);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// A read that never answers: the loading state stays.
final class _PendingSearch implements SearchRepository {
  final _pending = StreamController<LibrarySearchResults>();

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => _pending.stream;
}

/// The first page from the database; every later page fails.
final class _LaterPagesFail implements SearchRepository {
  _LaterPagesFail(this._inner);

  final SearchRepository _inner;

  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => through == null
      ? _inner.watchSearch(foldedTerm: foldedTerm)
      : Stream.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
}

void main() {
  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    libraryTest('search, empty query, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(tester, 'goldens/search_empty_query_$theme.png');
      });
    });

    libraryTest('search, loading, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: [searchRepositoryProvider.overrideWithValue(_PendingSearch())],
        );
        await _search(tester, 'học');
        await expectBoundaryGolden(tester, 'goldens/search_loading_$theme.png');
      });
    });

    libraryTest('search, results, $theme', (tester, env) async {
      await _seed(env, extraCards: 50);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await _search(tester, 'học');
        await expectBoundaryGolden(tester, 'goldens/search_results_$theme.png');
      });
    });

    libraryTest('search, no results, $theme', (tester, env) async {
      await _seed(env);
      await withRealShadows(() async {
        await pumpLibraryGolden(tester, env, _screen(), brightness);
        await _search(tester, 'hoc');
        await expectBoundaryGolden(tester, 'goldens/search_no_results_$theme.png');
      });
    });

    libraryTest('search, error, $theme', (tester, env) async {
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: [
            searchRepositoryProvider.overrideWithValue(_FailFirst()),
          ],
        );
        await _search(tester, 'học');
        await expectBoundaryGolden(tester, 'goldens/search_error_$theme.png');
      });
    });

    libraryTest('search, load more failed, $theme', (tester, env) async {
      await _seed(env, extraCards: 50);
      await withRealShadows(() async {
        await pumpLibraryGolden(
          tester,
          env,
          _screen(),
          brightness,
          overrides: [
            searchRepositoryProvider.overrideWithValue(
              _LaterPagesFail(SearchRepositoryImpl(env.db)),
            ),
          ],
        );
        await _search(tester, 'học');
        await tester.scrollUntilVisible(find.text(_en.searchLoadMore), 400);
        await tester.tap(find.text(_en.searchLoadMore));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await expectBoundaryGolden(tester, 'goldens/search_load_more_failed_$theme.png');
      });
    });
  }
}

/// Fails every read, the first page included.
final class _FailFirst implements SearchRepository {
  @override
  Stream<LibrarySearchResults> watchSearch({
    required String foldedTerm,
    SearchCursor? through,
  }) => Stream.error(const UnknownDatabaseFailure(cause: '/data/memox.sqlite'));
}
```

Check `pumpLibraryGolden`'s signature in `test/support/golden_harness.dart` / `library_harness.dart` and match its parameters (the deck golden test calls it as `pumpLibraryGolden(tester, env, screen, brightness, overrides: [...])`). Format the file with `dart format`.

- [ ] **Step 4: Write and review the goldens**

Run: `TZ=UTC flutter test --tags golden --update-goldens test/features/search/presentation/library_search_golden_test.dart test/features/deck/presentation/deck_screens_golden_test.dart`
Then: `TZ=UTC flutter test --tags golden`
Expected: all pass. Open every new PNG (light and dark) next to the kit's `docs/shared/ui/screen-handoff/img/04-library-search/*` and check: two skeleton groups in cards (loading); Decks then Cards, "20+"-style count only on Cards, the tag chip on the homework row, no emphasis on it, Load more then the footer (results); the search-off glyph (no results); the danger strip with Retry (load more failed). `git status` must show only the new search goldens and the Library root goldens whose trigger hint changed (`library_*` root states); any other changed PNG is a regression to fix, not to commit.

- [ ] **Step 5: Commit**

```bash
git add test/visual_audit test/features/search test/features/deck/presentation/goldens
git commit -m "test(search): screen 04 goldens and visual audit (FE-A10)"
```

---

### Task 8: Documents

**Files:**
- Modify: `docs/shared/ui/screen-handoff/04-library-search.md`, `docs/shared/ui/screen-handoff/00-index.md` (row 04), `docs/features/search/usecases/UC-SEARCH-001-tim-kiem-toan-thu-vien.md` (`code:`), `docs/features/deck/usecases/UC-DECK-003-*.md` (`code:`), `docs/features/search/README.md` (`code:`), `docs/features/deck/it-scenarios.md` (a note under IT-DISC-006 and IT-DISC-007), `docs/superpowers/specs/2026-09-23-flutter-ui-base-design.md` §9 (new row, D25), `docs/wbs_FE.md` (FE-A10), `docs/_generated/` (regenerated)

- [ ] **Step 1: `04-library-search.md`**

- Header line: `/decks/search`. UC-SEARCH-001 on `SearchLibraryUseCase` (FE-A10).
- **Layout** table: app bar hint "Search decks, cards, tags"; empty query = "SEARCH FINDS" card with three read-only rows (deck, card, tag) and the two-sentence note; searching = header + two skeleton groups in cards; results = "RESULTS FOR …", Decks group, Cards group (row: card tile, "front · back" with the match in the face that holds it, meta line tag chip when found by tag + deck path), Load more, footer; no results = search-off glyph, title, body naming the four fields; error as before; load-more failed = danger inline banner with Retry.
- **States** table: V8 column "As drawn" for emptyQuery (minus the fill arrows), loading, results, noResults, error; add a row `loadMoreFailed` with "— (not in the kit)" images replaced by a link to the golden `test/features/search/presentation/goldens/search_load_more_failed_light.png` and "Extrapolated from `MxInlineBanner` (spec D24)".
- **Pending** table: removed (empty), with one line "Nothing pending since FE-A10."
- **Deviations**: delete "Searches decks, cards and tags / Decks only"; keep the match-mark, field-height, subtitle-style rows; extend the group-label row to "…and the SEARCH FINDS label: no glyph (spec D26)"; add rows: hint rows without fill arrows (D9, owner 2026-09-26); every tile tinted primary, no green card tiles or orange tag tiles (D19, green = mastery, amber = warning); tag chip `MxTagChip` neutral, no tag glyph (D19); one-line title may clip a back-face match, the semantics label says it (D22).

- [ ] **Step 2: the index row, the UCs, the README, the IT note, §9, the WBS**

- `00-index.md` row 04: `| 04 | Library search | 5 | FE-A1, FE-A10 | aligned | [04-library-search.md](04-library-search.md) |` (unchanged text, still `aligned`; the detail file now matches the whole kit).
- `UC-SEARCH-001` front matter: `code: [lib/features/search/domain/usecases/search_library_use_case.dart, lib/features/search/presentation]`.
- `UC-DECK-003` front matter: drop `lib/features/deck/domain/usecases/search_decks_use_case.dart` from `code:`.
- `docs/features/search/README.md` front matter: add `lib/features/search/presentation` to `code:`.
- `docs/features/deck/it-scenarios.md`, under the IT-DISC-006 and IT-DISC-007 headings, one line each: "> **V8:** search covers the whole library (ruling P2-L9, UI-base §9 row 74); tested on screen 04 in `test/features/search/presentation/library_search_screen_test.dart` (FE-A10 spec D17)."
- UI-base spec §9: a new row at the end of the table: "`MxListSectionHeader` and its trailing `MxBadge` are two TalkBack nodes ("Decks", then "2"); screens 04 and 07 | open | merge the header's semantics in the shared widget in a later debt batch (FE-A10 spec D25)". Match the table's existing column layout.
- `docs/wbs_FE.md`: FE-A10 → `xong`, Bằng chứng: spec and plan links, PR link placeholder filled after the PR opens (the PR number goes in the same PR's last commit), Việc tiếp theo `—`; drop FE-A10 from "Bước tiếp theo"; add an "Ngữ cảnh cập nhật" line for 2026-09-26 FE-A10.

- [ ] **Step 3: Regenerate and check the docs**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS — 0 error(s)`, and the warning count does not grow (57 before this plan).

- [ ] **Step 4: Commit**

```bash
git add docs
git commit -m "docs(search): screen 04 handoff, UCs, WBS for FE-A10"
```

---

### Final gate

- [ ] Run the full gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` — Expected: `✓ mechanical gates passed`.
- [ ] Run the goldens: `TZ=UTC flutter test --tags golden` — Expected: all pass.
- [ ] Impeccable after the build (CLAUDE.md step 5): critique and audit the new goldens against the kit, fix everything found in one batch, confirm once.
- [ ] Final whole-branch review, then open the PR (owner's go-ahead through the popup).
