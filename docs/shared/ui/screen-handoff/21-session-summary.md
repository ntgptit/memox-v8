<!-- Hand-written screen record. -->

# 21 · Session summary

The terminal screen of a study session: shown once `StudySessionView.status` leaves
`in_progress` and `summary` is set (spec D11, A19).
UC-STUDY-001 (steps 13, A3, E3, E4).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (with no leading control its title starts on the gutter, critique 2026-09-30 part 3c-1) | Title only, in the `screen-title` role and the `foreground` colour: "Session summary". No back control, no actions — v1's minimal bar, Share removed. |
| Hero | `MxCard` (hero) + `MxIconTile` (large, tone-coloured) + `MxStatTile` × 1–2 | Icon and tone by outcome — ok `success` card and tile, paused the accent-tinted tile, ended the `warning` card with a caution tile, error the `danger` card and tile (FE-A6 spec D14) — a title, one body sentence with the headline count bold, and — where the session has facts — only the numbers the body does not state: the finished count when the body has none (an interrupted session), Answered when it differs from the finished count, and Wrong turns "{wrong} of {total}", with "Wrong cards came back in later rounds." under the tiles when wrong > 0 (critique 2026-09-30 part 3c-1, R3). When it fits, the hero and its note sit centred between the app bar and the footer; longer content scrolls from the top (R4). |
| Facts | `MxListSectionHeader` + `MxCard` (full-bleed) + `MxListRow` × 3 | "This session"; rows: finished (label depends on session kind), cards answered, wrong turns — leading a small tinted `MxIconTile`, trailing the value in the `content` role, in `warning` text when wrong > 0 and `foreground` otherwise. Shown only where the hero draws no stats (reset, content deleted, save error); with stats it would repeat them (critique 2026-09-30, R3). Omitted where the session has no facts (`schedulerChanged`). |
| End note | `MxNote` | One calm info line, only for the states that need it. |
| Footer | `MxFooterBar` + `MxActionPair` of `MxButton` × 2 | Outline "Study again" + primary "Done", a caption line under them. "Study again" shows only for `loaded`, `learning`, `large` and `leftEarly` (`SummaryOutcome.canStudyAgain`); it is hidden for `interrupted`, `reset`, `schedulerChanged`, `contentDeleted` and `saveError`, and Done is then alone. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `summary_review_light.png` | `summary_review_dark.png` | `completed`, a reviewing session (BR-STUDY-013); `SummaryOutcome.reviewFinished`. |
| learning | `summary_learning_light.png` | `summary_learning_dark.png` | `completed`, a learning session — finishing the stage sequence is the event, not a graded turn (BR-STUDY-053); `SummaryOutcome.learningFinished`. |
| large | `summary_large_light.png` | `summary_large_dark.png` | `completed` at the `card_limit` ceiling fixed when the session opened (BR-STUDY-024); a variant of `SummaryOutcome.reviewFinished`. |
| leftEarly | `summary_left_early_light.png` | `summary_left_early_dark.png` | `abandoned`/`user_exit` (BR-STUDY-014); turns already answered are kept (BR-STUDY-019). |
| interrupted | `summary_interrupted_light.png` | `summary_interrupted_dark.png` | `abandoned`/`interrupted`: yesterday's session, not resumed today (BR-STUDY-072; UC-STUDY-001 A3b). |
| reset | `summary_reset_light.png` | `summary_reset_dark.png` | `invalidated`/`scheduler_reset`: reset while the session was open, reached on returning to it (BR-STUDY-015). |
| schedulerChanged | `summary_scheduler_changed_light.png` | `summary_scheduler_changed_dark.png` | `invalidated`/`scheduler_changed` (BR-STUDY-016). No Facts card. |
| saveError | `summary_save_error_light.png` | `summary_save_error_dark.png` | `failed`/`persistence_error` (BR-STUDY-018); turns saved before the failure are kept (BR-STUDY-019). |
| contentDeleted | `summary_content_deleted_light.png` | `summary_content_deleted_dark.png` | `invalidated`/`content_deleted`: ended because content moved to Trash (BR-TRASH-004; UC-STUDY-001 A5). |

`contentDeleted` is reachable since the Trash backend (BE-B1,
BR-TRASH-004) and reads "Ended — content moved to Trash", the facts, and the
note "Restore the card from Trash to include it in the next review."

**Built (FE-A6 P1c):** every state above, drawn by `SessionSummaryWidget` on
the session's route (spec D2); goldens `test/features/study/presentation/goldens/summary_*`. `large`
reads "— the session limit" when a completed review's queue reached the `card_limit` the session
opened with (`SessionSummary.cardLimit`, read from `study_session.card_limit`).
There is no loading state: the summary arrives with the session's view, and the route's first load
is a spinner (see [Session route states](16-study-browse.md#session-route-states)). A session left early from a review reads "The {n} cards you reviewed are kept. The
other {m} are still due." (also for a review session).

## Accessibility

- TalkBack reads the title, then the hero (title, body, then each stat as one node "{label}: {value}"), the facts, the note and the footer. The hero glyph is decorative.
- Touch targets are at least 48 × 48; the two footer buttons keep 8 between them.

## Nothing answered

A session that ended before its first turn shows the hero without stats and no Facts card, as
`schedulerChanged` does (FE-A6 spec D18).

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| any open session | the session ends (a finish, Stop, interruption, reset, algorithm change, deleted content or a save error) | the matching state, on the same route | VERIFIED `session_ending_state_test.dart::every end V8 can reach maps to its summary state`; the screens `session_summary_test.dart::a finished review: the body states the count; the one tile is wrong turns, explained (critique 2026-09-30 part 3c-1, R3)` and the goldens `summary_*` |
| any open session | the end is a stale generation | no summary: the route leaves for the deck with a toast | VERIFIED `session_ending_state_test.dart::a stale generation leaves, with no summary (UC-STUDY-001 E4)`; `study_session_screen_test.dart::a write from a stale generation leaves for the deck, with no summary (UC-STUDY-001 E4)` |
| any open session | the last answer ends it while a turn is held | the held turn stays; the summary shows once released | VERIFIED `study_session_screen_test.dart::a held turn stays on screen when its answer ends the session; the summary follows its release (spec D5)` |
| loaded / learning / large / leftEarly | tap Study again | the deck's Study Entry (14) | the button's presence is VERIFIED `session_summary_test.dart::the footer is one MxActionPair: Study this deck 5, Done 6` and `session_ending_state_test.dart::tones, stats, facts and Study this deck follow the kit`; the navigation (`context.go`, `app_router.dart`) is `UNVERIFIED (code read)` |
| interrupted / reset / schedulerChanged / contentDeleted / saveError | the footer | Done only | VERIFIED `session_summary_test.dart::an ended or failed session draws no stats and offers no Study this deck (handoff 21 reset, saveError)` for reset and saveError; the others by `canStudyAgain` in `session_ending_state_test.dart`, as `UNVERIFIED (code read)` on screen |
| any state | tap Done, or system Back | the session's deck (`onDone`); a closed session is never reopened | VERIFIED `study_session_screen_test.dart::system Back mid-session keeps the ✕ contract: it asks, Stop abandons, the turn taken stays, no Continue; Back on the summary is Done, never a return to a closed session (IT-NAV-010)` |
| open session | tap ✕ then Stop | leftEarly, turns kept | VERIFIED `study_session_screen_test.dart::✕ asks first; Stop abandons and the same screen shows "You left early"; …` |
| a deck with a session that ended before its first turn | the summary opens | the hero without stats and without facts (FE-A6 D18) | VERIFIED `session_summary_test.dart::a session that ended before its first turn draws neither stats nor facts (FE-A6 D18)` |
| any state | the deck is deleted while the summary shows | nothing changes on screen; Done leads to a deck that is gone | `UNVERIFIED (code read)`: the route's deck-gone leave runs on an open session's `Rejected` read; the summary's own behaviour is not pinned by a test |

## Rulings (FE-A5)

- **Critique 2026-09-30 part 3c-1 (spec `2026-09-30-critique-fixes-part3c1-design.md`), R3, amends FE-A6 D17:** a tile states only what the body does not; the finished tile is gone except after an interruption, whose body states no count, Answered shows only when it differs, Wrong turns is explained under the tiles. R4: a short summary sits centred.

- `stale_generation` never reaches this screen: the write is refused, the session closes, and
  the app returns to the deck list (UC-STUDY-001 E4; it is not folded into `reset`).
  `reset` here is `scheduler_reset` only.
- "Study again" opens Study entry (14), via `go`; both ship in FE-A6. It shows only where `canStudyAgain` holds (see Layout).
- The app bar title is the app bar's own title (the `screen-title` role); the hero glyph is `MxIconTile` large (44) in the outcome tone.
- Fact rows are `MxListRow`; the wrong-turns sub-line wraps in the note role in the row's sub-line slot.
- `SessionSummary` carries "answered" and "total turns" (FE-A6) for the hero's three stats: finished, answered, wrong/total.
- **Critique 2026-09-30:** the wrong-turns value reads "{wrong} of {total}" ("{wrong} trên {total}").
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the hero's overline is an eyebrow that keeps the deck name as typed ("REVIEW SESSION · Nhà hàng"); the stat labels are eyebrows.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** "Wrong cards came back in later rounds." follows only a finished session; the facts of an ended or failed session read "Kept in the history" under the finished count, on a neutral tile with the value in plain text colour, and "of {total} turns" under the wrong turns (F1).

## Copy

- App bar: "Session summary".
- Hero titles: "Review finished" · "Learning finished" · "You left early" · "Session interrupted" ·
  "Ended by a reset" · "Ended by an algorithm change" · "Stopped by a save error".
- Hero bodies: "You reviewed {n} cards. Their next due dates are set." ·
  "{n} cards finished learning. They come back tomorrow at 00:00." · "You reviewed {n} cards — the
  session limit." · "The {n} cards you finished are kept. The other {n} stay new and will be offered
  again." · "This session from yesterday was closed by the system and could not be resumed today. Every
  answer you gave is kept." · "Learning progress of this deck was reset while you were studying, so this
  session could not continue. Answers given before the reset stay in the history of the earlier cycle." ·
  "The deck switched to a different review algorithm, so its learning sequence changed. Every card is new
  again; Done takes you back to the deck to start learning." · "An answer could not be written to this device, so the session
  stopped. Everything saved before that is kept; the unanswered cards are still due."
- Facts: "This session" · "Cards that finished learning" / "Cards reviewed" · "Kept in the history" ·
  "Cards answered" · "Wrong turns" · "{wrong} of {total}" · "of {total} turns".
- End note: "Nothing was lost — the answers are in the history." (`schedulerChanged` only, in V8).
- Footer: "Study again" · "Done" · "Done returns you to the deck."
