# MemoX V8 — Study session backend design (package 2a)

Status: decisions approved in chat 2026-09-24 · spec awaiting review · Path: architectural

## 1. Intent

Build package 2a of [`docs/wbs_BE.md`](../../wbs_BE.md):

- BE-A3, the study modes as a pure domain;
- BE-A4, the study session and its queue (UC-STUDY-001);
- BE-C3, the Trash filter on the study flow;
- the backend half of BE-A5, the question direction (UC-STUDY-003).

The four graded modes (`match`, `guess`, `recall`, `fill`) take a correct or
incorrect verdict here; package 2b builds their mechanics. The package writes
`domain/`, `data/` and `di/` only; a parallel session builds the screens (FE-A6
and FE-A7 in [`docs/wbs_FE.md`](../../wbs_FE.md)).

Success means:

- every interaction of UC-STUDY-001 and UC-STUDY-003 is reachable through one use
  case (AD-12, ADR-011 D4);
- every rule those use cases cite that the backend owns is enforced in the domain
  or inside the writing transaction, and a test fails when the rule is broken;
- the `HOST-FLOW` half of the study scenarios listed in §12 is covered by tests
  that name their scenario id;
- the schema invariants of `schema.md` hold after every study test;
- the phased gate of the root `README.md` passes after every task;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-24)

- `master` is at `86f2e0d`: package 1 (#30), then the Library card list (#31).
- `study_session` and `study_queue_items` exist in schema v1 with the CHECKs of
  invariants 12, 13, 17, 21 and 31. No code reads or writes them, except that
  `resetLearning` and `changeScheduler` invalidate the open sessions of a tree.
- `ScheduleRepository.recordReview` exists, but nothing calls it. The foundation
  plan's Clarification 15 records four ways in which it and the two schedulers
  differ from the rules, and hands their repair to the study sub-project:
  1. a new card moves on its first `remembered`/`good` and gets `learned_at` without
     `due_at`, where BR-STUDY-053 makes finishing learning an event that starts the
     schedule at the lowest level, due the next local day;
  2. a `forgotten` scheduled review keeps its box, where BR-SRS-008 sends it to box 1;
  3. `sm2`'s `again` is `q = 2`, where BR-SRS-010 says `q = 0`;
  4. the scheduler derives `kind` from the card's state, where BR-SRS-015 and
     BR-SRS-017 let the session say which turn is `relearning`.
- `SrsDao.rootOfCard` does not filter the Trash (BE-C3, ruled in the final review of
  the deck and card backend, PR #26).
- `SettingsRepository` has a stream of the effective study options but no one-shot
  read; package 1 (spec §11) left that read to BE-A4.
- `CardRepository.setFlagged` exists (BR-CARD-011).
- The guard rule `memox.architecture.single_study_mode_dispatch` already waits for
  one exhaustive switch on `StudyMode` in a `*_mode.dart` file.
- `test/support/invariant_queries.dart` parses invariants 1–32 from `schema.md`.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | Package 2a: BE-A3, BE-A4, BE-C3 and the backend of BE-A5. Package 2b: the mechanics of the four graded modes. Package 3 keeps BE-A6 | Owner, 2026-09-24 |
| D2 | One open session | The whole app has at most one `in_progress` session. Opening a session, on any deck, first closes the open one: `abandoned`/`user_exit` when it started on the current local day, `abandoned`/`interrupted` when it started on an earlier one. The Resume path shows at that deck's entry (this package) and on Study Home (BE-A6) | Owner, 2026-09-24; BR-STUDY-072 |
| D3 | Ownership | `study_mode` is a pure domain feature with one dispatch point. `srs` replaces `recordReview` with `recordTurn` and `completeLearning` and filters the Trash. `study` owns sessions, queues, reads and use cases. Dart import map: `study_mode → {srs}`, `study → {study_mode, srs, settings, card}` | Owner, 2026-09-24 (approach A of three) |
| D4 | Where the stage sequence lives | `stageSequenceOf` and `reviewModesOf` are exhaustive switches on `SchedulerType` in `study_mode`. BR-MODE-007's rationale suggests placing `stageSequence` on `SrsScheduler`; that needs `srs → study_mode`, and ADR-011 makes `srs` the base. The rule itself holds: the sequence is declared per algorithm, never in the UI | Design, approved |
| D5 | The `guess` threshold | The stage runs when its distractor source holds at least five distinct `back_folded`. The source is the session's cards plus the learned, active cards of the root's tree (BR-STUDY-038). BR-STUDY-040 says "tập thẻ của phiên", but IT-MODE-015 needs a review of one due card to run `guess` from four learned cards that are not due. The spec reads BR-STUDY-040's "tập" as that source; no BR changes | Design, approved |
| D6 | `sm2` start after learning | Interval 1 and `repetitions` 1, so the first `good` of a review gives 6 days (BR-SRS-011). Ease stays at its start value | Design, approved |
| D7 | Queue building | The first round of every stage is built when the session opens. A card that fails a stage's data condition has no row in that stage; this is "skipped with a record" (BR-STUDY-071). A wrong answer enrolls the card in the next round at once (BR-STUDY-062). The next round is built, meaning shuffled and positioned, when the current round ends; from then on its positions do not change (`schema.md`) | Design, approved |
| D8 | Turn kind | A card's first turn in a stage (`round = 1` and `answers_in_session = 0`) is `learning` in a learning session and `scheduled` in a review session. Every later turn is `relearning` (BR-STUDY-023). This refines the `schema.md` note on `answers_in_session` for rounds | Design, approved |
| D9 | Write errors | A `DatabaseLockedFailure` is E2: nothing is written, and the person retries. Every other `Failure` is E3: the use case closes the session as `failed`/`persistence_error` in its own transaction, then reports the error | Design, approved |
| D10 | Direction in 2a | The backend of UC-STUDY-003 is part of this package: opening an `sm2` review session needs a direction (BR-MODE-018) | Owner, 2026-09-24 |
| D11 | Summary | A session's summary holds its card count, the cards that finished learning (learning session) and the count of wrong turns (IT-CONT-005). The counts left outside the session come from `WatchStudyEntry` (IT-REVIEW-009, IT-LEARN-011) | Owner, 2026-09-24; wrong turns from IT-CONT-005 |
| D12 | A session with nothing left | If the rows of a session vanish because their cards were deleted (V8.0 deletes for good), settling the session moves on, and a session with no pending row left is `completed`. `content_deleted` stays with the Trash sub-project (`schema.md`) | Design |
| D13 | Scheduler version | Both schedulers keep `version` 1: the old branches never ran on user data, because nothing called `recordReview` | Design |
| D14 | Branch and PR | Branch `claude/be-study-session` from `master`. When the gate is green and the final review is clean, the package is opened as a PR and merged | Owner, 2026-09-24 |

## 4. Structure

```
lib/features/study_mode/                        new feature, domain only
└── domain/
    ├── models/
    │   ├── study_mode.dart                     StudyMode, StudyModeHandler, the one
    │   │                                       dispatch, stageSequenceOf, reviewModesOf
    │   ├── browse_mode.dart                    BrowseModeHandler
    │   ├── self_assess_mode.dart               SelfAssessModeHandler
    │   ├── graded_mode.dart                    GradedModeHandler (recall uses it as is)
    │   ├── match_mode.dart, guess_mode.dart,
    │   │   fill_mode.dart                      the graded modes with a data condition
    │   ├── session_kind_model.dart             SessionKind
    │   ├── study_answer_model.dart             StudyAnswer
    │   ├── stage_eligibility_model.dart        StudyCardFacts, StageEligibility,
    │   │                                       ModeUnavailableReason
    │   ├── row_step_model.dart                 RowStep
    │   └── question_direction_model.dart       DirectionChoice, QuestionDirection,
    │                                           acceptsDirection, assignDirections
    └── failures/study_mode_failure.dart        StudyModeRejection

lib/features/srs/
├── domain/models/{srs_scheduler, eight_box_scheduler, sm2_scheduler}.dart   §6.1
├── domain/models/review_turn_model.dart        new: ReviewTurn
├── domain/failures/srs_failure.dart            notLearned, alreadyLearned
├── domain/repositories/schedule_repository.dart  recordTurn, completeLearning;
│                                               recordReview removed
└── data/                                       DAO and implementation follow

lib/features/settings/                          one-shot read of the options (§8.4)

lib/features/study/                             new feature
├── domain/
│   ├── entities/study_session_entity.dart      StudySessionEntity, SessionStatus,
│   │                                           SessionEndReason
│   ├── models/                                 queue building, progression, entry
│   │                                           and session read models
│   ├── failures/study_failure.dart             StudyRejection
│   ├── repositories/study_session_repository.dart
│   └── usecases/                               eight use cases (§8.3)
├── data/
│   ├── datasources/                            session, queue and read DAOs
│   ├── mappers/
│   └── repositories/study_session_repository_impl.dart
└── di/study_session_repository_provider.dart

test/architecture/boundary_rules.dart           'study_mode': {'srs'},
                                                'study': {'study_mode', 'srs',
                                                          'settings', 'card'}
test/support/study_fixtures.dart                new
```

The exact file split may move while the plan is written, and the 500-line guard
will split the larger files; the responsibilities do not move.

## 5. Study modes (BE-A3)

Pure Dart in `lib/features/study_mode/domain/`, importing `srs` only. Nothing here
reads the database: `study` hands in the facts, receives decisions and writes
them.

### 5.1 `StudyMode` and the one dispatch

- **`StudyMode`** `{browse, selfAssess, match, guess, recall, fill}` carries the
  stored code (`browse`, `self_assess`, …) and a `fromCode` lookup, as
  `SchedulerType` does (BR-MODE-002, BR-MODE-008).
- **`StudyModeHandler`** is the one place a mode's policy lives. `study_mode.dart`
  holds the enum, the abstract handler and the only switch on `StudyMode`
  (`handler`), exhaustive and without `default`. No other file in `domain/` or
  `data/` branches on a mode; each question is a handler member.
- The handlers are `const` singletons. The four graded modes share
  `GradedModeHandler`. `match`, `guess` and `fill` extend it with their data
  condition; `recall` has none in this package and uses the base class as is.
- **`SessionKind`** `{learning, reviewing}`, stored by name (BR-STUDY-051).

### 5.2 Modes per algorithm

- **`stageSequenceOf(SchedulerType)`:** `eight_box` → `browse`, `match`, `guess`,
  `recall`, `fill`; `sm2` → `browse`, `self_assess` (BR-MODE-004, BR-MODE-007, D4).
- **`reviewModesOf(SchedulerType)`:** the stages of the sequence whose handler
  produces an action, so never `browse` (BR-STUDY-055).

### 5.3 Data conditions

**`StudyCardFacts`** holds what the conditions read: the card id, whether it has an
`example`, and its `back_folded`. A handler answers
`eligibility(cards, distinctMeaningCount)` with **`StageEligibility`**:

- `StageRuns(cardIds)`: the cards that get rows;
- `StageSkipped(reason)`, where `ModeUnavailableReason` is one of `noExample`,
  `tooFewPairs` or `tooFewMeanings`.

| Mode | Cards with rows | The stage runs when |
|---|---|---|
| `browse`, `self_assess`, `recall` | every card | at least one card |
| `fill` | cards with an `example` (BR-STUDY-044, IT-LEARN-005) | at least one such card |
| `match` | every card | at least two cards (BR-STUDY-045) |
| `guess` | every card | at least five distinct meanings in the distractor source (D5) |

`distinctMeaningCount` counts distinct `back_folded` over the session's cards and
the learned, active cards of the root's tree; the DAO stops counting at five. A
learning session skips a stage that does not run (BR-MODE-009). The review entry
uses the same function to count each mode's cards and to disable a mode with its
reason (BR-STUDY-044, BR-MODE-009). Opening a review session refuses a mode that
does not run.

### 5.4 Answers and actions

**`StudyAnswer`** is sealed. Package 2b adds the graded modes' real inputs (typed
text, a chosen option, a pair, a timeout) behind the same handler member.

| Answer | Accepted by | Action |
|---|---|---|
| `AdvanceAnswer` | `browse` | none: no action, no `review_log` (BR-MODE-005) |
| `SelfAssessAnswer(action)` | `self_assess` | the action the person pressed, which must be in the scheduler's `supportedActions` (BR-MODE-011, BR-STUDY-009) |
| `GradedAnswer(isCorrect)` | the four graded modes | `eight_box`: wrong → `forgotten`, right → `remembered` (BR-MODE-012) |

`actionOf(answer, scheduler)` returns `Outcome<Object?, StudyModeRejection>`.
`StudyModeRejection` is `{answerDoesNotFitMode, unsupportedAction}`.

`SrsScheduler.isLapse(action)` is true for `forgotten` and `again`. Handlers and
`srs` use it to tell a lapse from a pass (BR-STUDY-005, BR-STUDY-007, BR-SRS-018).

### 5.5 What a turn does to its row

`stepAfter(action, answersInSession)` returns **`RowStep`**, which `study` applies
in the turn's transaction:

| Handler | Pass | Lapse |
|---|---|---|
| `browse` (advance) | `Leave`: the row is completed (BR-STUDY-007) | — |
| `self_assess` | `Leave` | `ComeBack`: the same row stays pending and is served again once three other turns have passed, or at the end when fewer remain (BR-STUDY-005; §7.3 step 5). On the fourth turn of the row (one first turn and three `relearning`) the step is `LeaveAtCap` instead: the row is completed and the card is flagged (BR-STUDY-073, BR-CARD-009) |
| `match` | `Leave` | `StayAndEnroll`: the row stays pending on the board, and the card joins the next round once (BR-STUDY-062) |
| `guess`, `recall`, `fill` | `Leave` | `LeaveAndEnroll`: the row is completed, and the card joins the next round once (BR-STUDY-059, BR-STUDY-060) |

Four handler properties go with this:

- `producesAction`: false only for `browse` (BR-MODE-005, BR-MODE-011).
- `usesRounds`: false for `browse` and `self_assess`, which have no rounds
  (BR-STUDY-005, BR-STUDY-059).
- `servesInOrder`: false only for `match`. A `match` turn may name any pending row
  of the current round, because the board shows several at once.
- `takesDirection`: true only for `self_assess`, the one mode where a direction
  changes which side is the prompt and not what is graded (BR-MODE-013).

### 5.6 Question direction (BE-A5 backend)

- **`DirectionChoice`** `{koreanToMeaning, meaningToKorean, mixed}` and
  **`QuestionDirection`** `{koreanToMeaning, meaningToKorean}` carry their stored
  codes (BR-MODE-014, BR-MODE-015).
- **`acceptsDirection(kind, schedulerType, mode)`** is the one predicate of
  BR-MODE-013: `reviewing` × `sm2` × a mode whose handler `takesDirection`, which
  only `self_assess` does.
- **`assignDirections(count, choice, random)`** returns one direction per card:
  - a fixed choice gives every card that direction;
  - `mixed` gives each direction ⌊count/2⌋ cards; for an odd count, `random`
    chooses which direction takes the extra card;
  - the assignment is shuffled across the cards (BR-MODE-015).

## 6. `srs` changes

### 6.1 Schedulers (Clarification 15)

- **`next(state, action, now)`** is the `scheduled` turn only, the one turn that
  changes the schedule (BR-SRS-016). It requires a learned state.
  - `eight_box`: `forgotten` → box 1; `remembered` → `min(8, box + 1)`. The due
    date is 00:00 local time, the interval of the target box ahead (BR-SRS-008,
    BR-SRS-009, BR-STUDY-074).
  - `sm2`: `q` is 0, 3, 4 and 5 for `again`, `hard`, `good` and `easy`
    (BR-SRS-010). The ease is updated first, with a floor of 1.3 (BR-SRS-012).
    For `q < 3`, `repetitions` goes to 0 and the interval to 1. Otherwise the
    interval is 1 when `repetitions` is 0, 6 when it is 1, and
    `round(interval × new ease)` after that; then `repetitions` goes up by 1
    (BR-SRS-011). The due date follows BR-STUDY-074.
  - Counters: `answer_count` + 1. `lapse_count` + 1 when `isLapse(action)`
    (BR-SRS-018).
  - `last_answered_at` becomes `now`.
- **`learned(state, now)`** is the schedule a card starts when it finishes learning
  (BR-STUDY-053). `learned_at` becomes `now`, and `due_at` becomes the next local
  midnight.
  - `eight_box`: box 1.
  - `sm2`: interval 1, `repetitions` 1, ease unchanged (D6).
- The `_learning` and `_relearning` branches are removed. Learning and relearning
  turns do not reach the scheduler.
- `version` stays 1 (D13).

### 6.2 `recordTurn`

`recordTurn(ReviewTurn turn)` returns `Outcome<void, SrsRejection>`. A
**`ReviewTurn`** holds:

- `cardId`, `sessionId`, `generation`, `kind` and `action`;
- `modeCode` and `directionCode` (nullable). They are the codes of `StudyMode` and
  `QuestionDirection`, passed as text because `srs` is the base and does not import
  `study_mode` (ADR-011);
- `answeredAt`.

In one transaction, which joins the caller's:

1. **Guards.** The card must be active, and so must its deck (BE-C3, §6.4);
   otherwise `notFound`. The turn's `generation` must equal the root's and the
   schedule row's; otherwise `staleGeneration` (BR-SRS-026). The action must be in
   the root scheduler's `supportedActions`; otherwise `unsupportedAction`.
2. **`scheduled`.** The card must be learned; otherwise `notLearned`
   (BR-STUDY-058, invariant 25). `next()` runs, the schedule row takes the new
   state, and `review_log` gets the before and after values (BR-SRS-019).
3. **`learning` and `relearning`.** Only `last_answered_at` changes (BR-SRS-017,
   BR-SRS-018, BR-STUDY-053). `review_log` gets before = after, which is
   invariant 14, and `next_due_at` = the current `due_at`.
4. **Every row** carries `mode`, `direction`, `scheduler_type`, `generation`, `kind`
   and `action` as given (BR-SRS-015, BR-MODE-016). The graded-mode columns
   (`outcome_reason`, `comparison_version`, `used_hint`) stay NULL until package 2b.

`srs` no longer reads `study_session` for a turn: `study` passes the mode, the
generation and the direction. `srs` still closes open sessions on reset and on a
scheduler change, as before.

### 6.3 `completeLearning`

`completeLearning({cardId, generation, now})` returns `Outcome<void, SrsRejection>`
and joins the caller's transaction.

- Guards: the card active (§6.4) and the generation equal (as in §6.2). A card
  already learned is refused with `alreadyLearned`.
- The schedule row takes `learned(state, now)`. No `review_log` row is written
  (BR-STUDY-053).
- If the root's `first_answered_at` is NULL, it becomes `now` in the same
  transaction; this locks the scheduler (BR-SRS-003). A later completion does not
  overwrite it.

### 6.4 The Trash filter (BE-C3)

`SrsDao.rootOfCard` returns nothing for a card whose own row or whose deck carries
a `delete_batch_id`. `recordTurn` and `completeLearning` answer `notFound`.
`initializeCard` keeps its behavior, since a card just created is active. V8.0
deletes for good, so the filter guards the Trash sub-project's future rows.

### 6.5 `SrsRejection`

Two values are added:

- `notLearned`: a `scheduled` turn on a card that is not learned;
- `alreadyLearned`: `completeLearning` on a learned card.

`study` never causes either one when it is correct (§7.3).

## 7. Sessions and queues (BE-A4)

### 7.1 Opening a session

Only an explicit Study action opens a session (BR-STUDY-020). Each opening is one
transaction:

1. **Read.** The deck, which must be active (`notFound` otherwise). Its root, for
   the scheduler and the generation. The effective study options, through the
   one-shot read (§8.4).
2. **Choose the cards** of the deck and its whole subtree (IT-STUDY-011), all
   active. At most `card_limit` distinct cards (BR-STUDY-003, invariant 18):
   - **Learning:** `learned_at IS NULL`. With `created`, the order is
     `created_at, id`. With `random`, the order is a sample drawn with the injected
     `Random` (BR-STUDY-057). The order only chooses the set; every stage shuffles
     again (IT-STUDY-012). No card: `nothingToLearn`.
   - **Reviewing:** `learned_at` set and `due_at <= now`, ordered by
     `due_at, created_at, id` (BR-STUDY-001, BR-STUDY-002). No card: `nothingDue`
     (BR-STUDY-054). Before any write, the mode must be in `reviewModesOf`
     (`modeNotOffered`), the stage must run (`modeUnavailable`), and the direction
     must match BR-MODE-013. A missing direction where one is needed is refused as
     `directionRequired`, a validation error. A direction where none is accepted is
     refused as `directionNotAllowed`, a conflict (BR-MODE-018).
3. **Close the open session** of the app, whatever its deck (D2). Every refusal
   comes before this step, so a refused opening writes nothing and leaves the open
   session as it was.
4. **Write the session:** `in_progress`, the kind, the root and its generation,
   `cursor = 0`, `card_limit` from the options (BR-STUDY-024), `direction` (the
   choice's code, or NULL), `started_at = now`, and `current_mode` set to the first
   stage that has rows.
5. **Write round 1 of every stage** (§7.2) (BR-STUDY-021, BR-STUDY-022).

It returns the new session's id.

### 7.2 Building the queue

- **Learning:** for each stage of `stageSequenceOf`, the handler's eligibility
  decides its cards (§5.3). A stage that does not run has no row. A stage that runs
  gets its cards shuffled with the injected `Random`. If two or more of its cards
  are shared with the previous stage that has rows, and their order is that
  stage's order, the first two shared cards swap. A stage then never reuses the
  previous sequence (BR-STUDY-022, IT-LEARN-004).
- **Reviewing:** one stage, round 1 in the chosen order (`due_at` ascending,
  IT-REVIEW-004). For `self_assess`, each row takes its direction from
  `assignDirections` (BR-MODE-015, BR-MODE-016).
- **Every row starts** `pending`, with `round = 1`, positions `0…n-1`,
  `available_at = 0` and `answers_in_session = 0`. `remaining_ms` is NULL, since
  the timer belongs to package 2b.

### 7.3 A turn

`answerTurn({sessionId, cardId, answer, now})` is one transaction:

1. **The session.** It must exist (`notFound`) and be `in_progress`
   (`sessionClosed`). If the root's generation differs from the session's, the
   session becomes `invalidated`/`stale_generation`, `ended_at = now`, and the
   answer is refused as `staleGeneration`; no turn is written (BR-STUDY-017,
   IT-CONT-010).
2. **The row.** `cardId` must have a pending row in the current mode and the
   current round (§7.4). When the handler `servesInOrder`, it must also be the
   head row: the first pending row with `available_at <= cursor` by `position`, or,
   when there is none, the one with the smallest `available_at` (BR-STUDY-005).
   Otherwise `notCurrentCard`, so a second tap cannot answer twice (BR-STUDY-042).
3. **The action.** `handler.actionOf` gives the action, or `answerDoesNotFitMode` /
   `unsupportedAction`.
4. **The turn**, when there is an action. The kind follows D8, and `srs.recordTurn`
   receives the row's direction and the session's mode and generation. `notFound`,
   `staleGeneration` and `unsupportedAction` from `srs` come back as the same
   `StudyRejection`, with nothing written. Any other rejection means `study` and
   `srs` disagree; that is a bug, so it throws a `StateError`. The transaction rolls
   back, and the error reaches the use case as a `Failure` (E3).
5. **The row step** (§5.5):
   - `answers_in_session` + 1 when there was a turn;
   - `ComeBack` sets `available_at = cursor + 1 + 3`, the cursor after this turn
     plus three;
   - `LeaveAtCap` also calls `CardRepository.setFlagged({cardId}, true)`;
   - `StayAndEnroll` and `LeaveAndEnroll` insert the card's row in round
     `round + 1` if it is not there yet (the primary key dedupes, BR-STUDY-060).
     That row gets the next free provisional position.
6. **The cursor:** `cursor` + 1, once per answered turn and per `browse` advance
   (BR-STUDY-048).
7. **Progression** (§7.4).
8. **Learning complete.** In a learning session, when the step was not
   `LeaveAtCap` and the card has no pending row left in any stage, the card
   finished the last stage it takes part in: `srs.completeLearning` runs
   (BR-STUDY-053, BR-SRS-003, IT-LEARN-005, IT-LEARN-010). A card at the cap stays
   new and flagged (UC-STUDY-001 A2b, IT-LEARN-009).

### 7.4 Rounds and stages

- The **current round** of the current mode is the lowest round that has a pending
  row. The **head row** is defined in §7.3 step 2.
- **The current round has no pending row left:**
  - **A next round exists.** It is built now: its rows are shuffled with the
    injected `Random` and get positions `0…n-1`. When it has two or more cards and
    that order equals the previous round's order of the same cards, the first two
    swap (BR-STUDY-061). Its positions do not change after this (D7).
  - **No next round.** The stage is complete (BR-STUDY-069). A learning session
    moves `current_mode` to the next stage in `stageSequenceOf` that has pending
    rows (UC-STUDY-001 A0).
  - **No stage is left,** or the session is a review. The session is `completed`
    with `ended_at = now` (BR-STUDY-013). Invariant 16 holds by construction.
- The same routine runs after a turn and when a session is settled (§7.5).

### 7.5 Other endings

- **`abandonSession({sessionId, now})`:** `in_progress` → `abandoned`/`user_exit`
  (BR-STUDY-014). Another status is refused as `sessionClosed`. The recorded turns
  stay (BR-STUDY-019).
- **`abandonStaleSessions({now})`:** every `in_progress` session that started
  before today's local midnight → `abandoned`/`interrupted` (BR-STUDY-072). The UI
  calls it when the app starts. It never runs from a read (BR-STUDY-075).
- **`resumeSession({sessionId, now})`**, for the Continue action and for a stalled
  session view (§8.2):
  - A session that is not `in_progress` is refused as `sessionClosed`.
  - A session from an earlier local day → `abandoned`/`interrupted`, refused as
    `sessionExpired`.
  - A stale generation → `invalidated`/`stale_generation`, refused as
    `staleGeneration`.
  - Otherwise the session is **settled**: if the current round has no pending row,
    because its cards were deleted, the progression of §7.4 runs (D12).
- **`failSession({sessionId, now})`:** `in_progress` → `failed`/`persistence_error`
  (BR-STUDY-018). Otherwise it does nothing. Only the E3 path of
  `AnswerStudyTurnUseCase` calls it (D9).
- **Deleting the session's deck** removes the session and its queue by cascade.
  The session's watch then reports `notFound` (UC-STUDY-001 A5, IT-CONT-007).
- Reset and a scheduler change keep invalidating open sessions, as they do today
  (BR-STUDY-015, BR-STUDY-016).

## 8. Reads and use cases

Every watch returns a stream of `Outcome` and maps a missing row to `notFound`, as
the other features do. Database errors leave through `mapDatabaseErrors()`.

### 8.1 `WatchStudyEntry(deckId)` — the Study Entry of a deck

**`StudyEntry`** holds:

- `newCardCount` and `dueCardCount` over the active cards of the subtree. The two
  sets are disjoint and never capped (BR-STUDY-051, IT-STUDY-001).
- `nextDueAt`: the earliest `due_at` after now, for the empty state (E1,
  BR-STUDY-008).
- `schedulerType` and `cardLimit`. The UI builds the action buttons and the stage
  chain from the domain (BR-STUDY-009).
- `reviewModes`: for each mode of `reviewModesOf`, a `ReviewModeOption` with the
  mode, its card count, its `ModeUnavailableReason` (or none) and whether it needs a
  direction (`acceptsDirection`).
  - The counts use the set an opening would take: the first `card_limit` due cards
    (BR-STUDY-044, IT-STUDY-007, IT-REVIEW-010).
  - They go through the same function as §5.3, so the entry and the session cannot
    disagree.
- `resumableSessionId`: the open session of this deck, only when it meets all four
  conditions of BR-STUDY-075:
  - it is `in_progress`;
  - it started on the current local day;
  - its generation matches the root's;
  - its queue has at least one row.

The use case wraps the repository in `watchEachLocalDay` with the `DayClock`, as
`WatchDeckLevel` does, so "due" and "today" move at midnight without a write. The
repository combines the settings stream with its own statement through a small
private `switchMap`. There is no rxdart dependency.

### 8.2 `WatchStudySession(sessionId)` — the session screen

**`StudySessionView`** holds:

- **The session:** id, deck id and name, kind, status and `endReason`, current
  mode, current round, the direction choice, and the stages of the session that
  have rows, with the index of the current one (IT-MODE-001).
- **Progress:** completed and total rows of the current round (BR-STUDY-049).
- **`currentItem`**, the head row:
  - the card's `front`, `back`, `example`, `hint` and `pronunciation`;
  - the row's round, `answersInSession`, direction, `remainingMs` and
    `isRevealed`.
  - It is null when the session has ended or is stalled.
- **`isStalled`**: the session is `in_progress` but its current round has no
  pending row, because its cards were deleted. The UI then calls
  `ResumeStudySession`.
- **`summary`**, once the session has ended (D11):
  - `cardCount`: the distinct cards of the queue;
  - `learnedCardCount`, in a learning session: the session's cards that are now
    learned;
  - `wrongTurnCount`: the `review_log` rows of the session whose action is a
    lapse.

Package 2b extends this view with the `match` board, the `guess` options and the
`recall` timer.

### 8.3 Use cases — the contract for the UI

| Use case | Returns | Source |
|---|---|---|
| `OpenLearningSession(deckId)` | `Outcome<String, StudyRejection>` (session id) | UC-STUDY-001 steps 3, 5; BR-STUDY-020, BR-STUDY-024, BR-STUDY-072 |
| `OpenReviewSession(deckId, mode, direction?)` | `Outcome<String, StudyRejection>` | UC-STUDY-001 step 4; UC-STUDY-003 steps 4–5, E1–E3; BR-STUDY-054, BR-STUDY-055, BR-MODE-018 |
| `AnswerStudyTurn(sessionId, cardId, answer)` | `Outcome<void, StudyRejection>` | UC-STUDY-001 steps 6–13, A1–A2b, E2–E4 |
| `AbandonStudySession(sessionId)` | `Outcome<void, StudyRejection>` | A3; BR-STUDY-014 |
| `ResumeStudySession(sessionId)` | `Outcome<void, StudyRejection>` | A3b; BR-STUDY-072, BR-STUDY-075 |
| `AbandonStaleSessions()` | `Future<void>` | A3b; BR-STUDY-072 |
| `WatchStudyEntry(deckId)` | `Stream<Outcome<StudyEntry, StudyRejection>>` | Steps 1–2, 4; E1 |
| `WatchStudySession(sessionId)` | `Stream<Outcome<StudySessionView, StudyRejection>>` | Steps 6–13, A5; E5 |

`AnswerStudyTurn` holds the E2/E3 policy (D9). It catches a `Failure`. For anything
but a `DatabaseLockedFailure`, it calls `failSession` in a new transaction, then
rethrows the original `Failure`, which is what the UI shows. If `failSession`
fails as well, its own `Failure` is caught by type and dropped with a comment
saying why. The session then stays `in_progress`: Continue meets the same broken
storage, and `abandonStaleSessions` closes the session on a later day.

### 8.4 Repository and providers

- **`StudySessionRepository`** (contract) is implemented by
  `StudySessionRepositoryImpl(db, ScheduleRepository, CardRepository,
  SettingsRepository, {now, random})`. Its operations are:
  - open learning, open review, answer, abandon, resume, abandon stale, fail;
  - watch entry, watch session.
  Writes run in `_write`: one transaction and `mapDatabaseError`. The `srs` and
  `card` calls join it, as `CardRepositoryImpl` already does with
  `initializeCard`.
- **`SettingsRepository.studyOptionsOf({deckId})`:** a one-shot
  `Future<EffectiveStudyOptions?>` that joins the caller's transaction. It is null
  when the deck does not exist or is in the Trash, and it resolves the options as
  `watchStudyOptions` does.
- **`studySessionRepositoryProvider`** lives in `lib/features/study/di/`. The use
  case providers belong to `presentation/providers/`, which the UI session writes.
- `recordTurn`, `completeLearning` and `studyOptionsOf` get no use case: no
  interaction calls them (ADR-011 D4 covers interactions).

## 9. Errors

**`StudyRejection`** (ADR-011 D6):

| Value | When |
|---|---|
| `notFound` | The deck, the session or the card is gone |
| `nothingToLearn` | No new card in the subtree |
| `nothingDue` | No due card (BR-STUDY-054) |
| `modeNotOffered` | The mode is not a review mode of the scheduler (BR-STUDY-055) |
| `modeUnavailable` | The mode's stage does not run on the set (BR-MODE-009) |
| `directionRequired` | BR-MODE-018, validation |
| `directionNotAllowed` | BR-MODE-018, conflict |
| `sessionClosed` | The session is not `in_progress` |
| `sessionExpired` | The session is from an earlier local day (BR-STUDY-072) |
| `staleGeneration` | BR-STUDY-017 |
| `notCurrentCard` | The answer names a row that is not being served |
| `answerDoesNotFitMode` | The answer's type does not match the mode |
| `unsupportedAction` | The action is not in `supportedActions` (BR-STUDY-009) |

Unexpected errors leave as the typed `Failure` of `core/error`, and D9 decides
between E2 and E3.

## 10. Import map and tooling

- `test/architecture/boundary_rules.dart` gains `'study_mode': {'srs'}` and
  `'study': {'study_mode', 'srs', 'settings', 'card'}`, in the commits that create
  those folders.
- `verification_impact_map.json` already lists `study` and `study_mode`, and no
  `.drift` query file is added.
- The guard rule `single_study_mode_dispatch` gets its first target and must pass.
  No `targets_pending` entry concerns these layers.
- The test fake `_FailingScheduleRepository` in
  `test/features/card/data/card_repository_impl_test.dart` follows the changed
  `ScheduleRepository` contract in the same commit.

## 11. Documentation

- **`code:`** of UC-STUDY-001, UC-STUDY-003 and the study and study-mode READMEs.
  Both READMEs lose their stale "no `lib/`" warning. The study README's
  `depends_on` gains `settings`, whose options it reads.
- **`schema.md`:**
  - The `study_session` notes record D2: at most one `in_progress` session in the
    app.
  - The `answers_in_session` note states D8: 0 in round 1 means the card's first
    turn in the stage.
  - The `position` note states D7: a later round is built when the round before it
    ends.
- **`docs/features/study/data.md`:** the `completed` row also covers a queue whose
  remaining rows vanished (D12).
- **`docs/wbs_BE.md`:** BE-A3, BE-A4, BE-C3 and BE-A5 (backend) become `xong`, and
  package 3 is BE-A6.
- **`docs/_generated/`** is regenerated, since tests name the scenario and use case
  ids.
- **No BR or UC file changes.** D4, D5, D6 and D2 are recorded here and in
  `schema.md`.
- CHECKing invariant 24 needs a migration, which waits for BE-D1. Code and tests
  hold it until then (§12).

## 12. Verification

- Test first in every task. The five-command gate and `tools/docs/check.py` run
  after every task. `now` and `Random` are injected, and no test reads the wall
  clock.
- **Invariants.** A helper runs every query of `invariantQueries` (1–32, from
  `schema.md`) after each study scenario and expects no row. One query in the tests
  checks that at most one `in_progress` session exists (D2).
- **`study_mode`** (unit tests):
  - the dispatch covers the six modes, and `stageSequenceOf` / `reviewModesOf`
    per scheduler;
  - the table of §5.3, including the D5 source (IT-MODE-006, IT-MODE-015,
    IT-LEARN-006, IT-LEARN-007);
  - `actionOf` for every answer type, with refusals;
  - `stepAfter` for every row of §5.5, including the fourth `self_assess` turn;
  - `acceptsDirection` for every combination, and `assignDirections` with a
    difference of at most 1 on odd and even counts.
- **`srs`:**
  - the scheduler tables of BR-SRS-008, BR-SRS-009, BR-SRS-011 and BR-SRS-012.
    Example: `hard` takes the ease from 2.5 to 2.36, and an interval of 10 to 24;
  - `recordTurn` per kind: counters, `last_answered_at`, before = after on
    `relearning`;
  - `completeLearning`: the lowest level, due at the next local midnight, the lock
    set once, no log;
  - every rejection, and the Trash filter (BE-C3);
  - IT-REVIEW-005, IT-REVIEW-006 and IT-REVIEW-007 (host half).
- **`study`** (in-memory database):
  - **Opening:**
    - the subtree scope (IT-STUDY-011);
    - `created` and `random` (IT-STUDY-012);
    - the card limit, snapshotted (IT-STUDY-010, IT-LEARN-011, IT-REVIEW-004);
    - skipped stages (IT-LEARN-005, IT-LEARN-006, IT-LEARN-007);
    - a distinct sequence per stage (IT-LEARN-004);
    - review order (IT-REVIEW-004) and the review set (IT-REVIEW-001);
    - no session on an empty set (IT-STUDY-002, IT-STUDY-003);
    - closing the open session (IT-CONT-002, IT-CONT-014);
    - the direction rules (BR-MODE-018), and `mixed` stored per row.
  - **Turns:**
    - kinds and schedules (IT-REVIEW-005, IT-LEARN-012);
    - learning completion and the lock (IT-LEARN-010);
    - `self_assess` comeback, cap and flag (IT-LEARN-009);
    - rounds and failed sets (IT-LEARN-008);
    - stage chains (IT-LEARN-001, IT-LEARN-002) and one review mode
      (IT-REVIEW-002);
    - completion and summary (IT-CONT-005, IT-REVIEW-009);
    - no early review (IT-REVIEW-008).
  - **Endings and errors:**
    - resume on the same day (IT-CONT-001) and after a day change (IT-CONT-003);
    - a stale generation writes no turn (IT-CONT-010);
    - a transient error writes nothing and one retry writes once (IT-CONT-011);
    - a fatal error rolls back and closes the session as `failed` (IT-CONT-012);
    - a deleted deck (IT-CONT-007);
    - a queue that does not change when the deck does (IT-CONT-006);
    - a card deleted mid-session, settled by resume (D12).
  - **Watches:**
    - entry counts and per-mode counts (IT-STUDY-001, IT-STUDY-004, IT-STUDY-005,
      IT-STUDY-007, IT-REVIEW-010);
    - the four resume conditions;
    - the session view and its re-emission after a turn;
    - a read error leaves the session untouched (IT-CONT-013, host half).
- **Final review:** a whole-branch review by an independent reviewer. Critical and
  Important findings are fixed test first before the PR.

## 13. Coordination with the UI session

- New contract for FE-A6 and FE-A7:
  - the use cases of §8.3, `StudyEntry`, `StudySessionView` and `StudyAnswer`;
  - the `study_mode` domain the UI renders from (`stageSequenceOf`,
    `reviewModesOf`, `acceptsDirection`);
  - the provider in `study/di/`.
- Shared files touched:
  - `test/architecture/boundary_rules.dart` (two entries);
  - the `ScheduleRepository` and `SettingsRepository` contracts. Their only fakes are
    in this repository's tests and change in the same commits.

## 14. Out of scope

- **Package 2b:**
  - `fill` comparison, versioning, hints and the empty-answer rule (BR-STUDY-026 to
    BR-STUDY-030);
  - the `recall` timer, reveal and timeout (BR-STUDY-031 to BR-STUDY-036,
    BR-STUDY-065, BR-STUDY-066);
  - building `guess` questions, first choice only and the atomic block
    (BR-STUDY-037 to BR-STUDY-043);
  - `match` boards, turn attribution and feedback levels (BR-STUDY-049,
    BR-STUDY-062, BR-STUDY-070).
- **Study Home, and its Resume card** (BE-A6, UC-STUDY-002).
- **`content_deleted`** and the Trash (BE-B1).
- **A CHECK for invariant 24,** or any other schema change (BE-D1 comes first).
- **Screens, controllers, ARB strings,** and ignoring a second tap while a write
  runs (a controller concern, as in package 1).

## 15. Risks and rollback

- **The schedulers change behavior (§6.1).** No user data depends on the old
  branches (D13). Rollback: revert the task's commits.
- **Nested transactions across repositories.** `CardRepositoryImpl` already runs
  `initializeCard` inside its own transaction. The fatal-error test proves that a
  failure anywhere in a turn rolls back every row of it.
- **Building every stage at open.** At most `card_limit × 5` rows, 1000 at the
  upper bound of 200. Rollback: build each stage when it starts, as the rejected
  alternative did.
- **D2 is enforced in code, not by an index.** Opening a session runs in one
  transaction on SQLite's single writer, and a test checks the rule after every
  scenario. A unique partial index needs a migration and waits for BE-D1.
- **The private `switchMap`.** It gets its own tests: switching cancels the
  previous inner stream, and errors pass through.
