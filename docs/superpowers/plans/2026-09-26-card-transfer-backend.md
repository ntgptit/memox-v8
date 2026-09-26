# MemoX V8 Card Transfer Backend Implementation Plan (BE-B3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-B3 of [`docs/wbs_BE.md`](../../wbs_BE.md), the backend of Card
Transfer (UC-TRANSFER-001 import, UC-TRANSFER-002 export), as domain, data and di
code with five use cases, so the UI plan (FE-B3) can build kit screen 11 and sheet 12
on it. No UI.

**Architecture:** A new feature `lib/features/transfer/` holds the vocabulary (format,
source, rows of text, the one tags-cell codec, the column mapping, the preview and its
counts), two repository contracts (read or write a file; hand a file to the share
sheet) and five use cases. Its data layer wraps `csv` and `excel` in one data source
each, runs them through `compute`, and wraps `share_plus`. The card feature keeps
every read and write of cards: `CardRepository` gains `foldedPairs`, `importCards` (one
transaction, the duplicate policy applied again inside it, each card written the way
`createCard` writes one) and `exportSnapshot` (one read, ordered, tags sorted).

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35. Added: `csv` ^8.0.0, `excel` ^4.0.6,
`share_plus` ^13.3.0.

**Spec:** [`docs/superpowers/specs/2026-09-26-card-transfer-design.md`](../specs/2026-09-26-card-transfer-design.md),
approved 2026-09-26 with the kit rulings of §8.1 and §8.2, read with the
Clarifications below. Business rules: `docs/features/transfer/rules/`
(BR-TRANSFER-001…BR-TRANSFER-014); use cases: `docs/features/transfer/usecases/`.

**Prerequisite:** branch `claude/lexilize-flashcard-app-lpklbs`, which holds the spec,
its critique and this plan, on `master` at `b69b45c`. Generated code is not committed:
in a fresh working tree, run `flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root `README.md`).

**How this plan was checked:** every code block below was written and run in a scratch
worktree of this branch, task by task. The full gate (`dod_check.sh --force`) passed
there with 1,506 host tests, a clean `flutter analyze`, a clean guard and clean
architecture boundaries; its only reds were files not yet in git and the generated
docs index, which Task 7 regenerates. Rules were then broken on purpose, and each break
failed a test: no duplicate re-check inside the commit, `content_type` set by a batch
that wrote nothing, `;` not escaped in the tags cell, a NUL accepted as UTF-8, no
duplicate-within-source tracking, numbers written as XLSX number cells. One break did
not fail: dropping the explicit `id` tie-break of the export order, because
`idx_card_deck_created (deck_id, created_at, id)` already yields that order (C7).

## Clarifications (amend the spec where they differ)

- **C1 (spec §7).** A database failure is not a `TransferRejection`: it leaves as the
  thrown `Failure` of `mapDatabaseError`, as every other read and write in the app
  does. `commitFailed` and `readFailed` are therefore not enum values; FE-B3 maps a
  thrown `Failure` to the `failed` result (import) and to the read error (export).
- **C2 (spec D7).** Parsing and encoding run through Flutter's `compute`, which uses a
  background isolate on Android and runs inline on the web build that E2E uses
  (`Isolate.run` would throw there). The preview is a plain loop of `CardDraft.check`
  and runs where it is called.
- **C3 (spec §6).** `share_plus` writes the bytes to its own folder in the app's cache
  and clears that folder before each share. That is the private temporary area of
  BR-TRANSFER-014, with no `path_provider` dependency. "Deleted afterwards" becomes
  "cleared before the next share".
- **C4.** `ShareResultStatus.unavailable` means the system took the file but cannot say
  what the user did: it maps to `shared`. `MissingPluginException` and
  `UnimplementedError` map to `shareUnavailable` (E1); any other throw maps to
  `shareFailed` (E2), and its message is never shown.
- **C5 (BR-TRANSFER-013).** The file name is the sanitized deck name with white-space
  runs joined by `-`, then `-yyyy-mm-dd` and the extension: `Nhà-hàng-2026-09-26.csv`.
  The kit's sample `nha-hang-2026-09-16.csv` folds to ASCII, which would turn a Hangul
  deck name into `cards`. FE-B3 records this as a deviation in screen 12's detail file.
- **C6.** `exportSnapshot` answers `notFound` for a missing deck or a stale id.
  `BuildExportUseCase` maps it to `staleSelection` when a selection was asked for, and
  to `emptyScope` for a whole deck (a deck that is gone has nothing to export).
- **C7.** The explicit `ORDER BY created_at, id` stays, though the index already gives
  that order: it keeps BR-TRANSFER-010 true if the query plan changes.
- **C8.** Use case providers live in `presentation/providers/` in this repo, so they
  are FE-B3's, as the search backend left its provider to FE-A10. This plan adds only
  the two repository providers in `transfer/di/`.
- **C9 (scope).** Backend only. FE-B3's plan owns `file_picker`, the import route (spec
  D8, and IT-NAV-012's URL), the screens, the entry points, the kit deviations K1–K4,
  rows 11 and 12 of the screen-handoff index, `docs/README.md` N1 and the UI-base debt
  register.
- **C10 (spec §12).** The repository has no `web/` platform folder yet, so "the gate
  builds web" has nothing to build; both packages list web support for when it is
  added. This container has no Android SDK either, so Task 7 proves the Android build
  with the repository's own `build-apk` workflow (`share_plus` 13 needs minSdk 21;
  the app uses Flutter's default, which is higher).

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme (C9).
- The import map gains `'transfer': {'card'}`: transfer imports only
  `card/domain/{models,repositories,failures}/` (ADR-011 D2, D3).
- The card feature writes and reads cards; transfer never touches `card`, `card_tags`,
  `tags` or `card_schedule` (spec D6). No schema change, no migration.
- Nothing logs card content, pasted text, a file name or a raw row (BR-CORE-002,
  BR-TRANSFER-006). No message carries a path, a file name or an id (BR-CORE-005).
- UTF-8 and UTF-8 with a BOM only; anything else is refused, never guessed
  (BR-TRANSFER-006).
- Exactly six fields, in this order, with lower-case English headers:
  `front · back · example · hint · pronunciation · tags` (BR-TRANSFER-008,
  BR-TRANSFER-012). Tags are separated by `;` through the one codec `TagsCell`
  (BR-TRANSFER-009).
- `csv` is imported only by `delimited_text_data_source.dart`, `excel` only by
  `xlsx_data_source.dart`, `share_plus` only by `export_share_repository_impl.dart`
  (spec D4, D5). Tests may import them to build fixtures.
- Never `DateTime.now()`: the export date is passed in as `today` (BR-TRANSFER-013);
  FE-B3 reads it from `dayClockProvider`.
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing `call`
  (ADR-011 D4). File suffixes follow the guard's naming rules (`_model`, `_repository`,
  `_use_case`, `_failure`, `_data_source`, `_repository_impl`, `_provider`).

## Review Focus

The inputs a person meets first that the spec implies; each is pinned by a test in
the task named.

1. A CSV saved by Excel on Windows as "CSV (Comma delimited)", which is Windows-1252,
   not UTF-8: refused with the encoding reason, never read as mojibake (Task 3, "UTF-16,
   Latin-1 and UTF-16 without a BOM are refused").
2. A deck that changes between Preview and Import (a card added that duplicates every
   row, or a sub-deck created): nothing is written, and the result is `none` or
   `targetRejected` (Task 5).
3. A cell that starts with `=`, or looks like a number (`001`), exported to XLSX and
   opened in a spreadsheet: a text cell, never a formula or a number (Tasks 3 and 6).
4. A tag that contains `;` or `\`: survives export and import unchanged (Tasks 1
   and 6).
5. A 1,500-row file, the kit's sample size: one transaction, one schedule row per card,
   the tag created once (Task 4, "1,500 drafts in one batch").

## File map

| File | Task | Responsibility |
|---|---|---|
| `pubspec.yaml`, `pubspec.lock` | 1 | `csv`, `excel`, `share_plus` |
| `test/architecture/boundary_rules.dart` | 1 | import map entry `'transfer': {'card'}` |
| `lib/features/transfer/domain/models/transfer_format_model.dart` | 1 | CSV/TSV/XLSX, extension, MIME type |
| `lib/features/transfer/domain/models/transfer_source_model.dart` | 1 | a file's bytes and format, or pasted text |
| `lib/features/transfer/domain/models/source_table_model.dart` | 1 | rows of text cells, sheet names |
| `lib/features/transfer/domain/models/tags_cell_model.dart` | 1 | the one tags-cell codec |
| `lib/features/transfer/domain/failures/transfer_failure.dart` | 1 | `TransferRejection` |
| `lib/features/card/domain/models/card_folded_pair_model.dart` | 2 | the duplicate key |
| `lib/features/transfer/domain/models/column_mapping_model.dart` | 2 | fields, auto-map, assign, column letters |
| `lib/features/transfer/domain/models/import_preview_model.dart` | 2 | row statuses, counts, drafts to write |
| `lib/features/transfer/domain/repositories/transfer_file_repository.dart` | 3 | read a source, write rows |
| `lib/features/transfer/data/datasources/delimited_text_data_source.dart` | 3 | strict UTF-8, CSV/TSV through `csv` |
| `lib/features/transfer/data/datasources/xlsx_data_source.dart` | 3 | XLSX through `excel` |
| `lib/features/transfer/data/repositories/transfer_file_repository_impl.dart` | 3 | `compute`, typed reasons |
| `lib/features/card/domain/models/card_import_result_model.dart` | 4 | written, skipped |
| `lib/features/card/domain/models/card_export_snapshot_model.dart` | 4 | deck name, rows |
| `lib/features/card/domain/repositories/card_repository.dart` | 4 | three new methods |
| `lib/features/card/data/datasources/card_dao.dart` | 4 | `foldedPairs`, `exportRows` |
| `lib/features/card/data/repositories/card_repository_impl.dart` | 4 | the three methods, `_insertCard` |
| `lib/features/transfer/domain/models/import_summary_model.dart` | 5 | result counts and kind |
| `lib/features/transfer/domain/usecases/{read_import_source,preview_import,commit_import}_use_case.dart` | 5 | import |
| `lib/features/transfer/domain/models/export_artifact_model.dart` | 6 | artifact, share result, file name |
| `lib/features/transfer/domain/repositories/export_share_repository.dart` | 6 | hand a file to the share sheet |
| `lib/features/transfer/data/repositories/export_share_repository_impl.dart` | 6 | `share_plus` |
| `lib/features/transfer/domain/usecases/{build_export,share_export}_use_case.dart` | 6 | export |
| `lib/features/transfer/di/{transfer_file,export_share}_repository_provider.dart` | 6 | the two repositories |
| `docs/features/transfer/…`, `docs/wbs_BE.md`, `docs/_generated/…` | 7 | documents |

---


### Task 1: Packages, the import map and the transfer vocabulary

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock` (through `flutter pub add`)
- Modify: `test/architecture/boundary_rules.dart`
- Create: `lib/features/transfer/domain/models/transfer_format_model.dart`
- Create: `lib/features/transfer/domain/models/transfer_source_model.dart`
- Create: `lib/features/transfer/domain/models/source_table_model.dart`
- Create: `lib/features/transfer/domain/models/tags_cell_model.dart`
- Create: `lib/features/transfer/domain/failures/transfer_failure.dart`
- Test: `test/features/transfer/domain/tags_cell_model_test.dart`, `test/features/transfer/domain/transfer_format_model_test.dart`

**Interfaces:**
- Produces: `enum TransferFormat { csv, tsv, xlsx }` with `extension`, `mimeType`,
  `static TransferFormat? ofFileName(String)`; `sealed class TransferSource` with
  `FileSource({Uint8List bytes, TransferFormat format})` and `PastedSource(String text)`;
  `SourceTable({List<List<String>> rows, List<String> sheetNames, int sheetIndex})`
  with `columnCount` and `isBlank`; `TagsCell.encode(List<String>) → String`,
  `TagsCell.decode(String) → List<String>`; `enum TransferRejection` (11 values).

- [ ] **Step 0: Add the packages and the import map entry**

```bash
flutter pub add csv:^8.0.0 excel:^4.0.6 share_plus:^13.3.0
```

Expected: `pubspec.yaml` lists `csv: ^8.0.0`, `excel: ^4.0.6` and `share_plus: ^13.3.0` under `dependencies`.

`test/architecture/boundary_rules.dart` (apply this diff):

```diff
diff --git a/test/architecture/boundary_rules.dart b/test/architecture/boundary_rules.dart
index b4ecda9..7a3bd92 100644
--- a/test/architecture/boundary_rules.dart
+++ b/test/architecture/boundary_rules.dart
@@ -26,6 +26,7 @@ const allowedFeatureImports = <String, Set<String>>{
   'study': {'study_mode', 'srs', 'settings', 'card'},
   'progress': {},
   'search': {'deck'},
+  'transfer': {'card'},
 };
 
 const _package = 'package:memox/';
```

- [ ] **Step 1: Write the failing tests**

`test/features/transfer/domain/tags_cell_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/tags_cell_model.dart';

void main() {
  test(
    'tags join with ; and escape ; and \\ inside a tag (BR-TRANSFER-009)',
    () {
      expect(TagsCell.encode(['a', 'b;c', r'd\e']), r'a;b\;c;d\\e');
      expect(TagsCell.encode(const []), '');
    },
  );

  test(
    'decoding restores the spelling and the set of tags (BR-TRANSFER-009)',
    () {
      const tags = ['TOPIK', 'a;b', r'c\d', r'e\;f', 'g h'];
      expect(TagsCell.decode(TagsCell.encode(tags)), tags);
    },
  );

  test('a backslash before another character or at the end stays verbatim', () {
    expect(TagsCell.decode(r'a\b;c\'), [r'a\b', r'c\']);
  });

  test('tags are trimmed and blank ones dropped', () {
    expect(TagsCell.decode(' a ;; b ;'), ['a', 'b']);
    expect(TagsCell.decode('   '), isEmpty);
  });
}
```

`test/features/transfer/domain/transfer_format_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

void main() {
  test('a file name ends in the format it is read as, ignoring case (E1)', () {
    expect(TransferFormat.ofFileName('vocab.XLSX'), TransferFormat.xlsx);
    expect(TransferFormat.ofFileName('a.b.tsv'), TransferFormat.tsv);
    expect(TransferFormat.ofFileName('deck.apkg'), isNull);
    expect(TransferFormat.ofFileName('noextension'), isNull);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/domain/tags_cell_model_test.dart test/features/transfer/domain/transfer_format_model_test.dart`
Expected: FAIL to load: `tags_cell_model.dart` and `transfer_format_model.dart` do not exist.

- [ ] **Step 3: Write the implementation**

`lib/features/transfer/domain/models/transfer_format_model.dart`:

```dart
/// The three file formats Card Transfer reads and writes (UC-TRANSFER-001,
/// UC-TRANSFER-002).
enum TransferFormat {
  csv('csv', 'text/csv'),
  tsv('tsv', 'text/tab-separated-values'),
  xlsx(
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const TransferFormat(this.extension, this.mimeType);

  /// Without the dot, lower case.
  final String extension;
  final String mimeType;

  /// The format a file name ends with, ignoring case; null for any other
  /// extension (UC-TRANSFER-001 E1).
  static TransferFormat? ofFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final extension = fileName.substring(dot + 1).toLowerCase();
    for (final format in values) {
      if (format.extension == extension) return format;
    }
    return null;
  }
}
```

`lib/features/transfer/domain/models/transfer_source_model.dart`:

```dart
import 'dart:typed_data';

import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// What the user hands to an import: a file, or text pasted in the app
/// (UC-TRANSFER-001 step 2, A1). The file's name is never kept: only its
/// format (BR-TRANSFER-006).
sealed class TransferSource {
  const TransferSource();
}

final class FileSource extends TransferSource {
  const FileSource({required this.bytes, required this.format});

  final Uint8List bytes;
  final TransferFormat format;
}

final class PastedSource extends TransferSource {
  const PastedSource(this.text);

  final String text;
}
```

`lib/features/transfer/domain/models/source_table_model.dart`:

```dart
/// A source read into rows of text cells, before any mapping
/// (UC-TRANSFER-001 steps 3–4). Rows keep their order and their blank rows,
/// so a row's number is its index plus one.
final class SourceTable {
  const SourceTable({
    required this.rows,
    this.sheetNames = const [],
    this.sheetIndex = 0,
  });

  /// Every row as read, a header row included; every cell as text.
  final List<List<String>> rows;

  /// The sheets of an XLSX workbook, in workbook order; empty for CSV, TSV
  /// and pasted text (UC-TRANSFER-001 A2).
  final List<String> sheetNames;

  /// Which of [sheetNames] [rows] came from.
  final int sheetIndex;

  /// The width of the widest row.
  int get columnCount =>
      rows.fold(0, (widest, row) => row.length > widest ? row.length : widest);

  /// Whether no cell holds anything but white space (UC-TRANSFER-001 E2).
  bool get isBlank => rows.every((row) => row.every(_isBlankCell));
}

bool _isBlankCell(String cell) => cell.trim().isEmpty;
```

`lib/features/transfer/domain/models/tags_cell_model.dart`:

```dart
/// The one codec for the `tags` cell, shared by import and export
/// (BR-TRANSFER-009): tags joined by `;`, a `;` inside a tag written `\;`
/// and a `\` written `\\`.
abstract final class TagsCell {
  static const separator = ';';
  static const _escape = r'\';

  static String encode(List<String> tags) => tags
      .map(
        (tag) => tag
            .replaceAll(_escape, '$_escape$_escape')
            .replaceAll(separator, '$_escape$separator'),
      )
      .join(separator);

  /// A backslash escapes only a `;` or a `\` right after it; before any
  /// other character, or at the end of the cell, it is kept as written,
  /// since legacy sources never escaped. Each tag is trimmed; blank ones
  /// are dropped.
  static List<String> decode(String cell) {
    final tags = <String>[];
    final current = StringBuffer();
    for (var i = 0; i < cell.length; i++) {
      final char = cell[i];
      final next = i + 1 < cell.length ? cell[i + 1] : null;
      if (char == _escape && (next == separator || next == _escape)) {
        current.write(next);
        i++;
        continue;
      }
      if (char == separator) {
        tags.add(current.toString());
        current.clear();
        continue;
      }
      current.write(char);
    }
    tags.add(current.toString());
    return [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
  }
}
```

`lib/features/transfer/domain/failures/transfer_failure.dart`:

```dart
/// Why Card Transfer refuses a step (ADR-011 D6). A database failure is not
/// a reason here: it leaves as the thrown `Failure`, as every other write
/// and read does.
enum TransferRejection {
  /// UC-TRANSFER-001 E1: a file that is not CSV, TSV or XLSX, or that cannot
  /// be read (damaged, protected).
  unreadableFile,

  /// BR-TRANSFER-006: text that is not UTF-8 or UTF-8 with a BOM.
  badEncoding,

  /// UC-TRANSFER-001 E2: no row holds anything.
  emptySource,

  /// BR-TRANSFER-002: `front` or `back` is not mapped, or two columns map to
  /// one field.
  mappingIncomplete,

  /// UC-TRANSFER-001 E3: under the chosen duplicate policy, no row would be
  /// written.
  nothingToImport,

  /// BR-TRANSFER-001, UC-TRANSFER-001 E4: the deck is gone, is a root, or
  /// holds sub-decks.
  targetRejected,

  /// BR-TRANSFER-007, UC-TRANSFER-002 E5: nothing to export.
  emptyScope,

  /// BR-TRANSFER-007, UC-TRANSFER-002 E6: a chosen card is gone or has moved.
  staleSelection,

  /// UC-TRANSFER-002 E4: the file could not be written.
  encodeFailed,

  /// UC-TRANSFER-002 E1: this device has no share sheet.
  shareUnavailable,

  /// UC-TRANSFER-002 E2: the platform failed while sharing.
  shareFailed,
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/transfer/domain/tags_cell_model_test.dart test/features/transfer/domain/transfer_format_model_test.dart test/architecture`
Expected: PASS, every test, the boundary tests included.
Then run `dart format lib test` and `flutter analyze`: no issues.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock test/architecture/boundary_rules.dart lib/features/transfer test/features/transfer
git commit -m "feat(transfer): packages, import map and the transfer vocabulary (BE-B3)"
```

### Task 2: Column mapping and the import preview

**Files:**
- Create: `lib/features/card/domain/models/card_folded_pair_model.dart`
- Create: `lib/features/transfer/domain/models/column_mapping_model.dart`
- Create: `lib/features/transfer/domain/models/import_preview_model.dart`
- Test: `test/features/transfer/domain/column_mapping_model_test.dart`, `test/features/transfer/domain/import_preview_model_test.dart`

**Interfaces:**
- Consumes: `SourceTable`, `TagsCell` (Task 1); `CardDraft.check()` and
  `CardRejection` (card feature, unchanged).
- Produces: `typedef CardFoldedPair = ({String front, String back})`;
  `enum TransferField { front, back, example, hint, pronunciation, tags }` with
  `header`; `ColumnMapping(Map<int, TransferField>)`, `ColumnMapping.fromHeader(
  List<String>)`, `assign(int, TransferField?)`, `columnOf(TransferField)`,
  `isComplete`; `String columnLetter(int)`; `enum ImportRowKind { ready, invalid,
  duplicateInDeck, duplicateInSource, blank }`; `ImportRow`; `ImportPreview` with
  `total`, `ready`, `invalid`, `blank`, `duplicates`, `isEmpty`,
  `willWrite({required bool includeDuplicates})`, `draftsToWrite({required bool
  includeDuplicates})`; `ImportPreview buildImportPreview({SourceTable table,
  ColumnMapping mapping, bool hasHeaderRow, Set<CardFoldedPair> existing})`.

The preview decides each data row's status in this order: blank (every mapped cell empty after trim), invalid (the first `CardDraft` rule that fails, in form order), duplicate of a card in the deck, duplicate of an earlier *valid* row, ready. An invalid row never registers a key, so it cannot make a later valid row a duplicate.


- [ ] **Step 1: Write the failing tests**

`test/features/transfer/domain/column_mapping_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';

void main() {
  test('a header equal to a canonical name after the fold maps to it (UC-TRANSFER-001 step 4)', () {
    final mapping = ColumnMapping.fromHeader([
      ' Front',
      'BACK',
      'notes',
      'Tags',
    ]);

    expect(mapping.fieldByColumn, {
      0: TransferField.front,
      1: TransferField.back,
      3: TransferField.tags,
    });
    expect(mapping.isComplete, isTrue);
  });

  test('nothing else is guessed: term and meaning stay unmapped', () {
    final mapping = ColumnMapping.fromHeader(['term', 'meaning']);

    expect(mapping.fieldByColumn, isEmpty);
    expect(mapping.isComplete, isFalse);
  });

  test('the first column wins a field named twice', () {
    expect(ColumnMapping.fromHeader(['front', 'front', 'back']).fieldByColumn, {
      0: TransferField.front,
      2: TransferField.back,
    });
  });

  test('a field takes one column: assigning it elsewhere moves it (BR-TRANSFER-002)', () {
    final mapping = ColumnMapping.fromHeader(['front', 'back', 'x'])
        .assign(2, TransferField.back);

    expect(mapping.fieldByColumn, {
      0: TransferField.front,
      2: TransferField.back,
    });
    expect(mapping.assign(0, null).isComplete, isFalse);
  });

  test(
    'columns are named A, B … Z, AA, AB when the first row is data (A3)',
    () {
      expect([0, 1, 25, 26, 27, 51, 52].map(columnLetter), [
        'A',
        'B',
        'Z',
        'AA',
        'AB',
        'AZ',
        'BA',
      ]);
    },
  );
}
```

`test/features/transfer/domain/import_preview_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

ImportPreview _preview(
  List<List<String>> rows, {
  bool hasHeaderRow = true,
  Set<({String front, String back})> existing = const {},
}) => buildImportPreview(
  table: SourceTable(rows: rows),
  mapping: hasHeaderRow
      ? ColumnMapping.fromHeader(rows.first)
      : const ColumnMapping({0: TransferField.front, 1: TransferField.back}),
  hasHeaderRow: hasHeaderRow,
  existing: existing,
);

void main() {
  test('each row gets one status, in order (UC-TRANSFER-001 step 5)', () {
    final preview = _preview(
      [
        ['front', 'back', 'tags'],
        ['menu', 'thực đơn', 'food; noun'],
        ['bill', '', ''],
        ['Reservation', 'Sự đặt chỗ', ''],
        ['', '  ', ''],
        ['menu ', ' Thực đơn', ''],
        ['a' * 61, 'too long', ''],
      ],
      existing: {(front: 'reservation', back: 'sự đặt chỗ')},
    );

    expect(preview.rows.map((row) => (row.rowNumber, row.kind)), [
      (2, ImportRowKind.ready),
      (3, ImportRowKind.invalid),
      (4, ImportRowKind.duplicateInDeck),
      (5, ImportRowKind.blank),
      (6, ImportRowKind.duplicateInSource),
      (7, ImportRowKind.invalid),
    ]);
    expect(preview.rows[1].reason, CardRejection.blankContent);
    expect(preview.rows[4].firstRowNumber, 2);
    expect(preview.rows[5].reason, CardRejection.frontTooLong);
    expect(preview.rows[0].draft!.tagNames, ['food', 'noun']);
    expect(
      (
        preview.total,
        preview.ready,
        preview.invalid,
        preview.duplicates,
        preview.blank,
      ),
      (6, 1, 2, 2, 1),
    );
  });

  test('duplicates are skipped by default and written with Include duplicates (A4)', () {
    final preview = _preview([
      ['front', 'back'],
      ['a', 'b'],
      ['A', 'B'],
    ]);

    expect(preview.willWrite(includeDuplicates: false), 1);
    expect(preview.willWrite(includeDuplicates: true), 2);
    expect(
      preview
          .draftsToWrite(includeDuplicates: true)
          .map((draft) => draft.front),
      ['a', 'A'],
    );
  });

  test('an invalid row never shadows a later valid one as its duplicate', () {
    final preview = _preview([
      ['front', 'back', 'tags'],
      ['a', 'b', List.filled(11, 't').indexed.map((e) => 't${e.$1}').join(';')],
      ['a', 'b', ''],
    ]);

    expect(preview.rows.map((row) => row.kind), [
      ImportRowKind.invalid,
      ImportRowKind.ready,
    ]);
    expect(preview.rows.first.reason, CardRejection.tooManyTags);
  });

  test('without a header row the first row is data (A3)', () {
    final preview = _preview([
      ['a', 'b'],
      ['c', 'd'],
    ], hasHeaderRow: false);

    expect(preview.rows.map((row) => row.rowNumber), [1, 2]);
    expect(preview.ready, 2);
  });

  test('a source whose data rows are all blank is empty (E2)', () {
    expect(
      _preview([
        ['front', 'back'],
        ['', ''],
      ]).isEmpty,
      isTrue,
    );
    expect(
      _preview([
        ['front', 'back'],
      ]).isEmpty,
      isTrue,
    );
  });

  test('a short row reads its missing cells as empty', () {
    final preview = _preview([
      ['front', 'back', 'hint'],
      ['a', 'b'],
    ]);

    expect(preview.rows.single.kind, ImportRowKind.ready);
    expect(preview.rows.single.draft!.hint, isNull);
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/domain/column_mapping_model_test.dart test/features/transfer/domain/import_preview_model_test.dart`
Expected: FAIL to load: a file under `lib/` that the tests import, or a method they call, does not exist yet.

- [ ] **Step 3: Write the implementation**

`lib/features/card/domain/models/card_folded_pair_model.dart`:

```dart
/// A card's two faces as `front_folded` and `back_folded` hold them
/// (schema.md): the key that tells a duplicate on import (BR-TRANSFER-003).
typedef CardFoldedPair = ({String front, String back});
```

`lib/features/transfer/domain/models/column_mapping_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';

/// The six content fields a transfer file carries, in file order, each named
/// by its canonical header (BR-TRANSFER-008, BR-TRANSFER-012).
enum TransferField {
  front,
  back,
  example,
  hint,
  pronunciation,
  tags;

  /// The canonical header: the name itself, lower case English, never
  /// localized.
  String get header => name;
}

/// Which source column feeds which field (UC-TRANSFER-001 step 4). A column
/// feeds at most one field and a field takes at most one column
/// (BR-TRANSFER-002).
final class ColumnMapping {
  const ColumnMapping(this.fieldByColumn);

  /// A header cell equal to a canonical header after [foldText] maps to that
  /// field; the first column wins a field. Nothing else is guessed.
  factory ColumnMapping.fromHeader(List<String> header) {
    final fieldByColumn = <int, TransferField>{};
    for (var column = 0; column < header.length; column++) {
      final folded = foldText(header[column]);
      for (final field in TransferField.values) {
        if (field.header != folded) continue;
        if (fieldByColumn.containsValue(field)) continue;
        fieldByColumn[column] = field;
      }
    }
    return ColumnMapping(fieldByColumn);
  }

  final Map<int, TransferField> fieldByColumn;

  /// Maps [column] to [field], or leaves it unmapped when [field] is null. A
  /// field moved here leaves the column that had it.
  ColumnMapping assign(int column, TransferField? field) {
    final next = {
      for (final entry in fieldByColumn.entries)
        if (entry.key != column && entry.value != field) entry.key: entry.value,
    };
    if (field != null) next[column] = field;
    return ColumnMapping(next);
  }

  int? columnOf(TransferField field) {
    for (final entry in fieldByColumn.entries) {
      if (entry.value == field) return entry.key;
    }
    return null;
  }

  /// Whether both faces are mapped (BR-TRANSFER-002).
  bool get isComplete =>
      columnOf(TransferField.front) != null &&
      columnOf(TransferField.back) != null;
}

/// The position name of a column when the first row is not a header
/// (UC-TRANSFER-001 A3): A…Z, then AA, AB….
String columnLetter(int column) {
  const letters = 26;
  final codeOfA = 'A'.codeUnitAt(0);
  final name = <String>[];
  for (var rest = column + 1; rest > 0; rest = (rest - 1) ~/ letters) {
    name.insert(0, String.fromCharCode(codeOfA + (rest - 1) % letters));
  }
  return name.join();
}
```

`lib/features/transfer/domain/models/import_preview_model.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/tags_cell_model.dart';

/// What the preview decided for one data row (UC-TRANSFER-001 step 5).
enum ImportRowKind { ready, invalid, duplicateInDeck, duplicateInSource, blank }

final class ImportRow {
  const ImportRow({
    required this.rowNumber,
    required this.kind,
    this.draft,
    this.reason,
    this.firstRowNumber,
  });

  /// The row's number in the source, the header row counted.
  final int rowNumber;
  final ImportRowKind kind;

  /// Null only for a blank row.
  final CardDraft? draft;

  /// Why an invalid row is refused: the first failing card rule.
  final CardRejection? reason;

  /// For a duplicate within the source: the row it repeats.
  final int? firstRowNumber;

  bool get isDuplicate =>
      kind == ImportRowKind.duplicateInDeck ||
      kind == ImportRowKind.duplicateInSource;
}

/// Every data row with its status, and the counts the preview shows. It
/// writes nothing (BR-TRANSFER-006).
final class ImportPreview {
  const ImportPreview(this.rows);

  final List<ImportRow> rows;

  int get total => rows.length;
  int get ready => _count(ImportRowKind.ready);
  int get invalid => _count(ImportRowKind.invalid);
  int get blank => _count(ImportRowKind.blank);
  int get duplicates => rows.where((row) => row.isDuplicate).length;

  /// Whether no data row holds anything (UC-TRANSFER-001 E2).
  bool get isEmpty => blank == total;

  /// "Include duplicates" writes both duplicate kinds as new cards (A4).
  int willWrite({required bool includeDuplicates}) =>
      ready + (includeDuplicates ? duplicates : 0);

  /// The drafts a commit hands to the card feature, in source order.
  List<CardDraft> draftsToWrite({required bool includeDuplicates}) => [
    for (final row in rows)
      if (row.kind == ImportRowKind.ready ||
          (includeDuplicates && row.isDuplicate))
        row.draft!,
  ];

  int _count(ImportRowKind kind) =>
      rows.where((row) => row.kind == kind).length;
}

/// Decides each data row's status in order: blank, invalid, duplicate of a
/// card in the deck ([existing]), duplicate of an earlier valid row, ready
/// (BR-TRANSFER-002, BR-TRANSFER-003). The mapping must be complete.
ImportPreview buildImportPreview({
  required SourceTable table,
  required ColumnMapping mapping,
  required bool hasHeaderRow,
  required Set<CardFoldedPair> existing,
}) {
  final firstRowOf = <CardFoldedPair, int>{};
  final rows = <ImportRow>[];
  final firstDataRow = hasHeaderRow ? 1 : 0;
  for (var index = firstDataRow; index < table.rows.length; index++) {
    final rowNumber = index + 1;
    final cells = table.rows[index];
    String? cell(TransferField field) {
      final column = mapping.columnOf(field);
      if (column == null || column >= cells.length) return null;
      return cells[column];
    }

    final mapped = [for (final field in TransferField.values) cell(field)];
    if (mapped.every((value) => value == null || value.trim().isEmpty)) {
      rows.add(ImportRow(rowNumber: rowNumber, kind: ImportRowKind.blank));
      continue;
    }
    final draft = CardDraft(
      front: cell(TransferField.front) ?? '',
      back: cell(TransferField.back) ?? '',
      example: cell(TransferField.example),
      hint: cell(TransferField.hint),
      pronunciation: cell(TransferField.pronunciation),
      tagNames: TagsCell.decode(cell(TransferField.tags) ?? ''),
    );
    if (draft.check() case Rejected(:final reason)) {
      rows.add(
        ImportRow(
          rowNumber: rowNumber,
          kind: ImportRowKind.invalid,
          draft: draft,
          reason: reason,
        ),
      );
      continue;
    }
    final pair = (front: foldText(draft.front), back: foldText(draft.back));
    if (existing.contains(pair)) {
      rows.add(
        ImportRow(
          rowNumber: rowNumber,
          kind: ImportRowKind.duplicateInDeck,
          draft: draft,
        ),
      );
      continue;
    }
    final firstRowNumber = firstRowOf[pair];
    if (firstRowNumber != null) {
      rows.add(
        ImportRow(
          rowNumber: rowNumber,
          kind: ImportRowKind.duplicateInSource,
          draft: draft,
          firstRowNumber: firstRowNumber,
        ),
      );
      continue;
    }
    firstRowOf[pair] = rowNumber;
    rows.add(
      ImportRow(rowNumber: rowNumber, kind: ImportRowKind.ready, draft: draft),
    );
  }
  return ImportPreview(rows);
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/transfer/domain/column_mapping_model_test.dart test/features/transfer/domain/import_preview_model_test.dart`
Expected: PASS, every test.
Then run `dart format lib test` and `flutter analyze`: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card/domain/models/card_folded_pair_model.dart lib/features/transfer test/features/transfer
git commit -m "feat(transfer): column mapping and the import preview (BR-TRANSFER-002, BR-TRANSFER-003)"
```

### Task 3: Reading and writing files

**Files:**
- Create: `lib/features/transfer/domain/repositories/transfer_file_repository.dart`
- Create: `lib/features/transfer/data/datasources/delimited_text_data_source.dart`
- Create: `lib/features/transfer/data/datasources/xlsx_data_source.dart`
- Create: `lib/features/transfer/data/repositories/transfer_file_repository_impl.dart`
- Test: `test/features/transfer/data/transfer_file_repository_impl_test.dart`

**Interfaces:**
- Consumes: `TransferSource`, `SourceTable`, `TransferFormat`, `TransferRejection`
  (Task 1).
- Produces: `TransferFileRepository.read(TransferSource, {int? sheetIndex}) →
  Future<Outcome<SourceTable, TransferRejection>>` (`badEncoding`,
  `unreadableFile`, `emptySource`) and `write(List<List<String>> rows,
  TransferFormat) → Future<Outcome<Uint8List, TransferRejection>>`
  (`encodeFailed`); `const TransferFileRepositoryImpl()`.

Facts about the packages that this code relies on, checked in the scratch run:
- `Csv(autoDetect: false, skipEmptyLines: false).decode` keeps a blank line as the row `['']`, handles quotes, CRLF and embedded newlines, and returns strings while `dynamicTyping` is false (the default). `Csv(addBom: true)` starts the text with U+FEFF and ends lines with CRLF.
- `Excel.decodeBytes(...).tables` lists the sheets in workbook order, empty sheets included; a stored `2.0` reads back as `IntCellValue(2)`; an absent cell is `null` or a `Data` whose `value` is `null`. A `TextCellValue` is written as a string cell, so `=1+1` never becomes a formula.
- A test workbook must touch `workbook[name]` before appending rows, or an empty sheet is never created.


- [ ] **Step 1: Write the failing tests**

`test/features/transfer/data/transfer_file_repository_impl_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

const _files = TransferFileRepositoryImpl();

Uint8List _utf8(String text) => Uint8List.fromList(utf8.encode(text));

Future<SourceTable> _table(TransferSource source, {int? sheetIndex}) async {
  final result = await _files.read(source, sheetIndex: sheetIndex);
  return (result as Ok<SourceTable, TransferRejection>).value;
}

Future<TransferRejection> _refusal(TransferSource source) async {
  final result = await _files.read(source);
  return (result as Rejected<SourceTable, TransferRejection>).reason;
}

Future<Uint8List> _written(
  List<List<String>> rows,
  TransferFormat format,
) async {
  final result = await _files.write(rows, format);
  return (result as Ok<Uint8List, TransferRejection>).value;
}

Uint8List _workbook(Map<String, List<List<CellValue?>>> sheets) {
  final workbook = Excel.createExcel();
  final first = workbook.getDefaultSheet()!;
  sheets.forEach((name, rows) {
    final sheet = workbook[name];
    for (final row in rows) {
      sheet.appendRow(row);
    }
  });
  if (!sheets.containsKey(first)) workbook.delete(first);
  return Uint8List.fromList(workbook.encode()!);
}

void main() {
  group('CSV and TSV (BR-TRANSFER-006)', () {
    test(
      'quotes, delimiters and line breaks inside a cell, CRLF and a BOM',
      () async {
        final table = await _table(
          FileSource(
            bytes: _utf8('﻿front,back\r\n"a,b","c\nd"\r\n"say ""hi""",e\r\n'),
            format: TransferFormat.csv,
          ),
        );

        expect(table.rows, [
          ['front', 'back'],
          ['a,b', 'c\nd'],
          ['say "hi"', 'e'],
        ]);
      },
    );

    test('a blank line stays a row, so row numbers match the file', () async {
      final table = await _table(
        FileSource(
          bytes: _utf8('front,back\n\na,b\n'),
          format: TransferFormat.csv,
        ),
      );

      expect(table.rows, [
        ['front', 'back'],
        [''],
        ['a', 'b'],
      ]);
    });

    test('TSV splits on tabs only', () async {
      final table = await _table(
        FileSource(
          bytes: _utf8('front\tback\na, b\tc'),
          format: TransferFormat.tsv,
        ),
      );

      expect(table.rows.last, ['a, b', 'c']);
    });

    test(
      'UTF-16, Latin-1 and UTF-16 without a BOM are refused, never guessed',
      () async {
        final utf16 = Uint8List.fromList([0xFF, 0xFE, 0x61, 0x00, 0x2C, 0x00]);
        final latin1 = Uint8List.fromList([0x63, 0x61, 0x66, 0xE9, 0x2C, 0x62]);
        final utf16NoBom = Uint8List.fromList([
          0x61,
          0x00,
          0x2C,
          0x00,
          0x62,
          0x00,
        ]);

        for (final bytes in [utf16, latin1, utf16NoBom]) {
          expect(
            await _refusal(
              FileSource(bytes: bytes, format: TransferFormat.csv),
            ),
            TransferRejection.badEncoding,
          );
        }
      },
    );

    test(
      'pasted text is tab-separated when its first line has a tab (A1)',
      () async {
        expect((await _table(const PastedSource('a\tb,c\nd\te'))).rows, [
          ['a', 'b,c'],
          ['d', 'e'],
        ]);
        expect((await _table(const PastedSource('a,b\nc,d'))).rows.last, [
          'c',
          'd',
        ]);
      },
    );

    test('a source with nothing in it is empty (E2)', () async {
      expect(
        await _refusal(const PastedSource(' \n , \n')),
        TransferRejection.emptySource,
      );
      expect(
        await _refusal(
          FileSource(bytes: Uint8List(0), format: TransferFormat.csv),
        ),
        TransferRejection.emptySource,
      );
    });
  });

  group('XLSX', () {
    test('the first sheet that holds anything is chosen, and any sheet can be (A2)', () async {
      final bytes = _workbook({
        'Notes': [],
        'Vocab': [
          [TextCellValue('front'), TextCellValue('back')],
          [TextCellValue('menu'), TextCellValue('thực đơn')],
        ],
        'Other': [
          [TextCellValue('x')],
        ],
      });

      final table = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect(table.sheetNames, ['Notes', 'Vocab', 'Other']);
      expect(table.sheetIndex, 1);
      expect(table.rows.last, ['menu', 'thực đơn']);

      final other = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
        sheetIndex: 2,
      );
      expect(other.rows, [
        ['x'],
      ]);
    });

    test('numbers and dates read as text', () async {
      final bytes = _workbook({
        'Sheet1': [
          [
            const IntCellValue(7),
            const DoubleCellValue(2.0),
            const DoubleCellValue(2.5),
            const DateCellValue(year: 2026, month: 9, day: 1),
            null,
          ],
        ],
      });

      final table = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect(table.rows.single, ['7', '2', '2.5', '2026-09-01', '']);
    });

    test('bytes that are not a workbook are unreadable (E1)', () async {
      expect(
        await _refusal(
          FileSource(bytes: _utf8('front,back'), format: TransferFormat.xlsx),
        ),
        TransferRejection.unreadableFile,
      );
    });
  });

  group('writing (BR-TRANSFER-010, BR-TRANSFER-012)', () {
    const rows = [
      ['front', 'back', 'example', 'hint', 'pronunciation', 'tags'],
      ['=1+1', '001', '', '', '', r'a\;b;c'],
      ['say "hi"', 'x,y\nz', '', '', '', ''],
    ];

    test('CSV and TSV start with a BOM, and read back as written', () async {
      for (final format in [TransferFormat.csv, TransferFormat.tsv]) {
        final bytes = await _written(rows, format);

        expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
        expect(
          (await _table(FileSource(bytes: bytes, format: format))).rows,
          rows,
        );
      }
    });

    test('the same rows give the same CSV bytes', () async {
      expect(
        await _written(rows, TransferFormat.csv),
        await _written(rows, TransferFormat.csv),
      );
    });

    test('XLSX writes text cells: no formula, no number, and reads back as written', () async {
      final bytes = await _written(rows, TransferFormat.xlsx);
      final sheet = Excel.decodeBytes(bytes).tables.values.single;

      expect(sheet.rows[1][0]!.value, isA<TextCellValue>());
      expect(sheet.rows[1][1]!.value, isA<TextCellValue>());
      expect(
        (await _table(FileSource(bytes: bytes, format: TransferFormat.xlsx)))
            .rows,
        rows,
      );
    });
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/data/transfer_file_repository_impl_test.dart`
Expected: FAIL to load: a file under `lib/` that the tests import, or a method they call, does not exist yet.

- [ ] **Step 3: Write the implementation**

`lib/features/transfer/domain/repositories/transfer_file_repository.dart`:

```dart
import 'dart:typed_data';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';

/// Reads a source into rows of text and writes rows into a file. The one
/// implementation is `TransferFileRepositoryImpl` (data layer); the contract
/// exists for ADR-010's reason: domain stays free of the codec packages, and
/// tests substitute a fake. Nothing here logs content (BR-TRANSFER-006).
abstract interface class TransferFileRepository {
  /// UC-TRANSFER-001 steps 3–4, E1: [sheetIndex] picks a sheet of an XLSX;
  /// null picks the first sheet that holds anything (A2).
  Future<Outcome<SourceTable, TransferRejection>> read(
    TransferSource source, {
    int? sheetIndex,
  });

  /// UC-TRANSFER-002 step 5 (BR-TRANSFER-012): [rows] as a file of [format].
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  );
}
```

`lib/features/transfer/data/datasources/delimited_text_data_source.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';

/// CSV and TSV through the `csv` package, and the strict UTF-8 reading
/// BR-TRANSFER-006 asks for. The only file that imports `csv`.
final class DelimitedTextDataSource {
  const DelimitedTextDataSource();

  static const comma = ',';
  static const tab = '\t';
  static const _byteOrderMark = [0xEF, 0xBB, 0xBF];
  static const _nul = '\u0000';

  /// The text of [bytes] read as UTF-8, a leading BOM dropped. Throws
  /// [FormatException] for anything that is not UTF-8, and for a NUL, which
  /// UTF-8 text never holds but UTF-16 without a BOM does.
  String decodeUtf8(Uint8List bytes) {
    final hasByteOrderMark =
        bytes.length >= _byteOrderMark.length &&
        bytes[0] == _byteOrderMark[0] &&
        bytes[1] == _byteOrderMark[1] &&
        bytes[2] == _byteOrderMark[2];
    final text = utf8.decode(
      hasByteOrderMark ? bytes.sublist(_byteOrderMark.length) : bytes,
    );
    if (text.contains(_nul)) throw const FormatException('not UTF-8');
    return text;
  }

  /// Pasted text is tab-separated when its first line has a tab, else
  /// comma-separated (UC-TRANSFER-001 A1).
  String delimiterOfPasted(String text) {
    final firstLineEnd = text.indexOf('\n');
    final firstLine = firstLineEnd < 0 ? text : text.substring(0, firstLineEnd);
    return firstLine.contains(tab) ? tab : comma;
  }

  /// Every row, blank ones kept so row numbers match the source.
  List<List<String>> parse(String text, String delimiter) {
    final withoutByteOrderMark = text.startsWith('﻿')
        ? text.substring(1)
        : text;
    final rows = Csv(
      fieldDelimiter: delimiter,
      autoDetect: false,
      skipEmptyLines: false,
    ).decode(withoutByteOrderMark);
    return [
      for (final row in rows) [for (final cell in row) '$cell'],
    ];
  }

  /// UTF-8 with a BOM, CRLF line ends, fields quoted when needed
  /// (BR-TRANSFER-012).
  Uint8List encode(List<List<String>> rows, String delimiter) =>
      utf8.encode(Csv(fieldDelimiter: delimiter, addBom: true).encode(rows));
}
```

`lib/features/transfer/data/datasources/xlsx_data_source.dart`:

```dart
import 'dart:typed_data';

import 'package:excel/excel.dart';

/// XLSX through the `excel` package: the only file that imports it (spec
/// D4). Should the package break, this file is the whole replacement.
final class XlsxDataSource {
  const XlsxDataSource();

  static const exportSheetName = 'cards';

  /// The workbook's sheet names in order, and the rows of the sheet at
  /// [sheetIndex], or of the first sheet that holds anything when it is null
  /// (UC-TRANSFER-001 A2). Every cell reads as text. Throws when the bytes
  /// are not a readable workbook.
  ({List<String> sheetNames, int sheetIndex, List<List<String>> rows}) read(
    Uint8List bytes, {
    int? sheetIndex,
  }) {
    final sheets = Excel.decodeBytes(bytes).tables;
    final sheetNames = sheets.keys.toList();
    final tables = [
      for (final name in sheetNames)
        [
          for (final row in sheets[name]!.rows)
            [for (final cell in row) _textOf(cell?.value)],
        ],
    ];
    final chosen = sheetIndex ?? _firstFilled(tables) ?? 0;
    return (
      sheetNames: sheetNames,
      sheetIndex: chosen,
      rows: chosen < tables.length ? tables[chosen] : const [],
    );
  }

  /// One sheet whose every cell is a text cell, so `=`, `+`, `-` and `@`
  /// never start a formula and `001` stays `001` (BR-TRANSFER-012).
  Uint8List write(List<List<String>> rows) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet()!;
    workbook.rename(defaultSheet, exportSheetName);
    final sheet = workbook[exportSheetName];
    for (final row in rows) {
      sheet.appendRow([for (final cell in row) TextCellValue(cell)]);
    }
    final bytes = workbook.encode();
    if (bytes == null) throw StateError('workbook not encoded');
    return Uint8List.fromList(bytes);
  }

  int? _firstFilled(List<List<List<String>>> tables) {
    for (var index = 0; index < tables.length; index++) {
      final filled = tables[index].any(
        (row) => row.any((cell) => cell.trim().isNotEmpty),
      );
      if (filled) return index;
    }
    return null;
  }
}

/// A date as `yyyy-mm-dd`; a whole number without a decimal point; any other
/// value as the package prints it.
String _textOf(CellValue? value) => switch (value) {
  null => '',
  DateCellValue(:final year, :final month, :final day) =>
    '${_digits(year, 4)}-${_digits(month, 2)}-${_digits(day, 2)}',
  DoubleCellValue(:final value) when value == value.truncateToDouble() =>
    value.toInt().toString(),
  _ => value.toString(),
};

String _digits(int value, int width) => value.toString().padLeft(width, '0');
```

`lib/features/transfer/data/repositories/transfer_file_repository_impl.dart`:

```dart
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/datasources/delimited_text_data_source.dart';
import 'package:memox/features/transfer/data/datasources/xlsx_data_source.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// Reading and writing run off the UI isolate through [compute], which runs
/// them inline on the web build E2E uses (spec D7, ADR-001).
final class TransferFileRepositoryImpl implements TransferFileRepository {
  const TransferFileRepositoryImpl();

  @override
  Future<Outcome<SourceTable, TransferRejection>> read(
    TransferSource source, {
    int? sheetIndex,
  }) => compute(_read, (source, sheetIndex));

  @override
  Future<Outcome<Uint8List, TransferRejection>> write(
    List<List<String>> rows,
    TransferFormat format,
  ) => compute(_write, (rows, format));
}

const _delimited = DelimitedTextDataSource();
const _xlsx = XlsxDataSource();

Outcome<SourceTable, TransferRejection> _read((TransferSource, int?) request) {
  final (source, sheetIndex) = request;
  final table = switch (source) {
    PastedSource(:final text) => _pasted(text),
    FileSource(:final bytes, format: TransferFormat.xlsx) => _workbook(
      bytes,
      sheetIndex,
    ),
    FileSource(:final bytes, :final format) => _delimitedFile(bytes, format),
  };
  if (table case Ok(:final value) when value.isBlank) {
    return const Rejected(TransferRejection.emptySource);
  }
  return table;
}

Outcome<SourceTable, TransferRejection> _pasted(String text) => Ok(
  SourceTable(rows: _delimited.parse(text, _delimited.delimiterOfPasted(text))),
);

Outcome<SourceTable, TransferRejection> _delimitedFile(
  Uint8List bytes,
  TransferFormat format,
) {
  final String text;
  try {
    text = _delimited.decodeUtf8(bytes);
  } on FormatException {
    return const Rejected(TransferRejection.badEncoding);
  }
  final delimiter = format == TransferFormat.tsv
      ? DelimitedTextDataSource.tab
      : DelimitedTextDataSource.comma;
  return Ok(SourceTable(rows: _delimited.parse(text, delimiter)));
}

Outcome<SourceTable, TransferRejection> _workbook(
  Uint8List bytes,
  int? sheetIndex,
) {
  try {
    final workbook = _xlsx.read(bytes, sheetIndex: sheetIndex);
    return Ok(
      SourceTable(
        rows: workbook.rows,
        sheetNames: workbook.sheetNames,
        sheetIndex: workbook.sheetIndex,
      ),
    );
  } on Object {
    // Whatever the package throws for a damaged or protected workbook, the
    // user sees one typed reason and nothing of the file (BR-TRANSFER-006).
    return const Rejected(TransferRejection.unreadableFile);
  }
}

Outcome<Uint8List, TransferRejection> _write(
  (List<List<String>>, TransferFormat) request,
) {
  final (rows, format) = request;
  try {
    return Ok(switch (format) {
      TransferFormat.csv => _delimited.encode(
        rows,
        DelimitedTextDataSource.comma,
      ),
      TransferFormat.tsv => _delimited.encode(
        rows,
        DelimitedTextDataSource.tab,
      ),
      TransferFormat.xlsx => _xlsx.write(rows),
    });
  } on Object {
    return const Rejected(TransferRejection.encodeFailed);
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/transfer/data/transfer_file_repository_impl_test.dart`
Expected: PASS, every test.
Then run `dart format lib test` and `flutter analyze`: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer test/features/transfer
git commit -m "feat(transfer): read and write CSV, TSV and XLSX off the UI isolate (BR-TRANSFER-006, BR-TRANSFER-012)"
```

### Task 4: The card feature's half: duplicate key, batch write, export read

**Files:**
- Create: `lib/features/card/domain/models/card_import_result_model.dart`
- Create: `lib/features/card/domain/models/card_export_snapshot_model.dart`
- Modify: `lib/features/card/domain/repositories/card_repository.dart`
- Modify: `lib/features/card/data/datasources/card_dao.dart`
- Modify: `lib/features/card/data/repositories/card_repository_impl.dart` (`createCard` now calls `_insertCard`; its behaviour is unchanged)
- Test: `test/features/card/data/card_transfer_test.dart`

**Interfaces:**
- Consumes: `CardFoldedPair` (Task 2); `CardDao`, `CardListDao.tagsOf`,
  `ScheduleRepository.initializeCard`, `_replaceTags`, `_write`, `_mapped`
  (existing).
- Produces on `CardRepository`: `Future<Set<CardFoldedPair>> foldedPairs(String
  deckId)`; `Future<Outcome<CardImportResult, CardRejection>> importCards({required
  String deckId, required List<CardDraft> drafts, required bool includeDuplicates,
  DateTime? now})`; `Future<Outcome<CardExportSnapshot, CardRejection>>
  exportSnapshot({required String deckId, Set<String>? cardIds})`;
  `CardImportResult(written, skippedDuplicates)`; `CardExportSnapshot(deckName,
  rows)`, `CardExportRow(front, back, example, hint, pronunciation, tagNames)`.
  The six `implements CardRepository` fakes under `test/features/card/presentation/`
  use `noSuchMethod`, so they need no change.

`importCards` checks every draft before its first write: a `Rejected` returned after an insert would commit that insert, so a refusal must come before any write, and only a throw rolls back. The 1,500-draft test takes about 3 s on the scratch machine. Steps 2 and 4 run the whole `test/features/card` folder, so the `createCard` refactor is covered by its existing tests.


- [ ] **Step 1: Write the failing tests**

`test/features/card/data/card_transfer_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The card feature's half of Card Transfer: the duplicate key, the batch
// write of an import and the read of an export (UC-TRANSFER-001,
// UC-TRANSFER-002).

DateTime _now() => DateTime(2026, 9, 26);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

T _ok<T>(Outcome<T, CardRejection> result) =>
    (result as Ok<T, CardRejection>).value;

CardRejection _reason(Outcome<Object?, CardRejection> result) =>
    (result as Rejected<Object?, CardRejection>).reason;

/// Fails the second schedule row, after one card is already written.
final class _SecondScheduleFails implements ScheduleRepository {
  _SecondScheduleFails(this._inner);

  final ScheduleRepository _inner;
  var _calls = 0;

  @override
  Future<void> initializeCard({required String cardId}) async {
    _calls++;
    if (_calls == 2) throw StateError('schedule row not written');
    await _inner.initializeCard(cardId: cardId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());

  group('foldedPairs (BR-TRANSFER-003)', () {
    test('the folded faces of the live cards of the deck only', () async {
      final other = await decks.sub(root.id, 'o');
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: ' Menu',
        back: 'Thực đơn',
      );
      await insertCard(
        db,
        id: 'c',
        deckId: other.id,
        front: 'bill',
        back: 'hóa đơn',
      );
      await insertCard(
        db,
        id: 'b',
        deckId: leaf.id,
        front: 'gone',
        back: 'x',
        deleteBatchId: 'batch',
      );

      expect(await cards.foldedPairs(leaf.id), {
        (front: 'menu', back: 'thực đơn'),
      });
    });
  });

  group('importCards (BR-TRANSFER-001…BR-TRANSFER-005)', () {
    test('every draft becomes a new card with one schedule row and its tags; unset becomes card', () async {
      final result = _ok(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [
            CardDraft(
              front: 'menu',
              back: 'thực đơn',
              tagNames: ['food', 'noun'],
            ),
            CardDraft(
              front: 'bill',
              back: 'hóa đơn',
              example: 'The bill, please.',
            ),
          ],
          includeDuplicates: false,
        ),
      );

      expect((result.written, result.skippedDuplicates), (2, 0));
      expect(await _count(db, 'card'), 2);
      expect(await _count(db, 'card_schedule'), 2);
      expect(await _count(db, 'card_tags'), 2);
      expect(await _count(db, 'review_log'), 0);
      expect(
        (await decks.findById(leaf.id))!.contentType,
        DeckContentType.card,
      );
    });

    test('duplicates of the deck as it is now, and within the batch, are skipped by default', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'menu',
        back: 'thực đơn',
      );

      final result = _ok(
        await cards.importCards(
          deckId: leaf.id,
          drafts: const [
            CardDraft(front: 'MENU ', back: 'Thực đơn'),
            CardDraft(front: 'bill', back: 'hóa đơn'),
            CardDraft(front: 'Bill', back: 'Hóa đơn'),
          ],
          includeDuplicates: false,
        ),
      );

      expect((result.written, result.skippedDuplicates), (1, 2));
      expect(await _count(db, 'card'), 2);
    });

    test(
      'Include duplicates writes them as new cards, never merged (A4)',
      () async {
        await insertCard(
          db,
          id: 'a',
          deckId: leaf.id,
          front: 'menu',
          back: 'thực đơn',
        );

        final result = _ok(
          await cards.importCards(
            deckId: leaf.id,
            drafts: const [CardDraft(front: 'menu', back: 'thực đơn')],
            includeDuplicates: true,
          ),
        );

        expect(result.written, 1);
        expect(await _count(db, 'card'), 2);
      },
    );

    test(
      'a batch that writes nothing changes nothing, content_type included',
      () async {
        final before = await totalChanges(db);

        final result = _ok(
          await cards.importCards(
            deckId: leaf.id,
            drafts: const [],
            includeDuplicates: false,
          ),
        );

        expect(result.written, 0);
        expect(await totalChanges(db), before);
        expect(
          (await decks.findById(leaf.id))!.contentType,
          DeckContentType.unset,
        );
      },
    );

    test('a root, a deck holding sub-decks and a missing deck are refused; nothing is written (E4)', () async {
      await decks.sub(leaf.id, 'child');
      const drafts = [CardDraft(front: 'a', back: 'b')];

      expect(
        _reason(
          await cards.importCards(
            deckId: root.id,
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notACardContainer,
      );
      expect(
        _reason(
          await cards.importCards(
            deckId: leaf.id,
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notACardContainer,
      );
      expect(
        _reason(
          await cards.importCards(
            deckId: 'missing',
            drafts: drafts,
            includeDuplicates: false,
          ),
        ),
        CardRejection.notFound,
      );
      expect(await _count(db, 'card'), 0);
    });

    test('one draft the card rules refuse refuses the batch', () async {
      final result = await cards.importCards(
        deckId: leaf.id,
        drafts: [
          const CardDraft(front: 'a', back: 'b'),
          CardDraft(front: 'x' * 61, back: 'y'),
        ],
        includeDuplicates: false,
      );

      expect(_reason(result), CardRejection.frontTooLong);
      expect(await _count(db, 'card'), 0);
    });

    test(
      'a write that fails half way rolls the whole batch back (E5)',
      () async {
        final failing = CardRepositoryImpl(
          db,
          _SecondScheduleFails(ScheduleRepositoryImpl(db, now: _now)),
          TagRepositoryImpl(db, now: _now),
          now: _now,
        );

        await expectLater(
          failing.importCards(
            deckId: leaf.id,
            drafts: const [
              CardDraft(front: 'a', back: 'b'),
              CardDraft(front: 'c', back: 'd'),
            ],
            includeDuplicates: false,
          ),
          throwsA(isA<Failure>()),
        );
        expect(await _count(db, 'card'), 0);
        expect(await _count(db, 'card_schedule'), 0);
        expect(
          (await decks.findById(leaf.id))!.contentType,
          DeckContentType.unset,
        );
      },
    );

    test('1,500 drafts in one batch', () async {
      final result = _ok(
        await cards.importCards(
          deckId: leaf.id,
          drafts: [
            for (var i = 0; i < 1500; i++)
              CardDraft(
                front: 'term $i',
                back: 'meaning $i',
                tagNames: const ['bulk'],
              ),
          ],
          includeDuplicates: false,
        ),
      );

      expect(result.written, 1500);
      expect(await _count(db, 'card_schedule'), 1500);
      expect(await _count(db, 'tags'), 1);
    });
  });

  group('exportSnapshot (BR-TRANSFER-007, BR-TRANSFER-010, BR-TRANSFER-011)', () {
    // `c` is inserted before `b` on the same day, so insertion order alone
    // would put `c` first (BR-TRANSFER-010).
    setUp(() async {
      await insertCard(
        db,
        id: 'c',
        deckId: leaf.id,
        front: 'tie',
        back: '3',
        createdAt: DateTime(2026, 9, 2),
      );
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: 'first',
        back: '1',
        hint: 'h',
        createdAt: DateTime(2026, 9, 1),
      );
      await insertCard(
        db,
        id: 'b',
        deckId: leaf.id,
        front: 'second',
        back: '2',
        createdAt: DateTime(2026, 9, 2),
      );
      await insertCard(
        db,
        id: 'z',
        deckId: leaf.id,
        front: 'gone',
        back: '4',
        deleteBatchId: 'batch',
      );
      await TagRepositoryImpl(
        db,
        now: _now,
      ).replaceForCard(cardId: 'a', names: ['zeta', 'Alpha'], now: _now());
    });

    test(
      'the live cards by created_at then id, their six fields and sorted tags',
      () async {
        final snapshot = _ok(await cards.exportSnapshot(deckId: leaf.id));

        expect(snapshot.deckName, 'l');
        expect(snapshot.rows.map((row) => row.front), [
          'first',
          'second',
          'tie',
        ]);
        final first = snapshot.rows.first;
        expect((first.back, first.hint, first.example), ('1', 'h', null));
        expect(first.tagNames, ['Alpha', 'zeta']);
      },
    );

    test(
      'a selection keeps that order whatever order it was touched in',
      () async {
        final snapshot = _ok(
          await cards.exportSnapshot(deckId: leaf.id, cardIds: {'c', 'a'}),
        );

        expect(snapshot.rows.map((row) => row.front), ['first', 'tie']);
      },
    );

    test('an id that is gone, in the Trash or in another deck fails the whole request (E6)', () async {
      final other = await decks.sub(root.id, 'o');
      await insertCard(db, id: 'x', deckId: other.id);

      for (final ids in [
        {'a', 'missing'},
        {'a', 'z'},
        {'a', 'x'},
      ]) {
        expect(
          _reason(await cards.exportSnapshot(deckId: leaf.id, cardIds: ids)),
          CardRejection.notFound,
        );
      }
      expect(
        _reason(await cards.exportSnapshot(deckId: 'missing')),
        CardRejection.notFound,
      );
    });

    test(
      'an empty deck is an empty snapshot, and reading writes nothing',
      () async {
        final empty = await decks.sub(root.id, 'e');
        final before = await totalChanges(db);

        expect(_ok(await cards.exportSnapshot(deckId: empty.id)).rows, isEmpty);
        _ok(await cards.exportSnapshot(deckId: leaf.id));
        expect(await totalChanges(db), before);
      },
    );
  });
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/card`
Expected: FAIL to load: a file under `lib/` that the tests import, or a method they call, does not exist yet.

- [ ] **Step 3: Write the implementation**

`lib/features/card/domain/models/card_import_result_model.dart`:

```dart
/// What one import wrote (UC-TRANSFER-001 step 8).
final class CardImportResult {
  const CardImportResult({
    required this.written,
    required this.skippedDuplicates,
  });

  final int written;

  /// Drafts the duplicate policy dropped inside the commit (BR-TRANSFER-003).
  final int skippedDuplicates;
}
```

`lib/features/card/domain/models/card_export_snapshot_model.dart`:

```dart
/// One card as a transfer file carries it: its six content fields and
/// nothing else (BR-TRANSFER-008).
final class CardExportRow {
  const CardExportRow({
    required this.front,
    required this.back,
    this.example,
    this.hint,
    this.pronunciation,
    this.tagNames = const [],
  });

  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;

  /// Ordered by folded name, then id (BR-TRANSFER-010).
  final List<String> tagNames;
}

/// The deck's name and its cards, read in one transaction, ordered by
/// `created_at`, then `id` (BR-TRANSFER-010).
final class CardExportSnapshot {
  const CardExportSnapshot({required this.deckName, required this.rows});

  final String deckName;
  final List<CardExportRow> rows;
}
```

`lib/features/card/domain/repositories/card_repository.dart` (apply this diff):

```diff
diff --git a/lib/features/card/domain/repositories/card_repository.dart b/lib/features/card/domain/repositories/card_repository.dart
index 8070115..ef2a2b9 100644
--- a/lib/features/card/domain/repositories/card_repository.dart
+++ b/lib/features/card/domain/repositories/card_repository.dart
@@ -3,6 +3,9 @@ import 'package:memox/features/card/domain/entities/card_entity.dart';
 import 'package:memox/features/card/domain/failures/card_failure.dart';
 import 'package:memox/features/card/domain/models/card_detail_model.dart';
 import 'package:memox/features/card/domain/models/card_draft_model.dart';
+import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
+import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
+import 'package:memox/features/card/domain/models/card_import_result_model.dart';
 import 'package:memox/features/card/domain/models/card_list_query_model.dart';
 import 'package:memox/features/card/domain/models/card_list_view_model.dart';
 import 'package:memox/features/card/domain/models/card_move_target_model.dart';
@@ -86,4 +89,32 @@ abstract interface class CardRepository {
 
   /// BR-CARD-010: where the cards of [sourceDeckId] may move, in tree order.
   Stream<List<CardMoveTarget>> watchMoveTargets(String sourceDeckId);
+
+  /// BR-TRANSFER-003: the folded faces of the live cards of [deckId], the
+  /// set an import preview marks duplicates against.
+  Future<Set<CardFoldedPair>> foldedPairs(String deckId);
+
+  /// UC-TRANSFER-001 step 7, in one transaction: the deck is checked again
+  /// (BR-TRANSFER-001), the duplicate policy is applied again against the
+  /// deck as it is now and within [drafts] (BR-TRANSFER-003), and each draft
+  /// kept is written as [createCard] writes one (BR-TRANSFER-004). The deck
+  /// becomes a deck of cards only when a card was written (BR-TRANSFER-005).
+  /// A draft the card rules refuse refuses the batch, and nothing is
+  /// written.
+  Future<Outcome<CardImportResult, CardRejection>> importCards({
+    required String deckId,
+    required List<CardDraft> drafts,
+    required bool includeDuplicates,
+    DateTime? now,
+  });
+
+  /// UC-TRANSFER-002 step 4: the deck's name and its live cards, or those of
+  /// [cardIds], in one read that writes nothing (BR-TRANSFER-010,
+  /// BR-TRANSFER-011). A missing deck, or an id that is gone or in another
+  /// deck, is `notFound` for the whole request (BR-TRANSFER-007). An empty
+  /// scope is an empty snapshot; the caller refuses it.
+  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
+    required String deckId,
+    Set<String>? cardIds,
+  });
 }
```

`lib/features/card/data/datasources/card_dao.dart` (apply this diff):

```diff
diff --git a/lib/features/card/data/datasources/card_dao.dart b/lib/features/card/data/datasources/card_dao.dart
index e0aa0c5..99d5dda 100644
--- a/lib/features/card/data/datasources/card_dao.dart
+++ b/lib/features/card/data/datasources/card_dao.dart
@@ -2,6 +2,7 @@ import 'package:drift/drift.dart';
 import 'package:memox/core/database/app_database.dart';
 import 'package:memox/core/text/folded_text.dart';
 import 'package:memox/features/card/domain/models/card_draft_model.dart';
+import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
 
 /// Row access for `card`, plus the reads and writes of the owning `deck` row
 /// that card writes need. It returns Drift rows, never domain entities, and
@@ -32,6 +33,35 @@ final class CardDao {
     _db.deck,
   )..where((deck) => deck.id.isIn(ids) & deck.deleteBatchId.isNull())).get();
 
+  /// The folded faces of the live cards of [deckId] (BR-TRANSFER-003).
+  Future<Set<CardFoldedPair>> foldedPairs(String deckId) async {
+    final rows =
+        await (_db.select(_db.card)..where(
+              (card) =>
+                  card.deckId.equals(deckId) & card.deleteBatchId.isNull(),
+            ))
+            .get();
+    return {
+      for (final row in rows) (front: row.frontFolded, back: row.backFolded),
+    };
+  }
+
+  /// The live cards of [deckId], or those among [ids], by `created_at`, then
+  /// `id` (BR-TRANSFER-010).
+  Future<List<CardRow>> exportRows(String deckId, Set<String>? ids) =>
+      (_db.select(_db.card)
+            ..where(
+              (card) =>
+                  card.deckId.equals(deckId) &
+                  card.deleteBatchId.isNull() &
+                  (ids == null ? const Constant(true) : card.id.isIn(ids)),
+            )
+            ..orderBy([
+              (card) => OrderingTerm.asc(card.createdAt),
+              (card) => OrderingTerm.asc(card.id),
+            ]))
+          .get();
+
   Future<void> insertCard({
     required String id,
     required String deckId,
```

`lib/features/card/data/repositories/card_repository_impl.dart` (apply this diff):

```diff
diff --git a/lib/features/card/data/repositories/card_repository_impl.dart b/lib/features/card/data/repositories/card_repository_impl.dart
index c070041..974a894 100644
--- a/lib/features/card/data/repositories/card_repository_impl.dart
+++ b/lib/features/card/data/repositories/card_repository_impl.dart
@@ -2,6 +2,7 @@ import 'package:memox/core/database/app_database.dart';
 import 'package:memox/core/error/failure.dart';
 import 'package:memox/core/error/outcome.dart';
 import 'package:memox/core/id/new_id.dart';
+import 'package:memox/core/text/folded_text.dart';
 import 'package:memox/features/card/data/datasources/card_dao.dart';
 import 'package:memox/features/card/data/datasources/card_detail_dao.dart';
 import 'package:memox/features/card/data/datasources/card_list_dao.dart';
@@ -10,6 +11,9 @@ import 'package:memox/features/card/domain/entities/card_entity.dart';
 import 'package:memox/features/card/domain/failures/card_failure.dart';
 import 'package:memox/features/card/domain/models/card_detail_model.dart';
 import 'package:memox/features/card/domain/models/card_draft_model.dart';
+import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
+import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
+import 'package:memox/features/card/domain/models/card_import_result_model.dart';
 import 'package:memox/features/card/domain/models/card_list_query_model.dart';
 import 'package:memox/features/card/domain/models/card_list_view_model.dart';
 import 'package:memox/features/card/domain/models/card_move_target_model.dart';
@@ -63,10 +67,7 @@ final class CardRepositoryImpl implements CardRepository {
         return const Rejected(CardRejection.notACardContainer);
       }
 
-      final id = newId();
-      await _dao.insertCard(id: id, deckId: deckId, draft: draft, now: at);
-      await _schedules.initializeCard(cardId: id);
-      await _replaceTags(id, draft, at);
+      final id = await _insertCard(deckId, draft, at);
       if (contentType == DeckContentType.unset) {
         await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
       }
@@ -307,6 +308,99 @@ final class CardRepositoryImpl implements CardRepository {
           )
           .mapDatabaseErrors();
 
+  @override
+  Future<Set<CardFoldedPair>> foldedPairs(String deckId) =>
+      _mapped(() => _dao.foldedPairs(deckId));
+
+  @override
+  Future<Outcome<CardImportResult, CardRejection>> importCards({
+    required String deckId,
+    required List<CardDraft> drafts,
+    required bool includeDuplicates,
+    DateTime? now,
+  }) {
+    final at = now ?? _now();
+    return _write(() async {
+      for (final draft in drafts) {
+        if (draft.check() case Rejected(:final reason)) return Rejected(reason);
+      }
+      final deck = await _dao.deckRow(deckId);
+      if (deck == null) return const Rejected(CardRejection.notFound);
+      final contentType = DeckContentType.values.byName(deck.contentType);
+      if (DeckEntity.checkCreateCard(parentContentType: contentType)
+          case Rejected()) {
+        return const Rejected(CardRejection.notACardContainer);
+      }
+
+      final taken = await _dao.foldedPairs(deckId);
+      var written = 0;
+      for (final draft in drafts) {
+        final pair = (front: foldText(draft.front), back: foldText(draft.back));
+        if (!includeDuplicates && taken.contains(pair)) continue;
+        taken.add(pair);
+        await _insertCard(deckId, draft, at);
+        written++;
+      }
+      if (written > 0 && contentType == DeckContentType.unset) {
+        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
+      }
+      return Ok(
+        CardImportResult(
+          written: written,
+          skippedDuplicates: drafts.length - written,
+        ),
+      );
+    });
+  }
+
+  @override
+  Future<Outcome<CardExportSnapshot, CardRejection>> exportSnapshot({
+    required String deckId,
+    Set<String>? cardIds,
+  }) => _mapped(
+    () => _db.transaction(() async {
+      final deck = await _dao.deckRow(deckId);
+      if (deck == null) return const Rejected(CardRejection.notFound);
+      final rows = await _dao.exportRows(deckId, cardIds);
+      if (cardIds != null && rows.length != cardIds.length) {
+        return const Rejected(CardRejection.notFound);
+      }
+      final tags = await _listDao.tagsOf([for (final row in rows) row.id]);
+      return Ok(
+        CardExportSnapshot(
+          deckName: deck.name,
+          rows: [
+            for (final row in rows)
+              CardExportRow(
+                front: row.front,
+                back: row.back,
+                example: row.example,
+                hint: row.hint,
+                pronunciation: row.pronunciation,
+                tagNames: [
+                  for (final tag in tags[row.id] ?? const <Tag>[]) tag.name,
+                ],
+              ),
+          ],
+        ),
+      );
+    }),
+  );
+
+  /// One card, its schedule row (BR-CARD-004) and its tags, inside the
+  /// caller's transaction; the new card's id.
+  Future<String> _insertCard(
+    String deckId,
+    CardDraft draft,
+    DateTime at,
+  ) async {
+    final id = newId();
+    await _dao.insertCard(id: id, deckId: deckId, draft: draft, now: at);
+    await _schedules.initializeCard(cardId: id);
+    await _replaceTags(id, draft, at);
+    return id;
+  }
+
   /// The draft passed [CardDraft.check], which holds the tag rules, so a
   /// refusal here is a bug: throwing rolls the whole write back.
   Future<void> _replaceTags(String cardId, CardDraft draft, DateTime at) async {
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/card`
Expected: PASS, every test.
Then run `dart format lib test` and `flutter analyze`: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/card test/features/card/data/card_transfer_test.dart
git commit -m "feat(card): folded pairs, batch import and the export read (BR-TRANSFER-001…BR-TRANSFER-005, BR-TRANSFER-007, BR-TRANSFER-010)"
```

### Task 5: The import use cases

**Files:**
- Create: `lib/features/transfer/domain/models/import_summary_model.dart`
- Create: `lib/features/transfer/domain/usecases/read_import_source_use_case.dart`
- Create: `lib/features/transfer/domain/usecases/preview_import_use_case.dart`
- Create: `lib/features/transfer/domain/usecases/commit_import_use_case.dart`
- Test: `test/features/transfer/domain/import_use_cases_test.dart`

**Interfaces:**
- Consumes: `TransferFileRepository` (Task 3); `CardRepository.foldedPairs`,
  `importCards` (Task 4); `buildImportPreview`, `ColumnMapping` (Task 2).
- Produces: `ReadImportSourceUseCase(TransferFileRepository).call(TransferSource,
  {int? sheetIndex})`; `PreviewImportUseCase(CardRepository).call({deckId, table,
  mapping, hasHeaderRow}) → Outcome<ImportPreview, TransferRejection>`
  (`mappingIncomplete`, `emptySource`); `CommitImportUseCase(CardRepository).call(
  {deckId, preview, includeDuplicates}) → Outcome<ImportSummary, TransferRejection>`
  (`nothingToImport`, `targetRejected`); `ImportSummary(written, duplicatesSkipped,
  invalid, blank)` with `kind` in `enum ImportSummaryKind { success, partial, none }`.

`none` (spec §8.1 ruling 1) is `written == 0` at commit time. `partial` counts the duplicates skipped by the preview's policy, those the commit skipped, and invalid rows; a blank row is ignored and alone keeps `success`, as the kit's copy has it.


- [ ] **Step 1: Write the failing tests**

`test/features/transfer/domain/import_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/commit_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The import use cases run over the real repositories, so each test asserts
// what the person sees (UC-TRANSFER-001).

DateTime _now() => DateTime(2026, 9, 26);

T _ok<T>(Outcome<T, TransferRejection> result) =>
    (result as Ok<T, TransferRejection>).value;

TransferRejection _reason(Outcome<Object?, TransferRejection> result) =>
    (result as Rejected<Object?, TransferRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  const files = TransferFileRepositoryImpl();
  late ReadImportSourceUseCase read;
  late PreviewImportUseCase preview;
  late CommitImportUseCase commit;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    read = const ReadImportSourceUseCase(files);
    preview = PreviewImportUseCase(cards);
    commit = CommitImportUseCase(cards);
  });
  tearDown(() => db.close());

  Future<ImportPreview> previewOf(String text) async {
    final table = _ok(await read(PastedSource(text)));
    return _ok(
      await preview(
        deckId: leaf.id,
        table: table,
        mapping: ColumnMapping.fromHeader(table.rows.first),
        hasHeaderRow: true,
      ),
    );
  }

  test('pasted rows become cards; the summary counts what was skipped (UC-TRANSFER-001)', () async {
    await insertCard(
      db,
      id: 'old',
      deckId: leaf.id,
      front: 'tip',
      back: 'tiền boa',
    );
    final rows = await previewOf(
      'front,back,tags\nmenu,thực đơn,food\nbill,,\ntip,tiền boa,\n,,\nmenu,thực đơn,\n',
    );

    final summary = _ok(
      await commit(deckId: leaf.id, preview: rows, includeDuplicates: false),
    );

    expect(
      (
        summary.written,
        summary.duplicatesSkipped,
        summary.invalid,
        summary.blank,
      ),
      (1, 2, 1, 1),
    );
    expect(summary.kind, ImportSummaryKind.partial);
  });

  test('a clean source ends on success; a blank row alone does not make it partial', () async {
    final summary = _ok(
      await commit(
        deckId: leaf.id,
        preview: await previewOf('front,back\na,b\n,\nc,d'),
        includeDuplicates: false,
      ),
    );

    expect(summary.kind, ImportSummaryKind.success);
  });

  test(
    'rows that became duplicates after the preview end on none (spec §8.1)',
    () async {
      final rows = await previewOf('front,back\na,b');
      await insertCard(db, id: 'raced', deckId: leaf.id, front: 'a', back: 'b');

      final summary = _ok(
        await commit(deckId: leaf.id, preview: rows, includeDuplicates: false),
      );

      expect((summary.written, summary.kind), (0, ImportSummaryKind.none));
    },
  );

  test('an unmapped face, and a preview with nothing to write, are refused before any write', () async {
    final table = _ok(await read(const PastedSource('term,meaning\na,b')));
    expect(
      _reason(
        await preview(
          deckId: leaf.id,
          table: table,
          mapping: ColumnMapping.fromHeader(table.rows.first),
          hasHeaderRow: true,
        ),
      ),
      TransferRejection.mappingIncomplete,
    );

    final allInvalid = await previewOf('front,back\na,');
    expect(
      _reason(
        await commit(
          deckId: leaf.id,
          preview: allInvalid,
          includeDuplicates: false,
        ),
      ),
      TransferRejection.nothingToImport,
    );
  });

  test('a header without data rows is an empty source (E2)', () async {
    final table = _ok(await read(const PastedSource('front,back\n')));

    expect(
      _reason(
        await preview(
          deckId: leaf.id,
          table: table,
          mapping: ColumnMapping.fromHeader(table.rows.first),
          hasHeaderRow: true,
        ),
      ),
      TransferRejection.emptySource,
    );
  });

  test(
    'a target that gained sub-decks after the preview is refused (E4)',
    () async {
      final rows = await previewOf('front,back\na,b');
      await decks.sub(leaf.id, 'child');

      expect(
        _reason(
          await commit(
            deckId: leaf.id,
            preview: rows,
            includeDuplicates: false,
          ),
        ),
        TransferRejection.targetRejected,
      );
    },
  );
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/domain/import_use_cases_test.dart`
Expected: FAIL to load: a file under `lib/` that the tests import, or a method they call, does not exist yet.

- [ ] **Step 3: Write the implementation**

`lib/features/transfer/domain/models/import_summary_model.dart`:

```dart
/// Which result screen an import ends on (UC-TRANSFER-001 step 8; kit
/// screen 11: success, partial, none).
enum ImportSummaryKind { success, partial, none }

/// What one commit did, counted for the result screen.
final class ImportSummary {
  const ImportSummary({
    required this.written,
    required this.duplicatesSkipped,
    required this.invalid,
    required this.blank,
  });

  final int written;

  /// Skipped by the preview's policy and by the commit's own re-check
  /// (BR-TRANSFER-003).
  final int duplicatesSkipped;
  final int invalid;
  final int blank;

  /// `none`: the commit found nothing left to write (spec §8.1 ruling 1).
  /// A blank row is ignored, not skipped, so it alone keeps `success`.
  ImportSummaryKind get kind {
    if (written == 0) return ImportSummaryKind.none;
    if (duplicatesSkipped + invalid > 0) return ImportSummaryKind.partial;
    return ImportSummaryKind.success;
  }
}
```

`lib/features/transfer/domain/usecases/read_import_source_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// UC-TRANSFER-001 step 3, A2, E1, E2: the source read into rows, in
/// memory, writing nothing (BR-TRANSFER-006).
final class ReadImportSourceUseCase {
  const ReadImportSourceUseCase(this._files);

  final TransferFileRepository _files;

  Future<Outcome<SourceTable, TransferRejection>> call(
    TransferSource source, {
    int? sheetIndex,
  }) => _files.read(source, sheetIndex: sheetIndex);
}
```

`lib/features/transfer/domain/usecases/preview_import_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// UC-TRANSFER-001 steps 4–5: every row's status against the deck as it is
/// now. Writes nothing (BR-TRANSFER-006).
final class PreviewImportUseCase {
  const PreviewImportUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<ImportPreview, TransferRejection>> call({
    required String deckId,
    required SourceTable table,
    required ColumnMapping mapping,
    required bool hasHeaderRow,
  }) async {
    if (!mapping.isComplete) {
      return const Rejected(TransferRejection.mappingIncomplete);
    }
    final preview = buildImportPreview(
      table: table,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
      existing: await _cards.foldedPairs(deckId),
    );
    if (preview.isEmpty) return const Rejected(TransferRejection.emptySource);
    return Ok(preview);
  }
}
```

`lib/features/transfer/domain/usecases/commit_import_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_summary_model.dart';

/// UC-TRANSFER-001 steps 6–8, E3, E4: the preview's drafts written in one
/// transaction by the card feature, and the counts for the result screen.
/// A database failure leaves as the thrown `Failure` (E5).
final class CommitImportUseCase {
  const CommitImportUseCase(this._cards);

  final CardRepository _cards;

  Future<Outcome<ImportSummary, TransferRejection>> call({
    required String deckId,
    required ImportPreview preview,
    required bool includeDuplicates,
  }) async {
    final drafts = preview.draftsToWrite(includeDuplicates: includeDuplicates);
    if (drafts.isEmpty) {
      return const Rejected(TransferRejection.nothingToImport);
    }
    final result = await _cards.importCards(
      deckId: deckId,
      drafts: drafts,
      includeDuplicates: includeDuplicates,
    );
    return switch (result) {
      Ok(:final value) => Ok(
        ImportSummary(
          written: value.written,
          duplicatesSkipped:
              value.skippedDuplicates +
              (includeDuplicates ? 0 : preview.duplicates),
          invalid: preview.invalid,
          blank: preview.blank,
        ),
      ),
      Rejected(reason: CardRejection.notFound) ||
      Rejected(
        reason: CardRejection.notACardContainer,
      ) => const Rejected(TransferRejection.targetRejected),
      // The preview checked every draft with the same rules, so another
      // refusal is a bug, not a user's error.
      Rejected(:final reason) => throw StateError(
        'import refused a previewed draft: $reason',
      ),
    };
  }
}
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/transfer/domain/import_use_cases_test.dart`
Expected: PASS, every test.
Then run `dart format lib test` and `flutter analyze`: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer test/features/transfer
git commit -m "feat(transfer): read, preview and commit an import (UC-TRANSFER-001)"
```

### Task 6: Export and the share sheet

**Files:**
- Create: `lib/features/transfer/domain/models/export_artifact_model.dart`
- Create: `lib/features/transfer/domain/repositories/export_share_repository.dart`
- Create: `lib/features/transfer/domain/usecases/build_export_use_case.dart`
- Create: `lib/features/transfer/domain/usecases/share_export_use_case.dart`
- Create: `lib/features/transfer/data/repositories/export_share_repository_impl.dart`
- Create: `lib/features/transfer/di/transfer_file_repository_provider.dart`
- Create: `lib/features/transfer/di/export_share_repository_provider.dart`
- Test: `test/features/transfer/domain/export_file_name_test.dart`, `test/features/transfer/domain/export_use_cases_test.dart`, `test/features/transfer/data/export_share_repository_impl_test.dart`

**Interfaces:**
- Consumes: `CardRepository.exportSnapshot` (Task 4); `TransferFileRepository.write`
  (Task 3); `TagsCell.encode` (Task 1); `TransferField` (Task 2); the import use
  cases (Task 5), to read an exported file back in the tests.
- Produces: `ExportArtifact(bytes, fileName, format)`; `enum ExportShareResult {
  shared, dismissed }`; `String exportFileName({deckName, date, format})`;
  `BuildExportUseCase(CardRepository, TransferFileRepository).call({deckId, format,
  today, Set<String>? cardIds}) → Outcome<ExportArtifact, TransferRejection>`
  (`emptyScope`, `staleSelection`, `encodeFailed`); `List<List<String>>
  rowsOf(CardExportSnapshot)`; `ExportShareRepository.share(ExportArtifact)`;
  `ExportShareRepositoryImpl({share})`; `ShareExportUseCase(ExportShareRepository)`;
  `transferFileRepositoryProvider`, `exportShareRepositoryProvider`.

- [ ] **Step 1: Write the failing tests**

`test/features/transfer/domain/export_file_name_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

String _name(String deckName, [TransferFormat format = TransferFormat.csv]) =>
    exportFileName(
      deckName: deckName,
      date: DateTime(2026, 9, 6),
      format: format,
    );

void main() {
  test('the sanitized deck name, the local date and the extension (BR-TRANSFER-013)', () {
    expect(_name('Nhà hàng'), 'Nhà-hàng-2026-09-06.csv');
    expect(
      _name('한국어 TOPIK I', TransferFormat.xlsx),
      '한국어-TOPIK-I-2026-09-06.xlsx',
    );
  });

  test(
    'separators, control and refused characters go; white space collapses',
    () {
      expect(
        _name(' a/b\\c:d*e?"f<g>h|i\tj\u0007k  '),
        'a-b-c-d-e-f-g-h-i-j-k-2026-09-06.csv',
      );
    },
  );

  test('a name that sanitizes to nothing becomes cards', () {
    expect(_name(' /\\: '), 'cards-2026-09-06.csv');
  });
}
```

`test/features/transfer/domain/export_use_cases_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/build_export_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// The export use case runs over the real repositories, and its file is read
// back through the import use cases (UC-TRANSFER-002).

DateTime _now() => DateTime(2026, 9, 26);

T _ok<T>(Outcome<T, TransferRejection> result) =>
    (result as Ok<T, TransferRejection>).value;

TransferRejection _reason(Outcome<Object?, TransferRejection> result) =>
    (result as Rejected<Object?, TransferRejection>).reason;

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;
  const files = TransferFileRepositoryImpl();
  late ReadImportSourceUseCase read;
  late PreviewImportUseCase preview;
  late BuildExportUseCase export;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'Nhà hàng');
    read = const ReadImportSourceUseCase(files);
    preview = PreviewImportUseCase(cards);
    export = BuildExportUseCase(cards, files);
  });
  tearDown(() => db.close());

  group('export (UC-TRANSFER-002)', () {
    test('a deck exports, and importing the file into an empty deck gives the same content', () async {
      await insertCard(
        db,
        id: 'a',
        deckId: leaf.id,
        front: '=1+1',
        back: '001',
        example: 'e, "q"',
        createdAt: DateTime(2026, 9, 1),
      );
      await insertCard(
        db,
        id: 'b',
        deckId: leaf.id,
        front: 'b',
        back: 'x\ny',
        createdAt: DateTime(2026, 9, 2),
      );
      await TagRepositoryImpl(
        db,
        now: _now,
      ).replaceForCard(cardId: 'a', names: ['a;b', r'c\d'], now: _now());
      final target = await decks.sub(root.id, 'copy');

      for (final format in TransferFormat.values) {
        final artifact = _ok(
          await export(deckId: leaf.id, format: format, today: _now()),
        );
        expect(artifact.fileName, 'Nhà-hàng-2026-09-26.${format.extension}');

        final table = _ok(
          await read(FileSource(bytes: artifact.bytes, format: format)),
        );
        expect(table.rows, [
          ['front', 'back', 'example', 'hint', 'pronunciation', 'tags'],
          ['=1+1', '001', 'e, "q"', '', '', r'a\;b;c\\d'],
          ['b', 'x\ny', '', '', '', ''],
        ]);
        final rows = _ok(
          await preview(
            deckId: target.id,
            table: table,
            mapping: ColumnMapping.fromHeader(table.rows.first),
            hasHeaderRow: true,
          ),
        );
        expect(rows.rows.first.draft!.tagNames, ['a;b', r'c\d']);
      }
    });

    test(
      'the same deck exports the same CSV bytes twice (BR-TRANSFER-010)',
      () async {
        await insertCard(db, id: 'a', deckId: leaf.id);
        Future<Uint8List> bytes() async => _ok(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
          ),
        ).bytes;

        expect(await bytes(), await bytes());
        expect(
          utf8.decode((await bytes()).sublist(3)).split('\r\n').first,
          'front,back,example,hint,pronunciation,tags',
        );
      },
    );

    test('an empty deck, an empty selection and a stale selection are refused (E5, E6)', () async {
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
          ),
        ),
        TransferRejection.emptyScope,
      );
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
            cardIds: const {},
          ),
        ),
        TransferRejection.emptyScope,
      );
      await insertCard(db, id: 'a', deckId: leaf.id);
      expect(
        _reason(
          await export(
            deckId: leaf.id,
            format: TransferFormat.csv,
            today: _now(),
            cardIds: const {'a', 'gone'},
          ),
        ),
        TransferRejection.staleSelection,
      );
    });
  });
}
```

`test/features/transfer/data/export_share_repository_impl_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/repositories/export_share_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:share_plus/share_plus.dart';

final _artifact = ExportArtifact(
  bytes: Uint8List.fromList([1, 2, 3]),
  fileName: 'Nhà-hàng-2026-09-26.csv',
  format: TransferFormat.csv,
);

Future<Outcome<ExportShareResult, TransferRejection>> _shared(
  Future<ShareResult> Function(ShareParams params) share,
) => ExportShareRepositoryImpl(share: share).share(_artifact);

void main() {
  test('the file goes to the share sheet under its name and type', () async {
    late ShareParams sent;
    await _shared((params) async {
      sent = params;
      return const ShareResult('app', ShareResultStatus.success);
    });

    expect(sent.fileNameOverrides, ['Nhà-hàng-2026-09-26.csv']);
    expect(sent.files!.single.mimeType, 'text/csv');
    expect(await sent.files!.single.readAsBytes(), [1, 2, 3]);
  });

  test('success and an undetermined result are shared; a dismissal is a cancel (BR-TRANSFER-014)', () async {
    Future<Object?> result(ShareResultStatus status) async =>
        switch (await _shared((_) async => ShareResult('', status))) {
          Ok(:final value) => value,
          Rejected(:final reason) => reason,
        };

    expect(await result(ShareResultStatus.success), ExportShareResult.shared);
    expect(
      await result(ShareResultStatus.unavailable),
      ExportShareResult.shared,
    );
    expect(
      await result(ShareResultStatus.dismissed),
      ExportShareResult.dismissed,
    );
  });

  test(
    'no share sheet, and a platform failure, are typed reasons (E1, E2)',
    () async {
      TransferRejection reason(
        Outcome<ExportShareResult, TransferRejection> r,
      ) => (r as Rejected<ExportShareResult, TransferRejection>).reason;

      expect(
        reason(await _shared((_) => throw MissingPluginException())),
        TransferRejection.shareUnavailable,
      );
      expect(
        reason(
          await _shared(
            (_) => throw PlatformException(
              code: 'x',
              message: '/data/user/0/secret',
            ),
          ),
        ),
        TransferRejection.shareFailed,
      );
    },
  );
}
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/features/transfer/domain/export_file_name_test.dart test/features/transfer/domain/export_use_cases_test.dart test/features/transfer/data/export_share_repository_impl_test.dart`
Expected: FAIL to load: a file under `lib/` that the tests import, or a method they call, does not exist yet.

- [ ] **Step 3: Write the implementation**

`lib/features/transfer/domain/models/export_artifact_model.dart`:

```dart
import 'dart:typed_data';

import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// A finished export file, held in memory until the share sheet takes it
/// (BR-TRANSFER-014).
final class ExportArtifact {
  const ExportArtifact({
    required this.bytes,
    required this.fileName,
    required this.format,
  });

  final Uint8List bytes;
  final String fileName;
  final TransferFormat format;
}

/// How a share ended. Dismissing the share sheet is a cancel, never an
/// error (BR-TRANSFER-014).
enum ExportShareResult { shared, dismissed }

/// BR-TRANSFER-013: the deck's name without path separators, control
/// characters or characters a file system refuses, its white space runs
/// joined by one `-`, then the local date and the format's extension. A name
/// that sanitizes to nothing becomes `cards`.
String exportFileName({
  required String deckName,
  required DateTime date,
  required TransferFormat format,
}) {
  const fallback = 'cards';
  final sanitized = deckName
      .replaceAll(RegExp(r'[\\/:*?"<>|\u0000-\u001F\u007F-\u009F]'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), '-');
  final name = sanitized.isEmpty ? fallback : sanitized;
  final day = [
    date.year.toString().padLeft(4, '0'),
    date.month.toString().padLeft(2, '0'),
    date.day.toString().padLeft(2, '0'),
  ].join('-');
  return '$name-$day.${format.extension}';
}
```

`lib/features/transfer/domain/repositories/export_share_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';

/// Hands a file to the system share sheet (BR-TRANSFER-014). The one
/// implementation is `ExportShareRepositoryImpl` over `share_plus`; the
/// contract keeps the platform out of domain and out of tests (ADR-010).
abstract interface class ExportShareRepository {
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  );
}
```

`lib/features/transfer/domain/usecases/build_export_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/models/card_export_snapshot_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/models/tags_cell_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';

/// UC-TRANSFER-002 steps 4–5, E3–E6: the deck's cards, or [cardIds], as a
/// file of [format], named for the deck and [today] (BR-TRANSFER-013; the
/// caller reads [today] from the app's clock). Writes nothing
/// (BR-TRANSFER-011).
final class BuildExportUseCase {
  const BuildExportUseCase(this._cards, this._files);

  final CardRepository _cards;
  final TransferFileRepository _files;

  Future<Outcome<ExportArtifact, TransferRejection>> call({
    required String deckId,
    required TransferFormat format,
    required DateTime today,
    Set<String>? cardIds,
  }) async {
    final snapshot = await _cards.exportSnapshot(
      deckId: deckId,
      cardIds: cardIds,
    );
    final CardExportSnapshot value;
    switch (snapshot) {
      case Ok(value: final read):
        value = read;
      case Rejected():
        return Rejected(
          cardIds == null
              ? TransferRejection.emptyScope
              : TransferRejection.staleSelection,
        );
    }
    if (value.rows.isEmpty) return const Rejected(TransferRejection.emptyScope);

    final written = await _files.write(rowsOf(value), format);
    return switch (written) {
      Ok(value: final bytes) => Ok(
        ExportArtifact(
          bytes: bytes,
          fileName: exportFileName(
            deckName: value.deckName,
            date: today,
            format: format,
          ),
          format: format,
        ),
      ),
      Rejected(:final reason) => Rejected(reason),
    };
  }
}

/// The six canonical headers, then one row per card with an empty cell for
/// an absent field (BR-TRANSFER-008, BR-TRANSFER-012).
List<List<String>> rowsOf(CardExportSnapshot snapshot) => [
  [for (final field in TransferField.values) field.header],
  for (final row in snapshot.rows)
    [
      row.front,
      row.back,
      row.example ?? '',
      row.hint ?? '',
      row.pronunciation ?? '',
      TagsCell.encode(row.tagNames),
    ],
];
```

`lib/features/transfer/domain/usecases/share_export_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';

/// UC-TRANSFER-002 steps 6–7, A3, E1, E2: the file handed to the system
/// share sheet; a dismissal is a cancel (BR-TRANSFER-014).
final class ShareExportUseCase {
  const ShareExportUseCase(this._share);

  final ExportShareRepository _share;

  Future<Outcome<ExportShareResult, TransferRejection>> call(
    ExportArtifact artifact,
  ) => _share.share(artifact);
}
```

`lib/features/transfer/data/repositories/export_share_repository_impl.dart`:

```dart
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_artifact_model.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';
import 'package:share_plus/share_plus.dart';

/// `share_plus` writes the bytes to its own folder in the app's cache, which
/// it clears before each share, and hands that file to the system: no shared
/// directory, no storage permission (BR-TRANSFER-014).
final class ExportShareRepositoryImpl implements ExportShareRepository {
  ExportShareRepositoryImpl({
    Future<ShareResult> Function(ShareParams params)? share,
  }) : _share = share ?? SharePlus.instance.share;

  final Future<ShareResult> Function(ShareParams params) _share;

  @override
  Future<Outcome<ExportShareResult, TransferRejection>> share(
    ExportArtifact artifact,
  ) async {
    final ShareResult result;
    try {
      result = await _share(
        ShareParams(
          files: [
            XFile.fromData(artifact.bytes, mimeType: artifact.format.mimeType),
          ],
          fileNameOverrides: [artifact.fileName],
        ),
      );
    } on MissingPluginException {
      return const Rejected(TransferRejection.shareUnavailable);
    } on UnimplementedError {
      return const Rejected(TransferRejection.shareUnavailable);
    } on Object {
      // The platform's message may carry a path: the user sees only the
      // typed reason (UC-TRANSFER-002 E2).
      return const Rejected(TransferRejection.shareFailed);
    }
    return switch (result.status) {
      ShareResultStatus.dismissed => const Ok(ExportShareResult.dismissed),
      // `unavailable`: the system took the file but cannot say what the user
      // did with it. It was handed over, which is all the app may claim.
      ShareResultStatus.success ||
      ShareResultStatus.unavailable => const Ok(ExportShareResult.shared),
    };
  }
}
```

`lib/features/transfer/di/transfer_file_repository_provider.dart`:

```dart
import 'package:memox/features/transfer/data/repositories/transfer_file_repository_impl.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_file_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_file_repository_provider.g.dart';

@riverpod
TransferFileRepository transferFileRepository(Ref ref) =>
    const TransferFileRepositoryImpl();
```

`lib/features/transfer/di/export_share_repository_provider.dart`:

```dart
import 'package:memox/features/transfer/data/repositories/export_share_repository_impl.dart';
import 'package:memox/features/transfer/domain/repositories/export_share_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'export_share_repository_provider.g.dart';

@riverpod
ExportShareRepository exportShareRepository(Ref ref) =>
    ExportShareRepositoryImpl();
```

After writing the two provider files, run `dart run build_runner build --delete-conflicting-outputs` so their `.g.dart` parts exist before Step 4.


- [ ] **Step 4: Run the tests to verify they pass**

Run: `flutter test test/features/transfer/domain/export_file_name_test.dart test/features/transfer/domain/export_use_cases_test.dart test/features/transfer/data/export_share_repository_impl_test.dart`
Expected: PASS, every test.
Then run `dart format lib test` and `flutter analyze`: no issues.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer test/features/transfer
git commit -m "feat(transfer): build an export and hand it to the share sheet (UC-TRANSFER-002)"
```

### Task 7: Documents and the gate

**Files:**
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md`
- Modify: `docs/features/transfer/README.md`
- Modify: `docs/wbs_BE.md`
- Modify: `docs/_generated/open-questions.md`, `docs/_generated/traceability.md` (generated)

**Interfaces:** none (documents).

- [ ] **Step 1: Update the use cases, the feature README and the WBS**

Apply exactly these diffs (spec §8.1, §10):

`docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`:

```diff
diff --git a/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md b/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
index e74d6f0..f7b050d 100644
--- a/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
+++ b/docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md
@@ -3,11 +3,11 @@ id: UC-TRANSFER-001
 title: Import card hàng loạt vào một deck
 status: ready
 rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006, BR-TRANSFER-009]
-code: []
+code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/commit_import_use_case.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
-**Phạm vi:** sub-project sau — Import (spec §2).
+**Phạm vi:** backend xong ở BE-B3; màn hình là FE-B3 ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md)).
 
 **Actor:** Người dùng
 **Trigger:** Chọn "Import cards" từ card list của một deck loại card, từ empty
@@ -18,7 +18,7 @@ state của card list, hoặc từ lựa chọn tạo phần tử con của mộ
 
 **Main flow:**
 1. Người dùng mở màn import; hệ thống hiển thị deck đích, số card hiện có và
-   ba bước Source → Preview → Import.
+   bốn bước Source → Columns → Preview → Import (spec card transfer §8.1).
 2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV.
 3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-TRANSFER-006) — không
    ghi gì vào database.
@@ -65,6 +65,10 @@ state của card list, hoặc từ lựa chọn tạo phần tử con của mộ
   ghi gì; preview và mapping giữ nguyên.
 - **E5 — Commit thất bại giữa chừng:** một write lỗi → rollback toàn bộ
   (BR-TRANSFER-004); màn import giữ nguyên nguồn, mapping và preview, hiện Try again.
+- **E6 — Mọi hàng đã thành trùng lúc ghi:** giữa Preview và Import, deck nhận
+  các card trùng với mọi hàng sẽ ghi; kiểm tra trùng chạy lại trong transaction
+  (BR-TRANSFER-003) nên không ghi card nào → màn kết quả "Nothing added", deck
+  không đổi kể cả `content_type` (BR-TRANSFER-005); một lối về deck.
 
 ## UI
 
@@ -86,4 +90,8 @@ Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../.
 
 ## Acceptance criteria
 
-- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
+- [ ] **Given** một sub-deck `unset` và một file CSV có header `front,back,tags`, **when** người dùng import, **then** mỗi hàng hợp lệ thành một card mới có đúng một study state mới và tag của nó, deck thành `card`, và không có review log nào (BR-TRANSFER-004, BR-TRANSFER-005).
+- [ ] **Given** một hàng trùng `front`+`back` (sau fold) với card đã có trong deck và một hàng lặp lại trong file, **when** preview, **then** hai hàng đó được đánh dấu trùng và mặc định bị bỏ; bật Include duplicates thì cả hai được ghi thành card mới (BR-TRANSFER-003).
+- [ ] **Given** một file UTF-16 hoặc Latin-1, **when** chọn file, **then** hệ thống từ chối bằng lý do encoding kèm hướng dẫn và không ghi gì (BR-TRANSFER-006).
+- [ ] **Given** preview đã xong và deck vừa nhận deck con, **when** commit, **then** transaction từ chối bằng lý do có kiểu và không ghi gì (BR-TRANSFER-001, E4).
+- [ ] **Given** một write lỗi giữa batch, **when** commit, **then** không card, study state, tag hay `content_type` nào đổi (BR-TRANSFER-004, E5).
```

`docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md`:

```diff
diff --git a/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md b/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md
index 4b34e62..6b9d0b1 100644
--- a/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md
+++ b/docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md
@@ -3,11 +3,11 @@ id: UC-TRANSFER-002
 title: Export card của một deck ra file
 status: ready
 rules: [BR-CARD-012, BR-DECK-015, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-TAG-001, BR-TAG-002, BR-TRANSFER-007, BR-TRANSFER-008, BR-TRANSFER-009, BR-TRANSFER-010, BR-TRANSFER-011, BR-TRANSFER-012, BR-TRANSFER-013, BR-TRANSFER-014]
-code: []
+code: [lib/features/transfer/domain/usecases/build_export_use_case.dart, lib/features/transfer/domain/usecases/share_export_use_case.dart]
 ---
 ## Mục tiêu / Actor / Precondition
 
-**Phạm vi:** sub-project sau — Export (spec §2).
+**Phạm vi:** backend xong ở BE-B3; sheet export là FE-B3 ([spec card transfer](../../../superpowers/specs/2026-09-26-card-transfer-design.md)).
 
 **Actor:** Người dùng
 **Trigger:** Chọn `Export cards` trong overflow menu của card list, hoặc
@@ -94,4 +94,8 @@ Không áp dụng — ứng dụng local-only, không network ([ADR-001](../../.
 
 ## Acceptance criteria
 
-- [ ] OPEN QUESTION: nguồn chưa có acceptance criteria dạng Given/When/Then; Postconditions giữ nguyên văn ở `## Local`.
+- [ ] **Given** một deck loại card, **when** export CSV, TSV hoặc XLSX, **then** file có sáu header canonical, card theo `created_at` rồi `id`, tag theo tên đã fold, và import lại file vào một deck trống cho đúng nội dung đó (BR-TRANSFER-008, BR-TRANSFER-010, BR-TRANSFER-012).
+- [ ] **Given** một ô bắt đầu bằng `=` hoặc một chuỗi như `001`, **when** export XLSX, **then** ô được ghi là text, không thành formula hay số (BR-TRANSFER-012).
+- [ ] **Given** một tập chọn có một id đã bị xoá hoặc đã chuyển deck, **when** export, **then** cả request thất bại có kiểu và không có file (BR-TRANSFER-007, E6).
+- [ ] **Given** bất kỳ export nào, **when** export xong hoặc thất bại, **then** database không đổi (BR-TRANSFER-011).
+- [ ] **Given** người dùng đóng share sheet, **when** share trả về, **then** đó là cancel, không phải lỗi, và app không nói file đã được lưu (BR-TRANSFER-014, A3).
```

`docs/features/transfer/README.md`:

```diff
diff --git a/docs/features/transfer/README.md b/docs/features/transfer/README.md
index 518d2f6..4823cfe 100644
--- a/docs/features/transfer/README.md
+++ b/docs/features/transfer/README.md
@@ -1,13 +1,11 @@
 ---
 feature: transfer
-code: []
+code: [lib/features/transfer/domain, lib/features/transfer/data, lib/features/transfer/di]
 depends_on: [card, deck, tags]
 ---
 ## Phạm vi
 
-**Phạm vi:** sub-project sau — Import (spec §2).
-
-**Phạm vi:** sub-project sau — Export (spec §2).
+**Phạm vi:** Card Transfer: backend BE-B3 xong; màn hình import (kit 11) và sheet export (kit 12) là FE-B3. Thiết kế: [spec card transfer](../../superpowers/specs/2026-09-26-card-transfer-design.md).
 
 Import card hàng loạt vào một deck và export card của một deck ra file (Card Transfer).
 
@@ -18,8 +16,6 @@ nhập tay từng card không phải câu trả lời cho một file nghìn dòn
 khoá trong một cài đặt duy nhất — nhưng nó là export **nội dung**, không phải
 backup, nên không thay thế được sync.
 
-> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.
-
 ## Màn hình → Use case
 
 | Màn hình | UC |
```

`docs/wbs_BE.md`:

```diff
diff --git a/docs/wbs_BE.md b/docs/wbs_BE.md
index d678b21..a2ef155 100644
--- a/docs/wbs_BE.md
+++ b/docs/wbs_BE.md
@@ -84,7 +84,7 @@ Không còn hạng mục nào: BE-A8, hạng mục cuối, xong trong gói 5 và
 |---|---|---|---|---|---|---|
 | BE-B1 | Trash: xoá mềm theo batch, khôi phục, purge (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) | chưa bắt đầu | BE-02, BE-D1 | L | Cột `delete_batch_id` đã có trên `deck` và `card` nhưng chưa có FK; chưa có bảng `delete_batches`; mọi query và lệnh ghi đã lọc `delete_batch_id IS NULL` | Mang migration v2 → v3 (v1 → v2 thuộc gói 2b). Đổi xoá cứng của BR-DECK-022 và BR-DECK-023 thành tombstone; bất biến 33–37 của `schema.md` bắt đầu có hiệu lực |
 | BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
-| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | chưa bắt đầu | BE-04, BE-05 | M–L | Nice-to-have N1 trong [`docs/README.md`](README.md): import CSV/TSV/XLSX, export nội dung | Tuân thủ BR-CORE-001, BR-CORE-002, BR-CORE-004 |
+| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | xong | BE-04, BE-05 | M–L | [spec](superpowers/specs/2026-09-26-card-transfer-design.md) và [plan](superpowers/plans/2026-09-26-card-transfer-backend.md); test trong `test/features/transfer/` và `test/features/card/data/card_transfer_test.dart` | FE-B3 dựng màn 11 và sheet 12 trên năm use case này |
 | BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | chưa bắt đầu | BE-03, BE-04 | M | Cột `source_template_id` và `source_template_version` đã có trong `deck` | — |
 | BE-B5 | Nhắc học hằng ngày (UC-REMINDER-001; BR-REMINDER-001…BR-REMINDER-012) | chưa bắt đầu | BE-03, BE-A4 | M | Các cột `reminder_*` trong `app_settings` đã có | Cần quyết định dependency thông báo cục bộ (xem Điểm chặn) |
 
```

- [ ] **Step 2: Regenerate the generated docs and check them**

Run: `python tools/docs/generate.py`, then `python tools/docs/check.py`
Expected: `PASS — 0 error(s)`, and no warning names a `transfer` file. `docs/_generated/open-questions.md` and `docs/_generated/traceability.md` change.

- [ ] **Step 3: Run the full gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: every gate passes: format, analyze, generated code, docs, the guard and its self-tests, architecture boundaries, and the host suite (about 1,506 tests).

- [ ] **Step 4: Commit and push**

```bash
git add docs
git commit -m "docs(transfer): BE-B3 done — use case criteria, code paths, WBS"
git push origin claude/lexilize-flashcard-app-lpklbs
```

- [ ] **Step 5: Prove the Android build (C10)**

With the owner's approval (it is an action on the shared repository), run the `build-apk` workflow on this branch: GitHub → Actions → Build APK → Run workflow. Expected: green; it compiles `share_plus` and `excel` for Android.
