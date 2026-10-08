# MemoX V8 — Import from the Library

Status: design approved in chat 2026-10-08, spec in owner review · Path: architectural

## 1. Intent

A person who opens MemoX for the first time sees an empty Library offering "Create deck"
and "Browse starter decks". Nothing there says the app can import a file. Card import
(UC-TRANSFER-001, screen 11) exists, but it opens only from a sub-deck that is `unset` or
holds cards. From an empty Library, reaching it takes three manual steps: create a root
deck, create a sub-deck under it, then pick "Import cards from a file" in that sub-deck's
empty state.

The owner's ask (2026-10-08): import must be reachable from the Library itself. That
means the empty Library first, and the Library with decks too.

Success means:

- the empty Library offers "Import cards from a file", and one dialog takes the person
  from there to the import wizard;
- the Library with decks offers Import in its app bar, and the same dialog either picks an
  existing sub-deck or creates a new one;
- creating the target never leaves a root deck without its sub-deck, because both are
  written in one transaction;
- the import wizard, its route and BR-TRANSFER-001 are unchanged;
- every new state has goldens, light and dark, and the gate passes.

## 2. Context

- Root decks hold only sub-decks (ADR-006, BR-DECK-004). A new sub-deck is `unset`
  (BR-DECK-006), and an import into an `unset` sub-deck makes it `card` (BR-TRANSFER-005).
- A root deck's review algorithm is chosen at creation and never defaulted (BR-SRS-001).
  Every descendant inherits it (BR-DECK-024).
- Deck names may repeat (BR-DECK-021). They are 1–200 characters (BR-DECK-020).
- The empty state, `MxEmptyState`, already takes a tertiary action. The `unset` deck's
  empty state uses it for "Import cards from a file" (`deckUnsetImport`).
- `DeckLevelScreen` already receives `onImportCards(deckId)`, and the router turns it into
  `AppRoutes.importCards(deckId)`.
- `cardMoveTargets` (`card_queries.drift`) lists the eligible sub-decks of **one** tree.
  Nothing lists the eligible sub-decks of the whole Library.

## 3. Decisions

| # | Decision | Source |
|---|---|---|
| D1 | The target deck is created **before** the wizard opens, then the existing wizard opens on it. If the person cancels the wizard, the created decks stay, just as if they had been made by hand | owner 2026-10-08 |
| D2 | Two entry points: the empty Library's tertiary action "Import cards from a file", and an Import icon in the Library app bar when it holds decks (Starter decks · Tags · Trash · Import) | owner 2026-10-08 |
| D3 | One dialog, "Import target", serves both entry points. **Deck** is "New deck" or an existing root deck. **Sub-deck** is "New" (a name) or "Existing" (an eligible sub-deck of that root) | owner 2026-10-08 |
| D4 | With "New deck", or an empty Library, or a root with no eligible sub-deck, the sub-deck is "New" only, and the segmented control is hidden | owner 2026-10-08 |
| D5 | A new sub-deck sits directly under the chosen root (level 2). Creating one deeper is out of scope | this spec |
| D6 | New root + new sub-deck are written in **one** transaction through the deck repository. An existing root + a new sub-deck reuses `createSubDeck`. An existing sub-deck writes nothing | this spec |
| D7 | The dialog and its use cases live in the `deck` feature. It returns the target sub-deck's id, and the Library calls its existing `onImportCards(id)`. `transfer` and the import route do not change | this spec, flutter-architecture |
| D8 | The import route stays on the root navigator. The dialog closes before the wizard is pushed | screen 11 |

## 4. The dialog

`MxDialog`, title "Import cards", subtitle "Cards go into a sub-deck. Pick one, or name a
new one." Its content, top to bottom:

1. **Deck.** An `MxChipTrigger` labelled "Deck", reading "New deck" or the root's name.
   It opens a bottom sheet of options: "New deck" first, then the root decks in Library
   order. The empty Library has no roots, so the chip is hidden and the dialog is in
   "New deck" mode.
2. **With "New deck":** the name field ("Deck name") and the review algorithm
   `MxSegmentedTray` with its note, exactly as in the Create deck dialog. Nothing is
   chosen up front (BR-SRS-001); Continue without an algorithm says "Choose how the cards
   are reviewed."
3. **Sub-deck.** When the root has eligible sub-decks, an `MxSegmentedTray` offers
   "New sub-deck" · "Existing".
   - **New:** the name field "Sub-deck name". While the person has not edited it, it
     follows the deck name in "New deck" mode. With an existing root it starts empty.
   - **Existing:** an `MxChipTrigger` "Choose a sub-deck" opening the eligible sub-decks
     of the chosen root (`unset` or `card`, any level, BR-TRANSFER-001), each named by its
     path below the root (BR-DECK-021). Continue with none chosen says "Choose a
     sub-deck."
4. **Actions:** `MxSheetActions`, Cancel · Continue. Continue is disabled while the write
   runs (one at a time, as in Create deck).

Validation and leaving:

- An empty or too long name shows the deck rejection already used by Create deck and
  Rename (BR-DECK-020), under the field it belongs to.
- Cancel, Back or a tap outside, once something is typed or chosen, asks the Create deck
  dialog's "Discard this deck?" (UC-DECK-001 A1).
- A write failure (`Failure`) shows the usual snackbar, and the dialog stays.

## 5. Data

- **Use case `CreateImportTargetUseCase`** (deck), one of:
  - new root + new sub-deck → `DeckRepository.createRootWithSubDeck(rootName,
    schedulerType, subDeckName)`, one Drift transaction, returning the sub-deck. Each
    half applies the same rules and rejections as `createRootDeck` and `createSubDeck`;
    a rejection of either half writes nothing.
  - existing root + new sub-deck → `DeckRepository.createSubDeck`.
  - existing sub-deck → no write; the id is returned as is.
- **Use case `WatchImportTargetsUseCase`** (deck): a stream of the live root decks in
  Library order and, per root, its eligible sub-decks with their path. It is backed by one
  new query in `deck_queries.drift`, modelled on `cardMoveTargets` but over every tree,
  excluding trashed decks (`delete_batch_id IS NULL`).
- Sync is unchanged: the decks are written through the repository that already queues
  them.
- A target that stops qualifying between the dialog and the commit is refused by the
  wizard's commit, which is the existing UC-TRANSFER-001 E4.

## 6. Entry points

| Where | What | Copy |
|---|---|---|
| Library, `rootEmpty` | `MxEmptyState` tertiary action, after "Create deck" and "Browse starter decks" | "Import cards from a file" (`deckUnsetImport`) |
| Library with decks | 4th app bar `MxIconButton`, after Trash; hidden in reorder mode, as the others are | icon `AppIcons.fileUp` (the import glyph of screen 11), semantic label "Import cards" |

The FAB, the deck rows and their action sheets do not change.

## 7. Documents

- UC-TRANSFER-001: the trigger gains the two Library entry points. A new alternative flow
  A6 "Deck đích chọn hoặc tạo từ Library" points to UC-DECK-001/UC-DECK-004 for the
  create, and the precondition still holds once the dialog closes.
- Screen 01: `rootEmpty` gets its tertiary action, the app bar row gets Import, and a new
  state row `rootImportTarget` links the dialog's goldens. The copy list is updated.
- Screen 11: Entry points gains the Library. A section "Import target dialog" holds
  §4's layout and copy.
- `docs/features/transfer/README.md`: the screen → UC table gains the Library.
- `DESIGN.md` does not change: no new token or component.

## 8. Tests

- Repository/DAO: `createRootWithSubDeck` writes both or neither (a rejected sub-deck
  name leaves no root); the import-targets query lists only live `unset`/`card` sub-decks,
  every tree, with paths.
- Use cases: the three branches of `CreateImportTargetUseCase`.
- Widget: the dialog in each mode (empty Library, new deck, existing root with and
  without eligible sub-decks, existing sub-deck); the sub-deck name following the deck
  name until edited; the missing-algorithm and missing-sub-deck messages; discard on
  leave; the empty Library's tertiary action and the app bar icon calling
  `onImportCards` with the right id.
- Goldens (light, dark): `library_import_target_new` (empty Library mode) and
  `library_import_target_existing` (existing root, Existing chosen). `library_empty_*`
  and `library_decks_*` are updated, so the owner gets the golden review page.

## 9. Out of scope

- "Import cards" on a root deck's action sheet.
- Creating the new sub-deck below level 2, or picking a parent other than a root.
- Deleting decks the dialog created when the wizard is cancelled (D1).
- Any change to the import wizard, its route, or BR-TRANSFER-001.

## 10. Risks and rollback

| Risk | Mitigation | Rollback |
|---|---|---|
| A 4th app bar icon crowds the large app bar at 360 dp or large text | Golden at 360 dp. The Impeccable critique before the plan rules on the placement | Move Import into the empty state only, and drop the icon |
| The dialog grows too tall at large text scale | It scrolls inside `MxDialog`, as Create deck does. The text-scale widget test covers it | — |
| Empty decks pile up when people cancel the wizard | Accepted (D1). They are visible and deletable like any deck | Switch to creating the target at commit time (a later spec) |
