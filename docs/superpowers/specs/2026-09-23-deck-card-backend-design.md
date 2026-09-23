# MemoX V8 — Deck and card backend design

Status: decisions approved in chat 2026-09-23 · spec awaiting review · Path: architectural

## 1. Intent

Build the backend of the `deck` and `card` features — `domain/`, `data/` and `di/`,
plus the parts of `srs` and `tags` they need — so that a parallel UI session can
build the deck and card screens against a stable contract. The backend does not
touch `presentation/`, `shared/`, `l10n/` or the theme. The one exception is
foundation Task 10, which the project owner chose to run as planned (D3).

Success means:

- every operation of UC-DECK-001…006 and UC-CARD-001…002 is reachable through one
  use case (AD-12, ADR-011 D4);
- every business rule those use cases cite is enforced in the domain or inside the
  writing transaction, and a test fails when the rule is broken;
- the phased gate of the root `README.md` passes after every task;
- no file outside the backend boundary of §12 changes, except foundation Task 10.

## 2. Context (2026-09-23)

- The foundation spec's decomposition (§2) puts deck/card CRUD at the start of
  sub-project 3, the core learning slice. This spec is the backend half of that
  part for deck and card.
- The foundation plan has run Task 1. Tasks 2–10 build core primitives, the SRS
  domain, the central schema, the deck, srs and card repositories, and the app
  shell. Its deck and card surface is: create a root deck or a sub-deck, move and
  delete a deck, find a deck by id; create and delete a card.
- The feature docs ask for more:

  | Missing from the foundation | Source |
  |---|---|
  | Rename a deck; change its scheduler; counts before delete | UC-DECK-002, BR-DECK-020, BR-DECK-023, BR-SRS-004 |
  | Deck list with progress, filters, sorts, search | UC-DECK-003, BR-STUDY-046/047/051/067/068, IT-DISC-001…007 |
  | Manual reorder of sibling decks | UC-DECK-006, BR-SRS-007 |
  | Edit, move, flag and bulk operations on cards | UC-CARD-001 A1/A5/A6/A7, BR-CARD-005/009/010/011/012 |
  | Tags on cards | UC-CARD-001 A6/A8, BR-TAG-001/002, ADR-009 decision 4 |
  | Card list with filters, counts, sort, search | UC-CARD-001, BR-STUDY-047, IT-ORG-001…006 |
  | Card detail and review history | UC-CARD-002, BR-CARD-013…019 |

- The foundation plan also has three gaps against the docs:
  - Task 7 does not say how `sibling_position` is assigned, and manual order
    depends on it (BR-SRS-007).
  - Task 8's `changeScheduler` only rewrites `deck.scheduler_type`. BR-SRS-004
    re-initializes the study state of the whole tree, and BR-STUDY-016 invalidates
    the tree's open sessions. Its `resetLearning` writes `eight_box` start values
    for every scheduler.
  - Task 9 creates a card without its `card_schedule` row and flags this as an
    open question. BR-CARD-004 and UC-CARD-001 step 4 already answer it: both rows
    are created in one transaction.
- A UI session, "Flutter UI base code architecture", works on branch
  `claude/flutter-ui-base-architecture-b55542`, started from `e4c5717`. It had not
  pushed when this spec was written.

## 3. Decisions

Chosen by the project owner on 2026-09-23.

| # | Topic | Decision | Rejected |
|---|---|---|---|
| D1 | Scope | Foundation Tasks 2–10, then the backend for every deck and card use case | the foundation only; write operations without read models |
| D2 | Contract for the UI | Use cases in `domain/usecases/`, one per interaction. The UI creates their providers in `presentation/providers/` | repositories only; the backend also writing `presentation/providers/` |
| D3 | Foundation Task 10 | Runs as planned: `lib/app/app.dart`, `lib/app/router/app_router.dart`, retry policy in `lib/main.dart` | leaving the app layer to the UI session |
| D4 | Tags | Attach and detach tags on cards (BR-TAG-001, BR-TAG-002). Tag Management (UC-TAG-001) stays a later sub-project | leaving tags to that sub-project |
| D5 | Staging | Two stages: the amended foundation plan, then a new plan for the rest of this spec | one merged plan; one vertical slice per UC |
| D6 | Where tag code lives | A `tags` feature with `domain/`, `data/`, `di/`; the Dart import map gains `card → tags` | inside `card` |
| D7 | Local midnight | The watching use cases re-emit at each local day start, from an injectable day clock in `lib/core/clock/` | a timer in the UI |
| D8 | Foundation amendments | Tasks 7, 8 and 9 (§4) | Task 9 only |
| D9 | Counting "characters" | Grapheme clusters, with `package:characters`, as Flutter's `maxLength` does | UTF-16 code units or code points |
| D10 | Loading the card list | A watched window `LIMIT n`; the UI grows `n` as it scrolls | keyset pages under a watch |
| D11 | Queries | Fixed read models as named `.drift` queries in `lib/core/database/queries/`; the dynamic card-list predicate built in Dart, in one function | everything in Dart; everything in `.drift` |

## 4. Stage 1 — amendments to the foundation plan

Made in `docs/superpowers/plans/2026-09-23-memox-v8-foundation.md` before its
Task 2 runs.

- **Start values (Task 8).** `CardScheduleState.initial(SchedulerType type, {required int generation})`,
  a static member added to `srs/domain/models/card_schedule_state_model.dart`
  (created in Task 3):
  - both schedulers: `learnedAt`, `dueAt`, `lastAnsweredAt` null,
    `answerCount = 0`, `lapseCount = 0`, the given `generation`;
  - `eight_box`: `currentBox = 1`;
  - `sm2`: `easeFactor = 2.5`, `intervalDays = 0`, `repetitions = 0`.
- **Sibling position (Task 7).** A new root deck or sub-deck, and a moved deck, go
  to the end of their sibling group. The group is the rows with the same
  `parent_id`, `NULL` for roots. The position is `max(sibling_position) + 1`, or
  `0` for the first child. The value is computed inside the writing transaction.
- **Scheduler writes (Task 8).**
  - `ScheduleRepository.initializeCard({required String cardId})` inserts the
    card's `card_schedule` row from `CardScheduleState.initial`, using the root's
    `scheduler_type` and `generation` read through `card.deck_id → deck.root_id`.
  - `changeScheduler` rejects a sub-deck with the new `SrsRejection.notARootDeck`,
    a missing deck with `notFound`, and a locked root with `schedulerLocked`. The
    root's own scheduler is accepted and writes nothing (UC-DECK-002 A4).
    Otherwise, in one transaction, it:
    - updates the root's `scheduler_type` and `scheduler_version`;
    - replaces every `card_schedule` row under the root with
      `CardScheduleState.initial(newType, generation: unchanged)` (BR-SRS-004);
    - sets every `in_progress` `study_session` of the root to `invalidated`, with
      `end_reason = 'scheduler_changed'` and `ended_at = now` (BR-STUDY-016).
  - `resetLearning` recreates the rows with `CardScheduleState.initial` for the
    root's actual scheduler. It also invalidates the root's `in_progress` sessions
    with `end_reason = 'scheduler_reset'` (BR-STUDY-015), which is the same
    mechanism.
- **Card creation (Task 9).** `CardRepositoryImpl.createCard` calls
  `ScheduleRepository.initializeCard` inside its own transaction (BR-CARD-004).
  The task's open question is removed, and Task 10's smoke test passes as written.

## 5. Stage 2 — structure

Every file sits in an ADR-011 bucket and appears with its first real content.

```
lib/core/clock/
├── day_clock.dart                    DayClock, SystemDayClock (§10)
└── di/day_clock_provider.dart
lib/core/database/queries/
├── deck_queries.drift                level aggregates, view, move targets, search, deletion summary
└── card_queries.drift                detail, history page, move targets
lib/features/tags/
├── domain/entities/tag_entity.dart   TagEntity + name rule, fold
├── domain/failures/tag_failure.dart  TagRejection
├── domain/repositories/tag_repository.dart
├── data/datasources/tag_dao.dart
├── data/repositories/tag_repository_impl.dart
└── di/tag_repository_provider.dart
lib/features/deck/domain/
├── models/                           deck level, schedule status, query, view, path, targets, …
└── usecases/                         the twelve deck use cases of §6
lib/features/card/domain/
├── models/                           draft, display status, list query and view, detail, history, targets
└── usecases/                         the twelve card use cases of §6
```

The deck and card `data/` and `di/` folders exist from the foundation. Stage 2
extends their DAOs and repository implementations.

The Dart import map in `test/architecture/boundary_rules.dart` becomes:

- `srs → ∅`
- `tags → ∅`
- `deck → {srs}`
- `card → {deck, srs, tags}`

The docs' `depends_on` of `tags` stays `[card]`. That graph is the data direction
and may differ from the import map (ADR-011 D2).

## 6. Use cases — the contract for the UI

A write returns `Future<Outcome<T, R>>`, where `R` is the feature's rejection
enum. A read returns a `Stream` fed by Drift's `watch()`, or one keyset page. A
bulk operation takes a `Set<String>` of ids and is all-or-nothing in one
transaction (BR-CARD-011). Each use case is a class named `<Name>UseCase`, in
`<name>_use_case.dart`, exposing `call`.

**Deck** — `lib/features/deck/domain/usecases/`

| Use case | Returns | Serves |
|---|---|---|
| `CreateRootDeck(name, schedulerType)` | `Outcome<DeckEntity, DeckRejection>` | UC-DECK-001 |
| `CreateSubDeck(parentId, name)` | `Outcome<DeckEntity, DeckRejection>` | UC-DECK-004, deck branch |
| `RenameDeck(deckId, name)` | `Outcome<void, DeckRejection>` | UC-DECK-002 |
| `ChangeDeckScheduler(rootDeckId, schedulerType)` | `Outcome<void, SrsRejection>` | UC-DECK-002, BR-SRS-002/004, BR-STUDY-016 |
| `GetDeckDeletionSummary(deckId)` | `Outcome<DeckDeletionSummary, DeckRejection>` | BR-DECK-023 |
| `DeleteDeck(deckId)` | `Outcome<void, DeckRejection>` | UC-DECK-002, BR-DECK-022 |
| `MoveDeck(deckId, newParentId)` | `Outcome<void, DeckRejection>` | UC-DECK-005 |
| `WatchDeckMoveTargets(deckId)` | `Stream<List<DeckMoveTarget>>` | UC-DECK-005 |
| `ReorderDeck(deckId, anchorId, placement)` | `Outcome<void, DeckRejection>` | UC-DECK-006, BR-SRS-007 |
| `WatchDeckLevel(parentId?, sort, filter)` | `Stream<DeckLevel>` | UC-DECK-003, IT-DISC-001…005, 008 |
| `WatchDeck(deckId)` | `Stream<Outcome<DeckView, DeckRejection>>` | an open deck: name, `content_type`, Create options, scheduler lock, breadcrumb |
| `SearchDecks(scopeDeckId?, term)` | `Stream<List<DeckSearchHit>>` | IT-DISC-006/007 |

**Card** — `lib/features/card/domain/usecases/`

| Use case | Returns | Serves |
|---|---|---|
| `CreateCard(deckId, draft)` | `Outcome<CardEntity, CardRejection>` | UC-CARD-001, UC-DECK-004 card branch, BR-CARD-004 |
| `EditCard(cardId, draft)` | `Outcome<void, CardRejection>` | UC-CARD-001 A1, BR-CARD-005 |
| `DeleteCards(cardIds)` | `Outcome<void, CardRejection>` | UC-CARD-001 A2 and A6 |
| `MoveCards(cardIds, targetDeckId)` | `Outcome<void, CardRejection>` | UC-CARD-001 A5 and A6, BR-CARD-010 |
| `WatchCardMoveTargets(sourceDeckId)` | `Stream<List<CardMoveTarget>>` | UC-CARD-001 A5 |
| `SetCardsFlagged(cardIds, flagged)` | `Outcome<void, CardRejection>` | UC-CARD-001 A6 and A7 |
| `AddTagToCards(cardIds, tagName)` | `Outcome<void, TagRejection>` | UC-CARD-001 A6 and A8 |
| `RemoveTagFromCards(cardIds, tagId)` | `Outcome<void, TagRejection>` | UC-CARD-001 A8 |
| `WatchCardList(deckId, query, windowSize)` | `Stream<CardListView>` | UC-CARD-001, BR-STUDY-047, IT-ORG-001…006 |
| `SelectAllCardIds(deckId, query)` | `Future<Set<String>>` | BR-CARD-012 |
| `WatchCardDetail(cardId)` | `Stream<Outcome<CardDetail, CardRejection>>` | UC-CARD-002, BR-CARD-013/014/019 |
| `LoadCardHistoryPage(cardId, cursor?)` | `Outcome<ReviewHistoryPage, CardRejection>` | BR-CARD-015…018 |

`CardDraft` holds `front`, `back`, `example`, `hint`, `pronunciation`,
`isFlagged` and `tagNames`: the add and edit forms carry the flag and the tags
(card `ui.md`).

**Tags** has no use case in this spec. Its `TagRepository` is called by the card
data layer inside the card's transaction, as the foundation's Task 9 calls
`DeckRepository`. The tag use cases come with Tag Management.

## 7. Domain rules and models

Each rule is a member of an entity or a value object (ADR-011 D7). Limits are
named constants on that type.

- **Validation.** "Characters" are grapheme clusters (D9). `characters` is already
  in `pubspec.lock` as a transitive dependency; `pubspec.yaml` lists it directly.
  - Deck name: not blank after trim, at most 200 (BR-DECK-020);
    `DeckEntity.checkName`.
  - Card: `front` and `back` not blank after trim (BR-CARD-001); `front` at most
    60, `back` at most 240 (BR-CARD-002); `example`, `hint`, `pronunciation` at
    most 240 each (BR-CARD-003); at most 10 distinct tag names (BR-TAG-002), each
    passing the tag name rule; `CardDraft.check`.
  - Tag name: not blank after trim, at most 50, no control character; unique by
    its folded form (BR-TAG-001); `TagEntity.checkName`, `TagEntity.fold`.
  - The folded form of a card side, a tag name or a search term is
    `trim()` then `toLowerCase()` in Dart, as `schema.md` defines `front_folded`.
- **Rejection reasons**, added to the foundation's enums:
  - `DeckRejection`: `nameTooLong`, `notSiblings` (reorder when the two decks no
    longer share a parent), `sameParent` (a move to the current parent).
  - `CardRejection`: `frontTooLong`, `backTooLong`, `optionalFieldTooLong`,
    `invalidTagName`, `tooManyTags`, `targetNotFound`, `targetIsRoot`,
    `targetHoldsDecks`, `sameDeck`, `crossRootMove`.
  - `SrsRejection`: `notARootDeck` (§4).
  - `TagRejection` (new): `blankName`, `nameTooLong`, `controlCharacter`,
    `tooManyTags`, `notFound`.
- **Create options.** `DeckEntity.createOptions` returns `{deck}` for a root,
  `{deck, card}` for an `unset` sub-deck, `{card}` for a `card` sub-deck and
  `{deck}` for a `deck` sub-deck (BR-DECK-005, BR-DECK-007, BR-DECK-012).
- **Card display status.** `CardDisplayStatus.of(CardScheduleState)` returns
  `newCard`, `beginning`, `reviewing` or `mastered` (BR-CARD-006…008,
  BR-SRS-013):
  - `learnedAt == null` gives `newCard`;
  - `eight_box`: box 8 is `mastered`, boxes 1–3 `beginning`, 4–7 `reviewing`;
  - `sm2`: `intervalDays >= 128` is `mastered`, below 8 `beginning`, 8…127
    `reviewing`.
- **Local day.** `startOfLocalDay(DateTime now)` sits next to `dueAtLocalMidnight`
  in `srs/domain/models/due_date_model.dart`. It is the single place that defines
  the start of today (BR-STUDY-068).
- **Deck schedule status.** `DeckScheduleStatus.of(oldestDueAt, startOfToday)`
  returns `notDue` when there is no Due card, `dueToday` when the oldest Due card
  falls on today, and `overdue` before today. `overdueDays` counts the completed
  local day boundaries between that card's `due_at` and today, not hours divided
  by 24 (BR-STUDY-067).

## 8. Read models

Every read filters `delete_batch_id IS NULL` on `deck` and `card`, so the Trash
sub-project does not have to revisit each query. `now` and `startOfToday` come
from Dart (§10) and reach the SQL as parameters (BR-STUDY-068).

- **New and Due** (BR-STUDY-047, BR-STUDY-051). New is `learned_at IS NULL`. Due
  is `learned_at IS NOT NULL AND due_at <= now`, with Overdue
  (`due_at < startOfToday`) and Due today (`due_at >= startOfToday`) as its two
  disjoint halves. Scheduled is `total − New − Due`.
- **A deck level** (`WatchDeckLevel`) reads in one statement.
  - For each tile, a child deck of `parentId` (or each root when `parentId` is
    null), it computes: cards in the subtree, New, Overdue, Due today, the oldest
    Due `due_at`, the number of direct sub-decks, and the root's scheduler.
  - The root level groups by `root_id`. A deeper level uses a recursive CTE
    anchored at each child.
  - The use case derives `DeckScheduleStatus` and `overdueDays` per tile, and the
    level summary: the sums of the four sets over the tiles, and the maximum of
    `overdueDays`.
  - Sorts: `manual` is `(sibling_position, id)`; `name` is by folded name; `recent`
    is `created_at DESC`; `due` is Due count descending, then manual order. The
    `due` filter keeps tiles with Due > 0. Sort and filter are pure functions in
    `domain/models/`. UC-DECK-006 also names a "progress" sort that no document
    defines; it is not built until one does.
- **An open deck** (`WatchDeck`) returns the deck, its root's scheduler,
  `isSchedulerLocked` (the root's `first_answered_at` is set, BR-SRS-003),
  `createOptions`, and the breadcrumb from the root to the parent. When the deck
  disappears it emits `Rejected(DeckRejection.notFound)`.
- **Deletion summary** counts the descendant decks and the cards in the subtree
  of the deck (BR-DECK-023).
- **Deck move targets** are active decks that are not the deck or one of its
  descendants, have `content_type` `deck` or `unset`, have a root with the same
  `scheduler_type` and `generation` as the deck's root, keep `depth + subtree
  height <= 10`, and are not the current parent. Each target carries its path
  from the root.
- **Deck search** matches the folded term as a substring of the folded name, with
  `instr`, inside the subtree of `scopeDeckId` or across all decks when it is null.
  Each hit carries its path from the root (IT-DISC-006).
- **The card list** (`WatchCardList`):
  - One Dart function builds the predicate from the deck, the filter
    (`all`, `due`, `newCards`, `flagged`) and the search term. The list, the counts
    and `SelectAllCardIds` all use it (BR-CARD-012). A tag predicate (BR-TAG-004)
    can be added there later without touching the three callers.
  - Search matches the folded term as a substring of `front_folded` or
    `back_folded` with `instr`, so no `LIKE` escaping is needed.
  - Sorts: `newest` is `(created_at DESC, id DESC)`; `dueFirst` is `due_at ASC`
    with New cards last, then `created_at DESC, id DESC`.
  - The window is `LIMIT windowSize + 1`; the extra row only sets `hasMore`.
  - The counts All, Due, New and Flagged come from one statement that applies the
    search term but not the filter (IT-ORG-005).
  - Each item carries `id`, `front`, `back`, `isFlagged`, `dueAt` and its
    `CardDisplayStatus`.
- **Card detail** (`WatchCardDetail`) returns the card content, flag, tags ordered
  by folded name, the full `CardScheduleState` of the card's scheduler and its
  display status (BR-CARD-014). It re-emits when the card, its schedule row or its
  tags change. When the card disappears it emits `Rejected(CardRejection.notFound)`
  (BR-CARD-019). Reading writes nothing (BR-CARD-013).
- **Review history** (`LoadCardHistoryPage`) reads `review_log` of the card by
  keyset on `(answered_at DESC, id DESC)`, 50 rows per page, in one statement, with
  no `OFFSET` (BR-CARD-015). Each entry carries the stored values of BR-CARD-016
  and its `generation`, and the UI groups by generation (BR-CARD-017). An empty
  page is a valid result (BR-CARD-018). The cursor is the last row's
  `(answered_at, id)`.
- **Card move targets** are the sub-decks of the same root with `content_type`
  `unset` or `card`, other than the source deck (BR-CARD-010).

## 9. Writes

Every write runs in one `db.transaction`. A rule that needs the data as it is at
write time is checked on rows read inside that transaction. A rejection writes
nothing.

- **Rename a deck.** Validate the name, then update `name` and `updated_at`.
- **Reorder.** Read the deck and the anchor again, both active. When they no
  longer share `parent_id`, reject `notSiblings`. Otherwise place the deck before
  or after the anchor and renumber the group `0…n−1`. Only rows whose position
  changed get a new `updated_at` (BR-SRS-007).
- **Move a deck.** The foundation's rules, plus `sameParent`. The deck goes to the
  end of the new sibling group (§4).
- **Create a card.** In one transaction:
  1. `CardDraft.check`, then the deck rules of the foundation (`checkCreateCard`);
  2. insert the card with its folded sides;
  3. `ScheduleRepository.initializeCard` (§4);
  4. `TagRepository.replaceForCard` with the draft's tag names;
  5. set the deck to `card` when it was `unset` (BR-DECK-008).
- **Edit a card.** `CardDraft.check`, then update the content, the folded sides,
  `is_flagged` and `updated_at`, and replace its tags. The schedule row and the
  review log are untouched (BR-CARD-005).
- **Delete cards.** Every id must exist, or the batch rejects `notFound`. Delete
  the rows; the schedule, log and tag links go by cascade. Every deck that lost
  its last card returns to `unset` (BR-DECK-015).
- **Move cards.** The target must exist, must not be a root, must be `unset` or
  `card`, and must differ from the source. Every card's deck must share the
  target's root; otherwise the batch rejects `crossRootMove`, even when two roots
  share a scheduler and a generation (BR-CARD-010). Update `deck_id` and
  `updated_at` only. Each source deck that is left empty returns to `unset`, and
  the target becomes `card` when it was `unset` (BR-DECK-015).
- **Set flagged.** An explicit value for the whole batch, never a toggle; updates
  `is_flagged` and `updated_at` (BR-CARD-011).
- **Tags.**
  - `attachByName` validates and folds the name, reuses the tag with that folded
    name or creates it, and links it to every card that lacks it (idempotent).
    When any card would exceed 10 tags, the batch rejects `tooManyTags`
    (BR-CARD-011, BR-TAG-002).
  - `detach` removes the links; a missing link is not an error, and a missing card
    rejects `notFound`.
  - `replaceForCard` makes the card's tags equal to the given names, with the same
    rules.

## 10. Day clock and streams

`lib/core/clock/day_clock.dart` declares
`abstract interface class DayClock { DateTime now(); Stream<DateTime> dayStarts(); }`.
The interface exists so that tests can substitute a fake, the reason ADR-010
accepts. `SystemDayClock` emits the start of each new local day from a one-shot
`Timer` re-armed after each emission. `dayClockProvider` lives in
`lib/core/clock/di/`.

`WatchDeckLevel` and `WatchCardList` start their repository watch with `now` and
`startOfLocalDay(now)`. On every `dayStarts` event they switch to a new watch with
fresh values (BR-STUDY-067, BR-STUDY-068). `due_at` always falls on a local
midnight (BR-STUDY-074), so the Due sets change only at those instants, and no
other refresh is needed.

## 11. Verification

- **Pure rules:** table tests at the limits (200/201, 60/61, 240/241, 50/51,
  10/11 tags) and with a grapheme cluster made of several code points.
- **Repositories:** real in-memory SQLite through `test/support/test_database.dart`.
  Every store rule has a test that breaks it and then proves nothing was written.
- **Use cases:** fakes of the repository contracts; the watching use cases get a
  fake `DayClock` whose `dayStarts` a test drives across midnight.
- **Statement counts:** the rules that demand one statement (a deck level, the card
  counts, a history page) are tested by counting statements with a Drift
  `QueryInterceptor`.
- **Gate:** the phased gate of the root `README.md` after every task. No
  `targets_pending` entry waits on stage 2.
- **Docs:** `code:` of UC-DECK-001…006 and UC-CARD-001…002 lists their use case
  files, and the `code:` of the deck, card and tags READMEs lists their backend
  folders. The READMEs lose the note that says the repo has no `lib/`.
  `tools/docs/generate.py` and `tools/docs/check.py` pass. The UI session adds its
  presentation paths later.

## 12. Coordination with the UI session

- **The backend owns:** `lib/core/{database,error,id,clock}/`,
  `lib/features/{srs,deck,card,tags}/{domain,data,di}/`, their tests, and
  `lib/core/database/queries/`.
- **Files both sessions may change**, to reconcile at merge time by keeping both
  sides: `lib/main.dart` and `lib/app/` (foundation Task 10), `pubspec.yaml`,
  `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`
  and `test/architecture/boundary_rules.dart`. The UI session's app shell
  supersedes Task 10's placeholder route.
- **What the UI consumes:** the use cases of §6, the models and rejection enums in
  the public domain buckets, the repository providers in `di/`, and
  `dayClockProvider`. It writes the use-case providers in `presentation/providers/`.

## 13. Out of scope

- `presentation/`, `shared/`, `l10n/` and the theme, apart from foundation Task 10.
- Tag Management (UC-TAG-001), the tag catalog and filtering the card list by tag
  (BR-TAG-004).
- The use case of Reset learning progress (UC-SRS-001); study sessions and review
  (UC-STUDY-*); starter decks; Trash; transfer; the global search feature;
  reminders; settings.
- Promoting a sub-deck to a root deck (the deck README's out-of-scope list).

## 14. Risks and rollback

- **Merge conflicts with the UI branch** in the shared files of §12. The backend's
  edits there are small and additive.
- **Read-model cost on deep trees.** One recursive CTE per level, backed by
  `idx_deck_parent_position` and `idx_deck_root_position`. The statement-count
  tests keep it to one query; `EXPLAIN QUERY PLAN` is the tool if a level is slow.
- **Timers in tests.** The day clock is injected, and no test waits on real time.
- **Rollback.** Each stage-2 task is its own commit. Reverting one removes its use
  cases and repository methods without touching the foundation.
