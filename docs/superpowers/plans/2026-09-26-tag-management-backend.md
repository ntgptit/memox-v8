# MemoX V8 Tag Management Backend Implementation Plan (package 8)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-B2 of [`docs/wbs_BE.md`](../../wbs_BE.md) with BE-C4, the store side
of Tag Management (UC-TAG-001; BR-TAG-003…BR-TAG-011), as domain, data and use-case
code in `tags` and the card list's tag filter in `card`, so FE-B2 can build screen 05
and the card list's `Tags` filter on use cases alone.

**Architecture:** No schema change: the two tables, their keys, their index and
their cascades exist. `TagRepository` grows four methods over them:
`watchTagCounts` reads every tag with the active cards carrying it, in the library
or in one deck, in one statement per emission; `planRename` says before anything is
written whether a rename changes nothing, renames in place, or merges into the tag
that folds alike, with the counts; `renameTag` runs the same checks in its own
transaction and merges only into the tag the caller confirmed, by `INSERT OR IGNORE`
of the source's links then a delete of its row whose links go by cascade;
`deleteTag` deletes the row, its links by cascade. `tags` gains its first use cases,
five. In `card`, `CardListQuery.tagIds` adds one `EXISTS` term to the predicate the
window, Select all and the filter counts share.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `drift` 2.35, `flutter_riverpod` 3. No
dependency is added; the only generated output a task needs is the localizations.

**Spec:**
[`docs/superpowers/specs/2026-09-26-tag-management-backend-design.md`](../specs/2026-09-26-tag-management-backend-design.md),
approved 2026-09-26. Business rules: `docs/features/tags/rules/`
(BR-TAG-001…BR-TAG-011); use case:
`docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md`; data
model: [`shared/data/schema.md`](../../shared/data/schema.md), `tags` and
`card_tags`.

**Prerequisite:** `claude/be-tags` holds the spec (`7153112`), its approval
(`ea1a9bf`) and this plan, on `master` at `2ca85f2` (#69). The plan runs on that
branch, from this plan's commit; the gate passes there with 1561 tests. Generated
code is not committed: in a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`
first (root `README.md`, "Commands").

**How this plan was checked:** every code block below was written and run first, in
a scratch copy of the repository, task by task, test first. Each task's tests failed
as its "Expected" line says, then passed, and after every task the gate passed. Each
rule the tests pin was also broken on purpose in the scratch copy, one at a time:
the counts with cards in the Trash; a deck's counts over the library; another
profile's tags listed; the catalog by stored name; the search through `LIKE`; the
search term unfolded; the counts deaf to the cards; a merge without the
confirmation; the source's own row taken for a clash; an unchanged name written; a
merge that deletes the source before it copies the links; a merge without
`OR IGNORE`; the plan's counts with cards in the Trash; the union counted twice;
another profile's tag found by id; the source looked up before the name is checked;
a rename that keeps the spaces; the writes outside a transaction; a delete of a tag
that is gone or not the profile's; a delete that tells no stream; the filter not
tied to its card; the counts without the tags; the list and Select all without the
tags; no selected tag taken for no card; and the tags left out of the counts by the
repository. That is 25 breaks. Every break failed a test. Two of them first passed,
and their tests were fixed before this plan was written: a count stream deaf to
`card` hid behind fixtures whose updates did not name their kind (Clarification 10),
and an empty selection taken for no card passed an identity test that compared the
empty set with itself (Task 4). This document was then applied, step by step as
written, onto a clean checkout of this plan's commit: each task's files matched the
scratch commit's, no other file moved, and the outputs and counts below are that
run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only, but for what the contract forces: `mergeNotConfirmed`'s case in
  `tag_rejection_message_widget.dart` and its strings in `app_en.arb` and
  `app_vi.arb` (spec D11). No screen, no provider for a new use case, no other copy:
  screen 05, the filter overlay and the Library's `Tags` action are FE-B2's (§12).
- No schema change and no migration: `schemaVersion` stays 3 (D1).
- `tags` imports no feature, and its tests none either; `card` may import `tags`
  (ADR-011; spec §2). The import map does not change.
- Every read and write keeps to the local profile, `owner_id IS NULL` (D13).
- One fold for names and search terms: `TagEntity.fold`, which is `foldText`, trim
  then `toLowerCase()`; it keeps diacritics (BR-TAG-011, BR-SEARCH-002). A search
  matches with `instr(name_folded, fold(term))`, never `LIKE` (D4).
- The counts are of active cards, `c.delete_batch_id IS NULL`; the catalog is
  ordered by `name_folded`, then `id` (BR-TAG-003, BR-TAG-010; §5).
- A rename is planned, then written behind the guard; the write runs every check
  before its first write, in the plan's order, and a refusal writes nothing (§6, D5).
  A merge copies the source's links onto the target with `INSERT OR IGNORE`, trashed
  cards included, then deletes the source's row; the target's row is not written
  (D7).
- Rename, merge and delete write `tags` and `card_tags` and nothing else
  (BR-TAG-009).
- The tag filter is an `EXISTS` on `card_tags` inside `CardListDao._predicate` and in
  the filter counts; the status counts and the workload stay the deck's (BR-TAG-004,
  D10).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing `call`
  (AD-12).
- After every task the gate of the root `README.md` passes:
  `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`. It runs the host
  suite with `TZ=UTC` and `--exclude-tags golden`. Its generated-code check asks
  every source under `lib/` to be in git, so each task stages its files, runs the
  gate, then commits.
- The guard fails a hand-written file at 400 logical lines
  (`common.no_large_source_file`); `card_repository_impl.dart`, near it since package
  7, gains one line here.
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a rule or use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- The contract documents change only as spec §11 says: UC-TAG-001's `code:`, its
  scope line and its step 3 example (D4), the scope lines of the tags README,
  `schema.md` and `tags.drift`, and both WBS; `schema.md`'s line on the second index
  of `card_tags` is corrected with them (Clarification 9).
- Code, identifiers, test names and commit messages are in English; `docs/` keeps
  its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan. Each is
decided here and implemented as described; say so if one is wrong.

1. **The deck scope counts the deck's own cards** (Task 1; spec D3). A `deckId`
   counts the cards whose `deck_id` is that deck, not its subtree: the filter
   overlay belongs to a card list, and a card list shows one deck's cards.
2. **A blank search, spaces included, lists every tag** (Task 1; spec §9). A term
   of spaces folds to the empty string, and `instr` finds it in every name. FE-B2
   tells `empty` from `searchEmpty` by its own term.
3. **`findById` keeps to the local profile** (Task 2; spec D13). `TagDao.findById`
   gains `owner_id IS NULL`, so another profile's tag is `notFound` to a plan, a
   rename and a delete; `detach` inherits it. No V8.0 row has another owner.
4. **The write runs the plan's checks again, counts included** (Task 2; spec §6).
   `renameTag` calls the same private `_planRename` in its own transaction, so its
   checks are the plan's in the plan's order; a merge's two counts are read again,
   two small statements on `idx_card_tags_tag`.
5. **The merge and the delete share one statement** (Tasks 2 and 3). `TagDao.deleteTag`
   is written in Task 2 for the merge's second statement and serves Task 3's delete.
   It names `tags` with `UpdateKind.delete`: drift's generated update rule for the
   key of `card_tags` carries that delete to the watchers of `card_tags`, so every
   stream that reads the links hears the cascade.
6. **BR-TAG-009's snapshot is every other table** (Tasks 2 and 3; spec §10). The
   snapshot reads every table but `tags` and `card_tags`, row by row: `card`, `deck`,
   `card_schedule`, `review_log`, the study tables, `delete_batches` and
   `app_settings`. `insertStudiedCard` gives it a card with a schedule row, a review
   log row and a queue place in an open session.
7. **The forced failure** (Tasks 2 and 3; UC-TAG-001 E4, E5). `FailingTagDelete`
   fails the statement that deletes a `tags` row, the way a full disk does. In a merge
   it runs after the `INSERT OR IGNORE`, so the rollback test shows the copied links
   go back; for a delete it is the only statement.
8. **`mergeNotConfirmed`'s copy** (Task 2; spec D11). English: "Another tag now has
   this name. Check the merge and confirm again." Vietnamese: "Một nhãn khác vừa có
   tên này. Hãy xem lại việc gộp rồi xác nhận lại." FE-B2 aligns it with the kit when
   it draws the dialog.
9. **Which key each tag read walks** (Tasks 4 and 5; spec §13). drift renders the
   filter as `EXISTS (SELECT … FROM card_tags WHERE card_tags.card_id = card.id AND
   card_tags.tag_id IN (…))`, which SQLite answers from the key `(card_id, tag_id)`;
   the catalog's count, the merge's copy and the plan's counts walk
   `idx_card_tags_tag (tag_id, card_id)`. `schema.md` said the filter asks "every card
   carrying this tag" of the second index; Task 5 says which read uses which.
10. **The tests of `tags` write raw rows** (Tasks 1–3). `tag_fixtures.dart` writes
    decks, cards, tags, links and Trash marks as SQL, naming the tables each write
    touches so a watching stream hears it, and an update names its kind,
    `UpdateKind.update`, as the app's writes do: drift takes a write of unknown kind
    on `card` for a possible delete and tells every table whose key cascades from it,
    `card_tags` among them, which would hide a count stream deaf to `card`. The
    snapshot's studied card comes from `srs_fixtures.dart`'s `insertStudyTree`, SQL
    too.
11. **The plan's date.** The plan is written on 2026-09-26, the spec's day.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a person,
each pinned by a test in the task that owns the code:

1. **A card in the Trash carries both tags of a merge, then comes back**: it carries
   the target, once — Task 2, "a confirmed merge moves the links of active and
   trashed cards to the target, once per card, deletes the source and leaves the
   target as it was; a trashed card that carried both comes back carrying the target
   once".
2. **A rename that changes case only, and one that changes a diacritic**: the first
   keeps the tag's identity, the second is a new name — Task 2, "a case-only change
   renames the tag in place: same id, same links" and "a diacritic makes a new name:
   hoc renamed Học folds to học".
3. **The plan said rename, and the card editor made a tag with that folded name
   before the write**: `mergeNotConfirmed`, nothing written — Task 2, "the plan said
   rename, then the card editor made a tag with that name: the write is
   mergeNotConfirmed and writes nothing".
4. **A tag whose only cards are in the Trash (count 0) is deleted**: those links go,
   and a restored card comes back without it — Task 3, "a tag whose only card is in
   the Trash counts 0 and deletes like any other: the card comes back without it".
5. **The card list is filtered by a tag that is then merged away**: it matches
   nothing, and the overlay's list no longer offers it — Task 4, "a list filtered by
   a tag that is merged away matches nothing, and the deck's tag list no longer
   offers it".

## File Structure

```
lib/features/tags/
├── domain/
│   ├── failures/tag_failure.dart            mergeNotConfirmed (2)
│   ├── models/tag_count_model.dart          TagCount (1)
│   ├── models/tag_rename_plan_model.dart    TagRenamePlan and its three cases (2)
│   ├── repositories/tag_repository.dart     watchTagCounts (1); planRename,
│   │                                        renameTag (2); deleteTag (3)
│   └── usecases/                            the first of tags: watch_tag_catalog,
│                                            watch_deck_tag_counts (1); plan_tag_rename,
│                                            rename_tag (2); delete_tag (3)
└── data/
    ├── datasources/tag_dao.dart             countRows, countChanges (1); findById
    │                                        local, activeCardCount, rename, merge,
    │                                        deleteTag (2)
    └── repositories/tag_repository_impl.dart   (1, 2, 3)

lib/features/card/
├── domain/models/card_list_query_model.dart tagIds (4)
├── domain/models/card_list_view_model.dart, domain/repositories/card_repository.dart
│                                            what the counts follow (4)
├── data/datasources/card_list_dao.dart      _tagged in _predicate and the counts (4)
├── data/repositories/card_repository_impl.dart   passes tagIds to the counts (4)
└── presentation/widgets/support/tag_rejection_message_widget.dart   one case (2)

lib/l10n/app_en.arb, app_vi.arb              tagRejectionMergeNotConfirmed (2)
lib/core/database/tables/tags.drift          the scope comment (5)

test/support/tag_fixtures.dart               insertTagDecks, insertTagCard, insertTag,
                                             setCardBatch, setCardDeck (1); insertStudiedCard,
                                             rowsOutsideTags, tagRowsOf, linksOf,
                                             FailingTagDelete (2)
test/features/tags/data/                     tag_counts_test (1), tag_rename_test (2),
                                             tag_delete_test (3)
test/features/tags/domain/tag_management_use_cases_test.dart   (1, 2, 3)
test/features/card/data/card_list_tag_filter_test.dart         (4)
```

Other changed files: `docs/_generated/` where a task's tests name a new id (Tasks
1–4), and in Task 5 UC-TAG-001, the tags README, `schema.md`, `wbs_BE.md` and
`wbs_FE.md`.

---


### Task 1: Tag counts for the catalog and for a deck, and their two use cases

**Files:**
- Create: `lib/features/tags/domain/models/tag_count_model.dart`, `lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart`, `lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart`
- Modify: `lib/features/tags/data/datasources/tag_dao.dart`, `lib/features/tags/data/repositories/tag_repository_impl.dart`, `lib/features/tags/domain/repositories/tag_repository.dart`
- Test (create): `test/features/tags/data/tag_counts_test.dart`, `test/features/tags/domain/tag_management_use_cases_test.dart`, `test/support/tag_fixtures.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `TagEntity.fold`; `tableChanges` (`lib/core/database/table_changes.dart`);
  `mapDatabaseErrors` (`lib/core/error/failure.dart`); `insertDeleteBatch` of
  `test/support/trash_fixtures.dart`.
- Produces:
  - `final class TagCount({required String id, required String name, required int cardCount})`
    (`tags/domain/models/tag_count_model.dart`).
  - `Stream<List<TagCount>> TagRepository.watchTagCounts({String? deckId, String searchTerm = ''})`.
  - In `TagDao`: `Future<List<QueryRow>> countRows({String? deckId, required String foldedTerm})`
    (columns `id`, `name`, `card_count`) and `Stream<void> countChanges()`.
  - `WatchTagCatalogUseCase(TagRepository)` with
    `Stream<List<TagCount>> call({String searchTerm = ''})`, and
    `WatchDeckTagCountsUseCase(TagRepository)` with
    `Stream<List<TagCount>> call({required String deckId})`.
  - In `test/support/tag_fixtures.dart`: `Future<void> insertTagDecks(AppDatabase db)`
    (a root `r`, card sub-decks `leaf` and `other`),
    `Future<void> insertTagCard(AppDatabase db, String id, {String deckId = 'leaf'})`,
    `Future<void> insertTag(AppDatabase db, String id, String name, {List<String> cardIds = const [], String? ownerId})`,
    `Future<void> setCardBatch(AppDatabase db, String cardId, String? batchId)` and
    `Future<void> setCardDeck(AppDatabase db, String cardId, String deckId)`.

Spec §5, D3, D4, D13; Clarifications 1, 2 and 10. One statement per emission,
re-read after every write to the tags, their links or the cards. The tests write
their rows as SQL through `tag_fixtures.dart`: `tags` imports no feature.

- [ ] **Step 1: Write the failing tests**

Create `test/support/tag_fixtures.dart`:

```dart
import 'package:drift/drift.dart' show UpdateKind, Variable;
import 'package:memox/core/database/app_database.dart';

import 'trash_fixtures.dart';

// Raw rows for the tests of `tags`, which imports no feature (ADR-011), so
// its tests do not either. Every write names the tables it touches and, for
// an update, its kind, as the app's writes do: drift takes a write of unknown
// kind for a possible delete and tells every table whose key cascades from
// it, so a stream deaf to `card` would still hear a card move.

/// A root `r` with the card sub-decks `leaf` and `other`.
Future<void> insertTagDecks(AppDatabase db) async {
  await db.customStatement(
    'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, '
    'scheduler_version, generation, sibling_position, created_at, updated_at) '
    "VALUES ('r', 'r', NULL, 'r', 1, 'deck', 'eight_box', 1, 1, 0, 0, 0)",
  );
  for (final (index, id) in ['leaf', 'other'].indexed) {
    await db.customStatement(
      'INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, '
      'sibling_position, created_at, updated_at) '
      "VALUES (?, ?, 'r', 'r', 2, 'card', ?, 0, 0)",
      [id, id, index],
    );
  }
}

/// An active card in [deckId].
Future<void> insertTagCard(
  AppDatabase db,
  String id, {
  String deckId = 'leaf',
}) => db.customInsert(
  'INSERT INTO card (id, deck_id, front, back, created_at, updated_at) '
  "VALUES (?, ?, 'f', 'b', 0, 0)",
  variables: [Variable<String>(id), Variable<String>(deckId)],
  updates: {db.card},
);

/// The tag [name], folded as BR-TAG-001 folds it, carried by [cardIds].
Future<void> insertTag(
  AppDatabase db,
  String id,
  String name, {
  List<String> cardIds = const [],
  String? ownerId,
}) async {
  await db.customInsert(
    'INSERT INTO tags (id, name, name_folded, owner_id, created_at) '
    'VALUES (?, ?, ?, ?, 0)',
    variables: [
      Variable<String>(id),
      Variable<String>(name),
      Variable<String>(name.trim().toLowerCase()),
      Variable<String>(ownerId),
    ],
    updates: {db.tags},
  );
  for (final cardId in cardIds) {
    await db.customInsert(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      variables: [Variable<String>(cardId), Variable<String>(id)],
      updates: {db.cardTags},
    );
  }
}

/// [cardId] into the Trash as the batch [batchId], or back from it when
/// [batchId] is null.
Future<void> setCardBatch(
  AppDatabase db,
  String cardId,
  String? batchId,
) async {
  if (batchId != null) {
    await insertDeleteBatch(db, batchId, itemType: 'card', rootItemId: cardId);
  }
  await db.customUpdate(
    'UPDATE card SET delete_batch_id = ? WHERE id = ?',
    variables: [Variable<String>(batchId), Variable<String>(cardId)],
    updates: {db.card},
    updateKind: UpdateKind.update,
  );
}

/// [cardId] moved to [deckId], as a card move writes it.
Future<void> setCardDeck(AppDatabase db, String cardId, String deckId) =>
    db.customUpdate(
      'UPDATE card SET deck_id = ? WHERE id = ?',
      variables: [Variable<String>(deckId), Variable<String>(cardId)],
      updates: {db.card},
      updateKind: UpdateKind.update,
    );
```

Create `test/features/tags/data/tag_counts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 steps 1-3 and 6: every tag of the library with the active cards
// carrying it, in the library or in one deck (BR-TAG-003, BR-TAG-010; tag
// management spec §5).

List<(String, int)> _rows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;

  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 26));
    await insertTagDecks(db);
  });
  tearDown(() => db.close());

  Future<List<(String, int)>> catalog([String searchTerm = '']) async =>
      _rows(await tags.watchTagCounts(searchTerm: searchTerm).first);

  test('the catalog lists every tag by its folded name, each with its active '
      'cards, one with none at 0 (UC-TAG-001 step 1, BR-TAG-003)', () async {
    for (final id in ['c1', 'c2', 'c3']) {
      await insertTagCard(db, id);
    }
    await insertTag(db, 't1', 'TOPIK I', cardIds: ['c1', 'c2']);
    await insertTag(db, 't2', 'bài 12', cardIds: ['c3']);
    await insertTag(db, 't3', 'động từ', cardIds: ['c1']);
    await insertTag(db, 't4', 'tạm');

    // By `name_folded`, code point by code point: `topik i` before `tạm`,
    // and `đ` after every ASCII letter. By the stored name `TOPIK I` would
    // come first.
    expect(await catalog(), [
      ('bài 12', 1),
      ('TOPIK I', 2),
      ('tạm', 0),
      ('động từ', 1),
    ]);
  });

  test('a card in the Trash counts for no tag, and counts again once it is '
      'back (BR-TAG-010)', () async {
    await insertTagCard(db, 'c1');
    await insertTagCard(db, 'c2');
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2']);
    final seen = <List<(String, int)>>[];
    final subscription = tags.watchTagCounts().listen(
      (counts) => seen.add(_rows(counts)),
    );
    await pumpEventQueue();
    expect(seen.last, [('noun', 2)]);

    await setCardBatch(db, 'c1', 'b1');
    await pumpEventQueue();
    expect(seen.last, [('noun', 1)]);

    await setCardBatch(db, 'c1', null);
    await pumpEventQueue();
    expect(seen.last, [('noun', 2)]);
    await subscription.cancel();
  });

  test('the search keeps the tags whose folded name holds the folded term: '
      'ĐỘNG TỪ finds động từ, dong tu finds nothing, a blank term finds every '
      'tag (UC-TAG-001 step 3, BR-TAG-003, BR-TAG-011)', () async {
    await insertTag(db, 't1', 'động từ');
    await insertTag(db, 't2', 'danh từ');

    expect(await catalog('ĐỘNG TỪ'), [('động từ', 0)]);
    expect(await catalog('  từ '), [('danh từ', 0), ('động từ', 0)]);
    expect(await catalog('dong tu'), isEmpty);
    expect(await catalog('   '), [('danh từ', 0), ('động từ', 0)]);
  });

  test('% and _ in a search term are plain characters (BR-TAG-003)', () async {
    await insertTag(db, 't1', '100%');
    await insertTag(db, 't2', '1000');
    await insertTag(db, 't3', 'a_b');
    await insertTag(db, 't4', 'axb');

    expect(await catalog('%'), [('100%', 0)]);
    expect(await catalog('_'), [('a_b', 0)]);
  });

  test("in a deck every tag is listed, each with that deck's active cards, "
      '0 included (UC-TAG-001 step 6; tag management spec D3)', () async {
    await insertTagCard(db, 'c1');
    await insertTagCard(db, 'c2', deckId: 'other');
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2']);
    await insertTag(db, 't2', 'verb', cardIds: ['c2']);

    Future<List<(String, int)>> inDeck(String deckId) async =>
        _rows(await tags.watchTagCounts(deckId: deckId).first);

    expect(await inDeck('leaf'), [('noun', 1), ('verb', 0)]);
    expect(await inDeck('other'), [('noun', 1), ('verb', 1)]);
  });

  test(
    'a tag of another profile is not listed (tag management spec D13)',
    () async {
      await insertTag(db, 't1', 'mine');
      await insertTag(db, 't2', 'theirs', ownerId: 'someone');

      expect(await catalog(), [('mine', 0)]);
    },
  );

  test('the counts of a deck follow the tags, their links and the cards: a '
      'new tag, then a card moved out (BR-TAG-003)', () async {
    await insertTagCard(db, 'c1');
    final seen = <List<(String, int)>>[];
    final subscription = tags
        .watchTagCounts(deckId: 'leaf')
        .listen((counts) => seen.add(_rows(counts)));
    await pumpEventQueue();
    expect(seen.last, isEmpty);

    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await pumpEventQueue();
    expect(seen.last, [('noun', 1)]);

    await setCardDeck(db, 'c1', 'other');
    await pumpEventQueue();
    expect(seen.last, [('noun', 0)]);
    await subscription.cancel();
  });
}
```

Create `test/features/tags/domain/tag_management_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart';
import 'package:memox/features/tags/domain/usecases/watch_tag_catalog_use_case.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001: the use cases of Tag Management hand their arguments to the
// repository unchanged (tag management spec §9).

List<(String, int)> _rows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;

  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 26));
    await insertTagDecks(db);
    await insertTagCard(db, 'c1');
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await insertTag(db, 't2', 'verb');
  });
  tearDown(() => db.close());

  test('WatchTagCatalogUseCase reads the library under the search '
      '(UC-TAG-001 steps 1-3)', () async {
    final watch = WatchTagCatalogUseCase(tags);

    expect(_rows(await watch().first), [('noun', 1), ('verb', 0)]);
    expect(_rows(await watch(searchTerm: 'NO').first), [('noun', 1)]);
  });

  test('WatchDeckTagCountsUseCase reads every tag in one deck '
      '(UC-TAG-001 step 6)', () async {
    final watch = WatchDeckTagCountsUseCase(tags);

    expect(_rows(await watch(deckId: 'other').first), [
      ('noun', 0),
      ('verb', 0),
    ]);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/tags/data/tag_counts_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/tags/domain/models/tag_count_model.dart': No such file or directory`,
`Error: The method 'watchTagCounts' isn't defined for the type 'TagRepositoryImpl'.`,
`Error: Method not found: 'WatchTagCatalogUseCase'.` and
`Error: Method not found: 'WatchDeckTagCountsUseCase'.`

- [ ] **Step 3: Count the tags of the library and of a deck**

Create `lib/features/tags/domain/models/tag_count_model.dart`:

```dart
/// A tag and the active cards carrying it in the read's scope: the library
/// for the catalog, one deck for the card list's filter (BR-TAG-003; tag
/// management spec D3).
final class TagCount {
  const TagCount({
    required this.id,
    required this.name,
    required this.cardCount,
  });

  final String id;

  /// The canonical name, as stored (BR-TAG-001).
  final String name;

  /// Active cards only: a card in the Trash is not counted (BR-TAG-010).
  final int cardCount;
}
```

In `lib/features/tags/domain/repositories/tag_repository.dart`:

Replace

```dart
import 'package:memox/features/tags/domain/failures/tag_failure.dart';

```

with

```dart
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

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

  /// UC-TAG-001 steps 1-3 and 6: every tag of the local profile with the
  /// active cards carrying it, in [deckId] when given and in the library
  /// otherwise, by folded name then id; again after every change of the
  /// tags, their links or the cards (BR-TAG-003, BR-TAG-010). A
  /// [searchTerm] keeps the tags whose folded name holds its fold.
  Stream<List<TagCount>> watchTagCounts({
    String? deckId,
    String searchTerm = '',
  });
}
```

In `lib/features/tags/data/datasources/tag_dao.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';

```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

```

Replace

```dart
            (link) => link.cardId.isIn(cardIds) & link.tagId.equals(tagId),
          ))
          .go();
}
```

with

```dart
            (link) => link.cardId.isIn(cardIds) & link.tagId.equals(tagId),
          ))
          .go();

  /// Every tag of the local profile whose folded name holds [foldedTerm],
  /// with the active cards carrying it, in [deckId] when given; by folded
  /// name then id. One statement (tag management spec §5); `instr` finds an
  /// empty term everywhere.
  Future<List<QueryRow>> countRows({
    String? deckId,
    required String foldedTerm,
  }) => _db
      .customSelect(
        'SELECT t.id, t.name, ('
        'SELECT COUNT(*) FROM card_tags ct JOIN card c ON c.id = ct.card_id'
        ' WHERE ct.tag_id = t.id AND c.delete_batch_id IS NULL'
        ' AND (?1 IS NULL OR c.deck_id = ?1)'
        ') AS card_count FROM tags t'
        ' WHERE t.owner_id IS NULL AND instr(t.name_folded, ?2) > 0'
        ' ORDER BY t.name_folded, t.id',
        variables: [Variable<String>(deckId), Variable<String>(foldedTerm)],
        readsFrom: {_db.tags, _db.cardTags, _db.card},
      )
      .get();

  /// Fires once, then after every write to the tags, their links or the
  /// cards: a card entering the Trash or moving decks changes a count.
  Stream<void> countChanges() =>
      tableChanges(_db, [_db.tags, _db.cardTags, _db.card]);
}
```

In `lib/features/tags/data/repositories/tag_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
```

with

```dart
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
```

Replace

```dart

  Future<String> _createTag(String name, DateTime at) async {
```

with

```dart

  @override
  Stream<List<TagCount>> watchTagCounts({
    String? deckId,
    String searchTerm = '',
  }) {
    final term = TagEntity.fold(searchTerm);
    return _dao
        .countChanges()
        .asyncMap((_) => _dao.countRows(deckId: deckId, foldedTerm: term))
        .map(
          (rows) => [
            for (final row in rows)
              TagCount(
                id: row.read<String>('id'),
                name: row.read<String>('name'),
                cardCount: row.read<int>('card_count'),
              ),
          ],
        )
        .mapDatabaseErrors();
  }

  Future<String> _createTag(String name, DateTime at) async {
```

- [ ] **Step 4: Write the two use cases that read them**

Create `lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart`:

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 steps 1-3: the tag catalog, every tag of the library with its
/// active cards, under the search, again after every change (BR-TAG-003).
final class WatchTagCatalogUseCase {
  const WatchTagCatalogUseCase(this._tags);

  final TagRepository _tags;

  Stream<List<TagCount>> call({String searchTerm = ''}) =>
      _tags.watchTagCounts(searchTerm: searchTerm);
}
```

Create `lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart`:

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 6: every tag with the active cards of [deckId] carrying
/// it, for the card list's tag filter (tag management spec D3).
final class WatchDeckTagCountsUseCase {
  const WatchDeckTagCountsUseCase(this._tags);

  final TagRepository _tags;

  Stream<List<TagCount>> call({required String deckId}) =>
      _tags.watchTagCounts(deckId: deckId);
}
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 54 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/tags/data/tag_counts_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart
```

Expected: `+9: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/tags/data/datasources/tag_dao.dart \
  lib/features/tags/data/repositories/tag_repository_impl.dart \
  lib/features/tags/domain/models/tag_count_model.dart \
  lib/features/tags/domain/repositories/tag_repository.dart \
  lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart \
  lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart \
  test/features/tags/data/tag_counts_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart \
  test/support/tag_fixtures.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 54 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1570: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(tags): tag counts for the catalog and for a deck

watchTagCounts reads every tag of the local profile with the active
cards carrying it, in the library or in one deck, by folded name then
id, in one statement per emission, and again after every write to the
tags, their links or the cards (UC-TAG-001 steps 1-3 and 6; BR-TAG-003,
BR-TAG-010). A search keeps the tags whose folded name holds the folded
term, through instr: % and _ are plain characters, and a blank term
keeps every tag (tag management spec D3, D4). WatchTagCatalogUseCase and
WatchDeckTagCountsUseCase are the first use cases of tags.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: Plan a rename, then rename or merge behind the guard

**Files:**
- Create: `lib/features/tags/domain/models/tag_rename_plan_model.dart`, `lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart`, `lib/features/tags/domain/usecases/rename_tag_use_case.dart`
- Modify: `lib/features/card/presentation/widgets/support/tag_rejection_message_widget.dart`, `lib/features/tags/data/datasources/tag_dao.dart`, `lib/features/tags/data/repositories/tag_repository_impl.dart`, `lib/features/tags/domain/failures/tag_failure.dart`, `lib/features/tags/domain/repositories/tag_repository.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test (create): `test/features/tags/data/tag_rename_test.dart`
- Test (modify): `test/features/tags/domain/tag_management_use_cases_test.dart`, `test/support/tag_fixtures.dart`
- Regenerate: `lib/l10n/generated/` (`flutter gen-l10n`, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's `TagCount`, `TagDao` and fixtures; `TagEntity.checkName` and
  `fold`; `TagDao.findByFoldedName`; the repository's `_write`; `insertStudyTree` of
  `test/support/srs_fixtures.dart`; `totalChanges` of `test/support/test_database.dart`.
- Produces:
  - `TagRejection.mergeNotConfirmed`, with its case in
    `tag_rejection_message_widget.dart` and the ARB key `tagRejectionMergeNotConfirmed`.
  - `sealed class TagRenamePlan` with `TagRenameUnchanged()`, `TagRenameRename()` and
    `TagRenameMerge({required TagCount target, required int mergedCardCount})`
    (`tags/domain/models/tag_rename_plan_model.dart`).
  - `Future<Outcome<TagRenamePlan, TagRejection>> TagRepository.planRename({required String tagId, required String name})`
    and
    `Future<Outcome<void, TagRejection>> TagRepository.renameTag({required String tagId, required String name, String? mergeIntoTagId})`.
  - In `TagDao`: `findById` keeps to the local profile;
    `Future<int> activeCardCount(Set<String> tagIds)`,
    `Future<void> rename(String tagId, {required String name, required String nameFolded})`,
    `Future<void> merge({required String sourceId, required String targetId})` and
    `Future<void> deleteTag(String tagId)`.
  - `PlanTagRenameUseCase(TagRepository)` and `RenameTagUseCase(TagRepository)`,
    whose `call` takes the arguments of `planRename` and `renameTag`.
  - In `test/support/tag_fixtures.dart`: `Future<void> insertStudiedCard(AppDatabase db)`
    (card `s-card`),
    `Future<Map<String, List<Map<String, Object?>>>> rowsOutsideTags(AppDatabase db)`,
    `Future<List<(String, String, String)>> tagRowsOf(AppDatabase db)`,
    `Future<List<String>> linksOf(AppDatabase db)` (`card:tag`) and
    `final class FailingTagDelete extends QueryInterceptor`.

Spec §6, D5–D8, D11, D13; Clarifications 3–8; Review Focus 1, 2 and 3. The
plan and the write share one private `_planRename`, so the write's checks are the
plan's; a refusal writes nothing, and a failure rolls the whole merge back.

- [ ] **Step 1: Write the failing tests**

In `test/support/tag_fixtures.dart`:

Replace

```dart
import 'package:drift/drift.dart' show UpdateKind, Variable;
import 'package:memox/core/database/app_database.dart';

import 'trash_fixtures.dart';
```

with

```dart
import 'package:drift/drift.dart'
    show QueryExecutor, QueryInterceptor, UpdateKind, Variable;
import 'package:drift/native.dart' show SqliteException;
import 'package:memox/core/database/app_database.dart';

import 'srs_fixtures.dart';
import 'trash_fixtures.dart';
```

Replace

```dart
      updateKind: UpdateKind.update,
    );
```

with

```dart
      updateKind: UpdateKind.update,
    );

/// `s-card`, in a tree of its own, with a schedule row, a review log row and
/// a place in the queue of an in-progress session: rows a tag write leaves
/// as they are (BR-TAG-009).
Future<void> insertStudiedCard(AppDatabase db) async {
  final (_, cardId, sessionId) = await insertStudyTree(db, 's');
  await db.customStatement(
    'INSERT INTO study_queue_items (session_id, mode, card_id, position, '
    "status) VALUES (?, 'self_assess', ?, 0, 'pending')",
    [sessionId, cardId],
  );
  await db.customStatement(
    'INSERT INTO review_log (id, card_id, session_id, scheduler_type, '
    'generation, kind, mode, "action", answered_at) VALUES '
    "('s-log', ?, ?, 'eight_box', 1, 'learning', 'self_assess', "
    "'remembered', 0)",
    [cardId, sessionId],
  );
}

/// Every row outside `tags` and `card_tags`, table by table in rowid order:
/// a Tag Management write leaves it as it was (BR-TAG-009).
Future<Map<String, List<Map<String, Object?>>>> rowsOutsideTags(
  AppDatabase db,
) async {
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name NOT LIKE 'sqlite_%' AND name NOT IN ('tags', 'card_tags') "
        'ORDER BY name',
      )
      .get();
  return {
    for (final name in [for (final row in tables) row.read<String>('name')])
      name: [
        for (final row
            in await db
                .customSelect('SELECT * FROM "$name" ORDER BY rowid')
                .get())
          row.data,
      ],
  };
}

/// Every tag as (id, name, name_folded), by id.
Future<List<(String, String, String)>> tagRowsOf(AppDatabase db) async => [
  for (final row
      in await db
          .customSelect('SELECT id, name, name_folded FROM tags ORDER BY id')
          .get())
    (
      row.read<String>('id'),
      row.read<String>('name'),
      row.read<String>('name_folded'),
    ),
];

/// Every link as `card:tag`, by card then tag.
Future<List<String>> linksOf(AppDatabase db) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id, tag_id FROM card_tags ORDER BY card_id, tag_id',
          )
          .get())
    '${row.read<String>('card_id')}:${row.read<String>('tag_id')}',
];

/// Fails the statement that deletes a row of `tags`, the way a full disk
/// does. In a merge it runs after the links moved.
final class FailingTagDelete extends QueryInterceptor {
  static final _deletesTag = RegExp(r'^DELETE FROM "?tags"?\s');

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _failIfTagDelete(statement);
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    _failIfTagDelete(statement);
    return super.runDelete(executor, statement, args);
  }

  void _failIfTagDelete(String statement) {
    if (!_deletesTag.hasMatch(statement)) return;
    throw SqliteException(
      extendedResultCode: 13,
      message: 'database or disk is full',
    );
  }
}
```

Create `test/features/tags/data/tag_rename_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 step 4 and A1: a rename is planned, then written behind the
// merge guard (BR-TAG-006, BR-TAG-007, BR-TAG-009; tag management spec §6).

Matcher _refused<T>(TagRejection reason) => isA<Rejected<T, TagRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

Matcher _plans(Matcher plan) => isA<Ok<TagRenamePlan, TagRejection>>().having(
  (ok) => ok.value,
  'value',
  plan,
);

Matcher _mergesInto(
  String id,
  String name, {
  required int cardCount,
  required int mergedCardCount,
}) => _plans(
  isA<TagRenameMerge>()
      .having(
        (merge) => (merge.target.id, merge.target.name, merge.target.cardCount),
        'target',
        (id, name, cardCount),
      )
      .having(
        (merge) => merge.mergedCardCount,
        'mergedCardCount',
        mergedCardCount,
      ),
);

final _ok = isA<Ok<void, TagRejection>>();

List<(String, int)> _rows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;

  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 26));
    await insertTagDecks(db);
    for (final id in ['c1', 'c2', 'c3', 'c4']) {
      await insertTagCard(db, id);
    }
  });
  tearDown(() => db.close());

  test('a name that trims to the stored one is unchanged: planned, and '
      'written as nothing (tag management spec §6)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    final before = await totalChanges(db);

    expect(
      await tags.planRename(tagId: 't1', name: '  noun '),
      _plans(isA<TagRenameUnchanged>()),
    );
    expect(await tags.renameTag(tagId: 't1', name: '  noun '), _ok);
    expect(await totalChanges(db), before);
  });

  test('a case-only change renames the tag in place: same id, same links '
      '(BR-TAG-006)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2']);

    expect(
      await tags.planRename(tagId: 't1', name: 'Noun'),
      _plans(isA<TagRenameRename>()),
    );
    expect(await tags.renameTag(tagId: 't1', name: ' Noun '), _ok);

    expect(await tagRowsOf(db), [('t1', 'Noun', 'noun')]);
    expect(await linksOf(db), ['c1:t1', 'c2:t1']);
  });

  test('a diacritic makes a new name: hoc renamed Học folds to học '
      '(BR-TAG-001, BR-SEARCH-002)', () async {
    await insertTag(db, 't1', 'hoc', cardIds: ['c1']);

    expect(
      await tags.planRename(tagId: 't1', name: 'Học'),
      _plans(isA<TagRenameRename>()),
    );
    expect(await tags.renameTag(tagId: 't1', name: 'Học'), _ok);

    expect(await tagRowsOf(db), [('t1', 'Học', 'học')]);
    expect(await linksOf(db), ['c1:t1']);
  });

  test('a name another tag folds to plans a merge into it: the target with '
      'its active cards, and the active cards of both, once each '
      '(BR-TAG-007; tag management spec D6)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1', 'c2', 'c3']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2', 'c3', 'c4']);
    await setCardBatch(db, 'c3', 'b3');

    expect(
      await tags.planRename(tagId: 't1', name: ' VERB '),
      _mergesInto('t2', 'Verb', cardCount: 2, mergedCardCount: 3),
    );
  });

  test('the plan and the write refuse a bad name before a gone tag, and '
      'write nothing (BR-TAG-001; tag management spec §6)', () async {
    await insertTag(db, 't1', 'noun');
    final before = await totalChanges(db);

    for (final (tagId, name, reason) in [
      ('t1', '   ', TagRejection.blankName),
      ('t1', 'x' * 51, TagRejection.nameTooLong),
      ('t1', 'a\tb', TagRejection.controlCharacter),
      ('missing', '', TagRejection.blankName),
      ('missing', 'verb', TagRejection.notFound),
    ]) {
      expect(
        await tags.planRename(tagId: tagId, name: name),
        _refused<TagRenamePlan>(reason),
      );
      expect(
        await tags.renameTag(tagId: tagId, name: name),
        _refused<void>(reason),
      );
    }
    expect(await totalChanges(db), before);
  });

  test('a confirmed merge moves the links of active and trashed cards to '
      'the target, once per card, deletes the source and leaves the target '
      'as it was; a trashed card that carried both comes back carrying the '
      'target once (BR-TAG-007, BR-TAG-010)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1', 'c2', 'c3']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2', 'c3', 'c4']);
    await setCardBatch(db, 'c3', 'b3');

    expect(
      await tags.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      _ok,
    );

    expect(await tagRowsOf(db), [('t2', 'Verb', 'verb')]);
    expect(await linksOf(db), ['c1:t2', 'c2:t2', 'c3:t2', 'c4:t2']);
    await setCardBatch(db, 'c3', null);
    expect(_rows(await tags.watchTagCounts().first), [('Verb', 4)]);
  });

  test('a merge never takes a card past 10 tags: one carrying both among 10 '
      'keeps 9, one carrying the source among 10 trades it for the target '
      '(BR-TAG-002)', () async {
    for (var index = 0; index < 8; index++) {
      await insertTag(db, 'f$index', 'filler $index', cardIds: ['c1', 'c2']);
    }
    await insertTag(db, 'f8', 'filler 8', cardIds: ['c2']);
    await insertTag(db, 't1', 'verbs', cardIds: ['c1', 'c2']);
    await insertTag(db, 't2', 'verb', cardIds: ['c1']);

    expect(
      await tags.renameTag(tagId: 't1', name: 'VERB', mergeIntoTagId: 't2'),
      _ok,
    );

    final links = await linksOf(db);
    expect(links.where((link) => link.startsWith('c1:')), [
      for (var index = 0; index < 8; index++) 'c1:f$index',
      'c1:t2',
    ]);
    expect(links.where((link) => link.startsWith('c2:')), [
      for (var index = 0; index < 9; index++) 'c2:f$index',
      'c2:t2',
    ]);
  });

  test('the plan said rename, then the card editor made a tag with that '
      'name: the write is mergeNotConfirmed and writes nothing (tag '
      'management spec D5)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1']);
    expect(
      await tags.planRename(tagId: 't1', name: 'verb'),
      _plans(isA<TagRenameRename>()),
    );
    await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
    final before = await totalChanges(db);

    expect(
      await tags.renameTag(tagId: 't1', name: 'verb'),
      _refused<void>(TagRejection.mergeNotConfirmed),
    );
    expect(await totalChanges(db), before);
  });

  test(
    'a merge confirmed into another tag than the one the name folds to '
    'is mergeNotConfirmed and writes nothing (tag management spec D5)',
    () async {
      await insertTag(db, 't1', 'verbs', cardIds: ['c1']);
      await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
      await insertTag(db, 't3', 'noun', cardIds: ['c3']);
      final before = await totalChanges(db);

      expect(
        await tags.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't3'),
        _refused<void>(TagRejection.mergeNotConfirmed),
      );
      expect(await totalChanges(db), before);
    },
  );

  test('a confirmed merge whose target is gone renames the tag in place '
      '(tag management spec D8)', () async {
    await insertTag(db, 't1', 'verbs', cardIds: ['c1']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
    await db.customUpdate(
      "DELETE FROM tags WHERE id = 't2'",
      updates: {db.tags, db.cardTags},
    );

    expect(
      await tags.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      _ok,
    );

    expect(await tagRowsOf(db), [('t1', 'verb', 'verb')]);
    expect(await linksOf(db), ['c1:t1']);
  });

  test('a merge that fails after moving the links leaves both tags and '
      'every link as they were (UC-TAG-001 E4)', () async {
    final failing = openTestDatabase(interceptor: FailingTagDelete());
    addTearDown(failing.close);
    final broken = TagRepositoryImpl(failing);
    await insertTagDecks(failing);
    for (final id in ['c1', 'c2']) {
      await insertTagCard(failing, id);
    }
    await insertTag(failing, 't1', 'verbs', cardIds: ['c1', 'c2']);
    await insertTag(failing, 't2', 'Verb', cardIds: ['c2']);

    await expectLater(
      broken.renameTag(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    expect(await tagRowsOf(failing), [
      ('t1', 'verbs', 'verbs'),
      ('t2', 'Verb', 'verb'),
    ]);
    expect(await linksOf(failing), ['c1:t1', 'c2:t1', 'c2:t2']);
  });

  test("another profile's tag is not renamed, and its name is not a clash "
      '(tag management spec D13)', () async {
    await insertTag(db, 't1', 'verbs');
    await insertTag(db, 'x1', 'theirs', ownerId: 'someone');
    await insertTag(db, 'x2', 'verb', ownerId: 'someone');
    final before = await totalChanges(db);

    expect(
      await tags.planRename(tagId: 'x1', name: 'mine'),
      _refused<TagRenamePlan>(TagRejection.notFound),
    );
    expect(
      await tags.renameTag(tagId: 'x1', name: 'mine'),
      _refused<void>(TagRejection.notFound),
    );
    expect(await totalChanges(db), before);
    expect(
      await tags.planRename(tagId: 't1', name: 'verb'),
      _plans(isA<TagRenameRename>()),
    );
  });

  test('a rename and a merge write tags and card_tags and nothing else '
      '(BR-TAG-009)', () async {
    await insertStudiedCard(db);
    await setCardBatch(db, 'c1', 'b1');
    await insertTag(db, 't1', 'noun', cardIds: ['s-card', 'c1']);
    await insertTag(db, 't2', 'Verb', cardIds: ['s-card']);
    await insertTag(db, 't3', 'verbs', cardIds: ['s-card', 'c1', 'c2']);
    final before = await rowsOutsideTags(db);

    expect(await tags.renameTag(tagId: 't1', name: 'Noun'), _ok);
    expect(
      await tags.renameTag(tagId: 't3', name: 'verb', mergeIntoTagId: 't2'),
      _ok,
    );

    expect(await rowsOutsideTags(db), before);
  });

  test('the catalog follows a rename and a merge (BR-TAG-003)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await insertTag(db, 't2', 'Verb', cardIds: ['c2']);
    await insertTag(db, 't3', 'verbs', cardIds: ['c1', 'c2']);
    final seen = <List<(String, int)>>[];
    final subscription = tags.watchTagCounts().listen(
      (counts) => seen.add(_rows(counts)),
    );
    await pumpEventQueue();
    expect(seen.last, [('noun', 1), ('Verb', 1), ('verbs', 2)]);

    await tags.renameTag(tagId: 't1', name: 'Noun');
    await pumpEventQueue();
    expect(seen.last, [('Noun', 1), ('Verb', 1), ('verbs', 2)]);

    await tags.renameTag(tagId: 't3', name: 'verb', mergeIntoTagId: 't2');
    await pumpEventQueue();
    expect(seen.last, [('Noun', 1), ('Verb', 2)]);
    await subscription.cancel();
  });
}
```

In `test/features/tags/domain/tag_management_use_cases_test.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart';
```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/usecases/plan_tag_rename_use_case.dart';
import 'package:memox/features/tags/domain/usecases/rename_tag_use_case.dart';
import 'package:memox/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart';
```

Replace

```dart
      ('verb', 0),
    ]);
  });
}
```

with

```dart
      ('verb', 0),
    ]);
  });

  test('PlanTagRenameUseCase plans a rename and a merge '
      '(UC-TAG-001 step 4, A1)', () async {
    final plan = PlanTagRenameUseCase(tags);

    expect(
      await plan(tagId: 't1', name: 'Noun'),
      isA<Ok<TagRenamePlan, TagRejection>>().having(
        (ok) => ok.value,
        'value',
        isA<TagRenameRename>(),
      ),
    );
    expect(
      await plan(tagId: 't1', name: 'VERB'),
      isA<Ok<TagRenamePlan, TagRejection>>().having(
        (ok) => ok.value,
        'value',
        isA<TagRenameMerge>().having(
          (merge) => merge.target.id,
          'target',
          't2',
        ),
      ),
    );
  });

  test('RenameTagUseCase merges only into the confirmed tag '
      '(UC-TAG-001 A1)', () async {
    final rename = RenameTagUseCase(tags);

    expect(
      await rename(tagId: 't1', name: 'verb'),
      isA<Rejected<void, TagRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        TagRejection.mergeNotConfirmed,
      ),
    );
    expect(
      await rename(tagId: 't1', name: 'verb', mergeIntoTagId: 't2'),
      isA<Ok<void, TagRejection>>(),
    );
    expect(_rows(await tags.watchTagCounts().first), [('verb', 1)]);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/tags/data/tag_rename_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: Error when reading 'lib/features/tags/domain/models/tag_rename_plan_model.dart': No such file or directory`,
`Error: The method 'planRename' isn't defined for the type 'TagRepositoryImpl'.`,
`Error: The method 'renameTag' isn't defined for the type 'TagRepositoryImpl'.`,
`Error: Member not found: 'mergeNotConfirmed'.`,
`Error: Method not found: 'PlanTagRenameUseCase'.` and
`Error: Method not found: 'RenameTagUseCase'.`

- [ ] **Step 3: Name the new refusal**

In `lib/features/tags/domain/failures/tag_failure.dart`:

Replace

```dart
  /// A card or tag no longer exists.
  notFound,
}
```

with

```dart
  /// A card or tag no longer exists.
  notFound,

  /// BR-TAG-007, tag management spec D5: the rename would merge into a tag
  /// the caller did not confirm. The data moved since the plan: plan again.
  mergeNotConfirmed,
}
```

In `lib/features/card/presentation/widgets/support/tag_rejection_message_widget.dart`:

Replace

```dart
    TagRejection.notFound => tagRejectionNotFound,
  };
```

with

```dart
    TagRejection.notFound => tagRejectionNotFound,
    TagRejection.mergeNotConfirmed => tagRejectionMergeNotConfirmed,
  };
```

In `lib/l10n/app_en.arb`:

Replace

```json
    "description": "Tag refusal: a card or tag is gone."
  },
```

with

```json
    "description": "Tag refusal: a card or tag is gone."
  },
  "tagRejectionMergeNotConfirmed": "Another tag now has this name. Check the merge and confirm again.",
  "@tagRejectionMergeNotConfirmed": {
    "description": "Tag refusal: a rename would now merge into a tag the person did not confirm."
  },
```

In `lib/l10n/app_vi.arb`:

Replace

```json
  "tagRejectionNotFound": "Một thẻ hoặc nhãn không còn nữa.",
  "cardAddTitle": "Thẻ mới",
```

with

```json
  "tagRejectionNotFound": "Một thẻ hoặc nhãn không còn nữa.",
  "tagRejectionMergeNotConfirmed": "Một nhãn khác vừa có tên này. Hãy xem lại việc gộp rồi xác nhận lại.",
  "cardAddTitle": "Thẻ mới",
```

- [ ] **Step 4: Generate the localizations**

```bash
flutter gen-l10n
```

Expected: it prints
`Because l10n.yaml exists, the options defined there will be used instead.`, and
`lib/l10n/generated/` knows `tagRejectionMergeNotConfirmed`. `flutter analyze` does
not regenerate it: after an ARB edit, `flutter gen-l10n` runs first.

- [ ] **Step 5: Plan a rename, and write it or the merge**

`TagDao.findById` keeps to the local profile from here on (Clarification 3), and
`TagDao.deleteTag` serves the merge now and Task 3's delete next (Clarification 5).

Create `lib/features/tags/domain/models/tag_rename_plan_model.dart`:

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

/// What renaming a tag to a name would do, told before the write
/// (UC-TAG-001 A1; tag management spec D5).
sealed class TagRenamePlan {
  const TagRenamePlan();
}

/// The trimmed name is the stored one: nothing to write.
final class TagRenameUnchanged extends TagRenamePlan {
  const TagRenameUnchanged();
}

/// A new spelling that no other tag folds to; a case-only change is one
/// (BR-TAG-006).
final class TagRenameRename extends TagRenamePlan {
  const TagRenameRename();
}

/// Another tag folds alike: the rename merges into it (BR-TAG-007).
final class TagRenameMerge extends TagRenamePlan {
  const TagRenameMerge({required this.target, required this.mergedCardCount});

  /// The tag that stays, as the catalog lists it.
  final TagCount target;

  /// The distinct active cards carrying the source or the target: what the
  /// target carries once merged (tag management spec D6).
  final int mergedCardCount;
}
```

In `lib/features/tags/domain/repositories/tag_repository.dart`:

Replace

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

```

with

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';

```

Replace

```dart
    String searchTerm = '',
  });
}
```

with

```dart
    String searchTerm = '',
  });

  /// UC-TAG-001 step 4 and A1: what renaming [tagId] to [name] would do, read
  /// in one transaction: nothing, a rename, or a merge into the tag that
  /// folds alike, with its counts. Refuses a bad name (BR-TAG-001), then a
  /// tag that is gone (tag management spec §6).
  Future<Outcome<TagRenamePlan, TagRejection>> planRename({
    required String tagId,
    required String name,
  });

  /// UC-TAG-001 step 4 and A1: renames [tagId] to [name], keeping its id and
  /// links (BR-TAG-006), or merges it into the tag that folds alike when
  /// that tag is [mergeIntoTagId] (BR-TAG-007); a merge into any other tag
  /// is `mergeNotConfirmed` and writes nothing. With no tag to merge into,
  /// [mergeIntoTagId] is ignored (spec D8). The checks of [planRename] run
  /// first, in its order; only `tags` and `card_tags` are written
  /// (BR-TAG-009).
  Future<Outcome<void, TagRejection>> renameTag({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  });
}
```

In `lib/features/tags/data/datasources/tag_dao.dart`:

Replace

```dart

  Future<Tag?> findById(String id) => (_db.select(
    _db.tags,
  )..where((tag) => tag.id.equals(id))).getSingleOrNull();

```

with

```dart

  /// The local profile's tag [id] (tag management spec D13).
  Future<Tag?> findById(String id) =>
      (_db.select(_db.tags)
            ..where((tag) => tag.ownerId.isNull() & tag.id.equals(id)))
          .getSingleOrNull();

```

Replace

```dart
      tableChanges(_db, [_db.tags, _db.cardTags, _db.card]);
}
```

with

```dart
      tableChanges(_db, [_db.tags, _db.cardTags, _db.card]);

  /// The distinct active cards carrying any of [tagIds]: a card in the Trash
  /// is not counted (BR-TAG-010).
  Future<int> activeCardCount(Set<String> tagIds) async {
    final count = _db.cardTags.cardId.count(distinct: true);
    final query =
        _db.selectOnly(_db.cardTags).join([
            innerJoin(
              _db.card,
              _db.card.id.equalsExp(_db.cardTags.cardId),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..where(
            _db.cardTags.tagId.isIn(tagIds) & _db.card.deleteBatchId.isNull(),
          );
    return (await query.getSingle()).read(count)!;
  }

  /// Renames [tagId] in place: its id and links stay (BR-TAG-006).
  Future<void> rename(
    String tagId, {
    required String name,
    required String nameFolded,
  }) => (_db.update(_db.tags)..where((tag) => tag.id.equals(tagId))).write(
    TagsCompanion(name: Value(name), nameFolded: Value(nameFolded)),
  );

  /// Links every card of [sourceId], in the Trash or not, to [targetId],
  /// then deletes [sourceId] (BR-TAG-007, BR-TAG-010). A card carrying both
  /// keeps the target once: `OR IGNORE` skips the link it has.
  Future<void> merge({
    required String sourceId,
    required String targetId,
  }) async {
    await _db.customInsert(
      'INSERT OR IGNORE INTO card_tags (card_id, tag_id) '
      'SELECT card_id, ? FROM card_tags WHERE tag_id = ?',
      variables: [Variable<String>(targetId), Variable<String>(sourceId)],
      updates: {_db.cardTags},
    );
    await deleteTag(sourceId);
  }

  /// Deletes [tagId]. Its links go by the cascade of `card_tags`, and drift's
  /// update rule for that key tells the watchers of `card_tags` as well.
  Future<void> deleteTag(String tagId) => _db.customUpdate(
    'DELETE FROM tags WHERE id = ?',
    variables: [Variable<String>(tagId)],
    updates: {_db.tags},
    updateKind: UpdateKind.delete,
  );
}
```

In `lib/features/tags/data/repositories/tag_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
```

with

```dart
import 'package:memox/features/tags/domain/models/tag_count_model.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';
```

Replace

```dart

  Future<String> _createTag(String name, DateTime at) async {
```

with

```dart

  @override
  Future<Outcome<TagRenamePlan, TagRejection>> planRename({
    required String tagId,
    required String name,
  }) => _write(() => _planRename(tagId, name));

  @override
  Future<Outcome<void, TagRejection>> renameTag({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) => _write(() async {
    switch (await _planRename(tagId, name)) {
      case Rejected(:final reason):
        return Rejected(reason);
      case Ok(value: TagRenameUnchanged()):
        return const Ok(null);
      case Ok(value: TagRenameRename()):
        await _dao.rename(
          tagId,
          name: name.trim(),
          nameFolded: TagEntity.fold(name),
        );
        return const Ok(null);
      case Ok(value: TagRenameMerge(:final target)):
        if (target.id != mergeIntoTagId) {
          return const Rejected(TagRejection.mergeNotConfirmed);
        }
        await _dao.merge(sourceId: tagId, targetId: target.id);
        return const Ok(null);
    }
  });

  /// Tag management spec §6, on rows read in the caller's transaction: the
  /// name, the source, the stored name, then a clash. The source's own row
  /// is never a clash, so a case-only change renames (BR-TAG-006).
  Future<Outcome<TagRenamePlan, TagRejection>> _planRename(
    String tagId,
    String name,
  ) async {
    if (TagEntity.checkName(name) case Rejected(:final reason)) {
      return Rejected(reason);
    }
    final source = await _dao.findById(tagId);
    if (source == null) return const Rejected(TagRejection.notFound);
    if (name.trim() == source.name) return const Ok(TagRenameUnchanged());
    final target = await _dao.findByFoldedName(TagEntity.fold(name));
    if (target == null || target.id == tagId) {
      return const Ok(TagRenameRename());
    }
    return Ok(
      TagRenameMerge(
        target: TagCount(
          id: target.id,
          name: target.name,
          cardCount: await _dao.activeCardCount({target.id}),
        ),
        mergedCardCount: await _dao.activeCardCount({tagId, target.id}),
      ),
    );
  }

  Future<String> _createTag(String name, DateTime at) async {
```

- [ ] **Step 6: Write the two use cases**

Create `lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 4 and A1: what a rename would do, read as the name is
/// typed, so a merge is shown before the commit (BR-TAG-007).
final class PlanTagRenameUseCase {
  const PlanTagRenameUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<TagRenamePlan, TagRejection>> call({
    required String tagId,
    required String name,
  }) => _tags.planRename(tagId: tagId, name: name);
}
```

Create `lib/features/tags/domain/usecases/rename_tag_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 4 and A1: renames a tag, or merges it into the tag the
/// person confirmed (BR-TAG-006, BR-TAG-007).
final class RenameTagUseCase {
  const RenameTagUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({
    required String tagId,
    required String name,
    String? mergeIntoTagId,
  }) =>
      _tags.renameTag(tagId: tagId, name: name, mergeIntoTagId: mergeIntoTagId);
}
```

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 54 warning(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/tags/data/tag_rename_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart
```

Expected: `+18: All tests passed!`

- [ ] **Step 9: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/card/presentation/widgets/support/tag_rejection_message_widget.dart \
  lib/features/tags/data/datasources/tag_dao.dart \
  lib/features/tags/data/repositories/tag_repository_impl.dart \
  lib/features/tags/domain/failures/tag_failure.dart \
  lib/features/tags/domain/models/tag_rename_plan_model.dart \
  lib/features/tags/domain/repositories/tag_repository.dart \
  lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart \
  lib/features/tags/domain/usecases/rename_tag_use_case.dart \
  lib/l10n/app_en.arb \
  lib/l10n/app_vi.arb \
  test/features/tags/data/tag_rename_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart \
  test/support/tag_fixtures.dart \
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
`✓ architecture boundaries clean`; `PASS — 0 error(s), 54 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1586: All tests passed!`.

- [ ] **Step 11: Commit**

```bash
git commit -F - <<'EOF'
feat(tags): plan a rename, then rename or merge behind the guard

planRename says what a rename would do before anything is written:
nothing, a rename in place, or a merge into the tag that folds alike,
with that tag's active cards and the active cards of both. renameTag
runs the same checks in its own transaction and merges only into the
tag the caller named; any other merge is mergeNotConfirmed and writes
nothing (tag management spec D5, D8). A merge links the source's cards
to the target with INSERT OR IGNORE, cards in the Trash included, then
deletes the source, whose links go by cascade; the target's row is not
written (BR-TAG-006, BR-TAG-007, BR-TAG-010). Only tags and card_tags
change (BR-TAG-009). TagRejection gains mergeNotConfirmed, with its
message (D11).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: Delete a tag

**Files:**
- Create: `lib/features/tags/domain/usecases/delete_tag_use_case.dart`
- Modify: `lib/features/tags/data/repositories/tag_repository_impl.dart`, `lib/features/tags/domain/repositories/tag_repository.dart`
- Test (create): `test/features/tags/data/tag_delete_test.dart`
- Test (modify): `test/features/tags/domain/tag_management_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2's `TagDao.findById` and `deleteTag`, and its fixtures.
- Produces:
  - `Future<Outcome<void, TagRejection>> TagRepository.deleteTag({required String tagId})`.
  - `DeleteTagUseCase(TagRepository)` with
    `Future<Outcome<void, TagRejection>> call({required String tagId})`.

Spec §7, D9; Clarifications 5–7; Review Focus 4. The delete reuses Task 2's
`TagDao.deleteTag`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/tags/data/tag_delete_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/models/tag_count_model.dart';

import '../../../support/tag_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 step 5: deleting a tag removes its links and its row, and no
// card (BR-TAG-008, BR-TAG-009; tag management spec §7).

final _ok = isA<Ok<void, TagRejection>>();

Matcher _refused(TagRejection reason) => isA<Rejected<void, TagRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

List<(String, int)> _rows(List<TagCount> counts) => [
  for (final count in counts) (count.name, count.cardCount),
];

void main() {
  late AppDatabase db;
  late TagRepositoryImpl tags;

  setUp(() async {
    db = openTestDatabase();
    tags = TagRepositoryImpl(db, now: () => DateTime(2026, 9, 26));
    await insertTagDecks(db);
    for (final id in ['c1', 'c2', 'c3']) {
      await insertTagCard(db, id);
    }
  });
  tearDown(() => db.close());

  Future<List<String>> cardIds() async => [
    for (final row
        in await db.customSelect('SELECT id FROM card ORDER BY id').get())
      row.read<String>('id'),
  ];

  test('a delete removes the tag and its links, those of a card in the Trash '
      'included, and every card stays (BR-TAG-008, BR-TAG-010)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1', 'c2', 'c3']);
    await insertTag(db, 't2', 'verb', cardIds: ['c1']);
    await setCardBatch(db, 'c3', 'b3');

    expect(await tags.deleteTag(tagId: 't1'), _ok);

    expect(await tagRowsOf(db), [('t2', 'verb', 'verb')]);
    expect(await linksOf(db), ['c1:t2']);
    expect(await cardIds(), ['c1', 'c2', 'c3']);
  });

  test(
    'a tag whose only card is in the Trash counts 0 and deletes like any '
    'other: the card comes back without it (BR-TAG-008, BR-TAG-010)',
    () async {
      await insertTag(db, 't1', 'old', cardIds: ['c3']);
      await setCardBatch(db, 'c3', 'b3');
      expect(_rows(await tags.watchTagCounts().first), [('old', 0)]);

      expect(await tags.deleteTag(tagId: 't1'), _ok);
      await setCardBatch(db, 'c3', null);

      expect(await linksOf(db), isEmpty);
      expect(await tags.watchTagCounts().first, isEmpty);
    },
  );

  test("a tag that is gone, or another profile's, is notFound and nothing "
      'is written (tag management spec D13)', () async {
    await insertTag(db, 't1', 'noun', cardIds: ['c1']);
    await insertTag(db, 'x1', 'theirs', ownerId: 'someone');
    final before = await totalChanges(db);

    expect(
      await tags.deleteTag(tagId: 'missing'),
      _refused(TagRejection.notFound),
    );
    expect(await tags.deleteTag(tagId: 'x1'), _refused(TagRejection.notFound));
    expect(await totalChanges(db), before);
  });

  test('a delete that fails leaves the tag and its links as they were '
      '(UC-TAG-001 E5)', () async {
    final failing = openTestDatabase(interceptor: FailingTagDelete());
    addTearDown(failing.close);
    final broken = TagRepositoryImpl(failing);
    await insertTagDecks(failing);
    await insertTagCard(failing, 'c1');
    await insertTag(failing, 't1', 'noun', cardIds: ['c1']);

    await expectLater(
      broken.deleteTag(tagId: 't1'),
      throwsA(isA<UnknownDatabaseFailure>()),
    );

    expect(await tagRowsOf(failing), [('t1', 'noun', 'noun')]);
    expect(await linksOf(failing), ['c1:t1']);
  });

  test(
    'a delete writes tags and card_tags and nothing else (BR-TAG-009)',
    () async {
      await insertStudiedCard(db);
      await setCardBatch(db, 'c1', 'b1');
      await insertTag(db, 't1', 'noun', cardIds: ['s-card', 'c1', 'c2']);
      final before = await rowsOutsideTags(db);

      expect(await tags.deleteTag(tagId: 't1'), _ok);

      expect(await rowsOutsideTags(db), before);
    },
  );

  test(
    'the catalog and the counts of a deck follow a delete (BR-TAG-003)',
    () async {
      await insertTag(db, 't1', 'noun', cardIds: ['c1']);
      await insertTag(db, 't2', 'verb', cardIds: ['c1', 'c2']);
      final catalog = <List<(String, int)>>[];
      final inDeck = <List<(String, int)>>[];
      final subscriptions = [
        tags.watchTagCounts().listen((counts) => catalog.add(_rows(counts))),
        tags
            .watchTagCounts(deckId: 'leaf')
            .listen((counts) => inDeck.add(_rows(counts))),
      ];
      await pumpEventQueue();
      expect(catalog.last, [('noun', 1), ('verb', 2)]);

      await tags.deleteTag(tagId: 't2');
      await pumpEventQueue();
      expect(catalog.last, [('noun', 1)]);
      expect(inDeck.last, [('noun', 1)]);
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
}
```

In `test/features/tags/domain/tag_management_use_cases_test.dart`:

Replace

```dart
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/usecases/plan_tag_rename_use_case.dart';
```

with

```dart
import 'package:memox/features/tags/domain/models/tag_rename_plan_model.dart';
import 'package:memox/features/tags/domain/usecases/delete_tag_use_case.dart';
import 'package:memox/features/tags/domain/usecases/plan_tag_rename_use_case.dart';
```

Replace

```dart
    expect(_rows(await tags.watchTagCounts().first), [('verb', 1)]);
  });
}
```

with

```dart
    expect(_rows(await tags.watchTagCounts().first), [('verb', 1)]);
  });

  test('DeleteTagUseCase deletes the tag (UC-TAG-001 step 5)', () async {
    final delete = DeleteTagUseCase(tags);

    expect(await delete(tagId: 't1'), isA<Ok<void, TagRejection>>());
    expect(_rows(await tags.watchTagCounts().first), [('verb', 0)]);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/tags/data/tag_delete_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles:
`Error: The method 'deleteTag' isn't defined for the type 'TagRepositoryImpl'.`,
`Error: Error when reading 'lib/features/tags/domain/usecases/delete_tag_use_case.dart': No such file or directory`
and `Error: Method not found: 'DeleteTagUseCase'.`

- [ ] **Step 3: Delete a tag and its links**

In `lib/features/tags/domain/repositories/tag_repository.dart`:

Replace

```dart
    String? mergeIntoTagId,
  });
}
```

with

```dart
    String? mergeIntoTagId,
  });

  /// UC-TAG-001 step 5: deletes [tagId] and its links, those of cards in the
  /// Trash included; every card stays (BR-TAG-008). Only `tags` and
  /// `card_tags` are written (BR-TAG-009).
  Future<Outcome<void, TagRejection>> deleteTag({required String tagId});
}
```

In `lib/features/tags/data/repositories/tag_repository_impl.dart`:

Replace

```dart

  /// Tag management spec §6, on rows read in the caller's transaction: the
```

with

```dart

  @override
  Future<Outcome<void, TagRejection>> deleteTag({required String tagId}) =>
      _write(() async {
        if (await _dao.findById(tagId) == null) {
          return const Rejected(TagRejection.notFound);
        }
        await _dao.deleteTag(tagId);
        return const Ok(null);
      });

  /// Tag management spec §6, on rows read in the caller's transaction: the
```

- [ ] **Step 4: Write the use case**

Create `lib/features/tags/domain/usecases/delete_tag_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/tags/domain/failures/tag_failure.dart';
import 'package:memox/features/tags/domain/repositories/tag_repository.dart';

/// UC-TAG-001 step 5: deletes a tag and its links; no card is deleted
/// (BR-TAG-008).
final class DeleteTagUseCase {
  const DeleteTagUseCase(this._tags);

  final TagRepository _tags;

  Future<Outcome<void, TagRejection>> call({required String tagId}) =>
      _tags.deleteTag(tagId: tagId);
}
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 54 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/tags/data/tag_delete_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart
```

Expected: `+11: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/tags/data/repositories/tag_repository_impl.dart \
  lib/features/tags/domain/repositories/tag_repository.dart \
  lib/features/tags/domain/usecases/delete_tag_use_case.dart \
  test/features/tags/data/tag_delete_test.dart \
  test/features/tags/domain/tag_management_use_cases_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 54 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1593: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(tags): delete a tag, and its links with it

deleteTag deletes the tag's row; its links go by cascade, those of cards
in the Trash included, and no card, schedule, log or session is written
(BR-TAG-008, BR-TAG-009). A tag that is gone, or another profile's, is
notFound and nothing is written; a failure rolls back (UC-TAG-001 E5).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: The card list filtered by tags (BE-C4)

**Files:**
- Modify: `lib/features/card/data/datasources/card_list_dao.dart`, `lib/features/card/data/repositories/card_repository_impl.dart`, `lib/features/card/domain/models/card_list_query_model.dart`, `lib/features/card/domain/models/card_list_view_model.dart`, `lib/features/card/domain/repositories/card_repository.dart`
- Test (create): `test/features/card/data/card_list_tag_filter_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `CardListDao._predicate`, `counts`, `ids` and `window`; Task 1's
  `watchTagCounts` and Task 2's `renameTag`, in the tests.
- Produces:
  - `CardListQuery({CardListFilter filter, CardListSort sort, String searchTerm, Set<String> tagIds = const {}})`.
  - `CardListDao.counts({required String deckId, required String searchTerm, required Set<String> tagIds, required DateTime now})`.
  - `WatchCardListUseCase` and `SelectAllCardIdsUseCase` keep their signatures.

Spec §8, D10; Clarification 9; Review Focus 5. The test builds `Mixed due` of
S-DUE as `card_list_read_test.dart` does, and tags its cards through the tag
repository: `card` may import `tags`.

- [ ] **Step 1: Write the failing tests**

Create `test/features/card/data/card_list_tag_filter_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/models/card_list_query_model.dart';
import 'package:memox/features/card/domain/models/card_list_view_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/test_database.dart';

// UC-TAG-001 steps 7-8 and A4 (BE-C4): the card list filtered by tags, an OR
// between them that ANDs with the status filter and the search, shared by
// the window, the counts and Select all (BR-TAG-004; tag management spec
// §8). `Mixed due` of S-DUE at T0 = 2026-09-23 10:00, as in
// card_list_read_test.dart.
final _now = DateTime(2026, 9, 23, 10);

void main() {
  late AppDatabase db;
  late CardRepositoryImpl cards;
  late TagRepositoryImpl tags;
  late DeckEntity mixed;
  late Map<String, String> tagIds;

  setUp(() async {
    db = openTestDatabase();
    DateTime clock() => DateTime(2026, 9, 1);
    final decks = DeckRepositoryImpl(db, now: clock);
    tags = TagRepositoryImpl(db, now: clock);
    cards = CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: clock),
      tags,
      now: clock,
    );
    final root = await decks.root('Due library');
    mixed = await decks.sub(root.id, 'Mixed due');
    await insertCard(
      db,
      id: 'new',
      deckId: mixed.id,
      front: 'abandon',
      back: 'từ bỏ',
      createdAt: DateTime(2026, 9, 1),
    );
    await insertCard(
      db,
      id: 'begin',
      deckId: mixed.id,
      front: 'benevolent',
      back: 'nhân từ',
      isFlagged: true,
      learnedAt: DateTime(2026, 9, 20),
      dueAt: DateTime(2026, 9, 23),
      box: 2,
      createdAt: DateTime(2026, 9, 2),
    );
    await insertCard(
      db,
      id: 'review',
      deckId: mixed.id,
      front: 'candid',
      back: 'thẳng thắn',
      learnedAt: DateTime(2026, 9, 10),
      dueAt: DateTime(2026, 9, 22),
      box: 5,
      createdAt: DateTime(2026, 9, 3),
    );
    await insertCard(
      db,
      id: 'master',
      deckId: mixed.id,
      front: 'diligent',
      back: 'chăm chỉ',
      learnedAt: DateTime(2026, 5, 1),
      dueAt: DateTime(2026, 10, 23),
      box: 8,
      createdAt: DateTime(2026, 9, 4),
    );
    await tags.attachByName(cardIds: {'new', 'begin'}, name: 'verb');
    await tags.attachByName(cardIds: {'begin', 'review'}, name: 'noun');
    await tags.attachByName(cardIds: {'begin'}, name: 'adj');
    await tags.attachByName(cardIds: {'master'}, name: 'rare');
    tagIds = {
      for (final count in await tags.watchTagCounts().first)
        count.name: count.id,
    };
  });
  tearDown(() => db.close());

  CardListQuery tagged(
    Set<String> names, {
    CardListFilter filter = CardListFilter.all,
    String searchTerm = '',
  }) => CardListQuery(
    filter: filter,
    searchTerm: searchTerm,
    tagIds: {for (final name in names) tagIds[name] ?? name},
  );

  Future<CardListView> list(CardListQuery query, {int windowSize = 50}) => cards
      .watchCardList(
        deckId: mixed.id,
        query: query,
        windowSize: windowSize,
        now: _now,
      )
      .first;

  Future<List<String>> shown(CardListQuery query) async => [
    for (final item in (await list(query)).items) item.id,
  ];

  (int, int, int, int) countsOf(CardListView view) => (
    view.counts.all,
    view.counts.due,
    view.counts.newCards,
    view.counts.flagged,
  );

  Future<Set<String>> selectAll(CardListQuery query) =>
      cards.cardIdsMatching(deckId: mixed.id, query: query, now: _now);

  test('the selected tags are an OR: a card carrying any of them passes '
      '(BR-TAG-004)', () async {
    expect(await shown(tagged({'verb'})), ['begin', 'new']);
    expect(await shown(tagged({'verb', 'noun'})), ['review', 'begin', 'new']);
  });

  test('the tags AND with each status filter and with the search '
      '(BR-TAG-004)', () async {
    expect(await shown(tagged({'verb', 'noun'}, filter: CardListFilter.due)), [
      'review',
      'begin',
    ]);
    expect(
      await shown(tagged({'verb', 'noun'}, filter: CardListFilter.newCards)),
      ['new'],
    );
    expect(
      await shown(tagged({'verb', 'noun'}, filter: CardListFilter.flagged)),
      ['begin'],
    );
    expect(await shown(tagged({'noun'}, searchTerm: 'TỪ')), ['begin']);
  });

  test('a card carrying three selected tags appears once, counts once and '
      'takes one place in the window (BR-TAG-004)', () async {
    final query = tagged({'verb', 'noun', 'adj'});
    final first = await list(query, windowSize: 2);
    final whole = await list(query, windowSize: 3);

    expect([for (final item in first.items) item.id], ['review', 'begin']);
    expect(first.hasMore, isTrue);
    expect(
      [for (final item in whole.items) item.id],
      ['review', 'begin', 'new'],
    );
    expect(whole.hasMore, isFalse);
    expect(countsOf(whole), (3, 2, 1, 1));
  });

  test('the counts follow the tags; the status counts and the workload stay '
      'the deck\'s (tag management spec D10)', () async {
    final view = await list(tagged({'noun'}));

    expect(countsOf(view), (2, 2, 0, 1));
    expect(view.statusCounts.total, 4);
    expect(
      (view.workload.overdue, view.workload.today, view.workload.newCards),
      (1, 1, 1),
    );
  });

  test('Select all takes exactly the cards the list shows (BR-CARD-012, '
      'BR-TAG-004)', () async {
    expect(await selectAll(tagged({'verb', 'noun', 'adj'})), {
      'review',
      'begin',
      'new',
    });
    expect(
      await selectAll(tagged({'verb', 'noun'}, filter: CardListFilter.due)),
      {'review', 'begin'},
    );
  });

  test('no selected tag is the identity: the list, the counts and Select all '
      'as without the filter (BR-TAG-004)', () async {
    final view = await list(const CardListQuery(tagIds: {}));

    expect(
      [for (final item in view.items) item.id],
      ['master', 'review', 'begin', 'new'],
    );
    expect(countsOf(view), (4, 2, 1, 1));
    expect(await selectAll(const CardListQuery(tagIds: {})), {
      'master',
      'review',
      'begin',
      'new',
    });
  });

  test('a tag id that no longer exists matches no card, and a card in the '
      'Trash never passes (BR-TAG-010; tag management spec D10)', () async {
    await insertCard(
      db,
      id: 'trashed',
      deckId: mixed.id,
      deleteBatchId: 'batch',
    );
    await db.customInsert(
      'INSERT INTO card_tags (card_id, tag_id) VALUES (?, ?)',
      variables: [
        const Variable<String>('trashed'),
        Variable<String>(tagIds['rare']!),
      ],
      updates: {db.cardTags},
    );

    final gone = await list(tagged({'missing'}));
    expect(gone.items, isEmpty);
    expect(countsOf(gone), (0, 0, 0, 0));
    expect(await selectAll(tagged({'missing'})), isEmpty);
    expect(await shown(tagged({'rare'})), ['master']);
    expect(await selectAll(tagged({'rare'})), {'master'});
  });

  test('a list filtered by a tag that is merged away matches nothing, and the '
      "deck's tag list no longer offers it (tag management spec §9)", () async {
    final views = <CardListView>[];
    final subscription = cards
        .watchCardList(
          deckId: mixed.id,
          query: tagged({'noun'}),
          windowSize: 50,
          now: _now,
        )
        .listen(views.add);
    await pumpEventQueue();
    expect([for (final item in views.last.items) item.id], ['review', 'begin']);

    await tags.renameTag(
      tagId: tagIds['noun']!,
      name: 'VERB',
      mergeIntoTagId: tagIds['verb'],
    );
    await pumpEventQueue();

    expect(views.last.items, isEmpty);
    expect(views.last.counts.all, 0);
    expect(
      [
        for (final count in await tags.watchTagCounts(deckId: mixed.id).first)
          count.name,
      ],
      ['adj', 'rare', 'verb'],
    );
    await subscription.cancel();
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/card/data/card_list_tag_filter_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile:
`Error: No named parameter with the name 'tagIds'.`

- [ ] **Step 3: Give the query its tags**

In `lib/features/card/domain/models/card_list_query_model.dart`:

Replace

```dart
    this.searchTerm = '',
  });
```

with

```dart
    this.searchTerm = '',
    this.tagIds = const {},
  });
```

Replace

```dart
  final String searchTerm;
}
```

with

```dart
  final String searchTerm;

  /// A card passes when it carries any of these tags (BR-TAG-004); none
  /// lets every card through. An id that no longer exists matches no card.
  final Set<String> tagIds;
}
```

- [ ] **Step 4: Filter the window, Select all and the counts by the tags**

In `lib/features/card/data/datasources/card_list_dao.dart`:

Replace

```dart

  /// All, Due, New and Flagged under [searchTerm], whatever the filter, in
  /// one statement (IT-ORG-005).
  Future<({int all, int due, int newCards, int flagged})> counts({
```

with

```dart

  /// All, Due, New and Flagged under [searchTerm] and [tagIds], whatever the
  /// filter, in one statement (IT-ORG-005, BR-TAG-004).
  Future<({int all, int due, int newCards, int flagged})> counts({
```

Replace

```dart
    required String searchTerm,
    required DateTime now,
```

with

```dart
    required String searchTerm,
    required Set<String> tagIds,
    required DateTime now,
```

Replace

```dart
          ..addColumns([all, due, newCards, flagged])
          ..where(_inDeck(deckId, searchTerm));
    final row = await select.getSingle();
```

with

```dart
          ..addColumns([all, due, newCards, flagged])
          ..where(_inDeck(deckId, searchTerm) & _tagged(tagIds));
    final row = await select.getSingle();
```

Replace

```dart
  /// The one place that says which cards a query lets through: the active
  /// cards of [deckId], under the search, through the filter. A tag filter
  /// (BR-TAG-004) is one more term here.
  Expression<bool> _predicate({
```

with

```dart
  /// The one place that says which cards a query lets through: the active
  /// cards of [deckId], under the search, through the filter, carrying one
  /// of the selected tags (BR-TAG-004).
  Expression<bool> _predicate({
```

Replace

```dart
    required DateTime now,
  }) => _inDeck(deckId, query.searchTerm) & _passes(query.filter, now);

```

with

```dart
    required DateTime now,
  }) =>
      _inDeck(deckId, query.searchTerm) &
      _passes(query.filter, now) &
      _tagged(query.tagIds);

```

Replace

```dart
        (_holds(_card.frontFolded, term) | _holds(_card.backFolded, term));
  }
```

with

```dart
        (_holds(_card.frontFolded, term) | _holds(_card.backFolded, term));
  }

  /// BR-TAG-004: an `EXISTS` on `card_tags`, one boolean per card, never a
  /// join that repeats a card carrying several of [tagIds]. No tag is no
  /// term.
  Expression<bool> _tagged(Set<String> tagIds) {
    if (tagIds.isEmpty) return const Constant(true);
    final links = _db.cardTags;
    return existsQuery(
      _db.selectOnly(links)
        ..addColumns([links.tagId])
        ..where(links.cardId.equalsExp(_card.id) & links.tagId.isIn(tagIds)),
    );
  }
```

In `lib/features/card/data/repositories/card_repository_impl.dart`:

Replace

```dart
      searchTerm: query.searchTerm,
      now: now,
```

with

```dart
      searchTerm: query.searchTerm,
      tagIds: query.tagIds,
      now: now,
```

In `lib/features/card/domain/repositories/card_repository.dart`:

Replace

```dart
  /// through, whether more follow, and the count of every filter under the
  /// same search (IT-ORG-005). Due is due at [now]. Each item carries its
  /// tags and due label, and the view counts the deck's display states
  /// whatever the search and filter. Emits again on every change of a card,
  /// a schedule row or a card's tags.
  Stream<CardListView> watchCardList({
```

with

```dart
  /// through, whether more follow, and the count of every filter under the
  /// same search and tags (IT-ORG-005, BR-TAG-004). Due is due at [now].
  /// Each item carries its tags and due label, and the view counts the
  /// deck's display states whatever the search, filter and tags. Emits again
  /// on every change of a card, a schedule row, a tag or a card's tags.
  Stream<CardListView> watchCardList({
```

In `lib/features/card/domain/models/card_list_view_model.dart`:

Replace

```dart

/// How many cards each filter would show under the current search, whatever
/// filter is picked (IT-ORG-005).
final class CardListCounts {
```

with

```dart

/// How many cards each filter would show under the current search and tags,
/// whatever filter is picked (IT-ORG-005, BR-TAG-004).
final class CardListCounts {
```

Replace

```dart
/// How many of the deck's active cards show each display state
/// (BR-CARD-008, BR-SRS-013), whatever the search and the filter: the deck's
/// progress, not the list's.
final class CardStatusCounts {
```

with

```dart
/// How many of the deck's active cards show each display state
/// (BR-CARD-008, BR-SRS-013), whatever the search, the filter and the tags:
/// the deck's progress, not the list's.
final class CardStatusCounts {
```

Replace

```dart
/// The deck's work by when it is due (BR-STUDY-067, BR-STUDY-068), whatever
/// the search and the filter: the summary's breakdown line (owner decision
/// E-O1).
final class CardWorkload {
```

with

```dart
/// The deck's work by when it is due (BR-STUDY-067, BR-STUDY-068), whatever
/// the search, the filter and the tags: the summary's breakdown line (owner
/// decision E-O1).
final class CardWorkload {
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 54 warning(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/card/data/card_list_tag_filter_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 7: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add lib/features/card/data/datasources/card_list_dao.dart \
  lib/features/card/data/repositories/card_repository_impl.dart \
  lib/features/card/domain/models/card_list_query_model.dart \
  lib/features/card/domain/models/card_list_view_model.dart \
  lib/features/card/domain/repositories/card_repository.dart \
  test/features/card/data/card_list_tag_filter_test.dart \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 8: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 54 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1601: All tests passed!`.

- [ ] **Step 9: Commit**

```bash
git commit -F - <<'EOF'
feat(card): filter the card list by tags (BE-C4)

CardListQuery gains tagIds. The card list lets a card through when it
carries any of them: an EXISTS on card_tags inside the one predicate the
window and Select all share, and in the filter counts, so a card that
carries several selected tags shows, counts and selects once. No tag is
no term; an id that no longer exists matches no card. The status counts
and the workload stay the deck's (BR-TAG-004; tag management spec
D10).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: The package's documents

**Files:**
- Modify: `docs/features/tags/README.md`, `docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md`, `docs/shared/data/schema.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`, `lib/core/database/tables/tags.drift`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: the code of Tasks 1–4.
- Produces: the documents only.

Spec §11, D4; Clarification 9.

- [ ] **Step 1: Say what the tag tables serve now**

A comment only: the generated code does not change, and the gate's generated-code
check reads the declared parts without a rebuild.

In `lib/core/database/tables/tags.drift`:

Replace

```sql

-- Scope: V8.0, tagging a card only (ADR-009 decision 4). Tag Management
-- (UC-TAG-001) is a later sub-project.
CREATE TABLE tags (
```

with

```sql

-- Scope: V8.0 tags a card (ADR-009 decision 4). Tag Management (UC-TAG-001),
-- a sub-project after V8.0, renames, merges and deletes tags on these same
-- tables from BE-B2.
CREATE TABLE tags (
```

- [ ] **Step 2: Record the package in the tags documents, the schema and the WBS**

Replace the whole of `docs/features/tags/README.md` with:

```markdown
---
feature: tags
code: [lib/features/tags/domain, lib/features/tags/data, lib/features/tags/di]
depends_on: [card]
---
## Phạm vi

**Phạm vi:** Tag Management, phần store (BE-B2,
[spec](../../superpowers/specs/2026-09-26-tag-management-backend-design.md)).

Mô hình dữ liệu tag (BR-TAG-001, BR-TAG-002) và Tag Management v1: catalog, lọc theo tag, đổi tên/gộp, xoá.

Gắn/gỡ tag trên thẻ (BR-TAG-001, BR-TAG-002, UC-CARD-001 A8) thuộc V8.0 (chủ dự án chốt ngày 2026-09-23, [ADR-009](../../shared/decisions/ADR-009-chot-pham-vi-v8-0.md)); Tag Management là sub-project sau V8.0, phần store làm ở BE-B2.

Đổi tên được xem trước rồi mới ghi: `PlanTagRenameUseCase` nói trước lúc xác nhận là
giữ nguyên, đổi tên hay gộp vào tag nào, kèm số thẻ; `RenameTagUseCase` chỉ gộp vào
đúng tag người dùng đã xác nhận, còn lại từ chối `mergeNotConfirmed` và không ghi gì
(spec D5). Lọc card list theo tag là `CardListQuery.tagIds` của feature `card` (BE-C4).

## Màn hình → Use case

| Màn hình | UC |
|---|---|
| Tag catalog (hành động `Tags` trên app bar của Library, hoặc `Manage tags`) | UC-TAG-001 |

Nguồn: trigger của UC-TAG-001.

## Không thuộc phạm vi

| Thứ | Vì sao |
|---|---|
| Tag phân cấp, màu tag, taxonomy chia sẻ | Ngoài phạm vi Tag Management v1 — UC-TAG-001 chốt tag là nhãn phẳng, là định danh văn bản, không phải hệ thống deck thứ hai |
| Màn catalog (màn 05), overlay lọc của card list, hành động `Tags` trên app bar của Library | FE-B2 ([`wbs_FE.md`](../../wbs_FE.md)) |
```

In `docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md`:

Replace

```markdown
rules: [BR-CARD-012, BR-DECK-015, BR-TAG-001, BR-TAG-002, BR-TAG-003, BR-TAG-004, BR-TAG-005, BR-TAG-006, BR-TAG-007, BR-TAG-008, BR-TAG-009, BR-TAG-010, BR-TAG-011, BR-TRANSFER-009]
code: []
---
```

with

```markdown
rules: [BR-CARD-012, BR-DECK-015, BR-TAG-001, BR-TAG-002, BR-TAG-003, BR-TAG-004, BR-TAG-005, BR-TAG-006, BR-TAG-007, BR-TAG-008, BR-TAG-009, BR-TAG-010, BR-TAG-011, BR-TRANSFER-009]
code: [lib/features/tags/domain/usecases/watch_tag_catalog_use_case.dart, lib/features/tags/domain/usecases/watch_deck_tag_counts_use_case.dart, lib/features/tags/domain/usecases/plan_tag_rename_use_case.dart, lib/features/tags/domain/usecases/rename_tag_use_case.dart, lib/features/tags/domain/usecases/delete_tag_use_case.dart, lib/features/card/domain/usecases/watch_card_list_use_case.dart, lib/features/card/domain/usecases/select_all_card_ids_use_case.dart]
---
```

Replace

```markdown

**Phạm vi:** sub-project sau — Tags (spec §2).

```

with

```markdown

**Phạm vi:** Tag Management, phần store (BE-B2, gồm BE-C4). Màn catalog và overlay lọc
thuộc FE-B2.

```

Replace

```markdown
3. Người dùng gõ vào ô tìm kiếm để thu hẹp catalog. Hệ thống lọc theo cùng phép
   fold mà BR-TAG-001 dùng, nên `Dong tu` và `động từ` tìm thấy nhau đúng như lúc tạo
   tag (BR-TAG-003).
```

with

```markdown
3. Người dùng gõ vào ô tìm kiếm để thu hẹp catalog. Hệ thống lọc theo cùng phép
   fold mà BR-TAG-001 dùng, nên `ĐỘNG TỪ` và `động từ` tìm thấy nhau đúng như lúc tạo
   tag (BR-TAG-003).
```

In `docs/shared/data/schema.md`:

Replace

```markdown

**Phạm vi:** V8.0 cho việc gắn/gỡ tag trên thẻ (ADR-009 quyết định 4; chủ dự án chốt ngày 2026-09-23). Tag Management (UC-TAG-001) vẫn là sub-project sau.

```

with

```markdown

**Phạm vi:** V8.0 cho việc gắn/gỡ tag trên thẻ (ADR-009 quyết định 4; chủ dự án chốt ngày 2026-09-23). Tag Management (UC-TAG-001), sub-project sau V8.0, đổi tên, gộp và xoá tag trên chính hai bảng này từ BE-B2, không đổi schema.

```

Replace

```markdown
PK là `(card_id, tag_id)`. Index thứ hai `idx_card_tags_tag` trên `(tag_id,
card_id)` cho chiều ngược lại — "mọi thẻ mang tag này" là câu mà bộ lọc hỏi, và
PK không phục vụ được nó.

```

with

```markdown
PK là `(card_id, tag_id)`. Index thứ hai `idx_card_tags_tag` trên `(tag_id,
card_id)` cho chiều ngược lại — "mọi thẻ mang tag này" là câu mà số đếm của catalog
và việc gộp hỏi, và PK không phục vụ được nó. Bộ lọc tag của card list hỏi chiều kia:
với từng thẻ, một `EXISTS` đi theo PK (BR-TAG-004).

```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-B1 | Trash, phần store (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012): schema v3 với `delete_batches` và khoá `delete_batch_id` → `delete_batches(id)` (migration v2 → v3 bằng dựng lại bảng, test nâng cấp từ v1 và v2); xoá deck và card là soft-delete theo batch, đóng phiên chạm tới batch (kể cả qua lựa chọn `guess`); khôi phục và Undo theo đúng luật di chuyển; đích khôi phục; danh sách Trash và purge theo lượt, bỏ qua trọn batch còn chứa batch khác; 11 use case; test hình dạng câu lệnh của BR-TRASH-002 với allowlist có lý do | xong | BE-02, BE-D1 | L | [spec](superpowers/specs/2026-09-25-trash-backend-design.md) và [plan](superpowers/plans/2026-09-26-trash-backend.md) gói 7; test trong `test/features/trash/`, `test/features/deck/data/deck_trash_test.dart`, `test/features/card/data/card_trash_test.dart`, `test/drift/migration_test.dart`, `test/architecture/tombstone_filter_test.dart` | FE-B1 dựng màn 06, snackbar Undo và lời gọi auto-purge trên các use case này |

```

with

```markdown
| BE-B1 | Trash, phần store (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012): schema v3 với `delete_batches` và khoá `delete_batch_id` → `delete_batches(id)` (migration v2 → v3 bằng dựng lại bảng, test nâng cấp từ v1 và v2); xoá deck và card là soft-delete theo batch, đóng phiên chạm tới batch (kể cả qua lựa chọn `guess`); khôi phục và Undo theo đúng luật di chuyển; đích khôi phục; danh sách Trash và purge theo lượt, bỏ qua trọn batch còn chứa batch khác; 11 use case; test hình dạng câu lệnh của BR-TRASH-002 với allowlist có lý do | xong | BE-02, BE-D1 | L | [spec](superpowers/specs/2026-09-25-trash-backend-design.md) và [plan](superpowers/plans/2026-09-26-trash-backend.md) gói 7; test trong `test/features/trash/`, `test/features/deck/data/deck_trash_test.dart`, `test/features/card/data/card_trash_test.dart`, `test/drift/migration_test.dart`, `test/architecture/tombstone_filter_test.dart` | FE-B1 dựng màn 06, snackbar Undo và lời gọi auto-purge trên các use case này |
| BE-B2 | Tag Management, phần store (UC-TAG-001; BR-TAG-003…BR-TAG-011): catalog tag kèm số thẻ đang hoạt động, trong thư viện hoặc trong một deck, tìm theo đúng phép fold của BR-TAG-001; xem trước đổi tên (giữ nguyên, đổi tên, hay gộp vào tag nào và còn bao nhiêu thẻ) rồi ghi sau chốt chặn `mergeNotConfirmed`; gộp bằng `INSERT OR IGNORE` rồi xoá tag nguồn theo cascade, kể cả liên kết của thẻ trong Trash; xoá tag theo cascade; chỉ ghi `tags` và `card_tags`; 5 use case; không đổi schema | xong | BE-05 | M | [spec](superpowers/specs/2026-09-26-tag-management-backend-design.md) và [plan](superpowers/plans/2026-09-26-tag-management-backend.md) gói 8; test trong `test/features/tags/` | FE-B2 dựng màn 05 và overlay lọc trên các use case này |
| BE-C4 | Lọc card list theo tag (BR-TAG-004): `CardListQuery.tagIds`, một `EXISTS` trên `card_tags` trong vị từ chung của danh sách, số đếm và Select all; số đếm trạng thái và workload vẫn tính cả deck | xong | BE-B2 | S | Spec gói 8 §8; `test/features/card/data/card_list_tag_filter_test.dart` | — |

```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | chưa bắt đầu | BE-04, BE-05 | M–L | Nice-to-have N1 trong [`docs/README.md`](README.md): import CSV/TSV/XLSX, export nội dung | Tuân thủ BR-CORE-001, BR-CORE-002, BR-CORE-004 |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-B3 | Transfer: import card hàng loạt (parse, validate, xem trước, ghi trong một transaction) và export (UC-TRANSFER-001, UC-TRANSFER-002; BR-TRANSFER-001…BR-TRANSFER-014) | chưa bắt đầu | BE-04, BE-05 | M–L | Nice-to-have N1 trong [`docs/README.md`](README.md): import CSV/TSV/XLSX, export nội dung | Tuân thủ BR-CORE-001, BR-CORE-002, BR-CORE-004 |
```

Replace

```markdown
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
| BE-C4 | Lọc card list theo tag (BR-TAG-004) | chưa bắt đầu | BE-B2 | S | Spec backend deck/card §8 | Làm trong BE-B2 |

```

with

```markdown
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |

```

Replace

```markdown
  review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

with

```markdown
  review toàn nhánh trước khi mở PR.
- **BE-B2, BE-C4** (gói 8,
  [spec](superpowers/specs/2026-09-26-tag-management-backend-design.md),
  [plan](superpowers/plans/2026-09-26-tag-management-backend.md)): gate xanh sau mỗi
  task, final review toàn nhánh trước khi mở PR.
- **BE-D2** (gói 6, [spec](superpowers/specs/2026-09-25-ci-gate-design.md),
```

Replace

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 17/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003, UC-TRASH-001).
  5 UC còn lại chưa có code.

```

with

```markdown
  `gate`, `goldens` và `CI gate` đỏ, rồi commit hoàn lại đưa cả ba về xanh trước khi merge.
- **Traceability:** có test chứa ID cho 18/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SEARCH-001, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003, UC-TAG-001, UC-TRASH-001).
  4 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 7 (BE-B1).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 8 (BE-B2).

```

Replace

```markdown

1. BE-B2…BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của chúng đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
```

with

```markdown

1. BE-B3…BE-B5 theo ưu tiên sản phẩm. Truy vấn mới của chúng đọc `card` hoặc `deck` sẽ
   gặp test hình dạng của BR-TRASH-002 (spec gói 7 §11).
```

Replace

```markdown
  schema v3, xoá vào Trash, khôi phục, Undo, purge.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  schema v3, xoá vào Trash, khôi phục, Undo, purge.
- **Cập nhật ngày 2026-09-26:** BE-B2 và BE-C4 xong trong gói 8: catalog tag, đổi tên có
  gộp, xoá tag, lọc card list theo tag; không đổi schema.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | BE-B1 xong: hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Sau BE-B2 |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
```

with

```markdown
| FE-B1 | Trash: màn hình Trash mở từ app bar, xoá vào Trash, khôi phục (UC-TRASH-001) | chưa bắt đầu | BE-B1, FE-A1, FE-A2 | M | BE-B1 xong: hợp đồng cho UI ở §10 của [spec gói 7](superpowers/specs/2026-09-25-trash-backend-design.md); [README trash](features/trash/README.md) | Màn 06 trên 7 use case của `trash`; snackbar Undo cho xoá **một** item (`UndoDeckDeletionUseCase`, `UndoCardDeletionUseCase`) với thời gian UI chọn; gọi `PurgeExpiredTrashUseCase` lúc mở app, khi resume, khi mở Trash và khi Trash được focus lại; đổi câu chữ "xoá vĩnh viễn" của hộp thoại xoá và của quy tắc chung "Delete is permanent in V8.0" trong screen handoff; căn câu chữ của 5 lý do từ chối mới (D16) theo kit; ghi lệch với kit ở `youngerInside` (kit nói "xoá sau", bất biến 36 chỉ cho phép ngược lại). Tiếp tục hoặc rời một phiên mà nội dung vừa vào Trash nay trả `sessionClosed`; phiên có deck trong Trash thì watch trả `notFound` |
| FE-B2 | Danh mục tag và lọc card theo tag (UC-TAG-001) | chưa bắt đầu | BE-B2, FE-A2 | M | BE-B2 xong: hợp đồng cho UI ở §9 của [spec gói 8](superpowers/specs/2026-09-26-tag-management-backend-design.md); [ui.md](features/tags/ui.md), [kịch bản IT](features/tags/it-scenarios.md) | Màn 05 trên 5 use case của `tags`: gọi `PlanTagRenameUseCase` khi tên đổi, xác nhận gộp bằng `mergeIntoTagId`, gặp `mergeNotConfirmed` thì xem trước lại; ghi lệch với kit ở `renameMerge`: số thẻ sau gộp là hợp các thẻ (spec D6), không phải tổng `31 + 46`; overlay lọc của màn 07 đọc `WatchDeckTagCountsUseCase`, đặt `CardListQuery.tagIds` và bỏ khỏi lựa chọn tag không còn trong danh sách; hành động `Tags` trên app bar của Library; "Find cards with this tag" là tìm kiếm thư viện theo tên tag (spec D12) |
| FE-B3 | Import card vào deck và export card ra file (UC-TRANSFER-001, UC-TRANSFER-002) | chưa bắt đầu | BE-B3, FE-A2 | M | [README transfer](features/transfer/README.md), [kịch bản IT](features/transfer/it-scenarios.md) | Chọn file và chia sẻ file cần plugin nền tảng (xem Điểm chặn) |
```

Replace

```markdown
4. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1 xong trong gói
   7, nên FE-B1 không còn chờ backend; BE-B2…BE-B5 chưa bắt đầu.

```

with

```markdown
4. FE-C1 sau khi có quyết định; FE-C5 khi mở lại phạm vi tablet.
5. Sau V8.0: FE-B1…FE-B5 theo thứ tự các hạng mục BE-B tương ứng. BE-B1 và BE-B2 xong
   trong gói 7 và gói 8, nên FE-B1 và FE-B2 không còn chờ backend; BE-B3…BE-B5 chưa bắt
   đầu.

```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s), 53 warning(s)`.

- [ ] **Step 3: Stage the task's files**

The gate asks every source under `lib/` to be in git, so the task is staged before it runs.

```bash
git add docs/features/tags/README.md \
  docs/features/tags/usecases/UC-TAG-001-quan-ly-tag-va-loc-the-theo-tag.md \
  docs/shared/data/schema.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  lib/core/database/tables/tags.drift \
  docs/_generated
git status --short
```

Expected: every path `git status --short` lists is staged: a letter in its first column, a space in its second.

- [ ] **Step 4: Run the gate**

Run:

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: it ends with `✓ mechanical gates passed`. Among its steps:
`No issues found!`; `✓ generated code is fresh, complete and uncommitted`;
`✓ architecture boundaries clean`; `PASS — 0 error(s), 53 warning(s)` (the
warnings are older than this plan); the CI tooling tests `Ran 77 tests` and
`OK (skipped=8)` (eight of them need PowerShell 7); `204 passed` (the guard's
self-tests); `Code verification passed.`; `+1601: All tests passed!`.

- [ ] **Step 5: Commit**

```bash
git commit -F - <<'EOF'
docs: Tag Management is built; BE-B2 and BE-C4 done

UC-TAG-001 names its code and says its store is built, and its step 3
example follows the fold it names: ĐỘNG TỪ and động từ (tag management
spec D4). The tags README, schema.md and tags.drift say what the two
tables serve now, schema.md says which key each tag read walks, and the
WBS has BE-B2 and BE-C4 done, with FE-B2's notes (spec §11).
EOF
```

Append the session's attribution trailers to the message when you commit.


## After the final review: the pull request

- [ ] **Step 1: Open the pull request**

Push `claude/be-tags` and open its pull request against `master`, then subscribe
to its activity.

Expected: CI is paused during active development (root `README.md`, "CI"), so no
check runs on the pull request; it merges on the local gate.

- [ ] **Step 2: Merge**

Merge `master` into `claude/be-tags` if it moved, run the gate once more on the
branch head, and squash-merge only while it ends with `✓ mechanical gates passed`.
Then unsubscribe from the pull request's activity.


## Plan self-review

- **Spec coverage.** §5 the counts and D3's two scopes: Task 1. §6 the plan, the
  rename, the merge and the guard, with D5–D8: Task 2. §7 the delete: Task 3. §8 the
  card list's tag filter: Task 4. §9 the five use cases: Tasks 1–3. §10 tests: every
  line has its test in Tasks 1–4. §11 documents: Task 5. D11's refusal: Task 2. D13:
  Tasks 1–3.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the dry run
  compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the task that owns the
  code.
