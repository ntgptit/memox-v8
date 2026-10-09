<!-- Hand-written screen record. -->

# 10 · Card detail

A card, read-only, pushed over the card list: `CardDetailScreen` (library
phase 4b). UC-CARD-002; BR-CARD-013 (read-only), BR-CARD-014 (content and
current schedule), BR-CARD-015/017 (paginated, generation-grouped history).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) | Back; title "Card"; trailing compact secondary `MxButton` "Edit" (shown only once the card has loaded). |
| Deck path | `DeckContextHeaderWidget` | Library › ancestors › deck › "Card"; shown only once the card (and so its `deckId`) has loaded — see Rulings. |
| Content | `CardDetailContentWidget` (`MxCard`, `MxStatusBadge`, `MxTagChip`) | Status badge + flag glyph in their own row above the front/back (§9 row 89); front, back; only the optional fields that hold a value (BR-CARD-014); tag chips. |
| Schedule | `CardScheduleWidget` (`MxCard`, `MxIconTile` × n) | "Current schedule · Box {n} of 8" + an 8-bar ramp (eight_box), or "Current schedule · SM-2" (sm2, no ramp); fact tiles Due, Learned, Last answered, Answers, Lapses, Algorithm (Last answered, Answers and Lapses only once the card has an answer, critique 2026-09-30), plus Ease/Interval/Repetitions for SM-2. The paired facts come first; "Algorithm" takes a full-width row of its own after them. |
| History header | `MxListSectionHeader` | "History" / "History · newest first". |
| History list | A timeline (DEV-170, the kit's "Flashcard history" layout in the app's tokens): `CardHistoryRailWidget` nodes on a 2dp rail down the leading 24, each `CardHistoryEventWidget` (`MxBadge`, `MxCard`) beside its dot | Newest first. A cycle starts with a hollow mark on the rail and "Cycle {n} · {scheduler}" as a field label (BR-CARD-017). Each answer: a 14dp dot ringed in the outcome's ink (success, warning ink for a lapse, variant ink for relearning); in its card the outcome badge, and on the right how long ago ("19 days ago", bold) over the date and time; the kind ("Review", "Learning", "Repeat") as a body line; then the metadata: the box, ease or interval move in the outcome's ink, and mode, hint used, time ran out and next due each with its glyph. |
| Load more | `MxButton` (secondary, block) or `MxInlineBanner` (danger) on failure | "Load older history" / "Couldn't load older history." with Retry. |
| End of history | A hollow mark that ends the rail | "Beginning of history · card added {date}". While older history remains, the rail runs on past the last answer to the Load more button. |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This card is no longer here" / "It was moved to Trash while you were away. It can still be restored from Trash, with its history."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `card_detail_top_light.png` | `card_detail_top_dark.png` | — |
| loadMore | no golden | no golden | A secondary block `MxButton` "Load older history". |
| loadMoreFailed | no golden | no golden | Retry sits under the message (see Rulings); what loaded stays. |
| empty | no golden | no golden | `MxEmptyState` (neutral, compact) "Not studied yet"; content and schedule cards still show above it. |
| loading | no golden | no golden | A single generic `MxSkeletonList` (4 rows) replaces the whole body (see Rulings). |
| error | no golden | no golden | Full-screen `MxErrorState`, "Couldn't load this card" — the body is the shared "Nothing was lost. Try again in a moment." |
| notFound | no golden | no golden | `CardGoneWidget` (shared with the editor's gone state); both actions live now that Trash exists (§9 row 87, closed by FE-B1 D11). The deck path is hidden here. |
Other goldens: `card_detail_history_light.png` / `card_detail_history_dark.png` (the history scrolled into view).


Every state above is built.

## Rulings

- **§9 row 89:** the status badge and flag sit above the front/back, full width.
- **DEV-170 (owner 2026-10-05), replacing §9 row 86:** the history is a timeline in the layout of the kit's "Flashcard history" screen, with the app's tokens: a rail, a dot per answer in its outcome's ink, how long ago over the date and time, glyphs on the metadata. A cycle is a mark on the rail ("Cycle {n} · {scheduler}", a field label; the reset date is not stored), and the rail ends at "Beginning of history". No "All events" filter: no rule asks for one.
- **§9 row 90 (amended, critique 2026-09-30 part 3d-2):** the `MxBadge` carries the outcome ("Remembered", "Again"…); the kind ("Learning") is plain text beside it.
- **§9 row 50:** `MxInlineBanner` actions sit under the message.
- **UC-CARD-002 E1:** the deck path shows only once the card has loaded; the detail can open from an id alone, so the deck is unknown until then.
- **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide convention.
- **§9 row 115:** in-flow cards are `MxCard` at radius 12.
- The load error uses the app's shared local-first body "Nothing was lost. Try again in a moment." (as screens 06 and 23).
- **Critique 2026-09-30 tone pass, T5:** a history badge (it names the outcome, part 3d-2) is success for a right answer, warning for a lapse ("Again", "Forgot") and neutral for relearning.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the schedule card's title is an eyebrow; the read-only field labels are field labels in sentence case. (Its "cycle headers stay section labels" gave way to DEV-170's field-label marks.)
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** a history badge names the outcome ("Again", "Good", "Remembered", "Forgot"…) in that outcome's tone (warning lapse, neutral relearning, success otherwise); the kind ("Learning", "Review", "Repeat") is plain text (since DEV-170 a body line under the badge); the metadata lines were text without glyphs (DEV-170 gives them glyphs); the schedule's "Algorithm" fact takes a full-width row of its own after the paired facts.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is plain ink everywhere, the card list included (F6).

## Copy

- App bar: "Card" · "Edit".
- Content: card front, back, "Example sentence" · "Hint" · "Pronunciation" (each shown only with a value), tag chips.
- Schedule: "Current schedule · Box {box} of {count}" · "Current schedule · SM-2" · "Box 1 · 1 day" · "Box 8 · 128 days" · "Due" · "Learned" · "Last answered" · "Answers" · "Lapses" · "Algorithm" · "{scheduler} · cycle {generation}" · "Ease" · "Interval" · "{count, plural, =1{1 day} other{{count} days}}" · "Repetitions" · "Not yet".
- History: "History" · "History · newest first" · "Cycle {generation} · {scheduler}" · how long ago ("just now", "{n} minutes ago", "{n} hours ago", "yesterday", "{n} days ago", "{n} months ago", "{n} years ago", shared with Trash) · "Not studied yet" · "Every answer in a learning or review session will appear here, newest first." · "Load older history" · "Couldn't load older history." · "What is shown is complete up to here." · "Beginning of history · card added {date}" · "Box {from} → {to}" · "Ease {from} → {to}" · "Interval {from}d → {to}d" · "Hint used" · "Time ran out" · "Next due {date}".
- History outcomes (badge) and kinds (plain text): "Learning" · "Review" · "Repeat" · "Remembered" · "Forgot" · "Again" · "Hard" · "Good" · "Easy".
- Error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".
- Gone: "This card is no longer here" · "It was moved to Trash while you were away. It can still be restored from Trash, with its history." · "Back to deck" · "Open Trash".
