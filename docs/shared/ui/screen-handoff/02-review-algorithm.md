<!-- Hand-written screen record. -->

# 02 · Review algorithm & reset

`/decks/deck/:deckId/algorithm`, root decks only (BR-DECK-025). Replaces the scheduler
sheet. UC-DECK-002 (change scheduler), UC-SRS-001 (reset learning progress).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar, breadcrumb | `MxAppBar`, `MxBreadcrumb` | Back, "Review algorithm"; Library › root › Review algorithm. |
| Lock strip | `MxCard` + `MxIconTile` | Unlocked: plain card, open lock on primary, "Can still be changed" / "Locks once the first card finishes learning." Locked: the warning tint, lock on warning, "Locked · cycle {n}" / "The first card finished learning on {date}. Only a reset opens a new cycle." The lock is named in words, not colour alone. |
| ALGORITHM | `MxListSectionHeader`, `MxCard` of two `MxOptionRow`s | The current algorithm selected; both disabled when locked. |
| Note | `MxNote`, above the options (critique 2026-09-30) | Unlocked: "Switching resets every card's schedule in this tree and closes any open study session. Choosing the current algorithm changes nothing." Locked (lock icon): "To change the algorithm now, reset learning progress below and choose the algorithm for the new cycle." |
| START OVER | `MxListSectionHeader`, `MxCard`, `MxButton` (outline) | "Reset learning progress" / "Every card in this tree becomes new and a new cycle begins. You choose the algorithm for it. Decks, cards, tags and past history are kept." / "Reset learning progress…". |

Algorithm descriptions:

- **Eight boxes:** "Remembered moves a card up a box and forgotten sends it back to box 1; reviews use match, guess, recall or fill."
- **SM-2:** "Intervals adapt as you grade each card again, hard, good or easy in self-assess reviews."

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| locked | `library_algorithm_locked_light.png` | `library_algorithm_locked_dark.png` | Date from `firstAnsweredAt`, local time. |
| unlocked | `library_algorithm_unlocked_light.png` | `library_algorithm_unlocked_dark.png` | — |
| loading | no golden | no golden | Four skeleton rows (`MxSkeletonList`, `commonLoading`) while the deck view is read. `UNVERIFIED (code read)`: `deck_algorithm_screen.dart`; no test holds the read open. |
| error | no golden | no golden | `MxErrorState` "Couldn't open this deck" · "Nothing was lost. Try again in a moment." with Retry (it spins while the read runs). `UNVERIFIED (code read)`: `deck_algorithm_screen.dart`; no test fails the read. |
| gone | no golden | no golden | The not-found state of screen 01 (`DeckGoneStateWidget`) with "Back to Library" and "Open Trash", for a root deleted while open and for a sub-deck, which has no algorithm (BR-DECK-025, audit 2026-10-17 LIB-4). `deck_algorithm_screen_test.dart::a root deleted while open shows the gone state`, `::a sub-deck has no algorithm screen (BR-DECK-025)`. |
| switchConfirm | no golden | no golden | The switch confirmation: `MxDialog`, non-destructive, "Switch to {algorithm}?" with Cancel · Switch (UC-DECK-002 steps 3–4; copy under "Notes on the states above"). `deck_algorithm_screen_test.dart::unlocked: the current algorithm is selected; switching asks first`. |
| switching | no golden | no golden | Reached **after** the confirmation dialog (UC-DECK-002 steps 3–4). The options and "Reset learning progress…" are off until it ends (audit 2026-10-17 LIB-13). |
| switched | no golden | no golden | Snackbar "Switched to {algorithm} · every card starts fresh". |
| switchFailed | no golden | no golden | Danger banner "Couldn't switch." · "The deck still uses {algorithm}." with Retry (UC-DECK-002 E2). `deck_algorithm_screen_test.dart::a switch that fails says the deck kept its algorithm; Retry switches (E2)`. |
| resetConfirm | `library_algorithm_reset_light.png` | `library_algorithm_reset_dark.png` | "Kept" in `success` on the success tint (ADR-022); "the open session" only when a session is open. |
| resetting | no golden | no golden | The confirm spins and Cancel is off (M3 review B2). |
| resetDone | no golden | no golden | Then the unlocked state. |
| nothingToLose | no golden | no golden | When `hasProgressToLose` is false (UC-SRS-001 A2): no Kept and Lost tiles, the confirm stays on. `deck_reset_dialog_test.dart::nothing to lose says so and still resets (UC-SRS-001 A2)`. |
| resetSummaryLoading | no golden | no golden | The dialog while the summary is read: title, one skeleton row and the algorithm choice; no intro; the confirm is off until the summary lands. Code read: `deck_reset_dialog_widget.dart`. |
| resetSummaryRejected | no golden | no golden | The summary is refused (the deck is gone, or is not a root): the dialog body says why (the SRS rejection copy); the confirm stays off, Cancel closes. Code read: `deck_reset_dialog_widget.dart`. |
| resetSummaryError | no golden | no golden | The summary read fails: the body is the failure message (or "Nothing was lost, but something went wrong. Try again." for anything else); the confirm stays off. Code read: `deck_reset_dialog_widget.dart`. |
| resetFailed | no golden | no golden | The reset fails (E1): the dialog stays, the confirm stops spinning and a toast gives the failure; nothing changed. `deck_reset_dialog_test.dart::a reset that fails keeps the dialog for another try (E1)`. An unexpected error is logged and shown as the unknown-failure toast; the dialog stays. |

Notes on the states above:

- **Switch confirmation:** `MxDialog`, non-destructive: "Switch to {algorithm}?" / "Every card's schedule in this tree starts over and any open study session closes. No history is lost." / Cancel · Switch (UC-DECK-002 steps 3–4).
- **Refused because the tree just locked:** the locked state and the reason (UC-DECK-002 E4).

## Reset dialog copy

- Title "Reset learning progress?"
- With progress: "This starts cycle {n+1} for {deck} and its {count} cards."
  - Kept: "Decks, sub-decks, cards, tags, notes, and every past answer (labelled cycle {n})"
  - Lost: "Every card's schedule, due date and progress; the open session. All {count} cards become new"
- Nothing to lose: "Nothing has been studied in this cycle yet, so there is nothing to lose. A new cycle starts with the algorithm you pick."
- "Algorithm for the new cycle": "Keep {current}" · "Switch to {other}"
- Buttons: "Cancel" · "Reset" (warning tone; the intro names the cycle it starts, DEV-179); while it runs the confirm spins and Cancel is off
- Done: "Cycle {n+1} started · {count} cards are new again"
- Switch failed: "Couldn’t switch." "The deck still uses {algorithm}." · "Retry"
- Summary refused or unread: the body is the rejection or failure message; no tiles, the confirm off.
- Reset failed: a toast with the failure message; the dialog stays.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the deck lands as a root | locked / unlocked | VERIFIED `deck_algorithm_screen_test.dart::unlocked: the current algorithm is selected; switching asks first`, `::locked: cycle and date named, options disabled, the note points to the reset` |
| loading | the read fails | error | `UNVERIFIED (code read)`: `deck_algorithm_screen.dart` shows `MxErrorState`; no test fails the read |
| error | Retry | loading, then the screen | `UNVERIFIED (code read)`: invalidates `deckViewProvider` |
| loading | the deck is deleted or is a sub-deck | gone | VERIFIED `::a root deleted while open shows the gone state`, `::a sub-deck has no algorithm screen (BR-DECK-025)` |
| unlocked | tap the other algorithm | switchConfirm | VERIFIED `::unlocked: the current algorithm is selected; switching asks first` |
| unlocked | tap the current algorithm | nothing | VERIFIED `::tapping the current algorithm does nothing (UC-DECK-002 A4)` |
| switchConfirm | Cancel | unlocked, nothing changed | VERIFIED `::cancelling the switch changes nothing (UC-DECK-002 A3)` |
| switchConfirm | Switch | switching, then switched (the toast) and the new algorithm selected | VERIFIED `::unlocked: the current algorithm is selected; switching asks first` |
| switching | both rows are off and the target spins | a second choice is not possible | `UNVERIFIED (code read)`: `deck_algorithm_options_widget.dart` (`isChoosable`) |
| switching | the tree has just locked or the deck is gone | the locked state from the stream, the reason as a toast | VERIFIED `::a switch refused because the tree just locked says why (E4)` |
| switching | the switch fails | switchFailed | VERIFIED `::a switch that fails says the deck kept its algorithm; Retry switches (E2)` |
| switchFailed | Retry | switching, then switched | VERIFIED same test |
| switching | the screen is left | no state is set | `UNVERIFIED (code read)`: `deck_algorithm_screen.dart` returns on `!mounted` |
| locked | tap an algorithm | nothing (both rows are disabled) | VERIFIED `::locked: cycle and date named, options disabled, the note points to the reset` |
| locked / unlocked | tap Reset learning progress… | resetConfirm (with the summary read), or its loading / rejected / error variants | VERIFIED `deck_reset_dialog_test.dart::with progress: cycle, Kept and Lost; keeping the algorithm resets it (UC-SRS-001)`; loading, rejected and error `UNVERIFIED (code read)` |
| resetConfirm | Cancel | the screen, nothing changed | VERIFIED `deck_reset_dialog_test.dart::cancelling the reset changes nothing (UC-SRS-001 A3)` |
| resetConfirm | choose the other algorithm, Reset | resetting, then resetDone with the other algorithm | VERIFIED `::switching in the reset starts the new cycle on the other algorithm` |
| resetConfirm | Reset | resetting, then resetDone: the toast "Cycle {n} started · {count} cards are new again", the unlocked state | VERIFIED `::with progress: cycle, Kept and Lost; keeping the algorithm resets it (UC-SRS-001)` |
| resetting | the confirm spins and Cancel is off | no second reset | VERIFIED `::while the reset runs the confirm spins and Cancel is off` |
| resetting | the reset fails | resetFailed: the dialog stays for another try | VERIFIED `::a reset that fails keeps the dialog for another try (E1)` |
| held write (switching, resetting) | a bug (not a `Failure`) | switching: switchFailed, the same banner and Retry as a `Failure`, the bug reported; resetting: released with the toast "Nothing was lost, but something went wrong. Try again." (`failureUnknown`), reported, the dialog is no longer held and Back closes it | VERIFIED `deck_held_bug_test.dart::a switch that dies on a bug stops spinning and offers Retry, as a Failure does (UC-DECK-002 E2)`, `::a reset that dies on a bug releases the dialog (UC-SRS-001 E1)` |
| resetConfirm | a reset made elsewhere while open | the cycle named moves on | VERIFIED `::a reset made elsewhere while the dialog is open moves its cycle on` |
| nothingToLose | Reset | resetDone | VERIFIED `::nothing to lose says so and still resets (UC-SRS-001 A2)` |

## Rulings

- **UC-DECK-002 steps 3–4:** choosing the other algorithm asks for confirmation first; it never switches on the tap.
- **M3 review 2026-09-28 B2:** while a reset runs the confirm button spins (`MxSheetActions.isConfirmLoading`), with no "Resetting…" text, as every async confirm.
- **Spec A10, amended 2026-10-10:** "Kept" is written in `success` on the success tint (superseded 2026-10-13 by ADR-022, which tints over each theme's own surface).
- **D-L1:** a switch refused because the tree just locked shows the locked state from the stream, with the reason as a snackbar.
- **Critique 2026-09-30:** each algorithm is described in one sentence.
- **Critique 2026-09-30 tone pass (final review):** the reset dialog's Kept tile is success (a fine state), Lost stays warning.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the unlocked lock strip is a plain card with no hero ground (it states status and is not a door; DESIGN.md "a hero leads somewhere tappable"); the reset confirm takes the warning tone, as the dialog's Lost tile does.
