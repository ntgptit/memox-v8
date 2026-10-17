<!-- Hand-written screen record. -->

# 16a · Study · Self-assess

The `self_assess` session: `sm2`'s review mode, and the second stage of an `sm2`
learning session (BR-MODE-004). Shaped by Impeccable before the plan: this file is its
`shape` brief (FE-A5, 2026-09-25), built from the session language of screens 16 and
19 and the rules. UC-STUDY-001, UC-STUDY-003.

## Job

A learner on an `sm2` deck, one-handed, in a short gap in the day, grades how well they
remembered each due card. Success is a fast, honest grade: see the prompt, try to recall
the answer, reveal it, and tap one of four grades. Nothing on the screen should compete
with the prompt, and no grade should ever be committed by accident.

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | Close, mode badge "Self-assess", counter "{n} / {total}". Shared with 16–20 (see [16](16-study-browse.md#shared-by-the-session-screens)). |
| Context line | as 16–20 | "{deck} · Review" (learning session: "{deck} · Learning · stage {n} of {total}"). It carries no mode: the mode is the top bar's pill, "Self-assess" (`session_context_state.dart`). |
| Prompt card | the study face card (as 19's term card) | The prompt side for this queue row's direction (BR-MODE-014): the term for `korean_to_meaning`, the meaning for `meaning_to_korean`; a `mixed` row carries its own (BR-MODE-015). Tapping the prompt card reveals, same as "Show answer", but that tap is a shortcut only: the card is excluded from semantics (`study_face_card_widget.dart`, `excludeFromSemantics`), and "Show answer" is the accessible path. The term face carries the speaker ("Read aloud · {language}", disabled with "No {language} voice on this device" when the device lacks the voice) under the pronunciation (BR-STUDY-079; 16-study-browse.md, Speech). |
| Answer card | the study face card, answer tone | Hidden until revealed (BR-MODE-006), then shown under the prompt; the prompt stays in place. |
| Action area, before reveal | primary block `MxButton` | "Show answer". |
| Action area, after reveal | four `MxButton`s in one row, new: `StudyGradeRow` | Again · Hard · Good · Easy, in that order, from `supportedActions` (BR-STUDY-009). Again is error-tinted; Hard, Good and Easy share one tonal treatment. The label always names the grade, so colour never carries it alone. Under each label is the interval it would give, e.g. "1d", "6d", "15d" (see [Interval preview](#interval-preview)). Each button is at least 48 tall; at large text the row becomes a 2 × 2 grid instead of shrinking type. |

## Behaviour

- **Reveal:** tapping the card or "Show answer" does the same thing. Revealing writes nothing, and a revealed card is not an answer.
- **Grade:** one tap commits the turn and advances to the next card, with no confirm step. The row locks from tap to write (BR-STUDY-004), so a double tap records one turn. No swipe or long-press grades anything.
- **Again:** the card comes back after at least three other cards, or at the end of the queue (BR-STUDY-005). Its third relearning turn takes it out of the queue and flags it (BR-STUDY-073). No toast is shown per answer; the summary (21) tells the outcome.
- **Leaving:** Close and system Back follow the shared exit of 16–20. Everything answered is kept (BR-STUDY-014, BR-STUDY-019).
- **Resume:** a resumed session re-opens on the current card unrevealed (BR-STUDY-072). Its direction is read from the queue row, never asked again (BR-MODE-017).
- **Motion:** the answer card fades and slides in under the prompt (fade-through, standard easing). With Remove animations on, it appears at once.

## Interval preview

- For a **scheduled** turn (the card's first answer in this session), each grade shows the interval `Sm2Scheduler.next` would give from the card's current state. This is a pure preview: nothing is written.
- For a **relearning** turn, the schedule does not move (BR-SRS-016, BR-SRS-017), so the preview is hidden (spec A5). It is not drawn as "0d".
- Format: under 30 days "{n}d"; under a year "{n}mo" (days / 30, rounded); from a year "{n}y" (one decimal, trailing ".0" dropped). All in ARB.
- Needs a backend addition in FE-A6: a read-only preview of the four next intervals for the current turn, from the same scheduler the write uses. It must never fork the formula.

## States

| State | V8 |
|---|---|
| prompt | Prompt card and "Show answer"; the answer is hidden. |
| revealed | Both cards and the grade row; previews on a scheduled turn. |
| relearning | As revealed, without previews. |
| saving | The grade row takes no tap and draws no change (plan R3); a local write is well under 300 ms. |
| saveFailed | A `DatabaseLockedFailure` keeps the answer: the card stays and the unsaved-answer banner with Retry shows (UC-STUDY-001 E2; [Session route states](16-study-browse.md#session-route-states)). Any other `Failure` resets the turn (`study_session_controller.dart`); the use case has already closed the session as `failed`, and the summary (21, Save error) opens (BR-STUDY-018). |
| stale | A reset or algorithm change elsewhere invalidates the session on the next write, and the summary (21) opens with its reason (BR-STUDY-015, BR-STUDY-016, BR-STUDY-017). |
Other goldens: `study_self_assess_prompt_light.png` / `study_self_assess_prompt_dark.png` (the prompt before the reveal); `study_self_assess_revealed_light.png` / `study_self_assess_revealed_dark.png` (revealed, with the grades); `study_self_assess_meaning_first_light.png` / `study_self_assess_meaning_first_dark.png` (a meaning-first row); `study_self_assess_relearning_light.png` / `study_self_assess_relearning_dark.png` (a relearning card).

The goldens `study_self_assess_*` in `test/features/study/presentation/goldens/` are its
record.

**Built (FE-A6 P2):** `StudySelfAssessWidget` in the session route's mode switch. Two
`StudyFaceCardWidget`s (the prompt raised, the answer on `MxCard.isRecessed`), each with
its label in flow above the face, so a face grown by large text never slides under it.
The two faces share the height equally, as `StudyFaceCard` owns its `flex: 1`
growth; a short face is centred in its half.
"Show answer" is the study action (`MxButtonSize.study`); the grades are
`StudyGradeRowWidget`: four `MxButton`s, Again in the `dangerTint` tone and the rest
`secondary`, each with the interval as `MxButton.detail`, one semantics node "{grade},
next in {interval}", and a 2 × 2 grid from text scale 1.3. The preview is
`PreviewSelfAssessIntervalsUseCase` (FE-A6 D11b): the card's stored schedule through the
same `SrsScheduler.next` the write runs; null on a learning or relearning turn. Footer
hints as the other session screens: "Recall the answer, then show it" / "Grade how
well you remembered". After "Show answer" leaves, the answer face is the next
node TalkBack reads. Goldens:
`test/features/study/presentation/goldens/study_self_assess_{prompt,revealed,relearning,meaning_first}_*`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| prompt | tap Show answer, or the prompt card | revealed; nothing is written | VERIFIED `study_self_assess_test.dart::the prompt shows first, the answer waits for Show answer, and revealing writes nothing (IT-MODE-012, BR-MODE-006)`, `::tapping the prompt card reveals, as Show answer does` |
| prompt | tap Show answer, with TalkBack on | the reveal is announced: "The answer is {answer}." (the meaning when the card is term-first, the term when meaning-first), since Show answer takes the focus with it | VERIFIED `study_self_assess_test.dart::the reveal is announced: the answer is read, term-first and meaning-first alike (TalkBack)`, `::a meaning-first reveal announces the term` |
| prompt | a double tap on Show answer | revealed only; the grades take no tap for 400 ms | VERIFIED `::a double tap on Show answer grades nothing: the grades settle first (critique 2026-09-30 part 3c-2, R1)` |
| prompt | the card is meaning-first | the meaning is the prompt; the term and the example wait for the reveal | VERIFIED `::a meaning-first card prompts with the meaning; the term and the example wait for the reveal (BR-MODE-014)` |
| revealed | tap a grade (scheduled turn) | saving, then the next card, unrevealed | VERIFIED `::Good records one scheduled turn and the next card follows, unrevealed`; the previews and label: `::a scheduled turn shows each grade with its interval, and reads "Good, next in 6 days" (16a)` |
| revealed | a double tap on a grade | one turn recorded (BR-STUDY-004) | VERIFIED `::a double tap on a grade records one turn (IT-MODE-012, BR-STUDY-004)` |
| revealed | tap Again | the card returns later as relearning, with no interval and never "0d" | VERIFIED `::after Again the card comes back as a relearning turn, with no interval and never "0d" (BR-STUDY-005, 16a)` |
| relearning | tap a grade | saving, then the next card; the third relearning turn takes the card out of the queue and flags it (BR-STUDY-073) | `UNVERIFIED (code read)` on this screen; the rule is the domain's |
| saving | the busy database refuses the write | the card stays revealed with the unsaved-answer banner; the answer is kept | VERIFIED for the shared path `study_session_screen_test.dart::a busy database shows the error on the same card and Retry saves it (UC-STUDY-001 E2)` (driven from Browse); no test drives it from the grade row |
| saving | any other database failure | the turn resets, the session is closed as `failed`, summary Save error | VERIFIED for the close `test/features/study/domain/answer_study_turn_use_case_test.dart::a fatal error rolls the turn back and closes the session as failed; the turns before it stay (IT-CONT-012, UC-STUDY-001 E3, BR-STUDY-018, BR-STUDY-019)`; the summary on screen is `UNVERIFIED (code read)` |
| revealed / saving | a reset or algorithm change elsewhere | stale: the summary opens with its reason, or the route leaves for a stale generation | the leave is VERIFIED `study_session_screen_test.dart::a write from a stale generation leaves for the deck, with no summary (UC-STUDY-001 E4)`; the summaries are on screen 21 |
| any | ✕, system Back, the deck deleted, the session unreadable | the route states of [16](16-study-browse.md#session-route-states) | see 16 |
| any | the next card is served while the grades are shown | the new turn starts unrevealed (the widget is keyed per card and answer count) | VERIFIED `::Good records one scheduled turn and the next card follows, unrevealed` |
| revealed | Remove animations is on | the answer appears at once | VERIFIED `::with Remove animations on, the answer appears at once` |

## Rulings

- **FE-A6 P2 plan R1:** the mode badge reads "Self-assess", as the resume banner and the card screens name the mode. The context line does not repeat the mode ("{deck} · Review"; critique 2026-09-30, `session_context_state.dart`); `study_self_assess_test.dart::a review names its kind and mode in the context line (16a, plan R1)` pins the line without it.
- **Plan R2:** the recessed answer face is always laid out, with a still placeholder bar until the reveal; the answer fades in inside it, so the prompt never moves.
- **Plan R3:** while the grade is written the row takes no tap and draws no change; a local write is well under 300 ms.
- **Plan R4:** the interval preview is read when the card is served, so the grades have it at the reveal.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the grades settle for 400 ms after Show answer, so a double tap grades nothing (R1); they keep their rounded rectangles, as they judge rather than act (R7).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is info (F7).

## Accessibility

- TalkBack reads the prompt, then "Show answer". The reveal is announced ("The answer is {answer}."), because Show answer, the focused button, goes. After the reveal, focus moves to the answer card, then to the grades. Each grade reads "Good, next in 6 days", or just "Again" on a relearning turn.
- Stacked diacritics in either card follow the single-line rule where a line is ellipsized (spec §9 row 102). Card faces wrap and never ellipsize.
- Touch targets are at least 48 × 48, with 8 between the grades.

## Anti-goals

- No colour-coded rainbow of four grades, and no new rating tokens.
- No swipe-to-grade, no auto-advance timer, and no per-answer toast or confetti.
- No editing a card mid-session (as 19 and 20).

## Copy

- "Self-assess" (see Rulings) · "Show answer" · "Again" · "Hard" · "Good" · "Easy" · "{n}d" · "{n}mo" · "{n}y".
- TalkBack: "{grade}, next in {interval}".
