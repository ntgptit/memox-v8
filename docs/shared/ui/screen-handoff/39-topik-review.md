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
| App bar | `MxAppBar` | "Review · {no} / {last}". |
| Filters | `MxChipRow` of `MxFilterChip`s | All · Wrong · Unanswered · Correct; Previous and Next walk the filtered questions. |
| Content banner | `MxInlineBanner` (warning) | Only when the content changed after the attempt (BR-TOPIK-019). |
| Group material | as on 37 | Instruction, passage or picture, audio bar (Practice controls) and the script with its translation, shown open. |
| Question | stem + four `MxChoiceTile`s | The right option in its right state; the user's wrong choice in its wrong state; an unanswered question marks only the right option and says "Not answered". Nothing is tappable to change (BR-TOPIK-010). |
| Supporting content | `MxSection`s | Explanation · Translation · Words (Korean, part of speech, meaning) · Grammar (pattern, meaning), in the UI language; a section without data is absent (A2). |
| Footer | `MxFooterBar` | "Previous" (outline) · "Next" (primary); on the last filtered question "Next" becomes "Done". |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| wrong | `topik_review_wrong_light.png` | `topik_review_wrong_dark.png` | A wrong answer with explanation and words. |
| correct | `topik_review_correct_light.png` | `topik_review_correct_dark.png` | A right answer, no supporting content. |
| unanswered | `topik_review_unanswered_light.png` | `topik_review_unanswered_dark.png` | Not answered. |
| listening | `topik_review_listening_light.png` | `topik_review_listening_dark.png` | Audio bar and the open script. |
| contentUpdated | `topik_review_updated_light.png` | `topik_review_updated_dark.png` | The banner "This test was updated after this attempt". |
| contentMissing | `topik_review_content_missing_light.png` | `topik_review_content_missing_dark.png` | The test is gone: `MxEmptyState` (neutral) "Review isn't available for this test" with "Back to summary". |
| attemptMissing | `topik_review_missing_light.png` | `topik_review_missing_dark.png` | `MxEmptyState`, "Back to the test". |

**Not built yet (status `shaped`).** Goldens are the planned names under `test/features/topik/presentation/goldens/`; every transition's evidence is the rule it implements and the widget or controller test the screen's plan adds. Each row turns `VERIFIED` only with an executed test.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| any loaded | Next / Previous | the next or previous question in the filter | UC-TOPIK-005 step 4 |
| any loaded | filter | first question of the filter; opened question outside it → All | UC-TOPIK-005 A3 |
| any loaded | tap an option | no change, nothing written | BR-TOPIK-010 |
| loading | content version differs | contentUpdated | BR-TOPIK-019 |
| loading | content missing | contentMissing | BR-TOPIK-019 |
| any | attempt deleted elsewhere or account switched | attemptMissing | UC-TOPIK-005 E2 |
| any loaded | Back / Done | where it came from (38 or 36) | navigation |

## Rulings

- **Brief 2026-10-15:** the right and wrong option states reuse `MxChoiceTile`'s study states, so a right answer looks the same in study and in TOPIK.
- Explanations show in the UI language only; both languages always exist (BR-TOPIK-006).

## Copy

- App bar: "Review · {no} / {last}".
- Filters: as on 38.
- Question: "Not answered" · "Your answer" · "Right answer".
- Sections: "Explanation" · "Translation" · "Words" · "Grammar" · "Script".
- Banner: "This test was updated after this attempt" · "Your score stays as it was."
- Footer: "Previous" · "Next" · "Done".
- Missing: "Review isn't available for this test" · "Your score is still in the summary." · "Back to summary".
