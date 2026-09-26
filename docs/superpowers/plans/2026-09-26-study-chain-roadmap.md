# Study screen chain — roadmap for the phases left (P3 → P6)

Status: approved by the owner (2026-09-26): run P3 → P6 back to back, merging each phase's PR once green.

> **For agentic workers:** this roadmap does not replace the per-phase plans.
> At the start of each phase, write that phase's detailed plan with
> writing-plans, from this roadmap's rulings, then execute it with
> executing-plans. Each phase ships its own PR.

**Goal:** finish every study screen of V8.0: Guess 18 and Match 17 (P3), Recall 19
and Fill 20 (P4), the IT scenarios and records (P5), and Study Home 13 (P6,
FE-A8). The owner approves this roadmap once; the phases then run back to back
with no check-in between them.

**Spec:** [2026-09-26-study-ui-design.md](../specs/2026-09-26-study-ui-design.md) (D4, D5,
D12, D19, §3), screen handoffs 13, 16 (the section shared by the session
screens), 17–20, UC-STUDY-001 and UC-STUDY-002, and the study and study-mode rules. FE-A8
has no spec of its own: [13-study-home.md](../../shared/ui/screen-handoff/13-study-home.md)
and UC-STUDY-002 are its brief (the backend is BE-A6, `WatchStudyHomeUseCase`).

**Built so far:** P1a–P1c (#71, #73): the entry read model, the session route,
Browse 16 and Summary 21. P2 (#75): Self-assess 16a, the entry's actions and
the direction sheet. `sm2` decks work end to end.

## How each phase runs (no stops between phases)

1. **Read the kit** for the phase's screens and all their states (the Artifact
   tool's `read`; decoded modules in the scratchpad), and the handoffs.
2. **Impeccable before the plan:** a dual-agent critique of the kit states
   against the handoff. Its findings become rulings in the plan, not
   questions.
3. **The detailed phase plan:** written with writing-plans at
   `docs/superpowers/plans/2026-09-26-study-p<N>-<topic>.md`, built on the
   rulings below. It is committed with the phase, and nobody is asked to
   approve it: this roadmap is the approval.
4. **Execute it Native:** executing-plans, TDD, the ledger, `task-done` per task.
5. **The final whole-branch review** (opus), then one fix pass
   (RED→GREEN for each fix).
6. **Impeccable after the build:** dual-agent critique and audit of the
   goldens against the kit; everything found is fixed in one batch.
7. **Records:** handoffs, index rows, WBS, spec §3.
8. **The PR:** merge `origin/master` into the branch, run the gate
   (`dod_check.sh` plus the goldens) on the merged result, open the PR with
   every ruling in its body, and squash-merge it once green. Then the next
   phase starts.

**When I stop and ask** (and only then):

- an irreversible or destructive action outside the branch;
- a security-sensitive change;
- a conflict that the precedence order (BR/UC > kit > UI spec) cannot settle
  and that would change stored data or business behaviour;
- a gate or test failure I cannot root-cause after systematic debugging.

Everything else becomes a ledgered ruling and appears in the PR body. After
the last phase, one report lists every ruling of every phase.

---

## P3 — Guess 18, Match 17, choosing a review mode, top bar at large text

**Makes usable:** `eight_box` reviews in Match and Guess. `builtStudyModes`
gains `guess` and `match`. `eight_box` Learn still waits for P4, which builds
recall and fill.

| # | Ruling | Why |
|---|---|---|
| G1 | Guess: after the write commits, the chosen and the correct option take their tones (correct/wrong) and the other three fade. The turn is held (D5) for 1200 ms, then the next question follows; a tap on the screen continues early. Under Remove animations the tones change with no fade, and the hold stays. | 18: "only the first tap counts", result after commit (BR-STUDY-063); 16's shared rule: "each mode declares its own outcome-display duration". |
| G2 | The correct option is the option whose `cardId` is the served card's; it is never matched by text. | BR-STUDY-041. |
| G3 | A blocked question (`GuessQuestion.isBlocked`) shows an in-session notice, "This question can't be shown", with Close as its only action. Nothing is written or skipped. | BR-STUDY-040: block it, render nothing, record nothing. |
| M1 | Match: tap a term, then a meaning. Tapping another term re-selects; a meaning tapped with no term selected does nothing. The pair is answered with `MatchAnswer(meaningCardId)` on the selected term's card. | 17's footer hint; the repository's pending-pair contract (BR-STUDY-049, BR-STUDY-062). |
| M2 | A wrong pair flashes both tiles in the error tone for 600 ms after the write commits, and then both go back to idle. A right pair shows as matched, from the stream. | 17's deviation row (BR-STUDY-063, BR-STUDY-070). |
| M3 | Context lines: "{deck} · {kind} · Match · round {n} · {k} pairs left" (k is the board's unmatched terms) and "{deck} · Review · Guess · round {n} · first pick counts". Learning sessions add the stage, as Browse does. | 17 and 18 copy; P1c's learning line. |
| E1 | The `eight_box` review list becomes selectable: available rows are `MxOptionRow`s, and the first available mode in kit order (Match, Guess, Recall, Fill) is selected at first. The footer reviews the selected mode: "Review {n} due cards", with the caption "{Mode} · {n} due cards · oldest first". The selection is not persisted (default review modes belong to FE-A3 Study options). A single available mode is selected with nothing else to pick (BR-STUDY-055). | Kit `eightBox` frame; 14 copy. |
| T1 | `MxStudyTopBar`: the progress track keeps a minimum width of 48, and the mode chip flexes and ellipsizes on one line (height 1.5, UI-base §9 row 102). This includes a 2x text test and a golden. | Owner ruling after P2. |

**Before the plan:** read the backend's match board and guess option reads
(`StudySessionView.board`, `StudyItem.guess`) and `TurnResult.isCorrect`, the
kit frames `img/17-study-match/`, `img/18-study-guess/` and
`img/14-study-entry/eightBox-*`, and the kit modules.

## P4 — Recall 19, Fill 20, `eight_box` end to end

**Makes usable:** `eight_box` Learn (browse → match → guess → recall → fill)
and all four review modes. `builtStudyModes` and its "Coming soon" branches
are deleted (spec §3).

| # | Ruling | Why |
|---|---|---|
| R1 | Recall's clock is a widget-local ticker that starts from `StudyItem.remainingMs`. The controller gains `saveRecallTime(item, remainingMs)`, called on `AppLifecycleState.paused` and on dispose and never per tick, `revealRecall(item, remainingMs)`, and `showFillHint(item)`. Every write still goes through the controller. | D4, D12, BR-STUDY-031, BR-STUDY-036. |
| R2 | "Show the meaning" reveals (a write with no outcome). "Forgot" and "Remembered" answer, and the next card follows at once. When the clock reaches zero, the screen answers `RecallAnswer(timedOut)` with `shouldHoldFeedback: true`; the timedOut state ("Counted as forgot") shows until Continue releases the hold. | 19's states, BR-STUDY-032, BR-STUDY-033, BR-STUDY-066; P1c's hold. |
| R3 | Recall and Fill pass the mastery colour to the top bar's accent. | 16's shared section (kit choice). |
| F1 | Fill's field: `MxTextField` gains a bare variant (no chrome) with a study answer text role in `MxTextStyles`, built under flutter-theme-design. | 20 layout (the no-per-site-text-styling guard). |
| F2 | Check is disabled while the trimmed answer is empty, and IME Done submits. | BR-STUDY-029. |
| F3 | A wrong answer is held (D5) and shows the typed text struck through, the correct term, and "Wrong · comes back next round", until Continue. A right answer lets the next turn follow at once. The typed text lives only in widget state, which is keyed per turn, and is never persisted. | 20, BR-STUDY-027, BR-STUDY-030, BR-STUDY-059. |
| F4 | "Show hint" appears only when the card has a hint and it has not been shown yet (`StudyItem.isHintShown`); it goes through the controller. | BR-STUDY-028. |

## P5 — the IT set, and records closed

- The HOST-FLOW and HOST-WIDGET scenarios of `docs/features/study/it-scenarios.md` and
  `docs/features/study-mode/it-scenarios.md` that no test covers yet each
  get a test tagged with its IT id (`tools/docs/check.py` counts ids that no
  test contains).
- Index rows 14 and 16–21 → `aligned`; `wbs_FE.md` FE-A6 → `xong`.
- The spec's P2–P5 rows point to their plans; the deferred minors of P1–P4
  are either closed or carried to the UI-base debt register (§9).

## P6 — FE-A8 Study Home 13

**Makes usable:** the Study tab (it is a placeholder today). The brief is
handoff 13 and UC-STUDY-002; the read model is BE-A6.

| # | Ruling | Why |
|---|---|---|
| H1 | The handoff 13 deviations stand: the date is dropped; the pulse dot is primary; starter decks are hidden (`noDecks` offers only "Go to Library"); the hero breakdown gains a fourth term, "Scheduled" (`MxWorkloadBreakdownLine`). | 13's deviation table (BR-STUDY-068, spec A4). |
| H2 | `MxLinearProgress`: a new shared widget, the themed `LinearProgressIndicator`, built under flutter-theme-design. Its callers are 13's resume card and 14's resume banner, which gains the track in the same PR. | 13's deviation row: two callers. |
| H3 | Resume runs `ResumeStudySessionUseCase` and then opens the session route. A refusal shows a toast and the Study Home stream refreshes. A deck row opens that deck's Study Entry, and "Library" opens `/decks`. | UC-STUDY-002, D1, D2; P2's Continue path. |
| H4 | Study Home stays read-only (BR-STUDY-075): the stale-session sweep stays in `app/` (D9). | BR-STUDY-075. |

## After P6

One report lists every phase's PR, its rulings with their cost if wrong, the
deferred minors, and what is left in the WBS (FE-A3, FE-A9).
