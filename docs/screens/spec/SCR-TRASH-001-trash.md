---
id: SCR-TRASH-001
name: Trash
domain: trash
status: ready
route: [/decks/trash]
---

# Trash

## Purpose

Everything deleted in the last 30 days, newest first. Each entry can be restored to a place the
person picks, or deleted for good. A full-screen task on the root navigator, with no bottom bar.
Opened from the Trash icon on the Library's app bar (SCR-DECK-001); from "Open Trash" on the
toast after several cards move to the Trash and on every refused Undo; and from "Open Trash" in
the "no longer here" states of an open deck, the card editor and the card detail (SCR-DECK-001,
SCR-CARD-003, SCR-CARD-004). Opening it runs the auto-purge, as the app's start and every resume
do.

## Related Use Cases

- UC-TRASH-001

## Layout

- **App bar** — back, "Trash" and "Select" (a compact secondary button; hidden when the Trash is
  empty). While selecting: close, then "Select entries", "{n} cards selected" or "{n} decks
  selected".
- **Retention note** — a note with a history icon and a close button ("Hide this note"): "Kept
  for 30 days from deletion, then removed automatically. Restoring asks where the item should
  go." Hidden while selecting; once hidden it stays hidden on this device.
- **Kind-lock note** — while selecting: "Cards and decks can't be selected together." Not
  dismissible. It and the purge-blocked banners sit above the list, under the retention note.
- **Blocked purge** — a warning banner per batch the last purge skipped: "“X” still contains an
  entry deleted earlier (“Y”)".
- **Filters** — three filter chips: All · Cards · Decks, each with its count. Hidden while
  selecting.
- **Header** — a section header "{n} entries · newest first"; while selecting, the kind's total,
  "{m} cards" or "{m} decks".
- **Rows** — a card per entry: the kind's tile (a checkbox while selecting); the name ("front ·
  back" for a card) and the time left on the right — a warning badge under 3 days, grey text
  otherwise; then "Card · deleted {ago}" or "Deck · {n} sub-decks · {m} cards · deleted {ago}"
  (up to two lines); then "Was in {path}" or "Was in Top level", 8 apart — information only,
  never presented as where it will be restored; then ⋮. While selecting, an entry of the other
  kind is dimmed to 0.38.
- **Selection bar** — a footer bar with "Restore ({n})" (primary) · "Delete ({n})" (a filled
  destructive button), side by side, stacked when a label cannot fit; both disabled until a
  pick.
- **Action sheet** — the name and "{kind} · deleted {ago} · was in {deck}"; "Restore…" /
  "Choose which deck it goes to"; "Delete permanently" / "Cannot be undone · history lost"
  (destructive).
- **Restore picker** — the deck picker sheet: "Restore “{name}” to…" or "Restore {n} cards/decks
  to…", the rule, then the targets as paths with no counts, or the single "Top level" for
  top-level decks. With no target: "Nowhere to restore right now", why, and a filled OK, with the
  neutral folder — as the move sheets draw it; no disabled row that looks selectable.
- **Delete-for-good dialog** — "Delete {n} cards permanently?", "They disappear for good,
  together with their study history. This cannot be undone.", "Keep in Trash" (primary,
  focused) · "Delete {n}" (destructive, spinning while it runs). No glyph, left-aligned.
- **Toasts** — "“{name}” restored to {deck}" / "{n} entries restored to {deck}"; "{n} cards
  deleted permanently".

## States

### `all` · All entries

The tile is tinted, and "Was in" has no glyph.

Golden: light, dark

### `cards` · Cards filter

Golden: none — no golden in V8 (record 06)

### `decks` · Decks filter

Golden: none — no golden in V8 (record 06)

### `actions` · Action sheet

A row tap opens it too.

Golden: light, dark

### `restore_target` · Restore picker

Targets read as paths, without counts or "where it was".

Golden: light, dark

### `no_target` · Nowhere to restore

The neutral folder, and a filled OK.

Golden: light, dark

### `restored` · Restored

The restored toast; the entry leaves the list.

Golden: none — no golden in V8 (record 06)

### `undo_refused` · Undo refused

Shown where the item was deleted (SCR-DECK-001, SCR-CARD-001), with Open Trash.

Golden: none — no golden in V8 (record 06)

### `selection` · Selecting

"Restore ({n})" · "Delete ({n})" as a filled destructive button, the note hidden, the other kind
dimmed.

Golden: light, dark

### `purge_confirm` · Delete-for-good dialog

Golden: light, dark

### `purged` · Purged

The purged toast.

Golden: none — no golden in V8 (record 06)

### `younger_inside` · Purge blocked

"deleted earlier", in a warning banner, one per blocked batch.

Golden: light, dark

### `empty` · Empty

"Trash is empty" with the 30-day line; no Select, no filters.

Golden: light, dark

### `loading` · Loading

Skeleton rows.

Golden: none — no golden in V8 (record 06)

### `error` · Error

"Couldn't open Trash" with the app's local-first body, "Nothing was lost. Try again in a
moment.", and Retry.

Golden: light, dark

## Controls

### Opening the Trash (and every focus regained)

- Type: lifecycle
- Invokes: FN-TRASH-001
- Purpose: purges expired batches before the list is drawn; expired rows then leave in place,
  without a scroll jump.

### Entry list

- Type: read
- Invokes: FN-TRASH-002

#### On failure

- A database failure → `error`.

### Filter chips: All, Cards, Decks

- Type: filter chips

### Hide this note

- Type: icon button
- Purpose: hides the retention note on this device for good.

### Row, row ⋮

- Type: list row / icon button
- Purpose: opens the action sheet (`actions`); while selecting, a tap toggles the entry.

### Select / close selection

- Type: compact secondary button / icon button
- Enabled when: the Trash is not empty.
- Purpose: enters or leaves selection; the first pick locks the kind.

### Restore… (action sheet), Restore ({n}) (selection bar)

- Type: sheet command / primary button
- Invokes: FN-TRASH-003, FN-TRASH-004
- Purpose: opens the restore picker for the deck or card entries.

### Restore target row (restore picker)

- Type: picker row
- Invokes: FN-TRASH-005, FN-TRASH-006

#### On success

- The sheet closes; `restored`.

#### On failure

- A rejection (`notFound`, `targetInTrash`, `targetNotFound`, `targetIsRoot`,
  `targetHoldsDecks`, `crossRootMove`, `rootRestoresToTopLevel`, `subDeckNeedsParent`,
  `notADeckContainer`, `depthExceeded`, `subtreeSchedulerMismatch`) closes the sheet and shows a
  toast with its reason; the list follows the store.
- A database failure → a toast with the failure's message; nothing changed.

### OK (`no_target`)

- Type: filled button
- Purpose: closes the picker.

### Delete permanently (action sheet), Delete ({n}) (selection bar)

- Type: sheet command / destructive button
- Purpose: opens the delete-for-good dialog (`purge_confirm`).

### Delete {n} (delete-for-good dialog)

- Type: dialog confirm (destructive)
- Invokes: FN-TRASH-007

#### On success

- `purged`; batches the purge skipped show as `younger_inside` banners; a batch already gone
  is reported as no longer there, and the list refreshes with no ghost row.

#### On failure

- A database failure → a toast; nothing changed.

### Keep in Trash

- Type: dialog action (primary, focused)
- Purpose: closes the dialog; nothing changes.

### Retry (`error`)

- Type: button
- Invokes: FN-TRASH-002

## Responsive Behavior

The selection bar's two buttons stack when a label cannot fit; a row's meta line wraps to two
lines. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Each row is one TalkBack node carrying every fact: kind, name, when deleted, time left, where it
was. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A restore always asks where the item goes; the old place is never chosen on its own. | — |
| "Was in" is information, never presented as the restore target. | — |
| A selection holds one kind only, and says so. | — |
| The destructive colour is for deleting for good only, never for Restore. | — |
| The delete-for-good dialog focuses the safe action. | — |
| Restore targets read as paths, without counts. | — |

## Copy

- Header: "Trash" · "Select" · "Kept for 30 days from deletion, then removed automatically.
  Restoring asks where the item should go." · "All" · "Cards" · "Decks" · "{n} entries · newest
  first".
- Row: "Card · deleted {ago}" · "Deck · {n} sub-decks · {m} cards · deleted {ago}" · "just now" /
  "{n} minutes ago" / "{n} hours ago" / "yesterday" / "{n} days ago" · "{n} days left" · "{n}h
  left" · "Was in {path}" · "Top level" · "Actions for {name}".
- Actions: "Restore…" · "Choose which deck it goes to" · "Delete permanently" · "Cannot be undone
  · history lost".
- Restore: "Restore “{name}” to…" · "Its schedule, history, flag and tags come back with it. Only
  decks in the same tree that hold cards or are empty are offered." · "Nowhere to restore right
  now" · "No deck in “{root}” can hold cards at the moment. Create an empty sub-deck there, then
  restore." · "“{name}” restored to {deck}".
- Selection: "Select entries" · "{n} cards selected" · "{m} cards" · "{m} decks" · "Cards and
  decks can't be selected together." · "Restore ({n})" · "Delete ({n})" · "Clear selection".
- Delete for good: "Delete {n} cards permanently?" · "They disappear for good, together with their
  study history. This cannot be undone." · "Keep in Trash" · "Delete {n}" · "{n} cards deleted
  permanently".
- Empty and error: "Trash is empty" · "Decks and cards you delete stay here for 30 days before
  they are removed for good." · "Couldn't open Trash".

## Rulings

- **Invariant 36 (spec D6):** a blocked restore says "“X” still contains an entry deleted earlier
  (“Y”)" in a warning banner, one per blocked batch.
- **P3-L8:** a restore target shows its path, as the move sheets do; targets carry no counts.
- A deck has its own restore sheet and rule, with "Top level" for a top-level deck (FN-TRASH-003).
- **E-L3:** "Select" is a compact secondary button.
- **O11:** the no-target state is the deck picker sheet's empty state (the neutral folder, a
  filled OK), shared with the move sheets.
- **Spec §6:** a refused restore closes the sheet and shows a toast; the list follows the store.
- **Owner 2026-09-26 (UI refinements phase 2):** the selection bar reads "Restore ({n})" · "Delete
  ({n})"; "Delete" is a filled destructive button.
- **Owner 2026-09-26:** the time left under 3 days is a warning badge; the meta line wraps to two
  lines, 8 apart.
- **Owner 2026-09-26:** while selecting, the note hides, the other kind dims to 0.38, and "Cards
  and decks can't be selected together." shows.
- **Critique 2026-09-30:** the retention note has a close button ("Hide this note"); once hidden
  it stays hidden on this device (`dismissed_note`). The kind-lock note is not dismissible.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** the
  kind-lock note and the purge-blocked banners sit above the list, under the retention note (D4).
