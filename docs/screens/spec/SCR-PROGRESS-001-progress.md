---
id: SCR-PROGRESS-001
name: Progress
domain: progress
status: ready
route: [/progress, /progress/:deckId]
---

# Progress

## Purpose

The Progress tab: what was studied today and over the last seven days, the current streak, and how
much each deck was studied over 7 or 30 days, level by level down the deck tree. It only reads. One
screen and one scroll serve both levels: the library level (`/progress`, the Progress tab of the
bottom bar) and a deck's level (`/progress/:deckId`, under the tab bar), pushed by a deck row. Each
row pushes one level and Back climbs one; the breadcrumb of a deck's level returns to any level above.

## Related Use Cases

- UC-PROGRESS-001
- UC-PROGRESS-002

## Layout

### Library level

- **App bar** — "Progress" (screen density).
- **Today** — a card: the eyebrow "Today", the day's card-days, and "{l} learning · {r} reviewing · a
  card counts once per day", "No cards studied yet today" or "Nothing studied yet". Below, stacked day
  bars for the last seven days, learning over reviewing, labelled by narrow weekday and "Today", with
  the legend. Every day's bars draw at full strength, reviewing in primary and learning in its ink,
  each holding 3:1 on the card; Today is told by its bold label.
- **Streak** — a card with one tile, "Current": the flame in the `streak` colour, "{n} days", and
  "includes today", "held from yesterday" or "no study yesterday". Today's figure is the Today card's
  alone. A held streak adds "Study one card today and the streak continues at {n}."; a lost one "The
  streak ended on {day}. It starts again with the next card you study." — the weekday within six
  days, else a short date.
- **Range** — a wide segmented tray "Last 7 days" · "Last 30 days", directly above the list it
  changes. Switching reads nothing.
- **List** — "By deck", then a card of list rows: the total row "All decks" with the four numbers
  and no chevron, then a row per root deck: the name, "{n} cards · {d} active days", and "Card-days:
  {l} learning · {r} reviewing" (learning in the learning ink, reviewing in the primary ink), ending in
  a chevron. An idle deck reads "No activity in this range", at full contrast, nothing dimmed. No
  header totals.
- **Quiet-range note** — "Nothing studied in the last 7 days. Switch to Last 30 days to see older
  study." (at 30 days, the first sentence only).
- **Footer line** — "Read-only · resets change nothing here".

### Deck level

- **App bar** — back and the deck's name.
- **Breadcrumb** — "Progress › … › {deck}".
- **Range** — at the top.
- **List** — "Sub-decks", the total row "Whole deck", and a row per direct child; then the footer
  line. A deck with no children adds "This deck holds its cards directly, so the total above is all of
  it."

The numbers follow every write and every local midnight, with no skeleton once shown.

## States

### `week` · Last 7 days

The range above the list; one total row, no header totals.

Golden: light, dark

### `month` · Last 30 days

Golden: light, dark

### `held` · Streak held

Golden: light, dark

### `lost` · Streak lost

Golden: light, dark

### `never` · Never studied

"Start studying" (primary, the only action) under Today's placeholder opens the Study tab; no range
and no by-deck list, which would read 0 everywhere.

Golden: light, dark

### `quiet` · Quiet range

The note under the list; every deck still listed.

Golden: light, dark

### `no_decks` · No decks

Only "No decks yet · Create a deck in the Library and its progress appears here.". No range, no
total, no button.

Golden: light, dark

### `loading` · Loading

The screen's own skeleton: a Today card, a Streak card and a deck-list card; a deck's level shows the
deck-list card under its range control.

Golden: light, dark

### `error` · Error

With Retry, under the alert glyph: a local read failed, not the network.

Golden: light, dark

### `deck` · Deck level

The "Whole deck" total row and a row per sub-deck.

Golden: light, dark

### `deck_leaf` · Deck without sub-decks

The total row and its note.

Golden: light, dark

### `deck_gone` · Deck gone

"This deck is no longer here" with Back; no Retry, since reading again fails the same way.

Golden: light, dark

## Controls

### Library level data

- Type: read
- Invokes: FN-PROGRESS-001

#### On failure

- A database failure → `error`.

### Deck level data

- Type: read
- Invokes: FN-PROGRESS-002

#### On failure

- The deck missing → `deck_gone`; a database failure → `error`.

### Range tray

- Type: segmented tray
- Purpose: switches every number and the order at once; nothing is read again. The choice is shared by
  every level of the tab: a deck opened from "Last 30 days" is at 30 days too.

### Deck row

- Type: list row

#### On success

- Navigate to: SCR-PROGRESS-001 (that deck's level, pushed under the tab bar).

### Breadcrumb segment, Back

- Type: breadcrumb / back
- Purpose: returns to the level chosen, or climbs one.

### Start studying (`never`)

- Type: primary button

#### On success

- Navigate to: SCR-STUDY-001

### Retry (`error`)

- Type: button
- Invokes: FN-PROGRESS-001, FN-PROGRESS-002

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The day bars and the streak are stated in text as well as drawn. Otherwise follows the shared floor
(DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| The screen only reads; no action writes. | — |
| Switching the range reads nothing. | — |
| Once shown, numbers update in place with no skeleton. | — |
| A deck with no activity is listed at full contrast, never dimmed. | — |
| A deck gone offers Back, never Retry. | — |

## Copy

"Progress" · "Today" · "{l} learning · {r} reviewing · a card counts once per day" · "No cards studied
yet today" · "Nothing studied yet" · "Learning" · "Reviewing" · "Streak" · "Current" · "{n} days" ·
"includes today" · "held from yesterday" · "no study yesterday" · "{n} cards" · "counted once each" ·
"nothing yet" · "Study one card today and the streak continues at {n}." · "The streak ended on {day}.
It starts again with the next card you study." · "Your last seven days appear here once you study.
Browsing cards does not count." · "A streak starts with your first study day." · "Start studying" ·
"Last 7 days" · "Last 30 days" · "By deck" · "Sub-decks" · "All decks" · "Whole deck" · "{d} active
days" · "{l} learning" · "{r} reviewing" · "cards" · "No activity in this range" · "Nothing studied in
the last 7 days. Switch to Last 30 days to see older study." · "No decks yet" · "Create a deck in the
Library and its progress appears here." · "This deck holds its cards directly, so the total above is
all of it." · "Read-only · resets change nothing here" · "Couldn't summarise your progress" · "Your
study history is safe on this device. Try again in a moment." · "This deck is no longer here".

## Rulings

- **UC-PROGRESS-001 step 4, UC-PROGRESS-002 step 1, D10:** the range tray sits directly above the list
  it changes.
- **D2:** the list has a total row with the four numbers, no header totals.
- **Critique P2, D11:** an idle deck row keeps full contrast and reads "No activity in this range" (its
  0 went with the trailing count, critique 2026-09-30 part 3d-1).
- **UC-PROGRESS-001 A2, D1:** never studied shows the placeholders plus "Start studying" to the Study
  tab.
- **UI-base row 125:** loading shows the screen's own skeleton (Today, Streak and deck-list cards), not
  generic rows (part 3d-2).
- **UC-PROGRESS-002 A1–A3, E2:** quiet range, no deck, leaf and gone states are built from the UC.
- **D4, D5, D8:** the deck level is pushed under the tab bar, Back climbs one level, the range is shared
  across levels, and numbers update at writes and at local midnight with no skeleton once shown.
- **Critique 2026-09-30:** Today's figure is the Today card's alone; the error sits under the alert
  glyph, a local read, not the network; the never-studied state shows no range and no list.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the
  Today label and the streak labels are eyebrows; the list headers stay section labels.
- **Critique 2026-09-30 part 3b:** "By deck" names no range, which the segment above states; the
  footer line drops the once-a-day rule, which Today states.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** a deck row's
  meta reads "{n} cards · {d} active days" then "Card-days: {l} learning · {r} reviewing", and it ends
  in a chevron; the total row has none; the never-studied "Start studying" is primary (D3).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** loading shows
  the screen's own skeleton, a Today card, a Streak card and a deck-list card; deck progress keeps its
  range control and shows the deck-list card.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** every day's bars draw at full
  strength, reviewing in primary and learning in its ink, each holding 3:1 on the card; Today is told
  by its bold label (F5).
