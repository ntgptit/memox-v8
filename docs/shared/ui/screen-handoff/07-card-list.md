<!-- Hand-written screen record. -->

# 07 · Card list

An open deck whose content type is `card`: the card section of `DeckLevelScreen`
(Library spec D8). UC-CARD-001, UC-CARD-002.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar`, injected by `app/` (spec A14) | Back, deck name, search action, `⋮`. Selecting: close, "{n} selected", "Select all {count}". |
| Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck; hidden while selecting. |
| Search | `MxSearchField` | Revealed by the search action; closing it clears the term. Hidden while selecting; its term stays and returns with it. |
| Summary card | `MxCard` (hero) + `MxMasteryDonut` + `MxWorkloadBreakdownLine` | "DECK PROGRESS · {algorithm}", "{n} of {total} cards mastered", overdue · today · new; mastery is stated once, with no four-state bar or legend (critique 2026-09-30, R2). "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the deck holds no card to study. Hidden while selecting, and while search is open, so the first results sit above the keyboard (critique 2026-09-30 part 1). |
| Filters | `MxFilterChip` | All · Due · New · Flagged with counts, then Tags with the tag glyph: selected with the count of tags applied, and its tap opens the tag filter (FE-B2 D14). |
| Header | `MxListSectionHeader` + `MxChipTrigger` | "Cards" while every card of the deck shows; "Showing {n} of {total}" (matches of the deck's cards) while a filter, a tag or search narrows it; none while selecting, when the app bar holds the count (critique 2026-09-30 part 3b); sort "Newest ⇅" / "Due first ⇅" (the sort glyph, not a chevron). |
| Rows | card surface per row, 8 apart | The checkbox while selecting (no status dot: the label states the status once, critique 2026-09-30 part 3b, R3); front 16/700 and back 12, one line each; uppercase status label in its ink, up to two `MxTagChip`s and "+{n}"; trailing flag in plain ink (critique 2026-10-02, F6) and the due chip, an `MxBadge` (E-L4): "New", "Due today", "In {n}d", "{n}d overdue". The status label, tags and "+{n}" wrap at large text. Rows build as they scroll into view (E-L5). |
| Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Trash. |
| FAB | `MxFab` | "New card" (#33); hidden while selecting and while search is open (critique 2026-09-30 part 3d-1). The list ends clear of it (`MxScrollClearance.fabAboveNav`), and drops that clearance while selecting (critique 2026-09-30). |

## Deck action sheet (`⋮`)

Study this deck · Rename · Move to another deck · Import cards (screen 11) · Export cards
(screen 12) · Move to Trash. Study this deck opens the Study Entry, screen 14 (FE-A6 D10).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `card_list_light.png` | `card_list_dark.png` | The Tags chip reads as selected while tags are applied (D14; UI-base row 140). |
| empty | no golden | no golden | The deck is unset again (E-L1): screen 01's unset state. |
| searchEmpty | no golden | no golden | — |
| loading | no golden | no golden | — |
| error | no golden | no golden | — |
| notFound | no golden | no golden | As screen 01 deckNotFound. |
| deckActions | no golden | no golden | — |
| selection | `card_selection_light.png` | `card_selection_dark.png` | Long-press selects (BR-CARD-020). The app bar carries close, "{n} selected" and "Select all {n}" (A14). |
| moveTargets | no golden | no golden | — |
| noMoveTarget | no golden | no golden | — |
| bulkFailed | `card_list_bulk_failed_light.png` | `card_list_bulk_failed_dark.png` | Flag: an inline banner above the bulk bar (E-L6). Move, Tag and Trash keep their sheet or dialog open and say it there. The selection stays. Retry shows the button's loading state while it runs, the banner stays and the bulk bar ignores taps meanwhile. |
| delCard | `card_list_trash_dialog_light.png` | `card_list_trash_dialog_dark.png` | One selected card: the dialog without a glyph, with the card's preview. Several: "Move {n} cards to Trash?" without the preview, and the confirm names the count, "Move {n} cards to Trash" (SP2a 2.20). The confirm spins while they move (FE-B1 D15). |
| delDeck | no golden | no golden | As screen 01 deckDelete. |
| trashed | `card_list_trashed_light.png` | `card_list_trashed_dark.png` | One card: Undo for 8 seconds (FE-B1 D3, D14). Several: "{n} cards moved to Trash", also Undo for 8 seconds, all back or none (BR-TRASH-008, SP2a 2.20); Open Trash appears only on a refused Undo (UC-TRASH-001 E3). |
Other goldens: `card_list_search_light.png` / `card_list_search_dark.png` (search open, no match); `card_list_search_results_light.png` / `card_list_search_results_dark.png` (two matches with a 300 dp keyboard up: the summary card steps aside, critique 2026-09-30 part 3a).


Not captured: `cardActions` gives way to the card detail: a tap opens it (#35). The card
editor (screen 09) moves its card to the Trash from its "More" card with the same dialog
(FE-B1 D13):
`card_editor_trash_dialog_light.png` / `card_editor_trash_dialog_dark.png`

## Tag filter

Shaped by Impeccable before the plan (FE-B2 D3,
`.impeccable/critique/2026-09-27T06-00-00Z__tags-starter-kit.md`).

- **The sheet:** `MxBottomSheet`, "Filter by tags" over "Show cards with any of the chosen
  tags", or "{k} chosen · cards with any of them". A row per tag of the library
  (`MxListRow` with `MxSelectionCheckbox`, one checkbox node): the name and its cards in
  this deck, 0 included, in the catalog's order; a checked row never moves. Above eight
  tags, "Search tags" heads the list; it never drops a chosen tag.
- **The footer:** "Clear" (empties the choice, stays open; off when nothing is chosen) and
  "Apply" (closes and applies). Closing it any other way keeps what was applied (A5).
  With no tag in the library, the sheet says "No tags yet. Add tags while creating or
  editing cards." and offers Close.
- **Applying:** a card passes with any chosen tag (BR-TAG-004), and with the status filter
  and the search. The list starts again from its first window, and the selection clears
  (BR-TAG-005). A tag deleted or merged away leaves the applied set (D12).
- **No card with these tags (A7):** "No cards with these tags" with "Clear tag filter".

| State | Golden (light) | Golden (dark) |
|---|---|---|
| none chosen | `card_tag_filter_none_light.png` | `card_tag_filter_none_dark.png` |
| one chosen | `card_tag_filter_one_light.png` | `card_tag_filter_one_dark.png` |
| several chosen | `card_tag_filter_several_light.png` | `card_tag_filter_several_dark.png` |
| applied | `card_tag_filter_applied_light.png` | `card_tag_filter_applied_dark.png` |
| no card (A7) | `card_tag_filter_no_card_light.png` | `card_tag_filter_no_card_dark.png` |

The goldens are in `test/features/card/presentation/goldens/`.

## Rulings

- **Critique 2026-09-30 part 1:** search hides the summary card and keeps the filter row, so a filter still applies to the search and the results clear the keyboard.
- **Move to Trash dialog:** no glyph (`MxDialog` has no glyph slot); the body reads "Recoverable from Trash for 30 days, with its schedule and history", since the dialog reads no history count.
- **FE-B2 D14 (critique P1b):** Tags is a filter chip, selected while tags are applied.
- **BR-DECK-015, E-L1:** an empty card list makes the deck unset again; screen 01's unset state shows.
- **E-L2:** the flag uses the warning colour; the theme has no streak token. Superseded by critique 2026-10-02 (F6): plain ink.
- **E-L3:** "Select all" is a compact secondary `MxButton`.
- **E-L4:** the due chip is an `MxBadge`: overdue warning, today primary, else neutral.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the deck summary's progress line is an eyebrow.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** the add FAB steps aside while search is open; a failed bulk flag's banner offers Retry, repeating the same cards and choice.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** while a failed bulk flag's Retry runs, the banner stays and Retry shows the button's loading state; the bulk bar ignores taps meanwhile. A failure keeps the banner; success clears the selection as before.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain ink (`onSurface`), the filled glyph carrying the state as in the editor and the detail; E-L2 is superseded (F6).
- **SP2a 2.19–2.21 (spec `2026-10-03-ui-hardening-sp2a-design.md` §3.3):** a bulk Trash, Move, Tag or Flag works on the selected cards that still exist and skips the rest inside the same transaction. Its toast gains "{n} were already gone." and the selection drops the gone ids; when every selected card is gone it says so, changes nothing and drops them (2.19). The Trash confirm of several cards names the count, and its toast carries Undo for the whole batch, the restore the Trash screen uses (2.20). A bulk Tag refused at the limit names how many cards already hold 10 tags (2.21).

## Copy

- Summary: "Deck progress · {algorithm}" · "{n} of {total} cards mastered" · "New" · "Beginning" · "Reviewing" · "Mastered" · "Study this deck · {n} due".
- Filters and header: "All" · "Due" · "New" · "Flagged" · "Tags" · "Cards" · "Showing {n} of {total}" · "Newest" · "Due first".
- Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · "Export" · "Trash".
- Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move to Trash" (one card) / "Move {n} cards to Trash" (several) · "“{front}” moved to Trash" · "Undo" · "{n} cards moved to Trash".
- Bulk results: "{message}. {n} were already gone." ("1 was already gone."; the suffix of every bulk toast) · "The selected card is already gone. Nothing changed." / "The {n} selected cards are already gone. Nothing changed." · Tag at the limit: "{n} cards already have 10 tags; nothing was tagged." ("1 card already has 10 tags; nothing was tagged.").
- Empty: "No cards in this deck yet" · "Write your first card, or bring many at once from a spreadsheet or pasted text." · "Import cards (CSV, TSV, XLSX, text)" · "Studying this deck becomes available once it holds at least one card."
- Search empty: "No cards match “{term}”" · "Try a different term, or clear the search to see all {n} cards."
- Tag filter: "Tags" · "Filter by tags" · "Show cards with any of the chosen tags" · "{k} chosen · cards with any of them" · "Search tags" · "Clear" · "Apply" · "No tags yet. Add tags while creating or editing cards." · "Close" · "Couldn't load tags" · "No cards with these tags" · "Clear tag filter".
- Error: "Couldn't open this deck" · "Your data is safe on this device. Try again in a moment."
- Move: "Move {n} cards to…" · "Schedule, history, flags and tags travel with the cards. Decks in other trees are not offered." · no target: "Nowhere to move these cards" · "No other deck in “{root}” holds cards or is empty. Create an empty sub-deck first; cards can only move within their own tree."
