---
id: SCR-TRANSFER-001
name: Card import
domain: transfer
status: ready
route: [/decks/deck/:deckId/cards/import]
---

# Card import

## Purpose

A full-screen task above the shell that adds many cards to one deck from a CSV, TSV or XLSX file or
from pasted text, in four steps: Source · Columns · Preview · Import. On the root navigator, so the
bottom bar is gone while it is open. Opened from "Import cards" in the open deck's ⋮ sheet — a deck
that holds cards or holds nothing; a root and a deck of decks do not offer it — and from the unset
deck's third action, "Import cards from a file" (SCR-DECK-001, SCR-CARD-001).

## Related Use Cases

- UC-TRANSFER-001

## Layout

- **App bar** — close; "Import cards", then "Import results" on the result (content density).
- **Deck context** — the persistent deck header shared with the card editor: Library ›
  ancestors › deck › "Import", and the deck's name, with no card count. It stays above the scroll
  with the tracker.
- **Step tracker** — Source · Columns · Preview · Import. Done steps check in the mastery colour
  (progress through the flow), the current one is primary, later ones are muted. One row with
  stretching connectors; it wraps at large text. One semantic label: "Step {n} of 4: {name}".
- **1 · Choose a source** — two option cards, shown only before a source is read: "Choose a file"
  (its hint states the formats; tapping it opens the picker, selected or not) and "Paste text"
  (opens a text field in the body font). Beneath, the empty state "Pick a spreadsheet or text
  file" / "Nothing is added until you confirm.", with no wrapping card and no button. A
  dismissible file helper stays hidden once dismissed on this device.
- **Source chip** — once read, the source step collapses to a chip: the file name, then "{format}
  · UTF-8 · ready to read" or "{format} · {rows} · {columns}" once read (data rows: a header row is
  not one); a remove action. A workbook with several sheets adds a "Sheet: {name} ({i} of {n})"
  trigger. The file name is never logged or stored.
- **2 · Map columns** — a section: the "First row is a header" row with a toggle and the header
  sample; one row per column: "Column {A}", its header cell, its first value (the first data row's
  cell, one line; none when empty), and a field trigger (the six fields or "Not imported") opening a
  bottom sheet, the triggers ending on one edge with no arrow between. Only the six canonical header
  names map by themselves; the "mapped for you" note (a hint note) shows only once the mapping is
  complete.
- **Mapping error** — a warning banner on its own row when Term or Meaning is unmapped (not a red
  border); Preview is locked.
- **3 · Preview** — the title alone; Ready, Invalid, Duplicate and Blank badges, only for counts
  above 0 (Ready in the success tone); the "Include duplicates" toggle when there is a duplicate,
  after the badges and before the rows; one row per source row with its number, front over back
  (two lines each), its reason, and a status icon with a semantic label; the first 50 rows and
  "Showing the first {n} of {m} rows". An invalid row is not tinted: its reason and icon say it.
- **Importing** — a card with a spinner, "Adding {n} cards…". Close and Back do nothing until the
  write ends.
- **Footer** — Cancel and the step action (Read and map columns · Preview rows · Import {n} cards),
  with a caption; at Preview the caption shows only when nothing can be imported, since the button
  states the count. "Import {n} cards" is the confirmation: it names the count.
- **Result** — an empty state in the outcome's tone, a section of counts and a note: each skipped
  row (its number, term, meaning, why and mark, drawn as in the preview) under "Skipped rows", five
  first and then "Show all {n}"; rows the write's re-check dropped read "Already in this deck"; the
  skip note keeps only the duplicate rule.

## States

### `empty` · Source

Golden: light, dark

### `pasted` · Text pasted

The paste field uses the body font, not monospace.

Golden: none — no golden in V8 (record 11)

### `file_selected` · File selected

The source options give way to the chip.

Golden: none — no golden in V8 (record 11)

### `bad_encoding` · Not UTF-8

Read is locked and the caption says to choose another file (for a file) or to edit the text (for
pasted text); the source chosen before is kept.

Golden: none — no golden in V8 (record 11)

### `empty_sheet` · No rows

One copy for a file, a sheet or text with no row; another sheet can still be chosen.

Golden: none — no golden in V8 (record 11)

### `parsing` · Reading

"Reading your file…" in the source area.

Golden: none — no golden in V8 (record 11)

### `mapping` · Map columns

Headers such as `term`/`meaning` stay unmapped.

Golden: light, dark

### `mapping_no_header` · No header row

"First row is a header" off: each column shows its first value under "Column {A}".

Golden: light, dark

### `mapping_incomplete` · Mapping incomplete

The error banner; Preview locked.

Golden: none — no golden in V8 (record 11)

### `preview_all` · Preview, all ready

Rows stack front over back instead of three columns.

Golden: none — no golden in V8 (record 11)

### `preview_mix` · Preview, mixed

Golden: light, dark

### `importing` · Importing

Navigation is inert.

Golden: none — no golden in V8 (record 11)

### `success` · Imported

The success tone; no deck name in the body. Import another file · View the cards.

Golden: none — no golden in V8 (record 11)

### `partial` · Imported with skips

As success, with the skipped counts, the skipped rows and the skip note.

Golden: light, dark

### `none` · Nothing added

The neutral tone; the deck is unchanged. Import another file · Back to deck.

Golden: none — no golden in V8 (record 11)

### `failed` · Import didn't finish

The danger tone; Close · Try again, which returns to the preview with the source, mapping and
preview kept.

Golden: none — no golden in V8 (record 11)

### `rejects` · Deck no longer accepts cards

The warning tone; Close only — there is no deck picker.

Golden: none — no golden in V8 (record 11)

## Controls

### Choose a file

- Type: option card
- Invokes: FN-TRANSFER-001
- Purpose: opens the file picker; cancelling the picker is not an error and keeps the choice
  before.

#### On failure

- `badEncoding` → `bad_encoding`; `unreadableFile` → "This file can’t be read"; both keep the
  source chosen before.

### Paste text, Read and map columns

- Type: option card / footer action
- Invokes: FN-TRANSFER-001
- Purpose: the text is read only on Read; it stays as typed when reading fails.

### Remove source, sheet trigger

- Type: chip action / chip trigger
- Invokes: FN-TRANSFER-001
- Purpose: replaces the source, or reads another sheet (mapping and preview run again).

### First row is a header, field triggers

- Type: toggle / chip triggers
- Purpose: the mapping; Term and Meaning are required, and a column maps to one field at most.

### Preview rows

- Type: footer action
- Enabled when: Term and Meaning are mapped.
- Invokes: FN-TRANSFER-002

#### On failure

- `mappingIncomplete` → `mapping_incomplete`; `emptySource` → `empty_sheet`.

### Include duplicates

- Type: toggle
- Purpose: counts both kinds of duplicate as ready.

### Import {n} cards

- Type: footer action
- Enabled when: at least one row would be written.
- Invokes: FN-TRANSFER-003

#### On success

- `success`, `partial`, or `none` when every row turned out to be a duplicate at write time.

#### On failure

- `nothingToImport` → the button stays locked; nothing is written.
- `targetRejected` → `rejects`; the preview and mapping are kept.
- A database failure → `failed`.

### Cancel, Close, Android Back

- Type: footer action / app-bar action / back
- Purpose: Back steps back one step and keeps the draft (Preview → Columns → Source); at Source it
  closes; while importing nothing happens.

### View the cards, Back to deck (result)

- Type: buttons

#### On success

- Navigate to: SCR-CARD-001 (View the cards); Back to deck returns to the deck.

### Import another file, Try again (result)

- Type: buttons
- Purpose: Import another file keeps the deck and starts again at Source; Try again returns to the
  preview.

## Responsive Behavior

The step tracker wraps at large text. Preview rows stack front over back, since two-line cells do
not fit three columns at 360 dp. Otherwise follows the shared floor (DESIGN.md,
SCREEN_CATALOG.md).

## Accessibility

- The step tracker is one semantic label, "Step {n} of 4: {name}".
- Each preview row's status icon has a semantic label; an invalid row is not marked by tint alone.

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Nothing is written before Import {n} cards. | — |
| A mapping error is a banner of its own, not a red border. | — |
| Back steps back and keeps the draft; it does nothing while importing. | — |
| A failed import keeps the source, mapping and preview. | — |
| Only the six canonical header names map by themselves. | — |

## Copy

- Steps: "Source" · "Columns" · "Preview" · "Import" · "Step {n} of 4: {name}".
- Source: "1 · Choose a source" · "Choose a file" · "CSV, TSV or XLSX · UTF-8" · "Paste text" ·
  "Tab- or comma-separated rows" · "Pick a spreadsheet or text file" · "Nothing is added until you
  confirm." · "Each row makes one card".
- Problems: "This file is not UTF-8" · "This file can’t be read" · "There are no rows to import".
- Mapping: "2 · Map columns" · "First row is a header" · "Column {letter}" · "Term (front)" ·
  "Meaning (back)" · "Example" · "Hint" · "Pronunciation" · "Tags" · "Not imported" · "Map one
  column to Term and one to Meaning. Both are required."
- Preview: "3 · Preview" · "Ready · {n}" · "Invalid · {n}" · "Duplicate · {n}" · "Blank · {n}" ·
  "Already in this deck" · "Repeated in the file (row {row})" · "Showing the first {shown} of
  {total} rows" · "Include duplicates".
- Footer: "Read and map columns" · "Preview rows" · "Import {n} cards" · "Importing…".
- Result: "Imported" · "Imported with skips" · "Nothing added" · "Import didn’t finish" · "This
  deck no longer accepts cards" · "Added as new cards" · "Skipped — duplicates" · "Skipped —
  invalid rows" · "View the cards" · "Import another file" · "Back to deck" · "Try again".

## Rulings

- **Critique 2026-09-30 part 1:** each mapping row shows its column's first value, so a headerless
  file or pasted text is not mapped blind.
- **Spec §8.2 K1:** once read, the source step collapses to the source chip.
- **Spec §8.2 K2, UC-TRANSFER-001 step 5:** the preview shows the first 50 rows and "Showing the
  first {n} of {m} rows".
- **Spec §8.2 K3:** each status icon has a semantic label, a mapping error sits on its own row, and
  cells wrap to two lines; the preview is front over back in one column, since two-line cells do
  not fit three columns at 360 dp.
- **Spec §8.2 K4:** results use the empty state in its success, neutral, warning and danger tones.
- The deck is shown by the deck context header shared with the card editor and detail, with no
  card count.
- **UC-TRANSFER-001 step 8, ruling 1:** success offers Import another file · View the cards;
  `none` offers Import another file · Back to deck.
- **UC-TRANSFER-001:** there is no deck picker, so rejects offer Close only.
- **Spec D2:** only the six canonical header names map by themselves.
- Paste field and header cells use the body font; the theme has no monospace role.
- **Amends spec §5.1:** the file name shows in the chip while the wizard is open; it is never logged
  or stored.
- **FE-B3 plan 1:** Import is live from the deck actions.
- **Critique 2026-09-30:** the file helper ("importHelperBody") has a close button and stays hidden
  once dismissed on this device; the "mapped for you" note is a hint note.
- **Critique 2026-09-30 tone pass, T6:** Ready (chip and row mark) is success; the step tracker's
  finished steps stay mastery (progress through the flow).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** in the
  preview "Include duplicates" sits after the badges and before the preview rows; the source step's
  "Pick a spreadsheet or text file" empty state has no wrapping card, its body reads "Nothing is
  added until you confirm.", and the formats are stated only by the "Choose a file" option's hint.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the result lists each
  skipped row (its number, term, meaning, why and mark, drawn as in the preview) under "Skipped
  rows", five first and then "Show all {n}"; rows the commit's re-check dropped read "Already in
  this deck"; the skip note keeps only the duplicate rule (F4). Tapping the "Choose a file" card
  opens the picker, selected or not; the empty state below has no button (F9).
- **Migration 2026-10-04:** the legacy UC named a separate confirm step naming the deck and the
  counts; V8 confirms with the Preview step's "Import {n} cards" under the deck header.
