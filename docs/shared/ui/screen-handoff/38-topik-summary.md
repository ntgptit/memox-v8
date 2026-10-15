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
| App bar | `MxAppBar` | "Summary"; trailing eye `MxIconButton` hides or shows the Correct column. |
| Hero | `MxCard` (hero) | "제96회 · 듣기" (`titleMedium`), date and time and duration (meta); the score "96 / 100" in `displayMedium` (it fits at 100 / 100 at 360 dp, BR-TOPIK-025); beside it `TopikScoreDonut` (new, topik): correct / count, `successContainer` arc on the `surfaceContainerHighest` track, "48 / 50" inside. |
| Figures | Row of `MxStatTile`s | Accuracy · Answered · Unanswered · Longest ("Q{no} · 2m 05s"). |
| Filters | `MxChipRow` of `MxFilterChip`s | All · Wrong · Unanswered · Correct, each with its count in the chip's count slot (`labelSmall` after the label, PR #283), not in the label. |
| Time per question | `TopikQuestionBarChart` (new, topik) | Scrolls sideways; one bar per question, height by time, colour by status: `success` correct, `error` wrong, `onSurfaceVariant` on `surfaceContainerHighest` unanswered; the real number under each; each bar is an `MxRowInk` (focus ring, hover, never a raw `InkWell`); tap a bar → its time in a tooltip on the inverse surface; one TalkBack node per bar "Question {no}, {status}, {time}", asserted by a test (pitfall 19). |
| Table | `MxCard` of rows | No · Your · Correct · Time · Status; Your and Correct as ①–④ (or "—"); the status as a small `MxBadge` (success, danger, neutral); a row opens 39 at that question. |
| By question type | `MxSection` | One row per type: localized type name, "{correct} / {total}", a thin `MxLinearProgress`; the weakest type marked with an `MxBadge` (warning) "Weakest" (BR-TOPIK-024). |
| Footer | `MxFooterBar` | "Review answers" (primary) · "Done" (outline) back to 36. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `topik_summary_loaded_light.png` | `topik_summary_loaded_dark.png` | A mixed result. |
| perfect | `topik_summary_perfect_light.png` | `topik_summary_perfect_dark.png` | 100 / 100: no layout break; no weakest type. |
| zero | `topik_summary_zero_light.png` | `topik_summary_zero_dark.png` | 0 / 100, every question unanswered. |
| topik1Reading | `topik_summary_t1_reading_light.png` | `topik_summary_t1_reading_dark.png` | Numbers 31–70 in the chart and the table. |
| correctHidden | `topik_summary_hidden_light.png` | `topik_summary_hidden_dark.png` | The Correct column hidden by the eye. |
| filterEmpty | `topik_summary_filter_empty_light.png` | `topik_summary_filter_empty_dark.png` | Wrong selected on a perfect result: "No wrong answers". |
| attemptMissing | `topik_summary_missing_light.png` | `topik_summary_missing_dark.png` | Deleted from another device or account switched: neutral `MxEmptyState`, "Back to the test". |
| loading | `topik_summary_loading_light.png` | `topik_summary_loading_dark.png` | Hero skeleton. |

**Not built yet (status `shaped`).** Goldens are the planned names under `test/features/topik/presentation/goldens/`; every transition's evidence is the rule it implements and the widget or controller test the screen's plan adds. Each row turns `VERIFIED` only with an executed test.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| 37 | Submit | loaded (37 removed from the stack) | UC-TOPIK-003 step 6 |
| loaded | filter chip | loaded, chart and table filtered | UC-TOPIK-004 step 5 |
| loaded | filter with no rows | filterEmpty | UC-TOPIK-004 A1 |
| loaded | eye | correctHidden (and back) | UC-TOPIK-004 step 6 |
| loaded | table row / Review answers | 39 at that question / the first | UC-TOPIK-004 step 7 |
| loaded | content changed or removed | loaded, unchanged (snapshot) | BR-TOPIK-019 |
| any | attempt deleted elsewhere or account switched | attemptMissing | UC-TOPIK-004 E1 |
| loaded | Done / Back | 36 | navigation |

## Rulings

- **Brief 2026-10-15:** the title names the test and section, never "Listening Practice" (prompt §4).
- **Brief 2026-10-15:** Your and Correct are option numbers, never option text (prompt §4); text is in Review.
- **Brief 2026-10-15:** unanswered is neutral, not warning: a blank answer is not a refusal or a limit (DESIGN.md, Semantic).
- The donut is a topik widget, not `MxMasteryDonut`: that one draws the mastery ramp.
- **PR #283:** no raw `InkWell` or bare `Icon` in the chart or the table; the body sits on `context.screenMargin`; the chip counts use `MxFilterChip`'s count slot.

## Copy

- App bar: "Summary" · "Hide answers" · "Show answers".
- Hero: "{round}회 · {section}" · "{date} · {time} · {duration}" · "{score} / {max}" · "{correct} / {count}".
- Figures: "Accuracy" · "Answered" · "Unanswered" · "Longest" · "Q{no} · {duration}".
- Filters: "All" · "Wrong" · "Unanswered" · "Correct" (each with its count in the chip's count slot).
- Chart: "Time per question" · "Question {no}, {status}, {duration}".
- Table: "No" · "Your" · "Correct" · "Time" · "Status" · "Correct" · "Wrong" · "Unanswered".
- Types: "By question type" · "{correct} / {total}" · "Weakest".
- Footer: "Review answers" · "Done".
- Empty filter: "No wrong answers" · "No unanswered questions" · "No correct answers yet".
