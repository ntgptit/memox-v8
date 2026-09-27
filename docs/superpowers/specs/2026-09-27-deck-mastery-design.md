# Deck mastery: the BR/UC, the count and screen 01 — design

Status: approved in chat 2026-09-27, spec awaiting review · Path: architectural · Owner rulings 2026-09-27 (§3)

## 1. Intent

Screen 01 has two partial states, and both wait on the same thing. No BR or UC says
what a deck's mastery counts. `wbs_BE.md` records it as a blocker ("Mastery của danh
sách deck").

- `rootLoaded` hides the mastery bar the kit draws on every deck row.
- `rootSortFilter` lacks the kit's fifth sort, "Progress · Least mastered first".

`deckLoaded` is marked done, but its summary card also drops the kit's donut and its
"Mastered · {algorithm}" line (detail file 01, deviation row "Mastery bar, donut";
library alignment spec A5). This work closes all three.

Success means four things:

- the rule is written: two new BRs and two amended UCs, so the blocker row leaves
  `wbs_BE.md`;
- every deck row at every level shows its mastery bar, and the summary card of an
  open deck shows the donut and "Mastered · {algorithm}";
- the sort sheet offers Progress, and it orders decks as the BR says;
- the count in SQL and the display status in Dart cannot drift apart without a
  test failing.

## 2. Context (2026-09-27)

- **What "mastered" means already.**
  - BR-SRS-013 defines mastered: box 8 in `eight_box`, or an interval of 128 days
    or more in `sm2`.
  - BR-CARD-006, BR-CARD-007 and BR-CARD-008 split a card's display into four
    states: `new`, `beginning`, `reviewing` and `mastered`.
  - `CardDisplayStatus.of` in `lib/features/card/domain/models/card_display_status_model.dart`
    implements that split, with thresholds 8 (box) and 128 (days). An unlearned card
    (`learned_at IS NULL`) is `new` whatever its schedule says.
- **What the kit draws** (kit v3 `1790244159-01e6`, module "DeckList").
  - **Row:** a 5 px bar under the meta line, 12 below it. Its fill is
    `masteryColor(pct)`, `width = pct`, over the progress track. An empty deck
    draws the track alone: "Always the bar, never a sentence."
  - **Summary card** (an open deck of decks): `MasteryDonut pct={summary.mastery}`
    and the overline "Mastered · {algo}". Beside them sit "N sub-decks · N cards"
    and the workload breakdown with "N scheduled".
  - **Sort sheet:** Manual order · Date added · Name · Most due cards ·
    "Progress · Least mastered first".
  - **Sample numbers:** they fit mastered ÷ all cards. For example, 1248 cards give
    0.1635, which is 204 cards; a deck whose 5 cards are all new shows 0.
- **What exists.**
  - `deckLevelOfRoots` and `deckLevelOfChildren` in
    `lib/core/database/queries/deck_queries.drift` count the subtree of each tile in
    one statement: cards, new, overdue, due today and the oldest due date.
  - `DeckTile` and `DeckLevel` (`deck_level_model.dart`) carry those counts.
    `DeckLevelSort` has `manual`, `name`, `recent` and `due`; its doc comment says
    the progress order "has no definition yet".
  - `DeckRowWidget` and `DeckSummaryCardWidget` draw screen 01. The summary card's
    doc comment still reads "No mastery until BE-A7 (spec A5)".
  - Screen 07's `CardDeckSummaryWidget` already draws `MxMasteryDonut` with
    `mastered / total`.
  - `MxLinearProgress` is a 4 px bar in primary, excluded from semantics, drawn by
    screens 13 and 14.
  - The `MasteryRamp` utility maps a fraction to learning (<34 %), reviewing
    (34–66 %) or mastered (≥67 %).

## 3. Decisions

Owner rulings, 2026-09-27:

| # | Question | Ruling |
|---|---|---|
| R1 | What does a deck's mastery count? | Mastered cards ÷ **every** active card of the subtree, new cards included. This matches the kit's numbers and screen 07's donut. |
| R2 | Where does a deck with no card go under Progress? | **Last.** It has nothing to master. Ties keep the manual order. |
| R3 | How is the 5 px bar built? | **Extend `MxLinearProgress`** with a mastery variant: the `MasteryRamp` fill at 5 px. No new shared widget. |

Design decisions:

| # | Decision |
|---|---|
| D1 | **BR-DECK-026, "Mastery của deck":** the fraction is the subtree's active cards whose display status is `mastered` (BR-CARD-006, BR-SRS-013), over all its active cards. Cards and decks in Trash count for nothing. The fraction is derived on read and never stored. A deck with no card has no fraction: its bar is the bare track, and the summary's donut reads 0. |
| D2 | **BR-DECK-027, "Sắp theo tiến độ":** Progress orders a level by that fraction, lowest first. Decks with no card come after every deck with cards. Equal fractions fall back to `(sibling_position, id)`, like every other sort (UC-DECK-003). |
| D3 | **UC-DECK-003** names the bar on every row and the donut with "Mastered" on an open deck's summary; its rules gain BR-DECK-026 and BR-DECK-027. **UC-DECK-006** lists Progress among the view-only sorts it already names ("tiến độ"). |
| D4 | Both queries gain `mastered_count`: `COUNT(*) FILTER (WHERE cs.learned_at IS NOT NULL AND (cs.current_box >= 8 OR cs.interval_days >= 128))`. They stay one statement each; the root query still groups by `root_id`. |
| D5 | `DeckTile` gains `masteredCount` and `double? get masteryFraction` (null at 0 cards). `DeckLevel` gains `masteredCount` and `cardCount`, summed over every tile of the level whatever the filter, like its other totals. |
| D6 | `DeckLevelSort.progress` compares by cross-multiplication (`a.mastered × b.cards` against `b.mastered × a.cards`), so equal fractions compare equal without floating point. Empty decks sort last, as R2 rules. |
| D7 | **One source for the thresholds.** SQL cannot call Dart, so the literals 8 and 128 appear in the queries. A parity test builds cards at every boundary and checks that the SQL `mastered_count` equals the number of cards `CardDisplayStatus.of` calls `mastered`: box 7 and 8, interval 127 and 128, and an unlearned card whose box or interval is at the threshold. A change to one side without the other fails that test. |
| D8 | `MxLinearProgress` gains a mastery variant (R3). The fill is `MasteryRamp.fill(fraction)`, and nothing is painted at 0. It keeps the progress track, the 5 px height and the eased fill, and it stays excluded from semantics. The primary variant does not change. |
| D9 | **Deck row:** the bar sits under the meta line, 12 apart (`AppSpacing.control`, the kit's rhythm), across the text column. An empty deck draws the track. The row's semantics add "{percent}% mastered" when the deck has cards, because the bar itself is silent. |
| D10 | **Summary card** of an open deck of decks: `MxMasteryDonut` on the start side with `semanticLabel` "Mastered", as screen 07 does. Beside it: the overline "MASTERED · {algorithm}", then the existing "N sub-decks · N cards", the breakdown and the "Study this deck" action. The doc comment loses "No mastery until BE-A7". |
| D11 | The sort sheet gains "Progress" with the sub-line "Least mastered first", last in the list as in the kit; en and vi. The sort chip's label names it like the other sorts. |
| D12 | Reorder mode (`DeckReorderRowWidget`) is unchanged: the kit draws no bar there, and the mode hides every view-only sort. |

## 4. Structure

| Layer | File | Change |
|---|---|---|
| Docs (rules) | `docs/features/deck/rules/BR-DECK-026-…md`, `BR-DECK-027-…md` | New (D1, D2) |
| Docs (UC) | `UC-DECK-003-…md`, `UC-DECK-006-…md` | Amended (D3) |
| Data | `lib/core/database/queries/deck_queries.drift` | `mastered_count` in two queries (D4) |
| Data | `lib/features/deck/data/mappers/deck_mapper.dart` | Map the new column |
| Domain | `lib/features/deck/domain/models/deck_level_model.dart` | `masteredCount`, `masteryFraction`, level totals (D5) |
| Domain | `lib/features/deck/domain/models/deck_level_query_model.dart` | `DeckLevelSort.progress` (D6) |
| Shared | `lib/shared/widgets/mx_linear_progress.dart` | Mastery variant (D8) |
| Presentation | `deck_row_widget.dart`, `deck_summary_card_widget.dart`, the sort sheet and its label | D9–D11 |
| l10n | `app_en.arb`, `app_vi.arb` | Progress sort title and sub-line, the row's "{percent}% mastered", the "Mastered · {algorithm}" overline |

No schema change and no migration: every column read already exists.

## 5. Behaviour

- **A root row:** "한국어 TOPIK I" has 1,248 cards, 204 of them mastered. Its bar
  fills 16 % in the learning colour, and TalkBack reads "… 16% mastered".
- **An empty deck:** the bar is the bare track and the semantics add nothing.
- **An open deck of decks:** the donut shows the level's mastered cards over its
  cards, with "MASTERED · SM-2" beside it.
- **Progress sort:** 0 % (with cards) < 3.5 % < 16 % < 100 %, then the empty decks.
  Two decks at 50 % keep their manual order.
- **The due-only filter with Progress:** the filter keeps decks with Due cards, and
  Progress orders them. The summary's totals still cover every deck of the level (D5).
- **Live updates:** the level already re-reads after every write, so an answer that
  promotes a card to mastered moves the bar and the sort position.

## 6. Errors

Nothing new can fail: the count rides the existing read, so a read error is the
level's error state (`rootError` / `deckError`). A fraction is always within
[0, 1], because `mastered_count ≤ card_count` holds by construction.
`MasteryRamp.fill` throws outside that range, and a model test pins it.

## 7. Tests

- **Model:**
  - `masteryFraction` at 0 cards, some cards and all mastered;
  - `DeckLevel` totals under a filter;
  - `DeckLevelSort.progress` ordering: ascending, empties last, ties by position
    then id, and cross-multiplication with equal fractions such as 1/2 and 2/4.
- **Repository:**
  - both queries return `mastered_count`: a subtree across two levels, cards in
    Trash excluded, and a deck in Trash excluded;
  - the parity test of D7, for both schedulers.
- **Widget:**
  - the row shows a bar with the right fraction and the "{percent}% mastered"
    semantics, and an empty deck shows the track;
  - the summary card shows the donut and the overline;
  - the sort sheet lists Progress and selecting it applies it;
  - `MxLinearProgress` mastery: the ramp colour at each threshold and nothing
    painted at 0.
- **Goldens:** `rootLoaded`, `rootSortFilter` and `deckLoaded`, light and dark; the
  `MxLinearProgress` gallery entry; text scale 2 for the row.
- **Traceability:** test names carry BR-DECK-026, BR-DECK-027 and UC-DECK-003.

## 8. Documents

- New BR files and amended UC files (D1–D3); `code:` lists in the UCs.
- **Detail file 01:**
  - `rootLoaded`, `rootSortFilter` and `deckLoaded` read "As drawn";
  - the deviation rows "Mastery bar, donut" and "Sort by progress" leave, and so do
    the two "waits for a BR/UC" lines.
- **Checklist:** `rootLoaded` and `rootSortFilter` move to done, and the summary
  counts follow.
- **`wbs_BE.md`:** the blocker row "Mastery của danh sách deck" leaves, with a
  dated update line.
- **`wbs_FE.md`:** FE-A1 moves from blocked to done.
- **Screen handoff index:** row 01 moves to `aligned` if it is not already.
- **UI-base §9:** the rows that deferred the bar and the donut close, pointing at
  this spec.

## 9. Plan

One plan and one PR. The tasks, in order:

1. BR and UC docs;
2. SQL, mapper and model, with the parity test;
3. `MxLinearProgress` mastery;
4. the row and the summary card;
5. the sort;
6. docs, checklist and goldens.

Before the plan, Impeccable critiques the kit's rows, summary and sort sheet
against this spec. After the build, it audits the goldens.

## 10. Out of scope

- Mastery on other screens: Study home, search results and the Progress tab. Each
  draws its own numbers under its own spec.
- A stored mastery column, or any cache.
- Weighted mastery, where beginning and reviewing count partly. It was ruled out
  (R1).

## 11. Risks and rollback

- **Performance:** the new `FILTER` rides a scan the queries already do, and adds
  no join. If a large library shows a regression, revert the PR; there is no
  feature flag.
- **Threshold drift:** covered by D7.
- **Rollback:** revert the PR. No schema or data changes, so nothing persists.
