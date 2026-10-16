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
| Overall Progress | `MxCard` | A 3×2 grid of boxed `MxStatTile`s: Accuracy · Completion, Best · Average, Sessions · Completed (BR-TOPIK-020's six figures); a meta line "Last activity {ago} · {total time}"; `MxNote.hint` "Scores use completed tests only". No attempt: the card becomes an `MxEmptyState` (primary) "No attempts yet" with "Start" (BR-TOPIK-020). |
| Recent attempts | `MxListSectionHeader` + `MxCard` of `MxListRow`s | At most five: "#{n}", date and time, "{score} / {max}", "{correct} / {count} correct" and duration (BR-TOPIK-021); an in-progress row reads "In progress" and continues the attempt. |
| History | `MxListSectionHeader` "{n} attempts" + `MxCard` of `MxListRow`s | Every attempt, newest first: "#{n}" · `MxBadge` Completed or In progress · date and time · "{score} / {max}" · "{correct} / {count} correct" · duration (BR-TOPIK-021); actions small `MxButton`s "Summary" and "Review" (completed) or "Continue" (in progress); a trailing delete `MxIconButton` → `showMxConfirm`. |
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
| error | `topik_detail_error_light.png` | `topik_detail_error_dark.png` | `MxErrorState` with Retry; no FAB and the generic title, also when the error follows loaded data. |

**Built (plan 6a, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_test_detail_screen_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| overview | tap History | history | UC-TOPIK-002 step 2. VERIFIED `topik_test_detail_screen_test.dart::History: delete asks, then removes the row, renumbers the later ones and recomputes the progress (BR-TOPIK-018, -021)` |
| overviewEmpty / overview | FAB or Start, no attempt in progress | 37 (new attempt) | UC-TOPIK-003 step 1. VERIFIED `::no attempt: the empty card starts one, and there is no FAB (BR-TOPIK-020, critique F2)`, `::a second tap while starting opens one attempt` |
| overview / history | FAB, an attempt in progress | continueOrNew | BR-TOPIK-011. VERIFIED `::the FAB with an attempt in progress asks; Continue opens it (BR-TOPIK-011)` |
| continueOrNew | Continue | 37 at its current question | BR-TOPIK-011. VERIFIED same test |
| continueOrNew | dismissed | no change | BR-TOPIK-011. VERIFIED `::the dialog dismissed changes nothing` |
| continueOrNew | Start new, confirmed | 37 (new attempt); the old one deleted in one transaction | BR-TOPIK-011. VERIFIED `::Start new asks again, then replaces the attempt in progress` |
| history | delete, confirmed | history without the row; numbers and Overall Progress recomputed | BR-TOPIK-018, BR-TOPIK-021. VERIFIED `::History: delete asks, then removes the row, renumbers the later ones and recomputes the progress (BR-TOPIK-018, -021)` (deletes the middle of three: the old #3 reads #2, Completed goes 3 / 3 → 2 / 2) |
| deleteConfirm | Cancel | history unchanged | UC-TOPIK-002 A4. VERIFIED same test |
| history | delete fails | history unchanged + snackbar, nothing was lost | UC-TOPIK-002 E3. VERIFIED `::a delete that fails keeps the row and says nothing was lost (UC-TOPIK-002 E3)` |
| any loaded | attempt synced from another device | rows and figures update | UC-TOPIK-002 A3. VERIFIED at the stream (`topik_use_cases_test.dart::the catalog and the detail follow every later write`); the screen re-renders from it (the delete test above) |
| any loaded | account switched | overviewEmpty, then synced attempts arrive | UC-TOPIK-002 A5, BR-TOPIK-027. UNVERIFIED on this screen: the switch clears the store (`LocalDataReset`, plan 2) and the stream re-emits empty; no screen test drives an account switch |
| history | Summary / Review / Continue | 38 / 39 / 37 | UC-TOPIK-002 step 3. VERIFIED `::History: Summary, Review and Continue open their screens` (the routes of 37–39 come with plans 6b, 6c) |
| overview | a recent row | 38 when completed, 37 when in progress | BR-TOPIK-021. VERIFIED `::a recent row opens Summary when completed and the attempt when in progress (BR-TOPIK-021)` |
| overview / history | FAB, the start refused (the test left, or an attempt in progress appeared) | same state + snackbar naming why | BR-TOPIK-011, BR-TOPIK-019. VERIFIED `::a start refused because the test left says so (BR-TOPIK-019)` |
| loading / any loaded | the read fails | error: no FAB, the generic title | The Content Gate Rule. VERIFIED `::an error after the test loaded drops the FAB and the title (States: error, The Content Gate Rule)` |
| error | Retry | loading, then the state the read gives | UC-TOPIK-002 E3. VERIFIED `::error: Retry reads the test again (States: error to loaded)` |
| loading | test unknown | testMissing | UC-TOPIK-002 E1. VERIFIED `::an unknown test: missing, with Back to tests and no FAB (UC-TOPIK-002 E1)`, `topik_routes_test.dart::deep links: …` |

## Rulings

- **Brief 2026-10-15:** Overview and History are an `MxSegmentedTray`, not bottom tabs; Words (Phase B) joins the tray.
- **Brief 2026-10-15:** the carousel of the reference app is dropped while there is one card (Overall Progress); Score Trend and Needs Review (Phase B) bring it back as stacked cards first.
- One number per element: Best and Average are tiles; the row repeats a score only as that attempt's own. A completed row still shows both its score and its correct answers (BR-TOPIK-021, spec §6.2), the second spelled "{correct} / {count} correct" so the two never read as the same figure (final review I1).
- **Plan 6a (2026-10-15):** a History row is three lines: "#n" with its status badge (Completed in `success`, In progress neutral), then when · "{score} / {max}" · "{correct} / {count} correct" · how long, then its actions as small outline buttons and the delete button at the end (critique F1).
- **Plan 6a:** on an empty Overview the empty state's Start is the one action; the FAB is absent there and present on History, empty or not (critique F2).
- **Plan 6a:** Best and Average are the score alone; Accuracy is a percent; a figure with nothing to show is a dash (critique F8). A completed recent attempt opens its Summary; one in progress continues.
- **Plan 6a:** `testMissing` hides History, as above (owner question Q-P4-4 asks whether a removed test keeps it).
- **Owner 2026-10-16 (Q-P6-2):** the level and section line is `MxAppBar.subtitle`, read with the title in one heading node that names the route.
- **Owner 2026-10-16 (Q-P6-5):** a figure with nothing to show is a dash on screen and reads "None yet" to TalkBack (`MxStatTile.semanticValue`); a bare dash reads "en dash".
- **Q-C-1 (owner, 2026-10-16):** Overall Progress' last activity line ("Last activity 2 days ago · 1h 20m") wraps only between whole terms (`metaLine`) (The Wrap Rule; `lib/l10n/meta_line.dart`).
- **Wireframe pass (owner, 2026-10-16):** Overall Progress shows Completion and Sessions as figures of their own, as BR-TOPIK-020 lists them (it had folded them into "{completed} / {sessions}"); History is headed by its count, as Overview's lists are. The wireframe's accuracy ring, Score Trend, Needs Review, Bookmarks, Notes and the Words tab are Phase B (ADR-023) and stay absent; its bottom tabs stay the segmented switch.

## Copy

- Tray: "Overview" · "History".
- Overall Progress: "Accuracy" · "Best" · "Average" · "Completed" · "Last activity {ago} · {duration}" · "Scores use completed tests only"; TalkBack "None yet" for a dash.
- Empty: "No attempts yet" · "Start" · "Each attempt is saved as you answer."
- Recent: "Recent attempts" · "#{n}" · "In progress" · "{score} / {max}" · "{correct} / {count} correct".
- History: "Completed" · "In progress" · "Summary" · "Review" · "Continue" · "Delete attempt".
- Delete confirm: "Delete this attempt?" · "Its answers are deleted too. This can't be undone." · "Delete" · "Cancel".
- Continue dialog: "You have an attempt in progress" · "Continue where you left off, or start again." · "Continue" · "Start new"; then "Start a new attempt?" · "The attempt in progress and its answers are deleted." · "Start new" · "Cancel".
- Missing: "This test isn't available" · "Back to tests".
- Error: "Couldn't load this test" · "Nothing was lost. Try again." · "Retry".
- Refusals (snackbar): "This test isn't available" · "This attempt isn't here any more" · "That didn't go through. Nothing was lost."
