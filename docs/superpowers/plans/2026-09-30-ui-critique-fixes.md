# SP2 + SP3: fix the 2026-09-30 UI critique — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix every verified finding of the 2026-09-30 critique — shared components first, then screens — and record the result in `DESIGN.md`, the screen detail files and the goldens.

**Architecture:** Changes stay inside existing widgets (no new shared widget); one new token `AppOpacity.muted`. Each behaviour change is pinned by a widget test written first; visual changes are proven by goldens regenerated in the Linux container and reviewed by the owner.

**Tech Stack:** Flutter 3.47.5, Riverpod, go_router, `flutter_test`, goldens in `memox-golden:3.47.5` (Docker), ARB l10n (en, vi).

**Spec:** `docs/superpowers/specs/2026-09-30-ui-critique-fixes-design.md`

## Global Constraints

- No new shared widget; the only new token is `AppOpacity.muted = 0.7` (spec R6, S4).
- No raw colours, raw padding numbers or untranslated strings in feature code (guard `memox-v8`); every new string in `app_en.arb` and `app_vi.arb`.
- Feature code never imports the router; navigation is a callback injected by `app/`.
- Goldens are written only in `memox-golden:3.47.5`; on Windows run `flutter test --exclude-tags golden`, never `--update-goldens`.
- After ARB edits run `flutter gen-l10n`; after provider/Drift changes `dart run build_runner build --delete-conflicting-outputs`.
- Commits: conventional, English, `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- Read each file before editing it; match its idiom (named constants, `AppSpacing`, `AppIcons`, `context.l10n`).

## Review Focus

- Large text (scale 2) on every screen touched by S1: text wraps, nothing overflows (RenderFlex) — the existing `*_large_text` / `*_2x` goldens and `textScale: 2` widget tests must stay green.
- The due strip with 0 due cards: it is hidden today when the library holds no card; tapping must never fire when hidden (Task 7 test).
- Card list while selecting: no FAB, so no extra clearance (Task 4 test).
- Summary outcomes without answers (`hasAnswers == false`): facts and stats rules must not leave an empty page (Task 9 test).
- Study options switching from defaults to override and back: the stepper and tray return, values keep (Task 11 test).

---

### Task 1: `AppOpacity.muted`

**Files:** Modify `lib/core/theme/foundations/app_opacity.dart`, `lib/shared/widgets/mx_footer_bar.dart` (`_captionOpacity`), `lib/features/study/presentation/widgets/items/study_choice_widget.dart` (faded opacity). Test: `test/features/study/presentation/study_guess_test.dart` (or the existing choice test).

- [ ] Step 1: test — after an answer, a distractor's `AnimatedOpacity.opacity == AppOpacity.muted`.
- [ ] Step 2: run → FAIL (0.38).
- [ ] Step 3: add `static const double muted = 0.7;` with a doc line ("readable content that steps back; `disabled` is for controls that cannot be used"); use it in `study_choice_widget.dart` and replace `MxFooterBar._captionOpacity`.
- [ ] Step 4: run the study and footer-bar tests → PASS.
- [ ] Step 5: commit `feat(theme): AppOpacity.muted for readable content that steps back`.

### Task 2: Session context line and footer hint (S1, S2)

**Files:** `lib/features/study/presentation/states/session_context_state.dart`, `widgets/support/session_context_line_widget.dart`, `widgets/support/session_footer_hint_widget.dart`. Tests: `test/features/study/presentation/` context-state test (find with `grep -rl sessionContext test/`).

- [ ] Step 1: tests — the context text for a Guess round omits the mode label and contains "round 1" and "first pick counts"; for Match it contains no pairs-left text; `SessionContextLineWidget` and `SessionFooterHintWidget` `Text.maxLines == null`.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: drop the mode segment and the Match `studyContextPairsLeft` suffix in the state; remove `maxLines`/`overflow` from both widgets. Remove `studyContextPairsLeft` from both ARBs if no other use.
- [ ] Step 4: `flutter gen-l10n`; run study tests → PASS (update existing expectations that asserted the old text).
- [ ] Step 5: commit `fix(study): context line drops the mode, hints wrap at large text`.

### Task 3: Deck meta and breakdown wrap (S1)

**Files:** `lib/features/deck/presentation/widgets/items/deck_row_widget.dart`, `widgets/support/deck_workload_line_widget.dart`. Test: `test/features/deck/presentation/deck_row_widget_test.dart`.

- [ ] Step 1: test at `textScale: 2` — the meta `Text` has `maxLines == null` and the full meta string is laid out (no ellipsis); `DeckWorkloadLineWidget` builds `MxWorkloadBreakdownLine(canWrap: true)`.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: drop `maxLines: 1`/`overflow` from the meta; pass `canWrap: true`.
- [ ] Step 4: deck tests → PASS.
- [ ] Step 5: commit `fix(deck): row meta and due breakdown wrap at large text`.

### Task 4: Card list — FAB clearance and summary card (S3, 07/R2)

**Files:** `lib/features/card/presentation/widgets/sections/card_list_section_widget.dart`, `widgets/sections/card_deck_summary_widget.dart`. Tests: `card_list_section_test.dart`, `card_deck_summary_test.dart`.

- [ ] Step 1: tests — list `MxScreenScroll.clearance == MxScrollClearance.fabAboveNav` when not selecting and `base` while selecting; the summary card has no status bar and no legend (`find.text('Mastered 1')`-style legend entries absent), ring and "of … cards mastered" present.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: pass the clearance at the three `MxScreenScroll`s; delete `_StatusBar` and the legend `Wrap`; drop now-unused imports/keys (`cardStatusCount` only if unused elsewhere — grep).
- [ ] Step 4: card tests → PASS.
- [ ] Step 5: commit `fix(card): list clears the FAB, summary card states mastery once`.

### Task 5: Forms state the deck once and save once (S5)

**Files:** `lib/features/deck/presentation/widgets/sections/deck_context_header_widget.dart`, `lib/features/card/presentation/widgets/sections/card_editor_form_widget.dart`, delete `widgets/sections/card_required_legend_widget.dart` (or its location). Tests: `card_editor_screen_test.dart`, deck context header test (grep).

- [ ] Step 1: tests — the editor shows exactly one widget labelled Save-ish: `find.text(l10n.cardSave)` finds nothing, the footer save exists; no `MxDotOverline` with "REQUIRED"; `DeckContextHeaderWidget` renders `MxBreadcrumb` and no `MxIconTile`.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: remove the app-bar Save action (keep the edit flag), the legend widget and its use, and the destination row.
- [ ] Step 4: card + transfer + deck tests → PASS.
- [ ] Step 5: commit `fix(card): one save and one deck statement on the card forms`.

### Task 6: Study actions (S6, 16, 19)

**Files:** `lib/features/study/presentation/widgets/support/study_cta_row_widget.dart`, `sections/study_fill_widget.dart`, `study_recall_widget.dart`, `study_self_assess_widget.dart`, `study_browse_widget.dart`. Tests: `study_support_widgets_test.dart`, `study_recall_test.dart`, `study_browse_test.dart`.

- [ ] Step 1: tests — a single action in `StudyCtaRowWidget` is laid out at `min(available, 2 × 160 + AppSpacing.control)` wide; Recall revealed: Forgot and Remembered both `MxButtonTone.secondary`; Browse shows a "Next card" button whose tap advances like a left swipe.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: single child → `ConstrainedBox(maxWidth: 2 * _actionWidth + AppSpacing.control)` + `SizedBox(width: double.infinity)`; callers pass `isBlock: true`; recall tones; Browse adds `StudyCtaRowWidget([MxButton(label: studyBrowseNext, size: study, isBlock: true, onPressed: _forward)])` above the hint.
- [ ] Step 4: study tests → PASS.
- [ ] Step 5: commit `fix(study): one action spans the row, even grades, visible Next in Browse`.

### Task 7: Due strip opens Study (01/R4)

**Files:** `lib/features/deck/presentation/widgets/sections/deck_due_strip_widget.dart`, its callers (`deck_level_list_widget.dart`, the root widget, `deck_level_screen.dart`), `lib/app/router/app_router.dart` (inject `onOpenStudy: () => context.go(AppRoutes.study)`). Test: deck level test.

- [ ] Step 1: test — tapping the due strip calls the injected callback once; it has button semantics and a chevron; with no cards the strip is absent.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: wrap in the card's tap ink (as other tappable `MxCard`s do — grep `MxCard(` with `onTap`), trailing `AppIcons.chevronRight`, `Semantics(button: true)`; thread `onOpenStudy` from the screen; wire in `app_router.dart`; drop the "display only" comment.
- [ ] Step 4: deck + app tests → PASS.
- [ ] Step 5: commit `feat(deck): the due strip opens Study`.

### Task 8: Copy (02, 14, 21 label)

**Files:** `lib/l10n/app_en.arb`, `app_vi.arb`, `lib/features/deck/presentation/screens/deck_algorithm_screen.dart` (note above the options). Test: `deck_algorithm_screen_test.dart`.

- [ ] Step 1: test — on the algorithm screen the note appears above the options card (its dy < the options card's dy).
- [ ] Step 2: run → FAIL.
- [ ] Step 3: move the `MxNote`; ARB en/vi: `algorithmEightBoxDescription`, `algorithmSm2Description`, `algorithmSwitchNote` ("resets"), `studyEntryOverline` ("{algorithm} · up to {limit} cards per session" / "{algorithm} · tối đa {limit} thẻ mỗi phiên"), `summaryStatWrong` ("Wrong turns" / "Lượt sai"), exact en text from the spec §4.2–4.3.
- [ ] Step 4: `flutter gen-l10n`; deck + study tests → PASS.
- [ ] Step 5: commit `fix(copy): shorter algorithm choices, plain study caption, wrong turns`.

### Task 9: Session summary facts (21/R3)

**Files:** `lib/features/study/presentation/widgets/sections/session_summary_widget.dart`. Test: `session_summary_test.dart`.

- [ ] Step 1: tests — reviewFinished with answers: no "This session" header; reset outcome: facts shown; reviewFinished with `turnCount == 0`: facts shown (stats are not drawn then).
- [ ] Step 2: run → FAIL.
- [ ] Step 3: draw facts when `outcome.drawsFacts && (!outcome.drawsStats || !summary.hasAnswers)`.
- [ ] Step 4: study tests → PASS.
- [ ] Step 5: commit `fix(study): the summary states its numbers once`.

### Task 10: Small screen fixes (03, 10, 11, 13, 27)

**Files:** `starter_template_card_widget.dart`, `card_schedule_widget.dart`, `import_mapping_row_widget.dart`, `study_home_decks_widget.dart`, `sync_screen.dart`. Tests: each feature's existing screen/widget test.

- [ ] Step 1: tests — in-library template's add button tone `secondary`; schedule with `answerCount == 0` shows no Last answered/Answers/Lapses facts; two mapping rows' arrows share the same x; a study-home row with due > 0 has a chevron; Sync now `outline` when nothing waits and no failure, `primary` otherwise.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: implement each as spec §4.2–4.3.
- [ ] Step 4: those tests → PASS.
- [ ] Step 5: commit `fix(ui): starter, schedule, mapping, study home and sync refinements`.

### Task 11: Progress and study options (22, 15)

**Files:** `progress_streak_widget.dart`, `progress_screen.dart`, `study_options_form_widget.dart` (+ ARB if the merged note needs a new key). Tests: `progress_screen_test.dart`, study options test.

- [ ] Step 1: tests — streak card has no "Today" tile; error state icon is `AppIcons.alert`; never-studied state has no "All decks" row; study options on defaults shows one note and the two values as plain text (no `MxStepper`/`MxSegmentedTray`), and switching to override brings them back with the same values.
- [ ] Step 2: run → FAIL.
- [ ] Step 3: implement per spec §4.3.
- [ ] Step 4: progress + settings tests → PASS.
- [ ] Step 5: commit `fix(progress, settings): one today figure, local error icon, read-only defaults`.

### Task 12: Goldens

- [ ] Step 1: validate the container on `origin/master` (per `golden.Dockerfile`, "All tests passed!").
- [ ] Step 2: regenerate on this branch: `docker run --rm -v "$PWD":/w memox-golden:3.47.5 bash -lc 'flutter pub get && dart run build_runner build --delete-conflicting-outputs && TZ=UTC flutter test --tags golden --update-goldens'`, then run once more without `--update-goldens` → All tests passed.
- [ ] Step 3: check every changed PNG is explained by a task (`git diff --stat -- '*.png'`); an unexplained change is a bug to fix, not to accept.
- [ ] Step 4: commit `test(goldens): regenerate for the critique fixes`.
- [ ] Step 5: build the owner's golden review page with the `golden-compare` skill (Before · After · Diff, one sentence each).

### Task 13: Records

**Files:** `DESIGN.md`, `docs/shared/ui/screen-handoff/{01,02,03,07,08,09,10,11,13,14,15,16,17,18,19,20,21,22,27}-*.md`, `docs/wbs_FE.md`.

- [ ] Step 1: `DESIGN.md` — `AppOpacity.muted`, single study action spans the row, forms state the deck once and save once, due strip tappable hero; detail files — Layout/States/Copy follow each change, new goldens cited; wbs_FE — row FE-D6.
- [ ] Step 2: `python tools/docs/check.py` → PASS; every cited golden exists.
- [ ] Step 3: commit `docs(ui): record the critique fixes`.

### Task 14: Gate

- [ ] Step 1: `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` → all gates pass.
