# MemoX V8 Progress Backend Implementation Plan (package 4)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-A7 of [`docs/wbs_BE.md`](../../wbs_BE.md), the read models of
the Progress screen (UC-PROGRESS-001, UC-PROGRESS-002), as domain, data and di
code with two use cases, so the UI session can build screen 22 of the kit on
them. No UI.

**Architecture:** In `progress/domain`, `ProgressDays` turns one read of the
clock and its UTC offset into local day numbers, and pure functions build the
overview (Today, the last seven days, the streak) and order a level's decks for
each range. In `progress/data`, `ProgressDao` folds `review_log` in SQLite: the
days with activity over the whole history, the card-days of the last seven, and
one statement per level whose deck rows and total come from the same card-days.
`ProgressRepositoryImpl` reads each screen's statements in one transaction,
again after every write to `review_log`, `card` or `deck`, through a
listen-first change stream that Study Home now shares. The two use cases read
again at each local midnight.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35. No dependency is added.

**Spec:** [`docs/superpowers/specs/2026-09-25-progress-backend-design.md`](../specs/2026-09-25-progress-backend-design.md),
approved 2026-09-25 and amended on this branch with the Clarifications below.
Business rules: `docs/features/progress/rules/` (BR-PROGRESS-001…BR-PROGRESS-018);
use cases: `docs/features/progress/usecases/`; data model:
[`docs/shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-progress` holds the spec (`2737d31`), its
approval (`75d6150`) and its amendment from the Clarifications below
(`e865a0e`), on `master` at `66d9597` (#55). This plan runs on that
branch, from the commit that adds it; the gate passes there with 1320 tests.
Generated code is not committed: in a fresh working tree, run `flutter pub get`,
`flutter gen-l10n` and `dart run build_runner build --delete-conflicting-outputs`
first (root `README.md`, "Commands").

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed, and after every task the gate
passed. Each rule the data tests pin was also broken on purpose in the scratch
copy (the `browse` filter removed, the Learning partition flipped, the offset
dropped from the day, the day moved by one second, the card's Trash filter
removed, `deck` no longer listened to, days counted with repeats, a deck's own
cards or its subtree left out): every break failed the test that names the
rule. This document was then applied, step by step as written, onto a clean
checkout of `75d6150`: each task's files matched the scratch commit's, no other
file moved, and the suite counts below are that run's.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme. Screen 22, its controllers, the routes
  and the use cases' providers are FE-A9 (spec §1, §8, §11).
- The import map gains `'progress': {}`: the feature reads core's tables and
  imports no other feature (ADR-011 D2).
- Read only: nothing on these paths writes, and no session is opened, resumed
  or closed (BR-PROGRESS-007, BR-PROGRESS-009; spec D10). No schema change
  (spec D9).
- A row's day is `(answered_at + offset) / 86400`, with `answered_at` in UTC
  seconds and the offset of the read; Dart computes every day number
  (`ProgressDays`), and SQL never derives a midnight (BR-PROGRESS-011,
  BR-PROGRESS-013; spec D3).
- A level's total is read from the statement that reads its rows, never added
  up from them (BR-PROGRESS-002; spec D5). Each emission runs its statements in
  one `transaction` (spec §6.3).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing
  `call` (AD-12).
- The day's `now` and offset come from the caller, the use cases' from a
  `DayClock`; no test reads the wall clock.
- After every scenario `expectStudyInvariants` runs every invariant query of
  `schema.md` in scope. A tree with a learned card has its scheduler locked
  (invariant 30), and a deck in the Trash takes its cards into the Trash with it
  (invariant 33, in force from BE-B1).
- After every task the phased gate of the root `README.md` passes, plus
  `tools/docs/check.py`. On Linux, `flutter test` runs with
  `--exclude-tags golden`: the goldens were made on Windows (FE-D1 in
  [`docs/wbs_FE.md`](../../wbs_FE.md)).
- The guard warns at 400 logical lines of a file and fails at 500: keep each
  file under the warning. `progress_dao.dart` ends at 150 non-blank,
  non-comment lines and `study_view_dao.dart` at 257 (the guard's own count
  decides).
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a rule or use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- Of the contract files, only the `code:` fields of UC-PROGRESS-001 and
  UC-PROGRESS-002 change (spec D11).
- Code, identifiers, test names and commit messages are in English; `docs/`
  keeps its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan and showed
where it needed a change. Each is decided here, implemented as described, and
written into the spec on this branch (`e865a0e`); say so if one is wrong.

1. **D9's measurement, and the overview's reads** (Tasks 2 and 4; spec D6, D9,
   §5.3, §6.2). A synthetic history of 10 root decks, 2,000 learned cards and
   100 answers a day was read in this container (4 cores, Xeon 2.8 GHz; a phone
   is slower), in memory and from a file. Folding every card-day of the history
   into days in one statement, as the approved spec's statement 1 did, took
   141–193 ms at 100,000 answers and 638–892 ms at 300,000. The streak needs
   only which days have activity, and only the last seven days show the split,
   so that statement becomes two: the distinct days of the whole history, and the
   card-days of the last seven with their split. The same answers come out;
   `progressOverviewOf` takes both (`activeDays`, `week`). The `/progress`
   snapshot then reads in about 100 ms at 100,000 answers and 280 ms at 300,000,
   of which the level statement takes 15 and 35 ms. No index is added (D9).
2. **The third cell of the deck list's screen handoff** (Task 6; spec D11).
   `01-deck-list.md` has three cells that wait on BE-A7, not two: the mastery
   display twice, and "Sort by progress". All three point to the blocked row,
   since the progress sort is outside BE-A7 too (D1).
3. **The blocked row's wording** (Task 6; spec D1). The card list's "mastered"
   panel that IT-ORG-010 describes is already built on BE-A9's counts
   (`card_deck_summary_widget.dart`), so the row that leaves BE-A7 names what is
   still undefined: the deck list's mastery display and its progress sort.
4. **A transaction fires once only when it is flat** (Task 3; spec §6.4). A
   repository call that runs its own transaction inside another fires once per
   call (drift nests them as savepoints). The helper's test writes twice in one
   flat transaction; no repository nests another today.
5. **Test fixtures** (Tasks 4–6). `test/support/progress_fixtures.dart` makes
   learned cards (a `scheduled` answer suits them, invariant 25), answers
   through `logReview`, and Hanoi times. Unlike package 3's fixture (its
   deferred minor), a deck put in the Trash takes its cards with it.
6. **The WBS counts** (Task 6). Tests then name 15 of the 22 use cases and 63 IT
   ids: IT-CONT 12, IT-DISC 4, IT-LEARN 10, IT-MODE 12, IT-NAV 2 (with
   IT-NAV-011), IT-ORG 3, IT-REVIEW 9, IT-STUDY 11.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **A child deck in the Trash at its parent's level**: neither listed nor
   counted — Task 5, "a child in the Trash is neither listed nor counted".
2. **An answer at 00:00:00 or 23:59:59 local**: each falls on its own day, at
   Today and at the first day of the month — Task 4, "an answer at 00:00:00
   local falls on its new day".
3. **A deck moved to another root while its level is open**: the path follows
   and the numbers stay — Task 5, "a deck moved to another root while its level
   is open".
4. **An empty deck's level**: no row and zero numbers, and not missing — Task 5,
   "an empty deck has no row and zero numbers".
5. **Progress opened while a study session is open**: the session stays open and
   nothing is written — Task 4, "opening Progress while a study session is
   open".

## File Structure

```
lib/core/database/table_changes.dart                    tableChanges (3)

lib/features/progress/
├── domain/
│   ├── models/progress_level_model.dart                 ProgressRange, ProgressNumbers,
│   │                                                    RangeProgress, ProgressDeckRow,
│   │                                                    ProgressLevel, compareProgressDecks (1)
│   ├── models/progress_days_model.dart                  ProgressDays (1)
│   ├── models/progress_overview_model.dart              ActiveDay, DayActivity, StreakState,
│   │                                                    CurrentStreak, ProgressOverview,
│   │                                                    progressOverviewOf (2)
│   ├── models/progress_model.dart                       Progress (4); DeckProgress,
│   │                                                    DeckProgressLevel, ProgressDeckMissing,
│   │                                                    ProgressPathSegment (5)
│   ├── repositories/progress_repository.dart            watchProgress (4), watchDeckProgress (5)
│   └── usecases/watch_progress_use_case.dart            WatchProgressUseCase (6)
│       usecases/watch_deck_progress_use_case.dart       WatchDeckProgressUseCase (6)
├── data/
│   ├── datasources/progress_dao.dart                    activeDays, weekActivity, rootLevel,
│   │                                                    changes (4); childLevel, deckPath (5)
│   ├── mappers/progress_mapper.dart                     activeDaysOf, levelOf (4); pathOf (5)
│   └── repositories/progress_repository_impl.dart       (4, 5)
└── di/progress_repository_provider.dart                 progressRepositoryProvider (4)

test/architecture/boundary_rules.dart                         'progress': {} (1)
test/features/progress/domain/progress_days_test.dart         (1)
test/features/progress/domain/progress_level_test.dart        (1)
test/features/progress/domain/progress_overview_test.dart     (2)
test/database/table_changes_test.dart                         (3)
test/support/progress_fixtures.dart                           (4)
test/features/progress/data/watch_progress_test.dart          (4)
test/features/progress/data/watch_progress_stream_test.dart   (4)
test/features/progress/data/watch_deck_progress_test.dart     (5)
test/features/progress/domain/watch_progress_use_case_test.dart  (6)
```

`StudyViewDao.homeChanges()` delegates to `tableChanges` (3). Other changed
files: the two use cases' `code:`, the progress README, a new
`features/progress/data.md`, `wbs_BE.md`, `wbs_FE.md` and
`shared/ui/screen-handoff/01-deck-list.md` (Task 6), and `docs/_generated/`
(every task).

---


### Task 1: The local days of a read, and a level of Progress by deck

**Files:**
- Create: `lib/features/progress/domain/models/progress_days_model.dart`, `lib/features/progress/domain/models/progress_level_model.dart`
- Test (create): `test/features/progress/domain/progress_days_test.dart`, `test/features/progress/domain/progress_level_test.dart`
- Test (modify): `test/architecture/boundary_rules.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `foldText` (`lib/core/text/folded_text.dart`).
- Produces, in `lib/features/progress/domain/models/progress_level_model.dart`:
  - `enum ProgressRange { week, month }`, with `final int days` (7 and 30).
  - `ProgressNumbers({required int activeCards, required int activeDays, required int learningCardDays, required int reviewingCardDays})`,
    with `cardDays` and `hasActivity`.
  - `RangeProgress({required ProgressNumbers week, required ProgressNumbers month})`,
    with `ProgressNumbers of(ProgressRange range)`.
  - `ProgressDeckRow({required String deckId, required String name, required RangeProgress progress})`.
  - `ProgressLevel({required RangeProgress total, required List<ProgressDeckRow> decks})`,
    with `List<ProgressDeckRow> decksFor(ProgressRange range)` and `hasDecks`.
  - `Comparator<ProgressDeckRow> compareProgressDecks(ProgressRange range)`.
- Produces, in `lib/features/progress/domain/models/progress_days_model.dart`:
  `ProgressDays.of(DateTime now, Duration utcOffset)`, with `int today`,
  `Duration utcOffset`, `int weekStart`, `int monthStart`,
  `DateTime validUntil` and `DateTime dateOf(int day)`.
- `allowedFeatureImports` gains `'progress': {}`.

Spec §5.1, §5.2, §5.4. Pure Dart: the day numbers every read agrees on,
the four numbers of a scope for both ranges, and the order of BR-PROGRESS-006,
sorted once per range so switching the range reads nothing.

- [ ] **Step 1: Write the failing tests, and add the feature to the import map**

In `test/architecture/boundary_rules.dart`:

Replace

```dart
  'study': {'study_mode', 'srs', 'settings', 'card'},
};
```

with

```dart
  'study': {'study_mode', 'srs', 'settings', 'card'},
  'progress': {},
};
```

Create `test/features/progress/domain/progress_days_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

// BR-PROGRESS-003, BR-PROGRESS-011, BR-PROGRESS-013, BR-PROGRESS-015: the
// local days of one read (Progress spec §5.1).

void main() {
  const hanoi = Duration(hours: 7);

  DateTime todayOf(DateTime now, Duration offset) {
    final days = ProgressDays.of(now, offset);
    return days.dateOf(days.today);
  }

  test('23:30 and 00:30 local fall on two days (BR-PROGRESS-011)', () {
    // 23:30 on 25 September and 00:30 on 26 September in Hanoi.
    final evening = ProgressDays.of(DateTime.utc(2026, 9, 25, 16, 30), hanoi);
    final night = ProgressDays.of(DateTime.utc(2026, 9, 25, 17, 30), hanoi);

    expect(night.today - evening.today, 1);
    expect(evening.dateOf(evening.today), DateTime(2026, 9, 25));
    expect(night.dateOf(night.today), DateTime(2026, 9, 26));
  });

  test('one instant falls on the day of the offset it is read at: +7, -5, '
      '+14, -12 (BR-PROGRESS-011)', () {
    final instant = DateTime.utc(2026, 9, 25, 2);

    expect(todayOf(instant, hanoi), DateTime(2026, 9, 25));
    expect(todayOf(instant, const Duration(hours: -5)), DateTime(2026, 9, 24));
    expect(todayOf(instant, const Duration(hours: 14)), DateTime(2026, 9, 25));
    expect(todayOf(instant, const Duration(hours: -12)), DateTime(2026, 9, 24));
  });

  test('the week is today and the six days before, the month today and the '
      '29 before, across the end of a year (BR-PROGRESS-003, '
      'BR-PROGRESS-015)', () {
    // Noon on 3 January 2027 in Hanoi.
    final days = ProgressDays.of(DateTime.utc(2027, 1, 3, 5), hanoi);

    expect(days.dateOf(days.weekStart), DateTime(2026, 12, 28));
    expect(days.dateOf(days.monthStart), DateTime(2026, 12, 5));
    expect(days.today - days.weekStart + 1, 7);
    expect(days.today - days.monthStart + 1, 30);
  });

  test('across the end of a month, the week keeps seven days '
      '(BR-PROGRESS-015)', () {
    final days = ProgressDays.of(DateTime.utc(2026, 10, 2, 3), hanoi);

    expect(
      [
        for (var day = days.weekStart; day <= days.today; day++)
          days.dateOf(day),
      ],
      [
        DateTime(2026, 9, 26),
        DateTime(2026, 9, 27),
        DateTime(2026, 9, 28),
        DateTime(2026, 9, 29),
        DateTime(2026, 9, 30),
        DateTime(2026, 10),
        DateTime(2026, 10, 2),
      ],
    );
  });

  test('the snapshot holds until the next local midnight, an instant '
      '(BR-PROGRESS-003)', () {
    final east = ProgressDays.of(DateTime.utc(2026, 9, 25, 16, 30), hanoi);
    final west = ProgressDays.of(
      DateTime.utc(2026, 9, 25, 2),
      const Duration(hours: -5),
    );

    // Midnight of 26 September in Hanoi; midnight of 25 September at -5.
    expect(east.validUntil, DateTime.utc(2026, 9, 25, 17));
    expect(west.validUntil, DateTime.utc(2026, 9, 25, 5));
    expect(east.validUntil.isUtc, isTrue);
  });
}
```

Create `test/features/progress/domain/progress_level_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';

// BR-PROGRESS-001, BR-PROGRESS-003, BR-PROGRESS-005, BR-PROGRESS-006: one
// level of Progress by deck (Progress spec §5.2, §5.4).

const _none = ProgressNumbers(
  activeCards: 0,
  activeDays: 0,
  learningCardDays: 0,
  reviewingCardDays: 0,
);

ProgressNumbers _active(int cards) => ProgressNumbers(
  activeCards: cards,
  activeDays: 1,
  learningCardDays: 0,
  reviewingCardDays: cards,
);

ProgressDeckRow _deck(String id, String name, {int week = 0, int month = 0}) =>
    ProgressDeckRow(
      deckId: id,
      name: name,
      progress: RangeProgress(
        week: week == 0 ? _none : _active(week),
        month: month == 0 ? _none : _active(month),
      ),
    );

ProgressLevel _level(List<ProgressDeckRow> decks) => ProgressLevel(
  total: const RangeProgress(week: _none, month: _none),
  decks: decks,
);

List<String> _ids(List<ProgressDeckRow> decks) => [
  for (final deck in decks) deck.deckId,
];

void main() {
  test('each range orders the decks by its own active cards, most first '
      '(BR-PROGRESS-006)', () {
    final level = _level([
      _deck('a', 'Alpha', week: 1, month: 9),
      _deck('b', 'Beta', week: 5, month: 2),
    ]);

    expect(_ids(level.decksFor(ProgressRange.week)), ['b', 'a']);
    expect(_ids(level.decksFor(ProgressRange.month)), ['a', 'b']);
  });

  test('a tie falls to the name folded in Dart, so Động and động sit '
      'together as Verbs and verbs do, then to the id (BR-PROGRESS-006)', () {
    final level = _level([
      _deck('3', 'động'),
      _deck('1', 'Zebra'),
      _deck('2', 'Động'),
      _deck('0', 'verbs'),
      _deck('4', 'Verbs'),
    ]);

    expect(_ids(level.decksFor(ProgressRange.week)), ['0', '4', '1', '2', '3']);
  });

  test('a deck with no activity stays in the list, after every active one, '
      'in an order that does not change from read to read '
      '(BR-PROGRESS-006)', () {
    final decks = [
      _deck('c', 'Charlie'),
      _deck('z', 'Zulu', week: 1, month: 1),
      _deck('a', 'Alpha'),
      _deck('b', 'Bravo'),
    ];

    final first = _level(decks).decksFor(ProgressRange.week);
    final second = _level(decks.reversed.toList()).decksFor(ProgressRange.week);

    expect(_ids(first), ['z', 'a', 'b', 'c']);
    expect(_ids(second), _ids(first));
  });

  test('a range reads its own numbers; card-days are Learning and Reviewing '
      'together (BR-PROGRESS-001, BR-PROGRESS-003, BR-PROGRESS-005)', () {
    const week = ProgressNumbers(
      activeCards: 3,
      activeDays: 2,
      learningCardDays: 1,
      reviewingCardDays: 4,
    );
    const progress = RangeProgress(week: week, month: _none);

    expect(progress.of(ProgressRange.week), same(week));
    expect(progress.of(ProgressRange.month), same(_none));
    expect(week.cardDays, 5);
    expect(week.hasActivity, isTrue);
    expect(_none.hasActivity, isFalse);
  });

  test('a level with no deck has no row (UC-PROGRESS-002 A2)', () {
    expect(_level([]).hasDecks, isFalse);
    expect(_level([_deck('a', 'Alpha')]).hasDecks, isTrue);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/domain/progress_days_test.dart \
  test/features/progress/domain/progress_level_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles: the models do not exist yet. The first errors: `Error: Undefined name 'ProgressDays'.`, `Error: Undefined name 'ProgressRange'.`, `Error: Type 'ProgressDeckRow' not found.`

- [ ] **Step 3: Write a level of Progress by deck**

Create `lib/features/progress/domain/models/progress_level_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';

/// The two ranges of Progress by deck: whole local days that end today
/// (BR-PROGRESS-003).
enum ProgressRange {
  week(7),
  month(30);

  const ProgressRange(this.days);

  /// The local days the range holds, today included.
  final int days;
}

/// The four numbers of one scope over one range, and no other
/// (BR-PROGRESS-001).
final class ProgressNumbers {
  const ProgressNumbers({
    required this.activeCards,
    required this.activeDays,
    required this.learningCardDays,
    required this.reviewingCardDays,
  });

  /// Distinct cards with an answer in the range (BR-PROGRESS-002).
  final int activeCards;

  /// Distinct local days with an answer in the range; never a sum over decks
  /// (BR-PROGRESS-002).
  final int activeDays;

  /// Card-days with a `learning` answer, and all the others: one partition
  /// (BR-PROGRESS-005).
  final int learningCardDays;
  final int reviewingCardDays;

  int get cardDays => learningCardDays + reviewingCardDays;

  bool get hasActivity => activeCards > 0;
}

/// A scope's numbers for both ranges, from one read (BR-PROGRESS-003).
final class RangeProgress {
  const RangeProgress({required this.week, required this.month});

  final ProgressNumbers week;
  final ProgressNumbers month;

  ProgressNumbers of(ProgressRange range) => switch (range) {
    ProgressRange.week => week,
    ProgressRange.month => month,
  };
}

/// A deck of a level with the numbers of its whole subtree
/// (BR-PROGRESS-004).
final class ProgressDeckRow {
  const ProgressDeckRow({
    required this.deckId,
    required this.name,
    required this.progress,
  });

  final String deckId;
  final String name;
  final RangeProgress progress;
}

/// One level of Progress by deck (UC-PROGRESS-002): the numbers of the whole
/// scope and a row per deck in it, every deck included, active or not.
final class ProgressLevel {
  ProgressLevel({required this.total, required List<ProgressDeckRow> decks})
    : _weekDecks = _sorted(decks, ProgressRange.week),
      _monthDecks = _sorted(decks, ProgressRange.month);

  /// Read from the statement that reads the rows, never added up from them
  /// (BR-PROGRESS-002).
  final RangeProgress total;

  final List<ProgressDeckRow> _weekDecks;
  final List<ProgressDeckRow> _monthDecks;

  /// The rows in the order of [range] (BR-PROGRESS-006), sorted once when the
  /// level is built, so switching the range costs nothing (BR-PROGRESS-003).
  List<ProgressDeckRow> decksFor(ProgressRange range) => switch (range) {
    ProgressRange.week => _weekDecks,
    ProgressRange.month => _monthDecks,
  };

  bool get hasDecks => _weekDecks.isNotEmpty;

  static List<ProgressDeckRow> _sorted(
    List<ProgressDeckRow> decks,
    ProgressRange range,
  ) {
    final sorted = [...decks]..sort(compareProgressDecks(range));
    return List.unmodifiable(sorted);
  }
}

/// BR-PROGRESS-006: active cards of [range] descending; then the name folded
/// in Dart (`foldText`, never SQL's `lower()`); then the id. A deck with no
/// activity has 0, the least, so it sorts after every active one and stays.
Comparator<ProgressDeckRow> compareProgressDecks(ProgressRange range) =>
    (a, b) {
      final cards = b.progress
          .of(range)
          .activeCards
          .compareTo(a.progress.of(range).activeCards);
      if (cards != 0) return cards;
      final name = foldText(a.name).compareTo(foldText(b.name));
      if (name != 0) return name;
      return a.deckId.compareTo(b.deckId);
    };
```

- [ ] **Step 4: Write the local days of a read**

Create `lib/features/progress/domain/models/progress_days_model.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_level_model.dart';

/// The local days of one read (BR-PROGRESS-011, BR-PROGRESS-013; Progress
/// spec §5.1). An answer falls on the day its UTC time has at [utcOffset], the
/// offset of this read, however old it is: `review_log` keeps no offset.
final class ProgressDays {
  const ProgressDays._({required this.today, required this.utcOffset});

  /// One snapshot of the clock and its offset; nothing reads either again.
  factory ProgressDays.of(DateTime now, Duration utcOffset) {
    final seconds =
        now.millisecondsSinceEpoch ~/ Duration.millisecondsPerSecond;
    return ProgressDays._(
      today: (seconds + utcOffset.inSeconds) ~/ Duration.secondsPerDay,
      utcOffset: utcOffset,
    );
  }

  /// Today, as days since 1970-01-01 at [utcOffset].
  final int today;

  final Duration utcOffset;

  /// The first day of the last seven, today being the seventh
  /// (BR-PROGRESS-003, BR-PROGRESS-015).
  int get weekStart => _startOf(ProgressRange.week);

  /// The first day of the last thirty (BR-PROGRESS-003).
  int get monthStart => _startOf(ProgressRange.month);

  /// The next local midnight, an instant: every number of the snapshot
  /// changes there with no write (BR-PROGRESS-003).
  DateTime get validUntil => DateTime.fromMillisecondsSinceEpoch(
    ((today + 1) * Duration.secondsPerDay - utcOffset.inSeconds) *
        Duration.millisecondsPerSecond,
    isUtc: true,
  );

  /// The calendar date of [day], for a day's label and the lost streak's
  /// note.
  DateTime dateOf(int day) {
    final date = DateTime.utc(1970, 1, 1 + day);
    return DateTime(date.year, date.month, date.day);
  }

  int _startOf(ProgressRange range) => today - range.days + 1;
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
flutter test test/features/progress/domain/progress_days_test.dart \
  test/features/progress/domain/progress_level_test.dart
```

Expected: `+10: All tests passed!`

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

Expected: `No issues found!`; `+1330: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 8: Commit**

```bash
git add docs/_generated \
  lib/features/progress/domain/models/progress_days_model.dart \
  lib/features/progress/domain/models/progress_level_model.dart \
  test/architecture/boundary_rules.dart \
  test/features/progress/domain/progress_days_test.dart \
  test/features/progress/domain/progress_level_test.dart
git commit -F - <<'EOF'
feat(progress): the local days of a read and a level of progress by deck

ProgressDays turns one read of the clock and its UTC offset into local day
numbers: today, the first day of the week and of the month, the next local
midnight (BR-PROGRESS-003, BR-PROGRESS-011, BR-PROGRESS-013). A level holds
the four numbers of its scope and of each deck for both ranges, and orders
the decks per range by active cards, then the folded name, then the id
(BR-PROGRESS-001, BR-PROGRESS-006). The feature enters the import map with no
dependency.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The overview: Today, the last seven days and the streak

**Files:**
- Create: `lib/features/progress/domain/models/progress_overview_model.dart`
- Test (create): `test/features/progress/domain/progress_overview_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `ProgressDays` (Task 1).
- Produces, in `lib/features/progress/domain/models/progress_overview_model.dart`:
  - `ActiveDay({required int day, required int learning, required int reviewing})`.
  - `DayActivity({required DateTime date, required int learning, required int reviewing})`,
    with `total`.
  - `enum StreakState { includesToday, heldFromYesterday, lost, never }`.
  - `CurrentStreak({required int days, required StreakState state})`.
  - `ProgressOverview({required DayActivity today, required List<DayActivity> lastSevenDays, required CurrentStreak streak, required DateTime? lastActiveDay})`,
    with `hasLifetimeActivity`.
  - `ProgressOverview progressOverviewOf({required List<int> activeDays, required List<ActiveDay> week, required ProgressDays days})`.

Spec §5.3; Clarification 1. The streak reads which days have activity
over the whole history; Today and the bars read the last seven days' split.

- [ ] **Step 1: Write the failing tests**

Create `test/features/progress/domain/progress_overview_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

// UC-PROGRESS-001: Today, the last seven days and the current streak
// (BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016; Progress spec §5.3).

void main() {
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  /// A day [ago] days before today with [cards] reviewing card-days.
  ActiveDay active(int ago, {int learning = 0, int cards = 1}) =>
      ActiveDay(day: days.today - ago, learning: learning, reviewing: cards);

  /// The overview of a history with [rows], read as the repository reads it:
  /// every day for the streak, the last seven with their split.
  ProgressOverview overviewOf(List<ActiveDay> rows) => progressOverviewOf(
    activeDays: [for (final row in rows) row.day],
    week: [
      for (final row in rows)
        if (row.day >= days.weekStart) row,
    ],
    days: days,
  );

  test('Today carries its card-days split into Learning and Reviewing, and '
      'a day without activity is zero (BR-PROGRESS-014)', () {
    final studied = overviewOf([active(0, learning: 2, cards: 3)]).today;
    final quiet = overviewOf([active(1)]).today;

    expect(studied.date, DateTime(2026, 9, 25));
    expect((studied.learning, studied.reviewing, studied.total), (2, 3, 5));
    expect((quiet.learning, quiet.reviewing, quiet.total), (0, 0, 0));
  });

  test('the last seven days are seven, oldest first and today last, a day '
      'without activity as zero; an older day is not among them '
      '(BR-PROGRESS-015)', () {
    final seven = overviewOf([
      active(7, cards: 9),
      active(6, cards: 1),
      active(3, learning: 1, cards: 2),
      active(0, cards: 4),
    ]).lastSevenDays;

    expect(
      [for (final day in seven) day.date],
      [for (var n = 19; n <= 25; n++) DateTime(2026, 9, n)],
    );
    expect([for (final day in seven) day.total], [1, 0, 0, 3, 0, 0, 4]);
  });

  test('the streak counts back from today when today has activity, past '
      'the seven days with no cap (BR-PROGRESS-016)', () {
    final streak = overviewOf([for (var ago = 9; ago >= 0; ago--) active(ago)])
        .streak;

    expect((streak.days, streak.state), (10, StreakState.includesToday));
  });

  test('a day without activity ends the streak (BR-PROGRESS-016)', () {
    final streak = overviewOf([active(3), active(1), active(0)]).streak;

    expect((streak.days, streak.state), (2, StreakState.includesToday));
  });

  test('with nothing yet today, a streak that reached yesterday is held, '
      'not lost (BR-PROGRESS-016; UC-PROGRESS-001 A1)', () {
    final overview = overviewOf([active(2), active(1)]);

    expect(overview.today.total, 0);
    expect(
      (overview.streak.days, overview.streak.state),
      (2, StreakState.heldFromYesterday),
    );
  });

  test('with neither today nor yesterday the streak is 0 and lost, and the '
      'last active day names when it ended (BR-PROGRESS-016)', () {
    final overview = overviewOf([active(4), active(3)]);

    expect(
      (overview.streak.days, overview.streak.state),
      (0, StreakState.lost),
    );
    expect(overview.lastActiveDay, DateTime(2026, 9, 22));
    expect(overview.hasLifetimeActivity, isTrue);
  });

  test('never studied: no streak, no last active day and seven zero days '
      '(UC-PROGRESS-001 A2)', () {
    final overview = overviewOf(const []);

    expect(
      (overview.streak.days, overview.streak.state),
      (0, StreakState.never),
    );
    expect(overview.lastActiveDay, isNull);
    expect(overview.hasLifetimeActivity, isFalse);
    expect(
      [for (final day in overview.lastSevenDays) day.total],
      [0, 0, 0, 0, 0, 0, 0],
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/domain/progress_overview_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the overview does not exist yet. The first errors: `Error: Undefined name 'StreakState'.`, `Error: 'ActiveDay' isn't a type.`, `Error: Error when reading 'lib/features/progress/domain/models/progress_overview_model.dart': No such file or directory`

- [ ] **Step 3: Write the overview**

Create `lib/features/progress/domain/models/progress_overview_model.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

/// A day of the last seven with activity: its card-days split into Learning
/// and Reviewing (BR-PROGRESS-011, BR-PROGRESS-014).
final class ActiveDay {
  const ActiveDay({
    required this.day,
    required this.learning,
    required this.reviewing,
  });

  /// Days since 1970-01-01 at the read's offset ([ProgressDays.today]).
  final int day;
  final int learning;
  final int reviewing;
}

/// One day of the overview, zero when nothing was studied
/// (BR-PROGRESS-014, BR-PROGRESS-015).
final class DayActivity {
  const DayActivity({
    required this.date,
    required this.learning,
    required this.reviewing,
  });

  final DateTime date;
  final int learning;
  final int reviewing;

  /// Every card-day of the day: the split always adds up (BR-PROGRESS-014).
  int get total => learning + reviewing;
}

/// How the current streak stands, as the kit names it (BR-PROGRESS-016).
enum StreakState {
  /// Today has activity.
  includesToday,

  /// Nothing yet today, but yesterday had activity: the streak holds.
  heldFromYesterday,

  /// Neither day had activity, after some study before.
  lost,

  /// No activity ever.
  never,
}

final class CurrentStreak {
  const CurrentStreak({required this.days, required this.state});

  /// Days that follow each other back from the anchor; no cap
  /// (BR-PROGRESS-016).
  final int days;

  final StreakState state;
}

/// The overview of UC-PROGRESS-001: Today, the last seven days and the
/// current streak, all from one snapshot (BR-PROGRESS-013).
final class ProgressOverview {
  const ProgressOverview({
    required this.today,
    required this.lastSevenDays,
    required this.streak,
    required this.lastActiveDay,
  });

  final DayActivity today;

  /// Exactly seven days, oldest first, today last (BR-PROGRESS-015).
  final List<DayActivity> lastSevenDays;

  final CurrentStreak streak;

  /// The latest day with activity, the day a lost streak ended; null only
  /// when nothing was ever studied.
  final DateTime? lastActiveDay;

  bool get hasLifetimeActivity => streak.state != StreakState.never;
}

/// The overview from the history (Progress spec §5.3): [activeDays], every
/// local day with activity up to today, oldest first, for the streak; and
/// [week], the days of the last seven with activity, for Today and the bars.
ProgressOverview progressOverviewOf({
  required List<int> activeDays,
  required List<ActiveDay> week,
  required ProgressDays days,
}) {
  final byDay = {for (final row in week) row.day: row};
  DayActivity activityOf(int day) => DayActivity(
    date: days.dateOf(day),
    learning: byDay[day]?.learning ?? 0,
    reviewing: byDay[day]?.reviewing ?? 0,
  );
  return ProgressOverview(
    today: activityOf(days.today),
    lastSevenDays: [
      for (var day = days.weekStart; day <= days.today; day++) activityOf(day),
    ],
    streak: _streakOf(activeDays.toSet(), today: days.today),
    lastActiveDay: activeDays.isEmpty ? null : days.dateOf(activeDays.last),
  );
}

/// BR-PROGRESS-016: anchored today when today has activity, else yesterday
/// when yesterday has; with no anchor the streak is 0.
CurrentStreak _streakOf(Set<int> active, {required int today}) {
  if (active.isEmpty) {
    return const CurrentStreak(days: 0, state: StreakState.never);
  }
  final anchor = active.contains(today) ? today : today - 1;
  if (!active.contains(anchor)) {
    return const CurrentStreak(days: 0, state: StreakState.lost);
  }
  var days = 0;
  while (active.contains(anchor - days)) {
    days++;
  }
  return CurrentStreak(
    days: days,
    state: anchor == today
        ? StreakState.includesToday
        : StreakState.heldFromYesterday,
  );
}
```

- [ ] **Step 4: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/progress/domain/progress_overview_test.dart
```

Expected: `+7: All tests passed!`

- [ ] **Step 6: Run the phased gate**

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

Expected: `No issues found!`; `+1337: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 7: Commit**

```bash
git add docs/_generated \
  lib/features/progress/domain/models/progress_overview_model.dart \
  test/features/progress/domain/progress_overview_test.dart
git commit -F - <<'EOF'
feat(progress): the overview: today, the last seven days and the streak

progressOverviewOf builds UC-PROGRESS-001's overview from the history's
days with activity and the last seven days' card-days: Today with its
Learning and Reviewing split, seven days oldest first with zeros filled in,
and the current streak, anchored today or held from yesterday, with no cap
(BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016). The streak's state
tells a lapsed person from one who never studied.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: One change stream for the read models

**Files:**
- Create: `lib/core/database/table_changes.dart`
- Modify: `lib/features/study/data/datasources/study_view_dao.dart`
- Test (create): `test/database/table_changes_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`; package 3's `StudyViewDao.homeChanges()`.
- Produces: `Stream<void> tableChanges(AppDatabase db, Iterable<ResultSetImplementation<Object?, Object?>> tables)`
  (`lib/core/database/table_changes.dart`). `StudyViewDao.homeChanges()` keeps its
  signature and delegates to it.

Spec D8, §6.4; Clarification 4. Package 3's listen-first stream moves to
`core/database`, as its final review suggested once a second read model needs
it. Study Home's stream tests keep passing on it; the gate runs them.

- [ ] **Step 1: Write the failing tests**

Create `test/database/table_changes_test.dart`:

```dart
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';

import '../support/deck_fixtures.dart';
import '../support/test_database.dart';

// Progress spec D8: the change stream the read models share. The Study tab's
// stream tests prove its listen-first order (Study Home spec D7).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 25, 9));
  });
  tearDown(() => db.close());

  test('fires once when listened to, before any write', () async {
    var firings = 0;
    final subscription = tableChanges(db, [db.deck]).listen((_) => firings++);
    await pumpEventQueue();

    expect(firings, 1);
    await subscription.cancel();
  });

  test('a transaction that writes its tables twice fires once', () async {
    await decks.root('Korean');
    await decks.root('English');
    var firings = 0;
    final subscription = tableChanges(db, [db.deck]).listen((_) => firings++);
    await pumpEventQueue();

    await db.transaction(() async {
      for (final name in ['Korean', 'English']) {
        await db.customUpdate(
          'UPDATE deck SET name = ? WHERE name = ?',
          variables: [Variable<String>('$name 2'), Variable<String>(name)],
          updates: {db.deck},
        );
      }
    });
    await pumpEventQueue();

    expect(firings, 2);
    await subscription.cancel();
  });

  test('a write to another table fires nothing', () async {
    var firings = 0;
    final subscription = tableChanges(db, [db.card]).listen((_) => firings++);
    await pumpEventQueue();

    await decks.root('Korean');
    await pumpEventQueue();

    expect(firings, 1);
    await subscription.cancel();
  });

  test('a cancelled stream fires no more', () async {
    var firings = 0;
    final subscription = tableChanges(db, [db.deck]).listen((_) => firings++);
    await pumpEventQueue();
    await subscription.cancel();

    await decks.root('Korean');
    await pumpEventQueue();

    expect(firings, 1);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/database/table_changes_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the helper does not exist yet. The first errors: `Error: Method not found: 'tableChanges'.`, `Error: Error when reading 'lib/core/database/table_changes.dart': No such file or directory`

- [ ] **Step 3: Write the change stream**

Create `lib/core/database/table_changes.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';

/// Fires once when listened to, then after every write to one of [tables];
/// a flat transaction fires once, but a transaction nested in another fires
/// on its own (Progress spec §6.4). It listens to the tables before it fires
/// the first time, so a write that lands right after the first read is seen
/// (Study Home spec D7, Progress spec D8). A read model maps each firing to
/// one read.
Stream<void> tableChanges(
  AppDatabase db,
  Iterable<ResultSetImplementation<Object?, Object?>> tables,
) => Stream.multi((listener) {
  final updates = db
      .tableUpdates(TableUpdateQuery.onAllTables(tables))
      .listen((_) => listener.add(null), onError: listener.addError);
  listener
    ..add(null)
    ..onCancel = updates.cancel;
});
```

- [ ] **Step 4: Let the Study tab use it**

In `lib/features/study/data/datasources/study_view_dao.dart`:

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
  /// Fires once when listened to, then after every write to a table the
  /// Study tab reads: decks, cards, schedules, sessions and queues; a
  /// transaction fires once. It listens before it fires, so a write that
  /// lands right after the first read is seen (Study Home spec D7).
  Stream<void> homeChanges() => Stream.multi((listener) {
    final updates = _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _db.deck,
            _db.card,
            _db.cardSchedule,
            _db.studySession,
            _db.studyQueueItems,
          ]),
        )
        .listen((_) => listener.add(null), onError: listener.addError);
    listener
      ..add(null)
      ..onCancel = updates.cancel;
  });

```

with

```dart
  /// Fires once when listened to, then after every write to a table the
  /// Study tab reads: decks, cards, schedules, sessions and queues
  /// (`tableChanges`, Study Home spec D7).
  Stream<void> homeChanges() => tableChanges(_db, [
    _db.deck,
    _db.card,
    _db.cardSchedule,
    _db.studySession,
    _db.studyQueueItems,
  ]);

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
flutter test test/database/table_changes_test.dart
```

Expected: `+4: All tests passed!`

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

Expected: `No issues found!`; `+1341: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 8: Commit**

```bash
git add lib/core/database/table_changes.dart \
  lib/features/study/data/datasources/study_view_dao.dart \
  test/database/table_changes_test.dart
git commit -F - <<'EOF'
refactor(study,database): one listen-first change stream for the read models

tableChanges fires once when listened to, then after every write to the
tables it is given, one firing per flat transaction, and it listens before
it fires the first time (Study Home spec D7). StudyViewDao.homeChanges now
uses it, and Progress will.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 4: The library level: `/progress` in one snapshot

**Files:**
- Create: `lib/features/progress/data/datasources/progress_dao.dart`, `lib/features/progress/data/mappers/progress_mapper.dart`, `lib/features/progress/data/repositories/progress_repository_impl.dart`, `lib/features/progress/di/progress_repository_provider.dart`, `lib/features/progress/domain/models/progress_model.dart`, `lib/features/progress/domain/repositories/progress_repository.dart`
- Test (create): `test/features/progress/data/watch_progress_stream_test.dart`, `test/features/progress/data/watch_progress_test.dart`, `test/support/progress_fixtures.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Tasks 1 and 2's models and `progressOverviewOf`; `tableChanges`
  (Task 3); `mapDatabaseErrors` (`lib/core/error/failure.dart`);
  `databaseProvider`; `logReview` and `insertCard` (`test/support/card_fixtures.dart`).
- Produces:
  - `Progress({required ProgressOverview overview, required ProgressLevel level, required DateTime validUntil})`
    (`progress/domain/models/progress_model.dart`).
  - `ProgressDao(AppDatabase db)` (`progress/data/datasources/progress_dao.dart`),
    with `typedef ActiveDayRow = ({int day, int learning, int reviewing})`,
    `typedef CountsRow = ({int cards, int days, int learning, int reviewing})`,
    `typedef LevelRow = ({String? deckId, String? name, CountsRow week, CountsRow month})`;
    `Future<List<int>> activeDays(ProgressDays days)`,
    `Future<List<ActiveDayRow>> weekActivity(ProgressDays days)`,
    `Future<List<LevelRow>> rootLevel(ProgressDays days)` and `Stream<void> changes()`.
  - `List<ActiveDay> activeDaysOf(List<ActiveDayRow> rows)` and
    `ProgressLevel levelOf(List<LevelRow> rows)` (`progress/data/mappers/progress_mapper.dart`).
  - `abstract interface class ProgressRepository` with
    `Stream<Progress> watchProgress(ProgressDays days)`.
  - `ProgressRepositoryImpl(AppDatabase db)` and `progressRepositoryProvider`.
  - Test support: `learnedCard(db, deckId, id)`, `answer(db, cardId, at, {kind, mode})`
    and `hanoi(month, day, hour, [minute])` (`test/support/progress_fixtures.dart`).

Spec §6, D3–D10; Clarifications 1 and 5. The two test files come first:
what one snapshot says, then when it reads again and what a write changes. The
data access object folds the history in SQLite, the mapper and the repository
read it in one transaction, and the provider makes the repository available to
FE-A9.

- [ ] **Step 1: Write the failing tests**

Create `test/support/progress_fixtures.dart`:

```dart
import 'package:memox/core/database/app_database.dart';

import 'card_fixtures.dart';

var _answers = 0;

/// A learned card of [deckId], so an answer of any kind suits it (schema
/// invariant 25). The caller locks its root's scheduler (invariant 30).
Future<void> learnedCard(AppDatabase db, String deckId, String id) =>
    insertCard(
      db,
      id: id,
      deckId: deckId,
      back: 'meaning $id',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
    );

/// An answer to [cardId] at [at], as the study flow records it
/// (BR-SRS-016).
Future<void> answer(
  AppDatabase db,
  String cardId,
  DateTime at, {
  String kind = 'scheduled',
  String mode = 'recall',
}) => logReview(
  db,
  id: 'answer ${_answers++}',
  cardId: cardId,
  at: at,
  kind: kind,
  mode: mode,
);

/// [hour]:[minute] local time in Hanoi (UTC+7), as the instant it is.
DateTime hanoi(int month, int day, int hour, [int minute = 0]) =>
    DateTime.utc(2026, month, day, hour - 7, minute);
```

Create `test/features/progress/data/watch_progress_stream_test.dart`:

```dart
import 'package:drift/drift.dart' show QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart' show SqliteException;
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/failures/srs_failure.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-PROGRESS-001 A3, A5, A6 and UC-PROGRESS-002 step 6, E1: when `/progress`
// reads again, what a write changes, and a read that fails (Progress spec
// §6.3, §6.4, §6.6).

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (UC-PROGRESS-001 E1).
final class _FailingSelects extends QueryInterceptor {
  bool isArmed = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (isArmed) {
      throw SqliteException(extendedResultCode: 10, message: 'disk I/O error');
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ProgressRepositoryImpl progress;
  final now = DateTime(2026, 9, 25, 12);
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: () => now);
    progress = ProgressRepositoryImpl(db);
  }

  setUp(() => open());
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Progress> read() => progress.watchProgress(days).first;

  CardRepositoryImpl cards() => CardRepositoryImpl(
    db,
    ScheduleRepositoryImpl(db, now: () => now),
    TagRepositoryImpl(db, now: () => now),
    now: () => now,
  );

  /// The month's active cards per root deck, in the list's order.
  Map<String, int> monthCards(Progress snapshot) => {
    for (final deck in snapshot.level.decksFor(ProgressRange.month))
      deck.name: deck.progress.month.activeCards,
  };

  test('the snapshot comes again on a new answer, a renamed deck and a '
      'deleted deck (BR-PROGRESS-008)', () async {
    final alpha = await decks.root('Alpha');
    final alphaLesson = await decks.sub(alpha.id, 'Lesson');
    final beta = await decks.root('Beta');
    await learnedCard(db, alphaLesson.id, 'a1');
    await lockScheduler(db, alpha.id);
    final snapshots = <Progress>[];
    final subscription = progress.watchProgress(days).listen(snapshots.add);
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Alpha': 0, 'Beta': 0});

    await answer(db, 'a1', hanoi(9, 25, 9));
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Alpha': 1, 'Beta': 0});

    expect(
      await decks.renameDeck(deckId: beta.id, name: 'Aardvark'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Alpha': 1, 'Aardvark': 0});

    expect(
      await decks.deleteDeck(deckId: alpha.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(monthCards(snapshots.last), {'Aardvark': 0});
    expect(snapshots.last.overview.hasLifetimeActivity, isFalse);
    await subscription.cancel();
  });

  test('a sub-deck moved to another root takes its whole history along '
      '(BR-PROGRESS-004)', () async {
    final korean = await decks.root('Korean');
    final english = await decks.root('English');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await decks.sub(english.id, 'Words');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await lockScheduler(db, english.id);
    await answer(db, 'c1', hanoi(9, 10, 9));
    await answer(db, 'c1', hanoi(9, 25, 9));

    expect(
      await decks.moveDeck(deckId: lesson.id, newParentId: english.id),
      isA<Ok<void, DeckRejection>>(),
    );
    final snapshot = await read();

    expect(monthCards(snapshot), {'English': 1, 'Korean': 0});
    expect(
      snapshot.level
          .decksFor(ProgressRange.month)
          .first
          .progress
          .month
          .cardDays,
      2,
    );
  });

  test('a deleted card takes its history away, past days included '
      '(BR-PROGRESS-017; UC-PROGRESS-001 A6)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await learnedCard(db, lesson.id, 'c2');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 1, 9));
    await answer(db, 'c2', hanoi(9, 25, 9));

    expect(
      await cards().deleteCards(cardIds: {'c1'}),
      isA<Ok<void, CardRejection>>(),
    );
    final snapshot = await read();

    expect(snapshot.level.total.month.cardDays, 1);
    expect(snapshot.overview.streak.days, 1);
  });

  test('a reset of learning progress changes no number (BR-PROGRESS-017; '
      'UC-PROGRESS-001 A5)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 24, 9));
    await answer(db, 'c1', hanoi(9, 25, 9));
    final before = await read();

    expect(
      await ScheduleRepositoryImpl(
        db,
        now: () => now,
      ).resetLearning(rootDeckId: korean.id),
      isA<Ok<void, SrsRejection>>(),
    );
    final after = await read();

    expect(after.level.total.month.cardDays, before.level.total.month.cardDays);
    expect(after.overview.streak.days, 2);
  });

  test('reading writes nothing and opens no session (BR-PROGRESS-007, '
      'BR-PROGRESS-009; the backend half of IT-NAV-011 step 2)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 25, 9));
    final before = await totalChanges(db);

    await read();

    expect(await totalChanges(db), before);
    final sessions = await db
        .customSelect('SELECT COUNT(*) AS n FROM study_session')
        .getSingle();
    expect(sessions.read<int>('n'), 0);
  });

  test('opening Progress while a study session is open leaves it open and '
      'writes nothing (BR-PROGRESS-009; IT-NAV-011 step 2)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await insertCard(db, id: 'new', deckId: lesson.id, back: 'new');
    final opened = await studyEntryRepository(
      db,
      () => now,
    ).openLearningSession(deckId: lesson.id);
    final sessionId = (opened as Ok<String, StudyRejection>).value;
    final before = await totalChanges(db);

    await read();

    expect(await totalChanges(db), before);
    expect(
      (await sessionOf(db, sessionId)).read<String>('status'),
      'in_progress',
    );
  });

  test(
    'a read that fails comes as a database Failure (UC-PROGRESS-001 E1)',
    () async {
      await db.close();
      final failing = _FailingSelects();
      open(failing);
      await decks.root('Korean');
      failing.isArmed = true;

      await expectLater(
        progress.watchProgress(days),
        emitsError(isA<Failure>()),
      );
      failing.isArmed = false;
    },
  );
}
```

Create `test/features/progress/data/watch_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-PROGRESS-001 and UC-PROGRESS-002 at the library level: what one
// snapshot of `/progress` says (Progress spec §5, §6).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ProgressRepositoryImpl progress;
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => DateTime(2026, 9, 1));
    progress = ProgressRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<Progress> read([ProgressDays? at]) =>
      progress.watchProgress(at ?? days).first;

  /// A root deck with one sub-deck holding the learned cards [ids].
  Future<String> tree(String root, List<String> ids) async {
    final deck = await decks.root(root);
    final lesson = await decks.sub(deck.id, '$root lesson');
    for (final id in ids) {
      await learnedCard(db, lesson.id, id);
    }
    await lockScheduler(db, deck.id);
    return deck.id;
  }

  (int, int, int, int) numbersOf(ProgressNumbers numbers) => (
    numbers.activeCards,
    numbers.activeDays,
    numbers.learningCardDays,
    numbers.reviewingCardDays,
  );

  test('six answers to one card in one evening are one card-day and one '
      'active day (BR-PROGRESS-002, BR-PROGRESS-011)', () async {
    await tree('Korean', ['c1']);
    for (final minute in [0, 10, 20, 30, 40, 50]) {
      await answer(db, 'c1', hanoi(9, 24, 20, minute));
    }

    final snapshot = await read();

    expect(numbersOf(snapshot.level.total.week), (1, 1, 0, 1));
    expect(
      [for (final day in snapshot.overview.lastSevenDays) day.total],
      [0, 0, 0, 0, 0, 1, 0],
    );
  });

  test('two decks studied on one day are one active day at the level above '
      '(BR-PROGRESS-002)', () async {
    await tree('Korean', ['k1']);
    await tree('English', ['e1']);
    await answer(db, 'k1', hanoi(9, 24, 9));
    await answer(db, 'e1', hanoi(9, 24, 21));

    final level = (await read()).level;

    expect(numbersOf(level.total.week), (2, 1, 0, 2));
    expect(
      [
        for (final deck in level.decksFor(ProgressRange.week))
          deck.progress.week.activeDays,
      ],
      [1, 1],
    );
  });

  test('a card-day with a learning answer is Learning, whatever else that '
      'day holds; scheduled and relearning are Reviewing (BR-PROGRESS-005, '
      'BR-PROGRESS-014)', () async {
    await tree('Korean', ['c1', 'c2', 'c3']);
    await answer(db, 'c1', hanoi(9, 25, 9), kind: 'learning');
    await answer(db, 'c1', hanoi(9, 25, 10));
    await answer(db, 'c2', hanoi(9, 25, 10), kind: 'relearning');
    await answer(db, 'c3', hanoi(9, 25, 11));

    final snapshot = await read();
    final today = snapshot.overview.today;

    expect((today.learning, today.reviewing, today.total), (1, 2, 3));
    expect(numbersOf(snapshot.level.total.week), (3, 1, 1, 2));
  });

  test("23:30 and 00:30 local fall on two days at the read's offset; read "
      'at another offset they fall on one (BR-PROGRESS-011)', () async {
    await tree('Korean', ['c1']);
    await answer(db, 'c1', hanoi(9, 23, 23, 30));
    await answer(db, 'c1', hanoi(9, 24, 0, 30));

    final atHanoi = (await read()).level.total.week;
    final atUtc = (await read(
      ProgressDays.of(DateTime.utc(2026, 9, 25, 5), Duration.zero),
    )).level.total.week;

    expect((atHanoi.activeDays, atHanoi.cardDays), (2, 2));
    expect((atUtc.activeDays, atUtc.cardDays), (1, 1));
  });

  test('the week is today and the six days before, the month today and the '
      '29 before, each from local midnight, both from one read '
      '(BR-PROGRESS-003, BR-PROGRESS-011)', () async {
    await tree('Korean', ['six', 'seven', 'twentyNine', 'thirty']);
    // 03:00 in Hanoi is still the day before in UTC; 23:00 is the same day.
    await answer(db, 'six', hanoi(9, 19, 3));
    await answer(db, 'seven', hanoi(9, 18, 23));
    await answer(db, 'twentyNine', hanoi(8, 27, 3));
    await answer(db, 'thirty', hanoi(8, 26, 23));

    final total = (await read()).level.total;

    expect(numbersOf(total.week), (1, 1, 0, 1));
    expect(numbersOf(total.month), (3, 3, 0, 3));
  });

  test('an answer at 00:00:00 local falls on its new day and one at '
      '23:59:59 on the day before, at Today and at the first day of the '
      'month (BR-PROGRESS-003, BR-PROGRESS-011)', () async {
    await tree('Korean', ['midnight', 'lastSecond', 'monthStart', 'before']);
    await answer(db, 'midnight', hanoi(9, 25, 0));
    // 23:59:59 on 24 September, then on 26 August, in Hanoi.
    await answer(db, 'lastSecond', DateTime.utc(2026, 9, 24, 16, 59, 59));
    await answer(db, 'monthStart', hanoi(8, 27, 0));
    await answer(db, 'before', DateTime.utc(2026, 8, 26, 16, 59, 59));

    final snapshot = await read();

    expect(snapshot.overview.today.total, 1);
    expect(snapshot.overview.lastSevenDays[5].total, 1);
    expect(snapshot.level.total.month.activeCards, 3);
  });

  test(
    "a root deck's numbers are its whole tree's (BR-PROGRESS-004)",
    () async {
      final korean = await decks.root('Korean');
      final lesson = await decks.sub(korean.id, 'Lesson');
      final unit = await decks.sub(lesson.id, 'Unit');
      await learnedCard(db, unit.id, 'deep');
      await lockScheduler(db, korean.id);
      await answer(db, 'deep', hanoi(9, 25, 9));

      final deck = (await read()).level.decksFor(ProgressRange.week).single;

      expect((deck.deckId, deck.progress.week.activeCards), (korean.id, 1));
    },
  );

  test('every root deck is listed, those with no activity last '
      '(BR-PROGRESS-006; UC-PROGRESS-002 A3)', () async {
    await decks.root('Alpha');
    await tree('Beta', ['b1']);
    await tree('Charlie', ['c1']);
    await answer(db, 'b1', hanoi(9, 25, 9));

    final rows = (await read()).level.decksFor(ProgressRange.week);

    expect([for (final deck in rows) deck.name], ['Beta', 'Alpha', 'Charlie']);
    expect(
      [for (final deck in rows) deck.progress.week.hasActivity],
      [true, false, false],
    );
  });

  test('a browse row, a card in the Trash, a deck in the Trash and an answer '
      'dated after today count nowhere (BR-PROGRESS-012; spec D7)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final trashed = await decks.sub(korean.id, 'Trashed');
    await learnedCard(db, lesson.id, 'browsed');
    await learnedCard(db, lesson.id, 'future');
    await insertCard(
      db,
      id: 'gone',
      deckId: lesson.id,
      back: 'gone',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
      deleteBatchId: 'batch',
    );
    await insertCard(
      db,
      id: 'inTrashedDeck',
      deckId: trashed.id,
      back: 'kept',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    await lockScheduler(db, korean.id);
    await answer(db, 'browsed', hanoi(9, 25, 9), mode: 'browse');
    await answer(db, 'gone', hanoi(9, 25, 9));
    await answer(db, 'inTrashedDeck', hanoi(9, 25, 9));
    // 03:00 tomorrow in Hanoi, still today in UTC.
    await answer(db, 'future', hanoi(9, 26, 3));

    final snapshot = await read();

    expect(numbersOf(snapshot.level.total.month), (0, 0, 0, 0));
    expect(snapshot.overview.streak.state, StreakState.never);
  });

  test('never studied: every root deck with zeros, and the overview says '
      'never (UC-PROGRESS-001 A2, UC-PROGRESS-002 A3)', () async {
    await tree('Korean', ['c1']);

    final snapshot = await read();

    expect(snapshot.level.decksFor(ProgressRange.month).single.name, 'Korean');
    expect(snapshot.level.total.month.hasActivity, isFalse);
    expect(snapshot.overview.hasLifetimeActivity, isFalse);
  });

  test('a library with no deck has no row (UC-PROGRESS-002 A2)', () async {
    expect((await read()).level.hasDecks, isFalse);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/data/watch_progress_stream_test.dart \
  test/features/progress/data/watch_progress_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles: the repository does not exist yet. The first errors: `Error: 'Progress' isn't a type.`, `Error: Error when reading 'lib/features/progress/data/repositories/progress_repository_impl.dart': No such file or directory`, `Error: Error when reading 'lib/features/progress/domain/models/progress_model.dart': No such file or directory`

- [ ] **Step 3: Add the library level's snapshot**

Create `lib/features/progress/domain/models/progress_model.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

/// `/progress` (UC-PROGRESS-001, and UC-PROGRESS-002 at the library level):
/// the overview and a row per root deck, read as one snapshot (Progress
/// spec §5.2).
final class Progress {
  const Progress({
    required this.overview,
    required this.level,
    required this.validUntil,
  });

  final ProgressOverview overview;
  final ProgressLevel level;

  /// The next local midnight: every number changes there with no write
  /// (BR-PROGRESS-003).
  final DateTime validUntil;
}
```

- [ ] **Step 4: Fold the history in SQLite**

Create `lib/features/progress/data/datasources/progress_dao.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/database/table_changes.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';

/// A day of the last seven with activity: its Learning and Reviewing
/// card-days.
typedef ActiveDayRow = ({int day, int learning, int reviewing});

/// One range's four numbers.
typedef CountsRow = ({int cards, int days, int learning, int reviewing});

/// A row of a level: a deck with its numbers for the week and the month; the
/// level's total when [deckId] is null (Progress spec D5).
typedef LevelRow = ({
  String? deckId,
  String? name,
  CountsRow week,
  CountsRow month,
});

/// The answers that count, `r`, with their card `c` and its deck `k`: live
/// cards only, never a `browse` row (BR-PROGRESS-012), on a local day, at the
/// read's offset `?1`, that meets [days] (Progress spec §6.1).
String _answers(String days) =>
    ' FROM review_log r'
    ' JOIN card c ON c.id = r.card_id'
    ' JOIN deck k ON k.id = c.deck_id'
    ' WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL'
    " AND r.mode <> 'browse' AND (r.answered_at + ?1) / 86400 $days";

/// The card-days of [_answers]: one row per card and local day, with the
/// `tile_id` a level groups by. A card-day with a `learning` answer is
/// Learning (BR-PROGRESS-005).
String _cardDays({required String tile, required String days}) =>
    'SELECT c.id AS card_id, $tile AS tile_id,'
    ' (r.answered_at + ?1) / 86400 AS day,'
    " MAX(r.kind = 'learning') AS is_learning"
    '${_answers(days)}'
    ' GROUP BY c.id, day';

/// The four numbers of the week (days from `?2`) and of the month, over the
/// card-days in scope (BR-PROGRESS-001, BR-PROGRESS-002).
const _numbers =
    ' COUNT(DISTINCT card_id) FILTER (WHERE day >= ?2) AS week_cards,'
    ' COUNT(DISTINCT day) FILTER (WHERE day >= ?2) AS week_days,'
    ' COUNT(*) FILTER (WHERE day >= ?2 AND is_learning) AS week_learning,'
    ' COUNT(*) FILTER (WHERE day >= ?2 AND NOT is_learning)'
    ' AS week_reviewing,'
    ' COUNT(DISTINCT card_id) AS month_cards,'
    ' COUNT(DISTINCT day) AS month_days,'
    ' COUNT(*) FILTER (WHERE is_learning) AS month_learning,'
    ' COUNT(*) FILTER (WHERE NOT is_learning) AS month_reviewing';

/// The reads of the Progress screen (Progress spec §6). They write nothing
/// (BR-PROGRESS-007, BR-PROGRESS-009).
final class ProgressDao {
  const ProgressDao(this._db);

  final AppDatabase _db;

  /// Every local day with activity up to today, oldest first, folded in
  /// SQLite: the streak's days (UC-PROGRESS-001 step 2, BR-PROGRESS-016).
  Future<List<int>> activeDays(ProgressDays days) async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT (r.answered_at + ?1) / 86400 AS day'
          '${_answers('<= ?2')} ORDER BY day',
          variables: [
            Variable<int>(days.utcOffset.inSeconds),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
        )
        .get();
    return [for (final row in rows) row.read<int>('day')];
  }

  /// The days of the last seven with activity, with their Learning and
  /// Reviewing card-days: Today and the bars (BR-PROGRESS-014,
  /// BR-PROGRESS-015).
  Future<List<ActiveDayRow>> weekActivity(ProgressDays days) async {
    final rows = await _db
        .customSelect(
          'WITH card_days AS'
          " (${_cardDays(tile: 'NULL', days: 'BETWEEN ?2 AND ?3')})"
          ' SELECT day,'
          ' COUNT(*) FILTER (WHERE is_learning) AS learning,'
          ' COUNT(*) FILTER (WHERE NOT is_learning) AS reviewing'
          ' FROM card_days GROUP BY day ORDER BY day',
          variables: [
            Variable<int>(days.utcOffset.inSeconds),
            Variable<int>(days.weekStart),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
        )
        .get();
    return [
      for (final row in rows)
        (
          day: row.read<int>('day'),
          learning: row.read<int>('learning'),
          reviewing: row.read<int>('reviewing'),
        ),
    ];
  }

  /// Every active root deck with the numbers of its whole tree, grouped by
  /// `root_id`, and the library's total from the same statement
  /// (BR-PROGRESS-002, BR-PROGRESS-004).
  Future<List<LevelRow>> rootLevel(ProgressDays days) => _level(
    days,
    cardDays: _cardDays(tile: 'k.root_id', days: 'BETWEEN ?3 AND ?4'),
    decks: 'd.parent_id IS NULL',
  );

  /// Fires once when listened to, then after every write to the history,
  /// the cards or the decks (BR-PROGRESS-008).
  Stream<void> changes() =>
      tableChanges(_db, [_db.reviewLog, _db.card, _db.deck]);

  /// The decks that match [decks], each with the card-days whose `tile_id`
  /// is its id, then one total row over every card-day of [cardDays]
  /// (Progress spec D5).
  Future<List<LevelRow>> _level(
    ProgressDays days, {
    required String cardDays,
    required String decks,
  }) async {
    final rows = await _db
        .customSelect(
          'WITH card_days AS ($cardDays),'
          ' tiles AS (SELECT tile_id,$_numbers FROM card_days GROUP BY tile_id)'
          ' SELECT d.id AS deck_id, d.name AS name, tiles.*'
          ' FROM deck d LEFT JOIN tiles ON tiles.tile_id = d.id'
          ' WHERE $decks AND d.delete_batch_id IS NULL'
          ' UNION ALL'
          ' SELECT NULL, NULL, NULL,$_numbers FROM card_days',
          variables: [
            Variable<int>(days.utcOffset.inSeconds),
            Variable<int>(days.weekStart),
            Variable<int>(days.monthStart),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
        )
        .get();
    return [for (final row in rows) _levelRowOf(row)];
  }
}

LevelRow _levelRowOf(QueryRow row) => (
  deckId: row.readNullable<String>('deck_id'),
  name: row.readNullable<String>('name'),
  week: _countsOf(row, 'week'),
  month: _countsOf(row, 'month'),
);

/// A deck with no activity has no `tiles` row: its numbers are zero.
CountsRow _countsOf(QueryRow row, String range) => (
  cards: row.readNullable<int>('${range}_cards') ?? 0,
  days: row.readNullable<int>('${range}_days') ?? 0,
  learning: row.readNullable<int>('${range}_learning') ?? 0,
  reviewing: row.readNullable<int>('${range}_reviewing') ?? 0,
);
```

- [ ] **Step 5: Declare the repository, and map the rows to the read model**

Create `lib/features/progress/data/mappers/progress_mapper.dart`:

```dart
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';

/// The last seven days' split from their rows (Progress spec §6.5).
List<ActiveDay> activeDaysOf(List<ActiveDayRow> rows) => [
  for (final row in rows)
    ActiveDay(day: row.day, learning: row.learning, reviewing: row.reviewing),
];

/// A level from the rows of its statement: the one row with no deck is the
/// total, never added up from the others (Progress spec D5).
ProgressLevel levelOf(List<LevelRow> rows) => ProgressLevel(
  total: _rangeOf(rows.singleWhere((row) => row.deckId == null)),
  decks: [
    for (final row in rows)
      if (row.deckId case final deckId?)
        ProgressDeckRow(
          deckId: deckId,
          // A deck row always has its name (`deck.name` is NOT NULL).
          name: row.name!,
          progress: _rangeOf(row),
        ),
  ],
);

RangeProgress _rangeOf(LevelRow row) =>
    RangeProgress(week: _numbersOf(row.week), month: _numbersOf(row.month));

ProgressNumbers _numbersOf(CountsRow counts) => ProgressNumbers(
  activeCards: counts.cards,
  activeDays: counts.days,
  learningCardDays: counts.learning,
  reviewingCardDays: counts.reviewing,
);
```

Create `lib/features/progress/domain/repositories/progress_repository.dart`:

```dart
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';

/// The Progress screen's reads (UC-PROGRESS-001, UC-PROGRESS-002). The one
/// implementation is `ProgressRepositoryImpl` (data layer); the contract
/// exists for ADR-010's reason: domain stays framework-free and tests
/// substitute a fake.
abstract interface class ProgressRepository {
  /// `/progress` (Progress spec §6): the overview and every root deck with
  /// the numbers of its tree for both ranges, read as one snapshot on the
  /// local days of [days]; again after every write to the history, the cards
  /// or the decks. It writes nothing (BR-PROGRESS-009).
  Stream<Progress> watchProgress(ProgressDays days);
}
```

- [ ] **Step 6: Read the snapshot in one transaction**

Create `lib/features/progress/data/repositories/progress_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/data/mappers/progress_mapper.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// Reads the Progress screen (UC-PROGRESS-001, UC-PROGRESS-002; Progress
/// spec §6): its statements in one transaction, once when listened to and
/// again after every write it can see.
final class ProgressRepositoryImpl implements ProgressRepository {
  ProgressRepositoryImpl(this._db) : _progress = ProgressDao(_db);

  final AppDatabase _db;
  final ProgressDao _progress;

  @override
  Stream<Progress> watchProgress(ProgressDays days) => _progress
      .changes()
      .asyncMap((_) => _db.transaction(() => _progressOf(days)))
      .mapDatabaseErrors();

  /// The history's days, the last seven with their split and the root
  /// level, read in the caller's transaction, so Today, the streak and the
  /// deck numbers see one state of the database (UC-PROGRESS-001 step 4).
  Future<Progress> _progressOf(ProgressDays days) async => Progress(
    overview: progressOverviewOf(
      activeDays: await _progress.activeDays(days),
      week: activeDaysOf(await _progress.weekActivity(days)),
      days: days,
    ),
    level: levelOf(await _progress.rootLevel(days)),
    validUntil: days.validUntil,
  );
}
```

- [ ] **Step 7: Give the repository a provider**

Create `lib/features/progress/di/progress_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'progress_repository_provider.g.dart';

@riverpod
ProgressRepository progressRepository(Ref ref) =>
    ProgressRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 8: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run prints `Built with build_runner`, and `progress_repository_provider.g.dart` exists next to its provider.

- [ ] **Step 9: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 10: Run the task's tests**

```bash
flutter test test/features/progress/data/watch_progress_stream_test.dart \
  test/features/progress/data/watch_progress_test.dart
```

Expected: `+18: All tests passed!`

- [ ] **Step 11: Run the phased gate**

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

Expected: `No issues found!`; `+1359: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 12: Commit**

```bash
git add docs/_generated \
  lib/features/progress/data/datasources/progress_dao.dart \
  lib/features/progress/data/mappers/progress_mapper.dart \
  lib/features/progress/data/repositories/progress_repository_impl.dart \
  lib/features/progress/di/progress_repository_provider.dart \
  lib/features/progress/domain/models/progress_model.dart \
  lib/features/progress/domain/repositories/progress_repository.dart \
  test/features/progress/data/watch_progress_stream_test.dart \
  test/features/progress/data/watch_progress_test.dart \
  test/support/progress_fixtures.dart
git commit -F - <<'EOF'
feat(progress): the library level of progress reads one snapshot

ProgressRepository reads /progress in one transaction: the days with
activity over the whole history, the last seven days' card-days with their
split, and every root deck with the four numbers of its tree for 7 and 30
days, with the library's total from the same statement (UC-PROGRESS-001,
UC-PROGRESS-002; Progress spec §6). A row's day is taken at the read's UTC
offset; browse rows and the Trash count nowhere; nothing on the path writes.
It reads again after every write to review_log, card or deck.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 5: A deck's level: `/progress/:deckId`

**Files:**
- Modify: `lib/features/progress/data/datasources/progress_dao.dart`, `lib/features/progress/data/mappers/progress_mapper.dart`, `lib/features/progress/data/repositories/progress_repository_impl.dart`, `lib/features/progress/domain/models/progress_model.dart`, `lib/features/progress/domain/repositories/progress_repository.dart`
- Test (create): `test/features/progress/data/watch_deck_progress_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 4's `ProgressDao`, mapper and repository; `deckAndAncestors`
  (`lib/core/database/queries/deck_queries.drift`, row `Deck`).
- Produces:
  - In `progress_model.dart`: `sealed class DeckProgress`,
    `DeckProgressLevel({required List<ProgressPathSegment> path, required ProgressLevel level, required DateTime validUntil})`,
    `ProgressDeckMissing()` and
    `ProgressPathSegment({required String deckId, required String name})`.
  - In `ProgressDao`: `Future<List<LevelRow>> childLevel(String deckId, ProgressDays days)`
    and `Future<List<Deck>> deckPath(String deckId)`.
  - `List<ProgressPathSegment> pathOf(List<Deck> decks)` in the mapper.
  - `Stream<DeckProgress> watchDeckProgress({required String deckId, required ProgressDays days})`
    on the repository.

Spec §5.2, §6.2 statements 4 and 5, §6.6. A deck's level walks each
direct child's subtree the way the Library's deck level does, adds the deck's
own cards to the total, and names the deck missing, not failed, when it is gone
or in the Trash.

- [ ] **Step 1: Write the failing tests**

Create `test/features/progress/data/watch_deck_progress_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/deck/domain/failures/deck_failure.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-PROGRESS-002 steps 5 and 6, A1 and E2: `/progress/:deckId`, a deck's
// level (Progress spec §5.2, §6.2).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late ProgressRepositoryImpl progress;
  final now = DateTime(2026, 9, 25, 12);
  // Noon on 25 September 2026 in Hanoi.
  final days = ProgressDays.of(
    DateTime.utc(2026, 9, 25, 5),
    const Duration(hours: 7),
  );

  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    progress = ProgressRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<DeckProgress> read(String deckId) =>
      progress.watchDeckProgress(deckId: deckId, days: days).first;

  Future<DeckProgressLevel> levelOf(String deckId) async =>
      (await read(deckId)) as DeckProgressLevel;

  /// The month's active cards per row, in the list's order.
  Map<String, int> monthCards(DeckProgressLevel level) => {
    for (final deck in level.level.decksFor(ProgressRange.month))
      deck.name: deck.progress.month.activeCards,
  };

  test("a deck's level lists its direct children, each with its whole "
      'subtree; its total holds every card below it (BR-PROGRESS-004; '
      'UC-PROGRESS-002 step 5)', () async {
    final korean = await decks.root('Korean');
    final grammar = await decks.sub(korean.id, 'Grammar');
    final unit = await decks.sub(grammar.id, 'Unit');
    final vocab = await decks.sub(korean.id, 'Vocab');
    await learnedCard(db, unit.id, 'g1');
    await learnedCard(db, vocab.id, 'v1');
    await learnedCard(db, vocab.id, 'v2');
    await lockScheduler(db, korean.id);
    await answer(db, 'g1', hanoi(9, 24, 9));
    await answer(db, 'v1', hanoi(9, 24, 10));
    await answer(db, 'v2', hanoi(9, 25, 9));

    final level = await levelOf(korean.id);

    expect([for (final step in level.path) step.name], ['Korean']);
    expect(monthCards(level), {'Vocab': 2, 'Grammar': 1});
    expect(
      (level.level.total.month.activeCards, level.level.total.month.activeDays),
      (3, 2),
    );
  });

  test('a deck of cards has no row, its total counts its own cards, and its '
      'path runs from the root (UC-PROGRESS-002 A1)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 25, 9));

    final level = await levelOf(lesson.id);

    expect(
      [for (final step in level.path) step.deckId],
      [korean.id, lesson.id],
    );
    expect(level.level.hasDecks, isFalse);
    expect(level.level.total.week.activeCards, 1);
  });

  test('a card moved to a sibling deck takes its history there '
      '(BR-PROGRESS-004)', () async {
    final korean = await decks.root('Korean');
    final a = await decks.sub(korean.id, 'A');
    final b = await decks.sub(korean.id, 'B');
    await learnedCard(db, a.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 10, 9));

    final moved = await CardRepositoryImpl(
      db,
      ScheduleRepositoryImpl(db, now: () => now),
      TagRepositoryImpl(db, now: () => now),
      now: () => now,
    ).moveCards(cardIds: {'c1'}, targetDeckId: b.id);
    expect(moved, isA<Ok<void, CardRejection>>());

    expect(monthCards(await levelOf(korean.id)), {'B': 1, 'A': 0});
  });

  test('a deck deleted, in the Trash or never there is missing, not an '
      'error (UC-PROGRESS-002 E2)', () async {
    final korean = await decks.root('Korean');
    final deleted = await decks.sub(korean.id, 'Deleted');
    final trashed = await decks.sub(korean.id, 'Trashed');
    expect(
      await decks.deleteDeck(deckId: deleted.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );

    expect(await read(deleted.id), isA<ProgressDeckMissing>());
    expect(await read(trashed.id), isA<ProgressDeckMissing>());
    expect(await read('no such deck'), isA<ProgressDeckMissing>());
  });

  test("a deck's level reads again on an answer and a renamed child, and "
      'turns missing when the deck is deleted (BR-PROGRESS-008)', () async {
    final korean = await decks.root('Korean');
    final grammar = await decks.sub(korean.id, 'Grammar');
    final unit = await decks.sub(grammar.id, 'Unit');
    await learnedCard(db, unit.id, 'c1');
    await lockScheduler(db, korean.id);
    final snapshots = <DeckProgress>[];
    final subscription = progress
        .watchDeckProgress(deckId: grammar.id, days: days)
        .listen(snapshots.add);
    await pumpEventQueue();

    await answer(db, 'c1', hanoi(9, 25, 9));
    await pumpEventQueue();
    expect(monthCards(snapshots.last as DeckProgressLevel), {'Unit': 1});

    expect(
      await decks.renameDeck(deckId: unit.id, name: 'Unit 1'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(monthCards(snapshots.last as DeckProgressLevel), {'Unit 1': 1});

    expect(
      await decks.deleteDeck(deckId: grammar.id),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();
    expect(snapshots.last, isA<ProgressDeckMissing>());
    await subscription.cancel();
  });

  test("a child in the Trash is neither listed nor counted at its parent's "
      'level (spec D7)', () async {
    final korean = await decks.root('Korean');
    final kept = await decks.sub(korean.id, 'Kept');
    final trashed = await decks.sub(korean.id, 'Trashed');
    await learnedCard(db, kept.id, 'k1');
    await insertCard(
      db,
      id: 't1',
      deckId: trashed.id,
      back: 't1',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 30),
      box: 2,
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );
    await lockScheduler(db, korean.id);
    await answer(db, 'k1', hanoi(9, 25, 9));
    await answer(db, 't1', hanoi(9, 25, 9));

    final level = await levelOf(korean.id);

    expect(monthCards(level), {'Kept': 1});
    expect(level.level.total.month.activeCards, 1);
  });

  test(
    'a deck moved to another root while its level is open takes its new '
    'path, and its numbers stay (BR-PROGRESS-004, BR-PROGRESS-008)',
    () async {
      final korean = await decks.root('Korean');
      final english = await decks.root('English');
      final lesson = await decks.sub(korean.id, 'Lesson');
      await learnedCard(db, lesson.id, 'c1');
      await lockScheduler(db, korean.id);
      await lockScheduler(db, english.id);
      await answer(db, 'c1', hanoi(9, 25, 9));
      final snapshots = <DeckProgress>[];
      final subscription = progress
          .watchDeckProgress(deckId: lesson.id, days: days)
          .listen(snapshots.add);
      await pumpEventQueue();

      expect(
        await decks.moveDeck(deckId: lesson.id, newParentId: english.id),
        isA<Ok<void, DeckRejection>>(),
      );
      await pumpEventQueue();

      final level = snapshots.last as DeckProgressLevel;
      expect([for (final step in level.path) step.name], ['English', 'Lesson']);
      expect(level.level.total.week.activeCards, 1);
      await subscription.cancel();
    },
  );

  test('an empty deck has no row and zero numbers, and is not missing '
      '(UC-PROGRESS-002 A1)', () async {
    final korean = await decks.root('Korean');
    final empty = await decks.sub(korean.id, 'Empty');

    final level = await levelOf(empty.id);

    expect(level.level.hasDecks, isFalse);
    expect(level.level.total.month.hasActivity, isFalse);
  });

  test("reading a deck's level writes nothing (BR-PROGRESS-007)", () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    await learnedCard(db, lesson.id, 'c1');
    await lockScheduler(db, korean.id);
    await answer(db, 'c1', hanoi(9, 25, 9));
    final before = await totalChanges(db);

    await read(korean.id);
    await read('no such deck');

    expect(await totalChanges(db), before);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/data/watch_deck_progress_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the deck level does not exist yet. The first errors: `Error: 'DeckProgressLevel' isn't a type.`, `Error: 'ProgressDeckMissing' isn't a type.`, `Error: 'DeckProgress' isn't a type.`

- [ ] **Step 3: Add a deck's level to the read model**

In `lib/features/progress/domain/models/progress_model.dart`:

Replace

```dart
  final DateTime validUntil;
}
```

with

```dart
  final DateTime validUntil;
}

/// `/progress/:deckId` (UC-PROGRESS-002 at a deck's level).
sealed class DeckProgress {
  const DeckProgress();
}

/// A deck's level: its path, and a row per direct child with the numbers of
/// its subtree. A deck that holds cards has no row (UC-PROGRESS-002 A1); its
/// total still counts them.
final class DeckProgressLevel extends DeckProgress {
  const DeckProgressLevel({
    required this.path,
    required this.level,
    required this.validUntil,
  });

  /// The root first, the deck last.
  final List<ProgressPathSegment> path;

  final ProgressLevel level;

  /// The next local midnight (BR-PROGRESS-003).
  final DateTime validUntil;
}

/// The deck of a link is gone or in the Trash. Not an error: reading again
/// would find the same (UC-PROGRESS-002 E2).
final class ProgressDeckMissing extends DeckProgress {
  const ProgressDeckMissing();
}

/// A deck on the path from the root to the deck of a level.
final class ProgressPathSegment {
  const ProgressPathSegment({required this.deckId, required this.name});

  final String deckId;
  final String name;
}
```

- [ ] **Step 4: Read a deck's level and its path**

In `lib/features/progress/data/datasources/progress_dao.dart`:

Replace

```dart

/// The answers that count, `r`, with their card `c` and its deck `k`: live
/// cards only, never a `browse` row (BR-PROGRESS-012), on a local day, at the
/// read's offset `?1`, that meets [days] (Progress spec §6.1).
String _answers(String days) =>
    ' FROM review_log r'
    ' JOIN card c ON c.id = r.card_id'
    ' JOIN deck k ON k.id = c.deck_id'
    ' WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL'
```

with

```dart

/// The answers that count, `r`, with their card `c` and its deck `k`, and
/// [join] when a scope narrows them: live cards only, never a `browse` row
/// (BR-PROGRESS-012), on a local day, at the read's offset `?1`, that meets
/// [days] (Progress spec §6.1).
String _answers(String days, {String join = ''}) =>
    ' FROM review_log r'
    ' JOIN card c ON c.id = r.card_id'
    ' JOIN deck k ON k.id = c.deck_id$join'
    ' WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL'
```

Replace

```dart
/// Learning (BR-PROGRESS-005).
String _cardDays({required String tile, required String days}) =>
    'SELECT c.id AS card_id, $tile AS tile_id,'
```

with

```dart
/// Learning (BR-PROGRESS-005).
String _cardDays({
  required String tile,
  required String days,
  String join = '',
}) =>
    'SELECT c.id AS card_id, $tile AS tile_id,'
```

Replace

```dart
    " MAX(r.kind = 'learning') AS is_learning"
    '${_answers(days)}'
    ' GROUP BY c.id, day';

```

with

```dart
    " MAX(r.kind = 'learning') AS is_learning"
    '${_answers(days, join: join)}'
    ' GROUP BY c.id, day';

/// The decks of `?5`'s level, `tile_id` each direct child walked down its
/// subtree as `deckLevelOfChildren` walks it (`UNION`, cycle safe, no cap),
/// and `?5` itself with no tile: its own cards count in the total only
/// (BR-PROGRESS-004).
const _childScope =
    'tree(tile_id, deck_id) AS ('
    ' SELECT id, id FROM deck WHERE parent_id = ?5 AND delete_batch_id IS NULL'
    ' UNION'
    ' SELECT tree.tile_id, d.id FROM deck d JOIN tree ON d.parent_id = tree.deck_id'
    ' WHERE d.delete_batch_id IS NULL),'
    ' scope(tile_id, deck_id) AS ('
    ' SELECT tile_id, deck_id FROM tree UNION ALL SELECT NULL, ?5),';

```

Replace

```dart

  /// Fires once when listened to, then after every write to the history,
```

with

```dart

  /// Every active direct child of [deckId] with the numbers of its subtree,
  /// and the total of [deckId]'s whole subtree from the same statement
  /// (BR-PROGRESS-002, BR-PROGRESS-004).
  Future<List<LevelRow>> childLevel(String deckId, ProgressDays days) => _level(
    days,
    scope: _childScope,
    cardDays: _cardDays(
      tile: 's.tile_id',
      days: 'BETWEEN ?3 AND ?4',
      join: ' JOIN scope s ON s.deck_id = k.id',
    ),
    decks: 'd.parent_id = ?5',
    extra: [Variable<String>(deckId)],
  );

  /// [deckId] and every deck above it, root first; none when [deckId] is not
  /// an active deck (UC-PROGRESS-002 E2).
  Future<List<Deck>> deckPath(String deckId) =>
      _db.deckAndAncestors(deckId).get();

  /// Fires once when listened to, then after every write to the history,
```

Replace

```dart
  /// is its id, then one total row over every card-day of [cardDays]
  /// (Progress spec D5).
  Future<List<LevelRow>> _level(
```

with

```dart
  /// is its id, then one total row over every card-day of [cardDays]
  /// (Progress spec D5). [scope] defines the tables [cardDays] joins.
  Future<List<LevelRow>> _level(
```

Replace

```dart
    required String decks,
  }) async {
```

with

```dart
    required String decks,
    String scope = '',
    List<Variable<Object>> extra = const [],
  }) async {
```

Replace

```dart
        .customSelect(
          'WITH card_days AS ($cardDays),'
          ' tiles AS (SELECT tile_id,$_numbers FROM card_days GROUP BY tile_id)'
```

with

```dart
        .customSelect(
          'WITH RECURSIVE $scope card_days AS ($cardDays),'
          ' tiles AS (SELECT tile_id,$_numbers FROM card_days GROUP BY tile_id)'
```

Replace

```dart
            Variable<int>(days.monthStart),
            Variable<int>(days.today),
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
```

with

```dart
            Variable<int>(days.monthStart),
            Variable<int>(days.today),
            ...extra,
          ],
          readsFrom: {_db.reviewLog, _db.card, _db.deck},
```

- [ ] **Step 5: Declare it, and map the path**

In `lib/features/progress/data/mappers/progress_mapper.dart`:

Replace

```dart
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
```

with

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/progress/data/datasources/progress_dao.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
```

Replace

```dart

RangeProgress _rangeOf(LevelRow row) =>
```

with

```dart

/// The breadcrumb of a deck level, root first (UC-PROGRESS-002 step 2).
List<ProgressPathSegment> pathOf(List<Deck> decks) => [
  for (final deck in decks)
    ProgressPathSegment(deckId: deck.id, name: deck.name),
];

RangeProgress _rangeOf(LevelRow row) =>
```

In `lib/features/progress/domain/repositories/progress_repository.dart`:

Replace

```dart
  Stream<Progress> watchProgress(ProgressDays days);
}
```

with

```dart
  Stream<Progress> watchProgress(ProgressDays days);

  /// `/progress/:deckId`: [deckId]'s path and every direct child with the
  /// numbers of its subtree, for both ranges, as one snapshot on the local
  /// days of [days]; [ProgressDeckMissing] while [deckId] is not an active
  /// deck. Again after every write it can see; it writes nothing
  /// (BR-PROGRESS-007).
  Stream<DeckProgress> watchDeckProgress({
    required String deckId,
    required ProgressDays days,
  });
}
```

- [ ] **Step 6: Read it in one transaction**

In `lib/features/progress/data/repositories/progress_repository_impl.dart`:

Replace

```dart

  /// The history's days, the last seven with their split and the root
```

with

```dart

  @override
  Stream<DeckProgress> watchDeckProgress({
    required String deckId,
    required ProgressDays days,
  }) => _progress
      .changes()
      .asyncMap((_) => _db.transaction(() => _deckProgressOf(deckId, days)))
      .mapDatabaseErrors();

  /// The deck's path, then its level when the deck is there, in the
  /// caller's transaction (Progress spec §6.3).
  Future<DeckProgress> _deckProgressOf(String deckId, ProgressDays days) async {
    final path = await _progress.deckPath(deckId);
    if (path.isEmpty) return const ProgressDeckMissing();
    return DeckProgressLevel(
      path: pathOf(path),
      level: levelOf(await _progress.childLevel(deckId, days)),
      validUntil: days.validUntil,
    );
  }

  /// The history's days, the last seven with their split and the root
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
flutter test test/features/progress/data/watch_deck_progress_test.dart
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

Expected: `No issues found!`; `+1368: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 10: Commit**

```bash
git add docs/_generated \
  lib/features/progress/data/datasources/progress_dao.dart \
  lib/features/progress/data/mappers/progress_mapper.dart \
  lib/features/progress/data/repositories/progress_repository_impl.dart \
  lib/features/progress/domain/models/progress_model.dart \
  lib/features/progress/domain/repositories/progress_repository.dart \
  test/features/progress/data/watch_deck_progress_test.dart
git commit -F - <<'EOF'
feat(progress): a deck's level of progress, its path and its direct children

watchDeckProgress reads /progress/:deckId in one transaction: the deck's
path, root first, then each direct child with the four numbers of its
subtree and the total of the deck's whole subtree, its own cards included
(UC-PROGRESS-002 steps 5 and 6, A1). A deck that is gone or in the Trash is
ProgressDeckMissing, not an error (E2).
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 6: The use cases, and the package's documents

**Files:**
- Create: `lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart`, `lib/features/progress/domain/usecases/watch_progress_use_case.dart`
- Modify: `docs/features/progress/README.md`, `docs/features/progress/data.md`, `docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md`, `docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md`, `docs/shared/ui/screen-handoff/01-deck-list.md`, `docs/wbs_BE.md`, `docs/wbs_FE.md`
- Test (create): `test/features/progress/domain/watch_progress_use_case_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `ProgressRepository` (Tasks 4 and 5); `DayClock` and
  `watchEachLocalDay` (`lib/core/clock/day_clock.dart`); `FakeDayClock`
  (`test/support/`).
- Produces: `WatchProgressUseCase(ProgressRepository, DayClock)` with
  `Stream<Progress> call()` and `WatchDeckProgressUseCase(ProgressRepository, DayClock)`
  with `Stream<DeckProgress> call(String deckId)`
  (`progress/domain/usecases/`); the use cases' `code:` names them; the
  progress README and a new `features/progress/data.md` describe the reads;
  `wbs_BE.md` has BE-A7 done.

Spec §7, §10; Clarifications 2, 3 and 6. Each day reads the clock and
its offset once, as the Library and the Study tab do, so at local midnight the
window slides, Today returns to 0 and the streak takes its held branch, with no
write.

- [ ] **Step 1: Write the failing tests**

Create `test/features/progress/domain/watch_progress_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/progress/data/repositories/progress_repository_impl.dart';
import 'package:memox/features/progress/domain/models/progress_level_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/models/progress_overview_model.dart';
import 'package:memox/features/progress/domain/usecases/watch_deck_progress_use_case.dart';
import 'package:memox/features/progress/domain/usecases/watch_progress_use_case.dart';

import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/progress_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-PROGRESS-001 A4 and UC-PROGRESS-002 A4: the Progress screen across a
// local midnight (BR-PROGRESS-018; Progress spec §7). Times are local.

void main() {
  late AppDatabase db;
  late String lessonId;
  final evening = DateTime(2026, 9, 25, 21);

  setUp(() async {
    db = openTestDatabase();
    final decks = DeckRepositoryImpl(db, now: () => evening);
    final korean = await decks.root('Korean');
    lessonId = (await decks.sub(korean.id, 'Lesson')).id;
    await learnedCard(db, lessonId, 'c1');
    await lockScheduler(db, korean.id);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  test('at local midnight the window slides a day, Today returns to 0 and '
      'the streak is held from yesterday, with no write (BR-PROGRESS-018; '
      'UC-PROGRESS-001 A4)', () async {
    await answer(db, 'c1', DateTime(2026, 9, 25, 9));
    final clock = FakeDayClock(evening);
    final snapshots = <Progress>[];
    final subscription = WatchProgressUseCase(
      ProgressRepositoryImpl(db),
      clock,
    ).call().listen(snapshots.add);
    await pumpEventQueue();
    final before = await totalChanges(db);
    expect(snapshots.last.overview.today.total, 1);

    clock.startDay(DateTime(2026, 9, 26));
    await pumpEventQueue();

    final overview = snapshots.last.overview;
    expect(overview.today.total, 0);
    expect(overview.lastSevenDays.last.date, DateTime(2026, 9, 26));
    expect(
      (overview.streak.days, overview.streak.state),
      (1, StreakState.heldFromYesterday),
    );
    expect(snapshots.last.validUntil, DateTime(2026, 9, 27).toUtc());
    expect(await totalChanges(db), before);
    await subscription.cancel();
  });

  test(
    "at local midnight a deck's week slides too (UC-PROGRESS-002 A4)",
    () async {
      // Six days before the evening: the last day of its week.
      await answer(db, 'c1', DateTime(2026, 9, 19, 9));
      final clock = FakeDayClock(evening);
      final snapshots = <DeckProgress>[];
      final subscription = WatchDeckProgressUseCase(
        ProgressRepositoryImpl(db),
        clock,
      ).call(lessonId).listen(snapshots.add);
      await pumpEventQueue();
      RangeProgress total() =>
          (snapshots.last as DeckProgressLevel).level.total;
      expect(total().week.activeCards, 1);

      clock.startDay(DateTime(2026, 9, 26));
      await pumpEventQueue();

      expect(total().week.activeCards, 0);
      expect(total().month.activeCards, 1);
      await subscription.cancel();
    },
  );
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/progress/domain/watch_progress_use_case_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the use cases do not exist yet. The first errors: `Error: Error when reading 'lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart': No such file or directory`, `Error: Error when reading 'lib/features/progress/domain/usecases/watch_progress_use_case.dart': No such file or directory`, `Error: Method not found: 'WatchProgressUseCase'.`

- [ ] **Step 3: Write the two use cases**

Create `lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// UC-PROGRESS-002 at a deck's level: `/progress/:deckId`, again on every
/// write it can see and at every local midnight, with no write
/// (BR-PROGRESS-008; UC-PROGRESS-002 A4; Progress spec §7, D4).
final class WatchDeckProgressUseCase {
  const WatchDeckProgressUseCase(this._progress, this._clock);

  final ProgressRepository _progress;
  final DayClock _clock;

  Stream<DeckProgress> call(String deckId) => watchEachLocalDay(
    _clock,
    (now) => _progress.watchDeckProgress(
      deckId: deckId,
      days: ProgressDays.of(now, now.timeZoneOffset),
    ),
  );
}
```

Create `lib/features/progress/domain/usecases/watch_progress_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/progress/domain/models/progress_days_model.dart';
import 'package:memox/features/progress/domain/models/progress_model.dart';
import 'package:memox/features/progress/domain/repositories/progress_repository.dart';

/// UC-PROGRESS-001, and UC-PROGRESS-002 at the library level: `/progress`,
/// again on every write it can see and at every local midnight, when the
/// window slides a day, Today returns to 0 and the streak takes its held
/// branch, with no write. Each day reads the clock and its offset once
/// (BR-PROGRESS-013, BR-PROGRESS-018; Progress spec §7, D4).
final class WatchProgressUseCase {
  const WatchProgressUseCase(this._progress, this._clock);

  final ProgressRepository _progress;
  final DayClock _clock;

  Stream<Progress> call() => watchEachLocalDay(
    _clock,
    (now) => _progress.watchProgress(ProgressDays.of(now, now.timeZoneOffset)),
  );
}
```

- [ ] **Step 4: Record the package in the use cases, the documents and the WBS**

In `docs/features/progress/README.md`:

Replace

```markdown
feature: progress
code: []
depends_on: [deck, srs, study]
```

with

```markdown
feature: progress
code: [lib/features/progress/domain, lib/features/progress/data, lib/features/progress/di]
depends_on: [deck, srs, study]
```

Replace

```markdown
Tiến độ theo deck và Progress overview (V8.0): đọc lại lịch sử học, không ghi gì.

> ⚠️ OPEN QUESTION: repo chưa có code ứng dụng (không có `lib/`), nên `code` của feature và mọi UC là `[]`.

```

with

```markdown
Tiến độ theo deck và Progress overview (V8.0): đọc lại lịch sử học, không ghi gì.

```

Create `docs/features/progress/data.md`:

```markdown
# Progress — dữ liệu

Bảng, cột, index và invariant nằm ở `shared/data/schema.md`. File này chỉ giữ phần dữ liệu riêng của feature.

## Đọc lịch sử học

Progress chỉ đọc `review_log`, nối với `card` và `deck`. Nó không ghi hàng nào và không
mở hay đóng phiên nào (BR-PROGRESS-007, BR-PROGRESS-009).

- **Lượt được tính:** lượt của thẻ còn sống, thẻ và deck không nằm trong Trash. Hàng có
  `mode = 'browse'` không bao giờ được tính (BR-PROGRESS-012). Card bị xoá cứng mang lịch
  sử của nó đi theo cascade của schema (BR-PROGRESS-017).
- **Ngày của một lượt:** `(answered_at + offset) / 86400`, với `answered_at` tính bằng
  giây UTC và offset là UTC offset của lần đọc, áp cho mọi hàng kể cả hàng cũ
  (BR-PROGRESS-011). Dart tính hôm nay, ngày đầu của mỗi khoảng và nửa đêm kế tiếp; SQL
  không tự dẫn xuất nửa đêm (BR-PROGRESS-013).
- **Card-day:** một thẻ trong một ngày là một card-day. Card-day là Learning khi ngày đó
  có ít nhất một lượt `kind = 'learning'`, còn lại là Reviewing (BR-PROGRESS-002,
  BR-PROGRESS-005, BR-PROGRESS-014). Lịch sử quy cho vị trí hiện tại của thẻ
  (BR-PROGRESS-004).

## Các câu lệnh

`/progress` đọc ba câu lệnh trong một transaction:

1. các ngày có học trên toàn lịch sử tới hôm nay, cho streak (BR-PROGRESS-016);
2. card-day của bảy ngày gần nhất, tách Learning và Reviewing, cho Today và biểu đồ
   (BR-PROGRESS-014, BR-PROGRESS-015);
3. mọi root deck với bốn số của cả cây cho 7 và 30 ngày, và một hàng tổng từ cùng câu
   lệnh (BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-003).

`/progress/:deckId` đọc đường dẫn của deck, rồi các deck con trực tiếp với bốn số của
subtree và hàng tổng của cả subtree, gồm thẻ nằm trực tiếp trong deck. Deck không còn
hoặc đang trong Trash cho ra trạng thái "deck không còn" (UC-PROGRESS-002 E2).

## Khi nào đọc lại

Sau mỗi lần ghi vào `review_log`, `card` hay `deck` (một transaction, một lần đọc), và ở
mỗi nửa đêm địa phương (BR-PROGRESS-008, BR-PROGRESS-018).
```

In `docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md`:

Replace

```markdown
rules: [BR-MODE-005, BR-CORE-002, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGRESS-012, BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016, BR-PROGRESS-017, BR-PROGRESS-018, BR-STUDY-074]
code: []
---
```

with

```markdown
rules: [BR-MODE-005, BR-CORE-002, BR-PROGRESS-009, BR-PROGRESS-010, BR-PROGRESS-011, BR-PROGRESS-012, BR-PROGRESS-013, BR-PROGRESS-014, BR-PROGRESS-015, BR-PROGRESS-016, BR-PROGRESS-017, BR-PROGRESS-018, BR-STUDY-074]
code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart]
---
```

In `docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md`:

Replace

```markdown
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-CORE-001, BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-003, BR-PROGRESS-004, BR-PROGRESS-005, BR-PROGRESS-006, BR-PROGRESS-007, BR-PROGRESS-008, BR-SRS-015, BR-SRS-023, BR-STUDY-074]
code: []
---
```

with

```markdown
rules: [BR-DECK-001, BR-DECK-002, BR-DECK-003, BR-CORE-001, BR-PROGRESS-001, BR-PROGRESS-002, BR-PROGRESS-003, BR-PROGRESS-004, BR-PROGRESS-005, BR-PROGRESS-006, BR-PROGRESS-007, BR-PROGRESS-008, BR-SRS-015, BR-SRS-023, BR-STUDY-074]
code: [lib/features/progress/domain/usecases/watch_progress_use_case.dart, lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart]
---
```

In `docs/shared/ui/screen-handoff/01-deck-list.md`:

Replace

```markdown
| "Move to Trash", "Recoverable for 30 days", neutral confirm, Undo snackbar | "Delete deck?" naming the sub-deck and card counts, destructive confirm, no Undo | BR-DECK-022, BR-DECK-023 |
| Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for BE-A7) |
| Root search hint "Search decks, cards, tags" | "Search decks" | Spec A11 (waits for BE-A8) |
```

with

```markdown
| "Move to Trash", "Recoverable for 30 days", neutral confirm, Undo snackbar | "Delete deck?" naming the sub-deck and card counts, destructive confirm, no Undo | BR-DECK-022, BR-DECK-023 |
| Mastery bar on every row, donut and "Mastered" on the summary | Hidden | Spec A5 (waits for a BR/UC definition, blocked in `wbs_BE.md`) |
| Root search hint "Search decks, cards, tags" | "Search decks" | Spec A11 (waits for BE-A8) |
```

Replace

```markdown
| Study this deck, Study options | under Coming soon | FE-A6, FE-A3 |
| Sort by progress | under Coming soon | BE-A7 |
| Mastery bar, donut | hidden | BE-A7 |
| Due strip tap | not interactive | FE-A8 |
```

with

```markdown
| Study this deck, Study options | under Coming soon | FE-A6, FE-A3 |
| Sort by progress | under Coming soon | a BR/UC definition (blocked in `wbs_BE.md`) |
| Mastery bar, donut | hidden | a BR/UC definition (blocked in `wbs_BE.md`) |
| Due strip tap | not interactive | FE-A8 |
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-A6 | Study Home, 1 use case (UC-STUDY-002): một snapshot trong một transaction gồm phiên có thể Resume (bốn điều kiện của BR-STUDY-075, dùng chung với Tiếp tục của màn vào học) và mọi root deck kèm workload của cả cây; ba trạng thái đã tải, thứ tự của BR-STUDY-076 và tổng của hero ở domain; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | M | [spec](superpowers/specs/2026-09-25-study-home-backend-design.md) và [plan](superpowers/plans/2026-09-25-study-home-backend.md) gói 3; test trong `test/features/study/` | FE-A8 dựng màn 13 trên use case này |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

with

```markdown
| BE-A6 | Study Home, 1 use case (UC-STUDY-002): một snapshot trong một transaction gồm phiên có thể Resume (bốn điều kiện của BR-STUDY-075, dùng chung với Tiếp tục của màn vào học) và mọi root deck kèm workload của cả cây; ba trạng thái đã tải, thứ tự của BR-STUDY-076 và tổng của hero ở domain; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | M | [spec](superpowers/specs/2026-09-25-study-home-backend-design.md) và [plan](superpowers/plans/2026-09-25-study-home-backend.md) gói 3; test trong `test/features/study/` | FE-A8 dựng màn 13 trên use case này |
| BE-A7 | Progress, 2 use case (UC-PROGRESS-001, UC-PROGRESS-002): tổng quan (Today tách Learning/Reviewing, bảy ngày, streak) và tiến độ theo deck ở cấp thư viện và cấp deck (bốn số cho 7 và 30 ngày từ một lần đọc, tổng đọc thẳng từ câu lệnh); ngày chia theo UTC offset của lần đọc; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | L | [spec](superpowers/specs/2026-09-25-progress-backend-design.md) và [plan](superpowers/plans/2026-09-25-progress-backend.md) gói 4; test trong `test/features/progress/` | FE-A9 dựng màn 22 trên hai use case này |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-A7 | Progress: tiến độ theo deck và tổng quan, chỉ đọc (UC-PROGRESS-001, UC-PROGRESS-002; BR-PROGRESS-001…BR-PROGRESS-018) | chưa bắt đầu | BE-A4 | L | [README progress](features/progress/README.md): chỉ đọc lịch sử học, không ghi gì | Cần dữ liệu `review_log` thật do BE-A4 ghi. Panel "Mastered x/y" và sort "progress" chờ tài liệu (xem Điểm chặn) |
| BE-A8 | Tìm kiếm toàn thư viện: tên deck, hai mặt card, tên tag (UC-SEARCH-001; BR-SEARCH-001…BR-SEARCH-009) | chưa bắt đầu | BE-03, BE-04, BE-05 | M | ADR-009, quyết định 2; UC chưa có code | Làm được ngay, song song với nhóm study |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-A8 | Tìm kiếm toàn thư viện: tên deck, hai mặt card, tên tag (UC-SEARCH-001; BR-SEARCH-001…BR-SEARCH-009) | chưa bắt đầu | BE-03, BE-04, BE-05 | M | ADR-009, quyết định 2; UC chưa có code | Làm được ngay, song song với nhóm study |
```

Replace

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 13/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  9 UC còn lại chưa có code.

```

with

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A7** (gói 4, [spec](superpowers/specs/2026-09-25-progress-backend-design.md),
  [plan](superpowers/plans/2026-09-25-progress-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 15/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-PROGRESS-001, UC-PROGRESS-002, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  7 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 3 (BE-A6).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 4 (BE-A7).

```

Replace

```markdown
| BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
| BE-A7 (một phần) | Chưa tài liệu nào định nghĩa panel "Mastered x/y" của IT-ORG-010 và sort "progress" mà UC-DECK-006 nhắc tới | Chỉ hai phần đó; phần còn lại của BE-A7 làm được | Bổ sung định nghĩa vào BR/UC trước khi làm |
| BE-A8 | Tên deck chưa có cột folded: fold trong Dart như giai đoạn 2, hay thêm cột (kéo theo migration và cần BE-D1) | Cách truy vấn và hiệu năng tìm kiếm | Quyết trong spec của BE-A8 |
```

with

```markdown
| BE-C1 | Chưa chốt có thêm dependency collation hay không | Thứ tự sort tên deck | Chủ dự án quyết |
| Mastery của danh sách deck | Chưa BR/UC nào nói thanh mastery, donut và dòng "Mastered" của màn 01 đếm gì, cũng như sort "tiến độ" mà UC-DECK-006 nhắc tới (đang là Coming soon). Trạng thái thẻ đã có ở BR-CARD-006…BR-CARD-008, và panel "mastered" của card list (IT-ORG-010) đã dựng trên số đếm của BE-A9 | Chỉ hai phần đó của danh sách deck; không thuộc Progress (BE-A7, spec gói 4 D1) | Bổ sung định nghĩa vào BR/UC của deck trước khi làm |
| BE-A8 | Tên deck chưa có cột folded: fold trong Dart như giai đoạn 2, hay thêm cột (kéo theo migration và cần BE-D1) | Cách truy vấn và hiệu năng tìm kiếm | Quyết trong spec của BE-A8 |
```

Replace

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 62 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-NAV (1), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

with

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 63 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-NAV (2), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

Replace

```markdown

1. Gói 4: BE-A7. Rồi BE-A8. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
```

with

```markdown

1. Gói 5: BE-A8. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
```

Replace

```markdown
  trên cây: #49 bỏ test nhắc IT-ORG-013, và gói 3 nhắc IT-NAV-002.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  trên cây: #49 bỏ test nhắc IT-ORG-013, và gói 3 nhắc IT-NAV-002.
- **Cập nhật ngày 2026-09-25:** BE-A7 xong trong gói 4; gói 4 nhắc IT-NAV-011. Điểm chặn
  về mastery chuyển từ BE-A7 sang danh sách deck, nơi nó thuộc về.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

In `docs/wbs_FE.md`:

Replace

```markdown
| FE-A1…FE-A10 | Mỗi màn hình cần use case của hạng mục BE tương ứng | Thứ tự làm | Theo [`wbs_BE.md`](wbs_BE.md) |
| FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ định nghĩa ở BE-A7 |
| FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
```

with

```markdown
| FE-A1…FE-A10 | Mỗi màn hình cần use case của hạng mục BE tương ứng | Thứ tự làm | Theo [`wbs_BE.md`](wbs_BE.md) |
| FE-A1 (một phần) | Panel "Mastered x/y" trên danh sách deck chưa được định nghĩa | Chỉ phần panel đó | Chờ BR/UC của deck định nghĩa nó (điểm chặn "Mastery của danh sách deck" trong [`wbs_BE.md`](wbs_BE.md)) |
| FE-C1 | Quyết định "implement the handoff as written" (spec UI base §2) giữ nguyên các token dưới ngưỡng contrast | Accessibility của toàn app | Chủ dự án quyết có sửa giá trị handoff không |
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/progress/domain/watch_progress_use_case_test.dart
```

Expected: `+2: All tests passed!`

- [ ] **Step 6: Run the phased gate**

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

Expected: `No issues found!`; `+1370: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 7: Commit**

```bash
git add docs/_generated \
  docs/features/progress/README.md \
  docs/features/progress/data.md \
  docs/features/progress/usecases/UC-PROGRESS-001-xem-tien-do-hoc.md \
  docs/features/progress/usecases/UC-PROGRESS-002-xem-tien-do-theo-deck.md \
  docs/shared/ui/screen-handoff/01-deck-list.md \
  docs/wbs_BE.md \
  docs/wbs_FE.md \
  lib/features/progress/domain/usecases/watch_deck_progress_use_case.dart \
  lib/features/progress/domain/usecases/watch_progress_use_case.dart \
  test/features/progress/domain/watch_progress_use_case_test.dart
git commit -F - <<'EOF'
feat(progress): the progress use cases, read again at each local midnight

WatchProgressUseCase and WatchDeckProgressUseCase read the Progress screen
through watchEachLocalDay, each day with its own clock and offset, so at
local midnight the window slides, Today returns to 0 and the streak is held
from yesterday, with no write (BR-PROGRESS-018). The use cases' code fields
name them, a data document describes the reads, and the WBS has BE-A7 done;
the mastery display and the progress sort stay blocked, now under the deck
list that owns them.
EOF
```

Append the session's attribution trailers to the message when you commit.


## Plan self-review

- **Spec coverage.** §5.1 the days and §5.2, §5.4 a level: Task 1. §5.3 the
  overview: Task 2. §6.4 the change stream: Task 3. §6.1–§6.3, §6.5, §6.6 at
  the library level: Task 4; at a deck's level: Task 5. §7 the use cases and
  the day: Task 6. §8 the contract for the UI: Tasks 4–6 (the repository's
  provider, the use cases). §9 tests: every line has its test in Tasks 1–6,
  and Study Home's stream tests stay green in Task 3. §10 documents: Task 6 and
  `docs/_generated/` in every task.
- **Scenarios named by the spec (§9).** The backend half of IT-NAV-011 step 2
  (Task 4) is named by a test.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the
  replay compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test: two in Task 4, three in
  Task 5.
