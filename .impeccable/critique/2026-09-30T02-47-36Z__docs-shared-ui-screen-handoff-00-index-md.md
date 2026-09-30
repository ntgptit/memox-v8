---
target: toàn bộ màn hình (screen index 01–28)
total_score: 31
max_score: 40
na_heuristics: 
p0_count: 0
p1_count: 6
target_identity: "file:/home/user/memox-v8/docs/shared/ui/screen-handoff/00-index.md"
target_fingerprint: "sha256:acf014311396870ec99df8a245a79d616cf9ab384bf6ed7d5c7b34e46a153136"
target_path: /home/user/memox-v8/docs/shared/ui/screen-handoff/00-index.md
timestamp: 2026-09-30T02-47-36Z
slug: docs-shared-ui-screen-handoff-00-index-md
---
Method: dual-agent (A: 6 isolated design-review agents by screen group A1–A6 · B: 1 detector agent). Target: all 29 screens in docs/shared/ui/screen-handoff/00-index.md; evidence = goldens (~186 light + dark spot-checks), no emulator. All Major findings re-verified by the parent on golden/source.

## Design Health Score
| # | Heuristic | Score | Key issue |
|---|---|---|---|
| 1 | Visibility of System Status | 3 | Syncing state is a faint spinner; options save-failure only a muted caption; Match silent no-op |
| 2 | Match System / Real World | 3 | "wrong turns", card-days vs cards unlabeled; "Created" has 4 names |
| 3 | User Control and Freedom | 3 | Sync "Keep on this device" one-way, no confirm/Undo |
| 4 | Consistency and Standards | 3 | Tokens/Mx* near-perfect; composition drift (One Indigo, section-label, sheet headers) |
| 5 | Error Prevention | 3 | No settle guard reveal→grade; Edit Save live when pristine; import mapping blind |
| 6 | Recognition Rather Than Recall | 3 | Progress drill-down unsignalled; "Level · 2"; mapping without sample |
| 7 | Flexibility and Efficiency | 3 | Long-press select, hold-repeat, swipe; no start-from-hero |
| 8 | Aesthetic and Minimalist Design | 3 | Calm, but the same number repeated 3–4x on many screens |
| 9 | Error Recovery | 4 | Local-first voice consistent everywhere, Retry in place |
| 10 | Help and Documentation | 3 | Per-state footer hints good; unit definitions scattered |
| Total | | 31/40 | Good |

## Design Specificity
Authored for this product (recessed answer face, fixed CTA slot, session context line, Kept/Lost tiles, workload glyph line, local-first voice). Generic residue: all-caps section-label used as every kind of label.
Detector: `impeccable detect` returned [] for lib/features, lib/shared/widgets, lib/app, but it does not scan .dart (control test: .css caught, .dart with Color(0xFF…) returned []). Fallback greps: 0 hardcoded colour/spacing/fontSize/raw Material/direct showDialog in features; architecture guard clean. Browser overlay skipped (Flutter canvas).

## Priority Issues
1. [P1] 27 Sync rejected: "Try again" (banner) and "Sync now" both solid indigo, both start a sync, plus "Keep on this device" = 3 overlapping actions; row "Waiting to sync: Nothing waiting" contradicts banner "2 changes are kept only on this device"; "Keep" is one-way (deletes rejection record, R7) with spec §5.4 body dropped, no confirm/Undo. Fix: single primary (Try again), Sync now outline/hidden while rejected; restore body + consequence "won't sync to other devices"; 8s Undo; Waiting row reflects rejected count. Cmd: clarify, layout. (sync_rejected_light.png; sync_notice_widget.dart)
2. [P1] 14 Study entry resume: two indigo blocks; the thumb-zone footer "Start a new review instead" ends the open session. Fix: footer yields (outline/secondary) while a resume banner shows, or Continue moves to the footer. Cmd: layout. (study_entry_resume_light.png)
3. [P1] 07 Card list search: hero + filters stay above results (source hides them only when isSelecting); first matches sit under the keyboard. Fix: hide summary (and filters) while search is open. Cmd: adapt. (card_list_search_light.png; card_list_section_widget.dart)
4. [P1] 11 Import mapping: rows show only "Column A" + header if any; pasted/headerless input maps blind. Fix: first data cell under each column. Cmd: harden. (import_mapping_light.png; import_mapping_row_widget.dart)
5. [P1] 24 Reminder preview hard-codes "86 cards are due in Tiếng Hàn TOPIK I · Từ vựng, and 2 other decks" (reminder_preview_section_widget.dart:12-13) while the detail file says "live counts"; largest text on the page, unlabeled. Fix: real counts with neutral fallback, or "Example" label + body-large. Cmd: clarify.
System P2: "state a number once" violated on 01, 06, 07, 11, 13, 14, 21, 22, 28. Cmd: distill.

## Per-screen findings (Minor unless noted)
01 Deck list — Balanced. Unset-deck empty state: primary + FAB + secondary + outline (2 indigo, duplicate sub-deck path) → hide FAB. Due figure x3 in open deck + "1 sched…" truncation. Sort sheet "Newest / Newest first". Golden library_decks lacks due-strip chevron (fixture doesn't wire onOpenStudyHome); stale Pending row in 01. Reorder keeps tappable search (unverified).
02 Algorithm — Balanced (text-heavy). Locked: current algorithm at 0.38 opacity, strip doesn't name it → read-only-selected style or "Locked · SM-2 · cycle 1". Irreversible reset confirmed with plain indigo (Trash purge uses destructive). Unlocked strip hero+indigo but inert.
03 Starter — Balanced. Facts line repeats title/note, wraps mid-word. Algorithm sheet lacks lock consequence. Second copy = 4 taps. Load-failed cloud-off glyph.
04 Search — Balanced. Stacked overlines, "RESULTS FOR “HỌC”" uppercases user query. Golden search_load_more_failed shows idle button, not the failure banner.
05 Tags — list Balanced, merge dialog Too Dense (counter + 6-line panel + chips, irreversible). Green success card in destructive delete dialog. Dead search + "NO TAGS A→Z" in true empty. Sheet header differs from other sheets.
06 Trash — Balanced. Purge-blocked/kind-lock banners appended after list, detached from row. Numbers repeated in header/selection; two time forms per row. No-target restore states rule twice, OK only.
07 Card list — Balanced, chrome ~50% above fold. [Major] search (above). Numbers x3–4 (breakdown/button/chip/badge; donut % + fraction; row dot+label+badge; selection x3). Counts re-scope silently under tag filter/search ("All 3 / Showing 3 of 3" vs 4). Bulk-failure banner generic, no Retry.
08 Card create — Balanced. Sparkle glyph implies AI. Tag input commits only via IME Done.
09 Card edit — Balanced. Optional fields always open (create hides them). Save live when pristine. Three overline levels ("OPTIONAL DETAILS", field labels, "MORE").
10 Card detail — Balanced. History badge colour=outcome but label=kind; 4 icons per event. Half-width Algorithm tile wraps 3 lines. Section vs cycle header same style. Fixture inconsistent (cycle 1 vs CYCLE 2; Answers/Lapses tiles uncovered).
11 Import — Preview Too Dense (~45% chrome); Source/Mapping Balanced. [Major] mapping (above). Ready count x4; chip 6 rows vs preview 5. Include-duplicates toggle after rows. Row X glyph looks like dismiss; mastery green for ready/done. Source card-in-card, format line twice.
12 Export — Balanced. Stale state keeps formats live, lone Close is primary, copy asks for an action not offered.
13 Study home — Balanced. Workload hero inert (DESIGN: hero leads somewhere). Sync notice "Details" solid indigo. Eyebrow placement inconsistent, borrows requiredMarker.
14 Study entry — Balanced. [Major] resume (above). Disabled-option reason ~2.5:1. Numbers repeated; Learn offered twice. All-caps hero title wraps with orphan; limit editable only via unlabeled sliders icon. Direction sheet note buries the lock constraint; deck name x2.
15 Study options — Balanced. Save failure only muted caption. Read-only defaults dead end. "Created" has 4 names.
21 Session summary — Too Empty (stats states, ~40% blank). Hero top-anchored over void. "20 cards"/"20 REVIEWED"/"20 ANSWERED". "3 of 23 WRONG TURNS" undecodable (R3 hides explanation). "41 of / 241" wraps; label misaligned. Copy points to action footer lacks (interrupted). App bar title off gutter.
16 Browse — Balanced. Footer hint wraps, glyph detached, CTA shifts ~17dp vs other modes.
16a Self-check — Balanced. Reveal swaps button for grades in place, no settle guard (double-tap commits Hard/Good). Grade buttons rounded-rect vs pill elsewhere.
17 Match — Balanced. Meaning-first tap is a silent no-op; columns differ only by weight.
18 Guess — Balanced. Wrong answer held 1200ms, tap anywhere advances (Fill/Recall wait). Context line "FIRST PICK COUNTS" wraps, duplicates footer. Blocked state top-heavy, three × glyphs.
19 Recall / 20 Fill — Balanced. Outcome tags lose warning colour in light. Mastery-green mode accent without a recorded ruling. Fill hint 12px and shifts typed text ~14dp.
22 Progress — Balanced. Drill-down unsignalled; total row looks tappable. card-days vs cards unlabeled. Never-studied lone CTA is grey secondary. Streak card nested tile + 2 overlines. Rule stated twice; legend vs faded bars; skeleton mismatch; deck name x2.
23 Settings — Balanced. Reset row has chevron but opens dialog. Sync row failure in same grey as "Off". Copy "Apply to…" ungrammatical; detail file drift.
25 Theme — Balanced. Filled note vs hint form on siblings.
26 Language — Balanced. No findings.
24 Reminder — Balanced. [Major] preview (above). Time hint dimmed with row when off. Perm-denied body vs "Try again" ambiguity. Read-error cloud-off glyph; minute "0" not "00".
27 Sync — Balanced. [Major] x2 (above). Status value in small subtitle line. Syncing = empty box + faint spinner, no label.
28 Monitoring — Balanced. "Open" x5. "Not sent (27)" but 3 rows, no count. "Level · 2" opaque. Stack trace no hanging indent.

## Persona Red Flags
Casey: card search under keyboard; footer "Start a new review instead" on return; Guess wrong 1.2s; self-check double-tap grades. Sam: disabled reason ~2.5:1; light outcome tags lose amber; dimmed reminder hint; outline Cancel/Try again faint on dark sheets and warning grounds (02, 05, 24, 27). Exam crammer: "3 of 23 wrong turns"; card-days vs cards; "All" re-scoped by tag filter.

## Minor Observations
Doc drift: 07 legend/sort chip, 08 app-bar Save, 16/16a Self-check vs Self-assess and missing "ruled below", 23 reminder row/reset copy, 24 live counts, 27 §5.4 body, 01 Pending row. Fixture gaps: 01 chevron, 04 load-more failed, 10 cycle, 22 scrolled month/quiet. ARB mixes ' and ’. Skeletons (Progress, Settings) do not mirror loaded layout.

## Cross-screen / shared-component fixes
MxInlineBanner/MxFloatingNotice action tone yields when page has a primary (13, 27, 24). MxFooterBar/MxSheetActions yield tone + secondary dismiss-only (14, 12, 11). MxOptionRow/MxSettingsRow read-only-selected state; hint legible when disabled; action variant without chevron (02, 14, 24, 23). MxErrorState icon required/neutral default (03, 06, 24). Outline button contrast on dark surface-container-high and warning ground (02, 05, 24, 27). Split section-label into field-label/eyebrow/section; stop borrowing requiredMarker; never uppercase user data. MxListRow count+chevron slot, summary row. MxStatTile inline centring/no-wrap. MxBadge/tracker success tone + one glyph per state. StudyCtaRow settle lockout + pill grades. SessionFooterHint neutral glyph + wrap alignment. MxBottomSheet header standard. DESIGN.md rules: hero only when tappable; outcome hold (only correct auto-advances); neutral reassurance tone; dialog content budget; "state once" checklist.

## Questions to Consider
- If banners and the footer yield tone automatically, how many One Indigo breaks disappear?
- Should "state a number once" be a golden-review checklist item rather than per-screen fixes?
- Should Session summary be a weighted "done" moment (centred hero, one key number) or a stats table?

## Resolution (part 1, branch ccr-9f407421-jaecla)

Fixed by spec `docs/superpowers/specs/2026-09-30-critique-fixes-part1-design.md` and plan `docs/superpowers/plans/2026-09-30-critique-fixes-part1.md`:

- Priority 1 (27 Sync refused rows): fixed — a5f0fe1.
- Priority 2 (14 Study entry resume): fixed — d21ff54, 0b95a97+ (Try again too).
- Priority 3 (07 Card search): fixed — c37e7b8.
- Priority 4 (11 Import mapping): fixed — 2fd4577.
- Priority 5 (24 Reminder preview): fixed — 7b464a1, 8875de1 (use case).
- Shared: outline edge dark a16a521; MxOptionRow 5488a84; MxSettingsRow cad77a6; MxErrorState c270249; one-primary helper f0362f1; 12 formats and 01 unset FAB e011f3a.
- Open: part 2 (section-label typography) and the per-screen Minors.
