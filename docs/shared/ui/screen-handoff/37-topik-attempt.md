<!-- Hand-written screen record. -->

# 37 · TOPIK attempt

Taking a test in Practice mode (UC-TOPIK-003, BR-TOPIK-010…BR-TOPIK-017). Shape: the [TOPIK spec](../../../superpowers/specs/2026-10-15-topik-practice-design.md) §5, §8,
§13.6, brief of 2026-10-15.

## Entry points

- The FAB, Continue or "Start new" on screen 36; Continue on a row of 36.
- Deep link `/study/topik/attempt/:attemptId` (root navigator, full screen).

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Close (saves and leaves, no dialog); mode label "Practice"; the thin progress track = answered / count; counter "{no} / {last}" with the real numbers (TOPIK I reading 31–70, BR-TOPIK-001). |
| Group pane (top) | `TopikTwoPaneLayout` (new, topik) | The group's instruction ("※ [21～22] …", `bodyMedium`), passage (`bodyLarge`, Korean) or picture, and for listening the audio bar and the "Show script" toggle. It scrolls on its own, takes the height it needs up to about half the body, and has a collapse / expand `MxIconButton`. A question with no shared material has no top pane. |
| Audio bar | `TopikAudioBar` (new, topik) | Play / pause `MxIconButton`, a seek `Slider` read from a new `sliderTheme` slot (component admission, flutter-theme-design), "0:42 / 1:33" in `labelSmall` tabular, a speed `MxChipTrigger` "1×" opening the four speeds. Error: an inline `MxInlineBanner` (warning) "Couldn't play this audio" with "Try again" (BR-TOPIK-017). |
| Question pane (bottom) | `MxScreenScroll` | The stem (`bodyLarge`, Korean), then four `MxChoiceTile`s "①…④" (promoted from `StudyChoiceWidget`, idle and selected states only, BR-TOPIK-016). |
| Footer | `MxFooterBar` | "Previous" (outline) · the question grid `MxButton` "Questions" · "Next" (primary); on the last question "Next" becomes "Submit" (primary). |
| Question grid | `MxBottomSheet` + `TopikQuestionGrid` (new, topik) | One cell per question with its real number; answered cells in the accent tint, blank ones neutral, the current one with a `primary` edge; tap jumps; "Submit" at the foot of the sheet. Each cell is `sizeControl` and labelled "Question {no}, answered / not answered". |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| answering | `topik_attempt_reading_light.png` | `topik_attempt_reading_dark.png` | Reading, a passage group, an option selected. |
| answeringListening | `topik_attempt_listening_light.png` | `topik_attempt_listening_dark.png` | Listening, the audio bar paused at 0:42, script hidden. |
| scriptShown | `topik_attempt_script_light.png` | `topik_attempt_script_dark.png` | The script and its translation in the group pane (after answering or by the toggle). |
| collapsed | `topik_attempt_collapsed_light.png` | `topik_attempt_collapsed_dark.png` | The group pane collapsed to its header line. |
| grid | `topik_attempt_grid_light.png` | `topik_attempt_grid_dark.png` | The question grid sheet. |
| submitConfirm | `topik_attempt_submit_confirm_light.png` | `topik_attempt_submit_confirm_dark.png` | `showMxConfirm` "3 questions unanswered". |
| submitting | `topik_attempt_submitting_light.png` | `topik_attempt_submitting_dark.png` | Submit `isLoading`; Back and a second tap do nothing. |
| audioError | `topik_attempt_audio_error_light.png` | `topik_attempt_audio_error_dark.png` | The audio banner with Try again; answering still works. |
| attemptMissing | `topik_attempt_missing_light.png` | `topik_attempt_missing_dark.png` | Deleted elsewhere or the account changed: neutral `MxEmptyState`, "Back to the test". |
| contentMissing | `topik_attempt_content_missing_light.png` | `topik_attempt_content_missing_dark.png` | The test is no longer valid: `MxEmptyState` (warning) offering "Delete attempt" (BR-TOPIK-019). |
| loading | `topik_attempt_loading_light.png` | `topik_attempt_loading_dark.png` | Skeleton panes. |

**Not built yet (status `shaped`).** Goldens are the planned names under `test/features/topik/presentation/goldens/`; every transition's evidence is the rule it implements and the widget or controller test the screen's plan adds. Each row turns `VERIFIED` only with an executed test.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | attempt and test read | answering at `current_question_no` | BR-TOPIK-010, BR-TOPIK-011 |
| answering | pick an option | answering, choice saved, no right/wrong shown | BR-TOPIK-012, BR-TOPIK-016 |
| answering | Next / Previous / grid cell | answering at that question; time of the question left written | BR-TOPIK-015 |
| answering (same group) | move to the group's other question | audio keeps playing, group pane keeps its scroll | BR-TOPIK-017 |
| answering | move to another group | previous audio stops; no autoplay | BR-TOPIK-017 |
| answering | app to background | time stops; written | BR-TOPIK-015 |
| answering | Close / Back / process death | 36 (or wherever it came from); attempt still in progress with its answers and time | BR-TOPIK-010, UC-TOPIK-003 A2 |
| answering | Submit with blanks | submitConfirm | BR-TOPIK-014 |
| submitConfirm | Cancel | answering | BR-TOPIK-014 |
| submitConfirm / answering (no blank) | Submit | submitting → 38 | BR-TOPIK-013 |
| submitting | second tap / Back | no effect | BR-TOPIK-014 |
| answeringListening | play fails | audioError | BR-TOPIK-017 |
| audioError | Try again | answeringListening | BR-TOPIK-017 |
| any | attempt deleted or account switched | attemptMissing | UC-TOPIK-003 E2 |
| loading | test no longer valid | contentMissing | BR-TOPIK-019 |
| any | write fails | same state + snackbar "Your choice wasn't saved", the choice not shown as saved | UC-TOPIK-003 E4 |
| any | language changes | same question, relabelled; answers and time kept | UC-TOPIK-003 A4 |

## Accessibility

- Each `MxChoiceTile` is one node: "Option {n}, {text}, selected / not selected".
- The audio bar's slider announces position and duration; play/pause has its own label.
- Reduced motion: the pane collapse and the sheet open without animation.

## Rulings

- **Brief 2026-10-15 (owner):** two panes, the passage on top scrolling on its own and collapsible; one question per page (spec §5.4: one current question).
- **Brief 2026-10-15 (owner):** `StudyChoiceWidget` moves to `lib/shared` as `MxChoiceTile`; screen 16–20 goldens must not change.
- **Brief 2026-10-15 (owner):** the new widgets live in `lib/features/topik/presentation/widgets/` on tokens only, until a second feature needs them.
- Close needs no dialog: nothing is lost by leaving (BR-TOPIK-010).
- No clock on screen in the MVP: time is measured, not displayed while answering (spec §5.4); Summary shows it.

## Copy

- Top bar: "Practice" · "Close" · "{no} / {last}".
- Group pane: "Show script" · "Hide passage" · "Show passage".
- Audio: "Play" · "Pause" · "{position} / {length}" · "{speed}×" · "Playback speed" · "Couldn't play this audio" · "Your answers are safe." · "Try again".
- Footer: "Previous" · "Next" · "Questions" · "Submit".
- Grid: "Questions" · "Question {no}, answered" · "Question {no}, not answered".
- Submit confirm: "{n} questions unanswered" · "Unanswered questions score 0. Submit anyway?" · "Submit" · "Keep answering".
- Missing: "This attempt isn't here any more" · "Back to the test".
- Content missing: "This test changed and can't be continued" · "Delete attempt".
- Write failure: "Your choice wasn't saved. Try again."
