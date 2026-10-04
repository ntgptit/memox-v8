---
id: SCR-STUDY-006
name: Study · Guess
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Study · Guess

## Purpose

A round-based graded stage, eight boxes only: one term, exactly five meaning options, and only the
first tap counts. The top bar, exit, rounds, result-after-commit, unsaved-answer banner and session
errors are those of every session screen (SCR-STUDY-003, "Session screens").

## Related Use Cases

- UC-STUDY-001

## Layout

- **Top bar** — Indigo, as every mode.
- **Context line** — "{deck} · Review · round {n}".
- **Prompt** — the study face card: the eyebrow "What is this?" in flow, the term below it.
- **Options** — five rows lettered A–E: a letter badge and the meaning text. Once the pick's write
  commits, the pick and the right option — found by card id, never by display string — take their
  tones (right in `success`: success-soft, success border, success ink; wrong in error), and the rest
  fade. The options ease into their tones, surface and ink together (standard duration; at once under
  Remove animations).
- **Footer hint** — "Only your first pick counts" before the pick; "Answer shown — the correct option
  is highlighted" once answered; its glyph is info.
- **Blocked notice** — centred: "This question can't be shown", with "Close the session" (no glyph).

## States

### `idle` · Question

Golden: light, dark

### `right` · Answered right

The turn is held 1200 ms or until a tap, then the next card follows.

Golden: light, dark

### `wrong` · Answered wrong

The pick in error, the right option in success; held 1200 ms or until a tap.

Golden: light, dark

### `blocked` · Question can't be shown

The options could not be built: nothing is written or skipped, and Close ends the session.

Golden: light, dark

## Controls

### Session

- Type: read
- Invokes: FN-STUDY-004

### Option rows A–E

- Type: option rows
- Enabled when: no option has been picked in this turn and no write runs.
- Invokes: FN-STUDY-005
- Purpose: the first tap answers the turn; later taps change nothing.

#### On success

- `right` or `wrong`; with TalkBack on, the answered state waits on "Next" instead of advancing by
  itself.

#### On failure

- As every session screen (SCR-STUDY-003).

### Next (TalkBack only)

- Type: button
- Purpose: advances from the answered state.

### Close the session (`blocked`), Close, system Back

- Type: button / icon button / back
- Invokes: FN-STUDY-009
- Purpose: opens the exit dialog of every session screen.

## Responsive Behavior

The options scroll with the prompt once they outgrow the screen at large text, and a soft fade over
the bottom edge says more is below; each is at least 48 tall. A term word too wide for the prompt is
drawn just small enough to stay whole; the term wraps between words and never ellipsizes. Otherwise
follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- Each option reads "Option {letter}: {meaning}"; once answered, "…, correct" or "…, your pick, wrong".
- The outcome is announced when its write commits: "Correct", or "Wrong. The answer is {meaning}."

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Only the first pick counts. | — |
| The right option is found by card id, never by its text. | — |
| A question that can't be built writes nothing and skips nothing. | — |

## Copy

- Context line: "{deck} · Review · round {n}".
- Prompt eyebrow: "What is this?".
- Footer hint: "Only your first pick counts" (before the pick) · "Answer shown — the correct option is
  highlighted".
- Blocked: "This question can't be shown" · "Its options could not be built. Close the session; every
  answer so far is kept." · "Close the session".
- TalkBack: "Option {letter}: {meaning}" · "Correct" · "Wrong. The answer is {meaning}." · "Next".

## Rulings

- **FE-A6 spec D14 (P3 ruling C1):** the right option uses the `success` semantic (`successSoft` /
  `successBorder` / `successInk`); green is mastery-only.
- **P3 ruling C2:** a question that cannot be built shows "This question can't be shown", whose Close
  ends the session; nothing is written or skipped.
- **P3 ruling C6:** with TalkBack on, the answered state waits on a "Next" button instead of
  advancing by itself.
- Before the pick the footer hint reads "Only your first pick counts".
- **P3 rulings C3, C4; FE-A6 D19:** outcomes are announced on commit; the options scroll with a fade
  at large text; a too-wide term shrinks to stay whole.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  session context line is an eyebrow; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the hold
  stays 1200 ms or until a tap (R2); the blocked notice is centred and its Close has no glyph (R5); the
  context line drops "first pick counts", which the footer states (R9).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is
  info (F7).
