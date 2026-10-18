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
| retrying | (no golden) | (no golden) | The error state with Retry spinning (`isRetrying: isLoading` into `MxButton.isLoading`); no skeleton flash, since the error branch comes first. The behaviour (Retry reads again, the error clears) is VERIFIED by `topik_home_screen_test.dart::a failed read says nothing was lost; Retry reads again`; the spinner frame itself is `UNVERIFIED` (no test asserts the spinner, no golden). |
| error after data | (no golden) | (no golden) | The read errors after a value was shown: the `AsyncError` branch wins over the held value and replaces the list with the error state; Retry recovers. `UNVERIFIED (code read)`; no test executes it. VERIFIED (closing acceptance 2026-10-18): `topik/presentation/topik_home_state_coverage_test.dart::error after data: a read that errors after the levels were shown replaces them with the error; Retry brings them back` |

**Built (plan 6a, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_home_screen_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | catalog read | loaded / noTests | UC-TOPIK-001 step 1; BR-TOPIK-008. VERIFIED `topik_home_screen_test.dart::each level with its count; a tap opens it`, `::a level with no valid test says so and is not a button (BR-TOPIK-008)` |
| loading | read fails | error | UC-TOPIK-001 E1. VERIFIED `::a failed read says nothing was lost; Retry reads again`; a `Failure` reads in its own words, never a technical cause: `::a read that fails with a Failure speaks in its own words, never a technical cause (UC-TOPIK-001 E1, BR-CORE-005)` |
| error | Retry | error with Retry spinning, then the state the read gives | UC-TOPIK-001 E1. VERIFIED same test (the error stays up with its retry in progress; no skeleton, as on 38 and 39) |
| loaded | tap a level with tests | 35 (that level, Reading) | UC-TOPIK-001 step 2. VERIFIED `test/app/topik_routes_test.dart::Study home → TOPIK → a level → a test under the tab bar; Back climbs one level each time`. A level whose tests are all Listening still opens Reading, empty (UC-TOPIK-001 step 2; owner question Q-A-1 below) |
| loaded | tap a level without tests | no change (no tap target) | BR-TOPIK-008. VERIFIED `::a level with no valid test says so and is not a button (BR-TOPIK-008)` |
| any | Back | 13 | navigation. VERIFIED `topik_routes_test.dart::Study home → TOPIK → …` |
| loaded | the read errors after data was shown | error | `UNVERIFIED (code read)`: the `AsyncError` branch matches before the held value; recovery is Retry |
| any | language changes | same state, relabelled | UC-TOPIK-003 A4. VERIFIED `::in Vietnamese, the same screen relabelled (UC-TOPIK-003 A4)` (rendered in vi; a live switch is the app's locale provider, shared with every screen) |

## Rulings

- **Brief 2026-10-15:** the page is a plain `MxSection`; no hero, since nothing here is a decision.
- **Brief 2026-10-15:** the Korean exam name is a subtitle line of the app bar, so the title stays on one line (The One Line Rule).
- **Plan 6a (2026-10-15):** the meta line is terms joined so it breaks only between them (The Wrap Rule): grades ("Levels 3–6") and sections ("Reading, Listening") are separate keys.
- **Plan 6a:** a level without tests is information, not a disabled control: no chevron, no tap, not dimmed (critique F5).
- **Plan 6a:** the level glyph is `AppIcons.fileText`, a paper: a level holds both sections, so it takes neither section's glyph (owner 2026-10-16, Q-P6-3, gave the sections `book` and `headphones` on 35).
- **Owner 2026-10-16 (Q-P6-2):** the Korean subtitle is `MxAppBar.subtitle`, read with the title in one heading node that names the route; the TOPIK-local title widget is gone.
- **Audit 2026-10-16 (DEV-394):** OPEN QUESTION Q-A-1: a level with tests only in Listening opens 35 on an empty Reading section (UC-TOPIK-001 step 2 fixes Reading as the default). Proposed: open the first section that has tests. Code unchanged until the owner rules.
- **Impeccable audit 2026-10-17 (P3, not changed):** the loading skeleton is not the loaded layout's twin: `MxListSectionHeader` + `MxCard` + `MxSkeletonList(rows: 2)` has no divider hairline between its rows and is about 120 dp tall against about 144 dp loaded (two-line meta), so nothing below the card exists to shift. Left as is until the shared `MxSkeletonList` gets a divided variant (35 and others share it); no local patch.
- **Impeccable audit 2026-10-17 (P3, not changed):** the counts come through the shared catalog provider, which also watches the attempt-status stream (`watch_topik_catalog_use_case.dart`), so a status read failure shows "Couldn't load the tests" for a bundled catalog. The provider is shared with 13 and 35; a catalog-only provider for counts is a new structure and waits for the owner.
- **Wireframe pass (owner, 2026-10-16):** nothing missing in scope. The section description line has no slot in `MxSection` and adds no fact; the level cards keep their rows; Beginner/Intermediate/Advanced (level drills) and Simulated Exams are Phase C and B and stay absent, per the index rule.

## Copy

- App bar: "TOPIK" · "한국어능력시험".
- Section: "Practice".
- Rows: "TOPIK I" · "Levels 1–2 · Reading, Listening · {n} tests" · "TOPIK II" · "Levels 3–6 · Reading, Listening · {n} tests" · "No tests yet".
- Error: "Couldn't load the tests" · "Nothing was lost. Try again." (a `Failure`: its own sentence, BR-CORE-005) · "Retry".
