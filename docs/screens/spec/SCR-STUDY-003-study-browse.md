---
id: SCR-STUDY-003
name: Study · Browse
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Study · Browse

## Purpose

The first stage of every learning session, for both algorithms: both faces of the card at once,
nothing graded, nothing counted against the schedule. Browse never runs in a review session. It is
one of the session screens on the session route, full screen on the root navigator; this spec also
holds what every session screen shares (SCR-STUDY-003…SCR-STUDY-008).

## Related Use Cases

- UC-STUDY-001

## Layout

### Session screens (SCR-STUDY-003…SCR-STUDY-008)

- **Top bar** — the study top bar: a close icon ("Close the session"); the mode badge, the mode name
  in uppercase, tinted with the bar's Indigo in every mode; a progress track and a counter "{n} /
  {total}". For the four round-based modes (Match, Guess, Recall, Fill) the fraction is the
  **round's** position and size, never the board's; for Browse and Self-assess it is the stage's
  whole queue. The mode chip takes at most 40% of the bar and ellipsizes on one line, and a counter
  wider than a quarter of the bar shrinks to fit, so the track stays at least 48 wide at large text.
- **Context line** — a centred eyebrow under the bar, two lines at most; the deck name keeps its
  case.
- **Unsaved-answer banner** — a danger banner "Couldn't save that answer" / "The device is busy.
  Your answer is kept — try again." with Retry, under the context line, when a write fails but the
  session can go on. The card stays; nothing advances and no outcome is painted.
- **Footer hint** — one line in both languages, its info glyph inline before it, so the actions
  stand still with no empty line under them.
- **Exit dialog** — the close icon and system Back open one confirm dialog: "Stop this session?" /
  "Everything you answered is kept. Cards you haven't reached stay as they were." · "Keep studying" ·
  "Stop".
- **Rounds** — Match, Guess, Recall and Fill run in rounds: round 1 asks every card the stage can
  ask; each later round asks only the round's not-passed set, in its own shuffle. A card joins that
  set the moment it is answered wrong in the round, even if a later attempt in the same round gets
  it right. A stage is done once a round ends with an empty not-passed set; there is no cap on
  rounds. Browse and Self-assess never use rounds.
- **Result after commit** — a turn's outcome shows only after its write has committed.
- **The unit stays on screen between turns** — the card being answered stays visible while the
  outcome shows and the next turn loads; the body is never swapped for a loading state mid-session.
  Full-body loading is only for a session with no turn yet. Each mode declares its own outcome
  hold.
- **Keyboard** — only Fill takes typed input; every other session screen is tap-only.
- **Icons** — every glyph takes its colour from the shared icon tinting; no inline glyph colour.

### Browse

- **Context line** — "{deck} · Learning · stage {n} of {total}".
- **Card** — a full-bleed card in two panes: the term half on top with its label and pronunciation
  (the detail role of the body face), a hairline divider, the meaning half below with its label and
  the example when the card has one; both halves always visible. The face labels are eyebrows.
- **Navigation** — a swipe on the card, and a "Next card" button. Left advances; right looks back
  one card already shown in this round, in the order served, with a neutral "Looking back" badge on
  the card. Looking back does not record the card again or move the counter. The card follows the
  finger without a tilt while dragged, and stays still with reduced motion.
- **Footer hint** — "Swipe for next or back · nothing is graded".

## States

### `default` · Browsing

Golden: light, dark

### `looking_back` · Looking back

After a swipe back to an earlier card of the round.

Golden: light, dark

### `loading` · Session loading

A session with no turn yet; never mid-session.

Golden: none — no golden in V8 (record 16)

### `read_error` · Session can't be read

"Couldn't read this session" / "Your answers are safe on this device. Try again in a moment." with
Retry and Close.

Golden: none — no golden in V8 (record 16)

### `unsaved` · Answer not saved

The unsaved-answer banner with Retry; the card stays.

Golden: none — no golden in V8 (record 16)

## Controls

### Session

- Type: read
- Invokes: FN-STUDY-004

#### On failure

- A database failure → `read_error`.
- The session invalidated by a reset elsewhere → the toast "This session ended: the deck's learning
  progress was reset." and Navigate to: SCR-DECK-001 (the session's deck); nothing of that turn is
  written.
- The deck gone → the toast "This deck no longer exists" and Navigate to: SCR-DECK-001 (the
  Library).
- The session ended (completed, abandoned, failed, invalidated otherwise) → Navigate to:
  SCR-STUDY-009.

### Next card, left swipe

- Type: button / gesture
- Invokes: FN-STUDY-005
- Purpose: on the stage's last card, answers it and the session moves on to the next stage.

#### On failure

- A write that can go on → `unsaved`; a write that cannot → the session fails and SCR-STUDY-009
  shows the save error.

### Right swipe, Previous card

- Type: gesture / accessible action
- Purpose: looks back one card; on the round's first card it does nothing.

### Retry (unsaved-answer banner)

- Type: compact button
- Invokes: FN-STUDY-005
- Purpose: writes the same answer again.

### Close, system Back

- Type: icon button / back
- Purpose: opens the exit dialog.

### Stop (exit dialog)

- Type: dialog action
- Invokes: FN-STUDY-009

#### On success

- Navigate to: SCR-STUDY-009 (left early).

### Keep studying (exit dialog)

- Type: dialog action
- Purpose: closes the dialog; nothing changes.

### Retry, Close (`read_error`)

- Type: buttons
- Invokes: FN-STUDY-004
- Purpose: Retry reads the session again; Close leaves it.

#### On success

- Close: Navigate to: SCR-DECK-001 (the Library).

## Responsive Behavior

Card faces wrap and never ellipsize; at large text the faces scroll inside the card. Otherwise
follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- TalkBack reads the top bar (close, mode, "{done} of {total}"), the context line, then the card:
  term label and term, pronunciation, meaning label and meaning, example. The footer hint is read
  last.
- Card faces wrap and never ellipsize; Korean and Vietnamese with stacked marks render whole. Touch
  targets are at least 48 × 48.
- Swipes have accessible actions on the card: "Next card" and, when an earlier card exists,
  "Previous card".
- Edges: the hint does not change; a right swipe on the round's first card does nothing; a left
  swipe on the stage's last card answers it and the session moves on.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A turn's outcome shows only after its write committed; a failed write never advances. | — |
| The card stays on screen between turns; no full-body loading mid-session. | — |
| Leaving a session always asks first. | — |
| The round-based modes count the round, never the board. | — |
| Only Fill raises a keyboard. | — |
| Browse grades nothing and records nothing against the schedule. | — |

## Copy

- Top bar: "Close the session" · "{n} / {total}".
- Context line: "{deck} · Learning · stage {n} of {total}".
- Card: "Looking back".
- Footer hint: "Swipe for next or back · nothing is graded" / "Vuốt để sang hoặc quay lại · không chấm
  điểm".
- Exit: "Stop this session?" · "Everything you answered is kept. Cards you haven't reached stay as
  they were." · "Keep studying" · "Stop".
- Unsaved answer: "Couldn't save that answer" · "The device is busy. Your answer is kept — try
  again." · "Retry".
- Session errors: "Couldn't read this session" · "Your answers are safe on this device. Try again in
  a moment." · "This session ended: the deck's learning progress was reset." · "This deck no longer
  exists".

## Rulings

- **Owner ruling 2026-09-27; IT-NAV-010, IT-CONT-004:** the close icon and system Back open a confirm
  dialog first: Keep studying or Stop.
- The card follows the finger without a tilt while dragged, and stays still with reduced motion.
- Pronunciation uses the detail role of the body face; V8's typography has one family.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  face label and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the footer
  hint's glyph sits inline before the first line, and every hint is one line in both languages, so
  the CTA stands still with no empty line under it (R6, amended at the owner's golden review); the
  bar is Indigo in every mode (R8); the context line holds two lines at most (R9).
- **FE-A6 P3 ruling T1 and its final review:** the mode chip takes at most 40% of the bar and the
  counter shrinks to fit, so the track stays at least 48 wide.
- **FE-A6 spec D20:** the swipe edges as under Accessibility.
- **Critique 2026-09-30:** Browse has a "Next card" button beside the swipe.
- **Migration 2026-10-04:** the legacy UC-STUDY-001 E3 had the app return to the deck list after an
  unrecoverable save error; V8 ends the session as failed and shows SCR-STUDY-009 "Stopped by a save
  error", whose Done returns to the deck. E4 (a stale generation) leaves for the deck with a toast,
  as the legacy UC said.
