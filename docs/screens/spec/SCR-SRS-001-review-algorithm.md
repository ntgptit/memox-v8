---
id: SCR-SRS-001
name: Review algorithm & reset
domain: srs
status: ready
route: [/decks/deck/:deckId/algorithm]
---

# Review algorithm & reset

## Purpose

A root deck's review algorithm: which one its tree uses, whether it can still change, and the
one way to start over — Reset learning progress. Root decks only; it replaces the old scheduler
sheet. Reached from the root deck's action sheet (SCR-DECK-001).

## Related Use Cases

- UC-DECK-002
- UC-SRS-001

## Layout

- **App bar** — back, "Review algorithm" (content density).
- **Breadcrumb** — Library › root › Review algorithm; Library and the root are tappable.
- **Lock strip** — a card with an icon tile. Unlocked: a plain card (no hero ground: it states a
  status and is not a door), open lock on primary, "Can still be changed" / "Locks once the
  first card finishes learning." Locked: warning-soft ground, lock on warning, "Locked · cycle
  {n}" / "The first card finished learning on {date}. Only a reset opens a new cycle." The lock
  is named in words, not by colour alone.
- **Switch-failed banner** — after a failed switch only: a danger banner with Retry, under the
  lock strip.
- **ALGORITHM** — a section header, then a note, then a card of two option rows (Eight boxes,
  SM-2) with the current algorithm selected; both rows are disabled when locked. The note sits
  above the options, so the consequence is read before the choice. Unlocked (info icon):
  "Switching resets every card's schedule in this tree and closes any open study session.
  Choosing the current algorithm changes nothing." Locked (lock icon): "To change the algorithm
  now, reset learning progress below and choose the algorithm for the new cycle." The locked
  choice is shown with its reason and the way to Reset — never hidden, since a hidden choice
  reads as a feature that does not exist.
- **START OVER** — a section header and a card: "Reset learning progress" / "Every card in this
  tree becomes new and a new cycle begins. You choose the algorithm for it. Decks, cards, tags and
  past history are kept." / an outline button "Reset learning progress…".
- **Switch confirmation** — a dialog, non-destructive in tone: a switch is not a reset, spends
  no cycle and loses no history.
- **Reset dialog** — title, the intro, a Kept tile (success: decks, sub-decks, cards, tags,
  notes and every past answer) and a Lost tile (warning: every card's schedule, due date and
  progress, and the open session when there is one), "Algorithm for the new cycle" with two
  option rows (keep the current one, switch to the other), and Cancel · the confirm in the
  warning tone.

Algorithm descriptions:

- **Eight boxes:** "Remembered moves a card up a box and forgotten sends it back to box 1;
  reviews use match, guess, recall or fill."
- **SM-2:** "Intervals adapt as you grade each card again, hard, good or easy in self-assess
  reviews."

## States

### `locked` · Locked

The date comes from the root's first-answered time, in local time. Both options are disabled;
the note points to Reset.

Golden: light, dark

### `unlocked` · Unlocked

Golden: light, dark

### `switching` · Switching

Reached **after** the confirmation dialog: the chosen row shows the switch running.

Golden: none — no golden in V8 (record 02)

### `switched` · Switched

The snackbar "Switched to {algorithm} · every card starts fresh".

Golden: none — no golden in V8 (record 02)

### `switch_failed` · Switch failed

The danger banner "Couldn’t switch." / "The deck still uses {algorithm}." with Retry, which
tries the same switch again.

Golden: none — no golden in V8 (record 02)

### `reset_confirm` · Reset dialog

"Kept" in `on-status-mastered-container` on `status-mastered-container`; "the open session" only when a session is open.

Golden: light, dark

### `resetting` · Resetting

The confirm spins and Cancel is off; no "Resetting…" text.

Golden: none — no golden in V8 (record 02)

### `reset_done` · Reset done

The snackbar "Cycle {n+1} started · {count} cards are new again", then the unlocked state.

Golden: none — no golden in V8 (record 02)

### `nothing_to_lose` · Nothing to lose

The reset dialog when the tree has nothing to lose: one paragraph instead of the Kept and Lost
tiles.

Golden: none — no golden in V8 (record 02)

### `loading` · Loading

A skeleton list of four rows under the app bar.

Golden: none — no golden in V8 (record 02)

### `load_error` · Load error

The error state "Couldn't open this deck" · "Nothing was lost. Try again in a moment." with
Retry.

Golden: none — no golden in V8 (record 02)

### `not_found` · Not a root, or gone

The deck is a sub-deck, was moved to the Trash or no longer exists: the not-found state of
SCR-DECK-001, with its way back to the Library.

Golden: none — no golden in V8 (record 02)

## Controls

### Screen data

- Type: read
- Invokes: FN-DECK-008

### Breadcrumb: Library, root

- Type: breadcrumb segment

#### On success

- Navigate to: SCR-DECK-001

### Algorithm option row (unlocked)

- Type: option row
- Enabled when: the tree is not locked and no switch is running.
- Purpose: choosing the current algorithm changes nothing; choosing the other one opens the
  switch confirmation. It never switches on the tap.

### Switch (in the switch confirmation)

- Type: primary dialog action
- Invokes: FN-DECK-003

#### On success

- `switched`.

#### On failure

- `schedulerLocked` (the tree locked meanwhile — the screen's own drawing never decides whether
  the switch is allowed) and `notFound` → a snackbar with the reason; the stream draws the
  locked state, which offers the way to Reset.
- A database failure → `switch_failed`.

### Cancel (switch confirmation)

- Type: dialog action
- Purpose: closes the dialog; nothing changes.

### Retry (switch-failed banner)

- Type: compact button
- Invokes: FN-DECK-003

#### On success

- As Switch.

#### On failure

- As Switch.

### Reset learning progress…

- Type: outline button
- Invokes: FN-SRS-001
- Purpose: opens the reset dialog, which reads what a reset keeps and loses.

#### On failure

- A rejection or a database failure → the dialog's intro shows the reason instead of the counts.

### Keep {current} / Switch to {other} (reset dialog)

- Type: option rows
- Purpose: the algorithm of the new cycle; the current one is selected first.

### Reset and start cycle {n+1}

- Type: dialog confirm, warning tone
- Enabled when: no reset is running.
- Invokes: FN-SRS-002

#### On success

- `reset_done`.

#### On failure

- An `SrsRejection` → a snackbar with its message; a database failure → a snackbar with the
  failure's message. The dialog closes; nothing changed.

### Cancel (reset dialog)

- Type: dialog action
- Enabled when: no reset is running.
- Purpose: closes the dialog; nothing changes (UC-SRS-001 A3).

### Retry (`load_error`)

- Type: button
- Invokes: FN-DECK-008

### Back to Library (`not_found`)

- Type: button

#### On success

- Navigate to: SCR-DECK-001

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- The lock is named in words ("Can still be changed", "Locked · cycle {n}"), never by colour
  alone.
- "Kept" uses `on-status-mastered-container` on `status-mastered-container`, at 4.5:1 or more.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Choosing the other algorithm asks first; a tap never switches. | — |
| The locked algorithm choice is shown disabled with its reason and the way to Reset, never hidden. | — |
| The switch confirmation is not destructive in tone; only the reset confirm takes the warning tone. | — |
| While a reset runs, its confirm spins and Cancel is off. | — |
| The lock state is named in words, not by colour alone. | — |

## Copy

- Screen: "Review algorithm" · "Can still be changed" · "Locks once the first card finishes
  learning." · "Locked · cycle {n}" · "The first card finished learning on {date}. Only a reset
  opens a new cycle." · "ALGORITHM" · "Switching resets every card's schedule in this tree and
  closes any open study session. Choosing the current algorithm changes nothing." · "To change
  the algorithm now, reset learning progress below and choose the algorithm for the new cycle." ·
  "START OVER" · "Reset learning progress" · "Every card in this tree becomes new and a new cycle
  begins. You choose the algorithm for it. Decks, cards, tags and past history are kept." · "Reset
  learning progress…".
- Switch confirmation: "Switch to {algorithm}?" · "Every card's schedule in this tree starts over
  and any open study session closes. No history is lost." · "Cancel" · "Switch".
- Switched: "Switched to {algorithm} · every card starts fresh".
- Switch failed: "Couldn’t switch." · "The deck still uses {algorithm}." · "Retry".
- Reset dialog: "Reset learning progress?" · with progress "This starts cycle {n+1} for {deck}
  and its {count} cards." · Kept "Decks, sub-decks, cards, tags, notes, and every past answer
  (labelled cycle {n})" · Lost "Every card's schedule, due date and progress; the open session.
  All {count} cards become new" · nothing to lose "Nothing has been studied in this cycle yet, so
  there is nothing to lose. A new cycle starts with the algorithm you pick." · "Algorithm for the
  new cycle" · "Keep {current}" · "Switch to {other}" · "Cancel" · "Reset and start cycle {n+1}".
- Reset done: "Cycle {n+1} started · {count} cards are new again".
- Load error: "Couldn't open this deck" · "Nothing was lost. Try again in a moment." · "Retry".
- Rejections (snackbar, by failure type): `schedulerLocked` "The scheduler is locked because
  cards in this deck have been reviewed." · `notFound` "This deck no longer exists." ·
  `notARootDeck` "Only a top-level deck has a scheduler." · `staleGeneration` "The deck's
  schedule changed. Start again."

## Rulings

- **UC-DECK-002 steps 3–4:** choosing the other algorithm asks for confirmation first; it never
  switches on the tap.
- **UC-DECK-002 step 3 (moved from the UC, 2026-10-04):** the switch warning is not Reset
  learning progress — no cycle is spent and no history is dropped — so it never takes the
  reset's destructive tone.
- **UC-DECK-002 A1, UC-SRS-001 (moved from the UCs, 2026-10-04):** the locked choice is shown
  with its explanation and the way to Reset; Reset is usually reached from that explanation.
- **M3 review 2026-09-28 B2:** while a reset runs the confirm button spins, with no "Resetting…"
  text, as every async confirm.
- **Spec A10 (WCAG 2.2 AA):** "Kept" is written in `on-status-mastered-container` on
  `status-mastered-container` (4.5:1 or more in both themes).
- **D-L1:** a switch refused because the tree just locked shows the locked state from the
  stream, with the reason as a snackbar.
- **Critique 2026-09-30:** each algorithm is described in one sentence.
- **Critique 2026-09-30 tone pass (final review):** the reset dialog's Kept tile is success (a
  fine state), Lost stays warning.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the
  unlocked lock strip is a plain card with no hero ground (it states status and is not a door;
  DESIGN.md "a hero leads somewhere tappable"); the reset confirm "Reset and start cycle {n}"
  takes the warning tone, as the dialog's Lost tile does.
