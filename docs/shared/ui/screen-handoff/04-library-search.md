<!-- Hand-written screen record. -->

# 04 · Library search

`/decks/search`. UC-SEARCH-001 on `SearchLibraryUseCase`: deck names, both card faces
and tag names (FE-A10, [spec](../../../superpowers/specs/2026-09-26-library-search-ui-design.md)).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` with its title-widget slot | Back, then `MxSearchField` (focused on entry), hint "Search decks, cards, tags". No title. |
| Empty query | label, `MxCard` of `MxListRow`s, `MxNote` | No query runs (BR-SEARCH-003). "SEARCH FINDS"; three read-only hint rows: "a deck name" / "TOPIK, Học qua phim", "a card term or meaning" / "학생, học sinh, homework", "a tag name" / "verb, Học"; note "Case does not matter, accents do: “hoc” will not find “học”. Examples, hints and pronunciation are not searched." |
| Searching | label, skeleton groups | "Searching…" (no query: the field shows it, and user data is never upper-cased), then two groups, each a short header bar and three skeleton rows inside an `MxCard`. |
| Results | group headers, `MxCard`s of `MxListRow`s | No header repeats the query (critique 2026-09-30 part 2); group **Decks** then group **Cards** (BR-SEARCH-005), a group with no row has no header; each header counts the rows loaded, "{n}+" on the last group while another page follows. Deck row: tile by content type, name with the match emphasised, "{path} · holds cards / sub-decks / empty", chevron. Card row: card tile, "{front} · {back}" with the match emphasised in the face that holds it, a sub-line with the matched tag's `MxTagChip` when the card was found by a tag only, then the deck path; chevron; opens the card detail. |
| More | `MxButton` (secondary, block) | "Load more results" while another page follows (BR-SEARCH-007), busy while it reads. |
| Footer | caption | "Decks first, then cards · case-insensitive, accents matter". |
| No results | `MxEmptyState` (neutral, compact) | Search-off glyph; "No matches for “{query}”" / "Accents matter — “hoc” does not find “học”. Search covers deck names, card terms and meanings, and tag names." |
| Error | `MxErrorState` | "Search didn't run" / "Your library is safe on this device. Try again in a moment." |
| Load more failed | `MxInlineBanner` (danger) + Retry | The rows stay; the end of the list says "Couldn't load more results. What is shown is still correct." (UC-SEARCH-001 E2). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| emptyQuery | `search_empty_query_light.png` | `search_empty_query_dark.png` | Without the fill arrows. |
| loading | `search_loading_light.png` | `search_loading_dark.png` | — |
| results | `search_results_light.png` | `search_results_dark.png` | Colours per the deviations. |
| noResults | `search_no_results_light.png` | `search_no_results_dark.png` | — |
| error | `search_error_light.png` | `search_error_dark.png` | — |
| loadMoreFailed | `search_load_more_failed_light.png` | `search_load_more_failed_dark.png` | An `MxInlineBanner` with Retry under the loaded rows (spec D24). |

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
