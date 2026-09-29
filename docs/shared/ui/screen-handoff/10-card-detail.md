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
| Schedule | `CardScheduleWidget` (`MxCard`, `MxIconTile` × n) | "Current schedule · Box {n} of 8" + an 8-bar ramp (eight_box), or "Current schedule · SM-2" (sm2, no ramp); fact tiles Due, Learned, Last answered, Answers, Lapses, Algorithm, plus Ease/Interval/Repetitions for SM-2. |
| History header | `MxListSectionHeader` | "History" / "History · newest first". |
| History list | `CardHistoryEventWidget` × n (`MxBadge`, `MxCard`), grouped under a `_CycleHeader` overline | "Cycle {n} · {scheduler}" groups, newest first; each event: kind badge + action text, absolute date/time, mode, box/ease/interval before→after, hint used, timed out, next due — no rail, no dots, no relative time, no free-text note (§9 rows 86, 90). |
| Load more | `MxButton` (secondary, block) or `MxInlineBanner` (danger) on failure | "Load older history" / "Couldn't load older history." with Retry. |
| End of history | Centred caption line | "Beginning of history · card added {date}". |
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

Every state above is built.

## Rulings

- **§9 row 89:** the status badge and flag sit above the front/back, full width.
- **§9 row 86:** history is a plain `MxCard` per event with absolute date and time, no rail, dots or free-text note; a cycle header is the overline label only ("Cycle {n} · {scheduler}"), because the reset date is not stored.
- **§9 row 90:** the `MxBadge` carries the kind ("Learning"); the action ("Remembered") is text beside it.
- **§9 row 50:** `MxInlineBanner` actions sit under the message.
- **UC-CARD-002 E1:** the deck path shows only once the card has loaded; the detail can open from an id alone, so the deck is unknown until then.
- **§9 row 125:** loading is a single generic `MxSkeletonList`, the app-wide convention.
- **§9 row 115:** in-flow cards are `MxCard` at radius 12.
- The load error uses the app's shared local-first body "Nothing was lost. Try again in a moment." (as screens 06 and 23).

## Copy

- App bar: "Card" · "Edit".
- Content: card front, back, "Example sentence" · "Hint" · "Pronunciation" (each shown only with a value), tag chips.
- Schedule: "Current schedule · Box {box} of {count}" · "Current schedule · SM-2" · "Box 1 · 1 day" · "Box 8 · 128 days" · "Due" · "Learned" · "Last answered" · "Answers" · "Lapses" · "Algorithm" · "{scheduler} · cycle {generation}" · "Ease" · "Interval" · "{count, plural, =1{1 day} other{{count} days}}" · "Repetitions" · "Not yet".
- History: "History" · "History · newest first" · "Cycle {generation} · {scheduler}" · "Not studied yet" · "Every answer in a learning or review session will appear here, newest first." · "Load older history" · "Couldn't load older history." · "What is shown is complete up to here." · "Beginning of history · card added {date}" · "Box {from} → {to}" · "Ease {from} → {to}" · "Interval {from}d → {to}d" · "Hint used" · "Time ran out" · "Next due {date}".
- History kinds/actions: "Learning" · "Review" · "Repeat" · "Remembered" · "Forgot" · "Again" · "Hard" · "Good" · "Easy".
- Error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".
- Gone: "This card is no longer here" · "It was moved to Trash while you were away. It can still be restored from Trash, with its history." · "Back to deck" · "Open Trash".
