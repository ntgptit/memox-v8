<!-- Hand-written screen record. -->

# 08 · Card create

Adding a card to an open `card` deck: `CardEditorScreen.create` →
`CardEditorFormWidget` in create mode (library phase 4a). UC-CARD-001 steps
2–4, A4 (continuous add); BR-CARD-001, BR-CARD-002, BR-CARD-003.

## Layout

| Region | Widget | Design |
|---|---|---|
| App bar | `MxAppBar` (content density) | Close (✕); title "New card". No Save here: the single Save is the footer's "Save card" (critique 2026-09-30 part 3a records it). |
| Deck path | `DeckContextHeaderWidget` (`MxBreadcrumb`), injected by `app/` (ruling P4a-L7) | Library › ancestors › deck › "New card": the deck is named once (critique 2026-09-30). Not a picker: the card belongs to the deck it was opened from. |
| Deck-rejects banner | `MxInlineBanner` (warning) | "This deck no longer accepts cards." / "It now holds sub-decks."; shown only once the target deck can no longer hold a card. |
| Front | `CardFieldWidget` (`MxTextField`, `MxTextFieldVariant.term`) | Overline "Front · Term", "Required", live "{count} / 60"; inline error once the field is touched (ruling P4a-L2). |
| Back | `CardFieldWidget` (`MxTextFieldVariant.detail`) | Overline "Back · Meaning", "Required", "{count} / 240"; inline error once touched. |
| Optional details | `CardAddDetailsWidget` disclosure → `CardOptionalFieldsWidget` (3 × `CardFieldWidget`, `MxTextFieldVariant.detail`) | "Add details · example · hint · pronunciation"; opens example, hint, pronunciation, each "· optional", "{count} / 240". |
| Tags | `CardTagEditorWidget` (`CardRemovableTagChipWidget` × n, `MxButton` "Add tag", `MxFieldMessage`) | "Tags · optional · {n} / 10"; removable chips, an inline add input with an "Add" button beside it (enabled while the field holds text; Done adds too). At 10 tags, Add tag is withdrawn and a warning message shows (BR-TAG-002). |
| Footer | `CardEditorFooterWidget` (`MxFooterBar`, `MxActionPair` 1 : 1) | Caption line; Cancel (`MxButton` outline) + a primary "Save card" / "Retry save", sharing the row equally (DEV-169); a danger `MxInlineBanner` after a failed save. |
| Discard dialog | `showCardDiscardDialog` (`showMxConfirm`) | "Discard this card?" / "What you typed is not saved."; Keep editing / Discard. Guards leaving a dirty new-card form (ruling P4a-L5). |
| Gone state | `CardGoneWidget` (`MxEmptyState`) | "This deck is no longer here" / "It was moved to Trash or deleted while you were adding cards. This card was not saved."; Back to deck + Open Trash (FE-B1 D11). |

## States

| State | Golden (light) | Golden (dark) | App |
|---|---|---|---|
| emptyForm | `card_editor_create_light.png` | `card_editor_create_dark.png` | Blank fields, Save disabled, caption "Front and back are required to save." |
| valid | no golden | no golden | — |
| details | no golden | no golden | The opened example, hint and pronunciation are live `MxTextField`s. |
| validationErr | `card_editor_errors_light.png` | `card_editor_errors_dark.png` | The message shows only once the back field has been touched (ruling P4a-L2). |
| frontTooLong | no golden | no golden | Shown once the front field is touched. |
| tagLimit | no golden | no golden | — |
| deckRejects | no golden | no golden | Caption "This deck can't take cards now." and banner "It now holds sub-decks."; no path exists here to choose another deck (see Rulings). |
| saving | no golden | no golden | The button shows only its spinner in place of the label — no "Saving…" text inside the button (see Rulings). |
| saveFailed | no golden | no golden | — |
Other goldens: `card_editor_create_keyboard_light.png` / `card_editor_create_keyboard_dark.png` (the form with the keyboard open).

Two further states, both built as
extensions of ruling P4a-L1…L5 (§9 row 79, "gone state" + discard confirm) from
the edit form to create: a deck-gone state (`CardGoneWidget`, above) when the
target deck disappears mid-add, and a discard-changes confirm ("Discard this
card?") when leaving a dirty new-card form without saving.

## Rulings

- **DEV-169 (owner 2026-10-05):** every card field (term, meaning, example, hint, pronunciation) is the app's form field: muted fill that lightens on focus, r12, 12 padding, 52 floor, the body role. The footer pair shares the row 1 : 1 like every footer pair.
- **§9 row 81 (P4a-L7):** the deck chip is not a picker, so a deck that rejects cards says "This deck can't take cards now." / "It now holds sub-decks." with no "choose another deck".
- **§9 row 101:** "Add details" has a solid edge, 48 tall (touch floor); the edge is the outline, as the fields beside it (DEV-166, was `outlineVariant` at about 1.5:1).
- **§9 row 81 (P4a-L8):** "Add tag" is an outline `MxButton` chip; there is no dashed-border token.
- **§9 row 81:** `DeckContextHeaderWidget` sits outside the scroll as a persistent header.
- **§9 row 46 (plan O2):** while saving, `MxButton` swaps its label for the spinner; the words live only in the caption line.
- **Critique 2026-09-30 part 2 (spec `2026-10-01-critique-fixes-part2-typography-design.md`):** field headers are field labels in sentence case (14/600); Required is a caption in `primaryText` beside them; Optional details stays a section label.
- **Critique 2026-09-30 part 3d-2 (spec `2026-10-01-critique-fixes-part3d2-design.md`):** the tag field has an "Add" button (`cardTagConfirm`) beside it, enabled while the field holds text; Done or Add adds the tag through the same checks (BR-TAG-001, BR-TAG-002); Save first adds the tag still typed, and an invalid one shows its error and saves nothing; "Save and add another" clears the tag field with the rest of the form.

## Copy

- App bar and caption: "New card" · "Front and back are required to save." · "Fix the marked field to enable save." · "You can keep adding cards after saving." · "Saving to this device…" · "This deck can't take cards now."
- Fields: "Front · Term" · "Back · Meaning" · "Required" · "{count} / {limit}" · "The term you want to remember" · "The meaning; separate several with commas" · "Add details" · "example · hint · pronunciation" · "Optional details" · "· optional" · "Example sentence" · "Hint" · "Pronunciation" · "A sentence using this term" · "A clue that jogs memory without giving the answer" · "Romanisation or a note on how to say it".
- Errors: "Add the term to remember." · "The term can be at most 60 characters. Move the rest into the meaning or an example." · "Add a meaning so this card can be answered." · "The meaning can be at most 240 characters." · "Keep this to 240 characters."
- Deck rejects: "This deck no longer accepts cards." · "It now holds sub-decks."
- Tags: "Tags" · "optional · {count} / {limit}" · "Add tag" · "Add" · "Remove {tag}" · "A card can carry 10 tags. Remove one to add another."
- Footer: "Cancel" · "Save card" · "Retry save" · "Couldn't save card." · "Nothing was lost. Tap Save to try again."
- Discard: "Discard this card?" · "What you typed is not saved." · "Keep editing" · "Discard".
- Gone: "This deck is no longer here" · "It was moved to Trash or deleted while you were adding cards. This card was not saved." · "Back to deck" · "Open Trash".
- Toast: "Card added".
