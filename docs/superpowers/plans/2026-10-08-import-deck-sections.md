# Card import: deck sections (`*` rows) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A row whose `front` cell starts with `*` names a sub-deck of the import target; the rows under it become that deck's cards; the whole import is one transaction.

**Architecture:** The transfer feature splits the parsed `SourceTable` into sections (pure), reads the target and its direct sub-decks through `CardTransferRepository.importTarget`, and builds an `ImportPlan` whose `preview(...)` re-derives destinations as the user decides clashes and edits the default deck name. The card feature owns the write: `CardTransferRepository.importSections` checks every destination first, then creates sub-decks through `DeckRepository.createSubDeck` and writes cards through the existing per-deck path, inside one `mappedTransaction`. Flat files keep today's path untouched.

**Tech Stack:** Flutter 3.47, Dart 3.13, Riverpod 3 (codegen), Drift (`.drift` queries), `excel` 4.0.x, `flutter_test` + goldens.

**Spec:** `docs/superpowers/specs/2026-10-08-import-deck-sections-design.md` (approved 2026-10-08, epic DEV-289). Executors read both.

## Global Constraints

- Gate: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` after every task that touches code; goldens: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` (Linux container only; `--update` only in Task 11).
- Run a subset with `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file|dir>…`, never `flutter test <dir>`.
- After editing a `@riverpod` file or a `.drift` file: `dart run build_runner build --delete-conflicting-outputs`.
- After editing an ARB file: `flutter gen-l10n`.
- Riverpod and Drift only; no BLoC, no Freezed. Guard clauses, no magic values (named constants), no hardcoded colour/spacing/typography (tokens: `AppSpacing`, `context.textStyles`, `context.colors`).
- Every user-facing string is in `lib/l10n/app_en.arb` **and** `lib/l10n/app_vi.arb`, with an `@key` description in EN. Footer labels fit half of a 360 dp footer row (The Short Label Rule).
- Section marker: `*`. Deck name: BR-DECK-020 through `DeckEntity.checkName` (not blank after trim, at most 200 characters). Max depth: `DeckEntity.maxDepth` (10).
- Default deck name: EN "Uncategorized", VI "Chưa phân loại"; editable on the preview.
- Name comparison: `foldText` (trim, NFC, lower case) from `package:memox/core/text/folded_text.dart`.
- Boundary map: `transfer → {card, deck}` (spec §5.2). Transfer imports only `deck/domain/{entities,models,failures}`, never `deck/data` or `deck/domain/usecases`.
- Commits name `DEV-289`; end every commit message with the session attribution lines.
- No log line, error message or test name carries card content beyond fixtures (BR-TRANSFER-006, BR-CORE-005).

## Review Focus

1. **Default name edited to equal a `*` section's name in the same file** → the default group shows "Another deck in this file has this name." and Import stays locked; no two new decks with one name from one file. Test: Task 5.
2. **Mapping or header toggled after choices were made** (Back to Columns, change, Preview again) → every clash choice is cleared, because section indexes may now mean other sections; the edited default name stays. Test: Task 7.
3. **A clash deck trashed, moved or filled with sub-decks between preview and commit** → whole commit refused (`sectionTargetChanged`), nothing written, the preview stays with a banner and "Preview again". Test: Tasks 4 and 7.
4. **One section name repeated non-adjacently (`*A … *B … *a …`)** → one deck `A` holding both runs in source order; ids follow write order so the card list and an export keep that order. Test: Tasks 2 and 4.
5. **`  *Part 1` with leading spaces, `*` alone, and a header row whose front header starts with `*`** → the first is a section `Part 1`; `*` alone is a section with a blank name whose rows are invalid; a header row is never a section. Test: Task 2.

---

### Task 1: Rules, use case and boundary map (docs first)

**Files:**
- Create: `docs/features/transfer/rules/BR-TRANSFER-015-dong-sao-la-ten-deck.md`
- Modify: `docs/features/transfer/rules/BR-TRANSFER-001-dieu-kien-deck-dich-import.md`, `BR-TRANSFER-003-khoa-trung-lap-khi-import.md`, `BR-TRANSFER-004-import-mot-transaction.md`, `BR-TRANSFER-005-deck-unset-thanh-card-khi-import.md`
- Modify: `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
- Modify: `test/architecture/boundary_rules.dart:30`
- Regenerate: `docs/_generated/*` via `python3 tools/docs/generate.py`

**Interfaces:**
- Produces: rule id `BR-TRANSFER-015`, cited by every later task's doc comments.

- [ ] **Step 1: Write BR-TRANSFER-015**

```markdown
---
id: BR-TRANSFER-015
title: Dòng sao là tên deck
status: active
summary: Dòng dữ liệu có ô `front` bắt đầu bằng `*` đặt tên một deck con; các dòng dưới nó là card của deck đó.
superseded_by:
---
## Rule

Một **dòng dữ liệu** (dòng header không bao giờ tính) MUST được coi là **dòng sao** khi ô của cột map vào `front`, sau trim, bắt đầu bằng `*`; các ô khác của dòng sao MUST bị bỏ qua và dòng sao MUST NOT thành card, MUST NOT tính là dòng trống. Tên deck là phần sau `*` đã trim và MUST thoả BR-DECK-020; tên không hợp lệ thì mọi dòng card dưới nó MUST invalid với lý do tên deck. Hai dòng sao có tên trùng nhau sau fold (trim, NFC, chữ thường) MUST là một nhóm: các dòng dưới dòng sao sau nối tiếp nhóm đầu, giữ chính tả của dòng sao đầu. Nhóm không còn card nào để ghi MUST NOT tạo deck. Dòng card nằm trước dòng sao đầu tiên thuộc **deck mặc định** (EN "Uncategorized", VI "Chưa phân loại"), tên sửa được trên Preview và cũng theo BR-DECK-020. Nguồn không có dòng sao nào là nguồn **phẳng** và import như trước. Quy tắc áp dụng cho XLSX, CSV, TSV và văn bản dán. Không có cấp lồng: `**x` là deck tên `*x`. Một card có `front` bắt đầu bằng `*` không import được.

**Enforced by:** rule
**Liên quan:** BR-DECK-020, BR-DECK-021, BR-TRANSFER-001, BR-TRANSFER-003, BR-TRANSFER-004

## Lý do

Chủ dự án soạn từ vựng theo nhóm trong một sheet, mỗi nhóm mở đầu bằng một dòng `*Tên nhóm` (spec 2026-10-08).

## Ví dụ

| front | back |
|---|---|
| \*Part 1 | \*Part 1 |
| 가난하다 | Be poor |
| \*관용어 | \*관용어 |
| 눈이 높다 | Standards are high |

→ hai deck con `Part 1` (1 card) và `관용어` (1 card).

## Edge case

| Case | Expected behaviour |
|---|---|
| `  *Part 1` có khoảng trắng đầu | Dòng sao tên `Part 1` (BR-TRANSFER-015) |
| `*` đứng một mình | Dòng sao tên rỗng; mọi card dưới nó invalid (BR-TRANSFER-015, BR-DECK-020) |
| `*A`, …, `*B`, …, `*a` | Một deck `A` chứa cả hai đoạn, đúng thứ tự nguồn (BR-TRANSFER-015) |
| Dòng sao không có card nào dưới nó | Không tạo deck (BR-TRANSFER-015) |
```

- [ ] **Step 2: Amend BR-TRANSFER-001** — replace the `## Rule` paragraph with:

```markdown
Deck đích của một lần import MUST là deck người dùng mở import (spec 2026-10-08 §4.2). Nguồn **phẳng** (BR-TRANSFER-015) vào deck loại `card` hoặc sub-deck `unset` ghi card thẳng vào deck đích như trước. Nguồn phẳng vào root hoặc deck loại `deck` ghi vào **một** deck con mặc định. Nguồn **có dòng sao** tạo deck con của deck đích, nên deck đích MUST chứa được deck con: deck loại `card` MUST bị từ chối với lý do có kiểu (mở import từ deck cha), và deck ở cấp 10 MUST bị từ chối theo BR-DECK-001. Mọi điều kiện này MUST được kiểm tra lại **bên trong** transaction commit, kể cả từng deck có sẵn được chọn "Thêm vào có sẵn": deck đó MUST vẫn là deck con trực tiếp còn sống của deck đích và vẫn là `card` hoặc `unset`, nếu không cả lần import MUST bị từ chối và không ghi gì.
```

Add `BR-TRANSFER-015, BR-DECK-001` to its `**Liên quan:**` line and the edge-case rows:

```markdown
| File có dòng sao, mở từ deck loại `card` | Preview từ chối, hướng dẫn import từ deck cha (BR-TRANSFER-001) |
| Deck có sẵn được chọn "Thêm vào" bị xoá hoặc chuyển trước lúc ghi | Cả commit bị từ chối, không ghi gì (BR-TRANSFER-001) |
```

- [ ] **Step 3: Amend BR-TRANSFER-003** — append to `## Rule`:

```markdown
Với nguồn có dòng sao (BR-TRANSFER-015), trùng lặp MUST đo theo **từng deck đích**: nhóm "Thêm vào có sẵn" so với card của deck đó cộng các dòng trước trong cùng nhóm; nhóm tạo deck mới chỉ so với các dòng trước trong cùng nhóm. Hai dòng ở hai nhóm khác nhau MUST NOT bị coi là trùng.
```

- [ ] **Step 4: Amend BR-TRANSFER-004 and BR-TRANSFER-005** — append to BR-004's `## Rule`:

```markdown
Với nguồn có dòng sao, cùng **một** transaction đó MUST tạo các deck con theo thứ tự nguồn (BR-DECK-006, vị trí sau các deck con sẵn có) rồi ghi card của từng nhóm; mọi kiểm tra đích MUST chạy xong trước write đầu tiên, và một write lỗi MUST rollback cả deck lẫn card.
```

and to BR-005's `## Rule`:

```markdown
Với nguồn có dòng sao, deck đích `unset` MUST thành `deck` trong cùng transaction khi ít nhất một deck con được tạo (BR-DECK-015); không tạo deck con nào thì `content_type` MUST giữ nguyên.
```

- [ ] **Step 5: Amend UC-TRANSFER-001**
  - Front matter `rules:` gains `BR-TRANSFER-015, BR-DECK-001, BR-DECK-020`.
  - **Trigger:** add "từ action sheet của root deck hoặc deck loại `deck`".
  - **Preconditions:** replace with "Deck đích tồn tại (BR-TRANSFER-001)".
  - **A2:** replace "hệ thống mặc định chọn sheet không rỗng đầu tiên" with "hệ thống mặc định chọn sheet đầu tiên theo thứ tự workbook, kể cả khi nó rỗng (khi đó E2)".
  - Add **A6 — Nguồn chia deck:** "Có dòng sao (BR-TRANSFER-015): Preview hiện khối Decks liệt kê từng deck đích (Mới/Có sẵn, số card) và các dòng nhóm theo deck. Deck trùng tên deck con có sẵn bắt buộc chọn Thêm vào có sẵn hoặc Tạo mới; deck có sẵn loại `deck` thì tự Tạo mới và có ghi chú. Deck mặc định sửa được tên. Import bị khoá tới khi mọi lựa chọn xong và tên hợp lệ. Đổi mapping hoặc header xoá các lựa chọn."
  - Add error flows **E7** (file có dòng sao từ deck loại `card` → banner, không đi tiếp), **E8** (cấp 10 → banner), **E9** (deck có sẵn đổi giữa Preview và Import → không ghi gì, banner "Preview again").
  - Acceptance criteria, add:

```markdown
- [ ] **Given** root `Korean` và sheet đầu có `*Part 1` (2 card) và `*관용어` (1 card), **when** import từ root, **then** root có hai deck con mới `Part 1` (2 card) và `관용어` (1 card), mỗi card một study state mới (BR-TRANSFER-015, BR-TRANSFER-004).
- [ ] **Given** deck đích đã có deck con `Part 1` loại `card` và file có `*Part 1`, **when** preview, **then** Import khoá tới khi chọn; chọn Thêm vào có sẵn thì card trùng với `Part 1` bị bỏ (BR-TRANSFER-003).
- [ ] **Given** file có dòng sao và deck đích loại `card`, **when** preview, **then** hiện lý do có kiểu và không ghi gì (BR-TRANSFER-001).
```

  - `code:` gains `lib/features/transfer/domain/models/import_sections_model.dart`, `lib/features/transfer/domain/models/import_plan_model.dart`.

- [ ] **Step 6: Boundary map** — in `test/architecture/boundary_rules.dart` change line 30:

```dart
  'transfer': {'card', 'deck'},
```

- [ ] **Step 7: Regenerate and check docs**

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py`
Expected: `PASS — 0 error(s), 0 warning(s)`

- [ ] **Step 8: Run the architecture test**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/architecture`
Expected: all pass.

- [ ] **Step 9: Commit**

```bash
git add docs/features/transfer docs/_generated test/architecture/boundary_rules.dart
git commit -m "docs(transfer): DEV-289 BR-TRANSFER-015 and sectioned import rules"
```

---

### Task 2: XLSX reads the first sheet by default (S6)

**Files:**
- Modify: `lib/features/transfer/data/datasources/xlsx_data_source.dart`
- Modify: `lib/features/transfer/data/repositories/transfer_file_repository_impl.dart` (`_read` blank check)
- Modify: `lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart`, `import_commit_bar_widget.dart`
- Test: `test/features/transfer/data/transfer_file_repository_impl_test.dart:326-353`, `test/features/transfer/presentation/card_import_screen_test.dart`

**Interfaces:**
- Produces: `XlsxDataSource.read(bytes, {int? sheetIndex})` — null now means index 0.

- [ ] **Step 1: Rewrite the A2 test** — replace the test at line 326 with:

```dart
    test('the first sheet is read by default, even empty; any sheet can be (A2)', () async {
      final bytes = _workbook({
        'Notes': [],
        'Vocab': [
          [TextCellValue('front'), TextCellValue('back')],
          [TextCellValue('menu'), TextCellValue('thực đơn')],
        ],
      });

      final first = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect((first.sheetIndex, first.isBlank), (0, true));
      expect(first.sheetNames, ['Notes', 'Vocab']);

      final vocab = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
        sheetIndex: 1,
      );
      expect(vocab.sheetNames, ['Notes', 'Vocab']);
      expect(vocab.sheetIndex, 1);
      expect(vocab.rows.last, ['menu', 'thực đơn']);
    });
```

Decided (the sheet chip in `import_source_section_widget.dart:302` needs a `table`): a workbook with **several** sheets whose chosen sheet is blank reads as `Ok` with the blank table and its `sheetNames`, so the chip stays and the user can switch (A2); a single-sheet blank workbook, CSV, TSV and pasted text stay `Rejected(emptySource)`. So the first expectation above becomes:

```dart
      final first = await _table(
        FileSource(bytes: bytes, format: TransferFormat.xlsx),
      );
      expect((first.sheetIndex, first.isBlank), (0, true));
      expect(first.sheetNames, ['Notes', 'Vocab']);
```

and add a test that a one-sheet blank workbook is still `emptySource`.

In `transfer_file_repository_impl.dart` `_read`, change the blank check to:

```dart
  if (table case Ok(:final value)
      when value.isBlank && value.sheetNames.length <= 1) {
    return const Rejected(TransferRejection.emptySource);
  }
```

In `import_mapping_section_widget.dart`, when `table.isBlank`, show `MxInlineBanner(tone: MxBannerTone.warning, title: l10n.importProblemEmptyTitle, message: l10n.importProblemEmptyBody)` instead of the mapping rows and the mapping-incomplete banner; in `import_commit_bar_widget.dart` the Columns step's action is `null` while `draft.table?.isBlank ?? false`. Add a widget test to `card_import_screen_test.dart`: a two-sheet workbook with an empty first sheet shows the empty banner and the sheet chip; choosing sheet 2 shows the mapping rows.

- [ ] **Step 2: Run it, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/data/transfer_file_repository_impl_test.dart`
Expected: FAIL — the default read picks `Vocab`.

- [ ] **Step 3: Implement** — in `xlsx_data_source.dart` delete `_firstFilled` and set:

```dart
  /// The workbook's sheet names in order, and the rows of the sheet at
  /// [sheetIndex], or of the first sheet when it is null (UC-TRANSFER-001
  /// A2, spec 2026-10-08 S6). Every cell reads as text. Throws when the
  /// bytes are not a readable workbook.
  ({List<String> sheetNames, int sheetIndex, List<List<String>> rows}) read(
    Uint8List bytes, {
    int? sheetIndex,
  }) {
    final sheets = Excel.decodeBytes(bytes).tables;
    final sheetNames = sheets.keys.toList();
    final chosen = sheetIndex ?? 0;
    if (chosen >= sheetNames.length) {
      return (sheetNames: sheetNames, sheetIndex: chosen, rows: const []);
    }
    return (
      sheetNames: sheetNames,
      sheetIndex: chosen,
      rows: [
        for (final row in sheets[sheetNames[chosen]]!.rows)
          [for (final cell in row) _textOf(cell?.value)],
      ],
    );
  }
```

(Only the chosen sheet is decoded into text now, which also saves work on large workbooks.)

- [ ] **Step 4: Run, expect pass** — same command. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer test/features/transfer
git commit -m "feat(transfer): DEV-289 read the first XLSX sheet by default (S6)"
```

---

### Task 3: Sections and row classification (pure domain)

**Files:**
- Create: `lib/features/transfer/domain/models/import_sections_model.dart`
- Modify: `lib/features/transfer/domain/models/import_preview_model.dart` (extract `classifyRows`, add `ImportRow.deckNameReason`)
- Test: `test/features/transfer/domain/import_sections_model_test.dart`

**Interfaces:**
- Produces:
  - `const importSectionMarker = '*';`
  - `final class ImportSection { String name; bool isDefault; List<int> rowIndexes; }`
  - `List<ImportSection>? splitSections({required SourceTable table, required ColumnMapping mapping, required bool hasHeaderRow})` — null for a flat source.
  - `List<ImportRow> classifyRows({required SourceTable table, required Iterable<int> rowIndexes, required ColumnMapping mapping, required Set<CardFoldedPair> existing})`
  - `ImportRow.deckNameReason` (`DeckRejection?`, from `package:memox/features/deck/domain/failures/deck_failure.dart`).

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

List<ImportSection>? _split(List<List<String>> rows, {bool hasHeaderRow = true}) =>
    splitSections(
      table: SourceTable(rows: rows),
      mapping: _faces,
      hasHeaderRow: hasHeaderRow,
    );

List<(String, bool, List<int>)> _shape(List<ImportSection> sections) => [
  for (final s in sections) (s.name, s.isDefault, s.rowIndexes),
];

void main() {
  test('no section row: a flat source (BR-TRANSFER-015)', () {
    expect(_split([['Term', 'Meaning'], ['a', 'b']]), isNull);
  });

  test('each * row opens a section; rows before the first go to the default', () {
    final sections = _split([
      ['Term', 'Meaning'],
      ['x', 'y'],
      ['*Part 1', '*Part 1'],
      ['가난하다', 'Be poor'],
      ['  *관용어 ', ''],
      ['눈이 높다', 'Standards are high'],
    ])!;
    expect(_shape(sections), [
      ('', true, [1]),
      ('Part 1', false, [3]),
      ('관용어', false, [5]),
    ]);
  });

  test('names that fold equal are one section, kept in source order', () {
    final sections = _split([
      ['Term', 'Meaning'],
      ['*A', ''],
      ['a1', 'x'],
      ['*B', ''],
      ['b1', 'x'],
      ['*a ', ''],
      ['a2', 'x'],
    ])!;
    expect(_shape(sections), [
      ('A', false, [2, 6]),
      ('B', false, [4]),
    ]);
  });

  test('* alone is a section with a blank name; ** is a name starting with *', () {
    final sections = _split([
      ['Term', 'Meaning'],
      ['*', ''],
      ['a', 'b'],
      ['**x', ''],
      ['c', 'd'],
    ])!;
    expect(_shape(sections), [
      ('', false, [2]),
      ('*x', false, [4]),
    ]);
  });

  test('a header is never a section; without a header row 0 can be', () {
    expect(_split([['*Term', 'Meaning'], ['a', 'b']]), isNull);
    expect(
      _shape(_split([['*Part', ''], ['a', 'b']], hasHeaderRow: false)!),
      [('Part', false, [1])],
    );
  });

  test('blank rows before the first section stay out unless the default holds text', () {
    expect(
      _shape(_split([['Term', 'Meaning'], ['', ''], ['*A', ''], ['a', 'b']])!),
      [('A', false, [3])],
    );
  });

  test('classifyRows measures duplicates within the rows it is given only', () {
    final table = SourceTable(rows: [
      ['Term', 'Meaning'],
      ['a', 'b'],
      ['a', 'b'],
      ['c', 'd'],
    ]);
    final rows = classifyRows(
      table: table,
      rowIndexes: const [1, 3],
      mapping: _faces,
      existing: {(front: 'c', back: 'd')},
    );
    expect([for (final r in rows) (r.rowNumber, r.kind)], [
      (2, ImportRowKind.ready),
      (4, ImportRowKind.duplicateInDeck),
    ]);
  });
}
```

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/domain/import_sections_model_test.dart`
Expected: FAIL — `import_sections_model.dart` does not exist.

- [ ] **Step 3: Extract `classifyRows`** — in `import_preview_model.dart`, move the loop body of `buildImportPreview` into:

```dart
/// Each row of [rowIndexes] (indexes into [table]), in order: blank,
/// invalid, duplicate of [existing], duplicate of an earlier row given here,
/// ready (BR-TRANSFER-002, BR-TRANSFER-003). The mapping must be complete.
List<ImportRow> classifyRows({
  required SourceTable table,
  required Iterable<int> rowIndexes,
  required ColumnMapping mapping,
  required Set<CardFoldedPair> existing,
}) {
  final firstRowOf = <CardFoldedPair, int>{};
  final rows = <ImportRow>[];
  for (final index in rowIndexes) {
    // …the existing body of the for-loop, unchanged, with `index`…
  }
  return rows;
}

ImportPreview buildImportPreview({
  required SourceTable table,
  required ColumnMapping mapping,
  required bool hasHeaderRow,
  required Set<CardFoldedPair> existing,
}) => ImportPreview(
  classifyRows(
    table: table,
    rowIndexes: [
      for (var i = hasHeaderRow ? 1 : 0; i < table.rows.length; i++) i,
    ],
    mapping: mapping,
    existing: existing,
  ),
);
```

Also make the `mapped`/blank test reusable: move `String? cell(TransferField field)` into a private top-level `String? _cellOf(List<String> cells, ColumnMapping mapping, TransferField field)` and add:

```dart
/// Whether every mapped cell of [cells] is empty after trim (BR-TRANSFER-002).
bool isBlankRow(List<String> cells, ColumnMapping mapping) => [
  for (final field in TransferField.values) _cellOf(cells, mapping, field),
].every((value) => value == null || value.trim().isEmpty);
```

Add to `ImportRow` (constructor param `this.deckNameReason`):

```dart
  /// Why the deck this row's section names is refused (BR-TRANSFER-015,
  /// BR-DECK-020); such a row is invalid whatever its cells hold.
  final DeckRejection? deckNameReason;
```

- [ ] **Step 4: Write `import_sections_model.dart`**

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// A data row whose `front` cell starts with this names a deck
/// (BR-TRANSFER-015).
const importSectionMarker = '*';

/// The rows of one deck in a sectioned source (BR-TRANSFER-015).
final class ImportSection {
  const ImportSection({
    required this.name,
    required this.isDefault,
    required this.rowIndexes,
  });

  /// The text after the marker, trimmed; empty for the default section,
  /// which the preview names (S4).
  final String name;

  /// The rows before the first section row.
  final bool isDefault;

  /// Indexes into the table of the card rows, in source order.
  final List<int> rowIndexes;
}

/// The sections of [table] in order of first appearance, or null when no
/// data row is a section row (a flat source). Names that fold equal are one
/// section. The default section comes first, and only when a row before
/// the first section row holds text.
List<ImportSection>? splitSections({
  required SourceTable table,
  required ColumnMapping mapping,
  required bool hasHeaderRow,
}) {
  final frontColumn = mapping.columnOf(TransferField.front);
  if (frontColumn == null) return null;
  final defaultRows = <int>[];
  final names = <String>[];
  final rowsByKey = <String, List<int>>{};
  String? currentKey;
  for (var index = hasHeaderRow ? 1 : 0; index < table.rows.length; index++) {
    final cells = table.rows[index];
    final front = frontColumn < cells.length ? cells[frontColumn].trim() : '';
    if (front.startsWith(importSectionMarker)) {
      final name = front.substring(importSectionMarker.length).trim();
      final key = foldText(name);
      if (!rowsByKey.containsKey(key)) {
        names.add(name);
        rowsByKey[key] = [];
      }
      currentKey = key;
      continue;
    }
    if (currentKey == null) {
      defaultRows.add(index);
      continue;
    }
    rowsByKey[currentKey]!.add(index);
  }
  if (names.isEmpty) return null;
  final hasDefault = defaultRows.any(
    (index) => !isBlankRow(table.rows[index], mapping),
  );
  return [
    if (hasDefault)
      ImportSection(name: '', isDefault: true, rowIndexes: defaultRows),
    for (final name in names)
      ImportSection(
        name: name,
        isDefault: false,
        rowIndexes: rowsByKey[foldText(name)]!,
      ),
  ];
}
```

- [ ] **Step 5: Run the new and the old preview tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/domain`
Expected: PASS (including the unchanged `import_preview_model_test.dart`).

- [ ] **Step 6: Commit**

```bash
git add lib/features/transfer/domain/models test/features/transfer/domain/import_sections_model_test.dart
git commit -m "feat(transfer): DEV-289 split a source into * sections (BR-TRANSFER-015)"
```

---

### Task 4: The card feature reads and writes a sectioned import

**Files:**
- Modify: `lib/core/database/queries/card_row_queries.drift` (two queries)
- Modify: `lib/features/card/data/datasources/card_dao.dart`
- Create: `lib/features/card/domain/models/card_import_target_model.dart`
- Create: `lib/features/card/domain/models/card_import_section_model.dart`
- Modify: `lib/features/card/domain/failures/card_failure.dart`
- Modify: `lib/features/card/domain/repositories/card_transfer_repository.dart`
- Modify: `lib/features/card/data/repositories/card_transfer_repository_impl.dart`
- Modify: `lib/features/card/di/card_transfer_repository_provider.dart`
- Test: `test/features/card/data/card_transfer_sections_test.dart`
- Modify (constructor): every `CardTransferRepositoryImpl(` call in `test/` (grep) gains the deck repository argument.

**Interfaces:**
- Consumes: `DeckRepository.createSubDeck` (deck domain), `DeckEntity.checkCreateCard`, `DeckEntity.checkCreateSubDeck`, `DeckEntity.maxDepth`.
- Produces:

```dart
// card_import_target_model.dart
final class CardImportChild { String id; String name; bool canHoldCards; Set<CardFoldedPair> pairs; }
final class CardImportTarget { bool holdsCards; bool canHoldCards; bool hasRoomBelow; Set<CardFoldedPair> pairs; List<CardImportChild> children; bool get canHoldDecks; }
// card_import_section_model.dart
final class CardImportSection { String name; String? existingDeckId; List<CardDraft> drafts; }
final class CardImportSectionResult { String? deckId; int written; List<int> skippedIndexes; }
// CardTransferRepository
Future<CardImportTarget?> importTarget(String deckId);
Future<Outcome<List<CardImportSectionResult>, CardRejection>> importSections({
  required String targetDeckId,
  required List<CardImportSection> sections,
  required bool includeDuplicates,
  DateTime? now,
});
// CardRejection
notADeckContainer, depthExceeded, sectionTargetChanged
```

- [ ] **Step 1: Write the failing tests** (`test/features/card/data/card_transfer_sections_test.dart`)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/data/repositories/card_transfer_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_import_section_model.dart';
import 'package:memox/features/deck/data/datasources/deck_tree_data_source.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// Spec 2026-10-08 §4.5: one transaction makes the section decks and their
// cards, checking every destination before the first write.

DateTime _now() => DateTime(2026, 10, 8);

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

CardImportSection _section(String name, List<String> fronts, {String? into}) =>
    CardImportSection(
      name: name,
      existingDeckId: into,
      drafts: [for (final f in fronts) CardDraft(front: f, back: 'b')],
    );

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardTransferRepositoryImpl cards;
  late DeckEntity root;
  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardTransferRepositoryImpl(
      db,
      CardRepositoryImpl(
        db,
        ScheduleRepositoryImpl(db, now: _now),
        TagRepositoryImpl(db, now: _now),
        DeckTreeDataSource(db),
        now: _now,
      ),
      decks,
    );
    root = await decks.root('Korean');
  });
  tearDown(() => db.close());

  Future<List<(String, int)>> children(String parentId) async => [
    for (final row in await db
        .customSelect(
          'SELECT d.name, (SELECT COUNT(*) FROM card c WHERE c.deck_id = d.id) AS n '
          'FROM deck d WHERE d.parent_id = ? ORDER BY d.sibling_position',
          variables: [Variable<String>(parentId)],
        )
        .get())
      (row.read<String>('name'), row.read<int>('n')),
  ];

  test('importTarget: the target, its direct sub-decks in order, and their faces', () async {
    final words = await decks.sub(root.id, 'Words');
    final grammar = await decks.sub(root.id, 'Grammar');
    await decks.sub(grammar.id, 'Particles');
    await insertCard(db, id: 'c', deckId: words.id, front: ' Menu', back: 'x');

    final target = (await cards.importTarget(root.id))!;

    expect((target.holdsCards, target.canHoldCards, target.canHoldDecks), (false, false, true));
    expect([for (final c in target.children) (c.name, c.canHoldCards)], [
      ('Words', true),
      ('Grammar', false),
    ]);
    expect(target.children.first.pairs, {(front: 'menu', back: 'x')});
    expect(await cards.importTarget('gone'), isNull);
  });

  test('sections become sub-decks in source order, cards in source order', () async {
    final result = await cards.importSections(
      targetDeckId: root.id,
      sections: [_section('Part 1', ['a', 'b']), _section('관용어', ['c'])],
      includeDuplicates: false,
    );

    expect(result, isA<Ok<List<CardImportSectionResult>, CardRejection>>());
    expect(await children(root.id), [('Part 1', 2), ('관용어', 1)]);
    expect(await _count(db, 'card_schedule'), 3);
  });

  test('an unset target becomes a deck of decks', () async {
    final unset = await decks.sub(root.id, 'Topik');
    await cards.importSections(
      targetDeckId: unset.id,
      sections: [_section('A', ['a'])],
      includeDuplicates: false,
    );
    expect((await decks.findById(unset.id))!.contentType, DeckContentType.deck);
  });

  test('add to existing writes into it and skips its duplicates (BR-TRANSFER-003)', () async {
    final part = await decks.sub(root.id, 'Part 1');
    await insertCard(db, id: 'old', deckId: part.id, front: 'a', back: 'b');

    final result = await cards.importSections(
      targetDeckId: root.id,
      sections: [_section('Part 1', ['a', 'z'], into: part.id)],
      includeDuplicates: false,
    );

    final section = (result as Ok<List<CardImportSectionResult>, CardRejection>).value.single;
    expect((section.deckId, section.written, section.skippedIndexes), (part.id, 1, [0]));
    expect(await children(root.id), [('Part 1', 2)]);
  });

  test('a section left with nothing to write makes no deck', () async {
    final result = await cards.importSections(
      targetDeckId: root.id,
      sections: [_section('Empty', [])],
      includeDuplicates: false,
    );
    expect((result as Ok).value.single.deckId, isNull);
    expect(await children(root.id), isEmpty);
  });

  test('an existing deck that moved away refuses the whole import, nothing written', () async {
    final part = await decks.sub(root.id, 'Part 1');
    final other = await decks.root('Other');
    await decks.moveDeck(deckId: part.id, newParentId: other.id);

    final result = await cards.importSections(
      targetDeckId: root.id,
      sections: [_section('New', ['a']), _section('Part 1', ['b'], into: part.id)],
      includeDuplicates: false,
    );

    expect((result as Rejected).reason, CardRejection.sectionTargetChanged);
    expect(await _count(db, 'card'), 0);
    expect(await children(root.id), isEmpty);
  });

  test('a deck of cards cannot take sections (BR-TRANSFER-001)', () async {
    final words = await decks.sub(root.id, 'Words');
    await insertCard(db, id: 'c', deckId: words.id, front: 'a', back: 'b');

    final result = await cards.importSections(
      targetDeckId: words.id,
      sections: [_section('A', ['x'])],
      includeDuplicates: false,
    );

    expect((result as Rejected).reason, CardRejection.notADeckContainer);
  });

  test('a repeated name keeps both runs in one deck, in source order (Review Focus 4)', () async {
    await cards.importSections(
      targetDeckId: root.id,
      sections: [_section('A', ['a1', 'a2', 'a3'])],
      includeDuplicates: false,
    );
    final ids = await db
        .customSelect('SELECT front FROM card ORDER BY id')
        .map((r) => r.read<String>('front'))
        .get();
    expect(ids, ['a1', 'a2', 'a3']);
  });
}
```

Add `import 'package:drift/drift.dart' show Variable;` to the imports.

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card/data/card_transfer_sections_test.dart`
Expected: FAIL to compile — `importTarget`, `importSections`, the 3-argument constructor do not exist.

- [ ] **Step 3: Queries** — append to `card_row_queries.drift`:

```sql
-- Spec 2026-10-08 §4.3: the live direct sub-decks of :parent_id, in
-- sibling order.
liveChildDecks(:parent_id AS TEXT):
SELECT id, name, content_type FROM deck
WHERE parent_id = :parent_id AND delete_batch_id IS NULL
ORDER BY sibling_position, id;

-- BR-TRANSFER-003 per destination: the folded faces of the live cards of
-- every live direct sub-deck of :parent_id, in one read.
liveCardFacesUnder(:parent_id AS TEXT):
SELECT c.deck_id, c.front_folded, c.back_folded FROM card c
INNER JOIN deck d ON d.id = c.deck_id
WHERE d.parent_id = :parent_id
  AND d.delete_batch_id IS NULL
  AND c.delete_batch_id IS NULL;
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 4: DAO** — add to `CardDao`:

```dart
  /// The live direct sub-decks of [parentId], in sibling order.
  Future<List<LiveChildDecksResult>> childDecks(String parentId) =>
      liveChildDecks(parentId).get();

  /// The folded faces of the live cards of each live direct sub-deck of
  /// [parentId] (BR-TRANSFER-003), keyed by deck id.
  Future<Map<String, Set<CardFoldedPair>>> foldedPairsUnder(
    String parentId,
  ) async {
    final byDeck = <String, Set<CardFoldedPair>>{};
    for (final row in await liveCardFacesUnder(parentId).get()) {
      (byDeck[row.deckId] ??= {}).add(
        (front: row.frontFolded, back: row.backFolded),
      );
    }
    return byDeck;
  }
```

- [ ] **Step 5: Models**

```dart
// lib/features/card/domain/models/card_import_target_model.dart
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';

/// A live direct sub-deck of an import target (spec 2026-10-08 §4.3).
final class CardImportChild {
  const CardImportChild({
    required this.id,
    required this.name,
    required this.canHoldCards,
    required this.pairs,
  });

  final String id;
  final String name;

  /// `unset` or a deck of cards (BR-DECK-009, BR-DECK-010).
  final bool canHoldCards;

  /// The folded faces of its live cards (BR-TRANSFER-003).
  final Set<CardFoldedPair> pairs;
}

/// What an import preview knows of its target (spec 2026-10-08 §4.2).
final class CardImportTarget {
  const CardImportTarget({
    required this.holdsCards,
    required this.canHoldCards,
    required this.hasRoomBelow,
    required this.pairs,
    required this.children,
  });

  /// A deck of cards (BR-DECK-009).
  final bool holdsCards;

  /// `unset` or a deck of cards: a flat import writes into it.
  final bool canHoldCards;

  /// Below level 10 (BR-DECK-001).
  final bool hasRoomBelow;

  /// The folded faces of its own live cards (BR-TRANSFER-003).
  final Set<CardFoldedPair> pairs;

  /// Its live direct sub-decks, in sibling order.
  final List<CardImportChild> children;

  /// Whether a section may become a sub-deck of it (BR-TRANSFER-001).
  bool get canHoldDecks => !holdsCards && hasRoomBelow;
}
```

```dart
// lib/features/card/domain/models/card_import_section_model.dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';

/// One deck of a sectioned import (spec 2026-10-08 §4.5).
final class CardImportSection {
  const CardImportSection({
    required this.name,
    required this.existingDeckId,
    required this.drafts,
  });

  /// The name of the sub-deck made for it; unused when [existingDeckId] is
  /// set.
  final String name;

  /// "Add to existing": a live direct sub-deck of the target that takes
  /// cards. Null: a new sub-deck, made only when a draft is kept.
  final String? existingDeckId;
  final List<CardDraft> drafts;
}

/// What one section wrote.
final class CardImportSectionResult {
  const CardImportSectionResult({
    required this.deckId,
    required this.written,
    required this.skippedIndexes,
  });

  /// Null when nothing was written and no deck was made.
  final String? deckId;
  final int written;

  /// The places, in the section's drafts, the commit's re-check dropped
  /// (BR-TRANSFER-003).
  final List<int> skippedIndexes;
}
```

Add to `CardRejection`:

```dart
  /// BR-TRANSFER-001: sections need a target that takes sub-decks; this one
  /// holds cards.
  notADeckContainer,

  /// BR-DECK-001: a section's deck would go below level 10.
  depthExceeded,

  /// BR-TRANSFER-001: a deck chosen for "Add to existing" is gone, moved,
  /// or no longer takes cards.
  sectionTargetChanged,
```

Then fix every exhaustive `switch` on `CardRejection` the analyzer reports (for example `import_labels_widget.dart` `_invalid` already has `_ =>`; card presentation message helpers may need the three values mapped to their generic "can't add here" copy).

- [ ] **Step 6: Repository contract** — add to `CardTransferRepository`:

```dart
  /// Spec 2026-10-08 §4.2: [deckId] as an import target, with its direct
  /// sub-decks and the faces of their cards, in one read; null when it is
  /// gone.
  Future<CardImportTarget?> importTarget(String deckId);

  /// Spec 2026-10-08 §4.5, in one transaction: the target and every
  /// "Add to existing" deck are checked before the first write
  /// (BR-TRANSFER-001); then, section by section in order, the duplicate
  /// policy is applied against the section's deck as it is now and within
  /// the section (BR-TRANSFER-003), a new sub-deck is made only when a
  /// draft is kept (BR-TRANSFER-015), and the drafts are written as
  /// [importCards] writes them (BR-TRANSFER-004, BR-TRANSFER-005).
  Future<Outcome<List<CardImportSectionResult>, CardRejection>>
  importSections({
    required String targetDeckId,
    required List<CardImportSection> sections,
    required bool includeDuplicates,
    DateTime? now,
  });
```

- [ ] **Step 7: Implementation** — in `CardTransferRepositoryImpl`, add the `DeckRepository _decks` constructor parameter (third positional), extract the duplicate policy, and implement:

```dart
  CardTransferRepositoryImpl(
    this._db,
    this._cards,
    this._decks, {
    DateTime Function()? now,
  }) : _dao = CardDao(_db),
       _listDao = CardListDao(_db),
       _now = now ?? DateTime.now;

  final DeckRepository _decks;

  /// The drafts the duplicate policy keeps against [taken], which grows as
  /// it goes, and the places of those it drops (BR-TRANSFER-003).
  static (List<CardDraft>, List<int>) _keep(
    List<CardDraft> drafts,
    Set<CardFoldedPair> taken, {
    required bool includeDuplicates,
  }) {
    final kept = <CardDraft>[];
    final skipped = <int>[];
    for (final (index, draft) in drafts.indexed) {
      final pair = (front: foldText(draft.front), back: foldText(draft.back));
      if (!includeDuplicates && taken.contains(pair)) {
        skipped.add(index);
        continue;
      }
      taken.add(pair);
      kept.add(draft);
    }
    return (kept, skipped);
  }
```

Use `_keep` inside `importCards` (replace its inline loop; behaviour unchanged). Then:

```dart
  static bool _takesCards(String contentType) =>
      DeckEntity.checkCreateCard(
        parentContentType: DeckContentType.values.byName(contentType),
      ) is Ok;

  @override
  Future<CardImportTarget?> importTarget(String deckId) => guardDatabase(
    () => _db.transaction(() async {
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return null;
      final pairsByChild = await _dao.foldedPairsUnder(deckId);
      return CardImportTarget(
        holdsCards: deck.contentType == DeckContentType.card.name,
        canHoldCards: _takesCards(deck.contentType),
        hasRoomBelow: deck.depth < DeckEntity.maxDepth,
        pairs: await _dao.foldedPairs(deckId),
        children: [
          for (final child in await _dao.childDecks(deckId))
            CardImportChild(
              id: child.id,
              name: child.name,
              canHoldCards: _takesCards(child.contentType),
              pairs: pairsByChild[child.id] ?? {},
            ),
        ],
      );
    }),
  );

  @override
  Future<Outcome<List<CardImportSectionResult>, CardRejection>>
  importSections({
    required String targetDeckId,
    required List<CardImportSection> sections,
    required bool includeDuplicates,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      // Every check before the first write, so a refusal leaves nothing
      // behind (BR-TRANSFER-004).
      for (final section in sections) {
        for (final draft in section.drafts) {
          if (draft.check() case Rejected(:final reason)) {
            return Rejected(reason);
          }
        }
      }
      final target = await _dao.deckRow(targetDeckId);
      if (target == null) return const Rejected(CardRejection.notFound);
      final takesDecks = DeckEntity.checkCreateSubDeck(
        parentDepth: target.depth,
        parentContentType: DeckContentType.values.byName(target.contentType),
      );
      if (takesDecks case Rejected(:final reason)) {
        return Rejected(
          reason == DeckRejection.depthExceeded
              ? CardRejection.depthExceeded
              : CardRejection.notADeckContainer,
        );
      }
      final children = {
        for (final child in await _dao.childDecks(targetDeckId))
          child.id: child,
      };
      for (final section in sections) {
        final id = section.existingDeckId;
        if (id == null) continue;
        final child = children[id];
        if (child == null || !_takesCards(child.contentType)) {
          return const Rejected(CardRejection.sectionTargetChanged);
        }
      }

      final results = <CardImportSectionResult>[];
      for (final section in sections) {
        final existingId = section.existingDeckId;
        final taken = existingId == null
            ? <CardFoldedPair>{}
            : await _dao.foldedPairs(existingId);
        final (kept, skipped) = _keep(
          section.drafts,
          taken,
          includeDuplicates: includeDuplicates,
        );
        if (kept.isEmpty) {
          results.add(
            CardImportSectionResult(
              deckId: existingId,
              written: 0,
              skippedIndexes: skipped,
            ),
          );
          continue;
        }
        final deckId = existingId ?? await _newSubDeck(targetDeckId, section.name, at);
        final written = await _cards.insertCards(
          deckId: deckId,
          drafts: kept,
          now: at,
        );
        if (written case Rejected(:final reason)) {
          // Checked above, so this is a bug; throwing rolls the batch back.
          throw StateError('import section refused after its check: $reason');
        }
        results.add(
          CardImportSectionResult(
            deckId: deckId,
            written: kept.length,
            skippedIndexes: skipped,
          ),
        );
      }
      return Ok(results);
    });
  }

  /// A sub-deck the preview already named and the target was checked for;
  /// a refusal here is a bug, and throwing rolls the batch back.
  Future<String> _newSubDeck(String parentId, String name, DateTime at) async =>
      switch (await _decks.createSubDeck(
        parentId: parentId,
        name: name,
        now: at,
      )) {
        Ok(:final value) => value.id,
        Rejected(:final reason) => throw StateError(
          'import section deck refused: $reason',
        ),
      };
```

Imports to add: `deck_entity.dart`, `deck_content_type_model.dart`, `deck_failure.dart`, `deck_repository.dart` (deck domain), the two new card models.

- [ ] **Step 8: DI** — `card_transfer_repository_provider.dart`:

```dart
import 'package:memox/features/deck/di/deck_repository_provider.dart';

@riverpod
CardTransferRepository cardTransferRepository(Ref ref) =>
    CardTransferRepositoryImpl(
      ref.watch(databaseProvider),
      ref.watch(cardRepositoryProvider),
      ref.watch(deckRepositoryProvider),
    );
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 9: Fix the other constructor calls** — `grep -rn "CardTransferRepositoryImpl(" test lib` and pass a `DeckRepositoryImpl(db, now: _now)` (each file already has `decks`) as the third argument. Fakes that `implements CardTransferRepository` keep compiling through `noSuchMethod`.

- [ ] **Step 10: Run the card and transfer suites**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/card test/features/transfer test/architecture`
Expected: PASS.

- [ ] **Step 11: Commit**

```bash
git add lib/core/database lib/features/card test/features/card test/features/transfer
git commit -m "feat(card): DEV-289 import target read and sectioned import write"
```

---

### Task 5: The import plan and its preview (pure domain)

**Files:**
- Create: `lib/features/transfer/domain/models/import_plan_model.dart`
- Modify: `lib/features/transfer/domain/models/import_preview_model.dart` (groups, destinations)
- Test: `test/features/transfer/domain/import_plan_model_test.dart`

**Interfaces:**
- Consumes: `splitSections`, `classifyRows`, `isBlankRow` (Task 3); `CardImportTarget`, `CardImportChild` (Task 4); `DeckEntity.checkName`.
- Produces:

```dart
enum ImportSectionChoice { addToExisting, createNew }
enum ImportNameProblem { blank, tooLong, takenInFile }
sealed class ImportDestination {}            // IntoTarget, IntoNewDeck, IntoExistingDeck(deckId), Undecided
final class ImportClash { String deckId; String name; bool canHoldCards; }
final class ImportGroup { String name; bool isDefault; ImportDestination destination; ImportClash? clash; ImportNameProblem? nameProblem; List<ImportRow> rows; int willWrite({required bool includeDuplicates}); List<ImportRow> rowsToWrite({required bool includeDuplicates}); }
final class ImportPreview { ImportPreview(List<ImportRow> rows) /* flat */; ImportPreview.sectioned(List<ImportGroup> groups); List<ImportGroup> groups; bool isSectioned; List<ImportRow> rows; int undecided; bool hasNameProblem; bool get canCommit; … existing counters }
final class ImportPlan { SourceTable table; ColumnMapping mapping; bool hasHeaderRow; CardImportTarget target; List<ImportSection>? sections; ImportPreview preview({required String defaultDeckName, required Map<int, ImportSectionChoice> choices}); }
```

- [ ] **Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

const _faces = ColumnMapping({0: TransferField.front, 1: TransferField.back});

CardImportTarget _root({List<CardImportChild> children = const []}) =>
    CardImportTarget(
      holdsCards: false,
      canHoldCards: false,
      hasRoomBelow: true,
      pairs: const {},
      children: children,
    );

ImportPlan _plan(List<List<String>> rows, CardImportTarget target) {
  final table = SourceTable(rows: rows);
  return ImportPlan(
    table: table,
    mapping: _faces,
    hasHeaderRow: true,
    target: target,
    sections: splitSections(table: table, mapping: _faces, hasHeaderRow: true),
  );
}

const _sheet = [
  ['Term', 'Meaning'],
  ['loose', 'x'],
  ['*Part 1', ''],
  ['a', 'b'],
  ['a', 'b'],
  ['*관용어', ''],
  ['c', 'd'],
];

void main() {
  test('groups: the default first, then sections; all new without a clash', () {
    final preview = _plan(_sheet, _root()).preview(
      defaultDeckName: 'Uncategorized',
      choices: const {},
    );
    expect(preview.isSectioned, isTrue);
    expect([for (final g in preview.groups) (g.name, g.destination)], [
      ('Uncategorized', const IntoNewDeck()),
      ('Part 1', const IntoNewDeck()),
      ('관용어', const IntoNewDeck()),
    ]);
    // The repeat inside Part 1 is a duplicate of its own section only.
    expect(preview.groups[1].rows.map((r) => r.kind), [
      ImportRowKind.ready,
      ImportRowKind.duplicateInSource,
    ]);
    expect(preview.canCommit, isTrue);
  });

  test('a clash with a deck of cards is undecided until chosen (§4.3)', () {
    final plan = _plan(_sheet, _root(children: [
      const CardImportChild(
        id: 'p1',
        name: 'part 1',
        canHoldCards: true,
        pairs: {(front: 'a', back: 'b')},
      ),
    ]));

    final undecided = plan.preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(undecided.groups[1].destination, const Undecided());
    expect((undecided.undecided, undecided.canCommit), (1, false));
    // Shown against the existing deck, as "Add" would see it.
    expect(undecided.groups[1].rows.first.kind, ImportRowKind.duplicateInDeck);

    final added = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {1: ImportSectionChoice.addToExisting},
    );
    expect(added.groups[1].destination, const IntoExistingDeck('p1'));

    final created = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {1: ImportSectionChoice.createNew},
    );
    expect(created.groups[1].destination, const IntoNewDeck());
    expect(created.groups[1].rows.first.kind, ImportRowKind.ready);
  });

  test('a clash with a deck of decks is new without a choice (§4.3)', () {
    final preview = _plan(_sheet, _root(children: [
      const CardImportChild(id: 'g', name: 'Part 1', canHoldCards: false, pairs: {}),
    ])).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.groups[1].destination, const IntoNewDeck());
    expect(preview.groups[1].clash!.canHoldCards, isFalse);
    expect(preview.canCommit, isTrue);
  });

  test('the default name: blank, too long, or taken in the file locks the commit (Review Focus 1)', () {
    final plan = _plan(_sheet, _root());
    ImportNameProblem? problem(String name) => plan
        .preview(defaultDeckName: name, choices: const {})
        .groups
        .first
        .nameProblem;
    expect(problem('  '), ImportNameProblem.blank);
    expect(problem('x' * 201), ImportNameProblem.tooLong);
    expect(problem(' part 1'), ImportNameProblem.takenInFile);
    expect(problem('Misc'), isNull);
    expect(plan.preview(defaultDeckName: '', choices: const {}).canCommit, isFalse);
  });

  test('a section with a blank name makes its rows invalid (BR-TRANSFER-015)', () {
    final preview = _plan([
      ['Term', 'Meaning'],
      ['*', ''],
      ['a', 'b'],
    ], _root()).preview(defaultDeckName: 'Uncategorized', choices: const {});
    final row = preview.groups.single.rows.single;
    expect((row.kind, row.deckNameReason), (ImportRowKind.invalid, DeckRejection.blankName));
  });

  test('flat into a deck that takes cards: one group, into the target', () {
    final preview = _plan([
      ['Term', 'Meaning'],
      ['a', 'b'],
    ], const CardImportTarget(
      holdsCards: true,
      canHoldCards: true,
      hasRoomBelow: true,
      pairs: {},
      children: [],
    )).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.isSectioned, isFalse);
    expect(preview.groups.single.destination, const IntoTarget());
  });

  test('flat into a root: one default group, a new deck', () {
    final preview = _plan([
      ['Term', 'Meaning'],
      ['a', 'b'],
    ], _root()).preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(preview.isSectioned, isTrue);
    expect(
      [for (final g in preview.groups) (g.name, g.isDefault, g.destination)],
      [('Uncategorized', true, const IntoNewDeck())],
    );
  });
}
```

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/domain/import_plan_model_test.dart`
Expected: FAIL — `import_plan_model.dart` does not exist.

- [ ] **Step 3: Destinations and groups** — add to `import_preview_model.dart`:

```dart
/// Where a group's cards go (spec 2026-10-08 §4.2, §4.3).
sealed class ImportDestination {
  const ImportDestination();
}

/// A flat import into the deck it was opened from.
final class IntoTarget extends ImportDestination {
  const IntoTarget();
  @override
  bool operator ==(Object other) => other is IntoTarget;
  @override
  int get hashCode => (IntoTarget).hashCode;
}

/// A new sub-deck of the target, made at commit when a card is kept.
final class IntoNewDeck extends ImportDestination {
  const IntoNewDeck();
  @override
  bool operator ==(Object other) => other is IntoNewDeck;
  @override
  int get hashCode => (IntoNewDeck).hashCode;
}

/// "Add to existing": a live direct sub-deck that takes cards.
final class IntoExistingDeck extends ImportDestination {
  const IntoExistingDeck(this.deckId);
  final String deckId;
  @override
  bool operator ==(Object other) =>
      other is IntoExistingDeck && other.deckId == deckId;
  @override
  int get hashCode => deckId.hashCode;
}

/// A clash the user has not decided (U3): nothing can be written yet.
final class Undecided extends ImportDestination {
  const Undecided();
  @override
  bool operator ==(Object other) => other is Undecided;
  @override
  int get hashCode => (Undecided).hashCode;
}

/// A direct sub-deck of the target whose name folds equal to a group's.
final class ImportClash {
  const ImportClash({
    required this.deckId,
    required this.name,
    required this.canHoldCards,
  });

  final String deckId;
  final String name;
  final bool canHoldCards;
}

/// Why the default deck's name cannot be used (U4).
enum ImportNameProblem { blank, tooLong, takenInFile }

/// The rows bound for one deck.
final class ImportGroup {
  const ImportGroup({
    required this.name,
    required this.isDefault,
    required this.destination,
    required this.rows,
    this.clash,
    this.nameProblem,
  });

  final String name;
  final bool isDefault;
  final ImportDestination destination;
  final ImportClash? clash;
  final ImportNameProblem? nameProblem;
  final List<ImportRow> rows;

  List<ImportRow> rowsToWrite({required bool includeDuplicates}) => [
    for (final row in rows)
      if (row.kind == ImportRowKind.ready ||
          (includeDuplicates && row.isDuplicate))
        row,
  ];

  int willWrite({required bool includeDuplicates}) =>
      rowsToWrite(includeDuplicates: includeDuplicates).length;
}
```

Rework `ImportPreview` so it keeps its current API over groups:

```dart
final class ImportPreview {
  /// A flat preview into the target (today's import).
  ImportPreview(List<ImportRow> rows)
    : groups = [
        ImportGroup(
          name: '',
          isDefault: false,
          destination: const IntoTarget(),
          rows: rows,
        ),
      ],
      isSectioned = false;

  /// A preview whose groups become sub-decks (BR-TRANSFER-015).
  const ImportPreview.sectioned(this.groups) : isSectioned = true;

  final List<ImportGroup> groups;
  final bool isSectioned;

  List<ImportRow> get rows => [for (final g in groups) ...g.rows];

  int get total => rows.length;
  int get ready => _count(ImportRowKind.ready);
  int get invalid => _count(ImportRowKind.invalid);
  int get blank => _count(ImportRowKind.blank);
  int get duplicates => rows.where((row) => row.isDuplicate).length;

  /// Groups whose clash is still to be decided (U6).
  int get undecided =>
      groups.where((g) => g.destination is Undecided).length;

  bool get hasNameProblem => groups.any((g) => g.nameProblem != null);

  /// Whether Import may run once something is to be written (U6).
  bool get canCommit => undecided == 0 && !hasNameProblem;

  bool get isEmpty => blank == total;

  int willWrite({required bool includeDuplicates}) => [
    for (final g in groups) g.willWrite(includeDuplicates: includeDuplicates),
  ].fold(0, (a, b) => a + b);

  List<ImportRow> rowsToWrite({required bool includeDuplicates}) => [
    for (final g in groups) ...g.rowsToWrite(includeDuplicates: includeDuplicates),
  ];

  int _count(ImportRowKind kind) =>
      rows.where((row) => row.kind == kind).length;
}
```

(`ImportPreview` loses `const` on the flat constructor; fix any `const ImportPreview(` the analyzer reports.)

- [ ] **Step 4: `import_plan_model.dart`**

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/models/card_folded_pair_model.dart';
import 'package:memox/features/card/domain/models/card_import_target_model.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sections_model.dart';
import 'package:memox/features/transfer/domain/models/source_table_model.dart';

/// The user's answer to a name clash (spec 2026-10-08 §4.3).
enum ImportSectionChoice { addToExisting, createNew }

/// What a preview read, before the user's choices: re-derived into an
/// [ImportPreview] each time a choice or the default name changes, without
/// reading again (U2–U6).
final class ImportPlan {
  const ImportPlan({
    required this.table,
    required this.mapping,
    required this.hasHeaderRow,
    required this.target,
    required this.sections,
  });

  final SourceTable table;
  final ColumnMapping mapping;
  final bool hasHeaderRow;
  final CardImportTarget target;

  /// Null for a flat source (BR-TRANSFER-015).
  final List<ImportSection>? sections;

  /// Whether this import writes into the target itself (§4.2).
  bool get isFlatIntoTarget => sections == null && target.canHoldCards;

  /// The sections as written, or one default section with every data row
  /// for a flat source into a deck that takes decks (§4.2).
  List<ImportSection> get _groupsToBe =>
      sections ??
      [
        ImportSection(
          name: '',
          isDefault: true,
          rowIndexes: [
            for (var i = hasHeaderRow ? 1 : 0; i < table.rows.length; i++) i,
          ],
        ),
      ];

  ImportPreview preview({
    required String defaultDeckName,
    required Map<int, ImportSectionChoice> choices,
  }) {
    if (isFlatIntoTarget) {
      return buildImportPreview(
        table: table,
        mapping: mapping,
        hasHeaderRow: hasHeaderRow,
        existing: target.pairs,
      );
    }
    final toBe = _groupsToBe;
    final sectionKeys = {
      for (final s in toBe)
        if (!s.isDefault) foldText(s.name),
    };
    return ImportPreview.sectioned([
      for (final (index, section) in toBe.indexed)
        _group(
          section,
          name: section.isDefault ? defaultDeckName.trim() : section.name,
          choice: choices[index],
          isTakenInFile:
              section.isDefault &&
              sectionKeys.contains(foldText(defaultDeckName)),
        ),
    ]);
  }

  ImportGroup _group(
    ImportSection section, {
    required String name,
    required ImportSectionChoice? choice,
    required bool isTakenInFile,
  }) {
    final key = foldText(name);
    final child = target.children
        .where((c) => foldText(c.name) == key)
        .firstOrNull;
    final clash = child == null
        ? null
        : ImportClash(
            deckId: child.id,
            name: child.name,
            canHoldCards: child.canHoldCards,
          );
    final destination = switch ((child, choice)) {
      (null, _) => const IntoNewDeck(),
      (final c?, _) when !c.canHoldCards => const IntoNewDeck(),
      (final c?, ImportSectionChoice.addToExisting) => IntoExistingDeck(c.id),
      (_, ImportSectionChoice.createNew) => const IntoNewDeck(),
      (_, null) => const Undecided(),
    };
    final existing = switch (destination) {
      IntoExistingDeck() || Undecided() => child!.pairs,
      _ => <CardFoldedPair>{},
    };
    final nameCheck = DeckEntity.checkName(name);
    final rows = classifyRows(
      table: table,
      rowIndexes: section.rowIndexes,
      mapping: mapping,
      existing: existing,
    );
    return ImportGroup(
      name: name,
      isDefault: section.isDefault,
      destination: destination,
      clash: clash,
      nameProblem: section.isDefault
          ? _problem(nameCheck, isTakenInFile: isTakenInFile)
          : null,
      rows: switch (nameCheck) {
        Rejected(:final reason) when !section.isDefault => [
          for (final row in rows)
            if (row.kind == ImportRowKind.blank)
              row
            else
              ImportRow(
                rowNumber: row.rowNumber,
                kind: ImportRowKind.invalid,
                draft: row.draft,
                deckNameReason: reason,
              ),
        ],
        _ => rows,
      },
    );
  }

  static ImportNameProblem? _problem(
    Outcome<void, DeckRejection> check, {
    required bool isTakenInFile,
  }) => switch (check) {
    Rejected(reason: DeckRejection.blankName) => ImportNameProblem.blank,
    Rejected() => ImportNameProblem.tooLong,
    _ when isTakenInFile => ImportNameProblem.takenInFile,
    _ => null,
  };
}
```

- [ ] **Step 5: Run the transfer domain tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/domain`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transfer/domain/models test/features/transfer/domain
git commit -m "feat(transfer): DEV-289 import plan with deck groups and clash choices"
```

---

### Task 6: Preview and commit use cases

**Files:**
- Modify: `lib/features/transfer/domain/usecases/preview_import_use_case.dart`
- Modify: `lib/features/transfer/domain/usecases/commit_import_use_case.dart`
- Modify: `lib/features/transfer/domain/models/import_summary_model.dart`
- Modify: `lib/features/transfer/domain/failures/transfer_failure.dart`
- Test: `test/features/transfer/domain/import_sections_use_cases_test.dart`; adjust `import_use_cases_test.dart` (preview now returns `ImportPlan`).

**Interfaces:**
- Consumes: `CardTransferRepository.importTarget`, `.importSections`, `.importCards` (Task 4); `ImportPlan`, `ImportPreview` (Task 5).
- Produces:

```dart
// PreviewImportUseCase
Future<Outcome<ImportPlan, TransferRejection>> call({required String deckId, required SourceTable table, required ColumnMapping mapping, required bool hasHeaderRow});
// CommitImportUseCase — signature unchanged
Future<Outcome<ImportSummary, TransferRejection>> call({required String deckId, required ImportPreview preview, required bool includeDuplicates});
// ImportSummary gains: final List<ImportDeckResult> decks; (const [] for flat)
final class ImportDeckResult { String name; bool isNew; int written; }
// TransferRejection gains: sectionsNeedDeckContainer, depthExceeded, sectionTargetChanged, sectionChoiceMissing
```

- [ ] **Step 1: Write the failing tests** — `import_sections_use_cases_test.dart`, using the same real-repository setup as `import_use_cases_test.dart` (copy its `setUp`, adding `decks` as the third `CardTransferRepositoryImpl` argument), then:

```dart
  Future<ImportPlan> planOf(String deckId, String text) async {
    final table = _ok(await read(PastedSource(text)));
    return _ok(
      await preview(
        deckId: deckId,
        table: table,
        mapping: const ColumnMapping({0: TransferField.front, 1: TransferField.back}),
        hasHeaderRow: true,
      ),
    );
  }

  const sheet = 'Term,Meaning\n*Part 1,\na,b\nc,d\n*관용어,\ne,f\n';

  test('a sectioned file from a root makes its decks (UC-TRANSFER-001 A6)', () async {
    final plan = await planOf(root.id, sheet);
    final rows = plan.preview(defaultDeckName: 'Uncategorized', choices: const {});

    final summary = _ok(await commit(deckId: root.id, preview: rows, includeDuplicates: false));

    expect(summary.written, 3);
    expect([for (final d in summary.decks) (d.name, d.isNew, d.written)], [
      ('Part 1', true, 2),
      ('관용어', true, 1),
    ]);
  });

  test('sections from a deck of cards are refused at preview (E7)', () async {
    await insertCard(db, id: 'x', deckId: leaf.id, front: 'a', back: 'b');
    final table = _ok(await read(const PastedSource(sheet)));
    expect(
      _reason(await preview(
        deckId: leaf.id,
        table: table,
        mapping: const ColumnMapping({0: TransferField.front, 1: TransferField.back}),
        hasHeaderRow: true,
      )),
      TransferRejection.sectionsNeedDeckContainer,
    );
  });

  test('an undecided clash refuses the commit (U6)', () async {
    await decks.sub(root.id, 'Part 1');
    final plan = await planOf(root.id, sheet);
    final rows = plan.preview(defaultDeckName: 'Uncategorized', choices: const {});
    expect(
      _reason(await commit(deckId: root.id, preview: rows, includeDuplicates: false)),
      TransferRejection.sectionChoiceMissing,
    );
  });

  test('a chosen deck that moved before the commit refuses it, nothing written (E9)', () async {
    final part = await decks.sub(root.id, 'Part 1');
    final plan = await planOf(root.id, sheet);
    final rows = plan.preview(
      defaultDeckName: 'Uncategorized',
      choices: const {0: ImportSectionChoice.addToExisting},
    );
    final other = await decks.root('Other');
    await decks.moveDeck(deckId: part.id, newParentId: other.id);

    expect(
      _reason(await commit(deckId: root.id, preview: rows, includeDuplicates: false)),
      TransferRejection.sectionTargetChanged,
    );
  });
```

(`root` here is the root deck from `setUp`; `leaf` is its sub-deck.)

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/domain/import_sections_use_cases_test.dart`
Expected: FAIL — preview returns `ImportPreview`, the new rejections do not exist.

- [ ] **Step 3: Rejections** — add to `TransferRejection`:

```dart
  /// BR-TRANSFER-001, UC-TRANSFER-001 E7: a sectioned source from a deck
  /// of cards.
  sectionsNeedDeckContainer,

  /// BR-DECK-001, UC-TRANSFER-001 E8: the target is at level 10.
  depthExceeded,

  /// BR-TRANSFER-001, UC-TRANSFER-001 E9: a deck chosen for "Add to
  /// existing" changed before the commit.
  sectionTargetChanged,

  /// Spec 2026-10-08 U6: a clash is undecided or the default name is
  /// refused.
  sectionChoiceMissing,
```

- [ ] **Step 4: Preview use case**

```dart
/// UC-TRANSFER-001 steps 4–5, A6, E2, E7, E8: what the import would do,
/// read once; the plan re-derives its preview as the user decides. Writes
/// nothing (BR-TRANSFER-006).
final class PreviewImportUseCase {
  const PreviewImportUseCase(this._cards);

  final CardTransferRepository _cards;

  Future<Outcome<ImportPlan, TransferRejection>> call({
    required String deckId,
    required SourceTable table,
    required ColumnMapping mapping,
    required bool hasHeaderRow,
  }) async {
    if (!mapping.isComplete) {
      return const Rejected(TransferRejection.mappingIncomplete);
    }
    final target = await _cards.importTarget(deckId);
    if (target == null) return const Rejected(TransferRejection.targetRejected);
    final sections = splitSections(
      table: table,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
    );
    final needsDecks = sections != null || !target.canHoldCards;
    if (needsDecks && target.holdsCards) {
      return const Rejected(TransferRejection.sectionsNeedDeckContainer);
    }
    if (needsDecks && !target.hasRoomBelow) {
      return const Rejected(TransferRejection.depthExceeded);
    }
    final plan = ImportPlan(
      table: table,
      mapping: mapping,
      hasHeaderRow: hasHeaderRow,
      target: target,
      sections: sections,
    );
    // The default name does not change which rows are blank (E2).
    if (plan.preview(defaultDeckName: '', choices: const {}).isEmpty) {
      return const Rejected(TransferRejection.emptySource);
    }
    return Ok(plan);
  }
}
```

Update the old test file's `previewOf` helper to `_ok(await preview(...)).preview(defaultDeckName: 'Uncategorized', choices: const {})`.

- [ ] **Step 5: Summary** — in `import_summary_model.dart`:

```dart
/// One deck a sectioned import wrote to (U8).
final class ImportDeckResult {
  const ImportDeckResult({
    required this.name,
    required this.isNew,
    required this.written,
  });

  final String name;
  final bool isNew;
  final int written;
}
```

and `ImportSummary` gains `this.decks = const []` with `final List<ImportDeckResult> decks;` ("Empty for a flat import.").

- [ ] **Step 6: Commit use case** — keep the flat path as is (`preview.isSectioned == false`), and add the sectioned branch at the top of `call`:

```dart
    if (preview.isSectioned) {
      return _sectioned(deckId, preview, includeDuplicates: includeDuplicates);
    }
```

```dart
  Future<Outcome<ImportSummary, TransferRejection>> _sectioned(
    String deckId,
    ImportPreview preview, {
    required bool includeDuplicates,
  }) async {
    if (!preview.canCommit) {
      return const Rejected(TransferRejection.sectionChoiceMissing);
    }
    final toWrite = [
      for (final g in preview.groups)
        g.rowsToWrite(includeDuplicates: includeDuplicates),
    ];
    if (toWrite.every((rows) => rows.isEmpty)) {
      return const Rejected(TransferRejection.nothingToImport);
    }
    final result = await _cards.importSections(
      targetDeckId: deckId,
      sections: [
        for (final (index, group) in preview.groups.indexed)
          CardImportSection(
            name: group.name,
            existingDeckId: switch (group.destination) {
              IntoExistingDeck(:final deckId) => deckId,
              _ => null,
            },
            drafts: [for (final row in toWrite[index]) row.draft!],
          ),
      ],
      includeDuplicates: includeDuplicates,
    );
    return switch (result) {
      Ok(:final value) => Ok(
        ImportSummary(
          written: value.fold(0, (sum, s) => sum + s.written),
          blank: preview.blank,
          skipped: [
            for (final (index, group) in preview.groups.indexed)
              ..._skipped(
                ImportPreview(group.rows),
                toWrite[index],
                value[index].skippedIndexes,
                includeDuplicates: includeDuplicates,
              ),
          ],
          decks: [
            for (final (index, group) in preview.groups.indexed)
              if (value[index].written > 0)
                ImportDeckResult(
                  name: group.destination is IntoExistingDeck
                      ? group.clash!.name
                      : group.name,
                  isNew: group.destination is! IntoExistingDeck,
                  written: value[index].written,
                ),
          ],
        ),
      ),
      Rejected(reason: CardRejection.sectionTargetChanged) => const Rejected(
        TransferRejection.sectionTargetChanged,
      ),
      Rejected(reason: CardRejection.depthExceeded) => const Rejected(
        TransferRejection.depthExceeded,
      ),
      Rejected(
        reason: CardRejection.notFound || CardRejection.notADeckContainer,
      ) => const Rejected(TransferRejection.targetRejected),
      Rejected(:final reason) => throw StateError(
        'import refused a previewed section: $reason',
      ),
    };
  }
```

(`_skipped` is the existing static helper; it already walks one preview's rows in order.)

- [ ] **Step 7: Run the transfer suite**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer`
Expected: domain and data PASS. The controller still expects `ImportPreview` from the use case, so `card_import_controller.dart` stops compiling here: do Task 7 Step 4's `previewRows` change (and Step 5's screen callback with the `importDefaultDeckName` ARB entries) in this task, so this commit compiles and the whole transfer suite passes. Task 7 then adds the choices and the tests.

- [ ] **Step 8: Commit**

```bash
git add lib/features/transfer/domain test/features/transfer/domain
git commit -m "feat(transfer): DEV-289 preview plans and sectioned commit"
```

---

### Task 7: The wizard's controller and state

**Files:**
- Modify: `lib/features/transfer/presentation/states/card_import_state.dart`
- Modify: `lib/features/transfer/presentation/controllers/card_import_controller.dart`
- Modify: `lib/features/transfer/presentation/screens/card_import_screen.dart` (the `onPreview` callback only)
- Test: `test/features/transfer/presentation/card_import_sections_controller_test.dart`; update `card_import_controller_test.dart` calls to `previewRows(defaultDeckName: 'Uncategorized')`.

**Interfaces:**
- Consumes: `ImportPlan.preview`, `ImportSectionChoice` (Task 5); use cases (Task 6).
- Produces (state): `CardImportDraft.plan` (`ImportPlan?`), `.sectionChoices` (`Map<int, ImportSectionChoice>`, default `const {}`), `.defaultDeckName` (`String?`), `.preview` (still `ImportPreview?`, derived and stored).
- Produces (controller): `Future<void> previewRows({required String defaultDeckName})`, `void chooseSection(int index, ImportSectionChoice choice)`, `void renameDefaultDeck(String name)`.

- [ ] **Step 1: Write the failing tests** — same harness as `card_import_controller_test.dart` (a `ProviderContainer` over the real database with `importFilePickerProvider` faked). Seed: root `Korean` with a sub-deck `Part 1` (unset). Pick a file `words.csv` with text `'Term,Meaning\n*Part 1,\na,b\n*New,\nc,d\n'`, then:

```dart
    test('a clash must be chosen; Import counts once it is (U3, U6)', () async {
      final wizard = container.read(cardImportControllerProvider(root.id).notifier);
      await wizard.chooseFile();
      await wizard.readSource();
      wizard.assignColumn(0, TransferField.front);
      wizard.assignColumn(1, TransferField.back);
      await wizard.previewRows(defaultDeckName: 'Uncategorized');

      var draft = container.read(cardImportControllerProvider(root.id)) as CardImportDraft;
      expect((draft.preview!.undecided, draft.preview!.canCommit), (1, false));

      wizard.chooseSection(0, ImportSectionChoice.addToExisting);
      draft = container.read(cardImportControllerProvider(root.id)) as CardImportDraft;
      expect(draft.preview!.canCommit, isTrue);

      await wizard.commit();
      final done = container.read(cardImportControllerProvider(root.id)) as CardImportDone;
      expect([for (final d in done.summary.decks) (d.name, d.isNew)], [
        ('Part 1', false),
        ('New', true),
      ]);
    });

    test('changing the mapping clears the choices; the default name stays (Review Focus 2)', () async {
      // …same steps up to chooseSection(0, addToExisting)…
      wizard.renameDefaultDeck('Misc');
      expect(wizard.stepBack(), isTrue); // to Columns
      wizard.setHasHeaderRow(hasHeaderRow: true);
      await wizard.previewRows(defaultDeckName: 'Uncategorized');
      final draft = container.read(cardImportControllerProvider(root.id)) as CardImportDraft;
      expect(draft.sectionChoices, isEmpty);
      expect(draft.defaultDeckName, 'Misc');
    });

    test('a chosen deck that moved shows the problem on the preview (E9)', () async {
      // …up to chooseSection(0, addToExisting)…
      await decks.moveDeck(deckId: part.id, newParentId: (await decks.root('Other')).id);
      await wizard.commit();
      final draft = container.read(cardImportControllerProvider(root.id)) as CardImportDraft;
      expect((draft.step, draft.problem), (CardImportStep.preview, TransferRejection.sectionTargetChanged));
    });
```

Write the elided "same steps" out in full in the test file (a local `Future<CardImportController> toPreview()` helper doing pick → read → map → preview).

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/presentation/card_import_sections_controller_test.dart`
Expected: FAIL to compile.

- [ ] **Step 3: State** — add to `CardImportDraft` (constructor params with defaults `this.plan`, `this.sectionChoices = const {}`, `this.defaultDeckName`), and to `copyWith`:

```dart
    ImportPlan? plan,
    Map<int, ImportSectionChoice>? sectionChoices,
    String? defaultDeckName,
```

passing them through (`plan: plan ?? this.plan`, and so on). Every `CardImportDraft(...)` built in the controller's `stepBack` and `readSource` drops `plan`, `preview` and `sectionChoices` (they belong to one mapping) but keeps `defaultDeckName`. Change `willWrite` to:

```dart
  /// What the commit bar's Import writes (UC-TRANSFER-001 step 6).
  int get willWrite =>
      preview?.willWrite(includeDuplicates: isIncludingDuplicates) ?? 0;

  /// Import may run (U6).
  bool get canCommit => willWrite > 0 && (preview?.canCommit ?? false);
```

- [ ] **Step 4: Controller**

```dart
  /// Step 2 → 3 ("Preview rows"): what the import would do against the deck
  /// as it is now (UC-TRANSFER-001 step 5, A6). [defaultDeckName] is the
  /// localized name a default deck starts with (S4); a name the user typed
  /// before stays.
  Future<void> previewRows({required String defaultDeckName}) async {
    final draft = _draft;
    final table = draft?.table;
    if (draft == null || table == null || draft.isBusy) return;
    state = draft.copyWith(isBusy: true, isProblemCleared: true);
    final result = await ref.read(previewImportUseCaseProvider)(
      deckId: deckId,
      table: table,
      mapping: draft.mapping,
      hasHeaderRow: draft.hasHeaderRow,
    );
    if (!ref.mounted) return;
    final name = draft.defaultDeckName ?? defaultDeckName;
    state = switch (result) {
      Ok(:final value) => draft.copyWith(
        step: CardImportStep.preview,
        plan: value,
        sectionChoices: const {},
        defaultDeckName: name,
        preview: value.preview(defaultDeckName: name, choices: const {}),
        isBusy: false,
      ),
      Rejected(:final reason) => draft.copyWith(isBusy: false, problem: reason),
    };
  }

  /// Step 3 (U3): how a section whose name is taken is imported.
  void chooseSection(int index, ImportSectionChoice choice) {
    final draft = _draft;
    final plan = draft?.plan;
    if (draft == null || plan == null) return;
    final choices = {...draft.sectionChoices, index: choice};
    state = draft.copyWith(
      sectionChoices: choices,
      preview: plan.preview(
        defaultDeckName: draft.defaultDeckName ?? '',
        choices: choices,
      ),
    );
  }

  /// Step 3 (U4): the default deck's name; a choice made for its old name is
  /// cleared, since its clash may have changed.
  void renameDefaultDeck(String name) {
    final draft = _draft;
    final plan = draft?.plan;
    if (draft == null || plan == null) return;
    final defaultIndex = plan
        .preview(defaultDeckName: name, choices: const {})
        .groups
        .indexWhere((g) => g.isDefault);
    final choices = {...draft.sectionChoices}..remove(defaultIndex);
    state = draft.copyWith(
      defaultDeckName: name,
      sectionChoices: choices,
      preview: plan.preview(defaultDeckName: name, choices: choices),
    );
  }
```

In `setHasHeaderRow` and `assignColumn`, the `copyWith` already keeps `preview`; they run at the Columns step where preview is null, and `previewRows` resets `sectionChoices`, so Review Focus 2 holds. In `commit`, replace the `willWrite == 0` guard with `if (!draft.canCommit) return;`, and map the new rejection:

```dart
        Rejected(reason: TransferRejection.sectionTargetChanged) => draft.copyWith(
          step: CardImportStep.preview,
          isBusy: false,
          problem: TransferRejection.sectionTargetChanged,
        ),
        Rejected(:final reason) => draft.copyWith(
          step: CardImportStep.preview,
          isBusy: false,
          problem: reason,
        ),
```

(The existing `Rejected(:final reason) => draft.copyWith(problem: reason)` arm left `step: importing`; set it back to `preview` as above — `draft` is the pre-commit draft, so this restores the preview.)

- [ ] **Step 5: Screen callback** (already done in Task 6 Step 7 if the controller had to compile there; then only check it) — in `card_import_screen.dart`:

```dart
        onPreview: () => unawaited(
          _wizard.previewRows(defaultDeckName: l10n.importDefaultDeckName),
        ),
```

(The ARB key lands in Task 9; until then use a temporary test-only build? No — add the two ARB entries `importDefaultDeckName` now, EN "Uncategorized" / VI "Chưa phân loại", with `@importDefaultDeckName` description "The name a default deck starts with in an import split by * rows (BR-TRANSFER-015).", and run `flutter gen-l10n`.)

- [ ] **Step 6: Run the transfer presentation tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/transfer lib/l10n test/features/transfer
git commit -m "feat(transfer): DEV-289 wizard keeps clash choices and the default deck name"
```

---

### Task 8: Import from a root and from a deck of decks (U1)

**Files:**
- Modify: `lib/features/deck/presentation/screens/deck_level_screen.dart:316`
- Test: `test/features/deck/presentation/deck_action_sheet_test.dart:102-133`

**Interfaces:**
- Consumes: `DeckView.createOptions`.

- [ ] **Step 1: Rewrite the gating test**

```dart
  libraryTest(
    'every deck that takes cards or decks offers Import (BR-TRANSFER-001, spec 2026-10-08 U1)',
    (tester, env) async {
      final korean = await env.decks.root('Korean');
      final words = await env.decks.sub(korean.id, 'Words');
      final grammar = await env.decks.sub(korean.id, 'Grammar');
      await env.decks.sub(grammar.id, 'Particles');
      await insertCard(env.db, id: 'c1', deckId: words.id, front: 'mul');
      final imported = <String>[];

      for (final deckId in [korean.id, grammar.id, words.id]) {
        await pumpLibraryScreen(
          tester,
          env,
          deckScreen(deckId: deckId, onImportCards: imported.add),
        );
        await _openSheet(tester);
        expect(find.text(_en.deckActionImport), findsOneWidget);
        await _choose(tester, _en.deckActionImport);
      }

      expect(imported, [korean.id, grammar.id, words.id]);
    },
  );
```

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/deck/presentation/deck_action_sheet_test.dart`
Expected: FAIL — the root offers no Import.

- [ ] **Step 3: Implement** — line 316:

```dart
          // Every deck takes an import: cards into a deck that holds or may
          // hold cards, sections into one that may hold decks (spec
          // 2026-10-08 §4.2, U1).
          onImportCards: view.createOptions.isNotEmpty
              ? () => onImportCards(deck.id)
              : null,
```

- [ ] **Step 4: Run, expect pass** — same command, plus `test/features/deck/presentation/open_deck_screen_test.dart`. Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/deck/presentation/screens/deck_level_screen.dart test/features/deck/presentation/deck_action_sheet_test.dart
git commit -m "feat(deck): DEV-289 offer Import on roots and decks of decks"
```

---

### Task 9: Preview — the Decks block, grouped rows, banners and footer (U2–U7)

**Files:**
- Create: `lib/features/transfer/presentation/widgets/items/import_deck_row_widget.dart`
- Create: `lib/features/transfer/presentation/widgets/sections/import_decks_section_widget.dart`
- Modify: `lib/features/transfer/presentation/widgets/sections/import_preview_section_widget.dart`
- Modify: `lib/features/transfer/presentation/widgets/sections/import_mapping_section_widget.dart` (banner for E7/E8)
- Modify: `lib/features/transfer/presentation/widgets/sections/import_commit_bar_widget.dart`
- Modify: `lib/features/transfer/presentation/widgets/support/import_labels_widget.dart`
- Modify: `lib/features/transfer/presentation/screens/card_import_screen.dart` (wire callbacks)
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/features/transfer/presentation/import_decks_section_test.dart`

**Interfaces:**
- Consumes: `CardImportDraft.preview.groups`, `ImportGroup`, `ImportDestination`, `ImportNameProblem`; controller `chooseSection`, `renameDefaultDeck`, `previewRows`.
- Produces: `ImportDecksSectionWidget({required ImportPreview preview, required bool isIncludingDuplicates, required void Function(int, ImportSectionChoice) onChoose, required ValueChanged<String> onRename})`.

- [ ] **Step 1: ARB entries** — add to `app_en.arb` (each with an `@key` description) and `app_vi.arb`:

| Key | EN | VI |
|---|---|---|
| `importDecksHeader` | Decks | Deck |
| `importDeckNew` | New | Mới |
| `importDeckExisting` | Existing | Có sẵn |
| `importDeckCards` | `{count, plural, =1{1 card} other{{count} cards}}` | `{count} thẻ` |
| `importDeckNothing` | No cards to add · no deck made | Không có thẻ để thêm · không tạo deck |
| `importDeckAddToExisting` | Add to existing | Thêm vào có sẵn |
| `importDeckCreateNew` | Create new | Tạo mới |
| `importDeckClashNote` | A deck with this name is already here. | Ở đây đã có deck trùng tên. |
| `importDeckHoldsDecksNote` | The deck with this name holds decks, so a new one is made. | Deck trùng tên đang chứa deck con nên sẽ tạo deck mới. |
| `importDeckNameLabel` | Deck name | Tên deck |
| `importDeckNameTaken` | Another deck in this file has this name. | Một deck khác trong file đã dùng tên này. |
| `importRowDeckNameBlank` | Deck name after * is empty | Tên deck sau * bị trống |
| `importRowDeckNameTooLong` | Deck name over 200 characters | Tên deck dài quá 200 ký tự |
| `importCaptionChooseDecks` | `{count, plural, =1{Choose how to import 1 deck with a taken name.} other{Choose how to import {count} decks with taken names.}}` | `Chọn cách nhập cho {count} deck trùng tên.` |
| `importCaptionFixDeckName` | Fix the deck name to continue. | Sửa tên deck để tiếp tục. |
| `importProblemSectionsTitle` | This file is split into decks | File này chia theo deck |
| `importProblemSectionsBody` | A deck of cards can’t hold decks. Import from its parent deck instead. Nothing was added. | Deck chứa thẻ không chứa được deck con. Hãy import từ deck cha. Chưa có gì được thêm. |
| `importProblemDepthTitle` | No room for another level | Không thể thêm cấp |
| `importProblemDepthBody` | Decks go at most 10 levels deep. Import from a higher deck. Nothing was added. | Deck lồng tối đa 10 cấp. Hãy import từ deck cấp trên. Chưa có gì được thêm. |
| `importProblemChangedTitle` | A deck changed meanwhile | Một deck vừa thay đổi |
| `importProblemChangedBody` | Nothing was added. Preview again to see the decks as they are now. | Chưa có gì được thêm. Xem trước lại để thấy các deck hiện tại. |
| `importPreviewAgain` | Preview again | Xem trước lại |

Reuse `deckRejectionBlankName` and `deckRejectionNameTooLong` for the default name's blank/too-long errors. Run `flutter gen-l10n`.

- [ ] **Step 2: Labels** — in `import_labels_widget.dart`:

```dart
  /// Why a row will not be written, or null for a ready row.
  String? importRowNote(ImportRow row) => switch (row.kind) {
    ImportRowKind.ready => null,
    ImportRowKind.blank => importRowBlank,
    ImportRowKind.duplicateInDeck => importRowDuplicateInDeck,
    ImportRowKind.duplicateInSource => importRowDuplicateInSource(
      row.firstRowNumber!,
    ),
    ImportRowKind.invalid => switch (row.deckNameReason) {
      DeckRejection.blankName => importRowDeckNameBlank,
      _? => importRowDeckNameTooLong,
      null => _invalid(row),
    },
  };

  /// The error under the default deck's name field (U4).
  String importNameProblem(ImportNameProblem problem) => switch (problem) {
    ImportNameProblem.blank => deckRejectionBlankName,
    ImportNameProblem.tooLong => deckRejectionNameTooLong,
    ImportNameProblem.takenInFile => importDeckNameTaken,
  };
```

and extend `importProblem` with:

```dart
        TransferRejection.sectionsNeedDeckContainer => (
          title: importProblemSectionsTitle,
          body: importProblemSectionsBody,
        ),
        TransferRejection.depthExceeded => (
          title: importProblemDepthTitle,
          body: importProblemDepthBody,
        ),
        TransferRejection.sectionTargetChanged => (
          title: importProblemChangedTitle,
          body: importProblemChangedBody,
        ),
```

- [ ] **Step 3: Write the failing widget tests** (`import_decks_section_test.dart`) — pump `ImportDecksSectionWidget` inside the repo's widget harness (`pumpWidgetHarness` or whatever `import_preview_row_test.dart` uses — copy its pump helper) with a preview built from `ImportPlan` (as in Task 5's tests), and assert:

```dart
  testWidgets('a clash shows the tray with nothing chosen; a tap chooses (U3)', (tester) async {
    final chosen = <(int, ImportSectionChoice)>[];
    await pump(tester, previewWithClash, onChoose: (i, c) => chosen.add((i, c)));
    expect(find.text(_en.importDeckAddToExisting), findsOneWidget);
    expect(find.text(_en.importDeckCreateNew), findsOneWidget);
    await tester.tap(find.text(_en.importDeckAddToExisting));
    expect(chosen, [(1, ImportSectionChoice.addToExisting)]);
  });

  testWidgets('a clash with a deck of decks shows its note and no tray (§4.3)', (tester) async {
    await pump(tester, previewWithDeckOfDecksClash);
    expect(find.text(_en.importDeckHoldsDecksNote), findsOneWidget);
    expect(find.text(_en.importDeckAddToExisting), findsNothing);
  });

  testWidgets('the default deck name is a field; a taken name shows its error (U4)', (tester) async {
    await pump(tester, previewWithDefaultNamedPart1);
    expect(find.text(_en.importDeckNameTaken), findsOneWidget);
  });

  testWidgets('each deck row says New or Existing and its cards', (tester) async {
    await pump(tester, previewDecidedAdd);
    expect(find.text(_en.importDeckExisting), findsOneWidget);
    expect(find.text(_en.importDeckCards(1)), findsWidgets);
  });
```

Build the four previews in the test file from `ImportPlan` + `splitSections` exactly as Task 5 does.

- [ ] **Step 4: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/presentation/import_decks_section_test.dart`
Expected: FAIL — widget missing.

- [ ] **Step 5: `ImportDeckRowWidget`**

```dart
import 'package:flutter/material.dart';
import 'package:memox/core/theme/foundations/app_spacing.dart';
import 'package:memox/core/theme/theme_context.dart';
import 'package:memox/features/transfer/domain/models/import_plan_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/presentation/widgets/support/import_labels_widget.dart';
import 'package:memox/l10n/l10n_context.dart';
import 'package:memox/shared/widgets/mx_badge.dart';
import 'package:memox/shared/widgets/mx_field_message.dart';
import 'package:memox/shared/widgets/mx_note.dart';
import 'package:memox/shared/widgets/mx_segmented_tray.dart';
import 'package:memox/shared/widgets/mx_text_field.dart';

/// One destination of a sectioned import (spec 2026-10-08 U2–U4): its
/// name, New or Existing, the cards it receives, and — for a taken name —
/// the choice the user must make. The default deck's name is a field.
class ImportDeckRowWidget extends StatelessWidget {
  const ImportDeckRowWidget({
    super.key,
    required this.group,
    required this.willWrite,
    required this.onChoose,
    required this.onRename,
  });

  final ImportGroup group;
  final int willWrite;
  final ValueChanged<ImportSectionChoice> onChoose;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final styles = context.textStyles;
    final clash = group.clash;
    final isExisting = group.destination is IntoExistingDeck;
    final problem = group.nameProblem;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.gutter,
        vertical: AppSpacing.grouped,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.control,
        children: [
          if (group.isDefault)
            MxTextField(
              label: l10n.importDeckNameLabel,
              initialValue: group.name,
              errorText: problem == null ? null : l10n.importNameProblem(problem),
              onChanged: onRename,
            )
          else
            Text(group.name, style: styles.contentTitle),
          Row(
            spacing: AppSpacing.control,
            children: [
              MxBadge(
                label: isExisting ? l10n.importDeckExisting : l10n.importDeckNew,
                tone: isExisting ? MxBadgeTone.neutral : MxBadgeTone.primary,
              ),
              Expanded(
                child: Text(
                  willWrite == 0
                      ? l10n.importDeckNothing
                      : l10n.importDeckCards(willWrite),
                  style: styles.supporting,
                ),
              ),
            ],
          ),
          if (clash != null && clash.canHoldCards) ...[
            MxNote.hint(text: l10n.importDeckClashNote),
            MxSegmentedTray<ImportSectionChoice>(
              segments: [
                MxSegment(
                  value: ImportSectionChoice.addToExisting,
                  label: l10n.importDeckAddToExisting,
                ),
                MxSegment(
                  value: ImportSectionChoice.createNew,
                  label: l10n.importDeckCreateNew,
                ),
              ],
              selected: switch (group.destination) {
                IntoExistingDeck() => ImportSectionChoice.addToExisting,
                Undecided() => null,
                _ => ImportSectionChoice.createNew,
              },
              onSelected: onChoose,
            ),
          ],
          if (clash != null && !clash.canHoldCards)
            MxNote.hint(text: l10n.importDeckHoldsDecksNote),
        ],
      ),
    );
  }
}
```

Before writing: open `mx_text_field.dart` and use its real API for an initial value (it takes a `controller`; if there is no `initialValue`, make this widget a `StatefulWidget` that owns a `TextEditingController(text: group.name)` and disposes it). Use the text-style names the codebase has (`context.textStyles` — check `import_preview_row_widget.dart` for `contentTitle` and the supporting role it uses for notes) — never a raw `TextStyle`. Remove `MxFieldMessage` import if `errorText` covers it.

- [ ] **Step 6: `ImportDecksSectionWidget`**

```dart
/// The destinations of a sectioned import, before its rows (spec
/// 2026-10-08 U2): this block is the confirmation of what Import will
/// create and fill.
class ImportDecksSectionWidget extends StatelessWidget {
  const ImportDecksSectionWidget({
    super.key,
    required this.preview,
    required this.isIncludingDuplicates,
    required this.onChoose,
    required this.onRename,
  });

  final ImportPreview preview;
  final bool isIncludingDuplicates;
  final void Function(int index, ImportSectionChoice choice) onChoose;
  final ValueChanged<String> onRename;

  @override
  Widget build(BuildContext context) => MxSection(
    title: context.l10n.importDecksHeader,
    children: [
      for (final (index, group) in preview.groups.indexed)
        ImportDeckRowWidget(
          key: ValueKey(('deck', index)),
          group: group,
          willWrite: group.willWrite(includeDuplicates: isIncludingDuplicates),
          onChoose: (choice) => onChoose(index, choice),
          onRename: onRename,
        ),
    ],
  );
}
```

- [ ] **Step 7: Preview section** — in `ImportPreviewSectionWidget` add `onChooseSection` and `onRenameDefault` parameters; after the "Include duplicates" section and before the rows:

```dart
        if (preview.isSectioned) ...[
          ImportDecksSectionWidget(
            preview: preview,
            isIncludingDuplicates: draft.isIncludingDuplicates,
            onChoose: onChooseSection,
            onRename: onRenameDefault,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
```

and replace the single rows `MxSection` with one section per group, capped at `shownRows` across the whole import (K2, U5):

```dart
        ..._rowSections(context, preview),
```

```dart
  List<Widget> _rowSections(BuildContext context, ImportPreview preview) {
    final l10n = context.l10n;
    var left = shownRows;
    final sections = <Widget>[];
    for (final group in preview.groups) {
      if (left == 0) break;
      final shown = group.rows.take(left).toList();
      left -= shown.length;
      sections.add(
        MxSection(
          title: preview.isSectioned ? group.name : null,
          children: [for (final row in shown) ImportPreviewRowWidget(row: row)],
        ),
      );
    }
    final shownCount = shownRows - left;
    if (preview.total > shownCount) {
      sections.add(MxNote(text: l10n.importShowingFirst(shownCount, preview.total)));
    }
    return sections;
  }
```

(Keep the old `note:` placement if `MxSection.note` reads better; the flat case must render exactly as before — check against `import_preview_light.png` in Task 11.)

When `draft.problem == TransferRejection.sectionTargetChanged`, render above the badges:

```dart
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: copy.title,
            message: copy.body,
            actions: [
              MxButton(
                label: l10n.importPreviewAgain,
                tone: MxButtonTone.text,
                size: MxButtonSize.compact,
                onPressed: onPreviewAgain,
              ),
            ],
          ),
```

(with `final copy = l10n.importProblem(problem);` and a new `onPreviewAgain` callback; check `MxInlineBanner.actions` takes widgets — it is `this.actions = const []`.)

- [ ] **Step 8: Mapping banner (U7)** — in `ImportMappingSectionWidget`, after the mapping-incomplete banner:

```dart
        if (draft.problem
            case TransferRejection.sectionsNeedDeckContainer ||
                TransferRejection.depthExceeded) ...[
          MxInlineBanner(
            tone: MxBannerTone.warning,
            title: l10n.importProblem(draft.problem!).title,
            message: l10n.importProblem(draft.problem!).body,
          ),
          const SizedBox(height: AppSpacing.grouped),
        ],
```

In `ImportCommitBarWidget`, at the Columns step, lock Preview rows while one of these two problems stands (the same source and mapping refuse again): `draft.mapping.isComplete && !_isTargetProblem(draft.problem) ? onPreview : null`, where `_isTargetProblem` is those two values. Changing the mapping or header clears `problem` (`isProblemCleared: true`, already the case).

- [ ] **Step 9: Commit bar (U6)** — at the Preview step:

```dart
      CardImportStep.preview => (
        l10n.importCommitAction(draft.willWrite),
        AppIcons.download,
        draft.canCommit ? onCommit : null,
        switch (draft.preview) {
          final p? when p.undecided > 0 => l10n.importCaptionChooseDecks(p.undecided),
          final p? when p.hasNameProblem => l10n.importCaptionFixDeckName,
          _ when draft.willWrite == 0 => l10n.importCaptionNothingToImport,
          _ => null,
        },
      ),
```

- [ ] **Step 10: Wire the screen** — pass `onChooseSection: _wizard.chooseSection`, `onRenameDefault: _wizard.renameDefaultDeck`, `onPreviewAgain: () => unawaited(_wizard.previewRows(defaultDeckName: l10n.importDefaultDeckName))` to `ImportPreviewSectionWidget`.

- [ ] **Step 11: Run**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer`
Expected: PASS (existing layout and screen tests included).

- [ ] **Step 12: Commit**

```bash
git add lib/features/transfer lib/l10n test/features/transfer
git commit -m "feat(transfer): DEV-289 preview groups rows by deck with clash choices"
```

---

### Task 10: Result per deck (U8)

**Files:**
- Modify: `lib/features/transfer/presentation/widgets/sections/import_result_widget.dart`
- Modify: `lib/features/transfer/presentation/screens/card_import_screen.dart` (`_resultShell`)
- Test: `test/features/transfer/presentation/import_result_decks_test.dart`

**Interfaces:**
- Consumes: `ImportSummary.decks`, `ImportDeckResult` (Task 6); ARB `importDecksHeader`, `importDeckNew`, `importDeckExisting`, `importDeckCards`.

- [ ] **Step 1: Write the failing tests** — pump `ImportResultWidget(state: CardImportDone(summary))` with `ImportSummary(written: 3, blank: 0, skipped: const [], decks: const [ImportDeckResult(name: 'Part 1', isNew: false, written: 2), ImportDeckResult(name: '관용어', isNew: true, written: 1)])` and assert `find.text('Part 1')`, `find.text(_en.importDeckExisting)`, `find.text(_en.importDeckCards(2))`. Pump `CardImportScreen` through the controller test harness to a sectioned `CardImportDone` and assert the primary button reads `_en.importBackToDeck`, and that a flat import still reads `_en.importViewCards`.

- [ ] **Step 2: Run, expect failure**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/transfer/presentation/import_result_decks_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implement** — in `ImportResultWidget`, after `_Counts`:

```dart
          if (summary.decks.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.gutter),
            _Decks(decks: summary.decks),
          ],
```

```dart
class _Decks extends StatelessWidget {
  const _Decks({required this.decks});

  final List<ImportDeckResult> decks;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return MxSection(
      title: l10n.importDecksHeader,
      children: [
        for (final deck in decks)
          MxListRow(
            title: deck.name,
            subtitle: l10n.importDeckCards(deck.written),
            trailing: MxBadge(
              label: deck.isNew ? l10n.importDeckNew : l10n.importDeckExisting,
              tone: deck.isNew ? MxBadgeTone.primary : MxBadgeTone.neutral,
            ),
          ),
      ],
    );
  }
}
```

(Check `MxListRow`'s real parameter names — `title`, `leading`, `trailing` are used in `_Counts`; confirm `subtitle` exists, else put the count in `trailing` text and the badge before it.)

In `_resultShell`, add an arm before `CardImportDone()`:

```dart
      CardImportDone(summary: final summary) when summary.decks.isNotEmpty => (
        (l10n.importAnother, _wizard.startOver),
        (l10n.importBackToDeck, widget.onClose, AppIcons.back),
      ),
```

- [ ] **Step 4: Run, expect pass** — same command plus `test/features/transfer/presentation/import_result_skipped_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/transfer/presentation test/features/transfer/presentation
git commit -m "feat(transfer): DEV-289 result lists the decks an import wrote"
```

---

### Task 11: Goldens, screen 11 detail file, review

**Files:**
- Modify: `test/features/transfer/presentation/card_import_golden_test.dart`
- Create: `test/features/transfer/presentation/goldens/import_sections_{undecided,decided,result}_{light,dark}.png`
- Modify: `docs/shared/ui/screen-handoff/11-card-import.md` and its row in the screen index (`docs/shared/ui/screen-handoff/README.md` or wherever `grep -rn "11-card-import" docs/shared/ui` points)

- [ ] **Step 1: Golden tests** — add three `libraryTest`s per brightness to `card_import_golden_test.dart`, with a second picker fixture:

```dart
/// Romanized fronts: the golden test font has no Hangul glyphs.
const _sectionsCsv =
    'Term,Meaning\n'
    'loose,word\n'
    '*Part 1,\n'
    'mul,water\n'
    'bul,fire\n'
    '*Idioms,\n'
    'nun-i nopda,picky\n';

Future<String> _seedSections(LibraryEnv env) async {
  final root = await env.decks.root('Korean');
  final part = await env.decks.sub(root.id, 'Part 1');
  await insertCard(env.db, id: 'x', deckId: part.id, front: 'mul', back: 'water');
  return root.id;
}
```

- `import sections undecided, $theme`: pick → Map columns → map col 0 to Term, col 1 to Meaning (tap the chips as the existing mapping test does) → Preview rows → `expectBoundaryGolden(tester, 'goldens/import_sections_undecided_$theme.png')`.
- `import sections decided, $theme`: as above, then tap `_en.importDeckAddToExisting` → golden `import_sections_decided_$theme.png`.
- `import sections result, $theme`: as decided, then tap the Import button → golden `import_sections_result_$theme.png`.

Run: `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh --update`, then `bash .claude/skills/flutter-workflow/scripts/run_goldens.sh` → PASS. Open every new PNG and the unchanged `import_preview_*`/`import_partial_*` and check: the flat goldens did not change (`git status test/**/goldens` lists only the six new files).

- [ ] **Step 2: Detail file** — in `11-card-import.md`:
  - Entry points: "every deck: a deck of cards or an unset deck takes cards; a root or a deck of decks takes a file split by `*` rows, or a flat file into one default deck (spec 2026-10-08 U1)".
  - Layout: add a row "Decks (sectioned) | `MxSection` of `ImportDeckRowWidget` | U2–U4" and change the Preview row to "rows grouped by deck, 50 across the import (U5)".
  - States: add `sectionsUndecided`, `sectionsDecided`, `sectionsResult` with their goldens, and `sectionsRefused` (no golden; U7 banner) and `sectionTargetChanged` (no golden; banner + Preview again).
  - Rulings: add "Spec 2026-10-08 U1–U9" as one bullet each, and change "Sheet: first non-empty" to "first sheet (S6)".
  - Copy: add the Task 9 strings.
  - Update the screen index row's golden count.

Run: `python3 tools/docs/generate.py && python3 tools/docs/check.py` → PASS.

- [ ] **Step 3: Gate**

Run: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`
Expected: PASS (format, analyze, generated code, architecture, docs, guard, full suite).

- [ ] **Step 4: Commit**

```bash
git add test/features/transfer docs/shared/ui docs/_generated
git commit -m "test(transfer): DEV-289 sectioned import goldens and screen 11 record"
```

- [ ] **Step 5: After the build (CLAUDE.md screen workflow step 5–6, not code):** Impeccable critique and one `impeccable audit` of the six new goldens against `DESIGN.md`; fix everything found in one batch; build the golden review page with the `golden-compare` skill for the owner; then the final whole-branch review on Opus.

---

## Self-review notes

- Spec coverage: §4.1 → Tasks 3, 5; §4.2 → Tasks 4, 6, 8; §4.3 → Tasks 5, 9; §4.4 → Tasks 3, 4, 5; §4.5 → Task 4; §5.3 (S6) → Task 2; §5.4 U1 → 8, U2–U7 → 9, U8 → 10, U9 → 9 (flat path untouched, goldens unchanged in 11); §5.5 → Tasks 4, 6, 7, 9; §6 docs → Tasks 1, 11; §7 testing → each task.
- Types: `ImportSectionChoice`, `ImportGroup`, `ImportDestination` (`IntoTarget`, `IntoNewDeck`, `IntoExistingDeck`, `Undecided`), `ImportNameProblem`, `ImportPlan.preview({defaultDeckName, choices})`, `CardImportTarget`, `CardImportChild`, `CardImportSection`, `CardImportSectionResult`, `ImportDeckResult` are named the same in every task.
