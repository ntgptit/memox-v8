# FE-B1: the Trash UI — design

Status: approved 2026-09-26 · Path: architectural · Owner rulings 2026-09-26 (§3), amended after the pre-plan critique (`.impeccable/critique/2026-09-26T10-32-30Z__trash-kit.md`): D6, D13–D15

## 1. Intent

BE-B1 moved every delete of a deck or a card to the Trash (spec
[2026-09-25-trash-backend-design.md](2026-09-25-trash-backend-design.md); its §10 is
the contract for this work), but the app still says "deleted for good" and has no way
to see or restore what it moved. FE-B1 closes UC-TRASH-001 on the screen:

- the delete dialogs and toasts say "Move to Trash", and deleting one item offers
  **Undo** (BR-TRASH-001, BR-TRASH-008);
- screen 06 (kit "Trash", 15 states) lists what is in the Trash, restores it to a target
  the person picks, and deletes it for good (BR-TRASH-006, 010, 011, 012);
- the auto-purge runs when the app starts and resumes and when the Trash opens
  (BR-TRASH-009, UC A4);
- every "no longer here" state says where the item went and opens the Trash.

Success means three things:

- every state of kit 06, and the Trash states of kits 01, 07, 09 and 10 that §5 lists,
  is built from `Mx*` widgets;
- each UC-TRASH-001 flow (main, A1–A6, E1–E6) has a test;
- no copy anywhere says a delete is permanent, except the Trash's own "Delete
  permanently".

## 2. Context (2026-09-26)

- **Backend.**
  - `lib/features/trash/` holds the read model and seven use cases. The read model is
    `TrashEntry`, a `TrashDeckEntry` or a `TrashCardEntry` with `origin` and `expiresAt`.
  - `deck` and `card` hold `DeleteDeckUseCase` and `DeleteCardsUseCase`, which already
    move to the Trash, and the two Undo use cases.
  - None of the trash use cases has a presentation provider yet.
- **The UI today.**
  - The deck delete dialog (`deck_delete_dialog_widget.dart`) and the card delete
    dialog (`card_delete_dialog_widget.dart`) say the delete is permanent. The toasts
    say "deleted".
  - The gone states say "It was deleted…" and offer no way to the Trash.
  - Trash is a line of the Library's Coming soon sheet.
  - The screen-handoff index carries the shared rule "Delete is permanent in V8.0".
  - The UI-base debt register has rows 87 (the card detail's Open Trash waits for Trash)
    and 94 (the open deck's "Deck deleted" toast).
- **The kit.** Every state below is captured in `docs/shared/ui/screen-handoff/img/`:
  - screen 06: all, cards, decks, actions, restoreTarget, noTarget, restored,
    undoRefused, selection, purgeConfirm, purged, youngerInside, empty, loading, error;
  - screen 01: rootOverflow, rootDelete, rootTrashed, deckDelete, deckTrashed,
    deckNotFound;
  - screen 07: delCard, trashed, delDeck;
  - screen 09 delConfirm and notFound, and screen 10 notFound, each gone state with
    "Open Trash" (captured by plan 1);
  - screen 12 staleSelection.

## 3. Decisions

| # | Decision | Choice | Source |
|---|---|---|---|
| D1 | Where the Trash opens | A Trash icon on the Library app bar, beside Coming soon. Coming soon drops its Trash line and keeps the others. The kit draws three icons; starter decks and tags are not built | Owner 2026-09-26 |
| D2 | The route | `/decks/trash` on the root navigator, as the import is: a full-screen task above the shell, with no bottom bar, as kit 06 draws it | This spec |
| D3 | Undo | A snackbar after moving **one** deck or **one** card to the Trash, for **8 seconds**, with the action "Undo" | Owner 2026-09-26; BR-TRASH-008 |
| D4 | Several cards | The snackbar "{n} cards moved to Trash" with the action "Open Trash", and no Undo | Owner 2026-09-26; BR-TRASH-008 |
| D5 | Auto-purge | `app/` calls `PurgeExpiredTrashUseCase` once at start and on every resume (`AppLifecycleListener`). The Trash screen calls it when it opens. Nothing covers the Trash when it would regain focus, because only its own sheets and dialogs cover it and the resume call covers a return from another app. The list is a stream, so a purged row leaves in place | Backend spec §10; UC A4 |
| D6 | A purge the store blocks | The report's `blocked` batches stay. A note at the foot of the list, where the kit draws it, gives one sentence per blocked batch: "“{deck}” still contains an entry deleted earlier (“{entry}”). It can be removed for good once that entry is gone." It uses the warning tone, unlike the policy note, and it goes when the list next changes. The kit's `youngerInside` says "deleted later"; invariant 36 allows only the reverse | Backend spec §8; invariant 36; owner after the critique |
| D7 | Rejection copy | The five D16 values keep their strings: `targetNotFound`, `targetInTrash`, `rootRestoresToTopLevel` and `subDeckNeedsParent` for decks, and `targetInTrash` for cards. Where the kit draws a refusal it names the deck; our values carry no name, so the message wraps the value's string (§5) | Backend spec D16 |
| D8 | Selection | "Select" in the app bar, or a long-press on a row. The first pick locks the kind: the other kind's rows cannot be picked, and the kit's note says why | BR-TRASH-011 |
| D9 | Delete for good | The kit's dialog: its count, the lost study history, "Keep in Trash" as the default focus, and the destructive tone only on "Delete {n}" | BR-TRASH-011, UC A3 |
| D10 | Plans | One spec, two plans. Plan 1 covers the delete flows, Undo and the copy, because the app misleads today. Plan 2 covers screen 06 and every way into it: the Library icon, the Open Trash actions and the auto-purge | Owner 2026-09-26 |
| D11 | Gone states | The deck, card editor and card detail "no longer here" states take the kit's copy and gain "Open Trash" beside their back action. The card create state for a gone deck takes the deck's wording | Kit 01, 09, 10 |
| D13 | Move to Trash from the card editor | Kit 09's "More" card at the foot of the edit form: "Move this card to Trash", "Leaves {deck} and can be restored from Trash for 30 days, schedule and history included.", and an outline "Move to Trash". It opens the one-card dialog of §5. On Ok the editor closes to the card list, which shows the Undo snackbar. Closes UI-base row 82 | Kit 09; owner after the critique |
| D14 | Undo under TalkBack | A snackbar with an action stays until it is acted on or replaced while `MediaQuery.accessibleNavigation` is on (WCAG 2.2.1). Otherwise it times out after 8 seconds (D3). `showMxSnackbar` replaces the snackbar on screen instead of queueing behind it, so a snackbar that stays never blocks the next | Critique P1; owner after the critique |
| D15 | Busy confirms and full labels | Move to Trash, Restore and Delete {n} spin (`MxSheetActions.isConfirmLoading`) and ignore a second tap. A Trash row is one TalkBack node carrying its full name, kind, age, origin path and time left, whatever the ellipsis hides | Critique P3 |
| D12 | Export stale copy | The export's stale-selection banner takes the kit's "moved to another deck or sent to Trash" wording. It closes FE-B3's X11, which existed only because there was no Trash | Kit 12 |

## 4. Structure

```
lib/features/trash/presentation/
├── providers/      the seven trash use cases
├── controllers/    trash_controller.dart: the filter, the kind-locked selection,
│                   restore and purge, with their busy state and last problem
├── states/         trash_state.dart
├── screens/        trash_screen.dart (kit 06)
└── widgets/
    ├── items/      trash_entry_row_widget.dart
    ├── sections/   trash_filter_widget.dart, trash_selection_bar_widget.dart
    ├── overlays/   trash_entry_actions_sheet_widget.dart,
    │               trash_restore_sheet_widget.dart (deck and card targets),
    │               trash_purge_dialog_widget.dart
    └── support/    trash_labels_widget.dart (time left, origin, rejection copy)
```

- **Deck and card.** Each keeps its delete flow and gains the Undo snackbar in its own
  presentation (D3), through its own Undo use case, which gets a provider there.
- **Callbacks from `app/`.** Every "Open Trash" outside screen 06 is a callback wired in
  `app/`, as the import and export entries are: the several-cards snackbar, the refused
  Undo and the gone states. `deck` and `card` never import `trash`.
- **`app/`.** It holds the route (D2), the Library's `onOpenTrash`, those callbacks,
  and the auto-purge listener (D5).
- **The import map is unchanged.** `trash` already imports `deck` and `card`.

## 5. The delete flows (plan 1, apart from Open Trash)

- **Deck.** The `⋮` of a row, or of the open deck, reads "Move to Trash", with the
  sub-line "Recoverable for 30 days".
  - The dialog has the Trash glyph and the title "Move this deck to Trash?". Its body
    is "“{deck}” goes to Trash with its {n} sub-decks and {m} cards." Its note is
    "Recoverable from Trash for 30 days. Any open study session on these cards ends."
  - Its actions are Cancel and "Move to Trash". Move to Trash is primary, not
    destructive, and carries the Trash glyph.
  - When the deck has gone to the Trash, the snackbar reads "“{deck}” moved to Trash ·
    {n} sub-decks, {m} cards", with Undo (D3).
  - Deleting the open deck still steps back to its parent first (C-L5). The snackbar
    replaces "Deck deleted" (row 94).
- **Card editor (D13).** The "More" card at the foot of the edit form opens the one-card
  dialog below. On Ok the editor closes to the card list, which shows the one-card
  snackbar with Undo.
- **Cards,** from the bulk bar's Delete.
  - **One card:** the kit's dialog. Its title is "Move this card to Trash?", with the
    card's front over its back. Its note is "Recoverable from Trash for 30 days, with its
    schedule and history. Other cards are unaffected." The snackbar reads "“{front}”
    moved to Trash", with Undo.
  - **Several cards:** the title is "Move {n} cards to Trash?", with no preview. The
    note is "Recoverable from Trash for 30 days, with their schedule and history. Other
    cards are unaffected." The snackbar reads "{n} cards moved to Trash" (D4); plan 2
    adds its "Open Trash".
- **Undo (A1).** The item goes back where it was.
  - A refused Undo (E3) shows the snackbar "Can't undo — {reason} Restore it from Trash
    and choose a deck.", where `{reason}` is the D16 string. Plan 2 adds "Open Trash".
  - The item stays in the Trash.
  - The kit shows this refusal on screen 06 with "from here", but an Undo happens
    where the item was deleted.
- **Gone states (D11).**
  - **Deck:** "It was moved to Trash or deleted while you were away. Anything in Trash
    can still be restored."
  - **Card editor:** "It was moved to Trash while you were editing. Your unsaved changes
    were not applied; the card can still be restored from Trash."
  - **Card detail:** "It was moved to Trash while you were away. It can still be
    restored from Trash, with its history."
  - Plan 2 adds their "Open Trash".
- **Export (D12).** The stale selection reads "It was moved to another deck or sent to
  Trash meanwhile. Nothing was exported. Refresh the selection and export again."
- **The shared rule.** The index rule "Delete is permanent in V8.0" becomes "Delete
  moves to the Trash (UC-TRASH-001)". The detail files of 01 and 07 lose their
  permanent-delete deviations.

## 6. Screen 06 (plan 2)

- **Header.** Back, "Trash", and "Select", which is hidden when the Trash is empty.
  Below it, the note "Kept for 30 days from deletion, then removed automatically.
  Restoring asks where the item should go."
- **Filters.** All · Cards · Decks, each with its count, hidden when the Trash is empty
  (A6). Under them, "{n} entries · newest first".
- **Row.**
  - The kind glyph, then the name. A card shows "front · back".
  - The sub-line reads "Card · deleted {ago}", or "Deck · {n} sub-decks · {m} cards ·
    deleted {ago}".
  - Then "Was in {origin joined by ›}", or "Was in Top level".
  - The time left is at the top right: "{d} days left", or "{h}h left" under a day. It
    is in the warning ink under 3 days.
  - `⋮` opens the actions sheet.
- **Actions sheet.**
  - Its header is the name, then "{kind} · deleted {ago} · was in {parent}".
  - "Restore…" has the sub-line "Choose which deck it goes to".
  - "Delete permanently" has the sub-line "Cannot be undone · history lost", in the
    destructive tone.
- **Restore (UC steps 5–7).**
  - The sheet's title is "Restore “{name}” to…". A card's sheet adds "Its schedule,
    history, flag and tags come back with it. Only decks in the same tree that hold
    cards or are empty are offered."
  - A card lists `WatchCardRestoreTargetsUseCase`. Each target row shows its name, then
    its path and card count, or "Empty".
  - A deck lists `DeckRestoreUnder` decks, or offers the single row "Top level" for
    `DeckRestoreTopLevel`.
  - With no target (E1), the sheet shows "Nowhere to restore right now", why, and OK.
  - A refusal (E2) shows its D16 copy in the sheet. The list follows the stream.
  - When the restore is done, the snackbar reads "“{name}” restored to {deck}", or "to
    Top level".
- **Selection (A2).**
  - The header reads "✕ {n} cards selected" or "✕ {n} decks selected", with the
    overline "{n} of {m} cards" (or decks). The filters are hidden.
  - The other kind's rows stay listed but cannot be picked, and the kit's note says why.
  - The bar holds "Restore {n}…" (primary) and "Delete for good" (destructive
    outline).
  - Restoring several asks for one target that takes them all, because the backend
    intersects their targets.
- **Delete for good (A3).**
  - The dialog (D9) is titled "Delete {n} {cards|decks} permanently?", with the body
    "They disappear for good, together with their study history. This cannot be
    undone."
  - Its actions are "Keep in Trash" (focused) and "Delete {n}".
  - When the purge is done, the snackbar reads "{n} {cards|decks} deleted permanently".
  - Blocked batches get the note of D6. Missing ones (E6) need nothing: the list
    refreshes itself.
- **Other states.**
  - Loading shows skeleton rows.
  - Empty shows "Trash is empty" and "Decks and cards you delete stay here for 30 days
    before they are removed for good.", with no note, no filters and no Select.
  - Error shows "Couldn't open Trash" and "Your data is safe on this device. Try again
    in a moment.", with Retry.
- **Every other way into the Trash** (plan 2): the Library icon (D1), the several-cards
  snackbar and the refused Undo (§5), and the gone states (D11).

## 7. Errors

- A delete, restore, Undo or purge that throws leaves as the `Failure` of
  `mapDatabaseError` after the rollback. The screen shows the error copy with Retry
  and keeps the selection (E5).
- No message carries an id, a path or a SQL fragment (BR-CORE-005). The names shown are
  the person's own text on their own device.

## 8. Tests

| Layer | What |
|---|---|
| Controller | the filter; the kind lock of the selection; restore and purge mapping every outcome (ok, each rejection, blocked, missing, a thrown `Failure`); a second tap while busy does nothing |
| Widget, plan 1 | both delete dialogs (one card, several, a deck); the editor's Move to Trash; Undo for a deck and a card; a refused Undo; the snackbar for several cards; the gone copy; the snackbar lasting 8 seconds, and staying under TalkBack; a second snackbar replacing the first; a second tap on a busy confirm |
| Widget, plan 2 | every state of kit 06 over the real backend; the restore sheet for a card, a sub-deck, a root and no target; the purge dialog's default focus; every Open Trash |
| Golden | 01 deckDelete and deckTrashed; 07 delCard and trashed; 09 the More card and delConfirm; 06 all, selection, restoreTarget, purgeConfirm and empty — each in light and dark |
| Route | Library → Trash → Back; Open Trash from a snackbar and from a gone state |
| Lifecycle | a resume runs the auto-purge, and an expired row leaves the open list |
| Audit | the `TrashScreen` visual audit at 1x and 2x |

## 9. Documents

- **Screen handoff.**
  - `docs/shared/ui/screen-handoff/06-trash.md` is new, and the index gains its row.
  - The detail files of 01 and 07 get the move-to-Trash and Undo states.
  - The shared rule changes (§5).
- **UI-base debt register.**
  - Rows 82 (D13) and 87 are closed by FE-B1.
  - Row 94 is superseded: the open deck's toast is the D3 snackbar.
  - A row is added for each deviation this spec accepts: D6, D7's wrapped refusal, and
    the Undo refusal shown where the item was deleted.
- **Use cases and features.** UC-TRASH-001's `code:` and its acceptance criteria;
  `docs/features/trash/README.md`.
- **WBS.** `docs/wbs_FE.md` FE-B1.
- **Export.** `12-card-export.md` closes X11 (D12).

## 10. Out of scope

- Starter decks and tags stay under Coming soon (FE-B4, FE-B2).
- No change to the backend, the schema or the retention (720 hours).

## 11. Risks and rollback

| Risk | Mitigation | Rollback |
|---|---|---|
| The resume listener runs a purge while a delete is in flight | The purge is one transaction and skips batches that have not expired | Drop the resume call; keep the calls at start and on opening |
| An Undo snackbar outlives its screen, because the open deck is gone | The snackbar lives on the root `ScaffoldMessenger`, and its action calls the use case, not the screen | — |
| Plan 1 ships without plan 2 | Plan 1 alone is coherent: the copy is true and Undo works. Only the Open Trash actions wait for plan 2 | — |
