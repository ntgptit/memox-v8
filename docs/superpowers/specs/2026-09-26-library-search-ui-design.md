# MemoX V8 — Library search UI (FE-A10)

Status: approved by the owner (2026-09-26).

## 1. Intent

Screen 04 (`/decks/search`) searches the whole library — deck names, both card faces
and tag names — on `SearchLibraryUseCase` (BE-A8), instead of deck names on
`SearchDecksUseCase`. Specified by UC-SEARCH-001, BR-SEARCH-001…BR-SEARCH-009, the UI
contract in §8 of the [search backend spec](2026-09-25-library-search-backend-design.md)
and screen 04 of the kit ([handoff](../../shared/ui/screen-handoff/04-library-search.md)).
Once the screen runs on the new use case, `SearchDecksUseCase` and the deck-side search
read go (search backend spec D1).

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | The screen moves to `lib/features/search/presentation/`: `screens/library_search_screen.dart` (`LibrarySearchScreen`, replacing `DeckSearchScreen`), `controllers/`, `states/`, `providers/`, `widgets/{sections,items}/`. The route stays `/decks/search`, a child of the Library branch (UC-SEARCH-001 step 1). | `boundary_rules.dart` lets `search` import `deck`, never the reverse; a `deck` screen cannot read the search use case. ADR-011 D2. |
| D2 | `deckSearchMatch` moves to `lib/core/text/search_match.dart` as `searchMatchRange`, and `deckPathLabel` with `deckPathSeparator` to `lib/core/text/path_label.dart` as `pathLabel` and `pathSeparator`. The deck move sheet imports the new home. | Both are pure text functions over `core/text/folded_text.dart`; a feature may not import another feature's `presentation/`. |
| D3 | One `@riverpod` autoDispose Notifier, `LibrarySearchController`, owns the typed term, the 250 ms debounce, the cursor `through`, the subscription to the use case and the rows shown. It exposes a sealed `LibrarySearchState`. Widgets only draw it and call `search(term)`, `loadMore()` and `retry()`. | Owner, 2026-09-26. E2 must keep rows across a change of cursor, which a stream family keyed by `(term, through)` loses. |
| D4 | `LibrarySearchState`: `Idle`; `Loading(term)`; `Results(term, decks, cards, hasMore, more)` with `more` ∈ {`idle`, `loading`, `failed`}; `NoResults(term)`; `Failed(term)`. | UC-SEARCH-001 "UI states"; §8 of the backend spec. |
| D5 | **Typing.** A term that folds to empty cancels the timer and the subscription and is `Idle` at once, with no read (A4, BR-SEARCH-003). Any other term restarts a 250 ms timer; when it fires, the controller drops the old subscription, sets `through = null`, shows `Loading` and watches the use case. | BR-SEARCH-003. Cancelling the old subscription is what drops results of a query that changed. |
| D6 | **Emissions.** `LibrarySearchResults` with rows is `Results` (`hasMore = nextThrough != null`); without rows it is `NoResults`. Every later emission of the same watch replaces the state, so a write elsewhere updates rows and paths in place (A3, BR-SEARCH-008). | BR-SEARCH-008. |
| D7 | **Load more.** Only in `Results` with `hasMore` and `more != loading`: `more = loading`, rows stay, the controller watches again with `through = nextThrough`, and the new watch's first emission replaces the rows (A1). A failure of that watch keeps the rows and sets `more = failed`; retry repeats the load (E2). | BR-SEARCH-007; UC-SEARCH-001 A1, E2. |
| D8 | **First-page failure.** A failure before any row of the current term is shown is `Failed(term)`, with no stale rows under it; retry watches the term again from the first page (E1). | UC-SEARCH-001 E1. |
| D9 | **Hints.** Before a term: the "SEARCH FINDS" card with three rows — deck name, card term or meaning, tag name — each with its examples, read-only, with no fill arrow; then the note "Case does not matter, accents do: “hoc” will not find “học”. Examples, hints and pronunciation are not searched." | Owner, 2026-09-26: a row with two examples cannot say which one a tap would fill. Deviation from the kit, recorded in the handoff. |
| D10 | **Results.** "RESULTS FOR “{term}”", then the Decks group, then the Cards group (BR-SEARCH-005); a group with no row has no header (A2). Each header counts the rows loaded; only the last group drawn gets "+" when `hasMore`, since the next page continues it. Then "Load more results" while `hasMore`, then the footer "Decks first, then cards · case-insensitive, accents matter". | §8 of the backend spec; kit. |
| D11 | **Deck row.** As today: tile by content type, name with the match emphasised, "{path} · holds cards / sub-decks / empty", chevron; a tap opens `AppRoutes.deck(deckId)`. | Unchanged from FE-A11. |
| D12 | **Card row.** `MxListRow`: a card tile; title "{front} · {back}" with the match emphasised by `searchMatchRange` over the whole title; sub-line the card's deck path (`pathLabel`); when `matchedTag` is set, the meta slot holds an `MxTagChip` of that tag before the path (BR-SEARCH-006, UC-SEARCH-001 step 5); chevron. A tap opens `AppRoutes.card(cardId)`, the card detail in reading mode (BR-SEARCH-008). | Kit; UC-SEARCH-001 steps 5–6. |
| D13 | **Load more strip.** `hasMore` and `more = idle`: a secondary full-width `MxButton` "Load more results". `more = loading`: the same button busy. `more = failed`: an `MxInlineBanner` (danger) "Couldn't load more results" with a Retry action, in place of the button. | UC-SEARCH-001 E2: only the end of the list changes. |
| D14 | **No results and error.** `MxEmptyState` (neutral, compact) "No matches for “{term}”" with the body naming every searched field; `MxErrorState` "Search didn't run" with Retry. Loading keeps the "Searching for “{term}”…" header and one skeleton group. | Kit. |
| D15 | **Field hint.** "Search decks, cards, tags", on the screen's field and on the Library root's search trigger. | Kit; spec A11 ends here. |
| D16 | **Removal.** `SearchDecksUseCase` and its provider, `deckSearchProvider`, `DeckSearchScreen`, `DeckSearchResultsWidget`, `DeckSearchHitRowWidget`, `DeckSearchHit`, `DeckRepository.watchSearch` and its implementation, `DeckDao.watchSearchRows`, their tests, and the ARB keys only they use (`deckSearch*`). Surviving strings move to `search*` keys. | Search backend spec D1. |
| D17 | **IT-DISC-006, IT-DISC-007.** Their tests move to screen 04 in the whole-library sense: two decks of one name tell apart by their paths and a tap opens the one chosen (006); a term with no match shows the empty state naming what is searched, and clearing the field returns to the hints (007). The subtree scope of their text stays unimplemented and is recorded as the deviation of UI-base §9 row 74 (ruling P2-L9). | Owner, 2026-09-26. |
| D18 | **Documents.** `code:` of UC-DECK-003 (drops `search_decks_use_case.dart`) and of UC-SEARCH-001 (adds `lib/features/search/presentation`); the search README; `04-library-search.md` (layout, states, the "Pending" table emptied, deviations for D9 and D12); the screen index row 04 (FE-A10); `wbs_FE.md` (FE-A10 → xong); `docs/_generated/`. | CLAUDE.md "after building a screen"; docs and code in one commit. |

## 3. Tests

- **Controller** (`ProviderContainer`, a fake repository, `fake_async`): no read before
  250 ms; one read after; a blank term is `Idle` at once and cancels the pending read;
  a changed term drops the old query's emissions; `Results`/`NoResults`; a later
  emission updates rows; load more keeps rows then replaces them; load-more failure →
  `more = failed`, retry recovers; first-page failure → `Failed`, retry recovers;
  dispose cancels the timer and the subscription.
- **Widget** (library harness, real in-memory database): hints; loading; mixed,
  decks-only, cards-only (no empty header); a card matched only by a tag shows the tag
  chip; counts and "+"; Load more appends; the E2 strip; no results; error and retry;
  a deck row opens the deck, a card row opens the card; the field takes focus;
  IT-DISC-006 and IT-DISC-007.
- **Golden**, light and dark, in the Linux container: emptyQuery, loading, results
  (mixed, with Load more), noResults, error, load-more failed.
- **Visual audit:** the companion moves with the screen
  (`test/visual_audit/screens/features/search/screens/`).
- `dod_check.sh` green.

## 4. Out of scope

Scoped (subtree) search (row 74), fuzzy or accent-folding search, search history,
opening a card in edit mode, an index or FTS (BR-SEARCH-009).
