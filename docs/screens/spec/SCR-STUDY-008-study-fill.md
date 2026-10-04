---
id: SCR-STUDY-008
name: Study · Fill
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Study · Fill

## Purpose

A round-based graded stage, eight boxes only, and only for cards that have an example — others sit
out this stage without leaving the deck. The meaning is the prompt; the person types the term. The
top bar, exit, rounds, result-after-commit, unsaved-answer banner and session errors are those of
every session screen (SCR-STUDY-003, "Session screens"). It is the only session screen that takes
typed input.

## Related Use Cases

- UC-STUDY-001

## Layout

- **Top bar** — Indigo, as every mode.
- **Context line** — "{deck} · Review · round {n}".
- **Prompt face** — the study face card with its "Meaning" label in flow: the card's meaning, in the
  study passage role at 16. No edit button: no card can be edited mid-session.
- **Answer face** — the study face card in the answer role with its "Term" label in flow; the typed
  text is a bare, borderless field in the study term role. In input and hint: what has been typed so
  far with a blinking caret. In wrong: the typed answer struck through in `error`, the right
  term below it, tagged "Wrong · comes back next round".
- **Hint row** — inside the answer face, its line reserved from the start: a lightbulb glyph and the
  card's own hint, in the study detail role; offered only when the card has one.
- **Action row** — input: "Show hint" (only for a card with a hint not yet shown) and "Check". Hint:
  "Check" only. Wrong: one "Continue", as wide as a two-button row.
- **Footer hint** — by state; see Copy.
- **Keyboard** — the system keyboard opens for input and hint, and the action row sits above it; the
  shell resizes above the keyboard, so Check and the footer stay visible and the faces scroll inside.
  Wrong shows no field and the keyboard closes.

## States

### `input` · Typing

The field has focus when the turn opens.

Golden: light, dark

### `hint` · Hint shown

"Show hint" is gone once used; "Check" remains.

Golden: light, dark

### `wrong` · Wrong answer

Held until Continue. The correct-answer path has no visual of its own: the turn commits and the next
one loads at once.

Golden: light, dark

## Controls

### Session

- Type: read
- Invokes: FN-STUDY-004

### Answer field

- Type: text field
- Purpose: grading folds the typed text (trimmed, Unicode lower-case) against the term but never
  strips accents — "cong" does not match "công". The typed text is never kept, only the outcome.

### Show hint

- Type: button
- Enabled when: the card has a hint not yet shown.
- Invokes: FN-STUDY-008
- Purpose: shows the hint; using it is noted and changes nothing else.

### Check, IME Done

- Type: button / keyboard action
- Enabled when: the answer is not empty after trimming.
- Invokes: FN-STUDY-005

#### On success

- Right: the next turn follows at once. Wrong: `wrong`; focus leaves the field and the keyboard
  closes.

#### On failure

- As every session screen (SCR-STUDY-003).

### Continue (`wrong`)

- Type: button
- Enabled when: 400 ms after the outcome shows.
- Purpose: advances; the wrong row leaves this round and is enrolled exactly once in the next one.

### Close, system Back, exit dialog

- Type: icon button / back / dialog
- Invokes: FN-STUDY-009

## Responsive Behavior

With the keyboard open the shell resizes above it; the faces scroll inside. At large text the two
actions stack. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- The field reads "Your answer"; the hint row reads "Hint: {hint}"; the struck-through answer reads
  "You typed {typed}".
- A wrong answer is announced when its write commits: "Wrong. The answer is {term}."

## UI Invariants

| Invariant | Enforced by |
|---|---|
| An empty answer submits nothing. | — |
| Accents count: grading ignores case and outer spaces only. | — |
| The typed text is never kept. | — |
| Show hint appears only for a card with a hint. | — |
| A wrong answer waits for Continue; a right one advances at once. | — |

## Copy

- Context line: "{deck} · Review · round {n}".
- Actions: "Show hint" · "Check" · "Continue".
- Wrong tag: "Wrong · comes back next round".
- Footer hint: "Type the term for this meaning, then check" (`input`) · "Using the hint is noted; it
  changes nothing" (`hint`) · "Case and spaces are ignored, accents are not" (`wrong`).
- TalkBack: "Your answer" · "Hint: {hint}" · "You typed {typed}" · "Wrong. The answer is {term}."

## Rulings

- **P4 ruling V1:** the struck-through wrong answer uses the `error` ink, as Guess's wrong option; one
  wrong colour across the round modes.
- **P4 ruling V10:** the wrong tag and footer read "Wrong · comes back next round": a wrong fill row
  leaves the current round and is enrolled exactly once in the next one.
- **P4:** the prompt uses the study passage role at 16, and both faces carry their "Meaning" and
  "Term" labels in flow.
- **P4 ruling F1:** the field is the text field's bare study variant in the study term role.
- **P4 rulings V6, V7:** with the keyboard open the shell resizes above it; a wrong answer moves focus
  off the field and closes the keyboard.
- No card can be edited mid-session, so the prompt face has no edit button.
- **Critique 2026-09-30:** after a wrong answer, Continue is as wide as a two-button row.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** Continue
  after a wrong answer settles for 400 ms (R1); the card's hint is the study detail role with its
  line reserved (R4); the bar is Indigo (R8).
