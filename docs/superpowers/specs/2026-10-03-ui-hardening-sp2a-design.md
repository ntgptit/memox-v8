# UI hardening SP2a — study and cards: data safety and dead ends — design

Status: approved 2026-10-03 ·
Path: architectural, sub-project SP2a of [the UI hardening spec](2026-10-03-ui-hardening-design.md) ·
Owner rulings: R8–R11 (that spec §3)

## 1. Intent

SP2a fixes the backlog items of §6.1 in the parent spec for the study and card surfaces:
2.01–2.25 and 2.49–2.51.

The items fall into four kinds, and each needs a fix:

- typed content that is lost;
- a flow that strands the person;
- a state the screen shows that is false;
- an action that lands on the wrong thing.

The visible design does not change except for the few banners, dialogs and toasts named
below, which follow DESIGN.md and the SP1 rules:

- a note says something new;
- a destructive confirm names the loss;
- offline is neutral.

Success:

- every item below has a test that fails before its fix;
- `dod_check.sh` is green;
- the Linux goldens are green;
- the owner approves the golden-compare page;
- the WBS row FE-D28 tells the truth.

## 2. Owner rulings used here

- **R3.** Starting a session while another deck's session is open asks first.
- **R8.** SP2 is two PRs: SP2a (this spec) first, then SP2b.
- **R9.** A card being written is kept in a device-local draft table. Drafts are never
  synced or logged, and are offered back when the editor opens again.

## 3. Design

### 3.1 Study entry, session and summary

| # | Fix | Where |
|---|---|---|
| 2.01 | Before any start, ask `StudyEntryRepository` for an open, resumable session of another deck. A new query in `study_session_queries.drift` reads the open session whose deck is not this one. If one exists, the start shows an `MxDialog`: title "End your session in {deck}?", body "Its answers are kept; the rest of that round is dropped.", actions "Keep it" (outline) and "End it and start" (warning). Only the confirm calls `closeOpenSessions`. | `study_entry_repository_impl.dart:433`, `study_entry_controller.dart`, entry screen |
| 2.02 | `pick()` clears `failed` and `refused`, so Try again replays the picked mode. | `study_entry_controller.dart:113-118` |
| 2.03 | The body renders `Rejected(notFound)` from the stream value as `MxErrorState` (the not-found form) with Back. The one-shot listener stays as the fast path. | `study_entry_body_widget.dart:62-63`, `study_entry_screen.dart:442-445` |
| 2.04 | While `isStarting`, the entry holds Back (`PopScope(canPop: !isStarting)`) and disables the Study options action. | `study_entry_screen.dart:361-372` |
| 2.05 | Study options: an `appSettingsProvider` error renders the error branch. Retry invalidates both providers. | `study_options_screen.dart:274-325` |
| 2.06 | Study options: Back with a dirty draft asks Discard or Keep editing, using the card editor's discard dialog pattern. | `study_options_screen.dart:287` |
| 2.07 | The session screen remembers a leave that arrived while its route was not current, then runs it when the exit dialog's future completes. | `study_session_screen.dart:170-219` |
| 2.08 | A failed Stop shows `studyStopFailed` as a toast. While a confirm is open, ✕ and Back do nothing (`_isConfirming`). | `study_session_controller.dart:536-542`, screen `:89-94` |
| 2.09 | The summary footer sits in `StudySettleGuardWidget`, keyed on the summary, so the last answer's double tap cannot reach Done. | `session_summary_widget.dart:76-95` |
| 2.10 | Browse's Next sits in the settle guard, keyed on the card. | `study_browse_widget.dart:68-75,128-136` |
| 2.11 | The session screen owns a `ValueNotifier<bool> overlayOpen`, set while the exit dialog is up and passed to the Recall widget. The Recall clock stops while it is true and resumes when it turns false. | `study_recall_widget.dart:129-149` |
| 2.12 | A refused or failed reveal sets the turn's write-failed flag, so the existing unsaved banner shows. | `study_session_controller.dart:519-521` |
| 2.13 | `MxTextFieldVariant.study` sets `autocorrect: false` and `enableSuggestions: false`. | `mx_text_field.dart:269-290` |
| 2.49 | Resume refused: "This session can't be continued. Your answers are kept." Resume failed: "Couldn't open the session. Nothing was lost; try Resume again." Both come with VI strings. | `study_home_screen.dart:289-292`, ARB |
| 2.50 | Progress and deck progress keep the last value on a stream error and show an `MxInlineBanner` (warning, local-first copy) with Retry. The full error page appears only when there is no value yet. | `progress_screen.dart:180-196`, `deck_progress_screen.dart:46-66` |
| 2.51 | When its deck is lost, the summary stays. Only "Study this deck" goes, and Done still leaves. | `study_session_screen.dart:176-177` |

### 3.2 Card editor and the draft (R9)

- **Table.** `card_draft` goes in `lib/core/database/tables/ui_state.drift`:

  ```sql
  CREATE TABLE card_draft (
    draft_key TEXT NOT NULL PRIMARY KEY,
    front TEXT NOT NULL,
    back TEXT NOT NULL,
    extras TEXT NOT NULL,
    tags TEXT NOT NULL,
    updated_at DATETIME NOT NULL
  ) AS CardDraftRow;
  ```

  - `draft_key` is `create:<deckId>` or `edit:<cardId>`.
  - `extras` and `tags` hold JSON.
  - It is device-local, like `dismissed_note`: no sync trigger and no `server_version`.
  - Schema 12 → 13, with a migration step and a schema-snapshot test (`flutter-drift` rules).
  - Queries live in a `.drift` file (ADR-020).
- **Writes.** The form saves its content to the draft 500 ms after the last change,
  through a small `CardDraftRepository`:
  - `read(key)`, `save(key, content)` and `clear(key)`;
  - one implementation, consumed by the editor controller;
  - no interface, since it has a single implementation.

  A successful save clears the draft. So does Discard on the discard dialog, and so does
  an unchanged form.
- **Restore.** If a draft exists when the editor opens and it differs from what the form
  would show, an `MxInlineBanner` (neutral) sits above the fields:
  - title "Unsaved text from earlier";
  - actions "Restore" and "Discard".
- **2.15.** When the deck rejects the card, the draft stays. The banner explains the
  rejection, and the next editor opening on that deck offers the text back.
- **2.16.** While saving, Cancel, the close button and Back are held. The discard dialog
  cannot open over a save in flight.
- **2.17.** When the card goes away while it is being edited (deleted remotely, or an
  error), the form stays mounted:
  - a danger `MxInlineBanner` sits above it: "This card was deleted. Your text is kept on this phone.";
  - Save is disabled;
  - the draft stays.

  `_EditLoader` builds the form once and then only annotates it.
- **2.18.** The editor remembers the card's `updatedAt` when it opens.
  - At save, the repository compares it with the stored one. If they differ, it returns a
    typed `changedElsewhere` outcome.
  - The form then asks: title "This card changed on another device", actions "Use theirs"
    (outline) and "Keep mine" (primary).
  - "Keep mine" saves over the newer version. "Use theirs" reloads the card and clears
    the draft.

### 3.3 Card list bulk actions

- **2.19.** A bulk action works on the selected ids that still exist and skips the rest
  inside the same transaction. This covers Trash, Move, Tag, Flag and Export.
  - It returns `BulkOutcome(done, skipped)`.
  - The toast says "Moved 799 cards. 1 was already gone." (ICU plural).
  - The selection is pruned of the gone ids.
  - `deleteCards` and `exportSnapshot` no longer refuse the whole batch over one missing id.
- **2.20.** The bulk Trash confirm's button names the count: "Move {n} cards to Trash".
  The success toast for several cards carries Undo, which restores the whole
  `delete_batches` batch. That is the same restore the Trash screen uses.
- **2.21.** A refused bulk Tag names the count: "{n} cards already have 10 tags; nothing was tagged."

### 3.4 Import

- **2.22.** `previewRows` (and `readSource`, defensively) catch any exception, set a typed
  problem and clear `isBusy`.
- **2.23.** A file over 5 MB or a table over 20,000 rows is refused up front. It gets a new
  `TransferRejection.tooLarge(limit)`, copied as "This file is too large to import. Split
  it into files of up to 20,000 rows or 5 MB."
  - The check sits in `TransferFileRepository` before decoding.
  - The result screen's skipped rows show the first five inline.
  - "Show all" opens an `MxBottomSheet` with a lazy `ListView.builder`.
- **2.24.** After a read, `hasHeaderRow` defaults to whether `ColumnMapping.fromHeader`
  recognised any column. The toggle subtitle keeps naming row 1's cells.
- **2.25.** The commit returns the ids it wrote.
  - The result screen offers "Undo import", which moves those cards to the Trash as one
    batch. The batch is recoverable for 30 days.
  - It is confirmed with "Move the {n} imported cards to Trash?".
  - Before the write starts, Cancel stays available. Once the transaction runs, it holds.

## 4. Copy

Every new string is written in English first and Vietnamese with it (`app_en.arb`,
`app_vi.arb`), in the local-first voice. Plurals use ICU forms.

## 5. Testing

- **Behaviour items.** Each gets a failing test first:
  - a controller or repository test where the logic lives (2.01, 2.02, 2.07, 2.08,
    2.11, 2.12, 2.18, 2.19, 2.20, 2.22–2.25, the draft repository);
  - a widget test where the screen owns it (2.03–2.06, 2.09, 2.10, 2.13, 2.15–2.17,
    2.49–2.51).
- **Migration.** A schema-snapshot test for v13 and an upgrade test from v12.
- **Goldens.** New goldens for:
  - the cross-deck confirm;
  - the draft restore banner;
  - the card-deleted banner;
  - the changed-elsewhere dialog;
  - the too-large import state;
  - the Undo import result;
  - the Progress error-after-data banner.

  They are regenerated in the Linux container, and the golden-compare page goes to the
  owner before the merge.
- **Gate.** `dod_check.sh`, then `run_goldens.sh`. On Windows, test subsets run through
  `run_tests.sh` (`MEMOX_TEST_BUNDLES=2`).

## 6. Out of scope

- SP2b items (2.26–2.48).
- Any change to the SRS or scheduling rules.
- Syncing drafts.
