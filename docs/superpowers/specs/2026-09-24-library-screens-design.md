# MemoX V8 — Library screens design

The first presentation layer: the Library tab over the merged deck and card backend (#26), built from the Flutter UI base (#19–#24). UI only: no backend file changes.

## 1. Intent

The owner opens the app between other things, on a phone, often offline (`PRODUCT.md`). The Library tab answers two jobs:

- **Primary:** what is due today, and in which deck.
- **Secondary:** build and tend the library, where adding words must be fast.

Success:

- The first viewport of Library shows the level's workload: overdue · due today · new.
- From an open card deck, a new card is at most two taps away, and entry is continuous.
- Every count and status comes from the read models (`DeckLevel`, `DeckTile`, `CardDisplayStatus`, `DeckScheduleStatus`). The UI never re-derives them.

## 2. Decisions

Settled in brainstorming and in the Impeccable shape round (2026-09-24):

| # | Decision |
|---|---|
| D1 | Scope is the whole Library: everything the #26 backend exposes for decks and cards, including filters, search, bulk actions, tags on cards, review history and manual reorder. Delivered in four phases (§10). |
| D2 | Screen design comes from an Impeccable shape brief (§6), inside the existing visual world: the V3 handoff and the UI base. No new visual world. |
| D3 | Library's root puts today's work first: the level workload line and per-deck due counts lead. Management actions are secondary. |
| D4 | Phones only. Tablet layouts are deferred (`PRODUCT.md`, spec UI-base §9 row 63 stays open). |
| D5 | A card is added and edited on its own screen, not in a bottom sheet. |
| D6 | The AA contrast failures of status text on this surface are fixed here with status ink tokens (§7). |
| D7 | Manual reorder is a drag mode with drag handles and TalkBack move actions. |
| D8 | `app/` composes the features (§3). `deck` never imports `card`, so the router injects the card content into the deck screen. |

## 3. Structure

The folders follow ADR-011: `presentation/{screens,controllers,states,providers}` and `presentation/widgets/{sections,items,overlays,support}`, one level deep, each folder created only with its first real file.

```
lib/features/deck/presentation/
  providers/    one provider per deck use case
  states/       deck level query (sort, filter), reorder mode
  controllers/  deck actions: create root, create sub-deck, rename,
                delete, move, change scheduler, reorder
  screens/      deck level screen (Library root and any open deck),
                deck search screen
  widgets/      sections: workload header, deck list, unset state
                items: deck row, reorder row
                overlays: create/rename/delete dialogs, action sheet,
                          move sheet, scheduler sheet, sort/filter sheets
                support: rejection → copy mapping, drag handle
lib/features/card/presentation/
  providers/    one provider per card use case
  states/       card list query, selection
  controllers/  card actions (bulk), card editor
  screens/      card editor screen, card detail screen
  widgets/      sections: card list section (injected into the deck
                screen), detail sections, history section
                items: card row, tag input chip
                overlays: move sheet, delete dialog, tag sheet,
                          sort sheet
                support: rejection → copy mapping, status copy
lib/app/router/ Library routes and the deck ↔ card composition
```

Import rules stay as they are:

- The feature import map in `test/architecture/boundary_rules.dart` is unchanged: `srs → ∅`, `tags → ∅`, `deck → {srs}`, `card → {deck, srs, tags}`.
- `presentation/` imports its own `domain/` and `di/`, and other features' `domain/{entities,models,repositories,failures}/` or `di/` only.
- No feature imports `app/`.

## 4. Navigation

The `/decks` branch of the stateful shell keeps its place. The Library's routes are its children:

| Path | Screen |
|---|---|
| `/decks` | `DeckLevelScreen(deckId: null)`, the Library root |
| `/decks/deck/:deckId` | `DeckLevelScreen(deckId)`. Pushed once per level, so system Back climbs one level. |
| `/decks/search` | `DeckSearchScreen` |
| `/decks/deck/:deckId/cards/new` | `CardEditorScreen` in create mode |
| `/decks/card/:cardId` | `CardDetailScreen` |
| `/decks/card/:cardId/edit` | `CardEditorScreen` in edit mode |

Rules:

- Paths are constants in `lib/app/router/app_routes.dart`. Features receive navigation as callbacks (`onOpenDeck`, `onAddCard`, `onOpenCard`, `onEditCard`, `onSearch`) and never build a path.
- `DeckLevelScreen` takes `cardContent: Widget Function(String deckId)`. The router passes the `card` feature's `CardListSection`.
- A breadcrumb ancestor tap pops back to that level. The root crumb pops to `/decks`.
- Re-tapping the Library tab returns to `/decks` (existing shell behaviour).
- An open deck that stops existing emits `Rejected(notFound)`. The screen pops to its parent and shows a snackbar. A card detail whose card is gone does the same (BR-CARD-019).

## 5. Data flow

Riverpod codegen throughout. Every interaction goes through exactly one use case (AD-12).

**Use-case providers** (`presentation/providers/`): one `@riverpod` function per use case, built from the repository providers in `di/`.

**Reads:**

- Each read model is a `@riverpod` stream family that calls exactly one use case: `deckLevelProvider(parentId, query)`, `deckViewProvider(deckId)`, `deckMoveTargetsProvider(deckId)`, `deckSearchProvider(scopeId, term)`, `cardListProvider(deckId, query, windowSize)`, `cardDetailProvider(cardId)`, `cardMoveTargetsProvider(sourceDeckId)`.
- Widgets render the `AsyncValue`:
  - loading shows skeleton rows;
  - an error shows `MxErrorState` with Retry, which invalidates the provider;
  - data shows the content.
- Review history is paged, not streamed: the history section keeps the pages it loaded (`LoadCardHistoryPageUseCase`, keyset cursor) and loads the next one on "Load more".

**Writes:**

- A controller method calls exactly one use case and returns its `Outcome`. Controllers hold no screen state.
- The calling widget decides the feedback:
  - A `Rejected` reason that belongs to a form field is shown under that field (`MxFieldMessage`). Any other reason is shown in a snackbar.
  - `Ok` closes the dialog or sheet. In the card editor's create mode, `Ok` clears the form and refocuses the front field; in edit mode, it pops the screen.
  - An unexpected `Failure` shows its generic message in a snackbar. No id, path or SQL is ever shown (BR-CORE-005).

**UI state** (`presentation/states/`): small autoDispose Notifiers per screen: the level query (sort, filter), reorder mode, the card list query (filter, sort, search term, window size), and the selection (ids, select-all).

**Rejection copy:** one exhaustive `switch` per feature maps every `DeckRejection`, `CardRejection`, `SrsRejection` and `TagRejection` value to an ARB message. There is no `default`, so a new enum value is a compile error.

## 6. Screens (Impeccable shape brief)

**Mode:** Operate. **Visual authority:** the V3 handoff through the UI base. Screens compose shared widgets and never restyle them.

**Structural thesis: one recursive deck screen, one level at a time.** The Library root is level 0 of the same screen.

### 6.1 Deck level screen (Library root and any open deck)

- **App bar:**
  - The root shows the Library title and a search action.
  - An open deck shows `MxBreadcrumb` and an overflow action that opens the deck action sheet.
- **Content by level:**
  - The root and a `deck`-typed deck show a sub-deck list. On top of it sit the level workload line (`MxWorkloadBreakdownLine`, the focal element) and an `MxListSectionHeader` with two `MxChipTrigger`s: sort (manual, name, recent, due) and filter (all, due). Each opens an `MxOptionRow` sheet.
  - A `card`-typed deck shows the injected `CardListSection` (§6.4).
  - An `unset` deck shows `MxEmptyState` (tone primary) with two actions: create a sub-deck and add a card (UC-DECK-004).
- **Deck row:** `MxListRow` with `MxIconTile`, the name, `MxWorkloadBreakdownLine` in the meta slot, and a chevron.
- **FAB:** create, following `DeckView.createOptions`. A single option acts directly; two options open an action sheet.
- **States:**
  - First run (no deck): `MxEmptyState` "Create your first deck".
  - Filtered to nothing: `MxEmptyState` tone neutral.
  - Loading: `MxSkeletonRow` × 4.
  - Error: `MxErrorState` with Retry, in the local-first voice.
- **Reorder mode** (from the overflow, manual sort only):
  - Rows swap their chevron for a drag handle in a `ReorderableListView`.
  - Each row offers TalkBack custom actions "Move up" and "Move down".
  - A Done action ends the mode.
  - Every drop is one `ReorderDeckUseCase` call (anchor and placement).

### 6.2 Deck dialogs and sheets

- **Create root deck:** `MxDialog` with an `MxTextField` for the name and an `MxSegmentedTray` for the scheduler (eight box, SM-2). An `MxNote` says the scheduler locks after the first review.
- **Create sub-deck, rename:** `MxDialog` with the name field. The name is limited to 200 graphemes and must not be blank; both are shown inline.
- **Delete:** `MxDialog`. The body states how many sub-decks and cards will be deleted permanently (`GetDeckDeletionSummaryUseCase`, BR-DECK-023). The confirm is destructive.
- **Move:** `MxDeckPickerSheet` fed by `WatchDeckMoveTargetsUseCase`. The backend already leaves out ineligible targets. An empty list shows the sheet's neutral empty state.
- **Change scheduler** (root only): a sheet with two `MxOptionRow`s.
  - While unlocked, an `MxInlineBanner` (warning) says the change re-initialises every card's schedule and ends sessions in progress (BR-STUDY-016).
  - While locked, an `MxNote` explains the lock and no option can be chosen. Reset learning is out of scope.
- **Deck action sheet:** `MxBottomSheet` with `MxActionSheetCommandRow`s: Rename, Move, Change scheduler (root only), Reorder, and Delete (destructive).

### 6.3 Deck search

`MxSearchField` plus result rows that show the deck path. A blank term shows nothing (`SearchDecksUseCase` returns an empty stream). Tapping a result opens that deck.

### 6.4 Card list section

- `MxSearchField` (search within the deck).
- `MxFilterChip` × 4 with counts: all, due, new, flagged (`CardListCounts`).
- A sort trigger: newest, due first.
- **Card row:** `MxListRow` with the front as title, the back as subtitle (one line each), an `MxStatusBadge` dot and a flag glyph.
- **Growing window:** the list grows `windowSize` when it nears the end while `hasMore` is true (spec deck-card §8, D10).
- **Tap and long-press:** a tap opens the detail. A long-press enters selection mode; while selecting, a tap only toggles (BR-CARD-020).
- **Selection mode:**
  - The app bar shows the selected count and a close action.
  - Each row shows `MxSelectionCheckbox`.
  - An `MxFooterBar` holds Select all, Flag, Tag, Move and Delete:
    - Select all uses `SelectAllCardIdsUseCase` with the same query.
    - Flag sets or clears the flag explicitly, never toggles (BR-CARD-011).
    - Tag adds or removes one tag through a sheet.
    - Move opens `MxDeckPickerSheet` from `WatchCardMoveTargetsUseCase`.
    - Delete opens a confirmation dialog.
- **States:**
  - An empty deck shows `MxEmptyState` with "Add card" (UC-CARD-001 A3).
  - Filtered or searched to nothing shows the neutral empty state, naming the filter.

### 6.5 Card editor (own screen)

- **Fields:** five `MxTextField`s: front (60), back (240), example, hint and pronunciation (240 each). Each shows a character count against its limit. Required fields are marked. Errors are inline (BR-CARD-001/002).
- **Tags:** a feature-local chip input. Each chip is removable, and adding a tag uses a text field. Limits and invalid names come from `CardRejection`.
- **Flag:** an `MxSettingsRow` with an `MxToggle`.
- **Saving:** an `MxFooterBar` holds Save.
  - Create mode: after `Ok` the form clears, focus returns to the front field, and a snackbar confirms (UC-CARD-001 A4).
  - Edit mode: after `Ok` the screen pops.
- **Keyboard:** the form scrolls, and the footer stays above the keyboard.

### 6.6 Card detail (read-only)

- **Sections:**
  - Content: front, back, example, hint, pronunciation.
  - Tags (`MxTagChip`).
  - Status: `MxStatusBadge` pill, scheduler, due date.
  - Review history.
- **Edit:** the app bar holds the Edit action. Editing is never the tap gesture (BR-CARD-020).
- **Review history:** rows grouped by generation, with "Load more" while a next cursor exists.

### 6.7 Scope boundaries of the brief

- **Production-ready screens:** phone only, en and vi.
- **Untouched:** shared widget contracts and the backend.
- **Anti-goals (not built):**
  - No "Study" button until the study sub-project exists.
  - No tag management, starter decks, Trash, global search, or Reset learning.

## 7. Status ink tokens

The audit measured these status text colours below AA on this surface:

| Text | Background | Ratio | §9 row |
|---|---|---|---|
| StatusBadge learning label | its 12% tint (light) | 1.87:1 | 57 |
| Workload "new" term | surface (light) | 2.81:1 | 60 |
| `statusNew` label | its tint (light, dark) | 2.53:1, 3.80:1 | — |

The fix adds four derived colours to `MxDerivedColors`: `statusNewInk`, `statusLearningInk`, `statusReviewingInk` and `statusMasteredInk`.

- **How each ink is derived:** its status colour, darkened in light and lightened in dark by a stated mix toward `onSurface`, with the ratio chosen per theme so the ink reaches **≥ 4.5:1** both on its 12% tint and on `surface`. This follows the `warningInk` precedent (spec UI-base row 20).
- **What changes:**
  - `MxStatusBadge` and `MxWorkloadBreakdownLine` draw their text in the ink.
  - Dots, fills and tints keep the status colour.
  - The `MasteryRamp` and the donut arc are unchanged.
- **Proof:** a contrast test asserts every pair in both themes.
- **Record:** the UI-base spec §9 gets rows that resolve rows 57 (the badge half) and 60, and narrow row 3 to what remains (the MasteryDonut label).

## 8. Copy and localisation

- Every string is added to `lib/l10n/app_en.arb` (the template) and `app_vi.arb`, each with an `@description`. Keys use the prefixes `deck`, `card` and `library`.
- Plurals use ICU plural forms (for example, the delete summary counts).
- Dates use `DateFormat` for the current locale. Overdue reads "overdue N days" from `DeckTile.overdueDays`.
- The rejection copy (§5) is plain language, and never names ids, paths or SQL (BR-CORE-005).
- Failure copy follows the local-first voice: nothing was lost, then the retry (PRODUCT.md, Brand commitments).

## 9. Verification

**Screen and flow tests run through the real backend:**

- An in-memory Drift database (`test/support/test_database.dart`), the existing fixtures and `FakeDayClock`, with `databaseProvider` and `dayClockProvider` overridden in the `ProviderScope`.
- A test drives the widget, provider, use case and Drift together. Use cases are not mocked.

**Additional tests:**

- **Router:** deep navigation and Back, a breadcrumb pop, and a deck deleted while it is open.
- **Rejection mapping:** every enum value has copy, and no message contains an id, path or SQL.
- **Contrast:** every ink pair in §7, in both themes.
- **l10n:** every new key exists in `app_vi.arb`.
- **Accessibility:** each screen meets `androidTapTargetGuideline` and `labeledTapTargetGuideline`, and renders at text scale 2.0 without an exception.
- **Goldens:** light and dark at 3x per screen and main state: data, empty, error, selection, and a form with errors.

**Gate:**

- The UI-base gate: `dart format`, `flutter analyze`, `flutter test`, `check_architecture.py`, the CI tooling tests, guard `memox-v8` with 0 errors and 0 warnings, and `tools/docs/check.py`.
- Plus `dart run build_runner build --delete-conflicting-outputs` and `.claude/skills/flutter-workflow/scripts/dod_check.sh`, now that codegen exists (spec UI-base §8.3).
- Every phase ends with a whole-branch review on the most capable model.

## 10. Phases

One plan and one PR per phase. A phase's plan is written after the previous phase merges.

| # | Content | Usable result |
|---|---|---|
| 1 | Presentation infrastructure: use-case providers, rejection mapping, route composition, test harness with the real backend. Status ink tokens (§7). Library root: workload line, sort/filter, empty/loading/error states, create root deck. | Opening the app shows the decks and today's work; a deck can be created |
| 2 | Deck tree: the recursive deck screen, breadcrumb, sub-decks and the `unset` state. The deck action sheet: rename, delete with its summary, move, change scheduler, reorder mode. Deck search. | The whole deck tree can be managed (M1) |
| 3 | Card list section: filters, search, sort, the growing window. Selection mode with bulk flag, tag, move and delete. | Cards can be browsed and managed in bulk (M2, M4) |
| 4 | Card editor (continuous create, edit, tags, flag, validation). Card detail and review history. | Cards can be added, edited and inspected (M2) |

## 11. Debt register

The UI-base spec's register (`2026-09-23-flutter-ui-base-design.md` §9) stays the single register for UI debt. This project appends its rows there, marked "library phase N". Contradictions found while building follow the same rule: record, do not silently resolve.

## 12. Out of scope

- The study session and anything that starts one, the Study, Progress and Settings tabs, and Reset learning.
- Tag management (UC-TAG-001), starter decks, Trash, reminders, import and export, and global search.
- Tablet layouts (D4).
- Any backend change. A backend gap found while building is raised as a finding, not patched from `presentation/`.
