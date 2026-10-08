# MemoX V8 — Card import: deck sections (`*` rows)

Status: approved by the owner 2026-10-08 · epic DEV-289 · Path: architectural

## 1. Intent

The owner keeps vocabulary in hand-made spreadsheets where a row whose first cell starts
with `*` names a group, and the rows under it, up to the next `*` row, are that group's
words:

| Term | Meaning |
|---|---|
| \*Part 1 | \*Part 1 |
| 가난하다 | Be poor / Nghèo (…) |
| 끼우다 | Insert / Nhét vào (…) |
| \*관용어 | \*관용어 |
| 눈이 높다 | Standards are high / Kén chọn (…) |

Today UC-TRANSFER-001 writes every row into the one deck the import was opened from, so
`*Part 1` becomes a card. This change makes each `*` row a **deck**: one import of such a
file builds the sub-decks it names and fills each with its rows, in one transaction. A file
with no `*` row behaves as today: all its cards go into one deck.

Success means:

- the file above, imported from a deck that may hold sub-decks, yields sub-decks
  `Part 1`, `관용어`, … each holding exactly its rows, in one all-or-nothing transaction;
- a file with no `*` row imports exactly as it does today from a deck of cards or an
  `unset` deck;
- before anything is written, the preview shows the decks the import will create or add
  to, their cards, and asks the owner to decide every deck whose name is already taken;
- every new rule has a test that fails when it breaks; the gate passes; the use case, the
  rules, screen 11's detail file and its goldens change with the code.

## 2. Context (2026-10-08)

- Card Transfer is built (spec `2026-09-26-card-transfer-design.md`, BE-B3 and FE-B3).
  The import pipeline is: `ReadImportSourceUseCase` (file or pasted text → `SourceTable`)
  → `ColumnMapping` → `PreviewImportUseCase` / `buildImportPreview` (row statuses against
  the deck's `foldedPairs`) → `CommitImportUseCase` → `CardTransferRepository.importCards`
  (one `mappedTransaction`: check, duplicate re-check, `CardRepository.insertCards`).
- `CardTransferRepositoryImpl` already reaches the deck feature through
  `DeckContentRepository`; `DeckRepositoryImpl.createSubDeck` writes a sub-deck in its own
  `mappedTransaction`, and Drift nests a transaction opened inside another as a savepoint
  of the outer one.
- The deck tree rules that bound this change: a root holds only decks (BR-DECK-004); a
  deck holds cards or decks, never both (BR-DECK-009…011); a sub-deck is born `unset`
  (BR-DECK-006) and its `content_type` follows its direct children in the same
  transaction (BR-DECK-008, BR-DECK-015); depth at most 10 (BR-DECK-001); a name is not
  blank after trim and at most 200 characters (BR-DECK-020); names may repeat
  (BR-DECK-021).
- The "Import cards" action is offered today only where "Create card" is
  (`deck_level_screen.dart`: `canCreateCard`), i.e. on a deck of cards and on an `unset`
  sub-deck.
- XLSX reading picks the first sheet that holds anything (`XlsxDataSource._firstFilled`)
  and lets the user switch sheets (UC-TRANSFER-001 A2).

## 3. Decisions

| # | Decision | Ruling |
|---|---|---|
| S1 | Where the named decks go | Sub-decks of the deck the import was opened from (the **target**) | owner, 2026-10-08 |
| S2 | A section whose name is already a direct sub-deck of the target | The user decides on the preview, per section: "Add to existing" or "Create new". No default; Continue stays locked until every such section is decided | owner, 2026-10-08 |
| S3 | Rows before the first `*` row, in a file that has one | They go into a **default deck** | owner, 2026-10-08 |
| S4 | The default deck's name | A fixed localized name ("Uncategorized" / "Chưa phân loại"), editable on the preview | owner, 2026-10-08 |
| S5 | Which sources | Every source: XLSX, CSV, TSV and pasted text. The rule runs on the `SourceTable`, after parsing | owner, 2026-10-08 |
| S6 | XLSX sheets | The first sheet in workbook order is read by default, even when it is empty; the sheet switch stays | owner, 2026-10-08 |
| S7 | A file with `*` rows opened from a deck of cards | Refused at preview with a typed reason that says to import from the parent deck | owner, 2026-10-08 |
| S8 | Where the transaction lives | `CardTransferRepository` gains one batch write that creates the sub-decks and writes their cards in one `mappedTransaction` (approach A). Rejected: a unit-of-work abstraction in `core/` for one caller (B); one transaction per deck, which leaves half an import behind on failure (C) | owner, 2026-10-08 |

## 4. Rules

### 4.1 Section rows (new BR-TRANSFER-015)

- A **data row** (the header row, when there is one, is never a section row) is a
  **section row** when the cell of the column mapped to `front`, after trim, starts with
  `*`. Its other cells are ignored. A section row is neither a card nor a blank row and
  is not counted as either.
- The section's **name** is the text after the `*`, trimmed. It must pass BR-DECK-020
  (`DeckEntity.checkName`). A section whose name fails makes every card row under it
  **invalid**, with the deck-name reason; they are listed as skipped and never written.
  Section rows themselves are never listed as rows: their group header stands for them.
- Two section rows whose names fold equal (`foldText`: trim, NFC, lower case) are **one
  section**: rows under the second continue the first. The section keeps the spelling of
  its first section row.
- A section with no card row to write (none at all, or all blank, invalid or skipped
  duplicates) creates **no deck**. The preview says so.
- Card rows before the first section row belong to the **default section** (S3), whose
  name is S4's; the user may edit it on the preview, and the edited name passes
  BR-DECK-020 like any other.
- Known limit: a card whose `front` starts with `*` cannot be imported — it reads as a
  section row. There is no nesting (`**` is a section named `*…`).

A file is **sectioned** when it has at least one section row; otherwise it is **flat**.

### 4.2 Targets (BR-TRANSFER-001, amended)

| Target (where Import was opened) | Flat file | Sectioned file |
|---|---|---|
| Deck of cards | As today: cards into the target | Refused: `sectionsNeedDeckContainer` (S7) |
| `unset` sub-deck | As today: cards into the target, which becomes a deck of cards | Sub-decks per section, plus the default section if it has rows; the target becomes a deck of decks |
| Root, or deck of decks | One sub-deck, the default section, holds every card | Sub-decks per section, plus the default section if it has rows |
| Any target at depth 10 that would need a sub-deck | — | Refused: `depthExceeded` (BR-DECK-001) |

"Import cards" is therefore offered also on a root and on a deck of decks (wherever
"Create deck" or "Create card" is offered and the target can take the result). Every
target condition is checked again inside the commit transaction, as today.

### 4.3 Name clashes (S2)

- A section (default section included) **clashes** when a live direct sub-deck of the
  target has a name that folds equal to the section's name. When several do, the one first
  in sibling order is the clash.
- A clashing section shows a required choice: **Add to existing** or **Create new**.
  Add to existing is offered only when the existing deck is a deck of cards or `unset`;
  when it is a deck of decks the section is **Create new** without a choice, and its row
  says why (`MxSegmentedTray` has no per-option disable; the Decks block, U2, is the
  confirmation the owner asked for).
- Editing the default section's name re-evaluates its clash and clears a choice made for
  the old name.
- Continue stays locked while any clashing section is undecided.

### 4.4 Duplicates (BR-TRANSFER-003, amended)

Duplicates are measured per **destination deck**:

- a section added to an existing deck: against that deck's live cards and the earlier
  rows of the same section;
- a section creating a new deck: against the earlier rows of the same section only.

A flat import keeps today's rule (the target deck and the whole source). "Include
duplicates" stays one switch for the whole import. A row that repeats a row of another
section is not a duplicate.

### 4.5 Commit (BR-TRANSFER-004, BR-TRANSFER-005, amended)

One `mappedTransaction`, all or nothing:

1. Check the target again: it exists, is not a deck of cards when sections need it to
   hold decks, and has room for a level below it (BR-TRANSFER-001, BR-DECK-001).
2. For each section **in source order**: when it adds to an existing deck, check that
   deck again — still a live direct child of the target, still a deck of cards or
   `unset`; else refuse the whole import with `sectionTargetChanged`. Re-check duplicates
   against it (BR-TRANSFER-003). When the section still has a card to write, create its
   sub-deck if it is new (`createSubDeck` rules: BR-DECK-006, BR-DECK-020, sibling
   position after the existing children) and write its cards exactly as `importCards`
   writes them (one fresh study state each, tags by folded name, `content_type` per
   BR-DECK-015).
3. A section left with no card after the re-check creates no deck. When no section writes
   a card, nothing is written at all (E6 extended): the target's `content_type` and tree
   are unchanged.

Card ids are generated in write order across the whole import, so each deck lists and
exports its cards in source order (BR-TRANSFER-004, ADR-007). Decks get sibling positions
in source order.

## 5. Design

### 5.1 Domain (transfer)

- `import_sections_model.dart` (new): `ImportSection { name, firstRowNumber, isDefault }`
  and the pure `splitSections(table, mapping, hasHeaderRow, defaultName)` that returns
  the sections with their row ranges and the section rows' numbers. Pure, no I/O, unit
  tested on its own.
- `ImportPreview` gains `sections: List<ImportSectionPreview>`, each with its rows (the
  existing `ImportRow`s), its clash (`existingDeckId`, `existingDeckName`,
  `canAddToExisting`) and its own counts. A flat import has one section with
  `destination = target`, so today's preview is the one-section case and today's
  counts are sums over sections.
- `buildImportPreview` takes, per section, the folded pairs it is measured against
  (§4.4). The section rows themselves are reported as `ImportRowKind.section` so row
  numbers and the result list stay complete.
- `ImportSectionChoice { addToExisting, createNew }` lives in the controller state, keyed
  by section index; the preview never stores the user's choice.
- `TransferRejection` gains `sectionsNeedDeckContainer`, `depthExceeded`,
  `sectionTargetChanged`, `sectionChoiceMissing`; a deck-name failure is a row reason
  (`ImportRowReason.invalidDeckName`, alongside the existing `CardRejection` reasons).
- `PreviewImportUseCase` reads, besides the target's folded pairs, the target's live
  direct sub-decks (id, name, content type) and the folded pairs of each clashing deck of
  cards — one read each, never per row.
- `CommitImportUseCase` sends either the flat batch (today's `importCards`) or the
  sectioned batch below; the summary gains per-deck counts.

### 5.2 Data (card feature, owns the transaction — S8)

`CardTransferRepository` gains:

```dart
/// UC-TRANSFER-001 sectioned import, in one transaction (§4.5).
Future<Outcome<SectionedImportResult, CardRejection>> importSections({
  required String targetDeckId,
  required List<SectionBatch> sections, // name, existingDeckId?, drafts
  required bool includeDuplicates,
  DateTime? now,
});
```

The boundary map (`test/architecture/boundary_rules.dart`) gains `transfer → deck`
(`transfer → {card, deck}`, still acyclic) so the preview reuses `DeckEntity.checkName`
(BR-DECK-020) instead of a second copy of the name rule.

`CardTransferRepositoryImpl` gets the `DeckRepository` injected, as it already gets
`CardRepository`, and calls `createSubDeck` and the same per-deck path `importCards`
uses inside its own `mappedTransaction` (nested calls become savepoints of it). The
per-deck write is extracted from `importCards` into one private method both entry points
use, so the duplicate policy and the card write exist once. `DeckRepository` gains a
read of a deck's live direct children (id, name, content type) if no existing read
already serves it (checked at plan time; reuse first).

### 5.3 Source (S6)

`XlsxDataSource.read` defaults `sheetIndex` to `0` instead of the first filled sheet. An
empty first sheet is `emptySource` (E2) and the sheet switch still lets the user pick
another (A2).

### 5.4 UI (screen 11) — Impeccable `shape` rulings, owner 2026-10-08

Thesis: **decide the decks first, read the rows second.** No new step and no new shared
widget; the four-step tracker stays Source · Columns · Preview · Import.

- **U1 Entry.** The deck's `⋮` sheet offers "Import cards" on a root and on a deck of
  decks too (`deck_level_screen.dart` gating, §4.2).
- **U2 Decks block.** On a sectioned preview, under the global badges and the "Include
  duplicates" toggle, an `MxSection` "Decks" lists one row per destination: its name, an
  `MxBadge` New / Existing, and the cards it will receive. This block **is** the
  confirmation (owner: replaces the separate confirm step of the first draft); the footer
  stays "Import {n}".
- **U3 Clash choice.** A clashing destination's row holds an `MxSegmentedTray` "Add to
  existing" · "Create new" with `selected: null` until the user taps one. When the
  existing deck holds decks, the row shows no tray: it is New, and an `MxNote` says why
  (§4.3). An undecided row is not tinted; the empty tray is the cue.
- **U4 Default deck name.** The default destination's row holds an `MxTextField` with
  the localized default; a blank or over-long name shows the deck-name error under it
  (`MxFieldMessage`) and locks Import.
- **U5 Rows.** Below the Decks block the rows are grouped by an `MxListSectionHeader`
  per destination; section rows are not listed as rows (their header stands for them).
  The 50-row cap (K2) counts across the whole import.
- **U6 Locked footer.** While a clash is undecided or the default name is invalid,
  "Import {n}" is disabled and the footer caption says what is missing (e.g. "Choose how
  to import {k} decks with taken names").
- **U7 Refusals.** `sectionsNeedDeckContainer` and `depthExceeded` show as an
  `MxInlineBanner` (warning) on the Preview step with their guidance, Preview rows locked
  — the mapping-error pattern (K3), not the full-screen rejects state.
- **U8 Result.** The counts stay; a "Decks" `MxSection` lists each destination with its
  badge and the cards added. A sectioned import's primary action is "Back to deck" (the
  target now holds decks, so "View the cards" has no list to open); a flat import keeps
  "View the cards".
- **U9 Flat imports** look exactly as today; no Decks block.
- **Critique 2026-10-08 (owner-requested, after PR 270 opened), all five fixed:**
  - **C1** a group's rows are titled with the deck name as the user typed it, never
    upper-cased (DESIGN.md "user data is never upper-cased"), with its card count.
  - **C2** two or more clashes that need a choice add a first row to the Decks block,
    "{n} decks with taken names", with an `MxSegmentedTray` "Add all to existing" ·
    "Create all new", nothing chosen; it sets every such deck and each row still
    overrides it (S2 holds: no pre-selection).
  - **C3** a sectioned preview shows at most 3 rows per deck and "{n} more rows in this
    deck" under each; the 50-row ceiling of K2 still holds across the import.
  - **C4** a clash row names the facts: "{name} already has {n} cards."; once chosen it
    states the consequence ("Cards already in it are skipped." / "A second deck named
    {name} is made.").
  - **C5** "Include duplicates" explains the per-deck measure on a sectioned preview.
- Goldens (light and dark): `import_sections_undecided`, `import_sections_decided`,
  `import_sections_result`. After the build: Impeccable critique and one audit of these
  goldens against `DESIGN.md`, then the golden review page.
- Copy is localized (EN and VI ARB); the new strings are listed in the plan and must
  fit the 360 dp tray (The Short Label Rule).

### 5.5 Error flows (UC-TRANSFER-001, amended)

| Case | Behaviour |
|---|---|
| Sectioned file from a deck of cards | Preview refused, `sectionsNeedDeckContainer`, nothing written |
| Target at depth 10 needs a sub-deck | Preview refused, `depthExceeded` |
| Section name blank after `*` or over 200 characters | Its rows invalid with the deck-name reason; the other sections import |
| Clash undecided | Continue locked; commit refuses `sectionChoiceMissing` if reached |
| Existing deck chosen for "Add" changed between preview and commit (gone, moved, became a deck of decks) | Whole commit refused `sectionTargetChanged`; preview and choices kept; Try again re-previews |
| Every card of every section became a duplicate at commit | "Nothing added", no deck created, target unchanged (E6) |

## 6. Documents that change

- New `docs/features/transfer/rules/BR-TRANSFER-015-dong-sao-la-ten-deck.md` (§4.1).
- BR-TRANSFER-001 (targets, §4.2), BR-TRANSFER-003 (per destination, §4.4),
  BR-TRANSFER-004 and BR-TRANSFER-005 (sectioned commit, §4.5).
- UC-TRANSFER-001: trigger (root, deck of decks), steps 4–8, A2 (first sheet by default),
  new alternative flow for sections and clashes, the error flows of §5.5, acceptance
  criteria for each.
- `docs/shared/ui/screen-handoff/11-card-import.md` and its row in the screen index.
- Linear: one epic for this spec once approved, its plan's tasks as sub-issues.

## 7. Testing

| Level | What |
|---|---|
| Domain unit | `splitSections`: header on/off, rows before the first section, empty section, repeated section names folded together, `*` with blank name, name over 200, `front` cell `  *x` (trimmed), no section rows → flat |
| Domain unit | `buildImportPreview` per destination: duplicates inside a section, across sections (not duplicates), against an existing deck; clash detection incl. folded names and a deck of decks |
| Use case | Preview refusals (deck of cards + sections, depth 10); commit routing flat vs sectioned; summary per deck |
| Repository (Drift, in-memory) | `importSections`: decks created in source order with sibling positions; add-to-existing; target `unset` → deck of decks; zero-card section creates no deck; nothing written when all drop; rollback when one write fails mid-batch; `sectionTargetChanged` when the existing deck moved |
| Source | XLSX reads sheet 0 by default even when it is empty and sheet 1 is not |
| Controller | Clash choices required before Continue; editing the default name clears its choice |
| Widget + goldens | Sectioned preview (clash undecided/decided), confirm, result; light and dark |

## 8. Relation to "Import from the Library"

The spec `2026-10-08-library-import-entry-design.md` (epic DEV-288, branch
`claude/intelligent-mccarthy-ytn8tx`, in owner review) adds Library entry points whose
dialog always ends on a sub-deck that is `unset` or holds cards, then opens this wizard.
The two are separate epics (owner, 2026-10-08):

- Its out-of-scope line ("Import cards" in a root's action sheet, no change to
  BR-TRANSFER-001) is exactly what this spec does; neither contradicts the other.
- A sectioned file imported through its dialog lands its section decks **under the chosen
  sub-deck**: a new `unset` sub-deck becomes a deck of decks; an existing deck of cards
  is refused (S7). To put sections directly under a root, Import opens from the root's
  `⋮` sheet (§4.2).
- Both change UC-TRANSFER-001 and screen 11's detail file; whichever branch merges second
  merges those documents.

## 9. Out of scope

- Nested sections (`**`), section markers other than `*`, or a marker in a column other
  than the one mapped to `front`.
- Auto-mapping headers such as `Term` / `Meaning` (spec D2 stands).
- Importing several sheets in one go.
- Changing an existing deck's name or position from the import screen.
