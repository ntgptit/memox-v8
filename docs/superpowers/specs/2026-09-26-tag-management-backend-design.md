# MemoX V8 — Tag Management backend design (package 8)

Status: draft 2026-09-26, for the owner's review · Path: architectural

## 1. Intent

Build BE-B2 of [`docs/wbs_BE.md`](../../wbs_BE.md), which includes BE-C4: the store side
of Tag Management, UC-TAG-001, with BR-TAG-003…BR-TAG-011 and the tag model they lean on
(BR-TAG-001, BR-TAG-002).

The package writes `domain/`, `data/` and `di/` of `lib/features/tags/`, and the card
list's tag filter in `lib/features/card/`. The screens belong to FE-B2 in
[`docs/wbs_FE.md`](../../wbs_FE.md): screen 05 of the kit ("A13 · Tag catalog", twelve
states) and the `Tags` filter of screen 07.

Success means:

- FE-B2 builds every state of screen 05 and the tag filter from use cases alone: the
  catalog with its search, the rename dialog that says before the commit whether it
  merges and into what, the delete confirmation, and the filter's list of tags;
- a rename never merges without the person's confirmation, even when the data moves
  between the dialog and the write;
- the card list, its counts and Select all agree on which cards a tag filter lets
  through, and a card appears once whatever number of its tags is selected;
- a catalog operation writes `tags` and `card_tags` and nothing else;
- every rule the backend owns has a test that fails when it breaks;
- the gate of the root `README.md` passes after every task, and the documents change in
  the same commits as the code.

## 2. Context (2026-09-26)

- `master` is at `2ca85f2`: package 7 (#69, the Trash) merged. Cards in the Trash carry
  `delete_batch_id`; every read of active content filters it, and a text check fails a
  statement that reads `card` or `deck` without the filter (package 7 spec §11).
- **UC-TAG-001** is `ready` with `code: []`, and no test names it.
- **The rules.**
  - The catalog is library-wide: every tag of the local profile, its canonical name,
    and the number of active cards carrying it; sorted by `name_folded`, then `id`;
    searched with the fold of BR-TAG-001 on both sides; a tag with no card is listed
    with 0 (BR-TAG-003). A card in the Trash is not counted and never passes the tag
    filter, but its links survive a rename or a merge (BR-TAG-010).
  - Filtering by several tags is an OR between them, AND the status filter and the
    search; an empty selection is the identity; the predicate is an `EXISTS` on
    `card_tags`, never a join that duplicates rows; the list, the count and Select all
    share it (BR-TAG-004). Changing the selection resets the window (BR-TAG-005, a UI
    rule; the store serves each query on its own stream).
  - A rename keeps the tag's `id` and links, and a case-only change is not a clash with
    itself (BR-TAG-006). A rename onto another tag's folded name merges the two in one
    transaction: the source's cards join the target, duplicates collapse, the source's
    row goes, the target keeps its `id`, `name` and `name_folded`, and no card passes
    10 tags (BR-TAG-007, BR-TAG-002).
  - Deleting a tag removes its `card_tags` rows and its row, and nothing else
    (BR-TAG-008). Rename, merge and delete write `tags` and `card_tags` only
    (BR-TAG-009). One fold and one codec serve the catalog, import and export
    (BR-TAG-011).
- **The fold** is `foldText`: trim, then Dart's `toLowerCase()`. It never strips
  diacritics (BR-SEARCH-002), so `ĐỘNG TỪ` and `động từ` are one tag and `dong tu` is
  another. UC-TAG-001 step 3 says `Dong tu` and `động từ` find each other; that example
  contradicts the fold it names, and the owner ruled on 2026-09-26 to correct the
  example (D4).
- **The code today.**
  - `lib/features/tags/` has `TagEntity` (`checkName`, `fold`, `maxNameLength`,
    `maxPerCard`), `TagRejection` (`blankName`, `nameTooLong`, `controlCharacter`,
    `tooManyTags`, `notFound`), `TagRepository` with `attachByName`, `detach` and
    `replaceForCard` for the card editor, `TagDao`, `tagRepositoryProvider`, and no
    use case: until now the card feature was its only caller.
  - `CardListDao._predicate` builds the one predicate of the list, Select all and the
    counts' base (deck, search, filter), and was written to take a tag term later
    (deck/card backend spec §8). `CardListQuery` has `filter`, `sort`, `searchTerm`.
  - `TagRejection`'s messages live in the card feature
    (`tag_rejection_message_widget.dart`), an exhaustive `switch`.
- **The schema** needs nothing: `tags` (`id`, `name`, `name_folded`, `owner_id`,
  `created_at`) with the unique index `(COALESCE(owner_id, ''), name_folded)`, and
  `card_tags` with its key `(card_id, tag_id)`, the index `idx_card_tags_tag (tag_id,
  card_id)`, and `ON DELETE CASCADE` on both keys.
- **The kit**, screen 05: `loaded`, `loading`, `empty`, `searchEmpty`, `sheet` (Find
  cards with this tag · Rename tag · Delete tag), `rename`, `renameMerge` ("A tag called
  X already exists. Continuing will merge … into it"; its pills show the target with a
  count), `nameTooLong`, `del` ("Remove from N cards", "No card is deleted"), `busy`,
  `opError` (nothing changed, Retry) and `tagGone` (the tag was removed meanwhile).
  Screen 07 has a `Tags` filter chip whose overlay the kit does not draw.
- **Feature imports:** `card` may import `tags`; `tags` imports no feature.

## 3. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Scope: BE-B2 with BE-C4. No schema change, no migration. | The tables, keys, indexes and cascades exist (§2). |
| D2 | `tags` gains its first use cases, one per interaction, and `TagRepository` grows; no second repository. | AD-12: the feature now has screens of its own. One contract per feature, as `deck` and `card` do. |
| D3 | One read, two scopes: `watchTagCounts({deckId, searchTerm})`. No `deckId` is the catalog; a `deckId` lists every tag with the active cards of that deck carrying it, 0 included. | The owner, 2026-09-26: the filter overlay lists every tag (UC-TAG-001 step 6) with counts in the open deck, so a count says what selecting that tag alone shows. |
| D4 | Search matches `instr(name_folded, fold(term))`; a blank term lists every tag. UC-TAG-001 step 3's example becomes `ĐỘNG TỪ` and `động từ`. | BR-TAG-003 and BR-TAG-011 forbid a second normalizer; the fold keeps diacritics (BR-SEARCH-002). The owner ruled on the example, 2026-09-26. |
| D5 | A rename is planned, then written behind a guard: `planRename` returns `unchanged`, `rename` or `merge(target, mergedCardCount)`; `renameTag(tagId, name, mergeIntoTagId)` refuses `mergeNotConfirmed` when the write would merge into a tag the caller did not name. | The owner's choice A, 2026-09-26. The kit shows the merge panel while typing (`renameMerge`), UC-TAG-001 A1 discloses the merge before the commit, and no race can turn a rename into a silent merge. |
| D6 | `mergedCardCount` counts the distinct active cards carrying the source or the target. | A card carrying both keeps one tag (BR-TAG-007). The kit's sample shows `31 + 46`; FE-B2 shows the union and records the deviation. |
| D7 | A merge links every card of the source to the target with `INSERT OR IGNORE`, then deletes the source's row; its remaining links go by cascade. Cards in the Trash are included. | BR-TAG-007; BR-TAG-010 keeps a hidden card's tags for its restore. No card gains a tag, so BR-TAG-002 holds without a check. |
| D8 | A confirmed merge whose target is gone at the write is a plain rename. | The name is free; the person asked for it. The opposite race is D5's refusal. |
| D9 | A delete deletes the tag's row; `card_tags` goes by cascade, links of cards in the Trash included. The confirmation's count is the catalog's (active cards). | BR-TAG-008; the kit's `del` counts the row's cards. |
| D10 | `CardListQuery` gains `tagIds`. The tag term is an `EXISTS` on `card_tags` inside `_predicate` and in the counts; the status counts and the workload stay deck-wide. An id that no longer exists matches nothing. | BR-TAG-004. The status counts and workload are the deck's progress, not the list's (BR-CARD-008, E-O1). FE-B2 prunes its selection against the overlay's list (§9). |
| D11 | `TagRejection` gains `mergeNotConfirmed`, with its case in `tag_rejection_message_widget.dart` and its strings in `app_en.arb` and `app_vi.arb`. | The exhaustive `switch` needs it; the same step as package 7's D16. |
| D12 | "Find cards with this tag" needs no backend: the library search matches cards by a tag's name (BR-SEARCH-001). | BE-A8 is built. |
| D13 | Every read and write keeps to the local profile, `owner_id IS NULL`. | As `TagDao` does today; profiles are a later sub-project. |

## 4. Structure

```
lib/features/tags/
├── domain/
│   ├── failures/tag_failure.dart             + mergeNotConfirmed (D11)
│   ├── models/tag_count_model.dart           TagCount (new)
│   ├── models/tag_rename_plan_model.dart     TagRenamePlan and its three cases (new)
│   ├── repositories/tag_repository.dart      + watchTagCounts, planRename, renameTag, deleteTag
│   └── usecases/                             the five of §8 (new folder)
└── data/
    ├── datasources/tag_dao.dart              + the reads and writes of §5–§7
    └── repositories/tag_repository_impl.dart + the four methods

lib/features/card/
├── domain/models/card_list_query_model.dart  + tagIds (D10)
├── data/datasources/card_list_dao.dart       + the tag term in _predicate and counts
├── data/repositories/card_repository_impl.dart  passes tagIds to the counts
└── presentation/widgets/support/tag_rejection_message_widget.dart  + one case (D11)

lib/l10n/app_en.arb, app_vi.arb               + tagRejectionMergeNotConfirmed
lib/core/database/tables/tags.drift            the scope comment only
```

## 5. Tag counts

```dart
/// A tag and the active cards carrying it in the read's scope (BR-TAG-003).
final class TagCount {
  const TagCount({required this.id, required this.name, required this.cardCount});
  final String id;
  final String name;      // canonical, as stored
  final int cardCount;    // active cards only (BR-TAG-010)
}
```

`TagRepository.watchTagCounts({String? deckId, String searchTerm = ''})`:

- **One statement per emission.** Every tag with `owner_id IS NULL`; for each, a
  correlated count of `card_tags` joined to `card c` with `c.delete_batch_id IS NULL`,
  and `c.deck_id = :deck` when `deckId` is given. A tag with no such card counts 0 and
  stays. The statement reads `card` with its filter, so the BR-TRASH-002 check passes
  without an allowlist entry.
- **Search:** when `foldText(searchTerm)` is not empty, `instr(t.name_folded, :term) >
  0`; `instr`, never `LIKE`, so `%` and `_` are plain characters.
- **Order:** `t.name_folded, t.id`.
- **When it reads:** `tableChanges` over `tags`, `card_tags` and `card`: a tag write, a
  card entering or leaving the Trash, a card moving decks and a purge all re-emit. A
  failed read reaches the stream as a database `Failure` (`mapDatabaseErrors`).

## 6. Rename and merge

```dart
sealed class TagRenamePlan {
  const TagRenamePlan();
}

/// The trimmed name is the stored one: nothing to write.
final class TagRenameUnchanged extends TagRenamePlan {
  const TagRenameUnchanged();
}

/// A new spelling that no other tag folds to; a case-only change is one (BR-TAG-006).
final class TagRenameRename extends TagRenamePlan {
  const TagRenameRename();
}

/// Another tag folds alike: the rename merges into it (BR-TAG-007).
final class TagRenameMerge extends TagRenamePlan {
  const TagRenameMerge({required this.target, required this.mergedCardCount});
  final TagCount target;       // its catalog row
  final int mergedCardCount;   // D6
}
```

**`planRename({tagId, name})`**, one read transaction, checks in this order:

1. `TagEntity.checkName(name)`: `blankName`, `nameTooLong` or `controlCharacter`.
2. The source is gone: `notFound`.
3. `name.trim()` equals the stored `name`: `TagRenameUnchanged`.
4. Another tag of the profile has `name_folded = fold(name)` (the source's own row is
   never a clash): `TagRenameMerge`, with the target's active count and the union count
   of D6.
5. Otherwise `TagRenameRename`.

**`renameTag({tagId, name, String? mergeIntoTagId})`**, one transaction, every check
before any write, the same order as the plan:

- `unchanged`: `Ok`, no write.
- `rename`: `UPDATE tags SET name = trim(name), name_folded = fold(name) WHERE id =
  tagId`. The `id` and every link stay (BR-TAG-006). A `mergeIntoTagId` is ignored: its
  target is gone and the name is free (D8).
- `merge` into T: when `mergeIntoTagId != T.id`, `Rejected(mergeNotConfirmed)` and no
  write (D5). Otherwise, in this order:
  1. `INSERT OR IGNORE INTO card_tags (card_id, tag_id) SELECT card_id, :target FROM
     card_tags WHERE tag_id = :source` — every card, in the Trash or not (D7);
  2. `DELETE FROM tags WHERE id = :source` — its links go by cascade.
  T's row is not written (BR-TAG-007). Each card trades the source for the target or
  loses a duplicate, so none gains a tag (BR-TAG-002).
- A failure anywhere rolls the whole transaction back and leaves as the `Failure` of
  `mapDatabaseError`: both tags and every link as before (UC-TAG-001 E4).

## 7. Delete

**`deleteTag({tagId})`**, one transaction: the tag gone is `notFound`; otherwise
`DELETE FROM tags WHERE id = :tagId`, and `card_tags` follows by cascade, the links of
cards in the Trash included (D9, BR-TAG-008). No card, deck, schedule, log or session is
written (BR-TAG-009). A failure rolls back (UC-TAG-001 E5).

## 8. The card list's tag filter (BE-C4)

- `CardListQuery` gains `final Set<String> tagIds`, default `const {}`.
- `CardListDao`:
  - `_tagged(Set<String> tagIds)`: `Constant(true)` for an empty set, the identity of
    BR-TAG-004; otherwise `existsQuery` of `SELECT 1 FROM card_tags WHERE card_id =
    card.id AND tag_id IN (…)`, one boolean per card;
  - `_predicate` becomes deck & search & filter & tags: the window and Select all;
  - `counts` takes the tag ids and counts All, Due, New and Flagged under the search and
    the tags;
  - `activeSchedules` (the status counts) and the workload stay deck-wide (D10);
  - `changes()` already listens to `card_tags` and `tags`.
- `CardRepositoryImpl` passes `query.tagIds` to the counts; `WatchCardListUseCase` and
  `SelectAllCardIdsUseCase` keep their signatures.

## 9. Use cases and the contract for the UI (FE-B2)

| Use case | Call |
|---|---|
| `WatchTagCatalogUseCase` | `Stream<List<TagCount>> call({String searchTerm = ''})` |
| `WatchDeckTagCountsUseCase` | `Stream<List<TagCount>> call({required String deckId})` |
| `PlanTagRenameUseCase` | `Future<Outcome<TagRenamePlan, TagRejection>> call({required String tagId, required String name})` |
| `RenameTagUseCase` | `Future<Outcome<void, TagRejection>> call({required String tagId, required String name, String? mergeIntoTagId})` |
| `DeleteTagUseCase` | `Future<Outcome<void, TagRejection>> call({required String tagId})` |

What FE-B2 can rely on:

- **Catalog** (screen 05): a blank search is every tag; `empty` is an empty list with a
  blank search, `searchEmpty` an empty list with a term. The header's count is the
  list's length.
- **Rename:** call the plan as the name changes; `TagRenameMerge` is `renameMerge`
  (target name, its count, the union count, the `Merge tags` verb); confirm with
  `mergeIntoTagId: target.id`. `mergeNotConfirmed` means the data moved: plan again and
  show what it says. `notFound` is `tagGone`; a `Failure` is `opError`.
- **Delete:** the confirmation's count is the row's `cardCount`; a tag with 0 needs no
  different wording (BR-TAG-008). `notFound` is `tagGone`.
- **Filter:** `WatchDeckTagCountsUseCase` feeds the overlay; the applied set goes into
  `CardListQuery.tagIds`. When a selected tag leaves the overlay's list (deleted or
  merged away), drop it from the selection; an id that no longer exists matches no
  card. Changing the set resets the window and clears the selection (BR-TAG-005).
- **Find cards with this tag:** the library search with the tag's name (D12).

## 10. Tests

Each rule has a test that fails when it breaks, on a real in-memory database.

- **Counts** (`test/features/tags/data/tag_counts_test.dart`): order by `name_folded`
  then `id`, Vietnamese names included; a tag with no card at 0; a card in the Trash not
  counted, and counted again once restored; the search finds `động từ` from `ĐỘNG TỪ`
  and not from `dong tu`; `%` in a term is a plain character; the deck scope counts that
  deck's cards and lists every tag; the stream re-emits on a tag write, a card delete, a
  restore and a card move.
- **Rename** (`tag_rename_test.dart`): the four outcomes of the plan and its refusals; a
  rename keeps `id` and links; `noun` → `Noun` is a rename; `hoc` → `Học` is a new name;
  a merge moves the links of active and trashed cards, collapses a card carrying both,
  deletes the source and leaves the target's row as it was; a card with 10 tags among
  them the source and the target keeps 9; the union count; `mergeNotConfirmed` writes
  nothing (`totalChanges`); a confirmed merge whose target vanished renames; a failure
  forced mid-merge rolls everything back; BR-TAG-009 by a snapshot of `card`,
  `card_schedule`, `review_log`, `deck` and the study tables before and after.
- **Delete** (`tag_delete_test.dart`): links of active and trashed cards go, the cards
  stay (snapshot); `notFound` writes nothing; a forced failure rolls back.
- **Use cases** (`test/features/tags/domain/tag_management_use_cases_test.dart`): each
  passes its arguments through.
- **Card list** (`test/features/card/data/card_list_tag_filter_test.dart`): OR between
  tags; AND with each status filter and with the search; a card carrying three selected
  tags appears once, counts once and takes one place in a window of `LIMIT n`; Select
  all returns the same set; an empty set gives exactly the unfiltered result; a gone id
  matches nothing.
- The BR-TRASH-002 check and the architecture tests pass with the new statements.

**Review Focus** (inputs the tests above pin, most likely to bite first):

1. A card in the Trash carries both tags of a merge, then comes back: it carries the
   target, once.
2. A rename that changes case only, and one that changes a diacritic: the first keeps the
   tag's identity, the second is a new name.
3. The plan said rename, and a tag with that folded name appeared before the write (the
   card editor made it): `mergeNotConfirmed`, nothing written.
4. A tag whose only cards are in the Trash (count 0) is deleted: those links go, and a
   restored card comes back without it.
5. The card list is filtered by a tag that is then merged away: it matches nothing, and
   the overlay's list no longer offers it.

## 11. Documents

- UC-TAG-001: `code:` names the five use cases and the card list's two; the scope line
  says the store is built (BE-B2); step 3's example becomes `ĐỘNG TỪ` and `động từ`
  (D4).
- The tags README and `schema.md` § `tags`: the scope lines say Tag Management's store
  is built; `tags.drift`'s comment likewise.
- `wbs_BE.md`: BE-B2 and BE-C4 done, the next step, traceability 18/22 UC.
- `wbs_FE.md`: FE-B2's row points at §9 and records the kit deviation of D6.
- `docs/_generated/` regenerated.

## 12. Out of scope

- FE-B2: screen 05, the filter overlay, the `Tags` action of the Library's app bar,
  navigation, and the UI half of BR-TAG-005.
- The import and export codec (BE-B3); BR-TAG-011's codec half is theirs.
- Tag suggestions in the card editor; tag colours or hierarchy (tags README).
- Profiles (`owner_id`), and a separate `Merge` action (BR-TAG-007 merges by rename).

## 13. Risks and rollback

- **A merge that loses a link.** `INSERT OR IGNORE` then the cascade is two statements
  in one transaction; the tests pin every link and the rollback.
- **Speed.** The count is a correlated subquery per tag over `idx_card_tags_tag`, fine
  for hundreds of tags; the filter's `EXISTS` walks the key `(card_id, tag_id)` per
  card. No new index.
- **The text check** is a heuristic (package 7 spec §15); the new statements carry the
  filter explicitly.
- **Rollback:** code and documents only, no schema: reverting the pull request restores
  the previous behaviour, and no data needs converting.
