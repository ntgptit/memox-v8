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

**Built (plan 6a, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_home_screen_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | catalog read | loaded / noTests | UC-TOPIK-001 step 1; BR-TOPIK-008. VERIFIED `topik_home_screen_test.dart::each level with its count; a tap opens it`, `::a level with no valid test says so and is not a button (BR-TOPIK-008)` |
| loading | read fails | error | UC-TOPIK-001 E1. VERIFIED `::a failed read says nothing was lost; Retry reads again` |
| error | Retry | loading | UC-TOPIK-001 E1. VERIFIED same test |
| loaded | tap a level with tests | 35 (that level, Reading) | UC-TOPIK-001 step 2. VERIFIED `test/app/topik_routes_test.dart::Study home → TOPIK → a level → a test under the tab bar; Back climbs one level each time` |
| loaded | tap a level without tests | no change (no tap target) | BR-TOPIK-008. VERIFIED `::a level with no valid test says so and is not a button (BR-TOPIK-008)` |
| any | Back | 13 | navigation. VERIFIED `topik_routes_test.dart::Study home → TOPIK → …` |
| any | language changes | same state, relabelled | UC-TOPIK-003 A4. VERIFIED `::in Vietnamese, the same screen relabelled (UC-TOPIK-003 A4)` (rendered in vi; a live switch is the app's locale provider, shared with every screen) |

## Rulings

- **Brief 2026-10-15:** the page is a plain `MxSection`; no hero, since nothing here is a decision.
- **Brief 2026-10-15:** the Korean exam name is a subtitle line of the app bar, so the title stays on one line (The One Line Rule).
- **Plan 6a (2026-10-15):** the meta line is terms joined so it breaks only between them (The Wrap Rule): grades ("Levels 3–6") and sections ("Reading, Listening") are separate keys.
- **Plan 6a:** a level without tests is information, not a disabled control: no chevron, no tap, not dimmed (critique F5).
- **Plan 6a:** the level glyph is `AppIcons.fileText` (Q-P6-3).
- **Owner 2026-10-16 (Q-P6-2):** the Korean subtitle is `MxAppBar.subtitle`, read with the title in one heading node that names the route; the TOPIK-local title widget is gone.

## Copy

- App bar: "TOPIK" · "한국어능력시험".
- Section: "Practice".
- Rows: "TOPIK I" · "Levels 1–2 · Reading, Listening · {n} tests" · "TOPIK II" · "Levels 3–6 · Reading, Listening · {n} tests" · "No tests yet".
- Error: "Couldn't load the tests" · "Nothing was lost. Try again." · "Try again".
