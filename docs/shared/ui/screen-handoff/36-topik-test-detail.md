<!-- Hand-written screen record. -->

# 36 · TOPIK test detail

One test's progress and history, and the door to a new attempt (UC-TOPIK-002, BR-TOPIK-011,
BR-TOPIK-018, BR-TOPIK-020, BR-TOPIK-021). Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §6.1, §6.2, §8.

## Entry points

- A row on screen 35.
- Back from 38 or 39 when they were opened from here.
- Deep link `/study/topik/test/:testId` (Study branch).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | The Korean title, one line, with "{Level} · {Section}" as subtitle. |
| Switch | `MxSegmentedTray` | Overview · History. |
| Overall Progress | `MxCard` | A 2×2 grid of `MxStatTile`s: Accuracy, Best, Average, "{completed} / {sessions}" Completed; a meta line "Last activity {ago} · {total time}"; `MxNote.hint` "Scores use completed tests only". No attempt: the card becomes an `MxEmptyState` (primary) "No attempts yet" with "Start" (BR-TOPIK-020). |
| Recent attempts | `MxListSectionHeader` + `MxCard` of `MxListRow`s | At most five: "#{n}", date and time, "{score} / {max}" and duration; an in-progress row reads "In progress" and continues the attempt. |
| History | `MxCard` of `MxListRow`s | Every attempt, newest first: "#{n}" · `MxBadge` Completed or In progress · date and time · "{correct}/{count}" · duration; actions small `MxButton`s "Summary" and "Review" (completed) or "Continue" (in progress); a trailing delete `MxIconButton` → `showMxConfirm`. |
| Start | `MxFab` "+" | Starts an attempt; with one in progress, an `MxDialog`: "Continue" (primary) or "Start new", which asks once more before it deletes the attempt in progress (BR-TOPIK-011). Absent while loading and on error (The Content Gate Rule). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| overview | `topik_detail_overview_light.png` | `topik_detail_overview_dark.png` | Attempts in both statuses; Overall Progress filled. |
| overviewEmpty | `topik_detail_overview_empty_light.png` | `topik_detail_overview_empty_dark.png` | No attempt: the empty card with Start. |
| history | `topik_detail_history_light.png` | `topik_detail_history_dark.png` | Every attempt with its actions. |
| historyEmpty | `topik_detail_history_empty_light.png` | `topik_detail_history_empty_dark.png` | "No attempts yet". |
| deleteConfirm | `topik_detail_delete_light.png` | `topik_detail_delete_dark.png` | `showMxConfirm` over History. |
| continueOrNew | `topik_detail_continue_light.png` | `topik_detail_continue_dark.png` | The Continue or Start new dialog. |
| testMissing | `topik_detail_missing_light.png` | `topik_detail_missing_dark.png` | Deep link to an unknown or invalid test: neutral `MxEmptyState` with "Back to tests"; no Retry, no FAB (UC-TOPIK-002 E1). |
| loading | `topik_detail_loading_light.png` | `topik_detail_loading_dark.png` | Skeletons; no FAB. |
| error | `topik_detail_error_light.png` | `topik_detail_error_dark.png` | `MxErrorState` with Retry; no FAB. |

**Not built yet (status `shaped`).** Goldens are the planned names under `test/features/topik/presentation/goldens/`; every transition's evidence is the rule it implements and the widget or controller test the screen's plan adds. Each row turns `VERIFIED` only with an executed test.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| overview | tap History | history | UC-TOPIK-002 step 2 |
| overviewEmpty / overview | FAB, no attempt in progress | 37 (new attempt) | UC-TOPIK-003 step 1 |
| overview / history | FAB, an attempt in progress | continueOrNew | BR-TOPIK-011 |
| continueOrNew | Continue | 37 at its current question | BR-TOPIK-011 |
| continueOrNew | Start new, confirmed | 37 (new attempt); the old one deleted in one transaction | BR-TOPIK-011 |
| history | delete, confirmed | history without the row; numbers and Overall Progress recomputed | BR-TOPIK-018, BR-TOPIK-021 |
| deleteConfirm | Cancel | history unchanged | UC-TOPIK-002 A4 |
| history | delete fails | history unchanged + snackbar, nothing was lost | UC-TOPIK-002 E3 |
| any loaded | attempt synced from another device | rows and figures update | UC-TOPIK-002 A3 |
| any loaded | account switched | overviewEmpty, then synced attempts arrive | UC-TOPIK-002 A5, BR-TOPIK-027 |
| history | Summary / Review / Continue | 38 / 39 / 37 | UC-TOPIK-002 step 3 |
| loading | test unknown | testMissing | UC-TOPIK-002 E1 |

## Rulings

- **Brief 2026-10-15:** Overview and History are an `MxSegmentedTray`, not bottom tabs; Words (Phase B) joins the tray.
- **Brief 2026-10-15:** the carousel of the reference app is dropped while there is one card (Overall Progress); Score Trend and Needs Review (Phase B) bring it back as stacked cards first.
- One number per element: Best and Average are tiles; the row repeats a score only as that attempt's own.

## Copy

- Tray: "Overview" · "History".
- Overall Progress: "Accuracy" · "Best" · "Average" · "Completed" · "Last activity {ago} · {duration}" · "Scores use completed tests only".
- Empty: "No attempts yet" · "Start" · "Each attempt is saved as you answer."
- Recent: "Recent attempts" · "#{n}" · "In progress" · "{score} / {max}".
- History: "Completed" · "In progress" · "Summary" · "Review" · "Continue" · "Delete attempt".
- Delete confirm: "Delete this attempt?" · "Its answers are deleted too. This can't be undone." · "Delete" · "Cancel".
- Continue dialog: "You have an attempt in progress" · "Continue where you left off, or start again." · "Continue" · "Start new"; then "Start a new attempt?" · "The attempt in progress and its answers are deleted." · "Start new" · "Cancel".
- Missing: "This test isn't available" · "Back to tests".
