<!-- Hand-written screen record. -->

# 01 · Deck list

One recursive screen for the Library root (`/decks`) and any open deck
(`/decks/deck/:deckId`): `DeckLevelScreen`. UC-DECK-001…UC-DECK-006.

## Layout — root

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | "Library", then Starter decks (sparkles, screen 03), Tags (tag, screen 05; only with decks, The Content Gate Rule, DEV-309) and Trash (screen 06, always: the way back) (FE-B2 + FE-B4 D2). |
| Search | `MxSearchField`, trigger mode | Hint "Search decks, cards, tags", the same string as screen 04 (`searchFieldHint`; DEV-233). A tap pushes `/decks/search` (screen 04). Only with decks (The Content Gate Rule, DEV-309). |
| Due strip | `MxCard` (hero) + `MxIconTile` + `MxWorkloadBreakdownLine` | Bolt tile on primary, "N cards due", overdue · today (New is not due, BR-STUDY-068). A tap opens Study home; a trailing chevron says so (critique 2026-09-30, R4). Hidden when the library holds no card. |
| Section header | `MxListSectionHeader` + `MxChipTrigger` | "N DECKS"; ghost chip "Manual ⌄", or "Manual · Due only" tinted primary with the filter on. |
| Rows | `MxSelectableCardRow` per deck, 8 apart (DEV-304) | 44 px `MxIconTile` (layers = holds decks, copy = holds cards, folder-open = empty); name on one line with ellipsis; `MxBadge` "N due" when due > 0; meta "N sub-decks · N cards" or "Empty · add cards or a sub-deck"; the mastery bar (`MxLinearProgress.mastery`, 5 tall, 12 under the meta, across the text column, on `surfaceContainerLow`; BR-DECK-026), the bare track for a deck with no card; trailing `⋮` (`MxIconButton`). |
| FAB | `MxFab` | "New deck". |

## Layout — open deck

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back, deck name, `⋮` (the deck's action sheet). |
| Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck. |
| Summary card | `MxCard` (hero) | For a deck holding sub-decks: `MxMasteryDonut` of the level (BR-DECK-026) beside "MASTERED · {algorithm}", "N sub-decks · N cards", overdue · today · new · N scheduled. "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the subtree holds no card to study. |
| List | as root | Header "Sub-decks" with the sort pill: the summary card states the count (critique 2026-09-30 part 3b). TalkBack names the pill as a sort with the order shown, "Sort decks, {order}" (the chip's visible text alone would not say what it does). |
| FAB | `MxFab` | "New sub-deck"; none at level 10 (BR-DECK-001), and none on an `unset` deck, whose empty state offers both choices (R9, critique 2026-09-30 part 1). |
| By content type | — | `unset`: empty state with the two create choices (BR-DECK-007) and "Import cards from a file" (screen 11), all text-only block actions, Import as the outline third. `card`: the card list, screen 07. |

## Action sheet

`MxBottomSheet` headed by the deck's name, and `MxActionSheetCommandRow`s without count
subtitles (ruling C-L6):

- **Root deck:** Open deck · Study this deck → screen 14 · Rename · Study options
  ("Cards per session · new-card order") → screen 15 · Review algorithm
  ("{algorithm} · locked · reset to start over" when locked) → screen 02 · Import cards
  → screen 11 (spec 2026-10-08 U1) · Reorder · Move to Trash ("Recoverable for 30
  days").
- **Sub-deck:** Open · Study this deck → screen 14 · Rename ·
  Select cards (an open deck of cards only, DEV-307) → selection on screen 07 ·
  Study options → screen 15 (its root's options) ·
  Move to another deck · Import cards → screen 11 (every sub-deck, spec 2026-10-08 U1) ·
  Reorder ("Move before or after a sibling") · Move to Trash
  ("Recoverable for 30 days").

## Sort & filter sheet

One `MxBottomSheet`, "Sort & filter":

- Sort by (`MxOptionRow`): Manual order "Drag decks to arrange them" · Date added
  "Newest first" · Name "A → Z" · Most due cards · Progress "Least mastered first"
  (BR-DECK-027).
- Toggle row (`MxSettingsRow` + `MxToggle`): "Only decks with due cards" / "Hides
  decks where nothing is waiting".
- "Sort by" is an `MxListSectionHeader`; Done is the sheet's `MxSheetActions` footer.
- Button "Done".

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| rootLoaded | `library_decks_light.png` | `library_decks_dark.png` | Every row carries its mastery bar (BR-DECK-026); the learning band is the learning fill, `statusLearning` (spec 2026-10-10). The due strip shows its chevron: the fixture wires Study home as the app does (critique 2026-09-30 part 3a). |
| rootInApp | `app_library_light.png` | `app_library_dark.png` | The Library tab inside the real app (`MemoxApp`, on a phone): the root list over the bottom tab bar, every row wired as the app wires it. `test/app/app_golden_test.dart::Library tab, ${brightness.name}`. |
| rootTabletLandscape | `app_tablet_landscape_library_light.png` | `app_tablet_landscape_library_dark.png` | The Library root at 1280 × 800: the navigation rail in place of the bottom bar and the 720 column (FE-C5). `test/app/app_golden_test.dart::tablet $name, ${brightness.name}` with `name` = `landscape_library` (it also runs the tap-target guidelines); `test/app/tab_shell_test.dart::599 wide: the bottom nav; 600 wide: the rail`. |
| deckTabletPortrait | `app_tablet_portrait_deck_light.png` | `app_tablet_portrait_deck_dark.png` | An open deck at 800 × 1280 beside the rail (FE-C5). `test/app/app_golden_test.dart::tablet $name, ${brightness.name}` with `name` = `portrait_deck`; `test/app/tab_shell_test.dart::rotating across 600 keeps the open deck`. |
| rootLoading | no golden | no golden | Skeletons in the row's shape; header kept. The app bar keeps only Starter decks and the Trash (`library_content_gate_test.dart::a loading root keeps only Starter decks and the Trash over the skeleton`). |
| rootEmpty | `library_empty_light.png` | `library_empty_dark.png` | No search field, no Tags, no FAB (The Content Gate Rule, DEV-309); Starter decks and the Trash stay. "Create deck", then "Browse starter decks" (screen 03), and the footnote (FE-B4 §5.4). |
| rootError | no golden | no golden | "Couldn't load your decks" · "Nothing was lost. Try again in a moment." with Retry (Retry spins while the read runs). The app bar keeps only Starter decks and the Trash; the search trigger, Tags and the FAB wait for decks (`library_content_gate_test.dart::a failed root keeps only Starter decks and the Trash over Retry (Review Focus 3)`). |
| rootSearch | no golden | no golden | The field is a trigger: a tap opens screen 04 instead of typing here. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/deck_level_screen_test.dart::the search field opens the search` |
| rootSortFilter | `library_sort_light.png` | `library_sort_dark.png` | Progress orders least mastered first, decks with no card last (BR-DECK-027). |
| rootDueEmpty | no golden | no golden | "Nothing due right now" · "No deck has cards waiting." with "Show all decks"; the filter is on, so this is not the first-run empty state (ruling L4). |
| rootOverflow | `library_deck_actions_light.png` | `library_deck_actions_dark.png` | Rows as in "Action sheet"; Reorder added. |
| rootCreate | no golden | no golden | The create dialog: title "New deck", the "Deck name" field, the Eight boxes / SM-2 segmented tray and a note on the lock; no algorithm chosen up front (BR-SRS-001). A rejected name shows under the field; the confirm is held while the deck is created. |
| rootCreateSchedulerMissing | no golden | no golden | Create pressed with no algorithm: "Choose how the cards are reviewed." under the tray, nothing written (E3). |
| rootCreateDiscard | no golden | no golden | Cancel, Back or a tap outside after typing or choosing: "Discard this deck?" confirm (UC-DECK-001 A1). With nothing typed the dialog closes at once. |
| rootRename | no golden | no golden | The rename dialog: title "Rename deck", the "Deck name" field filled with the current name, confirm "Save". A name rejection stays under the field; any other refusal closes the dialog with a toast (ruling P2-L10). |
| subDeckCreate | no golden | no golden | The new sub-deck dialog (`showCreateSubDeckDialog`, UC-DECK-004): title "New sub-deck", the "Deck name" field, confirm "Create"; the same `DeckNameDialogWidget` as rootRename with another submit (`createSubDeck`), opened from the open deck's FAB or the unset state's "New sub-deck". `open_deck_screen_test.dart::the FAB opens the new sub-deck dialog`; its own write and hold are `UNVERIFIED (code read)`: `deck_name_dialog_widget.dart`. |
| rootDelete | `library_deck_delete_light.png` | `library_deck_delete_dark.png` | Moves to the Trash (UC-TRASH-001). The dialog has no glyph and names the deck in quotes, not bold. The confirm spins while the deck moves (FE-B1 D15). |
| rootTrashed | `library_deck_trashed_light.png` | `library_deck_trashed_dark.png` | Undo for 8 seconds, and until acted on under TalkBack (FE-B1 D3, D14). A refused Undo says why: "Can't undo. {reason} Restore it from Trash and choose a deck." |
| deckLoaded | `library_deck_open_light.png` | `library_deck_open_dark.png` | The level's donut beside "MASTERED · {algorithm}"; the breakdown line wraps between whole terms, never "…" (the Wrap Rule; critique 2026-09-30 part 3b). |
| deckEmpty | `library_deck_unset_light.png` | `library_deck_unset_dark.png` | `unset` deck: both create choices and "Import cards from a file" (screen 11); no FAB (R9, critique 2026-09-30 part 1). |
| deckEmptyTopLevel | no golden | no golden | A top-level deck with no sub-deck cannot hold cards (BR-DECK-005): "This deck is empty" · "Add a sub-deck to start organising it." (`deckRootEmptyBody`) with "New sub-deck" only, as the empty state's action and as the FAB; no Import. Code read: `deck_unset_state_widget.dart`. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/deck_list_state_coverage_test.dart::deckEmptyTopLevel: a top-level deck with no sub-deck says it is empty and offers a sub-deck only; no card, no Import (BR-DECK-005)` |
| deckEmptyDeepest | no golden | no golden | An empty deck at level 10 holds no sub-deck (BR-DECK-001): "This deck is at the deepest level, so it holds cards." (`deckUnsetDeepestBody`) with "New card" and "Import cards from a file" only. `open_deck_screen_test.dart::the deepest deck offers a card only`. |
| deckMaxDepth | no golden | no golden | No FAB. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/open_deck_screen_test.dart::the deepest deck offers a card only`; `deck_list_state_coverage_test.dart::deckMaxDepth: the deck at level 9 keeps its New sub-deck FAB and a level-10 deck with no card has none (BR-DECK-001)`; `::deckMaxDepth: a level-10 deck holding a card offers no New sub-deck FAB either (BR-DECK-001)` |
| deckLoading | no golden | no golden | Skeleton rows under the plain Library bar; the summary card waits for the deck, which the same read brings (`deck_level_screen.dart:244`). Corrected 2026-10-18: the row said the rows stood under the summary card, which the app never drew. VERIFIED `deck_list_state_coverage_test.dart::deckLoading: an open deck whose read has not landed shows skeleton rows under the plain Library bar` |
| deckError | no golden | no golden | "Couldn't open this deck" · "Nothing was lost. Try again in a moment." with Retry. Code read: `deck_level_screen.dart`. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/deck_list_state_coverage_test.dart::deckError: an open deck that cannot be read says so with Retry; Retry reads it again` |
| deckNotFound | no golden | no golden | "This deck is no longer here", Back to Library and Open Trash (FE-B1 D11), a neutral `MxEmptyState` like the card's (owner 2026-10-08); replaces ruling P2-L7. |
| deckOverflow | no golden | no golden | The sub-deck action sheet. |
| deckMove | no golden | no golden | The deck picker; only decks with the same review algorithm receive it (UC-DECK-005). Candidates are named by path; every candidate is held while a move runs. `deck_action_sheet_test.dart::Move lists targets by path and moves there`. |
| deckMoveLoading | no golden | no golden | `MxDeckPickerLoadingSheet`: title, rule and three skeleton rows. Code read: `deck_move_sheet_widget.dart`. |
| deckMoveError | no golden | no golden | `MxDeckPickerErrorSheet`: "Couldn't load your decks" with Retry and Cancel. Code read: `deck_move_sheet_widget.dart`. |
| deckMoveEmpty | no golden | no golden | "Nowhere to move" · "No other deck can hold this one." with OK, not Cancel (ruling O11). `deck_action_sheet_test.dart::with nowhere to go, the picker says so and offers OK`. |
| deckDelete | no golden | no golden | As rootDelete. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/deck_action_sheet_test.dart::Move to Trash says what goes with the deck, then offers Undo (FE-B1)` |
| deckTrashed | no golden | no golden | As rootTrashed. Moving the open deck steps back to its parent first (C-L5); the toast survives the step back. VERIFIED (closing acceptance 2026-10-18): `library_routes_test.dart::deleting the open deck returns to its parent once (RF1)`; `deck/presentation/deck_action_sheet_test.dart::Move to Trash says what goes with the deck, then offers Undo (FE-B1)` |
| deleteSummaryPending | no golden | no golden | The Move to Trash dialog before the count is read: no body, no note, the confirm disabled. Code read: `deck_delete_dialog_widget.dart`. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/deck_list_state_coverage_test.dart::deleteSummaryPending: before the count is read the Move to Trash dialog has no body, no note and a disabled confirm` |
| deleteSummaryFailed | no golden | no golden | The count is rejected or its read fails: the body says why (the rejection or the failure message) and the confirm stays disabled; Cancel closes. Code read: `deck_delete_dialog_widget.dart`. VERIFIED (closing acceptance 2026-10-18): `deck/presentation/deck_list_state_coverage_test.dart::deleteSummaryFailed: a rejection says why in the dialog body; the confirm stays disabled and Cancel closes` |
| deckActionsGone | no golden | no golden | The ⋮ of a row or of the open deck on a deck deleted meanwhile: no sheet, the toast "This deck is no longer here". `deck_action_sheet_test.dart::a row’s actions on a vanished deck say so`. |
| rootReorder | `library_reorder_light.png` | `library_reorder_dark.png` | Reorder mode: one `MxCard` per deck with a drag handle; "Done" replaces the app bar actions; the search field, due strip, sort pill and FAB are hidden (critique 2026-09-30 part 3d-2). A drop saves at once; a refused drop snaps back with a toast. |
| deckReorder | no golden | no golden | The same mode inside an open deck of decks: "Done" in the app bar, the FAB hidden. `deck_reorder_test.dart::Done ends the mode and brings back the FAB`. |

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| rootLoading | the level lands | rootLoaded, or rootEmpty with no deck | VERIFIED `deck_level_screen_test.dart::loading shows skeleton rows`, `::a deck made elsewhere appears without a reload (RF2)`; the chrome follows the same state in one frame `library_content_gate_test.dart::scenario C: the first deck brings the search field, Tags and the FAB in the same frame as its row` |
| rootLoading | the read fails | rootError | VERIFIED `deck_level_screen_test.dart::a load error offers Retry, in plain words` |
| rootError | Retry | rootLoading, then rootLoaded / rootEmpty | VERIFIED `deck_level_screen_test.dart::Retry after a load error loads the level again` |
| deckError | Retry | deckLoading, then the deck | `UNVERIFIED (code read)`: `deck_level_screen.dart` invalidates `deckViewProvider`; no test taps it |
| rootEmpty | Create deck | the create dialog (rootCreate) | VERIFIED `library_content_gate_test.dart::first run: an empty Library offers to create a deck` |
| rootEmpty | Browse starter decks | screen 03 | VERIFIED `library_content_gate_test.dart::rootEmpty offers a starter deck beside Create deck (spec §5.4)` |
| rootLoaded | tap the FAB | rootCreate | VERIFIED `deck_level_screen_test.dart::the FAB opens the create dialog` |
| rootCreate | Create with a name and an algorithm | the dialog closes; the new deck's row appears | VERIFIED `create_root_deck_dialog_widget_test.dart::a name and SM-2 create a root deck and close the dialog`, `::the keyboard Done action creates the deck` |
| rootCreate | Create with a blank or over-long name | the dialog stays, the reason under the field | VERIFIED `::a blank name is refused under the field; nothing is written`, `::a name longer than 200 characters is refused` |
| rootCreate | Create with no algorithm | rootCreateSchedulerMissing; nothing written | VERIFIED `::no scheduler is chosen up front; Create without one says so and writes nothing (BR-SRS-001, E3)` |
| rootCreate | a second tap on Create while it runs | one deck | VERIFIED `::a double tap on Create makes one deck (RF3)` |
| rootCreate | a second tap on Create in the same frame, before the busy confirm is drawn | one deck (REG-DOUBLE-SUBMIT) | VERIFIED `deck_held_scope_test.dart::a second tap in the same frame does not create two decks (UC-DECK-001)` |
| rootCreate | the write fails | the dialog stays, a toast says why | VERIFIED `::a database failure keeps the dialog and says so plainly (RF4)` |
| rootCreate | Cancel, Back or a tap outside, nothing typed | the dialog closes | VERIFIED `::Cancel with nothing typed closes at once (A1)` |
| rootCreate | Cancel, Back or a tap outside, form started | rootCreateDiscard; Keep editing returns, Discard closes and writes nothing | VERIFIED `::Cancel after typing asks first: Keep editing keeps the name, Discard closes and writes nothing (A1)`; Back and the outside tap share `_leave()`: `UNVERIFIED (code read)` |
| rootCreate | the dialog is left while Create runs | no state set after the dialog is gone | `UNVERIFIED (code read)`: `create_root_deck_dialog_widget.dart` returns on `!mounted` |
| rootLoaded | tap a deck row | deckLoaded (the deck opens) | VERIFIED `open_deck_screen_test.dart::a deck of decks lists its sub-decks; a row opens its deck` |
| rootLoaded | tap the due strip | Study home | VERIFIED `deck_level_screen_test.dart::the due strip is a button to Study home (critique 2026-09-30, R4)` |
| rootLoaded | tap the search field | screen 04 | VERIFIED `deck_level_screen_test.dart::the search field opens the search` |
| rootLoaded | tap Starter decks / Tags / Trash | screens 03 / 05 / 06 | VERIFIED `deck_level_screen_test.dart::the root app bar holds Starter decks, Tags and Trash, as kit 01 draws it; nothing waits under Coming soon (spec D2)` for the bar; the taps are `UNVERIFIED (code read)` |
| rootLoaded | tap the sort pill, choose a sort | rootSortFilter; the list re-orders at once | VERIFIED `deck_level_screen_test.dart::sort by name reorders the decks`, `::sort by progress puts the least mastered first and the empty deck last (BR-DECK-027)` |
| rootSortFilter | turn on "Only decks with due cards", Done | rootLoaded with idle decks hidden, or rootDueEmpty | VERIFIED `deck_level_screen_test.dart::the due filter hides idle decks and says so when none is left` |
| rootDueEmpty | Show all decks | rootLoaded | VERIFIED same test |
| rootLoaded (filter on) | the last deck is deleted | rootEmpty, not rootDueEmpty | VERIFIED `library_content_gate_test.dart::the last deck under "Due only" leaves the first-run empty state, not "Nothing due" (Review Focus 1)` |
| rootLoaded / deckLoaded | tap ⋮ on a row or the open deck | rootOverflow / deckOverflow | VERIFIED `deck_action_sheet_test.dart::a row’s ⋮ opens that deck’s sheet, with Open first` |
| rootOverflow | the deck was deleted meanwhile | deckActionsGone | VERIFIED `deck_action_sheet_test.dart::a row’s actions on a vanished deck say so` |
| rootOverflow | Rename, then Save | the name changes in place | VERIFIED `deck_name_dialog_widget_test.dart::rename starts from the current name and saves the new one`, `deck_action_sheet_test.dart::Rename renames the open deck` |
| rootRename | a blank name | the dialog stays, the reason under the field | VERIFIED `deck_name_dialog_widget_test.dart::a blank name stays in the dialog, under the field` |
| rootRename | the deck is gone | the dialog closes, a toast says so | VERIFIED `deck_name_dialog_widget_test.dart::a deck gone meanwhile closes the dialog and says so (P2-L10)` |
| rootRename | a second tap on Rename in the same frame | one rename (REG-DOUBLE-SUBMIT) | VERIFIED `deck_held_scope_test.dart::a second tap in the same frame does not rename twice (UC-DECK-004)` |
| deckOverflow | Move to another deck | deckMoveLoading, then deckMove / deckMoveEmpty / deckMoveError | deckMove and deckMoveEmpty VERIFIED (`deck_action_sheet_test.dart::Move lists targets by path and moves there`, `::with nowhere to go, the picker says so and offers OK`); loading and error `UNVERIFIED (code read)` |
| deckMoveError | Retry | deckMoveLoading, then the targets | `UNVERIFIED (code read)`: `deck_move_sheet_widget.dart` invalidates the targets provider |
| deckMove | tap a target | the sheet closes, the toast "Moved to {deck}" (or the rejection) | VERIFIED `deck_action_sheet_test.dart::Move lists targets by path and moves there` |
| deckMove | a second tap on a target while the move runs | one move | VERIFIED `deck_action_sheet_test.dart::a double tap on a move target moves once (RF2)` |
| rootOverflow | Move to Trash, Move | rootTrashed; the row leaves the list | VERIFIED `deck_action_sheet_test.dart::Move to Trash says what goes with the deck, then offers Undo (FE-B1)`; the spinner and a single move `::Move to Trash spins while the deck moves, and moves once (FE-B1 D15)` |
| deckOverflow (open deck) | Move to Trash, Move | the parent level; the toast with Undo stays | VERIFIED `test/app/library_routes_test.dart::deleting the open deck returns to its parent once (RF1)` |
| rootDelete | the count is pending, rejected or fails | deleteSummaryPending / deleteSummaryFailed; Move stays disabled | `UNVERIFIED (code read)`: `deck_delete_dialog_widget.dart` |
| rootDelete | the delete throws a failure | the dialog stays, a toast says why | `UNVERIFIED (code read)`: `deck_delete_dialog_widget.dart` |
| rootTrashed | Undo within 8 seconds | the deck is back where it was | VERIFIED `deck_action_sheet_test.dart::Undo puts the deck back where it was (UC-TRASH-001 A1)` |
| rootTrashed | Undo is refused | a toast with the reason and Open Trash; the deck stays in Trash | VERIFIED `deck_action_sheet_test.dart::a refused Undo says why; the deck stays in the Trash (UC-TRASH-001 E3)` |
| rootTrashed | the screen is left before Undo | Undo still works | The toast lives on the root navigator and reads the app container: VERIFIED for the open-deck step back by `library_routes_test.dart` above; the Undo after a step back is `UNVERIFIED (code read)` |
| rootOverflow | Reorder | rootReorder | VERIFIED `deck_reorder_test.dart::Reorder is offered for a manual level of two decks or more`, `deck_action_sheet_test.dart::Reorder from the sheet shows the drag handles` |
| rootReorder | drop a deck | the dropped order shows at once and is saved | VERIFIED `deck_reorder_test.dart::dragging a deck past the next one saves the new order` |
| rootReorder | a drop is refused | the order snaps back, a toast says why | VERIFIED `deck_reorder_test.dart::a refused drop snaps back and says why (RF3)` |
| held write (rootCreate, rootRename, deckMove, rootDelete, rootReorder) | a bug (not a `Failure`) | released with the toast "Nothing was lost, but something went wrong. Try again." (`failureUnknown`); the bug is reported. The dialog or sheet is no longer held and Back closes it (rootCreate asks to discard first); a drop snaps back to the stored order and the list follows the level again | VERIFIED `deck_held_bug_test.dart::a create that dies on a bug releases the new-deck dialog (UC-DECK-001)`, `::a rename that dies on a bug releases the name dialog (UC-DECK-004)`, `::a move that dies on a bug releases the deck sheet (UC-DECK-005)`, `::a delete that dies on a bug releases the dialog (FE-B1)`, `::a drop that dies on a bug snaps back to the stored order and follows the level again (RF3)` |
| rootDelete, deckMove | a bug after the write landed (here its toast) | the dialog or sheet closes as after any landed write; nothing offers the write again; the bug reaches the framework (REG-HELD-SCOPE) | VERIFIED `deck_held_scope_test.dart::a delete that landed closes its dialog though its toast fails (FE-B1)`, `deck_held_scope_test.dart::a move that landed closes its sheet though its toast fails (UC-DECK-005)` |
| rootReorder | the level updates while a drop saves | the dropped order stays | VERIFIED `deck_reorder_test.dart::a level update while a drop saves keeps the dropped order` |
| rootReorder | Done | rootLoaded with the FAB and the search field back | VERIFIED `deck_reorder_test.dart::Done ends the mode and brings back the FAB`, `::reorder hides the search field; Done brings it back (critique 2026-09-30 part 3d-2, E3)` |
| deckLoaded | tap "Study this deck" | screen 14 | VERIFIED `open_deck_screen_test.dart::a deck of decks leads with its summary and its Study (FE-A6 D10)` |
| deckLoaded | tap a breadcrumb segment | that level, the root as null | VERIFIED `open_deck_screen_test.dart::a breadcrumb tap reports that level, the root as null` |
| deckEmpty | add the first card or sub-deck | deckLoaded for the content type chosen; deleting the last card returns to deckEmpty | VERIFIED `open_deck_screen_test.dart::deleting the last card turns the deck into its unset state` |
| deckLoaded | the open deck is deleted elsewhere | deckNotFound; Back to Library or Open Trash | VERIFIED `open_deck_screen_test.dart::a deck deleted while open says it is no longer here and leads back or to the Trash (A8, FE-B1 D11)` |
| deckLoading | the deck lands, fails or is gone | deckLoaded / deckError / deckNotFound | deckNotFound VERIFIED in the test above; the others `UNVERIFIED (code read)`: `deck_level_screen.dart` |

Transitions added by the audit of 2026-10-17:

| From | Event | To | Evidence |
|---|---|---|---|
| rootReorder / deckReorder | system Back | rootLoaded / deckLoaded: the list in browse mode, still on the screen (`PopScope` in `DeckLevelBodyWidget`, LIB-7) | `deck_reorder_test.dart` |
| rootLoaded / deckLoaded | `⋮` on a row or on the open deck, and the deck's view fails to read | the failure's sentence as a toast, no sheet (LIB-9) | `deck_level_screen_test.dart` |
| rootLoaded / deckLoaded | TalkBack reaches the sort pill | named "Sort decks, {order}" (e.g. "Sort decks, Manual order") | VERIFIED `deck_sort_trigger_test.dart::the sort trigger is named as a sort for TalkBack, with the order shown (audit 2026-10-17)` |
| rootCreate | Create is tapped, and the write runs | the dialog is held: Cancel is off, Back and the scrim wait, Create spins; it closes when the write answers | VERIFIED `create_root_deck_dialog_widget_test.dart::while Create writes, the dialog is held, Cancel is off and Create spins (M3 B2: every async confirm)` |
| rootRename / subDeckCreate | the confirm is tapped, and the write runs | the same hold: Cancel off, the confirm spins | rename VERIFIED `deck_name_dialog_widget_test.dart::while the name saves, the dialog is held, Cancel is off and the confirm spins (M3 B2: every async confirm)`; the new sub-deck dialog is the same `DeckNameDialogWidget` with another submit: `UNVERIFIED (code read)` for its own run |

## Rulings

- **Critique 2026-09-30 part 1, R9 (amends P4a-L9):** an `unset` deck has no FAB; its empty state already offers New card and New sub-deck. The FAB returns once the deck holds sub-decks.
- **FE-B1 D7:** an Undo happens where the item was deleted. A refused Undo says
  "Can't undo. {reason} Restore it from Trash and choose a deck."; it carries no deck name.
- **Owner ruling R4, amended 2026-10-10:** the < 34% mastery band is the learning
  fill, `statusLearning` (#FF983A), in both themes; on Day's track it is a recorded
  contrast exception (spec 2026-10-10 D3).
- **§9 rows 142, 145 (FE-C1):** the mastery bar's track is `surfaceContainerLow`.
- **Library spec D7:** Reorder is in the root deck's action sheet too.
- **C-L6:** the action sheet reads only `DeckView`, which carries no counts, so its header
  is the name alone.
- **M3 review 2026-09-28 D2:** reorder mode keeps one `MxCard` per deck, 8 apart, as in
  browse mode.
- **Critique 2026-09-30:** a row's meta and the due strip's breakdown wrap at large text, between whole terms; only the deck name keeps one line.
- **Owner 2026-10-16 (Q-P6-4):** the row's structure line ("4 sub-decks · 1,248 cards") is laid out by the shared `MxTermLine`, as the breakdown line is, so it breaks only between its terms and no dot ends a line (spec W1, 2026-10-20).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the deck summary's progress line is an eyebrow (12/600 muted); the list headers stay section labels.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the recent sort is labelled "Date added" (vi "Ngày tạo") with the hint "Newest first"; the search field is hidden while decks are reordered, as the summary, the due strip and the sort pill are, and returns with Done.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the due strip's breakdown is overdue · today, the two halves of its total; New stays on each deck row (BR-STUDY-068).
- **Owner 2026-10-16 (Q-P6-4):** the summary card's "N sub-decks · N cards" uses the same `deckStructureLine` as the rows, and the breakdown's fallback ("N cards · nothing due") is split into terms when it wraps, so neither splits a count from its noun; the empty row line keeps its words breakable with each dot on the word before it (`metaDots`).
- **Q-C-1 (owner, 2026-10-16):** the action sheet's hints (Study options, a locked Review algorithm) keep each dot on the phrase before it and wrap as words (`metaDots`); they are capped at two lines, where `metaDots`, never `metaLine`, is allowed (06) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Pending

| Element | Shown as | Waits for |
|---|---|---|
| Level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks at level 10 | absent; the header says "· level 10" | a later phase (owner decision C-O6) |

## Copy

- Root: "Library" · "Search decks, cards, tags" · "{n} cards due" · "{n} decks" · "Manual" · "Manual · Due only" · "New deck".
- Row: "{n} due" · "{n} sub-deck(s)" · "{n} cards" · "Empty · add cards or a sub-deck" · "More actions for {name}" · "{n}% mastered" (TalkBack only).
- Summary: "Mastered · {algorithm}".
- Sort: "Progress" · "Least mastered first".
- First launch: "Start your library" · "Organize your cards into decks. Create your own or start with a ready-made collection." · "Create deck" · "Browse starter decks" · "Everything stays on this device. Nothing is added until you choose."
- Error: "Couldn't load your decks" · "Nothing was lost. Try again in a moment." An open deck that fails reads "Couldn't open this deck" with the same body.
- Due filter, none: "Nothing due right now" · "No deck has cards waiting." · "Show all decks".
- Create: "New deck" · field label "Deck name" · "Eight boxes" / "SM-2" (a segmented tray, no descriptions) · "The scheduler locks after the first review. Changing it later resets learning progress." · "Cancel" · "Create". No algorithm is chosen up front; Create without one says "Choose how the cards are reviewed." (BR-SRS-001, UC-DECK-001 E3). Cancel, Back or a tap outside after typing asks "Discard this deck?" · "What you typed is not saved." · "Keep editing" · "Discard" (UC-DECK-001 A1). A new sub-deck uses "New sub-deck" over the same field, with "Create".
- Rename: "Rename deck" · field label "Deck name" · "Cancel" · "Save". The dialog has no body text.
- Empty deck: "What goes in here?" · "Add cards to study them here, or nest sub-decks to organise further. A deck holds one or the other." · "New card" · "New sub-deck" · "Import cards from a file" · "The first card or sub-deck decides what this deck holds. Once it is empty again, both options come back." A top-level deck: "This deck is empty" · "Add a sub-deck to start organising it." At level 10: "This deck is at the deepest level, so it holds cards."
- Not found: "This deck is no longer here" · "It was moved to Trash or deleted while you were away. Anything in Trash can still be restored." · "Back to Library" · "Open Trash".
- Move to Trash: "Move to Trash" · "Recoverable for 30 days" · "Move this deck to Trash?" · "“{name}” goes to Trash with its {n} sub-decks and {n} cards." (the sub-deck and card phrases read "no sub-decks", "1 card" at 0 and 1) · "Recoverable from Trash for 30 days. Any open study session on these cards ends." · "Cancel" · "Move" · "“{name}” moved to Trash · {n} sub-decks, {n} cards" · "Undo".
- Move: "Move to deck" · "The deck moves with everything in it. Decks that can't hold it aren't offered." · each target is named by its path · "Moved to {deck}" · empty: "Nowhere to move" · "No other deck can hold this one." · "OK". A failed target read: "Couldn't load your decks" · "Nothing was lost. Try again in a moment." · "Retry".
- Sort & filter: as in "Sort & filter sheet".
