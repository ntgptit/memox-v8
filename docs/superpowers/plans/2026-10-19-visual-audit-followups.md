# Visual audit follow-ups Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close the five items the visual audit left open: G8 (score trend), G9 (accent fill), S1 (slider track), T1 (theme lag), T2 (settle tests).

**Architecture:**
- One new theme slot (`accentFill`) is read by every data mark that drew `primary`.
- One new shared chart (`MxLineChart`) feeds screen 36.
- Two shared widgets ease only their own state changes.
- Two test files wait on the controller instead of on the clock.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6, fl_chart 1.2.0, Riverpod, Drift.

**Spec:** `docs/superpowers/specs/2026-10-19-visual-audit-followups-design.md`

Execution: native, in the main loop (owner, 2026-10-19: "write the plan in one go, then implement").

## Global Constraints

- `accentFill`: light `#564BCB`, dark `#776EE0`. Text never uses it.
- Slider inactive track `mutedForeground`, active track `accentFill`.
- Score trend shows from 2 submitted attempts; no number on a point.
- New copy, exact:
  - en "Score trend" / vi "Xu hướng điểm".
  - en "Scores of {count} submitted attempts, oldest first: {scores}, out of {max}".
  - vi "Điểm của {count} lượt đã nộp, từ cũ đến mới: {scores}, trên {max}".
- fl_chart is imported only in `lib/shared/widgets` (UIL07).
- No raw colours or spacing outside the theme (the guard).
- Removed theme names stay removed.

## Review Focus

1. A theme switch while a tone eases: the tile must land on the new theme's colour of the new tone. Pinned in Task 1.
2. Reduced motion: a tone change is instant, and so is a theme change. Pinned in Task 1.
3. An attempt with a null score, or one in progress, is never a point. Pinned in Task 4.
4. A maximum score of 0 must not divide by zero; the chart is absent instead. Pinned in Task 4.
5. A 360 dp phone with 30 attempts: the chart scrolls and opens at the newest. Pinned in Task 4.

---

### Task 1: T1, ease only a tone change; the harness mounts each theme cold

**Files:**
- `lib/shared/widgets/mx_choice_tile.dart`: Stateful. It lerps between the previous tone's decoration and the current tone's decoration, both read from the current theme.
- `lib/shared/widgets/mx_app_shell.dart`: `_AppBarGround` does the same for its edge.
- `test/support/golden_harness.dart`: `pumpWidget(SizedBox.shrink())` after each capture.
- `test/shared/widgets/mx_choice_tile_test.dart`: a theme switch test.

- [ ] Step 1: Write the failing test. Light theme, idle tile. Switch to dark, pump 250 ms (past ForUI's 200 ms). The tile's decoration colour equals dark `card`, and its foreground equals dark `foreground`. Today it fails, because the tile still eases from light.
- [ ] Step 2: Write the tone test: idle → right eases over `short4` (mid-frame differs from both ends). Under `disableAnimations` it is at once.
- [ ] Step 3: Implement. Track `_from` (the previous tone and recess) in an `AnimationController` of `short4` with `Easing.standard`. `didUpdateWidget` restarts it when tone or recess changes. `build` lerps `_decoration(context, from)` → `_decoration(context, tone)`, and the same for the foreground.
- [ ] Step 4: Apply the same to `_AppBarGround`, which lerps edge alpha 0 ↔ 1 over the current `border`.
- [ ] Step 5: Add the harness teardown. Update goldens with `run_goldens.sh --changed --update` and check that the nine dark component goldens are now dark-correct.
- [ ] Step 6: Commit "Shared: tiles ease a tone, not a theme; goldens mount each theme cold (DEV-323)".

### Task 2: T2, wait on the controller, not on the clock

**Files:** `test/features/settings/presentation/settings_controller_test.dart`, `study_options_controller_test.dart`.

- [ ] Step 1: Prove the race. Temporarily add `sleep`-free busy work of 800 ms after the steps. The test fails as reported.
- [ ] Step 2: Add `untilLanded(landed)` to `test/support/settings_fakes.dart`, shared by both files. It polls `landed()` every 10 ms until it holds, and fails after 10 s on a stopwatch, because the guard bans the wall clock in tests.
- [ ] Step 3: Replace each `_settled()` that waits for a write with `untilLanded` on what the write produces: the stored row, plus the state's echo where the test asserts it.
  - Keep the `writes == 0` cases on a wait, because they assert that nothing happens. Use `_settled()` there, renamed `_pastSettle()`.
- [ ] Step 4: Do the same in `study_options_controller_test.dart`.
- [ ] Step 5: The busy-work probe now passes. Remove it and run both files three times.
- [ ] Step 6: Commit "Tests: the settings controllers' tests wait on the write, not the clock (DEV-323)".

### Task 3: G9 and S1, `accentFill`; the slider's tracks

**Files:**
- `lib/core/theme/mx_status_colors.dart`: the slot, `copyWith` and `lerp`.
- `lib/core/theme/mastery_ramp.dart`: `fill` reads `status.accentFill`; drop its `accent` parameter.
- `lib/shared/widgets/mx_linear_progress.dart`: the primary tone and the mastery fill.
- `lib/shared/widgets/mx_mastery_donut.dart`.
- `lib/shared/widgets/mx_slider.dart`: active `accentFill`, inactive `mutedForeground`.
- `lib/features/progress/presentation/widgets/sections/progress_today_widget.dart`: the reviewing series.
- `test/core/theme/token_contrast_test.dart`: `accentFill` on background, card and muted ≥ 3.
- `test/core/theme/mastery_ramp_test.dart`.
- DESIGN.md: regenerate with `MEMOX_WRITE_DESIGN_DOCS=1 flutter test test/tools/design_doc_test.dart`.
- Docs: 22 and 37 detail files; `SHARED_WIDGET_INVENTORY` rows for `MxSlider`, `MxLinearProgress` and `MxMasteryDonut`.

- [ ] Step 1: Write the failing contrast pairs. `accentFill` on background, card and muted must be ≥ 3:1 in both modes. The test fails to compile until the slot exists.
- [ ] Step 2: Add the slot (light `#564BCB`, dark `#776EE0`) with its doc comment.
- [ ] Step 3: Make `MasteryRamp.fill(status, fraction)` use `accentFill` and update its callers and tests. `foreground` keeps its `accent`, because text stays `primary` (2026-10-17 ruling).
- [ ] Step 4: Move every remaining data fill off `primary` (check similar: `rg "colors\.primary" lib`).
  - Change the bars, bands, progress fills, the slider track and chart series.
  - Leave alone buttons, selected surfaces, tints and text.
- [ ] Step 5: Slider: inactive `mutedForeground`, active `accentFill`; update `mx_slider_test`.
- [ ] Step 6: Regenerate DESIGN.md, then run `python3 tools/design/check.py`, the contrast test and the goldens (`--changed --update`). Check that every light golden is unchanged for G9.
- [ ] Step 7: Commit "Theme: the accent as a fill holds 3:1 in dark; the slider's tracks stand out (G9, DEV-323)".

### Task 4: G8, `MxLineChart` and the score trend on screen 36

**Files:**
- Create `lib/shared/widgets/mx_line_chart.dart` and `test/shared/widgets/mx_line_chart_test.dart`.
- Create `lib/features/topik/presentation/widgets/sections/topik_score_trend_widget.dart`.
- Modify `topik_overview_widget.dart`.
- ARB keys `topikScoreTrend` and `topikScoreTrendSummary` in en and vi.
- `topik_test_detail_screen_test.dart` and `topik_test_detail_golden_test.dart`: add a one-attempt overview.
- Docs:
  - `36-topik-test-detail.md`: Layout, States, Transitions, rulings, copy.
  - `docs/features/topik/README.md` and the 2026-10-15 spec §10: Score Trend leaves Phase B.
  - `SHARED_WIDGET_INVENTORY.md`: a new row.
  - The screen index row.

**Interfaces:**
- `MxLinePoint({required double value, required String label})`
- `MxLineChart({required List<MxLinePoint> points, required double maxValue, required String maxLabel, required String semanticLabel, MxScrollFadeGround ground = MxScrollFadeGround.page})`
- `topikAttemptIsScored(TopikAttempt)` and `topikScoredAttemptsOf(List<TopikNumberedAttempt>)` in `topik_test_progress_model.dart`, one rule shared with Best and Average

- [ ] Step 1: Write the failing widget tests for `MxLineChart`.
  - One semantics node carrying the label.
  - The labels sit under the points.
  - The y range is 0..max.
  - 30 points scroll and open at the end.
  - The line colour is `accentFill`.
- [ ] Step 2: Write the failing screen tests.
  - The trend is absent at 0 and 1 submitted attempts.
  - It shows at 2 or more.
  - In-progress and null-score attempts are skipped.
  - The TalkBack summary is exact.
  - `maxScore` 0 means no chart.
- [ ] Step 3: Implement `MxLineChart` on fl_chart `LineChart`.
  - Columns are `sizeControl` wide, under `MxScrollFade`, with `reverse: true` so the scroll opens at the newest.
  - No touch, no grid.
  - A baseline hairline in `border`.
  - `duration: Duration.zero`.
- [ ] Step 4: Implement `TopikScoreTrendWidget`: an `MxListSectionHeader` plus an `MxCard` around the chart. Insert it after the scores note in the overview.
- [ ] Step 5: Add the ARB keys and regenerate l10n. Update the docs. Run goldens with `--changed --update`.
- [ ] Step 6: Commit "TOPIK: score trend across submitted attempts on screen 36 (G8, DEV-323)".

### Task 5: Verification and review

- [ ] Run `dod_check.sh` and `run_goldens.sh` on the final tree.
- [ ] Run one Impeccable audit of the changed states.
- [ ] Run the final whole-branch review on Opus; fix its findings in one batch and rerun the gate.
- [ ] Rerun check degrade and check similar on the final diff.
- [ ] Build the golden-compare page, get the owner's approval, then open the pull request.
