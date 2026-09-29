# SP2 + SP3: fix the 2026-09-30 UI critique — design

Status: draft 2026-09-30, awaiting owner review ·
Path: architectural (sub-projects 2–4 of 4, one plan) · Owner rulings 2026-09-30 (§3): R1–R6

## 1. Intent

The 2026-09-30 Impeccable critique of all 28 screens scored the app 28/40. SP1
(`2026-09-30-retire-ui-kit-design.md`, PR #159) retired the kit so these fixes change the
app and its record (`DESIGN.md`, the screen detail files) with no deviation bookkeeping.
The owner asked to fix every finding in one pass, shared design system first, then the
screens.

Success means:

- every finding in §4 is fixed as designed, or dropped with the reason in §5;
- behaviour changes are pinned by widget tests written first;
- the golden suite is regenerated in the Linux container and every changed golden is shown
  to the owner on a golden review page before merge;
- `DESIGN.md`, the affected detail files and `docs/wbs_FE.md` describe the result;
- `bash .claude/skills/flutter-workflow/scripts/dod_check.sh` passes.

## 2. Verified findings

The critique findings were checked against the code before this spec (two read-only
surveys, 2026-09-30). Seven did not hold and are dropped (§5). The rest are in §4.

## 3. Owner rulings (2026-09-30)

- **R1.** Fix all findings in one pass: shared components first, then screens.
- **R2.** Screen 07: drop the stacked status bar and its legend from the deck summary
  card; keep the ring, "{n} of {total} cards mastered", the due line and the CTA.
- **R3.** Screen 21: keep the hero stats; the "This session" fact list shows only for
  outcomes that draw no hero stats (reset, content deleted, save error); the wrong stat
  is labelled "Wrong turns".
- **R4.** Screen 01: the due strip becomes tappable and opens the Study tab.
- **R5.** The branch stacks on SP1 (`claude/ui-critique-fixes` from
  `claude/ui-ux-screen-critique-c2b328`).
- **R6.** No new shared widget; changes go into the existing widgets and one new opacity
  token (§4.1 S4).

## 4. Design

Each item names the code that changes and the goldens it moves. File paths are under
`lib/` unless they start with `test/`.

### 4.1 SP2 — shared

- **S1 · Wrap, never cut, at large text.**
  - `features/study/presentation/widgets/support/session_context_line_widget.dart`:
    `maxLines: 2` → no line limit.
  - `features/study/presentation/widgets/support/session_footer_hint_widget.dart`:
    `maxLines: 2` → no line limit.
  - `features/deck/presentation/widgets/items/deck_row_widget.dart`: the meta `Text`
    drops `maxLines: 1`/ellipsis (the title keeps its one line).
  - `features/deck/presentation/widgets/support/deck_workload_line_widget.dart`: pass
    `canWrap: true` to `MxWorkloadBreakdownLine` (due strip, reorder rows).
  - The search field hint is a placeholder and keeps its ellipsis.
  - Goldens: every `study_*` session golden, `library_decks*`, `library_reorder`,
    `app_library*`.
- **S2 · The session context line stops repeating the mode.**
  `features/study/presentation/states/session_context_state.dart` drops the mode name
  (the top bar's pill already shows it) and Match's "{n} pairs left" (the board shows the
  matched tiles; the pill counter is the round progress). Line: deck · kind · [stage] ·
  round n · [first pick counts].
- **S3 · The card list clears its FAB.**
  `features/card/presentation/widgets/sections/card_list_section_widget.dart` passes
  `clearance: MxScrollClearance.fabAboveNav` to its three `MxScreenScroll`s while the FAB
  shows (not while selecting). Goldens: `card_list*`, `card_tag_filter_*`,
  `app_tablet_portrait_deck`.
- **S4 · One muted opacity.** `core/theme/foundations/app_opacity.dart` gains
  `AppOpacity.muted = 0.7`, for content that stays readable but steps back. It replaces
  `MxFooterBar._captionOpacity` (0.7) and Guess's faded distractors
  (`study_choice_widget.dart`, today `AppOpacity.disabled`). `AppOpacity.disabled` stays
  0.38 for controls that cannot be used.
- **S5 · Forms state the deck once and save once.**
  - `features/deck/presentation/widgets/sections/deck_context_header_widget.dart` drops
    the destination row (tile + deck name) under the breadcrumb; the breadcrumb already
    ends with the deck. Affects the card editor, detail and import.
  - `features/card/presentation/widgets/sections/card_editor_form_widget.dart` drops the
    app-bar Save (`cardSave`); the footer's block Save stays the only save. The edit
    screen's flag action stays in the app bar.
  - The editor drops `CardRequiredLegendWidget` (the "REQUIRED" overline); each required
    field keeps its "Required" marker and the footer keeps its caption. The widget file
    and its unused l10n use go.
  - Goldens: `card_editor_*`, `card_detail_*`, `import_*`.
- **S6 · A single study action spans the row.**
  `features/study/presentation/widgets/support/study_cta_row_widget.dart`: one action
  gets the width of a two-action row (`2 × 160 + control`), full width when narrower,
  instead of hugging its label. Callers pass `isBlock: true` for single actions
  (Fill's Continue, Recall's Continue and Show the meaning, Self-assess's Show answer).
  Goldens: `study_fill_*`, `study_recall_*`, `study_self_assess_*`.

### 4.2 SP3a — Library and cards

- **01 · Due strip opens Study (R4).** `deck_due_strip_widget.dart` takes an `onOpen`
  callback and renders as a tappable `MxCard` with a trailing chevron and a button
  semantics label; the Library root wires it to `AppRoutes.study` through the callback
  `app/` injects (no router import in the feature). The "display only" comment goes.
- **01 · Row meta wraps** (S1).
- **02 · Shorter algorithm choices, warning first.**
  - `algorithmEightBoxDescription` → "Remembered → one box up; forgotten → back to box 1.
    Forgiving of long breaks. Review modes: match, guess, recall, fill."
  - `algorithmSm2Description` → "Intervals adapt to how well you recall each card. You
    grade yourself: again, hard, good or easy. Review mode: self-assess."
  - `algorithmSwitchNote`: "re-initialises" → "resets".
  - `deck_algorithm_screen.dart` places the `MxNote` above the options card.
  - vi strings updated to match. Goldens: `library_algorithm_*`.
- **03 · "Add another copy" is secondary.** `starter_template_card_widget.dart` passes
  `tone: MxButtonTone.secondary` when `entry.isInLibrary`. Goldens: `starter_*` with an
  in-library template.
- **07 · Summary card (R2).** `card_deck_summary_widget.dart` drops `_StatusBar` and the
  legend `Wrap`; `cardStatusCount` stays only if another caller uses it. FAB clearance
  (S3). Goldens: `card_list*`.
- **10 · Schedule facts without answers.** `card_schedule_widget.dart` omits Last
  answered, Answers and Lapses while `answerCount == 0`. No golden shows that state; a
  widget test pins it.
- **11 · Mapping column aligns.** `import_mapping_row_widget.dart`: the arrow and the
  field chip sit in an `Expanded` half, start-aligned, so every row's arrow starts at the
  same x. Golden: `import_mapping`.

### 4.3 SP3b — Study, progress and settings

- **13 · Deck rows end alike.** `study_home_decks_widget.dart`: `hasChevron:
  deck.canStudy` whether or not a due badge shows. Goldens: `study_home_*`.
- **14 · Plain caption.** `studyEntryOverline` → "{algorithm} · up to {limit} cards per
  session" (vi "{algorithm} · tối đa {limit} thẻ mỗi phiên"). Goldens: `study_entry_*`.
- **16 · Browse has a visible Next.** `study_browse_widget.dart` adds a
  `StudyCtaRowWidget` with one "Next card" (`studyBrowseNext`) action above the footer
  hint; swipe and the semantics actions stay. Goldens: `study_browse*`.
- **17, 18 · Context line and wrapping** (S1, S2).
- **19 · Honest grades.** `study_recall_widget.dart`: Forgot and Remembered are both
  `MxButtonTone.secondary`. Goldens: `study_recall_revealed`, `_large_text`.
- **20 · Continue spans the row** (S6).
- **21 · Summary (R3).** `session_summary_widget.dart` draws the facts only when
  `!outcome.drawsStats || !summary.hasAnswers`; `summaryStatWrong` → "Wrong turns"
  (vi "Lượt sai"). Goldens: `summary_review`, `_learning`, `_large`, `_left_early`,
  `_interrupted`.
- **22 · Progress.**
  - `progress_streak_widget.dart` drops the "Today" tile; the Current tile stays alone.
  - `progress_screen.dart` passes `icon: AppIcons.alert` to its `MxErrorState` (a local
    read failure is not a network fault).
  - `progress_screen.dart` omits the by-deck list while the streak state is `never`
    (nothing was ever studied, so every row would read 0).
  - Goldens: `progress_*`.
- **15 · One note, read-only values.** `study_options_form_widget.dart`:
  - the scope note and the "changes apply to sessions started from now on" note merge
    into one `MxNote`;
  - while following the app defaults, the two rows show their values as plain trailing
    text at full contrast instead of disabled stepper and tray (no double dimming).
  - Goldens: `study_options_*`.
- **27 · Sync now steps back when nothing waits.** `sync_screen.dart`: `tone:
  MxButtonTone.outline` when nothing is waiting and there is no failure or refusal;
  primary otherwise. Goldens: `sync_synced`, `sync_never_synced`.

### 4.4 Records

- `DESIGN.md`: `AppOpacity.muted`; the study action rule (one action spans the row);
  forms state the deck once and save once; the due strip is a tappable hero card.
- Detail files 01, 02, 03, 07, 08, 09, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22,
  27: Layout, States and Copy follow the change; each change is stated as the app's
  behaviour (no "deviation").
- `docs/wbs_FE.md`: one FE row for this work.

### 4.5 Testing and verification

- Widget tests first for each behaviour change: due strip tap and semantics; card
  editor has one Save; editor has no REQUIRED legend; schedule facts hidden at zero
  answers; study CTA single action width; Browse Next advances; summary facts hidden with
  stats; progress by-deck hidden when never studied; sync button tone; study options
  read-only values; context line without mode.
- `flutter analyze`, `flutter test --exclude-tags golden` on Windows.
- Goldens regenerated only in `memox-golden:3.47.5` (validate on `origin/master` first,
  per `golden.Dockerfile`), then `flutter test --tags golden` green in the container.
- The owner reviews every changed golden on a `golden-compare` page before merge.
- `dod_check.sh` passes.

## 5. Dropped findings

| Finding | Why it is dropped |
|---|---|
| 23 stepper needs ~30 taps | `MxStepper` already repeats on hold and takes a typed number (FE-A3 D6) |
| 04 accents rule only under results | The no-results state states it (`searchNoMatchesBody`) |
| 12 export title vs filters | The title counts the whole deck, as the body says |
| 06 Restore/Delete filled pair | Owner ruling 2026-09-26; a confirm dialog guards purge |
| 24 time chip affordance | It is a tonal `MxButton` with a pressed state |
| 24 preview loudest text | It uses the ordinary settings label style |
| 19 two progress bars | D14 made the clock neutral; it is the turn signal |
| 07 row status label line, 13 four-term hero, 05, 06 banner | Rules (BR-STUDY-068) or rulings already decide them; no clear problem |

## 6. Out of scope

- Any new shared widget, dismissible notes, or the Trash banner.
- Search field hint wording.
- Screens 25, 26 (no finding).
