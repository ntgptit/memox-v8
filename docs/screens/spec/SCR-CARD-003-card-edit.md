---
id: SCR-CARD-003
name: Card edit
domain: card
status: ready
route: [/decks/card/:cardId/edit]
---

# Card edit

## Purpose

Editing a card's content, flag and tags. Content changes never touch the card's schedule or
history. The card can also be moved to the Trash from here. Opened from the card detail's Edit
(SCR-CARD-004).

## Related Use Cases

- UC-CARD-001
- UC-CARD-002

## Layout

- **App bar** — back; title "Edit card" (content density); a flag icon button that toggles here,
  in edit only; a trailing compact "Save".
- **Deck path** — a persistent breadcrumb outside the scroll: Library › ancestors › deck ›
  "Edit", above the scrolling history strip.
- **History summary** — a full-bleed card with a list row and an icon tile: "{status} · {n}
  answers · {n} lapses · due {date}"; its chevron opens the card detail, which closes the editor
  underneath it.
- **Front / Back** — the same fields as SCR-CARD-002, prefilled from the card.
- **Optional details** — always open, under the section label "Optional details", no disclosure;
  example, hint and pronunciation prefilled.
- **Tags** — prefilled; the same add, remove and limit behaviour as SCR-CARD-002, including the
  "Add" button and Save adding the tag still typed.
- **More** — a card "Move this card to Trash" / "Leaves this deck and can be restored from Trash
  for 30 days, schedule and history included." with an outline "Move to Trash".
- **Footer** — Cancel and "Save changes" / "Retry save"; a danger banner after a failed save.
- **Move to Trash dialog** — "Move this card to Trash?", a front/back preview, "Recoverable from
  Trash for 30 days, with its schedule and history. Other cards are unaffected."; no glyph; the
  confirm spins while it moves.
- **Discard dialog** — "Discard changes?" / "You edited {parts}. Leaving now keeps the card as it
  was saved.", naming what changed; Keep editing / Discard.
- **Gone state** — an empty state "This card is no longer here" with Back to deck and Open Trash.

## States

### `loaded` · Loaded

Golden: light, dark

### `more` · More card

The More card with Move to Trash, scrolled into view.

Golden: light, dark

### `loading` · Loading

A single generic skeleton list (4 rows) stands in for the whole form; no field-shaped
skeletons. The flag and Save actions and the deck path hold off until loaded.

Golden: none — no golden in V8 (record 09)

### `load_error` · Load error

A full-screen error state "Couldn't load this card" with the shared "Nothing was lost. Try again
in a moment." and Retry.

Golden: none — no golden in V8 (record 09)

### `not_found` · Card gone

The gone state; both actions are live.

Golden: none — no golden in V8 (record 09)

### `validation_err` · Validation error

The error shows only once the back field is touched.

Golden: light, dark

### `dirty_saving` · Saving

The button shows only its spinner in place of the label.

Golden: none — no golden in V8 (record 09)

### `save_failed` · Save failed

Golden: none — no golden in V8 (record 09)

### `discard` · Discard dialog

The body names what was edited ("You edited the meaning and the hint…").

Golden: none — no golden in V8 (record 09)

### `del_confirm` · Move to Trash dialog

No glyph beside the title and no answer count in the note; it spins while the move commits.

Golden: light, dark

## Controls

### Card data

- Type: read
- Invokes: FN-CARD-013

#### On failure

- A database failure → `load_error`; the card gone → `not_found`.

### Flag (app bar)

- Type: icon button
- Purpose: toggles the flag in the draft; the glyph swaps (flag → flagged) and never recolours.

### History summary chevron

- Type: list row

#### On success

- Navigate to: SCR-CARD-004 (the editor closes underneath it).

### Fields, tag input, Add, Remove {tag}

- Type: text fields / buttons
- Purpose: as on SCR-CARD-002.

### Save (app bar), Save changes (footer)

- Type: compact button / primary block button
- Enabled when: the draft differs from the saved card (typed tag text counts) and every field
  passes.
- Invokes: FN-CARD-003

#### On success

- The editor closes, back to the screen it was opened from.

#### On failure

- The fields' own checks catch the limits first; a rejection they let through shows as a snackbar
  with its reason; nothing is saved.
- `notFound` → `not_found`; the unsaved changes are not applied.
- A database failure → `save_failed`; what was typed is kept.

### Move to Trash (More card)

- Type: outline button
- Purpose: opens the Move to Trash dialog (`del_confirm`).

### Move to Trash (dialog confirm)

- Type: dialog confirm (destructive)
- Invokes: FN-CARD-004

#### On success

- The editor closes and reports the move to the screen under it.

### Cancel, Back

- Type: outline button / back
- Purpose: leaves the form; with changes, opens the discard dialog first.

### Retry (`load_error`)

- Type: button
- Invokes: FN-CARD-013

### Back to deck, Open Trash (`not_found`)

- Type: buttons

#### On success

- Back to deck returns to the screen the editor was opened from; Open Trash — Navigate to:
  SCR-TRASH-001.

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

The flag's state is carried by its glyph and its label ("Flag this card" / "Remove flag"), not by
colour. Otherwise follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| Save is enabled only once the draft differs from the saved card. | — |
| Editing content never changes the schedule or history, and the footer says so. | — |
| Leaving with changes asks first, naming what changed. | — |
| The Move to Trash dialog carries no glyph and no history count. | — |
| Loading is one generic skeleton list, not field-shaped skeletons. | — |

## Copy

- App bar: "Edit card" · "Flag this card" · "Remove flag" · "Save".
- History summary: "{status} · {answers}" · "{lapses}" · "due {date}".
- Fields: the labels, hints and errors of SCR-CARD-002, plus "Optional details".
- Footer: "Cancel" · "Save changes" · "Retry save" · "Couldn't save changes." · "Nothing was lost.
  Tap Save to try again." · "Editing content never changes the schedule or history." · "Add the
  missing field to enable save." · "Fix the marked field to enable save." · "Saving to this
  device…".
- More: "More" · "Move this card to Trash" · "Leaves this deck and can be restored from Trash for
  30 days, schedule and history included." · "Move to Trash".
- Move to Trash dialog: "Move this card to Trash?" · "Recoverable from Trash for 30 days, with its
  schedule and history. Other cards are unaffected." · "Cancel" · "Move to Trash".
- Discard: "Discard changes?" · "You edited {parts}. Leaving now keeps the card as it was saved."
  (parts: "the term", "the meaning", "the example", "the hint", "the pronunciation", "the flag",
  "the tags", joined "a, b and c") · "Keep editing" · "Discard".
- Gone: "This card is no longer here" · "It was moved to Trash while you were editing. Your unsaved
  changes were not applied; the card can still be restored from Trash." · "Back to deck" · "Open
  Trash".
- Load error: "Couldn't load this card" · "Nothing was lost. Try again in a moment." · "Retry".

## Rulings

- **§9 row 108:** the Move to Trash dialog has no glyph.
- **§9 row 110:** the dialog reads "Recoverable from Trash for 30 days, with its schedule and
  history" and "Leaves this deck and can be restored…"; it reads no history count, and the path
  above the "More" card already names the deck.
- **§9 rows 80, 28, E-L2:** the flag glyph swaps (`flag` → `flagged`) but never recolours; there is
  no streak token.
- **§9 rows 101, 81 (P4a-L8):** "Add details" has a solid edge, 48 tall; "Add tag" is an outline
  button chip.
- **§9 row 81:** the deck path sits outside the scroll as a persistent header, above the scrolling
  history strip.
- **§9 row 46 (plan O2):** while saving, the button swaps its label for the spinner; the words live
  only in the caption line.
- **§9 row 125:** loading is a single generic skeleton list, the app-wide convention.
- **Ruling P4a-L6, §9 row 80:** the flag toggles in the editor, in edit only.
- **Ruling P4a-L10, §9 row 82:** the history summary's chevron opens the detail, which closes the
  editor underneath it.
- **FE-B1 D13:** the editor moves its card to the Trash from its More card with the card list's
  dialog.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):**
  field headers are field labels in sentence case (14/600); Required is a caption in `primary`
  beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-1 (spec `2026-10-01-critique-fixes-part3d1-design.md`):** in edit,
  Save is enabled only once the draft differs from the saved card; create is unchanged.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the tag
  field has the same "Add" button and add rule as create; Save adds the tag still typed (so pending
  tag text enables Save, and is saved), and an invalid one shows its error and saves nothing.
- **Critique 2026-10-02 (spec `2026-10-02-critique2-fixes-design.md`):** the flag is `on-surface-variant`
  everywhere, the card list included (F6).
