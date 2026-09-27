---
target: screen 01 deck mastery as built (goldens library_decks, library_decks_2x, library_deck_open, library_sort; light and dark)
total_score: 35
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 0
target_identity: "dir:test/features/deck/presentation/goldens"
timestamp: 2026-09-27T14-00-00Z
slug: deck-mastery-build
---
Method: one batched pass over the regenerated goldens against kit 01 (v3 `1790244159-01e6`), spec `docs/superpowers/specs/2026-09-27-deck-mastery-design.md` and the pre-plan critique `2026-09-27T12-00-00Z__deck-mastery-kit.md`.

## Result

The pre-plan findings are closed:
- **P1:** the learning band is the darker ink in light; dark keeps the amber.
- **P2a:** the percent never lies (`MasteryRamp.percent`, with tests).
- **P2b:** the fill keeps its height in from either end (tests).
- **P3:** the track is `progress-track`; the bar spans the text column; the overline has `semanticsLabel`; Progress is the fifth row.

What the goldens show:
- **`library_decks_{light,dark}`:** the three ramp bands (Korean 1/6, Kanji N5 1/2, Hanja 1/1), at the kit's 5 tall and 12 under the meta.
- **`library_decks_2x_light`:** at text scale 2 the bar keeps its band, and the meta ellipsises as it did before.
- **`library_deck_open_*`:** the donut reads 17 % beside "MASTERED · EIGHT BOXES".
- **`library_sort_*`:** Progress · Least mastered first, last of five.

## Findings

- **[P3] The summary's breakdown line ends in an ellipsis at 1x ("… 1 sched…").** The donut takes 72 dp of the row. The kit draws the same ellipsis ("850 sche…"), and the scheduled set is neutral and not actionable (BR-STUDY-068). Kept as in the kit and noted in detail file 01. No fix.

No P0–P2. Nothing to fix; no second round.
