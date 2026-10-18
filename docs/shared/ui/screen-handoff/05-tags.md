<!-- Hand-written screen record. -->

# 05 · Tags

The tag catalog: every tag of the library with its active cards, narrowed by a search,
each renamed, merged or deleted from its actions. UC-TAG-001; BR-TAG-001…011; spec
[2026-09-27-tags-starter-ui-design.md](../../../superpowers/specs/2026-09-27-tags-starter-ui-design.md)
(FE-B2). The card list's tag filter is on screen 07.

## Entry points

- **The Library's app bar:** the tag action pushes `/decks/tags`, full screen on the root
  navigator, with no bottom bar (D2, D5).

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content) | Back and "Tags". |
| Search | `MxSearchField` | "Search tags". It narrows the catalog with the fold the store writes and searches with (BR-TAG-003): `ĐỘNG TỪ` finds `động từ`. With no tags at all it is not shown. |
| Header | `MxListSectionHeader` | "{n} tags" or "No matches", with "A→Z" as plain text: there is one order, and nothing to tap (critique P2b). |
| Rows | `MxSection` + `MxListRow` | A tag tile, the name (up to two lines, then an ellipsis: `titleMaxLines: 2` in `tag_row_widget.dart`), "{n} cards" and ⋮ ("Actions for {tag}"). A tap on the row opens the same action sheet as ⋮. While the tag's write runs, the row shows a spinner, says "Saving this tag" to TalkBack, and cannot be tapped. |
| Action sheet | `MxBottomSheet` + `MxTagChip` + `MxActionSheetCommandRow` ×3 | The chip "{tag} · {n}", marked as the sheet's heading (`header` and `namesRoute`, as `MxBottomSheet`'s own title is), and "Tag actions"; "Find cards with this tag" / "Search the library for “{tag}”"; "Rename tag" / "Renaming onto an existing name merges the two"; "Delete tag" / "Removes it from {n} cards · the cards stay" (destructive). |
| Rename dialog | `MxDialog` + `MxTextField` + `MxSheetActions` | "Rename tag", "Renaming updates every card that uses “{tag}”.", the label "New name" above the field, the field prefilled, "Tag names are case-insensitive." as its supporting text; Cancel / Rename. The name rules are checked as it is typed; what the rename would do is read 250 ms after the name stops changing (D8). Rename is off while the name is unchanged. |
| Delete dialog | `MxDialog` + `MxNote` + `MxSheetActions` | "Delete this tag?", "“{tag}” is removed from {n} cards and disappears from the catalog. Tags are not kept in Trash.", the note (a neutral `MxNote`, not a success card) "No card is deleted, hidden or changed — all {n} cards stay exactly where they are."; Cancel / "Delete" (destructive) (The Footer Pair Rule, DEV-169; the verb alone, DEV-179). |

"Find cards with this tag" opens the Library search on the tag's name (D11). The search
lives in the Library branch, under the shell, so Back from it returns to the Library,
not to Tags (plan C4).

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| loaded | `tags_loaded_light.png` | `tags_loaded_dark.png` | Tags in the store's folded order (BR-TAG-003; UI-base row 137); no sort glyph. |
| loading | `tags_loading_light.png` | `tags_loading_dark.png` | The search, then skeleton rows (UI-base row 125). |
| empty | `tags_empty_light.png` | `tags_empty_dark.png` | Only the empty state: no search field, no header. "Go to library" goes back. |
| searchEmpty | `tags_search_empty_light.png` | `tags_search_empty_dark.png` | "No tags match “{term}”" (A6), distinct from "No tags yet". |
| sheet | `tags_sheet_light.png` | `tags_sheet_dark.png` | — |
| rename | `tags_rename_light.png` | `tags_rename_dark.png` | The tag's name in quotes, not bold. |
| renameMerge | `tags_rename_merge_light.png` | `tags_rename_merge_dark.png` | "{len} / 50 · names are unique regardless of letter case.", the warning panel, the chips `{source} · {n}` → `{target} · {union}` (the union, BE-B2 D6), and "Merge tags" in the warning tone, yellow with dark text (D15; UI-base row 134). A merge that no longer plans the same way when written (`mergeNotConfirmed`) opens the dialog again on the name typed. |
| nameTooLong | `tags_name_too_long_light.png` | `tags_name_too_long_dark.png` | The counter "{len} / 50" in the error colour at the trailing end of the row under the field, beside "A tag name can be at most 50 characters.", Rename off. The field keeps one line. A blank name and a control character show their own messages (E2). |
| del | `tags_del_light.png` | `tags_del_dark.png` | No glyph over the title; the text is left-aligned; the buttons stay side by side ("Delete tag", The Footer Pair Rule) (UI-base row 139). |
| busy | `tags_busy_light.png` | `tags_busy_dark.png` | — |
| opError | `tags_op_error_light.png` | `tags_op_error_dark.png` | One sentence, "Couldn't rename tag. Nothing changed — try again in a moment." (or delete), with Retry, which runs the same write (UI-base row 138). The toast outlives the screen, so Retry runs from the app's container and the root navigator, not the screen's `ref`; after leaving Tags it still writes and says how it ended (audit 2026-10-17 LIB-1). |
| tagGone | `tags_tag_gone_light.png` | `tags_tag_gone_dark.png` | The gone state (E3), from an action or from the rename dialog, which closes when its plan finds the tag gone. |
| read error | — | — | (E1, D10) `MxErrorState` "Couldn't load tags" · "Nothing was lost. Try again in a moment." with Retry; the search field stays above it. |
Other goldens: `tags_read_error_light.png` / `tags_read_error_dark.png` (the tag list could not be read).


Goldens: `test/features/tags/presentation/goldens/tags_{loaded,loading,empty,search_empty,sheet,rename,rename_merge,name_too_long,del,busy,op_error,tag_gone,read_error}_{light,dark}.png`.

## Transitions

| From | Event | To | Evidence |
|---|---|---|---|
| loading | the catalog lands | loaded, or empty with no tag at all | VERIFIED `tags_screen_test.dart::loaded: every tag with its cards, by folded name; the header counts them and A→Z is not a control`, `::empty: a library without tags says where they come from` |
| loading | the read fails | read error | VERIFIED `::a failed read shows the error with Retry (E1, D10)` |
| read error | Retry | loading, then loaded / empty | Retry is on screen in the test above; the read after it is `UNVERIFIED (code read)`: `tags_screen.dart` invalidates `tagCatalogProvider` |
| empty | Go to library | the Library (Back) | `UNVERIFIED (code read)`: `tags_screen.dart` `_back()`; the state itself is VERIFIED above |
| loaded | type in the search | loaded (narrowed) or searchEmpty | VERIFIED `::search uses the catalog's fold: ĐỘNG TỪ finds động từ (BR-TAG-003)`, `::searchEmpty: no tag matches, which is not "no tags" (A6)` |
| loaded | tap a row or its ⋮ | sheet | VERIFIED `::sheet: the tag with its count and three commands; Find cards hands over the name (D11)` for the ⋮; the row tap shares `_openActions`: `UNVERIFIED (code read)` |
| sheet | Find cards with this tag | the Library search on the tag's name (screen 04); Back returns to the Library | VERIFIED `::sheet: ...` for the hand-over; Back landing on the Library is plan C4: `UNVERIFIED (code read)` |
| sheet | Rename tag | rename | VERIFIED `::rename: prefilled, nothing to write until the name changes; a new name renames in place (step 5)` |
| rename | the name breaks a rule | nameTooLong, or a blank / control-character message; Rename off | VERIFIED `::nameTooLong: the counter and the field say so, and Rename is off; a blank name has its own message (E2)` |
| rename | the name settles on an existing tag | renameMerge | VERIFIED `::renameMerge: the merge is told before it is confirmed, with the union count, and confirmed in the warning tone (A1)` |
| rename / renameMerge | Rename or Merge tags | busy on the row, then the catalog shows the new name; no toast | VERIFIED `::rename: prefilled, ...`; `tag_actions_controller_test.dart::rename keeps the id; merge folds into the confirmed target` |
| renameMerge | the write finds a merge nobody confirmed | the dialog opens again on the name typed | VERIFIED `::a merge that appeared after the plan opens the dialog again on the name typed (mergeNotConfirmed)` |
| rename | the tag is deleted elsewhere while the dialog is open | the dialog closes, "no longer exists" toast, nothing written | VERIFIED `::a tag deleted elsewhere while its rename dialog is open closes the dialog and says it is gone (E3)` |
| rename | Cancel | the catalog, nothing changed | `UNVERIFIED (code read)`: `tag_rename_dialog_widget.dart` |
| sheet | Delete tag | del | VERIFIED `::del: the dialog says no card is deleted; the tag goes and every card stays (A3)` |
| del | Delete | busy on the row, then the tag leaves the catalog and every card stays | VERIFIED same test; `tag_actions_controller_test.dart::delete removes the tag and keeps every card (A3)` |
| sheet | TalkBack opens the sheet | the chip "{tag} · {n}" is read as the sheet's heading and names the route | VERIFIED `tags_screen_test.dart::sheet: the tag with its count and three commands; Find cards hands over the name (D11)` (it asserts `isHeader` and `namesRoute`) |
| busy | TalkBack reads the row | "Saving this tag" for the spinner (`MxListRow.busyLabel`) | the shared mechanism is VERIFIED `test/shared/widgets/mx_list_row_busy_test.dart::a busy row says it is busy to TalkBack with the caller's label (audit 2026-10-17)`; the tag row passing `tagsRowBusy` is `UNVERIFIED (code read)`: `tag_row_widget.dart` |
| busy | tap the row or ⋮ | ignored (the row is not tappable) | `UNVERIFIED (code read)`: `tag_row_widget.dart` `onTap: isBusy ? null : …`; the spinner is VERIFIED `::busy: the row spins instead of ⋮ while its write runs` |
| busy | the write fails | opError: a toast, nothing changed, with Retry | VERIFIED `::opError: a failed delete changes nothing and offers Retry, which deletes (E5)`; `tag_actions_controller_test.dart::a failed write changes nothing and says so (E4, E5)` |
| opError | Retry | busy again with the same write | VERIFIED same screen test (delete); the rename path shares `_write`: `UNVERIFIED (code read)` |
| busy | the tag is gone | tagGone: a toast, nothing written | VERIFIED `::tagGone: a tag deleted elsewhere says so and writes nothing (E3)` |
| busy | the screen is left before the write ends | the toast is not shown | `UNVERIFIED (code read)`: `tags_screen.dart` `_write` returns on `!mounted`; the busy flag is cleared only while the controller is mounted |

## Rulings

- **D15 (AA):** "Merge tags" uses the warning role with its text.
- **BE-B2 D6, D8:** the merge target's count is the union of both tags' cards, not their sum.
- **BR-TAG-003, critique P2b:** there is one order (the store's folded order, diacritics folded), so "A→Z" is plain text with no sort glyph.
- **UC-TAG-001 E1, D10:** a read failure shows `MxErrorState` with Retry.
- Dialogs quote tag names, carry no glyph and are left-aligned (`MxDialog`); toasts are one sentence (`MxSnackbarContent`).
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** the rename dialog's "New name" is a field label in sentence case.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** with no tags at all the screen shows only the empty state (no search field, no header); when tags exist and a search finds none, the field and "No matches" stay; the delete dialog's reassurance is a neutral `MxNote`, not a success card.
- **Q-C-1 (owner, 2026-10-16):** the tag sheet's delete hint (capped at two lines, where `metaDots`, never `metaLine`, is allowed; 06) and the rename dialog's length hint keep each dot on the phrase before it (`metaDots`) (The Wrap Rule; `lib/l10n/meta_line.dart`).

## Copy

"Tags" · "Search tags" · "{n} tags" · "No matches" · "A→Z" · "{n} cards" ·
"Actions for {tag}" · "No tags yet" · "Tags appear here as you add them when creating or
editing flashcards." · "Go to library" · "No tags match “{term}”" · "Try a different
spelling. Tag search is case-insensitive." · "Couldn't load tags" · "Tag actions" · "Find
cards with this tag" · "Search the library for “{tag}”" · "Rename tag" · "Renaming onto
an existing name merges the two" · "Delete tag" · "Removes it from {n} cards · the cards
stay" · "Renaming updates every card that uses “{tag}”." · "New name" · "Tag names are
case-insensitive." · "{len} / {max}" · "{len} / {max} · names are unique regardless of
letter case." · "A tag name can be at most {max} characters." · "Rename" · "Merge tags" ·
"A tag called “{target}” already exists. Continuing will merge “{source}” into it — its
spelling stays “{target}”." · "No card is deleted. Cards carrying both keep one tag; no
card goes over 10 tags." · "Delete this tag?" · "“{tag}” is removed from {n} cards and
disappears from the catalog. Tags are not kept in Trash." · "No card is deleted, hidden
or changed — all {n} cards stay exactly where they are." · "Delete" ·
"Couldn't rename tag. Nothing changed — try again in a moment." · "Couldn't delete tag.
Nothing changed — try again in a moment." · "“{tag}” no longer exists — it was removed a
moment ago."
