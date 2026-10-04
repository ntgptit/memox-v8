---
id: SCR-TRANSFER-002
name: Card export
domain: transfer
status: ready
route: []
---

# Card export

## Purpose

A bottom sheet that hands a deck's cards, or the selected ones, to the system share sheet as a CSV,
TSV or XLSX file. It has no route of its own: it opens over the card list (SCR-CARD-001), from
"Export cards" in the open deck's ⋮ sheet — a deck of cards only — and from the bulk bar's
"Export" for the selected cards. The deck's cards are counted before the sheet opens, so the sheet
never loads. The scope follows from where it was opened and cannot be changed.

## Related Use Cases

- UC-TRANSFER-002

## Layout

- **Header** — "Export all {n} cards" and "Every card in {deck}, whatever filter or search is
  active."; for a selection, "Export {n} selected cards" and "Only the cards you selected."
- **Problem** — one banner per problem, above the formats: danger for a file that could not be
  prepared, warning otherwise, each with its tone glyph.
- **Formats** — a section header "Format" and three option rows: CSV (default, with a
  "Recommended" badge), TSV, XLSX, each with what it is for. Locked while a file is prepared, and
  locked by every final problem.
- **Content note** — a note with a file icon: the six columns; no schedule, no history.
- **Footer** — the sheet's actions: Cancel · "Export {n} cards" with the share icon; "Preparing…"
  spinning while the file is built and shared; "Try again" after a failure it can fix; a lone
  primary Close when it cannot.
- **Toast** — "Handed {n} cards to the system." once the share sheet took the file; it names no
  file and never says where the file was saved.

The overline, the banner and the note line up with the title (20 dp).

## States

### `whole_deck` · Whole deck

CSV carries "Recommended"; the action reads "Export {n} cards".

Golden: light, dark

### `selection` · Selected cards

As `whole_deck`.

Golden: none — no golden in V8 (record 12)

### `preparing` · Preparing

The formats lock and a second press is ignored; Cancel closes the sheet and nothing is shared.

Golden: none — no golden in V8 (record 12)

### `handed_over` · Handed over

The sheet closes; the toast names no file. A selection stays selected.

Golden: none — no golden in V8 (record 12)

### `share_closed` · Share sheet closed

A cancel, not an error: the export sheet stays open as it was, with its scope and format.

Golden: none — no golden in V8 (record 12)

### `failed` · Couldn't prepare the file

For a read or an encode failure, with Try again. A share failure has its own copy, also with Try
again.

Golden: light, dark

### `no_share_target` · No app can receive a file

The banner shows the warning glyph; Close only; nothing is left behind.

Golden: none — no golden in V8 (record 12)

### `stale_selection` · Selection changed

A selected card was moved to another deck or sent to the Trash since the sheet opened; nothing was
exported; the format rows are locked and the lone Close stays primary.

Golden: light, dark

### `nothing_to_export` · Nothing to export

Reached only by a deck emptied between the count and the export, or by a count of 0.

Golden: none — no golden in V8 (record 12)

## Controls

### Sheet opening

- Type: read
- Invokes: FN-TRANSFER-004
- Purpose: counts the deck's cards before the sheet opens.

### Format rows

- Type: option rows
- Enabled when: no file is being prepared and no final problem shows.

### Export {n} cards, Try again

- Type: primary sheet action
- Enabled when: no export is running.
- Invokes: FN-TRANSFER-005, FN-TRANSFER-006

#### On success

- `handed_over`, or `share_closed` when the person leaves the share sheet without a target.

#### On failure

- `encodeFailed` and a database failure → `failed` ("Couldn’t prepare the file").
- `shareFailed` → "Couldn’t hand the file over", with Try again; no path, file name or card content
  in the message.
- `shareUnavailable` → `no_share_target`.
- `staleSelection` → `stale_selection`.
- `emptyScope` → `nothing_to_export`.

### Cancel, Close, tap outside, Android Back

- Type: sheet actions / dismiss
- Purpose: closes the sheet; no file is made and the selection is untouched.

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

Each banner carries its tone glyph, so a problem is not told by colour alone. Otherwise follows the
shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| The scope is fixed by where the sheet was opened. | — |
| A final problem locks the formats and leaves a lone primary Close. | — |
| Closing the share sheet is a cancel, never an error. | — |
| No message names the file, its path or card content. | — |
| One export per press; a second press while preparing is ignored. | — |

## Copy

- Header: "Export all {n} cards" · "Every card in {deck}, whatever filter or search is active." ·
  "Export {n} selected cards" · "Only the cards you selected."
- Formats: "Format" · "CSV" · "Comma-separated · opens anywhere" · "TSV" · "Tab-separated · safest
  for commas in text" · "XLSX" · "Excel workbook" · "Recommended".
- Note: "Six columns: front, back, example, hint, pronunciation, tags. No schedule, no history —
  this is content, not a backup."
- Actions: "Cancel" · "Export {n} cards" · "Preparing…" · "Try again" · "Close".
- Problems: "Couldn’t prepare the file" · "Couldn’t hand the file over" · "No app on this device
  can receive a file" · "A selected card is no longer in this deck" · "It was moved to another deck
  or sent to Trash meanwhile. Nothing was exported. Close this sheet, check your selection and
  export again." · "There is nothing to export".
- Toast: "Handed {n} cards to the system."

## Rulings

- **Critique 2026-09-30 part 1, R8:** a final problem (stale, empty, no share target) locks the
  format rows; its lone Close stays primary (ruling C1 of the M3 review).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the
  stale-selection body (`exportStaleBody`) reads "It was moved to another deck or sent to Trash
  meanwhile. Nothing was exported. Close this sheet, check your selection and export again."; the
  lone Close stays.
- **UC-TRANSFER-002 A3 (E1):** closing the share sheet keeps the export sheet open with its scope
  and format.
- **Spec §7 (E2):** the result reads "Handed {n} cards to the system." without the file name.
- **UC-TRANSFER-002 step 2 (E3):** CSV carries a "Recommended" badge.
- **UC-TRANSFER-002 E2–E4 (E4):** read and encode failures share "Couldn't prepare the file"; a
  share failure has its own copy; both offer Try again.
- **UC-TRANSFER-002 E5 (E5):** "Export cards" appears on a deck of cards only.
- **UC-TRANSFER-002 step 3 (owner 2026-09-26):** the action reads "Export {n} cards".
- **Backend plan C5:** the file name keeps the deck's own letters (`Nhà-hàng-2026-09-26.csv`).
- Banners use their tone glyph; the banner has no glyph slot of its own.
