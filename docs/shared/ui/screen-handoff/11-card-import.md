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
| Choose a source | `MxCard` options (`isSelected`) | The section titles carry no "1 · " step number: the tracker does (audit 2026-10-19, G7). Choose a file · Paste text, shown only before a source is read (K1). The file option picks through `file_picker`; the paste option opens an `MxTextField`. The "Pick a spreadsheet or text file" empty state beneath is not wrapped in a card (`MxEmptyState` draws its own surface). Each option is one TalkBack node (label, button, tap, focus) that says whether it is the selected one, and a keyboard-focused option draws the row focus ring (M3F-10). |
| Source chip | `MxCard` + `MxIconTile` | File name, then "{format} · UTF-8 · ready to read" or "{format} · {rows} · {columns}" once read, counting data rows (a header row is not one, as the preview skips it; critique 2026-09-30 part 3b); remove action. A workbook with several sheets adds a "Sheet: {name} ({i} of {n})" `MxChipTrigger` (ruling 2). |
| Map columns | `MxSection` of `ImportMappingRowWidget` | "First row is a header" `MxSettingsRow` with an `MxToggle` and the header sample; one row per column: "Column {A}", its header cell, its first value (the first data row's cell, one line; none when empty; critique 2026-09-30 part 1), and an `MxChipTrigger` for the field, the chips ending on one edge with no arrow between (critique 2026-09-30) (six fields or "Not imported") in a bottom sheet. TalkBack names the chip with its column: "Column {letter} goes to {field}" (the visible field alone would not say which column it sets). |
| Mapping error | `MxInlineBanner` (warning) | Its own row when Term or Meaning is unmapped (K3). Preview is locked. |
| Decks (sectioned) | `MxSection` of `ImportDeckRowWidget` | A file split by `*` rows (BR-TRANSFER-015): one row per destination deck with its name (the default deck's is an `MxTextField`), a New / Existing `MxBadge` and its cards; a taken name adds a note and an `MxSegmentedTray` "Add to existing" · "Create new" with nothing chosen; a deck of decks of that name shows only a note (spec 2026-10-08 U2–U4). It sits after "Include duplicates", before the rows. |
| Preview | `MxListSectionHeader` + `MxBadge` + `MxSection` | The title alone (the badges carry the counts; critique 2026-09-30 part 3b); Ready, Invalid, Duplicate and Blank badges, only for counts above 0; the "Include duplicates" toggle when there is one (after the badges, before the rows); one row per source row with its number, front and back (two lines each), its reason, and a status icon with a semantic label (K3); the first 50 rows and "Showing the first {n} of {m} rows" (K2), counted across the whole import; a sectioned file groups its rows under one `MxSection` per deck (U5). |
| Importing | `MxCard` + `MxSpinner` | "Adding {n} cards…". Close and Back do nothing until the write ends. |
| Footer | `MxFooterBar`, `MxActionPair` 1 : 1 | Cancel + the step action (Map columns · Preview rows · Import {n}), side by side at every step in English and Vietnamese (The Footer Pair Rule, DEV-169), and a caption; at Preview the caption shows only when nothing can be imported, since the button states the count (critique 2026-09-30 part 3b). |
| Result | `MxEmptyState` in the outcome's tone + `MxSection` counts + `MxNote` | By outcome (K4); see States. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| empty (Source) | `import_source_light.png` | `import_source_dark.png` | Deck chip replaced by the deck context header. |
| pasted | no golden | no golden | The paste field uses the input font (`bodyLarge`), not monospace; it paints its label "Paste text" above the box and the pasted line count as its supporting text under it. |
| fileSelected | no golden | no golden | The source options give way to the chip (K1). |
| badEncoding | no golden | no golden | Read is locked (E1) and the caption says to choose another file; pasted text says to edit it. |
| emptySheet | no golden | no golden | One copy for a file, a sheet or text with no row (E2); another sheet can still be chosen (A2). |
| parsing | no golden | no golden | "Reading your file…" in the source area. The two source options take no tap meanwhile: each is announced as disabled (one node, not dimmed) and the chosen one keeps its selected state (M3F-10). |
| mapping | `import_mapping_light.png` | `import_mapping_dark.png` | Only canonical header names map by themselves (D2); headers such as `term`/`meaning` stay unmapped. |
| mappingNoHeader | `import_mapping_no_header_light.png` | `import_mapping_no_header_dark.png` | "First row is a header" off: each column shows its first value under "Column {A}" (critique 2026-09-30 part 1). |
| mappingIncomplete | no golden | no golden | The error is a banner of its own, not a red border (K3). The "mapped for you" note shows only once the mapping is complete. |
| previewAll | no golden | no golden | Rows stack front over back instead of three columns. |
| previewMix | `import_preview_light.png` | `import_preview_dark.png` | As previewAll; the invalid row is not tinted, its reason and icon say it. |
| importing | no golden | no golden | Navigation is inert (IT-NAV-012 step 5). |
| success | no golden | no golden | `MxEmptyState`, success tone; no deck name in the body. Import another file · View the cards (UC step 8). |
| partial | `import_partial_light.png` | `import_partial_dark.png` | As success, with the skipped counts and the skip note. |
| sectionsUndecided | `import_sections_undecided_light.png` | `import_sections_undecided_dark.png` | The Decks block with a taken name undecided; Import is locked and the caption says how many decks to choose for (U6). |
| sectionsDecided | `import_sections_decided_light.png` | `import_sections_decided_dark.png` | "Add to existing" chosen and its consequence; rows grouped under each deck's name as typed with its cards, 3 rows per deck (C1, C3, C4). |
| sectionsChooseAll | `import_sections_choose_all_light.png` | `import_sections_choose_all_dark.png` | Two taken names: a first row "{n} decks with taken names" with "Add all to existing" · "Create all new", nothing chosen (C2). |
| sectionsResult | `import_sections_result_light.png` | `import_sections_result_dark.png` | The counts, then a Decks section (New / Existing, cards); the primary action is Back to deck (U8). |
| sectionsRefused | no golden | no golden | A file split by `*` rows into a deck of cards (E7) or at level 10 (E8): a warning banner at Columns, Preview locked (U7). VERIFIED (closing acceptance 2026-10-18): `transfer/presentation/card_import_sections_screen_test.dart::a sectioned file into a deck of cards says so and locks Preview (E7)`; `transfer/presentation/card_import_state_coverage_test.dart::sectionsRefused: a sectioned file into a deck at level 10 says so in a warning banner at Columns and locks Preview (E8, U7)` |
| sectionTargetChanged | no golden | no golden | A deck chosen for "Add to existing" changed before Import (E9): a warning banner with "Preview again" on the preview. VERIFIED (closing acceptance 2026-10-18): `transfer/presentation/card_import_state_coverage_test.dart::sectionTargetChanged: a deck chosen for Add to existing that moved before Import is a warning banner with Preview again (E9)` |
| none | no golden | no golden | Neutral tone; Import another file · Back to deck (ruling 1). |
| failed | no golden | no golden | `MxEmptyState`, danger tone, "Import didn’t finish"; Close · Try again. A write that dies on a bug, not a `Failure`, ends here too (reported, ADR-016), so the wizard is never left on importing with Back and Close inert. Try again does not return to the preview: it commits the same preview again at once (`CardImportController.retry()` sets the draft back and calls `commit()`), so the screen goes to importing, then to a result. `card_import_controller_test.dart::a write that fails keeps the preview, and Try again commits it again (E5)`. |
| rejects | no golden | no golden | `MxEmptyState`, warning tone, "This deck no longer accepts cards"; Close only (E4). `card_import_controller_test.dart::a deck that gained sub-decks refuses the commit: the rejects result (E4)`. |
| pickerCancelled | no golden | no golden | The system picker is dismissed: the source chosen before stays (A5). `card_import_controller_test.dart::a cancelled picker keeps the source chosen before (A5)`, `card_import_source_pick_test.dart::from Paste, the file card switches to file and opens the picker; a cancelled picker leaves file chosen with no source`. |
| unsupportedFile | no golden | no golden | A name that is not CSV, TSV or XLSX, or a picker that throws, is refused at step 1 with the unreadable-file problem; the platform message (which may carry a path) is never shown (E1). `card_import_controller_test.dart::a file that is not CSV, TSV or XLSX, or not UTF-8, is refused at step 1 (E1)`. |
| previewRefused | no golden | no golden | A rejection from the preview or read (an unmapped Term or Meaning, E7, E8, an empty source E2, a deck that no longer takes cards E4) is always shown as a banner of the step's own: at Columns (`isShownImportProblem`; an incomplete mapping has its own warning and is not repeated) and on the preview. The refusal copy puts the local-first fact first ("Nothing was read." / "Nothing was added."). Preview waits for a change at Columns, since the same source and mapping would be refused again; "Preview again" is offered only for a stale preview (a deck changed, an emptied source). `import_preview_problem_test.dart::$problem on the preview says why and locks Import`, `::$problem at Columns says why; Preview waits for a change (audit 2026-10-17: no silent refusal)` (both emptySource and targetRejected), `::a refusal on the preview that is not stale still says why`, `card_import_screen_test.dart::an unmapped back locks Preview and says why (BR-TRANSFER-002)`. |

Goldens: `test/features/transfer/presentation/goldens/import_{source,mapping,preview,partial}_{light,dark}.png` and `import_sections_{undecided,decided,choose_all,result}_{light,dark}.png`.

## Transitions

`sections*` is sectionsUndecided, sectionsDecided and sectionsChooseAll.

| From | Event | To | Evidence |
|---|---|---|---|
| empty (Source) | choose a file | fileSelected, or unsupportedFile / pickerCancelled | VERIFIED `card_import_screen_test.dart::a file becomes cards through the four steps (IT-CARD-014)`; the other two as in States |
| empty (Source) | paste text | pasted; blank text is no source | VERIFIED `card_import_controller_test.dart::pasted text is a source once it holds something (A1)`, `card_import_screen_test.dart::pasted text is read on the device, and the caption says text` |
| fileSelected / pasted | remove the source | empty (Source) | `UNVERIFIED (code read)`: `card_import_controller.dart` `clearSource()` |
| fileSelected / pasted | Map columns | parsing, then mapping, or badEncoding / emptySheet | VERIFIED `card_import_screen_test.dart::a Latin-1 file is refused at step 1 with guidance (E1)` for the refusal; the success path in the first test above |
| mapping / previewAll / previewMix | Back while the next step is read | nothing: Back is held (`stepBack` returns true while `isBusy` past step 1), so a late result never throws the person forward again; at Source it still closes | VERIFIED `card_import_controller_test.dart::Back does nothing while the preview is read: a late result never throws the person forward again` |
| mapping / previewAll / previewMix | the read throws (a locked database, a bug) | the step stays and leaves busy, so Back steps back and the button works again; a Failure shows its toast, a bug is reported | closing review 2026-10-17. VERIFIED `card_import_read_failure_test.dart::a failed preview leaves busy, passes the Failure on, and Back still steps back`, `::a bug in the preview is reported and leaves busy`; the toast `UNVERIFIED (code read)`: `CardImportScreen._read` |
| parsing | the options are tapped | ignored, announced as disabled | VERIFIED `import_source_option_test.dart` (while reading, the option is announced as disabled) |
| mapping | choose another sheet of a workbook | parsing, then mapping of that sheet (A2) | `UNVERIFIED (code read)`: `card_import_controller.dart` `readSource(sheetIndex:)` |
| mapping | toggle "First row is a header" | mappingNoHeader / mapping | `UNVERIFIED (code read)`: `setHasHeaderRow`; the golden shows the off state |
| mapping | Term or Meaning left unmapped | mappingIncomplete; Preview locked | VERIFIED `card_import_screen_test.dart::an unmapped back locks Preview and says why (BR-TRANSFER-002)`, `card_import_controller_test.dart::an unmapped back stops the preview, and mapping it lets it through (BR-TRANSFER-002)` |
| mapping | Preview rows is refused (empty source, or the deck no longer takes cards) | previewRefused: the problem's banner at Columns; Preview off until the mapping, the source or the header toggle changes (empty source), so a silent dead button never remains | VERIFIED `import_preview_problem_test.dart::$problem at Columns says why; Preview waits for a change (audit 2026-10-17: no silent refusal)` (the locked Preview is asserted for emptySource; the targetRejected title is shown) |
| previewAll / previewMix / sections* | the refusal is not stale (the deck no longer takes cards, levels too deep, a file split into decks for a deck of cards) | the banner says why, with no "Preview again"; Import locked | VERIFIED `import_preview_problem_test.dart::a refusal on the preview that is not stale still says why` (targetRejected); `::$problem on the preview says why and locks Import` (depthExceeded, sectionsNeedDeckContainer) |
| previewAll / previewMix / sections* | the refusal is stale (`sectionTargetChanged`, `emptySource`) | the banner with "Preview again" | VERIFIED for `sectionTargetChanged`: `card_import_state_coverage_test.dart::sectionTargetChanged: a deck chosen for Add to existing that moved before Import is a warning banner with Preview again (E9)`; `emptySource` `UNVERIFIED (code read)`: `isStalePreviewProblem` |
| sectionTargetChanged | Preview again | the decks are read again: a fresh preview, the banner gone and Import unlocked | VERIFIED `card_import_preview_again_test.dart::sectionTargetChanged: Preview again reads the decks again, clears the banner and unlocks Import (E9)`. Fixed 2026-10-18 (closing acceptance REG-E9): the fresh preview kept the stale problem, so the banner stayed and Import stayed locked (`CardImportController.previewRows`) |
| mapping | Preview rows | previewAll / previewMix / sections*, or previewRefused | VERIFIED `card_import_screen_test.dart::a file becomes cards through the four steps (IT-CARD-014)` |
| previewAll / previewMix / sections* | toggle Include duplicates | the willWrite count follows | VERIFIED `card_import_controller_test.dart::Include duplicates writes them as new cards (A4)` |
| sections* | choose Add to existing / Create new, or all | sectionsDecided; Import unlocks when every clash is decided | VERIFIED `import_decks_section_test.dart::a clash shows the tray with nothing chosen; a tap chooses (U3)`, `::two clashes add a row that decides them all (C2)` |
| sections* | rename the default deck | its choice clears and its clash is found again | VERIFIED `card_import_sections_controller_test.dart::renaming the default deck clears its choice and finds its new clash (U4)` |
| sections* | go Back to Columns and change the mapping | the choices clear, the default name stays | VERIFIED `card_import_sections_controller_test.dart::changing the mapping clears the choices; the default name stays (Review Focus 2)` |
| previewAll / previewMix / sections* | a chosen deck changed before Import | sectionTargetChanged: warning banner with Preview again | VERIFIED `card_import_preview_again_test.dart::sectionTargetChanged: Preview again reads the decks again, clears the banner and unlocks Import (E9)` (the commit refused, then the banner) |
| previewAll / previewMix / sections* | Import {n} | importing, then success / partial / none / sectionsResult | VERIFIED `card_import_screen_test.dart::a file becomes cards through the four steps (IT-CARD-014)`; `import_result_decks_test.dart::the result lists each deck with New or Existing and its cards` |
| importing | Close or Back | nothing | `UNVERIFIED (code read)`: `card_import_screen.dart` `_close()` and `stepBack()` |
| importing | the write fails | failed | VERIFIED `card_import_controller_test.dart::a write that fails keeps the preview, and Try again commits it again (E5)` |
| importing | the write dies on a bug (not a `Failure`) | failed (Try again); the error is reported, Back and Close are no longer inert | VERIFIED `card_import_controller_test.dart::a bug in the write (not a Failure) ends on Try again, never stuck on importing with Back and Close inert (ADR-016)` |
| mapping | TalkBack reads a column's field chip | "Column {letter} goes to {field}" | VERIFIED `import_mapping_row_test.dart::the field chip names its column for TalkBack, not only the field` |
| previewAll / previewMix | TalkBack reads a row with a note | the note once (in the row's text); the mark stays silent and only a ready row's mark says "Ready" | VERIFIED `import_preview_row_test.dart::a row with a note says it once to TalkBack, not in the text and again on its mark (audit 2026-10-17)` |
| importing | the deck now holds sub-decks | rejects | VERIFIED `::a deck that gained sub-decks refuses the commit: the rejects result (E4)` |
| failed | Try again | importing again with the same preview, then a result | VERIFIED `::a write that fails keeps the preview, and Try again commits it again (E5)` |
| failed / rejects | Close | the screen closes | `UNVERIFIED (code read)`: `card_import_screen.dart` |
| success / partial / none | Import another file | empty (Source), a fresh draft | VERIFIED `card_import_controller_test.dart::Import another file starts a fresh step 1` |
| success | View the cards | the deck's card list; a sectioned import leads Back to deck | VERIFIED `import_result_decks_test.dart::a sectioned import leads back to the deck; a flat one to its cards` |
| partial | Show all {n} | every skipped row | VERIFIED `import_result_skipped_test.dart::a partial import lists its skipped rows with why, five at first, all after Show all` |
| previewAll / previewMix / sections* / mapping | Back | mapping / the Source step (fileSelected or pasted), the draft kept | VERIFIED `card_import_controller_test.dart::Back steps back one step and keeps what it held; at step 1 it closes (IT-NAV-012)` |
| empty (Source), a result | Back | the screen closes | same test |
| any | the picker or read result arrives after the screen is gone | no state is set | `UNVERIFIED (code read)`: the controller returns on `!ref.mounted` after each await |

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
- **Critique 2026-10-08 (DEV-289, after the build):** F1 an undecided deck shows no New or Existing badge until its choice is made; F2 the default deck's name field has a visible "Deck name" label above it (since DEV-372 the field paints that label itself). One audit confirmed both.
- **Critique 2026-10-08 (owner-requested, PR 270), spec C1–C5:** group titles are the deck name as typed with its cards, never upper-cased; two or more taken names add a choose-all row; a sectioned preview shows 3 rows per deck and "{n} more rows in this deck"; a clash names the existing deck's cards and, once chosen, its consequence; "Include duplicates" speaks of each deck. Its one audit reworded an empty existing deck ("{name} is already here, with no cards.").
- **Spec 2026-10-08 S6:** a workbook opens on its first sheet, even an empty one, which then says there are no rows; the sheet chip still offers the others.
- **Q-C-1 (owner, 2026-10-16):** the source file hint, a no-card deck line and a row's reason keep each dot on the phrase before it (`metaDots`); the file line ("CSV · 2 rows · 2 columns") wraps only between whole terms, with no dot at a line edge (`MxTermLine`; spec W1, 2026-10-20); the header row's column names are whole terms of the same kind (The Wrap Rule; `lib/l10n/meta_line.dart`).
- **Owner 2026-10-16:** the footer caption reads "Pick how to import {n} decks with taken names." ("Choose…" wrapped to two lines from three-digit counts in English at 360 dp, against the one-line footer caption ruling of 2026-10-05); `footer_caption_length_test.dart` measures it at 9999 decks.

## Copy

- Steps: "Source" · "Columns" · "Preview" · "Import" · "Step {n} of 4: {name}".
- Source: "Choose a source" · "Choose a file" · "CSV, TSV or XLSX · UTF-8" · "Paste text" · "Tab- or comma-separated rows" · "Pick a spreadsheet or text file" · "Nothing is added until you confirm." · "Each row makes one card".
- Problems: "This file is not UTF-8" · "This file can’t be read" · "There are no rows to import" · "This deck no longer accepts cards". Their bodies lead with the local-first fact: "Nothing was read. Save it again as UTF-8 …", "Nothing was read. Choose a CSV, TSV or XLSX file that is not protected.", "Nothing was added. A deck of cards can’t hold decks: import from its parent deck instead.", "Nothing was added. Decks go at most 10 levels deep: import from a higher deck."
- Mapping: "Map columns" · "First row is a header" · "Column {letter}" · TalkBack on the chip: "Column {letter} goes to {field}" · "Term (front)" · "Meaning (back)" · "Example" · "Hint" · "Pronunciation" · "Tags" · "Not imported" · "Map one column to Term and one to Meaning. Both are required."
- Preview: "Preview" · "Ready · {n}" · "Invalid · {n}" · "Duplicate · {n}" · "Blank · {n}" · "Already in this deck" · "Repeated in the file (row {row})" · "Showing the first {shown} of {total} rows" · "Include duplicates".
- Footer: "Map columns" · "Preview rows" · "Import {n}" · "Importing…" (Vietnamese "Ghép cột" · "Xem trước" · "Nhập {n}" · "Đang nhập…"); each fits half the 360 dp footer row (The Footer Pair Rule).
- Result: "Imported" · "Imported with skips" · "Nothing added" · "Import didn’t finish" · "This deck no longer accepts cards" · "Added as new cards" · "Skipped — duplicates" · "Skipped — invalid rows" · "View the cards" · "Import another file" · "Back to deck" · "Try again".
- Decks (spec 2026-10-08): "Decks" · "New" · "Existing" · "{n} cards" · "No cards to add · no deck made" · "Add to existing" · "Create new" · "The deck with this name holds decks, so a new one is made." · "Uncategorized" · "Another deck in this file has this name." · "Deck name after * is empty" · "Deck name over 200 characters" · "Pick how to import {n} decks with taken names." · "{n} decks with taken names" · "Add all to existing" · "Create all new" · "{name} already has {n} cards." · "{name} is already here, with no cards." · "Cards already in it are skipped." · "A second deck named {name} is made." · "{n} more rows in this deck" · "Off: rows already in their deck or repeated within it are skipped." · "Fix the deck name to continue." · "This file is split into decks" · "No room for another level" · "A deck changed meanwhile" · "Preview again".
