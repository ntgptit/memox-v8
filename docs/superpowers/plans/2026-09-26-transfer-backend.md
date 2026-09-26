# MemoX V8 Card Transfer Backend Implementation Plan (package 9a)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the CSV, TSV and pasted-text half of BE-B3 of
[`docs/wbs_BE.md`](../../wbs_BE.md), the store side of Card Transfer (UC-TRANSFER-001,
UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014), as domain, data and use-case code in a
new `transfer` feature and a batch create in `card`, so FE-B3 can build screens 11 and 12
on four use cases. XLSX is package 9b.

**Architecture:** A new feature, `lib/features/transfer` (domain, data, di), that imports
`card`. Import runs in three calls: `readSource` decodes a `.csv` or `.tsv` file (strict
UTF-8) or pasted text into numbered rows, on another isolate; `previewImport` classifies
every data row with the pure `ImportPreview.classify`, which judges a row by the card's
own rules (`CardDraft.firstFailure`) and its folded key, in one order the preview and the
commit share; `importCards` classifies again inside one transaction and hands the rows to
write to `CardRepository.createCards`, the batch form of a card create, whose ids ascend
in file order. `ScheduleRepository.initializeCards` replaces `initializeCard` and reads
the root once. Export is one call: `exportCards` reads one snapshot in one transaction,
writes CSV or TSV (a BOM, the canonical headers, CRLF, minimal quoting) and names the
file from the deck and the local day. No schema change.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `drift` 2.35, `flutter_riverpod` 3 with
`riverpod_generator`, `characters`. No dependency is added; the one generated output a
task needs is the new provider's (`build_runner`, Task 3).

**Spec:**
[`docs/superpowers/specs/2026-09-26-transfer-backend-design.md`](../specs/2026-09-26-transfer-backend-design.md),
approved 2026-09-26. Business rules: `docs/features/transfer/rules/`
(BR-TRANSFER-001…BR-TRANSFER-014); use cases:
`docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`
and `UC-TRANSFER-002-export-card-cua-deck-ra-file.md`; data model:
[`shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-transfer` holds the spec (`026ba63`), its approval
(`e9c9184`) and this plan, on `master` at `d41f9be` (#70). The plan runs on that
branch, from this plan's commit; the gate passes there with 1601 tests. Generated
code is not committed: in a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`
first (root `README.md`, "Commands").

**How this plan was checked:** every code block below was written and run first, in
a scratch copy of the repository, task by task, test first. Each task's tests failed
as its "Expected" line says, then passed, and after every task the gate passed. The
import was timed there at 1,500 and 10,000 rows (Clarification 4). Each rule the
tests pin was also broken on purpose in the scratch copy, one at a time: in Task 1,
ids in random order; an empty batch that skips the deck check; an empty batch that
flips an unset deck; a batch without its tags; an unset deck left unset; the fields
checked out of form order; a schedule row at another generation than the root's; the
root read once a card; a deck in the Trash given its root's schedule; in Task 2, the
header row read as data; a blank row judged; blank rows counted as data; an invalid
row that claims its key; a duplicate of an earlier row before one in the deck; the
key unfolded; duplicates written whether included or not; a header matched in one
case only; the last column with a name wins; a column that keeps its old field; the
back not required; a backslash not escaped; a legacy backslash taken for an escape;
an empty name kept; in Task 3, keys that count cards in the Trash; keys that count
another deck's cards; a commit that trusts the preview; an incomplete mapping
committed; included duplicates reported as skipped; a deck that takes no card
reported as gone; in Task 4, an extension read in one case only; a U+0000 accepted;
`;` never chosen; `;` chosen over `,`; pasted text never split on tabs; a blank
first line that decides the delimiter; a doubled quote not read as one; a line break
at the end read as a record; an unclosed quote read; in Task 5, an export without
its BOM; records ended by LF; a cell quoted only for the delimiter; quotes not
doubled; cards in the Trash exported; newest first; tags by stored name; a deck in
the Trash exported; a stale selection exported; an empty field written as null; a
failed read left unmapped; a name not cut to 200 bytes; a name cut inside a
character; characters a file system refuses kept; no name when nothing is left; a
month without its zero. That is 54 breaks. Every break failed a test, on an
assertion. After the first pass, the five tests of the Review Focus below were added
to their tasks; all five passed on the code as it stood, and one test name that
claimed more than its test checks was corrected (Clarification 10). This document
was then applied, step by step as written, onto a clean checkout of this plan's
commit: each task's files matched the scratch commit's, no other file moved, and the
outputs and counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: no screen, no route, no copy, no provider but the repository's. Screens
  11 and 12, picking a file, the private cache file, the share sheet, the routes and
  IT-NAV-012 are FE-B3's (spec §12).
- CSV, TSV and pasted text only: XLSX, reading and writing, `encodeFailed` and
  `passwordProtected` are package 9b (D3, D19).
- No schema change, no migration, no dependency (§13).
- `transfer` imports `card` and no other feature: the import map gains
  `'transfer': {'card'}` (spec §4, ADR-011). The domain is pure Dart: it imports
  `core/error`, `core/text`, `core/clock` and `card/domain`, nothing from Flutter or
  drift.
- One reason enum, `TransferRejection`, with the eight reasons of spec §4, in that
  order: `unsupportedFormat`, `notUtf8`, `unreadable`, `mappingIncomplete`,
  `deckNotFound`, `deckRejectsCards`, `emptyScope`, `staleSelection`.
- A file is `.csv` or `.tsv` by the extension after its last dot, in any case; its bytes
  are strict UTF-8 after an optional UTF-8 BOM; a UTF-16 BOM, a malformed sequence or a
  U+0000 is `notUtf8`, and no other encoding is guessed (§5.1, D4, BR-TRANSFER-006).
- The delimiter is chosen by §5.2 (D5), records are read by §5.3, and a quoted field
  still open at the end is `unreadable` (D6).
- A row is classified, in this order: blank, invalid (with its first failing field),
  a duplicate in the deck, a duplicate of an earlier row, ready. A valid row claims its
  key; an invalid row claims nothing. The key is `(foldText(front), foldText(back))`,
  what `card` stores (§6.2, D8, BR-TRANSFER-003).
- The tags cell goes through `TagCell` and nothing else, on import and on export
  (BR-TRANSFER-009, D9).
- The commit classifies again inside one transaction and writes through
  `CardRepository.createCards`; a refusal writes nothing, and a failure rolls
  everything back and leaves as the `Failure` of `mapDatabaseError` (§7,
  BR-TRANSFER-004).
- The cards of one import share one `created_at`, and their ids ascend in file order,
  so `(created_at, id)` keeps the file's order (D11).
- An export reads one snapshot in one transaction, three statements, each filtering the
  Trash, and writes nothing (§8.1, BR-TRANSFER-011).
- An export file: a UTF-8 BOM, the header `front,back,example,hint,pronunciation,tags`
  (tabs in a TSV), a CRLF after every record, and a cell quoted, its quotes doubled,
  only when it holds the delimiter, `"`, CR or LF (D14, BR-TRANSFER-012).
- Its name: the deck's name sanitized by §8.3 and cut to 200 UTF-8 bytes on whole
  graphemes, `cards` when nothing is left, then a space, the local day of
  `DayClock.now()` as `yyyy-MM-dd`, a dot and the extension (D15, BR-TRANSFER-013).
- No Unicode normalisation (D17).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing `call`
  (AD-12).
- Every statement on `card` or `deck` filters `delete_batch_id` (BR-TRASH-002);
  `tombstone_filter_test.dart` checks the SQL text.
- After every task the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It runs the host
  suite with `TZ=UTC` and `--exclude-tags golden`. Its generated-code check asks
  every source under `lib/` to be in git, so each task stages its files, runs the
  gate, then commits.
- The guard fails a hand-written file at 400 logical lines
  (`common.no_large_source_file`); `card_repository_impl.dart` stands at 379 and
  ends Task 1 at 377 (Clarification 2).
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a use case id runs `python3 tools/docs/generate.py` and commits
  `docs/_generated/`.
- The contract documents change only as spec §11 says, with the two WBS corrections
  of Clarification 7 and the WBS item of Clarification 8.
- Code, identifiers, test names and commit messages are in English; `docs/` keeps
  its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan. Each is
decided here and implemented as described; say so if one is wrong.

1. **Two booleans read as predicates** (Task 2; spec §6.1). The spec's
   `firstRowIsHeader` and `includeDuplicates` are `hasHeaderRow` and
   `shouldIncludeDuplicates` in the code, on `ImportSettings` and `ImportPreview`: the
   guard's `memox.naming.boolean_reads_as_predicate` fails the gate on the spec's
   names.
2. **The mapper takes the card list's assembly** (Task 1). With `createCards`,
   `card_repository_impl.dart` would reach 406 logical lines, past the guard's 400. The
   card list view and the review history page are assembled in `card_mapper.dart` from
   now on, as `cardListViewOf` and `historyPageOf`, unchanged; the file ends at 377.
3. **A draft without tags writes no tags** (Task 1; spec §7 step 5). Every card's tags
   go through `TagRepository.replaceForCard`, as a single create does, but a new card
   carries no tag yet, so a draft without tags is skipped: one savepoint and two reads
   fewer for each such card. `createCard` gets the same skip; its result does not
   change.
4. **The import's speed, measured** (Task 3; spec §7 step 5, §13). In this container,
   on an in-memory database, one transaction: 1,500 rows took 539 ms without tags and
   1,631 ms with two tags a row; 10,000 rows took 1,244 ms and 8,148 ms. The per-card
   tag write dominates. Ruling: no batch tag API in 9a (spec §12): a list of a thousand
   rows, the README's case, stays under two seconds here even with tags. FE-B3 shows the
   submitting state for as long as the transaction runs; a batch tag write comes when a
   measurement on a device asks for it. The 1,500-row test pins the order, not the time: a
   time bound would fail on a slow machine.
5. **The snapshot reads whole card rows** (Task 5; spec §8.1). drift's `select(card)`
   reads every column of the deck's active cards, a superset of "`id` and the six
   content columns"; the file carries only the six.
6. **The IT scenarios the store answers** (Task 3). IT-CARD-014 and IT-CARD-015 are
   `HOST-FLOW` scenarios of UC-TRANSFER-001: `import_cards_test.dart` names their store
   side, steps 1–4 of each, and Task 6 counts them in `wbs_BE.md`. Their screen steps,
   and IT-NAV-012, are FE-B3's.
7. **Two WBS lines that no longer held** (Task 6). Both WBS said CI runs on every pull
   request; #67 paused it (root `README.md`, "CI"), and Task 6 says so. `wbs_BE.md`
   counted 63 IT ids in the tests, but #68 added IT-DISC-007: with this package's two,
   the tests name 66.
8. **The NFC decision is BE-C5** (Task 6; spec D17). The item joins the backlog of the
   deck and card backend, `bị chặn` on the owner's decision, with its row in "Điểm chặn
   và quyết định còn mở": `foldText` trims and lowers case only, so `é` and `e` + U+0301
   are two keys, and changing the fold changes stored columns.
9. **A BOM on each side** (Tasks 4 and 5). The reader drops a UTF-8 BOM itself, as D4
   says. `utf8.decode` would drop a leading one too, silently, so the export tests check
   the BOM's three bytes before they decode the rest.
10. **What the use case test can see of the isolate** (Task 4). `readSource` runs the
    decode in `Isolate.run`; no test can observe the isolate itself.
    `ReadImportSourceUseCase`'s test goes through the real repository, so the source and
    the document cross isolates in it, and its name says only what it checks.
11. **The task order** (Tasks 2–5). The classification (Task 2) and the commit (Task 3)
    come before the reader (Task 4): they take rows, not bytes, so their tests build
    sheets by hand, and Task 5's round trip then runs export, reader and commit
    together.
12. **The plan's date.** The plan is written on 2026-09-26, the spec's day.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person,
beyond the five of spec §10 that the tests already pin, each pinned by a test in the
task that owns the code:

1. **A tags cell typed by hand**: spaces around the names, a tag the library holds in
   another case, a comma inside a name. The card carries the library's `noun` and one
   new tag `verb, adj`, with no space kept at either end (a comma is part of a name:
   BR-TRANSFER-009) — Task 3, "a tags cell typed by hand: spaces around the names, the
   library's tag in another case, a comma inside a name".
2. **Excel's "CSV UTF-8" from a locale with a decimal comma**, as Vietnamese is: a BOM,
   `;` between fields, CRLF, `1,5` unquoted, and a tags cell quoted because it holds
   `;`. Three columns, the decimal comma in its cell, the tags cell whole — Task 4,
   "Excel's \"CSV UTF-8\" from a locale with a decimal comma".
3. **Text copied from a spreadsheet**: tabs, CRLF, a cell of two lines in quotes, and a
   line break at the end. One row a record, the cell's line break kept, no blank row at
   the end — Task 4, "text copied from a spreadsheet".
4. **A file exported from a deck and imported back into it**: every row is a duplicate
   in the deck, nothing is written, and the result says so — Task 5, "the file imported
   back into its own deck adds nothing".
5. **A read that fails during an export**: a database `Failure`, no file, the state
   `failed` for FE-B3 — Task 5, "a read that fails leaves as a database Failure, with
   no file".

## File Structure

```
lib/features/card/
├── domain/models/card_field_model.dart        CardField (1)
├── domain/models/card_draft_model.dart        firstFailure; check answers its reason (1)
├── domain/repositories/card_repository.dart   createCards (1)
├── data/mappers/card_mapper.dart              cardListViewOf, historyPageOf (1)
└── data/repositories/card_repository_impl.dart   createCards; createCard is a batch of one (1)

lib/features/srs/
├── domain/repositories/schedule_repository.dart  initializeCards replaces initializeCard (1)
├── data/datasources/srs_dao.dart                 rootOfDeck (1)
└── data/repositories/schedule_repository_impl.dart   the root read once (1)

lib/features/transfer/                          (new)
├── domain/
│   ├── failures/transfer_failure.dart          TransferRejection (3; 4, 5 add reasons)
│   ├── models/import_sheet_model.dart          ImportRow, ImportSheet, ImportDocument,
│   │                                           columnLetter (2)
│   ├── models/column_mapping_model.dart        canonicalHeaders, ColumnMapping (2)
│   ├── models/tag_cell_model.dart              TagCell (2)
│   ├── models/import_preview_model.dart        ImportSettings, ImportRowOutcome…,
│   │                                           ImportPreview (2)
│   ├── models/import_result_model.dart         ImportResult (3)
│   ├── models/transfer_format_model.dart       TransferFormat (4)
│   ├── models/import_source_model.dart         ImportSource, ImportFile, PastedText (4)
│   ├── models/export_model.dart                ExportScope…, ExportFile, exportFileName (5)
│   ├── repositories/transfer_repository.dart   previewImport, importCards (3);
│   │                                           readSource (4); exportCards (5)
│   └── usecases/                               preview_import, import_cards (3);
│                                               read_import_source (4); export_cards (5)
├── data/
│   ├── datasources/transfer_dao.dart           contentKeys (3); the snapshot (5)
│   ├── mappers/delimited_text_mapper.dart      readDelimited (4); writeDelimited (5)
│   └── repositories/transfer_repository_impl.dart   (3, 4, 5)
└── di/transfer_repository_provider.dart        transferRepositoryProvider (3)

test/architecture/boundary_rules.dart           'transfer': {'card'} (2)
test/features/card/…                            card_create_batch_test (1), and the
                                                four fakes of ScheduleRepository (1)
test/features/srs/…                             initializeCards (1)
test/features/transfer/domain/                  column_mapping_test, tag_cell_test,
                                                import_classification_test (2);
                                                transfer_use_cases_test (3, 4, 5);
                                                export_file_name_test (5)
test/features/transfer/data/                    import_cards_test (3), delimited_text_test (4),
                                                export_cards_test (5)
```

Other changed files: `docs/_generated/` where a task's tests name a new id (Tasks
1–5), and in Task 6 UC-TRANSFER-001, UC-TRANSFER-002, the transfer README,
`wbs_BE.md` and `wbs_FE.md`.

---


### Task 1: Create cards in a batch, in their order

**Files:**
- Create: `lib/features/card/domain/models/card_field_model.dart`
- Modify: `lib/features/card/data/mappers/card_mapper.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `lib/features/card/domain/models/card_draft_model.dart`, `lib/features/card/domain/repositories/card_repository.dart`, `lib/features/srs/data/datasources/srs_dao.dart`, `lib/features/srs/data/repositories/schedule_repository_impl.dart`, `lib/features/srs/domain/repositories/schedule_repository.dart`
- Test (create): `test/features/card/data/card_create_batch_test.dart`
- Test (modify): `test/features/card/data/card_repository_impl_test.dart`, `test/features/card/domain/card_draft_model_test.dart`, `test/features/deck/presentation/deck_algorithm_screen_test.dart`, `test/features/deck/presentation/deck_reset_dialog_test.dart`, `test/features/srs/data/schedule_repository_impl_test.dart`, `test/features/srs/domain/reset_learning_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `DeckEntity.checkCreateCard`; `TagRepository.replaceForCard`; `CardDao`'s
  `deckRow`, `insertCard`, `findRow` and `setDeckContentType`; `newId`;
  `SelectCounter` of `test/support/test_database.dart`.
- Produces:
  - `enum CardField { front, back, example, hint, pronunciation, tags }`
    (`card/domain/models/card_field_model.dart`).
  - `({CardField field, CardRejection reason})? CardDraft.firstFailure()`;
    `CardDraft.check()` answers its reason.
  - `Future<Outcome<List<String>, CardRejection>> CardRepository.createCards({required String deckId, required List<CardDraft> drafts, DateTime? now})`,
    the ids in the order of `drafts`.
  - `Future<void> ScheduleRepository.initializeCards({required String deckId, required List<String> cardIds})`,
    which replaces `initializeCard({required String cardId})`, and
    `Future<Deck?> SrsDao.rootOfDeck(String deckId)`.
  - In `card_mapper.dart`: `CardListView cardListViewOf({required List<(CardRow, CardSchedule)> shown, required bool hasMore, required ({int all, int due, int newCards, int flagged}) counts, required List<CardSchedule> schedules, required Map<String, List<Tag>> tags, required DateTime now})`
    and `ReviewHistoryPage historyPageOf(List<ReviewLog> logs)`.

Spec §7, D11, D12, D20; Clarifications 2 and 3. The contract change touches the
four fakes of `ScheduleRepository` in the tests (spec §13), and the schedule test counts
the root reads with `SelectCounter`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/data/card_create_batch_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryRow;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRANSFER-001 step 7: an import writes its rows through createCards,
// the batch form of a card create (BR-TRANSFER-001, BR-TRANSFER-004,
// BR-TRANSFER-005; transfer spec §7, D11).

DateTime _now() => DateTime(2026, 9, 26, 10);

List<CardDraft> _drafts(int count) => [
  for (var i = 1; i <= count; i++) CardDraft(front: 'w$i', back: 'm$i'),
];

Matcher _refused(CardRejection reason) =>
    isA<Rejected<List<String>, CardRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

/// Fails the schedule rows of a batch, after its cards are inserted.
final class _FailingSchedules implements ScheduleRepository {
  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) async => throw StateError('schedule rows not written');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late DeckEntity root;
  late DeckEntity leaf;

  CardRepositoryImpl cardsWith(ScheduleRepository schedules) =>
      CardRepositoryImpl(
        db,
        schedules,
        TagRepositoryImpl(db, now: _now),
        now: _now,
      );

  setUp(() async {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: _now);
    cards = cardsWith(ScheduleRepositoryImpl(db, now: _now));
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  });
  tearDown(() => db.close());

  Future<List<QueryRow>> cardRows() => db
      .customSelect(
        'SELECT id, front, created_at FROM card ORDER BY created_at, id',
      )
      .get();

  test('the drafts become cards in their order: ids ascend with the list and '
      'every card shares one created_at (transfer spec D11)', () async {
    final result = await cards.createCards(
      deckId: leaf.id,
      drafts: _drafts(12),
    );

    final ids = (result as Ok<List<String>, CardRejection>).value;
    expect(ids, hasLength(12));
    expect(ids, [...ids]..sort());
    final rows = await cardRows();
    expect(
      [for (final row in rows) row.read<String>('front')],
      [for (var i = 1; i <= 12; i++) 'w$i'],
    );
    expect([for (final row in rows) row.read<String>('id')], ids);
    expect(
      {for (final row in rows) row.read<DateTime>('created_at')},
      {_now()},
    );
  });

  test('each card has one schedule row of its root, and tags reused or '
      'created by folded name (BR-TRANSFER-004)', () async {
    final sm2 = await decks.root('s', SchedulerType.sm2);
    final sm2Leaf = await decks.sub(sm2.id, 'l');
    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      sm2.id,
    ]);

    await cards.createCards(
      deckId: sm2Leaf.id,
      drafts: const [
        CardDraft(front: 'a', back: '1', tagNames: ['Noun']),
        CardDraft(front: 'b', back: '2', tagNames: ['noun', 'verb']),
      ],
    );

    final schedules = await db
        .customSelect(
          'SELECT scheduler_type, generation, learned_at, due_at '
          'FROM card_schedule',
        )
        .get();
    expect(schedules, hasLength(2));
    for (final row in schedules) {
      expect(row.read<String>('scheduler_type'), 'sm2');
      expect(row.read<int>('generation'), 2);
      expect(row.data['learned_at'], isNull);
      expect(row.data['due_at'], isNull);
    }
    final links = await db
        .customSelect(
          'SELECT c.front, t.name FROM card_tags ct '
          'JOIN card c ON c.id = ct.card_id JOIN tags t ON t.id = ct.tag_id '
          'ORDER BY c.front, t.name_folded',
        )
        .get();
    expect(
      [
        for (final row in links)
          '${row.read<String>('front')}:${row.read<String>('name')}',
      ],
      ['a:Noun', 'b:Noun', 'b:verb'],
    );
  });

  test('an unset deck becomes a deck of cards with the first card written, '
      'and an empty list changes nothing (BR-TRANSFER-005)', () async {
    final before = await totalChanges(db);

    expect(
      await cards.createCards(deckId: leaf.id, drafts: const []),
      isA<Ok<List<String>, CardRejection>>().having(
        (ok) => ok.value,
        'ids',
        isEmpty,
      ),
    );
    expect(await totalChanges(db), before);
    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.unset);

    await cards.createCards(deckId: leaf.id, drafts: _drafts(2));

    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.card);
  });

  test('the deck is checked even for an empty list: gone, in the Trash, a '
      'root or holding sub-decks (BR-TRANSFER-001)', () async {
    final mid = await decks.sub(root.id, 'mid');
    await decks.sub(mid.id, 'inner');
    final trashed = await decks.sub(root.id, 't');
    await trashDeckRows(db, trashed.id);
    final before = await totalChanges(db);

    for (final (deckId, reason) in [
      ('missing', CardRejection.notFound),
      (trashed.id, CardRejection.notFound),
      (root.id, CardRejection.notACardContainer),
      (mid.id, CardRejection.notACardContainer),
    ]) {
      for (final drafts in [const <CardDraft>[], _drafts(1)]) {
        expect(
          await cards.createCards(deckId: deckId, drafts: drafts),
          _refused(reason),
          reason: '$deckId with ${drafts.length} drafts',
        );
      }
    }
    expect(await totalChanges(db), before);
  });

  test('one draft the card rules refuse refuses the batch, which writes '
      'nothing (BR-TRANSFER-002)', () async {
    final before = await totalChanges(db);

    final result = await cards.createCards(
      deckId: leaf.id,
      drafts: [
        ..._drafts(2),
        const CardDraft(front: 'x', back: ' '),
      ],
    );

    expect(result, _refused(CardRejection.blankContent));
    expect(await totalChanges(db), before);
  });

  test('schedule rows that cannot be written roll the whole batch back '
      '(BR-TRANSFER-004)', () async {
    await expectLater(
      cardsWith(_FailingSchedules())
          .createCards(deckId: leaf.id, drafts: _drafts(3)),
      throwsA(anything),
    );

    expect(await cardRows(), isEmpty);
    expect((await decks.findById(leaf.id))!.contentType, DeckContentType.unset);
  });
}
```

In `test/features/card/data/card_repository_impl_test.dart`:

Replace

```dart
  @override
  Future<void> initializeCard({required String cardId}) async =>
      throw StateError('schedule row not written');

```

with

```dart
  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) async => throw StateError('schedule row not written');

```

In `test/features/card/domain/card_draft_model_test.dart`:

Replace

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';

```

with

```dart
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';

```

Replace

```dart
          CardRejection.tooManyTags,
        );
      },
    );
  });
}
```

with

```dart
          CardRejection.tooManyTags,
        );
      },
    );
  });

  group('firstFailure (BR-TRANSFER-002)', () {
    test('a valid draft has none', () {
      const draft = CardDraft(front: 'f', back: 'b', tagNames: ['noun']);
      expect(draft.firstFailure(), isNull);
    });
    test('it names the first failing field and its reason, in form order', () {
      expect(const CardDraft(front: ' ', back: '').firstFailure(), (
        field: CardField.front,
        reason: CardRejection.blankContent,
      ));
      expect(const CardDraft(front: 'f', back: '').firstFailure(), (
        field: CardField.back,
        reason: CardRejection.blankContent,
      ));
      expect(CardDraft(front: 'f' * 61, back: '').firstFailure(), (
        field: CardField.front,
        reason: CardRejection.frontTooLong,
      ));
      expect(
        CardDraft(
          front: 'f',
          back: 'b',
          example: 'e' * 241,
          hint: 'h' * 241,
        ).firstFailure(),
        (field: CardField.example, reason: CardRejection.optionalFieldTooLong),
      );
      expect(CardDraft(front: 'f', back: 'b', hint: 'h' * 241).firstFailure(), (
        field: CardField.hint,
        reason: CardRejection.optionalFieldTooLong,
      ));
      expect(
        CardDraft(
          front: 'f',
          back: 'b',
          pronunciation: 'p' * 241,
        ).firstFailure(),
        (
          field: CardField.pronunciation,
          reason: CardRejection.optionalFieldTooLong,
        ),
      );
      expect(
        const CardDraft(front: 'f', back: 'b', tagNames: ['  ']).firstFailure(),
        (field: CardField.tags, reason: CardRejection.invalidTagName),
      );
    });
  });
}
```

In `test/features/deck/presentation/deck_algorithm_screen_test.dart`:

Replace

```dart
  @override
  Future<void> initializeCard({required String cardId}) =>
      _real.initializeCard(cardId: cardId);

```

with

```dart
  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) => _real.initializeCards(deckId: deckId, cardIds: cardIds);

```

In `test/features/deck/presentation/deck_reset_dialog_test.dart`:

Replace

```dart
  @override
  Future<void> initializeCard({required String cardId}) =>
      _real.initializeCard(cardId: cardId);

```

with

```dart
  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) => _real.initializeCards(deckId: deckId, cardIds: cardIds);

```

In `test/features/srs/data/schedule_repository_impl_test.dart`:

Replace

```dart

  test('initializeCard writes the start values of the root scheduler at the root generation (BR-CARD-004)', () async {
    await insertStudyTree(db, 'r', scheduler: 'sm2');
```

with

```dart

  test('initializeCards writes the start values of the root scheduler at the root generation, for every card (BR-CARD-004)', () async {
    await insertStudyTree(db, 'r', scheduler: 'sm2');
```

Replace

```dart
    await insertBareCard(db, 'new', 'r-leaf');

    await repo.initializeCard(cardId: 'new');

    expectStartValues(
      await scheduleRowOf(db, 'new'),
      scheduler: 'sm2',
      generation: 3,
    );
  });

  test('initializeCard of a missing card throws', () async {
    await expectLater(repo.initializeCard(cardId: 'missing'), throwsStateError);
  });
```

with

```dart
    await insertBareCard(db, 'new', 'r-leaf');
    await insertBareCard(db, 'next', 'r-leaf');

    await repo.initializeCards(deckId: 'r-leaf', cardIds: ['new', 'next']);

    for (final cardId in ['new', 'next']) {
      expectStartValues(
        await scheduleRowOf(db, cardId),
        scheduler: 'sm2',
        generation: 3,
      );
    }
  });

  test('initializeCards reads the root once, whatever the number of cards (BR-TRANSFER-004)', () async {
    final counter = SelectCounter();
    final counted = openTestDatabase(interceptor: counter);
    addTearDown(counted.close);
    await insertStudyTree(counted, 'r');
    for (final cardId in ['n1', 'n2', 'n3']) {
      await insertBareCard(counted, cardId, 'r-leaf');
    }
    counter.selects = 0;

    await ScheduleRepositoryImpl(counted)
        .initializeCards(deckId: 'r-leaf', cardIds: ['n1', 'n2', 'n3']);

    expect(counter.selects, 1);
  });

  test('initializeCards for a deck that is gone throws', () async {
    await expectLater(
      repo.initializeCards(deckId: 'missing', cardIds: ['x']),
      throwsStateError,
    );
  });
```

In `test/features/srs/domain/reset_learning_use_cases_test.dart`:

Replace

```dart
    );
    await schedules.initializeCard(cardId: 'c');
    await db.customStatement(
```

with

```dart
    );
    await schedules.initializeCards(deckId: 'leaf', cardIds: ['c']);
    await db.customStatement(
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/data/card_create_batch_test.dart \
  test/features/card/data/card_repository_impl_test.dart \
  test/features/card/domain/card_draft_model_test.dart \
  test/features/deck/presentation/deck_algorithm_screen_test.dart \
  test/features/deck/presentation/deck_reset_dialog_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart
```

Expected: `+9 -6: Some tests failed.` Six of the seven test files do not compile:
`Error: Error when reading 'lib/features/card/domain/models/card_field_model.dart': No such file or directory`,
`Error: The method 'firstFailure' isn't defined for the type 'CardDraft'.`,
`Error: The method 'createCards' isn't defined for the type 'CardRepositoryImpl'.`,
`Error: The method 'initializeCards' isn't defined for the type 'ScheduleRepositoryImpl'.`,
and for the two widget tests' fakes
`Error: The non-abstract class '_FirstSwitchFails' is missing implementations for these members:`
and the same for `_GatedReset`. `card_repository_impl_test.dart` compiles, its fake
answering every other member through `noSuchMethod`, and its nine tests pass.

- [ ] **Step 3: Name the fields, and say which one fails first**

Create `lib/features/card/domain/models/card_field_model.dart`:

```dart
/// The six content fields of a card, in form order (card `ui.md`): the order
/// [CardDraft.firstFailure] checks them in, and the columns a transfer file
/// carries (BR-TRANSFER-008).
enum CardField { front, back, example, hint, pronunciation, tags }
```

In `lib/features/card/domain/models/card_draft_model.dart`:

Replace

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
```

with

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/tags/domain/entities/tag_entity.dart';
```

Replace

```dart

  /// The first failing field, in form order: front, back, example, hint,
  /// pronunciation, tags.
  Outcome<void, CardRejection> check() {
    final checks = [
      () => checkFront(front),
      () => checkBack(back),
      () => checkOptional(example),
      () => checkOptional(hint),
      () => checkOptional(pronunciation),
      () => checkTagNames(tagNames),
    ];
    for (final check in checks) {
      final result = check();
      if (result case Rejected()) return result;
    }
    return const Ok(null);
  }
```

with

```dart

  /// The reason of [firstFailure], or `Ok` when every field passes.
  Outcome<void, CardRejection> check() => switch (firstFailure()) {
    null => const Ok(null),
    (field: _, :final reason) => Rejected(reason),
  };

  /// The first failing field and its reason, in form order: front, back,
  /// example, hint, pronunciation, tags. Import names it at the row it
  /// refuses (BR-TRANSFER-002); null when the draft passes.
  ({CardField field, CardRejection reason})? firstFailure() {
    final checks = {
      CardField.front: () => checkFront(front),
      CardField.back: () => checkBack(back),
      CardField.example: () => checkOptional(example),
      CardField.hint: () => checkOptional(hint),
      CardField.pronunciation: () => checkOptional(pronunciation),
      CardField.tags: () => checkTagNames(tagNames),
    };
    for (final MapEntry(key: field, value: check) in checks.entries) {
      if (check() case Rejected(:final reason)) {
        return (field: field, reason: reason);
      }
    }
    return null;
  }
```

- [ ] **Step 4: Write the schedule rows of many cards from one read of the root**

In `lib/features/srs/domain/repositories/schedule_repository.dart`:

Replace

```dart
abstract interface class ScheduleRepository {
  /// Writes the schedule row of a card just created (BR-CARD-004): the start
  /// values of its root's scheduler, at the root's generation. Joins the
  /// caller's transaction. Throws [StateError] when the card does not exist:
  /// the caller inserts the card first, in that same transaction, so a
  /// missing card is a bug, not a business outcome.
  Future<void> initializeCard({required String cardId});

```

with

```dart
abstract interface class ScheduleRepository {
  /// Writes the schedule rows of [cardIds], cards just created in [deckId]
  /// (BR-CARD-004): the start values of the root's scheduler, at the root's
  /// generation, both read once for every card (BR-TRANSFER-004). Joins the
  /// caller's transaction. Throws [StateError] when the deck or its root is
  /// gone: the caller checked the deck in that same transaction, so that is
  /// a bug, not a business outcome.
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  });

```

In `lib/features/srs/data/datasources/srs_dao.dart`:

Replace

```dart
          readsFrom: {_db.card, _db.deck},
        )
```

with

```dart
          readsFrom: {_db.card, _db.deck},
        )
        .getSingleOrNull();
    return row == null ? null : _db.deck.map(row.data);
  }

  /// The root of [deckId]'s tree, reached through `deck.root_id`
  /// (BR-DECK-003); null when the deck or its root is in the Trash.
  Future<Deck?> rootOfDeck(String deckId) async {
    final row = await _db
        .customSelect(
          'SELECT root.* FROM deck d JOIN deck root ON root.id = d.root_id'
          ' WHERE d.id = ? AND d.delete_batch_id IS NULL'
          ' AND root.delete_batch_id IS NULL',
          variables: [Variable<String>(deckId)],
          readsFrom: {_db.deck},
        )
```

In `lib/features/srs/data/repositories/schedule_repository_impl.dart`:

Replace

```dart
  @override
  Future<void> initializeCard({required String cardId}) =>
      _db.transaction(() async {
        final root = await _dao.rootOfCard(cardId);
        if (root == null) throw StateError('card $cardId does not exist');
        final type = SchedulerType.fromCode(root.schedulerType!);
        final state = CardScheduleState.initial(
          type,
          generation: root.generation!,
        );
        await _dao.insertSchedule(
          _columnsOf(
            state,
            type: type,
            version: root.schedulerVersion!,
          ).copyWith(cardId: Value(cardId)),
        );
      });

```

with

```dart
  @override
  Future<void> initializeCards({
    required String deckId,
    required List<String> cardIds,
  }) => _db.transaction(() async {
    final root = await _dao.rootOfDeck(deckId);
    if (root == null) throw StateError('deck $deckId has no active root');
    final type = SchedulerType.fromCode(root.schedulerType!);
    final start = _columnsOf(
      CardScheduleState.initial(type, generation: root.generation!),
      type: type,
      version: root.schedulerVersion!,
    );
    for (final cardId in cardIds) {
      await _dao.insertSchedule(start.copyWith(cardId: Value(cardId)));
    }
  });

```

- [ ] **Step 5: Create cards in a batch; one card is a batch of one**

`card_mapper.dart` takes the card list's and the history page's assembly, unchanged,
so that `card_repository_impl.dart` stays under the guard's 400 logical lines with
`createCards` (Clarification 2).

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  });
```

with

```dart
    required String deckId,
    required CardDraft draft,
    DateTime? now,
  });

  /// UC-TRANSFER-001 step 7: [drafts] become cards of [deckId] as
  /// [createCard] makes one. Every draft is checked, then the deck, even for
  /// an empty list; then each card is written with its schedule row and its
  /// tags, and an `unset` deck becomes a deck of cards when a card is written
  /// (BR-TRANSFER-004, BR-TRANSFER-005). The cards share one `created_at`
  /// and their ids ascend in the order of [drafts], so `(created_at, id)`
  /// keeps that order (transfer spec D11). Answers the ids in that order and
  /// joins the caller's transaction.
  Future<Outcome<List<String>, CardRejection>> createCards({
    required String deckId,
    required List<CardDraft> drafts,
    DateTime? now,
  });
```

In `lib/features/card/data/mappers/card_mapper.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart
  tags: [for (final tag in tags) TagEntity(id: tag.id, name: tag.name)],
);

/// The display state of every schedule row, counted once each.
```

with

```dart
  tags: [for (final tag in tags) TagEntity(id: tag.id, name: tag.name)],
);

/// The card list from its reads: the rows [shown], whether more follow, the
/// filter counts of the query, every schedule row of the deck, and the tags
/// of the rows shown.
CardListView cardListViewOf({
  required List<(CardRow, CardSchedule)> shown,
  required bool hasMore,
  required ({int all, int due, int newCards, int flagged}) counts,
  required List<CardSchedule> schedules,
  required Map<String, List<Tag>> tags,
  required DateTime now,
}) {
  final startOfToday = startOfLocalDay(now);
  return CardListView(
    items: [
      for (final (card, schedule) in shown)
        listItemOf(
          card,
          schedule,
          tags: tags[card.id] ?? const [],
          startOfToday: startOfToday,
        ),
    ],
    hasMore: hasMore,
    counts: CardListCounts(
      all: counts.all,
      due: counts.due,
      newCards: counts.newCards,
      flagged: counts.flagged,
    ),
    statusCounts: statusCountsOf(schedules),
    workload: workloadOf(schedules, startOfToday),
  );
}

/// The display state of every schedule row, counted once each.
```

Replace

```dart

DeckTreeNode deckTreeNodeOf(DeckForestRow row) => DeckTreeNode(
```

with

```dart

/// A page of the history from [logs], read one row past the page: its
/// entries, and the cursor after the last one when more follow.
ReviewHistoryPage historyPageOf(List<ReviewLog> logs) {
  final entries = [
    for (final log in logs.take(ReviewHistoryPage.size)) historyEntryOf(log),
  ];
  return ReviewHistoryPage(
    entries: entries,
    next: logs.length > ReviewHistoryPage.size
        ? ReviewHistoryCursor(
            answeredAt: entries.last.answeredAt,
            id: entries.last.id,
          )
        : null,
  );
}

DeckTreeNode deckTreeNodeOf(DeckForestRow row) => DeckTreeNode(
```

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
```

with

```dart
import 'package:memox/features/deck/domain/models/deck_tree_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
```

Replace

```dart
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
      final deck = await _dao.deckRow(deckId);
      if (deck == null) return const Rejected(CardRejection.notFound);
      final contentType = DeckContentType.values.byName(deck.contentType);
      final container = DeckEntity.checkCreateCard(
        parentContentType: contentType,
      );
      if (container case Rejected()) {
        return const Rejected(CardRejection.notACardContainer);
      }

      final id = newId();
      await _dao.insertCard(id: id, deckId: deckId, draft: draft, now: at);
      await _schedules.initializeCard(cardId: id);
      await _replaceTags(id, draft, at);
      if (contentType == DeckContentType.unset) {
        await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
      }
      return Ok(cardEntityOf((await _dao.findRow(id))!));
    });
  }

```

with

```dart
    DateTime? now,
  }) => _write(
    () async => switch (await _create(deckId, [draft], now ?? _now())) {
      Rejected(:final reason) => Rejected(reason),
      Ok(value: final ids) => Ok(
        cardEntityOf((await _dao.findRow(ids.single))!),
      ),
    },
  );

  @override
  Future<Outcome<List<String>, CardRejection>> createCards({
    required String deckId,
    required List<CardDraft> drafts,
    DateTime? now,
  }) => _write(() => _create(deckId, drafts, now ?? _now()));

```

Replace

```dart
    );
    final counts = await _listDao.counts(
      deckId: deckId,
      searchTerm: query.searchTerm,
      tagIds: query.tagIds,
      now: now,
    );
    final schedules = await _listDao.activeSchedules(deckId);
    final shown = rows.take(windowSize).toList();
    final tags = await _listDao.tagsOf([
      for (final (card, _) in shown) card.id,
    ]);
    final startOfToday = startOfLocalDay(now);
    return CardListView(
      items: [
        for (final (card, schedule) in shown)
          listItemOf(
            card,
            schedule,
            tags: tags[card.id] ?? const [],
            startOfToday: startOfToday,
          ),
      ],
      hasMore: rows.length > windowSize,
      counts: CardListCounts(
        all: counts.all,
        due: counts.due,
        newCards: counts.newCards,
        flagged: counts.flagged,
      ),
      statusCounts: statusCountsOf(schedules),
      workload: workloadOf(schedules, startOfToday),
    );
```

with

```dart
    );
    final shown = rows.take(windowSize).toList();
    return cardListViewOf(
      shown: shown,
      hasMore: rows.length > windowSize,
      counts: await _listDao.counts(
        deckId: deckId,
        searchTerm: query.searchTerm,
        tagIds: query.tagIds,
        now: now,
      ),
      schedules: await _listDao.activeSchedules(deckId),
      tags: await _listDao.tagsOf([for (final (card, _) in shown) card.id]),
      now: now,
    );
```

Replace

```dart
    if (rows.isEmpty) return null;
    final logs = [
      for (final row in rows)
        if (row.r case final ReviewLog log) log,
    ];
    final entries = [
      for (final log in logs.take(ReviewHistoryPage.size)) historyEntryOf(log),
    ];
    return ReviewHistoryPage(
      entries: entries,
      next: logs.length > ReviewHistoryPage.size
          ? ReviewHistoryCursor(
              answeredAt: entries.last.answeredAt,
              id: entries.last.id,
            )
          : null,
    );
  });
```

with

```dart
    if (rows.isEmpty) return null;
    return historyPageOf([
      for (final row in rows)
        if (row.r case final ReviewLog log) log,
    ]);
  });
```

Replace

```dart
    return _moveTargetsOf(await _detailDao.restoreTargetRows(roots.single));
  }
```

with

```dart
    return _moveTargetsOf(await _detailDao.restoreTargetRows(roots.single));
  }

  /// A card create for any number of drafts: every draft is checked, then
  /// the deck; nothing is written before both pass. The ids ascend in the
  /// drafts' order and the cards share [at], so `(created_at, id)` keeps
  /// that order (transfer spec D11).
  Future<Outcome<List<String>, CardRejection>> _create(
    String deckId,
    List<CardDraft> drafts,
    DateTime at,
  ) async {
    for (final draft in drafts) {
      if (draft.check() case Rejected(:final reason)) return Rejected(reason);
    }
    final deck = await _dao.deckRow(deckId);
    if (deck == null) return const Rejected(CardRejection.notFound);
    final contentType = DeckContentType.values.byName(deck.contentType);
    final container = DeckEntity.checkCreateCard(
      parentContentType: contentType,
    );
    if (container case Rejected()) {
      return const Rejected(CardRejection.notACardContainer);
    }
    if (drafts.isEmpty) return const Ok([]);

    final ids = [for (final _ in drafts) newId()]..sort();
    for (final (index, draft) in drafts.indexed) {
      await _dao.insertCard(
        id: ids[index],
        deckId: deckId,
        draft: draft,
        now: at,
      );
    }
    await _schedules.initializeCards(deckId: deckId, cardIds: ids);
    // A new card carries no tag yet, so a draft without tags has none to
    // write: skipping it spares an import one savepoint and two reads a card.
    for (final (index, draft) in drafts.indexed) {
      if (draft.tagNames.isEmpty) continue;
      await _replaceTags(ids[index], draft, at);
    }
    if (contentType == DeckContentType.unset) {
      await _dao.setDeckContentType(deckId, DeckContentType.card.name, at);
    }
    return Ok(ids);
  }
```

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 52 warning(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/card/data/card_create_batch_test.dart \
  test/features/card/data/card_repository_impl_test.dart \
  test/features/card/domain/card_draft_model_test.dart \
  test/features/deck/presentation/deck_algorithm_screen_test.dart \
  test/features/deck/presentation/deck_reset_dialog_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart
```

Expected: `+69: All tests passed!`

- [ ] **Step 8: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/card/data/mappers/card_mapper.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/models/card_draft_model.dart \
  lib/features/card/domain/models/card_field_model.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  lib/features/srs/data/datasources/srs_dao.dart \
  lib/features/srs/data/repositories/schedule_repository_impl.dart \
  lib/features/srs/domain/repositories/schedule_repository.dart \
  test/features/card/data/card_create_batch_test.dart \
  test/features/card/data/card_repository_impl_test.dart \
  test/features/card/domain/card_draft_model_test.dart \
  test/features/deck/presentation/deck_algorithm_screen_test.dart \
  test/features/deck/presentation/deck_reset_dialog_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 9: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 52 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1610: All tests passed!`.

- [ ] **Step 10: Commit**

```bash
git commit -F - <<'EOF'
feat(card): create cards in a batch, in their order

createCards is the batch form of a card create: every draft is checked,
then the deck, even for an empty list; then the cards, one schedule row
each and their tags, and an unset deck becomes a deck of cards once
(BR-TRANSFER-001, BR-TRANSFER-004, BR-TRANSFER-005). The cards share one
created_at and their ids ascend in the list's order, so (created_at, id)
keeps it (transfer spec D11); createCard is a batch of one (D20).
initializeCards replaces initializeCard and reads the root once for all
the cards. CardDraft.firstFailure names the first failing field with its
reason, and check() answers that reason (D12). The card list and history
pages are assembled in the mapper, which keeps card_repository_impl.dart
under the guard's 400 lines.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: Map a sheet's columns and classify its rows

**Files:**
- Create: `lib/features/transfer/domain/models/column_mapping_model.dart`, `lib/features/transfer/domain/models/import_preview_model.dart`, `lib/features/transfer/domain/models/import_sheet_model.dart`, `lib/features/transfer/domain/models/tag_cell_model.dart`
- Test (create): `test/features/transfer/domain/column_mapping_test.dart`, `test/features/transfer/domain/import_classification_test.dart`, `test/features/transfer/domain/tag_cell_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's `CardField` and `CardDraft.firstFailure`; `foldText`
  (`lib/core/text/folded_text.dart`).
- Produces:
  - `ImportRow({required int number, required List<String> cells})` with `isBlank` and
    `String cellAt(int column)`; `ImportSheet({String? name, required List<ImportRow> rows})`
    with `columnCount` and `isEmpty`; `ImportDocument(List<ImportSheet> sheets)` with
    `defaultSheetIndex`; `String columnLetter(int index)`
    (`transfer/domain/models/import_sheet_model.dart`).
  - `const Map<CardField, String> canonicalHeaders` and
    `ColumnMapping([Map<CardField, int> columns = const {}])` with
    `ColumnMapping.byHeader(List<String> headerCells)`,
    `ColumnMapping.byPosition(int columnCount)`, `int? columnOf(CardField)`,
    `CardField? fieldAt(int)`, `ColumnMapping assign(CardField, int)`,
    `ColumnMapping unassign(CardField)` and `Set<CardField> missing`.
  - `TagCell.encode(Iterable<String> names)` and `TagCell.decode(String cell)`.
  - `ImportSettings({bool hasHeaderRow = true, ColumnMapping? mapping, bool shouldIncludeDuplicates = false})`;
    `typedef ContentKey = (String frontFolded, String backFolded)`;
    `sealed class ImportRowOutcome(int rowNumber)` with `ImportRowReady(rowNumber, CardDraft draft)`,
    `ImportRowDuplicate(rowNumber, CardDraft draft, {int? firstRowNumber})`,
    `ImportRowInvalid(rowNumber, {required String front, required String back, required CardField field, required CardRejection reason})`
    and `ImportRowBlank(rowNumber)`.
  - `ImportPreview.classify({required ImportSheet sheet, required ImportSettings settings, required Set<ContentKey> deckKeys})`
    with `mapping`, `shouldIncludeDuplicates`, `rows`, `dataRowCount`, `readyCount`,
    `duplicateCount`, `invalidCount`, `blankCount`, `writeCount` and
    `List<CardDraft> toWrite`.

Spec §5, §6, D7–D9; Clarification 1. Pure Dart: every test builds its sheet by
hand. The import map lets `transfer` import `card` from here on.

- [ ] **Step 1: Write the failing tests**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'trash': {'deck', 'card'},
};
```

with

```dart
  'trash': {'deck', 'card'},
  'transfer': {'card'},
};
```

Create `test/features/transfer/domain/column_mapping_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

// UC-TRANSFER-001 steps 4 and A2, A3: the columns a sheet feeds the card
// fields through (BR-TRANSFER-002; transfer spec D7).

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

void main() {
  group('the default mapping', () {
    test('a header maps the six canonical names, trimmed and in any case; '
        'the first column wins', () {
      final mapping = ColumnMapping.byHeader([
        ' Front ',
        'BACK',
        'note',
        'Tags',
        'front',
        'Pronunciation',
      ]);

      expect(mapping.columns, {
        CardField.front: 0,
        CardField.back: 1,
        CardField.tags: 3,
        CardField.pronunciation: 5,
      });
    });

    test('other names, the app labels among them, map nothing', () {
      expect(
        ColumnMapping.byHeader(['term', 'meaning', 'sentence', 'labels'])
            .columns,
        isEmpty,
      );
    });

    test('without a header, column A is the front and B the back', () {
      expect(ColumnMapping.byPosition(0).columns, isEmpty);
      expect(ColumnMapping.byPosition(1).columns, {CardField.front: 0});
      expect(ColumnMapping.byPosition(4).columns, {
        CardField.front: 0,
        CardField.back: 1,
      });
    });
  });

  group('changing the mapping', () {
    const mapping = ColumnMapping({CardField.front: 0, CardField.back: 1});

    test('a field moved to a column leaves its old column, and the column '
        'leaves its old field', () {
      expect(mapping.assign(CardField.back, 0).columns, {CardField.back: 0});
      expect(mapping.assign(CardField.example, 2).columns, {
        CardField.front: 0,
        CardField.back: 1,
        CardField.example: 2,
      });
      expect(mapping.assign(CardField.front, 1).columns, {CardField.front: 1});
    });

    test('a field unassigned reads no column', () {
      expect(mapping.unassign(CardField.back).columns, {CardField.front: 0});
      expect(mapping.fieldAt(1), CardField.back);
      expect(mapping.fieldAt(2), isNull);
      expect(mapping.columnOf(CardField.tags), isNull);
    });

    test('front and back are required', () {
      expect(mapping.missing, isEmpty);
      expect(mapping.unassign(CardField.back).missing, {CardField.back});
      expect(const ColumnMapping().missing, {CardField.front, CardField.back});
    });
  });

  test('a column is named by letters: A…Z, then AA', () {
    expect(
      [
        for (final index in [0, 1, 25, 26, 27, 51, 52, 701, 702])
          columnLetter(index),
      ],
      ['A', 'B', 'Z', 'AA', 'AB', 'AZ', 'BA', 'ZZ', 'AAA'],
    );
  });

  test('a sheet is as wide as its widest row, and empty when every row is '
      'blank', () {
    final sheet = _sheet([
      ['a'],
      ['b', 'c', ' '],
    ]);
    expect(sheet.columnCount, 3);
    expect(sheet.isEmpty, isFalse);
    expect(
      _sheet([
        [' ', '\t'],
        [''],
      ]).isEmpty,
      isTrue,
    );
    expect(_sheet([]).columnCount, 0);
  });

  test('a document opens on its first sheet that is not empty '
      '(UC-TRANSFER-001 A2)', () {
    final empty = _sheet([
      ['  '],
    ]);
    final full = _sheet([
      ['a', 'b'],
    ]);

    expect(ImportDocument([empty, full, empty]).defaultSheetIndex, 1);
    expect(ImportDocument([full]).defaultSheetIndex, 0);
    expect(ImportDocument([empty, empty]).defaultSheetIndex, 0);
  });
}
```

Create `test/features/transfer/domain/import_classification_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

// UC-TRANSFER-001 step 5, E2, E3: every data row's status, by the card's
// own rules and the duplicate key (BR-TRANSFER-002, BR-TRANSFER-003;
// transfer spec §6.2, D8).

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

ImportPreview _classify(
  List<List<String>> rows, {
  ImportSettings settings = const ImportSettings(),
  Set<ContentKey> deckKeys = const {},
}) => ImportPreview.classify(
  sheet: _sheet(rows),
  settings: settings,
  deckKeys: deckKeys,
);

/// Each row as `number status`, with what the status names.
List<String> _statuses(ImportPreview preview) => [
  for (final row in preview.rows)
    switch (row) {
      ImportRowReady(:final rowNumber) => '$rowNumber ready',
      ImportRowDuplicate(:final rowNumber, firstRowNumber: null) =>
        '$rowNumber duplicate in the deck',
      ImportRowDuplicate(:final rowNumber, :final firstRowNumber?) =>
        '$rowNumber duplicate of $firstRowNumber',
      ImportRowInvalid(:final rowNumber, :final field, :final reason) =>
        '$rowNumber invalid ${field.name} ${reason.name}',
      ImportRowBlank(:final rowNumber) => '$rowNumber blank',
    },
];

void main() {
  test('every status, in the order the rules run', () {
    final preview = _classify(
      [
        ['front', 'back', 'example'],
        ['reservation', 'sự đặt chỗ trước', ''],
        ['bill', '', ''],
        [' Reservation ', 'Sự đặt chỗ trước', ''],
        ['tip', 'tiền boa', ''],
        ['', '', ''],
        ['TIP', 'Tiền boa ', 'an example'],
        ['a' * 61, 'too long', ''],
        ['menu', 'thực đơn', ''],
      ],
      deckKeys: {('reservation', 'sự đặt chỗ trước')},
    );

    expect(_statuses(preview), [
      '2 duplicate in the deck',
      '3 invalid back blankContent',
      '4 duplicate in the deck',
      '5 ready',
      '6 blank',
      '7 duplicate of 5',
      '8 invalid front frontTooLong',
      '9 ready',
    ]);
    expect(
      (
        preview.readyCount,
        preview.duplicateCount,
        preview.invalidCount,
        preview.blankCount,
        preview.dataRowCount,
      ),
      (2, 3, 2, 1, 7),
    );
    expect(preview.writeCount, 2);
    expect([for (final draft in preview.toWrite) draft.front], ['tip', 'menu']);
  });

  test('with duplicates included they are written too, in row order '
      '(UC-TRANSFER-001 A4)', () {
    final preview = _classify(
      [
        ['front', 'back'],
        ['tip', 'tiền boa'],
        ['bill', 'hóa đơn'],
        ['tip', 'tiền boa'],
      ],
      settings: const ImportSettings(shouldIncludeDuplicates: true),
      deckKeys: {('bill', 'hóa đơn')},
    );

    expect(_statuses(preview), [
      '2 ready',
      '3 duplicate in the deck',
      '4 duplicate of 2',
    ]);
    expect(preview.writeCount, 3);
    expect(
      [for (final draft in preview.toWrite) draft.front],
      ['tip', 'bill', 'tip'],
    );
  });

  test('an invalid row claims no key: a later valid copy of it is ready', () {
    final preview = _classify([
      ['front', 'back', 'hint'],
      ['tip', 'tiền boa', 'h' * 241],
      ['tip', 'tiền boa', ''],
    ]);

    expect(_statuses(preview), [
      '2 invalid hint optionalFieldTooLong',
      '3 ready',
    ]);
  });

  test('blank is every cell of the row, mapped or not; text in an unmapped '
      'column alone leaves the front empty', () {
    final preview = _classify([
      ['front', 'back', 'note'],
      [' ', '\t', ''],
      ['', '', 'a note'],
    ]);

    expect(_statuses(preview), ['2 blank', '3 invalid front blankContent']);
    expect(preview.dataRowCount, 1);
  });

  test('an invalid row keeps its front and back, trimmed, for display', () {
    final row =
        _classify([
              ['front', 'back'],
              ['  bill ', ''],
            ]).rows.single
            as ImportRowInvalid;

    expect((row.front, row.back), ('bill', ''));
  });

  test('the tags cell goes through the codec, and the tag rules judge the '
      'names', () {
    final preview = _classify([
      ['front', 'back', 'tags'],
      ['a', '1', r'noun;x\;y;; '],
      [
        'b',
        '2',
        [for (var i = 0; i < 11; i++) 't$i'].join(';'),
      ],
    ]);

    expect((preview.rows.first as ImportRowReady).draft.tagNames, [
      'noun',
      'x;y',
    ]);
    expect(_statuses(preview).last, '3 invalid tags tooManyTags');
  });

  test('the header row is not a card; without a header the first row is '
      'data, read through columns A and B (UC-TRANSFER-001 A3)', () {
    const rows = [
      ['front', 'back'],
      ['tip', 'tiền boa'],
    ];

    expect(_statuses(_classify(rows)), ['2 ready']);
    final headless = _classify(
      rows,
      settings: const ImportSettings(hasHeaderRow: false),
    );
    expect(_statuses(headless), ['1 ready', '2 ready']);
    expect(headless.mapping.columns, {CardField.front: 0, CardField.back: 1});
  });

  test('a mapping given wins over the default, and a mapped column past '
      'the end of a row reads empty', () {
    final preview = _classify(
      [
        ['a', 'b', 'c'],
        ['x', 'tip', 'tiền boa'],
        ['y', 'bill'],
      ],
      settings: const ImportSettings(
        mapping: ColumnMapping({CardField.front: 1, CardField.back: 2}),
      ),
    );

    expect(_statuses(preview), ['2 ready', '3 invalid back blankContent']);
    expect((preview.rows.first as ImportRowReady).draft.front, 'tip');
  });

  test('without front or back mapped no row is judged, and the data rows '
      'are still counted', () {
    final preview = _classify([
      ['term', 'meaning'],
      ['tip', 'tiền boa'],
      ['', ''],
    ]);

    expect(preview.mapping.missing, {CardField.front, CardField.back});
    expect(preview.rows, isEmpty);
    expect(preview.dataRowCount, 1);
    expect(preview.writeCount, 0);
  });

  test('a source with no data row counts none (UC-TRANSFER-001 E2), and one '
      'with nothing to write has a write count of 0 (E3)', () {
    expect(
      _classify([
        ['front', 'back'],
      ]).dataRowCount,
      0,
    );
    expect(_classify([]).dataRowCount, 0);
    expect(
      _classify([
        ['front', 'back'],
        [' ', ''],
      ]).dataRowCount,
      0,
    );

    final allDuplicates = _classify(
      [
        ['front', 'back'],
        ['tip', 'tiền boa'],
      ],
      deckKeys: {('tip', 'tiền boa')},
    );
    expect(allDuplicates.dataRowCount, 1);
    expect(allDuplicates.writeCount, 0);
  });
}
```

Create `test/features/transfer/domain/tag_cell_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/tag_cell_model.dart';

// BR-TRANSFER-009: one codec for the tags cell, import and export alike.

void main() {
  test('names are joined by ";", with ";" and "\\" escaped inside a name', () {
    expect(
      TagCell.encode(['noun', 'a;b', r'c\d', r'e\']),
      r'noun;a\;b;c\\d;e\\',
    );
    expect(TagCell.encode([]), '');
  });

  test(r'decoding splits on each ";" no "\" escapes, and unescapes', () {
    expect(TagCell.decode(r'noun;a\;b;c\\d;e\\'), [
      'noun',
      'a;b',
      r'c\d',
      r'e\',
    ]);
  });

  test(r'a "\" before anything else, or at the end, stays as it is: legacy '
      'sources never escaped', () {
    expect(TagCell.decode(r'a\b;c\'), [r'a\b', r'c\']);
  });

  test('a segment empty after trim is dropped; names keep their spaces', () {
    expect(TagCell.decode('noun;; verb ;'), ['noun', ' verb ']);
    expect(TagCell.decode(''), isEmpty);
    expect(TagCell.decode(' ; '), isEmpty);
  });

  test('a round trip keeps every name and its spelling', () {
    const names = ['Động từ', 'a;b', r'\', r'\;', ';', 'x\\\\y', '명사'];

    expect(TagCell.decode(TagCell.encode(names)), names);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/domain/column_mapping_test.dart \
  test/features/transfer/domain/import_classification_test.dart \
  test/features/transfer/domain/tag_cell_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three test files compiles:
`Error: Error when reading 'lib/features/transfer/domain/models/import_sheet_model.dart': No such file or directory`,
and the same for `column_mapping_model.dart`, `tag_cell_model.dart` and
`import_preview_model.dart`.

- [ ] **Step 3: Read a sheet as numbered rows, and name its columns**

Create `lib/features/transfer/domain/models/import_sheet_model.dart`:

```dart
import 'dart:math' show max;

/// One record of an import source: its number in the source, from 1, and
/// its cells as read, untrimmed (transfer spec §5).
final class ImportRow {
  const ImportRow({required this.number, required this.cells});

  final int number;
  final List<String> cells;

  /// Every cell is empty after trim (BR-TRANSFER-002).
  bool get isBlank => cells.every((cell) => cell.trim().isEmpty);

  /// The cell of [column], or the empty string past the end of the row.
  String cellAt(int column) => column < cells.length ? cells[column] : '';
}

/// A table read from a source: a CSV or TSV file and pasted text are one
/// sheet; a workbook has one per sheet (package 9b).
final class ImportSheet {
  const ImportSheet({this.name, required this.rows});

  /// Null but in a workbook.
  final String? name;
  final List<ImportRow> rows;

  /// The number of cells of the widest row.
  int get columnCount =>
      rows.fold(0, (widest, row) => max(widest, row.cells.length));

  /// No row holds anything but whitespace.
  bool get isEmpty => rows.every((row) => row.isBlank);
}

/// What a source reads as: its sheets, in order.
final class ImportDocument {
  const ImportDocument(this.sheets);

  final List<ImportSheet> sheets;

  /// The first sheet that is not empty, or the first sheet
  /// (UC-TRANSFER-001 A2).
  int get defaultSheetIndex {
    final index = sheets.indexWhere((sheet) => !sheet.isEmpty);
    return index < 0 ? 0 : index;
  }
}

/// The name a spreadsheet gives the column at [index]: 0 is A, 25 is Z and
/// 26 is AA (UC-TRANSFER-001 A3).
String columnLetter(int index) {
  var letters = '';
  for (var rest = index + 1; rest > 0; rest = (rest - 1) ~/ 26) {
    letters = String.fromCharCode(0x41 + (rest - 1) % 26) + letters;
  }
  return letters;
}
```

- [ ] **Step 4: Map columns to fields**

Create `lib/features/transfer/domain/models/column_mapping_model.dart`:

```dart
import 'package:memox/features/card/domain/models/card_field_model.dart';

/// The header of each field in a transfer file, in file order: English,
/// lowercase, never localized (BR-TRANSFER-008, BR-TRANSFER-012).
const canonicalHeaders = {
  CardField.front: 'front',
  CardField.back: 'back',
  CardField.example: 'example',
  CardField.hint: 'hint',
  CardField.pronunciation: 'pronunciation',
  CardField.tags: 'tags',
};

/// Which column of a sheet feeds which field of a card: each field at most
/// one column, each column at most one field (UC-TRANSFER-001 step 4,
/// BR-TRANSFER-002; transfer spec D7).
final class ColumnMapping {
  const ColumnMapping([this.columns = const {}]);

  /// Each field reads the first column whose header cell, trimmed and in
  /// any case, is its canonical header.
  factory ColumnMapping.byHeader(List<String> headerCells) {
    final columns = <CardField, int>{};
    for (final (column, cell) in headerCells.indexed) {
      final name = cell.trim().toLowerCase();
      for (final MapEntry(key: field, value: header)
          in canonicalHeaders.entries) {
        if (header == name) columns.putIfAbsent(field, () => column);
      }
    }
    return ColumnMapping(columns);
  }

  /// With no header, column A is the front and column B the back, when the
  /// sheet has them (UC-TRANSFER-001 A3).
  factory ColumnMapping.byPosition(int columnCount) => ColumnMapping({
    if (columnCount > 0) CardField.front: 0,
    if (columnCount > 1) CardField.back: 1,
  });

  final Map<CardField, int> columns;

  int? columnOf(CardField field) => columns[field];

  CardField? fieldAt(int column) {
    for (final MapEntry(key: field, value: at) in columns.entries) {
      if (at == column) return field;
    }
    return null;
  }

  /// [field] reads [column]; the field the column fed before, if any, and
  /// the column the field read before, if any, are let go.
  ColumnMapping assign(CardField field, int column) => ColumnMapping({
    for (final MapEntry(key: other, value: at) in columns.entries)
      if (other != field && at != column) other: at,
    field: column,
  });

  ColumnMapping unassign(CardField field) => ColumnMapping({
    for (final MapEntry(key: other, value: at) in columns.entries)
      if (other != field) other: at,
  });

  /// The fields every row needs that no column feeds (BR-TRANSFER-002).
  Set<CardField> get missing => {
    for (final field in const [CardField.front, CardField.back])
      if (!columns.containsKey(field)) field,
  };
}
```

- [ ] **Step 5: Encode and decode the tags cell**

Create `lib/features/transfer/domain/models/tag_cell_model.dart`:

```dart
/// The one codec of the tags cell, for import and export alike
/// (BR-TRANSFER-009, BR-TAG-011).
abstract final class TagCell {
  /// The names joined by `;`; inside a name, `\` becomes `\\` and `;`
  /// becomes `\;`.
  static String encode(Iterable<String> names) => names
      .map((name) => name.replaceAll(r'\', r'\\').replaceAll(';', r'\;'))
      .join(';');

  /// The names of [cell], split on each `;` no `\` escapes. `\;` and `\\`
  /// unescape; a `\` before anything else, or at the end, stays as it is,
  /// since legacy sources never escaped. A name empty after trim is dropped;
  /// the tag rules trim the others where they always do.
  static List<String> decode(String cell) {
    final names = <String>[];
    final name = StringBuffer();
    void endName() {
      if (name.toString().trim().isNotEmpty) names.add(name.toString());
      name.clear();
    }

    var index = 0;
    while (index < cell.length) {
      final char = cell[index];
      final next = index + 1 < cell.length ? cell[index + 1] : null;
      index++;
      if (char == r'\' && (next == ';' || next == r'\')) {
        name.write(next);
        index++;
        continue;
      }
      if (char == ';') {
        endName();
        continue;
      }
      name.write(char);
    }
    endName();
    return names;
  }
}
```

- [ ] **Step 6: Classify every data row**

Create `lib/features/transfer/domain/models/import_preview_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/tag_cell_model.dart';

/// What the person chose before the preview (UC-TRANSFER-001 steps 4-5).
final class ImportSettings {
  const ImportSettings({
    this.hasHeaderRow = true,
    this.mapping,
    this.shouldIncludeDuplicates = false,
  });

  final bool hasHeaderRow;

  /// Null for the default of the header choice (transfer spec D7).
  final ColumnMapping? mapping;

  /// UC-TRANSFER-001 A4.
  final bool shouldIncludeDuplicates;
}

/// A row's duplicate key: its front and back folded as `card` stores them,
/// `front_folded` and `back_folded` (BR-TRANSFER-003).
typedef ContentKey = (String frontFolded, String backFolded);

/// The status of one data row of the preview.
sealed class ImportRowOutcome {
  const ImportRowOutcome(this.rowNumber);

  /// The row's number in the source.
  final int rowNumber;
}

final class ImportRowReady extends ImportRowOutcome {
  const ImportRowReady(super.rowNumber, this.draft);

  final CardDraft draft;
}

/// A valid row whose key the target deck holds ([firstRowNumber] null), or
/// an earlier row of the source claimed.
final class ImportRowDuplicate extends ImportRowOutcome {
  const ImportRowDuplicate(super.rowNumber, this.draft, {this.firstRowNumber});

  final CardDraft draft;
  final int? firstRowNumber;
}

/// A row the card's own rules refuse (BR-TRANSFER-002): the first failing
/// [field] and its [reason], with the row's front and back, trimmed.
final class ImportRowInvalid extends ImportRowOutcome {
  const ImportRowInvalid(
    super.rowNumber, {
    required this.front,
    required this.back,
    required this.field,
    required this.reason,
  });

  final String front;
  final String back;
  final CardField field;
  final CardRejection reason;
}

/// A row with nothing in any cell: skipped, and not an error
/// (BR-TRANSFER-002).
final class ImportRowBlank extends ImportRowOutcome {
  const ImportRowBlank(super.rowNumber);
}

/// The preview of an import (UC-TRANSFER-001 step 5): the data rows of a
/// sheet, each with its status. The commit classifies the rows again, with
/// the same rules, on the deck as it is then (BR-TRANSFER-003).
final class ImportPreview {
  const ImportPreview._({
    required this.mapping,
    required this.shouldIncludeDuplicates,
    required this.rows,
    required this.dataRowCount,
  });

  /// Classifies the data rows of [sheet] against [deckKeys], the keys of the
  /// target deck's active cards, in order (transfer spec §6.2): blank, then
  /// invalid, then a duplicate in the deck, then a duplicate of an earlier
  /// row, else ready. A valid row claims its key when no earlier row has;
  /// an invalid row claims nothing. No row is classified while front or
  /// back has no column.
  factory ImportPreview.classify({
    required ImportSheet sheet,
    required ImportSettings settings,
    required Set<ContentKey> deckKeys,
  }) {
    final dataRows = settings.hasHeaderRow
        ? sheet.rows.skip(1).toList()
        : sheet.rows;
    final mapping = settings.mapping ?? _defaultMapping(sheet, settings);
    final claimed = <ContentKey, int>{};
    return ImportPreview._(
      mapping: mapping,
      shouldIncludeDuplicates: settings.shouldIncludeDuplicates,
      rows: mapping.missing.isNotEmpty
          ? const []
          : [
              for (final row in dataRows)
                _classify(row, mapping, deckKeys, claimed),
            ],
      dataRowCount: dataRows.where((row) => !row.isBlank).length,
    );
  }

  /// The mapping the rows were read through, the default or the one given.
  final ColumnMapping mapping;

  final bool shouldIncludeDuplicates;

  /// Every data row, in source order; none while the mapping is missing
  /// front or back.
  final List<ImportRowOutcome> rows;

  /// The data rows that are not blank, whatever the mapping: none is
  /// UC-TRANSFER-001 E2.
  final int dataRowCount;

  int get readyCount => rows.whereType<ImportRowReady>().length;

  int get duplicateCount => rows.whereType<ImportRowDuplicate>().length;

  int get invalidCount => rows.whereType<ImportRowInvalid>().length;

  int get blankCount => rows.whereType<ImportRowBlank>().length;

  /// How many cards the import would write: none is UC-TRANSFER-001 E3.
  int get writeCount => toWrite.length;

  /// The drafts the import writes, in row order: the ready rows, and the
  /// duplicates when the person includes them (BR-TRANSFER-003).
  List<CardDraft> get toWrite => [
    for (final row in rows)
      if (row case ImportRowReady(:final draft))
        draft
      else if (row case ImportRowDuplicate(:final draft)
          when shouldIncludeDuplicates)
        draft,
  ];
}

ColumnMapping _defaultMapping(ImportSheet sheet, ImportSettings settings) {
  if (!settings.hasHeaderRow) {
    return ColumnMapping.byPosition(sheet.columnCount);
  }
  if (sheet.rows.isEmpty) return const ColumnMapping();
  return ColumnMapping.byHeader(sheet.rows.first.cells);
}

ImportRowOutcome _classify(
  ImportRow row,
  ColumnMapping mapping,
  Set<ContentKey> deckKeys,
  Map<ContentKey, int> claimed,
) {
  if (row.isBlank) return ImportRowBlank(row.number);
  String? cellOf(CardField field) => switch (mapping.columnOf(field)) {
    final int column => row.cellAt(column),
    null => null,
  };
  final front = cellOf(CardField.front) ?? '';
  final back = cellOf(CardField.back) ?? '';
  final draft = CardDraft(
    front: front,
    back: back,
    example: cellOf(CardField.example),
    hint: cellOf(CardField.hint),
    pronunciation: cellOf(CardField.pronunciation),
    tagNames: switch (cellOf(CardField.tags)) {
      final String cell => TagCell.decode(cell),
      null => const [],
    },
  );
  if (draft.firstFailure() case (:final field, :final reason)) {
    return ImportRowInvalid(
      row.number,
      front: front.trim(),
      back: back.trim(),
      field: field,
      reason: reason,
    );
  }
  final ContentKey key = (foldText(front), foldText(back));
  final first = claimed.putIfAbsent(key, () => row.number);
  if (deckKeys.contains(key)) return ImportRowDuplicate(row.number, draft);
  if (first != row.number) {
    return ImportRowDuplicate(row.number, draft, firstRowNumber: first);
  }
  return ImportRowReady(row.number, draft);
}
```

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 52 warning(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/transfer/domain/column_mapping_test.dart \
  test/features/transfer/domain/import_classification_test.dart \
  test/features/transfer/domain/tag_cell_test.dart
```

Expected: `+24: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/transfer/domain/models/column_mapping_model.dart \
  lib/features/transfer/domain/models/import_preview_model.dart \
  lib/features/transfer/domain/models/import_sheet_model.dart \
  lib/features/transfer/domain/models/tag_cell_model.dart \
  test/architecture/boundary_rules.dart \
  test/features/transfer/domain/column_mapping_test.dart \
  test/features/transfer/domain/import_classification_test.dart \
  test/features/transfer/domain/tag_cell_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 10: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 52 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1634: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
feat(transfer): map a sheet's columns and classify its rows

The transfer feature starts with its domain. A source reads as sheets of
numbered rows; ColumnMapping gives each card field at most one column,
by the six canonical headers or, with no header, columns A and B
(UC-TRANSFER-001 step 4, A3; transfer spec D7). ImportPreview.classify
judges every data row with the card's own rules and the folded key, in
one order the preview and the commit share: blank, invalid with its
field, a duplicate in the deck, a duplicate of an earlier row, ready
(BR-TRANSFER-002, BR-TRANSFER-003; D8). TagCell is the one codec of the
tags cell (BR-TRANSFER-009). The import map gains transfer -> card.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: Preview an import, then write it all or nothing

**Files:**
- Create: `lib/features/transfer/data/datasources/transfer_dao.dart`, `lib/features/transfer/data/repositories/transfer_repository_impl.dart`, `lib/features/transfer/di/transfer_repository_provider.dart`, `lib/features/transfer/domain/failures/transfer_failure.dart`, `lib/features/transfer/domain/models/import_result_model.dart`, `lib/features/transfer/domain/repositories/transfer_repository.dart`, `lib/features/transfer/domain/usecases/import_cards_use_case.dart`, `lib/features/transfer/domain/usecases/preview_import_use_case.dart`
- Test (create): `test/features/transfer/data/import_cards_test.dart`, `test/features/transfer/domain/transfer_use_cases_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's `createCards`; Task 2's `ImportSheet`, `ImportSettings`,
  `ContentKey` and `ImportPreview.classify`; `mapDatabaseError`
  (`lib/core/error/failure.dart`); `databaseProvider`, `cardRepositoryProvider`.
- Produces:
  - `enum TransferRejection { mappingIncomplete, deckNotFound, deckRejectsCards }`
    (Tasks 4 and 5 add the others) and
    `ImportResult({required int added, required int skippedDuplicates, required int skippedInvalid, required int ignoredBlank})`.
  - `TransferRepository` with
    `Future<ImportPreview> previewImport({required String deckId, required ImportSheet sheet, required ImportSettings settings})`
    and
    `Future<Outcome<ImportResult, TransferRejection>> importCards({required String deckId, required ImportSheet sheet, required ImportSettings settings, DateTime? now})`.
  - `TransferDao(AppDatabase)` with `Future<Set<ContentKey>> contentKeys(String deckId)`;
    `TransferRepositoryImpl(AppDatabase db, CardRepository cards, {DateTime Function()? now})`;
    `transferRepositoryProvider`.
  - `PreviewImportUseCase(TransferRepository)` with
    `call({required String deckId, required ImportSheet sheet, ImportSettings settings = const ImportSettings()})`,
    and `ImportCardsUseCase(TransferRepository)` with
    `call({required String deckId, required ImportSheet sheet, required ImportSettings settings})`.

Spec §7, D8, D11; Clarifications 4, 6 and 11; Review Focus 1. The commit runs
in one transaction that the batch create joins; the tests force a failure with a
`QueryInterceptor` and read the order through learning and the card list.

- [ ] **Step 1: Write the failing tests**

Create `test/features/transfer/data/import_cards_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/models/deck_content_type_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRANSFER-001 steps 5-7, E3-E5: the preview reads the deck; the commit
// classifies again and writes in one transaction (BR-TRANSFER-001,
// BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005; transfer spec §7).
// The store side of IT-CARD-014 steps 1-4 and IT-CARD-015 steps 1-4.

DateTime _now() => DateTime(2026, 9, 26, 10);

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

(int, int, int, int) _counts(ImportResult result) => (
  result.added,
  result.skippedDuplicates,
  result.skippedInvalid,
  result.ignoredBlank,
);

Matcher _imported((int, int, int, int) counts) =>
    isA<Ok<ImportResult, TransferRejection>>().having(
      (ok) => _counts(ok.value),
      'added, duplicates, invalid, blank',
      counts,
    );

Matcher _refused(TransferRejection reason) =>
    isA<Rejected<ImportResult, TransferRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

/// Fails the first tag link, after every card and schedule row of the
/// import is written (UC-TRANSFER-001 E5).
final class _FailingTagLinks extends QueryInterceptor {
  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (statement.contains('card_tags')) throw StateError('disk full');
    return super.runInsert(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TransferRepositoryImpl transfer;
  late DeckEntity root;
  late DeckEntity leaf;

  Future<void> open(AppDatabase database) async {
    db = database;
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    transfer = TransferRepositoryImpl(db, cards, now: _now);
    root = await decks.root('r');
    leaf = await decks.sub(root.id, 'l');
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() => db.close());

  Future<List<String>> frontsInCreationOrder() async => [
    for (final row
        in await db
            .customSelect('SELECT front FROM card ORDER BY created_at, id')
            .get())
      row.read<String>('front'),
  ];

  Future<DeckContentType> contentTypeOf(String deckId) async =>
      (await decks.findById(deckId))!.contentType;

  test('an import writes its ready rows, each with one schedule row and its '
      'tags, and the unset deck becomes a deck of cards '
      '(BR-TRANSFER-004, BR-TRANSFER-005)', () async {
    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back', 'tags'],
        ['tip', 'tiền boa', 'noun'],
        ['bill', 'hóa đơn', ''],
        ['', '', ''],
        ['menu', '', 'noun'],
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((2, 0, 1, 1)));
    expect(await frontsInCreationOrder(), ['tip', 'bill']);
    final schedules = await db
        .customSelect('SELECT scheduler_type, learned_at FROM card_schedule')
        .get();
    expect(
      [for (final row in schedules) row.read<String>('scheduler_type')],
      ['eight_box', 'eight_box'],
    );
    expect(schedules.every((row) => row.data['learned_at'] == null), isTrue);
    final links = await db
        .customSelect(
          'SELECT c.front, t.name FROM card_tags ct '
          'JOIN card c ON c.id = ct.card_id JOIN tags t ON t.id = ct.tag_id',
        )
        .get();
    expect(
      [
        for (final row in links)
          '${row.read<String>('front')}:${row.read<String>('name')}',
      ],
      ['tip:noun'],
    );
    expect(await contentTypeOf(leaf.id), DeckContentType.card);
  });

  test('a tags cell typed by hand: spaces around the names, the library\'s '
      'tag in another case, a comma inside a name (BR-TRANSFER-009, '
      'BR-TAG-001)', () async {
    final other = await decks.sub(root.id, 'o');
    await cards.createCard(
      deckId: other.id,
      draft: const CardDraft(front: 'x', back: 'y', tagNames: ['noun']),
      now: DateTime(2026, 9, 25),
    );

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back', 'tags'],
        ['tip', 'tiền boa', ' Noun ; verb, adj '],
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((1, 0, 0, 0)));
    final tags = await db
        .customSelect('SELECT name FROM tags ORDER BY name_folded')
        .get();
    expect(
      [for (final row in tags) row.read<String>('name')],
      ['noun', 'verb, adj'],
    );
    final links = await db
        .customSelect(
          'SELECT t.name FROM card_tags ct JOIN card c ON c.id = ct.card_id '
          "JOIN tags t ON t.id = ct.tag_id WHERE c.front = 'tip' "
          'ORDER BY t.name_folded',
        )
        .get();
    expect(
      [for (final row in links) row.read<String>('name')],
      ['noun', 'verb, adj'],
    );
  });

  test('the preview reads the deck as it is and writes nothing: a card in the '
      'Trash, or in another deck, is no duplicate (BR-TRANSFER-003)', () async {
    final other = await decks.sub(root.id, 'o');
    await cards.createCards(
      deckId: leaf.id,
      drafts: const [
        CardDraft(front: 'tip', back: 'tiền boa'),
        CardDraft(front: 'bill', back: 'hóa đơn'),
      ],
    );
    await cards.createCard(
      deckId: other.id,
      draft: const CardDraft(front: 'menu', back: 'thực đơn'),
    );
    final bill = await db
        .customSelect("SELECT id FROM card WHERE front = 'bill'")
        .getSingle();
    await trashCardRow(db, bill.read<String>('id'));
    final before = await totalChanges(db);

    final preview = await transfer.previewImport(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['TIP', 'Tiền boa'],
        ['bill', 'hóa đơn'],
        ['menu', 'thực đơn'],
      ]),
      settings: const ImportSettings(),
    );

    expect(
      [for (final row in preview.rows) row.runtimeType],
      [ImportRowDuplicate, ImportRowReady, ImportRowReady],
    );
    expect(await totalChanges(db), before);
  });

  test('the commit classifies again: a card written after the preview is '
      'skipped as a duplicate (BR-TRANSFER-003)', () async {
    final sheet = _sheet([
      ['front', 'back'],
      ['tip', 'tiền boa'],
      ['bill', 'hóa đơn'],
    ]);
    final preview = await transfer.previewImport(
      deckId: leaf.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );
    expect(preview.writeCount, 2);
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'Tip', back: 'Tiền boa'),
      now: DateTime(2026, 9, 25),
    );

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );

    expect(result, _imported((1, 1, 0, 0)));
    expect(await frontsInCreationOrder(), ['Tip', 'bill']);
  });

  test('duplicates included are written as new cards, the deck\'s copy and '
      'repeated rows alike (UC-TRANSFER-001 A4)', () async {
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'tip', back: 'tiền boa'),
      now: DateTime(2026, 9, 25),
    );

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['tip', 'tiền boa'],
        ['bill', 'hóa đơn'],
        ['bill', 'hóa đơn'],
      ]),
      settings: const ImportSettings(shouldIncludeDuplicates: true),
    );

    expect(result, _imported((3, 0, 0, 0)));
    expect(await frontsInCreationOrder(), ['tip', 'tip', 'bill', 'bill']);
  });

  test(
    'a deck that is gone, in the Trash, a root or holding sub-decks '
    'refuses the import, which writes nothing (E4, BR-TRANSFER-001)',
    () async {
      final mid = await decks.sub(root.id, 'mid');
      await decks.sub(mid.id, 'inner');
      final trashed = await decks.sub(root.id, 't');
      await trashDeckRows(db, trashed.id);
      final sheet = _sheet([
        ['front', 'back'],
        ['tip', 'tiền boa'],
      ]);
      final before = await totalChanges(db);

      for (final (deckId, reason) in [
        ('missing', TransferRejection.deckNotFound),
        (trashed.id, TransferRejection.deckNotFound),
        (root.id, TransferRejection.deckRejectsCards),
        (mid.id, TransferRejection.deckRejectsCards),
      ]) {
        expect(
          await transfer.importCards(
            deckId: deckId,
            sheet: sheet,
            settings: const ImportSettings(),
          ),
          _refused(reason),
          reason: deckId,
        );
      }
      expect(await totalChanges(db), before);
    },
  );

  test('with nothing to write nothing is written, and an unset deck stays '
      'unset (E3, BR-TRANSFER-004, BR-TRANSFER-005)', () async {
    final before = await totalChanges(db);

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['tip', ''],
        [' ', ' '],
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((0, 0, 1, 1)));
    expect(await totalChanges(db), before);
    expect(await contentTypeOf(leaf.id), DeckContentType.unset);
  });

  test('without front or back mapped the import is refused and writes '
      'nothing (BR-TRANSFER-002)', () async {
    final before = await totalChanges(db);

    expect(
      await transfer.importCards(
        deckId: leaf.id,
        sheet: _sheet([
          ['term', 'meaning'],
          ['tip', 'tiền boa'],
        ]),
        settings: const ImportSettings(),
      ),
      _refused(TransferRejection.mappingIncomplete),
    );
    expect(await totalChanges(db), before);
  });

  test('a failure in the middle rolls the whole import back: no card, no '
      'schedule, no tag, and the deck stays unset (E5)', () async {
    await db.close();
    await open(openTestDatabase(interceptor: _FailingTagLinks()));

    await expectLater(
      transfer.importCards(
        deckId: leaf.id,
        sheet: _sheet([
          ['front', 'back', 'tags'],
          ['tip', 'tiền boa', ''],
          ['bill', 'hóa đơn', 'noun'],
        ]),
        settings: const ImportSettings(),
      ),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    for (final table in ['card', 'card_schedule', 'tags', 'card_tags']) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      expect(rows, isEmpty, reason: table);
    }
    expect(await contentTypeOf(leaf.id), DeckContentType.unset);
  });

  test('1,500 rows keep the file\'s order: learning takes them in it, and '
      'the card list shows the newest, the last row, first (D11)', () async {
    final rows = [
      for (var i = 1; i <= 1500; i++)
        ['w${i.toString().padLeft(4, '0')}', 'meaning $i'],
    ];

    final result = await transfer.importCards(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ...rows,
      ]),
      settings: const ImportSettings(),
    );

    expect(result, _imported((1500, 0, 0, 0)));
    final fronts = [for (final row in rows) row.first];
    expect(await frontsInCreationOrder(), fronts);
    final byId = {
      for (final row
          in await db.customSelect('SELECT id, front FROM card').get())
        row.read<String>('id'): row.read<String>('front'),
    };
    final learning = await StudySessionDao(db).newCards(leaf.id);
    expect([for (final card in learning) byId[card.cardId]], fronts);
    final list = await cards
        .watchCardList(
          deckId: leaf.id,
          query: const CardListQuery(),
          windowSize: 5,
          now: _now(),
        )
        .first;
    expect(
      [for (final item in list.items) item.front],
      ['w1500', 'w1499', 'w1498', 'w1497', 'w1496'],
    );
  });
}
```

Create `test/features/transfer/domain/transfer_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/usecases/import_cards_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TRANSFER-001 and UC-TRANSFER-002: each use case passes its arguments
// to the repository.

DateTime _now() => DateTime(2026, 9, 26, 10);

ImportSheet _sheet(List<List<String>> rows) => ImportSheet(
  rows: [
    for (final (index, cells) in rows.indexed)
      ImportRow(number: index + 1, cells: cells),
  ],
);

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late TransferRepositoryImpl transfer;
  late DeckEntity leaf;

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    transfer = TransferRepositoryImpl(db, cards, now: _now);
    leaf = await decks.sub((await decks.root('r')).id, 'l');
  });
  tearDown(() => db.close());

  test('PreviewImportUseCase previews the sheet against the deck', () async {
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'tip', back: 'tiền boa'),
    );

    final preview = await PreviewImportUseCase(transfer)(
      deckId: leaf.id,
      sheet: _sheet([
        ['front', 'back'],
        ['tip', 'tiền boa'],
        ['bill', 'hóa đơn'],
      ]),
    );

    expect((preview.duplicateCount, preview.readyCount), (1, 1));
  });

  test(
    'ImportCardsUseCase imports the sheet with the settings given',
    () async {
      final result = await ImportCardsUseCase(transfer)(
        deckId: leaf.id,
        sheet: _sheet([
          ['tip', 'tiền boa'],
        ]),
        settings: const ImportSettings(hasHeaderRow: false),
      );

      expect(
        result,
        isA<Ok<ImportResult, TransferRejection>>().having(
          (ok) => ok.value.added,
          'added',
          1,
        ),
      );
    },
  );
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/data/import_cards_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/transfer/domain/failures/transfer_failure.dart': No such file or directory`,
and the same for `import_result_model.dart`, `transfer_repository_impl.dart`,
`preview_import_use_case.dart` and `import_cards_use_case.dart`.

- [ ] **Step 3: Name the refusals and the result of an import**

Create `lib/features/transfer/domain/failures/transfer_failure.dart`:

```dart
/// Why the transfer feature refuses a request (ADR-011 D6).
enum TransferRejection {
  /// BR-TRANSFER-002: no column feeds the front or the back.
  mappingIncomplete,

  /// UC-TRANSFER-001 E4: the target deck is gone or in the Trash.
  deckNotFound,

  /// UC-TRANSFER-001 E4, BR-TRANSFER-001: the target deck is a root or
  /// holds sub-decks.
  deckRejectsCards,
}
```

Create `lib/features/transfer/domain/models/import_result_model.dart`:

```dart
/// What an import did (UC-TRANSFER-001 step 8): the cards it added, and the
/// rows it left out.
final class ImportResult {
  const ImportResult({
    required this.added,
    required this.skippedDuplicates,
    required this.skippedInvalid,
    required this.ignoredBlank,
  });

  final int added;

  /// The duplicates it did not write; none when the person included them.
  final int skippedDuplicates;

  final int skippedInvalid;
  final int ignoredBlank;
}
```

- [ ] **Step 4: Declare the contract**

Create `lib/features/transfer/domain/repositories/transfer_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

/// The one implementation is `TransferRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and
/// tests substitute a fake.
abstract interface class TransferRepository {
  /// UC-TRANSFER-001 step 5: the data rows of [sheet], classified against
  /// the active cards of [deckId] as they are now (transfer spec §6.2).
  /// Writes nothing.
  Future<ImportPreview> previewImport({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
  });

  /// UC-TRANSFER-001 steps 6-7, in one transaction: classifies [sheet] again
  /// on the deck as it is (BR-TRANSFER-003) and writes the rows to write as
  /// new cards (BR-TRANSFER-004, BR-TRANSFER-005). Refuses, writing nothing,
  /// while front or back has no column (mappingIncomplete), and when the
  /// deck is gone (deckNotFound) or takes no card (deckRejectsCards) (E4).
  /// A failure rolls everything back and leaves as a database `Failure`
  /// (E5).
  Future<Outcome<ImportResult, TransferRejection>> importCards({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
    DateTime? now,
  });
}
```

- [ ] **Step 5: Read the deck's keys, then preview and commit**

The provider's `part` file does not exist until the next step generates it.

Create `lib/features/transfer/data/datasources/transfer_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';

/// Row access for transfer: the keys of a deck's cards (transfer spec
/// §6.2). It runs inside the caller's transaction.
final class TransferDao {
  TransferDao(this._db);

  final AppDatabase _db;

  /// The folded front and back of every active card of [deckId]
  /// (BR-TRANSFER-003).
  Future<Set<ContentKey>> contentKeys(String deckId) async {
    final card = _db.card;
    final rows =
        await (_db.selectOnly(card)
              ..addColumns([card.frontFolded, card.backFolded])
              ..where(card.deckId.equals(deckId) & card.deleteBatchId.isNull()))
            .get();
    return {
      for (final row in rows)
        (row.read(card.frontFolded)!, row.read(card.backFolded)!),
    };
  }
}
```

Create `lib/features/transfer/data/repositories/transfer_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/transfer/data/datasources/transfer_dao.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// Import and export (transfer spec §7, §8). The commit of an import is one
/// transaction, which the card feature's batch create joins.
final class TransferRepositoryImpl implements TransferRepository {
  TransferRepositoryImpl(this._db, this._cards, {DateTime Function()? now})
    : _dao = TransferDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final CardRepository _cards;
  final TransferDao _dao;
  final DateTime Function() _now;

  @override
  Future<ImportPreview> previewImport({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
  }) => _mapped(
    () async => ImportPreview.classify(
      sheet: sheet,
      settings: settings,
      deckKeys: await _dao.contentKeys(deckId),
    ),
  );

  @override
  Future<Outcome<ImportResult, TransferRejection>> importCards({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
    DateTime? now,
  }) => _mapped(
    () => _db.transaction(() async {
      final preview = ImportPreview.classify(
        sheet: sheet,
        settings: settings,
        deckKeys: await _dao.contentKeys(deckId),
      );
      if (preview.mapping.missing.isNotEmpty) {
        return const Rejected(TransferRejection.mappingIncomplete);
      }
      final written = await _cards.createCards(
        deckId: deckId,
        drafts: preview.toWrite,
        now: now ?? _now(),
      );
      return switch (written) {
        Ok(value: final ids) => Ok(
          ImportResult(
            added: ids.length,
            skippedDuplicates: settings.shouldIncludeDuplicates
                ? 0
                : preview.duplicateCount,
            skippedInvalid: preview.invalidCount,
            ignoredBlank: preview.blankCount,
          ),
        ),
        Rejected(reason: CardRejection.notFound) => const Rejected(
          TransferRejection.deckNotFound,
        ),
        Rejected(reason: CardRejection.notACardContainer) => const Rejected(
          TransferRejection.deckRejectsCards,
        ),
        // The classification checked every draft with the card's rules, so
        // any other refusal is a bug: throwing rolls the import back.
        Rejected(:final reason) => throw StateError(
          'the card rules refused a checked draft: $reason',
        ),
      };
    }),
  );

  /// [body], with an unexpected database error leaving as its [Failure].
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

Create `lib/features/transfer/di/transfer_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transfer_repository_provider.g.dart';

@riverpod
TransferRepository transferRepository(Ref ref) => TransferRepositoryImpl(
  ref.watch(databaseProvider),
  ref.watch(cardRepositoryProvider),
);
```

- [ ] **Step 6: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: its last line reads `Built with build_runner/aot in …; wrote … outputs.`,
and `lib/features/transfer/di/transfer_repository_provider.g.dart` now exists. Like
every `*.g.dart` file, it is not committed.

- [ ] **Step 7: Write the two use cases**

Create `lib/features/transfer/domain/usecases/preview_import_use_case.dart`:

```dart
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-001 steps 4-5: every data row of a sheet with its status,
/// against the deck as it is now; nothing is written.
final class PreviewImportUseCase {
  const PreviewImportUseCase(this._transfer);

  final TransferRepository _transfer;

  Future<ImportPreview> call({
    required String deckId,
    required ImportSheet sheet,
    ImportSettings settings = const ImportSettings(),
  }) =>
      _transfer.previewImport(deckId: deckId, sheet: sheet, settings: settings);
}
```

Create `lib/features/transfer/domain/usecases/import_cards_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-001 steps 6-8: the import, all or nothing (BR-TRANSFER-004).
final class ImportCardsUseCase {
  const ImportCardsUseCase(this._transfer);

  final TransferRepository _transfer;

  Future<Outcome<ImportResult, TransferRejection>> call({
    required String deckId,
    required ImportSheet sheet,
    required ImportSettings settings,
  }) => _transfer.importCards(deckId: deckId, sheet: sheet, settings: settings);
}
```

- [ ] **Step 8: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 51 warning(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/features/transfer/data/import_cards_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart
```

Expected: `+12: All tests passed!`

- [ ] **Step 10: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/transfer/data/datasources/transfer_dao.dart \
  lib/features/transfer/data/repositories/transfer_repository_impl.dart \
  lib/features/transfer/di/transfer_repository_provider.dart \
  lib/features/transfer/domain/failures/transfer_failure.dart \
  lib/features/transfer/domain/models/import_result_model.dart \
  lib/features/transfer/domain/repositories/transfer_repository.dart \
  lib/features/transfer/domain/usecases/import_cards_use_case.dart \
  lib/features/transfer/domain/usecases/preview_import_use_case.dart \
  test/features/transfer/data/import_cards_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 11: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 51 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1646: All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git commit -F - <<'EOF'
feat(transfer): preview an import, then write it all or nothing

previewImport classifies a sheet's rows against the active cards of the
target deck as they are now, and writes nothing (UC-TRANSFER-001 step
5). importCards classifies them again inside one transaction, on the
deck as it is then, and hands the rows to write to the card feature's
batch create: a card written after the preview is skipped as a
duplicate, a deck that is gone or takes no card refuses the import, an
empty mapping is refused, and a failure rolls everything back
(BR-TRANSFER-001, BR-TRANSFER-003, BR-TRANSFER-004; E3-E5). The result
counts the cards added and the rows left out. PreviewImportUseCase,
ImportCardsUseCase and the repository's provider.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: Read a CSV or TSV file, or pasted text

**Files:**
- Create: `lib/features/transfer/data/mappers/delimited_text_mapper.dart`, `lib/features/transfer/domain/models/import_source_model.dart`, `lib/features/transfer/domain/models/transfer_format_model.dart`, `lib/features/transfer/domain/usecases/read_import_source_use_case.dart`
- Modify: `lib/features/transfer/data/repositories/transfer_repository_impl.dart`, `lib/features/transfer/domain/failures/transfer_failure.dart`, `lib/features/transfer/domain/repositories/transfer_repository.dart`
- Test (create): `test/features/transfer/data/delimited_text_test.dart`
- Test (modify): `test/features/transfer/domain/transfer_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `ImportRow`, `ImportSheet` and `ImportDocument`; Task 3's
  `TransferRejection`, `TransferRepository` and `TransferRepositoryImpl`.
- Produces:
  - `TransferRejection.unsupportedFormat`, `notUtf8` and `unreadable`, first in the enum.
  - `enum TransferFormat { csv, tsv }` with `fileExtension`, `mimeType` and
    `static TransferFormat? ofFileName(String fileName)`.
  - `sealed class ImportSource` with `ImportFile({required String name, required Uint8List bytes})`
    and `PastedText(String text)`.
  - `Outcome<ImportDocument, TransferRejection> readDelimited(ImportSource source)`
    (`transfer/data/mappers/delimited_text_mapper.dart`), pure.
  - `Future<Outcome<ImportDocument, TransferRejection>> TransferRepository.readSource(ImportSource source)`.
  - `ReadImportSourceUseCase(TransferRepository)` with `call(ImportSource source)`.

Spec §5, D4–D6; Clarifications 9–11; Review Focus 2 and 3. The mapper is pure,
so `readSource` can run it on another isolate.

- [ ] **Step 1: Write the failing tests**

Create `test/features/transfer/data/delimited_text_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/data/mappers/delimited_text_mapper.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';

// UC-TRANSFER-001 steps 2-3, A1, E1: a CSV or TSV file, or pasted text,
// read as one sheet (BR-TRANSFER-006; transfer spec §5, D4-D6).

ImportFile _file(String name, List<int> bytes) =>
    ImportFile(name: name, bytes: Uint8List.fromList(bytes));

ImportFile _csv(String text, {String name = 'cards.csv'}) =>
    _file(name, utf8.encode(text));

ImportSheet _sheet(Outcome<ImportDocument, TransferRejection> result) =>
    (result as Ok<ImportDocument, TransferRejection>).value.sheets.single;

List<List<String>> _rows(Outcome<ImportDocument, TransferRejection> result) => [
  for (final row in _sheet(result).rows) row.cells,
];

Matcher _refused(TransferRejection reason) =>
    isA<Rejected<ImportDocument, TransferRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  test('a .csv or .tsv file, in any case, is read; any other extension, or '
      'none, is unsupportedFormat (E1)', () {
    expect(_rows(readDelimited(_csv('a,b', name: 'A.CSV'))), [
      ['a', 'b'],
    ]);
    expect(_rows(readDelimited(_csv('a\tb', name: 'b.Tsv'))), [
      ['a', 'b'],
    ]);
    for (final name in ['c.xlsx', 'd.txt', 'e', 'f.csv.txt', '.csv.bak']) {
      expect(
        readDelimited(_csv('a,b', name: name)),
        _refused(TransferRejection.unsupportedFormat),
        reason: name,
      );
    }
  });

  test('a UTF-8 BOM is dropped; a UTF-16 BOM, bytes that are not UTF-8, or '
      'a U+0000 is notUtf8 (D4, BR-TRANSFER-006)', () {
    expect(
      _rows(
        readDelimited(_file('a.csv', [0xEF, 0xBB, 0xBF, 0x61, 0x2C, 0x62])),
      ),
      [
        ['a', 'b'],
      ],
    );
    for (final (label, bytes) in [
      ('UTF-16 LE', [0xFF, 0xFE, 0x61, 0x00]),
      ('UTF-16 BE', [0xFE, 0xFF, 0x00, 0x61]),
      ('Latin-1 café', [0x63, 0x61, 0x66, 0xE9]),
      ('UTF-16 LE without a BOM', [0x61, 0x00, 0x2C, 0x00, 0x62, 0x00]),
    ]) {
      expect(
        readDelimited(_file('a.csv', bytes)),
        _refused(TransferRejection.notUtf8),
        reason: label,
      );
    }
  });

  test('a .tsv file is split on tabs, whatever else it holds', () {
    expect(_rows(readDelimited(_csv('a,b\tc;d', name: 'x.tsv'))), [
      ['a,b', 'c;d'],
    ]);
  });

  test('a .csv file is split on ";" when its first record holds ";" and no '
      '"," outside quotes, and on "," otherwise (D5)', () {
    expect(_rows(readDelimited(_csv('front;back\ntip;tiền boa'))), [
      ['front', 'back'],
      ['tip', 'tiền boa'],
    ]);
    expect(_rows(readDelimited(_csv('"a,b";c\n"d;e";f'))), [
      ['a,b', 'c'],
      ['d;e', 'f'],
    ]);
    expect(_rows(readDelimited(_csv('\n  \nfront;back'))), [
      [''],
      ['  '],
      ['front', 'back'],
    ]);
    expect(_rows(readDelimited(_csv('front,back\ntip;x,y'))), [
      ['front', 'back'],
      ['tip;x', 'y'],
    ]);
    expect(_rows(readDelimited(_csv('a;b,c'))), [
      ['a;b', 'c'],
    ]);
  });

  test('Excel\'s "CSV UTF-8" from a locale with a decimal comma: a BOM, ";" '
      'between fields, CRLF, a comma in an unquoted cell, and the tags '
      'quoted because they hold ";" (D5)', () {
    final bytes = [
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode('front;back;tags\r\ngiá;1,5 đô;"noun;price"\r\n'),
    ];

    expect(_rows(readDelimited(_file('Từ vựng.csv', bytes))), [
      ['front', 'back', 'tags'],
      ['giá', '1,5 đô', 'noun;price'],
    ]);
  });

  test('pasted text is split on tabs when its first record holds one, and '
      'as a .csv file otherwise (UC-TRANSFER-001 A1)', () {
    expect(
      _rows(readDelimited(const PastedText('term\tmeaning\ntip\ttiền boa'))),
      [
        ['term', 'meaning'],
        ['tip', 'tiền boa'],
      ],
    );
    expect(_rows(readDelimited(const PastedText('a;b'))), [
      ['a', 'b'],
    ]);
    expect(_rows(readDelimited(const PastedText('\uFEFFa,b'))), [
      ['a', 'b'],
    ]);
  });

  test('text copied from a spreadsheet: tabs, CRLF, a cell of two lines in '
      'quotes, and a line break at the end (UC-TRANSFER-001 A1)', () {
    const copied =
        'front\tback\r\n'
        '"line 1\nline 2"\tx\r\n'
        'tip\ttiền boa\r\n';

    expect(_rows(readDelimited(const PastedText(copied))), [
      ['front', 'back'],
      ['line 1\nline 2', 'x'],
      ['tip', 'tiền boa'],
    ]);
  });

  test('a quoted field holds delimiters, line breaks and doubled quotes; '
      'text after its closing quote is kept, and a quote inside an unquoted '
      'field is text (§5.3)', () {
    final result = readDelimited(
      _csv(
        'front,back\n'
        '"a, b","line 1\nline 2"\n'
        '"say ""hi""",x\n'
        '5" screen,"a"b\n',
      ),
    );

    expect(_rows(result), [
      ['front', 'back'],
      ['a, b', 'line 1\nline 2'],
      ['say "hi"', 'x'],
      ['5" screen', 'ab'],
    ]);
    expect([for (final row in _sheet(result).rows) row.number], [1, 2, 3, 4]);
  });

  test('records end at CRLF, LF or CR; a line break at the end adds no '
      'record, and each further one adds a blank row', () {
    expect(_rows(readDelimited(_csv('a,b\r\nc,d\re,f\n'))), [
      ['a', 'b'],
      ['c', 'd'],
      ['e', 'f'],
    ]);
    expect(_rows(readDelimited(_csv('a\n\n'))), [
      ['a'],
      [''],
    ]);
    expect(_rows(readDelimited(_csv(''))), isEmpty);
  });

  test('every field is kept, empty ones included, and the sheet is as wide '
      'as its widest record', () {
    final result = readDelimited(_csv('a,,c\n,\n'));

    expect(_rows(result), [
      ['a', '', 'c'],
      ['', ''],
    ]);
    expect(_sheet(result).columnCount, 3);
  });

  test('a quoted field still open at the end of the source is unreadable '
      '(E1)', () {
    expect(
      readDelimited(_csv('a,"b\nc')),
      _refused(TransferRejection.unreadable),
    );
  });
}
```

In `test/features/transfer/domain/transfer_use_cases_test.dart`:

Replace

```dart
import 'package:flutter_test/flutter_test.dart';
```

with

```dart
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
```

Replace

```dart
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/usecases/import_cards_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';

```

with

```dart
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/import_cards_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/preview_import_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/read_import_source_use_case.dart';

```

Replace

```dart
          (ok) => ok.value.added,
          'added',
          1,
        ),
      );
    },
  );
}
```

with

```dart
          (ok) => ok.value.added,
          'added',
          1,
        ),
      );
    },
  );

  test('ReadImportSourceUseCase reads a source through the repository, '
      'and passes its refusal through', () async {
    final read = ReadImportSourceUseCase(transfer);

    final document = await read(const PastedText('front\tback\ntip\ttiền boa'));

    expect(
      [
        for (final row
            in (document as Ok<ImportDocument, TransferRejection>)
                .value
                .sheets
                .single
                .rows)
          row.cells,
      ],
      [
        ['front', 'back'],
        ['tip', 'tiền boa'],
      ],
    );
    expect(
      await read(ImportFile(name: 'cards.pdf', bytes: Uint8List(0))),
      isA<Rejected<ImportDocument, TransferRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        TransferRejection.unsupportedFormat,
      ),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/data/delimited_text_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/transfer/data/mappers/delimited_text_mapper.dart': No such file or directory`,
the same for `import_source_model.dart` and `read_import_source_use_case.dart`, and
`Error: Member not found: 'unsupportedFormat'.`

- [ ] **Step 3: Name the formats and the sources**

Create `lib/features/transfer/domain/models/transfer_format_model.dart`:

```dart
/// The file formats a transfer reads and writes (UC-TRANSFER-001,
/// UC-TRANSFER-002). XLSX comes with package 9b (transfer spec D3).
enum TransferFormat {
  csv(fileExtension: 'csv', mimeType: 'text/csv'),
  tsv(fileExtension: 'tsv', mimeType: 'text/tab-separated-values');

  const TransferFormat({required this.fileExtension, required this.mimeType});

  final String fileExtension;
  final String mimeType;

  /// The format the extension of [fileName] names, in any case; null for
  /// any other extension, or none.
  static TransferFormat? ofFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0) return null;
    final extension = fileName.substring(dot + 1).toLowerCase();
    for (final format in values) {
      if (format.fileExtension == extension) return format;
    }
    return null;
  }
}
```

Create `lib/features/transfer/domain/models/import_source_model.dart`:

```dart
import 'dart:typed_data';

/// Where an import reads its rows from (UC-TRANSFER-001 step 2).
sealed class ImportSource {
  const ImportSource();
}

/// A file the person picked, read in memory. Its [name] gives the format,
/// and is never logged or kept (BR-TRANSFER-006).
final class ImportFile extends ImportSource {
  const ImportFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Rows the person pasted (UC-TRANSFER-001 A1).
final class PastedText extends ImportSource {
  const PastedText(this.text);

  final String text;
}
```

- [ ] **Step 4: Name the refusals of a source**

Replace the whole of `lib/features/transfer/domain/failures/transfer_failure.dart` with:

```dart
/// Why the transfer feature refuses a request (ADR-011 D6).
enum TransferRejection {
  /// UC-TRANSFER-001 E1: the file is neither a .csv nor a .tsv.
  unsupportedFormat,

  /// UC-TRANSFER-001 E1, BR-TRANSFER-006: the file is not UTF-8.
  notUtf8,

  /// UC-TRANSFER-001 E1: the source cannot be read, like a quoted field
  /// that never closes.
  unreadable,

  /// BR-TRANSFER-002: no column feeds the front or the back.
  mappingIncomplete,

  /// UC-TRANSFER-001 E4: the target deck is gone or in the Trash.
  deckNotFound,

  /// UC-TRANSFER-001 E4, BR-TRANSFER-001: the target deck is a root or
  /// holds sub-decks.
  deckRejectsCards,
}
```

- [ ] **Step 5: Read CSV, TSV and pasted text**

Create `lib/features/transfer/data/mappers/delimited_text_mapper.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

const _comma = ',';
const _semicolon = ';';
const _tab = '\t';
const _quote = '"';
const _carriageReturn = '\r';
const _lineFeed = '\n';
const _utf8Bom = [0xEF, 0xBB, 0xBF];
const _utf16LittleEndianBom = [0xFF, 0xFE];
const _utf16BigEndianBom = [0xFE, 0xFF];

/// [source] read as one sheet (transfer spec §5): a file by its extension
/// and as strict UTF-8, pasted text as it is. Pure, so it can run on
/// another isolate.
Outcome<ImportDocument, TransferRejection> readDelimited(ImportSource source) {
  switch (source) {
    case PastedText(:final text):
      final body = text.startsWith('\uFEFF') ? text.substring(1) : text;
      return _records(body, _delimiterOf(body, isTabAllowed: true));
    case ImportFile(:final name, :final bytes):
      final format = TransferFormat.ofFileName(name);
      if (format == null) {
        return const Rejected(TransferRejection.unsupportedFormat);
      }
      final text = _decodeUtf8(bytes);
      if (text == null) return const Rejected(TransferRejection.notUtf8);
      return _records(text, switch (format) {
        TransferFormat.csv => _delimiterOf(text, isTabAllowed: false),
        TransferFormat.tsv => _tab,
      });
  }
}

/// [bytes] as strict UTF-8 after an optional UTF-8 BOM; null when they are
/// not UTF-8: a UTF-16 or UTF-32 BOM, a malformed sequence, or a U+0000,
/// which UTF-16 without a BOM leaves (transfer spec D4). Nothing guesses
/// another encoding (BR-TRANSFER-006).
String? _decodeUtf8(Uint8List bytes) {
  if (_startsWith(bytes, _utf16LittleEndianBom) ||
      _startsWith(bytes, _utf16BigEndianBom)) {
    return null;
  }
  final body = _startsWith(bytes, _utf8Bom)
      ? Uint8List.sublistView(bytes, _utf8Bom.length)
      : bytes;
  final String text;
  try {
    text = utf8.decode(body);
  } on FormatException {
    // The error quotes the bytes, the person's own content: it stays here
    // (BR-TRANSFER-006), and the reason is what the caller needs.
    return null;
  }
  return text.contains('\u0000') ? null : text;
}

bool _startsWith(Uint8List bytes, List<int> prefix) {
  if (bytes.length < prefix.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (bytes[index] != prefix[index]) return false;
  }
  return true;
}

/// The delimiter of a CSV file or of pasted text (transfer spec §5.2), from
/// the first record that holds anything but whitespace, counting only what
/// lies outside quotes: a tab when [isTabAllowed] and the record holds one;
/// `;` when it holds `;` and no `,`; `,` otherwise.
String _delimiterOf(String text, {required bool isTabAllowed}) {
  final (:commas, :semicolons, :tabs) = _firstRecordDelimiters(text);
  if (isTabAllowed && tabs > 0) return _tab;
  if (semicolons > 0 && commas == 0) return _semicolon;
  return _comma;
}

({int commas, int semicolons, int tabs}) _firstRecordDelimiters(String text) {
  var commas = 0;
  var semicolons = 0;
  var tabs = 0;
  var hasText = false;
  var isQuoted = false;
  var isFieldStart = true;
  var index = 0;
  while (index < text.length) {
    final char = text[index];
    index++;
    if (isQuoted) {
      if (char != _quote) continue;
      if (index < text.length && text[index] == _quote) {
        index++;
        continue;
      }
      isQuoted = false;
      continue;
    }
    if (char == _carriageReturn || char == _lineFeed) {
      if (hasText) break;
      commas = 0;
      semicolons = 0;
      tabs = 0;
      isFieldStart = true;
      continue;
    }
    if (char == _quote && isFieldStart) {
      isQuoted = true;
      hasText = true;
      isFieldStart = false;
      continue;
    }
    isFieldStart = char == _comma || char == _semicolon || char == _tab;
    switch (char) {
      case _comma:
        commas++;
      case _semicolon:
        semicolons++;
      case _tab:
        tabs++;
      default:
        if (char.trim().isNotEmpty) hasText = true;
    }
  }
  return (commas: commas, semicolons: semicolons, tabs: tabs);
}

/// The records of [text], split by [delimiter] (RFC 4180, with the
/// leniencies of transfer spec §5.3), numbered from 1; `unreadable` when a
/// quoted field never closes.
Outcome<ImportDocument, TransferRejection> _records(
  String text,
  String delimiter,
) {
  final rows = <ImportRow>[];
  var cells = <String>[];
  final cell = StringBuffer();
  var isQuoted = false;
  var isFieldStart = true;
  var isRecordOpen = false;

  void endField() {
    cells.add(cell.toString());
    cell.clear();
    isFieldStart = true;
  }

  void endRecord() {
    endField();
    rows.add(ImportRow(number: rows.length + 1, cells: cells));
    cells = [];
    isRecordOpen = false;
  }

  var index = 0;
  while (index < text.length) {
    final char = text[index];
    index++;
    isRecordOpen = true;
    if (isQuoted) {
      if (char != _quote) {
        cell.write(char);
        continue;
      }
      if (index < text.length && text[index] == _quote) {
        cell.write(_quote);
        index++;
        continue;
      }
      isQuoted = false;
      continue;
    }
    if (char == _quote && isFieldStart) {
      isQuoted = true;
      isFieldStart = false;
      continue;
    }
    if (char == delimiter) {
      endField();
      continue;
    }
    if (char == _carriageReturn || char == _lineFeed) {
      final isCrLf =
          char == _carriageReturn &&
          index < text.length &&
          text[index] == _lineFeed;
      if (isCrLf) index++;
      endRecord();
      continue;
    }
    isFieldStart = false;
    cell.write(char);
  }
  if (isQuoted) return const Rejected(TransferRejection.unreadable);
  if (isRecordOpen) endRecord();
  return Ok(ImportDocument([ImportSheet(rows: rows)]));
}
```

- [ ] **Step 6: Read a source off the calling isolate**

In `lib/features/transfer/domain/repositories/transfer_repository.dart`:

Replace

```dart
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';

```

with

```dart
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';

```

Replace

```dart
abstract interface class TransferRepository {
  /// UC-TRANSFER-001 step 5: the data rows of [sheet], classified against
```

with

```dart
abstract interface class TransferRepository {
  /// UC-TRANSFER-001 steps 2-3: [source] read in memory, off the calling
  /// isolate, as a document (transfer spec §5). Refuses a file that is
  /// neither a .csv nor a .tsv (unsupportedFormat), one that is not UTF-8
  /// (notUtf8), and a source that cannot be read (unreadable) (E1,
  /// BR-TRANSFER-006).
  Future<Outcome<ImportDocument, TransferRejection>> readSource(
    ImportSource source,
  );

  /// UC-TRANSFER-001 step 5: the data rows of [sheet], classified against
```

In `lib/features/transfer/data/repositories/transfer_repository_impl.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';
```

with

```dart
import 'dart:isolate';

import 'package:memox/core/database/app_database.dart';
```

Replace

```dart
import 'package:memox/features/transfer/data/datasources/transfer_dao.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
```

with

```dart
import 'package:memox/features/transfer/data/datasources/transfer_dao.dart';
import 'package:memox/features/transfer/data/mappers/delimited_text_mapper.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
```

Replace

```dart
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';
```

with

```dart
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';
```

Replace

```dart
  final DateTime Function() _now;

```

with

```dart
  final DateTime Function() _now;

  @override
  Future<Outcome<ImportDocument, TransferRejection>> readSource(
    ImportSource source,
  ) => Isolate.run(() => readDelimited(source));

```

- [ ] **Step 7: Write the use case**

Create `lib/features/transfer/domain/usecases/read_import_source_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-001 steps 2-3: a picked file or pasted text read in memory;
/// nothing is written (BR-TRANSFER-006).
final class ReadImportSourceUseCase {
  const ReadImportSourceUseCase(this._transfer);

  final TransferRepository _transfer;

  Future<Outcome<ImportDocument, TransferRejection>> call(
    ImportSource source,
  ) => _transfer.readSource(source);
}
```

- [ ] **Step 8: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 51 warning(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/features/transfer/data/delimited_text_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart
```

Expected: `+14: All tests passed!`

- [ ] **Step 10: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/transfer/data/mappers/delimited_text_mapper.dart \
  lib/features/transfer/data/repositories/transfer_repository_impl.dart \
  lib/features/transfer/domain/failures/transfer_failure.dart \
  lib/features/transfer/domain/models/import_source_model.dart \
  lib/features/transfer/domain/models/transfer_format_model.dart \
  lib/features/transfer/domain/repositories/transfer_repository.dart \
  lib/features/transfer/domain/usecases/read_import_source_use_case.dart \
  test/features/transfer/data/delimited_text_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 11: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 51 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1658: All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git commit -F - <<'EOF'
feat(transfer): read a CSV or TSV file, or pasted text

readSource reads a source in memory, off the calling isolate, as one
sheet of numbered records (UC-TRANSFER-001 steps 2-3). A file is a .csv
or a .tsv by its extension, and strict UTF-8 after an optional BOM;
anything else is unsupportedFormat or notUtf8, and no encoding is
guessed (BR-TRANSFER-006; transfer spec D4). A .csv is split on ";"
when its first record holds ";" and no "," outside quotes; pasted text
on tabs when it holds one (D5). Records follow RFC 4180 with the
leniencies of spec §5.3; a quoted field that never closes is unreadable
(E1). ReadImportSourceUseCase.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: Export a deck's cards as a CSV or TSV file

**Files:**
- Create: `lib/features/transfer/domain/models/export_model.dart`, `lib/features/transfer/domain/usecases/export_cards_use_case.dart`
- Modify: `lib/features/transfer/data/datasources/transfer_dao.dart`, `lib/features/transfer/data/mappers/delimited_text_mapper.dart`, `lib/features/transfer/data/repositories/transfer_repository_impl.dart`, `lib/features/transfer/domain/failures/transfer_failure.dart`, `lib/features/transfer/domain/repositories/transfer_repository.dart`
- Test (create): `test/features/transfer/data/export_cards_test.dart`, `test/features/transfer/domain/export_file_name_test.dart`
- Test (modify): `test/features/transfer/domain/transfer_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `canonicalHeaders` and `TagCell.encode`; Task 1's `CardField`;
  Task 4's `TransferFormat`, `readSource` and the mapper's constants; `DayClock`
  (`lib/core/clock/day_clock.dart`) and `FakeDayClock` in the tests.
- Produces:
  - `TransferRejection.emptyScope` and `staleSelection`, last in the enum.
  - `sealed class ExportScope` with `ExportAllCards()` and
    `ExportSelectedCards(Set<String> cardIds)`;
    `ExportFile({required String fileName, required String mimeType, required Uint8List bytes, required int cardCount})`;
    `const exportNameMaxBytes = 200`;
    `String exportFileName({required String deckName, required DateTime now, required TransferFormat format})`.
  - `Uint8List writeDelimited(List<List<String>> records, TransferFormat format)`.
  - In `TransferDao`: `Future<String?> activeDeckName(String deckId)`,
    `Future<List<CardRow>> activeCards(String deckId)` and
    `Future<Map<String, List<String>>> tagNames(String deckId)`.
  - `Future<Outcome<ExportFile, TransferRejection>> TransferRepository.exportCards({required String deckId, required ExportScope scope, required TransferFormat format, required DateTime now})`.
  - `ExportCardsUseCase(TransferRepository, DayClock)` with
    `call({required String deckId, required ExportScope scope, required TransferFormat format})`.

Spec §8, D13–D16; Clarifications 5 and 9; Review Focus 4 and 5. The round trip
runs export, reader and commit together.

- [ ] **Step 1: Write the failing tests**

Create `test/features/transfer/data/export_cards_test.dart`:

```dart
import 'dart:convert';

import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
import 'package:memox/features/transfer/domain/models/import_result_model.dart';
import 'package:memox/features/transfer/domain/models/import_sheet_model.dart';
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
import '../../../support/trash_fixtures.dart';

// UC-TRANSFER-002: one snapshot of a deck's cards, written as a CSV or TSV
// file, read-only (BR-TRANSFER-007…BR-TRANSFER-013; transfer spec §8).

DateTime _now() => DateTime(2026, 9, 26, 10);

const _utf8Bom = [0xEF, 0xBB, 0xBF];

/// The file's text after the UTF-8 BOM that starts every export (transfer
/// spec D14). `utf8.decode` would drop the BOM silently, so its bytes are
/// checked here.
String _text(ExportFile file) {
  expect(file.bytes.take(_utf8Bom.length), _utf8Bom);
  return utf8.decode(file.bytes.skip(_utf8Bom.length).toList());
}

Matcher _refused(TransferRejection reason) =>
    isA<Rejected<ExportFile, TransferRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

ExportFile _file(Outcome<ExportFile, TransferRejection> result) =>
    (result as Ok<ExportFile, TransferRejection>).value;

/// Fails every read once [isFailing] is set (UC-TRANSFER-002 E3).
final class _FailingReads extends QueryInterceptor {
  bool isFailing = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isFailing) throw StateError('disk I/O error');
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late CardRepositoryImpl cards;
  late TransferRepositoryImpl transfer;
  late DeckEntity root;
  late DeckEntity deck;

  Future<void> open(AppDatabase database) async {
    db = database;
    decks = DeckRepositoryImpl(db, now: _now);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: _now),
      TagRepositoryImpl(db, now: _now),
      now: _now,
    );
    transfer = TransferRepositoryImpl(db, cards, now: _now);
    root = await decks.root('r');
    deck = await decks.sub(root.id, 'Nhà hàng');
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() => db.close());

  /// A card of [deckId] created on day [day] of September.
  Future<String> card(int day, CardDraft draft, {String? deckId}) async {
    final result = await cards.createCard(
      deckId: deckId ?? deck.id,
      draft: draft,
      now: DateTime(2026, 9, day),
    );
    return switch (result) {
      Ok(:final value) => value.id,
      Rejected(:final reason) => throw StateError('fixture card: $reason'),
    };
  }

  Future<Outcome<ExportFile, TransferRejection>> export(
    ExportScope scope, [
    TransferFormat format = TransferFormat.csv,
  ]) => transfer.exportCards(
    deckId: deck.id,
    scope: scope,
    format: format,
    now: _now(),
  );

  test('a CSV file: a BOM, the six canonical headers, then a CRLF record a '
      'card, oldest first, with empty cells, quotes where a cell needs them '
      'and tags by folded name (BR-TRANSFER-008, BR-TRANSFER-010, '
      'BR-TRANSFER-012)', () async {
    await card(
      3,
      const CardDraft(
        front: 'say "hi"',
        back: 'line 1\nline 2',
        example: 'a, b',
      ),
    );
    await card(
      1,
      const CardDraft(
        front: 'tip',
        back: 'tiền boa',
        pronunciation: '/tɪp/',
        tagNames: ['verb', 'Noun', r'a;b\c'],
      ),
    );
    await card(2, const CardDraft(front: '=1+1', back: '001'));

    final file = _file(await export(const ExportAllCards()));

    expect(
      _text(file),
      'front,back,example,hint,pronunciation,tags\r\n'
      'tip,tiền boa,,,/tɪp/,a\\;b\\\\c;Noun;verb\r\n'
      '=1+1,001,,,,\r\n'
      '"say ""hi""","line 1\nline 2","a, b",,,\r\n',
    );
    expect(
      (file.fileName, file.mimeType, file.cardCount),
      ('Nhà hàng 2026-09-26.csv', 'text/csv', 3),
    );
  });

  test('a TSV file is split by tabs and quotes a cell holding one', () async {
    await card(1, const CardDraft(front: 'a\tb', back: 'c, d'));

    final file = _file(
      await export(const ExportAllCards(), TransferFormat.tsv),
    );

    expect(
      _text(file),
      'front\tback\texample\thint\tpronunciation\ttags\r\n'
      '"a\tb"\tc, d\t\t\t\t\r\n',
    );
    expect(
      (file.fileName, file.mimeType),
      ('Nhà hàng 2026-09-26.tsv', 'text/tab-separated-values'),
    );
  });

  test('all is every active card of the deck itself, whatever the list '
      'shows: not those in the Trash, not another deck\'s '
      '(BR-TRANSFER-007)', () async {
    final other = await decks.sub(root.id, 'o');
    await card(1, const CardDraft(front: 'kept', back: 'x'));
    final trashed = await card(2, const CardDraft(front: 'trashed', back: 'x'));
    await trashCardRow(db, trashed);
    await card(
      3,
      const CardDraft(front: 'elsewhere', back: 'x'),
      deckId: other.id,
    );

    final file = _file(await export(const ExportAllCards()));

    expect(file.cardCount, 1);
    expect(_text(file), contains('kept'));
    expect(_text(file), isNot(contains('trashed')));
    expect(_text(file), isNot(contains('elsewhere')));
  });

  test('selected is those cards, oldest first whatever the set\'s order '
      '(BR-TRANSFER-007, BR-TRANSFER-010)', () async {
    final third = await card(3, const CardDraft(front: 'c3', back: 'x'));
    await card(2, const CardDraft(front: 'c2', back: 'x'));
    final first = await card(1, const CardDraft(front: 'c1', back: 'x'));

    final file = _file(await export(ExportSelectedCards({third, first})));

    expect(file.cardCount, 2);
    expect(
      _text(file).split('\r\n').skip(1).map((line) => line.split(',').first),
      ['c1', 'c3', ''],
    );
  });

  test(
    'a selected card sent to the Trash, moved or gone fails the whole '
    'export, and so does an empty selection (UC-TRANSFER-002 E5, E6)',
    () async {
      final other = await decks.sub(root.id, 'o');
      final kept = await card(1, const CardDraft(front: 'kept', back: 'x'));
      final trashed = await card(
        2,
        const CardDraft(front: 'trashed', back: 'x'),
      );
      await trashCardRow(db, trashed);
      final moved = await card(3, const CardDraft(front: 'moved', back: 'x'));
      await cards.moveCards(cardIds: {moved}, targetDeckId: other.id);

      for (final stale in [trashed, moved, 'missing']) {
        expect(
          await export(ExportSelectedCards({kept, stale})),
          _refused(TransferRejection.staleSelection),
          reason: stale,
        );
      }
      expect(
        await export(const ExportSelectedCards({})),
        _refused(TransferRejection.emptyScope),
      );
    },
  );

  test('a deck with no card is emptyScope; one that is gone or in the Trash '
      'is deckNotFound (UC-TRANSFER-002 E5)', () async {
    expect(
      await export(const ExportAllCards()),
      _refused(TransferRejection.emptyScope),
    );
    expect(
      await transfer.exportCards(
        deckId: root.id,
        scope: const ExportAllCards(),
        format: TransferFormat.csv,
        now: _now(),
      ),
      _refused(TransferRejection.emptyScope),
    );
    await trashDeckRows(db, deck.id);
    expect(
      await export(const ExportAllCards()),
      _refused(TransferRejection.deckNotFound),
    );
    expect(
      await transfer.exportCards(
        deckId: 'missing',
        scope: const ExportAllCards(),
        format: TransferFormat.csv,
        now: _now(),
      ),
      _refused(TransferRejection.deckNotFound),
    );
  });

  test('a read that fails leaves as a database Failure, with no file '
      '(UC-TRANSFER-002 E3)', () async {
    final reads = _FailingReads();
    await db.close();
    await open(openTestDatabase(interceptor: reads));
    await card(1, const CardDraft(front: 'tip', back: 'tiền boa'));
    reads.isFailing = true;

    await expectLater(
      export(const ExportAllCards()),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
  });

  test('an export writes nothing (BR-TRANSFER-011)', () async {
    final id = await card(
      1,
      const CardDraft(front: 'a', back: 'b', tagNames: ['t']),
    );
    final before = await totalChanges(db);

    await export(const ExportAllCards());
    await export(ExportSelectedCards({id}), TransferFormat.tsv);

    expect(await totalChanges(db), before);
  });

  test('the file imported back into its own deck adds nothing: each row is '
      'a duplicate in the deck (BR-TRANSFER-003)', () async {
    await card(
      1,
      const CardDraft(front: 'tip', back: 'tiền boa', tagNames: ['noun']),
    );
    await card(2, const CardDraft(front: 'bill', back: 'hóa, đơn'));
    final file = _file(await export(const ExportAllCards()));
    final document = await transfer.readSource(
      ImportFile(name: file.fileName, bytes: file.bytes),
    );
    final sheet =
        (document as Ok<ImportDocument, TransferRejection>).value.sheets.single;
    final before = await totalChanges(db);

    final preview = await transfer.previewImport(
      deckId: deck.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );
    final result = await transfer.importCards(
      deckId: deck.id,
      sheet: sheet,
      settings: const ImportSettings(),
    );

    expect((preview.duplicateCount, preview.writeCount), (2, 0));
    expect(
      (result as Ok<ImportResult, TransferRejection>).value.skippedDuplicates,
      2,
    );
    expect(result.value.added, 0);
    expect(await totalChanges(db), before);
  });

  test('a round trip: the file imported into an empty deck gives the same '
      'six fields, tag sets and order (BR-TRANSFER-009)', () async {
    for (final (day, draft) in [
      (
        1,
        const CardDraft(
          front: 'tip',
          back: 'tiền boa',
          tagNames: ['Noun', r'x\;y'],
        ),
      ),
      (
        2,
        const CardDraft(
          front: 'bill',
          back: 'hóa, đơn',
          example: '"quoted"',
          hint: 'h',
        ),
      ),
      (
        3,
        const CardDraft(
          front: 'menu',
          back: 'thực\nđơn',
          pronunciation: 'p',
          tagNames: ['a;b'],
        ),
      ),
    ]) {
      await card(day, draft);
    }
    final copy = await decks.sub(root.id, 'copy');

    for (final format in TransferFormat.values) {
      final file = _file(await export(const ExportAllCards(), format));
      final document = await transfer.readSource(
        ImportFile(name: file.fileName, bytes: file.bytes),
      );
      final sheet = (document as Ok<ImportDocument, TransferRejection>)
          .value
          .sheets
          .single;
      await transfer.importCards(
        deckId: copy.id,
        sheet: sheet,
        settings: const ImportSettings(shouldIncludeDuplicates: true),
      );
      final copied = _file(
        await transfer.exportCards(
          deckId: copy.id,
          scope: const ExportAllCards(),
          format: format,
          now: _now(),
        ),
      );
      final records = _text(copied).split('\r\n');
      expect(
        records.skip(1).take(3).toList(),
        _text(file).split('\r\n').skip(1).take(3).toList(),
        reason: format.name,
      );
      await db.customStatement('DELETE FROM card WHERE deck_id = ?', [copy.id]);
    }
  });
}
```

Create `test/features/transfer/domain/export_file_name_test.dart`:

```dart
import 'dart:convert';

import 'package:characters/characters.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

// UC-TRANSFER-002 step 5: the file's name, from the deck's name and the
// day (BR-TRANSFER-013; transfer spec D15).

final _day = DateTime(2026, 9, 26, 23, 59);

String _nameOf(String deckName, [TransferFormat format = TransferFormat.csv]) =>
    exportFileName(deckName: deckName, now: _day, format: format);

void main() {
  test(
    'the deck keeps its spelling; the local day and the extension follow',
    () {
      expect(_nameOf('Nhà hàng'), 'Nhà hàng 2026-09-26.csv');
      expect(_nameOf('명사', TransferFormat.tsv), '명사 2026-09-26.tsv');
      expect(
        exportFileName(
          deckName: 'x',
          now: DateTime(2026, 1, 5),
          format: TransferFormat.csv,
        ),
        'x 2026-01-05.csv',
      );
    },
  );

  test('path separators, characters no file system takes and control '
      'characters go; whitespace runs become one space', () {
    expect(_nameOf(r'a/b\c:d*e?f"g<h>i|j'), 'abcdefghij 2026-09-26.csv');
    expect(_nameOf('a\u0000b\u007Fc\u009Fd'), 'abcd 2026-09-26.csv');
    expect(_nameOf('Nhà \t\n  hàng'), 'Nhà hàng 2026-09-26.csv');
    expect(_nameOf('a / b'), 'a b 2026-09-26.csv');
  });

  test('leading and trailing spaces and dots go, and a name with nothing '
      'left is cards', () {
    expect(_nameOf(' . .hidden. . '), 'hidden 2026-09-26.csv');
    expect(_nameOf('/:*?'), 'cards 2026-09-26.csv');
    expect(_nameOf('  ...  '), 'cards 2026-09-26.csv');
  });

  test('the name is cut to 200 UTF-8 bytes on a whole character', () {
    for (final grapheme in ['Ệ', '😀', 'é', '👨‍👩‍👧']) {
      final name = _nameOf('a${grapheme * 200}');
      final kept = name.substring(0, name.length - ' 2026-09-26.csv'.length);

      expect(
        utf8.encode(kept).length,
        lessThanOrEqualTo(200),
        reason: grapheme,
      );
      expect(
        utf8.encode('$kept$grapheme').length,
        greaterThan(200),
        reason: grapheme,
      );
      expect(
        kept.characters.skip(1).every((each) => each == grapheme),
        isTrue,
        reason: grapheme,
      );
    }
  });
}
```

In `test/features/transfer/domain/transfer_use_cases_test.dart`:

Replace

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
```

with

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
```

Replace

```dart
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/usecases/import_cards_use_case.dart';
```

with

```dart
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/usecases/export_cards_use_case.dart';
import 'package:memox/features/transfer/domain/usecases/import_cards_use_case.dart';
```

Replace

```dart
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';
```

with

```dart
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/test_database.dart';
```

Replace

```dart
        TransferRejection.unsupportedFormat,
      ),
    );
  });
}
```

with

```dart
        TransferRejection.unsupportedFormat,
      ),
    );
  });

  test('ExportCardsUseCase names the file with the day of the clock', () async {
    await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: 'tip', back: 'tiền boa'),
    );

    final result =
        await ExportCardsUseCase(
          transfer,
          FakeDayClock(DateTime(2026, 12, 31, 23)),
        )(
          deckId: leaf.id,
          scope: const ExportAllCards(),
          format: TransferFormat.tsv,
        );

    expect(
      (result as Ok<ExportFile, TransferRejection>).value.fileName,
      'l 2026-12-31.tsv',
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/transfer/data/export_cards_test.dart \
  test/features/transfer/domain/export_file_name_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three test files compiles:
`Error: Error when reading 'lib/features/transfer/domain/models/export_model.dart': No such file or directory`,
the same for `export_cards_use_case.dart`,
`Error: The method 'exportCards' isn't defined for the type 'TransferRepositoryImpl'.`
and `Error: Member not found: 'emptyScope'.`

- [ ] **Step 3: Name the scopes, the file and its name**

In `lib/features/transfer/domain/failures/transfer_failure.dart`:

Replace

```dart
  deckRejectsCards,
}
```

with

```dart
  deckRejectsCards,

  /// UC-TRANSFER-002 E5, BR-TRANSFER-007: the deck has no card, or the
  /// selection is empty.
  emptyScope,

  /// UC-TRANSFER-002 E6, BR-TRANSFER-007: a selected card is gone, in the
  /// Trash, or in another deck.
  staleSelection,
}
```

Create `lib/features/transfer/domain/models/export_model.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

/// Which cards an export takes (BR-TRANSFER-007): it follows from where the
/// person opened it, and the sheet never changes it.
sealed class ExportScope {
  const ExportScope();
}

/// Every active card of the deck itself, whatever the list shows.
final class ExportAllCards extends ExportScope {
  const ExportAllCards();
}

/// The cards the person selected, each once.
final class ExportSelectedCards extends ExportScope {
  const ExportSelectedCards(this.cardIds);

  final Set<String> cardIds;
}

/// The file an export made, for the private cache and the share sheet
/// (BR-TRANSFER-014; transfer spec D16).
final class ExportFile {
  const ExportFile({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
    required this.cardCount,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
  final int cardCount;
}

/// The longest a file name's deck part may be: with the date and the
/// extension it stays within the 255 bytes a file system takes.
const exportNameMaxBytes = 200;

const _fallbackName = 'cards';

final _whitespace = RegExp(r'\s+');
final _invalid = RegExp(r'[<>:"/\\|?*\u0000-\u001F\u007F-\u009F]');
final _outerSpacesAndDots = RegExp(r'^[ .]+|[ .]+$');

/// The name of an export's file (BR-TRANSFER-013; transfer spec D15): the
/// deck's name without path separators, characters no file system takes
/// and control characters, its whitespace runs made one space, no space or
/// dot at either end, and cut to [exportNameMaxBytes] UTF-8 bytes on whole
/// characters, or `cards` when nothing is left; then a space, the day of
/// [now] as `yyyy-MM-dd`, and the format's extension.
String exportFileName({
  required String deckName,
  required DateTime now,
  required TransferFormat format,
}) {
  final cleaned = _strip(
    deckName.replaceAll(_whitespace, ' ').replaceAll(_invalid, ''),
  ).replaceAll(_whitespace, ' ');
  final name = _strip(_cutToBytes(cleaned, exportNameMaxBytes));
  final day = '${now.year}-${_twoDigits(now.month)}-${_twoDigits(now.day)}';
  return '${name.isEmpty ? _fallbackName : name} $day.${format.fileExtension}';
}

String _strip(String name) => name.replaceAll(_outerSpacesAndDots, '');

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String _cutToBytes(String text, int maxBytes) {
  final kept = StringBuffer();
  var bytes = 0;
  for (final character in text.characters) {
    bytes += utf8.encode(character).length;
    if (bytes > maxBytes) break;
    kept.write(character);
  }
  return kept.toString();
}
```

- [ ] **Step 4: Write CSV and TSV**

In `lib/features/transfer/data/mappers/delimited_text_mapper.dart`:

Replace

```dart
const _utf8Bom = [0xEF, 0xBB, 0xBF];
const _utf16LittleEndianBom = [0xFF, 0xFE];
```

with

```dart
const _utf8Bom = [0xEF, 0xBB, 0xBF];
const _recordEnd = '\r\n';
const _utf16LittleEndianBom = [0xFF, 0xFE];
```

Replace

```dart
        TransferFormat.tsv => _tab,
      });
  }
}

/// [bytes] as strict UTF-8 after an optional UTF-8 BOM; null when they are
```

with

```dart
        TransferFormat.tsv => _tab,
      });
  }
}

/// [records] as a CSV or TSV file (transfer spec D14): a UTF-8 BOM, then
/// each record and a CRLF; a cell is quoted, its quotes doubled, only when
/// it holds the delimiter, a quote, a CR or an LF, and is otherwise written
/// as it is (BR-TRANSFER-012).
Uint8List writeDelimited(List<List<String>> records, TransferFormat format) {
  final delimiter = switch (format) {
    TransferFormat.csv => _comma,
    TransferFormat.tsv => _tab,
  };
  final text = StringBuffer();
  for (final record in records) {
    text
      ..writeAll([
        for (final cell in record) _cellOf(cell, delimiter),
      ], delimiter)
      ..write(_recordEnd);
  }
  return Uint8List.fromList([..._utf8Bom, ...utf8.encode(text.toString())]);
}

String _cellOf(String cell, String delimiter) {
  final isQuoted =
      cell.contains(delimiter) ||
      cell.contains(_quote) ||
      cell.contains(_carriageReturn) ||
      cell.contains(_lineFeed);
  if (!isQuoted) return cell;
  return '$_quote${cell.replaceAll(_quote, '$_quote$_quote')}$_quote';
}

/// [bytes] as strict UTF-8 after an optional UTF-8 BOM; null when they are
```

- [ ] **Step 5: Read the export's snapshot**

Replace the whole of `lib/features/transfer/data/datasources/transfer_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';

/// Row access for transfer: the keys of a deck's cards (transfer spec
/// §6.2) and the three reads of an export's snapshot (§8.1). It runs
/// inside the caller's transaction.
final class TransferDao {
  TransferDao(this._db);

  final AppDatabase _db;

  /// The folded front and back of every active card of [deckId]
  /// (BR-TRANSFER-003).
  Future<Set<ContentKey>> contentKeys(String deckId) async {
    final card = _db.card;
    final rows =
        await (_db.selectOnly(card)
              ..addColumns([card.frontFolded, card.backFolded])
              ..where(card.deckId.equals(deckId) & card.deleteBatchId.isNull()))
            .get();
    return {
      for (final row in rows)
        (row.read(card.frontFolded)!, row.read(card.backFolded)!),
    };
  }

  /// The name of [deckId], unless it is gone or in the Trash.
  Future<String?> activeDeckName(String deckId) async {
    final deck =
        await (_db.select(_db.deck)..where(
              (deck) => deck.id.equals(deckId) & deck.deleteBatchId.isNull(),
            ))
            .getSingleOrNull();
    return deck?.name;
  }

  /// The active cards of [deckId] itself, oldest first, then by id
  /// (BR-TRANSFER-007, BR-TRANSFER-010).
  Future<List<CardRow>> activeCards(String deckId) =>
      (_db.select(_db.card)
            ..where(
              (card) =>
                  card.deckId.equals(deckId) & card.deleteBatchId.isNull(),
            )
            ..orderBy([
              (card) => OrderingTerm(expression: card.createdAt),
              (card) => OrderingTerm(expression: card.id),
            ]))
          .get();

  /// The tag names of the active cards of [deckId], by card, in one
  /// statement rather than one a card, each card's by folded name, then id
  /// (BR-TRANSFER-010).
  Future<Map<String, List<String>>> tagNames(String deckId) async {
    final rows = await _db
        .customSelect(
          'SELECT ct.card_id, t.name FROM card_tags ct'
          ' JOIN tags t ON t.id = ct.tag_id'
          ' JOIN card c ON c.id = ct.card_id'
          ' WHERE c.deck_id = ? AND c.delete_batch_id IS NULL'
          ' AND t.owner_id IS NULL'
          ' ORDER BY ct.card_id, t.name_folded, t.id',
          variables: [Variable<String>(deckId)],
          readsFrom: {_db.cardTags, _db.tags, _db.card},
        )
        .get();
    final names = <String, List<String>>{};
    for (final row in rows) {
      names
          .putIfAbsent(row.read<String>('card_id'), () => [])
          .add(row.read<String>('name'));
    }
    return names;
  }
}
```

- [ ] **Step 6: Export the cards of a scope**

In `lib/features/transfer/domain/repositories/transfer_repository.dart`:

Replace

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
```

with

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
```

Replace

```dart
import 'package:memox/features/transfer/domain/models/import_source_model.dart';

```

with

```dart
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';

```

Replace

```dart
    DateTime? now,
  });
}
```

with

```dart
    DateTime? now,
  });

  /// UC-TRANSFER-002 steps 4-5: the cards of [scope] in [deckId] as one file
  /// of [format], read from one snapshot, oldest first (BR-TRANSFER-010),
  /// and named for the deck and the local day of [now] (BR-TRANSFER-013).
  /// Writes nothing (BR-TRANSFER-011). Refuses a deck that is gone or in the
  /// Trash (deckNotFound), a scope with no card (emptyScope, E5), and a
  /// selection holding a card that is no longer active in the deck
  /// (staleSelection, E6). A failed read leaves as a database `Failure` (E3).
  Future<Outcome<ExportFile, TransferRejection>> exportCards({
    required String deckId,
    required ExportScope scope,
    required TransferFormat format,
    required DateTime now,
  });
}
```

In `lib/features/transfer/data/repositories/transfer_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
```

with

```dart
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_field_model.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
```

Replace

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
```

with

```dart
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/column_mapping_model.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/import_preview_model.dart';
```

Replace

```dart
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';
```

with

```dart
import 'package:memox/features/transfer/domain/models/import_source_model.dart';
import 'package:memox/features/transfer/domain/models/tag_cell_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';
```

Replace

```dart

  /// [body], with an unexpected database error leaving as its [Failure].
```

with

```dart

  @override
  Future<Outcome<ExportFile, TransferRejection>> exportCards({
    required String deckId,
    required ExportScope scope,
    required TransferFormat format,
    required DateTime now,
  }) async {
    final (:deckName, :cards, :tags) = await _mapped(
      () => _db.transaction(
        () async => (
          deckName: await _dao.activeDeckName(deckId),
          cards: await _dao.activeCards(deckId),
          tags: await _dao.tagNames(deckId),
        ),
      ),
    );
    if (deckName == null) return const Rejected(TransferRejection.deckNotFound);
    return switch (_cardsIn(scope, cards)) {
      Rejected(:final reason) => Rejected(reason),
      Ok(value: final chosen) => Ok(
        ExportFile(
          fileName: exportFileName(
            deckName: deckName,
            now: now,
            format: format,
          ),
          mimeType: format.mimeType,
          bytes: writeDelimited(_recordsOf(chosen, tags), format),
          cardCount: chosen.length,
        ),
      ),
    };
  }

  /// [body], with an unexpected database error leaving as its [Failure].
```

Replace

```dart
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

with

```dart
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

/// The cards of [scope] among the snapshot's [cards], in the snapshot's
/// order (transfer spec §8.2).
Outcome<List<CardRow>, TransferRejection> _cardsIn(
  ExportScope scope,
  List<CardRow> cards,
) {
  final chosen = switch (scope) {
    ExportAllCards() => cards,
    ExportSelectedCards(:final cardIds) => [
      for (final card in cards)
        if (cardIds.contains(card.id)) card,
    ],
  };
  if (scope case ExportSelectedCards(:final cardIds)
      when chosen.length < cardIds.length) {
    // An id the snapshot does not hold: the card is gone, in the Trash or in
    // another deck, and the whole request fails.
    return const Rejected(TransferRejection.staleSelection);
  }
  if (chosen.isEmpty) return const Rejected(TransferRejection.emptyScope);
  return Ok(chosen);
}

/// The header, then each card's six fields in file order (BR-TRANSFER-008,
/// BR-TRANSFER-012): an empty cell for an empty field, and the tags through
/// the one codec (BR-TRANSFER-009).
List<List<String>> _recordsOf(
  List<CardRow> cards,
  Map<String, List<String>> tags,
) => [
  canonicalHeaders.values.toList(),
  for (final card in cards)
    [
      for (final field in canonicalHeaders.keys)
        switch (field) {
          CardField.front => card.front,
          CardField.back => card.back,
          CardField.example => card.example ?? '',
          CardField.hint => card.hint ?? '',
          CardField.pronunciation => card.pronunciation ?? '',
          CardField.tags => TagCell.encode(tags[card.id] ?? const []),
        },
    ],
];
```

- [ ] **Step 7: Write the use case**

Create `lib/features/transfer/domain/usecases/export_cards_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/transfer/domain/failures/transfer_failure.dart';
import 'package:memox/features/transfer/domain/models/export_model.dart';
import 'package:memox/features/transfer/domain/models/transfer_format_model.dart';
import 'package:memox/features/transfer/domain/repositories/transfer_repository.dart';

/// UC-TRANSFER-002 steps 3-5: the file of an export, named for today's date
/// on the app's clock (BR-TRANSFER-013); nothing is written
/// (BR-TRANSFER-011).
final class ExportCardsUseCase {
  const ExportCardsUseCase(this._transfer, this._clock);

  final TransferRepository _transfer;
  final DayClock _clock;

  Future<Outcome<ExportFile, TransferRejection>> call({
    required String deckId,
    required ExportScope scope,
    required TransferFormat format,
  }) => _transfer.exportCards(
    deckId: deckId,
    scope: scope,
    format: format,
    now: _clock.now(),
  );
}
```

- [ ] **Step 8: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 51 warning(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/features/transfer/data/export_cards_test.dart \
  test/features/transfer/domain/export_file_name_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart
```

Expected: `+18: All tests passed!`

- [ ] **Step 10: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/transfer/data/datasources/transfer_dao.dart \
  lib/features/transfer/data/mappers/delimited_text_mapper.dart \
  lib/features/transfer/data/repositories/transfer_repository_impl.dart \
  lib/features/transfer/domain/failures/transfer_failure.dart \
  lib/features/transfer/domain/models/export_model.dart \
  lib/features/transfer/domain/repositories/transfer_repository.dart \
  lib/features/transfer/domain/usecases/export_cards_use_case.dart \
  test/features/transfer/data/export_cards_test.dart \
  test/features/transfer/domain/export_file_name_test.dart \
  test/features/transfer/domain/transfer_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 11: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 51 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1673: All tests passed!`.

- [ ] **Step 12: Commit**

```bash
git commit -F - <<'EOF'
feat(transfer): export a deck's cards as a CSV or TSV file

UC-TRANSFER-002 steps 4-5 (transfer spec §8): one snapshot in one
transaction (the active deck, its active cards oldest first, their tags
in one statement), the scope (all, or a selection that fails whole when
a card is no longer active in the deck), a BOM, the six canonical
headers and a CRLF record a card with minimal quoting, and the file name
from the deck's name and the local day. Nothing is written; a failed
read leaves as a database Failure (E3). ExportCardsUseCase takes the day
from DayClock.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: The package's documents

**Files:**
- Modify: `docs/features/transfer/README.md`, `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`, `docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: the code of Tasks 1–5.
- Produces: the documents only.

Spec §11; Clarifications 6–8.

- [ ] **Step 1: Record the package in the transfer documents and both WBS**

Replace the whole of `docs/features/transfer/README.md` with:

```markdown
---
feature: transfer
code: [lib/features/transfer/domain, lib/features/transfer/data, lib/features/transfer/di]
depends_on: [card, deck, tags]
---
## Phạm vi

**Phạm vi:** Card Transfer, phần store (BE-B3,
[spec gói 9a](../../superpowers/specs/2026-09-26-transfer-backend-design.md)): CSV, TSV và
văn bản dán ở gói 9a; XLSX ở gói 9b.

Import card hàng loạt vào một deck và export card của một deck ra file (Card Transfer).

Nửa import của N1 (UC-TRANSFER-001): thư viện starter giải quyết "app trống lúc mới
cài", nhưng không giải quyết "bộ thẻ của tôi đang nằm trong một file" — và
nhập tay từng card không phải câu trả lời cho một file nghìn dòng. Nửa export
(UC-TRANSFER-002): mang bộ thẻ ra khỏi app là điều kiện để "dữ liệu của tôi" không bị
khoá trong một cài đặt duy nhất — nhưng nó là export **nội dung**, không phải
backup, nên không thay thế được sync.

Import đọc nguồn trong bộ nhớ, trên một isolate khác (`ReadImportSourceUseCase`), rồi
xếp mỗi hàng dữ liệu vào một trạng thái bằng đúng các rule của card: sẵn sàng, trùng,
invalid hay trống (`PreviewImportUseCase`). Commit xếp lại trên deck như lúc ghi và ghi
tất cả hoặc không gì trong một transaction (`ImportCardsUseCase`); card nhập vào giữ thứ
tự của file khi học và khi export. Export đọc một snapshot và không ghi gì
(`ExportCardsUseCase`). Ô tags của cả hai chiều đi qua một codec duy nhất, `TagCell`
(BR-TRANSFER-009).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Card list của deck loại card — "Import cards" | UC-TRANSFER-001 |
| Card list — `Export cards` trong overflow menu | UC-TRANSFER-002 |

Nguồn: trigger của UC-TRANSFER-001 và UC-TRANSFER-002.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Backup/restore, sync, `.apkg` | Nice-to-have ngoài phạm vi export nội dung (trước migrate: `use-cases/README.md` mục "Điều đã cố ý không đặc tả") |
| Màn import (màn 11), màn export (màn 12), chọn file, file tạm, share sheet | FE-B3 ([`wbs_FE.md`](../../wbs_FE.md)) |
| Chuẩn hoá Unicode của text nhập vào | Quyết định chung cho cả ứng dụng, BE-C5 ([`wbs_BE.md`](../../wbs_BE.md)); import giữ nguyên code point (spec gói 9a D17) |
```

In `docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md`:

Replace

```markdown
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006, BR-TRANSFER-009]
code: []
---
```

with

```markdown
rules: [BR-CARD-001, BR-CARD-002, BR-CARD-003, BR-CARD-004, BR-DECK-004, BR-DECK-008, BR-DECK-010, BR-TAG-001, BR-TAG-002, BR-TRANSFER-001, BR-TRANSFER-002, BR-TRANSFER-003, BR-TRANSFER-004, BR-TRANSFER-005, BR-TRANSFER-006, BR-TRANSFER-009]
code: [lib/features/transfer/domain/usecases/read_import_source_use_case.dart, lib/features/transfer/domain/usecases/preview_import_use_case.dart, lib/features/transfer/domain/usecases/import_cards_use_case.dart, lib/features/card/domain/repositories/card_repository.dart]
---
```

Replace

```markdown

**Phạm vi:** sub-project sau — Import (spec §2).

```

with

```markdown

**Phạm vi:** Card Transfer, phần store (BE-B3): CSV, TSV và văn bản dán ở gói 9a, XLSX
ở gói 9b. Màn import (màn 11) thuộc FE-B3.

```

Replace

```markdown
   ba bước Source → Preview → Import.
2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV.
3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-TRANSFER-006) — không
```

with

```markdown
   ba bước Source → Preview → Import.
2. Người dùng chọn nguồn: một file CSV/TSV/XLSX, hoặc dán văn bản CSV/TSV. File CSV
   phân cách bằng `,`, hoặc bằng `;` khi hàng không trống đầu tiên, tính phần nằm ngoài
   dấu nháy kép, có `;` mà không có `,` — cách Excel lưu CSV ở locale dùng dấu phẩy thập
   phân.
3. Người dùng bấm Preview; hệ thống parse nguồn trong bộ nhớ (BR-TRANSFER-006) — không
```

Replace

```markdown
- **A1 — Dán văn bản:** ở bước Source người dùng dán các hàng CSV/TSV vào ô
  nhập; parse chỉ chạy khi bấm Preview, và văn bản giữ nguyên khi parse lỗi.
- **A2 — XLSX nhiều sheet:** hệ thống mặc định chọn sheet không rỗng đầu tiên
```

with

```markdown
- **A1 — Dán văn bản:** ở bước Source người dùng dán các hàng CSV/TSV vào ô
  nhập; parse chỉ chạy khi bấm Preview, và văn bản giữ nguyên khi parse lỗi. Văn bản là
  TSV khi hàng không trống đầu tiên có tab nằm ngoài dấu nháy kép; nếu không, nó được
  đọc như một file CSV, kể cả phân cách `;` của bước 2.
- **A2 — XLSX nhiều sheet:** hệ thống mặc định chọn sheet không rỗng đầu tiên
```

In `docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md`:

Replace

```markdown
rules: [BR-CARD-012, BR-DECK-015, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-TAG-001, BR-TAG-002, BR-TRANSFER-007, BR-TRANSFER-008, BR-TRANSFER-009, BR-TRANSFER-010, BR-TRANSFER-011, BR-TRANSFER-012, BR-TRANSFER-013, BR-TRANSFER-014]
code: []
---
```

with

```markdown
rules: [BR-CARD-012, BR-DECK-015, BR-CORE-001, BR-CORE-002, BR-CORE-004, BR-TAG-001, BR-TAG-002, BR-TRANSFER-007, BR-TRANSFER-008, BR-TRANSFER-009, BR-TRANSFER-010, BR-TRANSFER-011, BR-TRANSFER-012, BR-TRANSFER-013, BR-TRANSFER-014]
code: [lib/features/transfer/domain/usecases/export_cards_use_case.dart]
---
```

Replace

```markdown

**Phạm vi:** sub-project sau — Export (spec §2).

```

with

```markdown

**Phạm vi:** Card Transfer, phần store (BE-B3): CSV và TSV ở gói 9a, XLSX ở gói 9b. Màn
export (màn 12), file trong vùng riêng của ứng dụng và share sheet thuộc FE-B3.

```

In `docs/wbs_BE.md`:

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | chưa bắt đầu | BE-04, BE-05 | M–L | Nice-to-have N1 trong [`docs/README.md`](README.md): import CSV/TSV/XLSX, export nội dung | Tuân thủ BR-CORE-001, BR-CORE-002, BR-CORE-004 |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | chưa bắt đầu | BE-03, BE-04 | M | Cột `source_template_id` và `source_template_version` đã có trong `deck` | — |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | đang làm | BE-04, BE-05 | M–L | Gói 9a xong: import và export CSV, TSV, văn bản dán ([spec](superpowers/specs/2026-09-26-transfer-backend-design.md) và [plan](superpowers/plans/2026-09-26-transfer-backend.md) gói 9a); test trong `test/features/transfer/` và `test/features/card/data/card_create_batch_test.dart` | Gói 9b: XLSX, đọc và ghi (`archive` + `xml`), cùng `encodeFailed` và `passwordProtected`, theo spec riêng |
| BE-B4 | Starter decks: thư viện template, sao chép template vào dữ liệu người dùng (UC-STARTER-001; BR-STARTER-001…BR-STARTER-010) | chưa bắt đầu | BE-03, BE-04 | M | Cột `source_template_id` và `source_template_version` đã có trong `deck` | — |
```

Replace

```markdown
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |

```

with

```markdown
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
| BE-C5 | Chuẩn hoá Unicode (NFC) cho text trên toàn ứng dụng. Cùng một chữ có thể đến ở dạng dựng sẵn hoặc dạng tổ hợp (ví dụ `é` và `e` + U+0301), và `foldText` chỉ trim và hạ chữ thường, nên kiểm trùng (BR-TRANSFER-003), tên tag (BR-TAG-001) và tìm kiếm coi hai dạng là hai chuỗi khác nhau | bị chặn | — | S–M | D17 của [spec gói 9a](superpowers/specs/2026-09-26-transfer-backend-design.md): import giữ nguyên code point, vì chỉ chuẩn hoá import thì vẫn lệch với editor | Chủ dự án quyết có chuẩn hoá ở mọi đường ghi text và ở phép fold hay không; Dart không có sẵn chuẩn hoá Unicode (xem Điểm chặn) |

```

Replace

```markdown
  task, final review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

with

```markdown
  task, final review toàn nhánh trước khi mở PR.
- **BE-B3, gói 9a** (CSV, TSV, văn bản dán;
  [spec](superpowers/specs/2026-09-26-transfer-backend-design.md),
  [plan](superpowers/plans/2026-09-26-transfer-backend.md)): gate xanh sau mỗi task, final review
  toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

Replace

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 18/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRASH-001).
  4 UC còn lại chưa có code.

```

with

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 20/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRANSFER-001, UC-TRANSFER-002, UC-TRASH-001).
  2 UC còn lại chưa có code: UC-REMINDER-001, UC-STARTER-001.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 8 (BE-B2).

```

with

```markdown

BE-B3: gói 9a (CSV, TSV, văn bản dán) xong; gói 9b (XLSX) là bước tiếp theo, theo spec
riêng.

```

Replace

```markdown
| BE-B5 | BR-SETTINGS-008 ghi `Reset to defaults` đưa toàn bộ giá trị của `app_settings` về mặc định; BE-A1 (spec D6) chỉ đưa về mặc định bốn giá trị người dùng đặt được ở V8.0, chưa đụng `reminder_enabled`, `reminder_minute_of_day` | `Reset to defaults` khi nhắc học đã có giao diện | Quyết trong spec của BE-B5; sửa câu chữ BR-SETTINGS-008 cần chủ dự án cho phép |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | Cả 22 UC | Chủ dự án nêu phạm vi file được sửa |
```

with

```markdown
| BE-B5 | BR-SETTINGS-008 ghi `Reset to defaults` đưa toàn bộ giá trị của `app_settings` về mặc định; BE-A1 (spec D6) chỉ đưa về mặc định bốn giá trị người dùng đặt được ở V8.0, chưa đụng `reminder_enabled`, `reminder_minute_of_day` | `Reset to defaults` khi nhắc học đã có giao diện | Quyết trong spec của BE-B5; sửa câu chữ BR-SETTINGS-008 cần chủ dự án cho phép |
| BE-C5 | Chưa chốt có chuẩn hoá Unicode (NFC) hay không, và nếu có thì bằng dependency nào | Kiểm trùng khi import, tên tag, tìm kiếm | Chủ dự án quyết; đổi phép fold là đổi dữ liệu đã lưu (`front_folded`, `back_folded`, `name_folded`), cần migration |
| BE-D4 | Sửa UC `ready` là sửa hợp đồng ([`docs/README.md`](README.md), mục "Hợp đồng và phạm vi sửa") | Cả 22 UC | Chủ dự án nêu phạm vi file được sửa |
```

Replace

```markdown
- **Gate:** kết quả ở mục "Đã xong và đã kiểm chứng" là của cây `f28bdfd`. Gate hiện
  hành là `dod_check.sh` trong [`README.md` gốc](../README.md). CI chạy nó trên mỗi pull
  request, cùng job `goldens`, và `CI gate` phải xanh trước khi merge (BE-D2).
- **Kịch bản IT:** [host-coverage-map.md](shared/testing/host-coverage-map.md) có 141
```

with

```markdown
- **Gate:** kết quả ở mục "Đã xong và đã kiểm chứng" là của cây `f28bdfd`. Gate hiện
  hành là `dod_check.sh` trong [`README.md` gốc](../README.md). CI (BE-D2) chạy nó cùng
  job `goldens`, nhưng tạm dừng trên pull request từ 2026-09-26 (#67): CI chỉ chạy khi
  bấm tay, và pull request merge theo gate cục bộ.
- **Kịch bản IT:** [host-coverage-map.md](shared/testing/host-coverage-map.md) có 141
```

Replace

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 63 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-NAV (2), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

with

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 66 ID: IT-CARD (2), IT-CONT (12), IT-DISC (5), IT-LEARN (10), IT-MODE (12), IT-NAV (2), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

Replace

```markdown

1. BE-B3…BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của chúng đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.
```

with

```markdown

1. Gói 9b của BE-B3 (XLSX), rồi BE-B4 và BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của
   chúng đọc `card` hoặc `deck` sẽ gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
2. BE-D5 khi thuận tiện; không hạng mục nào chờ nó.
```

Replace

```markdown
  gộp, xoá tag, lọc card list theo tag; không đổi schema.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  gộp, xoá tag, lọc card list theo tag; không đổi schema.
- **Cập nhật ngày 2026-09-26:** gói 9a của BE-B3 xong: import (đọc nguồn, xem trước,
  ghi trong một transaction) và export, cho CSV, TSV và văn bản dán. Bước 2 và A1 của
  UC-TRANSFER-001 ghi thêm phân cách `;` (chủ dự án cho phép ngày 2026-09-26). Thêm BE-C5
  cho quyết định chuẩn hoá Unicode. Sửa dòng CI theo #67, và đếm lại ID kịch bản IT
  trong test: #68 thêm IT-DISC-007, gói 9a thêm IT-CARD-014 và IT-CARD-015.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
```

with

```markdown
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | BE-B3 gói 9a xong (CSV, TSV, văn bản dán): hợp đồng cho UI ở §9 của [spec gói 9a](superpowers/specs/2026-09-26-transfer-backend-design.md); [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Màn 11 và 12 trên 4 use case của `transfer`; XLSX chờ gói 9b. Ghi lệch với kit: tự map cột chỉ theo sáu tên chuẩn, không theo từ đồng nghĩa (spec D7); cho chọn sheet theo UC-TRANSFER-001 A2, kit chỉ đọc sheet đầu; tên file giữ cách viết của tên deck, không phải slug (spec D15); nhận CSV phân cách `;` (spec D5). Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
| FE-B4 | Thư viện starter: child flow trong Thư viện, kèm empty state khi chưa có deck (UC-STARTER-001) | chưa bắt đầu | BE-B4, FE-A1 | M | [ui.md](features/starter-decks/ui.md) | Sau BE-B4 |
```

Replace

```markdown
- **Gate:** `dod_check.sh` ([`README.md` gốc](../README.md)). CI chạy nó cùng goldens
  trên mỗi pull request, và `CI gate` phải xanh trước khi merge (BE-D2 trong
  [`wbs_BE.md`](wbs_BE.md)).

```

with

```markdown
- **Gate:** `dod_check.sh` ([`README.md` gốc](../README.md)). CI chạy nó cùng goldens
  (BE-D2 trong [`wbs_BE.md`](wbs_BE.md)), nhưng tạm dừng trên pull request từ 2026-09-26
  (#67): CI chỉ chạy khi bấm tay, và pull request merge theo gate cục bộ.

```

Replace

```markdown
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1 và BE-B2 xong
   trong gói 7 và gói 8, nên FE-B1 và FE-B2 không còn chờ backend; BE-B3…BE-B5 chưa bắt
   đầu.

```

with

```markdown
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1 và BE-B2 xong
   trong gói 7 và gói 8, nên FE-B1 và FE-B2 không còn chờ backend. BE-B3 đang làm: gói 9a
   xong CSV, TSV và văn bản dán, nên FE-B3 dựng được trên chúng; XLSX ở gói 9b. BE-B4,
   BE-B5 chưa bắt đầu.

```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 49 warning(s)`.

- [ ] **Step 2: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/transfer/README.md \
  docs/features/transfer/usecases/UC-TRANSFER-001-import-card-hang-loat-vao-deck.md \
  docs/features/transfer/usecases/UC-TRANSFER-002-export-card-cua-deck-ra-file.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 3: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 49 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1673: All tests passed!`.

- [ ] **Step 4: Commit**

```bash
git commit -F - <<'EOF'
docs(transfer): package 9a docs: use cases, README, both WBS

UC-TRANSFER-001 and UC-TRANSFER-002 name their use cases and scope;
steps 2 and A1 of UC-TRANSFER-001 say a CSV may be separated by ";"
(the owner's permission of 2026-09-26). The transfer README gets its
code paths, one scope line and a summary; the stale open question goes.
wbs_BE.md: BE-B3 in progress (9a done, 9b next), BE-C5 for the NFC
decision, the CI lines after #67, the IT id count. wbs_FE.md: FE-B3
points at spec §9 and records the kit deviations. docs/_generated.
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-transfer` and open its pull request against `master`, then subscribe
to its activity.

Expected: CI is paused during active development (root `README.md`, "CI"), so no
check runs on the pull request; it merges on the local gate.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-transfer` if it moved, run the gate once more on the
branch head, and squash-merge only while it ends with `✓ mechanical gates passed`.
Then unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** §5 reading a source, D4–D6: Task 4. §6 mapping, classification
  and the tag cell, D7–D9: Task 2. §7 the commit and the batch create, D11, D12, D20:
  Tasks 1 and 3. §8 export, D13–D16: Task 5. §9 the four use cases: Tasks 3–5. §10
  tests: every line has its test in Tasks 1–5; the file order after export is pinned by
  Task 5's round trip, which imports a file as one batch and exports it again. §10's
  Review Focus: Tasks 2–5. §11 documents: Task 6. D17: Clarification 8.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run
  compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the task that owns the
  code.
