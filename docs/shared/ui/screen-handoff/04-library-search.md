<!-- Hand-written screen record. -->

# 04 · Library search

`/decks/search`. UC-SEARCH-001 on `SearchLibraryUseCase`: deck names, both card faces
and tag names (FE-A10, [spec](../../../superpowers/specs/2026-09-26-library-search-ui-design.md)).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` with its title-widget slot | Back, then `MxSearchField` (focused on entry), hint "Search decks, cards, tags". No title: the field names the route for TalkBack (`MxSearchField(isRouteName: true)`, DEV-393), as the SDK app bar names a route by its title. |
| Empty query | label, `MxCard` of `MxListRow`s, `MxNote` | No query runs (BR-SEARCH-003). "SEARCH FINDS"; three read-only hint rows: "a deck name" / "TOPIK, Học qua phim", "a card term or meaning" / "학생, học sinh, homework", "a tag name" / "verb, Học"; note "Case does not matter, accents do: “hoc” will not find “học”. Examples, hints and pronunciation are not searched." |
| Searching | label, skeleton groups | "Searching…" (no query: the field shows it, and user data is never upper-cased), then two groups, each a short header bar and three skeleton rows inside an `MxCard`. |
| Results | group headers, `MxCard`s of `MxListRow`s | No header repeats the query (critique 2026-09-30 part 2); group **Decks** then group **Cards** (BR-SEARCH-005), a group with no row has no header; each header counts the rows loaded, "{n}+" on the last group while another page follows. Deck row: tile by content type, name with the match emphasised, "{path} · holds cards / sub-decks / empty", chevron. Card row: card tile, "{front} · {back}" with the match emphasised in the face that holds it, a sub-line with the matched tag's `MxTagChip` when the card was found by a tag only, then the deck path; chevron; opens the card detail. |
| More | `MxButton` (secondary, block) | "Load more results" while another page follows (BR-SEARCH-007), busy while it reads. |
| Footer | caption | "Decks first, then cards · case-insensitive, accents matter". |
| No results | `MxEmptyState` (neutral, compact) | Search-off glyph; "No matches for “{query}”" / "Accents matter — “hoc” does not find “học”. Search covers deck names, card terms and meanings, and tag names." |
| Error | `MxErrorState` | "Search didn't run" / "Nothing was lost. Try again in a moment." |
| Load more failed | `MxInlineBanner` (danger) + Retry | The rows stay; the end of the list says "Couldn't load more results. What is shown is still correct." (UC-SEARCH-001 E2). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| emptyQuery | `search_empty_query_light.png` | `search_empty_query_dark.png` | Without the fill arrows. |
| loading | `search_loading_light.png` | `search_loading_dark.png` | — |
| results | `search_results_light.png` | `search_results_dark.png` | — |
| noResults | `search_no_results_light.png` | `search_no_results_dark.png` | — |
| error | `search_error_light.png` | `search_error_dark.png` | — |
| loadingMore | no golden | no golden | The rows stay; "Load more results" shows its spinner while the next page reads (A1). `library_search_screen_test.dart::51 hits: the count says more, Load more reads the rest (A1)`, `search_screen_controller_test.dart::load more keeps the rows while it reads, then shows the longer extent (A1)`. |
| loadMoreFailed | `search_load_more_failed_light.png` | `search_load_more_failed_dark.png` | An `MxInlineBanner` with Retry under the loaded rows (spec D24). |
| arrivedWithTerm | no golden | no golden | Opened with a term (a tag's "Find cards with this tag", screen 05): the field holds it and the search runs once after the first frame (FE-B2 spec D11). `library_search_screen_test.dart::a term given on arrival is typed and searched, as Find cards with this tag opens it (FE-B2 spec D11)`. |

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (entry) | open with no term | emptyQuery, the field focused | VERIFIED `library_search_screen_test.dart::the field sits in the app bar and takes focus`, `::before a term it says what search finds (step 2)` |
| (entry) | open with a term | arrivedWithTerm, then loading | VERIFIED `::a term given on arrival is typed and searched, as Find cards with this tag opens it (FE-B2 spec D11)` |
| emptyQuery | type a term | loading 250 ms after the last keystroke, then results or noResults | VERIFIED `search_screen_controller_test.dart::a term is read once, 250 ms after the last keystroke`, `::rows are results; no rows is no results` |
| loading | the first page lands | results / noResults | VERIFIED `library_search_screen_test.dart::decks first, then cards, each group counted (step 4)`, `::no match names what is searched; clearing returns to the hints (IT-DISC-007, A4)` |
| loading | the first page fails | error | VERIFIED `::a failed first page is the error state; retry reads again (E1)` |
| error | Retry | loading, then results / noResults | VERIFIED same test; `search_screen_controller_test.dart::a first-page failure shows no rows; retry reads from the first page (E1)` |
| results | the data changes elsewhere (a rename) | the rows update in place | VERIFIED `library_search_screen_test.dart::a rename elsewhere updates the path in place (A3)` |
| results | the re-read of the first page fails after a write | error, no stale row | VERIFIED `search_screen_controller_test.dart::a failed re-read of the first page, after a write, shows no stale rows (E1)` |
| results / noResults / error | clear the field or type blanks | emptyQuery at once; a pending read is cancelled | VERIFIED `search_screen_controller_test.dart::a blank term is idle at once and cancels the pending read`; `library_search_screen_test.dart::no match names what is searched; clearing returns to the hints (IT-DISC-007, A4)` |
| results | tap Load more results | loadingMore, then results with the longer extent | VERIFIED `library_search_screen_test.dart::51 hits: the count says more, Load more reads the rest (A1)` |
| loadingMore | the page fails | loadMoreFailed, the rows kept | VERIFIED `::a failed later page keeps the rows and offers a retry (E2)` |
| loadMoreFailed | Retry | loadingMore with the same extent | VERIFIED `search_screen_controller_test.dart::a load-more failure keeps the rows; retry reads the same cursor (E2)` |
| loadingMore | a second tap on Load more | ignored | `UNVERIFIED (code read)`: `search_screen_controller.dart` `loadMore()` returns while `more` is loading (the button is also busy) |
| results | tap a deck row | the deck opens (screen 01) | VERIFIED `::two decks of one name tell apart by path, and a tap opens the one chosen (IT-DISC-006)` |
| results | tap a card row | the card detail (screen 10) | VERIFIED `::a card row opens the card (step 6)` |
| any | Back | the screen it came from; the pending read and the watch are cancelled | VERIFIED for the cancel `search_screen_controller_test.dart::leaving cancels the pending read and the watch`; the Back tap is `UNVERIFIED (code read)` |
| results | the shown deck or card is deleted elsewhere | the row leaves on the next emission; the group header goes with its last row | covered by the stream update above (A3); the deletion itself `UNVERIFIED (code read)` |

## Pending

Nothing pending since FE-A10.

## Rulings

- **Spec D9 (owner 2026-09-26):** hint rows are read-only with no fill arrow; a row with two examples cannot say which one a tap would fill.
- **Spec D19:** every result tile is tinted primary and a matched tag is the neutral `MxTagChip` with no glyph, because green means mastery and amber is the warning tone.
- **Spec D22:** every row is one height (`MxListRow`); a card's title is one line with a trailing ellipsis, so a match deep in a long back can be clipped, and the row's screen-reader label names both faces, the tag and the path.
- **Spec D26:** group labels are `MxListSectionHeader` without a glyph, with the count as a neutral `MxBadge` at the end.
- The match is emphasised with `rowTitleMatch` (primary, 700) and no background mark.
- The field in the app bar is `MxSearchField` at its 52 input floor inside the 56 bar.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** no header repeats the query (the field shows it, and user data is never upper-cased); Decks and Cards stay section labels.
- **Q-C-1 (owner, 2026-10-16):** the footer ("Decks first, then cards · …") keeps each dot on the phrase before it (`metaDots`); a deck hit's path line is one line with an ellipsis, so it is left as is (The Wrap Rule; `lib/l10n/meta_line.dart`).
