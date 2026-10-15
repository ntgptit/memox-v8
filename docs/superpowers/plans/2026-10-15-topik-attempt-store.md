# TOPIK attempt store (Drift v17) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Store TOPIK attempts on the device: schema v17 with `topik_attempt` and `topik_attempt_answer`, immutability and sync-capture triggers, the account-switch reset, and a `TopikAttemptRepository` that starts, answers, times, submits (scored and snapshotted) and deletes attempts and streams them back (spec §13.1, §13.5; Phase 2 plan 2 of §13.9, epic DEV-394).

**Architecture:** Two `.drift` tables in `lib/core/database/tables/topik.drift`, guarded by `CHECK`s and `BEFORE UPDATE` triggers so a completed attempt cannot change; the two capture triggers in `sync.drift` queue a submitted attempt and the deletion of a submitted attempt. Queries live in `queries/topik_queries.drift`, read through `TopikAttemptDao`; `TopikAttemptRepositoryImpl` runs every write in one `mappedTransaction` and maps rows to pure domain models. Scoring is the pure domain function `scoreTopikAttempt`, called inside the submit transaction.

**Tech Stack:** Dart 3.13 / Flutter 3.47.5, Drift (`.drift` files, `drift_dev` schema tools), Riverpod 3 codegen, `flutter_test`, `drift_dev/api/migrations_native.dart`.

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` (§5.1–§5.4, §6.3, §7, §13.1, §13.2, §13.5). Rules: `docs/features/topik/rules/BR-TOPIK-010…019`, `BR-TOPIK-022`, `BR-TOPIK-026`, `BR-TOPIK-027`. Skill: `flutter-drift` (`references/migrations.md`, `schema-conventions.md`, `testing-database.md`).

## Global Constraints

- Layering (ADR-011): `domain/` imports no Flutter, Riverpod or Drift; no Drift type (row, `Companion`, `Selectable`) leaves `data/`; a transaction never starts above `data/`.
- File suffixes: domain `_model.dart`, `_repository.dart`, `failures/*_failure.dart`; data `_dao.dart`, `_mapper.dart`, `_repository_impl.dart`; di `_provider.dart`.
- Drift: tables in `lib/core/database/tables/*.drift`, queries in `lib/core/database/queries/*.drift`, the DAO a `@DriftAccessor(include: {...})` (ADR-020). Row classes are `TopikAttemptRow` and `TopikAttemptAnswerRow` (`AS ...`). Drift still names the **table classes** `TopikAttempt` and `TopikAttemptAnswer` (as `card` gives `Card`), which collide with the domain models: a file that imports both imports `app_database.dart` with `show` (precedent: `lib/core/sync/sync_coordinator.dart`).
- `DATETIME` columns are UTC, stored by Drift as epoch seconds (ADR-008); durations are integer milliseconds; enums are text codes with a `CHECK`.
- Schema version 17; a migration on `master` is immutable (`block_released_migrations.py`). The v17 snapshot may be regenerated on this branch until it merges.
- Writes: one `_db.mappedTransaction` per repository write; legitimate refusals are `Rejected(TopikRejection.x)`, unexpected errors throw `Failure` (via `mappedTransaction` / `.mapDatabaseErrors()`). Ids from `newId()` (UUID v7), data layer only. Time from an injected `DateTime Function() now` (`dayClockProvider`), never `DateTime.now()` in a body.
- Sync capture triggers carry the `applying_remote` guard and `ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op`, as every trigger in `sync.drift` does. Entity type `topik_attempt`.
- Package imports only; `strict-casts`; no `print`; `dart format` before each commit; `dart run build_runner build --delete-conflicting-outputs` after any `.drift`, DAO or provider change.
- Tests of part of the suite run through `bash .claude/skills/flutter-workflow/scripts/run_tests.sh <file|dir>…`; the gate is `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`.
- Commits name the task's sub-issue (created under DEV-394 after approval, one per task in order) and end with the session's attribution lines.

## Review Focus

1. **A column added to `topik_attempt` later (Phase B `exam`)** that the immutability trigger's column list does not name: a completed attempt could then change through it. The test loops over `PRAGMA table_info` and requires every column but `server_version` to be refused (Task 2).
2. **A second Start racing a first on the same test** (double tap, two isolates): the partial unique index refuses the second open attempt even if both passed the read (Task 2 schema test; Task 4 tests the read path).
3. **Submit while the content changed shape** (a pack replaced so the test id or the question numbers no longer match the attempt): refused as `contentMismatch`, nothing written, the attempt stays in progress (Task 4).
4. **A write to an attempt deleted by another screen or by an account switch**: every write returns `notFound` and writes nothing; a watched attempt emits `null` (Task 4, Task 5).
5. **Negative elapsed time** (the clock moved back between two events): the store refuses it with an `ArgumentError` instead of shrinking a question's time; the presentation plan measures with a monotonic `Stopwatch` (Task 4 test; ledger note for plan 6).

---

### Task 1: Attempt models, scoring and the rejection enum

**Files:**
- Create: `lib/features/topik/domain/models/topik_attempt_status_model.dart`
- Create: `lib/features/topik/domain/models/topik_attempt_model.dart`
- Create: `lib/features/topik/domain/models/topik_attempt_score_model.dart`
- Create: `lib/features/topik/domain/models/topik_test_status_model.dart`
- Create: `lib/features/topik/domain/failures/topik_failure.dart`
- Modify: `lib/features/topik/domain/models/topik_question_model.dart` (public `topikOptionIdxs`)
- Modify: `lib/features/topik/domain/models/topik_content_check_model.dart` (use `topikOptionIdxs`, drop `_optionIdxs`)
- Modify: `test/support/topik_content_fixtures.dart` (add `topikTestFixture`)
- Test: `test/features/topik/domain/topik_attempt_score_test.dart`
- Test: `test/features/topik/domain/topik_test_status_test.dart`
- Test: `test/features/topik/domain/topik_attempt_model_test.dart`

**Interfaces:**
- Consumes: `TopikTest` (`testId`, `level`, `section`, `round`, `contentVersion`, `questions`), `TopikQuestion` (`no`, `points`, `answerIdx`, `questionType`), `TopikLevel`, `TopikSection`, `TopikQuestionType` (`code`, `ofCode`), `topikTestOf(json).test`, `topikTestJson({level, section, round})`.
- Produces:
  - `const Set<int> topikOptionIdxs = {1, 2, 3, 4};` (in `topik_question_model.dart`)
  - `enum TopikAttemptStatus { inProgress('in_progress'), completed('completed'); final String code; static TopikAttemptStatus fromCode(String code); }`
  - `enum TopikAttemptMode { practice('practice'); final String code; static TopikAttemptMode fromCode(String code); }`
  - `enum TopikAnswerStatus { correct, wrong, unanswered }`
  - `final class TopikAttempt` (fields below) with `bool get isCompleted`
  - `final class TopikAttemptAnswer` with `TopikAnswerStatus? get status`
  - `final class TopikAttemptDetail { TopikAttempt attempt; List<TopikAttemptAnswer> answers; }`
  - `final class TopikAnswerScore`, `final class TopikAttemptScore`, `TopikAttemptScore scoreTopikAttempt(TopikTest test, Map<int, int?> selections)`
  - `final class TopikTestStatus`, `Map<String, TopikTestStatus> topikTestStatusesOf(Iterable<TopikAttempt> attempts)`
  - `enum TopikRejection { notFound, inProgressExists, attemptCompleted, unknownQuestion, invalidOption, contentMismatch }`
  - `TopikTest topikTestFixture({TopikLevel level, TopikSection section, int round})` (test support)

- [ ] **Step 1: Add the fixture helper**

Append to `test/support/topik_content_fixtures.dart` (add the two imports at the top with the others):

```dart
import 'package:memox/features/topik/data/mappers/topik_test_mapper.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
```

```dart
/// [topikTestJson] read into a [TopikTest], for tests of code that takes the
/// content model. Answer of question n: `(n - 1) % 4 + 1`.
TopikTest topikTestFixture({
  TopikLevel level = TopikLevel.topik2,
  TopikSection section = TopikSection.reading,
  int round = 96,
}) => topikTestOf(
  topikTestJson(level: level, section: section, round: round),
).test!;
```

- [ ] **Step 2: Write the failing tests**

`test/features/topik/domain/topik_attempt_score_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_score_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/topik_content_fixtures.dart';

// BR-TOPIK-013, spec §5.3. Fixture: TOPIK I listening, questions 1–30,
// 1–10 worth 4 and 11–30 worth 3; the answer of question n is (n - 1) % 4 + 1.
void main() {
  final test1 = topikTestFixture(
    level: TopikLevel.topik1,
    section: TopikSection.listening,
  );
  Map<int, int?> blank() => {for (var no = 1; no <= 30; no++) no: null};

  test('scores correct, wrong and unanswered questions', () {
    final selections = blank()
      ..[1] = 1 // correct, 4 points
      ..[2] = 1 // wrong (answer 2)
      ..[11] = 3; // correct, 3 points

    final score = scoreTopikAttempt(test1, selections);

    expect(score.score, 7);
    expect(score.maxScore, 100);
    expect(score.correctCount, 2);
    expect(score.answeredCount, 3);
    expect(score.questionCount, 30);
    final byNo = {for (final a in score.answers) a.questionNo: a};
    expect(byNo[1]!.status, TopikAnswerStatus.correct);
    expect(byNo[1]!.pointsEarned, 4);
    expect(byNo[2]!.status, TopikAnswerStatus.wrong);
    expect(byNo[2]!.pointsEarned, 0);
    expect(byNo[2]!.correctIdx, 2);
    expect(byNo[3]!.status, TopikAnswerStatus.unanswered);
    expect(byNo[3]!.pointsEarned, 0);
    expect(byNo[3]!.points, 4);
    expect(byNo[11]!.questionType, TopikQuestionType.l1Topic);
  });

  test('answers come in question order', () {
    final score = scoreTopikAttempt(test1, blank());
    expect(
      score.answers.map((a) => a.questionNo),
      [for (var no = 1; no <= 30; no++) no],
    );
  });

  test('every answer right scores max_score; none answered scores 0', () {
    final all = {for (final q in test1.questions) q.no: q.answerIdx};
    final full = scoreTopikAttempt(test1, all);
    expect(full.score, full.maxScore);
    expect(full.correctCount, 30);

    final none = scoreTopikAttempt(test1, blank());
    expect(none.score, 0);
    expect(none.answeredCount, 0);
    expect(none.correctCount, 0);
  });

  test('TOPIK I reading keeps its real numbers 31–70', () {
    final reading = topikTestFixture(level: TopikLevel.topik1);
    final score = scoreTopikAttempt(reading, {
      for (var no = 31; no <= 70; no++) no: null,
    });
    expect(score.answers.first.questionNo, 31);
    expect(score.answers.last.questionNo, 70);
  });

  test('selections that are not exactly the test questions are an error', () {
    expect(
      () => scoreTopikAttempt(test1, blank()..remove(30)),
      throwsArgumentError,
    );
    expect(
      () => scoreTopikAttempt(test1, blank()..[31] = null),
      throwsArgumentError,
    );
  });
}
```

`test/features/topik/domain/topik_attempt_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';

TopikAttemptAnswer _answer({int? selected, int? correct}) => TopikAttemptAnswer(
  questionNo: 1,
  selectedIdx: selected,
  timeSpentMs: 0,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: correct,
  points: correct == null ? null : 2,
  pointsEarned: correct == null ? null : (selected == correct ? 2 : 0),
  questionType: null,
);

void main() {
  test('status codes round-trip and an unknown code is an error', () {
    for (final status in TopikAttemptStatus.values) {
      expect(TopikAttemptStatus.fromCode(status.code), status);
    }
    expect(TopikAttemptMode.fromCode('practice'), TopikAttemptMode.practice);
    expect(() => TopikAttemptStatus.fromCode('paused'), throwsArgumentError);
    expect(() => TopikAttemptMode.fromCode('exam'), throwsArgumentError);
  });

  test('an answer has no status until its attempt is submitted', () {
    expect(_answer(selected: 2).status, isNull);
  });

  test('a submitted answer is correct, wrong or unanswered', () {
    expect(_answer(selected: 2, correct: 2).status, TopikAnswerStatus.correct);
    expect(_answer(selected: 1, correct: 2).status, TopikAnswerStatus.wrong);
    expect(_answer(correct: 2).status, TopikAnswerStatus.unanswered);
  });
}
```

`test/features/topik/domain/topik_test_status_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

TopikAttempt _attempt(
  String id,
  String testId, {
  int? score,
  required DateTime updatedAt,
}) {
  final completed = score != null;
  return TopikAttempt(
    id: id,
    testId: testId,
    level: TopikLevel.topik2,
    section: TopikSection.reading,
    round: 96,
    mode: TopikAttemptMode.practice,
    status: completed
        ? TopikAttemptStatus.completed
        : TopikAttemptStatus.inProgress,
    startedAt: DateTime.utc(2026, 10, 1),
    completedAt: completed ? updatedAt : null,
    updatedAt: updatedAt,
    totalTimeMs: 0,
    currentQuestionNo: 1,
    questionCount: 50,
    maxScore: 100,
    score: score,
    correctCount: score == null ? null : score ~/ 2,
    answeredCount: completed ? 50 : null,
    contentVersion: 1,
  );
}

// BR-TOPIK-022, spec §6.3.
void main() {
  test('a test without attempts has no status (not started)', () {
    expect(topikTestStatusesOf(const []), isEmpty);
  });

  test('folds the attempts of each test', () {
    final statuses = topikTestStatusesOf([
      _attempt('a1', 'A', score: 60, updatedAt: DateTime.utc(2026, 10, 2)),
      _attempt('a2', 'A', score: 80, updatedAt: DateTime.utc(2026, 10, 3)),
      _attempt('a3', 'A', updatedAt: DateTime.utc(2026, 10, 5)),
      _attempt('b1', 'B', updatedAt: DateTime.utc(2026, 10, 4)),
    ]);

    final a = statuses['A']!;
    expect(a.hasInProgress, isTrue);
    expect(a.completedCount, 2);
    expect(a.bestScore, 80);
    expect(a.lastActivityAt, DateTime.utc(2026, 10, 5));

    final b = statuses['B']!;
    expect(b.hasInProgress, isTrue);
    expect(b.completedCount, 0);
    expect(b.bestScore, isNull);
    expect(b.lastActivityAt, DateTime.utc(2026, 10, 4));
  });
}
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_attempt_score_test.dart test/features/topik/domain/topik_attempt_model_test.dart test/features/topik/domain/topik_test_status_test.dart`
Expected: FAIL — the model files do not exist.

- [ ] **Step 4: Write the models**

In `topik_question_model.dart`, above `final class TopikOption`:

```dart
/// The option numbers of every question, ①–④ (BR-TOPIK-003). The schema's
/// `selected_idx` and `correct_idx` CHECKs copy this range.
const Set<int> topikOptionIdxs = {1, 2, 3, 4};
```

In `topik_content_check_model.dart`: delete `const Set<int> _optionIdxs = {1, 2, 3, 4};` and replace each `_optionIdxs` with `topikOptionIdxs` (it already imports `topik_question_model.dart`).

`lib/features/topik/domain/models/topik_attempt_status_model.dart`:

```dart
/// Where an attempt is in its life (BR-TOPIK-010), stored as a stable text
/// code on `topik_attempt.status`. [completed] is final: the attempt no longer
/// changes.
enum TopikAttemptStatus {
  inProgress('in_progress'),
  completed('completed');

  const TopikAttemptStatus(this.code);

  final String code;

  static TopikAttemptStatus fromCode(String code) {
    for (final status in values) {
      if (status.code == code) return status;
    }
    throw ArgumentError.value(code, 'code', 'unknown TOPIK attempt status');
  }
}

/// How an attempt is taken, stored on `topik_attempt.mode`. Exam mode is
/// Phase B (BR-TOPIK-032) and has no value yet.
enum TopikAttemptMode {
  practice('practice');

  const TopikAttemptMode(this.code);

  final String code;

  static TopikAttemptMode fromCode(String code) {
    for (final mode in values) {
      if (mode.code == code) return mode;
    }
    throw ArgumentError.value(code, 'code', 'unknown TOPIK attempt mode');
  }
}

/// What a submitted answer was (BR-TOPIK-013). Derived from the snapshot,
/// never stored.
enum TopikAnswerStatus { correct, wrong, unanswered }
```

`lib/features/topik/domain/models/topik_attempt_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// One time a person takes one test (BR-TOPIK-010). [completedAt], [score],
/// [correctCount] and [answeredCount] are null exactly while the attempt is
/// in progress (BR-TOPIK-013).
final class TopikAttempt {
  const TopikAttempt({
    required this.id,
    required this.testId,
    required this.level,
    required this.section,
    required this.round,
    required this.mode,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.updatedAt,
    required this.totalTimeMs,
    required this.currentQuestionNo,
    required this.questionCount,
    required this.maxScore,
    required this.score,
    required this.correctCount,
    required this.answeredCount,
    required this.contentVersion,
  });

  final String id;
  final String testId;
  final TopikLevel level;
  final TopikSection section;
  final int round;
  final TopikAttemptMode mode;
  final TopikAttemptStatus status;
  final DateTime startedAt;
  final DateTime? completedAt;

  /// The last write: an answer, a move, a time record or the submit.
  final DateTime updatedAt;

  /// The sum of the answers' time, in milliseconds (BR-TOPIK-015).
  final int totalTimeMs;

  /// The question the attempt shows; time accrues to it (BR-TOPIK-015).
  final int currentQuestionNo;
  final int questionCount;
  final int maxScore;
  final int? score;
  final int? correctCount;
  final int? answeredCount;

  /// The content version the attempt started on, then the one it was scored
  /// on (BR-TOPIK-019).
  final int contentVersion;

  bool get isCompleted => status == TopikAttemptStatus.completed;
}

/// One question of an attempt. [selectedIdx] is the chosen option (1–4) or
/// null (BR-TOPIK-003, BR-TOPIK-012). [correctIdx], [points] and
/// [pointsEarned] are the snapshot taken at submit, null while the attempt is
/// in progress (BR-TOPIK-013). [questionType] is null then too, and also for
/// a type code this build does not know (an attempt synced from a newer app).
final class TopikAttemptAnswer {
  const TopikAttemptAnswer({
    required this.questionNo,
    required this.selectedIdx,
    required this.timeSpentMs,
    required this.answeredAt,
    required this.correctIdx,
    required this.points,
    required this.pointsEarned,
    required this.questionType,
  });

  final int questionNo;
  final int? selectedIdx;
  final int timeSpentMs;
  final DateTime? answeredAt;
  final int? correctIdx;
  final int? points;
  final int? pointsEarned;
  final TopikQuestionType? questionType;

  /// Null while the attempt is in progress: nothing tells right from wrong
  /// before submit (BR-TOPIK-016).
  TopikAnswerStatus? get status {
    final correct = correctIdx;
    if (correct == null) return null;
    if (selectedIdx == null) return TopikAnswerStatus.unanswered;
    return selectedIdx == correct
        ? TopikAnswerStatus.correct
        : TopikAnswerStatus.wrong;
  }
}

/// An attempt with its answers in question order.
final class TopikAttemptDetail {
  const TopikAttemptDetail({required this.attempt, required this.answers});

  final TopikAttempt attempt;
  final List<TopikAttemptAnswer> answers;
}
```

`lib/features/topik/domain/models/topik_attempt_score_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';

/// The snapshot one answer takes at submit (BR-TOPIK-013).
final class TopikAnswerScore {
  const TopikAnswerScore({
    required this.questionNo,
    required this.correctIdx,
    required this.points,
    required this.pointsEarned,
    required this.questionType,
    required this.status,
  });

  final int questionNo;
  final int correctIdx;
  final int points;
  final int pointsEarned;
  final TopikQuestionType questionType;
  final TopikAnswerStatus status;
}

/// An attempt scored against its test (BR-TOPIK-013, spec §5.3).
final class TopikAttemptScore {
  const TopikAttemptScore({
    required this.answers,
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.answeredCount,
  });

  /// One per question, in question order.
  final List<TopikAnswerScore> answers;
  final int score;
  final int maxScore;
  final int correctCount;
  final int answeredCount;

  int get questionCount => answers.length;
}

/// Scores [selections] (question number → chosen option, or null when
/// unanswered) against the current content of [test]: the content at submit
/// is the one that scores (BR-TOPIK-013). The keys must be exactly the
/// question numbers of [test]; the store checks that first and refuses the
/// submit otherwise (BR-TOPIK-019).
TopikAttemptScore scoreTopikAttempt(
  TopikTest test,
  Map<int, int?> selections,
) {
  final numbers = {for (final question in test.questions) question.no};
  if (numbers.length != selections.length ||
      !numbers.containsAll(selections.keys)) {
    throw ArgumentError.value(
      selections.keys.toList(),
      'selections',
      'must be exactly the question numbers of ${test.testId}',
    );
  }
  final questions = [...test.questions]..sort((a, b) => a.no.compareTo(b.no));
  final answers = [
    for (final question in questions)
      _scoreOf(question, selections[question.no]),
  ];
  var score = 0;
  var maxScore = 0;
  var correctCount = 0;
  var answeredCount = 0;
  for (final answer in answers) {
    score += answer.pointsEarned;
    maxScore += answer.points;
    if (answer.status == TopikAnswerStatus.correct) correctCount++;
    if (answer.status != TopikAnswerStatus.unanswered) answeredCount++;
  }
  return TopikAttemptScore(
    answers: answers,
    score: score,
    maxScore: maxScore,
    correctCount: correctCount,
    answeredCount: answeredCount,
  );
}

TopikAnswerScore _scoreOf(TopikQuestion question, int? selected) {
  final status = switch (selected) {
    null => TopikAnswerStatus.unanswered,
    final idx when idx == question.answerIdx => TopikAnswerStatus.correct,
    _ => TopikAnswerStatus.wrong,
  };
  return TopikAnswerScore(
    questionNo: question.no,
    correctIdx: question.answerIdx,
    points: question.points,
    pointsEarned: status == TopikAnswerStatus.correct ? question.points : 0,
    questionType: question.questionType,
    status: status,
  );
}
```

`lib/features/topik/domain/models/topik_test_status_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';

/// What the test list shows of a test the person has attempted
/// (BR-TOPIK-022): in progress, or the best score of its completed attempts
/// and how many there are. A test without attempts has no status: not
/// started.
final class TopikTestStatus {
  const TopikTestStatus({
    required this.testId,
    required this.hasInProgress,
    required this.completedCount,
    required this.bestScore,
    required this.lastActivityAt,
  });

  final String testId;
  final bool hasInProgress;
  final int completedCount;

  /// Null when no attempt is completed.
  final int? bestScore;

  /// The latest `updatedAt` of any attempt, for the "latest activity" sort.
  final DateTime lastActivityAt;
}

/// The status of each test [attempts] belong to, keyed by test id.
Map<String, TopikTestStatus> topikTestStatusesOf(
  Iterable<TopikAttempt> attempts,
) {
  final byTest = <String, List<TopikAttempt>>{};
  for (final attempt in attempts) {
    (byTest[attempt.testId] ??= []).add(attempt);
  }
  return {
    for (final MapEntry(key: testId, value: ofTest) in byTest.entries)
      testId: _statusOf(testId, ofTest),
  };
}

TopikTestStatus _statusOf(String testId, List<TopikAttempt> attempts) {
  var hasInProgress = false;
  var completedCount = 0;
  int? bestScore;
  var lastActivityAt = attempts.first.updatedAt;
  for (final attempt in attempts) {
    if (attempt.updatedAt.isAfter(lastActivityAt)) {
      lastActivityAt = attempt.updatedAt;
    }
    final score = attempt.score;
    if (!attempt.isCompleted || score == null) {
      hasInProgress = true;
      continue;
    }
    completedCount++;
    if (bestScore == null || score > bestScore) bestScore = score;
  }
  return TopikTestStatus(
    testId: testId,
    hasInProgress: hasInProgress,
    completedCount: completedCount,
    bestScore: bestScore,
    lastActivityAt: lastActivityAt,
  );
}
```

`lib/features/topik/domain/failures/topik_failure.dart`:

```dart
/// Why the topik feature refuses an attempt write (ADR-011 D6). A refusal
/// writes nothing.
enum TopikRejection {
  /// The attempt is gone: deleted on another screen, or by an account switch
  /// (BR-TOPIK-018, BR-TOPIK-027).
  notFound,

  /// The test already has an attempt in progress on this device; the person
  /// chooses Continue or Start new (BR-TOPIK-011).
  inProgressExists,

  /// The attempt was submitted and no longer changes (BR-TOPIK-010).
  attemptCompleted,

  /// The question number is not one of the attempt's.
  unknownQuestion,

  /// The option is not one of ①–④ (BR-TOPIK-003).
  invalidOption,

  /// The content given is not the attempt's test, or no longer has the
  /// attempt's questions (BR-TOPIK-019).
  contentMismatch,
}
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain`
Expected: PASS (the new tests and the existing content-check tests).

- [ ] **Step 6: Analyze and commit**

```bash
dart format lib/features/topik test/features/topik test/support/topik_content_fixtures.dart
flutter analyze lib/features/topik test/features/topik test/support
git add lib/features/topik/domain test/features/topik/domain test/support/topik_content_fixtures.dart
git commit -m "<DEV-n> feat(topik): attempt models, scoring and rejections"
```

---

### Task 2: Schema v17 — the attempt tables, their guards and the migration

**Files:**
- Create: `lib/core/database/tables/topik.drift`
- Modify: `lib/core/database/app_database.dart` (include `topik.drift`, `schemaVersion => 17`, `from16To17`)
- Generate: `drift_schemas/drift_schema_v17.json`, `lib/core/database/schema_versions.dart`, `test/drift/generated/schema_v17.dart`, `test/drift/generated/schema.dart`
- Modify: `test/drift/migration_test.dart`, `test/drift/account_migration_test.dart`, `test/drift/interrupted_migration_test.dart`, `test/drift/nfc_migration_test.dart`, `test/drift/outbox_payload_migration_test.dart`, `test/drift/sql_log_switch_migration_test.dart`, `test/drift/sync_seed_migration_test.dart` (target 16 → 17)
- Modify: `test/core/database/schema_constants_parity_test.dart` (TOPIK CHECKs)
- Test: `test/database/topik_schema_test.dart`

**Interfaces:**
- Consumes: `TopikAttemptStatus`, `TopikAttemptMode`, `TopikLevel`, `TopikSection`, `topikOptionIdxs` (Task 1).
- Produces: tables `topik_attempt` (`TopikAttemptRow`, getter `db.topikAttempt`) and `topik_attempt_answer` (`TopikAttemptAnswerRow`, getter `db.topikAttemptAnswer`); indexes `idx_topik_attempt_test_started`, `idx_topik_attempt_one_open`; triggers `topik_attempt_completed_immutable`, `topik_attempt_answer_completed_immutable`; `schemaVersion == 17`.

- [ ] **Step 1: Write the failing schema test**

`test/database/topik_schema_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';

import '../support/test_database.dart';

// TOPIK spec 2026-10-15 §13.1: the attempt tables enforce what BR-TOPIK-010,
// BR-TOPIK-011, BR-TOPIK-012 and BR-TOPIK-013 promise, whatever writes them.

Future<void> _openAttempt(AppDatabase db, String id, {String test = 'T'}) =>
    db.customStatement(
      'INSERT INTO topik_attempt (id, test_id, level, section, round, mode, '
      'status, started_at, updated_at, current_question_no, question_count, '
      "max_score, content_version) VALUES (?, ?, 'topik2', 'reading', 96, "
      "'practice', 'in_progress', 10, 10, 1, 2, 4, 1)",
      [id, test],
    );

Future<void> _answers(AppDatabase db, String attemptId) => db.customStatement(
  'INSERT INTO topik_attempt_answer (attempt_id, question_no) '
  'VALUES (?, 1), (?, 2)',
  [attemptId, attemptId],
);

/// Submits [id] as the store does: answers first, then the attempt.
Future<void> _complete(AppDatabase db, String id) async {
  await db.customStatement(
    'UPDATE topik_attempt_answer SET selected_idx = 1, answered_at = 20 '
    'WHERE attempt_id = ? AND question_no = 1',
    [id],
  );
  await db.customStatement(
    'UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, '
    "points_earned = CASE WHEN selected_idx = 1 THEN 2 ELSE 0 END, "
    "question_type = 'R2_fill_blank' WHERE attempt_id = ?",
    [id],
  );
  await db.customStatement(
    "UPDATE topik_attempt SET status = 'completed', completed_at = 30, "
    'updated_at = 30, score = 2, correct_count = 1, answered_count = 1 '
    'WHERE id = ?',
    [id],
  );
}

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('an attempt in progress takes answers, time and moves', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await db.customStatement(
      'UPDATE topik_attempt_answer SET selected_idx = 3, answered_at = 11, '
      "time_spent_ms = 500 WHERE attempt_id = 'A' AND question_no = 2",
    );
    await db.customStatement(
      'UPDATE topik_attempt SET total_time_ms = 500, current_question_no = 2, '
      "updated_at = 11 WHERE id = 'A'",
    );
    expect(await _count(db, 'topik_attempt_answer'), 2);
  });

  test('a completed attempt refuses a change to any column but '
      'server_version (BR-TOPIK-010)', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await _complete(db, 'A');
    final columns = [
      for (final row in await db
          .customSelect('PRAGMA table_info(topik_attempt)')
          .get())
        row.read<String>('name'),
    ];
    expect(columns, contains('server_version'));
    for (final column in columns.where((c) => c != 'server_version')) {
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt SET "$column" = "$column" WHERE id = ?',
          ['A'],
        ),
        throwsA(anything),
        reason: column,
      );
    }
    await db.customStatement(
      "UPDATE topik_attempt SET server_version = 7 WHERE id = 'A'",
    );
  });

  test('the answers of a completed attempt refuse any change', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await _complete(db, 'A');
    await expectLater(
      db.customStatement(
        'UPDATE topik_attempt_answer SET time_spent_ms = 1 '
        "WHERE attempt_id = 'A' AND question_no = 2",
      ),
      throwsA(anything),
    );
  });

  test('deleting an attempt deletes its answers, in progress or completed '
      '(BR-TOPIK-018)', () async {
    await _openAttempt(db, 'A');
    await _answers(db, 'A');
    await _openAttempt(db, 'B', test: 'U');
    await _answers(db, 'B');
    await _complete(db, 'B');

    await db.customStatement("DELETE FROM topik_attempt WHERE id IN ('A', 'B')");

    expect(await _count(db, 'topik_attempt_answer'), 0);
  });

  test('a test has at most one attempt in progress (BR-TOPIK-011)', () async {
    await _openAttempt(db, 'A');
    await expectLater(_openAttempt(db, 'B'), throwsA(anything));
    await _answers(db, 'A');
    await _complete(db, 'A');
    await _openAttempt(db, 'B');
    await _answers(db, 'B');
    await _complete(db, 'B');
    expect(await _count(db, 'topik_attempt'), 2);
  });

  group('CHECKs refuse', () {
    test('a snapshot on an attempt in progress', () async {
      await expectLater(
        db.customStatement(
          'INSERT INTO topik_attempt (id, test_id, level, section, round, '
          'mode, status, started_at, updated_at, current_question_no, '
          'question_count, max_score, content_version, score) VALUES '
          "('A', 'T', 'topik2', 'reading', 96, 'practice', 'in_progress', 10, "
          '10, 1, 2, 4, 1, 0)',
        ),
        throwsA(anything),
      );
    });

    test('a completed attempt without its snapshot', () async {
      await _openAttempt(db, 'A');
      await expectLater(
        db.customStatement(
          "UPDATE topik_attempt SET status = 'completed' WHERE id = 'A'",
        ),
        throwsA(anything),
      );
    });

    test('a server version on an attempt in progress', () async {
      await _openAttempt(db, 'A');
      await expectLater(
        db.customStatement(
          "UPDATE topik_attempt SET server_version = 1 WHERE id = 'A'",
        ),
        throwsA(anything),
      );
    });

    test('an option outside 1–4', () async {
      await _openAttempt(db, 'A');
      await _answers(db, 'A');
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET selected_idx = 5, answered_at = 1 '
          "WHERE attempt_id = 'A' AND question_no = 1",
        ),
        throwsA(anything),
      );
    });

    test('a choice without its time, or a time without a choice', () async {
      await _openAttempt(db, 'A');
      await _answers(db, 'A');
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET selected_idx = 2 '
          "WHERE attempt_id = 'A' AND question_no = 1",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET answered_at = 1 '
          "WHERE attempt_id = 'A' AND question_no = 1",
        ),
        throwsA(anything),
      );
    });

    test('points earned on a wrong option, or a partial snapshot', () async {
      await _openAttempt(db, 'A');
      await _answers(db, 'A');
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, '
          "points_earned = 2, question_type = 'R2_fill_blank' "
          "WHERE attempt_id = 'A' AND question_no = 2",
        ),
        throwsA(anything),
      );
      await expectLater(
        db.customStatement(
          'UPDATE topik_attempt_answer SET correct_idx = 1 '
          "WHERE attempt_id = 'A' AND question_no = 2",
        ),
        throwsA(anything),
      );
    });

    test('an unknown level, section, mode or status', () async {
      const valid = {
        'level': 'topik2',
        'section': 'reading',
        'mode': 'practice',
        'status': 'in_progress',
      };
      const unknown = {
        'level': 'topik3',
        'section': 'writing',
        'mode': 'exam',
        'status': 'paused',
      };
      for (final column in valid.keys) {
        final codes = {...valid, column: unknown[column]!};
        await expectLater(
          db.customStatement(
            'INSERT INTO topik_attempt (id, test_id, level, section, round, '
            'mode, status, started_at, updated_at, current_question_no, '
            'question_count, max_score, content_version) VALUES '
            "('X', 'T', ?, ?, 96, ?, ?, 10, 10, 1, 2, 4, 1)",
            [codes['level'], codes['section'], codes['mode'], codes['status']],
          ),
          throwsA(anything),
          reason: column,
        );
      }
    });
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/database/topik_schema_test.dart`
Expected: FAIL — `no such table: topik_attempt`.

- [ ] **Step 3: Write the tables**

`lib/core/database/tables/topik.drift`:

```sql
-- TOPIK spec 2026-10-15 §7.1, §13.1 (ADR-023 #6). An attempt is device data
-- while in progress and an immutable, synced record once completed
-- (BR-TOPIK-010, BR-TOPIK-026). The content is not in Drift: test_id names a
-- bundled test (ADR-023 #3), so it has no foreign key.
CREATE TABLE topik_attempt (
  id TEXT NOT NULL PRIMARY KEY,
  test_id TEXT NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('topik1', 'topik2')),
  section TEXT NOT NULL CHECK (section IN ('listening', 'reading')),
  round INTEGER NOT NULL CHECK (round > 0),
  mode TEXT NOT NULL CHECK (mode IN ('practice')),
  status TEXT NOT NULL CHECK (status IN ('in_progress', 'completed')),
  started_at DATETIME NOT NULL,
  completed_at DATETIME,
  updated_at DATETIME NOT NULL,
  total_time_ms INTEGER NOT NULL DEFAULT 0 CHECK (total_time_ms >= 0),
  current_question_no INTEGER NOT NULL,
  question_count INTEGER NOT NULL CHECK (question_count > 0),
  max_score INTEGER NOT NULL CHECK (max_score > 0),
  score INTEGER,
  correct_count INTEGER,
  answered_count INTEGER,
  content_version INTEGER NOT NULL CHECK (content_version > 0),
  server_version INTEGER,
  -- the snapshot exists exactly once the attempt is submitted (BR-TOPIK-013)
  CHECK ((status = 'completed') = (completed_at IS NOT NULL)),
  CHECK ((status = 'completed') = (score IS NOT NULL)),
  CHECK ((status = 'completed') = (correct_count IS NOT NULL)),
  CHECK ((status = 'completed') = (answered_count IS NOT NULL)),
  CHECK (score BETWEEN 0 AND max_score),
  CHECK (answered_count BETWEEN 0 AND question_count),
  CHECK (correct_count BETWEEN 0 AND answered_count),
  -- only a submitted attempt ever reaches the server (BR-TOPIK-026)
  CHECK (status = 'completed' OR server_version IS NULL)
) AS TopikAttemptRow;

-- History and Recent attempts of one test, newest first (BR-TOPIK-021).
CREATE INDEX idx_topik_attempt_test_started ON topik_attempt (test_id, started_at);

-- At most one attempt in progress per test on this device (BR-TOPIK-011),
-- even when two Starts race; it also serves the lookup of that attempt.
CREATE UNIQUE INDEX idx_topik_attempt_one_open ON topik_attempt (test_id)
WHERE status = 'in_progress';

-- One row per question, inserted at Start; choosing and timing are updates
-- (§13.1). The snapshot columns are filled at submit (BR-TOPIK-013).
CREATE TABLE topik_attempt_answer (
  attempt_id TEXT NOT NULL REFERENCES topik_attempt (id) ON DELETE CASCADE,
  question_no INTEGER NOT NULL CHECK (question_no > 0),
  selected_idx INTEGER CHECK (selected_idx BETWEEN 1 AND 4),
  time_spent_ms INTEGER NOT NULL DEFAULT 0 CHECK (time_spent_ms >= 0),
  answered_at DATETIME,
  correct_idx INTEGER CHECK (correct_idx BETWEEN 1 AND 4),
  points INTEGER CHECK (points > 0),
  points_earned INTEGER,
  -- no CHECK: a type added by a newer app must still sync in (§13.1 ruling)
  question_type TEXT,
  -- a chosen option carries the time it was chosen (BR-TOPIK-012)
  CHECK ((selected_idx IS NULL) = (answered_at IS NULL)),
  -- the snapshot is whole or absent, and earns exactly on the right option
  -- (BR-TOPIK-013)
  CHECK ((correct_idx IS NULL) = (points IS NULL)),
  CHECK ((correct_idx IS NULL) = (points_earned IS NULL)),
  CHECK ((correct_idx IS NULL) = (question_type IS NULL)),
  CHECK (points_earned = CASE WHEN selected_idx = correct_idx THEN points ELSE 0 END),
  PRIMARY KEY (attempt_id, question_no)
) AS TopikAttemptAnswerRow;

-- BR-TOPIK-010: a submitted attempt is final, as review_log is append-only.
-- Every column but server_version (the server's acknowledgement) is listed;
-- a column added later must join the list (topik_schema_test checks it).
CREATE TRIGGER topik_attempt_completed_immutable
BEFORE UPDATE OF id, test_id, level, section, round, mode, status, started_at,
  completed_at, updated_at, total_time_ms, current_question_no, question_count,
  max_score, score, correct_count, answered_count, content_version
ON topik_attempt
WHEN OLD.status = 'completed'
BEGIN
  SELECT RAISE(ABORT, 'topik_attempt is immutable once completed');
END;

CREATE TRIGGER topik_attempt_answer_completed_immutable
BEFORE UPDATE ON topik_attempt_answer
WHEN (SELECT status FROM topik_attempt WHERE id = OLD.attempt_id) = 'completed'
BEGIN
  SELECT RAISE(ABORT, 'topik_attempt_answer is immutable once its attempt is completed');
END;
```

- [ ] **Step 4: Wire it into the database and write the step**

In `lib/core/database/app_database.dart`:
- add `'package:memox/core/database/tables/topik.drift',` to `@DriftDatabase(include: {...})` after `account.drift`;
- change `int get schemaVersion => 16;` to `int get schemaVersion => 17;`.

Generate the snapshot and the step helpers (run from the repository root):

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
```

Expected: `drift_schemas/drift_schema_v17.json` and `test/drift/generated/schema_v17.dart` exist; `schema_versions.dart` declares `from16To17`.

Add the step after `from15To16` in the `migrationSteps(...)` call:

```dart
    from16To17: (m, schema) async {
      // TOPIK spec 2026-10-15 §13.1: the attempt tables, their indexes and
      // the triggers that keep a submitted attempt final. New tables: no row
      // changes, no outbox seed.
      await m.createTable(schema.topikAttempt);
      await m.createTable(schema.topikAttemptAnswer);
      await m.createIndex(schema.idxTopikAttemptTestStarted);
      await m.createIndex(schema.idxTopikAttemptOneOpen);
      await m.createTrigger(schema.topikAttemptCompletedImmutable);
      await m.createTrigger(schema.topikAttemptAnswerCompletedImmutable);
    },
```

Run `dart run build_runner build --delete-conflicting-outputs` again.

- [ ] **Step 5: Move every migration target to v17 and add the v16 test**

```bash
rg -l "migrateAndValidate\(db, 16\)" test/drift
```

Expected list: `migration_test.dart`, `account_migration_test.dart`, `interrupted_migration_test.dart`, `nfc_migration_test.dart`, `outbox_payload_migration_test.dart`, `sql_log_switch_migration_test.dart`, `sync_seed_migration_test.dart`. In each, replace `migrateAndValidate(db, 16)` with `migrateAndValidate(db, 17)`, and in `migration_test.dart` replace `the schema of v16` with `the schema of v17` in every test title (the `v15 → v16` title stays `v15 upgrades to the schema of v17 (study speech spec §4)`; its body keeps checking the v16 columns). Also add `v17 adds the TOPIK attempt tables (TOPIK spec §13.1)` to the header comment's version list.

Add after the v15 test in `migration_test.dart`:

```dart
  test('v16 upgrades to the schema of v17 (TOPIK spec §13.1)', () async {
    final schema = await verifier.schemaAt(16);
    schema.rawDatabase.execute(
      "INSERT INTO deck (id, name, parent_id, root_id, depth, content_type, "
      "scheduler_type, scheduler_version, generation, sibling_position, "
      "created_at, updated_at) VALUES ('R', 'r', NULL, 'R', 1, 'deck', "
      "'eight_box', 1, 1, 0, 0, 0)",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, 17);

    expect(await db.select(db.topikAttempt).get(), isEmpty);
    expect(await db.select(db.topikAttemptAnswer).get(), isEmpty);
    expect(await db.select(db.deck).get(), hasLength(1));
    final queued = await db
        .customSelect(
          "SELECT COUNT(*) AS n FROM sync_outbox WHERE entity_type = 'topik_attempt'",
        )
        .getSingle();
    expect(queued.read<int>('n'), 0);
  });
```

In `interrupted_migration_test.dart`, any expectation on the latest version's object list that now gains the TOPIK tables or triggers is updated to include them (run it first; change only expectations that list v17 objects).

- [ ] **Step 6: Pin the CHECKs to the Dart constants**

In `test/core/database/schema_constants_parity_test.dart`, add the imports:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
```

and inside `group('Drift CHECKs', ...)`:

```dart
    test('topik_attempt stores every TopikLevel, TopikSection, '
        'TopikAttemptMode and TopikAttemptStatus code and no other', () {
      final sql = tableSql['topik_attempt']!;
      expect(
        codesOf(sql, r'"level" TEXT NOT NULL CHECK \(level IN \(([^)]*)\)'),
        {for (final level in TopikLevel.values) level.code},
      );
      expect(
        codesOf(sql, r'"section" TEXT NOT NULL CHECK \(section IN \(([^)]*)\)'),
        {for (final section in TopikSection.values) section.code},
      );
      expect(
        codesOf(sql, r'"mode" TEXT NOT NULL CHECK \(mode IN \(([^)]*)\)'),
        {for (final mode in TopikAttemptMode.values) mode.code},
      );
      expect(
        codesOf(sql, r'"status" TEXT NOT NULL CHECK \(status IN \(([^)]*)\)'),
        {for (final status in TopikAttemptStatus.values) status.code},
      );
    });

    test('topik_attempt_answer options are topikOptionIdxs (BR-TOPIK-003)', () {
      final sql = tableSql['topik_attempt_answer']!;
      final range = {
        for (var idx = 1; idx <= topikOptionIdxs.length; idx++) idx,
      };
      expect(topikOptionIdxs, range);
      expect(
        literalOf(sql, r'selected_idx BETWEEN 1 AND (\d+)'),
        topikOptionIdxs.length,
      );
      expect(
        literalOf(sql, r'correct_idx BETWEEN 1 AND (\d+)'),
        topikOptionIdxs.length,
      );
    });
```

If `codesOf` finds no match because Drift renders the column definition differently, print `tableSql['topik_attempt']` once and align the pattern with the rendered text (the same form the `study_session` patterns use).

- [ ] **Step 7: Run the database and migration tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/database test/drift test/core/database`
Expected: PASS, including `a snapshot exists for the current schema version` (schema_test) and every `vN upgrades to the schema of v17`.

- [ ] **Step 8: Run the Drift review script and commit**

```bash
bash .claude/skills/flutter-drift/scripts/check_drift.sh --diff
dart format lib/core/database test/database test/drift test/core/database
git add lib/core/database drift_schemas test/drift test/database/topik_schema_test.dart test/core/database/schema_constants_parity_test.dart
git commit -m "<DEV-n> feat(db): schema v17 with the TOPIK attempt tables"
```

Expected from `check_drift.sh`: no `ERROR`.

---

### Task 3: Capture triggers for submitted attempts

**Files:**
- Modify: `lib/core/database/tables/sync.drift` (import `topik.drift`, two triggers)
- Modify: `lib/core/database/app_database.dart` (`from16To17` creates them)
- Regenerate: `drift_schemas/drift_schema_v17.json`, `test/drift/generated/schema_v17.dart`, `lib/core/database/schema_versions.dart`
- Test: `test/database/topik_sync_trigger_test.dart`

**Interfaces:**
- Consumes: the v17 tables (Task 2); `syncApplyingRemoteKey` (`lib/core/database/tables/sync_keys.dart`).
- Produces: triggers `topik_attempt_sync_complete` (upsert on `in_progress → completed`) and `topik_attempt_sync_delete` (delete of a completed attempt); entity type `topik_attempt`, consumed by plan 3's adapter.

- [ ] **Step 1: Write the failing test**

`test/database/topik_sync_trigger_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/tables/sync_keys.dart';

import '../support/test_database.dart';

// TOPIK spec 2026-10-15 §7.2, §13.2, BR-TOPIK-026: only a submitted attempt
// reaches the outbox, as one upsert carrying the attempt id; deleting it
// queues a final delete. An attempt in progress and its answers never do.

Future<void> _open(AppDatabase db, String id) async {
  await db.customStatement(
    'INSERT INTO topik_attempt (id, test_id, level, section, round, mode, '
    'status, started_at, updated_at, current_question_no, question_count, '
    "max_score, content_version) VALUES (?, 'T-$id', 'topik2', 'reading', 96, "
    "'practice', 'in_progress', 10, 10, 1, 1, 2, 1)",
    [id],
  );
  await db.customStatement(
    'INSERT INTO topik_attempt_answer (attempt_id, question_no) VALUES (?, 1)',
    [id],
  );
}

Future<void> _submit(AppDatabase db, String id) async {
  await db.customStatement(
    'UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, '
    "points_earned = 0, question_type = 'R2_fill_blank' WHERE attempt_id = ?",
    [id],
  );
  await db.customStatement(
    "UPDATE topik_attempt SET status = 'completed', completed_at = 30, "
    'updated_at = 30, score = 0, correct_count = 0, answered_count = 0 '
    'WHERE id = ?',
    [id],
  );
}

Future<List<(String, String, String)>> _outbox(AppDatabase db) async => [
  for (final row in await db
      .customSelect(
        'SELECT entity_type, entity_id, op FROM sync_outbox ORDER BY entity_id',
      )
      .get())
    (
      row.read<String>('entity_type'),
      row.read<String>('entity_id'),
      row.read<String>('op'),
    ),
];

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  test('an attempt in progress queues nothing, whatever is written', () async {
    await _open(db, 'A');
    await db.customStatement(
      'UPDATE topik_attempt_answer SET selected_idx = 2, answered_at = 11, '
      "time_spent_ms = 900 WHERE attempt_id = 'A'",
    );
    await db.customStatement(
      "UPDATE topik_attempt SET total_time_ms = 900, updated_at = 11 WHERE id = 'A'",
    );
    await db.customStatement("DELETE FROM topik_attempt WHERE id = 'A'");
    expect(await _outbox(db), isEmpty);
  });

  test('submit queues one upsert of the attempt', () async {
    await _open(db, 'A');
    await _submit(db, 'A');
    expect(await _outbox(db), [('topik_attempt', 'A', 'upsert')]);
  });

  test("the server's acknowledgement queues nothing more", () async {
    await _open(db, 'A');
    await _submit(db, 'A');
    await db.customStatement('DELETE FROM sync_outbox');
    await db.customStatement(
      "UPDATE topik_attempt SET server_version = 4 WHERE id = 'A'",
    );
    expect(await _outbox(db), isEmpty);
  });

  test('deleting a submitted attempt queues its delete, replacing a pending '
      'upsert (BR-TOPIK-018)', () async {
    await _open(db, 'A');
    await _submit(db, 'A');
    await db.customStatement("DELETE FROM topik_attempt WHERE id = 'A'");
    expect(await _outbox(db), [('topik_attempt', 'A', 'delete')]);
  });

  test('rows applied from the server queue nothing', () async {
    await db.customStatement(
      'INSERT INTO sync_state (name, value) VALUES (?, ?)',
      [syncApplyingRemoteKey, '1'],
    );
    await _open(db, 'A');
    await _submit(db, 'A');
    await db.customStatement("DELETE FROM topik_attempt WHERE id = 'A'");
    expect(await _outbox(db), isEmpty);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/database/topik_sync_trigger_test.dart`
Expected: FAIL in `submit queues one upsert of the attempt` and `deleting a submitted attempt…` (outbox empty).

- [ ] **Step 3: Write the triggers**

In `lib/core/database/tables/sync.drift`, add `import 'topik.drift';` after `import 'tags.drift';`, and append after `card_schedule_sync_update` (before the `sync_rejection` comment):

```sql
-- TOPIK spec 2026-10-15 §7.2, §13.2 (BR-TOPIK-026): only a submitted attempt
-- syncs. Submit (in_progress → completed) queues an upsert in the submit's own
-- transaction; deleting a submitted attempt queues a final delete. A local
-- insert is always in progress and the answers travel inside the attempt's
-- row, so neither has a trigger: an attempt in progress never reaches the
-- outbox. The adapter is registered by plan 3; until then the coordinator's
-- push reads only registered types and leaves these rows queued.
CREATE TRIGGER topik_attempt_sync_complete AFTER UPDATE OF status ON topik_attempt
WHEN (SELECT value FROM sync_state WHERE name = 'applying_remote') IS NULL
  AND old.status = 'in_progress' AND new.status = 'completed'
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'topik_attempt', new.id, 'upsert', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;

CREATE TRIGGER topik_attempt_sync_delete AFTER DELETE ON topik_attempt
WHEN (SELECT value FROM sync_state WHERE name = 'applying_remote') IS NULL
  AND old.status = 'completed'
BEGIN
  INSERT INTO sync_outbox (op_id, entity_type, entity_id, op, created_at)
  VALUES (lower(hex(randomblob(4)) || '-' || hex(randomblob(2)) || '-4' || substr(hex(randomblob(2)), 2) || '-' || substr('89ab', 1 + (abs(random()) % 4), 1) || substr(hex(randomblob(2)), 2) || '-' || hex(randomblob(6))),
          'topik_attempt', old.id, 'delete', CAST(strftime('%s', 'now') AS INTEGER))
  ON CONFLICT (entity_type, entity_id) DO UPDATE SET op_id = excluded.op_id, op = excluded.op;
END;
```

In `from16To17`, append after the two immutability triggers and extend its comment with "and the capture triggers of §13.2":

```dart
      await m.createTrigger(schema.topikAttemptSyncComplete);
      await m.createTrigger(schema.topikAttemptSyncDelete);
```

- [ ] **Step 4: Regenerate the v17 snapshot and helpers**

```bash
dart run build_runner build --delete-conflicting-outputs
dart run drift_dev schema dump lib/core/database/app_database.dart drift_schemas/
dart run drift_dev schema steps drift_schemas/ lib/core/database/schema_versions.dart
dart run drift_dev schema generate drift_schemas/ test/drift/generated/
dart run build_runner build --delete-conflicting-outputs
```

(The v17 snapshot is not on `master` yet, so regenerating it is allowed.)

- [ ] **Step 5: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/database test/drift test/core/sync`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
dart format lib/core/database test/database
git add lib/core/database drift_schemas test/drift test/database/topik_sync_trigger_test.dart
git commit -m "<DEV-n> feat(db): queue submitted TOPIK attempts for sync"
```

---

### Task 4: The attempt repository — contract, DAO, writes

**Files:**
- Create: `lib/core/database/queries/topik_queries.drift`
- Create: `lib/features/topik/data/datasources/topik_attempt_dao.dart`
- Create: `lib/features/topik/data/mappers/topik_attempt_mapper.dart`
- Create: `lib/features/topik/domain/repositories/topik_attempt_repository.dart`
- Create: `lib/features/topik/data/repositories/topik_attempt_repository_impl.dart`
- Test: `test/features/topik/data/topik_attempt_repository_writes_test.dart`

**Interfaces:**
- Consumes: Task 1 models, `scoreTopikAttempt`, `TopikRejection`, `topikOptionIdxs`; Task 2/3 tables; `Outcome`/`Ok`/`Rejected` (`package:memox/core/error/outcome.dart`); `mappedTransaction` (`package:memox/core/database/mapped_transaction.dart`); `newId()` (`package:memox/core/id/new_id.dart`); `tableChanges` (`package:memox/core/database/table_changes.dart`).
- Produces (`TopikAttemptRepository`):
  - `Future<Outcome<TopikAttempt, TopikRejection>> start(TopikTest test, {DateTime? now})`
  - `Future<TopikAttempt> replaceInProgressAndStart(TopikTest test, {DateTime? now})`
  - `Future<Outcome<void, TopikRejection>> answer({required String attemptId, required int questionNo, required int selectedIdx, required int elapsedMs, DateTime? now})`
  - `Future<Outcome<void, TopikRejection>> move({required String attemptId, required int toQuestionNo, required int elapsedMs, DateTime? now})`
  - `Future<Outcome<void, TopikRejection>> recordTime({required String attemptId, required int elapsedMs, DateTime? now})`
  - `Future<Outcome<TopikAttempt, TopikRejection>> submit({required String attemptId, required TopikTest test, required int elapsedMs, DateTime? now})`
  - `Future<Outcome<void, TopikRejection>> delete(String attemptId)`
  - reads, implemented in Task 5: `Stream<List<TopikAttempt>> watchAttemptsOfTest(String testId)`, `Stream<TopikAttemptDetail?> watchAttempt(String attemptId)`, `Stream<Map<String, TopikTestStatus>> watchTestStatuses()`
  - `TopikAttemptRepositoryImpl(AppDatabase db, {DateTime Function()? now})`
  - mapper: `TopikAttempt topikAttemptOf(TopikAttemptRow row)`, `TopikAttemptAnswer topikAttemptAnswerOf(TopikAttemptAnswerRow row)`

Time rule (ruling R5): `elapsedMs` is the time since the last write, and the store adds it to the attempt's **stored** current question before anything else, then (for `answer` and `move`) makes the target question current. A negative `elapsedMs` throws `ArgumentError` (a programming error, not a refusal).

- [ ] **Step 1: Write the failing test**

`test/features/topik/data/topik_attempt_repository_writes_test.dart`:

```dart
import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_content_fixtures.dart';

// TOPIK spec §5.1–§5.4, §13.5. Fixture: TOPIK I listening, questions 1–30,
// 1–10 worth 4 and 11–30 worth 3; the answer of question n is (n - 1) % 4 + 1.
final _test = topikTestFixture(
  level: TopikLevel.topik1,
  section: TopikSection.listening,
);
final _t0 = DateTime.utc(2026, 10, 15, 9);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

T _ok<T>(Outcome<T, TopikRejection> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('rejected: $reason'),
};

TopikRejection _reason(Outcome<Object?, TopikRejection> outcome) =>
    switch (outcome) {
      Ok() => fail('expected a rejection'),
      Rejected(:final reason) => reason,
    };

Future<List<TopikAttemptAnswerRow>> _answers(AppDatabase db, String id) =>
    (db.select(db.topikAttemptAnswer)
          ..where((a) => a.attemptId.equals(id))
          ..orderBy([(a) => OrderingTerm(expression: a.questionNo)]))
        .get();

Future<TopikAttemptRow?> _row(AppDatabase db, String id) =>
    (db.select(db.topikAttempt)..where((a) => a.id.equals(id)))
        .getSingleOrNull();

void main() {
  late AppDatabase db;
  late TopikAttemptRepositoryImpl repository;
  setUp(() {
    db = openTestDatabase();
    repository = TopikAttemptRepositoryImpl(db, now: () => _t0);
  });
  tearDown(() => db.close());

  group('start', () {
    test('creates an attempt in progress with one blank answer per question '
        '(BR-TOPIK-010)', () async {
      final attempt = _ok(await repository.start(_test, now: _t0));

      expect(attempt.status, TopikAttemptStatus.inProgress);
      expect(attempt.testId, _test.testId);
      expect(attempt.level, TopikLevel.topik1);
      expect(attempt.section, TopikSection.listening);
      expect(attempt.round, 96);
      expect(attempt.mode, TopikAttemptMode.practice);
      expect(attempt.currentQuestionNo, 1);
      expect(attempt.questionCount, 30);
      expect(attempt.maxScore, 100);
      expect(attempt.totalTimeMs, 0);
      expect(attempt.score, isNull);
      expect(attempt.contentVersion, 1);
      expect(attempt.startedAt.isAtSameMomentAs(_t0), isTrue);
      final answers = await _answers(db, attempt.id);
      expect(answers.map((a) => a.questionNo), [for (var n = 1; n <= 30; n++) n]);
      expect(answers.every((a) => a.selectedIdx == null), isTrue);
      expect(answers.every((a) => a.timeSpentMs == 0), isTrue);
    });

    test('refuses a second attempt in progress of the same test '
        '(BR-TOPIK-011)', () async {
      _ok(await repository.start(_test));
      expect(_reason(await repository.start(_test)), TopikRejection.inProgressExists);
      expect(await db.select(db.topikAttempt).get(), hasLength(1));
    });

    test('Start new replaces the attempt in progress in one transaction '
        '(BR-TOPIK-011)', () async {
      final old = _ok(await repository.start(_test));
      _ok(await repository.answer(attemptId: old.id, questionNo: 1, selectedIdx: 2, elapsedMs: 0));

      final fresh = await repository.replaceInProgressAndStart(_test);

      expect(fresh.id, isNot(old.id));
      expect(await _row(db, old.id), isNull);
      expect(await _answers(db, old.id), isEmpty);
      expect(await _answers(db, fresh.id), hasLength(30));
    });

    test('Start new keeps the completed attempts', () async {
      final done = _ok(await repository.start(_test));
      _ok(await repository.submit(attemptId: done.id, test: _test, elapsedMs: 0));

      await repository.replaceInProgressAndStart(_test);

      expect(await db.select(db.topikAttempt).get(), hasLength(2));
    });
  });

  group('answer', () {
    test('saves the choice, replacing the old one, and its time '
        '(BR-TOPIK-012)', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 2, elapsedMs: 4000, now: _at(4)));
      _ok(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 4, elapsedMs: 1000, now: _at(5)));

      final first = (await _answers(db, attempt.id)).first;
      expect(first.selectedIdx, 4);
      expect(first.answeredAt!.isAtSameMomentAs(_at(5)), isTrue);
      expect(first.timeSpentMs, 5000);
      final row = (await _row(db, attempt.id))!;
      expect(row.totalTimeMs, 5000);
      expect(row.updatedAt.isAtSameMomentAs(_at(5)), isTrue);
    });

    test('refuses an option outside 1–4, an unknown question, a submitted '
        'or a deleted attempt, and writes nothing', () async {
      final attempt = _ok(await repository.start(_test));
      expect(
        _reason(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 5, elapsedMs: 10)),
        TopikRejection.invalidOption,
      );
      expect(
        _reason(await repository.answer(attemptId: attempt.id, questionNo: 31, selectedIdx: 1, elapsedMs: 10)),
        TopikRejection.unknownQuestion,
      );
      expect((await _row(db, attempt.id))!.totalTimeMs, 0);

      _ok(await repository.submit(attemptId: attempt.id, test: _test, elapsedMs: 0));
      expect(
        _reason(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 1, elapsedMs: 0)),
        TopikRejection.attemptCompleted,
      );

      expect(
        _reason(await repository.answer(attemptId: 'gone', questionNo: 1, selectedIdx: 1, elapsedMs: 0)),
        TopikRejection.notFound,
      );
    });

    test('negative elapsed time is a programming error', () async {
      final attempt = _ok(await repository.start(_test));
      await expectLater(
        repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 1, elapsedMs: -1),
        throwsArgumentError,
      );
    });
  });

  group('time (BR-TOPIK-015)', () {
    test('accrues to the question that was current, and adds up on return',
        () async {
      final attempt = _ok(await repository.start(_test));
      // 40 s on question 5 (reached by a move), 20 s on 6, back to 5 for 10 s.
      _ok(await repository.move(attemptId: attempt.id, toQuestionNo: 5, elapsedMs: 0));
      _ok(await repository.move(attemptId: attempt.id, toQuestionNo: 6, elapsedMs: 40000));
      _ok(await repository.move(attemptId: attempt.id, toQuestionNo: 5, elapsedMs: 20000));
      _ok(await repository.recordTime(attemptId: attempt.id, elapsedMs: 10000));

      final answers = {for (final a in await _answers(db, attempt.id)) a.questionNo: a};
      expect(answers[5]!.timeSpentMs, 50000);
      expect(answers[6]!.timeSpentMs, 20000);
      final row = (await _row(db, attempt.id))!;
      expect(row.totalTimeMs, 70000);
      expect(row.currentQuestionNo, 5);
    });

    test('move refuses an unknown question and writes nothing', () async {
      final attempt = _ok(await repository.start(_test));
      expect(
        _reason(await repository.move(attemptId: attempt.id, toQuestionNo: 99, elapsedMs: 500)),
        TopikRejection.unknownQuestion,
      );
      expect((await _row(db, attempt.id))!.totalTimeMs, 0);
    });
  });

  group('submit (BR-TOPIK-013)', () {
    test('scores against the content and snapshots every answer', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 1, elapsedMs: 1000));
      _ok(await repository.answer(attemptId: attempt.id, questionNo: 2, selectedIdx: 1, elapsedMs: 1000));
      _ok(await repository.answer(attemptId: attempt.id, questionNo: 11, selectedIdx: 3, elapsedMs: 1000));

      final done = _ok(
        await repository.submit(attemptId: attempt.id, test: _test, elapsedMs: 2000, now: _at(60)),
      );

      expect(done.status, TopikAttemptStatus.completed);
      expect(done.score, 7);
      expect(done.maxScore, 100);
      expect(done.correctCount, 2);
      expect(done.answeredCount, 3);
      expect(done.questionCount, 30);
      expect(done.totalTimeMs, 5000);
      expect(done.completedAt!.isAtSameMomentAs(_at(60)), isTrue);
      final answers = {for (final a in await _answers(db, attempt.id)) a.questionNo: a};
      expect(answers[1]!.pointsEarned, 4);
      expect(answers[2]!.pointsEarned, 0);
      expect(answers[2]!.correctIdx, 2);
      expect(answers[3]!.pointsEarned, 0);
      expect(answers[3]!.points, 4);
      expect(answers[11]!.questionType, 'L1_topic');
      // 1 s each on questions 1, 1 and 2 before each choice moved on, then
      // the 2 s before submit on question 11.
      expect(answers[1]!.timeSpentMs, 2000);
      expect(answers[2]!.timeSpentMs, 1000);
      expect(answers[11]!.timeSpentMs, 2000);
    });

    test('queues the attempt for sync in the same transaction '
        '(BR-TOPIK-026)', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.submit(attemptId: attempt.id, test: _test, elapsedMs: 0));
      final queued = await db.customSelect(
        "SELECT entity_id, op FROM sync_outbox WHERE entity_type = 'topik_attempt'",
      ).get();
      expect(queued.single.read<String>('entity_id'), attempt.id);
      expect(queued.single.read<String>('op'), 'upsert');
    });

    test('a second submit is refused and changes nothing (BR-TOPIK-014)',
        () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.submit(attemptId: attempt.id, test: _test, elapsedMs: 0, now: _at(10)));
      expect(
        _reason(await repository.submit(attemptId: attempt.id, test: _test, elapsedMs: 900, now: _at(20))),
        TopikRejection.attemptCompleted,
      );
      final row = (await _row(db, attempt.id))!;
      expect(row.completedAt!.isAtSameMomentAs(_at(10)), isTrue);
      expect(row.totalTimeMs, 0);
    });

    test('refuses content that is not the attempt\'s test and writes nothing '
        '(BR-TOPIK-019)', () async {
      final attempt = _ok(await repository.start(_test));
      final other = topikTestFixture(level: TopikLevel.topik1);
      expect(
        _reason(await repository.submit(attemptId: attempt.id, test: other, elapsedMs: 100)),
        TopikRejection.contentMismatch,
      );
      final row = (await _row(db, attempt.id))!;
      expect(row.status, 'in_progress');
      expect(row.totalTimeMs, 0);
    });

    test('a content correction made before submit is the one that scores',
        () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 2, elapsedMs: 0));
      final json = topikTestJson(level: TopikLevel.topik1, section: TopikSection.listening);
      questionJson(json, 1)['answerIdx'] = 2;
      json['contentVersion'] = 2;
      final corrected = topikTestOfFixtureJson(json);

      final done = _ok(await repository.submit(attemptId: attempt.id, test: corrected, elapsedMs: 0));

      expect(done.score, 4);
      expect(done.contentVersion, 2);
    });
  });

  group('delete (BR-TOPIK-018)', () {
    test('removes the attempt and its answers', () async {
      final attempt = _ok(await repository.start(_test));
      _ok(await repository.delete(attempt.id));
      expect(await _row(db, attempt.id), isNull);
      expect(await _answers(db, attempt.id), isEmpty);
      expect(_reason(await repository.delete(attempt.id)), TopikRejection.notFound);
    });

    test('every write to an attempt that is gone is notFound and writes '
        'nothing (BR-TOPIK-018, BR-TOPIK-027)', () async {
      expect(
        _reason(await repository.move(attemptId: 'gone', toQuestionNo: 1, elapsedMs: 0)),
        TopikRejection.notFound,
      );
      expect(
        _reason(await repository.recordTime(attemptId: 'gone', elapsedMs: 0)),
        TopikRejection.notFound,
      );
      expect(
        _reason(await repository.submit(attemptId: 'gone', test: _test, elapsedMs: 0)),
        TopikRejection.notFound,
      );
      expect(await db.select(db.topikAttempt).get(), isEmpty);
      expect(await db.select(db.syncOutbox).get(), isEmpty);
    });
  });
}
```

Add to `test/support/topik_content_fixtures.dart` (used by the content-correction test):

```dart
/// [json] (a [topikTestJson] broken or corrected in place) read into a
/// [TopikTest]; fails the test when it does not read.
TopikTest topikTestOfFixtureJson(Map<String, Object?> json) =>
    topikTestOf(json).test!;
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_attempt_repository_writes_test.dart`
Expected: FAIL — `topik_attempt_repository_impl.dart` does not exist.

- [ ] **Step 3: Write the queries**

`lib/core/database/queries/topik_queries.drift`:

```sql
import '../tables/topik.drift';

-- Rows of topik_attempt and topik_attempt_answer (TOPIK spec 2026-10-15
-- §13.1). Writes run inside the repository's transaction.

-- The attempt :id, or none.
topikAttemptById(:id AS TEXT):
SELECT * FROM topik_attempt WHERE id = :id;

-- The attempt of :test_id in progress on this device, or none (BR-TOPIK-011;
-- idx_topik_attempt_one_open).
openTopikAttemptOfTest(:test_id AS TEXT):
SELECT * FROM topik_attempt WHERE test_id = :test_id AND status = 'in_progress';

-- Every attempt of :test_id, newest first; the id (UUID v7) breaks a tie
-- inside one second (BR-TOPIK-021; idx_topik_attempt_test_started).
topikAttemptsOfTest(:test_id AS TEXT):
SELECT * FROM topik_attempt WHERE test_id = :test_id
ORDER BY started_at DESC, id DESC;

-- Every attempt on this device, for the test list (BR-TOPIK-022).
allTopikAttempts:
SELECT * FROM topik_attempt ORDER BY test_id, started_at DESC, id DESC;

-- The answers of :attempt_id in question order.
topikAnswersOfAttempt(:attempt_id AS TEXT):
SELECT * FROM topik_attempt_answer WHERE attempt_id = :attempt_id
ORDER BY question_no;

insertTopikAttempt(:id AS TEXT, :test_id AS TEXT, :level AS TEXT,
  :section AS TEXT, :round AS INTEGER, :mode AS TEXT, :started_at AS DATETIME,
  :current_question_no AS INTEGER, :question_count AS INTEGER,
  :max_score AS INTEGER, :content_version AS INTEGER):
INSERT INTO topik_attempt (id, test_id, level, section, round, mode, status,
  started_at, updated_at, total_time_ms, current_question_no, question_count,
  max_score, content_version)
VALUES (:id, :test_id, :level, :section, :round, :mode, 'in_progress',
  :started_at, :started_at, 0, :current_question_no, :question_count,
  :max_score, :content_version);

insertTopikAnswer(:attempt_id AS TEXT, :question_no AS INTEGER):
INSERT INTO topik_attempt_answer (attempt_id, question_no)
VALUES (:attempt_id, :question_no);

-- Adds :elapsed_ms to question :question_no (BR-TOPIK-015).
addTopikAnswerTime(:attempt_id AS TEXT, :question_no AS INTEGER,
  :elapsed_ms AS INTEGER):
UPDATE topik_attempt_answer SET time_spent_ms = time_spent_ms + :elapsed_ms
WHERE attempt_id = :attempt_id AND question_no = :question_no;

-- Adds :elapsed_ms to the total and makes :question_no current
-- (BR-TOPIK-015).
advanceTopikAttempt(:id AS TEXT, :elapsed_ms AS INTEGER,
  :question_no AS INTEGER, :updated_at AS DATETIME):
UPDATE topik_attempt SET total_time_ms = total_time_ms + :elapsed_ms,
  current_question_no = :question_no, updated_at = :updated_at
WHERE id = :id;

-- The new choice replaces the old one (BR-TOPIK-012).
chooseTopikAnswer(:attempt_id AS TEXT, :question_no AS INTEGER,
  :selected_idx AS INTEGER, :answered_at AS DATETIME):
UPDATE topik_attempt_answer SET selected_idx = :selected_idx,
  answered_at = :answered_at
WHERE attempt_id = :attempt_id AND question_no = :question_no;

-- The submit snapshot of one answer (BR-TOPIK-013).
snapshotTopikAnswer(:attempt_id AS TEXT, :question_no AS INTEGER,
  :correct_idx AS INTEGER, :points AS INTEGER, :points_earned AS INTEGER,
  :question_type AS TEXT):
UPDATE topik_attempt_answer SET correct_idx = :correct_idx, points = :points,
  points_earned = :points_earned, question_type = :question_type
WHERE attempt_id = :attempt_id AND question_no = :question_no;

-- Submit: the attempt becomes completed with its snapshot (BR-TOPIK-013);
-- topik_attempt_sync_complete queues it in this transaction (BR-TOPIK-026).
completeTopikAttempt(:id AS TEXT, :completed_at AS DATETIME,
  :score AS INTEGER, :max_score AS INTEGER, :correct_count AS INTEGER,
  :answered_count AS INTEGER, :question_count AS INTEGER,
  :content_version AS INTEGER):
UPDATE topik_attempt SET status = 'completed', completed_at = :completed_at,
  updated_at = :completed_at, score = :score, max_score = :max_score,
  correct_count = :correct_count, answered_count = :answered_count,
  question_count = :question_count, content_version = :content_version
WHERE id = :id;

-- The answers go by cascade (BR-TOPIK-018).
deleteTopikAttempt(:id AS TEXT):
DELETE FROM topik_attempt WHERE id = :id;
```

- [ ] **Step 4: Write the DAO and the mapper**

`lib/features/topik/data/datasources/topik_attempt_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';

part 'topik_attempt_dao.g.dart';

/// Row access for `topik_attempt` and `topik_attempt_answer`
/// (`topik_queries.drift`). It returns Drift rows, never domain values, and
/// runs inside the caller's transaction.
@DriftAccessor(
  include: {'package:memox/core/database/queries/topik_queries.drift'},
)
final class TopikAttemptDao extends DatabaseAccessor<AppDatabase>
    with _$TopikAttemptDaoMixin {
  TopikAttemptDao(super.attachedDatabase);

  Future<TopikAttemptRow?> attemptRow(String id) =>
      topikAttemptById(id).getSingleOrNull();

  Future<TopikAttemptRow?> openAttemptOf(String testId) =>
      openTopikAttemptOfTest(testId).getSingleOrNull();

  Future<List<TopikAttemptAnswerRow>> answerRows(String attemptId) =>
      topikAnswersOfAttempt(attemptId).get();

  Stream<List<TopikAttemptRow>> watchAttemptRowsOf(String testId) =>
      topikAttemptsOfTest(testId).watch();

  Stream<List<TopikAttemptRow>> watchAllAttemptRows() =>
      allTopikAttempts().watch();

  /// Fires once, then after every write to an attempt or an answer.
  Stream<void> attemptChanges() => tableChanges(attachedDatabase, [
    attachedDatabase.topikAttempt,
    attachedDatabase.topikAttemptAnswer,
  ]);

  Future<void> insertAttempt({
    required String id,
    required String testId,
    required String level,
    required String section,
    required int round,
    required String mode,
    required DateTime startedAt,
    required int currentQuestionNo,
    required int questionCount,
    required int maxScore,
    required int contentVersion,
  }) => insertTopikAttempt(
    id,
    testId,
    level,
    section,
    round,
    mode,
    startedAt,
    currentQuestionNo,
    questionCount,
    maxScore,
    contentVersion,
  );

  Future<void> insertAnswer(String attemptId, int questionNo) =>
      insertTopikAnswer(attemptId, questionNo);

  /// Adds [elapsedMs] to [questionNo] and to the total, and makes [toQuestionNo]
  /// current.
  Future<void> addTime({
    required String attemptId,
    required int questionNo,
    required int elapsedMs,
    required int toQuestionNo,
    required DateTime at,
  }) async {
    await addTopikAnswerTime(attemptId, questionNo, elapsedMs);
    await advanceTopikAttempt(attemptId, elapsedMs, toQuestionNo, at);
  }

  Future<void> choose({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required DateTime at,
  }) => chooseTopikAnswer(attemptId, questionNo, selectedIdx, at);

  Future<void> snapshotAnswer({
    required String attemptId,
    required int questionNo,
    required int correctIdx,
    required int points,
    required int pointsEarned,
    required String questionType,
  }) => snapshotTopikAnswer(
    attemptId,
    questionNo,
    correctIdx,
    points,
    pointsEarned,
    questionType,
  );

  Future<void> complete({
    required String id,
    required DateTime at,
    required int score,
    required int maxScore,
    required int correctCount,
    required int answeredCount,
    required int questionCount,
    required int contentVersion,
  }) => completeTopikAttempt(
    id,
    at,
    score,
    maxScore,
    correctCount,
    answeredCount,
    questionCount,
    contentVersion,
  );

  Future<int> deleteAttempt(String id) => deleteTopikAttempt(id);
}
```

If the generated positional order differs from the `.drift` declaration order, the analyzer reports a type mismatch; align the call to the generated signature in `topik_attempt_dao.g.dart`.

`lib/features/topik/data/mappers/topik_attempt_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart'
    show TopikAttemptAnswerRow, TopikAttemptRow;
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

/// [row] as the domain model. The schema's CHECKs keep `level` and `section`
/// to known codes, so an unknown one is a broken database, not data.
TopikAttempt topikAttemptOf(TopikAttemptRow row) => TopikAttempt(
  id: row.id,
  testId: row.testId,
  level:
      TopikLevel.ofCode(row.level) ??
      (throw StateError('unknown TOPIK level ${row.level}')),
  section:
      TopikSection.ofCode(row.section) ??
      (throw StateError('unknown TOPIK section ${row.section}')),
  round: row.round,
  mode: TopikAttemptMode.fromCode(row.mode),
  status: TopikAttemptStatus.fromCode(row.status),
  startedAt: row.startedAt,
  completedAt: row.completedAt,
  updatedAt: row.updatedAt,
  totalTimeMs: row.totalTimeMs,
  currentQuestionNo: row.currentQuestionNo,
  questionCount: row.questionCount,
  maxScore: row.maxScore,
  score: row.score,
  correctCount: row.correctCount,
  answeredCount: row.answeredCount,
  contentVersion: row.contentVersion,
);

/// [row] as the domain model; a type code this build does not know reads as
/// null (an attempt synced from a newer app).
TopikAttemptAnswer topikAttemptAnswerOf(TopikAttemptAnswerRow row) =>
    TopikAttemptAnswer(
      questionNo: row.questionNo,
      selectedIdx: row.selectedIdx,
      timeSpentMs: row.timeSpentMs,
      answeredAt: row.answeredAt,
      correctIdx: row.correctIdx,
      points: row.points,
      pointsEarned: row.pointsEarned,
      questionType: TopikQuestionType.ofCode(row.questionType),
    );
```

- [ ] **Step 5: Write the contract**

`lib/features/topik/domain/repositories/topik_attempt_repository.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

/// The attempts on this device (spec §5, §13.5). The one implementation is
/// `TopikAttemptRepositoryImpl`; the contract keeps domain free of Drift and
/// lets tests substitute a fake (ADR-010). Every write is one transaction and
/// a refusal writes nothing. `elapsedMs` is the time since the last write;
/// it is added to the attempt's current question before anything else
/// (BR-TOPIK-015), and a negative value is an `ArgumentError`.
abstract interface class TopikAttemptRepository {
  /// The attempts of [testId], newest first (BR-TOPIK-021).
  Stream<List<TopikAttempt>> watchAttemptsOfTest(String testId);

  /// [attemptId] with its answers in question order; null once it is gone
  /// (BR-TOPIK-018, BR-TOPIK-027).
  Stream<TopikAttemptDetail?> watchAttempt(String attemptId);

  /// The status of every test with an attempt, keyed by test id; a test
  /// without one is not started (BR-TOPIK-022).
  Stream<Map<String, TopikTestStatus>> watchTestStatuses();

  /// A new attempt of [test] in progress, one blank answer per question, the
  /// first question current (BR-TOPIK-010). inProgressExists when the test
  /// already has one on this device (BR-TOPIK-011).
  Future<Outcome<TopikAttempt, TopikRejection>> start(
    TopikTest test, {
    DateTime? now,
  });

  /// Start new, confirmed: the attempt of [test] in progress, if any, is
  /// deleted with its answers and a new one started, in one transaction
  /// (BR-TOPIK-011).
  Future<TopikAttempt> replaceInProgressAndStart(
    TopikTest test, {
    DateTime? now,
  });

  /// Chooses [selectedIdx] on [questionNo], replacing an earlier choice, and
  /// makes it current (BR-TOPIK-012). notFound, attemptCompleted,
  /// unknownQuestion, invalidOption.
  Future<Outcome<void, TopikRejection>> answer({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
    DateTime? now,
  });

  /// Makes [toQuestionNo] current (spec §5.1). notFound, attemptCompleted,
  /// unknownQuestion.
  Future<Outcome<void, TopikRejection>> move({
    required String attemptId,
    required int toQuestionNo,
    required int elapsedMs,
    DateTime? now,
  });

  /// Records time on the current question: background, exit
  /// (BR-TOPIK-015). notFound, attemptCompleted.
  Future<Outcome<void, TopikRejection>> recordTime({
    required String attemptId,
    required int elapsedMs,
    DateTime? now,
  });

  /// Records the last time, scores the attempt against [test] (the content
  /// at submit), snapshots every answer and completes the attempt, queued
  /// for sync in the same transaction (BR-TOPIK-013, BR-TOPIK-026).
  /// notFound, attemptCompleted, contentMismatch (BR-TOPIK-019).
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  });

  /// Deletes [attemptId] with its answers; a submitted one is queued as a
  /// final delete (BR-TOPIK-018). notFound.
  Future<Outcome<void, TopikRejection>> delete(String attemptId);
}
```

- [ ] **Step 6: Write the implementation (writes; reads throw until Task 5)**

`lib/features/topik/data/repositories/topik_attempt_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart'
    show AppDatabase, TopikAttemptAnswerRow, TopikAttemptRow;
import 'package:memox/core/database/mapped_transaction.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/core/id/new_id.dart';
import 'package:memox/features/topik/data/datasources/topik_attempt_dao.dart';
import 'package:memox/features/topik/data/mappers/topik_attempt_mapper.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_score_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// The attempts on this device (spec §13.1, §13.5). Every write is one
/// transaction that reads the rows as they are at the moment of writing; the
/// schema's CHECKs and triggers back the refusals up.
final class TopikAttemptRepositoryImpl implements TopikAttemptRepository {
  TopikAttemptRepositoryImpl(this._db, {DateTime Function()? now})
    : _dao = TopikAttemptDao(_db),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final TopikAttemptDao _dao;
  final DateTime Function() _now;

  @override
  Stream<List<TopikAttempt>> watchAttemptsOfTest(String testId) =>
      throw UnimplementedError('Task 5');

  @override
  Stream<TopikAttemptDetail?> watchAttempt(String attemptId) =>
      throw UnimplementedError('Task 5');

  @override
  Stream<Map<String, TopikTestStatus>> watchTestStatuses() =>
      throw UnimplementedError('Task 5');

  @override
  Future<Outcome<TopikAttempt, TopikRejection>> start(
    TopikTest test, {
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      if (await _dao.openAttemptOf(test.testId) != null) {
        return const Rejected(TopikRejection.inProgressExists);
      }
      return Ok(await _insert(test, at));
    });
  }

  @override
  Future<TopikAttempt> replaceInProgressAndStart(
    TopikTest test, {
    DateTime? now,
  }) {
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      final open = await _dao.openAttemptOf(test.testId);
      if (open != null) await _dao.deleteAttempt(open.id);
      return _insert(test, at);
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> answer({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
    DateTime? now,
  }) {
    _checkElapsed(elapsedMs);
    if (!topikOptionIdxs.contains(selectedIdx)) {
      return Future.value(const Rejected(TopikRejection.invalidOption));
    }
    final at = now ?? _now();
    return _onOpenAttempt(attemptId, (row, numbers) async {
      if (!numbers.contains(questionNo)) {
        return const Rejected(TopikRejection.unknownQuestion);
      }
      await _addTime(row, elapsedMs, questionNo, at);
      await _dao.choose(
        attemptId: attemptId,
        questionNo: questionNo,
        selectedIdx: selectedIdx,
        at: at,
      );
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> move({
    required String attemptId,
    required int toQuestionNo,
    required int elapsedMs,
    DateTime? now,
  }) {
    _checkElapsed(elapsedMs);
    final at = now ?? _now();
    return _onOpenAttempt(attemptId, (row, numbers) async {
      if (!numbers.contains(toQuestionNo)) {
        return const Rejected(TopikRejection.unknownQuestion);
      }
      await _addTime(row, elapsedMs, toQuestionNo, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> recordTime({
    required String attemptId,
    required int elapsedMs,
    DateTime? now,
  }) {
    _checkElapsed(elapsedMs);
    final at = now ?? _now();
    return _onOpenAttempt(attemptId, (row, _) async {
      await _addTime(row, elapsedMs, row.currentQuestionNo, at);
      return const Ok(null);
    });
  }

  @override
  Future<Outcome<TopikAttempt, TopikRejection>> submit({
    required String attemptId,
    required TopikTest test,
    required int elapsedMs,
    DateTime? now,
  }) {
    _checkElapsed(elapsedMs);
    final at = now ?? _now();
    return _db.mappedTransaction(() async {
      final row = await _dao.attemptRow(attemptId);
      if (row == null) return const Rejected(TopikRejection.notFound);
      if (row.status != TopikAttemptStatus.inProgress.code) {
        return const Rejected(TopikRejection.attemptCompleted);
      }
      final answers = await _dao.answerRows(attemptId);
      if (!_sameQuestions(row, answers, test)) {
        return const Rejected(TopikRejection.contentMismatch);
      }
      await _addTime(row, elapsedMs, row.currentQuestionNo, at);
      final scored = scoreTopikAttempt(test, {
        for (final answer in answers) answer.questionNo: answer.selectedIdx,
      });
      for (final answer in scored.answers) {
        await _dao.snapshotAnswer(
          attemptId: attemptId,
          questionNo: answer.questionNo,
          correctIdx: answer.correctIdx,
          points: answer.points,
          pointsEarned: answer.pointsEarned,
          questionType: answer.questionType.code,
        );
      }
      await _dao.complete(
        id: attemptId,
        at: at,
        score: scored.score,
        maxScore: scored.maxScore,
        correctCount: scored.correctCount,
        answeredCount: scored.answeredCount,
        questionCount: scored.questionCount,
        contentVersion: test.contentVersion,
      );
      return Ok(topikAttemptOf((await _dao.attemptRow(attemptId))!));
    });
  }

  @override
  Future<Outcome<void, TopikRejection>> delete(String attemptId) =>
      _db.mappedTransaction(() async {
        final deleted = await _dao.deleteAttempt(attemptId);
        if (deleted == 0) return const Rejected(TopikRejection.notFound);
        return const Ok(null);
      });

  Future<TopikAttempt> _insert(TopikTest test, DateTime at) async {
    final numbers = [for (final question in test.questions) question.no]
      ..sort();
    final id = newId();
    await _dao.insertAttempt(
      id: id,
      testId: test.testId,
      level: test.level.code,
      section: test.section.code,
      round: test.round,
      mode: TopikAttemptMode.practice.code,
      startedAt: at,
      currentQuestionNo: numbers.first,
      questionCount: numbers.length,
      maxScore: test.questions.fold(0, (sum, q) => sum + q.points),
      contentVersion: test.contentVersion,
    );
    for (final no in numbers) {
      await _dao.insertAnswer(id, no);
    }
    return topikAttemptOf((await _dao.attemptRow(id))!);
  }

  /// Runs [write] on [attemptId] when it exists and is in progress, with the
  /// attempt's question numbers; notFound or attemptCompleted otherwise.
  Future<Outcome<void, TopikRejection>> _onOpenAttempt(
    String attemptId,
    Future<Outcome<void, TopikRejection>> Function(
      TopikAttemptRow row,
      Set<int> questionNos,
    )
    write,
  ) => _db.mappedTransaction(() async {
    final row = await _dao.attemptRow(attemptId);
    if (row == null) return const Rejected(TopikRejection.notFound);
    if (row.status != TopikAttemptStatus.inProgress.code) {
      return const Rejected(TopikRejection.attemptCompleted);
    }
    final numbers = {
      for (final answer in await _dao.answerRows(attemptId)) answer.questionNo,
    };
    return write(row, numbers);
  });

  /// Adds [elapsedMs] to the question that was current, then makes
  /// [toQuestionNo] current (BR-TOPIK-015).
  Future<void> _addTime(
    TopikAttemptRow row,
    int elapsedMs,
    int toQuestionNo,
    DateTime at,
  ) => _dao.addTime(
    attemptId: row.id,
    questionNo: row.currentQuestionNo,
    elapsedMs: elapsedMs,
    toQuestionNo: toQuestionNo,
    at: at,
  );

  /// Whether [test] is the attempt's test with exactly its questions
  /// (BR-TOPIK-019).
  static bool _sameQuestions(
    TopikAttemptRow row,
    List<TopikAttemptAnswerRow> answers,
    TopikTest test,
  ) {
    if (test.testId != row.testId) return false;
    final stored = {for (final answer in answers) answer.questionNo};
    final current = {for (final question in test.questions) question.no};
    return stored.length == current.length && stored.containsAll(current);
  }

  static void _checkElapsed(int elapsedMs) {
    if (elapsedMs < 0) {
      throw ArgumentError.value(elapsedMs, 'elapsedMs', 'must not be negative');
    }
  }
}
```

- [ ] **Step 7: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/database
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
bash .claude/skills/flutter-drift/scripts/check_drift.sh --diff
dart format lib/core/database lib/features/topik test/features/topik test/support
git add lib/core/database/queries/topik_queries.drift lib/features/topik test/features/topik/data/topik_attempt_repository_writes_test.dart test/support/topik_content_fixtures.dart
git commit -m "<DEV-n> feat(topik): attempt repository writes"
```

---

### Task 5: The attempt repository — reads and the provider

**Files:**
- Modify: `lib/features/topik/data/repositories/topik_attempt_repository_impl.dart` (the three reads)
- Create: `lib/features/topik/di/topik_attempt_repository_provider.dart`
- Test: `test/features/topik/data/topik_attempt_repository_reads_test.dart`
- Test: `test/features/topik/di/topik_attempt_repository_provider_test.dart`

**Interfaces:**
- Consumes: Task 4 DAO (`watchAttemptRowsOf`, `watchAllAttemptRows`, `attemptChanges`, `attemptRow`, `answerRows`), mappers, `topikTestStatusesOf`; `databaseProvider` (`package:memox/core/database/di/database_provider.dart`); `dayClockProvider` (`package:memox/core/clock/di/day_clock_provider.dart`).
- Produces: `topikAttemptRepositoryProvider` (`@riverpod`, auto-dispose) → `TopikAttemptRepository`.

- [ ] **Step 1: Write the failing tests**

`test/features/topik/data/topik_attempt_repository_reads_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_content_fixtures.dart';

final _t0 = DateTime.utc(2026, 10, 15, 9);
DateTime _at(int seconds) => _t0.add(Duration(seconds: seconds));

T _ok<T>(Outcome<T, TopikRejection> outcome) => switch (outcome) {
  Ok(:final value) => value,
  Rejected(:final reason) => fail('rejected: $reason'),
};

void main() {
  late AppDatabase db;
  late TopikAttemptRepositoryImpl repository;
  final test2 = topikTestFixture();
  final test1 = topikTestFixture(level: TopikLevel.topik1);
  setUp(() {
    db = openTestDatabase();
    repository = TopikAttemptRepositoryImpl(db, now: () => _t0);
  });
  tearDown(() => db.close());

  Future<TopikAttempt> completed(int startedSecond) async {
    final attempt = _ok(await repository.start(test2, now: _at(startedSecond)));
    return _ok(
      await repository.submit(
        attemptId: attempt.id,
        test: test2,
        elapsedMs: 0,
        now: _at(startedSecond + 1),
      ),
    );
  }

  test('attempts of a test, newest first, and only that test\'s '
      '(BR-TOPIK-021)', () async {
    final first = await completed(0);
    final second = await completed(10);
    final open = _ok(await repository.start(test2, now: _at(20)));
    _ok(await repository.start(test1, now: _at(30)));

    final attempts = await repository.watchAttemptsOfTest(test2.testId).first;

    expect(attempts.map((a) => a.id), [open.id, second.id, first.id]);
  });

  test('a tie inside one second keeps creation order, newest first', () async {
    final a = await completed(0);
    final b = _ok(await repository.start(test2, now: _at(0)));
    final attempts = await repository.watchAttemptsOfTest(test2.testId).first;
    expect(attempts.map((x) => x.id), [b.id, a.id]);
  });

  test('an attempt with its answers re-emits on a write and emits null once '
      'deleted (BR-TOPIK-018)', () async {
    final attempt = _ok(await repository.start(test2));
    final seen = <TopikAttemptDetail?>[];
    final sub = repository.watchAttempt(attempt.id).listen(seen.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();
    expect(seen.single!.answers, hasLength(50));
    expect(seen.single!.answers.first.selectedIdx, isNull);

    _ok(await repository.answer(attemptId: attempt.id, questionNo: 1, selectedIdx: 3, elapsedMs: 0));
    await pumpEventQueue();
    expect(seen.last!.answers.first.selectedIdx, 3);

    _ok(await repository.delete(attempt.id));
    await pumpEventQueue();
    expect(seen.last, isNull);
  });

  test('test statuses fold every attempt (BR-TOPIK-022)', () async {
    await completed(0);
    _ok(await repository.start(test2, now: _at(20)));

    final statuses = await repository.watchTestStatuses().first;

    expect(statuses.keys, [test2.testId]);
    final status = statuses[test2.testId]!;
    expect(status.hasInProgress, isTrue);
    expect(status.completedCount, 1);
    expect(status.bestScore, 0);
    expect(status.lastActivityAt.isAtSameMomentAs(_at(20)), isTrue);
  });
}
```

`test/features/topik/di/topik_attempt_repository_provider_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/di/topik_attempt_repository_provider.dart';

import '../../../support/test_database.dart';

void main() {
  test('provides the Drift implementation on the app database', () {
    final db = openTestDatabase();
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    expect(
      container.read(topikAttemptRepositoryProvider),
      isA<TopikAttemptRepositoryImpl>(),
    );
  });
}
```

(If `databaseProvider` is not overridden this way elsewhere, copy the override another `di/*_provider_test.dart` uses: `rg -n "databaseProvider.overrideWith" test`.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/data/topik_attempt_repository_reads_test.dart test/features/topik/di/topik_attempt_repository_provider_test.dart`
Expected: FAIL — `UnimplementedError('Task 5')` and a missing provider file.

- [ ] **Step 3: Implement the reads**

In `topik_attempt_repository_impl.dart`, add `import 'package:memox/core/error/failure.dart';` (for `mapDatabaseErrors`) and replace the three `UnimplementedError` bodies:

```dart
  @override
  Stream<List<TopikAttempt>> watchAttemptsOfTest(String testId) => _dao
      .watchAttemptRowsOf(testId)
      .map((rows) => [for (final row in rows) topikAttemptOf(row)])
      .mapDatabaseErrors();

  @override
  Stream<TopikAttemptDetail?> watchAttempt(String attemptId) => _dao
      .attemptChanges()
      .asyncMap(
        (_) => _db.transaction(() async {
          final row = await _dao.attemptRow(attemptId);
          if (row == null) return null;
          return TopikAttemptDetail(
            attempt: topikAttemptOf(row),
            answers: [
              for (final answer in await _dao.answerRows(attemptId))
                topikAttemptAnswerOf(answer),
            ],
          );
        }),
      )
      .mapDatabaseErrors();

  @override
  Stream<Map<String, TopikTestStatus>> watchTestStatuses() => _dao
      .watchAllAttemptRows()
      .map((rows) => topikTestStatusesOf([for (final row in rows) topikAttemptOf(row)]))
      .mapDatabaseErrors();
```

(Check the import that declares `mapDatabaseErrors`: `rg -n "extension .*mapDatabaseErrors|mapDatabaseErrors\(\)" lib/core/error`; `TrashRepositoryImpl` imports it the same way.)

- [ ] **Step 4: Write the provider**

`lib/features/topik/di/topik_attempt_repository_provider.dart`:

```dart
import 'package:memox/core/clock/di/day_clock_provider.dart';
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'topik_attempt_repository_provider.g.dart';

@riverpod
TopikAttemptRepository topikAttemptRepository(Ref ref) =>
    TopikAttemptRepositoryImpl(
      ref.watch(databaseProvider),
      now: ref.watch(dayClockProvider).now,
    );
```

- [ ] **Step 5: Generate and run the tests**

```bash
dart run build_runner build --delete-conflicting-outputs
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/architecture
```

Expected: PASS (the architecture tests accept the new files and imports).

- [ ] **Step 6: Commit**

```bash
dart format lib/features/topik test/features/topik
git add lib/features/topik test/features/topik
git commit -m "<DEV-n> feat(topik): attempt repository reads and provider"
```

---

### Task 6: The account switch clears TOPIK data

**Files:**
- Modify: `lib/core/database/local_data_reset.dart`
- Modify: `test/core/database/local_data_reset_test.dart`

**Interfaces:**
- Consumes: the v17 tables and the delete trigger (Tasks 2–3).
- Produces: `LocalDataReset.run()` deletes every `topik_attempt` (answers by cascade) with `applying_remote` set, so nothing is queued, and marks `topikAttempt` and `topikAttemptAnswer` updated (BR-TOPIK-027).

- [ ] **Step 1: Write the failing test**

In `test/core/database/local_data_reset_test.dart`, add to the `_seed` list (before the `UPDATE app_settings` line):

```dart
    "INSERT INTO topik_attempt (id, test_id, level, section, round, mode, status, started_at, updated_at, current_question_no, question_count, max_score, content_version) VALUES ('TA', 'topik2-96-reading', 'topik2', 'reading', 96, 'practice', 'in_progress', 0, 0, 1, 1, 2, 1), ('TB', 'topik2-96-listening', 'topik2', 'listening', 96, 'practice', 'in_progress', 0, 0, 1, 1, 2, 1)",
    "INSERT INTO topik_attempt_answer (attempt_id, question_no) VALUES ('TA', 1), ('TB', 1)",
    "UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, points_earned = 0, question_type = 'L2_picture' WHERE attempt_id = 'TB'",
    "UPDATE topik_attempt SET status = 'completed', completed_at = 1, updated_at = 1, score = 0, correct_count = 0, answered_count = 0 WHERE id = 'TB'",
```

Add `'topik_attempt'` and `'topik_attempt_answer'` to the table list the first test expects at 0 rows. Add a test:

```dart
  test('BR-TOPIK-027: a watched attempt list sees the attempts go', () async {
    final db = openTestDatabase();
    addTearDown(db.close);
    await _seed(db);
    final counts = <int>[];
    final watch = db
        .select(db.topikAttempt)
        .watch()
        .listen((rows) => counts.add(rows.length));
    addTearDown(watch.cancel);
    await pumpEventQueue();

    await LocalDataReset(
      db,
      resetSyncedSettings: () =>
          SettingsDao(db).resetSyncedDefaults(DateTime.utc(2026)),
    ).run();
    await pumpEventQueue();

    expect(counts.first, 2);
    expect(counts.last, 0);
  });
```

(The seed's completed attempt queues an upsert through its trigger; the existing `sync_outbox` expectation of 0 rows after the reset proves the reset clears it and its own deletes queue nothing.)

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/database/local_data_reset_test.dart`
Expected: FAIL — `topik_attempt` still has 2 rows; the watch does not see 0.

- [ ] **Step 3: Implement**

In `local_data_reset.dart`:
- change the delete loop to `for (final table in ['card', 'deck', 'delete_batches', 'tags', 'topik_attempt'])`;
- add `_db.topikAttempt,` and `_db.topikAttemptAnswer,` to `markTablesUpdated([...])` after `_db.studyGuessOptions,`;
- add to the class comment, after "study rows go with them by cascade,": "TOPIK attempts go with their answers by cascade (BR-TOPIK-027),".

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/database test/features/account`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
dart format lib/core/database test/core/database
git add lib/core/database/local_data_reset.dart test/core/database/local_data_reset_test.dart
git commit -m "<DEV-n> feat(db): the account reset clears TOPIK attempts"
```

---

### Task 7: The data model document, its invariants and the gate

**Files:**
- Modify: `docs/shared/data/schema.md` (overview, two table sections, `sync_outbox` entity types and triggers, invariants 41–43)
- Modify: `test/database/invariants_test.dart` (1 to 43; seed and planted violations)
- Modify: `docs/features/topik/README.md` (`code:` adds `lib/core/database/tables/topik.drift`, `lib/core/database/queries/topik_queries.drift`)
- Modify: `.claude/skills/flutter-workflow/scripts/verification_impact_map.json` only if the docs check asks for the new paths

**Interfaces:**
- Consumes: the schema of Tasks 2–3.
- Produces: invariant queries 41–43 that `invariants_test.dart` runs from the document.

- [ ] **Step 1: Write the failing invariant tests**

In `test/database/invariants_test.dart`:
- change `'schema.md states invariants 1 to 40'` to `'schema.md states invariants 1 to 43'` and `n <= 40` to `n <= 43`;
- append to `_seed` (a completed attempt whose snapshot matches, and one in progress):

```dart
  // TOPIK (schema 17): T1 submitted with question 1 right (2 of 4 points),
  // T2 in progress with question 1 chosen.
  "INSERT INTO topik_attempt (id, test_id, level, section, round, mode, status, started_at, updated_at, total_time_ms, current_question_no, question_count, max_score, content_version) VALUES ('T1', 'topik2-96-reading', 'topik2', 'reading', 96, 'practice', 'in_progress', 0, 0, 0, 1, 2, 4, 1), ('T2', 'topik2-96-listening', 'topik2', 'listening', 96, 'practice', 'in_progress', 0, 0, 0, 1, 2, 4, 1)",
  "INSERT INTO topik_attempt_answer (attempt_id, question_no) VALUES ('T1', 1), ('T1', 2), ('T2', 1), ('T2', 2)",
  "UPDATE topik_attempt_answer SET selected_idx = 1, answered_at = 5, time_spent_ms = 3000 WHERE question_no = 1",
  "UPDATE topik_attempt SET total_time_ms = 3000",
  "UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, points_earned = CASE WHEN selected_idx = 1 THEN 2 ELSE 0 END, question_type = 'R2_fill_blank' WHERE attempt_id = 'T1'",
  "UPDATE topik_attempt SET status = 'completed', completed_at = 9, updated_at = 9, score = 2, correct_count = 1, answered_count = 1 WHERE id = 'T1'",
```

- add to `_planted`:

```dart
  41: ["UPDATE topik_attempt SET total_time_ms = 1 WHERE id = 'T2'"],
  42: [
    "INSERT INTO topik_attempt (id, test_id, level, section, round, mode, status, started_at, completed_at, updated_at, current_question_no, question_count, max_score, content_version, score, correct_count, answered_count) VALUES ('bad', 'x', 'topik2', 'reading', 96, 'practice', 'completed', 0, 1, 1, 1, 1, 4, 1, 3, 1, 1)",
    "INSERT INTO topik_attempt_answer (attempt_id, question_no, selected_idx, answered_at, correct_idx, points, points_earned, question_type) VALUES ('bad', 1, 1, 0, 1, 2, 2, 'R2_fill_blank')",
  ],
  43: [
    "UPDATE topik_attempt_answer SET correct_idx = 1, points = 2, points_earned = 2, question_type = 'L2_picture' WHERE attempt_id = 'T2' AND question_no = 1",
  ],
```

(41: a total that is not the sum of the answers' time; 42: a submitted attempt whose score is not the sum of its points earned — the trigger refuses an update of a completed row, so the violation is planted by insert; 43: a snapshot on an attempt in progress.)

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/database/invariants_test.dart`
Expected: FAIL — `schema.md states invariants 1 to 43` (41–43 missing).

- [ ] **Step 3: Document the tables and the invariants**

In `docs/shared/data/schema.md`:

1. In `## Tổng quan`, after the `account_state…` line add:
   `topik_attempt ──► topik_attempt_answer  (lượt làm đề TOPIK và đáp án từng câu, schema 17; đề là asset, không phải bảng)`
2. Before `## Bất biến — phải kiểm tra được bằng query`, add:

```markdown
## `topik_attempt` (schema 17)

Một lượt làm một đề TOPIK ([ADR-023](../decisions/ADR-023-luyen-de-topik.md),
[spec](../../superpowers/specs/2026-10-15-topik-practice-design.md) §7.1, §13.1). Đề là
asset đóng gói, nên `test_id` không có FK. Lượt dở gắn với máy; lượt đã nộp bất biến
(trigger `topik_attempt_completed_immutable` chặn mọi cột trừ `server_version`) và đồng
bộ (BR-TOPIK-010, BR-TOPIK-026).

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `id` | TEXT PK | UUID v7 |
| `test_id` | TEXT NOT NULL | `testId` của đề, ví dụ `topik2-96-reading` |
| `level` | TEXT NOT NULL | `topik1` \| `topik2` |
| `section` | TEXT NOT NULL | `listening` \| `reading` |
| `round` | INTEGER NOT NULL | kỳ thi (회차), > 0 |
| `mode` | TEXT NOT NULL | `practice`; `exam` ở Phase B (BR-TOPIK-032) |
| `status` | TEXT NOT NULL | `in_progress` \| `completed` (BR-TOPIK-010) |
| `started_at` | DATETIME NOT NULL | UTC |
| `completed_at` | DATETIME NULL | UTC; có đúng khi `completed` |
| `updated_at` | DATETIME NOT NULL | lần ghi cuối; "hoạt động gần nhất" (BR-TOPIK-022) |
| `total_time_ms` | INTEGER NOT NULL | Σ `time_spent_ms` của các đáp án (BR-TOPIK-015) |
| `current_question_no` | INTEGER NOT NULL | câu đang hiện; thời gian cộng cho câu này |
| `question_count` | INTEGER NOT NULL | số câu, ghi lúc bắt đầu |
| `max_score` | INTEGER NOT NULL | Σ điểm các câu (100), ghi lúc bắt đầu, chốt lại lúc nộp |
| `score` | INTEGER NULL | bản chốt: Σ `points_earned`; NULL khi đang làm |
| `correct_count` | INTEGER NULL | bản chốt; NULL khi đang làm |
| `answered_count` | INTEGER NULL | bản chốt; NULL khi đang làm |
| `content_version` | INTEGER NOT NULL | phiên bản nội dung lúc bắt đầu, rồi lúc chấm (BR-TOPIK-019) |
| `server_version` | INTEGER NULL | version server đã xác nhận; luôn NULL khi đang làm |

Index: `idx_topik_attempt_test_started` trên `(test_id, started_at)` cho History và
lượt gần đây; `idx_topik_attempt_one_open` UNIQUE trên `(test_id)` `WHERE status =
'in_progress'`: mỗi đề nhiều nhất một lượt dở trên một máy (BR-TOPIK-011).

## `topik_attempt_answer` (schema 17)

Một hàng mỗi câu, tạo lúc bắt đầu; chọn đáp án và thời gian là UPDATE. Bản chốt điền
lúc nộp (BR-TOPIK-013); sau đó trigger `topik_attempt_answer_completed_immutable` chặn
mọi thay đổi.

| Cột | Kiểu | Ghi chú |
|---|---|---|
| `attempt_id` | TEXT NOT NULL | → `topik_attempt(id)` ON DELETE CASCADE; PK cùng `question_no` |
| `question_no` | INTEGER NOT NULL | số câu thật (TOPIK I đọc bắt đầu từ 31) |
| `selected_idx` | INTEGER NULL | ①–④ là 1–4; NULL khi chưa chọn (BR-TOPIK-003, BR-TOPIK-012) |
| `time_spent_ms` | INTEGER NOT NULL | thời gian cộng dồn của câu (BR-TOPIK-015) |
| `answered_at` | DATETIME NULL | lần chọn cuối; có đúng khi `selected_idx` có |
| `correct_idx` | INTEGER NULL | bản chốt: đáp án đúng lúc nộp |
| `points` | INTEGER NULL | bản chốt: điểm của câu |
| `points_earned` | INTEGER NULL | bản chốt: `points` khi đúng, ngược lại 0 (CHECK) |
| `question_type` | TEXT NULL | bản chốt: mã dạng câu; không CHECK để lượt từ bản app mới hơn vẫn đồng bộ về |
```

3. In the `sync_outbox` table, extend the `entity_type` cell with ` \| \`topik_attempt\` (schema 17)`, and add to the trigger paragraph, after the `review_log`/`card_schedule` sentence: "Từ schema 17, `topik_attempt` xếp `upsert` khi lượt chuyển `in_progress` → `completed` và `delete` khi xoá một lượt đã nộp; lượt dở và đáp án không bao giờ vào outbox (BR-TOPIK-026)."
4. In `## Bất biến`, add a `### TOPIK` subsection before `## Quyết định về ID và thời gian`:

````markdown
### TOPIK

```sql
-- 41. Lượt có số câu, tổng thời gian hay câu hiện tại không khớp các đáp án của nó
--     (BR-TOPIK-012, BR-TOPIK-015)
--     Mọi trạng thái: bắt đầu tạo đủ một hàng mỗi câu, và mọi lần ghi thời gian
--     cộng cùng một khoảng vào câu và vào tổng trong một transaction.
SELECT t.id FROM topik_attempt t
WHERE t.question_count <> (SELECT COUNT(*) FROM topik_attempt_answer a WHERE a.attempt_id = t.id)
   OR t.total_time_ms <> (SELECT COALESCE(SUM(a.time_spent_ms), 0) FROM topik_attempt_answer a WHERE a.attempt_id = t.id)
   OR NOT EXISTS (SELECT 1 FROM topik_attempt_answer a
                  WHERE a.attempt_id = t.id AND a.question_no = t.current_question_no);

-- 42. Lượt đã nộp có bản chốt không khớp các đáp án (BR-TOPIK-013)
SELECT t.id FROM topik_attempt t
WHERE t.status = 'completed'
  AND (t.score <> (SELECT SUM(a.points_earned) FROM topik_attempt_answer a WHERE a.attempt_id = t.id)
    OR t.max_score <> (SELECT SUM(a.points) FROM topik_attempt_answer a WHERE a.attempt_id = t.id)
    OR t.correct_count <> (SELECT COUNT(*) FROM topik_attempt_answer a
                           WHERE a.attempt_id = t.id AND a.selected_idx = a.correct_idx)
    OR t.answered_count <> (SELECT COUNT(*) FROM topik_attempt_answer a
                            WHERE a.attempt_id = t.id AND a.selected_idx IS NOT NULL));

-- 43. Đáp án có bản chốt khi lượt còn dở, hoặc thiếu bản chốt khi lượt đã nộp
--     (BR-TOPIK-013)
--     CHECK của một hàng không nhìn được trạng thái của lượt.
SELECT a.attempt_id FROM topik_attempt_answer a
JOIN topik_attempt t ON t.id = a.attempt_id
WHERE (t.status = 'completed') <> (a.correct_idx IS NOT NULL);
```
````

- [ ] **Step 4: Run the tests and the docs check**

```bash
bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/database
python3 .claude/skills/flutter-workflow/scripts/verify_invariants.py
```

Expected: the Dart tests PASS. `verify_invariants.py` reports `Q41`–`Q43` "chưa có case vi phạm", like `Q38`–`Q40` already do on `master` (a pre-existing gap: its `BAD` table stops at 37; the gate runs `invariants_test.dart`, not this script). It must not report `SQL LỖI` or a false positive for 41–43; if it does, the column tables above are wrong.

- [ ] **Step 5: Update the feature README and run the gate**

In `docs/features/topik/README.md` frontmatter, set
`code: [lib/features/topik/domain, lib/features/topik/data, lib/features/topik/di, lib/core/database/tables/topik.drift, lib/core/database/queries/topik_queries.drift, tools/topik]`.

```bash
bash .claude/skills/flutter-workflow/scripts/dod_check.sh
```

Expected: PASS (format, analyze, generated code, architecture, docs, guard, full suite). Fix anything it reports in this task; if the docs check asks for an impact-map entry for the new paths, add it to `verification_impact_map.json`.

- [ ] **Step 6: Commit**

```bash
git add docs/shared/data/schema.md test/database/invariants_test.dart docs/features/topik/README.md .claude/skills/flutter-workflow/scripts/verification_impact_map.json
git commit -m "<DEV-n> docs(db): TOPIK attempt tables and invariants 41-43"
```

---

## Plan-time rulings

| # | Ruling | Why |
|---|---|---|
| R1 | The two sync capture triggers ship in v17 with this plan, not with plan 3 (§13.9 listed them under sync). | BR-TOPIK-026 needs the outbox operation in the submit's own transaction, and once v17 is on `master` it is immutable, so plan 3 would need a v18 migration for two triggers. Until plan 3 registers the adapter, `SyncCoordinator._push` reads `pendingBatch(_adapters.keys…)` and leaves `topik_attempt` rows queued; no screen can submit before plan 6, after plan 3. |
| R2 | `scoreTopikAttempt` moves from plan 4 to this plan; the statistics of §6 stay in plan 4. | `submit` cannot be written without it. |
| R3 | A partial unique index `idx_topik_attempt_one_open` enforces BR-TOPIK-011 (addition to §13.1). | "Enforced by: rule + store": a double Start that passes the read is still refused; it also serves the open-attempt lookup. |
| R4 | `level`, `section`, `mode`, `status` have `CHECK`s; `question_type` has none. Plan 3's `upsertFromServer` must skip (and log) a pulled attempt whose codes this build's CHECKs refuse, instead of failing the pull. | Enum codes are text with a CHECK (schema conventions); question types grow with content and a synced attempt from a newer app must still land. |
| R5 | Time is written as `elapsedMs` added to the **stored** current question by `answer`, `move`, `recordTime` and `submit`; negative is an `ArgumentError`. | The store, not the controller, decides which question the time belongs to, so a stale controller cannot misfile it; plan 6 measures with a monotonic `Stopwatch`. |
| R6 | `watchTestStatuses` folds every attempt in Dart (`topikTestStatusesOf`), not an SQL aggregate. | One person's attempts are few; the fold is pure and tested, and avoids Drift's nullable aggregate types. |
| R7 | The queries file is `queries/topik_queries.drift` (§3.2), the DAO `TopikAttemptDao`. | Spec §3.2 names the file. |
| R8 | `topikOptionIdxs` becomes public in `topik_question_model.dart`; the content check and the schema parity test use it. | One constant for ①–④ across content, store and schema. |
| R9 | Invariants 41–43 join `schema.md`. | The snapshot and time sums span rows, which a CHECK cannot see. |

## Out of this plan

- Sync adapter, `SyncStore.markAllPending` seed, Supabase migration and pgTAP (plan 3; R4 applies there).
- Statistics of §6, use cases, the duration formatter (plan 4); audio and `MxSlider` (plan 5); screens (plan 6); the round-96 pack (plan 7).
- `verify_invariants.py` has no violation case for invariants 38–43 (38–40 pre-date this plan): a sub-issue, not this plan.
