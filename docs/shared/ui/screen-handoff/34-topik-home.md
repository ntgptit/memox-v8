<!-- Hand-written screen record. -->

# 34 · TOPIK home

The landing page of TOPIK practice (UC-TOPIK-001, [ADR-023](../../decisions/ADR-023-luyen-de-topik.md)):
the two exams, each with the number of tests the bundled content holds. Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §8,
brief of 2026-10-15.

## Entry points

- The Practice row on Study home (screen 13).
- Deep link `/study/topik` (Study branch; the tab bar stays).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | "TOPIK" with "한국어능력시험" as its Korean subtitle line; Back to Study home. |
| Practice | `MxSection` of two `MxListRow`s in one `MxCard` | Leading `MxIconTile` (tinted); title "TOPIK I" / "TOPIK II"; meta "Levels 1–2 · Reading, Listening · {n} tests" / "Levels 3–6 · Reading, Listening · {n} tests"; a chevron. A level with no valid test keeps its row with the meta "No tests yet" and no chevron and no tap target (the content gate counts only valid tests, BR-TOPIK-008). |

Level drills and Simulated exams are absent until they exist (index rule: controls without their feature are hidden).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `topik_home_loaded_light.png` | `topik_home_loaded_dark.png` | Both levels with their counts. |
| noTests | `topik_home_no_tests_light.png` | `topik_home_no_tests_dark.png` | No valid test in the content: both rows read "No tests yet"; nothing is an error. |
| loading | `topik_home_loading_light.png` | `topik_home_loading_dark.png` | `MxSkeletonRow` ×2 in the card. |
| error | `topik_home_error_light.png` | `topik_home_error_dark.png` | `MxErrorState` with Retry; the body says nothing was lost. |

**Not built yet (status `shaped`).** Goldens are the planned names under `test/features/topik/presentation/goldens/`; every transition's evidence is the rule it implements and the widget or controller test the screen's plan adds. Each row turns `VERIFIED` only with an executed test.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | catalog read | loaded / noTests | UC-TOPIK-001 step 1; BR-TOPIK-008 |
| loading | read fails | error | UC-TOPIK-001 E1 |
| error | Retry | loading | UC-TOPIK-001 E1 |
| loaded | tap a level with tests | 35 (that level, Reading) | UC-TOPIK-001 step 2 |
| loaded | tap a level without tests | no change (no tap target) | BR-TOPIK-008 |
| any | Back | 13 | navigation |
| any | language changes | same state, relabelled | UC-TOPIK-003 A4 (applies to every TOPIK screen) |

## Rulings

- **Brief 2026-10-15:** the page is a plain `MxSection`; no hero, since nothing here is a decision.
- **Brief 2026-10-15:** the Korean exam name is a subtitle line of the app bar, so the title stays on one line (The One Line Rule).

## Copy

- App bar: "TOPIK" · "한국어능력시험".
- Section: "Practice".
- Rows: "TOPIK I" · "Levels 1–2 · Reading, Listening · {n} tests" · "TOPIK II" · "Levels 3–6 · Reading, Listening · {n} tests" · "No tests yet".
- Error: "Couldn't load the tests" · "Nothing was lost. Try again." · "Try again".
