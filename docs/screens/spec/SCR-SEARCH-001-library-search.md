---
id: SCR-SEARCH-001
name: Library search
domain: search
status: ready
route: [/decks/search]
---

# Library search

## Purpose

Search the whole library: deck names, both card faces and tag names. A child route of the
Library branch — the bottom bar stays and Back returns to the level left. Opened from the search
icon in the Library header, at any level (SCR-DECK-001), and from "Find cards with this tag"
(SCR-TAG-001), which arrives with the term in the `q` query parameter.

## Related Use Cases

- UC-SEARCH-001

## Layout

- **App bar** — back, then the search field in the title slot, focused on entry, hint "Search
  decks, cards, tags". No title. The field sits at its 52 input floor inside the 56 bar.
- **Empty query** — no query runs. A label "SEARCH FINDS"; a card of three read-only hint rows
  (no fill arrow): "a deck name" / "TOPIK, Học qua phim", "a card term or meaning" / "학생, học
  sinh, homework", "a tag name" / "verb, Học"; and the note "Case does not matter, accents do:
  “hoc” will not find “học”. Examples, hints and pronunciation are not searched."
- **Searching** — the label "Searching…" (no query: the field shows it, and user data is never
  upper-cased), then two groups, each a short header bar and three skeleton rows inside a card.
- **Results** — no header repeats the query. Group **Decks**, then group **Cards**; a group with
  no row has no header. Each group label is a section header with the count as a neutral badge at
  the end — the rows loaded, "{n}+" on the last group while another page follows. Deck row: a
  tile by content type, the name with the match emphasised, "{path} · holds cards / sub-decks /
  empty", chevron. Card row: a card tile, "{front} · {back}" with the match emphasised in the face
  that holds it, a sub-line with the matched tag's chip when the card was found by a tag only,
  then the deck path; chevron. Every row is one height; a card's title is one line with a
  trailing ellipsis.
- **More** — a secondary block button "Load more results" while another page follows, busy while
  it reads.
- **Footer** — the caption "Decks first, then cards · case-insensitive, accents matter".
- **No results** — a neutral compact empty state with the search-off glyph.
- **Error** — the error state with Retry; no earlier results stay under it.
- **Load more failed** — the loaded rows stay; a danger banner with Retry at the end of the list.

## States

### `empty_query` · Empty query

Golden: light, dark

### `loading` · Searching

The query is read 250 ms after typing stops; a term typed before that is never read.

Golden: light, dark

### `results` · Results

Golden: light, dark

### `no_results` · No results

Golden: light, dark

### `error` · Error

Golden: light, dark

### `load_more_failed` · Load more failed

A danger banner with Retry under the loaded rows.

Golden: light, dark

## Controls

### Search field

- Type: search field
- Invokes: FN-SEARCH-001
- Purpose: reads the first page 250 ms after typing stops. Clearing it returns to `empty_query`
  at once, with no wait and no read.

#### On failure

- A database failure → `error`.

### Deck result row

- Type: list row

#### On success

- Navigate to: SCR-DECK-001 (the deck).

### Card result row

- Type: list row

#### On success

- Navigate to: SCR-CARD-004 (read-only detail).

### Load more results

- Type: secondary block button
- Enabled when: another page follows and none is being read.
- Invokes: FN-SEARCH-001

#### On failure

- `load_more_failed`.

### Retry (`error`)

- Type: button
- Invokes: FN-SEARCH-001
- Purpose: reads again from the first page.

### Retry (`load_more_failed`)

- Type: banner action
- Invokes: FN-SEARCH-001
- Purpose: reads the same page again.

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

A card row's screen-reader label names both faces, the matched tag and the path, since its title
is cut to one line.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| No query runs while the field is empty. | — |
| A group with no result has no header. | — |
| No header repeats the query, and user data is never upper-cased. | — |
| Load more failing keeps the rows already shown. | — |
| A first-page error shows no earlier results. | — |

## Copy

- Field: "Search decks, cards, tags".
- Empty query: "SEARCH FINDS" · "a deck name" · "TOPIK, Học qua phim" · "a card term or meaning"
  · "학생, học sinh, homework" · "a tag name" · "verb, Học" · "Case does not matter, accents do:
  “hoc” will not find “học”. Examples, hints and pronunciation are not searched."
- Searching: "Searching…".
- Results: "Decks" · "Cards" · "{n}+" · "{path} · holds cards / sub-decks / empty" · "Load more
  results" · "Decks first, then cards · case-insensitive, accents matter".
- No results: "No matches for “{query}”" · "Accents matter — “hoc” does not find “học”. Search
  covers deck names, card terms and meanings, and tag names."
- Error: "Search didn't run" · "Your library is safe on this device. Try again in a moment."
- Load more failed: "Couldn't load more results. What is shown is still correct." · "Retry".

## Rulings

- **Spec D9 (owner 2026-09-26):** hint rows are read-only with no fill arrow; a row with two
  examples cannot say which one a tap would fill.
- **Spec D19:** every result tile is tinted primary and a matched tag is the neutral tag chip with
  no glyph, because green means mastery and amber is the warning tone.
- **Spec D22:** every row is one height; a card's title is one line with a trailing ellipsis, so
  a match deep in a long back can be clipped, and the row's screen-reader label names both faces,
  the tag and the path.
- **Spec D26:** group labels are section headers without a glyph, with the count as a neutral
  badge at the end.
- The match is emphasised with `rowTitleMatch` (primary, 700) and no background mark.
- The field in the app bar is the search field at its 52 input floor inside the 56 bar.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** no
  header repeats the query (the field shows it, and user data is never upper-cased); Decks and
  Cards stay section labels.
- **FE-B2 spec D11:** the search opens on a term passed as `q`.
