<!-- Hand-written screen record. -->

# 16 · Study · Browse

The first stage of every learning session, for both algorithms (BR-MODE-003,
BR-MODE-004): both faces of the card at once, nothing graded, nothing counted
against the schedule (BR-MODE-005, BR-MODE-006). FE-A6; UC-STUDY-001 (steps
3, 5, 7). `browse` never runs in a review session (BR-STUDY-055).

## Layout

| Region | Widget | Design |
|---|---|---|
| Top bar | `MxStudyTopBar` | See [Shared by the session screens](#shared-by-the-session-screens). |
| Context line | new: `SessionContextLine` (feature-local, deliberately not a shared widget) | Centred overline: "{deck} · Learning · stage {n} of {total}" (BR-MODE-004 orders the stage). |
| Card | `MxCard`, full-bleed, feature-local two-pane layout (`StudyFaceCard` is a different composition from this one) | Term half on top with its label, pronunciation and a speaker (`MxIconButton`, volume-2, "Read aloud · {language}"; disabled with "No {language} voice on this device" when the device lacks the voice) that reads the face shown (BR-STUDY-079), a hairline divider, meaning half below with its label and example when the card has one; both halves always visible (BR-MODE-006). |
| Navigation | swipe on the card, and a "Next card" button (`StudyCtaRow`, critique 2026-09-30) | Left advances, right looks back one card already shown in this round (BR-STUDY-048); looking back does not re-record the card or move `cursor`. |
| Footer hint | new: `SessionFooterHint` (feature-local) | "Swipe for next or back · nothing is graded" (BR-MODE-005); one line in both languages (owner, 3c-2 golden review). |

## Shared by the session screens

Common to Browse, Match, Guess, Recall and Fill (17–20).

- **`MxStudyTopBar`.** Close icon exits the session (see Exit/abandon below).
  Mode badge: the mode name, uppercase, tinted with the bar's Indigo, in every
  mode (critique 2026-09-30 part 3c-2, R8). Progress track and
  counter: for the four round-based modes the fraction is the **round's**
  position and size, never the board's (BR-STUDY-049 says this explicitly for
  Match's boards); for Browse and `self_assess` it is the stage's whole queue,
  since neither uses rounds. The mode chip takes at most 40% of the bar and
  ellipsizes on one line, and a counter wider than a quarter of the bar
  shrinks to fit, so the track stays at least 48 wide at large text
  (FE-A6 P3 ruling T1 and its final review).
- **Exit / abandon.** The close icon, system Back and Guess's blocked-question
  Close open one confirm dialog (owner ruling 2026-09-27). "Keep going" changes nothing;
  "Stop" ends the session. Every turn already committed stays recorded
  (BR-STUDY-004, BR-STUDY-019); the session becomes `abandoned` with
  `end_reason = user_exit` (BR-STUDY-014).
- **Round behaviour (Match, Guess, Recall, Fill only).** These four run in
  rounds (BR-STUDY-059): round 1 asks every card the stage can ask; each
  later round asks only the round's not-passed set. A card joins that set the
  moment it is answered wrong in the round, even if a later attempt in the
  same round gets it right — Match's stay-on-board retry is exactly this case
  (BR-STUDY-060, BR-STUDY-062). A round-based stage is done once one round
  ends with an empty not-passed set; there is no cap on the number of rounds
  (BR-STUDY-069). Browse and `self_assess` never use rounds; `self_assess`
  instead re-queues a wrong card after at least 3 other cards, up to 3
  `relearning` turns before the card leaves the queue and is flagged
  (BR-STUDY-005, BR-STUDY-073).
- **"Result after commit."** The UI shows a turn's outcome only after its
  write has committed (BR-STUDY-063); a failed write shows an inline error
  and lets the person retry the same answer instead (UC-STUDY-001 E2), and
  never advances or paints an outcome.
- **The unit stays on screen between turns.** The card being answered stays
  visible while the outcome shows and the next turn loads; the body is never
  swapped for a loading state mid-session. Full-body loading is only for a
  session that has no turn yet (BR-STUDY-064). Each mode declares its own
  outcome-display duration.
- **Speech (study speech spec 2026-10-07).** In a learning session a new turn in
  Browse, Self-assess, Guess and Recall reads the term aloud once in the root deck's
  speech language, never in Fill, Match or a review (BR-STUDY-078); the switch on
  screen 23 turns it off and a screen reader suppresses it, while the speaker under the
  term reads on tap whatever the switch says (BR-STUDY-079). The speaker's label names
  the language ("Read aloud · Korean"); when the device has no voice for it the speaker
  is disabled and says so ("No Korean voice on this device"), and automatic reading
  reads nothing (critique 2026-10-07). A failing engine is logged and changes nothing
  (BR-STUDY-081); a new reading or leaving the session stops the voice (BR-STUDY-082).
- **Keyboard / IME.** Only `fill` (20-study-fill.md) takes typed input; every
  other screen here is tap-only and never raises a keyboard.
- **`self_assess`.** See
  `16a-study-self-assess.md` (shape, FE-A5).
- **Icon colour guard.** The `Icon(color:)` guard forbids inline glyph colours
  in feature code; each screen's icons take their colour from the shared
  icon-tinting mechanism. Not repeated per screen below.

## Accessibility

- TalkBack reads the top bar (close, mode, "{done} of {total}"), the context line, then the card: term label and term, pronunciation, meaning label and meaning, example. The footer hint is read last.
- Card faces wrap and never ellipsize; Korean and Vietnamese with stacked marks render whole (UI-base §9 row 102). Touch targets are at least 48 × 48.
- Swipes have accessible actions on the card: "Next card" and, when an earlier card exists, "Previous card".
- Edges (FE-A6 spec D20): the hint does not change; a right swipe on the round's first card does nothing; a left swipe on the stage's last card answers it and the session moves on.

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| default | `study_browse_light.png` | `study_browse_dark.png` | — |
Other goldens: `study_browse_looking_back_light.png` / `study_browse_looking_back_dark.png` (after swiping back to an earlier card).


Not captured: the swipe-back preview of an earlier card in the round
(BR-STUDY-048) is an interaction inside `default`, not a separate state.

**Built (FE-A6 P1c):** `StudyBrowseWidget` inside `StudySessionScreen`. Looking back shows a neutral
"Looking back" badge on the card (BR-STUDY-048: the screen says it is looking back) and reads the
round's trail from the session read model, so it survives a resume; the counter does not move. The
look-back order is the order served, which the stage shuffles (BR-STUDY-022). Goldens
`test/features/study/presentation/goldens/study_browse{,_looking_back}_*`.

## Rulings

- **Owner ruling 2026-09-27; IT-NAV-010, IT-CONT-004:** the close icon and system Back open a confirm dialog first: Keep going or Stop.
- The card follows the finger without a tilt while dragged, and stays still with reduced motion.
- Pronunciation uses the detail role of the body face; V8's typography has one family.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the face label and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the footer hint's glyph sits inline before the first line, and every hint is one line in both languages, so the CTA stands still with no empty line under it (R6, amended at the owner's golden review); the bar is Indigo in every mode (R8); the context line holds two lines at most (R9).

## Copy

- Context line: "{deck} · Learning · stage {n} of {total}".
- Footer hint: "Swipe for next or back · nothing is graded" / "Vuốt để sang hoặc quay lại · không chấm điểm".
