# MemoX V8 — Study Home backend design (package 3)

Status: draft 2026-09-25, for the owner's review · Path: architectural

## 1. Intent

Build BE-A6 of [`docs/wbs_BE.md`](../../wbs_BE.md): the read model of the Study
tab, UC-STUDY-002, with BR-STUDY-075, BR-STUDY-076 and BR-STUDY-077, and the rules
they lean on (BR-STUDY-008, BR-STUDY-020, BR-STUDY-068, BR-STUDY-072).

The package writes `domain/`, `data/` and `di/` of `lib/features/study/`. The screen
(13 Study home of the kit) belongs to FE-A8 in [`docs/wbs_FE.md`](../../wbs_FE.md).

Success means:

- FE-A8 builds every state of screen 13 from one use case, with no second read;
- the Study tab reads one snapshot, the resumable session and every root deck with
  its workload, in one transaction (UC-STUDY-002 step 1);
- reading writes nothing (BR-STUDY-075), and a test fails when it does;
- the Resume card follows the four conditions of BR-STUDY-075 exactly as the Study
  Entry does: one SQL fragment serves both;
- a root deck's counts are the Library root level's, from the same statement;
- every rule above that the backend owns has a test that fails when it breaks;
- the phased gate of the root `README.md` passes after every task;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-25)

- `master` is at `54cb7fe`: package 2b (#50) merged.
- **UC-STUDY-002** is `ready` with `code: []`, and no test names it: two warnings of
  `tools/docs/check.py`.
- **The rules.**
  - UC-STUDY-002 step 1: one snapshot of the resumable session and every root deck
    with its workload, in one transaction; entering, scrolling or leaving the tab
    writes nothing.
  - BR-STUDY-075: the Resume card only for a session that is `in_progress`, started
    on the current local day (BR-STUDY-074), at its root's generation (BR-STUDY-017)
    and with at least one queue row; the newest by `started_at` when several are
    open. Closing a session of an earlier day stays with `abandonStaleSessions`
    (BR-STUDY-072). No read creates a session (BR-STUDY-020), locks a scheduler or
    builds a queue.
  - BR-STUDY-076: root decks only, one row each, the workload of the whole subtree
    through `root_id`; ordered by Overdue, then Due today, then New, all descending,
    never by the total; ties by the Unicode-folded name (BR-TAG-001's convention,
    never SQL's `lower()`), then `id`. A deck with no workload stays, last; a deck
    with no card gets no open action.
  - BR-STUDY-077: three loaded states: no root deck, root decks without a card, and
    cards, even when every workload is zero (BR-STUDY-008).
  - BR-STUDY-068: the sets. Overdue: learned and `due_at < startOfToday`; Due today:
    learned, `due_at >= startOfToday` and `due_at <= now`; New: `learned_at IS
    NULL`. `startOfToday` comes from Dart, never from SQL.
- **Code this package builds on.**
  - `deckLevelOfRoots` (`lib/core/database/queries/deck_queries.drift`): every active
    root deck with `card_count`, `new_count`, `overdue_count`, `due_today_count` and
    `scheduler_type`, grouped by `root_id` in one statement, with the sets of
    BR-STUDY-068. The Library root level reads it through `DeckDao`.
  - `StudyViewDao.resumableSessionId(deckId, startOfToday)` (package 2a): the four
    conditions of BR-STUDY-075, for one deck.
  - The session screen's progress (`StudySessionViewRepositoryImpl._servedOf`): the
    head row (`StudyQueueDao.headRow` of the session's mode at its cursor) and the
    counts of its round (`StudyViewDao.roundCounts`); none while nothing is served.
  - `StudyEntry.nextDueAt`: the Study Entry's earliest `due_at` after now, for its
    empty state.
  - `DayClock`, `watchEachLocalDay` and `startOfLocalDay`: `WatchDeckLevelUseCase`
    reads again at each local midnight, so Due today turns Overdue with no write.
  - The card list's change-driven read (`CardRepositoryImpl._watchCardList`): a first
    read, then `CardListDao.changes()`, a Drift `tableUpdates` stream that fires once
    per transaction.
  - `study_session.deck_id` references `deck` with `ON DELETE CASCADE`; `root_id` has
    no foreign key. A root deck always has `scheduler_type` and `generation` (CHECK).
  - ADR-011: `data/` imports its own `domain/` and `core/`, so study reads
    `deckLevelOfRoots` without importing `deck`. The study import map stays
    `study → {study_mode, srs, settings, card}`.
  - Guard: `StudyViewDao` is at 211 logical lines, `StudyEntryRepositoryImpl` at 215
    (non-blank, non-comment lines; the guard's own count decides).
- **Kit, screen 13, seven states:** `loaded`, `noResume`, `zero`, `noDecks`,
  `noCards`, `loading`, `error`. What they show:
  - the Resume card: the session's deck, "Review · Self-assess", "12 / 20 cards" and a
    progress bar;
  - the hero: "N cards due", "N overdue · N due today · N new", "across K decks"; at
    zero workload "Nothing due right now … The next one becomes due tomorrow at
    00:00";
  - a deck row: the name, the breakdown, an "N due" badge; "No cards yet" for a deck
    without cards, "N cards · nothing due" for one without workload;
  - `noDecks`: the Starter Library and Library; `noCards`: Library; `error`: a retry.
- **Kit against the rules.**
  - The kit's breakdown line drops a term that is zero, while BR-STUDY-076 shows all
    three numbers even at zero. The rule wins; FE-A8 records the deviation. The read
    model always carries the three numbers.
  - The kit's zero copy says "tomorrow". That holds only when the next card is due
    tomorrow, so the read model carries the date (D4).
- **Scenarios.** No IT scenario targets the Study tab. IT-NAV-002 (`HOST-WIDGET`,
  traced to BR-STUDY-020) says in step 1 that switching to the Study tab creates no
  session; its backend half is this package's.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | BE-A6 only: the Study tab's read model and its use case | Owner's WBS order, 2026-09-24 |
| D2 | Approach | A repository of its own, `StudyHomeRepository`. Four reads in one transaction make the snapshot; the domain holds the three states, the order and the hero's totals as pure functions; the use case reads again at each local midnight | Owner, 2026-09-25 (approach A of three) |
| D3 | Progress on the Resume card | `completed / total` of the round the session serves, as the session screen shows it (`RoundProgress`); none while nothing is served | Owner, 2026-09-25 |
| D4 | `nextDueAt` | The earliest `due_at` after now of a learned card, card and deck not in the Trash, across the library; null when none. The zero state names the day with it | Owner, 2026-09-25 |
| D5 | The counts | `deckLevelOfRoots` itself, so the Study tab and the Library root level cannot disagree | Owner, 2026-09-25 |
| D6 | The Resume conditions | One SQL fragment serves the Study tab and the Study Entry. Two open sessions started at the same instant fall to the higher `id`, so the pick is stable | Owner, 2026-09-25 |
| D7 | The stream | Subscribe to the table changes first, then read: a write that lands right after the first read is not lost. A transaction that writes fires one read | Owner, 2026-09-25 |
| D8 | Read only | Nothing on this path writes. Closing a session of an earlier day stays with `abandonStaleSessions` (BR-STUDY-072) | BR-STUDY-075 |
| D9 | Documents | Of the BR and UC files, only UC-STUDY-002's `code:` changes. `features/study/data.md`, `wbs_BE.md` and `docs/_generated/` change with it | Owner, 2026-09-25 |
| D10 | Branch and PR | Branch `claude/be-study-home` from `master`. When the gate is green and the final review is clean, the package is opened as a PR and squash-merged | Owner's standing choice |

## 4. Structure

```
lib/features/study/
├── domain/
│   ├── models/study_home_model.dart                StudyHome, ResumableSession,
│   │                                               StudyHomeContent, StudyHomeDeck,
│   │                                               studyHomeContentOf, compareStudyHomeDecks
│   ├── repositories/study_home_repository.dart     watchHome
│   └── usecases/watch_study_home_use_case.dart     WatchStudyHomeUseCase
├── data/
│   ├── datasources/study_view_dao.dart             resumableSessionRow, nextDueAt,
│   │                                               rootDeckRows, homeChanges; the shared
│   │                                               Resume fragment
│   ├── mappers/study_home_mapper.dart              rows → StudyHome
│   └── repositories/study_home_repository_impl.dart
└── di/study_home_repository_provider.dart          studyHomeRepositoryProvider

test/features/study/domain/study_home_test.dart
test/features/study/domain/watch_study_home_use_case_test.dart
test/features/study/data/watch_study_home_test.dart
```

The use case's provider belongs to FE-A8's `presentation/providers/`, as for every
use case so far.

## 5. The read model

### 5.1 Types

```dart
/// The Study tab (UC-STUDY-002): the session Resume takes up, and the library's
/// root decks with their workload, read as one snapshot.
final class StudyHome {
  final ResumableSession? resumable;   // null: no Resume card (A1, A2)
  final StudyHomeContent content;
}

final class ResumableSession {
  final String sessionId;
  final String deckName;               // the session's deck, a sub-deck or a root
  final SessionKind kind;              // from the session row (BR-SRS-015)
  final StudyMode mode;                // from the session row (BR-MODE-008)
  final RoundProgress? progress;       // D3; null while nothing is served
}

sealed class StudyHomeContent {}
final class NoRootDecks extends StudyHomeContent {}      // BR-STUDY-077
final class NoCards extends StudyHomeContent {}          // BR-STUDY-077
final class RootDeckWorkload extends StudyHomeContent {
  final List<StudyHomeDeck> decks;     // in the order of §5.3
  final DateTime? nextDueAt;           // D4
  int get overdueCount;                // the hero's totals (§5.4)
  int get dueTodayCount;
  int get newCount;
  int get dueCount;                    // overdue + due today
  int get workloadDeckCount;           // "across K decks"
  bool get isCaughtUp;                 // every workload zero (A3, BR-STUDY-008)
}

final class StudyHomeDeck {
  final String deckId;
  final String name;
  final SchedulerType schedulerType;
  final int cardCount;
  final int overdueCount;
  final int dueTodayCount;
  final int newCount;
  bool get hasWorkload;                // any of the three above greater than zero
  bool get canStudy;                   // cardCount > 0 (BR-STUDY-076)
}
```

`SessionKind`, `StudyMode`, `SchedulerType` and `RoundProgress` are the existing
types; no second type means the same thing.

### 5.2 The three loaded states

`studyHomeContentOf(decks, nextDueAt:)` decides, as a pure function:

- no root deck: `NoRootDecks`;
- root decks, none with a card: `NoCards`, with no numbers at all;
- otherwise `RootDeckWorkload`, every root deck included, even when every workload
  is zero.

### 5.3 The order

`compareStudyHomeDecks` (BR-STUDY-076): Overdue descending, then Due today
descending, then New descending, then `foldText(name)` ascending, then `id`
ascending. A deck with no workload, with cards or without, sorts after every deck
that has some, by the same keys.

### 5.4 The hero

The totals add up the rows, so the hero always agrees with the list: `dueCount` is
Overdue plus Due today (BR-STUDY-068 keeps that sum), and `workloadDeckCount`
counts the decks where `hasWorkload`.

### 5.5 The Resume card

- `deckName` is the session's deck, which is a sub-deck when the session was opened
  on one; `kind` and `mode` come from the session row, never inferred.
- `progress` is the session screen's: the counts of the round of the head row. It
  is null when the session serves nothing right now, as on the session screen.
- Resume itself is package 2a's `ResumeStudySession`, which settles and serves the
  saved turn (BR-STUDY-036).

## 6. The snapshot

### 6.1 The four reads

1. **Root decks:** `deckLevelOfRoots(startOfToday, now)`, through
   `StudyViewDao.rootDeckRows`.
2. **The resumable session:**

   ```sql
   SELECT s.*, d.name AS deck_name FROM study_session s
   JOIN deck d ON d.id = s.deck_id
   JOIN deck r ON r.id = s.root_id
   WHERE <resumable>
   ORDER BY s.started_at DESC, s.id DESC LIMIT 1
   ```

   `<resumable>` is the fragment the Study Entry's `resumableSessionId` uses too (D6):

   ```sql
   s.status = 'in_progress' AND s.started_at >= ? AND s.generation = r.generation
   AND d.delete_batch_id IS NULL AND r.delete_batch_id IS NULL
   AND EXISTS (SELECT 1 FROM study_queue_items q WHERE q.session_id = s.id)
   ```

   The Study Entry's query keeps its `s.deck_id = ?` and gains the join on `d`, the
   Trash filters and the `id` tie-break. None changes what it returns today.
3. **The progress** of that session: `StudyQueueDao.headRow(session, currentMode,
   cursor)`, then `StudyViewDao.roundCounts` of the head row's mode and round.
4. **`nextDueAt`:**

   ```sql
   SELECT MIN(cs.due_at) AS next_due_at FROM card c
   JOIN deck k ON k.id = c.deck_id
   JOIN card_schedule cs ON cs.card_id = c.id
   WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL
     AND cs.learned_at IS NOT NULL AND cs.due_at > ?
   ```

### 6.2 One transaction

`StudyHomeRepositoryImpl` runs the four reads in one `transaction`, so they see one
state of the database (UC-STUDY-002 step 1): a session that ends between two reads
cannot leave its Resume card beside counts that already include its turns.

### 6.3 When it reads

- `StudyViewDao.homeChanges()` fires once when listened to, then after every write
  to `deck`, `card`, `card_schedule`, `study_session` or `study_queue_items`. It
  listens to `tableUpdates` before it fires the first time (`Stream.multi`), so a
  write queued behind the first read is seen (D7).
- `watchHome` maps each firing to one snapshot with `asyncMap`, which reads one at a
  time and in order.

### 6.4 Mapping

`study_home_mapper.dart` turns the rows into the domain values: a `DeckTileRow` into
a `StudyHomeDeck`, the session row, its deck's name and its round counts into a
`ResumableSession`, and hands the decks to `studyHomeContentOf`.

### 6.5 Errors

`watchHome` ends in `.mapDatabaseErrors()`: a failed read reaches the UI as a
database `Failure`, which shows the error state with a retry (E1). The error names
no table, query or path.

## 7. The use case and the day

`WatchStudyHomeUseCase(StudyHomeRepository, DayClock)` returns
`watchEachLocalDay(clock, (now) => repository.watchHome(now: now, startOfToday:
startOfLocalDay(now)))`. At each local midnight the snapshot is read again with no
write:

- a card due today becomes Overdue (BR-STUDY-068);
- yesterday's open session is no longer offered (BR-STUDY-075, A2), and stays open
  until `abandonStaleSessions` closes it.

## 8. Use cases — the contract for the UI

| Use case | Input | Output | Errors |
|---|---|---|---|
| `WatchStudyHomeUseCase` | none | `Stream<StudyHome>`: again after every write it can see and at each local midnight | a database `Failure` on the stream (E1) |

For FE-A8:

- Resume calls package 2a's `ResumeStudySession(sessionId)` and opens the session
  screen. Guarding a double tap is the controller's (BR-STUDY-075).
- A deck row's Study opens the Study Entry of `deckId` (UC-STUDY-001), only when
  `canStudy`.
- `NoRootDecks` leads to the Starter Library and Library, `NoCards` to Library; a
  deck row shows its three numbers even at zero (BR-STUDY-076); the zero state
  names `nextDueAt`'s day.

## 9. Tests

Every test names the rule or the use case it pins.

`test/features/study/domain/study_home_test.dart` (pure):

- orders by Overdue, then Due today, then New, never by the total (BR-STUDY-076);
- breaks a tie by the Unicode-folded name, then by `id` (BR-STUDY-076);
- no root deck, roots without a card, cards with no workload: the three states
  (BR-STUDY-077, BR-STUDY-008);
- a deck without a card stays in the list, after the decks with work, and cannot
  be studied (BR-STUDY-076);
- the hero's totals and the decks with work (UC-STUDY-002).

`test/features/study/data/watch_study_home_test.dart` (UC-STUDY-002, a test
database):

- the Resume card names the session's deck, its kind and its mode, and for a
  session opened on a sub-deck the sub-deck (BR-STUDY-075, BR-SRS-015,
  BR-MODE-008);
- its progress is the one the session screen shows for the same session (D3);
- no Resume card for a session that fails one of the four conditions: ended,
  started before today, at an old generation, with no queue row left
  (BR-STUDY-075; A1, A2);
- the newest of two open sessions (BR-STUDY-075);
- a root deck's counts are its whole tree's (BR-STUDY-076);
- a session whose deck is in the Trash is not offered, and a card in the Trash
  counts toward nothing;
- `nextDueAt` is the earliest `due_at` after now of a learned card, and null when
  none waits (D4);
- reading writes nothing, even with yesterday's session open, which stays open
  (BR-STUDY-075, BR-STUDY-020; the backend half of IT-NAV-002 step 1);
- the stream emits again when a session ends or is abandoned, and when a turn is
  answered (UC-STUDY-002 step 5);
- a write made while the first read runs is not lost (D7);
- a failed read emits a database `Failure` (E1).

`test/features/study/domain/watch_study_home_use_case_test.dart`:

- at local midnight a card due today becomes Overdue and yesterday's session is no
  longer offered, with no write (BR-STUDY-068, BR-STUDY-075).

The Study Entry's existing tests (`watch_entry_test.dart`) keep passing with the
shared fragment.

## 10. Documents

- **UC-STUDY-002:** `code:` names `watch_study_home_use_case.dart`. No other line of
  a BR or UC file changes (D9).
- **`docs/features/study/data.md`:** a section on the Study tab: one snapshot, the
  four Resume conditions it shares with the Study Entry, and that it closes nothing.
- **`docs/wbs_BE.md`:** BE-A6 done; nothing in progress after package 3; the order
  moves on to BE-A7; the update log; the traceability line.
- **`docs/_generated/`:** regenerated.

## 11. Out of scope

- FE-A8: screen 13, its controller and ARB strings, the route, the Starter Library's
  "Coming soon" sheet (spec A4), guarding a double tap on Resume, and showing the
  zero terms.
- Closing sessions of an earlier day: `abandonStaleSessions` (BR-STUDY-072), when the
  person enters the study flow.
- The Study Entry's reads, apart from the shared Resume fragment.
- The card list's read-then-subscribe order in `CardRepositoryImpl._watchCardList`.
  If the prototype shows that it can lose a write, the owner is told, and it stays
  out of this package.
- The Trash (BE-B1).

## 12. Risks and rollback

- **Load.** Each write to the five tables re-reads the snapshot while the Study tab
  listens. Its heaviest read is `deckLevelOfRoots`, which the Library root level
  already runs on the same writes. FE-A8's provider disposes when the tab is gone.
- **The shared fragment** changes the Study Entry's query. It returns the same rows
  today; `watch_entry_test.dart` proves it.
- **Rollback.** No schema change and no write: reverting the package's commits
  removes it.
