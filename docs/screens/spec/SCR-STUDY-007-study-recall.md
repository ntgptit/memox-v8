---
id: SCR-STUDY-007
name: Study · Recall
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Study · Recall

## Purpose

A round-based graded stage, eight boxes only. The term is shown, the meaning hidden behind a
20-second turn clock; revealing is not an outcome, only the self-check after it is. The top bar,
exit, rounds, result-after-commit, unsaved-answer banner and session errors are those of every
session screen (SCR-STUDY-003, "Session screens").

## Related Use Cases

- UC-STUDY-001

## Layout

- **Top bar** — Indigo, as every mode.
- **Context line** — "{deck} · Review · round {n}".
- **Turn clock** — distinct from the top bar's session track: it measures the current turn. A caption
  and "{s}s / 20s", over a 4 dp fill that drains to 0. Neutral (`onSurfaceVariant`) while counting
  down; `warning` / warning ink once timed out. It stops whenever the app leaves the foreground and
  for good once revealed or timed out; stopped, not zeroed, on a reveal.
- **Term face** — the study face card labelled "Term": the prompt, always visible.
- **Meaning face** — the study face card in the answer role, its "Meaning" label in flow: a blurred
  placeholder before the reveal; the meaning once revealed or timed out, with a "Counted as forgot"
  tag when timed out.
- **Action row** — counting down: one "Show the meaning". Revealed: "Forgot" and "Remembered", both
  secondary so neither grade is the loud one — the only recorded input, at most once a turn. Timed
  out: one "Continue" that only advances and records nothing.
- **Footer hint** — by state; its glyph is info, and repeat after a timeout.

## States

### `counting` · Counting down

Golden: light, dark

### `revealed` · Revealed

The clock is stopped, not zeroed.

Golden: light, dark

### `timed_out` · Timed out

The outcome is already committed (wrong) before this paints; the turn is held until Continue.

Golden: light, dark

## Controls

### Session

- Type: read
- Invokes: FN-STUDY-004

### Turn clock

- Type: timer
- Invokes: FN-STUDY-007, FN-STUDY-005
- Purpose: saves the time left when the app pauses and when the turn's screen goes (never per tick);
  a resumed turn starts from the saved time, or opens revealed with its clock stopped. At zero the
  turn is answered timed out.

### Show the meaning

- Type: study button
- Invokes: FN-STUDY-006
- Purpose: stops the clock at once and records the reveal; the reveal is not an outcome.

### Forgot, Remembered

- Type: secondary buttons
- Enabled when: revealed, 400 ms after the reveal, and no write runs.
- Invokes: FN-STUDY-005

#### On success

- The next card follows by itself.

#### On failure

- As every session screen (SCR-STUDY-003).

### Continue (`timed_out`)

- Type: button
- Enabled when: 400 ms after the timeout.
- Purpose: advances; records nothing.

### Close, system Back, exit dialog

- Type: icon button / back / dialog
- Invokes: FN-STUDY-009

## Responsive Behavior

At large text the faces scroll inside and the two self-check buttons stack. Otherwise follows the
shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- The clock is one node: its caption, with "{n} seconds left" as its value. It is never announced per
  tick.
- A timeout is announced when its write commits: "Time is up. Counted as forgot. The meaning is
  {meaning}."
- Under Remove animations the clock's fill steps once a second and the meaning appears with no fade;
  the time runs the same.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Revealing is not an outcome; only Forgot or Remembered is. | — |
| A turn takes at most one self-check. | — |
| A timeout counts as forgot and waits for Continue; a self-check advances by itself. | — |
| The clock pauses in the background and resumes from the saved time. | — |

## Copy

- Context line: "{deck} · Review · round {n}".
- Clock caption: "Time to recall" (`counting`) · "Revealed with time left" (`revealed`) · "Time is up"
  (`timed_out`).
- Meaning tag: "Counted as forgot" (`timed_out`).
- Actions: "Show the meaning" · "Forgot" · "Remembered" · "Continue".
- Footer hint: "Recall the meaning before the time runs out" (`counting`) · "Be honest — the next card
  follows automatically" (`revealed`) · "This card comes back in a later round" (`timed_out`).
- TalkBack: "{n} seconds left" · "Time is up. Counted as forgot. The meaning is {meaning}."

## Rulings

- The ending has two branches: a self-check advances by itself, a timeout waits for Continue.
- **FE-A6 spec D14 (P4 ruling V2):** the clock's fill and caption are a neutral `onSurfaceVariant`
  while counting down and `warning` / `warningInk` once timed out; the top bar is Indigo (3c-2 R8).
- **M3 review 2026-09-28 F2:** the clock track is 4 dp, the app's thin track.
- **P2 face-label fix:** the answer face carries its "Meaning" label in flow, as every study face.
- **FE-A6 spec D5, D12:** the clock is the widget's own; it saves the time left on pause and when the
  turn's screen goes, never per tick.
- **P4 rulings V3, V5, V9; C4:** the clock is one node never announced per tick; under Remove
  animations it steps once a second; at large text the self-check buttons stack.
- **Critique 2026-09-30:** Forgot and Remembered are both secondary, so neither grade is the loud one.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** Forgot ·
  Remembered and the timed-out Continue settle for 400 ms (R1); the bar is Indigo (R8).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is
  info, and repeat on "This card comes back in a later round" after a timeout (F7).
- **Pending — open for the owner (record 19):** the 20-second turn is the same for TalkBack users, who
  read the chrome before they can recall. Changing it is a business-rule decision, not a UI one (V3).
