<!-- Hand-written screen record. -->

# 10 · Card detail

A card, read-only, pushed over the card list: `CardDetailScreen` (library
phase 4b). UC-CARD-002; BR-CARD-013 (read-only), BR-CARD-014 (content and
current schedule), BR-CARD-015/017 (paginated, generation-grouped history).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back; title "Card"; trailing small secondary `MxButton` "Edit" (shown only once the card has loaded). |
| Deck path | `DeckContextHeaderWidget` | Library › ancestors › deck › "Card"; shown only once the card (and so its `deckId`) has loaded — see Rulings. |
| Content | `CardDetailContentWidget` (`MxCard`, `MxStatusBadge`, `MxTagChip`) | Status badge + flag glyph in their own row above the front/back (§9 row 89); front, back; only the optional fields that hold a value (BR-CARD-014); tag chips. |
| Schedule | `CardScheduleWidget` (`MxCard`, `MxIconTile` × n) | "Current schedule · Box {n} of 8" + an 8-bar ramp (eight_box), or "Current schedule · SM-2" (sm2, no ramp); fact tiles Due, Learned, Last answered, Answers, Lapses, Algorithm (Last answered, Answers and Lapses only once the card has an answer, critique 2026-09-30), plus Ease/Interval/Repetitions for SM-2. The paired facts come first; "Algorithm" takes a full-width row of its own after them. The dates (Due, Learned, Last answered) take a row each, so a date keeps its year on one line; the counts pair (audit 2026-10-19, G5). |
| History header | `MxListSectionHeader` | "History" / "History · newest first". |
| History list | A timeline (DEV-170, the kit's "Flashcard history" layout in the app's tokens): `CardHistoryRailWidget` nodes on a 2dp rail down the leading 24, each `CardHistoryEventWidget` (`MxBadge`, `MxCard`) beside its dot | Newest first. A cycle starts with a hollow mark on the rail and "Cycle {n} · {scheduler}" as a field label (BR-CARD-017). Each answer: a 14dp dot ringed in the outcome's colour (success, warning text for a lapse, variant text for relearning); in its card the outcome badge, and on the right how long ago ("19 days ago", bold) over the date and time; the kind ("Review", "Learning", "Repeat") as a body line; then the metadata: the box, ease or interval move in the outcome's colour, and mode, hint used, time ran out and next due each with its glyph. |
| Load more | `MxButton` (secondary, block) or `MxInlineBanner` (danger) on failure | "Load older history" / "Couldn't load older history." with Retry. |
| End of history | A hollow mark that ends the rail | "Beginning of history · card added {date}". While older history remains, the rail runs on past the last answer to the Load more button. |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This card is no longer here" / "It was moved to Trash while you were away. It can still be restored from Trash, with its history."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `card_detail_top_light.png` | `card_detail_top_dark.png` | `card_detail_screen_test.dart::the detail shows the card under its path; Edit asks for it`. |
| history | `card_detail_history_light.png` | `card_detail_history_dark.png` | The loaded card scrolled to its history: one row per answer with the values its row stored (BR-CARD-016). `card_history_scroll_test.dart::each answer shows the values its row stored (BR-CARD-016)`. |
| historyLoading | no golden | no golden | The card shows (content, schedule); three skeleton rows stand in for the history while its first page reads. Code read: `card_history_scroll_widget.dart`. |
| historyError | no golden | no golden | The first history page fails: `MxErrorState` "Couldn't load the history" · "Nothing was lost. Try again in a moment." with Retry, under the content and schedule. Code read: `card_history_scroll_widget.dart`. VERIFIED (closing acceptance 2026-10-18): `card/presentation/card_detail_state_coverage_test.dart::historyError: a first history page that fails is an error in plain words with Retry, under the content; Retry shows the history` |
| loadMore | no golden | no golden | A secondary block `MxButton` "Load older history"; it spins while the page reads, the rows stay. `card_history_scroll_test.dart::Load older history adds the rest, then the history ends (A5)`. |
| loadMoreFailed | no golden | no golden | "Couldn't load older history." · "What is shown is complete up to here." with Retry under the message (see Rulings); what loaded stays. `card_history_scroll_test.dart::a failed older page keeps the rows and offers Retry (E4)`. |
| empty | no golden | no golden | `MxEmptyState` (neutral, compact) "Not studied yet"; content and schedule cards still show above it. `card_history_scroll_test.dart::a card never studied says so (BR-CARD-018)`. |
| loading | no golden | no golden | A single generic `MxSkeletonList` (4 rows) replaces the whole body (see Rulings). |
| error | no golden | no golden | Full-screen `MxErrorState`, "Couldn't load this card" — the body is the shared "Nothing was lost. Try again in a moment." `card_detail_screen_test.dart::a failed read offers Retry and hides the cause (E3)`. |
| notFound | no golden | no golden | `CardGoneWidget` (shared with the editor's gone state); both actions live now that Trash exists (§9 row 87, closed by FE-B1 D11). The deck path is hidden here. `card_detail_screen_test.dart::a card deleted while open shows it is gone (E2)`, `::a link to a card that does not exist shows it is gone (E1)`. |

Every state above is built.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the card lands | loaded (with historyLoading, then the history) | VERIFIED `card_detail_screen_test.dart::the detail shows the card under its path; Edit asks for it` |
| loading | the read fails | error | VERIFIED `::a failed read offers Retry and hides the cause (E3)` |
| error | Retry | loading, then loaded | Retry is on screen in the test above; the re-read is `UNVERIFIED (code read)`: `card_detail_screen.dart` invalidates `cardDetailProvider` |
| loading / loaded | the card does not exist, or is moved to Trash | notFound | VERIFIED `::a link to a card that does not exist shows it is gone (E1)`, `::a card deleted while open shows it is gone (E2)` |
| notFound | Back to deck / Open Trash | the previous screen / screen 06 | `UNVERIFIED (code read)`: `CardGoneWidget` callbacks |
| loaded | Edit, and the editor finds the card gone, then Back to deck | the editor pops `true` and the detail closes with it (`_editCard` in `app_router.dart`), so the person lands on the deck instead of this screen's own gone state | VERIFIED `test/app/library_routes_test.dart::a card trashed elsewhere while it is edited: Back to deck returns to the deck, past its detail (audit 2026-10-17)` |
| loaded | tap Edit | the card editor (screen 09) | VERIFIED `::the detail shows the card under its path; Edit asks for it` |
| historyLoading | the first page lands | the history, or empty | VERIFIED `card_history_scroll_test.dart::each answer shows the values its row stored (BR-CARD-016)`, `::a card never studied says so (BR-CARD-018)` |
| historyLoading | the first page fails | historyError | `UNVERIFIED (code read)`: `card_history_scroll_widget.dart`; no test fails the first page |
| historyError | Retry | historyLoading, then the history | `UNVERIFIED (code read)`: invalidates the history controller |
| loaded | tap Load older history | loadMore (spinner), then more rows, then the "Beginning of history" mark | VERIFIED `card_history_scroll_test.dart::Load older history adds the rest, then the history ends (A5)` |
| loadMore | a second tap | ignored | `UNVERIFIED (code read)`: `card_history_controller.dart` `loadMore()` returns while loading; the button also spins |
| loadMore | the page fails | loadMoreFailed, the rows kept | VERIFIED `::a failed older page keeps the rows and offers Retry (E4)` |
| loadMore | the page read dies on a bug (not a `Failure`) | loadMoreFailed, the rows kept, as for a `Failure`: Retry shows, no spinner for good; the bug is reported | VERIFIED `card_held_bug_test.dart::an older history page that dies on a bug offers Retry, not a spinner for good (UC-CARD-002 E4)` |
| loadMoreFailed | Retry | loadMore at the same cursor | VERIFIED same test |
| loadMore | a late or duplicate page arrives | dropped | `UNVERIFIED (code read)`: `card_history_controller.dart` compares the cursor (E5) |
| loaded | the card is edited in the editor and the editor closes | the detail shows the new content | the detail reads the card as a stream; `UNVERIFIED (code read)` for the return path |
| any | Back | the card list (screen 07) or the previous screen | `UNVERIFIED (code read)` |

## Rulings

- **§9 row 89:** the status badge and flag sit above the front/back, full width.
- **DEV-170 (owner 2026-10-05), replacing §9 row 86:** the history is a timeline in the layout of the kit's "Flashcard history" screen, with the app's tokens: a rail, a dot per answer in its outcome's colour, how long ago over the date and time, glyphs on the metadata. A cycle is a mark on the rail ("Cycle {n} · {scheduler}", a field label; the reset date is not stored), and the rail ends at "Beginning of history". No "All events" filter: no rule asks for one.
- **§9 row 90 (amended, critique 2026-09-30 part 3d-2):** the `MxBadge` carries the outcome ("Remembered", "Again"…); the kind ("Learning") is plain text beside it.
- **§9 row 50:** `MxInlineBanner` actions sit under the message.
- **UC-CARD-002 E1:** the deck path shows only once the card has loaded; the detail can open from an id alone, so the deck is unknown until then.
- **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide convention.
- **§9 row 115:** in-flow cards are `MxCard` at radius 12.
- The load error uses the app's shared local-first body "Nothing was lost. Try again in a moment." (as screens 06 and 23).
- **Critique 2026-09-30 tone pass, T5:** a history badge (it names the outcome, part 3d-2) is success for a right answer, warning for a lapse ("Again", "Forgot") and neutral for relearning.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the schedule card's title is an eyebrow; the read-only field labels are field labels in sentence case. (Its "cycle headers stay section labels" gave way to DEV-170's field-label marks.)
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** a history badge names the outcome ("Again", "Good", "Remembered", "Forgot"…) in that outcome's tone (warning lapse, neutral relearning, success otherwise); the kind ("Learning", "Review", "Repeat") is plain text (since DEV-170 a body line under the badge); the metadata lines were text without glyphs (DEV-170 gives them glyphs); the schedule's "Algorithm" fact takes a full-width row of its own after the paired facts.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain text colour everywhere, the card list included (F6).
- **Q-C-1 (owner, 2026-10-16):** the scheduler fact ("Eight boxes · cycle 2") and the history marks ("Cycle 2 · SM-2", "Beginning of history · card added …") wrap only between whole terms (`metaLine`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

- App bar: "Card" · "Edit".
- Content: card front, back, "Example sentence" · "Hint" · "Pronunciation" (each shown only with a value), tag chips.
- Schedule: "Current schedule · Box {box} of {count}" · "Current schedule · SM-2" · "Box 1 · 1 day" · "Box 8 · 128 days" · "Due" · "Learned" · "Last answered" · "Answers" · "Lapses" · "Algorithm" · "{scheduler} · cycle {generation}" · "Ease" · "Interval" · "{count, plural, =1{1 day} other{{count} days}}" · "Repetitions" · "Not yet".
- History: "History" · "History · newest first" · "Cycle {generation} · {scheduler}" · how long ago ("just now", "{n} minutes ago", "{n} hours ago", "yesterday", "{n} days ago", "{n} months ago", "{n} years ago", shared with Trash) · "Not studied yet" · "Every answer in a learning or review session will appear here, newest first." · "Load older history" · "Couldn't load older history." · "What is shown is complete up to here." · "Beginning of history · card added {date}" · "Box {from} → {to}" · "Ease {from} → {to}" · "Interval {from}d → {to}d" · "Hint used" · "Time ran out" · "Next due {date}".
- History outcomes (badge) and kinds (plain text): "Learning" · "Review" · "Repeat" · "Remembered" · "Forgot" · "Again" · "Hard" · "Good" · "Easy".
- Error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".
- Gone: "This card is no longer here" · "It was moved to Trash while you were away. It can still be restored from Trash, with its history." · "Back to deck" · "Open Trash".
