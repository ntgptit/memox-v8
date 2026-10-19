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
| Filters | `TopikAnswerFilterChipsWidget` above the panes | All · Wrong · Unanswered · Correct, counts in the chip's count slot; a chip with no question is off (`isEmptyDisabled`); picking a filter opens its first question (V5). Previous and Next walk the filtered questions. The row scrolls sideways at 360 dp inside an `MxScrollFade` (audit 2026-10-17 TOPIK-2). |
| Shell | `MxAppShell(isSession: true)` | The session column, the same as 37 (The Column Rule): from 600 dp the stacked panes keep 37's line length instead of the wide column's (Impeccable audit 2026-10-17, P2-2). The plain shell of the states without a question has no `isSession`, as 37's. |
| Panes | `TopikTwoPaneWidget` (screen 37's) | The group pane on top, the question pane below (V1). |
| Group material | `TopikGroupPaneWidget`, as on 37 | Instruction, passage or picture, collapsible; a listening group's `TopikAudioBarWidget` with its Practice controls (V10, BR-TOPIK-017) and the script with its translation, open by default; the person can hide it, per group. |
| Content banner | `MxInlineBanner` (warning) | At the head of the question pane, only when the content changed after the attempt (V4, BR-TOPIK-019). |
| Question | `TopikReviewQuestionWidget`: `MxScreenScroll` in an `MxScrollFade` (page ground), stem + four `MxChoiceTile`s | The pane fades its bottom edge while more lies below, as 37's (owner 2026-10-17); VERIFIED `topik_review_screen_test.dart::a question taller than its pane fades the pane's bottom edge, and the fade goes at the end of the scroll (owner 2026-10-17)`. The right option in `right`, the person's wrong choice in `wrong`, the rest idle; every option inert (V2, BR-TOPIK-010). Under them "Your answer ② · Right answer ③", or "Not answered · Right answer ③". TalkBack reads each option with its state ("the right answer", "your answer, wrong"), and the answer line with plain digits ("Your answer 3, Right answer 1"; the circled digits are painted only; VERIFIED `topik_review_question_test.dart::a wrong answer: the right option right, the choice wrong, nothing tappable; the explanation and the words in the UI language`). |
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
| contentMissing | `topik_review_content_missing_light.png` | `topik_review_content_missing_dark.png` | The test is gone, or no longer has the attempt's questions (a question dropped, renumbered or added, or a question whose group is gone): `MxEmptyState` (neutral) "Review isn't available for this test" with "Back to summary"; no footer, no error (BR-TOPIK-019). The match is `topikContentMatchesAttempt`, the one helper 37 uses for its contentMissing. VERIFIED `topik_review_screen_test.dart::a test whose question set no longer matches the attempt shows the unavailable state, not an error (BR-TOPIK-019)`; the helper: `test/features/topik/domain/topik_views_test.dart::a dropped question does not match`, `::a question added to the test does not match`, `::a question whose group is missing does not match`. |
| attemptMissing | `topik_review_missing_light.png` | `topik_review_missing_dark.png` | Deleted elsewhere, the account switched, or not submitted: `MxEmptyState`, "Back to the test"; no footer. |
| loading | `topik_review_loading_light.png` | `topik_review_loading_dark.png` | `MxSkeletonList` in a full-bleed card; no footer. |
| error | `topik_review_error_light.png` | `topik_review_error_dark.png` | `MxErrorState` "Couldn't load this review" with Retry; no footer (V8). |
| lastQuestion | (no golden) | (no golden) | The footer's Next reads "Done" and leaves. VERIFIED (label and callback) `topik_review_screen_test.dart::Next and Previous walk the filter; a filter opens its first question; the last says Done (UC-TOPIK-005 step 4)`; the frame itself `UNVERIFIED`. |
| groupCollapsed / scriptHidden | (no golden) | (no golden) | The shared pane folded to its instruction, or the script hidden (remembered per group while 39 is open). Tested on the shared pane (37's tests) and on 39 itself. VERIFIED (closing acceptance 2026-10-18): `topik/presentation/topik_review_state_coverage_test.dart::groupCollapsed: Hide passage folds the shared pane to its instruction and Show passage opens it again`; `::scriptHidden: Hide script hides a listening group's script; the choice is remembered for that group while the review is open` |
| audioFailed / audioLoading / speedSheet | (no golden) | (no golden) | The shared audio bar's own states: the warning banner with Retry, Play off while the clip loads, the speed sheet. VERIFIED on the bar `topik_audio_bar_test.dart::a clip that fails is a warning; Retry loads it again`, `::the speed sheet sets the speed`; `UNVERIFIED` on 39 (no 39 golden or screen test). |
| pictureOption | (no golden) | (no golden) | An option or passage that is a picture (`Image.asset`, "Picture" to TalkBack). No golden; no bundled content has pictures yet, so the test uses a bundled picture. VERIFIED (closing acceptance 2026-10-18): `topik/presentation/topik_review_state_coverage_test.dart::pictureOption: a passage and options that are pictures draw them, read "Picture" to TalkBack, and keep their review tones` |

**Built (plan 6c, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_review_screen_test.dart`, `topik_review_question_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | read done | the question asked (`?q=`, under All), or the first when the number is unknown | V9, UC-TOPIK-005 A3. VERIFIED `topik_review_screen_test.dart::opens the question asked, with its real number; an unknown number opens the first (UC-TOPIK-005, A3)`, `::TOPIK I reading: ?q=31 opens question 31 (BR-TOPIK-001)` |
| any loaded | Next / Previous | the next or previous question in the filter | UC-TOPIK-005 step 4. VERIFIED `::Next and Previous walk the filter; a filter opens its first question; the last says Done (UC-TOPIK-005 step 4)` |
| any loaded | another filter | the filter's first question, even when the one shown is in it | V5, UC-TOPIK-005 A3. VERIFIED `::a filter opens its first question, even when the one shown is in it (UC-TOPIK-005 A3)` |
| any loaded | the selected filter again | no change: the place is kept | V5. VERIFIED `::the selected filter tapped again keeps the place` |
| any loaded | a filter with no question | no change (the chip is off) | V5. VERIFIED `::a filter with no question cannot be picked` |
| any loaded | tap an option | no change, nothing written | BR-TOPIK-010. VERIFIED `::an option tapped changes nothing and writes nothing (BR-TOPIK-010)` |
| loading | content version differs | contentUpdated | BR-TOPIK-019. VERIFIED `::content updated after the attempt: the banner (BR-TOPIK-019)` |
| loading | content missing | contentMissing | BR-TOPIK-019. VERIFIED `::the test gone: Review is unavailable, Back to summary (BR-TOPIK-019)` |
| loading | the test keeps its id but its question set no longer matches the attempt | contentMissing (not error) | BR-TOPIK-019. VERIFIED `::a test whose question set no longer matches the attempt shows the unavailable state, not an error (BR-TOPIK-019)` (before 2026-10-17 the screen threw a `StateError` from `firstWhere`; the fix is the domain helper `topikContentMatchesAttempt`, shared with 37) |
| contentMissing | Back to summary | 38 | V8. VERIFIED same test (the callback); the route goes to 38 by its path |
| any | attempt deleted elsewhere | attemptMissing | UC-TOPIK-005 E2. VERIFIED `::the attempt deleted elsewhere, or still in progress: missing (UC-TOPIK-005 E2)` |
| deep link | attempt still in progress | attemptMissing | V8. VERIFIED same test |
| any | account switched | attemptMissing | UC-TOPIK-005 E2, BR-TOPIK-027. UNVERIFIED on this screen: the switch clears the store (`LocalDataReset`) and the stream emits null, the path the delete row exercises; no screen test drives a switch (as on 36 and 37) |
| error | Retry | error (retrying) → the state of the next read | V8. VERIFIED `::a read that fails: Retry reads again` (the second read lands on attemptMissing, so the retry-to-content branch is `UNVERIFIED`; the error stays up with its retry in progress, no skeleton) |
| listening question | show | the audio bar loaded, not playing; the script open | BR-TOPIK-017. VERIFIED `::listening: the audio bar and the script, open (BR-TOPIK-017)` |
| any loaded | Next / Previous / another filter | the new question is announced to TalkBack: the painted "{no}. {stem}" is a polite live region (`TopikReviewQuestionWidget`; 39's title sits in `MxAppBar`, which takes a String) | WCAG 4.1.3, Impeccable audit 2026-10-17 P2-1 (owner approved the local fix). VERIFIED `topik_review_screen_test.dart::the question change is announced: the stem is a live region whose label follows Next (WCAG 4.1.3)` |
| any loaded | collapse / expand the group pane | the material folds to its instruction (audio kept), and back | V1. VERIFIED on the shared pane `topik_attempt_widgets_test.dart::the group pane: instruction, passage; collapsed it keeps the instruction on one line`, `::a listening group: the audio stays when collapsed; the script shows with its translation in the UI language`; UNVERIFIED on 39 itself: no 39 test taps the collapse |
| any loaded | Hide / Show script | the group's script hidden or shown, remembered per group while 39 is open | V1. UNVERIFIED on 39: the shared pane's toggle is tested on 37 (`topik_attempt_widgets_test.dart`); 39's per-group memory (`_scriptChoice`) is read from the code only |
| any loaded | Back / Done on the last | where it came from (38 or 36; TOPIK when opened alone) | navigation. VERIFIED `topik_routes_test.dart::from the summary a row opens Review at its question; Back returns to the summary (UC-TOPIK-004 step 7)`; Done shares Back's callback (`topik_review_screen_test.dart::Next and Previous walk the filter; a filter opens its first question; the last says Done (UC-TOPIK-005 step 4)`) |
| any loaded | language changes | the explanation, words and labels in the UI language; the Korean stays | BR-TOPIK-006, UC-TOPIK-005 A4. VERIFIED (rendered in vi) `topik_review_screen_test.dart::in Vietnamese, the explanation and the words read in Vietnamese; the Korean stays (BR-TOPIK-006, UC-TOPIK-005)` |

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
- **Audit 2026-10-16 (DEV-394):** UC-TOPIK-005 A3 is rewritten to V5 and V9 as built (a question outside the current filter cannot occur). The right option marked is the snapshot's `correct_idx` (`topik_review_question_widget.dart`), while the stem, options and supporting content are the current content's: after an `answerIdx` correction the old index stays marked beside a current explanation. OPEN QUESTION Q-A-8: mark the current content's `answerIdx` as right (Review teaches the truth; the score stays from the snapshot and the banner says so) or keep the snapshot's. Code unchanged until the owner rules. "Back to summary" uses `go`, so Done on that summary lands on TOPIK home, not 36 (owner ruling Q-P6c, 2026-10-16: as built).
- **Impeccable fix 2026-10-17 (owner approved):** the loaded shell is the session column (`isSession: true`), as 37's, so the stacked panes keep one line length on a tablet; `UNVERIFIED (code read)` above compact width: no test or golden renders 39 at 600 dp or more. The question pane fades its bottom edge (Layout). The answer line speaks plain digits.
- **Q-A-8 stays open** (the right option marked is the snapshot's `correct_idx`; see Audit 2026-10-16): nothing in this batch changes it.
- **Impeccable audit 2026-10-17 (P3, not changed):** the right and wrong marks are colour and edge only, no glyph (the answer line and the TalkBack label carry them; a glyph in `MxChoiceTone.right` / `wrong` is a shared-tile change, which also benefits Guess on 18). On a listening question the group pane takes about half the body, so at rest the answer line sits at the footer and the explanation below the fold (the script is open by default, ruled V1). Three English titles wrap at 360 dp ("This test was updated after this attempt", "Review isn't available for this test", "This attempt isn't here any more"); shorter copy is the owner's. The loading skeleton is a generic list, not the screen's panes. A script-only listening group shows the chevron named "Hide passage" next to "Hide script" (shared pane, 37 and 39 together). `topikAttemptSummaryOf` is rebuilt on every `setState` (at most 70 answers; no cost seen). All `UNVERIFIED (code read or golden read)`.
- **Q-C-2 (owner, 2026-10-16):** in Words and Grammar the word, its part of speech and the pattern stay whole terms (The Wrap Rule); the meaning is authored prose and breaks between its words.

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
