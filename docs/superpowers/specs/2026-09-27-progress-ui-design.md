# FE-A9: the Progress UI — design

Status: draft for review; design sections approved 2026-09-27 · Path: architectural · Owner rulings 2026-09-27 (§3)

## 1. Intent

The Progress tab is still `PlaceholderScreen`. The backend of package 4 (BE-A7,
[spec](2026-09-25-progress-backend-design.md)) already has both read models of
UC-PROGRESS-001 and UC-PROGRESS-002. FE-A9 puts them on screen as kit screen 22,
"Progress", in two levels:

- **The library level, `/progress`:** Today with the last seven days, the current
  streak, and one row per root deck for the chosen range (7 or 30 days).
- **A deck's level, `/progress/:deckId`:** the deck's path, the range, and one row per
  direct child. A row opens the next level down.

The screen only reads. Its numbers follow every write and every local midnight on
their own (BR-PROGRESS-008, BR-PROGRESS-018).

Success means three things:

- every state of kit 22 is built from `Mx*` widgets, or is recorded as a deviation
  with the reason;
- each flow of UC-PROGRESS-001 (main, A1–A7, E1–E2) and UC-PROGRESS-002 (main, A1–A4,
  E1–E2) that the screen shows has a test;
- FE-A9 is the last item of V8.0 in [`wbs_FE.md`](../../wbs_FE.md).

## 2. Context (2026-09-27)

- **Backend (BE-A7):**
  - `WatchProgressUseCase` → `Stream<Progress>` (`overview`, `level`, `validUntil`);
  - `WatchDeckProgressUseCase(deckId)` → `Stream<DeckProgress>`, either
    `DeckProgressLevel` (`path`, `level`) or `ProgressDeckMissing`;
  - both read again at each local midnight (`watchEachLocalDay`), and a failed read
    reaches the stream as a database `Failure` (package 4 spec §6.6, §8).
- **The level:** `ProgressLevel.total.of(range)` and `decksFor(range)`, both sorted
  once. `ProgressNumbers` carries `activeCards`, `activeDays`, `learningCardDays`,
  `reviewingCardDays`, `cardDays` and `hasActivity`.
- **The overview:** `today`, `lastSevenDays` (seven `DayActivity`, oldest first),
  `streak` (`days`, `StreakState` of `includesToday`, `heldFromYesterday`, `lost` or
  `never`) and `lastActiveDay`.
- **The import map:** `test/architecture/boundary_rules.dart` gives `progress` no
  feature import.
- **The kit:** screen 22 has 8 states: `loaded` (Last 7 days), `month`, `held`,
  `lost`, `deck`, `never`, `loading` and `error`. They are captured in
  `docs/shared/ui/screen-handoff/img/22-progress/`, with screen 22 added to
  `tools/design/screen_states.json`.
- **Shared widgets that exist:** `MxSegmentedTray`, `MxCard`, `MxListSectionHeader`,
  `MxNote`, `MxEmptyState`, `MxErrorState`, `MxSkeletonList`, `MxBreadcrumb`,
  `MxIconTile` and `MxButton`.
- **Missing:**
  - a chart of stacked day bars;
  - a dashed placeholder;
  - a `streak` colour in the theme. Foundations defines it (#F97316 / #FFAE6E), and
    `mx_semantic_colors.dart` leaves every PRESERVE_ONLY colour unbound until a
    consumer exists.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Never studied | The kit's layout: dashed placeholders in Today and Streak, and every deck row at 0 (UC-PROGRESS-002 A3). Below Today's placeholder, a "Start studying" button opens the Study tab, which UC-PROGRESS-001 A2 asks for. Recorded as a deviation from the kit and from A2's "one empty state for the whole screen" | Owner, 2026-09-27 |
| D2 | The total | A total row heads each list, in the same shape as a deck row: active cards on the right; active days, learning and reviewing on the sub-line. It is read, never added up (BR-PROGRESS-002), and it is not a button. The kit's header trailing text stays | Owner, 2026-09-27 |
| D3 | Structure | Two screens, `ProgressScreen` and `DeckProgressScreen`, sharing their section widgets. Each reads one `StreamProvider` over its use case. No controller: the screen only reads | Owner, 2026-09-27 (approach A of three) |
| D4 | The range | One `progressRangeProvider` for the whole tab: a deck opened from Last 30 days opens at Last 30 days, and Back keeps the choice. Switching reads `decksFor(range)` and `total.of(range)` and never the database | Owner, 2026-09-27; BR-PROGRESS-003 |
| D5 | The route | `/progress/:deckId` is a child of the Progress branch, so the bottom navigation stays, as the kit draws it. Each row pushes one level; Back returns to the level it left, at any depth | Owner, 2026-09-27; UC-PROGRESS-002 step 5 |
| D6 | New shared widgets | `MxStackedDayBars` (stacked two-series day bars, day labels, legend, one TalkBack label per bar) and `MxDashedNote` (the kit's dashed placeholder). The guard allows raw layout only in `lib/shared/widgets/` | Owner, 2026-09-27 |
| D7 | The streak colour | `streak` joins `MxSemanticColors`, light and dark, from foundations, with `AppIcons.streak` (flame). This screen is its first consumer | Owner, 2026-09-27 |
| D8 | Live numbers | Once a level has shown, a new emission replaces the numbers without the skeleton (BR-PROGRESS-018). Retry is `ref.invalidate` of the level's provider | UC-PROGRESS-001 A3, E1 |
| D9 | The Study tab | `progress` imports no feature. "Start studying" calls a callback that `app/` wires to the Study branch | ADR-011 import map |

## 4. Structure

```
lib/shared/widgets/
  mx_stacked_day_bars.dart              D6
  mx_dashed_note.dart                   D6
lib/core/theme/                          D7: `streak` in the semantic colours
lib/features/progress/presentation/
  providers/
    watch_progress_use_case_provider.dart
    watch_deck_progress_use_case_provider.dart
    progress_provider.dart               Stream<Progress>
    deck_progress_provider.dart          family by deckId, Stream<DeckProgress>
    progress_range_provider.dart         ProgressRange, the tab's choice (D4)
  screens/
    progress_screen.dart                 /progress
    deck_progress_screen.dart            /progress/:deckId
  widgets/sections/
    progress_today_widget.dart           Today and the seven bars
    progress_streak_widget.dart          the two tiles and the note
    progress_level_list_widget.dart      header, total row, deck rows, A1/A3 notes
    progress_footer_widget.dart          the read-only line
  widgets/items/
    progress_deck_row_widget.dart        one deck, or the total (D2)
lib/app/router/                          the child route, the Study callback
```

Exact file names follow the guard's buckets and suffixes, and the plan settles them.

## 5. Behaviour

### 5.1 The library level (`/progress`)

From top to bottom, in one scroll view:

1. **App bar:** the large title "Progress".
2. **Range:** `MxSegmentedTray` with "Last 7 days" and "Last 30 days" (D4).
3. **Today** (`MxCard`):
   - the overline, the figure (`today.total`), and one of these sub-lines:
     - "{learning} learning · {reviewing} reviewing · a card counts once per day";
     - "No cards studied yet today" when today is 0;
     - "Nothing studied yet" when the state is `never`;
   - `MxStackedDayBars` over `lastSevenDays`: learning stacked over reviewing, today's
     bar at full strength, a day with nothing as a thin baseline;
   - day labels are the locale's narrow weekday, and the last reads "Today";
   - the legend: Learning, Reviewing.
4. **Streak** (`MxCard`), with two tiles side by side:
   - **"Current":** the flame in `streak` (in `onSurfaceVariant` at 0), "{n} days" (or
     "1 day"), and "includes today", "held from yesterday" or "no study yesterday";
   - **"Today":** "{n} cards", and "counted once each" or "nothing yet";
   - when the streak is held, an `MxNote`: "Study one card today and the streak
     continues at {n + 1}.";
   - when it is lost, an `MxNote`: "The streak ended on {day}. It starts again with the
     next card you study." {day} is the weekday name when `lastActiveDay` falls within
     the last six days, else a short date ("Sep 3").
5. **The list:**
   - the header "BY DECK · LAST 7 DAYS" (or "· LAST 30 DAYS"), with the kit's trailing
     "{active cards} active cards · {card-days} card-days";
   - the total row "All decks" (D2);
   - one row per root deck, in `decksFor(range)` order. Each row shows:
     - the name;
     - the sub-line "{days} active days · {learning} learning · {reviewing} reviewing",
       with learning in the learning ink and reviewing in `primaryInk`;
     - active cards on the right, over "cards".
   - A deck with no activity in the range is dimmed and reads "No activity in this
     range". A row opens `/progress/:deckId`.
6. **The footer line:** "Read-only · a card studied several times in a day counts
   once · resets change nothing here".

### 5.2 A deck's level (`/progress/:deckId`)

- **App bar:** Back and the deck's name.
- **`MxBreadcrumb`:** "Progress › {root} › … › {deck}" from `path`.
- **Range:** the same tray.
- **The list:** the header "SUB-DECKS · LAST 7 DAYS", the total row "Whole deck", and
  one row per direct child.
- **The footer line.**
- There is no Today and no Streak (UC-PROGRESS-002 step 1).

### 5.3 States

| State | Shown |
|---|---|
| Last 7 days / Last 30 days | §5.1 with the chosen range |
| Streak held, streak lost | §5.1 item 4, with its note |
| Never (D1) | `MxDashedNote` in Today ("Your last seven days appear here once you study. Browsing cards does not count.") and in Streak ("A streak starts with your first study day."). Below Today's note, "Start studying" (secondary `MxButton`) opens the Study tab. Every deck row at 0 |
| A range with no activity (UC-PROGRESS-002 A3) | an `MxNote` below the total row: "Nothing studied in the last 7 days. Switch to Last 30 days to see older study." At Last 30 days, only the first sentence. Neutral, never the error colour |
| No decks (UC-PROGRESS-002 A2) | only `MxEmptyState` "No decks yet · Create a deck in the Library and its progress appears here". No button, no range, no total |
| Inside a deck | §5.2 |
| A deck with no children (A1) | the total row and an `MxNote`: "This deck holds its cards directly, so the total above is all of it." |
| Deck gone (E2) | `MxEmptyState` "This deck is no longer here" with Back, and no Retry (UI-base row 129) |
| Loading | the range tray, then `MxSkeletonList` (UI-base row 125), where the kit draws a skeleton per card |
| Error (E1) | `MxErrorState` "Couldn't summarise your progress · Your study history is safe on this device. Try again in a moment." with Retry, and no range |

Every string is in `app_en.arb` (with its description) and `app_vi.arb`. Days and dates
are formatted with `intl` in the app's locale. Counts use ICU plurals.

## 6. Errors

- A failed read is a database `Failure` on the stream. The screen shows the error
  state. Its copy names the kind of failure, never `Failure.message`, and never a table
  or a card (BR-CORE-002).
- Retry invalidates the provider once. A second failure stays on the error state, with
  no loop and no write (UC-PROGRESS-001 E2).
- A deck that is gone is a value (`ProgressDeckMissing`), not an error.

## 7. Tests

- **Providers and the range:** plain `test()`s over a `LibraryEnv` that write
  `review_log` rows:
  - switching the range reads nothing;
  - a new answer updates the numbers and shows no skeleton (D8);
  - Retry reads again.
- **Widget tests (`libraryTest`),** one per state of §5.3. Also:
  - a row opens the deck's level;
  - Back returns to the level it left, and the range is kept;
  - "Start studying" calls the Study callback.
- **Goldens:**
  - the 8 kit states, light and dark, each compared with its kit capture;
  - 4 states the kit lacks: A1, A2, A3 and E2.
- **Visual audit:** 360 dp at text scale 2, in English and Vietnamese. Nothing
  overflows, and every target is 48 dp.
- **Shared widgets:** `MxStackedDayBars` and `MxDashedNote` get their own tests,
  goldens and TalkBack labels. A bar reads, for example, "Sunday: 17 cards, 5 learning,
  12 reviewing".

## 8. Documents

- The new detail file `docs/shared/ui/screen-handoff/22-progress.md`, with each
  deviation (D1, D2, the A1/A2/A3/E2 states, loading).
- Updates:
  - row 22 of the screen handoff index;
  - screen 22 in `docs/shared/ui/screen-state-checklist.md`;
  - UI-base §9 rows from 130 on (the next free rows on `master` at #91);
  - the new `docs/features/progress/ui.md`;
  - the `code:` of UC-PROGRESS-001 and UC-PROGRESS-002;
  - `wbs_FE.md`: FE-A9 done, which closes V8.0;
  - `docs/_generated/`.
- The kit captures of screen 22 and its entry in `tools/design/screen_states.json`
  land with this spec.

## 9. Plans

One plan of about five tasks:

1. The `streak` colour, `MxStackedDayBars` and `MxDashedNote`.
2. The providers and the range.
3. The library level.
4. A deck's level and the route.
5. The documents.

## 10. Out of scope

- The deck list's mastery display and its "progress" sort (still blocked; package 4
  D1).
- Every metric of BR-PROGRESS-010.
- Deep links from outside the app to `/progress/:deckId`: the route works, and nothing
  more is added for it.

## 11. Risks and rollback

- **Two new shared widgets and a theme colour.** They are additive, with no existing
  consumer to break. A rollback removes them together with the screen.
- **Live refresh.** A skeleton that flashes on every write would break BR-PROGRESS-018.
  D8 has a test that fails if the skeleton shows after the first emission.
- **Text scale 2 in Vietnamese.**
  - The two streak tiles may not fit side by side; the audit decides, and they stack
    the way `ThemeChoiceCardWidget` does.
  - The seven bar labels are single narrow weekdays.
