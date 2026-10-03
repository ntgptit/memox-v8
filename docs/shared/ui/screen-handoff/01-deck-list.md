<!-- Hand-written screen record. -->

# 01 · Deck list

One recursive screen for the Library root (`/decks`) and any open deck
(`/decks/deck/:deckId`): `DeckLevelScreen`. UC-DECK-001…UC-DECK-006.

## Layout — root

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (large) | "Library", then Starter decks (sparkles, screen 03), Tags (tag, screen 05) and Trash (screen 06) (FE-B2 + FE-B4 D2). |
| Search | `MxSearchField`, trigger mode | Hint "Search decks". A tap pushes `/decks/search` (screen 04). |
| Due strip | `MxCard` (hero) + `MxIconTile` + `MxWorkloadBreakdownLine` | Bolt tile on primary, "N cards due", overdue · today (New is not due, BR-STUDY-068). A tap opens Study home; a trailing chevron says so (critique 2026-09-30, R4). Hidden when the library holds no card. |
| Section header | `MxListSectionHeader` + `MxChipTrigger` | "N DECKS"; pill "Manual ⌄", or "Manual · Due only" tinted primary with the filter on. |
| Rows | `MxCard` per deck, 8 apart | 44 px `MxIconTile` (layers = holds decks, copy = holds cards, folder-open = empty); name on one line with ellipsis; `MxBadge` "N due" when due > 0; meta "N sub-decks · N cards" or "Empty · add cards or a sub-deck"; the mastery bar (`MxLinearProgress.mastery`, 5 tall, 12 under the meta, across the text column, on `surfaceContainerLow`; BR-DECK-026), the bare track for a deck with no card; trailing `⋮` (`MxIconButton`). |
| FAB | `MxFab` | "New deck". |

## Layout — open deck

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` | Back, deck name, `⋮` (the deck's action sheet). |
| Breadcrumb | `MxBreadcrumb` | Library › ancestors › deck. |
| Summary card | `MxCard` (hero) | For a deck holding sub-decks: `MxMasteryDonut` of the level (BR-DECK-026) beside "MASTERED · {algorithm}", "N sub-decks · N cards", overdue · today · new · N scheduled. "Study this deck · {n} due" (primary block `MxButton`; "Study this deck" when only new cards wait) opens the Study Entry, screen 14 (FE-A6 D10); hidden when the subtree holds no card to study. |
| List | as root | Header "Sub-decks" with the sort pill: the summary card states the count (critique 2026-09-30 part 3b). |
| FAB | `MxFab` | "New sub-deck"; none at level 10 (BR-DECK-001), and none on an `unset` deck, whose empty state offers both choices (R9, critique 2026-09-30 part 1). |
| By content type | — | `unset`: empty state with the two create choices (BR-DECK-007) and "Import cards from a file" (screen 11), all text-only block actions, Import as the outline third. `card`: the card list, screen 07. |

## Action sheet

`MxBottomSheet` headed by the deck's name, and `MxActionSheetCommandRow`s without count
subtitles (ruling C-L6):

- **Root deck:** Open deck · Study this deck → screen 14 · Rename · Study options
  ("Cards per session · new-card order") → screen 15 · Review algorithm
  ("{algorithm} · locked · reset to start over" when locked) → screen 02 · Reorder ·
  Move to Trash ("Recoverable for 30 days").
- **Sub-deck:** Open · Study this deck → screen 14 · Rename ·
  Study options → screen 15 (its root's options) ·
  Move to another deck · Reorder ("Move before or after a sibling") · Move to Trash
  ("Recoverable for 30 days").

## Sort & filter sheet

One `MxBottomSheet`, "Sort & filter":

- Sort by (`MxOptionRow`): Manual order "Drag decks to arrange them" · Date added
  "Newest first" · Name "A → Z" · Most due cards · Progress "Least mastered first"
  (BR-DECK-027).
- Toggle row (`MxSettingsRow` + `MxToggle`): "Only decks with due cards" / "Hides
  decks where nothing is waiting".
- "Sort by" is an `MxListSectionHeader`; Done is the sheet's `MxSheetActions` footer.
- Button "Done".

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| rootLoaded | `library_decks_light.png` | `library_decks_dark.png` | Every row carries its mastery bar (BR-DECK-026); the learning band is the darker learning ink in light (§9 row 141). The due strip shows its chevron: the fixture wires Study home as the app does (critique 2026-09-30 part 3a). |
| rootLoading | no golden | no golden | Skeletons in the row's shape; header kept. |
| rootEmpty | `library_empty_light.png` | `library_empty_dark.png` | "Create deck", then "Browse starter decks" (screen 03), and the footnote (FE-B4 §5.4). |
| rootError | no golden | no golden | "Couldn't load your library" with Retry. |
| rootSearch | no golden | no golden | The field is a trigger: a tap opens screen 04 instead of typing here. |
| rootSortFilter | `library_sort_light.png` | `library_sort_dark.png` | Progress orders least mastered first, decks with no card last (BR-DECK-027). |
| rootDueEmpty | no golden | no golden | "Nothing due right now" with "Show all decks". |
| rootOverflow | `library_deck_actions_light.png` | `library_deck_actions_dark.png` | Rows as in "Action sheet"; Reorder added. |
| rootCreate | no golden | no golden | The create dialog; no algorithm chosen up front (BR-SRS-001). While it writes it is held: Back, the scrim and Cancel wait, and they never open "Discard this deck?" over the write. A database failure shows in a warning banner at the top of the dialog; Create is the retry (SP2b 2.26, 2.27). |
| rootRename | no golden | no golden | The rename dialog. It is held while it saves, and a database failure shows in a warning banner inside it; Rename is the retry. The same dialog names a new sub-deck (SP2b 2.26, 2.27). |
| rootDelete | `library_deck_delete_light.png` | `library_deck_delete_dark.png` | Moves to the Trash (UC-TRASH-001). The dialog has no glyph and names the deck in quotes, not bold. The confirm spins while the deck moves (FE-B1 D15), and Back, the scrim and Cancel wait until it is done (SP2b 2.26). |
| rootDeleteFailed | `library_deck_delete_failed_light.png` | `library_deck_delete_failed_dark.png` | The move to Trash failed: the dialog stays, held no longer, with a warning banner ("Nothing was lost. The data is busy, so try again.") above the body. "Move to Trash" is the retry; Cancel works again. No toast, which would sit under the scrim (SP2b 2.27). |
| rootTrashed | `library_deck_trashed_light.png` | `library_deck_trashed_dark.png` | Undo for 8 seconds, and until acted on under TalkBack (FE-B1 D3, D14). A refused Undo says why: "Can't undo. {reason} Restore it from Trash and choose a deck." |
| deckLoaded | `library_deck_open_light.png` | `library_deck_open_dark.png` | The level's donut beside "MASTERED · {algorithm}"; the breakdown line wraps between whole terms, never "…" (the Wrap Rule; critique 2026-09-30 part 3b). |
| deckEmpty | `library_deck_unset_light.png` | `library_deck_unset_dark.png` | `unset` deck: both create choices and "Import cards from a file" (screen 11); no FAB (R9, critique 2026-09-30 part 1). |
| deckMaxDepth | no golden | no golden | No FAB. |
| deckLoading | no golden | no golden | Skeletons under the summary card. |
| deckError | no golden | no golden | Error state with Retry. |
| deckNotFound | no golden | no golden | "This deck is no longer here", Back to Library and Open Trash (FE-B1 D11); replaces ruling P2-L7. |
| deckOverflow | no golden | no golden | The sub-deck action sheet. |
| deckMove | no golden | no golden | The deck picker; only decks with the same review algorithm receive it (UC-DECK-005). While the move runs the sheet is held (`MxDeckPickerSheet.isHeld`: Back, the scrim, a drag and the dismiss button wait); a failure shows as the picker's `banner` under the rule, and choosing a deck again retries (SP2b 2.26, 2.27). |
| deckDelete | no golden | no golden | As rootDelete. |
| deckTrashed | no golden | no golden | As rootTrashed. Moving the open deck steps back to its parent first (C-L5); the toast survives the step back. |
Other goldens: `library_reorder_light.png` / `library_reorder_dark.png` (reorder mode).

## Rulings

- **Critique 2026-09-30 part 1, R9 (amends P4a-L9):** an `unset` deck has no FAB; its empty state already offers New card and New sub-deck. The FAB returns once the deck holds sub-decks.
- **FE-B1 D7:** an Undo happens where the item was deleted. A refused Undo says
  "Can't undo. {reason} Restore it from Trash and choose a deck."; it carries no deck name.
- **Owner ruling R4** (deck mastery spec, §9 row 141): the < 34% mastery band uses
  `statusLearningInk` in light (4.94:1 on the track) and the amber in dark.
- **§9 rows 142, 145 (FE-C1):** the mastery bar's track is `surfaceContainerLow`, so the fill keeps 3:1 against it in dark too.
- **Library spec D7:** Reorder is in the root deck's action sheet too.
- **C-L6:** the action sheet reads only `DeckView`, which carries no counts, so its header
  is the name alone.
- **M3 review 2026-09-28 D2:** reorder mode keeps one `MxCard` per deck, 8 apart, as in
  browse mode.
- **Critique 2026-09-30:** a row's meta and the due strip's breakdown wrap at large text, between whole terms; only the deck name keeps one line.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the deck summary's progress line is an eyebrow (12/600 muted); the list headers stay section labels.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the recent sort is labelled "Date added" (vi "Ngày tạo") with the hint "Newest first"; the search field is hidden while decks are reordered, as the summary, the due strip and the sort pill are, and returns with Done.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the due strip's breakdown is overdue · today, the two halves of its total; New stays on each deck row (BR-STUDY-068).
- **SP2b 2.26, 2.27 (spec `2026-10-03-ui-hardening-sp2b-design.md`):** the deck delete, rename and create dialogs and the move sheet are held while they write (`isHeld`; Cancel is off), so the result they report is never lost to Back or a scrim tap, and the create dialog's discard prompt cannot open over a write. A database `Failure` stays inside the dialog as a warning `MxInlineBanner` and the confirm retries (DESIGN.md, "a failure inside a dialog"). A throw that is not a `Failure` is reported once (`failureOfThrown`) and told as unknown ("Nothing was lost, but something went wrong. Try again.").

## Pending

| Element | Shown as | Waits for |
|---|---|---|
| Level-10 banner "This is level 10, the deepest a deck can go…" over sub-decks at level 10 | absent; the header says "· level 10" | a later phase (owner decision C-O6) |

## Copy

- Root: "Library" · "Search decks" · "{n} cards due" · "{n} decks" · "Manual" · "Manual · Due only" · "New deck".
- Row: "{n} due" · "{n} sub-deck(s)" · "{n} cards" · "Empty · add cards or a sub-deck" · "More actions for {name}" · "{n}% mastered" (TalkBack only).
- Summary: "Mastered · {algorithm}".
- Sort: "Progress" · "Least mastered first".
- First launch: "Start your library" · "A deck groups the sub-decks that hold your cards. Create one, or copy a starter deck to begin with content." · "Create deck" · "Browse starter decks" · "Everything stays on this device. Nothing is added until you choose."
- Error: "Couldn't load your library" · "Your data is safe on this device. Try again in a moment."
- Due filter, none: "Nothing due right now" · "No deck has cards waiting. The next card becomes due tomorrow at 00:00." · "Show all decks".
- Create: "New deck" · "Holds sub-decks; sub-decks hold cards." · "Name" · "Review algorithm · required" · "Eight boxes" / "Cards move up a box each time you remember them, back to box 1 when you forget. Forgiving of long breaks." · "SM-2" / "Intervals adapt to how well you recall each card. You grade yourself: again · hard · good · easy." · "Locks once the first card finishes learning. After that, only “Reset learning progress” starts a new cycle." · "Cancel" · "Create deck". No algorithm is chosen up front; Create without one says "Choose how the cards are reviewed." (BR-SRS-001, UC-DECK-001 E3). Cancel, Back or a tap outside after typing asks "Discard this deck?" · "What you typed is not saved." · "Keep editing" · "Discard" (UC-DECK-001 A1).
- Rename: "Rename deck" · "Only the name changes — sub-decks, cards and schedules stay as they are." · "Rename".
- Not found: "This deck is no longer here" · "It was moved to Trash or deleted while you were away. Anything in Trash can still be restored." · "Back to Library" · "Open Trash".
- Move to Trash: "Move to Trash" · "Recoverable for 30 days" · "Move this deck to Trash?" · "“{name}” goes to Trash with its {n} sub-decks and {n} cards." · "Recoverable from Trash for 30 days. Any open study session on these cards ends." · "Cancel" · "Move to Trash" · "“{name}” moved to Trash · {n} sub-decks, {n} cards" · "Undo".
- Move: "Move “{name}” to…" · "Its {n} sub-decks and {n} cards come along, schedules included. Only decks in the same review algorithm can receive it." · "Move here".
- Sort & filter: as in "Sort & filter sheet".
- Failure inside a dialog or sheet: the failure's own sentence (`l10n.failure`), e.g. "Nothing was lost. The data is busy, so try again." · "Nothing was lost, but something went wrong. Try again."
