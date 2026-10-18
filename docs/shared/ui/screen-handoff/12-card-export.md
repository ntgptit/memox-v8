<!-- Hand-written screen record. -->

# 12 · Card export

A bottom sheet that hands a deck's cards, or the selected ones, to the system share
sheet as a CSV, TSV or XLSX file. UC-TRANSFER-002; spec
[2026-09-26-card-transfer-design.md](../../../superpowers/specs/2026-09-26-card-transfer-design.md)
§6, §8.

## Entry points

- The open deck's `⋮` sheet, "Export cards": a deck of cards only. An unset deck, a root
  and a deck of decks do not offer it (UC-TRANSFER-002 E5). The deck's cards are
  counted before the sheet opens, so the sheet never loads.
- The card list's bulk bar, "Export": the selected cards. The selection stays after the
  export (A1).

## Layout

| Region | Widget | Design |
|---|---|---|
| Header | `MxBottomSheet` header | "Export all {n} cards" and "Every card in {deck}, whatever filter or search is active."; for a selection, "Export {n} selected cards" and "Only the cards you selected." The sheet draws its own head, so the title is marked as the sheet's heading (`header` and `namesRoute`) as `MxBottomSheet`'s own title is. |
| Problem | `MxInlineBanner` | One banner per problem, above the formats. Danger for a file that could not be prepared, warning otherwise. |
| Formats | `MxListSectionHeader` + `MxOptionRow` × 3 | CSV (default, "Recommended" badge), TSV, XLSX, each with what it is for. Locked while a file is prepared. |
| Content note | `MxNote` (file icon) | The six columns; no schedule, no history. |
| Footer | `MxSheetActions` (sheet form) | Cancel · "Export", no icon (the title names the cards, DEV-179); "Preparing…" spinning while the file is built and shared (A4); "Try again" after a failure it can fix; Close alone when it cannot. |
| Toast | `MxSnackbar` | "Handed {n} cards to the system." once the share sheet took the file. |

The overline, the banner and the note line up with the title (24 dp).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| wholeDeck | `export_deck_light.png` | `export_deck_dark.png` | CSV carries "Recommended"; the action reads "Export" and the header names the count (DEV-179). `card_export_sheet_test.dart::the whole deck is counted, then handed over; the toast says so (steps 1–7)`. |
| selection | no golden | no golden | As wholeDeck, with "Export {n} selected cards". `card_export_sheet_test.dart::a selection names its count; XLSX is written when chosen (A1, A2)`. |
| countFailed | no golden | no golden | The whole-deck entry counts the cards before the sheet opens; if that read fails, no sheet opens and a toast gives the failure. Code read: `card_export_sheet_widget.dart` (`showDeckExportSheet`). |
| preparing | no golden | no golden | The confirm reads "Preparing…" and spins, the format rows are locked, a second tap makes no second file; Cancel, Back, the scrim and a drag close the sheet and nothing is shared. `card_export_controller_test.dart::a second tap while the file is prepared makes no second file (A4)`, `::closing the sheet while the file is prepared shares nothing`, `card_export_sheet_test.dart::$how while the file is prepared shares nothing, even once it is ready (A5, ruling E6)`. |
| handedOver | no golden | no golden | The sheet closes by itself and the toast names no file. `card_export_sheet_test.dart::the whole deck is counted, then handed over; the toast says so (steps 1–7)`. |
| shareClosed | no golden | no golden | The share sheet is dismissed without a share: the export sheet stays open, as it was, with its format (A3). `card_export_sheet_test.dart::closing the share sheet keeps the export sheet as it was (A3, ruling E1)`. |
| failed | `export_failed_light.png` | `export_failed_dark.png` | For a read or encode failure: "Couldn't prepare the file" in a danger banner, Try again builds again (E3). A share failure has its own copy, "Couldn't hand the file over", in a warning banner, also with Try again. `card_export_controller_test.dart::a read that fails says so and Try again builds again (E3)`, `card_export_sheet_test.dart::a share error offers Try again; no share target offers Close only (E1, E2)`. |
| noShareTarget | no golden | no golden | The banner shows the warning glyph; the formats lock and a lone Close stays. `card_export_sheet_test.dart::a share error offers Try again; no share target offers Close only (E1, E2)`. |
| staleSelection | `export_stale_light.png` | `export_stale_dark.png` | (`card_export_sheet_test.dart::a selection with a card gone meanwhile exports nothing (E6)`.)  The selection changed since the sheet opened (FE-B1 D12 closes X11); the body says what happened, that nothing was exported, and to close the sheet, check the selection and export again. The format rows are locked, as in every final problem (critique 2026-09-30 part 1). |
| nothingToExport | no golden | no golden | Reached only by a deck emptied between the count and the export, or by a count of 0. `card_export_sheet_test.dart::an empty deck opens on nothing to export (E5)`. |

Goldens: `test/features/transfer/presentation/goldens/export_{deck,failed,stale}_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| (deck ⋮) | Export cards | the deck is counted, then wholeDeck (or nothingToExport at 0); a failed count is countFailed | VERIFIED `test/app/library_routes_test.dart::Export opens its sheet from the deck and from a selection (UC-TRANSFER-002)`, `card_export_sheet_test.dart::an empty deck opens on nothing to export (E5)`; the failed count `UNVERIFIED (code read)` |
| (card list bulk bar) | Export | selection; the selection stays after the sheet | VERIFIED `test/app/library_routes_test.dart::Export opens its sheet from the deck and from a selection (UC-TRANSFER-002)`; that the selection stays is `UNVERIFIED (code read)` |
| wholeDeck | TalkBack opens the sheet | the title "Export all {n} cards" is read as the sheet's heading and names the route | VERIFIED `card_export_sheet_test.dart::the whole deck is counted, then handed over; the toast says so (steps 1–7)` (it asserts `isHeader` and `namesRoute`) |
| wholeDeck / selection | choose a format | the same state with that format | VERIFIED `card_export_controller_test.dart::the chosen format is the one written (A2)` |
| wholeDeck / selection | Export | preparing, then handedOver (the sheet closes, the toast shows) | VERIFIED `card_export_sheet_test.dart::the whole deck is counted, then handed over; the toast says so (steps 1–7)` |
| preparing | a second tap on Export | one file | VERIFIED `card_export_controller_test.dart::a second tap while the file is prepared makes no second file (A4)` |
| preparing | Cancel, Back, scrim, drag | the sheet closes; the file is never shared, even if it finishes | VERIFIED `card_export_controller_test.dart::closing the sheet while the file is prepared shares nothing`, `card_export_sheet_test.dart::$how while the file is prepared shares nothing, even once it is ready (A5, ruling E6)` |
| preparing | the share sheet is dismissed | shareClosed (the sheet as it was) | VERIFIED `card_export_sheet_test.dart::closing the share sheet keeps the export sheet as it was (A3, ruling E1)` |
| preparing | the file cannot be built | failed | VERIFIED `card_export_controller_test.dart::a read that fails says so and Try again builds again (E3)` |
| preparing | the share fails | failed (share copy) | VERIFIED `card_export_sheet_test.dart::a share error offers Try again; no share target offers Close only (E1, E2)` |
| preparing | a bug (not a Failure) while the file is built or shared | failed (prepare or share copy); reported; Export comes back | VERIFIED `card_export_held_bug_test.dart::a bug while the file is built says it could not be prepared`, `::a bug from the share sheet says the share failed` (closing review 2026-10-18) |
| failed | Try again | preparing again | VERIFIED `card_export_controller_test.dart::a read that fails says so and Try again builds again (E3)` |
| preparing | no share target | noShareTarget; Close only | VERIFIED `card_export_sheet_test.dart::a share error offers Try again; no share target offers Close only (E1, E2)` |
| selection / preparing | a selected card was moved or trashed | staleSelection; formats locked, Close only | VERIFIED `card_export_controller_test.dart::a selection with a card gone meanwhile exports nothing (E6)`, `card_export_sheet_test.dart::a selection with a card gone meanwhile exports nothing (E6)` |
| nothingToExport / staleSelection / noShareTarget | Close | the sheet closes | VERIFIED in the sheet tests above |
| preparing | the sheet closes while the share is pending | no state is set after the sheet is gone | `UNVERIFIED (code read)`: `card_export_controller.dart` checks `ref.mounted` and `_isClosed` |

## Rulings

- **Critique 2026-09-30 part 1, R8:** a final problem (stale, empty, no share target) locks the format rows; its lone Close stays primary (ruling C1 of the M3 review).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the stale-selection body (`exportStaleBody`) reads "It was moved to another deck or sent to Trash meanwhile. Nothing was exported. Close this sheet, check your selection and export again."; the lone Close stays.
- **UC-TRANSFER-002 A3 (E1):** closing the share sheet keeps the export sheet open with its scope and format.
- **Spec §7, BR-TRANSFER-014 (E2):** the result reads "Handed {n} cards to the system." without the file name.
- **UC-TRANSFER-002 step 2 (E3):** CSV carries a "Recommended" badge.
- **UC-TRANSFER-002 E2–E4 (E4):** read and encode failures share "Couldn't prepare the file"; a share failure has its own copy; both offer Try again.
- **UC-TRANSFER-002 E5 (E5):** "Export cards" appears on a deck of cards only.
- **UC-TRANSFER-002 step 3 (owner 2026-09-26), superseded by DEV-179:** the action once read "Export {n} cards".
- **DEV-179 (owner 2026-10-06):** the header already names the cards, so the action reads "Export" alone.
- **BR-TRANSFER-013, backend plan C5:** the file name keeps the deck's own letters (`Nhà-hàng-2026-09-26.csv`).
- Banners use their tone glyph; `MxInlineBanner` has no glyph slot.
- **Q-C-1 (owner, 2026-10-16):** a format's body keeps each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- Header: "Export all {n} cards" · "Every card in {deck}, whatever filter or search is active." · "Export {n} selected cards" · "Only the cards you selected."
- Formats: "Format" · "CSV" · "Comma-separated · opens anywhere" · "TSV" · "Tab-separated · safest for commas in text" · "XLSX" · "Excel workbook" · "Recommended".
- Note: "Six columns: front, back, example, hint, pronunciation, tags. No schedule, no history — this is content, not a backup."
- Actions: "Cancel" · "Export" · "Preparing…" · "Try again" · "Close".
- Problems: "Couldn’t prepare the file" · "Couldn’t hand the file over" · "No app on this device can receive a file" · "A selected card is no longer in this deck" · "It was moved to another deck or sent to Trash meanwhile. Nothing was exported. Close this sheet, check your selection and export again." · "There is nothing to export".
- Toast: "Handed {n} cards to the system."
