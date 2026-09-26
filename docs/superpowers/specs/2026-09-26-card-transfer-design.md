# MemoX V8 — Card transfer: import and export (BE-B3, FE-B3)

Status: approved 2026-09-26 · kit rulings added after the Impeccable critique (§8.1, §8.2) · D9 added by the owner after the merge (2026-09-26) · Path: architectural

## 1. Intent

Build the Card Transfer sub-project: UC-TRANSFER-001 (import cards in bulk into a deck)
and UC-TRANSFER-002 (export a deck's cards to a file), with BR-TRANSFER-001…BR-TRANSFER-014
and the card, deck and tag rules they lean on. It is BE-B3 of
[`docs/wbs_BE.md`](../../wbs_BE.md) and FE-B3 of [`docs/wbs_FE.md`](../../wbs_FE.md),
nice-to-have N1 of [`docs/README.md`](../../README.md).

Why now: the owner compared MemoX with Lexilize Flashcards (2026-09-26). Of the gaps that
need no change to a platform ADR, bulk import from a spreadsheet is the one Lexilize leans
on most, and it is the only one that does not wait for the unbuilt Study, Progress and
Settings tabs. The owner's use is **their own hand-made spreadsheets**; importing another
app's export format is not a goal.

Success means:

- a CSV, TSV or XLSX file, or pasted CSV/TSV text, becomes cards in a chosen deck in one
  all-or-nothing transaction, each card with exactly one fresh schedule row;
- the preview shows, before anything is written, which rows will be written, which are
  duplicates, which are invalid and why, and which are blank;
- a deck's cards, or a selection of them, leave the app as a CSV, TSV or XLSX file through
  the system share sheet, and exporting then importing the file gives the same content;
- every state of kit screens 11 and 12 is built, with goldens, light and dark;
- every rule the sub-project owns has a test that fails when it breaks;
- the phased gate of the root `README.md` passes after every task, and the documents change
  in the same commits as the code.

## 2. Context (2026-09-26)

- `master` is at `b69b45c`. Every V8.0 backend item is done; the Library tab and its card
  screens are real, while Study, Progress and Settings are still placeholders.
- **The use cases.** UC-TRANSFER-001 and UC-TRANSFER-002 are `ready` with `code: []`. Their
  acceptance criteria are still missing: neither has Given/When/Then.
- **The rules, in short.**
  - The target is a sub-deck that is `unset` or holds cards (BR-TRANSFER-001); a target
    that stops qualifying between preview and commit refuses the commit.
  - A row needs both faces and passes exactly the card rules (BR-TRANSFER-002,
    BR-CARD-001…BR-CARD-003, BR-TAG-001, BR-TAG-002).
  - A duplicate is `front_folded + back_folded` equal to a card of the target deck or to
    an earlier row of the same source; skipped by default, written as a new card with
    "Include duplicates"; never merged; checked again inside the commit transaction
    (BR-TRANSFER-003).
  - One transaction writes cards, schedule rows, tags and `content_type`
    (BR-TRANSFER-004, BR-TRANSFER-005).
  - Import content is private: no logging of content, pasted text, file names or raw rows;
    processed in app memory; UTF-8 and UTF-8 BOM only, anything else refused with guidance
    (BR-TRANSFER-006).
  - Export scope is the whole deck or the selection, fixed by the entry point
    (BR-TRANSFER-007); six canonical content fields, never schedule or history
    (BR-TRANSFER-008, BR-TRANSFER-012); one codec for the tags cell (BR-TRANSFER-009);
    deterministic content (BR-TRANSFER-010); read-only (BR-TRANSFER-011); file name from
    the sanitized deck name and the date (BR-TRANSFER-013); the file lives in a private
    temporary area until the share sheet takes it, and the app never says "saved"
    (BR-TRANSFER-014).
- **What exists.**
  - `CardRepositoryImpl.createCard` (`lib/features/card/data/repositories/`) already writes
    one card the right way inside one transaction: `CardDraft.check()`, the container rule
    (`DeckEntity.checkCreateCard`), `CardDao.insertCard`,
    `ScheduleRepository.initializeCard`, the tag links, and `unset` → `card`.
  - `CardDraft` holds the per-field rules as static checks (`checkFront`, `checkBack`,
    `checkOptional`, `checkTagNames`), so a preview can report each row's reason.
  - `foldText` (`lib/core/text/`) is the fold behind `front_folded` and `back_folded`.
  - Routes: the card screens hang under `AppRoutes.deckChild` (`deck/:deckId`), e.g.
    `cards/new`.
  - `pubspec.yaml` has no CSV, XLSX, file-picker or share package. The guard forbids only
    `dio`, `connectivity_plus` and `flutter_secure_storage`
    (`memox.architecture.no_deferred_dependency_import`).
  - [`it-scenarios.md`](../../features/transfer/it-scenarios.md) of the feature holds
    IT-NAV-012, IT-CARD-014 and IT-CARD-015.
- **The kit.**
  - Screen 11 "Card import" is a full-screen task: step tracker (Source · Preview ·
    Import), deck chip, dashed source card, mapping step, preview table, commit bar, and
    terminal result screens. Sixteen states: `empty`, `fileSelected`, `pasted`,
    `parsing`, `badEncoding`, `emptySheet`, `mapping`, `mappingIncomplete`, `previewAll`,
    `previewMix`, `importing`, `success`, `partial`, `none`, `failed`, `rejects`.
  - Screen 12 "Card export" is a bottom sheet over the card list. Nine states:
    `wholeDeck`, `selection`, `generating`, `shared`, `dismissed`, `failed`,
    `shareUnavailable`, `staleSelection`, `emptyScope`.
  - The card list's app-bar ⋮ opens `deckActions` (study · import · export · rename ·
    move · Trash); the empty card list offers "add or import".

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | Import and export in one spec; they share the canonical schema and the tags codec, and one round-trip test covers both | owner, 2026-09-26 |
| D2 | Behaviour | Exactly the specified UC/BR. No column aliases beyond the six canonical names; no Lexilize, Anki or Quizlet format | owner, 2026-09-26 |
| D3 | CSV/TSV codec | Package `csv` (8.x). Decoding bytes to text is ours: strict `utf8.decode` after stripping a BOM, so malformed input is refused, never guessed | owner (approach), 2026-09-26 |
| D4 | XLSX codec | Package `excel` (4.0.x) for read and write, imported by one file only. It has not been published since 2024-08; the fallback is a small reader/writer on `archive` + `xml` in that same file | owner, 2026-09-26 |
| D5 | Platform plugins | `file_picker` to choose a file, `share_plus` to hand the export to the system. Both support web, which ADR-001 needs for E2E | this spec |
| D6 | Who writes cards | The card feature, through its own contract `CardTransferRepository` (`foldedPairs`, `importCards`, `countCards`, `exportSnapshot`; split from `CardRepository` when the Trash backend grew it past the size budget); transfer never writes or reads the `card` table itself | ADR-011 D2/D3, this spec |
| D7 | Parsing off the UI thread | Parse and preview run in `Isolate.run`; the kit's sample is a 1,500-row file | this spec |
| D8 | Import route | `AppRoutes.deckChild` + `cards/import` → `/decks/deck/<id>/cards/import`, on the root navigator so the wizard covers the shell. IT-NAV-012 writes `/decks/<id>/cards/import`; it follows the real route shape and the scenario is corrected in the same commit | IT-NAV-012, this spec |
| D9 | CSV delimiter | A `.csv` file splits on `,` or `;` (Excel saves CSV with `;` where the decimal mark is a comma): the one that each of its first 20 records that hold text holds as often, at least once, counting only what lies outside quotes; when both or neither do, `;` if the first of those records holds `;` and no `,`, else `,`. Pasted text is TSV when its first record that holds text has a tab outside quotes, else it reads as a `.csv` file. `.tsv` stays tab, and export keeps `,`. The `csv` package's own detection is not used: it counts inside quotes and scores frequency over 10 lines, so a `;` file with commas in its cells reads as `,` | owner, 2026-09-26, after the merge (package 9a's D5, which did not merge) |

## 4. Structure

```
lib/features/transfer/
├── domain/
│   ├── models/        transfer_source_model, column_mapping_model,
│   │                  import_preview_model, export_artifact_model
│   ├── repositories/  export_share_repository  (contract: hand a file to the system)
│   ├── failures/      transfer_failure  (enum TransferRejection)
│   └── usecases/      preview_import_use_case, commit_import_use_case,
│                      build_export_use_case, share_export_use_case
├── data/
│   ├── codecs/        delimited_codec (csv), xlsx_codec (excel), text_decoding
│   └── repositories/  export_share_repository_impl (private temp file + share_plus)
├── di/                providers for the use cases and the share repository
└── presentation/      import screen, export sheet, controllers, states, widgets
```

`lib/features/card/` gains three methods on `CardRepository` (`foldedPairs`, `importCards`, `exportSnapshot`) and their implementation. The
folder buckets and file suffixes are the ones ADR-011 and the guard already check; the
feature's entry in the import map is added in the commit that creates the folder
(ADR-011 "Feature mới thêm entry").

## 5. Import

### 5.1 Source and decoding

- A source is either `FileSource(bytes, extension)` or `PastedSource(text)`. The domain
  never carries the file name; the wizard shows it on the source chip while it is open
  (screen 11), and it is never logged or stored.
- `.csv` and `.tsv` and pasted text: strip a UTF-8 BOM, then strict UTF-8 decode; failure →
  `badEncoding` with the guidance "Save the file as UTF-8 and try again". A `.csv` file
  splits on `,` or `;`, and pasted text on tab when its first record that holds text has
  one, else as a `.csv` file (D9).
- `.xlsx`: the workbook's sheet names are listed; the first non-empty sheet is chosen by
  default (UC-TRANSFER-001 A2). Every cell reads as text: numbers keep their written form,
  dates their ISO date. A protected or unreadable workbook → `unreadableFile`.
- Any other extension → `unreadableFile`. An empty source, sheet or text → `emptySource`
  (E2).

### 5.2 Mapping

- The first row is a header by default ("First row is a header"); turning it off names the
  columns `Column A`, `Column B`, … and validates the first row as data (A3).
- A header cell equal to one of `front`, `back`, `example`, `hint`, `pronunciation`,
  `tags` after `foldText` maps to that field. Nothing else is guessed (D2).
- `front` and `back` must be mapped; one source column maps to at most one field
  (BR-TRANSFER-002). Otherwise the preview is `mappingIncomplete` and cannot continue.

### 5.3 Preview

For every data row, in order, the preview decides one status:

1. `blank` — every mapped cell is empty after trim; ignored and counted.
2. `invalid(reason)` — `CardDraft` refuses it; the reason is the first failing check
   as the existing `CardRejection` (`blankContent`, `frontTooLong`, `backTooLong`,
   `optionalFieldTooLong`, `invalidTagName`, `tooManyTags`).
3. `duplicateInDeck` — its folded pair equals a card of the target deck.
4. `duplicateInSource(firstRow)` — its folded pair equals an earlier non-blank, valid row.
5. `ready`.

The tags cell is decoded by the one tags codec of BR-TRANSFER-009. The preview reports the
totals (rows, ready, duplicates, invalid, blank), the policy's "will write" count, and the
first rows for the table. It writes nothing. "Include duplicates" moves both duplicate
kinds into "will write" (A4). "Will write" of zero locks Continue (E3).

The target deck's folded pairs are read once per preview through
`CardTransferRepository.foldedPairs(deckId)`, a read the preview needs anyway to report
`duplicateInDeck`.

### 5.4 Commit

`CardTransferRepository.importCards({deckId, drafts, includeDuplicates})` →
`Outcome<ImportResult, CardRejection>`, in one transaction:

1. Re-read the target; not found, root-level or holding sub-decks → `notACardContainer`
   (E4), nothing written.
2. Re-read the deck's folded pairs and re-apply the duplicate policy to `drafts` in order
   (BR-TRANSFER-003).
3. For each draft kept: insert the card, `ScheduleRepository.initializeCard`, the tag
   links — the same steps as `createCard`, factored into one private helper both methods
   call.
4. `unset` → `card` when at least one card was written (BR-TRANSFER-005).
5. Return `ImportResult(written, skippedDuplicates)`.

A throw rolls back everything (E5). `CommitImportUseCase` maps the result to the result
screens: `written > 0` with nothing skipped → `success`; `written > 0` with skips →
`partial`; `written == 0` → `none` (every row turned out to be a duplicate at commit time);
a refusal → `rejects`; an error → `failed`.

## 6. Export

- `CardTransferRepository.exportSnapshot({deckId, cardIds?})` →
  `Outcome<ExportSnapshot, CardRejection>`: the deck's name and, for each card in
  `created_at ASC, id ASC`, the six fields and its tag names in a fixed order. Reading
  writes nothing (BR-TRANSFER-011). An empty scope → `emptyScope`; an id missing or in
  another deck fails the whole request → `staleSelection` (BR-TRANSFER-007, E5, E6).
- `BuildExportUseCase` encodes the snapshot: the six canonical headers, an empty cell for an
  absent field, a BOM for CSV and TSV, text cells for XLSX (BR-TRANSFER-012); the name from
  the sanitized deck name plus the local date (BR-TRANSFER-013). Same content → same bytes
  for CSV and TSV; XLSX is compared by its cell values, since the zip carries timestamps.
- `ShareExportUseCase` asks `ExportShareRepository` to write the bytes to the app's private
  temporary directory and open the share sheet. It answers `shared`, `dismissed`,
  `shareUnavailable` or `shareFailed`; the temporary file is deleted afterwards in every
  case.

## 7. Errors

- `TransferRejection` (ADR-011 D6): `unreadableFile`, `badEncoding`, `emptySource`,
  `mappingIncomplete`, `nothingToImport`, `targetRejected`, `commitFailed`, `readFailed`,
  `encodeFailed`, `emptyScope`, `staleSelection`, `shareUnavailable`, `shareFailed`.
  Dismissing the share sheet is a result, not a rejection.
- No message carries a path, a file name, an id or card content (BR-CORE-005,
  BR-TRANSFER-006, BR-TRANSFER-014). Diagnostics log only format, row counts, duration and
  the rejection.
- On any import failure the screen keeps its source, mapping and preview (E1, E4, E5).
- The commit button and the export button lock while their work runs; navigation is inert
  while the import transaction runs (IT-NAV-012 step 5, UC-TRANSFER-002 A4).

## 8. The screens

- **Entry points.** The card list's ⋮ `deckActions` gains Import and Export (export only
  when the deck has cards); the empty card list gains Import; the bulk bar gains Export;
  the create sheet of an `unset` deck gains Import (§8.1 ruling 3).
- **Import** is a pushed full-screen route (D8) with one controller holding the step, the
  source, the mapping and the preview as an immutable sealed state; Back steps back one
  step, and at Source acts as Close (IT-NAV-012).
- **Export** is a bottom sheet whose scope is passed in by the caller; it never loads.
- The copy is localized (en, vi); the widgets are built from the existing `Mx*` components.
  A widget the kit needs and the library lacks goes through the admission rule of
  `flutter-theme-design`.

### 8.1 Rulings on the kit (Impeccable critique 2026-09-26, owner 2026-09-26)

The pre-plan critique is `.impeccable/critique/2026-09-26T03-27-35Z__transfer-kit.md`
(31/40). The owner ruled:

1. **`none` stays.** It is a commit-time outcome: the duplicate re-check inside the
   transaction finds nothing to write (§5.4). It differs from E3, which locks Continue at
   preview. UC-TRANSFER-001 gains it as an error flow; the kit's copy and neutral tone stay,
   with one exit back to the deck.
2. **The XLSX sheet choice (A2) is not a state.** A "Sheet: <name> (n of m)" row on the file
   chip, shown only for a workbook with several sheets; changing it reruns mapping and
   preview like changing the file. One golden covers it as a variant of the file-chosen and
   mapping states.
3. **The entry points already match.** Import: the ⋮ `deckActions` sheet, the empty card
   list, and the third option of an empty deck. Export: `deckActions` and the bulk bar's
   Export (Move · Flag · Tag · Export · Trash). The one change: `deckActions` hides Export on
   an empty deck (UC-TRANSFER-002 E5 beats the kit).
4. **The tracker keeps the kit's four steps** (Source · Columns · Preview · Import).
   UC-TRANSFER-001's "three steps" wording changes to match; mapping is a decision of its
   own.

### 8.2 Deviations from the kit (P1 and P2 of the critique)

Recorded in the detail files of screens 11 and 12 when they are written:

| # | Kit | Built | Why |
|---|---|---|---|
| K1 | "1 · Choose a source" stays above mapping, preview and the commit | Once a source is read, Step 1 collapses to the file chip with its change action | P1: the buttons push the table and the commit down at every step |
| K2 | The preview table renders every row | The first rows, and a caption "Showing first N of M rows" tied to the summary counts | P1: UC-TRANSFER-001 step 5 already says "the first rows"; a 1,500-row file |
| K3 | Row status by icon colour; an unmapped column by a red border; cells ellipsize | Each status icon has a semantic label; the mapping error sits on its own row; cells wrap to two lines | P2: TalkBack and large text scale |
| K4 | The result screen hand-builds a tinted hero per outcome | The existing Mx empty-state and error-state components with their tones | P2: one component per contract |

The critique's P3 items (one vocabulary for the fields, an "Import another file" exit, a
waiting line for large imports) go to the UI-base debt register, not into this build.

## 9. Tests

| Layer | What |
|---|---|
| Codec unit | CSV/TSV quotes, embedded newlines and delimiters, BOM; the `,`/`;` choice of D9 (a comma inside a `;` file's cells, quotes, the 20-record window, blank records) and pasted text's tab; UTF-16 and Latin-1 refused; XLSX several sheets, empty sheet, number and date cells as text; encoder headers, empty cells, BOM, text cells |
| Round trip | export → import yields the same six fields and tags for every card, CSV, TSV and XLSX |
| Determinism | the same snapshot encodes to identical CSV/TSV bytes and identical XLSX cell values |
| Preview unit | header auto-map by fold, `front`/`back` missing, one column mapped twice, each row status, the first reason wins, Include duplicates |
| Repository (Drift in memory) | `importCards` all or nothing; one fresh schedule row per card; tags linked; `unset` → `card`; the duplicate re-check sees a card added after the preview; a target that holds sub-decks is refused with nothing written; `exportSnapshot` order, stale ids, empty scope, and no write |
| Controller | the import and export controllers reach every kit state and only through legal transitions |
| Widget + golden | every state of screens 11 and 12, light and dark, at a large text scale; goldens in the Linux container |
| IT | IT-NAV-012, IT-CARD-014, IT-CARD-015 |

`file_picker` and `share_plus` are reached only through providers, so tests replace them
with fakes. No test logs content.

## 10. Documents

In the same commits as the code:

- UC-TRANSFER-001 and UC-TRANSFER-002: Given/When/Then acceptance criteria replace the
  missing ones; `code:` lists the files; UC-TRANSFER-001 gains the `none` error flow and
  its steps read as four (§8.1).
- The UI-base debt register (spec 2026-09-23 §9): the critique's P3 items (§8.2).
- `docs/features/transfer/README.md`: `code:` filled; the stale "repo has no `lib/`" note
  and the "sub-project later" lines go.
- `docs/features/transfer/it-scenarios.md`: IT-NAV-012's URL (D8).
- `docs/shared/ui/screen-handoff/00-index.md`: rows 11 and 12 move from `out of V8` to their
  status, with detail files.
- `docs/wbs_BE.md` BE-B3 and `docs/wbs_FE.md` FE-B3: status; the FE-B3 blocker ("file
  picking and sharing need a platform plugin") is resolved by D5 with this spec as its
  record.
- `docs/README.md`: N1 moves out of the deferred list.

## 11. Out of scope

- Other apps' formats (Anki `.apkg`, Lexilize, Quizlet) and column aliases (D2).
- Backup and restore of the whole database, and sync (transfer README "Không thuộc phạm
  vi").
- Encodings other than UTF-8 (BR-TRANSFER-006).
- Updating or merging existing cards on import (BR-TRANSFER-003).
- Exporting schedule or history (BR-TRANSFER-008).

## 12. Risks and rollback

| Risk | Mitigation | Rollback |
|---|---|---|
| `excel` breaks on a newer Dart or Flutter | Only `data/codecs/xlsx_codec.dart` imports it; the round-trip tests pin its behaviour | Replace that file with a reader/writer on `archive` + `xml` |
| A large file stalls the UI | Parsing and preview in `Isolate.run` (D7); the commit is one transaction of plain inserts | — |
| `file_picker` or `share_plus` breaks the web build that E2E needs (ADR-001) | Both list web support; the plan's first slice that adds them runs `flutter build web` once | Hide the entry points on web |
| The whole feature must go | No schema change: it writes the existing `card`, schedule and tag tables | Remove the route, the entry points, the feature folder, the three repository methods and the four packages |

Plan slices, in order: codecs → `importCards`, `foldedPairs` and the preview → import
screen → `exportSnapshot` and sharing → export sheet.
