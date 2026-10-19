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
| Context line | `SessionContextLine` | "{deck} · Review · round {n}"; a learning session adds its stage: "{deck} · Learning · stage {n} of {total} · round {n}" (`session_context_state.dart`). |
| Prompt face | `StudyFaceCard` | The card's meaning. |
| Answer face | `StudyFaceCard` (`role: answer`); the typed text itself: `MxTextField` (the `study` variant in the study term role; the golden `study_fill_input_*` draws it as a filled box in the page colour, inset on the recessed Term face and as wide as the face, with the typed text centred and a primary caret) — its style is a `context.texts` role, settled in the FE-A6 plan against the no-per-site-text-styling guard | `input`/`hint`: what has been typed so far with a blinking caret. `wrong`: the typed answer struck through, the correct term below it, tagged "Wrong · comes back next round" (see Rulings). |
| Hint row | inline row inside the answer face, shown only in `hint`, its line reserved from the start (3c-2 R4) | Lightbulb glyph + the card's own hint text; only offered when the card has one (BR-STUDY-028). |
| CTA row | `StudyCtaRow` | `input`: "Show hint" (only if the card has a hint) + "Check". `hint`: "Check" only. `wrong`: one "Continue" button, as wide as a two-button row (critique 2026-09-30). |
| Footer hint | `SessionFooterHint` | Varies by state; see Copy. The glyph is info for the `input` and `hint` instructions, and for `wrong` too, whose footer states the grading rule; the tag above says the card comes back (critique 2026-10-02 F7; audit 2026-10-19, G6). |

## Keyboard / IME

The system keyboard opens for `input`/`hint` and the CTA row sits above it;
`wrong` shows no field and the keyboard closes. Grading folds the typed text
(trim + Unicode-aware lower-case) against `front_folded` but never strips
accents — "cong" must not match "công" (BR-STUDY-026). The typed text itself
is never persisted, only the outcome, the match-policy version and whether a
hint was used (BR-STUDY-027, BR-STUDY-030). An empty answer after trim
submits nothing (BR-STUDY-029). The answer field asks the keyboard for no
suggestions and no autocorrect (the `study` variant of `MxTextField`), so the
keyboard neither offers the term nor corrects what was typed (BR-STUDY-026).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| input | `study_fill_input_light.png` | `study_fill_input_dark.png` | No edit button (see Rulings). |
| hint | `study_fill_hint_light.png` | `study_fill_hint_dark.png` | "Show hint" is gone once used, "Check" remains. |
| answering | none | none | The typed answer is being written (Check or IME Done): the controls are locked while the write runs. A right answer has no frame of its own, the next turn follows at once (BR-STUDY-063, BR-STUDY-064); a wrong one becomes `wrong`. `study_fill_test.dart::a right answer moves on at once, with no feedback frame (F3, BR-STUDY-064; case and outer spaces ignored)`. |
| wrong | `study_fill_wrong_light.png` | `study_fill_wrong_dark.png` | With the corrected footer copy. |

**Built (FE-A6 P4):** `StudyFillWidget` in the session route's mode switch. The field is
`MxTextField`'s bare `study` variant in the study term role (P4 ruling F1); it has focus
when the turn opens, Check waits for a non-empty answer, and IME Done checks
(BR-STUDY-029). A right answer lets the next turn follow at once; a wrong one is held
until Continue, the typed text struck through in the error colour beside the right term
(BR-STUDY-059, BR-STUDY-064). Show hint appears only for a card with a hint not yet shown
(BR-STUDY-028). The typed text is never kept (BR-STUDY-027). Goldens:
`test/features/study/presentation/goldens/study_fill_{input,hint,wrong}_*`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| input | the turn opens | the field has focus and the keyboard opens; Check is disabled until the answer is non-empty | VERIFIED `study_fill_test.dart::the field has focus when the turn opens (V7)`, `::the meaning asks, the field takes the term, and Check waits for text; Done on nothing does nothing (20 input, F2, V7)` |
| input | tap Check, or IME Done, with text | answering; the typed answer is written (case and outer spaces ignored, accents count) | VERIFIED `::IME Done checks (F2)`, `::accents count: "tèrm 1" does not match "term 1" (BR-STUDY-026)` |
| input | the field is drawn with the keyboard open on a short phone (360 × 800, 300 of inset) | the field stays whole on screen, above the keyboard | VERIFIED `study_fill_test.dart::on a short phone with the keyboard open the answer field stays whole on screen (audit 2026-10-17, STUDYB-9)` |
| input / hint | the keyboard is asked for suggestions or autocorrect | none: the field sets `autocorrect: false` and `enableSuggestions: false` | VERIFIED `test/shared/widgets/mx_text_field_test.dart::a study answer gets no suggestions and no autocorrect; a form field keeps them (BR-STUDY-026, audit 2026-10-17)` |
| input / hint | the footer hint shows | the info glyph with the instruction | VERIFIED `study_fill_test.dart::the input hint takes the info glyph, as every mode's instruction does (critique 2026-10-02 F7; audit 2026-10-17)` |
| input | IME Done on an empty answer | nothing | VERIFIED `::the meaning asks, the field takes the term, and Check waits for text; Done on nothing does nothing (20 input, F2, V7)` |
| answering | the answer is right | the next turn follows at once, with no feedback frame | VERIFIED `::a right answer moves on at once, with no feedback frame (F3, BR-STUDY-064; case and outer spaces ignored)` |
| answering | the answer is wrong | wrong: the typed text struck through beside the right term, only the letters that differ in `error` (audit 2026-10-19, G6), "Wrong · comes back next round", announced, focus leaves the field and the keyboard closes; held | VERIFIED `::a wrong answer is struck through beside the right term, announced, and waits for Continue (F3, V1, V10, BR-STUDY-059)`; the footer glyph is repeat, asserted in the same test |
| wrong | tap Continue | the next turn; the wrong card is asked again in the next round (BR-STUDY-059) | VERIFIED in the test above for the hold; the next-round enrolment is the domain's |
| wrong | a double tap on Check | Continue settles for 400 ms, so the wrong answer is not skipped | VERIFIED `::a double tap on Check does not skip the wrong answer: Continue settles first (critique 2026-09-30 part 3c-2, R1)` |
| input | tap Show hint (a card with a hint) | hint: the hint row appears in its reserved line, what was typed is kept, Show hint is gone, Check remains; the hint is noted and changes no result | VERIFIED `::Show hint shows the card's hint once and keeps what was typed (F4, BR-STUDY-028)`, `::Show hint moves nothing: the hint line is reserved, at the study detail role (critique 2026-09-30 part 3c-2, R4)`, `::a hint that wraps is reserved whole too (R4)` |
| input | the card has no hint | no Show hint button | VERIFIED `::a card with no hint offers no Show hint (F4)` |
| input | a double tap on Show hint | the hint only; Check settles first so a half-typed answer is not checked | VERIFIED `::a double tap on Show hint does not check a half-typed answer: Check settles first (critique 2026-09-30 part 3c-2, final review)` |
| input | tap Show hint, and the write meets a bug (not a `Failure`) | the turn is as it was and no longer busy; the bug is reported | VERIFIED `study_held_bug_test.dart::a fill hint that dies on a bug is no longer busy (_write)` |
| answering | the busy database refuses the answer | the unsaved-answer banner; the controls are locked while it waits for Retry (`isLocked`); on Retry the wrong answer shows what was typed | VERIFIED `::a wrong answer the busy database refused shows what was typed once Retry commits it (UC-STUDY-001 E2; P4 final review)` |
| input / hint | ✕ or Back with the keyboard open | the exit dialog of [16](16-study-browse.md#session-route-states); the typed text is dropped, never persisted (BR-STUDY-027) | `UNVERIFIED (code read)`: the controller is the widget's own and is disposed with it |
| any | deck deleted, stale write | the route states of [16](16-study-browse.md#session-route-states) | see 16 |

## Rulings

- **P4 ruling V1:** the struck-through wrong answer uses `error`, as Guess's wrong option; one wrong colour across the round modes.
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

- Context line: "{deck} · Review · round {n}" · "{deck} · Learning · stage {n} of {total} · round {n}".
- CTAs: "Show hint" · "Check" · "Continue".
- Wrong tag: "Wrong · comes back next round" (see Rulings).
- Footer hint: "Type the term for this meaning, then check" (`input`) · "Using the hint is noted; it changes nothing" (`hint`) · "Case and spaces ignored; accents count" (`wrong`).
