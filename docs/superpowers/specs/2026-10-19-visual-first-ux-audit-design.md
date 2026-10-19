# Visual-first UX audit of every screen

Date: 2026-10-19 · Asked by the owner (task "Comprehensive Visual-First UX Audit & Redesign") · Status: **approved by the owner 2026-10-19** (§9). Phases A–D of the task; nothing in §5–§7 is built yet. Progress is recorded on DEV-323 (the Linear workspace is at its issue limit).

## 1. Goal

Find where MemoX presents information as text that a visual form would make
faster to read, and where a screen's composition makes the user work harder
than it needs to, then propose the changes that pay for themselves, grouped
by the shared widget that owns them. The design system stays: every proposal
uses the ForUI theme in `lib/core/theme/` and the `Mx*` widgets (ADR-026), and
a proposal that needs a token change is marked for the owner.

## 2. Method

- **Units.** The 42 screen detail files in `docs/shared/ui/screen-handoff/`
  (01–39 with 16a, 23a, 23b), each with its code under `lib/features/*/presentation/`
  and its goldens (656 PNGs, 1080 px = 360 dp).
- **Describe pass.** One Sonnet agent per screen (`review-verify` workflow):
  an inventory note (goal, actions, every state of the States table with its
  golden, the data shown and its weight), then defects in six dimensions:
  text density, hierarchy, visual representation, interaction, consistency,
  accessibility, each with a file:line and a value measured on a golden.
  Learning content (terms, meanings, TOPIK passages, questions, explanations)
  was out of bounds for text density.
- **Verify pass.** Every P0–P2 finding re-checked twice, independently, by
  Opus agents reading the code as it stands, with one of five verdicts:
  CONFIRMED, REVISED_TARGET (real, but the fix goes elsewhere), REFUTED,
  NO_LONGER_REPRODUCIBLE, BLOCKED (needs something this work may not touch).
  Disagreements are settled by rank in code, not by a third agent.
- **Cost.** 514 agents, 40.6 M subagent tokens, about 2 h 48 min.

## 3. Result in one table

| Verdict | Count | What it means |
|---|---|---|
| Inventory and P3 notes | 44 | Appendix A; not verified |
| CONFIRMED | 4 | real, and the obvious fix is right |
| REVISED_TARGET | 28 | real, but the owner of the fix is elsewhere (often a shared widget) |
| BLOCKED | 2 | real, but an owner ruling or a theme role stands in the way |
| REFUTED | 202 | not a defect against the current record |
| **P0** | **0** | no high-impact usability problem survived verification |

**What the refutations say.** 202 of 236 verified findings (86 %) were
refuted, and in almost every case for the same reason: the screen's detail
file, an active spec or an owner ruling already decided the thing the finding
called a defect (168 refutations cite a ruling, 159 a spec, 136 the owner).
Recurring decisions: "a number has one home" (critique part 3b §3), the Wrap
Rule (a meta line wraps between whole terms, only a title keeps one line), the
One Accent Rule, status told by text and badge rather than glyph on card rows
(R3), and plain captions for counts and countdowns. So the app is text-led on
purpose, and the record shows why.

The consequence for this task: **visual-first changes are few, and most of
the leverage is in shared widgets**, not in redrawing screens. Twenty-five
visual-representation ideas were refuted because a ruling chose text; §5.2
lists the ones worth putting back to the owner, who alone can reopen them.

## 4. A. Inventory

Every screen and state is in Appendix A, one entry per screen: the primary
goal, primary and secondary actions, each state with its golden or "no
golden", and the data shown, split into critical, supporting and repeated.
Appendix B is the register of every finding and its verdict.

Two inventory facts matter for the plan:
- Many states have no golden (screen 01 alone lists 30+ states, 8 with
  goldens). A change to a shared widget must be checked on those states by a
  widget test or a throwaway golden, as CLAUDE.md asks of an audit.
- The idle choice tile (§6.1) appears in four screens (17, 18, 37, 39) and is
  the single most repeated defect.

## 5. B. Visual transformation opportunities

### 5.1 Verified: worth doing

| Screen | Text or layout today | Proposed visual | Level (task §6) | Verdict |
|---|---|---|---|---|
| 22 Progress | seven-day bars with no scale | dashed guide with the fullest day's count, tap tooltip with the day's numbers | 3 | **done**, pull request 314 (merged) |
| 36 TOPIK detail | best and average score as two figures | score across attempts as a line chart | 3 | owner decided 2026-10-19; Tier 2, its own spec |
| 38 TOPIK summary | time per question bars with no reference | the same bars on the shared chart, a guide at the longest question, keeping the 48 dp cell per bar and the status glyph | 3 | owner decided 2026-10-19 |
| 01, 07, 38 | two copies of one donut painter | one shared donut | 2 | owner decided 2026-10-19 |
| 39 TOPIK review | right and wrong option told by hue alone | a check or a cross beside the circled digit, as Guess (18) does | 3 | REVISED_TARGET (the glyph goes in the option builder, not in `MxChoiceTile`) |
| 09 Card edit | status, answers, lapses and due as one dotted sentence | `MxStatusBadge` for the status as on screen 10, the rest a compact line | 3 | REVISED_TARGET |
| 20 Study fill | the typed and the right term as two stacked words | the typed line with only the differing characters in `error`, struck through | 3 | REVISED_TARGET |
| 22 Progress | streak as a card with an inner tinted tile and an eyebrow | the streak value in `figure`, as Today's | 2 | REVISED_TARGET |
| 05 Tags | merge chips wrap so the arrow and the target part | arrow and target chip kept together | 2 | REVISED_TARGET |

### 5.2 Refuted by a ruling: the owner may reopen

Each was refuted only because an owner ruling or an active spec chose text.
None is recommended over the ruling; each is listed so the owner can decide
with the alternative in view.

| Screen | Idea | Ruling it conflicts with |
|---|---|---|
| 06 Trash | urgency of the 30-day deadline as a visual (a ring or a coloured time left) | owner ruling on the time-left line |
| 13 Study home | per-deck workload as compact counts | BR-STUDY-076 |
| 27 Sync | the sync state as an icon in every state | the settled-state rule in `sync_status_section_widget.dart` |
| 31 Code | the 60 s resend wait as a progress cue | the auth spec's plain caption |
| 35 TOPIK list | status and best score as an icon plus a figure | the TOPIK spec's row meta |
| 21 Summary | "W of T" wrong turns as a bar | critique 2026-09-30, R3 |
| 16a Self-assess | the four intervals on one shared scale | 16a's interval ruling |

## 6. C and D. Shared widgets and composition

### 6.1 Shared visual components

Each fix lands once and every screen that uses the widget inherits it
(CLAUDE.md, "Fix at the lowest shared owner"). Adding or promoting code into
`lib/shared/` needs the owner's approval; the first two only change existing
widgets.

**1. `MxChoiceTile`: an idle tile has a visible edge.** In light, the idle
tile is drawn with fill = edge = `card`, and `card` equals `background`
(#FFFFFF), so an idle option is bare text with no visible tap target. In dark
the card shows faintly, so the two themes differ.
- Fix: the idle edge becomes `border` at the hairline, the fill stays `card`
  (or `muted` when recessed). The edge then eases into the tone's edge as now.
- Screens: 17 Match (raised terms), 18 Guess, 37 TOPIK attempt, 39 TOPIK
  review, and every other `MxChoiceTile` caller.
- States to check: idle, selected, right, wrong, out of play, recessed, light
  and dark; the goldens of 17, 18, 37, 39 move.
- Accessibility: the hairline is a non-text cue only; the tile's semantics
  are unchanged.
- Not for: rows that are not choices (`MxListRow`, `MxSelectableCardRow`).

**2. `MxSlider`: the inactive track shows on any ground.** ForUI's default
inactive colour is `secondary`, which equals `muted`, the ground of the TOPIK
group pane, so the track after the thumb is invisible (1:1). The fix sets an
inactive track colour that stands out from `muted` (for example `border`) in
`MxSlider`'s style delta. It covers 37 and 39 and every slider on a recessed
ground. A theme-wide `sliderStyles` delta in `app_theme.dart` is the
alternative; the owner chooses the scope.

**3. A shared bar chart beside `MxStackedDayBars`.** Once the pilot in pull
request 314 merges, the TOPIK time chart moves onto fl_chart with the same
rules: one TalkBack summary node, a 48 dp cell per bar that still opens the
question, the status glyph and number under each bar, a guide, and no
animation under Remove animations. Whether it becomes `MxBarChart` or stays a
TOPIK widget on fl_chart is decided in its plan.

**4. One donut.** `MxMasteryDonut` and `TopikScoreDonutWidget` share one
painter in `lib/shared/widgets/`. The pictures stay the same, so no golden
should move.

**5. `MxScrollFade` with `MxChipRow`.** The edge fade of a chip row is
clipped away (07: the Tags chip is cut at the edge with no cue). The fix is
in the fade's bounds against the chip row's focus-ring clipper.

**6. `MxSkeletonList`: an opt-in divided mode** (34), so a skeleton matches a
divided section. P3; it needs the owner's approval to grow a shared widget.

### 6.2 Screen composition

| Screen | Today | Recommendation | Sev |
|---|---|---|---|
| 38 TOPIK summary | "By question type" (the weakest type, the next thing to study) comes after all 50 answer rows | move it right after the figures, before Answers | P1 |
| 18 Guess | the prompt card takes about 46 % of the height for one word | cap the prompt's share (a flex ratio or a theme-based max), with the room going to the options | P1 |
| 10 Card detail | Due and Learned dates wrap in half-width tiles ("Sep 26," / "2026") | date facts on full-width rows; the year stays | P1 |
| 02 Reset dialog | Kept and Lost side by side, 8 lines each at about 112 dp wide | stack the two tiles full width | P1 |
| 33 Users | emails cut at the domain | `titleMaxLines: 2` as Tags already does | P1 |
| 28 Monitoring detail | the error type repeated as the prefix of the error message | strip the leading type from the message | P1 |
| 27 Sync | the permanent note restates the offline notice | leave the note out while the offline notice shows | P2 |
| 07 Card list | the flag glyph moves the due badge | reserve the flag's slot | P2 |
| 23a Study defaults | in the invalid-limit state, − and + step from the wrong base | step from the stored limit, per the Transitions table | P2 |
| 20 Fill | the wrong state's footer takes the "comes back" icon | the info icon, matching its text | P2 |

Copy changes (owner's words, P2): drop the repeated lock sentence (02), drop
the second sentence of the SQL log hint so it takes three lines, not five, at 360 dp (23b), shorten
the first Welcome benefit (29), drop the "n · " step prefix the tracker
already carries (11).

Doc-only corrections (P2): 07 row status labels, 15 note copy, 23 height
budget, 23b loading-toggle row, and one scrolled golden pair for 13's
practice slot.

## 7. E. Plan

No P0. The groups below are ordered by impact and by the number of screens
one change reaches. Each is Tier 1 (a shared widget or one screen) unless
marked; each ends with its tests, the gate, `run_goldens.sh` and the
golden-compare page.

| Group | Content | Reach | Depends on | Risk |
|---|---|---|---|---|
| G1 | `MxChoiceTile` idle edge (§6.1.1) | 17, 18, 37, 39 and all callers | — | many goldens move; check every tone in both themes |
| G2 | `MxSlider` inactive track (§6.1.2) | 37, 39, any slider on `muted` | owner: widget or theme scope | slider goldens elsewhere |
| G3 | TOPIK: review glyphs (39), summary order (38) | 38, 39 | — | 38's Layout table and goldens |
| G4 | TOPIK charts: time chart on fl_chart, one donut | 01, 07, 38 | pull request 314 merged | the chart's 48 dp cells and TalkBack |
| G5 | Composition P1: 18 prompt cap, 10 dates, 02 reset tiles, 33 email, 28 message | five screens | — | low |
| G6 | P2 batch: §6.2 P2 rows, §5.1 P2 rows, chip-row fade (§6.1.5) | ten screens | — | low |
| G7 | Copy changes | 02, 11, 23b, 29 | owner approves the words | low |
| G8 | Score across attempts (36) | 36 | its own spec | Tier 2 |
| G9 | Reviewing fill out of `primary` (2.7:1 on the dark card) | 22 | owner decided; theme change via `docs/agent/visual-change.md` | theme-wide |

**Verification for every group:** a test that fails before and passes after,
the states and transitions the change reaches checked against the screen's
tables, check degrade on every consumer, check similar on the mechanism, the
gate, the goldens, and the golden-compare page before approval.

## 8. F. Visual evidence

The before/after page for the pilot is the golden-compare page of pull
request 314. The current goldens of every P1 finding are collected on the
audit's Artifact page as the "before". The "after" images come with each
group's golden-compare page, because a redesign is only shown once it is
built and tested.

## 9. Owner decisions (2026-10-19)

| # | Decision |
|---|---|
| O1 | The plan in §7 is approved: G1–G7 are to be built, in the order of §7. G8 (score across attempts) gets its own spec; G9 (the reviewing fill) is a theme change of its own. |
| O2 | G2 is fixed in `MxSlider`'s style delta only; the theme does not change. |
| O3 | §5.2 stays as decided: no ruling-bound idea is reopened. |
| O4 | Both BLOCKED findings keep their rulings: 21's wrong-turns figure stays the largest (R3), and a Match or Guess tile's meaning stays in `caption`. |
| O5 | This spec lands in its own pull request, after pull request 314 is merged (merged 2026-10-19). |

## Appendix A. Screen inventory

One entry per screen, as the describe pass wrote it from the detail file, the code and the goldens (not re-verified; the states and goldens it names are the detail file's).

### 01-deck-list

Primary goal: find a deck and start studying what is due, or navigate/organize the deck tree. Primary actions: due strip (opens Study home), tap a deck row (opens it), FAB New deck / New sub-deck, Study this deck (open deck). Secondary: search trigger, Starter decks/Tags/Trash app-bar icons, sort pill, per-row overflow, breadcrumb, deck overflow. States (golden / none): rootLoaded library_decks light+dark; rootLoading none; rootEmpty library_empty light+dark; rootError none; rootSearch none; rootSortFilter library_sort light+dark; rootDueEmpty none; rootOverflow library_deck_actions light+dark; rootCreate none; rootCreateSchedulerMissing none; rootCreateDiscard none; rootRename none; rootDelete library_deck_delete light+dark; rootTrashed library_deck_trashed light+dark; deckLoaded library_deck_open light+dark; deckEmpty library_deck_unset light+dark; deckEmptyTopLevel none; deckEmptyDeepest none; deckMaxDepth none; deckLoading none; deckError none; deckNotFound none; deckOverflow none; deckMove/Loading/Error/Empty none; deckDelete none; deckTrashed none; deleteSummaryPending/Failed none; deckActionsGone none; rootReorder library_reorder light+dark; deckReorder none. Data: CRITICAL = due count (strip, N due badge, Study CTA), deck name. SUPPORTING = mastery fraction (row bar, donut), sub-deck and card counts, algorithm. REPEATED = the due count appears in the strip, the row badge and the Study button; 'N sub-decks · N cards' appears in the summary card and again in each row. Measured on library_decks_light.png (900 px display, x1.2 = 1080): about 9 visible text lines on 3 decks (title, search hint, 2 strip lines, section header + sort, 3 name lines and 3 meta lines); library_deck_open_light.png about 12 lines.

Evidence: docs/shared/ui/screen-handoff/01-deck-list.md:59-96 (States table); golden test/features/deck/presentation/goldens/library_decks_light.png, library_deck_open_light.png

### 02-review-algorithm

Primary goal: see whether the root deck's scheduler can still change, and change it, or start a new cycle by reset. Primary action: pick the other algorithm (confirmation dialog follows). Secondary: 'Reset learning progress...' (outline button), breadcrumb and back. Critical data: the lock status and cycle (title of the strip), the selected algorithm. Supporting: lock date, the one-sentence algorithm descriptions, the consequence note. Repeated: the lock rule is told three times when unlocked or locked (strip body, note, reset body); 'Review algorithm' appears twice at the top (app bar title and last breadcrumb segment). States (detail file States table): locked (library_algorithm_locked_light/dark.png), unlocked (library_algorithm_unlocked_light/dark.png), switching (no golden), switched (no golden), switchFailed (no golden), resetConfirm (library_algorithm_reset_light/dark.png), resetting (no golden), resetDone (no golden), nothingToLose (no golden), resetSummaryLoading (no golden), resetSummaryRejected (no golden), resetSummaryError (no golden), resetFailed (no golden). Not in the States table but in code: the loading skeleton, load error and gone states (deck_algorithm_screen.dart:124-151).

Evidence: 02-review-algorithm.md:23-39; deck_algorithm_screen.dart:117,173

### 03-starter-decks

Primary goal: copy a bundled starter deck into the library under a chosen scheduler. Primary action: 'Add to library' (primary button; 'Add another copy' is secondary when a copy exists). Secondary: dismiss the fixture note, Back, Cancel in the sheet, Open on the toast, Retry, 'Create a deck'. States (golden light/dark each): list, choose, adding, added, alreadyPresent, secondCopy, addFailed, loading, none, loadFailed all have goldens (starter_*_light/dark.png); noteDismissed has no golden (widget test only). Data per card: title (critical), In-library badge (critical status), facts line language pair + card count + sub-deck count + source (supporting; the language pair and source repeat the title and the fixture note), suggested algorithm (supporting). The fixture note is a static, repeated 5-line block. Sheet: deck title repeated, lock warning, algorithm choice.

Evidence: docs/shared/ui/screen-handoff/03-starter-decks.md States table; starter_list_light.png

### 04-library-search

Goal: find a deck, card or tag by typing a term and open it. Primary action: type in the app-bar MxSearchField, then tap a result row (deck opens screen 01, card opens screen 10). Secondary: clear field, Load more results, Retry, Back. States (golden light/dark): emptyQuery (yes), loading (yes), results (yes), noResults (yes), error (yes), loadMoreFailed (yes), loadingMore (no golden), arrivedWithTerm (no golden). Data: critical = matched term emphasised in deck name or card face; supporting = deck path, group counts, tag chip; repeated = identical deck path 'TOPIK I > Danh tu' on every card row (4 of 4 rows in search_results_light.png), card tile icon on every row, chevron on every row. Static copy = hint rows, accent note, footer, no-results explanation.

Evidence: docs/shared/ui/screen-handoff/04-library-search.md:States table; goldens search_*_light.png

### 05-tags

Goal: find a tag and rename, merge or delete it safely (UC-TAG-001). Primary action: open a tag's actions (row tap or the three-dot button); secondary: search tags, Find cards with this tag, Back. Data per row: tag name (critical), card count (supporting), tag icon tile (repeated on every row, no information), the three-dot button (repeated). Header: '{n} tags' (supporting) and 'A→Z' (static, non-interactive). States and goldens (light/dark pairs): loaded, loading, empty, searchEmpty, sheet, rename, renameMerge, nameTooLong, del, busy, opError, tagGone, read error. All 13 states have goldens; the States table row for read error says '—' although tags_read_error_*.png exist. Golden size 1080x2400 (360x800 dp).

Evidence: docs/shared/ui/screen-handoff/05-tags.md:46-60; test/features/tags/presentation/goldens/tags_loaded_light.png

### 06-trash

Goal: recover a deleted card/deck (or purge it) before the 30-day expiry. Primary: Restore (row tap or ⋮ -> Restore..., selection bar Restore (n)). Secondary: Delete permanently, Select/multi-select, All/Cards/Decks filter, dismiss note, Open Trash entry. States: all (golden light+dark), cards/decks (no golden), actions (golden), restoreTarget (golden), noTarget (golden), restored (no golden), restoring (no golden), restoreTargetsLoading (no golden), restoreTargetsError (no golden), restoreRefused (no golden), undoRefused (no golden), selection (golden), selectionNone (no golden), kindLock (no golden), selectionShrinks (no golden), selectionEmptied (no golden), purgeConfirm (golden), purged (no golden), purging (no golden), purgeFailed (no golden), youngerInside/purge blocked (golden), noteDismissed (no golden), empty (golden), loading (no golden), error (golden). Data per row: name (critical), time left (critical: the deadline), kind + deleted-ago + sub-deck/card counts (supporting), Was in path (supporting; needed to choose restore target), kind icon (repeated kind info), static retention note and 'newest first' header (repeated, static).

Evidence: docs/shared/ui/screen-handoff/06-trash.md States table; trash_all_light.png

### 07-card-list

Goal: see how well the deck is learned, start studying it, find and manage individual cards. Primary action: 'Study this deck · n due' and, per row, open the card; secondary: New card FAB, search, filter chips (All/Due/New/Flagged/Tags), sort, long-press select then bulk Move/Flag/Tag/Export/Trash, deck action sheet. States (golden / none): loaded card_list_light+dark; empty none; filterEmpty none; searchEmpty card_list_search_*; searchResults card_list_search_results_*; loading none; error none; notFound none; deckActions none; selection card_selection_*; moveTargets, moveTargetsLoading, moveTargetsError, noMoveTarget, sortSheet, flagSheet, tagDialog, tagFilterLoading, tagFilterError none; bulkFailed card_list_bulk_failed_*; delCard card_list_trash_dialog_*; delDeck none; trashed card_list_trashed_*. Data: critical = due count, mastery 25%, card front; supporting = back, due badge, flag, tags; repeated = status label and due badge, mastery in ring and in text, due/new counts in summary, button and chips. On card_list_light.png about 22 visible text lines, only 3 full cards plus a cut fourth in an 800 dp viewport.

Evidence: docs/shared/ui/screen-handoff/07-card-list.md States table; test/features/card/presentation/goldens/card_list_light.png

### 08-card-create

Primary goal: add a card (front term + back meaning) to an open deck and keep adding more (UC-CARD-001 A4). Primary action: Save card (footer, right, 1:1 with Cancel). Secondary: Cancel/close, Add details disclosure (example, hint, pronunciation), Tags (Add tag then Add), breadcrumb (display only). States (detail file lines 26-40): emptyForm golden card_editor_create_light/dark.png; valid no golden; details no golden; validationErr golden card_editor_errors_light/dark.png; frontTooLong no golden; tagLimit no golden; deckRejects no golden; saving no golden; saveFailed no golden; saved no golden; pendingTag no golden; discardNew no golden; deckGone no golden. Extra goldens: card_editor_create_keyboard_*. Data shown. Critical: Front and Back fields, Save state. Supporting: char counters (0/60, 0/240), the footer caption explaining why Save is off, Tags. Repeated: 'New card' (app bar and breadcrumb), 'Required' twice, 'optional' on Add details and Tags. Only 2 of 13 states have goldens; the CLAUDE.md audit bar says an unrendered state is UNVERIFIED. Note: the Transitions table lists several rows as UNVERIFIED (code read) (detail file lines 56, 58, 59, 62, 64-66, 68, 70).

Evidence: docs/shared/ui/screen-handoff/08-card-create.md:26-41, 53-70; goldens card_editor_create_light.png, card_editor_errors_light.png

### 09-card-edit

Primary goal: correct a card's content (term, meaning, optional example/hint/pronunciation, tags) and save without touching schedule or history. Primary action: footer 'Save changes' (disabled until the draft differs). Secondary: Cancel, app-bar flag toggle, history-summary chevron (opens card detail, closes the editor), 'Move to Trash' (destructive, in the More card), 'Add tag'. States (detail file States table): loaded = card_editor_edit_light/dark.png; loading = no golden; loadError = no golden; notFound = no golden; validationErr = card_editor_errors_light/dark.png (golden shows the create variant 'New card' / 'Save card', not edit); dirtySaving, saveFailed, flagToggled, missingField, pendingTag, savedEdit, goneOnSave, discard = no golden; delConfirm = card_editor_trash_dialog_light/dark.png; extra golden card_editor_more_light/dark.png. Data: critical = term and meaning values; supporting = example, hint, pronunciation, tags, status/answers/lapses summary, deck path; repeated = 'Edit' (app-bar title 'Edit card' and breadcrumb tail), 'optional' (overline plus per-field), character counts per field, the 30-day Trash promise (More card and dialog). Budget: 12 tool calls; dark goldens, dialog golden and widget files under lib/features/card/presentation/widgets were not read, so findings rest on the screen file, the detail file and three light goldens.

Evidence: docs/shared/ui/screen-handoff/09-card-edit.md:26-44 (States table); lib/features/card/presentation/screens/card_editor_screen.dart:60-131 (_EditLoader loading/error/gone branches)

### 10-card-detail

Goal: read one card and see where it stands in SRS (when due, how it got there). Primary action: none beyond reading; Edit (app bar, secondary small button) is the only action. Secondary: Load older history, Retry, Back to deck, Open Trash. States: loaded (card_detail_top_light/dark.png; card_detail_history_light/dark.png cover the scrolled history), historyLoading, historyError, loadMore, loadMoreFailed, empty, loading, error, notFound (all no golden). Data: critical = front/back, Due date, box position; supporting = Learned, Algorithm, status badge, flag, deck path; repeated = 'Review' kind on every history card, 'Box a → b' plus 'Next due', and 'Card' shown in both app bar and breadcrumb. Top golden (1080x2400): schedule card plus first history entry fill the viewport; history entry cards are about 140 dp tall.

Evidence: docs/shared/ui/screen-handoff/10-card-detail.md:23-36; test/features/card/presentation/goldens/card_detail_top_light.png

### 11-card-import

Primary goal: add many cards to one deck from a CSV/TSV/XLSX file or pasted text, safely (nothing written until confirmed). Primary action: the footer step action (Map columns, Preview rows, Import {n}). Secondary: Cancel, Choose a file / Paste text, remove-source X, header toggle, per-column field chips, Include duplicates, Add to existing / Create new, Show all, Try again / View the cards / Back to deck. States with golden (light and dark): empty Source, mapping, mappingNoHeader, previewMix, partial, sectionsUndecided, sectionsDecided, sectionsChooseAll, sectionsResult. No golden: pasted, fileSelected, badEncoding, emptySheet, parsing, mappingIncomplete, previewAll, importing, success, sectionsRefused, sectionTargetChanged, none, failed, rejects, pickerCancelled, unsupportedFile, previewRefused. Data. Critical: the step action, the Ready count (Import n), per-row status, taken-name decisions, the Term/Meaning mapping. Supporting: file name/format/rows/columns, the first value per column, the duplicate/invalid reasons. Repeated: 'Import' (app bar title, breadcrumb leaf, tracker step 4), the step number (tracker and the '2 · MAP COLUMNS' section header), the source chip (kept on Columns and Preview), deck name and card count (Decks block and group headers).

Evidence: docs/shared/ui/screen-handoff/11-card-import.md:37-66 (States table), :22-35 (Layout); goldens import_{source,mapping,preview}_light.png

### 12-card-export

Goal: hand the deck's cards or the selected cards to the share sheet as a file. Primary action: Export (confirm; becomes Try again after a fixable failure, Close alone after a final problem). Secondary: Cancel, choosing a format. States: wholeDeck (golden export_deck_light/dark), selection (no golden), countFailed (no golden), preparing (no golden), handedOver (no golden), shareClosed (no golden), failed (golden export_failed_*), noShareTarget (no golden), staleSelection (golden export_stale_*), nothingToExport (no golden). Data: critical = card count and scope in the title, the format choice, the problem banner. Supporting = per-format description, Recommended badge. Repeated or low value = the header sentence 'Every card in {deck}, whatever filter or search is active', and the six-column note. The golden fixtures show a 1-card deck and a 2-card selection, so the 'Export 1 card' singular and the plural paths are not both pictured.

Evidence: docs/shared/ui/screen-handoff/12-card-export.md:31-44; goldens export_deck_light.png, export_failed_light.png, export_stale_light.png

### 13-study-home

Goal: see what is due and start or resume studying. Primary action: Resume (full-width primary button, shown only with an open session); when there is none, the primary action is tapping a deck row. Secondary: Library (small secondary button), Practice TOPIK row, Sync/Reauth notice buttons, noDecks CTAs. States (golden light/dark): loaded, noResume, zero, noDecks, noCards, loading, error, syncRejected, syncStale, reauth (account tests). All 10 have goldens, but the detail file's Rulings (line 78) say the frames with several decks (no_resume, sync_rejected, sync_stale) crop the Practice slot. Data: critical = due total (10 cards due) and Resume; supporting = overdue/today split and 'across N decks', per-deck deck names; repeated = overdue/today/new glyph+word terms, repeated on every deck row (3 terms x N decks, including 0-valued ones); the Resume card meta line (kind, mode, done/total) is supporting. Loaded golden (1080x2400 px): about 24 text lines visible, of which about 15 are workload term fragments.

Evidence: docs/shared/ui/screen-handoff/13-study-home.md:29-40; study_home_loaded_light.png

### 14-study-entry

Primary goal: start a study session on the open deck (Learn new cards, or Review due cards), or resume today's session. Primary action: the pinned footer button ("Review {n} due cards" / "Learn {n} new cards" / "Continue"; outline "Start a new review instead" while the resume banner shows). Secondary: the Learn row button, the Eight-boxes mode pick (radio rows), the Study options icon, Back, the SM-2 Direction sheet. States (detail file States table): sm2 golden; eightBox golden; onlyNew golden; nothing golden; resume golden; starting golden; refused golden; startFailed golden; loading golden (all with light and dark); error no golden (widget test); deckGone no golden (toast and pop); plus a Direction sheet golden. Data. Critical: the Due count, the footer CTA, the resume progress. Supporting: the New count, the overdue note, mode availability and counts, the algorithm name, the per-session cap. Repeated: the deck name (app bar and last breadcrumb crumb); the Due count (tile, footer button, caption "4 of 4 due" in sm2 golden); the New count (tile and Learn row "20 of 25 new"); the 20-card cap (hero line and Learn row).

Evidence: docs/shared/ui/screen-handoff/14-study-entry.md:32-47; goldens study_entry_sm2_light.png, study_entry_eight_box_light.png, study_entry_resume_light.png (1080x2400)

### 15-study-options

Primary goal: set a root deck's cards per session, new-card order and speech language (or follow app defaults) and save them for later sessions. Primary action: Save, in the footer (disabled until a valid change; 'Retry save' after a failure). Secondary: the Use app defaults toggle, the stepper, the order tray, the speech-language row and sheet, Back with discard confirm. States: override (golden light and dark), defaults (golden), invalid (golden), saving (golden), saved (golden), saveFailed (golden), loading (golden), unreadableOverride (no golden), gone (no golden), read error (no golden), discardAsk (no golden). Data: critical = card limit, order, speech language, Save enabled or not, failure banner. Supporting = the toggle's own-options or following-settings line, the section header, the caption 'Saved to this device only.'. Repeated = 'Study options' (app bar title and breadcrumb tail), the layers note restating scope, per-row hint lines ('1 to 200', 'How new cards enter a learning session', 'The language the term is read in').

Evidence: docs/shared/ui/screen-handoff/15-study-options.md:40-54; goldens study_options_{override,defaults,invalid,saving,saved,save_failed,loading}_{light,dark}.png

### 16-study-browse

Primary goal: read the term and meaning together and memorise them, then move on (ungraded, BR-MODE-005/006). Primary action: Next card (full-width MxButton, size study). Secondary actions: swipe left (next), swipe right (look back), speaker (read the term aloud), close (exit dialog). States in the detail file's States table: default (study_browse_light.png / study_browse_dark.png) and a note on looking back, which has study_browse_looking_back_light.png / study_browse_looking_back_dark.png goldens but is not a table row. The Session route states (sessionLoading, sessionReadError, unsavedAnswer, heldTurn, stalledRound, exitDialog, deckGone, stopFailed, staleGeneration, summary) all have no golden. Data shown. Critical: term, meaning. Supporting: pronunciation, example, speaker, looking-back badge, progress track and counter. Repeated or chrome: BROWSE badge, TERM and MEANING labels, context line, footer hint. Text lines on the default golden (1080x2400, 3 px per dp): about 9 (counter 1, BROWSE 1, context line 1, TERM 1, term 1, pronunciation 1, MEANING 1, meaning 1, example 1, button 1, hint 1 = 11 including controls; 9 excluding the button and the counter).

Evidence: docs/shared/ui/screen-handoff/16-study-browse.md:138-141; study_browse_light.png; study_browse_looking_back_light.png

### 16a-study-self-assess

Goal: grade how well a due card was remembered, quickly and one-handed. Primary action: Show answer (before reveal), then one of four grades. Secondary: speaker (Read aloud), Close, tapping the prompt card to reveal. States (detail file States table, lines 46-53): prompt (golden study_self_assess_prompt_light/dark; the meaning-first variant has study_self_assess_meaning_first_*), revealed (golden study_self_assess_revealed_*), relearning (golden study_self_assess_relearning_*), saving (no golden), saveFailed (no golden), stale (no golden; handled on screen 21). Data: critical = the prompt face, the answer face, the four grade labels; supporting = intervals under the grades (hidden on relearning), counter 1/2 and progress bar, pronunciation, example; repeated or low-value = mode pill 'SELF-ASSESS', context line 'Động từ · REVIEW' (a Vietnamese word beside an English one, which suggests a part-of-speech label in the deck row), face labels TERM and MEANING, and the footer hint.

Evidence: docs/shared/ui/screen-handoff/16a-study-self-assess.md:46-54; golden study_self_assess_revealed_light.png (1080x2400)

### 17-study-match

Goal: pair each term with its meaning, up to 5 pairs a board, graded (eight_box only). Primary action: tap a term then a meaning, in either order. Secondary: exit (X), tap again to move the selection. States table: default has study_match_board_light/dark.png; the wrong-pair flash has study_match_wrong_light/dark.png (listed under 'other goldens', not as a row). Matched, selected, busy-write, unsaved-answer banner and route states have no golden for this screen (busy and banner frames are UNVERIFIED in the detail file). Data shown. Critical: the 10 tiles with their tone, plus the term and meaning text. Supporting: pair progress counter (2/5), MATCH chip. Repeated: 'Review' and 'Round n' in the context line, and the persistent instruction footer, which is identical on every board.

Evidence: docs/shared/ui/screen-handoff/17-study-match.md:21-30; study_match_board_light.png (1080x2400); lib/features/study/presentation/widgets/sections/study_match_widget.dart:154-165

### 18-study-guess

Goal: pick the correct meaning of the shown term (one graded question per turn, first tap counts). Primary action: tap one of 5 option rows A-E. Secondary: speak the term (speaker button), exit X in top bar. Passive chrome: mode chip GUESS, round progress bar and '1 / 5', context line, footer hint. States (detail file States table + 'Other goldens' line): default = study_guess_idle_light/dark.png; answered right = study_guess_right_light/dark.png; answered wrong = study_guess_wrong_light/dark.png; blocked = study_guess_blocked_light/dark.png. Not in the table and with no golden: busy-refused (unsaved-answer banner, options locked), TalkBack answered with a Next button, speaker disabled (no voice on device). Data: critical = term ('reservation') and the 5 meanings; supporting = progress '1 / 5', deck name; repeated/low-value = mode name GUESS chip, 'REVIEW', 'ROUND 1', overline 'WHAT IS THIS?', footer hint. The golden has about 15 visible text runs (GUESS, 1/5, context line, overline, term, 5 letters, 5 meanings, hint) of which only the term and 5 meanings are learning content.

Evidence: docs/shared/ui/screen-handoff/18-study-guess.md States table; test/features/study/presentation/goldens/study_guess_idle_light.png (1080x2400)

### 19-study-recall

Primary goal: test recall of the term's meaning inside a 20 s turn, then self-grade. Primary actions: Show the meaning (countingDown), Forgot / Remembered (revealed, both secondary), Continue (timedOut). Secondary: exit X, speaker (Read aloud). States: countingDown = study_recall_counting_light/dark.png; revealed = study_recall_revealed_light/dark.png; timedOut = study_recall_timed_out_light/dark.png (all three states have goldens; the refused-reveal and unsaved-answer-banner frames have no golden, doc lines 51 and 61). Data: critical = term, meaning (once shown), seconds left; supporting = RECALL chip, 1/5 session count, clock bar, Counted as forgot tag; repeated/restated = context line 'Nha hang . REVIEW . ROUND 1', clock caption (Time to recall / Revealed with time left / Time is up), footer hint which restates the state. Visible text items on the counting golden: about 10 (chip, 1/5, context line, clock caption, 14s / 20s, TERM, term, MEANING, button, hint). Viewport is 1080x2400 px (360x800 dp).

Evidence: docs/shared/ui/screen-handoff/19-study-recall.md:13-31; study_recall_counting_light.png

### 20-study-fill

Primary goal: recall and type the term for a shown meaning. Primary action: Check (input/hint), Continue (wrong). Secondary: Show hint (only when the card has a hint), exit X. States: input (study_fill_input_light/dark.png), hint (study_fill_hint_light/dark.png), wrong (study_fill_wrong_light/dark.png); the right-answer path has no frame (no golden, by design). Keyboard-open and the unsaved-answer banner are covered by tests, no golden. Data shown. Critical: the meaning prompt, the answer field, the Check/Continue button, and in wrong the typed vs correct term. Supporting: the hint text, the 'Wrong . comes back next round' tag, the 1/5 progress. Repeated or chrome: FILL chip, context line 'deck . REVIEW . ROUND n', MEANING and TERM face labels, the footer instruction. Visible text blocks in the input golden: about 9 (FILL, 1/5, context line, MEANING, prompt, TERM, typed text, 2 buttons, footer); 11 incl. the prompt's 2 lines.

Evidence: docs/shared/ui/screen-handoff/20-study-fill.md:37-43; lib/features/study/presentation/widgets/sections/study_fill_widget.dart:117-185; golden study_fill_input_light.png

### 21-session-summary

Primary user goal: learn how the session ended and leave it (back to the deck). Primary action: Done (filled, right). Secondary action: Study again (outline, left; only for reviewFinished, learningFinished and leftEarly). No other controls (no back, no app-bar actions). States, each with light and dark goldens: loaded (summary_review), learning (summary_learning), large (summary_large), leftEarly (summary_left_early), interrupted (summary_interrupted), reset (summary_reset), schedulerChanged (summary_scheduler_changed), saveError (summary_save_error), contentDeleted (summary_content_deleted). No state lacks a golden. Loading is not a state of this screen. Data: critical = outcome title and tone icon, the headline count (cards reviewed or finished), wrong turns as 'W of T'. Supporting = deck name and session kind (overline), the body sentence, the 'Wrong cards came back in later rounds.' note, the answered count when it differs. Repeated = the finished and answered counts in the Facts card (shown only where the hero has no stats), the 'Done returns you to the deck.' caption on every state, and the hero body stating the count that a tile would also show. Measured on summary_review_light.png (1080 px wide, 3 px/dp): about 9 visible text lines (title, overline, title, 2 body lines, figure, label, note, caption, plus 2 button labels). summary_reset_light.png has about 17 (5 body lines, 3 fact rows with 2 sub-lines).

Evidence: docs/shared/ui/screen-handoff/21-session-summary.md:19-31 (States table), :13-17 (Layout); goldens summary_review_light.png, summary_reset_light.png

### 21-session-summary

Only 3 of 18 goldens (review, interrupted, reset, light) and the hero widget were read; the Facts widget file and dark goldens were not opened, so contrast and touch-target findings were not assessed.

Evidence: lib/features/study/presentation/widgets/sections/session_summary_facts_widget.dart not read

### 22-progress

Primary goal: see whether I studied today / this week, keep the streak, and find which deck got attention. Primary action: none on a loaded screen (read-only); drill into a deck row. Secondary: 7/30-day range tray; Start studying (never state only). States (detail file States table): loaded week (progress_week_light/dark.png), month (progress_month_*), held (progress_held_*), lost (progress_lost_*), deck (deck_progress_deck_*), never (progress_never_*), loading (progress_loading_*), error (progress_error_*), quiet range (progress_quiet_*), no decks (progress_no_decks_*), leaf (deck_progress_leaf_*), deck gone (deck_progress_gone_*), day tooltip (no golden), deck error (no golden). Data: critical = today's count (17), streak days (4); supporting = 7-day stacked bars, per-deck cards/active days/card-days; repeated = 'learning'/'reviewing' split appears in the Today line, chart legend, and in every deck row; 'Card-days:' label repeats per row; 'Last 7 days' range is stated in the tray only. Screen is 3 cards + tray + list: in progress_week_light.png the first 2000/2400 px hold the app title, Today, Streak, range tray and only 1.5 deck rows. Chart is out of scope (being rebuilt).

Evidence: docs/shared/ui/screen-handoff/22-progress.md:22-30,47-63; golden progress_week_light.png (900-wide view x1.2 = 1080 px)

### 23-settings

Primary goal: reach and read the current value of one setting group (Study, Theme, Language, Reminder, Account, Sync), or reset app options. Primary actions: tap a row to open its page (Study options, Theme, Language, Daily reminder, account, Sync, Admin tools). Secondary: Reset app options (dialog), debug gallery icon. States and goldens: loaded (settings_loaded_light/dark), loading (settings_loading_*), admin row (settings_admin_row_*), resetConfirm (settings_reset_confirm_*), resetDone (settings_reset_done_*), resetting (no golden), resetFailed (no golden), syncSynced/syncFailed/syncRejected (settings_sync_*_light/dark), account anonymous (settings_account_*), account signed in (settings_account_signed_in_*), account re-auth (settings_account_reauth_*), read error (no golden). Data: critical = each row's current value (study summary, theme, language, reminder, sync state, account email); supporting = row icons, section overlines; repeated = the Reset scope, stated in the row subtitle, the note under it and the dialog body. Loaded golden (1080x2400 px = 360x800 dp): about 21 visible text lines in 3 sections (title 1, overlines 3, Study 3, Theme 2, Language 2, Reminder 2, Reset row 3 + note 4 = 20-21). Unit is within budget; admin, reset-confirm, reauth and dark goldens were not opened.

Evidence: docs/shared/ui/screen-handoff/23-settings.md:41-58; settings_loaded_light.png line count read on the image

### 23a-study-defaults

Goal: set app-wide study defaults (cards per session, new-card order, read-aloud, speech language), each saved on change. Primary actions: step/type the card limit (stepper), flip the read-aloud toggle. Secondary: open the new-card order sheet, open the speech language sheet, Back. States (detail file 37-49): loaded (golden light+dark), loading (golden), saving (golden), saved (golden), invalidLimit (golden), saveFailed (golden), new-card order sheet (golden), speech language sheet (golden), read error (no golden). A further golden study_options_defaults_{light,dark}.png exists but is not in the States table. Data: critical = the four current values (20, In order, toggle on, English (US)); supporting = row sub-lines (Per session, the toggle hint, 'Used by decks that follow the defaults'); repeated = two footnotes that restate that a deck with its own options/speech language keeps them, and the info glyph on each.

Evidence: docs/shared/ui/screen-handoff/23a-study-defaults.md:37-49; study_defaults_loaded_light.png

### 23b-admin

Primary goal: reach an admin tool (Monitoring logs, Users) or switch SQL logging. Primary actions: open Monitoring (28), open Users (33), flip Log SQL statements toggle. Secondary: Back. States: loaded (admin_light.png, admin_dark.png); gate (no golden; wait skeleton or 'Only an admin can see this'). Data shown: critical = three row titles and the toggle's on/off value; supporting = three one-line descriptions; repeated = none, though the two Logs rows share the word 'Logs'/'Log' (section 'Logs', 'Logs of the app and the server', 'Log SQL statements'). Golden admin_light.png (900x2000 display, x1.2 to 1080x2400): about 14 visible text lines (title, 2 section headers, 3 row titles, 2 + 5 + 1 description lines), 3 text blocks of description. Roughly the bottom 45% of the viewport is empty.

Evidence: docs/shared/ui/screen-handoff/23b-admin.md:30-35; admin_screen.dart:40-45; test/features/settings/presentation/goldens/admin_light.png

### 24-daily-reminder

Goal: turn the one daily study notification on/off and set its time, with confidence about what it will say. Primary action: the toggle (row 1). Secondary: time button (opens Hour/Minute stepper dialog), banner actions (Try again / Open system settings / Retry). States (detail file States table): off (golden light+dark), turningOn (golden), on (golden), previewDue (golden), changingTime (golden), permDenied (golden), couldNotSchedule (golden), offMayShow (golden), couldNotChangeTime (no golden), savingTime (no golden), turningOff (no golden), unavailable (golden), loading (golden); read error has golden reminder_read_error_* but is only in the prose below the table, not in the table. Data: critical = toggle state, time HH:mm, any problem banner; supporting = notification preview sentence; repeated/boilerplate = three hints and a note that restate the same 'once a day, only when due' rule (row 1 subtitle, row 2 subtitle, note, preview hint). The 'on' golden has 15 visible text lines on a 2400 px (800 dp) screen: title 1, row1 3, row2 3, note 2, section title 1, preview 5.

Evidence: test/features/reminders/presentation/goldens/reminder_on_light.png (15 lines counted); docs/shared/ui/screen-handoff/24-daily-reminder.md:27-43

### 25-theme

Goal: choose the app theme (System / Light / Dark) and see it apply at once. Primary action: tap one of three theme cards (single choice, applies immediately, no confirm). Secondary: Back; Retry on the failure toast. No submit button. States (detail file States table): system = settings_theme_system_light.png / settings_theme_system_dark.png; light = settings_theme_light_light.png / settings_theme_light_dark.png; dark = settings_theme_dark_light.png / settings_theme_dark_dark.png; read error = no golden (MxErrorState + Retry, widget test only); loading skeleton (Transitions table only) = no golden, UNVERIFIED. Data shown. Critical: which theme is selected (indigo ring + check) and the three previews. Supporting: the names System/Light/Dark. Repeated/redundant: the hint lines Match phone / Always light / Always dark, which restate the name, and the footnote Applies at once. Measured on the system_light golden (1080x2400, 3 px/dp): about 3 percent of height, y 180-580 in displayed px, is cards; the content ends near y 710 of 2000 displayed, so about 65 percent of the viewport is empty. Visible text lines: 1 title + 3 names + 4 hint lines (Match phone wraps to 2) + 2 note lines = 10.

Evidence: docs/shared/ui/screen-handoff/25-theme.md:26-31; theme_screen.dart:60-105; golden settings_theme_system_light.png

### 26-language

Primary goal: choose the app language (follow phone / English / Tiếng Việt) and see it applied at once. Primary action: tap one of three radio rows (MxOptionRow). Secondary: Back; toast Retry on a failed save. States (detail file States table): english = settings_language_english_{light,dark}.png; vietnamese (toast in Vietnamese) = settings_language_switched_{light,dark}.png; system = settings_language_system_{light,dark}.png; read error = no golden (MxErrorState + Retry); loading (Transitions table, MxSkeletonList x3) = no golden. Data: critical = the three language names and which one is selected; supporting = 'Phone is set to X' line under Follow the system, the 'Vietnamese' gloss under Tiếng Việt; repeated/static = the 3-line note 'Applies at once ... own language', identical in every state. Golden count on settings_language_english_light.png (1080x2400): about 9 visible text lines (title 1, row titles 3, sub-lines 2, note 3); content ends near y=1040 px of 2400, so roughly 57% of the viewport is empty.

Evidence: docs/shared/ui/screen-handoff/26-language.md:26-31 (States table); settings_language_english_light.png: sub-lines at y~365 and ~755 px, note lines y~890-1020 px

### 27-sync

Primary goal: know whether my changes are safe and on the server, and act if not. Primary action: Sync now (primary only when changes wait or a non-network run failed and none refused); with refused rows the banner's Try again is the one primary. Secondary: Keep on device (opens a confirm dialog), Back. States in the detail file: synced, neverSynced, pending, failedNetwork, failedServer, rejected, keepDialog, syncing have goldens (sync_*_light/dark.png); retrying, keeping, change failed, loading, read error, unavailable have no golden. Data: critical = refused count and the failure sentence, the waiting count; supporting = Last synced time; repeated/boilerplate = the 'MemoX syncs on its own...' note (identical in every state) and the failure sentence that restates it. Measured on sync_synced_light.png (1080x2400): about 9 visible text lines (title, STATUS, 4 row lines, 2 note lines, button), content ends at about y=1140 px so about 52% of the viewport is empty.

Evidence: docs/shared/ui/screen-handoff/27-sync.md:37-52; sync_screen.dart:63-96; sync_synced_light.png

### 28-monitoring

Goal: an admin triages open warnings and errors (server logs), reads one log whole, and marks it fixed. Primary actions: open a row; on detail, Mark fixed or Reopen. Secondary: Server and Not sent tabs, search, 5 filter chips, refresh, copy JSON, SQL-log switch, Retry. States with a golden (light and dark): list loaded, list every level, list empty, list offline, Not sent, Level sheet, detail open error, detail scrolled (trace), detail fixed with note, detail local buffer. States with no golden: refresh failed, list loading, loading more, load more failed, end, Not sent loading, error and empty, detail changing, status sheet, change failed, no match, list error, not an admin, detail loading, error, offline and gone. Data in a list row: critical is the level glyph, event and time; supporting is the first message line and the Open/Fixed badge (hidden when the Status filter already says it). Repeated is the level and status, which the chips, header and badge all restate. Detail: critical is level, event, status and message; supporting is the error type, stack trace and Details; repeated is the event (app bar title) and the message (subtitle on the list, Message card on detail).

Evidence: docs/shared/ui/screen-handoff/28-monitoring.md:60-90 (States table, 10 golden states and 16 with no golden)

### 29-welcome

Primary user goal: get past the first-launch screen, choosing how (Google, email, or no account). Primary action: Continue with Google (the only filled button) while the account can link; Continue without an account becomes the primary and only action offline. Secondary actions: Continue with email (outline) and Continue without an account (text button). States in the detail file's States table: ready (golden welcome_ready_light and welcome_ready_dark); starting (no golden, widget test only); offline (golden welcome_offline_light and welcome_offline_dark); Google running (no golden); Google failed (no golden, toast, code read only); identity taken (no golden here, the merge sheet goldens are on screen 30). Data shown. Critical: the three exit actions and, offline, the caption 'Signing in needs a connection. Try later in Settings.'. Supporting: the lead 'MemoX works on this phone without an account, offline too. Signing in adds:' and two benefit rows (keep decks on reinstall, study on several phones). Decorative: the icon tile, which stands in for the app icon. Repeated: nothing repeated within the screen. Count on the ready golden: 9 visible text lines (title 1, lead 2, benefits 3, buttons 3).

Evidence: 29-welcome.md:37-48 (States table); welcome_screen.dart:103-173; welcome_ready_light.png (1080x2400)

### 30-sign-in

Primary goal: attach an email or Google account to this phone (link), or sign in again after the session was refused (reauth). Primary action: Send code (the filled button in the footer). Secondary actions: Continue with Google (outline), Back, and in reauth only 'Continue without this account' (text button in the body). Data shown. Critical: the email field and the two sign-in ways. Supporting: the title and the lead sentence, which says decks stay on the phone. Repeated in reauth: the account email appears twice, in the eyebrow and in the field. States with a golden: link, invalid, reauth, reauth unsent loss, reauth continue without, merge sheet merge, merge sheet discard, layer sending, merging, offline, target sign-in, sign-out offline and stuck. States with no golden: sending, Google running, problem under the field for offline, rate limit and other failures, waiting (offline caption), and layer merge stopped on refused changes. The detail file lists 14 goldens, and the account goldens folder holds 9 sign_in_* files only for link, invalid, reauth, unsent_loss and continue_without. Read this review from the link, invalid and reauth light goldens only. The merge sheet and layer goldens fall outside the budget and are not reviewed here.

Evidence: docs/shared/ui/screen-handoff/30-sign-in.md:102-121 (States table); lib/features/account/presentation/screens/sign_in_screen.dart:64-96

### 31-code

Primary goal: enter the 6-digit emailed code to finish sign-in. Primary action: typing six digits (auto-verifies, no button). Secondary actions: Resend code (after wait), Use another email, Back. States per detail file: waiting (golden code_waiting_light/dark), wrong (golden code_wrong_light/dark), verifying (no golden), resend ready (no golden), resending (no golden), resend failed (no golden), resend loss dialog (no golden here; frame is sign_in_unsent_loss_* on screen 30). Data: critical = the six code slots and the error message; supporting = title 'Enter the code', lead plus the address (confirms where the code went), countdown 'New code in 1:00'; repeated/low-value = spam hint, a second text 'Use another email', back arrow. Waiting golden: 5 visible text lines (title, lead, address, countdown, spam hint) plus one button label, about 6 text items, in the top ~850 px of 2400 (about 35% of the height); the rest is empty.

Evidence: test/features/account/presentation/goldens/code_waiting_light.png (1080x2400); lib/features/account/presentation/widgets/sections/code_form_widget.dart:102-146

### 32-account

Primary user goal: manage the account this phone's data belongs to (see who is signed in; switch, sign out, delete). Primary actions: Switch account, Sign out (3 command rows, each opens a confirm dialog). Secondary: Delete account (neutral row, danger only in the dialog), the reauth 'Sign in' button, Back. States (golden light/dark): ready (account_ready), validating (account_validating), reauth (account_reauth), switch dialog (account_switch_confirm), sign-out dialog (account_sign_out_confirm), sign-out loss (account_sign_out_loss), delete dialog (account_delete_confirm), delete offline (account_delete_offline), last admin (account_last_admin); command running, transitioning, command refused (toast): no golden. Data: critical = email + sign-in method (supporting: the only identity facts), the 'Removes this phone's data' consequence on Sign out; supporting = 'Move this phone to another account'; repeated = section captions ACCOUNT / THIS PHONE / DELETE restate the row labels ('Delete' appears as caption, label, and dialog confirm; 'Sign out' as label and confirm). Ready golden: 3 section captions, 4 rows, 4 subtitle lines in 6 wrapped text lines, ~1/3 of the 2400 px height used.

Evidence: docs/shared/ui/screen-handoff/32-account.md:49-62; lib/features/account/presentation/screens/account_screen.dart:92-132; golden account_ready_light.png

### 33-users

Goal: an admin finds an account by email and changes its role (Admin/User). Primary action: tap a row to open the role sheet, then Save. Secondary: search by email, pull to refresh, scroll to page, Retry, back. States (detail file States table): loaded (golden users_loaded_light/dark), no match (users_empty_search_*), offline (users_offline_*), role sheet (users_role_sheet_*), role sheet changed (users_role_sheet_changed_*), role sheet refused (users_role_sheet_refused_*), loading (no golden), loading more (no golden), load more failed (no golden), end (no golden), role sheet saving (no golden), no accounts (no golden), error (no golden), not an admin (no golden). Data per row: email = critical; role badge = critical (the thing being edited); join date = supporting but identical on every row in the golden (5 of 5 read 'Joined Sep 1, 2026'); person tile = repeated, same on all rows, carries no data; 'You' marker = supporting. Section overline 'ACCOUNTS' = repeated label with no count. Loaded golden (1080x2400 px): 8 distinct text lines above the fold excluding rows' repeated content (title, search hint, ACCOUNTS, 5 emails, 5 date lines, 5 badges, 'No more users'); about 40 percent of the viewport (y 1420-2400 px) is empty.

Evidence: docs/shared/ui/screen-handoff/33-users.md:42-61; users_loaded_light.png

### 34-topik-home

Primary goal: pick TOPIK I or TOPIK II to start practising. Primary action: tap a level row (opens screen 35, Reading). Secondary: Back to Study home; Retry in the error state. States (detail file States table, lines 25-32): loaded (golden light and dark), noTests (golden light and dark), loading (golden light and dark), error (golden light and dark), retrying (no golden), error after data (no golden). Data shown: critical = level name (TOPIK I / II) and whether it has tests; supporting = test count; repeated = 'Reading, Listening' on both rows, 'Levels x-y' grades, 'tests' unit, and the Korean subtitle (static). On the loaded golden 1080x2400 the page uses about 690 of 2000 displayed px (about 35 percent); the lower 65 percent is empty.

Evidence: docs/shared/ui/screen-handoff/34-topik-home.md:25-32; test/features/topik/presentation/goldens/topik_home_loaded_light.png

### 35-topik-test-list

Goal: pick one past paper of a level and section and open it (continue, retry or start). Primary action: tap a row (opens screen 36). Secondary: Reading/Listening tray, sort chip (sheet of 3 orders), Back. States (detail file States table): reading (topik_list_reading_light/dark.png), listening (topik_list_listening_*), withStatus (topik_list_status_*), sortSheet (topik_list_sort_*), empty (topik_list_empty_*), loading (topik_list_loading_*), error (topik_list_error_*); all have goldens, none is 'no golden'. Data: critical = round badge and Korean title, status (In progress / Best n / attempts); supporting = content tags; repeated or static = '{n} tests' count, section icon tile, 'Past papers published by NIIED.' (same text on every open of the screen), 'Newest round' sort label. Golden topik_list_status_light.png (1080x2400): about 1 app bar line, 1 tray line, 2 header lines, 3 rows with 4+2+2 meta/title lines = about 14 visible text lines; three rows fill only about 1/2 of the viewport.

Evidence: docs/shared/ui/screen-handoff/35-topik-test-list.md:States table; topik_test_row_widget.dart:43-49; topik_test_list_header_widget.dart:33-69

### 36-topik-test-detail

Goal: see how I am doing on one TOPIK test and start/continue/review an attempt. Primary action: FAB '+' (start or continue attempt); on empty Overview the Start button in the empty state. Secondary: tray Overview/History, recent row tap (Summary or Continue), History row Summary/Review/Continue, delete. States (golden light+dark unless noted): overview, overviewEmpty, history, historyEmpty, deleteConfirm, continueOrNew, testMissing, loading, error (all with golden); startNewConfirm no golden. Data: critical = Best, Average, Accuracy, Completion, per-attempt score; supporting = Sessions, Completed count, last activity, total time, correct/count, duration; repeated = score and correct/count in Recent attempts and History rows (same five attempts shown on both tabs), Completed count vs History count, 'Completed'/'In progress' status. Overview golden: 4 tiles-rows plus meta plus hint plus recent list, roughly 14 text lines in the first 2000 px viewport (~667 dp), the FAB overlaps the #3 row.

Evidence: docs/shared/ui/screen-handoff/36-topik-test-detail.md:16-38; golden topik_detail_overview_light.png, topik_detail_history_light.png

### 37-topik-attempt

Primary goal: answer the current question (read or listen, tap one of four options), move through ~50 questions, then submit. Primary action: pick an option, then Next / Submit. Secondary: Previous (icon), Questions (grid sheet), Close, collapse passage, Show/Hide script, audio play/seek/speed. States (golden light+dark unless noted): answering (topik_attempt_reading), answeringListening (topik_attempt_listening), scriptShown (topik_attempt_script), collapsed (topik_attempt_collapsed), grid (topik_attempt_grid), submitConfirm (topik_attempt_submit_confirm), submitting (topik_attempt_submitting), audioError (topik_attempt_audio_error), attemptMissing, contentMissing, submitted, loading, error (each with its golden); no golden: speedSheet, audioLoading (UNVERIFIED), audioPlaying, collapsedListening, pictureGroup (UNVERIFIED), deleteConfirm. Data: critical = question stem, four options, selected option, audio play/seek; supporting = position '1 / 50', passage/instruction, script; repeated = 'Questions' (footer button label and grid sheet title), the instruction line '※ ...' repeats per group and per question in the same group, 'PRACTICE' mode chip on every question. Listening golden (1080x2400 px = 360x800 dp): about 13 visible text lines/labels (PRACTICE, 1/50, instruction, 0:12/0:30, 1x, Show script, stem, 4 options, Questions, Next); the group pane takes y=160..760 px of display (about 240 dp, 30% of the screen) for instruction + audio + toggle.

Evidence: docs/shared/ui/screen-handoff/37-topik-attempt.md States table; golden test/features/topik/presentation/goldens/topik_attempt_listening_light.png

### 38-topik-summary

Primary goal: see how the submitted attempt went (score, where it was lost) and go review wrong answers. Primary action: 'Review answers' (footer, primary). Secondary: 'Done', answer-row/bar tap to Review (39), filter chips, eye toggle (show/hide right answers), app-bar Back. States (detail file States table): loaded (topik_summary_loaded_light/dark.png), loaded chart in view (topik_summary_chart_*), perfect (topik_summary_perfect_*), zero (topik_summary_zero_*), topik1Reading (topik_summary_t1_reading_*), correctHidden (topik_summary_hidden_*), filterEmpty (topik_summary_filter_empty_*), attemptMissing (topik_summary_missing_*), loading (topik_summary_loading_*), error (topik_summary_error_*); all have light and dark goldens. Data: CRITICAL = score 54/100, correct 27/50, weakest type, wrong count. SUPPORTING = average per Q, longest Q, answered/unanswered, per-question time bars, by-type stats. REPEATED = correct/total (hero donut + score), answered/unanswered (tiles + chip counts 40/10 vs 'Unanswered 10'), per-question status+time (bars + 50 rows), 'Correct/Wrong/Unanswered' (chips, legend, row badges). In the loaded golden (1080x2400 = 360x800 dp) the first viewport reaches only the chart top; 'By question type' (weakest area) is below 50 answer rows and is never visible without a long scroll.

Evidence: docs/shared/ui/screen-handoff/38-topik-summary.md:16-26,30-40; golden topik_summary_loaded_light.png

### 39-topik-review

Goal: after a submitted TOPIK attempt, see per question what the right answer is, what I chose, and why (explanation/words/grammar), then walk the questions (all or filtered). Primary action: Next (primary, footer; becomes Done on last). Secondary: Previous, the filter chips (All/Wrong/Unanswered/Correct with counts), collapse the group pane, hide/show script, audio play/speed, back. States (detail file States table): wrong (golden light+dark), correct (golden), unanswered (golden), listening (golden), contentUpdated (golden), contentMissing (golden), attemptMissing (golden), loading (golden), error (golden), lastQuestion (no golden), groupCollapsed/scriptHidden (no golden), audioFailed/audioLoading/speedSheet (no golden), pictureOption (no golden). Data: critical = right option and the person's wrong choice, stem, explanation; supporting = passage/instruction, words, grammar, translation, position in title; repeated = the right/wrong result appears three times (tile tone, the answer line 'Your answer 2 . Right answer 1', TalkBack label) and the question number appears in the title and in the stem. Goldens were read: topik_review_wrong_light.png and topik_review_listening_light.png only (budget); the other states were not rendered by me.

Evidence: docs/shared/ui/screen-handoff/39-topik-review.md:30-47 (States table); topik_review_wrong_light.png

## Appendix B. Finding register

Every P0–P2 finding the describe pass reported and its adjudicated verdict after two Opus passes (`*` = the passes disagreed; the more informative verdict wins). P3 notes other than the inventory are listed with `NOT_VERIFIED`.

| Screen | Sev | Dimension | Finding | Verdict |
|---|---|---|---|---|
| 01-deck-list | P1 | accessibility | Mastery bar is unlabeled and its colour carries the meaning; the percent is TalkBack-only | REFUTED |
| 01-deck-list | P2 | text-density | Open-deck summary: due figures stated in three places, breakdown wraps to a second line | REFUTED |
| 01-deck-list | P2 | text-density | Row meta: counts as text on every row, empty-deck meta wraps to 2 lines and breaks row rhythm | REFUTED |
| 01-deck-list | P2 | consistency | Three different encodings of the same mastery measure within one screen | REFUTED |
| 01-deck-list | P2 | hierarchy | Overflow menu and sort pill: three same-weight primary-ish controls compete on first view, row overflow icon is a dot menu with no visible due-first cue | REFUTED |
| 01-deck-list | P2 | interaction | Summary Study button is a full-width block that disappears when nothing waits, leaving the card without an action | REFUTED |
| 02-review-algorithm | P1 | text-density | Reset dialog Kept/Lost tiles squeeze prose into a narrow two-column layout | REVISED_TARGET |
| 02-review-algorithm | P2 | text-density | Lock rule and consequence repeated in strip, note and reset body | REVISED_TARGET |
| 02-review-algorithm | P1 | text-density | About 24-25 text lines and 7 text blocks above a below-fold primary secondary action | REFUTED |
| 02-review-algorithm | P1 | hierarchy | Algorithm choice and its lock state are separated by a note and read as three unrelated cards | REFUTED |
| 02-review-algorithm | P2 | visual-representation | Lock status shown as plain sentences rather than a status plus cycle badge | REFUTED |
| 02-review-algorithm | P2 | accessibility | Lost tile uses warning text on a warning tint in the reset dialog; Kept title is small | REFUTED |
| 02-review-algorithm | P2 | interaction | Algorithm descriptions use terms the user cannot compare | REFUTED |
| 03-starter-decks | P1 | text-density | Fixture note takes about a quarter of the first viewport | REFUTED |
| 03-starter-decks | P1 | visual-representation | Facts line repeats the title and the note, and mixes four attributes as dot-text | REFUTED |
| 03-starter-decks | P2 | hierarchy | Suggested algorithm is a loose text line under the action, and the choice is split across two places | REFUTED |
| 03-starter-decks | P2 | text-density | Algorithm sheet: long description rows and sheet competes with the lock warning | REFUTED |
| 03-starter-decks | P2 | accessibility | 'Add another copy' secondary button has low contrast fill against the card | REFUTED |
| 04-library-search | P2 | text-density | Empty query shows 3 hint rows plus a 3-line note (about 9 text lines before any input) | REFUTED |
| 04-library-search | P2 | text-density | Results footer is a 2-line caption restating the group order and the accent rule | REFUTED |
| 04-library-search | P2 | text-density | Deck path repeated on every card row | REFUTED |
| 04-library-search | P2 | hierarchy | Load-more-failed banner Retry button is a filled primary inside a danger banner, placed below the fold after 8+ rows | REFUTED |
| 04-library-search | P2 | accessibility | Result group counts are neutral badges with low contrast and no meaning of cap | REFUTED |
| 05-tags | P2 | visual-representation | Merge chips wrap so the arrow sits beside the first chip with the target chip below | REVISED_TARGET |
| 05-tags | P1 | text-density | Merge dialog stacks about 11 text lines and 4 text blocks before the primary button | REFUTED |
| 05-tags | P2 | text-density | Row repeats an identical tag icon and a 'cards' suffix 16 times | REFUTED |
| 05-tags | P2 | visual-representation | Card count is plain subtitle text, not a comparable figure | REFUTED |
| 05-tags | P2 | consistency | Dialog button layout differs between merge and delete | REFUTED |
| 05-tags | P2 | accessibility | Delete button label contrast and weight is low against its tinted fill | REFUTED |
| 05-tags | P2 | interaction | A→Z header label is static text beside a counter, looks like a control | REFUTED |
| 05-tags | P2 | text-density | Sheet repeats the tag count three times and the hint text is long for a three-row menu | REFUTED |
| 05-tags | P2 | interaction | Row tap and three-dot button open the same sheet, so the three-dot is redundant | REFUTED |
| 05-tags | P3 | consistency | Detail file States table has a read error row with no golden, but goldens exist | NOT_VERIFIED |
| 06-trash | P1 | text-density | Retention note takes 4 lines and ~27% of the first screen above the list | REFUTED |
| 06-trash | P1 | text-density | Each row carries three text lines plus the kind and age repeated per entry | REFUTED |
| 06-trash | P1 | visual-representation | Time left (the deadline) is shown as small muted text and, for most rows, not distinguishable by urgency | REFUTED |
| 06-trash | P2 | accessibility | Warning badge relies on colour and low-contrast tint only; muted days-left text is small and grey | REFUTED |
| 06-trash | P2 | text-density | Selection mode hides filters and leaves a 2-line instruction block plus a count header repeating the app bar | REFUTED |
| 06-trash | P2 | interaction | Row tap and ⋮ both open the same actions sheet; per-row ⋮ is an extra target next to a tappable row | REFUTED |
| 07-card-list | P2 | visual-representation | Card stage shown only as coloured uppercase word | REVISED_TARGET |
| 07-card-list | P2 | interaction | Tags filter chip clipped at the right edge with no scroll cue | REVISED_TARGET |
| 07-card-list | P2 | accessibility | Flag is an unlabelled outline glyph and shifts the badge position | REVISED_TARGET |
| 07-card-list | P1 | text-density | Each row repeats card state: status word plus due badge, 'NEW' twice | REFUTED |
| 07-card-list | P1 | hierarchy | Add FAB sits on the Due today badge and third row | REFUTED |
| 07-card-list | P2 | text-density | Summary card repeats due and mastered counts, 3x due above first row | REFUTED |
| 07-card-list | P2 | accessibility | Select all button measures 40 dp high | REFUTED |
| 07-card-list | P2 | consistency | Checkbox leaves a gutter and shifts text on entering selection | REFUTED |
| 08-card-create | P1 | accessibility | Add tag button and tag chips are about 31 dp tall, under the 48 dp touch floor | REFUTED |
| 08-card-create | P2 | text-density | Title 'New card' shown twice within 140 px of vertical space | REFUTED |
| 08-card-create | P2 | interaction | Tag entry takes three steps and a second label | REFUTED |
| 08-card-create | P2 | text-density | Error message is squeezed into about 65 percent of the row by the counter, wrapping to 3 lines | REFUTED |
| 08-card-create | P2 | hierarchy | 'Required' accent colour equals the interactive accent used for Add details | REFUTED |
| 08-card-create | P2 | accessibility | Disabled Save card has low contrast and its reason is a small caption under the button | REFUTED |
| 08-card-create | P2 | text-density | Add details row wraps its field list to two lines inside a 59 dp box | REFUTED |
| 09-card-edit | P2 | consistency | Tags header and count differ from the field pattern | REVISED_TARGET |
| 09-card-edit | P2 | visual-representation | Status, answers, lapses and due date shown as one dot-separated sentence | REVISED_TARGET* |
| 09-card-edit | P1 | accessibility | Add tag and Move to Trash buttons are under 48 dp | REFUTED |
| 09-card-edit | P1 | interaction | History-summary chevron closes the editor; unsaved-edit handling is unverified | REFUTED |
| 09-card-edit | P2 | interaction | Disabled Save in the loaded state gives no reason | REFUTED |
| 09-card-edit | P2 | hierarchy | Fixed non-editable history card pushes the term field down | REFUTED |
| 09-card-edit | P2 | text-density | Optional details always open: 'optional' repeated four times, versus collapsed on create | REFUTED |
| 09-card-edit | P2 | text-density | Breadcrumb tail 'Edit' repeats the app-bar title | REFUTED |
| 09-card-edit | P2 | text-density | Trash explanation is long and repeated in the dialog | REFUTED |
| 10-card-detail | P1 | hierarchy | Due date wraps to two lines and is not the lead figure | REVISED_TARGET |
| 10-card-detail | P2 | text-density | Box position stated three times in the schedule | REFUTED |
| 10-card-detail | P2 | text-density | Repeated 'Review' kind line and mode/hint/next-due lines in every history card | REFUTED |
| 10-card-detail | P2 | accessibility | Outcome colour carried by text colour and rail ring across lapse/success with small ring | REFUTED |
| 10-card-detail | P2 | text-density | Breadcrumb duplicates the app bar title | REFUTED |
| 11-card-import | P2 | consistency | Step number and 'Import' repeated across three header layers | REVISED_TARGET |
| 11-card-import | P1 | text-density | Source step stacks four text blocks around two choices | REFUTED |
| 11-card-import | P1 | hierarchy | About 57% of the Preview viewport is taken before the first data row | REFUTED |
| 11-card-import | P2 | visual-representation | Preview count badges wrap and orphan the fourth badge | REFUTED |
| 11-card-import | P2 | text-density | Mapping row is a three-line stack and the 'mapped for you' note is hidden under the footer | REFUTED |
| 11-card-import | P2 | text-density | Sectioned preview repeats deck name and card count between Decks block and groups | REFUTED |
| 12-card-export | P2 | text-density | Export content note is clipped below the fold in problem states and costs 3 lines in the default state | REFUTED |
| 12-card-export | P2 | text-density | Final-state problem copy repeats its own instruction in a 6-line banner while the sheet is a dead end behind a lone Close | REFUTED |
| 12-card-export | P2 | accessibility | Tone distinction between the danger and warning banners is carried mostly by colour; final stale state reads as a warning though nothing was exported | REFUTED |
| 12-card-export | P2 | hierarchy | Format choice shows jargon descriptions for a decision most users do not need to make | REFUTED |
| 12-card-export | P2 | consistency | Scope is stated twice with inconsistent wording between header title and sentence | REFUTED* |
| 13-study-home | P2 | consistency | Practice slot cropped in multi-deck goldens, so the common state is not seen | REVISED_TARGET |
| 13-study-home | P1 | text-density | Zero-count workload terms repeated on every deck row | REFUTED |
| 13-study-home | P1 | hierarchy | Two stacked cards compete before the deck list: Resume (hero) and Waiting for you | REFUTED |
| 13-study-home | P2 | visual-representation | Per-deck workload shown as three text terms where a compact count representation fits | REFUTED |
| 13-study-home | P2 | visual-representation | Resume card progress track is nearly invisible and unlabelled at 0 of 5 | REFUTED |
| 13-study-home | P2 | text-density | Due summary and its breakdown mix two colour meanings and wrap suffix into the last term | REFUTED |
| 13-study-home | P2 | accessibility | Workload colour coding: overdue amber and today primary distinguish without a glyph in the hero | REFUTED |
| 13-study-home | P2 | accessibility | Library button is a small control beside the section header (touch target not verified) | REFUTED |
| 14-study-entry | P1 | text-density | Learn row subtitle breaks into three dot-trailed fragments next to the button | REFUTED |
| 14-study-entry | P1 | hierarchy | Resume state pushes the Learn row under the footer | REFUTED |
| 14-study-entry | P1 | text-density | Eight-boxes mode list is cut by the footer and spends 2 to 3 lines per mode | REFUTED* |
| 14-study-entry | P2 | text-density | Breadcrumb repeats the deck name and is clipped on the left | REFUTED |
| 14-study-entry | P2 | visual-representation | Due count shown three times and the hero stat tiles carry little extra | REFUTED |
| 14-study-entry | P2 | accessibility | Learn button visual height is under 48 dp | REFUTED |
| 14-study-entry | P2 | accessibility | Unavailable mode reason and Not available badge are low-contrast grey on grey | REFUTED |
| 15-study-options | P2 | consistency | Detail file note text differs from the shipped copy | CONFIRMED |
| 15-study-options | P1 | text-density | Scope note takes 5 lines and ~127 dp before the first control | REFUTED |
| 15-study-options | P1 | hierarchy | Speech language row falls below the fold on the override and save-failed goldens | REFUTED |
| 15-study-options | P2 | interaction | Stepper stacked under its label wastes vertical space; buttons look about 32 dp | REFUTED |
| 15-study-options | P2 | text-density | 'Study options' shown twice, breadcrumb start clipped | REFUTED |
| 15-study-options | P2 | text-density | Hint lines under each option repeat static explanations | REFUTED* |
| 16-study-browse | P1 | hierarchy | Browse stage counter is 1/1 but context line says stage 1 of 3 | REFUTED |
| 16-study-browse | P1 | hierarchy | Term and meaning halves are equal-height with large empty areas, and the term does not outrank the meaning | REFUTED* |
| 16-study-browse | P1 | visual-representation | Looking-back state: only a small neutral badge marks that the card is not the live one, and the Next button is unchanged | REFUTED |
| 16-study-browse | P2 | accessibility | Context line is uppercased muted text at small size, with mixed case in one line | REFUTED |
| 16-study-browse | P2 | text-density | Footer hint repeats what the visible Next button and the swipe already say | REFUTED |
| 16-study-browse | P2 | consistency | Looking back loses the example line and shows the meaning at a different vertical position | REFUTED |
| 16a-study-self-assess | P1 | hierarchy | Answer card is a large empty recessed area while hidden and while revealed | REFUTED |
| 16a-study-self-assess | P2 | text-density | Footer hint repeats what the button or the card already says | REFUTED |
| 16a-study-self-assess | P2 | text-density | Mode pill, context line and face labels name the same thing the layout already shows | REFUTED |
| 16a-study-self-assess | P2 | visual-representation | Grade intervals are bare 'Nd' text with no shared visual encoding; three of four are nearly identical | REFUTED |
| 16a-study-self-assess | P2 | hierarchy | Again is distinguished by red tint plus a red border, while Hard, Good and Easy share one tone | REFUTED |
| 16a-study-self-assess | P2 | accessibility | Grade buttons are about 48 dp tall at the minimum, with 4 labels in a 360 dp row | REFUTED |
| 17-study-match | P1 | hierarchy | Idle term tiles have no visible container | REVISED_TARGET |
| 17-study-match | P2 | hierarchy | Meaning text is much smaller than term text | BLOCKED |
| 17-study-match | P2 | visual-representation | Matched pair is not visibly linked | REFUTED* |
| 17-study-match | P2 | interaction | Wrong-pair hint is shown for 600 ms only | REFUTED |
| 17-study-match | P2 | text-density | Persistent instruction line and ambiguous counter | REFUTED |
| 17-study-match | P2 | accessibility | Selected tile uses a solid indigo fill with no non-colour cue | REFUTED |
| 18-study-guess | P1 | hierarchy | Prompt card spends about 38 percent of height on a one-word question | REVISED_TARGET |
| 18-study-guess | P1 | hierarchy | Idle options have no row container, only a ring letter | REVISED_TARGET |
| 18-study-guess | P1 | hierarchy | Meaning text uses caption style for the primary answer content | REFUTED* |
| 18-study-guess | P2 | text-density | Three stacked meta lines above the question repeat the mode and round | REFUTED |
| 18-study-guess | P2 | text-density | Answered state changes the hint to a sentence that says what the colour already shows | REFUTED* |
| 18-study-guess | P2 | accessibility | Wrong answer: picked and correct rows both coloured, faded rows keep letter rings at reduced contrast | REFUTED |
| 19-study-recall | P2 | text-density | State is stated three times: clock caption, face tag and footer hint | REFUTED* |
| 19-study-recall | P2 | hierarchy | Turn clock is the least emphasised element despite being the mode's critical constraint | REFUTED |
| 19-study-recall | P2 | consistency | Two stacked linear tracks with different colour and meaning within ~230 px | REFUTED |
| 19-study-recall | P2 | accessibility | Forgot / Remembered buttons have very low fill contrast against the page | REFUTED |
| 19-study-recall | P2 | interaction | Revealed grading is two equal-weight buttons with identical style and no icon or colour cue | REFUTED |
| 20-study-fill | P2 | text-density | Footer hint restates what the state already shows | REVISED_TARGET |
| 20-study-fill | P2 | visual-representation | Typed vs correct term shown as two stacked words, not a character comparison | REVISED_TARGET |
| 20-study-fill | P1 | hierarchy | Two equal-height faces leave most of the viewport empty | REFUTED |
| 20-study-fill | P1 | accessibility | Answer field has weak affordance and a short visible height | REFUTED |
| 20-study-fill | P2 | text-density | Session identity is shown three times above the prompt | REFUTED |
| 20-study-fill | P2 | consistency | Wrong state uses two colours for one outcome | REFUTED |
| 21-session-summary | P1 | hierarchy | Wrong-turns figure outranks the headline count in a finished review | BLOCKED* |
| 21-session-summary | P2 | consistency | The same concept (cards reviewed) has two presentations in the hero | REFUTED |
| 21-session-summary | P2 | text-density | Facts card repeats equal values and a caption repeats on every state | REFUTED |
| 21-session-summary | P2 | visual-representation | Wrong turns shown only as a 'W of T' text pair | REFUTED |
| 22-progress | P2 | hierarchy | Streak is a full card with an inner tinted tile for a single figure | REVISED_TARGET* |
| 22-progress | P1 | visual-representation | Deck rows repeat a three-line text block with the same learning/reviewing split per row | REFUTED |
| 22-progress | P2 | accessibility | Learning and reviewing meaning carried by text colour only in rows, and amber text on light ground | REFUTED |
| 22-progress | P2 | text-density | Today card carries a verbose explanatory sentence in the figure's sub-line | REFUTED |
| 22-progress | P2 | hierarchy | Range tray detached from the figures it does not control; two ranges in one screen | REFUTED |
| 22-progress | P2 | text-density | Deck level repeats the deck name in app bar and breadcrumb | REFUTED |
| 22-progress | P2 | interaction | Chevron-only affordance and idle row differ from the total row at a glance | REFUTED |
| 23-settings | P2 | consistency | Doc height budget contradicts the golden for the signed-in hub | REVISED_TARGET |
| 23-settings | P1 | text-density | Reset scope is stated twice on the hub (row subtitle + note) and a third time in the dialog | REFUTED* |
| 23-settings | P2 | text-density | Study options summary wraps to 3 lines with a dangling separator dot | REFUTED |
| 23-settings | P2 | text-density | Account row subtitle is a constant sentence that makes the row 3 lines tall | REFUTED |
| 23-settings | P2 | hierarchy | Reset row has the same visual weight and tile colour as navigation rows | REFUTED |
| 23a-study-defaults | P2 | interaction | Invalid-limit state: error is colour plus icon plus text but the + button greys out with no stated reason; the row grows by about 33 dp | REVISED_TARGET |
| 23a-study-defaults | P1 | text-density | Footnotes and sub-lines carry about a third of the visible text, and the 'deck keeps its own' rule is said twice per section | REFUTED |
| 23a-study-defaults | P2 | hierarchy | Speech language row is a three-part wrapped sub-line, so the current value has no stand-alone line | REFUTED |
| 23a-study-defaults | P2 | visual-representation | Cards row: unit is split across label and sub-line, and the stepper value has no unit beside it | REFUTED |
| 23a-study-defaults | P2 | consistency | Golden study_options_defaults_{light,dark}.png is not listed in the States table or the Goldens line | REFUTED |
| 23b-admin | P2 | text-density | SQL log row hint wraps to 5 lines beside the toggle | CONFIRMED |
| 23b-admin | P2 | accessibility | Disabled-and-off toggle while value unread carries meaning by colour alone | REVISED_TARGET |
| 23b-admin | P2 | hierarchy | Toggle row is visually inconsistent with navigation rows and its state has no text label | REFUTED |
| 24-daily-reminder | P1 | text-density | Preview section: 5-line text block with the never-carries disclaimer repeated on every view | REFUTED |
| 24-daily-reminder | P1 | text-density | Static explanatory copy appears three times above the fold | REFUTED |
| 24-daily-reminder | P1 | hierarchy | Perm-denied banner stacks two buttons vertically, 4 text lines plus 2 buttons before the primary action | REFUTED |
| 24-daily-reminder | P2 | visual-representation | Disabled Time row is shown with a live-looking 20:00 and a hint that restates state | REFUTED |
| 24-daily-reminder | P2 | accessibility | Time button target and disabled contrast | REFUTED |
| 25-theme | P2 | text-density | Hint line restates the name on two of three cards | REFUTED |
| 25-theme | P2 | text-density | Footnote repeats a behaviour the control already shows | REFUTED |
| 25-theme | P2 | accessibility | Selected state is the ring plus a check only on the name row, no text or semantic difference sighted users can read at a glance | REFUTED |
| 25-theme | P2 | consistency | Theme choice is cards here, rows on the sibling choice screen | REFUTED |
| 26-language | P2 | text-density | Static 3-line note repeats what the toast and instant radio change already show | REFUTED |
| 26-language | P2 | consistency | Row heights differ because only some rows carry a sub-line | REFUTED |
| 27-sync | P2 | text-density | Permanent note restates the failure sentence and the Waiting row | REVISED_TARGET |
| 27-sync | P1 | accessibility | Banner action buttons are about 39 dp, below 48 dp | REFUTED |
| 27-sync | P1 | hierarchy | Two retry-like buttons in the rejected state | REFUTED |
| 27-sync | P2 | visual-representation | Sync state shown only as two text rows; icon appears in one state | REFUTED |
| 27-sync | P2 | consistency | Read-error body borrows a Library string | REFUTED* |
| 28-monitoring | P1 | text-density | Detail: message and error type repeat across three cards, each with its own label and frame | REVISED_TARGET |
| 28-monitoring | P1 | text-density | Not sent tab: the SQL-log switch, a note and a filter sit above the first log row | REFUTED |
| 28-monitoring | P1 | interaction | Filter chip row: five chips in one scroller; the third is cut off at the right edge with nothing marking the rest | REFUTED* |
| 28-monitoring | P2 | hierarchy | Detail: Open/Fixed status is a pill at the far edge, while the level glyph and the time both sit in a head row | REFUTED |
| 28-monitoring | P2 | accessibility | List row: time and status badge are separated from the level and lack a text-less cue for level | REFUTED |
| 28-monitoring | P2 | text-density | Level and status are stated 3 times in the list header region | REFUTED |
| 29-welcome | P2 | text-density | First benefit wraps to two lines, the second does not | CONFIRMED |
| 29-welcome | P2 | interaction | Benefit rows are drawn as settings rows, though they are not tappable | REFUTED |
| 30-sign-in | P2 | text-density | Reauth repeats the account email and the 'signed out' message above the form | REFUTED |
| 30-sign-in | P2 | hierarchy | Destructive 'Continue without this account' is styled as a bare text button | REFUTED |
| 30-sign-in | P2 | hierarchy | Body ends at about 30% of the viewport; the gap above the footer is empty | REFUTED |
| 31-code | P2 | hierarchy | Resend countdown shown only as a small caption in the middle, away from the field and visually weaker than the secondary hint | REFUTED |
| 31-code | P2 | visual-representation | Countdown is plain text; a time-limited wait with a known 60 s span carries no progress cue | REFUTED |
| 31-code | P2 | text-density | Three secondary text blocks under the field compete: countdown, spam hint, Use another email | REFUTED |
| 31-code | P2 | accessibility | Error state: colour and icon plus border signal the error, but message sits tight under the slots and the field clears | REFUTED |
| 31-code | P2 | interaction | Back and Use another email do the same thing, two controls for one action | REFUTED |
| 31-code | P2 | hierarchy | Unverified states lack goldens: verifying, resend ready, resending, resend failed | REFUTED* |
| 32-account | P2 | text-density | Every command row carries a wrapping two-line subtitle; 6 of 9 body text lines are explanatory | REFUTED |
| 32-account | P2 | hierarchy | Section caption 'DELETE' and 'THIS PHONE' wrap three rows into three single-row groups | REFUTED |
| 32-account | P2 | hierarchy | Reauth banner puts the fix below a 2-line message and leaves the account section looking intact | REFUTED |
| 32-account | P2 | accessibility | Sign-out loss dialog: destructive confirm is a tinted pale fill, low contrast against its white card | REFUTED |
| 33-users | P1 | text-density | Email, the identifying field, is truncated while the identical date line repeats on every row | REVISED_TARGET |
| 33-users | P1 | interaction | No row signals that it is tappable; the one non-tappable row looks identical to the rest | REFUTED |
| 33-users | P2 | text-density | Person tile repeats on all rows and carries no information | REFUTED |
| 33-users | P2 | visual-representation | Role shown only as a small badge; Admin vs User is the one comparison the admin scans for | REFUTED |
| 33-users | P2 | text-density | Search field is the only search affordance and its 'ACCOUNTS' overline duplicates the app bar meaning | REFUTED |
| 33-users | P2 | hierarchy | Role sheet refused: warning banner reads as a dead end while Save stays fully enabled | REFUTED |
| 34-topik-home | P2 | consistency | Skeleton is not the loaded layout's twin (documented, still open) | REVISED_TARGET |
| 34-topik-home | P1 | text-density | Meta line repeats the same section pair and wraps to a second line on both rows | REFUTED |
| 34-topik-home | P2 | visual-representation | Test count is plain text inside a muted meta sentence, not a figure | REFUTED |
| 34-topik-home | P2 | accessibility | No-tests rows look identical to tappable rows apart from a missing chevron | REFUTED |
| 35-topik-test-list | P1 | text-density | Header card spends about 128 dp on a count, a static sentence and the sort before the first test | REFUTED |
| 35-topik-test-list | P1 | text-density | First row's status wraps and leaves a dangling separator, making it 4 lines tall | REFUTED |
| 35-topik-test-list | P1 | hierarchy | Status is plain muted text, same weight and colour as the content tags | REFUTED* |
| 35-topik-test-list | P2 | visual-representation | Status and best score are text that a semantic status icon plus score would carry faster | REFUTED |
| 35-topik-test-list | P2 | accessibility | Round badge is the only leading element and reads '#96' in neutral grey on grey, low contrast | REFUTED |
| 36-topik-test-detail | P1 | text-density | History row: three-line text metadata run plus separate action row; row height ~190 dp makes 4 attempts fill a screen | REFUTED |
| 36-topik-test-detail | P1 | hierarchy | Score is not the emphasized figure in attempt rows; it is body text in a metadata run | REFUTED* |
| 36-topik-test-detail | P2 | visual-representation | Score across attempts is text-only; trend/sparkline fits the data (owner already scheduled a separate chart spec) | REFUTED |
| 36-topik-test-detail | P2 | hierarchy | Six equal-weight stat tiles: no emphasis among Accuracy/Best/Average/Sessions/Completed, and Sessions and Completed partly duplicate History | REFUTED |
| 36-topik-test-detail | P2 | interaction | FAB overlaps list content and sits over row actions at scroll end | REFUTED |
| 36-topik-test-detail | P2 | interaction | History actions: three visible outline buttons of equal weight per row, and Summary vs Review ambiguous | REFUTED |
| 36-topik-test-detail | P2 | accessibility | Status badge colour and neutral gray 'In progress' badge are low-contrast; status duplicated in Recent as plain text | REFUTED |
| 37-topik-attempt | P1 | interaction | Unselected options have no edge or ground, so they read as plain text | CONFIRMED |
| 37-topik-attempt | P1 | accessibility | Seek-bar inactive track is invisible on the recessed pane | REVISED_TARGET |
| 37-topik-attempt | P1 | visual-representation | No answered/remaining figure outside the grid sheet | REFUTED* |
| 37-topik-attempt | P2 | text-density | Audio bar uses two rows and the pane spends 240 dp before the question | REFUTED |
| 37-topik-attempt | P2 | text-density | 'Questions' appears as footer button and grid title; PRACTICE chip is constant | REFUTED |
| 38-topik-summary | P1 | hierarchy | By-type breakdown (the actionable weakness) sits after the 50-row answer list | REVISED_TARGET* |
| 38-topik-summary | P1 | text-density | Two parallel stat blocks: donut plus 2x2 tile card consume ~1.1 viewports before the chart | REFUTED |
| 38-topik-summary | P1 | text-density | Answer-row meta wraps into a dangling separator and repeats status twice | REFUTED |
| 38-topik-summary | P2 | visual-representation | Answered / Unanswered tiles duplicate the filter-chip counts; Wrong count has no stat | REFUTED |
| 38-topik-summary | P2 | visual-representation | Time chart: only ~7 of 50 bars visible, no scale or comparison reference | REFUTED* |
| 38-topik-summary | P2 | accessibility | Chart status glyph row adds a second line of marks that repeats the bar colour and the legend | REFUTED |
| 38-topik-summary | P2 | interaction | Filter chip row is cut at 360 dp and its 4th chip (Correct) is unreadable | REFUTED |
| 38-topik-summary | P2 | consistency | Uppercase section labels differ from the card title weight; 'Answers' header does not label the chart it sits above | REFUTED |
| 39-topik-review | P1 | accessibility | Right and wrong are colour and edge only, no glyph | REVISED_TARGET |
| 39-topik-review | P2 | interaction | Player controls row is unlabelled and loose: play icon beside an empty circle, 'Hide script' as a separate text row | REVISED_TARGET |
| 39-topik-review | P1 | hierarchy | Listening review: material takes about half the viewport and pushes the answer and explanation below the fold | REFUTED |
| 39-topik-review | P2 | visual-representation | Result stated again as a grey text line under the options | REFUTED |
| 39-topik-review | P2 | hierarchy | Filter chips are cut at the right edge, hiding the Correct chip and the Unanswered count context | REFUTED |
| 39-topik-review | P2 | consistency | Explanation panel visually detached and same weight as the stem: section header in small caps, content in outlined box | REFUTED |
