# Visual-first UX fixes (G1–G7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use subagent-driven-development (recommended) or executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the groups G1–G7 of the visual-first audit: the shared-widget fixes first, then TOPIK, composition, the P2 batch and the copy.

**Architecture:** Each fix lands at its lowest shared owner (CLAUDE.md). Three shared widgets are added with the owner's approval of 2026-10-19: `MxChoiceMark` (the ✓/✗ of an answered choice), `MxDonut` (one ring painter), `MxBarChart` (a scrolling bar chart on fl_chart with 48 dp cells). Everything else changes existing widgets or screens.

**Tech Stack:** Flutter 3.47.5, ForUI 0.27.6, fl_chart 1.2.0, Riverpod, flutter_test goldens.

**Spec:** `docs/superpowers/specs/2026-10-19-visual-first-ux-audit-design.md` (§5–§7, owner decisions §9). Execution: native, in this session (owner, 2026-10-19: "write the spec and plan in one go, then build").

## Global Constraints

- Every colour, size and type role comes from `context.colors`, `context.status`, `context.texts`, `context.dimens`, `context.radii`, `context.hairline`; no literal (guard `memox.design_token.*`).
- Features compose `Mx*` widgets only; `package:forui` stays in `lib/core/theme/`, `lib/shared/`, `lib/app/` (UIL06); `package:fl_chart` only in `lib/shared/widgets/` (UIL07).
- No token in `lib/core/theme/` changes (O2: the slider fix is in `MxSlider`).
- The rulings kept by O3 and O4 stay: no ruling-bound idea of spec §5.2; 21's wrong-turns figure and the Match/Guess meaning in `caption` stay.
- Copy (owner-approved 2026-10-19, en / vi):
  - `algorithmLockedBody`: "The first card finished learning on {date}." / "Thẻ đầu tiên học xong ngày {date}."
  - `settingsLogSqlHint`: "Logs each statement the app runs, for performance checks." / "Ghi log mỗi câu lệnh app chạy để kiểm tra hiệu năng."
  - `welcomeBenefitReinstall` (en only): "Keep decks across reinstalls"
  - `importSectionSource` / `importSectionColumns` / `importSectionPreview`: drop the "1 · ", "2 · ", "3 · " prefixes.
- One behaviour, one test: extend the test that has the same inputs.
- Each task ends green on `run_tests.sh` for the tests it touches and `run_goldens.sh --changed`; the full `dod_check.sh` and `run_goldens.sh` run once on the final tree; the owner gets one golden-compare page.

## Review Focus

- A raised idle choice on a raised ground (Match terms on the page, TOPIK options on the question pane): the new edge must show in light and stay quiet in dark.
- A recessed idle choice (Match meanings on `muted`): an edge on `muted` must not read as a selected state.
- `MxBarChart` with 0 recorded time (every value 0): no guide, every bar a floor stub, the summary says "no time recorded".
- `MxBarChart` at the 328 dp column: the seventh bar still peeks under the fade.
- Card detail with no answer yet: the date rows must not leave an empty half-width cell.

---

### Task 1: G1, an idle choice has a visible edge

**Files:**
- Modify: `lib/shared/widgets/mx_choice_tile.dart` (`_decoration`, its doc comment)
- Test: `test/shared/widgets/mx_choice_tile_test.dart` ("idle is the card ground…", "an idle recessed tile sits on the muted ground")

- [ ] Step 1: In both idle tests, assert the border's colour is `colors.border` (light and dark) while the fill stays `card` / `muted`. Run: `run_tests.sh test/shared/widgets/mx_choice_tile_test.dart`. Expected: FAIL (edge is the fill).
- [ ] Step 2: In `_decoration`, the idle arm becomes `(rest, colors.border)`; the doc comment says the edge is the hairline at rest and eases into the tone's edge.
- [ ] Step 3: Tests pass; `run_goldens.sh --changed --update`; check 17, 18, 37, 39 goldens in light and dark.
- [ ] Step 4: Update `DESIGN.md`'s study choice line only if it names the idle edge (it does not today); update 17/18/37 detail-file rows that say "no edge".
- [ ] Step 5: Commit "Shared: an idle choice tile shows its hairline edge (G1)".

### Task 2: G2, the slider's inactive track shows on `muted`

**Files:**
- Modify: `lib/shared/widgets/mx_slider.dart` (the `FSlider(...)` call)
- Test: `test/shared/widgets/mx_slider_test.dart`

- [ ] Step 1: Add a test: the resolved `FSlider.style` inactive colour is `colors.border`, not `colors.secondary` (which equals `muted`). Expected: FAIL.
- [ ] Step 2: Pass `style: FSliderStyleDelta.delta(inactiveColor: FVariantsValueDelta.delta([FVariantValueDeltaOperation.all(context.colors.border)]))` to `FSlider`, with a comment: ForUI's inactive `secondary` equals the `muted` pane the TOPIK player sits on.
- [ ] Step 3: Tests pass; goldens `--changed --update` (37, 39 players, the gallery).
- [ ] Step 4: Commit "Shared: the slider's inactive track stands out from muted (G2)".

### Task 3: G3, TOPIK review marks right and wrong; summary leads with the weakest type

**Files:**
- Create: `lib/shared/widgets/mx_choice_mark.dart` (`MxChoiceMark`)
- Modify: `lib/features/study/presentation/widgets/sections/study_guess_widget.dart` (`_option`), `lib/features/topik/presentation/widgets/sections/topik_review_question_widget.dart` (`_option`), `lib/features/topik/presentation/screens/topik_summary_screen.dart` (children order), `docs/shared/ui/screen-handoff/38-topik-summary.md`, `39-topik-review.md`, `docs/forui-migration/SHARED_WIDGET_INVENTORY.md`
- Test: `test/shared/widgets/mx_choice_mark_test.dart`, the existing Guess and TOPIK review/summary tests

**Interfaces:**
- Produces: `MxChoiceMark({required MxChoiceTone tone, required Color color})`: a `check` for `right`, a `close` for `wrong`, nothing (`SizedBox.shrink`) otherwise, at `sizeIconInline`, excluded from semantics (the tile's label already says it).

- [ ] Step 1: Test `MxChoiceMark`: right → `AppIcons.check`, wrong → `AppIcons.close`, idle/selected → no Icon; the colour passed in; no semantics node. Test TOPIK review: the right option shows a check, the wrong pick a cross. Test summary: "By question type" precedes "Answers". Expected: FAIL.
- [ ] Step 2: Write `MxChoiceMark`; replace Guess's inline `IconTheme`+`Icon` with it; add it to the TOPIK option's first row (`Row(children: [Expanded(Text), MxChoiceMark])`).
- [ ] Step 3: Move the `TopikTypeStatsWidget` block after `TopikSummaryFiguresWidget`, before the Answers header; reorder 38's Layout table; drop 39's "P3, not changed" note.
- [ ] Step 4: Tests and goldens; commit "TOPIK: mark right and wrong, lead the summary with the weakest type (G3)".

### Task 4: G4, one donut and a shared bar chart

**Files:**
- Create: `lib/shared/widgets/mx_donut.dart` (`MxDonut`), `lib/shared/widgets/mx_bar_chart.dart` (`MxBar`, `MxBarChart`)
- Modify: `lib/shared/widgets/mx_mastery_donut.dart`, `lib/features/topik/presentation/widgets/sections/topik_score_donut_widget.dart`, `lib/features/topik/presentation/widgets/sections/topik_question_bar_chart_widget.dart`, inventory, ADR-026 (fl_chart's second widget), 38 detail file
- Test: `test/shared/widgets/mx_donut_test.dart`, `test/shared/widgets/mx_bar_chart_test.dart`, `test/features/topik/presentation/topik_summary_chart_test.dart`

**Interfaces:**
- Produces: `MxDonut({required double fraction, required Color arc, required Color track, required double strokeWidth, double? radius, Widget? child})`: a ring from twelve o'clock, round caps, the radius filling the box unless given.
- Produces: `MxBar({required double value, required Color color, required Widget marker, required String label, Key? key})` and `MxBarChart({required List<MxBar> bars, required List<MxBarSeries> legend, required String semanticLabel, String? guideLabel, required ValueChanged<int> onOpen})`: one `sizeControl` cell per bar, scrolling sideways under `MxScrollFade`, the bar a `space12` rod scaled to the largest value with a `space4` floor, the marker and label under it, the whole cell an `MxRowInk` that calls `onOpen(index)`, a dashed guide at the largest value carrying `guideLabel`, one TalkBack node with `semanticLabel`, the legend under it, no animation under Remove animations.

- [ ] Step 1: Tests for `MxDonut` (arc sweep, no arc at 0, radius default) and `MxBarChart` (a bar per value scaled to the largest; floor for 0; a tap on a cell calls `onOpen`; one semantics node; guide only when the largest value > 0; the seventh cell's centre under the fade at 328 dp). Expected: FAIL.
- [ ] Step 2: Write both widgets; `MxMasteryDonut` and `TopikScoreDonutWidget` keep their API and draw with `MxDonut`; `TopikQuestionBarChartWidget` maps answers to `MxBar`s (colour and glyph by status, the number as label, the longest duration as `guideLabel`).
- [ ] Step 3: Update the TOPIK chart tests (cell key `topik-chart-cell-{no}`, the seventh cell's centre); goldens; docs; commit "Shared: one donut and a bar chart on fl_chart (G4)".

### Task 5: G5, composition P1

**Files:**
- Modify: `lib/features/study/presentation/widgets/sections/study_guess_widget.dart` (prompt slot), `lib/features/card/presentation/widgets/sections/card_schedule_widget.dart` (date facts), `lib/features/deck/presentation/widgets/overlays/deck_reset_dialog_widget.dart` (`_Consequences`), `lib/features/account/presentation/widgets/items/user_row_widget.dart`, `lib/features/monitoring/presentation/widgets/sections/monitoring_detail_body_widget.dart` (`_errorCard`), their detail files
- Test: the screens' existing widget tests

- [ ] Step 1: Tests: the Guess prompt is at most `sizeControl × 4` tall with the leftover room between it and the options; Due, Learned and Last answered each take a full-width row and numbers pair; the reset tiles stack full width; a long email wraps to two lines; the error message does not start with the error type. Expected: FAIL.
- [ ] Step 2: Implement each (prompt: `Flexible` + `ConstrainedBox(maxHeight: sizeControl * _promptMaxControls)` then a `Spacer`; dates: date facts in their own rows, numeric facts paired; reset: `Column(stretch, spacing: space8)`; users: `titleMaxLines: 2`; monitoring: strip a leading `"$errorType("` … `")"` wrapper or `"$errorType: "` prefix).
- [ ] Step 3: Tests, goldens, docs; commit "Screens: give the prompt, dates, reset tiles, emails and errors room (G5)".

### Task 6: G6, the P2 batch

**Files:** `sync_status_section_widget.dart` (note left out while the offline notice shows), `card_row_widget.dart` (`_Trailing` reserves the flag slot), `settings_session_section_widget.dart` (stepper guards step from the stored limit while the draft is invalid), `study_fill_widget.dart` (wrong-state footer icon `info`; `_Corrected` marks only differing characters), `card_edit_summary_widget.dart` (`MxStatusBadge` leading), `progress_streak_widget.dart` (value in `figure`, no inner tile, no eyebrow), `tag_rename_dialog_widget.dart` (arrow and target chip in one Wrap child), `mx_scroll_fade.dart` / `mx_chip_row.dart` (the fade survives the chip row's ring clipper), docs (07 copy line, 15 note, 23 height budget, 23b loading row), `study_home_golden_test.dart` (one scrolled pair).

- [ ] Step 1: For each item, the failing test in the file that already covers that widget.
- [ ] Step 2: Implement each.
- [ ] Step 3: Tests, goldens, docs; commit "Screens: the P2 batch of the visual audit (G6)".

### Task 7: G7, copy

**Files:** `lib/l10n/app_en.arb`, `lib/l10n/app_vi.arb`, detail files 02, 11, 23b, 28, 29, `docs/superpowers/specs/2026-10-07-sql-log-switch-design.md` §5.

- [ ] Step 1: Update the strings exactly as in Global Constraints; regenerate l10n; update the copy quoted in the docs; tests that pin the old strings.
- [ ] Step 2: Goldens; commit "Copy: the four lines the visual audit shortened (G7)".

### Task 8: Verification and review

- [ ] Step 1: `dod_check.sh` and `run_goldens.sh` on the final tree.
- [ ] Step 2: Impeccable audit of the changed states (one pass).
- [ ] Step 3: Final whole-branch review (Opus), fix its findings in one batch, rerun the gate.
- [ ] Step 4: Golden-compare page; owner approval; pull request with check degrade and check similar.
