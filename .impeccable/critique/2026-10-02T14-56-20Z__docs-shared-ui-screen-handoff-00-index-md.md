---
target: "toàn bộ màn hình (screen index 01–33) sau PR #188"
total_score: 27
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 3
target_identity: "file:D:\\workspace\\memox-v8\\.claude\\worktrees\\design-ux-audit-harden-8622fb\\docs\\shared\\ui\\screen-handoff\\00-index.md"
target_fingerprint: "sha256:2e19679f6a6b742d8f9e4291a4f7f529c3276a594b543e7eb7475b1d01fdc844"
target_path: "D:\\workspace\\memox-v8\\.claude\\worktrees\\design-ux-audit-harden-8622fb\\docs\\shared\\ui\\screen-handoff\\00-index.md"
timestamp: 2026-10-02T14-56-20Z
slug: docs-shared-ui-screen-handoff-00-index-md
---
Method: dual-agent (A: 6 isolated design-review agents by screen group A1–A6 · B: 1 detector agent). Target: all 34 screens (01–33, incl. 16a), after PR #188. Evidence: every light golden, dark spot-checks, source to confirm. No emulator. Majors re-verified by the parent (settings_sync_section_widget.dart:35 + sync_labels_widget.dart:57; reminder_preview_due_light.png; import_mapping_light.png; import_source_section_widget.dart:112-186).

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of System Status | 3 | Clear sync/due/streak states; reminder preview shown while off reads as pending; layer errors drop the step title (30) |
| 2 | Match System / Real World | 2 | SM-2, stage, cycle, turns, card-days, Front·Term double naming (carried over) |
| 3 | User Control and Freedom | 3 | Undo/Cancel almost everywhere; Browse back is swipe-only; "Start a new review instead" hides that it ends the open session |
| 4 | Consistency and Standards | 3 | Mx* near-perfect; offline drawn three ways (note/warning/danger); Settings Sync tile vs screen 27 disagree |
| 5 | Error Prevention | 3 | Kept/Lost tiles, merge preview, settle guard; draft-only flag in edit looks instant |
| 6 | Recognition Rather Than Recall | 3 | Icon-only Library actions; import mapping trigger is bare text; Users rows give no tap cue |
| 7 | Flexibility and Efficiency | 2 | No one-tap "study what is due" (owner ruled); no select-all in Trash; tag → cards takes 2 taps |
| 8 | Aesthetic and Minimalist Design | 3 | Calm; notes stacked above content; overlines repeat titles; Import 4 orientation layers; Monitoring 45% controls |
| 9 | Error Recovery | 3 | Local-first voice everywhere; bulk-fail banner does not name the action; Study options caption contradicts the Not-saved banner |
| 10 | Help and Documentation | 2 | Footer hints and notes are the only help; nothing defines turns, card-days, boxes |
| Total | | 27/40 | Acceptable (one point under Good) |

## Design Specificity
Authored for this product: recessed answer face, Kept/Lost tiles, box ramp, local-first copy, merge preview. The chrome is a disciplined category-standard M3 recipe; identical leading tiles (sparkles on every starter, tag glyph on every tag, hint rows) carry no information.
Detector: `impeccable detect` exit 0, [] — it reads .dart only as raw text with CSS/HTML rules (control proved it), so [] is not evidence for Flutter. Real evidence: guard `memox-v8` 87 rules, 0 violations; greps: 0 raw colours, spacing, TextStyle, raw Material widgets, hardcoded strings; 7 GestureDetector in features (ink/semantics to check), 1 Opacity outside shared (study_settle_guard_widget.dart:64). Architecture clean, 7 large-file warnings. Browser overlay not attempted (Flutter canvas, no served web build).

## Priority Issues
1. [P1] 23 Settings Sync tile turns amber on a plain "no connection" while screen 27 (F8) shows it as a neutral note. Fix: warning only for server, sign-in and refused rows; network = tinted tile. Cmd: harden, clarify.
2. [P1] 11 Import mapping: the tappable field choice ("Term (front) ⌄") is the weakest element in its row; four orientation layers (app bar, breadcrumb, tracker, numbered overline) push content to ~21%. Fix: chip/outline trigger; drop the overline numbers. Cmd: layout.
3. [P1] 24 Reminder: "What it says" preview ("3 cards are due in Korean.") is the dominant element while the reminder is off and under error banners; reads as a pending notification. Fix: show only when on, or caption it "When on, it would read". Cmd: clarify, layout.
4. [P2] Offline drawn three ways (neutral note 29/30/32, warning 30 layer, danger tile 33) and warning amber used for non-loss conditions (23, 24 off-may-show). Fix: one DESIGN.md rule. Cmd: clarify.
5. [P2] Notes, overlines and footer captions that repeat or contradict the screen (15 "Saved to this device only" under "Not saved"; 21 "Done returns you to the deck"; 23/32 one-row overlines; 02 "locked" ×3; 25 obvious note). Cmd: distill.
Carried over (owner calls): domain vocabulary (H2/H10); no one-tap start for due (13, ruling R2); Guess 1.2 s auto-advance (ruling).

## Persona Red Flags
- Exam crammer: summary gives no accuracy or next due (21); "17" on Progress has no noun (22); Trash expiring entries sorted last (06).
- Self-learner offline: Settings warns amber on a train (23); Users offline painted as danger (33); "hoc" finds nothing (04).
- Jordan (first-timer): sparkles icon for starter decks (01); SM-2/stage/turns; Import mapping looks like static text (11); Code field has no six-slot shape (31).
- Sam (accessibility): see the audit pass.

## Minor Observations
See the per-screen tables in the chat report (≈70 Minor findings across 34 screens).

## Questions to Consider
- Should the Study tab start "what is due" in one tap, leaving per-deck entry for control?
- Can every note pass the test "does it say something the screen does not already show"?
