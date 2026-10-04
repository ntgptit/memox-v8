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
| Context line | as 16–20 | "{deck} · Review · Self-assess" (learning session: "Learn"). |
| Prompt card | the study face card (as 19's term card) | The prompt side for this queue row's direction (BR-MODE-014): the term for `korean_to_meaning`, the meaning for `meaning_to_korean`; a `mixed` row carries its own (BR-MODE-015). The whole card is a button: tapping it reveals, same as "Show answer". |
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
| saving | The grade row is locked on the tapped grade, with no spinner under 300 ms. |
| saveFailed | The session ends as `failed` and the summary (21, Save error) opens (BR-STUDY-018). |
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
`StudyGradeRowWidget`: four `MxButton`s, Again in the `dangerSoft` tone and the rest
`secondary`, each with the interval as `MxButton.detail`, one semantics node "{grade},
next in {interval}", and a 2 × 2 grid from text scale 1.3. The preview is
`PreviewSelfAssessIntervalsUseCase` (FE-A6 D11b): the card's stored schedule through the
same `SrsScheduler.next` the write runs; null on a learning or relearning turn. Footer
hints as the other session screens: "Recall the answer, then show it" / "Be honest —
grade how well you remembered". After "Show answer" leaves, the answer face is the next
node TalkBack reads. Goldens:
`test/features/study/presentation/goldens/study_self_assess_{prompt,revealed,relearning,meaning_first}_*`.

## Rulings

- **FE-A6 P2 plan R1:** the mode badge and context line read "Self-assess", as the resume banner and the card screens name the mode.
- **Plan R2:** the recessed answer face is always laid out, with a still placeholder bar until the reveal; the answer fades in inside it, so the prompt never moves.
- **Plan R3:** while the grade is written the row takes no tap and draws no change; a local write is well under 300 ms.
- **Plan R4:** the interval preview is read when the card is served, so the grades have it at the reveal.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the face labels and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the grades settle for 400 ms after Show answer, so a double tap grades nothing (R1); they keep their rounded rectangles, as they judge rather than act (R7).
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the footer hint's glyph is info (F7).

## Accessibility

- TalkBack reads the prompt, then "Show answer". After the reveal, focus moves to the answer card, then to the grades. Each grade reads "Good, next in 6 days", or just "Again" on a relearning turn.
- Stacked diacritics in either card follow the single-line rule where a line is ellipsized (spec §9 row 102). Card faces wrap and never ellipsize.
- Touch targets are at least 48 × 48, with 8 between the grades.

## Anti-goals

- No colour-coded rainbow of four grades, and no new rating tokens.
- No swipe-to-grade, no auto-advance timer, and no per-answer toast or confetti.
- No editing a card mid-session (as 19 and 20).

## Copy

- "Self-assess" (see Rulings) · "Show answer" · "Again" · "Hard" · "Good" · "Easy" · "{n}d" · "{n}mo" · "{n}y".
- TalkBack: "{grade}, next in {interval}".
