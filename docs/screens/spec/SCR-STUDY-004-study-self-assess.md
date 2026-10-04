---
id: SCR-STUDY-004
name: Study · Self-assess
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Study · Self-assess

## Purpose

The `self_assess` session screen: SM-2's review mode, and the second stage of an SM-2 learning
session. A learner on an SM-2 deck, one-handed, in a short gap in the day, grades how well they
remembered each card: see the prompt, try to recall the answer, reveal it, and tap one of four
grades. Nothing on the screen competes with the prompt, and no grade is ever committed by accident.
The top bar, exit, unsaved-answer banner and session errors are those of every session screen
(SCR-STUDY-003, "Session screens").

## Related Use Cases

- UC-STUDY-001
- UC-STUDY-003

## Layout

- **Top bar** — close, the mode badge "Self-assess", the counter "{n} / {total}" over the stage's
  whole queue.
- **Context line** — "{deck} · Review · Self-assess" (a learning session: "Learn").
- **Prompt card** — the study face card, raised, with its label in flow above the face: the side
  this queue row asks first — the term for term-first, the meaning for meaning-first; a mixed row
  carries its own. The whole card is a button: tapping it reveals, as "Show answer" does.
- **Answer card** — the study face card on the recessed ground, always laid out, with a still
  placeholder bar until the reveal; the answer fades in inside it under the prompt, so the prompt
  never moves. The two faces share the height equally; a short face is centred in its half.
- **Action area, before the reveal** — "Show answer", the study-size primary block button.
- **Action area, after the reveal** — the grade row: four buttons in one row, Again · Hard · Good ·
  Easy, in that order. Again is in the danger-soft tone; Hard, Good and Easy share the secondary tone;
  the label always names the grade, so colour never carries it alone. Under each label, the interval
  it would give ("1d", "6d", "15d") on a scheduled turn; none on a learning or relearning turn. Each
  button is at least 48 tall, 8 apart; from text scale 1.3 the row becomes a 2 × 2 grid instead of
  shrinking type. The grades keep their rounded rectangles: they judge rather than act.
- **Footer hint** — "Recall the answer, then show it" before the reveal; "Be honest — grade how well
  you remembered" after it; its glyph is info.

## States

### `prompt` · Prompt

The prompt card and "Show answer"; the answer is hidden.

Golden: light, dark

### `revealed` · Revealed

Both cards and the grade row, with the interval previews on a scheduled turn.

Golden: light, dark

### `meaning_first` · Meaning first

A meaning-first row: the prompt is the meaning, the answer the term.

Golden: light, dark

### `relearning` · Relearning

As revealed, without previews: a relearning turn does not move the schedule, so the preview is not
drawn — not "0d".

Golden: light, dark

### `saving` · Saving

The grade row is locked on the tapped grade and draws no change; no spinner — a local write is well
under 300 ms.

Golden: none — no golden in V8 (record 16a)

### `save_failed` · Save failed

The session ends as failed and SCR-STUDY-009 opens on its save error.

Golden: none — no golden in V8 (record 16a)

### `stale` · Session invalidated

A reset or an algorithm change elsewhere invalidates the session on the next write, and
SCR-STUDY-009 opens with the reason, or the app returns to the deck for a reset.

Golden: none — no golden in V8 (record 16a)

## Controls

### Session, interval preview

- Type: read
- Invokes: FN-STUDY-004, FN-STUDY-013
- Purpose: the preview is read when the card is served, so the grades have it at the reveal; a
  failed read shows no interval.

### Prompt card, Show answer

- Type: card button / study button
- Purpose: reveals the answer; revealing writes nothing, and a revealed card is not an answer.

### Again, Hard, Good, Easy

- Type: grade buttons
- Enabled when: the answer is revealed, 400 ms have passed since the reveal, and no write runs — so a
  double tap grades nothing more than once.
- Invokes: FN-STUDY-005
- Purpose: one tap commits the turn and advances, with no confirm step. No swipe or long-press grades.
  Again brings the card back after at least three other cards, or at the end of the queue; its third
  relearning turn takes it out of the queue and flags it. No toast per answer.

#### On failure

- As every session screen (SCR-STUDY-003): a write that can go on → the unsaved-answer banner; one
  that cannot → `save_failed`; a stale generation → `stale`.

### Close, system Back, exit dialog

- Type: icon button / back / dialog
- Invokes: FN-STUDY-009
- Purpose: the exit dialog of every session screen; everything answered is kept.

## Responsive Behavior

From text scale 1.3 the grade row becomes a 2 × 2 grid. A face grown by large text never slides under
its label. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- TalkBack reads the prompt, then "Show answer". After the reveal, focus moves to the answer card,
  then to the grades. Each grade is one node, "Good, next in 6 days", or just "Again" on a relearning
  turn.
- Stacked diacritics follow the single-line rule where a line is ellipsized; card faces wrap and
  never ellipsize.
- Touch targets are at least 48 × 48, with 8 between the grades.
- The answer card fades and slides in (fade-through, standard easing); with Remove animations on, it
  appears at once.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A grade is never committed by accident: the row settles 400 ms after the reveal and locks during a write. | — |
| Revealing writes nothing. | — |
| The four grades are named by their labels, never by colour alone. | — |
| A relearning turn shows no interval preview. | — |
| A resumed session opens on its current card unrevealed, with the direction of its queue row. | — |

## Copy

- "Self-assess" · "Show answer" · "Again" · "Hard" · "Good" · "Easy" · "{n}d" · "{n}mo" · "{n}y".
- Interval format: under 30 days "{n}d"; under a year "{n}mo" (days / 30, rounded); from a year "{n}y"
  (one decimal, a trailing ".0" dropped).
- Footer hints: "Recall the answer, then show it" · "Be honest — grade how well you remembered".
- TalkBack: "{grade}, next in {interval}".

## Rulings

- **FE-A6 P2 plan R1:** the mode badge and context line read "Self-assess", as the resume banner and
  the card screens name the mode.
- **Plan R2:** the recessed answer face is always laid out, with a still placeholder bar until the
  reveal; the answer fades in inside it, so the prompt never moves.
- **Plan R3:** while the grade is written the row takes no tap and draws no change; a local write is
  well under 300 ms.
- **Plan R4:** the interval preview is read when the card is served, so the grades have it at the
  reveal.
- **Spec A5:** on a relearning turn the preview is hidden, not drawn as "0d".
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the grades
  settle for 400 ms after Show answer, so a double tap grades nothing (R1); they keep their rounded
  rectangles, as they judge rather than act (R7).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is
  info (F7).
- **Anti-goals (shape brief, FE-A5):** no colour-coded rainbow of four grades and no new rating
  tokens; no swipe-to-grade, no auto-advance timer, and no per-answer toast or confetti; no editing a
  card mid-session.
- **Migration 2026-10-04:** the legacy study `ui.md` drew the assessment buttons from the algorithm's
  actions, two for eight boxes; eight boxes never runs `self_assess` (its stages are browse, match,
  guess, recall, fill), so this screen only ever shows SM-2's four grades.
