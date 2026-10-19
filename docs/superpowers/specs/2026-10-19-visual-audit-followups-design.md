# Visual audit follow-ups: score trend, accent fill, slider, theme lag, settle tests

Status: approved by the owner on 2026-10-19 (decisions O6–O9 below).
Follows `2026-10-19-visual-first-ux-audit-design.md` (pull request 315). That
spec left G8, G9 and three open items; this one settles all five.

## 1. Scope

| # | Item | Tier | Owner |
|---|---|---|---|
| G8 | Score across attempts on screen 36 | 2 | a new shared `MxLineChart`; screen 36's Overview |
| G9 | The accent as a data fill holds 3:1 in dark | theme | `MxStatusColors.accentFill` |
| S1 | The slider's inactive track holds 3:1 on `muted` | 1 | `MxSlider` |
| T1 | A choice tile and the app bar's edge lag a theme change | 1 | `MxChoiceTile`, `_AppBarGround`, the golden harness |
| T2 | The settings controller tests race the database write | 0 | the two controller test files |

## 2. Root causes (proven, Opus investigation 2026-10-19)

- **T1, the golden.** `expectThemedGoldens`
  (`test/support/golden_harness.dart:114-137`) pumps light, then dark into the
  same tree. ForUI's `FTheme` animates a theme change for 200 ms
  (forui 0.27.6, `theme.dart:194-282`); `themeAnimationDuration` only stops
  Material's. The dark frame at t=300 ms starts ForUI's animation at 0, so the
  tile is built light. `pump(300ms)` draws one frame at t=600 ms where the
  theme is fully dark; the tile's own `TweenAnimationBuilder`s
  (`mx_choice_tile.dart:65,73`) get dark targets and restart from light with
  0 ms elapsed, and that frame is the golden. A probe printed
  `ctx.card=dark … deco=white anim=[0.0,0.0]` at the capture.
- **T1, the app.** The same chase happens on a real theme switch: the page
  reaches dark at about 208 ms, the tile at about 416 ms. `_AppBarGround`
  (`mx_app_shell.dart:255`) eases its edge the same way. The tween exists to
  ease a tone change, not a theme change.
- **T2.** The card limit settles on a 600 ms `Timer`
  (`settings_controller.dart:27,79`); the test waits a fixed
  `Future.delayed(600 + 150 ms)` (`settings_controller_test.dart:49`). When
  the isolate is starved past 750 ms both timers fire in one turn: the settle
  timer starts the drift transaction, and the test's expired delay runs
  before the commit, reading 20. A probe that blocks the isolate 800 ms
  reproduces "Expected 23, Actual 20".
- **G9.** Every "reviewing" data fill is `colors.primary` #564BCB, which is
  2.72:1 on the dark card #171538 and 2.33:1 on dark `muted`: below the
  3:1 floor for a graphic. It reaches the Progress bars and legend
  (`progress_today_widget.dart:106`), the mastery ramp's middle band
  (`mastery_ramp.dart:24`, through `MxMasteryDonut` and `MxLinearProgress`),
  a primary-tone `MxLinearProgress`, and the slider's active track.
- **S1.** `MxSlider`'s inactive track is `border` on `muted`: 1.16:1 light,
  1.51:1 dark.

## 3. Decisions (owner, 2026-10-19)

| # | Decision |
|---|---|
| O6 | G9: a new slot `MxStatusColors.accentFill`, "the accent as a fill: a bar, a band, a line, a track". Light #564BCB (the primary), dark **#776EE0**: 4.69:1 on the page, 4.24:1 on the card, 3.64:1 on `muted`. Text keeps `primary` or `accentMark` as ruled on 2026-10-17. |
| O7 | S1: the inactive track is `mutedForeground` (5.68:1 light, 6.04:1 dark on `muted`); the active track is `accentFill`. |
| O8 | G8: a section "Score trend" under Overall Progress on screen 36, shown from two submitted attempts. The six tiles stay. Score Trend leaves Phase B. |
| O9 | T1: a tile eases a tone change only; a theme change follows ForUI's own animation. The same for the app bar's edge. The harness tears the tree down between themes. |

## 4. G8 design

- **Data.** `detail.attempts` already holds each attempt's `score`,
  `maxScore` and `number`. The trend is the submitted attempts with a score
  (BR-TOPIK-020 counts only those), oldest first. Under two points the
  section is absent: one point is not a trend (BR-TOPIK-029 also starts at
  two).
- **Widget.** `MxLineChart` in `lib/shared/widgets` (fl_chart, UIL07):
  points `MxLinePoint(value, label)`, `maxValue`, `semanticLabel`.
  - A `space4`-wide line and dots in `accentFill`; the y axis runs from 0 to
    `maxValue` over `sizeControl * 2`; no grid; a `border` hairline baseline.
  - The `#n` label under each point in `meta`, `mutedForeground`; one
    `sizeControl` column per point. More points than fit scroll sideways
    inside `MxScrollFade` and open at the newest.
  - No number on a point: Best and Average are the tiles' numbers ("one
    number per element", screen 36 ruling).
  - One TalkBack node with `semanticLabel`; the chart itself is excluded.
    `duration: Duration.zero`: a result, and no colour easing behind a theme
    change.
- **Copy.** Header "Score trend" / "Xu hướng điểm". TalkBack: "Scores of
  {count} submitted attempts, oldest first: {scores}, out of {max}" /
  "Điểm của {count} lượt đã nộp, từ cũ đến mới: {scores}, trên {max}".
- **States.** `overview` gains the section when two or more attempts are
  submitted; `overview` with one submitted attempt shows no section (a new
  golden). Transitions: a submitted attempt arriving (sync, a finished
  attempt) or a delete recomputes the points, as the figures do.

## 5. Verification

Each item has a test that fails before its fix. Goldens move:
- G9 and S1: dark goldens that draw a reviewing band, a primary progress bar
  or the slider. Light is unchanged for G9, because `accentFill` is the
  primary in light.
- G8: screen 36's overview goldens, plus a new one-attempt overview.
- T1: nine themed component goldens. Their dark images become dark-correct.

The golden-compare page goes to the owner before the merge.
