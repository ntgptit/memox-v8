<!-- Hand-written screen record. -->

# 35 · TOPIK test list

The published tests of one level and section, with the user's status on each (UC-TOPIK-001,
BR-TOPIK-009, BR-TOPIK-022). Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §6.3, §8.

## Entry points

- A level row on screen 34 (opens Reading).
- Deep link `/study/topik/:level` (Study branch).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | "TOPIK I" / "TOPIK II"; Back to 34. |
| Section switch | `MxSegmentedTray` | Reading · Listening (Writing comes with Phase C). The prompt's bottom tabs are not used: the app's bottom bar already holds the destinations. |
| Header | `MxCard` | Leading `MxIconTile` (book or headphones), "{n} tests" in `titleMedium`, one line saying what the section is; trailing sort `MxChipTrigger` "Newest round ▾" opening an `MxBottomSheet` of three `MxOptionRow`s. |
| Rows | `MxCard` of `MxListRow`s | Leading `MxBadge` "#96"; title = the Korean title, one line; meta line 1 = the derived content tags (BR-TOPIK-009) joined by " · "; meta line 2 = the status: "Not started", "In progress", "Best {score} · {n} attempts" (both when both hold, BR-TOPIK-022); a chevron. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| reading | `topik_list_reading_light.png` | `topik_list_reading_dark.png` | Reading tests, newest round first. |
| listening | `topik_list_listening_light.png` | `topik_list_listening_dark.png` | Listening tests. |
| withStatus | `topik_list_status_light.png` | `topik_list_status_dark.png` | Rows in each status: not started, in progress, best with count, in progress and best. |
| sortSheet | `topik_list_sort_light.png` | `topik_list_sort_dark.png` | The sort sheet open. |
| empty | `topik_list_empty_light.png` | `topik_list_empty_dark.png` | No valid test for this section: neutral `MxEmptyState`, "No tests yet for this section"; no Retry (A1). |
| loading | `topik_list_loading_light.png` | `topik_list_loading_dark.png` | Header skeleton and `MxSkeletonRow`s. |
| error | `topik_list_error_light.png` | `topik_list_error_dark.png` | `MxErrorState` with Retry. |

**Built (plan 6a, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_test_list_screen_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| reading | tap Listening | listening | UC-TOPIK-001 step 3. VERIFIED `topik_test_list_screen_test.dart::Listening shows its tests; the choice is per screen` |
| any loaded | pick a sort | same section, re-sorted | BR-TOPIK-022. VERIFIED `::the sort sheet re-orders the rows` |
| any loaded | attempt submitted, deleted or synced elsewhere | status updates in place | UC-TOPIK-001 A2. VERIFIED for a submit `::a submitted attempt updates the status in place (A2)`; a delete or a sync reaches the same stream (`topik_use_cases_test.dart::the catalog and the detail follow every later write`) |
| any loaded | tap a row | 36 | UC-TOPIK-001 step 5. VERIFIED `::a row opens its test`, `topik_routes_test.dart::Study home → TOPIK → …` |
| loading | read fails | error | UC-TOPIK-001 E1. VERIFIED `::a failed read says nothing was lost; Retry reads again, and the section tray stays` |
| error | Retry | loading | UC-TOPIK-001 E1. VERIFIED same test |
| reading / listening | no valid test | empty | UC-TOPIK-001 A1. VERIFIED `::a section with no test is a calm empty state with no sort (A1, The Content Gate Rule)` |

## Rulings

- **Brief 2026-10-15:** the section switch is `MxSegmentedTray`, as the 7/30 switch on screen 22.
- **Brief 2026-10-15:** the status is the row's second meta line, not a badge: a row states its number once (DESIGN.md, Do's).
- The selected section and sort live in the screen's provider and reset when the screen closes.
- **Plan 6a (2026-10-15):** the header (count and sort) shows only with tests; the section tray stays in every state (The Content Gate Rule, critique F4). The count and the sort share the first line; the description reads full width under them.
- **Plan 6a:** the round badge is neutral (The One Accent Rule); the Korean title is content and may end in an ellipsis (critique F7); tags and status are glued terms (The Wrap Rule).
- **Owner 2026-10-16 (Q-P6-3):** Reading is `AppIcons.book`, Listening `AppIcons.headphones`, in the header and the empty state (they were the stand-ins `fileText` and `speak`).
- **Wireframe pass (owner, 2026-10-16):** nothing missing in scope. The header's "Reading" and "{n} tests" chips repeat the switch and the title; tags stay a meta line (The Wrap Rule); Writing is Phase C.

## Copy

- Tray: "Reading" · "Listening".
- Header: "{n} tests" · "Past papers published by NIIED." · sort "Newest round" · "Oldest round" · "Recent activity".
- Tags: "Explanation" · "Translation" · "Words" · "Grammar" · "Script".
- Status: "Not started" · "In progress" · "Best {score} · {n} attempts".
- Empty: "No tests yet for this section".
