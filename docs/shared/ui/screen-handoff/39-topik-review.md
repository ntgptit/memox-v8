<!-- Hand-written screen record. -->

# 39 · TOPIK review

Each question of a submitted attempt with the right answer and the supporting content
(UC-TOPIK-005, BR-TOPIK-006, BR-TOPIK-010, BR-TOPIK-017, BR-TOPIK-019). Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §8.

## Entry points

- A row or "Review answers" on screen 38; "Review" on screen 36.
- Deep link `/study/topik/attempt/:attemptId/review?q=<no>` (root navigator).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back in the leading slot; "Review · {no} / {last}" with the real numbers (V6); "Review" in the states without a question. |
| Filters | `TopikAnswerFilterChipsWidget` above the panes | All · Wrong · Unanswered · Correct, counts in the chip's count slot; a chip with no question is off (`isEmptyDisabled`); picking a filter opens its first question (V5). Previous and Next walk the filtered questions. |
| Panes | `TopikTwoPaneWidget` (screen 37's) | The group pane on top, the question pane below (V1). |
| Group material | `TopikGroupPaneWidget`, as on 37 | Instruction, passage or picture, collapsible; a listening group's `TopikAudioBarWidget` with its Practice controls (V10, BR-TOPIK-017) and the script with its translation, open by default; the person can hide it, per group. |
| Content banner | `MxInlineBanner` (warning) | At the head of the question pane, only when the content changed after the attempt (V4, BR-TOPIK-019). |
| Question | `TopikReviewQuestionWidget`: stem + four `MxChoiceTile`s | The right option in `right`, the person's wrong choice in `wrong`, the rest idle; every option inert (V2, BR-TOPIK-010). Under them "Your answer ② · Right answer ③", or "Not answered · Right answer ③". TalkBack reads each option with its state ("the right answer", "your answer, wrong"). |
| Supporting content | `MxSection`s | Explanation · Translation · Words (Korean, part of speech, meaning) · Grammar (pattern, meaning), in the UI language; a section without data is absent (V3, A2). |
| Footer | `MxFooterBar` with `MxActionPair` | "Previous" (outline, off on the filter's first question) · "Next" (primary); on the filter's last question "Next" becomes "Done", which leaves (V7). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| wrong | `topik_review_wrong_light.png` | `topik_review_wrong_dark.png` | A wrong answer with explanation and words. |
| correct | `topik_review_correct_light.png` | `topik_review_correct_dark.png` | A right answer, no supporting content. |
| unanswered | `topik_review_unanswered_light.png` | `topik_review_unanswered_dark.png` | Not answered: only the right option marked. |
| listening | `topik_review_listening_light.png` | `topik_review_listening_dark.png` | Audio bar and the open script. |
| contentUpdated | `topik_review_updated_light.png` | `topik_review_updated_dark.png` | The banner "This test was updated after this attempt". |
| contentMissing | `topik_review_content_missing_light.png` | `topik_review_content_missing_dark.png` | The test is gone: `MxEmptyState` (neutral) "Review isn't available for this test" with "Back to summary"; no footer. |
| attemptMissing | `topik_review_missing_light.png` | `topik_review_missing_dark.png` | Deleted elsewhere, the account switched, or not submitted: `MxEmptyState`, "Back to the test"; no footer. |
| loading | `topik_review_loading_light.png` | `topik_review_loading_dark.png` | `MxSkeletonList` in a full-bleed card; no footer. |
| error | `topik_review_error_light.png` | `topik_review_error_dark.png` | `MxErrorState` "Couldn't load this review" with Retry; no footer (V8). |

**Built (plan 6c, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_review_screen_test.dart`, `topik_review_question_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | read done | the question asked (`?q=`, under All), or the first when the number is unknown | V9, UC-TOPIK-005 A3. VERIFIED `topik_review_screen_test.dart::opens the question asked, with its real number; an unknown number opens the first (UC-TOPIK-005, A3)`, `::TOPIK I reading: ?q=31 opens question 31 (BR-TOPIK-001)` |
| any loaded | Next / Previous | the next or previous question in the filter | UC-TOPIK-005 step 4. VERIFIED `::Next and Previous walk the filter; a filter opens its first question; the last says Done (UC-TOPIK-005 step 4)` |
| any loaded | filter | the filter's first question | V5. VERIFIED same test |
| any loaded | a filter with no question | no change (the chip is off) | V5. VERIFIED `::a filter with no question cannot be picked` |
| any loaded | tap an option | no change, nothing written | BR-TOPIK-010. VERIFIED `::an option tapped changes nothing and writes nothing (BR-TOPIK-010)` |
| loading | content version differs | contentUpdated | BR-TOPIK-019. VERIFIED `::content updated after the attempt: the banner (BR-TOPIK-019)` |
| loading | content missing | contentMissing | BR-TOPIK-019. VERIFIED `::the test gone: Review is unavailable, Back to summary (BR-TOPIK-019)` |
| contentMissing | Back to summary | 38 | V8. VERIFIED same test (the callback); the route goes to 38 by its path |
| any | attempt deleted elsewhere | attemptMissing | UC-TOPIK-005 E2. VERIFIED `::the attempt deleted elsewhere, or still in progress: missing (UC-TOPIK-005 E2)` |
| deep link | attempt still in progress | attemptMissing | V8. VERIFIED same test |
| any | account switched | attemptMissing | UC-TOPIK-005 E2, BR-TOPIK-027. UNVERIFIED on this screen: the switch clears the store (`LocalDataReset`) and the stream emits null, the path the delete row exercises; no screen test drives a switch (as on 36 and 37) |
| error | Retry | loading → loaded | V8. VERIFIED `::a read that fails: Retry reads again` |
| listening question | show | the audio bar loaded, not playing; the script open | BR-TOPIK-017. VERIFIED `::listening: the audio bar and the script, open (BR-TOPIK-017)` |
| any loaded | Back / Done on the last | where it came from (38 or 36; TOPIK when opened alone) | navigation. VERIFIED `topik_routes_test.dart::from the summary a row opens Review at its question; Back returns to the summary (UC-TOPIK-004 step 7)`; Done shares Back's callback (`::Next and Previous walk the filter; …`) |

## Rulings

- **Brief 2026-10-15:** the right and wrong option states reuse `MxChoiceTile`'s study states, so a right answer looks the same in study and in TOPIK.
- Explanations show in the UI language only; both languages always exist (BR-TOPIK-006).
- **V1 (plan 6c):** screen 37's two panes; the script is open by default and the person can hide it; the chips sit above the panes.
- **V2 (plan 6c):** `MxChoiceTile` right / wrong / idle, every option inert; the answer line under the options.
- **V3 (plan 6c):** supporting sections in the UI language; a section without data is absent.
- **V4 (plan 6c):** the content banner heads the question pane.
- **V5 (plan 6c):** chips carry counts; an empty chip is off; a filter opens its first question.
- **V6 (plan 6c):** the title carries the real numbers; Back in the leading slot.
- **V7 (plan 6c):** Previous off on the filter's first question; Next becomes Done on its last.
- **V8 (plan 6c):** contentMissing (neutral, Back to summary), attemptMissing, loading and error with Retry; an attempt not submitted reads as attemptMissing.
- **V9 (plan 6c):** `?q=` opens that question under All; an unknown number opens the first.
- **V10 (plan 6c):** the audio bar of 37, with its Practice controls.

## Copy

- App bar: "Review · {no} / {last}" · "Review".
- Filters: as on 38.
- Question: "{no}. {stem}" · "Your answer {option}" · "Right answer {option}" · "Not answered"; TalkBack "Option {number}, {text}, {state}" with "the right answer" · "your answer, wrong".
- Sections: "Explanation" · "Translation" · "Words" · "Grammar"; group pane "Show passage" · "Hide passage" · "Show script" · "Hide script".
- Banner: "This test was updated after this attempt" · "Your score stays as it was."
- Footer: "Previous" · "Next" · "Done".
- Content missing: "Review isn't available for this test" · "Your score is still in the summary." · "Back to summary".
- Attempt missing: "This attempt isn't here any more" · "Back to the test".
- Error: "Couldn't load this review" · the failure's body · "Retry". Loading: "Loading the review" (TalkBack).
