# MemoX V8 — Progress backend design (package 4)

Status: approved 2026-09-25 · amended while writing the plan (its Clarifications: D1, D6, D9, D11, §2, §5.3, §6, §10–§12) · Path: architectural

## 1. Intent

Build BE-A7 of [`docs/wbs_BE.md`](../../wbs_BE.md): the read models of the Progress
screen, UC-PROGRESS-001 (the overview) and UC-PROGRESS-002 (progress by deck), with
BR-PROGRESS-001…BR-PROGRESS-018 and the rules they lean on (BR-STUDY-074, BR-SRS-015,
BR-SRS-016, BR-SRS-023, BR-MODE-005, BR-DECK-001…BR-DECK-003, BR-CORE-002).

The package writes `domain/`, `data/` and `di/` of a new `lib/features/progress/`.
The screen (22 Progress of the kit, eight states) belongs to FE-A9 in
[`docs/wbs_FE.md`](../../wbs_FE.md).

Success means:

- FE-A9 builds every state of screen 22 from two use cases, one per route
  (`/progress` and `/progress/:deckId`), with no second read on either;
- both ranges, 7 and 30 days, come from one read: switching the range reads nothing
  (BR-PROGRESS-003);
- every total is read from the statement that reads the rows, never added up from
  them (BR-PROGRESS-002);
- reading writes nothing (BR-PROGRESS-007, BR-PROGRESS-009), and a test fails when it
  does;
- every rule above that the backend owns has a test that fails when it breaks;
- the phased gate of the root `README.md` passes after every task;
- the documents change in the same commits as the code (`docs/README.md`).

## 2. Context (2026-09-25)

- `master` is at `66d9597`: package 3 (#55) merged.
- **UC-PROGRESS-001 and UC-PROGRESS-002** are `ready` with `code: []`, and no test
  names them.
- **The rules.**
  - The unit is the card-day, a distinct `(local day, card)`: six answers to one card
    in one evening count once (BR-PROGRESS-002, BR-PROGRESS-011). `active days` are
    never added up across decks: one day in two decks is one study day.
  - Every row, however old, falls on its local day by the UTC offset of the current
    read; `review_log` keeps no offset. A time-zone or DST change re-buckets past
    days, an accepted consequence (BR-PROGRESS-011). "Today" is
    `[startOfToday, startOfTomorrow)` from one snapshot of the clock and the offset;
    SQL never derives a local midnight (BR-PROGRESS-013).
  - Learning and Reviewing partition the card-days by the stored `kind`: a card-day
    with at least one `learning` answer is Learning, every other one Reviewing, so
    `learning + reviewing = total` (BR-PROGRESS-005, BR-PROGRESS-014).
  - The overview: Today with its split, the last seven days (exactly seven, oldest
    first, a day without activity as 0) and the current streak (anchored today, else
    held from yesterday, else 0; no cap, not cut by the seven days)
    (BR-PROGRESS-014…BR-PROGRESS-016). Nothing else: no accuracy, longest streak,
    goal, XP or heatmap (BR-PROGRESS-010).
  - By deck: exactly four numbers per scope, `unique active cards`, `active days`,
    Learning and Reviewing card-days (BR-PROGRESS-001), for two ranges of whole
    local days ending today, 7 and 30, from one read; the snapshot carries when it
    expires, the next local midnight (BR-PROGRESS-003).
  - History belongs to a card's current place: a moved card takes its whole history
    along. A deck's numbers cover its whole subtree, the root through `root_id` and a
    level below through a recursive walk, never `COALESCE(parent_id, id)`. A deleted
    deck vanishes through the schema's cascade, not a filter (BR-PROGRESS-004). A
    reset keeps `review_log` and changes no number; a hard delete removes the card's
    history, past days included (BR-PROGRESS-017). `browse` writes no answer, so it
    makes no card-day (BR-PROGRESS-012, BR-MODE-005).
  - The deck list: by `unique active cards` of the chosen range, descending, then
    the name folded in Dart (`toLowerCase()`, never SQL's `lower()`), then `id`; a
    deck with no activity stays, last (BR-PROGRESS-006).
  - Read only: opening, leaving, switching the range or retrying writes nothing and
    opens, resumes or closes no session (BR-PROGRESS-007, BR-PROGRESS-009).
  - Live: a new answer, a moved card or subtree, a deleted deck and a local midnight
    all change the numbers with no action; the first three through the tables'
    change streams, the fourth through one timer (BR-PROGRESS-008, BR-PROGRESS-018).
- **Code this package builds on.**
  - `review_log` (`lib/core/database/tables/srs.drift`): `kind` (`learning`,
    `scheduled`, `relearning`), `mode`, `answered_at` (drift's default: UTC seconds),
    `card_id REFERENCES card (id) ON DELETE CASCADE`; append-only triggers; indexes
    `(card_id, answered_at)` and `(session_id)`, none on `answered_at` alone.
  - `deck_queries.drift`: `deckLevelOfRoots` groups a tree by `root_id`;
    `deckLevelOfChildren` walks each child's subtree recursively (`UNION`, cycle safe);
    `deckAndAncestors(deckId)` returns the deck and every deck above it, root first,
    and no row when the deck is not active.
  - `StudyViewDao.homeChanges()` (package 3): a `Stream.multi` that listens to
    `tableUpdates` before it fires its first read, so a write queued behind that read
    is seen. Package 3's final review deferred a minor: make it a shared helper once
    a second read model needs the same guarantee.
  - `DayClock` and `watchEachLocalDay` (`lib/core/clock/day_clock.dart`): the Library's
    deck level and the Study tab read again at each local midnight through them.
  - `foldText` (`lib/core/text/folded_text.dart`): `trim()` then Dart's Unicode
    `toLowerCase()`.
  - `mapDatabaseErrors` (`lib/core/error/failure.dart`); the `logReview` test fixture
    (`test/support/card_fixtures.dart`) writes a `review_log` row at any time, kind
    and mode.
  - ADR-011's import map, `allowedFeatureImports` in
    `test/architecture/boundary_rules.dart`: a new feature adds its entry in the
    commit that creates it.
- **Kit, screen 22, eight states:** `loading`, `error`, `loaded` (7 days), `month`
  (30 days), `held`, `lost`, `deck`, `never`. What they show:
  - the range control, "Last 7 days" and "Last 30 days", switched with no loading;
  - Today: the total, "N learning · N reviewing", and seven stacked day bars,
    Learning over Reviewing, the last one labelled Today;
  - Streak: "N days" with "includes today", "held from yesterday" or "no study
    yesterday"; held: "Study one card today and the streak continues at N + 1";
    lost: "The streak ended on Sunday. It starts again with the next card you study";
  - by deck: a section header with the range and "N active cards · N card-days", one
    row per deck with its active cards, active days, Learning and Reviewing; a deck
    without activity dimmed, "No activity in this range";
  - `deck`: a deck's direct children under the same header, with the deck's name in
    the app bar and a breadcrumb;
  - `never`: a person who never studied, told apart from a lapsed one
    (`hasLifetimeActivity`), with empty charts;
  - `error`: "Couldn't summarise your progress", "Your study history is safe on this
    device", a retry.
- **Kit and documents against the rules and the code.**
  - The lost note names the day the streak ended, so the read model carries the last
    active day.
  - The kit's section header adds the rows up. BR-PROGRESS-002 wins: the read model
    carries totals read from the statement.
  - UC-PROGRESS-001 A2 describes a whole-screen empty with a way to Study; the kit's
    `never` state keeps the layout with empty charts. The layout is FE-A9's to rule
    on; the read model carries the `never` state either way.
  - UC-PROGRESS-002 A2 (no deck at all) and E2 (the deck of a link is gone) have no
    kit state; the read model still tells them apart.
  - UC-PROGRESS-001, BR-PROGRESS-013 and BR-PROGRESS-018 were written for V7: they
    name `clockProvider` and `utcOffsetProvider` and put the midnight timer in the UI
    controller. V8 has `DayClock` and reads again in the use case (D4).
- **Scenarios.** IT-NAV-011 step 2: opening Progress creates no study session and
  writes nothing (BR-PROGRESS-009, BR-PROGRESS-007). Its backend half is this
  package's.
- **Blocked, not this package.** The mastery display of the deck list (screen 01's
  mastery bars, donut and "Mastered", hidden and marked "waits for BE-A7") and the
  deck list's "progress" sort that UC-DECK-006 names (under Coming soon). The card
  states they would count exist (BR-CARD-006…BR-CARD-008), and the card list's
  "mastered" panel of IT-ORG-010 is already built on BE-A9's counts, but no BR or UC
  says what the deck list's display or sort counts (D1).

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | UC-PROGRESS-001 and UC-PROGRESS-002. The deck list's mastery display and its "progress" sort stay blocked; their blocked row leaves BE-A7 for the deck list, which owns them (the card list's panel of IT-ORG-010 is already built) | Owner, 2026-09-25 |
| D2 | Approach | Two read models: `WatchProgressUseCase` for `/progress` (the overview and the library level) and `WatchDeckProgressUseCase` for `/progress/:deckId` (a deck's level, or the deck is missing). Each emission runs its statements in one transaction | Owner, 2026-09-25 (approach A of three) |
| D3 | Local days | A row's day is `(answered_at + offset) / 86400`, with `answered_at` in UTC seconds and the offset of the read. `ProgressDays` computes today, both ranges and `validUntil` in Dart, from `now` and its offset; SQL gets day numbers and never derives a midnight | BR-PROGRESS-011, BR-PROGRESS-013 |
| D4 | Midnight | The use cases read again at each local midnight through `watchEachLocalDay`, as the Library and the Study tab do, and the snapshot carries `validUntil` (BR-PROGRESS-003). The documents put a one-shot timer in the UI controller over V7's providers; V8's lives in `DayClock` and behaves as they require: one per listener, cancelled with it, never looping on a boundary already past, and the offset read again at every read | Owner, 2026-09-25 |
| D5 | Totals | One statement per level returns the rows and one total row, `UNION ALL` over the same set of card-days: a total is read, never added up | BR-PROGRESS-002 |
| D6 | The overview | SQL folds the whole history into the days with activity, and the last seven days into card-days with their Learning and Reviewing split. Dart takes the streak and the last active day from the first, Today and the bars from the second (plan Clarification 1) | UC-PROGRESS-001 step 2; Owner, 2026-09-25 |
| D7 | What counts | A card and its deck out of the Trash. Never a row of mode `browse` (BR-PROGRESS-012; no such row is written today). Never a row whose day is after today. A hard delete leaves nothing to filter: the cascade took it | Owner, 2026-09-25 |
| D8 | The change stream | Package 3's listen-first stream becomes a helper in `lib/core/database/` over a list of tables; Study Home and Progress share it. Progress listens to `review_log`, `card` and `deck` | Owner, 2026-09-25 |
| D9 | Schema | No change. Measured by the plan on a synthetic log: the `/progress` snapshot reads in about 100 ms at 100,000 answers and 280 ms at 300,000 on a 4-core desktop container. An index on `answered_at` would be its own package, with a migration | Owner, 2026-09-25 |
| D10 | Read only | Nothing on these paths writes; no session is opened, resumed or closed | BR-PROGRESS-007, BR-PROGRESS-009 |
| D11 | Documents | Of the BR and UC files, only the `code:` of UC-PROGRESS-001 and UC-PROGRESS-002 changes. With them: the progress README (`code:`, and its stale note that the repository has no `lib/`), a new `features/progress/data.md`, `wbs_BE.md`, the FE-A1 blocked row of `wbs_FE.md`, and `docs/_generated/`, and the three cells of `shared/ui/screen-handoff/01-deck-list.md` that wait on BE-A7 (the mastery display twice, the progress sort once), which point to the blocked row instead | Owner, 2026-09-25 |
| D12 | Branch and PR | Branch `claude/be-progress` from `master`. When the gate is green and the final review is clean, the package is opened as a PR and squash-merged | Owner's standing choice |

## 4. Structure

```
lib/core/database/table_changes.dart                  tableChanges (D8)

lib/features/progress/
├── domain/
│   ├── models/progress_days_model.dart                ProgressDays
│   ├── models/progress_overview_model.dart            ProgressOverview, DayActivity,
│   │                                                  ActiveDay, CurrentStreak,
│   │                                                  StreakState, progressOverviewOf
│   ├── models/progress_level_model.dart               ProgressRange, ProgressNumbers,
│   │                                                  RangeProgress, ProgressDeckRow,
│   │                                                  ProgressLevel, compareProgressDecks
│   ├── models/progress_model.dart                     Progress, DeckProgress,
│   │                                                  DeckProgressLevel,
│   │                                                  ProgressDeckMissing,
│   │                                                  ProgressPathSegment
│   ├── repositories/progress_repository.dart          watchProgress, watchDeckProgress
│   └── usecases/watch_progress_use_case.dart          WatchProgressUseCase
│       usecases/watch_deck_progress_use_case.dart     WatchDeckProgressUseCase
├── data/
│   ├── datasources/progress_dao.dart                  activeDays, weekActivity,
│   │                                                  rootLevel, childLevel,
│   │                                                  deckPath, changes
│   ├── mappers/progress_mapper.dart                   rows → the read model
│   └── repositories/progress_repository_impl.dart
└── di/progress_repository_provider.dart               progressRepositoryProvider
```

`StudyViewDao.homeChanges()` delegates to `tableChanges`. `allowedFeatureImports`
gains `'progress': {}`: the feature reads core's tables and imports no other feature.
The use cases' providers belong to FE-A9's `presentation/providers/`, as for every
use case so far. The plan settles the file split of the tests.

## 5. The read model

### 5.1 Days

```dart
/// The local days of one read (BR-PROGRESS-011, BR-PROGRESS-013): every row falls
/// on the day its UTC time has at [utcOffset].
final class ProgressDays {
  factory ProgressDays.of(DateTime now, Duration utcOffset);
  final int today;              // days since 1970-01-01, at utcOffset
  final Duration utcOffset;
  int get weekStart;            // today - 6  (BR-PROGRESS-003, BR-PROGRESS-015)
  int get monthStart;           // today - 29 (BR-PROGRESS-003)
  DateTime get validUntil;      // the next local midnight, an instant (BR-PROGRESS-003)
  DateTime dateOf(int day);     // the day's calendar date, DateTime(y, m, d), for labels
}
```

`today` is `(now in UTC seconds + offset in seconds) ~/ 86400`. The use cases pass
`now` and `now.timeZoneOffset`; tests pass any offset.

### 5.2 Types

```dart
/// `/progress` (UC-PROGRESS-001, UC-PROGRESS-002 library level): one snapshot.
final class Progress {
  final ProgressOverview overview;
  final ProgressLevel level;           // a row per root deck
  final DateTime validUntil;
}

/// `/progress/:deckId` (UC-PROGRESS-002 deck level).
sealed class DeckProgress {}
final class DeckProgressLevel extends DeckProgress {
  final List<ProgressPathSegment> path; // root first, the deck last
  final ProgressLevel level;            // a row per direct child; none for a deck of cards (A1)
  final DateTime validUntil;
}
final class ProgressDeckMissing extends DeckProgress {}  // E2: not an error
final class ProgressPathSegment { final String deckId; final String name; }

final class ProgressOverview {
  final DayActivity today;
  final List<DayActivity> lastSevenDays; // exactly seven, oldest first
  final CurrentStreak streak;
  final DateTime? lastActiveDay;         // null only when never studied
  bool get hasLifetimeActivity;          // streak.state != never
}
final class DayActivity {
  final DateTime date;
  final int learning;                    // card-days (BR-PROGRESS-014)
  final int reviewing;
  int get total;                         // learning + reviewing
}
final class CurrentStreak { final int days; final StreakState state; }
enum StreakState { includesToday, heldFromYesterday, lost, never }

/// A row of statement 2 (§6.2): a day of the last seven with activity.
final class ActiveDay { final int day; final int learning; final int reviewing; }

enum ProgressRange { week, month }       // 7 and 30 days (BR-PROGRESS-003)
final class ProgressNumbers {            // exactly four (BR-PROGRESS-001)
  final int activeCards;
  final int activeDays;
  final int learningCardDays;
  final int reviewingCardDays;
  int get cardDays;                      // learning + reviewing (BR-PROGRESS-005)
  bool get hasActivity;                  // activeCards > 0
}
final class RangeProgress {
  final ProgressNumbers week;
  final ProgressNumbers month;
  ProgressNumbers of(ProgressRange range);
}
final class ProgressDeckRow {
  final String deckId;
  final String name;
  final RangeProgress progress;          // its whole subtree (BR-PROGRESS-004)
}
final class ProgressLevel {
  final RangeProgress total;             // read, never added up (D5)
  List<ProgressDeckRow> decksFor(ProgressRange range);  // in the order of §5.4
  bool get hasDecks;
}
```

### 5.3 The overview

`progressOverviewOf(activeDays:, week:, days:)` is pure. It takes the day numbers
with activity up to today, oldest first (`activeDays`, statement 1), and the last
seven days' rows, each a day number with its Learning and Reviewing card-days
(`week`, statement 2), and:

- **Today:** today's row, or zeros.
- **Last seven days:** the rows of `weekStart…today` in that order, a missing day as
  zeros, each with its date (BR-PROGRESS-015).
- **The streak** (BR-PROGRESS-016): the anchor is today when today has activity,
  else yesterday when yesterday has. From the anchor it counts the days that follow
  each other back in time, with no cap. The state is `includesToday` or
  `heldFromYesterday` by the anchor; with no anchor it is `lost` when any day has
  activity and `never` when none does, and `days` is 0.
- **The last active day:** the latest day with activity, for the lost note.

### 5.4 The order

`compareProgressDecks(range)` (BR-PROGRESS-006): `activeCards` of the range
descending, then `foldText(name)` ascending, then `deckId` ascending. A deck with no
activity has 0, the least, so it sorts after every deck with some, by the same keys,
and stays in the list. `ProgressLevel` sorts once per range when it is built;
`decksFor` reads, never sorts again, so switching the range is free
(BR-PROGRESS-003).

## 6. The reads

### 6.1 The card-days

Statements 2 to 4 (§6.2) start from the same set, the card-days of live cards in
their scope; statement 1 takes only the distinct days of the same answers:

```sql
SELECT c.id AS card_id, <tile> AS tile_id,
       (r.answered_at + :offset) / 86400 AS day,
       MAX(r.kind = 'learning') AS is_learning
FROM review_log r
JOIN card c ON c.id = r.card_id
JOIN deck k ON k.id = c.deck_id
WHERE c.delete_batch_id IS NULL AND k.delete_batch_id IS NULL
  AND r.mode <> 'browse'
  AND (r.answered_at + :offset) / 86400 BETWEEN :month_start AND :today
GROUP BY c.id, day
```

The day condition sits in `WHERE`, so answers outside the range are never grouped;
statement 2 takes the week instead of the month.

`is_learning` makes the partition (BR-PROGRESS-005, BR-PROGRESS-014). A range's four
numbers are `COUNT(DISTINCT card_id)`, `COUNT(DISTINCT day)`,
`COUNT(*) FILTER (WHERE is_learning)` and `COUNT(*) FILTER (WHERE NOT is_learning)`,
with `day >= :week_start` added for the week. SQLite accepts `DISTINCT` with
`FILTER`; the plan pins the exact statements.

### 6.2 The five statements

1. **`activeDays(offset, today)`:** the distinct days with activity over the whole
   history up to today, oldest first: the streak's days.
2. **`weekActivity(offset, weekStart, today)`:** the card-days of the last seven
   days, grouped by `day` with their Learning and Reviewing card-days. Neither
   statement lets a raw `review_log` row or a per-day read leave SQLite
   (UC-PROGRESS-001 step 2). Folding every card-day of the history instead cost
   about twice as much (plan Clarification 1).
3. **`rootLevel(offset, weekStart, monthStart, today)`:** every active root deck,
   with no activity too (`LEFT JOIN`), with its eight numbers, `<tile>` being
   `k.root_id`; then, `UNION ALL`, one total row over the same card-days (D5).
4. **`childLevel(deckId, offset, weekStart, monthStart, today)`:** every active direct
   child of `deckId`, its subtree walked from each child as `deckLevelOfChildren`
   walks it (`UNION`, cycle safe, no cap); the total row also takes the cards held
   by the deck itself.
5. **`deckPath(deckId)`:** `deckAndAncestors`; no row means `ProgressDeckMissing`.

### 6.3 One transaction

- `watchProgress` runs statements 1, 2 and 3 in one `transaction`, so Today and the
  deck numbers see one state of the database, as they share one screen
  (UC-PROGRESS-001 step 4).
- `watchDeckProgress` runs statement 5, then 4 when the deck is there, in one
  `transaction`.

### 6.4 When it reads

`tableChanges(db, tables)` fires once when listened to, then after every write to
one of `tables`; a flat transaction fires once (a repository call nested in
another transaction fires once per call; none is nested today). It listens before
it fires the first time (D8, package 3's D7). Progress passes `review_log`, `card` and `deck`: a new
answer, a moved card or deck, a deleted or trashed one and a renamed one
(BR-PROGRESS-008). Each firing becomes one snapshot through `asyncMap`, one at a
time and in order.

### 6.5 Mapping

`progress_mapper.dart` turns a row of the last seven days into an `ActiveDay`, a
level row into a `ProgressDeckRow` with its `RangeProgress`, the total row into the
level's `total`, and a `deckAndAncestors` row into a `ProgressPathSegment`.

### 6.6 Errors

Both streams end in `.mapDatabaseErrors()`: a failed read reaches the UI as a
database `Failure`, which shows the error state with a retry (UC-PROGRESS-001 E1,
UC-PROGRESS-002 E1). The error names no table, query or card (BR-CORE-002). A
missing deck is a value, not an error (UC-PROGRESS-002 E2).

## 7. The use cases and the day

- `WatchProgressUseCase(ProgressRepository, DayClock)` returns
  `watchEachLocalDay(clock, (now) => repository.watchProgress(ProgressDays.of(now,
  now.timeZoneOffset)))`.
- `WatchDeckProgressUseCase(ProgressRepository, DayClock)` does the same for
  `watchDeckProgress(deckId: deckId, days: ...)`.

At each local midnight the snapshot is read again with no write: the window slides
a day, Today goes to 0 and the streak takes its "held from yesterday" branch
(UC-PROGRESS-001 A4, UC-PROGRESS-002 A4). The offset is read at every new day and
every new subscription (a retry); within a day, a write re-reads with the day's
offset. A time-zone change mid-day re-buckets the days from the next midnight or
the next subscription (BR-PROGRESS-011's accepted consequence).

## 8. Use cases — the contract for the UI

| Use case | Input | Output | Errors |
|---|---|---|---|
| `WatchProgressUseCase` | none | `Stream<Progress>`: again after every write it can see and at each local midnight | a database `Failure` on the stream (E1) |
| `WatchDeckProgressUseCase` | `deckId` | `Stream<DeckProgress>`: the same, or `ProgressDeckMissing` | a database `Failure` on the stream (E1) |

For FE-A9:

- The range control reads `level.decksFor(range)` and `level.total.of(range)`; it
  never reads the database (BR-PROGRESS-003).
- A row opens `/progress/:deckId`. At the library level no deck
  (`!level.hasDecks`) is UC-PROGRESS-002 A2; at a deck level no row is A1. A range
  without activity is `!total.of(range).hasActivity` (A3).
- `StreakState` maps to the kit's streak copy; `lastActiveDay` names the day in the
  lost note; `never` is the kit's `never` state.
- `ProgressDeckMissing` shows the missing-deck state with the way back, and no
  retry (E2).

## 9. Tests

Every test names the rule or the use case it pins.

Domain (pure):

- `ProgressDays`: today, both ranges and `validUntil` at the offsets +7, −5, +14 and
  −12, across the end of a month and of a year (BR-PROGRESS-003, BR-PROGRESS-015);
- the overview: Today and its split; seven days, oldest first, zero-filled
  (BR-PROGRESS-015); the streak from today, held from yesterday, lost and never,
  longer than seven days (BR-PROGRESS-016); the last active day;
- the order: by active cards of the range, then the folded name (`Động` beside
  `động`), then `id`; decks with no activity last and stable across two reads
  (BR-PROGRESS-006).

Data (a test database, `logReview`):

- six answers to one card in one evening are one card-day and one active day; two
  decks studied on one day are one active day at the level above
  (BR-PROGRESS-002, BR-PROGRESS-011);
- a day with a `learning` and a `scheduled` answer to one card is a Learning day
  (BR-PROGRESS-005, BR-PROGRESS-014);
- 23:30 and 00:30 local at +7 fall on two days; the same rows read at another
  offset fall elsewhere (BR-PROGRESS-011);
- the week holds today and six days before, the month today and 29 before; one
  emission carries both (BR-PROGRESS-003);
- a root deck's numbers are its whole tree's; a deck level's rows are its direct
  children and its total takes its own cards (BR-PROGRESS-004);
- a moved card takes its history along; a deleted card or deck takes its history
  away, past days included; a reset changes nothing (BR-PROGRESS-004,
  BR-PROGRESS-017);
- a `browse` row, a card or deck in the Trash and a row dated after today count
  nowhere (BR-PROGRESS-012; D7);
- a missing or trashed deck is `ProgressDeckMissing` (UC-PROGRESS-002 E2);
- the stream emits again on a new answer, a moved card, a deleted deck and a
  renamed deck (BR-PROGRESS-008);
- reading writes nothing (BR-PROGRESS-007, BR-PROGRESS-009; the backend half of
  IT-NAV-011 step 2);
- a failed read emits a database `Failure` (E1);
- the plan's Review Focus.

The use case: at local midnight the window slides and Today returns to 0, with no
write (BR-PROGRESS-018, UC-PROGRESS-001 A4). Package 3's stream tests keep passing on
the shared helper.

## 10. Documents

- **UC-PROGRESS-001:** `code:` names `watch_progress_use_case.dart`.
  **UC-PROGRESS-002:** `code:` names both use cases. No other line of a BR or UC file
  changes (D11).
- **`docs/features/progress/README.md`:** `code:` names the feature's `domain`,
  `data` and `di`; the stale note that the repository has no `lib/` goes.
- **`docs/features/progress/data.md`** (new): the card-day, the day of a row, the
  statements, when they read, and that nothing writes.
- **`docs/wbs_BE.md`:** BE-A7 done; the blocked row moves from BE-A7 to the deck
  list; the order moves on to BE-A8; the update log; the traceability line.
- **`docs/wbs_FE.md`:** FE-A1's blocked row waits for the definition, not BE-A7.
- **`docs/shared/ui/screen-handoff/01-deck-list.md`** (D11): the three cells that
  wait on BE-A7 (the mastery display twice, the progress sort once) point to the
  blocked row.
- **`docs/_generated/`:** regenerated.

## 11. Out of scope

- FE-A9: screen 22, its controllers and ARB strings, the routes, the breadcrumb, the
  A1 line, the empty and `never` layouts, and the retry.
- The mastery display of the deck list and its "progress" sort (D1). The card
  list's panel of IT-ORG-010 is already built on BE-A9's counts.
- Every metric of BR-PROGRESS-010.
- An index on `review_log.answered_at` (D9).
- The Trash (BE-B1): the filters are in place; restore and purge come with it.

## 12. Risks and rollback

- **Load.** Each write to `review_log`, `card` or `deck` re-reads the snapshot while a
  Progress screen listens. Statement 1 scans the whole history, since the streak has
  no cap; the others filter by day, with no index to help. Measured (D9): about
  100 ms per `/progress` snapshot at 100,000 answers and 280 ms at 300,000, on a
  4-core desktop container; a phone is slower. FE-A9's providers dispose when their
  screen is gone.
- **The shared helper** changes package 3's stream; its tests prove it unchanged.
- **Time zones.** A change of offset re-buckets past days (BR-PROGRESS-011). On a DST
  day, the day of the read's offset can differ by an hour from the calendar day
  other screens use.
- **Rollback.** No schema change and no write: reverting the package's commits
  removes it.
