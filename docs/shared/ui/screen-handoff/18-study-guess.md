<!-- Hand-written screen record. -->

# 18 · Study · Guess

A round-based graded stage: `eight_box` only (BR-MODE-004). One term, exactly
five meaning options; only the first tap counts (BR-STUDY-037, BR-STUDY-042).
FE-A6; UC-STUDY-001 (steps 6–9, A0c). Shared session chrome and rules (top
bar, exit, rounds, result-after-commit, keyboard, the icon-colour guard):
[16-study-browse.md § Shared by the session
screens](16-study-browse.md#shared-by-the-session-screens).

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Indigo, as every mode (3c-2 R8); see the shared section. |
| Context line | `SessionContextLine` | "{deck} · Review · round {n}"; a learning session adds its stage: "{deck} · Learning · stage {n} of {total} · round {n}" (`session_context_state.dart`). |
| Prompt | new: `StudyFaceCard` (feature-local; `MxCard`-based, never promoted to shared — a session face is meaningless outside a session) | Overline "What is this?" in flow placement, the term below it, the speaker ("Read aloud · {language}", disabled with "No {language} voice on this device" when the device lacks the voice) under the term (BR-STUDY-079; 16-study-browse.md, Speech). At most four controls tall; the room left sits between it and the options, which stay near the thumb (audit 2026-10-19, G5). |
| Options | 5 rows, new: `GuessOptionRow` (feature-local) | Lettered A–E badge + meaning text. After the first tap: the chosen and the correct row switch to their tone (correct/wrong), the rest fade; matched by card id, never by display string (BR-STUDY-041). |
| Footer hint | `SessionFooterHint` | "The right option is highlighted" once answered. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| default | `study_guess_idle_light.png` | `study_guess_idle_dark.png` | — |
| answering | no golden | no golden | The first pick's write is running: the options take no tap (`onTap` is null while `isBusy`, the screen passes `turn.isLocked`); the tones come only after the commit. `UNVERIFIED (code read)`: `study_guess_widget.dart`. |
| right | `study_guess_right_light.png` | `study_guess_right_dark.png` | The pick in the success tone, the rest faded, "Correct" announced; held 1200 ms or until a tap. `study_guess_test.dart::the right pick shows as correct, is announced, and the next question follows after 1.2 s (G1, G2, C3)`. |
| wrong | `study_guess_wrong_light.png` | `study_guess_wrong_dark.png` | The pick wrong and the right option correct (by card id), the rest faded; "Wrong. The answer is …" announced. `study_guess_test.dart::a wrong pick marks it wrong and the right one correct, fades the rest, and a tap continues early (G1, C1, C3)`. |
| blocked | `study_guess_blocked_light.png` | `study_guess_blocked_dark.png` | A question that cannot be built: `MxErrorState` "This question can't be shown" with Close, which opens the exit dialog (BR-STUDY-040, C2). `study_guess_test.dart::a blocked question shows the notice, and Close ends the session (BR-STUDY-040, G3, C2)`. |

**Built (FE-A6 P3):** `StudyGuessWidget` in the session route's mode switch: the prompt
face ("What is this?" in flow) over five `MxChoiceTile` rows lettered A–E. Once the
pick's write commits, the pick and the right option (found by card id, BR-STUDY-041)
take their tones, the rest fade, and the outcome is announced; the turn is held for
1200 ms or until a tap. Goldens:
`test/features/study/presentation/goldens/study_guess_{idle,wrong,right,blocked}_*`.

## Transitions

`unsavedAnswer` is a route state, a row of [16 · Session route states](16-study-browse.md#session-route-states).

| From | Event | To | Evidence |
|---|---|---|---|
| default | tap an option | answering; the first pick is written | VERIFIED `study_guess_test.dart::the term is asked under "What is this?" with five lettered options (BR-STUDY-037)` for the layout; the pick in the two tests below |
| answering | the pick is right | right: the option in the success tone, "Correct" announced, held 1200 ms, then the next question | VERIFIED `::the right pick shows as correct, is announced, and the next question follows after 1.2 s (G1, G2, C3)` |
| answering | the pick is wrong | wrong: the pick wrong, the right option correct (by card id), the rest faded, announced "Wrong. The answer is …" | VERIFIED `::a wrong pick marks it wrong and the right one correct, fades the rest, and a tap continues early (G1, C1, C3)` |
| right / wrong | a tap anywhere | the next question at once | VERIFIED the wrong-pick test above |
| right / wrong | a second tap on an option while the turn is held | nothing is written (BR-STUDY-042) | VERIFIED `::a second tap while the turn is held writes nothing (BR-STUDY-042)` |
| right / wrong | TalkBack is on | no auto-advance; a "Next" button continues | VERIFIED `::with TalkBack on nothing advances by itself; Next does (C6)` |
| answering | a tap while the write runs | dropped (BR-STUDY-004) | `UNVERIFIED (code read)`: `onTap` is null while `isBusy` (the screen passes `turn.isLocked`) |
| answering | the busy database refuses the pick | unsavedAnswer (16): the banner with Retry; the options are locked (`StudyTurnState.isLocked`) and the first pick stays the answer (BR-STUDY-041) | VERIFIED `study_guess_test.dart::an answer a busy database kept stays the first pick: the options wait for Retry, which saves it (BR-STUDY-041 first pick; audit 2026-10-17)`; the banner path from Browse is VERIFIED in 16 |
| unsavedAnswer | tap another option | ignored; the first pick stays | VERIFIED the same test |
| unsavedAnswer | Retry | the first pick is saved; right / wrong follows as above | VERIFIED the same test (it ends on "Correct" announced) |
| default | the question cannot be built | blocked: the notice with Close | VERIFIED `::a blocked question shows the notice, and Close ends the session (BR-STUDY-040, G3, C2)` |
| blocked | tap Close | the exit dialog; Stop ends the session as `user_exit`, nothing written for the question | VERIFIED same test |
| right / wrong | leave the screen before the 1200 ms end | the timer is cancelled with the widget | `UNVERIFIED (code read)`: `dispose` cancels `_timer` |
| default | ✕, system Back, deck deleted, stale write | the route states of [16](16-study-browse.md#session-route-states) | see 16 |

## Rulings

- **FE-A6 spec D14 (P3 ruling C1):** the right option uses the `success` role (its tint over the surface, a `success` edge and text); green is mastery-only.
- **BR-STUDY-040 (P3 ruling C2):** a question that cannot be built shows "This question can't be shown", whose Close opens the shared exit dialog and, on Stop, ends the session (`onClose` is the screen's `_abandon`); nothing is written or skipped.
- **P3 ruling C6:** with TalkBack on, the answered state waits on a "Next" button instead of advancing by itself.
- **BR-STUDY-042:** before the pick the footer hint reads "Only your first pick counts".
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the session context line is an eyebrow; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the hold stays 1200 ms or until a tap (R2); the blocked notice is centred and its Close has no glyph (R5); the context line drops "first pick counts", which the footer states (R9).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is info (F7).

## Accessibility

- Each option reads "Option {letter}: {meaning}"; once answered, "…, correct" or "…, your pick, wrong".
- The outcome is announced when its write commits: "Correct", or "Wrong. The answer is {meaning}." (P3 ruling C3).
- The options scroll with the prompt once they outgrow the screen at large text, and a soft fade over the bottom edge says more is below; each is at least 48 tall (C4).
- A term word too wide for the prompt is drawn just small enough to stay whole; the term wraps between words and never ellipsizes (FE-A6 D19).
- The options ease into their tones, surface and foreground together (standard duration; at once under Remove animations).
- Keyboard: Tab reaches each option and Enter picks it; ForUI's focus outline is drawn outside the option and the column leaves its reach (`focusOutlineReach`) above and below, so the scroll view never cuts it (`study_choice_focus_ring_test.dart::Guess: Tab gives each of the five options a whole ring…`).

## Copy

- Context line: "{deck} · Review · round {n}" · "{deck} · Learning · stage {n} of {total} · round {n}".
- Prompt overline: "What is this?".
- Footer hint: "Only your first pick counts" (before the pick) · "The right option is highlighted".
- Blocked: "This question can't be shown" · "Its options could not be built. Close the session; every answer so far is kept." · "Close the session".
- TalkBack: "Option {letter}: {meaning}" · "Correct" · "Wrong. The answer is {meaning}." · "Next".
