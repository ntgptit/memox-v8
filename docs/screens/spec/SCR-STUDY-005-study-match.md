---
id: SCR-STUDY-005
name: Study · Match
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Study · Match

## Purpose

A round-based graded stage, eight boxes only: pair each term tile with its meaning tile, up to five
pairs a board. The top bar, exit, rounds, result-after-commit, unsaved-answer banner and session
errors are those of every session screen (SCR-STUDY-003, "Session screens").

## Related Use Cases

- UC-STUDY-001

## Layout

- **Top bar** — Indigo, as every mode; the counter is the round's, never the board's.
- **Context line** — "{deck} · {Learning/Review} · round {n}".
- **Board** — up to 10 tiles (5 pairs): the board's terms on the left and its meanings on the right,
  in their stored order. A tile is a small grid tile, not a padded card, with the states idle,
  selected, matched, and a wrong-pair flash. Idle meanings sit on the recessed ground; terms stay
  raised. A board with an odd remainder may hold one pair. A matched tile uses the `success` tone;
  green is mastery's alone. A tile eases into its tone, surface and ink together (standard duration;
  at once under Remove animations).
- **Footer hint** — "Tap a term and its meaning, in either order"; during a wrong pair's flash "Not a
  match — this pair comes back next round", with the repeat glyph.

## States

### `board` · Board

Golden: light, dark

### `wrong` · Wrong pair

After the write commits, both tiles flash the error tone, then settle back to idle and stay pending
on the board; the pair is guaranteed a slot in the next round, even if matched later in this round.

Golden: light, dark

## Controls

### Session

- Type: read
- Invokes: FN-STUDY-004

### Term tile, meaning tile

- Type: tiles
- Enabled when: the tile is not matched and no write runs.
- Invokes: FN-STUDY-005
- Purpose: tap a term and a meaning, in either order; the pair is answered on that term, on any
  pending pair of the board.

#### On success

- Matched: both tiles turn matched, announced "Matched". Wrong: `wrong`.

#### On failure

- As every session screen (SCR-STUDY-003).

### Close, system Back, exit dialog

- Type: icon button / back / dialog
- Invokes: FN-STUDY-009

## Responsive Behavior

The board scrolls once it outgrows the screen at large text, and a soft fade over its bottom edge
says more is below; each tile is at least 48 tall. A word too wide for its tile is drawn just small
enough to stay whole; tiles wrap between words and never ellipsize. Otherwise follows the shared
floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- TalkBack reads the terms first, then the meanings; each tile reads "Term: {text}" or "Meaning:
  {text}", with ", selected", ", matched" or, during a wrong pair's flash, ", not a match".
- Each outcome is announced when its write commits: "Matched", or the wrong-pair line.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A meaning may be tapped first. | — |
| A wrong pair stays pending on the board and returns next round. | — |
| A matched tile is success, never mastery green. | — |
| The counter counts the round, never the board. | — |

## Copy

- Context line: "{deck} · {Learning/Review} · round {n}".
- Footer hint: "Tap a term and its meaning, in either order" · "Not a match — this pair comes back next
  round" (during a wrong pair's flash).
- TalkBack: "Term: {text}" · "Meaning: {text}" · "{tile}, selected" · "{tile}, matched" · "{tile},
  not a match" · "Matched".

## Rulings

- **FE-A6 spec D14 (P3 ruling C1):** a matched tile uses the `success` semantic; green is
  mastery-only.
- **P3 ruling C7:** during a wrong pair's flash the footer hint reads "Not a match — this pair comes
  back next round".
- A wrong pair flashes the error tone on both tiles after the write commits, then both settle back to
  idle and stay pending on the board.
- A wrong pair keeps its row pending for this board and is guaranteed one slot in the next round,
  even if matched correctly later in this round.
- **P3 ruling C8:** TalkBack reads the terms first, then the meanings.
- **P3 ruling C3, C4; FE-A6 D19:** outcomes are announced on commit; the board scrolls with a fade at
  large text; a too-wide word shrinks to stay whole.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  session context line is an eyebrow; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** a meaning
  may be tapped first; idle meanings sit on the recessed ground, terms stay raised; hint "Tap a term
  and its meaning, in either order" (R3).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is
  info, and repeat while a wrong pair's "comes back next round" shows (F7).
