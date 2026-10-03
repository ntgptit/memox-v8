<!-- Hand-written screen record. -->

# 02 · Review algorithm & reset

`/decks/deck/:deckId/algorithm`, root decks only (BR-DECK-025). Replaces the scheduler
sheet. UC-DECK-002 (change scheduler), UC-SRS-001 (reset learning progress).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar, breadcrumb | `MxAppBar`, `MxBreadcrumb` | Back, "Review algorithm"; Library › root › Review algorithm. |
| Lock strip | `MxCard` + `MxIconTile` | Unlocked: plain card, open lock on primary, "Can still be changed" / "Locks once the first card finishes learning." Locked: warning-soft ground, lock on warning, "Locked · cycle {n}" / "The first card finished learning on {date}. Only a reset opens a new cycle." The lock is named in words, not colour alone. |
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
| switching | no golden | no golden | Reached **after** the confirmation dialog (UC-DECK-002 steps 3–4). |
| switched | no golden | no golden | Snackbar "Switched to {algorithm} · every card starts fresh". |
| switchFailed | no golden | no golden | Danger banner with Retry (UC-DECK-002 E2). |
| resetConfirm | `library_algorithm_reset_light.png` | `library_algorithm_reset_dark.png` | "Kept" in `statusMasteredInk` (spec A10); "the open session" only when a session is open. |
| resetting | no golden | no golden | The confirm spins and Cancel is off; Back and the scrim wait too (M3 review B2, SP2b 2.26). |
| resetFailed | no golden | no golden | The write failed: the dialog stays with a warning banner inside it (the failure's sentence) and the confirm is the retry (SP2b 2.27). |
| resetSummaryFailed | `library_algorithm_reset_failed_light.png` | `library_algorithm_reset_failed_dark.png` | The read of what the reset would change failed: no kept/lost tiles; the dialog leads with a warning banner and a compact Retry that reads it again; the confirm stays off. Cancel stays live, so it is never a dead end. A deck that is gone has no retry: it keeps its message (SP2b 2.28). |
| resetDone | no golden | no golden | Then the unlocked state. |
| nothingToLose | no golden | no golden | When `hasProgressToLose` is false (UC-SRS-001 A2). |

Beyond the states above:

- **Switch confirmation:** `MxDialog`, non-destructive: "Switch to {algorithm}?" / "Every card's schedule in this tree starts over and any open study session closes. No history is lost." / Cancel · Switch (UC-DECK-002 steps 3–4).
- **Refused because the tree just locked:** the locked state and the reason (UC-DECK-002 E4).
- **Loading, load error, not a root or gone:** skeleton, `MxErrorState`, the not-found state of screen 01.

## Reset dialog copy

- Title "Reset learning progress?"
- With progress: "This starts cycle {n+1} for {deck} and its {count} cards."
  - Kept: "Decks, sub-decks, cards, tags, notes, and every past answer (labelled cycle {n})"
  - Lost: "Every card's schedule, due date and progress; the open session. All {count} cards become new"
- Nothing to lose: "Nothing has been studied in this cycle yet, so there is nothing to lose. A new cycle starts with the algorithm you pick."
- "Algorithm for the new cycle": "Keep {current}" · "Switch to {other}"
- Buttons: "Cancel" · "Reset and start cycle {n+1}" (warning tone); while it runs the confirm spins and Cancel is off
- Done: "Cycle {n+1} started · {count} cards are new again"
- Switch failed: "Couldn’t switch." "The deck still uses {algorithm}." · "Retry"
- Reset failed (banner inside the dialog): the failure's sentence, e.g. "Nothing was lost. The data is busy, so try again."; summary read failed: the same, with "Retry".

## Rulings

- **UC-DECK-002 steps 3–4:** choosing the other algorithm asks for confirmation first; it never switches on the tap.
- **M3 review 2026-09-28 B2:** while a reset runs the confirm button spins (`MxSheetActions.isConfirmLoading`), with no "Resetting…" text, as every async confirm.
- **Spec A10 (WCAG 2.2 AA):** "Kept" is written in `statusMasteredInk` (4.5:1) on an 8% mastery tint; over 12% the ink falls to 4.4:1.
- **D-L1:** a switch refused because the tree just locked shows the locked state from the stream, with the reason as a snackbar.
- **Critique 2026-09-30:** each algorithm is described in one sentence.
- **Critique 2026-09-30 tone pass (final review):** the reset dialog's Kept tile is success (a fine state), Lost stays warning.
- **SP2b 2.26-2.28 (spec `2026-10-03-ui-hardening-sp2b-design.md`):** the reset dialog is held while it writes (`isHeld`, Cancel off) and keeps its database failure in a warning `MxInlineBanner` instead of a toast, the confirm retrying. A failed summary read shows a banner with a compact Retry (`ref.invalidate(resetLearningSummaryProvider)`); a typed rejection (deck gone) has no retry.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the unlocked lock strip is a plain card with no hero ground (it states status and is not a door; DESIGN.md "a hero leads somewhere tappable"); the reset confirm "Reset and start cycle {n}" takes the warning tone, as the dialog's Lost tile does.
