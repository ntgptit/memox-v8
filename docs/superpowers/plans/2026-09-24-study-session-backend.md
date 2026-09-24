# MemoX V8 Study Session Backend Implementation Plan (package 2a)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build package 2a of [`docs/wbs_BE.md`](../../wbs_BE.md) — BE-A3 the
study-mode domain, BE-A4 the study session and its queue (UC-STUDY-001), BE-C3
the Trash filter of the study flow and the backend of BE-A5 (UC-STUDY-003) — as
domain, data and di code with one use case per interaction, so the UI session
can wire the Study Entry of a deck and the session screen. The four graded
modes take a right or wrong verdict here; their mechanics are package 2b. No
UI.

**Architecture:** `study_mode` is a new, pure domain feature (import map
`study_mode → {srs}`) with one dispatch point: `StudyMode.handler` gives each
mode a handler that owns its data condition, what an answer means and what a
turn does to its queue row. `srs` replaces `recordReview` with `recordTurn` and
`completeLearning`, follows BR-SRS-008…BR-SRS-012 in both schedulers, and
filters the Trash. The new `study` feature (import map
`study → {study_mode, srs, settings, card}`) has two repositories:
`StudyEntryRepository` opens sessions and reads the Study Entry, through the
settings; `StudySessionRepository` answers turns, moves rounds and stages,
ends sessions and reads the session screen, through srs and card. The rules
that need no row live in the domain (`queue_plan_model.dart`,
`turn_kind_model.dart`, `study_entry_model.dart`); every write is one Drift
transaction that the srs, card and settings calls join, and every read is a
Drift `watch()`.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35. No dependency is added, and the schema does
not change.

**Spec:** [`docs/superpowers/specs/2026-09-24-study-session-backend-design.md`](../specs/2026-09-24-study-session-backend-design.md),
approved 2026-09-24 and amended on this branch in `dc78e5c` (the Clarifications
below). Business rules: `docs/features/{study,study-mode,srs}/rules/`;
scenarios: `docs/features/study/it-scenarios.md`; data model:
[`docs/shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-study-session` holds the spec (`7b72c79`),
`master` up to `cbf7007` (#40; merged in `de9da7b` and `e5c26e3`) and the
spec amendments (`dc78e5c`). This plan runs on that branch, from the commit
that adds it; the gate passes there with 1001 tests. Generated code is not
committed: in a working tree built before these merges, run `flutter pub get`
and `dart run build_runner build --delete-conflicting-outputs` first (root
`README.md`, "Commands"), or `flutter analyze` reports the card screens'
missing strings and providers.

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed, and after every task the gate
passed. The code steps were then replayed from this document onto a clean
checkout of `e5c26e3`, and each task's result matched the scratch commit file
for file. The "Expected" lines are the ones those runs produced.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme (spec §14). A parallel session builds the
  screens (FE-A6, FE-A7). The shared files this plan touches are
  `test/architecture/boundary_rules.dart` (two entries), the `ScheduleRepository`
  and `SettingsRepository` contracts, and `test/support/card_fixtures.dart` (one
  optional parameter).
- Import map (spec D3): `'study_mode': {'srs'}` and
  `'study': {'study_mode', 'srs', 'settings', 'card'}`; `srs` stays `∅`. A feature
  never imports another feature's `data/` or `di/`.
- One dispatch (spec §5.1): `StudyMode` is switched on only in
  `study_mode.dart` (guard `single_study_mode_dispatch`); every question about a
  mode is a member of its handler.
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing
  `call` (AD-12). A write returns `Future<Outcome<T, StudyRejection>>`; a watch
  returns `Stream<Outcome<T, StudyRejection>>`, with a missing row as `notFound`.
- Every write is one transaction through the repository's `_write`
  (`mapDatabaseError`); the srs, card and settings calls it makes join it. A
  refusal writes nothing, with two exceptions the refusal reports: a session
  whose root was reset is closed as `invalidated`/`stale_generation`
  (BR-STUDY-017), and a session of an earlier day on Continue as
  `abandoned`/`interrupted` (BR-STUDY-072).
- Every read and every write of `deck` and `card` filters
  `delete_batch_id IS NULL`; BE-C3 adds the filter to `SrsDao.rootOfCard`.
- Stored codes: `StudyMode.code`, `SessionStatus.code`, `SessionEndReason.code`,
  `DirectionChoice.code` and `QuestionDirection.code`; `session_kind` stores
  `SessionKind.name`, and `review_log.action` the action enum's name.
- `now` and `Random` are injected; no test reads the wall clock, and the study
  tests shuffle with a seeded `Random`.
- The schema does not change: no migration, no new CHECK (BE-D1 comes first).
  After every study scenario `expectStudyInvariants` runs every invariant query
  of `schema.md` and checks that at most one session is `in_progress` (D2).
- Drift writes that a watch must see go through the typed API or
  `customInsert` / `customUpdate` with `updates:`.
- Generated code (`*.g.dart`) is not committed. After adding a `@riverpod`
  provider (Tasks 3 and 5), run `dart run build_runner build --delete-conflicting-outputs`.
- After every task the phased gate of the root `README.md` passes, plus
  `tools/docs/check.py`. On Linux, `flutter test` runs with
  `--exclude-tags golden`: the goldens were made on Windows (FE-D1 in
  [`docs/wbs_FE.md`](../../wbs_FE.md)).
- The guard warns at 400 logical lines of a file and fails at 500: keep each
  file under the warning.
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- No BR file changes, and the use case files change in their `code:` field only
  (Task 9). BR-SETTINGS-008 is not touched.
- Code, identifiers, test names and commit messages are in English; `docs/` keeps
  its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code showed where the spec needed a change. Each is
decided here, implemented as described, and written into the spec in
`dc78e5c`; say so if one is wrong.

1. **`SrsRejection` keeps its five values** (Task 1; spec §4, §6.2, §6.3, §6.5,
   §7.3). `lib/features/deck/presentation/widgets/support/srs_rejection_message_widget.dart`
   switches over the enum with no default, so a new value breaks the UI's build,
   and this package does not touch presentation. The two cases the spec named
   are bugs a session never asks for: a `scheduled` turn on a card still learning
   and completing a learned card. The scheduler throws `ArgumentError`, the
   transaction rolls back, and the caller gets `UnknownDatabaseFailure` (E3).
2. **Two study repositories** (Tasks 3–9; spec §8.4, §13).
   `StudyEntryRepository(db, SettingsRepository, {now, random})` opens sessions
   and watches the Study Entry; `StudySessionRepository(db, ScheduleRepository,
   CardRepository, {now, random})` answers, leaves, continues, fails and watches
   the session. One implementation would pass the guard's 400-line warning, and
   the two halves depend on different features. The use cases of §8.3 keep their
   names and signatures; each takes the repository it calls, and `study/di/`
   has one provider per repository.
3. **The rules that need no row live in the domain** (Tasks 3–5, 9):
   `newCardsToLearn`, `learningQueues`, `reviewQueue` and `shuffledUnlike`
   (`queue_plan_model.dart`), `turnKindOf` (`turn_kind_model.dart`),
   `reviewModeOptions` (`study_entry_model.dart`) and
   `StudyRejection.ofModeRefusal` / `ofTurnRefusal` (`study_failure.dart`). The
   repositories read, call them and write. `reviewQueue` checks the request —
   the mode, then the direction — before the cards — due, then the stage; spec
   §7.1 names the checks without an order.
4. **No `study_session_entity.dart`** (Task 3; spec §4). `SessionStatus` and
   `SessionEndReason` are stored-code enums in
   `domain/models/session_status_model.dart`, like the other stored codes.
5. **`StudyCardFacts` holds `cardId` and `hasExample`** (Task 2; spec §5.3 also
   listed `back_folded`), and `distinctMeaningCount` is one SQL count over the
   distractor source, not stopped at five.
6. **A card that joins a next round sits at `position = -1`** until that round
   is built (Task 5; spec §7.3 step 5 said "the next free provisional
   position"). The served-row query skips such rows, and a round not built yet
   is listed by card id, so a seeded shuffle of it repeats. `schema.md` says so.
7. **`WatchStudyEntry` has no `switchMap`** (Task 9; spec §8.1, §15). The entry
   watches the rows it reads — `deck`, `card`, `card_schedule`, `app_settings`,
   `study_session`, `study_queue_items` — and on every emission reads the
   options through the one-shot `studyOptionsOf`, so a change of the options
   emits again, as the card list reads its counts. No stream helper is added.
8. **The study README's `depends_on` does not gain `settings`** (Task 9; spec
   §11). The settings README already declares `settings → study`, and the docs
   check refuses a cycle; `docs/README.md` lets the documentation graph differ
   from the import graph.
9. **The session view** (Task 8): `currentItem`, `progress` and `currentRound`
   are null while the session serves nothing — ended, or stalled — and `summary`
   is set once it has ended; `stages` comes with a `currentStageIndex` getter. A
   review mode option says `isDirectionRequired` (guard
   `boolean_reads_as_predicate`).
10. **`wbs_BE.md` gains BE-A10** (Task 9; spec §11), the mechanics of the four
    graded modes, so the rest of UC-STUDY-001 has a row of its own (package 2b).
    BE-A9 is taken: master gave it to the card list reads of the Library
    alignment (#34).
11. **The study fixtures** (Tasks 3, 5, 6): `studyEntryRepository` and
    `studySessionRepository` in `test/support/study_fixtures.dart` compose the
    real settings, srs and card repositories with a seeded `Random`;
    `studySessionRepository` takes a `ScheduleRepository` a test injects a fault
    into.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **A card deleted after it was served, then answered**: the answer is refused
   as `notCurrentCard` and writes nothing, and the next card is served — Task 7,
   "an answer on a card deleted after it was served".
2. **The last cards of a round deleted after a wrong answer**: the session is
   stalled on a round not built yet, and Continue builds it and serves it — Task
   7, "when the last cards of a round were deleted after a wrong answer".
3. **A session that crosses midnight**: it keeps taking answers; only Continue
   and the app start close a session of an earlier day (BR-STUDY-072) — Task 7,
   "a session keeps taking answers after midnight".
4. **A reset of the root while the session is open**: the view reports
   `invalidated`/`scheduler_reset` with its summary and serves no card, and an
   answer is `sessionClosed` — Task 8, "a reset of the root while the session is
   open". Writing this test found that an ended session still showed a card.
5. **A card edited during the session**: the view shows its new text and the
   queue keeps its order — Task 8, "a card edited during the session".

## File Structure

```
lib/features/srs/                                       (Task 1)
├── domain/models/{srs_scheduler, eight_box_scheduler, sm2_scheduler}.dart
├── domain/models/review_turn_model.dart                ReviewTurn
├── domain/repositories/schedule_repository.dart        recordTurn, completeLearning
└── data/{datasources/srs_dao, repositories/schedule_repository_impl}.dart

lib/features/study_mode/domain/                         new feature (Task 2)
├── models/study_mode.dart                              StudyMode, the dispatch, StudyModeHandler
├── models/{browse, self_assess, graded, match, guess, fill}_mode.dart
├── models/{session_kind, study_answer, stage_eligibility, row_step, question_direction}_model.dart
└── failures/study_mode_failure.dart                    StudyModeRejection

lib/features/settings/                                  studyOptionsOf (Task 3)

lib/features/study/                                     new feature (Tasks 3–9)
├── domain/
│   ├── failures/study_failure.dart                     StudyRejection (3, 5)
│   ├── models/session_status_model.dart                SessionStatus, SessionEndReason (3)
│   ├── models/queue_plan_model.dart                    StageQueue, newCardsToLearn, learningQueues,
│   │                                                   shuffledUnlike (3), reviewQueue (4)
│   ├── models/turn_kind_model.dart                     turnKindOf (5)
│   ├── models/study_session_view_model.dart            StudySessionView (8)
│   ├── models/study_entry_model.dart                   StudyEntry, reviewModeOptions (9)
│   ├── repositories/study_entry_repository.dart        (3, 4, 9)
│   ├── repositories/study_session_repository.dart      (5–8)
│   └── usecases/                                       eight use cases (3–9)
├── data/
│   ├── datasources/study_session_dao.dart              session rows, card choice (3–5, 7, 9)
│   ├── datasources/study_queue_dao.dart                queue rows (3–5)
│   ├── datasources/study_view_dao.dart                 the screens' reads (8, 9)
│   ├── mappers/study_session_view_mapper.dart          (8)
│   ├── repositories/study_entry_repository_impl.dart   (3, 4, 9)
│   └── repositories/study_session_repository_impl.dart (5–8)
└── di/{study_entry, study_session}_repository_provider.dart   (3, 5)

test/support/study_fixtures.dart                        (3, 5, 6)
```

Other changed files: `boundary_rules.dart` (2, 3), `card_fixtures.dart` (3); the
docs `schema.md` (3, 5), `features/study/data.md` (7), the study and study-mode
READMEs, UC-STUDY-001, UC-STUDY-003 and `wbs_BE.md` (9).

---


### Task 1: srs records study turns and learning completion, and filters the Trash

**Files:**
- Create: `lib/features/srs/domain/models/review_turn_model.dart`
- Modify: `lib/features/srs/data/datasources/srs_dao.dart`, `lib/features/srs/data/repositories/schedule_repository_impl.dart`, `lib/features/srs/domain/models/eight_box_scheduler.dart`, `lib/features/srs/domain/models/sm2_scheduler.dart`, `lib/features/srs/domain/models/srs_scheduler.dart`, `lib/features/srs/domain/repositories/schedule_repository.dart`
- Test (create): `test/features/srs/data/record_turn_test.dart`
- Test (modify): `test/features/srs/data/reset_learning_test.dart`, `test/features/srs/data/schedule_repository_impl_test.dart`, `test/features/srs/domain/eight_box_scheduler_test.dart`, `test/features/srs/domain/reset_learning_use_cases_test.dart`, `test/features/srs/domain/sm2_scheduler_test.dart`, `test/integration/foundation_smoke_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `CardScheduleState` and `copyWith`, `ReviewLogEntry`,
  `ReviewKind.{learning, scheduled, relearning}`, `EightBoxAction`, `Sm2Action`,
  `SchedulerType`, `dueAtLocalMidnight` (`srs/domain/models/`); `SrsDao`,
  `ScheduleRepositoryImpl(AppDatabase db, {DateTime Function()? now})`.
- Produces:
  - On `SrsScheduler`: `bool isLapse(Object action)`;
    `next(state, action, now)` for a `scheduled` turn on a learned card only
    (`ArgumentError` otherwise); `CardScheduleState learned(CardScheduleState state, DateTime now)`
    (`ArgumentError` on a learned card).
  - `final class ReviewTurn({required String cardId, required String sessionId, required int generation, required ReviewKind kind, required String modeCode, required Object action, required DateTime answeredAt, String? directionCode})`
    in `srs/domain/models/review_turn_model.dart`.
  - On `ScheduleRepository`: `Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn)`
    and `Future<Outcome<void, SrsRejection>> completeLearning({required String cardId, required int generation, DateTime? now})`;
    `recordReview` is gone.
  - `SrsDao.rootOfCard` is null for a card or deck in the Trash (BE-C3);
    `SrsDao.sessionRow` is gone.

Spec §6 and D6, D13; Clarification 1. Only a `scheduled` turn moves the
schedule; a `learning` or `relearning` turn stamps `last_answered_at` and logs
before = after (BR-SRS-016…BR-SRS-018). A card that finishes learning starts at
the lowest level, due at the next local midnight, and the first one of a
generation locks the scheduler (BR-STUDY-053, BR-SRS-003). The existing srs
tests move from `recordReview` to these two calls.

- [ ] **Step 1: Write the failing tests**

Create `test/features/srs/data/record_turn_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';

import '../../../support/srs_fixtures.dart';
import '../../../support/test_database.dart';

// The two writes a study session makes on srs: one turn, and the end of a
// card's learning (UC-STUDY-001 steps 7–11).

Matcher _refusedWith(SrsRejection reason) => isA<Rejected<void, SrsRejection>>()
    .having((rejected) => rejected.reason, 'reason', reason);

Future<List<QueryRow>> _logs(AppDatabase db) =>
    db.customSelect('SELECT * FROM review_log ORDER BY answered_at').get();

void main() {
  late AppDatabase db;
  late ScheduleRepositoryImpl repo;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    repo = ScheduleRepositoryImpl(db, now: () => now);
  });
  tearDown(() => db.close());

  ReviewTurn turn(
    String cardId, {
    ReviewKind kind = ReviewKind.learning,
    Object action = EightBoxAction.remembered,
    int generation = 1,
    String? direction,
    DateTime? at,
  }) => ReviewTurn(
    cardId: cardId,
    sessionId: 'r-session',
    generation: generation,
    kind: kind,
    modeCode: 'recall',
    action: action,
    directionCode: direction,
    answeredAt: at ?? now,
  );

  test('a learning turn is logged and changes nothing but last_answered_at '
      '(BR-STUDY-053, BR-SRS-018)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    expect(await repo.recordTurn(turn(cardId)), isA<Ok<void, SrsRejection>>());

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.data['learned_at'], isNull);
    expect(schedule.data['due_at'], isNull);
    expect(schedule.read<DateTime>('last_answered_at'), now);
    expect(schedule.read<int>('current_box'), 1);
    expect(schedule.read<int>('answer_count'), 0);
    final [log] = await _logs(db);
    expect(log.read<String>('kind'), 'learning');
    expect(log.read<String>('mode'), 'recall');
    expect(log.read<String>('action'), 'remembered');
    expect(log.read<String>('session_id'), 'r-session');
    expect(log.read<String>('scheduler_type'), 'eight_box');
    expect(log.read<int>('generation'), 1);
    expect((log.read<int>('previous_box'), log.read<int>('next_box')), (1, 1));
    expect(log.data['next_due_at'], isNull);
  });

  test('a relearning turn keeps the whole schedule (BR-SRS-017, '
      'invariant 14)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final later = now.add(const Duration(minutes: 5));

    await repo.recordTurn(
      turn(
        cardId,
        kind: ReviewKind.relearning,
        action: EightBoxAction.forgotten,
        at: later,
      ),
    );

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<DateTime>('due_at'), dueAtLocalMidnight(now, 1));
    expect(schedule.read<int>('current_box'), 1);
    expect(schedule.read<DateTime>('last_answered_at'), later);
    expect(
      (schedule.read<int>('answer_count'), schedule.read<int>('lapse_count')),
      (0, 0),
    );
    final [log] = await _logs(db);
    expect(log.read<String>('kind'), 'relearning');
    expect((log.read<int>('previous_box'), log.read<int>('next_box')), (1, 1));
    expect(log.read<DateTime>('next_due_at'), dueAtLocalMidnight(now, 1));
  });

  test('a scheduled turn runs the scheduler and logs the values before and '
      'after (BR-SRS-016, BR-SRS-019)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final nextDay = DateTime(2026, 9, 25, 7);

    await repo.recordTurn(
      turn(cardId, kind: ReviewKind.scheduled, at: nextDay),
    );

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<int>('current_box'), 2);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 27));
    expect(schedule.read<int>('answer_count'), 1);
    final [log] = await _logs(db);
    expect(log.read<String>('kind'), 'scheduled');
    expect((log.read<int>('previous_box'), log.read<int>('next_box')), (1, 2));
    expect(log.read<DateTime>('next_due_at'), DateTime(2026, 9, 27));
  });

  test('a turn keeps the direction it is given (BR-MODE-016)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r', scheduler: 'sm2');

    await repo.recordTurn(
      turn(cardId, action: Sm2Action.good, direction: 'meaning_to_korean'),
    );

    final [log] = await _logs(db);
    expect(log.read<String>('direction'), 'meaning_to_korean');
  });

  test('a scheduled turn on a card still learning is a bug that writes '
      'nothing (BR-STUDY-058, invariant 25)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    await expectLater(
      repo.recordTurn(turn(cardId, kind: ReviewKind.scheduled)),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(await totalChanges(db), before);
  });

  test('an action the root scheduler does not support is refused and '
      'writes nothing (BR-STUDY-009)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    final before = await totalChanges(db);

    expect(
      await repo.recordTurn(turn(cardId, action: Sm2Action.good)),
      _refusedWith(SrsRejection.unsupportedAction),
    );
    expect(await totalChanges(db), before);
  });

  test('a turn of an older generation is refused and writes nothing '
      '(BR-SRS-026)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.resetLearning(rootDeckId: rootId);
    final before = await totalChanges(db);

    expect(
      await repo.recordTurn(turn(cardId)),
      _refusedWith(SrsRejection.staleGeneration),
    );
    expect(
      await repo.completeLearning(cardId: cardId, generation: 1),
      _refusedWith(SrsRejection.staleGeneration),
    );
    expect(await totalChanges(db), before);
  });

  test(
    'a card deleted mid-session is notFound and nothing is written',
    () async {
      final (_, cardId, _) = await insertStudyTree(db, 'r');
      await db.customStatement('DELETE FROM card WHERE id = ?', [cardId]);
      final before = await totalChanges(db);

      expect(
        await repo.recordTurn(turn(cardId)),
        _refusedWith(SrsRejection.notFound),
      );
      expect(
        await repo.completeLearning(cardId: cardId, generation: 1),
        _refusedWith(SrsRejection.notFound),
      );
      expect(await totalChanges(db), before);
    },
  );

  test('a card in the Trash is notFound: the study flow never writes it '
      '(BE-C3)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE card SET delete_batch_id = 'b' WHERE id = ?",
      [cardId],
    );
    final before = await totalChanges(db);

    expect(
      await repo.recordTurn(turn(cardId)),
      _refusedWith(SrsRejection.notFound),
    );
    expect(
      await repo.completeLearning(cardId: cardId, generation: 1),
      _refusedWith(SrsRejection.notFound),
    );
    expect(await totalChanges(db), before);
  });

  test('a card whose deck is in the Trash is notFound (BE-C3)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = 'r-leaf'",
    );

    expect(
      await repo.recordTurn(turn(cardId)),
      _refusedWith(SrsRejection.notFound),
    );
  });

  test('completing learning starts the schedule at box 1, due at the next '
      'local midnight, with no review_log row (BR-STUDY-053)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');

    expect(
      await repo.completeLearning(cardId: cardId, generation: 1),
      isA<Ok<void, SrsRejection>>(),
    );

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<DateTime>('learned_at'), now);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect(schedule.read<int>('current_box'), 1);
    expect(schedule.read<int>('answer_count'), 0);
    expect(await _logs(db), isEmpty);
  });

  test('completing learning of an sm2 card starts interval 1 with one '
      'repetition (spec D6)', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r', scheduler: 'sm2');

    await repo.completeLearning(cardId: cardId, generation: 1);

    final schedule = await scheduleRowOf(db, cardId);
    expect(schedule.read<int>('interval_days'), 1);
    expect(schedule.read<int>('repetitions'), 1);
    expect(schedule.read<double>('ease_factor'), 2.5);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 25));
  });

  test('the first completion locks the scheduler and a later one keeps its '
      'mark (BR-SRS-003)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);
    final later = now.add(const Duration(hours: 1));

    await repo.completeLearning(cardId: cardId, generation: 1);
    await repo.completeLearning(cardId: deepCardId, generation: 1, now: later);

    final root = await deckRowOf(db, rootId);
    expect(root.read<DateTime>('first_answered_at'), now);
    expect(
      (await scheduleRowOf(db, deepCardId)).read<DateTime>('learned_at'),
      later,
    );
  });

  test('completing learning of a learned card is a bug that writes '
      'nothing', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final before = await totalChanges(db);

    await expectLater(
      repo.completeLearning(cardId: cardId, generation: 1),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(await totalChanges(db), before);
  });

  test('a turn reaches the card through its own row only', () async {
    final (_, cardId, _) = await insertStudyTree(db, 'r');
    final (_, otherCardId, _) = await insertStudyTree(db, 'other');

    await repo.recordTurn(turn(cardId));

    final other = await scheduleRowOf(db, otherCardId);
    expect(other.data['last_answered_at'], isNull);
    final count = await db
        .customSelect(
          'SELECT COUNT(*) AS n FROM review_log WHERE card_id = ?',
          variables: [Variable(otherCardId)],
        )
        .getSingle();
    expect(count.read<int>('n'), 0);
  });
}
```

In `test/features/srs/data/reset_learning_test.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart

void main() {
```

with

```dart

/// A `remembered` answer of [sessionId] at generation 1.
ReviewTurn _turn(
  String cardId,
  String sessionId, {
  ReviewKind kind = ReviewKind.learning,
}) => ReviewTurn(
  cardId: cardId,
  sessionId: sessionId,
  generation: 1,
  kind: kind,
  modeCode: 'recall',
  action: EightBoxAction.remembered,
  answeredAt: DateTime(2026, 9, 24),
);

void main() {
```

Replace

```dart

  for (final (from, to, learn) in <(String, SchedulerType, Object)>[
    ('sm2', SchedulerType.eightBox, Sm2Action.good),
    ('eight_box', SchedulerType.sm2, EightBoxAction.remembered),
  ]) {
```

with

```dart

  for (final (from, to) in <(String, SchedulerType)>[
    ('sm2', SchedulerType.eightBox),
    ('eight_box', SchedulerType.sm2),
  ]) {
```

Replace

```dart
        'values (UC-SRS-001 steps 3 and 5)', () async {
      final (rootId, cardId, sessionId) = await insertStudyTree(
        db,
```

with

```dart
        'values (UC-SRS-001 steps 3 and 5)', () async {
      final (rootId, cardId, _) = await insertStudyTree(
        db,
```

Replace

```dart
      );
      await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: learn,
      );
      expect(
```

with

```dart
      );
      await repo.completeLearning(cardId: cardId, generation: 1);
      expect(
```

Replace

```dart
      '(UC-SRS-001 A1)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(
      db,
```

with

```dart
      '(UC-SRS-001 A1)', () async {
    final (rootId, cardId, _) = await insertStudyTree(
      db,
```

Replace

```dart
    );
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: Sm2Action.good,
    );

```

with

```dart
    );
    await repo.completeLearning(cardId: cardId, generation: 1);

```

Replace

```dart
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await repo.resetLearning(rootDeckId: rootId);
    final lateAnswer = await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

```

with

```dart
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordTurn(_turn(cardId, sessionId));

    await repo.resetLearning(rootDeckId: rootId);
    final lateAnswer = await repo.recordTurn(_turn(cardId, sessionId));

```

Replace

```dart
    final (rootId, cardId, sessionId) = await insertStudyTree(failing, 'r');
    await broken.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
```

with

```dart
    final (rootId, cardId, sessionId) = await insertStudyTree(failing, 'r');
    await broken.completeLearning(cardId: cardId, generation: 1);
    await broken.recordTurn(
      _turn(cardId, sessionId, kind: ReviewKind.scheduled),
    );
```

Replace

```dart
      ]) {
        await repo.recordReview(
          cardId: card,
          sessionId: session,
          action: EightBoxAction.remembered,
        );
      }
```

with

```dart
      ]) {
        await repo.completeLearning(cardId: card, generation: 1);
        await repo.recordTurn(_turn(card, session, kind: ReviewKind.scheduled));
      }
```

Replace

```dart
      'whole tree, outside the Trash (UC-SRS-001 step 2)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);
```

with

```dart
      'whole tree, outside the Trash (UC-SRS-001 step 2)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    final deepCardId = await insertDeepCard(db, rootId);
```

Replace

```dart
    for (final id in [cardId, deepCardId]) {
      await repo.recordReview(
        cardId: id,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
    }
```

with

```dart
    for (final id in [cardId, deepCardId]) {
      await repo.completeLearning(cardId: id, generation: 1);
    }
```

In `test/features/srs/data/schedule_repository_impl_test.dart`:

Replace

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
```

with

```dart
import 'package:flutter_test/flutter_test.dart';
```

Replace

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart

  test(
    'recordReview rejects an action the deck scheduler does not support',
    () async {
      final (_, cardId, sessionId) = await insertStudyTree(
        db,
        'r',
      ); // eight_box
      final result = await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: Sm2Action.good,
      );
      expect(
        (result as Rejected<void, SrsRejection>).reason,
        SrsRejection.unsupportedAction,
      );
    },
  );

  test(
    'recordReview writes card_schedule and an append-only review_log row',
    () async {
      final (_, cardId, sessionId) = await insertStudyTree(db, 'r');
      final result = await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
      expect(result, isA<Ok<void, SrsRejection>>());

      expect((await scheduleRowOf(db, cardId)).read<int>('current_box'), 2);
      final logCount = await db
          .customSelect(
            'SELECT COUNT(*) AS n FROM review_log WHERE card_id = ?',
            variables: [Variable(cardId)],
          )
          .getSingle();
      expect(logCount.read<int>('n'), 1);
    },
  );

  test('reviewing a card deleted mid-session returns notFound and writes no log row', () async {
    final (_, cardId, sessionId) = await insertStudyTree(db, 'r');
    await db.customStatement('DELETE FROM card WHERE id = ?', [cardId]);

    final result = await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
    expect(
      (result as Rejected<void, SrsRejection>).reason,
      SrsRejection.notFound,
    );
    final logCount = await db
        .customSelect('SELECT COUNT(*) AS n FROM review_log')
        .getSingle();
    expect(logCount.read<int>('n'), 0);
  });

  test(
    'a review from a stale-generation session is rejected, not applied',
    () async {
      final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
      await repo.resetLearning(rootDeckId: rootId); // bumps generation to 2

      final result = await repo.recordReview(
        cardId: cardId,
        sessionId: sessionId,
        action: EightBoxAction.remembered,
      );
      expect(
        (result as Rejected<void, SrsRejection>).reason,
        SrsRejection.staleGeneration,
      );
    },
  );

  test('resetLearning bumps generation and recreates card_schedule', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

```

with

```dart

  test('resetLearning bumps generation and recreates card_schedule', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);

```

Replace

```dart
  test('resetLearning of an sm2 tree writes sm2 start values', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(
      db,
```

with

```dart
  test('resetLearning of an sm2 tree writes sm2 start values', () async {
    final (rootId, cardId, _) = await insertStudyTree(
      db,
```

Replace

```dart
    );
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: Sm2Action.good,
    );

```

with

```dart
    );
    await repo.completeLearning(cardId: cardId, generation: 1);

```

Replace

```dart
  test('resetLearning unlocks the scheduler and closes the open sessions (BR-SRS-024, BR-STUDY-015)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );

    await repo.resetLearning(rootDeckId: rootId);
```

with

```dart
  test('resetLearning unlocks the scheduler and closes the open sessions (BR-SRS-024, BR-STUDY-015)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);

    await repo.resetLearning(rootDeckId: rootId);
```

Replace

```dart
  test('the scheduler the root runs is a no-op on a locked tree too, not a rejection', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
    final before = await totalChanges(db);
```

with

```dart
  test('the scheduler the root runs is a no-op on a locked tree too, not a rejection', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final before = await totalChanges(db);
```

Replace

```dart

  test('changeScheduler after the first review is rejected (locked)', () async {
    final (rootId, cardId, sessionId) = await insertStudyTree(db, 'r');
    await repo.recordReview(
      cardId: cardId,
      sessionId: sessionId,
      action: EightBoxAction.remembered,
    );
    final before = await totalChanges(db);
```

with

```dart

  test('changeScheduler once a card finished learning is rejected (locked, '
      'BR-SRS-003)', () async {
    final (rootId, cardId, _) = await insertStudyTree(db, 'r');
    await repo.completeLearning(cardId: cardId, generation: 1);
    final before = await totalChanges(db);
```

Replace the whole of `test/features/srs/domain/eight_box_scheduler_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/eight_box_scheduler.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';

final _now = DateTime(2026, 9, 23, 8);

CardScheduleState _newCard() =>
    CardScheduleState.initial(SchedulerType.eightBox, generation: 1);

CardScheduleState _learnedIn(int box) => _newCard().copyWith(
  learnedAt: _now,
  currentBox: box,
  dueAt: dueAtLocalMidnight(_now, 1),
);

void main() {
  test('supportedActions is exactly forgotten and remembered', () {
    expect(eightBoxScheduler.supportedActions, {
      EightBoxAction.forgotten,
      EightBoxAction.remembered,
    });
  });

  test('forgotten is the one lapse (BR-SRS-018)', () {
    expect(eightBoxScheduler.isLapse(EightBoxAction.forgotten), isTrue);
    expect(eightBoxScheduler.isLapse(EightBoxAction.remembered), isFalse);
  });

  test('a card that finishes learning starts in box 1, due at the next '
      'local midnight (BR-STUDY-053, BR-STUDY-074)', () {
    final learned = eightBoxScheduler.learned(_newCard(), _now);

    expect(learned.learnedAt, _now);
    expect(learned.currentBox, 1);
    expect(learned.dueAt, DateTime(2026, 9, 24));
    expect(learned.lastAnsweredAt, isNull);
    expect((learned.answerCount, learned.lapseCount), (0, 0));
  });

  test('learning a card that is already learned is a programming error', () {
    expect(
      () => eightBoxScheduler.learned(_learnedIn(3), _now),
      throwsArgumentError,
    );
  });

  for (final (box, target, days) in [
    (1, 2, 2),
    (2, 3, 4),
    (3, 4, 8),
    (4, 5, 16),
    (5, 6, 32),
    (6, 7, 64),
    (7, 8, 128),
    (8, 8, 128),
  ]) {
    test('remembered in box $box moves to box $target, due in $days days '
        '(BR-SRS-008, BR-SRS-009)', () {
      final (state, log) = eightBoxScheduler.next(
        _learnedIn(box),
        EightBoxAction.remembered,
        _now,
      );

      expect(state.currentBox, target);
      expect(state.dueAt, dueAtLocalMidnight(_now, days));
      expect(log.kind, ReviewKind.scheduled);
      expect((log.previousBox, log.nextBox), (box, target));
      expect(log.nextDueAt, state.dueAt);
    });
  }

  test('forgotten sends a learned card back to box 1, due the next day '
      '(BR-SRS-008)', () {
    final (state, log) = eightBoxScheduler.next(
      _learnedIn(5),
      EightBoxAction.forgotten,
      _now,
    );

    expect(state.currentBox, 1);
    expect(state.dueAt, dueAtLocalMidnight(_now, 1));
    expect((log.previousBox, log.nextBox), (5, 1));
  });

  test('a scheduled turn stamps lastAnsweredAt, counts the answer, and '
      'counts a lapse on forgotten only (BR-SRS-018)', () {
    final answeredAt = _now.add(const Duration(days: 3));
    final (remembered, _) = eightBoxScheduler.next(
      _learnedIn(3),
      EightBoxAction.remembered,
      answeredAt,
    );
    final (forgotten, _) = eightBoxScheduler.next(
      _learnedIn(3),
      EightBoxAction.forgotten,
      answeredAt,
    );

    expect(remembered.lastAnsweredAt, answeredAt);
    expect((remembered.answerCount, remembered.lapseCount), (1, 0));
    expect((forgotten.answerCount, forgotten.lapseCount), (1, 1));
  });

  test('a scheduled turn on a card still learning is a programming error '
      '(BR-STUDY-058)', () {
    expect(
      () => eightBoxScheduler.next(_newCard(), EightBoxAction.remembered, _now),
      throwsArgumentError,
    );
  });

  test('an action of another scheduler is refused', () {
    expect(
      () => eightBoxScheduler.next(_learnedIn(1), 'good', _now),
      throwsArgumentError,
    );
  });
}
```

In `test/features/srs/domain/reset_learning_use_cases_test.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart
    );
    await schedules.recordReview(
      cardId: 'c',
      sessionId: 's',
      action: EightBoxAction.remembered,
    );
  });
```

with

```dart
    );
    await schedules.completeLearning(cardId: 'c', generation: 1);
  });
```

Replace the whole of `test/features/srs/domain/sm2_scheduler_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/card_schedule_state_model.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/sm2_scheduler.dart';

final _now = DateTime(2026, 9, 23, 8);

CardScheduleState _newCard() =>
    CardScheduleState.initial(SchedulerType.sm2, generation: 1);

CardScheduleState _learned({
  double ease = 2.5,
  int interval = 1,
  int repetitions = 1,
}) => _newCard().copyWith(
  learnedAt: _now,
  dueAt: dueAtLocalMidnight(_now, interval),
  easeFactor: ease,
  intervalDays: interval,
  repetitions: repetitions,
);

void main() {
  test('supportedActions is again/hard/good/easy', () {
    expect(sm2Scheduler.supportedActions, {
      Sm2Action.again,
      Sm2Action.hard,
      Sm2Action.good,
      Sm2Action.easy,
    });
  });

  test('again is the one lapse (BR-SRS-018)', () {
    expect(sm2Scheduler.isLapse(Sm2Action.again), isTrue);
    for (final action in [Sm2Action.hard, Sm2Action.good, Sm2Action.easy]) {
      expect(sm2Scheduler.isLapse(action), isFalse);
    }
  });

  test('a card that finishes learning starts at interval 1 with one '
      'repetition, due at the next local midnight, ease untouched '
      '(BR-STUDY-053; spec D6)', () {
    final learned = sm2Scheduler.learned(_newCard(), _now);

    expect(learned.learnedAt, _now);
    expect((learned.intervalDays, learned.repetitions), (1, 1));
    expect(learned.easeFactor, 2.5);
    expect(learned.dueAt, DateTime(2026, 9, 24));
    expect((learned.answerCount, learned.lapseCount), (0, 0));
  });

  test('learning a card that is already learned is a programming error', () {
    expect(() => sm2Scheduler.learned(_learned(), _now), throwsArgumentError);
  });

  for (final (action, ease) in [
    (Sm2Action.again, 1.7),
    (Sm2Action.hard, 2.36),
    (Sm2Action.good, 2.5),
    (Sm2Action.easy, 2.6),
  ]) {
    test('${action.name} takes the ease from 2.5 to $ease: q is 0, 3, 4, 5 '
        '(BR-SRS-010, BR-SRS-012)', () {
      final (state, log) = sm2Scheduler.next(_learned(), action, _now);

      expect(state.easeFactor, closeTo(ease, 1e-9));
      expect(log.previousEaseFactor, 2.5);
      expect(log.nextEaseFactor, state.easeFactor);
    });
  }

  test('the ease never falls under 1.3 (BR-SRS-012)', () {
    final (state, _) = sm2Scheduler.next(
      _learned(ease: 1.4),
      Sm2Action.again,
      _now,
    );

    expect(state.easeFactor, 1.3);
  });

  test('again starts the repetitions over at interval 1, due the next day '
      '(BR-SRS-011)', () {
    final (state, log) = sm2Scheduler.next(
      _learned(interval: 15, repetitions: 3),
      Sm2Action.again,
      _now,
    );

    expect((state.intervalDays, state.repetitions), (1, 0));
    expect(state.dueAt, dueAtLocalMidnight(_now, 1));
    expect(log.kind, ReviewKind.scheduled);
    expect((log.previousIntervalDays, log.nextIntervalDays), (15, 1));
  });

  test('good climbs the ladder from the learned start: 6 days, then the '
      'interval times the ease (BR-SRS-011)', () {
    final (second, log) = sm2Scheduler.next(_learned(), Sm2Action.good, _now);
    final (third, _) = sm2Scheduler.next(second, Sm2Action.good, _now);

    expect((second.intervalDays, second.repetitions), (6, 2));
    expect(second.dueAt, dueAtLocalMidnight(_now, 6));
    expect(log.nextDueAt, second.dueAt);
    expect((third.intervalDays, third.repetitions), (15, 3));
  });

  test('the interval is multiplied by the ease this turn produced: hard at '
      'interval 10 gives 24 days, not 25 (BR-SRS-011)', () {
    final (state, _) = sm2Scheduler.next(
      _learned(interval: 10, repetitions: 3),
      Sm2Action.hard,
      _now,
    );

    expect(state.intervalDays, 24);
    expect(state.dueAt, dueAtLocalMidnight(_now, 24));
  });

  test('a scheduled turn stamps lastAnsweredAt, counts the answer, and '
      'counts a lapse on again only (BR-SRS-018)', () {
    final answeredAt = _now.add(const Duration(days: 6));
    final (good, _) = sm2Scheduler.next(_learned(), Sm2Action.good, answeredAt);
    final (again, _) = sm2Scheduler.next(
      _learned(),
      Sm2Action.again,
      answeredAt,
    );

    expect(good.lastAnsweredAt, answeredAt);
    expect((good.answerCount, good.lapseCount), (1, 0));
    expect((again.answerCount, again.lapseCount), (1, 1));
  });

  test('a scheduled turn on a card still learning is a programming error '
      '(BR-STUDY-058)', () {
    expect(
      () => sm2Scheduler.next(_newCard(), Sm2Action.good, _now),
      throwsArgumentError,
    );
  });

  test('an action of another scheduler is refused', () {
    expect(
      () => sm2Scheduler.next(_learned(), 'remembered', _now),
      throwsArgumentError,
    );
  });
}
```

Replace the whole of `test/integration/foundation_smoke_test.dart` with:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/entities/card_entity.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/card/domain/models/card_draft_model.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../support/invariant_queries.dart';
import '../support/test_database.dart';

void main() {
  test('deck -> tagged card -> learned, then reviewed -> reset leaves a '
      'consistent database', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    final now = DateTime(2026, 9, 23);
    final decks = DeckRepositoryImpl(db, now: () => now);
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );

    final root = ((await decks.createRootDeck(
      name: 'Korean',
      schedulerType: SchedulerType.eightBox,
    )) as Ok<DeckEntity, DeckRejection>).value;
    final leaf = ((await decks.createSubDeck(
      parentId: root.id,
      name: 'Nouns',
    )) as Ok<DeckEntity, DeckRejection>).value;
    final card = ((await cards.createCard(
      deckId: leaf.id,
      draft: const CardDraft(front: '사과', back: 'apple', tagNames: ['fruit']),
    )) as Ok<CardEntity, CardRejection>).value;

    // A learning session finishes the card, then a review session answers
    // it on schedule (BR-STUDY-051, BR-STUDY-053).
    Future<void> openSession(String id, String kind, String mode) =>
        db.customStatement(
          'INSERT INTO study_session (id, deck_id, root_id, generation, '
          'session_kind, current_mode, status, cursor, card_limit, '
          "started_at) VALUES (?, ?, ?, 1, ?, ?, 'in_progress', 0, 20, 0)",
          [id, leaf.id, root.id, kind, mode],
        );
    ReviewTurn turn(String sessionId, ReviewKind kind) => ReviewTurn(
      cardId: card.id,
      sessionId: sessionId,
      generation: 1,
      kind: kind,
      modeCode: 'recall',
      action: EightBoxAction.remembered,
      answeredAt: now,
    );

    await openSession('learn', 'learning', 'recall');
    expect(
      await schedules.recordTurn(turn('learn', ReviewKind.learning)),
      isA<Ok<void, SrsRejection>>(),
    );
    expect(
      await schedules.completeLearning(cardId: card.id, generation: 1),
      isA<Ok<void, SrsRejection>>(),
    );
    await db.customStatement(
      "UPDATE study_session SET status = 'completed', ended_at = 0 "
      "WHERE id = 'learn'",
    );
    await openSession('review', 'reviewing', 'recall');
    expect(
      await schedules.recordTurn(turn('review', ReviewKind.scheduled)),
      isA<Ok<void, SrsRejection>>(),
    );
    expect(
      await schedules.resetLearning(rootDeckId: root.id),
      isA<Ok<void, SrsRejection>>(),
    );

    // A reset keeps the review log (BR-SRS-023).
    final logs = await db
        .customSelect('SELECT generation FROM review_log')
        .get();
    expect([for (final log in logs) log.read<int>('generation')], [1, 1]);

    // Every invariant query of schema.md still returns no row, 25 included:
    // it weighs only the turns of the card's current generation.
    for (final MapEntry(key: number, value: query)
        in invariantQueries.entries) {
      final rows = await db.customSelect(query).get();
      expect(
        rows,
        isEmpty,
        reason: 'invariant $number: ${invariantSummaries[number]}',
      );
    }
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/srs/data/record_turn_test.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/srs/domain/eight_box_scheduler_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart \
  test/features/srs/domain/sm2_scheduler_test.dart \
  test/integration/foundation_smoke_test.dart
```

Expected: `+0 -7: Some tests failed.` None of the changed files compiles. The first errors: `Error: The method 'completeLearning' isn't defined for the type 'ScheduleRepositoryImpl'.`, `Error: The method 'recordTurn' isn't defined for the type 'ScheduleRepositoryImpl'.`, `Error: Error when reading 'lib/features/srs/domain/models/review_turn_model.dart': No such file or directory`

- [ ] **Step 3: Follow BR-SRS-008…BR-SRS-012 in the schedulers**

In `lib/features/srs/domain/models/eight_box_scheduler.dart`:

Replace

```dart
};
const _lastBox = 8;

typedef _Step = (CardScheduleState, ReviewLogEntry);

/// The `eight_box` scheduler (BR-SRS-008, BR-SRS-009). Which answers change
/// the schedule, and how they are counted, follows this plan's kind model;
/// Clarification 15 of the foundation plan records where it differs from the
/// study rules.
final class EightBoxScheduler implements SrsScheduler {
```

with

```dart
};
const _firstBox = 1;
const _lastBox = 8;

/// The `eight_box` scheduler (BR-SRS-008, BR-SRS-009).
final class EightBoxScheduler implements SrsScheduler {
```

Replace

```dart
  @override
  (CardScheduleState, ReviewLogEntry) next(
```

with

```dart
  @override
  bool isLapse(Object action) => action == EightBoxAction.forgotten;

  /// `forgotten` goes back to box 1 and `remembered` one box up, box 8
  /// staying 8; the card is due at local midnight of the target box's
  /// interval (BR-SRS-008, BR-SRS-009, BR-STUDY-074).
  @override
  (CardScheduleState, ReviewLogEntry) next(
```

Replace

```dart
    }
    final box = state.currentBox;
    if (box == null) {
      throw ArgumentError.value(state, 'state', 'not an eight_box state');
    }
    final answered = state.copyWith(lastAnsweredAt: now);
    if (state.learnedAt == null) return _learning(answered, action, box, now);
    return switch (action) {
      EightBoxAction.remembered => _scheduled(answered, box, now),
      EightBoxAction.forgotten => _relearning(answered, box),
    };
  }

  /// Before the card is learned: `remembered` learns it and moves it up one
  /// box, `forgotten` leaves it where it is. No due date either way.
  _Step _learning(
    CardScheduleState state,
    EightBoxAction action,
    int box,
    DateTime now,
  ) {
    if (action == EightBoxAction.forgotten) {
      return (
        state,
        ReviewLogEntry(
          kind: ReviewKind.learning,
          previousBox: box,
          nextBox: box,
        ),
      );
    }
    final nextBox = _promoted(box);
    return (
      state.copyWith(learnedAt: now, currentBox: nextBox),
      ReviewLogEntry(
        kind: ReviewKind.learning,
        previousBox: box,
        nextBox: nextBox,
      ),
    );
  }

  /// A learned card remembered: one box up (box 8 stays 8) and due at local
  /// midnight of the box's interval (BR-SRS-009, BR-STUDY-074).
  _Step _scheduled(CardScheduleState state, int box, DateTime now) {
    final nextBox = _promoted(box);
    final dueAt = dueAtLocalMidnight(now, _intervalDaysByBox[nextBox]!);
    return (
      state.copyWith(
        currentBox: nextBox,
        dueAt: dueAt,
        answerCount: state.answerCount + 1,
      ),
```

with

```dart
    }
    final box = _boxOf(state);
    if (state.learnedAt == null) {
      throw ArgumentError.value(state, 'state', 'a card still learning');
    }
    final target = switch (action) {
      EightBoxAction.forgotten => _firstBox,
      EightBoxAction.remembered => box == _lastBox ? _lastBox : box + 1,
    };
    final dueAt = dueAtLocalMidnight(now, _intervalDaysByBox[target]!);
    final lapses = isLapse(action) ? 1 : 0;
    return (
      state.copyWith(
        currentBox: target,
        dueAt: dueAt,
        lastAnsweredAt: now,
        answerCount: state.answerCount + 1,
        lapseCount: state.lapseCount + lapses,
      ),
```

Replace

```dart
        previousBox: box,
        nextBox: nextBox,
        nextDueAt: dueAt,
```

with

```dart
        previousBox: box,
        nextBox: target,
        nextDueAt: dueAt,
```

Replace

```dart

  /// A learned card forgotten: box and due date unchanged (BR-SRS-017),
  /// one more lapse.
  _Step _relearning(CardScheduleState state, int box) => (
    state.copyWith(lapseCount: state.lapseCount + 1),
    ReviewLogEntry(
      kind: ReviewKind.relearning,
      previousBox: box,
      nextBox: box,
      nextDueAt: state.dueAt,
    ),
  );

  int _promoted(int box) => box == _lastBox ? _lastBox : box + 1;
}
```

with

```dart

  /// Box 1, due the next local day (BR-STUDY-053).
  @override
  CardScheduleState learned(CardScheduleState state, DateTime now) {
    _boxOf(state);
    if (state.learnedAt != null) {
      throw ArgumentError.value(state, 'state', 'a card already learned');
    }
    return state.copyWith(
      learnedAt: now,
      currentBox: _firstBox,
      dueAt: dueAtLocalMidnight(now, _intervalDaysByBox[_firstBox]!),
    );
  }

  int _boxOf(CardScheduleState state) {
    final box = state.currentBox;
    if (box == null) {
      throw ArgumentError.value(state, 'state', 'not an eight_box state');
    }
    return box;
  }
}
```

In `lib/features/srs/domain/models/sm2_scheduler.dart`:

Replace

```dart

/// SM-2's quality `q` of each action, as this plan maps it (Clarification 15
/// of the foundation plan records BR-SRS-010's mapping).
const _qualityOf = {
  Sm2Action.again: 2,
  Sm2Action.hard: 3,
```

with

```dart

/// SM-2's quality `q` of each action (BR-SRS-010).
const _qualityOf = {
  Sm2Action.again: 0,
  Sm2Action.hard: 3,
```

Replace

```dart
const _perfectQuality = 5;
const _minEase = 1.3;
```

with

```dart
const _perfectQuality = 5;
const _passingQuality = 3;
const _minEase = 1.3;
```

Replace

```dart

typedef _Step = (CardScheduleState, ReviewLogEntry);

/// The `sm2` scheduler: classic SM-2 with a 1.3 ease floor.
final class Sm2Scheduler implements SrsScheduler {
```

with

```dart

/// The `sm2` scheduler: classic SM-2 with a 1.3 ease floor (BR-SRS-010,
/// BR-SRS-011, BR-SRS-012).
final class Sm2Scheduler implements SrsScheduler {
```

Replace

```dart
  @override
  (CardScheduleState, ReviewLogEntry) next(
```

with

```dart
  @override
  bool isLapse(Object action) => action == Sm2Action.again;

  /// The ease first, from this turn's `q`; then `q < 3` starts the
  /// repetitions over at 1 day, and a pass goes 1 day, 6 days, then the
  /// interval times the new ease (BR-SRS-011). Due at local midnight
  /// (BR-STUDY-074).
  @override
  (CardScheduleState, ReviewLogEntry) next(
```

Replace

```dart
    }
    final ease = state.easeFactor;
    final interval = state.intervalDays;
    final repetitions = state.repetitions;
    if (ease == null || interval == null || repetitions == null) {
      throw ArgumentError.value(state, 'state', 'not an sm2 state');
    }
    final answered = state.copyWith(lastAnsweredAt: now);
    if (state.learnedAt == null) {
      return _learning(answered, action, ease, interval, now);
    }
    if (action == Sm2Action.again) return _relearning(answered, ease, interval);
    return _scheduled(answered, action, ease, interval, repetitions, now);
  }

  /// Before the card is learned: `good`/`easy` learn it at a one-day
  /// interval, `again` restarts its repetitions, `hard` only moves the ease.
  _Step _learning(
    CardScheduleState state,
    Sm2Action action,
    double ease,
    int interval,
    DateTime now,
  ) {
    final nextEase = _nextEase(ease, action);
    final next = switch (action) {
      Sm2Action.again => state.copyWith(easeFactor: nextEase, repetitions: 0),
      Sm2Action.hard => state.copyWith(easeFactor: nextEase),
      Sm2Action.good || Sm2Action.easy => state.copyWith(
        learnedAt: now,
        easeFactor: nextEase,
        intervalDays: _firstIntervalDays,
        repetitions: 1,
      ),
    };
    return (
      next,
      ReviewLogEntry(
        kind: ReviewKind.learning,
        previousEaseFactor: ease,
        nextEaseFactor: nextEase,
        previousIntervalDays: interval,
        nextIntervalDays: next.intervalDays,
      ),
    );
  }

  /// A learned card answered `hard`/`good`/`easy`: 1 day, then 6, then the
  /// interval times the new ease, due at local midnight (BR-STUDY-074).
  _Step _scheduled(
    CardScheduleState state,
    Sm2Action action,
    double ease,
    int interval,
    int repetitions,
    DateTime now,
  ) {
    final nextEase = _nextEase(ease, action);
    final nextInterval = switch (repetitions) {
      0 => _firstIntervalDays,
      1 => _secondIntervalDays,
      _ => (interval * nextEase).round(),
    };
    final dueAt = dueAtLocalMidnight(now, nextInterval);
    return (
```

with

```dart
    }
    final (ease, interval, repetitions) = _valuesOf(state);
    if (state.learnedAt == null) {
      throw ArgumentError.value(state, 'state', 'a card still learning');
    }
    final nextEase = _nextEase(ease, action);
    final passed = _qualityOf[action]! >= _passingQuality;
    final nextInterval = passed
        ? _passedInterval(interval, repetitions, nextEase)
        : _firstIntervalDays;
    final dueAt = dueAtLocalMidnight(now, nextInterval);
    final lapses = isLapse(action) ? 1 : 0;
    return (
```

Replace

```dart
        intervalDays: nextInterval,
        repetitions: repetitions + 1,
        dueAt: dueAt,
        answerCount: state.answerCount + 1,
      ),
```

with

```dart
        intervalDays: nextInterval,
        repetitions: passed ? repetitions + 1 : 0,
        dueAt: dueAt,
        lastAnsweredAt: now,
        answerCount: state.answerCount + 1,
        lapseCount: state.lapseCount + lapses,
      ),
```

Replace

```dart

  /// A learned card answered `again`: ease, interval and due date unchanged
  /// (BR-SRS-017), repetitions start over, one more lapse (BR-SRS-018).
  _Step _relearning(CardScheduleState state, double ease, int interval) => (
    state.copyWith(repetitions: 0, lapseCount: state.lapseCount + 1),
    ReviewLogEntry(
      kind: ReviewKind.relearning,
      previousEaseFactor: ease,
      nextEaseFactor: ease,
      previousIntervalDays: interval,
      nextIntervalDays: interval,
      nextDueAt: state.dueAt,
    ),
  );

```

with

```dart

  /// Interval 1 with one repetition, so the first `good` of a review gives
  /// 6 days; the ease stays as it is (BR-STUDY-053; spec D6).
  @override
  CardScheduleState learned(CardScheduleState state, DateTime now) {
    _valuesOf(state);
    if (state.learnedAt != null) {
      throw ArgumentError.value(state, 'state', 'a card already learned');
    }
    return state.copyWith(
      learnedAt: now,
      intervalDays: _firstIntervalDays,
      repetitions: 1,
      dueAt: dueAtLocalMidnight(now, _firstIntervalDays),
    );
  }

  (double, int, int) _valuesOf(CardScheduleState state) {
    final ease = state.easeFactor;
    final interval = state.intervalDays;
    final repetitions = state.repetitions;
    if (ease == null || interval == null || repetitions == null) {
      throw ArgumentError.value(state, 'state', 'not an sm2 state');
    }
    return (ease, interval, repetitions);
  }

  int _passedInterval(int interval, int repetitions, double ease) =>
      switch (repetitions) {
        0 => _firstIntervalDays,
        1 => _secondIntervalDays,
        _ => (interval * ease).round(),
      };

```

In `lib/features/srs/domain/models/srs_scheduler.dart`:

Replace

```dart

/// A pure function of (state, action, now) -> (next state, log entry). Time
/// is injected so tests never depend on the wall clock (spec §5 "SRS core").
abstract interface class SrsScheduler {
```

with

```dart

/// The schedule of a learned card, as pure functions of (state, action, now).
/// Time is injected so tests never depend on the wall clock (spec §5 "SRS
/// core"). Only a `scheduled` turn reaches [next]: the session decides a
/// turn's kind (BR-SRS-015), and `learning` and `relearning` turns leave the
/// schedule as it is (BR-SRS-017, BR-STUDY-053).
abstract interface class SrsScheduler {
```

Replace

```dart
  Set<Object> get supportedActions;
  (CardScheduleState, ReviewLogEntry) next(
```

with

```dart
  Set<Object> get supportedActions;

  /// Whether [action] says the card was not remembered: `forgotten` or
  /// `again` (BR-SRS-018, BR-STUDY-005, BR-STUDY-007).
  bool isLapse(Object action);

  /// A `scheduled` turn on a learned card (BR-SRS-016). A card still learning
  /// is a programming error and throws [ArgumentError].
  (CardScheduleState, ReviewLogEntry) next(
```

Replace

```dart
    DateTime now,
  );
}
```

with

```dart
    DateTime now,
  );

  /// The schedule a card starts when it finishes learning (BR-STUDY-053):
  /// learned at [now], at the lowest level, due at the next local midnight
  /// (BR-STUDY-074). A learned card is a programming error and throws
  /// [ArgumentError].
  CardScheduleState learned(CardScheduleState state, DateTime now);
}
```

- [ ] **Step 4: Record turns and learning completion in the repository**

In `lib/features/srs/data/datasources/srs_dao.dart`:

Replace

```dart
/// Row access for `card_schedule` and `review_log`, plus the reads of `deck`
/// and `study_session` srs needs. It returns Drift rows, never domain
/// values, and runs inside the caller's transaction.
final class SrsDao {
```

with

```dart
/// Row access for `card_schedule` and `review_log`, plus the reads of `deck`
/// srs needs and the sessions a reset closes. It returns Drift rows, never
/// domain values, and runs inside the caller's transaction.
final class SrsDao {
```

Replace

```dart
  /// The root of [cardId]'s tree, reached through `card.deck_id` and then
  /// `deck.root_id` — never `COALESCE(parent_id, id)` (BR-DECK-003).
  Future<Deck?> rootOfCard(String cardId) async {
```

with

```dart
  /// The root of [cardId]'s tree, reached through `card.deck_id` and then
  /// `deck.root_id` — never `COALESCE(parent_id, id)` (BR-DECK-003); null
  /// when the card or its deck is in the Trash (BE-C3).
  Future<Deck?> rootOfCard(String cardId) async {
```

Replace

```dart
          ' JOIN deck root ON root.id = d.root_id'
          ' WHERE c.id = ?',
          variables: [Variable<String>(cardId)],
```

with

```dart
          ' JOIN deck root ON root.id = d.root_id'
          ' WHERE c.id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL',
          variables: [Variable<String>(cardId)],
```

Replace

```dart
  )..where((schedule) => schedule.cardId.equals(cardId))).getSingleOrNull();

  Future<StudySession?> sessionRow(String id) => (_db.select(
    _db.studySession,
  )..where((session) => session.id.equals(id))).getSingleOrNull();

```

with

```dart
  )..where((schedule) => schedule.cardId.equals(cardId))).getSingleOrNull();

```

In `lib/features/srs/data/repositories/schedule_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/srs/domain/models/review_log_entry_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart
const _schedulerReset = 'scheduler_reset';

```

with

```dart
const _schedulerReset = 'scheduler_reset';

/// The root of a card's tree and the card's schedule.
typedef _Studied = (Deck, CardScheduleState);

```

Replace

```dart
  @override
  Future<Outcome<void, SrsRejection>> recordReview({
    required String cardId,
    required String sessionId,
    required Object action,
    DateTime? now,
```

with

```dart
  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) =>
      _write(() async {
        switch (await _studied(turn.cardId, turn.generation)) {
          case Rejected(:final reason):
            return Rejected(reason);
          case Ok(value: (final root, final before)):
            return _record(turn, root, before);
        }
      });

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
```

Replace

```dart
    return _write(() async {
      final schedule = await _dao.scheduleRow(cardId);
      final root = await _dao.rootOfCard(cardId);
      if (schedule == null || root == null) {
        return const Rejected(SrsRejection.notFound);
      }
      final type = SchedulerType.fromCode(root.schedulerType!);
      final scheduler = schedulerFor(type);
      if (!scheduler.supportedActions.contains(action)) {
        return const Rejected(SrsRejection.unsupportedAction);
      }
      final session = await _dao.sessionRow(sessionId);
      if (session == null) return const Rejected(SrsRejection.notFound);
      if (session.generation != root.generation) {
        return const Rejected(SrsRejection.staleGeneration);
      }

      final before = _stateOf(schedule);
      final (after, entry) = scheduler.next(before, action, at);
      await _dao.updateSchedule(
        cardId,
        _columnsOf(after, type: type, version: root.schedulerVersion!),
      );
      await _dao.insertReviewLog(
        _logOf(
          entry,
          cardId: cardId,
          sessionId: sessionId,
          mode: session.currentMode,
          type: type,
          generation: after.generation,
          action: action as Enum,
          at: at,
        ),
      );
      // The first card of the tree to finish learning locks its scheduler
      // (BR-SRS-003).
      final learnedNow = before.learnedAt == null && after.learnedAt != null;
      if (learnedNow && root.firstAnsweredAt == null) {
        await _dao.updateDeck(
          root.id,
          DeckCompanion(firstAnsweredAt: Value(at), updatedAt: Value(at)),
        );
      }
      return const Ok(null);
    });
  }
```

with

```dart
    return _write(() async {
      switch (await _studied(cardId, generation)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final root, final before)):
          return _complete(cardId, root, before, at);
      }
    });
  }

  Future<Outcome<void, SrsRejection>> _record(
    ReviewTurn turn,
    Deck root,
    CardScheduleState before,
  ) async {
    final type = SchedulerType.fromCode(root.schedulerType!);
    final scheduler = schedulerFor(type);
    if (!scheduler.supportedActions.contains(turn.action)) {
      return const Rejected(SrsRejection.unsupportedAction);
    }
    // A scheduled turn on a card still learning is a bug the scheduler throws
    // on, which rolls the turn back (BR-STUDY-058).
    final (after, entry) = turn.kind == ReviewKind.scheduled
        ? scheduler.next(before, turn.action, turn.answeredAt)
        : _unchanged(before, turn.kind, turn.answeredAt);
    await _dao.updateSchedule(
      turn.cardId,
      _columnsOf(after, type: type, version: root.schedulerVersion!),
    );
    await _dao.insertReviewLog(_logOf(entry, turn, type));
    return const Ok(null);
  }

  Future<Outcome<void, SrsRejection>> _complete(
    String cardId,
    Deck root,
    CardScheduleState before,
    DateTime at,
  ) async {
    // Completing a learned card again is a bug the scheduler throws on.
    final type = SchedulerType.fromCode(root.schedulerType!);
    await _dao.updateSchedule(
      cardId,
      _columnsOf(
        schedulerFor(type).learned(before, at),
        type: type,
        version: root.schedulerVersion!,
      ),
    );
    // The first card of the generation to finish learning locks the
    // scheduler (BR-SRS-003); a later one keeps that mark.
    if (root.firstAnsweredAt == null) {
      await _dao.updateDeck(
        root.id,
        DeckCompanion(firstAnsweredAt: Value(at), updatedAt: Value(at)),
      );
    }
    return const Ok(null);
  }

  /// The root and the schedule of [cardId], read inside the caller's
  /// transaction: notFound when the card is gone or in the Trash (BE-C3),
  /// staleGeneration when [generation] is not the root's (BR-SRS-026).
  Future<Outcome<_Studied, SrsRejection>> _studied(
    String cardId,
    int generation,
  ) async {
    final root = await _dao.rootOfCard(cardId);
    final schedule = await _dao.scheduleRow(cardId);
    if (root == null || schedule == null) {
      return const Rejected(SrsRejection.notFound);
    }
    if (generation != root.generation || schedule.generation != generation) {
      return const Rejected(SrsRejection.staleGeneration);
    }
    return Ok((root, _stateOf(schedule)));
  }
```

Replace

```dart

/// Every column of a `card_schedule` row but `card_id`.
```

with

```dart

/// A `learning` or `relearning` turn: the schedule stays as it is but for
/// `last_answered_at`, and the log's before and after values are the same
/// (BR-SRS-017, BR-SRS-018, invariant 14).
(CardScheduleState, ReviewLogEntry) _unchanged(
  CardScheduleState state,
  ReviewKind kind,
  DateTime at,
) => (
  state.copyWith(lastAnsweredAt: at),
  ReviewLogEntry(
    kind: kind,
    previousBox: state.currentBox,
    nextBox: state.currentBox,
    previousEaseFactor: state.easeFactor,
    nextEaseFactor: state.easeFactor,
    previousIntervalDays: state.intervalDays,
    nextIntervalDays: state.intervalDays,
    nextDueAt: state.dueAt,
  ),
);

/// Every column of a `card_schedule` row but `card_id`.
```

Replace

```dart
ReviewLogCompanion _logOf(
  ReviewLogEntry entry, {
  required String cardId,
  required String sessionId,
  required String mode,
  required SchedulerType type,
  required int generation,
  required Enum action,
  required DateTime at,
}) => ReviewLogCompanion.insert(
  id: newId(),
  cardId: cardId,
  sessionId: sessionId,
  schedulerType: type.code,
  generation: generation,
  kind: entry.kind.name,
  mode: mode,
  action: action.name,
  answeredAt: at,
  nextDueAt: Value(entry.nextDueAt),
```

with

```dart
ReviewLogCompanion _logOf(
  ReviewLogEntry entry,
  ReviewTurn turn,
  SchedulerType type,
) => ReviewLogCompanion.insert(
  id: newId(),
  cardId: turn.cardId,
  sessionId: turn.sessionId,
  schedulerType: type.code,
  generation: turn.generation,
  kind: entry.kind.name,
  mode: turn.modeCode,
  direction: Value(turn.directionCode),
  action: (turn.action as Enum).name,
  answeredAt: turn.answeredAt,
  nextDueAt: Value(entry.nextDueAt),
```

Create `lib/features/srs/domain/models/review_turn_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/review_kind_model.dart';

/// One answer a study session records (UC-STUDY-001 steps 7–9). The session
/// decides [kind] (BR-SRS-015) and hands over what `review_log` keeps of it:
/// [modeCode] and [directionCode] are the stored codes of the study mode and
/// of the row's direction, passed as text because `srs` is the base feature
/// and does not import `study_mode` (ADR-011).
final class ReviewTurn {
  const ReviewTurn({
    required this.cardId,
    required this.sessionId,
    required this.generation,
    required this.kind,
    required this.modeCode,
    required this.action,
    required this.answeredAt,
    this.directionCode,
  });

  final String cardId;
  final String sessionId;

  /// The session's generation (BR-SRS-025, BR-SRS-026).
  final int generation;
  final ReviewKind kind;
  final String modeCode;

  /// One of the root scheduler's `supportedActions`.
  final Object action;
  final String? directionCode;
  final DateTime answeredAt;
}
```

In `lib/features/srs/domain/repositories/schedule_repository.dart`:

Replace

```dart
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

with

```dart
import 'package:memox/features/srs/domain/models/reset_learning_summary_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
```

Replace

```dart

  Future<Outcome<void, SrsRejection>> recordReview({
    required String cardId,
    required String sessionId,
    required Object action,
    DateTime? now,
```

with

```dart

  /// Records one answer of a study session (BR-SRS-019). Only a `scheduled`
  /// turn changes the schedule; `learning` and `relearning` turns stamp
  /// `last_answered_at` and nothing else (BR-SRS-016, BR-SRS-017,
  /// BR-SRS-018). Refused, writing nothing, for a card that is gone or in the
  /// Trash (notFound), a turn of another generation (staleGeneration) and an
  /// action the root scheduler does not support (unsupportedAction). A
  /// `scheduled` turn on a card still learning is a bug: it throws and
  /// writes nothing (BR-STUDY-058). Joins the caller's transaction.
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn);

  /// A card finished learning (BR-STUDY-053): its schedule starts at the
  /// lowest level, due at the next local midnight, and no `review_log` row is
  /// written. The first completion of a generation also locks the root's
  /// scheduler, in one write with it (BR-SRS-003). Refused, writing nothing,
  /// for a card that is gone or in the Trash (notFound) and another
  /// generation (staleGeneration). Completing a learned card is a bug: it
  /// throws and writes nothing. Joins the caller's transaction.
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/srs/data/record_turn_test.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/srs/domain/eight_box_scheduler_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart \
  test/features/srs/domain/sm2_scheduler_test.dart \
  test/integration/foundation_smoke_test.dart
```

Expected: `+78: All tests passed!`

- [ ] **Step 7: Run the phased gate**

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

Expected: `No issues found!`; `+1028: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 8: Commit**

```bash
git add docs/_generated \
  lib/features/srs/data/datasources/srs_dao.dart \
  lib/features/srs/data/repositories/schedule_repository_impl.dart \
  lib/features/srs/domain/models/eight_box_scheduler.dart \
  lib/features/srs/domain/models/review_turn_model.dart \
  lib/features/srs/domain/models/sm2_scheduler.dart \
  lib/features/srs/domain/models/srs_scheduler.dart \
  lib/features/srs/domain/repositories/schedule_repository.dart \
  test/features/srs/data/record_turn_test.dart \
  test/features/srs/data/reset_learning_test.dart \
  test/features/srs/data/schedule_repository_impl_test.dart \
  test/features/srs/domain/eight_box_scheduler_test.dart \
  test/features/srs/domain/reset_learning_use_cases_test.dart \
  test/features/srs/domain/sm2_scheduler_test.dart \
  test/integration/foundation_smoke_test.dart
git commit -F - <<'EOF'
feat(srs): record study turns and learning completion, and filter the Trash

recordTurn records one answer of a session: only a scheduled turn moves the
schedule, a learning or relearning turn stamps last_answered_at and logs
before = after (BR-SRS-016, BR-SRS-017). completeLearning starts the schedule
of a card that finished learning at the lowest level, due at the next local
midnight, and locks the scheduler with the first one (BR-STUDY-053,
BR-SRS-003). Both schedulers follow BR-SRS-008 to BR-SRS-012, and rootOfCard
no longer reaches a card or deck in the Trash (BE-C3).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The study-mode domain: six modes, one dispatch point

**Files:**
- Create: `lib/features/study_mode/domain/failures/study_mode_failure.dart`, `lib/features/study_mode/domain/models/browse_mode.dart`, `lib/features/study_mode/domain/models/fill_mode.dart`, `lib/features/study_mode/domain/models/graded_mode.dart`, `lib/features/study_mode/domain/models/guess_mode.dart`, `lib/features/study_mode/domain/models/match_mode.dart`, `lib/features/study_mode/domain/models/question_direction_model.dart`, `lib/features/study_mode/domain/models/row_step_model.dart`, `lib/features/study_mode/domain/models/self_assess_mode.dart`, `lib/features/study_mode/domain/models/session_kind_model.dart`, `lib/features/study_mode/domain/models/stage_eligibility_model.dart`, `lib/features/study_mode/domain/models/study_answer_model.dart`, `lib/features/study_mode/domain/models/study_mode.dart`
- Test (create): `test/features/study_mode/domain/question_direction_model_test.dart`, `test/features/study_mode/domain/study_mode_handler_test.dart`, `test/features/study_mode/domain/study_mode_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`

**Interfaces:**
- Consumes: `SchedulerType`, `SrsScheduler` (`supportedActions`, `isLapse`),
  `EightBoxAction`, `Sm2Action` (Task 1); `Outcome`.
- Produces, all in `lib/features/study_mode/domain/`:
  - `enum StudyMode {browse, selfAssess, match, guess, recall, fill}` with
    `String code`, `static StudyMode fromCode(String)` and
    `StudyModeHandler get handler`; `List<StudyMode> stageSequenceOf(SchedulerType)`
    and `List<StudyMode> reviewModesOf(SchedulerType)` (`models/study_mode.dart`).
  - `abstract base class StudyModeHandler` with `producesAction`, `usesRounds`,
    `servesInOrder`, `takesDirection`,
    `StageEligibility eligibility(List<StudyCardFacts> cards, {required int distinctMeaningCount})`,
    `Outcome<Object?, StudyModeRejection> actionOf(StudyAnswer answer, SrsScheduler scheduler)`
    and `RowStep stepAfter({required bool lapsed, required int answersInSession})`;
    the handlers `browseMode`, `selfAssessMode`, `matchMode`, `guessMode`,
    `recallMode`, `fillMode`.
  - `enum SessionKind {learning, reviewing}`; `sealed class StudyAnswer` with
    `AdvanceAnswer()`, `SelfAssessAnswer(Object action)` and
    `GradedAnswer({required bool isCorrect})`.
  - `StudyCardFacts({required String cardId, required bool hasExample})`,
    `enum ModeUnavailableReason {noExample, tooFewPairs, tooFewMeanings}`,
    `sealed class StageEligibility` with `StageRuns(List<String> cardIds)` and
    `StageSkipped(ModeUnavailableReason reason)`.
  - `sealed class RowStep` with `Leave()`, `ComeBack({required int afterTurns})`,
    `LeaveAtCap()`, `StayAndEnroll()`, `LeaveAndEnroll()`.
  - `enum DirectionChoice {koreanToMeaning, meaningToKorean, mixed}` and
    `enum QuestionDirection {koreanToMeaning, meaningToKorean}` with `code` and
    `fromCode`; `bool acceptsDirection(SessionKind, SchedulerType, StudyMode)`;
    `List<QuestionDirection> assignDirections(int count, DirectionChoice choice, Random random)`.
  - `enum StudyModeRejection {answerDoesNotFitMode, unsupportedAction}`.
  - Import map entry `'study_mode': {'srs'}`.

Spec §5 and D4, D5; Clarification 5. Nothing here reads the database: the
session hands the facts in and applies the decisions. `graded_mode.dart` is the
right/wrong verdict of package 2a; `recall` uses it as it is, and `match`,
`guess` and `fill` add their data condition and row step.

- [ ] **Step 1: Write the failing tests**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'settings': {},
};
```

with

```dart
  'settings': {},
  'study_mode': {'srs'},
};
```

Create `test/features/study_mode/domain/question_direction_model_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

const _k2m = QuestionDirection.koreanToMeaning;
const _m2k = QuestionDirection.meaningToKorean;

void main() {
  test('the choices and the directions keep their stored codes '
      '(BR-MODE-014, BR-MODE-015)', () {
    expect(
      [for (final choice in DirectionChoice.values) choice.code],
      ['korean_to_meaning', 'meaning_to_korean', 'mixed'],
    );
    expect(
      [for (final direction in QuestionDirection.values) direction.code],
      ['korean_to_meaning', 'meaning_to_korean'],
    );
    for (final choice in DirectionChoice.values) {
      expect(DirectionChoice.fromCode(choice.code), choice);
    }
    for (final direction in QuestionDirection.values) {
      expect(QuestionDirection.fromCode(direction.code), direction);
    }
  });

  test('only a review of an sm2 deck in self_assess takes a direction '
      '(BR-MODE-013)', () {
    final accepted = [
      for (final kind in SessionKind.values)
        for (final type in SchedulerType.values)
          for (final mode in StudyMode.values)
            if (acceptsDirection(kind, type, mode)) (kind, type, mode),
    ];

    expect(accepted, [
      (SessionKind.reviewing, SchedulerType.sm2, StudyMode.selfAssess),
    ]);
  });

  test('a fixed choice gives every card that direction (BR-MODE-015)', () {
    expect(assignDirections(3, DirectionChoice.meaningToKorean, Random(1)), [
      _m2k,
      _m2k,
      _m2k,
    ]);
    expect(assignDirections(2, DirectionChoice.koreanToMeaning, Random(1)), [
      _k2m,
      _k2m,
    ]);
  });

  test('mixed splits the cards evenly, an odd card going to either side '
      '(BR-MODE-015)', () {
    for (final count in [0, 1, 2, 7, 20]) {
      for (var seed = 0; seed < 20; seed++) {
        final directions = assignDirections(
          count,
          DirectionChoice.mixed,
          Random(seed),
        );
        final koreanFirst = directions.where((d) => d == _k2m).length;
        expect(directions, hasLength(count));
        expect(
          (koreanFirst - (count - koreanFirst)).abs(),
          lessThanOrEqualTo(1),
        );
      }
    }
    final oddSides = {
      for (var seed = 0; seed < 20; seed++)
        assignDirections(1, DirectionChoice.mixed, Random(seed)).single,
    };
    expect(oddSides, {_k2m, _m2k});
  });

  test('mixed deals the directions across the cards, not in two blocks '
      '(BR-MODE-015)', () {
    final orders = {
      for (var seed = 0; seed < 20; seed++)
        assignDirections(6, DirectionChoice.mixed, Random(seed)).join(','),
    };

    expect(orders.length, greaterThan(1));
  });
}
```

Create `test/features/study_mode/domain/study_mode_handler_test.dart`:

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

List<StudyCardFacts> _cards(int count, {Set<int> withExample = const {}}) => [
  for (var i = 0; i < count; i++)
    StudyCardFacts(cardId: 'c$i', hasExample: withExample.contains(i)),
];

StageEligibility _eligibility(
  StudyMode mode,
  List<StudyCardFacts> cards, {
  int meanings = 5,
}) => mode.handler.eligibility(cards, distinctMeaningCount: meanings);

Matcher _runsOn(List<String> cardIds) =>
    isA<StageRuns>().having((runs) => runs.cardIds, 'cardIds', cardIds);

Matcher _skippedFor(ModeUnavailableReason reason) =>
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

void main() {
  group('data conditions', () {
    test('browse, self_assess and recall ask every card', () {
      for (final mode in [
        StudyMode.browse,
        StudyMode.selfAssess,
        StudyMode.recall,
      ]) {
        expect(
          _eligibility(mode, _cards(2), meanings: 1),
          _runsOn(['c0', 'c1']),
        );
      }
    });

    test('fill asks only the cards with an example and is skipped without '
        'one (BR-STUDY-044, BR-STUDY-071; IT-LEARN-005)', () {
      expect(
        _eligibility(StudyMode.fill, _cards(3, withExample: {0, 2})),
        _runsOn(['c0', 'c2']),
      );
      expect(
        _eligibility(StudyMode.fill, _cards(3)),
        _skippedFor(ModeUnavailableReason.noExample),
      );
    });

    test('match needs two pairs: one card is its own answer (BR-STUDY-045; '
        'IT-LEARN-007)', () {
      expect(
        _eligibility(StudyMode.match, _cards(1)),
        _skippedFor(ModeUnavailableReason.tooFewPairs),
      );
      expect(_eligibility(StudyMode.match, _cards(2)), _runsOn(['c0', 'c1']));
    });

    test('guess needs five distinct meanings in its distractor source, not '
        'five cards (BR-STUDY-037, BR-STUDY-040; spec D5; IT-LEARN-006, '
        'IT-MODE-006, IT-MODE-015)', () {
      expect(
        _eligibility(StudyMode.guess, _cards(4), meanings: 4),
        _skippedFor(ModeUnavailableReason.tooFewMeanings),
      );
      expect(
        _eligibility(StudyMode.guess, _cards(1), meanings: 5),
        _runsOn(['c0']),
      );
    });
  });

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
    RowStep step(StudyMode mode, {required bool lapsed, int answers = 0}) =>
        mode.handler.stepAfter(lapsed: lapsed, answersInSession: answers);

    test('a pass leaves the queue in every mode (BR-STUDY-007)', () {
      for (final mode in StudyMode.values) {
        expect(step(mode, lapsed: false), isA<Leave>());
      }
    });

    test('a forgotten self_assess card comes back after three other turns, '
        'up to three relearning turns, then leaves flagged (BR-STUDY-005, '
        'BR-STUDY-073; IT-LEARN-009)', () {
      for (final answers in [0, 1, 2]) {
        expect(
          step(StudyMode.selfAssess, lapsed: true, answers: answers),
          isA<ComeBack>().having((back) => back.afterTurns, 'afterTurns', 3),
        );
      }
      expect(
        step(StudyMode.selfAssess, lapsed: true, answers: 3),
        isA<LeaveAtCap>(),
      );
    });

    test('a wrong match stays on the board and joins the next round '
        '(BR-STUDY-062)', () {
      expect(step(StudyMode.match, lapsed: true), isA<StayAndEnroll>());
    });

    test('a wrong guess, recall or fill leaves its row and joins the next '
        'round, with no cap (BR-STUDY-059, BR-STUDY-069)', () {
      for (final mode in [StudyMode.guess, StudyMode.recall, StudyMode.fill]) {
        expect(step(mode, lapsed: true, answers: 12), isA<LeaveAndEnroll>());
      }
    });
  });
}
```

Create `test/features/study_mode/domain/study_mode_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

void main() {
  test('the six modes keep the codes schema.md stores (BR-MODE-002, '
      'BR-MODE-008)', () {
    expect(
      [for (final mode in StudyMode.values) mode.code],
      ['browse', 'self_assess', 'match', 'guess', 'recall', 'fill'],
    );
    for (final mode in StudyMode.values) {
      expect(StudyMode.fromCode(mode.code), mode);
    }
  });

  test('an unknown code is corrupt data, never a default', () {
    expect(() => StudyMode.fromCode('review'), throwsArgumentError);
  });

  test('each algorithm declares its learning chain (BR-MODE-004, '
      'BR-MODE-007; IT-LEARN-001, IT-LEARN-002)', () {
    expect(stageSequenceOf(SchedulerType.eightBox), [
      StudyMode.browse,
      StudyMode.match,
      StudyMode.guess,
      StudyMode.recall,
      StudyMode.fill,
    ]);
    expect(stageSequenceOf(SchedulerType.sm2), [
      StudyMode.browse,
      StudyMode.selfAssess,
    ]);
  });

  test('a review offers the graded stages of the chain, never browse '
      '(BR-STUDY-055; IT-STUDY-004, IT-STUDY-005)', () {
    expect(reviewModesOf(SchedulerType.eightBox), [
      StudyMode.match,
      StudyMode.guess,
      StudyMode.recall,
      StudyMode.fill,
    ]);
    expect(reviewModesOf(SchedulerType.sm2), [StudyMode.selfAssess]);
  });

  test('the one dispatch gives every mode its handler', () {
    final handlers = {for (final mode in StudyMode.values) mode: mode.handler};

    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (!handler.producesAction) mode,
      ],
      [StudyMode.browse],
    );
    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (handler.usesRounds) mode,
      ],
      [StudyMode.match, StudyMode.guess, StudyMode.recall, StudyMode.fill],
    );
    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (!handler.servesInOrder) mode,
      ],
      [StudyMode.match],
    );
    expect(
      [
        for (final MapEntry(key: mode, value: handler) in handlers.entries)
          if (handler.takesDirection) mode,
      ],
      [StudyMode.selfAssess],
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study_mode/domain/question_direction_model_test.dart \
  test/features/study_mode/domain/study_mode_handler_test.dart \
  test/features/study_mode/domain/study_mode_test.dart \
  test/architecture
```

Expected: `+26 -3: Some tests failed.` The architecture tests pass; the three new files do not compile. The first errors: `Error: Undefined name 'StudyMode'.`, `Error: Undefined name 'DirectionChoice'.`, `Error: Undefined name 'QuestionDirection'.`

- [ ] **Step 3: Write the vocabulary of a turn**

Create `lib/features/study_mode/domain/failures/study_mode_failure.dart`:

```dart
/// Why a mode refuses an answer (ADR-011 D6).
enum StudyModeRejection {
  /// The answer is of another mode's kind (spec §5.4).
  answerDoesNotFitMode,

  /// The action is not in the scheduler's `supportedActions` (BR-MODE-011,
  /// BR-STUDY-009).
  unsupportedAction,
}
```

Create `lib/features/study_mode/domain/models/row_step_model.dart`:

```dart
/// What a turn does to its queue row (spec §5.5). The study session applies
/// it in the turn's transaction.
sealed class RowStep {
  const RowStep();
}

/// The row is done (BR-STUDY-007).
final class Leave extends RowStep {
  const Leave();
}

/// `self_assess`: the same row stays pending and is served again once
/// [afterTurns] other turns have passed, or at the end when fewer remain
/// (BR-STUDY-005).
final class ComeBack extends RowStep {
  const ComeBack({required this.afterTurns});

  final int afterTurns;
}

/// `self_assess` at its cap: the row is done even though the card was
/// forgotten, and the card is flagged (BR-STUDY-073).
final class LeaveAtCap extends RowStep {
  const LeaveAtCap();
}

/// `match`: the row stays on the board, and the card joins the next round
/// once (BR-STUDY-062).
final class StayAndEnroll extends RowStep {
  const StayAndEnroll();
}

/// `guess`, `recall`, `fill`: the row is done, and the card joins the next
/// round once (BR-STUDY-059, BR-STUDY-060).
final class LeaveAndEnroll extends RowStep {
  const LeaveAndEnroll();
}
```

Create `lib/features/study_mode/domain/models/session_kind_model.dart`:

```dart
/// The two kinds of study session, stored by name on
/// `study_session.session_kind` (BR-STUDY-051). They never share cards.
enum SessionKind {
  /// Cards not learned yet, through the algorithm's stage chain
  /// (BR-MODE-003).
  learning,

  /// Learned cards that are due, through the one mode the person picks
  /// (BR-STUDY-055).
  reviewing,
}
```

Create `lib/features/study_mode/domain/models/stage_eligibility_model.dart`:

```dart
/// What a stage's data condition reads of one card (BR-STUDY-071).
final class StudyCardFacts {
  const StudyCardFacts({required this.cardId, required this.hasExample});

  final String cardId;
  final bool hasExample;
}

/// Why a stage cannot run on a set of cards (BR-MODE-009): a learning
/// session skips it, a review shows the mode disabled with this reason.
enum ModeUnavailableReason {
  /// No card of the set has an `example` (`fill`, BR-STUDY-044).
  noExample,

  /// Fewer than two cards: one pair is its own answer (`match`,
  /// BR-STUDY-045).
  tooFewPairs,

  /// Fewer than five distinct meanings to draw the options from (`guess`,
  /// BR-STUDY-037, BR-STUDY-040; spec D5).
  tooFewMeanings,
}

/// Whether a stage runs on a set of cards, and on which of them
/// (BR-MODE-009, BR-STUDY-025).
sealed class StageEligibility {
  const StageEligibility();
}

/// The stage asks [cardIds]; every other card of the set is skipped in this
/// stage only (BR-STUDY-071).
final class StageRuns extends StageEligibility {
  const StageRuns(this.cardIds);

  final List<String> cardIds;
}

final class StageSkipped extends StageEligibility {
  const StageSkipped(this.reason);

  final ModeUnavailableReason reason;
}
```

Create `lib/features/study_mode/domain/models/study_answer_model.dart`:

```dart
/// What the person did on one card (UC-STUDY-001 step 6). Package 2b gives
/// the graded modes their own inputs; here they hand in a verdict.
sealed class StudyAnswer {
  const StudyAnswer();
}

/// `browse`: moving on from the card (BR-MODE-005).
final class AdvanceAnswer extends StudyAnswer {
  const AdvanceAnswer();
}

/// `self_assess`: the action the person pressed (BR-MODE-011).
final class SelfAssessAnswer extends StudyAnswer {
  const SelfAssessAnswer(this.action);

  final Object action;
}

/// A graded mode's verdict (BR-MODE-011, BR-MODE-012).
final class GradedAnswer extends StudyAnswer {
  const GradedAnswer({required this.isCorrect});

  final bool isCorrect;
}
```

- [ ] **Step 4: Write StudyMode, its dispatch and the six handlers**

Create `lib/features/study_mode/domain/models/browse_mode.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// `browse`: both sides at once, to get acquainted. No grade, no action, no
/// `review_log` row and no schedule change; the card leaves the queue once
/// the person moves on (BR-MODE-005, BR-MODE-006, BR-STUDY-007).
final class BrowseModeHandler extends StudyModeHandler {
  const BrowseModeHandler();

  @override
  bool get producesAction => false;

  @override
  bool get usesRounds => false;

  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) => switch (answer) {
    AdvanceAnswer() => const Ok(null),
    SelfAssessAnswer() ||
    GradedAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) =>
      const Leave();
}

const BrowseModeHandler browseMode = BrowseModeHandler();
```

Create `lib/features/study_mode/domain/models/fill_mode.dart`:

```dart
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// `fill`: type the term. Only a card with an `example` can be asked; the
/// others are skipped in this stage and still take part in the rest
/// (BR-STUDY-044, BR-STUDY-071).
final class FillModeHandler extends GradedModeHandler {
  const FillModeHandler();

  @override
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    final withExample = [
      for (final card in cards)
        if (card.hasExample) card.cardId,
    ];
    if (withExample.isEmpty) {
      return const StageSkipped(ModeUnavailableReason.noExample);
    }
    return StageRuns(withExample);
  }
}

const FillModeHandler fillMode = FillModeHandler();
```

Create `lib/features/study_mode/domain/models/graded_mode.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The four graded modes (BR-MODE-011): a right or wrong verdict, mapped as
/// BR-MODE-012 says, and rounds that repeat the wrong cards until a round ends
/// with none, with no cap (BR-STUDY-059, BR-STUDY-069). `recall` uses this
/// class as it is; `match`, `guess` and `fill` add their data condition.
base class GradedModeHandler extends StudyModeHandler {
  const GradedModeHandler();

  @override
  bool get usesRounds => true;

  @override
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  ) {
    if (answer is! GradedAnswer) {
      return const Rejected(StudyModeRejection.answerDoesNotFitMode);
    }
    final action = answer.isCorrect
        ? EightBoxAction.remembered
        : EightBoxAction.forgotten;
    if (!scheduler.supportedActions.contains(action)) {
      return const Rejected(StudyModeRejection.unsupportedAction);
    }
    return Ok(action);
  }

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const LeaveAndEnroll();
  }
}

const GradedModeHandler recallMode = GradedModeHandler();
```

Create `lib/features/study_mode/domain/models/guess_mode.dart`:

```dart
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

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
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) {
    if (distinctMeaningCount < _optionCount) {
      return const StageSkipped(ModeUnavailableReason.tooFewMeanings);
    }
    return super.eligibility(cards, distinctMeaningCount: distinctMeaningCount);
  }
}

const GuessModeHandler guessMode = GuessModeHandler();
```

Create `lib/features/study_mode/domain/models/match_mode.dart`:

```dart
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// One pair on the board is its own answer (BR-STUDY-045).
const _minimumPairs = 2;

/// `match`: the pairs of a round on a board. A wrong pair keeps its row on
/// the board and sends the card to the next round (BR-STUDY-062), so any
/// pending row of the round can be answered.
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
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    return const StayAndEnroll();
  }
}

const MatchModeHandler matchMode = MatchModeHandler();
```

Create `lib/features/study_mode/domain/models/self_assess_mode.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// A forgotten card comes back after at least this many other turns
/// (BR-STUDY-005).
const _comeBackAfterTurns = 3;

/// The turns a row may take: one first turn and three `relearning` turns
/// (BR-STUDY-073, invariant 17).
const _turnCap = 4;

/// `self_assess`: the person flips the card and grades it with one of the
/// scheduler's actions (BR-MODE-006, BR-MODE-011). No rounds: a forgotten
/// card comes back in the same queue, up to the cap (BR-STUDY-005,
/// BR-STUDY-073).
final class SelfAssessModeHandler extends StudyModeHandler {
  const SelfAssessModeHandler();

  @override
  bool get usesRounds => false;

  @override
  bool get takesDirection => true;

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
    GradedAnswer() => const Rejected(StudyModeRejection.answerDoesNotFitMode),
  };

  @override
  RowStep stepAfter({required bool lapsed, required int answersInSession}) {
    if (!lapsed) return const Leave();
    if (answersInSession + 1 >= _turnCap) return const LeaveAtCap();
    return const ComeBack(afterTurns: _comeBackAfterTurns);
  }
}

const SelfAssessModeHandler selfAssessMode = SelfAssessModeHandler();
```

Create `lib/features/study_mode/domain/models/study_mode.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/srs_scheduler.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';
import 'package:memox/features/study_mode/domain/models/browse_mode.dart';
import 'package:memox/features/study_mode/domain/models/fill_mode.dart';
import 'package:memox/features/study_mode/domain/models/graded_mode.dart';
import 'package:memox/features/study_mode/domain/models/guess_mode.dart';
import 'package:memox/features/study_mode/domain/models/match_mode.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/self_assess_mode.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// The six ways a card is asked (BR-MODE-002), stored as a stable text code
/// on `study_session.current_mode`, `study_queue_items.mode` and
/// `review_log.mode` (BR-MODE-008).
enum StudyMode {
  browse('browse'),
  selfAssess('self_assess'),
  match('match'),
  guess('guess'),
  recall('recall'),
  fill('fill');

  const StudyMode(this.code);

  final String code;

  /// The mode a stored [code] names. An unknown code is corrupt data, never
  /// a reason to fall back to a default.
  static StudyMode fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    throw ArgumentError.value(code, 'code', 'unknown study mode code');
  }

  /// The one place a mode is told apart (guard
  /// `single_study_mode_dispatch`): every question about a mode is a member
  /// of its handler.
  StudyModeHandler get handler => switch (this) {
    StudyMode.browse => browseMode,
    StudyMode.selfAssess => selfAssessMode,
    StudyMode.match => matchMode,
    StudyMode.guess => guessMode,
    StudyMode.recall => recallMode,
    StudyMode.fill => fillMode,
  };
}

/// The stage chain of a learning session, declared per algorithm
/// (BR-MODE-004, BR-MODE-007; spec D4).
List<StudyMode> stageSequenceOf(SchedulerType type) => switch (type) {
  SchedulerType.eightBox => const [
    StudyMode.browse,
    StudyMode.match,
    StudyMode.guess,
    StudyMode.recall,
    StudyMode.fill,
  ],
  SchedulerType.sm2 => const [StudyMode.browse, StudyMode.selfAssess],
};

/// The modes a review offers: the stages of the chain that record an
/// action, so never `browse` (BR-STUDY-055).
List<StudyMode> reviewModesOf(SchedulerType type) => [
  for (final mode in stageSequenceOf(type))
    if (mode.handler.producesAction) mode,
];

/// A mode's policy (spec §5): what it needs of the cards, what an answer
/// means, and what a turn does to its queue row. Nothing here reads the
/// database; the study session hands the facts in and applies the decisions.
abstract base class StudyModeHandler {
  const StudyModeHandler();

  /// Whether a turn records an action: every mode but `browse`
  /// (BR-MODE-005, BR-MODE-011).
  bool get producesAction => true;

  /// Whether a wrong answer sends the card to a next round (BR-STUDY-059);
  /// `browse` and `self_assess` have no rounds (BR-STUDY-005).
  bool get usesRounds;

  /// Whether turns follow the queue one card at a time; `match` shows
  /// several rows of the round at once.
  bool get servesInOrder => true;

  /// Whether a direction can change which side is the prompt without
  /// changing what is graded (BR-MODE-013).
  bool get takesDirection => false;

  /// The cards of [cards] the stage asks, or why it cannot run on them
  /// (BR-MODE-009, BR-STUDY-071). [distinctMeaningCount] counts the distinct
  /// `back_folded` of the distractor source (spec D5).
  StageEligibility eligibility(
    List<StudyCardFacts> cards, {
    required int distinctMeaningCount,
  }) => StageRuns([for (final card in cards) card.cardId]);

  /// The action [answer] records under [scheduler], null when the mode
  /// records none, or why [answer] does not fit (BR-MODE-011, BR-MODE-012).
  Outcome<Object?, StudyModeRejection> actionOf(
    StudyAnswer answer,
    SrsScheduler scheduler,
  );

  /// What a turn does to its row: [lapsed] when its action was
  /// `forgotten`/`again`, after [answersInSession] earlier turns on that row
  /// (spec §5.5).
  RowStep stepAfter({required bool lapsed, required int answersInSession});
}
```

- [ ] **Step 5: Write the question directions**

Create `lib/features/study_mode/domain/models/question_direction_model.dart`:

```dart
import 'dart:math';

import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The direction a review asks in, chosen once for the whole session
/// (BR-MODE-015, BR-MODE-017) and stored on `study_session.direction`.
enum DirectionChoice {
  koreanToMeaning('korean_to_meaning'),
  meaningToKorean('meaning_to_korean'),
  mixed('mixed');

  const DirectionChoice(this.code);

  final String code;

  static DirectionChoice fromCode(String code) {
    for (final choice in values) {
      if (choice.code == code) return choice;
    }
    throw ArgumentError.value(code, 'code', 'unknown direction choice');
  }
}

/// The direction of one card (BR-MODE-014), stored on
/// `study_queue_items.direction` and copied to `review_log.direction`
/// (BR-MODE-016).
enum QuestionDirection {
  /// `front` is the prompt, `back` the answer.
  koreanToMeaning('korean_to_meaning'),

  /// `back` is the prompt, `front` the answer.
  meaningToKorean('meaning_to_korean');

  const QuestionDirection(this.code);

  final String code;

  static QuestionDirection fromCode(String code) {
    for (final direction in values) {
      if (direction.code == code) return direction;
    }
    throw ArgumentError.value(code, 'code', 'unknown question direction');
  }
}

/// The one predicate of BR-MODE-013: a review of an `sm2` deck in a mode
/// that takes a direction, which only `self_assess` does.
bool acceptsDirection(SessionKind kind, SchedulerType type, StudyMode mode) =>
    kind == SessionKind.reviewing &&
    type == SchedulerType.sm2 &&
    mode.handler.takesDirection;

/// One direction per card, once, when the queue is written (BR-MODE-015). A
/// fixed choice gives every card that direction. `mixed` gives each
/// direction half of the cards, [random] picking the side of an odd card,
/// and deals them across the cards.
List<QuestionDirection> assignDirections(
  int count,
  DirectionChoice choice,
  Random random,
) => switch (choice) {
  DirectionChoice.koreanToMeaning => List.filled(
    count,
    QuestionDirection.koreanToMeaning,
  ),
  DirectionChoice.meaningToKorean => List.filled(
    count,
    QuestionDirection.meaningToKorean,
  ),
  DirectionChoice.mixed => _mixed(count, random),
};

List<QuestionDirection> _mixed(int count, Random random) {
  final half = count ~/ 2;
  final odd = random.nextBool()
      ? QuestionDirection.koreanToMeaning
      : QuestionDirection.meaningToKorean;
  return [
    ...List.filled(half, QuestionDirection.koreanToMeaning),
    ...List.filled(half, QuestionDirection.meaningToKorean),
    if (count.isOdd) odd,
  ]..shuffle(random);
}
```

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/study_mode/domain/question_direction_model_test.dart \
  test/features/study_mode/domain/study_mode_handler_test.dart \
  test/features/study_mode/domain/study_mode_test.dart \
  test/architecture
```

Expected: `+48: All tests passed!`

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

Expected: `No issues found!`; `+1050: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 9: Commit**

```bash
git add lib/features/study_mode/domain/failures/study_mode_failure.dart \
  lib/features/study_mode/domain/models/browse_mode.dart \
  lib/features/study_mode/domain/models/fill_mode.dart \
  lib/features/study_mode/domain/models/graded_mode.dart \
  lib/features/study_mode/domain/models/guess_mode.dart \
  lib/features/study_mode/domain/models/match_mode.dart \
  lib/features/study_mode/domain/models/question_direction_model.dart \
  lib/features/study_mode/domain/models/row_step_model.dart \
  lib/features/study_mode/domain/models/self_assess_mode.dart \
  lib/features/study_mode/domain/models/session_kind_model.dart \
  lib/features/study_mode/domain/models/stage_eligibility_model.dart \
  lib/features/study_mode/domain/models/study_answer_model.dart \
  lib/features/study_mode/domain/models/study_mode.dart \
  test/architecture/boundary_rules.dart \
  test/features/study_mode/domain/question_direction_model_test.dart \
  test/features/study_mode/domain/study_mode_handler_test.dart \
  test/features/study_mode/domain/study_mode_test.dart
git commit -F - <<'EOF'
feat(study_mode): add the six study modes with one dispatch point

StudyMode names the six ways a card is asked and gives each one handler: its
data condition (BR-MODE-009, BR-STUDY-044, BR-STUDY-045), what an answer
means under the root's scheduler (BR-MODE-011, BR-MODE-012) and what a turn
does to its queue row (BR-STUDY-005, BR-STUDY-059, BR-STUDY-062,
BR-STUDY-073). The stage chain is declared per algorithm (BR-MODE-004), and
the question direction of an sm2 review has its one predicate and its
assignment (BR-MODE-013, BR-MODE-015).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: Open a learning session on a deck tree

**Files:**
- Create: `lib/features/study/data/datasources/study_queue_dao.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/repositories/study_entry_repository_impl.dart`, `lib/features/study/di/study_entry_repository_provider.dart`, `lib/features/study/domain/failures/study_failure.dart`, `lib/features/study/domain/models/queue_plan_model.dart`, `lib/features/study/domain/models/session_status_model.dart`, `lib/features/study/domain/repositories/study_entry_repository.dart`, `lib/features/study/domain/usecases/open_learning_session_use_case.dart`
- Modify: `lib/features/settings/data/datasources/settings_dao.dart`, `lib/features/settings/data/repositories/settings_repository_impl.dart`, `lib/features/settings/domain/repositories/settings_repository.dart`, `docs/shared/data/schema.md`
- Test (create): `test/features/study/data/open_learning_session_test.dart`, `test/features/study/domain/open_session_use_cases_test.dart`, `test/features/study/domain/queue_plan_model_test.dart`, `test/support/study_fixtures.dart`
- Test (modify): `test/architecture/boundary_rules.dart`, `test/features/settings/data/root_study_options_repository_test.dart`, `test/support/card_fixtures.dart`
- Regenerate: the `*.g.dart` of the new provider (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 2; `SettingsRepository`, `EffectiveStudyOptions`,
  `StudyOptions`, `NewCardOrder` (settings); `newId()`
  (`lib/core/id/new_id.dart`); `startOfLocalDay`; `databaseProvider`,
  `settingsRepositoryProvider`.
- Produces:
  - `SettingsRepository.studyOptionsOf({required String deckId})` —
    `Future<EffectiveStudyOptions?>`, joining the caller's transaction.
  - `enum StudyRejection` (the 13 values of spec §9) in
    `study/domain/failures/study_failure.dart`; `enum SessionStatus` and
    `enum SessionEndReason` with `code` and `fromCode` in
    `domain/models/session_status_model.dart`.
  - In `domain/models/queue_plan_model.dart`: `StageQueue(StudyMode mode, List<String> cardIds)`,
    `newCardsToLearn(List<StudyCardFacts> candidates, StudyOptions options, Random random)`,
    `learningQueues(SchedulerType type, List<StudyCardFacts> cards, {required int distinctMeaningCount, required Random random})`
    and `shuffledUnlike(List<String> cardIds, List<String> previous, Random random)`.
  - `StudyEntryRepository.openLearningSession({required String deckId, DateTime? now})` —
    `Future<Outcome<String, StudyRejection>>`;
    `StudyEntryRepositoryImpl(AppDatabase db, SettingsRepository settings, {DateTime Function()? now, Random? random})`;
    `studyEntryRepositoryProvider`.
  - `StudySessionDao(AppDatabase db)` with `deckRow`, `newCards`,
    `distinctMeaningCount`, `closeOpenSessions`, `insertSession`, and
    `typedef StudyCardRow = ({String cardId, bool hasExample})`;
    `StudyQueueDao(AppDatabase db).insertFirstRound(sessionId, mode, cardIds)`.
  - `OpenLearningSessionUseCase(StudyEntryRepository entries)` —
    `call({required String deckId})`.
  - Import map entry `'study': {'study_mode', 'srs', 'settings', 'card'}`.
  - For tests: `insertCard(..., String? example)`; in `test/support/study_fixtures.dart`
    `studyEntryRepository(db, now, {int seed = 1})`, `expectStudyInvariants`,
    `sessionOf`, `queueOf`, `modesOf`.

Spec §7.1, §7.2 and D2, D5, D7; Clarifications 2–4. An opening is one
transaction: every refusal comes before the open session of the app is closed
(D2), and round 1 of every stage the cards can run is written at once
(BR-STUDY-021, BR-STUDY-022).

- [ ] **Step 1: Write the failing tests**

In `test/support/card_fixtures.dart`:

Replace

```dart
  String back = 'back',
  bool isFlagged = false,
```

with

```dart
  String back = 'back',
  String? example,
  bool isFlagged = false,
```

Replace

```dart
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
```

with

```dart
    'INSERT INTO card (id, deck_id, front, back, front_folded, back_folded, '
    'example, is_flagged, delete_batch_id, created_at, updated_at) '
    'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
    variables: [
```

Replace

```dart
      Variable<String>(back.trim().toLowerCase()),
      Variable<bool>(isFlagged),
```

with

```dart
      Variable<String>(back.trim().toLowerCase()),
      Variable<String>(example),
      Variable<bool>(isFlagged),
```

Create `test/support/study_fixtures.dart`:

```dart
import 'dart:math';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';

import 'invariant_queries.dart';

// The study repositories and the reads the study tests check them with.

/// The study entry repository over [db], reading the options through the
/// real settings repository and the time from [now], and shuffling with a
/// seeded source, so every order a test sees repeats.
StudyEntryRepositoryImpl studyEntryRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
}) => StudyEntryRepositoryImpl(
  db,
  SettingsRepositoryImpl(db, now: now),
  now: now,
  random: Random(seed),
);

/// No invariant query of schema.md returns a row, and at most one session
/// of the app is open (spec D2).
Future<void> expectStudyInvariants(AppDatabase db) async {
  for (final MapEntry(key: number, value: query) in invariantQueries.entries) {
    expect(
      await db.customSelect(query).get(),
      isEmpty,
      reason: 'invariant $number: ${invariantSummaries[number]}',
    );
  }
  final open = await db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_session WHERE status = 'in_progress'",
      )
      .getSingle();
  expect(open.read<int>('n'), lessThanOrEqualTo(1), reason: 'spec D2');
}

Future<QueryRow> sessionOf(AppDatabase db, String sessionId) => db
    .customSelect(
      'SELECT * FROM study_session WHERE id = ?',
      variables: [Variable(sessionId)],
    )
    .getSingle();

/// The cards of [sessionId]'s rows in [mode] and [round], in serving order.
Future<List<String>> queueOf(
  AppDatabase db,
  String sessionId,
  String mode, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id FROM study_queue_items '
            'WHERE session_id = ? AND mode = ? AND round = ? ORDER BY position',
            variables: [Variable(sessionId), Variable(mode), Variable(round)],
          )
          .get())
    row.read<String>('card_id'),
];

/// The modes [sessionId] has rows in, in the order of the chain.
Future<List<String>> modesOf(AppDatabase db, String sessionId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT mode FROM study_queue_items WHERE session_id = ? '
            'GROUP BY mode ORDER BY MIN(rowid)',
            variables: [Variable(sessionId)],
          )
          .get())
    row.read<String>('mode'),
];
```

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'study_mode': {'srs'},
};
```

with

```dart
  'study_mode': {'srs'},
  'study': {'study_mode', 'srs', 'settings', 'card'},
};
```

In `test/features/settings/data/root_study_options_repository_test.dart`:

Replace

```dart
    expect(effective?.hasRootOverride, isTrue);
  });
```

with

```dart
    expect(effective?.hasRootOverride, isTrue);
  });

  test('the one-shot read gives what the stream gives: the root\'s options '
      'for a sub-deck, none for a missing deck or one in the Trash '
      '(BR-STUDY-056)', () async {
    await _insertTree(
      db,
      studyConfig: '{"card_limit":30,"new_card_order":"random"}',
    );

    final ofRoot = await settings.studyOptionsOf(deckId: 'r');
    final ofSub = await settings.studyOptionsOf(deckId: 's');

    expect(ofRoot?.rootDeckId, 'r');
    expect(ofRoot?.options.cardLimit, 30);
    expect(ofRoot?.options.newCardOrder, NewCardOrder.random);
    expect(ofRoot?.source, StudyOptionsSource.rootOverride);
    expect(ofSub?.rootDeckId, 'r');
    expect(ofSub?.options.cardLimit, 30);
    expect(await settings.studyOptionsOf(deckId: 'missing'), isNull);
    await _moveTreeToTrash(db);
    expect(await settings.studyOptionsOf(deckId: 's'), isNull);
  });
```

Create `test/features/study/data/open_learning_session_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 3 and 5: opening a learning session.

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<String, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

String _opened(Outcome<String, StudyRejection> result) => switch (result) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('opening refused: $reason'),
};

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  var clock = DateTime(2026, 9, 24, 9);
  final learnedAt = DateTime(2026, 9, 10);
  setUp(() {
    clock = DateTime(2026, 9, 24, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    entries = studyEntryRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// [count] new cards in [deckId], `<prefix>1`…, each one minute younger
  /// than the one before and of its own meaning.
  Future<List<String>> newCards(
    String deckId,
    String prefix,
    int count, {
    bool withExample = false,
  }) async {
    final ids = [for (var i = 1; i <= count; i++) '$prefix$i'];
    for (final (index, id) in ids.indexed) {
      await insertCard(
        db,
        id: id,
        deckId: deckId,
        back: 'meaning of $id',
        example: withExample ? 'example of $id' : null,
        createdAt: DateTime(2026, 9, 1).add(Duration(minutes: index)),
      );
    }
    return ids;
  }

  /// A learned card of [deckId] and the lock its learning left on
  /// [rootId] (BR-SRS-003).
  Future<void> learnedCard(String rootId, String deckId, String id) async {
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      back: 'meaning of $id',
      learnedAt: learnedAt,
      dueAt: DateTime(2026, 9, 30),
    );
    await lockScheduler(db, rootId);
  }

  test('a learning session takes the new cards of the deck and its whole '
      'subtree, and nothing else (IT-STUDY-011, BR-STUDY-051)', () async {
    final root = await decks.root('Korean');
    final lessonA = await decks.sub(root.id, 'Lesson A');
    final lessonB = await decks.sub(root.id, 'Lesson B');
    final inA = await newCards(lessonA.id, 'a', 3);
    final inB = await newCards(lessonB.id, 'b', 2);
    await learnedCard(root.id, lessonA.id, 'a-learned');

    final ofA = _opened(await entries.openLearningSession(deckId: lessonA.id));
    final ofRoot = _opened(await entries.openLearningSession(deckId: root.id));

    expect((await queueOf(db, ofA, 'browse'))..sort(), inA);
    expect((await queueOf(db, ofRoot, 'browse'))..sort(), [...inA, ...inB]);
  });

  test('the session starts in browse at the root generation, with the card '
      'limit in force (UC-STUDY-001 step 5, BR-STUDY-024)', () async {
    final root = await decks.root('Korean');
    await db.customStatement('UPDATE deck SET generation = 3 WHERE id = ?', [
      root.id,
    ]);
    final leaf = await decks.sub(root.id, 'Lesson');
    await newCards(leaf.id, 'c', 2);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    final session = await sessionOf(db, id);
    expect(session.read<String>('deck_id'), leaf.id);
    expect(session.read<String>('root_id'), root.id);
    expect(session.read<int>('generation'), 3);
    expect(session.read<String>('session_kind'), 'learning');
    expect(session.read<String>('current_mode'), 'browse');
    expect(session.read<String>('status'), 'in_progress');
    expect(session.read<int>('cursor'), 0);
    expect(session.read<int>('card_limit'), StudyOptions.defaultCardLimit);
    expect(session.data['direction'], isNull);
    expect(session.read<DateTime>('started_at'), clock);
    final rows = await db
        .customSelect(
          'SELECT * FROM study_queue_items WHERE session_id = ? '
          "AND mode = 'browse' ORDER BY position",
          variables: [Variable(id)],
        )
        .get();
    expect([for (final row in rows) row.read<int>('position')], [0, 1]);
    for (final row in rows) {
      expect(row.read<String>('status'), 'pending');
      expect(row.read<int>('round'), 1);
      expect(row.read<int>('available_at'), 0);
      expect(row.read<int>('answers_in_session'), 0);
      expect(row.data['direction'], isNull);
    }
  });

  test('created takes the oldest cards up to the limit, and the session '
      'keeps the limit it opened with (IT-STUDY-012, IT-STUDY-010)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final cards = await newCards(leaf.id, 'limit-', 21);
    final settings = SettingsRepositoryImpl(db, now: () => clock);
    await settings.saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.created,
      ),
    );

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));
    await settings.saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 3,
        newCardOrder: NewCardOrder.created,
      ),
    );

    expect((await queueOf(db, id, 'browse'))..sort(), cards.take(7).toList());
    expect((await sessionOf(db, id)).read<int>('card_limit'), 7);
  });

  test('random draws the set from the whole new set with the injected '
      'source (IT-STUDY-012, BR-STUDY-057)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final cards = await newCards(leaf.id, 'limit-', 21);
    await SettingsRepositoryImpl(db, now: () => clock).saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 7,
        newCardOrder: NewCardOrder.random,
      ),
    );

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    final set = await queueOf(db, id, 'browse');
    expect(set.toSet(), hasLength(7));
    expect(cards.toSet().containsAll(set), isTrue);
    expect(set.toSet(), isNot(cards.take(7).toSet()));
  });

  test('every stage of the eight_box chain asks the same cards in its own '
      'order (IT-LEARN-001, IT-LEARN-004, BR-STUDY-022)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final cards = await newCards(leaf.id, 'c', 5, withExample: true);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    expect(await modesOf(db, id), [
      'browse',
      'match',
      'guess',
      'recall',
      'fill',
    ]);
    final orders = [
      for (final mode in ['browse', 'match', 'guess', 'recall', 'fill'])
        await queueOf(db, id, mode),
    ];
    for (final order in orders) {
      expect([...order]..sort(), cards);
    }
    for (var i = 1; i < orders.length; i++) {
      expect(orders[i], isNot(orders[i - 1]));
    }
  });

  test('the sm2 chain is browse, then self_assess (IT-LEARN-002, '
      'BR-MODE-004)', () async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await newCards(leaf.id, 'c', 2);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    expect(await modesOf(db, id), ['browse', 'self_assess']);
  });

  test('a card without an example is skipped in fill only (IT-LEARN-005, '
      'BR-STUDY-071)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final plain = await newCards(leaf.id, 'p', 3);
    final withExample = await newCards(leaf.id, 'x', 2, withExample: true);

    final id = _opened(await entries.openLearningSession(deckId: leaf.id));

    expect((await queueOf(db, id, 'recall'))..sort(), [
      ...plain,
      ...withExample,
    ]);
    expect((await queueOf(db, id, 'fill'))..sort(), withExample);
  });

  test('guess is skipped under five meanings, and match and guess with one '
      'card (IT-LEARN-006, IT-LEARN-007, IT-MODE-006)', () async {
    final root = await decks.root('Korean');
    final four = await decks.sub(root.id, 'Four');
    final one = await decks.sub(root.id, 'One');
    await newCards(four.id, 'f', 4);
    await newCards(one.id, 'o', 1);

    final ofFour = _opened(await entries.openLearningSession(deckId: four.id));
    final ofOne = _opened(await entries.openLearningSession(deckId: one.id));

    expect(await modesOf(db, ofFour), ['browse', 'match', 'recall']);
    expect(await modesOf(db, ofOne), ['browse', 'recall']);
  });

  test("guess counts the meanings of the tree's learned cards, never of "
      'another tree (spec D5, IT-MODE-015)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    final learned = await decks.sub(root.id, 'Learned');
    await newCards(lesson.id, 'n', 1);
    for (final id in ['l1', 'l2', 'l3']) {
      await learnedCard(root.id, learned.id, id);
    }
    final other = await decks.root('Other');
    final otherLeaf = await decks.sub(other.id, 'Leaf');
    for (final id in ['o1', 'o2', 'o3', 'o4', 'o5']) {
      await learnedCard(other.id, otherLeaf.id, id);
    }

    final withThree = _opened(
      await entries.openLearningSession(deckId: lesson.id),
    );
    await learnedCard(root.id, learned.id, 'l4');
    final withFour = _opened(
      await entries.openLearningSession(deckId: lesson.id),
    );

    expect(await modesOf(db, withThree), isNot(contains('guess')));
    expect(await queueOf(db, withFour, 'guess'), ['n1']);
  });

  test('opening closes the open session of the app: user_exit the same day, '
      'interrupted from an earlier day (BR-STUDY-072, spec D2; '
      'IT-CONT-002)', () async {
    final root = await decks.root('Korean');
    final lessonA = await decks.sub(root.id, 'Lesson A');
    final other = await decks.root('Other');
    final lessonB = await decks.sub(other.id, 'Lesson B');
    await newCards(lessonA.id, 'a', 2);
    await newCards(lessonB.id, 'b', 2);

    final first = _opened(
      await entries.openLearningSession(deckId: lessonA.id),
    );
    clock = DateTime(2026, 9, 24, 21);
    final second = _opened(
      await entries.openLearningSession(deckId: lessonB.id),
    );
    clock = DateTime(2026, 9, 25, 7);
    final third = _opened(
      await entries.openLearningSession(deckId: lessonA.id),
    );

    final closedSameDay = await sessionOf(db, first);
    expect(closedSameDay.read<String>('status'), 'abandoned');
    expect(closedSameDay.read<String>('end_reason'), 'user_exit');
    expect(closedSameDay.read<DateTime>('ended_at'), DateTime(2026, 9, 24, 21));
    final closedNextDay = await sessionOf(db, second);
    expect(closedNextDay.read<String>('end_reason'), 'interrupted');
    expect(closedNextDay.read<DateTime>('ended_at'), clock);
    expect((await sessionOf(db, third)).read<String>('status'), 'in_progress');
  });

  test('a deck with nothing new is refused, writing nothing and leaving the '
      'open session open (BR-STUDY-020)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    final done = await decks.sub(root.id, 'Done');
    await newCards(leaf.id, 'c', 1);
    await learnedCard(root.id, done.id, 'l1');
    final open = _opened(await entries.openLearningSession(deckId: leaf.id));
    final before = await totalChanges(db);

    expect(
      await entries.openLearningSession(deckId: done.id),
      _refusedWith(StudyRejection.nothingToLearn),
    );
    expect(await totalChanges(db), before);
    expect((await sessionOf(db, open)).read<String>('status'), 'in_progress');
  });

  test('a missing deck and a deck in the Trash are notFound', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await newCards(leaf.id, 'c', 1);
    await db.customStatement(
      "UPDATE deck SET delete_batch_id = 'b' WHERE id = ?",
      [leaf.id],
    );
    await db.customStatement("UPDATE card SET delete_batch_id = 'b'");

    expect(
      await entries.openLearningSession(deckId: 'missing'),
      _refusedWith(StudyRejection.notFound),
    );
    expect(
      await entries.openLearningSession(deckId: leaf.id),
      _refusedWith(StudyRejection.notFound),
    );
  });
}
```

Create `test/features/study/domain/open_session_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/open_learning_session_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 3–5 through the use cases the Study Entry calls.

void main() {
  late AppDatabase db;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('OpenLearningSession opens a session on the deck and answers its id '
      '(UC-STUDY-001 step 3)', () async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    final open = OpenLearningSessionUseCase(
      studyEntryRepository(db, () => now),
    );

    final result = await open(deckId: leaf.id);

    final id = (result as Ok<String, StudyRejection>).value;
    expect((await sessionOf(db, id)).read<String>('deck_id'), leaf.id);
    expect(
      await open(deckId: 'missing'),
      isA<Rejected<String, StudyRejection>>(),
    );
  });
}
```

Create `test/features/study/domain/queue_plan_model_test.dart`:

```dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

List<StudyCardFacts> _cards(
  List<String> ids, {
  Set<String> withExample = const {},
}) => [
  for (final id in ids)
    StudyCardFacts(cardId: id, hasExample: withExample.contains(id)),
];

List<String> _ids(List<StudyCardFacts> cards) => [
  for (final card in cards) card.cardId,
];

void main() {
  group('newCardsToLearn', () {
    final candidates = _cards(['c1', 'c2', 'c3', 'c4']);

    test('created takes the oldest card_limit cards (BR-STUDY-003, '
        'BR-STUDY-057)', () {
      const options = StudyOptions(
        cardLimit: 2,
        newCardOrder: NewCardOrder.created,
      );

      expect(_ids(newCardsToLearn(candidates, options, Random(1))), [
        'c1',
        'c2',
      ]);
    });

    test('random draws card_limit cards with the random source '
        '(BR-STUDY-057)', () {
      const options = StudyOptions(
        cardLimit: 2,
        newCardOrder: NewCardOrder.random,
      );

      final draws = {
        for (var seed = 0; seed < 20; seed++)
          (_ids(
            newCardsToLearn(candidates, options, Random(seed)),
          )..sort()).join(),
      };

      expect(draws.every((draw) => draw.length == 4), isTrue);
      expect(draws.length, greaterThan(1));
    });
  });

  group('shuffledUnlike', () {
    test('keeps every card once', () {
      for (var seed = 0; seed < 20; seed++) {
        final order = shuffledUnlike(
          ['a', 'b', 'c', 'd'],
          const [],
          Random(seed),
        );
        expect([...order]..sort(), ['a', 'b', 'c', 'd']);
      }
    });

    test('never repeats the order of the cards it shares with the queue '
        'before it (BR-STUDY-022, BR-STUDY-061)', () {
      for (var seed = 0; seed < 50; seed++) {
        expect(
          shuffledUnlike(['a', 'b', 'c'], ['a', 'b', 'c'], Random(seed)),
          isNot(['a', 'b', 'c']),
        );
        expect(shuffledUnlike(['a', 'c'], ['a', 'b', 'c', 'd'], Random(seed)), [
          'c',
          'a',
        ]);
      }
    });

    test('one shared card, or none, leaves the shuffle as it came', () {
      expect(shuffledUnlike(['a'], ['a'], Random(3)), ['a']);
      final orders = {
        for (var seed = 0; seed < 20; seed++)
          shuffledUnlike(['x', 'y'], ['a', 'b'], Random(seed)).join(),
      };
      expect(orders, {'xy', 'yx'});
    });
  });

  group('learningQueues', () {
    test('five cards with examples and five meanings run the whole '
        'eight_box chain, each stage in an order unlike the one before '
        '(IT-LEARN-001, IT-LEARN-004)', () {
      final ids = ['c1', 'c2', 'c3', 'c4', 'c5'];

      final queues = learningQueues(
        SchedulerType.eightBox,
        _cards(ids, withExample: ids.toSet()),
        distinctMeaningCount: 5,
        random: Random(2),
      );

      expect(
        [for (final queue in queues) queue.mode],
        [
          StudyMode.browse,
          StudyMode.match,
          StudyMode.guess,
          StudyMode.recall,
          StudyMode.fill,
        ],
      );
      for (final queue in queues) {
        expect([...queue.cardIds]..sort(), ids);
      }
      for (var i = 1; i < queues.length; i++) {
        expect(queues[i].cardIds, isNot(queues[i - 1].cardIds));
      }
    });

    test('a stage that does not run has no queue, and fill asks only the '
        'cards with an example (BR-MODE-009, BR-STUDY-071)', () {
      final queues = learningQueues(
        SchedulerType.eightBox,
        _cards(['c1', 'c2', 'c3'], withExample: {'c2'}),
        distinctMeaningCount: 3,
        random: Random(2),
      );

      expect(
        [for (final queue in queues) queue.mode],
        [StudyMode.browse, StudyMode.match, StudyMode.recall, StudyMode.fill],
      );
      expect(queues.last.cardIds, ['c2']);
    });

    test('an sm2 set runs browse, then self_assess (BR-MODE-004)', () {
      final queues = learningQueues(
        SchedulerType.sm2,
        _cards(['c1']),
        distinctMeaningCount: 1,
        random: Random(2),
      );

      expect(
        [for (final queue in queues) queue.mode],
        [StudyMode.browse, StudyMode.selfAssess],
      );
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/settings/data/root_study_options_repository_test.dart \
  test/features/study/data/open_learning_session_test.dart \
  test/features/study/domain/open_session_use_cases_test.dart \
  test/features/study/domain/queue_plan_model_test.dart \
  test/architecture
```

Expected: `+26 -4: Some tests failed.` The architecture tests pass; the four changed test files do not compile. The first errors: `Error: 'StudyRejection' isn't a type.`, `Error: Method not found: 'shuffledUnlike'.`, `Error: The method 'studyOptionsOf' isn't defined for the type 'SettingsRepositoryImpl'.`

- [ ] **Step 3: Read the study options once, inside a transaction**

In `lib/features/settings/data/datasources/settings_dao.dart`:

Replace

```dart
  Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId) {
    final deck = _db.deck;
```

with

```dart
  Stream<(Deck, AppSetting)?> watchRootAndSettings(String deckId) {
    final (query, read) = _rootAndSettings(deckId);
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : read(row),
    );
  }

  /// [watchRootAndSettings] read once.
  Future<(Deck, AppSetting)?> rootAndSettings(String deckId) async {
    final (query, read) = _rootAndSettings(deckId);
    final row = await query.getSingleOrNull();
    return row == null ? null : read(row);
  }

  (Selectable<TypedResult>, (Deck, AppSetting) Function(TypedResult))
  _rootAndSettings(String deckId) {
    final deck = _db.deck;
```

Replace

```dart
    ])..where(deck.id.equals(deckId) & deck.deleteBatchId.isNull());
    return query.watchSingleOrNull().map(
      (row) =>
          row == null ? null : (row.readTable(root), row.readTable(settings)),
    );
  }
```

with

```dart
    ])..where(deck.id.equals(deckId) & deck.deleteBatchId.isNull());
    return (query, (row) => (row.readTable(root), row.readTable(settings)));
  }
```

In `lib/features/settings/data/repositories/settings_repository_impl.dart`:

Replace

```dart
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
      _dao
          .watchRootAndSettings(deckId)
          .map(
            (rows) => switch (rows) {
              (final Deck root, final AppSetting settings) =>
                effectiveStudyOptionsOf(root, settings),
              null => null,
            },
          )
          .mapDatabaseErrors();

```

with

```dart
  Stream<EffectiveStudyOptions?> watchStudyOptions({required String deckId}) =>
      _dao.watchRootAndSettings(deckId).map(_effectiveOf).mapDatabaseErrors();

  @override
  Future<EffectiveStudyOptions?> studyOptionsOf({required String deckId}) =>
      _mapped(() async => _effectiveOf(await _dao.rootAndSettings(deckId)));

```

Replace

```dart

  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}
```

with

```dart

  Future<T> _write<T>(Future<T> Function() body) =>
      _mapped(() => _db.transaction(body));

  /// [body], with an unexpected database error leaving as its [Failure].
  Future<T> _mapped<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

EffectiveStudyOptions? _effectiveOf((Deck, AppSetting)? rows) => switch (rows) {
  (final Deck root, final AppSetting settings) => effectiveStudyOptionsOf(
    root,
    settings,
  ),
  null => null,
};
```

In `lib/features/settings/domain/repositories/settings_repository.dart`:

Replace

```dart

  /// Gives the root [rootDeckId] options of its own, for the sessions opened
```

with

```dart

  /// [watchStudyOptions] read once, for the study session that opens with
  /// them (BR-STUDY-024). Joins the caller's transaction.
  Future<EffectiveStudyOptions?> studyOptionsOf({required String deckId});

  /// Gives the root [rootDeckId] options of its own, for the sessions opened
```

- [ ] **Step 4: Write the study vocabulary and the learning queue plan**

Create `lib/features/study/domain/failures/study_failure.dart`:

```dart
/// Why the study feature refuses an operation (ADR-011 D6).
enum StudyRejection {
  /// The deck, the session or the card is gone, or in the Trash.
  notFound,

  /// The deck and its subtree hold no card still to learn.
  nothingToLearn,

  /// The deck and its subtree hold no due card (BR-STUDY-054).
  nothingDue,

  /// The mode is not one the root's algorithm offers for a review
  /// (BR-STUDY-055).
  modeNotOffered,

  /// The mode cannot run on the cards a review would take (BR-MODE-009).
  modeUnavailable,

  /// A review that takes a direction was asked without one: a validation
  /// error (BR-MODE-018).
  directionRequired,

  /// A direction was given where none is taken: a conflict (BR-MODE-018).
  directionNotAllowed,

  /// The session has ended.
  sessionClosed,

  /// The session was opened on an earlier local day (BR-STUDY-072).
  sessionExpired,

  /// The root was reset after the session opened (BR-STUDY-017).
  staleGeneration,

  /// The answer names a card the session is not serving.
  notCurrentCard,

  /// The answer is of another mode's kind.
  answerDoesNotFitMode,

  /// The action is not in the scheduler's `supportedActions` (BR-STUDY-009).
  unsupportedAction,
}
```

Create `lib/features/study/domain/models/queue_plan_model.dart`:

```dart
import 'dart:math';

import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The first round of one stage: its mode and its cards in serving order
/// (BR-STUDY-022).
final class StageQueue {
  const StageQueue(this.mode, this.cardIds);

  final StudyMode mode;
  final List<String> cardIds;
}

/// The cards a learning session takes (UC-STUDY-001 step 3): at most
/// [options]' `card_limit` of [candidates], which come oldest first. `created`
/// takes the oldest, `random` draws with [random] (BR-STUDY-003,
/// BR-STUDY-057). The order only chooses the set: every stage shuffles it
/// again (IT-STUDY-012).
List<StudyCardFacts> newCardsToLearn(
  List<StudyCardFacts> candidates,
  StudyOptions options,
  Random random,
) {
  final ordered = switch (options.newCardOrder) {
    NewCardOrder.created => candidates,
    NewCardOrder.random => [...candidates]..shuffle(random),
  };
  return ordered.take(options.cardLimit).toList();
}

/// Round 1 of every stage of a learning session over [cards], all built
/// when the session opens so the queue never changes under it (BR-STUDY-021;
/// spec D7). A stage that cannot run has no queue (BR-MODE-009), a card a
/// stage cannot ask is left out of that stage only (BR-STUDY-071), and each
/// stage is shuffled on its own, unlike the stage before it (BR-STUDY-022).
List<StageQueue> learningQueues(
  SchedulerType type,
  List<StudyCardFacts> cards, {
  required int distinctMeaningCount,
  required Random random,
}) {
  final queues = <StageQueue>[];
  for (final mode in stageSequenceOf(type)) {
    final eligibility = mode.handler.eligibility(
      cards,
      distinctMeaningCount: distinctMeaningCount,
    );
    if (eligibility case StageRuns(:final cardIds)) {
      final previous = queues.isEmpty ? const <String>[] : queues.last.cardIds;
      queues.add(StageQueue(mode, shuffledUnlike(cardIds, previous, random)));
    }
  }
  return queues;
}

/// [cardIds] shuffled with [random], never in the order [previous] gave the
/// same cards (BR-STUDY-022, BR-STUDY-061): when two or more cards are in
/// both and the shuffle kept their order, the first two of them swap.
List<String> shuffledUnlike(
  List<String> cardIds,
  List<String> previous,
  Random random,
) {
  final order = [...cardIds]..shuffle(random);
  final before = previous.toSet();
  final shared = [
    for (final id in order)
      if (before.contains(id)) id,
  ];
  final kept = shared.toSet();
  final earlier = [
    for (final id in previous)
      if (kept.contains(id)) id,
  ];
  if (shared.length < 2 || !_sameOrder(shared, earlier)) return order;
  final first = order.indexOf(shared[0]);
  final second = order.indexOf(shared[1]);
  order[first] = shared[1];
  order[second] = shared[0];
  return order;
}

bool _sameOrder(List<String> a, List<String> b) {
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

Create `lib/features/study/domain/models/session_status_model.dart`:

```dart
/// Where a session is in its life, stored as a stable text code on
/// `study_session.status` (BR-STUDY-010). Every status but [inProgress] is
/// final.
enum SessionStatus {
  inProgress('in_progress'),
  completed('completed'),
  abandoned('abandoned'),
  invalidated('invalidated'),
  failed('failed');

  const SessionStatus(this.code);

  final String code;

  static SessionStatus fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    throw ArgumentError.value(code, 'code', 'unknown session status');
  }
}

/// Why a session ended other than by finishing its queue, stored on
/// `study_session.end_reason` (BR-STUDY-012; schema.md's status matrix).
enum SessionEndReason {
  userExit('user_exit'),
  interrupted('interrupted'),
  schedulerReset('scheduler_reset'),
  schedulerChanged('scheduler_changed'),
  staleGeneration('stale_generation'),
  persistenceError('persistence_error'),
  contentDeleted('content_deleted');

  const SessionEndReason(this.code);

  final String code;

  static SessionEndReason fromCode(String code) {
    for (final reason in values) {
      if (reason.code == code) return reason;
    }
    throw ArgumentError.value(code, 'code', 'unknown session end reason');
  }
}
```

- [ ] **Step 5: Open the session in the entry repository**

Create `lib/features/study/data/datasources/study_queue_dao.dart`:

```dart
import 'package:memox/core/database/app_database.dart';

/// `study_queue_items.status` of a row still to serve (BR-STUDY-007).
const _pending = 'pending';

/// Row access for `study_queue_items`. It returns Drift rows and card ids,
/// never domain values, and runs inside the caller's transaction.
final class StudyQueueDao {
  StudyQueueDao(this._db);

  final AppDatabase _db;

  /// Round 1 of [mode]: [cardIds] in serving order.
  Future<void> insertFirstRound(
    String sessionId,
    String mode,
    List<String> cardIds,
  ) => _db.batch(
    (batch) => batch.insertAll(_db.studyQueueItems, [
      for (final (position, cardId) in cardIds.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          cardId: cardId,
          position: position,
          status: _pending,
        ),
    ]),
  );
}
```

Create `lib/features/study/data/datasources/study_session_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';

/// A card a session can take, as the data conditions read it.
typedef StudyCardRow = ({String cardId, bool hasExample});

/// Row access for `study_session`, plus the reads of `deck`, `card` and
/// `card_schedule` a session is built from. It returns Drift rows and
/// records, never domain values, and runs inside the caller's transaction.
final class StudySessionDao {
  StudySessionDao(this._db);

  final AppDatabase _db;

  /// The deck [id] names, unless it is in the Trash.
  Future<Deck?> deckRow(String id) =>
      (_db.select(_db.deck)
            ..where((deck) => deck.id.equals(id) & deck.deleteBatchId.isNull()))
          .getSingleOrNull();

  /// The active cards of [deckId] and its whole subtree that are not learned
  /// yet, oldest first (BR-STUDY-051, BR-STUDY-057).
  Future<List<StudyCardRow>> newCards(String deckId) => _subtreeCards(
    deckId,
    where: 'cs.learned_at IS NULL',
    orderBy: 'c.created_at, c.id',
  );

  /// The active cards of [deckId]'s subtree matching [where], in [orderBy]
  /// order. The subtree is walked through `parent_id` (schema.md "Duyệt cây").
  Future<List<StudyCardRow>> _subtreeCards(
    String deckId, {
    required String where,
    required String orderBy,
    List<Variable<Object>> variables = const [],
  }) async {
    final rows = await _db
        .customSelect(
          'WITH RECURSIVE subtree(id) AS ('
          ' SELECT id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
          ' UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
          ' WHERE d.delete_batch_id IS NULL)'
          ' SELECT c.id, c.example IS NOT NULL AS has_example FROM card c'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.deck_id IN (SELECT id FROM subtree)'
          ' AND c.delete_batch_id IS NULL AND $where'
          ' ORDER BY $orderBy',
          variables: [Variable<String>(deckId), ...variables],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule},
        )
        .get();
    return [
      for (final row in rows)
        (
          cardId: row.read<String>('id'),
          hasExample: row.read<bool>('has_example'),
        ),
    ];
  }

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
  /// learned, active cards of [rootId]'s tree: the distractor source of
  /// `guess` (BR-STUDY-038; spec D5).
  Future<int> distinctMeaningCount(
    String rootId,
    List<String> sessionCardIds,
  ) async {
    final placeholders = List.filled(sessionCardIds.length, '?').join(', ');
    final row = await _db
        .customSelect(
          'SELECT COUNT(DISTINCT c.back_folded) AS n FROM card c'
          ' JOIN deck d ON d.id = c.deck_id'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE d.root_id = ? AND c.delete_batch_id IS NULL'
          ' AND d.delete_batch_id IS NULL'
          ' AND (cs.learned_at IS NOT NULL OR c.id IN ($placeholders))',
          variables: [
            Variable<String>(rootId),
            for (final id in sessionCardIds) Variable<String>(id),
          ],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule},
        )
        .getSingle();
    return row.read<int>('n');
  }

  /// Ends every open session: `user_exit` when it started on or after
  /// [startOfToday], `interrupted` when it started on an earlier local day
  /// (BR-STUDY-072; spec D2).
  Future<void> closeOpenSessions({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.customUpdate(
    'UPDATE study_session SET status = ?, ended_at = ?,'
    ' end_reason = CASE WHEN started_at >= ? THEN ? ELSE ? END'
    ' WHERE status = ?',
    variables: [
      Variable<String>(SessionStatus.abandoned.code),
      Variable<DateTime>(now),
      Variable<DateTime>(startOfToday),
      Variable<String>(SessionEndReason.userExit.code),
      Variable<String>(SessionEndReason.interrupted.code),
      Variable<String>(SessionStatus.inProgress.code),
    ],
    updates: {_db.studySession},
    updateKind: UpdateKind.update,
  );

  Future<void> insertSession(StudySessionCompanion row) =>
      _db.into(_db.studySession).insert(row);
}
```

Create `lib/features/study/data/repositories/study_entry_repository_impl.dart`:

```dart
import 'dart:math';

import 'package:drift/drift.dart' show Value;
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/settings/domain/repositories/settings_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

/// Opens sessions on a deck (UC-STUDY-001 steps 3–5, UC-STUDY-003). Every
/// write is one transaction, which the settings reads it makes join: the
/// rules read the rows as they are at the moment of writing, and a
/// refusal writes nothing.
final class StudyEntryRepositoryImpl implements StudyEntryRepository {
  StudyEntryRepositoryImpl(
    this._db,
    this._settings, {
    DateTime Function()? now,
    Random? random,
  }) : _dao = StudySessionDao(_db),
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  final AppDatabase _db;
  final SettingsRepository _settings;
  final StudySessionDao _dao;
  final StudyQueueDao _queue;
  final DateTime Function() _now;

  /// Every shuffle and draw of a session (BR-STUDY-022, BR-STUDY-057).
  final Random _random;

  @override
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final scope = await _scope(deckId);
      if (scope == null) return const Rejected(StudyRejection.notFound);
      final (root, options) = scope;
      final candidates = _factsOf(await _dao.newCards(deckId));
      if (candidates.isEmpty) {
        return const Rejected(StudyRejection.nothingToLearn);
      }

      final cards = newCardsToLearn(candidates, options, _random);
      final queues = learningQueues(
        SchedulerType.fromCode(root.schedulerType!),
        cards,
        distinctMeaningCount: await _meaningsOf(root, cards),
        random: _random,
      );
      return Ok(
        await _open(
          deckId: deckId,
          root: root,
          kind: SessionKind.learning,
          cardLimit: options.cardLimit,
          queues: queues,
          at: at,
        ),
      );
    });
  }

  /// The root of [deckId] and the options it studies with; null when the
  /// deck is gone or in the Trash.
  Future<(Deck, StudyOptions)?> _scope(String deckId) async {
    final deck = await _dao.deckRow(deckId);
    final options = await _settings.studyOptionsOf(deckId: deckId);
    if (deck == null || options == null) return null;
    final root = await _dao.deckRow(deck.rootId);
    if (root == null) return null;
    return (root, options.options);
  }

  /// The distinct meanings the `guess` stage can draw from (spec D5).
  Future<int> _meaningsOf(Deck root, List<StudyCardFacts> cards) => _dao
      .distinctMeaningCount(root.id, [for (final card in cards) card.cardId]);

  /// Closes the app's open session (spec D2), then writes the new session
  /// and round 1 of its [queues], the first of which it starts in.
  Future<String> _open({
    required String deckId,
    required Deck root,
    required SessionKind kind,
    required int cardLimit,
    required List<StageQueue> queues,
    required DateTime at,
  }) async {
    await _dao.closeOpenSessions(now: at, startOfToday: startOfLocalDay(at));
    final id = newId();
    await _dao.insertSession(
      StudySessionCompanion.insert(
        id: id,
        deckId: deckId,
        rootId: root.id,
        generation: root.generation!,
        sessionKind: kind.name,
        currentMode: queues.first.mode.code,
        status: SessionStatus.inProgress.code,
        cardLimit: Value(cardLimit),
        startedAt: at,
      ),
    );
    for (final queue in queues) {
      await _queue.insertFirstRound(id, queue.mode.code, queue.cardIds);
    }
    return id;
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

/// The cards [rows] name, as the study modes read them.
List<StudyCardFacts> _factsOf(List<StudyCardRow> rows) => [
  for (final row in rows)
    StudyCardFacts(cardId: row.cardId, hasExample: row.hasExample),
];
```

Create `lib/features/study/di/study_entry_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/settings/di/settings_repository_provider.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_entry_repository_provider.g.dart';

@riverpod
StudyEntryRepository studyEntryRepository(Ref ref) => StudyEntryRepositoryImpl(
  ref.watch(databaseProvider),
  ref.watch(settingsRepositoryProvider),
);
```

Create `lib/features/study/domain/repositories/study_entry_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';

/// The one implementation is `StudyEntryRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class StudyEntryRepository {
  /// UC-STUDY-001 steps 3 and 5: a learning session on the new cards of
  /// [deckId] and its whole subtree (BR-STUDY-051), at most `card_limit` of
  /// them chosen by `new_card_order` (BR-STUDY-003, BR-STUDY-057), with round
  /// 1 of every stage it runs (BR-STUDY-021, BR-STUDY-022). It closes the
  /// app's open session first (BR-STUDY-072; spec D2). Answers the session's
  /// id; notFound for a deck that is gone or in the Trash, nothingToLearn when
  /// no card is new, and a refusal writes nothing.
  Future<Outcome<String, StudyRejection>> openLearningSession({
    required String deckId,
    DateTime? now,
  });
}
```

Create `lib/features/study/domain/usecases/open_learning_session_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';

/// UC-STUDY-001 step 3: Learn new, the only way a learning session is
/// created (BR-STUDY-020). Answers the new session's id.
final class OpenLearningSessionUseCase {
  const OpenLearningSessionUseCase(this._entries);

  final StudyEntryRepository _entries;

  Future<Outcome<String, StudyRejection>> call({required String deckId}) =>
      _entries.openLearningSession(deckId: deckId);
}
```

- [ ] **Step 6: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner`, and the new `*_provider.g.dart` exists next to its provider.

- [ ] **Step 7: Record the one open session in schema.md**

In `docs/shared/data/schema.md`:

Replace

```markdown
gộp chúng làm lịch sử nói rằng người dùng bỏ cuộc trong khi họ không hề.

```

with

```markdown
gộp chúng làm lịch sử nói rằng người dùng bỏ cuộc trong khi họ không hề.

**Một phiên mở trong toàn app** (quyết định chủ dự án 2026-09-24): app có tối đa một
session `in_progress`. Mở phiên mới, ở bất kỳ deck nào, đóng phiên đang mở trước trong
cùng transaction: `abandoned`/`user_exit` nếu nó bắt đầu trong ngày học hiện tại,
`abandoned`/`interrupted` nếu nó bắt đầu từ ngày học trước (BR-STUDY-072). Code và test
giữ luật này; một unique index sẽ cần migration, và migration chờ BE-D1.

```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/settings/data/root_study_options_repository_test.dart \
  test/features/study/data/open_learning_session_test.dart \
  test/features/study/domain/open_session_use_cases_test.dart \
  test/features/study/domain/queue_plan_model_test.dart \
  test/architecture
```

Expected: `+61: All tests passed!`

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

Expected: `No issues found!`; `+1072: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  docs/shared/data/schema.md \
  lib/features/settings/data/datasources/settings_dao.dart \
  lib/features/settings/data/repositories/settings_repository_impl.dart \
  lib/features/settings/domain/repositories/settings_repository.dart \
  lib/features/study/data/datasources/study_queue_dao.dart \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/repositories/study_entry_repository_impl.dart \
  lib/features/study/di/study_entry_repository_provider.dart \
  lib/features/study/domain/failures/study_failure.dart \
  lib/features/study/domain/models/queue_plan_model.dart \
  lib/features/study/domain/models/session_status_model.dart \
  lib/features/study/domain/repositories/study_entry_repository.dart \
  lib/features/study/domain/usecases/open_learning_session_use_case.dart \
  test/architecture/boundary_rules.dart \
  test/features/settings/data/root_study_options_repository_test.dart \
  test/features/study/data/open_learning_session_test.dart \
  test/features/study/domain/open_session_use_cases_test.dart \
  test/features/study/domain/queue_plan_model_test.dart \
  test/support/card_fixtures.dart \
  test/support/study_fixtures.dart
git commit -F - <<'EOF'
feat(study): open a learning session on a deck tree

A learning session takes up to card_limit new cards of the deck and its
subtree, oldest first or drawn (BR-STUDY-003, BR-STUDY-057), and writes
round 1 of every stage they can run, each in an order unlike the one before
(BR-STUDY-021, BR-STUDY-022). Opening closes the app's open session first,
user_exit today and interrupted from an earlier day (BR-STUDY-072; one open
session in the app). The settings read the options once inside the
transaction.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: Open a review session in one mode, with a direction for sm2

**Files:**
- Create: `lib/features/study/domain/usecases/open_review_session_use_case.dart`
- Modify: `lib/features/study/data/datasources/study_queue_dao.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/repositories/study_entry_repository_impl.dart`, `lib/features/study/domain/models/queue_plan_model.dart`, `lib/features/study/domain/repositories/study_entry_repository.dart`
- Test (create): `test/features/study/data/open_review_session_test.dart`
- Test (modify): `test/features/study/domain/open_session_use_cases_test.dart`, `test/features/study/domain/queue_plan_model_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 3; `acceptsDirection`, `assignDirections` (Task 2).
- Produces:
  - `StageQueue(mode, cardIds, {List<QuestionDirection>? directions})`.
  - `reviewQueue(SchedulerType type, StudyMode mode, {required DirectionChoice? direction, required List<StudyCardFacts> dueCards, required int distinctMeaningCount, required Random random})` —
    `Outcome<StageQueue, StudyRejection>`.
  - `StudyEntryRepository.openReviewSession({required String deckId, required StudyMode mode, DirectionChoice? direction, DateTime? now})` —
    `Future<Outcome<String, StudyRejection>>`.
  - `StudySessionDao.dueCards(String deckId, DateTime now)`;
    `StudyQueueDao.insertFirstRound(..., {List<String>? directions})`.
  - `OpenReviewSessionUseCase(StudyEntryRepository entries)` —
    `call({required String deckId, required StudyMode mode, DirectionChoice? direction})`.

Spec §7.1, §7.2, §5.6 and D10; Clarification 3. A review takes the first
`card_limit` due cards in due order and runs one mode; `self_assess` of an
`sm2` deck takes a direction, stored on the session and, card by card, on its
rows (BR-MODE-013, BR-MODE-015, BR-MODE-018).

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/data/open_review_session_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 step 4 and UC-STUDY-003: opening a review session.

Matcher _refusedWith(StudyRejection reason) =>
    isA<Rejected<String, StudyRejection>>().having(
      (rejected) => rejected.reason,
      'reason',
      reason,
    );

String _opened(Outcome<String, StudyRejection> result) => switch (result) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('opening refused: $reason'),
};

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A root [name] running [scheduler] and its sub-deck `Lesson`.
  Future<(DeckEntity, DeckEntity)> tree([
    SchedulerType scheduler = SchedulerType.eightBox,
    String name = 'Korean',
  ]) async {
    final root = await decks.root(name, scheduler);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  /// A learned card of [deckId] due at [dueAt], of its own meaning, and the
  /// lock its learning left on [rootId] (BR-SRS-003).
  Future<void> learned(
    String rootId,
    String deckId,
    String id,
    DateTime dueAt, {
    bool withExample = false,
  }) async {
    await insertCard(
      db,
      id: id,
      deckId: deckId,
      back: 'meaning of $id',
      example: withExample ? 'example of $id' : null,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: dueAt,
    );
    await lockScheduler(db, rootId);
  }

  Future<List<String?>> directionsOf(String sessionId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT direction FROM study_queue_items WHERE session_id = ? '
              'ORDER BY position',
              variables: [Variable(sessionId)],
            )
            .get())
      row.read<String?>('direction'),
  ];

  test('a review takes the due cards of the subtree, earliest due first, up '
      'to the limit, in the mode picked (IT-REVIEW-001, IT-REVIEW-002, '
      'IT-REVIEW-004, BR-STUDY-002)', () async {
    final (root, leaf) = await tree();
    for (final (id, day) in [('d4', 23), ('d1', 20), ('d3', 22), ('d2', 21)]) {
      await learned(root.id, leaf.id, id, DateTime(2026, 9, day));
    }
    await learned(root.id, leaf.id, 'later', DateTime(2026, 9, 25));
    await insertCard(db, id: 'new', deckId: leaf.id);
    await SettingsRepositoryImpl(db, now: () => now).saveRootStudyOptions(
      rootDeckId: root.id,
      options: const StudyOptions(
        cardLimit: 3,
        newCardOrder: NewCardOrder.created,
      ),
    );

    final id = _opened(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.recall),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('session_kind'), 'reviewing');
    expect(session.read<String>('current_mode'), 'recall');
    expect(session.read<int>('card_limit'), 3);
    expect(session.data['direction'], isNull);
    expect(await modesOf(db, id), ['recall']);
    expect(await queueOf(db, id, 'recall'), ['d1', 'd2', 'd3']);
  });

  test('fill reviews the due cards with an example, and a mode that cannot '
      'run on the due cards is refused (BR-STUDY-044, BR-MODE-009; '
      'IT-STUDY-006, IT-STUDY-007)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    await learned(
      root.id,
      leaf.id,
      'b',
      DateTime(2026, 9, 21),
      withExample: true,
    );
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.guess),
      _refusedWith(StudyRejection.modeUnavailable),
    );
    expect(await totalChanges(db), before);
    final id = _opened(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.fill),
    );
    expect(await queueOf(db, id, 'fill'), ['b']);
  });

  test('match needs two due cards (BR-STUDY-045)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));

    expect(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.match),
      _refusedWith(StudyRejection.modeUnavailable),
    );
  });

  test('a mode the algorithm does not offer for a review is refused '
      '(BR-STUDY-055)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    final (sm2Root, sm2Leaf) = await tree(SchedulerType.sm2, 'Other');
    await learned(sm2Root.id, sm2Leaf.id, 's', DateTime(2026, 9, 20));

    for (final (deckId, mode) in [
      (root.id, StudyMode.browse),
      (root.id, StudyMode.selfAssess),
      (sm2Root.id, StudyMode.recall),
    ]) {
      expect(
        await entries.openReviewSession(deckId: deckId, mode: mode),
        _refusedWith(StudyRejection.modeNotOffered),
      );
    }
  });

  test('nothing due is refused, writing nothing: no review before its time '
      '(BR-STUDY-054; IT-STUDY-003, IT-REVIEW-008)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'later', DateTime(2026, 9, 25));
    await insertCard(db, id: 'new', deckId: leaf.id);
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.recall),
      _refusedWith(StudyRejection.nothingDue),
    );
    expect(await totalChanges(db), before);
  });

  test('an sm2 review needs a direction: none is a validation error that '
      'writes nothing (BR-MODE-013, BR-MODE-018; UC-STUDY-003 E3)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.selfAssess,
      ),
      _refusedWith(StudyRejection.directionRequired),
    );
    expect(await totalChanges(db), before);
  });

  test('a direction where none is taken is a conflict that writes nothing '
      '(BR-MODE-013, BR-MODE-018)', () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    final before = await totalChanges(db);

    expect(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.recall,
        direction: DirectionChoice.koreanToMeaning,
      ),
      _refusedWith(StudyRejection.directionNotAllowed),
    );
    expect(await totalChanges(db), before);
  });

  test('a fixed direction is stored on the session and on every row '
      '(BR-MODE-015, BR-MODE-016; UC-STUDY-003 step 5)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await learned(root.id, leaf.id, id, DateTime(2026, 9, day));
    }

    final id = _opened(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.meaningToKorean,
      ),
    );

    expect(
      (await sessionOf(db, id)).read<String>('direction'),
      'meaning_to_korean',
    );
    expect(await directionsOf(id), ['meaning_to_korean', 'meaning_to_korean']);
  });

  test('mixed gives each row one direction, split evenly, and stores mixed '
      'on the session only (BR-MODE-015)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final (id, day) in [('a', 20), ('b', 21), ('c', 22)]) {
      await learned(root.id, leaf.id, id, DateTime(2026, 9, day));
    }

    final id = _opened(
      await entries.openReviewSession(
        deckId: root.id,
        mode: StudyMode.selfAssess,
        direction: DirectionChoice.mixed,
      ),
    );

    expect((await sessionOf(db, id)).read<String>('direction'), 'mixed');
    final directions = await directionsOf(id);
    expect(directions, isNot(contains('mixed')));
    final koreanFirst = directions
        .where((direction) => direction == 'korean_to_meaning')
        .length;
    expect(koreanFirst, anyOf(1, 2));
    expect(directions, hasLength(3));
  });

  test('a review closes the open learning session of the same day as the '
      "person's exit (IT-CONT-014, spec D2)", () async {
    final (root, leaf) = await tree();
    await learned(root.id, leaf.id, 'a', DateTime(2026, 9, 20));
    await insertCard(db, id: 'new', deckId: leaf.id);
    final learning = _opened(
      await entries.openLearningSession(deckId: leaf.id),
    );

    final review = _opened(
      await entries.openReviewSession(deckId: leaf.id, mode: StudyMode.recall),
    );

    final closed = await sessionOf(db, learning);
    expect(closed.read<String>('status'), 'abandoned');
    expect(closed.read<String>('end_reason'), 'user_exit');
    expect(
      (await sessionOf(db, review)).read<String>('session_kind'),
      'reviewing',
    );
  });
}
```

In `test/features/study/domain/open_session_use_cases_test.dart`:

Replace

```dart
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/open_learning_session_use_case.dart';

```

with

```dart
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/open_learning_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/open_review_session_use_case.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

Replace

```dart
      isA<Rejected<String, StudyRejection>>(),
    );
  });
}
```

with

```dart
      isA<Rejected<String, StudyRejection>>(),
    );
  });

  test('OpenReviewSession opens a review in the mode picked, with the '
      'direction chosen (UC-STUDY-001 step 4, UC-STUDY-003 step 5)', () async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 20),
    );
    await lockScheduler(db, root.id);
    final open = OpenReviewSessionUseCase(studyEntryRepository(db, () => now));

    final result = await open(
      deckId: leaf.id,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.koreanToMeaning,
    );

    final id = (result as Ok<String, StudyRejection>).value;
    final session = await sessionOf(db, id);
    expect(session.read<String>('session_kind'), 'reviewing');
    expect(session.read<String>('direction'), 'korean_to_meaning');
  });
}
```

In `test/features/study/domain/queue_plan_model_test.dart`:

Replace

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
```

with

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
```

Replace

```dart
        [StudyMode.browse, StudyMode.selfAssess],
      );
    });
  });
}
```

with

```dart
        [StudyMode.browse, StudyMode.selfAssess],
      );
    });
  });

  group('reviewQueue', () {
    Outcome<StageQueue, StudyRejection> review(
      SchedulerType type,
      StudyMode mode, {
      DirectionChoice? direction,
      List<String> due = const ['c1', 'c2'],
    }) => reviewQueue(
      type,
      mode,
      direction: direction,
      dueCards: _cards(due),
      distinctMeaningCount: 2,
      random: Random(1),
    );

    StudyRejection? refusal(Outcome<StageQueue, StudyRejection> result) =>
        switch (result) {
          Rejected(:final reason) => reason,
          Ok() => null,
        };

    test('it checks the request before the cards: the mode, the direction, '
        'then the due cards and the stage (BR-STUDY-055, BR-MODE-018, '
        'BR-STUDY-054, BR-MODE-009)', () {
      expect(
        refusal(review(SchedulerType.sm2, StudyMode.browse, due: [])),
        StudyRejection.modeNotOffered,
      );
      expect(
        refusal(review(SchedulerType.sm2, StudyMode.selfAssess, due: [])),
        StudyRejection.directionRequired,
      );
      expect(
        refusal(
          review(
            SchedulerType.eightBox,
            StudyMode.recall,
            direction: DirectionChoice.mixed,
            due: [],
          ),
        ),
        StudyRejection.directionNotAllowed,
      );
      expect(
        refusal(review(SchedulerType.eightBox, StudyMode.fill, due: [])),
        StudyRejection.nothingDue,
      );
      expect(
        refusal(review(SchedulerType.eightBox, StudyMode.fill)),
        StudyRejection.modeUnavailable,
      );
    });

    test('round 1 keeps the due order, with one direction per card when the '
        'review takes one (BR-STUDY-002, BR-MODE-015)', () {
      final selfAssess = review(
        SchedulerType.sm2,
        StudyMode.selfAssess,
        direction: DirectionChoice.meaningToKorean,
        due: ['c2', 'c1'],
      );
      final recall = review(SchedulerType.eightBox, StudyMode.recall);

      final queue = (selfAssess as Ok<StageQueue, StudyRejection>).value;
      expect(queue.cardIds, ['c2', 'c1']);
      expect(queue.directions, [
        QuestionDirection.meaningToKorean,
        QuestionDirection.meaningToKorean,
      ]);
      expect(
        (recall as Ok<StageQueue, StudyRejection>).value.directions,
        isNull,
      );
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/open_review_session_test.dart \
  test/features/study/domain/open_session_use_cases_test.dart \
  test/features/study/domain/queue_plan_model_test.dart
```

Expected: `+0 -3: Some tests failed.` None of the three files compiles. The first errors: `Error: The method 'openReviewSession' isn't defined for the type 'StudyEntryRepositoryImpl'.`, `Error: The getter 'directions' isn't defined for the type 'StageQueue'.`, `Error: Error when reading 'lib/features/study/domain/usecases/open_review_session_use_case.dart': No such file or directory`

- [ ] **Step 3: Plan round 1 of a review in the domain**

In `lib/features/study/domain/models/queue_plan_model.dart`:

Replace

```dart

import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
```

with

```dart

import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
```

Replace

```dart

/// The first round of one stage: its mode and its cards in serving order
/// (BR-STUDY-022).
final class StageQueue {
  const StageQueue(this.mode, this.cardIds);

```

with

```dart

/// The first round of one stage: its mode, its cards in serving order
/// (BR-STUDY-022) and, in a review that takes one, each card's direction
/// (BR-MODE-015).
final class StageQueue {
  const StageQueue(this.mode, this.cardIds, {this.directions});

```

Replace

```dart
  final List<String> cardIds;
}
```

with

```dart
  final List<String> cardIds;

  /// One per card of [cardIds], in the same order; null when the session
  /// takes no direction (BR-MODE-013).
  final List<QuestionDirection>? directions;
}
```

Replace

```dart

/// [cardIds] shuffled with [random], never in the order [previous] gave the
```

with

```dart

/// Round 1 of a review in [mode] over [dueCards], which come earliest due
/// first (UC-STUDY-001 step 4, UC-STUDY-003). The request is checked before
/// the cards, and all before anything is written (spec §7.1): [mode] must be
/// a review mode of [type] (modeNotOffered, BR-STUDY-055) and [direction]
/// given exactly when BR-MODE-013 takes one (directionRequired,
/// directionNotAllowed, BR-MODE-018); then a card must be due (nothingDue,
/// BR-STUDY-054) and the stage must run on the cards (modeUnavailable,
/// BR-MODE-009). Round 1 keeps the due order (BR-STUDY-002), and with a
/// direction every card gets one (BR-MODE-015).
Outcome<StageQueue, StudyRejection> reviewQueue(
  SchedulerType type,
  StudyMode mode, {
  required DirectionChoice? direction,
  required List<StudyCardFacts> dueCards,
  required int distinctMeaningCount,
  required Random random,
}) {
  if (!reviewModesOf(type).contains(mode)) {
    return const Rejected(StudyRejection.modeNotOffered);
  }
  final takesDirection = acceptsDirection(SessionKind.reviewing, type, mode);
  if (takesDirection && direction == null) {
    return const Rejected(StudyRejection.directionRequired);
  }
  if (!takesDirection && direction != null) {
    return const Rejected(StudyRejection.directionNotAllowed);
  }
  if (dueCards.isEmpty) return const Rejected(StudyRejection.nothingDue);
  final eligibility = mode.handler.eligibility(
    dueCards,
    distinctMeaningCount: distinctMeaningCount,
  );
  if (eligibility is! StageRuns) {
    return const Rejected(StudyRejection.modeUnavailable);
  }
  final cardIds = eligibility.cardIds;
  return Ok(
    StageQueue(
      mode,
      cardIds,
      directions: direction == null
          ? null
          : assignDirections(cardIds.length, direction, random),
    ),
  );
}

/// [cardIds] shuffled with [random], never in the order [previous] gave the
```

- [ ] **Step 4: Open the review in the entry repository**

Replace the whole of `lib/features/study/data/datasources/study_queue_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// `study_queue_items.status` of a row still to serve (BR-STUDY-007).
const _pending = 'pending';

/// Row access for `study_queue_items`. It returns Drift rows and card ids,
/// never domain values, and runs inside the caller's transaction.
final class StudyQueueDao {
  StudyQueueDao(this._db);

  final AppDatabase _db;

  /// Round 1 of [mode]: [cardIds] in serving order, each with its entry of
  /// [directions] when there are directions (BR-MODE-015).
  Future<void> insertFirstRound(
    String sessionId,
    String mode,
    List<String> cardIds, {
    List<String>? directions,
  }) => _db.batch(
    (batch) => batch.insertAll(_db.studyQueueItems, [
      for (final (position, cardId) in cardIds.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          cardId: cardId,
          position: position,
          status: _pending,
          direction: Value(directions?[position]),
        ),
    ]),
  );
}
```

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart
    orderBy: 'c.created_at, c.id',
  );

  /// The active cards of [deckId]'s subtree matching [where], in [orderBy]
```

with

```dart
    orderBy: 'c.created_at, c.id',
  );

  /// The active learned cards of [deckId] and its whole subtree that are due
  /// at [now], earliest due first (BR-STUDY-001, BR-STUDY-002, BR-STUDY-051).
  Future<List<StudyCardRow>> dueCards(String deckId, DateTime now) =>
      _subtreeCards(
        deckId,
        where: 'cs.learned_at IS NOT NULL AND cs.due_at <= ?',
        orderBy: 'cs.due_at, c.created_at, c.id',
        variables: [Variable<DateTime>(now)],
      );

  /// The active cards of [deckId]'s subtree matching [where], in [orderBy]
```

In `lib/features/study/data/repositories/study_entry_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';

```

with

```dart
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

```

Replace

```dart

  /// The root of [deckId] and the options it studies with; null when the
```

with

```dart

  @override
  Future<Outcome<String, StudyRejection>> openReviewSession({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final scope = await _scope(deckId);
      if (scope == null) return const Rejected(StudyRejection.notFound);
      final (root, options) = scope;
      final due = _factsOf(await _dao.dueCards(deckId, at));
      final cards = due.take(options.cardLimit).toList();
      final planned = reviewQueue(
        SchedulerType.fromCode(root.schedulerType!),
        mode,
        direction: direction,
        dueCards: cards,
        distinctMeaningCount: await _meaningsOf(root, cards),
        random: _random,
      );
      switch (planned) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: final queue):
          return Ok(
            await _open(
              deckId: deckId,
              root: root,
              kind: SessionKind.reviewing,
              cardLimit: options.cardLimit,
              queues: [queue],
              direction: direction,
              at: at,
            ),
          );
      }
    });
  }

  /// The root of [deckId] and the options it studies with; null when the
```

Replace

```dart
  /// Closes the app's open session (spec D2), then writes the new session
  /// and round 1 of its [queues], the first of which it starts in.
  Future<String> _open({
```

with

```dart
  /// Closes the app's open session (spec D2), then writes the new session
  /// and round 1 of its [queues], the first of which it starts in, with the
  /// session's [direction] choice and each row's own direction (BR-MODE-015).
  Future<String> _open({
```

Replace

```dart
    required DateTime at,
  }) async {
```

with

```dart
    required DateTime at,
    DirectionChoice? direction,
  }) async {
```

Replace

```dart
        cardLimit: Value(cardLimit),
        startedAt: at,
```

with

```dart
        cardLimit: Value(cardLimit),
        direction: Value(direction?.code),
        startedAt: at,
```

Replace

```dart
    for (final queue in queues) {
      await _queue.insertFirstRound(id, queue.mode.code, queue.cardIds);
    }
```

with

```dart
    for (final queue in queues) {
      await _queue.insertFirstRound(
        id,
        queue.mode.code,
        queue.cardIds,
        directions: queue.directions
            ?.map((direction) => direction.code)
            .toList(),
      );
    }
```

In `lib/features/study/domain/repositories/study_entry_repository.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';

```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

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

  /// UC-STUDY-001 step 4 and UC-STUDY-003: a review in [mode] on the due
  /// cards of [deckId] and its whole subtree, at most `card_limit` of them,
  /// earliest due first (BR-STUDY-002, BR-STUDY-003, BR-STUDY-051). [mode]
  /// must be a review mode of the root's algorithm (modeNotOffered,
  /// BR-STUDY-055) that can run on those cards (modeUnavailable,
  /// BR-MODE-009); [direction] must be given exactly when BR-MODE-013 takes
  /// one (directionRequired, directionNotAllowed, BR-MODE-018). nothingDue
  /// when no card is due (BR-STUDY-054). It closes the app's open session
  /// first (spec D2); a refusal writes nothing.
  Future<Outcome<String, StudyRejection>> openReviewSession({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
    DateTime? now,
  });
}
```

- [ ] **Step 5: Write the use case**

Create `lib/features/study/domain/usecases/open_review_session_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// UC-STUDY-001 step 4 and UC-STUDY-003 step 5: Review in the mode picked,
/// with the direction chosen when the mode takes one (BR-MODE-013). Answers
/// the new session's id.
final class OpenReviewSessionUseCase {
  const OpenReviewSessionUseCase(this._entries);

  final StudyEntryRepository _entries;

  Future<Outcome<String, StudyRejection>> call({
    required String deckId,
    required StudyMode mode,
    DirectionChoice? direction,
  }) => _entries.openReviewSession(
    deckId: deckId,
    mode: mode,
    direction: direction,
  );
}
```

- [ ] **Step 6: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 7: Run the task's tests**

```bash
flutter test test/features/study/data/open_review_session_test.dart \
  test/features/study/domain/open_session_use_cases_test.dart \
  test/features/study/domain/queue_plan_model_test.dart
```

Expected: `+22: All tests passed!`

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

Expected: `No issues found!`; `+1085: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 9: Commit**

```bash
git add docs/_generated \
  lib/features/study/data/datasources/study_queue_dao.dart \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/repositories/study_entry_repository_impl.dart \
  lib/features/study/domain/models/queue_plan_model.dart \
  lib/features/study/domain/repositories/study_entry_repository.dart \
  lib/features/study/domain/usecases/open_review_session_use_case.dart \
  test/features/study/data/open_review_session_test.dart \
  test/features/study/domain/open_session_use_cases_test.dart \
  test/features/study/domain/queue_plan_model_test.dart
git commit -F - <<'EOF'
feat(study): open a review session in one mode, with a direction for sm2

A review takes the first card_limit due cards of the deck and its subtree,
earliest due first (BR-STUDY-001, BR-STUDY-002), in one review mode of the
root's algorithm that can run on them (BR-STUDY-055, BR-MODE-009). An sm2
self_assess review takes a direction, kept on the session and assigned card
by card (BR-MODE-013, BR-MODE-015); a missing or unwanted direction is
refused before anything is written (BR-MODE-018).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: Answer turns through rounds and stages to the end of a session

**Files:**
- Create: `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/di/study_session_repository_provider.dart`, `lib/features/study/domain/models/turn_kind_model.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`
- Modify: `lib/features/study/data/datasources/study_queue_dao.dart`, `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/domain/failures/study_failure.dart`, `docs/shared/data/schema.md`
- Test (create): `test/features/study/data/answer_rounds_test.dart`, `test/features/study/data/answer_turn_test.dart`, `test/features/study/domain/study_failure_test.dart`, `test/features/study/domain/turn_kind_model_test.dart`
- Test (modify): `test/support/study_fixtures.dart`
- Regenerate: the `*.g.dart` of the new provider (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Tasks 1–4; `CardRepository.setFlagged`, `cardRepositoryProvider`,
  `scheduleRepositoryProvider`, `schedulerFor`.
- Produces:
  - `ReviewKind turnKindOf(SessionKind session, {required int round, required int answersInSession})`
    (`domain/models/turn_kind_model.dart`).
  - `StudyRejection.ofModeRefusal(StudyModeRejection)` and
    `StudyRejection.ofTurnRefusal(SrsRejection)`.
  - `StudySessionRepository.answerTurn({required String sessionId, required String cardId, required StudyAnswer answer, DateTime? now})` —
    `Future<Outcome<void, StudyRejection>>`;
    `StudySessionRepositoryImpl(AppDatabase db, ScheduleRepository schedules, CardRepository cards, {DateTime Function()? now, Random? random})`;
    `studySessionRepositoryProvider`.
  - `StudyQueueDao`: `headRow`, `boardRow`, `leave`, `keep`, `enroll`,
    `hasPendingRows`, `lowestPendingRound`, `isUnbuilt`, `cardsOf`, `build`.
    `StudySessionDao`: `sessionRow`, `setCursor`, `setCurrentMode`,
    `endSession`.
  - For tests: `studySessionRepository(db, now, {int seed = 1})`,
    `servedCard(db, sessionId)` and `turnKindsOf(db, cardId)`.

Spec §7.3, §7.4 and D7, D8; Clarification 6. A turn is one transaction:
the session must be open at its root's generation, the card must be the one
served (any pending row of a `match` board), the handler turns the answer into
an action, srs records it, the row takes its step, the cursor moves, and the
session moves to the next round, the next stage or its end. A card finishes
learning with the last stage it takes part in.

- [ ] **Step 1: Write the failing tests**

Replace the whole of `test/support/study_fixtures.dart` with:

```dart
import 'dart:math';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import 'invariant_queries.dart';

// The study repositories and the reads the study tests check them with.

/// The study entry repository over [db], reading the options through the
/// real settings repository and the time from [now], and shuffling with a
/// seeded source, so every order a test sees repeats.
StudyEntryRepositoryImpl studyEntryRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
}) => StudyEntryRepositoryImpl(
  db,
  SettingsRepositoryImpl(db, now: now),
  now: now,
  random: Random(seed),
);

/// The study session repository over [db], composing the real srs and card
/// repositories, reading the time from [now] and shuffling with a seeded
/// source.
StudySessionRepositoryImpl studySessionRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
}) {
  final schedules = ScheduleRepositoryImpl(db, now: now);
  return StudySessionRepositoryImpl(
    db,
    schedules,
    CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: now),
      now: now,
    ),
    now: now,
    random: Random(seed),
  );
}

/// No invariant query of schema.md returns a row, and at most one session
/// of the app is open (spec D2).
Future<void> expectStudyInvariants(AppDatabase db) async {
  for (final MapEntry(key: number, value: query) in invariantQueries.entries) {
    expect(
      await db.customSelect(query).get(),
      isEmpty,
      reason: 'invariant $number: ${invariantSummaries[number]}',
    );
  }
  final open = await db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_session WHERE status = 'in_progress'",
      )
      .getSingle();
  expect(open.read<int>('n'), lessThanOrEqualTo(1), reason: 'spec D2');
}

Future<QueryRow> sessionOf(AppDatabase db, String sessionId) => db
    .customSelect(
      'SELECT * FROM study_session WHERE id = ?',
      variables: [Variable(sessionId)],
    )
    .getSingle();

/// The cards of [sessionId]'s rows in [mode] and [round], in serving order.
Future<List<String>> queueOf(
  AppDatabase db,
  String sessionId,
  String mode, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id FROM study_queue_items '
            'WHERE session_id = ? AND mode = ? AND round = ? ORDER BY position',
            variables: [Variable(sessionId), Variable(mode), Variable(round)],
          )
          .get())
    row.read<String>('card_id'),
];

/// The modes [sessionId] has rows in, in the order of the chain.
Future<List<String>> modesOf(AppDatabase db, String sessionId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT mode FROM study_queue_items WHERE session_id = ? '
            'GROUP BY mode ORDER BY MIN(rowid)',
            variables: [Variable(sessionId)],
          )
          .get())
    row.read<String>('mode'),
];

/// The card [sessionId] serves next, as schema.md's `cursor` and
/// `available_at` read it (BR-STUDY-005): in the current mode's lowest round
/// with a pending row, the first by position among the rows due at the
/// cursor, else the one due soonest. Null when nothing is served.
Future<String?> servedCard(AppDatabase db, String sessionId) async {
  final row = await db
      .customSelect(
        'SELECT q.card_id FROM study_queue_items q'
        ' JOIN study_session s ON s.id = q.session_id'
        " WHERE q.session_id = ? AND q.mode = s.current_mode AND q.status = 'pending'"
        ' AND q.position >= 0 AND q.round = (SELECT MIN(p.round)'
        '  FROM study_queue_items p WHERE p.session_id = q.session_id'
        "  AND p.mode = q.mode AND p.status = 'pending')"
        ' ORDER BY q.available_at > s.cursor,'
        ' CASE WHEN q.available_at > s.cursor THEN q.available_at ELSE 0 END,'
        ' q.position LIMIT 1',
        variables: [Variable(sessionId)],
      )
      .getSingleOrNull();
  return row?.read<String>('card_id');
}

/// The kinds of [cardId]'s turns, in the order they were written.
Future<List<String>> turnKindsOf(AppDatabase db, String cardId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT kind FROM review_log WHERE card_id = ? ORDER BY rowid',
            variables: [Variable(cardId)],
          )
          .get())
    row.read<String>('kind'),
];
```

Create `test/features/study/data/answer_rounds_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 A0, A0c and A1 on eight_box decks: the graded modes' rounds,
// with a right or wrong verdict standing in for their mechanics (package 2b).

const _right = GradedAnswer(isCorrect: true);
const _wrong = GradedAnswer(isCorrect: false);

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<DeckEntity> lesson() async {
    final root = await decks.root('Korean');
    return decks.sub(root.id, 'Lesson');
  }

  Future<String> openLearning(String deckId) async =>
      ((await entries.openLearningSession(
        deckId: deckId,
      )) as Ok<String, StudyRejection>).value;

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

  /// Answers right until the session leaves [mode].
  Future<void> passStage(String sessionId, String mode) async {
    while (await modeOf(sessionId) == mode &&
        (await sessionOf(db, sessionId)).read<String>('status') ==
            'in_progress') {
      await answer(
        sessionId,
        mode == 'browse' ? const AdvanceAnswer() : _right,
      );
    }
  }

  test('a wrong card joins the next round once; each round has its own order '
      'and a clean round ends the stage, with no cap (IT-LEARN-008, '
      'BR-STUDY-059, BR-STUDY-060, BR-STUDY-061, BR-STUDY-069)', () async {
    final leaf = await lesson();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await openLearning(leaf.id);
    await passStage(id, 'browse');
    await passStage(id, 'match');
    expect(await modeOf(id), 'recall');
    final roundOne = await queueOf(db, id, 'recall');

    await answer(id, _wrong);
    await answer(id, _wrong);
    await answer(id, _right);
    final roundTwo = await queueOf(db, id, 'recall', round: 2);
    await answer(id, _wrong, roundTwo.first);
    await answer(id, _right, roundTwo.last);
    await answer(id, _right);

    expect(roundTwo..sort(), roundOne.sublist(0, 2)..sort());
    expect(
      await queueOf(db, id, 'recall', round: 2),
      isNot(roundOne.sublist(0, 2)),
      reason: 'round 2 is not round 1 again (BR-STUDY-061)',
    );
    expect(await queueOf(db, id, 'recall', round: 3), hasLength(1));
    expect(await queueOf(db, id, 'recall', round: 4), isEmpty);
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    // match, then recall rounds 1, 2 and 3: only its first turn in each
    // stage is `learning` (BR-STUDY-023; spec D8).
    expect(await turnKindsOf(db, roundOne[1]), [
      'learning',
      'learning',
      'relearning',
      'relearning',
    ]);
  });

  test(
    'a wrong match stays on the board and joins the next round once, '
    'even when matched right afterwards (BR-STUDY-062, BR-STUDY-060)',
    () async {
      final leaf = await lesson();
      for (final id in ['a', 'b']) {
        await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
      }
      final id = await openLearning(leaf.id);
      await passStage(id, 'browse');
      expect(await modeOf(id), 'match');

      await answer(id, _wrong, 'b');
      await answer(id, _wrong, 'b');
      await answer(id, _right, 'b');
      await answer(id, _right, 'a');

      expect(await queueOf(db, id, 'match', round: 2), ['b']);
      expect(await modeOf(id), 'match');
      await answer(id, _right, 'b');
      expect(await modeOf(id), 'recall');
    },
  );

  test('a card finishes learning when it passes the last stage it takes '
      'part in: a card skipped in fill finishes at recall (IT-LEARN-005, '
      'BR-STUDY-053, BR-STUDY-071)', () async {
    final leaf = await lesson();
    await insertCard(db, id: 'plain', deckId: leaf.id, back: 'plain');
    await insertCard(
      db,
      id: 'rich',
      deckId: leaf.id,
      back: 'rich',
      example: 'an example',
    );
    final id = await openLearning(leaf.id);
    for (final mode in ['browse', 'match', 'recall']) {
      await passStage(id, mode);
    }

    expect(await modeOf(id), 'fill');
    expect((await scheduleRowOf(db, 'plain')).data['learned_at'], isNotNull);
    expect((await scheduleRowOf(db, 'rich')).data['learned_at'], isNull);
    await passStage(id, 'fill');
    expect((await scheduleRowOf(db, 'rich')).data['learned_at'], isNotNull);
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
  });

  test('in an eight_box review a wrong first turn sends the card to box 1, '
      'and its next round relearns it without moving it again '
      '(IT-REVIEW-005, IT-REVIEW-006, BR-SRS-008, BR-STUDY-023)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        back: 'meaning $id',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
        box: 3,
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;

    await answer(id, _wrong, 'a');
    await answer(id, _right, 'b');
    await answer(id, _right, 'a');

    final a = await scheduleRowOf(db, 'a');
    expect(a.read<int>('current_box'), 1);
    expect(a.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect((a.read<int>('answer_count'), a.read<int>('lapse_count')), (1, 1));
    final b = await scheduleRowOf(db, 'b');
    expect(b.read<int>('current_box'), 4);
    expect(b.read<DateTime>('due_at'), DateTime(2026, 10, 2));
    expect(await turnKindsOf(db, 'a'), ['scheduled', 'relearning']);
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    final logs = await db
        .customSelect(
          'SELECT mode FROM review_log WHERE session_id = ?',
          variables: [Variable(id)],
        )
        .get();
    expect({for (final log in logs) log.read<String>('mode')}, {'recall'});
  });
}
```

Create `test/features/study/data/answer_turn_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–13 on sm2 decks: browse, self_assess and the errors
// every answer checks first.

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
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A learning session on [count] new cards `c1`… of an sm2 tree.
  Future<(String, String)> learning(int count) async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (var i = 1; i <= count; i++) {
      await insertCard(db, id: 'c$i', deckId: leaf.id, back: 'meaning $i');
    }
    final opened = await entries.openLearningSession(deckId: leaf.id);
    return (root.id, (opened as Ok<String, StudyRejection>).value);
  }

  Future<void> answer(String sessionId, StudyAnswer answer) async {
    final cardId = await servedCard(db, sessionId);
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

  Future<void> browseAll(String sessionId, int count) async {
    for (var i = 0; i < count; i++) {
      await answer(sessionId, const AdvanceAnswer());
    }
  }

  Future<int> logCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test('browse moves on without a turn: the row leaves the queue and the '
      'cursor moves, with no log and no schedule change (BR-MODE-005, '
      'BR-STUDY-007; IT-LEARN-003)', () async {
    final (_, id) = await learning(2);
    final first = await servedCard(db, id);

    await answer(id, const AdvanceAnswer());

    expect((await sessionOf(db, id)).read<int>('cursor'), 1);
    expect(await servedCard(db, id), isNot(first));
    expect(await logCount(), 0);
    expect((await scheduleRowOf(db, first!)).data['last_answered_at'], isNull);
  });

  test('the sm2 chain runs browse, then self_assess; a card passing its '
      'last stage finishes learning, and the first one locks the scheduler '
      '(IT-LEARN-002, IT-LEARN-010, BR-STUDY-053, BR-SRS-003)', () async {
    final (rootId, id) = await learning(2);
    await browseAll(id, 2);
    expect(
      (await sessionOf(db, id)).read<String>('current_mode'),
      'self_assess',
    );
    final first = await servedCard(db, id);

    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    final schedule = await scheduleRowOf(db, first!);
    expect(schedule.read<DateTime>('learned_at'), now);
    expect(schedule.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect(schedule.read<int>('interval_days'), 1);
    expect(await turnKindsOf(db, first), ['learning']);
    expect(
      (await deckRowOf(db, rootId)).read<DateTime>('first_answered_at'),
      now,
    );
    expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');

    await answer(id, const SelfAssessAnswer(Sm2Action.easy));

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'completed');
    expect(session.data['end_reason'], isNull);
    expect(session.read<DateTime>('ended_at'), now);
  });

  test('a forgotten card comes back after three other cards, then last when '
      'fewer remain, and at the cap it leaves flagged and still new '
      '(IT-LEARN-009, BR-STUDY-005, BR-STUDY-073, BR-CARD-009)', () async {
    final (_, id) = await learning(5);
    await browseAll(id, 5);
    final order = await queueOf(db, id, 'self_assess');
    const again = SelfAssessAnswer(Sm2Action.again);
    const good = SelfAssessAnswer(Sm2Action.good);

    await answer(id, again);
    final served = <String?>[];
    for (var i = 0; i < 3; i++) {
      served.add(await servedCard(db, id));
      await answer(id, good);
    }
    expect(served, order.sublist(1, 4));
    expect(await servedCard(db, id), order[0]);
    await answer(id, again);
    expect(await servedCard(db, id), order[4]);
    await answer(id, good);
    for (var turn = 3; turn <= 4; turn++) {
      expect(await servedCard(db, id), order[0], reason: 'turn $turn');
      await answer(id, again);
    }

    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    final capped = await db
        .customSelect(
          'SELECT c.is_flagged, s.learned_at FROM card c '
          'JOIN card_schedule s ON s.card_id = c.id WHERE c.id = ?',
          variables: [Variable(order[0])],
        )
        .getSingle();
    expect(capped.read<int>('is_flagged'), 1);
    expect(capped.data['learned_at'], isNull);
    expect(await turnKindsOf(db, order[0]), [
      'learning',
      'relearning',
      'relearning',
      'relearning',
    ]);
    for (final other in order.sublist(1)) {
      expect((await scheduleRowOf(db, other)).data['learned_at'], isNotNull);
    }
  });

  test('in a review the first turn is scheduled and moves the schedule; a '
      'forgotten card comes back as relearning, which keeps it, and every '
      'turn carries its row\'s direction (IT-REVIEW-003, IT-REVIEW-005, '
      'BR-STUDY-023, BR-SRS-016, BR-SRS-017, BR-MODE-016)', () async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.koreanToMeaning,
    );
    final id = (opened as Ok<String, StudyRejection>).value;

    await answer(id, const SelfAssessAnswer(Sm2Action.again));
    final afterLapse = await scheduleRowOf(db, 'a');
    await answer(id, const SelfAssessAnswer(Sm2Action.good));
    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    expect(afterLapse.read<int>('lapse_count'), 1);
    expect(afterLapse.read<int>('repetitions'), 0);
    expect(afterLapse.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    final relearned = await scheduleRowOf(db, 'a');
    expect(relearned.read<DateTime>('due_at'), DateTime(2026, 9, 25));
    expect(relearned.read<int>('answer_count'), 1);
    expect(await turnKindsOf(db, 'a'), ['scheduled', 'relearning']);
    expect(await turnKindsOf(db, 'b'), ['scheduled']);
    final directions = await db
        .customSelect('SELECT DISTINCT direction FROM review_log')
        .get();
    expect(
      [for (final row in directions) row.read<String>('direction')],
      ['korean_to_meaning'],
    );
    expect((await sessionOf(db, id)).read<String>('status'), 'completed');
  });

  test(
    'an answer from a session whose root was reset since is refused, '
    'writes no turn and ends the session (BR-STUDY-017, IT-CONT-010)',
    () async {
      final (rootId, id) = await learning(1);
      await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
        rootId,
      ]);
      await db.customStatement('UPDATE card_schedule SET generation = 2');
      final card = await servedCard(db, id);

      expect(
        await sessions.answerTurn(
          sessionId: id,
          cardId: card!,
          answer: const AdvanceAnswer(),
        ),
        _refusedWith(StudyRejection.staleGeneration),
      );

      final session = await sessionOf(db, id);
      expect(session.read<String>('status'), 'invalidated');
      expect(session.read<String>('end_reason'), 'stale_generation');
      expect(session.read<DateTime>('ended_at'), now);
      expect(session.read<int>('cursor'), 0);
      expect(await logCount(), 0);
    },
  );

  test('a second tap on a card already answered records nothing '
      '(BR-STUDY-004, BR-STUDY-042)', () async {
    final (_, id) = await learning(2);
    await browseAll(id, 2);
    final card = await servedCard(db, id);
    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card!,
        answer: const SelfAssessAnswer(Sm2Action.good),
      ),
      _refusedWith(StudyRejection.notCurrentCard),
    );
    expect(await logCount(), 1);
  });

  test('an answer of another mode, or an action the algorithm lacks, is '
      'refused and writes nothing (BR-MODE-011, BR-STUDY-009)', () async {
    final (_, id) = await learning(1);
    final card = (await servedCard(db, id))!;
    final before = await totalChanges(db);

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card,
        answer: const SelfAssessAnswer(Sm2Action.good),
      ),
      _refusedWith(StudyRejection.answerDoesNotFitMode),
    );
    await answer(id, const AdvanceAnswer());
    final atSelfAssess = await totalChanges(db);
    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card,
        answer: const SelfAssessAnswer(EightBoxAction.remembered),
      ),
      _refusedWith(StudyRejection.unsupportedAction),
    );
    expect(atSelfAssess, greaterThan(before));
    expect(await totalChanges(db), atSelfAssess);
  });

  test('a session that ended, or one that is gone, takes no answer', () async {
    final (_, id) = await learning(1);
    final card = (await servedCard(db, id))!;
    await db.customStatement(
      "UPDATE study_session SET status = 'abandoned', "
      "end_reason = 'user_exit', ended_at = 0",
    );

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: card,
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.sessionClosed),
    );
    expect(
      await sessions.answerTurn(
        sessionId: 'missing',
        cardId: card,
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.notFound),
    );
  });
}
```

Create `test/features/study/domain/study_failure_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';

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

  test('srs refusals a session can meet keep their meaning; the others are '
      'bugs (spec §7.3 step 4)', () {
    expect(
      StudyRejection.ofTurnRefusal(SrsRejection.notFound),
      StudyRejection.notFound,
    );
    expect(
      StudyRejection.ofTurnRefusal(SrsRejection.staleGeneration),
      StudyRejection.staleGeneration,
    );
    expect(
      StudyRejection.ofTurnRefusal(SrsRejection.unsupportedAction),
      StudyRejection.unsupportedAction,
    );
    for (final bug in [
      SrsRejection.schedulerLocked,
      SrsRejection.notARootDeck,
    ]) {
      expect(() => StudyRejection.ofTurnRefusal(bug), throwsStateError);
    }
  });
}
```

Create `test/features/study/domain/turn_kind_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

void main() {
  test("a card's first turn in a stage is learning in a learning session and "
      'scheduled in a review (BR-STUDY-023, BR-SRS-016)', () {
    expect(
      turnKindOf(SessionKind.learning, round: 1, answersInSession: 0),
      ReviewKind.learning,
    );
    expect(
      turnKindOf(SessionKind.reviewing, round: 1, answersInSession: 0),
      ReviewKind.scheduled,
    );
  });

  test('every later turn is relearning: a comeback, a retry, a next round '
      '(BR-SRS-017; spec D8)', () {
    for (final session in SessionKind.values) {
      expect(
        turnKindOf(session, round: 1, answersInSession: 1),
        ReviewKind.relearning,
      );
      expect(
        turnKindOf(session, round: 2, answersInSession: 0),
        ReviewKind.relearning,
      );
    }
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/answer_rounds_test.dart \
  test/features/study/data/answer_turn_test.dart \
  test/features/study/domain/study_failure_test.dart \
  test/features/study/domain/turn_kind_model_test.dart
```

Expected: `+0 -4: Some tests failed.` None of the four new files compiles; `StudyRejection.ofModeRefusal` does not exist yet, so the compiler reads it as a constructor of the enum. The first errors: `Error: Enums can't be instantiated.`, `Error: Error when reading 'lib/features/study/data/repositories/study_session_repository_impl.dart': No such file or directory`, `Error: Method not found: 'turnKindOf'.`

- [ ] **Step 3: Write the turn kind and the refusal mapping**

In `lib/features/study/domain/failures/study_failure.dart`:

Replace

```dart
/// Why the study feature refuses an operation (ADR-011 D6).
```

with

```dart
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/study_mode/domain/failures/study_mode_failure.dart';

/// Why the study feature refuses an operation (ADR-011 D6).
```

Replace

```dart
  /// The action is not in the scheduler's `supportedActions` (BR-STUDY-009).
  unsupportedAction,
}
```

with

```dart
  /// The action is not in the scheduler's `supportedActions` (BR-STUDY-009).
  unsupportedAction;

  /// A mode's refusal of an answer, as the session reports it.
  static StudyRejection ofModeRefusal(StudyModeRejection reason) =>
      switch (reason) {
        StudyModeRejection.answerDoesNotFitMode => answerDoesNotFitMode,
        StudyModeRejection.unsupportedAction => unsupportedAction,
      };

  /// srs's refusal of a turn, as the session reports it. A refusal a
  /// session never causes is a bug (spec §7.3 step 4).
  static StudyRejection ofTurnRefusal(SrsRejection reason) => switch (reason) {
    SrsRejection.notFound => notFound,
    SrsRejection.staleGeneration => staleGeneration,
    SrsRejection.unsupportedAction => unsupportedAction,
    SrsRejection.schedulerLocked || SrsRejection.notARootDeck =>
      throw StateError('srs refused a turn: $reason'),
  };
}
```

Create `lib/features/study/domain/models/turn_kind_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/review_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';

/// The kind of a turn (BR-STUDY-023; spec D8). A card's first turn in a
/// stage, on its round 1 row with no answer yet, is `learning` in a learning
/// session and `scheduled` in a review; every later turn of the card in that
/// stage (a comeback, a retry on the board, a next round) is `relearning`.
ReviewKind turnKindOf(
  SessionKind session, {
  required int round,
  required int answersInSession,
}) {
  if (round > 1 || answersInSession > 0) return ReviewKind.relearning;
  return switch (session) {
    SessionKind.learning => ReviewKind.learning,
    SessionKind.reviewing => ReviewKind.scheduled,
  };
}
```

- [ ] **Step 4: Serve, step and build the queue rows**

Replace the whole of `lib/features/study/data/datasources/study_queue_dao.dart` with:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// `study_queue_items.status` of a row still to serve, and of a row done
/// (BR-STUDY-007).
const _pending = 'pending';
const _completed = 'completed';

/// The position of a row enrolled in a round not built yet: the round is
/// shuffled and numbered when the round before it ends (spec D7).
const _unbuilt = -1;

/// Row access for `study_queue_items`. It returns Drift rows and card ids,
/// never domain values, and runs inside the caller's transaction.
final class StudyQueueDao {
  StudyQueueDao(this._db);

  final AppDatabase _db;

  /// Round 1 of [mode]: [cardIds] in serving order, each with its entry of
  /// [directions] when there are directions (BR-MODE-015).
  Future<void> insertFirstRound(
    String sessionId,
    String mode,
    List<String> cardIds, {
    List<String>? directions,
  }) => _db.batch(
    (batch) => batch.insertAll(_db.studyQueueItems, [
      for (final (position, cardId) in cardIds.indexed)
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          cardId: cardId,
          position: position,
          status: _pending,
          direction: Value(directions?[position]),
        ),
    ]),
  );

  /// The row [sessionId] serves next in [mode] at [cursor] (schema.md,
  /// "cursor + available_at"; BR-STUDY-005): in the lowest round with a
  /// pending row, the first by position among the rows due at the cursor,
  /// else the one due soonest. Null when the mode has no pending row, or when
  /// that round is not built yet.
  Future<StudyQueueItem?> headRow(
    String sessionId,
    String mode,
    int cursor,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT q.* FROM study_queue_items q'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.status = ?'
          ' AND q.position >= 0 AND q.round = ($_lowestPendingRound)'
          ' ORDER BY q.available_at > ?,'
          ' CASE WHEN q.available_at > ? THEN q.available_at ELSE 0 END,'
          ' q.position LIMIT 1',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            const Variable<String>(_pending),
            const Variable<String>(_pending),
            Variable<int>(cursor),
            Variable<int>(cursor),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingleOrNull();
    return row == null ? null : _db.studyQueueItems.map(row.data);
  }

  /// [cardId]'s pending row in the lowest pending round of [mode], once that
  /// round is built: a `match` board serves any of its rows.
  Future<StudyQueueItem?> boardRow(
    String sessionId,
    String mode,
    String cardId,
  ) async {
    final row = await _db
        .customSelect(
          'SELECT q.* FROM study_queue_items q'
          ' WHERE q.session_id = ? AND q.mode = ? AND q.status = ?'
          ' AND q.card_id = ? AND q.position >= 0'
          ' AND q.round = ($_lowestPendingRound)',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            const Variable<String>(_pending),
            Variable<String>(cardId),
            const Variable<String>(_pending),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingleOrNull();
    return row == null ? null : _db.studyQueueItems.map(row.data);
  }

  /// The lowest round of `q`'s mode with a pending row.
  static const _lowestPendingRound =
      'SELECT MIN(p.round) FROM study_queue_items p'
      ' WHERE p.session_id = q.session_id AND p.mode = q.mode AND p.status = ?';

  /// The row is done, after [answers] turns (BR-STUDY-007).
  Future<void> leave(StudyQueueItem row, {required int answers}) => _update(
    row,
    StudyQueueItemsCompanion(
      status: const Value(_completed),
      answersInSession: Value(answers),
    ),
  );

  /// The row stays pending after [answers] turns, served again from the
  /// cursor [availableAt] when one is given (BR-STUDY-005).
  Future<void> keep(
    StudyQueueItem row, {
    required int answers,
    int? availableAt,
  }) => _update(
    row,
    StudyQueueItemsCompanion(
      answersInSession: Value(answers),
      availableAt: availableAt == null
          ? const Value.absent()
          : Value(availableAt),
    ),
  );

  /// Enrolls [cardId] in [round] of [mode] once: a second enrollment changes
  /// nothing (BR-STUDY-060, BR-STUDY-062).
  Future<void> enroll(
    String sessionId,
    String mode,
    int round,
    String cardId,
  ) => _db
      .into(_db.studyQueueItems)
      .insert(
        StudyQueueItemsCompanion.insert(
          sessionId: sessionId,
          mode: mode,
          round: Value(round),
          cardId: cardId,
          position: _unbuilt,
          status: _pending,
        ),
        mode: InsertMode.insertOrIgnore,
      );

  /// Whether [cardId] still has a row to serve in any mode of [sessionId].
  Future<bool> hasPendingRows(String sessionId, String cardId) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM study_queue_items WHERE session_id = ?'
          ' AND card_id = ? AND status = ?) AS pending',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(cardId),
            const Variable<String>(_pending),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return row.read<bool>('pending');
  }

  /// The lowest round of [mode] with a pending row; null when the stage has
  /// none left.
  Future<int?> lowestPendingRound(String sessionId, String mode) async {
    final row = await _db
        .customSelect(
          'SELECT MIN(round) AS round FROM study_queue_items'
          ' WHERE session_id = ? AND mode = ? AND status = ?',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            const Variable<String>(_pending),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return row.read<int?>('round');
  }

  /// Whether [round] of [mode] still waits to be built (spec D7).
  Future<bool> isUnbuilt(String sessionId, String mode, int round) async {
    final row = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM study_queue_items WHERE session_id = ?'
          ' AND mode = ? AND round = ? AND position < 0) AS unbuilt',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return row.read<bool>('unbuilt');
  }

  /// The cards of [round] of [mode], in serving order; a round not built yet
  /// lists them by id, so a seeded shuffle of it repeats.
  Future<List<String>> cardsOf(String sessionId, String mode, int round) async {
    final rows =
        await (_db.select(_db.studyQueueItems)
              ..where(
                (q) =>
                    q.sessionId.equals(sessionId) &
                    q.mode.equals(mode) &
                    q.round.equals(round),
              )
              ..orderBy([
                (q) => OrderingTerm(expression: q.position),
                (q) => OrderingTerm(expression: q.cardId),
              ]))
            .get();
    return [for (final row in rows) row.cardId];
  }

  /// Builds [round] of [mode]: [order] numbers its rows from 0, and the
  /// positions do not change after this (schema.md).
  Future<void> build(
    String sessionId,
    String mode,
    int round,
    List<String> order,
  ) async {
    for (final (position, cardId) in order.indexed) {
      await (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(sessionId) &
                q.mode.equals(mode) &
                q.round.equals(round) &
                q.cardId.equals(cardId),
          ))
          .write(StudyQueueItemsCompanion(position: Value(position)));
    }
  }

  Future<void> _update(StudyQueueItem row, StudyQueueItemsCompanion values) =>
      (_db.update(_db.studyQueueItems)..where(
            (q) =>
                q.sessionId.equals(row.sessionId) &
                q.mode.equals(row.mode) &
                q.round.equals(row.round) &
                q.cardId.equals(row.cardId),
          ))
          .write(values);
}
```

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart
      _db.into(_db.studySession).insert(row);
}
```

with

```dart
      _db.into(_db.studySession).insert(row);

  Future<StudySession?> sessionRow(String id) => (_db.select(
    _db.studySession,
  )..where((session) => session.id.equals(id))).getSingleOrNull();

  Future<void> setCursor(String id, int cursor) =>
      _updateSession(id, StudySessionCompanion(cursor: Value(cursor)));

  Future<void> setCurrentMode(String id, String mode) =>
      _updateSession(id, StudySessionCompanion(currentMode: Value(mode)));

  /// Ends the session as [status], for [reason] when it did not finish its
  /// queue (schema.md's status matrix).
  Future<void> endSession(
    String id, {
    required SessionStatus status,
    SessionEndReason? reason,
    required DateTime now,
  }) => _updateSession(
    id,
    StudySessionCompanion(
      status: Value(status.code),
      endReason: Value(reason?.code),
      endedAt: Value(now),
    ),
  );

  Future<void> _updateSession(String id, StudySessionCompanion values) =>
      (_db.update(
        _db.studySession,
      )..where((session) => session.id.equals(id))).write(values);
}
```

- [ ] **Step 5: Answer a turn in the session repository**

Create `lib/features/study/data/repositories/study_session_repository_impl.dart`:

```dart
import 'dart:math';

import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/queue_plan_model.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/row_step_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// Runs a session: its turns, its rounds and stages, and how it ends
/// (UC-STUDY-001 steps 6–13, A1–A5). Every write is one transaction, which
/// the srs and card writes it calls join: the rules read the rows as they
/// are at the moment of writing, and a refusal writes nothing.
final class StudySessionRepositoryImpl implements StudySessionRepository {
  StudySessionRepositoryImpl(
    this._db,
    this._schedules,
    this._cards, {
    DateTime Function()? now,
    Random? random,
  }) : _dao = StudySessionDao(_db),
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
       _random = random ?? Random();

  final AppDatabase _db;
  final ScheduleRepository _schedules;
  final CardRepository _cards;
  final StudySessionDao _dao;
  final StudyQueueDao _queue;
  final DateTime Function() _now;

  /// Every shuffle of a later round (BR-STUDY-061).
  final Random _random;

  @override
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      switch (await _live(await _dao.sessionRow(sessionId), at)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final session, final root)):
          return _answer(session, root, cardId, answer, at);
      }
    });
  }

  /// [session] and its root while the session is open and its generation
  /// still holds (spec §7.3 step 1). A session whose root was reset since it
  /// opened is invalidated on the way (BR-STUDY-017, IT-CONT-010).
  Future<Outcome<(StudySession, Deck), StudyRejection>> _live(
    StudySession? session,
    DateTime at,
  ) async {
    if (session == null) return const Rejected(StudyRejection.notFound);
    if (session.status != SessionStatus.inProgress.code) {
      return const Rejected(StudyRejection.sessionClosed);
    }
    final root = await _dao.deckRow(session.rootId);
    if (root == null) return const Rejected(StudyRejection.notFound);
    if (root.generation == session.generation) return Ok((session, root));
    await _dao.endSession(
      session.id,
      status: SessionStatus.invalidated,
      reason: SessionEndReason.staleGeneration,
      now: at,
    );
    return const Rejected(StudyRejection.staleGeneration);
  }

  /// [answer] on [cardId] in an open [session] (spec §7.3 steps 2–8).
  Future<Outcome<void, StudyRejection>> _answer(
    StudySession session,
    Deck root,
    String cardId,
    StudyAnswer answer,
    DateTime at,
  ) async {
    final mode = StudyMode.fromCode(session.currentMode);
    final row = mode.handler.servesInOrder
        ? await _queue.headRow(session.id, mode.code, session.cursor)
        : await _queue.boardRow(session.id, mode.code, cardId);
    if (row == null || row.cardId != cardId) {
      return const Rejected(StudyRejection.notCurrentCard);
    }

    final type = SchedulerType.fromCode(root.schedulerType!);
    final scheduler = schedulerFor(type);
    final Object? action;
    switch (mode.handler.actionOf(answer, scheduler)) {
      case Rejected(:final reason):
        return Rejected(StudyRejection.ofModeRefusal(reason));
      case Ok(:final value):
        action = value;
    }
    final kind = SessionKind.values.byName(session.sessionKind);
    if (action != null) {
      final recorded = await _schedules.recordTurn(
        ReviewTurn(
          cardId: cardId,
          sessionId: session.id,
          generation: session.generation,
          kind: turnKindOf(
            kind,
            round: row.round,
            answersInSession: row.answersInSession,
          ),
          modeCode: mode.code,
          action: action,
          directionCode: row.direction,
          answeredAt: at,
        ),
      );
      if (recorded case Rejected(:final reason)) {
        return Rejected(StudyRejection.ofTurnRefusal(reason));
      }
    }

    final cursor = session.cursor + 1;
    final step = mode.handler.stepAfter(
      lapsed: action != null && scheduler.isLapse(action),
      answersInSession: row.answersInSession,
    );
    await _apply(
      step,
      row,
      answers: row.answersInSession + (action == null ? 0 : 1),
      cursor: cursor,
      at: at,
    );
    await _dao.setCursor(session.id, cursor);
    // A card finishes learning with the last stage it takes part in; a
    // card at the cap stays new (BR-STUDY-053, UC-STUDY-001 A2b).
    if (kind == SessionKind.learning &&
        step is! LeaveAtCap &&
        !await _queue.hasPendingRows(session.id, cardId)) {
      await _required(
        _schedules.completeLearning(
          cardId: cardId,
          generation: session.generation,
          now: at,
        ),
        'finishing learning $cardId',
      );
    }
    await _progress(session, type, at);
    return const Ok(null);
  }

  /// What [step] does to [row] (spec §5.5).
  Future<void> _apply(
    RowStep step,
    StudyQueueItem row, {
    required int answers,
    required int cursor,
    required DateTime at,
  }) async {
    switch (step) {
      case Leave():
        await _queue.leave(row, answers: answers);
      case ComeBack(:final afterTurns):
        await _queue.keep(
          row,
          answers: answers,
          availableAt: cursor + afterTurns,
        );
      case LeaveAtCap():
        await _queue.leave(row, answers: answers);
        // Nothing turns the flag off (BR-STUDY-073, BR-CARD-009).
        await _required(
          _cards.setFlagged(cardIds: {row.cardId}, isFlagged: true, now: at),
          'flagging ${row.cardId}',
        );
      case StayAndEnroll():
        await _queue.keep(row, answers: answers);
        await _queue.enroll(row.sessionId, row.mode, row.round + 1, row.cardId);
      case LeaveAndEnroll():
        await _queue.leave(row, answers: answers);
        await _queue.enroll(row.sessionId, row.mode, row.round + 1, row.cardId);
    }
  }

  /// When the current round has no pending row left, the next round is
  /// built, or the session moves to the next stage that has rows, or, with
  /// none left, completes (spec §7.4; BR-STUDY-013, BR-STUDY-069).
  Future<void> _progress(
    StudySession session,
    SchedulerType type,
    DateTime at,
  ) async {
    final current = StudyMode.fromCode(session.currentMode);
    final chain = switch (SessionKind.values.byName(session.sessionKind)) {
      SessionKind.learning => stageSequenceOf(type),
      SessionKind.reviewing => [current],
    };
    for (final mode in chain.skipWhile((mode) => mode != current)) {
      final round = await _queue.lowestPendingRound(session.id, mode.code);
      if (round == null) continue;
      if (await _queue.isUnbuilt(session.id, mode.code, round)) {
        await _build(session.id, mode, round);
      }
      if (mode != current) await _dao.setCurrentMode(session.id, mode.code);
      return;
    }
    await _dao.endSession(session.id, status: SessionStatus.completed, now: at);
  }

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
  }

  /// One transaction. An unexpected database error leaves as the [Failure]
  /// `mapDatabaseError` makes of it, with its stack trace, after the rollback.
  Future<T> _write<T>(Future<T> Function() body) async {
    try {
      return await _db.transaction(body);
    } on Object catch (error, stackTrace) {
      Error.throwWithStackTrace(mapDatabaseError(error), stackTrace);
    }
  }
}

/// A write the turn cannot go without. A refusal there means study and the
/// feature it calls disagree: a bug, which rolls the turn back (spec §7.3,
/// E3).
Future<void> _required<R extends Enum>(
  Future<Outcome<void, R>> write,
  String what,
) async {
  if (await write case Rejected(:final reason)) {
    throw StateError('$what refused: $reason');
  }
}
```

Create `lib/features/study/di/study_session_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/card/di/card_repository_provider.dart';
import 'package:memox/features/srs/di/schedule_repository_provider.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_session_repository_provider.g.dart';

@riverpod
StudySessionRepository studySessionRepository(Ref ref) =>
    StudySessionRepositoryImpl(
      ref.watch(databaseProvider),
      ref.watch(scheduleRepositoryProvider),
      ref.watch(cardRepositoryProvider),
    );
```

Create `lib/features/study/domain/repositories/study_session_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// The one implementation is `StudySessionRepositoryImpl` (data layer). The
/// contract exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class StudySessionRepository {
  /// UC-STUDY-001 steps 6–9: [answer] on [cardId], the card the session
  /// serves in its current mode and round, or any pending card of a `match`
  /// board (notCurrentCard otherwise, BR-STUDY-042). A turn with an action
  /// is recorded through srs (BR-STUDY-009, BR-STUDY-023); the row then
  /// leaves, comes back or joins the next round (BR-STUDY-005,
  /// BR-STUDY-059, BR-STUDY-062), the cursor moves (BR-STUDY-048), and the
  /// session moves to the next round, the next stage or its end
  /// (BR-STUDY-013, BR-STUDY-069). In a learning session a card that passed
  /// the last stage it takes part in finishes learning (BR-STUDY-053). A
  /// session whose root was reset since it opened is invalidated and the
  /// answer refused as staleGeneration (BR-STUDY-017); any other refusal
  /// writes nothing.
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  });
}
```

- [ ] **Step 6: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run ends with `Built with build_runner`, and the new `*_provider.g.dart` exists next to its provider.

- [ ] **Step 7: Describe rounds and turn kinds in schema.md**

In `docs/shared/data/schema.md`:

Replace

```markdown
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `position` | INTEGER NOT NULL | thứ tự trong round đó (BR-STUDY-002, BR-STUDY-061). **Bất biến một khi round đã dựng** |
| `status` | TEXT NOT NULL | `pending` \| `completed` (BR-STUDY-007) |
| `available_at` | INTEGER NOT NULL DEFAULT 0 | mốc `cursor` tối thiểu để thẻ được phục vụ lại (BR-STUDY-005) |
| `answers_in_session` | INTEGER NOT NULL DEFAULT 0 | số lượt đã đánh giá; `0` ⇒ lượt tới là `scheduled` (BR-SRS-016) |
| `remaining_ms` | INTEGER NULL | chỉ `recall`: thời gian còn lại của lượt đang dở (BR-STUDY-036). NULL ở mọi stage khác |
```

with

```markdown
| `card_id` | TEXT NOT NULL | → `card(id)` ON DELETE CASCADE |
| `position` | INTEGER NOT NULL | thứ tự trong round đó (BR-STUDY-002, BR-STUDY-061). **Bất biến một khi round đã dựng**. Round 1 của mọi stage được dựng lúc mở phiên; một round sau được dựng (xáo lại, đánh số `0…n-1`) khi round trước nó hết dòng `pending`, và tới lúc đó các thẻ đã ghi danh vào nó mang `position = -1` |
| `status` | TEXT NOT NULL | `pending` \| `completed` (BR-STUDY-007) |
| `available_at` | INTEGER NOT NULL DEFAULT 0 | mốc `cursor` tối thiểu để thẻ được phục vụ lại (BR-STUDY-005) |
| `answers_in_session` | INTEGER NOT NULL DEFAULT 0 | số lượt đã đánh giá của dòng. `0` ở round 1 ⇒ lượt tới là lượt đầu của thẻ trong stage: `learning` ở phiên học mới, `scheduled` ở phiên ôn (BR-SRS-016, BR-STUDY-023). Mọi lượt sau đó, kể cả lượt đầu của round sau, là `relearning` |
| `remaining_ms` | INTEGER NULL | chỉ `recall`: thời gian còn lại của lượt đang dở (BR-STUDY-036). NULL ở mọi stage khác |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/study/data/answer_rounds_test.dart \
  test/features/study/data/answer_turn_test.dart \
  test/features/study/domain/study_failure_test.dart \
  test/features/study/domain/turn_kind_model_test.dart
```

Expected: `+16: All tests passed!`

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

Expected: `No issues found!`; `+1101: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  docs/shared/data/schema.md \
  lib/features/study/data/datasources/study_queue_dao.dart \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/di/study_session_repository_provider.dart \
  lib/features/study/domain/failures/study_failure.dart \
  lib/features/study/domain/models/turn_kind_model.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  test/features/study/data/answer_rounds_test.dart \
  test/features/study/data/answer_turn_test.dart \
  test/features/study/domain/study_failure_test.dart \
  test/features/study/domain/turn_kind_model_test.dart \
  test/support/study_fixtures.dart
git commit -F - <<'EOF'
feat(study): answer turns through rounds and stages to the end of a session

A turn names the card the session serves (BR-STUDY-042); its action goes to
srs as a learning, scheduled or relearning turn (BR-STUDY-023). Browse moves
on, self_assess brings a forgotten card back after three others up to the cap
that flags it (BR-STUDY-005, BR-STUDY-073), and a wrong graded answer joins
the next round once (BR-STUDY-059, BR-STUDY-060, BR-STUDY-062). A clean round
ends the stage, the last stage ends the session (BR-STUDY-013, BR-STUDY-069),
and a card finishes learning with the last stage it takes part in
(BR-STUDY-053).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: A turn that cannot be written

**Files:**
- Create: `lib/features/study/domain/usecases/answer_study_turn_use_case.dart`
- Modify: `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`
- Test (create): `test/features/study/data/fail_session_test.dart`, `test/features/study/domain/answer_study_turn_use_case_test.dart`
- Test (modify): `test/support/study_fixtures.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 5; `DatabaseLockedFailure`, `UnknownDatabaseFailure`,
  `Failure` (`lib/core/error/failure.dart`).
- Produces:
  - `StudySessionRepository.failSession({required String sessionId, DateTime? now})` —
    `Future<void>`.
  - `AnswerStudyTurnUseCase(StudySessionRepository sessions)` —
    `call({required String sessionId, required String cardId, required StudyAnswer answer})`
    → `Future<Outcome<void, StudyRejection>>`.
  - `studySessionRepository(..., {ScheduleRepository? schedules})` for a test
    that injects a fault.

Spec §8.3 and D9. A busy database (E2) writes nothing and the person
retries the same answer; any other failure (E3) has rolled the turn back, and
the use case closes the session as `failed`/`persistence_error` in a write of
its own before the failure reaches the UI. If that write fails too, the turn's
failure is the one reported.

- [ ] **Step 1: Write the failing tests**

Replace the whole of `test/support/study_fixtures.dart` with:

```dart
import 'dart:math';

import 'package:drift/drift.dart' show QueryRow, Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import 'invariant_queries.dart';

// The study repositories and the reads the study tests check them with.

/// The study entry repository over [db], reading the options through the
/// real settings repository and the time from [now], and shuffling with a
/// seeded source, so every order a test sees repeats.
StudyEntryRepositoryImpl studyEntryRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
}) => StudyEntryRepositoryImpl(
  db,
  SettingsRepositoryImpl(db, now: now),
  now: now,
  random: Random(seed),
);

/// The study session repository over [db], composing the real srs and card
/// repositories, reading the time from [now] and shuffling with a seeded
/// source. [schedules] stands in for the real srs writes when a test injects
/// a fault into them.
StudySessionRepositoryImpl studySessionRepository(
  AppDatabase db,
  DateTime Function() now, {
  int seed = 1,
  ScheduleRepository? schedules,
}) {
  schedules ??= ScheduleRepositoryImpl(db, now: now);
  return StudySessionRepositoryImpl(
    db,
    schedules,
    CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: now),
      now: now,
    ),
    now: now,
    random: Random(seed),
  );
}

/// No invariant query of schema.md returns a row, and at most one session
/// of the app is open (spec D2).
Future<void> expectStudyInvariants(AppDatabase db) async {
  for (final MapEntry(key: number, value: query) in invariantQueries.entries) {
    expect(
      await db.customSelect(query).get(),
      isEmpty,
      reason: 'invariant $number: ${invariantSummaries[number]}',
    );
  }
  final open = await db
      .customSelect(
        "SELECT COUNT(*) AS n FROM study_session WHERE status = 'in_progress'",
      )
      .getSingle();
  expect(open.read<int>('n'), lessThanOrEqualTo(1), reason: 'spec D2');
}

Future<QueryRow> sessionOf(AppDatabase db, String sessionId) => db
    .customSelect(
      'SELECT * FROM study_session WHERE id = ?',
      variables: [Variable(sessionId)],
    )
    .getSingle();

/// The cards of [sessionId]'s rows in [mode] and [round], in serving order.
Future<List<String>> queueOf(
  AppDatabase db,
  String sessionId,
  String mode, {
  int round = 1,
}) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT card_id FROM study_queue_items '
            'WHERE session_id = ? AND mode = ? AND round = ? ORDER BY position',
            variables: [Variable(sessionId), Variable(mode), Variable(round)],
          )
          .get())
    row.read<String>('card_id'),
];

/// The modes [sessionId] has rows in, in the order of the chain.
Future<List<String>> modesOf(AppDatabase db, String sessionId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT mode FROM study_queue_items WHERE session_id = ? '
            'GROUP BY mode ORDER BY MIN(rowid)',
            variables: [Variable(sessionId)],
          )
          .get())
    row.read<String>('mode'),
];

/// The card [sessionId] serves next, as schema.md's `cursor` and
/// `available_at` read it (BR-STUDY-005): in the current mode's lowest round
/// with a pending row, the first by position among the rows due at the
/// cursor, else the one due soonest. Null when nothing is served.
Future<String?> servedCard(AppDatabase db, String sessionId) async {
  final row = await db
      .customSelect(
        'SELECT q.card_id FROM study_queue_items q'
        ' JOIN study_session s ON s.id = q.session_id'
        " WHERE q.session_id = ? AND q.mode = s.current_mode AND q.status = 'pending'"
        ' AND q.position >= 0 AND q.round = (SELECT MIN(p.round)'
        '  FROM study_queue_items p WHERE p.session_id = q.session_id'
        "  AND p.mode = q.mode AND p.status = 'pending')"
        ' ORDER BY q.available_at > s.cursor,'
        ' CASE WHEN q.available_at > s.cursor THEN q.available_at ELSE 0 END,'
        ' q.position LIMIT 1',
        variables: [Variable(sessionId)],
      )
      .getSingleOrNull();
  return row?.read<String>('card_id');
}

/// The kinds of [cardId]'s turns, in the order they were written.
Future<List<String>> turnKindsOf(AppDatabase db, String cardId) async => [
  for (final row
      in await db
          .customSelect(
            'SELECT kind FROM review_log WHERE card_id = ? ORDER BY rowid',
            variables: [Variable(cardId)],
          )
          .get())
    row.read<String>('kind'),
];
```

Create `test/features/study/data/fail_session_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 E3 in the repository: the write the use case makes once a
// turn failed for good.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A learning session on one new card [cardId] of a fresh sm2 tree [name].
  Future<String> learningOn(String name, String cardId) async {
    final root = await decks.root(name, SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: cardId, deckId: leaf.id);
    final opened = await entries.openLearningSession(deckId: leaf.id);
    return (opened as Ok<String, StudyRejection>).value;
  }

  Future<void> answer(String sessionId, StudyAnswer answer) async => expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: (await servedCard(db, sessionId))!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
  );

  test('failSession closes an open session as failed/persistence_error and '
      'keeps its turns (BR-STUDY-018, BR-STUDY-019)', () async {
    final id = await learningOn('Korean', 'c1');
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.again));
    final later = now.add(const Duration(minutes: 5));

    await sessions.failSession(sessionId: id, now: later);

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'failed');
    expect(session.read<String>('end_reason'), 'persistence_error');
    expect(session.read<DateTime>('ended_at'), later);
    expect(await turnKindsOf(db, 'c1'), ['learning']);
  });

  test('failSession leaves a session that has ended, or is gone, as it is '
      '(spec §7.5)', () async {
    final first = await learningOn('Korean', 'c1');
    await learningOn('Japanese', 'c2');

    await sessions.failSession(sessionId: first);
    await sessions.failSession(sessionId: 'missing');

    final session = await sessionOf(db, first);
    expect(session.read<String>('status'), 'abandoned');
    expect(session.read<String>('end_reason'), 'user_exit');
  });
}
```

Create `test/features/study/domain/answer_study_turn_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/repositories/schedule_repository.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study/domain/usecases/answer_study_turn_use_case.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 E2 and E3: what a failed write does to the turn and to the
// session (spec D9).

const _good = SelfAssessAnswer(Sm2Action.good);

/// The real srs writes, failing the next turn with [fault] once they are
/// done, so the turn's transaction has something to roll back.
final class _FaultySchedules implements ScheduleRepository {
  _FaultySchedules(this._schedules);

  final ScheduleRepository _schedules;
  Exception? fault;

  @override
  Future<Outcome<void, SrsRejection>> recordTurn(ReviewTurn turn) async {
    final recorded = await _schedules.recordTurn(turn);
    final pending = fault;
    fault = null;
    if (pending != null) throw pending;
    return recorded;
  }

  @override
  Future<Outcome<void, SrsRejection>> completeLearning({
    required String cardId,
    required int generation,
    DateTime? now,
  }) => _schedules.completeLearning(
    cardId: cardId,
    generation: generation,
    now: now,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A session store whose answer fails with [answerError], or is refused
/// when there is none, and whose close fails with [failError].
final class _BrokenSessions implements StudySessionRepository {
  _BrokenSessions({this.answerError, this.failError});

  final Failure? answerError;
  final Failure? failError;
  final failed = <String>[];

  @override
  Future<Outcome<void, StudyRejection>> answerTurn({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
    DateTime? now,
  }) async {
    final error = answerError;
    if (error != null) throw error;
    return const Rejected(StudyRejection.notCurrentCard);
  }

  @override
  Future<void> failSession({required String sessionId, DateTime? now}) async {
    failed.add(sessionId);
    final error = failError;
    if (error != null) throw error;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late _FaultySchedules schedules;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepository sessions;
  late AnswerStudyTurnUseCase answerTurn;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    schedules = _FaultySchedules(ScheduleRepositoryImpl(db, now: () => now));
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now, schedules: schedules);
    answerTurn = AnswerStudyTurnUseCase(sessions);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Outcome<void, StudyRejection>> turn(
    String sessionId,
    StudyAnswer answer,
  ) async => answerTurn(
    sessionId: sessionId,
    cardId: (await servedCard(db, sessionId))!,
    answer: answer,
  );

  Future<void> answer(String sessionId, StudyAnswer answer) async =>
      expect(await turn(sessionId, answer), isA<Ok<void, StudyRejection>>());

  /// A learning session on [count] new cards `c1`… of an sm2 tree, past its
  /// browse stage.
  Future<String> selfAssessing(int count) async {
    final decks = DeckRepositoryImpl(db, now: () => now);
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (var i = 1; i <= count; i++) {
      await insertCard(db, id: 'c$i', deckId: leaf.id);
    }
    final opened = await entries.openLearningSession(deckId: leaf.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    for (var i = 0; i < count; i++) {
      await answer(id, const AdvanceAnswer());
    }
    return id;
  }

  Future<int> logCount() async =>
      (await db
              .customSelect('SELECT COUNT(*) AS n FROM review_log')
              .getSingle())
          .read<int>('n');

  test(
    'a busy database writes nothing and keeps the session open; the retry '
    'records the turn once (IT-CONT-011, UC-STUDY-001 E2, BR-STUDY-004)',
    () async {
      final id = await selfAssessing(1);
      schedules.fault = sqlite3.SqliteException(
        extendedResultCode: 5,
        message: 'database is locked',
      );

      await expectLater(turn(id, _good), throwsA(isA<DatabaseLockedFailure>()));

      final session = await sessionOf(db, id);
      expect(session.read<String>('status'), 'in_progress');
      expect(session.read<int>('cursor'), 1);
      expect(await logCount(), 0);
      expect((await scheduleRowOf(db, 'c1')).data['learned_at'], isNull);

      await answer(id, _good);

      expect(await turnKindsOf(db, 'c1'), ['learning']);
      expect((await sessionOf(db, id)).read<String>('status'), 'completed');
    },
  );

  test('a fatal error rolls the turn back and closes the session as failed; '
      'the turns before it stay (IT-CONT-012, UC-STUDY-001 E3, BR-STUDY-018, '
      'BR-STUDY-019)', () async {
    final id = await selfAssessing(3);
    await answer(id, _good);
    await answer(id, _good);
    final third = (await servedCard(db, id))!;
    schedules.fault = sqlite3.SqliteException(
      extendedResultCode: 11,
      message: 'database disk image is malformed',
    );

    await expectLater(turn(id, _good), throwsA(isA<UnknownDatabaseFailure>()));

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'failed');
    expect(session.read<String>('end_reason'), 'persistence_error');
    expect(await logCount(), 2);
    expect(await turnKindsOf(db, third), isEmpty);
    expect((await scheduleRowOf(db, third)).data['learned_at'], isNull);
  });

  test('when closing the session fails too, the turn keeps its own failure '
      '(spec §8.3)', () async {
    final sessions = _BrokenSessions(
      answerError: const UnknownDatabaseFailure(cause: 'disk'),
      failError: const DatabaseLockedFailure(cause: 'busy'),
    );

    await expectLater(
      AnswerStudyTurnUseCase(sessions)(
        sessionId: 's1',
        cardId: 'c1',
        answer: const AdvanceAnswer(),
      ),
      throwsA(isA<UnknownDatabaseFailure>()),
    );
    expect(sessions.failed, ['s1']);
  });

  test('a refusal comes back as it is and leaves the session open', () async {
    final sessions = _BrokenSessions();

    final result = await AnswerStudyTurnUseCase(sessions)(
      sessionId: 's1',
      cardId: 'c1',
      answer: const AdvanceAnswer(),
    );

    expect(
      (result as Rejected<void, StudyRejection>).reason,
      StudyRejection.notCurrentCard,
    );
    expect(sessions.failed, isEmpty);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/fail_session_test.dart \
  test/features/study/domain/answer_study_turn_use_case_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither file compiles. The first errors: `Error: The method 'failSession' isn't defined for the type 'StudySessionRepositoryImpl'.`, `Error: Method not found: 'AnswerStudyTurnUseCase'.`, `Error: Error when reading 'lib/features/study/domain/usecases/answer_study_turn_use_case.dart': No such file or directory`

- [ ] **Step 3: Fail an open session**

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
          return _answer(session, root, cardId, answer, at);
      }
    });
  }
```

with

```dart
          return _answer(session, root, cardId, answer, at);
      }
    });
  }

  @override
  Future<void> failSession({required String sessionId, DateTime? now}) {
    final at = now ?? _now();
    return _write(() async {
      final session = await _dao.sessionRow(sessionId);
      if (session?.status != SessionStatus.inProgress.code) return;
      await _dao.endSession(
        sessionId,
        status: SessionStatus.failed,
        reason: SessionEndReason.persistenceError,
        now: at,
      );
    });
  }
```

In `lib/features/study/domain/repositories/study_session_repository.dart`:

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

  /// UC-STUDY-001 E3: an open session becomes `failed`/`persistence_error`
  /// (BR-STUDY-018), and the turns it recorded stay (BR-STUDY-019). A
  /// session that has ended, or is gone, is left as it is. Only the E3 path
  /// of `AnswerStudyTurnUseCase` calls it (spec D9).
  Future<void> failSession({required String sessionId, DateTime? now});
}
```

- [ ] **Step 4: Write the use case with the E2/E3 policy**

Create `lib/features/study/domain/usecases/answer_study_turn_use_case.dart`:

```dart
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';

/// UC-STUDY-001 steps 6–13: [call] answers the card the session serves. A
/// busy database writes nothing, and the person retries the same answer
/// (E2, BR-STUDY-004). Any other database failure has rolled the turn back;
/// the session is then closed as `failed` in a write of its own, and the
/// failure reaches the UI (E3, BR-STUDY-018; spec D9).
final class AnswerStudyTurnUseCase {
  const AnswerStudyTurnUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({
    required String sessionId,
    required String cardId,
    required StudyAnswer answer,
  }) async {
    try {
      return await _sessions.answerTurn(
        sessionId: sessionId,
        cardId: cardId,
        answer: answer,
      );
    } on DatabaseLockedFailure {
      rethrow;
    } on Failure catch (failure, stackTrace) {
      await _close(sessionId);
      Error.throwWithStackTrace(failure, stackTrace);
    }
  }

  Future<void> _close(String sessionId) async {
    try {
      await _sessions.failSession(sessionId: sessionId);
    } on Failure {
      // The storage that failed the turn failed this write as well. The
      // person sees the turn's failure; the session stays in_progress, so
      // Continue meets the same storage, and abandonStaleSessions closes it
      // on a later day (spec §8.3).
    }
  }
}
```

- [ ] **Step 5: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/study/data/fail_session_test.dart \
  test/features/study/domain/answer_study_turn_use_case_test.dart
```

Expected: `+6: All tests passed!`

- [ ] **Step 7: Run the phased gate**

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

Expected: `No issues found!`; `+1107: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 8: Commit**

```bash
git add docs/_generated \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  lib/features/study/domain/usecases/answer_study_turn_use_case.dart \
  test/features/study/data/fail_session_test.dart \
  test/features/study/domain/answer_study_turn_use_case_test.dart \
  test/support/study_fixtures.dart
git commit -F - <<'EOF'
feat(study): close a session as failed when a turn cannot be written

AnswerStudyTurnUseCase lets a busy database fail the turn with nothing
written, for the person to retry (UC-STUDY-001 E2, BR-STUDY-004). Any other
failure has rolled the turn back; the use case then closes the session as
failed/persistence_error in a write of its own and reports the failure
(E3, BR-STUDY-018). The turns recorded before stay (BR-STUDY-019).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 7: Leave, continue and close stale sessions

**Files:**
- Create: `lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart`, `lib/features/study/domain/usecases/abandon_study_session_use_case.dart`, `lib/features/study/domain/usecases/resume_study_session_use_case.dart`
- Modify: `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`, `docs/features/study/data.md`
- Test (create): `test/features/study/data/session_endings_test.dart`, `test/features/study/domain/session_ending_use_cases_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 5 (`_live`, `_progress` in the session repository).
- Produces:
  - On `StudySessionRepository`:
    `abandonSession({required String sessionId, DateTime? now})` and
    `resumeSession({required String sessionId, DateTime? now})`, both
    `Future<Outcome<void, StudyRejection>>`, and
    `Future<void> abandonStaleSessions({DateTime? now})`.
  - `StudySessionDao.closeStaleSessions({required DateTime now, required DateTime startOfToday})`.
  - `AbandonStudySessionUseCase` and `ResumeStudySessionUseCase` —
    `call({required String sessionId})`; `AbandonStaleSessionsUseCase` —
    `Future<void> call()`.

Spec §7.5 and D12. Continue refuses a closed session, closes a session of
an earlier day as `interrupted` (BR-STUDY-072) and a stale one as
`invalidated`, and otherwise settles the session: when the cards left in its
current round were deleted, it moves on as after a turn, and completes with
nothing left.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/data/session_endings_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/entities/deck_entity.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/srs_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 A3 and A3b: leaving a session, Continue, and the sessions of
// earlier days.

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
  var clock = DateTime(2026, 9, 24, 9);
  setUp(() {
    clock = DateTime(2026, 9, 24, 9);
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => clock);
    entries = studyEntryRepository(db, () => clock);
    sessions = studySessionRepository(db, () => clock);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  /// A learning session on the new cards [cardIds] of a fresh [type] tree.
  Future<(DeckEntity, String)> learning(
    List<String> cardIds, [
    SchedulerType type = SchedulerType.eightBox,
  ]) async {
    final root = await decks.root('Korean', type);
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final id in cardIds) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final opened = await entries.openLearningSession(deckId: leaf.id);
    return (leaf, (opened as Ok<String, StudyRejection>).value);
  }

  Future<void> answer(String sessionId, StudyAnswer answer) async => expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: (await servedCard(db, sessionId))!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
  );

  Future<List<Map<String, Object?>>> queueRows(String sessionId) async => [
    for (final row
        in await db
            .customSelect(
              'SELECT * FROM study_queue_items WHERE session_id = ?'
              ' ORDER BY mode, round, position',
              variables: [Variable(sessionId)],
            )
            .get())
      row.data,
  ];

  Future<void> deleteCards(Set<String> cardIds) async {
    final schedules = ScheduleRepositoryImpl(db, now: () => clock);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => clock),
      now: () => clock,
    );
    expect(
      await cards.deleteCards(cardIds: cardIds),
      isA<Ok<void, CardRejection>>(),
    );
  }

  test('leaving ends the session as user_exit and keeps its turns; a '
      'session that has ended cannot be left again (BR-STUDY-014, '
      'BR-STUDY-019; UC-STUDY-001 A3)', () async {
    final (_, id) = await learning(['c1'], SchedulerType.sm2);
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.again));

    expect(
      await sessions.abandonSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'abandoned');
    expect(session.read<String>('end_reason'), 'user_exit');
    expect(session.read<DateTime>('ended_at'), clock);
    expect(await turnKindsOf(db, 'c1'), ['learning']);
    expect(
      await sessions.abandonSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
  });

  test('Continue on the same day finds the session where it stopped: the '
      'same card, cursor and queue (IT-CONT-001; UC-STUDY-001 A3b)', () async {
    final (_, id) = await learning(['a', 'b', 'c']);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    final served = await servedCard(db, id);
    final rows = await queueRows(id);
    clock = DateTime(2026, 9, 24, 22);

    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    expect(await servedCard(db, id), served);
    expect((await sessionOf(db, id)).read<int>('cursor'), 2);
    expect(await queueRows(id), rows);
  });

  test('a card added after the session opened never joins its queue '
      '(IT-CONT-006)', () async {
    final (leaf, id) = await learning(['a', 'b']);
    await insertCard(db, id: 'late', deckId: leaf.id, back: 'late');
    await sessions.resumeSession(sessionId: id);

    while ((await sessionOf(db, id)).read<String>('status') == 'in_progress') {
      final mode = (await sessionOf(db, id)).read<String>('current_mode');
      await answer(
        id,
        mode == 'browse'
            ? const AdvanceAnswer()
            : const GradedAnswer(isCorrect: true),
      );
    }

    final lateRows = await db
        .customSelect("SELECT 1 FROM study_queue_items WHERE card_id = 'late'")
        .get();
    expect(lateRows, isEmpty);
    expect(await turnKindsOf(db, 'late'), isEmpty);
    expect((await scheduleRowOf(db, 'late')).data['learned_at'], isNull);
  });

  test('a session from an earlier local day is closed as interrupted and '
      'refused as sessionExpired; its turns stay (IT-CONT-003, '
      'BR-STUDY-072)', () async {
    final (_, id) = await learning(['c1'], SchedulerType.sm2);
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.again));
    clock = DateTime(2026, 9, 25, 0, 30);

    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.sessionExpired),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'abandoned');
    expect(session.read<String>('end_reason'), 'interrupted');
    expect(session.read<DateTime>('ended_at'), clock);
    expect(await turnKindsOf(db, 'c1'), ['learning']);
    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.sessionClosed),
    );
  });

  test('Continue on a session whose root was reset since invalidates it '
      '(BR-STUDY-017)', () async {
    final (_, id) = await learning(['c1']);
    final rootId = (await sessionOf(db, id)).read<String>('root_id');
    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      rootId,
    ]);
    await db.customStatement('UPDATE card_schedule SET generation = 2');

    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.staleGeneration),
    );

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'invalidated');
    expect(session.read<String>('end_reason'), 'stale_generation');
  });

  test('when the cards left in the current stage were deleted, Continue '
      'moves on to the next stage, and a session with nothing left '
      'completes (spec D12, BR-STUDY-013)', () async {
    final (_, id) = await learning(['a', 'b', 'c']);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    final last = (await servedCard(db, id))!;
    await deleteCards({last});

    expect(await servedCard(db, id), isNull);
    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    expect((await sessionOf(db, id)).read<String>('current_mode'), 'match');

    await deleteCards({'a', 'b', 'c'}..remove(last));
    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );
    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'completed');
    expect(session.data['end_reason'], isNull);
  });

  test('Continue or leaving a session whose deck was deleted is notFound: '
      'the session went with the deck (IT-CONT-007)', () async {
    final (leaf, id) = await learning(['c1']);
    expect(
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<void, DeckRejection>>(),
    );

    expect(
      await sessions.resumeSession(sessionId: id),
      _refusedWith(StudyRejection.notFound),
    );
    expect(
      await sessions.abandonSession(sessionId: id),
      _refusedWith(StudyRejection.notFound),
    );
  });

  test('when the app starts, the open session of an earlier day closes as '
      "interrupted, and one of today's stays open (BR-STUDY-072; "
      'UC-STUDY-001 A3b)', () async {
    final (leaf, earlier) = await learning(['c1']);
    clock = DateTime(2026, 9, 25, 8);

    await sessions.abandonStaleSessions();

    final stale = await sessionOf(db, earlier);
    expect(stale.read<String>('status'), 'abandoned');
    expect(stale.read<String>('end_reason'), 'interrupted');
    expect(stale.read<DateTime>('ended_at'), clock);

    final opened = await entries.openLearningSession(deckId: leaf.id);
    final today = (opened as Ok<String, StudyRejection>).value;
    await sessions.abandonStaleSessions();
    expect((await sessionOf(db, today)).read<String>('status'), 'in_progress');
  });

  test('when the last cards of a round were deleted after a wrong answer, '
      'Continue builds the next round and serves it (spec D7, D12)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 20), ('b', 21), ('c', 22)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        back: 'meaning $id',
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
        box: 2,
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    await answer(id, const GradedAnswer(isCorrect: false));
    await deleteCards({'b', 'c'});
    expect(await servedCard(db, id), isNull);

    expect(
      await sessions.resumeSession(sessionId: id),
      isA<Ok<void, StudyRejection>>(),
    );

    expect(await servedCard(db, id), 'a');
    expect(await queueOf(db, id, 'recall', round: 2), ['a']);
    expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
  });

  test('an answer on a card deleted after it was served is refused as '
      'notCurrentCard and writes nothing; the next card is served '
      '(spec §7.3 step 2)', () async {
    final (_, id) = await learning(['a', 'b', 'c']);
    final served = (await servedCard(db, id))!;
    await deleteCards({served});

    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: served,
        answer: const AdvanceAnswer(),
      ),
      _refusedWith(StudyRejection.notCurrentCard),
    );

    expect((await sessionOf(db, id)).read<int>('cursor'), 0);
    expect(await servedCard(db, id), isNot(served));
  });

  test('a session keeps taking answers after midnight: only Continue and the '
      'app start close a session of an earlier day (BR-STUDY-072)', () async {
    clock = DateTime(2026, 9, 24, 23, 50);
    final (_, id) = await learning(['a', 'b']);
    await answer(id, const AdvanceAnswer());
    clock = DateTime(2026, 9, 25, 0, 10);

    await answer(id, const AdvanceAnswer());

    final session = await sessionOf(db, id);
    expect(session.read<String>('status'), 'in_progress');
    expect(session.read<int>('cursor'), 2);
  });
}
```

Create `test/features/study/domain/session_ending_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/usecases/abandon_stale_sessions_use_case.dart';
import 'package:memox/features/study/domain/usecases/abandon_study_session_use_case.dart';
import 'package:memox/features/study/domain/usecases/resume_study_session_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 A3 and A3b through the use cases the session screen and the
// app start call.

void main() {
  late AppDatabase db;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  var clock = DateTime(2026, 9, 24, 9);
  setUp(() {
    clock = DateTime(2026, 9, 24, 9);
    db = openTestDatabase();
    entries = studyEntryRepository(db, () => clock);
    sessions = studySessionRepository(db, () => clock);
  });
  tearDown(() => db.close());

  Future<String> opened() async {
    final decks = DeckRepositoryImpl(db, now: () => clock);
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    final result = await entries.openLearningSession(deckId: leaf.id);
    return (result as Ok<String, StudyRejection>).value;
  }

  Future<String> statusOf(String sessionId) async =>
      (await sessionOf(db, sessionId)).read<String>('status');

  test('AbandonStudySession leaves the session (UC-STUDY-001 A3)', () async {
    final id = await opened();

    final result = await AbandonStudySessionUseCase(sessions)(sessionId: id);

    expect(result, isA<Ok<void, StudyRejection>>());
    expect(await statusOf(id), 'abandoned');
  });

  test('ResumeStudySession continues a session of the same day '
      '(UC-STUDY-001 A3b)', () async {
    final id = await opened();

    final result = await ResumeStudySessionUseCase(sessions)(sessionId: id);

    expect(result, isA<Ok<void, StudyRejection>>());
    expect(await statusOf(id), 'in_progress');
  });

  test('AbandonStaleSessions closes the sessions of earlier days '
      '(BR-STUDY-072)', () async {
    final id = await opened();
    clock = DateTime(2026, 9, 25, 7);

    await AbandonStaleSessionsUseCase(sessions)();

    expect(await statusOf(id), 'abandoned');
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/session_endings_test.dart \
  test/features/study/domain/session_ending_use_cases_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither file compiles. The first errors: `Error: The method 'resumeSession' isn't defined for the type 'StudySessionRepositoryImpl'.`, `Error: The method 'abandonSession' isn't defined for the type 'StudySessionRepositoryImpl'.`, `Error: The method 'abandonStaleSessions' isn't defined for the type 'StudySessionRepositoryImpl'.`

- [ ] **Step 3: Leave, continue and close stale sessions in the repository**

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart

  Future<void> insertSession(StudySessionCompanion row) =>
```

with

```dart

  /// Ends as `interrupted` every open session that started before
  /// [startOfToday] (BR-STUDY-072).
  Future<void> closeStaleSessions({
    required DateTime now,
    required DateTime startOfToday,
  }) =>
      (_db.update(_db.studySession)..where(
            (session) =>
                session.status.equals(SessionStatus.inProgress.code) &
                session.startedAt.isSmallerThanValue(startOfToday),
          ))
          .write(
            StudySessionCompanion(
              status: Value(SessionStatus.abandoned.code),
              endReason: Value(SessionEndReason.interrupted.code),
              endedAt: Value(now),
            ),
          );

  Future<void> insertSession(StudySessionCompanion row) =>
```

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
```

with

```dart
import 'package:memox/features/card/domain/repositories/card_repository.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/srs/domain/models/review_turn_model.dart';
```

Replace

```dart
          return _answer(session, root, cardId, answer, at);
      }
    });
  }

  @override
```

with

```dart
          return _answer(session, root, cardId, answer, at);
      }
    });
  }

  @override
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final session = await _dao.sessionRow(sessionId);
      if (session == null) return const Rejected(StudyRejection.notFound);
      if (session.status != SessionStatus.inProgress.code) {
        return const Rejected(StudyRejection.sessionClosed);
      }
      await _dao.endSession(
        sessionId,
        status: SessionStatus.abandoned,
        reason: SessionEndReason.userExit,
        now: at,
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _write(() async {
      final session = await _dao.sessionRow(sessionId);
      if (session != null &&
          session.status == SessionStatus.inProgress.code &&
          session.startedAt.isBefore(startOfLocalDay(at))) {
        await _dao.endSession(
          sessionId,
          status: SessionStatus.abandoned,
          reason: SessionEndReason.interrupted,
          now: at,
        );
        return const Rejected(StudyRejection.sessionExpired);
      }
      switch (await _live(session, at)) {
        case Rejected(:final reason):
          return Rejected(reason);
        case Ok(value: (final open, final root)):
          await _progress(
            open,
            SchedulerType.fromCode(root.schedulerType!),
            at,
          );
          return const Ok(null);
      }
    });
  }

  @override
  Future<void> abandonStaleSessions({DateTime? now}) {
    final at = now ?? _now();
    return _write(
      () => _dao.closeStaleSessions(now: at, startOfToday: startOfLocalDay(at)),
    );
  }

  @override
```

In `lib/features/study/domain/repositories/study_session_repository.dart`:

Replace

```dart
  Future<void> failSession({required String sessionId, DateTime? now});
}
```

with

```dart
  Future<void> failSession({required String sessionId, DateTime? now});

  /// UC-STUDY-001 A3: the person leaves an open session. It becomes
  /// `abandoned`/`user_exit` (BR-STUDY-014) and keeps its turns
  /// (BR-STUDY-019); sessionClosed when it has ended, notFound when it is
  /// gone.
  Future<Outcome<void, StudyRejection>> abandonSession({
    required String sessionId,
    DateTime? now,
  });

  /// UC-STUDY-001 A3b, Continue. A session of an earlier local day is closed
  /// as `abandoned`/`interrupted` and refused as sessionExpired
  /// (BR-STUDY-072); one whose root was reset since is invalidated and
  /// refused as staleGeneration (BR-STUDY-017). Otherwise the session is
  /// settled: when the cards left in its current round were deleted, it
  /// moves on as after a turn, and completes with nothing left (spec D12).
  Future<Outcome<void, StudyRejection>> resumeSession({
    required String sessionId,
    DateTime? now,
  });

  /// UC-STUDY-001 A3b: every open session that started before today's
  /// local midnight becomes `abandoned`/`interrupted` (BR-STUDY-072). The app
  /// calls it when it starts; no read does (BR-STUDY-075).
  Future<void> abandonStaleSessions({DateTime? now});
}
```

- [ ] **Step 4: Write the three use cases**

Create `lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart`:

```dart
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 A3b: when the app starts, the sessions left open on an
/// earlier local day close as `interrupted` (BR-STUDY-072).
final class AbandonStaleSessionsUseCase {
  const AbandonStaleSessionsUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<void> call() => _sessions.abandonStaleSessions();
}
```

Create `lib/features/study/domain/usecases/abandon_study_session_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 A3: ✕ leaves the session for good; its turns stay
/// (BR-STUDY-014, BR-STUDY-019).
final class AbandonStudySessionUseCase {
  const AbandonStudySessionUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({required String sessionId}) =>
      _sessions.abandonSession(sessionId: sessionId);
}
```

Create `lib/features/study/domain/usecases/resume_study_session_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 A3b: Continue, on a session of the current local day
/// (BR-STUDY-072). A session of an earlier day, or one whose root was reset,
/// is closed and refused.
final class ResumeStudySessionUseCase {
  const ResumeStudySessionUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Future<Outcome<void, StudyRejection>> call({required String sessionId}) =>
      _sessions.resumeSession(sessionId: sessionId);
}
```

- [ ] **Step 5: Record in data.md that a queue with nothing left completes**

In `docs/features/study/data.md`:

Replace

```markdown
|---|---|---|
| in_progress | completed | hết queue (BR-STUDY-013) |
| in_progress | abandoned | người dùng thoát hoặc chọn đường mới thay vì tiếp tục (`user_exit`, BR-STUDY-014, BR-STUDY-072), hoặc phiên của ngày học trước không được tiếp tục (`interrupted`, BR-STUDY-072) |
```

with

```markdown
|---|---|---|
| in_progress | completed | hết queue (BR-STUDY-013), kể cả khi các dòng còn lại biến mất vì thẻ của chúng bị xóa hẳn: Tiếp tục phiên sẽ đi tiếp và kết thúc nó. `content_deleted` chỉ dành cho nội dung vào Trash |
| in_progress | abandoned | người dùng thoát hoặc chọn đường mới thay vì tiếp tục (`user_exit`, BR-STUDY-014, BR-STUDY-072), hoặc phiên của ngày học trước không được tiếp tục (`interrupted`, BR-STUDY-072) |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 6: Run the task's tests**

```bash
flutter test test/features/study/data/session_endings_test.dart \
  test/features/study/domain/session_ending_use_cases_test.dart
```

Expected: `+14: All tests passed!`

- [ ] **Step 7: Run the phased gate**

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

Expected: `No issues found!`; `+1121: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 8: Commit**

```bash
git add docs/_generated \
  docs/features/study/data.md \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart \
  lib/features/study/domain/usecases/abandon_study_session_use_case.dart \
  lib/features/study/domain/usecases/resume_study_session_use_case.dart \
  test/features/study/data/session_endings_test.dart \
  test/features/study/domain/session_ending_use_cases_test.dart
git commit -F - <<'EOF'
feat(study): leave, continue and close stale study sessions

Leaving ends an open session as abandoned/user_exit and keeps its turns
(BR-STUDY-014, BR-STUDY-019). Continue takes up a session of the same day
where it stopped, closes one of an earlier day as interrupted and one from
before a reset as invalidated (BR-STUDY-072, BR-STUDY-017), and moves on when
the cards left in its round were deleted. When the app starts, the open
sessions of earlier days close as interrupted.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 8: Watch the session screen

**Files:**
- Create: `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/data/mappers/study_session_view_mapper.dart`, `lib/features/study/domain/models/study_session_view_model.dart`, `lib/features/study/domain/usecases/watch_study_session_use_case.dart`
- Modify: `lib/features/study/data/repositories/study_session_repository_impl.dart`, `lib/features/study/domain/repositories/study_session_repository.dart`
- Test (create): `test/features/study/data/watch_session_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Tasks 5–7; `CardRow` (the `card` table's row class).
- Produces:
  - In `domain/models/study_session_view_model.dart`: `StudySessionView`
    (`sessionId`, `deckId`, `deckName`, `kind`, `status`, `endReason`,
    `currentMode`, `direction`, `stages`, `currentItem`, `progress`, `summary`;
    getters `currentStageIndex`, `currentRound`, `isStalled`), `StudyItem`,
    `RoundProgress({completed, total})`,
    `SessionSummary({cardCount, learnedCardCount, wrongTurnCount})`.
  - `StudySessionRepository.watchSession(String sessionId)` —
    `Stream<StudySessionView?>`.
  - `StudyViewDao(AppDatabase db)`: `watchSessionRow`, `cardRow`, `modesOf`,
    `roundCounts`, `summaryCounts`, with the records `SessionViewRow`,
    `RoundCounts`, `SummaryCounts`.
  - In `data/mappers/study_session_view_mapper.dart`: `studySessionViewOf`,
    `lapseActionsOf(SchedulerType)` and the record `ServedRow`.
  - `WatchStudySessionUseCase(StudySessionRepository sessions)` —
    `Stream<Outcome<StudySessionView, StudyRejection>> call({required String sessionId})`.

Spec §8.2 and D11, D12; Clarification 9. The view watches every row the
screen can see and reads, in the same emission, the card an open session serves
with the counts of its round (BR-STUDY-049), or the summary of an ended one.
A session that is open with nothing to serve is stalled, and Continue settles
it.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/data/watch_session_test.dart`:

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
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/srs/domain/models/review_action_model.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/usecases/watch_study_session_use_case.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 6–13 and E5: the read model of the session screen.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudySessionView> viewOf(String sessionId) async =>
      (await sessions.watchSession(sessionId).first)!;

  Future<(DeckEntity, DeckEntity)> tree([
    SchedulerType type = SchedulerType.eightBox,
  ]) async {
    final root = await decks.root('Korean', type);
    return (root, await decks.sub(root.id, 'Lesson'));
  }

  Future<String> learning(DeckEntity leaf) async =>
      ((await entries.openLearningSession(
        deckId: leaf.id,
      )) as Ok<String, StudyRejection>).value;

  Future<void> answer(String sessionId, StudyAnswer answer) async => expect(
    await sessions.answerTurn(
      sessionId: sessionId,
      cardId: (await servedCard(db, sessionId))!,
      answer: answer,
    ),
    isA<Ok<void, StudyRejection>>(),
  );

  Future<void> deleteCards(Set<String> cardIds) async {
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );
    expect(
      await cards.deleteCards(cardIds: cardIds),
      isA<Ok<void, CardRejection>>(),
    );
  }

  test('the view names the deck, the kind and the stages, and serves the '
      'head card with the count of its round (IT-MODE-001, '
      'BR-STUDY-049)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        front: 'front $id',
        back: 'back $id',
        example: 'example $id',
      );
    }
    final id = await learning(leaf);
    final served = await servedCard(db, id);

    final view = await viewOf(id);

    expect((view.deckId, view.deckName), (leaf.id, 'Lesson'));
    expect(view.kind, SessionKind.learning);
    expect(view.status, SessionStatus.inProgress);
    expect(view.stages, [
      StudyMode.browse,
      StudyMode.match,
      StudyMode.recall,
      StudyMode.fill,
    ]);
    expect((view.currentMode, view.currentStageIndex), (StudyMode.browse, 0));
    final item = view.currentItem!;
    expect(item.cardId, served);
    expect(
      (item.front, item.back, item.example),
      ('front $served', 'back $served', 'example $served'),
    );
    expect((view.currentRound, item.answersInSession), (1, 0));
    expect((view.progress!.completed, view.progress!.total), (0, 3));
    expect(view.isStalled, isFalse);
    expect(view.summary, isNull);
  });

  test('the view emits again after a turn: the next card, the round counted '
      '(BR-STUDY-049)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    final first = (await viewOf(id)).currentItem!.cardId;

    final next = expectLater(
      sessions.watchSession(id),
      emitsThrough(
        isA<StudySessionView>()
            .having((view) => view.progress?.completed, 'completed', 1)
            .having((view) => view.currentItem?.cardId, 'card', isNot(first)),
      ),
    );
    await answer(id, const AdvanceAnswer());
    await next;
  });

  test('an sm2 self_assess review shows the direction chosen, and each item '
      'its own direction (BR-MODE-015)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.selfAssess,
      direction: DirectionChoice.meaningToKorean,
    );
    final id = (opened as Ok<String, StudyRejection>).value;

    final view = await viewOf(id);

    expect(view.kind, SessionKind.reviewing);
    expect(view.stages, [StudyMode.selfAssess]);
    expect(view.direction, DirectionChoice.meaningToKorean);
    expect(view.currentItem!.cardId, 'a');
    expect(view.currentItem!.direction, QuestionDirection.meaningToKorean);
  });

  test(
    'a completed learning session sums up its cards, the ones that '
    'finished learning and the wrong turns (IT-CONT-005, spec D11)',
    () async {
      final (_, leaf) = await tree(SchedulerType.sm2);
      for (final id in ['c1', 'c2']) {
        await insertCard(db, id: id, deckId: leaf.id);
      }
      final id = await learning(leaf);
      await answer(id, const AdvanceAnswer());
      await answer(id, const AdvanceAnswer());
      await answer(id, const SelfAssessAnswer(Sm2Action.again));
      await answer(id, const SelfAssessAnswer(Sm2Action.good));
      await answer(id, const SelfAssessAnswer(Sm2Action.good));

      final view = await viewOf(id);

      expect(view.status, SessionStatus.completed);
      expect(view.currentItem, isNull);
      expect(view.isStalled, isFalse);
      final summary = view.summary!;
      expect(
        (summary.cardCount, summary.learnedCardCount, summary.wrongTurnCount),
        (2, 2, 1),
      );
    },
  );

  test('a completed review sums up its cards and wrong turns, with no '
      'learned count (IT-REVIEW-009, spec D11)', () async {
    final (root, leaf) = await tree();
    for (final (id, day) in [('a', 20), ('b', 21)]) {
      await insertCard(
        db,
        id: id,
        deckId: leaf.id,
        learnedAt: DateTime(2026, 9, 1),
        dueAt: DateTime(2026, 9, day),
        box: 3,
      );
    }
    await lockScheduler(db, root.id);
    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    await answer(id, const GradedAnswer(isCorrect: false));
    await answer(id, const GradedAnswer(isCorrect: true));
    await answer(id, const GradedAnswer(isCorrect: true));

    final summary = (await viewOf(id)).summary!;

    expect(
      (summary.cardCount, summary.learnedCardCount, summary.wrongTurnCount),
      (2, null, 1),
    );
  });

  test('a session whose current cards were deleted is stalled until '
      'Continue settles it (spec D12)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b', 'c']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    await deleteCards({(await servedCard(db, id))!});

    final stalled = await viewOf(id);
    expect(stalled.isStalled, isTrue);
    expect((stalled.currentItem, stalled.progress), (null, null));

    await sessions.resumeSession(sessionId: id);
    final settled = await viewOf(id);
    expect(settled.isStalled, isFalse);
    expect(settled.currentMode, StudyMode.match);
  });

  test('once its deck is deleted the session is notFound, and the watch '
      'says so (UC-STUDY-001 A5, E5; IT-CONT-007)', () async {
    final (_, leaf) = await tree();
    await insertCard(db, id: 'c1', deckId: leaf.id);
    final id = await learning(leaf);
    final watch = WatchStudySessionUseCase(sessions)(sessionId: id);

    final gone = expectLater(
      watch,
      emitsThrough(
        isA<Rejected<StudySessionView, StudyRejection>>().having(
          (rejected) => rejected.reason,
          'reason',
          StudyRejection.notFound,
        ),
      ),
    );
    expect(
      await decks.deleteDeck(deckId: leaf.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await gone;
  });

  test('a read error reaches the watch as a Failure and moves nothing: the '
      'same card is served once the read works again (IT-CONT-013)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    final served = await servedCard(db, id);
    await db.customStatement('ALTER TABLE card RENAME TO card_unreadable');

    await expectLater(
      sessions.watchSession(id),
      emitsError(isA<UnknownDatabaseFailure>()),
    );

    await db.customStatement('ALTER TABLE card_unreadable RENAME TO card');
    final view = await viewOf(id);
    expect(view.currentItem!.cardId, served);
    expect((await sessionOf(db, id)).read<int>('cursor'), 1);
  });

  test('a reset of the root while the session is open ends it: the view '
      'reports invalidated/scheduler_reset with its summary, and an answer '
      'is sessionClosed (BR-STUDY-015, UC-SRS-001)', () async {
    final (root, leaf) = await tree(SchedulerType.sm2);
    for (final id in ['c1', 'c2']) {
      await insertCard(db, id: id, deckId: leaf.id);
    }
    final id = await learning(leaf);
    await answer(id, const AdvanceAnswer());
    await answer(id, const AdvanceAnswer());
    await answer(id, const SelfAssessAnswer(Sm2Action.good));

    expect(
      await ScheduleRepositoryImpl(
        db,
        now: () => now,
      ).resetLearning(rootDeckId: root.id),
      isA<Ok<void, SrsRejection>>(),
    );

    final view = await viewOf(id);
    expect(
      (view.status, view.endReason),
      (SessionStatus.invalidated, SessionEndReason.schedulerReset),
    );
    expect((view.currentItem, view.isStalled), (null, false));
    expect(view.summary!.cardCount, 2);
    final served = await db
        .customSelect(
          "SELECT card_id FROM study_queue_items WHERE status = 'pending'",
        )
        .get();
    expect(
      await sessions.answerTurn(
        sessionId: id,
        cardId: served.first.read<String>('card_id'),
        answer: const SelfAssessAnswer(Sm2Action.good),
      ),
      isA<Rejected<void, StudyRejection>>().having(
        (rejected) => rejected.reason,
        'reason',
        StudyRejection.sessionClosed,
      ),
    );
  });

  test('a card edited during the session shows its new text; the queue '
      'keeps its order (IT-CONT-006)', () async {
    final (_, leaf) = await tree();
    for (final id in ['a', 'b']) {
      await insertCard(db, id: id, deckId: leaf.id, back: 'meaning $id');
    }
    final id = await learning(leaf);
    final served = (await servedCard(db, id))!;
    final order = await queueOf(db, id, 'browse');
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );

    expect(
      await cards.editCard(
        cardId: served,
        draft: const CardDraft(front: 'edited', back: 'meaning edited'),
      ),
      isA<Ok<void, CardRejection>>(),
    );

    final item = (await viewOf(id)).currentItem!;
    expect(
      (item.cardId, item.front, item.back),
      (served, 'edited', 'meaning edited'),
    );
    expect(await queueOf(db, id, 'browse'), order);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/watch_session_test.dart
```

Expected: `+0 -1: Some tests failed.` The file does not compile. The first errors: `Error: 'StudySessionView' isn't a type.`, `Error: The method 'watchSession' isn't defined for the type 'StudySessionRepositoryImpl'.`, `Error: Error when reading 'lib/features/study/domain/models/study_session_view_model.dart': No such file or directory`

- [ ] **Step 3: Write the session view**

Create `lib/features/study/domain/models/study_session_view_model.dart`:

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The session screen (UC-STUDY-001 steps 6–13; spec §8.2). Package 2b adds
/// the `match` board, the `guess` options and the `recall` timer.
final class StudySessionView {
  const StudySessionView({
    required this.sessionId,
    required this.deckId,
    required this.deckName,
    required this.kind,
    required this.status,
    required this.endReason,
    required this.currentMode,
    required this.direction,
    required this.stages,
    required this.currentItem,
    required this.progress,
    required this.summary,
  });

  final String sessionId;
  final String deckId;
  final String deckName;
  final SessionKind kind;
  final SessionStatus status;

  /// Why the session ended short of its queue (BR-STUDY-012); null while it
  /// runs and once it completes.
  final SessionEndReason? endReason;
  final StudyMode currentMode;

  /// The choice of an sm2 `self_assess` review (BR-MODE-013); null elsewhere.
  final DirectionChoice? direction;

  /// The stages the session has rows in, in the order it runs them
  /// (IT-MODE-001).
  final List<StudyMode> stages;

  /// The card the session serves (BR-STUDY-005); null once the session has
  /// ended, and while it is stalled.
  final StudyItem? currentItem;

  /// The rows of [currentItem]'s round, done and in all: the counter
  /// measures the whole round (BR-STUDY-049). Null with no current item.
  final RoundProgress? progress;

  /// Once the session has ended (spec D11).
  final SessionSummary? summary;

  int get currentStageIndex => stages.indexOf(currentMode);

  /// The round the session serves in its current stage.
  int? get currentRound => currentItem?.round;

  /// Open, with nothing to serve: the cards of its current round were
  /// deleted. Continue settles it (spec D12).
  bool get isStalled =>
      status == SessionStatus.inProgress && currentItem == null;
}

/// The card a session serves, with its queue row (spec §8.2).
final class StudyItem {
  const StudyItem({
    required this.cardId,
    required this.front,
    required this.back,
    required this.example,
    required this.hint,
    required this.pronunciation,
    required this.round,
    required this.answersInSession,
    required this.direction,
    required this.remainingMs,
    required this.isRevealed,
  });

  final String cardId;
  final String front;
  final String back;
  final String? example;
  final String? hint;
  final String? pronunciation;
  final int round;

  /// The turns the row has taken (BR-STUDY-073).
  final int answersInSession;

  /// The side this card asks from in an sm2 `self_assess` review
  /// (BR-MODE-015); null elsewhere.
  final QuestionDirection? direction;

  /// `recall` only: the time left of a turn in progress (BR-STUDY-036).
  final int? remainingMs;
  final bool isRevealed;
}

/// The rows of a round, done and in all.
final class RoundProgress {
  const RoundProgress({required this.completed, required this.total});

  final int completed;
  final int total;
}

/// What a session did, once it has ended (spec D11; IT-CONT-005).
final class SessionSummary {
  const SessionSummary({
    required this.cardCount,
    required this.learnedCardCount,
    required this.wrongTurnCount,
  });

  /// The distinct cards of the queue.
  final int cardCount;

  /// In a learning session, its cards that are now learned; null in a
  /// review.
  final int? learnedCardCount;

  /// The session's turns whose action was a lapse (BR-SRS-018).
  final int wrongTurnCount;
}
```

- [ ] **Step 4: Read the screen: the view DAO and its mapper**

Create `lib/features/study/data/datasources/study_view_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// A session row with its deck's name and its root's scheduler code.
typedef SessionViewRow = ({
  StudySession session,
  String deckName,
  String schedulerType,
});

/// The rows of a round, done and in all.
typedef RoundCounts = ({int completed, int total});

/// The counts a session's summary shows (spec D11).
typedef SummaryCounts = ({int cardCount, int learnedCount, int wrongCount});

/// The reads of the study screens (spec §8). They write nothing
/// (BR-STUDY-075), return Drift rows and records, never domain values.
final class StudyViewDao {
  StudyViewDao(this._db);

  final AppDatabase _db;

  /// [sessionId]'s row, with its deck's name and its root's scheduler; null
  /// once the session is gone. Emits again on every write the session
  /// screen can see: the session, its queue, its decks, cards, schedules and
  /// logs.
  Stream<SessionViewRow?> watchSessionRow(String sessionId) => _db
      .customSelect(
        'SELECT s.*, d.name AS deck_name, r.scheduler_type AS root_scheduler'
        ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
        ' JOIN deck r ON r.id = s.root_id WHERE s.id = ?',
        variables: [Variable<String>(sessionId)],
        readsFrom: {
          _db.studySession,
          _db.studyQueueItems,
          _db.deck,
          _db.card,
          _db.cardSchedule,
          _db.reviewLog,
        },
      )
      .watchSingleOrNull()
      .map(
        (row) => row == null
            ? null
            : (
                session: _db.studySession.map(row.data),
                deckName: row.read<String>('deck_name'),
                schedulerType: row.read<String>('root_scheduler'),
              ),
      );

  Future<CardRow?> cardRow(String cardId) => (_db.select(
    _db.card,
  )..where((card) => card.id.equals(cardId))).getSingleOrNull();

  /// The modes [sessionId] has rows in.
  Future<Set<String>> modesOf(String sessionId) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT mode FROM study_queue_items WHERE session_id = ?',
          variables: [Variable<String>(sessionId)],
          readsFrom: {_db.studyQueueItems},
        )
        .get();
    return {for (final row in rows) row.read<String>('mode')};
  }

  Future<RoundCounts> roundCounts(
    String sessionId,
    String mode,
    int round,
  ) async {
    final row = await _db
        .customSelect(
          "SELECT COALESCE(SUM(status = 'completed'), 0) AS completed,"
          ' COUNT(*) AS total FROM study_queue_items'
          ' WHERE session_id = ? AND mode = ? AND round = ?',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(mode),
            Variable<int>(round),
          ],
          readsFrom: {_db.studyQueueItems},
        )
        .getSingle();
    return (
      completed: row.read<int>('completed'),
      total: row.read<int>('total'),
    );
  }

  /// The distinct cards of [sessionId]'s queue, those of them now learned,
  /// and its logs whose action is one of [lapseActions].
  Future<SummaryCounts> summaryCounts(
    String sessionId, {
    required List<String> lapseActions,
  }) async {
    final lapses = List.filled(lapseActions.length, '?').join(', ');
    final row = await _db
        .customSelect(
          'SELECT'
          ' (SELECT COUNT(DISTINCT card_id) FROM study_queue_items'
          '  WHERE session_id = ?) AS card_count,'
          ' (SELECT COUNT(DISTINCT q.card_id) FROM study_queue_items q'
          '  JOIN card_schedule cs ON cs.card_id = q.card_id'
          '  WHERE q.session_id = ? AND cs.learned_at IS NOT NULL)'
          '  AS learned_count,'
          ' (SELECT COUNT(*) FROM review_log WHERE session_id = ?'
          '  AND action IN ($lapses)) AS wrong_count',
          variables: [
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            Variable<String>(sessionId),
            for (final action in lapseActions) Variable<String>(action),
          ],
          readsFrom: {_db.studyQueueItems, _db.cardSchedule, _db.reviewLog},
        )
        .getSingle();
    return (
      cardCount: row.read<int>('card_count'),
      learnedCount: row.read<int>('learned_count'),
      wrongCount: row.read<int>('wrong_count'),
    );
  }
}
```

Create `lib/features/study/data/mappers/study_session_view_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/srs/domain/models/schedulers_model.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The row a session serves, with its card and the counts of its round.
typedef ServedRow = ({StudyQueueItem row, CardRow card, RoundCounts round});

/// The stored `review_log.action` codes of [type]'s lapses (BR-SRS-018).
List<String> lapseActionsOf(SchedulerType type) {
  final scheduler = schedulerFor(type);
  return [
    for (final action in scheduler.supportedActions)
      if (scheduler.isLapse(action)) (action as Enum).name,
  ];
}

/// The session screen (spec §8.2) of [row]: [modes] are the modes its queue
/// has rows in, [served] the row an open session serves, and [counts] what
/// the summary of an ended one shows.
StudySessionView studySessionViewOf(
  SessionViewRow row, {
  required Set<String> modes,
  required ServedRow? served,
  required SummaryCounts? counts,
}) {
  final session = row.session;
  final kind = SessionKind.values.byName(session.sessionKind);
  final chain = stageSequenceOf(SchedulerType.fromCode(row.schedulerType));
  return StudySessionView(
    sessionId: session.id,
    deckId: session.deckId,
    deckName: row.deckName,
    kind: kind,
    status: SessionStatus.fromCode(session.status),
    endReason: switch (session.endReason) {
      final String code => SessionEndReason.fromCode(code),
      null => null,
    },
    currentMode: StudyMode.fromCode(session.currentMode),
    direction: switch (session.direction) {
      final String code => DirectionChoice.fromCode(code),
      null => null,
    },
    stages: [
      for (final mode in chain)
        if (modes.contains(mode.code)) mode,
    ],
    currentItem: served == null ? null : _itemOf(served),
    progress: served == null
        ? null
        : RoundProgress(
            completed: served.round.completed,
            total: served.round.total,
          ),
    summary: counts == null
        ? null
        : SessionSummary(
            cardCount: counts.cardCount,
            learnedCardCount: switch (kind) {
              SessionKind.learning => counts.learnedCount,
              SessionKind.reviewing => null,
            },
            wrongTurnCount: counts.wrongCount,
          ),
  );
}

StudyItem _itemOf(ServedRow served) => StudyItem(
  cardId: served.card.id,
  front: served.card.front,
  back: served.card.back,
  example: served.card.example,
  hint: served.card.hint,
  pronunciation: served.card.pronunciation,
  round: served.row.round,
  answersInSession: served.row.answersInSession,
  direction: switch (served.row.direction) {
    final String code => QuestionDirection.fromCode(code),
    null => null,
  },
  remainingMs: served.row.remainingMs,
  isRevealed: served.row.isRevealed == 1,
);
```

- [ ] **Step 5: Watch the session in the repository**

In `lib/features/study/data/repositories/study_session_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

with

```dart
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_session_view_mapper.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

Replace

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/models/turn_kind_model.dart';
```

Replace

```dart
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
```

with

```dart
       _queue = StudyQueueDao(_db),
       _views = StudyViewDao(_db),
       _now = now ?? DateTime.now,
```

Replace

```dart
  final StudyQueueDao _queue;
  final DateTime Function() _now;
```

with

```dart
  final StudyQueueDao _queue;
  final StudyViewDao _views;
  final DateTime Function() _now;
```

Replace

```dart
        now: at,
      );
    });
  }

  /// [session] and its root while the session is open and its generation
```

with

```dart
        now: at,
      );
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

  /// [session] and its root while the session is open and its generation
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
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
```

Replace

```dart
  Future<void> abandonStaleSessions({DateTime? now});
}
```

with

```dart
  Future<void> abandonStaleSessions({DateTime? now});

  /// UC-STUDY-001 steps 6–13 (spec §8.2): the session screen, again on every
  /// write it can see; null once the session is gone (A5). It writes nothing
  /// (BR-STUDY-075).
  Stream<StudySessionView?> watchSession(String sessionId);
}
```

- [ ] **Step 6: Write the use case**

Create `lib/features/study/domain/usecases/watch_study_session_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study/domain/repositories/study_session_repository.dart';

/// UC-STUDY-001 steps 6–13: the session screen, again after every turn, and
/// notFound once the session is gone with its deck (A5, E5). It writes
/// nothing (BR-STUDY-075).
final class WatchStudySessionUseCase {
  const WatchStudySessionUseCase(this._sessions);

  final StudySessionRepository _sessions;

  Stream<Outcome<StudySessionView, StudyRejection>> call({
    required String sessionId,
  }) => _sessions
      .watchSession(sessionId)
      .map<Outcome<StudySessionView, StudyRejection>>(
        (view) => switch (view) {
          final StudySessionView view => Ok(view),
          null => const Rejected(StudyRejection.notFound),
        },
      );
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

Expected: `No issues found!`; `+1131: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  lib/features/study/data/datasources/study_view_dao.dart \
  lib/features/study/data/mappers/study_session_view_mapper.dart \
  lib/features/study/data/repositories/study_session_repository_impl.dart \
  lib/features/study/domain/models/study_session_view_model.dart \
  lib/features/study/domain/repositories/study_session_repository.dart \
  lib/features/study/domain/usecases/watch_study_session_use_case.dart \
  test/features/study/data/watch_session_test.dart
git commit -F - <<'EOF'
feat(study): watch the session screen

The session screen reads its deck, kind, mode and stages, the card the
session serves with the count of its round (BR-STUDY-049), and once the
session has ended its summary: its cards, the ones that finished learning and
the wrong turns (IT-CONT-005). It emits again after every turn and reports
notFound once the session went with its deck (UC-STUDY-001 A5, E5). An open
session with nothing left to serve reads as stalled.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 9: Watch the Study Entry of a deck, and close the package docs

**Files:**
- Create: `lib/features/study/domain/models/study_entry_model.dart`, `lib/features/study/domain/usecases/watch_study_entry_use_case.dart`
- Modify: `lib/features/study/data/datasources/study_session_dao.dart`, `lib/features/study/data/datasources/study_view_dao.dart`, `lib/features/study/data/repositories/study_entry_repository_impl.dart`, `lib/features/study/domain/repositories/study_entry_repository.dart`, `docs/features/study-mode/README.md`, `docs/features/study/README.md`, `docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md`, `docs/features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md`, `docs/wbs_BE.md`
- Test (create): `test/features/study/data/watch_entry_test.dart`, `test/features/study/domain/watch_study_entry_use_case_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Tasks 3–8; `DayClock`, `watchEachLocalDay`
  (`lib/core/clock/day_clock.dart`); `FakeDayClock` (`test/support/`).
- Produces:
  - In `domain/models/study_entry_model.dart`: `StudyEntry` (`schedulerType`,
    `cardLimit`, `newCardCount`, `dueCardCount`, `nextDueAt`, `reviewModes`,
    `resumableSessionId`), `ReviewModeOption` (`mode`, `cardCount`,
    `unavailableReason`, `isDirectionRequired`) and
    `reviewModeOptions(SchedulerType type, List<StudyCardFacts> dueCards, {required int distinctMeaningCount})`.
  - `StudyEntryRepository.watchEntry({required String deckId, required DateTime now})` —
    `Stream<StudyEntry?>`.
  - `StudySessionDao.subtreeCounts(String deckId, DateTime now)` and
    `typedef SubtreeCounts`; `StudyViewDao.watchDeckRow(String deckId)` and
    `resumableSessionId(String deckId, {required DateTime startOfToday})`.
  - `WatchStudyEntryUseCase(StudyEntryRepository entries, DayClock clock)` —
    `Stream<Outcome<StudyEntry, StudyRejection>> call({required String deckId})`.

Spec §8.1, §11 and D11; Clarifications 7, 8, 10. The entry counts the new
and the due cards of the subtree, offers each review mode with the cards a
review would take and why it cannot run (BR-STUDY-044), and offers Continue
only for this deck's open session of today at the root's generation with a
queue (BR-STUDY-075). The use case follows the local day, so cards fall due at
midnight with no write. This task also closes the package's docs: the `code:`
fields, the two READMEs and the WBS.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/data/watch_entry_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:memox/features/settings/domain/failures/settings_failure.dart';
import 'package:memox/features/settings/domain/models/study_options_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_answer_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 1–2 and 4: the read model of the Study Entry.

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  final now = DateTime(2026, 9, 24, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudyEntry> entryOf(String deckId, [DateTime? at]) async =>
      (await entries.watchEntry(deckId: deckId, now: at ?? now).first)!;

  /// A learned card of [deckId] due at [dueAt], of its own meaning.
  Future<void> learned(
    String deckId,
    String id,
    DateTime dueAt, {
    String? example,
  }) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    example: example,
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  Future<void> limitCards(int cardLimit) async => expect(
    await SettingsRepositoryImpl(db, now: () => now).saveStudyDefaults(
      options: StudyOptions(
        cardLimit: cardLimit,
        newCardOrder: NewCardOrder.created,
      ),
    ),
    isA<Ok<void, SettingsRejection>>(),
  );

  test('the entry counts the new and the due cards of the whole subtree, '
      'disjoint and never capped, and the next due date after now '
      '(IT-STUDY-001, BR-STUDY-051, BR-STUDY-008)', () async {
    final root = await decks.root('Korean');
    final lessonA = await decks.sub(root.id, 'A');
    final lessonB = await decks.sub(root.id, 'B');
    await insertCard(db, id: 'n1', deckId: lessonA.id);
    await insertCard(db, id: 'n2', deckId: lessonB.id);
    await learned(lessonA.id, 'd1', DateTime(2026, 9, 20));
    await learned(lessonB.id, 'd2', DateTime(2026, 9, 24));
    await learned(lessonA.id, 'later', DateTime(2026, 9, 27));
    await learned(lessonB.id, 'soon', DateTime(2026, 9, 25));
    await lockScheduler(db, root.id);
    await limitCards(1);

    final ofRoot = await entryOf(root.id);
    final ofA = await entryOf(lessonA.id);

    expect((ofRoot.newCardCount, ofRoot.dueCardCount), (2, 2));
    expect(ofRoot.nextDueAt, DateTime(2026, 9, 25));
    expect(
      (ofRoot.schedulerType, ofRoot.cardLimit),
      (SchedulerType.eightBox, 1),
    );
    expect((ofA.newCardCount, ofA.dueCardCount), (1, 1));
    expect(ofA.nextDueAt, DateTime(2026, 9, 27));
  });

  test('each review mode counts the cards a review would take, the first '
      'card_limit due, and says why it cannot run (BR-STUDY-044, '
      'BR-MODE-009; IT-STUDY-004, IT-STUDY-007, IT-REVIEW-010)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await learned(leaf.id, 'a', DateTime(2026, 9, 20), example: 'ex a');
    await learned(leaf.id, 'b', DateTime(2026, 9, 21));
    await learned(leaf.id, 'c', DateTime(2026, 9, 22), example: 'ex c');
    await lockScheduler(db, root.id);
    await limitCards(2);

    final options = (await entryOf(leaf.id)).reviewModes;

    expect(
      [
        for (final option in options)
          (option.mode, option.cardCount, option.unavailableReason),
      ],
      [
        (StudyMode.match, 2, null),
        (StudyMode.guess, 0, ModeUnavailableReason.tooFewMeanings),
        (StudyMode.recall, 2, null),
        (StudyMode.fill, 1, null),
      ],
    );
    expect(options.any((option) => option.isDirectionRequired), isFalse);
  });

  test('an sm2 entry offers self_assess alone, with a direction to choose '
      '(IT-STUDY-005, BR-MODE-013)', () async {
    final root = await decks.root('Korean', SchedulerType.sm2);
    final leaf = await decks.sub(root.id, 'Lesson');
    await learned(leaf.id, 'a', DateTime(2026, 9, 20));
    await lockScheduler(db, root.id);

    final [option] = (await entryOf(leaf.id)).reviewModes;

    expect((option.mode, option.cardCount), (StudyMode.selfAssess, 1));
    expect(option.isDirectionRequired, isTrue);
  });

  test("Continue is offered for this deck's open session only while it is "
      "today's and at the root's generation (BR-STUDY-075, BR-STUDY-072; "
      'UC-STUDY-001 A3b)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id, back: 'one');
    await insertCard(db, id: 'c2', deckId: leaf.id, back: 'two');
    final opened = await entries.openLearningSession(deckId: leaf.id);
    final id = (opened as Ok<String, StudyRejection>).value;

    expect((await entryOf(leaf.id)).resumableSessionId, id);
    expect(
      (await entryOf(root.id)).resumableSessionId,
      isNull,
      reason: 'the session of another deck',
    );
    expect(
      (await entryOf(leaf.id, DateTime(2026, 9, 25, 8))).resumableSessionId,
      isNull,
      reason: 'a session of an earlier day',
    );

    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      root.id,
    ]);
    await db.customStatement('UPDATE card_schedule SET generation = 2');
    expect(
      (await entryOf(leaf.id)).resumableSessionId,
      isNull,
      reason: 'a session from before a reset',
    );
  });

  test('a session whose queue lost every row is not offered '
      '(BR-STUDY-075)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: leaf.id);
    await entries.openLearningSession(deckId: leaf.id);
    final schedules = ScheduleRepositoryImpl(db, now: () => now);
    final cards = CardRepositoryImpl(
      db,
      schedules,
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    );

    expect(
      await cards.deleteCards(cardIds: {'c1'}),
      isA<Ok<void, CardRejection>>(),
    );

    expect((await entryOf(leaf.id)).resumableSessionId, isNull);
  });

  test('the entry emits again when the options change and when a review '
      'moves cards out of due: the due cards left outside the session '
      '(IT-REVIEW-009, spec D11)', () async {
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    for (final (id, day) in [('a', 18), ('b', 19), ('c', 20), ('d', 21)]) {
      await learned(leaf.id, id, DateTime(2026, 9, day));
    }
    await lockScheduler(db, root.id);
    await limitCards(3);
    final limited = expectLater(
      entries.watchEntry(deckId: leaf.id, now: now),
      emitsThrough(
        isA<StudyEntry>().having((entry) => entry.cardLimit, 'limit', 2),
      ),
    );
    await limitCards(2);
    await limited;

    final opened = await entries.openReviewSession(
      deckId: leaf.id,
      mode: StudyMode.recall,
    );
    final id = (opened as Ok<String, StudyRejection>).value;
    for (var turn = 0; turn < 2; turn++) {
      await sessions.answerTurn(
        sessionId: id,
        cardId: (await servedCard(db, id))!,
        answer: const GradedAnswer(isCorrect: true),
      );
    }

    final entry = await entryOf(leaf.id);
    expect(entry.dueCardCount, 2);
    expect(entry.resumableSessionId, isNull);
  });

  test('a deck that is gone is null (UC-STUDY-001 E1)', () async {
    expect(await entries.watchEntry(deckId: 'missing', now: now).first, isNull);
  });
}
```

Create `test/features/study/domain/watch_study_entry_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/usecases/watch_study_entry_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-001 steps 1–2 and 4 through the use case the Study Entry watches.

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('a new local day makes a card due with no write (BR-STUDY-067, '
      'BR-STUDY-074)', () async {
    final decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    final root = await decks.root('Korean');
    final leaf = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'c1',
      deckId: leaf.id,
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 25),
      box: 2,
    );
    await lockScheduler(db, root.id);
    final clock = FakeDayClock(DateTime(2026, 9, 24, 22));
    final seen = <Outcome<StudyEntry, StudyRejection>>[];
    final subscription = WatchStudyEntryUseCase(
      studyEntryRepository(db, clock.now),
      clock,
    )(deckId: leaf.id).listen(seen.add);
    await pumpEventQueue();

    clock.startDay(DateTime(2026, 9, 25));
    await pumpEventQueue();
    await subscription.cancel();

    final [before, after] = [
      for (final outcome in seen)
        (outcome as Ok<StudyEntry, StudyRejection>).value.dueCardCount,
    ];
    expect((before, after), (0, 1));
  });

  test('a deck that is gone is notFound (UC-STUDY-001 E1)', () async {
    final clock = FakeDayClock(DateTime(2026, 9, 24, 9));

    final outcome = await WatchStudyEntryUseCase(
      studyEntryRepository(db, clock.now),
      clock,
    )(deckId: 'missing').first;

    expect(
      (outcome as Rejected<StudyEntry, StudyRejection>).reason,
      StudyRejection.notFound,
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/watch_entry_test.dart \
  test/features/study/domain/watch_study_entry_use_case_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither file compiles. The first errors: `Error: 'StudyEntry' isn't a type.`, `Error: The method 'watchEntry' isn't defined for the type 'StudyEntryRepositoryImpl'.`, `Error: Error when reading 'lib/features/study/domain/models/study_entry_model.dart': No such file or directory`

- [ ] **Step 3: Write the entry model and the review mode options**

Create `lib/features/study/domain/models/study_entry_model.dart`:

```dart
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/stage_eligibility_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The Study Entry of a deck (UC-STUDY-001 steps 1–2 and 4; spec §8.1). The
/// UI builds its actions and the stage chain from the domain (BR-STUDY-009).
final class StudyEntry {
  const StudyEntry({
    required this.schedulerType,
    required this.cardLimit,
    required this.newCardCount,
    required this.dueCardCount,
    required this.nextDueAt,
    required this.reviewModes,
    required this.resumableSessionId,
  });

  final SchedulerType schedulerType;

  /// The distinct cards a session takes (BR-STUDY-003).
  final int cardLimit;

  /// The new and the due cards of the deck and its subtree. The two sets are
  /// disjoint and never capped (BR-STUDY-051, IT-STUDY-001).
  final int newCardCount;
  final int dueCardCount;

  /// The earliest `due_at` after now, for the empty state (E1,
  /// BR-STUDY-008); null when no learned card waits.
  final DateTime? nextDueAt;

  /// One per review mode of [schedulerType] (BR-STUDY-055).
  final List<ReviewModeOption> reviewModes;

  /// This deck's open session, when Continue can take it up (BR-STUDY-075).
  final String? resumableSessionId;
}

/// A review mode as the Study Entry offers it (BR-STUDY-044, BR-MODE-009).
final class ReviewModeOption {
  const ReviewModeOption({
    required this.mode,
    required this.cardCount,
    required this.unavailableReason,
    required this.isDirectionRequired,
  });

  final StudyMode mode;

  /// The cards a review in [mode] would ask now.
  final int cardCount;

  /// Why [mode] cannot run on those cards; null when it can.
  final ModeUnavailableReason? unavailableReason;

  /// Whether opening it needs a direction (BR-MODE-013).
  final bool isDirectionRequired;
}

/// The review modes of [type] (BR-STUDY-055) on [dueCards], the cards a
/// review would take, through the same eligibility an opening runs (spec
/// §5.3), so the entry and the session cannot disagree (BR-STUDY-044).
List<ReviewModeOption> reviewModeOptions(
  SchedulerType type,
  List<StudyCardFacts> dueCards, {
  required int distinctMeaningCount,
}) => [
  for (final mode in reviewModesOf(type))
    switch (mode.handler.eligibility(
      dueCards,
      distinctMeaningCount: distinctMeaningCount,
    )) {
      StageRuns(:final cardIds) => ReviewModeOption(
        mode: mode,
        cardCount: cardIds.length,
        unavailableReason: null,
        isDirectionRequired: acceptsDirection(
          SessionKind.reviewing,
          type,
          mode,
        ),
      ),
      StageSkipped(:final reason) => ReviewModeOption(
        mode: mode,
        cardCount: 0,
        unavailableReason: reason,
        isDirectionRequired: acceptsDirection(
          SessionKind.reviewing,
          type,
          mode,
        ),
      ),
    },
];
```

- [ ] **Step 4: Read the entry: counts and the resumable session**

In `lib/features/study/data/datasources/study_session_dao.dart`:

Replace

```dart
typedef StudyCardRow = ({String cardId, bool hasExample});

```

with

```dart
typedef StudyCardRow = ({String cardId, bool hasExample});

/// The new and the due cards of a subtree, and the next due date.
typedef SubtreeCounts = ({int newCount, int dueCount, DateTime? nextDueAt});

/// The active decks of the subtree of the first variable, walked through
/// `parent_id` (schema.md "Duyệt cây").
const _subtree =
    'WITH RECURSIVE subtree(id) AS ('
    ' SELECT id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
    ' UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
    ' WHERE d.delete_batch_id IS NULL)';

```

Replace

```dart
  /// The active cards of [deckId]'s subtree matching [where], in [orderBy]
  /// order. The subtree is walked through `parent_id` (schema.md "Duyệt cây").
  Future<List<StudyCardRow>> _subtreeCards(
```

with

```dart
  /// The active cards of [deckId]'s subtree matching [where], in [orderBy]
  /// order.
  Future<List<StudyCardRow>> _subtreeCards(
```

Replace

```dart
        .customSelect(
          'WITH RECURSIVE subtree(id) AS ('
          ' SELECT id FROM deck WHERE id = ? AND delete_batch_id IS NULL'
          ' UNION SELECT d.id FROM deck d JOIN subtree s ON d.parent_id = s.id'
          ' WHERE d.delete_batch_id IS NULL)'
          ' SELECT c.id, c.example IS NOT NULL AS has_example FROM card c'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.deck_id IN (SELECT id FROM subtree)'
```

with

```dart
        .customSelect(
          '$_subtree SELECT c.id, c.example IS NOT NULL AS has_example'
          ' FROM card c JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.deck_id IN (SELECT id FROM subtree)'
```

Replace

```dart
          hasExample: row.read<bool>('has_example'),
        ),
    ];
  }

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
```

with

```dart
          hasExample: row.read<bool>('has_example'),
        ),
    ];
  }

  /// The new and the due cards of [deckId]'s subtree at [now], and the
  /// earliest `due_at` after [now] (BR-STUDY-051, BR-STUDY-008).
  Future<SubtreeCounts> subtreeCounts(String deckId, DateTime now) async {
    final row = await _db
        .customSelect(
          '$_subtree SELECT'
          ' COUNT(CASE WHEN cs.learned_at IS NULL THEN 1 END) AS new_count,'
          ' COUNT(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at <= ?'
          '  THEN 1 END) AS due_count,'
          ' MIN(CASE WHEN cs.learned_at IS NOT NULL AND cs.due_at > ?'
          '  THEN cs.due_at END) AS next_due_at'
          ' FROM card c JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.deck_id IN (SELECT id FROM subtree)'
          ' AND c.delete_batch_id IS NULL',
          variables: [
            Variable<String>(deckId),
            Variable<DateTime>(now),
            Variable<DateTime>(now),
          ],
          readsFrom: {_db.deck, _db.card, _db.cardSchedule},
        )
        .getSingle();
    return (
      newCount: row.read<int>('new_count'),
      dueCount: row.read<int>('due_count'),
      nextDueAt: row.read<DateTime?>('next_due_at'),
    );
  }

  /// The distinct meanings (`back_folded`) of [sessionCardIds] and of the
```

In `lib/features/study/data/datasources/study_view_dao.dart`:

Replace

```dart
              ),
      );

  Future<CardRow?> cardRow(String cardId) => (_db.select(
```

with

```dart
              ),
      );

  /// [deckId]'s row, unless it is gone or in the Trash. Emits again on every
  /// write the Study Entry can see: decks and their options, cards,
  /// schedules, sessions and queues.
  Stream<Deck?> watchDeckRow(String deckId) => _db
      .customSelect(
        'SELECT * FROM deck WHERE id = ? AND delete_batch_id IS NULL',
        variables: [Variable<String>(deckId)],
        readsFrom: {
          _db.deck,
          _db.card,
          _db.cardSchedule,
          _db.appSettings,
          _db.studySession,
          _db.studyQueueItems,
        },
      )
      .watchSingleOrNull()
      .map((row) => row == null ? null : _db.deck.map(row.data));

  /// The newest open session of [deckId] that Continue can take up
  /// (BR-STUDY-075): started on or after [startOfToday], at its root's
  /// generation, with at least one queue row.
  Future<String?> resumableSessionId(
    String deckId, {
    required DateTime startOfToday,
  }) async {
    final row = await _db
        .customSelect(
          'SELECT s.id FROM study_session s JOIN deck r ON r.id = s.root_id'
          " WHERE s.deck_id = ? AND s.status = 'in_progress'"
          ' AND s.started_at >= ? AND s.generation = r.generation'
          ' AND EXISTS (SELECT 1 FROM study_queue_items q'
          '  WHERE q.session_id = s.id)'
          ' ORDER BY s.started_at DESC LIMIT 1',
          variables: [
            Variable<String>(deckId),
            Variable<DateTime>(startOfToday),
          ],
          readsFrom: {_db.studySession, _db.deck, _db.studyQueueItems},
        )
        .getSingleOrNull();
    return row?.read<String>('id');
  }

  Future<CardRow?> cardRow(String cardId) => (_db.select(
```

- [ ] **Step 5: Watch the entry in the repository**

In `lib/features/study/data/repositories/study_entry_repository_impl.dart`:

Replace

```dart
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

with

```dart
import 'package:memox/features/study/data/datasources/study_session_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
```

Replace

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
```

with

```dart
import 'package:memox/features/study/domain/models/session_status_model.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';
```

Replace

```dart

/// Opens sessions on a deck (UC-STUDY-001 steps 3–5, UC-STUDY-003). Every
/// write is one transaction, which the settings reads it makes join: the
/// rules read the rows as they are at the moment of writing, and a
/// refusal writes nothing.
final class StudyEntryRepositoryImpl implements StudyEntryRepository {
```

with

```dart

/// What the Study Entry of a deck shows, and the sessions it opens
/// (UC-STUDY-001 steps 1–5, UC-STUDY-003). Every write is one transaction,
/// which the settings reads it makes join: the rules read the rows as they
/// are at the moment of writing, and a refusal writes nothing.
final class StudyEntryRepositoryImpl implements StudyEntryRepository {
```

Replace

```dart
       _queue = StudyQueueDao(_db),
       _now = now ?? DateTime.now,
```

with

```dart
       _queue = StudyQueueDao(_db),
       _views = StudyViewDao(_db),
       _now = now ?? DateTime.now,
```

Replace

```dart
  final StudyQueueDao _queue;
  final DateTime Function() _now;
```

with

```dart
  final StudyQueueDao _queue;
  final StudyViewDao _views;
  final DateTime Function() _now;
```

Replace

```dart

  /// The root of [deckId] and the options it studies with; null when the
```

with

```dart

  @override
  Stream<StudyEntry?> watchEntry({
    required String deckId,
    required DateTime now,
  }) => _views
      .watchDeckRow(deckId)
      .asyncMap((deck) async => deck == null ? null : _entryOf(deckId, now))
      .mapDatabaseErrors();

  /// The Study Entry of [deckId] as it stands (spec §8.1): the options come
  /// from the one-shot settings read, so a change of them emits again
  /// through [watchEntry].
  Future<StudyEntry?> _entryOf(String deckId, DateTime now) async {
    final scope = await _scope(deckId);
    if (scope == null) return null;
    final (root, options) = scope;
    final type = SchedulerType.fromCode(root.schedulerType!);
    final due = _factsOf(await _dao.dueCards(deckId, now))
        .take(options.cardLimit)
        .toList();
    final counts = await _dao.subtreeCounts(deckId, now);
    return StudyEntry(
      schedulerType: type,
      cardLimit: options.cardLimit,
      newCardCount: counts.newCount,
      dueCardCount: counts.dueCount,
      nextDueAt: counts.nextDueAt,
      reviewModes: reviewModeOptions(
        type,
        due,
        distinctMeaningCount: await _meaningsOf(root, due),
      ),
      resumableSessionId: await _views.resumableSessionId(
        deckId,
        startOfToday: startOfLocalDay(now),
      ),
    );
  }

  /// The root of [deckId] and the options it studies with; null when the
```

In `lib/features/study/domain/repositories/study_entry_repository.dart`:

Replace

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
```

with

```dart
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study_mode/domain/models/question_direction_model.dart';
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

  /// UC-STUDY-001 steps 1–2 and 4 (spec §8.1): the Study Entry of [deckId]
  /// at [now], again on every write it can see; null once the deck is gone
  /// or in the Trash. It writes nothing (BR-STUDY-075).
  Stream<StudyEntry?> watchEntry({
    required String deckId,
    required DateTime now,
  });
}
```

- [ ] **Step 6: Write the use case**

Create `lib/features/study/domain/usecases/watch_study_entry_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_entry_model.dart';
import 'package:memox/features/study/domain/repositories/study_entry_repository.dart';

/// UC-STUDY-001 steps 1–2 and 4: the Study Entry of a deck, again on every
/// change and at every local midnight, when cards fall due and "today"
/// moves with no write (BR-STUDY-067, BR-STUDY-072); notFound once the deck
/// is gone (E1). It writes nothing (BR-STUDY-075).
final class WatchStudyEntryUseCase {
  const WatchStudyEntryUseCase(this._entries, this._clock);

  final StudyEntryRepository _entries;
  final DayClock _clock;

  Stream<Outcome<StudyEntry, StudyRejection>> call({required String deckId}) =>
      watchEachLocalDay(
        _clock,
        (now) => _entries
            .watchEntry(deckId: deckId, now: now)
            .map<Outcome<StudyEntry, StudyRejection>>(
              (entry) => switch (entry) {
                final StudyEntry entry => Ok(entry),
                null => const Rejected(StudyRejection.notFound),
              },
            ),
      );
}
```

- [ ] **Step 7: Point the study docs at the code and record the package in the WBS**

In `docs/features/study-mode/README.md`:

Replace

```markdown
feature: study-mode
code: []
depends_on: [srs]
```

with

```markdown
feature: study-mode
code: [lib/features/study_mode/domain]
depends_on: [srs]
```

Replace

```markdown

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

## Màn hình → Use case
```

with

```markdown

## Màn hình → Use case
```

In `docs/features/study/README.md`:

Replace

```markdown
feature: study
code: []
depends_on: [card, deck, srs, study-mode]
```

with

```markdown
feature: study
code: [lib/features/study/domain, lib/features/study/data, lib/features/study/di]
depends_on: [card, deck, srs, study-mode]
```

Replace

```markdown
Vòng đời phiên học, hàng đợi, round, Study Home (V8.0): mở, giữ và đóng phiên `learning`/`reviewing`, hành vi từng mode chấm điểm, và tab Study.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

```

with

```markdown
Vòng đời phiên học, hàng đợi, round, Study Home (V8.0): mở, giữ và đóng phiên `learning`/`reviewing`, hành vi từng mode chấm điểm, và tab Study.

```

In `docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md`:

Replace

```markdown
rules: [BR-DECK-024, BR-MODE-002, BR-MODE-003, BR-MODE-006, BR-MODE-009, BR-SRS-003, BR-SRS-008, BR-SRS-009, BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-SRS-014, BR-SRS-015, BR-SRS-016, BR-SRS-017, BR-SRS-018, BR-SRS-019, BR-SRS-025, BR-SRS-026, BR-STUDY-002, BR-STUDY-003, BR-STUDY-004, BR-STUDY-005, BR-STUDY-006, BR-STUDY-007, BR-STUDY-008, BR-STUDY-009, BR-STUDY-010, BR-STUDY-012, BR-STUDY-013, BR-STUDY-014, BR-STUDY-015, BR-STUDY-017, BR-STUDY-018, BR-STUDY-019, BR-STUDY-020, BR-STUDY-021]
code: []
---
```

with

```markdown
rules: [BR-DECK-024, BR-MODE-002, BR-MODE-003, BR-MODE-006, BR-MODE-009, BR-SRS-003, BR-SRS-008, BR-SRS-009, BR-SRS-010, BR-SRS-011, BR-SRS-012, BR-SRS-014, BR-SRS-015, BR-SRS-016, BR-SRS-017, BR-SRS-018, BR-SRS-019, BR-SRS-025, BR-SRS-026, BR-STUDY-002, BR-STUDY-003, BR-STUDY-004, BR-STUDY-005, BR-STUDY-006, BR-STUDY-007, BR-STUDY-008, BR-STUDY-009, BR-STUDY-010, BR-STUDY-012, BR-STUDY-013, BR-STUDY-014, BR-STUDY-015, BR-STUDY-017, BR-STUDY-018, BR-STUDY-019, BR-STUDY-020, BR-STUDY-021]
code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/features/study/domain/usecases/open_learning_session_use_case.dart, lib/features/study/domain/usecases/open_review_session_use_case.dart, lib/features/study/domain/usecases/watch_study_session_use_case.dart, lib/features/study/domain/usecases/answer_study_turn_use_case.dart, lib/features/study/domain/usecases/abandon_study_session_use_case.dart, lib/features/study/domain/usecases/resume_study_session_use_case.dart, lib/features/study/domain/usecases/abandon_stale_sessions_use_case.dart]
---
```

In `docs/features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md`:

Replace

```markdown
rules: [BR-MODE-013, BR-MODE-014, BR-MODE-015, BR-MODE-016, BR-MODE-017, BR-MODE-018, BR-MODE-019, BR-STUDY-004, BR-STUDY-009, BR-STUDY-020, BR-STUDY-051, BR-STUDY-054, BR-STUDY-055, BR-STUDY-072]
code: []
---
```

with

```markdown
rules: [BR-MODE-013, BR-MODE-014, BR-MODE-015, BR-MODE-016, BR-MODE-017, BR-MODE-018, BR-MODE-019, BR-STUDY-004, BR-STUDY-009, BR-STUDY-020, BR-STUDY-051, BR-STUDY-054, BR-STUDY-055, BR-STUDY-072]
code: [lib/features/study/domain/usecases/watch_study_entry_use_case.dart, lib/features/study/domain/usecases/open_review_session_use_case.dart]
---
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-A2 | Reset learning progress, 2 use case (UC-SRS-001): reset giữ hoặc đổi scheduler, bản tóm tắt cho bước xác nhận (BR-SRS-020…BR-SRS-030, BR-STUDY-015) | xong | BE-02 | S | Spec và plan gói BE-A1 + BE-A2; test trong `test/features/srs/` | — |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

with

```markdown
| BE-A2 | Reset learning progress, 2 use case (UC-SRS-001): reset giữ hoặc đổi scheduler, bản tóm tắt cho bước xác nhận (BR-SRS-020…BR-SRS-030, BR-STUDY-015) | xong | BE-02 | S | Spec và plan gói BE-A1 + BE-A2; test trong `test/features/srs/` | — |
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, điều kiện dữ liệu của từng mode, câu trả lời và action, bước của dòng hàng đợi (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | xong | BE-02 | M | [spec](superpowers/specs/2026-09-24-study-session-backend-design.md) và [plan](superpowers/plans/2026-09-24-study-session-backend.md) gói 2a; test trong `test/features/study_mode/` | — |
| BE-A4 | Phiên học và hàng đợi, 8 use case (UC-STUDY-001): mở phiên `learning`/`reviewing` cho một cây deck, dựng round 1 của mọi stage; ghi lượt qua `recordTurn`, hoàn tất chuỗi học mới qua `completeLearning`; round, stage, thẻ quay lại và trần của `self_assess`; kết thúc, bỏ dở, tiếp tục, đóng phiên của ngày trước, `failed` khi lỗi ghi; read model của Study Entry và của màn phiên | xong | BE-A1, BE-A3 | XL | Spec và plan gói 2a; test trong `test/features/study/` và `test/features/srs/` | Cơ chế bốn mode chấm điểm ở BE-A10 |
| BE-A5 | Chọn chiều hỏi cho phiên self-assess của deck `sm2`, phần backend (UC-STUDY-003; BR-MODE-013…BR-MODE-019): phiên ôn `sm2` cần chiều hỏi, chiều của từng thẻ lưu trên dòng hàng đợi và chép sang `review_log` | xong | BE-A3, BE-A4 | S | Spec và plan gói 2a; test trong `test/features/study/` | — |
| BE-C3 | Lọc Trash trên luồng học: `SrsDao.rootOfCard`, dùng trong `recordTurn`, `completeLearning` và `initializeCard` | xong | — | S | Spec và plan gói 2a; test trong `test/features/srs/data/record_turn_test.dart` | — |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-A3 | Study-mode, domain thuần: sáu mode, chuỗi stage theo scheduler, một điểm dispatch, ngưỡng dữ liệu của từng mode (BR-MODE-001…BR-MODE-019; BR-STUDY-037, BR-STUDY-040, BR-STUDY-045) | chưa bắt đầu | BE-02 | M | [README study-mode](features/study-mode/README.md); guard đã có luật `single_study_mode_dispatch` | Đặc tả chung với BE-A4 |
| BE-A4 | Phiên học và hàng đợi (UC-STUDY-001): mở phiên `learning`/`reviewing` cho một cây deck; dựng `study_queue_items` theo `cursor` và `available_at`; ghi câu trả lời qua `recordReview`; round; kết thúc, bỏ dở, tiếp tục sau khi tắt app; phiên bị invalidated | chưa bắt đầu | BE-A1, BE-A3 | XL | Bảng `study_session` và `study_queue_items` đã có trong schema v1; `recordReview` đã có; UC chưa có code | Vertical slice đầu tiên theo `navigation.md`; làm luôn BE-C3 |
| BE-A5 | Chọn chiều hỏi cho phiên self-assess của deck `sm2` (UC-STUDY-003; BR-MODE-013…BR-MODE-019) | chưa bắt đầu | BE-A3, BE-A4 | S | UC chưa có code | Sau BE-A4 |
| BE-A6 | Study Home: read model cho tab Study (việc cần học trên toàn thư viện, phiên đang dở) (UC-STUDY-002) | chưa bắt đầu | BE-A4 | M | UC chưa có code | Sau BE-A4 |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-A10 | Cơ chế bốn mode chấm điểm (phần còn lại của UC-STUDY-001): so khớp, phiên bản chính sách và gợi ý của `fill`; đồng hồ, lật đáp án và hết giờ của `recall`; dựng câu hỏi `guess`, chỉ nhận lựa chọn đầu; bàn `match` và việc quy lượt (BR-STUDY-026…BR-STUDY-043, BR-STUDY-049, BR-STUDY-062, BR-STUDY-065, BR-STUDY-066, BR-STUDY-070) | chưa bắt đầu | BE-A4 | L | Gói 2a để các mode này nhận một kết luận đúng/sai (spec gói 2a §14) | Gói 2b, ngay sau gói 2a |
| BE-A6 | Study Home: read model cho tab Study (việc cần học trên toàn thư viện, phiên đang dở) (UC-STUDY-002) | chưa bắt đầu | BE-A4 | M | UC chưa có code | Sau BE-A4 |
```

Replace

```markdown
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
| BE-C3 | Lọc Trash trên luồng học: `SrsDao.rootOfCard`, dùng trong `recordReview` và `initializeCard` | chưa bắt đầu | — | S | Ruling ở final review của backend deck/card (PR #26) | Làm cùng BE-A4 hoặc BE-B1 |
| BE-C4 | Lọc card list theo tag (BR-TAG-004) | chưa bắt đầu | BE-B2 | S | Spec backend deck/card §8 | Làm trong BE-B2 |
```

with

```markdown
| BE-C2 | Batch trên 32.766 id, vượt giới hạn biến bind của SQLite | chưa bắt đầu | — | S | Clarification 16 của plan backend deck/card | Chia lô trong cùng transaction khi có nhu cầu thật |
| BE-C4 | Lọc card list theo tag (BR-TAG-004) | chưa bắt đầu | BE-B2 | S | Spec backend deck/card §8 | Làm trong BE-B2 |
```

Replace

```markdown
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2 | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở mọi UC | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
```

with

```markdown
| BE-D2 | CI chạy gate trên Linux: analyze, test, kiểm kiến trúc, unittest, guard, docs check | chưa bắt đầu | — | M | Workflow duy nhất là `build-apk.yml`, chạy tay; [spec UI base](superpowers/specs/2026-09-23-flutter-ui-base-design.md) §10 để Linux CI ngoài phạm vi | Phối hợp với FE-D1 vì goldens phải sinh lại trên Linux |
| BE-D3 | Sửa tài liệu đã lệch với code: [host-coverage-map.md](shared/testing/host-coverage-map.md) còn ghi "V8 chưa có test nào"; skill `flutter-workflow` còn trỏ tới `docs/wbs.md` của V7 | chưa bắt đầu | — | S | Khảo sát ngày 2026-09-24. `code:` của README srs và README settings đã sửa cùng BE-A1 và BE-A2; của README study và README study-mode cùng gói 2a | Sửa trong commit của hạng mục chạm tới phần đó (tài liệu và code cùng commit, [`docs/README.md`](README.md)) |
| BE-D4 | Acceptance criteria dạng Given/When/Then cho 22 UC; dùng chung với FE | bị chặn | — | M | [`open-questions.md`](_generated/open-questions.md) ghi thiếu ở mọi UC | Sửa UC `ready` là sửa hợp đồng: chủ dự án nêu phạm vi file được sửa, rồi viết theo từng nhóm hạng mục |
```

Replace

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 10/22 UC (UC-DECK-001…UC-DECK-006, UC-CARD-001,
  UC-CARD-002, UC-SETTINGS-001, UC-SRS-001). 12 UC còn lại chưa có code.

```

with

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A3, BE-A4, BE-A5 và BE-C3** (gói 2a,
  [spec](superpowers/specs/2026-09-24-study-session-backend-design.md),
  [plan](superpowers/plans/2026-09-24-study-session-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 12/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001, UC-STUDY-003).
  10 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói BE-A1 + BE-A2.

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 2a (BE-A3, BE-A4, BE-A5, BE-C3).

```

Replace

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 10 ID: IT-CONT-009, IT-DISC-001, IT-DISC-003, IT-DISC-005,
    IT-DISC-006, IT-ORG-001, IT-ORG-003, IT-ORG-005, IT-STUDY-008, IT-STUDY-013.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
```

with

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 52 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (3), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
  - Nhắc ID trong test chưa chứng minh kịch bản đã được phủ trọn.
```

Replace

```markdown

1. BE-A3 → BE-A4, đặc tả chung một spec "study", kèm BE-C3.
2. BE-A5 và BE-A6, rồi BE-A7.
3. BE-A8 chen vào bất kỳ lúc nào. BE-D1 phải xong trước migration đầu tiên; BE-D2 càng
   sớm càng tốt.
4. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration đầu tiên), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
```

with

```markdown

1. Gói 2b: BE-A10.
2. Gói 3: BE-A6. Rồi BE-A7, rồi BE-A8. BE-D1 phải xong trước migration đầu tiên; BE-D2
   càng sớm càng tốt.
3. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration đầu tiên), rồi BE-B2…BE-B5
   theo ưu tiên sản phẩm.
```

Replace

```markdown
  commit cuối của gói BE-A1 + BE-A2.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  commit cuối của gói BE-A1 + BE-A2.
- **Cập nhật ngày 2026-09-24:** BE-A3, BE-A4, BE-A5 và BE-C3 xong trong gói 2a; thêm
  BE-A10 cho cơ chế bốn mode chấm điểm (gói 2b).
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 8: Run the task's tests**

```bash
flutter test test/features/study/data/watch_entry_test.dart \
  test/features/study/domain/watch_study_entry_use_case_test.dart
```

Expected: `+9: All tests passed!`

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

Expected: `No issues found!`; `+1140: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  docs/features/study-mode/README.md \
  docs/features/study/README.md \
  docs/features/study/usecases/UC-STUDY-001-on-tap-mot-deck-luong-chinh.md \
  docs/features/study/usecases/UC-STUDY-003-chon-chieu-hoi-cho-phien-self-assess.md \
  docs/wbs_BE.md \
  lib/features/study/data/datasources/study_session_dao.dart \
  lib/features/study/data/datasources/study_view_dao.dart \
  lib/features/study/data/repositories/study_entry_repository_impl.dart \
  lib/features/study/domain/models/study_entry_model.dart \
  lib/features/study/domain/repositories/study_entry_repository.dart \
  lib/features/study/domain/usecases/watch_study_entry_use_case.dart \
  test/features/study/data/watch_entry_test.dart \
  test/features/study/domain/watch_study_entry_use_case_test.dart
git commit -F - <<'EOF'
feat(study): watch the Study Entry of a deck

The Study Entry counts the new and the due cards of the deck and its
subtree, never capped (BR-STUDY-051), gives the next due date for the empty
state (BR-STUDY-008), offers each review mode with the cards a review would
take and why it cannot run (BR-STUDY-044, BR-MODE-009), and offers Continue
only for this deck's session of today at its root's generation
(BR-STUDY-075). It follows the local day, so cards fall due at midnight with
no write. The study and study-mode code fields are filled, and wbs_BE.md
records package 2a as done and BE-A10 for package 2b.
EOF
```

Append the session's attribution trailers to the message when you commit.


## Plan self-review

- **Spec coverage.** §4: Tasks 1–9, with the file split of Clarifications 2–4.
  §5 (study modes): Task 2; §5.6 directions: Tasks 2 and 4. §6 (srs): Task 1,
  with Clarification 1. §7.1–§7.2 opening: Tasks 3 and 4. §7.3–§7.4 a turn,
  rounds, stages: Task 5. §7.5 endings: Tasks 6 (`failSession`) and 7. §8.1:
  Task 9; §8.2: Task 8; §8.3 the eight use cases: Tasks 3–9; §8.4 providers:
  Tasks 3 and 5, and `studyOptionsOf`: Task 3. §9 errors: Tasks 3, 5 and 6.
  §10 import map: Tasks 2 and 3. §11 docs: `schema.md` (Tasks 3, 5), `data.md`
  (Task 7), `code:` fields, READMEs and WBS (Task 9), `_generated` (every task).
  §12: every test the spec lists, in Tasks 1–9.
- **Scenarios named by the spec (§12).** IT-STUDY-001…IT-STUDY-013 of the entry
  and the opening, IT-LEARN-001…IT-LEARN-010, IT-REVIEW-001…IT-REVIEW-010 but
  IT-REVIEW-007's UI half, IT-CONT-001…IT-CONT-014 of the host, IT-MODE-001,
  IT-MODE-006 and IT-MODE-015: each is named by a test.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the
  replay compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in the owning task.
