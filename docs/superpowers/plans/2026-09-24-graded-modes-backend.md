# MemoX V8 Graded Study Modes Backend Implementation Plan (package 2b)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build package 2b of [`docs/wbs_BE.md`](../../wbs_BE.md) — BE-D1, the
Drift migration test framework, with schema v2 as its first migration, and
BE-A10, the mechanics of the four graded study modes `fill`, `recall`, `guess`
and `match` (the rest of UC-STUDY-001) — as domain, data and di code with one
use case per interaction, so the UI session can build screens 17–20 of the kit
on it. No UI.

**Architecture:** Schema v2 adds `study_queue_items.hint_shown`,
`study_queue_items.meaning_slot` and the table `study_guess_options`.
`AppDatabase` upgrades v1 to v2 through a `stepByStep` step that works on the
versioned schema drift generates from the flat snapshots in `drift_schemas/`,
and `test/drift/migration_test.dart` proves the upgrade keeps every row. In
`study_mode`, each handler judges the person's real input as a pure function,
`judge(answer, TurnContext, scheduler)` → `TurnVerdict`, and says what a round
lacks before it is served (`prepareRound`): the five options of a `guess`
question, the meaning slots of a `match` board. In `study`,
`StudyRoundDataSource` builds and prepares the rounds of both writers;
`StudySessionRepository` reads a turn's facts in its transaction, judges,
records through srs with what the mode adds, swaps a `match` slot when a pair
takes another card's equal meaning, and returns `TurnResult`; three writes that
are not turns keep the `recall` reveal and time and the `fill` hint; and the
session screen's read moves to `StudySessionViewRepository`, which also shows
the question and the board.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35 and `drift_dev` (`schema dump`, `schema
steps`, `schema generate`). No dependency is added.

**Spec:** [`docs/superpowers/specs/2026-09-24-graded-modes-backend-design.md`](../specs/2026-09-24-graded-modes-backend-design.md),
approved 2026-09-24 and amended on this branch in `7726774` (the
Clarifications below). Business rules: `docs/features/{study,study-mode,srs}/rules/`;
scenarios: `docs/features/study/it-scenarios.md`; data model:
[`docs/shared/data/schema.md`](../../shared/data/schema.md); migration
workflow and rules: `.claude/skills/flutter-drift/references/migrations.md`.

**Prerequisite:** `claude/be-graded-modes` holds the spec (`10beb86`), its
amendments (`7726774`) and `master` up to `cf73f5e` (#48, merged in
`a338912`). This plan runs on that branch, from the commit that adds it; the
gate passes there with 1205 tests. Generated code is not committed: in a fresh working tree, run
`flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root
`README.md`, "Commands").

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed, and after every task the gate
passed. This document was then applied, step by step as written, the drift
commands included, onto a clean checkout of `a338912`: each task's files
matched the scratch commit's, no other file moved, and the suite counts below
are that run's. The "Expected" lines are the ones those runs produced.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme. Screens 17–20 and their controllers are
  FE-A6 (spec §1, §13).
- The import map does not change: `study_mode → {srs}`,
  `study → {study_mode, srs, settings, card}`, and `srs` stays `∅`. A feature
  never imports another feature's `data/` or `di/`.
- One dispatch (spec §7.7): `StudyMode` is switched on only in `study_mode.dart`
  (guard `single_study_mode_dispatch`); every question about a mode is a member of
  its handler: `judge`, `prepareRound`, `asksWithOptions`, `turnTimeMs`,
  `servesInOrder`.
- Judging is pure and happens in the domain: a handler judges from the answer
  and the `TurnContext` the session reads inside the turn's transaction; the UI
  never judges (spec D4, BR-STUDY-063).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing
  `call` (AD-12). A write returns `Future<Outcome<T, StudyRejection>>`.
- Every write is one transaction through the repository's `_write`
  (`mapDatabaseError`), which the srs call joins. A refusal writes nothing. The
  writes that are not turns write no `review_log` row and move no cursor (spec
  D10).
- The migration is additive and, once released, immutable: the v1 → v2 step
  adds two columns, one table and one index, rewrites no row, and works on the
  versioned schema of `schema_versions.dart`, never on today's tables (spec D6;
  the repo skill).
- `drift_schemas/drift_schema_v2.json`, `lib/core/database/schema_versions.dart`
  and `test/drift/generated/` are written by `drift_dev` and committed. `*.g.dart`
  and `lib/l10n/generated/` are not committed: after changing a `.drift` file or
  adding a `@riverpod` provider, run
  `dart run build_runner build --delete-conflicting-outputs`.
- `now` and `Random` are injected; no test reads the wall clock, and the study
  tests shuffle with a seeded `Random`.
- After every study scenario `expectStudyInvariants` runs every invariant query
  of `schema.md` in scope — 1–32 and, from Task 1, 38–40 — and checks that at
  most one session is `in_progress`.
- Drift writes that a watch must see go through the typed API or
  `customInsert` / `customUpdate` with `updates:`; a read of the session screen
  names every table it reads in `readsFrom`.
- After every task the phased gate of the root `README.md` passes, plus
  `tools/docs/check.py`. On Linux, `flutter test` runs with
  `--exclude-tags golden`: the goldens were made on Windows (FE-D1 in
  [`docs/wbs_FE.md`](../../wbs_FE.md)).
- The guard warns at 400 logical lines of a file and fails at 500: keep each
  file under the warning. `study_session_repository_impl.dart` ends at 395.
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- Contract files change only where the owner allowed it (spec D11): IT-MODE-008
  steps 3–4, the front and back of `S-STUDY-FILL-V2` and the one sentence of
  BR-STUDY-026's rationale that names `back_folded` (Task 6), and UC-STUDY-001's
  `code:` field (Task 7). No other BR or UC file changes.
- Code, identifiers, test names and commit messages are in English; `docs/`
  keeps its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan and showed
where it needed a change. Each is decided here, implemented as described, and
written into the spec in `7726774`; say so if one is wrong.

1. **`addColumn` is enough** (Task 1; spec §6.3). A fresh v2 database and an
   upgraded v1 one both validate against snapshot v2, so `study_queue_items`
   needs no `TableMigration`.
2. **The generated files** (Task 1; spec §5.1, §5.4). `schema generate` creates
   one directory level only, so the step makes `test/drift/generated/` first.
   The generated `schema_v1.dart` and `schema_v2.dart` report 19
   `strict_raw_type` warnings — a language option, which their
   `ignore_for_file: type=lint` does not cover — so `analysis_options.yaml`
   excludes `test/drift/generated/**`. The guard's two length rules exclude
   `schema_versions.dart` (1,366 logical lines), as they already excluded
   `test/drift/generated/**`.
3. **Invariant 40's test** (Task 1; spec §6.4). The primary key and `UNIQUE` of
   `study_guess_options` refuse a sixth option and a second right option, so
   the planted violation is a question that lost its right option, and the
   refused one writes slot 5.
4. **`isHintShown`** (Tasks 3, 5; spec §7.2, §9). The guard rule
   `memox.naming.boolean_reads_as_predicate` names the `fill` flag
   `isHintShown` in `TurnContext` and `StudyItem`; the column stays
   `hint_shown`.
5. **Expand, then contract** (Tasks 3, 6; spec §7.1, §7.2). Task 3 adds `judge`
   and the four answers beside package 2a's `actionOf` and `GradedAnswer`; Task
   6 moves the session to `judge` and removes both. Every task ends green.
6. **One data source builds and prepares rounds** (Task 4; spec §8.2).
   `StudyRoundDataSource` in `study/data/datasources/` (the guard's
   `_data_source` suffix) is shared by the entry and the session repositories,
   and package 2a's numbering of a later round moves into it. The entry
   repository gets a factory constructor, so its data source shuffles with the
   `Random` it is given.
7. **`turnTimeMs`** (Task 5; spec §7.7, §9). A third new handler member, 20000
   for `recall` and null otherwise, gives the view a row's time while the row
   stores none, so the mapper asks the handler instead of naming a mode.
8. **`remainingMs` out of range** (Task 5; spec §8.3) is refused with
   `RangeError.checkValueInInterval`, whose `RangeError` is an `ArgumentError`.
9. **The fault of IT-MODE-014** (Tasks 4, 6; spec §11) is a drift
   `QueryInterceptor` in `test/support/test_database.dart`, `ThinMeaningSource`,
   which cuts the meaning source's rows (the query that selects
   `AS meaning_folded`) while its `keep` is set. Production code has no seam for
   it.
10. **One `fill` submission is the row's** (Task 6; spec §11). After its one
    turn the row leaves; with the one card of `S-STUDY-FILL-V2`, a wrong answer
    sends the card to round 2, whose question is a new turn (BR-STUDY-059). The
    IT-MODE-011 test pins exactly that.
11. **The graded scenarios run on a review** (Task 6; spec §11) of learned, due
    cards: `insertFiveDue` makes the cards of `SETUP-STUDY-EB-5-FULL` once
    learned. A turn is judged the same way in a learning session.
12. **The READMEs keep their `code:` fields** (Task 7; spec §12): they already
    name the `study` and `study_mode` folders, which hold the new files. Only
    UC-STUDY-001's `code:` field changes.
13. **The write side stays whole** (Task 6; spec §8.5).
    `study_session_repository_impl.dart` ends at 395 logical lines, under the
    warning, so no further cut is made; the next change to it cuts first.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **A meaning already matched, tapped again** (a tap during the match
   animation): refused as `notOnBoard`, with nothing written — Task 6, "a
   meaning already matched is off the board".
2. **A card deleted while its pair is on the board**: the other pairs keep their
   tiles and the round ends without it — Task 6, "a card deleted while its pair
   is on the board".
3. **An answer on a question that lost an option to a deleted card, before
   Continue**: refused as `questionBlocked`, with nothing written; Continue then
   builds the question again — Task 6, "an answer on a question that lost an
   option".
4. **The last pair of a board**: the next board becomes the current one, and its
   pairs end the round — Task 6, "once every pair of a board is matched".
5. **A `recall` timeout whose write met a busy database**: the person's retry
   sends the same `timedOut`, which is recorded once with its reason
   (BR-STUDY-033) — Task 6, "a recall timeout that met a busy database".

## File Structure

```
lib/core/database/                                  (Task 1)
├── tables/study.drift                              hint_shown, meaning_slot, study_guess_options
├── app_database.dart                               schemaVersion 2, stepByStep(from1To2)
└── schema_versions.dart                            generated (schema steps), committed
drift_schemas/drift_schema_v2.json                  generated (schema dump), committed
test/drift/generated/{schema, schema_v1, schema_v2}.dart   generated (schema generate), committed
test/drift/migration_test.dart                      v1 → v2 keeps every row (Task 1)

lib/features/study_mode/domain/                     (Tasks 3, 5, 6)
├── models/study_answer_model.dart                  FillAnswer, RecallAnswer, GuessAnswer, MatchAnswer
├── models/turn_judgement_model.dart                TurnCard, TurnContext, OutcomeReason, TurnVerdict
├── models/round_preparation_model.dart             RoundRowFacts, MeaningCard, RoundPreparation
├── models/study_mode.dart                          judge, asksWithOptions, prepareRound, turnTimeMs
├── models/graded_mode.dart                         verdictOf, shared by the four
├── models/{fill, recall, guess, match}_mode.dart   each judges its input; guessOptionsFor,
│                                                   meaningSlotsFor, matchBoardOf
└── failures/study_mode_failure.dart                six new refusals

lib/features/srs/domain/models/review_turn_model.dart   outcomeReasonCode, comparisonVersion,
                                                        usedHint (Task 6)

lib/features/study/
├── domain/
│   ├── failures/study_failure.dart                 seven new refusals (3, 5)
│   ├── models/study_session_view_model.dart        GuessQuestion, MatchBoard, isHintShown (4, 5)
│   ├── models/turn_result_model.dart               TurnResult (6)
│   ├── repositories/study_session_view_repository.dart   watchSession (2)
│   ├── repositories/study_session_repository.dart  the three writes (5), TurnResult (6)
│   └── usecases/{reveal_recall_answer, save_recall_time, show_fill_hint}_use_case.dart   (5)
├── data/
│   ├── datasources/study_round_dao.dart            round facts, meaning source, slots, options (4)
│   ├── datasources/study_round_data_source.dart    builds and prepares rounds (4)
│   ├── datasources/{study_queue_dao, study_session_dao, study_view_dao}.dart   (4–6)
│   ├── mappers/study_session_view_mapper.dart      the question, the board, time, hint (4, 5)
│   └── repositories/                               the view repository (2); both writers
│                                                   prepare rounds (4); the turn judges (6)
└── di/study_session_view_repository_provider.dart  (2)

test/support/{study_fixtures, test_database, card_fixtures, invariant_queries}.dart
```

Other changed files: `analysis_options.yaml` and the guard's
`overrides.yaml` (Task 1); the docs `schema.md` and the flutter-drift skill (1),
`features/study/data.md` (4, 5), IT-MODE-008, `S-STUDY-FILL-V2` and BR-STUDY-026
(6), UC-STUDY-001 and `wbs_BE.md` (7).

---


### Task 1: Schema v2, the first migration and its test (BE-D1)

**Files:**
- Modify: `.claude/skills/flutter-drift/references/migrations.md`, `analysis_options.yaml`, `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`, `lib/core/database/app_database.dart`, `lib/core/database/tables/study.drift`, `docs/shared/data/schema.md`
- Test (create): `test/drift/migration_test.dart`
- Test (modify): `test/database/invariants_test.dart`, `test/support/invariant_queries.dart`
- Generate with `drift_dev`, and commit: `drift_schemas/drift_schema_v2.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema.dart`, `test/drift/generated/schema_v1.dart`, `test/drift/generated/schema_v2.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed)

**Interfaces:**
- Consumes: `AppDatabase` and its `beforeOpen`; the invariant parser of
  `test/support/invariant_queries.dart`; `drift_schemas/drift_schema_v1.json`;
  `drift_dev` (already a dev dependency).
- Produces:
  - `study_queue_items.hint_shown INTEGER NOT NULL DEFAULT 0` and
    `study_queue_items.meaning_slot INTEGER`, on the Drift row as
    `StudyQueueItem.hintShown` (`int`) and `.meaningSlot` (`int?`).
  - The table `study_guess_options` (row class `StudyGuessOption`, table
    `db.studyGuessOptions`) and its index `idx_study_guess_options_option`.
  - `AppDatabase.schemaVersion == 2`, upgrading through
    `stepByStep(from1To2: …)` from `lib/core/database/schema_versions.dart`.
  - `test/drift/generated/schema.dart` (`GeneratedHelper`) with `schema_v1.dart`
    and `schema_v2.dart`, for `SchemaVerifier`.
  - Invariants 38–40 in `schema.md`, run by `invariants_test.dart` and
    `expectStudyInvariants`.

Spec §5, §6 and D5, D6; Clarifications 1–3. The test comes first,
then the schema and the generated files; the migration test then shows the
upgrade step missing before the step is written. A v1 database is seeded with
raw SQL through `schema.rawDatabase`: opening it through `AppDatabase` would
migrate it before the test reads its rows.

- [ ] **Step 1: Write the failing tests**

In `test/support/invariant_queries.dart`:

Replace

```dart

/// Invariant queries 1-32 of `docs/shared/data/schema.md` ("Bất biến"), read
/// from the document itself: the tests run exactly what the data model states,
/// and there is no copy to keep in step. Each query must return no row.
/// Invariants 33-37 need `delete_batches`, which does not exist yet
/// (foundation plan, Clarification 2).
final Map<int, String> invariantQueries = parseInvariantQueries(
```

with

```dart

/// The invariant queries of `docs/shared/data/schema.md` ("Bất biến"), read
/// from the document itself: the tests run exactly what the data model states,
/// and there is no copy to keep in step. Each query must return no row.
final Map<int, String> invariantQueries = parseInvariantQueries(
```

Replace

```dart

const _lastInvariantInScope = 32;

```

with

```dart

/// Invariants 33-37 need `delete_batches`, which does not exist yet
/// (foundation plan, Clarification 2; the Trash, BE-B1).
const _waitingForDeleteBatches = {33, 34, 35, 36, 37};

```

Replace

```dart
    final number = int.parse(headers[i].group(1)!);
    if (number > _lastInvariantInScope) continue;
    final end = i + 1 < headers.length ? headers[i + 1].start : sql.length;
```

with

```dart
    final number = int.parse(headers[i].group(1)!);
    if (_waitingForDeleteBatches.contains(number)) continue;
    final end = i + 1 < headers.length ? headers[i + 1].start : sql.length;
```

Replace

```dart
  32: "a turn carries the direction of its queue row (BR-MODE-016)",
};
```

with

```dart
  32: "a turn carries the direction of its queue row (BR-MODE-016)",
  38: "hint_shown appears only on fill (BR-STUDY-028)",
  39: "a meaning slot appears only on match, once per board (BR-STUDY-049)",
  40: "a guess question keeps its one right option (BR-STUDY-037)",
};
```

In `test/database/invariants_test.dart`:

Replace

```dart

/// Rows that satisfy all 32 invariants: three trees (eight_box, sm2, empty),
/// learned and new cards, three sessions (completed, open, invalidated) with
/// queue rows in four modes, and review turns of all three kinds.
const _seed = <String>[
```

with

```dart

/// Rows that satisfy every invariant in scope: three trees (eight_box, sm2,
/// empty), learned and new cards, three sessions (completed, open,
/// invalidated) with queue rows in five modes, a guess question with its five
/// options, and review turns of all three kinds.
const _seed = <String>[
```

Replace

```dart
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('C', 'C', NULL, 'C', 1, 'deck', 'eight_box', 1, 1, 2, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c1', 'A1', 'f', 'b', 0, 0), ('c2', 'A1', 'f', 'b', 0, 0), ('c3', 'A2a', 'f', 'b', 0, 0), ('c4', 'B1', 'f', 'b', 0, 0)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, current_box) VALUES ('c1', 'eight_box', 1, 1, 100, 200, 121, 1, 0, 3)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) VALUES ('c2', 'eight_box', 1, 1, 1), ('c3', 'eight_box', 1, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, ease_factor, interval_days, repetitions) VALUES ('c4', 'sm2', 1, 2, 2.5, 0, 0)",
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, end_reason, direction, started_at, ended_at) VALUES ('s1', 'A1', 'A', 1, 'learning', 'match', 'completed', NULL, NULL, 90, 150), ('s2', 'A', 'A', 1, 'reviewing', 'self_assess', 'in_progress', NULL, 'mixed', 110, NULL), ('s3', 'B', 'B', 2, 'reviewing', 'recall', 'invalidated', 'scheduler_reset', NULL, 280, 300)",
  "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status, answers_in_session, remaining_ms, is_revealed, direction) VALUES ('s1', 'self_assess', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL), ('s1', 'self_assess', 1, 'c2', 1, 'completed', 1, NULL, 0, NULL), ('s1', 'match', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL), ('s1', 'match', 1, 'c2', 1, 'completed', 2, NULL, 0, NULL), ('s1', 'match', 2, 'c2', 0, 'completed', 1, NULL, 0, NULL), ('s1', 'recall', 1, 'c1', 0, 'completed', 1, 20000, 1, NULL), ('s1', 'fill', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL), ('s2', 'self_assess', 1, 'c1', 0, 'pending', 2, NULL, 0, 'korean_to_meaning')",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('l1', 'c1', 's1', 'eight_box', 1, 'learning', 'self_assess', NULL, 'remembered', 100, 1, 2), ('l3', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'korean_to_meaning', 'remembered', 120, 2, 3), ('l4', 'c1', 's2', 'eight_box', 1, 'relearning', 'self_assess', 'korean_to_meaning', 'forgotten', 121, 3, 3)",
```

with

```dart
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, sibling_position, created_at, updated_at) VALUES ('C', 'C', NULL, 'C', 1, 'deck', 'eight_box', 1, 1, 2, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, created_at, updated_at) VALUES ('c1', 'A1', 'f', 'b', 0, 0), ('c2', 'A1', 'f', 'b', 0, 0), ('c3', 'A2a', 'f', 'b', 0, 0), ('c4', 'B1', 'f', 'b', 0, 0), ('c5', 'A1', 'f', 'b', 0, 0), ('c6', 'A1', 'f', 'b', 0, 0)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, current_box) VALUES ('c1', 'eight_box', 1, 1, 100, 200, 121, 1, 0, 3)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, current_box) VALUES ('c2', 'eight_box', 1, 1, 1), ('c3', 'eight_box', 1, 1, 1), ('c5', 'eight_box', 1, 1, 1), ('c6', 'eight_box', 1, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, ease_factor, interval_days, repetitions) VALUES ('c4', 'sm2', 1, 2, 2.5, 0, 0)",
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, end_reason, direction, started_at, ended_at) VALUES ('s1', 'A1', 'A', 1, 'learning', 'match', 'completed', NULL, NULL, 90, 150), ('s2', 'A', 'A', 1, 'reviewing', 'self_assess', 'in_progress', NULL, 'mixed', 110, NULL), ('s3', 'B', 'B', 2, 'reviewing', 'recall', 'invalidated', 'scheduler_reset', NULL, 280, 300)",
  "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status, answers_in_session, remaining_ms, is_revealed, direction, hint_shown, meaning_slot) VALUES ('s1', 'self_assess', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 0, NULL), ('s1', 'self_assess', 1, 'c2', 1, 'completed', 1, NULL, 0, NULL, 0, NULL), ('s1', 'match', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 0, 1), ('s1', 'match', 1, 'c2', 1, 'completed', 2, NULL, 0, NULL, 0, 0), ('s1', 'match', 2, 'c2', 0, 'completed', 1, NULL, 0, NULL, 0, 0), ('s1', 'guess', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 0, NULL), ('s1', 'recall', 1, 'c1', 0, 'completed', 1, 20000, 1, NULL, 0, NULL), ('s1', 'fill', 1, 'c1', 0, 'completed', 1, NULL, 0, NULL, 1, NULL), ('s2', 'self_assess', 1, 'c1', 0, 'pending', 2, NULL, 0, 'korean_to_meaning', 0, NULL)",
  "INSERT INTO study_guess_options (session_id, round, card_id, slot, option_card_id) VALUES ('s1', 1, 'c1', 0, 'c5'), ('s1', 1, 'c1', 1, 'c3'), ('s1', 1, 'c1', 2, 'c1'), ('s1', 1, 'c1', 3, 'c6'), ('s1', 1, 'c1', 4, 'c2')",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, previous_box, next_box) VALUES ('l1', 'c1', 's1', 'eight_box', 1, 'learning', 'self_assess', NULL, 'remembered', 100, 1, 2), ('l3', 'c1', 's2', 'eight_box', 1, 'scheduled', 'self_assess', 'korean_to_meaning', 'remembered', 120, 2, 3), ('l4', 'c1', 's2', 'eight_box', 1, 'relearning', 'self_assess', 'korean_to_meaning', 'forgotten', 121, 3, 3)",
```

Replace

```dart
  30: ["UPDATE deck SET first_answered_at = NULL WHERE id = 'A'"],
  32: [
```

with

```dart
  30: ["UPDATE deck SET first_answered_at = NULL WHERE id = 'A'"],
  39: [
    "UPDATE study_queue_items SET meaning_slot = 1 WHERE session_id = 's1' AND mode = 'match' AND round = 1 AND card_id = 'c2'",
  ],
  40: [
    "DELETE FROM study_guess_options WHERE session_id = 's1' AND option_card_id = 'c1'",
  ],
  32: [
```

Replace

```dart
  31: "UPDATE study_session SET direction = 'mixed' WHERE id = 's1'",
};
```

with

```dart
  31: "UPDATE study_session SET direction = 'mixed' WHERE id = 's1'",
  38: "UPDATE study_queue_items SET hint_shown = 1 WHERE session_id = 's1' AND mode = 'match'",
  39: "UPDATE study_queue_items SET meaning_slot = 0 WHERE session_id = 's2'",
  40: "INSERT INTO study_guess_options (session_id, round, card_id, slot, option_card_id) VALUES ('s1', 1, 'c1', 5, 'c4')",
};
```

Replace

```dart

  test('schema.md states invariants 1 to 32', () {
    expect(
      invariantQueries.keys,
      unorderedEquals([for (var n = 1; n <= 32; n++) n]),
    );
```

with

```dart

  test('schema.md states invariants 1 to 32 and 38 to 40', () {
    expect(
      invariantQueries.keys,
      unorderedEquals([for (var n = 1; n <= 32; n++) n, 38, 39, 40]),
    );
```

Create `test/drift/migration_test.dart`:

```dart
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/invariant_queries.dart';
import 'generated/schema.dart';

// BE-D1: every schema version upgrades to the current one, with its rows and
// their values intact (spec §5.3; .claude/skills/flutter-drift/references/
// migrations.md).

/// A v1 database a person could have: two trees, learned and new cards, three
/// ended sessions and one open in `guess`, and turns of every kind, the
/// `recall` and `fill` ones with their own columns.
const _v1Rows = <String>[
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, first_answered_at, study_config, sibling_position, created_at, updated_at) VALUES ('R', 'Korean', NULL, 'R', 1, 'deck', 'eight_box', 1, 1, 100, '{\"cardLimit\": 10}', 0, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, scheduler_type, scheduler_version, generation, first_answered_at, sibling_position, created_at, updated_at) VALUES ('S', 'Verbs', NULL, 'S', 1, 'deck', 'sm2', 1, 1, 100, 1, 0, 0)",
  "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, sibling_position, created_at, updated_at) VALUES ('R1', 'Food', 'R', 'R', 2, 'card', 0, 0, 0), ('S1', 'Motion', 'S', 'S', 2, 'card', 0, 0, 0)",
  "INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, example, hint, created_at, updated_at) VALUES ('k1', 'R1', '밥', 'Cơm', '밥', 'cơm', 'Tôi ăn cơm.', NULL, 1, 1), ('k2', 'R1', '물', 'Nước', '물', 'nước', NULL, NULL, 2, 2), ('k3', 'R1', '빵', 'Bánh mì', '빵', 'bánh mì', 'Bánh mì nóng.', 'Bắt đầu bằng B', 3, 3), ('k4', 'R1', '차', 'Trà', '차', 'trà', NULL, NULL, 4, 4), ('k5', 'R1', '국', 'Canh', '국', 'canh', NULL, NULL, 5, 5), ('k6', 'R1', '김치', 'Kim chi', '김치', 'kim chi', NULL, NULL, 6, 6), ('m1', 'S1', '가다', 'Đi', '가다', 'đi', NULL, NULL, 7, 7)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, current_box) VALUES ('k1', 'eight_box', 1, 1, 100, 900, 420, 6, 1, 3), ('k2', 'eight_box', 1, 1, 100, 800, 140, 5, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, answer_count, current_box) VALUES ('k3', 'eight_box', 1, 1, 1, 1), ('k4', 'eight_box', 1, 1, 1, 1), ('k5', 'eight_box', 1, 1, 1, 1), ('k6', 'eight_box', 1, 1, 1, 1)",
  "INSERT INTO card_schedule (card_id, scheduler_type, scheduler_version, generation, learned_at, due_at, last_answered_at, answer_count, lapse_count, ease_factor, interval_days, repetitions) VALUES ('m1', 'sm2', 1, 1, 100, 700, 310, 3, 0, 2.5, 6, 2)",
  "INSERT INTO tags (id, name, name_folded, created_at) VALUES ('t1', 'Món ăn', 'món ăn', 0)",
  "INSERT INTO card_tags (card_id, tag_id) VALUES ('k1', 't1')",
  "INSERT INTO study_session (id, deck_id, root_id, generation, session_kind, current_mode, status, end_reason, direction, cursor, card_limit, started_at, ended_at) VALUES ('learned', 'R', 'R', 1, 'learning', 'fill', 'completed', NULL, NULL, 12, 20, 90, 150), ('review', 'R', 'R', 1, 'reviewing', 'recall', 'completed', NULL, NULL, 1, 20, 400, 450), ('sm2', 'S', 'S', 1, 'reviewing', 'self_assess', 'completed', NULL, 'mixed', 1, 20, 300, 320), ('open', 'R', 'R', 1, 'learning', 'guess', 'in_progress', NULL, NULL, 8, 20, 1000, NULL)",
  "INSERT INTO study_queue_items (session_id, mode, round, card_id, position, status, available_at, answers_in_session, remaining_ms, is_revealed, direction) VALUES "
      "('learned', 'browse', 1, 'k1', 0, 'completed', 0, 0, NULL, 0, NULL), ('learned', 'browse', 1, 'k2', 1, 'completed', 0, 0, NULL, 0, NULL), "
      "('learned', 'match', 1, 'k2', 0, 'completed', 0, 1, NULL, 0, NULL), ('learned', 'match', 1, 'k1', 1, 'completed', 0, 1, NULL, 0, NULL), "
      "('learned', 'guess', 1, 'k1', 0, 'completed', 0, 1, NULL, 0, NULL), ('learned', 'guess', 1, 'k2', 1, 'completed', 0, 1, NULL, 0, NULL), "
      "('learned', 'recall', 1, 'k2', 0, 'completed', 0, 1, 0, 0, NULL), ('learned', 'recall', 1, 'k1', 1, 'completed', 0, 1, 7400, 1, NULL), "
      "('learned', 'recall', 2, 'k2', 0, 'completed', 0, 1, 11200, 1, NULL), ('learned', 'fill', 1, 'k1', 0, 'completed', 0, 1, NULL, 0, NULL), "
      "('review', 'recall', 1, 'k1', 0, 'completed', 0, 1, 15000, 1, NULL), "
      "('sm2', 'self_assess', 1, 'm1', 0, 'completed', 0, 1, NULL, 0, 'korean_to_meaning'), "
      "('open', 'browse', 1, 'k3', 0, 'completed', 0, 0, NULL, 0, NULL), ('open', 'browse', 1, 'k4', 1, 'completed', 0, 0, NULL, 0, NULL), "
      "('open', 'browse', 1, 'k5', 2, 'completed', 0, 0, NULL, 0, NULL), ('open', 'browse', 1, 'k6', 3, 'completed', 0, 0, NULL, 0, NULL), "
      "('open', 'match', 1, 'k5', 0, 'completed', 0, 1, NULL, 0, NULL), ('open', 'match', 1, 'k3', 1, 'completed', 0, 1, NULL, 0, NULL), "
      "('open', 'match', 1, 'k6', 2, 'completed', 0, 1, NULL, 0, NULL), ('open', 'match', 1, 'k4', 3, 'completed', 0, 1, NULL, 0, NULL), "
      "('open', 'guess', 1, 'k4', 0, 'pending', 0, 0, NULL, 0, NULL), ('open', 'guess', 1, 'k6', 1, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'guess', 1, 'k3', 2, 'pending', 0, 0, NULL, 0, NULL), ('open', 'guess', 1, 'k5', 3, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'recall', 1, 'k6', 0, 'pending', 0, 0, NULL, 0, NULL), ('open', 'recall', 1, 'k3', 1, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'recall', 1, 'k5', 2, 'pending', 0, 0, NULL, 0, NULL), ('open', 'recall', 1, 'k4', 3, 'pending', 0, 0, NULL, 0, NULL), "
      "('open', 'fill', 1, 'k3', 0, 'pending', 0, 0, NULL, 0, NULL)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, \"action\", answered_at, next_due_at, previous_box, next_box) VALUES "
      "('l1', 'k2', 'learned', 'eight_box', 1, 'learning', 'match', 'remembered', 100, NULL, 1, 1), ('l2', 'k1', 'learned', 'eight_box', 1, 'learning', 'match', 'remembered', 101, NULL, 1, 1), "
      "('l3', 'k1', 'learned', 'eight_box', 1, 'learning', 'guess', 'remembered', 102, NULL, 1, 1), ('l4', 'k2', 'learned', 'eight_box', 1, 'learning', 'guess', 'remembered', 103, NULL, 1, 1), "
      "('l6', 'k1', 'learned', 'eight_box', 1, 'learning', 'recall', 'remembered', 105, NULL, 1, 1), ('l7', 'k2', 'learned', 'eight_box', 1, 'relearning', 'recall', 'remembered', 106, NULL, 1, 1), "
      "('l9', 'k1', 'review', 'eight_box', 1, 'scheduled', 'recall', 'remembered', 420, 900, 2, 3), "
      "('l10', 'k5', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1001, NULL, 1, 1), ('l11', 'k3', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1002, NULL, 1, 1), "
      "('l12', 'k6', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1003, NULL, 1, 1), ('l13', 'k4', 'open', 'eight_box', 1, 'learning', 'match', 'remembered', 1004, NULL, 1, 1)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, outcome_reason, \"action\", answered_at, previous_box, next_box) VALUES ('l5', 'k2', 'learned', 'eight_box', 1, 'learning', 'recall', 'timeout', 'forgotten', 104, 1, 1)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, comparison_version, used_hint, \"action\", answered_at, previous_box, next_box) VALUES ('l8', 'k1', 'learned', 'eight_box', 1, 'learning', 'fill', 1, 0, 'remembered', 107, 1, 1)",
  "INSERT INTO review_log (id, card_id, session_id, scheduler_type, generation, kind, mode, direction, \"action\", answered_at, next_due_at, previous_ease_factor, next_ease_factor, previous_interval_days, next_interval_days) VALUES ('l14', 'm1', 'sm2', 'sm2', 1, 'scheduled', 'self_assess', 'korean_to_meaning', 'good', 310, 700, 2.5, 2.5, 1, 6)",
  "INSERT INTO app_settings (id, card_limit, new_card_order, theme_mode, language, updated_at) VALUES (1, 15, 'random', 'dark', 'vi', 5)",
];

/// The tables of v1, whose rows the upgrade must keep as they are.
const _v1Tables = [
  'deck',
  'card',
  'card_schedule',
  'tags',
  'card_tags',
  'study_session',
  'study_queue_items',
  'review_log',
  'app_settings',
];

/// The columns v2 adds to v1's tables (spec §6.1).
const _v2Columns = {'hint_shown', 'meaning_slot'};

/// A row as text, its columns in name order, so two reads compare as sets.
String _canonical(Map<String, Object?> row) =>
    ([...row.keys]..sort()).map((column) => '$column=${row[column]}').join('|');

/// [rows] as text without v2's columns, in a stable order.
List<String> _v1Values(Iterable<Map<String, Object?>> rows) => [
  for (final row in rows)
    _canonical({
      for (final MapEntry(:key, :value) in row.entries)
        if (!_v2Columns.contains(key)) key: value,
    }),
]..sort();

void main() {
  late SchemaVerifier verifier;
  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test('v1 upgrades to the schema of v2', () async {
    final db = AppDatabase(await verifier.startAt(1));
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 2);
  });

  test(
    'a new database has the schema of v2, the one an upgrade ends at',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
    },
  );

  group('a v1 database with rows', () {
    late AppDatabase db;
    late Map<String, List<String>> before;

    setUp(() async {
      final schema = await verifier.schemaAt(1);
      for (final statement in _v1Rows) {
        schema.rawDatabase.execute(statement);
      }
      before = {
        for (final table in _v1Tables)
          table: _v1Values(schema.rawDatabase.select('SELECT * FROM $table')),
      };
      db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 2);
    });
    tearDown(() => db.close());

    test('keeps every row of v1 with its values', () async {
      for (final table in _v1Tables) {
        final after = await db.customSelect('SELECT * FROM $table').get();
        expect(
          _v1Values([for (final row in after) row.data]),
          before[table],
          reason: table,
        );
      }
      expect(before['study_queue_items'], hasLength(29));
      expect(before['review_log'], hasLength(14));
    });

    test('gives the new columns their defaults and adds no option', () async {
      final queue = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM study_queue_items'
            ' WHERE hint_shown = 0 AND meaning_slot IS NULL',
          )
          .getSingle();
      expect(queue.read<int>('n'), 29);
      final options = await db
          .customSelect('SELECT COUNT(*) AS n FROM study_guess_options')
          .getSingle();
      expect(options.read<int>('n'), 0);
    });

    test('still holds every invariant of schema.md', () async {
      for (final MapEntry(key: number, value: query)
          in invariantQueries.entries) {
        expect(
          await db.customSelect(query).get(),
          isEmpty,
          reason: 'invariant $number: ${invariantSummaries[number]}',
        );
      }
    });

    test('passes the integrity and foreign key checks', () async {
      final integrity = await db.customSelect('PRAGMA integrity_check').get();
      expect([for (final row in integrity) row.data.values.single], ['ok']);
      expect(await db.customSelect('PRAGMA foreign_key_check').get(), isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/database/invariants_test.dart \
  test/drift/migration_test.dart
```

Expected: `+0 -73: Some tests failed.` The migration test does not compile: its generated helpers do not exist yet. Every test of `invariants_test.dart` fails on `table study_queue_items has no column named hint_shown`. The first errors: `Error: Error when reading 'test/drift/generated/schema.dart': No such file or directory`, `Error: Method not found: 'GeneratedHelper'.`

- [ ] **Step 3: Add the v2 schema**

In `lib/core/database/app_database.dart`:

Replace

```dart
  @override
  int get schemaVersion => 1;

```

with

```dart
  @override
  int get schemaVersion => 2;

```

In `lib/core/database/tables/study.drift`:

Replace

```sql
  direction TEXT CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')),
  PRIMARY KEY (session_id, mode, round, card_id),
```

with

```sql
  direction TEXT CHECK (direction IS NULL OR direction IN ('korean_to_meaning', 'meaning_to_korean')),
  -- v2, fill only: the hint of the turn in progress was shown (BR-STUDY-028,
  -- invariant 38).
  hint_shown INTEGER NOT NULL DEFAULT 0
    CHECK (hint_shown IN (0, 1) AND (mode = 'fill' OR hint_shown = 0)),
  -- v2, match only: the slot of this card's meaning on its board
  -- (BR-STUDY-049, invariant 39).
  meaning_slot INTEGER
    CHECK (meaning_slot IS NULL OR (mode = 'match' AND meaning_slot BETWEEN 0 AND 4)),
  PRIMARY KEY (session_id, mode, round, card_id),
```

Replace

```sql
CREATE INDEX idx_study_queue_pending ON study_queue_items (session_id, status, available_at, position);
```

with

```sql
CREATE INDEX idx_study_queue_pending ON study_queue_items (session_id, status, available_at, position);

-- v2: the five options of a guess question, in the order shown (BR-STUDY-037,
-- BR-STUDY-043). A question with fewer rows is blocked (BR-STUDY-040). `mode`
-- exists for the foreign key: an option belongs to a guess row and goes with it.
CREATE TABLE study_guess_options (
  session_id TEXT NOT NULL,
  mode TEXT NOT NULL DEFAULT 'guess' CHECK (mode = 'guess'),
  round INTEGER NOT NULL,
  card_id TEXT NOT NULL,
  slot INTEGER NOT NULL CHECK (slot BETWEEN 0 AND 4),
  option_card_id TEXT NOT NULL REFERENCES card (id) ON DELETE CASCADE,
  PRIMARY KEY (session_id, mode, round, card_id, slot),
  UNIQUE (session_id, mode, round, card_id, option_card_id),
  FOREIGN KEY (session_id, mode, round, card_id)
    REFERENCES study_queue_items (session_id, mode, round, card_id) ON DELETE CASCADE
) AS StudyGuessOption;

CREATE INDEX idx_study_guess_options_option ON study_guess_options (option_card_id);
```

- [ ] **Step 4: Generate the database code, the v2 snapshot and the migration helpers**

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
mkdir -p test/drift/generated
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

Expected: `build_runner` prints `Built with build_runner` (it warns that `--delete-conflicting-outputs` is ignored); `schema dump` prints `Wrote to drift_schemas/drift_schema_v2.json`; `schema steps` prints nothing and writes `lib/core/database/schema_versions.dart`; `schema generate` prints `Wrote 3 files into test/drift/generated` (`schema.dart`, `schema_v1.dart`, `schema_v2.dart`; Clarification 2).

- [ ] **Step 5: Keep the analyzer and the guard off the generated files**

In `analysis_options.yaml`:

Replace

```yaml
    - "**/*.g.dart"
    - build/**
```

with

```yaml
    - "**/*.g.dart"
    # drift's migration test helpers (`schema generate`), which nobody edits.
    - test/drift/generated/**
    - build/**
```

In `code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml`:

Replace

```yaml
        - lib/l10n/**
        # drift's migration helper. Committed because a released schema cannot
        # be regenerated once the source moves on, but nobody writes it.
        - test/drift/generated/**
      max_lines: 500
```

with

```yaml
        - lib/l10n/**
        # drift's migration helpers. Committed because a released schema cannot
        # be regenerated once the source moves on, but nobody writes them.
        - test/drift/generated/**
        - lib/core/database/schema_versions.dart
      max_lines: 500
```

Replace

```yaml
        - test/drift/generated/**
    flutter.max_build_lines:
```

with

```yaml
        - test/drift/generated/**
        - lib/core/database/schema_versions.dart
    flutter.max_build_lines:
```

- [ ] **Step 6: Run the migration test to see the upgrade step missing**

```bash
flutter test test/drift/migration_test.dart
```

Expected: `+1 -5: Some tests failed.` A new database has the schema of v2 already; the five tests that open a v1 database fail with `Exception: You've bumped the schema version for your drift database but didn't provide a strategy for schema updates.`

- [ ] **Step 7: Write the v1 → v2 step**

In `lib/core/database/app_database.dart`:

Replace

```dart
import 'package:drift/drift.dart';

```

with

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/schema_versions.dart';

```

Replace

```dart

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
```

with

```dart

  /// Each step works on the schema of its own version (`schema_versions.dart`,
  /// generated from `drift_schemas/`), never on today's tables, and a shipped
  /// step never changes (`.claude/skills/flutter-drift/references/
  /// migrations.md`).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: stepByStep(
      from1To2: (m, schema) async {
        // Package 2b: the fill hint and the match board on the queue row, and
        // the stored options of a guess question (graded modes spec §6).
        await m.addColumn(
          schema.studyQueueItems,
          schema.studyQueueItems.hintShown,
        );
        await m.addColumn(
          schema.studyQueueItems,
          schema.studyQueueItems.meaningSlot,
        );
        await m.createTable(schema.studyGuessOptions);
        await m.createIndex(schema.idxStudyGuessOptionsOption);
      },
    ),
    beforeOpen: (details) async {
```

- [ ] **Step 8: Describe schema v2, its invariants and the step**

In `.claude/skills/flutter-drift/references/migrations.md`:

Replace

```markdown
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

with

```markdown
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

Replace

```markdown

`dart run drift_dev make-migrations` automates steps 4–6 (snapshot, step file,
test scaffold) and is the path Drift now recommends for new schema work. This
repo's v1 → v2 step is hand-written and predates that; **do not retrofit it** —
rewriting a released migration is the one thing this document forbids outright.
If you adopt `make-migrations`, do it for the *next* version only, in its own
task, and keep the existing step untouched.

```

with

```markdown

`schema steps` writes the versioned schemas that `stepByStep` hands each step,
so a step works on the tables of its own version and never on today's.
`dart run drift_dev make-migrations` automates steps 4–6 too, but it keeps its
snapshots in `drift_schemas/<database>/`, and `test/database/schema_test.dart`
reads the flat `drift_schemas/drift_schema_vN.json`; this repo does not use it.
The first step, v1 → v2, adds the graded-mode columns and table; like every step
after it, **it never changes once released** — rewriting a released migration is
the one thing this document forbids outright.

```

Replace

```markdown
Adding a nullable or defaulted column is the cheap case, and it is why the v1 → v2
step here is four `addColumn` calls and two `createTable` calls with no row
rewrite: a v1 card upgrades without a value being invented for it.

```

with

```markdown
Adding a nullable or defaulted column is the cheap case, and it is why the v1 → v2
step here is two `addColumn` calls, one `createTable` and one `createIndex`, with
no row rewrite: a v1 queue row upgrades without a value being invented for it.

```

In `docs/shared/data/schema.md`:

Replace

```markdown
| `study_queue_items.remaining_ms` · `is_revealed` | BR-STUDY-036 |
| `study_session.direction` | BR-MODE-013 (điều kiện), BR-MODE-015 (`mixed`), BR-MODE-017 (khoá) |
```

with

```markdown
| `study_queue_items.remaining_ms` · `is_revealed` | BR-STUDY-036 |
| `study_queue_items.hint_shown` | BR-STUDY-028 |
| `study_queue_items.meaning_slot` | BR-STUDY-049 |
| `study_guess_options` | BR-STUDY-037, BR-STUDY-043 |
| `study_session.direction` | BR-MODE-013 (điều kiện), BR-MODE-015 (`mixed`), BR-MODE-017 (khoá) |
```

Replace

````markdown
                             └──► study_queue_items  (một hàng đợi mỗi stage, BR-STUDY-022)
```
````

with

````markdown
                             └──► study_queue_items  (một hàng đợi mỗi stage, BR-STUDY-022)
                                    └──► study_guess_options  (năm lựa chọn của một câu guess)
```
````

Replace

```markdown
`abandoned`/`interrupted` nếu nó bắt đầu từ ngày học trước (BR-STUDY-072). Code và test
giữ luật này; một unique index sẽ cần migration, và migration chờ BE-D1.

```

with

```markdown
`abandoned`/`interrupted` nếu nó bắt đầu từ ngày học trước (BR-STUDY-072). Code và test
giữ luật này; một unique index sẽ cần một migration riêng, và chưa có.

```

Replace

```markdown
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` — chiều thật của **thẻ này**, gán một lần lúc dựng round (BR-MODE-015). NULL ở mọi stage ngoài `self_assess` của một phiên đủ điều kiện (BR-MODE-013) |

```

with

```markdown
| `direction` | TEXT NULL | `korean_to_meaning` \| `meaning_to_korean` — chiều thật của **thẻ này**, gán một lần lúc dựng round (BR-MODE-015). NULL ở mọi stage ngoài `self_assess` của một phiên đủ điều kiện (BR-MODE-013) |
| `hint_shown` | INTEGER NOT NULL DEFAULT 0 | từ v2, chỉ `fill`: gợi ý của lượt đang dở đã hiện (BR-STUDY-028). `used_hint` của lượt đọc từ cột này, nên vẫn đúng khi app bị thu hồi rồi Tiếp tục. `0` ở mọi stage khác (invariant 38) |
| `meaning_slot` | INTEGER NULL | từ v2, chỉ `match`: chỗ `0…4` của nghĩa thẻ này trên bàn của nó (BR-STUDY-049). Một bàn là các vị trí `5k … 5k+4` của round. Gán khi round được chuẩn bị, xáo theo từng bàn, không trùng thứ tự term khi bàn có từ hai cặp. NULL ở mọi stage khác (invariant 39) |

```

Replace

```markdown
nào, bỏ dở bao nhiêu" — thứ nếu không lưu thì không tồn tại ở bất kỳ đâu.

```

with

```markdown
nào, bỏ dở bao nhiêu" — thứ nếu không lưu thì không tồn tại ở bất kỳ đâu.

## `study_guess_options`

**Phạm vi:** V8.0, từ schema v2.

Năm lựa chọn của một câu `guess`, theo thứ tự hiển thị (BR-STUDY-037, BR-STUDY-043).
Câu được dựng khi round của nó bắt đầu được phục vụ, và không dựng lại khi Tiếp tục.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `session_id` | TEXT NOT NULL | cùng `mode`, `round`, `card_id`: dòng hàng đợi của câu hỏi → `study_queue_items` ON DELETE CASCADE |
| `mode` | TEXT NOT NULL DEFAULT 'guess' | luôn `guess`; có mặt vì khoá ngoại ghép cần nó |
| `round` | INTEGER NOT NULL | round của câu hỏi |
| `card_id` | TEXT NOT NULL | thẻ đang hỏi |
| `slot` | INTEGER NOT NULL | vị trí hiển thị `0…4` |
| `option_card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE. Đúng một lựa chọn là chính thẻ đang hỏi (invariant 40) |

PK là `(session_id, mode, round, card_id, slot)`, và một card xuất hiện tối đa một lần
trong một câu. Index `idx_study_guess_options_option` phục vụ cascade khi xoá card.

**Câu có ít hơn năm dòng là câu bị chặn** (BR-STUDY-040): nó không dựng được, hoặc mất
một lựa chọn vì card bị xoá. Câu bị chặn không hiện và không nhận lượt.

```

Replace

```markdown

-- Bất biến 33-37: Phạm vi sub-project sau — Trash. Giữ số và nghĩa, có hiệu
```

with

```markdown

-- 38. `hint_shown` nằm ngoài `fill` (BR-STUDY-028)
--     CHECK của cột đã chặn; query giữ luật đọc được ở đây.
SELECT session_id FROM study_queue_items
WHERE hint_shown NOT IN (0, 1) OR (mode <> 'fill' AND hint_shown <> 0);

-- 39. `meaning_slot` nằm ngoài `match`, vượt 0–4, hoặc hai cặp của một bàn chung
--     một chỗ (BR-STUDY-049)
--     Bàn là các vị trí `5k … 5k+4` của round. Vế đầu CHECK đã chặn; vế sau thì
--     không, vì CHECK không nhìn được dòng khác.
SELECT session_id FROM study_queue_items
WHERE meaning_slot IS NOT NULL AND (mode <> 'match' OR meaning_slot NOT BETWEEN 0 AND 4)
UNION ALL
SELECT session_id FROM study_queue_items
WHERE mode = 'match' AND meaning_slot IS NOT NULL AND position >= 0
GROUP BY session_id, round, position / 5, meaning_slot
HAVING COUNT(*) > 1;

-- 40. Câu `guess` quá năm lựa chọn, hoặc không có đúng một đáp án đúng (BR-STUDY-037)
--     Hai lựa chọn cùng `back_folded` (BR-STUDY-039) không phải bất biến: sửa một
--     card sau khi câu đã dựng có thể làm điều đó đúng một cách hợp lệ. Bộ dựng
--     câu hỏi giữ luật ấy lúc dựng.
SELECT session_id FROM study_guess_options
GROUP BY session_id, round, card_id
HAVING COUNT(*) > 5 OR SUM(option_card_id = card_id) <> 1;

-- Bất biến 33-37: Phạm vi sub-project sau — Trash. Giữ số và nghĩa, có hiệu
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/database/invariants_test.dart \
  test/drift/migration_test.dart
```

Expected: `+80: All tests passed!`

- [ ] **Step 10: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1219: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 11: Commit**

```bash
git add .claude/skills/flutter-drift/references/migrations.md \
  analysis_options.yaml \
  code-verification-guard-v2/registries/projects/memox-v8/config/overrides.yaml \
  docs/shared/data/schema.md \
  drift_schemas/drift_schema_v2.json \
  lib/core/database/app_database.dart \
  lib/core/database/schema_versions.dart \
  lib/core/database/tables/study.drift \
  test/database/invariants_test.dart \
  test/drift/generated/schema.dart \
  test/drift/generated/schema_v1.dart \
  test/drift/generated/schema_v2.dart \
  test/drift/migration_test.dart \
  test/support/invariant_queries.dart
git commit -F - <<'EOF'
feat(database): schema v2 and the first migration, proven by its test (BE-D1)

Schema v2 adds the fill hint and the match meaning slot to the queue row and
the stored options of a guess question (graded modes spec §6). The v1 to v2
step adds two columns, one table and one index on the versioned schema that
drift generates from the flat snapshots, and rewrites no row. The migration
test upgrades a realistic v1 database and proves every row keeps its values,
the invariants still hold, the file passes the integrity and foreign key
checks, and a fresh and an upgraded database end at the same schema. The
invariants gain 38 to 40, and the flutter-drift skill describes this step.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The session screen reads through its own repository

**Files:**
- Create: `lib/features/study/data/repositories/study_session_view_repository_impl.dart`, `lib/features/study/di/study_session_view_repository_provider.dart`, `lib/features/study/domain/repositories/study_session_view_repository.dart`
- Modify: `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`, `lib/features/study/domain/usecases/watch_study_session_use_case.dart`
- Test (modify): `test/features/study/data/watch_session_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed)

**Interfaces:**
- Consumes: package 2a's `StudySessionRepositoryImpl` read (`watchSession`,
  `StudyViewDao`, `study_session_view_mapper.dart`); `databaseProvider`.
- Produces:
  - `abstract interface class StudySessionViewRepository` with
    `Stream<StudySessionView?> watchSession(String sessionId)`
    (`study/domain/repositories/study_session_view_repository.dart`);
    `StudySessionRepository` no longer has `watchSession`.
  - `StudySessionViewRepositoryImpl(AppDatabase db)`
    (`study/data/repositories/study_session_view_repository_impl.dart`).
  - `studySessionViewRepositoryProvider`
    (`study/di/study_session_view_repository_provider.dart`).
  - `WatchStudySessionUseCase(StudySessionViewRepository)`, its `call`
    unchanged.

Spec §8.5. The read moves as it is: the same statements, the same
emissions. The writes stay in `StudySessionRepository`, which this package
grows; moving the read first keeps it under the guard's warning.

- [ ] **Step 1: Write the failing tests**

In `test/features/study/data/watch_session_test.dart`:

Replace

```dart
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

with

```dart
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

Replace

```dart
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
```

with

```dart
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);
```

Replace

```dart
    sessions = studySessionRepository(db, () => now);
  });
```

with

```dart
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  });
```

Replace

```dart
  Future<StudySessionView> viewOf(String sessionId) async =>
      (await sessions.watchSession(sessionId).first)!;

```

with

```dart
  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

```

Replace

```dart
    final next = expectLater(
      sessions.watchSession(id),
      emitsThrough(
```

with

```dart
    final next = expectLater(
      views.watchSession(id),
      emitsThrough(
```

Replace

```dart
    final id = await learning(leaf);
    final watch = WatchStudySessionUseCase(sessions)(sessionId: id);

```

with

```dart
    final id = await learning(leaf);
    final watch = WatchStudySessionUseCase(views)(sessionId: id);

```

Replace

```dart
    await expectLater(
      sessions.watchSession(id),
      emitsError(isA<UnknownDatabaseFailure>()),
```

with

```dart
    await expectLater(
      views.watchSession(id),
      emitsError(isA<UnknownDatabaseFailure>()),
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/watch_session_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile. The first errors: `Error: Error when reading 'lib/features/study/data/repositories/study_session_view_repository_impl.dart': No such file or directory`, `Error: 'StudySessionViewRepositoryImpl' isn't a type.`, `Error: Method not found: 'StudySessionViewRepositoryImpl'.`

- [ ] **Step 3: Declare the view repository, and take the read off the session repository**

In `lib/features/study/domain/repositories/study_session_repository.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// The one implementation is `StudySessionRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class StudySessionRepository {
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// The writes of a session; its screen reads through
/// `StudySessionViewRepository`. The one implementation is
/// `StudySessionRepositoryImpl` (data layer). The contract exists for
/// ADR-010's reason: domain stays framework-free and tests substitute a fake.
abstract interface class StudySessionRepository {
```

Replace

```dart
  Future<void> abandonStaleSessions({DateTime? now});

  /// UC-STUDY-001 steps 6–13 (spec §8.2): the session screen, again on every
  /// write it can see; null once the session is gone (A5). It writes nothing
  /// (BR-STUDY-075).
  Stream<StudySessionView?> watchSession(String sessionId);
}
```

with

```dart
  Future<void> abandonStaleSessions({DateTime? now});
}
```

Create `lib/features/study/domain/repositories/study_session_view_repository.dart`:

```dart
import 'package:memox/features/study/domain/models/study_session_view_model.dart';

/// The session screen's read, apart from the writes of
/// `StudySessionRepository` (graded modes spec §8.5). The one implementation
/// is `StudySessionViewRepositoryImpl` (data layer); the contract exists for
/// ADR-010's reason: domain stays framework-free and tests substitute a fake.
abstract interface class StudySessionViewRepository {
  /// UC-STUDY-001 steps 6–13 (spec §8.2): the session screen, again on every
  /// write it can see; null once the session is gone (A5). It writes nothing
  /// (BR-STUDY-075).
  Stream<StudySessionView?> watchSession(String sessionId);
}
```

- [ ] **Step 4: Move the read into its implementation**

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_session_view_mapper.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

with

```dart
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

Replace

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
```

Replace

```dart
/// Runs a session: its turns, its rounds and stages, and how it ends
/// (UC-STUDY-001 steps 6–13, A1–A5). Every write is one transaction, which
/// the srs and card writes it calls join: the rules read the rows as they
```

with

```dart
/// Runs a session: its turns, its rounds and stages, and how it ends
/// (UC-STUDY-001 steps 6–13, A1–A5); its screen reads through
/// `StudySessionViewRepositoryImpl`. Every write is one transaction, which
/// the srs and card writes it calls join: the rules read the rows as they
```

Replace

```dart
       _queue = StudyQueueDao(_db),
       _views = StudyViewDao(_db),
       _now = now ?? DateTime.now,
```

with

```dart
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
```

Replace

```dart
  final StudyQueueDao _queue;
  final StudyViewDao _views;
  final DateTime Function() _now;
```

with

```dart
  final StudyQueueDao _queue;
  final DateTime Function() _now;
```

Replace

```dart
    });
  }

  @override
  Stream<StudySessionView?> watchSession(String sessionId) => _views
      .watchSessionRow(sessionId)
      .asyncMap((row) async => row == null ? null : _viewOf(row))
      .mapDatabaseErrors();

  /// The rest of [row]'s screen, read in the same emission (spec §8.2): an
  /// open session shows the card it serves, an ended one its summary,
  /// whatever rows it left.
  Future<StudySessionView> _viewOf(SessionViewRow row) async {
    final session = row.session;
    final modes = await _views.modesOf(session.id);
    if (session.status == SessionStatus.inProgress.code) {
      return studySessionViewOf(
        row,
        modes: modes,
        served: await _servedOf(session),
        counts: null,
      );
    }
    return studySessionViewOf(
      row,
      modes: modes,
      served: null,
      counts: await _views.summaryCounts(
        session.id,
        lapseActions: lapseActionsOf(SchedulerType.fromCode(row.schedulerType)),
      ),
    );
  }

  /// The row [session] serves, with its card and the counts of its round;
  /// null while nothing is left to serve (spec D12).
  Future<ServedRow?> _servedOf(StudySession session) async {
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    if (head == null) return null;
    final card = await _views.cardRow(head.cardId);
    if (card == null) return null;
    return (
      row: head,
      card: card,
      round: await _views.roundCounts(session.id, head.mode, head.round),
    );
  }
```

with

```dart
    });
  }
```

Create `lib/features/study/data/repositories/study_session_view_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_session_view_mapper.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';

/// Reads the session screen (UC-STUDY-001 steps 6–13): one Drift `watch()` on
/// the session row, and the rest of the screen read in the same emission.
final class StudySessionViewRepositoryImpl
    implements StudySessionViewRepository {
  StudySessionViewRepositoryImpl(AppDatabase db)
    : _queue = StudyQueueDao(db),
      _views = StudyViewDao(db);

  final StudyQueueDao _queue;
  final StudyViewDao _views;

  @override
  Stream<StudySessionView?> watchSession(String sessionId) => _views
      .watchSessionRow(sessionId)
      .asyncMap((row) async => row == null ? null : _viewOf(row))
      .mapDatabaseErrors();

  /// The rest of [row]'s screen, read in the same emission (spec §8.2): an
  /// open session shows the card it serves, an ended one its summary,
  /// whatever rows it left.
  Future<StudySessionView> _viewOf(SessionViewRow row) async {
    final session = row.session;
    final modes = await _views.modesOf(session.id);
    if (session.status == SessionStatus.inProgress.code) {
      return studySessionViewOf(
        row,
        modes: modes,
        served: await _servedOf(session),
        counts: null,
      );
    }
    return studySessionViewOf(
      row,
      modes: modes,
      served: null,
      counts: await _views.summaryCounts(
        session.id,
        lapseActions: lapseActionsOf(SchedulerType.fromCode(row.schedulerType)),
      ),
    );
  }

  /// The row [session] serves, with its card and the counts of its round;
  /// null while nothing is left to serve (spec D12).
  Future<ServedRow?> _servedOf(StudySession session) async {
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    if (head == null) return null;
    final card = await _views.cardRow(head.cardId);
    if (card == null) return null;
    return (
      row: head,
      card: card,
      round: await _views.roundCounts(session.id, head.mode, head.round),
    );
  }
}
```

- [ ] **Step 5: Give it a provider, and let WatchStudySession take it**

Create `lib/features/study/di/study_session_view_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_view_repository_provider.g.dart';

@riverpod
StudySessionViewRepository studySessionViewRepository(Ref ref) =>
    StudySessionViewRepositoryImpl(ref.watch(databaseProvider));
```

In `lib/features/study/domain/usecases/watch_study_session_use_case.dart`:

Replace

```dart
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

```

with

```dart
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';

```

Replace

```dart

  final StudySessionRepository _sessions;

```

with

```dart

  final StudySessionViewRepository _sessions;

```

- [ ] **Step 6: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run prints `Built with build_runner`, and `study_session_view_repository_provider.g.dart` exists next to its provider.

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/study/data/watch_session_test.dart
```

Expected: `+10: All tests passed!`

- [ ] **Step 9: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1219: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/data/repositories/study_session_view_repository_impl.dart \
  lib/features/study/di/study_session_view_repository_provider.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  lib/features/study/domain/repositories/study_session_view_repository.dart \
  lib/features/study/domain/usecases/watch_study_session_use_case.dart \
  test/features/study/data/watch_session_test.dart
git commit -F - <<'EOF'
refactor(study): the session screen reads through its own repository

WatchStudySession now reads through StudySessionViewRepository, whose one
implementation takes the session repository's read as it was (graded modes
spec §8.5). The writes stay in StudySessionRepository, which the graded
modes grow, and each side stays under the guard's size warning.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: Each graded mode judges the person's real input

**Files:**
- Create: `lib/features/study_mode/domain/models/recall_mode.dart`, `lib/features/study_mode/domain/models/round_preparation_model.dart`, `lib/features/study_mode/domain/models/turn_judgement_model.dart`
- Modify: `lib/features/study/domain/failures/study_failure.dart`, `lib/features/study_mode/domain/failures/study_mode_failure.dart`, `lib/features/study_mode/domain/models/browse_mode.dart`, `lib/features/study_mode/domain/models/fill_mode.dart`, `lib/features/study_mode/domain/models/graded_mode.dart`, `lib/features/study_mode/domain/models/guess_mode.dart`, `lib/features/study_mode/domain/models/match_mode.dart`, `lib/features/study_mode/domain/models/self_assess_mode.dart`, `lib/features/study_mode/domain/models/study_answer_model.dart`, `lib/features/study_mode/domain/models/study_mode.dart`
- Test (create): `test/features/study_mode/domain/guess_question_test.dart`, `test/features/study_mode/domain/match_board_test.dart`, `test/features/study_mode/domain/turn_judging_test.dart`
- Test (modify): `test/features/study/domain/study_failure_test.dart`

**Interfaces:**
- Consumes: `StudyModeHandler`, `GradedModeHandler`, the six handlers,
  `StudyModeRejection`, `StudyRejection.ofModeRefusal` (package 2a);
  `SrsScheduler.supportedActions`, `EightBoxAction`; `foldText`
  (`lib/core/text/folded_text.dart`).
- Produces, in `lib/features/study_mode/domain/`:
  - Answers: `FillAnswer(String typed)`, `RecallAnswer(RecallOutcome outcome)`
    with `enum RecallOutcome {remembered, forgot, timedOut}`,
    `GuessAnswer(String chosenCardId)`, `MatchAnswer(String meaningCardId)`.
    `GradedAnswer` stays until Task 6.
  - `models/turn_judgement_model.dart`:
    `TurnCard({required String cardId, required String frontFolded, required String backFolded})`;
    `TurnContext({required TurnCard card, bool isRevealed = false, bool isHintShown = false, List<String>? guessOptionIds, Map<String, String> boardMeanings = const {}})`;
    `enum OutcomeReason {timeout}` with `String code`;
    `TurnVerdict({required Object? action, bool? isCorrect, OutcomeReason? outcomeReason, int? comparisonVersion, bool? usedHint, String? takesMeaningSlotOf})`.
  - `models/round_preparation_model.dart`:
    `RoundRowFacts({required String cardId, required int position, required bool isPending, required int? meaningSlot, required int optionCount, required String meaningFolded})`;
    `typedef MeaningCard = ({String cardId, String meaningFolded})`;
    `RoundPreparation({Map<String, int> meaningSlots = const {}, Map<String, List<String>?> questions = const {}})`
    with `bool get isEmpty`.
  - On `StudyModeHandler`:
    `Outcome<TurnVerdict, StudyModeRejection> judge(StudyAnswer answer, TurnContext context, SrsScheduler scheduler)`;
    `bool get asksWithOptions` (true for `guess`);
    `RoundPreparation prepareRound(List<RoundRowFacts> rows, {required List<MeaningCard> meaningSource, required Random random})`,
    empty by default. `actionOf` stays until Task 6.
  - `GradedModeHandler.verdictOf(bool isCorrect, SrsScheduler scheduler, {OutcomeReason? outcomeReason, int? comparisonVersion, bool? usedHint, String? takesMeaningSlotOf})`.
  - `const fillComparisonVersion = 1` (`fill_mode.dart`); `const recallTurnMs = 20000`,
    `RecallModeHandler` and `const recallMode` (`recall_mode.dart`, new);
    `List<String>? guessOptionsFor(MeaningCard asked, List<MeaningCard> source, Random random)`
    (`guess_mode.dart`); `const matchBoardSize = 5`,
    `int matchBoardOf(int position)` and
    `List<int> meaningSlotsFor(int pairCount, Random random)` (`match_mode.dart`).
  - `StudyModeRejection` and `StudyRejection` gain `emptyAnswer`, `notRevealed`,
    `alreadyRevealed`, `questionBlocked`, `notAnOption`, `notOnBoard`, and
    `ofModeRefusal` maps each to its namesake.

Spec §7 and D2, D3; Clarifications 4, 5. Nothing here reads the
database: the session hands the facts in (Task 6) and writes what the verdict
says. The four graded modes map right to `remembered` and wrong to `forgotten`
through `verdictOf`; `browse` and `self_assess` judge their 2a answers the way
`actionOf` did.

- [ ] **Step 1: Write the failing tests**

In `test/features/study/domain/study_failure_test.dart`:

Replace

```dart
void main() {
  test('a mode refusal keeps its meaning in the session (spec §9)', () {
    expect(
      StudyRejection.ofModeRefusal(StudyModeRejection.answerDoesNotFitMode),
      StudyRejection.answerDoesNotFitMode,
    );
    expect(
      StudyRejection.ofModeRefusal(StudyModeRejection.unsupportedAction),
      StudyRejection.unsupportedAction,
    );
  });
```

with

```dart
void main() {
  test('a mode refusal keeps its meaning, and its name, in the session '
      '(spec §9; graded modes spec §7.8)', () {
    for (final reason in StudyModeRejection.values) {
      expect(StudyRejection.ofModeRefusal(reason).name, reason.name);
    }
    expect(StudyModeRejection.values, hasLength(8));
  });
```

Create `test/features/study_mode/domain/guess_question_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// The five options of a guess question (graded modes spec §7.5, §7.7).

const _meanings = {
  'q': 'library',
  'a': 'kitchen',
  'b': 'school',
  'c': 'office',
  'd': 'classroom',
  'e': 'garden',
  'f': 'kitchen',
};

List<MeaningCard> _source(Map<String, String> meanings) => [
  for (final MapEntry(:key, :value) in meanings.entries)
    (cardId: key, meaningFolded: value),
];

const MeaningCard _asked = (cardId: 'q', meaningFolded: 'library');

void main() {
  final source = _source(_meanings);

  test('five options: the asked card once, and four other meanings '
      '(BR-STUDY-037, BR-STUDY-039; IT-MODE-005F)', () {
    for (var seed = 0; seed < 20; seed++) {
      final options = guessOptionsFor(_asked, source, Random(seed))!;
      expect(options, hasLength(5));
      expect(options.where((id) => id == 'q'), hasLength(1));
      expect({for (final id in options) _meanings[id]}, hasLength(5));
    }
  });

  test('a card with the asked meaning is never a distractor, whatever its '
      'text (BR-STUDY-039; IT-MODE-015)', () {
    final twin = [...source, (cardId: 'twin', meaningFolded: 'library')];
    for (var seed = 0; seed < 20; seed++) {
      expect(
        guessOptionsFor(_asked, twin, Random(seed)),
        isNot(contains('twin')),
      );
    }
  });

  test('no question below four meanings besides the asked one '
      '(BR-STUDY-040)', () {
    final few = _source({
      'q': 'library',
      'a': 'kitchen',
      'f': 'kitchen',
      'b': 'school',
      'c': 'office',
    });
    expect(guessOptionsFor(_asked, few, Random(1)), isNull);
  });

  test('a seed gives the same question whatever order the source comes in', () {
    expect(
      guessOptionsFor(_asked, source.reversed.toList(), Random(7)),
      guessOptionsFor(_asked, source, Random(7)),
    );
  });

  test('the options have a shuffle of their own: the right one moves '
      '(BR-STUDY-043)', () {
    final places = {
      for (var seed = 0; seed < 20; seed++)
        guessOptionsFor(_asked, source, Random(seed))!.indexOf('q'),
    };
    expect(places.length, greaterThan(1));
  });

  group('preparing a guess round (spec §7.7)', () {
    RoundRowFacts row(
      String id,
      int position, {
      bool isPending = true,
      int optionCount = 0,
    }) => RoundRowFacts(
      cardId: id,
      position: position,
      isPending: isPending,
      meaningSlot: null,
      optionCount: optionCount,
      meaningFolded: _meanings[id]!,
    );

    test('builds a question for each pending row that lacks its five '
        'options, and leaves the others (BR-STUDY-043)', () {
      final preparation = StudyMode.guess.handler.prepareRound(
        [
          row('q', 0),
          row('a', 1, optionCount: 5),
          row('b', 2, isPending: false),
        ],
        meaningSource: source,
        random: Random(1),
      );
      expect(preparation.questions.keys, ['q']);
      expect(preparation.questions['q'], hasLength(5));
      expect(preparation.meaningSlots, isEmpty);
    });

    test('a question that cannot be built is null, so what is left of it '
        'goes (BR-STUDY-040)', () {
      final preparation = StudyMode.guess.handler.prepareRound(
        [row('q', 0, optionCount: 4)],
        meaningSource: _source({'q': 'library', 'a': 'kitchen'}),
        random: Random(1),
      );
      expect(preparation.questions, {'q': null});
    });

    test('only guess asks with options, and the other modes but match '
        'prepare nothing', () {
      expect(
        [
          for (final mode in StudyMode.values)
            if (mode.handler.asksWithOptions) mode,
        ],
        [StudyMode.guess],
      );
      for (final mode in [
        StudyMode.browse,
        StudyMode.selfAssess,
        StudyMode.recall,
        StudyMode.fill,
      ]) {
        final preparation = mode.handler.prepareRound(
          [row('q', 0)],
          meaningSource: source,
          random: Random(1),
        );
        expect(preparation.isEmpty, isTrue, reason: mode.code);
      }
    });
  });
}
```

Create `test/features/study_mode/domain/match_board_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

// The boards of a match round and the order of their meanings
// (BR-STUDY-049; graded modes spec D7, §7.6, §7.7).

void main() {
  test('a board of two or more pairs never keeps the order of its terms', () {
    for (final pairs in [2, 3, 5]) {
      for (var seed = 0; seed < 50; seed++) {
        final slots = meaningSlotsFor(pairs, Random(seed));
        expect(slots.toSet(), {for (var i = 0; i < pairs; i++) i});
        expect(slots, isNot([for (var i = 0; i < pairs; i++) i]));
      }
    }
  });

  test('one pair takes slot 0', () {
    expect(meaningSlotsFor(1, Random(1)), [0]);
  });

  test('a board is five positions of the round', () {
    expect(
      [
        for (final position in [0, 4, 5, 9, 10]) matchBoardOf(position),
      ],
      [0, 0, 1, 1, 2],
    );
  });

  group('preparing a match round', () {
    RoundRowFacts row(
      String id,
      int position, {
      int? slot,
      bool isPending = true,
    }) => RoundRowFacts(
      cardId: id,
      position: position,
      isPending: isPending,
      meaningSlot: slot,
      optionCount: 0,
      meaningFolded: 'meaning $id',
    );

    test('each board gets its own slots, its matched pairs too', () {
      final rows = [
        for (var i = 0; i < 7; i++) row('c$i', i, isPending: i != 2),
      ];
      final preparation = StudyMode.match.handler.prepareRound(
        rows,
        meaningSource: const [],
        random: Random(3),
      );
      final slots = preparation.meaningSlots;
      expect(slots.keys.toSet(), {for (var i = 0; i < 7; i++) 'c$i'});
      expect({for (var i = 0; i < 5; i++) slots['c$i']}, {0, 1, 2, 3, 4});
      expect({slots['c5'], slots['c6']}, {0, 1});
      expect(preparation.questions, isEmpty);
    });

    test('a board that has its slots is left as it is (spec D8)', () {
      final preparation = StudyMode.match.handler.prepareRound(
        [row('a', 0, slot: 1), row('b', 1, slot: 0), row('c', 5), row('d', 6)],
        meaningSource: const [],
        random: Random(3),
      );
      expect(preparation.meaningSlots.keys.toSet(), {'c', 'd'});
    });
  });
}
```

Create `test/features/study_mode/domain/turn_judging_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

// Each mode judges the person's real input as a pure function of the answer
// and the facts the session reads (graded modes spec §7).

const _card = TurnCard(cardId: 'c1', frontFolded: 'công', backFolded: 'work');

TurnContext _context({
  bool isRevealed = false,
  bool isHintShown = false,
  List<String>? options,
  Map<String, String> board = const {},
}) => TurnContext(
  card: _card,
  isRevealed: isRevealed,
  isHintShown: isHintShown,
  guessOptionIds: options,
  boardMeanings: board,
);

Outcome<TurnVerdict, StudyModeRejection> _judge(
  StudyMode mode,
  StudyAnswer answer, [
  TurnContext? context,
]) => mode.handler.judge(answer, context ?? _context(), eightBoxScheduler);

Matcher _refusedWith(StudyModeRejection reason) =>
    isA<Rejected<TurnVerdict, StudyModeRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

Matcher _verdict({
  required Object? action,
  bool? isCorrect,
  OutcomeReason? outcomeReason,
  int? comparisonVersion,
  bool? usedHint,
  String? takesMeaningSlotOf,
}) => isA<Ok<TurnVerdict, StudyModeRejection>>().having(
  (ok) => ok.value,
  'verdict',
  isA<TurnVerdict>()
      .having((verdict) => verdict.action, 'action', action)
      .having((verdict) => verdict.isCorrect, 'isCorrect', isCorrect)
      .having(
        (verdict) => verdict.outcomeReason,
        'outcomeReason',
        outcomeReason,
      )
      .having(
        (verdict) => verdict.comparisonVersion,
        'comparisonVersion',
        comparisonVersion,
      )
      .having((verdict) => verdict.usedHint, 'usedHint', usedHint)
      .having(
        (verdict) => verdict.takesMeaningSlotOf,
        'takesMeaningSlotOf',
        takesMeaningSlotOf,
      ),
);

void main() {
  group('fill', () {
    test('folds the typed term and compares it with front_folded: spaces and '
        'case fall away, accents stay (BR-STUDY-026; IT-MODE-010)', () {
      expect(
        _judge(StudyMode.fill, const FillAnswer('  cÔnG  ')),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          comparisonVersion: 1,
          usedHint: false,
        ),
      );
      expect(
        _judge(StudyMode.fill, const FillAnswer('cong')),
        _verdict(
          action: EightBoxAction.forgotten,
          isCorrect: false,
          comparisonVersion: 1,
          usedHint: false,
        ),
      );
    });

    test('a blank answer is refused, so it records nothing (BR-STUDY-029)', () {
      for (final typed in ['', '   ', '\n\t ']) {
        expect(
          _judge(StudyMode.fill, FillAnswer(typed)),
          _refusedWith(StudyModeRejection.emptyAnswer),
        );
      }
    });

    test('a shown hint rides on the turn and changes nothing else '
        '(BR-STUDY-028; IT-MODE-011)', () {
      expect(
        _judge(
          StudyMode.fill,
          const FillAnswer('nope'),
          _context(isHintShown: true),
        ),
        _verdict(
          action: EightBoxAction.forgotten,
          isCorrect: false,
          comparisonVersion: 1,
          usedHint: true,
        ),
      );
      expect(
        _judge(
          StudyMode.fill,
          const FillAnswer('Công'),
          _context(isHintShown: true),
        ),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          comparisonVersion: 1,
          usedHint: true,
        ),
      );
    });
  });

  group('recall', () {
    test('a self-assessment needs the answer revealed, then records the '
        "person's choice (BR-STUDY-065)", () {
      for (final outcome in [RecallOutcome.remembered, RecallOutcome.forgot]) {
        expect(
          _judge(StudyMode.recall, RecallAnswer(outcome)),
          _refusedWith(StudyModeRejection.notRevealed),
        );
      }
      expect(
        _judge(
          StudyMode.recall,
          const RecallAnswer(RecallOutcome.remembered),
          _context(isRevealed: true),
        ),
        _verdict(action: EightBoxAction.remembered, isCorrect: true),
      );
      expect(
        _judge(
          StudyMode.recall,
          const RecallAnswer(RecallOutcome.forgot),
          _context(isRevealed: true),
        ),
        _verdict(action: EightBoxAction.forgotten, isCorrect: false),
      );
    });

    test('a timeout records wrong with its reason, and never once the answer '
        'is revealed (BR-STUDY-032 to BR-STUDY-034)', () {
      expect(
        _judge(StudyMode.recall, const RecallAnswer(RecallOutcome.timedOut)),
        _verdict(
          action: EightBoxAction.forgotten,
          isCorrect: false,
          outcomeReason: OutcomeReason.timeout,
        ),
      );
      expect(
        _judge(
          StudyMode.recall,
          const RecallAnswer(RecallOutcome.timedOut),
          _context(isRevealed: true),
        ),
        _refusedWith(StudyModeRejection.alreadyRevealed),
      );
      expect(OutcomeReason.timeout.code, 'timeout');
    });
  });

  group('guess', () {
    const options = ['d1', 'c1', 'd2', 'd3', 'd4'];

    test('an option is judged by its card id (BR-STUDY-041)', () {
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('c1'),
          _context(options: options),
        ),
        _verdict(action: EightBoxAction.remembered, isCorrect: true),
      );
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('d3'),
          _context(options: options),
        ),
        _verdict(action: EightBoxAction.forgotten, isCorrect: false),
      );
    });

    test('a card that is not one of the options is refused (BR-STUDY-041)', () {
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('x'),
          _context(options: options),
        ),
        _refusedWith(StudyModeRejection.notAnOption),
      );
    });

    test('a question without its five options is blocked (BR-STUDY-040; '
        'IT-MODE-014)', () {
      expect(
        _judge(StudyMode.guess, const GuessAnswer('c1')),
        _refusedWith(StudyModeRejection.questionBlocked),
      );
      expect(
        _judge(
          StudyMode.guess,
          const GuessAnswer('c1'),
          _context(options: const ['d1', 'c1', 'd2', 'd3']),
        ),
        _refusedWith(StudyModeRejection.questionBlocked),
      );
    });
  });

  group('match', () {
    const board = {'c1': 'work', 'c2': 'water', 'c3': 'work'};

    test("the turn is the term card's, and a meaning of the same back_folded "
        'is right (BR-STUDY-062; spec D3)', () {
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c1'),
          _context(board: board),
        ),
        _verdict(action: EightBoxAction.remembered, isCorrect: true),
      );
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c3'),
          _context(board: board),
        ),
        _verdict(
          action: EightBoxAction.remembered,
          isCorrect: true,
          takesMeaningSlotOf: 'c3',
        ),
      );
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c2'),
          _context(board: board),
        ),
        _verdict(action: EightBoxAction.forgotten, isCorrect: false),
      );
    });

    test('a meaning that is not a pending pair of the board is refused '
        '(BR-STUDY-049)', () {
      expect(
        _judge(
          StudyMode.match,
          const MatchAnswer('c9'),
          _context(board: board),
        ),
        _refusedWith(StudyModeRejection.notOnBoard),
      );
    });
  });

  group('every mode', () {
    test("an answer of another mode's kind is refused", () {
      const foreign = <StudyMode, StudyAnswer>{
        StudyMode.browse: FillAnswer('x'),
        StudyMode.selfAssess: GuessAnswer('c1'),
        StudyMode.match: RecallAnswer(RecallOutcome.remembered),
        StudyMode.guess: MatchAnswer('c1'),
        StudyMode.recall: FillAnswer('x'),
        StudyMode.fill: AdvanceAnswer(),
      };
      for (final MapEntry(key: mode, value: answer) in foreign.entries) {
        expect(
          _judge(mode, answer, _context(isRevealed: true)),
          _refusedWith(StudyModeRejection.answerDoesNotFitMode),
          reason: mode.code,
        );
      }
    });

    test('browse moves on with no action, and self_assess records the action '
        'pressed from its scheduler (BR-MODE-005, BR-MODE-011)', () {
      expect(
        _judge(StudyMode.browse, const AdvanceAnswer()),
        _verdict(action: null),
      );
      final selfAssess = StudyMode.selfAssess.handler;
      expect(
        selfAssess.judge(
          const SelfAssessAnswer(Sm2Action.hard),
          _context(),
          sm2Scheduler,
        ),
        _verdict(action: Sm2Action.hard),
      );
      expect(
        selfAssess.judge(
          const SelfAssessAnswer(EightBoxAction.remembered),
          _context(),
          sm2Scheduler,
        ),
        _refusedWith(StudyModeRejection.unsupportedAction),
      );
    });

    test('a graded verdict has no action under sm2 (BR-MODE-007)', () {
      expect(
        StudyMode.recall.handler.judge(
          const RecallAnswer(RecallOutcome.remembered),
          _context(isRevealed: true),
          sm2Scheduler,
        ),
        _refusedWith(StudyModeRejection.unsupportedAction),
      );
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/domain/study_failure_test.dart \
  test/features/study_mode/domain/guess_question_test.dart \
  test/features/study_mode/domain/match_board_test.dart \
  test/features/study_mode/domain/turn_judging_test.dart
```

Expected: `+1 -5: Some tests failed.` `guess_question_test.dart`, `match_board_test.dart` and `turn_judging_test.dart` do not compile; in `study_failure_test.dart` the mode refusals are two where the test expects eight. The tool may add `The Dart compiler exited unexpectedly` while the others fail to load. The first errors: `Error: Undefined name 'RecallOutcome'.`, `Error: Method not found: 'guessOptionsFor'.`, `Error: The method 'prepareRound' isn't defined for the type 'StudyModeHandler'.`

- [ ] **Step 3: Write the vocabulary of judging**

In `lib/features/study/domain/failures/study_failure.dart`:

Replace

```dart
  /// The action is not in the scheduler's `supportedActions` (BR-STUDY-009).
  unsupportedAction;

```

with

```dart
  /// The action is not in the scheduler's `supportedActions` (BR-STUDY-009).
  unsupportedAction,

  /// `fill`: nothing is left of the answer once folded (BR-STUDY-029).
  emptyAnswer,

  /// `recall`: a self-assessment before the answer was revealed
  /// (BR-STUDY-065).
  notRevealed,

  /// `recall`: a timeout once the answer was revealed (BR-STUDY-032).
  alreadyRevealed,

  /// `guess`: the question lacks some of its five options; the stage stops
  /// here until the person leaves (BR-STUDY-040).
  questionBlocked,

  /// `guess`: the chosen card is not one of the options (BR-STUDY-041).
  notAnOption,

  /// `match`: the meaning is not a pending pair of the current board
  /// (BR-STUDY-049, BR-STUDY-062).
  notOnBoard;

```

Replace

```dart
        StudyModeRejection.unsupportedAction => unsupportedAction,
      };
```

with

```dart
        StudyModeRejection.unsupportedAction => unsupportedAction,
        StudyModeRejection.emptyAnswer => emptyAnswer,
        StudyModeRejection.notRevealed => notRevealed,
        StudyModeRejection.alreadyRevealed => alreadyRevealed,
        StudyModeRejection.questionBlocked => questionBlocked,
        StudyModeRejection.notAnOption => notAnOption,
        StudyModeRejection.notOnBoard => notOnBoard,
      };
```

Replace the whole of `lib/features/study_mode/domain/failures/study_mode_failure.dart` with:

```dart
/// Why a mode refuses an answer (ADR-011 D6).
enum StudyModeRejection {
  /// The answer is of another mode's kind (spec §5.4).
  answerDoesNotFitMode,

  /// The action is not in the scheduler's `supportedActions` (BR-MODE-011,
  /// BR-STUDY-009).
  unsupportedAction,

  /// `fill`: nothing is left of the answer once folded (BR-STUDY-029).
  emptyAnswer,

  /// `recall`: a self-assessment before the answer was revealed
  /// (BR-STUDY-065).
  notRevealed,

  /// `recall`: a timeout once the answer was revealed (BR-STUDY-032).
  alreadyRevealed,

  /// `guess`: the question lacks some of its five options (BR-STUDY-040).
  questionBlocked,

  /// `guess`: the chosen card is not one of the options (BR-STUDY-041).
  notAnOption,

  /// `match`: the meaning is not a pending pair of the current board
  /// (BR-STUDY-049, BR-STUDY-062).
  notOnBoard,
}
```

Create `lib/features/study_mode/domain/models/round_preparation_model.dart`:

```dart
/// A built row of a round, as preparing the round reads it (graded modes
/// spec §7.7).
final class RoundRowFacts {
  const RoundRowFacts({
    required this.cardId,
    required this.position,
    required this.isPending,
    required this.meaningSlot,
    required this.optionCount,
    required this.meaningFolded,
  });

  final String cardId;
  final int position;
  final bool isPending;

  /// `match`: the row's meaning slot, null until the round is prepared.
  final int? meaningSlot;

  /// `guess`: how many options the row's question has stored.
  final int optionCount;

  /// The card's `back_folded`.
  final String meaningFolded;
}

/// A card the options of a `guess` question can come from: its id and its
/// meaning, compared folded (BR-STUDY-038, BR-STUDY-039).
typedef MeaningCard = ({String cardId, String meaningFolded});

/// What preparing a round writes (spec §7.7). Empty when the round has all
/// it needs.
final class RoundPreparation {
  const RoundPreparation({
    this.meaningSlots = const {},
    this.questions = const {},
  });

  /// `match`: the meaning slot of each card of a board that lacked one.
  final Map<String, int> meaningSlots;

  /// `guess`: each card whose question is built again, with its five options
  /// in the order shown, or null when it cannot be built (BR-STUDY-040).
  final Map<String, List<String>?> questions;

  bool get isEmpty => meaningSlots.isEmpty && questions.isEmpty;
}
```

In `lib/features/study_mode/domain/models/study_answer_model.dart`:

Replace

```dart
/// What the person did on one card (UC-STUDY-001 step 6). Package 2b gives
/// the graded modes their own inputs; here they hand in a verdict.
sealed class StudyAnswer {
```

with

```dart
/// What the person did on one card (UC-STUDY-001 step 6): each mode takes its
/// own input (graded modes spec §7.1).
sealed class StudyAnswer {
```

Replace

```dart

/// A graded mode's verdict (BR-MODE-011, BR-MODE-012).
final class GradedAnswer extends StudyAnswer {
```

with

```dart

/// A graded mode's verdict (BR-MODE-011, BR-MODE-012). Package 2a's stand-in
/// for the real inputs below; the session stops taking it in Task 6.
final class GradedAnswer extends StudyAnswer {
```

Replace

```dart
  final bool isCorrect;
}
```

with

```dart
  final bool isCorrect;
}

/// `fill`: the term the person typed. It is judged and never stored
/// (BR-STUDY-030).
final class FillAnswer extends StudyAnswer {
  const FillAnswer(this.typed);

  final String typed;
}

/// `recall`: the person's self-assessment once the answer is revealed, or the
/// end of the turn's time (BR-STUDY-032, BR-STUDY-065).
final class RecallAnswer extends StudyAnswer {
  const RecallAnswer(this.outcome);

  final RecallOutcome outcome;
}

enum RecallOutcome { remembered, forgot, timedOut }

/// `guess`: the option chosen, by card id (BR-STUDY-041).
final class GuessAnswer extends StudyAnswer {
  const GuessAnswer(this.chosenCardId);

  final String chosenCardId;
}

/// `match`: the meaning paired with the turn's card, which owns the term
/// (BR-STUDY-062).
final class MatchAnswer extends StudyAnswer {
  const MatchAnswer(this.meaningCardId);

  final String meaningCardId;
}
```

Create `lib/features/study_mode/domain/models/turn_judgement_model.dart`:

```dart
/// What a turn reads of its card (graded modes spec §7.2).
final class TurnCard {
  const TurnCard({
    required this.cardId,
    required this.frontFolded,
    required this.backFolded,
  });

  final String cardId;

  /// `fill` compares the typed term with it (BR-STUDY-026).
  final String frontFolded;

  /// `match` compares two meanings by it (spec D3).
  final String backFolded;
}

/// The facts a mode judges a turn on. The session reads them in the turn's
/// transaction, so the judging itself stays a pure function (spec §7.2).
final class TurnContext {
  const TurnContext({
    required this.card,
    this.isRevealed = false,
    this.isHintShown = false,
    this.guessOptionIds,
    this.boardMeanings = const {},
  });

  final TurnCard card;

  /// `recall`: the answer of this turn has been revealed (BR-STUDY-065).
  final bool isRevealed;

  /// `fill`: the hint of this turn has been shown (BR-STUDY-028).
  final bool isHintShown;

  /// `guess`: the stored options of the row, in the order shown; null when
  /// none are stored.
  final List<String>? guessOptionIds;

  /// `match`: the pending pairs of the current board, card id to
  /// `back_folded`.
  final Map<String, String> boardMeanings;
}

/// Why a wrong outcome was recorded without the person choosing it, stored
/// as its code on `review_log.outcome_reason` (BR-STUDY-034).
enum OutcomeReason {
  timeout('timeout');

  const OutcomeReason(this.code);

  final String code;
}

/// What a mode makes of a turn (spec §7.2): the action it records, whether a
/// graded answer was right, what `review_log` keeps of the turn, and for
/// `match` the card whose meaning slot the turn's card takes.
final class TurnVerdict {
  const TurnVerdict({
    required this.action,
    this.isCorrect,
    this.outcomeReason,
    this.comparisonVersion,
    this.usedHint,
    this.takesMeaningSlotOf,
  });

  /// One of the scheduler's actions; null for `browse`, which records none.
  final Object? action;

  /// Null for `browse` and `self_assess`, whose result the person chose.
  final bool? isCorrect;
  final OutcomeReason? outcomeReason;

  /// `fill` only (BR-STUDY-027).
  final int? comparisonVersion;

  /// `fill` only (BR-STUDY-028).
  final bool? usedHint;

  /// `match`: a right pair on another card's equal meaning. The two rows swap
  /// their meaning slots, so the tile the person tapped is the one matched
  /// (spec §7.6).
  final String? takesMeaningSlotOf;
}
```

- [ ] **Step 4: Give every handler judge and prepareRound**

In `lib/features/study_mode/domain/models/browse_mode.dart`:

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

```

Replace

```dart
    SelfAssessAnswer() ||
    GradedAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };
```

with

```dart
    SelfAssessAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) => switch (answer) {
    AdvanceAnswer() => const Ok(TurnVerdict(action: null)),
    SelfAssessAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };
```

In `lib/features/study_mode/domain/models/graded_mode.dart`:

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

```

Replace

```dart
/// BR-MODE-012 says, and rounds that repeat the wrong cards until a round ends
/// with none, with no cap (BR-STUDY-059, BR-STUDY-069). `recall` uses this
/// class as it is; `match`, `guess` and `fill` add their data condition.
base class GradedModeHandler extends StudyModeHandler {
  const GradedModeHandler();
```

with

```dart
/// BR-MODE-012 says, and rounds that repeat the wrong cards until a round ends
/// with none, with no cap (BR-STUDY-059, BR-STUDY-069). Each mode judges its
/// own input (graded modes spec §7).
abstract base class GradedModeHandler extends StudyModeHandler {
  const GradedModeHandler();
```

Replace

```dart
    }
    final action = answer.isCorrect
        ? EightBoxAction.remembered
        : EightBoxAction.forgotten;
    if (!scheduler.supportedActions.contains(action)) {
      return const Rejected(StudyModeRejection.unsupportedAction);
    }
    return Ok(action);
  }

```

with

```dart
    }
    return _actionOf(answer.isCorrect, scheduler);
  }

  /// The verdict of a right or wrong answer: right is `remembered`, wrong is
  /// `forgotten`, and every level short of right is wrong (BR-MODE-012,
  /// BR-STUDY-070). The other fields are what `review_log` keeps of the turn.
  Outcome<TurnVerdict, StudyModeRejection> verdictOf(
    bool isCorrect,
    SrsScheduler scheduler, {
    OutcomeReason? outcomeReason,
    int? comparisonVersion,
    bool? usedHint,
    String? takesMeaningSlotOf,
  }) => switch (_actionOf(isCorrect, scheduler)) {
    Rejected(:final reason) => Rejected(reason),
    Ok(value: final action) => Ok(
      TurnVerdict(
        action: action,
        isCorrect: isCorrect,
        outcomeReason: outcomeReason,
        comparisonVersion: comparisonVersion,
        usedHint: usedHint,
        takesMeaningSlotOf: takesMeaningSlotOf,
      ),
    ),
  };

```

Replace

```dart

const GradedModeHandler recallMode = GradedModeHandler();
```

with

```dart

/// The action of a right or wrong answer, when [scheduler] has it.
Outcome<Object?, StudyModeRejection> _actionOf(
  bool isCorrect,
  SrsScheduler scheduler,
) {
  final action = isCorrect
      ? EightBoxAction.remembered
      : EightBoxAction.forgotten;
  if (!scheduler.supportedActions.contains(action)) {
    return const Rejected(StudyModeRejection.unsupportedAction);
  }
  return Ok(action);
}
```

In `lib/features/study_mode/domain/models/self_assess_mode.dart`:

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

```

Replace

```dart
    AdvanceAnswer() ||
    GradedAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };
```

with

```dart
    AdvanceAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) => switch (answer) {
    SelfAssessAnswer(:final action)
        when scheduler.supportedActions.contains(action) =>
      Ok(TurnVerdict(action: action)),
    SelfAssessAnswer() => const Rejected(StudyModeRejection.unsupportedAction),
    AdvanceAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };
```

In `lib/features/study_mode/domain/models/study_mode.dart`:

Replace

```dart
import 'package:memox/core/error/outcome.dart';
```

with

```dart
import 'dart:math';

import 'package:memox/core/error/outcome.dart';
```

Replace

```dart
import 'package:memox/features/study_mode/domain/models/fill_mode.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
```

with

```dart
import 'package:memox/features/study_mode/domain/models/fill_mode.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
```

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

```

Replace

```dart
  /// records none, or why [answer] does not fit (BR-MODE-011, BR-MODE-012).
  Outcome<Object?, StudyModeRejection> actionOf(
```

with

```dart
  /// records none, or why [answer] does not fit (BR-MODE-011, BR-MODE-012).
  /// Package 2a's path, which [judge] replaces in Task 6.
  Outcome<Object?, StudyModeRejection> actionOf(
```

Replace

```dart
    SrsScheduler scheduler,
  );

  /// What a turn does to its row: [lapsed] when its action was
```

with

```dart
    SrsScheduler scheduler,
  );

  /// What [answer] makes of the turn [context] describes under [scheduler],
  /// or why it does not fit (graded modes spec §7.2). The session reads the
  /// facts and writes what the verdict says.
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  );

  /// Whether a question shows stored options, which the session then reads
  /// with their meaning source (`guess`, spec §7.7).
  bool get asksWithOptions => false;

  /// What the round of [rows] needs before it is served: nothing but for
  /// `match` boards and `guess` questions (spec §7.7).
  RoundPreparation prepareRound(
    List<RoundRowFacts> rows, {
    required List<MeaningCard> meaningSource,
    required Random random,
  }) => const RoundPreparation();

  /// What a turn does to its row: [lapsed] when its action was
```

- [ ] **Step 5: Judge fill and recall**

In `lib/features/study_mode/domain/models/fill_mode.dart`:

Replace

```dart
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// `fill`: type the term. Only a card with an `example` can be asked; the
/// others are skipped in this stage and still take part in the rest
/// (BR-STUDY-044, BR-STUDY-071).
final class FillModeHandler extends GradedModeHandler {
```

with

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// The comparison policy a `fill` turn is judged by, stored on the turn: the
/// typed term, trimmed and lower-cased with its accents kept, against
/// `front_folded`. A change to the policy raises it and never touches the
/// turns already recorded (BR-STUDY-026, BR-STUDY-027).
const fillComparisonVersion = 1;

/// `fill`: the meaning is shown and the person types the term. Only a card
/// with an `example` can be asked; the others are skipped in this stage and
/// still take part in the rest (BR-STUDY-044, BR-STUDY-071).
final class FillModeHandler extends GradedModeHandler {
```

Replace

```dart
    return StageRuns(withExample);
  }
}

```

with

```dart
    return StageRuns(withExample);
  }

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! FillAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final typed = foldText(answer.typed);
    if (typed.isEmpty) return const Rejected(StudyModeRejection.emptyAnswer);
    return verdictOf(
      typed == context.card.frontFolded,
      scheduler,
      comparisonVersion: fillComparisonVersion,
      usedHint: context.isHintShown,
    );
  }
}

```

Create `lib/features/study_mode/domain/models/recall_mode.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// The time of one `recall` turn, measured in interaction time by the screen
/// (BR-STUDY-031).
const recallTurnMs = 20000;

/// `recall`: the term is shown and the meaning hidden for [recallTurnMs].
/// Revealing the meaning records nothing; only the person's self-assessment
/// after it does, once, and the end of the time records wrong
/// (BR-STUDY-031 to BR-STUDY-036, BR-STUDY-065, BR-STUDY-066).
final class RecallModeHandler extends GradedModeHandler {
  const RecallModeHandler();

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! RecallAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final outcome = answer.outcome;
    if (outcome == RecallOutcome.timedOut) {
      // Once the answer is shown, the time has stopped (BR-STUDY-032).
      if (context.isRevealed) {
        return const Rejected(StudyModeRejection.alreadyRevealed);
      }
      return verdictOf(false, scheduler, outcomeReason: OutcomeReason.timeout);
    }
    if (!context.isRevealed) {
      return const Rejected(StudyModeRejection.notRevealed);
    }
    return verdictOf(outcome == RecallOutcome.remembered, scheduler);
  }
}

const RecallModeHandler recallMode = RecallModeHandler();
```

- [ ] **Step 6: Judge guess and match, and build their questions and boards**

Replace the whole of `lib/features/study_mode/domain/models/guess_mode.dart` with:

```dart
import 'dart:math';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// Each question shows one answer and four distractors, five distinct
/// meanings in all (BR-STUDY-037, BR-STUDY-039).
const _optionCount = 5;

/// `guess`: pick the meaning among five. The stage runs when its distractor
/// source (the session's cards and the learned, active cards of the root's
/// tree, BR-STUDY-038) holds five distinct meanings, however few cards the
/// session has (BR-STUDY-040; spec D5; IT-MODE-015).
final class GuessModeHandler extends GradedModeHandler {
  const GuessModeHandler();

  @override
  bool get asksWithOptions => true;

  @override
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    if (distinctMeaningCount < _optionCount) {
      return const StageSkipped(ModeUnavailableReason.tooFewMeanings);
    }
    return super.eligibility(cards, distinctMeaningCount: distinctMeaningCount);
  }

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! GuessAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final options = context.guessOptionIds;
    if (options == null || options.length != _optionCount) {
      return const Rejected(StudyModeRejection.questionBlocked);
    }
    if (!options.contains(answer.chosenCardId)) {
      return const Rejected(StudyModeRejection.notAnOption);
    }
    return verdictOf(answer.chosenCardId == context.card.cardId, scheduler);
  }

  /// A question for every pending row that lacks its five options; a
  /// question with them is never built again (BR-STUDY-043; spec D8).
  @override
  RoundPreparation prepareRound(
    List<RoundRowFacts> rows, {
    required List<MeaningCard> meaningSource,
    required Random random,
  }) {
    final byPosition = [...rows]
      ..sort((a, b) => a.position.compareTo(b.position));
    return RoundPreparation(
      questions: {
        for (final row in byPosition)
          if (row.isPending && row.optionCount != _optionCount)
            row.cardId: guessOptionsFor(
              (cardId: row.cardId, meaningFolded: row.meaningFolded),
              meaningSource,
              random,
            ),
      },
    );
  }
}

const GuessModeHandler guessMode = GuessModeHandler();

/// The five options of a question on [asked], in the order shown, or null
/// when [source] holds fewer than four meanings besides [asked]'s, so the
/// question is blocked (BR-STUDY-037 to BR-STUDY-040; spec §7.5). One card
/// stands for each meaning, never one with [asked]'s meaning; the order is a
/// shuffle of its own, apart from the round's (BR-STUDY-043). Groups and
/// cards are sorted before drawing, so a seeded [random] repeats whatever
/// order [source] comes in.
List<String>? guessOptionsFor(
  MeaningCard asked,
  List<MeaningCard> source,
  Random random,
) {
  final cardsByMeaning = <String, List<String>>{};
  for (final card in source) {
    if (card.cardId == asked.cardId) continue;
    if (card.meaningFolded == asked.meaningFolded) continue;
    (cardsByMeaning[card.meaningFolded] ??= []).add(card.cardId);
  }
  if (cardsByMeaning.length < _optionCount - 1) return null;
  final meanings = cardsByMeaning.keys.toList()
    ..sort()
    ..shuffle(random);
  final options = [
    asked.cardId,
    for (final meaning in meanings.take(_optionCount - 1))
      _oneOf(cardsByMeaning[meaning]!..sort(), random),
  ];
  return options..shuffle(random);
}

String _oneOf(List<String> cardIds, Random random) =>
    cardIds[random.nextInt(cardIds.length)];
```

Replace the whole of `lib/features/study_mode/domain/models/match_mode.dart` with:

```dart
import 'dart:math';

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

/// One pair on the board is its own answer (BR-STUDY-045).
const _minimumPairs = 2;

/// The pairs a board shows at most (BR-STUDY-049).
const matchBoardSize = 5;

/// The board of the row at [position]: consecutive positions of the round,
/// [matchBoardSize] at a time; the last board takes what is left
/// (BR-STUDY-049).
int matchBoardOf(int position) => position ~/ matchBoardSize;

/// `match`: the pairs of a round on boards of [matchBoardSize]. A turn is the
/// term card's and is judged by meaning, so a meaning equal to the term's own
/// is right (BR-STUDY-062; spec D3). A wrong pair keeps its row on the board
/// and sends the card to the next round (BR-STUDY-062).
final class MatchModeHandler extends GradedModeHandler {
  const MatchModeHandler();

  @override
  bool get servesInOrder => false;

  @override
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    if (cards.length < _minimumPairs) {
      return const StageSkipped(ModeUnavailableReason.tooFewPairs);
    }
    return super.eligibility(cards, distinctMeaningCount: distinctMeaningCount);
  }

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
    StudyAnswer answer,
    TurnContext context,
    SrsScheduler scheduler,
  ) {
    if (answer is! MatchAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final meaning = context.boardMeanings[answer.meaningCardId];
    if (meaning == null) return const Rejected(StudyModeRejection.notOnBoard);
    final isCorrect = meaning == context.card.backFolded;
    final takesOtherSlot =
        isCorrect && answer.meaningCardId != context.card.cardId;
    return verdictOf(
      isCorrect,
      scheduler,
      takesMeaningSlotOf: takesOtherSlot ? answer.meaningCardId : null,
    );
  }

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const StayAndEnroll();
  }

  /// Meaning slots for every board with a row that lacks one, the matched
  /// pairs included; a board that has its slots keeps them (spec D7, D8).
  @override
  RoundPreparation prepareRound(
    List<RoundRowFacts> rows, {
    required List<MeaningCard> meaningSource,
    required Random random,
  }) {
    final boards = <int, List<RoundRowFacts>>{};
    for (final row in rows) {
      (boards[matchBoardOf(row.position)] ??= []).add(row);
    }
    final slots = <String, int>{};
    for (final board in boards.keys.toList()..sort()) {
      final pairs = boards[board]!
        ..sort((a, b) => a.position.compareTo(b.position));
      if (pairs.every((pair) => pair.meaningSlot != null)) continue;
      final shuffled = meaningSlotsFor(pairs.length, random);
      for (final (index, pair) in pairs.indexed) {
        slots[pair.cardId] = shuffled[index];
      }
    }
    return RoundPreparation(meaningSlots: slots);
  }
}

const MatchModeHandler matchMode = MatchModeHandler();

/// The slot of each meaning on a board of [pairCount] pairs, in the order of
/// its terms: a shuffle with [random] that never keeps that order when there
/// are two or more pairs; if it did, the first two swap (spec D7).
List<int> meaningSlotsFor(int pairCount, Random random) {
  final slots = [for (var slot = 0; slot < pairCount; slot++) slot]
    ..shuffle(random);
  if (pairCount < _minimumPairs) return slots;
  var keptOrder = true;
  for (var index = 0; index < pairCount; index++) {
    if (slots[index] != index) keptOrder = false;
  }
  if (!keptOrder) return slots;
  return [slots[1], slots[0], ...slots.skip(2)];
}
```

- [ ] **Step 7: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/study/domain/study_failure_test.dart \
  test/features/study_mode/domain/guess_question_test.dart \
  test/features/study_mode/domain/match_board_test.dart \
  test/features/study_mode/domain/turn_judging_test.dart
```

Expected: `+28: All tests passed!`

- [ ] **Step 9: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1245: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add lib/features/study/domain/failures/study_failure.dart \
  lib/features/study_mode/domain/failures/study_mode_failure.dart \
  lib/features/study_mode/domain/models/browse_mode.dart \
  lib/features/study_mode/domain/models/fill_mode.dart \
  lib/features/study_mode/domain/models/graded_mode.dart \
  lib/features/study_mode/domain/models/guess_mode.dart \
  lib/features/study_mode/domain/models/match_mode.dart \
  lib/features/study_mode/domain/models/recall_mode.dart \
  lib/features/study_mode/domain/models/round_preparation_model.dart \
  lib/features/study_mode/domain/models/self_assess_mode.dart \
  lib/features/study_mode/domain/models/study_answer_model.dart \
  lib/features/study_mode/domain/models/study_mode.dart \
  lib/features/study_mode/domain/models/turn_judgement_model.dart \
  test/features/study/domain/study_failure_test.dart \
  test/features/study_mode/domain/guess_question_test.dart \
  test/features/study_mode/domain/match_board_test.dart \
  test/features/study_mode/domain/turn_judging_test.dart
git commit -F - <<'EOF'
feat(study_mode): each graded mode judges the person's real input

fill compares the folded typed term with the card's front, keeps its
diacritics and records the comparison version and the hint; recall takes the
person's self-assessment after a reveal, or a timeout before one; guess takes
one of its five stored options and builds a question from one card per other
meaning; match takes a meaning of the current board, right when the folded
meanings are equal, and shuffles each board's meanings unlike its terms
(BR-STUDY-026 to BR-STUDY-043, BR-STUDY-049, BR-STUDY-062, BR-STUDY-065,
BR-STUDY-070). Judging is a pure function of the answer and the facts the
session hands in; package 2a's actionOf stays until the session moves over.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: A round gets its guess questions and match boards when it is served

**Files:**
- Create: `lib/features/study/data/datasources/study_round_dao.dart`, `lib/features/study/data/datasources/study_round_data_source.dart`
- Modify: `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/data/mappers/study_session_view_mapper.dart`, `lib/features/study/data/repositories/study_entry_repository_impl.dart`, `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/data/repositories/study_session_view_repository_impl.dart`, `lib/features/study/domain/models/study_session_view_model.dart`, `lib/features/study_mode/domain/models/guess_mode.dart`, `docs/features/study/data.md`
- Test (create): `test/features/study/data/round_preparation_test.dart`
- Test (modify): `test/support/study_fixtures.dart`

**Interfaces:**
- Consumes: Task 3's `prepareRound`, `asksWithOptions`, `RoundRowFacts`,
  `MeaningCard`, `matchBoardOf`, `matchBoardSize`; `shuffledUnlike`
  (`queue_plan_model.dart`); `StudyQueueDao.cardsOf` and `build`; Task 2's view
  repository and `StudyViewDao`.
- Produces:
  - `StudyRoundDao(AppDatabase db)` with `builtRows(sessionId, mode, round)` →
    `Future<List<RoundRowRecord>>`, `meaningSource(sessionId, rootId)` →
    `Future<List<({String cardId, String meaningFolded})>>`,
    `setMeaningSlots(sessionId, mode, round, Map<String, int> slots)` and
    `replaceOptions(sessionId, round, cardId, List<String>? optionIds)`.
  - `StudyRoundDataSource(AppDatabase db, Random random)` with
    `build(String sessionId, String rootId, StudyMode mode, int round)` and
    `prepare(String sessionId, String rootId, StudyMode mode, int round)`; the
    entry repository prepares round 1 of a review, and the session repository
    prepares a stage's round 1, every new round and, on Continue, the round it
    serves.
  - `const guessOptionCount = 5` (was private in `guess_mode.dart`).
  - `StudySessionView.board` (`MatchBoard?`); `StudyItem.guess`
    (`GuessQuestion?`); `GuessQuestion(List<GuessOption> options)` with
    `bool get isBlocked`; `GuessOption({required String cardId, required String meaning})`;
    `MatchBoard({required List<MatchTile> terms, required List<MatchTile> meanings})`;
    `MatchTile({required String cardId, required String text, required bool isMatched})`.
  - `StudyViewDao.guessOptions(sessionId, round, cardId)` and
    `boardPairs(sessionId, mode, round, {required int from, required int to})`.
  - Test fixtures: `optionsOf(db, sessionId, cardId, {int round = 1})` and
    `meaningSlotsOf(db, sessionId, {int round = 1})`.

Spec §8.2, §9 and D7, D8; Clarifications 6, 9. Preparing is
idempotent: a board with its slots and a question with its five options stay
as they are, so Continue fills in only what a session from before v2 lacks, or
a question that lost an option to a card deletion. A `QueryInterceptor` local
to the test file thins the meaning source for the blocked question; Task 6
moves it to `test_database.dart`.

- [ ] **Step 1: Write the failing tests**

In `test/support/study_fixtures.dart`:

Replace

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
```

Replace

```dart
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
```

with

```dart
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';
```

Replace

```dart
    row.read<String>('kind'),
];
```

with

```dart
    row.read<String>('kind'),
];

/// The options of [cardId]'s question in [round] of `guess`, in the order
/// shown (graded modes spec §6.2).
Future<List<String>> optionsOf(
  AppDatabase db,
  String sessionId,
  String cardId, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT option_card_id FROM study_guess_options'
            ' WHERE session_id = ? AND round = ? AND card_id = ? ORDER BY slot',
            variables: [Variable(sessionId), Variable(round), Variable(cardId)],
          )
          .get())
    row.read<String>('option_card_id'),
];

/// The meaning slot of each card of [round] of `match`, in position order
/// (graded modes spec §6.1).
Future<Map<String, int?>> meaningSlotsOf(
  AppDatabase db,
  String sessionId, {
  int round = 1,
}) async => {
  for (final row
      in await db
          .customSelect(
            'SELECT card_id, meaning_slot FROM study_queue_items'
            " WHERE session_id = ? AND mode = 'match' AND round = ?"
            ' ORDER BY position',
            variables: [Variable(sessionId), Variable(round)],
          )
          .get())
    row.read<String>('card_id'): row.read<int?>('meaning_slot'),
};

/// Answers the card [sessionId] serves in its current mode, or [cardId],
/// right or wrong as [right] says. A refusal fails the test.
Future<void> answerServed(
  AppDatabase db,
  StudySessionRepositoryImpl sessions,
  String sessionId, {
  required bool right,
  String? cardId,
}) async {
  final mode = (await sessionOf(db, sessionId)).read<String>('current_mode');
  final card = cardId ?? await servedCard(db, sessionId);
  final outcome = await sessions.answerTurn(
    sessionId: sessionId,
    cardId: card!,
    answer: mode == 'browse'
        ? const AdvanceAnswer()
        : GradedAnswer(isCorrect: right),
  );
  expect(outcome, isA<Ok<void, StudyRejection>>(), reason: 'answer on $card');
}
```

Create `test/features/study/data/round_preparation_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Graded modes spec §8.2: a round gets what it needs when it starts being
// served, the options of its guess questions and the meaning slots of its
// match boards, and keeps them.

/// Cuts the meaning source of a guess question to the rows [keep] names,
/// the way the fault injector of S-STUDY-GUESS-BLOCKED-V2 does, with the
/// database untouched.
final class _ThinMeaningSource extends QueryInterceptor {
  _ThinMeaningSource(this.keep);

  final int keep;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    if (!statement.contains('AS meaning_folded')) return rows;
    return rows.take(keep).toList();
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);

  void open(AppDatabase database) {
    db = database;
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  Future<(DeckEntity, DeckEntity)> tree([String name = 'Korean']) async {
    final root = await decks.root(name);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  /// A learned card of [deckId], due now when [due], of the meaning [back].
  Future<void> learned(
    DeckEntity root,
    String deckId,
    String id, {
    required String back,
    bool due = false,
  }) async {
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      back: back,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: due ? DateTime(2026, 9, 20) : DateTime(2026, 10, 20),
    );
    await lockScheduler(db, root.id);
  }

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  /// Five due cards of five meanings under a fresh tree.
  Future<DeckEntity> fiveDue() async {
    final (root, leaf) = await tree();
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'library',
    ].indexed) {
      await learned(root, leaf.id, 'c$index', back: meaning, due: true);
    }
    return leaf;
  }

  test('the options come from the learned cards of the same tree: no new card '
      'outside the session, no card of another root, one card per meaning '
      '(BR-STUDY-037 to BR-STUDY-039; IT-MODE-015)', () async {
    final (root, leaf) = await tree('A');
    await learned(root, leaf.id, 'asked', back: 'library', due: true);
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
    ].indexed) {
      await learned(root, leaf.id, 'd$index', back: meaning);
    }
    await learned(root, leaf.id, 'variant', back: '  KITCHEN ');
    await insertCard(db, id: 'new', deckId: leaf.id, back: 'new-only-secret');
    final (other, otherLeaf) = await tree('B');
    await learned(other, otherLeaf.id, 'other', back: 'other-root-secret');

    final id = await review(leaf.id, StudyMode.guess);
    final question = (await viewOf(id)).currentItem!.guess!;

    expect(question.isBlocked, isFalse);
    final meanings = [
      for (final option in question.options)
        option.meaning.trim().toLowerCase(),
    ];
    expect(meanings.toSet(), {
      'library',
      'kitchen',
      'school',
      'office',
      'garden',
    });
    expect([
      for (final option in question.options) option.cardId,
    ], containsOnce('asked'));
  });

  test('the options and the card order stay as they are across Continue, and '
      'a new round has its own order and its own questions (BR-STUDY-043, '
      'BR-STUDY-061; IT-MODE-007)', () async {
    final leaf = await fiveDue();
    final id = await review(leaf.id, StudyMode.guess);
    final order = await queueOf(db, id, 'guess');
    final questions = {
      for (final card in order) card: await optionsOf(db, id, card),
    };
    for (final options in questions.values) {
      expect(options, hasLength(5));
    }

    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    expect(await queueOf(db, id, 'guess'), order);
    for (final card in order) {
      expect(await optionsOf(db, id, card), questions[card], reason: card);
    }

    await answerServed(db, sessions, id, right: false);
    await answerServed(db, sessions, id, right: false);
    for (var turn = 0; turn < 3; turn++) {
      await answerServed(db, sessions, id, right: true);
    }
    final second = await queueOf(db, id, 'guess', round: 2);
    expect(second.toSet(), {order[0], order[1]});
    expect(second, isNot([order[0], order[1]]));
    for (final card in second) {
      expect(await optionsOf(db, id, card, round: 2), hasLength(5));
    }
  });

  test('a learning session prepares its guess questions when the stage '
      'starts, not when it opens (spec D8)', () async {
    final (_, leaf) = await tree();
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'library',
    ].indexed) {
      await insertCard(db, id: 'n$index', deckId: leaf.id, back: meaning);
    }
    final id = ((await entries.openLearningSession(
      deckId: leaf.id,
    )) as Ok<String, StudyRejection>).value;
    final guessed = await queueOf(db, id, 'guess');
    expect(await optionsOf(db, id, guessed.first), isEmpty);

    while ((await sessionOf(db, id)).read<String>('current_mode') != 'guess') {
      await answerServed(db, sessions, id, right: true);
    }
    for (final card in guessed) {
      expect(await optionsOf(db, id, card), hasLength(5), reason: card);
    }
  });

  test('a review opened in match gives every board its meaning slots, never '
      "in its terms' order, and the view shows the board (BR-STUDY-049; "
      'spec D7)', () async {
    final (root, leaf) = await tree();
    for (var index = 0; index < 7; index++) {
      await learned(
        root,
        leaf.id,
        'c$index',
        back: 'meaning $index',
        due: true,
      );
    }
    final id = await review(leaf.id, StudyMode.match);
    final order = await queueOf(db, id, 'match');
    final slots = await meaningSlotsOf(db, id);

    final first = [for (final card in order.take(5)) slots[card]];
    expect(first.toSet(), {0, 1, 2, 3, 4});
    expect(first, isNot([0, 1, 2, 3, 4]));
    expect([for (final card in order.skip(5)) slots[card]], [1, 0]);

    final board = (await viewOf(id)).board!;
    expect([for (final tile in board.terms) tile.cardId], order.take(5));
    expect(
      [for (final tile in board.meanings) slots[tile.cardId]],
      [0, 1, 2, 3, 4],
    );
    expect(board.terms.every((tile) => !tile.isMatched), isTrue);
  });

  test('the board keeps its tiles in place and marks the pairs matched in the '
      'round (BR-STUDY-049; the backend half of IT-MODE-003)', () async {
    final (root, leaf) = await tree();
    for (var index = 0; index < 3; index++) {
      await learned(
        root,
        leaf.id,
        'c$index',
        back: 'meaning $index',
        due: true,
      );
    }
    final id = await review(leaf.id, StudyMode.match);
    final before = (await viewOf(id)).board!;
    final matched = before.terms.first.cardId;

    await answerServed(db, sessions, id, right: true, cardId: matched);

    final after = (await viewOf(id)).board!;
    expect(
      [for (final tile in after.terms) tile.cardId],
      [for (final tile in before.terms) tile.cardId],
    );
    expect(
      [for (final tile in after.meanings) tile.cardId],
      [for (final tile in before.meanings) tile.cardId],
    );
    expect(
      {
        for (final tile in [...after.terms, ...after.meanings])
          if (tile.isMatched) tile.cardId,
      },
      {matched},
    );
  });

  test('Continue fills in what a round lacks, as a session from before v2 '
      'has: the questions of guess and the slots of match (spec §6.5, '
      '§8.2)', () async {
    final leaf = await fiveDue();
    final guessId = await review(leaf.id, StudyMode.guess);
    await db.customStatement('DELETE FROM study_guess_options');
    expect((await viewOf(guessId)).currentItem!.guess!.isBlocked, isTrue);

    await sessions.resumeSession(sessionId: guessId);
    for (final card in await queueOf(db, guessId, 'guess')) {
      expect(await optionsOf(db, guessId, card), hasLength(5), reason: card);
    }

    final matchId = await review(leaf.id, StudyMode.match);
    await db.customStatement(
      'UPDATE study_queue_items SET meaning_slot = NULL',
    );
    await sessions.resumeSession(sessionId: matchId);
    expect((await meaningSlotsOf(db, matchId)).values.toSet(), {0, 1, 2, 3, 4});
  });

  test('a question that lost an option to a deleted card is blocked until '
      'Continue builds it again from what is left (BR-STUDY-040; spec '
      '§8.2)', () async {
    final (root, leaf) = await tree();
    await learned(root, leaf.id, 'asked', back: 'library', due: true);
    for (final (index, meaning) in [
      'kitchen',
      'school',
      'office',
      'garden',
      'river',
    ].indexed) {
      await learned(root, leaf.id, 'd$index', back: meaning);
    }
    final id = await review(leaf.id, StudyMode.guess);
    final gone = (await optionsOf(
      db,
      id,
      'asked',
    )).firstWhere((card) => card != 'asked');
    await db.customStatement("DELETE FROM card WHERE id = '$gone'");

    expect(await optionsOf(db, id, 'asked'), hasLength(4));
    final blocked = (await viewOf(id)).currentItem!.guess!;
    expect(blocked.isBlocked, isTrue);
    expect(blocked.options, isEmpty);

    await sessions.resumeSession(sessionId: id);
    final rebuilt = await optionsOf(db, id, 'asked');
    expect(rebuilt, hasLength(5));
    expect(rebuilt, isNot(contains(gone)));
  });

  test('a question its meaning source cannot fill stores no option, and the '
      'view shows it blocked (BR-STUDY-040)', () async {
    await db.close();
    open(openTestDatabase(interceptor: _ThinMeaningSource(4)));
    final leaf = await fiveDue();
    final id = await review(leaf.id, StudyMode.guess);

    final served = await servedCard(db, id);
    expect(await optionsOf(db, id, served!), isEmpty);
    final question = (await viewOf(id)).currentItem!.guess!;
    expect(question.isBlocked, isTrue);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/round_preparation_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile. The first errors: `Error: The getter 'guess' isn't defined for the type 'StudyItem'.`, `Error: The getter 'board' isn't defined for the type 'StudySessionView'.`

- [ ] **Step 3: Read and write what a round needs**

Create `lib/features/study/data/datasources/study_round_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// A built row of a round, with what preparing the round reads of it.
typedef RoundRowRecord = ({
  String cardId,
  int position,
  bool isPending,
  int? meaningSlot,
  int optionCount,
  String backFolded,
});

/// Row access for preparing a round (graded modes spec §8.2): its built rows,
/// the meaning source of its `guess` questions, the meaning slots of its
/// `match` boards and the stored options. It returns Drift rows and records,
/// never domain values, and runs inside the caller's transaction.
final class StudyRoundDao {
  StudyRoundDao(this._db);

  final AppDatabase _db;

  /// The built rows of [round] of [mode], in position order, with their
  /// card's `back_folded` and the options their question has stored.
  Future<List<RoundRowRecord>> builtRows(
    String sessionId,
    String mode,
    int round,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT q.card_id, q.position, q.status, q.meaning_slot,'
          ' c.back_folded, (SELECT COUNT(*) FROM study_guess_options o'
          '  WHERE o.session_id = q.session_id AND o.mode = q.mode'
          '  AND o.round = q.round AND o.card_id = q.card_id) AS option_count'
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          ' AND q.position >= 0 ORDER BY q.position',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems, _db.card, _db.studyGuessOptions},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('card_id'),
          position: row.read<int>('position'),
          isPending: row.read<String>('status') == 'pending',
          meaningSlot: row.read<int?>('meaning_slot'),
          optionCount: row.read<int>('option_count'),
          backFolded: row.read<String>('back_folded'),
        ),
    ];
  }

  /// The cards a `guess` question of [sessionId] can draw on: those of its
  /// queue and the learned, active cards of [rootId]'s tree, each with its
  /// `back_folded` (BR-STUDY-038; package 2a spec D5). Sorted, so a seeded
  /// draw repeats.
  Future<List<({String cardId, String meaningFolded})>> meaningSource(
    String sessionId,
    String rootId,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT c.id, c.back_folded AS meaning_folded FROM card c'
          ' JOIN deck d ON d.id = c.deck_id'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE d.root_id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL'
          ' AND (cs.learned_at IS NOT NULL OR c.id IN'
          '  (SELECT card_id FROM study_queue_items WHERE session_id = ?))'
          ' ORDER BY c.back_folded, c.id',
          variables: [Variable<String>(rootId), Variable<String>(sessionId)],
          readsFrom: {
            _db.card,
            _db.deck,
            _db.cardSchedule,
            _db.studyQueueItems,
          },
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('id'),
          meaningFolded: row.read<String>('meaning_folded'),
        ),
    ];
  }

  /// Gives each card of [slots] its meaning slot in [round] of [mode].
  Future<void> setMeaningSlots(
    String sessionId,
    String mode,
    int round,
    Map<String, int> slots,
  ) async {
    for (final MapEntry(key: cardId, value: slot) in slots.entries) {
      await (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(sessionId) &
                q.mode.equals(mode) &
                q.round.equals(round) &
                q.cardId.equals(cardId),
          ))
          .write(StudyQueueItemsCompanion(meaningSlot: Value(slot)));
    }
  }

  /// Replaces the options of [cardId]'s question in [round] with
  /// [optionIds], in the order shown; with none when [optionIds] is null.
  Future<void> replaceOptions(
    String sessionId,
    int round,
    String cardId,
    List<String>? optionIds,
  ) async {
    await (_db.delete(_db.studyGuessOptions)..where(
          (o) =>
              o.sessionId.equals(sessionId) &
              o.round.equals(round) &
              o.cardId.equals(cardId),
        ))
        .go();
    if (optionIds == null) return;
    await _db.batch(
      (batch) => batch.insertAll(_db.studyGuessOptions, [
        for (final (slot, optionId) in optionIds.indexed)
          StudyGuessOptionsCompanion.insert(
            sessionId: sessionId,
            round: round,
            cardId: cardId,
            slot: slot,
            optionCardId: optionId,
          ),
      ]),
    );
  }
}
```

- [ ] **Step 4: Build and prepare rounds in one place, for both writers**

Create `lib/features/study/data/datasources/study_round_data_source.dart`:

```dart
import 'dart:math';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_round_dao.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study_mode/domain/models/round_preparation_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// Builds and prepares the rounds of a session, inside the caller's
/// transaction (graded modes spec §8.2). A later round is numbered unlike the
/// round before it (BR-STUDY-061); every round then gets what its mode says
/// it lacks before it is served: the meaning slots of `match` boards, the
/// questions of `guess` (spec §7.7). Both writers of a session share it.
final class StudyRoundDataSource {
  StudyRoundDataSource(AppDatabase db, this._random)
    : _queue = StudyQueueDao(db),
      _rounds = StudyRoundDao(db);

  final StudyQueueDao _queue;
  final StudyRoundDao _rounds;

  /// The shuffles of round orders, board slots and options.
  final Random _random;

  /// Numbers [round] of [mode] unlike the round before it, then prepares it.
  Future<void> build(
    String sessionId,
    String rootId,
    StudyMode mode,
    int round,
  ) async {
    final previous = await _queue.cardsOf(sessionId, mode.code, round - 1);
    final cards = await _queue.cardsOf(sessionId, mode.code, round);
    await _queue.build(
      sessionId,
      mode.code,
      round,
      shuffledUnlike(cards, previous, _random),
    );
    await prepare(sessionId, rootId, mode, round);
  }

  /// Writes what [round] of [mode] lacks, and only that (spec D8): a board
  /// with its slots and a question with its five options stay as they are.
  Future<void> prepare(
    String sessionId,
    String rootId,
    StudyMode mode,
    int round,
  ) async {
    final handler = mode.handler;
    final rows = await _rounds.builtRows(sessionId, mode.code, round);
    final preparation = handler.prepareRound(
      [
        for (final row in rows)
          RoundRowFacts(
            cardId: row.cardId,
            position: row.position,
            isPending: row.isPending,
            meaningSlot: row.meaningSlot,
            optionCount: row.optionCount,
            meaningFolded: row.backFolded,
          ),
      ],
      meaningSource: handler.asksWithOptions
          ? await _rounds.meaningSource(sessionId, rootId)
          : const [],
      random: _random,
    );
    await _rounds.setMeaningSlots(
      sessionId,
      mode.code,
      round,
      preparation.meaningSlots,
    );
    for (final MapEntry(key: cardId, value: options)
        in preparation.questions.entries) {
      await _rounds.replaceOptions(sessionId, round, cardId, options);
    }
  }
}
```

In `lib/features/study/data/repositories/study_entry_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
```

with

```dart
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_round_data_source.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
```

Replace

```dart
final class StudyEntryRepositoryImpl implements StudyEntryRepository {
  StudyEntryRepositoryImpl(
    this._db,
    this._settings, {
    DateTime Function()? now,
    Random? random,
  }) : _dao = StudySessionDao(_db),
       _queue = StudyQueueDao(_db),
       _views = StudyViewDao(_db),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

```

with

```dart
final class StudyEntryRepositoryImpl implements StudyEntryRepository {
  factory StudyEntryRepositoryImpl(
    AppDatabase db,
    SettingsRepository settings, {
    DateTime Function()? now,
    Random? random,
  }) => StudyEntryRepositoryImpl._(
    db,
    settings,
    now ?? DateTime.now,
    random ?? Random(),
  );

  StudyEntryRepositoryImpl._(this._db, this._settings, this._now, this._random)
    : _dao = StudySessionDao(_db),
      _queue = StudyQueueDao(_db),
      _views = StudyViewDao(_db),
      _rounds = StudyRoundDataSource(_db, _random);

```

Replace

```dart
  final Random _random;

```

with

```dart
  final Random _random;

  /// Prepares the round a new session starts in (graded modes spec §8.2).
  final StudyRoundDataSource _rounds;

```

Replace

```dart
            ?.map((direction) => direction.code)
            .toList(),
      );
    }
    return id;
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
```

with

```dart
            ?.map((direction) => direction.code)
            .toList(),
      );
    }
    await _rounds.prepare(id, root.id, queues.first.mode, 1);
    return id;
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
```

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
```

with

```dart
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_round_data_source.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
```

Replace

```dart
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

```

with

```dart
       _queue = StudyQueueDao(_db),
       _rounds = StudyRoundDataSource(_db, random ?? Random()),
       _now = now ?? DateTime.now;

```

Replace

```dart
  final StudyQueueDao _queue;
  final DateTime Function() _now;

  /// Every shuffle of a later round (BR-STUDY-061).
  final Random _random;

```

with

```dart
  final StudyQueueDao _queue;

  /// Builds later rounds and prepares every round the session moves to.
  final StudyRoundDataSource _rounds;
  final DateTime Function() _now;

```

Replace

```dart
          );
          return const Ok(null);
```

with

```dart
          );
          await _prepareServed(sessionId);
          return const Ok(null);
```

Replace

```dart
      if (await _queue.isUnbuilt(session.id, mode.code, round)) {
        await _build(session.id, mode, round);
      }
```

with

```dart
      if (await _queue.isUnbuilt(session.id, mode.code, round)) {
        await _rounds.build(session.id, session.rootId, mode, round);
      } else if (mode != current) {
        // Round 1 of a later stage, built when the session opened, is
        // prepared when the stage starts (graded modes spec D8).
        await _rounds.prepare(session.id, session.rootId, mode, round);
      }
```

Replace

```dart

  /// Shuffles [round], unlike the round before it (BR-STUDY-061).
  Future<void> _build(String sessionId, StudyMode mode, int round) async {
    final previous = await _queue.cardsOf(sessionId, mode.code, round - 1);
    final cards = await _queue.cardsOf(sessionId, mode.code, round);
    await _queue.build(
      sessionId,
      mode.code,
      round,
      shuffledUnlike(cards, previous, _random),
    );
```

with

```dart

  /// Continue fills in what the round the session serves lacks: the
  /// questions and slots of a session from before v2, or a question that
  /// lost an option to a deleted card (graded modes spec §6.5, §8.2).
  Future<void> _prepareServed(String sessionId) async {
    final session = await _dao.sessionRow(sessionId);
    if (session?.status != SessionStatus.inProgress.code) return;
    final round = await _queue.lowestPendingRound(
      sessionId,
      session!.currentMode,
    );
    if (round == null) return;
    await _rounds.prepare(
      sessionId,
      session.rootId,
      StudyMode.fromCode(session.currentMode),
      round,
    );
```

- [ ] **Step 5: Show the question and the board**

In `lib/features/study/data/datasources/study_view_dao.dart`:

Replace

```dart
typedef SummaryCounts = ({int cardCount, int learnedCount, int wrongCount});

```

with

```dart
typedef SummaryCounts = ({int cardCount, int learnedCount, int wrongCount});

/// An option of a `guess` question: the option card and its meaning.
typedef OptionRecord = ({String cardId, String back});

/// A pair of a `match` board: its card's two sides, whether it is matched in
/// the round, and its meaning slot.
typedef BoardPairRecord = ({
  String cardId,
  String front,
  String back,
  bool isCompleted,
  int? meaningSlot,
});

```

Replace

```dart
          _db.studyQueueItems,
          _db.deck,
```

with

```dart
          _db.studyQueueItems,
          _db.studyGuessOptions,
          _db.deck,
```

Replace

```dart

  /// The distinct cards of [sessionId]'s queue, those of them now learned,
```

with

```dart

  /// The options of [cardId]'s question in [round] of `guess`, in the order
  /// shown (graded modes spec §9).
  Future<List<OptionRecord>> guessOptions(
    String sessionId,
    int round,
    String cardId,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT o.option_card_id, c.back FROM study_guess_options o'
          ' JOIN card c ON c.id = o.option_card_id'
          ' WHERE o.session_id = ? AND o.round = ? AND o.card_id = ?'
          ' ORDER BY o.slot',
          variables: [
            Variable<String>(sessionId),
            Variable<int>(round),
            Variable<String>(cardId),
          ],
          readsFrom: {_db.studyGuessOptions, _db.card},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('option_card_id'),
          back: row.read<String>('back'),
        ),
    ];
  }

  /// The pairs of [round] of [mode] at positions [from] to [to], a board, in
  /// position order (graded modes spec §9).
  Future<List<BoardPairRecord>> boardPairs(
    String sessionId,
    String mode,
    int round, {
    required int from,
    required int to,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT q.card_id, q.status, q.meaning_slot, c.front, c.back'
          ' FROM study_queue_items q JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          ' AND q.position BETWEEN ? AND ? ORDER BY q.position',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
            Variable<int>(from),
            Variable<int>(to),
          ],
          readsFrom: {_db.studyQueueItems, _db.card},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('card_id'),
          front: row.read<String>('front'),
          back: row.read<String>('back'),
          isCompleted: row.read<String>('status') == 'completed',
          meaningSlot: row.read<int?>('meaning_slot'),
        ),
    ];
  }

  /// The distinct cards of [sessionId]'s queue, those of them now learned,
```

In `lib/features/study/data/mappers/study_session_view_mapper.dart`:

Replace

```dart
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
```

Replace

```dart

/// The row a session serves, with its card and the counts of its round.
typedef ServedRow = ({StudyQueueItem row, CardRow card, RoundCounts round});

```

with

```dart

/// The row a session serves, with its card and the counts of its round;
/// its question's options in `guess`, and its board in `match`.
typedef ServedRow = ({
  StudyQueueItem row,
  CardRow card,
  RoundCounts round,
  List<OptionRecord>? options,
  List<BoardPairRecord>? board,
});

```

Replace

```dart
            wrongTurnCount: counts.wrongCount,
          ),
  );
}

StudyItem _itemOf(ServedRow served) => StudyItem(
```

with

```dart
            wrongTurnCount: counts.wrongCount,
          ),
    board: switch (served?.board) {
      final List<BoardPairRecord> pairs => _boardOf(pairs),
      null => null,
    },
  );
}

/// The terms in position order, the meanings by their slot (graded modes
/// spec §9).
MatchBoard _boardOf(List<BoardPairRecord> pairs) {
  final bySlot = [...pairs]
    ..sort(
      (a, b) => (a.meaningSlot ?? pairs.length).compareTo(
        b.meaningSlot ?? pairs.length,
      ),
    );
  return MatchBoard(
    terms: [
      for (final pair in pairs)
        MatchTile(
          cardId: pair.cardId,
          text: pair.front,
          isMatched: pair.isCompleted,
        ),
    ],
    meanings: [
      for (final pair in bySlot)
        MatchTile(
          cardId: pair.cardId,
          text: pair.back,
          isMatched: pair.isCompleted,
        ),
    ],
  );
}

/// The question of a `guess` row, blocked unless all five options are
/// stored (BR-STUDY-040).
GuessQuestion _questionOf(List<OptionRecord> options) => GuessQuestion(
  options.length != guessOptionCount
      ? const []
      : [
          for (final option in options)
            GuessOption(cardId: option.cardId, meaning: option.back),
        ],
);

StudyItem _itemOf(ServedRow served) => StudyItem(
```

Replace

```dart
  isRevealed: served.row.isRevealed == 1,
);
```

with

```dart
  isRevealed: served.row.isRevealed == 1,
  guess: switch (served.options) {
    final List<OptionRecord> options => _questionOf(options),
    null => null,
  },
);
```

In `lib/features/study/data/repositories/study_session_view_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';

```

with

```dart
import 'package:memox/features/study/domain/repositories/study_session_view_repository.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

Replace

```dart

  /// The row [session] serves, with its card and the counts of its round;
  /// null while nothing is left to serve (spec D12).
  Future<ServedRow?> _servedOf(StudySession session) async {
```

with

```dart

  /// The row [session] serves, with its card and the counts of its round,
  /// and in `guess` its options, in `match` its board; null while nothing is
  /// left to serve (spec D12).
  Future<ServedRow?> _servedOf(StudySession session) async {
```

Replace

```dart
    if (card == null) return null;
    return (
```

with

```dart
    if (card == null) return null;
    final handler = StudyMode.fromCode(head.mode).handler;
    final board = matchBoardOf(head.position) * matchBoardSize;
    return (
```

Replace

```dart
      round: await _views.roundCounts(session.id, head.mode, head.round),
    );
```

with

```dart
      round: await _views.roundCounts(session.id, head.mode, head.round),
      options: handler.asksWithOptions
          ? await _views.guessOptions(session.id, head.round, head.cardId)
          : null,
      board: handler.servesInOrder
          ? null
          : await _views.boardPairs(
              session.id,
              head.mode,
              head.round,
              from: board,
              to: board + matchBoardSize - 1,
            ),
    );
```

In `lib/features/study/domain/models/study_session_view_model.dart`:

Replace

```dart

/// The session screen (UC-STUDY-001 steps 6–13; spec §8.2). Package 2b adds
/// the `match` board, the `guess` options and the `recall` timer.
final class StudySessionView {
```

with

```dart

/// The session screen (UC-STUDY-001 steps 6–13; spec §8.2), with the
/// `match` board and the `guess` options of package 2b (graded modes spec
/// §9).
final class StudySessionView {
```

Replace

```dart
    required this.summary,
  });
```

with

```dart
    required this.summary,
    this.board,
  });
```

Replace

```dart

  int get currentStageIndex => stages.indexOf(currentMode);
```

with

```dart

  /// `match`: the board of [currentItem], whose first pending pair it is;
  /// null in every other mode (BR-STUDY-049).
  final MatchBoard? board;

  int get currentStageIndex => stages.indexOf(currentMode);
```

Replace

```dart
    required this.isRevealed,
  });
```

with

```dart
    required this.isRevealed,
    this.guess,
  });
```

Replace

```dart
  final bool isRevealed;
}
```

with

```dart
  final bool isRevealed;

  /// `guess`: the question on this card; null in every other mode.
  final GuessQuestion? guess;
}

/// A `guess` question (BR-STUDY-037, BR-STUDY-043).
final class GuessQuestion {
  const GuessQuestion(this.options);

  /// The five options in the order shown; empty while the question is
  /// blocked.
  final List<GuessOption> options;

  /// Fewer than five options could be built or kept: the question is not
  /// shown and takes no answer (BR-STUDY-040).
  bool get isBlocked => options.isEmpty;
}

/// An option of a `guess` question: a card and its meaning. The answer names
/// the card (BR-STUDY-041).
final class GuessOption {
  const GuessOption({required this.cardId, required this.meaning});

  final String cardId;
  final String meaning;
}

/// The `match` board a session serves (BR-STUDY-049): its terms in position
/// order and its meanings in their stored order.
final class MatchBoard {
  const MatchBoard({required this.terms, required this.meanings});

  final List<MatchTile> terms;
  final List<MatchTile> meanings;
}

/// A tile of a board: one side of a card, and whether its pair is matched in
/// this round, so it stays marked in place (IT-MODE-003).
final class MatchTile {
  const MatchTile({
    required this.cardId,
    required this.text,
    required this.isMatched,
  });

  final String cardId;
  final String text;
  final bool isMatched;
}
```

In `lib/features/study_mode/domain/models/guess_mode.dart`:

Replace

```dart
/// meanings in all (BR-STUDY-037, BR-STUDY-039).
const _optionCount = 5;

```

with

```dart
/// meanings in all (BR-STUDY-037, BR-STUDY-039).
const guessOptionCount = 5;

```

Replace

```dart
  }) {
    if (distinctMeaningCount < _optionCount) {
      return const StageSkipped(ModeUnavailableReason.tooFewMeanings);
```

with

```dart
  }) {
    if (distinctMeaningCount < guessOptionCount) {
      return const StageSkipped(ModeUnavailableReason.tooFewMeanings);
```

Replace

```dart
    final options = context.guessOptionIds;
    if (options == null || options.length != _optionCount) {
      return const Rejected(StudyModeRejection.questionBlocked);
```

with

```dart
    final options = context.guessOptionIds;
    if (options == null || options.length != guessOptionCount) {
      return const Rejected(StudyModeRejection.questionBlocked);
```

Replace

```dart
        for (final row in byPosition)
          if (row.isPending && row.optionCount != _optionCount)
            row.cardId: guessOptionsFor(
```

with

```dart
        for (final row in byPosition)
          if (row.isPending && row.optionCount != guessOptionCount)
            row.cardId: guessOptionsFor(
```

Replace

```dart
  }
  if (cardsByMeaning.length < _optionCount - 1) return null;
  final meanings = cardsByMeaning.keys.toList()
```

with

```dart
  }
  if (cardsByMeaning.length < guessOptionCount - 1) return null;
  final meanings = cardsByMeaning.keys.toList()
```

Replace

```dart
    asked.cardId,
    for (final meaning in meanings.take(_optionCount - 1))
      _oneOf(cardsByMeaning[meaning]!..sort(), random),
```

with

```dart
    asked.cardId,
    for (final meaning in meanings.take(guessOptionCount - 1))
      _oneOf(cardsByMeaning[meaning]!..sort(), random),
```

- [ ] **Step 6: Describe how a round is prepared**

In `docs/features/study/data.md`:

Replace

```markdown
Trạng thái kết thúc là terminal — không có đường quay lại `in_progress`.
```

with

```markdown
Trạng thái kết thúc là terminal — không có đường quay lại `in_progress`.

## Dựng round

Một round có được thứ nó cần khi bắt đầu được phục vụ: lúc mở phiên ôn tập, khi phiên
học mới sang một stage, khi dựng một round mới, và khi Tiếp tục.

- `match`: mỗi bàn (các vị trí `5k … 5k+4` của round) có chỗ riêng cho nghĩa của từng
  cặp. Chỗ được xáo theo bàn, và không trùng thứ tự term khi bàn có từ hai cặp
  (BR-STUDY-049).
- `guess`: mỗi dòng `pending` có một câu năm lựa chọn. Nguồn là thẻ trong hàng đợi của
  phiên và thẻ đã học, còn hoạt động, của cây; mỗi nghĩa (`back_folded`) góp tối đa một
  thẻ (BR-STUDY-037, BR-STUDY-038, BR-STUDY-039). Câu không dựng đủ năm lựa chọn thì bị
  chặn (BR-STUDY-040).
- Dựng chỉ bổ sung phần còn thiếu: bàn đã có chỗ và câu đã đủ năm lựa chọn giữ nguyên,
  nên Tiếp tục không đổi thứ tự (BR-STUDY-043). Tiếp tục dựng lại câu đã mất một lựa
  chọn vì card của lựa chọn đó bị xoá hẳn.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/study/data/round_preparation_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 8: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1253: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 9: Commit**

```bash
git add docs/features/study/data.md \
  lib/features/study/data/datasources/study_round_dao.dart \
  lib/features/study/data/datasources/study_round_data_source.dart \
  lib/features/study/data/datasources/study_view_dao.dart \
  lib/features/study/data/mappers/study_session_view_mapper.dart \
  lib/features/study/data/repositories/study_entry_repository_impl.dart \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/data/repositories/study_session_view_repository_impl.dart \
  lib/features/study/domain/models/study_session_view_model.dart \
  lib/features/study_mode/domain/models/guess_mode.dart \
  test/features/study/data/round_preparation_test.dart \
  test/support/study_fixtures.dart
git commit -F - <<'EOF'
feat(study): a round gets its guess questions and match boards when it is served

A round is prepared when it starts being served: when a review opens in guess
or match, when a learning session reaches a stage, when a new round is built,
and on Continue. A guess question stores its five options, drawn from the
learned cards of the tree and the session's own; a match board stores its
meaning slots, never in its terms' order (BR-STUDY-037 to BR-STUDY-040,
BR-STUDY-043, BR-STUDY-049; graded modes spec D7, D8). Both writers prepare
through one data source, which also numbers later rounds, and the session
view shows the question, blocked when it has fewer than five options, and the
board with its matched pairs.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: The recall reveal and time and the fill hint: writes that are not turns

**Files:**
- Create: `lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart`, `lib/features/study/domain/usecases/save_recall_time_use_case.dart`, `lib/features/study/domain/usecases/show_fill_hint_use_case.dart`
- Modify: `lib/features/study/data/datasources/study_queue_dao.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/mappers/study_session_view_mapper.dart`, `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/domain/failures/study_failure.dart`, `lib/features/study/domain/models/study_session_view_model.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`, `lib/features/study_mode/domain/models/recall_mode.dart`, `lib/features/study_mode/domain/models/study_mode.dart`, `docs/features/study/data.md`
- Test (create): `test/features/study/data/turn_state_writes_test.dart`, `test/features/study/domain/turn_state_use_cases_test.dart`
- Test (modify): `test/support/card_fixtures.dart`

**Interfaces:**
- Consumes: `_live` and `_write` of `StudySessionRepositoryImpl`;
  `StudyQueueDao.headRow`; `recallTurnMs` (Task 3); the view mapper (Task 4).
- Produces:
  - `StudyModeHandler.turnTimeMs` (`int?`): `recallTurnMs` for `recall`, null
    otherwise.
  - `StudyRejection.noHint`.
  - On `StudySessionRepository`, each returning
    `Future<Outcome<void, StudyRejection>>`:
    `revealRecallAnswer({required String sessionId, required String cardId, required int remainingMs, DateTime? now})`,
    `saveRecallTime({required String sessionId, required String cardId, required int remainingMs, DateTime? now})`,
    `showFillHint({required String sessionId, required String cardId, DateTime? now})`.
  - `StudyQueueDao.reveal(row, {required int remainingMs})`,
    `saveTimeLeft(row, {required int remainingMs})`, `showHint(row)`;
    `StudySessionDao.hasHint(String cardId)`.
  - `RevealRecallAnswerUseCase`, `SaveRecallTimeUseCase` (both `call({required
    String sessionId, required String cardId, required int remainingMs})`) and
    `ShowFillHintUseCase` (`call({required String sessionId, required String cardId})`),
    each taking a `StudySessionRepository`.
  - `StudyItem.isHintShown` (`bool`); `StudyItem.remainingMs` falls back to the
    handler's `turnTimeMs`.
  - `insertCard(…, String? hint)` in `test/support/card_fixtures.dart`.

Spec §8.3 and D10; Clarifications 7, 8. The three writes check
what a turn checks — the session is open and current, in the write's mode, and
serves the card — and write only the row. The time left never grows, and once
the answer is revealed it stays where it stopped (BR-STUDY-036).

- [ ] **Step 1: Write the failing tests**

In `test/support/card_fixtures.dart`:

Replace

```dart
  String? example,
  bool isFlagged = false,
```

with

```dart
  String? example,
  String? hint,
  bool isFlagged = false,
```

Replace

```dart
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'example, is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
```

with

```dart
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'example, hint, is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
```

Replace

```dart
      Variable<String>(example),
      Variable<bool>(isFlagged),
```

with

```dart
      Variable<String>(example),
      Variable<String>(hint),
      Variable<bool>(isFlagged),
```

Create `test/features/study/data/turn_state_writes_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// Graded modes spec §8.3: the recall reveal and time and the fill hint are
// writes that are not turns. They record nothing and move nothing.

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<void, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  /// Two due cards under a fresh tree, the first with an example and a hint.
  Future<(DeckEntity, DeckEntity)> twoDue() async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      front: 'Công',
      back: 'work',
      example: 'Đây là một công việc tốt.',
      hint: 'Bắt đầu bằng C',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await insertCard(
      db,
      id: 'c2',
      deckId: leaf.id,
      front: 'Nước',
      back: 'water',
      example: 'Uống nước.',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 21),
    );
    await lockScheduler(db, root.id);
    return (root, leaf);
  }

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  Future<int> turnCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  Future<int> cursorOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<int>('cursor');

  test('a new recall turn has its full time and its answer hidden '
      '(BR-STUDY-031, BR-STUDY-036)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.recall);

    final item = (await viewOf(id)).currentItem!;
    expect(item.remainingMs, 20000);
    expect(item.isRevealed, isFalse);
  });

  test('revealing the answer records nothing, stops the time and moves '
      'nothing; revealing it again changes nothing (BR-STUDY-065)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.recall);

    expect(
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 12400,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
    expect(
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 5000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );

    final item = (await viewOf(id)).currentItem!;
    expect(item.cardId, 'c1');
    expect(item.isRevealed, isTrue);
    expect(item.remainingMs, 12400);
    expect(await turnCount(), 0);
    expect(await cursorOf(id), 0);
  });

  test('the time left is kept for Continue and never grows, and once the '
      'answer is revealed it stays where it stopped (BR-STUDY-036)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.recall);

    await sessions.saveRecallTime(
      sessionId: id,
      cardId: 'c1',
      remainingMs: 15000,
    );
    await sessions.saveRecallTime(
      sessionId: id,
      cardId: 'c1',
      remainingMs: 16000,
    );
    await sessions.resumeSession(sessionId: id);
    expect((await viewOf(id)).currentItem!.remainingMs, 15000);

    await sessions.revealRecallAnswer(
      sessionId: id,
      cardId: 'c1',
      remainingMs: 9000,
    );
    expect(
      await sessions.saveRecallTime(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 3000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
    expect((await viewOf(id)).currentItem!.remainingMs, 9000);
    expect(await turnCount(), 0);
  });

  test('a shown hint stays on the row and changes nothing else; a card '
      'without a hint has none to show (BR-STUDY-028)', () async {
    final (_, leaf) = await twoDue();
    final id = await review(leaf.id, StudyMode.fill);
    expect((await viewOf(id)).currentItem!.isHintShown, isFalse);

    for (var times = 0; times < 2; times++) {
      expect(
        await sessions.showFillHint(sessionId: id, cardId: 'c1'),
        isA<Ok<void, StudyRejection>>(),
      );
    }
    expect((await viewOf(id)).currentItem!.isHintShown, isTrue);
    expect(await turnCount(), 0);
    expect(await cursorOf(id), 0);

    await db.customStatement("UPDATE card SET hint = NULL WHERE id = 'c1'");
    await db.customStatement(
      "UPDATE study_queue_items SET hint_shown = 0 WHERE card_id = 'c1'",
    );
    expect(
      await sessions.showFillHint(sessionId: id, cardId: 'c1'),
      _refusedWith(StudyRejection.noHint),
    );
  });

  test('each write is refused where a turn would be: another card, another '
      'mode, an ended session, a root reset since (spec §8.3)', () async {
    final (root, leaf) = await twoDue();
    final recall = await review(leaf.id, StudyMode.recall);

    expect(
      await sessions.revealRecallAnswer(
        sessionId: recall,
        cardId: 'c2',
        remainingMs: 1000,
      ),
      _refusedWith(StudyRejection.notCurrentCard),
    );
    expect(
      await sessions.showFillHint(sessionId: recall, cardId: 'c1'),
      _refusedWith(StudyRejection.answerDoesNotFitMode),
    );

    final fill = await review(leaf.id, StudyMode.fill);
    expect(
      await sessions.saveRecallTime(
        sessionId: fill,
        cardId: 'c1',
        remainingMs: 1000,
      ),
      _refusedWith(StudyRejection.answerDoesNotFitMode),
    );
    expect(
      await sessions.revealRecallAnswer(
        sessionId: recall,
        cardId: 'c1',
        remainingMs: 1000,
      ),
      _refusedWith(StudyRejection.sessionClosed),
    );

    await ScheduleRepositoryImpl(
      db,
      now: () => now,
    ).resetLearning(rootDeckId: root.id);
    await db.customUpdate(
      "UPDATE study_session SET status = 'in_progress', end_reason = NULL,"
      ' ended_at = NULL WHERE id = ?',
      variables: [Variable<String>(fill)],
    );
    expect(
      await sessions.showFillHint(sessionId: fill, cardId: 'c1'),
      _refusedWith(StudyRejection.staleGeneration),
    );
    expect(
      (await sessionOf(db, fill)).read<String>('end_reason'),
      'stale_generation',
    );
  });
}
```

Create `test/features/study/domain/turn_state_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/reveal_recall_answer_use_case.dart';
import 'package:memox/features/study/domain/usecases/save_recall_time_use_case.dart';
import 'package:memox/features/study/domain/usecases/show_fill_hint_use_case.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// The three writes of graded modes spec §8.3 through the use cases the
// recall and fill screens call.

void main() {
  late AppDatabase db;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() => db.close());

  Future<String> opened(StudyMode mode) async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      example: 'example',
      hint: 'hint',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await lockScheduler(db, root.id);
    final result = await studyEntryRepository(
      db,
      () => now,
    ).openReviewSession(deckId: leaf.id, mode: mode);
    return (result as Ok<String, StudyRejection>).value;
  }

  test('RevealRecallAnswer and SaveRecallTime take the time left of the '
      'turn', () async {
    final id = await opened(StudyMode.recall);

    expect(
      await SaveRecallTimeUseCase(sessions)(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 14000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
    expect(
      await RevealRecallAnswerUseCase(sessions)(
        sessionId: id,
        cardId: 'c1',
        remainingMs: 13000,
      ),
      isA<Ok<void, StudyRejection>>(),
    );
  });

  test('a time outside 0 to 20 seconds is a bug in the caller: nothing is '
      'written', () async {
    final id = await opened(StudyMode.recall);
    final before = await totalChanges(db);

    for (final remainingMs in [-1, 20001]) {
      expect(
        () => SaveRecallTimeUseCase(sessions)(
          sessionId: id,
          cardId: 'c1',
          remainingMs: remainingMs,
        ),
        throwsArgumentError,
      );
      expect(
        () => RevealRecallAnswerUseCase(sessions)(
          sessionId: id,
          cardId: 'c1',
          remainingMs: remainingMs,
        ),
        throwsArgumentError,
      );
    }
    expect(await totalChanges(db), before);
  });

  test('ShowFillHint shows the hint of the turn', () async {
    final id = await opened(StudyMode.fill);

    expect(
      await ShowFillHintUseCase(sessions)(sessionId: id, cardId: 'c1'),
      isA<Ok<void, StudyRejection>>(),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/turn_state_writes_test.dart \
  test/features/study/domain/turn_state_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` The two test files do not compile. The first errors: `Error: The method 'revealRecallAnswer' isn't defined for the type 'StudySessionRepositoryImpl'.`, `Error: The method 'saveRecallTime' isn't defined for the type 'StudySessionRepositoryImpl'.`, `Error: The method 'showFillHint' isn't defined for the type 'StudySessionRepositoryImpl'.`

- [ ] **Step 3: Name the refusal, and the time of a recall turn**

In `lib/features/study/domain/failures/study_failure.dart`:

Replace

```dart

  /// The answer is of another mode's kind.
  answerDoesNotFitMode,
```

with

```dart

  /// The answer, or the reveal, time or hint asked of the row, is of another
  /// mode's kind.
  answerDoesNotFitMode,
```

Replace

```dart
  /// (BR-STUDY-049, BR-STUDY-062).
  notOnBoard;

```

with

```dart
  /// (BR-STUDY-049, BR-STUDY-062).
  notOnBoard,

  /// `fill`: the card has no hint to show (BR-STUDY-028).
  noHint;

```

In `lib/features/study_mode/domain/models/recall_mode.dart`:

Replace

```dart
  const RecallModeHandler();

```

with

```dart
  const RecallModeHandler();

  @override
  int get turnTimeMs => recallTurnMs;

```

In `lib/features/study_mode/domain/models/study_mode.dart`:

Replace

```dart

  /// What the round of [rows] needs before it is served: nothing but for
```

with

```dart

  /// The time of one turn, for a mode that has a timer (`recall`,
  /// BR-STUDY-031); null otherwise.
  int? get turnTimeMs => null;

  /// What the round of [rows] needs before it is served: nothing but for
```

- [ ] **Step 4: Write the reveal, the time and the hint**

In `lib/features/study/data/datasources/study_queue_dao.dart`:

Replace

```dart

  /// Enrolls [cardId] in [round] of [mode] once: a second enrollment changes
```

with

```dart

  /// `recall`: the answer of [row]'s turn is shown, and its time stops at
  /// [remainingMs] (BR-STUDY-065, BR-STUDY-036).
  Future<void> reveal(StudyQueueItem row, {required int remainingMs}) =>
      _update(
        row,
        StudyQueueItemsCompanion(
          isRevealed: const Value(1),
          remainingMs: Value(remainingMs),
        ),
      );

  /// `recall`: the time left of [row]'s turn (BR-STUDY-036).
  Future<void> saveTimeLeft(StudyQueueItem row, {required int remainingMs}) =>
      _update(row, StudyQueueItemsCompanion(remainingMs: Value(remainingMs)));

  /// `fill`: the hint of [row]'s turn is shown (BR-STUDY-028).
  Future<void> showHint(StudyQueueItem row) =>
      _update(row, const StudyQueueItemsCompanion(hintShown: Value(1)));

  /// Enrolls [cardId] in [round] of [mode] once: a second enrollment changes
```

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
```

with

```dart

  /// Whether [cardId] has a hint; a blank one is stored as NULL
  /// (BR-CARD-003).
  Future<bool> hasHint(String cardId) async {
    final row = await _db
        .customSelect(
          'SELECT hint IS NOT NULL AS has_hint FROM card WHERE id = ?',
          variables: [Variable<String>(cardId)],
          readsFrom: {_db.card},
        )
        .getSingleOrNull();
    return row?.read<bool>('has_hint') ?? false;
  }

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
```

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
```

Replace

```dart
      }
    });
  }

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
```

with

```dart
      }
    });
  }

  @override
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _onServedRow(sessionId, cardId, StudyMode.recall, now, (row) async {
    if (row.isRevealed == 1) return const Ok(null);
    await _queue.reveal(row, remainingMs: _timeLeft(row, remainingMs));
    return const Ok(null);
  });

  @override
  Future<Outcome<void, StudyRejection>> saveRecallTime({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  }) => _onServedRow(sessionId, cardId, StudyMode.recall, now, (row) async {
    if (row.isRevealed == 1) return const Ok(null);
    await _queue.saveTimeLeft(row, remainingMs: _timeLeft(row, remainingMs));
    return const Ok(null);
  });

  @override
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
  }) => _onServedRow(sessionId, cardId, StudyMode.fill, now, (row) async {
    if (!await _dao.hasHint(cardId)) {
      return const Rejected(StudyRejection.noHint);
    }
    if (row.hintShown == 0) await _queue.showHint(row);
    return const Ok(null);
  });

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
```

Replace

```dart
        reason: SessionEndReason.persistenceError,
        now: at,
      );
    });
  }

```

with

```dart
        reason: SessionEndReason.persistenceError,
        now: at,
      );
    });
  }

  /// [write] on the row [sessionId] serves: the checks of a turn, for a write
  /// that is not one (graded modes spec §8.3). The session is open at its
  /// root's generation, in [mode], and serves [cardId].
  Future<Outcome<void, StudyRejection>> _onServedRow(
    String sessionId,
    String cardId,
    StudyMode mode,
    DateTime? now,
    Future<Outcome<void, StudyRejection>> Function(StudyQueueItem row) write,
  ) {
    final at = now ?? _now();
    return _write(() async {
      switch (await _live(await _dao.sessionRow(sessionId), at)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final session, _)):
          if (session.currentMode != mode.code) {
            return const Rejected(StudyRejection.answerDoesNotFitMode);
          }
          final row = await _queue.headRow(
            session.id,
            mode.code,
            session.cursor,
          );
          if (row == null || row.cardId != cardId) {
            return const Rejected(StudyRejection.notCurrentCard);
          }
          return write(row);
      }
    });
  }

```

Replace

```dart

/// A write the turn cannot go without. A refusal there means study and the
```

with

```dart

/// The time left of [row]'s turn after a save of [remainingMs]: it never
/// grows (BR-STUDY-036).
int _timeLeft(StudyQueueItem row, int remainingMs) =>
    min(row.remainingMs ?? recallTurnMs, remainingMs);

/// A write the turn cannot go without. A refusal there means study and the
```

In `lib/features/study/domain/repositories/study_session_repository.dart`:

Replace

```dart
    required StudyAnswer answer,
    DateTime? now,
```

with

```dart
    required StudyAnswer answer,
    DateTime? now,
  });

  /// `recall`: the answer of the turn on [cardId] is shown before the time
  /// runs out. It records nothing and moves nothing: the time stops at the
  /// smaller of what is stored and [remainingMs], and the turn waits for the
  /// person's self-assessment (BR-STUDY-065, BR-STUDY-036). A second reveal
  /// changes nothing. It is refused as a turn would be: notFound,
  /// sessionClosed, staleGeneration (the session is invalidated),
  /// notCurrentCard, answerDoesNotFitMode (graded modes spec §8.3).
  Future<Outcome<void, StudyRejection>> revealRecallAnswer({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  });

  /// `recall`: the time left of the turn on [cardId], kept for Continue. It
  /// never grows, and once the answer is revealed it stays where it stopped
  /// (BR-STUDY-036). Refused as [revealRecallAnswer] is.
  Future<Outcome<void, StudyRejection>> saveRecallTime({
    required String sessionId,
    required String cardId,
    required int remainingMs,
    DateTime? now,
  });

  /// `fill`: the hint of the turn on [cardId] is shown, and the turn records
  /// that it was, without its result changing (BR-STUDY-028). noHint when the
  /// card has none; otherwise refused as [revealRecallAnswer] is.
  Future<Outcome<void, StudyRejection>> showFillHint({
    required String sessionId,
    required String cardId,
    DateTime? now,
```

- [ ] **Step 5: Add the three use cases**

Create `lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';

/// `recall`: the person shows the answer before the time runs out. Nothing
/// is recorded; the time stops, and the turn waits for the person's
/// self-assessment (BR-STUDY-065, BR-STUDY-036; graded modes spec §8.3).
final class RevealRecallAnswerUseCase {
  const RevealRecallAnswerUseCase(this._sessions);

  final StudySessionRepository _sessions;

  /// [remainingMs] outside 0 to [recallTurnMs] is a bug in the caller: an
  /// `ArgumentError`, before any write.
  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
    required int remainingMs,
  }) {
    RangeError.checkValueInInterval(
      remainingMs,
      0,
      recallTurnMs,
      'remainingMs',
    );
    return _sessions.revealRecallAnswer(
      sessionId: sessionId,
      cardId: cardId,
      remainingMs: remainingMs,
    );
  }
}
```

Create `lib/features/study/domain/usecases/save_recall_time_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';

/// `recall`: the time left of the turn, kept so Continue takes it up where it
/// stopped. The screen saves it when the app goes to the background and when
/// the screen closes, not on every tick (BR-STUDY-036; graded modes spec
/// §8.3).
final class SaveRecallTimeUseCase {
  const SaveRecallTimeUseCase(this._sessions);

  final StudySessionRepository _sessions;

  /// [remainingMs] outside 0 to [recallTurnMs] is a bug in the caller: an
  /// `ArgumentError`, before any write.
  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
    required int remainingMs,
  }) {
    RangeError.checkValueInInterval(
      remainingMs,
      0,
      recallTurnMs,
      'remainingMs',
    );
    return _sessions.saveRecallTime(
      sessionId: sessionId,
      cardId: cardId,
      remainingMs: remainingMs,
    );
  }
}
```

Create `lib/features/study/domain/usecases/show_fill_hint_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// `fill`: the person asks for the card's hint. The turn records that it was
/// shown, and its result does not change (BR-STUDY-028; graded modes spec
/// §8.3).
final class ShowFillHintUseCase {
  const ShowFillHintUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
  }) => _sessions.showFillHint(sessionId: sessionId, cardId: cardId);
}
```

- [ ] **Step 6: Show the time and the hint on the session screen**

In `lib/features/study/data/mappers/study_session_view_mapper.dart`:

Replace

```dart
  },
  remainingMs: served.row.remainingMs,
  isRevealed: served.row.isRevealed == 1,
  guess: switch (served.options) {
```

with

```dart
  },
  remainingMs:
      served.row.remainingMs ??
      StudyMode.fromCode(served.row.mode).handler.turnTimeMs,
  isRevealed: served.row.isRevealed == 1,
  isHintShown: served.row.hintShown == 1,
  guess: switch (served.options) {
```

In `lib/features/study/domain/models/study_session_view_model.dart`:

Replace

```dart
    required this.isRevealed,
    this.guess,
```

with

```dart
    required this.isRevealed,
    this.isHintShown = false,
    this.guess,
```

Replace

```dart

  /// `recall` only: the time left of a turn in progress (BR-STUDY-036).
  final int? remainingMs;
  final bool isRevealed;

```

with

```dart

  /// `recall` only: the time left of the turn, the full turn until the first
  /// save (BR-STUDY-031, BR-STUDY-036).
  final int? remainingMs;
  final bool isRevealed;

  /// `fill`: the hint of this turn has been shown (BR-STUDY-028).
  final bool isHintShown;

```

- [ ] **Step 7: Describe the writes that are not turns**

In `docs/features/study/data.md`:

Replace

```markdown
  chọn vì card của lựa chọn đó bị xoá hẳn.
```

with

```markdown
  chọn vì card của lựa chọn đó bị xoá hẳn.

## Ghi không phải lượt

Ba lệnh ghi trạng thái của lượt đang dở mà không phải một lượt: không ghi
`review_log`, không tiến `cursor`. Chúng bị từ chối ở đúng những chỗ một lượt bị từ
chối: phiên đã đóng, root đã reset sau khi phiên mở, thẻ không phải thẻ đang phục vụ,
hoặc phiên đang ở mode khác.

| Lệnh | Mode | Ghi |
|---|---|---|
| Lật đáp án | `recall` | `is_revealed = 1`; đồng hồ dừng ở thời gian còn lại. Lật lần hai không đổi gì (BR-STUDY-065, BR-STUDY-036) |
| Lưu thời gian | `recall` | `remaining_ms`, chỉ giảm; đã lật thì không đổi nữa (BR-STUDY-036) |
| Hiện gợi ý | `fill` | `hint_shown = 1`; lượt sau đó ghi `used_hint = 1` mà kết quả không đổi. Thẻ không có gợi ý thì bị từ chối (BR-STUDY-028) |

Một lượt mới ở round sau là một dòng mới, nên bắt đầu lại đủ 20 giây, đáp án ẩn và
gợi ý chưa hiện (BR-STUDY-036).
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/study/data/turn_state_writes_test.dart \
  test/features/study/domain/turn_state_use_cases_test.dart
```

Expected: `+8: All tests passed!`

- [ ] **Step 9: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1261: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/features/study/data.md \
  lib/features/study/data/datasources/study_queue_dao.dart \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/mappers/study_session_view_mapper.dart \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/domain/failures/study_failure.dart \
  lib/features/study/domain/models/study_session_view_model.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart \
  lib/features/study/domain/usecases/save_recall_time_use_case.dart \
  lib/features/study/domain/usecases/show_fill_hint_use_case.dart \
  lib/features/study_mode/domain/models/recall_mode.dart \
  lib/features/study_mode/domain/models/study_mode.dart \
  test/features/study/data/turn_state_writes_test.dart \
  test/features/study/domain/turn_state_use_cases_test.dart \
  test/support/card_fixtures.dart
git commit -F - <<'EOF'
feat(study): the recall reveal and time and the fill hint, writes that are not turns

RevealRecallAnswer shows the answer and stops the time without recording an
outcome (BR-STUDY-065); SaveRecallTime keeps the time left for Continue, which
never grows (BR-STUDY-036); ShowFillHint marks the hint shown, refused as
noHint on a card without one (BR-STUDY-028). Each checks what a turn checks,
writes only the queue row, and moves neither the cursor nor the log (graded
modes spec §8.3). The session screen shows the stored time, or the full turn
while none is stored, and whether the hint is shown.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: The turn judges the person's real input

**Files:**
- Create: `lib/features/study/domain/models/turn_result_model.dart`
- Modify: `lib/features/srs/data/repositories/schedule_repository_impl.dart`, `lib/features/srs/domain/models/review_turn_model.dart`, `lib/features/study/data/datasources/study_queue_dao.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`, `lib/features/study/domain/usecases/answer_study_turn_use_case.dart`, `lib/features/study_mode/domain/models/browse_mode.dart`, `lib/features/study_mode/domain/models/graded_mode.dart`, `lib/features/study_mode/domain/models/self_assess_mode.dart`, `lib/features/study_mode/domain/models/study_answer_model.dart`, `lib/features/study_mode/domain/models/study_mode.dart`, `lib/features/study_mode/domain/models/turn_judgement_model.dart`, `docs/features/study/it-scenarios.md`, `docs/features/study/rules/BR-STUDY-026-fill-de-la-mat-sau-go-mat-truoc.md`, `docs/shared/testing/agent-execution-guide.md`
- Test (create): `test/features/study/data/match_guess_turns_test.dart`, `test/features/study/data/recall_fill_turns_test.dart`
- Test (modify): `test/features/srs/data/record_turn_test.dart`, `test/features/study/data/answer_rounds_test.dart`, `test/features/study/data/round_preparation_test.dart`, `test/features/study/data/session_endings_test.dart`, `test/features/study/data/watch_entry_test.dart`, `test/features/study/data/watch_session_test.dart`, `test/features/study/domain/answer_study_turn_use_case_test.dart`, `test/features/study_mode/domain/study_mode_handler_test.dart`, `test/support/study_fixtures.dart`, `test/support/test_database.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Tasks 3–5; `ScheduleRepository.recordTurn` and `ReviewTurn`
  (package 2a); `CardRow` (`card.drift`).
- Produces:
  - `ReviewTurn` gains `String? outcomeReasonCode`, `int? comparisonVersion`
    and `bool? usedHint`, which `recordTurn` writes to `review_log`.
  - `final class TurnResult({bool? isCorrect})`
    (`study/domain/models/turn_result_model.dart`).
  - `StudySessionRepository.answerTurn(...)` and `AnswerStudyTurnUseCase.call(...)`
    return `Future<Outcome<TurnResult, StudyRejection>>`.
  - `StudyQueueDao.optionIds(row)`, `pendingMeanings(row, {required int from, required int to})`
    and `swapMeaningSlots(row, String otherCardId)`;
    `StudySessionDao.cardRow(String id)` → `Future<CardRow>`.
  - `StudyModeHandler.actionOf` and `GradedAnswer` are gone.
  - Test support: `answerServed(db, sessions, sessionId, {required bool right, String? cardId})`
    → `Future<TurnResult>` and `insertFiveDue(db, decks, [String rootName = 'Korean'])`
    in `study_fixtures.dart`; `ThinMeaningSource(int? keep)` in
    `test_database.dart`.

Spec §8.1, §8.4, §11, §12 and D2, D3, D9, D11; Clarifications 5,
9–11, 13. A `match` turn now stays on the current board: the board of the head
row, which is the round's lowest pending position. Package 2a's tests move to
the real inputs through `answerServed`, which answers the served card right or
wrong in any mode (a `recall` answer reveals first). The three documents the
owner allowed are fixed in this commit, with the code that reads them.

- [ ] **Step 1: Write the failing tests**

In `test/support/study_fixtures.dart`:

Replace

```dart
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
```

with

```dart
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/repositories/deck_repository.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
```

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
```

Replace

```dart

import 'invariant_queries.dart';
```

with

```dart

import 'card_fixtures.dart';
import 'deck_fixtures.dart';
import 'invariant_queries.dart';
```

Replace

```dart

/// Answers the card [sessionId] serves in its current mode, or [cardId],
/// right or wrong as [right] says. A refusal fails the test.
Future<void> answerServed(
  AppDatabase db,
```

with

```dart

/// Five learned eight_box cards `ST-01`…`ST-05` in [rootName] > Lesson, due
/// in that order, of five meanings, each with an example and a hint: the
/// cards of SETUP-STUDY-EB-5-FULL once learned, so a review opens straight in
/// the mode a test takes. Returns the lesson deck.
Future<DeckEntity> insertFiveDue(
  AppDatabase db,
  DeckRepository decks, [
  String rootName = 'Korean',
]) async {
  final root = await decks.root(rootName);
  final leaf = await decks.sub(root.id, 'Lesson');
  const meanings = ['apple', 'banana', 'cherry', 'date', 'elder'];
  for (final (index, meaning) in meanings.indexed) {
    await insertCard(
      db,
      id: 'ST-0${index + 1}',
      deckId: leaf.id,
      front: 'term ${index + 1}',
      back: meaning,
      example: 'example ${index + 1}',
      hint: 'hint ${index + 1}',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 10 + index),
    );
  }
  await lockScheduler(db, root.id);
  return leaf;
}

/// Answers the card [sessionId] serves in its current mode, or [cardId],
/// the way a person who knows it ([right]) or does not would, each mode with
/// its own input (graded modes spec §7.1). A `recall` answer reveals first.
/// A refusal fails the test.
Future<TurnResult> answerServed(
  AppDatabase db,
```

Replace

```dart
  final mode = (await sessionOf(db, sessionId)).read<String>('current_mode');
  final card = cardId ?? await servedCard(db, sessionId);
  final outcome = await sessions.answerTurn(
    sessionId: sessionId,
    cardId: card!,
    answer: mode == 'browse'
        ? const AdvanceAnswer()
        : GradedAnswer(isCorrect: right),
  );
  expect(outcome, isA<Ok<void, StudyRejection>>(), reason: 'answer on $card');
}
```

with

```dart
  final mode = (await sessionOf(db, sessionId)).read<String>('current_mode');
  final card = cardId ?? (await servedCard(db, sessionId))!;
  final outcome = await sessions.answerTurn(
    sessionId: sessionId,
    cardId: card,
    answer: await _answerOf(db, sessions, sessionId, mode, card, right: right),
  );
  expect(
    outcome,
    isA<Ok<TurnResult, StudyRejection>>(),
    reason: 'answer on $card',
  );
  return (outcome as Ok<TurnResult, StudyRejection>).value;
}

Future<StudyAnswer> _answerOf(
  AppDatabase db,
  StudySessionRepositoryImpl sessions,
  String sessionId,
  String mode,
  String cardId, {
  required bool right,
}) async {
  switch (mode) {
    case 'browse':
      return const AdvanceAnswer();
    case 'self_assess':
      return SelfAssessAnswer(right ? Sm2Action.good : Sm2Action.again);
    case 'fill':
      final front =
          (await db
                  .customSelect(
                    'SELECT front FROM card WHERE id = ?',
                    variables: [Variable(cardId)],
                  )
                  .getSingle())
              .read<String>('front');
      return FillAnswer(right ? front : '$front?');
    case 'recall':
      await sessions.revealRecallAnswer(
        sessionId: sessionId,
        cardId: cardId,
        remainingMs: 10000,
      );
      return RecallAnswer(
        right ? RecallOutcome.remembered : RecallOutcome.forgot,
      );
    case 'guess':
      if (right) return GuessAnswer(cardId);
      final round = await _servedRound(db, sessionId, cardId);
      final options = await optionsOf(db, sessionId, cardId, round: round);
      return GuessAnswer(options.firstWhere((id) => id != cardId));
    case 'match':
      return MatchAnswer(
        right ? cardId : await _otherPair(db, sessionId, cardId),
      );
  }
  throw ArgumentError.value(mode, 'mode');
}

/// The round in which [cardId]'s row of the current mode is served.
Future<int> _servedRound(
  AppDatabase db,
  String sessionId,
  String cardId,
) async =>
    (await db
            .customSelect(
              'SELECT MIN(q.round) AS round FROM study_queue_items q'
              ' JOIN study_session s ON s.id = q.session_id'
              ' WHERE q.session_id = ? AND q.mode = s.current_mode'
              " AND q.card_id = ? AND q.status = 'pending' AND q.position >= 0",
              variables: [Variable(sessionId), Variable(cardId)],
            )
            .getSingle())
        .read<int>('round');

/// Another pending pair of the `match` board [cardId] is on, whose meaning
/// is a wrong one for it.
Future<String> _otherPair(
  AppDatabase db,
  String sessionId,
  String cardId,
) async =>
    (await db
            .customSelect(
              'SELECT q.card_id FROM study_queue_items q'
              ' JOIN study_queue_items me ON me.session_id = q.session_id'
              '  AND me.mode = q.mode AND me.round = q.round'
              " WHERE me.session_id = ? AND me.mode = 'match' AND me.card_id = ?"
              " AND me.status = 'pending' AND me.position >= 0"
              " AND q.status = 'pending' AND q.card_id <> me.card_id"
              ' AND q.position / 5 = me.position / 5 ORDER BY q.position LIMIT 1',
              variables: [Variable(sessionId), Variable(cardId)],
            )
            .getSingle())
        .read<String>('card_id');
```

In `test/support/test_database.dart`:

Replace

```dart
    message: 'constraint failed',
  );
}
```

with

```dart
    message: 'constraint failed',
  );
}

/// Cuts the meaning source of a `guess` question to its first [keep] rows
/// while [keep] is set, the way the fault injector of
/// S-STUDY-GUESS-BLOCKED-V2 does, with the database untouched.
final class ThinMeaningSource extends QueryInterceptor {
  ThinMeaningSource(this.keep);

  int? keep;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    final kept = keep;
    if (kept == null || !statement.contains('AS meaning_folded')) return rows;
    return rows.take(kept).toList();
  }
}
```

In `test/features/srs/data/record_turn_test.dart`:

Replace

```dart
    expect(log.read<DateTime>('next_due_at'), DateTime(2026, 9, 27));
  });
```

with

```dart
    expect(log.read<DateTime>('next_due_at'), DateTime(2026, 9, 27));
  });

  test('a turn keeps what its mode adds: the reason of a recall timeout, the '
      'comparison version and the hint of a fill (BR-STUDY-027, BR-STUDY-028, '
      'BR-STUDY-034)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    await repo.recordTurn(
      ReviewTurn(
        cardId: cardId,
        sessionId: 'r-session',
        generation: 1,
        kind: ReviewKind.learning,
        modeCode: 'recall',
        action: EightBoxAction.forgotten,
        answeredAt: now,
        outcomeReasonCode: 'timeout',
      ),
    );
    await repo.recordTurn(
      ReviewTurn(
        cardId: cardId,
        sessionId: 'r-session',
        generation: 1,
        kind: ReviewKind.relearning,
        modeCode: 'fill',
        action: EightBoxAction.remembered,
        answeredAt: now.add(const Duration(minutes: 1)),
        comparisonVersion: 1,
        usedHint: true,
      ),
    );

    final [timeout, fill] = await _logs(db);
    expect(timeout.read<String>('outcome_reason'), 'timeout');
    expect(timeout.data['comparison_version'], isNull);
    expect(timeout.data['used_hint'], isNull);
    expect(fill.data['outcome_reason'], isNull);
    expect(fill.read<int>('comparison_version'), 1);
    expect(fill.read<bool>('used_hint'), isTrue);
  });

  test("a mode's column on another mode is a bug the schema refuses, and the "
      'turn writes nothing (invariants 22, 23)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    await expectLater(
      repo.recordTurn(
        ReviewTurn(
          cardId: cardId,
          sessionId: 'r-session',
          generation: 1,
          kind: ReviewKind.learning,
          modeCode: 'recall',
          action: EightBoxAction.remembered,
          answeredAt: now,
          comparisonVersion: 1,
        ),
      ),
      throwsA(isA<ConstraintFailure>()),
    );
    expect(await _logs(db), isEmpty);
  });
```

In `test/features/study/data/answer_rounds_test.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

Replace

```dart
// UC-STUDY-001 A0, A0c and A1 on eight_box decks: the graded modes' rounds,
// with a right or wrong verdict standing in for their mechanics (package 2b).

const _right = GradedAnswer(isCorrect: true);
const _wrong = GradedAnswer(isCorrect: false);

```

with

```dart
// UC-STUDY-001 A0, A0c and A1 on eight_box decks: the graded modes' rounds,
// answered right or wrong with each mode's own input (graded modes spec §7.1).

```

Replace

```dart

  Future<void> answer(
    String sessionId,
    StudyAnswer answer, [
    String? card,
  ]) async {
    final cardId = card ?? await servedCard(db, sessionId);
    expect(
      await sessions.answerTurn(
        sessionId: sessionId,
        cardId: cardId!,
        answer: answer,
      ),
      isA<Ok<void, StudyRejection>>(),
      reason: 'answer on $cardId',
    );
  }

  Future<String> modeOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<String>('current_mode');

```

with

```dart

  Future<String> modeOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<String>('current_mode');

  /// Answers [card], or the card served, right or wrong.
  Future<void> graded(String sessionId, {required bool right, String? card}) =>
      answerServed(db, sessions, sessionId, right: right, cardId: card);

```

Replace

```dart
            'in_progress') {
      await answer(
        sessionId,
        mode == 'browse' ? const AdvanceAnswer() : _right,
      );
    }
```

with

```dart
            'in_progress') {
      await graded(sessionId, right: true);
    }
```

Replace

```dart

    await answer(id, _wrong);
    await answer(id, _wrong);
    await answer(id, _right);
    final roundTwo = await queueOf(db, id, 'recall', round: 2);
    await answer(id, _wrong, roundTwo.first);
    await answer(id, _right, roundTwo.last);
    await answer(id, _right);

```

with

```dart

    await graded(id, right: false);
    await graded(id, right: false);
    await graded(id, right: true);
    final roundTwo = await queueOf(db, id, 'recall', round: 2);
    await graded(id, right: false, card: roundTwo.first);
    await graded(id, right: true, card: roundTwo.last);
    await graded(id, right: true);

```

Replace

```dart

      await answer(id, _wrong, 'b');
      await answer(id, _wrong, 'b');
      await answer(id, _right, 'b');
      await answer(id, _right, 'a');

```

with

```dart

      await graded(id, right: false, card: 'b');
      await graded(id, right: false, card: 'b');
      await graded(id, right: true, card: 'b');
      await graded(id, right: true, card: 'a');

```

Replace

```dart
      expect(await modeOf(id), 'match');
      await answer(id, _right, 'b');
      expect(await modeOf(id), 'recall');
```

with

```dart
      expect(await modeOf(id), 'match');
      await graded(id, right: true, card: 'b');
      expect(await modeOf(id), 'recall');
```

Replace

```dart

    await answer(id, _wrong, 'a');
    await answer(id, _right, 'b');
    await answer(id, _right, 'a');

```

with

```dart

    await graded(id, right: false, card: 'a');
    await graded(id, right: true, card: 'b');
    await graded(id, right: true, card: 'a');

```

Create `test/features/study/data/match_guess_turns_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–9 in `match` and `guess`: a turn judges the pair or
// the option the person picked (graded modes spec §7.5, §7.6, §8.1).

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<TurnResult, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

Matcher _judged({required bool isCorrect}) =>
    isA<Ok<TurnResult, StudyRejection>>().having(
      (ok) => ok.value.isCorrect,
      'isCorrect',
      isCorrect,
    );

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);

  void open(AppDatabase database) {
    db = database;
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  Future<Outcome<TurnResult, StudyRejection>> turn(
    String sessionId,
    String cardId,
    StudyAnswer answer,
  ) =>
      sessions.answerTurn(sessionId: sessionId, cardId: cardId, answer: answer);

  Future<List<QueryRow>> logsOf(String cardId) => db
      .customSelect(
        'SELECT * FROM review_log WHERE card_id = ? ORDER BY rowid',
        variables: [Variable<String>(cardId)],
      )
      .get();

  /// A match review of seven learned, due cards `c0`…`c6` of seven meanings:
  /// two boards, of five pairs and of two.
  Future<String> sevenPairs() async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (var index = 0; index < 7; index++) {
      await insertCard(
        db,
        id: 'c$index',
        deckId: leaf.id,
        back: 'meaning $index',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 10 + index),
      );
    }
    await lockScheduler(db, root.id);
    return review(leaf.id, StudyMode.match);
  }

  Future<int> turnCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test(
    'a wrong pair is a wrong turn of the term card only; the pair stays on '
    'the board, and the next round holds exactly the cards that were ever '
    'wrong (BR-STUDY-060, BR-STUDY-062, BR-STUDY-070; IT-MODE-004F)',
    () async {
      final leaf = await insertFiveDue(db, decks);
      final id = await review(leaf.id, StudyMode.match);

      expect(
        await turn(id, 'ST-01', const MatchAnswer('ST-02')),
        _judged(isCorrect: false),
      );
      expect(await logsOf('ST-02'), isEmpty);
      expect(
        (await logsOf('ST-01')).single.read<String>('action'),
        'forgotten',
      );
      expect([
        for (final tile in (await viewOf(id)).board!.terms) tile.isMatched,
      ], everyElement(isFalse));

      expect(
        await turn(id, 'ST-01', const MatchAnswer('ST-01')),
        _judged(isCorrect: true),
      );
      await turn(id, 'ST-03', const MatchAnswer('ST-04'));
      await turn(id, 'ST-03', const MatchAnswer('ST-03'));
      for (final card in ['ST-02', 'ST-04', 'ST-05']) {
        expect(
          await turn(id, card, MatchAnswer(card)),
          _judged(isCorrect: true),
        );
      }

      expect((await queueOf(db, id, 'match', round: 2)).toSet(), {
        'ST-01',
        'ST-03',
      });
      final logs = await logsOf('ST-01');
      expect(logs.every((log) => log.data['outcome_reason'] == null), isTrue);
      expect(
        logs.every((log) => log.data['comparison_version'] == null),
        isTrue,
      );
    },
  );

  test('a right pair on another card of the same meaning takes that tile, so '
      'the tile tapped is the one matched (spec D3, §7.6)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, meaning, day) in [
      ('a', 'water', 10),
      ('b', ' Water', 11),
      ('c', 'fire', 12),
    ]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        back: meaning,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }
    await lockScheduler(db, root.id);
    final id = await review(leaf.id, StudyMode.match);
    final slots = await meaningSlotsOf(db, id);
    final meanings = (await viewOf(id)).board!.meanings;
    final tapped = meanings.indexWhere((tile) => tile.cardId == 'b');
    final other = meanings.indexWhere((tile) => tile.cardId == 'a');

    expect(
      await turn(id, 'a', const MatchAnswer('b')),
      _judged(isCorrect: true),
    );

    final swapped = await meaningSlotsOf(db, id);
    expect((swapped['a'], swapped['b']), (slots['b'], slots['a']));
    final after = (await viewOf(id)).board!.meanings;
    expect((after[tapped].cardId, after[tapped].isMatched), ('a', true));
    expect((after[other].cardId, after[other].isMatched), ('b', false));
    expect(
      await turn(id, 'b', const MatchAnswer('b')),
      _judged(isCorrect: true),
    );
  });

  test('a turn stays on the current board: a meaning of another board is '
      'refused, and so is a term there (BR-STUDY-049)', () async {
    final id = await sevenPairs();
    final order = await queueOf(db, id, 'match');
    final before = await totalChanges(db);

    expect(
      await turn(id, order.first, MatchAnswer(order.last)),
      _refusedWith(StudyRejection.notOnBoard),
    );
    expect(
      await turn(id, order.last, MatchAnswer(order.last)),
      _refusedWith(StudyRejection.notCurrentCard),
    );
    expect(await totalChanges(db), before);
  });

  test('once every pair of a board is matched, the next board is the current '
      'one, and its pairs end the round (BR-STUDY-049)', () async {
    final id = await sevenPairs();
    final order = await queueOf(db, id, 'match');
    for (final card in order.take(5)) {
      expect(await turn(id, card, MatchAnswer(card)), _judged(isCorrect: true));
    }

    final board = (await viewOf(id)).board!;
    expect([for (final tile in board.terms) tile.cardId], order.skip(5));
    for (final card in order.skip(5)) {
      expect(await turn(id, card, MatchAnswer(card)), _judged(isCorrect: true));
    }
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
  });

  test('a meaning already matched is off the board: refused, with nothing '
      'written (BR-STUDY-049)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await review(leaf.id, StudyMode.match);
    await turn(id, 'ST-01', const MatchAnswer('ST-01'));
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-02', const MatchAnswer('ST-01')),
      _refusedWith(StudyRejection.notOnBoard),
    );
    expect(await totalChanges(db), before);
  });

  test(
    'a card deleted while its pair is on the board takes its pair away: '
    'the other pairs keep their tiles, and the round ends without it',
    () async {
      final leaf = await insertFiveDue(db, decks);
      final id = await review(leaf.id, StudyMode.match);
      final before = (await viewOf(id)).board!;
      await db.customStatement("DELETE FROM card WHERE id = 'ST-03'");

      final after = (await viewOf(id)).board!;
      List<String> kept(List<MatchTile> tiles) => [
        for (final tile in tiles)
          if (tile.cardId != 'ST-03') tile.cardId,
      ];
      expect([for (final tile in after.terms) tile.cardId], kept(before.terms));
      expect([
        for (final tile in after.meanings) tile.cardId,
      ], kept(before.meanings));
      for (final card in ['ST-01', 'ST-02', 'ST-04', 'ST-05']) {
        expect(
          await turn(id, card, MatchAnswer(card)),
          _judged(isCorrect: true),
        );
      }
      expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    },
  );

  test('a guess question has five options, the right one once; the first '
      'pick is the one turn it records (BR-STUDY-037, BR-STUDY-041, '
      'BR-STUDY-042; IT-MODE-005F)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await review(leaf.id, StudyMode.guess);
    final options = (await viewOf(id)).currentItem!.guess!.options;
    expect(options, hasLength(5));
    expect([
      for (final option in options) option.cardId,
    ], containsOnce('ST-01'));
    final wrong = options.firstWhere((option) => option.cardId != 'ST-01');

    expect(
      await turn(id, 'ST-01', GuessAnswer(wrong.cardId)),
      _judged(isCorrect: false),
    );
    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      _refusedWith(StudyRejection.notCurrentCard),
    );
    expect(await turnCount(), 1);
    expect((await logsOf('ST-01')).single.read<String>('action'), 'forgotten');
  });

  test('a card that is not one of the options is refused and writes nothing '
      '(BR-STUDY-041)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await review(leaf.id, StudyMode.guess);
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-01', const GuessAnswer('elsewhere')),
      _refusedWith(StudyRejection.notAnOption),
    );
    expect(await totalChanges(db), before);
  });

  test('an answer on a question that lost an option to a deleted card is '
      'refused as blocked, with nothing written; Continue builds the question '
      'again from what is left (BR-STUDY-040)', () async {
    final leaf = await insertFiveDue(db, decks);
    await insertCard(
      db,
      id: 'ST-06',
      deckId: leaf.id,
      back: 'fig',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 10, 20),
    );
    final id = await review(leaf.id, StudyMode.guess);
    final gone = (await optionsOf(
      db,
      id,
      'ST-01',
    )).firstWhere((card) => card != 'ST-01');
    await db.customStatement("DELETE FROM card WHERE id = '$gone'");
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      _refusedWith(StudyRejection.questionBlocked),
    );
    expect(await totalChanges(db), before);

    await sessions.resumeSession(sessionId: id);
    expect(await optionsOf(db, id, 'ST-01'), hasLength(5));
    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      _judged(isCorrect: true),
    );
  });

  test('a blocked question takes no answer and moves nothing; once the person '
      'leaves, a new session without the fault builds five options '
      '(BR-STUDY-040; IT-MODE-014)', () async {
    await db.close();
    final fault = ThinMeaningSource(4);
    open(openTestDatabase(interceptor: fault));
    final leaf = await insertFiveDue(db, decks);
    final id = await review(leaf.id, StudyMode.guess);
    final view = await viewOf(id);
    expect(view.currentItem!.cardId, 'ST-01');
    expect(view.currentItem!.guess!.isBlocked, isTrue);
    final before = await totalChanges(db);

    expect(
      await turn(id, 'ST-01', const GuessAnswer('ST-01')),
      _refusedWith(StudyRejection.questionBlocked),
    );
    expect(await totalChanges(db), before);
    final still = await viewOf(id);
    expect(still.currentItem!.cardId, 'ST-01');
    expect(still.progress!.completed, 0);

    expect(
      await sessions.abandonSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    fault.keep = null;
    final again = await review(leaf.id, StudyMode.guess);
    expect((await viewOf(again)).currentItem!.guess!.options, hasLength(5));
    expect(
      await turn(again, 'ST-01', const GuessAnswer('ST-01')),
      _judged(isCorrect: true),
    );
  });
}
```

Create `test/features/study/data/recall_fill_turns_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–9 in `recall` and `fill`: a turn judges the person's
// self-assessment or the term typed (graded modes spec §7.3, §7.4, §8.1).

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<TurnResult, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

Matcher _judged({required bool isCorrect}) =>
    isA<Ok<TurnResult, StudyRejection>>().having(
      (ok) => ok.value.isCorrect,
      'isCorrect',
      isCorrect,
    );

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudySessionViewRepositoryImpl views;
  final now = DateTime(2026, 9, 24, 9);

  void open(AppDatabase database) {
    db = database;
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    views = StudySessionViewRepositoryImpl(db);
  }

  setUp(() => open(openTestDatabase()));
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await views.watchSession(sessionId).first)!;

  Future<String> review(String deckId, StudyMode mode) async =>
      ((await entries.openReviewSession(
        deckId: deckId,
        mode: mode,
      )) as Ok<String, StudyRejection>).value;

  Future<Outcome<TurnResult, StudyRejection>> turn(
    String sessionId,
    String cardId,
    StudyAnswer answer,
  ) =>
      sessions.answerTurn(sessionId: sessionId, cardId: cardId, answer: answer);

  Future<List<QueryRow>> logsOf(String cardId) => db
      .customSelect(
        'SELECT * FROM review_log WHERE card_id = ? ORDER BY rowid',
        variables: [Variable<String>(cardId)],
      )
      .get();

  Future<int> turnCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test(
    'revealing records nothing; the self-assessment after it is the one '
    'turn, and is refused before a reveal (BR-STUDY-065; IT-MODE-008F)',
    () async {
      final leaf = await insertFiveDue(db, decks);
      final id = await review(leaf.id, StudyMode.recall);

      expect(
        await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.remembered)),
        _refusedWith(StudyRejection.notRevealed),
      );
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'ST-01',
        remainingMs: 12000,
      );
      expect(await turnCount(), 0);

      expect(
        await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.remembered)),
        _judged(isCorrect: true),
      );
      expect(
        await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.forgot)),
        _refusedWith(StudyRejection.notCurrentCard),
      );
      final log = (await logsOf('ST-01')).single;
      expect(log.read<String>('action'), 'remembered');
      expect(log.data['outcome_reason'], isNull);
    },
  );

  test('the time left survives Continue; a timeout records wrong with its '
      'reason, and nothing after it or after a reveal takes a second '
      'outcome (BR-STUDY-032 to BR-STUDY-036; IT-MODE-009F)', () async {
    final leaf = await insertFiveDue(db, decks);
    final id = await review(leaf.id, StudyMode.recall);
    await sessions.saveRecallTime(
      sessionId: id,
      cardId: 'ST-01',
      remainingMs: 12400,
    );
    await sessions.resumeSession(sessionId: id);
    final resumed = (await viewOf(id)).currentItem!;
    expect((resumed.remainingMs, resumed.isRevealed), (12400, false));

    expect(
      await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.timedOut)),
      _judged(isCorrect: false),
    );
    final log = (await logsOf('ST-01')).single;
    expect(log.read<String>('action'), 'forgotten');
    expect(log.read<String>('outcome_reason'), 'timeout');
    expect(
      await sessions.revealRecallAnswer(
        sessionId: id,
        cardId: 'ST-01',
        remainingMs: 0,
      ),
      isA<Rejected<void, StudyRejection>>(),
    );
    expect(
      await turn(id, 'ST-01', const RecallAnswer(RecallOutcome.timedOut)),
      _refusedWith(StudyRejection.notCurrentCard),
    );

    await sessions.revealRecallAnswer(
      sessionId: id,
      cardId: 'ST-02',
      remainingMs: 3000,
    );
    expect(
      await turn(id, 'ST-02', const RecallAnswer(RecallOutcome.timedOut)),
      _refusedWith(StudyRejection.alreadyRevealed),
    );
    expect(await logsOf('ST-02'), isEmpty);
  });

  group('fill on S-STUDY-FILL-V2: front `Công`, back `Nghề nghiệp`', () {
    /// A fresh tree holding the one card of S-STUDY-FILL-V2, and a fill review
    /// on it.
    Future<String> fillReview(String rootName) async {
      final root = await decks.root(rootName);
      final leaf = await decks.sub(root.id, 'Lesson');
      await insertCard(
        db,
        id: '$rootName-card',
        deckId: leaf.id,
        front: 'Công',
        back: 'Nghề nghiệp',
        example: 'Đây là một công việc tốt.',
        hint: 'Bắt đầu bằng C',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, 20),
      );
      await lockScheduler(db, root.id);
      return review(leaf.id, StudyMode.fill);
    }

    test('spaces and case fall away and accents stay; a blank answer writes '
        'nothing, and what was typed is kept nowhere (BR-STUDY-026, '
        'BR-STUDY-027, BR-STUDY-029, BR-STUDY-030; IT-MODE-010)', () async {
      final blank = await fillReview('A');
      final before = await totalChanges(db);
      for (final typed in ['', '   ']) {
        expect(
          await turn(blank, 'A-card', FillAnswer(typed)),
          _refusedWith(StudyRejection.emptyAnswer),
        );
      }
      expect(await totalChanges(db), before);
      expect((await sessionOf(db, blank)).read<int>('cursor'), 0);

      final cased = await fillReview('B');
      expect(
        await turn(cased, 'B-card', const FillAnswer('  cÔnG  ')),
        _judged(isCorrect: true),
      );

      final unaccented = await fillReview('C');
      expect(
        await turn(unaccented, 'C-card', const FillAnswer('cong')),
        _judged(isCorrect: false),
      );
      final log = (await logsOf('C-card')).single;
      expect(log.read<String>('action'), 'forgotten');
      expect(log.read<int>('comparison_version'), 1);
      expect(log.read<bool>('used_hint'), isFalse);
      final stored = [
        for (final row
            in await db.customSelect('SELECT * FROM review_log').get())
          ...row.data.values,
        for (final row
            in await db.customSelect('SELECT * FROM study_queue_items').get())
          ...row.data.values,
      ];
      expect(stored, isNot(contains('cong')));
      expect(stored, isNot(contains('  cÔnG  ')));
    });

    test('a shown hint is recorded on a turn it does not turn right; the one '
        'submission ends the turn, and the card comes back as a new turn of '
        'the next round (BR-STUDY-028, BR-STUDY-059; IT-MODE-011)', () async {
      final id = await fillReview('A');
      await sessions.showFillHint(sessionId: id, cardId: 'A-card');

      expect(
        await turn(id, 'A-card', const FillAnswer('Cong')),
        _judged(isCorrect: false),
      );
      final log = (await logsOf('A-card')).single;
      expect(log.read<String>('action'), 'forgotten');
      expect(log.read<bool>('used_hint'), isTrue);
      final rows = await db
          .customSelect(
            'SELECT round, status, hint_shown FROM study_queue_items'
            ' WHERE session_id = ? ORDER BY round',
            variables: [Variable<String>(id)],
          )
          .get();
      expect(
        [
          for (final row in rows)
            (
              row.read<int>('round'),
              row.read<String>('status'),
              row.read<int>('hint_shown'),
            ),
        ],
        [(1, 'completed', 1), (2, 'pending', 0)],
      );
    });
  });
}
```

In `test/features/study/data/round_preparation_test.dart`:

Replace

```dart
import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:flutter_test/flutter_test.dart';
```

with

```dart
import 'package:flutter_test/flutter_test.dart';
```

Replace

```dart
// match boards, and keeps them.

/// Cuts the meaning source of a guess question to the rows [keep] names,
/// the way the fault injector of S-STUDY-GUESS-BLOCKED-V2 does, with the
/// database untouched.
final class _ThinMeaningSource extends QueryInterceptor {
  _ThinMeaningSource(this.keep);

  final int keep;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    if (!statement.contains('AS meaning_folded')) return rows;
    return rows.take(keep).toList();
  }
}

```

with

```dart
// match boards, and keeps them.

```

Replace

```dart
    await db.close();
    open(openTestDatabase(interceptor: _ThinMeaningSource(4)));
    final leaf = await fiveDue();
```

with

```dart
    await db.close();
    open(openTestDatabase(interceptor: ThinMeaningSource(4)));
    final leaf = await fiveDue();
```

In `test/features/study/data/session_endings_test.dart`:

Replace

```dart
    while ((await sessionOf(db, id)).read<String>('status') == 'in_progress') {
      final mode = (await sessionOf(db, id)).read<String>('current_mode');
      await answer(
        id,
        mode == 'browse'
            ? const AdvanceAnswer()
            : const GradedAnswer(isCorrect: true),
      );
    }
```

with

```dart
    while ((await sessionOf(db, id)).read<String>('status') == 'in_progress') {
      await answerServed(db, sessions, id, right: true);
    }
```

Replace

```dart
    final id = (opened as Ok<String, StudyRejection>).value;
    await answer(id, const GradedAnswer(isCorrect: false));
    await deleteCards({'b', 'c'});
```

with

```dart
    final id = (opened as Ok<String, StudyRejection>).value;
    await answerServed(db, sessions, id, right: false);
    await deleteCards({'b', 'c'});
```

Replace

```dart
        cardId: 'a',
        answer: const GradedAnswer(isCorrect: true),
      ),
```

with

```dart
        cardId: 'a',
        answer: const AdvanceAnswer(),
      ),
```

In `test/features/study/data/watch_entry_test.dart`:

Replace

```dart
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

with

```dart
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

Replace

```dart
    for (var turn = 0; turn < 2; turn++) {
      await sessions.answerTurn(
        sessionId: id,
        cardId: (await servedCard(db, id))!,
        answer: const GradedAnswer(isCorrect: true),
      );
    }
```

with

```dart
    for (var turn = 0; turn < 2; turn++) {
      await answerServed(db, sessions, id, right: true);
    }
```

In `test/features/study/data/watch_session_test.dart`:

Replace

```dart
    final id = (opened as Ok<String, StudyRejection>).value;
    await answer(id, const GradedAnswer(isCorrect: false));
    await answer(id, const GradedAnswer(isCorrect: true));
    await answer(id, const GradedAnswer(isCorrect: true));

```

with

```dart
    final id = (opened as Ok<String, StudyRejection>).value;
    await answerServed(db, sessions, id, right: false);
    await answerServed(db, sessions, id, right: true);
    await answerServed(db, sessions, id, right: true);

```

In `test/features/study/domain/answer_study_turn_use_case_test.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
```

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
```

Replace

```dart
  @override
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
```

with

```dart
  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
```

Replace

```dart

  Future<Outcome<void, StudyRejection>> turn(
    String sessionId,
```

with

```dart

  Future<Outcome<TurnResult, StudyRejection>> turn(
    String sessionId,
```

Replace

```dart

  test('a fatal error rolls the turn back and closes the session as failed; '
```

with

```dart

  test('a recall timeout that met a busy database is sent again and recorded '
      'once, with its reason (BR-STUDY-033, UC-STUDY-001 E2)', () async {
    final leaf = await insertFiveDue(
      db,
      DeckRepositoryImpl(db, now: () => now),
    );
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    schedules.fault = sqlite3.SqliteException(
      extendedResultCode: 5,
      message: 'database is locked',
    );
    const timedOut = RecallAnswer(RecallOutcome.timedOut);

    await expectLater(
      turn(id, timedOut),
      throwsA(isA<DatabaseLockedFailure>()),
    );
    expect(await logCount(), 0);

    expect(
      await turn(id, timedOut),
      isA<Ok<TurnResult, StudyRejection>>().having(
        (ok) => ok.value.isCorrect,
        'isCorrect',
        isFalse,
      ),
    );
    final log = await db
        .customSelect('SELECT "action", outcome_reason FROM review_log')
        .getSingle();
    expect(
      (log.read<String>('action'), log.read<String>('outcome_reason')),
      ('forgotten', 'timeout'),
    );
  });

  test('a fatal error rolls the turn back and closes the session as failed; '
```

In `test/features/study_mode/domain/study_mode_handler_test.dart`:

Replace

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

with

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

Replace

```dart
    isA<StageSkipped>().having((skipped) => skipped.reason, 'reason', reason);

Matcher _refusedWith(StudyModeRejection reason) =>
    isA<Rejected<Object?, StudyModeRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

Matcher _gives(Object? action) => isA<Ok<Object?, StudyModeRejection>>().having(
  (ok) => ok.value,
  'action',
  action,
);

```

with

```dart
    isA<StageSkipped>().having((skipped) => skipped.reason, 'reason', reason);

```

Replace

```dart

  group('answers and actions', () {
    test('browse moves on without an action and refuses a grade '
        '(BR-MODE-005)', () {
      final browse = StudyMode.browse.handler;

      expect(
        browse.actionOf(const AdvanceAnswer(), eightBoxScheduler),
        _gives(null),
      );
      expect(
        browse.actionOf(const GradedAnswer(isCorrect: true), eightBoxScheduler),
        _refusedWith(StudyModeRejection.answerDoesNotFitMode),
      );
    });

    test('self_assess records the action the person pressed, from the '
        'scheduler\'s actions only (BR-MODE-011, BR-STUDY-009)', () {
      final selfAssess = StudyMode.selfAssess.handler;

      expect(
        selfAssess.actionOf(
          const SelfAssessAnswer(Sm2Action.hard),
          sm2Scheduler,
        ),
        _gives(Sm2Action.hard),
      );
      expect(
        selfAssess.actionOf(
          const SelfAssessAnswer(EightBoxAction.remembered),
          sm2Scheduler,
        ),
        _refusedWith(StudyModeRejection.unsupportedAction),
      );
      expect(
        selfAssess.actionOf(const AdvanceAnswer(), sm2Scheduler),
        _refusedWith(StudyModeRejection.answerDoesNotFitMode),
      );
    });

    test('a graded mode maps wrong to forgotten and right to remembered '
        '(BR-MODE-012)', () {
      for (final mode in [
        StudyMode.match,
        StudyMode.guess,
        StudyMode.recall,
        StudyMode.fill,
      ]) {
        final handler = mode.handler;
        expect(
          handler.actionOf(
            const GradedAnswer(isCorrect: false),
            eightBoxScheduler,
          ),
          _gives(EightBoxAction.forgotten),
        );
        expect(
          handler.actionOf(
            const GradedAnswer(isCorrect: true),
            eightBoxScheduler,
          ),
          _gives(EightBoxAction.remembered),
        );
        expect(
          handler.actionOf(
            const SelfAssessAnswer(EightBoxAction.remembered),
            eightBoxScheduler,
          ),
          _refusedWith(StudyModeRejection.answerDoesNotFitMode),
        );
      }
    });

    test('a graded verdict has no action under sm2 (BR-MODE-007)', () {
      expect(
        StudyMode.recall.handler.actionOf(
          const GradedAnswer(isCorrect: true),
          sm2Scheduler,
        ),
        _refusedWith(StudyModeRejection.unsupportedAction),
      );
    });
  });

  group('what a turn does to its row', () {
```

with

```dart

  group('what a turn does to its row', () {
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/srs/data/record_turn_test.dart \
  test/features/study/data/answer_rounds_test.dart \
  test/features/study/data/match_guess_turns_test.dart \
  test/features/study/data/recall_fill_turns_test.dart \
  test/features/study/data/round_preparation_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_entry_test.dart \
  test/features/study/data/watch_session_test.dart \
  test/features/study/domain/answer_study_turn_use_case_test.dart \
  test/features/study_mode/domain/study_mode_handler_test.dart
```

Expected: `+8 -9: Some tests failed.` Every changed test file fails to load, `TurnResult` and the new `ReviewTurn` fields not existing yet, but `study_mode_handler_test.dart`, whose eight tests pass. The first errors: `Error: 'TurnResult' isn't a type.`, `Error: Error when reading 'lib/features/study/domain/models/turn_result_model.dart': No such file or directory`, `Error: Type 'TurnResult' not found.`

- [ ] **Step 3: Carry what the mode adds to review_log**

In `lib/features/srs/data/repositories/schedule_repository_impl.dart`:

Replace

```dart
  direction: Value(turn.directionCode),
  action: (turn.action as Enum).name,
```

with

```dart
  direction: Value(turn.directionCode),
  outcomeReason: Value(turn.outcomeReasonCode),
  comparisonVersion: Value(turn.comparisonVersion),
  usedHint: Value(switch (turn.usedHint) {
    null => null,
    true => 1,
    false => 0,
  }),
  action: (turn.action as Enum).name,
```

In `lib/features/srs/domain/models/review_turn_model.dart`:

Replace

```dart
    this.directionCode,
  });
```

with

```dart
    this.directionCode,
    this.outcomeReasonCode,
    this.comparisonVersion,
    this.usedHint,
  });
```

Replace

```dart
  final DateTime answeredAt;
}
```

with

```dart
  final DateTime answeredAt;

  /// What the mode adds to the turn, passed the way [modeCode] is: the code
  /// of the reason a `recall` turn ended (BR-STUDY-034), and the comparison
  /// version and the shown hint of a `fill` turn (BR-STUDY-027,
  /// BR-STUDY-028). The schema refuses them on any other mode.
  final String? outcomeReasonCode;
  final int? comparisonVersion;
  final bool? usedHint;
}
```

- [ ] **Step 4: Return the turn's result**

Create `lib/features/study/domain/models/turn_result_model.dart`:

```dart
/// What a turn tells the screen (graded modes spec §8.1): whether the answer
/// was right, for the feedback of a graded mode. Null for `browse` and
/// `self_assess`, whose result the person chose.
final class TurnResult {
  const TurnResult({this.isCorrect});

  final bool? isCorrect;
}
```

In `lib/features/study/domain/repositories/study_session_repository.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
```

Replace

```dart
  /// UC-STUDY-001 steps 6–9: [answer] on [cardId], the card the session
  /// serves in its current mode and round, or any pending card of a `match`
  /// board (notCurrentCard otherwise, BR-STUDY-042). A turn with an action
  /// is recorded through srs (BR-STUDY-009, BR-STUDY-023); the row then
  /// leaves, comes back or joins the next round (BR-STUDY-005,
```

with

```dart
  /// UC-STUDY-001 steps 6–9: [answer] on [cardId], the card the session
  /// serves in its current mode and round, or a pending pair of the current
  /// `match` board (notCurrentCard otherwise, BR-STUDY-042, BR-STUDY-049).
  /// The mode judges the answer against the card and what its row keeps
  /// (graded modes spec §7): a blank `fill` answer, a `recall` answer out of
  /// turn with its reveal, a blocked `guess` question, a card that is not
  /// one of its options and a meaning off the board are refused. A turn with
  /// an action is recorded through srs with what its mode adds (BR-STUDY-009,
  /// BR-STUDY-023, BR-STUDY-027, BR-STUDY-028, BR-STUDY-034); the row then
  /// leaves, comes back or joins the next round (BR-STUDY-005,
```

Replace

```dart
  /// answer refused as staleGeneration (BR-STUDY-017); any other refusal
  /// writes nothing.
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
```

with

```dart
  /// answer refused as staleGeneration (BR-STUDY-017); any other refusal
  /// writes nothing. The result says whether a graded answer was right.
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
```

In `lib/features/study/domain/usecases/answer_study_turn_use_case.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
```

Replace

```dart

  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
```

with

```dart

  Future<Outcome<TurnResult, StudyRejection>> call({
    required String sessionId,
```

- [ ] **Step 5: Judge the turn in the session**

In `lib/features/study/data/datasources/study_queue_dao.dart`:

Replace

```dart
  /// [cardId]'s pending row in the lowest pending round of [mode], once that
  /// round is built: a `match` board serves any of its rows.
  Future<StudyQueueItem?> boardRow(
```

with

```dart
  /// [cardId]'s pending row in the lowest pending round of [mode], once that
  /// round is built: a `match` board serves any of its rows, and the caller
  /// checks the row is on the current board.
  Future<StudyQueueItem?> boardRow(
```

Replace

```dart
      _update(row, const StudyQueueItemsCompanion(hintShown: Value(1)));

```

with

```dart
      _update(row, const StudyQueueItemsCompanion(hintShown: Value(1)));

  /// `guess`: the options stored for [row], in the order shown
  /// (BR-STUDY-041).
  Future<List<String>> optionIds(StudyQueueItem row) async {
    final options =
        await (_db.select(_db.studyGuessOptions)
              ..where(
                (o) =>
                    o.sessionId.equals(row.sessionId) &
                    o.mode.equals(row.mode) &
                    o.round.equals(row.round) &
                    o.cardId.equals(row.cardId),
              )
              ..orderBy([(o) => OrderingTerm(expression: o.slot)]))
            .get();
    return [for (final option in options) option.optionCardId];
  }

  /// `match`: the pending pairs of [row]'s round between the positions
  /// [from] and [to], card id to `back_folded` (graded modes spec §7.6).
  Future<Map<String, String>> pendingMeanings(
    StudyQueueItem row, {
    required int from,
    required int to,
  }) async {
    final rows = await _db
        .customSelect(
          'SELECT q.card_id, c.back_folded FROM study_queue_items q'
          ' JOIN card c ON c.id = q.card_id'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.round = ?'
          ' AND q.status = ? AND q.position BETWEEN ? AND ?',
          variables: [
            Variable<String>(row.sessionId),
            Variable<String>(row.mode),
            Variable<int>(row.round),
            const Variable<String>(_pending),
            Variable<int>(from),
            Variable<int>(to),
          ],
          readsFrom: {_db.studyQueueItems, _db.card},
        )
        .get();
    return {
      for (final pair in rows)
        pair.read<String>('card_id'): pair.read<String>('back_folded'),
    };
  }

  /// `match`: [row] and [otherCardId]'s row of the same round swap their
  /// meaning slots (graded modes spec §7.6).
  Future<void> swapMeaningSlots(StudyQueueItem row, String otherCardId) async {
    final other =
        await (_db.select(_db.studyQueueItems)..where(
              (q) =>
                  q.sessionId.equals(row.sessionId) &
                  q.mode.equals(row.mode) &
                  q.round.equals(row.round) &
                  q.cardId.equals(otherCardId),
            ))
            .getSingle();
    await _update(
      row,
      StudyQueueItemsCompanion(meaningSlot: Value(other.meaningSlot)),
    );
    await _update(
      other,
      StudyQueueItemsCompanion(meaningSlot: Value(row.meaningSlot)),
    );
  }

```

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart
    );
  }

  /// Whether [cardId] has a hint; a blank one is stored as NULL
```

with

```dart
    );
  }

  /// The card [id]: a turn is judged on its folded fields (graded modes spec
  /// §7.2). A queue row keeps its card, so the card is there.
  Future<CardRow> cardRow(String id) =>
      (_db.select(_db.card)..where((card) => card.id.equals(id))).getSingle();

  /// Whether [cardId] has a hint; a blank one is stored as NULL
```

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
```

with

```dart
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study/domain/models/turn_result_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/recall_mode.dart';
```

Replace

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

with

```dart
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/study_mode/domain/models/turn_judgement_model.dart';

```

Replace

```dart
  @override
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
```

with

```dart
  @override
  Future<Outcome<TurnResult, StudyRejection>> answerTurn({
    required String sessionId,
```

Replace

```dart

  /// [answer] on [cardId] in an open [session] (spec §7.3 steps 2–8).
  Future<Outcome<void, StudyRejection>> _answer(
    StudySession session,
```

with

```dart

  /// [answer] on [cardId] in an open [session] (spec §7.3 steps 2–8; graded
  /// modes spec §8.1).
  Future<Outcome<TurnResult, StudyRejection>> _answer(
    StudySession session,
```

Replace

```dart
    final mode = StudyMode.fromCode(session.currentMode);
    final row = mode.handler.servesInOrder
        ? await _queue.headRow(session.id, mode.code, session.cursor)
        : await _queue.boardRow(session.id, mode.code, cardId);
    if (row == null || row.cardId != cardId) {
      return const Rejected(StudyRejection.notCurrentCard);
    }

```

with

```dart
    final mode = StudyMode.fromCode(session.currentMode);
    final row = await _servedRow(session, mode, cardId);
    if (row == null) return const Rejected(StudyRejection.notCurrentCard);

```

Replace

```dart
    final scheduler = schedulerFor(type);
    final Object? action;
    switch (mode.handler.actionOf(answer, scheduler)) {
      case Rejected(:final reason):
```

with

```dart
    final scheduler = schedulerFor(type);
    final TurnVerdict verdict;
    switch (mode.handler.judge(
      answer,
      await _contextOf(mode, row),
      scheduler,
    )) {
      case Rejected(:final reason):
```

Replace

```dart
      case Ok(:final value):
        action = value;
    }
    final kind = SessionKind.values.byName(session.sessionKind);
```

with

```dart
      case Ok(:final value):
        verdict = value;
    }
    final action = verdict.action;
    final kind = SessionKind.values.byName(session.sessionKind);
```

Replace

```dart
          answeredAt: at,
        ),
```

with

```dart
          answeredAt: at,
          outcomeReasonCode: verdict.outcomeReason?.code,
          comparisonVersion: verdict.comparisonVersion,
          usedHint: verdict.usedHint,
        ),
```

Replace

```dart
    );
    await _dao.setCursor(session.id, cursor);
```

with

```dart
    );
    if (verdict.takesMeaningSlotOf case final other?) {
      await _queue.swapMeaningSlots(row, other);
    }
    await _dao.setCursor(session.id, cursor);
```

Replace

```dart
    await _progress(session, type, at);
    return const Ok(null);
  }
```

with

```dart
    await _progress(session, type, at);
    return Ok(TurnResult(isCorrect: verdict.isCorrect));
  }

  /// [cardId]'s row that [session] serves in [mode]: the head row, or in a
  /// mode that does not serve in order, the card's pending pair on the board
  /// of the head row (graded modes spec §7.6). Null when the card is not
  /// served.
  Future<StudyQueueItem?> _servedRow(
    StudySession session,
    StudyMode mode,
    String cardId,
  ) async {
    final head = await _queue.headRow(session.id, mode.code, session.cursor);
    if (head == null || mode.handler.servesInOrder) {
      return head?.cardId == cardId ? head : null;
    }
    final row = await _queue.boardRow(session.id, mode.code, cardId);
    if (row == null) return null;
    return matchBoardOf(row.position) == matchBoardOf(head.position)
        ? row
        : null;
  }

  /// What [mode] judges the turn on [row] by: the card's folded fields, the
  /// row's flags, and the stored options or the pending pairs of the board
  /// (graded modes spec §7.2, §8.1 step 3).
  Future<TurnContext> _contextOf(StudyMode mode, StudyQueueItem row) async {
    final card = await _dao.cardRow(row.cardId);
    final board = matchBoardOf(row.position) * matchBoardSize;
    return TurnContext(
      card: TurnCard(
        cardId: card.id,
        frontFolded: card.frontFolded,
        backFolded: card.backFolded,
      ),
      isRevealed: row.isRevealed == 1,
      isHintShown: row.hintShown == 1,
      guessOptionIds: mode.handler.asksWithOptions
          ? await _queue.optionIds(row)
          : null,
      boardMeanings: mode.handler.servesInOrder
          ? const {}
          : await _queue.pendingMeanings(
              row,
              from: board,
              to: board + matchBoardSize - 1,
            ),
    );
  }
```

In `lib/features/study_mode/domain/models/turn_judgement_model.dart`:

Replace

```dart

  /// `guess`: the stored options of the row, in the order shown; null when
  /// none are stored.
  final List<String>? guessOptionIds;
```

with

```dart

  /// `guess`: the stored options of the row, in the order shown; a question
  /// without five takes no answer (BR-STUDY-040). Null in the other modes.
  final List<String>? guessOptionIds;
```

- [ ] **Step 6: Remove actionOf and GradedAnswer**

In `lib/features/study_mode/domain/models/browse_mode.dart`:

Replace

```dart
  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) => switch (answer) {
    AdvanceAnswer() => const Ok(null),
    SelfAssessAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
```

with

```dart
  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
```

Replace

```dart
    AdvanceAnswer() => const Ok(TurnVerdict(action: null)),
    SelfAssessAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
```

with

```dart
    AdvanceAnswer() => const Ok(TurnVerdict(action: null)),
    SelfAssessAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
```

In `lib/features/study_mode/domain/models/graded_mode.dart`:

Replace

```dart
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

with

```dart
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
```

Replace

```dart
  bool get usesRounds => true;

  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) {
    if (answer is! GradedAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    return _actionOf(answer.isCorrect, scheduler);
  }

```

with

```dart
  bool get usesRounds => true;

```

In `lib/features/study_mode/domain/models/self_assess_mode.dart`:

Replace

```dart
  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) => switch (answer) {
    SelfAssessAnswer(:final action)
        when scheduler.supportedActions.contains(action) =>
      Ok(action),
    SelfAssessAnswer() => const Rejected(StudyModeRejection.unsupportedAction),
    AdvanceAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
    MatchAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
```

with

```dart
  @override
  Outcome<TurnVerdict, StudyModeRejection> judge(
```

Replace

```dart
      Ok(TurnVerdict(action: action)),
    SelfAssessAnswer() => const Rejected(StudyModeRejection.unsupportedAction),
    AdvanceAnswer() ||
    GradedAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
```

with

```dart
      Ok(TurnVerdict(action: action)),
    SelfAssessAnswer() => const Rejected(StudyModeRejection.unsupportedAction),
    AdvanceAnswer() ||
    FillAnswer() ||
    RecallAnswer() ||
    GuessAnswer() ||
```

In `lib/features/study_mode/domain/models/study_answer_model.dart`:

Replace

```dart
  final Object action;
}

/// A graded mode's verdict (BR-MODE-011, BR-MODE-012). Package 2a's stand-in
/// for the real inputs below; the session stops taking it in Task 6.
final class GradedAnswer extends StudyAnswer {
  const GradedAnswer({required this.isCorrect});

  final bool isCorrect;
}
```

with

```dart
  final Object action;
}
```

In `lib/features/study_mode/domain/models/study_mode.dart`:

Replace

```dart

  /// The action [answer] records under [scheduler], null when the mode
  /// records none, or why [answer] does not fit (BR-MODE-011, BR-MODE-012).
  /// Package 2a's path, which [judge] replaces in Task 6.
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  );

  /// What [answer] makes of the turn [context] describes under [scheduler],
```

with

```dart

  /// What [answer] makes of the turn [context] describes under [scheduler],
```

- [ ] **Step 7: Fix the three documents the owner allowed**

In `docs/features/study/it-scenarios.md`:

Replace

```markdown
| 2 | Chờ một khoảng khi ứng dụng ở phía trước | Thời gian giảm theo thời gian tương tác; thời gian tải nội dung không bị tính vào lượt |
| 3 | Chạm Hiện đáp án trước hạn | Mặt sau hiện ra và kết cục được chốt một lần, không còn hành động khác để đổi |
| 4 | Quan sát trạng thái sau khi lật | Có lời xác nhận lượt đã chốt; màn hình không giống bị treo và chỉ vòng sau mới bắt đầu lại 20 giây |

```

with

```markdown
| 2 | Chờ một khoảng khi ứng dụng ở phía trước | Thời gian giảm theo thời gian tương tác; thời gian tải nội dung không bị tính vào lượt |
| 3 | Chạm Hiện đáp án trước hạn | Mặt sau hiện ra, đồng hồ dừng, và hai lựa chọn Nhớ được/Đã quên xuất hiện; chưa có kết cục nào được ghi (BR-STUDY-065) |
| 4 | Chọn Nhớ được hoặc Đã quên | Chỉ lựa chọn đó được ghi, đúng một lần; lượt tự chuyển sau khi ghi, không có nút Tiếp theo (BR-STUDY-066); chỉ vòng sau mới bắt đầu lại 20 giây |

```

In `docs/features/study/rules/BR-STUDY-026-fill-de-la-mat-sau-go-mat-truoc.md`:

Replace

```markdown

**BR-STUDY-026 dùng lại `back_folded`, và điều đáng kiểm là nó fold những gì.** Cột đó
trim và hạ hoa Unicode-aware nhưng **không bỏ dấu** — chỉ fold hoa/thường, nên
```

with

```markdown

**BR-STUDY-026 dùng lại `front_folded`, và điều đáng kiểm là nó fold những gì.** Cột đó
trim và hạ hoa Unicode-aware nhưng **không bỏ dấu** — chỉ fold hoa/thường, nên
```

In `docs/shared/testing/agent-execution-guide.md`:

Replace

```markdown

Một thẻ Eight Box đã học và đến hạn: mặt trước `Nghề nghiệp`, mặt sau `Công`, câu
ví dụ `Đây là một công việc tốt.`, gợi ý `Bắt đầu bằng C`. `Fill` có số lượng 1
```

with

```markdown

Một thẻ Eight Box đã học và đến hạn: mặt trước `Công`, mặt sau `Nghề nghiệp`, câu
ví dụ `Đây là một công việc tốt.`, gợi ý `Bắt đầu bằng C`. `Fill` có số lượng 1
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/srs/data/record_turn_test.dart \
  test/features/study/data/answer_rounds_test.dart \
  test/features/study/data/match_guess_turns_test.dart \
  test/features/study/data/recall_fill_turns_test.dart \
  test/features/study/data/round_preparation_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_entry_test.dart \
  test/features/study/data/watch_session_test.dart \
  test/features/study/domain/answer_study_turn_use_case_test.dart \
  test/features/study_mode/domain/study_mode_handler_test.dart
```

Expected: `+85: All tests passed!`

- [ ] **Step 9: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1274: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  docs/features/study/it-scenarios.md \
  docs/features/study/rules/BR-STUDY-026-fill-de-la-mat-sau-go-mat-truoc.md \
  docs/shared/testing/agent-execution-guide.md \
  lib/features/srs/data/repositories/schedule_repository_impl.dart \
  lib/features/srs/domain/models/review_turn_model.dart \
  lib/features/study/data/datasources/study_queue_dao.dart \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/domain/models/turn_result_model.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  lib/features/study/domain/usecases/answer_study_turn_use_case.dart \
  lib/features/study_mode/domain/models/browse_mode.dart \
  lib/features/study_mode/domain/models/graded_mode.dart \
  lib/features/study_mode/domain/models/self_assess_mode.dart \
  lib/features/study_mode/domain/models/study_answer_model.dart \
  lib/features/study_mode/domain/models/study_mode.dart \
  lib/features/study_mode/domain/models/turn_judgement_model.dart \
  test/features/srs/data/record_turn_test.dart \
  test/features/study/data/answer_rounds_test.dart \
  test/features/study/data/match_guess_turns_test.dart \
  test/features/study/data/recall_fill_turns_test.dart \
  test/features/study/data/round_preparation_test.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/data/watch_entry_test.dart \
  test/features/study/data/watch_session_test.dart \
  test/features/study/domain/answer_study_turn_use_case_test.dart \
  test/features/study_mode/domain/study_mode_handler_test.dart \
  test/support/study_fixtures.dart \
  test/support/test_database.dart
git commit -F - <<'EOF'
feat(study,srs): the turn judges the person's real input

A turn reads its card's folded fields, the row's reveal and hint, the
question's stored options or the board's pending pairs, and the mode judges
the answer (graded modes spec §8.1). The turn records through srs with the
outcome reason of a recall timeout, and the comparison version and the hint
of a fill; a right match pair on another card's equal meaning takes that
card's tile; and the use case returns whether the answer was right
(BR-STUDY-063). A match turn stays on the current board. Package 2a's tests
answer with the real inputs, and actionOf and GradedAnswer are gone.

IT-MODE-008 steps 3 and 4, the front and back of S-STUDY-FILL-V2 and the
field BR-STUDY-026's rationale names now agree with the rules (spec D11).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 7: Package docs: the use case code field, the WBS

**Files:**
- Modify: `docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md`, `docs/wbs_BE.md`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: the three use case files of Task 5.
- Produces: UC-STUDY-001's `code:` names them; `docs/wbs_BE.md` has BE-D1 and
  BE-A10 done, and BE-B1 brings migration v2 → v3.

Spec §12; Clarification 12. The traceability index picks up the
new use cases, and the WBS records the package.

- [ ] **Step 1: Update the use case and the WBS**

In `docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md`:

Replace

```markdown
rules: [BR-DECK-024, BR-MODE-002, BR-MODE-003, BR-MODE-006, BR-MODE-009, BR-SRS-003, BR-SRS-008, BR-SRS-009, BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-SRS-014, BR-SRS-015, BR-SRS-016, BR-SRS-017, BR-SRS-018, BR-SRS-019, BR-SRS-025, BR-SRS-026, BR-STUDY-002, BR-STUDY-003, BR-STUDY-004, BR-STUDY-005, BR-STUDY-006, BR-STUDY-007, BR-STUDY-008, BR-STUDY-009, BR-STUDY-010, BR-STUDY-012, BR-STUDY-013, BR-STUDY-014, BR-STUDY-015, BR-STUDY-017, BR-STUDY-018, BR-STUDY-019, BR-STUDY-020, BR-STUDY-021]
code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/features/study/domain/usecases/open_learning_session_use_case.dart, lib/features/study/domain/usecases/open_review_session_use_case.dart, lib/features/study/domain/usecases/watch_study_session_use_case.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/domain/usecases/abandon_study_session_use_case.dart, lib/features/study/domain/usecases/resume_study_session_use_case.dart, lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart]
---
```

with

```markdown
rules: [BR-DECK-024, BR-MODE-002, BR-MODE-003, BR-MODE-006, BR-MODE-009, BR-SRS-003, BR-SRS-008, BR-SRS-009, BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-SRS-014, BR-SRS-015, BR-SRS-016, BR-SRS-017, BR-SRS-018, BR-SRS-019, BR-SRS-025, BR-SRS-026, BR-STUDY-002, BR-STUDY-003, BR-STUDY-004, BR-STUDY-005, BR-STUDY-006, BR-STUDY-007, BR-STUDY-008, BR-STUDY-009, BR-STUDY-010, BR-STUDY-012, BR-STUDY-013, BR-STUDY-014, BR-STUDY-015, BR-STUDY-017, BR-STUDY-018, BR-STUDY-019, BR-STUDY-020, BR-STUDY-021]
code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/features/study/domain/usecases/open_learning_session_use_case.dart, lib/features/study/domain/usecases/open_review_session_use_case.dart, lib/features/study/domain/usecases/watch_study_session_use_case.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/domain/usecases/reveal_recall_answer_use_case.dart, lib/features/study/domain/usecases/save_recall_time_use_case.dart, lib/features/study/domain/usecases/show_fill_hint_use_case.dart, lib/features/study/domain/usecases/abandon_study_session_use_case.dart, lib/features/study/domain/usecases/resume_study_session_use_case.dart, lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart]
---
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, điều kiện dữ liệu của từng mode, câu trả lời và action, bước của dòng hàng đợi (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | xong | BE-02 | M | [spec](superpowers/specs/2026-09-24-study-session-backend-design.md) và [plan](superpowers/plans/2026-09-24-study-session-backend.md) gói 2a; test trong `test/features/study_mode/` | — |
| BE-A4 | Phiên học và hàng đợi, 8 use case (UC-STUDY-001): mở phiên `learning`/`reviewing` cho một cây deck, dựng round 1 của mọi stage; ghi lượt qua `recordTurn`, hoàn tất chuỗi học mới qua `completeLearning`; round, stage, thẻ quay lại và trần của `self_assess`; kết thúc, bỏ dở, tiếp tục, đóng phiên của ngày trước, `failed` khi lỗi ghi; read model của Study Entry và của màn phiên | xong | BE-A1, BE-A3 | XL | Spec và plan gói 2a; test trong `test/features/study/` và `test/features/srs/` | Cơ chế bốn mode chấm điểm ở BE-A10 |
| BE-A5 | Chọn chiều hỏi cho phiên self-assess của deck `sm2`, phần backend (UC-STUDY-003; BR-MODE-013…BR-MODE-019): phiên ôn `sm2` cần chiều hỏi, chiều của từng thẻ lưu trên dòng hàng đợi và chép sang `review_log` | xong | BE-A3, BE-A4 | S | Spec và plan gói 2a; test trong `test/features/study/` | — |
| BE-C3 | Lọc Trash trên luồng học: `SrsDao.rootOfCard`, dùng trong `recordTurn`, `completeLearning` và `initializeCard` | xong | — | S | Spec và plan gói 2a; test trong `test/features/srs/data/record_turn_test.dart` | — |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

with

```markdown
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, điều kiện dữ liệu của từng mode, câu trả lời và action, bước của dòng hàng đợi (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | xong | BE-02 | M | [spec](superpowers/specs/2026-09-24-study-session-backend-design.md) và [plan](superpowers/plans/2026-09-24-study-session-backend.md) gói 2a; test trong `test/features/study_mode/` | — |
| BE-A4 | Phiên học và hàng đợi, 8 use case (UC-STUDY-001): mở phiên `learning`/`reviewing` cho một cây deck, dựng round 1 của mọi stage; ghi lượt qua `recordTurn`, hoàn tất chuỗi học mới qua `completeLearning`; round, stage, thẻ quay lại và trần của `self_assess`; kết thúc, bỏ dở, tiếp tục, đóng phiên của ngày trước, `failed` khi lỗi ghi; read model của Study Entry và của màn phiên | xong | BE-A1, BE-A3 | XL | Spec và plan gói 2a; test trong `test/features/study/` và `test/features/srs/` | — |
| BE-A5 | Chọn chiều hỏi cho phiên self-assess của deck `sm2`, phần backend (UC-STUDY-003; BR-MODE-013…BR-MODE-019): phiên ôn `sm2` cần chiều hỏi, chiều của từng thẻ lưu trên dòng hàng đợi và chép sang `review_log` | xong | BE-A3, BE-A4 | S | Spec và plan gói 2a; test trong `test/features/study/` | — |
| BE-C3 | Lọc Trash trên luồng học: `SrsDao.rootOfCard`, dùng trong `recordTurn`, `completeLearning` và `initializeCard` | xong | — | S | Spec và plan gói 2a; test trong `test/features/srs/data/record_turn_test.dart` | — |
| BE-A10 | Cơ chế bốn mode chấm điểm (phần còn lại của UC-STUDY-001), 3 use case mới: so khớp, phiên bản chính sách và gợi ý của `fill`; đồng hồ, lật đáp án và hết giờ của `recall`; dựng câu hỏi `guess`, chỉ nhận lựa chọn đầu; bàn `match` và việc quy lượt; mỗi lượt trả về đúng hay sai (BR-STUDY-026…BR-STUDY-043, BR-STUDY-049, BR-STUDY-062, BR-STUDY-065, BR-STUDY-066, BR-STUDY-070) | xong | BE-A4, BE-D1 | L | [spec](superpowers/specs/2026-09-24-graded-modes-backend-design.md) và [plan](superpowers/plans/2026-09-24-graded-modes-backend.md) gói 2b; test trong `test/features/study/` và `test/features/study_mode/` | — |
| BE-D1 | Khung test migration Drift: snapshot schema theo từng version, bước nâng cấp sinh từ snapshot (`stepByStep`) và test nâng cấp; migration đầu tiên v1 → v2 của gói 2b | xong | — | S | Spec gói 2b §5, §6; `drift_schemas/`, `test/drift/migration_test.dart` | Mỗi migration sau thêm snapshot và bước của nó ([skill flutter-drift](../.claude/skills/flutter-drift/references/migrations.md)) |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-A10 | Cơ chế bốn mode chấm điểm (phần còn lại của UC-STUDY-001): so khớp, phiên bản chính sách và gợi ý của `fill`; đồng hồ, lật đáp án và hết giờ của `recall`; dựng câu hỏi `guess`, chỉ nhận lựa chọn đầu; bàn `match` và việc quy lượt (BR-STUDY-026…BR-STUDY-043, BR-STUDY-049, BR-STUDY-062, BR-STUDY-065, BR-STUDY-066, BR-STUDY-070) | chưa bắt đầu | BE-A4 | L | Gói 2a để các mode này nhận một kết luận đúng/sai (spec gói 2a §14) | Gói 2b, ngay sau gói 2a |
| BE-A6 | Study Home: read model cho tab Study (việc cần học trên toàn thư viện, phiên đang dở) (UC-STUDY-002) | chưa bắt đầu | BE-A4 | M | UC chưa có code | Sau BE-A4 |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-A6 | Study Home: read model cho tab Study (việc cần học trên toàn thư viện, phiên đang dở) (UC-STUDY-002) | chưa bắt đầu | BE-A4 | M | UC chưa có code | Sau BE-A4 |
```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-B1 | Trash: xoá mềm theo batch, khôi phục, purge (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) | chưa bắt đầu | BE-02, BE-D1 | L | Cột `delete_batch_id` đã có trên `deck` và `card` nhưng chưa có FK; chưa có bảng `delete_batches`; mọi query và lệnh ghi đã lọc `delete_batch_id IS NULL` | Mang migration đầu tiên (v1 → v2). Đổi xoá cứng của BR-DECK-022 và BR-DECK-023 thành tombstone; bất biến 33–37 của `schema.md` bắt đầu có hiệu lực |
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-B1 | Trash: xoá mềm theo batch, khôi phục, purge (UC-TRASH-001; BR-TRASH-001…BR-TRASH-012) | chưa bắt đầu | BE-02, BE-D1 | L | Cột `delete_batch_id` đã có trên `deck` và `card` nhưng chưa có FK; chưa có bảng `delete_batches`; mọi query và lệnh ghi đã lọc `delete_batch_id IS NULL` | Mang migration v2 → v3 (v1 → v2 thuộc gói 2b). Đổi xoá cứng của BR-DECK-022 và BR-DECK-023 thành tombstone; bất biến 33–37 của `schema.md` bắt đầu có hiệu lực |
| BE-B2 | Tag Management: danh mục tag, đổi tên có gộp, xoá, lọc card theo tag (UC-TAG-001; BR-TAG-003…BR-TAG-011) | chưa bắt đầu | BE-05 | M | Hàm predicate của card list đã chừa chỗ cho BR-TAG-004 (spec backend deck/card §8) | Gồm cả BE-C4 |
```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-D1 | Khung test migration Drift: snapshot schema theo từng version và test nâng cấp | chưa bắt đầu | — | S | Có `drift_schemas/drift_schema_v1.json` nhưng chưa có test migration nào | Làm trước migration đầu tiên (BE-B1, hoặc BE-A8 nếu thêm cột) |
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
```

Replace

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 12/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001, UC-STUDY-003).
```

with

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-D1 và BE-A10** (gói 2b,
  [spec](superpowers/specs/2026-09-24-graded-modes-backend-design.md),
  [plan](superpowers/plans/2026-09-24-graded-modes-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 12/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001, UC-STUDY-003).
```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 2a (BE-A3, BE-A4, BE-A5, BE-C3).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 2b (BE-D1, BE-A10).

```

Replace

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 52 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (3), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

with

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 62 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-ORG (4), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

Replace

```markdown

1. Gói 2b: BE-A10.
2. Gói 3: BE-A6. Rồi BE-A7, rồi BE-A8. BE-D1 phải xong trước migration đầu tiên; BE-D2
   càng sớm càng tốt.
3. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration đầu tiên), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
```

with

```markdown

1. Gói 3: BE-A6. Rồi BE-A7, rồi BE-A8. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
```

Replace

```markdown
  BE-A10 cho cơ chế bốn mode chấm điểm (gói 2b).
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  BE-A10 cho cơ chế bốn mode chấm điểm (gói 2b).
- **Cập nhật ngày 2026-09-24:** BE-D1 và BE-A10 xong trong gói 2b. Migration đầu tiên
  (v1 → v2) thuộc gói này, nên BE-B1 mang migration v2 → v3.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 2: Run the phased gate**

Run each command from the repository root:

```bash
export PATH=/root/.flutter-sdk/3.47.5/flutter/bin:$PATH   # this repository's Flutter
flutter analyze
flutter test --exclude-tags golden
python3 .claude/skills/flutter-architecture/scripts/check_architecture.py
python3 -m unittest discover -s .claude/skills/flutter-workflow/scripts/tests -p 'test_*.py'
COLUMNS=400 python3.13 code-verification-guard-v2/guard/run.py check --project . --ruleset memox-v8
python3 tools/docs/check.py
```

Expected: `No issues found!`; `+1274: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 3: Commit**

```bash
git add docs/_generated \
  docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md \
  docs/wbs_BE.md
git commit -F - <<'EOF'
docs(study): record package 2b in the use case and the WBS

UC-STUDY-001's code field names the three new use cases, and the backend WBS
has BE-D1 and BE-A10 done: the first migration (v1 to v2) is this package's,
so BE-B1 brings v2 to v3.
EOF
```

Append the session's attribution trailers to the message when you commit.


## Plan self-review

- **Spec coverage.** §5 BE-D1 (workflow, `AppDatabase`, the migration test, the
  generated files, the repo skill): Task 1. §6 schema v2 and invariants 38–40:
  Task 1; §6.5 sessions open across the upgrade: Task 4 (Continue fills them
  in). §7.1–§7.8 the study-mode domain: Task 3, with `turnTimeMs` in Task 5
  and the removal of `actionOf` and `GradedAnswer` in Task 6. §8.1 a turn and
  §8.4 srs: Task 6. §8.2 preparing a round: Task 4. §8.3 the writes that are
  not turns: Task 5. §8.5 the split: Task 2. §9 the read model: Tasks 4 and 5.
  §10 the use cases: Tasks 2, 5, 6. §11 tests: every scenario and every
  "also covered" line has its test in Tasks 1–6. §12 documents: `schema.md`
  and the skill (Task 1), `data.md` (Tasks 4, 5), the three contract fixes
  (Task 6), `code:`, WBS and `_generated` (Task 7 and every task).
- **Scenarios named by the spec (§11).** IT-MODE-004F, IT-MODE-005F,
  IT-MODE-008F, IT-MODE-009F, IT-MODE-010, IT-MODE-011, IT-MODE-014 (Task 6),
  IT-MODE-007, IT-MODE-015 and the backend half of IT-MODE-003 (Task 4): each
  is named by a test.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the
  replay compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in Task 6.
