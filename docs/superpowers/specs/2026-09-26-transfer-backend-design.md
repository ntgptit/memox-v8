# MemoX V8 — Card Transfer backend design (package 9a: CSV, TSV, pasted text)

Status: draft 2026-09-26 · Path: architectural

## 1. Intent

Build the first half of BE-B3 of [`docs/wbs_BE.md`](../../wbs_BE.md): the store side of
Card Transfer, UC-TRANSFER-001 (import) and UC-TRANSFER-002 (export), with
BR-TRANSFER-001…BR-TRANSFER-014 and the rules they lean on (BR-CARD-001…BR-CARD-004,
BR-DECK-008, BR-TAG-001, BR-TAG-002, BR-CORE-001, BR-CORE-002, BR-CORE-004), for CSV,
TSV and pasted text. Package 9b adds XLSX, read and written with `archive` and `xml`
(the owner, 2026-09-26), under its own spec.

The package writes `domain/`, `data/` and `di/` of a new feature, `lib/features/transfer/`;
a batch create in `card`; and a batch schedule start in `srs`. The screens belong to FE-B3
in [`docs/wbs_FE.md`](../../wbs_FE.md): screen 11 of the kit ("A11 · Card import", 16
states) and screen 12 ("A12 · Card export", 9 states). FE-B3 also owns picking a file,
writing the export into the app's private cache, and the share sheet; its spec decides the
plugins for them.

Success means:

- FE-B3 builds every state of screens 11 and 12 that CSV, TSV and pasted text reach from
  use cases alone: the typed file problems, the column mapping, the preview with every
  row's status, the confirmation's counts, the result, and the export's scope failures;
- an import is all or nothing, checks the deck and the duplicates again inside its own
  transaction, and writes cards that learning, the card list and export all see in the
  file's order;
- an export writes nothing, reads one consistent snapshot, gives the same content for the
  same data, and fails as a whole on a stale selection;
- import, export and the card editor share one validation (`CardDraft`) and one tag
  codec;
- every rule the backend owns has a test that fails when it breaks;
- the gate of the root `README.md` passes after every task, and the documents change in
  the same commits as the code.

## 2. Context (2026-09-26)

- `master` is at `d41f9be`: package 8 (#70, Tag Management) merged. Cards and decks in
  the Trash carry `delete_batch_id`; a text check fails any statement of `lib/` that reads
  `card` or `deck` without that filter (package 7 spec §11).
- **UC-TRANSFER-001 and UC-TRANSFER-002** are `ready` with `code: []`, and no test names
  them. The transfer README still carries the open question "repo chưa có code ứng dụng",
  which is no longer true.
- **The rules, in short.**
  - The target of an import takes cards as a single card create does: a sub-deck that is
    `unset` or `card`; checked again inside the commit (BR-TRANSFER-001).
  - Every row needs `front` and `back` after trim; a fully blank row is skipped; the
    content rules are the card's, with no second validation anywhere; tags in one cell
    are separated by `;` (BR-TRANSFER-002).
  - A duplicate is the key `front_folded + back_folded`, against the target deck's cards
    and earlier rows of the same source; skipped by default, written as a new card when
    the person includes duplicates; checked again inside the commit (BR-TRANSFER-003).
  - One transaction writes every card, exactly one new study state each from the root's
    scheduler and generation read once, and the tags; a failure rolls everything back;
    zero rows to write means no mutation; no schedule travels with the file
    (BR-TRANSFER-004). An `unset` target becomes `card` when at least one card is written
    (BR-TRANSFER-005).
  - Import content is private: nothing of it is logged; the file stays in memory; UTF-8
    and UTF-8 with a BOM only, anything else refused with guidance, never guessed
    (BR-TRANSFER-006).
  - Export has two scopes: `all` (the deck's own active cards, whatever the list shows) and
    `selected` (the materialized ids, each once; one stale id fails the request; an empty
    scope is refused) (BR-TRANSFER-007). It carries six content fields only
    (BR-TRANSFER-008), through the one tag codec (BR-TRANSFER-009), in `created_at ASC,
    id ASC` order with tags by folded name, from one snapshot, never N+1
    (BR-TRANSFER-010). It writes nothing and keeps the selection (BR-TRANSFER-011). The
    file starts with the six canonical headers, CSV and TSV carry a UTF-8 BOM
    (BR-TRANSFER-012), and its name is the sanitized deck name, a date from the clock and
    the format's extension, never logged (BR-TRANSFER-013). The file is handed over
    through the share sheet; closing it is a cancel (BR-TRANSFER-014).
- **The code today.**
  - `CardDraft` holds the content rules: `check()` returns the first failing field's
    reason in form order (front, back, example, hint, pronunciation, tags) but not which
    field; the static per-field checks serve the editor.
  - `CardRepository.createCard` checks the draft, reads the deck, applies
    `DeckEntity.checkCreateCard` (a deck of type `deck` refuses; a root is always `deck`,
    `schema.md` § `content_type`), inserts through `CardDao.insertCard` (trim, fold,
    blank optional → `NULL`), calls `ScheduleRepository.initializeCard` (which reads the
    root through the card, once per card), replaces the tags through
    `TagRepository.replaceForCard`, and turns an `unset` deck into `card`.
    `card_repository_impl.dart` is about 380 logical lines; the guard warns at 400
    (package 8's deferred minor asks for a split by role when `card` is next touched).
  - `foldText` is trim then `toLowerCase()`; `front_folded` and `back_folded` store it.
    It does not normalise Unicode (owner, 2026-09-26: stays so; §3 D17).
  - `DayClock` (`dayClockProvider`) is V8's clock; BR-TRANSFER-013's `clockProvider`
    means it.
  - drift stores `DateTime` as Unix seconds, and `newId()` is a random UUID v4. Cards
    written in the same second therefore tie on `created_at` and fall back to `id`, which
    is random: learning takes new cards by `created_at, id`
    (`StudySessionDao.newCards`), the card list's default sort is `(created_at DESC, id
    DESC)`, and export sorts by `created_at, id`. Without care, a 1,500-row import would
    be learned, listed and exported in a random order.
  - The index `idx_card_deck_created (deck_id, created_at, id)` serves the export's order.
  - No `archive`, `xml` or CSV package is in the project; pub.dev is reachable.
- **The kit.** Screen 11: `empty`, `fileSelected`, `pasted`, `parsing`, `mapping`,
  `mappingIncomplete`, `previewAll`, `previewMix`, `importing`, `badEncoding`,
  `emptySheet`, and the results `success`, `partial`, `none`, `failed`, `rejects`. Row
  statuses are ready, invalid (with the field and the rule: "Meaning is empty", "Term over
  60 characters"), duplicate ("Already in this deck", "Repeated in the file (row 4)") and
  blank. Screen 12: `wholeDeck`, `selection`, `generating`, `shared`, `dismissed`,
  `failed`, `shareUnavailable`, `staleSelection`, `emptyScope`. Three kit details differ
  from the UC and BR, which win (D7, D15, §9): the kit auto-maps the synonyms `term,
  meaning, sentence, labels`; it reads only a workbook's first sheet; and its file name is
  a slug (`nha-hang-2026-09-16.csv`).
- **Feature imports:** `card` may import `deck`, `srs` and `tags`; `transfer` is new.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Scope: BE-B3 without XLSX — CSV, TSV and pasted text, for import and export. Package 9b adds XLSX with `archive` and `xml`. No schema change, no migration, no new dependency in 9a. | The owner, 2026-09-26: split 9a/9b; XLSX brings the only new dependencies, and CSV/TSV already carry every rule of both use cases. |
| D2 | Approach A: `transfer` owns the sources, the mapping, the row classification, the commit's orchestration and export; `card` creates the cards (`createCards`); `srs` starts their schedules (`initializeCards`). The import map gains `transfer → {card}`. | The owner, 2026-09-26. One place creates cards; one function classifies rows for the preview and the commit, so they cannot disagree. |
| D3 | `TransferFormat` holds `csv` and `tsv`; 9b adds `xlsx`, and every exhaustive `switch` then asks for it. A `.xlsx` file is `unsupportedFormat` until 9b. | No format is offered before it works. |
| D4 | A file is read as strict UTF-8 after an optional UTF-8 BOM. A UTF-16 or UTF-32 BOM, bytes that are not UTF-8, or a decoded U+0000 (UTF-16 without a BOM) is `notUtf8`. Nothing guesses an encoding. | BR-TRANSFER-006; the kit's `badEncoding` names UTF-16. |
| D5 | Delimiter: `.tsv` is tab. `.csv` is `,`, unless its first non-blank record holds `;` outside quotes and no `,` outside quotes — then `;`. Pasted text is tab when its first non-blank record holds a tab outside quotes, otherwise as `.csv`. UC-TRANSFER-001's wording says so. | The owner, 2026-09-26: Excel in locales with a decimal comma, Vietnamese among them, saves CSV with `;`, even as "CSV UTF-8". |
| D6 | Records follow RFC 4180, with the leniencies of §5.3; a quoted field still open at the end of the source is `unreadable`. A row's number is its record's number, from 1. | UC-TRANSFER-001 E1 ("file hỏng"); the kit numbers rows so a person can find them in the file. |
| D7 | `ColumnMapping` gives each field at most one column and each column at most one field. The default maps the six canonical names (trimmed, any case; the first column wins) when the first row is a header, and column A → front, B → back when it is not. `front` and `back` must be mapped (`mappingIncomplete`). | UC-TRANSFER-001 step 4 and A3; BR-TRANSFER-002. The kit's synonyms go beyond the UC: FE-B3 records the deviation. |
| D8 | One pure classification serves the preview and the commit: blank → invalid → duplicate in the deck → duplicate in the file → ready (§6.2). Only valid rows claim a key. | BR-TRANSFER-002, BR-TRANSFER-003; preview and commit cannot drift apart. |
| D9 | The tag cell codec of BR-TRANSFER-009 lives in `transfer`'s domain and is the only one; decoding drops segments that are empty after trim. | BR-TRANSFER-009, BR-TAG-011; a trailing `;` in a hand-written cell is not an invalid tag. |
| D10 | The commit is one transaction: read the deck's keys, classify again, then `createCards`, which checks the deck before it writes, even when no row is left. It answers `ImportResult`; a gone deck is `deckNotFound`, a deck that no longer takes cards `deckRejectsCards`; any failure rolls everything back and leaves as a database `Failure`. | BR-TRANSFER-001, BR-TRANSFER-003, BR-TRANSFER-004, UC-TRANSFER-001 E3–E5. |
| D11 | One import shares one `now`. Its ids are generated, sorted ascending, and handed out in row order, so `(created_at, id)` follows the file for learning, the card list and export. | Seconds-precision `created_at` ties every card of an import (§2); no schema or ADR change is needed. |
| D12 | `CardDraft.firstFailure()` returns the first failing field and its reason; `check()` returns that reason. The field names live in a new `CardField` enum of the card domain, in form order. | BR-TRANSFER-002 forbids a second validation; the kit names the field ("Meaning is empty"). |
| D13 | Export reads one snapshot in one transaction: the deck, its active cards by `created_at, id`, and their tags in one statement by card, `name_folded`, `id`. | BR-TRANSFER-010: one snapshot, no N+1. |
| D14 | CSV and TSV files: a UTF-8 BOM, the header line `front,back,example,hint,pronunciation,tags` (tabs in TSV; explicit strings, not enum names), CRLF, and quotes only around a cell holding the delimiter, `"`, CR or LF. Content stays verbatim: no `'` before `=`, `+`, `-` or `@`. | BR-TRANSFER-012; its text-cell rule is XLSX's (9b), and changing the content would break BR-TRANSFER-010. |
| D15 | The file name is the deck name sanitized (§8.3), cut to 200 UTF-8 bytes on a grapheme boundary, then ` yyyy-MM-dd` of the local day of `DayClock.now()`, then the extension: `Nhà hàng 2026-09-26.csv`; `cards 2026-09-26.csv` when nothing is left. | BR-TRANSFER-013; a deck name may be 200 characters, which can pass the 255-byte limit of a file name. The kit's slug is a deviation FE-B3 records. |
| D16 | Export answers `ExportFile(fileName, mimeType, bytes, cardCount)`. Writing the temporary file and the share sheet are FE-B3's; so is picking a file to import. | BR-TRANSFER-014 is a UI and platform rule; the store stays testable without plugins. |
| D17 | No Unicode normalisation: import keeps the cell's code points, and the fold stays as it is. A separate WBS item holds the app-wide NFC decision. | The owner, 2026-09-26: normalising import alone would still differ from the editor. |
| D18 | The feature logs nothing, and no error it raises carries content: the UTF-8 decoder's `FormatException` never leaves the reader. | BR-TRANSFER-006, BR-TRANSFER-013, BR-CORE-002. |
| D19 | `encodeFailed` and `passwordProtected` arrive with 9b: writing CSV or TSV cannot fail, and only XLSX can be protected. | No rejection without a path that reaches it and a test that proves it. |
| D20 | `createCard` runs through the batch path. If `card_repository_impl.dart` would still pass the guard's 400-line warning, the plan splits it by role. | Package 8's deferred minor. |

## 4. Structure

```
lib/features/transfer/                        (new)
├── domain/
│   ├── failures/transfer_failure.dart        TransferRejection
│   ├── models/transfer_format_model.dart     TransferFormat (csv, tsv)
│   ├── models/import_source_model.dart       ImportSource, ImportFile, PastedText
│   ├── models/import_sheet_model.dart        ImportDocument, ImportSheet, ImportRow, columnLetter
│   ├── models/column_mapping_model.dart      ColumnMapping
│   ├── models/tag_cell_model.dart            TagCell (the one codec, BR-TRANSFER-009)
│   ├── models/import_preview_model.dart      ImportSettings, ImportRowOutcome…, ImportPreview
│   ├── models/import_result_model.dart       ImportResult
│   ├── models/export_model.dart              ExportScope…, ExportFile, exportFileName
│   ├── repositories/transfer_repository.dart
│   └── usecases/                             the four of §9
├── data/
│   ├── datasources/transfer_dao.dart         the deck's keys; the export snapshot
│   ├── mappers/delimited_text_mapper.dart    read and write CSV/TSV
│   └── repositories/transfer_repository_impl.dart
└── di/transfer_repository_provider.dart

lib/features/card/
├── domain/models/card_field_model.dart       CardField (new, D12)
├── domain/models/card_draft_model.dart       + firstFailure()
├── domain/repositories/card_repository.dart  + createCards
└── data/repositories/card_repository_impl.dart  + createCards; createCard delegates (D20)

lib/features/srs/
├── domain/repositories/schedule_repository.dart  initializeCard → initializeCards
└── data/…                                    the root read once

test/architecture/boundary_rules.dart         + 'transfer': {'card'}
```

The feature's one reason enum (ADR-011 D6), in 9a:

```dart
enum TransferRejection {
  unsupportedFormat,  // UC-TRANSFER-001 E1: not .csv or .tsv
  notUtf8,            // E1, BR-TRANSFER-006 (D4)
  unreadable,         // E1: a quoted field never closed (D6)
  mappingIncomplete,  // BR-TRANSFER-002: front or back unmapped
  deckNotFound,       // E4, UC-TRANSFER-002: the deck is gone or in the Trash
  deckRejectsCards,   // E4, BR-TRANSFER-001: a root, or a deck holding sub-decks
  emptyScope,         // UC-TRANSFER-002 E5, BR-TRANSFER-007
  staleSelection,     // UC-TRANSFER-002 E6, BR-TRANSFER-007
}
```

## 5. Reading a source

```dart
sealed class ImportSource { const ImportSource(); }

/// A file the person picked: its name gives the format and is never logged.
final class ImportFile extends ImportSource {
  const ImportFile({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

final class PastedText extends ImportSource {
  const PastedText(this.text);
  final String text;
}

final class ImportRow {
  const ImportRow({required this.number, required this.cells});
  final int number;              // the record's number in the source, from 1
  final List<String> cells;      // as read, untrimmed
  bool get isBlank;              // every cell is empty after trim
}

final class ImportSheet {
  const ImportSheet({this.name, required this.rows});
  final String? name;            // null for CSV, TSV and pasted text
  final List<ImportRow> rows;
  int get columnCount;           // the widest row
  bool get isEmpty;              // every row blank, or no row
}

final class ImportDocument {
  const ImportDocument(this.sheets);   // one sheet in 9a
  final List<ImportSheet> sheets;
  int get defaultSheetIndex;           // the first sheet that is not empty, else 0 (UC A2)
}

String columnLetter(int index);        // 0 → A, 25 → Z, 26 → AA
```

`TransferRepository.readSource(ImportSource)` answers
`Outcome<ImportDocument, TransferRejection>`. It runs the decode in `Isolate.run`, so a
large file does not hold the UI isolate; the result holds plain values.

### 5.1 Format and encoding

- **File:** the extension after the last `.`, in any case: `csv` → `,` or `;` (§5.2),
  `tsv` → tab; anything else, no extension included, is `unsupportedFormat`.
- **Bytes:** a leading UTF-8 BOM is dropped. A leading `FF FE` or `FE FF` is `notUtf8`.
  The rest is decoded as strict UTF-8; a malformed sequence is `notUtf8`, and so is a
  decoded U+0000 (D4).
- **Pasted text:** a leading U+FEFF is dropped; there is no encoding step.

### 5.2 Delimiter (D5)

The first record that holds a character other than whitespace decides. Counting only the
characters outside quotes:

- a `.tsv` file is tab, whatever it holds;
- a `.csv` file is `;` when that record holds `;` and no `,`; otherwise `,`;
- pasted text is tab when that record holds a tab; otherwise as a `.csv` file.

A source with no such record is read with `,` and yields only blank rows.

### 5.3 Records

- A field is quoted when its first character is `"`. Inside it, `""` is one `"`, and the
  delimiter and line breaks are text. The closing `"` ends the quoted part; characters
  after it, up to the next delimiter or line break, are kept as they are (`"a"b` →
  `ab`).
- A `"` anywhere else in an unquoted field is an ordinary character.
- A record ends at CRLF, LF or CR outside quotes. A line break at the very end does not
  start another record; each further line break does, as a blank row.
- A quoted field still open at the end of the source is `unreadable`, and nothing is
  returned.
- Every field is kept, empty ones included; cells are not trimmed here.

## 6. Mapping and classification

### 6.1 Settings and mapping

```dart
/// card domain, in form order (D12)
enum CardField { front, back, example, hint, pronunciation, tags }

final class ColumnMapping {
  const ColumnMapping(this.columns);
  factory ColumnMapping.byHeader(List<String> headerCells);  // the six canonical names
  factory ColumnMapping.byPosition(int columnCount);         // A → front, B → back
  final Map<CardField, int> columns;
  int? columnOf(CardField field);
  CardField? fieldAt(int column);
  ColumnMapping assign(CardField field, int column);  // frees the column's old field
  ColumnMapping unassign(CardField field);
  Set<CardField> get missing;                         // of {front, back}
}

final class ImportSettings {
  const ImportSettings({
    this.firstRowIsHeader = true,     // UC-TRANSFER-001 step 4
    this.mapping,                     // null: the default of D7 for this header choice
    this.includeDuplicates = false,   // UC-TRANSFER-001 A4
  });
}
```

`byHeader` compares each header cell, trimmed and lowercased, with `front`, `back`,
`example`, `hint`, `pronunciation` and `tags`; the first column with a name wins.
`byPosition` maps column A to `front` and B to `back` when they exist. A mapped column
the sheet does not have reads as an empty cell.

### 6.2 Classifying rows (D8)

`ImportPreview.classify(sheet, settings, deckKeys)` is pure; the preview and the commit
both call it. `deckKeys` holds `(front_folded, back_folded)` of the target deck's active
cards. With the first row as header, that row is not classified. When `mapping.missing`
is not empty, no row is classified. Otherwise each row, in order:

1. **Blank** when every cell of the row, mapped or not, is empty after trim.
2. Otherwise a `CardDraft` is built: `front` and `back` from their columns (empty when
   the column is missing), `example`, `hint` and `pronunciation` from theirs or `null`,
   `tagNames` from `TagCell.decode` of the tags column or none, `isFlagged` false.
3. **Invalid** when `draft.firstFailure()` answers: the row keeps the field and the
   reason.
4. The key is `(foldText(front), foldText(back))` — what the card row stores.
   **Duplicate in the deck** when `deckKeys` holds it.
5. **Duplicate in the file** when an earlier valid row claimed it; the row names that
   row.
6. Otherwise **ready**. A valid row claims its key when no earlier row has; an invalid row
   claims nothing, so a later valid copy of it is ready.

```dart
sealed class ImportRowOutcome { int get rowNumber; }
final class ImportRowReady extends ImportRowOutcome { /* rowNumber, draft */ }
final class ImportRowDuplicate extends ImportRowOutcome {
  /* rowNumber, draft, int? firstRowNumber — null when the deck holds it */
}
final class ImportRowInvalid extends ImportRowOutcome {
  /* rowNumber, front, back (trimmed, for display), CardField field, CardRejection reason */
}
final class ImportRowBlank extends ImportRowOutcome { /* rowNumber */ }

final class ImportPreview {
  final ColumnMapping mapping;           // the one used, default or given
  final bool includeDuplicates;
  final List<ImportRowOutcome> rows;     // every data row, in source order
  final int dataRowCount;                // data rows that are not blank, mapped or not
  int get readyCount, invalidCount, duplicateCount, blankCount;
  int get writeCount;                    // ready, plus duplicates when included
  List<CardDraft> get toWrite;           // in row order
}
```

- **E2 (empty source):** `dataRowCount == 0`.
- **E3 (nothing to write):** `writeCount == 0`.
- **Incomplete mapping:** `mapping.missing` is not empty; `rows` is empty.

### 6.3 The tag cell (D9)

```dart
abstract final class TagCell {
  /// `;` between names; `\` becomes `\\` and `;` becomes `\;` inside a name.
  static String encode(Iterable<String> names);

  /// Splits on `;` not escaped; `\;` and `\\` unescape; a `\` before anything else, or
  /// at the end, stays as it is. Segments empty after trim are dropped.
  static List<String> decode(String cell);
}
```

Names keep their spelling; the tag rules trim and fold them where they already do.

## 7. The import commit

`TransferRepository.importCards({deckId, sheet, settings, now})` answers
`Outcome<ImportResult, TransferRejection>`:

```
transaction
  keys    ← TransferDao.contentKeys(deckId)        -- active cards of the deck
  preview ← ImportPreview.classify(sheet, settings, keys)
  mapping incomplete           → Rejected(mappingIncomplete)
  created ← CardRepository.createCards(deckId, preview.toWrite, now)
  Rejected(notFound)           → Rejected(deckNotFound)
  Rejected(notACardContainer)  → Rejected(deckRejectsCards)
  Rejected(anything else)      → throw StateError   -- a checked draft refused: a bug
  Ok(ids)                      → Ok(ImportResult(added, skippedDuplicates,
                                                 skippedInvalid, ignoredBlank))
```

- `ImportResult.added` is the number written; `skippedDuplicates` is 0 when duplicates
  were included.
- A refusal writes nothing. Any throw rolls back every card, schedule row, tag, link and
  the content type, and leaves as the `Failure` of `mapDatabaseError` (E5).

`CardRepository.createCards({required String deckId, required List<CardDraft> drafts,
DateTime? now})` answers `Outcome<List<String>, CardRejection>` and joins the caller's
transaction:

1. Every draft passes `check()`, or the batch is refused with the first reason.
2. The deck: gone or in the Trash → `notFound`; of type `deck` → `notACardContainer`.
   This runs for an empty list too.
3. `n` ids are generated, sorted ascending, and given out in the order of `drafts`
   (D11). Every card is inserted with the same `now`.
4. `ScheduleRepository.initializeCards(deckId: deckId, cardIds: ids)` writes the start
   values of the root's scheduler at the root's generation, read once (BR-TRANSFER-004).
   It replaces `initializeCard`; a single create passes a list of one.
5. Each card's tags go through `TagRepository.replaceForCard`, as a single create does.
   The prototype measures 1,500 and 10,000 rows; a batch tag API comes only if that is
   too slow.
6. An `unset` deck becomes `card` once, when at least one card was written
   (BR-TRANSFER-005).

`createCard` is `createCards` with one draft, then the entity read back (D20).

## 8. Export

```dart
sealed class ExportScope { const ExportScope(); }
final class ExportAllCards extends ExportScope { const ExportAllCards(); }
final class ExportSelectedCards extends ExportScope {
  const ExportSelectedCards(this.cardIds);
  final Set<String> cardIds;              // duplicates are already gone
}

final class ExportFile {
  final String fileName;
  final String mimeType;                  // text/csv, text/tab-separated-values
  final Uint8List bytes;
  final int cardCount;
}
```

`TransferRepository.exportCards({deckId, scope, format, now})` answers
`Outcome<ExportFile, TransferRejection>` and writes nothing.

### 8.1 The snapshot (D13)

In one transaction, three statements, each filtering the Trash:

- the deck: `id`, `name`, where it is active;
- its own active cards: `id` and the six content columns, `ORDER BY created_at, id`;
- their tags: `card_id` and `name`, joining `card_tags`, `tags` (`owner_id IS NULL`) and
  the active cards of the deck, `ORDER BY card_id, name_folded, id`, grouped in Dart.

### 8.2 The scope

- The deck is gone or in the Trash → `deckNotFound`.
- `all`: no card → `emptyScope`.
- `selected`: an empty set → `emptyScope`; an id that is not one of the snapshot's cards
  (deleted, in the Trash, moved) → `staleSelection` for the whole request; otherwise the
  snapshot's cards whose id is in the set, in the snapshot's order.

### 8.3 Writing and naming

- CSV (`,`) or TSV (tab), as D14 says; an empty optional field is an empty cell; the tags
  cell is `TagCell.encode` of the card's tags in snapshot order.
- `exportFileName({deckName, now, format})`, pure, in the domain:
  1. Remove `<`, `>`, `:`, `"`, `/`, `\`, `|`, `?`, `*` and control characters (C0, DEL,
     C1).
  2. Turn each run of whitespace into one space; trim; drop leading and trailing dots.
  3. When nothing is left, use `cards`.
  4. Keep whole graphemes while the name's UTF-8 bytes stay within 200.
  5. Append a space, the local day of `now` as `yyyy-MM-dd`, a dot and the extension.

## 9. Use cases and the contract for the UI (FE-B3)

| Use case | Call |
|---|---|
| `ReadImportSourceUseCase` | `Future<Outcome<ImportDocument, TransferRejection>> call(ImportSource source)` |
| `PreviewImportUseCase` | `Future<ImportPreview> call({required String deckId, required ImportSheet sheet, ImportSettings settings = const ImportSettings()})` |
| `ImportCardsUseCase` | `Future<Outcome<ImportResult, TransferRejection>> call({required String deckId, required ImportSheet sheet, required ImportSettings settings})` |
| `ExportCardsUseCase` | `Future<Outcome<ExportFile, TransferRejection>> call({required String deckId, required ExportScope scope, required TransferFormat format})` — the date comes from `DayClock` |

What FE-B3 can rely on, screen 11:

- **Source problems** (`badEncoding` and its kin): `unsupportedFormat`, `notUtf8`,
  `unreadable`. The previous source stays; nothing was read (E1).
- **Mapping:** the preview's `mapping` is the one in force. Column labels are the header
  row's cells, or `columnLetter` when there is no header or the cell is empty.
  `mapping.missing` not empty is `mappingIncomplete`. Toggling the header passes
  `mapping: null` to get the default back.
- **Preview:** `rows` gives every row's status with its number; the counts feed the
  badges; `writeCount` is the Import button's number. `dataRowCount == 0` is E2;
  `writeCount == 0` is E3.
- **Result:** `ImportResult` with `added > 0` and nothing skipped is `success`, with
  skips `partial`, and `added == 0` is `none`. `deckNotFound` and `deckRejectsCards` are
  `rejects`; a `Failure` is `failed`, and Try again resubmits the same sheet and settings.
- **Order:** imported cards sit in file order for learning and export, and in reverse
  file order under the card list's default sort (newest first).

Screen 12:

- The scope comes from the entry point: `ExportAllCards` or `ExportSelectedCards`.
- `emptyScope` is `emptyScope`, `staleSelection` is `staleSelection`, `deckNotFound` is
  shown as `staleSelection`'s "nothing was exported"; a `Failure` is `failed`.
- `ExportFile` goes to the app's private cache and the share sheet under its `fileName`,
  whose spelling differs from the kit's slug (D15).

## 10. Tests

Each rule has a test that fails when it breaks, on a real in-memory database where data
is involved.

- **Card** (`test/features/card/…`): `firstFailure` gives each field and reason in form
  order, and `check()` agrees; `createCards` writes cards whose ids ascend in list order
  and share `created_at`, one schedule row each from the root, tags reused or created by
  folded name, `unset` → `card` once; an empty list writes nothing, a deck gone or of
  type `deck` refuses even then; one invalid draft refuses the batch; a failing schedule
  write rolls the batch back. `createCard` behaves as before.
- **srs:** `initializeCards` writes the root's start values for every card and reads the
  root once (a statement counter on the database).
- **Reading** (`test/features/transfer/data/delimited_text_test.dart`): extensions;
  BOM; UTF-16 BOM, malformed UTF-8 and U+0000 → `notUtf8`; `,`/`;`/tab choice, a `;`
  file whose quoted cells hold commas; quotes, `""`, line breaks in quotes, `"a"b`, a
  stray `"`; CRLF, LF, CR; a trailing line break; an unclosed quote → `unreadable`; row
  numbers; column count.
- **Domain** (`test/features/transfer/domain/…`): `ColumnMapping` defaults, `assign`,
  `missing`, `columnLetter`; `TagCell` round trips (`;`, `\`, `\;`, trailing `\`,
  legacy backslashes, empty segments); classification of every status and its order;
  in-deck and in-file keys under case and spaces; an invalid first copy; include
  duplicates; E2 and E3; `exportFileName` (invalid characters only, whitespace runs,
  dots, the 200-byte cut on a Vietnamese and an emoji name, the date).
- **Commit** (`test/features/transfer/data/import_cards_test.dart`): one transaction
  writes cards, schedules and tags; a duplicate created after the preview is skipped by
  the commit; `deckNotFound`, `deckRejectsCards` and zero rows write nothing
  (`totalChanges`); a forced failure rolls back everything; the file's order survives in
  learning's new-card order, the card list and export; a 1,500-row import in one
  transaction, timed.
- **Export** (`test/features/transfer/data/export_cards_test.dart`): the bytes of a CSV
  and a TSV file (BOM, headers, CRLF, quoting, empty cells, tags by folded name); scope
  `all` ignores the list's filter and skips cards in the Trash and in sub-decks;
  `selected` in `created_at` order whatever the set's order; each refusal; nothing
  written (`totalChanges`).
- **Round trip:** export then import into an empty deck gives the same six fields and tag
  sets, in the same order.
- **Use cases:** each passes its arguments through; `ExportCardsUseCase` takes the date
  from `DayClock`.
- The BR-TRASH-002 check and the architecture tests pass with the new statements and the
  new feature.

**Review Focus** (inputs most likely to bite first; the tests above pin each):

1. A CSV saved by Excel in Vietnamese: `;` between fields, quoted cells that hold commas
   and `;`-separated tags.
2. A file that repeats its own rows and the deck's cards with other case and spaces: one
   card per key by default, every row with Include duplicates.
3. A 1,500-row lesson list: learned, listed and exported in the file's order, written in
   one transaction.
4. A selected card sent to the Trash before the export runs: `staleSelection`, no file.
5. A deck named with 200 Vietnamese characters, or only with `/:*?`: a file name within
   255 bytes, or `cards …`.

## 11. Documents

- UC-TRANSFER-001: `code:` names the three import use cases and `CardRepository`'s batch
  create; the scope line says the store is built for CSV, TSV and pasted text (9a) and
  XLSX follows (9b); steps 2 and A1 say a CSV may be separated by `;` when its first row
  shows it (D5, the owner's permission of 2026-09-26).
- UC-TRANSFER-002: `code:` names the export use case; the scope line likewise.
- The transfer README: `code:` paths, the scope lines, and the stale open question
  removed.
- `wbs_BE.md`: BE-B3 in progress (9a done, 9b next); the NFC decision as a new item
  (D17); the next step; the log line.
- `wbs_FE.md`: FE-B3 points at §9 and records the kit deviations of D7 (canonical names
  only), UC A2 (a sheet picker instead of the first sheet only), D15 (the file name keeps
  the deck's spelling) and D5 (`;` accepted).
- `docs/_generated/` regenerated.

## 12. Out of scope

- XLSX, reading and writing, `encodeFailed` and `passwordProtected`: package 9b.
- FE-B3: screens 11 and 12, picking a file, the private cache file, the share sheet, the
  routes and IT-NAV-012.
- Unicode normalisation (D17).
- Backup, restore, sync, `.apkg` and Anki (the transfer README).
- A size cap: the contract has none.
- A batch tag API, unless the measurement of §7 asks for it.

## 13. Risks and rollback

- **Import speed:** per-card tag writes inside one transaction. The prototype measures
  1,500 and 10,000 rows before the plan is written.
- **Delimiter detection** can misread a one-column `.csv` whose first cell holds `;` and
  no `,`; such a file cannot hold `front` and `back` anyway. The header of this app's own
  exports holds `,`.
- **Order:** D11 relies on `(created_at, id)` being the tie-break wherever creation order
  matters; the tests pin learning, the card list and export.
- **Contract changes:** `createCards` and `initializeCards` touch the fakes of
  `ScheduleRepository` in four test files.
- **Rollback:** code and documents only, no schema, no migration, no dependency: reverting
  the pull request restores the previous behaviour, and no data needs converting.
