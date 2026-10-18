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
  `end_reason = user_exit` (BR-STUDY-014). A turn held on screen is dropped by
  a successful Stop, so the summary shows at once. A Stop that cannot be written
  says so with the toast "Everything you answered is kept. Couldn't stop the session, so try again." and keeps the session open on the
  same card. While the dialog asks, a leave that arrives (deck gone, stale
  generation) closes the dialog first and then leaves, so no blank page is left
  behind it. System Back on a session that is loading or unreadable leaves as ✕
  does, with no dialog.
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

### Session route states

`StudySessionScreen` (`study_session_screen.dart`) owns these around every mode body (16-21). They are the route's states, not a mode's; each mode file lists its own.

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| sessionLoading | none | none | Before the session's first view: a centred `MxSpinner` ("Loading") in the session shell (`StudySessionLoadingWidget`). The summary has no loading of its own; it arrives with the view (spec D2). Code read: `study_session_error_widget.dart`. |
| sessionReadError | none | none | The session could not be read (UC-STUDY-001 E5): `MxErrorState` "Couldn't read this session" with Retry and a close icon (`StudySessionErrorWidget`). VERIFIED without a golden by `study_session_screen_test.dart::a session that cannot be read says so and Retry reads again (UC-STUDY-001 E5)`. |
| unsavedAnswer | none | none | A busy database refused an answer (`DatabaseLockedFailure`): the card stays, a danger `MxInlineBanner` "Couldn't save that answer" with a small Retry sits under the context line, and the answer is kept (`turn.unsaved`, UC-STUDY-001 E2). While it waits for Retry, every mode's controls are locked and a second pick is ignored: it stays the turn's answer (BR-STUDY-041, `StudyTurnState.isLocked`; each mode gets `isBusy: turn.isLocked`). VERIFIED without a golden by `::a busy database shows the error on the same card and Retry saves it (UC-STUDY-001 E2)`; the banner's margins by `::M3F-19: the unsaved-answer banner keeps the 16.0 screen margin at 360 wide` (and 24 at 700). The lock is VERIFIED for Guess by `study_guess_test.dart::an answer a busy database kept stays the first pick: the options wait for Retry, which saves it (BR-STUDY-041 first pick; audit 2026-10-17)`; for the other modes it is `UNVERIFIED (code read)`: `study_session_screen.dart` passes `turn.isLocked` to each. |
| heldTurn | none | none | A graded turn stays drawn in the view it was answered in, with its result, until its mode releases it (spec D5), even when its answer ended the session or stalled the round. VERIFIED `::a held turn stays on screen when its answer ends the session; the summary follows its release (spec D5)`. |
| stalledRound | none | none | A round whose cards were all deleted has no card to serve: the route shows the loading spinner while it settles (`settle` resumes the session, spec D12), waiting for a held turn to release first. VERIFIED `::a stalled round waits for a held turn before it settles (spec D5)` for the order and the settle; the spinner frame itself is `UNVERIFIED (code read)`. |
| exitDialog | none | none | ✕ and system Back ask "Stop this session?" with "Keep going" and "Stop" (owner ruling 2026-09-27). Recall's clock is paused while it asks (`_isAsking`). VERIFIED `::✕ asks first; Stop abandons and the same screen shows "You left early"; …`, `::Keep studying in the exit dialog changes nothing: the session stays open on the same card (IT-CONT-004)`. |
| deckGone | none | none | The deck went to the Trash: the toast "This deck no longer exists", then the route leaves for the Library, once (UC-STUDY-001 A5). When the exit dialog is open, it closes first and the leave follows. VERIFIED `::the deck moved to the Trash leaves once, for the Library, with a message (UC-STUDY-001 A5)`, `::the deck gone while the exit dialog is open closes it and leaves, never a blank page`. |
| stopFailed | none | none | A Stop the database refused: the toast "Everything you answered is kept. Couldn't stop the session, so try again." (local-first), and the session stays in progress on the same card; the next start closes it (BR-STUDY-072). VERIFIED `::Stop that cannot be written says so, local-first, and the session stays open on the same card`. |
| staleGeneration | none | none | A write came from a stale generation: the toast "This session ended: the deck's learning progress was reset.", then the route leaves for the deck, with no summary (UC-STUDY-001 E4). VERIFIED `::a write from a stale generation leaves for the deck, with no summary (UC-STUDY-001 E4)`. |
| summary | see 21 | see 21 | An ended session shows screen 21 on the same route (spec D3); system Back there is Done. VERIFIED `::system Back mid-session keeps the ✕ contract: it asks, Stop abandons, the turn taken stays, no Continue; Back on the summary is Done, never a return to a closed session (IT-NAV-010)`. |

### Session route transitions

| From | Event | To | Evidence |
|---|---|---|---|
| sessionLoading | the view lands | the mode body of the current stage, or the summary if the session has ended | `UNVERIFIED (code read)`: `study_session_screen.dart` `build` and `_pageOf`; every session test pumps past it |
| sessionLoading | the read fails | sessionReadError | VERIFIED `study_session_screen_test.dart::a session that cannot be read says so and Retry reads again (UC-STUDY-001 E5)` |
| sessionReadError | Retry | sessionLoading, then the view (the provider is invalidated) | VERIFIED same test (the read runs again); the landing after Retry is `UNVERIFIED (code read)` |
| sessionReadError | tap the close icon | leaves for the Library (`onLeave(null)`) | `UNVERIFIED (code read)` |
| sessionLoading / sessionReadError | system Back | leaves for the Library as ✕ does (`onLeave(null)`), without the Stop dialog | VERIFIED `study_session_screen_test.dart::system Back on a session that cannot be read leaves, as its ✕ does, without asking to stop`; the loading branch shares `_onPop` and is `UNVERIFIED (code read)` |
| any open mode | the stream errors after a view was shown | sessionReadError replaces the body | `UNVERIFIED (code read)`: the `AsyncError` branch of `build` |
| any open mode | an answer is refused by a busy database | unsavedAnswer; nothing moves or is painted | VERIFIED `::a busy database shows the error on the same card and Retry saves it (UC-STUDY-001 E2)`; `study_session_controller_test.dart::a busy database keeps the answer for Retry and moves nothing (UC-STUDY-001 E2)` |
| unsavedAnswer | Retry | the same answer is sent again; on success the banner goes and the next turn follows | VERIFIED same screen test; `study_session_controller_test.dart::Retry resends the same pair the busy database refused (E2)` |
| unsavedAnswer | a second pick or tap on the mode's controls | ignored; the refused answer stays the turn's answer (`isLocked`), and Retry saves it | VERIFIED for Guess `study_guess_test.dart::an answer a busy database kept stays the first pick: the options wait for Retry, which saves it (BR-STUDY-041 first pick; audit 2026-10-17)`; the other modes `UNVERIFIED (code read)`: `study_session_controller.dart` `answer` |
| unsavedAnswer | any other failure on Retry | the turn resets with no banner; the stream shows the session failed (summary `saveError`) | `UNVERIFIED (code read)`: `StudySessionController.answer` catches `Failure` |
| any open mode | a second command while a write runs | dropped (BR-STUDY-004) | VERIFIED `study_session_controller_test.dart::a second command while a write runs is dropped (BR-STUDY-004)` |
| any open mode | an answer meets a bug (not a `Failure`) | the turn resets with no banner, as for any `Failure` other than a busy database: it is no longer busy and nothing is held; the bug is reported | VERIFIED `study_held_bug_test.dart::an answer that dies on a bug is no longer busy and keeps nothing held (_answer)` |
| any open mode | settling a stalled round meets a bug | the session is no longer busy, so it can settle again; the bug is reported | VERIFIED `study_held_bug_test.dart::a settle that dies on a bug is no longer busy, so the stalled round can settle again (settle)` |
| any open mode | tap ✕ or system Back | exitDialog | VERIFIED `study_session_screen_test.dart::✕ asks first; Stop abandons …`, `::system Back mid-session keeps the ✕ contract …` |
| exitDialog | Keep going | the same card, nothing written | VERIFIED `::Keep studying in the exit dialog changes nothing: the session stays open on the same card (IT-CONT-004)` |
| exitDialog | Stop | summary `leftEarly`; the turns taken stay and the entry offers no Continue | VERIFIED `::✕ asks first; Stop abandons and the same screen shows "You left early"; …`; `study_session_controller_test.dart::abandon ends the session as user_exit and keeps its turns (UC-STUDY-001 A3)` |
| exitDialog | Stop, and the write fails | stopFailed: the toast "Everything you answered is kept. Couldn't stop the session, so try again."; the session stays open on the same card; the next start closes it (BR-STUDY-072) | VERIFIED `::Stop that cannot be written says so, local-first, and the session stays open on the same card` |
| exitDialog | Stop while a turn is held | the held turn is dropped and the summary `leftEarly` shows at once | VERIFIED `::Stop on a held turn shows the summary at once: the hold does not outlive the session` |
| exitDialog (Recall) | opens, then Keep going | the Recall clock stops while the dialog asks and resumes where it stopped | VERIFIED `study_recall_test.dart::the clock stops while the exit dialog asks, and Keep going takes it up where it stopped (BR-STUDY-036)` |
| exitDialog | the deck is deleted or the generation goes stale while it asks | the dialog closes, then deckGone / staleGeneration leaves once | VERIFIED `::the deck gone while the exit dialog is open closes it and leaves, never a blank page` for deckGone; the stale-generation path shares `_leave` and is `UNVERIFIED (code read)` |
| exitDialog | ✕ or system Back again while it is open | ignored (`_isAsking`) | `UNVERIFIED (code read)`: `_confirmAbandon` |
| any open mode | the answer ends the session while a turn is held | the held turn stays; the summary shows once it is released | VERIFIED `::a held turn stays on screen when its answer ends the session; the summary follows its release (spec D5)` |
| any open mode | every remaining card of the round is deleted | stalledRound, then the session serves again | VERIFIED `::a stalled round waits for a held turn before it settles (spec D5)`; `study_session_controller_test.dart::a stalled session settles and serves again (spec D12)` |
| any open mode | the deck is deleted | deckGone: toast, leave to the Library, once | VERIFIED `::the deck moved to the Trash leaves once, for the Library, with a message (UC-STUDY-001 A5)` |
| any open mode | the session is invalidated by a stale generation | staleGeneration: toast, leave to the deck | VERIFIED `::a write from a stale generation leaves for the deck, with no summary (UC-STUDY-001 E4)` |
| summary | tap Done / Study this deck / system Back | the deck / its Study Entry / the deck | Back is VERIFIED in `::system Back mid-session keeps the ✕ contract …`; the two buttons are listed on screen 21 |
| any open mode | the screen is disposed with a write or a voice running | the voice stops; a late result is dropped (`ref.mounted`) | the voice: VERIFIED `study_speech_test.dart::ending the session stops the voice (BR-STUDY-082)`; the dropped result is `UNVERIFIED (code read)` |

## Accessibility

- TalkBack reads the top bar (close, mode, "{done} of {total}"), the context line, then the card: term label and term, pronunciation, meaning label and meaning, example. The footer hint is read last.
- Card faces wrap and never ellipsize; Korean and Vietnamese with stacked marks render whole (UI-base §9 row 102). Touch targets are at least 48 × 48.
- Swipes have accessible actions on the card: "Next card" and, when an earlier card exists, "Previous card".
- Edges (FE-A6 spec D20): the hint does not change; a right swipe on the round's first card does nothing; a left swipe on the stage's last card answers it and the session moves on.

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| default | `study_browse_light.png` | `study_browse_dark.png` | — |
| lookingBack | `study_browse_looking_back_light.png` | `study_browse_looking_back_dark.png` | After a right swipe (or TalkBack "Previous card") the earlier card of the round with a neutral "Looking back" badge (BR-STUDY-048); nothing is written and the counter does not move. `study_browse_test.dart::left advances one stop; right looks back without writing; left from a look-back returns and does not answer twice (IT-MODE-002 steps 4–6, BR-STUDY-048)`. |

**Built (FE-A6 P1c):** `StudyBrowseWidget` inside `StudySessionScreen`. Looking back shows a neutral
"Looking back" badge on the card (BR-STUDY-048: the screen says it is looking back) and reads the
round's trail from the session read model, so it survives a resume; the counter does not move. The
look-back order is the order served, which the stage shuffles (BR-STUDY-022). Goldens
`test/features/study/presentation/goldens/study_browse{,_looking_back}_*`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| default | left swipe, or tap Next | the next card (the live card is answered with an advance, nothing graded) | VERIFIED `study_browse_test.dart::left advances one stop; right looks back without writing; left from a look-back returns and does not answer twice (IT-MODE-002 steps 4–6, BR-STUDY-048)`, `::a visible Next moves on like a left swipe, for a thumb or a switch (critique 2026-09-30)` |
| default | right swipe, or TalkBack "Previous card" | lookingBack: the earlier card of the round with a neutral badge; nothing is written, the counter stays | VERIFIED the same first test; golden `study_browse_looking_back_*` |
| default (first card of the round) | right swipe | nothing; no Previous action offered | VERIFIED `::a right swipe on the round's first card does nothing (FE-A6 D20)`, `::the card offers Next always and Previous only when there is a card behind (IT-MODE-002 step 7)` |
| lookingBack | left swipe, or Next | one step forward, still no answer; the live card again at the end | VERIFIED the first test above |
| lookingBack | a new live card arrives | the look back starts over from the live card | `UNVERIFIED (code read)`: `didUpdateWidget` in `study_browse_widget.dart` |
| default | Next on the stage's last card | the card is answered and the session moves to the next stage or the summary | `UNVERIFIED (code read)`: Browse sends the same advance; the stage change is the session read model's |
| default | Next or a swipe while a write runs | dropped (BR-STUDY-004) | `UNVERIFIED (code read)`: `isBusy` in `_forward`; the controller side is VERIFIED `study_session_controller_test.dart::a second command while a write runs is dropped (BR-STUDY-004)` |
| default | Next, and a busy database refuses the answer | the same card stays with the unsaved-answer banner | VERIFIED `study_session_screen_test.dart::a busy database shows the error on the same card and Retry saves it (UC-STUDY-001 E2)` (it swipes in Browse) |
| default / lookingBack | tap the speaker | the face shown is read (BR-STUDY-079); disabled with the reason when the device lacks the voice | VERIFIED `study_speech_test.dart::with the switch off nothing is read, but the speaker button reads on tap (BR-STUDY-079)`, `::a language the device lacks disables the speaker and says so; auto-play asks the engine, which reads nothing (BR-STUDY-081)` |
| default | a new card is served | the term is read once, when auto-play is on and a learning session runs | VERIFIED `study_speech_test.dart::each new card is read, and only once` |
| default | ✕ or Back, deck deleted, stale write, unreadable session | the route states in [Session route states](#session-route-states) | see the table above |

## Rulings

- **Owner ruling 2026-09-27; IT-NAV-010, IT-CONT-004:** the close icon and system Back open a confirm dialog first: Keep going or Stop.
- The card follows the finger without a tilt while dragged, and stays still with reduced motion.
- Pronunciation uses the detail role of the body face; V8's typography has one family.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the face label and the session context line are eyebrows; the deck name keeps its case.
- **Critique 2026-09-30 part 3c-2 (spec `2026-10-01-critique-fixes-part3c2-design.md`):** the footer hint's glyph sits inline before the first line, and every hint is one line in both languages, so the CTA stands still with no empty line under it (R6, amended at the owner's golden review); the bar is Indigo in every mode (R8); the context line holds two lines at most (R9).
- **Q-C-1 (owner, 2026-10-16):** the footer hint keeps each dot on the phrase before it (`metaDots`); the session context line above every session is capped at two lines with an ellipsis, so it stays unglued, as the Trash meta does (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- Context line: "{deck} · Learning · stage {n} of {total}".
- Footer hint: "Swipe for next or back · nothing is graded" / "Vuốt để chuyển thẻ · không chấm điểm".
