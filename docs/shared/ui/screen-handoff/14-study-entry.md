<!-- Hand-written screen record. -->

# 14 · Study entry

The Study Entry of an open deck (FE-A6, FE-A7): `StudyEntryScreen`, the choice
between Learn and Review before a session opens. UC-STUDY-001, UC-STUDY-003.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) | Back, deck name (composed by `app/` from the deck feature, FE-A6 spec D16), and the trailing "Study options" icon, which opens screen 15 (FE-A3 D3). |
| Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck. |
| Hero | `MxCard` (hero) + `MxStatTile` × 2 (FE-A6 spec D17) | "{algorithm} · up to {n} cards per session" (BR-STUDY-024); two stat tiles, New and Due: Due above zero in primary, New above zero muted, a zero in plain ink (BR-STUDY-047, BR-STUDY-051 — the two sets never merge); "{n} of the due cards are overdue" note, in the warning ink, when any are overdue. |
| Resume banner | `MxCard` | "Session from today" overline with a pulse dot, "{kind} · {mode} · {done} of {total} cards", a line explaining Continue vs. starting fresh, "Continue" (`MxButton`, primary block). Shown only per BR-STUDY-072's in-progress, same-day session. |
| Nothing-due state | `MxEmptyState` (compact, success tone) | "Nothing to do right now" (BR-STUDY-008, BR-STUDY-054). |
| Learn row | full-bleed `MxCard` of one `MxListRow` | "Learn new cards", subtitle "{stage description} · {n} of {n} new · in creation order" (BR-STUDY-056, BR-STUDY-057); trailing compact `MxButton` "Learn" starts a `learning` session directly (BR-STUDY-051), independent of the footer's Review action. |
| Review options | `MxListSectionHeader` (overline) + full-bleed `MxCard` of `MxOptionRow`s + `MxNote` | Eight boxes: Match · Guess · Recall · Fill, each with its own `MxBadge` "{n} cards" or "Not available" plus the unavailable reason as the row's subtitle (BR-STUDY-044, BR-STUDY-045, BR-MODE-009); a single available mode skips this list and opens directly (BR-STUDY-055). SM-2 has one mode, so this list never appears for it — see the Direction sheet. |
| Inline banners | `MxInlineBanner` | `refused` (warning): counts changed since the screen opened. `startFailed` (danger): the write failed; nothing was saved (BR-STUDY-018). |
| Footer | `MxFooterBar` | A caption line plus one block `MxButton` (primary; outline while the resume banner shows, "Try again" included, since Continue is then the one primary, critique 2026-09-30 part 1): "Learn {n} new cards" / "Review {n} due cards" / "Continue" / "Start a new review instead" / "Try again"; `MxSpinner` + "Starting…" while a session opens, and the button plus every option lock (BR-STUDY-004). |

## Direction sheet (SM-2 only)

Tapping the footer's Review action on an SM-2 root deck opens `MxBottomSheet`
with a header and three `MxOptionRow`s — Term first (recommended, selected by
default), Meaning first, Mixed — each with a one-line description, an
`MxNote` stating the choice locks once the session starts (BR-MODE-017), and
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
| starting | `study_entry_starting_light.png` | `study_entry_starting_dark.png` | Footer shows the spinner, every option locks (BR-STUDY-004). |
| refused | `study_entry_refused_light.png` | `study_entry_refused_dark.png` | Inline warning banner; the footer stays usable (plan R5). |
| startFailed | `study_entry_start_failed_light.png` | `study_entry_start_failed_dark.png` | Inline danger banner, footer offers "Try again". |
| loading | `study_entry_loading_light.png` | `study_entry_loading_dark.png` | Skeletons in the hero and option-list shapes. |
Other goldens: `study_entry_direction_sheet_light.png` / `study_entry_direction_sheet_dark.png` (the Direction sheet).


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
caption "{mode} · {n} due cards · oldest first". Every mode has its screen since P4, so
Learn is offered whenever new cards exist and nothing says "Coming soon". A deck deleted while its entry is open leaves with
the toast "This deck no longer exists" (UC-STUDY-001 E1). Goldens:
`test/features/study/presentation/goldens/study_entry_{eight_box,sm2,only_new,nothing,loading,resume,starting,refused,start_failed,direction_sheet}_*`.

## Accessibility

- TalkBack reads the app bar, the breadcrumb, the hero (overline, then "New: {n}", "Due: {n}" — each stat tile is one node), the overdue note, then the rows and the footer. The resume banner's pulse dot is decorative.
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

## Copy

- Hero: "{algorithm} · up to {n} cards per session" · "New" · "Due" · "{n} of the due cards are overdue".
- Resume: "Session from today" · "{kind} · {mode} · {n} of {n} cards" · "Continue where you stopped, or start something new — that ends this one and keeps its answers." · "Continue".
- Nothing: "Nothing to do right now" · "Every card is learned and resting. Cards cannot be reviewed before they are due."
- Learn row: "Learn new cards" · "Browse, then self-assess" (SM-2) / "Browse → match → guess → recall → fill" (Eight boxes) · "{n} of {n} new · in creation order" · "Learn".
- Review options, Eight boxes: "Review · choose how cards are asked" · "Match" "Pair terms with meanings, up to 5 at a time" · "Guess" "Pick the meaning out of five" · "Recall" "Recall the meaning within 20 seconds" · "Fill" "Type the term for the meaning" · "{n} cards" · "Not available" · "A mode that is not available lacks suitable cards for this review — it comes back when the cards qualify."
- Direction sheet, SM-2: "Review · question direction" · "Term first" "See the term, recall the meaning" · "Meaning first" "See the meaning, recall the term" · "Mixed" "Half each way, evenly split" · "SM-2 has one review mode: reveal, then grade yourself again · hard · good · easy. The direction cannot change once the session starts." · "Start review".
- Banners: "Nothing is due any more." "The due cards were reviewed from another session or deleted since this screen was opened. Counts are up to date now." · "No new cards left to learn." "They were learned in another session or deleted since this screen was opened. Counts are up to date now." · "This mode can't run on the due cards any more." "The due cards changed since this screen was opened. Counts are up to date now." · "That session can't be continued." "It ended since this screen was opened, and its answers are kept. Start a new one below." · "Couldn't start the session." "Nothing was written. Try again."
- Footer: "Learn {n} new cards" · "Review {n} due cards" · "Starting…" · "Try again" · "Start a new review instead" · captions "Nothing is due — review is available once cards come due." · "{mode} · {n} due cards · oldest first" (Eight boxes) · "{shown} of {due} due · oldest first" (SM-2).
