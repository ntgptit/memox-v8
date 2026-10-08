<!-- Hand-written screen record. -->

# 11 · Card import

A full-screen task above the shell that adds many cards to one deck from a CSV, TSV or
XLSX file or from pasted text (IT-NAV-012). UC-TRANSFER-001; spec
[2026-09-26-card-transfer-design.md](../../../superpowers/specs/2026-09-26-card-transfer-design.md)
§8.

## Entry points

- The open deck's `⋮` sheet, "Import cards": every deck. A deck of cards or an unset
  deck takes cards; a root or a deck of decks takes a file split by `*` rows, or a flat
  file into one default deck (spec 2026-10-08 U1, BR-TRANSFER-001).
- The unset deck's third action, "Import cards from a file".

Route: `/decks/deck/<id>/cards/import`, on the root navigator, so the bottom navigation
bar is gone while it is open.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Close; "Import cards", then "Import results" on the result. |
| Deck context | `DeckContextHeaderWidget`, injected by `app/` | Library › ancestors › deck › "Import", and the deck's name. It stays above the scroll with the tracker, as on the card editor. |
| Step tracker | `ImportStepTrackerWidget` | Source · Columns · Preview · Import (spec §8.1 ruling 4). Done steps check in the mastery colour, the current one is primary, later ones are muted. It stays on one row with stretching connectors and wraps at a large text scale. One semantic label: "Step {n} of 4: {name}". |
| 1 · Choose a source | `MxCard` options (`isSelected`) | Choose a file · Paste text, shown only before a source is read (K1). The file option picks through `file_picker`; the paste option opens an `MxTextField`. The "Pick a spreadsheet or text file" empty state beneath is not wrapped in a card (`MxEmptyState` draws its own surface). |
| Source chip | `MxCard` + `MxIconTile` | File name, then "{format} · UTF-8 · ready to read" or "{format} · {rows} · {columns}" once read, counting data rows (a header row is not one, as the preview skips it; critique 2026-09-30 part 3b); remove action. A workbook with several sheets adds a "Sheet: {name} ({i} of {n})" `MxChipTrigger` (ruling 2). |
| 2 · Map columns | `MxSection` of `ImportMappingRowWidget` | "First row is a header" `MxSettingsRow` with an `MxToggle` and the header sample; one row per column: "Column {A}", its header cell, its first value (the first data row's cell, one line; none when empty; critique 2026-09-30 part 1), and an `MxChipTrigger` for the field, the chips ending on one edge with no arrow between (critique 2026-09-30) (six fields or "Not imported") in a bottom sheet. |
| Mapping error | `MxInlineBanner` (warning) | Its own row when Term or Meaning is unmapped (K3). Preview is locked. |
| Decks (sectioned) | `MxSection` of `ImportDeckRowWidget` | A file split by `*` rows (BR-TRANSFER-015): one row per destination deck with its name (the default deck's is an `MxTextField`), a New / Existing `MxBadge` and its cards; a taken name adds a note and an `MxSegmentedTray` "Add to existing" · "Create new" with nothing chosen; a deck of decks of that name shows only a note (spec 2026-10-08 U2–U4). It sits after "Include duplicates", before the rows. |
| 3 · Preview | `MxListSectionHeader` + `MxBadge` + `MxSection` | The title alone (the badges carry the counts; critique 2026-09-30 part 3b); Ready, Invalid, Duplicate and Blank badges, only for counts above 0; the "Include duplicates" toggle when there is one (after the badges, before the rows); one row per source row with its number, front and back (two lines each), its reason, and a status icon with a semantic label (K3); the first 50 rows and "Showing the first {n} of {m} rows" (K2), counted across the whole import; a sectioned file groups its rows under one `MxSection` per deck (U5). |
| Importing | `MxCard` + `MxSpinner` | "Adding {n} cards…". Close and Back do nothing until the write ends. |
| Footer | `MxFooterBar`, `MxActionPair` 1 : 1 | Cancel + the step action (Map columns · Preview rows · Import {n}), side by side at every step in English and Vietnamese (The Short Label Rule, DEV-169), and a caption; at Preview the caption shows only when nothing can be imported, since the button states the count (critique 2026-09-30 part 3b). |
| Result | `MxEmptyState` in the outcome's tone + `MxSection` counts + `MxNote` | By outcome (K4); see States. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| empty (Source) | `import_source_light.png` | `import_source_dark.png` | Deck chip replaced by the deck context header. |
| pasted | no golden | no golden | The paste field uses the body font, not monospace. |
| fileSelected | no golden | no golden | The source options give way to the chip (K1). |
| badEncoding | no golden | no golden | Read is locked (E1) and the caption says to choose another file; pasted text says to edit it. |
| emptySheet | no golden | no golden | One copy for a file, a sheet or text with no row (E2); another sheet can still be chosen (A2). |
| parsing | no golden | no golden | "Reading your file…" in the source area. |
| mapping | `import_mapping_light.png` | `import_mapping_dark.png` | Only canonical header names map by themselves (D2); headers such as `term`/`meaning` stay unmapped. |
| mappingNoHeader | `import_mapping_no_header_light.png` | `import_mapping_no_header_dark.png` | "First row is a header" off: each column shows its first value under "Column {A}" (critique 2026-09-30 part 1). |
| mappingIncomplete | no golden | no golden | The error is a banner of its own, not a red border (K3). The "mapped for you" note shows only once the mapping is complete. |
| previewAll | no golden | no golden | Rows stack front over back instead of three columns. |
| previewMix | `import_preview_light.png` | `import_preview_dark.png` | As previewAll; the invalid row is not tinted, its reason and icon say it. |
| importing | no golden | no golden | Navigation is inert (IT-NAV-012 step 5). |
| success | no golden | no golden | `MxEmptyState`, success tone; no deck name in the body. Import another file · View the cards (UC step 8). |
| partial | `import_partial_light.png` | `import_partial_dark.png` | As success, with the skipped counts and the skip note. |
| sectionsUndecided | `import_sections_undecided_light.png` | `import_sections_undecided_dark.png` | The Decks block with a taken name undecided; Import is locked and the caption says how many decks to choose for (U6). |
| sectionsDecided | `import_sections_decided_light.png` | `import_sections_decided_dark.png` | "Add to existing" chosen; rows grouped by deck. |
| sectionsResult | `import_sections_result_light.png` | `import_sections_result_dark.png` | The counts, then a Decks section (New / Existing, cards); the primary action is Back to deck (U8). |
| sectionsRefused | no golden | no golden | A file split by `*` rows into a deck of cards (E7) or at level 10 (E8): a warning banner at Columns, Preview locked (U7). |
| sectionTargetChanged | no golden | no golden | A deck chosen for "Add to existing" changed before Import (E9): a warning banner with "Preview again" on the preview. |
| none | no golden | no golden | Neutral tone; Import another file · Back to deck (ruling 1). |
| failed | no golden | no golden | `MxEmptyState`, danger tone; Close · Try again, which returns to the preview. |
| rejects | no golden | no golden | `MxEmptyState`, warning tone; Close only. |

Goldens: `test/features/transfer/presentation/goldens/import_{source,mapping,preview,partial}_{light,dark}.png` and `import_sections_{undecided,decided,result}_{light,dark}.png`.

## Back

Android Back steps back one step and keeps the draft: Preview → Columns → Source. At
Source it closes; while importing it does nothing (IT-NAV-012 step 4–5).

## Rulings

- **Critique 2026-09-30 part 1:** each mapping row shows its column's first value, so a headerless file or pasted text is not mapped blind.
- **Spec §8.2 K1:** once read, the source step collapses to the source chip.
- **Spec §8.2 K2, UC-TRANSFER-001 step 5:** the preview shows the first 50 rows and "Showing the first {n} of {m} rows".
- **Spec §8.2 K3:** each status icon has a semantic label, a mapping error sits on its own row, and cells wrap to two lines; the preview is front over back in one column, since two-line cells do not fit three columns at 360 dp.
- **Spec §8.2 K4:** results use `MxEmptyState` in its success, neutral, warning and danger tones.
- The deck is shown by the deck context header shared with the card editor and detail, with no card count.
- **UC-TRANSFER-001 step 8, ruling 1:** success offers Import another file · View the cards; `none` offers Import another file · Back to deck.
- **UC-TRANSFER-001:** there is no deck picker, so rejects offer Close only.
- **Spec D2:** only the six canonical header names map by themselves.
- Paste field and header cells use the body font; the theme has no monospace role.
- **Amends spec §5.1:** the file name shows in the chip while the wizard is open; it is never logged or stored.
- **FE-B3 plan 1:** Import is live from the deck actions.
- **Critique 2026-09-30:** the file helper ("importHelperBody") has a close button and stays hidden once dismissed on this device; the "mapped for you" note is an `MxNote.hint`.
- **Critique 2026-09-30 tone pass, T6:** Ready (chip and row mark) is success; the step tracker's finished steps stay mastery (progress through the flow).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** in the preview "Include duplicates" sits after the badges and before the preview rows; the source step's "Pick a spreadsheet or text file" empty state has no wrapping card, its body reads "Nothing is added until you confirm.", and the formats are stated only by the "Choose a file" option's hint.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the result lists each skipped row (its number, term, meaning, why and mark, drawn as in the preview) under "Skipped rows", five first and then "Show all {n}"; rows the commit's re-check dropped read "Already in this deck"; the skip note keeps only the duplicate rule (F4). Tapping the "Choose a file" card opens the picker, selected or not; the empty state below has no button (F9).
- **Spec 2026-10-08 (DEV-289), deck sections:** a row whose Term cell starts with `*` names a sub-deck (BR-TRANSFER-015). U1 Import on every deck · U2 the Decks block is the confirmation, no extra step · U3 a taken name needs a choice, none pre-selected; a deck of decks of that name means a new deck · U4 the default deck's name is editable · U5 rows grouped by deck, 50 across the import · U6 Import locked with a caption until every choice is made · U7 E7/E8 as a banner at Columns · U8 the result lists the decks and leads Back to deck · U9 a flat file looks as before.
- **Critique 2026-10-08 (DEV-289, after the build):** F1 an undecided deck shows no New or Existing badge until its choice is made; F2 the default deck's name field has a visible "Deck name" label above it (the field's own label is for TalkBack). One audit confirmed both.
- **Spec 2026-10-08 S6:** a workbook opens on its first sheet, even an empty one, which then says there are no rows; the sheet chip still offers the others.

## Copy

- Steps: "Source" · "Columns" · "Preview" · "Import" · "Step {n} of 4: {name}".
- Source: "1 · Choose a source" · "Choose a file" · "CSV, TSV or XLSX · UTF-8" · "Paste text" · "Tab- or comma-separated rows" · "Pick a spreadsheet or text file" · "Nothing is added until you confirm." · "Each row makes one card".
- Problems: "This file is not UTF-8" · "This file can’t be read" · "There are no rows to import".
- Mapping: "2 · Map columns" · "First row is a header" · "Column {letter}" · "Term (front)" · "Meaning (back)" · "Example" · "Hint" · "Pronunciation" · "Tags" · "Not imported" · "Map one column to Term and one to Meaning. Both are required."
- Preview: "3 · Preview" · "Ready · {n}" · "Invalid · {n}" · "Duplicate · {n}" · "Blank · {n}" · "Already in this deck" · "Repeated in the file (row {row})" · "Showing the first {shown} of {total} rows" · "Include duplicates".
- Footer: "Map columns" · "Preview rows" · "Import {n}" · "Importing…" (Vietnamese "Ghép cột" · "Xem trước" · "Nhập {n}" · "Đang nhập…"); each fits half the 360 dp footer row (The Short Label Rule).
- Result: "Imported" · "Imported with skips" · "Nothing added" · "Import didn’t finish" · "This deck no longer accepts cards" · "Added as new cards" · "Skipped — duplicates" · "Skipped — invalid rows" · "View the cards" · "Import another file" · "Back to deck" · "Try again".
- Decks (spec 2026-10-08): "Decks" · "New" · "Existing" · "{n} cards" · "No cards to add · no deck made" · "A deck with this name is already here." · "Add to existing" · "Create new" · "The deck with this name holds decks, so a new one is made." · "Uncategorized" · "Another deck in this file has this name." · "Deck name after * is empty" · "Deck name over 200 characters" · "Choose how to import {n} decks with taken names." · "Fix the deck name to continue." · "This file is split into decks" · "No room for another level" · "A deck changed meanwhile" · "Preview again".
