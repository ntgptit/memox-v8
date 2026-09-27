---
target: built screen 22 Progress, both levels (post-build audit)
target_identity: "dir:test/features/progress/presentation/goldens"
timestamp: 2026-09-27T05-00-00Z
slug: progress-build
p0_count: 0
p1_count: 1
---
Method: one batched pass. The 24 screen 22 goldens (light and dark: the 8 kit states and the 4 the kit lacks) were read beside the kit captures in `docs/shared/ui/screen-handoff/img/22-progress/` and `22-progress.md`, with `mx_day_bars_*`. Throwaway captures of both levels at text scale 2 in Vietnamese (360 dp, light and dark) were added for the hardest case. The visual audits (`test/visual_audit/screens/features/progress/`) already enforce 48 dp targets, labelled targets and no overflow at 1x and 2x, in English and Vietnamese.

## Findings

- **[P1] At large text the streak tiles broke every label and count.** At 2x in Vietnamese the two tiles were about 120 dp wide, so "HIỆN TẠI", "3 ngày" and "giữ từ hôm qua" each took a line per word. The visual audit passed, because wrapping is not overflow.
  - *Fixed in this pass:* `ProgressStreakWidget` stacks the tiles, one per line, when a tile's label or count would not fit its line (`_StreakTile.minWidth`, the rule of `ThemeChoiceCardWidget` in plan 1). At 1x they stay side by side and no golden changes. `MxIconTile.smallBox` is now public for the measure.
  - *Test:* "at large text in Vietnamese the streak tiles stack, so a label or a count keeps its line; at 1x they sit side by side" (RED, then GREEN).
- **[P3, recorded] At 2x the bar labels shrink to fit.** "Hôm nay" scales down under the last bar (C2). Each bar's TalkBack label carries the day in full, and the numbers of today are above the chart.

## Checked and matching the kit (with the recorded deviations)

- **Library level:** Today with its split and seven bars; the streak with the held and lost notes; the range directly above the list (D10); "All decks" with its four numbers (D2); idle decks at full contrast (D11); never studied with "Start studying" (D1).
- **A deck's level:** the path, "Sub-decks", "Whole deck", the children; no sub-decks (A1) and gone (E2).
- **Loading and error:** as recorded (UI-base rows 125, 129).

## Score

Accessibility 4 · Performance 4 · Theming 4 · Conformance 4 · Adaptivity 3 (phone only, by ADR) = 19/20 after the fix.
