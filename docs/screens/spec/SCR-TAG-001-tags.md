---
id: SCR-TAG-001
name: Tags
domain: tags
status: ready
route: [/decks/tags]
---

# Tags

## Purpose

The tag catalog: every tag of the library with its active cards, narrowed by a search, each
renamed, merged or deleted from its actions. Full screen on the root navigator, with no bottom
bar; opened from the tag action on the Library's app bar (SCR-DECK-001). The card list's tag
filter belongs to SCR-CARD-001.

## Related Use Cases

- UC-TAG-001

## Layout

- **App bar** — back and "Tags" (content density).
- **Search** — the search field "Search tags". It narrows the catalog with the fold the store
  writes and searches with: `ĐỘNG TỪ` finds `động từ`. With no tags at all it is not shown.
- **Header** — a section header "{n} tags" or "No matches", with "A→Z" as plain text: there is
  one order, and nothing to tap.
- **Rows** — a section of list rows: a tag tile, the canonical name (one line, ellipsis), "{n}
  cards" and ⋮ ("Actions for {tag}"). While the tag's write runs, ⋮ is a spinner and the row
  cannot be tapped.
- **Action sheet** — a bottom sheet with the chip "{tag} · {n}" and "Tag actions"; three command
  rows: "Find cards with this tag" / "Search the library for “{tag}”"; "Rename tag" / "Renaming
  onto an existing name merges the two"; "Delete tag" / "Removes it from {n} cards · the cards
  stay" (destructive).
- **Rename dialog** — "Rename tag", "Renaming updates every card that uses “{tag}”.", the field
  label "New name" with the field prefilled with the current name, "Tag names are
  case-insensitive."; Cancel / Rename. The name rules are checked as it is typed; what the rename
  would do is read 250 ms after the name stops changing. Rename is off while the name is
  unchanged. When the name would merge, the dialog says so **before** the confirm: a warning
  panel naming the target, the chips `{source} · {n}` → `{target} · {union}` (the union of both
  tags' cards, not their sum), and "Merge tags" in the warning tone.
- **Delete dialog** — "Delete this tag?", "“{tag}” is removed from {n} cards and disappears from
  the catalog. Tags are not kept in Trash.", a neutral note (not a success card) "No card is
  deleted, hidden or changed — all {n} cards stay exactly where they are."; Cancel / "Remove from
  {n} cards" (destructive).

## States

### `loaded` · Loaded

Tags in the store's folded order; no sort glyph.

Golden: light, dark

### `loading` · Loading

The search, then skeleton rows.

Golden: light, dark

### `empty` · No tags yet

Only the empty state: no search field, no header. "Go to library" goes back.

Golden: light, dark

### `search_empty` · No tag matches

"No tags match “{term}”", distinct from "No tags yet"; the field and "No matches" stay.

Golden: light, dark

### `sheet` · Action sheet

Golden: light, dark

### `rename` · Rename dialog

The tag's name in quotes, not bold.

Golden: light, dark

### `rename_merge` · Rename that merges

"{len} / 50 · names are unique regardless of letter case.", the warning panel, the chips, and
"Merge tags" in the warning tone, amber with dark ink.

Golden: light, dark

### `name_too_long` · Name too long

The counter "{len} / 50" in the error ink, "A tag name can be at most 50 characters." under the
field, Rename off. The field keeps one line. A blank name and a control character show their own
messages.

Golden: light, dark

### `del` · Delete dialog

No glyph over the title; the text is left-aligned; the buttons stack when "Remove from {n}
cards" cannot keep its line.

Golden: light, dark

### `busy` · Write running

The row's ⋮ is a spinner and the row cannot be tapped.

Golden: light, dark

### `op_error` · Write failed

One sentence, "Couldn't rename tag. Nothing changed — try again in a moment." (or delete), with
Retry, which runs the same write.

Golden: light, dark

### `tag_gone` · Tag gone

"“{tag}” no longer exists — it was removed a moment ago.", from an action or from the rename
dialog, which closes when its plan finds the tag gone; the catalog updates itself.

Golden: light, dark

### `read_error` · Read error

The error state "Couldn't load tags" with Retry.

Golden: light, dark

## Controls

### Catalog and search field

- Type: read / search field
- Invokes: FN-TAG-001

#### On failure

- A database failure → `read_error`.

### Row ⋮

- Type: icon button
- Enabled when: no write of that tag is running.
- Purpose: opens the action sheet (`sheet`).

### Find cards with this tag

- Type: sheet command

#### On success

- Navigate to: SCR-SEARCH-001 (on the tag's name). The search lives in the Library branch, so
  Back from it returns to the Library, not to Tags.

### Rename tag

- Type: sheet command
- Purpose: opens the rename dialog with the current name.

### New name field (rename dialog)

- Type: text field
- Invokes: FN-TAG-002
- Purpose: checks the name rules as typed and reads the plan 250 ms after the name stops.

#### On failure

- `blankName`, `nameTooLong`, `controlCharacter` → the message under the field, the typed name
  kept, Rename off.
- `notFound` → the dialog closes; `tag_gone`.

### Rename / Merge tags (rename dialog)

- Type: dialog confirm (warning tone when it merges)
- Enabled when: the name changed and passes the rules.
- Invokes: FN-TAG-003

#### On success

- The dialog closes; the catalog shows the new name, or the merged tag.

#### On failure

- `mergeNotConfirmed` → the dialog opens again on the name typed, with the new plan.
- `notFound` → `tag_gone`.
- A database failure → `op_error`.

### Delete tag

- Type: sheet command (destructive)
- Purpose: opens the delete dialog (`del`).

### Remove from {n} cards (delete dialog)

- Type: dialog confirm (destructive)
- Invokes: FN-TAG-004

#### On failure

- `notFound` → `tag_gone`.
- A database failure → `op_error`.

### Cancel (rename and delete dialogs)

- Type: dialog action
- Purpose: closes the dialog; nothing changes.

### Retry (`op_error`)

- Type: toast action
- Invokes: FN-TAG-003, FN-TAG-004
- Purpose: runs the same write again.

### Retry (`read_error`)

- Type: button
- Invokes: FN-TAG-001

### Go to library (`empty`)

- Type: button

#### On success

- Navigate to: SCR-DECK-001

## Responsive Behavior

The delete dialog's buttons stack when "Remove from {n} cards" cannot keep its line. Otherwise
follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

"Merge tags" uses the warning role with its ink, at AA. Otherwise follows the shared floor
(DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A rename that merges says so, naming the target, before the confirm. | — |
| The merge target's count is the union of both tags' cards, not their sum. | — |
| "No tags yet" and "No tags match" are distinct states. | — |
| The delete dialog says no card is deleted. | — |
| A tag write in progress makes its row inert. | — |

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
or changed — all {n} cards stay exactly where they are." · "Remove from {n} cards" ·
"Couldn't rename tag. Nothing changed — try again in a moment." · "Couldn't delete tag.
Nothing changed — try again in a moment." · "“{tag}” no longer exists — it was removed a
moment ago."

Rejections (by failure type): `blankName` "Enter a tag name." · `nameTooLong` "Keep the tag to
50 characters." · `controlCharacter` "A tag can't hold that character." · `notFound` "A card or
tag no longer exists." · `mergeNotConfirmed` "Another tag now has this name. Check the merge and
confirm again."

## Rulings

- **D15 (AA):** "Merge tags" uses the warning role with its ink.
- **BE-B2 D6, D8:** the merge target's count is the union of both tags' cards, not their sum.
- **Critique P2b:** there is one order (the store's folded order, diacritics folded), so "A→Z" is
  plain text with no sort glyph.
- **UC-TAG-001 E1, D10:** a read failure shows the error state with Retry.
- Dialogs quote tag names, carry no glyph and are left-aligned; toasts are one sentence.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):**
  the rename dialog's "New name" is a field label in sentence case.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** with no
  tags at all the screen shows only the empty state (no search field, no header); when tags exist
  and a search finds none, the field and "No matches" stay; the delete dialog's reassurance is a
  neutral note, not a success card.
- **Plan C4 (FE-B2):** "Find cards with this tag" opens the Library search on the tag's name; Back
  from it returns to the Library.
- **Migration 2026-10-04:** the legacy UC-TAG-001 trigger also named "Manage tags" in the card
  list's overflow menu; V8 has no such action, and the only entry point is the Library app bar.
