---
id: SCR-STUDY-002
name: Study entry
domain: study
status: ready
route: [/decks/deck/:deckId/study]
---

# Study entry

## Purpose

The Study Entry of an open deck: the choice between learning new cards and reviewing due ones
before a session opens, never mixed. Opened from a deck row of Study home (SCR-STUDY-001), "Study
this deck" on an open deck (SCR-DECK-001, SCR-CARD-001) and on the session summary
(SCR-STUDY-009). Only an explicit choice here opens a session.

## Related Use Cases

- UC-STUDY-001
- UC-STUDY-003

## Layout

- **App bar** — back, the deck name, and the trailing "Study options" icon (content density).
- **Breadcrumb** — Library › ancestors › deck.
- **Hero** — a plain card (a summary, not a door): the eyebrow names the algorithm alone ("EIGHT
  BOXES", "SM-2"); a plain line "Up to {n} cards per session"; two stat tiles, New and Due — Due
  above zero in primary, New above zero muted, a zero in plain ink; the two sets never merge. "{n}
  of the due cards are overdue" in the warning ink when any are overdue.
- **Resume banner** — a card: the eyebrow "Session from today" with a static primary dot, "{kind} ·
  {mode} · {done} of {total} cards", a 4-tall progress track, a line explaining Continue against
  starting fresh, and "Continue" (primary block). Shown only for a session of this deck still open
  today.
- **Nothing-due state** — a compact empty state in the success tone, "Nothing to do right now": a
  normal state, not an error; no session can be opened and nothing reviews early.
- **Learn row** — a full-bleed card of one list row: "Learn new cards", the subtitle "{stage
  description} · {n} of {n} new · in creation order", and a trailing compact "Learn" (the secondary
  tone with the sparkles glyph) while a review leads the footer. With only new cards, the footer
  offers Learn and the row has no button.
- **Review options (eight boxes)** — a section header "Review · choose how cards are asked", a
  full-bleed card of option rows — Match · Guess · Recall · Fill — each with its own badge "{n}
  cards", or "Not available" with the reason as the row's subtitle, and a note. Browse never
  appears. A single available mode skips this list. SM-2 has one mode, so the list never appears for
  it.
- **Inline banners** — `refused` (warning): the counts changed since the screen opened, with its own
  title per reason. `start_failed` (danger): the write failed; nothing was saved.
- **Footer** — a caption line and one block button: "Learn {n} new cards" / "Review {n} due cards" /
  "Continue" / "Start a new review instead" / "Try again". Primary, or outline while the resume
  banner shows (Continue is then the one primary). While a session opens: a spinner, "Starting…" in
  the caption, and the button and every option lock.
- **Direction sheet (SM-2 only)** — opened by the footer's Review: a bottom sheet with a header, a
  note that leads with the lock ("The direction can't change once the session starts."), three
  option rows — Term first (recommended, selected first), Meaning first, Mixed — each with a
  one-line description naming no language, and one "Start review" button that locks the sheet while
  the session opens. A tap on a row only selects. Closing the sheet — a swipe down or a tap outside —
  writes nothing.

## States

### `sm2` · SM-2 deck

The hero and counts; the direction is chosen in the direction sheet.

Golden: light, dark

### `eight_box` · Eight-boxes deck

The mode list is inline.

Golden: light, dark

### `only_new` · Only new cards

Due = 0: only the Learn row and its footer action show.

Golden: light, dark

### `nothing` · Nothing to do

The positive empty state, no footer.

Golden: light, dark

### `resume` · Session from today

The Continue banner; the footer's start is outline.

Golden: light, dark

### `starting` · Starting

The footer shows the spinner; every option locks.

Golden: light, dark

### `refused` · Refused

The inline warning banner; the footer is rebuilt from the up-to-date counts and stays usable; the
banner stays until the next start.

Golden: light, dark

### `start_failed` · Start failed

The inline danger banner; the footer offers "Try again", repeating the same start, direction
included.

Golden: light, dark

### `loading` · Loading

Skeletons in the hero and option-list shapes.

Golden: light, dark

### `direction_sheet` · Direction sheet

Golden: light, dark

## Controls

### Entry data

- Type: read
- Invokes: FN-STUDY-001

#### On failure

- The deck deleted while the entry is open → the toast "This deck no longer exists", and the entry
  closes.

### Study options (app bar)

- Type: icon button

#### On success

- Navigate to: SCR-SETTINGS-001

### Learn (row), Learn {n} new cards (footer)

- Type: compact button / footer button
- Enabled when: new cards exist and no session is opening.
- Invokes: FN-STUDY-002

#### On success

- Navigate to: SCR-STUDY-003 (a learning session starts with browse).

#### On failure

- A refusal (no new cards left) → `refused`; a database failure → `start_failed`.

### Mode option rows (eight boxes)

- Type: option rows
- Enabled when: the mode is available.
- Purpose: picks the review mode; the first available one is picked at first, and the pick is not
  kept.

### Review {n} due cards (footer)

- Type: footer button
- Enabled when: cards are due and no session is opening.
- Invokes: FN-STUDY-003
- Purpose: on eight boxes, opens the review in the picked mode; on SM-2, opens the direction sheet.

#### On success

- Navigate to: SCR-STUDY-005, SCR-STUDY-006, SCR-STUDY-007, SCR-STUDY-008 (the picked mode).

#### On failure

- A refusal (nothing due, a mode that no longer runs) → `refused`; a database failure →
  `start_failed`.

### Direction rows, Start review (direction sheet)

- Type: option rows / sheet action
- Enabled when: no session is opening.
- Invokes: FN-STUDY-003

#### On success

- The sheet closes; the footer shows `starting`. Navigate to: SCR-STUDY-004.

#### On failure

- `modeNotOffered` (the root switched to eight boxes or was reset meanwhile) → the banner
  "Self-check is no longer offered for this deck."; nothing due any more → its own refusal
  banner; nothing written.

### Continue

- Type: primary block button
- Invokes: FN-STUDY-010
- Purpose: takes up today's session at its saved turn, with its saved direction; the direction sheet
  is not asked again.

#### On success

- Navigate to: SCR-STUDY-003, SCR-STUDY-004, SCR-STUDY-005, SCR-STUDY-006, SCR-STUDY-007,
  SCR-STUDY-008 (the session's mode screen).

#### On failure

- The session ended meanwhile → `refused` ("That session can't be continued."); a database failure →
  `start_failed`.

### Start a new review instead

- Type: outline footer button
- Invokes: FN-STUDY-003
- Purpose: ends today's open session (its answers kept) and starts a review.

### Try again (`start_failed`)

- Type: footer button
- Invokes: FN-STUDY-002, FN-STUDY-003
- Purpose: repeats the same start, direction included.

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- TalkBack reads the app bar, the breadcrumb, the hero (eyebrow, then "New: {n}", "Due: {n}" — each
  stat tile is one node), the overdue note, then the rows and the footer. The resume dot is
  decorative.
- Single-line text that ellipsizes keeps line-height 1.5 for stacked marks. Touch targets are at
  least 48 × 48.
- While a session opens, the locked footer and options stay in the reading order and read as
  disabled.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| New and Due are two numbers, never merged. | — |
| With nothing due there is no way to review early. | — |
| Only one session opens per press; while it opens, every choice locks. | — |
| SM-2's direction is chosen in a sheet, never inline; a row tap only selects. | — |
| While an open session shows, Continue is the one primary. | — |
| Browse is never offered as a review mode. | — |

## Copy

- Hero: "{algorithm}" · "Up to {n} cards per session" · "New" · "Due" · "{n} of the due cards are
  overdue".
- Resume: "Session from today" · "{kind} · {mode} · {n} of {n} cards" · "Continue where you
  stopped, or start something new — that ends this one and keeps its answers." · "Continue".
- Nothing: "Nothing to do right now" · "Every card is learned and resting. Cards cannot be reviewed
  before they are due."
- Learn row: "Learn new cards" · "Browse, then self-assess" (SM-2) / "Browse → match → guess →
  recall → fill" (Eight boxes) · "{n} of {n} new · in creation order" · "Learn".
- Review options, Eight boxes: "Review · choose how cards are asked" · "Match" "Pair terms with
  meanings, up to 5 at a time" · "Guess" "Pick the meaning out of five" · "Recall" "Recall the
  meaning within 20 seconds" · "Fill" "Type the term for the meaning" · "{n} cards" · "Not
  available" · "A mode that is not available lacks suitable cards for this review — it comes back
  when the cards qualify."
- Direction sheet, SM-2: "Review · question direction" · "Term first" "See the term, recall the
  meaning" · "Meaning first" "See the meaning, recall the term" · "Mixed" "Half each way, evenly
  split" · "The direction can't change once the session starts. SM-2 has one review mode: reveal,
  then grade yourself again · hard · good · easy." · "Start review".
- Banners: "Nothing is due any more." "The due cards were reviewed from another session or deleted
  since this screen was opened. Counts are up to date now." · "No new cards left to learn." "They
  were learned in another session or deleted since this screen was opened. Counts are up to date
  now." · "This mode can't run on the due cards any more." "The due cards changed since this screen
  was opened. Counts are up to date now." · "Self-check is no longer offered for this deck." · "That
  session can't be continued." "It ended since this screen was opened, and its answers are kept.
  Start a new one below." · "Couldn't start the session." "Nothing was written. Try again."
- Footer: "Learn {n} new cards" · "Review {n} due cards" · "Starting…" · "Try again" · "Start a new
  review instead" · captions "Nothing is due — review is available once cards come due." · "{mode} ·
  oldest first" (Eight boxes) · "{shown} of {due} due · oldest first" (SM-2).
- Deck gone: "This deck no longer exists".

## Rulings

- **UC-STUDY-003:** SM-2's direction is chosen in a separate bottom sheet opened by the footer's
  Review action (three choices, then "Start review"), never inline; the space above the pinned
  footer stays empty.
- **UI-base row 28, FE-A8 ruling S3:** the resume dot is primary and static, as on SCR-STUDY-001.
- **FE-A8 H2:** the resume banner carries a linear progress track under its line.
- **Plan R5:** on `refused` the footer is rebuilt from the up-to-date counts and stays usable; the
  banner stays until the next start.
- **Plan R6:** while starting, the button spins and "Starting…" is the footer's caption.
- **Plan R7:** "Start review" answers the choice and closes the sheet; the entry footer shows
  `starting`, and Try again repeats the review with the same direction.
- **Plan R8:** the SM-2 caption reads "{shown} of {due} due · oldest first".
- **Plan R9:** each refusal has its own title: nothing due, no new cards, a mode that no longer
  runs, a session that can no longer be continued.
- **Critique 2026-09-30 part 1:** while an open session shows, "Continue" is the one primary and the
  footer's start (Review instead or Learn) is outline, since it ends that session (DESIGN.md One
  Indigo).
- **FE-A6 P3 ruling C5:** `eight_box` picks the first available mode at first; the pick is not kept.
- The Learn button is the secondary tone with the sparkles glyph.
- Direction descriptions name no language ("See the term, recall the meaning"): a card is
  language-agnostic.
- **Owner 2026-09-28 (UC-STUDY-003 E1):** a session refused because self-check is no longer offered
  has its own banner.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  hero's algorithm overline is an eyebrow.
- **Critique 2026-09-30 part 3c-1, R5:** the per-session limit is its own plain line, so no word is
  left alone on a wrapped line.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** with only
  new cards, Learn is offered by the footer alone; the Learn row keeps its button when a review leads
  the footer (D2).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the hero
  is a plain card (a summary, not a door; DESIGN.md "a hero leads somewhere tappable"); its tiles and
  lines are unchanged.
- **IMPLEMENTATION GAP — next due time on the nothing-due state.** Required: UC-STUDY-001 step 2 and
  E1 have the person learn when the nearest card comes due, and FN-STUDY-001 returns that time when
  nothing is due. Current V8 implementation: the entry's nothing-due state says "Every card is
  learned and resting. Cards cannot be reviewed before they are due." with no time (Study home's
  zero card does name the next due day). Status: IMPLEMENTATION GAP. No code changes in this
  migration.
