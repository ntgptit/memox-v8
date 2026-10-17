<!-- Hand-written screen record. -->

# 38 · TOPIK summary

The result of one submitted attempt, read from its snapshot (UC-TOPIK-004, BR-TOPIK-013,
BR-TOPIK-019, BR-TOPIK-023…BR-TOPIK-025). Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §6.4, §8.

## Entry points

- Submit on screen 37 (replaces 37 in the stack: Back goes to 36).
- "Summary" on screen 36.
- Deep link `/study/topik/attempt/:attemptId/summary` (root navigator).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back in the leading slot; "Summary"; trailing an `MxIconButton` (`AppIcons.preview`) labelled "Hide answers" or "Show answers" (S9: `AppIcons` has no eye-off glyph, so the label carries the state). The eye shows only when a result is loaded. |
| Hero | `TopikSummaryHeroWidget` in an `MxCard` (hero) | "#96 · TOPIK II · Reading", from the attempt's own fields so it holds when the test is gone (S2), glued terms (The Wrap Rule); meta "{date time} · {duration}"; the score "96 / 100" (fits 100 / 100 at 360 dp, BR-TOPIK-025); beside it `TopikScoreDonutWidget`: correct / count with the caption "Correct" under it, `success` arc on the `surfaceContainerHighest` track (S3, Contrast Floor). The row is one TalkBack node "Score 96 of 100, 48 of 50 correct". |
| Figures | `TopikSummaryFiguresWidget`: 2×2 boxed `MxStatTile`s in an `MxCard` | "Average per Q" (the time over all questions, a blank one counted) · Answered · Unanswered · "Longest · Q{no}" with the duration as its value (S1, One Line Rule). Each label keeps one line at 360 dp in both languages (124 dp: "Average per question" is 160 and "Trung bình mỗi câu" 139, so the tile says "Average per Q" / "Trung bình/câu"; "Lâu nhất · Câu 32" is 123.7); a time figure with no time is a dash that reads "None". Correct of total is the donut's. |
| Filters | "Answers" header + `TopikAnswerFilterChipsWidget` (`MxChipRow` of `MxFilterChip`s) | All · Wrong · Unanswered · Correct, the count in the chip's count slot; scrolls sideways at 360 dp. |
| Time per question | "Time per question" header + `TopikQuestionBarChartWidget` | Scrolls sideways; one bar per question, height by time, colour by status (`success`, `error`, `outline` for unanswered, S4); a zero time keeps a `space4` stub; the real number under each; each bar is an `MxRowInk` `sizeControl` wide; a tap opens 39 at that question (S4); under each bar a status glyph (`AppIcons.check`, `close`, `remove`) at `sizeIconButton` in the status's text role (`success`, `error`, `onSurfaceVariant`) is a second channel besides colour; the row is wrapped in `MxScrollFade` (horizontal, page ground) so a cut bar reads as "scroll for more". TalkBack gets one node for the whole chart, "Time per question, {count} questions, longest question {no} {duration}" (no "longest" when no time was recorded), and none for the bars (owner 2026-10-17, S4): the answer rows below are the way to each question. Under it an `MxChartLegend` in the filter chips' order: Wrong, Unanswered, Correct, each with a dot of its bar colour, silent to TalkBack. |
| Answers | `MxCard` of `TopikAnswerRowWidget`s (`MxListRow`) | Title "Question {no}"; meta "Your answer ② · Right answer ③ · 1m 05s" (the eye drops "Right answer"); trailing a status `MxBadge` (success, danger, neutral) and no chevron (`MxListRow` takes one or the other); a row opens 39 at that question (S5). |
| Empty filter | `MxEmptyState` (compact, neutral) | Replaces the chart and the rows (S6). |
| By question type | `TopikTypeStatsWidget` in an `MxSection` | One row per type: localized name (`titleSmall`), "{correct} / {total}", an `MxLinearProgress` under it; the weakest marked by an `MxBadge` (warning) "Weakest" (BR-TOPIK-024); a perfect result has none (S7). |
| Footer | `MxFooterBar` with `MxActionPair` | "Done" (outline, leading) · "Review answers" (primary) (S8). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `topik_summary_loaded_light.png` | `topik_summary_loaded_dark.png` | A mixed result. |
| loaded, chart in view | `topik_summary_chart_light.png` | `topik_summary_chart_dark.png` | The loaded result scrolled to Time per question: the bars, their numbers and the legend. |
| perfect | `topik_summary_perfect_light.png` | `topik_summary_perfect_dark.png` | 100 / 100: no layout break; no weakest type. |
| zero | `topik_summary_zero_light.png` | `topik_summary_zero_dark.png` | 0 / 100, every question unanswered. |
| topik1Reading | `topik_summary_t1_reading_light.png` | `topik_summary_t1_reading_dark.png` | Numbers 31–70 in the figures, the chart and the rows. |
| correctHidden | `topik_summary_hidden_light.png` | `topik_summary_hidden_dark.png` | The right answers hidden by the eye. |
| filterEmpty | `topik_summary_filter_empty_light.png` | `topik_summary_filter_empty_dark.png` | Wrong selected on a perfect result: "No wrong answers". |
| attemptMissing | `topik_summary_missing_light.png` | `topik_summary_missing_dark.png` | Deleted elsewhere, the account switched, or still in progress: neutral `MxEmptyState`, "Back to the test"; no footer, no eye. |
| loading | `topik_summary_loading_light.png` | `topik_summary_loading_dark.png` | `MxSkeletonList` in a card; no footer, no eye. |
| error | `topik_summary_error_light.png` | `topik_summary_error_dark.png` | `MxErrorState` "Couldn't load this summary" with Retry; no footer (S10). |

**Built (plan 6c, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_summary_screen_test.dart`, `topik_summary_widgets_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why. contentMissing does not apply: the summary reads the attempt's snapshot (S10).

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| 37 | Submit | loaded (37 replaced in the stack) | UC-TOPIK-003 step 6. VERIFIED `topik_routes_test.dart::Submit on 37 replaces it with the summary; Done lands on the test (UC-TOPIK-003 step 6)` |
| loading | read done | loaded | UC-TOPIK-004. VERIFIED `topik_summary_screen_test.dart::the result from the snapshot: score, rows per question; a row, Review answers and Done lead out (UC-TOPIK-004)` |
| loaded | filter chip | loaded, chart and rows filtered | UC-TOPIK-004 step 5. VERIFIED `::a filter narrows the chart and the rows; an empty one says so (UC-TOPIK-004 step 5, A1)` |
| loaded | filter with no rows | filterEmpty | UC-TOPIK-004 A1. VERIFIED `::a perfect result: Wrong is empty and says so; no weakest type (BR-TOPIK-024)` (Wrong, Unanswered), `::a zero result: Wrong and Correct are empty and say so (BR-TOPIK-023, UC-TOPIK-004 A1)` |
| filterEmpty | another filter with rows | loaded | UC-TOPIK-004 step 5. VERIFIED `::a perfect result: Wrong is empty and says so; no weakest type (BR-TOPIK-024)` (Unanswered → All) |
| loaded | eye | correctHidden, and back | UC-TOPIK-004 step 6. VERIFIED `::the eye hides the right answers, and shows them again (UC-TOPIK-004 step 6)` |
| loaded | answer row / Review answers | 39 at that question / at the first | UC-TOPIK-004 step 7. VERIFIED `::the result from the snapshot: score, rows per question; a row, Review answers and Done lead out (UC-TOPIK-004)`, `topik_routes_test.dart::from the summary a row opens Review at its question; Back returns to the summary (UC-TOPIK-004 step 7)` |
| loaded | chart bar | 39 at that question | S4. VERIFIED `topik_summary_widgets_test.dart::the chart: a bar per question with its real number and a status glyph, and a tap opens it (critique S4)` (the callback; TalkBack reaches the question by its row); the route is the row's |
| loaded | content changed or removed | loaded, unchanged (snapshot) | BR-TOPIK-019. VERIFIED `::the test removed afterwards changes nothing: the snapshot stays (BR-TOPIK-019)` (removed); a changed `contentVersion` is the same path, read from the code |
| any | the content read fails | unchanged: the summary reads no content | BR-TOPIK-019. VERIFIED `test/features/topik/domain/topik_use_cases_test.dart::the summary reads from the snapshot alone: a content read that fails changes nothing (BR-TOPIK-019)` |
| any | attempt deleted elsewhere | attemptMissing | UC-TOPIK-004 E1. VERIFIED `::the attempt deleted elsewhere: missing, Back to the test (UC-TOPIK-004 E1)` |
| any | account switched | attemptMissing | UC-TOPIK-004 E1, BR-TOPIK-027. UNVERIFIED on this screen: the switch clears the store (`LocalDataReset`) and the stream emits null, the path the delete row exercises; no screen test drives a switch (as on 36 and 37) |
| deep link | attempt still in progress | attemptMissing | UC-TOPIK-004. VERIFIED `::an attempt in progress has no summary` |
| error | Retry | error (retrying) → the state of the next read | S10. VERIFIED `::a read that fails: Retry reads again` (the second read lands on attemptMissing; the error stays up with its retry in progress, no skeleton) |
| attemptMissing | Back to the test | 36 (or TOPIK when opened alone) | navigation. VERIFIED `::the attempt deleted elsewhere: missing, Back to the test (UC-TOPIK-004 E1)` (the callback) |
| loaded | Done / Back | 36 (or TOPIK when opened alone) | S11. VERIFIED `topik_routes_test.dart::Submit on 37 replaces it with the summary; Done lands on the test (UC-TOPIK-003 step 6)` |

## Rulings

- **Brief 2026-10-15:** the title names the test and section, never "Listening Practice" (prompt §4).
- **Brief 2026-10-15:** Your and Right are option numbers, never option text (prompt §4); text is in Review.
- **Brief 2026-10-15:** unanswered is neutral, not warning: a blank answer is not a refusal or a limit (DESIGN.md, Semantic).
- The donut is a topik widget, not `MxMasteryDonut`: that one draws the mastery ramp.
- **PR #283:** no raw `InkWell` or bare `Icon` in the chart or the rows; the body sits on `context.screenMargin`; the chip counts use `MxFilterChip`'s count slot.
- **S1 (plan 6c):** figures in a 2×2 grid; "Longest · Q{no}" is the label, the duration the value.
- **S2 (plan 6c):** the hero title comes from the attempt, "#{round} · {level} · {section}", so it holds when the test is gone.
- **S3 (plan 6c):** the donut arc is `success` (3:1 on its track); the hero is one TalkBack node.
- **S4 (plan 6c):** a bar opens Review at its question, like its row; no tooltip. Unanswered bars are `outline`. **Owner 2026-10-17 (Impeccable audit):** the chart is one TalkBack node (a summary) and its bars are excluded from the tree, because 70 bar nodes before the rows were a long swipe; the rows carry the same status and time and open the same question. A glyph under each bar (check, cross, dash) is the second channel besides colour, and the scrolling row fades its edge. Pinned by `topik_summary_widgets_test.dart::the chart is one TalkBack node; its bars are hidden from the tree (owner 2026-10-17, ruling S4)`.
- **Owner 2026-10-17 (Impeccable audit):** the Accuracy tile goes (the donut already shows correct of total) and "Average per Q" takes its place; `TopikAttemptSummary.averageTimeMs` is the total time over `questionCount`. The option digits ①–④ stay on screen in the answer rows and read as plain digits to TalkBack ("Your answer 3, Right answer 1", `Text.semanticsLabel`).
- **S5 (plan 6c):** one `MxListRow` per answer instead of a five-column table, which does not fit 296 dp; the status badge takes the trailing slot, so there is no chevron.
- **S6 (plan 6c):** an empty filter is a compact neutral `MxEmptyState` in place of the chart and the rows.
- **S7 (plan 6c):** by type: name, share and a linear progress; the weakest gets a warning badge, a perfect result none.
- **S8 (plan 6c):** footer "Done" (outline) and "Review answers" (primary): one accent.
- **S9 (plan 6c):** the eye's label carries its state; Back is in the leading slot.
- **S10 (plan 6c):** an error state with Retry; no contentMissing.
- **S11 (plan 6c):** 38 replaces 37, so Done and Back land on 36; a deep link builds Study → TOPIK → 38.
- **Owner 2026-10-16 (Q-P6-5):** Longest with no time is a dash on screen and reads "None" to TalkBack (`MxStatTile.semanticValue`): a submitted attempt is final, so not "None yet".
- **Audit 2026-10-16 (DEV-394):** `WatchTopikSummaryUseCase` awaited the content catalog although nothing on this screen reads it (the hero names the test from the attempt's fields), so a catalog read that failed turned the summary into its error state against BR-TOPIK-019. It now reads the attempt alone. The hero is pinned by `topik_summary_widgets_test.dart::the hero: which test, when and how long, from the attempt, and one TalkBack node for the score (critique S2, S3)`. Vietnamese: the empty Unanswered filter now says "Không có câu chưa trả lời", the term every other TOPIK string uses (it said "bỏ trống").
- **Wireframe pass (owner, 2026-10-16):** the time chart gets a legend (shared `MxChartLegend`, owner's choice), so colour is not the only cue on screen; the donut's figure says what it counts ("Correct"), since "27 / 50" sits beside "54 / 100". The wireframe's section description line and the bottom ad stay out (no BR; ads are out of scope).

## Copy

- App bar: "Summary" · "Hide answers" · "Show answers".
- Hero: "#{round} · {level} · {section}" · "{date time} · {duration}" · "{score} / {max}" · "{correct} / {count}" · "Correct" (under the donut figure) · TalkBack "Score {score} of {max}, {correct} of {count} correct".
- Figures: "Average per Q" · "Answered" · "Unanswered" · "Longest · Q{no}"; TalkBack "None" when Longest has no time.
- Filters: "Answers" · "All" · "Wrong" · "Unanswered" · "Correct" (each with its count in the chip's count slot).
- Chart: "Time per question" · legend "Wrong" · "Unanswered" · "Correct" · "Time per question, {count} questions, longest question {no} {duration}" (TalkBack, the whole chart).
- Rows: "Question {no}" · "Your answer {option}" · "Right answer {option}" · "Not answered" · badges "Correct" · "Wrong" · "Unanswered".
- Types: "By question type" · "{correct} / {total}" · "Weakest".
- Footer: "Done" · "Review answers".
- Empty filter: "No wrong answers" · "No unanswered questions" · "No correct answers".
- Missing: "This attempt isn't here any more" · "Back to the test".
- Error: "Couldn't load this summary" · the failure's body · "Retry". Loading: "Loading the summary" (TalkBack).
