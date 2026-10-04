---
id: SCR-DECK-001
name: Deck list
domain: deck
status: ready
route: [/decks, /decks/deck/:deckId]
---

# Deck list

## Purpose

One recursive screen for the Library root (`/decks`) and for any open deck
(`/decks/deck/:deckId`). It shows a level of the deck tree with each deck's due work and
mastery, and is where decks are created, renamed, reordered, moved and moved to the Trash. A
deck that holds cards shows the card list (SCR-CARD-001) instead of sub-decks.

## Related Use Cases

- UC-DECK-001
- UC-DECK-002
- UC-DECK-003
- UC-DECK-004
- UC-DECK-005
- UC-DECK-006

## Layout

### Root

- **App bar** (large) — title "Library"; actions Starter decks (sparkles icon, SCR-STARTER-001), Tags
  (tag icon, SCR-TAG-001) and Trash (SCR-TRASH-001).
- **Search field** (trigger mode) — hint "Search decks"; a tap opens SCR-SEARCH-001 instead of typing
  here.
- **Due strip** (hero card with an icon tile and a workload breakdown line) — bolt tile on
  primary, "{n} cards due", then overdue · today (New is not due). A tap opens Study home
  (SCR-STUDY-001); a trailing chevron says so. Hidden when the library holds no card.
- **Section header** with a chip trigger — "{n} DECKS"; pill "Manual ⌄", or "Manual · Due only"
  tinted primary while the due filter is on.
- **Rows** — one card per deck, 8 apart: a 44 icon tile (layers = holds decks, copy = holds
  cards, folder-open = empty); the name on one line with ellipsis; a "{n} due" badge when due
  > 0; the meta "{n} sub-decks · {n} cards" or "Empty · add cards or a sub-deck"; the mastery
  bar (5 tall, 12 under the meta, across the text column, on `surfaceContainerLow`), the bare
  track for a deck with no card; a trailing `⋮` icon button.
- **Floating action button** — "New deck".

### Open deck

- **App bar** — Back, the deck's name, `⋮` (the deck's action sheet).
- **Breadcrumb** — Library › ancestors › deck.
- **Summary card** (hero), for a deck holding sub-decks — the level's mastery donut beside
  "MASTERED · {algorithm}", "{n} sub-decks · {n} cards", then overdue · today · new ·
  {n} scheduled. "Study this deck · {n} due" (primary block button; "Study this deck" when only
  new cards wait) opens the Study entry, SCR-STUDY-002; hidden when the subtree holds no card to
  study.
- **List** — as at the root. Header "Sub-decks" with the sort pill; the summary card states the
  count.
- **Floating action button** — "New sub-deck"; none at level 10, and none on an `unset` deck,
  whose empty state offers both choices.
- **By content type** — `unset`: an empty state with the two create choices and "Import cards
  from a file" (SCR-TRANSFER-001), all text-only block actions, Import as the outline third. `card`:
  the card list, SCR-CARD-001.

### Action sheet

A bottom sheet headed by the deck's name alone, with command rows and no count subtitles:

- **Root deck:** Open deck · Study this deck (SCR-STUDY-002) · Rename · Study options ("Cards per
  session · new-card order", SCR-SETTINGS-001) · Review algorithm ("{algorithm} · locked · reset to
  start over" when locked, SCR-SRS-001) · Reorder · Move to Trash ("Recoverable for 30 days").
- **Sub-deck:** Open · Study this deck (SCR-STUDY-002) · Rename · Study options (its root's options,
  SCR-SETTINGS-001) · Move to another deck · Reorder ("Move before or after a sibling") · Move to Trash
  ("Recoverable for 30 days").

### Sort & filter sheet

One bottom sheet, "Sort & filter":

- "Sort by" section label, then option rows: Manual order "Drag decks to arrange them" · Date
  added "Newest first" · Name "A → Z" · Most due cards · Progress "Least mastered first".
- A settings row with a toggle: "Only decks with due cards" / "Hides decks where nothing is
  waiting".
- Footer action "Done".

## States

### `root_loaded` · Root loaded

Every row carries its mastery bar; the learning band is the darker learning ink in light. The
due strip shows its chevron.

Golden: light, dark

### `root_loading` · Root loading

Skeletons in the row's shape; the header is kept.

Golden: none — no golden in V8 (record 01)

### `root_empty` · Root empty

"Create deck", then "Browse starter decks" (SCR-STARTER-001), and the footnote.

Golden: light, dark

### `root_error` · Root error

"Couldn't load your library" with Retry.

Golden: none — no golden in V8 (record 01)

### `root_search` · Root search

The field is a trigger: a tap opens SCR-SEARCH-001 instead of typing here.

Golden: none — no golden in V8 (record 01)

### `root_sort_filter` · Sort & filter sheet

Progress orders least mastered first, decks with no card last.

Golden: light, dark

### `root_due_empty` · Due filter, nothing due

"Nothing due right now" with "Show all decks".

Golden: none — no golden in V8 (record 01)

### `root_overflow` · Root deck action sheet

Rows as in "Action sheet"; Reorder included.

Golden: light, dark

### `root_reorder` · Reorder mode

One card per deck, 8 apart, as in browse mode; drag to reorder. The search field, the summary,
the due strip and the sort pill are hidden while decks are reordered, and return with Done.

Golden: light, dark

### `root_create` · Create root deck dialog

The create dialog; no algorithm is chosen up front.

Golden: none — no golden in V8 (record 01)

### `root_rename` · Rename dialog

The rename dialog.

Golden: none — no golden in V8 (record 01)

### `root_delete` · Move to Trash dialog

The dialog has no glyph and names the deck in quotes, not bold. The confirm button spins while
the deck moves.

Golden: light, dark

### `root_trashed` · Deck moved to Trash

The toast with Undo, for 8 seconds, and until acted on under TalkBack. A refused Undo says why:
"Can't undo. {reason} Restore it from Trash and choose a deck."

Golden: light, dark

### `deck_loaded` · Open deck loaded

The level's donut beside "MASTERED · {algorithm}"; the breakdown line wraps between whole
terms, never "…".

Golden: light, dark

### `deck_empty` · Open deck, unset

An `unset` deck: both create choices and "Import cards from a file" (SCR-TRANSFER-001); no FAB.

Golden: light, dark

### `deck_max_depth` · Open deck at level 10

No FAB; the header says "· level 10".

Golden: none — no golden in V8 (record 01)

### `deck_loading` · Open deck loading

Skeletons under the summary card.

Golden: none — no golden in V8 (record 01)

### `deck_error` · Open deck error

Error state with Retry.

Golden: none — no golden in V8 (record 01)

### `deck_not_found` · Deck no longer here

"This deck is no longer here", with Back to Library and Open Trash.

Golden: none — no golden in V8 (record 01)

### `deck_overflow` · Sub-deck action sheet

The sub-deck action sheet.

Golden: none — no golden in V8 (record 01)

### `deck_move` · Move picker

The deck picker; only decks with the same review algorithm receive the deck.

Golden: none — no golden in V8 (record 01)

### `deck_delete` · Move sub-deck to Trash dialog

As `root_delete`.

Golden: none — no golden in V8 (record 01)

### `deck_trashed` · Sub-deck moved to Trash

As `root_trashed`. Moving the open deck to the Trash steps back to its parent first; the toast
survives the step back.

Golden: none — no golden in V8 (record 01)

## Controls

### Level list

- Type: list, data source
- Purpose: shows the decks of the level with their counts and mastery.
- Invokes: FN-DECK-007

#### On success

- The rows, the due strip and (open deck) the summary card; the list updates in place on every
  emission.

#### On failure

- A read failure → `root_error` / `deck_error`.

### Open deck content

- Type: data source of the open deck
- Purpose: the deck's content, create options, scheduler lock and breadcrumb.
- Invokes: FN-DECK-008

#### On success

- `deck_loaded`, `deck_empty` or `deck_max_depth`.
- A deck holding cards shows the card list — Navigate to: SCR-CARD-001

#### On failure

- `notFound` → `deck_not_found`.
- A read failure → `deck_error`.

### Deck row

- Type: list row
- Purpose: opens the deck.

#### On success

- Navigate to: SCR-DECK-001 (the open deck).

### Row `⋮` and app-bar `⋮`

- Type: icon button
- Purpose: opens the deck's action sheet (`root_overflow` or `deck_overflow`).

### Breadcrumb segment

- Type: link
- Purpose: goes to that level.

#### On success

- Navigate to: SCR-DECK-001

### Search field

- Type: search trigger
- Purpose: opens library search.

#### On success

- Navigate to: SCR-SEARCH-001

### Due strip

- Type: tappable hero card
- Enabled when: the library holds at least one card.

#### On success

- Navigate to: SCR-STUDY-001

### Sort pill

- Type: chip trigger
- Purpose: opens the sort & filter sheet; the chosen sort and filter are inputs of FN-DECK-007.

### Sort option rows, due-only toggle, Done

- Type: option rows, toggle, sheet action
- Invokes: FN-DECK-007

#### On success

- The list re-orders or filters in place; with the filter on and nothing due, `root_due_empty`.

### Show all decks

- Type: text button in `root_due_empty`
- Purpose: turns the due filter off.
- Invokes: FN-DECK-007

### Retry

- Type: button in `root_error` / `deck_error`
- Purpose: reads the level again.
- Invokes: FN-DECK-007

### New deck (root FAB, empty-state "Create deck")

- Type: floating action button / block button
- Purpose: opens the create dialog (`root_create`).

### Create deck (in the create dialog)

- Type: primary dialog action
- Enabled when: always; validation runs on press.
- Invokes: FN-DECK-001

#### On success

- The dialog closes; the new deck appears in the list, empty.

#### On failure

- No algorithm chosen → inline error "Choose how the cards are reviewed." under the algorithm
  choice (UC-DECK-001 E3).
- `blankName`, `nameTooLong` → the field's error under Name.
- Any other failure → a snackbar with the failure's message; the dialog keeps what was typed.

### Cancel, Back or tap outside (create dialog)

- Type: dismiss
- Purpose: leaves the dialog.

#### On success

- With a name or an algorithm entered: asks "Discard this deck?" (Keep editing / Discard);
  empty: closes at once (UC-DECK-001 A1).

### New sub-deck (open-deck FAB, `unset` empty state)

- Type: floating action button / text block action
- Enabled when: the deck holds decks or nothing, and is above level 10.
- Invokes: FN-DECK-009

#### On success

- The new sub-deck appears at the end of the list; an `unset` deck becomes a deck of decks.

#### On failure

- `blankName`, `nameTooLong` → the field's error.
- `depthExceeded`, `notADeckContainer`, `notFound` → a snackbar with the rejection's message.
- Any other failure → a snackbar with the failure's message.

### New card (`unset` empty state)

- Type: text block action
- Purpose: creates the deck's first card.

#### On success

- Navigate to: SCR-CARD-002

### Import cards from a file (`unset` empty state)

- Type: outline block action

#### On success

- Navigate to: SCR-TRANSFER-001

### Browse starter decks (`root_empty`)

- Type: block button

#### On success

- Navigate to: SCR-STARTER-001

### App-bar actions: Starter decks, Tags, Trash

- Type: icon buttons

#### On success

- Starter decks — Navigate to: SCR-STARTER-001
- Tags — Navigate to: SCR-TAG-001
- Trash — Navigate to: SCR-TRASH-001

### Action sheet: Open deck

- Type: command row

#### On success

- Navigate to: SCR-DECK-001

### Action sheet: Study this deck (and the summary card's "Study this deck")

- Type: command row / primary block button
- Enabled when: the subtree holds a card to study (summary card only).

#### On success

- Navigate to: SCR-STUDY-002

### Action sheet: Study options

- Type: command row

#### On success

- Navigate to: SCR-SETTINGS-001 (a sub-deck opens its root's options)

### Action sheet: Review algorithm (root only)

- Type: command row; its subtitle says when the algorithm is locked.

#### On success

- Navigate to: SCR-SRS-001

### Action sheet: Rename

- Type: command row → rename dialog (`root_rename`)
- Invokes: FN-DECK-002

#### On success

- The dialog closes; the row shows the new name.

#### On failure

- `blankName`, `nameTooLong` → the field's error.
- `notFound` → a snackbar "This deck no longer exists."
- Any other failure → a snackbar with the failure's message.

### Action sheet: Reorder

- Type: command row
- Enabled when: Manual order is on and the level holds at least two decks; hidden under any
  other sort.
- Purpose: enters `root_reorder`.

### Reorder drag, TalkBack Move up / Move down, Done

- Type: drag handle, accessibility actions, toolbar action
- Enabled when: Move up on all but the first deck, Move down on all but the last.
- Invokes: FN-DECK-012

#### On success

- The deck swaps place with that neighbour; no other deck changes order. Done leaves reorder
  mode.

#### On failure

- `notSiblings`, `notFound` → a snackbar with the rejection's message; the list keeps its order.

### Action sheet: Move to another deck (sub-deck only)

- Type: command row → move picker (`deck_move`)
- Invokes: FN-DECK-010

### Move here (in the move picker)

- Type: primary sheet action
- Invokes: FN-DECK-011

#### On success

- The deck moves; the sheet closes and the list updates.

#### On failure

- Any `DeckRejection` → a snackbar with the rejection's message.
- Any other failure → a snackbar with the failure's message.

### Action sheet: Move to Trash

- Type: destructive command row → confirmation dialog (`root_delete` / `deck_delete`)
- Invokes: FN-DECK-004

#### On success

- The dialog states the sub-decks and cards that go with the deck before anything is written.

#### On failure

- `notFound` → the dialog body says the deck no longer exists.

### Move to Trash (dialog confirm)

- Type: destructive dialog action; spins while the deck moves.
- Invokes: FN-DECK-005

#### On success

- The dialog closes and the toast of `root_trashed` / `deck_trashed` shows. An open deck steps
  back to its parent first.

#### On failure

- `notFound` → a snackbar "This deck no longer exists."
- Any other failure → a snackbar with the failure's message; nothing moved.

### Undo (toast)

- Type: toast action
- Invokes: FN-DECK-006

#### On success

- The deck and its batch come back where they were.

#### On failure

- Any `DeckRejection` → a toast "Can't undo. {reason} Restore it from Trash and choose a deck.",
  with no deck name.

### Back to Library, Open Trash (`deck_not_found`)

- Type: block buttons

#### On success

- Back to Library — Navigate to: SCR-DECK-001
- Open Trash — Navigate to: SCR-TRASH-001

## Responsive Behavior

A row's meta and the due strip's breakdown wrap at large text, between whole terms; only the
deck name keeps one line. The open deck's breakdown line wraps between whole terms, never "…".
Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

- The mastery bar has no text, so each row reads "{n}% mastered" to TalkBack; a deck with no
  card reads no percentage.
- Reorder mode offers Move up / Move down actions to TalkBack.
- The Undo toast stays until acted on under TalkBack (INV-UI-003).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| An `unset` deck has no FAB; its empty state offers both create choices. | — |
| A deck at level 10 has no "New sub-deck" anywhere. | — |
| Reorder is offered only under Manual order with at least two decks. | — |
| A refused Undo names the reason, never the deck. | — |
| A name error shows under the Name field, never as a snackbar. | — |
| A deck with due cards is marked by text ("{n} due"), not by colour alone. | — |
| An Undo happens where the item was deleted. | — |

## Copy

- Root: "Library" · "Search decks" · "{n} cards due" · "{n} decks" · "Manual" · "Manual · Due
  only" · "New deck".
- Row: "{n} due" · "{n} sub-deck(s)" · "{n} cards" · "Empty · add cards or a sub-deck" · "More
  actions for {name}" · "{n}% mastered" (TalkBack only).
- Summary: "Mastered · {algorithm}".
- Sort: "Progress" · "Least mastered first".
- First launch: "Start your library" · "A deck groups the sub-decks that hold your cards. Create
  one, or copy a starter deck to begin with content." · "Create deck" · "Browse starter decks" ·
  "Everything stays on this device. Nothing is added until you choose."
- Error: "Couldn't load your library" · "Your data is safe on this device. Try again in a
  moment."
- Due filter, none: "Nothing due right now" · "No deck has cards waiting. The next card becomes
  due tomorrow at 00:00." · "Show all decks".
- Create: "New deck" · "Holds sub-decks; sub-decks hold cards." · "Name" · "Review algorithm ·
  required" · "Eight boxes" / "Cards move up a box each time you remember them, back to box 1
  when you forget. Forgiving of long breaks." · "SM-2" / "Intervals adapt to how well you recall
  each card. You grade yourself: again · hard · good · easy." · "Locks once the first card
  finishes learning. After that, only “Reset learning progress” starts a new cycle." · "Cancel" ·
  "Create deck". No algorithm is chosen up front; Create without one says "Choose how the cards
  are reviewed." Cancel, Back or a tap outside after typing asks "Discard this deck?" · "What
  you typed is not saved." · "Keep editing" · "Discard".
- Rename: "Rename deck" · "Only the name changes — sub-decks, cards and schedules stay as they
  are." · "Rename".
- Not found: "This deck is no longer here" · "It was moved to Trash or deleted while you were
  away. Anything in Trash can still be restored." · "Back to Library" · "Open Trash".
- Move to Trash: "Move to Trash" · "Recoverable for 30 days" · "Move this deck to Trash?" ·
  "“{name}” goes to Trash with its {n} sub-decks and {n} cards." · "Recoverable from Trash for
  30 days. Any open study session on these cards ends." · "Cancel" · "Move to Trash" · "“{name}”
  moved to Trash · {n} sub-decks, {n} cards" · "Undo".
- Move: "Move “{name}” to…" · "Its {n} sub-decks and {n} cards come along, schedules included.
  Only decks in the same review algorithm can receive it." · "Move here".
- Sort & filter: as in "Sort & filter sheet".
- Rejections (snackbar or field error, by failure type): `blankName` "Enter a name." ·
  `nameTooLong` "Keep the name to 200 characters." · `depthExceeded` "Decks nest 10 levels deep
  at most." · `notADeckContainer` "This deck holds cards, so it can't hold decks." ·
  `notACardContainer` "This deck holds decks, so it can't hold cards." ·
  `subtreeSchedulerMismatch` "That deck uses a different scheduler." · `movingIntoOwnSubtree` "A
  deck can't move inside itself." · `rootCannotMove` "A top-level deck can't be moved." ·
  `notFound` "This deck no longer exists." · `notSiblings` "The order changed. Try again." ·
  `sameParent` "The deck is already there." · `targetNotFound` "That deck no longer exists." ·
  `targetInTrash` "That deck is in the Trash too."

## Rulings

- **Critique 2026-09-30 part 1, R9 (amends P4a-L9):** an `unset` deck has no FAB; its empty
  state already offers New card and New sub-deck. The FAB returns once the deck holds sub-decks.
- **FE-B1 D7:** an Undo happens where the item was deleted. A refused Undo says "Can't undo.
  {reason} Restore it from Trash and choose a deck."; it carries no deck name.
- **Owner ruling R4** (deck mastery spec, §9 row 141): the < 34% mastery band uses
  `statusLearningInk` in light (4.94:1 on the track) and the amber in dark.
- **§9 rows 142, 145 (FE-C1):** the mastery bar's track is `surfaceContainerLow`, so the fill
  keeps 3:1 against it in dark too.
- **Library spec D7:** Reorder is in the root deck's action sheet too.
- **C-L6:** the action sheet reads only the open deck's view, which carries no counts, so its
  header is the name alone.
- **M3 review 2026-09-28 D2:** reorder mode keeps one card per deck, 8 apart, as in browse mode.
- **Critique 2026-09-30:** a row's meta and the due strip's breakdown wrap at large text, between
  whole terms; only the deck name keeps one line.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):**
  the deck summary's progress line is an eyebrow (12/600 muted); the list headers stay section
  labels.
- **Critique 2026-09-30 part 3a:** the due strip shows a trailing chevron because a tap opens
  Study home.
- **Critique 2026-09-30 part 3b:** the open deck's list header is "Sub-decks" with the sort pill;
  the summary card states the count.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the
  recent sort is labelled "Date added" (vi "Ngày tạo") with the hint "Newest first"; the search
  field is hidden while decks are reordered, as the summary, the due strip and the sort pill
  are, and returns with Done.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the due strip's
  breakdown is overdue · today, the two halves of its total; New stays on each deck row.
- **FE-B1 D11:** `deck_not_found` replaces ruling P2-L7.
- **FE-B1 D15:** the delete confirm spins while the deck moves.
- **C-L5:** moving the open deck to the Trash steps back to its parent first.
- **From UC-DECK-001 (moved here 2026-10-04, spec R20):** a name error is inline under the field,
  not a snackbar; a missing algorithm is inline under the algorithm choice; a failed save keeps
  the dialog and what was typed.
- **From UC-DECK-003 (moved here 2026-10-04, spec R20):** a deck with due cards is marked by an
  icon and text, never colour alone; the mastery bar has no text, so the row reads
  "{n}% mastered" to TalkBack; an open deck holding sub-decks shows the level's mastery donut
  beside "Mastered · {algorithm}".
- **From UC-DECK-006 (moved here 2026-10-04, spec R20):** Reorder is a command of the action
  sheet under Manual order; reorder mode allows drag and, under TalkBack, Move up / Move down
  (no Move up on the first deck, no Move down on the last); a level with one deck offers no
  Reorder; any view-only sort hides it; an error keeps the list as it was.

> ⚠️ OPEN QUESTION: UC-DECK-001 E2 asked the Name field to stop input at 200 characters instead of truncating silently; the V8 app accepts the input and shows "Keep the name to 200 characters." when Create is pressed. Which does the rebuild do?

> ⚠️ OPEN QUESTION: UC-DECK-003 step 3 described a deck tile showing total Due + New, a large icon in three schedule states (not due: outlined, neutral; due today: filled, the time-pressure amber; overdue: missed with a days badge on the error container) and a hero summary as a 2×2 grid of Overdue / Due today / New / Scheduled on one baseline. The V8 app shows a "{n} due" badge per row, a due strip "overdue · today", and the open deck's breakdown as one wrapping line; the schedule status exists in the domain (`DeckScheduleStatus`) but no screen draws it. Which does the rebuild follow?

- Pending — a level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks at
  level 10; absent today, the header says "· level 10"; waits for a later phase (owner decision
  C-O6).
