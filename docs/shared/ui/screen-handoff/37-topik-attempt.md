<!-- Hand-written screen record. -->

# 37 · TOPIK attempt

Taking a test in Practice mode (UC-TOPIK-003, BR-TOPIK-010…BR-TOPIK-017, BR-TOPIK-019). Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §5, §8, §13.6, brief of 2026-10-15; built by plan 6b (`docs/superpowers/plans/2026-10-15-topik-screen-attempt.md`).

## Entry points

- The FAB, Continue or "Start new" on screen 36; a row of 36 in progress (Recent or History).
- Deep link `/study/topik/attempt/:attemptId` (root navigator, full screen, no tab bar). Close returns where it came from, or to TOPIK home when it was opened alone.

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Close (saves and leaves, no dialog); mode "Practice" (painted upper-case); the thin track is the position of the current question (critique F2: the bar's contract is 1-based); counter "{no} / {last}" with the real numbers (TOPIK I reading 31–70, BR-TOPIK-001). |
| Group pane (top) | `TopikTwoPaneWidget` + `TopikGroupPaneWidget` | On the recessed ground (`surfaceContainerLow`, The Tone Before Shadow Rule), at most half the body, scrolling on its own (F5). The instruction ("※ …", `bodyMedium` `onSurfaceVariant`) with a text button "Hide passage" / "Show passage"; then the audio bar (listening); the passage (`bodyLarge`, Korean) or picture; for a group with a script, "Show script" / "Hide script" and, when shown, the script (`bodyMedium`) and its translation in the UI language (`onSurfaceVariant`). Collapsed, it keeps the instruction on one line and the audio bar. |
| Audio bar | `TopikAudioBarWidget` | Two lines (impeccable after 6b, so the seek bar has the pane's width): play-circle / pause-circle `MxIconButton` and the `MxSlider` seek bar; then "0:42 / 1:33" in `labelSmall` (no tabular figures: The Twelve Roles Rule, F6) and the speed `MxChipTrigger` "1×" opening a sheet of four `MxOptionRow`s (0.75, 1, 1.25, 1.5). Error: an `MxInlineBanner` (warning) "Couldn't play this audio" · "Your answers are safe." with "Retry" (BR-TOPIK-017). |
| Question pane (bottom) | `TopikQuestionPaneWidget` in `MxScreenScroll` | "{no}. {stem}" (`bodyLarge`, Korean), then four `MxChoiceTile`s "① …" in `bodyLarge` (F3), idle or selected only (BR-TOPIK-016). |
| Footer | `TopikAttemptFooterWidget` in `MxFooterBar` | Previous as an `MxIconButton` (back glyph, off on the first question) · "Questions" `MxButton` outline taking the rest of the row · "Next" primary; on the last question "Submit" primary (F1: three labelled buttons do not fit 360 dp). |
| Question grid | `showTopikQuestionGrid` (`MxBottomSheet`) | "Questions", one cell per question with its real number, as many control-wide columns as fit, the cells sharing the row; answered cells in the accent tinted over the sheet, blank cells with no ground and an `outlineVariant` hairline (impeccable after 6b: two grounds read alike in dark), the current one with a `primary` edge; each cell an `MxRowInk`, one node "Question {no}, answered / not answered" with `isSelected` on the current one; "Submit" (`MxSheetActions.single`) at the foot. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| answering | `topik_attempt_reading_light.png` | `topik_attempt_reading_dark.png` | Reading, a passage group, an option selected. |
| answeringListening | `topik_attempt_listening_light.png` | `topik_attempt_listening_dark.png` | Listening, the audio bar paused at 0:12 of 0:30, script hidden. |
| scriptShown | `topik_attempt_script_light.png` | `topik_attempt_script_dark.png` | The script and its translation in the group pane (after answering or by the toggle). |
| collapsed | `topik_attempt_collapsed_light.png` | `topik_attempt_collapsed_dark.png` | The group pane collapsed to its instruction line. |
| grid | `topik_attempt_grid_light.png` | `topik_attempt_grid_dark.png` | The question grid sheet. |
| submitConfirm | `topik_attempt_submit_confirm_light.png` | `topik_attempt_submit_confirm_dark.png` | `showMxConfirm` "3 questions unanswered". |
| submitting | `topik_attempt_submitting_light.png` | `topik_attempt_submitting_dark.png` | Submit spins; options, Previous, Questions are off; Back does nothing. |
| audioError | `topik_attempt_audio_error_light.png` | `topik_attempt_audio_error_dark.png` | The audio banner with Retry; answering still works. |
| attemptMissing | `topik_attempt_missing_light.png` | `topik_attempt_missing_dark.png` | Deleted elsewhere or the account changed: neutral `MxEmptyState`, "Back to the test". |
| contentMissing | `topik_attempt_content_missing_light.png` | `topik_attempt_content_missing_dark.png` | The test is gone or no longer has the attempt's questions: `MxEmptyState` (warning) offering "Delete attempt" (BR-TOPIK-019). |
| submitted | `topik_attempt_submitted_light.png` | `topik_attempt_submitted_dark.png` | A link to an attempt already submitted: neutral `MxEmptyState` "This attempt was submitted" with "See summary". |
| loading | `topik_attempt_loading_light.png` | `topik_attempt_loading_dark.png` | The plain bar with Close, a skeleton. |
| error | `topik_attempt_error_light.png` | `topik_attempt_error_dark.png` | `MxErrorState` with Retry; Close stays. |

**Built (plan 6b, 2026-10-15).** Every state has its light and dark golden under `test/features/topik/presentation/goldens/`. A transition is VERIFIED by the executed test it names (`topik_attempt_screen_test.dart`, `topik_attempt_screen_states_test.dart`, `topik_attempt_controller_test.dart`, `test/app/topik_routes_test.dart`); a row no test executes says UNVERIFIED and why. The states without content (loading, error, attemptMissing, contentMissing, submitted) show the plain bar with Close and no footer or grid (The Content Gate Rule, F8).

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | attempt and test read | answering at `current_question_no` | BR-TOPIK-010, BR-TOPIK-011. VERIFIED `topik_attempt_screen_test.dart::opens at the attempt's current question, with the real numbers (BR-TOPIK-010, -011, -001)` |
| answering | pick an option | answering, choice saved, no right/wrong shown | BR-TOPIK-012, BR-TOPIK-016. VERIFIED `::a pick is saved at once and shows only as chosen (BR-TOPIK-012, -016)` |
| answering | Next / Previous / grid cell | answering at that question; time of the question left written | BR-TOPIK-015. VERIFIED `::Next, Previous and a grid cell move; the time of the question left is written (BR-TOPIK-015)`, `topik_attempt_controller_test.dart::time goes to the question that was current, adds up when the person returns, and stops in the background (BR-TOPIK-015)` |
| answering (same group) | move to the group's other question | audio as it is, group pane kept | BR-TOPIK-017. VERIFIED `topik_attempt_screen_states_test.dart::listening: the group loads its clip, never plays it, and keeps it across its questions; another group loads its own (BR-TOPIK-017)` |
| answering | move to another group | its own clip loaded, none played; the previous one paused by the player | BR-TOPIK-017. VERIFIED same test (the load); the pause is the plan-5 repository's (`topik_audio_repository_impl_test.dart`) |
| answering | app to background, then back | no time runs while away; the time so far written | BR-TOPIK-015. VERIFIED `::in the background no time runs (BR-TOPIK-015)`, `topik_attempt_controller_test.dart::a pause while paused writes nothing more` |
| answering | Close / Back | 36 (or TOPIK home when opened alone); attempt still in progress with its answers and time | BR-TOPIK-010, UC-TOPIK-003 A2. VERIFIED `::Close leaves with nothing lost: the attempt stays in progress with its answer and its time (BR-TOPIK-010)`, `topik_routes_test.dart::an attempt opens full screen above the tab bar, and Close returns to the test (spec §8)`, `::a deep link to an attempt opens it; Close lands on TOPIK` |
| answering | process death | on reopen, the attempt in progress with its answers; the time since the last write lost | Spec §5.4. UNVERIFIED: no test kills the process; every answer, move and background transition writes (the rows above) |
| answering | Submit with blanks | submitConfirm | BR-TOPIK-014. VERIFIED `::Submit with blanks asks; Keep answering stays; Submit submits and opens the summary (BR-TOPIK-013, -014)` |
| submitConfirm | Keep answering | answering | BR-TOPIK-014. VERIFIED same test |
| submitConfirm / answering (no blank) | Submit | submitting → 38 (replaces 37) | BR-TOPIK-013. VERIFIED same test, `::with every question answered, Submit does not ask`; route 38 is plan 6c's |
| submitting | second tap / Back | no effect | BR-TOPIK-014. VERIFIED `::while submitting, a second tap and Back do nothing (BR-TOPIK-014)`, `topik_attempt_controller_test.dart::a second submit, and every answer after one, is ignored (BR-TOPIK-014)` |
| submitting | submit refused (the test left) | answering + snackbar; the person goes on | BR-TOPIK-019. VERIFIED `topik_attempt_controller_test.dart::a refused submit lets the person go on` (controller); the snackbar is the shared refusal path of `::a choice that is not saved…` |
| answeringListening | play fails | audioError | BR-TOPIK-017. VERIFIED `::audio that fails is a warning; answering still works (BR-TOPIK-017)`, `topik_audio_bar_test.dart::a clip that fails is a warning; Retry loads it again` |
| audioError | Retry | answeringListening | BR-TOPIK-017. VERIFIED `topik_audio_bar_test.dart::a clip that fails is a warning; Retry loads it again` |
| answering | the script toggle, or answering the question | scriptShown; the person's own hide wins | Spec §5.5, D15. VERIFIED `::the script shows once the question is answered, or by its toggle (spec §5.5, D15)` |
| answering | Hide passage / Show passage | collapsed / answering | Critique F5. VERIFIED `topik_attempt_widgets_test.dart::the group pane: instruction, passage; collapsed it keeps the instruction on one line` |
| any | attempt deleted | attemptMissing; Back to the test leaves | UC-TOPIK-003 E2. VERIFIED `::the attempt deleted elsewhere: missing, and Back to the test leaves (UC-TOPIK-003 E2)` |
| any | account switched | attemptMissing | UC-TOPIK-003 E2, BR-TOPIK-027. UNVERIFIED on this screen: the switch clears the store (`LocalDataReset`) and the stream emits null, the path the delete row exercises; no screen test drives a switch |
| loading | test no longer valid | contentMissing | BR-TOPIK-019. VERIFIED `::the test changed: the attempt offers Delete, which leaves (BR-TOPIK-019)` |
| contentMissing | Delete attempt, confirmed | the attempt deleted; leaves | BR-TOPIK-019. VERIFIED same test |
| loading | the attempt is submitted (a link) | submitted; See summary → 38 | Plan 6b. VERIFIED `::a link to a submitted attempt offers its summary` |
| loading | the read fails | error; Retry → loading | Plan 6b. VERIFIED `::a read that fails: Retry reads again; Close stays` |
| any | write fails | same state + snackbar "Your choice wasn't saved. Try again.", the choice not shown as saved | UC-TOPIK-003 E4. VERIFIED `::a choice that is not saved says so and is not shown as chosen (UC-TOPIK-003 E4)` |
| any | language changes | same question, relabelled; answers and time kept | UC-TOPIK-003 A4. VERIFIED for the labels (`::in Vietnamese: the same question, relabelled; the Korean stays (UC-TOPIK-003 A4)`, pumped in Vietnamese); a live switch rebuilds from the same stream, no test drives it |

## Accessibility

- Each `MxChoiceTile` is one node: "Option {n}, {text}", with its selected state and its tap (`topik_attempt_widgets_test.dart`).
- The seek bar is one node: "Audio position", value "{position} / {length}" (`topik_audio_bar_test.dart::the seek bar says where it is, of how long`); play/pause have their own labels.
- Each grid cell is one node: "Question {no}, answered / not answered", selected when current (`topik_attempt_widgets_test.dart::the grid…`).
- Reduced motion: the pane collapses at once (no animation); the sheets follow `showMxBottomSheet`.
- Keyboard focus ring on the options: none yet, as on Guess and Match (DEV-391, the choice surface's focus ring).

## Rulings

- **Brief 2026-10-15 (owner):** two panes, the passage on top scrolling on its own and collapsible; one question per page (spec §5.4: one current question).
- **Brief 2026-10-15 (owner):** `StudyChoiceWidget` moves to `lib/shared` as `MxChoiceTile`; screen 16–20 goldens did not change (plan 6b Task 1).
- **Brief 2026-10-15 (owner):** the new widgets live in `lib/features/topik/presentation/widgets/` on tokens only, until a second feature needs them.
- Close needs no dialog: nothing is lost by leaving (BR-TOPIK-010).
- **PR #283:** no raw `Slider` or `InkWell` in feature code: the seek bar is `MxSlider`, every grid cell an `MxRowInk`; both panes sit on `context.screenMargin`.
- No clock on screen in the MVP: time is measured, not displayed while answering (spec §5.4); Summary shows it.
- **Plan 6b (critique F1):** Previous is a glyph so three actions fit 360 dp; "Questions" is outline; Next / Submit is the one primary.
- **Plan 6b (F2):** the top bar's track is the position, as its counter; answered versus blank lives in the grid.
- **Plan 6b (F3):** stem and options are `bodyLarge` (content read like the passage), not the Tile-body role of a study option (owner question Q-P6b-3).
- **Plan 6b (F4):** the selected option's primary fill is a state of the choice surface, not a second action.
- **Plan 6b (F5):** the collapse control is a text button: `AppIcons` has no chevron-up (owner question Q-P6b-4); collapsing keeps the audio bar, so audio is never stopped by a collapse.
- **Plan 6b (F6):** the audio time has no tabular figures (The Twelve Roles Rule); the speed is a sheet of `MxOptionRow`s.
- **Plan 6b (F7):** grid cells fill the sheet's width; answered tinted, blank edged, current with a primary edge.
- **Plan 6b (F8):** loading, error and the gone states have no footer or grid; Close stays.
- **Plan 6b (F9):** while submitting the screen is held (`PopScope`), options and footer off; after a successful submit it stays held until `app/` replaces it with 38.
- **Plan 6b (F10–F14):** contentMissing deletes through `showTopikDeleteDialog`; the write failure keeps the option unselected; the script toggle is a text button and its translation follows the UI language; pictures read "Picture" to TalkBack (UNVERIFIED: no bundled content has pictures yet); options read "Option {n}, {text}" with the selected state on the node.
- **Plan 6b:** two states the shape lacked are added: `error` (a read that fails) and `submitted` (a link to a submitted attempt) (owner question Q-P6b-5).

## Copy

- Top bar: "Practice" · "Close" · "{no} / {last}".
- Group pane: "Hide passage" · "Show passage" · "Show script" · "Hide script" · "Picture".
- Audio: "Play" · "Pause" · "Audio position" · "{position} / {length}" · "{speed}×" · "Playback speed" · "Couldn't play this audio" · "Your answers are safe." · "Retry".
- Question: "{no}. {stem}" · "Option {n}, {text}".
- Footer: "Previous" · "Questions" · "Next" · "Submit".
- Grid: "Questions" · "Question {no}, answered" · "Question {no}, not answered" · "Submit".
- Submit confirm: "{n} questions unanswered" · "Unanswered questions score 0. Submit anyway?" · "Submit" · "Keep answering".
- Missing: "This attempt isn't here any more" · "Back to the test".
- Content missing: "This test changed and can't be continued" · "Delete attempt" (then "Delete this attempt?" · "Delete").
- Submitted: "This attempt was submitted" · "See summary".
- Error: "Couldn't load this attempt" · "Nothing was lost. Try again." · "Retry".
- Loading: "Loading the attempt".
- Write failure: "Your choice wasn't saved. Try again."
