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
| Top bar | `MxStudyTopBar` | Primary accent (default); see the shared section. |
| Context line | `SessionContextLine` | "{deck} · Review · Guess · round {n} · first pick counts". |
| Prompt | new: `StudyFaceCard` (feature-local; `MxCard`-based, never promoted to shared — a session face is meaningless outside a session) | Overline "What is this?" in flow placement, the term below it. |
| Options | 5 rows, new: `GuessOptionRow` (feature-local) | Lettered A–E badge + meaning text. After the first tap: the chosen and the correct row switch to their tone (correct/wrong), the rest fade; matched by card id, never by display string (BR-STUDY-041). |
| Footer hint | `SessionFooterHint` | "Answer shown — the correct option is highlighted" once answered. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| default | `study_guess_idle_light.png` | `study_guess_idle_dark.png` | — |

Not captured: the pre-tap idle appearance of the five options is an
interaction inside `default`, not a separate capture.

**Built (FE-A6 P3):** `StudyGuessWidget` in the session route's mode switch: the prompt
face ("What is this?" in flow) over five `StudyChoiceWidget` rows lettered A–E. Once the
pick's write commits, the pick and the right option (found by card id, BR-STUDY-041)
take their tones, the rest fade, and the outcome is announced; the turn is held for
1200 ms or until a tap. Goldens:
`test/features/study/presentation/goldens/study_guess_{idle,wrong,right,large_text,blocked}_*`.

## Rulings

- **FE-A6 spec D14 (P3 ruling C1):** the right option uses the `success` semantic (`successSoft`/`successBorder`/`successInk`); green is mastery-only.
- **BR-STUDY-040 (P3 ruling C2):** a question that cannot be built shows "This question can't be shown", whose Close ends the session; nothing is written or skipped.
- **P3 ruling C6:** with TalkBack on, the answered state waits on a "Next" button instead of advancing by itself.
- **BR-STUDY-042:** before the pick the footer hint reads "Only your first pick counts".

## Accessibility

- Each option reads "Option {letter}: {meaning}"; once answered, "…, correct" or "…, your pick, wrong".
- The outcome is announced when its write commits: "Correct", or "Wrong. The answer is {meaning}." (P3 ruling C3).
- The options scroll with the prompt once they outgrow the screen at large text, and a soft fade over the bottom edge says more is below; each is at least 48 tall (C4).
- A term word too wide for the prompt is drawn just small enough to stay whole; the term wraps between words and never ellipsizes (FE-A6 D19).
- The options ease into their tones, surface and ink together (standard duration; at once under Remove animations).

## Copy

- Context line: "{deck} · Review · Guess · round {n} · first pick counts".
- Prompt overline: "What is this?".
- Footer hint: "Only your first pick counts" (before the pick) · "Answer shown — the correct option is highlighted".
- Blocked: "This question can't be shown" · "Its options could not be built. Close the session; every answer so far is kept." · "Close the session".
- TalkBack: "Option {letter}: {meaning}" · "Correct" · "Wrong. The answer is {meaning}." · "Next".
