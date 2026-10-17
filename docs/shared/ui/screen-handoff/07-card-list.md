<!-- Hand-written screen record. -->

# 07 · Card list

An open deck whose content type is `card`: the card section of `DeckLevelScreen`
(Library spec D8). UC-CARD-001, UC-CARD-002.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar`, injected by `app/` (spec A14) | Back, deck name, search action, `⋮` (the deck's action sheet, with Select cards). Selecting: close, "{n} selected", "Select all {count}". |
| Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck; hidden while selecting. |
| Search | `MxSearchField` | Revealed by the search action; closing it clears the term. Hidden while selecting; its term stays and returns with it. |
| Summary card | `MxCard` (hero) + `MxMasteryDonut` + `MxWorkloadBreakdownLine` | "DECK PROGRESS · {algorithm}", "{n} of {total} cards mastered", overdue · today · new; mastery is stated once, with no four-state bar or legend (critique 2026-09-30, R2). "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the deck holds no card to study. Hidden while selecting, and while search is open, so the first results sit above the keyboard (critique 2026-09-30 part 1). |
| Filters | `MxFilterChip` | All · Due · New · Flagged with counts, then Tags with the tag glyph: selected with the count of tags applied, and its tap opens the tag filter (FE-B2 D14). |
| Header | `MxListSectionHeader` + `MxChipTrigger` | "Cards" while every card of the deck shows; "Showing {n} of {total}" (matches of the deck's cards) while a filter, a tag or search narrows it; none while selecting, when the app bar holds the count (critique 2026-09-30 part 3b); sort "Newest ⇅" / "Due first ⇅" (the sort glyph, not a chevron); TalkBack names the trigger "Sort cards, {order}" (e.g. "Sort cards, Newest"). |
| Rows | `MxSelectableCardRow` per row, 8 apart (DEV-304) | The checkbox while selecting (no status dot: the label states the status once, critique 2026-09-30 part 3b, R3); front 16/700 and back 12, one line each; uppercase status label in its text token, up to two `MxTagChip`s and "+{n}"; trailing flag in plain text colour (critique 2026-10-02, F6) and the due chip, an `MxBadge` (E-L4): "New", "Due today", "In {n}d", "{n}d overdue". The status label, tags and "+{n}" wrap at large text. Rows build as they scroll into view (E-L5). |
| Bulk bar | `MxFooterBar` with five icon buttons | Move · Flag · Tag · Export (screen 12; the selection stays) · Trash. |
| FAB | `MxFab` | "New card" (#33); hidden while selecting and while search is open (critique 2026-09-30 part 3d-1). The list ends clear of it (`MxScrollClearance.fabAboveNav`), and drops that clearance while selecting (critique 2026-09-30). |

## Deck action sheet (`⋮`)

Study this deck · Rename · Select cards (enters selection with nothing picked, DEV-307) ·
Move to another deck · Import cards (screen 11) · Export cards (screen 12) · Move to Trash. Study this deck opens the Study Entry, screen 14 (FE-A6 D10).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `card_list_light.png` | `card_list_dark.png` | The Tags chip reads as selected while tags are applied (D14; UI-base row 140). |
| empty | no golden | no golden | The deck is unset again (E-L1): screen 01's unset state. The section's own fallback (no filter, tag or term, and no row) reads "No cards yet" · "The cards you add to this deck show here." with a "New card" action only; it is unreachable by design (E-L1). `open_deck_screen_test.dart::deleting the last card turns the deck into its unset state`. |
| filterEmpty | no golden | no golden | A status filter (Due, New, Flagged) with no card: "No cards under “{filter}”" with "Show all cards" (`cardFilterEmptyTitle`, `cardShowAll`). `card_list_section_test.dart::an empty filter names itself and offers every card`. |
| searchEmpty | `card_list_search_light.png` | `card_list_search_dark.png` | Search open, no match (the copy below). |
| searchResults | `card_list_search_results_light.png` | `card_list_search_results_dark.png` | Two matches with a 300 dp keyboard up: the summary card steps aside (critique 2026-09-30 part 3a). |
| loading | no golden | no golden | Four skeleton rows while the first window loads; a later request keeps the rows already shown (ruling P3-L5). Code read: `card_list_section_widget.dart`. Back while selecting ends the selection first (audit 2026-10-17 CARD-14b). |
| error | no golden | no golden | `MxErrorState` "Couldn't open this deck" · "Nothing was lost. Try again in a moment." with Retry, even over rows loaded before (spec §5). `card_list_section_test.dart::a load error says so plainly and offers Retry`, `::an error after the rows loaded still says so, with Retry`. Back while selecting ends the selection first (audit 2026-10-17 CARD-14b). |
| notFound | no golden | no golden | As screen 01 deckNotFound. |
| deckActions | no golden | no golden | — |
| selection | `card_selection_light.png` | `card_selection_dark.png` | Long-press selects (BR-CARD-020), or Select cards from `⋮` enters selection with nothing picked; Close ends it, unticking the last card does not (DEV-307). Back ends it in every list state, loaded, loading or error. Picks of cards that left the list while picked (deleted, moved elsewhere, or no longer matching the search and filters, the same set Select all reads) drop out when the list changes; a card picked while that read runs stays, so a bulk action is not refused whole for them (audit 2026-10-17 CARD-14a). The app bar carries close, "{n} selected" and "Select all {n}" (A14). |
| moveTargets | no golden | no golden | The deck picker, targets named by path; one move at a time. `card_bulk_actions_test.dart::Move sends the cards to another deck of the root`. |
| moveTargetsLoading | no golden | no golden | `MxDeckPickerLoadingSheet`: title, rule and three skeleton rows. Code read: `card_move_sheet_widget.dart`. |
| moveTargetsError | no golden | no golden | `MxDeckPickerErrorSheet`: "Couldn't open this deck" · "Nothing was lost. Try again in a moment." with Retry and Cancel; the selection stays. Code read: `card_move_sheet_widget.dart`. |
| noMoveTarget | no golden | no golden | "Nowhere to move" · "No other deck here can hold cards." with OK, not Cancel. Code read: `card_move_sheet_widget.dart`. |
| sortSheet | no golden | no golden | "Sort cards": Newest · Due first; a choice applies at once and closes the sheet. Code read: `card_sort_sheet_widget.dart`; the order `card_list_section_test.dart::due first puts the soonest due first and new cards last`. |
| flagSheet | no golden | no golden | "Flag": "Flag cards" or "Remove flag", never a toggle (P3-L4). `card_bulk_actions_test.dart::Flag sets the flag on every selected card`, `::Remove flag clears it, never toggles (P3-L4)`. |
| tagDialog | no golden | no golden | "Add a tag" with the "Tag name" field, Cancel · Add. A name rule stays under the field; any other refusal closes the dialog with a toast and keeps the selection (IT-ORG-014). `card_bulk_actions_test.dart::Tag adds one tag to every selected card`, `::a blank tag stays in the dialog, under the field`. |
| tagFilterLoading | no golden | no golden | The tag filter sheet while the tags load: title, "Show cards with any of the chosen tags", three skeleton rows. Code read: `card_tag_filter_sheet_widget.dart`. |
| tagFilterError | no golden | no golden | The sheet keeps its head; "Couldn't load tags" with Retry, and Close beside it. `card_tag_filter_test.dart::a failed load keeps the sheet head, Retry and a dismiss`. |
| bulkFailed | `card_list_bulk_failed_light.png` | `card_list_bulk_failed_dark.png` | Flag: an inline banner above the bulk bar (E-L6). Move, Tag and Trash keep their sheet or dialog open and say it there. The selection stays. Retry shows the button's loading state while it runs, the banner stays and the bulk bar ignores taps meanwhile. |
| delCard | `card_list_trash_dialog_light.png` | `card_list_trash_dialog_dark.png` | One selected card: the dialog without a glyph, with the card's preview. Several: "Move {n} cards to Trash?" without the preview. The confirm spins while they move (FE-B1 D15). |
| delDeck | no golden | no golden | As screen 01 deckDelete. |
| trashed | `card_list_trashed_light.png` | `card_list_trashed_dark.png` | One card: Undo for 8 seconds (FE-B1 D3, D14). Several: "{n} cards moved to Trash" with Open Trash, no Undo (D4). |

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

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the first window lands | loaded | VERIFIED `card_list_section_test.dart::rows show front, back, a status label, no dot, and the flag (critique 2026-09-30 part 3b, R3)` |
| loading / loaded | the read fails | error | VERIFIED `::a load error says so plainly and offers Retry`, `::an error after the rows loaded still says so, with Retry` |
| error | Retry | loading, then loaded | Retry is on screen in the tests above; the re-read is `UNVERIFIED (code read)`: `card_list_section_widget.dart` invalidates the list provider |
| loaded | tap a filter chip | loaded (narrowed) or filterEmpty; the selection clears | VERIFIED `::each chip counts its filter; a chip filters the rows` |
| filterEmpty | Show all cards | loaded under All | VERIFIED `::an empty filter names itself and offers every card` |
| loaded | tap the search action, type | searchResults or searchEmpty; closing the search clears the term | VERIFIED `::search matches the front or the back`, `::a search with no hit names the term`, `::search hides the deck summary and keeps the filters (critique 2026-09-30: results clear the keyboard)` |
| loaded | TalkBack reaches the sort trigger | named "Sort cards, {order}" | VERIFIED `card_list_section_test.dart::the sort trigger is named as a sort for TalkBack, with the order shown (audit 2026-10-17)` |
| loaded | tap the sort pill | sortSheet; a choice re-orders at once | VERIFIED order only `::due first puts the soonest due first and new cards last`; the sheet `UNVERIFIED (code read)` |
| loaded | scroll near the end | the window grows once per request, the rows kept | VERIFIED `::the window grows near the end and keeps its rows (RF4)`, `::after a new request the window grows again: a growth is asked once per request, not once per screen` |
| loaded | tap the Tags chip | tag filter sheet (loading, none chosen / picker, error) | VERIFIED `card_tag_filter_test.dart::none chosen: every tag with its cards in this deck, 0 included, in the catalog order; Clear is off`; loading `UNVERIFIED (code read)` |
| tag filter | Apply | loaded with the tags applied; the selection clears; no card: "No cards with these tags" | VERIFIED `::one, then several: Apply shows the cards with any of them, and the chip says how many are applied (steps 7-8)`, `::a tag with no card here shows none, and offers to clear the tag filter (A7)` |
| tag filter | dismissed any other way | what was applied stays | VERIFIED `::closing without Apply keeps what was applied (A5)` |
| tag filter | a tag is deleted or merged away | it leaves the applied set | VERIFIED `::a tag deleted meanwhile leaves the applied set (D12)` |
| tag filter error | Retry | loading, then the picker | `UNVERIFIED (code read)`: `card_tag_filter_sheet_widget.dart` invalidates the provider |
| loaded | tap a row | the card detail (screen 10) | `UNVERIFIED (code read)`: `card_list_section_widget.dart` `onOpenCard`; the row's content is VERIFIED above |
| loaded | long-press a row, or Select cards from ⋮ | selection | VERIFIED `card_selection_test.dart::a long-press selects that card`; ⋮ path `deck_action_sheet_test.dart::Select cards shows only from an open deck of cards and enters selection with nothing picked (DEV-307)` |
| selection | tap a row | toggles; unticking the last one keeps the mode | VERIFIED `card_selection_test.dart::a tap toggles; unticking the last one keeps selection` |
| selection | Select all {n} | every card the filter, tags and term let through, beyond the loaded window | VERIFIED `card_deck_app_bar_test.dart::Select all takes every card the term lets through`, `::Select all honours the filter under the search too`, `::Select all stays while a larger window loads` |
| selection | Close, or system Back | loaded; Back leaves selection before the deck | VERIFIED `card_deck_app_bar_test.dart::Close clears the selection; the deck bar returns`, `card_selection_test.dart::system Back leaves selection first (RF5)` |
| selection | Move | moveTargetsLoading, then moveTargets / noMoveTarget / moveTargetsError; on success the selection clears | moveTargets VERIFIED `card_bulk_actions_test.dart::Move sends the cards to another deck of the root`; loading, empty and error `UNVERIFIED (code read)` |
| moveTargets | a second tap on a target while the move runs | one move | `UNVERIFIED (code read)`: `_isMoving` guard in `card_move_sheet_widget.dart` |
| selection | Flag, then Flag cards / Remove flag | the flag is set or cleared; the selection clears, a toast says how many | VERIFIED `card_bulk_actions_test.dart::Flag sets the flag on every selected card`, `::Remove flag clears it, never toggles (P3-L4)` |
| selection | the flag write fails | bulkFailed: the banner above the bar, the selection stays | VERIFIED `card_list_flag_retry_test.dart::while Retry runs the banner stays with a spinning Retry, and neither Retry nor the bulk bar takes a tap (critique 2026-09-30 part 3d-2)` |
| bulkFailed | Retry | the same cards and choice are written again | VERIFIED same test |
| bulkFailed | the selection changes | the banner goes (Retry would write other cards) | `UNVERIFIED (code read)`: `card_list_section_widget.dart` listens to the selection |
| selection | Tag | tagDialog; Add tags every selected card, a toast, the selection clears | VERIFIED `card_bulk_actions_test.dart::Tag adds one tag to every selected card` |
| tagDialog | Add is tapped, and the write runs | the dialog is held: Cancel is off, Back and the scrim wait, Add spins; the write answers with its toast and the selection clears | VERIFIED `card_bulk_actions_test.dart::Tag holds its dialog while it writes: Cancel in the same instant does nothing, and the write still says so` |
| tagDialog | a blank or invalid name | the dialog stays, the reason under the field | VERIFIED `::a blank tag stays in the dialog, under the field` |
| selection | Export | the export sheet over the selection (screen 12); the selection stays | `UNVERIFIED (code read)`: `card_list_section_widget.dart` `onExport`; the router test is in screen 12 |
| selection | Trash | delCard, Cancel keeps the selection | VERIFIED `card_bulk_actions_test.dart::Trash asks with the count; Cancel keeps the selection; several cards get no Undo (FE-B1 D4)` |
| delCard | Move | trashed: one card offers Undo; several offer Open Trash | VERIFIED `::one card shows its text; Undo puts it back (UC-TRASH-001 A1)`, `::Move to Trash spins while the cards move (FE-B1 D15)` |
| trashed | Undo is refused | a toast with the reason; the card stays in the Trash | VERIFIED `::a refused Undo says why; the card stays in the Trash (UC-TRASH-001 E3)` |
| delCard | the move dies on a bug | the dialog is released | VERIFIED `::a move that dies on a bug releases the dialog` |
| loaded | the last card is deleted | screen 01's unset state | VERIFIED `open_deck_screen_test.dart::deleting the last card turns the deck into its unset state` |
| loaded | the deck is deleted elsewhere | notFound | VERIFIED `open_deck_screen_test.dart::a deck deleted while open says it is no longer here and leads back or to the Trash (A8, FE-B1 D11)` |
| any | the FAB | the card editor (screen 08); hidden while selecting and while search is open | VERIFIED `card_list_section_test.dart::New card: the FAB adds, and hides while selecting (P4a-L9)` |

## Rulings

- **Critique 2026-09-30 part 1:** search hides the summary card and keeps the filter row, so a filter still applies to the search and the results clear the keyboard.
- **Move to Trash dialog:** no glyph (`MxDialog` has no glyph slot); the body reads "Recoverable from Trash for 30 days, with its schedule and history", since the dialog reads no history count.
- **FE-B2 D14 (critique P1b):** Tags is a filter chip, selected while tags are applied.
- **BR-DECK-015, E-L1:** an empty card list makes the deck unset again; screen 01's unset state shows.
- **E-L2:** the flag uses the warning colour; the theme has no streak token. Superseded by critique 2026-10-02 (F6): plain text colour.
- **E-L3:** "Select all" is a small secondary `MxButton`.
- **E-L4:** the due chip is an `MxBadge`: overdue warning, today primary, else neutral.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the deck summary's progress line is an eyebrow.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** the add FAB steps aside while search is open; a failed bulk flag's banner offers Retry, repeating the same cards and choice.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** while a failed bulk flag's Retry runs, the banner stays and Retry shows the button's loading state; the bulk bar ignores taps meanwhile. A failure keeps the banner; success clears the selection as before.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain text colour (`onSurface`), the filled glyph carrying the state as in the editor and the detail; E-L2 is superseded (F6).
- **Q-C-1 (owner, 2026-10-16):** the tag filter sheet's subtitle ("N chosen · cards with any of them") keeps each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- Summary: "Deck progress · {algorithm}" · "{n} of {total} cards mastered" · "New" · "Beginning" · "Reviewing" · "Mastered" · "Study this deck · {n} due".
- Filters and header: "All" · "Due" · "New" · "Flagged" · "Tags" · "Cards" · "Showing {n} of {total}" · "Newest" · "Due first".
- Selection: "{n} selected" · "Select all {total}" · "Move" · "Flag" · "Tag" · "Export" · "Trash".
- Move to Trash: "Move this card to Trash?" / "Move {n} cards to Trash?" · "Recoverable from Trash for 30 days, with its schedule and history. Other cards are unaffected." · "Cancel" · "Move" · "“{front}” moved to Trash" · "Undo" · "{n} cards moved to Trash".
- Empty (the section's fallback, unreachable by design E-L1): "No cards yet" · "The cards you add to this deck show here." · "New card". The deck's own empty state is screen 01's unset state.
- Sort: "Sort cards" · "Newest" · "Due first". Flag: "Flag" · "Flag cards" · "Remove flag" · "{n} cards flagged" · "Flag removed from {n} cards". Tag: "Add a tag" · "Tag name" · "Add" · "{n} cards tagged “{tag}”". Bulk failure: "Couldn't finish that." · "Nothing changed. The cards stay selected."
- Search empty: "No card matches “{term}”" · under All "Try a different term, or clear the search to see all {n} cards."; under another filter "Try a different term, or clear the search."
- Filter empty: "No cards under “{filter}”" · "Show all cards".
- Tag filter: "Tags" · "Filter by tags" · "Show cards with any of the chosen tags" · "{k} chosen · cards with any of them" · "Search tags" · "Clear" · "Apply" · "No tags yet. Add tags while creating or editing cards." · "Close" · "Couldn't load tags" · "No cards with these tags" · "Clear tag filter".
- Error: "Couldn't open this deck" · "Nothing was lost. Try again in a moment."
- Move: "Move to deck" · "Cards keep their learning. Only decks that hold cards in this top-level deck are offered." · each target is named by its path · "{n} cards moved to {deck}" · no target: "Nowhere to move" · "No other deck here can hold cards." · "OK". A failed target read: "Couldn't open this deck" · "Nothing was lost. Try again in a moment." · "Retry".
