---
id: SCR-CARD-002
name: Card create
domain: card
status: ready
route: [/decks/deck/:deckId/cards/new]
---

# Card create

## Purpose

Adding a card to an open deck that holds cards, or holds nothing yet. The card belongs to the
deck it was opened from. After a save the form stays open, cleared, so cards can be added one
after another.

## Related Use Cases

- UC-CARD-001

## Layout

- **App bar** — close (✕); title "New card" (content density). No Save here: the single Save is
  the footer's "Save card".
- **Deck path** — a persistent breadcrumb outside the scroll: Library › ancestors › deck › "New
  card". The deck is named once. It is not a picker.
- **Deck-rejects banner** — a warning banner "This deck no longer accepts cards." / "It now holds
  sub-decks.", shown only once the deck can no longer hold a card.
- **Front** — the term field: the field label "Front · Term" with "Required" as a caption in
  `primary` beside it, a live "{count} / 60"; an inline error once the field is touched.
- **Back** — the meaning field: "Back · Meaning", "Required", "{count} / 240"; an inline error
  once touched.
- **Optional details** — a disclosure "Add details · example · hint · pronunciation" with a solid
  edge, 48 tall; it opens example, hint and pronunciation, each "· optional", "{count} / 240".
- **Tags** — "Tags · optional · {n} / 10": removable chips, an "Add tag" outline chip button,
  and an inline add input with an "Add" button beside it, enabled while the field holds text;
  Done adds too. At 10 tags, Add tag is withdrawn and a warning message shows.
- **Footer** — a caption line; Cancel (outline) and a block primary "Save card" / "Retry save"; a
  danger banner after a failed save. While saving, the button shows only its spinner; the words
  live in the caption line.
- **Discard dialog** — "Discard this card?" / "What you typed is not saved."; Keep editing /
  Discard. It guards leaving a form with something typed.
- **Gone state** — an empty state "This deck is no longer here" with Back to deck and Open Trash.

## States

### `empty_form` · Empty form

Blank fields, Save disabled, the caption "Front and back are required to save."

Golden: light, dark

### `empty_form_keyboard` · Empty form, keyboard open

Golden: light, dark

### `valid` · Valid

Golden: none — no golden in V8 (record 08)

### `details` · Details open

The opened example, hint and pronunciation are live fields.

Golden: none — no golden in V8 (record 08)

### `validation_err` · Validation error

The message shows only once the back field has been touched.

Golden: light, dark

### `front_too_long` · Front too long

Shown once the front field is touched.

Golden: none — no golden in V8 (record 08)

### `tag_limit` · Ten tags

Golden: none — no golden in V8 (record 08)

### `deck_rejects` · Deck no longer takes cards

The caption "This deck can't take cards now." and the banner "It now holds sub-decks."; there is
no way here to choose another deck.

Golden: none — no golden in V8 (record 08)

### `saving` · Saving

The button shows only its spinner in place of the label.

Golden: none — no golden in V8 (record 08)

### `save_failed` · Save failed

The danger banner; the form keeps what was typed; the button reads "Retry save".

Golden: none — no golden in V8 (record 08)

### `deck_gone` · Deck gone

The deck was moved to the Trash or deleted while cards were being added.

Golden: none — no golden in V8 (record 08)

### `discard` · Discard dialog

Golden: none — no golden in V8 (record 08)

## Controls

### Front, Back, Example, Hint, Pronunciation

- Type: text fields
- Purpose: checked as typed against the card's limits; an error shows at its field once the field
  is touched.

### Add details

- Type: disclosure
- Purpose: opens the optional fields.

### Tag input, Add, Done

- Type: text field / button
- Enabled when: the field holds text and the card has fewer than 10 tags.
- Purpose: adds the typed tag through the same checks as a save.

### Remove {tag}

- Type: chip action

### Save card

- Type: primary block button
- Enabled when: front and back are filled and every field passes.
- Invokes: FN-CARD-002
- Purpose: first adds the tag still typed; an invalid one shows its error and saves nothing.

#### On success

- "Card added"; the form stays open with every field cleared, the tag field included.

#### On failure

- The fields' own checks catch the limits before a save; a rejection they let through
  (`blankContent`, `frontTooLong`, `backTooLong`, `optionalFieldTooLong`, `invalidTagName`,
  `tooManyTags`) shows as a snackbar with its reason; nothing is saved.
- `notACardContainer` → `deck_rejects`.
- `notFound` (the deck is gone) → `deck_gone`.
- A database failure → `save_failed`; what was typed is kept.

### Cancel, close (✕), Back

- Type: outline button / icon button
- Purpose: leaves the form; with something typed, opens the discard dialog first.

#### On success

- Back to SCR-CARD-001.

### Keep editing, Discard (discard dialog)

- Type: dialog actions

### Back to deck (`deck_gone`)

- Type: button

#### On success

- Navigate to: SCR-DECK-001

### Open Trash (`deck_gone`)

- Type: button

#### On success

- Navigate to: SCR-TRASH-001

## Responsive Behavior

Follows the shared floor (DESIGN.md, SCREEN_CATALOG.md).

## Accessibility

"Add details" and "Add tag" keep the 48 touch floor. Otherwise follows the shared floor
(DESIGN.md, SCREEN_CATALOG.md).

## UI Invariants

| Invariant | Enforced by |
|---|---|
| A field's error shows at that field, only once it has been touched. | — |
| While saving, the button holds only its spinner; the words are in the caption. | — |
| A save failure keeps everything typed. | — |
| The deck is not a picker: a deck that rejects cards offers no other deck. | — |
| Leaving a form with something typed asks first. | — |

## Copy

- App bar and caption: "New card" · "Front and back are required to save." · "Fix the marked
  field to enable save." · "You can keep adding cards after saving." · "Saving to this device…" ·
  "This deck can't take cards now."
- Fields: "Front · Term" · "Back · Meaning" · "Required" · "{count} / {limit}" · "The term you
  want to remember" · "The meaning; separate several with commas" · "Add details" · "example ·
  hint · pronunciation" · "Optional details" · "· optional" · "Example sentence" · "Hint" ·
  "Pronunciation" · "A sentence using this term" · "A clue that jogs memory without giving the
  answer" · "Romanisation or a note on how to say it".
- Errors: "Add the term to remember." · "The term can be at most 60 characters. Move the rest into
  the meaning or an example." · "Add a meaning so this card can be answered." · "The meaning can be
  at most 240 characters." · "Keep this to 240 characters."
- Deck rejects: "This deck no longer accepts cards." · "It now holds sub-decks."
- Tags: "Tags" · "optional · {count} / {limit}" · "Add tag" · "Add" · "Remove {tag}" · "A card can
  carry 10 tags. Remove one to add another."
- Footer: "Cancel" · "Save card" · "Retry save" · "Couldn't save card." · "Nothing was lost. Tap
  Save to try again."
- Discard: "Discard this card?" · "What you typed is not saved." · "Keep editing" · "Discard".
- Gone: "This deck is no longer here" · "It was moved to Trash or deleted while you were adding
  cards. This card was not saved." · "Back to deck" · "Open Trash".
- Toast: "Card added".

## Rulings

- **§9 row 81 (P4a-L7):** the deck chip is not a picker, so a deck that rejects cards says "This
  deck can't take cards now." / "It now holds sub-decks." with no "choose another deck".
- **§9 row 101:** "Add details" has a solid `outlineVariant` edge, 48 tall (touch floor).
- **§9 row 81 (P4a-L8):** "Add tag" is an outline button chip; there is no dashed-border token.
- **§9 row 81:** the deck path sits outside the scroll as a persistent header.
- **§9 row 46 (plan O2):** while saving, the button swaps its label for the spinner; the words live
  only in the caption line.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):**
  field headers are field labels in sentence case (14/600); Required is a caption in `primary`
  beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the tag
  field has an "Add" button (`cardTagConfirm`) beside it, enabled while the field holds text; Done
  or Add adds the tag through the same checks (FN-CARD-002); Save first adds the tag still typed,
  and an invalid one shows its error and saves nothing; "Save and add another" clears the tag field
  with the rest of the form.
- **Ruling P4a-L5, §9 row 79:** the deck-gone state and the discard confirm extend the edit form's
  rulings to create.
- **Migration 2026-10-04:** the Vietnamese field errors of the legacy `features/card/ui.md` are the
  app's Vietnamese strings (`app_vi.arb`); this spec keeps the English copy.
