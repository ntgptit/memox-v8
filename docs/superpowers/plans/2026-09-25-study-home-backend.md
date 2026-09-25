# MemoX V8 Study Home Backend Implementation Plan (package 3)

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build BE-A6 of [`docs/wbs_BE.md`](../../wbs_BE.md), the read model of
the Study tab (UC-STUDY-002), as domain, data and di code with one use case, so
the UI session can build screen 13 of the kit on it. No UI.

**Architecture:** In `study/domain`, `StudyHome` holds the session Resume takes
up and the library's root decks with their workload; pure functions tell the
three loaded states apart (BR-STUDY-077), order the decks (BR-STUDY-076) and
add up the hero. In `study/data`, `StudyHomeRepositoryImpl` reads one snapshot
in one transaction — the Library root level's `deckLevelOfRoots`, the
resumable session through a SQL fragment the Study Entry's Continue now
shares, the counts of the round it serves, and the next due date — again after
every write the tab can see, through a stream that listens before it reads.
`WatchStudyHomeUseCase` reads it again at each local midnight.

**Tech Stack:** Flutter 3.47.5 (Dart 3.13.4), `flutter_riverpod` 3 with
`riverpod_generator`, `drift` 2.35. No dependency is added.

**Spec:** [`docs/superpowers/specs/2026-09-25-study-home-backend-design.md`](../specs/2026-09-25-study-home-backend-design.md),
approved 2026-09-25 and amended on this branch with the Clarifications below.
Business rules: `docs/features/study/rules/` (BR-STUDY-075, BR-STUDY-076,
BR-STUDY-077, BR-STUDY-068); use case:
`docs/features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md`;
data model: [`docs/shared/data/schema.md`](../../shared/data/schema.md).

**Prerequisite:** `claude/be-study-home` holds the spec (`0917e30`), its
approval (`1fbee66`) and its amendment, on `master` at `54cb7fe` (#50). This
plan runs on that branch, from the commit that adds it; the gate passes there
with 1276 tests. Generated code is not committed: in a fresh working tree, run
`flutter pub get`, `flutter gen-l10n` and
`dart run build_runner build --delete-conflicting-outputs` first (root
`README.md`, "Commands").

**How this plan was checked:** every code block below was written and run in a
scratch copy of the repository, task by task, test first. Each task's tests
failed as its "Expected" line says, then passed, and after every task the gate
passed. This document was then applied, step by step as written, onto a clean
checkout of `1fbee66`: each task's files matched the scratch commit's, no other
file moved, and the suite counts below are that run's. The "Expected" lines are
the ones those runs produced.

## Global Constraints

Every task's requirements implicitly include these.

- Backend only: nothing under `lib/features/*/presentation/`, `lib/shared/`,
  `lib/l10n/`, `lib/app/` or the theme. Screen 13, its controller and the use
  case's provider are FE-A8 (spec §1, §8, §11).
- The import map does not change: `study → {study_mode, srs, settings, card}`.
  The Study tab reads `deckLevelOfRoots` from `core/database/`, never through
  the `deck` feature (ADR-011).
- Read only: nothing on the Study tab's path writes, and it closes no session;
  closing a session of an earlier day stays with `abandonStaleSessions`
  (BR-STUDY-075, BR-STUDY-072; spec D8).
- One snapshot: the four reads run in one `transaction` (UC-STUDY-002 step 1;
  spec §6.2).
- The Resume conditions are one SQL fragment, `_resumable` in `StudyViewDao`,
  which the Study Entry's `resumableSessionId` uses too (spec D6).
- Each use case is a class `<Name>UseCase` in `<name>_use_case.dart` exposing
  `call` (AD-12).
- `now` and `startOfToday` come from the caller, and the use case from a
  `DayClock`; no test reads the wall clock.
- After every study scenario `expectStudyInvariants` runs every invariant query
  of `schema.md` in scope and checks that at most one session is `in_progress`.
- After every task the phased gate of the root `README.md` passes, plus
  `tools/docs/check.py`. On Linux, `flutter test` runs with
  `--exclude-tags golden`: the goldens were made on Windows (FE-D1 in
  [`docs/wbs_FE.md`](../../wbs_FE.md)).
- The guard warns at 400 logical lines of a file and fails at 500: keep each
  file under the warning. `study_view_dao.dart` ends at 265 non-blank,
  non-comment lines (the guard's own count decides).
- Docs and code change in the same commit (`docs/README.md`). A task whose tests
  name a use case id, or that changes a `code:` field, runs
  `python3 tools/docs/generate.py` and commits `docs/_generated/`.
- Of the contract files, only UC-STUDY-002's `code:` field changes (spec D9).
- Code, identifiers, test names and commit messages are in English; `docs/`
  keeps its Vietnamese. Every commit message ends with the session's attribution
  trailers.

## Clarifications to confirm during plan review

Writing and running the code settled what the spec left to the plan and showed
where it needed a change. Each is decided here, implemented as described, and
written into the spec on this branch; say so if one is wrong.

1. **D7 in practice** (Task 2; spec D7, §6.3, §11). The scratch copy swapped the
   stream for the card list's order (read, then listen) and wrote while the
   first read ran, once with a multi-statement write and once with a
   one-statement write, three runs each: no write was lost. The listener is in
   place before any write can commit and notify. The listen-first order stays,
   since it holds by construction rather than by timing, and its test ("a write
   made while the first read runs is not lost") passes with either order: it
   pins the outcome, not the order. Nothing opens for the card list.
2. **Two test files** (Task 2; spec §9). With the Review Focus tests the data
   tests reach 469 logical lines, over the guard's 400:
   `watch_study_home_test.dart` holds what the snapshot says (11 tests), and
   `watch_study_home_stream_test.dart` when it reads again and a failed read
   (5 tests).
3. **Fixtures the invariants accept** (Task 2). A tree with a learned card has
   its scheduler locked (invariant 30), so the tests lock it. A card in the
   Trash sits in a sub-deck of the same batch: invariant 29 skips a deck in the
   Trash, not an active sub-deck left with no card.
4. **The Study Entry's query** (Task 2; spec §6.1) takes its variables in a new
   order, the start of today then the deck, because the shared fragment reads
   `started_at` first. Its seven tests pass unchanged.
5. **The WBS scenario count** (Task 3). #49 removed the only test that named
   IT-ORG-013, so `master`'s tests name 61 IT ids, not the 62 its WBS says; with
   IT-NAV-002 this package's tests name 62: IT-CONT 12, IT-DISC 4, IT-LEARN 10,
   IT-MODE 12, IT-NAV 1, IT-ORG 3, IT-REVIEW 9, IT-STUDY 11.

## Review Focus

The inputs and conditions the spec implies that are most likely to bite a
person, each pinned by a test in the task that owns the code:

1. **A session whose cards left in its round were deleted**: it is still offered
   (its queue keeps rows), with no progress, until Continue settles it — Task 2,
   "a session whose cards left in its round were deleted".
2. **A newer open session from before a reset beside an older one that is
   valid**: the older one is offered, not nothing — Task 2, "of two open
   sessions, the newest that may be taken up".
3. **A write of many rows at once** (deleting several cards): the tab reads
   again once, not once per row — Task 2, "a write of several rows in one
   transaction".
4. **A library whose every card is in the Trash**: the no-card state, with no
   numbers — Task 2, "a library whose every card is in the Trash".
5. **A deck renamed while the tab is open**: the list takes the new name and
   its new place — Task 2, "a deck renamed while the tab is open".

## File Structure

```
lib/features/study/
├── domain/
│   ├── models/study_home_model.dart                StudyHome, ResumableSession,
│   │                                               StudyHomeContent (NoRootDecks, NoCards,
│   │                                               RootDeckWorkload), StudyHomeDeck,
│   │                                               studyHomeContentOf, compareStudyHomeDecks (1)
│   ├── repositories/study_home_repository.dart     watchHome (2)
│   └── usecases/watch_study_home_use_case.dart     WatchStudyHomeUseCase (3)
├── data/
│   ├── datasources/study_view_dao.dart             the Resume fragment, resumableSessionRow,
│   │                                               rootDeckRows, nextDueAt, homeChanges (2)
│   ├── mappers/study_home_mapper.dart              studyHomeOf (2)
│   └── repositories/study_home_repository_impl.dart   one snapshot, one transaction (2)
└── di/study_home_repository_provider.dart          studyHomeRepositoryProvider (2)

test/features/study/domain/study_home_test.dart                 (1)
test/features/study/data/watch_study_home_test.dart             (2)
test/features/study/data/watch_study_home_stream_test.dart      (2)
test/features/study/domain/watch_study_home_use_case_test.dart  (3)
```

Other changed files: `features/study/data.md`, UC-STUDY-002 and `wbs_BE.md`
(Task 3), and `docs/_generated/` (every task).

---


### Task 1: The Study tab's read model: its states, its order and its hero

**Files:**
- Create: `lib/features/study/domain/models/study_home_model.dart`
- Test (create): `test/features/study/domain/study_home_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `foldText` (`lib/core/text/folded_text.dart`); `SchedulerType`
  (`srs/domain/models/scheduler_type_model.dart`); `SessionKind`, `StudyMode`
  (`study_mode/domain/models/`); `RoundProgress`
  (`study/domain/models/study_session_view_model.dart`).
- Produces, in `lib/features/study/domain/models/study_home_model.dart`:
  - `StudyHome({required ResumableSession? resumable, required StudyHomeContent content})`.
  - `ResumableSession({required String sessionId, required String deckName, required SessionKind kind, required StudyMode mode, required RoundProgress? progress})`.
  - `sealed class StudyHomeContent`, with `NoRootDecks()`, `NoCards()` and
    `RootDeckWorkload({required List<StudyHomeDeck> decks, required DateTime? nextDueAt})`,
    whose getters are `overdueCount`, `dueTodayCount`, `newCount`, `dueCount`,
    `workloadDeckCount` and `isCaughtUp`.
  - `StudyHomeDeck({required String deckId, required String name, required SchedulerType schedulerType, required int cardCount, required int overdueCount, required int dueTodayCount, required int newCount})`,
    with `hasWorkload` and `canStudy`.
  - `StudyHomeContent studyHomeContentOf(List<StudyHomeDeck> decks, {required DateTime? nextDueAt})`
    and `int compareStudyHomeDecks(StudyHomeDeck a, StudyHomeDeck b)`.

Spec §5. Pure Dart: the three loaded states, the order of BR-STUDY-076
and the hero's totals are decided here, so the UI shows what the domain says.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/domain/study_home_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';

// UC-STUDY-002 steps 1–3: the loaded states, the order and the hero of the
// Study tab (Study Home spec §5).

StudyHomeDeck deck(
  String id, {
  String? name,
  int cards = 10,
  int overdue = 0,
  int dueToday = 0,
  int fresh = 0,
}) => StudyHomeDeck(
  deckId: id,
  name: name ?? id,
  schedulerType: SchedulerType.eightBox,
  cardCount: cards,
  overdueCount: overdue,
  dueTodayCount: dueToday,
  newCount: fresh,
);

List<String> idsOf(StudyHomeContent content) => [
  for (final deck in (content as RootDeckWorkload).decks) deck.deckId,
];

void main() {
  test('orders the decks by Overdue, then Due today, then New, never by the '
      'total (BR-STUDY-076)', () {
    final content = studyHomeContentOf([
      deck('big-today', dueToday: 100, fresh: 500),
      deck('new-only', fresh: 3),
      deck('one-overdue', overdue: 1),
      deck('today', dueToday: 5),
      deck('today-and-new', dueToday: 5, fresh: 1),
    ], nextDueAt: null);

    expect(idsOf(content), [
      'one-overdue',
      'big-today',
      'today-and-new',
      'today',
      'new-only',
    ]);
  });

  test('breaks a tie by the Unicode-folded name, then by id '
      '(BR-STUDY-076, BR-TAG-001)', () {
    final content = studyHomeContentOf([
      deck('z', name: 'Zebra'),
      deck('e1', name: 'Émile'),
      deck('k2', name: 'korean'),
      deck('a', name: 'apple'),
      deck('e2', name: 'élan'),
      deck('k1', name: 'Korean'),
    ], nextDueAt: null);

    expect(idsOf(content), ['a', 'k1', 'k2', 'z', 'e2', 'e1']);
  });

  test('no root deck, roots without a card, and cards with no workload are '
      'the three loaded states (BR-STUDY-077, BR-STUDY-008)', () {
    final nextDue = DateTime(2026, 9, 26);

    expect(studyHomeContentOf([], nextDueAt: null), isA<NoRootDecks>());
    expect(
      studyHomeContentOf([
        deck('a', cards: 0),
        deck('b', cards: 0),
      ], nextDueAt: null),
      isA<NoCards>(),
    );
    expect(
      studyHomeContentOf([deck('a'), deck('b', cards: 0)], nextDueAt: nextDue),
      isA<RootDeckWorkload>()
          .having((content) => content.decks, 'decks', hasLength(2))
          .having((content) => content.isCaughtUp, 'caught up', isTrue)
          .having((content) => content.nextDueAt, 'next due', nextDue),
    );
  });

  test('a deck without a card stays in the list, after the decks with work, '
      'and cannot be studied (BR-STUDY-076)', () {
    final content = studyHomeContentOf([
      deck('empty', name: 'A empty', cards: 0),
      deck('rested', name: 'B rested'),
      deck('busy', name: 'C busy', fresh: 2),
    ], nextDueAt: null) as RootDeckWorkload;

    expect(idsOf(content), ['busy', 'empty', 'rested']);
    expect(
      [for (final deck in content.decks) deck.canStudy],
      [true, false, true],
    );
  });

  test('the hero adds up the list: the due and the new cards, and the decks '
      'with work (UC-STUDY-002 step 3, BR-STUDY-068)', () {
    final content = studyHomeContentOf([
      deck('a', overdue: 3, dueToday: 2, fresh: 1),
      deck('b', dueToday: 4),
      deck('c', fresh: 5),
      deck('d'),
    ], nextDueAt: null) as RootDeckWorkload;

    expect(
      (
        content.overdueCount,
        content.dueTodayCount,
        content.newCount,
        content.dueCount,
        content.workloadDeckCount,
        content.isCaughtUp,
      ),
      (3, 6, 6, 9, 3, false),
    );
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/domain/study_home_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the read model does not exist yet. The first errors: `Error: Method not found: 'studyHomeContentOf'.`, `Error: 'RootDeckWorkload' isn't a type.`, `Error: Error when reading 'lib/features/study/domain/models/study_home_model.dart': No such file or directory`

- [ ] **Step 3: Write the read model**

Create `lib/features/study/domain/models/study_home_model.dart`:

```dart
import 'package:memox/core/text/folded_text.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The Study tab (UC-STUDY-002; Study Home spec §5): the session Resume takes
/// up, and the library's root decks with their workload, read as one
/// snapshot.
final class StudyHome {
  const StudyHome({required this.resumable, required this.content});

  /// The session the Resume card offers (BR-STUDY-075); null when no open
  /// session may be taken up (A1, A2).
  final ResumableSession? resumable;

  final StudyHomeContent content;
}

/// The open session the Resume card offers (BR-STUDY-075).
final class ResumableSession {
  const ResumableSession({
    required this.sessionId,
    required this.deckName,
    required this.kind,
    required this.mode,
    required this.progress,
  });

  final String sessionId;

  /// The deck the session was opened on: a sub-deck or a root.
  final String deckName;

  /// Both read from the session row, never inferred (BR-SRS-015,
  /// BR-MODE-008).
  final SessionKind kind;
  final StudyMode mode;

  /// The round the session serves, counted as the session screen counts it
  /// (spec D3); null while it serves nothing.
  final RoundProgress? progress;
}

/// The three loaded states of the Study tab (BR-STUDY-077).
sealed class StudyHomeContent {
  const StudyHomeContent();
}

/// No root deck: the way forward is the Starter Library.
final class NoRootDecks extends StudyHomeContent {
  const NoRootDecks();
}

/// Root decks, none with a card: the way forward is Library, and no number
/// is shown.
final class NoCards extends StudyHomeContent {
  const NoCards();
}

/// Every root deck with its workload, in the order of BR-STUDY-076, even when
/// no deck has any: the schedule is running (BR-STUDY-008).
final class RootDeckWorkload extends StudyHomeContent {
  const RootDeckWorkload({required this.decks, required this.nextDueAt});

  final List<StudyHomeDeck> decks;

  /// The earliest due date after now of a learned card, the day the caught-up
  /// state names (spec D4); null when no learned card waits.
  final DateTime? nextDueAt;

  int get overdueCount => _sum((deck) => deck.overdueCount);

  int get dueTodayCount => _sum((deck) => deck.dueTodayCount);

  int get newCount => _sum((deck) => deck.newCount);

  /// Overdue and Due today together (BR-STUDY-068).
  int get dueCount => overdueCount + dueTodayCount;

  /// The decks with any workload: "across K decks".
  int get workloadDeckCount => decks.where((deck) => deck.hasWorkload).length;

  /// No deck has any workload (A3, BR-STUDY-008).
  bool get isCaughtUp => workloadDeckCount == 0;

  int _sum(int Function(StudyHomeDeck deck) count) =>
      decks.fold(0, (total, deck) => total + count(deck));
}

/// A root deck of the Study tab with the workload of its whole tree
/// (BR-STUDY-076).
final class StudyHomeDeck {
  const StudyHomeDeck({
    required this.deckId,
    required this.name,
    required this.schedulerType,
    required this.cardCount,
    required this.overdueCount,
    required this.dueTodayCount,
    required this.newCount,
  });

  final String deckId;
  final String name;
  final SchedulerType schedulerType;
  final int cardCount;
  final int overdueCount;
  final int dueTodayCount;
  final int newCount;

  bool get hasWorkload => overdueCount + dueTodayCount + newCount > 0;

  /// A deck with no card gets no open action (BR-STUDY-076).
  bool get canStudy => cardCount > 0;
}

/// The loaded state [decks] make (BR-STUDY-077), with the decks in the order
/// of BR-STUDY-076.
StudyHomeContent studyHomeContentOf(
  List<StudyHomeDeck> decks, {
  required DateTime? nextDueAt,
}) {
  if (decks.isEmpty) return const NoRootDecks();
  if (!decks.any((deck) => deck.canStudy)) return const NoCards();
  return RootDeckWorkload(
    decks: [...decks]..sort(compareStudyHomeDecks),
    nextDueAt: nextDueAt,
  );
}

/// BR-STUDY-076: Overdue, then Due today, then New, each descending and never
/// their total; then the Unicode-folded name (`foldText`, as tags sort,
/// BR-TAG-001), then the id.
int compareStudyHomeDecks(StudyHomeDeck a, StudyHomeDeck b) {
  final overdue = b.overdueCount.compareTo(a.overdueCount);
  if (overdue != 0) return overdue;
  final dueToday = b.dueTodayCount.compareTo(a.dueTodayCount);
  if (dueToday != 0) return dueToday;
  final fresh = b.newCount.compareTo(a.newCount);
  if (fresh != 0) return fresh;
  final name = foldText(a.name).compareTo(foldText(b.name));
  if (name != 0) return name;
  return a.deckId.compareTo(b.deckId);
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
flutter test test/features/study/domain/study_home_test.dart
```

Expected: `+5: All tests passed!`

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

Expected: `No issues found!`; `+1281: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 7: Commit**

```bash
git add docs/_generated \
  lib/features/study/domain/models/study_home_model.dart \
  test/features/study/domain/study_home_test.dart
git commit -F - <<'EOF'
feat(study): the Study tab's read model: its three states, its order and its hero

StudyHome holds the session Resume takes up and the root decks with their
workload (UC-STUDY-002; Study Home spec §5). studyHomeContentOf tells the
three loaded states apart (BR-STUDY-077), compareStudyHomeDecks orders the
decks by Overdue, Due today and New, then by the folded name and the id
(BR-STUDY-076), and the hero's totals add up the list.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 2: The Study tab reads one snapshot

**Files:**
- Create: `lib/features/study/data/mappers/study_home_mapper.dart`, `lib/features/study/data/repositories/study_home_repository_impl.dart`, `lib/features/study/di/study_home_repository_provider.dart`, `lib/features/study/domain/repositories/study_home_repository.dart`
- Modify: `lib/features/study/data/datasources/study_view_dao.dart`
- Test (create): `test/features/study/data/watch_study_home_stream_test.dart`, `test/features/study/data/watch_study_home_test.dart`
- Regenerate: the `*.g.dart` files (build_runner, not committed), `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: Task 1's types and `studyHomeContentOf`; `deckLevelOfRoots`
  (`lib/core/database/queries/deck_queries.drift`, row `DeckTileRow`);
  `StudyQueueDao.headRow` and `StudyViewDao.roundCounts` (package 2a);
  `mapDatabaseErrors` (`lib/core/error/failure.dart`); `databaseProvider`.
- Produces:
  - In `StudyViewDao`: `typedef ResumableRow = ({StudySession session, String deckName})`;
    `Future<ResumableRow?> resumableSessionRow({required DateTime startOfToday})`;
    `Future<List<DeckTileRow>> rootDeckRows({required DateTime now, required DateTime startOfToday})`;
    `Future<DateTime?> nextDueAt({required DateTime now})`;
    `Stream<void> homeChanges()`. `resumableSessionId` keeps its signature.
  - `StudyHome studyHomeOf({required List<DeckTileRow> roots, required ResumableRow? resumable, required RoundCounts? round, required DateTime? nextDueAt})`
    (`study/data/mappers/study_home_mapper.dart`).
  - `abstract interface class StudyHomeRepository` with
    `Stream<StudyHome> watchHome({required DateTime now, required DateTime startOfToday})`.
  - `StudyHomeRepositoryImpl(AppDatabase db)`.
  - `studyHomeRepositoryProvider` (`study/di/study_home_repository_provider.dart`).

Spec §6, D3–D8; Clarifications 1–4. The two test files come first;
the data access object then gets the snapshot's reads and its change stream, the
mapper and the repository read them in one transaction, and the provider makes
the repository available to FE-A8.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/data/watch_study_home_stream_test.dart`:

```dart
import 'dart:async';

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
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-002 step 5 and E1: when the Study tab reads again, and a read
// that fails (Study Home spec §6.3, §6.5).

/// Completes [started] when the Study tab's snapshot reads the sessions, so a
/// test can write while that read runs.
final class _SessionReadSignal extends QueryInterceptor {
  final started = Completer<void>();

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (!started.isCompleted && statement.contains('FROM study_session s')) {
      started.complete();
    }
    return super.runSelect(executor, statement, args);
  }
}

/// Fails every SELECT while [isArmed], the way a disk that cannot be read
/// does (UC-STUDY-002 E1).
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
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudyHomeRepositoryImpl home;
  final now = DateTime(2026, 9, 25, 9);
  final today = DateTime(2026, 9, 25);

  void open([QueryInterceptor? interceptor]) {
    db = openTestDatabase(interceptor: interceptor);
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    home = StudyHomeRepositoryImpl(db);
  }

  setUp(() => open());
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  String opened(Outcome<String, StudyRejection> outcome) =>
      (outcome as Ok<String, StudyRejection>).value;

  CardRepositoryImpl cardRepository() => CardRepositoryImpl(
    db,
    ScheduleRepositoryImpl(db, now: () => now),
    TagRepositoryImpl(db, now: () => now),
    now: () => now,
  );

  List<String> namesOf(StudyHome snapshot) => [
    for (final deck in (snapshot.content as RootDeckWorkload).decks) deck.name,
  ];

  /// A learned card of [deckId] due at [dueAt], of its own meaning.
  Future<void> learned(String deckId, String id, DateTime dueAt) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  test('the snapshot comes again when a turn is answered and when the '
      'session is left (UC-STUDY-002 step 5)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await learned(lesson.id, 'a', DateTime(2026, 9, 24));
    await learned(lesson.id, 'b', DateTime(2026, 9, 24));
    await lockScheduler(db, root.id);
    final id = opened(
      await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.recall,
      ),
    );
    final homes = <StudyHome>[];
    final subscription = home
        .watchHome(now: now, startOfToday: today)
        .listen(homes.add);
    await pumpEventQueue();
    expect(homes.last.resumable?.progress?.completed, 0);

    await answerServed(db, sessions, id, right: true);
    await pumpEventQueue();
    expect(homes.last.resumable?.progress?.completed, 1);
    expect((homes.last.content as RootDeckWorkload).overdueCount, 1);

    await sessions.abandonSession(sessionId: id);
    await pumpEventQueue();
    expect(homes.last.resumable, isNull);
    await subscription.cancel();
  });

  test(
    'a write made while the first read runs is not lost (spec D7)',
    () async {
      await db.close();
      final signal = _SessionReadSignal();
      open(signal);
      final root = await decks.root('Korean');
      final lesson = await decks.sub(root.id, 'Lesson');
      await insertCard(db, id: 'c1', deckId: lesson.id, back: 'one');
      final id = opened(await entries.openLearningSession(deckId: lesson.id));
      final homes = <StudyHome>[];

      final subscription = home
          .watchHome(now: now, startOfToday: today)
          .listen(homes.add);
      await signal.started.future;
      await sessions.abandonSession(sessionId: id);
      await pumpEventQueue();

      expect(homes.first.resumable?.sessionId, id);
      expect(homes.last.resumable, isNull);
      await subscription.cancel();
    },
  );

  test('a write of several rows in one transaction reads the tab again once '
      '(spec D7)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    for (final id in ['c1', 'c2', 'c3']) {
      await insertCard(db, id: id, deckId: lesson.id, back: id);
    }
    final homes = <StudyHome>[];
    final subscription = home
        .watchHome(now: now, startOfToday: today)
        .listen(homes.add);
    await pumpEventQueue();
    final before = homes.length;

    expect(
      await cardRepository().deleteCards(cardIds: {'c1', 'c2'}),
      isA<Ok<void, CardRejection>>(),
    );
    await pumpEventQueue();

    expect(homes.length, before + 1);
    expect((homes.last.content as RootDeckWorkload).newCount, 1);
    await subscription.cancel();
  });

  test('a deck renamed while the tab is open takes its new place in the list '
      '(BR-STUDY-076)', () async {
    final alpha = await decks.root('Alpha');
    final beta = await decks.root('Beta');
    final a = await decks.sub(alpha.id, 'A');
    final b = await decks.sub(beta.id, 'B');
    await insertCard(db, id: 'a1', deckId: a.id, back: 'one');
    await insertCard(db, id: 'b1', deckId: b.id, back: 'two');
    final homes = <StudyHome>[];
    final subscription = home
        .watchHome(now: now, startOfToday: today)
        .listen(homes.add);
    await pumpEventQueue();
    expect(namesOf(homes.last), ['Alpha', 'Beta']);

    expect(
      await decks.renameDeck(deckId: alpha.id, name: 'Zulu'),
      isA<Ok<void, DeckRejection>>(),
    );
    await pumpEventQueue();

    expect(namesOf(homes.last), ['Beta', 'Zulu']);
    await subscription.cancel();
  });

  test(
    'a read that fails comes as a database Failure (UC-STUDY-002 E1)',
    () async {
      await db.close();
      final failing = _FailingSelects();
      open(failing);
      await decks.root('Korean');
      failing.isArmed = true;

      await expectLater(
        home.watchHome(now: now, startOfToday: today),
        emitsError(isA<Failure>()),
      );
      failing.isArmed = false;
    },
  );
}
```

Create `test/features/study/data/watch_study_home_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/card/data/repositories/card_repository_impl.dart';
import 'package:memox/features/card/domain/failures/card_failure.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/srs/data/repositories/schedule_repository_impl.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/study/data/repositories/study_entry_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_session_view_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';
import 'package:memox/features/tags/data/repositories/tag_repository_impl.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-002 steps 1–3: what the Study tab's snapshot holds (Study Home
// spec §5, §6.1).

void main() {
  late AppDatabase db;
  late DeckRepositoryImpl decks;
  late StudyEntryRepositoryImpl entries;
  late StudySessionRepositoryImpl sessions;
  late StudyHomeRepositoryImpl home;
  final now = DateTime(2026, 9, 25, 9);
  setUp(() {
    db = openTestDatabase();
    decks = DeckRepositoryImpl(db, now: () => now);
    entries = studyEntryRepository(db, () => now);
    sessions = studySessionRepository(db, () => now);
    home = StudyHomeRepositoryImpl(db);
  });
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  Future<StudyHome> homeAt([DateTime? at]) {
    final time = at ?? now;
    return home.watchHome(now: time, startOfToday: startOfLocalDay(time)).first;
  }

  Future<RootDeckWorkload> workload() async =>
      (await homeAt()).content as RootDeckWorkload;

  String opened(Outcome<String, StudyRejection> outcome) =>
      (outcome as Ok<String, StudyRejection>).value;

  CardRepositoryImpl cardRepository() => CardRepositoryImpl(
    db,
    ScheduleRepositoryImpl(db, now: () => now),
    TagRepositoryImpl(db, now: () => now),
    now: () => now,
  );

  /// A learned card of [deckId] due at [dueAt], of its own meaning.
  Future<void> learned(String deckId, String id, DateTime dueAt) => insertCard(
    db,
    id: id,
    deckId: deckId,
    back: 'meaning $id',
    learnedAt: DateTime(2026, 9, 1),
    dueAt: dueAt,
    box: 2,
  );

  test("the Resume card names the session's deck, its kind and its mode, "
      'from the session row; a session opened on a sub-deck names the '
      'sub-deck (BR-STUDY-075, BR-SRS-015, BR-MODE-008)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson A');
    await insertCard(db, id: 'n1', deckId: lesson.id, back: 'one');
    await insertCard(db, id: 'n2', deckId: lesson.id, back: 'two');
    final learning = opened(
      await entries.openLearningSession(deckId: lesson.id),
    );
    final stage = StudyMode.fromCode(
      (await sessionOf(db, learning)).read<String>('current_mode'),
    );

    expect(
      (await homeAt()).resumable,
      isA<ResumableSession>()
          .having((session) => session.sessionId, 'id', learning)
          .having((session) => session.deckName, 'deck', 'Lesson A')
          .having((session) => session.kind, 'kind', SessionKind.learning)
          .having((session) => session.mode, 'mode', stage),
    );

    await learned(lesson.id, 'd1', DateTime(2026, 9, 20));
    await lockScheduler(db, root.id);
    final review = opened(
      await entries.openReviewSession(deckId: root.id, mode: StudyMode.recall),
    );

    expect(
      (await homeAt()).resumable,
      isA<ResumableSession>()
          .having((session) => session.sessionId, 'id', review)
          .having((session) => session.deckName, 'deck', 'Korean')
          .having((session) => session.kind, 'kind', SessionKind.reviewing)
          .having((session) => session.mode, 'mode', StudyMode.recall),
    );
  });

  test('its progress is the one the session screen shows for the same '
      'session (spec D3)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    for (final id in ['a', 'b', 'c']) {
      await learned(lesson.id, id, DateTime(2026, 9, 20));
    }
    await lockScheduler(db, root.id);
    final id = opened(
      await entries.openReviewSession(
        deckId: lesson.id,
        mode: StudyMode.recall,
      ),
    );
    await answerServed(db, sessions, id, right: true);

    final progress = (await homeAt()).resumable!.progress!;
    final screen = (await StudySessionViewRepositoryImpl(
      db,
    ).watchSession(id).first)!.progress!;

    expect((progress.completed, progress.total), (1, 3));
    expect((screen.completed, screen.total), (1, 3));
  });

  test('no Resume card without an open session, nor for one that has ended, '
      'started before today, has no queue row left or belongs to an old '
      'generation (BR-STUDY-075; UC-STUDY-002 A1, A2)', () async {
    final root = await decks.root('Korean');
    final lessons = [
      for (final name in ['A', 'B', 'C']) await decks.sub(root.id, name),
    ];
    for (final (index, lesson) in lessons.indexed) {
      await insertCard(db, id: 'c$index', deckId: lesson.id, back: 'm$index');
    }
    expect((await homeAt()).resumable, isNull, reason: 'no open session');

    final first = opened(
      await entries.openLearningSession(deckId: lessons[0].id),
    );
    expect((await homeAt()).resumable?.sessionId, first);
    expect(
      (await homeAt(DateTime(2026, 9, 26, 8))).resumable,
      isNull,
      reason: 'a session of an earlier day',
    );
    await sessions.abandonSession(sessionId: first);
    expect((await homeAt()).resumable, isNull, reason: 'an ended session');

    await entries.openLearningSession(deckId: lessons[1].id);
    expect(
      await cardRepository().deleteCards(cardIds: {'c1'}),
      isA<Ok<void, CardRejection>>(),
    );
    expect((await homeAt()).resumable, isNull, reason: 'no queue row left');

    final third = opened(
      await entries.openLearningSession(deckId: lessons[2].id),
    );
    expect((await homeAt()).resumable?.sessionId, third);
    await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
      root.id,
    ]);
    await db.customStatement('UPDATE card_schedule SET generation = 2');
    expect(
      (await homeAt()).resumable,
      isNull,
      reason: 'a session from before a reset',
    );
  });

  test('of two open sessions, the newest; of two started at once, the '
      'higher id (BR-STUDY-075, spec D6)', () async {
    final root = await decks.root('Korean');
    final a = await decks.sub(root.id, 'A');
    final b = await decks.sub(root.id, 'B');
    await insertCard(db, id: 'a1', deckId: a.id, back: 'one');
    await insertCard(db, id: 'b1', deckId: b.id, back: 'two');
    final older = opened(
      await studyEntryRepository(
        db,
        () => DateTime(2026, 9, 25, 8),
      ).openLearningSession(deckId: a.id),
    );
    final newer = opened(await entries.openLearningSession(deckId: b.id));
    // Opening the second closed the first (package 2a D2): open it again.
    await db.customStatement(
      "UPDATE study_session SET status = 'in_progress', end_reason = NULL, "
      'ended_at = NULL WHERE id = ?',
      [older],
    );

    expect((await homeAt()).resumable?.sessionId, newer);

    await db.customStatement(
      'UPDATE study_session SET started_at = '
      '(SELECT started_at FROM study_session WHERE id = ?) WHERE id = ?',
      [newer, older],
    );
    expect(
      (await homeAt()).resumable?.sessionId,
      older.compareTo(newer) > 0 ? older : newer,
    );

    // One open session again, as package 2a keeps it (D2).
    await sessions.abandonSession(sessionId: older);
  });

  test(
    'of two open sessions, the newest that may be taken up: a newer one '
    'from before a reset leaves the older one offered (BR-STUDY-075)',
    () async {
      final korean = await decks.root('Korean');
      final english = await decks.root('English');
      final a = await decks.sub(korean.id, 'A');
      final b = await decks.sub(english.id, 'B');
      await insertCard(db, id: 'a1', deckId: a.id, back: 'one');
      await insertCard(db, id: 'b1', deckId: b.id, back: 'two');
      final older = opened(
        await studyEntryRepository(
          db,
          () => DateTime(2026, 9, 25, 8),
        ).openLearningSession(deckId: a.id),
      );
      await entries.openLearningSession(deckId: b.id);
      await db.customStatement(
        "UPDATE study_session SET status = 'in_progress', end_reason = NULL, "
        'ended_at = NULL WHERE id = ?',
        [older],
      );
      await db.customStatement('UPDATE deck SET generation = 2 WHERE id = ?', [
        english.id,
      ]);
      await db.customStatement(
        "UPDATE card_schedule SET generation = 2 WHERE card_id = 'b1'",
      );

      expect((await homeAt()).resumable?.sessionId, older);

      // One open session again, as package 2a keeps it (D2).
      await sessions.abandonSession(sessionId: older);
    },
  );

  test('a session whose cards left in its round were deleted is still '
      'offered, with no progress until Continue settles it (BR-STUDY-075, '
      'spec D3)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id, back: 'one');
    await insertCard(db, id: 'c2', deckId: lesson.id, back: 'two');
    final id = opened(await entries.openLearningSession(deckId: lesson.id));
    final first = (await servedCard(db, id))!;
    await answerServed(db, sessions, id, right: true);
    expect(
      await cardRepository().deleteCards(
        cardIds: {first == 'c1' ? 'c2' : 'c1'},
      ),
      isA<Ok<void, CardRejection>>(),
    );

    final resumable = (await homeAt()).resumable;

    expect(resumable?.sessionId, id);
    expect(resumable?.progress, isNull);
  });

  test("a root deck's counts are its whole tree's: Overdue, Due today, New "
      'and its cards (BR-STUDY-076, BR-STUDY-068)', () async {
    final korean = await decks.root('Korean');
    final lesson = await decks.sub(korean.id, 'Lesson');
    final unit = await decks.sub(lesson.id, 'Unit');
    final other = await decks.sub(korean.id, 'Other');
    final english = await decks.root('English');
    final words = await decks.sub(english.id, 'Words');
    await learned(unit.id, 'overdue', DateTime(2026, 9, 24));
    await learned(unit.id, 'today', DateTime(2026, 9, 25));
    await learned(other.id, 'later', DateTime(2026, 9, 28));
    await insertCard(db, id: 'new', deckId: other.id, back: 'new');
    await insertCard(db, id: 'english', deckId: words.id, back: 'word');
    await lockScheduler(db, korean.id);

    expect(
      [
        for (final deck in (await workload()).decks)
          (
            deck.name,
            deck.cardCount,
            deck.overdueCount,
            deck.dueTodayCount,
            deck.newCount,
          ),
      ],
      [('Korean', 4, 1, 1, 1), ('English', 1, 0, 0, 1)],
    );
  });

  test('a session whose deck is in the Trash is not offered, and a card in '
      'the Trash counts toward nothing (BR-STUDY-075, BR-STUDY-076)', () async {
    final root = await decks.root('Korean');
    final kept = await decks.sub(root.id, 'Kept');
    final trashed = await decks.sub(root.id, 'Trashed');
    await learned(kept.id, 'due', DateTime(2026, 9, 24));
    await insertCard(
      db,
      id: 'gone',
      deckId: kept.id,
      back: 'gone',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 24),
      box: 2,
      deleteBatchId: 'batch',
    );
    await insertCard(db, id: 'new', deckId: trashed.id, back: 'new');
    await lockScheduler(db, root.id);
    await entries.openLearningSession(deckId: trashed.id);
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', trashed.id],
    );

    final snapshot = await homeAt();
    final deck = (snapshot.content as RootDeckWorkload).decks.single;

    expect(snapshot.resumable, isNull);
    expect((deck.cardCount, deck.overdueCount, deck.newCount), (1, 1, 0));
  });

  test('a library whose every card is in the Trash has no numbers to show '
      '(BR-STUDY-077)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'gone',
      deckId: lesson.id,
      back: 'gone',
      deleteBatchId: 'batch',
    );
    await db.customStatement(
      'UPDATE deck SET delete_batch_id = ? WHERE id = ?',
      ['batch', lesson.id],
    );

    expect((await homeAt()).content, isA<NoCards>());
  });

  test('nextDueAt is the earliest due date after now of a learned card, and '
      'null while none waits (spec D4)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'new', deckId: lesson.id, back: 'new');
    expect((await workload()).nextDueAt, isNull);

    await learned(lesson.id, 'today', DateTime(2026, 9, 25));
    await learned(lesson.id, 'later', DateTime(2026, 9, 30));
    await learned(lesson.id, 'next', DateTime(2026, 9, 27));
    await lockScheduler(db, root.id);

    expect((await workload()).nextDueAt, DateTime(2026, 9, 27));
  });

  test("reading writes nothing, even with yesterday's session open, which "
      'stays open (BR-STUDY-075, BR-STUDY-020; the backend half of IT-NAV-002 '
      'step 1)', () async {
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(db, id: 'c1', deckId: lesson.id, back: 'one');
    final id = opened(
      await studyEntryRepository(
        db,
        () => DateTime(2026, 9, 24, 20),
      ).openLearningSession(deckId: lesson.id),
    );
    final before = await totalChanges(db);

    final snapshot = await homeAt();

    expect(snapshot.resumable, isNull);
    expect(await totalChanges(db), before);
    expect((await sessionOf(db, id)).read<String>('status'), 'in_progress');
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/data/watch_study_home_stream_test.dart \
  test/features/study/data/watch_study_home_test.dart
```

Expected: `+0 -2: Some tests failed.` Neither test file compiles: the repository does not exist yet. The first errors: `Error: Error when reading 'lib/features/study/data/repositories/study_home_repository_impl.dart': No such file or directory`, `Error: 'StudyHomeRepositoryImpl' isn't a type.`, `Error: Method not found: 'StudyHomeRepositoryImpl'.`

- [ ] **Step 3: Add the snapshot's reads and its change stream to StudyViewDao**

In `lib/features/study/data/datasources/study_view_dao.dart`:

Replace

```dart
typedef RoundCounts = ({int completed, int total});

```

with

```dart
typedef RoundCounts = ({int completed, int total});

/// The session the Study tab's Resume card offers, with the name of the deck
/// it was opened on.
typedef ResumableRow = ({StudySession session, String deckName});

```

Replace

```dart
  int? meaningSlot,
});

/// The reads of the study screens (spec §8). They write nothing
```

with

```dart
  int? meaningSlot,
});

/// The sessions Continue and Resume may take up (BR-STUDY-075), over
/// `study_session s`, its deck `d` and its root `r`: open, started on or after
/// the one variable, the start of today, at the root's generation, out of the
/// Trash and with a queue row left (Study Home spec D6).
const _resumable =
    ' FROM study_session s JOIN deck d ON d.id = s.deck_id'
    ' JOIN deck r ON r.id = s.root_id'
    " WHERE s.status = 'in_progress' AND s.started_at >= ?"
    ' AND s.generation = r.generation'
    ' AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL'
    ' AND EXISTS (SELECT 1 FROM study_queue_items q WHERE q.session_id = s.id)';

/// The newest of them; of two started at once, the higher id.
const _newestFirst = ' ORDER BY s.started_at DESC, s.id DESC LIMIT 1';

/// The reads of the study screens (spec §8). They write nothing
```

Replace

```dart
  /// The newest open session of [deckId] that Continue can take up
  /// (BR-STUDY-075): started on or after [startOfToday], at its root's
  /// generation, with at least one queue row.
  Future<String?> resumableSessionId(
```

with

```dart
  /// The newest open session of [deckId] that Continue can take up
  /// (BR-STUDY-075), by the conditions the Study tab's Resume card uses.
  Future<String?> resumableSessionId(
```

Replace

```dart
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
```

with

```dart
        .customSelect(
          'SELECT s.id$_resumable AND s.deck_id = ?$_newestFirst',
          variables: [
            Variable<DateTime>(startOfToday),
            Variable<String>(deckId),
          ],
```

Replace

```dart
    return row?.read<String>('id');
  }

  Future<CardRow?> cardRow(String cardId) => (_db.select(
```

with

```dart
    return row?.read<String>('id');
  }

  /// The session the Study tab's Resume card offers, of any deck
  /// (BR-STUDY-075); null when none may be taken up.
  Future<ResumableRow?> resumableSessionRow({
    required DateTime startOfToday,
  }) async {
    final row = await _db
        .customSelect(
          'SELECT s.*, d.name AS deck_name$_resumable$_newestFirst',
          variables: [Variable<DateTime>(startOfToday)],
          readsFrom: {_db.studySession, _db.deck, _db.studyQueueItems},
        )
        .getSingleOrNull();
    if (row == null) return null;
    return (
      session: _db.studySession.map(row.data),
      deckName: row.read<String>('deck_name'),
    );
  }

  /// Every root deck with the workload of its whole tree: the statement the
  /// Library's root level reads (BR-STUDY-076, BR-STUDY-068).
  Future<List<DeckTileRow>> rootDeckRows({
    required DateTime now,
    required DateTime startOfToday,
  }) => _db.deckLevelOfRoots(startOfToday, now).get();

  /// The earliest due date after [now] of a learned card out of the Trash
  /// (Study Home spec D4); null when none waits.
  Future<DateTime?> nextDueAt({required DateTime now}) async {
    final row = await _db
        .customSelect(
          'SELECT MIN(cs.due_at) AS next_due_at FROM card c'
          ' JOIN deck k ON k.id = c.deck_id'
          ' JOIN card_schedule cs ON cs.card_id = c.id'
          ' WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL'
          ' AND cs.learned_at IS NOT NULL AND cs.due_at > ?',
          variables: [Variable<DateTime>(now)],
          readsFrom: {_db.card, _db.deck, _db.cardSchedule},
        )
        .getSingle();
    return row.read<DateTime?>('next_due_at');
  }

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

  Future<CardRow?> cardRow(String cardId) => (_db.select(
```

- [ ] **Step 4: Declare the repository, and map the rows to the read model**

Create `lib/features/study/data/mappers/study_home_mapper.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/features/srs/domain/models/scheduler_type_model.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/models/study_session_view_model.dart';
import 'package:memox/features/study_mode/domain/models/session_kind_model.dart';
import 'package:memox/features/study_mode/domain/models/study_mode.dart';

/// The Study tab from the rows of its snapshot (Study Home spec §6.4): the
/// root decks, the resumable session and the counts of its round, and the
/// next due date.
StudyHome studyHomeOf({
  required List<DeckTileRow> roots,
  required ResumableRow? resumable,
  required RoundCounts? round,
  required DateTime? nextDueAt,
}) => StudyHome(
  resumable: resumable == null ? null : _resumableOf(resumable, round),
  content: studyHomeContentOf([
    for (final row in roots) _deckOf(row),
  ], nextDueAt: nextDueAt),
);

ResumableSession _resumableOf(ResumableRow row, RoundCounts? round) =>
    ResumableSession(
      sessionId: row.session.id,
      deckName: row.deckName,
      kind: SessionKind.values.byName(row.session.sessionKind),
      mode: StudyMode.fromCode(row.session.currentMode),
      progress: round == null
          ? null
          : RoundProgress(completed: round.completed, total: round.total),
    );

StudyHomeDeck _deckOf(DeckTileRow row) => StudyHomeDeck(
  deckId: row.id,
  name: row.name,
  // A root always has its scheduler (the CHECK of `deck`).
  schedulerType: SchedulerType.fromCode(row.schedulerType!),
  cardCount: row.cardCount,
  overdueCount: row.overdueCount,
  dueTodayCount: row.dueTodayCount,
  newCount: row.newCount,
);
```

Create `lib/features/study/domain/repositories/study_home_repository.dart`:

```dart
import 'package:memox/features/study/domain/models/study_home_model.dart';

/// The Study tab's read (UC-STUDY-002). The one implementation is
/// `StudyHomeRepositoryImpl` (data layer); the contract exists for ADR-010's
/// reason: domain stays framework-free and tests substitute a fake.
abstract interface class StudyHomeRepository {
  /// UC-STUDY-002 step 1 (Study Home spec §6): the session Resume takes up
  /// and every root deck with its workload as of [now], Overdue before
  /// [startOfToday], read as one snapshot; again after every write it can
  /// see. It writes nothing (BR-STUDY-075).
  Stream<StudyHome> watchHome({
    required DateTime now,
    required DateTime startOfToday,
  });
}
```

- [ ] **Step 5: Read the snapshot in one transaction**

Create `lib/features/study/data/repositories/study_home_repository_impl.dart`:

```dart
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/failure.dart';
import 'package:memox/features/study/data/datasources/study_queue_dao.dart';
import 'package:memox/features/study/data/datasources/study_view_dao.dart';
import 'package:memox/features/study/data/mappers/study_home_mapper.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';

/// Reads the Study tab (UC-STUDY-002; Study Home spec §6): four reads in one
/// transaction, once when listened to and again after every write the tab
/// can see.
final class StudyHomeRepositoryImpl implements StudyHomeRepository {
  StudyHomeRepositoryImpl(this._db)
    : _queue = StudyQueueDao(_db),
      _views = StudyViewDao(_db);

  final AppDatabase _db;
  final StudyQueueDao _queue;
  final StudyViewDao _views;

  @override
  Stream<StudyHome> watchHome({
    required DateTime now,
    required DateTime startOfToday,
  }) => _views
      .homeChanges()
      .asyncMap(
        (_) => _db.transaction(
          () => _snapshot(now: now, startOfToday: startOfToday),
        ),
      )
      .mapDatabaseErrors();

  /// The root decks, the resumable session and its round, and the next due
  /// date, read in the caller's transaction so they see one state of the
  /// database (UC-STUDY-002 step 1).
  Future<StudyHome> _snapshot({
    required DateTime now,
    required DateTime startOfToday,
  }) async {
    final roots = await _views.rootDeckRows(
      now: now,
      startOfToday: startOfToday,
    );
    final resumable = await _views.resumableSessionRow(
      startOfToday: startOfToday,
    );
    return studyHomeOf(
      roots: roots,
      resumable: resumable,
      round: resumable == null ? null : await _roundOf(resumable.session),
      nextDueAt: await _views.nextDueAt(now: now),
    );
  }

  /// The counts of the round [session] serves, read as the session screen
  /// reads them (spec D3); null while it serves nothing.
  Future<RoundCounts?> _roundOf(StudySession session) async {
    final head = await _queue.headRow(
      session.id,
      session.currentMode,
      session.cursor,
    );
    if (head == null) return null;
    return _views.roundCounts(session.id, head.mode, head.round);
  }
}
```

- [ ] **Step 6: Give the repository a provider**

Create `lib/features/study/di/study_home_repository_provider.dart`:

```dart
import 'package:memox/core/database/di/database_provider.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'study_home_repository_provider.g.dart';

@riverpod
StudyHomeRepository studyHomeRepository(Ref ref) =>
    StudyHomeRepositoryImpl(ref.watch(databaseProvider));
```

- [ ] **Step 7: Generate the provider**

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected: the run prints `Built with build_runner`, and `study_home_repository_provider.g.dart` exists next to its provider.

- [ ] **Step 8: Regenerate the docs index**

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 9: Run the task's tests**

```bash
flutter test test/features/study/data/watch_study_home_stream_test.dart \
  test/features/study/data/watch_study_home_test.dart
```

Expected: `+16: All tests passed!`

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

Expected: `No issues found!`; `+1297: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 11: Commit**

```bash
git add docs/_generated \
  lib/features/study/data/datasources/study_view_dao.dart \
  lib/features/study/data/mappers/study_home_mapper.dart \
  lib/features/study/data/repositories/study_home_repository_impl.dart \
  lib/features/study/di/study_home_repository_provider.dart \
  lib/features/study/domain/repositories/study_home_repository.dart \
  test/features/study/data/watch_study_home_stream_test.dart \
  test/features/study/data/watch_study_home_test.dart
git commit -F - <<'EOF'
feat(study): the Study tab reads one snapshot of its sessions and decks

StudyHomeRepository reads the root decks with their workload (the Library
root level's statement), the session Resume takes up, the counts of the round
it serves and the next due date, in one transaction (UC-STUDY-002 step 1;
Study Home spec §6). The Resume conditions of BR-STUDY-075 are one SQL
fragment, which the Study Entry's Continue now shares. The stream listens to
the tables before its first read, and nothing on the path writes.
EOF
```

Append the session's attribution trailers to the message when you commit.


### Task 3: The Study tab's use case, and the package's documents

**Files:**
- Create: `lib/features/study/domain/usecases/watch_study_home_use_case.dart`
- Modify: `docs/features/study/data.md`, `docs/features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md`, `docs/wbs_BE.md`
- Test (create): `test/features/study/domain/watch_study_home_use_case_test.dart`
- Regenerate: `docs/_generated/` (`python3 tools/docs/generate.py`)

**Interfaces:**
- Consumes: `StudyHomeRepository` (Task 2); `DayClock` and `watchEachLocalDay`
  (`lib/core/clock/day_clock.dart`); `startOfLocalDay`
  (`srs/domain/models/due_date_model.dart`); `FakeDayClock` (`test/support/`).
- Produces: `WatchStudyHomeUseCase(StudyHomeRepository, DayClock)` with
  `Stream<StudyHome> call()`
  (`study/domain/usecases/watch_study_home_use_case.dart`); UC-STUDY-002's
  `code:` names it; `features/study/data.md` describes the Study tab's
  snapshot; `wbs_BE.md` has BE-A6 done.

Spec §7, §10; Clarification 5. The use case reads the tab again at
each local midnight, as `WatchDeckLevelUseCase` does, so Due today turns
Overdue and yesterday's session stops being offered with no write.

- [ ] **Step 1: Write the failing tests**

Create `test/features/study/domain/watch_study_home_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:memox/core/database/app_database.dart';
import 'package:memox/core/error/outcome.dart';
import 'package:memox/features/deck/data/repositories/deck_repository_impl.dart';
import 'package:memox/features/study/data/repositories/study_home_repository_impl.dart';
import 'package:memox/features/study/domain/failures/study_failure.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/usecases/watch_study_home_use_case.dart';

import '../../../support/card_fixtures.dart';
import '../../../support/deck_fixtures.dart';
import '../../../support/fake_day_clock.dart';
import '../../../support/study_fixtures.dart';
import '../../../support/test_database.dart';

// UC-STUDY-002 step 5 and A2: the Study tab across a local midnight.

(int, int) overdueAndDueToday(StudyHome home) {
  final workload = home.content as RootDeckWorkload;
  return (workload.overdueCount, workload.dueTodayCount);
}

void main() {
  late AppDatabase db;
  setUp(() => db = openTestDatabase());
  tearDown(() async {
    await expectStudyInvariants(db);
    await db.close();
  });

  test("at local midnight a card due today becomes Overdue and yesterday's "
      'session is no longer offered, with no write (BR-STUDY-068, '
      'BR-STUDY-075)', () async {
    final evening = DateTime(2026, 9, 25, 21);
    final decks = DeckRepositoryImpl(db, now: () => evening);
    final root = await decks.root('Korean');
    final lesson = await decks.sub(root.id, 'Lesson');
    await insertCard(
      db,
      id: 'today',
      deckId: lesson.id,
      back: 'today',
      learnedAt: DateTime(2026, 9, 1),
      dueAt: DateTime(2026, 9, 25),
      box: 2,
    );
    await insertCard(db, id: 'new', deckId: lesson.id, back: 'new');
    await lockScheduler(db, root.id);
    final opened = await studyEntryRepository(
      db,
      () => evening,
    ).openLearningSession(deckId: lesson.id);
    final id = (opened as Ok<String, StudyRejection>).value;
    final clock = FakeDayClock(evening);
    final homes = <StudyHome>[];

    final subscription = WatchStudyHomeUseCase(
      StudyHomeRepositoryImpl(db),
      clock,
    ).call().listen(homes.add);
    await pumpEventQueue();
    final before = await totalChanges(db);
    expect(homes.last.resumable?.sessionId, id);
    expect(overdueAndDueToday(homes.last), (0, 1));

    clock.startDay(DateTime(2026, 9, 26));
    await pumpEventQueue();

    expect(homes.last.resumable, isNull);
    expect(overdueAndDueToday(homes.last), (1, 0));
    expect(await totalChanges(db), before);
    await subscription.cancel();
  });
}
```

- [ ] **Step 2: Run them to see them fail**

```bash
flutter test test/features/study/domain/watch_study_home_use_case_test.dart
```

Expected: `+0 -1: Some tests failed.` The test file does not compile: the use case does not exist yet. The first errors: `Error: Error when reading 'lib/features/study/domain/usecases/watch_study_home_use_case.dart': No such file or directory`, `Error: Method not found: 'WatchStudyHomeUseCase'.`

- [ ] **Step 3: Write the use case**

Create `lib/features/study/domain/usecases/watch_study_home_use_case.dart`:

```dart
import 'package:memox/core/clock/day_clock.dart';
import 'package:memox/features/srs/domain/models/due_date_model.dart';
import 'package:memox/features/study/domain/models/study_home_model.dart';
import 'package:memox/features/study/domain/repositories/study_home_repository.dart';

/// UC-STUDY-002: the Study tab, again on every write it can see and at every
/// local midnight, when Due today becomes Overdue and yesterday's session is
/// no longer offered, with no write (BR-STUDY-068, BR-STUDY-075; Study Home
/// spec §7).
final class WatchStudyHomeUseCase {
  const WatchStudyHomeUseCase(this._home, this._clock);

  final StudyHomeRepository _home;
  final DayClock _clock;

  Stream<StudyHome> call() => watchEachLocalDay(
    _clock,
    (now) => _home.watchHome(now: now, startOfToday: startOfLocalDay(now)),
  );
}
```

- [ ] **Step 4: Record the package in the use case, the data document and the WBS**

In `docs/features/study/data.md`:

Replace

```markdown
gợi ý chưa hiện (BR-STUDY-036).
```

with

```markdown
gợi ý chưa hiện (BR-STUDY-036).

## Tab Study

Tab Study đọc một snapshot trong một transaction: mọi root deck kèm workload của cả
cây (cùng câu truy vấn với cấp root của Thư viện), phiên có thể Resume cùng số đếm của
round nó đang phục vụ, và hạn gần nhất sau hiện tại (UC-STUDY-002).

- Resume chỉ nhận phiên `in_progress`, bắt đầu từ đầu ngày học hiện tại, cùng
  generation với root, deck và root không nằm trong Trash, và còn ít nhất một dòng hàng
  đợi. Nhiều phiên thì lấy phiên mới nhất; bắt đầu cùng lúc thì lấy `id` lớn hơn
  (BR-STUDY-075). Tiếp tục ở màn vào học dùng đúng các điều kiện này.
- Đọc không ghi gì: phiên của ngày trước vẫn mở cho tới khi `abandonStaleSessions` đóng
  nó (BR-STUDY-072).
- Snapshot được đọc lại sau mỗi lần ghi vào `deck`, `card`, `card_schedule`,
  `study_session` hay `study_queue_items`, và ở mỗi nửa đêm địa phương.
```

In `docs/features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md`:

Replace

```markdown
rules: [BR-STUDY-008, BR-STUDY-017, BR-STUDY-020, BR-STUDY-036, BR-STUDY-051, BR-STUDY-068, BR-STUDY-072, BR-STUDY-074, BR-STUDY-075, BR-STUDY-076, BR-STUDY-077]
code: []
---
```

with

```markdown
rules: [BR-STUDY-008, BR-STUDY-017, BR-STUDY-020, BR-STUDY-036, BR-STUDY-051, BR-STUDY-068, BR-STUDY-072, BR-STUDY-074, BR-STUDY-075, BR-STUDY-076, BR-STUDY-077]
code: [lib/features/study/domain/usecases/watch_study_home_use_case.dart]
---
```

In `docs/wbs_BE.md`:

Replace

```markdown
| BE-D1 | Khung test migration Drift: snapshot schema theo từng version, bước nâng cấp sinh từ snapshot (`stepByStep`) và test nâng cấp; migration đầu tiên v1 → v2 của gói 2b | xong | — | S | Spec gói 2b §5, §6; `drift_schemas/`, `test/drift/migration_test.dart` | Mỗi migration sau thêm snapshot và bước của nó ([skill flutter-drift](../.claude/skills/flutter-drift/references/migrations.md)) |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

with

```markdown
| BE-D1 | Khung test migration Drift: snapshot schema theo từng version, bước nâng cấp sinh từ snapshot (`stepByStep`) và test nâng cấp; migration đầu tiên v1 → v2 của gói 2b | xong | — | S | Spec gói 2b §5, §6; `drift_schemas/`, `test/drift/migration_test.dart` | Mỗi migration sau thêm snapshot và bước của nó ([skill flutter-drift](../.claude/skills/flutter-drift/references/migrations.md)) |
| BE-A6 | Study Home, 1 use case (UC-STUDY-002): một snapshot trong một transaction gồm phiên có thể Resume (bốn điều kiện của BR-STUDY-075, dùng chung với Tiếp tục của màn vào học) và mọi root deck kèm workload của cả cây; ba trạng thái đã tải, thứ tự của BR-STUDY-076 và tổng của hero ở domain; đọc lại sau mỗi lần ghi và ở mỗi nửa đêm, không ghi gì | xong | BE-A4 | M | [spec](superpowers/specs/2026-09-25-study-home-backend-design.md) và [plan](superpowers/plans/2026-09-25-study-home-backend.md) gói 3; test trong `test/features/study/` | FE-A8 dựng màn 13 trên use case này |
| BE-A9 | Read của danh sách card cho screen handoff: mỗi card mang tag (một statement theo trang) và nhãn hạn (`CardDue`); view đếm 4 trạng thái hiển thị của cả deck; stream phát lại khi tag của card đổi | xong | BE-04, BE-05 | S | [spec căn Thư viện](superpowers/specs/2026-09-24-library-artifact-alignment-design.md) §5, phase B; test trong `test/features/card/` | Phase E đọc các trường này |
```

Replace

```markdown
|---|---|---|---|---|---|---|
| BE-A6 | Study Home: read model cho tab Study (việc cần học trên toàn thư viện, phiên đang dở) (UC-STUDY-002) | chưa bắt đầu | BE-A4 | M | UC chưa có code | Sau BE-A4 |
| BE-A7 | Progress: tiến độ theo deck và tổng quan, chỉ đọc (UC-PROGRESS-001, UC-PROGRESS-002; BR-PROGRESS-001…BR-PROGRESS-018) | chưa bắt đầu | BE-A4 | L | [README progress](features/progress/README.md): chỉ đọc lịch sử học, không ghi gì | Cần dữ liệu `review_log` thật do BE-A4 ghi. Panel "Mastered x/y" và sort "progress" chờ tài liệu (xem Điểm chặn) |
```

with

```markdown
|---|---|---|---|---|---|---|
| BE-A7 | Progress: tiến độ theo deck và tổng quan, chỉ đọc (UC-PROGRESS-001, UC-PROGRESS-002; BR-PROGRESS-001…BR-PROGRESS-018) | chưa bắt đầu | BE-A4 | L | [README progress](features/progress/README.md): chỉ đọc lịch sử học, không ghi gì | Cần dữ liệu `review_log` thật do BE-A4 ghi. Panel "Mastered x/y" và sort "progress" chờ tài liệu (xem Điểm chặn) |
```

Replace

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 12/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001, UC-STUDY-003).
  10 UC còn lại chưa có code.

```

with

```markdown
  mỗi task, final review toàn nhánh trước khi mở PR.
- **BE-A6** (gói 3, [spec](superpowers/specs/2026-09-25-study-home-backend-design.md),
  [plan](superpowers/plans/2026-09-25-study-home-backend.md)): gate năm lệnh xanh sau
  mỗi task, final review toàn nhánh trước khi mở PR.
- **Traceability:** có test chứa ID cho 13/22 UC (UC-CARD-001, UC-CARD-002, UC-DECK-001…UC-DECK-006, UC-SETTINGS-001, UC-SRS-001, UC-STUDY-001…UC-STUDY-003).
  9 UC còn lại chưa có code.

```

Replace

```markdown

Không có hạng mục backend nào đang làm sau gói 2b (BE-D1, BE-A10).

```

with

```markdown

Không có hạng mục backend nào đang làm sau gói 3 (BE-A6).

```

Replace

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 62 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-ORG (4), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

with

```markdown
  về UC của nó.
  - Test hiện có nhắc tới 62 ID: IT-CONT (12), IT-DISC (4), IT-LEARN (10), IT-MODE (12), IT-NAV (1), IT-ORG (3), IT-REVIEW (9), IT-STUDY (11). Danh sách:
    `grep -rhoE 'IT-[A-Z]+-[0-9]+' test | sort -u`.
```

Replace

```markdown

1. Gói 3: BE-A6. Rồi BE-A7, rồi BE-A8. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
```

with

```markdown

1. Gói 4: BE-A7. Rồi BE-A8. BE-D2 càng sớm càng tốt.
2. Sau V8.0: BE-B1 trước (đổi hành vi xoá và mang migration v2 → v3), rồi BE-B2…BE-B5
```

Replace

```markdown
  (v1 → v2) thuộc gói này, nên BE-B1 mang migration v2 → v3.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

with

```markdown
  (v1 → v2) thuộc gói này, nên BE-B1 mang migration v2 → v3.
- **Cập nhật ngày 2026-09-25:** BE-A6 xong trong gói 3. Số ID kịch bản IT được đếm lại
  trên cây: #49 bỏ test nhắc IT-ORG-013, và gói 3 nhắc IT-NAV-002.
- **Cập nhật cùng commit:** sửa file này trong cùng commit với việc nó mô tả.
```

Run:

```bash
python3 tools/docs/generate.py
python3 tools/docs/check.py
```

Expected: `check.py` ends with `PASS — 0 error(s)`.

- [ ] **Step 5: Run the task's tests**

```bash
flutter test test/features/study/domain/watch_study_home_use_case_test.dart
```

Expected: `+1: All tests passed!`

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

Expected: `No issues found!`; `+1298: All tests passed!`;
`✓ architecture boundaries clean`; `OK (skipped=11)`; the guard's summary
`Total: 2 | Errors: 0 | Warnings: 0 | Info: 2` (the two infos are
`guard.config.rule_targets_pending`); `PASS — 0 error(s)` (the warnings are
older than this plan).

- [ ] **Step 7: Commit**

```bash
git add docs/_generated \
  docs/features/study/data.md \
  docs/features/study/usecases/UC-STUDY-002-mo-tab-study-va-chon-viec-de-hoc.md \
  docs/wbs_BE.md \
  lib/features/study/domain/usecases/watch_study_home_use_case.dart \
  test/features/study/domain/watch_study_home_use_case_test.dart
git commit -F - <<'EOF'
feat(study): the Study tab's use case, read again at each local midnight

WatchStudyHomeUseCase reads the Study tab through watchEachLocalDay, so at
local midnight Due today turns Overdue and yesterday's session is no longer
offered, with no write (BR-STUDY-068, BR-STUDY-075). UC-STUDY-002's code
field names it, the study data document describes the snapshot, and the
backend WBS has BE-A6 done, with the IT scenario count taken again from the
tree.
EOF
```

Append the session's attribution trailers to the message when you commit.


## Plan self-review

- **Spec coverage.** §5 the read model: Task 1. §6.1 the four reads, §6.2 one
  transaction, §6.3 when it reads, §6.4 mapping, §6.5 errors: Task 2. §7 the
  use case and the day: Task 3. §8 the contract for the UI: Tasks 2 and 3 (the
  repository's provider, the use case). §9 tests: every line has its test in
  Tasks 1–3, the Study Entry's tests stay green in Task 2. §10 documents:
  `code:`, `data.md`, the WBS and `docs/_generated/` (Task 3 and every task).
- **Scenarios named by the spec (§9).** The backend half of IT-NAV-002 step 1
  (Task 2) is named by a test.
- **Placeholders.** None: every step carries its code or its command and its
  expected output.
- **Type consistency.** The Interfaces blocks name each signature once; the
  replay compiled every task on top of the previous one.
- **Review Focus.** Each of the five lines has its test in Task 2.
