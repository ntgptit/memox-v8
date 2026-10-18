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
| Resume banner | `MxCard` | "Session from today" overline with a static primary dot (`MxDotOverline`), "{kind} · {mode} · {done} of {total} cards", a line explaining Continue vs. starting fresh, "Continue" (`MxButton`, primary block). Shown only per BR-STUDY-072's in-progress, same-day session. |
| Nothing-due state | `MxEmptyState` (compact, success tone) | "Nothing to do right now" (BR-STUDY-008, BR-STUDY-054). |
| Learn row | full-bleed `MxCard` of one `MxListRow` | "Learn new cards", subtitle "{stage description} · {n} of {n} new · in creation order" (BR-STUDY-056, BR-STUDY-057); trailing small `MxButton` "Learn" starts a `learning` session directly (BR-STUDY-051) while a review leads the footer; with only new cards the footer offers Learn and the row has no button (critique 2026-09-30 part 3d-1, D2). |
| Review options | `MxListSectionHeader` (overline) + full-bleed `MxCard` of `MxOptionRow`s + `MxNote` | Eight boxes: Match · Guess · Recall · Fill, each with its own `MxBadge` "{n} cards" or "Not available" plus the unavailable reason as the row's subtitle (BR-STUDY-044, BR-STUDY-045, BR-MODE-009); a single available mode skips this list and opens directly (BR-STUDY-055). SM-2 has one mode, so this list never appears for it — see the Direction sheet. |
| Inline banners | `MxInlineBanner` | `refused` (warning): counts changed since the screen opened. `startFailed` (danger): the write failed; nothing was saved (BR-STUDY-018). The banner sits under the hero (and the resume banner), above the choices, so it is never below the fold; the body's 12 gaps space it (`hasBottomMargin: false`). |
| Footer | `MxFooterBar` | A caption line plus one block `MxButton` (primary; outline while the resume banner shows, "Try again" included, since Continue is then the one primary, critique 2026-09-30 part 1): "Learn {n} new cards" / "Review {n} due cards" / "Continue" / "Start a new review instead" / "Try again"; `MxSpinner` + "Starting…" while a session opens, and the button plus every option lock (BR-STUDY-004). |

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
| nothing | `study_entry_nothing_light.png` | `study_entry_nothing_dark.png` | Positive empty state, no footer (BR-STUDY-008, BR-STUDY-054). |
| resume | `study_entry_resume_light.png` | `study_entry_resume_dark.png` | The Continue banner with a primary, static dot and its progress track (see Rulings); the footer's start is outline (critique 2026-09-30 part 1). |
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
| resume | tap Continue on a session that ended meanwhile | refused (warning banner "That session can't be continued.") | the controller's refusal is VERIFIED `study_entry_controller_test.dart::Continue on a session that ended meanwhile is refused`; the banner copy for this reason is `UNVERIFIED (code read)` (`study_entry_banner_widget.dart` default branch) |
| starting | a second tap on Learn, Review or Continue | dropped; every option and the footer are locked | VERIFIED `study_entry_controller_test.dart::a second start while one runs is dropped (BR-STUDY-004)`; `study_entry_actions_test.dart::while a session opens every action is locked and the footer says Starting… (BR-STUDY-004, kit starting)`, `::while a start runs the review rows keep their pick (E1, BR-STUDY-004)` |
| refused / startFailed | the banner is drawn | it reads under the hero, above the choices, where the footer's Try again points | VERIFIED `study_entry_actions_test.dart::a failed start says so and Try again starts it again (screen 14 startFailed)` (the title sits above `StudyEntryLearnWidget`) |
| starting | the cards changed meanwhile (nothing due, nothing to learn, mode unavailable or not offered, deck or session gone) | refused: warning banner, footer rebuilt from the new counts | VERIFIED `study_entry_actions_test.dart::a start the counts no longer allow is refused with the warning banner; the footer follows the new counts`; `study_entry_banner_test.dart::self-assess no longer offered says the review algorithm changed, not that the session ended (UC-STUDY-003 E1)` |
| starting | the write fails, or any other refusal | startFailed: danger banner under the hero, above the choices; the footer is "Try again" | VERIFIED `study_entry_actions_test.dart::a failed start says so and Try again starts it again (screen 14 startFailed)`, `::a failed start beside an open session keeps one primary (final review, critique 2026-09-30 part 1)`; the banner's place above the first choice (the Learn row) is asserted in the first of them (audit 2026-10-17) |
| startFailed | tap Try again | starting with the same start (direction included) | VERIFIED same test (`study_entry_controller.dart` `retry`) |
| starting | Back, so the screen is gone before the start answers | no navigation to the session | `UNVERIFIED (code read)`: the controller returns null on `!ref.mounted` and `_open` checks `context.mounted`; nothing is rolled back if the write already landed, and Continue on 14 or Resume on 13 takes that session up |

## Accessibility

- The app bar's `titleWidget` is the deck header and the screen sets `isTitleWidgetRouteName: true`, so the deck header names the route for TalkBack (`study_entry_screen.dart`). `UNVERIFIED (code read)`: no test reads the route's semantics name.
- TalkBack reads the app bar, the breadcrumb, the hero (overline, then "New: {n}", "Due: {n}" — each stat tile is one node), the overdue note, then the rows and the footer. The resume banner's dot is decorative.
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
- **FE-A6 P3 ruling C5:** `eightBox` picks the first available mode at first; the pick is not kept.
- The Learn button is the secondary tone with the sparkles glyph.
- **BR-CARD-002:** direction descriptions name no language ("See the term, recall the meaning").
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the hero's algorithm overline is an eyebrow.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** with only new cards, Learn is offered by the footer alone; the Learn row keeps its button when a review leads the footer (D2).
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the hero is a plain `MxCard` (a summary, not a door; DESIGN.md "a hero leads somewhere tappable"); its tiles and lines are unchanged.
- **Owner 2026-10-16 (Q-P6-4):** the resume line ("{kind} · {mode} · {done} of {total} cards") wraps only between its terms (`lib/l10n/meta_line.dart`).
- **Q-C-1 (owner, 2026-10-16):** the Learn line keeps its stages a phrase and its count whole terms ("20 of 120 new · in creation order"), the footer's caption is glued as whole terms (`metaLine`; it is ruled one line, so this only keeps it whole), and the direction sheet's note keeps each dot on the word before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- Hero: "{algorithm}" · "Up to {n} cards per session" · "New" · "Due" · "{n} of the due cards are overdue".
- Resume: "Session from today" · "{kind} · {mode} · {n} of {n} cards" · "Continue where you stopped, or start something new — that ends this one and keeps its answers." · "Continue".
- Nothing: "Nothing to do right now" · "Every card is learned and resting. Cards cannot be reviewed before they are due."
- Learn row: "Learn new cards" · "Browse, then self-assess" (SM-2) / "Browse → match → guess → recall → fill" (Eight boxes) · "{n} of {n} new · in creation order" · "Learn".
- Review options, Eight boxes: "Review · choose how cards are asked" · "Match" "Pair terms with meanings, up to 5 at a time" · "Guess" "Pick the meaning out of five" · "Recall" "Recall the meaning within 20 seconds" · "Fill" "Type the term for the meaning" · "{n} cards" · "Not available" · "A mode that is not available lacks suitable cards for this review — it comes back when the cards qualify."
- Direction sheet, SM-2: "Review · question direction" · "Term first" "See the term, recall the meaning" · "Meaning first" "See the meaning, recall the term" · "Mixed" "Half each way, evenly split" · "The direction can't change once the session starts. SM-2 has one review mode: reveal, then grade yourself again · hard · good · easy." · "Start review".
- Banners: "Nothing is due any more." "The due cards were reviewed from another session or deleted since this screen was opened. Counts are up to date now." · "No new cards left to learn." "They were learned in another session or deleted since this screen was opened. Counts are up to date now." · "This mode can't run on the due cards any more." "The due cards changed since this screen was opened. Counts are up to date now." · "That session can't be continued." "It ended since this screen was opened, and its answers are kept. Start a new one below." · "Couldn't start the session." "Nothing was written. Try again."
- Footer: "Learn {n} new cards" · "Review {n} due cards" · "Starting…" · "Try again" · "Start a new review instead" · captions "Nothing due. Review opens once cards are due." · "{mode} · oldest first" (Eight boxes) · "{shown} of {due} due · oldest first" (SM-2).
