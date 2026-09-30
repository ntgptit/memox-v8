<!-- Hand-written screen record. -->

# 21 · Session summary

The terminal screen of a study session: shown once `StudySessionView.status` leaves
`in_progress` and `summary` is set (spec D11, A19).
UC-STUDY-001 (steps 13, A3, E3, E4).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density; with no leading control its title starts on the gutter, critique 2026-09-30 part 3c-1) | Title only, muted ink: "Session summary". No back control, no actions — v1's minimal bar, Share removed. |
| Hero | `MxCard` (hero) + `MxIconTile` (large, tone-coloured) + `MxStatTile` × 1–2 | Icon and tone by outcome — ok `success`, paused tinted, ended `warning`, error `danger` (FE-A6 spec D14) — a title, one body sentence with the headline count bold, and — where the session has facts — only the numbers the body does not state: the finished count when the body has none (an interrupted session), Answered when it differs from the finished count, and Wrong turns "{wrong} of {total}", with "Wrong cards came back in later rounds." under the tiles when wrong > 0 (critique 2026-09-30 part 3c-1, R3). When it fits, the hero and its note sit centred between the app bar and the footer; longer content scrolls from the top (R4). |
| Facts | `MxListSectionHeader` + `MxCard` (full-bleed) + `MxListRow` × 3 | "This session"; rows: finished (label depends on session kind), cards answered, wrong turns — leading a small tinted `MxIconTile`, trailing the value in tabular numerals, warning ink when wrong > 0. Shown only where the hero draws no stats (reset, content deleted, save error); with stats it would repeat them (critique 2026-09-30, R3). Omitted where the session has no facts (`schedulerChanged`). |
| End note | `MxNote` | One calm info line, only for the states that need it. |
| Footer | `MxFooterBar` + `MxButton` × 2 | Outline "Study this deck" (hidden once the outcome is `ended`/`error`) + primary "Done" (disabled while loading); a caption line under them. |
| Loading | `MxSkeleton` | Hero and fact-row shapes while the summary is read. |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `summary_review_light.png` | `summary_review_dark.png` | `completed`, a reviewing session (BR-STUDY-013). |
| learning | `summary_learning_light.png` | `summary_learning_dark.png` | `completed`, a learning session — finishing the stage sequence is the event, not a graded turn (BR-STUDY-053). |
| large | `summary_large_light.png` | `summary_large_dark.png` | `completed` at the `card_limit` ceiling fixed when the session opened (BR-STUDY-024). |
| leftEarly | `summary_left_early_light.png` | `summary_left_early_dark.png` | `abandoned`/`user_exit` (BR-STUDY-014); turns already answered are kept (BR-STUDY-019). |
| interrupted | `summary_interrupted_light.png` | `summary_interrupted_dark.png` | `abandoned`/`interrupted`: yesterday's session, not resumed today (BR-STUDY-072; UC-STUDY-001 A3b). |
| reset | `summary_reset_light.png` | `summary_reset_dark.png` | `invalidated`/`scheduler_reset`: reset while the session was open, reached on returning to it (BR-STUDY-015). |
| schedulerChanged | `summary_scheduler_changed_light.png` | `summary_scheduler_changed_dark.png` | `invalidated`/`scheduler_changed` (BR-STUDY-016). No Facts card. |
| saveError | `summary_save_error_light.png` | `summary_save_error_dark.png` | `failed`/`persistence_error` (BR-STUDY-018); turns saved before the failure are kept (BR-STUDY-019). |
| loading | no golden | no golden | — |
Other goldens: `summary_content_deleted_light.png` / `summary_content_deleted_dark.png` (ended because content moved to Trash).


`contentDeleted` (`invalidated`/`content_deleted`) is reachable since the Trash backend (BE-B1,
BR-TRASH-004) and reads "Ended — content moved to Trash", the facts, and the
note "Restore the card from Trash to include it in the next review."

**Built (FE-A6 P1c):** every state above but `loading`, drawn by `SessionSummaryWidget` on
the session's route (spec D2); goldens `test/features/study/presentation/goldens/summary_*`. `large`
reads "— the session limit" when a completed review's queue reached the `card_limit` the session
opened with (`SessionSummary.cardLimit`, read from `study_session.card_limit`).
`loading` is not reachable: the summary arrives with the session's view, and the route's first load
is a spinner. A session left early from a review reads "The {n} cards you reviewed are kept. The
other {m} are still due." (also for a review session).

## Accessibility

- TalkBack reads the title, then the hero (title, body, then each stat as one node "{label}: {value}"), the facts, the note and the footer. The hero glyph is decorative.
- Touch targets are at least 48 × 48; the two footer buttons keep 8 between them.

## Nothing answered

A session that ended before its first turn shows the hero without stats and no Facts card, as
`schedulerChanged` does (FE-A6 spec D18).

## Rulings (FE-A5)

- **Critique 2026-09-30 part 3c-1 (spec `2026-09-30-critique-fixes-part3c1-design.md`), R3, amends FE-A6 D17:** a tile states only what the body does not; the finished tile is gone except after an interruption, whose body states no count, Answered shows only when it differs, Wrong turns is explained under the tiles. R4: a short summary sits centred.

- `stale_generation` never reaches this screen: the write is refused, the session closes, and
  the app returns to the deck list (UC-STUDY-001 E4; it is not folded into `reset`).
  `reset` here is `scheduler_reset` only.
- "Study this deck" opens Study entry (14); both ship in FE-A6.
- The app bar title uses the content bar's title role; the hero glyph is `MxIconTile` large (44) in the outcome tone.
- Fact rows are `MxListRow`; the wrong-turns sub-line wraps in the note role in the row's sub-line slot.
- `SessionSummary` carries "answered" and "total turns" (FE-A6) for the hero's three stats: finished, answered, wrong/total.
- **Critique 2026-09-30:** the wrong-turns value reads "{wrong} of {total}" ("{wrong} trên {total}").

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
- Facts: "This session" · "Cards that finished learning" / "Cards reviewed" · "Now scheduled, due
  tomorrow" / "Schedules updated" · "Cards answered" · "Wrong turns" · "{wrong} of {total}" · "of {total} turns" · "wrong cards
  came back in later rounds".
- End note: "Nothing was lost — the answers are in the history." (`schedulerChanged` only, in V8).
- Footer: "Study this deck" · "Done" · "Done returns you to the deck." · "Loading your summary…".
