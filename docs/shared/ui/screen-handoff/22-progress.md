<!-- Hand-written screen record. -->

# 22 · Progress

The Progress tab: what was studied today and over the last seven days, the current
streak, and how much each deck was studied over 7 or 30 days, level by level down the
deck tree. It only reads. UC-PROGRESS-001, UC-PROGRESS-002; BR-PROGRESS-001…018; spec
[2026-09-27-progress-ui-design.md](../../../superpowers/specs/2026-09-27-progress-ui-design.md).

## Entry points

- **The bottom navigation:** the Progress tab opens the library level, `/progress`.
- **A deck row:** opens that deck's level, `/progress/:deckId`, under the tab bar (D5).
  Each row pushes one level, and Back climbs one.
- **The breadcrumb of a deck's level:** "Progress" returns to the library level; a deck
  above returns to its level.

## Layout

The library level, top to bottom:

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (screen) | "Progress". |
| Today | `MxCard` | The overline "Today", the day's card-days, and "{l} learning · {r} reviewing · a card counts once per day", "No cards studied yet today" or "Nothing studied yet". Below, `MxStackedDayBars`: the last seven days, learning over reviewing, today at full strength, labelled by narrow weekday and "Today", with the legend; a dashed guide at the fullest day carries its count, and a tap on a day shows its numbers in a tooltip above it. |
| Streak | `MxCard` | One tile, "Current" (the flame in `warning` on its tint; at 0 days the tile goes to the neutral `MxIconTile` tone; "{n} days", and "includes today", "held from yesterday" or "no study yesterday"); Today's figure is the Today card's alone (critique 2026-09-30). A held streak adds "Study one card today and the streak continues at {n}."; a lost one "The streak ended on {day}. It starts again with the next card you study." |
| Range | `MxSegmentedTray` (wide) | "Last 7 days" · "Last 30 days", directly above the list (D10). |
| List | `MxListSectionHeader` + `MxCard` + `MxListRow`s | "By deck" (the range segment above states the range; critique 2026-09-30 part 3b); the total row "All decks" (D2), then a row per root deck: the name, then "{n} cards · {d} active days" and "Card-days: {l} learning · {r} reviewing" (learning in `warning`, reviewing in `primary`), and a chevron on a deck row, none on the total (critique 2026-09-30 part 3d-1, D3). An idle deck reads "No activity in this range", nothing dimmed (D11). |
| Note | `MxNote` | A quiet range: "Nothing studied in the last 7 days. Switch to Last 30 days to see older study." (at 30 days, the first sentence only). |
| Footer line | text | "Read-only · resets change nothing here" (Today states the once-a-day rule; critique 2026-09-30 part 3b). |

From a content width of 672 (`MxTwoColumns.minWidth`) the library level runs in two
columns: Today and Streak on the start side, Range and the list on the end side, each
column starting at the top. Below it they stack in that order. Never studied, the end
side is empty and Today and Streak keep the full width.

A deck's level: the app bar with Back and the deck's name, the breadcrumb "Progress › …
› {deck}", the range at the top, "Sub-decks", the total row "Whole deck",
a row per direct child, and the footer line. A deck with no children adds "This deck
holds its cards directly, so the total above is all of it."

Switching the range reads nothing (BR-PROGRESS-003). The numbers follow every write and
every local midnight with no skeleton once shown (BR-PROGRESS-018, D8).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `progress_week_light.png` | `progress_week_dark.png` | Last 7 days, the default range. The range sits above the list (D10); one total row, no header totals (D2). |
| month | `progress_month_light.png` | `progress_month_dark.png` | Last 30 days. As loaded. |
| held | `progress_held_light.png` | `progress_held_dark.png` | — |
| lost | `progress_lost_light.png` | `progress_lost_dark.png` | The note names the weekday within six days, else a short date. |
| deck | `deck_progress_deck_light.png` | `deck_progress_deck_dark.png` | "Whole deck" total row (D2). |
| never | `progress_never_light.png` | `progress_never_dark.png` | "Start studying" (primary, the only action) under Today's placeholder opens the Study tab (UC-PROGRESS-001 A2); no range and no by-deck list, which would read 0 everywhere (critique 2026-09-30). |
| loading | `progress_loading_light.png` | `progress_loading_dark.png` | The screen's own skeleton: Today card, Streak card, deck-list card; deck progress shows the deck-list card under its range control (UI-base row 125, part 3d-2). |
| error | `progress_error_light.png` | `progress_error_dark.png` | With Retry, under the alert glyph: a local read failed, not the network (critique 2026-09-30). The body follows the failure: a `Failure` shows `l10n.failure(error)` (a busy database: "Nothing was lost. The data is busy, so try again."), anything else "Your study history is safe on this device. Try again in a moment." (`progress_screen.dart`; UC-PROGRESS-001 E1, BR-CORE-005). An error after content was shown replaces the whole screen the same way, and the range goes back to 7 days once Retry shows content (see Transitions). |
| tooltip | none | none | A day's tooltip shown over the Today card's figure and line, above the tapped day: the day's words in ForUI's tooltip look. VERIFIED without a golden by `mx_stacked_day_bars_test.dart::a tap on a day shows its words; …`; its look on a throwaway golden, light and dark (2026-10-19). |
| deck error | none | none | The same `MxErrorState` on a deck's level, in place of the range and the list, with the breadcrumb and Back kept only once a level has been read (`deck_progress_screen.dart`). VERIFIED without a golden by `deck_progress_screen_test.dart::a failed read shows the error with Retry (E1)`. |
| quiet range | `progress_quiet_light.png` | `progress_quiet_dark.png` | (UC-PROGRESS-002 A3) the note under the list. |
| no decks | `progress_no_decks_light.png` | `progress_no_decks_dark.png` | (A2) only "No decks yet · Create a deck in the Library and its progress appears here". No range, no total, no button. |
| no sub-decks | `deck_progress_leaf_light.png` | `deck_progress_leaf_dark.png` | (A1) the total row and its note. |
| deck gone | `deck_progress_gone_light.png` | `deck_progress_gone_dark.png` | (E2) "This deck is no longer here" with Back, no Retry, in the neutral tone (UI-base row 129; owner 2026-10-08). |

Goldens: `test/features/progress/presentation/goldens/progress_{week,month,held,lost,never,quiet,no_decks,loading,error}_{light,dark}.png` and `deck_progress_{deck,leaf,gone}_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the read lands | loaded, never, or no decks, by the data | VERIFIED `progress_screen_test.dart::Today, the seven bars, the streak, and a row per root deck with its four numbers under a total (UC-PROGRESS-001 step 4, D2)`, `::never studied: the places of the chart and the streak, no by-deck list of zeros, and Start studying opens the Study tab (UC-PROGRESS-001 A2, D1; critique 2026-09-30)`, `::no deck: only the empty state, no range, no total (UC-PROGRESS-002 A2)`; loading is `::loading is labelled for TalkBack` |
| loading | the read fails | error (body by the kind of failure) | VERIFIED `::a failed read shows the error; Retry reads again (UC-PROGRESS-001 E1)`, `::a failed read says what failed, by the kind of failure (UC-PROGRESS-001 E1, BR-CORE-005)` |
| error | Retry | the read runs again; the Retry spins while it reloads; then loaded or error again | VERIFIED `::a failed read shows the error; Retry reads again (UC-PROGRESS-001 E1)` (a second read, the error again); `progress_providers_test.dart::a failed read is an error; Retry reads again, once (UC-PROGRESS-001 E1, E2)`; the spin on the tab is `UNVERIFIED (code read)` (`isRetrying: isLoading`), on a deck's level VERIFIED `deck_progress_screen_test.dart::while a Retry reloads, the error stays and its Retry spins` |
| loaded | the stream errors after content was shown | error replaces the whole screen (Today, Streak, range and list) | `UNVERIFIED (code read)`: `AsyncError` is matched before the value in `progress_screen.dart`, so the earlier snapshot is not kept |
| error (after content) | Retry, and the read succeeds | loaded again with the range back at 7 days, even if 30 was chosen | `UNVERIFIED (code read)`: while the error shows, no widget watches `progressRangeChoiceProvider`, an auto-dispose provider whose `build` returns the week (`progress_range_provider.dart`); a deck's level still on the stack keeps watching it, so its range survives. The default and the one-choice rule are VERIFIED `progress_providers_test.dart::the range starts at 7 days and is one choice for every level (D4)` |
| loaded | a new answer is written, or local midnight passes | the numbers change in place, no skeleton | VERIFIED `progress_screen_test.dart::a new answer updates the numbers with no skeleton (D8, UC-PROGRESS-001 A3)`; `progress_providers_test.dart::a new answer updates the library level; nothing else is read`; midnight is `UNVERIFIED (code read)` |
| loaded / month | tap Last 30 days / Last 7 days | month / loaded: the numbers and the order switch at once, nothing is read | VERIFIED `::Last 30 days switches the numbers and the order at once, with no loading; the idle deck keeps full contrast (UC-PROGRESS-002 step 4, D11)` |
| loaded | the range is 7 days and nothing was studied in it | quiet range: the note under the list | VERIFIED `::a quiet week says so and points to 30 days; at 30 days only the fact (UC-PROGRESS-002 A3)` |
| loaded | the streak is held or lost | held / lost: the note under the tile | VERIFIED `::with nothing today but yesterday, the streak holds and says where it goes next (UC-PROGRESS-001 A1)`, `::a lost streak names the day it ended`; `progress_lost_streak_day_test.dart::six calendar days back is a weekday, seven is a date, across a spring clock change` |
| loaded / tooltip | tap a day's column in the chart | tooltip / loaded: a tooltip above that day with its words ("Sunday: 17 cards, 5 learning, 12 reviewing"); a tap on another day moves it; a second tap on the same day, or a tap anywhere outside the chart, hides it | VERIFIED `test/shared/widgets/mx_stacked_day_bars_test.dart::a tap on a day shows its words; a tap on another day, a second tap or a tap outside the chart moves or hides them`; its look was checked on a throwaway golden, light and dark (2026-10-19) |
| loaded / tooltip | the week's numbers change (a new answer) | loaded / tooltip: the bars ease to the new heights, at once under Remove animations; a tooltip shown keeps its day, and a new day (the week slides at local midnight) clears it; a theme change redraws at once | VERIFIED `mx_stacked_day_bars_test.dart::new numbers ease in; a theme change, a tap, or the platform removing animations draw at once`, `::a tap on a day shows its words; a tap on another day, a second tap or a tap outside the chart moves or hides them` |
| never | tap Start studying | the Study tab | VERIFIED the never-studied test above |
| loaded | tap a deck row | that deck's level, under the tab bar, keeping the range; Back climbs one level | VERIFIED `progress_screen_test.dart::a row opens its deck; the total is not a button`; `test/app/progress_routes_test.dart::a row opens its level under the tab bar, keeping the range; Back climbs one level (D4, D5)` |
| deck | tap a child row, or a breadcrumb segment | the child's level / that level (null is Progress) | VERIFIED `deck_progress_screen_test.dart::the deck's path, its whole-deck total and a row per child; a row opens the child, a segment its level (steps 1, 5; D2)` |
| deck | a deck with no child | no sub-decks: the total and "This deck holds its cards directly…" | VERIFIED `::a deck with no children keeps its total and says it is all of it (A1)` |
| deck | open a deck that is gone | deck gone: Back only, no Retry | VERIFIED `::a deck gone to the Trash offers Back only, no Retry (E2)` |
| deck | the deck goes to the Trash while open | deck gone, with no error in between | VERIFIED `::a deck moved to the Trash while its level is open turns into the gone state, with no error in between (E2, BR-PROGRESS-008)` |
| deck | the read fails, then Retry | deck error, then the level | VERIFIED `::a failed read shows the error with Retry (E1)`, `::a failed read says what failed, by the kind of failure, without its cause (UC-PROGRESS-002 E1, BR-CORE-005)` |
| any level | the account is switched, or a sync lands mid-way | the snapshot follows the local data | `UNVERIFIED (code read)`: the screens read local streams only; no test switches the account here |

## Rulings

- **UC-PROGRESS-001 step 4, UC-PROGRESS-002 step 1, D10:** the range tray sits directly above the list it changes.
- **BR-PROGRESS-001, D2:** the list has a total row with the four numbers, no header totals.
- **Critique P2, D11:** an idle deck row keeps full contrast and reads "No activity in this range" (its 0 went with the trailing count, critique 2026-09-30 part 3d-1).
- **UC-PROGRESS-001 A2, D1:** never studied shows the placeholders plus "Start studying" to the Study tab.
- **UI-base row 125:** loading shows the screen's own skeleton (Today, Streak and deck-list cards), not generic rows (part 3d-2).
- **UC-PROGRESS-002 A1–A3, E2:** quiet range, no deck, leaf and gone states are built from the UC.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the Today label and the streak labels are eyebrows; the list headers stay section labels.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** a deck row's meta reads "{n} cards · {d} active days" then "Card-days: {l} learning · {r} reviewing", and it ends in a chevron; the total row has none; the never-studied "Start studying" is primary (D3).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** loading shows the screen's own skeleton, a Today card, a Streak card and a deck-list card (`MxSkeletonPulse`, `MxCard`, `MxSkeleton`, `MxSkeletonRow`); deck progress keeps its range control and shows the deck-list card.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** every day's bars draw at full strength, reviewing in primary and learning in `statusLearning` (Day's learning bars on the card are a recorded contrast exception, owner 2026-10-10); Today is told by its bold label (F5).
- **Critique 2026-10-19 (owner: fl_chart pilot, ADR-026):** the seven bars are drawn with fl_chart; a dashed guide at the fullest day carries its count, a tap on a day shows its numbers in a tooltip, the parts are parted by a hairline of the ground under the chart, a day's height stays its share of the fullest day and a part with any cards keeps `sizeTrack` out of the larger part, the stack rounds only its outer corners, and the legend dot is `space8`. The reviewing fill in `primary` reads 2.7:1 on the dark card and spends the accent; the owner chose to change it in the theme, as its own change after this one.
- **Owner 2026-10-16 (Q-P6-4):** a row's "N cards · N active days" and its learning · reviewing card-days wrap only between whole terms (`lib/l10n/meta_line.dart`).
- **Q-C-1 (owner, 2026-10-16):** Today's line and the footer keep each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

"Progress" · "Today" · "{l} learning · {r} reviewing · a card counts once per day" · "No
cards studied yet today" · "Nothing studied yet" · "Learning" · "Reviewing" · "Streak" ·
"Current" · "{n} days" · "includes today" · "held from yesterday" · "no study yesterday" ·
"{n} cards" · "counted once each" · "nothing yet" · "Study one card today and the streak
continues at {n}." · "The streak ended on {day}. It starts again with the next card you
study." · "Your last seven days appear here once you study. Browsing cards does not
count." · "A streak starts with your first study day." · "Start studying" · "Last 7 days"
· "Last 30 days" · "By deck" · "Sub-decks" · "All decks" ·
"Whole deck" · "{d} active days" · "{l} learning" · "{r} reviewing" · "cards" · "No
activity in this range" · "Nothing studied in the last 7 days. Switch to Last 30 days to
see older study." · "No decks yet" · "Create a deck in the Library and its progress
appears here." · "This deck holds its cards directly, so the total above is all of it." ·
"Read-only · resets change nothing here" · "Couldn't summarise your progress" · on a `Failure` its message by kind, e.g. "Nothing was lost. The data is busy, so try again." · otherwise "Your study history is safe on this device.
Try again in a moment."
