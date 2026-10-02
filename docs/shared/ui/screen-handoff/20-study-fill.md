<!-- Hand-written screen record. -->

# 20 · Study · Fill

A round-based graded stage: `eight_box` only (BR-MODE-004), and only for
cards that have an `example` — others sit out this stage without leaving the
deck (BR-STUDY-044, BR-STUDY-071). The meaning is the prompt; the person
types the term. FE-A6; UC-STUDY-001 (steps 6–9, A0c). Shared session chrome
and rules (top bar, exit, rounds, result-after-commit, the icon-colour
guard): [16-study-browse.md § Shared by the session
screens](16-study-browse.md#shared-by-the-session-screens).

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Indigo, as every mode (3c-2 R8). |
| Context line | `SessionContextLine` | "{deck} · Review · round {n}". |
| Prompt face | `StudyFaceCard` | The card's meaning. |
| Answer face | `StudyFaceCard` (`role: answer`); the typed text itself: `MxTextField` (borderless, no visible chrome, the study answer text style) — its style comes from `MxTextStyles`, settled in the FE-A6 plan against the no-per-site-text-styling guard | `input`/`hint`: what has been typed so far with a blinking caret. `wrong`: the typed answer struck through, the correct term below it, tagged "Wrong · comes back next round" (see Rulings). |
| Hint row | inline row inside the answer face, shown only in `hint`, its line reserved from the start (3c-2 R4) | Lightbulb glyph + the card's own hint text; only offered when the card has one (BR-STUDY-028). |
| CTA row | `StudyCtaRow` | `input`: "Show hint" (only if the card has a hint) + "Check". `hint`: "Check" only. `wrong`: one "Continue" button, as wide as a two-button row (critique 2026-09-30). |
| Footer hint | `SessionFooterHint` | Varies by state; see Copy. |

## Keyboard / IME

The system keyboard opens for `input`/`hint` and the CTA row sits above it;
`wrong` shows no field and the keyboard closes. Grading folds the typed text
(trim + Unicode-aware lower-case) against `front_folded` but never strips
accents — "cong" must not match "công" (BR-STUDY-026). The typed text itself
is never persisted, only the outcome, the match-policy version and whether a
hint was used (BR-STUDY-027, BR-STUDY-030). An empty answer after trim
submits nothing (BR-STUDY-029).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| input | `study_fill_input_light.png` | `study_fill_input_dark.png` | No edit button (see Rulings). |
| hint | `study_fill_hint_light.png` | `study_fill_hint_dark.png` | "Show hint" is gone once used, "Check" remains. |
| wrong | `study_fill_wrong_light.png` | `study_fill_wrong_dark.png` | With the corrected footer copy. |

Not captured: the correct-answer path has no dedicated visual — the turn
commits and the next one loads immediately (BR-STUDY-063, BR-STUDY-064).

**Built (FE-A6 P4):** `StudyFillWidget` in the session route's mode switch. The field is
`MxTextField`'s bare `study` variant in the study term role (P4 ruling F1); it has focus
when the turn opens, Check waits for a non-empty answer, and IME Done checks
(BR-STUDY-029). A right answer lets the next turn follow at once; a wrong one is held
until Continue, the typed text struck through in the error ink beside the right term
(BR-STUDY-059, BR-STUDY-064). Show hint appears only for a card with a hint not yet shown
(BR-STUDY-028). The typed text is never kept (BR-STUDY-027). Goldens:
`test/features/study/presentation/goldens/study_fill_{input,hint,wrong}_*`.

## Rulings

- **P4 ruling V1:** the struck-through wrong answer uses the `error` ink, as Guess's wrong option; one wrong colour across the round modes.
- **BR-STUDY-059, BR-STUDY-069 (P4 ruling V10):** the wrong tag and footer read "Wrong · comes back next round": a wrong `fill` row leaves the current round and is enrolled exactly once in the next one.
- **P4:** the prompt uses the study passage role at 16, and both faces carry their "Meaning" and "Term" labels in flow.
- No card can be edited mid-session, so the prompt face has no edit button.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** Continue after a wrong answer settles for 400 ms (R1); the card's hint is the study detail role with its line reserved (R4); the bar is Indigo (R8).

## Accessibility

- The field reads "Your answer"; the hint row reads "Hint: {hint}"; the struck-through answer reads "You typed {typed}".
- A wrong answer is announced when its write commits: "Wrong. The answer is {term}." Focus leaves the field and the keyboard closes (V7).
- With the keyboard open the shell resizes above it, so Check and the footer stay visible; the faces scroll inside (V6). At large text the two actions stack.

## Copy

- Context line: "{deck} · Review · round {n}".
- CTAs: "Show hint" · "Check" · "Continue".
- Wrong tag: "Wrong · comes back next round" (see Rulings).
- Footer hint: "Type the term for this meaning, then check" (`input`) · "Using the hint is noted; it changes nothing" (`hint`) · "Case and spaces are ignored, accents are not" (`wrong`).
