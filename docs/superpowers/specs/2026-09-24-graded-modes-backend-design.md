# MemoX V8 — Graded study modes backend design (package 2b)

Status: draft 2026-09-24, for the owner's review · Path: architectural

## 1. Intent

Build package 2b of [`docs/wbs_BE.md`](../../wbs_BE.md), in this order:

- **BE-D1**, the Drift migration test framework: a schema snapshot per version and
  tests that upgrade to the current version;
- **BE-A10**, the mechanics of the four graded modes (`fill`, `recall`, `guess`,
  `match`): the rest of UC-STUDY-001, BR-STUDY-026 to BR-STUDY-043, BR-STUDY-049,
  BR-STUDY-062, BR-STUDY-065, BR-STUDY-066 and BR-STUDY-070. It needs schema v2,
  the first migration, which is why BE-D1 comes first.

The package writes `lib/core/database/`, and `domain/`, `data/` and `di/` of the
features. The screens (17 Match, 18 Guess, 19 Recall, 20 Fill of the kit) belong
to FE-A6 in [`docs/wbs_FE.md`](../../wbs_FE.md).

Success means:

- a v1 database upgrades to v2 with its rows and their values intact, and the
  migration test proves it (§5.3);
- each graded mode judges the person's real input in the domain, and the UI never
  judges (§7);
- every interaction of the four modes is reachable through one use case (AD-12,
  ADR-011 D4);
- every rule listed above that the backend owns is enforced in the domain or inside
  the writing transaction, and a test fails when the rule is broken;
- the `HOST-FLOW` scenarios of §11 are covered by tests that name their scenario id;
- the schema invariants of `schema.md` hold after every study test and after the
  upgrade;
- the phased gate of the root `README.md` passes after every task;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-24)

- `master` is at `e0f2581`: package 2a (#45) merged.
- Package 2a left the graded modes a verdict: `GradedAnswer(isCorrect)`. Its spec
  (§5.4, §6.2, §8.2, §14) hands their mechanics to this package:
  - `review_log.outcome_reason`, `comparison_version` and `used_hint` stay NULL;
  - `study_queue_items.remaining_ms` and `is_revealed` exist, and nothing writes
    them;
  - `match` accepts a turn on any pending row of its round (`servesInOrder = false`,
    `StudyQueueDao.boardRow`); boards do not exist yet.
- **Schema.** `AppDatabase.schemaVersion` is 1, and its `MigrationStrategy` has only
  `beforeOpen`. `drift_schemas/drift_schema_v1.json` exists, and
  `test/database/schema_test.dart` checks that the snapshot of the current version
  exists at that flat path. No migration test exists (BE-D1).
- **Repo rule.** `.claude/skills/flutter-drift/references/migrations.md` holds the
  migration workflow and its rules. Two of its sentences come from V7: they say a
  hand-written v1 → v2 step already exists here and describe it as four
  `addColumn` and two `createTable` calls. V8 has no such step.
- **Guard.** The length rule warns at 400 logical lines and fails at 500. Its
  memox-v8 override already excludes `test/drift/generated/**`, drift's migration
  helper. `StudySessionRepositoryImpl` is at 345 logical lines. Files under `data/`
  must end in `_repository_impl`, `_dao`, `_mapper`, `_model`, `_data_source` or
  `_loader`. (Line counts here are non-blank, non-comment lines; the guard's own
  count decides.)
- **Folding.** `foldText` (`lib/core/text/folded_text.dart`) trims both ends and
  lower-cases with Dart's Unicode mapping. It keeps diacritics, and it fills
  `front_folded` and `back_folded`.
- **Kit.** Screen 17 Match has one state, 18 Guess one, 19 Recall three (hidden,
  revealed, timedOut) and 20 Fill three (input, hint, wrong). None is built. The
  kit does not draw the blocked `guess` question of BR-STUDY-040.
- **Documents that disagree with the rules** (§12 fixes the first three, with the
  owner's leave):
  - IT-MODE-008 steps 3–4 still treat a reveal as the recorded outcome, which
    BR-STUDY-065 forbids;
  - the data set `S-STUDY-FILL-V2` (`agent-execution-guide.md`) has front `Nghề
    nghiệp`, back `Công`, and IT-MODE-010 grades `  cÔnG  ` right, so it types the
    back. BR-STUDY-026 and the kit type the front;
  - the rationale of BR-STUDY-026 says the rule reuses `back_folded`, while its
    rule compares with `front_folded`;
  - the kit's `fill` wrong state says "comes back this round", while BR-STUDY-059
    sends the card to the next round. The rule wins; FE-A6 carries it.
- `test/support/invariant_queries.dart` runs invariants 1–32 of `schema.md`;
  33–37 wait for `delete_batches` (Trash).

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | BE-D1 first, then BE-A10, in one spec, one plan and one PR | Owner, 2026-09-24 |
| D2 | A `recall` reveal | A reveal is not an outcome: it records nothing, stops the clock and opens the two-choice self-assessment (BR-STUDY-065). IT-MODE-008 steps 3–4 change to match | Owner, 2026-09-24 |
| D3 | A `match` pair | A pair is right when the two cards have the same `back_folded`, the term's own meaning included. The turn is the term card's (BR-STUDY-062) | Owner, 2026-09-24 |
| D4 | Approach | Each graded handler judges the real input as a pure function of the answer and the facts the session hands it. Questions and boards are built with their round and stored. The `recall` reveal and time and the `fill` hint are writes that are not turns | Owner, 2026-09-24 (approach A of three) |
| D5 | Migration tooling | The repo skill's workflow: flat snapshots under `drift_schemas/`, `schema steps` for a `stepByStep` upgrade on the versioned schema, `schema generate` for the verifier. Every generated file is committed. `make-migrations` is not used: it keeps snapshots in `drift_schemas/<database>/`, which `schema_test.dart` does not read | Owner, 2026-09-24 |
| D6 | Schema v2 | Additive only: the table `study_guess_options` and the columns `study_queue_items.hint_shown` and `study_queue_items.meaning_slot`. The step rewrites no row | Owner, 2026-09-24 |
| D7 | The meanings of a `match` board | Stored in `meaning_slot`, shuffled per board when the round is prepared, and never in the terms' order on a board of two or more pairs. The board is the same after Continue (IT-CONT-001) | Owner, 2026-09-24 |
| D8 | When a round is prepared | When it starts being served: when a review opens in `match` or `guess`, when a learning session moves to a stage, when a new round is built, and on Continue. Preparing is idempotent: it fills in only what is missing, and it never rebuilds a question that has its five options. This refines "built with the round" of D4: round 1 of a later stage of a learning session is prepared when the stage starts, not when the session opens | Owner, 2026-09-24 |
| D9 | Turn result | `AnswerStudyTurn` returns `TurnResult.isCorrect` once the turn is committed, so the screen shows the verdict without judging (BR-STUDY-063) | Owner, 2026-09-24 |
| D10 | Writes that are not turns | `RevealRecallAnswer`, `SaveRecallTime`, `ShowFillHint`: no `review_log` row, no cursor move, the same session and row checks as a turn, and none of the E2/E3 policy of `AnswerStudyTurn` | Owner, 2026-09-24 |
| D11 | Document fixes | Authorized: IT-MODE-008 steps 3–4; the front and back of `S-STUDY-FILL-V2`; the one sentence of BR-STUDY-026's rationale that names `back_folded`. BR-STUDY-026's rule does not change | Owner, 2026-09-24 |
| D12 | Branch and PR | Branch `claude/be-graded-modes` from `master`. When the gate is green and the final review is clean, the package is opened as a PR and merged | Owner's standing choice |

## 4. Structure

```
lib/core/database/
├── tables/study.drift                      v2: two columns, study_guess_options (§6)
├── app_database.dart                       schemaVersion 2, onUpgrade (§5.2)
└── schema_versions.dart                    generated by `schema steps`, committed

drift_schemas/drift_schema_v2.json          generated by `schema dump`, committed
test/drift/generated/                       generated by `schema generate`, committed
test/drift/migration_test.dart              §5.3

lib/features/study_mode/domain/
├── models/study_answer_model.dart          FillAnswer, RecallAnswer, GuessAnswer,
│                                           MatchAnswer; GradedAnswer removed (§7.1)
├── models/turn_judgement_model.dart        TurnCard, TurnContext, TurnVerdict,
│                                           OutcomeReason (§7.2)
├── models/round_preparation_model.dart     RoundRowFacts, MeaningCard,
│                                           RoundPreparation (§7.7)
├── models/study_mode.dart                  judge replaces actionOf; prepareRound;
│                                           asksWithOptions
├── models/graded_mode.dart                 the right/wrong mapping the four share
├── models/fill_mode.dart                   §7.3
├── models/recall_mode.dart                 new: RecallModeHandler (§7.4)
├── models/guess_mode.dart                  §7.5
├── models/match_mode.dart                  §7.6
└── failures/study_mode_failure.dart        six new reasons (§7.8)

lib/features/srs/                           ReviewTurn's three fields and their
                                            write (§8.4)

lib/features/study/
├── domain/models/turn_result_model.dart    TurnResult (§8.1)
├── domain/models/study_session_view_model.dart
│                                           GuessQuestion, GuessOption, MatchBoard,
│                                           MatchTile, hintShown (§9)
├── domain/failures/study_failure.dart      seven new reasons (§7.8)
├── domain/repositories/
│   ├── study_session_repository.dart       answerTurn returns TurnResult; the three
│   │                                       writes of §8.3
│   └── study_session_view_repository.dart  new: watchSession moves here (§8.5)
├── domain/usecases/                        AnswerStudyTurn changes; RevealRecallAnswer,
│                                           SaveRecallTime, ShowFillHint are new
├── data/datasources/study_round_dao.dart   new: round facts, meaning slots, options,
│                                           the meaning source (§8.2)
├── data/datasources/                       the current board, the row flags
├── data/repositories/                      both writers prepare rounds; the view
│                                           repository is new (§8.5)
├── data/mappers/study_session_view_mapper.dart   the board and the options (§9)
└── di/                                     one more provider
```

## 5. BE-D1: the migration framework

### 5.1 Workflow

The workflow is the one in `.claude/skills/flutter-drift/references/migrations.md`,
run from the repository root after `build_runner`:

```bash
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

- `schema dump` writes `drift_schema_v2.json` next to `drift_schema_v1.json`. The
  flat layout stays, because `schema_test.dart` reads it.
- `schema steps` writes the versioned schemas and `stepByStep`. A step then works on
  the schema of its own version, never on the tables of today's code (the skill's
  rule against current application code in a migration).
- `schema generate` writes the `SchemaVerifier` helpers and the versioned schemas the
  tests open.

### 5.2 `AppDatabase`

- `schemaVersion` becomes 2.
- `onUpgrade: stepByStep(from1To2: …)` adds the two columns and creates the table
  and its index (§6.3).
- `beforeOpen` does not change: it turns foreign keys on and inserts the settings row
  once the schema is current.
- `onCreate` stays drift's `createAll`.

### 5.3 The migration test

`test/drift/migration_test.dart` proves, from snapshot v1 to v2:

1. **The schema arrives:** `SchemaVerifier.migrateAndValidate(db, 2)`.
2. **The data keeps its meaning.** Realistic v1 rows go in with raw SQL:
   - three trees, learned and new cards and their schedules;
   - a completed session and an open one;
   - queue rows in `browse`, `self_assess`, `match`, `guess`, `recall` (with
     `remaining_ms` and `is_revealed` set) and `fill`;
   - `review_log` rows of every kind, `fill` and `recall` ones with their columns.

   After the upgrade every v1 column of every row holds its value, `hint_shown` is 0,
   `meaning_slot` is NULL, and `study_guess_options` is empty.
3. **The invariants still hold:** every invariant query of `schema.md` in scope
   returns no row on the upgraded database.
4. **The file is sound:** `PRAGMA integrity_check` returns `ok`, and
   `PRAGMA foreign_key_check` returns no row.

A fresh v2 database and an upgraded one both validate against snapshot v2, so the
two paths end at the same schema. `schema_test.dart`'s snapshot check keeps
passing, now for v2.

### 5.4 Generated files

- `drift_schema_v2.json`, `lib/core/database/schema_versions.dart` and
  `test/drift/generated/` are committed. Nobody writes them, and a released schema
  cannot be regenerated once the `.drift` files move on.
- The guard's length rule excludes `schema_versions.dart`, as it already excludes
  `test/drift/generated/**`. The analyzer excludes a generated file only if it
  reports lints in it; the plan records any such case.

### 5.5 The repo skill

The two V7 sentences of `migrations.md` (§2) are corrected: V8's first step is v1 →
v2 of this package, written with `schema steps` and `stepByStep`, and it adds two
columns, one table and one index. Nothing else in the skill changes.

## 6. Schema v2

### 6.1 `study_queue_items`

Two columns, declared after `direction`:

```sql
-- fill only: the hint of the turn in progress was shown (BR-STUDY-028).
hint_shown INTEGER NOT NULL DEFAULT 0
  CHECK (hint_shown IN (0, 1) AND (mode = 'fill' OR hint_shown = 0)),
-- match only: the slot of this card's meaning on its board (BR-STUDY-049; D7).
meaning_slot INTEGER
  CHECK (meaning_slot IS NULL OR (mode = 'match' AND meaning_slot BETWEEN 0 AND 4)),
```

- `hint_shown` is set by `ShowFillHint` (§8.3). A turn's `used_hint` is read from it,
  not from the UI's input, so it holds across Continue after the app was killed.
- A `match` row gets `meaning_slot` when its round is prepared (§8.2). A board is the
  rows of positions `5k … 5k+4` of the round (BR-STUDY-049).

### 6.2 `study_guess_options`

```sql
-- The five options of a guess question, in the order shown (BR-STUDY-037,
-- BR-STUDY-043). A question with fewer rows is blocked (BR-STUDY-040).
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

- `mode` exists for the composite foreign key: an option belongs to a `guess` row,
  and it goes with that row when the session or the asked card is deleted.
- Deleting a card that is an option removes that option only. The question then has
  four rows and is blocked until Continue prepares it again (§8.2).
- The index serves the card cascade.

### 6.3 The v1 → v2 step

`from1To2` adds `hint_shown` and `meaning_slot` to `study_queue_items`, creates
`study_guess_options`, then creates its index. It rewrites no row.

Whether `addColumn` is enough for the verifier (§5.3: claim 1 and the check that a
fresh and an upgraded database end at the same schema), or the column order of a
fresh table forces a `TableMigration` of `study_queue_items`, is settled by the
plan's prototype and recorded there. A `TableMigration` copies every row as
it is, so neither path changes a value.

### 6.4 Invariants 38–40

Added to "Bất biến" in `schema.md`, run by `invariants_test.dart` and by
`expectStudyInvariants`:

```sql
-- 38. `hint_shown` nằm ngoài `fill` (BR-STUDY-028)
SELECT session_id FROM study_queue_items
WHERE hint_shown NOT IN (0, 1) OR (mode <> 'fill' AND hint_shown <> 0);

-- 39. `meaning_slot` nằm ngoài `match`, vượt 0–4, hoặc hai cặp của một bàn chung
--     một chỗ (BR-STUDY-049)
SELECT session_id FROM study_queue_items
WHERE meaning_slot IS NOT NULL AND (mode <> 'match' OR meaning_slot NOT BETWEEN 0 AND 4)
UNION ALL
SELECT session_id FROM study_queue_items
WHERE mode = 'match' AND meaning_slot IS NOT NULL AND position >= 0
GROUP BY session_id, round, position / 5, meaning_slot
HAVING COUNT(*) > 1;

-- 40. Câu `guess` quá năm lựa chọn, hoặc không có đúng một đáp án đúng (BR-STUDY-037)
SELECT session_id FROM study_guess_options
GROUP BY session_id, round, card_id
HAVING COUNT(*) > 5 OR SUM(option_card_id = card_id) <> 1;
```

- The parser of `invariant_queries.dart` runs 1–32 and 38 onward. 33–37 still wait
  for `delete_batches`.
- Two options with the same `back_folded` (BR-STUDY-039) is not an invariant: editing
  a card after its question was built can make it true legitimately. The question
  builder enforces it, and a test pins it (§7.5).

### 6.5 Sessions open across the upgrade

The step writes no row, so a session open when the upgrade runs keeps its rows as
they are:

- In `match` or `guess`, it has no meaning slots and no questions. Continue prepares
  its round (§8.2) and fills them in.
- In `fill`, every row has `hint_shown = 0`. A hint shown before the upgrade was
  never stored, so that turn's `used_hint` is 0, which is what v1 kept.

V8.0 is not released; this path exists for the migration test and for developer
devices.

## 7. The study-mode domain

### 7.1 Answers

`StudyAnswer` stays sealed, and each mode takes its real input:

| Answer | Mode | Carries |
|---|---|---|
| `AdvanceAnswer` | `browse` | nothing (package 2a) |
| `SelfAssessAnswer(action)` | `self_assess` | the action pressed (package 2a) |
| `FillAnswer(typed)` | `fill` | the text typed, which is never stored (BR-STUDY-030) |
| `RecallAnswer(outcome)` | `recall` | `RecallOutcome.remembered`, `forgot` or `timedOut` |
| `GuessAnswer(chosenCardId)` | `guess` | the option chosen, by card id (BR-STUDY-041) |
| `MatchAnswer(meaningCardId)` | `match` | the meaning paired with the turn's card, which is the term's (BR-STUDY-062) |

`GradedAnswer` is removed. The package 2a tests that use it move to the real inputs
through helpers in `test/support/study_fixtures.dart`, which read the session view to
answer right or wrong in any mode (a right `recall` answer reveals first).

### 7.2 Judging a turn

`StudyModeHandler.actionOf(answer, scheduler)` becomes
`judge(answer, context, scheduler)`, which returns
`Outcome<TurnVerdict, StudyModeRejection>`.

- **`TurnContext`** holds the facts the session reads in the turn's transaction:
  - `card`, a `TurnCard`: the card's id, `frontFolded` and `backFolded`;
  - `isRevealed` and `hintShown` of the row;
  - `guessOptionIds`: the stored options of the row, in slot order (`guess`);
  - `boardMeanings`: card id → `backFolded` of the pending pairs of the current board
    (`match`).
- **`TurnVerdict`** holds:
  - the `action`;
  - `isCorrect`: null for `browse` and `self_assess`;
  - what `review_log` keeps of the turn: `outcomeReason`, `comparisonVersion`,
    `usedHint`;
  - for `match`, `takesMeaningSlotOf`, the card whose meaning slot the turn's card
    takes (§7.6).
- `OutcomeReason` is an enum with one value, `timeout('timeout')`. `srs` receives its
  code as text, the way it receives the mode.
- The four graded modes map right to `remembered` and wrong to `forgotten`, and check
  the action against the scheduler's `supportedActions` (BR-MODE-012, as in 2a).
- `browse` and `self_assess` ignore the context and keep their 2a behavior.
- Row steps do not change (2a §5.5): `Leave` or `LeaveAndEnroll`, and for `match`
  `Leave` or `StayAndEnroll`.

### 7.3 `fill` (BR-STUDY-026 to BR-STUDY-030)

- `foldText(typed)` empty: `emptyAnswer`. Nothing is written and the cursor does not
  move (BR-STUDY-029).
- Right when `foldText(typed) == card.frontFolded`: both ends trimmed, Unicode lower
  case, diacritics kept, so `cong` does not match `công` (BR-STUDY-026).
- The verdict carries `comparisonVersion = fillComparisonVersion`, which is 1 for
  this policy. Changing the policy raises the constant and never touches earlier
  turns (BR-STUDY-027).
- The verdict carries `usedHint = context.hintShown`, which changes neither the
  action nor the schedule (BR-STUDY-028).

### 7.4 `recall` (BR-STUDY-031 to BR-STUDY-036, BR-STUDY-065, BR-STUDY-066)

- `RecallModeHandler` replaces the bare `GradedModeHandler` of 2a. It holds
  `recallTurnMs = 20000`, the time of one turn (BR-STUDY-031).
- `remembered` or `forgot` needs `isRevealed`; otherwise `notRevealed`. Only the
  person's choice is recorded, once (BR-STUDY-065).
- `timedOut` needs a row not revealed; otherwise `alreadyRevealed`. It records wrong
  with `outcomeReason = timeout` (BR-STUDY-032 to BR-STUDY-034). A retry after a
  failed write sends the same `timedOut` (BR-STUDY-033).
- The UI measures interaction time (BR-STUDY-031) and decides which of a reveal and a
  timeout came first at the deadline (BR-STUDY-032). The backend makes the two
  exclusive: once a reveal is stored, a timeout is refused; once a timeout is
  recorded, the row has left and a reveal is refused.

### 7.5 `guess` (BR-STUDY-037 to BR-STUDY-043)

**Judging.**

- Fewer than five stored options: `questionBlocked`. Nothing is written, nothing is
  skipped, and the cursor does not move (BR-STUDY-040).
- A chosen id that is not one of the options: `notAnOption`.
- Right when the chosen id is the card's own id (BR-STUDY-041).

**Building a question.** `guessOptionsFor(asked, source, random)` returns five card
ids in the order shown, or null.

1. Group `source` by `meaningFolded`. Leave out the asked card and every card with the
   asked card's meaning (BR-STUDY-039).
2. Fewer than four groups left: null, and the question is blocked (BR-STUDY-040).
3. Otherwise draw four groups and one card of each with `random`. Groups sort by
   meaning and cards by id first, so a seeded draw repeats whatever order the source
   comes in.
4. Add the asked card and shuffle the five with `random`.

That shuffle is its own permutation, independent of the round's card order
(BR-STUDY-043). The source is §8.2's. BR-STUDY-042 holds because the row leaves after
its first turn; the controller ignores a second tap while a write runs (2a §14).

### 7.6 `match` (BR-STUDY-049, BR-STUDY-062, BR-STUDY-070)

- `matchBoardSize = 5`. A row's board is `position ~/ matchBoardSize`. The current
  board is the board of the lowest pending position of the round.
- The turn's card must be a pending pair of the current board; otherwise
  `notCurrentCard`. This tightens 2a, which took any pending row of the round.
- The meaning must be a pending pair of the current board; otherwise `notOnBoard`.
- Right when the two `back_folded` are equal (D3). A wrong meaning never marks the
  card that owns it (BR-STUDY-062). There are two levels only, right and wrong
  (BR-STUDY-070, IT-MODE-004 step 4).
- A right pair on another card's meaning sets `takesMeaningSlotOf`. The two rows then
  swap `meaning_slot`, so the tile the person tapped is the one marked matched, and
  the other card keeps a tile with the same text.
- `meaningSlotsFor(pairCount, random)` returns a slot for each pair of a board, in
  position order. It is a shuffle that never keeps the terms' order when there are
  two or more pairs: if the shuffle kept it, the first two slots swap, as
  `shuffledUnlike` does.

### 7.7 Preparing a round

Two new members of `StudyModeHandler`:

- `asksWithOptions`, true for `guess`. The session then reads the meaning source and
  the stored options.
- `prepareRound(facts, meaningSource: …, random: …)`, which returns a
  `RoundPreparation` and is empty by default.
  - The input is `RoundRowFacts` for each built row of the round: card id, position,
    pending or not, `meaningSlot`, option count, `meaningFolded`.
  - `match` gives every board with a row lacking a slot a full set of slots from
    `meaningSlotsFor`.
  - `guess` gives every pending row with fewer than five options a question from
    `guessOptionsFor`, or null when it cannot be built.

Mode-specific choices stay handler members, so the guard's one-dispatch rule holds.

### 7.8 Rejections

- `StudyModeRejection` gains `emptyAnswer`, `notRevealed`, `alreadyRevealed`,
  `questionBlocked`, `notAnOption` and `notOnBoard`.
- `StudyRejection` gains the same six and `noHint`. `ofModeRefusal` maps them.
- The documentation of `answerDoesNotFitMode` widens to a reveal, a time save or a
  hint asked of a row of another mode.

## 8. The study write path

### 8.1 A turn

`answerTurn({sessionId, cardId, answer, now})` returns
`Outcome<TurnResult, StudyRejection>` in one transaction. Only steps 2, 3, 5, 6 and 8
change from 2a §7.3:

1. The session is open and its generation holds (`_live`, unchanged).
2. The row:
   - modes served in order take the head row, which must be `cardId`'s;
   - `match` takes `cardId`'s pending row on the current board.
3. The `TurnContext`: the card's folded fields, the row's flags, and the stored
   options (`asksWithOptions`) or the board's pending pairs (`match`).
4. `judge`. A refusal returns its `StudyRejection` and writes nothing.
5. `recordTurn`, with the verdict's `outcomeReason`, `comparisonVersion` and
   `usedHint`.
6. The row step, then the `meaning_slot` swap when the verdict names a card.
7. Cursor, learning completion and `_progress`, as in 2a. `_progress` also prepares
   the round it moves to (§8.2).
8. Returns `TurnResult(isCorrect: verdict.isCorrect)`.

`TurnResult.isCorrect` is null for `browse` and `self_assess`, whose result the
person chose.

### 8.2 Preparing a round

**Where.** Both writers prepare rounds, so the pieces are split by layer:

- the handler decides (§7.7);
- `StudyRoundDao` reads the round's facts and the meaning source, and writes the
  slots and the options;
- the repository reads, calls `prepareRound` and writes, in the caller's transaction.
  This is the pattern 2a uses for `learningQueues` and `insertFirstRound`.

Writing a question replaces the row's options: a rebuilt question, or one that
cannot be built, first removes the options left from before.

**When** (D8):

| Moment | Round prepared |
|---|---|
| A review opens in `match` or `guess` | round 1, after its rows are inserted |
| `_progress` moves a learning session to a stage | that stage's round 1 |
| `_progress` builds a new round | that round, after it is numbered |
| Continue (`resumeSession`) | the round the session serves, after `_progress` |

**Idempotent.** A board that has its slots and a question that has its five options
are left as they are (BR-STUDY-043: stable on Continue). What Continue fills in is
what a v1 session lacks (§6.5), or a question that lost an option to a card deletion.
A later round's rows are new rows, so they get new questions: a turn in a later round
is a new turn (BR-STUDY-036).

**The meaning source** is the set of package 2a's spec D5: the cards of the session's
queue and the learned, active cards of the root's tree, with their `back_folded`.

```sql
SELECT c.id, c.back_folded FROM card c
JOIN deck d ON d.id = c.deck_id
JOIN card_schedule cs ON cs.card_id = c.id
WHERE d.root_id = ? AND c.delete_batch_id IS NULL AND d.delete_batch_id IS NULL
  AND (cs.learned_at IS NOT NULL
       OR c.id IN (SELECT card_id FROM study_queue_items WHERE session_id = ?))
ORDER BY c.back_folded, c.id
```

A new card outside the session and a card of another root never appear (IT-MODE-015).

### 8.3 Writes that are not turns

| Write | Mode | Effect |
|---|---|---|
| `revealRecallAnswer({sessionId, cardId, remainingMs, now})` | `recall` | `is_revealed = 1`; `remaining_ms` = the smaller of the stored time (20000 when NULL) and `remainingMs`. A second reveal changes nothing (BR-STUDY-065, BR-STUDY-036) |
| `saveRecallTime({sessionId, cardId, remainingMs, now})` | `recall` | `remaining_ms` = the smaller of the stored time and `remainingMs`: the time left never grows. Once revealed, it changes nothing (BR-STUDY-036) |
| `showFillHint({sessionId, cardId, now})` | `fill` | `hint_shown = 1`. A card without a hint: `noHint`. A second call changes nothing (BR-STUDY-028) |

- **Checks.** Each write checks what a turn checks:
  - the session is open and its generation holds (`_live`, which also invalidates a
    stale session);
  - `cardId` is the served row (`notCurrentCard`);
  - the session is in the write's mode (`answerDoesNotFitMode`).
- **Effect.** None writes `review_log` or moves the cursor.
- **Input.** The use case refuses a `remainingMs` outside 0…20000 with an
  `ArgumentError` before any write: it is a bug in the caller.
- **Errors.** A write error reaches the UI as the `Failure` 2a maps. There is no
  `failed` session here, since no turn is lost.
- **Note for FE-A6.** Call `SaveRecallTime` when the app goes to the background and
  when the screen closes, not on every tick: each write makes the session stream emit
  again.

### 8.4 `srs`: the turn's extra columns

- `ReviewTurn` gains `outcomeReasonCode` (`String?`), `comparisonVersion` (`int?`)
  and `usedHint` (`bool?`), and `recordTurn` writes them to `review_log` as given.
- The CHECKs of invariants 22 and 23 refuse one written on another mode. That is a
  bug, which rolls the turn back (2a §6.5).

### 8.5 Splitting the session repository

With this package, `StudySessionRepositoryImpl` would cross the guard's 400-line
warning. The session screen's read moves to a new repository, which also takes the
board and the options of §9:

- `StudySessionViewRepository` has one member, `watchSession`;
- its implementation is `StudySessionViewRepositoryImpl(db)`;
- `WatchStudySession` takes it, and it gets a provider.

The writes stay in `StudySessionRepository`. If the plan's prototype shows the write
side still over 400, the plan records the next cut as a Clarification.

## 9. The session read model

`WatchStudySession` emits `StudySessionView` as in 2a, read in one emission. It
re-emits when `study_guess_options` changes too. Additions:

- **`StudyItem.guess`** (`guess` only) is a `GuessQuestion`:
  - `options`: five `GuessOption(cardId, meaning)` in slot order, where `meaning` is
    the option card's `back`;
  - empty with `isBlocked` when fewer than five are stored (BR-STUDY-040: the
    question is not rendered).
- **`StudyItem.remainingMs`** (`recall` only): the stored time, or `recallTurnMs`
  while the row has none.
- **`StudyItem.hintShown`**: the row's flag for `fill`, false otherwise.
- **`StudySessionView.board`** (`match` only) is a `MatchBoard` of the current board:
  - `terms`: in position order;
  - `meanings`: in `meaning_slot` order, then position;
  - each is a `MatchTile(cardId, text, isMatched)`, where `isMatched` means the row
    is completed in this round.
  - `currentItem` is the board's first pending pair, and `progress` counts the whole
    round (BR-STUDY-049).

What the kit's states read:

| Screen | State | From the backend |
|---|---|---|
| 17 Match | idle, selected, matched | `board`; `selected` is UI state; `isMatched` from the row |
| 18 Guess | options; correct, wrong, faded after a pick | `guess.options`; `TurnResult.isCorrect`; the right option is the one whose `cardId` is the item's |
| 19 Recall | hidden, revealed, timedOut | `isRevealed`, `remainingMs`; timedOut is the screen after a committed `timedOut` turn |
| 20 Fill | input, hint, wrong | `hint`, `hintShown`; wrong from `TurnResult`, with `front` as the answer shown (BR-STUDY-026) |

## 10. Use cases — the contract for the UI

| Use case | Returns | Source |
|---|---|---|
| `AnswerStudyTurn(sessionId, cardId, answer)` | `Outcome<TurnResult, StudyRejection>`; was `Outcome<void, …>`, E2/E3 policy unchanged | UC-STUDY-001 steps 6–13; BR-STUDY-063 |
| `RevealRecallAnswer(sessionId, cardId, remainingMs)` | `Outcome<void, StudyRejection>` | BR-STUDY-065, BR-STUDY-036 |
| `SaveRecallTime(sessionId, cardId, remainingMs)` | `Outcome<void, StudyRejection>` | BR-STUDY-031, BR-STUDY-036 |
| `ShowFillHint(sessionId, cardId)` | `Outcome<void, StudyRejection>` | BR-STUDY-028 |
| `WatchStudySession(sessionId)` | as in 2a, from `StudySessionViewRepository`, with §9's additions | UC-STUDY-001 steps 6–13 |

The other use cases of 2a do not change.

## 11. Tests

Test first, on in-memory SQLite with the real repositories, as in 2a.

**Scenarios (`HOST-FLOW`).** Each test names its id:

| Scenario | What the test proves |
|---|---|
| IT-MODE-004F | A wrong pair records a wrong turn on the term's card only. The pair stays on the board, the card enrolls in the next round once, and the next round holds exactly the two cards that were ever wrong |
| IT-MODE-005F | Five options, the right one once. The first pick records one turn, and a second answer to the same question is refused |
| IT-MODE-007 | The options and the card order stay the same across Continue. A new round has a new card order and new options, from a separate shuffle |
| IT-MODE-008F | A reveal records nothing and stops the time. Then one self-assessment records once, and a second is refused |
| IT-MODE-009F | A timeout records wrong with `timeout`. The saved time survives Continue, and a reveal or a second timeout afterwards is refused |
| IT-MODE-010 | `  cÔnG  ` is right on front `Công`, and `cong` is wrong. A blank answer writes nothing and does not move the cursor. The typed text is stored nowhere |
| IT-MODE-011 | A shown hint is recorded as `used_hint = 1` without changing a wrong result. One submission only |
| IT-MODE-014 | A `QueryInterceptor` cuts the meaning source to three distractors, with the database untouched. The question is blocked: no options in the view, the answer refused, cursor and progress unchanged. A new session without the fault gets five options |
| IT-MODE-015 | The options come from learned cards of the same tree: no new card outside the session, no card of another root, at most one card per `back_folded` |

**Also covered:**

- the board keeps its matched pairs and positions through the round (the backend half
  of IT-MODE-003, a `HOST-WIDGET` scenario);
- a right pair on another card's equal meaning swaps the slots;
- a meaning of another board is refused;
- an option card deleted, then Continue, rebuilds the question;
- a v1 session open in `guess` and `match` gets questions and slots on Continue;
- `SaveRecallTime` after a reveal changes nothing;
- `ShowFillHint` on a card without a hint is refused;
- `remainingMs` out of range is an `ArgumentError`;
- every turn writes `comparison_version` and `used_hint` on `fill` only, and
  `outcome_reason` on a `recall` timeout only.

**Domain, pure:**

- each handler's `judge`: every rejection, right and wrong, and the verdict's extras;
- `guessOptionsFor`:
  - five ids, the asked one once;
  - distinct meanings, the asked meaning excluded;
  - null below four other meanings;
  - repeatable under a seed;
- `meaningSlotsFor`: never the identity from two pairs on; one pair gets slot 0;
- `prepareRound`: fills only what is missing.

**Migration:** §5.3.

**Invariants:** 38–40 run in `invariants_test.dart`, whose seed gains `guess`
options, meaning slots and a shown hint, and in `expectStudyInvariants` after every
study test.

## 12. Documents

Changed in the same commits as the code they describe:

- **`docs/shared/data/schema.md`:**
  - the two columns and the table (§6);
  - their rows in the column → rule map;
  - invariants 38–40.
- **`docs/features/study/data.md`:** preparing a round (§8.2) and the three writes that
  are not turns (§8.3).
- **`docs/features/study/it-scenarios.md`, IT-MODE-008 steps 3–4 (D11):**

  | Bước | Thao tác người dùng | Kết quả mong đợi |
  |---|---|---|
  | 3 | Chạm Hiện đáp án trước hạn | Mặt sau hiện ra, đồng hồ dừng, và hai lựa chọn Nhớ được/Đã quên xuất hiện; chưa có kết cục nào được ghi (BR-STUDY-065) |
  | 4 | Chọn Nhớ được hoặc Đã quên | Chỉ lựa chọn đó được ghi, đúng một lần; lượt tự chuyển sau khi ghi, không có nút Tiếp theo (BR-STUDY-066); chỉ vòng sau mới bắt đầu lại 20 giây |

- **`docs/shared/testing/agent-execution-guide.md`, `S-STUDY-FILL-V2` (D11):** mặt
  trước `Công`, mặt sau `Nghề nghiệp`. The example, the hint and the rest stay.
- **`docs/features/study/rules/BR-STUDY-026-…md`, rationale (D11):** "dùng lại
  `back_folded`" becomes "dùng lại `front_folded`". Nothing else in the file changes.
- **`code:` fields:** UC-STUDY-001, and the READMEs of `study` and `study-mode`.
- **`docs/wbs_BE.md`:**
  - BE-D1 and BE-A10 done;
  - BE-B1 brings migration v2 → v3;
  - the order and the update log.
- **`.claude/skills/flutter-drift/references/migrations.md`:** §5.5.
- **`docs/_generated/`:** regenerated.

## 13. Out of scope

- Screens 17–20, controllers and ARB strings (FE-A6), and ignoring a second tap while
  a write runs (a controller concern, 2a §14).
- The recall countdown: the UI measures interaction time and pauses it
  (BR-STUDY-031). The backend stores what the UI reports.
- The blocked `guess` screen, which the kit does not draw: FE-A6 shapes it with
  Impeccable.
- Study Home (BE-A6).
- The Trash (BE-B1): a card in the Trash stays in the table, so its options will need
  a filter then.
- A unique index for the one open session of 2a D2: it needs a migration of its own,
  and is not added here.
- The two minors 2a deferred, unless the plan's prototype meets them in code this
  package touches:
  - `StudyQueueDao.build()` row by row;
  - `ReviewModeOption.cardCount` for a mode that cannot run.

## 14. Risks and rollback

- **The first migration runs on devices and cannot be undone there.**
  - It is additive (D6) and proven by §5.3.
  - Before a release, rollback is a revert of the package's commits.
  - After one, a shipped migration is immutable: a repair is a new version that goes
    forward (the repo skill).
- **The `match` answer narrows** from the round to the current board (§7.6). 2a's
  tests that answered across boards change in the same task, with the behavior they
  now pin.
- **`AnswerStudyTurn` changes its return type.** No UI calls it yet.
- **The repository split (§8.5)** moves one member, and its use case changes with it.
  Rollback: revert that task's commits.
