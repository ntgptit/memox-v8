# TOPIK statistics, use cases and the duration formatter Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything screens 34–39 read, as pure domain code: the shared duration formatter (BR-TOPIK-025), the test's Overall Progress and attempt numbering (BR-TOPIK-020, BR-TOPIK-021), the Summary figures and per-type statistics (BR-TOPIK-023, BR-TOPIK-024), the test list order (BR-TOPIK-022), and one use case per interaction of spec §3.3 (Phase 2 plan 4 of §13.9, epic DEV-394).

**Architecture:** Pure functions in `lib/features/topik/domain/models/` over `TopikAttempt` / `TopikAttemptDetail` (plan 2) and `TopikTest` (plan 1). Use cases in `domain/usecases/` combine `TopikContentRepository.catalog()` (a `Future`, read once) with the attempt repository's streams. The duration parts live in `lib/core/text/` (owner ruling in BR-TOPIK-025); the localized words live in `lib/l10n/` beside `relative_time.dart`, as the app already does for "3 hours ago". Use case providers are presentation (`presentation/providers/`, the progress feature's pattern) and come with the screens (plan 6).

**Tech Stack:** Dart 3.13 / Flutter 3.47.5, `flutter_localizations` (ARB, `flutter gen-l10n`), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-15-topik-practice-design.md` §3.3, §5.4, §6.1–§6.4. Rules: `BR-TOPIK-019`…`BR-TOPIK-025`.

## Global Constraints

- `domain/` imports no Flutter, Riverpod or Drift; `lib/core/text/` imports nothing from features; `lib/l10n/*.dart` extends `AppLocalizations`.
- Whole percents and the average round half up: `(2 * part * 100 + whole) ~/ (2 * whole)` for non-negative values.
- Durations are milliseconds in storage and whole seconds on screen, truncated (a question at 59 999 ms shows `59s`); never milliseconds.
- Ordering ties are total: attempts by `startedAt` then `id`; questions by number; types by `TopikQuestionType` enum order.
- Use cases take their repositories in the constructor and expose `call`; they never start a transaction or read a clock (the repository has the clock, plan 2).
- New ARB keys go to both `app_en.arb` and `app_vi.arb`; run `flutter gen-l10n` after editing them.
- Commits name the task's sub-issue and end with the session's attribution lines.

## Review Focus

1. **A test with no attempts, or only one in progress**: Overall Progress shows Sessions 1, Completed 0, and no Best, Average, Accuracy (null), never a division by zero (Task 2).
2. **Two attempts started in the same second**: numbers `#1`/`#2` follow creation (id) order, and deleting `#1` renumbers the other to `#1` (Task 2).
3. **An attempt whose every question took 0 ms** (submitted at once): Summary names no Longest question (Task 3).
4. **A question type unknown to this build** (an attempt synced from a newer app): left out of the per-type table, never a crash (Task 3).
5. **The content pack missing or invalid for an attempt's test** (BR-TOPIK-019): the detail, Summary and Review still stream; Start, Continue and Submit are refused `testUnavailable` (Task 5).

---

### Task 1: The shared duration formatter

**Files:**
- Create: `lib/core/text/duration_parts.dart`
- Create: `lib/l10n/duration_text.dart`
- Modify: `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`
- Test: `test/core/text/duration_parts_test.dart`, `test/l10n/duration_text_test.dart`

**Interfaces:**
- Produces: `final class DurationParts { const DurationParts(this.hours, this.minutes, this.seconds); factory DurationParts.ofMilliseconds(int ms); final int hours, minutes, seconds; }`; `extension DurationText on AppLocalizations { String duration(int milliseconds); }`.

- [ ] **Step 1: Write the failing tests**

`test/core/text/duration_parts_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/text/duration_parts.dart';

// BR-TOPIK-025: whole seconds, truncated; hours do not wrap.
void main() {
  (int, int, int) parts(int ms) {
    final p = DurationParts.ofMilliseconds(ms);
    return (p.hours, p.minutes, p.seconds);
  }

  test('splits milliseconds into hours, minutes and whole seconds', () {
    expect(parts(0), (0, 0, 0));
    expect(parts(42000), (0, 0, 42));
    expect(parts(59999), (0, 0, 59));
    expect(parts(185000), (0, 3, 5));
    expect(parts(3731000), (1, 2, 11));
    expect(parts(90000000), (25, 0, 0));
  });

  test('a negative duration is an error', () {
    expect(() => DurationParts.ofMilliseconds(-1), throwsArgumentError);
  });
}
```

`test/l10n/duration_text_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/l10n/duration_text.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

// BR-TOPIK-025: 42s, 3m 05s, 1h 02m 11s, in the interface language.
void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final vi = lookupAppLocalizations(const Locale('vi'));

  test('English reads seconds, minutes and hours, zero-padded after the first unit', () {
    expect(en.duration(0), '0s');
    expect(en.duration(42000), '42s');
    expect(en.duration(185000), '3m 05s');
    expect(en.duration(3731000), '1h 02m 11s');
    expect(en.duration(3600000), '1h 00m 00s');
  });

  test('Vietnamese reads the same steps', () {
    expect(vi.duration(42000), '42 giây');
    expect(vi.duration(185000), '3 phút 05 giây');
    expect(vi.duration(3731000), '1 giờ 02 phút 11 giây');
  });
}
```

- [ ] **Step 2: Run them to verify they fail**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/text/duration_parts_test.dart test/l10n/duration_text_test.dart`
Expected: FAIL — the files do not exist.

- [ ] **Step 3: Implement**

`lib/core/text/duration_parts.dart`:

```dart
/// A stored duration as the screen shows it: whole hours, minutes and
/// seconds, the milliseconds truncated (BR-TOPIK-025). Hours do not wrap into
/// days. The words around the numbers are localized in `lib/l10n/`.
final class DurationParts {
  const DurationParts(this.hours, this.minutes, this.seconds);

  factory DurationParts.ofMilliseconds(int milliseconds) {
    if (milliseconds < 0) {
      throw ArgumentError.value(milliseconds, 'milliseconds', 'is negative');
    }
    final seconds = milliseconds ~/ Duration.millisecondsPerSecond;
    return DurationParts(
      seconds ~/ Duration.secondsPerHour,
      seconds % Duration.secondsPerHour ~/ Duration.secondsPerMinute,
      seconds % Duration.secondsPerMinute,
    );
  }

  final int hours;
  final int minutes;
  final int seconds;
}
```

`lib/l10n/duration_text.dart`:

```dart
import 'package:memox/core/text/duration_parts.dart';
import 'package:memox/l10n/generated/app_localizations.dart';

/// A stored duration in the person's words: `42s`, `3m 05s`, `1h 02m 11s`
/// (BR-TOPIK-025). Units after the first are zero-padded to two digits.
extension DurationText on AppLocalizations {
  String duration(int milliseconds) {
    final parts = DurationParts.ofMilliseconds(milliseconds);
    String two(int value) => value.toString().padLeft(2, '0');
    if (parts.hours > 0) {
      return commonDurationHours(
        parts.hours,
        two(parts.minutes),
        two(parts.seconds),
      );
    }
    if (parts.minutes > 0) {
      return commonDurationMinutes(parts.minutes, two(parts.seconds));
    }
    return commonDurationSeconds(parts.seconds);
  }
}
```

`app_en.arb`, after the `commonAgo*` entries:

```json
  "commonDurationSeconds": "{seconds}s",
  "@commonDurationSeconds": {
    "description": "A duration under a minute (BR-TOPIK-025).",
    "placeholders": {"seconds": {"type": "int"}}
  },
  "commonDurationMinutes": "{minutes}m {seconds}s",
  "@commonDurationMinutes": {
    "description": "A duration under an hour; seconds is two digits (BR-TOPIK-025).",
    "placeholders": {"minutes": {"type": "int"}, "seconds": {"type": "String"}}
  },
  "commonDurationHours": "{hours}h {minutes}m {seconds}s",
  "@commonDurationHours": {
    "description": "A duration of an hour or more; minutes and seconds are two digits (BR-TOPIK-025).",
    "placeholders": {"hours": {"type": "int"}, "minutes": {"type": "String"}, "seconds": {"type": "String"}}
  },
```

`app_vi.arb`, after the `commonAgo*` entries:

```json
  "commonDurationSeconds": "{seconds} giây",
  "commonDurationMinutes": "{minutes} phút {seconds} giây",
  "commonDurationHours": "{hours} giờ {minutes} phút {seconds} giây",
```

Run `flutter gen-l10n`.

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/core/text test/l10n`
Expected: PASS (including the existing ARB tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/text/duration_parts.dart lib/l10n/duration_text.dart lib/l10n/app_en.arb lib/l10n/app_vi.arb test/core/text/duration_parts_test.dart test/l10n/duration_text_test.dart
git commit -m "<DEV-n> feat(text): the shared duration formatter"
```

---

### Task 2: Overall Progress and attempt numbers

**Files:**
- Create: `lib/features/topik/domain/models/topik_test_progress_model.dart`
- Test: `test/features/topik/domain/topik_test_progress_test.dart`

**Interfaces:**
- Consumes: `TopikAttempt` (plan 2).
- Produces:
  - `final class TopikTestProgress { int sessions; int completed; int? completionPercent; int? accuracyPercent; int? bestScore; int? averageScore; DateTime? lastActivityAt; int totalTimeMs; bool get isEmpty; }`
  - `TopikTestProgress topikTestProgressOf(Iterable<TopikAttempt> attempts)`
  - `final class TopikNumberedAttempt { TopikAttempt attempt; int number; }`
  - `List<TopikNumberedAttempt> topikNumberedAttemptsOf(Iterable<TopikAttempt> attempts)` — newest first, `#1` the oldest.
  - `const int topikRecentAttemptCount = 5;`

- [ ] **Step 1: Write the failing test**

`test/features/topik/domain/topik_test_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';

TopikAttempt _attempt(
  String id, {
  required int startedMinute,
  int? score,
  int correct = 0,
  int timeMs = 0,
}) {
  final started = DateTime.utc(2026, 10, 15, 9, startedMinute);
  final completed = score != null;
  return TopikAttempt(
    id: id,
    testId: 'T',
    level: TopikLevel.topik2,
    section: TopikSection.reading,
    round: 96,
    mode: TopikAttemptMode.practice,
    status: completed
        ? TopikAttemptStatus.completed
        : TopikAttemptStatus.inProgress,
    startedAt: started,
    completedAt: completed ? started.add(const Duration(minutes: 1)) : null,
    updatedAt: started.add(const Duration(minutes: 1)),
    totalTimeMs: timeMs,
    currentQuestionNo: 1,
    questionCount: 50,
    maxScore: 100,
    score: score,
    correctCount: completed ? correct : null,
    answeredCount: completed ? 50 : null,
    contentVersion: 1,
  );
}

// BR-TOPIK-020, BR-TOPIK-021, spec §6.1–§6.2.
void main() {
  test('no attempt is the empty state', () {
    final progress = topikTestProgressOf(const []);
    expect(progress.isEmpty, isTrue);
    expect(progress.sessions, 0);
    expect(progress.totalTimeMs, 0);
    expect(progress.bestScore, isNull);
  });

  test('only an attempt in progress has no score figures', () {
    final progress = topikTestProgressOf([
      _attempt('a', startedMinute: 0, timeMs: 5000),
    ]);
    expect(progress.sessions, 1);
    expect(progress.completed, 0);
    expect(progress.completionPercent, 0);
    expect(progress.accuracyPercent, isNull);
    expect(progress.bestScore, isNull);
    expect(progress.averageScore, isNull);
    expect(progress.totalTimeMs, 5000);
  });

  test('scores use completed attempts only; time uses every attempt', () {
    final progress = topikTestProgressOf([
      _attempt('a', startedMinute: 0, score: 60, correct: 30, timeMs: 1000),
      _attempt('b', startedMinute: 1, score: 81, correct: 41, timeMs: 2000),
      _attempt('c', startedMinute: 2, timeMs: 4000),
    ]);
    expect(progress.sessions, 3);
    expect(progress.completed, 2);
    expect(progress.completionPercent, 67); // 66.7 rounds half up
    expect(progress.accuracyPercent, 71); // 71 / 100
    expect(progress.bestScore, 81);
    expect(progress.averageScore, 71); // 70.5 rounds half up
    expect(progress.lastActivityAt, DateTime.utc(2026, 10, 15, 9, 3));
    expect(progress.totalTimeMs, 7000);
  });

  test('numbers follow start order, ties by id; the list is newest first', () {
    final numbered = topikNumberedAttemptsOf([
      _attempt('b', startedMinute: 0),
      _attempt('c', startedMinute: 5),
      _attempt('a', startedMinute: 0),
    ]);
    expect(
      [for (final n in numbered) (n.attempt.id, n.number)],
      [('c', 3), ('b', 2), ('a', 1)],
    );
  });

  test('deleting an attempt renumbers the rest', () {
    final numbered = topikNumberedAttemptsOf([
      _attempt('b', startedMinute: 1),
      _attempt('c', startedMinute: 2),
    ]);
    expect([for (final n in numbered) n.number], [2, 1]);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_test_progress_test.dart`
Expected: FAIL — the model file does not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/domain/models/topik_test_progress_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';

/// How many attempts Recent Attempts shows (BR-TOPIK-021).
const int topikRecentAttemptCount = 5;

/// The Overall Progress card of one test (BR-TOPIK-020, spec §6.1). Score
/// figures use completed attempts only; time and sessions use every attempt.
/// A figure with nothing to show is null.
final class TopikTestProgress {
  const TopikTestProgress({
    required this.sessions,
    required this.completed,
    required this.completionPercent,
    required this.accuracyPercent,
    required this.bestScore,
    required this.averageScore,
    required this.lastActivityAt,
    required this.totalTimeMs,
  });

  final int sessions;
  final int completed;
  final int? completionPercent;
  final int? accuracyPercent;
  final int? bestScore;
  final int? averageScore;
  final DateTime? lastActivityAt;
  final int totalTimeMs;

  /// No attempt at all: the card becomes an empty state with Start.
  bool get isEmpty => sessions == 0;
}

TopikTestProgress topikTestProgressOf(Iterable<TopikAttempt> attempts) {
  var sessions = 0;
  var totalTimeMs = 0;
  DateTime? lastActivityAt;
  final scores = <int>[];
  var correct = 0;
  var questions = 0;
  for (final attempt in attempts) {
    sessions++;
    totalTimeMs += attempt.totalTimeMs;
    if (lastActivityAt == null || attempt.updatedAt.isAfter(lastActivityAt)) {
      lastActivityAt = attempt.updatedAt;
    }
    final score = attempt.score;
    if (!attempt.isCompleted || score == null) continue;
    scores.add(score);
    correct += attempt.correctCount ?? 0;
    questions += attempt.questionCount;
  }
  return TopikTestProgress(
    sessions: sessions,
    completed: scores.length,
    completionPercent: _percent(scores.length, sessions),
    accuracyPercent: _percent(correct, questions),
    bestScore: scores.isEmpty ? null : scores.reduce((a, b) => a > b ? a : b),
    averageScore: scores.isEmpty
        ? null
        : _roundHalfUp(scores.fold(0, (sum, s) => sum + s), scores.length),
    lastActivityAt: lastActivityAt,
    totalTimeMs: totalTimeMs,
  );
}

/// An attempt and its `#n`: its rank among the test's current attempts by
/// start time (BR-TOPIK-021).
final class TopikNumberedAttempt {
  const TopikNumberedAttempt({required this.attempt, required this.number});

  final TopikAttempt attempt;
  final int number;
}

/// [attempts] numbered from the oldest (`#1`), listed newest first. A tie in
/// start time goes to the id (UUID v7, creation order).
List<TopikNumberedAttempt> topikNumberedAttemptsOf(
  Iterable<TopikAttempt> attempts,
) {
  final oldestFirst = [...attempts]
    ..sort((a, b) {
      final byStart = a.startedAt.compareTo(b.startedAt);
      return byStart != 0 ? byStart : a.id.compareTo(b.id);
    });
  return [
    for (var i = oldestFirst.length - 1; i >= 0; i--)
      TopikNumberedAttempt(attempt: oldestFirst[i], number: i + 1),
  ];
}

/// [part] of [whole] as a whole percent, rounded half up; null when [whole]
/// is 0.
int? _percent(int part, int whole) =>
    whole == 0 ? null : _roundHalfUp(part * 100, whole);

int _roundHalfUp(int numerator, int denominator) =>
    (2 * numerator + denominator) ~/ (2 * denominator);
```

- [ ] **Step 4: Run the test**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/topik/domain/models/topik_test_progress_model.dart test/features/topik/domain/topik_test_progress_test.dart
git commit -m "<DEV-n> feat(topik): overall progress and attempt numbers"
```

---

### Task 3: The Summary figures and the per-type statistics

**Files:**
- Create: `lib/features/topik/domain/models/topik_attempt_summary_model.dart`
- Test: `test/features/topik/domain/topik_attempt_summary_test.dart`

**Interfaces:**
- Consumes: `TopikAttemptDetail`, `TopikAttemptAnswer`, `TopikAnswerStatus`, `TopikQuestionType`.
- Produces:
  - `enum TopikAnswerFilter { all, wrong, unanswered, correct }`
  - `final class TopikTypeStat { TopikQuestionType type; int correct; int total; }`
  - `final class TopikAttemptSummary { int score; int maxScore; int correctCount; int questionCount; int answeredCount; int get unansweredCount; int accuracyPercent; TopikAttemptAnswer? longest; List<TopikTypeStat> typeStats; TopikQuestionType? weakestType; List<TopikAttemptAnswer> answers; List<TopikAttemptAnswer> answersFor(TopikAnswerFilter filter); }`
  - `TopikAttemptSummary topikAttemptSummaryOf(TopikAttemptDetail detail)` — `ArgumentError` when the attempt is not completed.

- [ ] **Step 1: Write the failing test**

`test/features/topik/domain/topik_attempt_summary_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';

const _fill = TopikQuestionType.r2GrammarBlank;
const _topic = TopikQuestionType.r2AdTopic;

TopikAttemptAnswer _answer(
  int no, {
  int? selected,
  int correct = 1,
  int timeMs = 0,
  TopikQuestionType? type = _fill,
}) => TopikAttemptAnswer(
  questionNo: no,
  selectedIdx: selected,
  timeSpentMs: timeMs,
  answeredAt: selected == null ? null : DateTime.utc(2026, 10, 15),
  correctIdx: correct,
  points: 2,
  pointsEarned: selected == correct ? 2 : 0,
  questionType: type,
);

TopikAttemptDetail _detail(
  List<TopikAttemptAnswer> answers, {
  TopikAttemptStatus status = TopikAttemptStatus.completed,
}) {
  final correct = answers.where((a) => a.selectedIdx == a.correctIdx).length;
  final answered = answers.where((a) => a.selectedIdx != null).length;
  final completed = status == TopikAttemptStatus.completed;
  return TopikAttemptDetail(
    attempt: TopikAttempt(
      id: 'A',
      testId: 'T',
      level: TopikLevel.topik2,
      section: TopikSection.reading,
      round: 96,
      mode: TopikAttemptMode.practice,
      status: status,
      startedAt: DateTime.utc(2026, 10, 15),
      completedAt: completed ? DateTime.utc(2026, 10, 15, 1) : null,
      updatedAt: DateTime.utc(2026, 10, 15, 1),
      totalTimeMs: answers.fold(0, (s, a) => s + a.timeSpentMs),
      currentQuestionNo: 1,
      questionCount: answers.length,
      maxScore: answers.length * 2,
      score: completed ? correct * 2 : null,
      correctCount: completed ? correct : null,
      answeredCount: completed ? answered : null,
      contentVersion: 1,
    ),
    answers: answers,
  );
}

// BR-TOPIK-023, BR-TOPIK-024, spec §6.4.
void main() {
  test('figures, filters and the longest question', () {
    final summary = topikAttemptSummaryOf(
      _detail([
        _answer(1, selected: 1, timeMs: 3000),
        _answer(2, selected: 2, timeMs: 9000),
        _answer(3, timeMs: 9000),
        _answer(4, selected: 1, timeMs: 1000),
      ]),
    );
    expect(summary.score, 4);
    expect(summary.maxScore, 8);
    expect(summary.correctCount, 2);
    expect(summary.answeredCount, 3);
    expect(summary.unansweredCount, 1);
    expect(summary.accuracyPercent, 50);
    expect(summary.longest!.questionNo, 2); // tie 9000 ms goes to the lower number
    expect(
      [for (final a in summary.answersFor(TopikAnswerFilter.wrong)) a.questionNo],
      [2],
    );
    expect(
      [
        for (final a in summary.answersFor(TopikAnswerFilter.unanswered))
          a.questionNo,
      ],
      [3],
    );
    expect(summary.answersFor(TopikAnswerFilter.correct), hasLength(2));
    expect(summary.answersFor(TopikAnswerFilter.all), hasLength(4));
  });

  test('no time at all names no longest question', () {
    final summary = topikAttemptSummaryOf(_detail([_answer(1), _answer(2)]));
    expect(summary.longest, isNull);
  });

  test('per type, and the weakest among types with two questions', () {
    final summary = topikAttemptSummaryOf(
      _detail([
        _answer(1, selected: 1, type: _topic),
        _answer(2, selected: 2, type: _topic),
        _answer(3, selected: 1),
        _answer(4, selected: 1),
        _answer(5, selected: 1),
        _answer(6, selected: 2),
      ]),
    );
    expect(
      [for (final s in summary.typeStats) (s.type, s.correct, s.total)],
      [(_fill, 3, 4), (_topic, 1, 2)], // enum order: grammar blank first
    );
    expect(summary.weakestType, _topic); // 50% < 75%
  });

  test('a tie in accuracy goes to the type with more questions', () {
    final summary = topikAttemptSummaryOf(
      _detail([
        _answer(1, selected: 1, type: _topic),
        _answer(2, selected: 2, type: _topic),
        _answer(3, selected: 1),
        _answer(4, selected: 1),
        _answer(5, selected: 2),
        _answer(6, selected: 2),
      ]),
    );
    expect(summary.weakestType, _fill); // both 50%, fill has 4
  });

  test('no weakest type when no type has two questions or all are right', () {
    expect(
      topikAttemptSummaryOf(
        _detail([_answer(1, selected: 2, type: _topic), _answer(2, selected: 2)]),
      ).weakestType,
      isNull,
    );
    expect(
      topikAttemptSummaryOf(
        _detail([_answer(1, selected: 1), _answer(2, selected: 1)]),
      ).weakestType,
      isNull,
    );
  });

  test('an unknown type is left out of the table', () {
    final summary = topikAttemptSummaryOf(
      _detail([_answer(1, selected: 1, type: null), _answer(2, selected: 1)]),
    );
    expect([for (final s in summary.typeStats) s.type], [_fill]);
  });

  test('an attempt in progress has no summary', () {
    expect(
      () => topikAttemptSummaryOf(
        _detail([_answer(1)], status: TopikAttemptStatus.inProgress),
      ),
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_attempt_summary_test.dart`
Expected: FAIL — the model file does not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/domain/models/topik_attempt_summary_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_status_model.dart';
import 'package:memox/features/topik/domain/models/topik_question_type_model.dart';

/// The Summary's question filter (BR-TOPIK-023).
enum TopikAnswerFilter { all, wrong, unanswered, correct }

/// Correct answers out of the questions of one type (BR-TOPIK-024).
final class TopikTypeStat {
  const TopikTypeStat({
    required this.type,
    required this.correct,
    required this.total,
  });

  final TopikQuestionType type;
  final int correct;
  final int total;
}

/// What Summary shows of a submitted attempt, from its snapshot alone
/// (BR-TOPIK-019, BR-TOPIK-023, BR-TOPIK-024).
final class TopikAttemptSummary {
  const TopikAttemptSummary({
    required this.score,
    required this.maxScore,
    required this.correctCount,
    required this.questionCount,
    required this.answeredCount,
    required this.accuracyPercent,
    required this.longest,
    required this.typeStats,
    required this.weakestType,
    required this.answers,
  });

  final int score;
  final int maxScore;
  final int correctCount;
  final int questionCount;
  final int answeredCount;
  final int accuracyPercent;

  /// The question that took the most time, ties to the lower number; null
  /// when no question took any time.
  final TopikAttemptAnswer? longest;

  /// One row per type in the attempt, in enum order; types this build does
  /// not know are left out.
  final List<TopikTypeStat> typeStats;
  final TopikQuestionType? weakestType;

  /// Every answer in question order.
  final List<TopikAttemptAnswer> answers;

  int get unansweredCount => questionCount - answeredCount;

  List<TopikAttemptAnswer> answersFor(TopikAnswerFilter filter) {
    final wanted = switch (filter) {
      TopikAnswerFilter.all => null,
      TopikAnswerFilter.wrong => TopikAnswerStatus.wrong,
      TopikAnswerFilter.unanswered => TopikAnswerStatus.unanswered,
      TopikAnswerFilter.correct => TopikAnswerStatus.correct,
    };
    if (wanted == null) return answers;
    return [
      for (final answer in answers)
        if (answer.status == wanted) answer,
    ];
  }
}

/// A type needs this many questions to be named the weakest (BR-TOPIK-024).
const int _weakestTypeMinQuestions = 2;

TopikAttemptSummary topikAttemptSummaryOf(TopikAttemptDetail detail) {
  final attempt = detail.attempt;
  final score = attempt.score;
  final correctCount = attempt.correctCount;
  final answeredCount = attempt.answeredCount;
  if (!attempt.isCompleted ||
      score == null ||
      correctCount == null ||
      answeredCount == null) {
    throw ArgumentError.value(attempt.id, 'detail', 'is not submitted');
  }
  final answers = [...detail.answers]
    ..sort((a, b) => a.questionNo.compareTo(b.questionNo));
  final typeStats = _typeStatsOf(answers);
  return TopikAttemptSummary(
    score: score,
    maxScore: attempt.maxScore,
    correctCount: correctCount,
    questionCount: attempt.questionCount,
    answeredCount: answeredCount,
    accuracyPercent:
        (2 * correctCount * 100 + attempt.questionCount) ~/
        (2 * attempt.questionCount),
    longest: _longestOf(answers),
    typeStats: typeStats,
    weakestType: _weakestOf(typeStats),
    answers: answers,
  );
}

TopikAttemptAnswer? _longestOf(List<TopikAttemptAnswer> byNumber) {
  TopikAttemptAnswer? longest;
  for (final answer in byNumber) {
    if (answer.timeSpentMs <= (longest?.timeSpentMs ?? 0)) continue;
    longest = answer;
  }
  return longest;
}

List<TopikTypeStat> _typeStatsOf(List<TopikAttemptAnswer> answers) {
  final correct = <TopikQuestionType, int>{};
  final total = <TopikQuestionType, int>{};
  for (final answer in answers) {
    final type = answer.questionType;
    if (type == null) continue;
    total[type] = (total[type] ?? 0) + 1;
    if (answer.status == TopikAnswerStatus.correct) {
      correct[type] = (correct[type] ?? 0) + 1;
    }
  }
  return [
    for (final type in TopikQuestionType.values)
      if (total.containsKey(type))
        TopikTypeStat(
          type: type,
          correct: correct[type] ?? 0,
          total: total[type]!,
        ),
  ];
}

TopikQuestionType? _weakestOf(List<TopikTypeStat> stats) {
  TopikTypeStat? weakest;
  for (final stat in stats) {
    if (stat.total < _weakestTypeMinQuestions) continue;
    if (stat.correct == stat.total) continue;
    if (weakest == null || _isWeaker(stat, weakest)) weakest = stat;
  }
  return weakest?.type;
}

/// Lower accuracy first, then more questions; [stats] come in enum order, so
/// an exact tie keeps the earlier type.
bool _isWeaker(TopikTypeStat a, TopikTypeStat b) {
  final left = a.correct * b.total;
  final right = b.correct * a.total;
  if (left != right) return left < right;
  return a.total > b.total;
}
```

- [ ] **Step 4: Run the test**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/topik/domain/models/topik_attempt_summary_model.dart test/features/topik/domain/topik_attempt_summary_test.dart
git commit -m "<DEV-n> feat(topik): summary figures and per-type statistics"
```

---

### Task 4: The test list and its order

**Files:**
- Create: `lib/features/topik/domain/models/topik_catalog_model.dart`
- Test: `test/features/topik/domain/topik_catalog_test.dart`

**Interfaces:**
- Consumes: `TopikTest`, `TopikTestStatus`, `TopikLevel`, `TopikSection`.
- Produces:
  - `enum TopikTestOrder { roundDescending, roundAscending, latestActivity }`
  - `final class TopikCatalogEntry { TopikTest test; TopikTestStatus? status; }`
  - `List<TopikCatalogEntry> topikCatalogEntriesOf(List<TopikTest> tests, Map<String, TopikTestStatus> statuses)`
  - `List<TopikCatalogEntry> topikTestsOf(List<TopikCatalogEntry> entries, {required TopikLevel level, required TopikSection section, required TopikTestOrder order})`

- [ ] **Step 1: Write the failing test**

`test/features/topik/domain/topik_catalog_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

import '../../../support/topik_content_fixtures.dart';

TopikTestStatus _status(String testId, DateTime at) => TopikTestStatus(
  testId: testId,
  hasInProgress: false,
  completedCount: 1,
  bestScore: 80,
  lastActivityAt: at,
);

// BR-TOPIK-022, spec §6.3.
void main() {
  final r91 = topikTestFixture(round: 91);
  final r96 = topikTestFixture(round: 96);
  final r83 = topikTestFixture(round: 83);
  final listening = topikTestFixture(section: TopikSection.listening);
  final entries = topikCatalogEntriesOf(
    [r91, r96, r83, listening],
    {
      r83.testId: _status(r83.testId, DateTime.utc(2026, 10, 2)),
      r91.testId: _status(r91.testId, DateTime.utc(2026, 10, 5)),
    },
  );

  List<int> rounds(TopikTestOrder order) => [
    for (final e in topikTestsOf(
      entries,
      level: TopikLevel.topik2,
      section: TopikSection.reading,
      order: order,
    ))
      e.test.round,
  ];

  test('each entry carries its status, or none when never taken', () {
    expect(entries.firstWhere((e) => e.test.round == 96).status, isNull);
    expect(entries.firstWhere((e) => e.test.round == 91).status, isNotNull);
  });

  test('one level and section, by round', () {
    expect(rounds(TopikTestOrder.roundDescending), [96, 91, 83]);
    expect(rounds(TopikTestOrder.roundAscending), [83, 91, 96]);
  });

  test('latest activity first; tests never taken last, by round descending', () {
    expect(rounds(TopikTestOrder.latestActivity), [91, 83, 96]);
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_catalog_test.dart`
Expected: FAIL — the model file does not exist.

- [ ] **Step 3: Implement**

`lib/features/topik/domain/models/topik_catalog_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_level_model.dart';
import 'package:memox/features/topik/domain/models/topik_section_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_status_model.dart';

/// The test list's sort (BR-TOPIK-022); round descending is the default.
enum TopikTestOrder { roundDescending, roundAscending, latestActivity }

/// A test with the person's status on it; null when never taken.
final class TopikCatalogEntry {
  const TopikCatalogEntry({required this.test, required this.status});

  final TopikTest test;
  final TopikTestStatus? status;
}

List<TopikCatalogEntry> topikCatalogEntriesOf(
  List<TopikTest> tests,
  Map<String, TopikTestStatus> statuses,
) => [
  for (final test in tests)
    TopikCatalogEntry(test: test, status: statuses[test.testId]),
];

/// The tests of one [level] and [section] in [order]. Under latest activity,
/// tests never taken come last, by round descending.
List<TopikCatalogEntry> topikTestsOf(
  List<TopikCatalogEntry> entries, {
  required TopikLevel level,
  required TopikSection section,
  required TopikTestOrder order,
}) {
  int byRoundDescending(TopikCatalogEntry a, TopikCatalogEntry b) =>
      b.test.round.compareTo(a.test.round);
  final picked = [
    for (final entry in entries)
      if (entry.test.level == level && entry.test.section == section) entry,
  ];
  return picked
    ..sort(switch (order) {
      TopikTestOrder.roundDescending => byRoundDescending,
      TopikTestOrder.roundAscending => (a, b) => byRoundDescending(b, a),
      TopikTestOrder.latestActivity => (a, b) {
        final left = a.status?.lastActivityAt;
        final right = b.status?.lastActivityAt;
        if (left == null && right == null) return byRoundDescending(a, b);
        if (left == null) return 1;
        if (right == null) return -1;
        final byActivity = right.compareTo(left);
        return byActivity != 0 ? byActivity : byRoundDescending(a, b);
      },
    });
}
```

- [ ] **Step 4: Run the test**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/topik/domain/models/topik_catalog_model.dart test/features/topik/domain/topik_catalog_test.dart
git commit -m "<DEV-n> feat(topik): the test list and its order"
```

---

### Task 5: The use cases

**Files:**
- Modify: `lib/features/topik/domain/failures/topik_failure.dart` (`testUnavailable`)
- Create: `lib/features/topik/domain/models/topik_views_model.dart`
- Create: `lib/features/topik/domain/usecases/watch_topik_catalog_use_case.dart`, `watch_topik_test_detail_use_case.dart`, `start_topik_attempt_use_case.dart`, `watch_topik_attempt_use_case.dart`, `answer_topik_question_use_case.dart`, `move_topik_question_use_case.dart`, `record_topik_time_use_case.dart`, `submit_topik_attempt_use_case.dart`, `delete_topik_attempt_use_case.dart`, `watch_topik_summary_use_case.dart`, `watch_topik_review_use_case.dart`
- Create: `test/support/topik_fakes.dart`
- Test: `test/features/topik/domain/topik_use_cases_test.dart`

**Interfaces:**
- Consumes: `TopikContentRepository.catalog()`, `TopikAttemptRepository` (plan 2), Tasks 2–4.
- Produces (`topik_views_model.dart`):
  - `final class TopikTestDetail { TopikTest? test; TopikTestProgress progress; List<TopikNumberedAttempt> attempts; TopikNumberedAttempt? inProgress; List<TopikNumberedAttempt> get recent; }`
  - `final class TopikAttemptView { TopikAttemptDetail detail; TopikTest? test; }`
  - `final class TopikSummaryView { TopikAttempt attempt; TopikAttemptSummary summary; TopikTest? test; }`
  - `final class TopikReviewView { TopikAttemptDetail detail; TopikTest? test; bool get isContentChanged; bool get isUnavailable; }`
- Use cases (each `final class` with `const` constructor and `call`):
  - `WatchTopikCatalogUseCase(content, attempts)`: `Stream<List<TopikCatalogEntry>> call()`
  - `WatchTopikTestDetailUseCase(content, attempts)`: `Stream<TopikTestDetail> call(String testId)`
  - `StartTopikAttemptUseCase(content, attempts)`: `Future<Outcome<TopikAttempt, TopikRejection>> call(String testId, {bool replaceInProgress = false})`
  - `WatchTopikAttemptUseCase(content, attempts)`: `Stream<TopikAttemptView?> call(String attemptId)`
  - `AnswerTopikQuestionUseCase(attempts)`: `Future<Outcome<void, TopikRejection>> call({required String attemptId, required int questionNo, required int selectedIdx, required int elapsedMs})`
  - `MoveTopikQuestionUseCase(attempts)`: `Future<Outcome<void, TopikRejection>> call({required String attemptId, required int toQuestionNo, required int elapsedMs})`
  - `RecordTopikTimeUseCase(attempts)`: `Future<Outcome<void, TopikRejection>> call({required String attemptId, required int elapsedMs})`
  - `SubmitTopikAttemptUseCase(content, attempts)`: `Future<Outcome<TopikAttempt, TopikRejection>> call({required String attemptId, required String testId, required int elapsedMs})`
  - `DeleteTopikAttemptUseCase(attempts)`: `Future<Outcome<void, TopikRejection>> call(String attemptId)`
  - `WatchTopikSummaryUseCase(content, attempts)`: `Stream<TopikSummaryView?> call(String attemptId)` — null when gone or not submitted
  - `WatchTopikReviewUseCase(content, attempts)`: `Stream<TopikReviewView?> call(String attemptId)` — null when gone

- [ ] **Step 1: Write the fakes and the failing test**

`test/support/topik_fakes.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// A catalog of the given tests; a test can change it between reads.
final class FakeTopikContentRepository implements TopikContentRepository {
  FakeTopikContentRepository(this.tests);

  List<TopikTest> tests;

  @override
  Future<List<TopikTest>> catalog() async => tests;
}
```

`test/features/topik/domain/topik_use_cases_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart' show AppDatabase;
import 'package:memox/features/topik/data/repositories/topik_attempt_repository_impl.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/usecases/answer_topik_question_use_case.dart';
import 'package:memox/features/topik/domain/usecases/delete_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/start_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/submit_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_attempt_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_catalog_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_review_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_summary_use_case.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

import '../../../support/test_database.dart';
import '../../../support/topik_attempt_fixtures.dart';
import '../../../support/topik_content_fixtures.dart';
import '../../../support/topik_fakes.dart';

// Spec §3.3: one use case per interaction, over the real attempt store.
void main() {
  final content = topikTestFixture();
  late AppDatabase db;
  late TopikAttemptRepositoryImpl attempts;
  late FakeTopikContentRepository catalog;
  setUp(() {
    db = openTestDatabase();
    attempts = TopikAttemptRepositoryImpl(db);
    catalog = FakeTopikContentRepository([content]);
  });
  tearDown(() => db.close());

  test('the catalog carries each test with its status', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    topikOk(await start(content.testId));

    final entries = await WatchTopikCatalogUseCase(catalog, attempts)().first;

    expect(entries.single.test.testId, content.testId);
    expect(entries.single.status!.hasInProgress, isTrue);
  });

  test('Start refuses a test the catalog no longer has (BR-TOPIK-019)', () async {
    expect(
      topikReason(await StartTopikAttemptUseCase(catalog, attempts)('gone')),
      TopikRejection.testUnavailable,
    );
  });

  test('Start new replaces the attempt in progress (BR-TOPIK-011)', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    final first = topikOk(await start(content.testId));
    expect(
      topikReason(await start(content.testId)),
      TopikRejection.inProgressExists,
    );
    final second = topikOk(
      await start(content.testId, replaceInProgress: true),
    );
    expect(second.id, isNot(first.id));
  });

  test('the test detail numbers attempts and keeps the one in progress', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    final submit = SubmitTopikAttemptUseCase(catalog, attempts);
    final done = topikOk(await start(content.testId));
    topikOk(
      await submit(attemptId: done.id, testId: content.testId, elapsedMs: 0),
    );
    final open = topikOk(await start(content.testId));

    final detail = await WatchTopikTestDetailUseCase(
      catalog,
      attempts,
    )(content.testId).first;

    expect(detail.test, isNotNull);
    expect([for (final n in detail.attempts) n.number], [2, 1]);
    expect(detail.inProgress!.attempt.id, open.id);
    expect(detail.progress.sessions, 2);
    expect(detail.recent, hasLength(2));
  });

  test('submit, then summary and review read the attempt', () async {
    final start = StartTopikAttemptUseCase(catalog, attempts);
    final attempt = topikOk(await start(content.testId));
    topikOk(
      await AnswerTopikQuestionUseCase(attempts)(
        attemptId: attempt.id,
        questionNo: 1,
        selectedIdx: 1,
        elapsedMs: 700,
      ),
    );
    final view = await WatchTopikAttemptUseCase(catalog, attempts)(
      attempt.id,
    ).first;
    expect(view!.detail.answers.first.selectedIdx, 1);
    expect(
      await WatchTopikSummaryUseCase(catalog, attempts)(attempt.id).first,
      isNull,
    );

    topikOk(
      await SubmitTopikAttemptUseCase(catalog, attempts)(
        attemptId: attempt.id,
        testId: content.testId,
        elapsedMs: 0,
      ),
    );

    final summary = (await WatchTopikSummaryUseCase(
      catalog,
      attempts,
    )(attempt.id).first)!;
    expect(summary.summary.score, 2);
    final review = (await WatchTopikReviewUseCase(
      catalog,
      attempts,
    )(attempt.id).first)!;
    expect(review.isContentChanged, isFalse);
    expect(review.isUnavailable, isFalse);
  });

  test('review flags newer content, and an unavailable test', () async {
    final attempt = topikOk(
      await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
    );
    topikOk(
      await SubmitTopikAttemptUseCase(catalog, attempts)(
        attemptId: attempt.id,
        testId: content.testId,
        elapsedMs: 0,
      ),
    );
    final json = topikTestJson()..['contentVersion'] = 2;
    catalog.tests = [topikTestOfFixtureJson(json)];
    final changed = (await WatchTopikReviewUseCase(
      catalog,
      attempts,
    )(attempt.id).first)!;
    expect(changed.isContentChanged, isTrue);

    catalog.tests = [];
    final gone = (await WatchTopikReviewUseCase(
      catalog,
      attempts,
    )(attempt.id).first)!;
    expect(gone.isUnavailable, isTrue);
    expect(
      (await WatchTopikSummaryUseCase(catalog, attempts)(attempt.id).first)!
          .summary
          .score,
      0,
    );
  });

  test('submit refuses when the test is unavailable; delete removes', () async {
    final attempt = topikOk(
      await StartTopikAttemptUseCase(catalog, attempts)(content.testId),
    );
    catalog.tests = [];
    expect(
      topikReason(
        await SubmitTopikAttemptUseCase(catalog, attempts)(
          attemptId: attempt.id,
          testId: content.testId,
          elapsedMs: 0,
        ),
      ),
      TopikRejection.testUnavailable,
    );
    topikOk(await DeleteTopikAttemptUseCase(attempts)(attempt.id));
    expect(
      await WatchTopikAttemptUseCase(catalog, attempts)(attempt.id).first,
      isNull,
    );
  });
}
```

- [ ] **Step 2: Run it to verify it fails**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik/domain/topik_use_cases_test.dart`
Expected: FAIL — the use case files do not exist.

- [ ] **Step 3: Implement**

`topik_failure.dart`, append to the enum:

```dart

  /// The attempt's test is no longer in the catalog, or no longer valid:
  /// it cannot start, continue or be submitted; it can be deleted
  /// (BR-TOPIK-019).
  testUnavailable,
```

`lib/features/topik/domain/models/topik_views_model.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';

/// Test detail (screen 36): the test, its Overall Progress and every
/// attempt numbered, newest first (BR-TOPIK-020, BR-TOPIK-021). [test] is
/// null when the catalog no longer has it (BR-TOPIK-019).
final class TopikTestDetail {
  const TopikTestDetail({
    required this.test,
    required this.progress,
    required this.attempts,
  });

  final TopikTest? test;
  final TopikTestProgress progress;
  final List<TopikNumberedAttempt> attempts;

  /// The one attempt in progress on this device, if any (BR-TOPIK-011).
  TopikNumberedAttempt? get inProgress {
    for (final numbered in attempts) {
      if (!numbered.attempt.isCompleted) return numbered;
    }
    return null;
  }

  List<TopikNumberedAttempt> get recent =>
      attempts.take(topikRecentAttemptCount).toList();
}

/// The attempt screen's data (screen 37); [test] null when unavailable.
final class TopikAttemptView {
  const TopikAttemptView({required this.detail, required this.test});

  final TopikAttemptDetail detail;
  final TopikTest? test;
}

/// Summary (screen 38): from the snapshot alone; [test] only names it.
final class TopikSummaryView {
  const TopikSummaryView({
    required this.attempt,
    required this.summary,
    required this.test,
  });

  final TopikAttempt attempt;
  final TopikAttemptSummary summary;
  final TopikTest? test;
}

/// Review (screen 39): the attempt over the current content
/// (BR-TOPIK-019).
final class TopikReviewView {
  const TopikReviewView({required this.detail, required this.test});

  final TopikAttemptDetail detail;
  final TopikTest? test;

  /// The test is gone or invalid: Review is unavailable, Summary still is.
  bool get isUnavailable => test == null;

  /// The content was updated after this attempt was scored.
  bool get isContentChanged =>
      test != null && test!.contentVersion != detail.attempt.contentVersion;
}
```

Each use case file below (imports of the models, repositories, `Outcome` and `TopikRejection` as used):

`watch_topik_catalog_use_case.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_catalog_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// UC-TOPIK-001: the tests with the person's status on each, again on every
/// attempt write (BR-TOPIK-022).
final class WatchTopikCatalogUseCase {
  const WatchTopikCatalogUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<List<TopikCatalogEntry>> call() =>
      Stream.fromFuture(_content.catalog()).asyncExpand(
        (tests) => _attempts.watchTestStatuses().map(
          (statuses) => topikCatalogEntriesOf(tests, statuses),
        ),
      );
}
```

`watch_topik_test_detail_use_case.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_test_model.dart';
import 'package:memox/features/topik/domain/models/topik_test_progress_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';

/// UC-TOPIK-002: Overall Progress, Recent Attempts and History of one test.
final class WatchTopikTestDetailUseCase {
  const WatchTopikTestDetailUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikTestDetail> call(String testId) =>
      Stream.fromFuture(topikTestIn(_content, testId)).asyncExpand(
        (test) => _attempts
            .watchAttemptsOfTest(testId)
            .map(
              (attempts) => TopikTestDetail(
                test: test,
                progress: topikTestProgressOf(attempts),
                attempts: topikNumberedAttemptsOf(attempts),
              ),
            ),
      );
}

/// The valid test [testId] of the catalog, or null (BR-TOPIK-019).
Future<TopikTest?> topikTestIn(
  TopikContentRepository content,
  String testId,
) async {
  for (final test in await content.catalog()) {
    if (test.testId == testId) return test;
  }
  return null;
}
```

`start_topik_attempt_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-003 start: a new attempt of a valid test; with
/// [replaceInProgress] (Start new, confirmed) the attempt in progress is
/// replaced in one write (BR-TOPIK-010, BR-TOPIK-011, BR-TOPIK-019).
final class StartTopikAttemptUseCase {
  const StartTopikAttemptUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Future<Outcome<TopikAttempt, TopikRejection>> call(
    String testId, {
    bool replaceInProgress = false,
  }) async {
    final test = await topikTestIn(_content, testId);
    if (test == null) return const Rejected(TopikRejection.testUnavailable);
    if (replaceInProgress) {
      return Ok(await _attempts.replaceInProgressAndStart(test));
    }
    return _attempts.start(test);
  }
}
```

`watch_topik_attempt_use_case.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-003: the attempt with its answers and its test; null once the
/// attempt is gone (BR-TOPIK-018, BR-TOPIK-027).
final class WatchTopikAttemptUseCase {
  const WatchTopikAttemptUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikAttemptView?> call(String attemptId) => _attempts
      .watchAttempt(attemptId)
      .asyncMap(
        (detail) async => detail == null
            ? null
            : TopikAttemptView(
                detail: detail,
                test: await topikTestIn(_content, detail.attempt.testId),
              ),
      );
}
```

`answer_topik_question_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-003: choose an option, replacing an earlier one (BR-TOPIK-012).
final class AnswerTopikQuestionUseCase {
  const AnswerTopikQuestionUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call({
    required String attemptId,
    required int questionNo,
    required int selectedIdx,
    required int elapsedMs,
  }) => _attempts.answer(
    attemptId: attemptId,
    questionNo: questionNo,
    selectedIdx: selectedIdx,
    elapsedMs: elapsedMs,
  );
}
```

`move_topik_question_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-003: go to another question; the time of the one left is kept
/// (BR-TOPIK-015).
final class MoveTopikQuestionUseCase {
  const MoveTopikQuestionUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call({
    required String attemptId,
    required int toQuestionNo,
    required int elapsedMs,
  }) => _attempts.move(
    attemptId: attemptId,
    toQuestionNo: toQuestionNo,
    elapsedMs: elapsedMs,
  );
}
```

`record_topik_time_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// UC-TOPIK-003: background or exit; the current question keeps its time
/// (BR-TOPIK-015).
final class RecordTopikTimeUseCase {
  const RecordTopikTimeUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call({
    required String attemptId,
    required int elapsedMs,
  }) => _attempts.recordTime(attemptId: attemptId, elapsedMs: elapsedMs);
}
```

`submit_topik_attempt_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/models/topik_attempt_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-003 submit: scored against the content at submit
/// (BR-TOPIK-013); refused when that content is gone (BR-TOPIK-019).
final class SubmitTopikAttemptUseCase {
  const SubmitTopikAttemptUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Future<Outcome<TopikAttempt, TopikRejection>> call({
    required String attemptId,
    required String testId,
    required int elapsedMs,
  }) async {
    final test = await topikTestIn(_content, testId);
    if (test == null) return const Rejected(TopikRejection.testUnavailable);
    return _attempts.submit(
      attemptId: attemptId,
      test: test,
      elapsedMs: elapsedMs,
    );
  }
}
```

`delete_topik_attempt_use_case.dart`:

```dart
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/topik/domain/failures/topik_failure.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';

/// Delete an attempt, confirmed by the screen (BR-TOPIK-018).
final class DeleteTopikAttemptUseCase {
  const DeleteTopikAttemptUseCase(this._attempts);

  final TopikAttemptRepository _attempts;

  Future<Outcome<void, TopikRejection>> call(String attemptId) =>
      _attempts.delete(attemptId);
}
```

`watch_topik_summary_use_case.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_attempt_summary_model.dart';
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-004: Summary of a submitted attempt from its snapshot; null
/// when the attempt is gone or not submitted (BR-TOPIK-019, BR-TOPIK-023).
final class WatchTopikSummaryUseCase {
  const WatchTopikSummaryUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikSummaryView?> call(String attemptId) => _attempts
      .watchAttempt(attemptId)
      .asyncMap((detail) async {
        if (detail == null || !detail.attempt.isCompleted) return null;
        return TopikSummaryView(
          attempt: detail.attempt,
          summary: topikAttemptSummaryOf(detail),
          test: await topikTestIn(_content, detail.attempt.testId),
        );
      });
}
```

`watch_topik_review_use_case.dart`:

```dart
import 'package:memox/features/topik/domain/models/topik_views_model.dart';
import 'package:memox/features/topik/domain/repositories/topik_attempt_repository.dart';
import 'package:memox/features/topik/domain/repositories/topik_content_repository.dart';
import 'package:memox/features/topik/domain/usecases/watch_topik_test_detail_use_case.dart';

/// UC-TOPIK-005: the attempt over the current content, flagged when the
/// content changed or is gone (BR-TOPIK-019); null once the attempt is gone.
final class WatchTopikReviewUseCase {
  const WatchTopikReviewUseCase(this._content, this._attempts);

  final TopikContentRepository _content;
  final TopikAttemptRepository _attempts;

  Stream<TopikReviewView?> call(String attemptId) => _attempts
      .watchAttempt(attemptId)
      .asyncMap(
        (detail) async => detail == null
            ? null
            : TopikReviewView(
                detail: detail,
                test: await topikTestIn(_content, detail.attempt.testId),
              ),
      );
}
```

- [ ] **Step 4: Run the tests**

Run: `bash .claude/skills/flutter-workflow/scripts/run_tests.sh test/features/topik test/architecture`
Expected: PASS.

- [ ] **Step 5: Docs and the gate**

- `docs/features/topik/rules/BR-TOPIK-025-dinh-dang-thoi-luong-va-diem.md`: the formatter is `DurationParts` in `lib/core/text/duration_parts.dart` with its words in `lib/l10n/duration_text.dart` (as `relative_time.dart`).
- Spec §3.3: replace "Exact names are fixed by the plan." with the eleven names as built, and note that Start new is `StartTopikAttemptUseCase(…, replaceInProgress: true)`.
- Run `python3 tools/docs/check.py` and `bash .claude/skills/flutter-workflow/scripts/dod_check.sh`; both PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/topik test/features/topik test/support/topik_fakes.dart docs
git commit -m "<DEV-n> feat(topik): one use case per interaction"
```

## Plan-time rulings

| # | Ruling | Why |
|---|---|---|
| P1 | The duration's numbers are split in `lib/core/text/duration_parts.dart`; its words are ARB keys read by `lib/l10n/duration_text.dart`. | BR-TOPIK-025 places the formatter in `lib/core/text/`, and the app keeps localized phrasing in `lib/l10n/` (`relative_time.dart`). |
| P2 | Seconds are truncated, not rounded. | A running total never shows a second that has not passed; question times then never add up to more than the total. Owner question Q-P4-1. |
| P3 | Whole percents and the average round half up. | §6.1 names half-up for Average; the same rule for the percents keeps one rounding in the feature. Owner question Q-P4-2. |
| P4 | Vietnamese words: `42 giây`, `3 phút 05 giây`, `1 giờ 02 phút 11 giây`. | The compact `s`/`m`/`h` is English; the Vietnamese UI spells units out. Owner question Q-P4-3. |
| P5 | A new rejection `testUnavailable` covers Start, Continue and Submit on a test the catalog no longer has. | BR-TOPIK-019. |
| P6 | Start new is a flag on `StartTopikAttemptUseCase`, not its own class. | One interaction (Start) with a confirmed variant; the repository keeps the two writes apart. |
| P7 | Use case providers come with the screens (plan 6), in `presentation/providers/`. | The progress feature's pattern; nothing reads them before plan 6. |

## Out of this plan

Audio and `MxSlider` (plan 5); controllers, providers and screens 13, 34–39 (plan 6); the round-96 pack (plan 7).
