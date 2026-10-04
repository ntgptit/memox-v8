---
id: SCR-STUDY-001
name: Study home
domain: study
status: ready
route: [/study]
---

# Study home

## Purpose

The Study tab's landing screen: the session that can be resumed, and every root deck with its
whole-tree workload, read as one snapshot. It writes nothing but Resume. Opened from the Study tab,
the `/study` deep link, the return after a session, and a tap on the daily reminder
(FN-REMINDER-005).

## Related Use Cases

- UC-STUDY-002

## Layout

- **App bar** — "Study" (screen density); no date.
- **Resume card** — a hero card with an icon tile: the eyebrow "Continue studying" with a static
  primary dot; the deck's name; "{kind} · {mode} · {done} / {total} cards"; a thin 4-tall progress
  track; "Resume", a primary block button with the play glyph. Shown only when a session can be
  resumed (FN-STUDY-012); otherwise nothing takes its place — not an empty card, not a disabled
  button.
- **Workload card** — a plain card (a summary, not a door; sessions start per deck): the eyebrow
  "Waiting for you", "{n} cards due" over its two halves, overdue · today, "across {k} decks"; new
  cards are not in the hero, they show in each deck row. Zero workload swaps to a calm card shaped
  like an empty state, with a check tile in the success tone: "Nothing due right now" — not an
  error, not an achievement — and the next due day.
- **Section header** — "Your decks" with a trailing compact secondary "Library".
- **Rows** — a full-bleed card of list rows: an icon tile ("layers"); the deck name; the workload
  line overdue · today · new, always shown even at 0, each led by its glyph (history, zap,
  sparkles) in its ink, a zero term muted; "No cards yet" for a deck with no card. A chevron on every
  row that can be studied; the counts are in the meta line, so there is no due badge. A deck with no
  card has no chevron and no tap target. Rows are ordered Overdue ↓ Due today ↓ New ↓ name.
- **Floating notice** — one slot over the bottom of the loaded page. The sync notice shows when a
  change has waited more than 24 h or the server refused a row, with "Details" (outline) on the
  message line and no close button; hidden on a build without a server, while loading, on a read
  error and when the sync status fails. The re-auth notice, while the sign-in is refused, takes the
  slot over the sync notice, with "Sign in".

## States

### `loaded` · Loaded

The hero's due breakdown (overdue · today) and the primary resume dot.

Golden: light, dark

### `no_resume` · No session to resume

The same workload card and deck list, no Resume card.

Golden: light, dark

### `zero` · Nothing due

Every root deck holds cards but nothing is due; rows still list every deck with 0 · 0 · 0. The
body says "…tomorrow." on the next local day, "…on {date}." later, and "Every card is resting."
with no next date.

Golden: light, dark

### `no_decks` · No decks

"Nothing to study yet", with "Browse starter decks" and "Go to Library".

Golden: light, dark

### `no_cards` · No cards

Root decks exist, none holds a card; no invented Due number; "Go to Library" only, no starter
button.

Golden: light, dark

### `loading` · Loading

A two-bar hero skeleton and skeleton rows.

Golden: light, dark

### `error` · Error

The error state with Retry; no table, query or path names; the body says the cards are safe and
Library still opens.

Golden: light, dark

### `sync_rejected` · Sync notice, refused rows

Golden: light, dark

### `sync_stale` · Sync notice, a change waiting over a day

Golden: light, dark

### `reauth` · Re-auth notice

Golden: light, dark

## Controls

### Snapshot

- Type: read
- Invokes: FN-STUDY-012

#### On failure

- A database failure → `error`.

### Resume

- Type: primary block button
- Invokes: FN-STUDY-010

#### On success

- Navigate to: SCR-STUDY-003, SCR-STUDY-004, SCR-STUDY-005, SCR-STUDY-006, SCR-STUDY-007,
  SCR-STUDY-008 (the session's mode screen, at the saved turn).

#### On failure

- A refusal → the toast "This session can't be continued any more"; a failed write → "Couldn't
  start the session."; the snapshot refreshes by itself.

### Deck row

- Type: list row
- Enabled when: the deck holds a card.

#### On success

- Navigate to: SCR-STUDY-002

### Library (section header), Go to Library

- Type: compact secondary button / empty-state action

#### On success

- Navigate to: SCR-DECK-001

### Browse starter decks (`no_decks`)

- Type: empty-state action

#### On success

- Navigate to: SCR-STARTER-001

### Details (sync notice)

- Type: compact outline button
- Invokes: FN-ACCOUNT-015

#### On success

- Navigate to: SCR-ACCOUNT-001

### Sign in (re-auth notice)

- Type: compact button
- Invokes: FN-ACCOUNT-002

#### On success

- Navigate to: SCR-ACCOUNT-003 (re-auth, under Settings; it returns here once signed in).

### Retry (`error`)

- Type: button
- Invokes: FN-STUDY-012

## Responsive Behavior

A row's and the hero's breakdowns wrap between whole terms (glyph, count, word and dot stay
together), never ellipsized, so all three counts show at any text size. Otherwise follows the
shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- The dot and the glyphs, the workload terms' included, are decorative; the progress track says
  nothing, as the line beside it states "{done} of {total} cards".
- A deck with no card is shown dimmed and read as a disabled button; every row is at least 48 tall.
- The hero title and "across {n} decks" are plurals.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| The screen writes nothing but Resume. | — |
| With no session to resume, nothing takes the Resume card's place. | — |
| A deck row always states its three counts, never merged. | — |
| A deck with no card has no tap target and no invented count. | — |
| The re-auth notice takes the notice slot over the sync notice. | — |

## Copy

- Header: "Study".
- Resume: "Continue studying" · "{kind} · {mode}" e.g. "Review · Self-assess" · "{done} / {total}
  cards" · "Resume".
- Workload: "Waiting for you" · "{n} cards due" · "across {n} decks".
- Workload, zero: "Nothing due right now" · "Every card is resting. The next one becomes due
  tomorrow." · "…on {date}." · "Every card is resting."
- Resume refused: "This session can't be continued any more" · "Couldn't start the session."
- Section: "Your decks" · "Library".
- No decks: "Nothing to study yet" · "Your library is empty. Copy a starter deck to begin with
  content, or create a deck in Library." · "Browse starter decks" · "Go to Library".
- No cards: "Your decks have no cards yet" · "Add cards to a sub-deck, or import them from a file,
  and they will show up here." · "Go to Library".
- Re-auth notice: "Your sign-in expired. Your decks are still on this phone." · "Sign in".
- Sync notice: "{n} changes weren't accepted." (one: "1 change wasn't accepted.") · "Some changes
  haven't synced in over a day. They're safe here." · "Details".
- Error: "Couldn't load your study overview" · "Your cards are safe on this device. You can still
  open Library directly."

## Rulings

- **Owner 2026-09-30:** the hero states "{n} cards due" over its two halves, overdue · today; new
  and scheduled cards are not in the hero, new ones show in each deck row.
- **UI-base row 28:** the resume dot and paused tile use primary; there is no streak tone.
- The app bar carries no date: its actions take buttons only and no UC calls for one.
- **FE-A8 ruling S3:** the dot beside "Continue studying" is static, as on SCR-STUDY-002; no looping
  motion. The resume progress is the shared 4-tall linear progress.
- **FE-A8 ruling S2:** the zero-workload body says "…tomorrow." on the next local day, "…on
  {date}." later, and "Every card is resting." with no next date.
- **FE-A6 spec D14:** the zero card's check tile uses the `success` tone; green is mastery's alone.
- **FE-A8 ruling S9:** Resume is a primary block button with the play glyph; "Go to Library" in
  `no_decks` is the empty state's neutral secondary action; `primary-soft` is preserve-only.
- **E-L3:** "Library" is a compact secondary button.
- The hero and row breakdowns wrap between whole terms, never cut; a deck with cards always states
  its three counts, a zero term muted, each led by its glyph (history, zap, sparkles) in its ink; a
  deck with no card reads "No cards yet".
- **UI-base ruling O3:** loading uses a two-bar hero skeleton and the standard skeleton rows.
- Empty-state actions carry no glyph.
- **Account UI spec R2, B5:** the re-auth notice takes the slot over the sync notice.
- **SB-U1 (sync status spec R2, UI-base row 143):** a floating sync notice shows under the sync
  status rules (ADR-015).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):**
  "Continue studying" and "Waiting for you" are eyebrows; Waiting for you no longer borrows the
  Required style, and its glyph follows the eyebrow's colour.
- **Critique 2026-09-30 part 3c-1, R2:** the workload card is not a hero: it is a summary, not a
  door; sessions start per deck.
- **Migration 2026-10-04:** the legacy UC-STUDY-002 named a scheduler label on each deck row; V8
  draws none and no BR asks for one, so the spec follows the app and UC-STUDY-002 keeps the intent
  only (owner precedent 2026-10-04, UC-DECK-003 tri-state icon).
