---
id: SCR-SETTINGS-001
name: Study options
domain: settings
status: ready
route: [/decks/deck/:deckId/options]
---

# Study options

## Purpose

A root deck's study options, opened from any deck in its tree: its own cards per session and
new-card order, or the app defaults from Settings. Save writes them for sessions started afterwards.
On the root navigator, with no bottom bar. Opened from the deck action sheet — "Study options" /
"Cards per session · new-card order", below Rename (SCR-DECK-001, SCR-CARD-001) — and from the
sliders icon on the Study Entry's app bar (SCR-STUDY-002). On a sub-deck the screen shows its root's
options.

## Related Use Cases

- UC-SETTINGS-001

## Layout

- **App bar** — back and "Study options" (content density).
- **Breadcrumb** — Library › the deck's path › the deck › "Study options".
- **Not-saved banner** — after a failed save, a danger banner "Not saved" at the top of the page:
  "Couldn't save. The deck still uses {n} cards, {order}." It stays through edits until a save
  succeeds.
- **Note** — the screen's one note, with a layers icon: "These options belong to {root} and every
  sub-deck in it. Changes apply to sessions started from now on; a session already open keeps its
  options." One plain string, so the root's name is not bold.
- **Unreadable override** — a warning banner "This deck's options could not be read. Saving replaces
  them."
- **Toggle** — a settings row with a toggle, "Use app defaults"; on: "Following Settings · {n} cards,
  {order}"; off: "Off · this deck has its own options".
- **Options** — a section "App defaults (read-only here)" or "This deck": "Cards per session" / "1 to
  200" with a stepper (−/+, a hold that repeats, a typed entry); "New-card order" as a settings row
  with a segmented tray ("In order" · "Random"), each row with its icon. While the toggle is on, the
  two rows show their values as plain text at full contrast, with no stepper or tray; turning it off
  brings the controls back with the same values.
- **Card limit message** — "Enter a number from 1 to 200" under the stepper; the sub-line stays.
- **Footer** — "Save", enabled only for a valid change, spinning while it runs with no "Saving…"
  text; "Retry save" after a failure. The caption: "Saved to this device only." or "Fix the limit to
  enable save."
- **Toast** — "Saved · applies to the next session".

## States

### `override` · Own options

Save is disabled until something changes.

Golden: light, dark

### `defaults` · Following the app defaults

Save disabled.

Golden: light, dark

### `invalid` · Limit out of range

The message under the stepper; the sub-line stays.

Golden: light, dark

### `saving` · Saving

The stepper and the button spin; the button has no "Saving…" text.

Golden: light, dark

### `saved` · Saved

Golden: light, dark

### `save_failed` · Save failed

The "Not saved" banner and "Retry save"; both stay through edits until a save succeeds; the stored
override is kept.

Golden: light, dark

### `loading` · Loading

Skeleton rows, no footer.

Golden: light, dark

### `gone` · Deck gone

A deck gone to the Trash shows "This deck is no longer here" with Back.

Golden: none — no golden in V8 (record 15)

### `read_error` · Read error

The error state with Retry and no invented value.

Golden: none — no golden in V8 (record 15)

## Controls

### Options in force

- Type: read
- Invokes: FN-SETTINGS-006

#### On failure

- `deckNotFound` → `gone`; a database failure → `read_error`.

### Use app defaults (toggle)

- Type: toggle
- Purpose: switches the draft between the app defaults and the root's own options; nothing is
  written until Save.

### Cards per session stepper, New-card order tray

- Type: stepper / segmented tray
- Enabled when: the toggle is off.

### Save, Retry save

- Type: primary button
- Enabled when: the draft differs and is valid; a second Save while one runs is ignored.
- Invokes: FN-SETTINGS-007, FN-SETTINGS-008
- Purpose: with the toggle on and the root holding its own options, removes them (Use app defaults);
  otherwise saves the root's options.

#### On success

- `saved`; the toast.

#### On failure

- `cardLimitOutOfRange` → `invalid`; `deckNotFound`, `notARootDeck` → the reason; a database failure
  → `save_failed`, the root's options kept.

### Back (`gone`)

- Type: button

#### On success

- Navigate to: SCR-DECK-001

### Retry (`read_error`)

- Type: button
- Invokes: FN-SETTINGS-006

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Save is enabled only for a valid change. | — |
| The options belong to the root; a sub-deck shows its root's. | — |
| An invalid limit says why under the stepper and saves nothing. | — |
| A failed save keeps its banner and Retry through edits until a save succeeds. | — |
| No value is invented when the options cannot be read. | — |

## Copy

"Study options" · "These options belong to {root} and every sub-deck in it. Changes apply to sessions
started from now on; a session already open keeps its options." · "This deck's options could not be
read. Saving replaces them." · "Use app defaults" · "Following Settings · {n} cards, {order}" · "in
creation order" · "random order" · "Off · this deck has its own options" · "App defaults (read-only
here)" · "This deck" · "Cards per session" · "1 to {max}" · "Enter a number from {min} to {max}" ·
"New-card order" · "In order" · "Oldest cards first — the order you added or imported them" ·
"Random" · "Shuffled each learning session" · "Changes apply to sessions started from now on. A
session already open keeps the options it started with." · "Save" · "Retry save" · "Saved to this
device only." · "Fix the limit to enable save." · "Couldn't save. The deck still uses {n} cards,
{order}." · "Saved · applies to the next session" · "Cards per session · new-card order" · "Not
saved" · "This deck is no longer here" · "Back".

## Rulings

- The note carries one plain string, so the root's name is not bold.
- **UC-SETTINGS-001 E1:** "Enter a number from 1 to 200" sits under the stepper and the sub-line
  stays.
- **D9:** Save is enabled only for a valid change; while saving the button spins.
- **Spec §6, UI-base row 129:** a gone root shows the Library's gone state with Back.
- **M3 review 2026-09-28 E1, E2:** new-card order is one settings row and a segmented tray, with
  icons on every row.
- **D3:** "Study options" is in the deck action sheet, below Rename, and on the Study Entry's app bar.
- **Critique 2026-09-30:** while the toggle is on, the values are plain text at full contrast, with no
  stepper or tray.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** a failed
  save shows a danger banner, "Not saved", at the top of the page; the footer keeps Retry save and its
  local-only caption.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** a failed
  save's "Not saved" banner and the footer's "Retry save" stay through edits until a save succeeds
  (the banner's values are the deck's stored ones, so they stay true while the person edits).
