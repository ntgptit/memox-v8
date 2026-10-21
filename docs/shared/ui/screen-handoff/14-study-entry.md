<!-- Hand-written screen record. -->

# 14 · Study entry

The Study Entry of an open deck (FE-A6, FE-A7): `StudyEntryScreen`, the choice
between Learn and Review before a session opens. UC-STUDY-001, UC-STUDY-003.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back, deck name (composed by `app/` from the deck feature, FE-A6 spec D16), and the trailing "Study options" icon, which opens screen 15 (FE-A3 D3). |
| Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck. |
| Hero | `MxCard` (plain, not a hero card: a summary, not a door) + `MxStatTile` × 2 (FE-A6 spec D17) | The overline names the algorithm alone ("EIGHT BOXES", "SM-2"); a plain line under it reads "Up to {n} cards per session" (BR-STUDY-024), so no word is left alone on a wrapped line (critique 2026-09-30 part 3c-1, R5); two stat tiles, New and Due, boxed on the Muted Fill so they read as boxes on the plain card (DEV-231): Due above zero in primary, New above zero muted, a zero in plain text colour (BR-STUDY-047, BR-STUDY-051 — the two sets never merge); "{n} of the due cards are overdue" note, in the warning text, when any are overdue. |
| Resume banner | `MxCard` | "Session from today" overline with a static primary dot (`MxDotOverline`), "Session in another deck" when the session is another deck's (owner 2026-10-21), "{kind} · {mode} · {done} / {total} cards" (as screen 13, owner 2026-10-20), "Continue where you stopped.", "Continue" (`MxButton`, primary block). Shown for the app's open, same-day session (BR-STUDY-072, BR-STUDY-075), of this deck or another: on another deck's session it names that deck first by its whole path from its root, "{root} › … › {deck}" (`StudyDeckPathWidget`, shared with 13; owner 2026-10-21): two lines at most; when it does not fit, the deck and as many levels nearest it as fit stay, the levels above them give way to "…", and the root stays before the "…" only while there is room ("… › {parent} › {deck}", "{root} › … › {deck}", then "… › {deck}"); a deck name longer than two lines starts the first line after "…" and only its own end is cut; each "›" glued to the deck after it so no line ends on it (spec 2026-10-20 B1); read whole, deck first ("{deck}, in {parent}, in {root}"); the deck alone on a root (`itemTitle`), and Continue opens that session (owner 2026-10-21). |
| Other sessions | `MxListSectionHeader` + `MxNote` | While the Resume banner shows and the footer offers a start: "Or start another session" and the note "Starting one ends today's session. Its answers are kept." (spec 2026-10-20 E1, BR-STUDY-072), under the banner and any refused or failed banner, over the Learn row and the review options. |
| Nothing-due state | `MxEmptyState` (compact, success tone) | From the data (BR-STUDY-008, BR-STUDY-054; owner 2026-10-21): with cards that all rest, "Nothing to study in this deck" · "Every card is learned and resting. Cards cannot be reviewed before they are due."; with no card in the deck or its sub-decks, "No cards yet" · "Add or import cards to study them here." The title names this deck, so it never reads against another deck's Continue above it. The success tone stays on the empty deck too (owner 2026-10-21: colour is not changed here). |
| Learn row | full-bleed `MxCard` of one `MxListRow` | "Learn new cards", subtitle "{stage description} · {n} of {n} new · in creation order" (BR-STUDY-056, BR-STUDY-057); trailing small `MxButton` "Learn" starts a `learning` session directly (BR-STUDY-051) while a review leads the footer; with only new cards the footer offers Learn and the row has no button (critique 2026-09-30 part 3d-1, D2). |
| Review options | `MxListSectionHeader` (overline) + full-bleed `MxCard` of `MxOptionRow`s + `MxNote` | Eight boxes: Match · Guess · Recall · Fill, each with its own `MxBadge` "{n} cards" or "Not available" plus the unavailable reason as the row's subtitle (BR-STUDY-044, BR-STUDY-045, BR-MODE-009); a single available mode skips this list and opens directly (BR-STUDY-055). SM-2 has one mode, so this list never appears for it — see the Direction sheet. |
| Inline banners | `MxInlineBanner` | `refused` (warning): counts changed since the screen opened. `startFailed` (danger): the write failed; nothing was saved (BR-STUDY-018). The banner sits under the hero (and the resume banner), above the choices, so it is never below the fold; the body's 16 block gaps space it (`hasBottomMargin: false`; spacing spec 2026-10-20). |
| Footer | `MxFooterBar` | A caption line plus one block `MxButton` (primary; outline while the resume banner shows, "Try again" included, since Continue is then the one primary, critique 2026-09-30 part 1): "Learn {n} new cards" / "Review {n} due cards" / "Continue" / "Start a new review instead" / "Try again"; `MxSpinner` + "Starting…" while a session opens, and the button plus every option lock (BR-STUDY-004). Beside the Resume banner the caption leads with "Ends today's session" (spec E1). |

## Direction sheet (SM-2 only)

Tapping the footer's Review action on an SM-2 root deck opens `MxBottomSheet`
with a header and three `MxOptionRow`s — Term first (recommended, selected by
default), Meaning first, Mixed — each with a one-line description, an
`MxNote` above them that leads with the lock ("The direction can't change once the session starts.", BR-MODE-017; critique 2026-09-30 part 3c-1), and
`MxSheetActions.custom` with a single "Start review" button that locks the
sheet while the session opens (BR-STUDY-004). Closing the sheet without
choosing "Start review" writes nothing (BR-STUDY-020).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| sm2 | `study_entry_sm2_light.png` | `study_entry_sm2_dark.png` | The hero and counts; the direction is chosen in the Direction sheet (see Rulings). |
| eightBox | `study_entry_eight_box_light.png` | `study_entry_eight_box_dark.png` | The mode list is inline here (BR-STUDY-055, UC-STUDY-001 step 4). |
| onlyNew | `study_entry_only_new_light.png` | `study_entry_only_new_dark.png` | Due = 0, only the Learn row and its footer CTA show. |
| nothing | `study_entry_nothing_light.png` | `study_entry_nothing_dark.png` | Positive empty state, no footer (BR-STUDY-008, BR-STUDY-054): the deck has cards and every one rests, "Nothing to study in this deck" · "Every card is learned and resting…" (owner 2026-10-21). VERIFIED `study_entry_screen_test.dart::nothing new and nothing due is the calm empty state, and it follows the cards: …` |
| nothingEmpty | `study_entry_nothing_empty_deck_light.png` | `study_entry_nothing_empty_deck_dark.png` | The deck and its sub-decks hold no live card: "No cards yet" · "Add or import cards to study them here.", no footer (owner 2026-10-21). Reached when an emptied deck's entry is open or opened. VERIFIED same test |
| nothing beside another deck's session | `study_entry_nothing_other_deck_session_light.png` | `study_entry_nothing_other_deck_session_dark.png` | The hero at 0 and 0, the resume banner with the session's path and Continue, the only button and the one primary, then the positive empty state ("Nothing to study in this deck", as on any caught-up deck); no section over starts, no footer, since nothing can start here (owner 2026-10-21). VERIFIED `study_entry_other_deck_test.dart::a caught-up deck beside another deck's session: the banner, Continue alone, then nothing to study in this deck`. |
| resume | `study_entry_resume_light.png`, `study_entry_resume_eight_box_light.png` (Eight boxes, scrolled to the end), `study_entry_resume_other_deck_light.png` (the root beside its sub-deck's session), `study_entry_resume_deep_deck_light.png` (the root beside a session four levels down: the farther levels give way to "…", the root kept while there is room) | `study_entry_resume_dark.png`, `study_entry_resume_eight_box_dark.png`, `study_entry_resume_other_deck_dark.png`, `study_entry_resume_deep_deck_dark.png` | The Continue banner with a primary, static dot and its progress track (see Rulings); the other starts under "Or start another session" and its note; the footer's start is outline, its caption led by "Ends today's session" (critique 2026-09-30 part 1, spec E1). VERIFIED `study_entry_actions_test.dart::today's open session shows the resume banner; …`, `::resume with only new cards keeps one primary`, `::eight boxes beside an open session: the caption leads with what the start ends (spec E1)`. On SM-2 with due cards alone the body has no choice, so the section stays away and the caption alone says it: VERIFIED `::SM-2 with due cards alone beside an open session: no empty section; …`. Another deck's name longer than two lines leads after "…" and ends in an ellipsis, never ending a line on "›", at 1.0 and 1.3, and a session on another root names its deck alone: VERIFIED `study_entry_other_deck_test.dart::a deck name longer than two lines leads after "…" …`, `::a session on another root names that deck alone`. |
| directionSheet | `study_entry_direction_sheet_light.png` | `study_entry_direction_sheet_dark.png` | The sheet the footer's Review opens on `sm2`: Term first is chosen at first, with "Start review" (UC-STUDY-003; see Rulings). `study_entry_actions_test.dart::Review opens the direction sheet, Term first chosen; Start review opens the review in the direction picked (UC-STUDY-003)`. |
| starting | `study_entry_starting_light.png` | `study_entry_starting_dark.png` | Footer shows the spinner, every option locks (BR-STUDY-004). |
| refused | `study_entry_refused_light.png` | `study_entry_refused_dark.png` | Inline warning banner; the footer stays usable (plan R5). |
| startFailed | `study_entry_start_failed_light.png` | `study_entry_start_failed_dark.png` | Inline danger banner, footer offers "Try again". |
| loading | `study_entry_loading_light.png` | `study_entry_loading_dark.png` | Skeletons in the hero and option-list shapes. |
| error | none | none | `MxErrorState` with Retry (`studyEntryErrorTitle`, `studyEntryErrorBody`) under the breadcrumb; no footer. Code read: `study_entry_body_widget.dart`; VERIFIED without a golden by `study_entry_screen_test.dart::a read that fails says so and Retry reads again (UC-STUDY-001)`. |
| deckGone | none | none | Not a frame: the deck was deleted while the entry was open, so the screen shows the toast "This deck no longer exists" and pops (UC-STUDY-001 E1). VERIFIED `study_entry_screen_test.dart::a deck deleted while its entry is open leaves with a message (UC-STUDY-001 E1)`. |

Every state above is built.

**Built (FE-A6 P2):** all nine states on `sm2`. Learn (the row's button
and, with nothing due, the footer) opens a learning session; the footer's Review
opens the Direction sheet, then the review; Continue takes up today's session.
While a session opens, the footer spins with "Starting…" in its caption and the
Learn button and Continue lock (BR-STUDY-004); a refusal shows the warning
banner and a failed write the danger banner, whose footer is "Try again"
(repeating the same start, direction included). `eight_box` reviews in any mode its
cards can run (FE-A6 P3; Recall and Fill since P4): the available rows are a pick, the
first available one picked at first, and the footer reviews the picked mode with the
caption "{mode} · oldest first" (the button states the count; critique 2026-09-30 part 3b, R5). Every mode has its screen since P4, so
Learn is offered whenever new cards exist and nothing says "Coming soon". A deck deleted while its entry is open leaves with
the toast "This deck no longer exists" (UC-STUDY-001 E1). Goldens:
`test/features/study/presentation/goldens/study_entry_{eight_box,sm2,only_new,nothing,loading,resume,starting,refused,start_failed,direction_sheet}_*`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the read lands | sm2 / eightBox / onlyNew / nothing / resume, by the counts and the open session | VERIFIED per state in `study_entry_screen_test.dart` (e.g. `::nothing new and nothing due is the calm empty state (BR-STUDY-008)`); the skeleton is `::loading draws the hero and the option list as skeletons (kit loading)` |
| loading | the read fails | error | VERIFIED `::a read that fails says so and Retry reads again (UC-STUDY-001)` |
| error | Retry | loading, then the state the read gives | the read runs again: VERIFIED in the test above; the landing after Retry is `UNVERIFIED (code read)`: `StudyEntryBodyWidget._retry` invalidates `studyEntryProvider` |
| any loaded state | the stream errors after data was shown | error: the body and the footer are replaced | `UNVERIFIED (code read)`: the `AsyncError` branch of `study_entry_body_widget.dart`; the footer is built only for `AsyncData(Ok)` |
| any loaded state | the deck is deleted (a `notFound` read) | deckGone: toast, then pop, once | VERIFIED `::a deck deleted while its entry is open leaves with a message (UC-STUDY-001 E1)`; the `isCurrent` guard that keeps a later emission from a second toast is `UNVERIFIED (code read)` |
| any loaded state | tap the Study options icon | screen 15 | VERIFIED `::the app bar's Study options icon opens the deck's options (FE-A3 D3, kit 14)` |
| sm2 / eightBox / onlyNew | tap Learn (the row's button, or the footer when only new cards exist) | starting, then the learning session opens | VERIFIED `study_entry_actions_test.dart::Learn on the row opens a learning session (BR-STUDY-051)`, `::with only new cards the footer is "Learn 2 new cards" with the nothing-due caption (kit onlyNew)` |
| sm2 | tap Review | directionSheet | VERIFIED `::Review opens the direction sheet, Term first chosen; Start review opens the review in the direction picked (UC-STUDY-003)` |
| directionSheet | Start review | starting, then the review session opens in that direction | VERIFIED same test |
| directionSheet | close without Start review | back on the entry, nothing written | VERIFIED `::closing the sheet without Start review writes nothing (BR-STUDY-020)` |
| eightBox | pick a mode row | the footer follows the pick; no sheet; the pick is not kept | VERIFIED `::eight_box: Match is picked at first; picking Guess moves the footer, which opens a Guess review with no sheet (E1)` |
| resume | tap Continue | starting, then today's session opens | VERIFIED `::today's open session shows the resume banner; Continue opens it, and the footer offers a new review instead (kit resume)` |
| resume (another deck's session) | tap Continue | starting, then that session opens | owner 2026-10-21, BR-STUDY-072. VERIFIED `study_entry_other_deck_test.dart::an open session of another deck shows on this entry with its deck and says what a start would end; …`; that the entry wrote nothing before (still `in_progress`) is asserted in the same test |
| nothing beside another deck's session | tap Continue | starting, then that session opens | owner 2026-10-21. `UNVERIFIED (code read)`: the banner and its Continue are the widgets the row above VERIFIES; no test taps Continue in this state |
| nothing | the last card leaves the deck while the entry is open | nothingEmpty | owner 2026-10-21. VERIFIED for the Trash, `study_entry_screen_test.dart::nothing new and nothing due is the calm empty state, and it follows the cards: …`; a move or a pull reaches the same read (`watchDeckRow` re-reads on `card`), `UNVERIFIED (code read)` |
| nothingEmpty | a card arrives (added in another tab, restored, pulled) | onlyNew (or sm2 / eightBox by the counts) | VERIFIED for a new card in the same test |
| resume (another deck's session), or nothing beside it | another deck's session ends or opens while the entry shows | the banner and the title follow: without a session the entry is its plain state again (the banner goes; the nothing state stays as it is) | `watchDeckRow` re-reads on every `study_session` and `study_queue_items` write; the path follows a rename, VERIFIED `watch_entry_test.dart::the open session's path follows a rename of its ancestor`; the screen's switch is `UNVERIFIED (code read)`, `study_entry_body_widget.dart` |
| resume (another deck's session) | start Review or Learn here | starting; that session ends `abandoned / user_exit`, its answers kept, after the note and the caption said so | BR-STUDY-072. VERIFIED `study_entry_other_deck_test.dart::a start beside another deck's open session ends it, its answers kept, as BR-STUDY-072 rules` |
| resume | tap Learn on the row, pick a mode and start, or "Start a new review instead" | starting; the start ends today's session (its answers kept) and the new session opens; the note and the caption say so beforehand | BR-STUDY-072, spec E1. The start is VERIFIED as on the rows above (`study_entry_actions_test.dart::a failed start beside an open session keeps one primary …` starts Learn beside a session); the section, the note and the caption are VERIFIED `::today's open session shows the resume banner; …`, `::resume with only new cards keeps one primary`, `::eight boxes beside an open session: …`; that the old session ends `abandoned / user_exit` is VERIFIED `study_entry_other_deck_test.dart::a start beside another deck's open session ends it, its answers kept, as BR-STUDY-072 rules` |
| resume | tap Continue on a session that ended meanwhile | refused (warning banner "That session can't be continued.") | the controller's refusal is VERIFIED `study_entry_controller_test.dart::Continue on a session that ended meanwhile is refused`; the banner copy for this reason is `UNVERIFIED (code read)` (`study_entry_banner_widget.dart` default branch) |
| starting | a second tap on Learn, Review or Continue | dropped; every option and the footer are locked | VERIFIED `study_entry_controller_test.dart::a second start while one runs is dropped (BR-STUDY-004)`; `study_entry_actions_test.dart::while a session opens every action is locked and the footer says Starting… (BR-STUDY-004, kit starting)`, `::while a start runs the review rows keep their pick (E1, BR-STUDY-004)` |
| refused / startFailed | the banner is drawn | it reads under the hero (and the Resume banner), above the choices and the "Or start another session" section, where the footer's Try again points | VERIFIED `study_entry_actions_test.dart::a failed start says so and Try again starts it again (screen 14 startFailed)` (the title sits above `StudyEntryLearnWidget`) |
| starting | the cards changed meanwhile (nothing due, nothing to learn, mode unavailable or not offered, deck or session gone) | refused: warning banner, footer rebuilt from the new counts | VERIFIED `study_entry_actions_test.dart::a start the counts no longer allow is refused with the warning banner; the footer follows the new counts`; `study_entry_banner_test.dart::self-assess no longer offered says the review algorithm changed, not that the session ended (UC-STUDY-003 E1)` |
| starting | the write fails, or any other refusal | startFailed: danger banner under the hero, above the choices; the footer is "Try again" | VERIFIED `study_entry_actions_test.dart::a failed start says so and Try again starts it again (screen 14 startFailed)`, `::a failed start beside an open session keeps one primary (final review, critique 2026-09-30 part 1)`; the banner's place above the first choice (the Learn row) is asserted in the first of them (audit 2026-10-17) |
| starting | the start meets a bug (not a `Failure`) | startFailed, the same danger banner and Try again (with the same start) as a `Failure`; nothing is starting any more; the bug is reported | VERIFIED `study_held_bug_test.dart::a start that dies on a bug ends failed with Try again, as a Failure does (start)` |
| startFailed | tap Try again | starting with the same start (direction included) | VERIFIED same test (`study_entry_controller.dart` `retry`) |
| starting | Back, so the screen is gone before the start answers | no navigation to the session | `UNVERIFIED (code read)`: the controller returns null on `!ref.mounted` and `_open` checks `context.mounted`; nothing is rolled back if the write already landed, and Continue on 14 or Resume on 13 takes that session up |

## Accessibility

- The app bar's `titleWidget` is the deck header and the screen sets `isTitleWidgetRouteName: true`, so the deck header names the route for TalkBack (`study_entry_screen.dart`). `UNVERIFIED (code read)`: no test reads the route's semantics name.
- TalkBack reads the app bar, the breadcrumb, the hero (overline, then "New: {n}", "Due: {n}" — each stat tile is one node), the overdue note, then the rows and the footer. The resume banner's dot is decorative; on another deck's session its path is read whole, deck first ("{deck}, in {parent}, in {root}"), without the › glyph or the "…" (`study_deck_path_test.dart`).
- Single-line text that ellipsizes keeps line-height 1.5 for stacked marks (UI-base §9 row 102). Touch targets are at least 48 × 48.
- While a session opens, the locked footer and options stay in the reading order and read as disabled.

## Rulings

- **UC-STUDY-003:** SM-2's direction is chosen in a separate `MxBottomSheet` opened by the footer's Review action (three choices, then "Start review"), never inline; the space above the pinned footer stays empty.
- **UI-base row 28, FE-A8 ruling S3:** the resume dot is primary and static, as on 13.
- **FE-A8 H2:** the resume banner carries a `MxLinearProgress` track under its line.
- **Plan R5:** on `refused` the footer is rebuilt from the up-to-date counts and stays usable; the banner stays until the next start.
- **Plan R6:** while starting, the button spins (`MxButton.isLoading`) and "Starting…" is the footer's caption.
- **Plan R7:** "Start review" answers the choice and closes the sheet; the entry footer shows `starting`, and Try again repeats the review with the same direction.
- **Plan R8:** the SM-2 caption reads "{shown} of {due} due · oldest first".
- **Plan R9:** each refusal has its own title: nothing due, no new cards, a mode that no longer runs, a session that can no longer be continued.
- **Critique 2026-09-30 part 1:** while an open session shows, "Continue" is the one primary and the footer's start (Review instead or Learn) is outline, since it ends that session (DESIGN.md One Indigo).
- **Owner 2026-10-21 (BR-STUDY-072):** the entry reads the app's open session, not this deck's only: a start here ends it wherever it was opened, so its banner shows on every deck's entry, names the session's deck by its whole path when it is another's (the shared widget of 13's Resume title), and Continue opens that session. Looking at or moving between entries writes nothing (BR-STUDY-075).
- **Owner 2026-10-21 (hierarchy):** the banner leads with the session and its progress ("{kind} · {mode} · {done} / {total} cards", `sectionTitle`); the deck path above it is its context (`itemTitle`). Screen 13 leads with the path instead. Both draw it with `StudyDeckPathWidget`, which takes the role the screen gives it and fits the path in that style, so the order is a screen's choice and the path's logic is one.
- **Spec 2026-10-20 E1 (owner):** while the Resume banner shows, Learn and the review options sit under "Or start another session" with a note that a start ends today's session and keeps its answers, and the footer's caption leads with "Ends today's session"; a refused or failed banner reads above that section. The rules of the session do not change (BR-STUDY-072).
- **FE-A6 P3 ruling C5:** `eightBox` picks the first available mode at first; the pick is not kept.
- The Learn button is the secondary tone with the sparkles glyph.
- **BR-CARD-002:** direction descriptions name no language ("See the term, recall the meaning").
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the hero's algorithm overline is an eyebrow.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** with only new cards, Learn is offered by the footer alone; the Learn row keeps its button when a review leads the footer (D2).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the hero is a plain `MxCard` (a summary, not a door; DESIGN.md "a hero leads somewhere tappable"); its tiles and lines are unchanged.
- **Owner 2026-10-16 (Q-P6-4):** the resume line ("{kind} · {mode} · {done} / {total} cards") wraps only between its terms (`MxTermLine`: no dot at a line edge since spec W1, 2026-10-20).
- **Q-C-1 (owner, 2026-10-16):** the Learn line and the footer's caption are lines of whole terms with no dot at a line edge (`MxTermLine`; spec W1, 2026-10-20: the stages are one term, which wraps at its own spaces only when wider than the line), and the direction sheet's note keeps each dot on the word before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- Hero: "{algorithm}" · "Up to {n} cards per session" · "New" · "Due" · "{n} of the due cards are overdue".
- Resume: "Session from today", or "Session in another deck" ("Phiên ở bộ thẻ khác") · on another deck's session "{root} › … › {deck}" (read "{deck}, in {parent}, in {root}" / "{deck}, trong {parent}, trong {root}") · "{kind} · {mode} · {n} / {n} cards" · "Continue where you stopped." · "Continue".
- Other sessions: "Or start another session" ("Hoặc bắt đầu phiên khác") · "Starting one ends today's session. Its answers are kept." ("Bắt đầu phiên mới sẽ kết thúc phiên hôm nay. Câu trả lời được giữ lại.") · caption term "Ends today's session" ("Kết thúc phiên hôm nay").
- Nothing: "Nothing to study in this deck" ("Không còn gì để học trong bộ thẻ này") · "Every card is learned and resting. Cards cannot be reviewed before they are due."; with no card "No cards yet" ("Chưa có thẻ") · "Add or import cards to study them here." ("Hãy thêm hoặc nhập thẻ để học tại đây."): it names no deck to add to, since a root takes sub-decks, not cards (BR-DECK-004)
- Learn row: "Learn new cards" · "Browse, then self-assess" (SM-2) / "Browse → match → guess → recall → fill" (Eight boxes) · "{n} of {n} new · in creation order" · "Learn".
- Review options, Eight boxes: "Review · choose how cards are asked" · "Match" "Pair terms with meanings, up to 5 at a time" · "Guess" "Pick the meaning out of five" · "Recall" "Recall the meaning within 20 seconds" · "Fill" "Type the term for the meaning" · "{n} cards" · "Not available" · "A mode that is not available lacks suitable cards for this review — it comes back when the cards qualify."
- Direction sheet, SM-2: "Review · question direction" · "Term first" "See the term, recall the meaning" · "Meaning first" "See the meaning, recall the term" · "Mixed" "Half each way, evenly split" · "The direction can't change once the session starts. SM-2 has one review mode: reveal, then grade yourself again · hard · good · easy." · "Start review".
- Banners: "Nothing is due any more." "The due cards were reviewed from another session or deleted since this screen was opened. Counts are up to date now." · "No new cards left to learn." "They were learned in another session or deleted since this screen was opened. Counts are up to date now." · "This mode can't run on the due cards any more." "The due cards changed since this screen was opened. Counts are up to date now." · "That session can't be continued." "It ended since this screen was opened, and its answers are kept. Start a new one below." · "Couldn't start the session." "Nothing was written. Try again."
- Footer: "Learn {n} new cards" · "Review {n} due cards" · "Starting…" · "Try again" · "Start a new review instead" · captions "Nothing due. Review opens once cards are due." · "{mode} · oldest first" (Eight boxes) · "{shown} of {due} due · oldest first" (SM-2).
