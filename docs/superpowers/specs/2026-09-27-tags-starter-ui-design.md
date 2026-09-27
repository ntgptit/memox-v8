# FE-B2 + FE-B4: the Tags and Starter decks UI — design

Status: approved 2026-09-27 · Path: architectural · Owner rulings 2026-09-27 (§3)

## 1. Intent

Two screens of the kit wait on backends that are built:

- **Screen 03 "Starter decks" (FE-B4).** It sits on BE-B4
  ([spec](2026-09-26-starter-decks-backend-design.md) §9) and UC-STARTER-001.
- **Screen 05 "Tags" (FE-B2).** It sits on BE-B2 and BE-C4
  ([spec](2026-09-26-tag-management-backend-design.md) §9) and UC-TAG-001.

The owner asked for them as one batch (2026-09-27): one spec, one plan, one PR.
Two half-built states elsewhere wait on the same work, so they join it:
- screen 01 `rootEmpty`, whose starter half waits under Coming soon;
- screen 07 `loaded`, whose Tags chip and filter wait under Coming soon.

Success means four things:

- all 22 kit states of 03 and 05 are built from `Mx*` widgets, or recorded as a
  deviation with the reason;
- screen 01's `rootEmpty` and screen 07's `loaded` are no longer partial;
- each flow of UC-STARTER-001 and UC-TAG-001 that a screen shows has a test;
- the Coming soon sheet is gone: nothing it named waits any more, except the progress
  sort, which a BR still blocks.

## 2. Context (2026-09-27)

- **Starter (BE-B4):**
  - `WatchStarterLibraryUseCase` → `Stream<List<StarterLibraryEntry>>`. Each entry
    carries `templateId`, `version`, `title`, `locale`, `frontLanguage`,
    `backLanguage`, `contentSource`, `suggestedScheduler`, `cardCount`,
    `subDeckCount` and `isInLibrary`.
  - `AddStarterDeckUseCase({templateId, schedulerType, allowSecondCopy})` →
    `Outcome<AddedStarterDeck, StarterRejection>`. The rejections are
    `alreadyInLibrary` and `templateNotFound`; a `Failure` is a failed write.
  - The build ships two templates, with language tags `en`, `vi`, `ko` and
    `ko-Latn`.
- **Tags (BE-B2, BE-C4):**
  - `WatchTagCatalogUseCase({searchTerm})` and `WatchDeckTagCountsUseCase({deckId})`
    return `Stream<List<TagCount>>`.
  - `PlanTagRenameUseCase` returns unchanged, rename or merge (target, union count).
  - `RenameTagUseCase({tagId, name, mergeIntoTagId})` and
    `DeleteTagUseCase({tagId})` do the writes.
  - `CardListQuery.tagIds` filters the card list.
  - `TagRejection` is `blankName`, `nameTooLong`, `controlCharacter`,
    `tooManyTags`, `notFound` or `mergeNotConfirmed`. Its messages live in the card
    feature's `tag_rejection_message_widget.dart`.
- **The import map:**
  - `card` may import `tags`;
  - `tags` imports no feature;
  - `starter_decks` may import `deck`, `card` and `srs`.
- **The kit:**
  - 03 has 10 states and 05 has 12; both are captured in
    `docs/shared/ui/screen-handoff/img/{03-starter-decks,05-tags}/`.
  - Kit 01's root app bar draws Starter decks · Tags · Trash.
  - Kit 07 draws a "Tags" chip with a chevron, but no filter overlay.
- **Shared gaps:** `MxButton` has no warning tone, and kit 05's "Merge tags" button
  is filled in the warning colour.

## 3. Decisions

| # | Topic | Decision | Authority |
|---|---|---|---|
| D1 | Scope | 03 and 05 with 01's `rootEmpty` and 07's `loaded`. Screen 24 waits on BE-B5b; the progress sort waits on a BR | Owner, 2026-09-27 |
| D2 | The Library's app bar | As kit 01: Starter decks (sparkles), Tags (tag), Trash. The Coming soon sheet and its ARB keys go. The progress sort stays absent, recorded in 01's detail file | Owner, 2026-09-27 |
| D3 | The tag filter overlay | A bottom sheet: one `MxOptionRow` checkbox per tag, "{tag} · {n}"; a search field once there are more than 8 tags; a footer of "Clear" and "Apply". Closing it without Apply keeps the applied set (A5). Shaped by Impeccable before the plan | Owner, 2026-09-27 |
| D4 | Structure | Per feature: a provider per use case, a stream provider per read, one controller for the writes (`StarterAddController`, `TagActionsController`). Screens take callbacks; `app/` wires the routes | Owner, 2026-09-27 |
| D5 | Routes | `/decks/starter` and `/decks/tags` on the root navigator, full screen with no bottom bar, as the kit draws them and as the Trash is (FE-B1 D2) | Owner, 2026-09-27 |
| D6 | Starter flow | "Add to library" opens the algorithm sheet, with `suggestedScheduler` preselected. "Add another copy" first asks with a dialog, then opens the sheet, and adds with `allowSecondCopy: true`. While it adds, the sheet's controls lock and a second add is ignored. `Ok` closes the sheet and toasts "Added …" with Open. `alreadyInLibrary` toasts. `templateNotFound` or a `Failure` keeps the sheet open with an error banner and "Try again" | Owner, 2026-09-27; BE-B4 §9 |
| D7 | Language names | A small ARB table for the language tags the build ships (English, Vietnamese, Korean; `-Latn` reads "Latin"). Another tag shows as written | Owner, 2026-09-27 |
| D8 | Rename | The plan runs as the name changes, after a short settle (an `AppDurations` token). A merge shows the kit's panel and "Merge tags". The target's count is the union (BE-B2 D6), not the kit's sum. `mergeNotConfirmed` plans again. `notFound` toasts "no longer exists" (`tagGone`), and a `Failure` toasts with Retry (`opError`) | Owner, 2026-09-27; BE-B2 §9 |
| D9 | A warning button | `MxButtonTone.warning`: the warning fill with its on-colour, for "Merge tags" | Owner, 2026-09-27 (kit 05) |
| D10 | Tags read error | A failed catalog read shows `MxErrorState` with Retry (UC-TAG-001 E1), which the kit does not draw | UC-TAG-001 E1 |
| D11 | Find cards with this tag | Opens the Library search with the tag's name: `LibrarySearchScreen` takes an `initialQuery` (BE-B2 D12) | Owner, 2026-09-27 |
| D12 | The card list's filter | The applied set goes into `CardListQuery.tagIds`. Applying resets the window and clears the selection (BR-TAG-005). A tag that leaves the overlay's list leaves the set. With a tag filter and no match, the empty state offers "Clear tag filter" (A7) | BE-B2 §9; UC-TAG-001 A4, A5, A7 |
| D13 | Adding and saving | The adding button spins without "Adding…" text (`MxButton.isLoading`), as screen 15 does | FE-A3 C8 |

## 4. Structure

```
lib/shared/widgets/mx_button.dart                   D9: the warning tone
lib/features/starter_decks/presentation/
  providers/   watch_starter_library_use_case_provider, add_starter_deck_use_case_provider,
               starter_library_provider (Stream<List<StarterLibraryEntry>>)
  controllers/ starter_add_controller      the add, its guard, its result
  states/      starter_add_state
  screens/     starter_library_screen      /decks/starter
  widgets/     items/starter_template_card_widget
               overlays/starter_algorithm_sheet_widget, starter_second_copy_dialog_widget
               support/starter_language_labels_widget (D7)
lib/features/tags/presentation/
  providers/   one per use case; tag_catalog_provider(searchTerm);
               deck_tag_counts_provider(deckId)
  controllers/ tag_actions_controller      rename plan, rename, merge, delete, busy row
  states/      tag_actions_state
  screens/     tags_screen                 /decks/tags
  widgets/     items/tag_row_widget
               overlays/tag_actions_sheet_widget, tag_rename_dialog_widget,
               tag_delete_dialog_widget
lib/features/card/presentation/            07: the Tags chip, the filter sheet,
                                           the applied set in the request state, A7
lib/features/deck/presentation/            01: the app bar, rootEmpty; Coming soon goes
lib/features/search/presentation/          initialQuery (D11)
lib/app/router/                            the two routes and their callbacks
```

The plan settles the exact names within the guard's buckets.

## 5. Behaviour

### 5.1 Screen 03, Starter decks

- **App bar:** Back and "Starter decks".
- **Note:** an `MxNote` with a flask glyph: "These decks are practice fixtures for
  development and testing, not published course material. Anything you add is yours
  to edit." (BR-STARTER-010).
- **A card per template:**
  - a sparkles tile, the title, and "In library" when `isInLibrary`;
  - the line "{front language} · {back language} · {n} cards · {m} sub-decks ·
    Development fixture";
  - the button "Add to library", or "Add another copy" when already in the library;
  - "Suggests SM-2" or "Suggests Eight boxes".

| State | Shown |
|---|---|
| `list` | As above |
| `choose` | A bottom sheet: "Add “{title}”", "{n} cards in {m} sub-decks, as a new deck of your own.", the overline "Review algorithm · required", and two `MxOptionRow` radios. SM-2 reads "grade yourself, intervals adapt" and Eight boxes "Boxes 1–8 · match, guess, recall, fill". The suggested one is prefixed "Suggested for this deck", and preselected. The footer has Cancel and "Add deck" |
| `adding` | The options and Cancel lock; "Add deck" spins (D13) |
| `added` | The sheet closes; a toast "Added “{title}” · {algorithm} · {n} new cards" with Open, which opens the new root deck |
| `alreadyPresent` | A toast "Already in your library — nothing was copied" |
| `secondCopy` | A dialog "Add a second copy?" · "“{title}” is already in your library. A second copy is a separate deck with its own progress." · Cancel / "Add second copy", which opens the algorithm sheet |
| `addFailed` | The sheet stays open, with an `MxInlineBanner` (danger): "Couldn't add the deck. Nothing was copied — try again.", and the button reads "Try again" |
| `loading` | `MxSkeletonList` (UI-base row 125) |
| `none` | `MxEmptyState` "No starter decks in this build" · "This version ships without practice content. Create a deck or import cards instead." · "Create a deck" |
| `loadFailed` | `MxErrorState` "Couldn't load starter decks" · "Your library is unaffected. Try again in a moment." · Retry |

"Create a deck" returns to the Library and opens its create-deck dialog (`app/`).

### 5.2 Screen 05, Tags

- **App bar:** Back and "Tags".
- **Search:** `MxSearchField` "Search tags". It uses the catalog's own fold, so
  `ĐỘNG TỪ` finds `động từ` (BR-TAG-003).
- **Header:** "{n} tags", "No tags" or "No matches", with "A→Z" as static text.
  There is one order (BR-TAG-003).
- **A row per tag:** a tag tile, the name, "{n} cards" and ⋮.

| State | Shown |
|---|---|
| `loaded` | As above |
| `loading` | `MxSkeletonList` |
| `empty` | `MxEmptyState` "No tags yet" · "Tags appear here as you add them when creating or editing flashcards." · "Go to library" (back) |
| `searchEmpty` | `MxEmptyState` "No tags match “{term}”" · "Try a different spelling. Tag search is case-insensitive." |
| `sheet` | An action sheet under the chip "{tag} · {n}": "Find cards with this tag" / "Search the library for “{tag}”"; "Rename tag" / "Renaming onto an existing name merges the two"; "Delete tag" / "Removes it from {n} cards · the cards stay" |
| `rename` | A dialog "Rename tag" · "Renaming updates every card that uses {tag}.", with the "New name" field prefilled and "Tag names are case-insensitive."; Cancel / Rename |
| `renameMerge` | The plan says merge. The count reads "{len} / 50 · names are unique regardless of letter case.", and a warning panel says "A tag called {target} already exists. Continuing will merge “{source}” into it — its spelling stays “{target}”." It shows the chips `{source} · {n}` → `{target} · {union}` (D8), then "No card is deleted. Cards carrying both keep one tag; no card goes over 10 tags." The button is "Merge tags" in the warning tone (D9) |
| `nameTooLong` | The counter turns to the error ink, the field shows "A tag name can be at most 50 characters.", and Rename is disabled. A blank name and a control character use the existing `TagRejection` messages (E2) |
| `del` | A dialog "Delete this tag?" · "{tag} is removed from {n} cards and disappears from the catalog. Tags are not kept in Trash.", with a success-toned note "No card is deleted, hidden or changed — all {n} cards stay exactly where they are."; Cancel / "Remove from {n} cards" (destructive) |
| `busy` | The row's ⋮ turns into a spinner while its write runs |
| `opError` | A toast "Couldn't rename tag" (or "Couldn't delete tag") · "Nothing changed. Try again in a moment." with Retry |
| `tagGone` | A toast "“{tag}” no longer exists — it was removed a moment ago." |
| read error | `MxErrorState` with Retry (D10) |

### 5.3 Screen 07, the Tags filter

- **The chip:** `MxChipTrigger` "Tags" after the four filters; "Tags · {k}" when
  {k} are applied.
- **The sheet (D3):**
  - its title is "Filter by tags", with "{n} tags in this deck";
  - each tag is a row "{tag} · {n in this deck}" with a checkbox, and a tag with 0
    in this deck is still listed (BE-B2 D3);
  - a search field appears above 8 tags;
  - the footer has "Clear" and "Apply".
  - Its three states (none chosen, one, several) are shaped by Impeccable before the
    plan.
- **Applying:** the set goes into `CardListQuery.tagIds` (OR between tags, AND with
  the status filter and the search). The window resets and the selection clears.
- **With a tag filter and no match (A7):** `MxEmptyState` "No cards with these tags" ·
  "Clear tag filter".

### 5.4 Screen 01

- **The root app bar (D2):** Starter decks (sparkles), Tags (tag), Trash. Coming soon
  goes.
- **`rootEmpty`:**
  - the body reads "A deck groups the sub-decks that hold your cards. Create one, or
    copy a starter deck to begin with content.";
  - "Create deck" stays primary, and "Browse starter decks" is a secondary action;
  - the local-first note stays.

Every string is in `app_en.arb` (with its description) and `app_vi.arb`.

## 6. Errors

- Reads that fail show `MxErrorState` with Retry: `loadFailed` on 03, and D10 on 05.
- Writes that fail keep what was typed or chosen and say so: 03's banner in the sheet
  (`addFailed`), 05's toast with Retry (`opError`).
- A rejection is never shown as its raw text. `templateNotFound` reads as `addFailed`;
  `notFound` reads as `tagGone`; the `TagRejection` name rules read as their field
  messages.
- No message carries an id, a path or SQL (BR-CORE-005).

## 7. Tests

- **Controllers** (plain `test()`s over a `LibraryEnv`):
  - Starter: add, already in library, second copy, a failed write, and a second add
    ignored while one runs.
  - Tags: plan unchanged, rename and merge; `mergeNotConfirmed` planning again;
    delete; `notFound`; `Failure`; the busy row.
- **Widget tests** (`libraryTest`):
  - each state of 03 and 05;
  - the filter sheet: A4 Clear, A5 close without Apply, A7, and a vanished tag
    pruned from the set;
  - "Find cards with this tag".
- **Route tests:**
  - the Library's app bar opens 03 and 05, and `rootEmpty` opens 03;
  - Open lands on the new deck;
  - "Find cards" opens the search with the tag's name.
- **Goldens:**
  - the 22 kit states, light and dark, compared with their captures;
  - the states the kit lacks: the Tags read error, the filter sheet's three states,
    and 07 filtered with its A7 state;
  - 01's new `rootEmpty` and app bar.
  - Changed goldens of 01 and 07 are compared with their kit frames.
- **Visual audits:** 03, 05 and the filter sheet at 360 dp and text scale 2, in English
  and Vietnamese.

## 8. Documents

- New detail files `03-starter-decks.md` and `05-tags.md`.
- Detail files 01 and 07 lose their Coming soon rows.
- The index, the checklist (22 states done, and 01 `rootEmpty` and 07 `loaded` no longer
  partial), and UI-base §9 rows from 134 on.
- `ui.md` and the use cases of `tags` and `starter-decks` (`code:`).
- `wbs_FE.md`: FE-B2 and FE-B4 done.
- The kit captures of 03 and 05 and their manifest entries land with this spec.

## 9. Plan

One plan of about eight tasks:

1. `MxButtonTone.warning`, then the starter providers and `StarterAddController`.
2. Screen 03: the cards, the algorithm sheet, the second-copy dialog and the toasts.
3. The tags providers and `TagActionsController`.
4. Screen 05: the catalog, the action sheet, and the rename, merge and delete dialogs.
5. Screen 07: the Tags chip, the filter sheet and the filtered states.
6. Screen 01: the app bar and `rootEmpty`; Coming soon goes.
7. The routes, the callbacks and the search's `initialQuery`.
8. The documents.

Before the plan, Impeccable critiques kits 03 and 05 and shapes the filter sheet.

## 10. Out of scope

- Screen 24 (FE-B5), which waits on BE-B5b.
- The progress sort of screen 01, which waits on a BR (`wbs_BE.md`).
- Tag colours, tag hierarchy, or bulk tag management beyond UC-TAG-001.

## 11. Risks and rollback

- **A shared button tone.** It is additive; the existing tones and their goldens do not
  change.
- **The filter changes the card list's request.** BE-C4's predicate is tested. The UI
  tests cover the reset of the window and the selection.
- **Coming soon goes.** Its tests and goldens are updated in the same task. A rollback
  restores it with the two screens.
