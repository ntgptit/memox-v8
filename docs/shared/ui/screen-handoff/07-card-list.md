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
| Summary card | `MxCard` (hero) + `MxMasteryDonut` + `MxWorkloadBreakdownLine` | "DECK PROGRESS · {algorithm}", "{n} of {total} cards mastered", overdue · today · new; mastery is stated once, with no four-state bar or legend (critique 2026-09-30, R2). "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the deck holds no card to study. Hidden while selecting. |
| Filters | `MxFilterChip` | All · Due · New · Flagged with counts, then Tags with the tag glyph: selected with the count of tags applied, and its tap opens the tag filter (FE-B2 D14). |
| Header | `MxListSectionHeader` + `MxChipTrigger` | "Showing {n} of {total}" (selecting: "{n} of {total} selected"); sort "Newest first ⌄" / "Due first ⌄". |
| Rows | card surface per row, 8 apart | Status dot (checkbox while selecting); front 16/700 and back 12, one line each; uppercase status label in its ink, up to two `MxTagChip`s and "+{n}"; trailing flag in the warning colour (E-L2) and the due chip, an `MxBadge` (E-L4): "New", "Due today", "In {n}d", "{n}d overdue". The status label, tags and "+{n}" wrap at large text. Rows build as they scroll into view (E-L5). |
| Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Trash. |
| FAB | `MxFab` | "New card" (#33); hidden while selecting. The list ends clear of it (`MxScrollClearance.fabAboveNav`), and drops that clearance while selecting (critique 2026-09-30). |

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
| bulkFailed | `card_list_bulk_failed_light.png` | `card_list_bulk_failed_dark.png` | Flag: an inline banner above the bulk bar (E-L6). Move, Tag and Trash keep their sheet or dialog open and say it there. The selection stays. |
| delCard | `card_list_trash_dialog_light.png` | `card_list_trash_dialog_dark.png` | One selected card: the dialog without a glyph, with the card's preview. Several: "Move {n} cards to Trash?" without the preview. The confirm spins while they move (FE-B1 D15). |
| delDeck | no golden | no golden | As screen 01 deckDelete. |
| trashed | `card_list_trashed_light.png` | `card_list_trashed_dark.png` | One card: Undo for 8 seconds (FE-B1 D3, D14). Several: "{n} cards moved to Trash" with Open Trash, no Undo (D4). |
Other goldens: `card_list_search_light.png` / `card_list_search_dark.png` (search open with matches).


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

- **Move to Trash dialog:** no glyph (`MxDialog` has no glyph slot); the body reads "Recoverable from Trash for 30 days, with its schedule and history", since the dialog reads no history count.
- **FE-B2 D14 (critique P1b):** Tags is a filter chip, selected while tags are applied.
- **BR-DECK-015, E-L1:** an empty card list makes the deck unset again; screen 01's unset state shows.
- **E-L2:** the flag uses the warning colour; the theme has no streak token.
- **E-L3:** "Select all" is a compact secondary `MxButton`.
- **E-L4:** the due chip is an `MxBadge`: overdue warning, today primary, else neutral.

## Copy

- Summary: "Deck progress · {algorithm}" · "{n} of {total} cards mastered" · "New" · "Beginning" · "Reviewing" · "Mastered" · "Study this deck · {n} due".
- Filters and header: "All" · "Due" · "New" · "Flagged" · "Tags" · "Showing {n} of {total}" · "{n} of {total} selected" · "Newest first".
- Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · "Export" · "Trash".
- Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move to Trash" · "“{front}” moved to Trash" · "Undo" · "{n} cards moved to Trash".
- Empty: "No cards in this deck yet" · "Write your first card, or bring many at once from a spreadsheet or pasted text." · "Import cards (CSV, TSV, XLSX, text)" · "Studying this deck becomes available once it holds at least one card."
- Search empty: "No cards match “{term}”" · "Try a different term, or clear the search to see all {n} cards."
- Tag filter: "Tags" · "Filter by tags" · "Show cards with any of the chosen tags" · "{k} chosen · cards with any of them" · "Search tags" · "Clear" · "Apply" · "No tags yet. Add tags while creating or editing cards." · "Close" · "Couldn't load tags" · "No cards with these tags" · "Clear tag filter".
- Error: "Couldn't open this deck" · "Your data is safe on this device. Try again in a moment."
- Move: "Move {n} cards to…" · "Schedule, history, flags and tags travel with the cards. Decks in other trees are not offered." · no target: "Nowhere to move these cards" · "No other deck in “{root}” holds cards or is empty. Create an empty sub-deck first; cards can only move within their own tree."
