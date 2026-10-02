---
target: "toàn bộ màn hình (screen index 01–33) sau PR #167"
total_score: 28
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:/home/user/memox-v8/docs/shared/ui/screen-handoff/00-index.md"
target_fingerprint: "sha256:2e19679f6a6b742d8f9e4291a4f7f529c3276a594b543e7eb7475b1d01fdc844"
target_path: /home/user/memox-v8/docs/shared/ui/screen-handoff/00-index.md
timestamp: 2026-10-02T04-11-02Z
slug: docs-shared-ui-screen-handoff-00-index-md
---
Method: dual-agent (A: 6 isolated design-review agents by screen group A1–A6 · B: 1 detector agent). Target: all 34 screens in docs/shared/ui/screen-handoff/00-index.md (01–33, incl. 16a); evidence = light goldens for every screen, dark spot-checks, source to confirm. No emulator. P1 findings re-verified by the parent on golden/source. Scope note: screens 29–33 (welcome, sign-in, code, account, users) are new since the 2026-09-30 run, and the reviewer pool differs, so the score is not like-for-like with 31/40.

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of System Status | 3 | Sync, layer and save states are clear; transition layer indeterminate only; 28 tab count 27 over a list of 3 |
| 2 | Match System / Real World | 3 | "Card-days", "wrong turns", "SM-2", "stage 1 of 3", "cycle" still unexplained (02, 14, 16, 21, 22) |
| 3 | User Control and Freedom | 3 | Undo and Cancel almost everywhere; sign-out stopped offline has no exit (30/32); Recall/Fill grades final |
| 4 | Consistency and Standards | 3 | Tokens and Mx* near-perfect; drift: footer hint glyph always a check, flag amber in 07 only, Account rows chevron on dialogs |
| 5 | Error Prevention | 3 | Settle guard, held saves, counted loss dialogs; "Keep on this device" irreversible as primary (27) |
| 6 | Recognition Rather Than Recall | 3 | Labels and samples mostly visible; icon-only Library actions (01), weekday "S S" (22) |
| 7 | Flexibility and Efficiency | 2 | Core loop 4–5 taps per sitting, nothing remembered (14, ruling C5); accent-strict search (04); reminder steppers only (24) |
| 8 | Aesthetic and Minimalist Design | 3 | Calm; card-list top zone 50% chrome (07); summary repeats counts (21) |
| 9 | Error Recovery | 3 | Local-first voice everywhere; summary states untrue facts after interruption/reset/save error (21); import result names no skipped rows (11) |
| 10 | Help and Documentation | 2 | No place explains rounds, turns, card-days, boxes or the two algorithms; footer hints are the only help |
| Total | | 28/40 | Good |

## Design Specificity
Authored for this product in its voice and in a handful of domain objects (recessed answer face, Kept/Lost tiles, box ramp, local-first copy, transition layer "Nothing is lost if you close the app"). The chrome is a disciplined but category-standard Material 3 recipe (white card, 40–44 dp icon tile, two-line row, chevron, bottom sheet); identical tiles (sparkles on every starter, tag glyph on every tag row) carry no information. Product ideas (rounds, 8-box schedule, card-days) barely surface visually.
Detector: `impeccable detect` returned [] (exit 0) for lib/features, lib/shared/widgets, lib/app, but it does not scan .dart (control: .css/.html caught, .dart with Color(0xFF…) not). Fallback greps over lib/features: 0 hardcoded colours, 0 raw spacing literals, 0 raw TextStyle/fontSize, 0 raw Material widgets, 0 hardcoded Text strings; one non-localised literal (Android notification channel name 'Daily reminder'). Architecture check clean; 7 large-file warnings (card_list_section 462, card_editor_form 440, deck_level_screen 412, app_router 477, …). Browser overlay skipped (Flutter canvas, no web build served).

## Priority Issues
1. [P1] 21 Session summary states untrue facts on non-completed outcomes. "Wrong cards came back in later rounds." prints for interrupted, left-early and save-error sessions (verified: summary_interrupted_light.png; session_summary_hero_widget.dart gates only on wrongTurnCount > 0), and the facts card shows a green "Schedules updated" under reset and save-error heroes (session_summary_facts_widget.dart, summaryFactReviewedSub for every non-learning outcome). Fix: outcome-aware copy and tone — the came-back note only for completed sessions ("Wrong cards stay due" otherwise); a neutral row for reset and save error. Cmd: clarify, harden.
2. [P1] 30/32 Sign-out stopped offline traps the user. account_transition_layer_widget.dart:59 offers Cancel only for a switch before the target signs in (canCancelSwitch && !isStuck); the offline sign-out layer offers only Retry (needs a connection) or "Sign out now and lose N changes", under a banner that says "Your data is safe". The Sign out row's hint says only "Your changes are sent first" while the dialog says the phone's data is removed; the confirm is primary. Fix: Cancel on a stopped sign-out before local data is touched; row hint names the outcome; destructive or warning confirm. Cmd: harden, clarify.
3. [P1] 11 Import result names no skipped rows. "Imported with skips" shows counts only (import_partial_light.png); the note asks to fix invalid rows in the source but gives no row numbers or reasons, and the preview is gone. Fix: list skipped rows (row number, first cell, reason) under each count, collapsed to five with Show all, and keep a way back to the preview. Cmd: harden.
4. [P2] Domain vocabulary is never explained (H2/H10): "Card-days" (22), "wrong turns" and "of N turns" (21), "SM-2"/"Eight boxes" eyebrows and "stage 1 of 3" (14, 16), "cycle" (02, 10), Recall's "Counted as forgot". Fix: plain words where possible ("reviews", "cards to revisit"), one-line definitions where not, recommendation lines on the two algorithms. Cmd: clarify.
5. [P2] The core loop is long and remembers nothing (H7): Study tab → deck → Review → direction sheet → Start → first card on SM-2 every sitting; eight-box mode pick resets (14, ruling C5); search is accent-strict for Vietnamese content (04, BR-SEARCH-002); reminder time by steppers only (24, ruling D2). These rest on owner rulings and BRs, so each needs an owner call. Cmd: shape, adapt.

Also P2, single-screen: footer hint glyph is always a check, even on "Not a match" and "Time is up" lines (16a, 17, 18, 19); Progress past-day bars at 55–70% indigo ≈2.3:1, under the 3:1 non-text floor (mx_stacked_day_bars.dart:66-67); 01 "4 cards due" breakdown sums to 6 because "2 new" sits in it; flag is amber in 07 but ink in 09/10 and shares amber with Learning; Account action rows show chevrons though they open dialogs (isAction); Sync shows plain offline as an amber warning with Sync now primary (27); "Keep on this device" is irreversible as a primary indigo confirm (27); import source shows two primaries for one action (11).

## Persona Red Flags
- Exam crammer: summary gives no accuracy, no "due tomorrow" (21); Progress answers "what did I do", not "will I be ready" (22); import silently skips rows (11); the due-count breakdown does not add up (01).
- Self-learner, phone, offline, short sessions: 4–5 taps to the first card (14); sign-out on a flaky connection can lock the app until a connection returns (30); offline styled as a problem on Sync (27); "hoc" finds nothing in search (04).
- Jordan (first-timer): Welcome never says what MemoX does (29); SM-2, stage, cycle, card-days, turns everywhere; icon-only Library actions (01); "A→Z" looks like a control but is inert (05).
- Sam (accessibility): past-day bars under 3:1 (22); footer captions at 0.7 opacity (shared MxFooterBar); dimmed titles beside full-contrast subtitles on disabled rows (02, 32).

## Minor Observations
- 07 card-list top zone takes half the screen; the due count appears three times; chip counts re-scope under search ("All 0").
- 10 history rows: the kind ("Review") is set heavier than the outcome badge; two stacked overlines.
- 14 eight-box: the note repeats the per-row "Not available" reason and lands under the footer.
- 15 rest-state caption "Saved to this device only." beside a disabled Save reads as already saved.
- 16a prompt card's grey answer bar reads as a skeleton.
- 18 "Answer shown — the correct option is highlighted" also after a right answer.
- 19 Forgot/Remembered pale pills with no glyph; misgrade is final.
- 22 weekday initials "S S"; streak tile nested in a card; tray halo looks mid-animation.
- 24 "What it says" title treatment differs between quiet and due states.
- 26 selected row shows a grey pressed ground off the indigo palette.
- 28 tab count "Not sent (27)" over a list of 3; error type repeated.
- 29 Welcome: placeholder tile, ~40% empty gap, Google primary here but outline on 30.
- 30 merge-sheet goldens show a stray "go" behind the scrim (test host).
- 33 offline styled danger-red; every row repeats "Joined Sep 1, 2026".
- Goldens show Hangul as boxes in 04 (missing test font); Vietnamese layouts largely unverified.

## Questions to Consider
- Should the Study tab be a "Today" queue that starts one mixed session in a tap, leaving per-deck entry for those who want control?
- Does the summary exist to reassure or to motivate? It reassures; what one number would bring the crammer back tomorrow?
- Should an offline-first personal app let Sign out take the app away at all, or move the account in the background with a banner?
