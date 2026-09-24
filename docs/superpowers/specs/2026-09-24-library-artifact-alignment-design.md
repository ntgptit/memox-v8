# MemoX V8 — Library alignment with the V3 screen handoff

The Library screens merged in #28–#31 were designed from an Impeccable shape brief because the V3 handoff had no screens. The owner has since supplied the screens: the artifact **"MemoX — Mobile UI Kit v3"** (claude.ai artifact `UCesgHkzYHKsZwhwVshKRE`, version `1790244159-01e6`). This project records that artifact as the official screen handoff and realigns the Library to it.

## 1. Intent

- **Outcome:** the Library looks and behaves like the artifact on every state that V8 supports, and the repository holds a screen handoff that later screens (card editor, study, progress, settings) are built from.
- **Who it is for:** the owner, on an Android phone (`PRODUCT.md`).
- **Success:**
  - `docs/shared/ui/screen-handoff/` indexes all 26 artifact screens and details 01, 02, 04 and 07.
  - Screens 01 Deck list, 02 Review algorithm & reset, 04 Library search and 07 Card list match their handoff images state by state, light and dark, within the deviations recorded in §4.
  - Every count still comes from a read model. The UI derives none (Library spec §1).
  - The current gate passes; every changed screen has widget tests, light/dark goldens, a `test/visual_audit/` companion and en/vi strings.

## 2. Decisions

Settled with the owner in brainstorming on 2026-09-24:

| # | Decision |
|---|---|
| A1 | The artifact is the official screen handoff. Where it contradicts a BR or UC, the BR/UC wins and the handoff records the deviation. |
| A2 | The merged Library is realigned to the artifact. Scope: screens 01, 02, 04 and 07. Library phase 4 (card editor and detail, artifact 08–10) follows this project and is built straight from the artifact. |
| A3 | The handoff lives in `docs/shared/ui/screen-handoff/`: an index of all 26 screens now, a detail file per screen when that screen is built. |
| A4 | A **control** whose feature or backend does not exist yet is **hidden**. The Library root's "Coming soon" app-bar action opens a sheet that names each such feature with one line on what it will do (amended 2026-09-25, owner decision; before, such controls showed disabled). |
| A5 | A **data display** whose data does not exist yet (deck mastery bar, deck mastery donut) is **hidden**: an empty bar would claim 0 % mastered. |
| A6 | The root due strip is display-only (no chevron, no tap) until Study home (FE-A8) exists. |
| A7 | Deck rows drop the overdue · today · new line. The breakdown lives on the root strip and the deck summary card; a row carries one "N due" badge. |
| A8 | A deck that vanishes while open shows the artifact's "This deck is no longer here" empty state. This replaces ruling P2-L7 (snackbar and pop). An operation that fails because its deck vanished still returns with a snackbar (UC-DECK-002 E1). |
| A9 | Changing the review algorithm while unlocked asks for confirmation in a non-destructive dialog (UC-DECK-002 steps 3–4), although the artifact switches on tap. |
| A10 | The "Kept" label of the reset dialog uses `statusMasteredInk`. `statusMastered` equals `mastery` in both themes, and that ink is already pinned at ≥ 4.5:1 on every ground and on its own tint (`mx_derived_colors_test`). No new token. |
| A11 | Library search shows decks only. The Cards group, tag names on card rows, "Load more" and the card/tag hints wait for BE-A8. The field hint is "Search decks". |
| A12 | `MxAppBar` gets a title-widget slot so the search field sits in the app bar. |
| A13 | The card deck summary shows the mastery donut and the New/Beginning/Reviewing/Mastered distribution. A new read counts the four display states (BR-CARD-008, BR-SRS-013) in one query. |
| A14 | The deck app bar carries the card list's search action and selection header. `app/` injects them into the deck screen, as it injects the card content (D8 of the Library spec holds; UI-base debt row 75 closes). |
| A15 | Card rows show up to two tags and "+N". The card list read returns each card's tags without N+1. |
| A16 | Superseded by #33 (Library phase 4a): the card list's "New card" FAB and the unset deck's "New card" exist, and phases C–E keep them. The card detail (phase 4b) stays outside this project. |
| A17 | Five phases, one plan and one PR each (§9). |

## 3. Screen handoff

```
docs/shared/ui/screen-handoff/
  00-index.md               the 26 screens: states, FE item, status, artifact link and version
  01-deck-list.md
  02-review-algorithm.md
  04-library-search.md
  07-card-list.md
  img/<nn>-<screen>/<state>-{light,dark}.png
tools/design/capture_screens.mjs
```

- **Index status values:** `aligned`, `to align`, `not built`, `out of V8`. Screens 08–10 are `not built` (Library phase 4); 03, 05, 06, 11, 12 are `out of V8` until their sub-project; study, progress and settings screens are `not built`.
- **Each detail file holds:**
  - purpose, and layout from top to bottom with the `Mx*` widget for each region;
  - a state table: artifact state id → V8 behaviour → image;
  - a deviation table: what the artifact says, what V8 does, which BR/UC wins;
  - a pending table: disabled controls and hidden data, each with the item that unblocks it;
  - the artifact's English copy, the source for the ARB entries.
- **Images:** 390 px wide, light and dark, only the states V8 supports. States that exist only for Trash or starter decks are listed in the deviation table, not captured.
- **Capture script:** Playwright renders the downloaded artifact, steps each screen's state stepper and writes the images. It prints in English (`CLAUDE.md`). The artifact HTML itself is not committed; the index names its URL and version.
- **Generated handoff untouched:** `design-handoff.json`, `tools/docs/split_handoff.py` and the files it writes are not edited. The screen handoff lives beside `design-handoff/`, not in it: `tools/docs/check.py` rejects any file in `design-handoff/` that the JSON does not produce. Its files are hand-written and say so in their first line.

## 4. Screens

### 4.1 01 Deck list — Library root and any open deck

One recursive screen, `DeckLevelScreen`, as today. Routes, providers and controllers stay; widgets change.

**Root (`/decks`):**

| Region | Design |
|---|---|
| App bar | Large "Library". One action, "Coming soon", opening the sheet of A4 (Starter decks, Tags, Trash and the rest). The root reorder action leaves the app bar (see the action sheet). |
| Search | `MxSearchField` in trigger mode, hint "Search decks" (A11); a tap pushes `/decks/search`. |
| Due strip | Hero `MxCard`: bolt tile on primary, "N cards due", `MxWorkloadBreakdownLine` (overdue · today · new). Display-only (A6). Hidden when the library holds no card. |
| Section header | `MxListSectionHeader` "N DECKS" with a sort pill, "Manual ⌄"; "Manual · Due only" tinted primary when the filter is on. |
| Sort & filter | One sheet replacing today's two: the four V8 sorts (manual, name, recent, due; "Progress" waits for BE-A7 under Coming soon, A4), and the "Only decks with due cards" toggle. |
| Rows | One `MxCard` per deck, 8 apart: 44 px `MxIconTile` (layers / copy / folder-open by content type), name on one line with ellipsis, `MxBadge` "N due" when due > 0, meta "N sub-decks · N cards" or "Empty · add cards or a sub-deck", trailing `⋮`. No mastery bar (A5). No breakdown line (A7). |
| FAB | "New deck". |

**Open deck (`/decks/deck/:id`):**

| Region | Design |
|---|---|
| App bar | Back, deck name, `⋮` opening the same action sheet as its row. |
| Breadcrumb | Library › ancestors › deck. |
| Summary card (deck holding sub-decks) | Hero `MxCard`: label with the scheduler name ("SM-2"), "N sub-decks · N cards", breakdown with "N scheduled". "Study this deck" waits under Coming soon (A4). No donut, no "Mastered" (A5). |
| List | Header "N sub-decks" with the sort pill; rows as at the root. |
| FAB | "New sub-deck"; none at level 10 (BR-DECK-001). |
| Content by type | `unset`: today's empty state with its two create choices. `card`: the card list (4.4). |

**Action sheet** (row `⋮` and open-deck `⋮`), with a header naming the deck:

- Root: Open deck · Rename · Review algorithm → screen 02 · Reorder · Delete.
- Sub-deck: Open · Rename · Move · Reorder · Delete.

Reorder moves into the sheet at both levels; UI-base debt row 72 closes.

**States and deviations:**

| Artifact state | V8 |
|---|---|
| loading | Skeletons shaped like the deck row. |
| first launch | "Start your library": Create deck; footnote "Everything stays on this device." |
| error | `MxErrorState`, local-first copy. |
| due filter, none | "Nothing due right now" + "Show all decks". |
| create | Dialog: name, required review algorithm, lock `MxNote`. |
| rename | Dialog, name pre-selected. |
| move to Trash, trashed · Undo | **Deviation:** delete is permanent (BR-DECK-022, BR-DECK-023). The dialog names the sub-deck and card counts and confirms with a destructive button; no Undo snackbar. Trash is a later sub-project (UC-TRASH-001). |
| move sheet | `MxDeckPickerSheet`, ineligible targets disabled with their reason (UC-DECK-005). |
| level 10 | No FAB; the header says the level. |
| not found | "This deck is no longer here" + "Back to Library" (A8); Trash waits under Coming soon (A4). |

### 4.2 02 Review algorithm & reset — `/decks/deck/:deckId/algorithm`

A new `DeckAlgorithmScreen` in `deck/presentation` (`deck → srs` is allowed). It replaces `deck_scheduler_sheet_widget.dart`; the root action sheet's "Review algorithm" navigates here. Backend unchanged: `ChangeDeckScheduler`, `GetResetLearningSummary`, `ResetLearningProgress`, and the deck's `generation` and `firstAnsweredAt`.

| Region | Design |
|---|---|
| App bar, breadcrumb | Back, "Review algorithm"; Library › root › Review algorithm. |
| Lock strip | Unlocked: hero ground, open-lock tile, "Can still be changed · Locks once the first card finishes learning." Locked: warning-soft ground, lock tile, "Locked · cycle N · The first card finished learning on {date}. Only a reset opens a new cycle." The date is `firstAnsweredAt` in local time, formatted for the locale. |
| ALGORITHM | Two `MxOptionRow`s with the artifact's descriptions; the current one selected; both disabled when locked, with a lock `MxNote` pointing to the reset (UC-DECK-002 A1: never hidden). While unlocked, an `MxNote` says what a switch resets. |
| START OVER | `MxCard` explaining the reset, outline button "Reset learning progress…". |

**Switch (unlocked):**

1. Tapping the current algorithm does nothing (UC-DECK-002 A4).
2. Tapping the other opens a non-destructive `MxDialog`: "Switch to {algorithm}? Every card's schedule in this tree starts over and any open study session closes. No history is lost." Cancel / Switch (A9).
3. While switching, the chosen row shows `MxSpinner`.
4. Success: `MxSnackbar` "Switched to {algorithm} · every card starts fresh".
5. Failure (E2): danger `MxInlineBanner` "Couldn't switch. The deck still uses {algorithm}." with Retry.
6. Refused because the tree just locked (E4): the screen renders the locked state and the reason. The rendered state never decides validity.

**Reset:**

1. The dialog loads `ResetLearningSummary`.
2. Nothing to lose (`hasProgressToLose == false`): one sentence, "Nothing has been studied in this cycle yet, so there is nothing to lose. A new cycle starts with the algorithm you pick."
3. Otherwise: "This starts cycle N+1 for {deck} and its {cardCount} cards.", then two tiles:
   - **Kept** (`statusMasteredInk`, A10): decks, cards, tags and every past answer, labelled cycle N;
   - **Lost** (warning ink): every card's schedule, due date and progress; "the open session" only when `openSessionCount > 0`.
4. "Algorithm for the new cycle": Keep {current} (selected) / Switch to {other}.
5. Cancel / "Reset and start cycle N+1"; while running, a spinner and "Resetting…".
6. Success: snackbar "Cycle N+1 started · N cards are new again"; the screen shows the unlocked state.
7. Rejections go through `srs_rejection_message_widget.dart`.

**Other states:** loading skeleton; load error `MxErrorState`; deck gone or not a root (BR-DECK-025) → the not-found empty state of 4.1.

### 4.3 04 Library search — `/decks/search`

| Region | Design |
|---|---|
| App bar | Back, then `MxSearchField` in the app bar's title-widget slot (A12), focused on entry. No "Search" title. |
| Empty query | No query runs (BR-SEARCH-003). Label "SEARCH FINDS", one hint row "a deck name", `MxNote` "Case does not matter, accents do: “hoc” will not find “học”." (true under BR-SEARCH-002). |
| Searching | "Searching for “…”…" and skeleton rows. |
| Results | "Results for “…”"; a **Decks** group whose header carries the layers glyph, the primary title and a count pill; each row an `MxListRow` with the content-type tile, the name with the match emphasised, the path and "holds cards / sub-decks", and a chevron. |
| No results | Neutral `MxEmptyState` "No matches for “…”" with the accent sentence. |
| Error | `MxErrorState` "Search didn't run · Your library is safe on this device." |

Pending BE-A8 (A11): the Cards group, tag names on card rows, "Load more", the card and tag hints, and the footer line naming cards.

### 4.4 07 Card list — an open deck whose content type is `card`

| Region | Design |
|---|---|
| App bar | Back, deck name, search action, `⋮`. While selecting: close, "N selected", "Select all M". Injected by `app/` (A14). |
| Search | The search action reveals the in-deck search field above the filters; closing it clears the term. |
| Summary card | Hero `MxCard`: `MxMasteryDonut`, "DECK PROGRESS · {algorithm}", "N of M cards mastered", the breakdown, the four-state distribution bar and its legend (A13). "Study this deck" waits under Coming soon (A4). Hidden while selecting. |
| Filters | `MxFilterChip` All · Due · New · Flagged with counts; the Tags filter waits under Coming soon (A4, FE-B2). |
| Header | "Showing N of M" (while selecting "N of M selected") with the sort pill "Newest first ⌄" / "Due first ⌄". |
| Rows | One card per row: status dot (checkbox while selecting), front 16/700 and back 12, one line each with ellipsis; the uppercase status label in its ink, up to two `MxTagChip`s and "+N" (A15); trailing flag in the streak colour and the due chip ("New", "Due today", "In Nd", "Nd overdue") from a domain helper. |
| Bulk bar | Move · Flag · Tag · Delete; Export waits under Coming soon (A4, FE-B3). |
| FAB | "New card", as #33 built it (A16); hidden while selecting. |

**States and deviations:**

| Artifact state | V8 |
|---|---|
| loading | Skeletons shaped like the card row. |
| empty | "No cards in this deck yet"; Import waits under Coming soon (A4); `MxNote` on when studying opens. "Add first card" opens the #33 editor (A16). |
| search empty | Neutral empty state naming the term. |
| error, not found | As 4.1. |
| selection, select all | Long-press selects (BR-CARD-020); "Select all" covers the whole filtered set. |
| card → Trash, trashed · Undo, deck → Trash | **Deviation:** permanent delete with a count, no Undo (as 4.1). |
| move targets, no move target | `MxDeckPickerSheet` with its empty slot. |
| bulk failed | The selection stays and an `MxInlineBanner` says what failed. |
| card actions | Waits for phase 4 (open, edit). UI-base debt row 77 stays open until then. |

## 5. Backend and domain changes

The only changes outside `presentation/`, each test-first:

| Where | Change |
|---|---|
| `card` domain + data | **Status counts:** for a deck, the number of cards in each `CardDisplayStatus` in one query, as a stream that updates with the list. `CardDisplayStatus` stays the single definition (BR-CARD-008, BR-SRS-013). |
| `card` domain + data | **Tags on list items:** `CardListItem` carries its tags, sorted by folded name (BR-TAG-001), read for the whole page in one query; no read per card. |
| `card` domain | **Due label:** a pure helper from `dueAt` and the list's start of day to new / today / in N days / N days overdue, next to `CardDisplayStatus`. |
| `deck` domain | `DeckLevel.deckCount`: every deck of the level whatever the filter, for the open deck's summary (phase C, owner decision C-O1). |
| `deck` domain + data, `deck_queries.drift`, `card_queries.drift` | `contentType` on `DeckTreeNode` and `DeckSearchHit`, read from `d.content_type` in the three queries that share `DeckForestRow` (C-O2). No schema change. |
| `card` domain + data | **Deck workload** (phase E, ruling E-L1): `CardListView.workload`, the overdue, today and new counts of the whole deck, counted from the schedules the list already reads with `CardDue.of`. No query or schema change. |

No schema change and no migration. If either read needs one, the phase stops and raises it (BE-D1 would come first).

## 6. Shared UI and theme changes

Each follows `flutter-theme-design`: widget test, light/dark golden, gallery entry.

| Where | Change |
|---|---|
| `MxSearchField` | A trigger mode: read-only, an `onTap`, button semantics. |
| `MxAppBar` | A `titleWidget` slot as an alternative to the title string; the title still gives up width first. |
| `MxEmptyState` | An optional secondary action between the primary action and the footnote; a null callback draws it disabled (C-O3). |
| `MxActionSheetCommandRow` | `isEnabled`: a disabled command is dimmed and announced as disabled. |
| Theme | Icons `starterDecks`, `dueNow`, `cardDeck`; text role `rowTitleMatch` for the emphasised part of a search hit (C-O4). |
| `MxIconTile` | `tone`: `tinted` (default), `primary` and `warning` solid fills with `onPrimary` / `onWarning` glyphs; `seed` only with `tinted` (phase D, owner decision D-O1). |
| `MxCard` | `isWarning`: the warning-soft ground with the warning border, for screen 02's locked strip (D-O1). |
| `MxOutcomeTile` | New: a label in its ink over a tinted ground and a body, tones `kept` (`statusMasteredInk` over the mastery tint, A10) and `lost` (`warningInk` over `warningSoft`) (D-O2). |
| Theme (phase D) | Icons `lock`, `lockOpen`, `resetProgress`. |
| Theme (phase E) | `streak` / `onStreak` semantic colours (#F97316 / #FFAE6E, #FFFFFF) and `streakInk` (light: 20% toward onSurface; dark: streak), owner decisions E-O2, E-O4. |
| `MxFlagMark` | New: the flag glyph in `streakInk` with its accessible label (E-O2). |
| `MxStatusDistribution` | New: the four display states as one stacked bar with a legend of counts (A13, E-O2). |
| `MxCard` | `isSelected`: a primary border (E-O5). |
| `MxStatusBadge` | `isPlain`: the uppercase label in its status ink, no pill (the card row's status line). |

## 7. Routing and composition

- New child route `/decks/deck/:deckId/algorithm` → `DeckAlgorithmScreen`. System Back returns to the deck screen.
- `DeckLevelScreen` receives, besides `cardContent`, a builder for the app bar of a card deck (actions and the selection header). `app/router` composes both from `card/presentation`. `deck` still never imports `card` (Library spec D8).
- The feature import map in `test/architecture/boundary_rules.dart` is unchanged.

## 8. Verification

- **Per phase:** the tests in §5–§6; a widget test for every state row in 4.1–4.4 that V8 supports; light/dark goldens at 3x; `test/visual_audit/` companions; ARB entries in en and vi; the `HOST-WIDGET` IT scenarios of the touched UCs; `expectAccessibleTargets` and text scale 2 (phones only).
- **Gate:** the one the root `README.md` names at the time of the phase (the five commands, or `dod_check.sh` once FE-D2 lands).
- **Visual check:** app screenshots against the handoff images, state by state: one inspection round, one batch of fixes, at most one confirming round.
- **Goldens on Linux (FE-D1):** a phase regenerates, on Linux, only the goldens of the screens it changes (owner decision, 2026-09-24). The other goldens stay as the owner's platform produced them, and fail on Linux as before.
- **Ledgers:** `docs/wbs_FE.md` and `docs/wbs_BE.md` change in the commit of the work they describe. Phase A also corrects `wbs_FE.md`, which still lists FE-A1 as not started although #28–#31 merged.

## 9. Phases

One spec; one plan and one PR per phase; a phase's plan is written after the previous phase merges.

| # | Content | Usable result |
|---|---|---|
| A | The handoff: `screen-handoff/00-index.md`, detail files 01, 02, 04, 07, images, capture script; `wbs_FE.md` corrected. | Screens are specified in the repository. |
| B | Foundations: `MxSearchField` trigger mode, `MxAppBar` title slot; the card status counts, tags on list items and the due label helper. | The pieces C–E compose exist and are tested. |
| C | 01 Deck list (root and open deck, action sheet, sort & filter sheet, dialogs, states) and 04 Library search. | The deck tree matches the handoff. |
| D | 02 Review algorithm & reset; the scheduler sheet is removed. | The algorithm can be switched and progress reset from its own screen (FE-A4). |
| E | 07 Card list: injected app bar, summary card, filters, rows, bulk bar. | The card list matches the handoff. |

## 10. Debt register

The UI-base register (`2026-09-23-flutter-ui-base-design.md` §9) stays the only one. This project:

- closes row 72 (phase C) and row 75 (phase E);
- supersedes ruling P2-L7 with A8 and records it there (phase C);
- appends any contradiction found while building, marked "library alignment phase N".

## 11. Out of scope

- Library phase 4 (card editor, card detail; artifact 08–10).
- Trash, starter decks, tag management, import and export, reminders; the Coming soon sheet names them (A4).
- Study, Progress and Settings screens, and anything that starts a session.
- BE-A7 (deck mastery) and BE-A8 (library-wide search).
- Tablet layouts (Library spec D4).
