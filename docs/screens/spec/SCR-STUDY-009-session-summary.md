---
id: SCR-STUDY-009
name: Session summary
domain: study
status: ready
route: [/study/session/:sessionId]
---

# Session summary

## Purpose

The terminal screen of a study session, on the session's own route: shown once the session is no
longer in progress and its summary is set. It says how the session ended and what it changed. A
session refused for a stale generation never reaches it: the write is refused, the session closes
and the app returns to the deck list.

## Related Use Cases

- UC-STUDY-001

## Layout

- **App bar** — the title only, in muted ink: "Session summary" (content density). With no leading
  control the title starts on the gutter. No back control, no actions.
- **Hero** — a hero card with a large icon tile (44) in the outcome's tone — ok `success`, paused
  tinted, ended `warning`, error `danger` — a title, one body sentence with the headline count bold,
  and — where the session has facts — only the numbers the body does not state: the finished count
  when the body has none (an interrupted session), Answered when it differs from the finished count,
  and Wrong turns "{wrong} of {total}", with "Wrong cards came back in later rounds." under the tiles
  when wrong > 0 and the session finished. The eyebrow keeps the deck name as typed ("REVIEW SESSION
  · Nhà hàng"); the stat labels are eyebrows. When it fits, the hero and its note sit centred between
  the app bar and the footer; longer content scrolls from the top.
- **Facts** — "This session" and a full-bleed card of three list rows: finished (the label depends on
  the session kind), cards answered, wrong turns — each leading a small tinted icon tile, trailing the
  value in tabular numerals, in `warning` when wrong > 0. Shown only where the hero draws no
  stats (reset, content deleted, save error); omitted where the session has no facts. In an ended or
  failed session the finished row reads "Kept in the history" on a neutral tile in `on-surface`, and the
  wrong turns read "of {total} turns".
- **End note** — one calm info line, only for the states that need it.
- **More due** — after a review that reached its card limit while the tree still has cards due: "{n}
  more cards are due." with "Study this deck" to start the next session at once; under the limit it is
  not stated.
- **Footer** — outline "Study this deck" (hidden once the outcome is ended or error) and primary
  "Done", with a caption line under them; the two buttons keep 8 between them.

## States

### `loaded` · Review finished

A completed review.

Golden: light, dark

### `learning` · Learning finished

A completed learning session: finishing the stage sequence is the event, not a graded turn.

Golden: light, dark

### `large` · Review at the session limit

A completed review whose queue reached the card limit the session opened with: "— the session
limit".

Golden: light, dark

### `left_early` · Left early

The person left; the turns already answered are kept. From a review: "The {n} cards you reviewed
are kept. The other {m} are still due."

Golden: light, dark

### `interrupted` · Interrupted

Yesterday's session, not resumed today and closed by the system.

Golden: light, dark

### `reset` · Ended by a reset

Learning progress was reset while the session was open; reached on returning to it.

Golden: light, dark

### `scheduler_changed` · Ended by an algorithm change

No Facts card; the end note "Nothing was lost — the answers are in the history."

Golden: light, dark

### `save_error` · Stopped by a save error

The turns saved before the failure are kept.

Golden: light, dark

### `content_deleted` · Ended, content moved to Trash

"Ended — content moved to Trash", the facts, and the note "Restore the card from Trash to include it
in the next review."; then Done leads back to the list.

Golden: light, dark

### `nothing_answered` · Nothing answered

A session that ended before its first turn: the hero without stats and no Facts card.

Golden: none — no golden in V8 (record 21)

### `loading` · Loading

Not reachable: the summary arrives with the session's view, and the route's first load is a spinner.

Golden: none — no golden in V8 (record 21)

## Controls

### Summary

- Type: read
- Invokes: FN-STUDY-004

### Study this deck

- Type: outline button
- Enabled when: the outcome is neither ended nor error.

#### On success

- Navigate to: SCR-STUDY-002

### Done

- Type: primary button
- Enabled when: the summary has loaded.

#### On success

- Navigate to: SCR-DECK-001 (back to the deck).

## Responsive Behavior

A short summary sits centred between the app bar and the footer; longer content scrolls from the
top. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- TalkBack reads the title, then the hero (title, body, then each stat as one node "{label}:
  {value}"), the facts, the note and the footer. The hero glyph is decorative.
- Touch targets are at least 48 × 48; the two footer buttons keep 8 between them.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A stat tile states only what the body does not. | — |
| Facts show only where the hero draws no stats. | — |
| Every session that ends says how it ended. | — |
| "Study this deck" is hidden once the session ended or failed. | — |

## Copy

- App bar: "Session summary".
- Hero titles: "Review finished" · "Learning finished" · "You left early" · "Session interrupted" ·
  "Ended by a reset" · "Ended by an algorithm change" · "Stopped by a save error" · "Ended — content
  moved to Trash".
- Hero bodies: "You reviewed {n} cards. Their next due dates are set." · "{n} cards finished
  learning. They come back tomorrow at 00:00." · "You reviewed {n} cards — the session limit." · "The
  {n} cards you finished are kept. The other {n} stay new and will be offered again." · "The {n}
  cards you reviewed are kept. The other {m} are still due." · "This session from yesterday was
  closed by the system and could not be resumed today. Every answer you gave is kept." · "Learning
  progress of this deck was reset while you were studying, so this session could not continue.
  Answers given before the reset stay in the history of the earlier cycle." · "The deck switched to a
  different review algorithm, so its learning sequence changed. Every card is new again; Done takes
  you back to the deck to start learning." · "An answer could not be written to this device, so the
  session stopped. Everything saved before that is kept; the unanswered cards are still due."
- Facts: "This session" · "Cards that finished learning" / "Cards reviewed" · "Kept in the history" ·
  "Cards answered" · "Wrong turns" · "{wrong} of {total}" · "of {total} turns" · "Wrong cards came
  back in later rounds."
- More due: "{n} more cards are due." (one: "1 more card is due.").
- End notes: "Nothing was lost — the answers are in the history." · "Restore the card from Trash to
  include it in the next review."
- Footer: "Study this deck" · "Done" · "Done returns you to the deck." · "Loading your summary…".

## Rulings

- **Critique 2026-09-30 part 3c-1 (spec `2026-09-30-critique-fixes-part3c1-design.md`), R3, amends
  FE-A6 D17:** a tile states only what the body does not; the finished tile is gone except after an
  interruption, whose body states no count, Answered shows only when it differs, Wrong turns is
  explained under the tiles. R4: a short summary sits centred.
- A stale generation never reaches this screen: the write is refused, the session closes, and the
  app returns to the deck list; it is not folded into `reset`. `reset` here is a reset only.
- "Study this deck" opens the Study Entry; both ship in FE-A6.
- The app bar title uses the content bar's title role; the hero glyph is a large icon tile (44) in the
  outcome tone.
- Fact rows are list rows; the wrong-turns sub-line wraps in the note role in the row's sub-line
  slot.
- The summary carries "answered" and "total turns" for the hero's three stats: finished, answered,
  wrong/total.
- **Critique 2026-09-30:** the wrong-turns value reads "{wrong} of {total}" ("{wrong} trên
  {total}").
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  hero's overline is an eyebrow that keeps the deck name as typed ("REVIEW SESSION · Nhà hàng"); the
  stat labels are eyebrows.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** "Wrong cards came back in
  later rounds." follows only a finished session; the facts of an ended or failed session read "Kept
  in the history" under the finished count, on a neutral tile with the value in `on-surface`, and "of
  {total} turns" under the wrong turns (F1).
- **FE-A6 spec D18:** a session that ended before its first turn shows the hero without stats and no
  Facts card, as `scheduler_changed` does.
- **Owner 2026-09-28 (UC-STUDY-001 A5):** a session ended because its deck went to the Trash shows
  the summary "Ended — content moved to Trash", then the list.
