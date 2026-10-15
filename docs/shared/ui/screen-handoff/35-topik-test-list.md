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

**Not built yet (status `shaped`).** Goldens are the planned names under `test/features/topik/presentation/goldens/`; every transition's evidence is the rule it implements and the widget or controller test the screen's plan adds. Each row turns `VERIFIED` only with an executed test.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| reading | tap Listening | listening | UC-TOPIK-001 step 3 |
| any loaded | pick a sort | same section, re-sorted | BR-TOPIK-022 |
| any loaded | attempt submitted, deleted or synced elsewhere | status updates in place | UC-TOPIK-001 A2 |
| any loaded | tap a row | 36 | UC-TOPIK-001 step 5 |
| loading | read fails | error | UC-TOPIK-001 E1 |
| error | Retry | loading | UC-TOPIK-001 E1 |
| reading / listening | no valid test | empty | UC-TOPIK-001 A1 |

## Rulings

- **Brief 2026-10-15:** the section switch is `MxSegmentedTray`, as the 7/30 switch on screen 22.
- **Brief 2026-10-15:** the status is the row's second meta line, not a badge: a row states its number once (DESIGN.md, Do's).
- The selected section and sort live in the screen's provider and reset when the screen closes.

## Copy

- Tray: "Reading" · "Listening".
- Header: "{n} tests" · "Past papers published by NIIED." · sort "Newest round" · "Oldest round" · "Recent activity".
- Tags: "Explanation" · "Translation" · "Words" · "Grammar" · "Script".
- Status: "Not started" · "In progress" · "Best {score} · {n} attempts".
- Empty: "No tests yet for this section".
