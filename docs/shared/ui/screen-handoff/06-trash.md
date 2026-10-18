<!-- Hand-written screen record. -->

# 06 · Trash

Everything deleted in the last 30 days, newest first. Each entry can be restored to a
place the person picks, or deleted for good. UC-TRASH-001; spec
[2026-09-26-trash-ui-design.md](../../../superpowers/specs/2026-09-26-trash-ui-design.md)
§6.

## Entry points

- **The Library's app bar:** the Trash icon, after Starter decks and Tags; it stays when the Library is empty (D1, screen 01).
- **Toasts:** the toast after several cards move to the Trash, and every refused Undo,
  both through "Open Trash" (D4, UC-TRASH-001 E3).
- **Gone states:** the "no longer here" states of an open deck, the card editor and the
  card detail, through "Open Trash" (D11).

The Trash is a full-screen task on the root navigator, `/decks/trash`, with no bottom
bar (D2). Opening it runs the auto-purge, as the app's start and every resume do (D5).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back, "Trash" and "Select" (a small secondary `MxButton`; hidden when the Trash is empty). While selecting: close, then "Select entries", "{n} cards selected" or "{n} decks selected". |
| Note | `MxNote` (history icon), dismissible | "Kept for 30 days from deletion, then removed automatically. Restoring asks where the item should go." Hidden while selecting. |
| Filters | `MxFilterChip` × 3 | All · Cards · Decks, each with its count (A6). Hidden while selecting. |
| Header | `MxListSectionHeader` | "{n} entries · newest first"; while selecting, the kind's total, "{m} cards" or "{m} decks": the title states the selection (critique 2026-09-30 part 3b). |
| Rows | `MxSelectableCardRow` per entry (DEV-304) | The kind's tile (a checkbox while selecting). The name ("front · back" for a card), and the time left on the right: a warning `MxBadge` under 3 days, grey text otherwise. Then "Card · deleted {ago}" or "Deck · {n} sub-decks · {m} cards · deleted {ago}" (up to two lines), then "Was in {path}" or "Was in Top level", 8 apart. Then `⋮`. While selecting, an entry of the other kind is dimmed to 0.38. The row is one TalkBack node with every fact (D15). |
| Kind lock | `MxNote` | "Cards and decks can't be selected together." |
| Blocked purge | `MxInlineBanner` (warning) | One per batch the last purge skipped (D6). |
| Bar | `MxFooterBar` + `MxActionPair` | While selecting: "Restore ({n})" (primary) · "Delete ({n})" (destructive), side by side; from 1,000 selected items they may stack (see Rulings). Both are disabled until a pick. |
| Actions | `MxBottomSheet` + `MxActionSheetCommandRow` × 2 | The name and "{kind} · deleted {ago} · was in {deck}"; "Restore…" / "Choose which deck it goes to"; "Delete permanently" / "Cannot be undone · history lost" (destructive). |
| Restore | `MxDeckPickerSheet` | "Restore “{name}” to…" or "Restore {n} cards/decks to…", the rule, then the targets as paths, or the single "Top level" for top-level decks. With no target: "Nowhere to restore right now", why, and OK. |
| Delete for good | `MxDialog` + `MxSheetActions.custom` | "Delete {n} cards permanently?", "They disappear for good, together with their study history. This cannot be undone.", "Keep in Trash" (primary, focused) · "Delete" (destructive, spinning while it runs), 1 : 1 (DEV-179). |
| Toasts | `MxSnackbar` | "“{name}” restored to {deck}" / "{n} entries restored to {deck}"; "{n} cards deleted permanently". |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| all | `trash_all_light.png` | `trash_all_dark.png` | The tile is tinted, and "Was in" has no glyph. |
| cards | no golden | no golden | The Cards chip: only cards; `trash_screen_test.dart::each filter counts its kind and shows only it (A6)`. |
| decks | no golden | no golden | The Decks chip, as above. |
| actions | `trash_actions_light.png` | `trash_actions_dark.png` | A row tap opens it too. |
| restoreTarget | `trash_restore_target_light.png` | `trash_restore_target_dark.png` | Targets read as paths, without counts or "where it was". The targets follow the store while the sheet is open (`trash_restore_test.dart::the targets follow the store while the sheet is open (E2)`). |
| noTarget | `trash_no_target_light.png` | `trash_no_target_dark.png` | As the move sheets draw it: the neutral folder, and a filled OK. |
| restored | no golden | no golden | The sheet closes and the toast names the entry or the count and the deck; a selection ends. `trash_restore_test.dart::a card goes back into a deck the person picks (UC-TRASH-001 steps 5-7)`, `trash_selection_test.dart::Restore 2… asks one target for both, then ends the selection (UC-TRASH-001 A2)`. |
| restoring | no golden | no golden | The sheet is held: every target is disabled until the write lands, a second tap does nothing. Code read: `trash_restore_sheet_widget.dart`. |
| restoreTargetsLoading | no golden | no golden | `MxDeckPickerLoadingSheet` with the title and three skeleton rows (the rule is unknown until the targets load). Code read: `trash_restore_sheet_widget.dart`. |
| restoreTargetsError | no golden | no golden | `MxDeckPickerErrorSheet`: "Couldn't open Trash" with Retry and Cancel. Code read: `trash_restore_sheet_widget.dart`. |
| restoreRefused | no golden | no golden | The restore is refused: the sheet closes with the rejection as a toast and the list follows the store (spec §6). A failure keeps the sheet and shows the failure toast. Code read: `trash_restore_sheet_widget.dart`. |
| undoRefused | no golden | no golden | Shown where the item was deleted, with Open Trash (UI-base row 109). VERIFIED (closing acceptance 2026-10-18): `trash_routes_test.dart::a refused Undo opens the Trash (UC-TRASH-001 E3)`; `deck/presentation/deck_action_sheet_test.dart::a refused Undo says why; the deck stays in the Trash (UC-TRASH-001 E3)` |
| selection | `trash_selection_light.png` | `trash_selection_dark.png` | "Restore ({n})" · "Delete ({n})" as a filled destructive button, the note hidden, the other kind dimmed (owner 2026-09-26). |
| selectionNone | no golden | no golden | "Select" or a long-press started the mode and nothing is picked: "Select entries" in the bar, both footer buttons disabled, every row selectable. `trash_selection_test.dart::Select starts with nothing chosen; the first pick locks the kind (BR-TRASH-011)`. |
| kindLock | no golden | no golden | After the first pick: "Cards and decks can't be selected together." above the list, the other kind dimmed and not tappable, the retention note hidden. `trash_selection_test.dart::while selecting, the retention note hides and one line says why the other kind waits`, `::while cards are selected, a deck row is dimmed and a card row is not`. |
| selectionShrinks | no golden | no golden | A picked entry leaves the Trash (it expired): the count and the header follow, no stale count. `trash_selection_test.dart::a picked entry that leaves the Trash leaves every count`. |
| selectionEmptied | no golden | no golden | Every entry leaves the Trash while selecting (expiry, a purge elsewhere): the selection ends and the empty state shows under the plain app bar (audit 2026-10-17 TRASH-1). `trash_selection_test.dart::selection ends when the last entry leaves the Trash`. |
| purgeConfirm | `trash_purge_confirm_light.png` | `trash_purge_confirm_dark.png` | No glyph, left-aligned (UI-base row 108). |
| purged | no golden | no golden | The dialog closes and "{n} cards deleted permanently" (or decks) shows; nothing shows when the store skipped every batch. `trash_selection_test.dart::Delete for good names the count, focuses Keep in Trash, and deletes only on its own button (BR-TRASH-011)`. |
| purging | no golden | no golden | Delete spins, Keep in Trash and Back wait; nothing is deleted behind a closed dialog. `trash_selection_test.dart::while the purge runs, Keep in Trash and Back wait for it; nothing is deleted behind a closed dialog`. |
| purgeFailed | no golden | no golden | The purge fails: the dialog stays, the failure toast shows, Delete is usable again. Code read: `trash_purge_dialog_widget.dart`. VERIFIED (closing acceptance 2026-10-18): `trash/presentation/trash_state_coverage_test.dart::purgeFailed: a purge that fails keeps the dialog, shows the failure toast and makes Delete usable again` |
| youngerInside | `trash_purge_blocked_light.png` | `trash_purge_blocked_dark.png` | "deleted earlier", in a warning banner, one per batch the purge skipped and that is still in the Trash, above the list (D6); the banners stay through the filter and the selection until the next purge or restore (audit 2026-10-17 LIB-11). `trash_selection_test.dart::a purge the store skips names what it still holds (spec D6)`. |
| noteDismissed | no golden | no golden | After "Hide this note" the retention note is gone and stays gone on this device. `trash_screen_test.dart::the retention note can be hidden, and stays hidden (critique 2026-09-30)`. |
| empty | `trash_empty_light.png` | `trash_empty_dark.png` | — |
| loading | no golden | no golden | Skeleton rows. `trash_screen_test.dart::while the entries load, skeleton rows stand in`. |
| error | `trash_error_light.png` | `trash_error_dark.png` | The app's local-first body, "Nothing was lost. Try again in a moment." |

Goldens: `test/features/trash/presentation/goldens/trash_{all,actions,restore_target,no_target,selection,purge_confirm,purge_blocked,empty,error}_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (entry) | the Trash opens | loading; the auto-purge runs once, a failure leaves the list as it is | `UNVERIFIED (code read)`: `trash_screen.dart` `initState`; the purge itself is `trash_selection_test.dart::a picked entry that leaves the Trash leaves every count` |
| loading | the entries land | all (or empty when none) | VERIFIED `trash_screen_test.dart::entries read newest first with their kind, age, time left and origin (UC-TRASH-001 step 3)`, `::an empty Trash says so, with no note and no filters` |
| loading | the read fails | error | VERIFIED `::a failed read says so; Retry reads again (E5)` |
| error | Retry | loading, then all / empty | VERIFIED same test |
| all | choose Cards / Decks / All | cards / decks / all | VERIFIED `::each filter counts its kind and shows only it (A6)` |
| all | tap a row or ⋮ | actions | VERIFIED `::⋮ offers Restore… and Delete permanently for its entry`; the row tap shares `_openActions`: `UNVERIFIED (code read)` |
| actions | Restore… | restoreTargetsLoading, then restoreTarget / noTarget / restoreTargetsError | restoreTarget and noTarget VERIFIED `trash_restore_test.dart::a card goes back into a deck the person picks (UC-TRASH-001 steps 5-7)`, `::with nowhere to go, the sheet says why and offers OK (E1)`; loading and error `UNVERIFIED (code read)` |
| restoreTargetsError | Retry | restoreTargetsLoading, then the targets | `UNVERIFIED (code read)`: `trash_restore_sheet_widget.dart` invalidates the targets provider |
| restoreTarget | tap a target | restoring, then restored | VERIFIED `trash_restore_test.dart::a card goes back into a deck the person picks (UC-TRASH-001 steps 5-7)`, `::a top-level deck goes back to the top level, which the person still confirms (BR-TRASH-006)`, `::a sub-deck goes under a deck that could take it by a move` |
| restoring | a second tap on a target | ignored | `UNVERIFIED (code read)`: `_isRestoring` guard |
| restoring | the restore is refused or fails | restoreRefused | refusal copy VERIFIED `trash_rejection_message_test.dart`; the sheet behaviour `UNVERIFIED (code read)` |
| restoreTarget | the last target disappears while open | noTarget | VERIFIED `::the targets follow the store while the sheet is open (E2)` |
| noTarget | OK | the Trash, nothing restored | VERIFIED `::with nowhere to go, the sheet says why and offers OK (E1)` |
| actions | Delete permanently | purgeConfirm | `UNVERIFIED (code read)`: `trash_screen.dart`; the dialog is VERIFIED through the selection path below |
| all | tap Select, or long-press a row | selectionNone / selection with that row | VERIFIED `trash_selection_test.dart::Select starts with nothing chosen; the first pick locks the kind (BR-TRASH-011)`, `::a long-press starts the selection with its entry (spec D8)` |
| selectionNone | pick the first entry | selection + kindLock | VERIFIED same first test |
| selection | tap an entry of the other kind | nothing | VERIFIED `::while cards are selected, a deck row is dimmed and a card row is not` |
| selection | tap Restore ({n}) | the restore sheet for the whole selection; on success the selection ends | VERIFIED `::Restore 2… asks one target for both, then ends the selection (UC-TRASH-001 A2)` |
| selection | tap Delete ({n}) | purgeConfirm | VERIFIED `::Delete for good names the count, focuses Keep in Trash, and deletes only on its own button (BR-TRASH-011)` |
| selection | close or Back | all, the mode left before the screen is | `UNVERIFIED (code read)`: `trash_screen.dart` `PopScope`; the close glyph's label is in the bar |
| selection | a picked entry expires | selectionShrinks | VERIFIED `::a picked entry that leaves the Trash leaves every count` |
| selection | every entry leaves | selectionEmptied: selection ends, plain app bar | VERIFIED `trash_selection_test.dart::selection ends when the last entry leaves the Trash` |
| purgeConfirm | Keep in Trash | the Trash, nothing deleted | VERIFIED `::Delete for good names the count, focuses Keep in Trash, and deletes only on its own button (BR-TRASH-011)` |
| purgeConfirm | Delete | purging, then purged; the selection ends | VERIFIED `::while the purge runs, Keep in Trash and Back wait for it; nothing is deleted behind a closed dialog` |
| purging | the store skips a batch | purged for the rest, youngerInside for the skipped | VERIFIED `::a purge the store skips names what it still holds (spec D6)` |
| purging | the purge fails | purgeFailed | `UNVERIFIED (code read)`: `trash_purge_dialog_widget.dart` |
| held write (purging, restoring) | a bug (not a `Failure`) | released with the toast "Nothing was lost, but something went wrong. Try again." (`failureUnknown`); the bug is reported. The dialog or sheet is no longer held and Back closes it | VERIFIED `trash_held_bug_test.dart::a purge that dies on a bug releases the dialog (UC-TRASH-001 A3)`, `::a restore that dies on a bug releases the sheet (UC-TRASH-001 steps 5-7)` |
| all | tap Hide this note | noteDismissed | VERIFIED `trash_screen_test.dart::the retention note can be hidden, and stays hidden (critique 2026-09-30)` |

## Rulings

- **The Footer Pair Rule (DEV-169):** the pairs stay side by side in English and Vietnamese; Vietnamese reads "Xoá ({n})" in the selection bar and "Giữ lại" in the delete-for-good dialog. Exception: from 1,000 items the counts in the selection bar no longer fit their shares and the pair stacks (`canStack`), since the count is what the action acts on.
- **DEV-179 (owner 2026-10-06):** the delete-for-good dialog's title names the count, so its confirm is "Delete" / "Xoá" alone, sharing the row 1 : 1 with "Keep in Trash"; it no longer stacks.
- **Invariant 36 (spec D6):** a blocked restore says "“X” still contains an entry deleted earlier (“Y”)" in a warning banner, one per blocked batch.
- **Owner 2026-10-17 (LIB-11):** spec D6's "it goes when the list next changes" means the Trash's contents changing (a purge, a restore, or the entry the banner names leaving), not the view: a filter, entering or leaving selection, or a tick keep the purge-blocked banners. Under the Cards filter a banner about a deck batch therefore still shows.
- **P3-L8:** a restore target shows its path, as the move sheets do; targets carry no counts.
- **BR-TRASH-006:** a deck has its own restore sheet and rule, with "Top level" for a top-level deck.
- **E-L3:** "Select" is a small secondary `MxButton`.
- **O11:** the no-target state is `MxDeckPickerSheet`'s empty state (the neutral folder, a filled OK), shared with the move sheets.
- **Spec §6:** a refused restore closes the sheet and shows a toast; the list follows the store.
- **Owner 2026-09-26 (UI refinements phase 2):** the selection bar reads "Restore ({n})" · "Delete ({n})"; "Delete" is a filled destructive `MxButton`.
- **Owner 2026-09-26:** the time left under 3 days is a warning `MxBadge`; the meta line wraps to two lines, 8 apart.
- **Owner 2026-09-26, BR-TRASH-011:** while selecting, the note hides, the other kind dims to 0.38, and "Cards and decks can't be selected together." shows.
- **Critique 2026-09-30:** the retention note has a close button ("Hide this note"); once hidden it stays hidden on this device (`dismissed_note`). The kind-lock note is not dismissible.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** the kind-lock note and the purge-blocked banners sit above the list, under the retention note (D4).
- **Owner 2026-10-16 (Q-P6-4), executor ruling:** an entry's meta stays unglued. It is capped at two lines, and gluing its terms (whole terms, or whole terms with a breakable "deleted {ago}") pushed it past the cap, so it ellipsized (`trash_screen_test.dart::a long meta line wraps to two lines instead of ellipsizing`); a lost fact costs more than a count on its own line. Settled by Q-C-1 below.
- **Q-C-1 (owner, 2026-10-16):** the actions sheet's subtitle (it holds the parent's name) and the Delete permanently hint keep each dot on the phrase before it (`metaDots`); the entry meta stays unglued, as ruled above. A line capped with an ellipsis is never glued as whole terms (`metaLine`), which pushed the entry meta past its cap; keeping only each dot on the phrase before it (`metaDots`) is allowed there, since it moves at most one word down (the sheet's two-line hints) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- Header: "Trash" · "Select" · "Kept for 30 days from deletion, then removed automatically. Restoring asks where the item should go." · "All" · "Cards" · "Decks" · "{n} entries · newest first".
- Row: "Card · deleted {ago}" · "Deck · {n} sub-decks · {m} cards · deleted {ago}" · "just now" / "{n} minutes ago" / "{n} hours ago" / "yesterday" / "{n} days ago" · "{n} days left" · "{n}h left" · "Was in {path}" · "Top level" · "Actions for {name}".
- Actions: "Restore…" · "Choose which deck it goes to" · "Delete permanently" · "Cannot be undone · history lost".
- Restore: "Restore “{name}” to…" · "Its schedule, history, flag and tags come back with it. Only decks in the same tree that hold cards or are empty are offered." · "Nowhere to restore right now" · "No deck in “{root}” can hold cards at the moment. Create an empty sub-deck there, then restore." · "“{name}” restored to {deck}".
- Selection: "Select entries" · "{n} cards selected" · "{m} cards" · "{m} decks" · "Cards and decks can't be selected together." · "Restore ({n})" · "Delete ({n})" · "Close selection" (Card list's label, owner 2026-10-08).
- Delete for good: "Delete {n} cards permanently?" · "They disappear for good, together with their study history. This cannot be undone." · "Keep in Trash" · "Delete" · "{n} cards deleted permanently".
- Empty and error: "Trash is empty" · "Decks and cards you delete stay here for 30 days before they are removed for good." · "Couldn't open Trash".
