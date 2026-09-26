# MemoX V8 — Study UI (FE-A6, FE-A7)

Status: approved by the owner (2026-09-26).

## 1. Intent

Build the study flow on the finished backend (BE-A3, BE-A4, BE-A5, BE-A10). A learner
opens a deck's Study entry, starts a learning or review session, answers it through
the six modes, and lands on the session summary. It is specified by the screen
handoff 14, 16, 16a, 17–21 (`docs/shared/ui/screen-handoff/`), UC-STUDY-001 and
UC-STUDY-003, and the study and study-mode rules. Screen 13 (Study home, FE-A8) is
not part of it.

## 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | Study entry is a Library child route, `/decks/deck/:deckId/study`, like the algorithm screen; the tab bar stays. | It belongs to one deck and returns there with Back. |
| D2 | A session is one full-screen route, `/study/session/:sessionId`, on the root navigator, with no tab bar. The summary is the same route once the session has ended, not a second route. | `WatchStudySessionUseCase` already carries the summary; one route means one Back story and no hand-off race when the last turn commits. |
| D3 | `StudySessionScreen` watches the session and picks its body with an exhaustive `switch` over `StudyMode`, plus the summary once `summary != null`. There is no mode registry. | Six fixed modes (BR-MODE-002); an exhaustive switch makes a seventh a compile error, not a runtime miss. |
| D4 | One `@riverpod` session controller owns the commands: answer, recall reveal, recall time save, fill hint and abandon. It holds a single in-flight flag, so a second tap while a write runs is dropped (BR-STUDY-004). Mode widgets never call use cases. | One write path per session; widgets stay presentational (no business logic in UI). |
| D5 | **Feedback hold.** The screen keeps the item that was answered, with its `TurnResult`, on screen until that mode's continue condition is met (an auto-advance delay, or a Continue tap). Only then does it show the stream's current item. The stream is never shown mid-feedback. | BR-STUDY-063 (result after commit) and BR-STUDY-064 (the unit stays on screen). The stream moves on at commit, so without the hold the outcome would be lost. |
| D6 | Write failures: a `DatabaseLockedFailure` shows an inline error on the same turn with the answer kept, to retry (UC-STUDY-001 E2). Any other failure has already failed the session, and the summary's "Save error" state opens (E3; the summary is where the error shows and the way back to the deck). | Mirrors `AnswerStudyTurnUseCase`: it rethrows a lock and fails the session on any other failure. |
| D7 | Ended sessions: `staleGeneration` pops back to the deck list with a snackbar and no summary (UC-STUDY-001 E4, ruling in handoff 21). A session whose deck was deleted (`notFound`) pops to the list (A5). Every other end reason shows the summary state of handoff 21. | UC over kit. |
| D8 | Exit: the ✕ and system Back abandon the session at once, with no confirm (handoff 16); the same route then shows the summary "You left early" (D2), whose Done returns to the deck. Back on the summary is Done. | Owner, 2026-09-26 (before P1c): an abandoned session cannot be continued (UC-STUDY-001 A3, A3b; BR-STUDY-014, BR-STUDY-072), and the kit draws `leftEarly`. Answered turns are kept. |
| D9 | App start runs `AbandonStaleSessionsUseCase` once, before the first frame that can show a resumable session. | BR-STUDY-072: a session from an earlier day is `interrupted`, never resumed. |
| D10 | Entry points: a real `DeckAction.study` in the deck action sheet, and the card list summary's "Study this deck". Both leave the Coming soon sheet; Study options stays there (spec A4). Study home (A8) adds its own entry later. | Handoff 07 and 14. |
| D11 | Two backend additions, each with its own tests, in the phase that needs it. `SessionSummary` gains `answeredCardCount` and `turnCount` (P1, handoff 21). A read-only `PreviewSelfAssessIntervalsUseCase` returns the four next intervals for a scheduled `self_assess` turn and null on a relearning turn, computed by the same `Sm2Scheduler.next` the write uses (P2, handoff 16a). | The kit's summary numbers; the owner-confirmed 16a brief. |
| D12 | Recall's clock is a widget ticker. `SaveRecallTimeUseCase` runs on `AppLifecycleState.paused` and on dispose, never per tick. At zero, the ticker answers `RecallAnswer(timedOut)`. | BR-STUDY-031, BR-STUDY-036. |
| D13 | Layout follows the Library pattern: `lib/features/study/presentation/{providers,controllers,states,screens,widgets/{sections,items,overlays}}`; use-case providers one per file; `app/` composes and routes (spec A14). | ADR-010 and the Library screens. |
| D14 | **Summary hero tones.** The theme binds the PRESERVE_ONLY `success` semantic as a field of `MxSemanticColors` (a green of its own, never `mastery`), and `MxIconTile` and the hero card gain a `success` and a `danger` tone (`danger` on the existing soft danger tint, `dangerSoft`/`dangerBorder` with the `error` glyph, as `MxInlineBanner` and `MxErrorState` draw it; the solid `errorFill`/`onErrorFill` pair stays the destructive button's). Outcome → tone: ok (`completed`) success; paused (`user_exit`, `interrupted`) tinted; ended (`scheduler_reset`, `scheduler_changed`) warning; error (`persistence_error`) danger. Built under `flutter-theme-design` (theme slot and Mx widget together). | Owner, 2026-09-26 (Impeccable critique before P1): the kit's four tones; green stays mastery-only. |
| D15 | **Study entry read model.** `StudyEntry` gains `overdueCardCount` (the due cards whose due day is before today, same local-day boundary as BR-STUDY-068) and `resumable`, a `ResumableSession` (the Study Home shape: kind, mode, progress) replacing the bare `resumableSessionId`. Each with its own repository test, in P1. | Owner, 2026-09-26: the kit's overdue note and resume banner. |
| D16 | **Deck context on the entry.** The deck name and breadcrumb come from the deck feature, composed by `app/` and passed to the entry screen as a widget, as the card editor's `_deckContext` does: `study` may not import `deck` (`boundary_rules.dart`). | ADR-011 D2. |
| D17 | **`MxStatTile`.** A new shared widget: a large tabular number over a small-caps label, inked as the kit draws New and Due (Due above zero primary, New above zero muted, a zero plain), one semantics node "{label}: {value}". Callers: the entry hero (New, Due) and the summary hero (three stats). Built under `flutter-theme-design`, with its widget test and goldens. | Owner, 2026-09-26: two callers exist (14, 21). |
| D18 | **A summary with nothing answered.** A session that ended before its first turn shows the hero without stats and no Facts card, as `schedulerChanged` does. | Owner, 2026-09-26. |
| D19 | **Accessibility.** 14, 16 and 21 follow 16a's rules: card faces wrap and never ellipsize; single-line text keeps line-height 1.5 for stacked marks (UI-base §9 row 102); every target 48 dp; the resume pulse dot and hero glyphs are decorative (no own node); a stat tile is one node; the Browse card reads term then meaning; the feedback hold keeps focus on the card. | Owner, 2026-09-26. |
| D20 | **Browse edges.** The footer hint does not change; a right swipe on the round's first card does nothing; a left swipe on the stage's last card answers it and the session moves on. | Owner, 2026-09-26. |

## 3. Screens by phase

| Phase | Scope | Makes usable |
|---|---|---|
| P1 | Theme tones and `MxStatTile` (D14, D17); the entry read model (D15); routes; the session shell (top bar, context line, exit, feedback hold, ended states); Study entry 14 without the direction sheet; Browse 16; Summary 21 with D11a and D18; entry points (D10); stale-session sweep (D9); the session read model carries Browse's trail of the round's shown cards, for looking back (BR-STUDY-048). | Screens 14, 16 and 21 end to end. A Browse-only stage can complete. |
| P2 | Self-check 16a with D11b; the direction sheet (FE-A7, UC-STUDY-003); the Study entry's actions (Learn, Review, Continue; starting, refused, startFailed; resume), which P1 left read-only. | `sm2` decks: learning (browse → self_assess) and review. |
| P3 | Guess 18, Match 17. | Those stages. |
| P4 | Recall 19 (D12), Fill 20. | `eight_box` decks end to end. |
| P5 | The HOST-FLOW scenarios of `docs/features/study/it-scenarios.md` and `study-mode/it-scenarios.md` not yet covered; index rows 14 and 16–21 → built/aligned; WBS FE-A6 and FE-A7 → xong. | The IT set is closed. |

**Unbuilt stages are never offered.** A learning session runs its algorithm's whole stage
sequence (BR-MODE-004), so the entry offers Learn only when every stage of that
sequence is built, and offers a review mode only when that mode is built. The
presentation layer keeps one constant set of built modes, which grows each phase. What
it excludes shows as not available with the reason "Coming soon". So P1 starts no
session from the UI: its screens are exercised by tests that open sessions through the
harness. P2 makes `sm2` usable, and P4 makes `eight_box` usable. The set is deleted in
P4, once every mode is built.

## 4. Verification

- Each phase: TDD for controllers and use cases; widget tests for its HOST-WIDGET scenarios; visual-audit companions for new screens (the coverage test requires them); goldens light and dark, generated in the Linux container.
- `dod_check.sh` green; the final opus review per phase; one PR per phase after the owner's approval.

## 5. Out of scope

Study home (FE-A8), Study options (FE-A3), streaks, audio, editing a card mid-session,
and tablet layouts.
