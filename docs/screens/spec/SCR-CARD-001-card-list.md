---
id: SCR-CARD-001
name: Card list
domain: card
status: ready
route: [/decks/deck/:deckId]
---

# Card list

## Purpose

An open deck whose content type is `card`: the card section of the open-deck screen
(SCR-DECK-001 shows a deck that holds decks; this spec, a deck that holds cards). It shows the
deck's progress and its cards — filtered, searched, sorted and tagged — and is where cards are
selected in bulk, moved, flagged, tagged, exported and moved to the Trash.

## Related Use Cases

- UC-CARD-001
- UC-CARD-002
- UC-TAG-001
- UC-TRASH-001

## Layout

- **App bar** — back, the deck name, a search action, ⋮. While selecting: close, "{n} selected",
  and "Select all {count}" (a compact secondary button).
- **Breadcrumb** — Library › ancestors › deck; hidden while selecting.
- **Search** — the search field, revealed by the search action; closing it clears the term.
  Hidden while selecting; its term stays and returns with it.
- **Summary card** — a hero card with a mastery donut and the workload line: the eyebrow "Deck
  progress · {algorithm}", "{n} of {total} cards mastered", overdue · today · new; mastery is
  stated once, with no four-state bar or legend. "Study this deck · {n} due" (a primary block
  button; "Study this deck" when only new cards wait) opens the Study Entry; hidden when the deck
  holds no card to study. Hidden while selecting, and while search is open, so the first results
  sit above the keyboard.
- **Filters** — filter chips All · Due · New · Flagged with counts, then Tags with the tag glyph:
  selected with the count of tags applied; its tap opens the tag filter.
- **Header** — a section header: "Cards" while every card of the deck shows; "Showing {n} of
  {total}" while a filter, a tag or search narrows it; none while selecting, when the app bar
  holds the count. A sort trigger "Newest ⇅" / "Due first ⇅" (the sort glyph, not a chevron).
- **Rows** — a card surface per row, 8 apart: the checkbox while selecting (no status dot: the
  label states the status once); the front 16/700 and the back 12, one line each; the uppercase
  status label in its ink, up to two tag chips and "+{n}"; a trailing flag in plain ink (the
  filled glyph carries the state) and the due chip, a badge: "New", "Due today", "In {n}d",
  "{n}d overdue" — overdue warning, today primary, else neutral. The status label, tags and
  "+{n}" wrap at large text. Rows build as they scroll into view.
- **Bulk bar** — while selecting, a footer bar with five icon buttons: Move · Flag · Tag · Export
  · Trash.
- **FAB** — "New card"; hidden while selecting and while search is open. The list ends clear of
  it, and drops that clearance while selecting.
- **Deck action sheet (⋮)** — Study this deck · Rename · Move to another deck · Import cards ·
  Export cards · Move to Trash; Rename, Move and Move to Trash behave as on SCR-DECK-001.
- **Flag sheet** — "Flag cards" · "Remove flag".
- **Move sheet** — the deck picker: "Move {n} cards to…", the rule, the targets as paths; with
  no target, "Nowhere to move these cards" and why.
- **Move to Trash dialog** — no glyph. One card: "Move this card to Trash?" with the card's
  preview; several: "Move {n} cards to Trash?" without it. The body reads "Recoverable from Trash
  for 30 days, with its schedule and history. Other cards are unaffected." The confirm spins while
  they move.
- **Tag filter sheet** — a bottom sheet, "Filter by tags" over "Show cards with any of the chosen
  tags", or "{k} chosen · cards with any of them". A row per tag of the library (a list row with
  one checkbox node): the name and its cards in this deck, 0 included, in the catalog's order; a
  checked row never moves. Above eight tags, "Search tags" heads the list; it never drops a
  chosen tag. Footer: "Clear" (empties the choice and stays open; off when nothing is chosen) and
  "Apply" (closes and applies). Closing it any other way keeps what was applied. With no tag in
  the library: "No tags yet. Add tags while creating or editing cards." and Close.

## States

### `loaded` · Loaded

The Tags chip reads as selected while tags are applied.

Golden: light, dark

### `empty` · Empty

The deck holds no card again, so it is `unset`: SCR-DECK-001's `deck_empty` state shows, with
Add card and Import cards.

Golden: none — no golden in V8 (record 07)

### `search_empty` · Search, no match

"No cards match “{term}”" with the way to clear the search. A filter's empty state is not the
deck's: it offers to show all.

Golden: light, dark

### `search_results` · Search with results

Two matches with a 300 dp keyboard up: the summary card steps aside.

Golden: light, dark

### `loading` · Loading

Golden: none — no golden in V8 (record 07)

### `error` · Error

"Couldn't open this deck" · "Your data is safe on this device. Try again in a moment." with
Retry.

Golden: none — no golden in V8 (record 07)

### `not_found` · Deck no longer here

As SCR-DECK-001 `deck_not_found`.

Golden: none — no golden in V8 (record 07)

### `deck_actions` · Deck action sheet

Golden: none — no golden in V8 (record 07)

### `selection` · Selecting

Long-press, or Select, selects; the app bar carries close, "{n} selected" and "Select all {n}".
A tap in selection mode only toggles the card; it never opens the detail.

Golden: light, dark

### `move_targets` · Move sheet

Golden: none — no golden in V8 (record 07)

### `no_move_target` · Nowhere to move

Golden: none — no golden in V8 (record 07)

### `bulk_failed` · Bulk action failed

Flag: an inline banner above the bulk bar, with Retry repeating the same cards and choice. Move,
Tag and Trash keep their sheet or dialog open and say it there. The selection stays. While Retry
runs it shows the button's loading state, the banner stays and the bulk bar ignores taps.

Golden: light, dark

### `del_card` · Move to Trash dialog

Golden: light, dark

### `del_deck` · Move deck to Trash dialog

As SCR-DECK-001 `deck_delete`.

Golden: none — no golden in V8 (record 07)

### `trashed` · Moved to Trash

One card: "“{front}” moved to Trash" with Undo for 8 seconds, where it was deleted. Several:
"{n} cards moved to Trash" with Open Trash, no Undo. A refused Undo says "Can't undo. {reason}
Restore it from Trash and choose a deck."

Golden: light, dark

### `tag_filter_none` · Tag filter, none chosen

Golden: light, dark

### `tag_filter_one` · Tag filter, one chosen

Golden: light, dark

### `tag_filter_several` · Tag filter, several chosen

Golden: light, dark

### `tag_filter_applied` · Tags applied

The list starts again from its first window and the selection clears. A tag deleted or merged
away leaves the applied set.

Golden: light, dark

### `tag_filter_no_card` · No card with these tags

"No cards with these tags" with "Clear tag filter".

Golden: light, dark

## Controls

### Deck summary and card list

- Type: read
- Invokes: FN-DECK-008, FN-CARD-001

#### On failure

- A database failure → `error`.

### Search action, search field

- Type: icon button / search field
- Invokes: FN-CARD-001
- Purpose: narrows the list by the term; closing the search clears it.

### Filter chips: All, Due, New, Flagged

- Type: filter chips
- Invokes: FN-CARD-001

### Tags chip

- Type: filter chip
- Invokes: FN-CARD-012
- Purpose: opens the tag filter sheet with every tag, its count in this deck and the current
  choice.

### Tag rows, Clear, Apply (tag filter sheet)

- Type: checkbox rows / sheet actions
- Invokes: FN-CARD-001
- Purpose: Apply applies the choice (any chosen tag, and the status filter and the search); Clear
  empties the choice; closing without Apply drops the draft.

### Clear tag filter (`tag_filter_no_card`)

- Type: button
- Invokes: FN-CARD-001

### Sort trigger

- Type: chip trigger
- Invokes: FN-CARD-001
- Purpose: Newest, or Due first (new cards last).

### Card row

- Type: list row
- Purpose: outside selection, opens the read-only detail; in selection, toggles the card.

#### On success

- Navigate to: SCR-CARD-004 (pushed over the list).

### Long-press on a row

- Type: gesture
- Purpose: starts selection with that card.

### Select all {count}

- Type: compact secondary button
- Invokes: FN-CARD-008
- Purpose: selects every card that matches the list, not only the loaded rows.

### Move (bulk bar)

- Type: icon button
- Invokes: FN-CARD-006, FN-CARD-007

#### On success

- The sheet closes and the selection clears.

#### On failure

- A rejection → the sheet stays open and says why; the selection stays.

### Flag (bulk bar)

- Type: icon button
- Invokes: FN-CARD-009
- Purpose: opens the flag sheet — Flag cards, or Remove flag — for the selection.

#### On success

- "{n} cards flagged"; the selection clears.

#### On failure

- `bulk_failed` with Retry.

### Tag (bulk bar)

- Type: icon button
- Invokes: FN-CARD-010

#### On failure

- A rejection (`blankName`, `nameTooLong`, `controlCharacter`, `tooManyTags`, `notFound`) → the
  sheet stays open and says why; the selection stays.

### Export (bulk bar), Export cards (⋮)

- Type: icon button / sheet command
- Purpose: opens the export sheet for the selection, or for the whole deck; the selection stays.

#### On success

- Navigate to: SCR-TRANSFER-002

### Trash (bulk bar)

- Type: icon button
- Purpose: opens the Move to Trash dialog (`del_card`).

### Move to Trash (dialog confirm)

- Type: dialog confirm (destructive)
- Invokes: FN-CARD-004

#### On success

- `trashed`.

#### On failure

- The dialog stays and says why; the selection stays.

### Undo (one card moved to Trash)

- Type: toast action
- Invokes: FN-CARD-005

#### On failure

- "Can't undo. {reason} Restore it from Trash and choose a deck."

### Open Trash (several cards moved, refused Undo)

- Type: toast action

#### On success

- Navigate to: SCR-TRASH-001

### Study this deck (summary card, ⋮)

- Type: primary block button / sheet command

#### On success

- Navigate to: SCR-STUDY-002

### Import cards (⋮)

- Type: sheet command

#### On success

- Navigate to: SCR-TRANSFER-001

### Rename, Move to another deck, Move to Trash (⋮)

- Type: sheet commands
- Invokes: FN-DECK-002, FN-DECK-010, FN-DECK-011, FN-DECK-004, FN-DECK-005
- Purpose: as on SCR-DECK-001.

### New card (FAB)

- Type: floating action button

#### On success

- Navigate to: SCR-CARD-002

### Retry (`error`)

- Type: button
- Invokes: FN-DECK-008, FN-CARD-001

## Responsive Behavior

A row's status label, tags and "+{n}" wrap at large text. The summary card steps aside while
search is open, so results sit above the keyboard. Otherwise follows the shared floor (DESIGN.md,
SCREEN_CATALOG.md).

## Accessibility

- A tag filter row is one checkbox node.
- The flag's state is carried by its filled glyph, not by colour.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Select all selects every matching card, not only the loaded rows. | — |
| A new filter, search, sort or tag set starts the list from its first window and clears the selection. | — |
| A tap in selection mode toggles; it never opens the detail. | — |
| A failed bulk action keeps the selection. | — |
| Undo happens where the card was deleted; several cards get Open Trash, not Undo. | — |
| A filter's empty state is distinct from the deck's. | — |

## Copy

- Summary: "Deck progress · {algorithm}" · "{n} of {total} cards mastered" · "New" · "Beginning"
  · "Reviewing" · "Mastered" · "Study this deck · {n} due".
- Filters and header: "All" · "Due" · "New" · "Flagged" · "Tags" · "Cards" · "Showing {n} of
  {total}" · "Newest" · "Due first".
- Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · "Export" ·
  "Trash".
- Flag: "Flag cards" · "Remove flag" · "{n} cards flagged".
- Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Recoverable from Trash
  for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move to
  Trash" · "“{front}” moved to Trash" · "Undo" · "{n} cards moved to Trash" · "Can't undo.
  {reason} Restore it from Trash and choose a deck.".
- Empty: "No cards in this deck yet" · "Write your first card, or bring many at once from a
  spreadsheet or pasted text." · "Import cards (CSV, TSV, XLSX, text)" · "Studying this deck
  becomes available once it holds at least one card."
- Search empty: "No cards match “{term}”" · "Try a different term, or clear the search to see all
  {n} cards."
- Tag filter: "Tags" · "Filter by tags" · "Show cards with any of the chosen tags" · "{k} chosen ·
  cards with any of them" · "Search tags" · "Clear" · "Apply" · "No tags yet. Add tags while
  creating or editing cards." · "Close" · "Couldn't load tags" · "No cards with these tags" ·
  "Clear tag filter".
- Bulk failed: "Couldn't finish that." · "Nothing changed. The cards stay selected." · "Retry".
- Error: "Couldn't open this deck" · "Your data is safe on this device. Try again in a moment."
- Move: "Move {n} cards to…" · "Schedule, history, flags and tags travel with the cards. Decks in
  other trees are not offered." · no target: "Nowhere to move these cards" · "No other deck in
  “{root}” holds cards or is empty. Create an empty sub-deck first; cards can only move within
  their own tree."
- Rejections (by failure type): `notFound` "This card no longer exists." · `targetNotFound` "That
  deck no longer exists." · `targetIsRoot` "A top-level deck can't hold cards." ·
  `targetHoldsDecks` "That deck holds decks, so it can't hold cards." · `sameDeck` "The cards are
  already there." · `crossRootMove` "Cards can only move within the same top-level deck." ·
  `targetInTrash` "That deck is in the Trash." · `tooManyTags` "A card holds 10 tags at most." ·
  `invalidTagName` "That tag name can't be used."

## Rulings

- **Critique 2026-09-30 part 1:** search hides the summary card and keeps the filter row, so a
  filter still applies to the search and the results clear the keyboard.
- **Move to Trash dialog:** no glyph; the body reads "Recoverable from Trash for 30 days, with its
  schedule and history", since the dialog reads no history count.
- **FE-B2 D14 (critique P1b):** Tags is a filter chip, selected while tags are applied.
- **E-L1:** an empty card list makes the deck unset again; SCR-DECK-001's unset state shows.
- **E-L2:** the flag uses the warning colour; the theme has no streak token. Superseded by
  critique 2026-10-02 (F6): plain ink.
- **E-L3:** "Select all" is a compact secondary button.
- **E-L4:** the due chip is a badge: overdue warning, today primary, else neutral.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  deck summary's progress line is an eyebrow.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** the add
  FAB steps aside while search is open; a failed bulk flag's banner offers Retry, repeating the
  same cards and choice.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** while a
  failed bulk flag's Retry runs, the banner stays and Retry shows the button's loading state; the
  bulk bar ignores taps meanwhile. A failure keeps the banner; success clears the selection as
  before.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain ink
  (`onSurface`), the filled glyph carrying the state as in the editor and the detail; E-L2 is
  superseded (F6).
- **FE-B1 D3, D4, D14:** one card moved to Trash gets Undo for 8 seconds; several get Open Trash
  and no Undo; an Undo happens where the card was deleted.
- **Migration 2026-10-04:** the legacy UC-CARD-001 A6 named a contextual bar with Add tag, Flag,
  Remove flag and Delete; V8 draws Move · Flag · Tag · Export · Trash, Flag opening a sheet with
  Flag cards and Remove flag. The spec follows the app.
