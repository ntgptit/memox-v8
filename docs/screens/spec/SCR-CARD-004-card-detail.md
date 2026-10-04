---
id: SCR-CARD-004
name: Card detail
domain: card
status: ready
route: [/decks/card/:cardId]
---

# Card detail

## Purpose

A card, read-only, pushed over the card list (not replacing it): its content, its current
schedule and its full review history, newest first, grouped by cycle. A tap on a card row opens it
(SCR-CARD-001); so do a card result of the library search (SCR-SEARCH-001) and the editor's history
summary (SCR-CARD-003). Editing is a separate, explicit action.

## Related Use Cases

- UC-CARD-002

## Layout

- **App bar** — back; title "Card" (content density); a trailing compact secondary "Edit", shown
  only once the card has loaded.
- **Deck path** — a persistent breadcrumb: Library › ancestors › deck › "Card"; shown only once
  the card has loaded, since the detail can open from an id alone and the deck is unknown until
  then.
- **Content** — a card: the status badge and the flag glyph in their own row, full width, above the
  front and back; the front, the back; only the optional fields that hold a value; the tag chips.
- **Schedule** — a card with the eyebrow "Current schedule · Box {n} of 8" and an 8-bar ramp
  (eight boxes), or "Current schedule · SM-2" (no ramp); fact tiles Due, Learned, Last answered,
  Answers, Lapses (the last three only once the card has an answer), plus Ease, Interval and
  Repetitions for SM-2. The paired facts come first; "Algorithm" takes a full-width row of its own
  after them.
- **History header** — "History" / "History · newest first".
- **History list** — cycle groups "Cycle {n} · {scheduler}", newest first, the header an overline
  label only (the reset date is not stored). Each event is a plain card at radius 12: the outcome
  badge ("Again", "Good", "Remembered", "Forgot"…) in its tone — success for a right answer,
  warning for a lapse, neutral for relearning — with the kind ("Learning", "Review", "Repeat") as
  plain text beside it; the absolute date and time; then metadata lines as text without glyphs
  (mode, box / ease / interval before → after, hint used, time ran out, next due). No rail, no
  dots, no relative time, no free-text note.
- **Load more** — a secondary block "Load older history" at the end of the list, or, after a
  failure, a danger banner with Retry under its message; what loaded stays.
- **End of history** — a centred caption "Beginning of history · card added {date}", instead of a
  dead load-more button.
- **Gone state** — an empty state "This card is no longer here" with Back to deck and Open Trash;
  the deck path is hidden.

## States

### `loaded` · Loaded

Golden: light, dark

### `history` · History in view

The history scrolled into view.

Golden: light, dark

### `load_more` · More history

The secondary block "Load older history".

Golden: none — no golden in V8 (record 10)

### `load_more_failed` · Older history failed

Retry sits under the message; what loaded stays. A page that arrives late, after the card or its
query changed, is dropped.

Golden: none — no golden in V8 (record 10)

### `empty` · Not studied yet

A neutral compact empty state "Not studied yet" explaining that every answer will appear here;
the content and schedule cards still show above it.

Golden: none — no golden in V8 (record 10)

### `loading` · Loading

A single generic skeleton list (4 rows) replaces the whole body.

Golden: none — no golden in V8 (record 10)

### `error` · Error

A full-screen error state "Couldn't load this card" with the shared "Nothing was lost. Try again in
a moment." and Retry.

Golden: none — no golden in V8 (record 10)

### `not_found` · Card gone

The gone state, shared with the editor's; both actions are live. The deck path is hidden. No blank
screen.

Golden: none — no golden in V8 (record 10)

## Controls

### Card content and schedule

- Type: read
- Invokes: FN-CARD-013

#### On failure

- A database failure → `error`; the card gone (in the Trash or deleted) → `not_found`.

### History

- Type: read
- Invokes: FN-CARD-014

### Load older history, Retry (history banner)

- Type: secondary block button / banner action
- Invokes: FN-CARD-014
- Purpose: reads the next page from where the list ended.

#### On failure

- `load_more_failed`.

### Edit

- Type: compact secondary button
- Enabled when: the card has loaded.

#### On success

- Navigate to: SCR-CARD-003

### Back

- Type: back
- Purpose: returns to the list under it.

### Retry (`error`)

- Type: button
- Invokes: FN-CARD-013

### Back to deck, Open Trash (`not_found`)

- Type: buttons

#### On success

- Back to deck returns to the screen under it; Open Trash — Navigate to: SCR-TRASH-001.

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The flag and the status are carried by text and glyph, not colour alone. Otherwise follows the
shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| The detail is read-only; editing is the explicit Edit action. | — |
| History is newest first and grouped by cycle. | — |
| A failed page keeps what loaded; a late page is dropped. | — |
| The end of history is a caption, not a dead button. | — |
| Only optional fields that hold a value are shown. | — |

## Copy

- App bar: "Card" · "Edit".
- Content: card front, back, "Example sentence" · "Hint" · "Pronunciation" (each shown only with a
  value), tag chips.
- Schedule: "Current schedule · Box {box} of {count}" · "Current schedule · SM-2" · "Box 1 · 1
  day" · "Box 8 · 128 days" · "Due" · "Learned" · "Last answered" · "Answers" · "Lapses" ·
  "Algorithm" · "{scheduler} · cycle {generation}" · "Ease" · "Interval" · "{count, plural, =1{1
  day} other{{count} days}}" · "Repetitions" · "Not yet".
- History: "History" · "History · newest first" · "Cycle {generation} · {scheduler}" · "Not
  studied yet" · "Every answer in a learning or review session will appear here, newest first." ·
  "Load older history" · "Couldn't load older history." · "What is shown is complete up to here." ·
  "Beginning of history · card added {date}" · "Box {from} → {to}" · "Ease {from} → {to}" ·
  "Interval {from}d → {to}d" · "Hint used" · "Time ran out" · "Next due {date}".
- History outcomes (badge) and kinds (plain text): "Learning" · "Review" · "Repeat" · "Remembered"
  · "Forgot" · "Again" · "Hard" · "Good" · "Easy".
- Error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".
- Gone: "This card is no longer here" · "It was moved to Trash while you were away. It can still be
  restored from Trash, with its history." · "Back to deck" · "Open Trash".

## Rulings

- **§9 row 89:** the status badge and flag sit above the front/back, full width.
- **§9 row 86:** history is a plain card per event with absolute date and time, no rail, dots or
  free-text note; a cycle header is the overline label only ("Cycle {n} · {scheduler}"), because
  the reset date is not stored.
- **§9 row 90 (amended, critique 2026-09-30 part 3d-2):** the badge carries the outcome
  ("Remembered", "Again"…); the kind ("Learning") is plain text beside it.
- **§9 row 50:** banner actions sit under the message.
- **UC-CARD-002 E1:** the deck path shows only once the card has loaded; the detail can open from
  an id alone, so the deck is unknown until then.
- **§9 row 125:** loading is a single generic skeleton list, the app-wide convention.
- **§9 row 115:** in-flow cards are at radius 12.
- The load error uses the app's shared local-first body "Nothing was lost. Try again in a moment."
  (as SCR-TRASH-001 and SCR-SETTINGS-002).
- **Critique 2026-09-30 tone pass, T5:** a history badge (it names the outcome, part 3d-2) is
  success for a right answer, warning for a lapse ("Again", "Forgot") and neutral for relearning.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  schedule card's title is an eyebrow; the read-only field labels are field labels in sentence
  case; the history's cycle headers stay section labels.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** a history
  badge names the outcome ("Again", "Good", "Remembered", "Forgot"…) in that outcome's tone
  (warning lapse, neutral relearning, success otherwise); the kind ("Learning", "Review",
  "Repeat") is plain text beside it; the metadata lines are text without glyphs; the schedule's
  "Algorithm" fact takes a full-width row of its own after the paired facts.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain ink
  everywhere, the card list included (F6).
