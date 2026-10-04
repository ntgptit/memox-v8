# SP3b — App shell and the SCR-DECK-001 vertical slice

Status: draft for owner review · 2026-10-04 · Branch: `claude/wonderful-ride-dnypk9`

SP3b replaces the placeholder shell with the real navigation shell (docs/NAVIGATION.md) and builds
the first production screen, SCR-DECK-001 (the Library root and any open deck), as the reference
vertical slice that SP3c copies for the remaining 33 screens. It builds the product-semantic and
`feature:deck` components the screen needs. It ends with an Impeccable audit, the first `scr_*`
goldens and the owner's sign-off.

Inputs: the SP3a spec §9–§10 (handoff and close-out), DESIGN.md, `docs/screens/spec/SCR-DECK-001-deck-list.md`,
docs/NAVIGATION.md, `docs/functional-spec/deck.md`, docs/USE_CASES.md (UC-DECK-001…006), the deck
domain and data in `lib/features/deck/`.

## 1. Owner rulings (2026-10-04)

These bind every phase. They come from the SP3b brainstorm.

**R1. The whole of SCR-DECK-001, and nothing beyond it.**
- Every state and interaction of the screen is built. That covers:
  - root and open deck; loaded, loading, empty, error and not found;
  - create, rename, move, Move to Trash and Undo, reorder, sort and filter;
  - the action sheets, the picker sheet, the dialogs, the toast;
  - the responsive and accessibility states the screen spec asks for.
- All 23 states are traced (§6). None is dropped because it is rare, hard to golden, has no real
  destination yet, or was not built in V8.
- Destinations the screen opens are SP3c's (SCR-CARD-001, SCR-STUDY-001/002, SCR-SEARCH-001,
  SCR-TRASH-001, SCR-SETTINGS-001, SCR-SRS-001, SCR-STARTER-001, SCR-TAG-001,
  SCR-TRANSFER-001, SCR-CARD-002).
  - They stay route stubs in their NAVIGATION.md position.
  - SP3b proves only that SCR-DECK-001 emits the right navigation intent and that the router lands
    on the right destination. It builds no destination UI.

**R2. Product-semantic components.**
- SP3b builds the catalog components the slice needs: `MasteryRamp`, `MasteryDonut`,
  `WorkloadBreakdownLine`, `DueStrip`, `DeckRow`, `DeckPickerSheet`, and `LibraryHeader` (R3).
- They compose the SP3a foundation, follow DESIGN.md, copy no legacy UI, and have their own contract
  and goldens.
- A component that turns out to be generic across features is not promoted into SP3a mid-phase. It
  becomes a finding or ruling, and the owner reviews it.

**R3. The Library root has a feature header, not a large app bar.**
- SCR-DECK-001's "(large)" bar becomes `LibraryHeader`, a `feature:deck` component:
  - the "Library" title sits at the top of the scroll in the Headline role;
  - the three icon actions (Starter decks, Tags, Trash) sit on its line.
- The root uses no `MxAppBar`, and `MxAppBar` keeps its two frozen densities.
- `LibraryHeader` gets a catalog row and a contract, and Impeccable `shape` reviews its values
  before it is built.

**R4. DESIGN.md wins over the screen spec, and the screen spec wins over the ARB (ADR-021).**
- A screen-spec value that departs from an approved token or contract is mapped to the canonical
  value, and the screen spec is corrected at its source:
  - the row icon tile 44 becomes the medium tile, 40;
  - the mastery bar 5 becomes the regular progress, 4;
  - the gap between deck rows, 8, becomes 16 ("16 between list items"; spacing inside a row is
    layout, not inter-row spacing).
- No token or variant is added to keep an old number.
- Copy follows the screen spec. The ARB is updated to it, never the reverse.
- Each correction is made at its source with a short ruling in this sub-project. No blind bulk
  rewrite: each mismatch is read for its meaning first.
- DESIGN.md changes only for a real new requirement: a new meaning that no token or component can
  express, with reuse or architectural reach, and the owner's review.

**R5. Sort and filter live for the session, per level.**
- Each Library or deck level keeps its own sort and filter. They are restored on Back and on a tab
  switch, and reset to the spec default (Manual, all decks) on a cold start.
- They are controller state of SCR-DECK-001, keyed by the level (`deckId`, `null` for the root).
- They are never persisted to Drift, preferences, an entity or a repository. No BR or FN is added
  for them.
- Remembering the choice across restarts would be a new product requirement.
- Ruling added to SCR-DECK-001: "Each Library/deck stack entry preserves its own transient
  sort/filter state for the current app session."

**R6. The architecture is the reference for SP3c.**
- The data flow is fixed: existing domain and data → controller and immutable state → screen
  composition.
- No business rule sits in a widget, and no widget calls a repository.
- The controller, loading and error handling, and the effect and navigation pattern are clean
  enough to copy, and are documented as the reference implementation (§9).

**R7. Phasing.** One spec on this branch, four phases (§5), each with its own plan, the owner's plan
approval, execution, review and sign-off, as in SP3a.

## 2. Scope

**In:**
- `AppNavigationShell`, `MxBottomNav` and `MxNavRail`, with the router moved off
  `lib/app/placeholder/`.
- Route stubs for SP3c's destinations, and the not-found screen.
- `MasteryRamp`, `MasteryDonut`, `WorkloadBreakdownLine`, `DueStrip`, `DeckRow`, `LibraryHeader`
  and `DeckPickerSheet`.
- SCR-DECK-001 complete: its controller, states, screen, sheets, dialogs and toast.
- The SCR-DECK-001 screen spec and the ARB, corrected per R4 and R5.
- Component (`mx_*`) and screen (`scr_*`) goldens.
- Impeccable `shape` (P2) and critique plus audit (every phase).
- The reference-implementation record.

**Out:**
- Any other screen's UI.
- New BR, FN or UC.
- Domain or data changes beyond what a deck use case needs to serve a traced state. If a state
  cannot be served by the existing use cases, the gap is raised to the owner, not invented.
- The SP3c asks: search in the bar, the three-button footer, the icon bulk bar, the settings
  under-label controls, row-end buttons, extra list-header trailings, centred short content.
- Persisting sort and filter.

## 3. Authority

BR, FN and UC > DESIGN.md (and the Mx contracts) > the screen spec > the ARB and legacy copy >
goldens.

- The SP3a contracts stay frozen. One reopens only when a composition in this sub-project exposes
  a real root cause, a gate, accessibility or contrast check fails, or a DESIGN.md change passes
  review.
- The P3 visual debts (DESIGN.md `- Debt:` on `MxCard`, `MxBadge`, `MxLinearProgress` and
  `MxSheetActions`) are reviewed here when their triggers fire on this screen.
- The SP3a minors listed in its §10 are taken up only when their trigger fires during this work,
  and each is recorded when it is.

## 4. Architecture

### 4.1 Paths by catalog layer

`tools/docs/design_catalog.py` learns these paths, and `check.py` enforces them as it does for
SP3a.

| Layer | Source | Test |
|---|---|---|
| `app-shell` | `lib/app/shell/<snake>.dart` | `test/app/shell/<snake>_test.dart` |
| `product-semantic` | `lib/shared/widgets/semantic/<snake>.dart` | `test/shared/widgets/semantic/<snake>_test.dart` |
| `feature:deck` | `lib/features/deck/presentation/widgets/<bucket>/<snake>_widget.dart` (ADR-011 buckets: `DeckRow` in `items/`; `DueStrip` and `LibraryHeader` in `sections/`; `DeckPickerSheet` in `overlays/`) | `test/features/deck/presentation/widgets/<snake>_widget_test.dart` |

- `lib/app/placeholder/` is deleted.
- The stubs for SP3c's destinations and the not-found screen move to `lib/app/router/`.
- Component goldens keep the `mx_<snake>__<state>__<variant>` namespace for every catalog layer.
- Screen goldens are `scr_deck_001__<state>__<variant>`.

### 4.2 Screen data flow

Every feature in SP3c copies this flow.

- **Use cases (existing):**
  - `WatchDeckLevelUseCase(parentId, sort, filter)` gives a `DeckLevel` (tiles and the level
    summary).
  - `WatchDeckUseCase(deckId)` gives `Outcome<DeckView, DeckRejection>`.
  - The create, rename, move-target, move, reorder, deletion-summary, delete and undo use cases.
- **Controller:** `DeckLevelController` in `presentation/controllers/deck_level_controller.dart`.
  - It is a Riverpod codegen `Notifier`, a family keyed by `deckId` (`null` = root), and auto
    disposed.
  - It watches the level and the open deck, and exposes one method per user intent.
- **State:** `DeckLevelState` in `presentation/states/`, immutable and hand-written (no freezed). It
  holds:
  - `level`, an `AsyncValue<DeckLevel>`;
  - `view`, the open deck's outcome;
  - per-intent task status (creating, renaming, the set of decks being moved or trashed,
    reordering);
  - `effect`, a one-shot effect.
- **Effects:** a sealed `DeckLevelEffect` (navigate, toast, Undo offer, Undo refused, step back).
  - The screen consumes each one through `ref.listen` with a previous-value check.
  - It clears the effect after consuming it, so a rebuild never replays it.
- **Session preferences:** `DeckViewPrefsController` is kept alive for the session.
  - It holds a map from `deckId` to sort and filter, and is the only holder of them (R5).
  - It resets on a cold start.
- **Navigation:** only through `AppRoutes`. A screen never builds a path string. An intent becomes an
  effect, and the screen performs it with `go_router`.
- **Rules:**
  - Business rules stay in the domain.
  - The controller holds no `BuildContext`.
  - It guards against double submits and checks `ref.mounted` after every await.
  - It maps rejections (`Outcome.rejected`) to the spec's copy keys. Name errors are shown inline,
    never as a snackbar.

## 5. Phases

Each phase runs its own cycle:
1. Plan (the owner approves the plan and its decision table).
2. TDD execution.
3. Impeccable critique and one batch of fixes, closed by exactly one `impeccable audit`.
4. Opus whole-phase review.
5. Gate.
6. `golden-compare` page.
7. Owner sign-off.

### P1 — Navigation shell

- **`AppNavigationShell`** becomes the builder of the existing `StatefulShellRoute.indexedStack`.
  The four branches and the route contract are unchanged.
  - Below 600dp it shows `MxBottomNav` at the bottom.
  - From 600dp it shows `MxNavRail` on the leading edge (the right edge in RTL), with tab content
    measured in the remaining width.
  - Tapping the current tab returns it to its root.
  - Each tab keeps its stack and scroll position.
  - At a tab root, Back leaves the app.
- **Inset hand-off.** The shell wraps each branch navigator in a `MediaQuery` whose bottom padding
  adds the bar's height.
  - `MxScreenScaffold` and `MxScreenScroll` read that padding as a system inset: the tail and the
    FAB sit above the bar, and content scrolls under the glass.
  - The inset drops while the keyboard is up (SP3a).
  - Routes over the shell get no inset.
- **`MxBottomNav`** (DESIGN.md):
  - a 64 bar in an 80 block, glass (surface at 84%, an 18 blur);
  - labels always shown;
  - an outlined resting glyph and a filled selected glyph in a tonal `primary-container` pill (The
    Selection Ladder Rule: no `primary` fill);
  - a 48 target per destination, read as a selected tab.
- **`MxNavRail`:** 80 wide, on the `surface-container-low` ground, with the same glyphs, pill and
  labels as the bar.
- **Values.** Values DESIGN.md does not state (pill size, gaps) go through Impeccable `shape` and
  the P1 decision table for the owner's approval. Legacy code never decides them.
- **Stubs and not found.**
  - Each SP3c destination is a stub screen built from `MxScreenScaffold` and `MxEmptyState`, naming
    its screen ID. It sits in its NAVIGATION.md place, under or over the shell.
  - The not-found screen is an `MxErrorState` with no technical text and one way back to the
    Library.
- **Tests:**
  - tab switching, re-tapping a tab to its root, stacks kept across tabs;
  - the rail from 600, RTL, the inset hand-off, 48 targets, semantics;
  - `test/app/placeholder_app_test.dart` rewritten for the real shell;
  - the redirect tests unchanged and green.
- **Goldens:** `mx_bottom_nav`, `mx_nav_rail`, and `mx_app_navigation_shell` (phone and tablet).

### P2 — Product-semantic and deck components

Each contract is written into DESIGN.md first. Impeccable `shape` reviews every value DESIGN.md
does not state, and the P2 decision table goes to the owner.

- **`MasteryRamp`** — the single threshold function (DESIGN.md): below 34% `status-learning`,
  34–66% `status-reviewing`, from 67% `status-mastered`.
  - It draws on `MxLinearProgress` at the regular size, 4 (R4).
  - With no card (a `null` fraction) it shows a bare track and reads no percentage.
  - A percentage never rounds falsely to 0 or 100. TalkBack reads "{n}% mastered".
- **`MasteryDonut`** — a level's mastery as a ring, using the same threshold function, with the
  percentage in its centre. Diameter and stroke come through the decision table.
- **`WorkloadBreakdownLine`** — "overdue · today · new":
  - one colour per part, each a role with a declared contrast pair;
  - only parts above 0 are shown, and the caller picks the parts (the due strip shows
    overdue · today);
  - it wraps between whole terms (The Wrap Rule).
- **`DeckRow`** (`items/`) — a tappable `MxCard` holding:
  - a 40 tile by content type (holds decks, holds cards, empty);
  - the name on one line;
  - the three counts overdue · due · new, each its own `MxBadge` (a deck with no work shows zero
    due and zero new on a neutral ground);
  - the meta line, a `MasteryRamp`, and a separate `⋮` `MxIconButton`.

  Rows sit 16 apart.
- **`DueStrip`** (`sections/`) — a hero-tone `MxCard` with:
  - a bolt tile and "{n} cards due";
  - a `WorkloadBreakdownLine` (overdue · today) and a chevron.

  It opens the Study tab, and is hidden when the library holds no card.
- **`LibraryHeader`** (`sections/`) — R3.
- **`DeckPickerSheet`** (`overlays/`) — an `MxBottomSheet` listing move targets (name and path, from
  FN-DECK-010).
  - The current place is locked, with its reason.
  - The footer is "Move here", built from `MxSheetActions`.
  - The API stays reusable for CARD, TRANSFER and TRASH.
- **Tests and goldens.** Each has a widget test (states, 48, semantics, RTL, both themes, text scale
  1.5 and 2.0) and `mx_*` goldens.

### P3 — SCR-DECK-001, the read path

- **Screen.** `DeckListScreen({String? deckId})` serves `/decks` and `/decks/deck/:deckId`.
- **Root:** `LibraryHeader`, then the search field (trigger mode), `DueStrip`, the "{n} DECKS"
  header with the sort `MxChipTrigger`, the `DeckRow` list, and the FAB "New deck".
- **Open deck:**
  - `MxAppBar` (back, the name, `⋮`) and `MxBreadcrumb`;
  - the summary `MxCard` (`MasteryDonut`, `WorkloadBreakdownLine`, "Study this deck");
  - "Sub-decks" with the sort trigger, the `DeckRow` list, and the FAB "New sub-deck" (none at level
    10 or on an `unset` deck);
  - an `unset` deck shows `MxEmptyState` with its three ways forward;
  - a deck that holds cards navigates to the SCR-CARD-001 stub.
- **States built in P3:** `root_loaded`, `root_loading`, `root_empty`, `root_error`, `root_search`,
  `root_sort_filter`, `root_due_empty`, `deck_loaded`, `deck_empty`, `deck_max_depth`,
  `deck_loading`, `deck_error`, `deck_not_found`.
- **Sort and filter sheet** per R5.
- **Navigation.** Every navigation intent, tested by the location it reaches.

### P4 — SCR-DECK-001, the write path

- **Action sheets:**
  - root: Open · Study this deck · Rename · Study options · Review algorithm · Reorder · Move to
    Trash;
  - sub-deck: Open · Study · Rename · Study options · Move to another deck · Reorder · Move to
    Trash;
  - the header is the name alone.
- **Dialogs:** create deck, create sub-deck (with discard confirm), rename, Move to Trash (counts
  from FN-DECK-004; the confirm spins).
- **Move.** Through `DeckPickerSheet` (FN-DECK-010/011). Only decks with the same review algorithm
  receive the deck.
- **Trash and Undo.**
  - The Undo toast lasts 8 seconds, and persists under TalkBack (INV-UI-003).
  - A refused Undo says why: "Can't undo. {reason} Restore it from Trash and choose a deck."
  - Moving the open deck to the Trash steps back to its parent first, and the toast survives the
    step back (C-L5).
- **Reorder.**
  - Drag, plus Move up / Move down for TalkBack.
  - Only under the Manual sort with at least two decks.
  - The search field, summary, due strip and sort pill hide while reordering, and return with Done.
- **States built in P4:** `root_overflow`, `root_reorder`, `root_create`, `root_rename`,
  `root_delete`, `root_trashed`, `deck_overflow`, `deck_move`, `deck_delete`, `deck_trashed`.
- **Closing work:**
  - the SP3b-wide Impeccable pass;
  - the Opus review of the whole SP3b diff;
  - the full `golden-compare` page;
  - the reference-implementation record (§9).

## 6. State trace (SCR-DECK-001, 23 states)

Each state names its condition, its composition, its proof, and whether it has a golden. A state
with no golden is covered by a widget test.

| State | Condition (`DeckLevelState`) | Composition | Proof | Golden |
|---|---|---|---|---|
| `root_loaded` | root, `level` has data, ≥1 deck | header, search trigger, due strip (if cards), list header, rows, FAB | widget | light, dark |
| `root_loading` | root, `level` loading | header kept, `MxSkeleton` rows in the row's shape | widget | light (owner, R1) |
| `root_empty` | root, 0 decks | `MxEmptyState`: Create deck, Browse starter decks, footnote | widget | light, dark |
| `root_error` | root, `level` error | `MxErrorState` "Couldn't load your library" + Retry | widget, controller | light (owner) |
| `root_search` | tap on the search trigger | navigate effect to SCR-SEARCH-001 stub | widget (location) | — |
| `root_sort_filter` | sort sheet open | `MxBottomSheet`: sort `MxOptionRow`s with hints, due-only `MxSettingsRow` toggle, Done | widget | light, dark |
| `root_due_empty` | due filter on, 0 due | "Nothing due right now" + Show all decks | widget | — |
| `root_overflow` | `⋮` on a root row | action sheet of `MxActionSheetCommandRow`s, Reorder included | widget | light, dark |
| `root_reorder` | reorder mode | rows only (search, due strip, pill hidden), drag handles, Done | widget, controller | light, dark |
| `root_create` | create dialog | `MxDialog` with `MxTextField`, scheduler choice, discard confirm | widget, controller | — |
| `root_rename` | rename dialog | `MxDialog` with `MxTextField`, inline errors | widget, controller | — |
| `root_delete` | Move to Trash confirm | `MxDialog` with counts, the deck in quotes; confirm spins | widget, controller | light, dark |
| `root_trashed` | after trash | `MxSnackbar` with Undo (8s, persists under TalkBack); refused Undo copy | widget, controller | light, dark |
| `deck_loaded` | open deck, holds decks | app bar, breadcrumb, summary card, Sub-decks, rows, FAB | widget | light, dark |
| `deck_empty` | open deck `unset` | `MxEmptyState`: New card, New sub-deck, Import (outline); no FAB | widget | light, dark |
| `deck_max_depth` | open deck at level 10 | no FAB; header "· level 10" | widget | — |
| `deck_loading` | open deck, `level` loading | skeletons under the summary card | widget | — |
| `deck_error` | open deck error | `MxErrorState` + Retry | widget, controller | — |
| `deck_not_found` | `view` rejected `notFound` | "This deck is no longer here" + Back to Library + Open Trash | widget, controller | light (owner) |
| `deck_overflow` | `⋮` on a sub-deck | sub-deck action sheet | widget | — |
| `deck_move` | move picker | `DeckPickerSheet`, same-algorithm targets only | widget, controller | — |
| `deck_delete` | sub-deck Move to Trash confirm | as `root_delete` | widget, controller | — |
| `deck_trashed` | after a sub-deck trash | as `root_trashed`; the open deck steps back to its parent first | widget, controller | — |

**Further screen goldens (owner, R1):**
- `scr_deck_001__tablet__light`: the rail and the 720 column.
- `scr_deck_001__large_text__light`: 2.0× text on `root_loaded`.

## 7. Document corrections (made at their source, each with a ruling)

- **SCR-DECK-001:**
  - the row tile is 40, the mastery bar 4, and rows sit 16 apart (R4);
  - `LibraryHeader` replaces "(large)" (R3);
  - add the session sort/filter ruling (R5);
  - the three-count row resolves the spec's "IMPLEMENTATION GAP" note;
  - its catalog and Golden lines follow §6.
- **DESIGN.md:**
  - contracts for every component in §5;
  - a catalog row for `LibraryHeader`;
  - SP3b statuses go `planned` → `built` within their phase;
  - path rules for the `app-shell`, `product-semantic` and `feature:` layers.
- **ARB (en, vi):** updated to the spec's copy. Examples:
  - "Couldn't load your library" and its body;
  - "Search decks", "Move here", "Create deck";
  - the move title and body, and the scheduler hints.

  Keys of this screen that the spec no longer uses are removed.
- **docs/NAVIGATION.md:** unchanged, unless the shell work finds a gap. A gap is raised as a ruling.

## 8. Testing and goldens

- **Controller tests** (fake use cases): state transitions, double-submit guards, rejection-to-copy
  mapping, and effects consumed exactly once.
- **Widget tests** (`ProviderScope` overrides):
  - every state in §6;
  - navigation by the location reached;
  - semantics, RTL, text scale 1.5 and 2.0, 48 targets.
- **One integration test** on a real Drift database, with the existing `libraryTest` and
  `pumpMemoxApp`: cold start → create a deck → open it → move it to the Trash → Undo.
- **Domain and data.** The existing 121 deck tests stay green unchanged.
- **Goldens:**
  - fake data through overrides, a fixed clock, the Linux container only (`run_goldens.sh`);
  - a `golden-compare` page for every phase that changes goldens.

## 9. Definition of done

SP3b is done only when all of these hold:
1. The whole SCR-DECK-001 contract is traced (§6).
2. No state is left out.
3. The shell and navigation work (P1).
4. The product-semantic and deck components the screen needs are built.
5. The domain and data are intact.
6. Accessibility passes.
7. The responsive layouts pass.
8. Light and dark pass.
9. Impeccable critique and audit are done.
10. The screen goldens pass.
11. The full gate is green.
12. The controller, state and composition architecture is recorded as the SP3c reference.

The reference record is a "Reference implementation" section in the `flutter-feature-slice`
skill, or an ADR. It points at the SCR-DECK-001 code and states the §4.2 flow.

Also:
- `lib/app/placeholder/` is deleted.
- The SP3a debts whose SP3b triggers fired are handled and recorded.
- A whole-branch Opus review is done, and the full `golden-compare` page is built.

## 10. Risks

- **Glass blur cost.** A `BackdropFilter` behind the bar can cost frames on low-end Android. Limit
  it to the bar's bounds; the audit checks it.
- **Reorder accessibility.** Drag is not reachable by TalkBack. The Move up / Move down actions are
  part of the contract, not polish.
- **Effects.** One-shot effects replayed on rebuild are the common bug. The previous-value check and
  the clear-after-consume rule are tested.
- **Copy drift.** The ARB still holds V8 copy. R4 makes the screen spec the source, and each key the
  screen uses is checked against it.

## 11. Handoff to SP3c

SP3c starts from:
- the real shell, with stubs for its screens;
- the reference implementation (§9);
- the product-semantic components;
- `DeckPickerSheet`, for CARD, TRANSFER and TRASH;
- the deferred asks recorded in the SP3a close-out.
